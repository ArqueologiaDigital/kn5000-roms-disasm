#!/usr/bin/env python3
"""orphan_sources.py -- which .s files does no build ever assemble?

QUESTION THIS ANSWERS
  The Makefile lists every `*.s` under a tree as a dependency (wildcards), so a file that the
  top-level source never `.include`s still looks like part of the build.  Walks the `.include`
  graph from each top-level file (an include may follow a label: `GUI_FormatStrings: .include
  "..."`) and prints the files it never reaches.

USAGE
  python3 notes/orphan-sources-2026-10-02/orphan_sources.py
"""
import glob
import os
import re
import subprocess

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
TOPS = ("v10/maincpu/kn5000_v10_program.s", "v9/maincpu/kn5000_v9_program.s",
        "v7/maincpu/kn5000_v7_program.s", "hdae5000/hd-ae5000_v2_06i.s",
        "table_data/kn5000_table_data.s", "custom_data/kn5000_custom_data.s",
        "v142/subcpu/kn5000_subprogram_v142.s", "subcpu/boot/kn5000_subcpu_boot.s")
INC = re.compile(r'^(?:[A-Za-z_][\w.$]*:)?\s*\.include\s+"([^"]+)"')

for top in TOPS:
    top = os.path.join(REPO, top)
    if not os.path.exists(top):
        continue
    root, seen, stack = os.path.dirname(top), set(), [top]
    while stack:
        f = stack.pop()
        if f in seen or not os.path.exists(f):
            continue
        seen.add(f)
        for l in open(f, "rb").read().decode("latin-1").split("\n"):
            m = INC.match(l)
            if m:
                for base in (os.path.dirname(f), root):
                    p = os.path.normpath(os.path.join(base, m.group(1)))
                    if os.path.exists(p):
                        stack.append(p)
                        break
    allf = set(os.path.normpath(p) for p in glob.glob(os.path.join(root, "**", "*.s"), recursive=True))
    orphans = sorted(allf - seen)
    print("%s: %d assembled, %d never included" % (os.path.relpath(top, REPO), len(seen), len(orphans)))
    for o in orphans:
        print("    %s (%d B)" % (os.path.relpath(o, REPO), os.path.getsize(o)))
