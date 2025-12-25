#!/bin/bash

# System Setup Script for maxiscoding.dev
# Run as admin user with sudo privileges
# Assumes users are already created via GCP SSH key metadata

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_green() { echo -e "${GREEN}$1${NC}"; }
print_yellow() { echo -e "${YELLOW}$1${NC}"; }
print_red() { echo -e "${RED}$1${NC}"; }

# Check if running with sudo/root
if [[ $EUID -ne 0 ]]; then
    print_red "ERROR: This script must be run with sudo"
    echo "Usage: sudo ./setup-system.sh"
    exit 1
fi

APP_DIR="/opt/maxiscoding"
DEPLOY_USER="deployer"

# Verify deployer user exists (should be created by GCP)
if ! id -u $DEPLOY_USER &>/dev/null; then
    print_red "ERROR: User '$DEPLOY_USER' does not exist"
    echo "Add the deployer's SSH public key to GCP VM metadata first."
    echo "GCP will automatically create the user."
    exit 1
fi

echo "=========================================="
echo "System Setup for maxiscoding.dev"
echo "=========================================="

# Update system packages
print_yellow "Updating system packages..."
apt-get update
apt-get upgrade -y

# Install required packages
print_yellow "Installing required packages..."
apt-get install -y \
    ca-certificates \
    curl \
    git

# Install Docker
print_yellow "Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    print_green "Docker installed successfully!"
else
    print_green "Docker is already installed"
fi

docker --version
docker compose version

# Add deployer to docker group
print_yellow "Adding $DEPLOY_USER to docker group..."
usermod -aG docker $DEPLOY_USER
print_green "$DEPLOY_USER added to docker group"

# Create application directory
print_yellow "Creating application directory..."
mkdir -p $APP_DIR
chown -R $DEPLOY_USER:$DEPLOY_USER $APP_DIR
print_green "Application directory created at $APP_DIR"

# Setup Docker log rotation
print_yellow "Setting up Docker log rotation..."
cat > /etc/docker/daemon.json <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

systemctl restart docker
print_green "Docker log rotation configured"

# Summary
print_green "=========================================="
print_green "System Setup Complete!"
print_green "=========================================="
echo ""
echo "Summary:"
echo "- Docker installed and $DEPLOY_USER added to docker group"
echo "- Application directory: $APP_DIR"
echo ""
echo "Next steps:"
echo "1. Log out and back in as $DEPLOY_USER (for docker group to take effect)"
echo "2. Run: ./setup-app.sh"
