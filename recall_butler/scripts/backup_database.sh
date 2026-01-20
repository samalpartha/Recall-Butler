#!/bin/bash
# Database backup script for Recall Butler
# Usage: ./backup_database.sh

set -e

# Configuration
BACKUP_DIR="/backups/recall-butler"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/recall_butler_$TIMESTAMP.sql.gz"
RETENTION_DAYS=30

# Load environment variables
if [ -f .env ]; then
    source .env
else
    echo "Error: .env file not found"
    exit 1
fi

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo "Starting database backup..."
echo "Backup file: $BACKUP_FILE"

# Perform backup with compression
pg_dump "$DATABASE_URL" | gzip > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo "✅ Backup completed successfully"
    
    # Calculate backup size
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo "Backup size: $BACKUP_SIZE"
    
    # Upload to S3 (optional)
    if [ -n "$AWS_S3_BACKUP_BUCKET" ]; then
        echo "Uploading to S3..."
        aws s3 cp "$BACKUP_FILE" "s3://$AWS_S3_BACKUP_BUCKET/backups/"
        echo "✅ Uploaded to S3"
    fi
    
    # Delete old backups
    echo "Cleaning up old backups (older than $RETENTION_DAYS days)..."
    find "$BACKUP_DIR" -name "recall_butler_*.sql.gz" -type f -mtime +$RETENTION_DAYS -delete
    echo "✅ Cleanup completed"
    
else
    echo "❌ Backup failed"
    exit 1
fi

# Test backup integrity
echo "Testing backup integrity..."
gunzip -c "$BACKUP_FILE" | head -n 1 > /dev/null

if [ $? -eq 0 ]; then
    echo "✅ Backup integrity verified"
else
    echo "⚠️  Backup may be corrupted"
    exit 1
fi

echo "✅ Backup process complete"
