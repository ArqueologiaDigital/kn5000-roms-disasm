#!/usr/bin/env python3
"""ship_compare.py -- regression comparison for shipping the §133 readings.

ACT 0x0D and ACT 0x0E carry 829 of the corpus's 6282 ALU words (13.2%) and appear
in ALL 91 IC311 programs, so setting them in the default is a corpus-wide change,
not a PARAMETRIC EQ one.  Before shipping, check that:

  * every frame still CLOSES (0 traps, 0 partials) -- a reading that makes frames
    trap would be discarded silently by the device and read as "quieter", not as
    "broken";
  * the only currently-audible unit (1, the reverb on DO2) still produces output;
  * what changes on DO1 (unit 0 / PARAMETRIC EQ) is stated rather than assumed.

  python3 ship_compare.py <log> [<log> ...]
"""
import re
import sys

PATS = [
    ("presentation", re.compile(r"PER-UNIT PRESENTATION: (.*)")),
    ("frames run",   re.compile(r"frames run\s+(\d+)")),
    ("trapped",      re.compile(r"frames that TRAPPED\s+(\S+ \(\S+ %\))")),
    ("last frame",   re.compile(r"last frame: (\d+ slots = .*)")),
    ("tracking",     re.compile(r"§54 TRACKING: (.*)")),
    ("verdict",      re.compile(r"VERDICT: (.*?)\s\s")),
    ("datum peak",   re.compile(r"PRESENTATION WORDS: (.*)")),
    ("rebase",       re.compile(r"rebase \(mask bit 38 = \d\): FIRED (\d+)")),
    ("act0d fired",  re.compile(r"ACT 0x0D .*?(\d+)\s*$")),
]

for path in sys.argv[1:]:
    print("=" * 78)
    print(path.rsplit("/", 1)[-1])
    print("=" * 78)
    txt = open(path, errors="ignore").read()
    m = re.search(r"UPD6383_SPEC = (0x[0-9A-F]+)", txt)
    if m:
        v = int(m.group(1), 16)
        print("  mask %s  ->  sel0D=%d sel0E=%d f4=%d f5=%d supp=%d rebase=%d"
              % (m.group(1), (v >> 42) & 7, (v >> 45) & 7, (v >> 48) & 3,
                 (v >> 50) & 3, (v >> 52) & 1, (v >> 38) & 1))
    for name, pat in PATS:
        mm = pat.search(txt)
        if mm:
            print("  %-13s %s" % (name + ":", mm.group(1).strip()[:150]))
    print()
