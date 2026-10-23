#!usr/bin/env bash
# One-way push of ~/Work to Proton Drive with dated safety net.
set -euo pipefail

REMOTE="protondrive:00 - Work"
LOCAL="$HOME/Work"
BACKUP="protondrive:_backups/$(date +%Y-%m-%d_%H%M%S)"
LOG="$HOME/.local/state/rclone-push.log"

# --- Preconditions -----------------------------------------------------------

if [[ ! -d "$LOCAL" ]]; then
  echo "ERROR: local source '$LOCAL' does not exist. Aborting." >&2
  exit 1
fi

mkdir -p "$(dirname "$LOG")"

PASS="$(secret-tool lookup service rclone config automation)"
if [[ -z "$PASS" ]]; then
  echo "ERROR: no rclone config password found in the secret service." >&2
  echo "       Expected attributes: service=rclone config=automation" >&2
  exit 1
fi
export RCLONE_CONFIG_PASS="$PASS"

# --- Push --------------------------------------------------------------------

echo "[$(date)] Pushing $LOCAL -> $REMOTE"

if rclone sync "$LOCAL" "$REMOTE" \
     --backup-dir "$BACKUP" \
     --exclude 'Archive/**' \
     --transfers 4 \
     --checkers 8 \
     --log-file "$LOG" --log-level INFO
then
  echo "[$(date)] Push complete. Safety net: $BACKUP"
else
  rc=$?
  echo "[$(date)] PUSH FAILED (rclone exit $rc). Last log lines:" >&2
  tail -n 15 "$LOG" >&2
  exit "$rc"
fi
