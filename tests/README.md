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

## Extending this

Every subsystem graded SPECIFIED should get one of these. A grade that no one can run is an
opinion; a grade with a failing test is a bug report; a grade with a passing test is evidence.
