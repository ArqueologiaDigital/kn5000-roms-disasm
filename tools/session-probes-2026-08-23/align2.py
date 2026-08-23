#!/usr/bin/env python3
"""Content-align each refused v7 range onto v9/v10 and read off THEIR framing.

ALIGNMENT: search the sibling ROM for the range's own bytes, longest window
first, shrinking until exactly one hit.  A unique hit of >=16 bytes fixes the
correspondence; then the sibling's committed sources (flattened through llvm-mc,
gated on classifying the ROM to the byte) say which of those addresses are
INSTRUCTION STARTS.  That is a framing opinion produced independently of the v7
decode and of the v7 labels.
"""
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


def occ(hay, needle, cap=6):
    out, i = [], 0
    while len(out) < cap:
        j = hay.find(needle, i)
        if j < 0:
            break
        out.append(j); i = j + 1
    return out


def align(tag, e_off, span, lab_offs, ctx_lo):
    H = rom[tag]
    # windows: [start, end) in v7 offsets, all containing the entry
    wins = []
    hi = e_off + span
    lo_choices = sorted({ctx_lo, e_off - 32, e_off - 8, e_off}, reverse=True)
    for lo in lo_choices:
        if lo < 0:
            continue
        for shrink in (0, 8, 16, 24, 32, 48, 64, 96, 128):
            if hi - shrink - lo >= 16:
                wins.append((lo, hi - shrink))
    # also widen to cover the last label + a bit
    if lab_offs:
        hi2 = max(lab_offs) + 24
        for lo in lo_choices:
            if lo >= 0 and hi2 - lo >= 16:
                wins.append((lo, hi2))
    wins = sorted(set(wins), key=lambda w: -(w[1] - w[0]))
    found_any = False
    for lo, hiw in wins:
        hits = occ(H, rom["v7"][lo:hiw])
        if hits:
            found_any = True
        if len(hits) == 1:
            return {"lo": lo, "hi": hiw, "delta": hits[0] - lo, "win": hiw - lo}
    return {"delta": None, "found_any": found_any}


rows = []
for rng in ev:
    e, sp = rng["entry"], rng["span"]
    c = by_entry[e]
    e_off, hi7 = e - BASE, e - BASE + sp
    lab_offs = [l["addr"] - BASE for l in rng["labels"]]
    row = {"entry": e, "span": sp, "n_off": rng["n_off"], "file": rng["file"],
           "labels": [[l["name"], l["addr"]] for l in rng["labels"]]}
    for tag in ("v9", "v10"):
        a = align(tag, e_off, sp, lab_offs, rng["first_block"] - BASE)
        if a["delta"] is None:
            row[tag] = {"aligned": False, "found_any": a.get("found_any")}
            continue
        delta, starts, terr = a["delta"], flat[tag]["starts"], flat[tag]["terr"]
        ins_off = [ia - BASE for ia, _n, _x in c["insns"]]
        row[tag] = {
            "aligned": True, "win": a["win"], "delta": delta,
            "sib_entry": e_off + delta + BASE,
            "entry_is_start": (e_off + delta) in starts,
            "insn_agree": sum(1 for o in ins_off if (o + delta) in starts),
            "insn_total": len(ins_off),
            "code_bytes": sum(1 for o in range(e_off, hi7) if terr[o + delta] == 2),
            "labels": [{"name": l["name"], "addr": l["addr"],
                        "is_start": (l["addr"] - BASE + delta) in starts,
                        "terr": terr[l["addr"] - BASE + delta]}
                       for l in rng["labels"]],
        }
    rows.append(row)

import collections
cat, byte = collections.Counter(), collections.Counter()
for r in rows:
    x = r["v9"] if r["v9"].get("aligned") else r["v10"]
    if not x.get("aligned"):
        k = ("range bytes ABSENT from both siblings" if not x.get("found_any")
             else "range bytes occur but not uniquely")
    elif x["code_bytes"] < sp_ if False else x["code_bytes"] < r["span"]:
        k = "sibling carries these bytes as DATA"
    elif x["insn_agree"] == x["insn_total"] and all(l["is_start"] for l in x["labels"]):
        k = "sibling agrees with BOTH"
    elif x["insn_agree"] == x["insn_total"]:
        k = "sibling CONFIRMS the decode, CONTRADICTS the label(s)"
    elif all(l["is_start"] for l in x["labels"]):
        k = "sibling CONFIRMS the label(s), CONTRADICTS the decode"
    else:
        k = "sibling contradicts both"
    r["verdict"] = k
    cat[k] += 1; byte[k] += r["span"]
for k, v in cat.most_common():
    print(f"{v:4} ranges {byte[k]:6} B   {k}")
json.dump(rows, open(os.path.join(S, "align.json"), "w"), indent=1)
