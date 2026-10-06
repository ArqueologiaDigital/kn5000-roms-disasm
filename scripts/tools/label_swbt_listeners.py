#!/usr/bin/env python3
"""label_swbt_listeners.py -- place labels at the unlabelled entries of the SwbtWr listener tables (v10/v9/v7).

QUESTION IT ANSWERS / WHAT IT DOES
  SwbtWr_DispatchLoop (audio/dsp_config_sysex.s) calls, for each queued SwbtWr event, every callback of the
  listener table its bank keeps for the event's code (`SwbtB2_Code63_Listeners`: `.long`s ended by
  0xFFFFFFFF; codes 0x00-0xBF are the panel-record tags, 0xA8/0xA9/0xAA the panel command / LCD-button / raw
  panel-change classes of technics-docs control-panel-protocol.md).  The dispatch census lists the entries that
  land on an instruction with no label, spelled `Label + N`.  The table gives each such entry its context
  (which bank, which event), so this script labels it from the table, never from the body:
    a bare `ret`                         <Table minus "s">  ->  SwbtB2_Code69_NopListener
    the one routine three bank-3 tables  SwbtB3_OnPanelEvent (the 0xA8, 0xA9 and 0xAA listeners all call it)
    share
    any other entry                      <Table minus "s"> (SwbtB2_Code63_Listener, SwbtBank2_PostCallback),
                                         with the entry's position when one table has several
  and respells the table entry with the new label.

RUN (repository root; census maps of this tree state: scripts/analysis/dispatch_table_census/build_maps.py)
  python3 scripts/tools/label_swbt_listeners.py v10 [--apply]       # also v9, v7; then make all
"""
import collections
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "scripts/analysis/dispatch_table_census"))
ARGS = sys.argv[1:]
sys.argv = sys.argv[:1]
import census  # noqa: E402

TREE = {"v10": "v10/maincpu", "v9": "v9/maincpu", "v7": "v7/maincpu"}
TABLE = re.compile(r'^Swbt(B\d_Code[0-9A-F]{2}_Listeners|Bank\d_PostCallbacks)$')


def main():
    key = ARGS[0]
    apply = "--apply" in ARGS
    m = census.load(key)
    rows = m["rows"]
    raw, base = m["raw"], m["base"]
    tabs = [t for t in census.detect_A(key) if t["name"] and TABLE.match(t["name"])]
    by_target = collections.defaultdict(list)
    for t in tabs:
        for k, e in enumerate(t["ents"]):
            if e["tcls"] == "nolabel" and e["owner"] == key:
                by_target[e["val"]].append((t["name"], k, e["at"]))
    in_use = set(m["byname"]) | {r[7] for r in rows if r[7]}
    names = {}
    for val, uses in sorted(by_target.items()):
        tables = sorted({u[0] for u in uses})
        if raw[val - base] == 0x0E:                               # ret
            nm = tables[0][:-1].replace("_Listener", "_NopListener").replace("_PostCallback", "_NopPostCallback")
        elif len(tables) > 1:
            assert set(tables) == {"SwbtB3_CodeA8_Listeners", "SwbtB3_CodeA9_Listeners", "SwbtB3_CodeAA_Listeners"}, tables
            nm = "SwbtB3_OnPanelEvent"
        else:
            nm = tables[0][:-1]
            same = [u for u in by_target.items() if u[0] != val and any(x[0] == tables[0] for x in u[1])]
            if same:
                nm = "%s%d" % (nm, uses[0][1])
        assert nm not in in_use, (key, nm)
        in_use.add(nm)
        names[val] = (nm, uses)
    edits = collections.defaultdict(list)
    for val, (nm, uses) in names.items():
        r = census.find(m, val)
        assert r and r[0] == val and not r[7], (key, hex(val))
        edits[r[2]].append((r[3], [nm + ":"]))
        for tname, k, at in uses:
            tr = census.find(m, at)
            assert tr and tr[0] == at and tr[5] == ".long", (key, tname, hex(at))
            text = tr[6]
            mm = re.match(r'^(\s*\.long\s+)(\S.*?)(\s*;.*)?$', text)
            assert mm and "+" in mm.group(2), (key, text)
            edits[tr[2]].append((tr[3], "%s%s" % (mm.group(1), nm)))
    for val, (nm, uses) in sorted(names.items()):
        print("%s  0x%06X  %-34s %s" % (key, val, nm, ", ".join("%s[%d]" % (u[0], u[1]) for u in uses)))
    if not apply:
        return
    root = os.path.join(REPO, TREE[key])
    for rel, ops in edits.items():
        p = os.path.join(root, rel)
        L = open(p, "rb").read().decode("latin-1").split("\n")
        for li, op in sorted(ops, key=lambda x: (-x[0], isinstance(x[1], str))):
            if isinstance(op, str):
                L[li] = op                                         # respell the .long entry
            else:
                L[li:li] = op                                      # label line before the instruction
        data = "\n".join(L).encode("latin-1")
        open(p + ".tmp", "wb").write(data)
        os.replace(p + ".tmp", p)


if __name__ == "__main__":
    main()
