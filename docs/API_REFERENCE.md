# API Reference

## Base URL

The Flutter app automatically uses the correct base URL based on the platform:
- **Web (Chrome/Browser)**: `http://localhost:8000`
- **Android Emulator**: `http://10.0.2.2:8000`
- **Physical Device**: `http://<your-mac-ip>:8000`

> **Note**: The platform detection is handled automatically in `api_service.dart` using Flutter's `kIsWeb` constant.

## 🔒 Authentication

**All endpoints (except public ones) require authentication**.

### Authentication Header
```
Authorization: Bearer <google_id_token>
```

The Google ID token is obtained from the Flutter `google_sign_in` package and sent with every API request.

### Public Endpoints
The following endpoints do NOT require authentication:
- `GET /` - Root/health check
- `GET /health` - Detailed health check
- `GET /docs` - API documentation
- `GET /auth/status` - Backend OAuth status

### Authentication Errors
- **401 Unauthorized**: Missing or invalid ID token
- **403 Forbidden**: Email not verified
- **429 Too Many Requests**: Rate limit exceeded

---

## CORS Configuration

The backend is configured to accept cross-origin requests from:
- `http://localhost:3000` (Flutter web app)
- `http://127.0.0.1:3000`

Configured via `CORS_ORIGINS` environment variable.

**Allowed Methods**: GET, POST, DELETE  
**Allowed Headers**: Authorization, Content-Type

---

## Authentication Endpoints

### GET `/auth/status`
**Public endpoint** - Check backend OAuth authentication status (for server-to-Google API).

**Response**:
```json
{
  "status": "authenticated|unauthenticated",
  "user": "Display Name",
  "email": "user@example.com"
}
```

### GET `/auth/login`
**Public endpoint** - Triggers backend OAuth flow (opens browser for server authentication).

**Response**:
```json
{
  "status": "success",
  "message": "Authenticated successfully. You can close this window."
}
```

### POST `/auth/exchange_token`
**Public endpoint** - Exchange a Google Access Token (Web) for user information to establish a session.

**Rate Limit**: 60 requests/minute (default)

**Headers**:
None (Public)

**Request Body**:
```json
{
  "access_token": "ya29.a0..."
}
```

**Response**:
```json
{
  "id_token": "ya29.a0...",
  "email": "user@example.com",
  "name": "John Doe"
}
```

---

## Contact Endpoints

All contact endpoints require authentication and automatically filter data by authenticated user.

### GET `/contacts/`
List all contacts for the authenticated user.

**Rate Limit**: 30 requests/minute

**Headers**:
```
Authorization: Bearer <id_token>
```

**Response**:
```json
[
  {
    "resource_name": "people/c123",
    "user_email": "user@example.com",
    "given_name": "John Doe",
    "phone_number": "<encrypted>",
    "raw_json": "<encrypted>",
    "etag": "..."
  }
]
```

> **Note**: `phone_number` and `raw_json` are automatically decrypted by the backend.

### POST `/contacts/sync`
Sync contacts from Google People API for the authenticated user.

**Rate Limit**: 5 requests/minute

**Headers**:
```
Authorization: Bearer <id_token>
```

**Response**:
```json
{
  "status": "success",
  "synced_count": 150,
  "total_from_google": 150
}
```

### GET `/contacts/missing_extension?region=XX`
Get contacts needing phone number standardization.

**Rate Limit**: 20 requests/minute

**Headers**:
```
Authorization: Bearer <id_token>
```

**Parameters**:
- `region` (string): 2-letter ISO country code (e.g., "US", "IN", "GB")

**Response**:
```json
{
  "count": 25,
  "contacts": [
    {
      "resource_name": "people/c123",
      "name": "John Doe",
      "phone": "5551234567",
      "suggested": "+15551234567",
      "updated_at": "2026-01-07T..."
    }
  ]
}
```

**Errors**:
- `400 Bad Request`: Invalid region code format

### GET `/contacts/analyze_regions`
Analyze contacts across multiple regions.

**Rate Limit**: 10 requests/minute

**Headers**:
```
Authorization: Bearer <id_token>
```

**Response**:
```json
{
  "regions": [
    {"region": "US", "count": 45},
    {"region": "IN", "count": 12}
  ]
}
```

---

## Staging Endpoints

### POST `/contacts/stage_fix`
Stage a contact fix for later pushing to Google.

**Rate Limit**: 60 requests/minute

**Headers**:
```
Authorization: Bearer <id_token>
Content-Type: application/json
```

**Request Body**:
```json
{
  "resource_name": "people/c123",
  "contact_name": "John Doe",
  "original_phone": "5551234567",
  "new_phone": "+15551234567",
  "action": "accept",
  "new_name": "Johnny Doe"
}
```

**Field Validation**:
- `resource_name`: Must match `^people/[a-zA-Z0-9]+$`
- `action`: Must be "accept", "reject", or "edit"
- `contact_name`, `original_phone`, `new_phone`: Max 200 characters
- `new_name`: Optional, max 200 characters

