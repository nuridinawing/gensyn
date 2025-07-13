#!/bin/bash

# Create directory 'ezlabs'
mkdir -p ezlabs

# Copy files to 'ezlabs'
cp $HOME/rl-swarm/modal-login/temp-data/userApiKey.json $HOME/ezlabs/
cp $HOME/rl-swarm/modal-login/temp-data/userData.json $HOME/ezlabs/
cp $HOME/rl-swarm/swarm.pem $HOME/ezlabs/

# Close Screen and Remove Old Repository
screen -XS gensyn quit
rm -rf nonofficialauto.zip && cd ~ && rm -rf rl-swarm

# Install Automation Tools
sudo apt-get update
sudo apt-get install expect -y

# Download and Unzip ezlabs7.zip, then change to rl-swarm directory
sudo apt-get install -y unzip && \
wget https://github.com/ezlabsnodes/gensyn/raw/refs/heads/main/nonofficialauto.zip && \
unzip nonofficialauto.zip && \
cd ~/rl-swarm

# Copy swarm.pem to $HOME/rl-swarm/
cp $HOME/ezlabs/swarm.pem $HOME/rl-swarm/

# Create Screen and run commands
screen -S gensyn -dm bash -c "python3 -m venv .venv && source .venv/bin/activate && chmod +x run_rl_swarm.sh && ./run_rl_swarm.sh"

echo "Script completed. The 'gensyn' screen session should be running in the background."
echo "Check logs : tail -f $HOME/rl-swarm/logs/swarm_launcher.log"
