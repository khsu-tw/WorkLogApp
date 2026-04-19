#!/bin/bash
# =============================================================================
# Work Log Journal - Linux/Ubuntu Build Script
# Generates WorkLog (Linux standalone executable)
# =============================================================================

set -e  # Exit immediately if any command fails

VERSION=$(cat VERSION)
DIST_NAME="WorkLog_v${VERSION}_Linux"
ARCHIVE_NAME="${DIST_NAME}.tar.gz"
VENV_DIR=".venv_build"

echo "============================================"
echo " Work Log Journal v${VERSION} - Linux Build"
echo "============================================"
echo ""

# ── 1. Check Python Environment ──────────────────────────────────────────────
echo "[1/5] Checking Python environment..."
python3 --version || { echo "Error: python3 not found"; exit 1; }

# Ensure python3-venv is available
if ! python3 -m venv --help &>/dev/null; then
    echo "  python3-venv not found. Installing..."
    sudo apt-get install -y python3-venv
fi

# Create (or reuse) isolated build venv
if [ ! -d "$VENV_DIR" ]; then
    echo "  Creating build venv at ${VENV_DIR}..."
    python3 -m venv "$VENV_DIR"
fi

# Activate venv — all subsequent pip/python/pyinstaller calls use it
source "${VENV_DIR}/bin/activate"
echo "  Using Python: $(which python3)"

# ── 2. Install/Check Dependencies ────────────────────────────────────────────
echo "[2/5] Installing dependencies..."
pip install --upgrade pip --quiet
pip install -r requirements.txt --quiet
pip install pyinstaller --quiet

# ── 3. Clean Old Build Directories ───────────────────────────────────────────
echo "[3/5] Cleaning old build directories..."
python3 clean_build.py

# ── 4. Run PyInstaller Build ──────────────────────────────────────────────────
echo "[4/5] Building WorkLog..."
pyinstaller --clean docs/build/worklog_linux.spec

# ── 5. Package as tar.gz (for distribution) ───────────────────────────────────
echo "[5/5] Packaging as ${ARCHIVE_NAME}..."
cd dist
tar -czf "../${ARCHIVE_NAME}" WorkLog
cd ..

deactivate

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