**Response**:
```json
{
  "status": "staged",
  "action": "accept",
  "resource_name": "people/c123"
}
```

**Errors**:
- `400 Bad Request`: Validation failed
- `500 Internal Server Error`: Failed to stage

### GET `/contacts/pending_changes`
Get all staged changes and summary for the authenticated user.

**Rate Limit**: 20 requests/minute

**Headers**:
```
Authorization: Bearer <id_token>
```

**Response**:
```json
{
  "summary": {
    "total": 15,
    "accepts": 10,
    "rejects": 3,
    "edits": 2
  },
  "changes": [
    {
      "id": 1,
      "resource_name": "people/c123",
      "user_email": "user@example.com",
      "contact_name": "John Doe",
      "original_phone": "5551234567",
      "new_phone": "+15551234567",
      "action": "accept",
      "created_at": "2026-01-07T...",
      "updated_at": "2026-01-07T..."
    }
  ]
}
```

### DELETE `/contacts/staged/remove?resource_name=people/c123`
Remove a specific staged change.

**Rate Limit**: 30 requests/minute

**Headers**:
```
Authorization: Bearer <id_token>
```

**Parameters**:
- `resource_name` (string, required): Must start with "people/"

**Response**:
```json
{
  "status": "removed",
  "resource_name": "people/c123"
}
```

**Errors**:
- `400 Bad Request`: Invalid resource_name format

### DELETE `/contacts/staged`
Clear all staged changes for the authenticated user.

**Rate Limit**: 10 requests/minute

**Headers**:
```
Authorization: Bearer <id_token>
```

**Response**:
```json
{
  "status": "cleared"
}
```

### POST `/contacts/push_to_google`
Push all staged changes to Google Contacts.

**Rate Limit**: 3 requests/minute (strict limit for critical operation)

**Headers**:
```
Authorization: Bearer <id_token>
```

**Response**:
```json
{
  "status": "completed",
  "pushed": 10,
  "failed": 1,
  "skipped": 3,
  "details": {
    "success": ["John Doe", "Jane Smith"],
    "failed": [
      {"name": "Bob Wilson", "error": "Contact not found"}
    ],
    "skipped": ["Rejected Contact"]
  }
}
```

---

## Rate Limiting

**Default**: 100 requests/minute per user (configurable via `RATE_LIMIT_PER_MINUTE`)

**Per-Endpoint Limits**:
- `/contacts/sync`: 5/min (expensive Google API call)
- `/contacts/push_to_google`: 3/min (critical operation)
- `/contacts/`: 50/min
- `/contacts/missing_extension`: 40/min
- `/contacts/stage_fix`: 100/min (increased for batch operations)
- `/contacts/pending_changes`: 40/min
- `/contacts/staged/remove`: 100/min (increased for batch operations)
- `/contacts/staged`: 10/min
- `/contacts/analyze_regions`: 10/min

**Rate Limit Response** (429):
```json
{
  "error": "Rate limit exceeded"
}
```

---

## Security Features

### Data Encryption
- `phone_number` and `raw_json` fields are encrypted at rest using Fernet (AES-256)
- Automatic encryption on write, decryption on read
- Encryption key stored in `ENCRYPTION_KEY` environment variable

### User Isolation
- All data queries filtered by authenticated user's email
- Users can only access their own contacts and staged changes
- Multi-tenant architecture with complete data separation

### Input Validation
- Strict Pydantic models with regex patterns
- Length limits on all string fields
- Type validation on all inputs
- Custom validators for enums and formats

### Audit Logging
- All authentication events logged
- Rate limit violations logged
- Invalid input attempts logged
- Security events include user email and endpoint

---

## Error Responses

### Standard Error Format
```json
{
  "detail": "Error message",
  "type": "error_type"
}
```

### Common Error Types
- `authentication_required`: 401, missing Authorization header
- `invalid_token_format`: 401, malformed token
- `invalid_token`: 401, token verification failed
- `email_not_verified`: 403, Google email not verified
- `invalid_input`: 400, validation failed

---

## Health Check

### GET `/health`
**Public endpoint** - Detailed health check with security status.

**Response**:
```json
{
  "status": "ok",
  "environment": "development",
  "security": {
    "authentication": "enabled",
    "rate_limiting": "enabled",
    "encryption": "enabled"
  }
}
```

---

## Migration from v0.x

If upgrading from version 0.x (no authentication):

1. **Backend**: Run migration script to add `user_email` and encrypt data
2. **Frontend**: Update all API calls to include `Authorization` header
3. **Testing**: Verify authentication flow end-to-end

See [FRONTEND_AUTH_INTEGRATION.md](FRONTEND_AUTH_INTEGRATION.md) for details.

---

**Last Updated**: 2026-01-07  
**API Version**: 1.0.0 (Security Hardening Release)
