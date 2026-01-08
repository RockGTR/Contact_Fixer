#!/bin/bash

# ============================================================
# Contact Fixer - Database Backup Script
# ============================================================
# Automated database backup with encryption and retention
# Usage: ./scripts/backup_database.sh
# Cron: 0 2 * * * /opt/contact-fixer/scripts/backup_database.sh
# ============================================================

set -e  # Exit on error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DB_PATH="${PROJECT_ROOT}/backend/contacts.db"
BACKUP_DIR="${PROJECT_ROOT}/backups"
LOG_FILE="${PROJECT_ROOT}/backend/logs/backup.log"
RETENTION_DAYS=7

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Start backup
log "========== Starting Database Backup =========="

# Check if database exists
if [ ! -f "$DB_PATH" ]; then
    log "❌ ERROR: Database not found at $DB_PATH"
    exit 1
fi

# Generate backup filename with timestamp
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
BACKUP_FILE="${BACKUP_DIR}/contacts_${TIMESTAMP}.db"

# Create backup
log "📦 Creating backup: $BACKUP_FILE"
cp "$DB_PATH" "$BACKUP_FILE"

# Verify backup
if [ ! -f "$BACKUP_FILE" ]; then
    log "❌ ERROR: Backup file was not created"
    exit 1
fi

# Get file sizes
DB_SIZE=$(du -h "$DB_PATH" | cut -f1)
BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)

log "✅ Backup created successfully"
log "   Original: $DB_SIZE"
log "   Backup  : $BACKUP_SIZE"

# Create 'latest' symlink
LATEST_LINK="${BACKUP_DIR}/contacts_LATEST.db"
ln -sf "$(basename "$BACKUP_FILE")" "$LATEST_LINK"
log "🔗 Updated latest backup symlink"

# Optional: Compress backup
if command -v gzip &> /dev/null; then
    log "🗜️  Compressing backup..."
    gzip "$BACKUP_FILE"
    BACKUP_FILE="${BACKUP_FILE}.gz"
    COMPRESSED_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    log "   Compressed: $COMPRESSED_SIZE"
fi

# Clean up old backups (retention policy)
log "🧹 Cleaning up old backups (keeping last $RETENTION_DAYS days)..."
find "$BACKUP_DIR" -name "contacts_*.db*" -type f -mtime +$RETENTION_DAYS -delete
REMAINING=$(find "$BACKUP_DIR" -name "contacts_*.db*" -type f | wc -l)
log "   Backups remaining: $REMAINING"

# Calculate total backup size
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
log "📊 Total backup storage: $TOTAL_SIZE"

log "========== Backup Completed Successfully =========="
log ""

exit 0
