from fastapi import APIRouter
from pydantic import BaseModel
from typing import Optional
from backend.services import contact_service, db_service

router = APIRouter(
    prefix="/contacts",
    tags=["contacts"]
)

# ============= REQUEST MODELS =============

class StageFixRequest(BaseModel):
    resource_name: str
    contact_name: str
    original_phone: str
    new_phone: str
    action: str  # 'accept', 'reject', 'edit'
    new_name: Optional[str] = None

# ============= EXISTING ENDPOINTS =============

@router.get("/")
async def list_contacts():
    """Get all contacts currently in the local database."""
    return db_service.get_all_contacts()

@router.post("/sync")
async def sync_contacts():
    """Trigger a fetch from Google to the local database."""
    return contact_service.sync_contacts_from_google()

@router.get("/missing_extension")
async def get_missing_extension_contacts(region: str = "US"):
    """Returns contacts that need phone number standardization."""
    contacts = contact_service.get_contacts_missing_extension(default_region=region)
    
    # Filter out already staged contacts
    unstaged = [c for c in contacts if not db_service.is_contact_staged(c['resource_name'])]
    
    return {
        "count": len(unstaged),
        "contacts": unstaged
    }

@router.get("/analyze_regions")
async def analyze_regions():
    """Analyzes contacts across multiple regions and returns counts."""
    regions_to_test = ["IN", "US", "GB", "AU", "CA", "DE", "AE", "SG"]
    
    results = []
    for region in regions_to_test:
        contacts = contact_service.get_contacts_missing_extension(default_region=region)
        if len(contacts) > 0:
            results.append({"region": region, "count": len(contacts)})
    
    results.sort(key=lambda x: x["count"], reverse=True)
    return {"regions": results[:5]}

# ============= STAGING ENDPOINTS =============

@router.post("/stage_fix")
async def stage_fix(request: StageFixRequest):
    """
    Stage a contact fix for later pushing to Google.
    Actions: 'accept', 'reject', 'edit'
    """
    db_service.stage_change(
        resource_name=request.resource_name,
        contact_name=request.contact_name,
        original_phone=request.original_phone,
        new_phone=request.new_phone,
        action=request.action,
        new_name=request.new_name
    )
    return {
        "status": "staged",
        "action": request.action,
        "resource_name": request.resource_name
    }

@router.get("/pending_changes")
async def get_pending_changes():
    """Get all staged changes and summary."""
    changes = db_service.get_staged_changes()
    summary = db_service.get_staged_changes_summary()
    return {
        "summary": summary,
        "changes": changes
    }

@router.delete("/staged/remove")
async def remove_staged(resource_name: str):
    """Remove a specific staged change."""
    db_service.remove_staged_change(resource_name)
    return {"status": "removed", "resource_name": resource_name}

@router.delete("/staged")
async def clear_staged():
    """Clear all staged changes."""
    db_service.clear_all_staged_changes()
    return {"status": "cleared"}

@router.post("/push_to_google")
async def push_to_google():
    """
    Apply all accepted/edited staged changes to Google Contacts.
    Rejects are skipped (no action needed on Google).
    """
    changes = db_service.get_staged_changes()
    
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
            contact = db_service.find_contact_by_resource_name(change['resource_name'])
            if not contact:
                results['failed'].append({
                    "name": change['contact_name'],
                    "error": "Contact not found in local DB"
                })
                continue
                
            contact_service.update_contact(
                resource_name=change['resource_name'],
                etag=contact['etag'],
                new_phone=change['new_phone'],
                new_name=change['new_name']
            )
            results['success'].append(change['contact_name'])
        except Exception as e:
            results['failed'].append({
                "name": change['contact_name'],
                "error": str(e)
            })
    
    # Clear all staged changes after push
    db_service.clear_all_staged_changes()
    
    return {
        "status": "completed",
        "pushed": len(results['success']),
        "failed": len(results['failed']),
        "skipped": len(results['skipped']),
        "details": results
    }
