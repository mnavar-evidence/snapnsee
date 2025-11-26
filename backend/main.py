import os
import shutil
import requests
import numpy as np
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from PIL import Image
from dotenv import load_dotenv
from transformers import CLIPProcessor, CLIPModel
import torch
from sklearn.metrics.pairwise import cosine_similarity
import easyocr
import re

# --- Load Environment & Configuration ---
load_dotenv()
TMDB_API_KEY = os.getenv("TMDB_API_KEY")
TMDB_API_URL = "https://api.themoviedb.org/3"
DEVICE = "cuda" if torch.cuda.is_available() else "cpu"
MODEL_NAME = "openai/clip-vit-base-patch32"
# Confidence threshold for a match
SIMILARITY_THRESHOLD = 0.90 

# --- AI Model and Database Initialization ---
print("Loading CLIP model... This may take a moment.")
model = CLIPModel.from_pretrained(MODEL_NAME).to(DEVICE)
processor = CLIPProcessor.from_pretrained(MODEL_NAME)
print("CLIP model loaded successfully.")

# OCR reader (lazy loaded on first use)
ocr_reader = None

def get_ocr_reader():
    """Lazy load the OCR reader"""
    global ocr_reader
    if ocr_reader is None:
        print("Loading EasyOCR reader...")
        ocr_reader = easyocr.Reader(['en'], gpu=False)
        print("EasyOCR reader loaded.")
    return ocr_reader

# --- Dummy Vector Database ---
# Load real movie embeddings from file
print("Loading movie embeddings database...")
try:
    db_data = np.load('movie_embeddings.npz', allow_pickle=True)
    db_ids = db_data['ids'].tolist()
    db_embeddings = db_data['embeddings']
    print(f"✅ Loaded {len(db_ids)} movies from database")
except FileNotFoundError:
    print("⚠️  movie_embeddings.npz not found, using placeholder data")
    # Fallback to placeholder if file doesn't exist
    placeholder_db = {
        "157336": np.random.rand(1, 512), # "Interstellar"
        "299536": np.random.rand(1, 512), # "Avengers: Endgame"
    }
    db_ids = list(placeholder_db.keys())
    db_embeddings = np.vstack(list(placeholder_db.values()))
    print("Using placeholder database.")

# --- FastAPI App Initialization ---
app = FastAPI(
    title="SnapnSee API",
    description="API for recognizing movies/shows from images and getting metadata.",
    version="0.2.0",  # Version incremented
)

# Add CORS middleware to allow browser requests
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for testing
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Helper Functions ---

def identify_media_from_image(image: Image.Image) -> str | None:
    """
    Identifies a movie or show from an image using the CLIP model.
    """
    try:
        # Pre-process the image and get the embedding
        inputs = processor(images=image, return_tensors="pt", padding=True)
        inputs = {k: v.to(DEVICE) for k, v in inputs.items()}
        with torch.no_grad():
            image_embedding = model.get_image_features(**inputs)

        # Normalize the embedding for cosine similarity
        image_embedding = image_embedding.cpu().numpy()
        
        # --- Search in Vector DB ---
        # Calculate cosine similarity against the database
        similarities = cosine_similarity(image_embedding, db_embeddings)
        
        best_match_index = np.argmax(similarities)
        best_match_score = similarities[0, best_match_index]

        print(f"DEBUG: Best match score: {best_match_score:.4f}")

        if best_match_score >= SIMILARITY_THRESHOLD:
            return db_ids[best_match_index]
        
        return None

    except Exception as e:
        print(f"ERROR: Could not process image with CLIP model: {e}")
        return None

def get_tmdb_details(media_id: str, media_type: str = "movie"):
    """Fetches detailed information for a given media ID from TMDB."""
    if not TMDB_API_KEY or TMDB_API_KEY == "YOUR_TMDB_API_KEY":
        print("WARN: TMDB_API_KEY is not set. Skipping TMDB search.")
        return {"id": media_id, "title": "TMDB API Key Not Configured", "overview": "Please set your TMDB_API_KEY in the .env file."}

    detail_url = f"{TMDB_API_URL}/{media_type}/{media_id}"
    params = {"api_key": TMDB_API_KEY}

    try:
        response = requests.get(detail_url, params=params)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Error fetching TMDB details: {e}")
        return None

