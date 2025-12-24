# Quick Start - Deployment Setup

This is a quick start guide to get your Next.js application deployed to Google Cloud VM with Docker, Nginx, and SSL.

## Prerequisites Checklist

- [ ] Fresh Debian VM on Google Cloud
- [ ] VM has public IP address
- [ ] Domain `maxiscoding.dev` DNS points to VM IP
- [ ] Domain `www.maxiscoding.dev` DNS points to VM IP
- [ ] SSH access to VM as root
- [ ] GitHub repository is set up

## Step-by-Step Setup

### 1. Initial VM Setup (One-time, ~5 minutes)

```bash
# SSH into your VM as root
ssh root@YOUR_VM_IP

# Download and run setup script
wget https://raw.githubusercontent.com/YOUR_USERNAME/maxiscoding/main/scripts/setup-vm.sh
chmod +x setup-vm.sh
./setup-vm.sh

# The script will create a 'deployer' user and set up Docker
```

### 2. Add SSH Key for GitHub Actions (One-time)

```bash
# On your local machine, generate deployment key
ssh-keygen -t ed25519 -C "github-actions" -f ~/.ssh/maxiscoding_deploy

# Copy public key to VM
ssh-copy-id -i ~/.ssh/maxiscoding_deploy.pub deployer@YOUR_VM_IP

# Or manually:
# ssh deployer@YOUR_VM_IP
# mkdir -p ~/.ssh
# echo "PASTE_PUBLIC_KEY_HERE" >> ~/.ssh/authorized_keys
# chmod 600 ~/.ssh/authorized_keys
```

### 3. Configure GitHub Secrets (One-time)

Go to your GitHub repository → Settings → Secrets and variables → Actions → New repository secret

Add these secrets:

1. **VM_IP**
   ```
   Value: YOUR_VM_IP (e.g., 34.123.45.67)
   ```

2. **SSH_PRIVATE_KEY**
   ```
   Value: Content of ~/.ssh/maxiscoding_deploy (entire file including BEGIN/END lines)
   ```

### 4. Deploy Application

```bash
# On your local machine
git add .
git commit -m "Setup deployment infrastructure"
git push origin main

# This triggers GitHub Actions:
# 1. Build workflow builds Docker image
# 2. Deploy workflow deploys to VM
```

Wait for GitHub Actions to complete (check Actions tab in GitHub).

### 5. Verify Deployment

```bash
# Check if application is running (HTTP only at this point)
curl http://maxiscoding.dev

# Or visit in browser:
# http://maxiscoding.dev
```

### 6. Setup SSL Certificates

Go to GitHub repository → Actions → "SSL Certificate Setup" → Run workflow

Enter your email address and click "Run workflow"

Wait for the workflow to complete (~2 minutes).

### 7. Verify HTTPS

```bash
# Check HTTPS is working
curl -I https://maxiscoding.dev

# Or visit in browser:
# https://maxiscoding.dev
```

## You're Done!

Your application is now deployed with:
- Docker containers running Next.js
- Nginx as reverse proxy
- SSL certificates from Let's Encrypt
- Automatic deployments via GitHub Actions

## What Happens Now?

Every time you push to the `main` branch:
1. GitHub Actions builds a new Docker image
2. Image is pushed to GitHub Container Registry
3. VM pulls the new image and restarts containers
4. Your application updates automatically (zero downtime)

## Common Tasks

### View Application Logs

```bash
ssh deployer@YOUR_VM_IP
cd /opt/maxiscoding
docker compose logs -f nextjs
```

### Restart Application

```bash
ssh deployer@YOUR_VM_IP
cd /opt/maxiscoding
docker compose restart nextjs
```

### Update Nginx Configuration

1. Edit `nginx/conf.d/default.conf` locally
2. Commit and push changes
3. Go to Actions → "Update Nginx Configuration" → Run workflow

## Documentation

- **Full Deployment Guide**: [DEPLOYMENT.md](./DEPLOYMENT.md)
- **Quick Reference**: [INFRASTRUCTURE.md](./INFRASTRUCTURE.md)

## Troubleshooting

### Application not accessible?

```bash
# SSH into VM and check containers
ssh deployer@YOUR_VM_IP
cd /opt/maxiscoding
docker compose ps
docker compose logs
```

### SSL not working?

```bash
# Check DNS is pointing to VM
dig maxiscoding.dev

# Re-run SSL setup workflow from GitHub Actions
```

### GitHub Actions failing?

1. Check Actions tab for error messages
2. Verify GitHub secrets are set correctly
3. Test SSH connection: `ssh deployer@YOUR_VM_IP`

## Need Help?

See [DEPLOYMENT.md](./DEPLOYMENT.md) for detailed troubleshooting and advanced configuration.
