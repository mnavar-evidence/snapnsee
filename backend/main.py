import os
import base64
import json
import requests
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from PIL import Image
from io import BytesIO
from dotenv import load_dotenv
from openai import OpenAI

# --- Load Environment & Configuration ---
load_dotenv()
TMDB_API_KEY = os.getenv("TMDB_API_KEY")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
TMDB_API_URL = "https://api.themoviedb.org/3"

# Initialize OpenAI client
client = OpenAI(api_key=OPENAI_API_KEY)

# --- FastAPI App Initialization ---
app = FastAPI(
    title="SnapnSee API",
    description="AI-powered movie/TV show recognition using GPT-4o Vision",
    version="2.0.1",
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Helper Functions ---

def identify_media_with_gpt4o(image_bytes: bytes) -> dict:
    """
    Uses GPT-4o Vision to identify the movie/show from an image.
    Returns a dict with title, media_type, year, and confidence.
    """
    try:
        # Encode image to base64
        base64_image = base64.b64encode(image_bytes).decode('utf-8')

        # Prepare the prompt
        system_prompt = """You are an expert at identifying movies and TV shows from screenshots.
Analyze the image and identify the exact title of the movie or TV show.
Look for title text, logos, recognizable scenes, or UI elements from streaming services.

Return ONLY a JSON object with this structure:
{
  "title": "exact title of the movie or show",
  "media_type": "movie" or "tv",
  "year": release year if visible (or null),
  "confidence": 0.0 to 1.0,
  "reasoning": "brief explanation of how you identified it"
}

If you cannot identify it with confidence, set confidence to 0.0 and title to "unknown"."""

        # Call GPT-4o Vision
        response = client.chat.completions.create(
            model="gpt-4o",
            messages=[
                {
                    "role": "system",
                    "content": system_prompt
                },
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": "What movie or TV show is this? Return JSON only."
                        },
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/jpeg;base64,{base64_image}",
                                "detail": "high"
                            }
                        }
                    ]
                }
            ],
            max_tokens=500,
            temperature=0.2
        )

        # Parse the response
        content = response.choices[0].message.content
        print(f"DEBUG: GPT-4o raw response: {content}")

        # Try to extract JSON from response (in case there's extra text)
        try:
            # Look for JSON in the response
            if "```json" in content:
                content = content.split("```json")[1].split("```")[0].strip()
            elif "```" in content:
                content = content.split("```")[1].split("```")[0].strip()

            result = json.loads(content)
            return result
        except json.JSONDecodeError:
            print(f"ERROR: Could not parse JSON from GPT-4o response: {content}")
            return {
                "title": "unknown",
                "media_type": "unknown",
                "year": None,
                "confidence": 0.0,
                "reasoning": "Failed to parse GPT-4o response"
            }

    except Exception as e:
        print(f"ERROR: GPT-4o Vision call failed: {e}")
        return {
            "title": "unknown",
            "media_type": "unknown",
            "year": None,
            "confidence": 0.0,
            "reasoning": f"Error: {str(e)}"
        }


def search_tmdb(title: str, media_type: str = None, year: int = None):
    """
    Searches TMDB for the given title and returns the best match.
    """
    if not TMDB_API_KEY or TMDB_API_KEY == "YOUR_TMDB_API_KEY":
        print("WARN: TMDB_API_KEY is not set.")
        return None

    # Try multi-search (searches both movies and TV)
    search_url = f"{TMDB_API_URL}/search/multi"
    params = {
        "api_key": TMDB_API_KEY,
        "query": title,
        "page": 1
    }

    # Add year if provided
    if year and media_type == "movie":
        params["year"] = year
    elif year and media_type == "tv":
        params["first_air_date_year"] = year

    try:
        response = requests.get(search_url, params=params)
        response.raise_for_status()
        data = response.json()

        if data.get("results") and len(data["results"]) > 0:
            # Filter by media type if specified
            results = data["results"]
            if media_type:
                results = [r for r in results if r.get("media_type") == media_type]

            # Filter out person results
            results = [r for r in results if r.get("media_type") in ["movie", "tv"]]

            if results:
                # Return the first result (most relevant)
                result = results[0]
                print(f"DEBUG: TMDB found: {result.get('title') or result.get('name')} (ID: {result['id']}, Type: {result['media_type']})")
                return result

        return None

    except requests.exceptions.RequestException as e:
        print(f"Error searching TMDB: {e}")
        return None


