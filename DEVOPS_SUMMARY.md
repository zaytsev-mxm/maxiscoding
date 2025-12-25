# DevOps Infrastructure Summary

This document summarizes the deployment infrastructure set up for **maxiscoding.dev** - a Next.js application deployed to a Google Cloud VM using Docker, Nginx, and GitHub Actions.

## Architecture Overview

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

## Files Created

### Docker Configuration

| File | Purpose |
|------|---------|
| `Dockerfile` | Multi-stage production build for Next.js |
| `docker-compose.yml` | Production orchestration (Next.js + Nginx + Certbot) |
| `docker-compose.dev.yml` | Optional local Docker testing |
| `.dockerignore` | Excludes unnecessary files from Docker builds |

### Nginx Configuration

| File | Purpose |
|------|---------|
| `nginx/nginx.conf` | Main Nginx config with performance optimizations |
| `nginx/conf.d/default.conf` | HTTPS server configuration with SSL |
| `nginx/conf.d/default-nossl.conf` | HTTP-only config for initial SSL setup |

### Deployment Scripts

| File | Purpose |
|------|---------|
| `scripts/setup-system.sh` | System setup (run as root) |
| `scripts/setup-app.sh` | App setup (run as deployer) |
| `scripts/setup-ssl.sh` | SSL certificate acquisition via Certbot |
| `scripts/deploy.sh` | Application deployment (pull image, restart containers) |
| `scripts/update-nginx.sh` | Nginx configuration updates |

### GitHub Actions Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `.github/workflows/build.yml` | Push to `main` | Build Docker image, push to ghcr.io |
| `.github/workflows/deploy.yml` | After successful build | Deploy to VM via SSH |
| `.github/workflows/ssl-setup.yml` | Manual | Initial SSL certificate setup |
| `.github/workflows/nginx-update.yml` | Manual | Update Nginx configuration on VM |

---

## Detailed File Descriptions

### 1. Dockerfile

A multi-stage build optimized for production:

```dockerfile
# Stage 1: deps     - Install all dependencies
# Stage 2: builder  - Build the Next.js application
# Stage 3: runner   - Minimal production image
```

**Key features:**
- Uses `node:20-alpine` for minimal image size
- Leverages Next.js `standalone` output mode
- Runs as non-root user (`nextjs:nodejs`) for security
- Disables telemetry in production
- Final image contains only production dependencies

### 2. docker-compose.yml

Production stack with three services:

```yaml
services:
  nextjs:     # The Next.js application container
  nginx:      # Reverse proxy with SSL termination
  certbot:    # Automatic SSL certificate renewal
```

**Key features:**
- Uses Docker bridge network for inter-container communication
- Health checks for the Next.js container
- Nginx reloads every 6 hours to pick up renewed certificates
- Certbot renews certificates every 12 hours
- All volumes mounted for persistence

### 3. Nginx Configuration

**`nginx/nginx.conf`** - Main configuration:
- Worker process auto-scaling
- Gzip compression for text/JSON/CSS/JS
- Connection optimizations (keepalive, sendfile, tcp_nopush)
- Security hardening (server_tokens off)

**`nginx/conf.d/default.conf`** - HTTPS server:
- HTTP to HTTPS redirect
- Let's Encrypt ACME challenge handling
- TLS 1.2/1.3 with modern cipher suite
- Security headers (HSTS, X-Frame-Options, X-Content-Type-Options)
- Reverse proxy to Next.js with WebSocket support
- Static asset caching for `/_next/static`

### 4. VM Setup Scripts

The VM setup is split into two scripts for proper privilege separation:

#### `scripts/setup-system.sh` (run as admin with sudo)

System-level setup. Assumes users already exist (created via GCP SSH metadata):

1. **Verifies deployer user exists** - Fails if not created via GCP
2. **System updates** - `apt-get update && upgrade`
3. **Docker installation** - Official Docker CE + Compose plugin
4. **Docker group** - Adds deployer to docker group
5. **Directory structure** - `/opt/maxiscoding` owned by deployer
6. **Docker log rotation** - 10MB max, 3 files retained

#### `scripts/setup-app.sh` (run as deployer)

Application-level setup (no sudo required):

1. **Docker access verification** - Ensures deployer can use Docker
2. **Certbot directories** - Creates SSL certificate directories
3. **Log directories** - Creates application log directories

### 5. GitHub Actions Workflows

#### Build Workflow (`build.yml`)

**Triggers:** Push to `main`, PRs to `main`, manual dispatch

**Steps:**
1. Checkout code
2. Set up Docker Buildx
3. Login to GitHub Container Registry (ghcr.io)
4. Extract metadata (tags, labels)
5. Build and push image with caching

**Image tags generated:**
- `latest` (for main branch)
- `main-<sha>` (commit-specific)
- Branch/PR name

#### Deploy Workflow (`deploy.yml`)

**Triggers:** After successful build, manual dispatch

**Steps:**
1. Checkout code
2. Set up SSH connection to VM
3. Copy `docker-compose.yml`, `nginx/`, and `deploy.sh` to VM
4. Execute deployment script on VM
5. Verify container status
6. Cleanup SSH keys

