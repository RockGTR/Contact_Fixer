# Production Deployment Guide

This guide covers deploying Contact Fixer to a production environment with enterprise-grade security and reliability.

## 📋 Prerequisites

### System Requirements
- **OS**: Ubuntu 20.04+ / Debian 11+ / RHEL 8+
- **Python**: 3.9 or higher
- **Memory**: Minimum 1GB RAM (2GB+ recommended)
- **Storage**: 10GB+ free space
- **Network**: Static IP or domain name with HTTPS support

### Required Software
- Git
- Python 3.9+ with `venv`
- Nginx or Caddy (for reverse proxy)
- Certbot (for SSL certificates)

## 🔐 Step 1: Environment Setup

### 1.1 Clone Repository
```bash
cd /opt
sudo git clone https://github.com/yourusername/contact-fixer.git
cd contact-fixer
```

### 1.2 Create Production `.env`
Copy the production template:
```bash
cp .env.production.example .env
```

Edit `.env` with production values:
```bash
sudo nano .env
```

**Required Changes**:
- Set `ENVIRONMENT=production`
- Update `CORS_ORIGINS` to your production domain
- Generate new security keys (see Step 1.3)
- Add your Google OAuth client IDs
- Set production database path
- Configure logging

### 1.3 Generate Security Keys
Run the key generation script:
```bash
./scripts/generate_prod_keys.sh
```

Copy the output and update your `.env` file:
- `JWT_SECRET_KEY`
- `ENCRYPTION_KEY`

> [!CAUTION]
> **Never** use development keys in production. Always generate new keys for each environment.

### 1.4 Google OAuth Setup
Create **separate** OAuth clients for production:

1. Go to [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Create new OAuth clients:
   - **Web Application** (for production domain)
   - **Android** (with production SHA-1)
3. Configure authorized origins:
   - `https://yourdomain.com`
   - `https://www.yourdomain.com`
4. Update `.env` with production client IDs

## 🐍 Step 2: Backend Setup

### 2.1 Create Virtual Environment
```bash
python3 -m venv venv
source venv/bin/activate
```

### 2.2 Install Dependencies
```bash
pip install --upgrade pip
pip install -r backend/requirements.txt
```

### 2.3 Initialize Database
```bash
# Load environment variables
source .env

# Test backend
uvicorn backend.main:app --host 127.0.0.1 --port 8000

# Should see: "INFO:     Application startup complete"
# Press Ctrl+C to stop
```

### 2.4 Run Database Migration (if upgrading)
If you're upgrading from an existing installation:
```bash
python3 backend/migrations/migrate_to_secure.py
```

## 🌐 Step 3: HTTPS/TLS Setup

Choose **one** of the following reverse proxy options.

### Option A: Nginx (Recommended for most users)

#### Install Nginx
```bash
sudo apt update
sudo apt install nginx certbot python3-certbot-nginx
```

#### Configure Nginx
Copy the example config:
```bash
sudo cp deployment/nginx.conf.example /etc/nginx/sites-available/contact-fixer
```

Edit the configuration:
```bash
sudo nano /etc/nginx/sites-available/contact-fixer
```

Update these values:
- `server_name yourdomain.com www.yourdomain.com;`
- Backend proxy address (default: `http://127.0.0.1:8000`)

Enable the site:
```bash
sudo ln -s /etc/nginx/sites-available/contact-fixer /etc/nginx/sites-enabled/
sudo nginx -t  # Test configuration
sudo systemctl restart nginx
```

#### Obtain SSL Certificate
```bash
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

Follow the prompts. Certbot will automatically:
- Obtain SSL certificate
- Configure HTTPS in Nginx
- Set up auto-renewal

### Option B: Caddy (Simpler, auto-HTTPS)

#### Install Caddy
```bash
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy
```

#### Configure Caddy
```bash
sudo cp deployment/Caddyfile.example /etc/caddy/Caddyfile
sudo nano /etc/caddy/Caddyfile
```

Update `yourdomain.com` to your actual domain.

Restart Caddy:
```bash
sudo systemctl restart caddy
```

Caddy automatically obtains and renews SSL certificates.

## 🚀 Step 4: Systemd Service Setup

### 4.1 Install Service
```bash
sudo cp deployment/systemd/contact-fixer.service /etc/systemd/system/
sudo nano /etc/systemd/system/contact-fixer.service
```

Update paths if needed:
- `WorkingDirectory=/opt/contact-fixer`
- `EnvironmentFile=/opt/contact-fixer/.env`

### 4.2 Enable and Start Service
```bash
sudo systemctl daemon-reload
sudo systemctl enable contact-fixer
sudo systemctl start contact-fixer
```

### 4.3 Verify Service Status
```bash
sudo systemctl status contact-fixer
```

You should see: `Active: active (running)`

View logs:
```bash
sudo journalctl -u contact-fixer -f
```

## 📊 Step 5: Database Backup

### 5.1 Configure Automated Backups
```bash
# Make script executable
chmod +x scripts/backup_database.sh

# Test backup
./scripts/backup_database.sh

# Add to crontab (daily at 2 AM)
sudo crontab -e
```

Add this line:
```cron
0 2 * * * /opt/contact-fixer/scripts/backup_database.sh
```

### 5.2 Backup Strategy
- **Frequency**: Daily automatic backups
- **Retention**: 7 days (configurable in script)
- **Storage**: Encrypted backups in `/opt/contact-fixer/backups/`
- **Monitoring**: Check backup logs in `/opt/contact-fixer/backend/logs/backup.log`

## 📝 Step 6: Logging & Monitoring

### 6.1 Log Rotation
Create logrotate configuration:
```bash
sudo nano /etc/logrotate.d/contact-fixer
```

Add:
```
/opt/contact-fixer/backend/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 0640 www-data www-data
    sharedscripts
}
```

### 6.2 Monitor Logs
```bash
# Application logs
tail -f backend/logs/app.log

