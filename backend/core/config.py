"""
Configuration Management
Loads and validates environment variables for the application.
"""
import os
from typing import List
from dotenv import load_dotenv

# Load .env file
load_dotenv()

class Config:
    """Application configuration loaded from environment variables."""
    
    # Security
    JWT_SECRET_KEY: str = os.getenv("JWT_SECRET_KEY", "")
    ENCRYPTION_KEY: str = os.getenv("ENCRYPTION_KEY", "")
    
    # CORS
    CORS_ORIGINS: List[str] = os.getenv("CORS_ORIGINS", "http://localhost:3000").split(",")
    
    # Rate Limiting
    RATE_LIMIT_PER_MINUTE: int = int(os.getenv("RATE_LIMIT_PER_MINUTE", "100"))
    
    # Environment
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development")
    IS_PRODUCTION: bool = ENVIRONMENT == "production"
    
    # Google OAuth (optional - defaults to file-based)
    GOOGLE_CREDENTIALS_JSON: str = os.getenv("GOOGLE_CREDENTIALS_JSON", "")
    
    @classmethod
    def validate(cls):
        """Validate that required configuration is present."""
        errors = []
        
        if not cls.JWT_SECRET_KEY:
            errors.append("JWT_SECRET_KEY is not set")
        
        if not cls.ENCRYPTION_KEY:
            errors.append("ENCRYPTION_KEY is not set")
            
        if len(cls.JWT_SECRET_KEY) < 32:
            errors.append("JWT_SECRET_KEY must be at least 32 characters")
            
        if errors:
            raise ValueError(f"Configuration errors: {', '.join(errors)}")
    
    @classmethod
    def is_development(cls) -> bool:
        """Check if running in development mode."""
        return cls.ENVIRONMENT == "development"

# Validate configuration on import
Config.validate()

# Export singleton instance
config = Config()
