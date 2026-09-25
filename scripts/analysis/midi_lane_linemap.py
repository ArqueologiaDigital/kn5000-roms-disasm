#!/usr/bin/env python3
r"""WHICH ADDRESS DOES EACH SOURCE LINE OF A MAINCPU IMAGE EMIT? (v10, v9 or v7)

QUESTION ANSWERED
-----------------
`address_line_map.py` answers this for v10 only.  The midi lane (2026-09-25)
needed the same map for v9 and v7, to port v10's re-framed data to the other
two versions and to read a table's bytes against its source lines.  This is a
thin driver over `data_range_census.py`'s own mirror/marker/link machinery (so
the map is built by the same, inertness-checked instrument the census uses):
it REFUSES to print anything if the marked mirror does not rebuild the dump
byte-identically.

RUN (from the repo root, after `make all` has produced includes/generated/)
    python3 scripts/analysis/midi_lane_linemap.py --image v9 --file midi/midi_dispatch_handlers.s
    python3 scripts/analysis/midi_lane_linemap.py --image v10 --addr 0xFD1309
    python3 scripts/analysis/midi_lane_linemap.py --image v7 --json OUT.json --file midi/x.s

OUTPUT: one row per emitting span:  <start> <end> <rel>:<line1based> <text>
"""
import argparse
import json
import os
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import data_range_census as drc  # noqa: E402


def build(key):
    img = [i for i in drc.IMAGES if i["key"] == key][0]
    tmp = tempfile.mkdtemp(prefix="midilm-")
    c = drc.census_image(img, tmp, verbose=False)
    import shutil
    shutil.rmtree(tmp, ignore_errors=True)   # /tmp is a shared tmpfs
    if not c["inert"]:
        sys.exit("REFUSED: the marked mirror of %s does not rebuild the dump" % key)
    return c


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True, choices=["v10", "v9", "v7"])
    ap.add_argument("--file", action="append", default=[],
                    help="restrict to these files (relative to <image>/maincpu)")
    ap.add_argument("--addr", action="append", default=[], help="print the span holding this address")
    ap.add_argument("--json")
    a = ap.parse_args()
    c = build(a.image)
    rows = []
    for (s, e, rel, li) in c["spans"]:
        if a.file and rel not in a.file:
            continue
        rows.append((s, e, rel, li, c["src"].text(rel, li)))
    if a.addr:
        for x in a.addr:
            v = int(x, 0)
            for r in rows:
                if r[0] <= v < r[1]:
                    print("0x%06X 0x%06X %s:%d %s" % (r[0], r[1], r[2], r[3] + 1, r[4].rstrip()))
        return
    if a.json:
        json.dump([dict(start=r[0], end=r[1], rel=r[2], line=r[3] + 1) for r in rows],
                  open(a.json, "w"))
        print("wrote %d spans to %s" % (len(rows), a.json))
        return
    for r in rows:
        print("0x%06X 0x%06X %s:%d %s" % (r[0], r[1], r[2], r[3] + 1, r[4].rstrip()))


if __name__ == "__main__":
    main()
