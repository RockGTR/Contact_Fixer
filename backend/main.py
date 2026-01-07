from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi.errors import RateLimitExceeded
from backend.routers import auth, contacts, token_exchange
from backend.core.config import config
from backend.core.logging_config import setup_logging
from backend.middleware.auth_middleware import AuthenticationMiddleware
from backend.middleware.rate_limit import limiter, rate_limit_handler
import logging

# Setup logging
setup_logging()
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Contact Fixer API",
    description="Secure API for fetching and fixing Google Contacts",
    version="1.0.0"
)

# Add rate limiting
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, rate_limit_handler)

# Configure CORS with strict settings
app.add_middleware(
    CORSMiddleware,
    allow_origins=config.CORS_ORIGINS,  # Restrict to specific origins
    allow_credentials=True,
    allow_methods=["GET", "POST", "DELETE"],  # Only allowed methods
    allow_headers=["Authorization", "Content-Type"],  # Only needed headers
    max_age=3600,  # Cache preflight for 1 hour
)

# Add authentication middleware
app.add_middleware(AuthenticationMiddleware)


# Security headers middleware
@app.middleware("http")
async def add_security_headers(request, call_next):
    """Add security headers to all responses."""
    response = await call_next(request)
    
    # Prevent MIME type sniffing
    response.headers["X-Content-Type-Options"] = "nosniff"
    
    # Prevent clickjacking
    response.headers["X-Frame-Options"] = "DENY"
    
    # XSS protection
    response.headers["X-XSS-Protection"] = "1; mode=block"
    
    # HSTS (only in production with HTTPS)
    if config.IS_PRODUCTION:
        response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    
    return response


# Include routers
app.include_router(auth.router)
app.include_router(token_exchange.router)  # Token exchange for web clients
app.include_router(contacts.router)


@app.get("/")
async def read_root():
    """Health check endpoint."""
    return {
        "message": "Contact Fixer API is running!",
        "version": "1.0.0",
        "environment": config.ENVIRONMENT
    }


@app.get("/health")
async def health_check():
    """Detailed health check."""
    return {
        "status": "ok",
        "environment": config.ENVIRONMENT,
        "security": {
            "authentication": "enabled",
            "rate_limiting": "enabled",
            "encryption": "enabled"
        }
    }


# Startup event
@app.on_event("startup")
async def startup_event():
    """Log startup information."""
    logger.info("=" * 60)
    logger.info("Contact Fixer API Starting")
    logger.info(f"Environment: {config.ENVIRONMENT}")
    logger.info(f"CORS Origins: {', '.join(config.CORS_ORIGINS)}")
    logger.info(f"Rate Limit: {config.RATE_LIMIT_PER_MINUTE}/minute")
    logger.info("Security Features: Authentication, Rate Limiting, Encryption")
    logger.info("=" * 60)

