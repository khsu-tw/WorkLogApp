#!/bin/bash
# =============================================================================
# WorkLogServer Diagnostic Script
# =============================================================================
# This script helps diagnose connectivity and runtime issues with WorkLogServer
#
# Usage:
#   chmod +x diagnose_worklog.sh
#   sudo ./diagnose_worklog.sh
# =============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
WORKLOG_USER="khsu"
WORKLOG_DIR="/home/khsu/worklog-server"
WORKLOG_BIN="${WORKLOG_DIR}/WorkLogServer"
SERVICE_NAME="worklog"
DEFAULT_PORT="5000"

# Track issues found
ISSUES_FOUND=0

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE} WorkLogServer Diagnostic Tool${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Function to print section header
print_section() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}✗ $1${NC}"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Function to print info
print_info() {
    echo -e "  $1"
}

# =============================================================================
# 1. Check if running as root
# =============================================================================
print_section "1. Checking Permissions"
if [ "$EUID" -ne 0 ]; then
    print_error "This script must be run as root (use sudo)"
    exit 1
else
    print_success "Running as root"
fi
echo ""

# =============================================================================
# 2. Check WorkLogServer binary
# =============================================================================
print_section "2. Checking WorkLogServer Binary"
if [ -f "${WORKLOG_BIN}" ]; then
    print_success "Binary exists at ${WORKLOG_BIN}"

    # Check if executable
    if [ -x "${WORKLOG_BIN}" ]; then
        print_success "Binary is executable"
    else
        print_error "Binary is not executable"
        print_info "Fix: chmod +x ${WORKLOG_BIN}"
    fi

    # Check file size
    FILE_SIZE=$(stat -f%z "${WORKLOG_BIN}" 2>/dev/null || stat -c%s "${WORKLOG_BIN}" 2>/dev/null)
    print_info "Binary size: $(numfmt --to=iec-i --suffix=B $FILE_SIZE 2>/dev/null || echo "${FILE_SIZE} bytes")"
else
    print_error "Binary not found at ${WORKLOG_BIN}"
    print_info "Please extract the WorkLogServer release archive"
fi
echo ""

# =============================================================================
# 3. Check systemd service
# =============================================================================
print_section "3. Checking systemd Service"
if systemctl list-unit-files | grep -q "^${SERVICE_NAME}.service"; then
    print_success "Service ${SERVICE_NAME}.service exists"

    # Check if enabled
    if systemctl is-enabled --quiet "${SERVICE_NAME}" 2>/dev/null; then
        print_success "Service is enabled (will start on boot)"
    else
        print_warning "Service is not enabled for auto-start"
        print_info "Fix: sudo systemctl enable ${SERVICE_NAME}"
    fi

    # Check if active
    if systemctl is-active --quiet "${SERVICE_NAME}"; then
        print_success "Service is currently running"
    else
        print_error "Service is not running"
        print_info "Fix: sudo systemctl start ${SERVICE_NAME}"
    fi

    # Show service status
    echo ""
    print_info "Service status:"
    systemctl status "${SERVICE_NAME}" --no-pager -l | sed 's/^/    /'
else
    print_error "Service ${SERVICE_NAME}.service not found"
    print_info "Fix: Run ./setup_worklog_server_autostart.sh"
fi
echo ""

# =============================================================================
# 4. Check process
# =============================================================================
print_section "4. Checking Running Process"
WORKLOG_PID=$(pgrep -f WorkLogServer || true)
if [ -n "${WORKLOG_PID}" ]; then
    print_success "WorkLogServer process is running (PID: ${WORKLOG_PID})"
    print_info "Process details:"
    ps -p ${WORKLOG_PID} -o pid,user,%cpu,%mem,vsz,rss,stat,start,time,cmd --no-headers | sed 's/^/    /'
else
    print_error "No WorkLogServer process found"
fi
echo ""

# =============================================================================
# 5. Check port listening
# =============================================================================
print_section "5. Checking Port Status"
# Try to detect which port is configured
CONFIGURED_PORT=$(grep -oP 'Environment=PORT=\K[0-9]+' /etc/systemd/system/${SERVICE_NAME}.service 2>/dev/null || echo "${DEFAULT_PORT}")
print_info "Configured port: ${CONFIGURED_PORT}"

# Check if port is listening
PORT_INFO=$(lsof -i :${CONFIGURED_PORT} -P -n 2>/dev/null || true)
if [ -n "${PORT_INFO}" ]; then
    print_success "Port ${CONFIGURED_PORT} is being listened on"
    echo "${PORT_INFO}" | sed 's/^/    /'
else
    print_error "Port ${CONFIGURED_PORT} is not being listened on"
fi
echo ""

# =============================================================================
# 6. Check network configuration
# =============================================================================
print_section "6. Checking Network Configuration"
print_info "Network interfaces:"
ip addr show | grep -E 'inet ' | sed 's/^/    /'
echo ""

print_info "Default route:"
ip route | grep default | sed 's/^/    /'
echo ""

