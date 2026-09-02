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

## The directory names its chains -- a bijection (2026-09-02)

The record layout above lists everything but the name as "unidentified".  The five u16
fields at record **+0x00, +0x04, +0x06, +0x08 and +0x0A** are CELL POINTERS, resolved by
the same rule as the chain links (`block = (v & 0x0FFF) + first_cell_block_of_section`),
and they are a consecutive ascending run `v, v+1, v+2, v+3, v+4` in **240 of 240**
records.  Field +0x02 is zero in every record.

Across all 240 records they name **all 1,200 linked chains (`byte[0] == 0x80`) and none
of the 818 unlinked template blocks (`byte[0] == 0x00`)** -- no duplicate, no gap.  So
every music chain now has a style name, and `scripts/build/style_to_midi.py` writes one
Standard MIDI File per record into `custom_data/styles/midi/`.

⚠ The obvious test -- "the value resolves to a chain head" -- is **worthless here**: it
passes 1,200/1,200, and so does a uniformly random value drawn from the same block range,
because chain heads are dense in the cell region.  The two properties above are the ones
whose null can fail.

⚠ **A zero is a valid pointer.**  The Composer bank's section nibble is 0 rather than
section+1, so its first pointer is literally `0x0000`, addressing that section's first
cell block.  Treating zero as "absent" discards one real pointer and invents one unnamed
chain.

Reproduce: `python3 scripts/analysis/style_directory_chains.py [--names|--gaps|--selftest]`.

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

    status  args   count   meaning
    0x90       5  26,633   NOTE: pos, note, velocity, dur_ticks, dur_beats
    0x91       7   7,538   NOTE plus two trailing bytes -- see below, now decoded
    0x81       0  13,965   advance one beat
    0xD1       2     112   controller, selector 1 -- NOT decoded
    0xD2       2   1,227   controller, selector 2 -- PITCH BEND
    0xD3       2     770   controller, selector 3 -- MIDI CC 0x40, the damper pedal
    0x83       -   1,050   end of chain (one per chain, hence the chain count)

    non-terminator total 50,245, which is the chain-walk figure quoted above.

⚠ CORRECTED 2026-08-21. An earlier version of this table came from
`scripts/analysis/style_cell_census.py`, which reads cells in ISOLATION -- only the 1050 whose PREV
is 0xFFFF, stopping at 0x83 -- so its rows summed to 35,080 while the same document correctly
reported 50,245 for the chain walk. Every count above is re-derived by following chains.

### The 0xDn low nibble is a CONTROLLER SELECTOR, and two of the three are decoded

The part is NOT in the event data: it comes from RAM 0x7E52 and becomes the low nibble of the
RUNTIME status 0xD0|part. In the STREAM, the low nibble is a selector instead.

**0xD3 is the damper pedal, and the emit site is now traced.** The IC19-style cell walker at ROM
0xF6EE35 dispatches 0xD1/D2/D3/D4/D5/D7 to 0xF6EF76, where `and A,0x0f` turns the status into a
selector; selector 3 reaches a literal MIDI control change **0xB0 with controller number 0x40** and
a value booleanised to 0 or 0x7F. That closes the inference recorded earlier from three converging
signals -- the data's 0/127-only argument, the sub-CPU's CC 0x40 handler treating its argument as a
boolean, and the shared main-CPU handler. It is no longer an inference.

**0xD2 is PITCH BEND and must not be rendered as a control change.** Selector 2's body at 0xFE89C4
expands the 7-bit argument to 14 bits as `value = (v << 7) | (2v - 128 if v >= 64 else 0)`, and
`SndPart_SetParam` routes it as bend rather than as a controller. This is why its argument clusters
at 61..64: that is bend-centre.

**The whole 0xD selector family is now decoded.** `SeqPerformance_EventDispatch` (ROM 0xFE89A8,
`v10/maincpu/audio/note_voice_mapping.s`) holds the selector bodies laid out in order, each ending
in `SndPart_SetParam(part, value, parameter_id)`. The parameter ids, read straight off the
consecutive bodies:

    selector 1  ->  parameter 1     MIDI CC 1   MODULATION
    selector 2  ->  parameter 432   (not a CC)  PITCH BEND -- the body at 0xFE89C4 is the
                                                7-to-14-bit expansion described above
    selector 3  ->  parameter 64    MIDI CC 64  DAMPER PEDAL
    selector 4  ->  parameter 10    MIDI CC 10  PAN
    selector 5  ->  parameter 11    MIDI CC 11  EXPRESSION
    selector 6  ->  parameter 94    MIDI CC 94  effect depth

