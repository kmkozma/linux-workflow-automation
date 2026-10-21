#!/usr/bin/env bash
# Pull from Proton Drive to ~/Work. Run BEFORE editing when switching devices.
set -euo pipefail

REMOTE="protondrive:Work"
LOCAL="$HOME/Work"
LOG="$HOME/.local/state/rclone-pull.log"

PASS="$(secret-tool lookup service rclone config automation)"
export RCLONE_CONFIG_PASS="$PASS"

echo "[$(date)] Pulling $REMOTE -> $LOCAL"
rclone sync "$REMOTE" "$LOCAL" \
  --exclude 'Archive/**' \
  --transfers 4 \
  --checkers 8 \
  --log-file "$LOG" --log-level INFO

echo "[$(date)] Pull complete."
