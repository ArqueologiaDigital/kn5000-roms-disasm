#!/usr/bin/env python3
"""dlyseed_confront.py -- confront a seeded SINGLE DELAY LLE frame trace with the delay oracle.

Reads the upd6383 TIME-ORDERED FRAME TRACE (error.log from a run with -log, rows
    upd6383:   n  iw u1  word dp mem acc accb P cur coef tA tB MUL L
 -- the format lle_trace_diff.py parses; mem/coef/tA/tB are 24-bit hex, acc/accb/P signed
decimals, L the operand latch as a signed decimal) captured with UPD6383_DLYSEED2 (which
seeds the external delay DRAM at the chip's own tap address with 0x4000 -> 0x400000 = 0.5 FS
on the bus), and asks the three questions that decode the delay datapath:

  1. DOES THE SEEDED TAP DATUM REACH THE ALU?  Any body row (iw >= 84, unit 0) whose operand
     latch L == 4194304 (0x400000) -- or whose P equals coef*0x400000 >> 6 -- proves the
     external-DRAM read -> per-line latch -> publish -> multiply path carries the impulse.
     (v1 seeding of the D-RAM state block never reached L; N-DLYSEED-SINGLE-DELAY-TRACE.)
  2. IS THE DAMPING/FILTER ACCUMULATOR A RUNNING SUM?  Across consecutive class-A rows
     (MUL == 'Y') of the body, acc[k] == acc[k-1] + P[k] (scale-free) confirms the "+=" op on
     the delay program exactly as lle_trace_diff.py confirmed it on the biquad; a row with
     acc == P is a load (the section start).
  3. WHERE DOES THE SIGNAL DIE?  The last body row with |acc| or |P| non-zero.

⚠ The `mem` column is m_dram[dp] (the D-RAM cell at the pointer), NOT the fetched delay
datum -- the fetch lands on L.  Do not read "mem" as the tap value.

    python3 dsp/tools/dlyseed_confront.py error.log [--lo 84] [--hi 130]
"""
import re
import sys

IMPULSE = 0x400000                          # 0x4000 << 8, the DLYSEED2 datum on the bus
ROW = re.compile(r"upd6383:\s+(\d+)\s+(\d+)\s+([01])\s+([0-9A-F]+)\s+([0-9A-F]{2})\s+([0-9A-F]{6})"
                 r"\s+(-?\d+)\s+(-?\d+)\s+(-?\d+)\s+([0-9A-F]{2})\s+([0-9A-F]{6})\s+([0-9A-F]{6})"
                 r"\s+([0-9A-F]{6})\s+([Y.])\s+(-?\d+)")


def parse(path):
    rows = []
    in_block = False
    for ln in open(path, errors="replace"):
        if "TIME-ORDERED FRAME TRACE" in ln:
            in_block = True; rows = []          # keep the LAST block in the file
            continue
        if not in_block:
            continue
        m = ROW.search(ln)
        if not m:
            continue
        n, iw, u1, word, dp, mem, acc, accb, p, cur, coef, ta, tb, mul, l = m.groups()
        rows.append(dict(n=int(n), iw=int(iw), u1=int(u1), word=word, dp=int(dp, 16),
                         mem=int(mem, 16), acc=int(acc), accb=int(accb), p=int(p),
                         cur=int(cur, 16), coef=int(coef, 16), mul=(mul == "Y"), l=int(l)))
    return rows


def s24(v):
    v &= 0xffffff
    return v - 0x1000000 if v & 0x800000 else v


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    lo = int(sys.argv[sys.argv.index("--lo") + 1]) if "--lo" in sys.argv else 84
    hi = int(sys.argv[sys.argv.index("--hi") + 1]) if "--hi" in sys.argv else 130
    if not args:
        print(__doc__); return 2
    rows = parse(args[0])
    body = [r for r in rows if r["u1"] == 0 and lo <= r["iw"] <= hi]
    if not body:
        print("no unit-0 body rows in iw %d..%d (is the trace armed after navigation?)" % (lo, hi))
        return 1
    print("%d body rows (unit 0, iw %d..%d)\n" % (len(body), lo, hi))

    # Q1: does the seeded impulse reach the operand latch / a product?
    hits = [r for r in body if abs(r["l"]) == IMPULSE]
    phits = [r for r in body if r["mul"] and r["coef"] and
             r["p"] == (s24(r["coef"]) * IMPULSE) >> 6]
    print("Q1  impulse on the operand latch L (== +-0x400000): %d row(s)" % len(hits))
    for r in hits[:8]:
        print("     n=%3d iw=%3d word=%s dp=%02X L=%d P=%d acc=%d" % (r["n"], r["iw"], r["word"], r["dp"], r["l"], r["p"], r["acc"]))
    print("    products equal to coef*0x400000>>6 (impulse multiplied): %d row(s)" % len(phits))
    for r in phits[:8]:
        print("     n=%3d iw=%3d coef=%06X P=%d" % (r["n"], r["iw"], r["coef"], r["p"]))
    if not hits and not phits:
        print("    -> the impulse did NOT reach the ALU: the tap read is not being published/consumed"
              " (or DLYSEED2 was not active on this frame).")

    # Q2: running sum across consecutive multiply rows
    ok = bad = loads = 0
    prev = None
    for r in body:
        if r["mul"]:
            if prev is not None and r["acc"] == prev["acc"] + r["p"]:
                ok += 1
            elif r["acc"] == r["p"]:
                loads += 1
            elif prev is not None:
                bad += 1
        prev = r
    print("\nQ2  running-sum on multiply rows: acc==prev+P %d, load (acc==P) %d, neither %d" % (ok, loads, bad))
    nz_p = sum(1 for r in body if r["mul"] and r["p"])
    if nz_p == 0:
        print("    ⚠ VACUOUS: every product P is 0 on this frame (starved datapath), so acc==prev+0 holds"
              " trivially -- this does NOT confirm the '+=' op. Re-run with a seeded tap (DLYSEED2).")
    else:
        print("    %d multiply rows carry a non-zero product -> the running-sum test is meaningful." % nz_p)

    # Q3: where the signal dies
    live = [r for r in body if r["acc"] or r["p"] or r["l"]]
    if live:
        last = live[-1]
        print("\nQ3  last body row with a non-zero acc/P/L: n=%d iw=%d acc=%d P=%d L=%d" %
              (last["n"], last["iw"], last["acc"], last["p"], last["l"]))
    else:
        print("\nQ3  every body row is zero -- the datapath is starved on this frame.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
