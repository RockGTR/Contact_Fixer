from fastapi import APIRouter, Request, HTTPException, status
from pydantic import BaseModel, Field, validator
from typing import Optional
from backend.services import contact_service, db_service
from backend.middleware.auth_middleware import get_current_user_email
from backend.middleware.rate_limit import limiter
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
@limiter.limit("30/minute")
async def list_contacts(request: Request):
    """Get all contacts for the authenticated user."""
    user_email = get_current_user_email(request)
    logger.info(f"Listing contacts for user: {user_email}")
    return db_service.get_all_contacts(user_email)

@router.post("/sync")
@limiter.limit("5/minute")  # Stricter limit for expensive operation
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
@limiter.limit("20/minute")
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
        
        # Filter out already staged contacts
        unstaged = [c for c in contacts if not db_service.is_contact_staged(c['resource_name'], user_email)]
        
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
@limiter.limit("10/minute")
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
@limiter.limit("60/minute")
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
@limiter.limit("20/minute")
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
@limiter.limit("30/minute")
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
@limiter.limit("10/minute")
async def clear_staged(request: Request):
    """Clear all staged changes for the authenticated user."""
    user_email = get_current_user_email(request)
    logger.info(f"Clearing all staged changes for user: {user_email}")
    
    db_service.clear_all_staged_changes(user_email)
    return {"status": "cleared"}

@router.post("/push_to_google")
@limiter.limit("3/minute")  # Very strict limit for this critical operation
async def push_to_google(request: Request):
    """
    Apply all accepted/edited staged changes to Google Contacts.
    Rejects are skipped (no action needed on Google).
    """
    user_email = get_current_user_email(request)
    logger.info(f"Pushing changes to Google for user: {user_email}")
    
    changes = db_service.get_staged_changes(user_email)
    
    if not changes:
        return {
            "status": "completed",
            "pushed": 0,
            "failed": 0,
            "skipped": 0,
            "message": "No staged changes to push"
        }
    
    results = {
        "success": [],
        "failed": [],
        "skipped": []
    }
    
    for change in changes:
        if change['action'] == 'reject':
            results['skipped'].append(change['contact_name'])
            continue
            
        # For 'accept' and 'edit', push to Google
        try:
            contact = db_service.find_contact_by_resource_name(change['resource_name'], user_email)
            if not contact:
                results['failed'].append({
                    "name": change['contact_name'],
                    "error": "Contact not found in local DB"
                })
                logger.warning(f"Contact not found for push: {change['resource_name']}")
                continue
                
            contact_service.update_contact(
                resource_name=change['resource_name'],
                etag=contact['etag'],
                user_email=user_email,
                new_phone=change['new_phone'],
                new_name=change['new_name']
            )
            results['success'].append(change['contact_name'])
            logger.info(f"Successfully pushed change for: {change['contact_name']}")
        except Exception as e:
            results['failed'].append({
                "name": change['contact_name'],
                "error": str(e)
            })
            logger.error(f"Failed to push change for {change['contact_name']}: {e}")
    
    # Clear all staged changes after push
    db_service.clear_all_staged_changes(user_email)
    
    logger.info(f"Push completed for {user_email}: {len(results['success'])} success, {len(results['failed'])} failed, {len(results['skipped'])} skipped")
    
    return {
        "status": "completed",
        "pushed": len(results['success']),
        "failed": len(results['failed']),
        "skipped": len(results['skipped']),
        "details": results
    }
