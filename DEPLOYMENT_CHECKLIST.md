# Deployment Checklist for maxiscoding.dev

Use this checklist to ensure all steps are completed correctly.

## Pre-Deployment Checklist

### Domain Configuration
- [ ] Domain `maxiscoding.dev` purchased and owned
- [ ] DNS A record for `maxiscoding.dev` points to VM IP
- [ ] DNS A record for `www.maxiscoding.dev` points to VM IP
- [ ] DNS propagation completed (check with `dig maxiscoding.dev`)

### Google Cloud VM
- [ ] Debian VM created on Google Cloud
- [ ] VM has public static IP address (note the IP: _______________)
- [ ] Firewall rules allow ports 22, 80, 443
- [ ] SSH access as root configured
- [ ] VM is running and accessible

### Local Machine
- [ ] Git installed
- [ ] SSH client installed
- [ ] GitHub account set up
- [ ] Repository access configured

## Initial Setup (One-Time)

### Step 1: System Setup (as root)
- [ ] SSH into VM as root: `ssh root@VM_IP`
- [ ] Download system setup script:
  ```bash
  wget https://raw.githubusercontent.com/YOUR_USERNAME/maxiscoding/main/scripts/setup-system.sh
  ```
- [ ] Make script executable: `chmod +x setup-system.sh`
- [ ] Run setup script: `sudo ./setup-system.sh`
- [ ] Verify Docker installed: `docker --version`
- [ ] Verify Docker Compose installed: `docker compose version`
- [ ] Verify deployer user created: `id deployer`
- [ ] Verify firewall configured: `sudo ufw status`

### Step 1b: App Setup (as deployer)
- [ ] Add SSH key: `echo "YOUR_KEY" >> /home/deployer/.ssh/authorized_keys`
- [ ] Switch to deployer user: `su - deployer`
- [ ] Download app setup script:
  ```bash
  cd /opt/maxiscoding
  wget https://raw.githubusercontent.com/YOUR_USERNAME/maxiscoding/main/scripts/setup-app.sh
  ```
- [ ] Make script executable: `chmod +x setup-app.sh`
- [ ] Run app setup: `./setup-app.sh`
- [ ] Verify certbot directories created: `ls -la /opt/maxiscoding/certbot`

### Step 2: SSH Key Setup
- [ ] Generate SSH key pair on local machine:
  ```bash
  ssh-keygen -t ed25519 -C "github-actions@maxiscoding.dev" -f ~/.ssh/maxiscoding_deploy
  ```
- [ ] Note location of private key: ~/.ssh/maxiscoding_deploy
- [ ] Note location of public key: ~/.ssh/maxiscoding_deploy.pub
- [ ] Copy public key to VM:
  ```bash
  ssh-copy-id -i ~/.ssh/maxiscoding_deploy.pub deployer@VM_IP
  ```
  OR manually:
  ```bash
  ssh deployer@VM_IP
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh
  echo "PASTE_PUBLIC_KEY" >> ~/.ssh/authorized_keys
  chmod 600 ~/.ssh/authorized_keys
  exit
  ```
- [ ] Test SSH connection: `ssh -i ~/.ssh/maxiscoding_deploy deployer@VM_IP`
- [ ] Verify connection works without password

### Step 3: GitHub Repository Setup
- [ ] Repository created on GitHub
- [ ] Code pushed to repository
- [ ] Repository visibility set (public or private)
- [ ] GitHub Actions enabled

### Step 4: GitHub Secrets Configuration
- [ ] Navigate to: Repository > Settings > Secrets and variables > Actions
- [ ] Add secret `VM_IP`:
  - Name: `VM_IP`
  - Value: Your VM IP address (e.g., 34.123.45.67)
  - [ ] Secret added successfully
- [ ] Add secret `SSH_PRIVATE_KEY`:
  - Name: `SSH_PRIVATE_KEY`
  - Value: Contents of ~/.ssh/maxiscoding_deploy (entire file)
  - Copy with: `cat ~/.ssh/maxiscoding_deploy | pbcopy` (macOS) or `cat ~/.ssh/maxiscoding_deploy`
  - Include BEGIN and END lines
  - [ ] Secret added successfully
- [ ] Verify both secrets are listed in repository settings

