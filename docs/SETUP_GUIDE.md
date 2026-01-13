# Contact Fixer - Quick Setup Guide

## 🚀 Quick Start (5 Minutes)

This guide will help you set up Contact Fixer with your own Google credentials in a single configuration file.

## Prerequisites

- Python 3.9+
- Flutter SDK
- Google Cloud Project ([Create one here](https://console.cloud.google.com/))

## Step 1: Google Cloud Setup (One-Time)

### 1.1 Enable APIs

Go to [Google Cloud Console](https://console.cloud.google.com/) and enable:
- Google People API
- Google+ API

### 1.2 Create OAuth 2.0 Credentials

Create **THREE** OAuth clients:

#### A. Web Application (for web + backend token exchange)
1. Click "+ CREATE CREDENTIALS" → "OAuth client ID"
2. Type: **Web application**
3. Name: `Contact Fixer Web`
4. Authorized JavaScript origins: *leave empty*
5. Authorized redirect URIs: *leave empty*
6. **Copy the Client ID** → You'll need this

#### B. Android (for mobile app)
1. Get your SHA-1 fingerprint:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android | grep "SHA1:"
   ```
2. Create OAuth client ID → Type: **Android**
3. Package name: `com.contactfixer.frontend`
4. SHA-1: Paste from above
5. **Copy the Client ID**

#### C. Desktop (for backend Python script)
1. Create OAuth client ID → Type: **Desktop**
2. Download JSON → Save as `backend/credentials.json`

## Step 2: Single Configuration File

**ALL your configuration happens in ONE file**: `.env`

Create `/Users/rockgtr/Desktop/Personal/Contact_Fixer/.env`:

```bash
# ============================================================
# CONTACT FIXER CONFIGURATION
# ============================================================
# All credentials and settings in one place!
#
# SECURITY: Never commit this file to git!
# ============================================================

# -----------------------------
# Backend Security Keys
# -----------------------------
# Generate new keys with: python3 -c "import secrets; print(secrets.token_urlsafe(32))"

JWT_SECRET_KEY=YOUR_JWT_SECRET_HERE
ENCRYPTION_KEY=YOUR_ENCRYPTION_KEY_HERE

# -----------------------------
# Google OAuth Client IDs
# -----------------------------
# Get these from: https://console.cloud.google.com/apis/credentials

# Web OAuth Client ID (from Step 1.2.A above)
GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com

# Android OAuth Client ID (from Step 1.2.B above)  
GOOGLE_ANDROID_CLIENT_ID=YOUR_ANDROID_CLIENT_ID.apps.googleusercontent.com

# Desktop credentials file (from Step 1.2.C above)
# Place the downloaded JSON file at: backend/credentials.json

# -----------------------------
# CORS & Security Settings
# -----------------------------
# Allowed origins for web app
CORS_ORIGINS=http://localhost:3000,http://127.0.0.1:3000

# Rate limiting (requests per minute)
RATE_LIMIT_PER_MINUTE=60

# Environment
ENVIRONMENT=development

# -----------------------------
# Optional: Production Settings
# -----------------------------
# Uncomment and update for production deployment:
# CORS_ORIGINS=https://yourdomain.com
# RATE_LIMIT_PER_MINUTE=30
# ENVIRONMENT=production
```

### Generate Security Keys

Run these commands to generate secure keys:

```bash
cd /Users/rockgtr/Desktop/Personal/Contact_Fixer

# Generate JWT secret
python3 -c "import secrets; print('JWT_SECRET_KEY=' + secrets.token_urlsafe(32))"

# Generate encryption key (Fernet format)
python3 -c "from cryptography.fernet import Fernet; print('ENCRYPTION_KEY=' + Fernet.generate_key().decode())"
```

Copy the output and paste into your `.env` file.

## Step 3: Update Frontend Configuration

Edit `frontend/lib/providers/auth_provider.dart` (line 16):

```dart
serverClientId: kIsWeb 
    ? null 
    : 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',  // ← Paste Web Client ID here
```

Edit `frontend/lib/services/web_id_token_provider.dart` if needed (backend URL is localhost:8000 by default).

## Step 4: Run the App

### Backend
```bash
cd /Users/rockgtr/Desktop/Personal/Contact_Fixer
source venv/bin/activate
source .env
uvicorn backend.main:app --reload --host 0.0.0.0
```

### Frontend (Mobile)
```bash
cd frontend
flutter run
```

### Frontend (Web)
```bash
cd frontend  
flutter run -d chrome --web-port=3000
```

## Step 5: First-Time Database Migration

If you have existing contacts, encrypt them:

```bash
source venv/bin/activate
source .env
python3 backend/migrations/migrate_to_secure.py
```

## ✅ Verification Checklist

- [ ] `.env` file created with all credentials
- [ ] Security keys generated
- [ ] Three OAuth clients created in Google Cloud
- [ ] `backend/credentials.json` file present
- [ ] Web Client ID added to `auth_provider.dart`
- [ ] Backend starts without errors
- [ ] Can sign in on mobile
- [ ] Can sign in on web
- [ ] Sync contacts works

## 🔒 Security Best Practices

1. **Never commit `.env` to git** - It's in `.gitignore`
2. **Use different OAuth clients** for dev/prod
3. **Rotate keys regularly** in production
4. **Enable HTTPS** for production deployment
5. **Review logs** in `backend/logs/` directory

## 📊 Monitoring & Logs

Logs are automatically created in:
- `backend/logs/app.log` - General application logs
- `backend/logs/security.log` - Authentication events
- `backend/logs/error.log` - Error tracking

## 🆘 Troubleshooting

### "401 Unauthorized" errors
- Check that OAuth client IDs match in `.env` and code
- Verify `credentials.json` is in `backend/` directory
- Ensure `.env` is loaded: `source .env`

### Web sign-in fails
- Check Web Client ID in both `.env` and `auth_provider.dart`
- Verify CORS_ORIGINS includes `http://localhost:3000`
- Check browser console for errors

### Database errors
- Run migration script if upgrading from old version
- Check ENCRYPTION_KEY is valid Fernet key
- Verify database permissions

## 🚀 Production Deployment

For production, update `.env`:
```bash
CORS_ORIGINS=https://yourdomain.com
ENVIRONMENT=production
RATE_LIMIT_PER_MINUTE=30
```

Set up:
- HTTPS reverse proxy (Nginx/Caddy)
- Separate production OAuth clients
- Database backups
- Log rotation

---

**Need help?** Check the full documentation in `/docs/` directory.

---

**Last Updated**: 2026-01-13  
**Version**: 1.2.4
