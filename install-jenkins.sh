#!/bin/bash
set -e

echo "=== Updating system packages ==="
sudo apt update -y
sudo apt upgrade -y

echo "=== Installing Java (Jenkins requires Java) ==="
sudo apt install -y fontconfig openjdk-17-jre

echo "=== Adding Jenkins repository key ==="
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo tee \
    /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo "=== Adding Jenkins repository to sources list ==="
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
    https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null

echo "=== Updating package index ==="
sudo apt update -y

echo "=== Installing Jenkins ==="
sudo apt install -y jenkins

echo "=== Starting Jenkins service ==="
sudo systemctl start jenkins
sudo systemctl enable jenkins

echo "=== Jenkins installed and running ==="
echo "Jenkins will be available at: http://<your-server-ip>:8080"

echo "=== Fetching initial admin password ==="
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
