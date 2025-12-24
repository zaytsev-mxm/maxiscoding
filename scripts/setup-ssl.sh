#!/bin/bash

# SSL Setup Script using Certbot
# This script obtains SSL certificates for maxiscoding.dev
# Run this script on the VM after the application is deployed with the no-SSL Nginx config

set -e

echo "=========================================="
echo "SSL Certificate Setup for maxiscoding.dev"
echo "=========================================="

DOMAIN="maxiscoding.dev"
EMAIL="admin@maxiscoding.dev"  # Change this to your email
APP_DIR="/opt/maxiscoding"

# Navigate to application directory
cd $APP_DIR

# Ensure certbot directories exist
mkdir -p ./certbot/conf
mkdir -p ./certbot/www

# Request SSL certificate
echo "Requesting SSL certificate for $DOMAIN and www.$DOMAIN..."

docker compose run --rm --entrypoint "certbot" certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    -d $DOMAIN \
    -d www.$DOMAIN

if [ $? -eq 0 ]; then
    echo "SSL certificate obtained successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Update Nginx configuration to use SSL"
    echo "2. Restart Nginx container"
    echo ""
    echo "You can do this by running the nginx-update workflow from GitHub Actions"
    echo "or manually by replacing default-nossl.conf with default.conf"
else
    echo "Failed to obtain SSL certificate"
    echo "Please check the error messages above"
    exit 1
fi
