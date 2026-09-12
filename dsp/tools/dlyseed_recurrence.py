#!/usr/bin/env python3
"""dlyseed_recurrence.py -- read the SINGLE DELAY's per-frame recurrence off a seeded LLE trace and
check it at the fixed point.

With UPD6383_DLYSEED2 seeding EVERY frame, the tap datum is a constant x = 0x400000 (= 1.0 at the
chip's Q22, since P = coef*L >> 6 and the datum is acc >> 16) and, thousands of frames in, every
state cell is at its FIXED POINT: the value a cell holds when the frame starts must equal the value
the frame's last writer leaves in it.  That turns one frame trace into a closed set of equations.

The L-channel words of prog09 (iw = 84 + w), with the operand routing the trace shows
(L[N] = mem[dp[N-1]] for SRC 0x07, acc>>16 for SRC 0x10, tempA for SRC 0x19, coefficient bus for the
LFO-family words) and the coefficient in force (coef column of the previous row):

    w7   000.2.48.000   acc = (v + m08) << 16        (bus-add of mem[0x08] onto P[w6] = c2 * x =: v)
    w10  ld  (p)        acc = v ; P = c3 * (v + m08)  (mem[0x50] holds v + m08 from w7)
    w11  mac acc        acc += c3*(x+m08) ; P = c4 * x
    w12  mac (p)        acc += c4*x ; P = c5 * x        -> s50' = acc>>16 (left in cell 0x50)
    w13  mac.st acc     acc += c5*x  (= y_A, not stored: the bit-4 store keeps the PRE-ALU acc)
    w14  000.2.01.000   acc = trunc(acc)
    w15  ld  (p)        acc = c5*x (the stale P) ; P = c6 * s51
    w16  mac acc        acc += c6*s51 ; P = c7 * (c5*x)
    w17  mac (p)        acc += c7*c5*x ; P = c8 * (c5*x)   -> s51' = acc>>16 (left in cell 0x51)
    w18  mac.st acc     acc += c8*c5*x  (= y_B) -> cells 0x07/0x08 for the next frame
    w1..w5  line_in = dry + (1 + c0) * y_B   [the 0x0D/0x0E pair + w3; 1.0 = the P<-bus reading of 0x0E]

    python3 dsp/tools/dlyseed_recurrence.py error.log
prints the coefficients, the fixed-point prediction of s50', s51', y_B from the cells the frame
STARTS with, and the trace's own values, so the reading is checked rather than asserted.
"""
import sys
sys.path.insert(0, __file__.rsplit("/", 1)[0])
from dlyseed_confront import parse, s24   # noqa: E402

X = 0x400000
PSHIFT = 6                                   # the multiplier's right shift (S227: 6 shipped, 7 = total 23)
SHIFT_OF = {}                                # per-coefficient shift (--fmtbit: 7 on bit-12-clear words)


def mul(c, l, name=None):
    return (s24(c) * l) >> SHIFT_OF.get(name, PSHIFT)


