# Probe: llvm-mc spelling for the unidasm forms `ld (imm),(imm)` and `ldw (imm),(imm)`

The TLCS-900 memory-to-memory move prints as two parenthesised addresses and
nothing else. The printed text therefore drops **three** independent facts that
each choose a different encoding:

* the operand **width** — byte or word (`ld` vs `ldw` is unidasm's only hint and
  it is not enough on its own, because the same width appears with three
  different address widths);
* **which side the leading prefix addresses** — the `sd*` half of the family
  puts the SOURCE in the prefix and uses sub-opcode `0x19`, the `dd24` half puts
  the DESTINATION there and uses `0x14`/`0x16`;
* **how wide that prefix address is** — 8, 16 or 24 bits.

Reasoning from the mnemonic cannot recover any of them. So the rule offers the
whole family and lets the ROM bytes choose, exactly like the `cp`/`inc` families
already in `convert_corroborated_blocks.translate()`.

| script | question it answers | command |
|---|---|---|
| `verify_ldmm_memtomem.py` | Is the family rule byte-exact at every printed site in v7/v9/v10, and does exactly ONE member match (negative control)? | `python3 tools/spelling-probes/verify_ldmm_memtomem.py original_ROMs/kn5000_v{7,9,10}_program.rom` |
| `blocking_ldmm_and_ldsp.py` | Which sites actually block `convert_reachable_ranges.py`, with what bytes, and how many bytes would the rule release? | `python3 tools/spelling-probes/blocking_ldmm_and_ldsp.py --marginal` |

Signal read: the raw ROM bytes at each address (program ROMs load at 0xE00000).
PASS = `llvm-mc -triple=tlcs900 --show-encoding` emits exactly those bytes.
"Assembled without error" is NOT a pass.

## The rule

Printed operand order is **DST, SRC**. `D`/`S` are the two printed addresses;
`d0 d1 d2` / `s0 s1 s2` are their little-endian bytes.

    ldmm8      D, S            C1 + S16 + 19 + D16     byte, 16-bit source addr
    ldmm16     D, S            D1 + S16 + 19 + D16     word, 16-bit source addr
    ldmm_sd24b s0,s1,s2,d0,d1  C2 + S24 + 19 + D16     byte, 24-bit source addr
    ldmm_sd24w s0,s1,s2,d0,d1  D2 + S24 + 19 + D16     word, 24-bit source addr
    ldmm_sd8b  s0,d0,d1        C0 + S8  + 19 + D16     byte, 8-bit source addr
    ldmmb_dd24 d0,d1,d2,s0,s1  F2 + D24 + 14 + S16     byte, 24-bit dest addr
    ldmmw_dd24 d0,d1,d2,s0,s1  F2 + D24 + 16 + S16     word, 24-bit dest addr

All seven defs already exist in `TLCS900InstrInfo.td` (lines 3406, 3412, 5181,
5189, 5145, 4177, 4182). **No backend work is required** — this is cause (a), a
spelling nobody had tried. What is missing is the rule in
`scripts/converters/convert_corroborated_blocks.translate()`, which today yields
nothing that matches for either form.

## Measured, 2026-08-23

| ROM | printed sites | byte-exact | unmatched | negative-control collisions |
|---|---|---|---|---|
| v7 | 630 | 621 | 9 | 0 |
| v9 | 628 | 621 | 7 | 0 |
| v10 | 628 | 621 | 7 | 0 |

Chosen member, per site, identical in all three images: `ldmm16` 397,
`ldmm8` 183, `ldmmw_dd24` 14, `ldmm_sd24w` 12, `ldmmb_dd24` 10, `ldmm_sd24b` 5.

**Zero negative-control collisions** — at every site exactly one family member
reproduces the bytes, so byte-selection is not arbitrary between members.

## Blocking sites in the v7 reachable ranges

25 instructions block `convert_reachable_ranges.py`; 23 of them are this form
and **all 23 get a byte-exact spelling** (the other 2 are `ld SP,#imm16`, see
`README-ld_sp_imm16.md`). Marginal bytes released, with the converter's
plausibility screen applied:

* `ldw (imm),(imm)` alone — **79 B** (`--ldw-only`)
* the whole family, `ld` + `ldw` — **165 B**

⚠ The `ld` (byte) half must ship with the `ldw` half. In
`SeqPlay_RestartWithVoiceConfig` (range 0xF39585) the byte form at 0xF39627
blocks 10 bytes *before* the word form at 0xF39631, so fixing `ldw` alone gains
nothing there.

⚠ 7 of the 16 affected ranges — including `FDC_CMD_EXEC`, which holds 4 of the
sites — are refused for a different reason (`a branch target cannot be named`)
and release nothing until that refusal is addressed.

## The residue: DD8 (F0) and DD16 (F1) have no def

The 9 v7 sites the rule does not match are the destination-direct forms with an
8- or 16-bit destination address:

    f0 00 16 d0 f0        ldw (0x00),(0xf0d0)        F0 + D8  + 16 + S16
    f1 03 00 16 f1 03     ldw (0x0003),(0x03f1)      F1 + D16 + 16 + S16

`TLCS900InstrInfo.td` has `LDMMB_DD24`/`LDMMW_DD24` (prefix F2) and
`LDMM_SD8B` (prefix C0) but nothing for prefixes F0/F1 with sub-opcode
`0x14`/`0x16`. That is cause (b), a genuinely missing backend instruction, and
the def to mirror is `LDMMW_DD24` (line 4182) with `Opcode = 0xF1` and two
pre-op bytes instead of three. **None of the 9 is at a blocking site**, and all
9 sit in obvious table data (`f1 ea 00 14 f1 ea` is a repeating pair), so this
is recorded rather than actioned.

⚠ Do **not** close the residue with `extpfx6`. `extpfx<N>` is an unconditional
raw-byte emitter — `extpfx6 0xf1, 0x03, 0x00, 0x16, 0xf1, 0x03` assembles to
exactly those bytes — so it would make every form trivially "spellable" while
producing `.byte` wearing a mnemonic. It appears nowhere in `v7/`, `v9/` or
`v10/`, and it must stay that way.
