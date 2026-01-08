# Contact Fixer - Change Log

## Version 1.2.2 - Bug Fixes & Rate Limiting (2026-01-07)

### 🐛 Bug Fixes
- **Missing Stub File**: Added `web_id_token_provider_stub.dart` for mobile builds
- **Accept All Disabled**: Removed Accept All button to prevent rate limiting issues

### 📚 Documentation Updates
- **Frontend Auth Guide**: Completely rewrote with rate limiting best practices
- **Rate Limit Safety**: Documented safe vs unsafe operations
- **Bulk Operations**: Explained which endpoints use single API calls vs loops

### 🛡️ Rate Limiting
- Accept All feature was making 100+ individual API calls, exceeding 60/minute limit
- Feature disabled and marked as premium for future batch API implementation
- Delete All is safe - uses single bulk endpoint with 10/minute limit

---

## Version 1.2.1 - Production Deployment Prep (2026-01-07)

### 🧹 Code Quality
- **Code Cleanup**: Removed unused imports, fixed style warnings
- **Error Handling**: Added mounted checks to prevent async context issues
- **Dart Style**: Fixed curly braces in flow control statements
- **Analysis**: Reduced Flutter analyze issues from 66 to 60

### 📚 Production Documentation
- **Deployment Guide**: Comprehensive production deployment documentation
- **Configuration Templates**: Nginx, Caddy, and systemd service examples
- **Automation Scripts**: Database backup and security key generation scripts
- **Production .env**: Complete production environment template

### 🔧 DevOps Tools
- **Backup Script**: Automated database backup with compression and retention
- **Key Generation**: Secure production key generation utility
- **Service Management**: Systemd service file with auto-restart and security hardening
- **Reverse Proxy**: Production-ready Nginx and Caddy configurations

---

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
