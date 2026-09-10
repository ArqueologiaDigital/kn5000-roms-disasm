#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""lle_oracle.py -- turn the validated HLE biquad into a per-WORD ORACLE for the LLE core.

WHY THIS EXISTS.  The uPD6383 LLE core (kn7000_mame src/devices/cpu/upd6383/) executes the
microcode word by word, but the instruction set is only partly decoded: it runs six word forms
and TRAPS the rest, so every audio frame is discarded (silence by construction).  The open
unknowns on the biquad path are small and specific (upd6383d.cpp, DECODED FORMS + hi12 notes):

  * hi12 bits 3:1  -- THE ACCUMULATOR OPERATION.  Only 3 of 8 codes are read
                      (0 = acc<-P, 1 = acc+=P, 2 = unchanged); the biquad needs one load
                      then four accumulates, so the "+=" code must be confirmed on it.
  * the D-RAM OPERAND POINTER origin (m_dp) -- OPEN: nothing in the decoded set loads it, so
                      the core does not know which state cells hold x0,x1,x2,y1,y2.

This module supplies the OTHER side of the equation Felipe asked for -- "use insights from the
HLE of the DSP to aid the LLE".  The HLE biquad is proven bit-exact (biquad-eq.md; +12.00 dB
peak, impulse response == analytic to 0.000 dB), so for a given section's coefficients and a
given input sample it fixes, for each of the five recursive multiply-accumulates:

    (a) the COEFFICIENT consumed  -- from the MEASURED cursor: base + k, +1 per class-A word;
    (b) the OPERAND it multiplies -- one of x0,x1,x2,y1,y2 (a D-RAM state cell);
    (c) the ACCUMULATOR value after the step;
    (d) the accumulator OP required (load for the first term, += for the rest).

Confronting a live per-word LLE trace with this table turns ISA archaeology into constraint
solving: where the LLE traps or diverges, the oracle says exactly what that word must compute
and which cell it must read -- which is what pins down the hi12 "+=" code and the m_dp origin.

GRADING (honest).  The chip stores the recursive pair PRE-NEGATED (C-RAM = b1,b0,b2,-a1,-a2,
makeup), so every term is a plain += MAC with no subtraction -- that is why a load-then-four-
accumulates schedule is the natural one.  The SET of five products and the FINAL sum are
order-invariant HARD targets, and the coefficient at cursor position k is MEASURED regardless
of order.  The step ORDER printed here (b1*x1, b0*x0, b2*x2, -a1*y1, -a2*y2) is the canonical
DF-I schedule and is the HYPOTHESIS a live trace tests -- not itself a measurement.

