"""merge_proposals.py WORKDIR N|proposals_X.json ... -- WORKDIR/proposals_batchN.json (or proposals_X.json) + WORKDIR/inventory.json -> WORKDIR/reviewed-batchN.json (reviewed-X.json).
Adds asm, size, blob and off_v10 from the inventory.  A piece check that is false on the piece's own bytes but true on
the slice's is marked check_on = "slice" (written with slice offsets).  A later piece that kept the slice's old label is
renamed, because the converter moves the old label to piece 0."""
import json, os, struct, sys
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
os.chdir(sys.argv[1])
inv = {(x["label"] or (x["blob"], x["off"])): x for x in json.load(open("inventory.json"))}   # unlabelled: by (blob, off)
for n in sys.argv[2:]:
    src = n if n.endswith(".json") else "proposals_batch%s.json" % n       # a batch number, or a proposals file
    n = os.path.basename(src)[len("proposals_"):-len(".json")] if n.endswith(".json") else "batch%s" % n
    P = json.load(open(src))
    out = []
    for r in P:
        x = inv[r["label"] or (r["blob"], r["off"])]
        r = dict(r)
        r.update(asm=x["asm"], size=x["size"], blob=x["blob"], off_v10=x["off"])
        if not x["label"]:
            r["after_label"] = x["after_label"]
        sb = open(os.path.join(ROOT, "v10/maincpu/includes/generated", x["blob"] + ".bin"), "rb").read()[x["off"]:x["off"] + x["size"]]
        for p in (r.get("pieces") or []):
            if not p.get("check"):
                continue
            pb = sb[p["off_in_slice"]:p["off_in_slice"] + p["size"]]
            def ev(b):
                try:
                    return bool(eval(p["check"], {"struct": struct, "b": b}))
                except Exception:
                    return False
            if not ev(pb):
                assert ev(sb), (r["label"], p["new_label"], "check false on piece and slice")
                p["check_on"] = "slice"         # the check was written with slice offsets
        for i, p in enumerate(r.get("pieces") or []):
            if i and p["new_label"] == r["label"]:      # a later piece may not keep the slice's old name (the rename moves it)
                new = p["new_label"] + ("_Str" if p["ctype"] == "char" else "_Item")
                p["header"] = [h.replace(p["new_label"] + " --", new + " --", 1) for h in p["header"]]
                p["new_label"] = new
                r.setdefault("review_notes", []).append("piece %d renamed %s: the slice's old label moves to piece 0" % (i, new))
        out.append(r)
    json.dump(out, open("reviewed-%s.json" % n, "w"), indent=1)
    print(n, len(out), sum(r.get("verdict") == "type" for r in out))
