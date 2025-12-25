# GCP VM SSH Setup with Ed25519 Keys

Setting up SSH access for admin and deployer users on Google Cloud VM.

## Step 1: Generate the two SSH key pairs

```bash
# Admin key (for your personal use)
ssh-keygen -t ed25519 -C "admin@maxiscoding.dev" -f ~/.ssh/gcp_admin_ed25519

# Deployer key (for GitHub Actions)
ssh-keygen -t ed25519 -C "deployer@maxiscoding.dev" -f ~/.ssh/gcp_deployer_ed25519
```

Set a passphrase for the admin key if you want extra security. Leave the deployer key without a passphrase for GitHub Actions automation.

## Step 2: View and copy the public keys

```bash
# Admin public key
cat ~/.ssh/gcp_admin_ed25519.pub

# Deployer public key
cat ~/.ssh/gcp_deployer_ed25519.pub
```

## Step 3: Add both keys to your GCP VM

1. Go to **Compute Engine > VM instances**
2. Click your VM instance
3. Click **Edit**
4. Scroll to **SSH Keys**
5. Click **Add Item** and paste the **admin** public key
6. Click **Add Item** again and paste the **deployer** public key
7. Click **Save**

The usernames will be `admin` and `deployer` respectively (extracted from before the @ symbol).

## Step 4: Configure SSH on your Mac

Edit `~/.ssh/config`:

```bash
nano ~/.ssh/config
```

Add:

```
Host gcp-admin
    HostName YOUR_EXTERNAL_IP
    User admin
    IdentityFile ~/.ssh/gcp_admin_ed25519
    IdentitiesOnly yes
```

Connect with:
```bash
ssh gcp-admin
```

## Step 5: For GitHub Actions

Add these secrets to your repository (Settings > Secrets and variables > Actions):

**SSH_PRIVATE_KEY:**
```bash
cat ~/.ssh/gcp_deployer_ed25519
```

**VM_IP:** Your VM's external IP address