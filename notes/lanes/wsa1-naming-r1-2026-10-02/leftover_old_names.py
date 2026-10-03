#!/usr/bin/env python3
"""leftover_old_names.py -- after applying an accepted pack, where do its OLD names still occur?

QUESTION THIS ANSWERS
  apply_label_edits.py renames in the pack's files and `also` files.  Prose elsewhere (another CPU's
  comments, notes scripts' docstrings) may still quote an old `sub_XXXXXX`.  This lists, per file under
  wsa1/, how many such occurrences remain, so the pack's sed can be run over the prose ones.  Generators
  keyed by the old names (prom_a_understanding_round7.py) are reported too and are left alone.

  The headers a pack inserts are written AFTER its sed ran, and the namer's evidence quotes old names
  (`jrl sub_F82028`), so the pack's own file needs a second pass too.

USAGE (repository root)
  python3 notes/lanes/wsa1-naming-r1-2026-10-02/leftover_old_names.py prom_a-s00 [--fix]
    --fix  runs scripts/renaming/rename_<pack name>.sed over every listed file that is not a .py
           (assembly comments, findings notes); .py generators keep the names they are keyed by
"""
import subprocess
import glob
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
pk = json.load(open(os.path.join(HERE, "accepted", sys.argv[1] + ".json")))
pat = re.compile(r'\b(%s)\b' % "|".join(re.escape(r["old"]) for r in pk["renames"]))
for f in sorted(glob.glob("wsa1/**/*", recursive=True)):
    if not re.search(r'\.(s|inc|ld|py|md|txt)$', f):
        continue
    n = len(pat.findall(open(f, "rb").read().decode("latin-1")))
    if n:
        print("%5d  %s" % (n, f))
        if "--fix" in sys.argv and not f.endswith(".py"):
            sed = os.path.join("scripts", "renaming", "rename_%s.sed" % pk["name"])
            for _ in range(2):
                subprocess.run(["sed", "-i", "-f", sed, f], check=True)
            # the sed treats `.` as part of a name (`.LF9C7DC`), so `... through sub_F8A90B.` at the
            # end of a sentence survives it; a period followed by a blank or the line end is prose
            t = open(f, "rb").read().decode("latin-1")
            for r in pk["renames"]:
                t = re.sub(r'(?<![\w.$@])%s(?=\.(?:\s|$))' % re.escape(r["old"]), r["new"], t, flags=re.M)
            open(f, "wb").write(t.encode("latin-1"))
