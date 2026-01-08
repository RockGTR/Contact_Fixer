import sqlite3
import json
import os
import threading
from contextlib import contextmanager
from datetime import datetime
from backend.core.security import FieldEncryption
import logging

logger = logging.getLogger(__name__)

DB_FILE = 'backend/contacts.db'

# PERF: Thread-local storage for connection pooling
_local = threading.local()

def get_db_connection():
    """Get or create a thread-local database connection."""
    if not hasattr(_local, 'conn') or _local.conn is None:
        _local.conn = sqlite3.connect(DB_FILE, check_same_thread=False)
        _local.conn.row_factory = sqlite3.Row
    return _local.conn

@contextmanager
def get_db():
    """Context manager for database operations with connection reuse."""
    conn = get_db_connection()
    try:
        yield conn
    except Exception:
        conn.rollback()
        raise

def init_db():
    """Initialize database with encryption-ready schema."""
    conn = get_db_connection()
    
    # Contacts table with user isolation
    conn.execute('''
        CREATE TABLE IF NOT EXISTS contacts (
            resource_name TEXT,
            user_email TEXT,
            etag TEXT,
            given_name TEXT,
            phone_number TEXT,
            raw_json TEXT,
            PRIMARY KEY (resource_name, user_email)
        )
    ''')
    
    # Staged changes table with user isolation
    conn.execute('''
        CREATE TABLE IF NOT EXISTS staged_changes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            resource_name TEXT,
            user_email TEXT,
            contact_name TEXT,
            new_name TEXT,
            original_phone TEXT,
            new_phone TEXT,
            action TEXT,
            created_at TEXT,
            updated_at TEXT,
            UNIQUE(resource_name, user_email)
        )
    ''')
    
    # Migration: Add user_email column to existing tables if needed
    try:
        conn.execute('ALTER TABLE contacts ADD COLUMN user_email TEXT')
        logger.info("Added user_email column to contacts table")
    except sqlite3.OperationalError:
        pass
    
    try:
        conn.execute('ALTER TABLE staged_changes ADD COLUMN user_email TEXT')
        logger.info("Added user_email column to staged_changes table")
    except sqlite3.OperationalError:
        pass
    
    # Create indexes for performance
    try:
        conn.execute('CREATE INDEX IF NOT EXISTS idx_contacts_user ON contacts(user_email)')
        conn.execute('CREATE INDEX IF NOT EXISTS idx_staged_user ON staged_changes(user_email)')
    except sqlite3.OperationalError:
        pass
        
    conn.commit()
    # Note: Don't close - connection is pooled and reused
    logger.info("Database initialized successfully")

def save_contacts(contacts_list, user_email: str):
    """
    Saves a list of contact dictionaries to the DB with encryption.
    contacts_list items must have: resourceName, etag, names, phoneNumbers
    
    Args:
        contacts_list: List of contact dictionaries from Google API
        user_email: Email of the authenticated user
    """
    conn = get_db_connection()
    cursor =  conn.cursor()
    
    count = 0
    for person in contacts_list:
        resource_name = person.get('resourceName')
        etag = person.get('etag')
        
        # Extract Display Name
        given_name = "Unknown"
        names = person.get('names', [])
        if names:
            given_name = names[0].get('displayName')
            
        # Extract First Phone Number (for simplicity in this v1)
        phone_number = None
        phones = person.get('phoneNumbers', [])
        if phones:
            phone_number = phones[0].get('value')
            
        raw_json = json.dumps(person)
        
        # Encrypt sensitive fields
        encrypted_phone = FieldEncryption.encrypt(phone_number) if phone_number else None
        encrypted_raw = FieldEncryption.encrypt(raw_json)

        cursor.execute('''
            INSERT OR REPLACE INTO contacts 
            (resource_name, user_email, etag, given_name, phone_number, raw_json)
            VALUES (?, ?, ?, ?, ?, ?)
        ''', (resource_name, user_email, etag, given_name, encrypted_phone, encrypted_raw))
        count += 1
        
    conn.commit()
    # Connection pooled - no close needed
    logger.info(f"Saved {count} contacts for user {user_email}")
    return count

def get_all_contacts(user_email: str):
    """Get all contacts for a specific user with decryption."""
    conn = get_db_connection()
    contacts = conn.execute(
        'SELECT * FROM contacts WHERE user_email = ?', 
        (user_email,)
    ).fetchall()
    # Connection pooled - no close needed
    
    # Decrypt sensitive fields
    decrypted_contacts = []
    for row in contacts:
        contact = dict(row)
        if contact.get('phone_number'):
            contact['phone_number'] = FieldEncryption.decrypt(contact['phone_number'])
        if contact.get('raw_json'):
            contact['raw_json'] = FieldEncryption.decrypt(contact['raw_json'])
        decrypted_contacts.append(contact)
    
    return decrypted_contacts

def find_contact_by_name(name: str):
    """Finds a contact by exact given name."""
    conn = get_db_connection()
    row = conn.execute('SELECT * FROM contacts WHERE given_name = ?', (name,)).fetchone()
    # Connection pooled - no close needed
    if row:
        return dict(row)
    return None

