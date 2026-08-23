#!/usr/bin/env python3
"""ADVERSARIAL: how often would a WRONG entry point pass the converter's gates?

WHY THIS IS THE RIGHT QUESTION
------------------------------
The branch closure added 522 entry points and every rebuilt ROM stayed
byte-identical. That proves nothing about whether the entries are CORRECT: a
range decoded from the wrong offset re-assembles to the same bytes it was
decoded from, so the byte gate is blind to entry-point errors by construction.
The gates that DO stand between a wrong entry and the sources are structural --
at least 3 instructions, ends in a terminator or exactly at a code boundary,
every instruction spellable to its exact bytes, no implausible opcodes.

So the honest measure of the closure's risk is the FALSE-ENTRY RATE: feed those
same gates entry points that are known-bad and count how many get through.

THE CONTROL: random offsets inside `.byte` territory. Almost all are not
instruction boundaries. If a large share passes, the gates are weak and the 522
entries carry real risk. If very few pass, a wrong entry is unlikely to survive,
and the closure's own entries -- which additionally have a branch from verified
code pointing AT them -- are on much firmer ground than the control.

⚠ This bounds the gates' selectivity. It does NOT prove any individual entry
correct, and it cannot: no amount of gate-passing distinguishes a real function
from data that reads as one. It answers "how much does passing tell us?".

Run:  python3 tools/spelling-probes/adv_closure_false_entry_rate.py [--n 400]
"""
import argparse, importlib.util, json, os, random, sys

REPO = "/home/fsanches/compartilhado/kn5000-roms-disasm"
sys.path.insert(0, REPO); os.chdir(REPO)
BASE, DATA = 0xE00000, 2


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--n", type=int, default=400)
    a = ap.parse_args()

    _s = importlib.util.spec_from_file_location(
        "crr", os.path.join(REPO, "scripts/converters/convert_reachable_ranges.py"))
    crr = importlib.util.module_from_spec(_s); _s.loader.exec_module(crr)
    spec = importlib.util.spec_from_file_location(
        "spans", os.path.join(REPO, "scripts/analysis/v7_undisassembled_spans.py"))
    spans = importlib.util.module_from_spec(spec); spec.loader.exec_module(spans)
    terr = spans.territory(spans.runs("v7/maincpu/kn5000_v7_program.s", "v7/maincpu"))
    rom = open("original_ROMs/kn5000_v7_program.rom", "rb").read()

    def gates(t):
        """Apply the converter's structural gates. Returns the verdict string."""
        insns = crr.decode_range(rom, terr, t)
        if len(insns) < 3:
            return "too short"
        span = sum(n for _, n, _ in insns)
        o, run = t - BASE, 0
        while o + run < len(terr) and terr[o + run] == DATA:
            run += 1
        last = insns[-1][2].strip()
        if (last.split()[0].lower() not in crr.TERMINATORS
                and not crr.UNCOND_JUMP.match(last) and span != run):
            return "no terminator"
        addrs = {x for x, _n, _t in insns}
        for _x, _n, txt in insns:
            m = crr.BRANCH_RE.match(txt.strip())
            if m:
                tg = int(m.group(3), 16)
                if t <= tg < t + span and tg not in addrs:
                    return "misframed branch"
        return "PASSES"

    # ⚠ CONTROL v1 WAS TOO WEAK TO CONCLUDE FROM, and is kept for contrast.
    # Random offsets in `.byte` territory are NOT known-bad: that territory is
    # largely undisassembled CODE, so a good share of those offsets are genuine
    # instruction boundaries and SHOULD pass. Its 28.5% pass rate therefore
    # measures "how much of .byte is code" as much as it measures gate leakage.
    #
    # CONTROL v2 is known-bad by construction: take an entry the converter has
    # already ACCEPTED and shift it by +1. For any instruction longer than one
    # byte that lands strictly inside an instruction, so it cannot be a real
    # entry point. Anything passing from there is pure gate leakage.
    # Control: random offsets in .byte territory.
    rng = random.Random(20260823)
    data_off = [i for i in range(0, len(terr), 97) if terr[i] == DATA]
    picks = rng.sample(data_off, min(a.n, len(data_off)))
    from collections import Counter
    ctrl = Counter(gates(BASE + o) for o in picks)

    # The closure's own new entries.
    cl = json.load(open("analysis/v7-reachability/v7_branch_closure_targets.json"))
    seed = set(json.load(open(
        "analysis/v7-reachability/v7_call_targets.json"))["targets"])
    newly = [t for t in cl["targets"] if t not in seed]
    still_data = [t for t in newly if terr[t - BASE] == DATA]
    real = Counter(gates(t) for t in still_data[:a.n])

    # CONTROL v2: an offset strictly INSIDE the first instruction of a range
    # that passes. Known-bad by construction and independent of how much has
    # been converted so far -- an earlier version selected "seed entries now in
    # CODE territory" and got n=1, because the conversion state it keyed on was
    # being rewritten by a running loop.
    rng2 = random.Random(4242)
    pool = [t for t in still_data if gates(t) == "PASSES"]
    shifted = []
    for t in pool:
        ins = crr.decode_range(rom, terr, t)
        if ins and ins[0][1] >= 2:
            shifted.append(t + 1)               # strictly inside instruction 0
        if len(shifted) >= a.n:
            break
    ctrl2 = Counter(gates(t) for t in shifted)

    def show(name, c, tot):
        print(f"  {name}  (n={tot})")
        for k, v in c.most_common():
            print(f"      {k:18} {v:5}  {100*v/tot:5.1f}%")

    print()
    show("CONTROL: random .byte offsets", ctrl, sum(ctrl.values()))
    print()
    show("closure entries not yet converted", real, max(1, sum(real.values())))
    print()
    show("CONTROL v2: +1 off a converted entry (KNOWN-BAD)", ctrl2, max(1, sum(ctrl2.values())))
    c2 = 100 * ctrl2["PASSES"] / max(1, sum(ctrl2.values()))
    print(f"\n  gate leakage on KNOWN-BAD entries: {c2:.1f}%")
    cp = 100 * ctrl["PASSES"] / max(1, sum(ctrl.values()))
    rp = 100 * real["PASSES"] / max(1, sum(real.values()))
    print()
    print(f"  false-entry rate (control passing all gates) : {cp:.1f}%")
    print(f"  closure entries passing all gates            : {rp:.1f}%")
    if cp > 0:
        print(f"  ratio                                        : {rp/cp:.1f}x")
    print()
    print("  A LOW control rate means passing the gates is informative.")
    print("  ⚠ It does not make any individual entry correct.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
