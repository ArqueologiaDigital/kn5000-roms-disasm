#!/usr/bin/env python3
"""Does the ROM accept exactly the dump sizes Technics published?

QUESTION IT ANSWERS
  The reference's bulk-dump table was decoded from the program: the eight
  (ADR, SIZ) pairs the instrument matches literally on reception.  Three of the
  four categories were then confirmed against a capture from a real machine.
  The fourth, SEQUENCER, could not be -- the capture came from a rack, and a
  rack refuses that category.

  It does not need a capture.  Technics printed the sizes, on page 45 of the
  Reference Guide, in a table headed "SIZ of data dump area".  This asserts that
  the set the ROM accepts and the set the guide prints are the same set,
  SEQUENCER included.  Two sources, one a disassembly and one a printed book,
  that share no path at all.

WHAT THAT DOES AND DOES NOT SETTLE
  It settles the ADDRESSES AND LENGTHS of every category, including the one no
  capture covers, and the guide's own "SEQUENCER : WSA1 only" note confirms the
  model restriction the feature table gives.

  It does not settle FRAME-LEVEL behaviour for SEQUENCER -- checksums,
  continuation, the acknowledgement handshake.  Those are verified by capture on
  the other three categories, and the program runs all four through one code
  path, but no SEQUENCER transfer has been observed.

SIGNAL BEING READ
  The stdout of `sysex_dump_categories.py`, and the guide's table transcribed
  below.  Page 45 is image-only and was rendered and read.

RUN
  python3 wsa1/notes/sysex-probes/sysex_published_sizes.py

PASS CRITERION
  The two sets of sizes are equal, area by area, and OK.
"""
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CATS = os.path.join(HERE, "sysex_dump_categories.py")

# --- transcribed from the guide, page 45, "SIZ of data dump area" -----------
# Area name as the guide prints it, then its subareas' SIZ bytes in order.
# "Variable" is the guide's own word for the last SEQUENCER block.
PUBLISHED = {
    "SOUND MEMORY": ["10 00 00"],
    "PANEL":        ["00 00 20", "00 12 60"],
    "COMBINATION":  ["00 06 00", "05 40 00"],
    "SEQUENCER":    ["00 18 00", "01 70 00", "Variable"],
}
# "ADR of data request concerns the data dump", same page.
PUBLISHED_REQUEST = {"SOUND MEMORY": "20 00 00", "PANEL": "40 00 00",
                     "COMBINATION": "50 00 00", "SEQUENCER": "60 00 00"}
# The guide prints this beside the request table.
PUBLISHED_NOTE = "SEQUENCER : WSA1 only"

# the menu's names for the guide's areas
AREA_OF = {"SOUND": "SOUND MEMORY", "SYSTEM,PART & MIDI": "PANEL",
           "COMBINATION": "COMBINATION", "SEQUENCER": "SEQUENCER"}

ROW = re.compile(r"^\s{2}(\S.*?)\s{2,}(\d)\s+((?:[0-9A-F]{2} ?)+?)\s*->")


def rom_sizes():
    out = subprocess.run([sys.executable, CATS], capture_output=True,
                         text=True, check=True).stdout
    assert "Accepted on RECEIVE" in out, "the categories probe changed shape"
    body = out.split("Accepted on RECEIVE", 1)[1]
    got = {}
    for line in body.splitlines():
        m = ROW.match(line)
        if not m:
            continue
        cat, part, byts = m.group(1).strip(), int(m.group(2)), m.group(3).split()
        area = AREA_OF.get(cat)
        assert area, "unknown category %r" % cat
        siz = " ".join(byts[3:6]) if len(byts) >= 6 else "Variable"
        got.setdefault(area, {})[part] = siz
    return {a: [v[k] for k in sorted(v)] for a, v in got.items()}


def main():
    got = rom_sizes()
    print("\nDUMP SIZES: what the ROM accepts, against what Technics printed")
    print("  %-14s %-28s %s" % ("area", "ROM (decoded)", "guide, page 45"))
    ok = True
    for area in sorted(PUBLISHED):
        mine = got.get(area, [])
        theirs = PUBLISHED[area]
        mark = "  " if mine == theirs else "!!"
        print("%s%-14s %-28s %s" % (mark, area, " / ".join(mine), " / ".join(theirs)))
        ok = ok and mine == theirs
    assert ok, "the ROM and the published table disagree on a dump size"
    assert set(got) == set(PUBLISHED), \
        "the two sources do not list the same areas: %s vs %s" % (
            sorted(got), sorted(PUBLISHED))
    print("\n  the two sets are identical, area by area --- SEQUENCER included,")
    print("  which no capture available here can cover")
    print("\n  the guide prints, beside its request table: %r" % PUBLISHED_NOTE)
    print("  which is the same restriction the feature table gives the rack")
    print("OK")


if __name__ == "__main__":
    main()
