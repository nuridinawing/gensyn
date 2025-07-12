#!/bin/bash

# Deteksi user (root atau non-root) dan set path yang sesuai
if [ "$(whoami)" = "root" ]; then
    EZLABS_DIR="/root/ezlabs"
    SWARM_DIR="/root/rl-swarm"
else
    EZLABS_DIR="$HOME/ezlabs"
    SWARM_DIR="$HOME/rl-swarm"
fi

# Create directory 'ezlabs'
mkdir -p "$EZLABS_DIR"

# Copy files to 'ezlabs' (pastikan path sumber file ada)
if [ -f "/root/rl-swarm/modal-login/temp-data/userApiKey.json" ]; then
    cp "/root/rl-swarm/modal-login/temp-data/userApiKey.json" "$EZLABS_DIR/"
fi

if [ -f "/root/rl-swarm/modal-login/temp-data/userData.json" ]; then
    cp "/root/rl-swarm/modal-login/temp-data/userData.json" "$EZLABS_DIR/"
fi

if [ -f "/root/rl-swarm/swarm.pem" ]; then
    cp "/root/rl-swarm/swarm.pem" "$EZLABS_DIR/"
fi

# Close Screen and Remove Old Repository
screen -XS gensyn quit 2>/dev/null  # Ignore error jika screen tidak ada
rm -f "$HOME/testing.zip"
rm -rf "$SWARM_DIR"

# Install Automation Tools
sudo apt-get update
sudo apt-get install -y expect unzip

# Download and Unzip
wget -O "$HOME/testing.zip" "https://github.com/ezlabsnodes/gensyn/raw/refs/heads/main/testing.zip" && \
unzip -o "$HOME/testing.zip" -d "$HOME/" && \
cd "$SWARM_DIR" || exit

# Copy swarm.pem jika ada
if [ -f "$EZLABS_DIR/swarm.pem" ]; then
    cp "$EZLABS_DIR/swarm.pem" "$SWARM_DIR/"
fi

# Create Screen and run commands
screen -S gensyn -dm bash -c \
"cd $SWARM_DIR && \
python3 -m venv .venv && \
source .venv/bin/activate && \
chmod +x run_rl_swarm.sh && \
./run_rl_swarm.sh"

echo "Script completed. The 'gensyn' screen session should be running in the background."
echo "Check logs: tail -f $SWARM_DIR/logs/swarm_launcher.log"
