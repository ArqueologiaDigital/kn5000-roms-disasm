#!/usr/bin/env python3
"""apply_kn5000_naming_proposals.py -- apply reviewed caller-based routine names to the KN5000 trees (v10/v9/v7).

QUESTION IT ANSWERS
  analysis/kn5000-naming/proposals-*.json record names for generically-named routines (X_Helper7 ...).  Each name
  was read from the routine's callers and its body, with file:line evidence; see that directory's README.  This
  script applies every record with verdict "name" to every tree that defines the old label:
    - the new name must not be defined anywhere in that tree;
    - the record's header (one or two lines) goes above the label line;
    - the label is renamed in the tree's *.s, *.ld and *.h files, and in *.c code segments only (never inside a C
      comment, which the C comment gate protects);
    - the rules are written to scripts/renaming/rename_kn5000_naming_<tag>_<tree>.sed.
  v9 and v7 are NOT renamed by name: an old generic label there can sit on other code.  They take the new names
  from scripts/renaming/harmonize_version_labels.py --to v9 / --to v7 (address correspondence with a byte proof).

RUN (repository root)
  python3 scripts/renaming/apply_kn5000_naming_proposals.py TAG proposals.json ... [--apply]
  python3 scripts/renaming/apply_kn5000_naming_proposals.py --tree v142/subcpu TAG proposals.json ... [--apply]
  then: make all; harmonize_version_labels.py --to v9 --apply; --to v7 --apply; make gate-all;
        python3 scripts/analysis/l2_symbol_reference.py --regen && --check
"""
import glob
import json
import os
import re
import subprocess
import sys
import textwrap

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "scripts/converters"))
from name_resname_strings import segments   # noqa: E402

APPLY = "--apply" in sys.argv
# v10 only: the names were read in v10, and an old generic label of v9 / v7 need not sit on the same code (v7's
# Scoop_SoundEditorData_Helper5 is v10's SeMenu_CyclePartLfoState).  v9 and v7 take the new names afterwards from
# scripts/renaming/harmonize_version_labels.py, which matches code by address and proves it by the bytes.
TREES = ("v10",)
# --tree DIR: a single-version image instead (v142/subcpu, hdae5000, subcpu/boot); evidence paths are relative to it
TREE_DIR = None
if "--tree" in sys.argv:
    TREE_DIR = sys.argv[sys.argv.index("--tree") + 1]
    sys.argv[sys.argv.index("--tree"):sys.argv.index("--tree") + 2] = []
    TREES = (TREE_DIR,)
ARGS = [a for a in sys.argv[1:] if a != "--apply"]
TAG, FILES = ARGS[0], ARGS[1:]


def main():
    recs = [r for f in FILES for r in json.load(open(f)) if r.get("verdict") == "name"]
    olds = [r["old"] for r in recs]
    news = [r["new"] for r in recs]
    assert len(set(olds)) == len(olds) and len(set(news)) == len(news), "duplicate old or new name"
    for tree in TREES:
        tdir = os.path.join(ROOT, tree if TREE_DIR else os.path.join(tree, "maincpu"))
        srcs = sorted(glob.glob(os.path.join(tdir, "**", "*.s"), recursive=True))
        defs = {}
        for p in srcs:
            for i, x in enumerate(open(p, "rb").read().decode("latin-1").split("\n")):
                m = re.match(r'^([A-Za-z_][\w$]*):', x)
                if m:
                    defs.setdefault(m.group(1), (p, i))
        ren, skipped = [], []
        for r in recs:
            if r["old"] not in defs:
                skipped.append((r["old"], "not defined"))
            elif r["new"] in defs:
                skipped.append((r["old"], "%s already defined" % r["new"]))
            else:
                ren.append(r)
        print("%s: %d renames, %d skipped" % (tree, len(ren), len(skipped)))
        for s in skipped:
            print("    skip %-44s %s" % s)
        if not APPLY or not ren:
            continue
        # headers above the definitions
        byfile = {}
        for r in ren:
            p, i = defs[r["old"]]
            byfile.setdefault(p, []).append((i, r))
        for p, items in byfile.items():
            L = open(p, "rb").read().decode("latin-1").split("\n")
            for i, r in sorted(items, key=lambda x: -x[0]):
                h = " ".join((r.get("header") or "").split())
                if not h:
                    continue                     # switch-case records usually carry no header (cases-*.json)
                lines = ["; " + x for x in textwrap.wrap("%s: %s" % (r["new"], h), 116, subsequent_indent="  ")]
                if lines[0] not in L[max(0, i - 6):i]:
                    L[i:i] = lines
            data = "\n".join(L).encode("latin-1")
            open(p + ".tmp", "wb").write(data)
            os.replace(p + ".tmp", p)
        # the rename
        rmap = {r["old"]: r["new"] for r in ren}
        rx = re.compile(r'\b(%s)\b' % "|".join(sorted(map(re.escape, rmap), key=len, reverse=True)))
        hit = subprocess.run(["grep", "-rlwE", "|".join(map(re.escape, rmap)), tdir, "--include=*.s", "--include=*.c",
                              "--include=*.h", "--include=*.ld"], capture_output=True, text=True).stdout.split()
        for q in hit:
            t = open(q, "rb").read().decode("latin-1")
            if q.endswith(".c"):
                t = "".join(rx.sub(lambda m: rmap[m.group(1)], seg) if k == "code" else seg for k, seg in segments(t))
            else:
                t = rx.sub(lambda m: rmap[m.group(1)], t)
            data = t.encode("latin-1")
            open(q + ".tmp", "wb").write(data)
            os.replace(q + ".tmp", q)
        sed = os.path.join(ROOT, "scripts/renaming/rename_kn5000_naming_%s_%s.sed" % (TAG, tree.replace("/", "_")))
        open(sed, "w").write("# written by scripts/renaming/apply_kn5000_naming_proposals.py\n"
                             + "".join("s/\\b%s\\b/%s/g\n" % (o, n) for o, n in rmap.items()))
        print("    renamed in %d files" % len(hit))


if __name__ == "__main__":
    main()
