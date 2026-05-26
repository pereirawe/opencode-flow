#!/usr/bin/env bash
set -euo pipefail

# Intelligent backup script
# Usage: backup.sh <source_dir> [backup_name] [--zip]
#
# Creates a timestamped backup excluding common junk directories.
# Automatically prevents recursive self-copying.
# Preserves .env files by default (only junk dirs are excluded).

source "$(dirname "$0")/config.sh"

SOURCE_DIR="${1:-}"
BACKUP_NAME="${2:-dev_backup}"
CREATE_ZIP=false

for arg in "$@"; do
  case "$arg" in
    --zip) CREATE_ZIP=true ;;
  esac
done

if [[ -z "$SOURCE_DIR" ]]; then
  echo "Usage: backup.sh <source_dir> [backup_name] [--zip]"
  echo ""
  echo "Arguments:"
  echo "  source_dir   Directory to back up"
  echo "  backup_name  Base name for the backup (default: dev_backup)"
  echo "  --zip        Also create a .zip archive after copy"
  echo ""
  echo "Example:"
  echo "  backup.sh /home/user/dev my_backup --zip"
  exit 1
fi

SOURCE_DIR="$(realpath "$SOURCE_DIR" 2>/dev/null || echo "$SOURCE_DIR")"

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "Error: source directory '$SOURCE_DIR' does not exist"
  exit 1
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="${SOURCE_DIR}/${BACKUP_NAME}_${TIMESTAMP}"

EXCLUDES=(
  "${BACKUP_NAME}_*"         # prevent infinite recursion (any timestamped backup)
  "${BACKUP_NAME}_latest"    # prevent symlink recursion
  'bk'                       # user-defined backup dirs to ignore
  'node_modules'
  '.venv'
  '__pycache__'
  '.pytest_cache'
  'my_pycache'
  'vendor'                    # composer packages
  'bootstrap/cache'           # Laravel cache
)

RSYNC_EXCLUDES=()
for ex in "${EXCLUDES[@]}"; do
  RSYNC_EXCLUDES+=(--exclude="$ex")
done

echo "=== Intelligent Backup ==="
echo "  Source:       $SOURCE_DIR"
echo "  Destination:  $BACKUP_DIR"
echo "  Timestamp:    $TIMESTAMP"
echo "  Create .zip:  $CREATE_ZIP"
echo ""

mkdir -p "$BACKUP_DIR"

rsync -a --delete \
  "${RSYNC_EXCLUDES[@]}" \
  --info=progress2 \
  "$SOURCE_DIR/" "$BACKUP_DIR/"

echo ""
echo "Backup completed: $BACKUP_DIR"

# Update latest symlink
ln -sfn "${BACKUP_NAME}_${TIMESTAMP}" "${SOURCE_DIR}/${BACKUP_NAME}_latest"

if $CREATE_ZIP; then
  echo "Creating zip archive..."
  cd "$SOURCE_DIR"
  zip -r "${BACKUP_NAME}_${TIMESTAMP}.zip" "${BACKUP_NAME}_${TIMESTAMP}/" \
    -x "${BACKUP_NAME}_${TIMESTAMP}/node_modules/**" \
    -x "${BACKUP_NAME}_${TIMESTAMP}/.venv/**" \
    -x "${BACKUP_NAME}_${TIMESTAMP}/__pycache__/**" \
    -x "${BACKUP_NAME}_${TIMESTAMP}/.pytest_cache/**" \
    -x "${BACKUP_NAME}_${TIMESTAMP}/my_pycache/**" \
    -x "${BACKUP_NAME}_${TIMESTAMP}/vendor/**" \
    -x "${BACKUP_NAME}_${TIMESTAMP}/bk/**" \
    > /dev/null 2>&1
  cd "$OLDPWD"
  echo "Zip created: ${SOURCE_DIR}/${BACKUP_NAME}_${TIMESTAMP}.zip"
fi

echo ""
echo "Disk usage:"
du -sh "$BACKUP_DIR"
