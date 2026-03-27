#!/bin/bash
# Build script for macOS application
# Run this on macOS to create a .app bundle

echo "🍎 Building WorkLog for macOS..."
echo "================================"

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "⚠️  Warning: This script should be run on macOS"
    echo "Current OS: $OSTYPE"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: Python 3 is not installed"
    exit 1
fi

# Create virtual environment if it doesn't exist
if [ ! -d "venv_macos" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv_macos
fi

# Activate virtual environment
echo "🔄 Activating virtual environment..."
source venv_macos/bin/activate

# Install dependencies
echo "📥 Installing dependencies..."
pip install --upgrade pip
pip install pyinstaller
pip install -r requirements.txt

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf build dist WorkLog.app

# Build the application
echo "🔨 Building application..."
pyinstaller --clean worklog_macos.spec

# Check if build was successful
if [ -d "dist/WorkLog.app" ]; then
    echo "✅ Build successful!"
    echo "📂 Application location: dist/WorkLog.app"
    echo ""
    echo "To run the app:"
    echo "  open dist/WorkLog.app"
    echo ""
    echo "To create a DMG installer:"
    echo "  ./create_dmg.sh"
else
    echo "❌ Build failed!"
    exit 1
fi

deactivate
