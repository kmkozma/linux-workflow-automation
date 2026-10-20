# Document Workflow

## Purpose

This chapter documents the document editing stack for the workstation — what
editor, what file format, what autosave and sync discipline keeps work safe
across the rclone push/pull cycle.

The guiding rule: **never rely on bidirectional cloud sync for active editing**.
If you need to edit on multiple devices, use the pull-before-edit, push-after
protocol. That protocol works regardless of the editor; the rest of this chapter
is about picking the right editor for the job.

## Editor Choice: OnlyOffice

OnlyOffice Desktop Editors is the default choice for all .docx and .xlsx files.
LibreOffice is the fallback for legacy or exotic formats.

### Why OnlyOffice Over LibreOffice?

| Criteria | OnlyOffice | LibreOffice | Verdict |
|----------|------------|-------------|---------|
| Native OOXML rendering | High — .docx is its native format | Medium — imports/export but loses complex formatting | OnlyOffice wins for collaborative .docx |
| Collaboration with MS Office users | Preserves layout, fonts, tables | Occasional reflow, style drift | OnlyOffice wins |
| LibreOffice compatibility | Reads .odt fine | N/A | Tie |
| Legacy format support (.dot, .xls) | Limited | Excellent | LibreOffice wins |
| Install footprint | Light (~1GB) | Larger (~2GB) | Slight edge to OnlyOffice |
| Linux maturity | Good, actively maintained | Mature, very stable | Both acceptable |

The deciding factor is collaboration. Most of your collaborators still live in
Microsoft Office. When you send a .docx back and forth, you want the recipient's
document to look like yours. OnlyOffice minimizes fidelity loss; LibreOffice
sometimes introduces subtle reflows that require manual fixes.

### Installing OnlyOffice

```bash
sudo apt install onlyoffice-desktopeditors
