#!/usr/bin/env python3
"""
Build a real vector database from movie posters
Downloads posters from TMDB and generates CLIP embeddings
"""

import os
import requests
import numpy as np
import torch
from PIL import Image
from transformers import CLIPProcessor, CLIPModel
from io import BytesIO

# TMDB configuration
TMDB_API_KEY = os.getenv("TMDB_API_KEY", "YOUR_TMDB_API_KEY")
TMDB_IMAGE_BASE = "https://image.tmdb.org/t/p/w500"

# Movies to add
MOVIES = [
    {"id": "27205", "title": "Inception", "poster_path": "/xlaY2zyzMfkhk0HSC5VUwzoZPU1.jpg"},
    {"id": "157336", "title": "Interstellar", "poster_path": "/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg"},
    {"id": "299536", "title": "Avengers: Endgame", "poster_path": "/or06FN3Dka5tukK1e9sl16pB3iy.jpg"},
]

def download_poster(poster_path):
    """Download a poster image from TMDB"""
    url = f"{TMDB_IMAGE_BASE}{poster_path}"
    print(f"Downloading {url}...")
    response = requests.get(url)
    response.raise_for_status()
    return Image.open(BytesIO(response.content))

def generate_embedding(image, model, processor, device):
    """Generate CLIP embedding for an image"""
    inputs = processor(images=image, return_tensors="pt").to(device)

    with torch.no_grad():
        image_embedding = model.get_image_features(**inputs)

    # Normalize and convert to numpy
    image_embedding = image_embedding.cpu().numpy()
    image_embedding = image_embedding / np.linalg.norm(image_embedding)

    return image_embedding

def main():
    print("🎬 Building SnapnSee Vector Database")
    print("=" * 50)

    # Load CLIP model
    print("\n📦 Loading CLIP model...")
    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"Using device: {device}")

    model = CLIPModel.from_pretrained("openai/clip-vit-base-patch32").to(device)
    processor = CLIPProcessor.from_pretrained("openai/clip-vit-base-patch32")
    print("✅ CLIP model loaded")

    # Generate embeddings
    database = {}

    for movie in MOVIES:
        print(f"\n🎥 Processing: {movie['title']}")

        try:
            # Download poster
            image = download_poster(movie['poster_path'])
            print(f"  ✓ Downloaded poster")

            # Generate embedding
            embedding = generate_embedding(image, model, processor, device)
            print(f"  ✓ Generated embedding: shape {embedding.shape}")

            database[movie['id']] = embedding

        except Exception as e:
            print(f"  ✗ Error: {e}")

    # Save database
    print(f"\n💾 Saving database...")
    np.savez('movie_embeddings.npz',
             ids=np.array(list(database.keys())),
             embeddings=np.vstack(list(database.values())))

    print(f"✅ Database saved to movie_embeddings.npz")
    print(f"   {len(database)} movies stored")

    # Print stats
    print("\n📊 Database Contents:")
    for movie_id, embedding in database.items():
        movie = next(m for m in MOVIES if m['id'] == movie_id)
        print(f"  {movie_id}: {movie['title']} - embedding shape: {embedding.shape}")

if __name__ == "__main__":
    main()
