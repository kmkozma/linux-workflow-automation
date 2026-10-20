# Architecture Overview

## Purpose

This project replaces a production Windows workstation with a hardened Linux
environment designed around three principles:

1. **Local-first document editing** — edit files on the NVMe; sync to cloud on demand
2. **Encrypted cloud synchronization** — rclone push to Proton Drive with dated
   `--backup-dir` safety net
3. **No secrets in plaintext files** — credentials live only inside the system
   secret service (GNOME Keyring), accessed via `secret-tool` at runtime

Every design decision documented here was chosen because it satisfies one of these
three rules without violating another. The "obvious" alternatives — live-editing
on a FUSE mount, bidirectional sync, secrets in dotfiles — were rejected for
specific reasons that are spelled out in their respective chapters.

## Design Decisions That Were Made (And Why)

| Decision | Alternative Rejected | Reason |
|----------|---------------------|--------|
| Local-first, scripted push | Live-edit on rclone FUSE mount | rclone's Proton backend has no event system; concurrent clients cause stale-cache corruption and conflicts. See `docs/03-cloud-sync-rclone.md`. |
| One-way sync with `--backup-dir` | Bidirectional sync (bisync) | Bisync is fragile; user reports show conflict pileups. Last-pusher-wins with dated trash folders is simpler and auditable. See `docs/03-cloud-sync-rclone.md`. |
| GNOME Keyring (Secret Service) | KeePassXC, plaintext dotfiles, Bitwarden | Single system secret service owning the D-Bus interface; unlocks at login matching the automation boundary; scripts retrieve secrets at runtime via `secret-tool`. No extra vault to manage alongside ProtonPass. |
| OnlyOffice (.docx native) | LibreOffice, VS Code, Markdown-only | OnlyOffice's native OOXML handling eliminates round-trip conversion fidelity loss when collaborating with MS Office users. LibreOffice kept as fallback for legacy/exotic files. See `docs/04-document-workflow.md`. |
| LUKS full-disk encryption | File-level encryption, no encryption | Foundational trust: disk wipe or theft = data lost, not exposed. LUKS is battle-tested; no performance penalty on NVMe. |

## Directory Layout

- `~/Work/` — canonical working tree
  - `Projects/` — canonical .docx/.xlsx, live-edited in OnlyOffice
  - `Drafts/` — Lumo-generated markdown/text
  - `lumo-brief.md` — standing conventions for Lumo sessions
- `protondrive:/Work/` — mirror of `~/Work/` (pushed via rclone --backup-dir)

**Note:** `~/Vault/` was removed. The project now relies on GNOME Keyring for
automation secrets and ProtonPass for personal passwords — no separate vault
directory required.

## Data Flow

**Push path:** OnlyOffice edit → ~/Work/ → (manual or cron) rclone push → protondrive:/Work/ → (parallel) HDD snapshots

**Pull path:** reverse — pull before editing on another device (MacBook), push again after. Never leave unsynced work on either machine before switching.

## Security Boundaries

| Layer | Protection |
|-------|------------|
| Physical theft | LUKS full-disk encryption (NVMe) |
| Cloud breach | rclone encrypts at client side before upload; Proton zero-knowledge |
| Local compromise | Secrets never in dotfiles; retrieved via secret-service at runtime |
| Sync accident | `--backup-dir` dated trash folders + HDD snapshots |

## Chapter Index

| Chapter | Description | Status |
|---------|-------------|--------|
| `00-architecture-overview.md` | This document | Complete |
| `01-foundation-luks.md` | LUKS installation and verification | Pending |
| `02-secrets-management.md` | GNOME Keyring, Secret Service, SSH agent integration | Pending |
| `03-cloud-sync-rclone.md` | rclone configuration, push/pull scripts, --backup-dir safety | Pending |
| `04-document-workflow.md` | OnlyOffice, LibreOffice fallback, autosave discipline | Pending |
| `05-lumo-integration.md` | What Lumo is, what it does and doesn't do, custom persona setup | Pending |
| `06-multi-device-discipline.md` | Desktop + MacBook turn-taking protocol | Pending |

## Status

Work in progress — chapters are published as they're finalized. See the commit
history for the current state.

---

## Revision Notes

These notes document changes from an earlier draft of this chapter. Readers who
care only about the final state can skip this section.

### Secret Service Stack (Changed)

Earlier draft proposed KeePassXC + Secret Service as the secrets hub. That
decision was revisited: KeePassXC was purged, GNOME Keyring retained as the sole
system secret service (the D-Bus interface owner). Automation secrets now live
in GNOME Keyring; personal passwords remain in ProtonPass. No separate vault
directory (`~/Vault/`) exists.

### Why This Changes Nothing for Scripts

The `secret-tool` retrieval pattern works identically against any Secret Service
daemon — GNOME Keyring or KeePassXC. Scripts don't care which backend owns the
interface. This is purely a simplification: fewer moving parts, fewer daemons to
configure, no vault file to manage separately.

### Removed References

- All mentions of KeePassXC as an SSH agent
- All mentions of a `~/Vault/vault.kdbx` path in directory layout
- All KeePassXC-specific configuration steps

