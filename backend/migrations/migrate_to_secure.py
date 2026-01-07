"""
Database Migration Script for Security Hardening
Migrates existing database to add encryption and user tracking.
"""
import sqlite3
import sys
import os
from datetime import datetime
from cryptography.fernet import Fernet

# Get encryption key from environment
ENCRYPTION_KEY = os.getenv('ENCRYPTION_KEY')
if not ENCRYPTION_KEY:
    print("ERROR: ENCRYPTION_KEY not set in environment")
    sys.exit(1)

try:
    fernet = Fernet(ENCRYPTION_KEY.encode())
except Exception as e:
    print(f"ERROR: Invalid encryption key: {e}")
    sys.exit(1)

DB_FILE = 'backend/contacts.db'
BACKUP_FILE = f'backend/contacts.db.backup.{datetime.now().strftime("%Y%m%d_%H%M%S")}'

def encrypt(data: str) -> str:
    """Encrypt a string."""
    if not data:
        return ""
    return fernet.encrypt(data.encode('utf-8')).decode('utf-8')

def backup_database():
    """Create a backup of the database."""
    if not os.path.exists(DB_FILE):
        print(f"No existing database found at {DB_FILE}")
        return False
    
    import shutil
    shutil.copy2(DB_FILE, BACKUP_FILE)
    print(f"✅ Created backup: {BACKUP_FILE}")
    return True

def migrate_database(default_user_email='user@localhost'):
    """Migrate database schema and encrypt sensitive fields."""
    print(f"\n🔧 Starting database migration for{DB_FILE}")
    
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    try:
        # Check if migration already done
        cursor.execute("PRAGMA table_info(contacts)")
        columns = [col[1] for col in cursor.fetchall()]
        
        if 'user_email' in columns:
            print("⚠️  Migration appears to have already been run (user_email column exists)")
            response = input("Continue anyway? This will re-encrypt data. (y/N): ")
            if response.lower() != 'y':
                print("Migration cancelled")
                return
        
        print("\n📋 Migration Steps:")
        print("1. Adding user_email columns")
        print("2. Encrypting sensitive fields (phone_number, raw_json)")
        print("3. Creating indexes")
        
        # Step 1: Add user_email column if not exists
        try:
            cursor.execute('ALTER TABLE contacts ADD COLUMN user_email TEXT')
            print("  ✅ Added user_email to contacts table")
        except sqlite3.OperationalError as e:
            if 'duplicate column' in str(e).lower():
                print("  ℹ️  user_email already exists in contacts")
            else:
                raise
        
        try:
            cursor.execute('ALTER TABLE staged_changes ADD COLUMN user_email TEXT')
            print("  ✅ Added user_email to staged_changes table")
        except sqlite3.OperationalError as e:
            if 'duplicate column' in str(e).lower():
                print("  ℹ️  user_email already exists in staged_changes")
            else:
                raise
        
        # Step 2: Encrypt existing data and set default user_email
        print(f"\n Encrypting and assigning contacts to '{default_user_email}'...")
        
        cursor.execute('SELECT resource_name, phone_number, raw_json, user_email FROM contacts')
        contacts = cursor.fetchall()
        
        encrypted_count = 0
        for contact in contacts:
            resource_name = contact['resource_name']
            phone = contact['phone_number']
            raw_json = contact['raw_json']
            current_user_email = contact['user_email']
            
            # Check if already encrypted (starts with 'gAAAAA')
            phone_encrypted = phone and phone.startswith('gAAAAA')
            json_encrypted = raw_json and raw_json.startswith('gAAAAA')
            
            # Encrypt if not already encrypted
            new_phone = phone if phone_encrypted else encrypt(phone) if phone else None
            new_raw_json = raw_json if json_encrypted else encrypt(raw_json) if raw_json else None
            new_user_email = current_user_email if current_user_email else default_user_email
            
            cursor.execute('''
                UPDATE contacts 
                SET phone_number = ?, raw_json = ?, user_email = ?
                WHERE resource_name = ?
            ''', (new_phone, new_raw_json, new_user_email, resource_name))
            
            if not phone_encrypted or not json_encrypted:
                encrypted_count += 1
        
        print(f"  ✅ Encrypted {encrypted_count} contacts")
        
        # Update staged_changes with default user
        cursor.execute('UPDATE staged_changes SET user_email = ? WHERE user_email IS NULL', (default_user_email,))
        staged_count = cursor.rowcount
        print(f"  ✅ Assigned {staged_count} staged changes to user")
        
        # Step 3: Create indexes
        try:
            cursor.execute('CREATE INDEX IF NOT EXISTS idx_contacts_user ON contacts(user_email)')
            cursor.execute('CREATE INDEX IF NOT EXISTS idx_staged_user ON staged_changes(user_email)')
            print("  ✅ Created indexes")
        except sqlite3.OperationalError:
            print("  ℹ️  Indexes already exist")
        
        # Commit changes
        conn.commit()
        print("\n✅ Migration completed successfully!")
        
        # Show summary
        cursor.execute('SELECT COUNT(*) FROM contacts')
        total_contacts = cursor.fetchone()[0]
        cursor.execute('SELECT COUNT(*) FROM staged_changes')
        total_staged = cursor.fetchone()[0]
       
        print(f"\n📊 Database Summary:")
        print(f"  - Total contacts: {total_contacts}")
        print(f"  - Staged changes: {total_staged}")
        print(f"  - Encryption: Enabled")
        print(f"  - User isolation: Enabled")
        
    except Exception as e:
        print(f"\n❌ Migration failed: {e}")
        conn.rollback()
        print(f"Database rolled back. Restore from backup: {BACKUP_FILE}")
        raise
    finally:
        conn.close()

if __name__ == '__main__':
    print("=" * 60)
    print("   CONTACT FIXER - DATABASE MIGRATION TO SECURE VERSION")
    print("=" * 60)
    
    # Prompt for user email
    default_user = input("\nEnter default user email for existing data (default: user@localhost): ").strip()
    if not default_user:
        default_user = 'user@localhost'
    
    # Create backup
    has_existing_db = backup_database()
    
    if not has_existing_db:
        print("\nNo existing database to migrate. A new secure database will be created on first use.")
        sys.exit(0)
    
    # Confirm migration
    print(f"\n⚠️  WARNING: This will modify {DB_FILE}")
    print(f"   Backup created: {BACKUP_FILE}")
    response = input("\nProceed with migration? (y/N): ")
    
    if response.lower() != 'y':
        print("Migration cancelled")
        sys.exit(0)
    
    # Run migration
    migrate_database(default_user)
    
    print("\n" + "=" * 60)
    print("Migration complete! Your database is now secure.")
    print("=" * 60)
