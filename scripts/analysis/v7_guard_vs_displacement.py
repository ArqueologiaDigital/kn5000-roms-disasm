#!/usr/bin/env python3
"""Are the labels blocking the converter the SAME labels that are mis-placed?

QUESTION ANSWERED
-----------------
Two of the three remaining conversion blockers looked independent:

  * 2,168 B -- `rewrite()` declines because a label inside the range does not sit
    on a decoded instruction boundary ("the decode and the framing disagree");
  * 3,474 labels in 0x00FCCE4A..0x00FFFE80 sit exactly 0x41A above the routine
    they name (`v7_label_displacement.py`).

They are ONE defect. Measured here:

    labels inside a range but not on an instruction boundary
        also in the -0x41A displaced set : 304
        not displaced                    :  41

So in ~88% of cases the decode is RIGHT and the label is in the wrong place: it
lands mid-instruction because it is 0x41A too high. The guard was correctly
refusing -- it saw a real disagreement without being able to say which side was
wrong. Now we can say.

CONSEQUENCES, both worth acting on:
  * repairing the displacement should clear most of the label-guard bucket, so
    the two jobs are one job and the ordering matters;
  * the 41 non-displaced cases are a genuinely separate, smaller problem and sit
    OUTSIDE the displaced region (e.g. `WidgetParam_Config_004` at 0x00EE646E).
    They should not be swept into the same fix.

⚠ This does NOT license moving anything. Relocating a label changes no bytes, so
the byte-match gate cannot review it (spec anti-patterns 12, 13, and the
correction in `v7_label_repair_feasibility.py`: 2,834 of the targets have no
source line to hold a label until the surrounding `.byte` runs are converted).

Run:  python3 scripts/analysis/v7_guard_vs_displacement.py
"""
import importlib.util, json, os, sys

REPO = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
BASE, DISP, W = 0xE00000, 0x41A, 32
LO, HI = 0x00FCCE4A, 0x00FFFE80


def syms(p):
    d = {}
    for line in open(os.path.join(REPO, "symbols", p), encoding="latin1"):
        if line.startswith("#") or not line.strip():
            continue
        f = line.split()
        if len(f) == 2:
            try:
                d[f[0]] = int(f[1], 16)
            except ValueError:
                pass
    return d


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, os.path.join(REPO, path))
    m = importlib.util.module_from_spec(spec)
    saved, sys.argv = sys.argv, [name]
    try:
        spec.loader.exec_module(m)
    finally:
        sys.argv = saved
    return m


def main():
    rom7 = open(os.path.join(REPO, "original_ROMs", "kn5000_v7_program.rom"), "rb").read()
    rom9 = open(os.path.join(REPO, "original_ROMs", "kn5000_v9_program.rom"), "rb").read()
    s7, s9 = syms("maincpu_v7_symbols_reference.txt"), syms("maincpu_v9_symbols_reference.txt")
    displaced = set()
    for n in set(s7) & set(s9):
        a7, a9 = s7[n], s9[n]
        if not (LO <= a7 <= HI):
            continue
        o7, o9 = a7 - BASE, a9 - BASE
        if not (0 <= o9 < len(rom9) - W and DISP <= o7 < len(rom7) - W):
            continue
        ref = rom9[o9:o9 + W]
        at = sum(1 for x, y in zip(rom7[o7:o7 + W], ref) if x == y)
        tr = sum(1 for x, y in zip(rom7[o7 - DISP:o7 - DISP + W], ref) if x == y)
        if at <= 8 and tr >= 28:
            displaced.add(a7)

    cr = load("cr", "scripts/converters/convert_reachable_ranges.py")
    spm = load("sp", "scripts/analysis/v7_undisassembled_spans.py")
    idx = cr.source_index(cr.cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf"))
    terr = spm.territory(spm.runs("v7/maincpu/kn5000_v7_program.s", "v7/maincpu"))
    targets = json.load(open(os.path.join(
        REPO, "analysis/v7-reachability/v7_call_targets.json")))["targets"]

    hit, miss, seen, examples = 0, 0, set(), []
    for t in sorted(int(x, 16) if isinstance(x, str) else x for x in targets):
        insns = cr.decode_range(rom7, terr, t)
        if len(insns) < 3:
            continue
        span = sum(n for _, n, _ in insns)
        ia = {a for a, _, _ in insns}
        for f, (lines, blocks) in idx.items():
            for (l, a, st, e, raw) in blocks:
                if a is None or not (t < a < t + span) or a in ia or (t, a) in seen:
                    continue
                seen.add((t, a))
                if a in displaced:
                    hit += 1
                else:
                    miss += 1
                    if len(examples) < 8:
                        examples.append((l, a))
    print("  labels inside a range but NOT on an instruction boundary:")
    print(f"     also in the -0x41A displaced set : {hit}")
    print(f"     not displaced                    : {miss}")
    tot = hit + miss
    if tot:
        print(f"     => {100.0*hit/tot:.0f}% of the guard's refusals are the displacement defect")
    print("\n  the non-displaced ones, which are a SEPARATE and smaller problem:")
    for l, a in examples:
        print(f"     {l:46} {a:#010x}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
