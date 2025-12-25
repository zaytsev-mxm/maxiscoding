# Infrastructure Quick Reference

This document provides quick reference commands and information for managing the maxiscoding.dev infrastructure.

## Quick Links

- **Application URL**: https://maxiscoding.dev
- **GitHub Repository**: https://github.com/YOUR_USERNAME/maxiscoding
- **Docker Registry**: ghcr.io/YOUR_USERNAME/maxiscoding

## File Structure

```
Infrastructure Files:
├── Dockerfile                  # Multi-stage Next.js production build
├── docker-compose.yml         # Production deployment configuration
├── docker-compose.dev.yml     # Local Docker testing
├── .dockerignore             # Docker build exclusions
├── .env.example              # Environment variables template
├── nginx/
│   ├── nginx.conf            # Main Nginx config
│   └── conf.d/
│       ├── default.conf       # HTTPS config (with SSL)
│       └── default-nossl.conf # HTTP config (without SSL)
├── scripts/
│   ├── setup-system.sh       # System setup (run as root)
│   ├── setup-app.sh          # App setup (run as deployer)
│   ├── setup-ssl.sh          # SSL certificate setup
│   ├── deploy.sh             # Deployment script
│   └── update-nginx.sh       # Nginx config update
└── .github/workflows/
    ├── build.yml             # Build Docker image
    ├── deploy.yml            # Deploy to VM
    ├── ssl-setup.yml         # Setup SSL certificates
    └── nginx-update.yml      # Update Nginx config
```

## GitHub Secrets Required

Configure these in GitHub repository settings (Settings > Secrets and variables > Actions):

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `VM_IP` | VM public IP address | `34.123.45.67` |
| `SSH_PRIVATE_KEY` | Private SSH key for deployer user | `-----BEGIN OPENSSH PRIVATE KEY-----...` |

## Common Commands

### On VM (SSH Access)

```bash
# SSH into VM
ssh deployer@VM_IP

# Navigate to app directory
cd /opt/maxiscoding

# View running containers
docker compose ps

# View logs
docker compose logs -f nextjs
docker compose logs -f nginx

# Restart services
docker compose restart

# Pull latest images and restart
docker compose pull
docker compose up -d

# Stop all services
docker compose down

# Start all services
docker compose up -d

# View resource usage
docker stats

# Clean up unused Docker resources
docker system prune -f
```

### GitHub Actions Workflows

All workflows are in `.github/workflows/`:

1. **Build and Push Docker Image** (`build.yml`)
   - Triggers: Automatic on push to main
   - Manually: Actions > "Build and Push Docker Image" > Run workflow

2. **Deploy to VM** (`deploy.yml`)
   - Triggers: Automatic after successful build
   - Manually: Actions > "Deploy to VM" > Run workflow

3. **SSL Certificate Setup** (`ssl-setup.yml`)
   - Triggers: Manual only
   - Run: Actions > "SSL Certificate Setup" > Run workflow > Enter email

4. **Update Nginx Configuration** (`nginx-update.yml`)
   - Triggers: Manual only
   - Run: Actions > "Update Nginx Configuration" > Run workflow > Select SSL option

### Local Development

```bash
# Standard development (no Docker)
npm install
npm run dev
# Access: http://localhost:3000

# Test with Docker (development mode)
docker compose -f docker-compose.dev.yml up --build

# Test production build locally
docker build -t maxiscoding:test .
docker run -p 3000:3000 maxiscoding:test
```

## Deployment Workflow

### Initial Setup (One-time)

1. Set up VM (as root):
   ```bash
   ssh root@VM_IP
   wget https://raw.githubusercontent.com/YOUR_USERNAME/maxiscoding/main/scripts/setup-system.sh
   chmod +x setup-system.sh
   sudo ./setup-system.sh
   ```

2. Add SSH key to deployer user:
   ```bash
   echo "YOUR_PUBLIC_KEY" >> /home/deployer/.ssh/authorized_keys
   ```

3. Run app setup as deployer:
   ```bash
   su - deployer
   cd /opt/maxiscoding
   wget https://raw.githubusercontent.com/YOUR_USERNAME/maxiscoding/main/scripts/setup-app.sh
   chmod +x setup-app.sh
   ./setup-app.sh
   ```

4. Configure GitHub secrets (VM_IP, SSH_PRIVATE_KEY)

5. Deploy application (via GitHub Actions)

6. Set up SSL certificates (via GitHub Actions)

### Regular Deployment

1. Make code changes locally
2. Commit and push to main branch
3. GitHub Actions automatically builds and deploys
4. Application updates with zero downtime

## Nginx Configuration

### Switch Between SSL and Non-SSL

**Enable SSL (HTTPS):**
```bash
cd /opt/maxiscoding/nginx/conf.d
# Ensure default.conf contains SSL configuration
docker compose exec nginx nginx -t
docker compose exec nginx nginx -s reload
```

