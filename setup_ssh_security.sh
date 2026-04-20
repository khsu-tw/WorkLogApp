#!/bin/bash
# =============================================================================
# SSH Security Update Script for Raspberry Pi
# =============================================================================
# This script updates SSH host keys and optimizes security configuration
#
# Usage:
#   1. Transfer this script to your Raspberry Pi
#   2. Make it executable: chmod +x setup_ssh_security.sh
#   3. Run it with sudo: sudo ./setup_ssh_security.sh
# =============================================================================

set -e  # Exit on error

echo "============================================"
echo " SSH Security Update & Configuration"
echo "============================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then
   echo -e "${RED}Error: This script must be run as root (use sudo)${NC}"
   exit 1
fi

# Backup timestamp
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/etc/ssh.backup.${BACKUP_DATE}"

echo -e "${BLUE}[1/7] Creating backup of current SSH configuration...${NC}"
cp -r /etc/ssh "${BACKUP_DIR}"
echo -e "${GREEN}✓ Backup created at: ${BACKUP_DIR}${NC}"
echo ""

echo -e "${BLUE}[2/7] Removing old RSA host key...${NC}"
if [ -f /etc/ssh/ssh_host_rsa_key ]; then
    mv /etc/ssh/ssh_host_rsa_key /etc/ssh/ssh_host_rsa_key.old 2>/dev/null || true
    mv /etc/ssh/ssh_host_rsa_key.pub /etc/ssh/ssh_host_rsa_key.pub.old 2>/dev/null || true
    echo -e "${GREEN}✓ Old RSA key moved to .old${NC}"
else
    echo -e "${YELLOW}⚠ No existing RSA key found${NC}"
fi
echo ""

echo -e "${BLUE}[3/7] Generating new SSH host keys...${NC}"

# Generate RSA 4096-bit key (for compatibility)
echo "  • Generating RSA 4096-bit key..."
ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N "" -q
chmod 600 /etc/ssh/ssh_host_rsa_key
chmod 644 /etc/ssh/ssh_host_rsa_key.pub

# Generate ED25519 key (most secure and modern)
echo "  • Generating ED25519 key..."
if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
    ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N "" -q
    chmod 600 /etc/ssh/ssh_host_ed25519_key
    chmod 644 /etc/ssh/ssh_host_ed25519_key.pub
else
    echo "    ED25519 key already exists, skipping..."
fi

# Generate ECDSA key (fallback)
echo "  • Generating ECDSA 521-bit key..."
if [ ! -f /etc/ssh/ssh_host_ecdsa_key ]; then
    ssh-keygen -t ecdsa -b 521 -f /etc/ssh/ssh_host_ecdsa_key -N "" -q
    chmod 600 /etc/ssh/ssh_host_ecdsa_key
    chmod 644 /etc/ssh/ssh_host_ecdsa_key.pub
else
    echo "    ECDSA key already exists, skipping..."
fi

echo -e "${GREEN}✓ All host keys generated${NC}"
echo ""

echo -e "${BLUE}[4/7] Verifying generated keys...${NC}"
ls -lh /etc/ssh/ssh_host_*key.pub | awk '{print "  " $9 " (" $5 ")"}'
echo -e "${GREEN}✓ Keys verified${NC}"
echo ""

echo -e "${BLUE}[5/7] Backing up current sshd_config...${NC}"
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.${BACKUP_DATE}
echo -e "${GREEN}✓ Config backed up${NC}"
echo ""

echo -e "${BLUE}[6/7] Updating SSH configuration...${NC}"

# Check if configuration already updated
if grep -q "# Modern SSH Configuration - Updated" /etc/ssh/sshd_config; then
    echo -e "${YELLOW}⚠ Configuration already updated, skipping...${NC}"
else
    cat >> /etc/ssh/sshd_config << 'EOF'

# =============================================================================
# Modern SSH Configuration - Updated by setup_ssh_security.sh
# =============================================================================

# Host Keys (prefer modern algorithms)
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_rsa_key

# Network Configuration
Port 22
ListenAddress 0.0.0.0
AddressFamily any

# Authentication
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication yes
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes

# Security Limits
MaxAuthTries 3
MaxSessions 5
LoginGraceTime 30

# Key Exchange Algorithms (modern and secure)
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group-exchange-sha256

# Ciphers (modern and secure)
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr

# MAC Algorithms (modern and secure)
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256

# Other Security Settings
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server

# Logging
SyslogFacility AUTH
LogLevel INFO
EOF
    echo -e "${GREEN}✓ Configuration updated${NC}"
fi
echo ""

echo -e "${BLUE}[7/7] Testing configuration and restarting SSH...${NC}"

# Test SSH configuration
if sshd -t; then
    echo -e "${GREEN}✓ SSH configuration syntax is valid${NC}"

    # Restart SSH service
    systemctl restart ssh
    sleep 2

    if systemctl is-active --quiet ssh; then
        echo -e "${GREEN}✓ SSH service restarted successfully${NC}"
    else
        echo -e "${RED}✗ SSH service failed to start${NC}"
        echo "Restoring backup configuration..."
        cp "${BACKUP_DIR}/sshd_config" /etc/ssh/sshd_config
        systemctl restart ssh
        exit 1
    fi
else
    echo -e "${RED}✗ SSH configuration has syntax errors${NC}"
    echo "Restoring backup configuration..."
    cp "${BACKUP_DIR}/sshd_config" /etc/ssh/sshd_config
    exit 1
fi
echo ""

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN} SSH Security Update Completed!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "Summary of changes:"
echo "  • Generated new RSA 4096-bit host key"
echo "  • Generated ED25519 host key (if not exists)"
echo "  • Generated ECDSA 521-bit host key (if not exists)"
echo "  • Updated SSH configuration with modern security settings"
echo "  • Backup saved to: ${BACKUP_DIR}"
echo ""
echo -e "${YELLOW}IMPORTANT:${NC}"
echo "  • SSH host key fingerprints have changed"
echo "  • Clients will see a warning on first connection"
echo "  • This is normal - accept the new key fingerprint"
echo ""
echo "New host key fingerprints:"
for key in /etc/ssh/ssh_host_*key.pub; do
    echo ""
    echo "  $(basename $key):"
    ssh-keygen -lf "$key" | awk '{print "    " $2 " (" $4 ")"}'
done
echo ""
echo "SSH service status:"
systemctl status ssh --no-pager -l | head -10
echo ""
echo "Test connection:"
echo "  ssh khsu@localhost"
echo "  ssh khsu@192.168.0.105"
echo "  ssh khsu@1.34.56.127"
echo ""
echo -e "${GREEN}Done!${NC}"
