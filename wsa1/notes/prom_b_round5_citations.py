#!/usr/bin/env python3
"""Does every instruction QUOTED in round 5's findings note actually decode there?

QUESTION IT ANSWERS
  This tree's standing defect list includes "~20 call sites cited one byte past
  the instruction".  A note that prints `0xF105F0  add XWA,0x00f12f24` when the
  instruction is at 0xF1060F is wrong in a way no gate can see, and the first
  draft of notes/FINDINGS-prom_b-f0ea9f-module.md did exactly that.

  So: parse the note's own fenced code blocks for lines of the form

      0xADDRESS   <mame text>

  and assert, from the ROM, that the instruction AT that address decodes to that
  text.  The note and this script cannot drift apart, because the script reads
  the note.

RUN
  python3 notes/prom_b_round5_citations.py
  python3 notes/prom_b_round5_citations.py --list
Exit status is non-zero if any citation is wrong -- which is the point.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_b_module_trace as MT                                   # noqa: E402

NOTES = [os.path.join(ROOT, "notes", "FINDINGS-prom_b-f0ea9f-module.md")]
LINE = re.compile(r"^0x([0-9A-F]{6})\s{2,}(\S.*?)\s*$")


def citations():
    out = []
    for path in NOTES:
        infence = False
        for i, ln in enumerate(open(path), 1):
            if ln.startswith("```"):
                infence = not infence
                continue
            if not infence:
                continue
            m = LINE.match(ln.rstrip("\n"))
            if m:
                txt = m.group(2).split(";")[0].strip()
                out.append((os.path.basename(path), i, int(m.group(1), 16), txt))
    return out


def main():
    cites = citations()
    bad = 0
    for f, line, addr, want in cites:
        dec = MT.decode_at(addr)
        got = dec[1].strip() if dec else None
        ok = got == want
        if not ok:
            bad += 1
        if not ok or "--list" in sys.argv:
            print("  %s:%d  0x%06X  %-28s %s"
                  % (f, line, addr, want, "OK" if ok else "MISMATCH got %r" % got))
    print("%d citation(s) checked, %d wrong" % (len(cites), bad))
    if not cites:
        print("⚠ NO citations found -- the note's format changed and this script "
              "is now silently vacuous, which is worse than a failure.")
        return 1
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
