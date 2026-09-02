#!/usr/bin/env python3
"""prom_b_small_span_gate_visibility.py

QUESTION IT ANSWERS
-------------------
"Can the byte gate SEE the tiny conversions lane promB6 made?"

A green gate is least informative exactly where this lane worked.  A 1-, 2- or
3-byte span has so little to get wrong that a pass could be accidental -- and a
stale object would pass too, certifying nothing.  So this tool perturbs ONE BYTE
of one of those conversions, runs the real gate, and requires it to go RED **at
that byte's address**.  Then it restores the file and requires green again.

    python3 scripts/analysis/prom_b_small_span_gate_visibility.py

Run from `wsa1/`.  Exits non-zero if any probe fails to make the gate red, or if
the tree is not green before and after.  Result 2026-09-02: 4 of 4 probes red at
the expected address, tree green before and after.

Each probe names the smallest, least-informative kind of conversion in the lane:
a 1-byte `ret` pad, a 2-byte routine trailer, the 3-byte lead of a pointer-array
entry the reachability walk cut in half, and a display-list record tail.
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")
GATE = os.path.join(ROOT, "scripts", "analysis", "assert_byte_identical.py")

# (ROM address of the perturbed byte, the exact source line, the poisoned line)
PROBES = [
    (0x0001B4, "\t.byte\t0x0E\t; F001B4  routine trailer",
               "\t.byte\t0x0F\t; F001B4  routine trailer"),
    (0x00003A, "\t.byte\t0x00, 0x00\t; F0003A  routine trailer",
               "\t.byte\t0x01, 0x00\t; F0003A  routine trailer"),
    (0x0054EA, "\t.byte\t0x54, 0xF0, 0x00\t; F054EA  top 3 bytes of the entry at F054E9 = 0x00F054D9",
               "\t.byte\t0x55, 0xF0, 0x00\t; F054EA  top 3 bytes of the entry at F054E9 = 0x00F054D9"),
    (0x034C9B, "\t.byte\t0x08, 0x20, 0x17, 0x28, 0x00, 0x4B, 0x00\t; F34C9B  rest of the op 0x0E record that starts at F34C9A",
               "\t.byte\t0x09, 0x20, 0x17, 0x28, 0x00, 0x4B, 0x00\t; F34C9B  rest of the op 0x0E record that starts at F34C9A"),
]


def gate():
    p = subprocess.run([sys.executable, GATE], capture_output=True, text=True, cwd=ROOT)
    return p.returncode, p.stdout + p.stderr


def swap(old, new):
    s = open(SRC, encoding="latin-1").read()
    if s.count(old) != 1:
        sys.exit("expected exactly one copy of:\n%r\nfound %d" % (old, s.count(old)))
    open(SRC, "w", encoding="latin-1").write(s.replace(old, new))


def main():
    rc, out = gate()
    if rc != 0:
        sys.exit("the tree is not green to begin with:\n" + out)
    print("baseline: green")
    fails = 0
    for addr, good, bad in PROBES:
        swap(good, bad)
        rc, out = gate()
        swap(bad, good)
        m = re.search(r'wsa1_prom_b\.ic13: (\d+) byte\(s\), first at 0x([0-9A-Fa-f]+)', out)
        ok = rc != 0 and m and int(m.group(2), 16) == addr
        print("%-6s poison at 0x%06X -> %s" % (
            "ok" if ok else "FAIL", addr,
            ("gate red, first differing byte 0x%s" % m.group(2)) if m else
            "gate did NOT report a prom_b difference"))
        fails += not ok
    rc, out = gate()
    print("restored: %s" % ("green" if rc == 0 else "NOT GREEN\n" + out))
    if rc != 0:
        fails += 1
    print("\n%d of %d probes made the gate red at the expected address"
          % (len(PROBES) - fails, len(PROBES)))
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
