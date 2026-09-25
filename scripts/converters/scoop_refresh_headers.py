#!/usr/bin/env python3
r"""scoop_refresh_headers.py -- re-derive the reader-cited headers that
scoop_auto_headers.py wrote, after the source changed under them.

QUESTION ANSWERED
-----------------
"Do the generated data headers in display/scoop_display.s still say what the
readers say?"  They can go stale in two ways, both seen in this lane: a
reader that loaded the table as a BARE NUMBER (v7 `ld xix, 15688317`) was
invisible to the by-name search, so the header wrongly said "No reader
found"; and "also read at file:line" references drift as lines move.  This
re-runs the draft for every object and replaces ONLY the generated header
block (recognised by its first line: "<Kind>, <N> B.  Read by ..." or
"<Kind>, <N> B.  No reader found ...") with the fresh one.  Hand-written
headers are never touched.  Byte-neutral (comments only); the image is
still rebuilt and compared.

RUN
    python3 scripts/analysis/scoop_data_headers.py --image v7 --file F --out DRAFT.json
    python3 scripts/converters/scoop_refresh_headers.py --image v7 --draft DRAFT.json
"""
import argparse
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import scoop_reframe as R  # noqa: E402
from scoop_auto_headers import clean  # noqa: E402

GEN = re.compile(r'^\t; (Handler dispatch table|Pointer table|Byte data|Lcd text|Uirender display list),'
                 r' \d+ B\.  (Read by|No reader found)')
CONT = re.compile(r'^\t; (indexed with stride|copies \d+ byte|handed in XIY|\d+ x 4-byte handler|index bounded'
                  r'|also read (at|by)|name at this address is loaded anywhere|scripts/analysis/scoop_data_headers\.py\);)')


def fresh_lines(e):
    if not e["sites"]:
        return ["%s, %d B.  No reader found: no label, positional or absolute .set"
                % (e["kind"].capitalize(), e["size"]),
                "name at this address is loaded anywhere in the image (searched by",
                "scripts/analysis/scoop_data_headers.py); purpose not established."]
    return [clean(x) for x in e["comment"]]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--draft", required=True)
    a = ap.parse_args()
    draft = json.load(open(a.draft))
    rel = draft[0]["file"]
    p = os.path.join(R.ROOT, rel)
    backup = open(p, "rb").read()
    lines = backup.decode("latin-1").split("\n")
    by_label = {}
    for e in draft:
        for nm in e["names"]:
            by_label[nm] = e
    changed = 0
    i = 0
    while i < len(lines):
        if GEN.match(lines[i]):
            j = i + 1
            while j < len(lines) and CONT.match(lines[j]):
                j += 1
            k = j
            while k < len(lines) and not R.LABEL_RE.match(lines[k].strip() or "x"):
                k += 1
            lab = R.LABEL_RE.match(lines[k].strip()).group(1) if k < len(lines) else None
            e = by_label.get(lab)
            if e and k - j <= 1:
                new = ["\t; " + x for x in fresh_lines(e)]
                if new != lines[i:j]:
                    lines[i:j] = new
                    changed += 1
                i += len(new)
                continue
            i = j
            continue
        i += 1
    open(p, "wb").write("\n".join(lines).encode("latin-1"))
    ok, _, data = R.build(a.image)
    if not ok or data != R.rom(a.image):
        open(p, "wb").write(backup)
        raise SystemExit("REJECTED: restored")
    print("%s: %d generated headers refreshed; image byte-identical" % (rel, changed))


if __name__ == "__main__":
    main()
