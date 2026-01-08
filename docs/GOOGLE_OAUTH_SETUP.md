# Google OAuth Setup for ID Tokens

## ✅ Setup Complete

Your app is configured with:
- **Web Client ID**: `508004432990-iremf8omgfljq5kj02ifjimg8k96o79a.apps.googleusercontent.com`
- **Android Client**: `508004432990-p63sl6jkdm1nqi0uekkk0ptmv9i8uo3j.apps.googleusercontent.com`
- **Desktop Client**: `508004432990-9ih4l23notjpre38oobruoohd4m1ato6.apps.googleusercontent.com`

## How It Works

### OAuth Clients Explained

Your Google Cloud project has **3 OAuth clients**:

1. **Web Application** (`Contact Fixer Web`)
   - Used as `serverClientId` in Flutter
   - Enables ID token generation
   - Required for backend authentication

2. **Android** (`Contact Fixer App`)
   - Matched by package name + SHA-1 fingerprint
   - Handles the actual sign-in flow on Android
   - Provides user profile info

3. **Desktop** (`Contact Fixer Backend`)
   - Used by Python backend
   - Accesses Google People API
   - Server-to-server authentication

### Authentication Flow

```
User taps "Sign in with Google"
         ↓
Android OAuth client validates (package + SHA-1)
         ↓
User approves and signs in
         ↓
Web OAuth client generates ID token
         ↓
Flutter app receives: profile + email + ID token
         ↓
ID token sent to backend with every API call
         ↓
Backend verifies ID token with Google
         ↓
Request authenticated ✅
```

### Platform-Specific Differences

#### Mobile (Android/iOS)
- **No CORS restrictions** - Direct HTTP calls
- **serverClientId required** for ID tokens
- **SHA-1 fingerprint** must be registered
- **Package name** must match OAuth client
- ID tokens generated automatically

#### Web (Chrome/Browser)
- **CORS restrictions apply** - Must configure CORS_ORIGINS
- **serverClientId NOT supported** - Will cause error
- **Meta tag in index.html** handles OAuth
  ```html
  <meta name="google-signin-client_id" content="WEB_CLIENT_ID.apps.googleusercontent.com">
  ```
- ID tokens work differently (via browser cookie/session)

**Important**: The `auth_provider.dart` uses `kIsWeb` to conditionally set `serverClientId`:
```dart
serverClientId: kIsWeb ? null : 'WEB_CLIENT_ID', // Only for mobile
```

## Current Configuration

### Flutter (`frontend/lib/providers/auth_provider.dart`)

```dart
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
  serverClientId: '508004432990-iremf8omgfljq5kj02ifjimg8k96o79a.apps.googleusercontent.com',
);
```

### Backend (`backend/core/security.py`)

The backend verifies ID tokens using Google's public keys:
```python
async def verify_google_token(id_token: str) -> dict:
    # Verifies token with Google
    # Returns user email if valid
```

## Troubleshooting

### No ID Token Generated

**Symptom**: "ID token is null" in logs

**Causes**:
1. `serverClientId` not configured
2. Wrong client ID (using Desktop instead of Web)
3. Client ID doesn't match Google Cloud Console

**Fix**: Verify Web client ID in Google Cloud Console matches code

### Sign-In Fails (ApiException: 10)

**Symptom**: Error code 10 when signing in

**Causes**:
1. SHA-1 fingerprint not registered
2. Wrong serverClientId
3. Package name mismatch

**Fix**:
```bash
# Get SHA-1 fingerprint
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android | grep "SHA1:"

# Add to Google Cloud Console under Android OAuth client
```

### Backend Rejects Token

**Symptom**: 401 Unauthorized from backend

**Causes**:
1. ID token expired (tokens last ~1 hour)
2. Backend can't reach Google's token verification endpoint
3. Clock skew between devices

**Fix**: Sign out and sign in again to get fresh token

## Production Considerations

### Separate OAuth Clients

For production, create separate OAuth clients:
- Development: `Contact Fixer Dev (Web)`
- Production: `Contact Fixer (Web)`

Update `serverClientId` based on build type:

```dart
final serverClientId = kReleaseMode
    ? 'PRODUCTION_WEB_CLIENT_ID'
    : 'DEV_WEB_CLIENT_ID';
```

### Token Refresh

ID tokens expire after ~1 hour. Handle expiration:
```dart
// AuthProvider already handles this via onAuthenticationExpired callback
```

### Security Best Practices

1. **Never commit client secrets** (only needed for server-side auth)
2. **Use environment-specific OAuth clients**
3. **Monitor failed auth attempts**
4. **Rotate credentials regularly**

## Verification Checklist

- [x] Web OAuth client created
- [x] Web client ID added to Flutter (`auth_provider.dart`)
- [x] Android SHA-1 registered in Google Cloud Console
- [x] Backend verifies ID tokens
- [x] User can sign in successfully
- [x] ID tokens generated and logged
- [x] API calls authenticated

## References

- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- [Google OAuth 2.0](https://developers.google.com/identity/protocols/oauth2)
- [Verify ID Tokens](https://developers.google.com/identity/sign-in/android/backend-auth)

---

**Status**: ✅ Fully configured and working
**Last Updated**: 2026-01-08