# Security events
tail -f backend/logs/security.log

# Error logs
tail -f backend/logs/error.log
```

## ✅ Step 7: Verification Checklist

- [ ] Backend starts without errors
- [ ] HTTPS works (visit `https://yourdomain.com`)
- [ ] Google Sign-In works on mobile app
- [ ] Google Sign-In works on web app
- [ ] Contacts can be synced
- [ ] Changes can be staged and pushed
- [ ] Rate limiting is enforced
- [ ] Logs are being written
- [ ] Backups are running
- [ ] Systemd service auto-restarts on failure

## 🔒 Security Hardening

### Firewall Configuration
```bash
# Allow only necessary ports
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP (Certbot)
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable
```

### File Permissions
```bash
# Secure .env file
chmod 600 .env

# Secure database
chmod 600 backend/contacts.db

# Secure logs
chmod 700 backend/logs
```

### Regular Updates
```bash
# Update system packages
sudo apt update && sudo apt upgrade

# Update Python dependencies
source venv/bin/activate
pip install --upgrade -r backend/requirements.txt
```

## 🛠️ Maintenance

### Restart Application
```bash
sudo systemctl restart contact-fixer
```

### View Service Logs
```bash
sudo journalctl -u contact-fixer -n 100 --no-pager
```

### Database Maintenance
```bash
# Manual backup
./scripts/backup_database.sh

# Restore from backup
cp backups/contacts_YYYY-MM-DD_HH-MM-SS.db backend/contacts.db
sudo systemctl restart contact-fixer
```

### Update Application
```bash
cd /opt/contact-fixer
git pull origin main
source venv/bin/activate
pip install -r backend/requirements.txt
sudo systemctl restart contact-fixer
```

## 🚨 Troubleshooting

### Backend Won't Start
Check logs:
```bash
sudo journalctl -u contact-fixer -n 50
```

Common issues:
- Missing `.env` file
- Invalid encryption key
- Port 8000 already in use

### HTTPS Not Working
Test Nginx:
```bash
sudo nginx -t
sudo systemctl status nginx
```

Renew SSL certificate:
```bash
sudo certbot renew --dry-run
```

### Database Errors
Check file permissions:
```bash
ls -la backend/contacts.db
```

Restore from backup if corrupted:
```bash
./scripts/backup_database.sh  # Create current backup first
cp backups/contacts_LATEST.db backend/contacts.db
sudo systemctl restart contact-fixer
```

## 📞 Support

For issues and questions:
- Review [Troubleshooting Guide](TROUBLESHOOTING.md)
- Check [Security Best Practices](SECURITY.md)
- Review system logs
- Contact your system administrator

---

**Last Updated**: 2026-01-08  
**Version**: 1.2.4 Production Guide
