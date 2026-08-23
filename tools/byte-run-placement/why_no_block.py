#!/usr/bin/env python3
"""WHY is each refused entry in no indexed .byte block?

Re-runs convert_reachable_ranges.source_index() (cheap: no unidasm), then for
each refused entry finds the raw `.byte` run that really holds it -- using the
assembler-derived line map, not a guess -- and reports which of source_index()'s
gates dropped that run.
"""
import bisect, importlib.util, os, pickle, re, sys, glob, tempfile

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.environ.get("KN5000_PROBE_DIR",
                     os.path.join(tempfile.gettempdir(), "kn5000-byte-run-placement"))
os.makedirs(OUT, exist_ok=True)
BASE = 0xE00000
os.chdir(REPO)
sys.argv = [sys.argv[0]]
spec = importlib.util.spec_from_file_location(
    "crr", os.path.join(REPO, "scripts/converters/convert_reachable_ranges.py"))
mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
syms = mod.cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf")
name2addr = {n: a for a, n in syms.items()}
idx = mod.source_index(syms)
ROM = mod.ROM
print(f"source_index: {len(idx)} file(s) indexed, "
      f"{sum(len(b) for _l, b in idx.values())} block(s); "
      f"{len(mod.DROPPED)} block(s) dropped on the ROM check")
dropped_by_file = {}
for (fn, lb, a) in mod.DROPPED:
    dropped_by_file.setdefault(fn, []).append((lb, a))

recs = pickle.load(open(os.path.join(OUT, "line_map.pkl"), "rb"))
addrs = [r[0] for r in recs]
rows = pickle.load(open(os.path.join(OUT, "unplaced.pkl"), "rb"))["rows"]

def line_of(a):
    i = bisect.bisect_right(addrs, a) - 1
    if i < 0: return None
    while i + 1 < len(recs) and recs[i + 1][0] <= a:
        i += 1
    return i

# ---- raw runs, keeping EVERY run (blocks_of() drops several kinds)
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
        lm = re.match(r'^([A-Za-z_][\w]*):', ln)
        if lm: label = lm.group(1)
        elif ln.strip() and not ln.lstrip().startswith((';', '#')): label = None
    if cur: runs.append((label, start, len(lines) - 1, cur))
    return runs

REASONS = {}
for t, span in sorted(rows):
    i = line_of(t)
    a0, _tag, rel, ln0, text = recs[i]
    path = os.path.join(REPO, "v7", "maincpu", rel)
    lines = open(path, "rb").read().decode("latin-1").split("\n")
    runs = raw_runs(lines)
    # the run holding line ln0
    run = next((r for r in runs if r[1] <= ln0 <= r[2]), None)
    blocks = idx.get(path, (None, []))[1]
    covering = [bk for bk in blocks if bk[1] <= t < bk[1] + len(bk[4])]
    if run is None:
        REASONS.setdefault("entry is NOT in a `.byte` run at all", []).append(
            (t, span, rel, ln0 + 1, text.strip()[:70]))
        continue
    lb, s, e, vals = run
    run_addr = recs[line_of_start][0] if False else None
    # exact address of the run's first line, from the line map
    j = next((k for k, r in enumerate(recs) if r[2] == rel and r[3] == s), None)
    run_a = recs[j][0] if j is not None else None
    nb = len(vals)
    why = []
    if any(v is None for v in vals):
        why.append("symbolic .byte in the run -> blocks_of() discards it")
    if lb is None:
        why.append("run has NO LABEL of its own")
    elif lb not in name2addr:
        why.append(f"label {lb} is not in the ELF symbol table")
    if lb and lb in name2addr and run_a is not None and name2addr[lb] != run_a:
        why.append(f"label {lb} resolves to 0x{name2addr[lb]:06X} but the run is at 0x{run_a:06X}")
    if not why:
        why.append("labelled and non-symbolic -- would be indexed; check ROM drop")
    # what precedes the run (for the cursor rule)?
    k = s - 1
    inter = []
    while k >= 0 and (not lines[k].strip() or lines[k].lstrip().startswith((';', '#'))
                      or re.match(r'^[A-Za-z_][\w]*:', lines[k])):
        inter.append(lines[k]); k -= 1
    prev_line = lines[k] if k >= 0 else "<top of file>"
    prev_is_byte = bool(re.match(r'^\s*\.byte\s', prev_line))
    blank_only = all((not x.strip()) or x.lstrip().startswith((';', '#')) for x in inter)
    REASONS.setdefault(" + ".join(why), []).append(
        (t, span, rel, s + 1, e + 1, nb, lb, prev_line.strip()[:70], prev_is_byte, blank_only,
         len(covering)))

print()
for k, v in sorted(REASONS.items(), key=lambda kv: -sum(x[1] for x in kv[1])):
    print(f"### {len(v)} range(s), {sum(x[1] for x in v):,} bytes: {k}")
    for row in v:
        if len(row) == 5:
            print(f"   0x{row[0]:06X} {row[1]:4} B  {row[2]}:{row[3]}  {row[4]}")
            continue
        (t, span, rel, s, e, nb, lb, prev, pb, blank, ncov) = row
        print(f"   0x{t:06X} {span:4} B  {rel}:{s}..{e} ({nb} B run, label={lb})")
        print(f"        preceded by {'a .byte line' if pb else 'NON-.byte'}: {prev!r}"
              f"  (only blank/comment between: {blank})")
    print()