## First Deployment

### Step 5: Push Code to Trigger Build
- [ ] Ensure all infrastructure files are committed
- [ ] Check status: `git status`
- [ ] Add files: `git add .`
- [ ] Commit: `git commit -m "Setup deployment infrastructure"`
- [ ] Push: `git push origin main`
- [ ] Navigate to GitHub Actions tab
- [ ] Verify "Build and Push Docker Image" workflow started
- [ ] Wait for build to complete (usually 3-5 minutes)
- [ ] Verify build succeeded (green checkmark)
- [ ] Verify "Deploy to VM" workflow started automatically
- [ ] Wait for deployment to complete (usually 1-2 minutes)
- [ ] Verify deployment succeeded (green checkmark)

### Step 6: Verify Initial Deployment (HTTP)
- [ ] Visit `http://maxiscoding.dev` in browser
- [ ] Application loads successfully
- [ ] No errors in browser console
- [ ] SSH to VM: `ssh deployer@VM_IP`
- [ ] Navigate to app directory: `cd /opt/maxiscoding`
- [ ] Check containers running: `docker compose ps`
- [ ] Verify 3 containers running: nextjs, nginx, certbot
- [ ] Check application logs: `docker compose logs nextjs --tail=50`
- [ ] Check nginx logs: `docker compose logs nginx --tail=50`
- [ ] No errors in logs

## SSL Certificate Setup

### Step 7: Setup SSL Certificates
- [ ] Navigate to GitHub Actions tab
- [ ] Click on "SSL Certificate Setup" workflow
- [ ] Click "Run workflow" button
- [ ] Enter email address for certificate notifications: _____________
- [ ] Click "Run workflow" button
- [ ] Wait for workflow to complete (usually 2-3 minutes)
- [ ] Verify workflow succeeded (green checkmark)
- [ ] Review workflow logs for any errors

### Step 8: Verify HTTPS Working
- [ ] Visit `https://maxiscoding.dev` in browser
- [ ] Certificate is valid (padlock icon appears)
- [ ] No certificate warnings
- [ ] Application loads over HTTPS
- [ ] Visit `http://maxiscoding.dev` - should redirect to HTTPS
- [ ] Check certificate details in browser:
  - Issued by: Let's Encrypt
  - Valid for: maxiscoding.dev and www.maxiscoding.dev
  - Expiration date: ~90 days from now
- [ ] Test with curl: `curl -I https://maxiscoding.dev`
- [ ] Verify response is 200 OK

## Post-Deployment Verification

### Step 9: Final Checks
- [ ] SSH into VM: `ssh deployer@VM_IP`
- [ ] Check all containers healthy: `docker compose ps`
- [ ] View application logs: `docker compose logs -f nextjs` (Ctrl+C to exit)
- [ ] No errors or warnings in logs
- [ ] Check disk space: `df -h`
- [ ] Check memory usage: `free -h`
- [ ] Verify firewall: `sudo ufw status`
- [ ] Test from multiple browsers (Chrome, Firefox, Safari)
- [ ] Test from mobile device
- [ ] Test www subdomain: `https://www.maxiscoding.dev`

### Step 10: Security Verification
- [ ] SSL Labs test: Visit `https://www.ssllabs.com/ssltest/analyze.html?d=maxiscoding.dev`
- [ ] Verify grade A or higher
- [ ] Check security headers are present:
  ```bash
  curl -I https://maxiscoding.dev
  ```
  - [ ] Strict-Transport-Security header present
  - [ ] X-Frame-Options header present
  - [ ] X-Content-Type-Options header present
  - [ ] X-XSS-Protection header present

## Documentation Review

### Step 11: Review Documentation
- [ ] Read [DEPLOYMENT.md](./DEPLOYMENT.md) - comprehensive guide
- [ ] Read [INFRASTRUCTURE.md](./INFRASTRUCTURE.md) - quick reference
- [ ] Read [README.deployment.md](./README.deployment.md) - quick start
- [ ] Bookmark for future reference

## Continuous Deployment Setup Verification

