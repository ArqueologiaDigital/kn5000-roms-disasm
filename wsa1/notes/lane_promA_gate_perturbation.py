#!/usr/bin/env python3
"""Can the byte gate SEE the promA lane's conversions?  Prove it by breaking them.

QUESTION IT ANSWERS: "make gate-wsa1 is green after 2,542 bytes were converted.
Would it have gone RED if one of those bytes were wrong?"

WHY THIS EXISTS.  A green gate is not evidence unless it has been shown to fail
on the very edit it is supposed to certify.  This tree has already been burned by
objects built from stale prerequisites certifying nothing.  So: for one line in
each converted span -- and for both a CODE line and a DATA line in the largest
span -- flip one character in prom_a/wsa1_prom_a.s, rebuild, and check that
scripts/analysis/assert_byte_identical.py reports a difference AT THE EXPECTED
FILE OFFSET.  Then restore and confirm green again.

The source file is written back byte-for-byte except for the one edit; the script
restores from an in-memory copy in a `finally`, and prints a warning if the file
on disk does not match the original at the end.

RUN (from the wsa1/ directory; takes a few minutes, one rebuild per case)
    python3 notes/lane_promA_gate_perturbation.py
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "prom_a", "wsa1_prom_a.s")
GATE = os.path.join(ROOT, "scripts", "analysis", "assert_byte_identical.py")
BASE = 0xF80000

# (converted span, address of the line to break, needle, replacement,
#  file offset the gate must name)
CASES = [
    ("0xF96504 +1889 (code)",  0xF96508, "inc 1,XIX", "inc 2,XIX", 0x016509),
    ("0xF96504 +1889 (data)",  0xF9667A, "0x01, 0x02, 0x7f", "0x01, 0x02, 0x7e", 0x01667C),
    ("0xF98DE5 +539",          0xF98DE5, "0x00f2ddbd", "0x00f2ddbc", 0x018DE5),
    ("0xF8E77C +81",           0xF8E77C, "0x00f8e68b", "0x00f8e68a", 0x00E77C),
    ("0xFDFFDF +33",           0xFDFFDF, "0x08, 0x04", "0x09, 0x04", 0x05FFDF),
]


def line_index(lines, addr, needle):
    pat = re.compile(r';\s*%06X\b' % addr)
    hits = [i for i, l in enumerate(lines) if pat.search(l) and needle in l]
    if len(hits) != 1:
        sys.exit("expected exactly one line at 0x%06X containing %r, found %d"
                 % (addr, needle, len(hits)))
    return hits[0]


def gate():
    r = subprocess.run([sys.executable, GATE], cwd=ROOT,
                       capture_output=True, text=True)
    m = re.search(r'first at 0x([0-9A-F]+)', r.stdout)
    return r.returncode, (int(m.group(1), 16) if m else None), r.stdout


def main():
    original = open(SRC, encoding="utf-8").read()
    ok_all = True
    try:
        rc, _off, _out = gate()
        print("baseline gate: %s" % ("GREEN" if rc == 0 else "RED (unexpected)"))
        if rc != 0:
            return 2
        for name, addr, needle, repl, want in CASES:
            lines = original.split("\n")
            i = line_index(lines, addr, needle)
            lines[i] = lines[i].replace(needle, repl, 1)
            open(SRC, "w", encoding="utf-8").write("\n".join(lines))
            rc, off, _out = gate()
            good = rc != 0 and off == want
            ok_all &= good
            print("  [%s] %-24s broke 0x%06X -> gate %s%s"
                  % ("ok" if good else "FAIL", name, addr,
                     "RED at file offset 0x%06X" % off if off is not None
                     else ("GREEN -- THE GATE IS BLIND HERE" if rc == 0 else "RED, no offset"),
                     "" if good else "  (expected 0x%06X)" % want))
            open(SRC, "w", encoding="utf-8").write(original)
    finally:
        open(SRC, "w", encoding="utf-8").write(original)
    if open(SRC, encoding="utf-8").read() != original:
        sys.exit("!! SOURCE NOT RESTORED -- fix by hand before committing")
    rc, _off, _out = gate()
    print("restored gate:  %s" % ("GREEN" if rc == 0 else "RED -- restore failed"))
    return 0 if (ok_all and rc == 0) else 1


if __name__ == "__main__":
    sys.exit(main())