def extract_text_from_image(image: Image.Image) -> list[str]:
    """Extract text from image using EasyOCR"""
    try:
        reader = get_ocr_reader()

        # Convert PIL image to numpy array
        import numpy as np
        img_array = np.array(image)

        # Extract text
        results = reader.readtext(img_array)

        # Extract just the text, filter out low confidence
        texts = [text for (bbox, text, confidence) in results if confidence > 0.3]

        print(f"DEBUG: Extracted texts: {texts}")
        return texts

    except Exception as e:
        print(f"ERROR: Could not extract text from image: {e}")
        return []

def search_tmdb_by_title(title: str):
    """Search TMDB for movies/TV shows by title"""
    if not TMDB_API_KEY or TMDB_API_KEY == "YOUR_TMDB_API_KEY":
        print("WARN: TMDB_API_KEY is not set.")
        return None

    # Try multi search first (searches both movies and TV shows)
    search_url = f"{TMDB_API_URL}/search/multi"
    params = {
        "api_key": TMDB_API_KEY,
        "query": title,
        "page": 1
    }

    try:
        response = requests.get(search_url, params=params)
        response.raise_for_status()
        data = response.json()

        if data.get("results") and len(data["results"]) > 0:
            # Filter out person results, we only want movies/TV shows
            media_results = [r for r in data["results"] if r.get("media_type") in ["movie", "tv"]]

            if media_results:
                # Return the first media result (most relevant)
                result = media_results[0]
                print(f"DEBUG: Found match for '{title}': {result.get('title') or result.get('name')} (ID: {result['id']}, Type: {result['media_type']})")
                return result

        return None

    except requests.exceptions.RequestException as e:
        print(f"Error searching TMDB: {e}")
        return None

def find_best_title_match(texts: list[str]) -> str | None:
    """
    Find the most likely title from extracted text
    Looks for the largest/most prominent text that's likely a title
    """
    if not texts:
        return None

    # Filter out unwanted text patterns
    candidates = []
    for text in texts:
        # Skip if too short
        if len(text) < 3:
            continue

        # Skip numbers-only
        if text.isdigit():
            continue

        # Skip time/duration patterns
        if re.match(r'^\d+\s*(hr|min|m|h|Season|Episode|s|Ep).*', text, re.IGNORECASE):
            continue

        # Skip URLs
        if any(url_pattern in text.lower() for url_pattern in ['http', 'www.', '.com', 'netflix.com', 'tps:', '://']):
            continue

        # Skip common UI elements
        if text.lower() in ['play', 'more', 'recently added', 'more like this', 'limited series', 'season', 'episodes', 'cast:', 'genres:']:
            continue

        # Skip ratings
        if text in ['PG-13', 'R', 'TV-MA', 'TV-14', 'G', 'PG', 'HD']:
            continue

        # Skip long sentences (descriptions)
        if len(text.split()) > 10:
            continue

        candidates.append(text)

    if not candidates:
        return None

    # Try to find all-caps words (titles are often capitalized)
    uppercase_candidates = [text for text in candidates if text.isupper() and len(text) > 1]

    print(f"DEBUG: All candidates: {candidates}")
    print(f"DEBUG: Uppercase candidates: {uppercase_candidates}")

    # Try uppercase candidates, preferring cleaner ones first
    # Sort by: single words first, then multi-word, then weird spacing
    def title_quality_score(text):
        """Score title candidates - higher is better"""
        score = 0
        # Penalize weird spacing like "L E 0 N A R D 0"
        if len(text) > 10 and text.count(' ') > len(text.replace(' ', '')) * 0.3:
            score -= 100
        # Penalize special chars
        if '|' in text or "'" in text or any(c.isdigit() for c in text):
            score -= 50
        # Prefer shorter titles (likely more specific)
        score -= len(text.split())
        # Prefer alphabetic
        if text.replace(' ', '').replace('-', '').isalpha():
            score += 10
        return score

    sorted_candidates = sorted(uppercase_candidates, key=title_quality_score, reverse=True)

    print(f"DEBUG: Sorted candidates by quality: {sorted_candidates[:3]}")

    # If we have multiple uppercase candidates, try combining them first
    # (e.g., "KEVIN HART" + "ACTING MY AGE" = "KEVIN HART ACTING MY AGE")
    if len(sorted_candidates) >= 2:
        # Combine top 2-3 candidates (avoid combining too many)
        combined = " ".join(sorted_candidates[:min(3, len(sorted_candidates))])
        print(f"DEBUG: Trying combined title: {combined}")
        return combined

    # Try top single candidate (usually the cleanest/most likely title)
    if sorted_candidates:
        return sorted_candidates[0]

    # If we have uppercase words, try to combine them into a title
    if uppercase_candidates:
        # Find the first uppercase word
        first_upper = uppercase_candidates[0]
        start_idx = texts.index(first_upper)

        # Combine consecutive words starting from first uppercase
        # Include connecting words like "OF", "A", "THE" between uppercase words
        title_parts = []
        for i in range(start_idx, min(start_idx + 10, len(texts))):
            word = texts[i]

            # Skip filtered words
            if word in ['Recently Added', 'More Like This', 'Play', 'Season', 'Episodes', 'Limited Series']:
                break

            # Include uppercase words
            if word.isupper() and len(word) > 1:
                title_parts.append(word)
            # Include small connecting words (OF, A, THE, AND, IN, etc.)
            elif word.upper() in ['OF', 'A', 'THE', 'AND', 'IN', 'ON', 'AT', 'TO', 'FOR']:
                title_parts.append(word.upper())
            # Stop if we hit non-title text
            else:
                # Only stop if we already have some title words
                if len(title_parts) > 0:
                    break

            # Stop at max 7 words
            if len(title_parts) >= 7:
                break

        if title_parts:
            combined_title = " ".join(title_parts)
            print(f"DEBUG: Combined title: {combined_title}")
            return combined_title

    # Fallback: return longest non-sentence candidate
    candidates.sort(key=len, reverse=True)
    return candidates[0] if candidates else None

