"""
Authentication Middleware
Verifies Google ID tokens and injects user info into request state.
"""
from fastapi import Request, HTTPException, status
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware
from backend.core.security import GoogleTokenVerifier
from backend.core.logging_config import security_logger
import logging

logger = logging.getLogger(__name__)


class AuthenticationMiddleware(BaseHTTPMiddleware):
    """Middleware to verify Google ID tokens from Authorization header."""
    
    # Public endpoints that don't require authentication
    PUBLIC_ENDPOINTS = {
        "/",
        "/health",
        "/docs",
        "/redoc",
        "/openapi.json",
        "/auth/login",
        "/auth/callback",
        "/auth/exchange_token",  # Allow token exchange without auth
    }
    
    async def dispatch(self, request: Request, call_next):
        """Process request and verify authentication."""
        # Skip authentication for public paths
        if request.url.path in self.PUBLIC_ENDPOINTS:
            return await call_next(request)
        
        # Skip authentication for OPTIONS requests (CORS preflight)
        if request.method == "OPTIONS":
            return await call_next(request)
        
        # Extract Authorization header
        auth_header = request.headers.get("Authorization")
        
        if not auth_header:
            security_logger.log_auth_failure("Missing Authorization header", request.url.path)
            return JSONResponse(
                status_code=status.HTTP_401_UNAUTHORIZED,
                content={
                    "detail": "Missing Authorization header",
                    "type": "authentication_required"
                }
            )
        
        # Parse Bearer token
        try:
            scheme, token = auth_header.split()
            if scheme.lower() != "bearer":
                raise ValueError("Invalid authentication scheme")
        except ValueError:
            security_logger.log_auth_failure("Invalid Authorization header format", request.url.path)
            return JSONResponse(
                status_code=status.HTTP_401_UNAUTHORIZED,
                content={
                    "detail": "Invalid Authorization header format. Use: Bearer <token>",
                    "type": "invalid_token_format"
                }
            )
        
        # Verify Google ID token
        user_info = GoogleTokenVerifier.verify_token(token)
        
        if not user_info:
            security_logger.log_auth_failure("Invalid or expired token", request.url.path)
            return JSONResponse(
                status_code=status.HTTP_401_UNAUTHORIZED,
                content={
                    "detail": "Invalid or expired token",
                    "type": "invalid_token"
                }
            )
        
        # Verify email is present and verified
        if not user_info.get('email') or not user_info.get('email_verified'):
            security_logger.log_auth_failure("Email not verified", request.url.path)
            return JSONResponse(
                status_code=status.HTTP_403_FORBIDDEN,
                content={
                    "detail": "Email address must be verified",
                    "type": "email_not_verified"
                }
            )
        
        # Inject user info into request state
        request.state.user = user_info
        request.state.user_email = user_info['email']
        
        # Log successful authentication
        security_logger.log_auth_success(user_info['email'], request.url.path)
        
        # Continue processing request
        response = await call_next(request)
        return response


def get_current_user(request: Request) -> dict:
    """
    Dependency to get current authenticated user from request state.
    Use in route parameters: user = Depends(get_current_user)
    """
    if not hasattr(request.state, 'user'):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated"
        )
    return request.state.user


def get_current_user_email(request: Request) -> str:
    """
    Dependency to get current user's email from request state.
    """
    user = get_current_user(request)
    return user['email']
