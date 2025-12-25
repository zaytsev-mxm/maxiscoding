#!/bin/bash

# Application Setup Script for maxiscoding.dev
# Run as deployer user (no sudo required)

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_green() { echo -e "${GREEN}$1${NC}"; }
print_yellow() { echo -e "${YELLOW}$1${NC}"; }
print_red() { echo -e "${RED}$1${NC}"; }

# Check not running as root
if [[ $EUID -eq 0 ]]; then
    print_red "ERROR: Do not run this script as root"
    echo "Run as your deployer user instead"
    exit 1
fi

echo "=========================================="
echo "Application Setup for maxiscoding.dev"
echo "Running as: $(whoami)"
echo "=========================================="

APP_DIR="/opt/maxiscoding"

# Verify app directory exists and is writable
if [[ ! -d "$APP_DIR" ]]; then
    print_red "ERROR: $APP_DIR does not exist"
    echo "Run setup-system.sh first"
    exit 1
fi

if [[ ! -w "$APP_DIR" ]]; then
    print_red "ERROR: No write access to $APP_DIR"
    echo "Ensure setup-system.sh set correct ownership"
    exit 1
fi

# Verify Docker access
print_yellow "Verifying Docker access..."
if ! docker info &> /dev/null; then
    print_red "ERROR: Cannot connect to Docker"
    echo ""
    echo "If you just ran setup-system.sh, you need to log out and back in"
    echo "for the docker group membership to take effect."
    echo ""
    echo "Or run: newgrp docker"
    exit 1
fi
print_green "Docker access verified"

# Create directories
print_yellow "Creating application directories..."
mkdir -p $APP_DIR/certbot/conf
mkdir -p $APP_DIR/certbot/www
mkdir -p $APP_DIR/logs
print_green "Directories created"

# Verify docker compose
print_yellow "Verifying Docker Compose..."
docker compose version
print_green "Docker Compose verified"

# Summary
print_green "=========================================="
print_green "Application Setup Complete!"
print_green "=========================================="
echo ""
echo "Directory structure:"
ls -la $APP_DIR
echo ""
echo "Next steps:"
echo "1. Configure GitHub secrets (VM_IP, SSH_PRIVATE_KEY)"
echo "2. Push to main branch to trigger deployment"
echo "3. Run SSL setup workflow"
