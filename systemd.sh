#!/bin/bash

# Auto-install script for Gensyn RL Swarm as systemd service
# Version 1.6 - Fixed systemd service configuration
# Run as root

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Service name
SERVICE_NAME="gensyn-swarm"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: Please run as root${NC}"
    exit 1
fi

# Enhanced service stopping function
stop_existing_service() {
    echo -e "${YELLOW}[+] Stopping existing service...${NC}"
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        systemctl stop "$SERVICE_NAME"
        systemctl disable "$SERVICE_NAME"
        echo -e "${GREEN}Systemd service stopped successfully${NC}"
    else
        echo -e "${YELLOW}Service was not running${NC}"
    fi
    
    pkill -f "run_gensyn_auto.exp" || true
    pkill -f "rl-swarm" || true
    screen -XS gensyn quit 2>/dev/null || true
}

# Function to verify service file content
verify_service_file() {
    local expected_content=$(cat <<'EOF'
[Unit]
Description=Gensyn RL Swarm Service
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
User=root
WorkingDirectory=/root/rl-swarm
ExecStart=/usr/bin/expect /root/rl-swarm/run_gensyn_auto.exp
Restart=always
RestartSec=5s
Environment="PYTHONUNBUFFERED=1"
Environment="CONNECT_TO_TESTNET=true"
Environment="HF_HUB_ENABLE_HF_TRANSFER=1"

StandardOutput=journal
StandardError=journal
SyslogIdentifier=gensyn-swarm

[Install]
WantedBy=multi-user.target
EOF
    )

    if [ -f "$SERVICE_FILE" ]; then
        current_content=$(cat "$SERVICE_FILE")
        if [ "$current_content" == "$expected_content" ]; then
            echo -e "${GREEN}Service file is already up to date${NC}"
            return 0
        else
            echo -e "${YELLOW}Service file needs updating${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}Service file does not exist${NC}"
        return 1
    fi
}

# Step 0: Preparation
echo -e "${YELLOW}[0/5] Preparing system...${NC}"
stop_existing_service
mkdir -p /root/ezlabs

# Backup files
[ -f /root/rl-swarm/modal-login/temp-data/userApiKey.json ] && cp /root/rl-swarm/modal-login/temp-data/userApiKey.json /root/ezlabs/
[ -f /root/rl-swarm/modal-login/temp-data/userData.json ] && cp /root/rl-swarm/modal-login/temp-data/userData.json /root/ezlabs/
[ -f /root/rl-swarm/swarm.pem ] && cp /root/rl-swarm/swarm.pem /root/ezlabs/

# Cleanup
rm -rf /root/officialauto.zip /root/systemd.zip /root/rl-swarm

# Step 1: Install dependencies
echo -e "${YELLOW}[1/5] Installing dependencies...${NC}"
apt-get update
apt-get install -y expect unzip wget python3-venv

# Step 2: Download and setup
echo -e "${YELLOW}[2/5] Downloading and setting up application...${NC}"
cd /root
wget -q https://github.com/ezlabsnodes/gensyn/raw/refs/heads/main/systemd.zip || {
    echo -e "${RED}Error: Failed to download systemd.zip${NC}"
    exit 1
}
unzip -q systemd.zip || {
    echo -e "${RED}Error: Failed to unzip systemd.zip${NC}"
    exit 1
}

# Restore backups
mkdir -p /root/rl-swarm/modal-login/temp-data
[ -f /root/ezlabs/swarm.pem ] && cp /root/ezlabs/swarm.pem /root/rl-swarm/
[ -f /root/ezlabs/userApiKey.json ] && cp /root/ezlabs/userApiKey.json /root/rl-swarm/modal-login/temp-data/
[ -f /root/ezlabs/userData.json ] && cp /root/ezlabs/userData.json /root/rl-swarm/modal-login/temp-data/

# Step 3: Setup virtual environment
echo -e "${YELLOW}[3/5] Setting up Python environment...${NC}"
cd /root/rl-swarm
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt 2>/dev/null
chmod +x run_rl_swarm.sh run_gensyn_auto.exp

# Step 4: Create systemd service
echo -e "${YELLOW}[4/5] Configuring systemd service...${NC}"

if ! verify_service_file; then
    cat > "$SERVICE_FILE" <<'EOF'
[Unit]
Description=Gensyn RL Swarm Service
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
User=root
WorkingDirectory=/root/rl-swarm
ExecStart=/usr/bin/expect /root/rl-swarm/run_gensyn_auto.exp
Restart=always
RestartSec=5s
Environment="PYTHONUNBUFFERED=1"
Environment="CONNECT_TO_TESTNET=true"
Environment="HF_HUB_ENABLE_HF_TRANSFER=1"

StandardOutput=journal
StandardError=journal
SyslogIdentifier=gensyn-swarm

[Install]
WantedBy=multi-user.target
EOF
    echo -e "${GREEN}Service file created/updated successfully${NC}"
fi

# Step 5: Enable and start service
echo -e "${YELLOW}[5/5] Starting service...${NC}"
systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl start "$SERVICE_NAME"

# Verification
sleep 5
SERVICE_STATUS=$(systemctl is-active "$SERVICE_NAME")

if [ "$SERVICE_STATUS" = "active" ]; then
    echo -e "${GREEN}Service is running successfully!${NC}"
    echo -e "\nTo check service status: ${YELLOW}systemctl status $SERVICE_NAME${NC}"
    echo -e "To view logs: ${YELLOW}journalctl -u $SERVICE_NAME -f${NC}"
else
    echo -e "${RED}Error: Service failed to start. Status: $SERVICE_STATUS${NC}"
    journalctl -u "$SERVICE_NAME" -xe --no-pager | tail -n 20
    exit 1
fi

echo -e "\n${GREEN}Installation completed successfully!${NC}"
