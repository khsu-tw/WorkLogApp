#!/bin/bash
# =============================================================================
# Work Log Journal - Linux Headless Server Build Script
# Generates WorkLogServer (no GUI, suitable for systemd service)
# =============================================================================

set -e

VERSION=$(cat VERSION)
DIST_NAME="WorkLogServer_v${VERSION}_Linux"
ARCHIVE_NAME="${DIST_NAME}.tar.gz"
VENV_DIR=".venv_build"

echo "============================================"
echo " Work Log Server v${VERSION} - Linux Build"
echo "============================================"
echo ""

echo "[1/5] Checking Python environment..."
python3 --version || { echo "Error: python3 not found"; exit 1; }

if ! python3 -m venv --help &>/dev/null; then
    echo "  python3-venv not found. Installing..."
    sudo apt-get install -y python3-venv
fi

if [ ! -d "$VENV_DIR" ]; then
    echo "  Creating build venv at ${VENV_DIR}..."
    python3 -m venv "$VENV_DIR"
fi

source "${VENV_DIR}/bin/activate"
echo "  Using Python: $(which python3)"

echo "[2/5] Installing dependencies..."
pip install --upgrade pip --quiet
pip install -r requirements.txt --quiet
pip install pyinstaller --quiet

echo "[3/5] Cleaning old build directories..."
python3 clean_build.py WorkLogServer

echo "[4/5] Building WorkLogServer..."
pyinstaller --clean docs/build/worklog_server_linux.spec

echo "[5/5] Packaging as ${ARCHIVE_NAME}..."
cd dist
tar -czf "../${ARCHIVE_NAME}" WorkLogServer
cd ..

deactivate

echo ""
echo "============================================"
echo " Build completed!"
echo "  Executable:  dist/WorkLogServer/WorkLogServer"
echo "  Package:     ${ARCHIVE_NAME}"
echo "============================================"
echo ""
echo "Usage:"
echo "  1. Extract: tar -xzf ${ARCHIVE_NAME}"
echo "  2. Run:     cd WorkLogServer && ./WorkLogServer"
echo "  3. Custom port: PORT=8080 ./WorkLogServer"
echo ""
echo "To run as systemd service:"
echo "  sudo cp worklog.service /etc/systemd/system/"
echo "  sudo systemctl enable --now worklog"
echo "============================================"
