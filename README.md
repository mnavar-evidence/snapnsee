# 📸 SnapnSee

**Snap the screen. Know the vibe.**

SnapnSee is an AI-powered app that identifies movies and TV shows from Netflix screenshots. Point your iPhone camera at a TV screen, and instantly get detailed information about what's playing.

## 🎯 Features

- **📷 Camera Recognition**: Point your iPhone at any Netflix screen
- **🤖 Hybrid AI**: Text extraction (OCR) + Visual embeddings (CLIP)
- **🎬 Rich Metadata**: Fetches details from TMDB (ratings, overview, release date)
- **⚡ Fast**: Real-time processing with confidence scores
- **📱 Native iOS**: Beautiful SwiftUI interface

## 🏗️ Architecture

### Backend (Python + FastAPI)
- **OCR**: EasyOCR for text extraction from title screens
- **Visual Recognition**: OpenAI's CLIP model for image embeddings
- **Vector Database**: 50 popular Netflix titles with pre-computed embeddings
- **Metadata**: TMDB API integration for movie/show details

### iOS App (Swift + SwiftUI)
- **Camera**: Live preview with AVFoundation
- **API Integration**: Async/await networking
- **UI**: Gradient design with results view

## 📁 Project Structure

```
snapnsee/
├── backend/                 # Python FastAPI backend
│   ├── main.py             # API endpoints & recognition logic
│   ├── build_db.py         # Generate movie embeddings database
│   ├── test_app.html       # Web testing interface
│   ├── requirements.txt    # Python dependencies
│   ├── Procfile           # Railway deployment config
│   └── movie_embeddings.npz # Vector database (50 titles)
│
└── ios/                    # iOS app
    ├── SnapnSee/
    │   ├── SnapnSeeApp.swift    # App entry
    │   ├── ContentView.swift    # Main UI
    │   ├── CameraView.swift     # Camera capture
    │   ├── ResultView.swift     # Results display
    │   ├── APIService.swift     # Backend integration
    │   ├── Models.swift         # Data models
    │   ├── Config.swift         # API configuration
    │   └── Info.plist          # Permissions
    └── README.md           # iOS setup guide
```

## 🚀 Quick Start

### Backend Setup

1. **Install dependencies:**
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

2. **Set TMDB API Key:**
```bash
echo "TMDB_API_KEY=your_key_here" > .env
```

3. **Run locally:**
```bash
python3 main.py
# Access at http://localhost:8000
```

4. **Test via web interface:**
```
Open http://localhost:8000/test
```

### iOS App Setup

See detailed instructions in [`ios/README.md`](ios/README.md)

1. Open Xcode → New Project → iOS App
2. Add all Swift files from `ios/SnapnSee/SnapnSee/`
3. Update `Config.swift` with backend URL
4. Build to iPhone and test!

## 🌐 Deployment

### Deploy Backend to Railway

```bash
cd backend
railway login
railway init
railway up
```

Add environment variable in Railway dashboard:
- `TMDB_API_KEY` = `your_tmdb_api_key`

Then update `ios/SnapnSee/SnapnSee/Config.swift` with your Railway URL.

## 🎓 How It Works

### Recognition Pipeline

1. **Image Capture**: iPhone camera captures TV screen
2. **Text Extraction** (Primary):
   - EasyOCR extracts visible text
   - Smart filtering finds title candidates
   - TMDB search matches title
3. **Visual Matching** (Fallback):
   - CLIP model generates image embedding
   - Cosine similarity search in vector database
   - Returns best match above 90% threshold
4. **Metadata Fetch**: TMDB API enriches result with details

### Current Database

50 popular Netflix titles including:
- Memoirs of a Geisha
- Inception
- Interstellar
- The Matrix
- Breaking Bad
- Stranger Things
- And more...

## 🔮 Future Enhancements

- [ ] Expand database to 1000+ titles
- [ ] Add logo recognition for branded content
- [ ] Support other streaming services (Disney+, Hulu, HBO)
- [ ] Real-time continuous scanning
- [ ] User history and favorites
- [ ] Social sharing features

## 📊 Current Limitations

- **Database Size**: Only 50 titles in vector database
- **OCR Accuracy**: Struggles with stylized fonts and logos
- **Background Complexity**: Text over busy backgrounds may fail
- **Lighting**: Needs decent lighting for best results

## 🛠️ Tech Stack

**Backend:**
- Python 3.11
- FastAPI (API framework)
- CLIP (openai/clip-vit-base-patch32)
- EasyOCR (text extraction)
- NumPy & scikit-learn (vector operations)
- TMDB API (metadata)

**iOS:**
- Swift 5.9+
- SwiftUI (UI framework)
- AVFoundation (camera)
- URLSession (networking)

**Infrastructure:**
- Railway (backend hosting)
- GitHub (version control)

## 📝 License

MIT License - feel free to use and modify!

## 👤 Author

Created by M Navar

---

**Ready to try it?** Point your iPhone at a Netflix screen and see the magic happen! ✨
