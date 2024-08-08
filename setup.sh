#!/bin/bash

# Update and Upgrade the System
echo
echo "===================="
echo "Updating and upgrading the system..."
echo "===================="
sudo apt update && sudo apt upgrade -y && echo "System updated and upgraded successfully." || { echo "System update/upgrade failed."; exit 1; }

# Install Required Packages
echo
echo "===================="
echo "Installing required packages..."
echo "===================="
sudo apt install -y ca-certificates zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev curl git wget make jq build-essential pkg-config lsb-release libssl-dev libreadline-dev libffi-dev gcc screen unzip lz4 && echo "Required packages installed successfully." || { echo "Failed to install required packages."; exit 1; }

# Install Python3 and Pip
echo
echo "===================="
echo "Installing Python3 and pip..."
echo "===================="
sudo apt install -y python3 python3-pip && echo "Python3 and pip installed successfully." || { echo "Failed to install Python3 and pip."; exit 1; }
python3 --version || { echo "Python3 installation verification failed."; exit 1; }
pip3 --version || { echo "Pip installation verification failed."; exit 1; }

# Install Docker
echo
echo "===================="
echo "Installing Docker..."
echo "===================="
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && echo "Docker GPG key added successfully." || { echo "Failed to add Docker GPG key."; exit 1; }
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null && echo "Docker repository added successfully." || { echo "Failed to add Docker repository."; exit 1; }
sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io && echo "Docker installed successfully." || { echo "Failed to install Docker."; exit 1; }
docker version || { echo "Docker installation verification failed."; exit 1; }

# Install Docker-Compose
echo
echo "===================="
echo "Installing Docker-Compose..."
echo "===================="
VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4) && echo "Docker-Compose version fetched: $VER" || { echo "Failed to fetch Docker-Compose version."; exit 1; }
sudo curl -L "https://github.com/docker/compose/releases/download/${VER}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && echo "Docker-Compose downloaded successfully." || { echo "Failed to download Docker-Compose."; exit 1; }
sudo chmod +x /usr/local/bin/docker-compose && echo "Docker-Compose installed successfully." || { echo "Failed to install Docker-Compose."; exit 1; }
docker-compose --version || { echo "Docker-Compose installation verification failed."; exit 1; }

# Add Docker Permission to User
echo
echo "===================="
echo "Configuring Docker permissions..."
echo "===================="
if ! grep -q '^docker:' /etc/group; then
    sudo groupadd docker
    echo "Docker group added."
fi

# Install Go
echo
echo "===================="
echo "Installing Go..."
echo "===================="
sudo rm -rf /usr/local/go && curl -L https://go.dev/dl/go1.22.4.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local && echo "Go installed successfully." || { echo "Failed to install Go."; exit 1; }
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile && echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> $HOME/.bash_profile && source $HOME/.bash_profile && echo "Go environment variables set successfully." || { echo "Failed to set Go environment variables."; exit 1; }
go version || { echo "Go installation verification failed."; exit 1; }

# Install Allorad: Wallet
echo
echo "===================="
echo "Cloning Allora repository..."
echo "===================="
git clone https://github.com/allora-network/allora-chain.git && cd allora-chain && echo "Allora repository cloned successfully." || { echo "Failed to clone Allora repository."; exit 1; }
echo "Building Allora..."
make all && echo "Allora built successfully." || { echo "Failed to build Allora."; exit 1; }
allorad version || { echo "Allorad installation verification failed."; exit 1; }

# Add Wallet
echo
echo "===================="
echo "Adding wallet..."
echo "===================="
allorad keys add testkey --recover || allorad keys add testkey && echo "Wallet added successfully." || { echo "Failed to add wallet."; exit 1; }

# Get Faucet Instructions
echo
echo "===================="
echo "Follow the instructions to get faucet from the Allora dashboard."
echo "===================="

# Install Worker
echo
echo "===================="
echo "Installing Worker..."
echo "===================="
cd $HOME
git clone https://github.com/allora-network/basic-coin-prediction-node && cd basic-coin-prediction-node && echo "Worker repository cloned successfully." || { echo "Failed to clone Worker repository."; exit 1; }
mkdir workers workers/worker-1 workers/worker-2  workers/worker-3 head-data && echo "Directories for workers created successfully." || { echo "Failed to create directories for workers."; exit 1; }

# Give Permissions
echo
echo "===================="
echo "Setting permissions..."
echo "===================="
sudo chmod -R 777 workers/worker-1 && sudo chmod -R 777 workers/worker-2 && sudo chmod -R 777 workers/worker-3 && sudo chmod -R 777 head-data && echo "Permissions set successfully." || { echo "Failed to set permissions."; exit 1; }

