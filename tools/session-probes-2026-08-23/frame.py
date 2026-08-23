#!/usr/bin/env python3
"""A self-check a MIS-FRAMED decode cannot fake: does the stack frame balance?

A routine that opens `lda xsp,(xsp - N)` / `dec N,XSP` / `push R` must close with
the matching `lda xsp,(xsp + N)` / `inc N,XSP` / `pop R` (or a `retd N`).  The
two halves are tens of bytes apart and encode N independently, so a decode
started at the wrong offset has no way to make them agree.
"""
import collections, os, pickle, re, sys
S = os.environ["SCRATCH"]
cases = sorted(pickle.load(open(os.path.join(S, "cases.pkl"), "rb"))["cases"], key=lambda c: c["entry"])
LDA = re.compile(r'lda\s+xsp,\s*\(xsp\s*([-+])\s*(0x[0-9a-f]+)\)', re.I)
INCDEC = re.compile(r'\b(inc|dec)\s+(\d+),\s*xsp\b', re.I)
PUSHPOP = re.compile(r'\b(push|pop)\s+(\w+)\b', re.I)
RETD = re.compile(r'\bretd\s+(0x[0-9a-f]+)', re.I)
res = collections.Counter()
detail = []
for c in cases:
    T = [t.lower() for t in c["texts"]]
    delta = 0
    ev = []
    for t in T:
        m = LDA.search(t)
        if m:
            v = int(m.group(2), 16)
            delta += (-v if m.group(1) == '-' else v); ev.append(t); continue
        m = INCDEC.search(t)
        if m:
            v = int(m.group(2))
            delta += (v if m.group(1).lower() == 'inc' else -v); ev.append(t); continue
        m = PUSHPOP.match(t)
        if m:
            w = 4 if m.group(2).lower().startswith('x') else 2
            delta += (-w if m.group(1).lower() == 'push' else w); ev.append(t); continue
        m = RETD.search(t)
        if m:
            delta += int(m.group(1), 16); ev.append(t)
    tag = ("balanced" if delta == 0 else f"net {delta:+d}") if ev else "no frame ops"
    res[tag] += 1
    detail.append((c["entry"], c["span"], tag, len(ev), ev[:2] + ev[-2:]))
for k, v in res.most_common():
    print(f"  {v:3}  {k}")
print()
for e, sp, tag, n, ev in detail:
    print(f"0x{e:06X} {sp:5} B  {tag:14} ({n} frame ops)  {' | '.join(ev)[:110]}")
