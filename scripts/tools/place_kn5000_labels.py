#!/usr/bin/env python3
"""place_kn5000_labels.py -- put new labels at v10 addresses that have none (table targets found by the census).

QUESTION IT ANSWERS
  The dispatch census lists table entries whose target is an instruction start WITHOUT a label (blocker
  `nolabel`).  A naming pass (analysis/kn5000-naming/proposals-*.json) gives each such address a name.  This
  script finds the source line that starts at the address and inserts `Name:` before it, with the record's
  one-line header above it.  It uses the census maps of the current tree (scripts/analysis/dispatch_table_census/
  build_maps.py first).  Each placement asserts that:
    - some source line starts exactly at the address (an instruction or data line, never mid-line);
    - no label is there yet;
    - the name is free in the tree.
  Records that carry `table_rename` (old table label -> new) are applied as plain renames (whole words, *.s / *.ld
  / *.h, code segments of *.c).  v9 and v7 take the labels afterwards from
  scripts/renaming/harmonize_version_labels.py, by address correspondence with a byte proof.

RUN (repository root; built tree, census maps built)
  python3 scripts/tools/place_kn5000_labels.py proposals.json [--apply] [--tree v7]   (addresses of that tree)
  then: make all; harmonize_version_labels.py --to v9/--to v7 --apply; make gate-all; l2 --regen/--check;
        symbolize_c_rom_pointers.py (+ the v7 flow) so C tables name the new labels; make dispatch-census
"""
import collections
import json
import os
import re
import subprocess
import sys
import textwrap

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "scripts/analysis/dispatch_table_census"))
sys.path.insert(0, os.path.join(REPO, "scripts/converters"))
ARGS = sys.argv[1:]
sys.argv = sys.argv[:1]
import census  # noqa: E402
from name_resname_strings import segments  # noqa: E402

KEY = "v10"
if "--tree" in ARGS:
    KEY = ARGS[ARGS.index("--tree") + 1]
    ARGS = [a for a in ARGS if a not in ("--tree", KEY)]
TREE = os.path.join(REPO, KEY, "maincpu")


def main():
    apply = "--apply" in ARGS
    recs = [r for f in ARGS if f.endswith(".json") for r in json.load(open(f))]
    places = [r for r in recs if r.get("addr") and r.get("new") and r.get("verdict", "name") == "name"]
    renames = [r for r in recs if r.get("table_rename") and r.get("new")]
    m = census.load(KEY)
    rows = m["rows"]
    in_use = set(m["byname"]) | {r[7] for r in rows if r[7]}
    edits = collections.defaultdict(list)
    done = 0
    for r in places:
        a = int(r["addr"], 16) if isinstance(r["addr"], str) else r["addr"]
        row = census.find(m, a)
        assert row and row[0] == a, ("no source line starts at", hex(a), r["new"])
        assert not row[7], ("already labelled", hex(a), row[7])
        assert r["new"] not in in_use, ("name taken", r["new"])
        in_use.add(r["new"])
        h = " ".join((r.get("header") or "").split())
        lines = ["; " + x for x in textwrap.wrap("%s: %s" % (r["new"], h), 116, subsequent_indent="  ")] if h else []
        edits[row[2]].append((row[3], lines + [r["new"] + ":"]))
        done += 1
    print("%s: %d labels to place, %d table renames" % (KEY, done, len(renames)))
    if not apply:
        return
    for rel, ops in edits.items():
        p = os.path.join(TREE, rel)
        L = open(p, "rb").read().decode("latin-1").split("\n")
        for line, new in sorted(ops, key=lambda x: -x[0]):
            L[line:line] = new
        data = "\n".join(L).encode("latin-1")
        with open(p + ".tmp", "wb") as fh:
            fh.write(data)
        os.replace(p + ".tmp", p)
    if renames:
        rmap = {r["table_rename"]: r["new"] for r in renames}
        for o, n in rmap.items():
            assert n not in in_use, ("name taken", n)
        rx = re.compile(r'\b(%s)\b' % "|".join(sorted(map(re.escape, rmap), key=len, reverse=True)))
        hit = subprocess.run(["grep", "-rlwE", "|".join(map(re.escape, rmap)), TREE, "--include=*.s", "--include=*.c",
                              "--include=*.h", "--include=*.ld"], capture_output=True, text=True).stdout.split()
        for q in hit:
            t = open(q, "rb").read().decode("latin-1")
            if q.endswith(".c"):
                t = "".join(rx.sub(lambda mm: rmap[mm.group(1)], s) if k == "code" else s for k, s in segments(t))
            else:
                t = rx.sub(lambda mm: rmap[mm.group(1)], t)
            data = t.encode("latin-1")
            with open(q + ".tmp", "wb") as fh:
                fh.write(data)
            os.replace(q + ".tmp", q)
        with open(os.path.join(REPO, "scripts/renaming/rename_kn5000_hidden_tables_v10.sed"), "a") as fh:
            fh.writelines("s/\\b%s\\b/%s/g\n" % (o, n) for o, n in rmap.items())


if __name__ == "__main__":
    main()