So **0xD1 is modulation**, and the family is an ordinary MIDI controller set with pitch bend given
an internal id because it is not a control change.

THE ORDERING IS ANCHORED, NOT ASSUMED. Two selectors were traced independently by a different
route before this table was read: selector 3 reaches a literal `0xB0` control change with
controller number `0x40` = 64, and selector 2's body is the pitch-bend expansion at 0xFE89C4.
Both land exactly where this layout predicts, which is what makes reading the remaining bodies
positionally safe. Selector 5 = expression also explains why the parser special-cases selector 5
alone, storing its value through the pointer at 0x7E74.

⚠ Only selectors 1, 2 and 3 occur in the 210 factory styles. Selectors 4, 5 and 6 are part of the
vocabulary the format supports and this data does not exercise -- the same situation as
0xD4/0xD5/0xD7 and 0x84.

### NOTE2 (0x91): the two trailing bytes come from a firmware table

Decoded, from instructions rather than from names. In v9/v10 the routine at ROM 0xF722AB emits
status **0x91 instead of 0x90 exactly when** a 48-byte table at ROM 0xF72368 -- 12 records of 4
bytes, indexed by `(value at RAM 0x7F38) % 12` through the 128-entry mod-12 lookup at ROM
0xE46142 -- has a non-zero byte[0] for that record. When it does, the routine appends **that
record's byte[1] and byte[2]** as the two extra trailing arguments.

So the pair is not a per-note property computed from the note: it is a per-record constant selected
by a mod-12 index, which is exactly why only 57 distinct pairs occur and why the same pair repeats
across thousands of events. The firmware fixes the event sizes accordingly: 0xF6EECA `cp A,0x90`
takes six bytes, 0xF6EEE7 `cp A,0x91` takes eight -- 5 and 7 arguments plus the status.

### What the table actually contains (2026-08-21)

Dumped from ROM 0xF72368, twelve 4-byte records:

    rec  0  1  2   00 00 00 00        -> plain NOTE
    rec  3         01 00 11 00        -> NOTE2, extra args (0, 17)
    rec  4         01 00 11 00        -> NOTE2, extra args (0, 17)
    rec  5  6      00 00 00 00        -> plain NOTE
    rec  7         01 03 00 00        -> NOTE2, extra args (3, 0)
    rec  8  9 10   00 00 00 00        -> plain NOTE
    rec 11         01 11 11 00        -> NOTE2, extra args (17, 17)

The non-zero rows are **exactly 3, 4, 7 and 11**, and their (b1, b2) pairs are `(0,17)`, `(3,0)`
and `(17,17)` -- **the three most frequent pairs observed in the corpus**, at 4291, 2518 and 437
occurrences. So the mechanism is settled: the pair is a per-record constant, and this table is the
record set.

A musical reading is available and is recorded as an INFERENCE, not adopted: mod 12 makes the index
a pitch class, and 3, 4, 7, 11 are the minor third, major third, perfect fifth and major seventh --
the chord-defining intervals, which are exactly the degrees an accompaniment must adjust when the
chord changes.

**The data supports it strongly but not deterministically.** Of 7538 NOTE2 events, 5990 (79.5%)
have `note % 12` in {3,4,7,11}, against a base rate of 21.8% among plain NOTEs (5806 of 26633).
That is a large enrichment, not a rule -- classes 0 and 9 also carry 630 and 731 NOTE2 events.

### RAM 0x7F38 IS the note, and the 79.5% has a different explanation

`AccPlay_NoteAllocAndWrite` (ROM 0xF722AB, `v10/maincpu/sequencer/seq_event_playback.s:2457`) reads
0x7F38, passes it through the mod-12 table, scales by 4, indexes `AccPlay_NoteParamTable` -- the
twelve 4-byte records above -- stores b0/b1/b2 to RAM 0x7E54/55/56, and emits **0x90 when b0 is
zero and 0x91 otherwise**. It then writes the event as `status, (0x7F37), (0x7F38)`.

Three independent uses show 0x7F38 is the NOTE NUMBER:

* it is the event's SECOND argument, and the second argument of a 0x9n event is the note;
* the same routine stores `(0x7F38) | 0x80` into a voice-slot record, the classic
  slot-in-use-plus-note idiom;
* `AccPlay_FindSlotByChannel` scans the slot table at 0x7E7B for it -- **that label is a misnomer,
  it searches by NOTE**, and the name is a curated guess rather than evidence.

