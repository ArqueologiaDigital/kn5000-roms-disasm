#!/usr/bin/env python3
r"""HOW MUCH OF LANE `seui`'S FILES IS UNDERSTOOD?  (before/after instrument)

QUESTION ANSWERED
-----------------
Aggregates a `data_range_census.py --json` run over the files lane seui owns
(notes/lanes/ROSTER-2026-09-25.json: audio/sound_editor_ui.s,
sound_editor_routines.s, sound_editor_screens/*, semenu_routines.s,
sndparam_routines.s, sndparam_records/* -- in v10, v9 and v7) and prints, per
image and per file:

  CODE / KNOWN-A / KNOWN-B / UNKNOWN / FILLER bytes (the census grades) and
  RESEARCH-TARGET bytes (census `is_target`: UNKNOWN, self-admitted, or
  embedded-in-code),

plus two source-side counts the census does not make:

  markers   data-as-code markers, the regex of scripts/analysis/lane_worklists.py
            (halt/incf/decf/ldf/normal/max/min/swi, jr cc,0, jr f, nop-nop)
  romslice  bytes still pulled in verbatim from includes/romslices/ (v7)

RUN
    python3 scripts/analysis/data_range_census.py --images v10,v9,v7 --json X.json
    python3 scripts/lanes/seui/seui_census_summary.py X.json
"""
import fnmatch
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
from data_range_census import is_target            # noqa: E402

GLOBS = ["audio/sound_editor_ui.s", "audio/sound_editor_routines.s",
         "audio/sound_editor_screens/*", "audio/semenu_routines.s",
         "audio/sndparam_routines.s", "audio/sndparam_records/*"]
ABS = re.compile(r'^(halt|incf|decf|ldf|normal|max|min|swi)\b|^(jr|jrl)\s+[a-z]+\s*,\s*(0x)?0+$'
                 r'|^(jr|jrl)\s+f\s*,')
GRADES = ["CODE", "KNOWN-A", "KNOWN-B", "UNKNOWN", "FILLER"]


def mine(rel):
    return any(fnmatch.fnmatch(rel, g) for g in GLOBS)


def markers_and_slices(v, rel):
    p = os.path.join(ROOT, v, "maincpu", rel)
    if not p.endswith(".s") or not os.path.exists(p):
        return 0, 0
    prev, n, sl = "", 0, 0
    for ln in open(p, encoding="latin-1").read().split("\n"):
        c = ln.split(";")[0]
        m = re.search(r'\.incbin\s+"(includes/romslices/[^"]+)"', c)
        if m:
            f = os.path.join(ROOT, v, "maincpu", m.group(1))
            sl += os.path.getsize(f) if os.path.exists(f) else 0
        cc = re.sub(r'^[\w.$]+:\s*', '', c.strip()).lower()
        if not cc or cc.startswith("."):
            prev = ""
            continue
        if ABS.match(cc) or (cc == "nop" and prev == "nop"):
            n += 1
        prev = cc
    return n, sl


def main():
    d = json.load(open(sys.argv[1]))
    per = {}
    for r in d["regions"]:
        if r["image"] not in ("v10", "v9", "v7") or not mine(r["rel"]):
            continue
        k = (r["image"], r["rel"])
        t = per.setdefault(k, dict.fromkeys(GRADES + ["TARGET"], 0))
        t[r["grade"]] = t.get(r["grade"], 0) + r["size"]
        if is_target(r):
            t["TARGET"] += r["size"]
    hdr = "%-4s %-40s" % ("img", "file") + "".join("%9s" % g for g in GRADES) + \
        "%9s%9s%9s" % ("TARGET", "markers", "romslice")
    print(hdr)
    tot = {}
    for (v, rel) in sorted(per):
        t = per[(v, rel)]
        mk, sl = markers_and_slices(v, rel)
        t["markers"], t["romslice"] = mk, sl
        if sum(t[g] for g in GRADES) == 0 and not mk:
            continue
        print("%-4s %-40s" % (v, rel) + "".join("%9d" % t[g] for g in GRADES) +
              "%9d%9d%9d" % (t["TARGET"], mk, sl))
        tt = tot.setdefault(v, dict.fromkeys(GRADES + ["TARGET", "markers", "romslice"], 0))
        for g in tt:
            tt[g] += t[g]
    for v, tt in sorted(tot.items()):
        print("%-4s %-40s" % (v, "TOTAL") + "".join("%9d" % tt[g] for g in GRADES) +
              "%9d%9d%9d" % (tt["TARGET"], tt["markers"], tt["romslice"]))


if __name__ == "__main__":
    main()
