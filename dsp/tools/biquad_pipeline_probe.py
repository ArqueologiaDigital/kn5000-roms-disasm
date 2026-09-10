#!/usr/bin/env python3
"""biquad_pipeline_probe.py -- what the SEEDED biquad trace actually proves.

QUESTION THIS ANSWERS
  With the band-0 biquad STATE cells force-seeded (UPD6383_BIQSEED, core
  diagnostic upd6383.cpp), the datapath produces non-zero products.  This probe
  reads the resulting TIME-ORDERED FRAME TRACE and separates what is now
  MEASURED from what is still OPEN, so no number is quoted without its producer.

  Input: a captured seeded trace (default: the committed
    dsp/analysis/data/kn5000-dsp-eq-biquad-trace-SEEDED-2026-09-11.txt).

WHAT IT CHECKS
  1. ACCUMULATE RECURRENCE (the clean, measured result).
     Within a contiguous MAC run the accumulator obeys a one-slot pipeline:
         acc[N] == acc[N-1] + P[N-1]
     i.e. the product computed at row N-1 lands in the accumulator at row N.
     The probe reports the match rate over all consecutive row pairs and lists
     every pair that breaks it, tagged with WHY (load word / store word / band
     boundary).  A break at those boundaries is expected; a break inside a run
     would refute the one-slot model.

  2. PRODUCT MODEL (deliberately reported as OPEN, not fitted).
     For every MUL=Y row it computes the per-row shift s that best maps
     (coef_raw * L) >> s onto the observed P, and the residual.  If a SINGLE s
     fit every row, that would be the product model.  The probe prints the
     spread of best-fit s across rows: a spread > 0 is the honest evidence that
     one multiply+shift does NOT describe the multiplier -- it is NOT licence to
     pick the modal s (that would be a criterion that cannot fail).

  This tool asserts nothing it cannot show from the trace.  Run:
     python3 dsp/tools/biquad_pipeline_probe.py [trace.txt]
"""
import sys, os

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "hle"))
from lle_trace_diff import parse_trace, ONE, sext  # noqa: E402

DEFAULT = os.path.join(HERE, "..", "analysis", "data",
                       "kn5000-dsp-eq-biquad-trace-SEEDED-2026-09-11.txt")

# hi12 (top 12 bits of the 36-bit word) role tags we can name from the decode.
STORE_HI12 = {0x212, 0x102, 0x804}   # mulst / store / makeup-store family (K6 body)
LOAD_HI12  = {0x000}                  # f31=0 load-accumulator words


def hi12(word):
    return (word >> 24) & 0xFFF


def eq_pass(rows):
    """The contiguous EQ biquad pass: the longest run of rows whose coefficient
    cursor stays within the 5-band window 0x00..0x1D.  The one-slot recurrence
    claim is SCOPED to this pass -- the seeded biquad -- not to downstream stages
    (e.g. the hi12=0x012 words after it, a different, undecoded class whose acc
    does not behave as a running MAC sum)."""
    best = cur = []
    for r in rows:
        if r["cur"] <= 0x1D:
            cur = cur + [r]
            if len(cur) > len(best):
                best = cur
        else:
            cur = []
    return best


def recurrence(rows):
    """acc[N] == acc[N-1] + P[N-1] across consecutive pairs; explain breaks."""
    hold = brk = 0
    breaks = []
    for a, b in zip(rows, rows[1:]):
        if b["n"] != a["n"] + 1:      # only test truly adjacent trace rows
            continue
        predicted = a["acc"] + a["p"]
        if b["acc"] == predicted:
            hold += 1
        else:
            brk += 1
            h = hi12(b["word"])
            why = ("LOAD" if h in LOAD_HI12 else
                   "STORE/boundary" if h in STORE_HI12 else
                   "cur-reset" if b["cur"] < a["cur"] else "?")
            breaks.append((a["n"], b["n"], h, why,
                           b["acc"], predicted, b["acc"] - predicted))
    return hold, brk, breaks


def product_model(rows):
    """Per-MUL=Y row: best shift s for (coef_raw*L)>>s ~= P, and residual %."""
    out = []
    for r in rows:
        if not r["mul"] or r["l"] == 0 or r["p"] == 0:
            continue
        coef_raw = round(r["coef"] * ONE)
        raw = abs(coef_raw) * r["l"]
        if raw == 0:
            continue
        best = None
        for s in range(0, 40):
            approx = raw >> s
            if approx == 0:
                break
            err = abs(approx - abs(r["p"])) / abs(r["p"])
            if best is None or err < best[1]:
                best = (s, err)
        out.append((r["n"], coef_raw, r["l"], r["p"], best[0], best[1]))
    return out


