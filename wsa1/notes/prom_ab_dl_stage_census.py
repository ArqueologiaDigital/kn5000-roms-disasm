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
  python3 wsa1/notes/prom_ab_dl_stage_census.py
"""
import collections
import os
import re
import subprocess

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
BASE = 0x12F6
NAME = "DisplayListB_Stage"
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
            if 0x12C0 <= v < 0x1340:
                (wr if re.match(r'\s*ld\s+\(', code) and code.index("(") == m.start() else other)[v] += 1
        for m in re.finditer(r'\b(?:ld|lda)\s+x[a-z]{2}\s*,\s*%s\s*$' % TOK, code, re.I):
            v = val(m.group(1))
            if 0x12C0 <= v < 0x1340:
                other[v] += 1
print("addr    DL-source  code-stores  other-code")
for v in range(0x12C0, 0x1340):
    if src[v] or wr[v] or other[v]:
        print("0x%04x  %9d  %11d  %10d" % (v, src[v], wr[v], other[v]))
blk = [v for v in range(0x12C0, 0x1340) if src[v]]
print("DL-source extent: 0x%04X-0x%04X, %d bytes, all read by DL records: %s" %
      (blk[0], blk[-1], blk[-1] - blk[0] + 1, all(src[v] for v in range(blk[0], blk[-1] + 1))))
print("code reads inside it:", sum(other[v] for v in range(blk[0], blk[-1] + 1)))
