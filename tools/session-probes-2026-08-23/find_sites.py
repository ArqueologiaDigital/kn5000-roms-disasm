#!/usr/bin/env python3
"""Locate every site of `djnz r,imm` and `ld (r+),r` in the v7 reachable ranges.

Replays convert_reachable_ranges.main()'s decode loop READ-ONLY: same ROM, same
territory map, same call-target list, same decode_range().  For every decoded
instruction it records address, ROM bytes and unidasm text; separately it marks
which of them are the BLOCKING site of their range (the instruction at which the
converter's per-instruction byte match gives up), because that is what
`--forms` counts.
"""
import importlib.util, json, os, re, sys

REPO = os.path.expanduser("~/compartilhado/kn5000-roms-disasm")
os.chdir(REPO)
BASE = 0xE00000

spec = importlib.util.spec_from_file_location(
    "crr", os.path.join(REPO, "scripts/converters/convert_reachable_ranges.py"))
crr = importlib.util.module_from_spec(spec); spec.loader.exec_module(crr)
cc = crr.cc

rom = open(os.path.join(REPO, "original_ROMs", "kn5000_v7_program.rom"), "rb").read()
sp = importlib.util.spec_from_file_location(
    "spans", os.path.join(REPO, "scripts/analysis/v7_undisassembled_spans.py"))
spans = importlib.util.module_from_spec(sp); sp.loader.exec_module(spans)
terr = spans.territory(spans.runs("v7/maincpu/kn5000_v7_program.s", "v7/maincpu"))
targets = json.load(open(os.path.join(
    REPO, "analysis/v7-reachability/v7_call_targets.json")))["targets"]
syms = cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf")
addr2name = dict(syms)


def formkey(x):
    mn = x.split()[0]
    rest = x.split(None, 1)[1] if len(x.split(None, 1)) > 1 else ""
    return mn + " " + re.sub(r'0x[0-9a-fA-F]+', 'imm',
                             re.sub(r'\b[A-Z]{1,4}\b', 'r', rest))


WANT = {"djnz r,imm", "ld (r+),r"}
allsites, blocking = {}, {}

for t in sorted(targets):
    insns = crr.decode_range(rom, terr, t)
    if len(insns) < 3:
        continue
    span = sum(n for _, n, _ in insns)
    want = rom[t - BASE: t - BASE + span]
    # every occurrence, regardless of whether the converter reached it
    pos = 0
    for a, n, x in insns:
        k = formkey(x)
        if k in WANT:
            allsites.setdefault((a, k), (want[pos:pos + n], x, t))
        pos += n
    # now replay the converter's spelling loop to find the BLOCKING instruction
    br = crr.resolve_branches(insns, t, span, addr2name)
    if br is None:
        continue
    br_texts, _bl = br
    pos = 0
    for bi, (a, n, x) in enumerate(insns):
        target = want[pos:pos + n]
        if br_texts[bi] is not None:
            e = cc.encode(br_texts[bi])
            if e is None or len(e) != n:
                blocking.setdefault((a, formkey(x)), (target, x, t)); break
            pos += n; continue
        chosen = None
        for cand in list(cc.translate(x)) + [cc.canonical(x)]:
            if cc.encode(cand) == target:
                chosen = cand; break
        if chosen is None:
            blocking.setdefault((a, formkey(x)), (target, x, t)); break
        pos += n

print("=== BLOCKING sites (what --forms counts) ===")
for (a, k), (b, x, t) in sorted(blocking.items()):
    if k in WANT:
        print(f"0x{a:06X}  {b.hex(' '):20}  {x:32} form={k!r}  range=0x{t:06X} "
              f"{addr2name.get(t,'')}")
print()
print("=== ALL occurrences in decoded ranges ===")
for (a, k), (b, x, t) in sorted(allsites.items()):
    print(f"0x{a:06X}  {b.hex(' '):20}  {x:32} form={k!r}  range=0x{t:06X} "
          f"{addr2name.get(t,'')}")
