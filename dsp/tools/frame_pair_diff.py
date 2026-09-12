#!/usr/bin/env python3
"""frame_pair_diff.py -- is the DSP body ACTUALLY RUNNING?  Diff two consecutive frame traces.

QUESTION IT ANSWERS
    The project's #1 open item is that external audio never reaches the effect body (the "4.2 audio
    gate").  Every downstream measurement -- operand scales, filter state, signal flow -- is
    meaningless while the body is static, and "the operands look starved" is a judgement call.
    This is the two-sided instrument that settles it:

        capture frame F and frame F+1 with an OTHERWISE IDENTICAL command line, and diff every
        D-RAM cell the two traces report.

    A body fed live audio CANNOT produce two identical frames: the input changes every sample, so
    at least the cells downstream of the input must move.  If F and F+1 are bit-identical, the
    body is frozen -- whatever the coverage counters or the "live operand" censuses say.

    MEASURED 2026-09-12 on the PARAMETRIC EQ (UPD6383_PSHIFT=2, unseeded, DSPCFG=3): every state
    cell bit-identical across the pair (N-SINGLE-DELAY-RECURRENCE §11).  Use this as the ACCEPTANCE
    TEST for any future input-route arm: if the pair still matches, the route did not open.

    python3 dsp/tools/frame_pair_diff.py traceF.log traceF1.log [--lo 84] [--hi 400]

Capture recipe (the two runs differ ONLY in UPD6383_TRACE_FRAME):
    DISPLAY=:0 DHLE=0 DSPCFG=3 TYPEIDX=15 NOTEMODE=0 TGM=0 UPD6383_PSHIFT=2 \\
      UPD6383_TRACE_FRAME=1764000 ./kn7000 kn5000 -rompath ./roms -skip_gameinfo -log -window \\
      -autoboot_script dsp/tools/fx_ab.lua ; cp error.log traceF.log      # then 1764001 -> traceF1
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from dlyseed_confront import parse, s24   # noqa: E402


def cells_of(path, lo, hi):
    """First value each pointer cell shows in the frame (the state the frame ENTERS with)."""
    out, accs = {}, []
    for r in parse(path):
        if r["u1"] or not (lo <= r["iw"] <= hi):
            continue
        out.setdefault(r["dp"], s24(r["mem"]))
        accs.append((r["iw"], r["acc"], r["p"], r["l"]))
    return out, accs


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    lo = int(sys.argv[sys.argv.index("--lo") + 1]) if "--lo" in sys.argv else 84
    hi = int(sys.argv[sys.argv.index("--hi") + 1]) if "--hi" in sys.argv else 400
    if len(args) < 2:
        print(__doc__); return 2
    a, aa = cells_of(args[0], lo, hi)
    b, bb = cells_of(args[1], lo, hi)
    if not a or not b:
        print("one of the traces has no unit-0 body rows in iw %d..%d" % (lo, hi)); return 1
    keys = sorted(set(a) | set(b))
    moved = [k for k in keys if a.get(k) != b.get(k)]
    print("frame A: %s\nframe B: %s" % (os.path.basename(args[0]), os.path.basename(args[1])))
    print("cells seen: %d   MOVED: %d" % (len(keys), len(moved)))
    for k in moved[:24]:
        print("   0x%02X  %12s -> %12s" % (k, a.get(k, "-"), b.get(k, "-")))
    rows_differ = sum(1 for x, y in zip(aa, bb) if x != y)
    print("per-row (iw, acc, P, L) tuples differing: %d of %d" % (rows_differ, min(len(aa), len(bb))))
    if not moved and not rows_differ:
        print("\n⛔ VERDICT: the two frames are BIT-IDENTICAL -- the body is STATIC.  No audio is")
        print("   reaching it, and nothing downstream (operand scales, filter state, signal flow)")
        print("   can be measured until that changes.")
        return 1
    print("\n✅ VERDICT: the frames DIFFER -- the body is live; downstream measurements are meaningful.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
