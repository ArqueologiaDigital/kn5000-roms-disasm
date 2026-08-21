#!/usr/bin/env python3
"""Q: does the IC19 custom-data style payload use the SAME event grammar the repo
already decoded for demo presets (scripts/build/demo_preset_to_midi.py)?
Signal: every 256-byte cell starting with 80 FF FF FF FF 87 must reach status 0x83
under the rule "bit7 set = status, following bit7-clear bytes = its args".
PASS = 725/725 and a self-consistent (status -> arg-count) census.
Run: python3 ic19_cell_grammar_probe.py <repo>/original_ROMs/kn5000_custom_data.ic19"""
import re, sys
from collections import Counter
d = open(sys.argv[1], 'rb').read()
hits = [m.start() for m in re.finditer(re.escape(b'\x80\xff\xff\xff\xff\x87'), d)]
ok = 0; stat = Counter(); arg = Counter()
for h in hits:
    body = d[h:h+256][6:]
    cur = None; n = 0
    for b in body:
        if b & 0x80:
            if cur is not None: arg[(cur, n)] += 1
            cur = b; n = 0; stat[b] += 1
            if b == 0x83: ok += 1; break
        else: n += 1
print(f"cells framed to 0x83: {ok}/{len(hits)}")
print("status census:", stat.most_common())
print("(status,args):", [(hex(s), n, c) for (s, n), c in arg.most_common(8)])