So the index IS `note % 12`, a pitch class, and the musical reading stands.

**Then why only 79.5%? NOT for the reason recorded here fifteen minutes earlier.** That entry said
the factory styles were written by firmware carrying a different twelve-record table. **Falsified
the same session, by looking:**

* the table is **byte-identical in all three dumped KN5000 revisions** -- v7 at ROM 0xF71F64, v9
  and v10 at 0xF72368 -- so no KN5000-revision difference can explain anything;
* the whole main CPU contains **exactly one emitter of status 0x91** (`v10/.../seq_event_playback.s:2479`)
  and **exactly one reference to the table** (`:2467`), so there is no second producer with a
  different record set.

Three distinct pairs are producible by this routine. The corpus contains **57**. Therefore

> **the 0x91 events in the 210 factory styles were not produced by the KN5000's own emitter.**

The custom-data flash is programmed from the "initial data disk" at factory setup, so the styles
were authored on other equipment -- another model, or a factory authoring tool -- whose table had
more non-zero rows. That is a finding about PROVENANCE, and it is worth more than the wrong
explanation it replaces.

What this leaves established, and what it does not:

* ESTABLISHED -- the KN5000's emission mechanism: index `note % 12` through the mod-12 table, scale
  by 4, read a 12-record table, emit 0x91 when b0 is non-zero and append b1, b2. Proven from
  instructions.
* NOT ESTABLISHED -- what the corpus's extra bytes MEAN. They were written by something this
  repository does not contain, so the v10 table cannot decode them, and the chord-tone reading of
  {3,4,7,11} describes THIS firmware's table rather than the data's semantics. Recovering the
  authoring tool's table is the open step, and it is not in these ROMs.

⚠ Two more misnomers met on this path, both curated guesses being used as evidence by their names
alone: `Display_FontPalette_Table_0x12EA` is the mod-12 lookup, and `AccPlay_FindSlotByChannel`
searches by note. Neither name should be trusted in this area.

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

## A second cell marker (2026-09-01)

Lane CUST's byte-debt measurement found that "RAW" (undecoded hex-dump) blocks in the exported
`.styles` listings were not uniformly erased/zero filler: 816 of them, across all four banks, are
shaped exactly like a cell -- `byte[5]==0x87`, `byte[255]==0x87` -- but carry **`byte[0]==0x00`**
where a chain cell carries `0x80`. `cells_of()` required `0x80` and so filed all 816 as
undifferentiated hex.

Every one of the 816 has `prev=next=0xFFFF` (a trivial, unlinked, single-block "chain"), and
**813 of 816 decode with ZERO malformed events** under the unchanged event grammar. More: 811 of
the 816 are **one single 256-byte block, byte-for-byte identical**, repeated in every section --
an ascending eight-note run (`NOTE` 0x30..0x37, one `BEAT` after each, then `END`, then zero PAD
to the block boundary). Section_3_4 and section_5_6 are each 100% this one template; section_0
and section_1_2 carry a handful of near-variants alongside it. [INFERENCE, not established] a
factory-blank template slot is a plausible reading of `byte[0]==0x00` -- a chromatic run is a
recognisable factory test/calibration pattern -- but nothing in the firmware has been traced to
confirm what writes or reads it, so this stays a guess about MEANING, not a claim.

`cells_of()` in `scripts/build/style_events.py` now accepts `byte[0] in (0x80, 0x00)` (with the
`byte[255]==0x87` check added for both, proven not to exclude any of the original 1564 cells
first). The `export()` decode loop was made to fall back to an honest `PAD` dump instead of
crashing on an unrecognised status, for the 3 of 816 that don't decode cleanly. Round trip
reproved exact (`style_events.py verify`) after the change. This moved 208,896 bytes from
undifferentiated hex to decoded, typed event data with no byte-for-byte change to any ROM output.

A **third**, smaller anomaly, found while checking the arithmetic: at a FIXED offset (source
offset `+0x1300` relative to each section's own "H.K." magic, i.e. block 0x13, the block
immediately before the first 256-aligned cell) there sits a **misaligned** pseudo-cell -- the same
6-byte header/trailer shape (`80 FF FF FF FF 87 ... 87`) but NOT on a 256-byte boundary (it starts
64 bytes before the aligned cell grid begins), holding seven `BEAT`s and an `END`. It is
byte-identical across all seven occurrences (one per HK-announced sub-section, 7 x 256 B = 1,792
B including its zero padding). Because `cells_of()` only ever tests 256-byte-aligned offsets, this
one is NOT picked up by the fix above, and is reported as the genuine UNCLASSIFIED remainder by
`scripts/lanes/measure_lane_cust_ic19_debt.py` -- honestly, rather than silently absorbed by
relaxing the alignment check (which would also start matching inside ordinary cell payloads).
Reproduce: run the measurement script; the seven offsets it prints are exactly these blocks.

