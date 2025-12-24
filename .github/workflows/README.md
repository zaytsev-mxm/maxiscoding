# GitHub Actions Workflows

This directory contains CI/CD workflows for automated deployment.

## Workflows

### 1. Build and Push Docker Image (`build.yml`)

**Trigger**: Automatic on push to `main` branch

**What it does**:
- Builds Docker image using multi-stage Dockerfile
- Pushes image to GitHub Container Registry (ghcr.io)
- Tags image with branch name, commit SHA, and `latest`

**Manual trigger**: Actions > "Build and Push Docker Image" > Run workflow

### 2. Deploy to VM (`deploy.yml`)

**Trigger**: Automatic after successful build, or manual

**What it does**:
- Copies docker-compose.yml and configs to VM
- Pulls latest Docker image
- Restarts containers with new image
- Zero downtime deployment

**Manual trigger**: Actions > "Deploy to VM" > Run workflow
- Optional: Specify custom image tag

### 3. SSL Certificate Setup (`ssl-setup.yml`)

**Trigger**: Manual only

**What it does**:
- Requests SSL certificates from Let's Encrypt
- Configures Nginx with SSL
- Sets up automatic certificate renewal

**Manual trigger**: Actions > "SSL Certificate Setup" > Run workflow
- Required: Email address for certificate notifications

**When to use**: Once after initial deployment

### 4. Update Nginx Configuration (`nginx-update.yml`)

**Trigger**: Manual only

**What it does**:
- Copies updated Nginx configs to VM
- Tests configuration validity
- Reloads Nginx without downtime

**Manual trigger**: Actions > "Update Nginx Configuration" > Run workflow
- Optional: Choose SSL or non-SSL mode

**When to use**: When you modify Nginx configuration files

## Workflow Dependencies

```
Push to main
    |
    v
build.yml (automatic)
    |
    v
deploy.yml (automatic)
```

Manual workflows:
- ssl-setup.yml (run once after first deployment)
- nginx-update.yml (run when Nginx configs change)

## Required Secrets

Configure in: Repository Settings > Secrets and variables > Actions

| Secret | Description | Example |
|--------|-------------|---------|
| VM_IP | VM public IP | 34.123.45.67 |
| SSH_PRIVATE_KEY | Private SSH key | -----BEGIN OPENSSH PRIVATE KEY----- ... |

## Workflow Execution Order

1. **First Time Setup**:
   - Push code → `build.yml` runs
   - `deploy.yml` runs automatically
   - Manually run `ssl-setup.yml`

2. **Regular Updates**:
   - Push code → `build.yml` + `deploy.yml` run automatically

3. **Config Updates**:
   - Modify Nginx configs → Push → Run `nginx-update.yml`

## Monitoring Workflows

- Check status: Repository > Actions tab
- View logs: Click on any workflow run
- Re-run failed workflows: Click "Re-run jobs"
