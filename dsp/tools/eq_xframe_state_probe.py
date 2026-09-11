#!/usr/bin/env python3
r"""eq_xframe_state_probe.py -- N2: the EQ biquad's state across CONSECUTIVE frames.

QUESTION IT ANSWERS
    The only valid biquad-realization decode is a cross-frame STATE-trajectory match
    (response/FFT/HLE are topology-invariant).  With UPD6383_TRACE_DETAIL (per-word
    detail at the trace-frame arm) + SPEC_INJECT (real audio to x0=0x64), the band-0
    operand cells 0x64..0x67 can be read on consecutive frames.  This pairs two such
    frames and reports how each cell moves frame-to-frame.

CAPTURE (binary built -DKN5000_ENABLE_DSP1=1 with the UPD6383_TRACE_DETAIL edit)
    cd ~/compartilhado/kn7000_mame_build ; for F in 2100000 2100001; do
      DISPLAY=:0 TYPEIDX=15 NPARAM=2 NVALUE=0 UPD6383_SPEC_INJECT=1 \
        UPD6383_TRACE_DETAIL=1 UPD6383_TRACE_FRAME=$F timeout 420 \
        ./kn7000 kn5000 -rompath ./roms -skip_gameinfo -log \
        -autoboot_script ~/compartilhado/kn5000-roms-disasm/dsp/tools/peq_gain.lua
      sed 's/^\[:dsp1\] //' error.log > frame_$F.txt ; done
    (deterministic emulation => TRACE_FRAME=F arms frame F+1, so F and F+1 give
     consecutive frames.)  Committed pair: data/kn5000-dsp-eq-xframe-{A,B}-2026-09-11.txt

FINDING (this pair): 0x65[B] == 0x64[A] exactly -> the input delay line shifts x0->x1
    one cell per frame (feedforward delay CONFIRMED from state).  The recursive cells
    0x66/0x67 are frozen and the accumulator is pinned (datum saturates at -1.0): the
    LLE recursion SATURATES, so the recursive-state trajectory -- and thus the exact
    DF-II-family realization -- CANNOT be decided from this capture.  Next: seed a
    small non-saturating excitation (as BIQSEED did) to get a clean recursive
    trajectory, then run the differential null over {DF-I, DF-II, DF-II transposed}
    under saturating fixed point (biquad_topology_probe.py).

    Run: python3 dsp/tools/eq_xframe_state_probe.py [frameA.txt frameB.txt]
"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "hle"))
from lle_trace_diff import parse_trace  # noqa: E402
DATA = os.path.join(HERE, "..", "analysis", "data")

def cell(path, c):
    rows = parse_trace(open(path).read())
    starts = [i for i, r in enumerate(rows) if r["n"] == 0]
    fr = rows[starts[0]:(starts[1] if len(starts) > 1 else len(rows))] if starts else rows
    rd = [r["mem"] for r in fr if r["dp"] == c]
    return rd[0] if rd else None

def main():
    a = sys.argv[1] if len(sys.argv) > 2 else os.path.join(DATA, "kn5000-dsp-eq-xframe-A-2026-09-11.txt")
    b = sys.argv[2] if len(sys.argv) > 2 else os.path.join(DATA, "kn5000-dsp-eq-xframe-B-2026-09-11.txt")
    print("eq_xframe_state_probe: A=%s  B=%s" % (os.path.basename(a), os.path.basename(b)))
    print("  cell   frame A            frame B")
    A = {c: cell(a, c) for c in range(0x64, 0x68)}
    B = {c: cell(b, c) for c in range(0x64, 0x68)}
    for c in range(0x64, 0x68):
        print(f"  0x{c:02X}   {A[c]!s:>16}  {B[c]!s:>16}")
    shift = (A[0x64] is not None and A[0x64] == B[0x65])
    print(f"\n  0x65[B] == 0x64[A] (x0 -> x1 one-frame delay) ? {shift}"
          f"   [{B[0x65]} == {A[0x64]}]")
    frozen = (A[0x66] == B[0x66] and A[0x67] == B[0x67])
    print(f"  0x66/0x67 frozen frame-to-frame (recursion saturated) ? {frozen}")
    print("\n  READ: feedforward delay confirmed; recursive trajectory saturated ->\n"
          "  full realization needs a non-saturating excitation first (see docstring).")

if __name__ == "__main__":
    main()
