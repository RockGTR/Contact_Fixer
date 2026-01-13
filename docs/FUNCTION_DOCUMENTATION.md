# Function Documentation

## Overview
This document provides detailed information about the backend Python functions.

---

## Authentication Service (`auth_service.py`)

### `get_authenticated_service()`
Handles OAuth 2.0 handshake with Google.

**Process**:
1. Checks for existing `token.json`
2. If valid token exists, uses it
3. If expired, refreshes using refresh token
4. If no token, initiates browser OAuth flow
5. Saves new tokens to `token.json`

**Returns**: Authenticated Google People API service object

---

## Contact Service (`contact_service.py`)

### `sync_contacts_from_google()`
Downloads contacts from Google and saves to local database.

**Returns**: `{"status": "success", "synced_count": int, "total_from_google": int}`

---

### `detect_country_code(phone: str) -> str`
Attempts to intelligently detect the country code for a phone number.

> **Note**: This function is kept for reference but is NOT used by default. 
> The user's selected default region is used instead, as automatic detection 
> is inherently unreliable for 10-digit numbers that are valid in multiple countries.

**Detection Strategy**:
1. If number starts with `+`, extracts region
2. Tries parsing with multiple common regions
3. Uses number length and pattern heuristics
4. Defaults to US for ambiguous cases

**Returns**: Region code string (e.g., "US", "IN", "GB")

---

### `parse_and_validate(phone: str, default_region: str)`
Parses a phone number and returns E.164 format if valid.

**Arguments**:
- `phone`: Phone number string to parse
- `default_region`: ISO region code (e.g., "US", "IN") for ambiguous numbers

**Returns**: E.164 formatted string or None if invalid

---

### `fix_phone_numbers(default_country_code: str = None)`
Analyzes all contacts and returns formatting suggestions.

**Returns**: 
```json
{
  "status": "analyzed",
  "needs_fixing_count": 10,
  "preview": [{"name": "...", "old": "...", "new": "..."}]
}
```

---

### `get_contacts_missing_extension(default_region: str = "US")`
Retrieves contacts with non-E.164 formatted numbers.

**Arguments**:
- `default_region`: User-selected ISO country code for parsing ambiguous numbers

**Returns**: List of contacts with suggested fixes:
```json
[{
  "resource_name": "people/c123",
  "name": "John Doe",
  "phone": "9794228264",
  "suggested": "+19794228264"
}]
```

---

### `create_dummy_contact(name: str, phone: str)`
Creates a new contact in Google Contacts.

**Returns**: `{"status": "created", "resourceName": "...", "name": "...", "phone": "..."}`

---

### `update_contact_phone(resource_name: str, etag: str, new_phone: str)`
Updates an existing contact's phone number.

**Process**:
1. Fetches latest etag from Google (avoids stale data errors)
2. Updates phone number
3. Saves updated contact to local DB

**Returns**: Updated contact object

---

## Database Service (`db_service.py`)

### `save_contacts(contacts: list)`
Saves contacts to SQLite database.

### `get_all_contacts()`
Retrieves all contacts from local database.

**Returns**: List of contact dictionaries with `resource_name`, `given_name`, `phone_number`

---

**Last Updated**: 2026-01-13  
**Version**: 1.2.4
