# 🍎 macOS Build Instructions

## Prerequisites

1. **macOS Computer** (cannot build on Windows/Linux)
2. **Python 3.8+** installed
3. **Command Line Tools**: `xcode-select --install`

## Quick Start

```bash
# Make scripts executable
chmod +x build_macos.sh create_dmg.sh

# Build the application
./build_macos.sh

# (Optional) Create DMG installer
./create_dmg.sh
```

## Manual Build Steps

If you prefer to build manually:

```bash
# 1. Create virtual environment
python3 -m venv venv_macos
source venv_macos/bin/activate

# 2. Install dependencies
pip install --upgrade pip
pip install pyinstaller
pip install -r requirements.txt

# 3. Build the app
pyinstaller --clean worklog_macos.spec

# 4. Run the app
open dist/WorkLog.app
```

## Distribution

### Method 1: DMG Installer (Recommended)
```bash
./create_dmg.sh
```
This creates `dist/WorkLog-macOS.dmg` that users can download and install.

### Method 2: Direct .app Distribution
Compress the app and share:
```bash
cd dist
zip -r WorkLog-macOS.zip WorkLog.app
```

## Code Signing (Optional but Recommended)

For distribution outside the Mac App Store:

```bash
# 1. Get a Developer ID from Apple Developer Program
# 2. Sign the app
codesign --deep --force --verify --verbose \
    --sign "Developer ID Application: Your Name" \
    dist/WorkLog.app

# 3. Notarize with Apple
xcrun notarytool submit dist/WorkLog-macOS.dmg \
    --apple-id "your-email@example.com" \
    --team-id "YOUR_TEAM_ID" \
    --password "app-specific-password"
```

## Troubleshooting

### "Cannot be opened because the developer cannot be verified"
Users need to right-click → Open (first time only)

Or sign the app with your Developer ID (see Code Signing above)

### Build fails with "module not found"
Make sure all dependencies are installed:
```bash
pip install -r requirements.txt
```

### App crashes on launch
Check console logs:
```bash
open dist/WorkLog.app
# Then check Console.app for crash logs
```
