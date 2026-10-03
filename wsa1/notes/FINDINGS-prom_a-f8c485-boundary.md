# prom_a 0xF8C485-0xF8C630: CONVERTED 2026-09-02, three embedded tables were
# misread as code by the naive linear decode

**Status: 427 B converted. This was the lead FINDINGS-prom_a-f8c000-cluster.md
left for whoever took it next**, which reported the span as self-consistent
overall (0 undecodable bytes over 0xF8C485-0xF8C630) but refused it because one
of `DispatchTable_F8C2B2`'s own targets, `0xF8C4D8`, lands **3 bytes inside** an
instruction of that decode (`ld XWA,0xc4c08000` at `0xF8C4D5-0xF8C4DA`) rather
than on a boundary.

Converter: `notes/gen_prom_a_f8c485_module.py` (`--check` re-derives every
number below and re-verifies the whole 427 B region round-trips byte-exact
through llvm-mc; `--emit` produces the assembly spliced into
`prom_a/wsa1_prom_a.s`). Gate: `make gate-wsa1`, green.

## What was actually wrong: three embedded tables, not a decode error

The span is five short bit-set/clear routines interleaved with three small
data tables that the naive linear decode swallowed as garbage instructions
(`normal`, `max`, stray `push SR`/`nop` -- exactly the "suspicious mnemonics"
signature the cluster note flagged).

**Table 1 -- `BitmaskTable_F8C4B8`, 32 B, 16 little-endian words.** The FIRST
routine in the span (`PanelLed_ShowSoundSelect`) ends with a genuine indexed read:
`ld A,(0x2169) / and A,0x0f / sla 0x01,A / ld XIY,0x00f8c4b8 / ld WA,(XIY+A)` --
a nibble (0-15) shifted left by one indexes a WORD table. That pins the
table's size from the *reader*, not from a walk: max index 15, word width 2,
so the table is exactly 32 bytes, ending at `0xF8C4D8` -- which is
`DispatchTable_F8C2B2`'s own second target, already committed to the tree
before this pass touched the span. The table's 16 values corroborate the
read on their own merits: `0x0101, 0x0201, 0x0401, ... 0x8001, 0x0100, 0x0200,
... 0x8000` -- a clean single-bit-per-nibble progression, not noise.

**Tables 2 and 3 -- `BucketTable_F8C536` and `BucketTable_F8C592`, 4 B each.**
The same 3-value bucket-select idiom appears twice (`cp A,0x18 / jr c / cp
A,0x1a / jr ugt / sub A,0x18 / extz WA / extz XWA / add XWA,<table> / ld
A,(XWA)`). The `cp`/`jr` pair proves the passthrough range is exactly `A in
{0x18, 0x19, 0x1a}` (three values, `jr c` bypasses `A<0x18`, `jr ugt` bypasses
`A>0x1a`), so each table needs 3 bytes -- but each is followed by **one extra
byte that duplicates the table's own last entry** (`0x10,0x20,0x40,0x40` and
`0x01,0x02,0x04,0x04`), a padding convention rather than a fourth valid index.
Independent corroboration: each table's three values match, byte for byte,
the SAME routine's own hardcoded fallback constants for the same three
buckets (`cp A,0x08`/`0x28 -> 0x10`, `cp A,0x09`/`0x29 -> 0x20`, else `-> 0x40`,
and the `0x01/0x02/0x04` triple in the second routine) -- the table and the
code that reads it agree on what the three buckets mean without either one
citing the other.

## External corroboration: 4 of 8 dispatch targets land exactly on the seams

With all three tables excised (40 B of the 427), the remaining 387 bytes
decode as five short, near-identical routines with **zero drift**, and FOUR
of `DispatchTable_F8C2B2`'s eight non-placeholder pointers -- a table already
committed to this tree, not derived by this pass -- land exactly on the
resulting segment starts:

```
0xF8C485  PanelLed_ShowSoundSelect   dispatch id=0x0004   (span start)
0xF8C4D8  PanelLed_ShowBank   dispatch id=0x0040   (table 1's own end)
0xF8C596  PanelLed_ShowCtrl1Offset   dispatch id=0x0100   (table 3's own end)
0xF8C5E3  PanelLed_ShowCtrl2Offset   dispatch id=0x0800   (internal ret boundary)
```

This is the same evidentiary standard as `FINDINGS-prom_a-fc4000-boundary.md`
and `FINDINGS-prom_a-fde74c-boundary.md`: the boundary is fixed by something
outside the walk (here, a pointer table already sitting in the tree, plus the
tables' own readers), not by how plausible the decode looks.

## What is still NOT claimed

Every routine is `sub_XXXXXX`; semantics are not named. `reachability.py`
still does not credit this span -- a bare `ld XIY,imm32` load is explicitly
outside that walk's seed classes, the same limitation already noted in
`FINDINGS-prom_a-f8c000-cluster.md`. The internal target `0xF8C53A` (reached
only by `PanelLed_ShowBank`'s own `jr z`) is not a dispatch entry and is given a
local `.LF8C53A` label, not a `sub_` name.

## Byte accounting

51 (`PanelLed_ShowSoundSelect`) + 32 (table 1) + 94 (`PanelLed_ShowBank`) + 4 (table 2) + 88
(`.LF8C53A` body) + 4 (table 3) + 77 (`PanelLed_ShowCtrl1Offset`) + 77 (`PanelLed_ShowCtrl2Offset`) = 427 =
`0xF8C630 - 0xF8C485`, matching the `.incbin` this pass replaced.

## What this leaves in the cluster

`0xF8C652-0xF8C842` (496 B), the cluster note's other refused neighbour, is
NOT closed by this pass -- its own reported signature (8 undecodable bytes at
a ~16-byte stride) is a different shape from what closed this span and needs
its own reader-derived boundary.
