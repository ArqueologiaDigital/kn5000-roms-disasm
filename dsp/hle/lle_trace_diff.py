#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""lle_trace_diff.py -- confront a live upd6383 LLE per-word trace with the HLE biquad ORACLE.

The LLE core (kn7000_mame src/devices/cpu/upd6383/upd6383.cpp) emits a TIME-ORDERED FRAME TRACE
when armed: one row per executed word, in execution order, with columns
    n iw u1 word dp mem acc accb P cur coef tA tB MUL L
(mem/coef/tA/tB are 24-bit Q0.23 hex; acc/accb/P are signed 44-bit decimals).  This tool reads
that trace and asks, against dsp/hle/lle_oracle.py, the three questions that decode the biquad:

  1. IS THE ACCUMULATOR A RUNNING SUM?  For the five class-A MACs of a biquad section, does
     acc[k] == acc[k-1] + P[k] (and acc[0] == P[0])?  This is SCALE-FREE (acc and P are in the
     same chip fixed-point), so it CONFIRMS THE hi12 "+=" OP directly: the words that satisfy it
     carry the accumulate code, the one that resets carries the load code.
  2. DOES THE COEFFICIENT SEQUENCE MATCH?  Converting coef (Q0.23) to float, do the cursor cells
     the trace reads carry the oracle's [b1,b0,b2,-a1,-a2] in order?  (The cursor advance is
     MEASURED; this checks the words really consume it.)
  3. WHICH D-RAM CELL IS EACH OPERAND?  The operand a MAC multiplied is P/coef; matching it to
     the oracle's x0/x1/x2/y1/y2 gives the (role -> dp) map -- i.e. PINS THE m_dp ORIGIN.

⚠ There is no live trace until the core is built and run (it is instantiated DISABLED; a rig
arms the trace on the PARAMETRIC EQ effect).  So --selftest synthesises a trace FROM the oracle
(a plausible integer datapath) and proves this tool recovers the += op, the coefficients and the
m_dp map from it -- and that a corrupted word (a load where a += belongs) is REJECTED.  That
makes the tool checkable now and fixes the exact trace format the run must produce.

    python3 dsp/hle/lle_trace_diff.py --selftest
    python3 dsp/hle/lle_trace_diff.py TRACE.txt [--section N]   # against a real trace
