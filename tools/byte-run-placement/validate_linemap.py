#!/usr/bin/env python3
"""Corroborate the assembler-derived line map against source_index()'s own blocks,
and census what an assembler-addressed index would gain."""
import importlib.util, os, pickle, re, sys, tempfile

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.environ.get("KN5000_PROBE_DIR",
                     os.path.join(tempfile.gettempdir(), "kn5000-byte-run-placement"))
os.makedirs(OUT, exist_ok=True)
BASE = 0xE00000
os.chdir(REPO); sys.argv = [sys.argv[0]]
spec = importlib.util.spec_from_file_location(
    "crr", os.path.join(REPO, "scripts/converters/convert_reachable_ranges.py"))
mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
syms = mod.cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf")
idx = mod.source_index(syms)
ROM = mod.ROM

recs = pickle.load(open(os.path.join(OUT, "line_map.pkl"), "rb"))
lm = {}                                   # (rel, lineno0) -> addr   (first wins)
for (a, tag, rel, ln, text) in recs:
    lm.setdefault((rel, ln), a)

def raw_runs(lines):
    runs, cur, start, label = [], [], None, None
    for i, ln in enumerate(lines):
        m = re.match(r'^\s*\.byte\s+(.*)$', ln)
        if m:
            if start is None: start = i
            body = re.split(r'[;#]', m.group(1))[0]
            for tok in body.split(","):
                tok = tok.strip()
                if not tok: continue
                try: cur.append(int(tok, 0))
                except ValueError: cur.append(None)
            continue
        if cur:
            runs.append((label, start, i - 1, cur)); cur, start, label = [], None, None
        lm2 = re.match(r'^([A-Za-z_][\w]*):', ln)
        if lm2: label = lm2.group(1)
        elif ln.strip() and not ln.lstrip().startswith((';', '#')): label = None
    if cur: runs.append((label, start, len(lines) - 1, cur))
    return runs

import glob
files = sorted(glob.glob(os.path.join(REPO, "v7/maincpu/*/*.s"))
               + glob.glob(os.path.join(REPO, "v7/maincpu/*.s")))
agree = disagree = missing = 0
gain_runs = gain_bytes = 0
still_runs = still_bytes = 0
sym_runs = sym_bytes = 0
romfail = 0
idx_runs = idx_bytes = 0
for f in files:
    rel = os.path.relpath(f, os.path.join(REPO, "v7/maincpu"))
    lines = open(f, "rb").read().decode("latin-1").split("\n")
    blocks = idx.get(f, (None, []))[1]
    by_start = {bk[2]: bk for bk in blocks}
    for (lb, s, e, vals) in raw_runs(lines):
        a = lm.get((rel, s))
        if s in by_start:
            idx_runs += 1; idx_bytes += len(vals)
            if a is None: missing += 1
            elif a == by_start[s][1]: agree += 1
            else:
                disagree += 1
                if disagree <= 5:
                    print(f"  DISAGREE {rel}:{s+1} index 0x{by_start[s][1]:06X} "
                          f"asm 0x{a:06X}")
            continue
        if any(v is None for v in vals):
            sym_runs += 1; sym_bytes += len(vals); continue
        blob = bytes(v & 0xFF for v in vals)
        if a is not None and ROM[a - BASE:a - BASE + len(blob)] == blob:
            gain_runs += 1; gain_bytes += len(blob)
        else:
            if a is not None: romfail += 1
            still_runs += 1; still_bytes += len(vals)
print(f"\nindexed runs: {idx_runs} ({idx_bytes:,} B) -- assembler address agrees "
      f"{agree}, disagrees {disagree}, no label located {missing}")
print(f"UNindexed, non-symbolic runs that GAIN a ROM-verified address from the "
      f"assembler: {gain_runs} run(s), {gain_bytes:,} bytes")
print(f"  still unaddressed: {still_runs} run(s), {still_bytes:,} bytes "
      f"({romfail} of them located but the bytes disagree with the ROM)")
print(f"  symbolic `.byte` runs (never convertible): {sym_runs} run(s), {sym_bytes:,} bytes")
