#!/usr/bin/env python3
"""POSITIVE CONTROL for lane b1's negative "the WSA1 address-comment regex matches
0 of 473,775 KN5000 source lines".  A regex that matches nothing anywhere would
make that check un-failable.  Same regex, same code, pointed at the WSA1 sources.
"""
import re, os
RX = re.compile(r'^\t(\S.*?)\s*;\s*([0-9A-F]{6})\s+(.*)$')   # verbatim, line 160
W = os.path.expanduser("~/compartilhado/wsa1-roms-disasm")
for rel in ("prom_a/wsa1_prom_a.s", "prom_b/wsa1_prom_b.s", "prom_c/wsa1_prom_c.s"):
    p = os.path.join(W, rel)
    if not os.path.exists(p):
        print("  %-28s MISSING" % rel); continue
    n = t = 0
    for ln in open(p, encoding="latin-1"):
        t += 1
        if RX.match(ln.rstrip("\n")):
            n += 1
    print("  %-28s %7d of %7d lines match" % (rel, n, t))
