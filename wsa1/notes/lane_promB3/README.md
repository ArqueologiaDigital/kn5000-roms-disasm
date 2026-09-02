# lane promB3 — four prom_b spans, 1,757 bytes

The scripts behind every number this lane reported. Run from `wsa1/`.

| script | question it answers | command |
|---|---|---|
| `xref_scan.py` | Does anything in the four WSA1R images hold a little-endian 3- or 4-byte value pointing INTO a given address range? A span whose interior is named by a stored pointer is data reached by dereference, and the pointer's own record says how wide the entries are. | `python3 notes/lane_promB3/xref_scan.py 0xF0D4D2 0xF0D698` |
| `gen_promB3_spans.py` | What is in the spans `0xF0D4D2+454`, `0xF0D7E2+442`, `0xF2B422+338`, `0xF2BB0D+523`, and what says so? Emits them as typed data and checks every framing claim. | `python3 notes/lane_promB3/gen_promB3_spans.py --selftest` (46 checks, 0 failures)<br>`--render` prints `Bitmap_F0D5BF_80x24` as pixels<br>`--show` prints the assembly<br>`--splice` writes it into `prom_b/wsa1_prom_b.s` |

## What the numbers mean

* **454 = 72 + 11 + 11 + 72 + 11 + 11 + 16 + 33 + 217** — three 8-byte-entry
  operand tables, the four interpreter-B records that point at them, a 33-byte
  ramp, and 217 of the 240 bytes of an 80x24 bitmap.
* **442 = 352 + 44 + 44 + 2** — 16 interpreter-A op-07 text records, two
  11-entry tables of 4-byte pointers into them, two character codes.
* **338 = 13 + 11 + 11 + 128 + 11 + 64 + 40 + 60** — the tail of a word array
  that starts three bytes before the span, three interpreter-B records, two
  operand tables, a 10-entry pointer table and the five arrays it names.
* **523 = 11 + 512** — one interpreter-B record whose AND mask implies exactly
  64 entries of 8 bytes, and the 64 entries.

## The one claim that is NOT a pointer

`Bitmap_F0D5BF_80x24` is named by nothing. Its shape is forced instead by three
facts: swi 7 service 3 (prom_a `0xF8EDB4`) stores bitmaps column-major, HL bytes
per column and BC columns; the run must end on `0xF0D6AF`, the `op 23, 5 bytes`
glyph record that lands on the already-converted record at `0xF0D6B4`; and of
the two 24-aligned starts that clear the table above it, the lower one would
split the proven `0x01..0x21` ramp. `--render` is the check — at 10 columns the
bytes are a single connected line drawing, and at any other width they shear.

That same argument moved the neighbouring walk start from +454 to +477 and
rewrote the `op 0C, 28 bytes` record at `0xF0D698`, which was the bitmap's last
23 bytes plus the glyph record, framed on a handler (`0xF31AEB`) that is a bare
`ret` and therefore accepts any length at all.

## Coverage, measured

`python3 scripts/analysis/source_coverage.py` — prom_b `.incbin` went
**10,664 -> 8,907 bytes** (substantive 442,320 -> 444,077).
