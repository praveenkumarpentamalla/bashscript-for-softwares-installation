#!/bin/bash
set -e

echo "=== Updating packages ==="
sudo apt update -y
sudo apt upgrade -y

echo "=== Installing required dependencies ==="
sudo apt install -y wget unzip

echo "=== Downloading latest Terraform ==="
TERRAFORM_VERSION=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | cut -d '"' -f4 | tr -d 'v')
wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip

echo "=== Installing Terraform ${TERRAFORM_VERSION} ==="
unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip
sudo mv terraform /usr/local/bin/

echo "=== Cleaning up ==="
rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

echo "=== Verifying installation ==="
terraform -version

echo "=== Terraform installation complete! ==="
