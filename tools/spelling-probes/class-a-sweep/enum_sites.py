#!/usr/bin/env python3
"""INDEPENDENT enumeration of every `push r` / `or (imm),r` site in the
reachable-range decodes, and whether the tree's translate()+canonical() can
spell each one to its exact ROM bytes.

Unlike the census in convert_reachable_ranges.main(), this does NOT stop at the
first unspellable instruction in a range, so it sees sites the census masks.
"""
import importlib.util, json, os, re, sys, pickle

REPO = "/home/fsanches/compartilhado/kn5000-roms-disasm"
sys.path.insert(0, REPO)
os.chdir(REPO)
BASE = 0xE00000

_s = importlib.util.spec_from_file_location(
    "crr", os.path.join(REPO, "scripts/converters/convert_reachable_ranges.py"))
crr = importlib.util.module_from_spec(_s); _s.loader.exec_module(crr)
cc = crr.cc

rom = open(os.path.join(REPO, "original_ROMs", "kn5000_v7_program.rom"), "rb").read()
spec = importlib.util.spec_from_file_location(
    "spans", os.path.join(REPO, "scripts/analysis/v7_undisassembled_spans.py"))
spans = importlib.util.module_from_spec(spec); spec.loader.exec_module(spans)
terr = spans.territory(spans.runs("v7/maincpu/kn5000_v7_program.s", "v7/maincpu"))
targets = json.load(open(os.path.join(
    REPO, "analysis/v7-reachability/v7_call_targets.json")))["targets"]

CACHE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "decodes.pkl")
if os.path.exists(CACHE):
    decodes = pickle.load(open(CACHE, "rb"))
else:
    decodes = {}
    for i, t in enumerate(sorted(targets)):
        decodes[t] = crr.decode_range(rom, terr, t)
        if i % 200 == 0:
            print(f"  decoded {i}/{len(targets)}", file=sys.stderr)
    pickle.dump(decodes, open(CACHE, "wb"))
print(f"{len(decodes)} ranges decoded", file=sys.stderr)


def formkey(x):
    mn = x.split()[0]
    rest = x.split(None, 1)[1] if len(x.split(None, 1)) > 1 else ""
    return mn + " " + re.sub(r'0x[0-9a-fA-F]+', 'imm',
                             re.sub(r'\b[A-Z]{1,4}\b', 'r', rest))


WANT = {"push r", "or (imm),r"}
seen = {}          # addr -> (text, nbytes)
for t, insns in decodes.items():
    for (addr, n, x) in insns:
        k = formkey(x)
        if k in WANT:
            seen[addr] = (x, n, k)

print(f"{len(seen)} distinct sites with form-key in {WANT}")
fails = []
by_key = {}
for addr in sorted(seen):
    x, n, k = seen[addr]
    target = rom[addr - BASE: addr - BASE + n]
    chosen = None
    for cand in list(cc.translate(x)) + [cc.canonical(x)]:
        e = cc.encode(cand)
        if e == target:
            chosen = cand; break
    by_key.setdefault(k, [0, 0])
    by_key[k][0] += 1
    if chosen is None:
        by_key[k][1] += 1
        fails.append((addr, x, target.hex(' '), k))

for k, (tot, bad) in sorted(by_key.items()):
    print(f"  {k:16}  total {tot:5}  UNSPELLABLE {bad}")
print()
print("UNSPELLABLE SITES:")
for addr, x, hx, k in fails:
    print(f"  0x{addr:06X}  {hx:20}  {x}")
