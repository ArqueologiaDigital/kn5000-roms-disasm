# prom_a 0xF8C652-0xF8C842: CONVERTED 2026-09-02, a db-count undercounted the
# number of embedded tables by two

**Status: 496 B converted.** `FINDINGS-prom_a-f8c000-cluster.md` refused this
span outright: "8 undecodable bytes at a roughly 16-byte stride
(0xF8C687 through 0xF8C708), the signature of an embedded fixed-stride
table, not a misread of pure code." That call was right that a table sits
there, but the `db` count itself is a poor instrument: **two more tables**
further down in the same span decode as short, individually valid-looking
instructions (`normal`, `push SR`, `max`) and never trip unidasm's
undecodable-byte flag at all.

Converter: `notes/gen_prom_a_f8c652_module.py` (`--check` re-derives every
number below and re-verifies the whole 496 B region round-trips byte-exact
through llvm-mc; `--emit` produces the assembly spliced into
`prom_a/wsa1_prom_a.s`). Gate: `make gate-wsa1`, green.

## Three tables, found from their readers, not from decode plausibility

**Table 1 -- `PointerTable_F8C687`, 128 B, 32 little-endian longs.** The
span's first routine (`sub_F8C652`) ends with `ld A,(0x2250) / sla 0x02,A /
ld XIY,0x00f8c687 / ld XIY,(XIY+A)` -- a 5-bit index, shifted left by 2 (i.e.
multiplied by 4), selects a 32-bit entry from a table at `0xF8C687`. Max
index 31, entry width 4, so the table is exactly `32*4 = 128` bytes, ending
at `0xF8C707` -- `DispatchTable_F8C2B2`'s OWN `id=0x0002` target, already
committed to the tree before this pass. The table's 32 values corroborate the
read on their own: a strictly monotonic increasing progression,
`0x000076c2, 0x00007702, 0x00007742, ... 0x00007ec2`, each 0x40 more than the
last except one 0x80 step at index 7->8 -- a real irregularity in the ROM's
own data, reproduced as measured, not smoothed into a formula.

**Tables 2 and 3 -- `RecordTable_F8C727` (31 B, 10 x 3-byte records + a
0xFF terminator) and `RecordTable_F8C764` (25 B, 8 x 3-byte records + a 0xFF
terminator).** Both are read by the SAME shared parser, `sub_F8C7F9`
(`cp (XIY),0xff` / `cp A,(XIY)` / `add IY,0x0003` / loop) -- the identical
terminator-and-linear-scan shape already established for the `CmdList_*`
tables and their shared parser at `.LF8C16D` in
`FINDINGS-prom_a-f8c000-cluster.md`, just a different shared routine and a
different record width. The two call sites (`sub_F8C707` loading
`XIY,0x00f8c727` then `calr sub_F8C7F9`; the routine at `0xF8C746` doing the
same with `0x00f8c764`) are code THIS SAME PASS decoded, not manufactured to
fit the tables -- and each table's own terminator byte lands exactly where
the following code block already needs to start: `0xF8C746`, and `0xF8C77D`
(the latter ALSO `DispatchTable_F8C2B2`'s own `id=0x0200` target).

## Byte accounting and the resulting boundaries

```
0xF8C652-0xF8C687   53 B  sub_F8C652          dispatch id=0x0080 (span start)
0xF8C687-0xF8C707  128 B  PointerTable_F8C687 32 longs
0xF8C707-0xF8C727   32 B  sub_F8C707          dispatch id=0x0002
0xF8C727-0xF8C746   31 B  RecordTable_F8C727  10 records + terminator
0xF8C746-0xF8C764   30 B  (internal)          reads RecordTable_F8C764
0xF8C764-0xF8C77D   25 B  RecordTable_F8C764  8 records + terminator
0xF8C77D-0xF8C842  197 B  sub_F8C77D ..       dispatch id=0x0200, plus the
                          sub_F8C7F9 ..          shared parser and one more
                                                  small routine reading it
```

53+128+32+31+30+25+197 = 496 = `0xF8C842-0xF8C652`, matching the `.incbin`
this pass replaced. With all three tables excised, the remaining 312 bytes
decode with zero drift, and three of `DispatchTable_F8C2B2`'s eight
non-placeholder targets land exactly on the resulting segment starts:
`0xF8C652`, `0xF8C707`, `0xF8C77D`. Same evidentiary standard as FC4000,
FDE74C and 0xF8C485: the boundary is fixed by something outside the walk.

## What is still NOT claimed

Every routine is `sub_XXXXXX`; the record tables' key bytes and values are
not interpreted (they look like a small state-flag encoding, matching the
shape of the already-named `CmdList_*` tables' 7-byte records, but that is
not asserted here). `reachability.py` still does not credit this span, the
same limitation already on record for the rest of this cluster.

## What this closes in the cluster

Both spans `FINDINGS-prom_a-f8c000-cluster.md` left for later --
`0xF8C485-0xF8C630` (`FINDINGS-prom_a-f8c485-boundary.md`) and this one --
are now converted. `DispatchTable_F8C2B2`'s remaining two non-placeholder
targets, `0xF8C77D` and `0xF8C7AC`, both already sit inside already-converted
territory (`0xF8C77D` by this pass, `0xF8C7AC` by the pre-existing
`.incbin`-free code further on).
