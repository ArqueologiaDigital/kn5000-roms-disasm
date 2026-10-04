#!/usr/bin/env python3
"""Name still-unnamed WSA1 routines that only wrap a content-named routine.

QUESTION IT ANSWERS
  A `sub_` whose whole body is
      `jp T` / `jrl T`                                  -> <T>_Veneer
      `call T` / `calr T`, `ret`                         -> <T>_Call
      `push ..` x n, `call T` / `calr T`, `pop ..` x n, `ret` -> <T>_SaveRegs
  does nothing but reach T, so it takes T's name with the shape as suffix -- when T is content-named
  (not sub_ / T_F4xxxx / loc_ / Data_ / LABEL_, and not ending in six hex digits).  A thunk-directory
  slot (T_F4xxxx, or a slot already renamed T_<target>) counts through its `jp` target.  A name already
  taken gets _B, _C ... (first free), the spelling commit 9ff764d8 used.
  Promoted 2026-10-04 from the session scratch (it produced 9ff764d8 and this commit's rename).

RUN (from wsa1/)
  python3 notes/wsa1_wrapper_names.py    # 'old=new|header' lines for the rename helper
"""
import collections
import os
import re
import sys
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FILES = [os.path.join(ROOT, "prom_a", "wsa1_prom_a.s"), os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")]
TXT = {f: open(f, "rb").read().decode("latin-1") for f in FILES}
ALL = "\n".join(TXT.values())
TOK = set(re.findall(r'[A-Za-z_][\w$]*', ALL))
# every thunk-directory slot, whether still T_F4xxxx or already T_<target> (2026-10-04 renames)
th = {m.group(1): m.group(2) for m in re.finditer(r'^(T_\w+):\s*jp\s+(\S+)', TXT[FILES[1]], re.M)}
def content(n):
    if re.match(r'^(sub_|T_F4|loc_|Data_|LABEL_)', n) or re.search(r'_[0-9A-F]{6}$', n):
        return None
    return n
out, seen = [], collections.Counter()
for f in FILES:
    L = TXT[f].split("\n")
    G = re.compile(r'^([A-Za-z_][\w$]*):')
    starts = [(i, G.match(l).group(1)) for i, l in enumerate(L) if G.match(l)]
    for k, (i, name) in enumerate(starts):
        if not re.match(r'^sub_F[0-9A-F]{5}$', name):
            continue
        j = starts[k + 1][0] if k + 1 < len(starts) else len(L)
        body = [re.sub(r'\s+', ' ', l.split(";")[0].strip()) for l in L[i + 1:j]]
        body = [b for b in body if b and not b.startswith(".L")]
        t = " / ".join(body)
        m = re.match(r'^(?:jp|jrl)\s+(\w+)$', t, re.I)
        kind = None
        if m: kind, tgt = "Veneer", m.group(1)
        m = m or None
        mm = re.match(r'^(?:call|calr)\s+(\w+) / ret$', t, re.I)
        if mm: kind, tgt = "Call", mm.group(1)
        ms = re.match(r'^(?:push \w+ / )+(?:call|calr)\s+(\w+) / (?:pop \w+ / )+ret$', t, re.I)
        if ms: kind, tgt = "SaveRegs", ms.group(1)
        if not kind:
            continue
        tname = th.get(tgt, tgt) if tgt.startswith("T_") else tgt
        c = content(tname)
        if not c:
            continue
        new = "%s_%s" % (c, kind)
        seen[new] += 1
        out.append((name, new, "%s: %s -- `%s`." % (new, {"Veneer": "a jump to %s" % c, "Call": "calls %s and returns" % c,
                                                       "SaveRegs": "calls %s with the registers it pushes saved around it" % c}[kind], t)))
for o, n, h in out:
    if seen[n] > 1 or n in TOK:
        n2 = None
        for s in "BCDEFGH":
            if (n + "_" + s) not in TOK and seen[n + "_" + s] == 0:
                n2 = n + "_" + s; seen[n2] += 1; break
        if not n2: continue
        h = h.replace(n + ":", n2 + ":", 1); n = n2
    TOK.add(n)
    print("%s=%s|%s" % (o, n, h))
