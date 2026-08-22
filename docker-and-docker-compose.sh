#!/bin/bash
# ------------------------------------------------------------------
# Server provisioning script: Docker, Docker Compose, Nginx,
# PostgreSQL client, MySQL client, Certbot
# ------------------------------------------------------------------
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo "==> Updating package list and upgrading existing packages"
sudo apt-get update -y
sudo apt-get upgrade -y

echo "==> Installing prerequisites"
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    gnupg \
    lsb-release

echo "==> Removing any old/conflicting Docker packages"
sudo apt-get remove -y docker docker-engine docker.io containerd runc docker-compose 2>/dev/null || true

echo "==> Adding Docker's official GPG key and repository"
sudo install -m 0755 -d /usr/share/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "==> Updating package list for Docker repo"
sudo apt-get update -y

echo "==> Installing Docker CE, CLI, containerd, and the Compose plugin"
sudo apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

echo "==> Enabling and starting Docker"
sudo systemctl enable docker
sudo systemctl start docker

echo "==> Adding current user to the docker group (takes effect on next login)"
sudo usermod -aG docker "$USER"

echo "==> Verifying Docker and Docker Compose installation"
docker --version
docker compose version

echo "==> Installing Nginx"
sudo apt-get install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx

echo "==> Installing PostgreSQL client"
sudo apt-get install -y postgresql-client

echo "==> Installing MySQL client"
sudo apt-get install -y mysql-client

echo "==> Installing Certbot with Nginx plugin"
sudo apt-get install -y certbot python3-certbot-nginx

echo "==> Cleaning up unnecessary files and packages"
sudo apt-get autoremove -y
sudo apt-get clean

echo ""
echo "Docker, Docker Compose, Nginx, PostgreSQL client, MySQL client, and Certbot have been installed successfully."
echo "NOTE: Log out and back in (or run 'newgrp docker' interactively yourself) for the docker group change to take effect."
