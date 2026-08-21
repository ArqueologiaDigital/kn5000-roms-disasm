# The KN5000 accompaniment style format (IC19 custom data)

Status: partial. Everything below is measured; the gaps are named rather than glossed.
Reproduce with `python3 scripts/analysis/style_cell_census.py`.

## Why this document exists

`custom_data` is 639,296 bytes of style data that entered the build as four opaque `.incbin`
blobs. The completeness spec (`DISASSEMBLY-COMPLETENESS-SPEC.md` §3) says a binary include is
legitimate only when the bytes have no better human-readable form. Style data plainly has one --
it is music -- so this is a work item, and this document is what a converter would need.

## Chip layout

The 1 MB flash at IC19 holds eight style banks, each announced by an `H\0K\0` magic on a 0x100
boundary:

    0x300000  section 0     0x319800  section 1     0x330000  section 2     0x349800  section 3
    0x360000  section 4     0x379800  section 5     0x390000  section 6     0x3B0000  section 7

Section 7 is a 96-byte header followed by erased flash; it is now typed out in
`custom_data/kn5000_custom_data.s` rather than incbin'd. Sections 0-6 carry styles.

## Style directory

At magic + 0x60, thirty records of 96 bytes, seven directories in all = 210 styles.

    +0x00  ..      unidentified
    +0x40  16 B    style name, ASCII, space- or NUL-padded
    +0x50  ..      unidentified

The names are now typed out in the source, so they are greppable: "Bolero puro",
"GentleSwing 1", "GospelRevival", "Roaring 20's", "AccordionJazz", "8BtPopBallad D".
**Only the name field is established.** No other field in the 96 bytes has been identified.

## Cells

Style music lives in 256-byte cells, 1050 of them across the four section blobs (150 in
section_0, 300 in each double section). A cell is:

    +0x00  1 B     0x80        cell-start marker
    +0x01  2 B     FF FF       constant
    +0x03  2 B     u16 LE      NEXT CELL, or 0xFFFF to end the chain
    +0x05  1 B     0x87        end-of-header marker
    +0x06  250 B   payload     event stream

**The header reading is confirmed by an independent signal.** 718 cells carry next = 0xFFFF, and
exactly 718 cells reach the end-of-stream status 0x83 in their payload. Those two counts come
from different fields and agree cell for cell in every section (105/206/182/225). The remaining
332 cells run off the end of their payload mid-stream, which is what a chained format predicts:
an event may straddle a cell boundary and only the last cell of a chain terminates.

⚠ An earlier probe searched for the literal `80 FF FF FF FF 87` and reported 725 cells. That
pattern only matches cells whose next pointer happens to be 0xFFFF -- it was finding chain ends,
not cells. Matching the header SHAPE finds 1050.

## Event grammar

Identical in structure to the demo-song presets (`scripts/build/demo_preset_to_midi.py`): a byte
with bit 7 SET is a status; the bytes after it with bit 7 CLEAR are its arguments. Because the
argument count is self-delimiting, the stream can always be framed, whether or not the meaning of
a given status is known.

    status  args  count    meaning
    0x90       5  16,654   NOTE: pos, note, velocity, dur_ticks, dur_beats
    0x81       0  11,339   advance one beat
    0x91       7   5,453   NOT DECODED
    0xD2       2     958   NOT DECODED
    0xD3       2     576   NOT DECODED
    0xD1       2     100   NOT DECODED
    0x83       -     718   end of chain

Timing, inherited from the demo-preset work and not re-verified here: 96 ticks per beat, `pos` is
the tick within the current beat (0..95), duration is `dur_beats * 96 + dur_ticks`. Both `pos` and
`dur_ticks` are bounded by 95, which is why this is base-96 rather than a 16-bit value.

The stray 0x90 events with 1-4 arguments (47/43/35/32 of them) are notes cut off at a cell
boundary. They resolve once chains are followed instead of cells being read in isolation, and
their existence is a check on the chaining rather than a defect.

## What is still missing

1. **The cell pointer encoding.** Non-terminal pointers are values like 0x1096, 0x109A, 0x109B,
   0x109D -- a 0x10 high byte with an incrementing low byte. The demo-preset rule, cell `c` at
   `0x800 + (c-1)*256`, puts 0x1096 far outside the section, so styles address cells differently:
   bank-relative, or a split bank/index field. **This is the blocker.** A converter cannot follow
   chains without it, and without following chains the straddling events cannot be decoded.
2. **0x91, 0xD1, 0xD2, 0xD3.** Argument counts are known (7, 2, 2, 2); meanings are not.
3. **The 96-byte directory record**, beyond the name.
4. **Which chain belongs to which style**, and how a style's parts/variations map onto chains.

## What NOT to do

The grammar is self-delimiting, so any byte run can be reframed as events and written back
byte-exactly. That would empty the illegitimate-blob column without establishing anything: 200,000
lines of `90 40 7f 00 00 00` satisfy a byte count and none of L3, which asks for field meanings.
Converting this data is worth doing after item 1 above is settled, not before.