def main():
    global PSHIFT
    if len(sys.argv) < 2:
        print(__doc__); return 2
    if "--pshift" in sys.argv:
        PSHIFT = int(sys.argv[sys.argv.index("--pshift") + 1])
    rows = parse(sys.argv[1])
    b = {r["iw"]: r for r in rows if r["u1"] == 0 and 84 <= r["iw"] <= 131}
    if not b:
        print("no body rows"); return 1
    # coefficient -> (row whose coef column shows it, the word that MULTIPLIES with it)
    CW = (("c0", 86, 87), ("c1", 87, 88), ("c2", 89, 90), ("c3", 93, 94), ("c4", 94, 95),
          ("c5", 95, 96), ("c6", 98, 99), ("c7", 99, 100), ("c8", 100, 101))
    c = {k: b[iw]["coef"] for k, iw, _ in CW}
    if "--fmtbit" in sys.argv:
        # UPD6383_FMTBIT reading: the multiplying word's bit 12 clear -> Q0.23 (shift 7), set -> Q1.22 (6)
        for k, _, mw in CW:
            SHIFT_OF[k] = 6 if (int(b[mw]["word"], 16) >> 12) & 1 else 7
    print("coefficients in force (coef column of the previous row):")
    for k, iw, mw in CW:
        v = c[k]
        sh = SHIFT_OF.get(k, PSHIFT)
        print("  %s = %06X  (%+.4f at Q22)  multiplied at iw%d %s bit12=%d shift %d" % (
            k, v, s24(v) / 4194304.0, mw, b[mw]["word"], (int(b[mw]["word"], 16) >> 12) & 1, sh))
    m08 = s24(b[87]["mem"])                     # cell 0x08 as the frame starts (dp=08 at iw87; w7's operand)
    s51 = s24(b[98]["mem"])                     # cell 0x51 as section B starts
    print("\nstate entering the frame: m08 = %d (%+.4f)  s51 = %d (%+.4f)  x = %d (1.0)"
          % (m08, m08 / 4194304.0, s51, s51 / 4194304.0, X))

    # section A.  w10 LOADS the product w6 formed, c2 * x (c2 = 0x400000: unity at total shift 22,
    # one half at 23), and leaves its datum v in cell 0x50; w11/w12 multiply v.
    a10 = mul(c["c2"], X, "c2")
    v = a10 >> 16
    u = v + m08                                  # w7's bus-add: P[w6] (= c2*x) + mem[0x08]
    accA = a10 + mul(c["c3"], u, "c3") + mul(c["c4"], v, "c4")   # after w12's accumulate
    s50n = accA >> 16
    yA = (accA + mul(c["c5"], v, "c5")) >> 16
    # section B
    p5 = mul(c["c5"], v, "c5")
    accB = p5 + mul(c["c6"], s51, "c6") + mul(c["c7"], p5 >> 16, "c7")
    s51n = accB >> 16
    yB = (accB + mul(c["c8"], p5 >> 16, "c8")) >> 16

    def chk(name, pred, got):
        print("  %-28s predicted %12d   trace %12d   %s" % (name, pred, got, "OK" if pred == got else "DIFF %+d" % (got - pred)))
    print("\nfixed-point check (prediction from the entering state vs the trace's own columns):")
    chk("acc after w12 (iw96)", accA, b[96]["acc"])
    chk("cell 0x50 left (mem@iw97)", s50n, s24(b[97]["mem"]))
    chk("y_A = acc after w13 (iw97)", yA, b[97]["acc"] >> 16)
    chk("acc after w17 (iw101)", accB, b[101]["acc"])
    chk("cell 0x51 left (mem@iw102)", s51n, s24(b[102]["mem"]))
    chk("y_B = acc after w18 (iw102)", yB, b[102]["acc"] >> 16)
    chk("y_B == m08 (steady state)", yB, m08)
    chk("s51' == s51 (steady state)", s51n, s51)
    # the input/feedback fold w1..w4, as the DEVICE executes it: acc[w4] = P[w0] (the kernel's stale
    # product, loaded by w1's f31=0) + L[w2]<<16 (the P<-bus reading of ACT 0x0E, here the pickup
    # cell 0x05 = a saturated rail in the starved LLE) + c0*m08 (w3: FEEDBACK x damped output) + c1*m08.
    # Only the c0 term is a clean multiply; the rest rides on the open 0x0D/0x0E readings.
    fold = b[84]["p"] + (b[86]["l"] << 16) + mul(c["c0"], m08, "c0") + mul(c["c1"], m08, "c1")
    chk("acc after w4 (iw88) = fold", fold, b[88]["acc"])
    print("\n  the fold's clean term: c0 = C-RAM[0x00] = %+.4f (Q22) x y_B -- the HLE's feedback cell; the "
          "other two terms (P[w0] stale, L[w2]<<16 = the pickup rail) are the open 0x0D/0x0E words."
          % (s24(c["c0"]) / 4194304.0))

    # DC gain of the damping cascade under the MEASURED routing, closed form, for the two
    # coefficient scales S227 leaves open (total shift 22 = shipped, unity 0x400000; 23 = the
    # "UNTIED" variant, unity 0x7FFFFF).  Section B's own fixed point s51 = c5(1+c7)x/(1-c6),
    # y_B = c5(1+c7+c8)x + c6*s51.  A damping filter has |gain| <= 1; the tap x is the input.
    print("\nDC gain of the damping cascade y_B/x under the measured routing (device reading; v = c2*x):")
    for shift, unity in ((22, 4194304.0), (23, 8388608.0)):
        k = {n: s24(vv) / unity for n, vv in c.items()}
        s51fp = k["c5"] * k["c2"] * (1 + k["c7"]) / (1 - k["c6"])
        ybx = k["c5"] * k["c2"] * (1 + k["c7"] + k["c8"]) + k["c6"] * s51fp
        print("  total shift %d (unity 0x%06X): c2 = %+.3f  c3..c8 = %+.3f %+.3f %+.3f | %+.3f %+.3f %+.3f  ->  s51/x = %+.3f  y_B/x = %+.3f  |gain| %s 1"
              % (shift, int(unity), k["c2"], k["c3"], k["c4"], k["c5"], k["c6"], k["c7"], k["c8"], s51fp, ybx,
                 "<=" if abs(ybx) <= 1 else ">"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
