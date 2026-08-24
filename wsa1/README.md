# Technics SX-WSA1R ROM disassembly

Sibling of `../kn5000-roms-disasm`, same practices.

## What certifies this tree

**Only one thing: reassembling the sources reproduces the original ROMs byte for byte.**

    python3 scripts/analysis/assert_byte_identical.py

That script rebuilds first and compares bytes. Do not substitute a similarity
percentage, and do not run it with `--no-build` unless you have just built --
both shortcuts have already cost the sibling tree real retractions, and the
reasons are written into the script's docstring.

Every commit must keep the gate green, and every commit message must carry the
`LLVM: <branch>@<short> (<full>)` line (enforced by `.githooks/commit-msg`).

## The four images

| source | file | base | status |
|---|---|---|---|
| `prom_a/` | `wsa1_prom_a.ic12` | `0xF80000` | program, boot image of CPU 1 |
| `prom_b/` | `wsa1_prom_b.ic13` | `0xF00000` (inferred) | program, same bus as A |
| `prom_c/` | `wsa1_prom_c.ic28` | `0xF80000` | program, boot image of CPU 2 |
| `prom_d/` | `wsa1_prom_d.bin` | unknown | data only |

Base addresses for A and C are **established**: 33 of 64 words at file offset
`0x7FF00` point into `0xF00000-0xFFFFFF`, which is where a TMP95C061 fetches its
reset PC (`0xFFFF00`). B lands 3 of 64 there and D lands 0, so neither is a boot
image. Evidence: `../technics_roms/tools/wsa1_rom_anatomy.py`.

`prom_d`'s ORIGIN of 0 in its linker script is a build convenience and asserts
nothing about where the device sits.

## Provenance of the images

These are **not chip reads**. They are the publicly redistributed v2 firmware
set; see `../technics_roms/roms/wsa1/PROVENANCE.md`. That does not affect the
byte-match discipline here -- the bytes are what they are -- but it must not be
misreported downstream.

## Status

Bootstrap. Each ROM is still a single `.incbin`, so the gate passes by
construction and nothing in the sources is yet a claim about contents.
Territory is converted incrementally, gate green at every step.