# Create head keys
echo
echo "===================="
echo "Creating head keys..."
echo "===================="
sudo docker run -it --entrypoint=bash -v $(pwd)/head-data:/data alloranetwork/allora-inference-base:latest -c "mkdir -p /data/keys && (cd /data/keys && allora-keys)" && echo "Head keys created successfully." || { echo "Failed to create head keys."; exit 1; }

# Create worker keys
echo
echo "===================="
echo "Creating worker-1 keys..."
echo "===================="
sudo docker run -it --entrypoint=bash -v $(pwd)/workers/worker-1:/data alloranetwork/allora-inference-base:latest -c "mkdir -p /data/keys && (cd /data/keys && allora-keys)" && echo "Worker-1 keys created successfully." || { echo "Failed to create worker-1 keys."; exit 1; }

echo
echo "===================="
echo "Creating worker-2 keys..."
echo "===================="
sudo docker run -it --entrypoint=bash -v $(pwd)/workers/worker-2:/data alloranetwork/allora-inference-base:latest -c "mkdir -p /data/keys && (cd /data/keys && allora-keys)" && echo "Worker-2 keys created successfully." || { echo "Failed to create worker-2 keys."; exit 1; }

echo
echo "===================="
echo "Creating worker-3 keys..."
echo "===================="
sudo docker run -it --entrypoint=bash -v $(pwd)/workers/worker-3:/data alloranetwork/allora-inference-base:latest -c "mkdir -p /data/keys && (cd /data/keys && allora-keys)" && echo "Worker-3 keys created successfully." || { echo "Failed to create worker-2 keys."; exit 1; }


cat head-data/keys/identity
# Prompt for HEAD_ID and WALLET_SEED_PHRASE
echo
echo "===================="
read -p "Enter HEAD_ID: " HEAD_ID
echo

read -p "Enter WALLET_SEED_PHRASE: " WALLET_SEED_PHRASE
echo

# Create Docker Compose file
echo
echo "===================="
echo "Creating Docker Compose file..."
echo "===================="
rm -rf docker-compose.yml
cat <<EOF >docker-compose.yml
version: '3'

