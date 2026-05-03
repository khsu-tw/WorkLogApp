#!/bin/bash
# =============================================================================
# Work Log Journal - Universal Server Build Script
# Automatically detects platform (x86_64, ARM64, ARMv7) and builds accordingly
#
# Usage:
#   bash build_server.sh             # build only
#   sudo bash build_server.sh --deploy
#                                   # build, then auto-detect install state:
#                                   #   - first install  → invoke setup_worklog_server_autostart.sh
#                                   #   - already installed → invoke update_worklog_server.sh
# =============================================================================

set -e

# ── Parse arguments ──────────────────────────────────────────────────────────
DEPLOY_MODE=false
for arg in "$@"; do
    case "$arg" in
        --deploy) DEPLOY_MODE=true ;;
        -h|--help)
            head -n 13 "$0" | tail -n 11
            exit 0
            ;;
    esac
done

VERSION=$(cat VERSION)
ARCH=$(uname -m)          # x86_64, aarch64, armv7l, etc.
PLATFORM=""

# ── Warn if source tree is behind remote ─────────────────────────────────────
if [ -d ".git" ]; then
    git fetch --quiet 2>/dev/null || true
    LOCAL_HEAD=$(git rev-parse HEAD 2>/dev/null || echo "")
    REMOTE_HEAD=$(git rev-parse '@{u}' 2>/dev/null || echo "")
    if [ -n "$LOCAL_HEAD" ] && [ -n "$REMOTE_HEAD" ] && [ "$LOCAL_HEAD" != "$REMOTE_HEAD" ]; then
        echo "⚠  WARNING: local HEAD differs from remote — you may not be building the latest code."
        echo "   Run: git pull    (then re-run this script)"
        echo ""
        read -p "Continue anyway with VERSION=${VERSION}? (y/N) " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then exit 1; fi
    fi
fi

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

# ── Verify version bundled into the build ───────────────────────────────────
BUNDLED_VERSION=""
for p in dist/WorkLogServer/_internal/VERSION dist/WorkLogServer/VERSION; do
    if [ -f "$p" ]; then BUNDLED_VERSION=$(cat "$p" 2>/dev/null); break; fi
done
if [ "$BUNDLED_VERSION" != "$VERSION" ]; then
    echo "⚠  WARNING: bundled VERSION ('${BUNDLED_VERSION}') != source VERSION ('${VERSION}')"
    echo "   Something is wrong with the build; the deployed server may report the wrong version."
else
    echo "  ✓ Bundled VERSION verified: ${BUNDLED_VERSION}"
fi

echo ""
echo "============================================"
echo " ✅ Build completed!"
echo "============================================"
echo "  Platform:    ${PLATFORM}"
echo "  Executable:  dist/WorkLogServer/WorkLogServer"
echo "  Package:     ${ARCHIVE_NAME}"
echo "============================================"
echo ""

# ── 7. Optional deploy ───────────────────────────────────────────────────────
if [ "$DEPLOY_MODE" = true ]; then
    # --deploy requires root to manage systemd
    if [ "$EUID" -ne 0 ]; then
        echo "⚠  --deploy requires root. Re-run as: sudo bash $0 --deploy"
        exit 1
    fi

    SERVICE_NAME="worklog.service"
    TARGET_DIR="/home/khsu/worklog-server"

    # Detect install state
    if systemctl list-unit-files 2>/dev/null | grep -q "^${SERVICE_NAME}" && [ -f "${TARGET_DIR}/WorkLogServer" ]; then
        echo "[7/7] Detected existing install → running update_worklog_server.sh"
        echo ""
        # update script expects interactive confirm; pipe "y" to auto-accept
        yes y | bash "$(dirname "$0")/update_worklog_server.sh"
    else
        echo "[7/7] No existing install detected → running first-time setup"
        echo ""
        mkdir -p "${TARGET_DIR}"
        cp -r dist/WorkLogServer/* "${TARGET_DIR}/"
        chmod +x "${TARGET_DIR}/WorkLogServer"
        chown -R khsu:khsu "${TARGET_DIR}" 2>/dev/null || true
        bash "$(dirname "$0")/setup_worklog_server_autostart.sh"
    fi
    # Verify the running server reports the expected version
    sleep 2
    RUNNING_VERSION=$(curl -s http://localhost:5000/api/config 2>/dev/null | python3 -c "import json,sys; print(json.load(sys.stdin).get('version',''))" 2>/dev/null || echo "")
    echo ""
    echo "============================================"
    echo " ✅ Deploy completed!"
    echo "============================================"
    if [ -n "$RUNNING_VERSION" ]; then
        if [ "$RUNNING_VERSION" = "$VERSION" ]; then
            echo "  ✓ Running server reports version: ${RUNNING_VERSION}"
        else
            echo "  ⚠  Running server reports '${RUNNING_VERSION}' but expected '${VERSION}'"
            echo "     Try: sudo systemctl restart worklog.service"
        fi
    else
        echo "  (could not reach http://localhost:5000/api/config to verify version)"
    fi
    echo "============================================"
else
    echo "🚀 Quick start:"
    echo "  cd dist/WorkLogServer && ./WorkLogServer"
    echo ""
    echo "🔧 Custom port:"
    echo "  PORT=8080 ./WorkLogServer"
    echo ""
    echo "🤖 Install or update via systemd (auto-detects install state):"
    echo "  sudo bash $0 --deploy"
    echo ""
    echo "🔍 Diagnose runtime issues:"
    echo "  sudo bash diagnose_worklog.sh"
    echo "============================================"
fi
