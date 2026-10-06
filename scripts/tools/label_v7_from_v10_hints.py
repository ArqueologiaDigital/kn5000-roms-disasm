#!/usr/bin/env python3
"""label_v7_from_v10_hints.py -- label v7 table targets with the name their v10 counterpart already has.

QUESTION IT ANSWERS / WHAT IT DOES
  When v7's sources were ported from v10, table entries whose v7 target had no label were spelled `Label + N`
  with a hint comment naming the v10 counterpart:
      .long VoiceSlot_CheckAndApply_Data + 175   ; no label at this callback entry yet; v10: UIState_ProcessKeyEvent
  The table position fixes the correspondence (same table, same slot in both versions), so the v10 name is the
  v7 routine's name.  For every such line this script checks, in v7's census map, that the target is an
  instruction start with no label, that every hint for that address names the same routine, and that the name is
  not already defined in v7; then it places the label and spells the entries with it (the hint comment goes).

RUN (repository root; census maps of this tree state: scripts/analysis/dispatch_table_census/build_maps.py)
  python3 scripts/tools/label_v7_from_v10_hints.py [--apply]       # then make all
"""
import collections
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "scripts/analysis/dispatch_table_census"))
APPLY = "--apply" in sys.argv
sys.argv = sys.argv[:1]
import census  # noqa: E402

HINT = re.compile(r'^(\s*\.long\s+)([A-Za-z_]\w*)\s*\+\s*(\d+)\s*;\s*no label at this \w+ entry yet; v10: (\w+)\s*$')


def main():
    m = census.load("v7")
    rows = m["rows"]
    want = collections.defaultdict(set)
    lines = []
    for r in rows:
        mm = HINT.match(r[6]) if r[5] == ".long" else None
        if mm:
            val = census.le(m, r[0], 4)
            want[val].add(mm.group(4))
            lines.append((r, mm, val))
    in_use = set(m["byname"]) | {r[7] for r in rows if r[7]}
    names, edits = {}, collections.defaultdict(list)
    for val, ns in sorted(want.items()):
        assert len(ns) == 1, (hex(val), ns)
        nm = ns.pop()
        assert nm not in in_use, nm
        r = census.find(m, val)
        assert r and r[0] == val and census.is_insn_row("v7", r) and not r[7], (nm, hex(val), r and r[:8])
        names[val] = nm
        edits[r[2]].append((r[3], [nm + ":"]))
    for r, mm, val in lines:
        assert (m["byname"].get(mm.group(2), -1) + int(mm.group(3))) == val, r[6]
        edits[r[2]].append((r[3], mm.group(1) + names[val]))
    print("v7: %d targets labelled from v10 hints, %d table entries respelled" % (len(names), len(lines)))
    if not APPLY:
        for val, nm in sorted(names.items())[:10]:
            print("  0x%06X %s" % (val, nm))
        return
    root = os.path.join(REPO, "v7/maincpu")
    for rel, ops in edits.items():
        p = os.path.join(root, rel)
        L = open(p, "rb").read().decode("latin-1").split("\n")
        for li, op in sorted(ops, key=lambda x: -x[0]):
            if isinstance(op, str):
                L[li] = op
            else:
                L[li:li] = op
        data = "\n".join(L).encode("latin-1")
        open(p + ".tmp", "wb").write(data)
        os.replace(p + ".tmp", p)


if __name__ == "__main__":
    main()
