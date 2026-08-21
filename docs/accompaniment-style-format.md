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

Style music lives in 256-byte cells. A cell is recognised by `byte[0] == 0x80 && byte[5] == 0x87`:

    +0x00  1 B     0x80        cell-start marker
    +0x01  2 B     u16 LE      PREV cell, 0xFFFF at a chain head
    +0x03  2 B     u16 LE      NEXT cell, 0xFFFF at a chain end
    +0x05  1 B     0x87        end-of-header marker
    +0x06  249 B   payload     event stream
    +0xFF  1 B     0x87        trailing marker, on all 1564 cells

**1564 cells, 400,384 B** -- 214 in section_0 and 423/488/439 in the double sections.

⚠ TWO EARLIER COUNTS WERE WRONG, each by assuming a constant that is a field:
  * searching for the literal `80 FF FF FF FF 87` found 725. That matches only cells where BOTH
    u16 fields are 0xFFFF.
  * requiring `byte[1..2] == FF FF` found 1050. That treats field A as a constant; it is not.

Both fields are SECTION-TAGGED: the high nibble is the section number plus one, verified by the
per-section ranges being disjoint and exactly as predicted -- section_0 uses 0x1xxx only, the
section_1_2 blob 0x2xxx and 0x3xxx, section_3_4 0x4xxx and 0x5xxx, section_5_6 0x6xxx and 0x7xxx.
The low 12 bits are a 256-byte block index **relative to the section's FIRST CELL BLOCK**:

    target_block = (value & 0x0FFF) + first_cell_block_of_section
    target_off   = target_block * 256

The relative base is the whole difficulty. Section 0's cells begin at block 0x014, and the double
sections' at 0x01C and 0x184, so reading a pointer as an ABSOLUTE block index lands outside the
cell region most of the time -- 8 of 45 in section_0, which is what an earlier pass measured
before drawing the wrong conclusion from it.

Among the 1050 cells whose field A is 0xFFFF, 718 have field B = 0xFFFF and exactly 718 reach
end-of-stream 0x83 in their payload, agreeing cell for cell in every section (105/206/182/225).
Two different fields predicting each other that precisely is why the CELL framing is trusted.

**THE CELLS ARE DOUBLY-LINKED CHAINS, and the pointer rule is proved.** With the relative base
above, every pointer in every section resolves to a real cell -- **1028 of 1028** -- and every
forward link's target points back at its source -- **514 of 514**. Two independent properties,
no exceptions, across all seven sections. There are 1050 chain heads.

⚠ RETRACTED, and it was mine: an earlier version of this document said the linked-list reading
was "refuted", on the strength of 0 of 510 back-pointers agreeing and the two fields tracking the
block index at constant offsets across blocks 0xAA-0xAC. Both observations were artefacts of
resolving pointers against the wrong base. The constant offsets were the tell -- a difference of
0x14 between the pointer and the block is the base, not a coincidence -- and I read them as
evidence against a chain instead of as the missing constant. Reproduce the corrected result with
`scripts/analysis/style_cell_chains.py`, which asserts both properties rather than printing them.

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

**Following the chains decodes the whole corpus: 50,245 events, ZERO malformed.** Every status
receives exactly its documented argument count, including the notes that straddle cell boundaries
-- which were the 1-to-4-argument 0x90s an isolated per-cell read reported. That is the check on
the chain rule and the payload length at once: get either wrong and the count of malformed events
is in the hundreds.

The payload is 249 bytes, not 250. Byte 0xFF of every cell is a second 0x87 marker, and reading it
as payload injects one bogus status per cell.

## What is still missing

1. ~~The cell pointer encoding~~ **SOLVED 2026-08-21** -- prev/next, section nibble plus a
   12-bit block index relative to the section's first cell block. Chains can now be followed, so
   events straddling cell boundaries can be decoded.
2. **0x91, 0xD1, 0xD2, 0xD3.** Argument counts are known and now confirmed against the whole
   corpus with no exceptions (7, 2, 2, 2); their MEANINGS are not known. This is the remaining
   semantic gap, and it no longer blocks reading the data -- only interpreting those events.
3. **The 96-byte directory record**, beyond the name.
4. **Which chain belongs to which style**, and how a style's parts/variations map onto chains.

## What NOT to do

The grammar is self-delimiting, so any byte run can be reframed as events and written back
byte-exactly. That would empty the illegitimate-blob column without establishing anything: 200,000
lines of `90 40 7f 00 00 00` satisfy a byte count and none of L3, which asks for field meanings.
Converting this data is worth doing after item 1 above is settled, not before.
