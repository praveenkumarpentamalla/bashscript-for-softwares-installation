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

# Clean up unnecessary files and packages
sudo apt-get autoremove -y
sudo apt-get clean

# Output installation status
echo "Docker, Docker Compose, Nginx, PostgreSQL client, MySQL client, and Certbot have been installed successfully."

# Instruct the user to log out and back in for the Docker group changes to take effect
echo "Please log out and back in to apply the Docker group changes."
