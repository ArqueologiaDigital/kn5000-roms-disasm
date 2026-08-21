# Executable completeness tests

`DISASSEMBLY-COMPLETENESS-SPEC.md` defines L5 as: **an independent implementer could build a
working implementation from the documentation alone, without reading the disassembly.**

That is stated as a bar to be judged. It does not have to be. It can be RUN.

## `l5_reimplement_style_format.py`

    python3 tests/l5_reimplement_style_format.py original_ROMs/kn5000_custom_data.ic19

A reader of `docs/accompaniment-style-format.md` and nothing else. It shares no code with
`scripts/build/style_events.py` -- every constant and rule in it is quoted from the document, with
the quotes left in as comments so a reviewer can check that nothing was smuggled in from the
disassembly. If the document is wrong or incomplete, this fails.

It currently reproduces the corpus exactly:

    cells   1564
    chains  1050
    events  50245   malformed 0
    names   210

Those are the same figures `scripts/analysis/style_cell_chains.py` derives from the ROM by a
different route. **This is what an L5 grade should mean**: not "a reviewer judged the prose
adequate", but "an implementation built only from the prose agrees with the artefact".

## What it does NOT show

The container is sufficient; the SEMANTICS are not complete. NOTE2's two trailing fields, CTL1
and CTL2 have no established meaning, and the document says so. A test like this can prove a
format description sufficient to READ the data. It cannot prove the description of what the data
MEANS, because there is nothing to compare that against but the machine.

## `l5_reimplement_demo_format.py`

    python3 tests/l5_reimplement_demo_format.py

A reader of `table_data/includes/demo_presets/README.md` and nothing else, over the 19 committed
demo songs.

**This one FAILED, three times, and each failure was a real defect in the document or in the
shipping converter.**

1. **Payload length.** The document said a cell payload is `[5..255]` = "250 bytes". `[5..255]`
   inclusive is 251. Pinned from both sides: 588 short notes at 250, zero at 251, and 1009 spurious
   `0x80`s at 252. `scripts/build/demo_preset_to_midi.py` carried the same 250.
2. **The terminator was backwards.** The document said `0x83` ends a track and `0x82` carries text.
   Measured: **`0x83` occurs zero times in all 19 songs and every one of the 168 tracks contains
   `0x82`**, and the firmware parser ends on `0x82`. The converter's `return on 0x83` therefore
   never fired, so it parsed every track past its real end. This also manufactured a spurious list
   of *eleven* undocumented statuses that were simply bytes after the terminator.
3. **The running-status rule was missing.** The format section marked `0x9n` "(repeatable)" and
   never said what that meant. A parser without the rule silently loses most of the notes.

All three are fixed. The test now implements the full documented grammar and reports **67,300
events with 36 malformed** -- the 36 being exactly the three genuinely undocumented statuses
(`0x80` x16, `0x85` x10, `0x86` x10), each of which has an explicit case in
`SetWall_ParseStream_MainLoop`. No partial or short runs remain.

That residue is the real open item, and the test failing loudly on precisely it -- and on nothing
else -- is what a good L5 test looks like.

## `l5_reimplement_slide4k.py`

    python3 tests/l5_reimplement_slide4k.py

Implements the SLIDE4K codec from `demo_presets/README.md` and nothing else. **19 of 19 songs
decompress byte-exactly** -- so that subsystem's SPECIFIED grade is now evidence rather than
judgement, which is the good outcome for a test like this and worth having explicitly.

It still found a gap: the document's block format (magic + size + payload) describes the ROM
block, while the committed `*_compressed.bin` are payload-only, because the header is emitted by
the assembler. An implementer following the prose asserts on a missing magic. Recorded in that
README.

## Extending this

Every subsystem graded SPECIFIED should get one of these. A grade that no one can run is an
opinion; a grade with a failing test is a bug report; a grade with a passing test is evidence.
