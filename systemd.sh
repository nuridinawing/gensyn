#!/bin/bash

# Auto-install script for Gensyn RL Swarm as systemd service
# Version 1.1 - Fixed
# Run as root

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: Please run as root${NC}"
    exit 1
fi

# Step 0: Preparation
echo -e "${YELLOW}[0/5] Preparing system...${NC}"

# Create backup directory
mkdir -p ezlabs

# Backup files if they exist
cp $HOME/rl-swarm/modal-login/temp-data/userApiKey.json $HOME/ezlabs/
cp $HOME/rl-swarm/modal-login/temp-data/userData.json $HOME/ezlabs/
cp $HOME/rl-swarm/swarm.pem $HOME/ezlabs/

# Stop any existing service
screen -XS gensyn quit
rm -rf officialauto.zip && cd ~ && rm -rf rl-swarm

# Step 1: Install dependencies
echo -e "${YELLOW}[1/5] Installing dependencies...${NC}"
apt-get update
apt-get install -y expect unzip wget

# Step 2: Download and setup
echo -e "${YELLOW}[2/5] Downloading and setting up application...${NC}"
cd /root
rm -rf rl-swarm nonofficialauto.zip systemd.zip 2>/dev/null
wget https://github.com/ezlabsnodes/gensyn/raw/refs/heads/main/systemd.zip
unzip systemd.zip

cp $HOME/ezlabs/swarm.pem $HOME/rl-swarm/

# Step 3: Setup virtual environment
echo -e "${YELLOW}[3/5] Setting up Python environment...${NC}"
cd $HOME/rl-swarm
python3 -m venv .venv
source .venv/bin/activate
chmod +x run_rl_swarm.sh run_gensyn_auto.exp

# Step 4: Create systemd service
echo -e "${YELLOW}[4/5] Creating systemd service...${NC}"

SERVICE_NAME="gensyn-swarm"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

cat > "$SERVICE_FILE" <<EOL
[Unit]
Description=Gensyn RL Swarm Auto-Restart Service
After=network.target

[Service]
User=root
WorkingDirectory=/root/rl-swarm

# Activate venv and run Expect script
ExecStart=/bin/bash -c 'source /root/rl-swarm/.venv/bin/activate && /usr/bin/expect /root/rl-swarm/run_gensyn_auto.exp'

# Restart policy
Restart=always
RestartSec=5s

# Environment variables
Environment="PYTHONUNBUFFERED=1"
Environment="CONNECT_TO_TESTNET=true"

# Log management
StandardOutput=journal
StandardError=journal
SyslogIdentifier=$SERVICE_NAME

[Install]
WantedBy=multi-user.target
EOL

# Step 5: Enable and start service
echo -e "${YELLOW}[5/5] Starting service...${NC}"
systemctl daemon-reload
systemctl enable $SERVICE_NAME
systemctl start $SERVICE_NAME

# Verification
sleep 5
SERVICE_STATUS=$(systemctl is-active $SERVICE_NAME)

if [ "$SERVICE_STATUS" = "active" ]; then
    echo -e "${GREEN}Service is running successfully!${NC}"
    echo -e "\nTo check service status: ${YELLOW}systemctl status $SERVICE_NAME${NC}"
    echo -e "To view logs: ${YELLOW}journalctl -u $SERVICE_NAME -f${NC}"
else
    echo -e "${RED}Error: Service failed to start. Status: $SERVICE_STATUS${NC}"
    echo -e "Check logs with: ${YELLOW}journalctl -u $SERVICE_NAME -xe${NC}"
    exit 1
fi

echo -e "\n${GREEN}Installation completed successfully!${NC}"
