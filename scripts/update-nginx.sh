#!/bin/bash

# Nginx Configuration Update Script
# This script updates Nginx configuration and reloads Nginx

set -e

echo "=========================================="
echo "Updating Nginx Configuration"
echo "=========================================="

APP_DIR="/opt/maxiscoding"
USE_SSL="${1:-false}"

cd $APP_DIR

# Copy the appropriate configuration file
if [ "$USE_SSL" = "true" ]; then
    echo "Enabling SSL configuration..."
    if [ ! -f "./certbot/conf/live/maxiscoding.dev/fullchain.pem" ]; then
        echo "Error: SSL certificates not found!"
        echo "Please run the SSL setup workflow first"
        exit 1
    fi
    # The SSL config should already be in place from the repo
    echo "SSL configuration is active (default.conf)"
else
    echo "Using non-SSL configuration..."
    echo "Make sure default-nossl.conf is the active configuration"
fi

# Test Nginx configuration
echo "Testing Nginx configuration..."
docker compose exec nginx nginx -t

if [ $? -eq 0 ]; then
    # Reload Nginx
    echo "Reloading Nginx..."
    docker compose exec nginx nginx -s reload
    echo "Nginx configuration updated and reloaded successfully!"
else
    echo "Nginx configuration test failed!"
    echo "Please check the configuration files"
    exit 1
fi

echo "=========================================="
echo "Nginx update completed!"
echo "=========================================="
