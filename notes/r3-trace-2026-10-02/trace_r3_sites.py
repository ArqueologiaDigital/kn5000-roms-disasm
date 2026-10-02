#!/usr/bin/env python3
"""trace_r3_sites.py -- which "absurd block" (R3) branch refusals sit in code that control flow really reaches?

QUESTION THIS ANSWERS
  scripts/converters/symbolize_numeric_branches.py refuses a numeric branch within 12 lines of an
  instruction real code rarely holds (R3) -- including any `nop / nop`, with which many
  accompaniment-engine routines begin.  A refusal is a false positive when the branch is real
  code.  This traces control flow (scripts/converters/scoop_reframe.py trace: unidasm recursive
  descent) over the address range of one source file, entering ONLY at addresses some `call` /
  `calr` in the tree targets, and lists the R3 sites whose branch AND target are reached as
  instruction starts.  Writes them as JSON for symbolize_numeric_branches.py --trust-traced.

USAGE
  make all
  python3 scripts/converters/symbolize_numeric_branches.py --image v10 --report BR.json
  python3 notes/r3-trace-2026-10-02/trace_r3_sites.py --image v10 \\
      --file sequencer/accompaniment_engine.s --report BR.json --out TRUSTED.json
  python3 scripts/converters/symbolize_numeric_branches.py --image v10 --trust-traced TRUSTED.json --apply --verify
"""
import argparse
import glob
import json
import os
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
sys.path.insert(0, os.path.join(REPO, "scripts", "converters"))
import scoop_reframe as SR  # noqa: E402

NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
CALL = re.compile(r'^\s*(?:[A-Za-z_][\w.$]*:)?\s*(?:call|calr)\s+(?:[a-z]+\s*,\s*)?([A-Za-z_][\w.$]*)\s*$', re.I)
LABEL = re.compile(r'^([A-Za-z_][\w.$]*):')

ap = argparse.ArgumentParser()
ap.add_argument("--image", required=True, choices=("v10", "v9", "v7"))
ap.add_argument("--file", required=True)
ap.add_argument("--report", required=True)
ap.add_argument("--out", required=True)
a = ap.parse_args()
addr = {}
for l in subprocess.run([NM, "--defined-only", os.path.join(REPO, "rebuilt_ROMs/kn5000_%s_program.llvm.elf" % a.image)],
                        capture_output=True, text=True, check=True).stdout.splitlines():
    x, t, n = l.split()
    addr[n] = int(x, 16)
src = os.path.join(REPO, a.image, "maincpu", a.file)
names = set(m.group(1) for m in (LABEL.match(l) for l in open(src, "rb").read().decode("latin-1").split("\n")) if m)
inrange = sorted(addr[n] for n in names if n in addr)
lo, hi = inrange[0], inrange[-1] + 0x100
called = set()
for f in glob.glob(os.path.join(REPO, a.image, "maincpu", "**", "*.s"), recursive=True):
    for l in open(f, "rb").read().decode("latin-1").split("\n"):
        m = CALL.match(l.split(";")[0])
        if m and m.group(1) in addr:
            called.add(addr[m.group(1)])
ents = sorted(x for x in called if lo <= x < hi)
insns, ext, conflicts = SR.trace(a.image, lo, hi, ents)
r3 = json.load(open(a.report))["report"].get("R3", [])
ok = [y["src_addr"] for y in r3 if a.file in y["src"] and int(y["src_addr"], 16) in insns and int(y["target"], 16) in insns]
json.dump(ok, open(a.out, "w"), indent=1)
print("%s %s: range 0x%06X-0x%06X, %d called entries, %d instructions reached, %d conflicts; "
      "R3 sites in this file %d, reached with their targets %d -> %s"
      % (a.image, a.file, lo, hi, len(ents), len(insns), len(conflicts),
         sum(1 for y in r3 if a.file in y["src"]), len(ok), a.out))