## What is still missing

1. ~~The cell pointer encoding~~ **SOLVED 2026-08-21** -- prev/next, section nibble plus a
   12-bit block index relative to the section's first cell block. Chains can now be followed, so
   events straddling cell boundaries can be decoded.
2. **0x91, 0xD1, 0xD2, 0xD3.** Argument counts are known and now confirmed against the whole
   corpus with no exceptions (7, 2, 2, 2); their MEANINGS are not known. This is the remaining
   semantic gap, and it no longer blocks reading the data -- only interpreting those events.
3. **The 96-byte directory record**, beyond the name.
4. **Which chain belongs to which style**, and how a style's parts/variations map onto chains.
5. **The 0x00-marker cell's meaning** (§ above) and the 7 misaligned pseudo-cells at `+0x1300`.

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

## THIS DOCUMENT ALSO DESCRIBES THE .CMP DISK FILE FORMAT

When the instrument saves custom accompaniment styles to floppy it writes **the same structure it
keeps in IC19 flash**. Verified on seven real KN-series disks:

* the 96-byte directory at magic + 0x60, 16-char name at +0x40 -- 184 records across the seven,
  carrying user content: "DON JUAN", "a-variation1", "Foxtrot 1";
* the same cell (0x80 at +0, u16 at +1 and +3, 0x87 at +5 and +0xFF);
* the same pointer rule, section nibble plus a block index relative to the first cell block, which
  comes out as base 0x014 -- the same as IC19 section 0;
* 1437 cells, **777 of 777 pointers resolving and 388 of 388 back-links agreeing**;
* **51,443 events decoding with ZERO malformed** under the grammar above, unchanged.

The headers differ only in magic -- IC19 sections open `48 00 4B 00` ("H.K."), .CMP files open
`4C 4B 45 00` ("LKE") -- and from offset 3 they are the same shape byte for byte.

So anything that reads an IC19 style reads a .CMP, and this document is the disk format's
specification as much as the ROM's. Reproduce with
`scripts/analysis/disk_cmp_is_ic19_format.py <dir>`, which ASSERTS the three properties rather
than printing them.

## The container is a FAMILY, and the disk files belong to it

Established 2026-08-21 from seven real KN-series floppies (`KN7000/floppy-archive/*.zip`, six
files each: `.CMP .LSW .MSP .SEQ .SQF .TM`). The `.SEQ` song files are built from the SAME
256-byte cell: a 0x80 marker at +0, two u16 little-endian fields at +1 and +3, payload after.

Three variants of one container, differing in how a pointer is resolved and where the payload
starts. Reading one with another's rules produces plausible garbage, which is why this table
matters more than it looks:

| variant | markers | "none" | pointer means | payload |
|---|---|---|---|---|
| IC19 styles | 0x80 at +0, 0x87 at +5 and +0xFF | 0xFFFF | section nibble + block index **relative to the section's first cell block** | +0x06, 249 B |
| demo songs (ROM) | 0x80 at +0 only | 0xFFFF | cell number; cell *c* at `0x800 + (c-1)*256` | +0x05, 251 B |
| disk `.SEQ` | 0x80 at +0 only | **0x0000** | plain block index within the file | +0x05 |

Measured over 596 cells in 7 disk files: **every one of the 1087 in-range pointers lands on a
real cell**, and each file has exactly one pointer that lands outside itself.

⚠ **On disk the two fields are NOT a prev/next pair.** Only 48 of 540 forward links have their
target pointing back, against 514 of 514 in the IC19 styles. So the field at +1 is something else
here -- and this is exactly the trap that cost three wrong readings of the IC19 header earlier
today. It is recorded unresolved rather than guessed.

Reproduce: `scripts/analysis/disk_seq_container.py <dir>`.

The other five file types are untouched: `.SQF` begins `5A 5A 5A 5A` and carries ASCII names,
`.CMP` and `.MSP` both begin `"LKE"` then `5A 5A 5A` (and `scripts/analysis/extract_composer_msp.py`
already reads the latter), `.LSW` begins `5A 5A`, and `.TM` begins with the ASCII string
`"KN1500 SOUND RAM"` -- which is itself a finding, since these are KN7000-era disks.
