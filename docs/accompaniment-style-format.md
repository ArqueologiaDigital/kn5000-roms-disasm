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

## What the event arguments look like, measured

Distributions over the full corpus (57,702 events). These are OBSERVATIONS, not decodings: no
label below is invented, and where a meaning is not established it says so.

### NOTE (0x90) and NOTE2 (0x91) share their first five arguments

Argument ranges are indistinguishable between the two, which is why NOTE2 is read as a note:

    arg0  0..95     tick within the beat
    arg1  22..114   note number
    arg2  1..127    velocity
    arg3  0..95     duration, ticks
    arg4  0..15     duration, beats

**NOTE2 carries two more, and they are NOT established.** Ranges 0..24 and 0..25, 57 distinct
pairs of the 256 possible, heavily skewed: (0,17) 4291, (3,0) 2518, (18,0) 600, (17,17) 437.

Two facts constrain what they can be. They are **per-note, not per-part**: of 701 chains
containing NOTE2, the pair varies within 549 of them, usually across 2 or 3 distinct values. And
NOTE and NOTE2 **coexist inside one chain** (552 chains use both), so NOTE2 is a different kind of
note within a part rather than a different part.

### Chains split cleanly into two populations

    NOTE-only chains (388)   notes 22..114, most common 36, 49, 38, 74
    mixed chains (552)       NOTE notes 24..96 (top 60, 72, 48), NOTE2 28..96 (top 64, 55, 67)

The NOTE-only population's most common values are 36 and 38, and its range is the widest. That is
what a percussion part looks like under General MIDI, and percussion is exactly the part that would
need no chord conversion. [INFERENCE] -- consistent with the data, not demonstrated: no code path
has been traced that treats these chains differently.

### The three controllers

    CTL1 (0xD1)  112 events   arg0 0..94, arg1 0..117, both sparse
    CTL2 (0xD2)  1227 events  arg0 0..95, arg1 0..75 but clustered at 61..64
    CTL3 (0xD3)   982 events  arg0 0..95, arg1 is **0 or 127 ONLY** (395 / 375)

arg0 shares the 0..95 domain of every other event's first argument, so it is read as the tick
within the beat. CTL3's second argument being exactly two values is the strongest single clue in
this section: 0/127 is the standard switch encoding. **Which switch is not established.**

All three appear THROUGHOUT their chains (median relative position 0.46, 0.47, 0.72), not
clustered at the start, so they are not part-setup.

### The consumer side, traced

`v10/maincpu/sequencer/seq_event_playback.s:2150` is a dispatcher over exactly these statuses, and
it settles some of the question from the CODE rather than from distributions:

    0x90  -> AccPlay_ProcessNoteEvent
    0xD2  -> MidiSeq_HandleD2Event            entry size 5
    0xD1  -> MidiSeq_ProcessSustainEvent      entry size 4
    0xD3  -> MidiSeq_ProcessSustainEvent      entry size 4   (the SAME handler as 0xD1)
    0xC0  -> MidiSeq_HandleProgChange         (MIDI program change)
    0xB0  -> MidiSeq_HandleCtrlChange         (MIDI control change)

Three facts follow, and they are code facts:

1. **0xD1 and 0xD3 are handled identically**, by one routine, with the same 4-byte entry size.
   Whatever they select, they are the same KIND of thing.
2. **0xD2 is different**, with a 5-byte entry, and its handler copies the byte at +3 down to +2
   before processing -- an argument shuffle the sustain path does not do.
3. The dispatcher also accepts 0xC0 and 0xB0, plain MIDI program-change and control-change
   statuses. So this event stream is a MIDI-adjacent encoding, which is consistent with 0xD3's
   argument being exactly 0 or 127.
4. Inside the shared handler, an 0xD3 in the buffer is REWRITTEN to 0xD5 before processing
   (`cp a,0xd3` / `ldb a,0xd5`), so the two are distinguished downstream even though they enter
   the same routine.

⚠ THE NAME "Sustain" IS NOT EVIDENCE. `MidiSeq_ProcessSustainEvent` is a curated symbol from an
earlier pass, not something the ROM says. It is consistent with 0xD3's 0/127 values, but this
document does not adopt it as established: what is established is the dispatch structure above.
Confirming it needs the MIDI controller number the handler ultimately emits, which has not been
traced to a literal.

### 0x84 is a TEMPO RESET (accompaniment parser)

`v10/maincpu/sequencer/accompseq_routines.s:2004` dispatches status **0x84** to
`AccompSeq_SeqParse_TempoReset`, which takes NO arguments from the event: it loads a stored value
from 0x7E65 (or 0x7E69 when the flag at 0x7E52 is set) and writes it to 0x7E44, 0x7E42 and an
`stw_erp WA, 0xe2` register. So 0x84 means "restore the tempo to the stored value", not "set the
tempo to this number".

