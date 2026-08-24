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

**Converted to real assembly so far** (everything else is still `.incbin`, so it
builds byte-exact by construction and asserts nothing):

| where | bytes | what |
|---|---|---|
| `prom_a` 0xF826A9-0xF827C7 | 287 | `RESET` — the entire CPU 1 boot path, from the watchdog disarm to the jump into prom_b |
| `prom_a` 0xFFFF00-0xFFFFFF | 256 | interrupt vector table (33 entries), RET padding, build tag |
| `prom_c` 0xFFF000-0xFFF0E4 | 229 | `RESET` plus the interrupt trampoline block |
| `prom_c` 0xFFF0E5-0xFFFFFF | 3867 | RET padding, vector table, the fc configuration byte, build tag — i.e. the whole 4 KiB tail |

4639 bytes of 2 MiB. Small, but it is the part every other claim hangs off: the
memory map and the system clock are both read out of these two blocks.

`include/tmp95c061_sfr.inc` holds the register equates, each with the MAME line
that names it and, where a field meaning is asserted at all, where that meaning
comes from.

`prom_b` and `prom_d` are still one `.incbin` each. prom_b's obvious next slice
is its 3388-slot linker thunk region at file 0x40000-0x434F4, where every entry
is self-checking against the routine it names.

## What is established, and what is not

Two findings documents, both written to be checkable rather than believed:

* **`notes/FINDINGS-memory-map.md`** — both processors' maps, with the ROM
  address of every establishing write, and an explicit list of every range that
  is *not* established. The window sizes are no longer imported from the sibling
  project's self-graded-unproven reconstruction: they come from
  `scripts/analysis/mamr_reading_elimination.py`, which enumerates eight
  candidate readings of MSAR/MAMR and kills six of them using this machine's own
  firmware. What survives: 32 KB per MAMR unit, higher-numbered chip select
  wins. What is still open: whether MSAR's base is truncated to the window,
  which changes exactly one row (CPU 1's CS0).
* **`notes/FINDINGS-system-clock.md`** — `fc = 28,000,000 Hz`, from three
  levers of unequal strength. The strongest is that prom_c's byte at `0xFFFFEF`
  is fc in MHz: the firmware's own baud rule makes 31250 come out for *any*
  value of it provided `fc = 1e6 x M`, and it is 0x1C. The tolerance window and
  the second independent estimate (the sequencer's `5*fc = 140,000,000`) are
  both in there, along with why the MIDI divisor alone cannot choose between
  28 MHz and the 24 MHz oscillator that is also in this machine's parts list.

`notes/system-clock.md` is superseded and says so.

Territory is converted incrementally, gate green at every step.
