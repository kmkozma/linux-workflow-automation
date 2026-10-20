# Lumo Integration

## Purpose

This chapter documents where the AI assistant fits in the workstation stack,
what it is and isn't used for, and the conventions that keep AI-assisted output
consistent across sessions. The design keeps Lumo as a **generation and
reasoning tool**, never a storage location or document editor.

## What Lumo Is

Lumo is Proton's AI assistant. The relevant properties for this workflow:

- **Zero-access encryption** — chats, uploaded files, and generated images are
  stored so that not even Proton can access them; Lumo does not use chat data
  to train AI models
- **Multi-model routing** — different specialized models handle different task
  types (reasoning, writing, code, image generation, web search), routed
  automatically
- **Projects** — persistent, encrypted workspaces bundling chats, files, and
  requirements for a recurring subject; Projects integrate with Proton Drive so
  linked files stay end-to-end encrypted
- **Memory** — opt-in long-term memory of preferences and working style across
  conversations; disabled by default

The privacy posture is why it's in the stack at all. Document drafting involves
sensitive professional material — resumes, cover letters, consulting work — and
that content goes to an AI provider's servers by necessity. Zero-access
encryption and no-training-use commitments bound that exposure to a level
consistent with the rest of this architecture.

## What Lumo Is Used For (and Not)

| Task | Lumo? | Rationale |
|------|-------|-----------|
| Drafting text (resumes, letters, docs) | Yes | Generation tool; output lands in ~/Work/Drafts/ |
| Refining/reviewing existing documents | Yes | Paste-in review passes |
| Technical reasoning, plan validation | Yes | Multi-perspective critique before committing to work |
| Editing .docx/.xlsx files | No | Not a document editor; output goes to OnlyOffice |
| Storing documents | No | Files live locally on LUKS NVMe; Lumo sees them transiently |
| Web research with citations | Yes | Deep web search with source citation |
| Permanent record of decisions | No | The runbook (this repo) is the record; chats are disposable |

The core rule: **local-first applies to AI too.** Lumo output is treated as
draft material to be saved to the workstation and reviewed — never as the
authoritative copy of anything.

## Standing Conventions: lumo-brief.md

Consistency across sessions comes from a conventions file rather than
re-explaining preferences each time. The working file lives at
`~/Work/lumo-brief.md` (kept local — it accumulates personal context and
does not belong in a public repo). Its shape:

    # Lumo Session Conventions

    - Output format: markdown for technical content, .docx for deliverables
    - Tone: direct, concise, no fluff
    - Reality checks: verify facts before stating them; flag uncertainty
      explicitly; no cherry-picked statistics
    - Clarify: ask questions when requirements are ambiguous
    - Iteration: first pass is a draft; refine with targeted feedback

Adapting this pattern for your own setup: keep the file short enough to paste
into a session in one shot, review it quarterly, and keep personal or client-
identifying detail out of anything published.

## Session Workflow

1. Start a session (or a Project, for recurring workstreams)
2. Paste current conventions if the session lacks context
3. Draft — markdown output, saved to ~/Work/Drafts/
4. Convert to deliverable in OnlyOffice with proper template/styling
5. Push via rclone per the sync discipline

### When to Use Projects

Projects (persistent workspaces bundled with chats and files) suit recurring
subjects — an ongoing job search, a consulting engagement, a long-running
documentation effort like this one. One-off drafting tasks don't need the
overhead. Project-linked files come from Proton Drive, so the encryption
boundary extends to the attached material.

### Memory Setting

Memory is disabled by default and that's the correct posture for this
workflow: conventions belong in lumo-brief.md (portable, reviewable,
version-controllable in spirit) rather than in opaque model-side state.
Enable it only if session-to-session recall of preferences proves more
valuable than the transparency of the file-based approach.

## Privacy Boundary Summary

| Layer | Exposure |
|-------|----------|
| Prompt content | Goes to Proton servers (necessarily); zero-access encrypted at rest |
| Uploaded files | Same boundary; never used for training |
| Final documents | Never stored in Lumo; canonical copies local + Proton Drive |
| Conventions file | Local only; contains preferences, not secrets |

No secrets ever enter a Lumo session — passwords, tokens, and keys stay in
GNOME Keyring and never pass through a prompt.
