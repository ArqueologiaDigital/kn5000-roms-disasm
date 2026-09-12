#!/usr/bin/env python3
"""regression_report.py -- does a candidate decode break any OTHER program?

QUESTION IT ANSWERS
    N-INPUT-GATE-OPENED §32 found the first configuration to pass all four gate criteria, on the
    two reference programs (CHORUS and PARAMETRIC EQ).  Two programs is not the catalogue, and
    the arms stay default-off until the rest of it says they are safe.  This is that check.

    Per program it reads ONE frame pair per configuration and reports three things that do not
    assume any particular topology, so they apply to a reverb and a compressor as readily as to
    a biquad:

      LIVE     do the two consecutive frames differ at all?  (a dead body is the first failure
               mode any arm can cause)
      RAILED   how many distinct D-RAM cells sit at +-0x7FFFFF?  ★ This is the failure mode
               §33 MEASURED for §109 bit 28 without the flush: the store reached all five band
               blocks and saturated every one.  A candidate that raises the railed count on any
               program is delivering too much, whatever its liveness says.
      PRODUCTS how many body rows carry a non-zero product?  (a body that is "live" because one
               pointer walks is not computing)

    VERDICT per program: the candidate must not turn a live body dead, and must not rail cells the
    baseline does not.  Anything else is reported as a difference to be read, not an automatic
    failure -- more movement and more products are what the fix is FOR.

USAGE
    python3 dsp/tools/regression_report.py --base <dir> --cand <dir> [--lo 84] [--hi 400]

    Each directory holds `t<TYPEIDX>_F.log' and `t<TYPEIDX>_F1.log' captures, as written by
    dsp/tools/catalogue_regression.sh.
"""
import glob
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from dlyseed_confront import parse, s24   # noqa: E402

RAIL = 0x7fffff
TYPE_NAME = {
    0: "CHORUS", 1: "MODULATED CHORUS", 2: "ENHANCER", 3: "FLANGER", 4: "PHASER",
    5: "ENSEMBLE", 6: "GATED REVERB", 7: "SINGLE DELAY", 8: "MULTI TAP DELAY",
    15: "PARAMETRIC EQ",
}


def stats(fa, fb, lo, hi):
    """(live, n_railed_cells, n_nonzero_product_rows, n_cells) for one frame pair.

    Returns None if either half of the pair is missing -- a sweep in progress, or a capture
    whose emulator run was killed.  A regression table must degrade to "no data" on that row
    rather than crash and discard the rows that DID complete.
    """
    if not (os.path.exists(fa) and os.path.exists(fb)):
        return None

    def cells(path):
        out = {}
        rows = []
        for r in parse(path):
            if r["u1"] or not (lo <= r["iw"] <= hi):
                continue
            out.setdefault(r["dp"], s24(r["mem"]))
            rows.append((r["iw"], r["acc"], r["p"], r["l"]))
        return out, rows
    ca, ra = cells(fa)
    cb, rb = cells(fb)
    if not ra:
        return None
    moved = sum(1 for k in ca if k in cb and ca[k] != cb[k])
    rowdiff = sum(1 for x, y in zip(ra, rb) if x != y)
    railed = sum(1 for v in ca.values() if abs(v) >= RAIL)
    prods = sum(1 for _iw, _a, p, _l in ra if p)
    return dict(live=(moved > 0 or rowdiff > 0), moved=moved, rows=rowdiff,
                railed=railed, prods=prods, cells=len(ca), nrows=len(ra))


def main():
    argv = sys.argv[1:]
    def opt(n, d):
        return argv[argv.index(n) + 1] if n in argv else d
    base = opt("--base", None)
    cand = opt("--cand", None)
    lo = int(opt("--lo", "84"))
    hi = int(opt("--hi", "400"))
    if not base or not cand:
        print(__doc__)
        return 2

    idx = sorted({int(re.search(r"t(\d+)_F\.log$", p).group(1))
                  for p in glob.glob(os.path.join(base, "t*_F.log"))})
    print("catalogue regression: baseline %s  vs  candidate %s   (iw %d..%d)\n"
          % (os.path.basename(base), os.path.basename(cand), lo, hi))
    print("%-4s %-18s | %-26s | %-26s | %s"
          % ("TYPE", "effect", "BASELINE live/rail/prod", "CANDIDATE live/rail/prod", "verdict"))
    print("-" * 118)
    bad = 0
    for t in idx:
        b = stats(os.path.join(base, "t%d_F.log" % t), os.path.join(base, "t%d_F1.log" % t), lo, hi)
        c = stats(os.path.join(cand, "t%d_F.log" % t), os.path.join(cand, "t%d_F1.log" % t), lo, hi)
        name = TYPE_NAME.get(t, "type %d" % t)
        if b is None or c is None:
            print("%-4d %-18s | %-26s | %-26s | ⚠ no body rows -- capture missing or unarmed"
                  % (t, name, "-", "-"))
            continue
        fb = "%s %2d/%2d %2d %3d" % ("LIVE" if b["live"] else "DEAD", b["moved"], b["cells"], b["railed"], b["prods"])
        fc = "%s %2d/%2d %2d %3d" % ("LIVE" if c["live"] else "DEAD", c["moved"], c["cells"], c["railed"], c["prods"])
        if b["live"] and not c["live"]:
            v = "⛔ REGRESSION -- the candidate kills a live body"
            bad += 1
        elif c["railed"] > b["railed"]:
            v = "⛔ REGRESSION -- %d new railed cell(s)" % (c["railed"] - b["railed"])
            bad += 1
        elif c["moved"] > b["moved"] or c["prods"] > b["prods"]:
            v = "✅ no regression (and MORE alive: %+d cells, %+d products)" % (
                c["moved"] - b["moved"], c["prods"] - b["prods"])
        else:
            v = "✅ no regression"
        print("%-4d %-18s | %-26s | %-26s | %s" % (t, name, fb, fc, v))
    print("\n%d regression(s)." % bad)
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
