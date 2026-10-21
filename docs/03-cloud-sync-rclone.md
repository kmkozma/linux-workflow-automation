# Cloud Sync: rclone + Proton Drive

## Purpose

This chapter documents the synchronization layer: a one-way push discipline
from `~/Work/` to Proton Drive via rclone, with dated safety-net folders for
accidental overwrites, plus the inverse pull procedure for the multi-device
protocol.

Core design rules, established in `00-architecture-overview.md`:

1. **One-way push, never bisync** — last pusher wins; conflicts are
   impossible by construction rather than detected after the fact
2. **No live editing on the mount** — the remote is a mirror, not a workspace
3. **Credentials never in plaintext** — the rclone config is encrypted at
   rest, and the configuration password is retrieved from the system secret
   service (GNOME Keyring) at runtime

## Installation

Mint's packaged rclone predates the Proton Drive backend, so install from
upstream:

```bash
sudo apt remove rclone
curl https://rclone.org/install.sh | sudo bash
sudo apt install libsecret-tools
```

`libsecret-tools` provides `secret-tool`, used to retrieve the configuration
password at runtime. Verify the backend exists before configuring:

```bash
rclone help backend protondrive
```

If that prints backend documentation instead of an error, proceed.

## Remote Setup

The Proton Drive backend authenticates with **account credentials** —
username, password, and 2FA — not an OAuth browser flow.

```bash
rclone config
```

1. `n` — new remote
2. Name it `protondrive`
3. Backend type: `protondrive`
4. Username: the Proton account address
5. Password: `y`, then the account password — paste through a text editor
   first to verify there is no trailing whitespace
6. 2FA code: leave empty (codes are generated from the seed)
7. OTP secret key: `y`, then the TOTP seed in plaintext — rclone obscures it
   itself. Do not add quotes; they are stored as part of the value
8. `n` at advanced config, `y` to save

**Important:** the account password resides (obfuscated, not encrypted) in
`~/.config/rclone/rclone.conf` until a configuration password is set. Because
the whole Proton account — not just Drive — rides on those credentials,
configuration encryption is **mandatory** in this design, not optional.

### Set the Configuration Password

From the main `rclone config` menu after the remote exists:

```
s) Set configuration password
```

Choose a strong passphrase and store a break-glass copy in a password
manager — there is no other recovery path for an encrypted config.

### Register the Password with the Secret Service

```bash
secret-tool store --label="rclone config password" \
  service rclone config automation
```

The attribute pair (`service rclone`, `config automation`) must match the
`secret-tool lookup` calls in the sync scripts exactly.

## Verification

```bash
head -3 ~/.config/rclone/rclone.conf
```

An encrypted config begins with a header comment; no credentials visible.

```bash
chmod 600 ~/.config/rclone/rclone.conf
secret-tool lookup service rclone config automation
export RCLONE_CONFIG_PASS="$(secret-tool lookup service rclone config automation)"
rclone lsd protondrive:
```

If the last command lists Drive folders, the full chain works: credential
authentication, TOTP generation from the stored seed, and config decryption
via the Keyring-retrieved password.

## The Scripts

All scripts live in `scripts/` and assume the `rclone` binary and the
`protondrive` remote configured above. Credentials are retrieved at runtime;
nothing sensitive is hardcoded.

### scripts/sync-push.sh

```bash
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
```

How the safety net works: `rclone sync` makes the remote match the local
directory, which includes deleting remote files deleted locally.
`--backup-dir` intercepts every overwritten or deleted remote file and moves
it into the dated folder instead of destroying it. Every push is reversible;
`_backups` accumulates dated folders you prune periodically.

### scripts/sync-pull.sh

```bash
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
```

Deliberate asymmetry: **the pull has no --backup-dir**. If you run pull
having forgotten to push local changes first, the remote wins and the local
unpushed work is destroyed. That is harsh on purpose — see Discipline below.

### Make Them Executable

```bash
chmod +x scripts/sync-push.sh scripts/sync-pull.sh
```

## Discipline (The Part That Actually Matters)

The scripts are trivial; the protocol is the product:

- **Push after every work session.** End of day, minimum. Unsynced local
  work violates the entire architecture.
- **Pull before the first edit of the day** on any machine, and always
  before editing on a device other than the one last pushed from.
- **One machine active at a time.** Never edit the same file on two devices
  between pushes.
- **The remote is a mirror, not a workspace.**

### Recovering an Overwrite

Deleted or clobbered a file and pushed? Find it in the dated backups:

```bash
rclone ls protondrive:_backups --max-depth 1
rclone copyto "protondrive:_backups/2026-10-21_101530/proposal.docx" \
  ~/Work/Projects/proposal.docx
```

### Pruning Old Backups

Safety nets accumulate and count against Drive quota. Once a month:

```bash
rclone delete protondrive:_backups --min-age 90d --rmdirs
```

## Troubleshooting

These failures occurred during setup of this project; the resolutions are
field-tested.

### `couldn't generate 2FA code: Decoding of secret as base32 failed`

The stored OTP seed is invalid — a placeholder, truncation, or a paste
contaminated with quotes or trailing characters. Re