### Step 12: Test Automatic Deployment
- [ ] Make a small change to application code
- [ ] Commit change: `git commit -am "Test deployment"`
- [ ] Push: `git push origin main`
- [ ] Verify build workflow runs automatically
- [ ] Verify deploy workflow runs automatically after build
- [ ] Wait for deployment to complete
- [ ] Verify change appears on live site: `https://maxiscoding.dev`
- [ ] Check no downtime occurred

## Monitoring Setup

### Step 13: Set Up Monitoring (Optional)
- [ ] Bookmark GitHub Actions page for quick access
- [ ] Set up email notifications for workflow failures (if desired)
- [ ] Set up uptime monitoring service (optional):
  - UptimeRobot: https://uptimerobot.com/
  - Pingdom: https://www.pingdom.com/
  - StatusCake: https://www.statuscake.com/
- [ ] Configure alert email/SMS for downtime

## Backup Plan

### Step 14: Backup Strategy
- [ ] Document VM IP address: _______________
- [ ] Save SSH private key securely
- [ ] Document GitHub secrets location
- [ ] Create backup script schedule (optional):
  ```bash
  # On VM, create backup
  cd /opt/maxiscoding
  tar -czf backup-$(date +%Y%m%d).tar.gz \
    docker-compose.yml nginx/ certbot/ .env.production
  ```
- [ ] Test backup restore procedure

## Troubleshooting Checklist

If something goes wrong, check these:

### Application Not Loading
- [ ] Check DNS: `dig maxiscoding.dev`
- [ ] Check VM is running: `gcloud compute instances list`
- [ ] Check firewall: `sudo ufw status`
- [ ] Check containers: `docker compose ps`
- [ ] Check logs: `docker compose logs`

### SSL Issues
- [ ] Check DNS propagation: `dig maxiscoding.dev`
- [ ] Check certificate files: `ls -la /opt/maxiscoding/certbot/conf/live/`
- [ ] Check Certbot logs: `docker compose logs certbot`
- [ ] Re-run SSL setup workflow

### Deployment Fails
- [ ] Check GitHub Actions logs
- [ ] Verify GitHub secrets are correct
- [ ] Test SSH manually: `ssh deployer@VM_IP`
- [ ] Check VM disk space: `df -h`
- [ ] Check Docker is running: `systemctl status docker`

## Maintenance Schedule

### Regular Maintenance Tasks
- [ ] Weekly: Review application logs
- [ ] Weekly: Check disk space
- [ ] Monthly: Review SSL certificate expiration
- [ ] Monthly: Update system packages on VM
- [ ] Quarterly: Review and update Docker images
- [ ] Quarterly: Review security headers and SSL configuration

## Success Criteria

Deployment is successful when ALL of these are true:
- [ ] Application accessible at https://maxiscoding.dev
- [ ] HTTPS certificate is valid
- [ ] HTTP redirects to HTTPS
- [ ] No errors in application logs
- [ ] Automatic deployments work (push to main → live)
- [ ] All containers running and healthy
- [ ] Local development still works with `npm run dev`

## Notes and Issues

Record any issues encountered and their solutions:

```
Date: ___________
Issue:





Solution:





```

```
Date: ___________
Issue:





Solution:





```

## Sign-Off

- [ ] All steps completed successfully
- [ ] Application is live and working
- [ ] Team notified of successful deployment
- [ ] Documentation updated if needed

Deployed by: ___________________
Date: ___________________
Verification by: ___________________

## Quick Reference Commands

```bash
# SSH to VM
ssh deployer@VM_IP

# Check containers
cd /opt/maxiscoding && docker compose ps

# View logs
docker compose logs -f nextjs

# Restart application
docker compose restart nextjs

# Full restart
docker compose down && docker compose up -d

# Pull latest code and redeploy
# (Just push to GitHub, it will auto-deploy)
git push origin main
```

## Support Resources

- Full Documentation: [DEPLOYMENT.md](./DEPLOYMENT.md)
- Quick Reference: [INFRASTRUCTURE.md](./INFRASTRUCTURE.md)
- Architecture: [ARCHITECTURE.txt](./ARCHITECTURE.txt)
- Workflow Docs: [.github/workflows/README.md](./.github/workflows/README.md)

---

**Note**: Keep this checklist for future deployments and updates. It can also serve as a template for deploying to additional environments (staging, testing, etc.).
