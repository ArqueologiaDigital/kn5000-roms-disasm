# Probe: llvm-mc spelling for the unidasm form `ld r,N` (KN5000 v7 ROM)

Staged OUTSIDE the disasm repo because a converter held the repo lock when these
were produced. **These belong in the repo** (suggested: `tools/spelling-probes/`).

| script | question it answers | command |
|---|---|---|
| `verify_ld_r_N_full.py` | Does the proposed spelling rule assemble byte-exactly at **every** `ld r,N` site in the v7 ROM? | `python3 verify_ld_r_N_full.py` |
| `verify_ld_r_0.py` | Same, restricted to the 2-byte prefix forms (earlier/narrower pass). | `python3 verify_ld_r_0.py` |
| `blob_forms.py` | Which `ld r,N` sites still sit inside un-converted `.byte` blobs in `v7/maincpu`, and in which file? | `python3 blob_forms.py` |

Signal read: the raw ROM bytes at each address (`original_ROMs/kn5000_v7_program.rom`,
load base 0xE00000). PASS = `llvm-mc -triple=tlcs900 --show-encoding` output equals
those bytes. "Assembled without error" is NOT a pass.

Result 2026-08-22: 12088 / 12089 sites byte-exact. The single failure, `ld SP,7` at
0xE0ADE4, is a spurious linear decode inside a 32-bit pointer table
(0xE0ADD0.. holds `d0 af e0 00, d3 af e0 00, ...`) — not real code. There are **zero**
real `ld SP,N` instructions; the assembler rejects `lds sp, N` because GR16 excludes SP.
