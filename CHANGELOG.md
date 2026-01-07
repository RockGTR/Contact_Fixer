# Contact Fixer - Change Log

## Version 1.2 - Security & Web Support (2026-01-07)

### 🔐 Security Enhancements
- **Google OAuth Authentication**: Secure sign-in on both web and mobile platforms
- **Field-Level Encryption**: All sensitive data encrypted at rest using AES-256 (Fernet)
- **Multi-User Support**: Complete data isolation per user with email-based filtering
- **Rate Limiting**: Protection against abuse (60 requests/minute per user)
- **Audit Logging**: Comprehensive logging of all authentication and security events
- **Security Headers**: CORS, XSS, and clickjacking protection

### 🌐 Web Platform Support
- **Web Authentication**: Backend token exchange for web OAuth tokens
- **Cross-Platform**: Single codebase supports mobile (Android/iOS) and web (Chrome/Firefox/Safari)
- **Platform-Specific Auth**: ID tokens for mobile, access_token exchange for web
- **CORS Configuration**: Secure cross-origin requests with configurable origins

### 📊 Logging & Monitoring
- **Structured Logging**: Comprehensive logging across all backend components
- **Security Audit Trail**: Detailed tracking of authentication events
- **Error Tracking**: Enhanced error logging with stack traces
- **Performance Metrics**: Request/response logging for analytics

### 📝 Documentation
- **Setup Guide**: Single-file configuration guide (`docs/SETUP_GUIDE.md`)
- **Environment Template**: Complete `.env.example` with all options documented
- **OAuth Guide**: Comprehensive Google OAuth setup instructions
- **Troubleshooting**: Common issues and solutions documented

### 🔧 Developer Experience
- **Single-File Config**: All credentials in one `.env` file
- **Improved Logging**: Better error messages and debugging information
- **Database Migration**: Automated migration script for existing databases
- **Development Mode**: Enhanced debugging with verbose logging

### 🐛 Bug Fixes
- Fixed ID token generation on web (using backend token exchange)
- Fixed authentication middleware to handle both ID tokens and access_tokens
- Fixed CORS configuration for web requests
- Fixed database encryption for existing contacts

### 📦 Dependencies Updated
- Added `google_identity_services_web` for web OAuth
- Enhanced `requests` library usage for token verification
- Updated security middleware for dual-token support

---

## Version 1.0 - Initial Release

### Core Features
- Phone number standardization to E.164 format
- Google Contacts API integration
- Multi-region phone number support
- Swipe-based review interface (mobile)
- Batch updates to Google Contacts
- Region analysis and auto-detection

### Mobile Support
- Android & iOS apps via Flutter
- Native Google Sign-In
- Offline contact caching
- Intuitive swipe UI

### Backend
- FastAPI REST API
- SQLite database
- Google People API integration
- Phone number parsing with `phonenumbers` library

---

**For detailed migration guide and upgrade instructions, see `docs/SETUP_GUIDE.md`**
