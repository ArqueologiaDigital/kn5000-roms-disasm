#!/usr/bin/env python3
r"""check_stale_v10_notes.py -- is "; v10 does not spell this byte either" still true?

QUESTION THIS ANSWERS
    An earlier lane annotated v7 `.byte` lines with "v10 does not spell this byte
    either".  After this wave re-framed v10 and ported v10 onto v7, many of those
    notes now stand above a v7 INSTRUCTION.  For each such note in the given v7
    files: map the v7 instruction to v10 by byte alignment (port_islands.Porter:
    label anchor + difflib) and report whether v10 now has an instruction line of
    the same length at the mapped address (then the note is proven false).

RUN
    python3 scripts/lanes/sys/check_stale_v10_notes.py
"""
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import port_islands as pi
P = pi.Porter("v10", "v7")
ins10 = {}
for e in P.os:
    if e[0] is not None and e[4] > 0:
        body = pi.split_line(e[3])[1]
        if body and not body.startswith("."):
            ins10[e[0]] = (e[4], body)
ok = bad = unk = 0
for rel in ("boot/system_handlers.s", "demo/fdemotext_routines.s"):
    idx = [k for k, e in enumerate(P.od) if e[1] == rel]
    for q, k in enumerate(idx):
        e = P.od[k]
        if e[3].strip() != "; v10 does not spell this byte either":
            continue
        j = q + 1
        while j < len(idx) and P.od[idx[j]][3].strip().startswith(";"):
            j += 1
        nx = P.od[idx[j]]
        body = pi.split_line(nx[3])[1]
        if not body or body.startswith(".byte"):
            continue
        a7, n = nx[0], nx[4]
        d0 = P.anchor_delta(idx[j])
        if d0 is None:
            unk += 1; print(rel, nx[2], "no anchor"); continue
        dm, s0, s1 = P.align(a7, a7 + n, d0)
        inv = {a + d: a for a, d in dm.items()}
        a10 = inv.get(a7)
        if a10 is not None and a10 in ins10 and ins10[a10][0] == n and all(inv.get(a7 + t) == a10 + t for t in range(n)):
            ok += 1; print(rel, nx[2], hex(a7), "-> v10", hex(a10), "SPELLED:", ins10[a10][1])
        else:
            bad += 1; print(rel, nx[2], hex(a7), "-> v10", hex(a10) if a10 else None, "not proven", ins10.get(a10))
print("proven false:", ok, "not proven:", bad, "no anchor:", unk)
