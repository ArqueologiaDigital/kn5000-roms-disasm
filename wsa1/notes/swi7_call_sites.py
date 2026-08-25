#!/usr/bin/env python3
"""Which SWI7 services does the firmware actually CALL, and how often?

QUESTION IT ANSWERS: FINDINGS-fonts.md and the prom_a service headers all end
with "no caller is traced", which leaves "which font does the UI use for what"
wide open.  This asks the cheapest version of that question: `swi 7` is one
byte, 0xFF, and the service number arrives in A, so a call with a literal
service number is the three bytes `21 nn ff` -- `ldb a,nn` then `swi 7`, which
is exactly how prom_a issues its own at 0xF83076.

    python3 notes/swi7_call_sites.py            # the histogram
    python3 notes/swi7_call_sites.py --sites    # every address

⚠ WHAT THIS IS AND IS NOT.  It is a BYTE-PATTERN census, not a disassembly.  It
does not prove any hit is on an instruction boundary, and it cannot see a call
whose service number came from a variable rather than a literal.  So every
count is a LOWER BOUND on calls-with-a-literal, and an over-count of calls.

★ It calibrates its own noise, which is the only reason it is worth quoting.
30 of the 64 slots are DEAD -- they point at a bare RET (notes/
swi7_service_table.py) -- so a hit on a dead slot is a hit no real caller would
make.  The script counts those separately and reports them as the false-positive
floor measured on this same data, rather than asking anyone to assume a rate.
"""
import os
import sys
from collections import Counter, defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
A = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
B = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
DEAD_TARGET = 0xF8EAC6
TABLE = 0xF8E9C6

slot = [int.from_bytes(A[TABLE - 0xF80000 + 4 * i:][:4], "little") for i in range(64)]
dead = {i for i in range(64) if slot[i] == DEAD_TARGET}

hits = Counter()
sites = defaultdict(list)
for tag, lo, img in (("prom_a", 0xF80000, A), ("prom_b", 0xF00000, B)):
    for i in range(len(img) - 2):
        if img[i] == 0x21 and img[i + 2] == 0xFF and img[i + 1] < 0x40:
            n = img[i + 1]
            hits[n] += 1
            sites[n].append((tag, lo + i))

live_hits = sum(v for k, v in hits.items() if k not in dead)
dead_hits = sum(v for k, v in hits.items() if k in dead)
print("`ldb a,n` + `swi 7` byte-pattern census, n < 0x40")
print("  hits on LIVE slots : %d" % live_hits)
print("  hits on DEAD slots : %d   <-- the measured false-positive floor"
      % dead_hits)
print("  slots hit          : %d live, %d dead"
      % (len({k for k in hits if k not in dead}),
         len({k for k in hits if k in dead})))
print()
print("  svc   hits  prom_a  prom_b   status")
for n in sorted(hits):
    pa = sum(1 for t, _ in sites[n] if t == "prom_a")
    print("  0x%02X  %5d  %6d  %6d   %s"
          % (n, hits[n], pa, hits[n] - pa, "DEAD -- noise" if n in dead else ""))
print()
# The question this was written for.
TEXT = {0x06: "8x14 Latin", 0x07: "8x16 Latin", 0x08: "16x16 Latin",
        0x20: "8x10 Latin", 0x21: "16x24 Latin", 0x17: "8x8 Latin prop.",
        0x1C: "16x16 Latin prop.", 0x16: "half-width katakana",
        0x19: "katakana 16x16", 0x1D: "hiragana 16x16",
        0x1A: "kanji set A", 0x1F: "kanji set B"}
print("  the twelve text services:")
for n in sorted(TEXT):
    print("    0x%02X  %-20s %s" % (n, TEXT[n],
          ("%d sites" % hits[n]) if hits[n] else "-- no literal call site found"))
jp = [n for n in (0x16, 0x19, 0x1A, 0x1D, 0x1F) if hits[n]]
print()
print("  ★ Japanese-script services with a literal call site: %d of 5 %s"
      % (len(jp), [hex(n) for n in jp]))
print("    Latin services with one                          : %d of 7"
      % len([n for n in (0x06, 0x07, 0x08, 0x17, 0x1C, 0x20, 0x21) if hits[n]]))
if "--sites" in sys.argv:
    for n in sorted(hits):
        for t, addr in sites[n]:
            print("    0x%02X  %s 0x%06X" % (n, t, addr))