# --- API Endpoints ---
@app.get("/", tags=["General"])
def read_root():
    """A simple health check endpoint."""
    return {"status": "ok", "message": "Welcome to the SnapnSee API!"}

@app.get("/test", tags=["General"])
def test_interface():
    """Serve the test web interface."""
    return FileResponse("test_app.html")

@app.post("/api/v1/recognize", tags=["Recognition"])
async def recognize_image_endpoint(file: UploadFile = File(...)):
    """
    Accepts an image, identifies a movie/show using hybrid approach:
    1. Try text extraction first (for title screens)
    2. Fall back to visual embedding match if text fails
    """
    temp_file_path = f"_temp_{file.filename}"
    try:
        with open(temp_file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        image = Image.open(temp_file_path)

        # --- HYBRID APPROACH ---

        # Strategy 1: Try text extraction (best for title screens)
        print("DEBUG: Attempting text extraction...")
        texts = extract_text_from_image(image)

        if texts:
            title = find_best_title_match(texts)
            if title:
                print(f"DEBUG: Searching TMDB for title: '{title}'")
                tmdb_result = search_tmdb_by_title(title)

                if tmdb_result:
                    # Success with text-based search!
                    return {
                        "method": "text_extraction",
                        "extracted_title": title,
                        "identified_media_id": str(tmdb_result['id']),
                        "media_type": tmdb_result.get('media_type', 'unknown'),
                        "match_confidence": 0.95,  # High confidence for text matches
                        "tmdb_match": tmdb_result,
                    }

        # Strategy 2: Fall back to visual embedding match
        print("DEBUG: Text extraction failed or no results, falling back to visual matching...")
        identified_media_id = identify_media_from_image(image)

        if not identified_media_id:
             raise HTTPException(
                status_code=404,
                detail="Could not identify a movie or show from the image. Try getting a clearer shot of the title.",
            )

        tmdb_result = get_tmdb_details(identified_media_id, media_type="movie")

        if not tmdb_result:
             raise HTTPException(
                status_code=404,
                detail=f"Found media ID {identified_media_id}, but could not fetch details from TMDB.",
            )

        return {
            "method": "visual_embedding",
            "identified_media_id": identified_media_id,
            "match_confidence": 0.90,  # Based on similarity threshold
            "tmdb_match": tmdb_result,
        }

    except HTTPException:
        raise  # Re-raise HTTP exceptions (404s) as-is
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {str(e)}")

    finally:
        if os.path.exists(temp_file_path):
            os.remove(temp_file_path)

if __name__ == "__main__":
    import uvicorn
    print("Starting server... Access at http://127.0.0.1:8000")
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)
