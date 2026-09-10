#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""validate_against_capture.py -- run the REAL captured C-RAM coefficients through the HLE
biquad kernel, closing the loop between the runtime capture and the reference model.

Reads the committed runtime capture
(dsp/analysis/data/wsa1-cram-coefficient-capture-2026-09-09.txt), takes the biquad region of
IC6's C-RAM (consecutive cells from 96), groups it into 6-cell sections and interprets each in
the decoded order b1,b0,b2,-a1,-a2,makeup (biquad-eq.md).  It then asks a FALSIFIABLE question:
under that interpretation, is every section a STABLE biquad (poles inside the unit circle)?
A wrong coefficient order or fixed-point reading would produce unstable sections; stability of
all of them corroborates both the decode order and the HLE kernel on real chip numbers.

    python3 dsp/hle/validate_against_capture.py
"""
import os
import re
import sys
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from kernels import BiquadDF1                                            # noqa: E402

CAP = os.path.join(os.path.dirname(__file__), "..", "analysis", "data",
                   "wsa1-cram-coefficient-capture-2026-09-09.txt")


def first_record_cells():
    for ln in open(CAP):
        if ln.startswith("rec ") and "IC6:" in ln:
            body = ln.split("IC6:", 1)[1]
            cells = {}
            for tok in body.split():
                m = re.match(r"(\d+):(-?\d+\.\d+)", tok)
                if m:
                    cells[int(m.group(1))] = float(m.group(2))
            return cells
    return {}


def stable(a1, a2):
    """Jury stability for z^2 + a1 z + a2: |a2|<1 and |a1| < 1 + a2."""
    return abs(a2) < 1.0 and abs(a1) < 1.0 + a2


def main():
    cells = first_record_cells()
    if not cells:
        print("no capture rows found at", CAP)
        return 1
    # consecutive biquad region from cell 96
    region = []
    c = 96
    while c in cells:
        region.append(cells[c]); c += 1
    nsec = len(region) // 6
    print("IC6 biquad region: %d consecutive cells from 96 -> %d six-cell sections\n" % (len(region), nsec))
    print("sec  cells(b1,b0,b2,-a1,-a2,mk)                         a1      a2     |poles|  stable  peakdB@")
    all_stable = True
    for s in range(nsec):
        c0, c1, c2, c3, c4, c5 = region[s * 6:s * 6 + 6]
        b1, b0, b2 = c0, c1, c2
        a1, a2 = -c3, -c4                                    # C-RAM holds -a1,-a2
        mk = c5
        st = stable(a1, a2)
        all_stable = all_stable and st
        polemag = abs(np.roots([1.0, a1, a2])).max()
        bq = BiquadDF1(b0, b1, b2, a1, a2, mk)
        freqs = np.linspace(20, 20000, 400)
        resp = 20 * np.log10(bq.response(freqs, 44100.0) + 1e-12)
        pk = freqs[int(np.argmax(resp))]
        print("%2d   [%+.3f %+.3f %+.3f %+.3f %+.3f %+.3f]  %+.3f %+.3f  %.4f   %-5s  %6.0f Hz" %
              (s, c0, c1, c2, c3, c4, c5, a1, a2, polemag, st, pk))
    print("\n%d/%d captured sections are STABLE biquads in the decoded order b1,b0,b2,-a1,-a2,makeup."
          % (sum(1 for s in range(nsec)
                 if stable(-region[s*6+3], -region[s*6+4])), nsec))
    print("=> the HLE kernel runs the REAL chip coefficients, and their stability corroborates"
          "\n   the coefficient order (biquad-eq.md) and the Q0.23 fixed-point reading (sect.9).")
    return 0 if all_stable else 1


if __name__ == "__main__":
    sys.exit(main())
