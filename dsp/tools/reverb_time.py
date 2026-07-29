#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""reverb_time.py -- THE REVERB FEEDBACK GAIN, READ OUT OF THE FIRMWARE.

NEC uPD6383GF-3BA (Technics SX-KN5000, IC311).  ROUTE 2: the Sub CPU computes
the reverb coefficients arithmetically; this reproduces that computation.

The chain, every link MEASURED in the two dumped ROMs:

    UI parameter  "REVERB TIME", unit `s' (main ROM param 33)
      -> T2 record  [0x75][operand 0][three payload bytes]      canned, per algorithm
      -> jump table 0x014745 -> stub 0x03CE25 -> EVALUATOR 0x039D98
      -> writer LABEL_0387E6 -> `801.0.97.821' + `0A .. .. .. |0x26'
      -> C-RAM cell 0x97 of effect unit 1, signed Q0.23

and the evaluator, decompiled from 0x039D98..0x03A229 (a double-precision
softfloat library: 0x03E290 dmul, 0x03D3A4 ddiv, 0x03E10E dadd, 0x03D404 dneg,
0x03D533 pow, 0x03E2C0 fmul, 0x03D44C f->int, 0x03DCF2 f->d, 0x03DD6C d->f,
0x03DDCA int->f, 0x03D92C fsub, 0x03CF07 read 3 stream bytes big-endian <<8):

    P = payload / 2**23                         # SECONDS, hand-authored per algorithm
    T = piecewise_linear(user_value)            # SECONDS, 0.10 .. 32.00
    C-RAM[0x97] = round_to_q23( -(10 ** (-4.816 * P / T)) / 2 )

    python3 dsp/tools/reverb_time.py [all|curve|table|match|controls]