# =============================================================================
# 7. Test local connectivity
# =============================================================================
print_section "7. Testing Local Connectivity"
if command -v curl >/dev/null 2>&1; then
    # Test localhost
    print_info "Testing http://localhost:${CONFIGURED_PORT}..."
    if curl -s --max-time 5 "http://localhost:${CONFIGURED_PORT}" >/dev/null 2>&1; then
        print_success "localhost:${CONFIGURED_PORT} is accessible"
    else
        print_error "Cannot connect to localhost:${CONFIGURED_PORT}"
    fi

    # Test 127.0.0.1
    print_info "Testing http://127.0.0.1:${CONFIGURED_PORT}..."
    if curl -s --max-time 5 "http://127.0.0.1:${CONFIGURED_PORT}" >/dev/null 2>&1; then
        print_success "127.0.0.1:${CONFIGURED_PORT} is accessible"
    else
        print_error "Cannot connect to 127.0.0.1:${CONFIGURED_PORT}"
    fi

    # Test network IP
    NETWORK_IP=$(hostname -I | awk '{print $1}')
    if [ -n "${NETWORK_IP}" ]; then
        print_info "Testing http://${NETWORK_IP}:${CONFIGURED_PORT}..."
        if curl -s --max-time 5 "http://${NETWORK_IP}:${CONFIGURED_PORT}" >/dev/null 2>&1; then
            print_success "${NETWORK_IP}:${CONFIGURED_PORT} is accessible"
        else
            print_error "Cannot connect to ${NETWORK_IP}:${CONFIGURED_PORT}"
        fi
    fi
else
    print_warning "curl not installed, skipping connectivity tests"
    print_info "Install: sudo apt-get install curl"
fi
echo ""

# =============================================================================
# 8. Check firewall
# =============================================================================
print_section "8. Checking Firewall Configuration"
if command -v ufw >/dev/null 2>&1; then
    UFW_STATUS=$(ufw status 2>/dev/null || echo "inactive")
    if echo "${UFW_STATUS}" | grep -q "Status: active"; then
        print_info "UFW firewall is active"
        if echo "${UFW_STATUS}" | grep -q "${CONFIGURED_PORT}"; then
            print_success "Port ${CONFIGURED_PORT} is allowed in UFW"
        else
            print_warning "Port ${CONFIGURED_PORT} is not explicitly allowed in UFW"
            print_info "Fix: sudo ufw allow ${CONFIGURED_PORT}/tcp"
        fi
    else
        print_info "UFW firewall is inactive"
    fi
else
    print_info "UFW not installed"
fi

# Check iptables
if command -v iptables >/dev/null 2>&1; then
    IPTABLES_RULES=$(iptables -L -n 2>/dev/null | grep "${CONFIGURED_PORT}" || true)
    if [ -n "${IPTABLES_RULES}" ]; then
        print_info "iptables rules for port ${CONFIGURED_PORT}:"
        echo "${IPTABLES_RULES}" | sed 's/^/    /'
    fi
fi
echo ""

# =============================================================================
# 9. Check logs
# =============================================================================
print_section "9. Checking Logs"
# systemd journal
if journalctl -u "${SERVICE_NAME}" -n 1 >/dev/null 2>&1; then
    print_info "Recent systemd journal entries:"
    journalctl -u "${SERVICE_NAME}" -n 10 --no-pager | sed 's/^/    /'
    echo ""
fi

# Application logs
if [ -f "${WORKLOG_DIR}/worklog.log" ]; then
    print_info "Application log exists (${WORKLOG_DIR}/worklog.log)"
    LOG_SIZE=$(stat -f%z "${WORKLOG_DIR}/worklog.log" 2>/dev/null || stat -c%s "${WORKLOG_DIR}/worklog.log" 2>/dev/null)
    print_info "Log size: $(numfmt --to=iec-i --suffix=B $LOG_SIZE 2>/dev/null || echo "${LOG_SIZE} bytes")"

    if [ -s "${WORKLOG_DIR}/worklog.log" ]; then
        print_info "Last 10 lines of worklog.log:"
        tail -n 10 "${WORKLOG_DIR}/worklog.log" | sed 's/^/    /'
    fi
else
    print_warning "Application log not found"
fi
echo ""

if [ -f "${WORKLOG_DIR}/worklog_error.log" ]; then
    if [ -s "${WORKLOG_DIR}/worklog_error.log" ]; then
        print_warning "Error log contains entries"
        print_info "Last 10 lines of worklog_error.log:"
        tail -n 10 "${WORKLOG_DIR}/worklog_error.log" | sed 's/^/    /'
        echo ""
    fi
fi

# =============================================================================
# 10. Summary
# =============================================================================
print_section "10. Diagnostic Summary"
if [ ${ISSUES_FOUND} -eq 0 ]; then
    echo -e "${GREEN}✓ No issues found!${NC}"
    echo ""
    echo "WorkLogServer should be accessible at:"
    echo "  • http://localhost:${CONFIGURED_PORT}"
    echo "  • http://$(hostname -I | awk '{print $1}'):${CONFIGURED_PORT}"
else
    echo -e "${RED}✗ Found ${ISSUES_FOUND} issue(s)${NC}"
    echo ""
    echo "Review the errors above and apply the suggested fixes."
    echo ""
    echo "Common fixes:"
    echo "  1. Start service:     sudo systemctl start ${SERVICE_NAME}"
    echo "  2. Enable service:    sudo systemctl enable ${SERVICE_NAME}"
    echo "  3. Restart service:   sudo systemctl restart ${SERVICE_NAME}"
    echo "  4. View logs:         sudo journalctl -u ${SERVICE_NAME} -f"
    echo "  5. Re-run setup:      sudo ./setup_worklog_server_autostart.sh"
fi
echo ""

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE} Diagnostic Complete${NC}"
echo -e "${BLUE}============================================${NC}"