**Disable SSL (HTTP only - for testing):**
```bash
cd /opt/maxiscoding/nginx/conf.d
cp default-nossl.conf default.conf
docker compose exec nginx nginx -t
docker compose exec nginx nginx -s reload
```

### Test Nginx Configuration

```bash
# Test configuration syntax
docker compose exec nginx nginx -t

# Reload without downtime
docker compose exec nginx nginx -s reload

# View Nginx logs
docker compose logs nginx
```

## SSL Certificate Management

### Check Certificate Status

```bash
# SSH into VM
ssh deployer@VM_IP

# Check certificate files
ls -la /opt/maxiscoding/certbot/conf/live/maxiscoding.dev/

# Check expiration date
echo | openssl s_client -servername maxiscoding.dev -connect maxiscoding.dev:443 2>/dev/null | openssl x509 -noout -dates
```

### Manual Certificate Renewal

```bash
# SSH into VM
cd /opt/maxiscoding

# Renew certificates
docker compose run --rm certbot renew

# Reload Nginx
docker compose exec nginx nginx -s reload
```

## Monitoring

### Check Application Health

```bash
# SSH into VM
cd /opt/maxiscoding

# Container status
docker compose ps

# Container health
docker inspect --format='{{.State.Health.Status}}' maxiscoding-app

# Application logs
docker compose logs --tail=100 nextjs

# Real-time logs
docker compose logs -f nextjs
```

### Check System Resources

```bash
# Disk usage
df -h

# Docker disk usage
docker system df

# Container resource usage
docker stats

# System memory
free -h
```

## Troubleshooting Quick Fixes

### Application Not Responding

```bash
# Restart Next.js container
docker compose restart nextjs

# Full restart
docker compose down && docker compose up -d

# Check logs for errors
docker compose logs nextjs
```

### SSL Certificate Issues

```bash
# Re-run SSL setup from GitHub Actions
# Or manually:
cd /opt/maxiscoding
./setup-ssl.sh
```

### Nginx Issues

```bash
# Test configuration
docker compose exec nginx nginx -t

# Restart Nginx
docker compose restart nginx

# Check logs
docker compose logs nginx
```

### Out of Disk Space

```bash
# Clean up Docker
docker system prune -a -f

# Remove unused volumes
docker volume prune -f

# Check disk usage
du -sh /opt/maxiscoding/*
```

## Environment Variables

### Add New Environment Variables

1. SSH into VM:
   ```bash
   ssh deployer@VM_IP
   cd /opt/maxiscoding
   ```

2. Create/edit .env.production:
   ```bash
   nano .env.production
   ```

3. Update docker-compose.yml to use env_file (if not already configured)

4. Restart containers:
   ```bash
   docker compose down
   docker compose up -d
   ```

## Backup and Restore

### Backup Important Files

```bash
# On VM
cd /opt/maxiscoding
tar -czf backup-$(date +%Y%m%d).tar.gz \
  docker-compose.yml \
  nginx/ \
  certbot/ \
  .env.production

# Download backup
scp deployer@VM_IP:/opt/maxiscoding/backup-*.tar.gz ./
```

### Restore from Backup

```bash
# Upload backup to VM
scp backup-*.tar.gz deployer@VM_IP:/opt/maxiscoding/

# On VM
cd /opt/maxiscoding
tar -xzf backup-*.tar.gz
docker compose up -d
```

## Performance Optimization

### Enable Nginx Caching

Already configured in `nginx/conf.d/default.conf` for:
- Static files (/_next/static) - 60 minutes
- Public assets (/static) - 1 hour

### Docker Image Optimization

The Dockerfile already uses:
- Multi-stage builds
- Production-only dependencies
- Next.js standalone output
- Non-root user
- Alpine Linux base

### Monitoring Response Times

```bash
# Check response time
curl -o /dev/null -s -w 'Total: %{time_total}s\n' https://maxiscoding.dev

# Check with headers
curl -I https://maxiscoding.dev
```

## Security Checklist

- [ ] VM firewall configured (ports 22, 80, 443)
- [ ] Non-root user for deployment
- [ ] SSH key authentication only
- [ ] SSL certificates installed and auto-renewing
- [ ] HSTS header enabled in Nginx
- [ ] Security headers configured
- [ ] Docker containers run as non-root user
- [ ] Sensitive data in environment variables (not in code)
- [ ] Regular system updates
- [ ] Docker images regularly updated

## Useful Links

- **Full Documentation**: See [DEPLOYMENT.md](./DEPLOYMENT.md)
- **Next.js Docs**: https://nextjs.org/docs
- **Docker Docs**: https://docs.docker.com/
- **Nginx Docs**: https://nginx.org/en/docs/
- **Let's Encrypt**: https://letsencrypt.org/

## Support

For detailed information, see [DEPLOYMENT.md](./DEPLOYMENT.md).
