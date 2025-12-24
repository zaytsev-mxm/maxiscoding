#!/bin/bash

# VM Setup Script for maxiscoding.dev
# This script sets up a fresh Debian VM with all required dependencies
# Run this script as root or with sudo privileges

set -e  # Exit on any error

echo "=========================================="
echo "Starting VM Setup for maxiscoding.dev"
echo "=========================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_green() {
    echo -e "${GREEN}$1${NC}"
}

print_yellow() {
    echo -e "${YELLOW}$1${NC}"
}

# Update system packages
print_yellow "Updating system packages..."
apt-get update
apt-get upgrade -y

# Install required packages
print_yellow "Installing required packages..."
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    git \
    ufw

# Install Docker
print_yellow "Installing Docker..."
if ! command -v docker &> /dev/null; then
    # Add Docker's official GPG key
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    # Add Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker packages
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Start and enable Docker
    systemctl start docker
    systemctl enable docker

    print_green "Docker installed successfully!"
else
    print_green "Docker is already installed"
fi

# Verify Docker installation
docker --version
docker compose version

# Create deployment user (optional but recommended)
print_yellow "Creating deployment user..."
if ! id -u deployer &>/dev/null; then
    useradd -m -s /bin/bash deployer
    usermod -aG docker deployer
    print_green "Deployment user 'deployer' created and added to docker group"
else
    print_green "Deployment user 'deployer' already exists"
fi

# Create application directory
print_yellow "Creating application directory..."
APP_DIR="/opt/maxiscoding"
mkdir -p $APP_DIR
chown -R deployer:deployer $APP_DIR
print_green "Application directory created at $APP_DIR"

# Setup SSH for deployment
print_yellow "Setting up SSH for deployment..."
mkdir -p /home/deployer/.ssh
chmod 700 /home/deployer/.ssh
chown -R deployer:deployer /home/deployer/.ssh

# Setup firewall
print_yellow "Configuring firewall..."
ufw --force enable
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw status
print_green "Firewall configured"

# Create certbot directories
print_yellow "Creating certbot directories..."
mkdir -p $APP_DIR/certbot/conf
mkdir -p $APP_DIR/certbot/www
chown -R deployer:deployer $APP_DIR/certbot
print_green "Certbot directories created"

# Setup log rotation for Docker
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

# Create systemd service for automatic container startup (optional)
print_yellow "Creating systemd service for Docker Compose..."
cat > /etc/systemd/system/maxiscoding.service <<EOF
[Unit]
Description=MaxisCoding Docker Compose Application
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
print_green "Systemd service created"

# Display summary
print_green "=========================================="
print_green "VM Setup Complete!"
print_green "=========================================="
echo ""
echo "Summary:"
echo "- Docker and Docker Compose installed"
echo "- Deployment user 'deployer' created"
echo "- Application directory: $APP_DIR"
echo "- Firewall configured (SSH, HTTP, HTTPS)"
echo "- Certbot directories created"
echo "- Docker log rotation configured"
echo "- Systemd service created"
echo ""
echo "Next steps:"
echo "1. Add your SSH public key to /home/deployer/.ssh/authorized_keys"
echo "2. Set up GitHub Actions secrets (VM_IP, SSH_PRIVATE_KEY)"
echo "3. Run the SSL setup workflow from GitHub Actions"
echo "4. Deploy the application using GitHub Actions"
echo ""
print_yellow "Note: Remember to add your SSH public key for the deployer user!"
