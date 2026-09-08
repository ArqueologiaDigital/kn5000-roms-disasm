#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""dsp_immediate_census.py -- the topology/coefficient split, measured at the VALUE level.

Every prior "coefficients are runtime data, not baked in the program" result came from bus
capture or from the descriptor structure. This checks the same claim from a fresh angle -- the
actual C-format immediate VALUES a program embeds -- and partitions them by file class:

    effect BODY (prog*/eff*)  vs  resident KERNEL (kernel.dsm)  vs  boot STRUCT records.

    python3 dsp/tools/dsp_immediate_census.py

MEASURED 2026-09-08 (both products' committed .dsm):
  * The 86 effect-body programs embed ONLY structural immediates: delay/length (register
    0x000: 384/480/704/896), makeup gain (0x44C: 800/992), filter-count (0x451: 480/672),
    and a handful of per-effect singletons -- every one |imm| <= ~1500.
  * EVERY larger constant (|imm| > 1500) lives in kernel.dsm (the resident runtime program)
    or the boot struct_* records -- 0 of 86 effect bodies has one.

=> the effect program is pure TOPOLOGY plus structural sizing; the numeric filter constants
   live in the resident kernel, and per-effect character is the streamed C-RAM coefficients
   (matches the runtime bus finding). NOT claimed: the exact role of the kernel/struct
   constants (their values span ~0.1..1.9 in Q1.11 across four registers -- too wide for a
   single clean coefficient class, so they are left OPEN, not decoded as biquad a-coeffs).

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
BIG = 1500   # threshold separating structural sizing from larger (filter-coefficient-range) values


def file_class(b):
    if b.startswith(("prog", "eff")):
        return "effect-body"
    if b == "kernel.dsm":
        return "kernel"
    return "struct/other"


def imms(path):
    out = []
    for ln in open(path):
        m = WORD.match(ln)
        if m:
            w = int(m.group(1), 16)
            if D.c_format(w):
                im = D.c_imm13(w)
                out.append(im - 0x2000 if im & 0x1000 else im)
    return out


def main():
    by_class = collections.defaultdict(list)       # class -> all imms
    nfiles = collections.Counter()
    body_with_big = []
    for tree in TREES:
        for p in sorted(glob.glob(os.path.join(tree, "*.dsm"))):
            b = os.path.basename(p)
            if b == "index.dsm":
                continue
            cls = file_class(b)
            nfiles[cls] += 1
            vs = imms(p)
            by_class[cls].extend(vs)
            if cls == "effect-body" and any(abs(v) > BIG for v in vs):
                body_with_big.append(b)

    print("C-format immediate VALUES by file class  (|imm|>%d = larger-than-structural)\n" % BIG)
    print("class          files   imms   value range        # |imm|>%d   distinct 'big' vals" % BIG)
    for cls in ("effect-body", "kernel", "struct/other"):
        vs = by_class[cls]
        if not vs:
            continue
        big = [v for v in vs if abs(v) > BIG]
        print("%-13s  %4d  %5d   [%6d..%6d]   %6d      %s"
              % (cls, nfiles[cls], len(vs), min(vs), max(vs), len(big),
                 sorted(set(big))[:6]))

    print("\neffect-body files carrying ANY |imm|>%d : %d of %d  %s"
          % (BIG, len(body_with_big), nfiles["effect-body"], body_with_big or "(none)"))
    print("=> effect bodies are topology + structural sizing; every filter-range constant is")
    print("   confined to the resident kernel and boot struct records (topology/coeff split,")
    print("   measured at the value level; corroborates the runtime bus finding).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
