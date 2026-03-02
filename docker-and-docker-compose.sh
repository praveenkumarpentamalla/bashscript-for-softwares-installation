#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()    { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()   { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()  { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

retry() {
    local n=1
    local max=3
    local delay=10
    while true; do
        "$@" && break || {
            if [[ $n -lt $max ]]; then
                warn "Command failed. Attempt $n/$max. Retrying in ${delay}s..."
                sleep $delay
                ((n++))
            else
                error "Command failed after $max attempts: $*"
            fi
        }
    done
}

# ─── System Update ────────────────────────────────────────────────────────────
log "Updating system packages..."
retry sudo apt-get update -y
retry sudo apt-get upgrade -y

# ─── Prerequisites ────────────────────────────────────────────────────────────
log "Installing prerequisites..."
retry sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    wget \
    gnupg \
    lsb-release \
    software-properties-common

# ─── Remove Old Docker Versions ───────────────────────────────────────────────
log "Removing old Docker versions if present..."
sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# ─── Install Docker ───────────────────────────────────────────────────────────
log "Installing Docker..."

# Clean up any broken Docker repo/keyring entries
sudo rm -f /usr/share/keyrings/docker-archive-keyring.gpg
sudo rm -f /etc/apt/sources.list.d/docker.list

# Add Docker GPG key with retry
retry bash -c 'curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg'

# Add Docker repo
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

retry sudo apt-get update -y

# Install Docker with fallback
if ! retry sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
    warn "Official Docker install failed. Trying convenience script..."
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    retry sudo sh /tmp/get-docker.sh
    rm -f /tmp/get-docker.sh
fi

# Enable and start Docker
sudo systemctl enable docker
sudo systemctl start docker

# Verify Docker is running
if ! sudo systemctl is-active --quiet docker; then
    error "Docker service failed to start!"
fi
log "Docker installed: $(sudo docker --version)"

# ─── Install Docker Compose (Standalone) ─────────────────────────────────────
log "Installing Docker Compose..."

COMPOSE_VERSION=$(curl -fsSL https://api.github.com/repos/docker/compose/releases/latest \
    | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')

if [[ -z "$COMPOSE_VERSION" ]]; then
    warn "Could not fetch latest version. Using fallback v2.24.0"
    COMPOSE_VERSION="v2.24.0"
fi

log "Installing Docker Compose $COMPOSE_VERSION..."
COMPOSE_URL="https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)"

if retry sudo curl -L "$COMPOSE_URL" -o /usr/local/bin/docker-compose; then
    sudo chmod +x /usr/local/bin/docker-compose
    log "Docker Compose installed: $(docker-compose --version)"
else
    # Fallback: use plugin installed via apt
    warn "Standalone compose failed. Checking docker compose plugin..."
    if docker compose version &>/dev/null; then
        log "Docker Compose plugin available: $(docker compose version)"
        # Create symlink for backward compatibility
        sudo ln -sf /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose 2>/dev/null || true
    else
        error "Docker Compose installation failed completely."
    fi
fi

# ─── Add User to Docker Group ─────────────────────────────────────────────────
log "Adding $USER to docker group..."
sudo usermod -aG docker "$USER"

# ─── Install Nginx ────────────────────────────────────────────────────────────
log "Installing Nginx..."
retry sudo apt-get install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx
log "Nginx installed: $(nginx -v 2>&1)"

# ─── Install Database Clients ─────────────────────────────────────────────────
log "Installing PostgreSQL client..."
retry sudo apt-get install -y postgresql-client

log "Installing MySQL client..."
# mysql-client may be called default-mysql-client on some Ubuntu versions
retry sudo apt-get install -y mysql-client || retry sudo apt-get install -y default-mysql-client

# ─── Install Certbot ──────────────────────────────────────────────────────────
log "Installing Certbot..."
retry sudo apt-get install -y certbot python3-certbot-nginx

# ─── Cleanup ──────────────────────────────────────────────────────────────────
log "Cleaning up..."
sudo apt-get autoremove -y
sudo apt-get clean

# ─── Final Summary ────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}══════════════════════════════════════════${NC}"
echo -e "${GREEN}  Installation Complete!${NC}"
echo -e "${GREEN}══════════════════════════════════════════${NC}"
sudo docker --version        2>/dev/null && log "✔ Docker"
docker-compose --version     2>/dev/null && log "✔ Docker Compose"
nginx -v                     2>&1        | log "✔ Nginx: $(nginx -v 2>&1)"
psql --version               2>/dev/null && log "✔ PostgreSQL client"
mysql --version              2>/dev/null && log "✔ MySQL client"
certbot --version            2>/dev/null && log "✔ Certbot"
echo ""
warn "Log out and back in (or run 'newgrp docker') for Docker group changes to take effect."








=============================================================================




#!/bin/bash

# Update the package list and upgrade existing packages
sudo apt-get update -y
sudo apt-get upgrade -y

# Install prerequisites
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg

# Add Docker's official GPG key and set up the stable repository
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package list for Docker packages from the new repository
sudo apt-get update -y

# Install Docker CE (Community Edition)
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Enable and start Docker
sudo systemctl enable docker
sudo systemctl start docker

# Add current user to the Docker group to avoid needing 'sudo' for Docker commands
sudo usermod -aG docker $USER
newgrp docker

# Install Docker Compose (latest version)
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify Docker and Docker Compose installation
docker --version
docker-compose --version

# Install Nginx
sudo apt-get install -y nginx

# Enable and start Nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Install PostgreSQL client
sudo apt-get install -y postgresql-client

# Install MySQL client
sudo apt-get install -y mysql-client

# Install Certbot and python3-certbot-nginx for automatic Nginx SSL configuration
sudo apt-get install -y certbot python3-certbot-nginx

sudo usermod -aG docker $USER

# Clean up unnecessary files and packages
sudo apt-get autoremove -y
sudo apt-get clean

# Output installation status
echo "Docker, Docker Compose, Nginx, PostgreSQL client, MySQL client, and Certbot have been installed successfully."

# Instruct the user to log out and back in for the Docker group changes to take effect
echo "Please log out and back in to apply the Docker group changes."
