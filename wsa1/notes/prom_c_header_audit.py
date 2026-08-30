#!/usr/bin/env python3
"""Which semantic labels in prom_c have NO evidence in the comment block above them?

QUESTION IT ANSWERS
  The round-1 audit measured "semantic labels with no line containing 'Evidence' in the comment
  block above" and got prom_c 44 of 92 for the labels added that round.  That is a number
  nobody could re-derive, and it over-states the problem: many labels sit under a SHARED block
  comment that argues its case at length without using the word.  This script makes the
  measurement reproducible and splits those two cases apart.

WHAT COUNTS AS A SEMANTIC LABEL
  A top-level label definition (`Name:` at column 0) that is NOT
    * `sub_XXXXXX` / `L_XXXXXX` / `loc_XXXXXX`  -- deliberately anonymous,
    * `Something__FCxxxx` / `Something__loop`   -- an INTERNAL label of a routine whose own
      header carries the evidence.
  Everything else asserts something and needs a citation.

WHAT COUNTS AS EVIDENCE
  Tier A  the contiguous `;` comment block immediately above the label contains a line with
          "Evidence" (the house convention).
  Tier B  it does not, but it cites something checkable anyway: a `notes/*.py` invocation, a
          `0xXXXXXX` address, or a "see <label>" / "see 0x" pointer.
  Tier C  neither -- the name is asserted and nothing in its own header backs it.

  ⚠ Tier B is NOT a pass.  It is printed separately because the fix for it is one word and the
  fix for tier C is research.

RUN
  python3 notes/prom_c_header_audit.py            # the summary and the tier-C list
  python3 notes/prom_c_header_audit.py --all      # every label, with its tier
  python3 notes/prom_c_header_audit.py --tier B   # just one tier
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# ⚠ prom_c is 26 files now (notes/prom_c_split.py): the master alone is 2% of
# the image, and this scan passed VACUOUSLY over it until this line changed.
# notes/prom_c_probe_health.py is the check; notes/prom_c_image.py is a shim
# that should become `from asm_source import ...` when that reader is green.
sys.path.insert(0, os.path.join(ROOT, "notes"))
import prom_c_image
SRC = prom_c_image.path()

LABEL = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):\s*(;.*)?$")
ANON = re.compile(r"^(sub|L|loc)_[0-9A-Fa-f]+$")
INTERNAL = re.compile(r"__")


def main():
    show_all = "--all" in sys.argv
    only = None
    if "--tier" in sys.argv:
        only = sys.argv[sys.argv.index("--tier") + 1].upper()

    lines = open(SRC, encoding="utf-8").read().split("\n")
    rows = []
    for i, ln in enumerate(lines):
        m = LABEL.match(ln)
        if not m:
            continue
        name = m.group(1)
        if ANON.match(name) or INTERNAL.search(name):
            continue
        # the contiguous comment block immediately above
        j = i - 1
        block = []
        while j >= 0 and (lines[j].lstrip().startswith(";") or lines[j].strip() == ""):
            if lines[j].strip() == "":
                if block:
                    break
                j -= 1
                continue
            block.append(lines[j])
            j -= 1
        text = "\n".join(block)
        if "Evidence" in text:
            tier = "A"
        elif re.search(r"notes/\w+\.py|0x[0-9A-Fa-f]{6}|\bsee\b", text):
            tier = "B"
        else:
            tier = "C"
        rows.append((tier, name, i + 1, len(block)))

    counts = {"A": 0, "B": 0, "C": 0}
    for t, _, _, _ in rows:
        counts[t] += 1
    total = len(rows)
    print("prom_c semantic labels (excluding sub_/L_/loc_ and internal `__` labels): %d" % total)
    print("  tier A -- header says \"Evidence\"                  : %3d  (%.0f%%)"
          % (counts["A"], 100.0 * counts["A"] / total))
    print("  tier B -- cites a tool, an address or another label: %3d  (%.0f%%)"
          % (counts["B"], 100.0 * counts["B"] / total))
    print("  tier C -- asserts a name and backs it with nothing : %3d  (%.0f%%)"
          % (counts["C"], 100.0 * counts["C"] / total))
    print()
    for t, name, line, n in rows:
        if show_all or (only and t == only) or (not show_all and not only and t == "C"):
            print("  %s  %-45s %s:%d   (%d comment line(s) above)"
                  % (t, name, "prom_c/wsa1_prom_c.s", line, n))
    if not show_all and not only:
        print()
        print("  (tier C listed above; `--tier B` for the one-word fixes, `--all` for everything)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