"""
import argparse
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lle_oracle as O                                                   # noqa: E402

Q = 23                                        # Q0.23 fixed point on the 24-bit IDB
ONE = 1 << Q


def sext(v, bits):
    v &= (1 << bits) - 1
    return v - (1 << bits) if (v >> (bits - 1)) else v


def q23(hexstr):
    """24-bit Q0.23 hex -> float in [-1, 1)."""
    return sext(int(hexstr, 16), 24) / float(ONE)


# One parsed trace row.  acc/accb/P are ints (chip fixed-point); mem/coef/ta/tb are floats.
ROW = re.compile(
    r"^\s*(?:upd6383:\s*)?(\d+)\s+(\d+)\s+([01])\s+([0-9A-Fa-f]+)\s+([0-9A-Fa-f]+)\s+"
    r"([0-9A-Fa-f]+)\s+(-?\d+)\s+(-?\d+)\s+(-?\d+)\s+([0-9A-Fa-f]+)\s+([0-9A-Fa-f]+)\s+"
    r"([0-9A-Fa-f]+)\s+([0-9A-Fa-f]+)\s+([Y.])\s+(-?\d+)\s*$")


def parse_trace(text):
    rows = []
    for ln in text.splitlines():
        m = ROW.match(ln)
        if not m:
            continue
        g = m.groups()
        rows.append(dict(n=int(g[0]), iw=int(g[1]), u1=int(g[2]), word=int(g[3], 16),
                         dp=int(g[4], 16), mem=q23(g[5]), acc=int(g[6]), accb=int(g[7]),
                         p=int(g[8]), cur=int(g[9], 16), coef=q23(g[10]),
                         ta=q23(g[11]), tb=q23(g[12]), mul=(g[13] == "Y"), l=int(g[14])))
    return rows


def diff_section(rows, base, section, tol=1e-3):
    """Confront the class-A MAC words for one biquad section (cursor base..base+4) with the
    oracle.  Returns (ok, report-lines, m_dp_map)."""
    oracle = O.BiquadOracle(section, base=base)
    # drive the oracle far enough that x/y history is generically non-zero, then take one step
    for x in (0.31, -0.52):
        oracle.step(x)
    steps, _, _ = oracle.step(0.73)
    want = {s.cursor_cell: s for s in steps}          # cursor cell -> expected MacStep

    macs = [r for r in rows if base <= r["cur"] <= base + 4]
    out, dp_map = [], {}
    ok = True

    # 1. coefficient sequence
    for cell in range(base, base + 5):
        tr = next((r for r in macs if r["cur"] == cell), None)
        exp = want[cell]
        if tr is None:
            out.append("  cur 0x%02X  MISSING from trace (oracle wants %s=%+.3f)"
                       % (cell, exp.coeff_role, exp.coeff)); ok = False; continue
        cmatch = abs(tr["coef"] - exp.coeff) < tol
        ok = ok and cmatch
        out.append("  cur 0x%02X  coef %+.4f vs oracle %s %+.4f  [%s]"
                   % (cell, tr["coef"], exp.coeff_role, exp.coeff, "match" if cmatch else "DIFF"))

    # 2. running-sum test (the += op), in chip fixed-point (scale-free)
    ordered = [next((r for r in macs if r["cur"] == c), None) for c in range(base, base + 5)]
    if all(ordered):
        load_ok = (ordered[0]["acc"] == ordered[0]["p"])
        run_ok = all(ordered[k]["acc"] == ordered[k - 1]["acc"] + ordered[k]["p"]
                     for k in range(1, 5))
        ok = ok and load_ok and run_ok
        out.append("  running sum: step0 load acc==P [%s]; steps1..4 acc==prev+P [%s]"
                   % ("yes" if load_ok else "NO", "yes" if run_ok else "NO"))
        if run_ok and load_ok:
            out.append("  => the hi12 op on cur 0x%02X..0x%02X is the ACCUMULATE (\"+=\") code;"
                       " cur 0x%02X is the LOAD code" % (base + 1, base + 4, base))
    else:
        ok = False
        out.append("  running sum: cannot test -- not all five MAC words present")

    # 3. operand identity -> m_dp map (operand = P/coef, robust to mem sample timing)
    for cell in range(base, base + 5):
        tr = next((r for r in macs if r["cur"] == cell), None)
        if tr is None or abs(tr["coef"]) < 1e-9:
            continue
        operand = (tr["p"] / float(ONE)) / tr["coef"]   # P is Q0.23(coef*operand); /coef -> operand
        exp = want[cell]
        role_ok = abs(operand - exp.operand_value) < 5e-2
        dp_map[exp.operand_role] = tr["dp"]
        out.append("  cur 0x%02X  operand %+.3f (P/coef) vs oracle %s %+.3f -> D-RAM[0x%02X]  [%s]"
                   % (cell, operand, exp.operand_role, exp.operand_value, tr["dp"],
                      "match" if role_ok else "loose"))
    return ok, out, dp_map


# ---- synthetic trace for the self-test (a plausible integer datapath) ----------------------
def synth_trace(section, base, dp_of, corrupt_step=None):
    """Render the oracle's five MACs as a trace in the core's dump format, using an integer
    Q0.23 datapath: coef_i, operand_i in Q0.23; P_i = coef_i*operand_i >> 23; acc = running sum.
    dp_of maps operand roles to D-RAM addresses.  corrupt_step, if set, makes that step a LOAD
    (acc reset) instead of a += -- the negative control."""
    oracle = O.BiquadOracle(section, base=base)
    for x in (0.31, -0.52):
        oracle.step(x)
    steps, _, _ = oracle.step(0.73)
    lines = ["upd6383: ==== TIME-ORDERED FRAME TRACE, 5 slots ===="]
    acc = 0
    for k, s in enumerate(steps):
        coef_i = round(s.coeff * ONE)
        oper_i = round(s.operand_value * ONE)
        p_i = (coef_i * oper_i) >> Q
        if k == 0 or k == corrupt_step:
            acc = p_i                                  # load
        else:
            acc = acc + p_i                            # accumulate
        h24 = lambda v: "%06X" % (v & 0xFFFFFF)
        # a plausible class-A word (804.A.NN.415); the diff never reads `word`, only the fields
        synth_word = 0x804A00415 | (s.cursor_cell << 12)
        lines.append("upd6383:  %3d %3d  0  %010X %02X %s %14d %14d %14d  %02X %s %s %s   Y %8d"
                     % (k, 100 + k, synth_word, dp_of[s.operand_role], h24(oper_i),
                        acc, 0, p_i, s.cursor_cell, h24(coef_i), h24(0), h24(oper_i), 0))
    return "\n".join(lines)


def selftest():
    secs = O.sections_from_capture()
    base, section = secs[0]
    dp_of = {"x1": 0x10, "x0": 0x11, "x2": 0x12, "y1": 0x13, "y2": 0x14}
    ok_all = True

    print("SELFTEST 1 -- a faithful synthetic trace must be ACCEPTED:")
    rows = parse_trace(synth_trace(section, base, dp_of))
    ok, rep, dp_map = diff_section(rows, base, section)
    for r in rep:
        print(r)
    print("  recovered m_dp map:", {k: "0x%02X" % v for k, v in dp_map.items()})
    ok_all = ok_all and ok and (dp_map.get("x0") == 0x11)
    print("  [%s]\n" % ("PASS" if ok and dp_map.get("x0") == 0x11 else "FAIL"))

    print("SELFTEST 2 -- a corrupted trace (step 3 a LOAD not a +=) must be REJECTED:")
    rows = parse_trace(synth_trace(section, base, dp_of, corrupt_step=3))
    ok_bad, rep, _ = diff_section(rows, base, section)
    print("  " + [r for r in rep if "running sum" in r][0])
    ok_all = ok_all and (not ok_bad)
    print("  [%s]\n" % ("PASS" if not ok_bad else "FAIL (accepted a wrong trace!)"))

    print("ALL SELFTESTS PASSED" if ok_all else "SELFTEST FAILED")
    return 0 if ok_all else 1


def classify_ops(rows):
    """Accumulator-op decode from a live trace, INDEPENDENT of the oracle: for each word,
    decode hi12 bits [3:1] (the accumulator-op field f31, upd6383d.cpp) and classify what the
    accumulator actually did -- LOAD (acc==P), ACCUMULATE (acc==prev+P), UNCHANGED (acc==prev).
    Builds the f31 -> behaviour table the LLE needs (3 of 8 codes were read; 5 open).  Words
    whose P is 0 carry no information (a silent frame), and are counted separately -- which is why
    a MEANINGFUL run needs audio into the DSP (RULE 12)."""
    table = {}   # f31 -> Counter of behaviours
    prev = None
    informative = 0
    for r in rows:
        w = r["word"]
        hi12 = (w >> 24) & 0xFFF
        esc = (hi12 >> 11) & 1
        f31 = (hi12 >> 1) & 7
        acc, p = r["acc"], r["p"]
        if prev is None or esc:      # first word / format-escape word: f31 not an op field
            prev = acc
            continue
        # ★ LOAD (acc<-P) and ACC (acc+=P) are only DISTINGUISHABLE when the accumulator was
        #   non-zero AND the product is non-zero.  On a silent frame both give acc==P, so the
        #   op cannot be read -- which is exactly why a meaningful capture needs audio (RULE 12).
        # The product and the accumulator can live at different fixed-point scales: the biquad
        # applies a MEASURED one-bit shift (P<<1, the factor-of-two of biquad-eq.md / §227), and
        # the coefficient/accumulator shifts (P_SHIFT 6 / ACC_SHIFT 16) can put P at P>>k.  So an
        # ACCUMULATE shows acc-prev == P at ONE of these scales, not only P itself.
        scales = (p, p << 1, p >> 1) + tuple(p >> k for k in (6, 16, 22))
        if p == 0:
            beh = "silent(P=0)"
        elif prev != 0 and any(acc == prev + s for s in scales):
            beh = "ACC"                       # definitive: acc grew by P (at a known scale) from non-zero
        elif acc == p and prev == 0:
            beh = "LOAD/ACC?"                 # ambiguous: prev was 0, both ops give acc==P
        elif any(acc == s for s in scales):
            beh = "LOAD"                      # definitive: acc reset to P (at a known scale)
        elif acc == prev:
            beh = "UNCH"
        else:
            beh = "other"
        prev = acc
        table.setdefault(f31, {}).setdefault(beh, 0)
        table[f31][beh] += 1
        if beh in ("LOAD", "ACC"):
            informative += 1                  # a word that DISTINGUISHED the op
    return table, informative


def ops_report(rows):
    table, informative = classify_ops(rows)
    print("Accumulator-op decode from the live trace (hi12 bits[3:1] = f31 -> behaviour):")
    print("  f31  behaviours (count)                     reading")
    known = {0: "acc <- P (LOAD)", 1: "acc += P (ACC)", 2: "acc unchanged"}
    for f31 in sorted(table):
        behs = ", ".join("%s=%d" % (b, n) for b, n in sorted(table[f31].items()))
        print("   %d   %-40s %s" % (f31, behs, known.get(f31, "OPEN -- researched guess only")))
    print("\n%d informative words (non-zero product, LOAD or ACC)." % informative)
    if informative < 5:
        print("⚠ Few informative words: the frame carried little signal.  For the biquad += op and")
        print("  the m_dp origin, capture with audio flowing into the DSP (RULE 12) -- see the rig.")
    return 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("trace", nargs="?", help="a upd6383 frame-trace file (log or capture)")
    ap.add_argument("--selftest", action="store_true")
    ap.add_argument("--ops", action="store_true", help="classify accumulator ops (oracle-free)")
    ap.add_argument("--section", type=int, default=0, help="which captured biquad section")
    a = ap.parse_args()
    if a.ops and a.trace:
        return ops_report(parse_trace(open(a.trace).read()))
    if a.selftest or not a.trace:
        return selftest()
    secs = O.sections_from_capture()
    base, section = secs[a.section]
    rows = parse_trace(open(a.trace).read())
    if not rows:
        print("no trace rows parsed from", a.trace); return 1
    print("parsed %d trace rows; confronting biquad section %d (cursor 0x%02X..0x%02X)\n"
          % (len(rows), a.section, base, base + 4))
    ok, rep, dp_map = diff_section(rows, base, section)
    for r in rep:
        print(r)
    print("\nm_dp map:", {k: "0x%02X" % v for k, v in dp_map.items()})
    print("VERDICT:", "biquad datapath CONFIRMED" if ok else "divergences above are the worklist")
    return 0


if __name__ == "__main__":
    sys.exit(main())
