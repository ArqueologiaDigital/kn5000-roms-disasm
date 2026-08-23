#!/usr/bin/env python3
"""Which sites of the two assigned forms does the converter FAIL to spell?"""
import importlib.util, json, os, re, sys, collections

REPO = "/home/fsanches/compartilhado/kn5000-roms-disasm"
BASE = 0xE00000
spec = importlib.util.spec_from_file_location(
    "crr", os.path.join(REPO, "scripts/converters/convert_reachable_ranges.py"))
crr = importlib.util.module_from_spec(spec); spec.loader.exec_module(crr)
cc = crr.cc
os.chdir(REPO)
rom = open(os.path.join(REPO, "original_ROMs", "kn5000_v7_program.rom"), "rb").read()
spec2 = importlib.util.spec_from_file_location(
    "spans", os.path.join(REPO, "scripts/analysis/v7_undisassembled_spans.py"))
spans = importlib.util.module_from_spec(spec2); spec2.loader.exec_module(spans)
terr = spans.territory(spans.runs("v7/maincpu/kn5000_v7_program.s", "v7/maincpu"))
targets = json.load(open("analysis/v7-reachability/v7_call_targets.json"))["targets"]

def norm(x):
    mn = x.split()[0]
    rest = x.split(None, 1)[1] if len(x.split(None, 1)) > 1 else ""
    return mn + " " + re.sub(r'0x[0-9a-fA-F]+', 'imm',
                             re.sub(r'\b[A-Z]{1,4}\b', 'r', rest))

WANT = {"or (r+imm),imm", "ld r,(r+imm)"}

allhits = collections.defaultdict(list)   # text -> [(entry, addr, bytes)]
blocking = []                             # census-equivalent: first failure in a range
for t in sorted(targets):
    insns = crr.decode_range(rom, terr, t)
    want = rom[t-BASE : t-BASE+sum(n for _,n,_ in insns)]
    pos = 0
    for (a, n, x) in insns:
        target = rom[a-BASE:a-BASE+n]
        if norm(x) in WANT:
            allhits[x].append((t, a, target))
    # census-equivalent walk (byte-match choice, stop at first failure)
    for (a, n, x) in insns:
        target = rom[a-BASE:a-BASE+n]
        chosen = None
        for cand in list(cc.translate(x)) + [cc.canonical(x)]:
            if cc.encode(cand) == target:
                chosen = cand; break
        if chosen is None:
            if norm(x) in WANT:
                blocking.append((t, a, x, target))
            break

print("=== distinct texts of the two forms, and whether the converter can spell them ===")
res = {}
for x in sorted(allhits):
    sites = allhits[x]
    # group by distinct byte pattern
    bybytes = collections.defaultdict(list)
    for (t, a, b) in sites:
        bybytes[b].append((t, a))
    for b, locs in bybytes.items():
        chosen = None
        for cand in list(cc.translate(x)) + [cc.canonical(x)]:
            if cc.encode(cand) == b:
                chosen = cand; break
        res[(x, b)] = (chosen, locs)
        flag = "OK " if chosen else "FAIL"
        print(f"{flag} {x:28} bytes={' '.join(f'{c:02x}' for c in b):18} n={len(locs):4} spelling={chosen}")

print()
print("=== census-equivalent BLOCKING instances (first unspellable insn in a range) ===")
for t, a, x, b in blocking:
    print(f"entry=0x{t:06X} site=0x{a:06X} text={x!r} bytes={' '.join(f'{c:02x}' for c in b)}")
print(f"total blocking: {len(blocking)}")

print()
print("=== ALL failing (text,bytes) pairs with their sites ===")
for (x, b), (chosen, locs) in sorted(res.items()):
    if chosen is None:
        print(f"{x!r} bytes={' '.join(f'{c:02x}' for c in b)}  sites={len(locs)}")
        for (t, a) in locs:
            print(f"     entry=0x{t:06X} site=0x{a:06X}")
