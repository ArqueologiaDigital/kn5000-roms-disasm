#!/usr/bin/env python3
"""How many of the CUT ranges had more than one blocking label?

WHY IT MATTERS: `_cut_at_first_blocking_label()` truncates a range at the
earliest label the decode does not treat as an instruction boundary. That is
byte-safe -- nothing at or past the label is converted, so no label moves and no
`.long <symbol>` changes -- but byte-safety is not the whole question.

A single off-boundary label is most likely a misplaced label. SEVERAL of them in
one range says the decode disagrees with the sources REPEATEDLY, which is what a
MIS-FRAMED decode looks like; and then the kept prefix is suspect too, because a
wrong framing is wrong before the label as well as after it. No gate in this
project can see that: the bytes are the same bytes (spec anti-pattern 13), and
the structural gates pass 67.5% of known-bad entries (anti-pattern 23).

So this reports the multiplicity distribution of what was actually converted,
and names the subset that would survive the strictest reading.

Run:  python3 tools/spelling-probes/cut_range_label_multiplicity.py
"""
import importlib.util, json, os, sys
from collections import Counter

REPO = "/home/fsanches/compartilhado/kn5000-roms-disasm"
sys.path.insert(0, REPO); os.chdir(REPO)
BASE, DATA = 0xE00000, 2

_s = importlib.util.spec_from_file_location(
    "crr", os.path.join(REPO, "scripts/converters/convert_reachable_ranges.py"))
crr = importlib.util.module_from_spec(_s); _s.loader.exec_module(crr)
spec = importlib.util.spec_from_file_location(
    "spans", os.path.join(REPO, "scripts/analysis/v7_undisassembled_spans.py"))
spans = importlib.util.module_from_spec(spec); spec.loader.exec_module(spans)

# Re-derive the blocking-label multiplicity for every range the converter would
# hand to the cut path, using the PRE-cut sources from git so the ranges are the
# ones that were actually cut.
import subprocess
terr = spans.territory(spans.runs("v7/maincpu/kn5000_v7_program.s", "v7/maincpu"))
rom = open("original_ROMs/kn5000_v7_program.rom", "rb").read()
syms = crr.cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf")
idx = crr.source_index(syms)
cl = json.load(open("analysis/v7-reachability/v7_branch_closure_targets.json"))["targets"]

mult = Counter()
for t in cl:
    o = t - BASE
    if not (0 <= o < len(terr)) or terr[o] != DATA:
        continue
    insns = crr.decode_range(rom, terr, t)
    if len(insns) < 3:
        continue
    span = sum(n for _a, n, _x in insns)
    insn_addrs = {a for a, _n, _x in insns}
    blocking = []
    for _p, (_lines, blocks) in idx.items():
        touched = [bk for bk in blocks if bk[1] < t + span and bk[1] + len(bk[4]) > t]
        if not touched:
            continue
        touched.sort(key=lambda bk: bk[2])
        first = touched[0]
        for bk in touched:
            if bk[0] and bk[1] != first[1] and t <= bk[1] < t + span \
                    and bk[1] not in insn_addrs:
                blocking.append(bk[1])
    if blocking:
        mult[len(set(blocking))] += 1

tot = sum(mult.values())
print(f"  ranges still blocked by >=1 off-boundary label: {tot}")
print()
print("  blocking labels per range -> ranges")
for k in sorted(mult):
    print(f"      {k:2}  {mult[k]:4}")
one = mult.get(1, 0)
print()
print(f"  single-label (weakest mis-framing signal) : {one}"
      f"  ({100*one/max(1,tot):.0f}%)")
print(f"  multi-label  (decode disagrees repeatedly): {tot-one}"
      f"  ({100*(tot-one)/max(1,tot):.0f}%)")
print()
print("  ⚠ Set CUT_SINGLE_LABEL_ONLY = True in the converter to restrict the cut")
print("    path to the single-label subset if the multi-label rows are doubted.")
