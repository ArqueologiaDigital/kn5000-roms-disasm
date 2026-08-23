#!/usr/bin/env python3
"""Reproduce v7_label_guard_subjects.py's 313-label census, then apply the same
drift / provenance tests to the WHOLE population, and separate it from the 33
ranges that actually reach rewrite()."""
import importlib.util, json, os, struct, sys, pickle, collections, subprocess, re
REPO = "/home/fsanches/compartilhado/kn5000-roms-disasm"; S = os.environ["SCRATCH"]
BASE = 0xE00000
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
os.chdir(REPO)


def load(name, path):
    sp = importlib.util.spec_from_file_location(name, os.path.join(REPO, path))
    m = importlib.util.module_from_spec(sp)
    a = sys.argv; sys.argv = [name]
    try: sp.loader.exec_module(m)
    finally: sys.argv = a
    return m


cr = load("cr", "scripts/converters/convert_reachable_ranges.py")
spm = load("sp", "scripts/analysis/v7_undisassembled_spans.py")
rom = open(os.path.join(REPO, "original_ROMs", "kn5000_v7_program.rom"), "rb").read()
idx = cr.source_index(cr.cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf"))
terr = spm.territory(spm.runs("v7/maincpu/kn5000_v7_program.s", "v7/maincpu"))
targets = json.load(open(os.path.join(REPO, "analysis/v7-reachability/v7_call_targets.json")))["targets"]
tset = set(targets)

ptr = set()
for i in range(0, len(rom) - 3):
    w = struct.unpack_from("<I", rom, i)[0]
    if BASE <= w < 0x1000000:
        ptr.add(w)


def syms(elf):
    out = {}
    for ln in subprocess.run([NM, "--no-sort", os.path.join(REPO, elf)],
                             capture_output=True, text=True).stdout.splitlines():
        p = ln.split()
        if len(p) == 3:
            try: a = int(p[0], 16)
            except ValueError: continue
            if BASE <= a < 0x1000000 and p[2] not in out: out[p[2]] = a
    return out


s9 = syms("rebuilt_ROMs/kn5000_v9_program.llvm.elf")
rom9 = open(os.path.join(REPO, "original_ROMs", "kn5000_v9_program.rom"), "rb").read()

seen, rows = set(), []
for t in sorted(int(x, 16) if isinstance(x, str) else x for x in targets):
    insns = cr.decode_range(rom, terr, t)
    if len(insns) < 3:
        continue
    span = sum(n for _, n, _ in insns)
    ia = {a for a, _, _ in insns}
    for f, (lines, blocks) in idx.items():
        for (l, a, st, e, raw) in blocks:
            if a is None or not (t < a < t + span) or a in ia or a in seen:
                continue
            seen.add(a)
            below = max((x for x in ia if x <= a), default=None)
            rows.append({"label": l, "addr": a, "range": t, "span": span,
                         "ptr": a in ptr, "call_target": a in tset,
                         "drift": (a - below) if below is not None else None,
                         "in_v9": l in s9})
print(f"distinct labels blocking a range : {len(rows)}")
print(f"  referenced by a 32-bit ROM value: {sum(r['ptr'] for r in rows)}")
print(f"  is itself a decoded call target : {sum(r['call_target'] for r in rows)}")
print(f"  name exists in v9               : {sum(r['in_v9'] for r in rows)}")
dr = collections.Counter(r["drift"] for r in rows)
print("  drift from the nearest decoded instruction boundary below the label:")
for k in sorted(dr, key=lambda x: (x is None, x)):
    print(f"     +{k}: {dr[k]}")
print(f"  drift 1..4 : {sum(v for k,v in dr.items() if k is not None and 1<=k<=4)}")
print(f"  drift >4   : {sum(v for k,v in dr.items() if k is not None and k>4)}")
pl = [r for r in rows if r["ptr"]]
print("\n  ROM-referenced (the guard is right about these):")
for r in sorted(pl, key=lambda r: r["addr"]):
    print(f"    {r['label']:46} 0x{r['addr']:06X}  drift +{r['drift']}  range 0x{r['range']:06X}")
json.dump(rows, open(os.path.join(S, "census313.json"), "w"), indent=1)
