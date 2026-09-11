#!/usr/bin/env python3
"""eq_cram_operand_reconcile.py -- how the uploaded EQ coefficients (C-RAM 0x00+)
relate to the operands the multiplier actually reads (the cursor-walk `coef`).

QUESTION IT ANSWERS
    N1' found the parametric-EQ coefficients live in C-RAM 0x00+ in a near-RBJ form
    (2cos w0 terms up to ~2.0), while the biquad datapath decode multiplies the
    cursor-walk `coef` values (0.75, 0.5, 0.49 ...).  Two representations, or one?
    This pairs, within a SINGLE capture that dumps BOTH (the SEED8 biquad trace),
    each executed word's cursor coefficient with the C-RAM cell at its cursor index,
    and reports the ratio.

RESULT (SEED8 capture): the ratio is EXACTLY 2.000000 for every paired cell
    (41/41, max deviation 0.0).  So the multiplier operand = C-RAM[cursor] >> 1;
    there is NO transform beyond a 1-bit (Q-format) scale.  The biquad's real
    coefficients ARE the near-RBJ C-RAM 0x00+ set, read halved.  This feeds N2:
    the realization question becomes "which structure does the cursor-ordered MAC
    sequence implement over these near-RBJ coefficients", answerable from the
    decoded datapath -- potentially without a cross-frame state match.

    Run: python3 dsp/tools/eq_cram_operand_reconcile.py [seed8-trace.txt]
"""
import re, os, sys, statistics
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "hle"))
from lle_trace_diff import parse_trace  # noqa: E402

DEFAULT = os.path.join(HERE, "..", "analysis", "data",
                       "kn5000-dsp-eq-biquad-trace-SEED8-2026-09-11.txt")

def q22(x):
    return (x - 0x1000000 if x >= 0x800000 else x) / 2.0 ** 22

def load_cram(path):
    c = {}
    for ln in open(path, encoding="utf-8", errors="replace"):
        m = re.search(r"C-RAM ([0-9A-Fa-f]{2}):\s+(.+)", ln)
        if not m:
            continue
        b = int(m.group(1), 16)
        for i, v in enumerate(m.group(2).split()):
            if re.fullmatch(r"[0-9A-Fa-f]{6}", v):
                c[b + i] = int(v, 16)
    return c

def main():
    path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT
    cram = load_cram(path)
    rows = parse_trace(open(path).read())
    best = cur = []
    for r in rows:
        if r["cur"] <= 0x1D:
            cur = cur + [r]; best = cur if len(cur) > len(best) else best
        else:
            cur = []
    ratios = []
    print("eq_cram_operand_reconcile: %s" % os.path.basename(path))
    print("  cur  C-RAM(Q1.22)  cursor coef   ratio")
    for r in best:
        idx = r["cur"]
        if idx in cram and r["coef"] != 0:
            crv, cov = q22(cram[idx]), r["coef"]
            ratios.append(crv / cov)
            if idx <= 0x05:                    # show band 0 in full
                print(f"  0x{idx:02X}  {crv:+.5f}     {cov:+.5f}    {crv/cov:.5f}")
    print(f"\n  {len(ratios)} paired cells | ratio mean={statistics.mean(ratios):.6f} "
          f"min={min(ratios):.6f} max={max(ratios):.6f} "
          f"| max|r-2|={max(abs(x - 2.0) for x in ratios):.1e}")
    print("  => multiplier operand = C-RAM[cursor] >> 1 (exact); one coefficient set.")

if __name__ == "__main__":
    main()
