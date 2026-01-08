# Troubleshooting Guide

## 🔒 Security & Authentication Issues

### `ID token is null` Error
**Symptoms**: "ID token is null, user may need to re-authenticate" when trying to sync or make API calls

**Root Cause**: GoogleSignIn not configured with `serverClientId`, so no ID tokens are generated

**Solution**: Add Web OAuth Client ID to GoogleSignIn configuration

In `frontend/lib/providers/auth_provider.dart`:
```dart
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
  serverClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
);
```

**How to get Web Client ID:**
1. Go to [Google Cloud Console → Credentials](https://console.cloud.google.com/apis/credentials)
2. Find your **Web application** OAuth 2.0 client
3. Copy the Client ID
4. If you don't have one, click "+ CREATE CREDENTIALS" → "OAuth client ID" → "Web application"

**Test after fix:**
1. Hot restart app (`R`)
2. Sign out and sign in again
3. ID token should now be generated

### `ApiException: 10` (Developer Error)
**Symptoms**: Sign-in fails after adding `serverClientId`

**Cause**: Wrong client ID type used (e.g., Desktop instead of Web)

**Solution**: Ensure you're using the **Web application** client ID, not Desktop or Android

### `401 Unauthorized` Error
**Symptoms**: API requests fail with "Authentication expired" or "Not authenticated"

**Solutions**:
1. **Sign out and sign in again** - Token may have expired
2. **Check Google Sign-In** - Ensure you're signed into the Flutter app
3. **Verify ID Token** - Check browser console (Web) or logs (Mobile) for token errors
4. **Backend Running** - Ensure backend server is running on port 8000

**Testing**:
```bash
# Frontend should send Authorization header
curl -H "Authorization: Bearer <your_google_id_token>" http://localhost:8000/contacts/
```

### `403 Forbidden - Email not verified`
**Cause**: Your Google account email is not verified

**Solution**: Verify your email with Google, then sign in again

### Authentication Token Missing
**Symptoms**: All API calls fail immediately with 401

**Causes & Solutions**:
1. **Frontend not passing token** - Check that `api_service.dart` includes `Authorization` header
2. **AuthProvider not getting token** - Verify `getIdToken()` returns a value
3. **Google Sign-In failed** - Check Sign-In screen for errors

**Debug Steps**:
```dart
// In Flutter app, check token
final token = await Provider.of<AuthProvider>(context, listen: false).getIdToken();
print('ID Token: ${token?.substring(0, 20)}...'); // Should print token prefix
```

### `429 Too Many Requests` (Rate Limit)
**Cause**: Exceeded rate limit (default: 60 edits/minute). A visual indicator appears at 75% usage to warn you proactively.

**Solutions**:
1. **Wait 1 minute** - Limits reset every minute
2. **Reduce request frequency** - Add delays between operations
3. **Increase limit** - Edit `RATE_LIMIT_PER_MINUTE` in `.env` (development only)
4. **Check for loops** - Ensure no infinite request loops in your code

**Per-Endpoint Limits**:
- Sync: 5/min
- Push: 3/min  
- Stage: 60/min
- List: 30/min

---

## Google Sign-In Issues

### Current Configuration (v1.0+)
**Authentication Method**: GoogleSign-In with ID tokens
- Frontend: Native Google Sign-In for user identity
- Backend: ID token verification for API access
- Works with apps in Testing mode

### `Can't continue with google.com - Something went wrong` (Web)
**Solution**: This was caused by FedCM compatibility issues. We've disabled FedCM:
```html
<!-- FedCM disabled temporarily in index.html -->
<!-- <meta name="google-identity-fedcm-enabled" content="true"> -->
```
**To re-enable** (after publishing app):
1. Uncomment the FedCM meta tag
2. Run `flutter clean`
3. Rebuild: `flutter run -d chrome --web-port=3000`

### `[28444] Developer console is not set up correctly`
**Solution**: Downgrade to `google_sign_in: ^6.2.1`

### `ApiException: 10` (Mobile)
**Solutions**:
1. Verify SHA-1 in Google Cloud Console
2. Add yourself as test user if app is in Testing mode
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android | grep "SHA1:"
```

---

## Backend Issues

### `Connection refused` or `Failed to fetch`

**Platform-Specific Solutions**:
- **Web (Chrome)**: The app should use `http://localhost:8000` automatically. If you see connection errors, verify the backend is running.
- **Android Emulator**: The app automatically uses `http://10.0.2.2:8000` (emulator's special IP for host machine).
- **Physical Device**: You need to update `api_service.dart` to use your computer's local IP address (e.g., `http://192.168.1.100:8000`).

**Check Backend Status**:
```bash
curl http://localhost:8000/health
# Should return: {"status":"ok","environment":"development","security":{...}}
```

### CORS Errors (Web Only)

**Important**: CORS only applies to **web applications**. Mobile apps (Android/iOS) don't use CORS.

#### Understanding CORS

When you run the Flutter app on **Chrome** (web), the browser enforces CORS (Cross-Origin Resource Sharing) because:
- Frontend runs on: `http://localhost:3000`
- Backend runs on: `http://localhost:8000`
- Different ports = different origins = CORS check required

**Mobile apps bypass CORS** because they make direct HTTP requests, not browser requests.

#### Symptoms

Browser console shows errors like:
```
Access to XMLHttpRequest at 'http://localhost:8000/contacts/' from origin 
'http://localhost:3000' has been blocked by CORS policy: No 
'Access-Control-Allow-Origin' header is present on the requested resource.
```

#### Solution

1. **Check .env file** has correct CORS_ORIGINS:
   ```bash
   CORS_ORIGINS=http://localhost:3000,http://127.0.0.1:3000
   ```

2. **Verify backend is running** with CORS middleware:
   ```bash
   curl http://localhost:8000/health
   ```

3. **Restart backend** if you changed .env:
   ```bash
   pkill -f uvicorn
   uvicorn backend.main:app --reload --host 0.0.0.0
   ```

4. **Hard refresh browser**: Cmd+Shift+R (Mac) or Ctrl+Shift+R (Windows)

#### Common CORS Issues

**Issue**: CORS error even though .env is correct

**Causes**:
- Backend not restarted after .env change
- Browser cached old CORS headers
- Wrong port (should be 3000 for web, 8000 for backend)

**Fix**:
```bash
# Stop backend
pkill -f uvicorn

# Restart with env variables loaded
cd /Users/rockgtr/Desktop/Personal/Contact_Fixer
source .env
uvicorn backend.main:app --reload --host 0.0.0.0
```

#### Production CORS Setup

For production deployment, update CORS_ORIGINS:
```bash
# .env (production)
CORS_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
```

**Security Note**: Never use `*` (allow all origins) in production - always specify exact origins.

### `Configuration errors: JWT_SECRET_KEY is not set`
**Cause**: Missing or invalid `.env` file

**Solution**:
1. Copy `.env.example` to `.env`
2. Generate secrets:
```bash
python3 -c "import secrets; print('JWT_SECRET_KEY=' + secrets.token_urlsafe(32))"
python3 -c "from cryptography.fernet import Fernet; print('ENCRYPTION_KEY=' + Fernet.generate_key().decode())"
```
3. Add to `.env` file
4. Restart backend

### Database Errors

#### `Invalid ENCRYPTION_KEY in configuration`
**Cause**: Malformed encryption key in `.env`

**Solution**:
```bash
# Generate new key
python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
# Add to .env as ENCRYPTION_KEY=<generated-key>
```

#### `cryptography.fernet.InvalidToken`
**Cause**: Encryption key changed after data was encrypted

**Solutions**:
1. **If testing**: Delete `backend/contacts.db` and resync
2. **If production**: Restore old `ENCRYPTION_KEY` from backup
3. **Migration**: Run migration script with correct keys

#### Database locked
**Cause**: Multiple processes accessing SQLite

**Solution**:
```bash
# Stop all backend processes
pkill -f uvicorn
# Restart
uvicorn backend.main:app --reload --host 0.0.0.0
```

---

## Phone Number Detection

### Why some numbers always suggest +91 even with US selected?
The `phonenumbers` library validates against real country formats:
- `9953285721` → Only valid as Indian (995 is not a US area code)
- `9794228264` → Valid as both (979 = Texas)

Region selector only affects **ambiguous numbers** valid in multiple countries.

---

## Development Tips

### Hot Restart Required
When adding new Providers, use `R` not `r`

### Clear Staged Changes
```bash
# Must include Authorization header now
curl -X DELETE "http://localhost:8000/contacts/staged" \
  -H "Authorization: Bearer <your_id_token>"
```

### Test Authentication Flow
```bash
# Should fail (401)
curl http://localhost:8000/contacts/

# Should succeed
curl http://localhost:8000/contacts/ \
  -H "Authorization: Bearer <valid_google_id_token>"
```

### Debug Mode Logging
The backend logs security events. Check terminal for:
- `Auth success - User: user@example.com`
- `Auth failure - Reason: Missing Authorization header`
- `Rate limit exceeded - Identifier: user@example.com`

---

## Platform-Specific Issues

### Region Suggestion Not Showing (Web)
**Cause**: Platform.localeName doesn't work on web
**Solution**: Already fixed in `settings_provider.dart` with platform-aware locale detection using `kIsWeb`

### API Connection Issues
**Platform-aware URLs** (automatically configured in `api_service.dart`):
- **Web**: `http://localhost:8000`
- **Android Emulator**: `http://10.0.2.2:8000`
- **Physical Device**: Must manually set your computer's IP address

---

## Migration Issues (v0.x → v1.0)

### Frontend compilation errors after upgrade
**Symptom**: "1 positional argument expected by 'syncContacts', but 0 found"

**Cause**: API methods now require `idToken` parameter

**Solution**: See [FRONTEND_AUTH_INTEGRATION.md](FRONTEND_AUTH_INTEGRATION.md) for complete migration guide

### Existing database not working
**Symptom**: Contacts not loading after upgrade

**Solution**: Run migration script:
```bash
python3 backend/migrations/migrate_to_secure.py
```

This will:
- Back up existing database
- Add `user_email` columns
- Encrypt sensitive fields
- Assign data to default user

---

## Production Issues

### HTTPS Required
**Symptom**: "Not Secure" warning or HSTS errors

**Solution**: Deploy behind HTTPS reverse proxy (nginx, Caddy)

### Environment variable not loaded  
**Symptom**: Config errors in production

**Solution**: Ensure `.env` file is present and readable:
```bash
ls -la .env
chmod 600 .env  # Secure permissions
source .env  # Test loading
```

### Multi-user data leakage (testing)
**Symptom**: User A sees User B's contacts

**Cause**: Authentication middleware not working

**Debug**:
1. Check logs for "Auth success" messages
2. Verify `user_email` in database queries
3. Test with two different Google accounts

---

## Getting Help

1. **Check logs**: Backend terminal and browser console
2. **Test health endpoint**: `curl http://localhost:8000/health`
3. **Verify .env**: Ensure all variables are set
4. **Security logs**: Look for authentication/rate limit events
5. **Migration needed?**: If upgrading from v0.x

**Common Log Messages**:
- ✅ `Auth success - User: user@example.com, Endpoint: /contacts/sync`
- ❌ `Auth failure - Reason: Missing Authorization header`
- ⚠️ `Rate limit exceeded - Identifier: 192.168.1.100`

---

**Last Updated**: 2026-01-07  
**Version**: 1.0.0 (Security Hardening Release)
