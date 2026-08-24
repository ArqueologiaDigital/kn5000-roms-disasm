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
| `prom_a/` | `wsa1_prom_a.ic12` | `0xF80000` **established** | program, boot image of CPU 1 |
| `prom_b/` | `wsa1_prom_b.ic13` | `0xF00000` **confirmed** | program, low half of the same 1 MiB image |
| `prom_c/` | `wsa1_prom_c.ic28` | `0xF80000` **established** | program, boot image of CPU 2 |
| `prom_d/` | `wsa1_prom_d.bin` | **not established** | data only |

Base addresses for A and C: 33 of 64 words at file offset `0x7FF00` point into
`0xF00000-0xFFFFFF`, which is where a TMP95C061 fetches its reset PC
(`0xFFFF00`), and both reset words land on real boot blocks — now converted to
assembly. B lands 3 of 64 there and D lands 0, so neither is a boot image.
Evidence: `../technics_roms/tools/wsa1_rom_anatomy.py`.

**B's base is no longer inferred.** Four independent proofs — prom_a's vectors,
its reset path's jump, a PC-relative call across the boundary, and the
expansion-board probe's thunk — all land on well-formed code at exactly
`0xF00000`, and none survives a one-byte error in it. Written out in
`prom_b/prom_b.ld`.

**D's base is still not established.** It is *strongly supported* as an image of
the 512 KiB flash at `0xE80000` on CPU 2's bus (exact size match to the flash the
sector-erase routine proves, erased-flash tail, 0-based offset header, no
absolute pointers) but no byte-level tie to an instruction exists yet, so its
linker `ORIGIN` stays 0 as a build convenience. Argument and its hole:
`prom_d/prom_d.ld`.

## Provenance of the images

These are **not chip reads**. They are the publicly redistributed v2 firmware
set; see `../technics_roms/roms/wsa1/PROVENANCE.md`. That does not affect the
byte-match discipline here -- the bytes are what they are -- but it must not be
misreported downstream.

## Status

**Converted: 604,523 of 2,097,152 bytes (28.8%).** Regenerate this table with
`python3 scripts/analysis/source_coverage.py` -- do not retype it; it has been wrong before.

| source | image | converted | still `.incbin` | `.incbin` spans |
|---|---|---:|---:|---:|
| `prom_a/` | `wsa1_prom_a.ic12` | 4,278 | 520,010 | 14 |
| `prom_b/` | `wsa1_prom_b.ic13` | 59,586 | 464,702 | 136 |
| `prom_c/` | `wsa1_prom_c.ic28` | 16,371 | 507,917 | 12 |
| `prom_d/` | `wsa1_prom_d.bin` | 524,288 | 0 | 0 |

The gate is green at every commit; see the top of this file. Conversion is incremental and
reachability-driven, not linear, so a low percentage on an image does not mean nothing is
known about it -- `notes/` carries the structural findings.

⚠ This section was stale for one commit (it still claimed 4,639 bytes and "prom_b and
prom_d are still one .incbin each" after four agents had converted 604,523 bytes). Three of
the four lanes noticed and none edited it, because it was outside every lane. Hence the
script: the number is now derived from the sources, not maintained by hand.
