#!/usr/bin/env python3
"""name_wsa1_ram_count.py -- how many code operands use each WSA1 RAM name group (the numbers the commits and notes quote).

Counts, per GROUPS entry of scripts/tools/name_wsa1_ram.py, the occurrences of its names in the
non-comment, non-directive lines of the sources it rewrites.  A sub-field expression
(`Link_E2Payload+4`) counts once, under its base name.
USAGE: python3 scripts/tools/name_wsa1_ram_count.py
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import name_wsa1_ram as N  # noqa: E402

lines = []
for f in N.SOURCES:
    p = f if os.path.isabs(f) else os.path.join(N.REPO, f)
    for l in open(p, "rb").read().decode("latin-1").split("\n"):
        code = l.split(";")[0]
        if code.strip() and not code.strip().startswith("."):
            lines.append((os.path.basename(p), code))
tot = 0
for doc, _, g in N.GROUPS:
    bases = sorted({n.split("+")[0] for n, _, _ in g.values()})
    rx = re.compile(r'\b(%s)\b' % "|".join(map(re.escape, bases)))
    per = {}
    for f, c in lines:
        k = len(rx.findall(c))
        if k:
            per[f] = per.get(f, 0) + k
    n = sum(per.values())
    tot += n
    print("%-48s %3d names %5d operands  %s" % (os.path.basename(doc), len(bases), n,
                                                " ".join("%s=%d" % kv for kv in sorted(per.items()))))
print("total %d" % tot)
