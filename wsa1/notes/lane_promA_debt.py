#!/usr/bin/env python3
"""How many bytes of prom_a are still NOT reproduced by real source, and what
did each of the promA lane's four spans become?

QUESTION IT ANSWERS: "the 2026-09-02 promA lane started with four `.incbin`
spans totalling 2,542 bytes.  How many are left, and is the replacement real
source or a `.byte` blob wearing a different name?"

⚠ `.incbin` COUNT ALONE IS THE WRONG INSTRUMENT.  The lane brief records that
this project once shipped a false "territorially complete" claim by counting
`.incbin` directives in a tree whose remaining debt was written as `.byte`.  So
this script reports BOTH: the `.incbin` byte total, and, per span, a census of
the DIRECTIVE KIND of every source line inside it -- instruction, `.long`,
`.byte`, `.fill` -- because a `.byte` run is exactly where un-decoded code
hides.

METHOD.  Every line the converters emit carries a `; XXXXXX` address comment.
The census walks those, attributes each line to the span containing its address,
and classifies the line by its leading directive.  It does NOT try to compute
byte lengths from the text: the byte gate already proves the source reproduces
the image, so what matters here is the KIND of source, not a second byte count.

RUN
    python3 notes/lane_promA_debt.py
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "prom_a", "wsa1_prom_a.s")

# the lane's four spans, as they stood at the start of 2026-09-02
SPANS = [(0xF96504, 1889, "script interpreter: 8 handlers + 3 tables"),
         (0xF98DE5, 539, "PtrTable_F98DE5: 134 LE32 + a truncated 135th"),
         (0xF8E77C, 81, "AddrTable_F8E77C / _F8E7A9 + 13 B residue"),
         (0xFDFFDF, 33, "linker slack: a truncated stale prologue")]

INCBIN = re.compile(r'\.incbin "original_ROMs/wsa1_prom_a\.ic12", '
                    r'(0x[0-9A-Fa-f]+), (0x[0-9A-Fa-f]+)')
LINE = re.compile(r'^\t(\S+)[^;]*;\s*([0-9A-F]{6})\b', re.M)


def kind(directive):
    if directive.startswith(".byte"):
        return ".byte"
    if directive.startswith(".long"):
        return ".long"
    if directive.startswith((".word", ".short")):
        return ".word"
    if directive.startswith(".fill") or directive.startswith(".zero"):
        return ".fill"
    if directive.startswith(".incbin"):
        return ".incbin"
    if directive.startswith("."):
        return "other directive"
    return "instruction"


def main():
    s = open(SRC, encoding="utf-8").read()
    left = [(0xF80000 + int(o, 16), int(n, 16)) for o, n in INCBIN.findall(s)]
    total_before = sum(n for _a, n, _w in SPANS)
    print("prom_a source: prom_a/wsa1_prom_a.s")
    print("  .incbin remaining: %d span(s), %d bytes"
          % (len(left), sum(n for _a, n in left)))
    for a, n in left:
        print("    0x%06X + %d" % (a, n))
    print()
    print("  the promA lane's four spans, %d bytes before:" % total_before)
    for lo, n, what in SPANS:
        hi = lo + n
        still = sum(m for a, m in left if a < hi and a + m > lo)
        counts = {}
        for m in LINE.finditer(s):
            adr = int(m.group(2), 16)
            if lo <= adr < hi:
                k = kind(m.group(1))
                counts[k] = counts.get(k, 0) + 1
        census = ", ".join("%d %s line(s)" % (v, k)
                           for k, v in sorted(counts.items(), key=lambda kv: -kv[1]))
        print("    0x%06X + %-4d  still .incbin: %d" % (lo, n, still))
        print("        now: %s" % (census or "NOTHING FOUND -- check the address comments"))
        print("        %s" % what)
    return 0


if __name__ == "__main__":
    sys.exit(main())
