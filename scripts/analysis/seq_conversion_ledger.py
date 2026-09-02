#!/usr/bin/env python3
r"""HOW MUCH OF EACH CONVERTED REGION WAS PREVIOUSLY SPELLED AS INSTRUCTIONS?
(lane v10seq, 2026-09-02)

QUESTION ANSWERED
-----------------
This lane re-typed several v10/maincpu/sequencer regions from a mixture of
instruction mnemonics and `.byte` residue into typed data.  Two different debts
were paid and they must not be added together carelessly:

  * DATA-AS-CODE retired -- bytes that were written as instruction mnemonics in
    a region that is really data.  Invisible to every `.byte` counter, and the
    byte gate cannot object to either spelling.
  * `.byte` operands RE-TYPED -- bytes that were already `.byte` and are now
    `.short`/`.long`/an aligned record grid with a stated shape.

METHOD
------
For each region, the SIZE comes from the linked build (label to label) and is
supplied on the command line; the OLD `.byte` operand count is read out of the
pre-conversion source with `git show <rev>:<path>`, counting operands between
the region's label and the next label definition.  Everything in the region
that was not a `.byte` operand was an instruction mnemonic (or `.zero`), so

    mnemonic bytes = size - old_byte_operands

No address map is needed for the old tree, which is why this works after the
tree has already moved.

`.zero N` runs are counted in their own column, not as mnemonics: they were
already typed data.  A real subroutine living inside a data block (two of the
six regions have one, and both were left alone) is subtracted from the size and
its own `.byte` residue from the operand count, so its mnemonics are never
credited as data-as-code retired.

RUN
    python3 scripts/analysis/seq_conversion_ledger.py --before a99564a6
"""
import argparse
import re
import subprocess

LABEL_RE = re.compile(r"^([A-Za-z_.$][\w.$]*):")

# region, file, label, size in bytes as linked (label to the next label), and
# (kept_code_bytes, kept_code_byte_operands): a real subroutine that lives
# INSIDE the block and was deliberately NOT converted, so its mnemonics must
# not be counted as data-as-code retired.
REGIONS = [
    ("AccVoice_ParamIndexData", "v10/maincpu/sequencer/accompaniment_engine.s",
     "AccVoice_ParamIndexData", 115, 0, 0),
    ("Voice_NoteChannelTable1", "v10/maincpu/sequencer/seq_event_playback.s",
     "Voice_NoteChannelTable1", 1343, 29, 3),   # +0x422 routine, kept
    ("Voice_NoteChannelTable2", "v10/maincpu/sequencer/seq_event_playback.s",
     "Voice_NoteChannelTable2", 1026, 0, 0),
    ("Voice_BankIndexTable", "v10/maincpu/sequencer/seq_event_playback.s",
     "Voice_BankIndexTable", 36, 0, 0),
    ("Voice_NoteParamTable", "v10/maincpu/sequencer/seq_event_playback.s",
     "Voice_NoteParamTable", 1026, 0, 0),
    ("AccVoice_OffsetTable", "v10/maincpu/sequencer/accompaniment_engine.s",
     "AccVoice_OffsetTable", 256, 0, 0),
    ("AccStyle_TempoMultiplierTable", "v10/maincpu/sequencer/accompaniment_engine.s",
     "AccStyle_TempoMultiplierTable", 32, 0, 0),
    ("AccVoice_IndexedTableLookup_BaseOffsets",
     "v10/maincpu/sequencer/accompaniment_engine.s",
     "AccVoice_IndexedTableLookup_BaseOffsets", 744, 38, 3),  # +0x2A2 routine, kept
]


def old_region(rev, path, label):
    blob = subprocess.run(["git", "show", "%s:%s" % (rev, path)],
                          capture_output=True, check=True).stdout.decode("latin-1")
    lines = blob.split("\n")
    start = None
    for i, raw in enumerate(lines):
        s = raw.split(";", 1)[0].strip()
        m = LABEL_RE.match(s)
        if m and m.group(1) == label:
            start = i + 1
            break
    if start is None:
        raise SystemExit("label %s not found at %s" % (label, rev))
    nbyte = nzero = 0
    for raw in lines[start:]:
        s = raw.split(";", 1)[0].strip()
        m = LABEL_RE.match(s)
        if m and s.split(":", 1)[1].strip() == "":
            break
        if s.startswith(".byte"):
            nbyte += len([v for v in s[5:].split(",") if v.strip()])
        elif s.startswith(".zero"):
            nzero += int(s.split()[1], 0)
    return nbyte, nzero


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--before", required=True)
    a = ap.parse_args()
    print("%-42s %6s %8s %6s %6s %9s" % ("region", "size", "was.byte", ".zero",
                                         "kept", "was mnem"))
    tot = totb = totz = totm = 0
    for name, path, label, size, keep, keepb in REGIONS:
        nb, nz = old_region(a.before, path, label)
        nb -= keepb                       # residue inside the kept subroutine
        size -= keep                      # the kept subroutine is not converted
        mn = size - nb - nz
        print("%-42s %6d %8d %6d %6d %9d" % (name, size, nb, nz, keep, mn))
        tot += size; totb += nb; totz += nz; totm += mn
    print("%-42s %6d %8d %6d %6s %9d" % ("TOTAL", tot, totb, totz, "", totm))
    print()
    print("data-as-code retired (bytes that were instruction mnemonics): %d B" % totm)
    print("`.zero` bytes folded into the typed layout (were already data): %d B" % totz)
    print("`.byte` operands re-typed into .short/.long/record grids: %d B" % totb)


if __name__ == "__main__":
    main()
