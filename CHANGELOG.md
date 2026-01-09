# Contact Fixer - Change Log

## Version 1.2.6 - Google API Throttling & Progress UI (2026-01-08)

### 🚀 New Features

**Real-time Sync Progress Dialog:**
- Neumorphic progress dialog during "Sync to Google" operations
- Live progress bar showing X/Y contacts synced
- Current contact name display
- Estimated time remaining
- Cancel button with confirmation

### ⚡ Performance & Reliability

**Google API Quota Protection:**
- **Throttling**: Push operations limited to 60 contacts/minute (1 second delay between each)
- **Optimistic ETag Updates**: Uses stored ETag first, only fetches fresh on 412 conflict (reduces API calls by ~50%)
- **Exponential Backoff**: On 429 errors, waits 60s → 120s → 240s before retry (max 3 retries)

**Backend:**
- New SSE streaming endpoint `/contacts/push_to_google/stream` for real-time progress
- Custom `GoogleRateLimitError` exception for proper 429 handling
- Async throttling with `asyncio.sleep()` for non-blocking delays

**Frontend:**
- New `PushProgressDialog` widget with neumorphic design
- SSE stream consumption for live updates
- Graceful handling of backoff events

**Background Sync (Android):**
- Sync continues when app is minimized or closed
- Progress notification: "Syncing 5/15 contacts..."
- Completion notification with summary
- Uses Android Foreground Service for reliable execution
- Packages: `flutter_foreground_task`, `flutter_local_notifications`

**Live Pending Changes Updates:**
- Neumorphic `SyncProgressBanner` with animated gradient progress bar
- Inset icon well with accent glow effects
- Synced contacts dynamically removed from list in real-time
- `SyncStateProvider` for global sync state management
- Rate limit status with amber color during backoff waits


### 🧹 Code Quality - Modular Refactoring

**Frontend (all files now <300 lines):**
- Extracted `push_progress_event.dart` - SSE event model
- Extracted `neumorphic_progress_bar.dart` - Reusable progress bar component
- Extracted `push_status_widgets.dart` - Status and timer components
- Extracted `push_completion_summary.dart` - Completion stats display
- Refactored `push_progress_dialog.dart`: 555→280 lines

**Backend (all files now <300 lines):**
- New `push_service.py` - Push logic with throttling and backoff
- Refactored `contacts.py`: 382→241 lines (router now thin)

### 📝 Documentation
- Updated TROUBLESHOOTING.md with Google API quota vs app rate limit explanation
- Added quota limits reference table
- Documented new streaming endpoint in API_REFERENCE.md


---


## Version 1.2.5 - Performance Optimizations (2026-01-08)

### ⚡ Performance Improvements

**Backend:**
- **N+1 Query Fix**: Batch fetch staged contacts (501 → 2 queries for 500 contacts)
- **Token Caching**: TTLCache (5 min) for access token verification (saves 100-300ms/request)
- **Connection Pooling**: Thread-local SQLite connections (saves ~5-10ms/query)

**Frontend:**
- **RateLimitTracker**: Event-driven timers, Queue for O(1) removal
- **Filter/Sort Caching**: Results cached until data/filter/sort changes
- **Pre-parsed Dates**: O(n) on load instead of O(n log n) per sort
- **Provider Optimization**: Single lookup before loops

### 🔧 Bug Fixes
- Fixed backend startup command (must run from project root with PYTHONPATH)
- Fixed connection pooling conflict with conn.close() calls

### 📝 Documentation
- Updated backend startup instructions
- Added performance troubleshooting section

---

## Version 1.2.4 - Rate Limit Adjustment (2026-01-07)

### 🔧 Changes
- **Reduced Rate Limits** (optimized for stability):
  - Default: 100 → **60 edits/minute**
  - `stage_fix`: 100 → **60/min**
  - `list_contacts`: 50 → **30/min**
  - `missing_extension`: 40 → **20/min**
  - `pending_changes`: 40 → **20/min**
  - `remove_staged`: 100 → **30/min**

### 🎨 UI/UX
- Visual indicator now triggers at 45/60 edits (75% threshold)
- Faster countdown refresh for better UX at lower limits
- Error notifications dismiss after 2 seconds

---

## Version 1.2.3 - Rate Limit Enhancements (2026-01-07)

### ✨ New Features
- **Visual Rate Limit Indicator**: Real-time animated progress bar showing API usage
  - Only appears after 75% usage for cleaner UI
  - Color-coded zones: 🟡 Amber (75-80%), 🟠 Orange (80-99%), 🔴 Red (100%)
  - Shows both percentage and remaining edit count
  - Live countdown to next available edit: "Next edit in 12s"
  - Dynamic updates every 500ms for smooth countdown animation

### 🔧 Improvements
- **Increased Rate Limits**:
  - Default: 60 → **100 edits/minute**
  - `stage_fix`: 60 → **100/min** (batch operations)
  - `list_contacts`: 30 → **50/min**
  - `missing_extension`: 20 → **40/min**
  - `pending_changes`: 20 → **40/min**
  - `remove_staged`: 30 → **100/min**
  
- **Hard Limit Enforcement**: Prevents exceeding 100 edits (no more 105% errors)
- **Rolling Window Visualization**: 
  - Shows "3 edits free in 8s" when requests about to expire
  - Count visibly decreases as 60-second window rolls
  - Real-time feedback on quota refresh
  
- **Better Error Messages**:
  - "At limit! (100/100)" instead of generic errors
  - "🔒 At capacity - requests will auto-resume as edits free up"
  - Clear explanation of rolling window behavior

### 🎨 UI/UX
- Compact badge in app bar when approaching limit
- Gradient progress bar with pulse effect when near/at limit
- Smooth animations (300-500ms transitions)
- Clock icon for countdown timer
- Changed terminology: "slots" → "edits" for clarity

---

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
