#!/usr/bin/env python3
"""Dump every BLOCKING site of the forms `push r` and `or (imm),r`.

Replicates convert_reachable_ranges.main()'s per-instruction loop exactly, but
instead of counting a form it records: site address, ROM bytes, unidasm text,
and every candidate spelling that was tried (with the encoding it produced).
"""
import importlib.util, json, os, re, sys, collections

REPO = "/home/fsanches/compartilhado/kn5000-roms-disasm"
sys.path.insert(0, REPO)
BASE = 0xE00000

def load(name, path):
    spec = importlib.util.spec_from_file_location(name, os.path.join(REPO, path))
    m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
    return m

crr = load("crr", "scripts/converters/convert_reachable_ranges.py")
cc = crr.cc
spans = load("spans", "scripts/analysis/v7_undisassembled_spans.py")

os.chdir(REPO)
rom = open(os.path.join(REPO, "original_ROMs", "kn5000_v7_program.rom"), "rb").read()
terr = spans.territory(spans.runs("v7/maincpu/kn5000_v7_program.s", "v7/maincpu"))
targets = json.load(open(os.path.join(
    REPO, "analysis/v7-reachability/v7_call_targets.json")))["targets"]

def formkey(x):
    mn = x.split()[0]
    rest = x.split(None, 1)[1] if len(x.split(None, 1)) > 1 else ""
    return mn + " " + re.sub(r'0x[0-9a-fA-F]+', 'imm',
                             re.sub(r'\b[A-Z]{1,4}\b', 'r', rest))

WANT = {"push r", "or (imm),r"}
hits = []
seen = set()
for t in sorted(targets):
    insns = crr.decode_range(rom, terr, t)
    if len(insns) < 3:
        continue
    want = rom[t - BASE: t - BASE + sum(n for _, n, _ in insns)]
    pos = 0
    for (a, n, x) in insns:
        target = want[pos:pos + n]
        chosen = None
        tried = []
        for cand in list(cc.translate(x)) + [cc.canonical(x)]:
            e = cc.encode(cand)
            tried.append((cand, e))
            if e == target:
                chosen = cand; break
        if chosen is None:
            k = formkey(x)
            if k in WANT and a not in seen:
                seen.add(a)
                hits.append(dict(entry=t, addr=a, bytes=target.hex(" "),
                                 text=x, form=k,
                                 tried=[(c, (e.hex(" ") if e else None)) for c, e in tried]))
            break   # converter breaks the range here
        pos += n

print(json.dumps(hits, indent=1))