0x84 does not occur in the 210 factory styles -- another member of the vocabulary the shipped data
does not exercise, alongside 0xD4/0xD5/0xD7.

⚠ This does NOT support the separate guess that the demo songs' `0x80` is a tempo SET (recorded in
`table_data/includes/demo_presets/README.md`). Different parser, different status, and 0x84 carries
no value. That guess stays unconfirmed.

### The 0xD family is larger than these styles use

`v10/maincpu/sequencer/accompseq_routines.s:165` classifies events for the accompaniment engine,
and it accepts **0xD1, 0xD2, 0xD3, 0xD4, 0xD5, 0xD7 and 0xC0** as one class -- "timed events",
routed together to `AccompSeq_ProcessTimedEvent`, which computes a delta time and parses.

So the container supports at least seven control statuses; the 210 factory styles in this chip use
only three of them. That matters for a reader of this document: an ENCODER must not assume the
three seen here are the whole vocabulary, and a decoder should reject rather than guess on
0xD4/0xD5/0xD7.

It also explains the 0xD3 -> 0xD5 rewrite noted above: 0xD5 is a real status in the same family,
not a sentinel invented by the handler.

### CTL3 (0xD3): three signals converge on the damper pedal

Not proved, but no longer merely suggestive. Three independent facts line up:

1. **The data.** 0xD3's second argument takes exactly two values across the whole corpus, 0 and
   127 (395 and 375 occurrences). Nothing else appears.
2. **The sub-CPU.** `v142/subcpu/kn5000_subprogram_v142.s:17223` is `Voice_CC_SetSustain`, the
   handler for **CC 0x40 (64), the MIDI damper pedal**. It treats its argument as a BOOLEAN --
   `cps c, 0`, set bit 0 of the part flags word if non-zero, clear it if zero -- which is exactly
   the 0/127 domain the data uses, and exactly why a controller that is logically a switch is
   transmitted as 0 or 127.
3. **The main CPU.** 0xD1 and 0xD3 are routed to a single handler that an earlier naming pass
   called `MidiSeq_ProcessSustainEvent`, and the dispatcher around it also handles plain MIDI
   0xC0 and 0xB0.

**The missing link is the emit site**: no code path has been traced from the main CPU's 0xD3
handling to a literal 0x40 being sent to the sub-CPU. Until that exists this stays an inference --
a well-supported one, from three directions that share no assumptions, but an inference. It is
recorded here rather than baked into a name, so the next reader can finish it or refute it.

### CTL1 (0xD1): a lead, and a tension worth recording

`v10/maincpu/sequencer/seq_event_playback.s:2955-2985` sends status **0xD1** through
`AccompSeq_SendMidiEvent` from two places, and the surrounding code names them: the REVERB restore
path and the CHORUS restore path. Both set the value register to **0 or 0x7F** from a flag bit, and
pass a small selector alongside -- 7 on the reverb path, 3 on the chorus path.

That is a genuine lead: 0xD1 carries an on/off value in an effect-enable role there.

**But it does not match the style data, and the mismatch is the useful part.** In the 210 factory
styles, 0xD1's first argument spans 0..94 with 60 distinct values and its second 0..117 with 55 --
neither looks like a two-element selector {3, 7} nor like a 0/127 switch. So either the playback
path builds a different 0xD1 than the one stored in a style, or 0xD1's arguments are not the
(selector, value) pair this call site suggests.

Recorded unresolved on purpose. Two readings of one status that do not reconcile is exactly the
kind of thing that gets quietly averaged into a confident wrong sentence, and the next person
should see both halves.

### Where the trail stops, precisely

What is established: the dispatch structure, the shared handler for 0xD1/0xD3, 0xD2's distinct
entry size and argument shuffle, the D-family membership, and the MIDI-adjacency implied by 0xC0
and 0xB0 being handled alongside.

What is NOT established: which controller each status selects. The chain from
`MidiSeq_ProcessSustainEvent` runs through `MidiSeqBuf_ScanAllEntries` and
`MidiSeqBuf_ProcessEntries` into a ring buffer walked by `Util_ExtractAndShiftBits`, and no literal
controller number has been traced to an emit site. **That is the next step**, and it is bounded:
find where a buffer entry of this class reaches the tone generator or the MIDI output, and read the
constant.

Naming these from distributions alone would be the "confident header" anti-pattern the completeness
spec lists. Naming them from a symbol that is itself an inference is the same mistake one step
removed.
