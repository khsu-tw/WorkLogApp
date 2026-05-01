#!/bin/bash
# =============================================================================
# WorkLogServer Auto-Start Setup Script for Raspberry Pi
# =============================================================================
# This script sets up WorkLogServer to automatically start on boot using systemd
#
# Usage:
#   1. Transfer this script and the WorkLogServer binary to your Raspberry Pi
#   2. Make it executable: chmod +x setup_worklog_autostart.sh
#   3. Run it: sudo ./setup_worklog_autostart.sh
# =============================================================================

set -e  # Exit on error

echo "============================================"
echo " WorkLogServer Auto-Start Setup"
echo "============================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
WORKLOG_USER="khsu"
WORKLOG_DIR="/home/khsu/worklog-server"
WORKLOG_BIN="${WORKLOG_DIR}/WorkLogServer"
WORKLOG_PORT="${PORT:-5000}"
SERVICE_NAME="worklog"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

echo "Configuration:"
echo "  User:      ${WORKLOG_USER}"
echo "  Directory: ${WORKLOG_DIR}"
echo "  Binary:    ${WORKLOG_BIN}"
echo "  Port:      ${WORKLOG_PORT}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root (use sudo)${NC}"
    exit 1
fi

# Step 1: Verify WorkLogServer binary exists
echo "[1/6] Verifying WorkLogServer installation..."
if [ ! -f "${WORKLOG_BIN}" ]; then
    echo -e "${RED}Error: WorkLogServer binary not found at ${WORKLOG_BIN}${NC}"
    echo ""
    echo "Please extract the release archive first:"
    echo "  mkdir -p ${WORKLOG_DIR}"
    echo "  tar -xzf WorkLogServer_v*_Linux.tar.gz -C ${WORKLOG_DIR} --strip-components=1"
    exit 1
fi
chmod +x "${WORKLOG_BIN}"
echo -e "${GREEN}✓ WorkLogServer binary found${NC}"
echo ""

# Step 2: Stop any running WorkLogServer processes
echo "[2/6] Stopping existing WorkLogServer processes..."
systemctl stop "${SERVICE_NAME}" 2>/dev/null || true
pkill WorkLogServer 2>/dev/null || true
sleep 2
echo -e "${GREEN}✓ Existing processes stopped${NC}"
echo ""

# Step 2.5: Check if port is in use
echo "[2.5/6] Checking if port ${WORKLOG_PORT} is available..."
PORT_IN_USE=$(lsof -ti:${WORKLOG_PORT} 2>/dev/null || true)

if [ ! -z "${PORT_IN_USE}" ]; then
    echo -e "${YELLOW}⚠ Port ${WORKLOG_PORT} is currently in use${NC}"
    echo ""
    echo "Process details:"
    ps -p ${PORT_IN_USE} -o pid,user,cmd --no-headers
    echo ""

    # Ask user if they want to kill the process
    read -p "Do you want to terminate this process? (Y/n): " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        echo "Terminating process ${PORT_IN_USE}..."
        kill -9 ${PORT_IN_USE} 2>/dev/null || true
        sleep 1
        echo -e "${GREEN}✓ Process terminated${NC}"
        echo ""
    else
        echo ""
        echo -e "${YELLOW}Please specify a different port for WorkLogServer:${NC}"
        read -p "Enter port number (default: 5000): " NEW_PORT

        # Validate port number
        if [ -z "${NEW_PORT}" ]; then
            NEW_PORT=5000
        fi

        if ! [[ "${NEW_PORT}" =~ ^[0-9]+$ ]] || [ "${NEW_PORT}" -lt 1024 ] || [ "${NEW_PORT}" -gt 65535 ]; then
            echo -e "${RED}Error: Invalid port number. Must be between 1024 and 65535${NC}"
            exit 1
        fi

        # Check if new port is also in use
        NEW_PORT_IN_USE=$(lsof -ti:${NEW_PORT} 2>/dev/null || true)
        if [ ! -z "${NEW_PORT_IN_USE}" ]; then
            echo -e "${RED}Error: Port ${NEW_PORT} is also in use${NC}"
            echo "Please free up the port manually or choose another port"
            exit 1
        fi

        WORKLOG_PORT="${NEW_PORT}"
        echo -e "${GREEN}✓ Will use port ${WORKLOG_PORT}${NC}"
        echo ""
    fi
else
    echo -e "${GREEN}✓ Port ${WORKLOG_PORT} is available${NC}"
    echo ""
fi

# Step 3: Create systemd service file
echo "[3/6] Creating systemd service file..."
cat > "${SERVICE_FILE}" << EOF
[Unit]
Description=WorkLog Server
After=network.target

[Service]
Type=simple
User=${WORKLOG_USER}
Group=${WORKLOG_USER}
WorkingDirectory=${WORKLOG_DIR}
ExecStart=${WORKLOG_BIN}
Environment=PORT=${WORKLOG_PORT}
Restart=always
RestartSec=5
StandardOutput=append:${WORKLOG_DIR}/worklog.log
StandardError=append:${WORKLOG_DIR}/worklog_error.log

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=read-only
ReadWritePaths=${WORKLOG_DIR}

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
chown -R "${WORKLOG_USER}:${WORKLOG_USER}" "${WORKLOG_DIR}"
echo -e "${GREEN}✓ Permissions set${NC}"
echo ""

# Step 5: Enable and start service
echo "[5/6] Enabling and starting WorkLogServer service..."
systemctl daemon-reload
systemctl enable "${SERVICE_NAME}"
systemctl start "${SERVICE_NAME}"
sleep 3
echo -e "${GREEN}✓ Service enabled and started${NC}"
echo ""

# Step 6: Verify service status
echo "[6/6] Verifying service status..."
if systemctl is-active --quiet "${SERVICE_NAME}"; then
    echo -e "${GREEN}✓ WorkLogServer is running!${NC}"
    echo ""
    systemctl status "${SERVICE_NAME}" --no-pager -l
    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN} Setup completed successfully!${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    echo "WorkLogServer is now configured to start automatically on boot."
    echo ""
    echo "Useful commands:"
    echo "  • Check status:       sudo systemctl status ${SERVICE_NAME}"
    echo "  • Stop service:       sudo systemctl stop ${SERVICE_NAME}"
    echo "  • Restart service:    sudo systemctl restart ${SERVICE_NAME}"
    echo "  • View logs:          sudo journalctl -u ${SERVICE_NAME} -f"
    echo "  • View output log:    tail -f ${WORKLOG_DIR}/worklog.log"
    echo "  • Disable auto-start: sudo systemctl disable ${SERVICE_NAME}"
    echo ""
    echo "Access WorkLogServer:"
    echo "  • Local:              http://localhost:${WORKLOG_PORT}"
    echo "  • Network (Pi):       http://$(hostname -I | awk '{print $1}'):${WORKLOG_PORT}"
    echo ""
else
    echo -e "${RED}✗ Service failed to start${NC}"
    echo ""
    echo "Checking logs:"
    journalctl -u "${SERVICE_NAME}" -n 20 --no-pager
    exit 1
fi
