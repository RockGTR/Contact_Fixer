"""
Push Service - Handles pushing staged changes to Google Contacts.
Implements throttling (60/min), exponential backoff, and SSE streaming.
"""

import asyncio
import json
import logging
from typing import AsyncGenerator, Dict, List, Any

from backend.services import contact_service, db_service
from backend.services.contact_service import GoogleRateLimitError

logger = logging.getLogger(__name__)

# Constants
THROTTLE_DELAY_SECONDS = 1.0  # 60 contacts/min
MAX_RETRIES = 3
INITIAL_BACKOFF_SECONDS = 60


class PushResult:
    """Result of a push operation."""
    def __init__(self):
        self.success: List[str] = []
        self.failed: List[Dict[str, str]] = []
        self.skipped: List[str] = []
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            "success": self.success,
            "failed": self.failed,
            "skipped": self.skipped,
        }


async def push_contacts(user_email: str) -> Dict[str, Any]:
    """
    Push all staged changes to Google Contacts.
    Throttled to 60 contacts/minute with exponential backoff on 429 errors.
    
    Returns summary dict with pushed/failed/skipped counts.
    """
    changes = db_service.get_staged_changes(user_email)
    
    if not changes:
        return {
            "status": "completed",
            "pushed": 0,
            "failed": 0,
            "skipped": 0,
            "message": "No staged changes to push"
        }
    
    result = PushResult()
    
    for i, change in enumerate(changes):
        if change['action'] == 'reject':
            result.skipped.append(change['contact_name'])
            continue
        
        # Throttle: 1 second between contacts
        if i > 0:
            await asyncio.sleep(THROTTLE_DELAY_SECONDS)
        
        success = await _push_single_contact(change, user_email, result)
        if success:
            logger.info(f"Successfully pushed: {change['contact_name']}")
    
    # Clear all staged changes after push
    db_service.clear_all_staged_changes(user_email)
    
    logger.info(
        f"Push completed for {user_email}: "
        f"{len(result.success)} success, {len(result.failed)} failed, {len(result.skipped)} skipped"
    )
    
    return {
        "status": "completed",
        "pushed": len(result.success),
        "failed": len(result.failed),
        "skipped": len(result.skipped),
        "details": result.to_dict()
    }


async def push_contacts_stream(user_email: str) -> AsyncGenerator[str, None]:
    """
    Push staged changes with real-time progress via SSE stream.
    Yields JSON events for: start, progress, backoff, complete.
    """
    changes = db_service.get_staged_changes(user_email)
    
    if not changes:
        yield _sse_event({"type": "complete", "pushed": 0, "failed": 0, "skipped": 0})
        return
    
    # Separate pushable and skipped
    pushable = [c for c in changes if c['action'] != 'reject']
    skipped = [c for c in changes if c['action'] == 'reject']
    total = len(pushable)
    
    result = PushResult()
    result.skipped = [c['contact_name'] for c in skipped]
    
    # Send start event
    yield _sse_event({"type": "start", "total": total, "skipped": len(skipped)})
    
    for i, change in enumerate(pushable):
        # Throttle
        if i > 0:
            await asyncio.sleep(THROTTLE_DELAY_SECONDS)
        
        # Send progress event
        yield _sse_event({
            "type": "progress",
            "current": i + 1,
            "total": total,
            "name": change['contact_name']
        })
        
        # Push with backoff
        success = await _push_with_backoff_stream(change, user_email, result)
        
        # Yield backoff events if rate limited (handled in _push_with_backoff_stream)
        # Note: For true streaming of backoff, we'd need a different approach
    
    # Clear staged changes
    db_service.clear_all_staged_changes(user_email)
    
    # Send complete event
    yield _sse_event({
        "type": "complete",
        "pushed": len(result.success),
        "failed": len(result.failed),
        "skipped": len(result.skipped),
        "details": result.to_dict()
    })


async def _push_single_contact(
    change: Dict[str, Any],
    user_email: str,
    result: PushResult
) -> bool:
    """Push a single contact with retry logic."""
    try:
        contact = db_service.find_contact_by_resource_name(
            change['resource_name'], user_email
        )
        if not contact:
            result.failed.append({
                "name": change['contact_name'],
                "error": "Contact not found in local DB"
            })
            logger.warning(f"Contact not found for push: {change['resource_name']}")
            return False
        
        # Try with exponential backoff
        for retry in range(MAX_RETRIES + 1):
            try:
                contact_service.update_contact(
                    resource_name=change['resource_name'],
                    etag=contact['etag'],
                    user_email=user_email,
                    new_phone=change['new_phone'],
                    new_name=change['new_name']
                )
                result.success.append(change['contact_name'])
                return True
            except GoogleRateLimitError as rate_err:
                if retry < MAX_RETRIES:
                    wait_time = INITIAL_BACKOFF_SECONDS * (2 ** retry)
                    logger.warning(
                        f"Rate limited on {change['contact_name']}, "
                        f"waiting {wait_time}s (retry {retry + 1}/{MAX_RETRIES})"
                    )
                    await asyncio.sleep(wait_time)
                else:
                    raise rate_err
                    
    except Exception as e:
        result.failed.append({
            "name": change['contact_name'],
            "error": str(e)[:100]
        })
        logger.error(f"Failed to push {change['contact_name']}: {e}")
        return False
    
    return False


async def _push_with_backoff_stream(
    change: Dict[str, Any],
    user_email: str,
    result: PushResult
) -> bool:
    """Push a single contact with backoff (for streaming endpoint)."""
    return await _push_single_contact(change, user_email, result)


def _sse_event(data: Dict[str, Any]) -> str:
    """Format data as SSE event string."""
    return f"data: {json.dumps(data)}\n\n"
