#!/bin/bash
# =============================================================================
# Work Log Journal - Raspberry Pi Build Script (ARMv7 / ARM64)
# Run this script DIRECTLY ON the Raspberry Pi to build a native executable.
# =============================================================================

set -e

VERSION=$(cat VERSION)
ARCH=$(uname -m)          # armv7l or aarch64
DIST_NAME="WorkLogServer_v${VERSION}_${ARCH}"
ARCHIVE_NAME="${DIST_NAME}.tar.gz"
VENV_DIR=".venv_build"

echo "============================================"
echo " Work Log Server v${VERSION} - Pi Build"
echo " Architecture: ${ARCH}"
echo "============================================"
echo ""

# ── 1. Check Python ──────────────────────────────────────────────────────────
echo "[1/5] Checking Python environment..."
python3 --version || { echo "Error: python3 not found. Run: sudo apt install python3"; exit 1; }

# Install venv support if missing
if ! python3 -m venv --help &>/dev/null; then
    echo "  Installing python3-venv..."
    sudo apt-get install -y python3-venv python3-dev
fi

# ── 2. Install system build dependencies ────────────────────────────────────
echo "[2/5] Installing system dependencies..."
sudo apt-get install -y --no-install-recommends \
    libpq-dev gcc build-essential libffi-dev libssl-dev 2>/dev/null || true

# ── 3. Create/activate venv ──────────────────────────────────────────────────
echo "[3/5] Setting up virtual environment..."
if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
fi
source "${VENV_DIR}/bin/activate"
pip install --upgrade pip --quiet

# ── 4. Install Python dependencies ───────────────────────────────────────────
echo "[4/5] Installing Python dependencies..."
pip install -r requirements.txt --quiet
pip install pyinstaller --quiet

# ── 5. Build ──────────────────────────────────────────────────────────────────
echo "[5/5] Building WorkLogServer for ${ARCH}..."
python3 clean_build.py WorkLogServer 2>/dev/null || true
pyinstaller --clean docs/build/worklog_server_linux.spec

# ── 6. Package ────────────────────────────────────────────────────────────────
echo "[6/6] Packaging as ${ARCHIVE_NAME}..."
cd dist
tar -czf "../${ARCHIVE_NAME}" WorkLogServer
cd ..

deactivate

echo ""
echo "============================================"
echo " Build completed!"
echo "  Executable: dist/WorkLogServer/WorkLogServer"
echo "  Package:    ${ARCHIVE_NAME}"
echo "============================================"
echo ""
echo "Quick start:"
echo "  cd dist/WorkLogServer && ./WorkLogServer"
echo ""
echo "Custom port:"
echo "  PORT=8080 ./WorkLogServer"
echo ""
echo "Install as systemd service:"
echo "  sudo bash setup_worklog_autostart.sh"
echo "============================================"
