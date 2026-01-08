# Contact Fixer

A powerful, **security-hardened** utility app to fix, standardize, and format phone numbers in your Google Contacts. Features encryption, authentication, and enterprise-grade security for production use.

## 🔒 Security Features (v1.0+)

- ✅ **Google ID Token Authentication** - Only authenticated users can access API
- ✅ **Field-Level Encryption** - Sensitive data encrypted at rest (AES-256)
- ✅ **Multi-User Support** - Complete data isolation between users
- ✅ **Rate Limiting** - Protection against abuse
- ✅ **Input Validation** - Strict validation on all inputs
- ✅ **Security Headers** - CORS, XSS, clickjacking protection
- ✅ **Audit Logging** - Security event tracking

## Features

- **Smart Analysis**: Scans your contacts to identify numbers with missing country codes or incorrect formatting.
- **Interactive "Phone Fixer"**:
  - **Swipe Interface**: Tinder-style card interface to quickly Accept (Right), Skip (Left), or Edit (Up) suggestions.
  - **List View**: Bulk review changes in a traditional list format.
- **Region Support**: Automatically suggests country codes based on your selected region.
- **Safe Syncing**: Changes are staged first. You review them before they are physically pushed to Google Contacts.
- **Undo/Rollback**: Staged changes can be modified or deleted before syncing.
- **Privacy Focused**: All data encrypted and runs locally on your machine.

## Tech Stack

- **Backend**: Python (FastAPI), Google People API
- **Frontend**: Flutter (Mobile/Web), Material Design 3
- **Security**: Fernet encryption, Google OAuth 2.0, JWT-ready

## Prerequisites

- Python 3.9+
- Flutter SDK (3.x+)
- Google Cloud Project with "Google People API" enabled and `credentials.json`

---

## 🚀 Setup Guide

### 1. Backend Setup

#### Clone and Enter Directory
```bash
git clone https://github.com/yourusername/Contact_Fixer.git
cd Contact_Fixer
```

#### Create Virtual Environment
```bash
python3 -m venv venv
source venv/bin/activate  # macOS/Linux
# .\\venv\\Scripts\\activate  # Windows
```

#### Install Dependencies
```bash
pip install -r backend/requirements.txt
```

#### Configure Environment Variables

Create `.env` file in the project root:

```bash
# Copy template
cp .env.example .env
```

Edit `.env` with secure values:
## 🚀 Quick Setup

**New to Contact Fixer?** Follow our [📖 Complete Setup Guide](docs/SETUP_GUIDE.md) for step-by-step instructions.

### Prerequisites

- Python 3.9+ with `venv`
- Flutter SDK 3.0+
- Google Cloud Project with People API enabled

### Quick Start

1. **Clone and setup**:
   ```bash
   git clone https://github.com/yourusername/contact-fixer.git
   cd contact-fixer
   ```

2. **Configure credentials** (see [Setup Guide](docs/SETUP_GUIDE.md)):
   - Copy `.env.example` to `.env`
   - Add your Google OAuth client IDs
   - Generate security keys

3. **Run backend**:
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   pip install -r backend/requirements.txt
   source .env
   uvicorn backend.main:app --reload --host 0.0.0.0
   ```

4. **Run frontend**:
   ```bash
   cd frontend
   flutter pub get
   flutter run  # or: flutter run -d chrome --web-port=3000
   ```

For detailed setup including Google Cloud configuration, see [docs/SETUP_GUIDE.md](docs/SETUP_GUIDE.md).

If you have an existing database, migrate it:

```bash
python3 backend/migrations/migrate_to_secure.py
```

This will:
- Create a backup of your existing database
- Add user tracking columns
- Encrypt all sensitive fields
- Create performance indexes

####  Start the Backend Server
```bash
uvicorn backend.main:app --reload --host 0.0.0.0
```

Server will be available at: `http://localhost:8000`

Check health: `http://localhost:8000/health`

---

### 2. Frontend Setup

#### Navigate to Frontend
```bash
cd frontend
```

#### Install Dependencies
```bash
flutter pub get
```

#### Run the App

**For Web:**
```bash
flutter run -d chrome --web-port 3000
```

**For Android:**
```bash
flutter run
```

**For iOS:**
```bash
flutter run
```

---

## 📖 Documentation

- **[🚀 Setup Guide](docs/SETUP_GUIDE.md)** - Quick start & single-file configuration
- **[🏭 Production Deployment](docs/PRODUCTION_DEPLOYMENT.md)** - Complete production deployment guide
- **[Architecture](docs/ARCHITECTURE.md)** - System design and data flow
- **[API Reference](docs/API_REFERENCE.md)** - Backend API endpoints
- **[Security Best Practices](docs/SECURITY.md)** - Production deployment security
- **[Google OAuth Setup](docs/GOOGLE_OAUTH_SETUP.md)** - ID token configuration
- **[Frontend Documentation](docs/FRONTEND_DOCUMENTATION.md)** - UI components
- **[Function Documentation](docs/FUNCTION_DOCUMENTATION.md)** - Core functions
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and solutions

---

## 🔐 Production Deployment

Before deploying to production:

1. **Set `ENVIRONMENT=production` in `.env`**
2. **Deploy behind HTTPS** (use nginx/Caddy reverse proxy)
3. **Update CORS_ORIGINS** to your production domain
4. **Use separate Google OAuth credentials** for production
5. **Run security migration** if upgrading from v0.x
6. **Set up log monitoring** and alerts

See [docs/SECURITY.md](docs/SECURITY.md) for complete checklist.

---

## 🎯 How It Works

1. **Authenticate**: Sign in with Google (frontend)
2. **Sync**: Backend fetches your contacts from Google People API
3. **Analyze**: Phone numbers are parsed and validated against E.164 standard
4. **Review**: Use Swipe or List view to accept/reject/edit suggestions
5. **Stage**: Approved changes are staged locally (encrypted)
6. **Push**: Batch push all changes to Google Contacts

All contact data is encrypted at rest and isolated per user.

---

## 🛠️ Development

### Backend
- FastAPI with automatic OpenAPI docs at `/docs`
- Rate limiting: 60 req/min (configurable)
- Logging: Structured logs with security events

### Frontend 
- Provider pattern for state management
- Google Sign-In for authentication
- ID tokens sent with every API request

---

## 🤝 Contributing

Security contributions are especially welcome! Please:
1. Report vulnerabilities privately
2. Follow secure coding practices
3. Include tests for new features
4. Update documentation

---

## 📜 License

MIT License - See LICENSE file

---

## ⚙️ Troubleshooting

### "Authentication expired" error
- Sign out and sign in again
- Check that frontend is sending ID tokens

### Database errors
- Ensure `.env` has correct `ENCRYPTION_KEY`
- Run migration if upgrading: `python3 backend/migrations/migrate_to_secure.py`

### 401 Unauthorized
- Check that backend is running
- Verify Google Sign-In is working in frontend
- Check browser console for token errors

### Rate limit errors (429)
- Increase `RATE_LIMIT_PER_MINUTE` in `.env`
- Wait a minute and try again

For more help, see [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
