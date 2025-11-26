# SnapnSee iOS App

📸 Point your iPhone at a Netflix screen to instantly identify what's playing!

## Quick Start

### 1. Open in Xcode

Since we've created the Swift files manually, you'll need to create an Xcode project:

**Option A: Create New Project in Xcode**
1. Open Xcode
2. File → New → Project
3. Choose "iOS" → "App"
4. Fill in:
   - Product Name: `SnapnSee`
   - Team: Your development team
   - Organization Identifier: `com.yourname` (e.g., `com.mnavar`)
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: None
5. Save to: `/Users/mnavar/Work/coding/projects/snapnsee/snapnsee/ios/SnapnSee`
6. **Delete the auto-generated files** (ContentView.swift, SnapnSeeApp.swift, etc.)
7. **Add all the Swift files** from the `SnapnSee` folder:
   - Right-click on SnapnSee folder in Project Navigator
   - Add Files to "SnapnSee"
   - Select all `.swift` files
   - Check "Copy items if needed"

**Option B: Use Existing Files**
1. Open Xcode
2. File → New → Project → iOS → App
3. Create project as above
4. Replace generated files with the ones in `/Users/mnavar/Work/coding/projects/snapnsee/snapnsee/ios/SnapnSee/SnapnSee/`

### 2. Configure Info.plist

The Info.plist is already created with camera permissions. Make sure it's added to your Xcode project:

- Camera Usage: ✅ Already configured
- HTTP localhost: ✅ Already allowed for testing

### 3. Update API URL

Before deploying to a physical device, update the API URL in `Config.swift`:

```swift
// For local testing on simulator
static let API_BASE_URL = "http://localhost:8000"

// For testing on iPhone with Railway deployment
static let API_BASE_URL = "https://your-railway-url.up.railway.app"
```

### 4. Build & Run

**For Simulator (Testing UI only):**
- Select iPhone simulator
- Click Run (⌘R)
- Note: Camera won't work in simulator

**For Physical iPhone (Real testing):**
1. Connect iPhone via USB
2. Select your iPhone from device list
3. Trust computer on iPhone if prompted
4. Click Run (⌘R)
5. On iPhone: Settings → General → VPN & Device Management → Trust developer app

## Backend Setup

Make sure the backend is running before testing the app:

### Option 1: Local Backend (for testing)
```bash
cd /Users/mnavar/Work/coding/projects/snapnsee/snapnsee/backend
source venv/bin/activate
python3 main.py
```

### Option 2: Railway Deployment (for real iPhone testing)

1. **Deploy to Railway:**
   - Go to https://railway.app/dashboard
   - New Project → Empty Service
   - Link and deploy:
   ```bash
   cd /Users/mnavar/Work/coding/projects/snapnsee/snapnsee/backend
   railway link
   railway up
   ```
   - Add environment variable: `TMDB_API_KEY` = `7a78bacb21c745a4ce5f9093dcf08cc9`

2. **Update iOS Config:**
   - Copy your Railway URL (e.g., `https://snapnsee-production.up.railway.app`)
   - Update `Config.swift` with the Railway URL

## Project Structure

```
SnapnSee/
├── SnapnSeeApp.swift       # App entry point
├── ContentView.swift       # Main UI with camera trigger
├── CameraView.swift        # Camera capture with live preview
├── ResultView.swift        # Results display
├── Models.swift            # Data models for API responses
├── APIService.swift        # Network requests to backend
├── Config.swift            # API URL configuration
├── Info.plist             # Permissions & app config
└── Assets.xcassets/       # App icons and assets
```

## Features

- ✅ **Live Camera Preview**: Real-time camera feed with capture button
- ✅ **Image Capture**: Take photos of TV screens
- ✅ **API Integration**: Sends images to backend for recognition
- ✅ **Beautiful Results**: Shows movie/show details with ratings and overview
- ✅ **Error Handling**: Graceful error messages
- ✅ **Confidence Scoring**: Color-coded match confidence badges

## Testing Tips

1. **Best Results:**
   - Point camera at clear title screens
   - Ensure good lighting
   - Keep camera steady

2. **What Works:**
   - Netflix detail screens with clean titles
   - Movie posters with visible text
   - Shows in the 50-movie database

3. **Current Limitations:**
   - Only 50 Netflix titles in database
   - Stylized logos may not be recognized
   - Text over complex backgrounds can fail OCR

## Troubleshooting

**"Connection error"**
- Make sure backend is running
- Check API URL in Config.swift
- For iPhone: Use Railway URL, not localhost

**Camera not working**
- Only works on physical iPhone (not simulator)
- Check camera permissions in Settings

**"Could not identify"**
- Try a clearer shot of the title screen
- Check if the show is in the database
- Ensure good lighting

## Next Steps

1. Deploy backend to Railway
2. Update Config.swift with Railway URL
3. Build to iPhone
4. Test by pointing at Netflix TV screen
5. Celebrate when it works! 🎉
