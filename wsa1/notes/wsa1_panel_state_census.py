#!/usr/bin/env python3
"""wsa1_panel_state_census.py -- every operand of the panel-state bytes 0x2076-0x209C in prom_a / prom_b.

QUESTION THIS ANSWERS
  Which routines read and write each of the mode / screen latches and the dial's button pair
  (FINDINGS-prom_a-panel-state-variables.md), and how?  Numeric operands only: once an address is named
  in include/wsa1_ram.inc it drops out (grep the name instead).

USAGE (from the repository's wsa1/ directory)
  python3 notes/wsa1_panel_state_census.py
"""
import collections
import re

WANT = set(range(0x2076, 0x209D))
for f in ["prom_a/wsa1_prom_a.s", "prom_b/wsa1_prom_b.s"]:
    L = open(f, "rb").read().decode("latin-1").split("\n")
    cur = "?"
    d = collections.defaultdict(lambda: collections.defaultdict(set))
    for l in L:
        m = re.match(r'^([A-Za-z_][\w$]*):', l)
        if m and not re.search(r'_(Skip|Join|Loop|Return|Exit|Done|Next|Part)\d*$', m.group(1)):
            cur = m.group(1)
        c = l.split(";")[0]
        for x in re.findall(r'\((0x[0-9a-fA-F]+|\d+)(?::16|:24|:8)?\)|\bM[BWDL](?:8|16|24)\s*,\s*(0x[0-9a-fA-F]+|\d+)', c):
            s = x[0] or x[1]
            v = int(s, 0)
            if v in WANT:
                op = re.sub(r'\s+', ' ', c.strip())
                d[v][op].add(cur)
    print("#####", f)
    for v in sorted(d):
        print("== 0x%04X" % v)
        for op, rs in sorted(d[v].items(), key=lambda kv: -len(kv[1]))[:14]:
            print("   %-40s %s" % (op[:40], ", ".join(sorted(rs))[:150]))
