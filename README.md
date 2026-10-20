# Linux Workflow Automation

A documented, security-first migration of a production workstation from
Windows to Linux — including full-disk encryption, encrypted cloud
synchronization, secrets management, and a local-first document workflow.

## Why This Exists

This project replaced a Windows workstation with a hardened Linux setup
built around three principles: local-first document editing, encrypted
sync to cloud storage, and no secrets ever living in plaintext files.
Every decision and failure mode is documented in `docs/` so the design
can be audited — including the tradeoffs that ruled out the "obvious"
approaches (live filesystem mounts and bidirectional sync).

## Architecture at a Glance

- **Foundation:** Linux Mint with LUKS full-disk encryption (root + data)
- **Documents:** OnlyOffice (OOXML-native) with LibreOffice fallback,
  edited locally, pushed on demand
- **Sync:** rclone one-way push to Proton Drive with dated `--backup-dir`
  safety net; local HDD snapshots as a second layer
- **Secrets:** KeePassXC vault exposed via the Freedesktop Secret Service
  API; scripts retrieve credentials at runtime with `secret-tool`
- **Collaboration:** .docx/.xlsx with Office users; Proton-native
  in-browser editing when true co-editing is needed

See `docs/00-architecture-overview.md` for the full design rationale.

## Repository Contents

| Path | Description |
|------|-------------|
| `docs/` | Full technical runbook, chaptered by component |
| `scripts/` | Sync, pull, and mount scripts referenced by the runbook |

## Status

Work in progress — chapters are published as they're finalized.
See the commit history for the current state.# linux-workflow-automation
Documenting conversion of Windows PC to Linux and creating helpful home automation projects.
