from backend.services.auth_service import get_authenticated_service
from backend.services import db_service
import phonenumbers
import json

def sync_contacts_from_google(user_email: str):
    """
    1. Connects to Google
    2. Fetches all contacts
    3. Saves them to DB
    
    Args:
        user_email: Email of the authenticated user
    """
    service = get_authenticated_service()
    
    # connections.list is the API to get contacts
    # We ask for names and phoneNumbers
    results = service.people().connections().list(
        resourceName='people/me',
        pageSize=1000,
        personFields='names,phoneNumbers,metadata'
    ).execute()
    
    connections = results.get('connections', [])
    
    # Save to Local DB with user association
    count = db_service.save_contacts(connections, user_email)
    return {"status": "success", "synced_count": count, "total_from_google": len(connections)}

def detect_country_code(phone: str) -> str:
    """
    Intelligently detects the country code for a phone number.
    
    Detection Strategy:
    1. If number already has country code (starts with +), extract region
    2. Try to parse with multiple common regions and see which validates
    3. Use number length and pattern matching as hints
    4. Default to US if ambiguous (most common international format)
    
    Returns the detected region code (e.g., "US", "IN", "GB")
    """
    # Clean the number for analysis
    clean_phone = phone.strip().replace(" ", "").replace("-", "").replace("(", "").replace(")", "")
    
    # If already has country code, try to detect it
    if clean_phone.startswith('+'):
        try:
            parsed = phonenumbers.parse(clean_phone, None)
            region = phonenumbers.region_code_for_number(parsed)
            if region:
                return region
        except:
            pass
    
    # Common country patterns and their typical number lengths (without country code)
    # Format: (region_code, [typical_lengths], [specific_patterns])
    country_patterns = [
        ("US", [10], ["1"]),        # US/Canada: 10 digits, often starts with area code
        ("IN", [10], ["91", "0"]),  # India: 10 digits, may start with 91 or 0
        ("GB", [10, 11], ["44"]),   # UK: 10-11 digits
        ("AU", [9, 10], ["61"]),    # Australia: 9-10 digits
        ("DE", [10, 11], ["49"]),   # Germany: 10-11 digits
    ]
    
    # Try each region and check if the number is valid
    for region, lengths, _ in country_patterns:
        try:
            parsed = phonenumbers.parse(clean_phone, region)
            if phonenumbers.is_valid_number(parsed):
                return region
        except:
            continue
    
    # Fallback: Use number length heuristics
    digits_only = ''.join(filter(str.isdigit, clean_phone))
    
    # 10 digits without country code - could be US or IN
    if len(digits_only) == 10:
        # Check for US-style area codes (first digit 2-9)
        if digits_only[0] in '23456789':
            return "US"
        # Indian mobile numbers typically start with 6, 7, 8, or 9
        if digits_only[0] in '6789':
            return "IN"
    
    # 11 digits starting with 1 - likely US/Canada
    if len(digits_only) == 11 and digits_only.startswith('1'):
        return "US"
    
    # 12+ digits starting with 91 - likely India
    if len(digits_only) >= 12 and digits_only.startswith('91'):
        return "IN"
    
    # Default to US as it's the most common international format
    return "US"

def parse_and_validate(phone: str, default_region: str = None):
    """
    Parses a phone number and returns the E.164 format if valid.
    If no default_region is provided, intelligently detects the country.
    Returns None if invalid.
    """
    if default_region is None:
        default_region = detect_country_code(phone)
    
    try:
        parsed = phonenumbers.parse(phone, default_region)
        if phonenumbers.is_valid_number(parsed):
            return phonenumbers.format_number(parsed, phonenumbers.PhoneNumberFormat.E164)
    except phonenumbers.NumberParseException:
        pass
    return None

