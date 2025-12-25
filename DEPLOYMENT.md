# Deployment Guide for maxiscoding.dev

This document provides comprehensive instructions for deploying the Next.js application to a Google Cloud VM using Docker, Nginx, and GitHub Actions.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Initial VM Setup](#initial-vm-setup)
- [GitHub Configuration](#github-configuration)
- [Deployment Process](#deployment-process)
- [SSL Certificate Setup](#ssl-certificate-setup)
- [Updating Nginx Configuration](#updating-nginx-configuration)
- [Local Development](#local-development)
- [Troubleshooting](#troubleshooting)

## Architecture Overview

The deployment stack consists of:

- **Next.js Application**: Running in a Docker container (port 3000)
- **Nginx**: Reverse proxy with SSL termination (ports 80, 443)
- **Certbot**: Automated SSL certificate management
- **GitHub Actions**: CI/CD pipeline for automated deployments
- **GitHub Container Registry**: Docker image storage

### Directory Structure

```
maxiscoding/
├── .github/
│   └── workflows/
│       ├── build.yml          # Build and push Docker images
│       ├── deploy.yml         # Deploy to VM
│       ├── ssl-setup.yml      # SSL certificate setup
│       └── nginx-update.yml   # Update Nginx configuration
├── nginx/
│   ├── nginx.conf            # Main Nginx configuration
│   └── conf.d/
│       ├── default.conf       # HTTPS configuration
│       └── default-nossl.conf # HTTP-only configuration
├── scripts/
│   ├── setup-system.sh       # System setup (run as root)
│   ├── setup-app.sh          # App setup (run as deployer)
│   ├── setup-ssl.sh          # SSL certificate setup
│   ├── deploy.sh             # Deployment script
│   └── update-nginx.sh       # Nginx update script
├── docker-compose.yml        # Production Docker Compose
├── docker-compose.dev.yml    # Development Docker Compose
├── Dockerfile                # Multi-stage Next.js build
└── next.config.ts            # Next.js configuration (with standalone output)
```

## Prerequisites

### On Your Local Machine

- Git installed
- GitHub account with repository access
- SSH key pair for VM access

### Google Cloud VM Requirements

- Fresh Debian VM instance
- Public IP address
- Firewall rules allowing:
  - SSH (port 22)
  - HTTP (port 80)
  - HTTPS (port 443)

### Domain Configuration

- Domain: maxiscoding.dev
- DNS A record pointing to VM IP address
- DNS A record for www.maxiscoding.dev pointing to VM IP address

## Initial VM Setup

### Step 1: Add SSH Keys to GCP VM Metadata

In the GCP Console, add SSH public keys to your VM's metadata. GCP automatically creates users from these keys.

Add two keys:
1. **Admin key** (for system setup): `admin:ssh-ed25519 AAAA... your-email`
2. **Deployer key** (for GitHub Actions): `deployer:ssh-ed25519 AAAA... your-email`

### Step 2: Run System Setup (as admin)

```bash
# SSH as admin
ssh -i ~/.ssh/gcp_admin_ed25519 admin@VM_IP

# Download and run system setup
wget https://raw.githubusercontent.com/zaytsev-mxm/maxiscoding/main/scripts/setup-system.sh
chmod +x setup-system.sh
sudo ./setup-system.sh
```

This script will:
- Verify the `deployer` user exists
- Install Docker and Docker Compose
- Add `deployer` to the docker group
- Create `/opt/maxiscoding` owned by `deployer`
- Set up Docker log rotation

### Step 3: Run Application Setup (as deployer)

```bash
# SSH as deployer (new session for docker group to take effect)
ssh -i ~/.ssh/gcp_deployer_ed25519 deployer@VM_IP

# Download and run app setup
cd /opt/maxiscoding
wget https://raw.githubusercontent.com/zaytsev-mxm/maxiscoding/main/scripts/setup-app.sh
chmod +x setup-app.sh
./setup-app.sh
```

This script will:
- Verify Docker access
- Create certbot directories
- Create log directories

### Step 4: Verify Setup

```bash
# Check Docker installation
docker --version
docker compose version

# Check firewall status
sudo ufw status

# Verify application directory
ls -la /opt/maxiscoding
```

## GitHub Configuration

### Step 1: Set Up GitHub Secrets

In your GitHub repository, go to Settings > Secrets and variables > Actions, and add:

1. **VM_IP**: Your VM's public IP address
   ```
   Example: 34.123.45.67
   ```

2. **SSH_PRIVATE_KEY**: Private SSH key for the deployer user
   ```bash
   # Generate a new SSH key pair (if needed)
   ssh-keygen -t ed25519 -C "github-actions@maxiscoding.dev" -f ~/.ssh/maxiscoding_deploy

   # Copy the private key content (paste this into GitHub secret)
   cat ~/.ssh/maxiscoding_deploy

   # Add the public key to VM (see Step 3 above)
   cat ~/.ssh/maxiscoding_deploy.pub
   ```

### Step 2: Enable GitHub Actions

The workflows are already configured and will run automatically:

- **build.yml**: Triggers on push to main branch
- **deploy.yml**: Triggers after successful build (or manually)
- **ssl-setup.yml**: Manual trigger only
- **nginx-update.yml**: Manual trigger only

### Step 3: Enable GitHub Container Registry

GitHub Container Registry (ghcr.io) is automatically available. Ensure your repository is public or you have the necessary permissions.

## Deployment Process

### Initial Deployment (Without SSL)

1. **Push Code to GitHub**
   ```bash
   git add .
   git commit -m "Initial deployment setup"
   git push origin main
   ```

2. **Build Workflow Runs Automatically**
   - GitHub Actions builds the Docker image
   - Image is pushed to ghcr.io

3. **Trigger Manual Deployment**
   - Go to Actions tab in GitHub
   - Select "Deploy to VM" workflow
   - Click "Run workflow"
   - This deploys with HTTP-only configuration

4. **Verify Deployment**
   ```bash
   # SSH into VM
   ssh deployer@VM_IP

   # Check running containers
   cd /opt/maxiscoding
   docker compose ps

   # Check logs
   docker compose logs nextjs
   docker compose logs nginx
   ```

5. **Test the Application**
   - Visit http://maxiscoding.dev in your browser
   - You should see your Next.js application

## SSL Certificate Setup

After the initial deployment is working, set up SSL certificates:

### Step 1: Run SSL Setup Workflow

1. Go to Actions tab in GitHub
2. Select "SSL Certificate Setup" workflow
3. Click "Run workflow"
4. Enter your email address (for Let's Encrypt notifications)
5. Click "Run workflow"

This workflow will:
- Switch to non-SSL Nginx configuration temporarily
- Request SSL certificates from Let's Encrypt
- Validate domain ownership
- Switch back to SSL-enabled configuration
- Reload Nginx

### Step 2: Verify SSL Setup

```bash
# SSH into VM
ssh deployer@VM_IP

# Check certificate files
sudo ls -la /opt/maxiscoding/certbot/conf/live/maxiscoding.dev/

# Test HTTPS
curl -I https://maxiscoding.dev
```

### Step 3: Test in Browser

- Visit https://maxiscoding.dev
- Check for the padlock icon in the browser
- Verify certificate is valid

## Updating Nginx Configuration

To update Nginx configuration without redeploying the entire application:

### Step 1: Modify Nginx Configuration

Edit files in the `nginx/` directory locally:
- `nginx/nginx.conf` - Main configuration
- `nginx/conf.d/default.conf` - HTTPS configuration
- `nginx/conf.d/default-nossl.conf` - HTTP-only configuration

### Step 2: Commit and Push Changes

```bash
git add nginx/
git commit -m "Update Nginx configuration"
git push origin main
```

### Step 3: Run Nginx Update Workflow

1. Go to Actions tab in GitHub
2. Select "Update Nginx Configuration" workflow
3. Click "Run workflow"
4. Select SSL option (true/false)
5. Click "Run workflow"

This workflow will:
- Copy updated Nginx configuration to VM
- Test configuration validity
- Reload Nginx without downtime

## Local Development

### Option 1: Without Docker (Recommended for Development)

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Access at http://localhost:3000
```

This is the standard Next.js development workflow and doesn't require Docker.

### Option 2: With Docker (Testing Production Build Locally)

```bash
# Build and run with Docker Compose
docker compose -f docker-compose.dev.yml up --build

# Access at http://localhost:3000
```

### Option 3: Test Production Build Locally

```bash
# Build the production Docker image
docker build -t maxiscoding:local .

# Run the production image
docker run -p 3000:3000 maxiscoding:local

# Access at http://localhost:3000
```

## Continuous Deployment

Once everything is set up, the deployment process is fully automated:

1. **Make changes** to your code locally
2. **Commit and push** to the main branch
3. **Build workflow** automatically builds and pushes Docker image
4. **Deploy workflow** automatically deploys to VM
5. **Application updates** with zero downtime

### Manual Deployment

To deploy a specific version:

1. Go to Actions > "Deploy to VM"
2. Click "Run workflow"
3. Optionally specify an image tag
4. Click "Run workflow"

## Monitoring and Maintenance

### View Application Logs

```bash
# SSH into VM
ssh deployer@VM_IP
cd /opt/maxiscoding

# View all logs
docker compose logs

# View specific service logs
docker compose logs nextjs
docker compose logs nginx
docker compose logs certbot

# Follow logs in real-time
docker compose logs -f nextjs
```

### Check Container Status

```bash
# Check running containers
docker compose ps

# Check container health
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
```

### Restart Services

```bash
# Restart all services
docker compose restart

# Restart specific service
docker compose restart nextjs
docker compose restart nginx

# Full restart (down and up)
docker compose down
docker compose up -d
```

### Update Docker Images

```bash
# Pull latest images
docker compose pull

# Restart with new images
docker compose up -d

# Clean up old images
docker image prune -f
```

### SSL Certificate Renewal

Certificates automatically renew via the Certbot container. To manually trigger renewal:

```bash
# SSH into VM
ssh deployer@VM_IP
cd /opt/maxiscoding

# Manually renew certificates
docker compose run --rm certbot renew

# Reload Nginx to use new certificates
docker compose exec nginx nginx -s reload
```

### Check Certificate Expiration

```bash
# SSH into VM
ssh deployer@VM_IP

# Check certificate expiration date
echo | openssl s_client -servername maxiscoding.dev -connect maxiscoding.dev:443 2>/dev/null | openssl x509 -noout -dates
```

## Troubleshooting

### Application Not Accessible

1. **Check if containers are running:**
   ```bash
   docker compose ps
   ```

2. **Check firewall rules:**
   ```bash
   sudo ufw status
   ```

3. **Check Nginx logs:**
   ```bash
   docker compose logs nginx
   ```

4. **Check application logs:**
   ```bash
   docker compose logs nextjs
   ```

### SSL Certificate Issues

1. **Verify DNS is pointing to VM:**
   ```bash
   dig maxiscoding.dev
   ```

2. **Check certificate files:**
   ```bash
   sudo ls -la /opt/maxiscoding/certbot/conf/live/maxiscoding.dev/
   ```

3. **Try manual certificate request:**
   ```bash
   cd /opt/maxiscoding
   docker compose run --rm certbot certonly --webroot -w /var/www/certbot -d maxiscoding.dev -d www.maxiscoding.dev
   ```

### Docker Issues

1. **Check Docker service:**
   ```bash
   sudo systemctl status docker
   ```

2. **Restart Docker:**
   ```bash
   sudo systemctl restart docker
   ```

3. **Check disk space:**
   ```bash
   df -h
   ```

4. **Clean up Docker:**
   ```bash
   docker system prune -a
   ```

### Deployment Fails in GitHub Actions

1. **Check GitHub Actions logs** for specific error messages

2. **Verify secrets are set correctly** (VM_IP, SSH_PRIVATE_KEY)

3. **Test SSH connection manually:**
   ```bash
   ssh deployer@VM_IP
   ```

4. **Check Docker registry authentication:**
   ```bash
   ssh deployer@VM_IP
   docker login ghcr.io
   ```

### Nginx Configuration Errors

1. **Test Nginx configuration:**
   ```bash
   docker compose exec nginx nginx -t
   ```

2. **View Nginx error log:**
   ```bash
   docker compose exec nginx cat /var/log/nginx/error.log
   ```

3. **Reload Nginx configuration:**
   ```bash
   docker compose exec nginx nginx -s reload
   ```

### Build Fails

1. **Check build logs** in GitHub Actions

2. **Test build locally:**
   ```bash
   docker build -t test .
   ```

3. **Check Next.js configuration** (next.config.ts should have `output: 'standalone'`)

4. **Verify package.json** has all required dependencies

## Environment Variables

To add environment variables to your application:

### Step 1: Create .env.production on VM

```bash
# SSH into VM
ssh deployer@VM_IP
cd /opt/maxiscoding

# Create environment file
cat > .env.production << EOF
NODE_ENV=production
NEXT_PUBLIC_API_URL=https://api.maxiscoding.dev
DATABASE_URL=your_database_url
EOF
```

### Step 2: Update docker-compose.yml

Add environment file to the nextjs service:

```yaml
nextjs:
  # ... other configuration ...
  env_file:
    - .env.production
```

### Step 3: Redeploy

```bash
docker compose down
docker compose up -d
```

## Security Best Practices

1. **Keep the VM updated:**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Monitor Docker containers:**
   ```bash
   docker compose ps
   docker stats
   ```

3. **Regular backups:**
   - Database backups (if applicable)
   - SSL certificates backup
   - Configuration backups

4. **Rotate SSH keys** periodically

5. **Monitor SSL certificate expiration** (Certbot handles auto-renewal)

6. **Review Nginx logs** regularly for suspicious activity

7. **Keep Docker images updated:**
   ```bash
   docker compose pull
   docker compose up -d
   ```

## Additional Resources

- [Next.js Documentation](https://nextjs.org/docs)
- [Docker Documentation](https://docs.docker.com/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## Support

For issues or questions:
- Check the troubleshooting section above
- Review GitHub Actions logs
- Check VM logs via SSH

## License

This deployment configuration is part of the maxiscoding project.
