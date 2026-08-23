#!/usr/bin/env python3
"""Of the ranges refused by "a branch target cannot be named", how many are a
MISFRAME (correct refusal) and how many are merely UNNAMED (my limitation)?

`resolve_branches()` returns None for two reasons that the census reports as one:

  (1) the target is INSIDE the range but not at an instruction boundary
      -> the decode is mis-framed; refusing is CORRECT and the range is not
         recoverable by naming anything.
  (2) the target is OUTSIDE the range and absent from addr2name
      -> nothing is wrong with the decode; there is simply no symbol at the
         destination. This is a naming gap, not a decode failure.

The distinction decides whether the 170-range bucket is real work or a wall.
Only (2) is potentially recoverable, and only where the destination is a
plausible instruction boundary.

⚠ Reports the two counts SEPARATELY and never sums them into a "recoverable"
headline -- the whole point is that they are different things.

Run:  python3 tools/spelling-probes/split_branch_target_refusals.py
"""
import importlib.util, json, os, sys, collections

REPO = "/home/fsanches/compartilhado/kn5000-roms-disasm"
sys.path.insert(0, REPO); os.chdir(REPO)
BASE = 0xE00000

_s = importlib.util.spec_from_file_location(
    "crr", os.path.join(REPO, "scripts/converters/convert_reachable_ranges.py"))
crr = importlib.util.module_from_spec(_s); _s.loader.exec_module(crr)
_d = importlib.util.spec_from_file_location(
    "_decodes", os.path.join(REPO, "tools/spelling-probes/class-a-sweep/_decodes.py"))
_dm = importlib.util.module_from_spec(_d); _d.loader.exec_module(_dm)

rom = open("original_ROMs/kn5000_v7_program.rom", "rb").read()
decodes = _dm.load(crr)
syms = crr.load_symbols() if hasattr(crr, "load_symbols") else None

# Rebuild addr2name exactly as main() does.
import re
addr2name = {}
for ln in open("analysis/maincpu_symbols_reference_v7.txt", encoding="latin1",
               errors="replace") if os.path.exists(
                   "analysis/maincpu_symbols_reference_v7.txt") else []:
    m = re.match(r'\s*([0-9a-fA-F]{6,8})\s+(\S+)', ln)
    if m:
        addr2name.setdefault(int(m.group(1), 16), m.group(2))
if not addr2name:                       # fall back to the converter's own loader
    for nm in ("build_addr2name", "addr_to_name", "symbol_map"):
        if hasattr(crr, nm):
            addr2name = getattr(crr, nm)(); break

misframe, unnamed, unnamed_dests = 0, 0, collections.Counter()
examples = {"misframe": [], "unnamed": []}
for t, insns in sorted(decodes.items()):
    if len(insns) < 3:
        continue
    span = sum(n for _, n, _ in insns)
    addrs = {a for a, _n, _x in insns}
    why = None
    for a, n, x in insns:
        m = crr.BRANCH_RE.match(x.strip())
        if not m:
            continue
        tgt = int(m.group(3), 16)
        if t <= tgt < t + span:
            if tgt not in addrs:
                why = "misframe"; break
        elif tgt not in addr2name:
            why = "unnamed"
            unnamed_dests[tgt] += 1
            break
    if why == "misframe":
        misframe += 1
        if len(examples["misframe"]) < 4:
            examples["misframe"].append((t, x, tgt))
    elif why == "unnamed":
        unnamed += 1
        if len(examples["unnamed"]) < 4:
            examples["unnamed"].append((t, x, tgt))

print(f"  refused: target MID-INSTRUCTION (misframe, correct refusal) : {misframe}")
print(f"  refused: target has NO SYMBOL   (naming gap, maybe fixable) : {unnamed}")
print(f"  distinct unnamed destinations                               : {len(unnamed_dests)}")
print()
print("  most-wanted unnamed destinations:")
for d, c in unnamed_dests.most_common(10):
    inside = "in a decoded range" if any(
        d in {a for a, _, _ in v} for v in decodes.values()) else "NOT in any decode"
    print(f"    0x{d:06X}  wanted by {c:3} range(s)   {inside}")
print()
for k in ("misframe", "unnamed"):
    print(f"  example {k}:")
    for t, x, tgt in examples[k]:
        print(f"    range 0x{t:06X}  {x.strip():34}  -> 0x{tgt:06X}")