def get_tmdb_details(media_id: str, media_type: str = "movie"):
    """Fetches detailed information for a given media ID from TMDB."""
    if not TMDB_API_KEY or TMDB_API_KEY == "YOUR_TMDB_API_KEY":
        return None

    detail_url = f"{TMDB_API_URL}/{media_type}/{media_id}"
    params = {"api_key": TMDB_API_KEY}

    try:
        response = requests.get(detail_url, params=params)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Error fetching TMDB details: {e}")
        return None


# --- API Endpoints ---

@app.get("/", tags=["General"])
def read_root():
    """Health check endpoint."""
    return {
        "status": "ok",
        "message": "Welcome to SnapnSee API v2.0!",
        "powered_by": "GPT-4o Vision + TMDB"
    }


@app.get("/test", tags=["General"])
def test_interface():
    """Serve the test web interface."""
    return FileResponse("test_app.html")


@app.post("/api/v1/recognize", tags=["Recognition"])
async def recognize_image_endpoint(file: UploadFile = File(...)):
    """
    Accepts an image and identifies the movie/show using GPT-4o Vision.
    Then enriches the result with TMDB metadata.
    """
    try:
        # Read image bytes
        image_bytes = await file.read()

        # Validate it's an image
        try:
            image = Image.open(BytesIO(image_bytes))
            image.verify()
        except Exception:
            raise HTTPException(status_code=400, detail="Invalid image file")

        # Re-read bytes (verify consumes the stream)
        image_bytes = await file.read()
        if not image_bytes:
            await file.seek(0)
            image_bytes = await file.read()

        # Step 1: Identify with GPT-4o Vision
        print("DEBUG: Calling GPT-4o Vision for identification...")
        gpt_result = identify_media_with_gpt4o(image_bytes)

        if gpt_result["confidence"] < 0.5:
            raise HTTPException(
                status_code=404,
                detail=f"Could not identify the media with sufficient confidence. GPT-4o said: {gpt_result.get('reasoning', 'Unknown')}"
            )

        # Step 2: Search TMDB for verification and metadata
        print(f"DEBUG: Searching TMDB for: {gpt_result['title']}")
        tmdb_result = search_tmdb(
            title=gpt_result["title"],
            media_type=gpt_result.get("media_type"),
            year=gpt_result.get("year")
        )

        if not tmdb_result:
            # Return GPT result even without TMDB match
            return {
                "method": "gpt4o_vision",
                "gpt_identification": gpt_result,
                "identified_media_id": None,
                "media_type": gpt_result.get("media_type", "unknown"),
                "match_confidence": gpt_result["confidence"],
                "tmdb_match": None,
                "note": "GPT-4o identified the media but TMDB search found no match"
            }

        # Step 3: Get detailed TMDB info
        media_id = str(tmdb_result["id"])
        media_type = tmdb_result["media_type"]
        tmdb_details = get_tmdb_details(media_id, media_type)

        return {
            "method": "gpt4o_vision",
            "gpt_identification": gpt_result,
            "identified_media_id": media_id,
            "media_type": media_type,
            "match_confidence": gpt_result["confidence"],
            "tmdb_match": tmdb_details or tmdb_result,
        }

    except HTTPException:
        raise
    except Exception as e:
        print(f"ERROR: Unexpected error in recognition: {e}")
        raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {str(e)}")


if __name__ == "__main__":
    import uvicorn
    print("Starting SnapnSee API v2.0 (GPT-4o Vision)...")
    print("Access at http://127.0.0.1:8000")
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)
