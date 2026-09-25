#!/usr/bin/env python3
r"""scoop_auto_headers.py -- turn scoop_data_headers.py drafts into an annotate
spec for the data objects that still have no evidence header.

QUESTION ANSWERED
-----------------
"Which data objects of this file still carry no header, and what can be said
about each FROM ITS READER alone?"  For every drafted object that the census
does not already grade KNOWN-A (and that no hand-written spec covers), this
emits: a label when the object has none (named after its reader and its kind,
e.g. `PerfMode_ParamHandler_2_DispatchTbl`), the draft's reader-cited header,
and a rename of the positional `.set` names that pointed at it.  An object
with no reader gets an honest header that says so and what was searched.

Nothing here interprets; the headers only restate the reader's instructions.

RUN
    python3 scripts/analysis/scoop_data_headers.py --image v10 --file F --out DRAFT.json
    python3 scripts/converters/scoop_auto_headers.py --draft DRAFT.json \
        --census CENSUS.json --skip MANUAL.json --out SPEC.json
    python3 scripts/converters/scoop_annotate.py --image v10 --spec SPEC.json
"""
import argparse
import json
import re

KIND = {"handler dispatch table": "DispatchTbl", "pointer table": "PtrTbl",
        "LCD text": "Text", "byte data": "Tbl", "UIRender display list": "DisplayList"}


def clean(x):
    return re.sub(r'`([^`]*)`', lambda m: "`" + re.sub(r'\s+', ' ', m.group(1)) + "`", x)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--draft", required=True)
    ap.add_argument("--census", required=True)
    ap.add_argument("--skip", action="append", default=[])
    ap.add_argument("--out", required=True)
    a = ap.parse_args()
    draft = json.load(open(a.draft))
    rel = draft[0]["file"] if draft else ""
    img, crel = rel.split("/")[0], rel.split("/maincpu/")[1] if "/maincpu/" in rel else rel
    have = set()
    for r in json.load(open(a.census))["regions"]:
        if r["image"] == img and r["rel"] == crel and r["grade"] == "KNOWN-A" and r["addr"]:
            have.add(r["addr"])
    skip = set()
    inside = []
    used = set()
    for s in a.skip:
        for e in json.load(open(s)):
            skip.add(int(e["addr"], 16))
            if e.get("label"):
                used.add(e["label"])
            if e.get("label") == "Tbl_AccompPartNames":
                inside.append((int(e["addr"], 16), int(e["addr"], 16) + 52))
    spec = []
    for e in draft:
        ad = int(e["addr"], 16)
        if ad in have or ad in skip:
            continue
        sites = e["sites"]
        own = [x for x in e["names"] if not re.search(r'_0x[0-9A-Fa-f]+$', x)]
        lines = [clean(x) for x in e["comment"]]
        if not sites:
            lines = ["%s, %d B.  No reader found: no label, positional or absolute .set"
                     % (e["kind"].capitalize(), e["size"]),
                     "name at this address is loaded anywhere in the image (searched by",
                     "scripts/analysis/scoop_data_headers.py); purpose not established."]
        ent = {"file": rel, "addr": e["addr"], "comment": lines}
        # a reader-less object that sits inside a hand-documented one (the
        # positional names drawbar_panel_ui.s uses into Tbl_AccompPartNames)
        if any(lo < ad < hi for lo, hi in inside):
            continue
        if not own:
            base = sites[0]["routine"] if sites and sites[0].get("routine") else "Unref_%06X" % ad
            nm = "%s_%s" % (base, KIND.get(e["kind"], "Tbl"))
            if e["kind"] == "LCD text":
                t = "".join(c if c.isalnum() else " " for c in e["text"])
                w = [x.capitalize() for x in t.split()][:4]
                if w:
                    nm = "Str_" + "".join(w) + ("Eq" if e["text"].rstrip().endswith("=") else "")
            k, stem = 2, nm
            while nm in used:
                nm = "%s%d" % (stem, k)
                k += 1
            used.add(nm)
            ent["label"] = nm
            ent["rename"] = {x: nm for x in e["names"] if re.search(r'_0x[0-9A-Fa-f]+$', x)}
        if e["kind"] in ("handler dispatch table", "pointer table") and e["size"] % 4 == 0:
            ent["render"] = {"size": e["size"], "record": 4, "kind": "long"}
        spec.append(ent)
    # the comments quote the reader's instruction; re-point any positional
    # name that this spec renames, so the quote matches the source
    ren = {}
    for ent in spec:
        ren.update(ent.get("rename", {}))
    if ren:
        pat = re.compile(r'(?<![\w.$])(%s)(?![\w.$])' % "|".join(re.escape(o) for o in ren))
        for ent in spec:
            ent["comment"] = [pat.sub(lambda m: ren[m.group(1)], x) for x in ent["comment"]]
    json.dump(spec, open(a.out, "w"), indent=1)
    print("%d objects -> %s" % (len(spec), a.out))


if __name__ == "__main__":
    main()
