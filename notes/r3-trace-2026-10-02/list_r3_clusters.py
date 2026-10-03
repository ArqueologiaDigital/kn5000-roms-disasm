#!/usr/bin/env python3
"""list_r3_clusters.py -- print each cluster of R3-refused numeric branches with the code around it, and the
address of every line that starts a block (the first instruction after a `ret`/`reti`/`jp`/unconditional `jr`
or a column-0 label), so a seed for trace_r3_sites.py --seed can be chosen by reading.

QUESTION IT ANSWERS
  Which unreached blocks hold the R3 refusals, and where does each block begin?  It reads the line addresses
  from symbolize_numeric_branches.py's marker mirror (via scripts/tools/place_labels.Planner), so the
  addresses are the linked ones.

RUN
  python3 scripts/converters/symbolize_numeric_branches.py --image v10 --only F.s --report BR.json
  python3 notes/r3-trace-2026-10-02/list_r3_clusters.py --image v10 --file sequencer/accompaniment_engine.s \\
      --report BR.json [--first N --count K]
"""
import argparse, bisect, json, os, re, subprocess, sys
REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True).stdout.strip()
sys.path.insert(0, os.path.join(REPO, "scripts", "tools"))
import place_labels as PL
ap = argparse.ArgumentParser()
ap.add_argument("--image", required=True); ap.add_argument("--file", required=True); ap.add_argument("--report", required=True)
ap.add_argument("--first", type=int, default=0); ap.add_argument("--count", type=int, default=1000)
a = ap.parse_args()
P = PL.Planner(a.image)
rel = os.path.join(a.image, "maincpu", a.file) if not a.file.startswith(a.image) else a.file
rel = os.path.relpath(os.path.join(REPO, rel), P.srcroot)
L = P.lines(rel)
addr_of = {}
for s in P.spans:
    if s[2] == rel:
        addr_of.setdefault(s[3], s[0])
r3 = [x for x in json.load(open(a.report))["report"].get("R3", []) if a.file in x["src"]]
lines = sorted(int(x["src"].rsplit(":", 1)[1]) - 1 for x in r3)
cl, cur = [], [lines[0]] if lines else []
for x in lines[1:]:
    if x - cur[-1] > 40:
        cl.append(cur); cur = [x]
    else:
        cur.append(x)
if cur:
    cl.append(cur)
END = re.compile(r'^\s*(ret|reti|retd|jp\s+[A-Za-z_.]|jr\s+[A-Za-z_.0-9-]+\s*$|jrl\s+[A-Za-z_.0-9-]+\s*$)')
for k, c in enumerate(cl[a.first:a.first + a.count], a.first):
    lo = c[0]
    while lo > 0 and not END.match(L[lo - 1].split(";")[0]) and lo > c[0] - 30:
        lo -= 1
    print("=== cluster %d: %d sites, lines %d-%d" % (k, len(c), c[0] + 1, c[-1] + 1))
    prev_end = True
    for i in range(lo, min(len(L), c[-1] + 4)):
        t = L[i].split(";")[0].rstrip()
        if not t.strip():
            continue
        start = prev_end or re.match(r'^[A-Za-z_]', t)
        ad = addr_of.get(i)
        mark = "*" if i in c else " "
        print("%s %s %s" % (("%06X" % ad if ad is not None else "      ") + ("<" if start and ad is not None else " "), mark, t[:76]))
        prev_end = bool(END.match(t))
