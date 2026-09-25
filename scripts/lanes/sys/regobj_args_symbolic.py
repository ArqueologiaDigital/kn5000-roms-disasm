#!/usr/bin/env python3
"""regobj_args_symbolic.py IMAGE [apply] FILE,FILE,... -- in RegObjTable / RegObjTabl macro
lines of the given files (relative to IMAGE/maincpu), replace a 24-bit numeric proc / data /
(RegObjTable) +8-source argument by the label defined EXACTLY at that address (positional
`_0xNNN` aliases excluded).  Byte-neutral by construction; rebuild to confirm."""
import os
import re
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import port_islands as pi
img = sys.argv[1]; apply = len(sys.argv) > 2
order, syms = pi.amap(img)
exact = {}
for k, v in syms.items():
    if 0xE00000 <= v < 0x1000000 and not k.startswith(('__', '.')) and not re.search(r'_0x[0-9A-Fa-f]+$', k):
        exact.setdefault(v, k)
RX = re.compile(r'^(\t(RegObjTable|RegObjTabl)\s+)(\S+),\s*(\S+),\s*(\S+),\s*(\S+),\s*(\S+)(\s*(;.*)?)$')
tot = conv = 0
for rel in sorted({e[1] for e in order} & set(sys.argv[3].split(','))):
    p = os.path.join(pi.ROOT, img, 'maincpu', rel)
    raw = open(p, 'rb').read().decode('latin-1')
    L = raw.split('\n'); ch = False
    for i, ln in enumerate(L):
        m = RX.match(ln)
        if not m: continue
        args = list(m.group(3, 4, 5, 6, 7))
        idxs = (1, 2, 3) if m.group(2) == 'RegObjTable' else (1, 3)
        for j in idxs:
            t = args[j]
            if re.match(r'^0x[0-9a-fA-F]{6}$', t):
                tot += 1
                v = int(t, 16)
                if v in exact:
                    args[j] = exact[v]; conv += 1; ch = True
        L[i] = m.group(1) + ', '.join(args) + (m.group(8) or '')
    if ch:
        print(img, rel)
        if apply: open(p, 'wb').write('\n'.join(L).encode('latin-1'))
print(img, 'numeric address args', tot, 'made symbolic', conv)
