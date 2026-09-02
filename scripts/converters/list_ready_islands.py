#!/usr/bin/env python3
"""list_ready_islands.py -- which island runs are ready to fill, right now?

QUESTION ANSWERED
  Runs fill_verified_islands' own acceptance test over every island in an
  image and prints the ones that convert with ZERO bytes left over, with
  the instructions they would become. A dry-run work list: it writes
  nothing.

RUN
    python3 scripts/converters/list_ready_islands.py [tag] [workdir]
      tag     -- v10 (default) or v9.  ⚠ v10 IS THE PRIORITY IMAGE; v9 is
                 explicitly deprioritised by the project owner, so pass it
                 only when a fix is free for both.
      workdir -- census work directory (default: ./island-work)

⚠ READY IS NOT PROVEN. This lists runs whose decode TILES the run exactly
  from surrounding context. That is much stronger than an isolated decode --
  see fill_verified_islands' header for why -- but it is still not evidence
  that the bytes are code. A wrong frame reproduces the same bytes and the
  byte gate cannot object. Corroborate before converting: check that the
  decoded call targets land on routines already named in the tree.
"""
import sys, os, tempfile

TAG = sys.argv[1] if len(sys.argv) > 1 else "v10"
_here = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(_here))
os.chdir(REPO)
sys.path.insert(0, "scripts/converters")
import fill_verified_islands as fvi

WORK = sys.argv[2] if len(sys.argv) > 2 else os.path.join(REPO, "island-work")
terr, blobs, rom = fvi.load(TAG, WORK)
       and b["end"] < fvi.SIZE and terr[b["start"] - 1] == 1 and terr[b["end"]] == 1]
accepted = []
for b in isl:
    fr, ok = fvi.bounds_from_context(rom, terr, b["start"], b["end"], tmp)
    if fr == "ONE_INSN" or (fr == "MULTI" and ok):
        accepted.append(b)

ready = []
for b in accepted:
    raw = rom[b["start"]:b["end"]]
    try:
        new_lines, remaining = fvi.build_replacement(list(raw), fvi.BASE + b["start"])
    except Exception:
        continue
    if remaining == 0:
        ready.append((b, new_lines))

for b, nl in sorted(ready, key=lambda t: t[0]["file"]):
    print(f"{fvi.BASE+b['start']:#08x} {b['size']:>3}B {b['file']}:{b['line']} -> {'; '.join(l.strip() for l in nl)}")
print(f"TOTAL {len(ready)} candidates {sum(b['size'] for b,_ in ready)} B", file=sys.stderr)