def fix_phone_numbers(default_country_code: str = None):
    """
    1. Reads contacts from DB
    2. Uses libphonenumber to parse and format
    3. Returns diff if formatting changes
    
    If default_country_code is None, uses intelligent detection per number.
    """
    all_contacts = db_service.get_all_contacts()
    
    fixed_list = []
    
    for contact in all_contacts:
        original_phone = contact['phone_number']
        if not original_phone:
            continue
            
        # Parse logic - uses intelligent detection if no default provided
        formatted = parse_and_validate(original_phone, default_country_code)
        
        if formatted:
            clean_original = original_phone.replace(" ", "").replace("-", "")
            if clean_original != formatted:
                 fixed_list.append({
                    "name": contact['given_name'],
                    "old": original_phone,
                    "new": formatted
                })
            
    return {"status": "analyzed", "needs_fixing_count": len(fixed_list), "preview": fixed_list}

def create_dummy_contact(name: str, phone: str):
    """
    Creates a new contact in Google Contacts.
    This demonstrates WRITE permissions.
    """
    service = get_authenticated_service()
    
    body = {
        "names": [
            {"givenName": name}
        ],
        "phoneNumbers": [
            {"value": phone}
        ]
    }
    
    # Execute the creation
    result = service.people().createContact(body=body).execute()
    
    # Note: This function is not used with authentication (no user_email parameter yet)
    # For future enhancement: add user_email parameter
    
    return {
        "status": "created",
        "resourceName": result.get('resourceName'),
        "name": name,
        "phone": phone
    }

def update_contact(resource_name: str, etag: str, user_email: str, new_phone: str = None, new_name: str = None):
    """
    Updates the phone number and/or name of an existing contact.
    Fetches fresh data first to ensure ETag is valid.
    
    Args:
        resource_name: Google contact resource name
        etag: Current etag (may be stale)
        user_email: Email of the authenticated user
        new_phone: New phone number (optional)
        new_name: New name (optional)
    """
    service = get_authenticated_service()
    
    # [ROBUSTNESS] Fetch latest Etag from Google to prevent 400 Stale Error
    latest_person = service.people().get(
        resourceName=resource_name,
        personFields='names,phoneNumbers'
    ).execute()
    
    fresh_etag = latest_person.get('etag')
    
    body = {"etag": fresh_etag}
    update_fields = []
    
    if new_phone:
        body["phoneNumbers"] = [{"value": new_phone}]
        update_fields.append('phoneNumbers')
        
    if new_name:
        body["names"] = [{"givenName": new_name}]
        update_fields.append('names')
        
    if not update_fields:
        return latest_person # No changes needed
    
    result = service.people().updateContact(
        resourceName=resource_name,
        updatePersonFields=','.join(update_fields),
        body=body
    ).execute()
    
    # [SYNC-CRITICAL] Immediately update local DB with new Etag
    db_service.save_contacts([result], user_email)
    
    return result

def get_contacts_missing_extension(user_email: str, default_region: str = "US"):
    """
    Retrieves all contacts that deviate from the standard E.164 format.
    
    Args:
        user_email: Email of the authenticated user
        default_region: ISO country code for numbers without country prefix (e.g., "US", "IN")
    """
    all_contacts = db_service.get_all_contacts(user_email)
    
    missing_ext_list = []
    
    for contact in all_contacts:
        phone = contact['phone_number']
        if not phone:
            continue
        
        # Use user-specified default region for parsing
        formatted = parse_and_validate(phone, default_region)
        
        # If it's a valid number BUT the original raw string doesn't match the E.164 format
        # This catches: 999... (missing +91), 099... (extra 0), 080... (landline)
        if formatted:
            clean_original = phone.replace(" ", "").replace("-", "")
            if clean_original != formatted:
                # Try to extract updated_at
                updated_at = None
                if contact.get('raw_json'):
                    try:
                        data = json.loads(contact['raw_json'])
                        if 'metadata' in data and 'sources' in data['metadata']:
                            for source in data['metadata']['sources']:
                                if 'updateTime' in source:
                                    updated_at = source['updateTime']
                                    break
                    except:
                        pass

                missing_ext_list.append({
                    "resource_name": contact['resource_name'],
                    "name": contact['given_name'],
                    "phone": phone,
                    "suggested": formatted,
                    "updated_at": updated_at
                })
            
    return missing_ext_list
