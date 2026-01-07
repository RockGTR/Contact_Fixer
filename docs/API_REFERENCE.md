# API Reference

## Base URL
- **Android Emulator**: `http://10.0.2.2:8000`
- **Physical Device**: `http://<your-mac-ip>:8000`
- **Local Development**: `http://localhost:8000`

---

## Authentication Endpoints

### GET `/auth/status`
Check backend authentication status.

### GET `/auth/login`
Triggers OAuth flow.

---

## Contact Endpoints

### GET `/contacts/`
List all contacts in local database.

### POST `/contacts/sync`
Sync contacts from Google.

### GET `/contacts/missing_extension?region=XX`
Get contacts needing phone number standardization (excludes already staged).

| Parameter | Type   | Default | Description |
|-----------|--------|---------|-------------|
| `region`  | string | `"US"`  | ISO country code |

**Response Example**:
```json
[
  {
    "resource_name": "people/123",
    "name": "Jane Doe",
    "phone": "555-0100",
    "suggested": "+15550100",
    "updated_at": "2023-10-27T10:00:00Z"
  }
]
```

### GET `/contacts/analyze_regions`
Analyzes contacts across regions, returns top 5 by count.

---

## Staging Endpoints (New)

### POST `/contacts/stage_fix`
Stage a contact fix for later pushing to Google.

**Request Body**:
```json
{
  "resource_name": "people/c123",
  "contact_name": "John Doe",
  "original_phone": "9794228264",
  "new_phone": "+919794228264",
  "action": "accept",  // accept, reject, or edit
  "new_name": "John Updated" // optional (for edit action)
}
```

### GET `/contacts/pending_changes`
Get all staged changes with summary.

**Response**:
```json
{
  "summary": {"total": 10, "accepts": 7, "rejects": 2, "edits": 1},
  "changes": [...]
}
```

### DELETE `/contacts/staged/remove?resource_name=...`
Remove a specific staged change.

**Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| `resource_name` | string | The full resource name (e.g., `people/c123`) |

### DELETE `/contacts/staged`
Clear *all* staged changes from the database.

### POST `/contacts/push_to_google`
Apply all accepted/edited changes to Google Contacts.

**Response**:
```json
{
  "status": "completed",
  "pushed": 8,
  "failed": 0,
  "skipped": 2,
  "details": {...}
}
```

---

## Health Check

### GET `/health`
Check if the API is running.

**Response**:
```json
{"status": "ok"}
```
