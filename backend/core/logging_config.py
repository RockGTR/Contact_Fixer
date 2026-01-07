"""
Structured Logging Configuration
Provides secure logging with appropriate log levels and formats.
"""
import logging
import sys
from backend.core.config import config

# Define log format
LOG_FORMAT = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"

def setup_logging():
    """Configure application logging."""
    # Set log level based on environment
    log_level = logging.DEBUG if config.is_development() else logging.INFO
    
    # Configure root logger
    logging.basicConfig(
        level=log_level,
        format=LOG_FORMAT,
        handlers=[
            logging.StreamHandler(sys.stdout)
        ]
    )
    
    # Set specific log levels for third-party libraries
    logging.getLogger("google").setLevel(logging.WARNING)
    logging.getLogger("googleapiclient").setLevel(logging.WARNING)
    logging.getLogger("urllib3").setLevel(logging.WARNING)
    
    logger = logging.getLogger(__name__)
    logger.info(f"Logging configured - Level: {logging.getLevelName(log_level)}, Environment: {config.ENVIRONMENT}")


# Security event logging helper
class SecurityLogger:
    """Logs security-related events."""
    
    def __init__(self):
        self.logger = logging.getLogger("security")
    
    def log_auth_success(self, email: str, endpoint: str):
        """Log successful authentication."""
        self.logger.info(f"Auth success - User: {email}, Endpoint: {endpoint}")
    
    def log_auth_failure(self, reason: str, endpoint: str):
        """Log authentication failure."""
        self.logger.warning(f"Auth failure - Reason: {reason}, Endpoint: {endpoint}")
    
    def log_rate_limit(self, identifier: str, endpoint: str):
        """Log rate limit violation."""
        self.logger.warning(f"Rate limit exceeded - Identifier: {identifier}, Endpoint: {endpoint}")
    
    def log_invalid_input(self, endpoint: str, error: str):
        """Log invalid input attempt."""
        self.logger.warning(f"Invalid input - Endpoint: {endpoint}, Error: {error}")
    
    def log_security_event(self, event_type: str, details: str):
        """Log general security event."""
        self.logger.info(f"Security event - Type: {event_type}, Details: {details}")


# Initialize security logger
security_logger = SecurityLogger()
