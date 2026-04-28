#!/bin/bash
# =============================================================================
# Work Log Journal - Universal Server Build Script
# Automatically detects platform (x86_64, ARM64, ARMv7) and builds accordingly
# =============================================================================

set -e

VERSION=$(cat VERSION)
ARCH=$(uname -m)          # x86_64, aarch64, armv7l, etc.
PLATFORM=""

# ── Detect Platform ──────────────────────────────────────────────────────────
case "$ARCH" in
    x86_64)
        PLATFORM="Linux-x86_64"
        IS_PI=false
        ;;
    aarch64)
        PLATFORM="RaspberryPi5-ARM64"
        IS_PI=true
        ;;
    armv7l)
        PLATFORM="RaspberryPi-ARMv7"
        IS_PI=true
        ;;
    *)
        PLATFORM="Linux-${ARCH}"
        IS_PI=false
        ;;
esac

DIST_NAME="WorkLogServer_v${VERSION}_${PLATFORM}"
ARCHIVE_NAME="${DIST_NAME}.tar.gz"
VENV_DIR=".venv_build"

echo "============================================"
echo " Work Log Server v${VERSION}"
echo " Platform: ${PLATFORM}"
echo " Architecture: ${ARCH}"
echo "============================================"
echo ""

# ── 1. Check Python ──────────────────────────────────────────────────────────
echo "[1/6] Checking Python environment..."
python3 --version || { echo "Error: python3 not found. Run: sudo apt install python3"; exit 1; }

# Install venv support if missing
if ! python3 -m venv --help &>/dev/null; then
    echo "  Installing python3-venv..."
    sudo apt-get update -qq
    sudo apt-get install -y python3-venv python3-dev
fi

# ── 2. Install system build dependencies ────────────────────────────────────
echo "[2/6] Installing system dependencies..."
if [ "$IS_PI" = true ]; then
    # Raspberry Pi needs additional build tools
    echo "  Detected Raspberry Pi - installing ARM build dependencies..."
    sudo apt-get install -y --no-install-recommends \
        libpq-dev gcc build-essential libffi-dev libssl-dev \
        zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev 2>/dev/null || true
else
    # Regular Linux
    sudo apt-get install -y --no-install-recommends \
        libpq-dev gcc build-essential 2>/dev/null || true
fi

# ── 3. Create/activate venv ──────────────────────────────────────────────────
echo "[3/6] Setting up virtual environment..."
if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
fi
source "${VENV_DIR}/bin/activate"
pip install --upgrade pip --quiet

# ── 4. Install Python dependencies ───────────────────────────────────────────
echo "[4/6] Installing Python dependencies..."
pip install -r requirements.txt --quiet
pip install pyinstaller --quiet

# ── 5. Build ──────────────────────────────────────────────────────────────────
echo "[5/6] Building WorkLogServer for ${PLATFORM}..."
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
echo " ✅ Build completed!"
echo "============================================"
echo "  Platform:    ${PLATFORM}"
echo "  Executable:  dist/WorkLogServer/WorkLogServer"
echo "  Package:     ${ARCHIVE_NAME}"
echo "============================================"
echo ""
echo "🚀 Quick start:"
echo "  cd dist/WorkLogServer && ./WorkLogServer"
echo ""
echo "🔧 Custom port:"
echo "  PORT=8080 ./WorkLogServer"
echo ""
if [ "$IS_PI" = true ]; then
    echo "🤖 Install as systemd service (auto-start on boot):"
    echo "  sudo bash setup_worklog_autostart.sh"
else
    echo "🤖 Run as systemd service:"
    echo "  sudo cp -r dist/WorkLogServer /opt/worklog/"
    echo "  sudo bash setup_worklog_autostart.sh"
fi
echo "============================================"
