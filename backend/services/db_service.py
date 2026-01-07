import sqlite3
import json
import os
from datetime import datetime

DB_FILE = 'backend/contacts.db'

def get_db_connection():
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db_connection()
    # Contacts table
    conn.execute('''
        CREATE TABLE IF NOT EXISTS contacts (
            resource_name TEXT PRIMARY KEY,
            etag TEXT,
            given_name TEXT,
            phone_number TEXT,
            raw_json TEXT
        )
    ''')
    
    # Staged changes table - tracks fixes before pushing to Google
    conn.execute('''
        CREATE TABLE IF NOT EXISTS staged_changes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            resource_name TEXT UNIQUE,
            contact_name TEXT,
            new_name TEXT,
            original_phone TEXT,
            new_phone TEXT,
            action TEXT,
            created_at TEXT
        )
    ''')
    
    # 3. Migration: Add new_name column if it doesn't exist
    try:
        conn.execute('ALTER TABLE staged_changes ADD COLUMN new_name TEXT')
    except sqlite3.OperationalError:
        pass

    # 4. Migration: Add updated_at if it doesn't exist
    try:
        conn.execute('ALTER TABLE staged_changes ADD COLUMN updated_at TEXT')
    except sqlite3.OperationalError:
        pass
        
    conn.commit()
    conn.close()

def save_contacts(contacts_list):
    """
    Saves a list of contact dictionaries to the DB.
    contacts_list items must have: resourceName, etag, names, phoneNumbers
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    
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

        cursor.execute('''
            INSERT OR REPLACE INTO contacts (resource_name, etag, given_name, phone_number, raw_json)
            VALUES (?, ?, ?, ?, ?)
        ''', (resource_name, etag, given_name, phone_number, raw_json))
        count += 1
        
    conn.commit()
    conn.close()
    return count

def get_all_contacts():
    conn = get_db_connection()
    contacts = conn.execute('SELECT * FROM contacts').fetchall()
    conn.close()
    return [dict(row) for row in contacts]

def find_contact_by_name(name: str):
    """Finds a contact by exact given name."""
    conn = get_db_connection()
    row = conn.execute('SELECT * FROM contacts WHERE given_name = ?', (name,)).fetchone()
    conn.close()
    if row:
        return dict(row)
    return None

def find_contact_by_resource_name(resource_name: str):
    """Finds a contact by resource name."""
    conn = get_db_connection()
    row = conn.execute('SELECT * FROM contacts WHERE resource_name = ?', (resource_name,)).fetchone()
    conn.close()
    if row:
        return dict(row)
    return None

# ============= STAGED CHANGES FUNCTIONS =============

def stage_change(resource_name: str, contact_name: str, original_phone: str, new_phone: str, action: str, new_name: str = None):
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
            (resource_name, contact_name, original_phone, new_phone, action, new_name, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(resource_name) DO UPDATE SET
                contact_name=excluded.contact_name,
                original_phone=excluded.original_phone,
                new_phone=excluded.new_phone,
                action=excluded.action,
                new_name=excluded.new_name,
                updated_at=excluded.updated_at
        ''', (resource_name, contact_name, original_phone, new_phone, action, new_name, now, now))
    except sqlite3.OperationalError:
        # Fallback for older SQLite (unlikely on Mac, but safe): INSERT OR REPLACE
        # This resets created_at unfortunately, but functionality works.
        conn.execute('''
            INSERT OR REPLACE INTO staged_changes 
            (resource_name, contact_name, original_phone, new_phone, action, created_at, new_name)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ''', (resource_name, contact_name, original_phone, new_phone, action, now, new_name))
        
    conn.commit()
    conn.close()

def get_staged_changes():
    """Get all staged changes."""
    conn = get_db_connection()
    # Return both created_at and updated_at
    changes = conn.execute('SELECT * FROM staged_changes ORDER BY created_at DESC').fetchall()
    conn.close()
    return [dict(row) for row in changes]

def get_staged_changes_summary():
    """Get summary counts of staged changes."""
    conn = get_db_connection()
    summary = {
        'total': 0,
        'accepts': 0,
        'rejects': 0,
        'edits': 0
    }
    rows = conn.execute('SELECT action, COUNT(*) as count FROM staged_changes GROUP BY action').fetchall()
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
    conn.close()
    return summary

def remove_staged_change(resource_name: str):
    """Remove a specific staged change."""
    conn = get_db_connection()
    conn.execute('DELETE FROM staged_changes WHERE resource_name = ?', (resource_name,))
    conn.commit()
    conn.close()

def clear_all_staged_changes():
    """Clear all staged changes."""
    conn = get_db_connection()
    conn.execute('DELETE FROM staged_changes')
    conn.commit()
    conn.close()

def is_contact_staged(resource_name: str) -> bool:
    """Check if a contact is already staged."""
    conn = get_db_connection()
    row = conn.execute('SELECT 1 FROM staged_changes WHERE resource_name = ?', (resource_name,)).fetchone()
    conn.close()
    return row is not None

# Initialize on module load
if not os.path.exists(DB_FILE):
    init_db()
else:
    # Ensure staged_changes table exists and has latest schema
    init_db()

