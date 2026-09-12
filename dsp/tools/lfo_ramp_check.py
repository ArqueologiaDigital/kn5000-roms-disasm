#!/usr/bin/env python3
"""lfo_ramp_check.py -- is the LFO phase a FREE-RUNNING RAMP, or does it only look like one?

QUESTION IT ANSWERS, and why it exists
    The gate's chorus criterion was the phase cell's WITHIN-FRAME delta: the value at the wrap
    word minus the value at the accumulate word, which must be the increment (114 at rest).
    ⛔ **That criterion cannot fail in the way that matters.** `iw89` LOADs the increment into the
    accumulator and `iw91` stores it, so the delta is 114 even when the cell is reset to zero
    every frame and the LFO never advances at all. N-INPUT-GATE-OPENED §34 MEASURED exactly that:
    a configuration reporting a perfect 114 whose phase was **0 on eight consecutive frames**.

    The device has always logged the right thing — §119's witness, the phase cell resident at
    body-0 `iw89` on eight consecutive frames. This reads it back and checks the only property an
    LFO phase must have: **a constant, non-zero step**.

        free-running ramp   7273022 7273136 7273250 7273364 ...   step +114, CONSTANT   ✅
        frozen              3168511 3168511 3168511 ...            step 0               ⛔
        reset every frame   0 0 0 0 0 0 0 0                        no phase at all      ⛔
        wrong increment     6987734 1767751 4936376 ...            step ~3.17 M         ⛔

USAGE
    python3 dsp/tools/lfo_ramp_check.py chorus_capture.log [more.log ...] [--increment 114]

    Captures are any chorus (TYPEIDX 0) run with -log; the witness is printed unconditionally by
    the device, so EVERY archived chorus capture can be checked retrospectively -- which is how
    §34 was found.
"""
import os
import re
import sys

WITNESS = re.compile(r"LFO PHASE resident at body-0 iw89 on 8 consecutive frames:([^\\\n]*)")
PAIR = re.compile(r"f(\d+):(-?\d+)")


def phases(path):
    for ln in open(path, errors="replace"):
        m = WITNESS.search(ln)
        if m:
            return [(int(a), int(b)) for a, b in PAIR.findall(m.group(1))]
    return []


def main():
    argv = sys.argv[1:]
    logs = []
    skip = False
    for a in argv:
        if skip:
            skip = False
            continue
        if a == "--increment":
            skip = True
        elif not a.startswith("--"):
            logs.append(a)
    want = int(argv[argv.index("--increment") + 1]) if "--increment" in argv else 114
    if not logs:
        print(__doc__)
        return 2

    print("LFO phase across 8 consecutive frames -- the step must be CONSTANT and equal %d\n" % want)
    print("%-32s %10s %12s  %s" % ("capture", "frames", "step", "verdict"))
    bad = 0
    for p in logs:
        ph = phases(p)
        name = os.path.basename(p)[:32]
        if len(ph) < 3:
            print("%-32s %10s %12s  ⚠ no witness in this log" % (name, len(ph), "-"))
            bad += 1
            continue
        steps = [b - a for (_f1, a), (_f2, b) in zip(ph, ph[1:])]
        uniq = sorted(set(steps))
        if len(uniq) == 1 and uniq[0] == want:
            v = "✅ FREE-RUNNING RAMP at the increment"
        elif len(uniq) == 1 and uniq[0] == 0:
            v = "⛔ FROZEN -- the phase never advances (value %d)" % ph[0][1]
            bad += 1
        elif all(v2 == 0 for _f, v2 in ph):
            v = "⛔ NO PHASE AT ALL -- zero on every frame"
            bad += 1
        elif len(uniq) == 1:
            v = "⛔ constant step %d, not the increment %d" % (uniq[0], want)
            bad += 1
        else:
            v = "⛔ step NOT constant: %s" % ", ".join(str(x) for x in uniq[:4])
            bad += 1
        print("%-32s %10d %12s  %s"
              % (name, len(ph), (str(uniq[0]) if len(uniq) == 1 else "varies"), v))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