def find_contact_by_resource_name(resource_name: str, user_email: str):
    """Finds a contact by resource name for a specific user."""
    conn = get_db_connection()
    row = conn.execute(
        'SELECT * FROM contacts WHERE resource_name = ? AND user_email = ?', 
        (resource_name, user_email)
    ).fetchone()
    # Connection pooled - no close needed
    
    if row:
        contact = dict(row)
        # Decrypt sensitive fields
        if contact.get('phone_number'):
            contact['phone_number'] = FieldEncryption.decrypt(contact['phone_number'])
        if contact.get('raw_json'):
            contact['raw_json'] = FieldEncryption.decrypt(contact['raw_json'])
        return contact
    return None

# ============= STAGED CHANGES FUNCTIONS =============

def stage_change(resource_name: str, contact_name: str, original_phone: str, new_phone: str, action: str, user_email: str, new_name: str = None):
    """
    Stage a contact change. Uses UPSERT to track created_at vs updated_at.
    """
    conn = get_db_connection()
    now = datetime.now().isoformat()
    
    # SQLite UPSERT syntax (requires SQLite 3.24+)
    # If resource_name exists, update fields and set updated_at. 
    # If new, insert with created_at (and updated_at = now too?).
    try:
        conn.execute('''
            INSERT INTO staged_changes 
            (resource_name, user_email, contact_name, original_phone, new_phone, action, new_name, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(resource_name, user_email) DO UPDATE SET
                contact_name=excluded.contact_name,
                original_phone=excluded.original_phone,
                new_phone=excluded.new_phone,
                action=excluded.action,
                new_name=excluded.new_name,
                updated_at=excluded.updated_at
        ''', (resource_name, user_email, contact_name, original_phone, new_phone, action, new_name, now, now))
    except sqlite3.OperationalError:
        # Fallback for older SQLite
        conn.execute('''
            INSERT OR REPLACE INTO staged_changes 
            (resource_name, user_email, contact_name, original_phone, new_phone, action, created_at, new_name)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''', (resource_name, user_email, contact_name, original_phone, new_phone, action, now, new_name))
        
    conn.commit()
    # Connection pooled - no close needed

def get_staged_changes(user_email: str):
    """Get all staged changes for a specific user."""
    conn = get_db_connection()
    changes = conn.execute(
        'SELECT * FROM staged_changes WHERE user_email = ? ORDER BY created_at DESC',
        (user_email,)
    ).fetchall()
    # Connection pooled - no close needed
    return [dict(row) for row in changes]

def get_staged_changes_summary(user_email: str):
    """Get summary counts of staged changes for a specific user."""
    conn = get_db_connection()
    summary = {
        'total': 0,
        'accepts': 0,
        'rejects': 0,
        'edits': 0
    }
    rows = conn.execute(
        'SELECT action, COUNT(*) as count FROM staged_changes WHERE user_email = ? GROUP BY action',
        (user_email,)
    ).fetchall()
    for row in rows:
        action = row['action']
        count = row['count']
        summary['total'] += count
        if action == 'accept':
            summary['accepts'] = count
        elif action == 'reject':
            summary['rejects'] = count
        elif action == 'edit':
            summary['edits'] = count
    # Connection pooled - no close needed
    return summary

def remove_staged_change(resource_name: str, user_email: str):
    """Remove a specific staged change for a user."""
    conn = get_db_connection()
    conn.execute(
        'DELETE FROM staged_changes WHERE resource_name = ? AND user_email = ?', 
        (resource_name, user_email)
    )
    conn.commit()
    # Connection pooled - no close needed

def clear_all_staged_changes(user_email: str):
    """Clear all staged changes for a specific user."""
    conn = get_db_connection()
    conn.execute('DELETE FROM staged_changes WHERE user_email = ?', (user_email,))
    conn.commit()
    # Connection pooled - no close needed

def is_contact_staged(resource_name: str, user_email: str) -> bool:
    """Check if a contact is already staged for a user."""
    conn = get_db_connection()
    row = conn.execute(
        'SELECT 1 FROM staged_changes WHERE resource_name = ? AND user_email = ?', 
        (resource_name, user_email)
    ).fetchone()
    # Connection pooled - no close needed
    return row is not None

def get_all_staged_resource_names(user_email: str) -> set:
    """
    Get all staged resource names for a user as a set.
    Used for O(1) lookup instead of N individual queries.
    
    Args:
        user_email: Email of the authenticated user
        
    Returns:
        Set of resource_name strings that are currently staged
    """
    conn = get_db_connection()
    rows = conn.execute(
        'SELECT resource_name FROM staged_changes WHERE user_email = ?',
        (user_email,)
    ).fetchall()
    # Connection pooled - no close needed
    return {row['resource_name'] for row in rows}

# Initialize on module load
if not os.path.exists(DB_FILE):
    init_db()
else:
    # Ensure staged_changes table exists and has latest schema
    init_db()

