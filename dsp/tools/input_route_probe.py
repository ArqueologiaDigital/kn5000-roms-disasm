#!/usr/bin/env python3
"""input_route_probe.py -- does audio reach the DSP, and where does it stop?

QUESTION THIS ANSWERS (Phase 4.2, the audio gate)
  The effects DSP only makes faithful sound if the external audio actually
  reaches the biquad's band-0 input.  This probe reads a SIGNAL-BEARING frame
  trace (AUDIO=key) and reports, from the trace alone, how far the signal gets:
    - the DEPOSIT cells (where the core writes the DI latches), and whether the
      trace shows a non-zero value there (= audio arrived at the DSP), vs
    - the BIQUAD band cells 0x64.. (where the multiplier reads its operands),
      and whether any signal is present there (= audio was routed onward).

  Core mechanism it cross-checks (upd6383.cpp latch_inputs_to_dram):
    m_in_base = m_dp at frame start (= 0xFF), IN_LATCH_L_OFF=2, R_OFF=5
    => audio m_di[IN_PORT] is deposited to D-RAM 0x01 (L) and 0x04 (R).

  Run: python3 dsp/tools/input_route_probe.py <trace.txt>
  (Default: the committed non-seeded AUDIO=key EQ trace.)
"""
import sys, os

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "hle"))
from lle_trace_diff import parse_trace, ONE  # noqa: E402

DEFAULT = os.path.join(HERE, "..", "analysis", "data",
                       "kn5000-dsp-eq-biquad-trace-2026-09-10.txt")
DEPOSIT_CELLS = {0x01, 0x04}           # m_in_base(0xFF)+2, +5  (from the core)
BIQUAD_CELLS = set(range(0x64, 0x78))  # band k at 0x64+4k, 5 bands


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT
    with open(path) as f:
        rows = parse_trace(f.read())
    nz = [r for r in rows if abs(r["mem"]) > 1e-9 or r["p"] != 0 or r["l"] != 0]
    print("input_route_probe: %d rows; %d carry any non-zero mem/P/L.\n"
          % (len(rows), len(nz)))

    dep = [r for r in nz if r["dp"] in DEPOSIT_CELLS]
    biq = [r for r in nz if r["dp"] in BIQUAD_CELLS]
    print("DEPOSIT cells {0x01,0x04} (audio arrival at the DSP):")
    if dep:
        for r in dep:
            print("   row %d dp=0x%02X mem=%+.6f  <= audio reached the DI latch" %
                  (r["n"], r["dp"], r["mem"]))
        print("   => AUDIO ARRIVES at the DSP input.\n")
    else:
        print("   none non-zero => audio never reached the deposit (upstream gap).\n")

    print("BIQUAD band cells 0x64..0x77 (audio routed onward to band-0 x0):")
    if biq:
        for r in biq[:8]:
            print("   row %d dp=0x%02X mem=%+.6f  P=%d" % (r["n"], r["dp"], r["mem"], r["p"]))
        print("   => signal present in the biquad state.\n")
    else:
        print("   none non-zero => the input route STOPS before the biquad: the deposited")
        print("   audio at 0x01/0x04 is NOT carried to band-0 x0 at 0x64.\n")

    # Per-unit signal reach: does signal propagate from unit-0 to unit-1?  The
    # reverb (5.1) lives in unit-1; if unit-1's operands are all 0 while unit-0
    # computes, the unit-0 -> unit-1 handoff is the blocker, not just the input.
    for u in (0, 1):
        ur = [r for r in rows if r["u1"] == u]
        if not ur:
            continue
        liveL = sum(1 for r in ur if r["l"] != 0)
        liveP = sum(1 for r in ur if r["p"] != 0)
        naccs = len({r["acc"] for r in ur})
        print("UNIT-%d: %d rows, %d live operands, %d live products, %d distinct acc%s"
              % (u, len(ur), liveL, liveP, naccs,
                 "  <= FROZEN (no computation)" if naccs <= 1 and len(ur) > 4 else ""))
    print()

    print("VERDICT:")
    if dep and not biq:
        print("   Audio reaches the DSP (deposit non-zero) but does NOT reach the biquad.")
        print("   The gap is the input-stage ALU words that would route 0x01/0x04 -> 0x64.")
        print("   Those words are executed as ADDRESSING-ONLY (ALU open), so the copy never")
        print("   happens AND cannot be passively observed in any trace -- decoding them is an")
        print("   ISA-level task (their ALU + full SRC/ACT route), not just a capture problem.")
    elif not dep:
        print("   Audio does not even reach the deposit -- fix the upstream feed first.")
    else:
        print("   Signal reaches the biquad; the input route is (at least partly) live.")


if __name__ == "__main__":
    main()