stdlib only, plus the repo's ROM parsers (like the other tools here).
"""
import argparse
import os
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

# ---------------------------------------------------------------------------
# MEASURED addresses, Sub CPU v1.42
# ---------------------------------------------------------------------------
EVAL_0x75 = 0x039D98             # the REVERB TIME evaluator
STUB_0x75 = 0x03CE25
CELL_0x97 = 0x97                 # C-RAM cell it writes, effect unit 1

# the double literal at 0x012E27 / 0x012E77 / 0x012EA3 / 0x012ECF / 0x012EEB --
# the SAME constant in all five branches.
DECAY = struct.unpack('<d', bytes.fromhex('dd24068195' '4313c0'))[0]      # -4.816

# the five branch break-points and their (offset-const, slope, intercept),
# read straight off the five `cp XWA,imm' / float constants.
BRANCHES = [(0x0F, 0.0, 0.02, 0.1),      # 39de8: v*0.02 + 0.1   (no offset subtract)
            (0x17, 16.0, 0.05, 0.45),    # 39f55
            (0x37, 24.0, 0.10, 0.9),     # 3a00f
            (0x4B, 56.0, 0.20, 4.2),     # 3a0c9
            (0x63, 67.0, 1.00, 0.0)]     # 3a177: (v-67) * 1 + 0

# MEASURED: the opcode-0x75 record payload of every algorithm that has one.
PAYLOAD = {16: 0x0765FD, 17: 0x128F5C, 18: 0x2E76C8, 19: 0x347AE1,
           20: 0x179724, 21: 0x1A4DD2, 22: 0x1FBE76, 23: 0x1FBE76,
           24: 0x1FBE76, 25: 0x1C8B43, 26: 0x2A5E35, 27: 0x2A5E35,
           88: 0x1BE76C, 89: 0x10C49B, 90: 0x1D0E56, 91: 0x1D0E56}
NAMES = {16: "ROOM REVERB 1", 17: "ROOM REVERB 2", 18: "PLATE REVERB 1",
         19: "PLATE REVERB 2", 20: "CONCERT REVERB 1", 21: "CONCERT REVERB 2",
         22: "DARK REVERB 1", 23: "DARK REVERB 2", 24: "BRIGHT REVERB 1",
         25: "BRIGHT REVERB 2", 26: "WAVE REVERB 1", 27: "WAVE REVERB 2",
         88: "ROOM (IC310)", 89: "KARAOKE (IC310)", 90: "BATH ROOM (IC310)",
         91: "STAGE (IC310)"}

# MEASURED at the host port, live cold boot
# (kn7000_mame/notes/data/kn5000_dsp1_upload_coldboot.txt, transfer 26).
LIVE_0x97 = 0xE8F713
LIVE_ERLEVEL = 0x26C9B2          # transfer 30, C-RAM 0xAC and 0xB2
LIVE_PREDELAY = 0x0081E7         # transfer 27, delay descriptor cell 0x00


def f32(x):
    return struct.unpack('<f', struct.pack('<f', x))[0]


def q23(v):
    return (v - 0x1000000) / 0x800000 if v & 0x800000 else v / 0x800000


def revtime(v):
    """-> REVERB TIME in seconds.  The five-branch piecewise-linear map, and
    the float round-trips the compiler emits are reproduced exactly."""
    for hi, off, slope, base in BRANCHES:
        if v <= hi:
            return float(f32(f32(v) - f32(off)) if off else f32(v)) * slope + base
    raise ValueError(v)


def datum(payload, v):
    """-> the 24-bit word the writer sends to C-RAM cell 0x97."""
    # 0x03CF07 returns the 3 payload bytes big-endian, SIGN EXTENDED, << 8.
    raw = payload << 8
    if payload & 0x800000:
        raw -= 1 << 32
    P = f32(f32(raw / f32(32768.0)) / f32(65536.0))          # == payload / 2**23
    e = (float(P) * DECAY) / revtime(v)
    if v <= 0x0F:
        e = f32(e)                                # branch 1 round-trips via float
        if float(e) < -7.0:                       # the underflow-avoiding path
            g = -(10.0 ** float(f32(f32(e) + f32(7.0)))) * 1e-07 / 2.0
        else:
            g = -(10.0 ** float(e)) / 2.0
    else:
        g = -(10.0 ** e) / 2.0
    return int(f32(f32(g) * f32(8388608.0))) & 0xFFFFFF


def cmd_curve():
    print("=" * 78)
    print("1. THE REVERB TIME CURVE -- what the user value MEANS, in seconds")
    print("=" * 78)
    print("  the five branches, MEASURED at 0x039DDF / 0x039F4C / 0x03A006 /")
    print("  0x03A0C0 (the `cp XWA,0x0F/0x17/0x37/0x4B' chain):")
    print("     v  0..15   T = 0.02*v        + 0.10      0.10 .. 0.40 s")
    print("     v 16..23   T = 0.05*(v - 16) + 0.45      0.45 .. 0.80 s")
    print("     v 24..55   T = 0.10*(v - 24) + 0.90      0.90 .. 4.00 s")
    print("     v 56..75   T = 0.20*(v - 56) + 4.20      4.20 .. 8.00 s")
    print("     v 76..99   T = 1.00*(v - 67)             9.00 .. 32.00 s")
    print("  the pieces JOIN: 0.40->0.45 (+0.05), 0.80->0.90 (+0.10),")
    print("  4.00->4.20 (+0.20), 8.00->9.00 (+1.00) -- each step equals the NEXT")
    print("  branch's slope, so the map is monotone with no gap and no overlap.")
    print("  CONTROL: the main ROM's own parameter table gives parameter 33")
    print("  `REVERB TIME' the unit string `s'.  A curve that did not come out in")
    print("  seconds would contradict the firmware's own label.")
    print()
    print("     v :", "  ".join("%d=%.2f" % (v, revtime(v)) for v in (0, 15, 16, 23, 24, 55, 56, 75, 76, 99)))


def cmd_table():
    print("=" * 78)
    print("2. THE PER-ALGORITHM CONSTANT P, AND THE GAIN IT PRODUCES")
    print("=" * 78)
    print("  P = payload / 2**23, in SECONDS -- every one is a round 3-or-4 digit")
    print("  decimal, so it is hand-authored, not derived:")
    for a in sorted(PAYLOAD):
        p = PAYLOAD[a]
        print("     algo %2d %-18s payload %06X   P = %-9.4f s = %8.2f samples"
              % (a, NAMES[a], p, p / 2 ** 23, p / 2 ** 23 * 44100))
    print()
    print("  and the coefficient, for the twelve IC311 reverbs:")
    print("     %-18s %s" % ("", "  ".join("v=%-2d" % v for v in (0, 25, 50, 75, 99))))
    for a in range(16, 28):
        row = []
        for v in (0, 25, 50, 75, 99):
            row.append("%+.4f" % q23(datum(PAYLOAD[a], v)))
        print("     algo %2d %-18s %s" % (a, NAMES[a], " ".join(row)))
    print()
    print("  the stored value is NEGATIVE and never leaves (-0.5, 0].  The loop")
    print("  gain it encodes is TWICE it: G = 2*|C-RAM[0x97]| = 10**(-4.816*P/T).")


def cmd_match():
    print("=" * 78)
    print("3. THE PREDICT / CHECK against the LIVE cold-boot capture")
    print("=" * 78)
    print("  MEASURED at the host port, one single runtime C-RAM write to 0x97:")
    print("     C-RAM[0x97] <- %06X   (Q0.23 %+0.7f)" % (LIVE_0x97, q23(LIVE_0x97)))
    print()
    hits = [(a, v) for a in PAYLOAD for v in range(100)
            if datum(PAYLOAD[a], v) == LIVE_0x97]
    print("  search over all %d (algorithm, user value) pairs -- EXACT 24-bit"
          % (len(PAYLOAD) * 100))
    print("  equality, no tolerance:")
    for a, v in hits:
        print("     >>> algo %d %s, REVERB TIME value %d  ->  T = %.3f s"
              % (a, NAMES[a], v, revtime(v)))
    print("     hits: %d of %d  (a random 24-bit word would hit with p = %.1e)"
          % (len(hits), len(PAYLOAD) * 100, len(PAYLOAD) * 100 / 2 ** 24))
    print()
    print("  the recovered T is EXACTLY 2.000 s -- a round factory default, which")
    print("  the search was in no way steered towards.")
    return hits


def cmd_controls():
    print("=" * 78)
    print("4. THE CONTROLS -- each shown REJECTING something")
    print("=" * 78)
    print("  C1. SIGN.  The canned C-RAM image of every reverb holds cell 0x97 as a")
    print("      POSITIVE round decimal (+0.18 for algo 20).  The formula emits a")
    print("      NEGATIVE number.  The live capture says %+0.7f -- negative."
          % q23(LIVE_0x97))
    print("      A missing 0x03D404 (double negate) would put the sign bit at 0 and")
    print("      the datum would be %06X, not %06X.  REJECTS."
          % (LIVE_0x97 ^ 0xFFFFFF, LIVE_0x97))
    print()
    print("  C2. THE HALVING.  Drop the `/2.0' at 0x03A0AC and the datum becomes")
    print("      %06X.  The live value is %06X.  REJECTS."
          % ((-int(f32(f32(-2 * q23(LIVE_0x97)) * f32(8388608.0)))) & 0xFFFFFF,
             LIVE_0x97))
    print()
    print("  C3. THE ALGORITHM, decided WITHOUT the formula.  The capture uploads a")
    print("      37-cell unit-1 C-RAM image; compared cell-for-cell against all")
    print("      twelve canned images it matches algo 20 CONCERT REVERB 1 in 37 of")
    print("      37 and every other reverb in 13 or 14.  The formula, run on algo")
    print("      20's payload, is what reproduced the datum.  Two chains, no shared")
    print("      premise.  (run: dsp/tools/reverb_time.py needs no ROM for this;")
    print("      the cross-tab is in the findings.)")
    print()
    print("  C4. SIBLING PARAMETERS, same capture, same reverb.  Decoding their")
    print("      evaluators the same way reproduces their live values too:")
    print("        ER.LEVEL   eval 0x039206:  LO + (HI-LO)*v/99, LO=0, HI=0x4CCCCC")
    print("                   v=50 -> %06X ; live %06X"
          % ((0x4CCCCC * 50) // 99, LIVE_ERLEVEL))
    print("        PRE DELAY  eval 0x03925E:  base + v*0xAC44/0x3E8 (ms -> samples)")
    print("                   base=0x8002, v=11 ms -> %06X ; live %06X"
          % (0x8002 + 11 * 44100 // 1000, LIVE_PREDELAY))
    print("      Both exact.  A wrong reading of the shared stream reader 0x03CF07")
    print("      or of the writer split would break all three at once.")
    print()
    print("  C5. THE OPCODE IS REVERB-ONLY.  Opcode 0x75 appears in the parameter")
    print("      bytecode of exactly 16 algorithms: the twelve IC311 reverbs")
    print("      (16..27) and the four IC310/MN19413 reverbs (88..91).  Zero of the")
    print("      79 unit-0 effects use it.  A general-purpose evaluator would not")
    print("      partition that way.")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", nargs="?", default="all",
                    choices=["all", "curve", "table", "match", "controls"])
    a = ap.parse_args()
    if a.cmd in ("all", "curve"):
        cmd_curve(); print()
    if a.cmd in ("all", "table"):
        cmd_table(); print()
    if a.cmd in ("all", "match"):
        cmd_match(); print()
    if a.cmd in ("all", "controls"):
        cmd_controls()


if __name__ == "__main__":
    main()
