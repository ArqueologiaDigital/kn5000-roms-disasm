#!/usr/bin/env python3
r"""scoop_v7_v10_correspondence.py -- is a v7 span the SAME CODE as a v10 span?

QUESTION ANSWERED
-----------------
When lane `scoop` re-framed a v7 romslice as instructions, was that the same
routine the (independently disassembled) v10 source already holds at the
corresponding place?  Both spans are decoded linearly by MAME `unidasm`; the
mnemonic sequences (operands dropped, because absolute addresses shift between
versions) are aligned with difflib, and the matching share is printed.  A high
ratio from two decoders' views of two different ROM images is corroboration a
single image cannot give: data bytes do not decode to the same instruction
stream twice by accident.

RUN (repo root)
    python3 scripts/analysis/scoop_v7_v10_correspondence.py 0xF03D56 0xF06146 0xF03D80 0xF0616F
    (v7 lo, v7 hi, v10 lo, v10 hi)
"""
import difflib
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "converters"))
import scoop_reframe as R  # noqa: E402


def mnems(img, lo, hi):
    out = []
    for a, n, t in R.unidasm(img, lo, hi - lo):
        out.append(t.split()[0].lower() if t else "?")
    return out


def main():
    a7, b7, a10, b10 = (int(x, 16) for x in sys.argv[1:5])
    m7, m10 = mnems("v7", a7, b7), mnems("v10", a10, b10)
    sm = difflib.SequenceMatcher(None, m7, m10, autojunk=False)
    same = sum(bl.size for bl in sm.get_matching_blocks())
    print("v7 %06X-%06X: %d insns   v10 %06X-%06X: %d insns" % (a7, b7, len(m7), a10, b10, len(m10)))
    print("matching mnemonic sequence: %d (%.1f%% of v7, %.1f%% of v10), ratio %.3f"
          % (same, 100.0 * same / max(1, len(m7)), 100.0 * same / max(1, len(m10)), sm.ratio()))


if __name__ == "__main__":
    main()
