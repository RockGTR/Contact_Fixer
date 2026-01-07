"""
Token exchange endpoint for web clients.
Web Google Sign-In provides access_token but not ID tokens.
This endpoint exchanges the access_token for an ID token.
"""
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from google.auth.transport import requests
from google.oauth2 import id_token as google_id_token
import requests as http_requests
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/auth", tags=["authentication"])


class TokenExchangeRequest(BaseModel):
    access_token: str
    

class TokenExchangeResponse(BaseModel):
    id_token: str
    email: str
    name: str


@router.post("/exchange_token", response_model=TokenExchangeResponse)
async def exchange_token(request: TokenExchangeRequest):
    """
    Exchange a web access_token for user information and generate ID token.
    
    Web clients get access_token from Google Sign-In but not ID tokens.
    This endpoint:
    1. Verifies the access_token with Google
    2. Gets user info (email, name)
    3. Returns the info (backend will create session token for API auth)
    
    Note: For web, we'll use the access_token itself as the "ID token"
    since we can verify it with Google's userinfo endpoint.
    """
    logger.info("Token exchange request received")
    
    try:
        # Verify access token by calling Google's userinfo endpoint
        userinfo_url = "https://www.googleapis.com/oauth2/v3/userinfo"
        headers = {"Authorization": f"Bearer {request.access_token}"}
        
        logger.debug(f"Verifying access_token with Google userinfo endpoint")
        response = http_requests.get(userinfo_url, headers=headers, timeout=10)
        
        if response.status_code != 200:
            logger.warning(f"Token exchange failed: {response.status_code}")
            logger.debug(f"Response body: {response.text[:200]}")
            raise HTTPException(
                status_code=401,
                detail="Invalid access token"
            )
        
        user_info = response.json()
        
        # Extract user details
        email = user_info.get("email")
        name = user_info.get("name")
        email_verified = user_info.get("email_verified", False)
        
        if not email or not email_verified:
            logger.warning(f"Token exchange rejected - Email not verified: {email}")
            raise HTTPException(
                status_code=403,
                detail="Email not verified"
            )
        
        logger.info(f"Token exchange success - User: {email}")
        logger.debug(f"User details: name={name}, verified={email_verified}")
        
        # Return the access token as the ID token for web clients
        # This works because our auth middleware can verify it the same way
        return TokenExchangeResponse(
            id_token=request.access_token,  # Use access_token as ID token for web
            email=email,
            name=name or email
        )
        
    except HTTPException:
        raise
    except http_requests.exceptions.Timeout:
        logger.error("Token exchange timeout - Google API not responding")
        raise HTTPException(
            status_code=504,
            detail="Google API timeout"
        )
    except http_requests.exceptions.RequestException as e:
        logger.error(f"Token exchange network error: {e}")
        raise HTTPException(
            status_code=503,
            detail="Network error contacting Google"
        )
    except Exception as e:
        logger.error(f"Token exchange unexpected error: {type(e).__name__}: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail="Token exchange failed"
        )
