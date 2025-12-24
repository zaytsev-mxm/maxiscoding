#!/bin/bash

# Deployment Script
# This script is run by GitHub Actions to deploy the application
# It pulls the latest Docker image and restarts the containers

set -e

echo "=========================================="
echo "Deploying maxiscoding.dev"
echo "=========================================="

APP_DIR="/opt/maxiscoding"
IMAGE_TAG="${1:-latest}"
GITHUB_REPOSITORY_OWNER="${2:-maxzaytsev}"

cd $APP_DIR

# Login to GitHub Container Registry (token should be passed via stdin)
echo "Logging in to GitHub Container Registry..."
echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_REPOSITORY_OWNER" --password-stdin

# Pull the latest image
echo "Pulling Docker image: ghcr.io/$GITHUB_REPOSITORY_OWNER/maxiscoding:$IMAGE_TAG"
export IMAGE_TAG=$IMAGE_TAG
export GITHUB_REPOSITORY_OWNER=$GITHUB_REPOSITORY_OWNER
docker compose pull nextjs

# Stop and remove old containers
echo "Stopping old containers..."
docker compose down

# Start new containers
echo "Starting new containers..."
docker compose up -d

# Wait for containers to be healthy
echo "Waiting for containers to be healthy..."
sleep 10

# Check container status
echo "Container status:"
docker compose ps

# Clean up old images
echo "Cleaning up old Docker images..."
docker image prune -f

echo "=========================================="
echo "Deployment completed successfully!"
echo "=========================================="
