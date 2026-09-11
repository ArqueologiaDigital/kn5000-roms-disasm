#!/usr/bin/env python3
"""input_stage_alu_probe.py -- what part of the input-stage words is really open?

QUESTION THIS ANSWERS (Phase 4.2 / 5.x)
  dsp_disasm.py marks the K6 input-stage words w3/w5/w10 "ALU UNKNOWN".  This
  probe asks, from a real-audio trace, WHICH half is unknown: the MULTIPLY
  (coef x L) or the ACCUMULATOR/STORE (f31 op + what is written).

  It reads a signal-bearing trace, finds those words, and tests their product P
  (the chip's product register) bit-exact against the general multiplier
  P = (coef x L) >> 6 established across two programs.

DEGENERACY GUARD (why this probe exists)
  A word with coef = 0.5 has coef_raw = 0x400000 = 2^22, so (coef x L) >> 6
  reduces IDENTICALLY to L << 16.  Reading L<<16 off such a word and calling it
  an "input-injection ALU" is a criterion that cannot fail.  The probe flags any
  coef=0.5 row as DEGENERATE and leans on the non-degenerate rows for the verdict.

  Run: python3 dsp/tools/input_stage_alu_probe.py <trace.txt>
"""
import sys, os

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "hle"))
from lle_trace_diff import parse_trace, ONE, sext  # noqa: E402

DEFAULT = os.path.join(HERE, "..", "analysis", "data",
                       "kn5000-dsp-live-frame-trace-2026-09-10.txt")
WORD_MASK = (1 << 36) - 1
# The three "ALU UNKNOWN" input-stage words (dsp_disasm.py K6_INPUT_STAGE).
ALU_UNKNOWN = {0x0122FF1CE: "w3", 0x202A00448: "w5", 0x282A01417: "w10"}
PORT_READ = {0x2042021CE: "w4 portL", 0x0842011C0: "w8 portR"}


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT
    with open(path) as f:
        rows = parse_trace(f.read())

    print("input_stage_alu_probe: %s\n" % os.path.basename(path))
    print("The audio DI latch reaches the input-stage MULTIPLY?  Port-read words:")
    for r in rows:
        role = PORT_READ.get(r["word"] & WORD_MASK)
        if role:
            print("   %-9s n=%d  L(operand)=%d  %s" % (role, r["n"], r["l"],
                  "<= audio present" if r["l"] else "(quiet this frame)"))

    print("\n'ALU UNKNOWN' words -- is the MULTIPLY standard (coef x L)>>6?")
    nondegen_ok = nondegen_tot = 0
    for r in rows:
        role = ALU_UNKNOWN.get(r["word"] & WORD_MASK)
        if not role or not r["mul"] or r["p"] == 0:
            continue
        coef = sext(round(r["coef"] * ONE), 24)
        L = sext(r["l"] & 0xFFFFFF, 24)
        std = (coef * L) >> 6 == r["p"]
        degen = abs(r["coef"] - 0.5) < 1e-4         # coef=0.5 => (coef*L)>>6 == L<<16
        tag = "DEGENERATE (coef=0.5: (coef*L)>>6 == L<<16)" if degen else \
              ("standard MAC" if std else "NOT standard -- genuinely other")
        if not degen:
            nondegen_tot += 1
            nondegen_ok += std
        print("   %-4s n=%d coef=%+.5f L=%d P=%d  (coef*L)>>6 %s  [%s]" %
              (role, r["n"], r["coef"], r["l"], r["p"],
               "==P" if std else "!=P", tag))

    print("\nVERDICT:")
    if nondegen_tot and nondegen_ok == nondegen_tot:
        print("   The MULTIPLY of the input-stage words is the ordinary (coef x L)>>6 -- "
              "%d/%d non-degenerate rows bit-exact." % (nondegen_ok, nondegen_tot))
        print("   So 'ALU UNKNOWN' is NOT the multiply; it is the ACCUMULATOR/STORE side")
        print("   (f31 op + what value is written) that is open.  The audio reaches the")
        print("   input-stage multiply; whether it PROPAGATES depends on that accumulator-side")
        print("   op -- the real, still-open part of the 4.2 decode.")
    elif not nondegen_tot:
        print("   Only degenerate (coef=0.5) rows present this frame -- inconclusive; need a")
        print("   frame where an input-stage word carries a non-0.5 coefficient.")
    else:
        print("   Some input-stage multiply is NOT the standard multiplier -- genuinely other op.")


if __name__ == "__main__":
    main()
