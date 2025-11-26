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
- **AI Vision**: GPT-4o Vision API for intelligent image recognition
- **Metadata**: TMDB API integration for movie/show details
- **Lightweight**: No local models or embeddings - ~50MB deployment

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

2. **Set API Keys:**
```bash
echo "TMDB_API_KEY=your_tmdb_key_here" > .env
echo "OPENAI_API_KEY=your_openai_key_here" >> .env
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

Add environment variables in Railway dashboard:
- `TMDB_API_KEY` = `your_tmdb_api_key`
- `OPENAI_API_KEY` = `your_openai_api_key`

Then update `ios/SnapnSee/SnapnSee/Config.swift` with your Railway URL.

## 🎓 How It Works

### Recognition Pipeline

1. **Image Capture**: iPhone camera captures TV screen
2. **AI Vision Recognition**:
   - GPT-4o Vision analyzes the image
   - Identifies title, media type, and release year
   - Returns confidence score and reasoning
3. **TMDB Verification**:
   - Searches TMDB with identified title
   - Filters by media type and year
   - Fetches detailed metadata
4. **Result Display**: Shows movie/show details with rating, overview, and confidence

## 🔮 Future Enhancements

- [ ] Support other streaming services (Disney+, Hulu, HBO, Prime Video)
- [ ] Real-time continuous scanning mode
- [ ] User history and favorites
- [ ] Social sharing features
- [ ] Offline caching of recent results
- [ ] Multi-language support

## 📊 Current Limitations

- **API Cost**: ~$0.01-0.02 per recognition (GPT-4o Vision pricing)
- **Latency**: 2-4 seconds per request (depends on OpenAI API)
- **Accuracy**: GPT-4o may hallucinate occasionally - always verify with TMDB
- **Privacy**: Images are sent to OpenAI for processing

## 🛠️ Tech Stack

**Backend:**
- Python 3.11
- FastAPI (API framework)
- OpenAI GPT-4o Vision (image recognition)
- TMDB API (metadata)
- Pillow (image processing)

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
