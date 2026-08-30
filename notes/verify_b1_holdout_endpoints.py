#!/usr/bin/env python3
"""The FIRST and the LAST holdout, named correctly (the sweep script mislabelled
them because short bodies are skipped). This project's signature failure is a
result proven on record 1 and failing on record N, so both ends are stated."""
import os, sys, tempfile, shutil
sys.path.insert(0, os.path.expanduser("~/compartilhado/kn5000-roms-disasm/notes"))
import reachability_kn5000 as R

data, base = R.rom_bytes(), R.TARGET["base"]
mirror = tempfile.mkdtemp(prefix="verify-b1-ends-")
try:
    R.build_mirror(mirror)
    code, labels, words, dbytes, pbytes, total = R.flatten(mirror)
finally:
    shutil.rmtree(mirror, ignore_errors=True)
converted = {a + i for a, (n, _t) in code.items() for i in range(n)}
r = R.gather()
sd = {k: set(v) for k, v in r["seed_lists"].items()}
entries = sorted(a for a in sd["branch"] if a in code)

def body(e):
    out, pc, g = set(), e, 0
    while pc in code and g < 4000:
        g += 1
        n, t = code[pc]
        out |= {pc + i for i in range(n)}
        if R.FLOW_END.match(t): break
        pc += n
    return out

for label, e in (("FIRST branch seed on converted code", entries[0]),
                 ("LAST  branch seed on converted code", entries[-1])):
    b = body(e)
    seen = R.walk_from(data, base, [e], converted - b)
    print("%s  0x%06X  body %4d B  recall %5.1f%%  evidence %s"
          % (label, e, len(b), 100.0 * len(b & seen) / len(b),
             R.start_evidence(e, sd, R.EV_STRONG)))
print("eligible candidates: %d" % len(entries))
