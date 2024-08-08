#!/bin/bash

# Update and Upgrade the System
echo
echo "===================="
echo "Updating and upgrading the system..."
echo "===================="
echo
sudo apt update && sudo apt upgrade -y

# Install Required Packages
echo
echo "===================="
echo "Installing required packages..."
echo "===================="
echo
sudo apt install -y ca-certificates zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev curl git wget make jq build-essential pkg-config lsb-release libssl-dev libreadline-dev libffi-dev gcc screen unzip lz4

# Add a new user
read -p "Enter new username: " NEW_USER
sudo adduser $NEW_USER
sudo usermod -aG sudo $NEW_USER

# Install Python3 and Pip
echo
echo "===================="
echo "Installing Python3 and pip..."
echo "===================="
echo
sudo apt install -y python3 python3-pip
python3 --version
pip3 --version

# Install Docker
echo
echo "===================="
echo "Installing Docker..."
echo "===================="
echo
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
docker version

# Install Docker-Compose
echo
echo "===================="
echo "Installing Docker-Compose..."
echo "===================="
echo
VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
sudo curl -L "https://github.com/docker/compose/releases/download/${VER}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version

# Add Docker Permission to User
echo
echo "===================="
echo "Configuring Docker permissions..."
echo "===================="
echo
sudo usermod -aG docker $NEW_USER

# Install Go
echo
echo "===================="
echo "Installing Go..."
echo "===================="
echo
sudo rm -rf /usr/local/go
curl -L https://go.dev/dl/go1.22.4.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> /home/$NEW_USER/.bash_profile
echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> /home/$NEW_USER/.bash_profile
source /home/$NEW_USER/.bash_profile
go version

# Install Allorad: Wallet
echo
echo "===================="
echo "Cloning Allora repository..."
echo "===================="
echo
sudo -u $NEW_USER git clone https://github.com/allora-network/allora-chain.git /home/$NEW_USER/allora-chain
cd /home/$NEW_USER/allora-chain
echo
echo "===================="
echo "Building Allora..."
echo "===================="
echo
sudo -u $NEW_USER make all
sudo -u $NEW_USER allorad version

# Add Wallet
echo
echo "===================="
echo "Adding wallet..."
echo "===================="
echo
sudo -u $NEW_USER allorad keys add testkey --recover || sudo -u $NEW_USER allorad keys add testkey

# Get Faucet Instructions
echo
echo "===================="
echo "Follow the instructions to get faucet from the Allora dashboard."
echo "===================="
echo

# Install Worker
cd /home/$NEW_USER
sudo -u $NEW_USER git clone https://github.com/allora-network/basic-coin-prediction-node
cd basic-coin-prediction-node
sudo -u $NEW_USER mkdir workers workers/worker-1 workers/worker-2 workers/worker-3 head-data

# Give Permissions
echo
echo "===================="
echo "Giving permissions..."
echo "===================="
echo
sudo chmod -R 777 workers/worker-1
sudo chmod -R 777 workers/worker-2
sudo chmod -R 777 workers/worker-3
sudo chmod -R 777 head-data

# Create head keys
echo
echo "===================="
echo "Creating head keys..."
echo "===================="
echo
sudo docker run -it --entrypoint=bash -v $(pwd)/head-data:/data alloranetwork/allora-inference-base:latest -c "mkdir -p /data/keys && (cd /data/keys && allora-keys)"

# Create worker keys
echo
echo "===================="
echo "Creating worker-1 keys..."
echo "===================="
echo
sudo docker run -it --entrypoint=bash -v $(pwd)/workers/worker-1:/data alloranetwork/allora-inference-base:latest -c "mkdir -p /data/keys && (cd /data/keys && allora-keys)"

echo
echo "===================="
echo "Creating worker-2 keys..."
echo "===================="
echo
sudo docker run -it --entrypoint=bash -v $(pwd)/workers/worker-2:/data alloranetwork/allora-inference-base:latest -c "mkdir -p /data/keys && (cd /data/keys && allora-keys)"

echo
echo "===================="
echo "Creating worker-3 keys..."
echo "===================="
echo
sudo docker run -it --entrypoint=bash -v $(pwd)/workers/worker-3:/data alloranetwork/allora-inference-base:latest -c "mkdir -p /data/keys && (cd /data/keys && allora-keys)"

cat head-data/keys/identity
echo

# Prompt for HEAD_ID and WALLET_SEED_PHRASE
read -p "Enter HEAD_ID: " HEAD_ID
echo

read -p "Enter WALLET_SEED_PHRASE: " WALLET_SEED_PHRASE
echo

# Create Docker Compose file
echo
echo "===================="
echo "Creating Docker Compose file..."
echo "===================="
echo
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

echo
echo "===================="
echo "Docker Compose file created with the provided HEAD_ID and WALLET_SEED_PHRASE."
echo "===================="
echo

# Run worker
echo
echo "===================="
echo "Running Docker Compose..."
echo "===================="
echo
docker-compose up -d --build
