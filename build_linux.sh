#!/bin/bash
# =============================================================================
# Work Log Journal - Linux/Ubuntu Build Script
# Generates WorkLog (Linux standalone executable)
# =============================================================================

set -e  # Exit immediately if any command fails

VERSION=$(cat VERSION)
DIST_NAME="WorkLog_v${VERSION}_Linux"
ARCHIVE_NAME="${DIST_NAME}.tar.gz"

echo "============================================"
echo " Work Log Journal v${VERSION} - Linux Build"
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
echo "[4/5] Building WorkLog..."
pyinstaller --clean worklog_linux.spec

# ── 5. Package as tar.gz (for distribution) ───────────────────────────────────
echo "[5/5] Packaging as ${ARCHIVE_NAME}..."
cd dist
tar -czf "../${ARCHIVE_NAME}" WorkLog
cd ..

echo ""
echo "============================================"
echo " Build completed!"
echo "  Executable:  dist/WorkLog/WorkLog"
echo "  Package:     ${ARCHIVE_NAME}"
echo "============================================"
echo ""
echo "Usage:"
echo "  1. Extract: tar -xzf ${ARCHIVE_NAME}"
echo "  2. Run:     cd WorkLog && ./WorkLog"
echo "============================================"