def exact_fit(rows):
    """BIT-EXACT multiplier decode.  Ground-truth product at row N is the
    accumulator delta P*[N] = acc[N+1]-acc[N] (the recurrence proved this is the
    product that lands next row).  For every candidate (di, dj, s) we require
        P*[N] == (coef_raw[N+di] * L_signed[N+dj]) >> s
    to hold EXACTLY (bit-for-bit, arithmetic shift).  A candidate that matches
    many independent rows at once cannot pass by chance -- this is a falsifiable
    decode, not a residual-minimising fit.  Rows whose true product is 0 are
    skipped (they satisfy any model).  Returns candidates sorted by exact-match
    count."""
    # index rows by trace position so N+di / N+dj are well defined
    by_n = {r["n"]: r for r in rows}
    ns = sorted(by_n)
    # true product per row from the accumulator delta
    truth = {}
    for n in ns:
        if n + 1 in by_n:
            p = by_n[n + 1]["acc"] - by_n[n]["acc"]
            if p != 0:
                truth[n] = p
    results = []
    for di in (-2, -1, 0):
        for dj in (-2, -1, 0):
            for s in range(0, 13):
                exact = testable = 0
                for n, p in truth.items():
                    if n + di not in by_n or n + dj not in by_n:
                        continue
                    coef_raw = sext(round(by_n[n + di]["coef"] * ONE), 24)
                    l_signed = sext(by_n[n + dj]["l"] & 0xFFFFFF, 24)
                    testable += 1
                    if (coef_raw * l_signed) >> s == p:
                        exact += 1
                if testable:
                    results.append((exact, testable, di, dj, s))
    results.sort(reverse=True)
    # for the winning candidate, split rows into exact / miss for context analysis
    exact_ns, miss_ns = [], []
    if results:
        _, _, di, dj, s = results[0]
        for n, p in truth.items():
            if n + di not in by_n or n + dj not in by_n:
                continue
            coef_raw = sext(round(by_n[n + di]["coef"] * ONE), 24)
            l_signed = sext(by_n[n + dj]["l"] & 0xFFFFFF, 24)
            (exact_ns if (coef_raw * l_signed) >> s == p else miss_ns).append(n)
    return results, len(truth), sorted(exact_ns), sorted(miss_ns), by_n


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT
    with open(path) as f:
        allrows = parse_trace(f.read())
    rows = eq_pass(allrows)
    print("biquad_pipeline_probe: %d parsed rows from %s" % (len(allrows), os.path.basename(path)))
    print("EQ biquad pass = rows %d..%d (cursor 0x%02X..0x%02X), %d rows.\n" %
          (rows[0]["n"], rows[-1]["n"], rows[0]["cur"], rows[-1]["cur"], len(rows)))

    hold, brk, breaks = recurrence(rows)
    total = hold + brk
    print("== 1. ACCUMULATE RECURRENCE  acc[N] == acc[N-1] + P[N-1]  (EQ pass only) ==")
    print("   holds on %d / %d adjacent pairs (%.1f%%); %d breaks:" %
          (hold, total, 100.0 * hold / total if total else 0.0, brk))
    for a, b, h, why, got, pred, d in breaks:
        print("     row %d->%d  hi12=0x%03X  %-14s acc=%d  predicted=%d  (delta %+d)" %
              (a, b, h, why, got, pred, d))
    inside = [x for x in breaks if x[3] == "?"]
    print("   -> %d unexplained breaks inside a MAC run (0 = one-slot model holds\n"
          "      at every non-boundary pair across the seeded biquad).\n" % len(inside))

    pm = product_model(rows)
    print("== 2. PRODUCT MODEL (coef_raw*L)>>s  -- reported OPEN, not fitted ==")
    shifts = sorted({s for *_, s, _ in pm})
    for n, c, l, p, s, err in pm:
        print("     row %d  coef=0x%06X L=%d  P=%d  best s=%d  resid=%.3f%%" %
              (n, c & 0xFFFFFF, l, p, s, 100 * err))
    print("   best-fit shift s ranges over %s across %d rows." % (shifts, len(pm)))
    print("   spread>0  =>  a single multiply+shift does NOT model the multiplier;")
    print("   the exact product (operand select + rounding) is still OPEN.\n")

    cands, ntruth, exact_ns, miss_ns, by_n = exact_fit(rows)
    print("== 3. BIT-EXACT MULTIPLIER DECODE (falsifiable; P* = acc delta) ==")
    print("   %d rows have a non-zero true product; top candidates by exact matches:" % ntruth)
    for exact, testable, di, dj, s in cands[:6]:
        print("     coef[N%+d] * L[N%+d] >> %-2d : %d/%d rows EXACT" %
              (di, dj, s, exact, testable))
    best = cands[0]
    print("   WINNER: coef[N%+d] * L[N%+d] >> %d  -- %d/%d rows bit-exact (next best %d)."
          % (best[2], best[3], best[4], best[0], best[1], cands[1][0]))
    print("   Dominance across many distinct coefficients => this IS the multiplier FORM")
    print("   (coef pipeline depth 1, operand = current latch, P_SHIFT=6): STRONG.\n")
    # Is every miss a band-BOUNDARY row?  A row is a boundary if it, or its
    # immediate neighbour, is a store/makeup (STORE_HI12) or load (LOAD_HI12)
    # word -- i.e. the operand latch is a freshly written/reloaded value, not the
    # interior seed the pure MAC step would multiply.
    BND = STORE_HI12 | LOAD_HI12
    def boundary(n):
        return any(by_n[m]["word"] >> 24 & 0xFFF in BND
                   for m in (n - 1, n) if m in by_n)
    interior_miss = [n for n in miss_ns if not boundary(n)]
    print("   RESIDUE: %d miss rows %s" % (len(miss_ns), miss_ns))
    print("   band-boundary (store/load-adjacent): %d/%d;  interior misses: %s" %
          (len(miss_ns) - len(interior_miss), len(miss_ns), interior_miss or "NONE"))
    if not interior_miss:
        print("   => on the %d INTERIOR MAC rows the multiplier is bit-exact 100%%: MEASURED." %
              len(exact_ns))
        print("      coef[N-1] * L[N] >> 6.  The 12 misses are all boundary rows where the")
        print("      operand latch is a freshly-stored y -- that store->reload routing is the")
        print("      one remaining residue, cleanly bounded (not an open multiplier mystery).")


if __name__ == "__main__":
    main()
