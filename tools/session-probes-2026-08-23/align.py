#!/usr/bin/env python3
"""Content-align each refused v7 range onto v9/v10 and read off THEIR framing."""
import json, os, pickle, sys

ROOT = "/home/fsanches/compartilhado/kn5000-roms-disasm"
S = os.environ["SCRATCH"]
BASE = 0xE00000

ev = json.load(open(os.path.join(S, "evidence.json")))
cases = pickle.load(open(os.path.join(S, "cases.pkl"), "rb"))["cases"]
by_entry = {c["entry"]: c for c in cases}
flat = pickle.load(open(os.path.join(S, "flat.pkl"), "rb"))
rom = {n: open(os.path.join(ROOT, f"original_ROMs/kn5000_{n}_program.rom"), "rb").read()
       for n in ("v7", "v9", "v10")}


def occurrences(hay, needle, cap=8):
    out, i = [], 0
    while len(out) < cap:
        j = hay.find(needle, i)
        if j < 0:
            break
        out.append(j)
        i = j + 1
    return out


rows = []
for rng in ev:
    e, sp = rng["entry"], rng["span"]
    c = by_entry[e]
    fb = rng["first_block"]
    lo7 = fb - BASE                       # start of the source block holding the entry
    hi7 = e - BASE + sp
    row = {"entry": e, "span": sp, "n_off": rng["n_off"], "file": rng["file"],
           "labels": [[l["name"], l["addr"]] for l in rng["labels"]]}
    for tag in ("v9", "v10"):
        H = rom[tag]
        best = None
        # widest window first, shrink until a UNIQUE hit
        for a, b in ((lo7, hi7), (e - BASE, hi7), (e - BASE, e - BASE + min(sp, 24))):
            if b - a < 8:
                continue
            hits = occurrences(H, rom["v7"][a:b])
            if len(hits) == 1:
                best = (a, b, hits[0]); break
        if best is None:
            row[tag] = {"aligned": False}
            continue
        a, b, h = best
        delta = (h + BASE) - (a + BASE)   # v9addr = v7addr + delta
        starts = flat[tag]["starts"]
        terr = flat[tag]["terr"]
        ins_off = [ia - BASE for ia, _n, _x in c["insns"]]
        agree = sum(1 for o in ins_off if (o + delta) in starts)
        codeb = sum(1 for o in range(e - BASE, hi7) if terr[o + delta] == 2)
        lab = []
        for _l in rng["labels"]:
            nm, la = _l["name"], _l["addr"]
            o = la - BASE
            lab.append({"name": nm, "is_start": (o + delta) in starts,
                        "terr": terr[o + delta]})
        row[tag] = {"aligned": True, "window": b - a, "delta": delta,
                    "v9_entry": (e - BASE + delta) + BASE,
                    "entry_is_start": (e - BASE + delta) in starts,
                    "insn_agree": agree, "insn_total": len(ins_off),
                    "code_bytes": codeb, "span": sp, "labels": lab}
    rows.append(row)

json.dump(rows, open(os.path.join(S, "align.json"), "w"), indent=1)

import collections
cat = collections.Counter()
byte = collections.Counter()
for r in rows:
    x = r.get("v9") or {}
    if not x.get("aligned"):
        x = r.get("v10") or {}
    if not x.get("aligned"):
        k = "no unique alignment in v9/v10"
    elif x["code_bytes"] < x["span"]:
        k = f"sibling carries the range as DATA ({x['code_bytes']}/{x['span']} B code)"
    elif x["insn_agree"] == x["insn_total"] and all(l["is_start"] for l in x["labels"]):
        k = "sibling agrees with BOTH the decode and the labels (impossible-looking)"
    elif x["insn_agree"] == x["insn_total"]:
        k = "sibling CONFIRMS the decode, contradicts the label(s)"
    elif all(l["is_start"] for l in x["labels"]):
        k = "sibling CONFIRMS the label(s), contradicts the decode"
    else:
        k = f"sibling contradicts both ({x['insn_agree']}/{x['insn_total']} insns agree)"
    cat[k] += 1
    byte[k] += r["span"]
    r["verdict"] = k
for k, v in cat.most_common():
    print(f"{v:4} ranges {byte[k]:6} B   {k}")
json.dump(rows, open(os.path.join(S, "align.json"), "w"), indent=1)
