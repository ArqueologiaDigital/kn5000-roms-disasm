#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""lle_oracle_delay.py -- compose the primitive oracles into a SINGLE-DELAY program oracle.

WHY THIS EXISTS.  `lle_oracle.py` supplies the per-word oracles for the individual datapath
primitives -- BiquadOracle, OnePoleOracle (damping), LFOOracle, DelayOracle (the ring-buffer tap).
The biquad one is already confronted with a live LLE trace by `lle_trace_diff.py`, which decoded
the biquad's accumulator op, coefficient order and operand origin.  The NEXT datapath after the
biquad is the SINGLE DELAY (prog09), whose remaining open microwords are the mixing pair
(ACT 0x0D/0x0E) and the delay-line read (SRC 0x00).  This module CHAINS the primitives into the
whole single-delay signal flow so a seeded delay trace (the build-lane's DLYSEED, the delay analogue
of BIQSEED/REVSEED) can be confronted against it the same way -- turning the delay's open words into
constraint-solving targets instead of guesses.

THE SIGNAL FLOW (from prog09 + the validated HLE delay, kn7000_mame kn5000_tonegen.cpp):
    tap    = line.read(N)                 # DRAM READ, N = descriptor 0x26 (READ_CELL - WRITE_CELL)
    damped = onepole(tap)                 # in-loop HIGH DAMP -- C-RAM 0x03..0x05 (role damping,
                                          #   PROVEN in the disasm; the bytecode CORRECTED the HLE,
                                          #   which had fed the tap back undamped)
    line.write(x + g*damped)              # DRAM WRITE at the line base; g = feedback (C-RAM 0x00)
    out    = (1-mix)*x + mix*tap          # mix ~= 0.5 (SINGLE DELAY designed constant)

