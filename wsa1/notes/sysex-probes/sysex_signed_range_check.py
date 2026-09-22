#!/usr/bin/env python3
"""Does each sound parameter's HEX span agree with the decimal span printed beside it?

QUESTION IT ANSWERS
  The guide's sound-parameter tables give every parameter twice over: a RANGE
  in hex (its "DATA (HEX)" column) and the same range in decimal (its
  "DATA (DEC)" column).  The two are redundant, so they check each other --
  which makes any row where they disagree either a transcription slip in
  `sound_layout.json` or a slip in the printed guide.

  This asks the arithmetic question on every row that carries both, and names
  the rows that fail.

  IT FOUND ONE.  DRUM SOUND / NOTE TONE DATA / PITCH KEY SHIFT (parameter 1AE
  in the AREA frame, which the guide prints as 016 / 028 in the NOTE frame)
  gives `E8~18` beside `- 50~+ 50`.  E8..18 read as a signed byte is -24..+24.
  The SAME parameter in NORMAL SOUND TONE DATA (0DD / 12E / 17F / 1D0) gives
  `E8~18` beside `- 24~+ 24`.

  The guide itself is what disagrees: both rows were rendered and read, and
  both say what `sound_layout.json` says they say.

      DRUM   p55, NOTE TONE DATA (1st, 2nd)
             016 | 028 | PITCH | KEY SHIFT | BP7~0 | E8~18 | - 50~+ 50
      NORMAL p50, TONE DATA (1st, 2nd, 3rd, 4th)
             0DD | 12E | 17F | 1D0 | PITCH | KEY SHIFT | BP7~0 | E8~18 | - 24~+ 24

  E8..18 is the arithmetic that holds, and the neighbouring rows in the DRUM
  table (LEVEL TOUCH DEPTH, CE~32, `- 50~+ 50`) are where the `50` came from:
  every other signed row on that page is CE~32.  So the hex is right and the
  guide's decimal column is the typo.

POSITIVE CONTROL
  The check is not "nothing fired".  Rows that DO agree are counted and printed,
  including three more PITCH KEY SHIFT rows with a different span (C4~3C,
  -60..+60) and every CE~32 row.  A run that reports no passes at all would mean
  the matcher is broken, and the exit code says so.

COVERAGE, STATED
  This reads `sound_layout.json` only -- the transcription of the guide's
  NORMAL SOUND and DRUM SOUND tables.  It cannot see a row whose note is prose
  ("0.2 per cent per step"), a row with no decimal span at all, or a parameter
  outside those two areas.  The rows it cannot judge are counted and printed
  too, so the coverage is visible rather than implied.

SIGNAL BEING READ
  `sound_layout.json`: each entry's `range` ("E8-18") against its `note`
  ("-24 to +24").  A hex span is read as an unsigned byte pair AND as a signed
  byte pair, and the row passes if EITHER reading reproduces the decimal span.

RUN
  python3 wsa1/notes/sysex-probes/sysex_signed_range_check.py

PASS CRITERION
  At least one row is judged, at least one row passes (the control), and no row
  fails.  Exits non-zero while the guide's DRUM KEY SHIFT row stands, which is
  the point: the failure is the finding, not a defect in the probe.
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
LAYOUT = os.path.join(HERE, "sound_layout.json")

HEX_SPAN = re.compile(r"^([0-9A-Fa-f]{2})-([0-9A-Fa-f]{2})$")
# "-24 to +24", "-128 to +127", "0 to 127".  Anything wordier is prose and is
# not judged.
DEC_SPAN = re.compile(r"^([+-]?\d+)\s+to\s+([+-]?\d+)$")


def signed(b):
    return b - 256 if b >= 0x80 else b


def walk(node, path, out):
    """Yield (path, entry) for every parameter entry, at any nesting depth."""
    for block in node.get("blocks", []):
        here = path + [block["name"]]
        for entry in block.get("entries", []):
            out.append((" / ".join(here), entry))
        walk(block, here, out)


def main():
    layout = json.load(open(LAYOUT))
    entries = []
    for area in layout["areas"]:
        walk(area, [area["name"]], entries)

    judged, passed, failed, skipped = 0, [], [], 0
    for where, e in entries:
        m_hex = HEX_SPAN.match((e.get("range") or "").strip())
        m_dec = DEC_SPAN.match((e.get("note") or "").strip())
        if not (m_hex and m_dec):
            skipped += 1
            continue
        judged += 1
        lo, hi = int(m_hex.group(1), 16), int(m_hex.group(2), 16)
        want = (int(m_dec.group(1)), int(m_dec.group(2)))
        unsigned_ok = (lo, hi) == want
        signed_ok = (signed(lo), signed(hi)) == want
        row = (e.get("at"), where, e.get("name"), e["range"], e["note"])
        (passed if (unsigned_ok or signed_ok) else failed).append(row)

    print("\nHEX SPAN vs DECIMAL SPAN, sound_layout.json")
    print("  %d parameter entries, %d carry both spans, %d do not"
          % (len(entries), judged, skipped))
    print("\nPASSED (%d) -- the control: these rows agree" % len(passed))
    for at, where, name, rng, note in passed:
        print("  %-4s %-60s %-8s %s" % (at, (where + " / " + name)[:60], rng, note))
    print("\nFAILED (%d)" % len(failed))
    for at, where, name, rng, note in failed:
        lo, hi = int(rng[:2], 16), int(rng[3:], 16)
        print("  %-4s %s / %s" % (at, where, name))
        print("       guide prints  range %s  note '%s'" % (rng, note))
        print("       signed byte   %s..%s     unsigned  %d..%d"
              % (signed(lo), signed(hi), lo, hi))

    assert judged, "no row carried both spans; the matcher is broken"
    assert passed, "no row passed; the matcher is broken, not the data"
    if failed:
        print("\n%d row(s) disagree with themselves." % len(failed))
        return 1
    print("\nOK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
