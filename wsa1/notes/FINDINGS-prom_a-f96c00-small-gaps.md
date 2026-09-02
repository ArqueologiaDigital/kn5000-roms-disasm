# prom_a: four small residues near RamInitTable_F96CA6, CONVERTED 2026-09-02
# (42 B total: 15 + 1 + 3 + 23)

**Status: all four converted.** None required a walk: each sits between two
anchors already committed to the tree by earlier passes (a `sub_` routine's
own `ret`, the already-documented `RamInitTable_F96CA6` arrays, or the
already-verified 1400 B 0x0E fill run), and this pass only had to account
for what falls between them.

Converter: `notes/gen_prom_a_f96c00_small_gaps.py` (`--check` re-derives
every number below). Gate: `make gate-wsa1`, green.

## 0xF96C7B (15 B) -- a 3-slot reserved record table, 2 slots unused

`sub_F96C65` (already-converted, immediately above) sets `XIY=0x00f96c7b`,
`BC=1`, then loops exactly ONCE over a 5-byte record (`ld XIX,(XIY)` /
`inc 4,XIY` / `ld A,(XIY)` / `inc 1,XIY` / `and (XIX),A` -- a 4-byte address
then a 1-byte AND-mask) before `ret`. That accounts for only the first 5 of
15 bytes. The remaining 10 are zero, and `15 = 3 * 5` exactly: read as a
3-slot table with only slot 0 populated (`addr=0x00007f32, mask=0xfb`) and
slots 1-2 zero -- reserved capacity the routine's hardcoded `BC=1` never
touches. `0xf96c7b` is the ONLY literal 3-byte reference to this address
anywhere in the ROM (checked), so no other call site processes more slots.

## 0xF96CA5 (1 B) -- a single 0x0E pad byte

Sits between `sub_F96C8A`'s `ret` (0xF96CA4) and the already-documented
`RamInitTable_F96CA6_Addrs` (starts 0xF96CA6). Its value is `0x0E` -- this
file's own established erased-flash/RET-padding constant, used throughout
the rest of the file's verified `.fill` runs.

## 0xF96E86 (3 B) -- unclassified, provably outside both RamInitTable arrays

`RamInitTable_F96CA6`'s own pre-existing header comment already does this
arithmetic: 80 address longs (320 B) + 80 value words (160 B) = 480 B,
landing exactly on `0xF96E86`. So `0x24, 0xff, 0xff` are provably NOT part of
either array. A raw pointer scan of the whole ROM (3- and 4-byte
little-endian patterns for this address) finds zero hits. Left honestly
unclassified, the same treatment `Unclassified_FC48D8` got in
`FINDINGS-prom_a-fc4000-boundary.md`.

## 0xF97401 (23 B) -- unclassified, not a clean tile of the neighbouring fill

Bounded by the already-verified 1400 B 0x0E fill run (ends exactly here,
per the file's own comment) and `sub_F97418` (already-converted, starts
exactly at the far end). The bytes (`00 00 00 0e` x5 + `00 00 00`) are
mostly zero with one 0x0E every 4th byte -- not simply "more fill,
mismeasured" (23 is not a multiple of 4, and the fill run's own byte is
uniform 0x0E, not 3-zeros-then-0x0E). Zero pointer hits in the ROM. Left
unclassified.

## Byte accounting

15 + 1 + 3 + 23 = 42 B, four independent splices, each bounded on both sides
by material this pass did not touch.