⚠ GRADING (honest, per Felipe's rule: the BYTECODE is the source of truth, the HLE may be wrong).
N, g, the damping cells and mix=0.5 are decoded/measured; the ORDER in which the mixing words fold
tap and acc onto the bus (ACT 0x0D/0x0E) is the OPEN part this oracle exists to test -- it encodes
the HLE hypothesis, and a live seeded trace is what confirms or refutes it (exactly as the biquad
oracle is a hypothesis the EQ trace tested).

    python3 dsp/hle/lle_oracle_delay.py --selftest      # synthesise + prove the echo structure
    python3 dsp/hle/lle_oracle_delay.py                 # print what a seeded trace must reproduce
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lle_oracle import OnePoleOracle                                        # noqa: E402


class SingleDelayOracle:
    """The whole single-delay signal path, composed from the primitives.  A feedback ring buffer
    with an in-loop one-pole HIGH DAMP, then the dry/wet mix -- the HLE the seeded trace tests."""

    def __init__(self, delay_samples, feedback, damping, mix=0.5):
        self.N = max(1, int(delay_samples))
        self.g = float(feedback)
        self.mix = float(mix)
        self.damp = OnePoleOracle(float(damping))
        self.buf = [0.0] * (self.N + 1)      # ring buffer; head - N reads the tap
        self.head = 0

    def step(self, x):
        """One frame.  Returns a per-frame record naming every datapath value a trace must show:
        (read_addr, tap, damped, write_addr, write_value, out)."""
        x = float(x)
        read_addr = (self.head - self.N) % len(self.buf)
        tap = self.buf[read_addr]                        # DRAM READ (SRC 0x00, addr = head-N)
        damped, _ = self._damp(tap)                      # in-loop HIGH DAMP (cells 0x03..0x05)
        write_value = x + self.g * damped                # feedback fold (mixing pair 0x0D/0x0E)
        self.buf[self.head] = write_value                # DRAM WRITE at the line base
        out = (1.0 - self.mix) * x + self.mix * tap      # dry/wet mix (~0.5)
        rec = dict(read_addr=read_addr, tap=tap, damped=damped,
                   write_addr=self.head, write_value=write_value, out=out)
        self.head = (self.head + 1) % len(self.buf)
        return rec

    def _damp(self, x):
        steps, acc = self.damp.step(x)
        return acc, steps


def _selftest():
    """Feed an impulse and prove the echo structure: peaks at N, 2N, 3N decaying by ~g each, and
    that the in-loop damping (d>0) makes the fed-back value differ from the undamped one."""
    N, g, d = 5, 0.6, 0.5
    orc = SingleDelayOracle(N, g, d, mix=0.5)
    x = [1.0] + [0.0] * (3 * N + 3)
    out, taps = [], []
    for xi in x:
        r = orc.step(xi)
        out.append(r["out"]); taps.append(r["tap"])

    # dry hit at n=0 (mix*? no -- out[0] = (1-mix)*1 + mix*0 = 0.5)
    assert abs(out[0] - 0.5) < 1e-9, out[0]
    # first echo of the impulse arrives at the tap N frames later
    assert abs(taps[N] - 1.0) < 1e-9, ("tap@N", taps[N])
    # the recirculated echoes appear at 2N, 3N, each smaller (feedback + damping loss)
    e1, e2, e3 = taps[N], taps[2 * N], taps[3 * N]
    assert e1 > e2 > e3 > 0.0, (e1, e2, e3)
    # each recirculation is bounded above by g (damping only removes energy)
    assert e2 <= g * e1 + 1e-9 and e3 <= g * e2 + 1e-9, (e1, e2, e3)

    # damping actually acts: with d=0 the fed-back tap equals the raw tap; with d>0 it lags/loses.
    undamped = SingleDelayOracle(N, g, 0.0, mix=0.5)
    uo = []
    for xi in x:
        uo.append(undamped.step(xi)["tap"])
    # the damped 2nd echo carries less than the undamped 2nd echo (HIGH DAMP removes energy)
    assert taps[2 * N] < uo[2 * N] - 1e-9, (taps[2 * N], uo[2 * N])

    print("selftest PASS:")
    print("  impulse -> echoes at N=%d,2N,3N = %.4f, %.4f, %.4f (decaying)" % (N, e1, e2, e3))
    print("  damped 2nd echo %.4f < undamped %.4f  (in-loop HIGH DAMP acts)" % (taps[2 * N], uo[2 * N]))
    print("  a corrupted read address (tap from the wrong cell) would break the echo lag -> rejected")
    return 0


def _describe():
    N, g, d = 15437, -0.29, 0.4     # ROM-ish: 350 ms @44.1k, documented feedback, a plausible damp
    print("SINGLE DELAY (prog09) oracle -- what a seeded delay trace must reproduce, per frame:")
    print("  N=%d (descriptor 0x26 = READ_CELL - WRITE_CELL), feedback g=%.2f (C-RAM 0x00)," % (N, g))
    print("  in-loop HIGH DAMP one-pole from C-RAM 0x03..0x05 (role damping, PROVEN), mix~=0.5.\n")
    print("  DRAM READ  word: read_addr = (head - N) mod len         (SRC 0x00; the tap)")
    print("  DAMP words : y = (1-d)*tap + d*y1                        (OnePole, cells 0x03..0x05)")
    print("  MIX words  : fold tap and acc onto the bus              (ACT 0x0D/0x0E -- OPEN: the")
    print("               write_value = x + g*damped                  order these fold is what the")
    print("  DRAM WRITE word: buf[head] = write_value                 seeded trace decides)")
    print("  OUTPUT     : (1-mix)*x + mix*tap\n")
    print("  Confront a DLYSEED trace (impulse in the delay-line cells) against these values to pin")
    print("  the mixing pair and the read address, as lle_trace_diff.py did for the biquad.")
    return 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--selftest", action="store_true")
    args = ap.parse_args()
    return _selftest() if args.selftest else _describe()


if __name__ == "__main__":
    sys.exit(main())
