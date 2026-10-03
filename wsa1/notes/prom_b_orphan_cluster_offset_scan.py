#!/usr/bin/env python3
"""prom_b_orphan_cluster_offset_scan.py -- does ONE constant offset move prom_b's orphan-cluster call
targets onto prom_a instruction starts?

QUESTION IT ANSWERS
    FINDINGS-prom_b-f00c4d-orphan-cluster.md (N2) says the cluster 0xF00C00-0xF017FF calls a prom_a that
    is not the one beside it, and that no offset in -2048..+2048 fixes that.  prom_a's own stale handler
    copies (FINDINGS-prom_a-fdfee2-stale-handlers.md) moved by 0x1FD5-0x2028, outside that window.  This
    scans d in -0x3000..+0x3000 and counts, for each d, how many of the cluster's distinct `call` targets
    T have T+d on a prom_a instruction start.

    Call targets are read from wsa1/prom_b/wsa1_prom_b.s's `; ADDR  call 0x...` comments in 0xF00C00-
    0xF017FF; instruction starts from wsa1/prom_a/wsa1_prom_a.s's `; ADDR  bytes` comments.

RUN (from the repository root)
    python3 wsa1/notes/prom_b_orphan_cluster_offset_scan.py

SIGNAL
    The number of distinct targets, then the six best (count, d).  2026-10-03: 34 targets; best 25,
    at d = -0x85D and d = -0x2D33.  No constant offset fits.
"""
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
src = open(os.path.join(ROOT, "wsa1/prom_a/wsa1_prom_a.s"), "rb").read().decode("latin-1")
starts = {int(m.group(1), 16) for m in re.finditer(r";\s+([0-9A-F]{6})  [0-9a-f]{2}", src)}
bs = open(os.path.join(ROOT, "wsa1/prom_b/wsa1_prom_b.s"), "rb").read().decode("latin-1")
tg = set()
for m in re.finditer(r";\s+(F0[01][0-9A-F]{3})\s+call 0x(f[cd][0-9a-f]{4})\b", bs):
    if 0xF00C00 <= int(m.group(1), 16) < 0xF01800:
        tg.add(int(m.group(2), 16))
print(len(tg), "distinct call targets")
best = sorted(((sum((t + d) in starts for t in tg), d) for d in range(-0x3000, 0x3001)), reverse=True)[:6]
print([(n, hex(d)) for n, d in best])
