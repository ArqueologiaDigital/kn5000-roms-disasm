# Reviewed readings of the `[nakarest] purpose not established` slices

**What question this answers.** The naka_*.bin blobs of the KN5000 main CPU are compiled C (`v10/maincpu/ui_widgets/naka_*.c`).
Their asm side cuts them into labelled slices:

    Label: .incbin "includes/generated/<blob>.bin", off, size

Several hundred slices still carry a `; [nakarest] purpose not established` note, and their C members are anonymous
`field_XXXX` words. For each slice in a `reviewed-*.json` file, this directory records what the slice IS, read from the
code that reads it.

Each JSON object is one slice (keys as `scripts/converters/nakarest_reviewed_slices.py` documents):
- `label`, `asm`, `size`: the slice as it stood. The label is current, and is looked up in every tree.
- `verdict`: `type`, or `refuse` with `why_refused`.
- `new_label`, `ctype`, `dims`, `struct_fields`, `cdoc`, `header`: the typing and the asm header. Alternatively
  `pieces`, when one slice holds several objects.
- `evidence`: `file:line` `instruction` -- what it shows (paths relative to `v10/maincpu`).
- `check`: a Python expression over the slice's bytes `b` asserting the property the reading rests on. The converter
  evaluates it on every tree's own bytes and skips a tree where it is false.
- `basis`: the kind of evidence (reader code, reader code + index meaning, ...).

**How the readings were made.** The batches were triaged by read-only passes. Each pass read the readers named in the
`[nakarest]` note, then the instructions around each reference: how the base is loaded, the access width, the index
scaling, the bounds check, and what the value is used for. Every proposal was then checked against its cited lines
before it went into a `reviewed-*.json` file. A proposal whose evidence did not show the claim was turned into a
refusal, or corrected, and the file says which.

**Apply** (repository root, built tree):

    python3 scripts/converters/nakarest_reviewed_slices.py            # dry run: what each tree would get
    python3 scripts/converters/nakarest_reviewed_slices.py --apply
    scripts/build/regenerate_v7_c_divergence.py --apply                # BEFORE make
    make all && make gate-all

The byte gate certifies that no compiled byte changed.