services:
  inference:
    container_name: inference
    build:
      context: .
    command: python -u /app/app.py
    ports:
      - "8000:8000"
    networks:
      eth-model-local:
        aliases:
          - inference
        ipv4_address: 172.22.0.4
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/inference/ETH"]
      interval: 10s
      timeout: 10s
      retries: 12
    volumes:
      - ./inference-data:/app/data
  
  updater:
    container_name: updater
    build: .
    environment:
      - INFERENCE_API_ADDRESS=http://inference:8000
    command: >
      sh -c "
      while true; do
        python -u /app/update_app.py;
        sleep 24h;
      done
      "
    depends_on:
      inference:
        condition: service_healthy
    networks:
      eth-model-local:
        aliases:
          - updater
        ipv4_address: 172.22.0.5
  
  head:
    container_name: head
    image: alloranetwork/allora-inference-base-head:latest
    environment:
      - HOME=/data
    entrypoint:
      - "/bin/bash"
      - "-c"
      - |
        if [ ! -f /data/keys/priv.bin ]; then
          echo "Generating new private keys..."
          mkdir -p /data/keys
          cd /data/keys
          allora-keys
        fi
        allora-node --role=head --peer-db=/data/peerdb --function-db=/data/function-db  \
          --runtime-path=/app/runtime --runtime-cli=bls-runtime --workspace=/data/workspace \
          --private-key=/data/keys/priv.bin --log-level=debug --port=9010 --rest-api=:6000 \
          --boot-nodes=/dns4/head-0-p2p.v2.testnet.allora.network/tcp/32130/p2p/12D3KooWGKY4z2iNkDMERh5ZD8NBoAX6oWzkDnQboBRGFTpoKNDF
    ports:
      - "6000:6000"
    volumes:
      - ./head-data:/data
    working_dir: /data
    networks:
      eth-model-local:
        aliases:
          - head
        ipv4_address: 172.22.0.100

  worker-1:
    container_name: worker-1
    environment:
      - INFERENCE_API_ADDRESS=http://inference:8000
      - HOME=/data
    build:
      context: .
      dockerfile: Dockerfile_b7s
    entrypoint:
      - "/bin/bash"
      - "-c"
      - |
        if [ ! -f /data/keys/priv.bin ]; then
          echo "Generating new private keys..."
          mkdir -p /data/keys
          cd /data/keys
          allora-keys
        fi
        # Change boot-nodes below to the key advertised by your head
        allora-node --role=worker --peer-db=/data/peerdb --function-db=/data/function-db \
          --runtime-path=/app/runtime --runtime-cli=bls-runtime --workspace=/data/workspace \
          --private-key=/data/keys/priv.bin --log-level=debug --port=9011 \
          --boot-nodes=/ip4/172.22.0.100/tcp/9010/p2p/${HEAD_ID} \
          --topic=allora-topic-1-worker --allora-chain-worker-mode=worker \
          --allora-chain-restore-mnemonic='${WALLET_SEED_PHRASE}' \
          --allora-node-rpc-address=https://allora-rpc.testnet-1.testnet.allora.network \
          --allora-chain-key-name=worker-1 \
          --allora-chain-topic-id=1
    volumes:
      - ./workers/worker-1:/data
    working_dir: /data
    depends_on:
      - inference
      - head
    networks:
      eth-model-local:
        aliases:
          - worker1
        ipv4_address: 172.22.0.12

  worker-2:
    container_name: worker-2
    environment:
      - INFERENCE_API_ADDRESS=http://inference:8000
      - HOME=/data
    build:
      context: .
      dockerfile: Dockerfile_b7s
    entrypoint:
      - "/bin/bash"
      - "-c"
      - |
        if [ ! -f /data/keys/priv.bin ]; then
          echo "Generating new private keys..."
          mkdir -p /data/keys
          cd /data/keys
          allora-keys
        fi
        # Change boot-nodes below to the key advertised by your head
        allora-node --role=worker --peer-db=/data/peerdb --function-db=/data/function-db \
          --runtime-path=/app/runtime --runtime-cli=bls-runtime --workspace=/data/workspace \
          --private-key=/data/keys/priv.bin --log-level=debug --port=9013 \
          --boot-nodes=/ip4/172.22.0.100/tcp/9010/p2p/${HEAD_ID} \
          --topic=allora-topic-2-worker --allora-chain-worker-mode=worker \
          --allora-chain-restore-mnemonic='${WALLET_SEED_PHRASE}' \
          --allora-node-rpc-address=https://allora-rpc.testnet-1.testnet.allora.network \
          --allora-chain-key-name=worker-2 \
          --allora-chain-topic-id=2
    volumes:
      - ./workers/worker-2:/data
    working_dir: /data
    depends_on:
      - inference
      - head
    networks:
      eth-model-local:
        aliases:
          - worker2
        ipv4_address: 172.22.0.13
  worker-3:
    container_name: worker-3
    environment:
      - INFERENCE_API_ADDRESS=http://inference:8000
      - HOME=/data
    build:
      context: .
      dockerfile: Dockerfile_b7s
    entrypoint:
      - "/bin/bash"
      - "-c"
      - |
        if [ ! -f /data/keys/priv.bin ]; then
          echo "Generating new private keys..."
          mkdir -p /data/keys
          cd /data/keys
          allora-keys
        fi
        # Change boot-nodes below to the key advertised by your head
        allora-node --role=worker --peer-db=/data/peerdb --function-db=/data/function-db \
          --runtime-path=/app/runtime --runtime-cli=bls-runtime --workspace=/data/workspace \
          --private-key=/data/keys/priv.bin --log-level=debug --port=9013 \
          --boot-nodes=/ip4/172.22.0.100/tcp/9010/p2p/${HEAD_ID} \
          --topic=allora-topic-7-worker --allora-chain-worker-mode=worker \
          --allora-chain-restore-mnemonic='${WALLET_SEED_PHRASE}' \
          --allora-node-rpc-address=https://allora-rpc.testnet-1.testnet.allora.network \
          --allora-chain-key-name=worker-3 \
          --allora-chain-topic-id=7
    volumes:
      - ./workers/worker-3:/data
    working_dir: /data
    depends_on:
      - inference
      - head
    networks:
      eth-model-local:
        aliases:
          - worker3
        ipv4_address: 172.22.0.14
  
networks:
  eth-model-local:
    driver: bridge
    ipam:
      config:
        - subnet: 172.22.0.0/24

volumes:
  inference-data:
  workers:
  head-data:
EOF

echo "Docker Compose file created with the provided HEAD_ID and WALLET_SEED_PHRASE."

# Run worker
echo
echo "===================="
echo "Running Docker Compose..."
echo "===================="
docker-compose up -d --build && echo "Docker Compose started successfully." || { echo "Failed to start Docker Compose."; exit 1; }
