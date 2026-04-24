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
VENV_DIR=".venv_build"
if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
fi
source "$VENV_DIR/bin/activate"
pip install -r requirements.txt --quiet
pip install pyinstaller --quiet

# ── 3. Clean Old Build Directories ───────────────────────────────────────────
echo "[3/5] Cleaning old build directories..."
python3 clean_build.py

# ── 4. Run PyInstaller Build ──────────────────────────────────────────────────
echo "[4/5] Building WorkLog.app..."
pyinstaller --clean docs/build/worklog_mac.spec

# ── 5. Package as zip (for distribution) ──────────────────────────────────────
echo "[5/5] Packaging as ${ARCHIVE_NAME}..."
# Clear resource forks (iCloud Drive directories may re-add FinderInfo xattrs,
# so the bundle-level sign is attempted but non-fatal — inner binaries are already
# signed by PyInstaller)
dot_clean -m dist/WorkLog.app
xattr -rd com.apple.FinderInfo dist/WorkLog.app 2>/dev/null || true
xattr -rd "com.apple.fileprovider.fpfs#P" dist/WorkLog.app 2>/dev/null || true
codesign -s - --force --deep dist/WorkLog.app 2>/dev/null \
    || echo "  [Note] Bundle ad-hoc sign skipped (iCloud xattr conflict — inner binaries are already signed)"
zip -r "${ARCHIVE_NAME}" "dist/WorkLog.app" --quiet

echo ""
echo "============================================"
echo " Build completed!"
echo "  App:      dist/WorkLog.app"
echo "  Package:  ${ARCHIVE_NAME}"
echo "============================================"
