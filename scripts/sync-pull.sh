#!/usr/bin/env bash
# Pull from Proton Drive to ~/Work. Run BEFORE editing when switching devices.
set -euo pipefail

REMOTE="protondrive:00 - Work"
LOCAL="$HOME/Work"
LOG="$HOME/.local/state/rclone-pull.log"

# --- Preconditions -----------------------------------------------------------

if [[ ! -d "$LOCAL" ]]; then
  echo "ERROR: local target '$LOCAL' does not exist. Aborting." >&2
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

# --- Pull --------------------------------------------------------------------

echo "[$(date)] Pulling $REMOTE -> $LOCAL"

if rclone sync "$REMOTE" "$LOCAL" \
     --exclude 'Archive/**' \
     --transfers 4 \
     --checkers 8 \
     --log-file "$LOG" --log-level INFO
then
  echo "[$(date)] Pull complete."
else
  rc=$?
  echo "[$(date)] PULL FAILED (rclone exit $rc). Last log lines:" >&2
  tail -n 15 "$LOG" >&2
  exit "$rc"
fi
