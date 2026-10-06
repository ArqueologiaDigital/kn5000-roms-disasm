#!/usr/bin/env python3
"""label_v7_table_entries_from_v10.py -- give unlabelled v7 table targets the label v10 has in the same slot.

QUESTION IT ANSWERS / WHAT IT DOES
  For every pointer table (dispatch census detector A) that v7 and v10 both have, under the same name and with the
  same number of entries, slot k of v7 and slot k of v10 dispatch the same thing.  Where v7's entry lands on an
  instruction with no label (spelled `Label + N`) and v10's entry is a plain label L, this script places L at
  v7's target. It does so only when all of these hold:
    * the first 8 bytes at the two targets agree at >= 6 positions including the first (absolute operands
      differ between the versions);
    * every slot that names the same v7 target asks for the same L;
    * L is not defined in v7 yet.
  The entry is then spelled with L.  Example: v7 SeqChan_CommandHandlers[1] = `SeqChan_UnhandledCmd + 1`, v10's
  slot is SeqChan_UnhandledCmd_0x01, and both targets are the second of a run of `ret`s.
  SEE ALSO scripts/tools/v7_table_entries_from_v10.py, which does the same from a list of positional aliases and
  v10's source line at the same label offset, and label_v7_from_v10_hints.py (the `; v10: NAME` hint comments).

RUN (repository root; built tree; census maps of this tree state: scripts/analysis/dispatch_table_census/build_maps.py)
  python3 scripts/tools/label_v7_table_entries_from_v10.py [--apply]       # then make all
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


def main():
    m7, m10 = census.load("v7"), census.load("v10")
    t10 = {t["name"]: t for t in census.detect_A("v10") if t["name"]}
    defined7 = set(m7["byname"])
    want = collections.defaultdict(set)
    entries = collections.defaultdict(list)
    for t in census.detect_A("v7"):
        u = t10.get(t["name"])
        if not u or len(u["ents"]) != len(t["ents"]):
            continue
        for e7, e10 in zip(t["ents"], u["ents"]):
            if e7["tcls"] != "nolabel" or e7["owner"] != "v7" or e10["tcls"] != "code":
                continue
            if not re.match(r'^[A-Za-z_]\w*$', e10["op"]) or e10["op"] in defined7:
                continue
            a7, a10 = e7["val"], e10["val"]
            x = m7["raw"][a7 - m7["base"]:a7 - m7["base"] + 8]
            y = m10["raw"][a10 - m10["base"]:a10 - m10["base"] + 8]
            if x[:1] != y[:1] or sum(p == q for p, q in zip(x, y)) < 6:
                continue
            want[a7].add(e10["op"])
            entries[a7].append((t["name"], e7["at"]))
    edits = collections.defaultdict(list)
    names = {}
    for a7, ns in sorted(want.items()):
        if len(ns) != 1:
            print("  skip 0x%06X: slots ask for %s" % (a7, sorted(ns)))
            continue
        nm = ns.pop()
        if nm in names.values():
            print("  skip 0x%06X: %s already placed elsewhere" % (a7, nm))
            continue
        r = census.find(m7, a7)
        assert r and r[0] == a7 and census.is_insn_row("v7", r) and not r[7], (nm, hex(a7))
        names[a7] = nm
        edits[r[2]].append((r[3], [nm + ":"]))
        for tname, at in entries[a7]:
            tr = census.find(m7, at)
            mm = re.match(r'^(\s*\.long\s+)(\S.*?)(\s*;.*)?$', tr[6])
            assert tr[0] == at and mm and "+" in mm.group(2), (tname, tr[6])
            edits[tr[2]].append((tr[3], mm.group(1) + nm))
    for a7, nm in sorted(names.items()):
        print("v7 0x%06X  %-40s %s" % (a7, nm, ", ".join("%s@%06X" % e for e in entries[a7])))
    print("%d targets labelled" % len(names))
    if not APPLY:
        return
    root = os.path.join(REPO, "v7/maincpu")
    for rel, ops in edits.items():
        p = os.path.join(root, rel)
        L = open(p, "rb").read().decode("latin-1").split("\n")
        for li, op in sorted(ops, key=lambda x: (-x[0], isinstance(x[1], str))):
            if isinstance(op, str):
                L[li] = op
            else:
                L[li:li] = op
        data = "\n".join(L).encode("latin-1")
        open(p + ".tmp", "wb").write(data)
        os.replace(p + ".tmp", p)


if __name__ == "__main__":
    main()
