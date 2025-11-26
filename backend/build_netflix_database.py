#!/usr/bin/env python3
"""
Build vector database from top Netflix content
Fetches top 50 shows/movies from TMDB and generates CLIP embeddings
"""

import os
import requests
import numpy as np
import torch
from PIL import Image
from transformers import CLIPProcessor, CLIPModel
from io import BytesIO
from dotenv import load_dotenv
import time

# Load environment
load_dotenv()
TMDB_API_KEY = os.getenv("TMDB_API_KEY")
TMDB_IMAGE_BASE = "https://image.tmdb.org/t/p/w500"
TMDB_API_URL = "https://api.themoviedb.org/3"

# Netflix provider ID on TMDB
NETFLIX_PROVIDER_ID = 8

def get_top_netflix_content(content_type="tv", limit=25):
    """
    Fetch top Netflix content from TMDB
    content_type: 'tv' or 'movie'
    """
    url = f"{TMDB_API_URL}/discover/{content_type}"

    all_results = []
    page = 1

    while len(all_results) < limit:
        params = {
            "api_key": TMDB_API_KEY,
            "watch_region": "US",
            "with_watch_providers": NETFLIX_PROVIDER_ID,
            "sort_by": "popularity.desc",
            "page": page
        }

        try:
            print(f"Fetching {content_type} page {page}...")
            response = requests.get(url, params=params)
            response.raise_for_status()
            data = response.json()

            results = data.get("results", [])
            if not results:
                break

            all_results.extend(results)
            page += 1

            # Rate limiting
            time.sleep(0.3)

        except Exception as e:
            print(f"Error fetching {content_type}: {e}")
            break

    return all_results[:limit]

def download_poster(poster_path):
    """Download a poster image from TMDB"""
    if not poster_path:
        return None

    url = f"{TMDB_IMAGE_BASE}{poster_path}"
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        return Image.open(BytesIO(response.content))
    except Exception as e:
        print(f"  ✗ Error downloading poster: {e}")
        return None

def generate_embedding(image, model, processor, device):
    """Generate CLIP embedding for an image"""
    try:
        inputs = processor(images=image, return_tensors="pt").to(device)

        with torch.no_grad():
            image_embedding = model.get_image_features(**inputs)

        # Normalize and convert to numpy
        image_embedding = image_embedding.cpu().numpy()
        image_embedding = image_embedding / np.linalg.norm(image_embedding)

        return image_embedding
    except Exception as e:
        print(f"  ✗ Error generating embedding: {e}")
        return None

def main():
    print("🎬 Building SnapnSee Netflix Vector Database")
    print("=" * 60)

    if not TMDB_API_KEY or TMDB_API_KEY == "YOUR_TMDB_API_KEY":
        print("❌ Error: TMDB_API_KEY not set in .env file")
        return

    # Load CLIP model
    print("\n📦 Loading CLIP model...")
    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"Using device: {device}")

    model = CLIPModel.from_pretrained("openai/clip-vit-base-patch32").to(device)
    processor = CLIPProcessor.from_pretrained("openai/clip-vit-base-patch32")
    print("✅ CLIP model loaded")

    # Fetch top Netflix content
    print("\n🎯 Fetching top Netflix content from TMDB...")
    print("Getting top 25 TV shows...")
    tv_shows = get_top_netflix_content("tv", limit=25)
    print(f"✅ Found {len(tv_shows)} TV shows")

    print("Getting top 25 movies...")
    movies = get_top_netflix_content("movie", limit=25)
    print(f"✅ Found {len(movies)} movies")

    all_content = tv_shows + movies
    print(f"\n📊 Total content to process: {len(all_content)}")

    # Generate embeddings
    database = {}
    successful = 0
    failed = 0

    for idx, item in enumerate(all_content, 1):
        media_type = "tv" if "name" in item else "movie"
        title = item.get("name") or item.get("title", "Unknown")
        media_id = str(item["id"])
        poster_path = item.get("poster_path")

        print(f"\n[{idx}/{len(all_content)}] Processing: {title} ({media_type})")
        print(f"  ID: {media_id}")

        if not poster_path:
            print(f"  ✗ No poster available")
            failed += 1
            continue

        # Download poster
        image = download_poster(poster_path)
        if image is None:
            failed += 1
            continue

        print(f"  ✓ Downloaded poster")

        # Generate embedding
        embedding = generate_embedding(image, model, processor, device)
        if embedding is None:
            failed += 1
            continue

        print(f"  ✓ Generated embedding: shape {embedding.shape}")
        database[media_id] = embedding
        successful += 1

    # Save database
    print(f"\n💾 Saving database...")
    if len(database) > 0:
        np.savez('movie_embeddings.npz',
                 ids=np.array(list(database.keys())),
                 embeddings=np.vstack(list(database.values())))

        print(f"✅ Database saved to movie_embeddings.npz")
        print(f"   {successful} items stored successfully")
        print(f"   {failed} items failed")
    else:
        print("❌ No embeddings generated, database not saved")

    # Print summary
    print("\n📊 Database Summary:")
    print(f"   Total processed: {len(all_content)}")
    print(f"   Successful: {successful}")
    print(f"   Failed: {failed}")
    print(f"   Success rate: {(successful/len(all_content)*100):.1f}%")

if __name__ == "__main__":
    main()
