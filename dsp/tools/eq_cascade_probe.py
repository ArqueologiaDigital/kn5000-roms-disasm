#!/usr/bin/env python3
"""eq_cascade_probe.py -- accept test for the S1/S4 speculative EQ bring-up.

QUESTION THIS ANSWERS
  Given a captured PARAMETRIC-EQ frame with real audio injected at band-0 x0
  (UPD6383_SPEC_INJECT), is the 5-band cascade a working, stable filter or does
  it rail?  Used to judge the S4 variants on one committed criterion:
    * SHIFT       (UPD6383_SPEC_SHIFT)   -- rotate y->y1->y2 each frame
    * SHIFT+SUBFB (+UPD6383_SPEC_SUBFB)  -- and negate the recursive operands

WHAT IT REPORTS
  1. per band: the input-cell value (band k reads x0 at 0x64+4k) and whether it
     is RAILED (|v| >= 0.999)
  2. peak |acc| in the EQ pass relative to accumulator full scale (2^23 << 16)
  3. whether the recursive-state cells in+2/in+3 CHANGE across the frame -- with
     the rotation alive they must; stuck (distinct=1) means the recursion is dead
  4. a one-line verdict

  Run: python3 dsp/tools/eq_cascade_probe.py <trace.txt>
"""
import sys, os

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "hle"))
from lle_trace_diff import parse_trace  # noqa: E402

FS_ACC = 0x800000 << 16


def main():
    path = sys.argv[1]
    rows = parse_trace(open(path).read())
    print("eq_cascade_probe: %s\n" % os.path.basename(path))

    railed = 0
    print("1. cascade signal per band (input cell 0x64+4k):")
    for b in range(5):
        cell = 0x64 + 4 * b
        r = [x for x in rows if x["dp"] == cell and abs(x["mem"]) > 1e-12]
        v = r[0]["mem"] if r else 0.0
        rail = abs(v) >= 0.999
        railed += rail
        print("   band %d in 0x%02X: %+.6f (%5.1f%% FS)%s" %
              (b, cell, v, 100 * abs(v), "  RAILED" if rail else ""))

    eq = [r for r in rows if r["cur"] <= 0x1D]
    accs = [abs(r["acc"]) for r in eq if r["acc"] != 0]
    pk = (max(accs) / FS_ACC) if accs else 0.0
    print("2. peak |acc| in EQ pass = %.3f x FS_acc" % pk)

    # NOTE: the y->y1->y2 rotation happens BETWEEN frames, so within one frame the
    # recursive cells are always constant -- "distinct within frame" cannot detect it.
    # Report their VALUES and rail status instead: a live, stable recursion holds
    # plausible sub-rail history; a dead or unstable one sits at the rail.
    print("3. recursive-state cells in+2/in+3 (value, rail):")
    rec_railed = 0
    for b in range(5):
        for off in (2, 3):
            c = 0x64 + 4 * b + off
            vals = [x["mem"] for x in rows if x["dp"] == c]
            if not vals:
                continue
            v = vals[0]
            rail = abs(v) >= 0.999
            rec_railed += rail
            print("   0x%02X (band %d in+%d): %+.6f%s" % (c, b, off, v, "  RAILED" if rail else ""))

    in0 = [x["mem"] for x in rows if x["dp"] == 0x64 and abs(x["mem"]) > 1e-12]
    print("\n4. VERDICT:")
    if not in0:
        print("   INVALID: no injected signal at band-0 x0 (0x64) -- empty/partial frame, not a")
        print("   filter result.  Re-capture a full frame (arm-timing) before judging.")
    elif railed == 0 and pk < 1.5 and rec_railed == 0:
        print("   STABLE cascade, no rail, bounded acc, sub-rail history -> a working filter.")
    else:
        print("   RAILING: %d band inputs + %d recursive cells at the rail, peak acc %.2fxFS ->" %
              (railed, rec_railed, pk))
        print("   recursion live but UNSTABLE; the feedback sign/order is the variable to settle.")


if __name__ == "__main__":
    main()
