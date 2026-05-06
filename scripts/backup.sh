#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="${DEPLOY_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"
ENV_FILE="${ENV_FILE:-$DEPLOY_DIR/.env}"
BACKUP_DIR="${BACKUP_DIR:-$DEPLOY_DIR/backups}"
LOG_FILE="${BACKUP_LOG_FILE:-$DEPLOY_DIR/backup.log}"
RETENTION_COUNT="${RETENTION_COUNT:-7}"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "$ENV_FILE"
  set +a
fi

DB_NAME="${DB_NAME:-statuspulse}"
DB_USER="${DB_USER:-statuspulse}"
DB_PASSWORD="${DB_PASSWORD:-}"
S3_BUCKET="${S3_BUCKET:-}"

log() {
  printf "%s %s\n" "$(date -Iseconds)" "$*" | tee -a "$LOG_FILE"
}

die() {
  log "ERROR: $*"
  exit 1
}

[[ -n "$DB_PASSWORD" ]] || die "DB_PASSWORD must be set"

mkdir -p "$BACKUP_DIR"
timestamp="$(date +%F_%H%M%S)"
backup_file="$BACKUP_DIR/statuspulse_db_${timestamp}.sql.gz"

log "Starting PostgreSQL backup to $backup_file"
docker exec -e PGPASSWORD="$DB_PASSWORD" statuspulse-postgres \
  pg_dump -U "$DB_USER" "$DB_NAME" | gzip -9 > "$backup_file"
log "Backup created: $backup_file"

mapfile -t old_backups < <(find "$BACKUP_DIR" -maxdepth 1 -type f -name 'statuspulse_db_*.sql.gz' -printf '%T@ %p\n' | sort -rn | awk "NR>${RETENTION_COUNT} {print \$2}")
for old_backup in "${old_backups[@]}"; do
  rm -f "$old_backup"
  log "Removed old backup: $old_backup"
done

if [[ -n "$S3_BUCKET" ]]; then
  if command -v aws >/dev/null 2>&1; then
    log "Uploading backup to s3://$S3_BUCKET/statuspulse/$(basename "$backup_file")"
    aws s3 cp "$backup_file" "s3://$S3_BUCKET/statuspulse/$(basename "$backup_file")"
  else
    log "S3_BUCKET is set, but aws CLI is not installed; skipping upload"
  fi
fi

log "Backup completed successfully"
