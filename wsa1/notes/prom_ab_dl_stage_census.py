#!/usr/bin/env python3
"""prom_ab_dl_stage_census.py -- the display-list-B staging block, from both ends.

QUESTION THIS ANSWERS (FINDINGS-prom_ab-display-list-b-stage.md)
  Which RAM bytes around 0x12F6 do interpreter-B display-list records read as their
  "+0x02 source variable" (`.short ADDR ; +0x02 source variable`), and what does the CODE do with
  them?  For every address 0x12C0..0x133F it prints:
  - the count of DL records that read it;
  - the code stores to it (`ld (ADDR),...`);
  - every other code use.
  A staging block is one the code only writes and the display lists only read.  The address is
  matched as hex, as decimal and, once named, as `DisplayListB_Stage[+n]`.

USAGE
  python3 wsa1/notes/prom_ab_dl_stage_census.py                      # 0x12F6, DisplayListB_Stage
  python3 wsa1/notes/prom_ab_dl_stage_census.py 0x2640 UI_DrawScratch 0x2600 0x2680
"""
import collections
import os
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
BASE = int(sys.argv[1], 0) if len(sys.argv) > 1 else 0x12F6
NAME = sys.argv[2] if len(sys.argv) > 2 else "DisplayListB_Stage"
LO = int(sys.argv[3], 0) if len(sys.argv) > 3 else 0x12C0
HI = int(sys.argv[4], 0) if len(sys.argv) > 4 else 0x1340
TOK = r'(0x[0-9a-fA-F]+|\d+|%s(?:\+\d+)?)' % NAME


def val(t):
    if t.startswith(NAME):
        return BASE + (int(t.split("+")[1]) if "+" in t else 0)
    return int(t, 0)


src, wr, other = collections.Counter(), collections.Counter(), collections.Counter()
for f in ["wsa1/prom_a/wsa1_prom_a.s", "wsa1/prom_b/wsa1_prom_b.s"]:
    for l in open(os.path.join(REPO, f), "rb").read().decode("latin-1").split("\n"):
        m = re.match(r'^\s*\.short\s+%s\s*;\s*\+0x02 source variable' % TOK, l)
        if m:
            src[val(m.group(1))] += 1
            continue
        code = l.split(";")[0]
        if not code.strip() or code.strip().startswith("."):
            continue
        for m in re.finditer(r'\(%s(?::16)?\)' % TOK, code):
            v = val(m.group(1))
            if LO <= v < HI:
                (wr if re.match(r'\s*ld\s+\(', code) and code.index("(") == m.start() else other)[v] += 1
        for m in re.finditer(r'\b(?:ld|lda)\s+x[a-z]{2}\s*,\s*%s\s*$' % TOK, code, re.I):
            v = val(m.group(1))
            if LO <= v < HI:
                other[v] += 1
print("addr    DL-source  code-stores  other-code")
for v in range(LO, HI):
    if src[v] or wr[v] or other[v]:
        print("0x%04x  %9d  %11d  %10d" % (v, src[v], wr[v], other[v]))
end = BASE
while src[end]:
    end += 1
print("contiguous DL-source run from 0x%04X: 0x%04X-0x%04X, %d bytes" % (BASE, BASE, end - 1, end - BASE))
print("inside it: DL records %d, code stores %d, other code uses %d" % (
    sum(src[v] for v in range(BASE, end)), sum(wr[v] for v in range(BASE, end)), sum(other[v] for v in range(BASE, end))))