These remain only as history in the commit log if needed for reference.
# Architecture Overview

## Purpose

This project replaces a production Windows workstation with a hardened Linux
environment designed around three principles:

1. **Local-first document editing** — edit files on the NVMe; sync to cloud on demand
2. **Encrypted cloud synchronization** — rclone push to Proton Drive with dated
   `--backup-dir` safety net
3. **No secrets in plaintext files** — credentials live only inside the system
   secret service (GNOME Keyring), accessed via `secret-tool` at runtime

Every design decision documented here was chosen because it satisfies one of these
three rules without violating another. The "obvious" alternatives — live-editing
on a FUSE mount, bidirectional sync, secrets in dotfiles — were rejected for
specific reasons that are spelled out in their respective chapters.

## Design Decisions That Were Made (And Why)

| Decision | Alternative Rejected | Reason |
|----------|---------------------|--------|
| Local-first, scripted push | Live-edit on rclone FUSE mount | rclone's Proton backend has no event system; concurrent clients cause stale-cache corruption and conflicts. See `docs/03-cloud-sync-rclone.md`. |
| One-way sync with `--backup-dir` | Bidirectional sync (bisync) | Bisync is fragile; user reports show conflict pileups. Last-pusher-wins with dated trash folders is simpler and auditable. See `docs/03-cloud-sync-rclone.md`. |
| GNOME Keyring (Secret Service) | KeePassXC, plaintext dotfiles, Bitwarden | Single system secret service owning the D-Bus interface; unlocks at login matching the automation boundary; scripts retrieve secrets at runtime via `secret-tool`. No extra vault to manage alongside ProtonPass. |
| OnlyOffice (.docx native) | LibreOffice, VS Code, Markdown-only | OnlyOffice's native OOXML handling eliminates round-trip conversion fidelity loss when collaborating with MS Office users. LibreOffice kept as fallback for legacy/exotic files. See `docs/04-document-workflow.md`. |
| LUKS full-disk encryption | File-level encryption, no encryption | Foundational trust: disk wipe or theft = data lost, not exposed. LUKS is battle-tested; no performance penalty on NVMe. |

## Directory Layout

- `~/Work/` — canonical working tree
  - `Projects/` — canonical .docx/.xlsx, live-edited in OnlyOffice
  - `Drafts/` — Lumo-generated markdown/text
  - `lumo-brief.md` — standing conventions for Lumo sessions
- `protondrive:/Work/` — mirror of `~/Work/` (pushed via rclone --backup-dir)

**Note:** `~/Vault/` was removed. The project now relies on GNOME Keyring for
automation secrets and ProtonPass for personal passwords — no separate vault
directory required.

## Data Flow

**Push path:** OnlyOffice edit → ~/Work/ → (manual or cron) rclone push → protondrive:/Work/ → (parallel) HDD snapshots

**Pull path:** reverse — pull before editing on another device (MacBook), push again after. Never leave unsynced work on either machine before switching.

## Security Boundaries

| Layer | Protection |
|-------|------------|
| Physical theft | LUKS full-disk encryption (NVMe) |
| Cloud breach | rclone encrypts at client side before upload; Proton zero-knowledge |
| Local compromise | Secrets never in dotfiles; retrieved via secret-service at runtime |
| Sync accident | `--backup-dir` dated trash folders + HDD snapshots |

## Chapter Index

| Chapter | Description | Status |
|---------|-------------|--------|
| `00-architecture-overview.md` | This document | Complete |
| `01-foundation-luks.md` | LUKS installation and verification | Pending |
| `02-secrets-management.md` | GNOME Keyring, Secret Service, SSH agent integration | Pending |
| `03-cloud-sync-rclone.md` | rclone configuration, push/pull scripts, --backup-dir safety | Pending |
| `04-document-workflow.md` | OnlyOffice, LibreOffice fallback, autosave discipline | Pending |
| `05-lumo-integration.md` | What Lumo is, what it does and doesn't do, custom persona setup | Pending |
| `06-multi-device-discipline.md` | Desktop + MacBook turn-taking protocol | Pending |

## Status

Work in progress — chapters are published as they're finalized. See the commit
history for the current state.

---

## Revision Notes

These notes document changes from an earlier draft of this chapter. Readers who
care only about the final state can skip this section.

### Secret Service Stack (Changed)

Earlier draft proposed KeePassXC + Secret Service as the secrets hub. That
decision was revisited: KeePassXC was purged, GNOME Keyring retained as the sole
system secret service (the D-Bus interface owner). Automation secrets now live
in GNOME Keyring; personal passwords remain in ProtonPass. No separate vault
directory (`~/Vault/`) exists.

### Why This Changes Nothing for Scripts

The `secret-tool` retrieval pattern works identically against any Secret Service
daemon — GNOME Keyring or KeePassXC. Scripts don't care which backend owns the
interface. This is purely a simplification: fewer moving parts, fewer daemons to
configure, no vault file to manage separately.

### Removed References

- All mentions of KeePassXC as an SSH agent
- All mentions of a `~/Vault/vault.kdbx` path in directory layout
- All KeePassXC-specific configuration steps

These remain only as history in the commit log if needed for reference.
