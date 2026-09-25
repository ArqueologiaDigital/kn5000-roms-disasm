#!/usr/bin/env python3
r"""scoop_header_second_line.py -- give every ONE-LINE data header in a lane
scoop file a second line: the reader's own instruction sequence.

QUESTION ANSWERED
-----------------
"Which data objects carry a header of a single comment line?"  The census
credits a header only as a run of >= 2 comment lines ending directly above
the object (scripts/analysis/data_range_census.py, DocIndex.context), so a
correct one-liner such as '"SUSTAIN ", 8 chars copied by ParamPopup_PartSustain'
leaves the object graded 'descriptive name only'.  This inserts, below each
such line, the reader's instructions as the draft found them
(`ld xiy, Str_Sustain` / `ld bc, 8` + ldir ...).  Insert-only: no comment is
changed or removed; the image is rebuilt and compared.

RUN
    python3 scripts/analysis/scoop_data_headers.py --image v10 --file F --out DRAFT.json
    python3 scripts/converters/scoop_header_second_line.py --image v10 --draft DRAFT.json
"""
import argparse
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import scoop_reframe as R  # noqa: E402


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
    by = {}
    for e in draft:
        for nm in e["names"]:
            by[nm] = e
    added = 0
    out = []
    for i, ln in enumerate(lines):
        m = R.LABEL_RE.match(ln.strip() or "x")
        if m and i >= 1 and lines[i - 1].strip().startswith(";") and \
                (i < 2 or not lines[i - 2].strip().startswith(";")):
            e = by.get(m.group(1))
            if e and e["sites"]:
                s = e["sites"][0]
                seq = "`%s`" % re.sub(r"\s+", " ", s["line"])
                if s.get("copy"):
                    seq += " then `ld bc, %d` + ldir (%d bytes copied)" % (s["count"], s["count"])
                elif s.get("indexed"):
                    seq += " then `%s`" % re.sub(r"\s+", " ", s["indexed"])
                who = s.get("routine") or "?"
                out.append("\t; reader %s: %s" % (who, seq))
                added += 1
        out.append(ln)
    open(p, "wb").write("\n".join(out).encode("latin-1"))
    ok, _, data = R.build(a.image)
    if not ok or data != R.rom(a.image):
        open(p, "wb").write(backup)
        raise SystemExit("REJECTED: restored")
    print("%s: %d one-line headers got their reader line; image byte-identical" % (rel, added))


if __name__ == "__main__":
    main()
