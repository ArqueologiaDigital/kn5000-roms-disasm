#!/usr/bin/env python3
"""How many bytes did this working tree move from DATA to CODE, against HEAD?

QUESTION ANSWERED. Every conversion round quotes a CODE figure ("CODE 600,523 ->
600,755"). `l1_territory_map.py` gives the CURRENT figure; the previous one has
to come from somewhere, and reading it out of the last commit message is how a
stale number survives a round that did not do what it claimed.

This runs the SAME classifier twice: once on the working tree, once on a copy in
which every file `git diff HEAD -- v7/maincpu` names has been restored to its
HEAD content. Untracked files (new romslices) are left in the copy, which is
correct: at HEAD nothing includes them, so they emit no bytes.

⚠ The classifier's own invariant is asserted here too -- classified total must
equal the 2,097,152-byte ROM, and no directive may be unrecognised -- so a tree
this cannot size exactly fails loudly instead of reporting a plausible delta.

    python3 scripts/analysis/v7_code_delta_vs_head.py

MEASURED 2026-08-22, after convert_reachable_ranges.py gained the .incbin split:

    CODE     HEAD   600,755   now   607,450   delta +6,695
    DATA     HEAD 1,429,645   now 1,422,950   delta -6,695

and the converter's own `converted N range(s), M bytes` line printed the same
6,695, which is the check that makes either number worth quoting.
"""
import importlib.util
import os
import shutil
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
_spec = importlib.util.spec_from_file_location(
    "l1", os.path.join(REPO, "scripts/analysis/l1_territory_map.py"))
l1 = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(l1)
ROMSIZE = 2097152


def totals(root):
    l1.ROOT = root
    terr, pos, unknown = l1.classify("v7/maincpu/kn5000_v7_program.s", "v7/maincpu")
    if unknown:
        sys.exit(f"unclassified directive(s) in {root}: {unknown[:5]}")
    if pos != sum(terr.values()) or pos != ROMSIZE:
        sys.exit(f"{root} classifies {pos} bytes, expected {ROMSIZE}")
    return terr


def main():
    work = tempfile.mkdtemp(prefix="v7_code_delta_")
    shutil.copytree(os.path.join(REPO, "v7/maincpu"),
                    os.path.join(work, "v7", "maincpu"), symlinks=True)
    mod = subprocess.run(["git", "diff", "--name-only", "HEAD", "--", "v7/maincpu"],
                         cwd=REPO, capture_output=True, text=True).stdout.split()
    for rel in mod:
        blob = subprocess.run(["git", "show", f"HEAD:{rel}"], cwd=REPO,
                              capture_output=True).stdout
        open(os.path.join(work, rel), "wb").write(blob)
    print(f"{len(mod)} file(s) restored to HEAD in the copy")
    head, now = totals(work), totals(REPO)
    for k in ("CODE", "DATA", "PADDING"):
        print(f"  {k:8} HEAD {head[k]:>9,}   now {now[k]:>9,}   "
              f"delta {now[k] - head[k]:+,}")
    shutil.rmtree(work, ignore_errors=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
