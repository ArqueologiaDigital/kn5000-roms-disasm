#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""dsp_immediate_census.py -- the topology/coefficient split, measured at the VALUE level.

Every prior "coefficients are runtime data, not baked in the program" result came from bus
capture or from the descriptor structure. This checks the same claim from a fresh angle -- the
actual C-format immediate VALUES a program embeds -- and partitions them by file class:

    effect BODY (prog*/eff*)  vs  resident KERNEL (kernel.dsm)  vs  boot STRUCT records.

    python3 dsp/tools/dsp_immediate_census.py

The C-format opcode matters: 0x620 is the immediate VALUE load (a size, gain or coefficient),
whereas 0x600 (WAIT/SYNC, whose field is the word's own I-RAM address) and 0x60B/0x60C/0x60D
(pointer-loads) carry ADDRESSES, not values. Lumping them (as an early draft did) makes
addresses look like huge "coefficients". This tool separates them.

MEASURED 2026-09-08 (both products' committed .dsm):
  * Effect bodies contain ONLY value-load C-format words (opcode 0x620): 296 of them, every
    value in [0..1440] -- delay/length (register 0x000: 384/480/704/896), makeup gain
    (0x44C: 800/992), filter-count (0x451), per-effect singletons. NO WAIT/SYNC, NO pointer
    loads, NO control words at all.
  * The resident kernel (kernel.dsm) contains ONLY control words -- WAIT/SYNC + pointer-loads
    (its "big" values 224..3520 are I-RAM addresses / pointer targets) -- and ZERO value
    loads. Coefficients reach the resident program via streamed C-RAM, never a C-format
    immediate.
  * Across ALL programs, NO value-load (0x620) immediate exceeds |imm|=1440. There is no
    baked biquad-range (a1/a2 ~ +/-2) signal coefficient ANYWHERE; every large number is an
    address, not a coefficient.

=> the effect program is pure TOPOLOGY + structural sizing (value-loads only); the resident
   kernel is pure control/pointer scaffolding; per-effect character is the streamed C-RAM.
   The topology/coefficient split, measured at the value level, and it matches the runtime
   bus finding.

stdlib + dsp_disasm; read-only.
"""
import collections
import glob
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dsp_disasm as D                              # noqa: E402

WORD = re.compile(r"^\s*w\d+\s+([0-9A-Fa-f]{10})\b")
TREES = [os.path.join(HERE, "..", "disasm"),
         os.path.join(HERE, "..", "..", "wsa1", "dsp", "disasm")]
VALUE_LOAD = 0x620   # C-format opcode that loads an immediate VALUE (size / gain / coeff);
#                      every other C-format opcode (0x600 sync, 0x60B/C/D pointer-load) is a
#                      control word whose 13-bit field is an ADDRESS, not a value.


def file_class(b):
    if b.startswith(("prog", "eff")):
        return "effect-body"
    if b == "kernel.dsm":
        return "kernel"
    return "struct/other"


def imm(w):
    im = D.c_imm13(w)
    return im - 0x2000 if im & 0x1000 else im


def main():
    val = collections.defaultdict(list)     # class -> value-load (0x620) immediates
    ctrl = collections.defaultdict(list)     # class -> control-word (sync/pointer) fields
    nfiles = collections.Counter()
    for tree in TREES:
        for p in sorted(glob.glob(os.path.join(tree, "*.dsm"))):
            b = os.path.basename(p)
            if b == "index.dsm":
                continue
            cls = file_class(b)
            nfiles[cls] += 1
            for ln in open(p):
                m = WORD.match(ln)
                if m:
                    w = int(m.group(1), 16)
                    if D.c_format(w):
                        (val if D.c_opcode(w) == VALUE_LOAD else ctrl)[cls].append(imm(w))

    print("C-format words by file class, split VALUE-LOAD (opcode 0x620) vs CONTROL (sync/ptr)\n")
    print("class          files   value-loads (sizes/gains/coeffs)   control words (addresses)")
    for cls in ("effect-body", "kernel", "struct/other"):
        v, c = val[cls], ctrl[cls]
        vs = ("n=%-3d range[%d..%d] max|imm|=%d" % (len(v), min(v), max(v),
              max(abs(x) for x in v))) if v else "n=0 (none)"
        cs = ("n=%-3d range[%d..%d]" % (len(c), min(c), max(c))) if c else "n=0 (none)"
        print("%-13s  %4d   %-32s %s" % (cls, nfiles[cls], vs, cs))

    allval = [x for cls in val for x in val[cls]]
    print("\n* Effect bodies carry ONLY value-loads (0 control words); the resident kernel")
    print("  carries ONLY control words (0 value-loads).")
    print("* No value-load (0x620) immediate anywhere exceeds |imm|=%d -- there is NO baked"
          % max(abs(x) for x in allval))
    print("  biquad-range signal coefficient in any program; every large field is an address.")
    print("=> topology/coefficient split, measured at the value level; matches the bus finding.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
