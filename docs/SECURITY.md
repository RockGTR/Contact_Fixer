# Security Best Practices

This document outlines security best practices for the Contact Fixer application.

## 🔒 Security Features

Contact Fixer implements enterprise-grade security:

- **Authentication**: Google ID token verification
- **Data Encryption**: Field-level encryption for sensitive data at rest
- **User Isolation**: Multi-user support with complete data separation
- **Rate Limiting**: Per-user and per-IP request throttling
- **Input Validation**: Strict validation on all API inputs
- **CORS Protection**: Restricted cross-origin requests
- **Security Headers**: Standard headers to prevent common attacks
- **Audit Logging**: Security event logging for compliance

## 🚀 Production Deployment Checklist

Before deploying to production:

### 1. Environment Configuration

- [ ] Generate strong `JWT_SECRET_KEY` (32+ characters)
- [ ] Generate `ENCRYPTION_KEY` using Fernet.generate_key()
- [ ] Set `ENVIRONMENT=production`
- [ ] Configure allowed `CORS_ORIGINS` for your domain
- [ ] Never commit `.env` file to version control

### 2. Database Security

- [ ] Run migration script to encrypt existing data
- [ ] Ensure database file has restrictive permissions (600)
- [ ] Set up regular encrypted backups
- [ ] Consider using a dedicated database server

### 3. HTTPS/TLS

- [ ] Deploy behind HTTPS reverse proxy (nginx, Caddy) OR
- [ ] Configure FastAPI with SSL certificates
- [ ] Force HTTPS redirects
- [ ] Enable HSTS headers (automatic in production)

### 4. Google OAuth Configuration

- [ ] Add production domain to Authorized JavaScript origins
- [ ] Add production domain to Authorized redirect URIs
- [ ] Review OAuth consent screen for production
- [ ] Use separate OAuth client for production

### 5. Monitoring & Logging

- [ ] Set up log aggregation (e.g., ELK stack)
- [ ] Configure security alerting
- [ ] Monitor rate limit violations
- [ ] Track authentication failures

### 6. Access Control

- [ ] Restrict server SSH access
- [ ] Use firewall to limit exposed ports
- [ ] Implement principle of least privilege
- [ ] Rotate credentials regularly

## 🔐 Credential Management

### Backend Secrets

All sensitive configuration is managed through environment variables:

```bash
# Required
JWT_SECRET_KEY=<32+ character random string>
ENCRYPTION_KEY=<Fernet key from cryptography.fernet.Fernet.generate_key()>

# Optional
CORS_ORIGINS=https://yourdomain.com
RATE_LIMIT_PER_MINUTE=60
ENVIRONMENT=production
```

### Generating Secure Keys

```bash
# Generate JWT secret
python3 -c "import secrets; print(secrets.token_urlsafe(32))"

# Generate encryption key
python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

### Google OAuth Credentials

Store Google OAuth credentials securely:
- Keep `credentials.json` in `.gitignore`
- Consider using environment variable `GOOGLE_CREDENTIALS_JSON` for deployment
- Never expose client secret in frontend code

## 🛡️ Security Headers

The following security headers are automatically applied:

| Header | Value | Purpose |
|--------|-------|---------|
| X-Content-Type-Options | nosniff | Prevent MIME sniffing |
| X-Frame-Options | DENY | Prevent clickjacking |
| X-XSS-Protection | 1; mode=block | XSS protection |
| Strict-Transport-Security | max-age=31536000 (prod only) | Force HTTPS |

## 🚨 Incident Response

### Authentication Token Compromised

1. User signs out (invalidates token)
2. User signs in again (new token issued)
3. Monitor logs for suspicious activity

### Database Breach

If the database file is compromised:
- Encrypted fields (`phone_number`, `raw_json`) remain protected
- Attackers cannot decrypt without `ENCRYPTION_KEY`
- Rotate encryption key and re-encrypt data
- Notify affected users

### Rate Limit Bypass Attempts

- Logs will show repeated violations from same IP/user
- Consider temporary IP blocks for severe cases
- Adjust rate limits if legitimate traffic is affected

## 🔍 Audit & Compliance

### Logging

Security events are logged with the following format:
- Authentication success/failure (with user email)
- Rate limit violations (with IP/user identifier)
- Invalid input attempts (with endpoint and error)

Example log entry:
```
2026-01-07 11:30:15 - security - INFO - Auth success - User: user@example.com, Endpoint: /contacts/sync
```

### Data Retention

- Contact data: Stored until user deletes or signs out
- Staged changes: Cleared after pushing to Google
- Logs: Rotate logs regularly (recommend 30-90 days)

### GDPR Compliance

For GDPR compliance, implement:
1. Right to deletion: Clear user's contacts and staged changes on request
2. Data export: Provide API endpoint to export user's data
3. Consent management: Obtain consent for data processing
4. Data minimization: Only store necessary contact fields

## 🧪 Security Testing

### Before Production

Run security tests:

```bash
# Test authentication
curl -X POST http://localhost:8000/contacts/sync
# Expected: 401 Unauthorized

# Test rate limiting
for i in {1..100}; do
  curl -H "Authorization: Bearer <valid_token>" \
       http://localhost:8000/contacts/ &
done
# Expected: Eventually 429 Too Many Requests

# Test input validation
curl -X POST http://localhost:8000/contacts/stage_fix \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"resource_name": "invalid", "action": "malicious"}'
# Expected: 400 Bad Request or 500 with validation error
```

### Automated Security Scanning

Consider using:
- **Dependency scanning**: `pip-audit` for Python backend
- **SAST**: Static analysis tools (Bandit for Python)
- **DAST**: Dynamic testing (OWASP ZAP)
- **Container scanning**: If using Docker (Trivy, Snyk)

## 📞 Security Contacts

- Report security vulnerabilities privately
- Do not disclose exploits publicly before patch
- Apply security updates promptly

## 📚 Additional Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [FastAPI Security Best Practices](https://fastapi.tiangolo.com/tutorial/security/)
- [Google OAuth 2.0 Best Practices](https://developers.google.com/identity/protocols/oauth2/best-practices)

---

**Last Updated**: 2026-01-07  
**Version**: 1.0.0 (Security Hardening Release)
