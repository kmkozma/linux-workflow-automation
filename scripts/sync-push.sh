#!/usr/bin/env bash
# One-way push of ~/Work to Proton Drive with dated safety net.
set -euo pipefail

REMOTE="protondrive:Work"
LOCAL="$HOME/Work"
BACKUP="protondrive:_backups/$(date +%Y-%m-%d_%H%M%S)"
LOG="$HOME/.local/state/rclone-push.log"

PASS="$(secret-tool lookup service rclone config automation)"
export RCLONE_CONFIG_PASS="$PASS"

echo "[$(date)] Pushing $LOCAL -> $REMOTE"
rclone sync "$LOCAL" "$REMOTE" \
  --backup-dir "$BACKUP" \
  --exclude 'Archive/**' \
  --transfers 4 \
  --checkers 8 \
  --log-file "$LOG" --log-level INFO

echo "[$(date)] Push complete. Safety net: $BACKUP"