stdlib + numpy.  Consistent with validate_against_capture.py (same capture, same section map).
"""
import os
import re
import sys
from collections import namedtuple

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from kernels import BiquadDF1                                            # noqa: E402

CAP = os.path.join(os.path.dirname(__file__), "..", "analysis", "data",
                   "wsa1-cram-coefficient-capture-2026-09-09.txt")

# One decoded microword's worth of oracle target.  `cursor_cell` is the ABSOLUTE C-RAM address
# the class-A word reads (base + k); `acc_op` is the hi12 accumulator operation the word must
# carry ("load" = code 0, "mac" = the still-unconfirmed "+=" code); `operand_role` names the
# D-RAM state cell whose pointer the m_dp origin must resolve to.
MacStep = namedtuple("MacStep",
                     "n cursor_cell coeff coeff_role operand_role operand_value "
                     "acc_op product acc_after")

# The recursive-pair coefficients are stored pre-negated, so the five MACs, in canonical DF-I
# order, are (coeff_role, operand_role, section-cell offset, accumulator op).
BIQUAD_SCHEDULE = (
    ("b1",  "x1", 0, "load"),   # acc  <- b1 * x[n-1]
    ("b0",  "x0", 1, "mac"),    # acc  += b0 * x[n]
    ("b2",  "x2", 2, "mac"),    # acc  += b2 * x[n-2]
    ("-a1", "y1", 3, "mac"),    # acc  += (-a1) * y[n-1]   (coeff pre-negated on the chip)
    ("-a2", "y2", 4, "mac"),    # acc  += (-a2) * y[n-2]
)


class BiquadOracle:
    """The per-word oracle for ONE biquad section.  `section` is the six C-RAM cells in the
    decoded order [b1, b0, b2, -a1, -a2, makeup]; `base` is the section's first ABSOLUTE C-RAM
    address (the cursor value at its first class-A word).  Feeding a sample yields the five
    MacSteps plus the makeup post-step, and mirrors the validated BiquadDF1 exactly."""

    def __init__(self, section, base=0):
        assert len(section) == 6, "a section is six C-RAM cells"
        self.c = [float(v) for v in section]      # [b1, b0, b2, -a1, -a2, makeup]
        self.base = int(base)
        self.x0 = self.x1 = self.x2 = 0.0
        self.y1 = self.y2 = 0.0

    def _operand(self, role, xn):
        return {"x0": xn, "x1": self.x1, "x2": self.x2, "y1": self.y1, "y2": self.y2}[role]

    def step(self, xn):
        """One input sample -> the list of MacSteps (five) and the post-sum makeup value.
        Returns (steps, y_presum, y_out).  Updates the x/y history like BiquadDF1."""
        xn = float(xn)
        acc = 0.0
        steps = []
        for k, (coeff_role, operand_role, cell, op) in enumerate(BIQUAD_SCHEDULE):
            coeff = self.c[cell]
            operand = self._operand(operand_role, xn)
            product = coeff * operand
            acc = product if op == "load" else acc + product
            steps.append(MacStep(n=k, cursor_cell=self.base + cell, coeff=coeff,
                                  coeff_role=coeff_role, operand_role=operand_role,
                                  operand_value=operand, acc_op=op, product=product,
                                  acc_after=acc))
        y_presum = acc
        y_out = acc * self.c[5]                    # makeup: the class-8 post-sum step (cell +5)
        # advance the history exactly as DF-I does
        self.x2, self.x1, self.x0 = self.x1, xn, xn
        self.y2, self.y1 = self.y1, y_presum
        return steps, y_presum, y_out

    def as_biquad(self):
        """The equivalent validated BiquadDF1 (b0,b1,b2,a1,a2,makeup) for cross-checking."""
        b1, b0, b2, na1, na2, mk = self.c
        return BiquadDF1(b0, b1, b2, -na1, -na2, mk)


class OnePoleOracle:
    """Per-word oracle for the one-pole DAMPING filter (the reverb/mod feedback loss, the
    0x0D/0x0E two-state pair, §3/§5).  The kernel is y = (1-d)*x + d*y1, so one sample is TWO
    MACs -- a load then an accumulate -- exactly the biquad's schedule in miniature:
        acc  <- (1-d) * x        (load)
        acc  += d     * y1       (accumulate)   ; y1 <- acc
    ⚠ GRADED: the SET of the two products and their sum is the hard target; whether the chip
    stores {1-d, d} as two coefficients or one coefficient plus a subtract is the factorization
    hypothesis a live trace tests (the 0x0D/0x0E adjacency is what carries it)."""

    def __init__(self, damping, base=0):
        self.d = float(damping)
        self.base = int(base)
        self.y1 = 0.0

    def step(self, x):
        x = float(x)
        p0 = (1.0 - self.d) * x
        acc = p0                                   # load
        p1 = self.d * self.y1
        acc = acc + p1                             # accumulate
        steps = [
            MacStep(0, self.base, 1.0 - self.d, "1-d", "x", x, "load", p0, p0),
            MacStep(1, self.base + 1, self.d, "d", "y1", self.y1, "mac", p1, acc),
        ]
        self.y1 = acc
        return steps, acc


class LFOOracle:
    """Per-word oracle for the LFO PHASE ACCUMULATOR (§6/§7a; the 0x092 phase-accumulate word
    that writes the phase back, = 0x082 LFO-read + bit4).  One frame advances the phase by a
    fixed increment and wraps at 2^23-1 -- so the decode target is the plainest possible '+=':
        phase <- (phase + inc) mod 2^23
    A live trace's phase cell must grow by exactly `inc` each frame (the running-sum test across
    FRAMES, not within one), confirming the phase word carries the accumulate op and writes back.
    inc = round(rate_hz/fs * 2^23) is the 23-bit phase increment."""

    WRAP = 1 << 23

    def __init__(self, rate_hz, fs=44100.0, phase=0):
        self.inc = int(round(float(rate_hz) / float(fs) * self.WRAP)) & (self.WRAP - 1)
        self.phase = int(phase) & (self.WRAP - 1)

    def step(self):
        before = self.phase
        self.phase = (self.phase + self.inc) & (self.WRAP - 1)
        return before, self.inc, self.phase


# ---- capture ingest (identical section map to validate_against_capture.py) ------------------
def first_record_cells(path=CAP):
    for ln in open(path):
        if ln.startswith("rec ") and "IC6:" in ln:
            body = ln.split("IC6:", 1)[1]
            return {int(m.group(1)): float(m.group(2))
                    for m in re.finditer(r"(\d+):(-?\d+\.\d+)", body)}
    return {}


def sections_from_capture(path=CAP, first_cell=96):
    """The consecutive biquad region from `first_cell`, as (base, [6 cells]) sections."""
    cells = first_record_cells(path)
    region, c = [], first_cell
    while c in cells:
        region.append(cells[c]); c += 1
    return [(first_cell + s * 6, region[s * 6:s * 6 + 6]) for s in range(len(region) // 6)]


def _fmt(steps):
    print("  k  C-RAM  coeff(role)      operand(role)     op     product        acc_after")
    for s in steps:
        print("  %d  0x%02X  %+.4f(%-3s)  %+.4f(%-2s)   %-4s  %+.6f   %+.6f" %
              (s.n, s.cursor_cell, s.coeff, s.coeff_role, s.operand_value,
               s.operand_role, s.acc_op, s.product, s.acc_after))


def main():
    secs = sections_from_capture()
    if not secs:
        print("no capture found at", CAP); return 1
    print("%d biquad sections in the runtime capture (6 C-RAM cells each, from 0x%02X).\n"
          % (len(secs), secs[0][0]))
    base, section = secs[0]
    orc = BiquadOracle(section, base=base)
    print("ORACLE for section 0  (C-RAM 0x%02X..0x%02X = [b1,b0,b2,-a1,-a2,makeup])" % (base, base + 5))
    print("  = %s\n" % " ".join("%+.3f" % v for v in section))
    for i, x in enumerate((1.0, 0.0, 0.0)):          # an impulse -> the section's response
        steps, y_presum, y_out = orc.step(x)
        print("input sample %d  x = %+.3f  ->  five MACs, then makeup:" % (i, x))
        _fmt(steps)
        print("  sum before makeup = %+.6f ; * makeup %+.3f = OUTPUT %+.6f\n"
              % (y_presum, section[5], y_out))
    print("WHAT A LIVE LLE TRACE MUST REPRODUCE, and what it then decides:")
    print("  * the five 'acc_after' values, in some order  -> confirms the hi12 '+=' op code")
    print("  * the operand of each MAC (x0/x1/x2/y1/y2)     -> pins the D-RAM operand origin m_dp")
    print("  * cursor 0x%02X..0x%02X consumed one-per-class-A -> confirms the coefficient cursor"
          % (base, base + 4))
    print("  * the makeup as a post-sum step at cursor 0x%02X -> the class-8 post-sum word" % (base + 5))
    return 0


if __name__ == "__main__":
    sys.exit(main())
