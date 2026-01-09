from fastapi import APIRouter, Request, HTTPException, status
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field, validator
from typing import Optional
from backend.services import contact_service, db_service
from backend.middleware.auth_middleware import get_current_user_email
from backend.core.logging_config import security_logger
import logging


logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/contacts",
    tags=["contacts"]
)

# ============= REQUEST MODELS WITH VALIDATION =============

class StageFixRequest(BaseModel):
    resource_name: str = Field(..., min_length=1, max_length=200, pattern=r'^people/[a-zA-Z0-9]+$')
    contact_name: str = Field(..., min_length=1, max_length=200)
    original_phone: str = Field(..., min_length=1, max_length=50)
    new_phone: str = Field(..., min_length=1, max_length=50)
    action: str = Field(..., pattern=r'^(accept|reject|edit)$')
    new_name: Optional[str] = Field(None, max_length=200)
    
    @validator('action')
    def validate_action(cls, v):
        """Ensure action is valid."""
        if v not in ['accept', 'reject', 'edit']:
            raise ValueError('Action must be accept, reject, or edit')
        return v

# ============= ENDPOINTS WITH AUTHENTICATION =============

@router.get("/")
async def list_contacts(request: Request):
    """Get all contacts for the authenticated user."""
    user_email = get_current_user_email(request)
    logger.info(f"Listing contacts for user: {user_email}")
    return db_service.get_all_contacts(user_email)

@router.post("/sync")
async def sync_contacts(request: Request):
    """Trigger a fetch from Google for the authenticated user."""
    user_email = get_current_user_email(request)
    logger.info(f"Syncing contacts from Google for user: {user_email}")
    try:
        result = contact_service.sync_contacts_from_google(user_email)
        logger.info(f"Successfully synced {result['synced_count']} contacts for {user_email}")
        return result
    except Exception as e:
        logger.error(f"Failed to sync contacts for {user_email}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to sync contacts from Google"
        )

@router.get("/missing_extension")
async def get_missing_extension_contacts(request: Request, region: str = "US"):
    """Returns contacts that need phone number standardization."""
    user_email = get_current_user_email(request)
   
    # Validate region format (2-letter ISO code)
    if not region or len(region) != 2 or not region.isalpha():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid region code. Must be 2-letter ISO country code (e.g., US, IN, GB)"
        )
    
    region = region.upper()
    logger.info(f"Getting contacts needing fixes for user: {user_email}, region: {region}")
    
    try:
        contacts = contact_service.get_contacts_missing_extension(user_email, default_region=region)
        
        # PERF: Single query to get all staged resource names (O(1) lookup instead of N queries)
        staged_names = db_service.get_all_staged_resource_names(user_email)
        unstaged = [c for c in contacts if c['resource_name'] not in staged_names]
        
        return {
            "count": len(unstaged),
            "contacts": unstaged
        }
    except Exception as e:
        logger.error(f"Failed to get missing extension contacts: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to analyze contacts"
        )

@router.get("/analyze_regions")
async def analyze_regions(request: Request):
    """Analyzes contacts across multiple regions and returns counts."""
    user_email = get_current_user_email(request)
    logger.info(f"Analyzing regions for user: {user_email}")
    
    regions_to_test = ["IN", "US", "GB", "AU", "CA", "DE", "AE", "SG"]
    
    results = []
    for region in regions_to_test:
        contacts = contact_service.get_contacts_missing_extension(user_email, default_region=region)
        if len(contacts) > 0:
            results.append({"region": region, "count": len(contacts)})
    
    results.sort(key=lambda x: x["count"], reverse=True)
    return {"regions": results[:5]}

# ============= STAGING ENDPOINTS =============

@router.post("/stage_fix")
async def stage_fix(request: Request, fix_request: StageFixRequest):
    """
    Stage a contact fix for later pushing to Google.
    Actions: 'accept', 'reject', 'edit'
    """
    user_email = get_current_user_email(request)
    
    logger.info(f"Staging fix for user: {user_email}, action: {fix_request.action}, contact: {fix_request.contact_name}")
    
    try:
        db_service.stage_change(
            resource_name=fix_request.resource_name,
            contact_name=fix_request.contact_name,
            original_phone=fix_request.original_phone,
            new_phone=fix_request.new_phone,
            action=fix_request.action,
            user_email=user_email,
            new_name=fix_request.new_name
        )
        return {
            "status": "staged",
            "action": fix_request.action,
            "resource_name": fix_request.resource_name
        }
    except Exception as e:
        error_msg = f"Failed to stage fix for {fix_request.contact_name}: {type(e).__name__}: {str(e)}"
        logger.error(error_msg, exc_info=True)
        security_logger.log_invalid_input("/contacts/stage_fix", str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to stage fix: {str(e)[:100]}"  # Include partial error message
        )

@router.get("/pending_changes")
async def get_pending_changes(request: Request):
    """Get all staged changes and summary for the authenticated user."""
    user_email = get_current_user_email(request)
    logger.info(f"Getting pending changes for user: {user_email}")
    
    changes = db_service.get_staged_changes(user_email)
    summary = db_service.get_staged_changes_summary(user_email)
    return {
        "summary": summary,
        "changes": changes
    }

@router.delete("/staged/remove")
async def remove_staged(request: Request, resource_name: str):
    """Remove a specific staged change."""
    user_email = get_current_user_email(request)
    
    # Validate resource_name format
    if not resource_name or not resource_name.startswith("people/"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid resource_name format"
        )
    
    logger.info(f"Removing staged change for user: {user_email}, resource: {resource_name}")
    
    db_service.remove_staged_change(resource_name, user_email)
    return {"status": "removed", "resource_name": resource_name}

@router.delete("/staged")
async def clear_staged(request: Request):
    """Clear all staged changes for the authenticated user."""
    user_email = get_current_user_email(request)
    logger.info(f"Clearing all staged changes for user: {user_email}")
    
    db_service.clear_all_staged_changes(user_email)
    return {"status": "cleared"}

@router.post("/push_to_google")
async def push_to_google(request: Request):
    """
    Apply all accepted/edited staged changes to Google Contacts.
    Throttled to 60 contacts/minute to avoid Google API quota (90/min).
    Implements exponential backoff on 429 errors.
    """
    from backend.services import push_service
    
    user_email = get_current_user_email(request)
    logger.info(f"Pushing changes to Google for user: {user_email}")
    
    result = await push_service.push_contacts(user_email)
    
    logger.info(
        f"Push completed for {user_email}: "
        f"{result['pushed']} success, {result['failed']} failed, {result['skipped']} skipped"
    )
    
    return result


@router.get("/push_to_google/stream")
async def push_to_google_stream(request: Request):
    """
    Server-Sent Events (SSE) stream for pushing changes with real-time progress.
    Throttled to 60 contacts/minute to avoid Google API quota.
    """
    from backend.services import push_service
    
    user_email = get_current_user_email(request)
    logger.info(f"Streaming push to Google for user: {user_email}")
    
    return StreamingResponse(
        push_service.push_contacts_stream(user_email),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no"
        }
    )


