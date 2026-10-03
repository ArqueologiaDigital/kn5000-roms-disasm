#!/usr/bin/env python3
"""apply_verdicts.py -- a reviewed round-1 pack: the rebased pack minus the renames its review rejected.

QUESTION THIS ANSWERS
  Which of a pack's renames survived an independent read of the code?  verdicts/<pack>.json records
  the review: which renames were read (`read`, index ranges into rebased/<pack>.json), how
  (`method`), and the rejected ones (`rejected`: {index: reason}) or renamed ones (`amended`:
  {index: [new name, reason]}).  This writes accepted/<pack>.json with "verified" set to that record,
  ready for `python3 scripts/tools/apply_label_edits.py accepted/<pack>.json`.

USAGE (repository root)
  python3 notes/lanes/wsa1-naming-r1-2026-10-02/apply_verdicts.py prom_a-s06
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
name = sys.argv[1]
pk = json.load(open(os.path.join(HERE, "rebased", name + ".json")))
v = json.load(open(os.path.join(HERE, "verdicts", name + ".json")))
rej = {int(k): r for k, r in v.get("rejected", {}).items()}
amd = {int(k): r for k, r in v.get("amended", {}).items()}
keep, old2new = [], {}
for i, r in enumerate(pk["renames"]):
    if i in rej:
        continue
    r = dict(r)
    if i in amd:
        r["new"], r["amended"] = amd[i][0], amd[i][1]
    keep.append(r)
    old2new[r["old"]] = r["new"]
dropped_new = {pk["renames"][i]["new"] for i in rej}
renamed_new = {pk["renames"][i]["new"]: amd[i][0] for i in amd}
hdr = []
for h in pk.get("headers", []):
    if h["label"] in dropped_new:
        continue
    hdr.append(dict(h, label=renamed_new.get(h["label"], h["label"])))
out = dict(pk, renames=keep, headers=hdr, verified=v)
os.makedirs(os.path.join(HERE, "accepted"), exist_ok=True)
json.dump(out, open(os.path.join(HERE, "accepted", name + ".json"), "w"), indent=1)
print("%s: %d accepted, %d rejected, %d amended, %d headers" % (name, len(keep), len(rej), len(amd), len(hdr)))
