#!/usr/bin/env python3
"""POSITIVE CONTROL for lane b1's negative "the WSA1 address-comment regex matches
0 of 473,775 KN5000 source lines".  A regex that matches nothing anywhere would
make that check un-failable.  Same regex, same code, pointed at the WSA1 sources.
"""
import re, os
RX = re.compile(r'^\t(\S.*?)\s*;\s*([0-9A-F]{6})\s+(.*)$')   # verbatim, line 160
W = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "wsa1")
# ★ A POSITIVE CONTROL THAT CANNOT FAIL IS WORTHLESS, and this one could: when the
# WSA1 tree moved into wsa1/ on 2026-09-01 the old path stopped existing, every
# file printed MISSING, and the script still exited 0 -- reporting nothing while
# looking like a pass. A missing input is now a FAILURE, not a line of output.
missing = 0
for rel in ("prom_a/wsa1_prom_a.s", "prom_b/wsa1_prom_b.s", "prom_c/wsa1_prom_c.s"):
    p = os.path.join(W, rel)
    if not os.path.exists(p):
        print("  %-28s MISSING -- the control cannot run" % rel)
        missing += 1
        continue
    n = t = 0
    for ln in open(p, encoding="latin-1"):
        t += 1
        if RX.match(ln.rstrip("\n")):
            n += 1
    print("  %-28s %7d of %7d lines match" % (rel, n, t))

if missing:
    raise SystemExit("FAIL: %d of 3 inputs missing; this control proved nothing" % missing)
