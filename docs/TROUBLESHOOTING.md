# Troubleshooting Guide

## Google Sign-In Issues

### `[28444] Developer console is not set up correctly`
**Solution**: Downgrade to `google_sign_in: ^6.2.1`

### `ApiException: 10`
**Solutions**:
1. Verify SHA-1 in Google Cloud Console
2. Add yourself as test user if app is in Testing mode
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android | grep "SHA1:"
```

---

## Backend Issues

### `Connection refused, address = localhost`
**Solution**: Use `10.0.2.2` for Android emulator

### Region changes not taking effect
**Solution**: Restart backend server
```bash
pkill -f uvicorn
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
curl -X DELETE "localhost:8000/contacts/staged"
```
