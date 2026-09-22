#!/usr/bin/env python3
"""Do the guide's per-instance parameter columns advance by the block's stride?

QUESTION IT ANSWERS
  Where a block repeats, the guide prints one column of parameter numbers per
  instance: NORMAL SOUND / TONE DATA has "1st, 2nd, 3rd, 4th" and DRUM SOUND /
  NOTE TONE DATA has "1st, 2nd".  Those columns are pure redundancy -- the nth
  column must be the first plus (n-1) times the block's stride, on every row --
  so they check both the transcription and the printing.

  IT FOUND A MISPRINT.  On DRUM page 55, NOTE TONE DATA (1st, 2nd), the 2nd
  column starts at 024 and runs 024 025 026 027 028 029 02A, then jumps to
  030 031 032 ... 03F.  A 23-byte block starting at 012 puts its second
  instance at 029, so the tail (030..03F) is right and the first seven entries
  are five too low.  The jump is inside the column: 02A is followed by 030.

  The 23-byte stride is not in doubt.  The table's own 1st column spans
  012..028 inclusive, which is 23, and NOTE DATA's 150-byte stride only adds up
  as 18 + 2*23 + 2*43 -- the 150 and the area total behind it came from the
  firmware decode, not from this page (see sysex_sound_layout.py).

  `sound_layout.json` is UNAFFECTED, and for a stated reason: its method is to
  transcribe the first column only and derive the rest from the stride.  That
  rule was written after a different column-reading mistake; here it is what
  kept the guide's own misprint out of the data.

POSITIVE CONTROL
  The same check is run on NORMAL SOUND / TONE DATA, whose four columns are
  printed correctly and advance by exactly 81 on every row.  Those rows pass in
  the same run, so a silent matcher would be visible.

COVERAGE, STATED
  Two tables: the two whose repeated-instance columns were rendered and read
  (guide pages 50/51 and 55).  The guide prints per-instance columns elsewhere --
  MODELING DATA, NOTE MODELING DATA -- and those were not transcribed here, so
  this says nothing about them.

SIGNAL BEING READ
  The columns as printed, transcribed below from 200-dpi renders of guide pages
  50, 51 and 55, against the stride each block has in `sound_layout.json`.

RUN
  python3 wsa1/notes/sysex-probes/sysex_repeat_numbering_check.py

PASS CRITERION
  Every row of every column equals first + (n-1)*stride.  Exits non-zero while
  the guide's DRUM 2nd column stands, which is the finding.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
LAYOUT = os.path.join(HERE, "sound_layout.json")

# As printed.  One tuple per row, one entry per instance column.
TABLES = [
    ("NORMAL SOUND", "TONE DATA", 50, [
        ("ATTRIBUTE DELAY", "0D9", "12A", "17B", "1CC"),
        ("ATTRIBUTE PANNING", "0DA", "12B", "17C", "1CD"),
        ("TTN SELECT", "0DB", "12C", "17D", "1CE"),
        ("TONE KIND", "0DC", "12D", "17E", "1CF"),
        ("PITCH KEY SHIFT", "0DD", "12E", "17F", "1D0"),
        ("PITCH DETUNE", "0DE", "12F", "180", "1D1"),
        ("LFO-FM1", "0DF", "130", "181", "1D2"),
        ("ENV TOTAL DEPTH", "0E0", "131", "182", "1D3"),
        # page 51 carries the tail of the same table
        ("FILTER KEY FOLLOW SLOPE", "115", "166", "1B7", "208"),
        ("FILTER ENV CUTOFF ADJUST", "116", "167", "1B8", "209"),
        ("FILTER ENV STOP POINT", "11F", "170", "1C1", "212"),
        ("FILTER ENV TF DEPTH", "121", "172", "1C3", "214"),
    ]),
    ("DRUM SOUND", "NOTE TONE DATA", 55, [
        ("ATTRIBUTE DELAY", "012", "024"),
        ("PANNING", "013", "025"),
        ("TTN SELECT", "014", "026"),
        ("TONE KIND", "015", "027"),
        ("PITCH KEY SHIFT", "016", "028"),
        ("PITCH DETUNE", "017", "029"),
        ("LEVEL VOLUME", "018", "02A"),
        ("TOUCH DEPTH", "019", "030"),
        ("TOUCH CURVE", "01A", "031"),
        ("ATTACK TIME", "01B", "032"),
        ("RELEASE TIME", "020", "037"),
        ("FILTER MODE", "023", "03A"),
        ("FILTER TOUCH DEPTH", "024", "03B"),
        ("FILTER VALUE1", "025", "03C"),
        ("FILTER VALUE4", "028", "03F"),
    ]),
]


def find_block(layout, area_name, block_name):
    def walk(node):
        for b in node.get("blocks", []):
            if b["name"] == block_name:
                return b
            hit = walk(b)
            if hit:
                return hit
        return None
    for area in layout["areas"]:
        if area["name"] == area_name:
            return walk(area)
    raise SystemExit("no area %s" % area_name)


def main():
    layout = json.load(open(LAYOUT))
    rc = 0
    for area_name, block_name, page, rows in TABLES:
        block = find_block(layout, area_name, block_name)
        stride = block["stride"]
        span = int(block["to"], 16) - int(block["at"], 16) + 1
        print("\n%s / %s   (guide p%d)" % (area_name, block_name, page))
        print("  sound_layout.json: %s..%s = %d bytes, stride %d, count %d"
              % (block["at"], block["to"], span, stride, block["count"]))
        assert span == stride, \
            "%s spans %d bytes but strides %d" % (block_name, span, stride)
        good = bad = 0
        for row in rows:
            name, first = row[0], int(row[1], 16)
            for n, printed in enumerate(row[2:], start=1):
                want = first + n * stride
                got = int(printed, 16)
                if got == want:
                    good += 1
                else:
                    bad += 1
                    print("    %-20s column %d prints %s, stride gives %03X"
                          % (name, n + 1, printed, want))
        print("  %d column entries agree, %d do not" % (good, bad))
        assert good, "nothing agreed; the matcher is broken, not the guide"
        rc |= 1 if bad else 0

    if rc:
        print("\nThe guide misprints a column. sound_layout.json takes the "
              "first column only, so it is unaffected.")
        return 1
    print("\nOK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
