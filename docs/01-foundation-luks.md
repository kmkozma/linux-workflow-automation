# Foundation: LUKS Full-Disk Encryption

## Purpose

This chapter documents the LUKS full-disk encryption layer — the foundation
of the entire security posture. It includes the installation and verification
steps, plus the failure mode that shaped the entire project: the first
migration shipped without LUKS and was subsequently wiped and redone.

## The Lesson Up Front

The first migration of this workstation completed successfully — only to be
wiped and redone weeks later when it became clear that full-disk encryption
was not optional. Retrofitting LUKS onto an existing installation is not
cleanly possible; the correct path is to encrypt from scratch or accept the
risk. The cost of that lesson was a full reinstall. The benefit: the
architecture now matches the threat model.

Rule: **LUKS before daily driving, never after.**

## Threat Model

| Attack Vector | What LUKS Protects Against |
|---------------|----------------------------|
| Physical theft | Immediate: drive removed from machine = unreadable |
| Drive disposal | Data unrecoverable without passphrase |
| Unauthorized imaging | Bit-for-bit copies remain ciphertext |
| Cold-boot attacks | Mitigated by suspending/shutting down before physical access |

It does not protect against:

- Online compromise while the system is unlocked
- Malicious actors with physical access and time to brute-force the passphrase
- Social engineering for the passphrase itself

Those threats are outside the scope of this architecture. LUKS addresses
offline attacks — disk removal, imaging, disposal. That's the threat model
it was built for.

## The First Migration (What Went Wrong)

In June 2025, the evaluation phase produced a working Linux desktop. The
priority was getting a usable replacement for Windows — stable apps,
functional hardware, acceptable performance. LUKS was recognized as the
right long-term choice, but deferred to "later."

Later arrived when the same workstation was in use for weeks. The realization
hit: an unencrypted NVMe is not a production machine. The only correct action
was to back up personal data and redo the installation with LUKS enabled
from the start. The cost: reinstalling applications, reconfiguring tooling,
and re-deriving muscle memory for the new stack.

The takeaway: security decisions deferred until after daily-driving begin
cost more in time than they did in planning. This is why the second
installation — the one documented here — had LUKS as requirement #1.

## Installation (Second Migration)

The second migration began with the Linux Mint installer. LUKS was enabled
during partition setup:

1. Boot the installer USB
2. Proceed to "Installation Type"
3. Select "Erase disk and install Linux Mint" — but check the checkbox for
   **Encrypt the new Linux installation** (this triggers LUKS)
4. Set the passphrase — strong, memorized, physically recorded
5. Continue with installation as normal

The installer handles the crypto-layer setup transparently. The resulting
partition structure is:

- `crypto_LUKS` root filesystem
- EFI boot partition (unencrypted, small)
- Swap (encrypted via the LUKS layer, if configured)

### Passphrase Selection

Choose a passphrase you can memorize, but not guess. Length beats complexity;
three random words separated by spaces is stronger than eight-character
random passwords, and easier to type repeatedly. Write it down on paper
once and store it in a secure physical location. The computer will not
let you recover it.

## Verification

After reboot, verify the encryption layer is active:

```bash
cryptsetup luksDump /dev/nvme0n1p3
```

(Adjust the device name to your system — use `lsblk` or `fdisk -l` to find it.)

The output shows:

- Cipher: aes
- Key size: 256 bits (or 512, both acceptable)
- Hash: sha256
- LUKS version: 2

If it fails or reports no encryption, the install skipped the checkbox or
used a different partition scheme. Reboot into the installer and redo.

### Confirm Mount Point Encryption

```bash
df -hT /
```

Check that the filesystem shows the underlying encrypted mapping. The exact
output varies by distribution, but the key is that `/` mounts from a
`/dev/mapper/*` path rather than directly from the device.

### Boot Behavior Test

Shutdown, wait 10 seconds, power on. The pre-boot prompt should appear asking
for the LUKS passphrase before loading the desktop. This is the primary
defense: without it, the machine won't boot into an unlocked state.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Lost passphrase | Total data loss | Memorization + physical paper copy |
| Weak passphrase | Brute-force feasible | Use long passphrases (3+ random words) |
| Firmware bugs | Rare, but possible | Keep kernel/distro current |
| Cold-boot attack | RAM retains key briefly | Suspend or shut down before handing off machine |
| Key escrow requirements | Institutional demands | Not addressed — out of scope |

## Recovery

Keep a bootable Linux USB handy. If the LUKS container becomes corrupted,
you may be able to repair it with `cryptsetup repair` or `fsck`. If the
passphrase is lost, the data is unrecoverable — LUKS is designed to prevent
any other path.
