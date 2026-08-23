#!/usr/bin/env python3
"""Why do 67.5% of KNOWN-BAD entry points pass the structural gates?

HYPOTHESIS: TLCS-900 is a variable-length ISA and self-synchronises. Decoding
from an offset inside an instruction produces a garbage instruction or two and
then RE-JOINS the true instruction stream, after which the decode is identical to
the correct one -- same instructions, same terminator, same end. That decode
passes every structural gate because, past the first few bytes, it IS the correct
decode.

If true, the consequence is precise rather than alarming: a wrong entry point
does not fabricate a whole wrong function, it prepends a few wrong instructions
to a right one. The bytes still round-trip (they are the same bytes), so no gate
sees it -- but the damage is bounded and localised, and it is visible as a
mismatch in the FIRST instructions only.

MEASURE: for entries that pass, decode from t and from t+1, and find the first
address present in BOTH decodes. The gap from t is the resynchronisation
distance.

Run:  python3 tools/spelling-probes/adv_resync_distance.py
"""
import importlib.util, json, os, sys
from collections import Counter

REPO = "/home/fsanches/compartilhado/kn5000-roms-disasm"
sys.path.insert(0, REPO); os.chdir(REPO)
BASE, DATA = 0xE00000, 2

_s = importlib.util.spec_from_file_location(
    "crr", os.path.join(REPO, "scripts/converters/convert_reachable_ranges.py"))
crr = importlib.util.module_from_spec(_s); _s.loader.exec_module(crr)
spec = importlib.util.spec_from_file_location(
    "spans", os.path.join(REPO, "scripts/analysis/v7_undisassembled_spans.py"))
spans = importlib.util.module_from_spec(spec); spec.loader.exec_module(spans)
terr = spans.territory(spans.runs("v7/maincpu/kn5000_v7_program.s", "v7/maincpu"))
rom = open("original_ROMs/kn5000_v7_program.rom", "rb").read()

cl = json.load(open("analysis/v7-reachability/v7_branch_closure_targets.json"))["targets"]
dists, never, n = Counter(), 0, 0
for t in cl:
    if terr[t - BASE] != DATA:
        continue
    a = crr.decode_range(rom, terr, t)
    b = crr.decode_range(rom, terr, t + 1)
    if len(a) < 3 or len(b) < 3:
        continue
    n += 1
    sb = {x for x, _, _ in b}
    for x, _, _ in a:
        if x in sb:
            dists[x - t] += 1
            break
    else:
        never += 1
    if n >= 400:
        break

print(f"  entry pairs compared                : {n}")
print(f"  never re-synchronised               : {never}")
print(f"  re-synchronised                     : {n - never}")
print()
print("  resync distance from the true entry (bytes) -> count")
tot = 0
for d, c in sorted(dists.items())[:14]:
    tot += c
    print(f"      {d:4}  {c:5}   cumulative {100*tot/max(1,n):5.1f}%")
print()
print("  A short resync distance means a wrong entry prepends a few bad")
print("  instructions to an otherwise CORRECT decode -- which is exactly why")
print("  the structural gates let it through, and why the byte gate cannot see it.")
