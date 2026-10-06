"""verify_proposals.py WORKDIR/proposals_batchN.json ... -- for every proposal: the type's size equals the slice or
piece, its check is true on the v10 bytes, and every cited `file:line` `instruction` exists (the instruction's mnemonic
and first operand found within 3 lines of the cited one).  Prints one row per slice; flags are ev-miss / check / size.
Reads inventory.json from the proposals file's directory."""
import json, os, re, struct, sys
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
SZ = {"uint8_t": 1, "int8_t": 1, "char": 1, "uint16_t": 2, "int16_t": 2, "uint32_t": 4, "int32_t": 4}
def nel(d):
    n = 1
    for k in re.findall(r'\[([^\]]+)\]', d or ""):
        n *= int(k, 0)
    return n
for f in sys.argv[1:]:
    P = json.load(open(f))
    inv = {x["label"]: x for x in json.load(open(os.path.join(os.path.dirname(f), "inventory.json")))}
    for r in P:
        lab = r["label"]
        x = inv.get(lab)
        if r.get("verdict") not in ("type", "name"):
            print("REFUSE %-44s %s" % (lab, (r.get("why_refused") or "")[:110]))
            continue
        b = open(os.path.join(ROOT, "v10/maincpu/includes/generated/%s.bin" % x["blob"]), "rb").read()[x["off"]:x["off"] + x["size"]]
        ps = r.get("pieces") or [dict(r, off_in_slice=0, size=x["size"])]
        if r.get("verdict") == "name":          # the C is already typed: no size to check
            ps = [dict(p, ctype="uint8_t", dims="[%d]" % p["size"]) for p in ps]
        probs = []
        for p in ps:
            bb = b[p["off_in_slice"]:p["off_in_slice"] + p["size"]]
            sz = (sum(SZ[q["ctype"]] * nel(q.get("dims")) for q in p["struct_fields"]) if p["ctype"] == "struct" else SZ[p["ctype"]]) * nel(p.get("dims"))
            if sz != p["size"]:
                probs.append("size %s != %d" % (sz, p["size"]))
            try:
                if p.get("check") and not eval(p["check"], {"struct": struct, "b": bb}):
                    probs.append("check FALSE")
            except Exception as e:
                probs.append("check error %s" % e)
        bad = 0
        for ev in r.get("evidence", []):
            m = re.match(r'\s*([\w/.\-]+\.s):(\d+)\s+`([^`]+)`', ev)
            if not m:
                continue
            L = open(os.path.join(ROOT, "v10/maincpu", m.group(1)), "rb").read().decode("latin-1").split("\n")
            ln = int(m.group(2))
            want = re.sub(r'\s+', ' ', m.group(3).strip().lower())
            got = " ".join(re.sub(r'\s+', ' ', L[k].split(";")[0].strip().lower()) for k in range(max(0, ln - 3), min(len(L), ln + 2)))
            if want.split(" ")[0] not in got or not any(t in got for t in re.findall(r'[a-z_][\w]+', want)[1:2] or [want]):
                bad += 1
        print("%-6s %-44s -> %-44s %s%s" % (r["verdict"].upper(), lab, ", ".join(p["new_label"] for p in ps)[:44],
              ("ev-miss %d/%d " % (bad, len(r.get("evidence", []))) if bad else ""), "; ".join(probs)))
