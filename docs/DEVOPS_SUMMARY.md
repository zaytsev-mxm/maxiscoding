# DevOps Quick Reference

Quick reference for **maxiscoding.dev** infrastructure. For step-by-step setup instructions, see [DEPLOYMENT.md](./DEPLOYMENT.md).

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              GitHub                                     │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────────────────┐  │
│  │   Code Push │───▶│ Build Image │───▶│ Push to ghcr.io             │  │
│  └─────────────┘    └─────────────┘    └──────────────┬──────────────┘  │
└───────────────────────────────────────────────────────┼─────────────────┘
                                                        │
                                                        ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         Google Cloud VM (Debian)                        │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │                        Docker Network                             │  │
│  │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐            │  │
│  │  │   Nginx     │◀──▶│   Next.js   │    │   Certbot   │            │  │
│  │  │  (SSL/TLS)  │    │    App      │    │  (Auto-SSL) │            │  │
│  │  │  :80, :443  │    │   :3000     │    │             │            │  │
│  │  └─────────────┘    └─────────────┘    └─────────────┘            │  │
│  └───────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
                                    ▲
                                    │ HTTPS
                                    ▼
                          https://maxiscoding.dev
```

## Files Reference

### Docker

| File | Purpose |
|------|---------|
| `Dockerfile` | Multi-stage production build for Next.js |
| `docker-compose.yml` | Production orchestration (Next.js + Nginx + Certbot) |
| `docker-compose.dev.yml` | Optional local Docker testing |

### Nginx

| File | Purpose |
|------|---------|
| `nginx/nginx.conf` | Main config with gzip, keepalive, security |
| `nginx/conf.d/default.conf` | HTTPS server with SSL termination |
| `nginx/conf.d/default-nossl.conf` | HTTP-only for initial SSL setup |

### Scripts

| File | Purpose |
|------|---------|
| `scripts/setup-system.sh` | System setup (run as admin with sudo) |
| `scripts/setup-app.sh` | App setup (run as deployer) |
| `scripts/setup-ssl.sh` | SSL certificate acquisition |
| `scripts/deploy.sh` | Pull image, restart containers |
| `scripts/update-nginx.sh` | Update Nginx configuration |

### GitHub Actions

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `build.yml` | Push to `main` | Build Docker image, push to ghcr.io |
| `deploy.yml` | After build | Deploy to VM via SSH |
| `ssl-setup.yml` | Manual | Initial SSL certificate setup |
| `nginx-update.yml` | Manual | Update Nginx configuration |

## File Details

### Dockerfile

Multi-stage build with 3 stages:
- **deps**: Install dependencies
- **builder**: Build Next.js with `standalone` output
- **runner**: Minimal Alpine image, runs as non-root user `nextjs`

### docker-compose.yml

Three services:
- **nextjs**: Application container with health checks
- **nginx**: Reverse proxy, reloads every 6h for cert updates
- **certbot**: Renews certificates every 12h

### Nginx

- HTTP→HTTPS redirect
- TLS 1.2/1.3, modern ciphers
- Security headers (HSTS, X-Frame-Options, etc.)
- Static asset caching for `/_next/static`
- WebSocket support

### Setup Scripts

**setup-system.sh** (as admin):
1. Verify deployer user exists
2. Install Docker + Compose
3. Add deployer to docker group
4. Create `/opt/maxiscoding`
5. Configure Docker log rotation

**setup-app.sh** (as deployer):
1. Verify Docker access
2. Create certbot directories
3. Create log directories

## Quick Reference

### Links

- **App**: https://maxiscoding.dev
- **Repo**: https://github.com/zaytsev-mxm/maxiscoding
- **Registry**: ghcr.io/zaytsev-mxm/maxiscoding

### Commands

```bash
# SSH into VM
ssh deployer@<VM_IP>
cd /opt/maxiscoding

# Container status
docker compose ps

# View logs
docker compose logs -f nextjs
docker compose logs -f nginx

# Restart
docker compose restart nextjs
docker compose restart           # all services
docker compose down && docker compose up -d  # full restart

# Update to latest
docker compose pull
docker compose up -d

# SSL certificate
docker compose run --rm certbot renew
docker compose exec nginx nginx -s reload

# Check cert expiration
echo | openssl s_client -servername maxiscoding.dev -connect maxiscoding.dev:443 2>/dev/null | openssl x509 -noout -dates

# Cleanup
docker system prune -f
docker volume prune -f
```

### Backup and Restore

```bash
# Backup
cd /opt/maxiscoding
tar -czf backup-$(date +%Y%m%d).tar.gz \
  docker-compose.yml nginx/ certbot/ .env.production

# Download backup locally
scp deployer@VM_IP:/opt/maxiscoding/backup-*.tar.gz ./

# Upload and restore
scp backup-*.tar.gz deployer@VM_IP:/opt/maxiscoding/
ssh deployer@VM_IP "cd /opt/maxiscoding && tar -xzf backup-*.tar.gz && docker compose up -d"
```
