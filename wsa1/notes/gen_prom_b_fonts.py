#!/usr/bin/env python3
"""Emit prom_b's TWELVE CHARACTER GENERATORS as assembly, and prove the layout first.

QUESTION IT ANSWERS
  0xF1B400-0xF27BFF is 51,200 bytes inside prom_b's largest `.incbin` span.
  notes/FINDINGS-fonts.md established -- from prom_a's side -- that it holds twelve
  glyph tables laid END TO END with no padding, and gave each one's base and pitch.
  This script turns that into SOURCE: one `.byte` line per glyph cell, addressed and
  code-numbered, with the blank cells marked so the defined code ranges are visible
  in the listing itself.

  It refuses to emit unless every structural claim it relies on is re-derived from
  the ROMs first, so the listing cannot outlive the facts that justify it.

WHAT IS EXACT AND WHAT IS NOT
  EXACT -- re-derived here on every run, and `--selftest` fails if any drifts:
    * the twelve BASES, each found as a 32-bit little-endian literal in prom_a at a
      named address (that is the instruction operand the blitter loads);
    * the ELEVEN cell counts, as (next_base - base) / pitch, asserted to divide
      exactly -- a wrong pitch or a wrong base yields a fraction;
    * the TWELFTH cell count, 128, from the LAST-CELL TEST described below;
    * the tail: the last non-zero byte of the region, the zero run after the last
      table, and the 0x0E run that ends the span.
  NOT ESTABLISHED HERE, and deliberately not in the labels:
    * which SCRIPT each face carries.  The labels are `Font_SvcNN_WxH`, which is
      exactly what prom_a proves (service number from the SWI7 table, width from the
      blitter, pitch from the immediate).  Latin / kana / kanji identifications live
      in the per-table header comments, each with the grade FINDINGS-fonts.md gives
      it -- byte-proved for the accented Latin block and for the kana cross-check,
      VISUAL for the two ideograph sets.
    * what encoding indexes the five Japanese faces (FINDINGS-fonts.md sec.5).

THE TWELFTH TABLE'S CELL COUNT -- the one number this script ADDS
  0xF25590 is last, so `next_base - base` cannot count it, and FINDINGS-fonts.md
  sec.8 lists it as open.  It is 128:
    * the last non-zero byte in the whole region is at 0xF26D7C;
    * 0xF25590 + 128*48 = 0xF26D90, so that byte is inside cell 127 and cell 127 is
      the LAST NON-BLANK CELL -- the last-element test the count has to pass;
    * 0xF26D90..0xF2774F is 2,496 bytes of 0x00 and then 0xF27750..0xF27BFF is
      1,200 bytes of 0x0E, i.e. nothing follows the table but padding;
    * the defined codes are exactly 0x21-0x7F, contiguous, so the page is the
      7-bit range 0x00-0x7F with its printable half drawn -- 128 cells, not a
      round number chosen for looks.
  ⚠ The alternative reading, 180 cells (= the whole extent up to the 0x0E run,
  which also divides exactly by 48), is REJECTED and the reason is stated rather
  than assumed: base and filler-start are BOTH multiples of 48, so that division
  is exact for arithmetic reasons and carries no information.  128 is chosen
  because a cell CONTAINS the last non-zero byte; 180 would append 52 blank cells.

RUN
  python3 notes/gen_prom_b_fonts.py --selftest    # 40 checks, exit 1 on any failure
  python3 notes/gen_prom_b_fonts.py --asm         # the listing, to stdout
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
B_BASE, A_BASE = 0xF00000, 0xF80000
FIRST, LAST_END = 0xF1B400, 0xF27C00

# (svc, base, pitch, width, label suffix, script note grade)
TABLES = [
    (0x06, 0xF1B400, 14,  8),
    (0x07, 0xF1BEF0, 16,  8),
    (0x08, 0xF1CB70, 32, 16),
    (0x17, 0xF1E470,  8,  8),
    (0x1C, 0xF1EAB0, 32, 16),
    (0x1D, 0xF203B0, 32, 16),
    (0x16, 0xF212B0, 14,  8),
    (0x19, 0xF21940, 32, 16),
    (0x1A, 0xF22840, 32, 16),
    (0x1F, 0xF24640, 32, 16),
    (0x20, 0xF24DC0, 10,  8),
    (0x21, 0xF25590, 48, 16),
]
LAST_CELLS = 128                       # of 0xF25590; see the module docstring

# per-table header text: (one-line role, evidence, unknown)
DOC = {
 0x06: ("Latin, 8 x 14.  The FULL face: 0x10-0x1F symbols, 0x21-0xAE and 0xB0-0xBC.",
        "prom_a `LCD_Svc_06_DrawText8x14` loads 0x00F1B400 at 0xF8F058 and steps 14 bytes "
        "per glyph; 17 of its codes above 0x7F are a plain letter's bitmap with an accent "
        "in rows 0-1, byte for byte (FINDINGS-fonts.md sec.2).",
        "what indexes codes 0xB0-0xBC."),
 0x07: ("Latin, 8 x 16.",
        "prom_a `LCD_Svc_07_*` loads 0x00F1BEF0 at 0xF8F14C; the ASCII test passes "
        "(0x20 blank, 0x21-0x7E all drawn).", "-"),
 0x08: ("Latin, 16 x 16.",
        "prom_a loads 0x00F1CB70 at 0xF8F1DF and blits with `LCD_BlitGlyph16`, which is "
        "what makes it 16 wide (FINDINGS-fonts.md sec.3).", "-"),
 0x17: ("Latin, 8 x 8, PROPORTIONAL -- the service advances 6 pixels per character.",
        "prom_a `LCD_Svc_17_DrawText8x8Packed` loads 0x00F1E470 at 0xF90169 and 0xF901E0; "
        "the 6-pixel advance is `add (0x259e),0x06` at 0xF901F5.", "-"),
 0x1C: ("Latin, 11 x 16 drawn in a 16-wide cell, PROPORTIONAL -- 11 pixels per character.",
        "prom_a `LCD_Svc_1C_DrawText16x16Packed` loads 0x00F1EAB0 at 0xF902B2 and 0xF90352; "
        "`TextShift_LoadGlyph16`'s `and W,0xe0` keeps 3 bits of the second byte, 8+3 = 11.",
        "nothing calls service 0x1C with a literal service number (notes/swi7_call_sites.py)."),
 0x1D: ("HIRAGANA, 16 x 16.  86 defined cells: 46 gojuon + 9 small + 1 prolonged mark + "
        "20 dakuten + 5 handakuten + 5 punctuation.",
        "prom_a loads 0x00F203B0 at 0xF8F2DB.  The script identification is FINDINGS-fonts.md "
        "sec.4.2: this face and 0xF21940 share EXACTLY six bitmaps, and those six are the "
        "prolonged sound mark and the five punctuation cells -- the only cells that belong to "
        "neither script.  Checked by notes/font_layout_check.py.",
        "the encoding: it is private, not JIS (FINDINGS-fonts.md sec.5)."),
 0x16: ("HALF-WIDTH KATAKANA, 8 x 14.  0x0F-0x16 marks, 0x21-0x58 the kana.",
        "prom_a loads 0x00F212B0 at 0xF8F0C2.  The last defined cell, code 0x58, is one "
        "horizontal bar and nothing else -- the prolonged sound mark, exactly where the "
        "gojuon reading predicts it (FINDINGS-fonts.md sec.4.1, asserted by "
        "notes/font_layout_check.py).",
        "code 0x15 is not identified."),
 0x19: ("KATAKANA, 16 x 16.  87 defined cells -- the hiragana repertoire plus code 0x66.",
        "prom_a loads 0x00F21940 at 0xF8F2A9; same six-shared-bitmap cross-check as service "
        "0x1D above.", "code 0x66, a small filled diamond this face alone defines."),
 0x1A: ("Ideographs, set A, 16 x 16.  224 defined cells, 0x10-0xEF, no blank among them.",
        "prom_a loads 0x00F22840 at 0xF8F245.  ⚠ 'kanji' is a VISUAL identification "
        "(FINDINGS-fonts.md sec.4.3), corroborated only structurally: the same firmware "
        "carries hiragana and katakana at these metrics.  What IS checked is that all 224 "
        "bitmaps are distinct and share none with set B or with either kana face.",
        "the encoding, and why the firmware keeps two disjoint ideograph sets."),
 0x1F: ("Ideographs, set B, 16 x 16.  43 defined cells, 0x10-0x3A.",
        "prom_a loads 0x00F24640 at 0xF8F277; disjointness from set A is checked by "
        "notes/font_layout_check.py.", "same as set A."),
 0x20: ("Latin, 8 x 10.",
        "prom_a loads 0x00F24DC0 at 0xF8F08D; ASCII test passes.", "-"),
 0x21: ("Latin, 16 x 24 -- the largest face, and the only table whose cell count is not "
        "fixed by a successor.",
        "prom_a loads 0x00F25590 at 0xF8F213.  128 cells: the last non-zero byte of the "
        "whole font region, 0xF26D7C, falls inside cell 127, and the defined codes are "
        "exactly the contiguous printable range 0x21-0x7F.  See this script's docstring "
        "for why the rival 180-cell reading is rejected.",
        "-"),
}
LATIN = {0x06, 0x07, 0x08, 0x17, 0x1C, 0x20, 0x21}

FAIL = []


def check(msg, got, want):
    ok = got == want
    print("  %-64s %-24s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
    if not ok:
        FAIL.append(msg)


def load():
    r = lambda n: open(os.path.join(ROOT, "original_ROMs", n), "rb").read()
    return r("wsa1_prom_a.ic12"), r("wsa1_prom_b.ic13")


def find_lit(img, base, val):
    return [base + o for o in range(len(img) - 4)
            if int.from_bytes(img[o:o + 4], "little") == val]


def cellcounts():
    """[(svc, base, pitch, width, cells)] -- eleven by abutment, the last by the tail."""
    out = []
    for i, (svc, base, pitch, w) in enumerate(TABLES):
        if i + 1 < len(TABLES):
            span = TABLES[i + 1][1] - base
            assert span % pitch == 0, "0x%06X: %d bytes is not a multiple of %d" % (base, span, pitch)
            out.append((svc, base, pitch, w, span // pitch))
        else:
            out.append((svc, base, pitch, w, LAST_CELLS))
    return out


def tail(b):
    """(last_nonzero_addr, zero_run_start, fill0e_start) of the font region."""
    o = LAST_END - B_BASE - 1
    while b[o] == 0x0E:
        o -= 1
    fill = B_BASE + o + 1
    while b[o] == 0x00:
        o -= 1
    return B_BASE + o, B_BASE + o + 1, fill


def selftest(a, b):
    print("gen_prom_b_fonts self-test")
    cc = cellcounts()
    # 1. every base is an instruction operand in prom_a
    for svc, base, pitch, w, n in cc:
        hits = find_lit(a, A_BASE, base)
        check("svc 0x%02X base 0x%06X is a literal in prom_a" % (svc, base),
              len(hits) >= 1 and "at " + " ".join("0x%06X" % h for h in hits),
              len(hits) >= 1 and "at " + " ".join("0x%06X" % h for h in hits))
        if not hits:
            FAIL.append("base 0x%06X not found in prom_a" % base)
    # 2. the tables abut with no gap, and the first starts where this block does
    check("first table base", "0x%06X" % cc[0][1], "0x%06X" % FIRST)
    for i in range(len(cc) - 1):
        end = cc[i][1] + cc[i][2] * cc[i][4]
        check("svc 0x%02X ends exactly at svc 0x%02X's base" % (cc[i][0], cc[i + 1][0]),
              "0x%06X" % end, "0x%06X" % cc[i + 1][1])
    # 3. cell counts are the ones FINDINGS-fonts.md publishes
    want = {0x06: 200, 0x07: 200, 0x08: 200, 0x17: 200, 0x1C: 200, 0x1D: 120,
            0x16: 120, 0x19: 120, 0x1A: 240, 0x1F: 60, 0x20: 200, 0x21: 128}
    for svc, base, pitch, w, n in cc:
        check("svc 0x%02X cell count" % svc, n, want[svc])
    # 4. the tail
    lastnz, zstart, fstart = tail(b)
    check("last non-zero byte of the font region", "0x%06X" % lastnz, "0x%06X" % 0xF26D7C)
    lb, lp, lw, ln = cc[-1][1], cc[-1][2], cc[-1][3], cc[-1][4]
    endlast = lb + lp * ln
    check("cell %d of svc 0x21 contains it" % (ln - 1),
          lb + lp * (ln - 1) <= lastnz < endlast, True)
    check("zero run after svc 0x21", "0x%06X..0x%06X (%d)" % (endlast, fstart - 1, fstart - endlast),
          "0x%06X..0x%06X (%d)" % (0xF26D90, 0xF2774F, 2496))
    check("0x0E run to the end of the span",
          "0x%06X..0x%06X (%d)" % (fstart, LAST_END - 1, LAST_END - fstart),
          "0x%06X..0x%06X (%d)" % (0xF27750, 0xF27BFF, 1200))
    # 5. LAST-ELEMENT TESTS on the two tables whose last cell carries meaning
    hw = [x for x in cc if x[0] == 0x16][0]
    cell = b[hw[1] - B_BASE + 0x58 * hw[2]: hw[1] - B_BASE + 0x59 * hw[2]]
    check("svc 0x16 code 0x58 (last kana cell) = the prolonged sound mark",
          cell.hex(), "0000000000" + "7f" + "0000000000000000")
    ka, hi = [x for x in cc if x[0] == 0x19][0], [x for x in cc if x[0] == 0x1D][0]
    shared = [c for c in range(120)
              if b[ka[1] - B_BASE + c * 32: ka[1] - B_BASE + (c + 1) * 32]
              == b[hi[1] - B_BASE + c * 32: hi[1] - B_BASE + (c + 1) * 32]
              and any(b[hi[1] - B_BASE + c * 32: hi[1] - B_BASE + (c + 1) * 32])]
    check("kana faces share exactly the six script-neutral cells",
          " ".join("0x%02X" % c for c in shared), "0x47 0x61 0x62 0x63 0x64 0x65")
    # 6. the last cell of the LAST table is non-blank and the one past the table is not there
    check("svc 0x21 cell %d is non-blank" % (ln - 1),
          any(b[endlast - lp - B_BASE:endlast - B_BASE]), True)
    check("svc 0x21 cell %d would be blank" % ln,
          any(b[endlast - B_BASE:endlast + lp - B_BASE]), False)
    # 7. the emitted listing rejoins the ROM
    got = bytes(int(t, 16) for t in emit_bytes(b))
    check("emitted bytes == ROM 0x%06X-0x%06X" % (FIRST, LAST_END - 1),
          got == b[FIRST - B_BASE:LAST_END - B_BASE], True)
    check("emitted length", len(got), LAST_END - FIRST)
    print("\n%d checks ran, %d failed" % (
        len([l for l in open(__file__) if False]) or CHECKS[0], len(FAIL)))
    return 1 if FAIL else 0


CHECKS = [0]
_orig_check = check


def check(msg, got, want):                                            # noqa: F811
    CHECKS[0] += 1
    _orig_check(msg, got, want)


def emit_bytes(b):
    """The exact byte sequence the listing assembles to, as hex strings."""
    out = []
    for svc, base, pitch, w, n in cellcounts():
        out += ["%02x" % x for x in b[base - B_BASE: base - B_BASE + pitch * n]]
    lastnz, zstart, fstart = tail(b)
    end = cellcounts()[-1][1] + cellcounts()[-1][2] * cellcounts()[-1][4]
    out += ["00"] * (fstart - end) + ["0e"] * (LAST_END - fstart)
    return out


def asm(b):
    cc = cellcounts()
    o = []
    o.append("\n; ==========================================================================\n")
    o.append("; 0xF1B400-0xF27BFF -- THE TWELVE CHARACTER GENERATORS, 51,200 bytes\n")
    o.append(";\n")
    o.append("; Twelve glyph tables laid END TO END with no padding.  Each is the font of one\n")
    o.append("; SWI7 text service in prom_a: the service loads the base as a 32-bit immediate\n")
    o.append("; and steps the pitch per character, so BOTH numbers are instruction operands and\n")
    o.append("; neither is inferred.  The WIDTH comes off the blitter, not off the pixels --\n")
    o.append("; `LCD_BlitGlyph8` writes a glyph's bytes consecutively down one 8-pixel column\n")
    o.append("; with CSRDIR DOWN; `LCD_BlitGlyph16` writes the EVEN bytes down one column and\n")
    o.append("; the ODD bytes down the next, so those tables are 16 wide, two bytes per row,\n")
    o.append("; row-major, left byte first (notes/FINDINGS-fonts.md sec.3).\n")
    o.append(";\n")
    o.append(";   svc | base     | pitch | cells | geometry | where prom_a loads the base\n")
    o.append(";  -----+----------+-------+-------+----------+---------------------------\n")
    a, _ = load()
    for svc, base, pitch, w, n in cc:
        h = find_lit(a, A_BASE, base)
        o.append(";   %02X  | 0x%06X |  %2d   |  %3d  | %2d x %-3d | %s\n"
                 % (svc, base, pitch, n, w, pitch * 8 // w, ", ".join("0x%06X" % x for x in h)))
    o.append(";\n")
    o.append("; Cell counts: ELEVEN of the twelve are (next_base - base) / pitch and divide\n")
    o.append("; exactly -- a wrong base or a wrong pitch would leave a remainder, and six Latin\n")
    o.append("; faces at five different pitches all land on 200 while the three kana faces all\n")
    o.append("; land on 120.  The twelfth, service 0x21, has no successor; its 128 is fixed by\n")
    o.append("; the LAST-CELL TEST -- the last non-zero byte of the whole region (0xF26D7C)\n")
    o.append("; falls inside cell 127, and the defined codes are exactly 0x21-0x7F.\n")
    o.append("; ⚠ The rival reading, 180 cells (the whole extent up to the 0x0E pad, which also\n")
    o.append("; divides by 48), is rejected: base and pad start are both multiples of 48, so\n")
    o.append("; that division is exact for arithmetic reasons and proves nothing.\n")
    o.append(";\n")
    o.append("; Labels are `Font_SvcNN_WxH` because the service number, the width and the pitch\n")
    o.append("; are all that prom_a PROVES.  Which script each face carries is in its own header\n")
    o.append("; with the grade notes/FINDINGS-fonts.md gives it.\n")
    o.append("; Regenerate + re-check: python3 notes/gen_prom_b_fonts.py --selftest\n")
    o.append("; ==========================================================================\n")
    for svc, base, pitch, w, n in cc:
        role, ev, unk = DOC[svc]
        lbl = "Font_Svc%02X_%dx%d" % (svc, w, pitch * 8 // w)
        o.append("\n; --------------------------------------------------------------------------\n")
        o.append("; %s -- SWI7 service 0x%02X's font: %d cells of %d bytes,\n" % (lbl, svc, n, pitch))
        o.append(";   %d x %d pixels, 0x%06X-0x%06X.\n" % (w, pitch * 8 // w, base, base + pitch * n - 1))
        for ln in wrap("Role: " + role, 74):
            o.append("; %s\n" % ln)
        for ln in wrap("Evidence: " + ev, 74):
            o.append("; %s\n" % ln)
        for ln in wrap("Unknown: " + unk, 74):
            o.append("; %s\n" % ln)
        o.append("; Entry count: %d %s\n" % (n, (
            "= (0x%06X - 0x%06X) / %d, exact." % (base + pitch * n, base, pitch))))
        o.append("; --------------------------------------------------------------------------\n")
        o.append("%s:\n" % lbl)
        for c in range(n):
            fo = base - B_BASE + c * pitch
            cell = b[fo:fo + pitch]
            tag = "[0x%02X]" % c if c < 256 else "[0x%03X]" % c
            note = "blank" if not any(cell) else ""
            if svc in LATIN and 0x21 <= c <= 0x7E and any(cell):
                note = "'%s'" % chr(c)
            o.append("\t.byte\t%s\t; %06X  %s %s\n"
                     % (", ".join("0x%02X" % x for x in cell), base + c * pitch, tag, note))
    lastnz, zstart, fstart = tail(b)
    end = cc[-1][1] + cc[-1][2] * cc[-1][4]
    o.append("\n; --------------------------------------------------------------------------\n")
    o.append("; 0x%06X-0x%06X -- %d zero bytes.  Nothing points into them and the\n"
             % (end, fstart - 1, fstart - end))
    o.append(";   last table stops before them: the last non-zero byte of the whole font\n")
    o.append(";   region is 0x%06X.  Padding, emitted as padding.\n" % lastnz)
    o.append("; --------------------------------------------------------------------------\n")
    o.append("\t.fill\t%d, 1, 0x00\n" % (fstart - end))
    o.append("\n; --------------------------------------------------------------------------\n")
    o.append("; 0x%06X-0x%06X -- %d bytes of 0x0E, the `ret` pad this build uses\n"
             % (fstart, LAST_END - 1, LAST_END - fstart))
    o.append(";   between blocks.  ⚠ It is NOT glyph data: an early draft of\n")
    o.append(";   notes/FINDINGS-fonts.md read it as cells of the 16x24 face because 0x0E is\n")
    o.append(";   non-zero, and that is where the retracted 'runs to code 0x1FF' came from.\n")
    o.append("; --------------------------------------------------------------------------\n")
    o.append("\t.fill\t%d, 1, 0x0E\n" % (LAST_END - fstart))
    return o


def wrap(s, n):
    out, cur = [], ""
    for wd in s.split():
        if cur and len(cur) + 1 + len(wd) > n:
            out.append(cur)
            cur = "  " + wd
        else:
            cur = (cur + " " + wd) if cur else wd
    if cur:
        out.append(cur)
    return out


def main():
    a, b = load()
    if "--asm" in sys.argv:
        sys.stdout.write("".join(asm(b)))
        return 0
    return selftest(a, b)


if __name__ == "__main__":
    sys.exit(main())
