#!/usr/bin/env python3
"""Per-range evidence for the label-guard bucket."""
import collections, json, os, pickle, re, subprocess, sys, pathlib

REPO = pathlib.Path("/home/fsanches/compartilhado/kn5000-roms-disasm")
S = pathlib.Path(os.environ["SCRATCH"])
BASE = 0xE00000
UNIDASM = os.path.expanduser("~/compartilhado/tools/unidasm")
LABEL = re.compile(r'^([A-Za-z_][\w]*):')

d = pickle.load(open(S / "cases.pkl", "rb"))
cases = sorted(d["cases"], key=lambda r: r["entry"])
rom = d["rom"]
terr = d["terr"]

targets = set(json.load(open(REPO / "analysis/v7-reachability/v7_call_targets.json"))["targets"])


def scan(tree):
    defined, used = set(), collections.Counter()
    for f in sorted((REPO / tree).rglob('*.s')):
        for line in f.read_bytes().decode('latin1').splitlines():
            m = LABEL.match(line)
            if m:
                defined.add(m.group(1)); rest = line[m.end():]
            else:
                rest = line
            rest = re.split(r'[;#]', rest)[0]
            for w in re.findall(r'[A-Za-z_][\w]*', rest):
                used[w] += 1
    return defined, used


d7, u7 = scan('v7/maincpu')
_, u9 = scan('v9/maincpu')
_, u10 = scan('v10/maincpu')

# every 32-bit LE value in the ROM that looks like a code pointer
ptr = collections.Counter()
import struct
for i in range(0, len(rom) - 3):
    w = struct.unpack_from("<I", rom, i)[0]
    if BASE <= w < 0x1000000:
        ptr[w] += 1


def dis(start, nbytes):
    tmp = S / "_e.bin"
    open(tmp, "wb").write(rom[start - BASE:start - BASE + nbytes])
    out = subprocess.run([UNIDASM, str(tmp), "-arch", "tlcs900", "-basepc", hex(start)],
                         capture_output=True, text=True, timeout=120).stdout
    rows = []
    for line in out.split("\n"):
        m = re.match(r'^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.+)$', line)
        if m:
            rows.append((int(m.group(1), 16), m.group(2).split(), m.group(3).strip()))
    return rows


rep = []
for r in cases:
    e, sp = r["entry"], r["span"]
    ia = {a: (n, x) for a, n, x in r["insns"]}
    ent = {"entry": e, "span": sp, "file": os.path.basename(r["path"]),
           "n_off": len(r["off_boundary"]), "labels": [],
           "first_block": r["blocks"][0][1], "lead": r["lead"], "tail": r["tail"],
           "texts": r["texts"]}
    for a, nm in r["off_boundary"]:
        # which decoded instruction straddles the label?
        strad = None
        for ia_, n, x in r["insns"]:
            if ia_ < a < ia_ + n:
                strad = (ia_, n, x, rom[ia_ - BASE:ia_ - BASE + n].hex(" "))
                break
        lab_dis = dis(a, min(48, (e + sp) - a + 24))
        ent["labels"].append({
            "name": nm, "addr": a,
            "is_call_target": a in targets,
            "ptr_hits": ptr.get(a, 0),
            "v7_refs": u7.get(nm, 0), "v9_refs": u9.get(nm, 0), "v10_refs": u10.get(nm, 0),
            "straddle": strad,
            "label_dis": lab_dis[:6],
        })
    rep.append(ent)

json.dump(rep, open(S / "evidence.json", "w"), indent=1)

# summary
tot_lbl = sum(x["n_off"] for x in rep)
ct = sum(1 for x in rep for l in x["labels"] if l["is_call_target"])
pt = sum(1 for x in rep for l in x["labels"] if l["ptr_hits"])
r7 = sum(1 for x in rep for l in x["labels"] if l["v7_refs"])
r9 = sum(1 for x in rep for l in x["labels"] if l["v9_refs"] or l["v10_refs"])
print(f"ranges {len(rep)}  bytes {sum(x['span'] for x in rep)}  off-boundary labels {tot_lbl}")
print(f"  label IS a v7 call target        : {ct}")
print(f"  label addr appears as a ROM ptr   : {pt}")
print(f"  label referenced in v7/maincpu/*.s: {r7}")
print(f"  name referenced in v9 or v10      : {r9}")
