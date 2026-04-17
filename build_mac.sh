#!/bin/bash
# =============================================================================
# Work Log Journal - macOS Build Script
# Generates WorkLog.app (macOS standalone application)
# =============================================================================

set -e  # Exit immediately if any command fails

VERSION=$(cat VERSION)
DIST_NAME="WorkLog_v${VERSION}_macOS"
ARCHIVE_NAME="${DIST_NAME}.zip"

echo "============================================"
echo " Work Log Journal v${VERSION} - macOS Build"
echo "============================================"
echo ""

# ── 1. Check Python Environment ──────────────────────────────────────────────
echo "[1/5] Checking Python environment..."
python3 --version || { echo "Error: python3 not found"; exit 1; }

# ── 2. Install/Check Dependencies ────────────────────────────────────────────
echo "[2/5] Installing dependencies..."
pip3 install -r requirements.txt --quiet
pip3 install pyinstaller --quiet

# ── 3. Clean Old Build Directories ───────────────────────────────────────────
echo "[3/5] Cleaning old build directories..."
python3 clean_build.py

# ── 4. Run PyInstaller Build ──────────────────────────────────────────────────
echo "[4/5] Building WorkLog.app..."
pyinstaller --clean worklog_mac.spec

# ── 5. Package as zip (for distribution) ──────────────────────────────────────
echo "[5/5] Packaging as ${ARCHIVE_NAME}..."
cd dist
zip -r "../${ARCHIVE_NAME}" "WorkLog.app" --quiet
cd ..

echo ""
echo "============================================"
echo " Build completed!"
echo "  App:      dist/WorkLog.app"
echo "  Package:  ${ARCHIVE_NAME}"
echo "============================================"
