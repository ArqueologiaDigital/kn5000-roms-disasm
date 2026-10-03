#!/usr/bin/env python3
"""wsa1_ram_unnamed_census.py -- which WSA1 RAM addresses are still spelled as numbers, busiest first.

QUESTION THIS ANSWERS
  Which RAM address should be researched and named next?  The script counts every memory operand
  `(N)` / `(N:8|16|24)` and every m_* macro address argument (MB16, 0x...) in prom_a and prom_b
  whose value is RAM: 0x0400-0xFFFF (internal / direct page) or 0x600000-0x6FFFFF (external).  A
  named address is spelled by its symbol and so is not counted.  For each address it prints the
  number of operands and the four routines that use it most.
  Then: research it, write a wsa1/notes/FINDINGS-* table, and name it with
  scripts/tools/name_wsa1_ram.py.  prom_ab_ram_operand_shapes.py gives the per-shape detail.

USAGE
  python3 scripts/analysis/wsa1_ram_unnamed_census.py [LO HI [N]]     # default: all RAM, top 60
"""
import collections
import os
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
MEM = re.compile(r'\((0x[0-9a-fA-F]+|\d+)(?::8|:16|:24)?\)')
MAC = re.compile(r'\bM[BWDL](?:8|16|24),\s*(0x[0-9a-fA-F]+|\d+)\b')
LAB = re.compile(r'^([A-Za-z_.$][\w.$]*):')
def ram(v): return 0x400 <= v < 0x10000 or 0x600000 <= v < 0x700000
cnt = collections.Counter(); users = collections.defaultdict(collections.Counter)
for f in ["wsa1/prom_a/wsa1_prom_a.s", "wsa1/prom_b/wsa1_prom_b.s"]:
    cur = "?"
    for l in open(os.path.join(REPO, f), "rb").read().decode("latin-1").split("\n"):
        m = LAB.match(l)
        if m and not m.group(1).startswith("."): cur = m.group(1)
        code = l.split(";")[0]
        if not code.strip() or code.strip().startswith("."): continue
        for r in (MEM, MAC):
            for x in r.finditer(code):
                v = int(x.group(1), 0)
                if ram(v):
                    cnt[v] += 1; users[v][f.split("/")[1] + ":" + cur] += 1
lo = int(sys.argv[1], 0) if len(sys.argv) > 1 else 0
hi = int(sys.argv[2], 0) if len(sys.argv) > 2 else 1 << 32
n = int(sys.argv[3]) if len(sys.argv) > 3 else 60
print("unnamed RAM addresses %d, operands %d" % (len(cnt), sum(cnt.values())))
for v, c in sorted(((v, c) for v, c in cnt.items() if lo <= v < hi), key=lambda t: -t[1])[:n]:
    u = users[v]
    print("0x%06x %4d  %3d routines  %s" % (v, c, len(u), ", ".join("%s(%d)" % kv for kv in u.most_common(4))))
