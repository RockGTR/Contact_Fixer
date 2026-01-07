"""
Security Utilities
Handles JWT verification, Google ID token validation, and field-level encryption.
"""
from typing import Optional, Dict, Any
from jose import jwt, JWTError
from google.auth.transport import requests
from google.oauth2 import id_token
from cryptography.fernet import Fernet
from backend.core.config import config
import logging

logger = logging.getLogger(__name__)

# Initialize Fernet encryption with key from config
try:
    fernet = Fernet(config.ENCRYPTION_KEY.encode())
except Exception as e:
    logger.error(f"Failed to initialize encryption: {e}")
    raise ValueError("Invalid ENCRYPTION_KEY in configuration")


class GoogleTokenVerifier:
    """Verifies Google ID tokens and access tokens from client."""
    
    @staticmethod
    def verify_token(token: str) -> Optional[Dict[str, Any]]:
        """
        Verify Google token and return user information.
        Handles both ID tokens (mobile) and access tokens (web).
        
        Args:
            token: Google ID token or access token from client
            
        Returns:
            Dict with user info (email, name, sub) or None if invalid
        """
        # First, try as ID token (mobile clients)
        result = GoogleTokenVerifier._verify_id_token(token)
        if result:
            return result
        
        # If ID token verification failed, try as access token (web clients)
        result = GoogleTokenVerifier._verify_access_token(token)
        if result:
            return result
        
        return None
    
    @staticmethod
    def _verify_id_token(token: str) -> Optional[Dict[str, Any]]:
        """Verify Google ID token (mobile clients)."""
        try:
            # Verify the token with Google's servers
            idinfo = id_token.verify_oauth2_token(
                token, 
                requests.Request()
            )
            
            # Token is valid, extract user info
            return {
                'email': idinfo.get('email'),
                'name': idinfo.get('name'),
                'sub': idinfo.get('sub'),  # Google user ID
                'picture': idinfo.get('picture'),
                'email_verified': idinfo.get('email_verified', False)
            }
        except ValueError as e:
            # Not a valid ID token
            logger.debug(f"Not a valid ID token: {e}")
            return None
        except Exception as e:
            logger.debug(f"ID token verification error: {e}")
            return None
    
    @staticmethod
    def _verify_access_token(token: str) -> Optional[Dict[str, Any]]:
        """Verify Google access token (web clients) using userinfo endpoint."""
        try:
            import requests as http_requests
            
            # Verify access token by calling Google's userinfo endpoint
            userinfo_url = "https://www.googleapis.com/oauth2/v3/userinfo"
            headers = {"Authorization": f"Bearer {token}"}
            
            response = http_requests.get(userinfo_url, headers=headers, timeout=10)
            
            if response.status_code != 200:
                logger.debug(f"Access token verification failed: {response.status_code}")
                return None
            
            user_info = response.json()
            
            # Extract user details
            return {
                'email': user_info.get('email'),
                'name': user_info.get('name'),
                'sub': user_info.get('sub'),
                'picture': user_info.get('picture'),
                'email_verified': user_info.get('email_verified', False)
            }
        except Exception as e:
            logger.debug(f"Access token verification error: {e}")
            return None


class FieldEncryption:
    """Field-level encryption for sensitive data."""
    
    @staticmethod
    def encrypt(data: str) -> str:
        """
        Encrypt a string value.
        
        Args:
            data: Plain text string to encrypt
            
        Returns:
            Encrypted string (base64 encoded)
        """
        if not data:
            return ""
        try:
            encrypted_bytes = fernet.encrypt(data.encode('utf-8'))
            return encrypted_bytes.decode('utf-8')
        except Exception as e:
            logger.error(f"Encryption failed: {e}")
            raise
    
    @staticmethod
    def decrypt(encrypted_data: str) -> str:
        """
        Decrypt an encrypted string.
        
        Args:
            encrypted_data: Encrypted string (base64 encoded)
            
        Returns:
            Decrypted plain text string
        """
        if not encrypted_data:
            return ""
        try:
            decrypted_bytes = fernet.decrypt(encrypted_data.encode('utf-8'))
            return decrypted_bytes.decode('utf-8')
        except Exception as e:
            logger.error(f"Decryption failed: {e}")
            # Return empty string rather than raising (data might be corrupted)
            return ""


def create_access_token(data: Dict[str, Any]) -> str:
    """
    Create a JWT access token (for future use).
    Currently using Google tokens directly.
    
    Args:
        data: Payload to encode in token
        
    Returns:
        JWT token string
    """
    try:
        encoded_jwt = jwt.encode(
            data, 
            config.JWT_SECRET_KEY, 
            algorithm="HS256"
        )
        return encoded_jwt
    except JWTError as e:
        logger.error(f"JWT encoding failed: {e}")
        raise


def verify_access_token(token: str) -> Optional[Dict[str, Any]]:
    """
    Verify a JWT access token (for future use).
    
    Args:
        token: JWT token string
        
    Returns:
        Decoded token payload or None if invalid
    """
    try:
        payload = jwt.decode(
            token, 
            config.JWT_SECRET_KEY, 
            algorithms=["HS256"]
        )
        return payload
    except JWTError as e:
        logger.warning(f"JWT verification failed: {e}")
        return None
