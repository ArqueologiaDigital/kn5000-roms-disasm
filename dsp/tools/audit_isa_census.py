#!/usr/bin/env python3
"""audit_isa_census.py -- READ-ONLY census for the ISA audit (AUDIT_ISA_findings.md).

Re-measures a handful of published claims over the FULL 3057-word corpus
(kernel 60 + epilogue 23 + 38 distinct body images = 2974), split by region,
because several of the claims under audit were measured on the BODIES ONLY and
the kernel is systematically excluded by construction.

Usage:  python3 dsp/tools/audit_isa_census.py
"""
import os
import sys
from collections import Counter, defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import pat_corpus  # noqa: E402


def hi12(w):
    return (w >> 24) & 0xFFF


def class4(w):
    return (w >> 20) & 0xF


def addr8(w):
    return (w >> 12) & 0xFF


def lo12(w):
    return w & 0xFFF


def c_format(w):
    return (hi12(w) & 0xF00) == 0xC00


def is_c40(w):
    return (hi12(w) & 0xFFE) == 0xC40


def lo_src(w):
    return (w >> 6) & 0x1F


def lo_act(w):
    return w & 0x1F


def main():
    progs, meta = pat_corpus.load()
    regions = {}
    for name, ws in progs.items():
        regions[name] = ("kernel" if name in ("KERNEL", "EPILOGUE") else "body", ws)

    def walk(pred, want_regions=("kernel", "body")):
        out = []
        for name, (reg, ws) in regions.items():
            if reg not in want_regions:
                continue
            for i, w in enumerate(ws):
                if pred(w):
                    out.append((name, i, w))
        return out

    total = sum(len(ws) for _r, ws in regions.values())
    nk = sum(len(ws) for r, ws in regions.values() if r == "kernel")
    nb = total - nk
    print("corpus: %d words (kernel %d, bodies %d, %d images)"
          % (total, nk, nb, len(regions) - 2))

    # ---- 1. lo12 bit 11 census, and the five "phantom" SRC/ACT codes --------
    print("\n=== 1. lo12 bit 11 (the alternate encoding) ===")
    for reg in ("kernel", "body"):
        hits = walk(lambda w: (lo12(w) & 0x800) and not c_format(w), (reg,))
        print("  %-7s bit-11 non-c-format words: %d  shapes %s"
              % (reg, len(hits),
                 dict(Counter("%03X" % lo12(w) for _n, _i, w in hits))))

    print("\n  the five codes bit11-family.md sect. 9.3 calls PARSE ARTEFACTS")
    for label, pred in (("SRC 0x02", lambda w: lo_src(w) == 0x02),
                        ("SRC 0x04", lambda w: lo_src(w) == 0x04),
                        ("ACT 0x03", lambda w: lo_act(w) == 0x03),
                        ("ACT 0x04", lambda w: lo_act(w) == 0x04),
                        ("ACT 0x1C", lambda w: lo_act(w) == 0x1C)):
        for reg in ("kernel", "body"):
            hits = walk(lambda w: pred(w) and not c_format(w), (reg,))
            b11 = [h for h in hits if lo12(h[2]) & 0x800]
            clr = [h for h in hits if not (lo12(h[2]) & 0x800)]
            if not hits:
                continue
            print("    %-9s %-7s n=%-4d bit11-set=%-4d bit11-CLEAR=%-4d %s"
                  % (label, reg, len(hits), len(b11), len(clr),
                     sorted({"%s w%d %03X.%X.%02X.%03X"
                             % (n, i, hi12(w), class4(w), addr8(w), lo12(w))
                             for n, i, w in clr})[:6]))

    # ---- 2. hi12 bit 10 (END OF BLOCK) by region ---------------------------
    print("\n=== 2. hi12 bit 10 with bit 11 clear (END OF BLOCK) ===")
    for reg in ("kernel", "body"):
        hits = walk(lambda w: (hi12(w) & 0x400) and not (hi12(w) & 0x800), (reg,))
        tagged = [h for h in hits
                  if class4(h[2]) == 1 and addr8(h[2]) in (0x0E, 0x0F)]
        print("  %-7s END words %-4d  unit-TAGGED %-4d  untagged %d"
              % (reg, len(hits), len(tagged), len(hits) - len(tagged)))
        if reg == "kernel":
            for n, i, w in hits:
                print("      %-9s w%-3d %03X.%X.%02X.%03X%s"
                      % (n, i, hi12(w), class4(w), addr8(w), lo12(w),
                         "   <== TAGGED" if (class4(w) == 1 and addr8(w) in (0x0E, 0x0F))
                         else ""))
        else:
            per = Counter(n for n, _i, _w in hits)
            bad = {k: v for k, v in per.items() if v != 1}
            last = sum(1 for n, i, _w in hits if i == len(progs[n]) - 1)
            print("      one-per-image: %s ; final word in %d of %d"
                  % ("YES" if not bad else "NO %s" % bad, last, len(hits)))

    # ---- 3. the C-format payload rule --------------------------------------
    print("\n=== 3. C-FORMAT: format predicate vs payload rule ===")
    cf = walk(c_format)
    c40 = [h for h in cf if is_c40(h[2])]
    out = [h for h in cf if not is_c40(h[2])]
    print("  c_format (hi12[11:8]==0xC) : %d" % len(cf))
    print("  is_c40   ((hi12&0xFFE)==0xC40, i.e. opcode 0x620) : %d" % len(c40))
    print("  OUTSIDE the payload rule   : %d   (A = imm13>>5 is NOT the payload)"
          % len(out))
    for n, i, w in out:
        imm = (w >> 12) & 0x1FFF
        print("      %-9s w%-3d %03X.%X.%02X.%03X  opcode %03X  imm13 %5d  "
              "A=%d B=%d  mult32=%s"
              % (n, i, hi12(w), class4(w), addr8(w), lo12(w),
                 (w >> 25) & 0x7FF, imm, (w >> 17) & 0xFF, (w >> 12) & 0x1F,
                 imm % 32 == 0))
    print("  C-format opcode census bits[35:25]: %s"
          % dict(Counter("%03X" % ((w >> 25) & 0x7FF) for _n, _i, w in cf)))

    # ---- 4. bit 23 (cursor fetch) by class, per region ---------------------
    print("\n=== 4. bit 23 (cursor FETCH) by class4, per region ===")
    for reg in ("kernel", "body"):
        c = Counter(class4(w) for _n, _i, w in
                    walk(lambda w: (w >> 23) & 1 and not c_format(w), (reg,)))
        print("  %-7s %s" % (reg, dict(sorted(c.items()))))

    # ---- 5. hi12 bit 4 store census (the gate) -----------------------------
    print("\n=== 5. hi12 bit 4 (STORE) x bit 7 x f31 ===")
    tab = defaultdict(int)
    for _n, _i, w in walk(lambda w: (hi12(w) & 0x10) and not c_format(w)):
        b7 = 1 if hi12(w) & 0x80 else 0
        tab[(b7, (hi12(w) >> 1) & 7)] += 1
    print("  (bit7, f31) -> n : %s" % dict(sorted(tab.items())))

    # ---- 6. mode 2 never carries the escape (R2) --------------------------
    print("\n=== 6. hi12 bit 11 (ESC) vs addressing mode (class4 & 7) ===")
    t = defaultdict(int)
    for _n, _i, w in walk(lambda w: not c_format(w)):
        t[(class4(w) & 7, 1 if hi12(w) & 0x800 else 0)] += 1
    for k in sorted(t):
        print("  mode %d  esc %d : %d" % (k[0], k[1], t[k]))


if __name__ == "__main__":
    main()
