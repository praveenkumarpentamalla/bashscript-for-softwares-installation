#!/bin/bash
set -e

##############################
# Install Jenkins
##############################

echo "=== Updating system packages ==="
apt update -y
apt upgrade -y

echo "=== Installing Java (Jenkins requires Java) ==="
apt install -y fontconfig openjdk-17-jre

echo "=== Adding Jenkins repository key ==="
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | tee \
    /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo "=== Adding Jenkins repository to sources list ==="
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
    https://pkg.jenkins.io/debian-stable binary/ | tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null

echo "=== Updating package index ==="
apt update -y

echo "=== Installing Jenkins ==="
apt install -y jenkins

echo "=== Starting Jenkins service ==="
systemctl start jenkins
systemctl enable jenkins

echo "=== Jenkins installed and running ==="
echo "Jenkins will be available at: http://<your-server-ip>:8080"

# Save Jenkins initial admin password to root's home
cat /var/lib/jenkins/secrets/initialAdminPassword > /root/jenkins_initial_admin_password.txt

##############################
# Install Terraform
##############################

echo "=== Installing dependencies for Terraform ==="
apt install -y wget unzip

echo "=== Downloading latest Terraform ==="
TERRAFORM_VERSION=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | cut -d '"' -f4 | tr -d 'v')
wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip

echo "=== Installing Terraform ${TERRAFORM_VERSION} ==="
unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip
mv terraform /usr/local/bin/

echo "=== Cleaning up Terraform installer files ==="
rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

echo "=== Verifying Terraform installation ==="
terraform -version

echo "=== Installation of Jenkins and Terraform complete! ==="
