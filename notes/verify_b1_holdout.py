#!/usr/bin/env python3
"""HOLDOUT / POWER TEST for lane b1's central negative:
  "at most 176 bytes of v10 maincpu's .incbin are defensible code".

A criterion that cannot fail is not a pass. So: take code the tree HAS already
converted, pretend it is still .incbin, and ask whether b1's STRONG+EVIDENCE
pipeline would surface it. If it does -- for the FIRST and the LAST holdout, and
across a sample -- the instrument can see code in unconverted territory, and the
176-byte answer is a measurement rather than an artefact of a blind walk.

Method: b1's own walk() / start_evidence(), unmodified. For a routine entry E
that is a `branch` seed, remove E's routine from `converted` and walk from E.
Recall = the routine's own bytes that come back marked.
"""
import os, sys, random
sys.path.insert(0, os.path.expanduser("~/compartilhado/kn5000-roms-disasm/notes"))
import reachability_kn5000 as R

data = R.rom_bytes()
base = R.TARGET["base"]
end = base + len(data)

import tempfile, shutil
mirror = tempfile.mkdtemp(prefix="verify-b1-holdout-")
try:
    spans = R.build_mirror(mirror)
    code, labels, words, dbytes, pbytes, total = R.flatten(mirror)
finally:
    shutil.rmtree(mirror, ignore_errors=True)
assert total == len(data), (total, len(data))
print("flatten ok: %d bytes, %d converted instructions" % (total, len(code)))

converted = set()
for a, (n, t) in code.items():
    for i in range(n):
        converted.add(a + i)

r = R.gather()
sd = {k: set(v) for k, v in r["seed_lists"].items()}

# Routine entries that ARE branch seeds and ARE converted code.
entries = sorted(a for a in sd["branch"] if a in code)
print("candidate holdouts (branch seeds landing on a converted instruction): %d"
      % len(entries))

def routine_bytes(e):
    """The tree's own instructions from e up to and including the first flow end."""
    out, pc, guard = set(), e, 0
    while pc in code and guard < 4000:
        guard += 1
        n, t = code[pc]
        for i in range(n):
            out.add(pc + i)
        if R.FLOW_END.match(t):
            break
        pc += n
    return out

random.seed(20260830)
sample = [entries[0], entries[-1]] + random.sample(entries, 60)
rows, full, none = [], 0, 0
for e in sample:
    body = routine_bytes(e)
    if len(body) < 8:
        continue
    held = converted - body                     # pretend this routine is .incbin
    seen = R.walk_from(data, base, [e], held)
    rec = len(body & seen) / float(len(body))
    ev = R.start_evidence(e, sd, R.EV_STRONG)
    rows.append((e, len(body), rec, ev))
    if rec >= 0.999: full += 1
    if rec == 0.0: none += 1

print()
print("  %-10s %6s  %7s  %s" % ("entry", "bytes", "recall", "start evidence"))
for e, n, rec, ev in rows[:2]:
    print("  0x%06X %6d  %6.1f%%  %s   <-- %s" %
          (e, n, rec * 100, ev, "FIRST branch seed" if e == entries[0] else "LAST branch seed"))
for e, n, rec, ev in rows[2:12]:
    print("  0x%06X %6d  %6.1f%%  %s" % (e, n, rec * 100, ev))
print("  ... (%d holdouts total)" % len(rows))
print()
print("RECALL: %d of %d holdouts fully recovered, %d recovered nothing"
      % (full, len(rows), none))
print("EVIDENCE: %d of %d holdout starts carry STRONG evidence"
      % (sum(1 for _e, _n, _r, ev in rows if ev), len(rows)))
