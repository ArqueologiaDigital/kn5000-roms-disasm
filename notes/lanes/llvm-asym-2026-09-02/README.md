# llvm-asym lane, 2026-09-02 — decode/encode asymmetry: verdicts and population

Every number in `../llvm-asym-2026-09-02.md` came from one of these files, and
every file came from one of these commands. All three probes carry a
`--selftest` whose controls are synthetic, so they cannot go red merely because
a backend fix removed the case they name.

| file | question it answers | command |
|---|---|---|
| `sweep-e816cddb6e2d.txt` | Of every REAL instruction in the 13 committed images, how many does llvm-objdump print as a text that re-encodes to different bytes (ASYM), or consume the wrong number of bytes for (LENGTH)? | `python3 scripts/analysis/decode_encode_asymmetry_sweep.py --verbose` |
| `subopcode-cross-check-e816cddb6e2d.txt` | For each of 23 prefix tables, which of the 256 sub-opcodes does this backend read differently from MAME's unidasm, and which does it print a text for that re-encodes to different bytes? | `python3 scripts/analysis/decoder_subopcode_cross_check.py` |
| `branch-displacement-audit-before.txt` | Which JR/JRL/CALR/DJNZ operands in the tree do not fit the displacement field they are written into — and is each a sign-extended displacement or a target address? | `python3 scripts/analysis/branch_displacement_field_audit.py` |

**Signal read.** The sweep takes its instruction boundaries from
`llvm-mc --show-encoding` over the tree's own sources, so every probe is a real
instruction at a real boundary and its bytes are the ROM's — that is what
`make gate-all` certifies. PASS for one instruction = the text llvm-objdump
prints for its bytes assembles back to exactly those bytes.

⚠ **These numbers are properties of the DECODER as much as of the bytes.** The
toolchain commit is printed at the top of each file and is part of the result;
the same tree gave 4-of-5 asymmetric at `6f456a19f05b` and 0-of-5 at
`e816cddb6e2d` with not one source byte changed.
