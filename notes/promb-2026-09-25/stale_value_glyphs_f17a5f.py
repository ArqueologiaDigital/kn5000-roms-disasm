#!/usr/bin/env python3
r"""prom_b 0xF17A5F-0xF17BFF: a SECOND older-build copy of the value-glyph data, 0x1A401 below the live one.

QUESTION THIS ANSWERS
    stale_dl_tables_f0ed50.py showed that 0xF0ED50-0xF0EFFF is the display-list
    interpreter's data block as an older build placed it (live - 0x23001).  The
    0xF17559 module holds three objects the f17559 layout already tied to the
    same live data by byte identity, without saying why:

      BitTable_F17A5F  (13 bytes)  "last 13 bytes of the 128-byte glyph quantiser
                                    at 0xF31DED"
      PtrTable_F17A6C  (29 words)  "all addresses in prom_a/prom_b; UNREFERENCED"
      Bitmap_F17AE0    (288 bytes) "4 x 72-byte 24x24 glyphs, byte-identical to
                                    0xF31EE1"

    All three sit at their live twin's address - 0x1A401 (0xF31E60, 0xF31E6D,
    0xF31EE1), and the table's 29 words are ValueGlyph_Table's - 0x1A401 -- the
    older build's pointers to ITS 29 glyphs, of which only glyphs 0-3 survive.
    The stretch begins right after DL_MainOutEqualizer_F17A2C (a live object
    of this build) and ends on the 1 KB boundary 0xF17C00.  Entries 4-28 name
    0xF17C00-0xF182C0, which this build filled with display lists; the source
    spelled them as those lists' labels plus offsets (`DL_Mixer + 0x4C`, ...),
    which reads as if the table pointed into them.  They are respelled
    `OldBuild2_ValueGlyph_Bitmaps + 72 k`.  Nothing in prom_a or prom_b names
    0xF17A5F, 0xF17A6C or 0xF17AE0 (32- or 24-bit).

RUN
    python3 notes/promb-2026-09-25/stale_value_glyphs_f17a5f.py            # checks
    python3 notes/promb-2026-09-25/stale_value_glyphs_f17a5f.py --apply    # write the source
    make gate-wsa1
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
SRC = os.path.join(ROOT, "wsa1", "prom_b", "wsa1_prom_b.s")
ROMB = os.path.join(ROOT, "wsa1", "original_ROMs", "wsa1_prom_b.ic13")
ROMA = os.path.join(ROOT, "wsa1", "original_ROMs", "wsa1_prom_a.ic12")
BASE = 0xF00000
DELTA = 0x1A401
QT, GT, G, END = 0xF17A5F, 0xF17A6C, 0xF17AE0, 0xF17C00
FAIL = []


def check(msg, cond):
    print("  %-4s %s" % ("ok" if cond else "FAIL", msg))
    if not cond:
        FAIL.append(msg)


def derive():
    b = open(ROMB, "rb").read()
    ba = open(ROMA, "rb").read()
    at = lambda a, n: b[a - BASE:a - BASE + n]
    u = lambda a: int.from_bytes(at(a, 4), "little")
    check("0xF17A5F + 0x1A401 = 0xF31E60 (ValueGlyph_Quantiser 0xF31DED + 115), and the 13 bytes "
          "match", QT + DELTA == 0xF31DED + 115 and at(QT, 13) == at(QT + DELTA, 13))
    check("0xF17A5E does NOT match 0xF31E5F (the match starts exactly at 0xF17A5F)",
          at(QT - 1, 1) != at(QT - 1 + DELTA, 1))
    check("0xF17A6C: 29 words = ValueGlyph_Table (0xF31E6D) - 0x1A401 each, = 0xF17AE0 + 72 k",
          GT + DELTA == 0xF31E6D and all(u(GT + 4 * k) == u(GT + DELTA + 4 * k) - DELTA == G + 72 * k
                                         for k in range(29)))
    n = 0
    while at(G + n, 1) == at(G + DELTA + n, 1):
        n += 1
    check("0xF17AE0: the first %d bytes = ValueGlyph_Bitmaps (0xF31EE1), glyphs 0-3, ending at "
          "0xF17C00 (1 KB aligned)" % n, n == 288 and G + n == END and END % 0x400 == 0)
    hits = []
    for t in (QT, GT, G):
        for img, r, base in (("prom_b", b, BASE), ("prom_a", ba, 0xF80000)):
            for w in (t.to_bytes(4, "little"), t.to_bytes(3, "little")):
                i = r.find(w)
                while i >= 0:
                    if not (img == "prom_b" and QT <= base + i < END):
                        hits.append((t, img, base + i))
                    i = r.find(w, i + 1)
    check("no 32-bit or 24-bit occurrence of 0xF17A5F / 0xF17A6C / 0xF17AE0 outside the stretch",
          not hits)
    txt = open(SRC, "rb").read().decode("latin-1")
    check("the stretch follows DL_MainOutEqualizer_F17A2C (0xF17A2C-0xF17A5E) in the source",
          "DL_MainOutEqualizer_F17A2C -- display list, 0xF17A2C-0xF17A5E" in txt)
    return txt


ANS_Q = [
    "; ⚠ 2026-09-25: an OLDER BUILD's bytes, not this build's.  This, PtrTable",
    ";   and bitmap below sit at their live twins' addresses - 0x1A401 (the",
    ";   quantiser's 0xF31E60, ValueGlyph_Table 0xF31E6D, ValueGlyph_Bitmaps",
    ";   0xF31EE1): the value-glyph data as an earlier build placed it, cut at",
    ";   0xF17A5F by this build's DL_MainOutEqualizer_F17A2C and ending on the",
    ";   1 KB boundary 0xF17C00.  Same phenomenon, other offset, as",
    ";   OldBuild_DLHandlerTables_Tail at 0xF0ED50 (live - 0x23001).",
    ";   notes/promb-2026-09-25/stale_value_glyphs_f17a5f.py.",
]
ANS_T = [
    "; ⚠ 2026-09-25: ValueGlyph_Table (0xF31E6D) with every word - 0x1A401 -- the",
    ";   older build's pointers to its 29 glyphs.  Only glyphs 0-3 survive (the",
    ";   next object); entries 4-28 name 0xF17C00-0xF182C0, which this build",
    ";   filled with display lists, so they are spelled",
    ";   `OldBuild2_ValueGlyph_Bitmaps + 72 k`, not as offsets into those lists.",
]
ANS_G = [
    "; ⚠ 2026-09-25: the older build's glyphs 0-3 (see",
    ";   OldBuild2_ValueGlyph_QuantiserTail above); 24 x 24 dials stored",
    ";   column-major, 3 columns x 24 bytes.",
]


def apply(txt):
    L = txt.split("\n")

    def after_evidence(label, lines):
        i = [k for k, t in enumerate(L) if t.startswith(label + ":")]
        assert len(i) == 1, label
        k = i[0] - 1
        assert L[k].startswith("; ----"), L[k]
        L[k:k] = [x.encode("utf-8").decode("latin-1") for x in lines]

    after_evidence("BitTable_F17A5F", ANS_Q)
    after_evidence("PtrTable_F17A6C", ANS_T)
    after_evidence("Bitmap_F17AE0", ANS_G)
    p = [k for k, t in enumerate(L) if t.startswith("PtrTable_F17A6C:")][0]
    for j in range(29):
        m = re.match(r'^\t\.long \S+(?: \+ 0x[0-9A-F]+)?( +; F17A[6-9A-D][0-9A-F]  \[%d\] .*)$' % j,
                     L[p + 1 + j])
        assert m, L[p + 1 + j]
        L[p + 1 + j] = "\t.long OldBuild2_ValueGlyph_Bitmaps%s%s" % (
            "" if j == 0 else " + 0x%X" % (72 * j), m.group(1))
    txt = "\n".join(L)
    for old, new in (("BitTable_F17A5F", "OldBuild2_ValueGlyph_QuantiserTail"),
                     ("PtrTable_F17A6C", "OldBuild2_ValueGlyph_Table"),
                     ("Bitmap_F17AE0", "OldBuild2_ValueGlyph_Bitmaps")):
        txt = re.sub(r'\b%s\b' % old, new, txt)
    open(SRC, "wb").write(txt.encode("latin-1"))
    print("wrote", SRC)


def main():
    txt = derive()
    if FAIL:
        print("\nVERDICT: FAIL (%d)" % len(FAIL))
        return 1
    if "--apply" in sys.argv:
        apply(txt)
    print("\nVERDICT: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
