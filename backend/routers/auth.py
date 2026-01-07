from fastapi import APIRouter, HTTPException
from backend.services.auth_service import get_authenticated_service

router = APIRouter(
    prefix="/auth",
    tags=["auth"]
)


@router.get("/login")
async def login_redirect():
    """
    Triggers the authentication flow.
    Since this is a local dev tool, this will likely open a browser on the Server (User's Mac).
    """
    try:
        # This will trigger the browser flow if not logged in
        get_authenticated_service()
        return {"status": "success", "message": "Authenticated successfully. You can close this window."}
    except Exception as e:
         raise HTTPException(status_code=500, detail=str(e))

@router.get("/status")
async def get_auth_status():
    try:
        service = get_authenticated_service()
        # Try to get the user's profile to prove we are logged in
        profile = service.people().get(resourceName='people/me', personFields='names,emailAddresses').execute()
        
        name = "Unknown"
        if 'names' in profile and len(profile['names']) > 0:
            name = profile['names'][0].get('displayName')
            
        email = "Unknown"
        if 'emailAddresses' in profile and len(profile['emailAddresses']) > 0:
            email = profile['emailAddresses'][0].get('value')

        return {
            "status": "authenticated",
            "user": name,
            "email": email
        }
    except Exception as e:
        # If we can't get the service or the profile, we aren't fully authenticated
        return {
            "status": "unauthenticated", 
            "detail": str(e),
            "instruction": "Please run 'python backend/services/auth_service.py' locally to login."
        }
