#!/bin/bash
# Create a DMG installer for macOS distribution
# Run this after building with build_macos.sh

echo "💿 Creating DMG installer..."
echo "==========================="

# Check if .app exists
if [ ! -d "dist/WorkLog.app" ]; then
    echo "❌ Error: WorkLog.app not found in dist/"
    echo "Run ./build_macos.sh first"
    exit 1
fi

# Create temporary directory for DMG contents
echo "📁 Preparing DMG contents..."
mkdir -p dist/dmg
cp -r dist/WorkLog.app dist/dmg/
ln -s /Applications dist/dmg/Applications

# Create DMG
echo "🔨 Creating DMG..."
hdiutil create -volname "WorkLog" \
    -srcfolder dist/dmg \
    -ov -format UDZO \
    dist/WorkLog-macOS.dmg

# Clean up
rm -rf dist/dmg

if [ -f "dist/WorkLog-macOS.dmg" ]; then
    echo "✅ DMG created successfully!"
    echo "📂 Location: dist/WorkLog-macOS.dmg"
    echo ""
    echo "You can now distribute this DMG file to users."
else
    echo "❌ DMG creation failed!"
    exit 1
fi
