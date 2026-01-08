"""
Rate Limiting Middleware
Prevents abuse by limiting request rates per IP and per user.
"""
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from backend.core.config import config
from backend.core.logging_config import security_logger


def get_user_identifier(request):
    """
    Get identifier for rate limiting (user email if authenticated, otherwise IP).
    """
    # Try to get authenticated user email
    if hasattr(request.state, 'user_email'):
        return request.state.user_email
    # Fallback to IP address
    return get_remote_address(request)


# Create limiter instance
limiter = Limiter(
    key_func=get_user_identifier,
    default_limits=[f"{config.RATE_LIMIT_PER_MINUTE}/minute"]
)


def rate_limit_handler(request, exc: RateLimitExceeded):
    """Custom handler for rate limit exceeded with detailed error message."""
    identifier = get_user_identifier(request)
    security_logger.log_rate_limit(identifier, request.url.path)
    
    # Log detailed rate limit info
    import logging
    logger = logging.getLogger(__name__)
    logger.warning(
        f"Rate limit exceeded for {identifier} on {request.url.path}. "
        f"Limit: {exc.detail if hasattr(exc, 'detail') else 'unknown'}"
    )
    
    # Return more helpful error response
    from fastapi.responses import JSONResponse
    return JSONResponse(
        status_code=429,
        content={
            "error": "Rate limit exceeded",
            "detail": f"Too many requests. Please wait a moment before trying again.",
            "retry_after": 60  # Suggest retry after 60 seconds
        }
    )
