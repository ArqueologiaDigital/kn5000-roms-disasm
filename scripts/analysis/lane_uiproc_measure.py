#!/usr/bin/env python3
r"""HOW MUCH OF LANE `uiproc`'S FILES IS UNDERSTOOD?  (before/after instrument)

QUESTION ANSWERED
-----------------
For the twelve files lane `uiproc` owns (ui/drawbar_panel_ui.s, ui_widget_defs.s,
ui_mode_handlers.s, ui_window_procs.s under v10/, v9/ and v7/maincpu), report:

* census bytes by grade (CODE / KNOWN-A / KNOWN-B / UNKNOWN / FILLER) and the
  RESEARCH-TARGET bytes (data_range_census.is_target: UNKNOWN, self-admitted, or
  embedded-in-code), read from a `data_range_census.py --json` file;
* v7 romslice bytes (`.incbin "includes/romslices/..."`) still in the files;
* data-as-code marker lines (the regex lane_worklists.py uses: halt/incf/decf/
  ldf/normal/max/min/swi, `jr cc,0`, `jr f`, nop-nop);
* numeric branch operands (`jr z, 17`, `calr 2716`, `call 16569399`), the
  shape symbolize_numeric_branches.py converts;
* `.byte` lines (a crude count of raw byte statements).

RUN
    python3 scripts/analysis/data_range_census.py --images v10,v9,v7 --json C.json
    python3 scripts/analysis/lane_uiproc_measure.py C.json
    python3 scripts/analysis/lane_uiproc_measure.py --text-only   # no census needed
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
FILES = ["ui/drawbar_panel_ui.s", "ui/ui_widget_defs.s", "ui/ui_mode_handlers.s",
         "ui/ui_window_procs.s"]
IMAGES = ["v10", "v9", "v7"]
ABS = re.compile(r'^(halt|incf|decf|ldf|normal|max|min|swi)\b|^(jr|jrl)\s+[a-z]+\s*,\s*(0x)?0+$'
                 r'|^(jr|jrl)\s+f\s*,')
NUMBR = re.compile(r'^\s*(?:[A-Za-z_.$][\w.$@]*:\s*)?(jr|jrl|calr|call|jp)\s+'
                   r'(?:[a-z]+\s*,\s*)?(-?0x[0-9a-fA-F]+|-?\d+)\s*(?:;.*)?$')


def text_counts(path):
    L = open(path, encoding="latin-1").read().split("\n")
    prev, nabs, nnum, nbyte, slices = "", 0, 0, 0, 0
    for ln in L:
        c = ln.split(";")[0]
        m = re.search(r'\.incbin\s+"(includes/romslices/[^"]+)"', c)
        if m:
            full = os.path.join(ROOT, "v7/maincpu", m.group(1))
            slices += os.path.getsize(full) if os.path.exists(full) else 0
        if NUMBR.match(c):
            nnum += 1
        if re.match(r'^\s*(?:[\w.$]+:\s*)?\.byte\b', c):
            nbyte += 1
        cc = re.sub(r'^[\w.$]+:\s*', '', c.strip()).lower()
        if not cc or cc.startswith("."):
            prev = ""
            continue
        if ABS.match(cc) or (cc == "nop" and prev == "nop"):
            nabs += 1
        prev = cc
    return nabs, nnum, nbyte, slices


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    text_only = "--text-only" in sys.argv
    import data_range_census as drc
    agg = {}
    if not text_only:
        d = json.load(open(args[0]))
        for r in d["regions"]:
            if r["image"] not in IMAGES or r["rel"] not in FILES:
                continue
            k = (r["image"], r["rel"])
            a = agg.setdefault(k, {"CODE": 0, "KNOWN-A": 0, "KNOWN-B": 0, "UNKNOWN": 0,
                                   "FILLER": 0, "target": 0})
            a[r["grade"]] = a.get(r["grade"], 0) + r["size"]
            if drc.is_target(r):
                a["target"] += r["size"]
    tot = {}
    hdr = "%-4s %-24s %8s %7s %7s %7s %7s %8s %6s %6s %6s %7s" % (
        "img", "file", "CODE", "KN-A", "KN-B", "UNK", "FILL", "target", "absurd",
        "numbr", ".byte", "slices")
    print(hdr)
    for img in IMAGES:
        for f in FILES:
            a = agg.get((img, f), {})
            nabs, nnum, nbyte, sl = text_counts(os.path.join(ROOT, img, "maincpu", f))
            row = [a.get("CODE", 0), a.get("KNOWN-A", 0), a.get("KNOWN-B", 0),
                   a.get("UNKNOWN", 0), a.get("FILLER", 0), a.get("target", 0),
                   nabs, nnum, nbyte, sl]
            for i, v in enumerate(row):
                tot[i] = tot.get(i, 0) + v
            print("%-4s %-24s %8d %7d %7d %7d %7d %8d %6d %6d %6d %7d" % ((img, f) + tuple(row)))
    print("%-29s %8d %7d %7d %7d %7d %8d %6d %6d %6d %7d" % (("TOTAL",) + tuple(tot[i] for i in range(10))))


if __name__ == "__main__":
    main()
