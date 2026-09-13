#!/usr/bin/env python3
"""src0b2_regression.py -- the promotion gate for `UPD6383_SRC0B2`, across the catalogue.

QUESTION IT ANSWERS
    N-INPUT-GATE-OPENED §73 showed `UPD6383_SRC0B2=1` passes five pre-registered criteria at the
    site where the kernel's input stage breaks (`iw25`), and explicitly did NOT promote it, for a
    reason written down in advance: *"one kernel site passing is not the 1 610-word population
    `SRC 0x0B` spans."*  This is the missing measurement -- the SAME programs, at the TRUE DEVICE
    DEFAULT, with the arm off and on -- and it is the first catalogue sweep ever taken at the
    default, because every previous one carried the datum-halving `PSHIFT=2` (§72).

    Verdict per program, on the per-unit hand-off cell `0x05`:

        FIXED     off = railed or zero      -> on = a plausible sample
        KEPT      off = plausible           -> on = plausible            (no regression)
        BROKEN    off = plausible           -> on = railed or zero       ⛔ blocks promotion
        STILL     off = railed or zero      -> on = railed or zero       (unfixed, not a regression)

USAGE
    python3 dsp/tools/src0b2_regression.py <REG_off_dir> <REG_on_dir>

    Capture both with, e.g.:
      NOPAIR=1 TYPES="0 1 2 ..." NOTEOFS=2.5 dsp/tools/catalogue_regression.sh <out_off> \\
          UPD6383_PSHIFT=0 UPD6383_C8SHIFT=0
      NOPAIR=1 TYPES="0 1 2 ..." NOTEOFS=2.5 dsp/tools/catalogue_regression.sh <out_on>  \\
          UPD6383_PSHIFT=0 UPD6383_C8SHIFT=0 UPD6383_SRC0B2=1

⚠ ONE BROKEN PROGRAM BLOCKS PROMOTION.  A decode that fixes twenty programs and silences one is
  not a decode, it is a trade -- and this project has shipped a regression that way before (§56).
⚠ This grades the HAND-OFF only.  It does NOT show the bodies produce correct audio; it shows they
  are handed something other than a rail, which is a precondition, not a result.
"""
import glob
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pickup_cells import read, RAIL                                    # noqa: E402


def state(v):
    if v is None:
        return "missing"
    if abs(v) >= RAIL:
        return "railed"
    if v == 0:
        return "zero"
    return "ok"


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        return 2
    off_dir, on_dir = sys.argv[1], sys.argv[2]
    rows, tally = [], {"FIXED": 0, "KEPT": 0, "BROKEN": 0, "STILL": 0, "missing": 0}
    for f in sorted(glob.glob(os.path.join(off_dir, "t*_F.log")),
                    key=lambda p: int(re.search(r"t(\d+)_F", p).group(1))):
        ti = int(re.search(r"t(\d+)_F", f).group(1))
        g = os.path.join(on_dir, "t%d_F.log" % ti)
        if not os.path.exists(g):
            tally["missing"] += 1
            rows.append((ti, None, None, "missing"))
            continue
        a, b = read(f).get(0x05), read(g).get(0x05)
        sa, sb = state(a), state(b)
        if "missing" in (sa, sb):
            v = "missing"
        elif sa == "ok" and sb != "ok":
            v = "BROKEN"
        elif sa == "ok":
            v = "KEPT"
        elif sb == "ok":
            v = "FIXED"
        else:
            v = "STILL"
        tally[v] += 1
        rows.append((ti, a, b, v))

    print("=== `UPD6383_SRC0B2` PROMOTION GATE -- hand-off cell 0x05, TRUE DEFAULT ===")
    print("  TYPE        arm OFF        arm ON   verdict")
    for ti, a, b, v in rows:
        mark = "  ⛔" if v == "BROKEN" else "  ★" if v == "FIXED" else ""
        print("  %4d %13s %13s   %-7s%s"
              % (ti, "-" if a is None else a, "-" if b is None else b, v, mark))
    print("\n  FIXED %d | KEPT %d | STILL %d | BROKEN %d | missing %d"
          % (tally["FIXED"], tally["KEPT"], tally["STILL"], tally["BROKEN"], tally["missing"]))
    if tally["BROKEN"]:
        print("  ⛔ PROMOTION BLOCKED: %d program(s) that were healthy are not, with the arm on."
              % tally["BROKEN"])
    elif tally["FIXED"]:
        print("  ✅ No regressions, and %d program(s) fixed. The gate this note set is MET;"
              % tally["FIXED"])
        print("     what remains is the judgement that a hand-off is not yet audio.")
    else:
        print("  ⚠ No regressions and nothing fixed -- the arm is INERT on this sample.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