#### SSL Setup Workflow (`ssl-setup.yml`)

**Triggers:** Manual only (requires email input)

**Steps:**
1. Copy SSL setup script to VM
2. Switch to non-SSL Nginx config (for ACME challenge)
3. Run Certbot to obtain certificates
4. Restore SSL Nginx config
5. Verify certificates installed

#### Nginx Update Workflow (`nginx-update.yml`)

**Triggers:** Manual only (choose SSL or no-SSL)

**Steps:**
1. Copy latest Nginx configs to VM
2. Run update script with SSL preference
3. Reload Nginx and verify status

---

## GitHub Secrets Required

| Secret | Description |
|--------|-------------|
| `VM_IP` | IP address of the Google Cloud VM |
| `SSH_PRIVATE_KEY` | Private SSH key for the `deployer` user |

> `GITHUB_TOKEN` is automatically provided by GitHub Actions.

---

## Deployment Flow

### Initial Setup (One-time)

```bash
# 1. Add SSH keys to GCP VM metadata (creates admin + deployer users)
#    admin:ssh-ed25519 AAAA...
#    deployer:ssh-ed25519 AAAA...

# 2. SSH as admin and run system setup
ssh -i ~/.ssh/gcp_admin_ed25519 admin@VM_IP
curl -O https://raw.githubusercontent.com/YOUR_REPO/main/scripts/setup-system.sh
chmod +x setup-system.sh
sudo ./setup-system.sh

# 3. SSH as deployer and run app setup (new session for docker group)
ssh -i ~/.ssh/gcp_deployer_ed25519 deployer@VM_IP
cd /opt/maxiscoding
curl -O https://raw.githubusercontent.com/YOUR_REPO/main/scripts/setup-app.sh
chmod +x setup-app.sh
./setup-app.sh

# 4. In GitHub repository settings
#    Add secrets: VM_IP, SSH_PRIVATE_KEY (deployer's private key)

# 5. Push code to trigger first deployment
git push origin main

# 6. Run SSL Setup workflow from GitHub Actions UI
```

### Continuous Deployment

After initial setup, every push to `main`:

1. **Build workflow** triggers automatically
2. Docker image is built and pushed to `ghcr.io/OWNER/maxiscoding:latest`
3. **Deploy workflow** triggers on successful build
4. VM pulls new image and restarts containers
5. Zero-downtime deployment complete

---

## Local Development

Local development remains unchanged:

```bash
npm run dev    # Starts Next.js on localhost:3000
```

Docker is only used for production builds and deployment. The `docker-compose.dev.yml` is optional for testing the production build locally:

```bash
docker compose -f docker-compose.dev.yml up --build
```

---

## Security Features

1. **Non-root containers** - Next.js runs as `nextjs` user (UID 1001)
2. **TLS 1.2+** - Modern SSL protocols only
3. **Security headers** - HSTS, X-Frame-Options, X-Content-Type-Options, X-XSS-Protection
4. **Firewall** - Only ports 22, 80, 443 open
5. **Automatic certificate renewal** - Certbot runs every 12 hours
6. **SSH key authentication** - No password auth for deployments

---

## Maintenance Commands

```bash
# SSH into VM
ssh deployer@<VM_IP>

# View logs
cd /opt/maxiscoding
docker compose logs -f nextjs    # App logs
docker compose logs -f nginx     # Nginx logs

# Restart services
docker compose restart nextjs
docker compose restart nginx

# Check container status
docker compose ps

# Manual certificate renewal
docker compose run --rm certbot renew

# View certificate expiry
docker compose run --rm certbot certificates
```

---

## File Tree

```
maxiscoding/
├── .dockerignore
├── .github/
│   └── workflows/
│       ├── build.yml           # Build and push Docker image
│       ├── deploy.yml          # Deploy to VM
│       ├── nginx-update.yml    # Update Nginx config
│       ├── ssl-setup.yml       # Initial SSL setup
│       └── README.md
├── Dockerfile
├── docker-compose.yml
├── docker-compose.dev.yml
├── nginx/
│   ├── nginx.conf
│   └── conf.d/
│       ├── default.conf        # HTTPS config
│       └── default-nossl.conf  # HTTP-only config
├── scripts/
│   ├── deploy.sh
│   ├── setup-ssl.sh
│   ├── setup-system.sh
│   ├── setup-app.sh
│   └── update-nginx.sh
├── next.config.ts              # Modified: added output: 'standalone'
└── package.json
```

---

## Summary

This infrastructure provides:

- **Containerized deployment** via Docker with multi-stage builds
- **Automated CI/CD** via GitHub Actions
- **SSL/TLS** via Let's Encrypt with auto-renewal
- **Reverse proxy** via Nginx with performance optimizations
- **Infrastructure as code** - all configs versioned in the repository
- **Minimal manual setup** - single script to initialize VM
- **Security hardened** - non-root containers, modern TLS, firewall rules

The setup separates concerns across multiple workflows, allowing independent updates to the application, Nginx configuration, or SSL certificates.
