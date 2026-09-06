#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""spec_coverage.py -- strict vs SPECULATIVE decode coverage of the uPD6383GF ISA.

NEC uPD6383GF (Technics SX-KN5000 IC311, SX-WSA1R IC5/6/30).

Goal 2026-09-06: "improve DSP decoding by temporarily accepting less rigorously
some prospective hypotheses so that things fit in place."  This measures exactly
how much fits: it compares the STRICT decode predicate (`dsp_disasm.alu_decoded`,
the rigorous baseline, mirror of `upd6383d.cpp alu_decoded()`) with the
SPECULATIVE one (`alu_decoded_spec`, which additionally anchors the prospective
SRC/ACT codes) over the whole 3057-word corpus.

The prospective codes accepted (each graded, basis at its enum line in
dsp_disasm.py / upd6383d.h; none is MEASURED):
    SRC 0x0B  delay-read data register   (LEDGER sect. 215)
    SRC 0x11  ACCB, second accumulator    (sect. 27; CDJ-500 block diagram)
    SRC 0x13  coef/wave table port        (CORPUS-PATTERNS-SPECULATIVE S-6)
    ACT 0x0C  delay READ                  (12/12 followed by a delay read)
    ACT 0x08  table-port multiply         (pairs with SRC 0x13; weakest)

    python3 dsp/tools/spec_coverage.py

stdlib only, read-only.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pat_corpus import load                                   # noqa: E402
import dsp_disasm as D                                        # noqa: E402

PUB_WORDS = 3057
PUB_STRICT = 1178          # f31_367.py self-test / register tail


def main():
    progs, _ = load()
    words = [w for ws in progs.values() for w in ws]
    tot = len(words)
    strict = sum(1 for w in words if D.alu_decoded(w))
    spec = sum(1 for w in words if D.alu_decoded_spec(w))

    print("== RULE 20 SELF-TEST")
    print("   corpus words   %4d   published %4d   %s"
          % (tot, PUB_WORDS, "PASS" if tot == PUB_WORDS else "FAIL"))
    print("   strict decoded %4d   published %4d   %s"
          % (strict, PUB_STRICT, "PASS" if strict == PUB_STRICT else "FAIL"))

    # the UNIFIED "has a meaning" metric: an ALU op decoded (speculatively), OR a
    # C-format immediate (rendered with its opcode), OR nop/ldptr/rstcur/setvec,
    # OR any structural/idiom annotation.  This is the fraction of the corpus that
    # is not TRULY DARK -- the sense in which the ~93.3% ceiling was stated.
    def has_meaning(w):
        return (D.alu_decoded_spec(w) or D.c_format(w) or D.decoded(w)
                or bool(D.annotate(w)))
    meaning = sum(1 for w in words if has_meaning(w))
    dark = tot - meaning

    print("\n== DECODE COVERAGE")
    print("   STRICT (alu_decoded, rigorous baseline):  %4d / %d = %.2f%%"
          % (strict, tot, 100.0 * strict / tot))
    print("   SPECULATIVE (alu_decoded_spec):           %4d / %d = %.2f%%"
          % (spec, tot, 100.0 * spec / tot))
    print("   ⇒ prospective readings fit in place:      +%d words (+%.2f pts)"
          % (spec - strict, 100.0 * (spec - strict) / tot))
    print("   UNIFIED (has any meaning: spec ALU + C-format + nop/ldptr/setvec")
    print("            + structural annotation):        %4d / %d = %.2f%%"
          % (meaning, tot, 100.0 * meaning / tot))
    print("   ⇒ TRULY DARK (no annotation at all):      %4d / %d = %.2f%%"
          % (dark, tot, 100.0 * dark / tot))

    print("\n== per prospective code: words it newly decodes (isolated on top of strict)")
    for label, s_add, a_add in [
            ("SRC 0x0B delay-read reg", (0x0b,), ()),
            ("SRC 0x11 ACCB",          (0x11,), ()),
            ("SRC 0x13 table port",    (0x13,), ()),
            ("ACT 0x0C delay READ",    (), (0x0c,)),
            ("ACT 0x08 table mul",     (), (0x08,))]:
        src_set = D._ANCHORED_SRC + s_add
        act_set = D._ANCHORED_ACT + a_add
        n = sum(1 for w in words if _decoded_with(w, src_set, act_set)
                and not D.alu_decoded(w))
        print("   %-24s +%d" % (label, n))
    # the register-file addressing modes are an addressing extension, not a code
    c19 = sum(1 for w in words if D.alu_decoded_spec(w) and D.class4(w) in (1, 9))
    print("   %-24s %d (class 1/9 register-file words admitted)" % ("class 1/9 modes", c19))


def _decoded_with(w, src_set, act_set):
    """alu_decoded with a given (src_set, act_set) -- isolated per-code count."""
    if D.c_format(w):
        return False
    cl = D.class4(w)
    if cl not in (2, 8, 0xA):
        return False
    if D.lo12(w) & 0x800 or D.lo_ptrmode(w):
        return False
    if D.lo_src(w) not in src_set or D.lo_act(w) not in act_set:
        return False
    if (D.hi12(w) & D.HI_ST) and (cl & 7) != 2:
        return False
    if D.lo_act(w) == D.LO_ACT_ST_BUS and (cl & 7) != 2:
        return False
    if (D.hi12(w) & D.HI_ST) and (D.hi12(w) & D.HI_B7) and D.hi_f31(D.hi12(w)) != 2:
        return False
    f = D.hi_f31(D.hi12(w))
    if f in (D.HI_ACC_LOAD, D.HI_ACC_ADD):
        return True
    if f == D.HI_ACC_HOLD:
        return cl == 8
    return False


if __name__ == "__main__":
    sys.exit(main())
