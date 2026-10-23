# Linux Workflow Automation

A documented, security-first migration of a production workstation from
Windows to Linux — including full-disk encryption, encrypted cloud
synchronization, secrets management, and a local-first document workflow.

## Why This Exists

This project began in June 2026 as an evaluation of hardened Linux options for
a production Windows workstation. The guiding principles: local-first document
editing, encrypted sync to cloud storage, and no secrets ever living in
plaintext files. Every decision and failure mode is documented in `docs/`
so the design can be audited.

The first migration shipped without full-disk encryption and was subsequently
wiped and redone correctly once the LUKS requirement was recognized — a
failure documented in `docs/01-foundation-luks.md`. This is technically the
second migration, and that lesson shapes the entire architecture.

## Architecture at a Glance

- **Foundation:** Linux Mint with LUKS full-disk encryption
- **Documents:** OnlyOffice (OOXML-native) with LibreOffice fallback,
  edited locally, pushed on demand
- **Sync:** rclone one-way push to Proton Drive with dated `--backup-dir`
  safety net (community-implemented backend; occasionally requires
  manual re-authentication)
- **Secrets:** GNOME Keyring (Secret Service API); scripts retrieve
  credentials at runtime with `secret-tool`
- **Collaboration:** .docx/.xlsx with Office users; Proton-native
  in-browser editing when true co-editing is needed

See `docs/00-architecture-overview.md` for the full design rationale.

## Repository Contents

| Path | Description |
|------|-------------|
| `~/Work/` | Canonical local work tree — the only directory synced |
| `docs/` | Runbook chapters, one per component |
| `scripts/` | Sync, pull, and mount scripts referenced by the runbook |


## Status

Work in progress — chapters are published as they're finalized.
See the commit history for the current state.
