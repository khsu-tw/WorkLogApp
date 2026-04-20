#!/bin/bash
# =============================================================================
# PocketBase Auto-Start Setup Script for Raspberry Pi
# =============================================================================
# This script sets up PocketBase to automatically start on boot using systemd
#
# Usage:
#   1. Transfer this script to your Raspberry Pi
#   2. Make it executable: chmod +x setup_pocketbase_autostart.sh
#   3. Run it: ./setup_pocketbase_autostart.sh
# =============================================================================

set -e  # Exit on error

echo "============================================"
echo " PocketBase Auto-Start Setup"
echo "============================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
POCKETBASE_USER="khsu"
POCKETBASE_DIR="/home/khsu/pocketbase"
POCKETBASE_BIN="${POCKETBASE_DIR}/pocketbase"
SERVICE_FILE="/etc/systemd/system/pocketbase.service"

echo "Configuration:"
echo "  User: ${POCKETBASE_USER}"
echo "  Directory: ${POCKETBASE_DIR}"
echo "  Binary: ${POCKETBASE_BIN}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
   echo -e "${RED}Error: This script must be run as root (use sudo)${NC}"
   exit 1
fi

# Step 1: Verify PocketBase exists
echo "[1/6] Verifying PocketBase installation..."
if [ ! -f "${POCKETBASE_BIN}" ]; then
    echo -e "${RED}Error: PocketBase binary not found at ${POCKETBASE_BIN}${NC}"
    exit 1
fi
echo -e "${GREEN}✓ PocketBase binary found${NC}"
echo ""

# Step 2: Stop any running PocketBase processes
echo "[2/6] Stopping existing PocketBase processes..."
pkill pocketbase || true
sleep 2
echo -e "${GREEN}✓ Existing processes stopped${NC}"
echo ""

# Step 3: Create systemd service file
echo "[3/6] Creating systemd service file..."
cat > "${SERVICE_FILE}" << 'EOF'
[Unit]
Description=PocketBase Service
Documentation=https://pocketbase.io/docs/
After=network.target

[Service]
Type=simple
User=khsu
Group=khsu
WorkingDirectory=/home/khsu/pocketbase
ExecStart=/home/khsu/pocketbase/pocketbase serve --http=0.0.0.0:8090
Restart=always
RestartSec=5
StandardOutput=append:/home/khsu/pocketbase/pocketbase.log
StandardError=append:/home/khsu/pocketbase/pocketbase_error.log

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=read-only
ReadWritePaths=/home/khsu/pocketbase

# Resource limits
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

echo -e "${GREEN}✓ Service file created at ${SERVICE_FILE}${NC}"
echo ""

# Step 4: Set proper permissions
echo "[4/6] Setting permissions..."
chmod 644 "${SERVICE_FILE}"
chown "${POCKETBASE_USER}:${POCKETBASE_USER}" "${POCKETBASE_DIR}" -R
echo -e "${GREEN}✓ Permissions set${NC}"
echo ""

# Step 5: Enable and start service
echo "[5/6] Enabling and starting PocketBase service..."
systemctl daemon-reload
systemctl enable pocketbase
systemctl start pocketbase
sleep 3
echo -e "${GREEN}✓ Service enabled and started${NC}"
echo ""

# Step 6: Verify service status
echo "[6/6] Verifying service status..."
if systemctl is-active --quiet pocketbase; then
    echo -e "${GREEN}✓ PocketBase service is running!${NC}"
    echo ""
    systemctl status pocketbase --no-pager -l
    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN} Setup completed successfully!${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    echo "PocketBase is now configured to start automatically on boot."
    echo ""
    echo "Useful commands:"
    echo "  • Check status:       sudo systemctl status pocketbase"
    echo "  • Stop service:       sudo systemctl stop pocketbase"
    echo "  • Restart service:    sudo systemctl restart pocketbase"
    echo "  • View logs:          sudo journalctl -u pocketbase -f"
    echo "  • View output log:    tail -f ${POCKETBASE_DIR}/pocketbase.log"
    echo "  • Disable auto-start: sudo systemctl disable pocketbase"
    echo ""
    echo "Access PocketBase admin UI:"
    echo "  • Local:              http://localhost:8090/_/"
    echo "  • Network (Pi):       http://192.168.0.105:8090/_/"
    echo ""
else
    echo -e "${RED}✗ Service failed to start${NC}"
    echo ""
    echo "Checking logs:"
    journalctl -u pocketbase -n 20 --no-pager
    exit 1
fi
