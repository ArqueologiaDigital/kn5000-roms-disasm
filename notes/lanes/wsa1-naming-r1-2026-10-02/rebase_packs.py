#!/usr/bin/env python3
"""rebase_packs.py -- carry the round-1 naming packs (made at AT_COMMIT) onto the current tree.

QUESTION THIS ANSWERS
  Which of each pack's renames still apply?  Later work renamed some of the same routines (the
  display-list drawers, 2026-10-03), so a pack made at AT_COMMIT names OLD labels that no longer
  exist and fails `apply_label_edits.py --check` as a whole.  This keeps a rename only when its OLD
  name is still defined exactly once and its NEW name is defined nowhere, keeps a header only when
  its label is a kept rename's NEW name (or still defined), and writes `rebased/<pack>.json`, which
  carries `"verified": false` like its source.  Its `also` lists prom_b and the two linker scripts,
  which reference prom_a's names (prom_b through `.set sub_X, 0xX` aliases); apply_label_edits.py
  renames there too.  It prints, per pack, kept / dropped and why.

USAGE (repository root)
  python3 notes/lanes/wsa1-naming-r1-2026-10-02/rebase_packs.py
  python3 scripts/tools/apply_label_edits.py --check notes/lanes/wsa1-naming-r1-2026-10-02/rebased/<pack>.json
"""
import collections
import glob
import json
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
os.makedirs(os.path.join(HERE, "rebased"), exist_ok=True)
for p in sorted(glob.glob(os.path.join(HERE, "packs", "*.json"))):
    pk = json.load(open(p))
    defs = collections.Counter()
    for f in pk["files"]:
        for l in open(f, "rb").read().decode("latin-1").split("\n"):
            m = re.match(r'^([A-Za-z_.$][\w.$@]*):', l) or re.match(r'^\s*\.(?:set|equ)\s+([A-Za-z_.$][\w.$@]*)\s*,', l)
            if m:
                defs[m.group(1)] += 1
    keep, why = [], collections.Counter()
    for r in pk["renames"]:
        if defs[r["old"]] != 1:
            why["old gone (renamed since)"] += 1
        elif defs[r["new"]]:
            why["new already defined"] += 1
        else:
            keep.append(r)
    news = {r["new"] for r in keep}
    hdr = [h for h in pk.get("headers", []) if h["label"] in news or defs[h["label"]] == 1]
    # prom_b's thunks jump to prom_a's names (`T_F41978: jp sub_F9C9F4`) and the linker scripts carry
    # cross-ROM names: a pack that renamed in prom_a alone would break the link.  The packs listed
    # prom_a only.
    also = [f for f in ("wsa1/prom_b/wsa1_prom_b.s", "wsa1/prom_a/prom_a.ld", "wsa1/prom_b/prom_b.ld")
            if f not in pk["files"]]
    out = dict(pk, also=also, renames=keep, headers=hdr, rebased_from=os.path.relpath(p, HERE))
    json.dump(out, open(os.path.join(HERE, "rebased", os.path.basename(p)), "w"), indent=1)
    print("%-12s kept %3d of %3d renames, %3d of %3d headers; dropped %s" % (
        pk["name"] if len(pk["name"]) < 13 else os.path.basename(p)[:-5], len(keep), len(pk["renames"]),
        len(hdr), len(pk.get("headers", [])), dict(why)))
