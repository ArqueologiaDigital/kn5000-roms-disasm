#!/usr/bin/env python3
"""Re-derive, from the ROM bytes alone, every number FINDINGS-fonts.md quotes
about the WSA1's glyph tables.

QUESTION IT ANSWERS: "how many glyph tables are there, how many CELLS does each
one have, and what is in them?"  The first version of that note answered the
first question with 'ten' and the third with 'five are ASCII, five resist', and
both answers were artefacts of the window it looked through:

  * it counted only the ten BYTE-ALIGNED text services and missed the two
    proportional ones, SWI7 0x17 (font 0xF1E470) and 0x1C (font 0xF1EAB0).
    Twelve tables, not ten.
  * it tested codes 0x20-0x7E only.  Every table also defines codes BELOW 0x20
    and most define codes above 0x7E, so the test saw the middle third of a
    code page and called the rest a failure.

★ THE LENGTHS ARE ARITHMETIC, NOT INSPECTION.  The twelve tables are laid end
to end in prom_b with no padding between them: for all eleven that have a
successor, (next_base - base) is an exact multiple of the table's own glyph
pitch.  That quotient IS the cell count, and it is proved without looking at a
single pixel or guessing where zero padding starts.  Six Latin faces come out
at exactly 200 cells each despite having five different pitches (8, 10, 14, 16,
32 bytes per glyph); the three kana faces at exactly 120; the big kanji face at
240; the small one at 60.

    python3 notes/font_layout_check.py        # exits non-zero on any failure
    python3 notes/font_layout_check.py -v     # print every check

Companion viewers: notes/render_font.py (one glyph), notes/font_sheet.py (a
contact sheet, and `--extent` for the non-blank code blocks of each table).
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
A = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
B = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
FAILS = []
RAN = []
VERBOSE = "-v" in sys.argv


def check(name, cond, detail=""):
    RAN.append(name)
    if VERBOSE or not cond:
        print("%-4s %s%s" % ("ok" if cond else "FAIL", name,
                             ("  -- " + detail) if detail and not cond else ""))
    if not cond:
        FAILS.append(name)


def gl(base, pitch, code):
    o = base - 0xF00000 + code * pitch
    return B[o:o + pitch]


def blank(base, pitch, code):
    return not any(gl(base, pitch, code))


# ---------------------------------------------------------------------------
# 1. The twelve tables, and the fact that each service really loads that base.
#
# (service, prom_a routine, font base, bytes per glyph, pixel width).  The first
# ten are the byte-aligned text services; the last two are the proportional
# ones, whose bases are loaded into XIX rather than XIY and so were missed by
# the census that produced the "ten character generators" headline.
# ---------------------------------------------------------------------------
TABLES = [
    (0x06, 0xF8F039, 0xF1B400, 14, 8),
    (0x07, 0xF8F130, 0xF1BEF0, 16, 8),
    (0x08, 0xF8F1C3, 0xF1CB70, 32, 16),
    (0x17, 0xF90118, 0xF1E470, 8, 8),
    (0x1C, 0xF9025E, 0xF1EAB0, 32, 16),
    (0x1D, 0xF8F2BF, 0xF203B0, 32, 16),
    (0x16, 0xF8F0A3, 0xF212B0, 14, 8),
    (0x19, 0xF8F28D, 0xF21940, 32, 16),
    (0x1A, 0xF8F229, 0xF22840, 32, 16),
    (0x1F, 0xF8F25B, 0xF24640, 32, 16),
    (0x20, 0xF8F06E, 0xF24DC0, 10, 8),
    (0x21, 0xF8F1F7, 0xF25590, 48, 16),
]
check("twelve glyph tables, not ten", len(TABLES) == 12)
# every live SWI7 target, so a routine's extent can be bounded by the next one
TABLES_ALL = [(i, int.from_bytes(A[0xF8E9C6 + 4 * i - 0xF80000:][:4], "little"))
              for i in range(64)]
TABLES_ALL = [t for t in TABLES_ALL if t[1] != 0xF8EAC6]
for svc, addr, base, pitch, w in TABLES:
    # SWI7_ServiceTable slot -> the routine
    slot = int.from_bytes(A[0xF8E9C6 + 4 * svc - 0xF80000:][:4], "little")
    check("svc 0x%02X: SWI7 slot points at 0x%06X" % (svc, addr), slot == addr,
          "slot holds 0x%06X" % slot)
    # the routine loads the base as a 32-bit immediate (`ld XIY,n` = 0x45,
    # `ld XIX,n` = 0x44); accept either register.
    imm = bytes([base & 0xFF, (base >> 8) & 0xFF, (base >> 16) & 0xFF, 0x00])
    # The window is the routine itself: from its entry to the next SWI7 target
    # above it, so a base found here cannot have been borrowed from a
    # neighbouring routine.  The two proportional services load their base into
    # XIX (0x44) about 0x50 bytes in, which is why a fixed 0x40-byte window --
    # the one that produced the "ten character generators" headline -- missed
    # them.
    ends = sorted(t[1] for t in TABLES_ALL if t[1] > addr)
    stop = ends[0] if ends else addr + 0x200
    blob = A[addr - 0xF80000: stop - 0xF80000]
    check("svc 0x%02X: its body loads 0x%06X as an immediate" % (svc, base),
          bytes([0x45]) + imm in blob or bytes([0x44]) + imm in blob)

# ---------------------------------------------------------------------------
# 2. ★ The cell counts, by abutment.
# ---------------------------------------------------------------------------
order = sorted(TABLES, key=lambda t: t[2])
CELLS = {}
for i, (svc, addr, base, pitch, w) in enumerate(order):
    if i + 1 == len(order):
        break
    nxt = order[i + 1][2]
    delta = nxt - base
    check("0x%06X (pitch %d): abuts 0x%06X exactly" % (base, pitch, nxt),
          delta % pitch == 0, "delta %d is not a multiple of %d" % (delta, pitch))
    CELLS[base] = delta // pitch
LATIN = [0xF1B400, 0xF1BEF0, 0xF1CB70, 0xF1E470, 0xF1EAB0, 0xF24DC0]
KANA = [0xF203B0, 0xF212B0, 0xF21940]
check("the six Latin faces all have exactly 200 cells",
      all(CELLS[b] == 200 for b in LATIN),
      str({hex(b): CELLS[b] for b in LATIN}))
check("the six Latin faces use five different pitches",
      len({p for _, _, b, p, _ in TABLES if b in LATIN}) == 5)
check("the three kana faces all have exactly 120 cells",
      all(CELLS[b] == 120 for b in KANA),
      str({hex(b): CELLS[b] for b in KANA}))
check("the big kanji face 0xF22840 has exactly 240 cells", CELLS[0xF22840] == 240)
check("the small kanji face 0xF24640 has exactly 60 cells", CELLS[0xF24640] == 60)
check("0xF25590 is last and its cell count is NOT established this way",
      0xF25590 not in CELLS)

# ---------------------------------------------------------------------------
# 3. The kana pair: 0xF203B0 hiragana against 0xF21940 katakana.
#
# The two tables share a code space.  Six codes hold the SAME bitmap in both --
# the characters that are not hiragana or katakana at all -- and every other
# code they both define differs.  Those six codes are predicted, not observed:
# counting the repertoire gives 46 gojuon + 9 small + 1 chouonpu + 20 dakuten +
# 5 handakuten + 5 punctuation = 86, which puts the chouonpu at 0x10+46+9 =
# 0x47 and the punctuation at 0x61-0x65.  The script finds the six by comparing
# bitmaps, knowing nothing about kana, and asserts it got exactly that set.
# ---------------------------------------------------------------------------
HIRA, KATA = 0xF203B0, 0xF21940
same = [c for c in range(0, 120) if gl(HIRA, 32, c) == gl(KATA, 32, c)
        and not blank(HIRA, 32, c)]
check("hiragana/katakana: exactly 6 codes hold the same non-blank bitmap",
      len(same) == 6, str([hex(c) for c in same]))
check("hiragana/katakana: and they are 0x47 and 0x61-0x65",
      same == [0x47, 0x61, 0x62, 0x63, 0x64, 0x65], str([hex(c) for c in same]))
hn = [c for c in range(120) if not blank(HIRA, 32, c)]
kn = [c for c in range(120) if not blank(KATA, 32, c)]
# ⚠ This used to read `check("46+9+1+20+5+5 = 86", 46+9+1+20+5+5 == 86)` -- a
# comparison of two literals, which cannot fail and inflated the tally by one.
# The measurable half of that sentence is that the ROM defines as many cells as
# the repertoire predicts, so THAT is what is checked; the decomposition itself
# is a claim about kana and stays a comment.
check("hiragana: the ROM defines exactly 46+9+1+20+5+5 = 86 cells",
      len(hn) == 46 + 9 + 1 + 20 + 5 + 5, "%d" % len(hn))
check("hiragana defines 86 cells, 0x10..0x65",
      len(hn) == 86 and hn[0] == 0x10 and hn[-1] == 0x65,
      "%d, 0x%02X..0x%02X" % (len(hn), hn[0], hn[-1]))
check("katakana defines 87 cells, 0x10..0x66 -- one more than hiragana",
      len(kn) == 87 and kn[0] == 0x10 and kn[-1] == 0x66,
      "%d, 0x%02X..0x%02X" % (len(kn), kn[0], kn[-1]))
check("hiragana and katakana are contiguous over their defined range",
      hn == list(range(0x10, 0x66)) and kn == list(range(0x10, 0x67)))
check("the extra katakana cell 0x66 is blank in the hiragana face",
      blank(HIRA, 32, 0x66))
check("outside those six, no hiragana bitmap equals ANY katakana bitmap",
      len({gl(HIRA, 32, c) for c in hn} & {gl(KATA, 32, c) for c in kn}) == 6)

# ---------------------------------------------------------------------------
# 4. The half-width katakana face, 0xF212B0.
#
# Two blocks: 8 marks and punctuation at 0x0F-0x16, then 56 kana at 0x21-0x58.
# 56 = 46 gojuon + 9 small + 1 chouonpu -- the same repertoire as the 16x16
# katakana face MINUS its 25 dakuten/handakuten forms, which a half-width face
# does not carry because the two marks are separate characters (0x0F, 0x10).
# ---------------------------------------------------------------------------
HK = 0xF212B0
hk = [c for c in range(120) if not blank(HK, 14, c)]
blocks = []
for c in hk:
    if blocks and c == blocks[-1][1] + 1:
        blocks[-1][1] = c
    else:
        blocks.append([c, c])
check("half-width katakana: exactly two blocks", len(blocks) == 2, str(blocks))
check("half-width katakana: 0x0F-0x16 (8 marks) and 0x21-0x58 (56 kana)",
      blocks == [[0x0F, 0x16], [0x21, 0x58]], str(blocks))
# ⚠ This used to read `check("46+9+1 = 56", 46+9+1 == 56)` -- literals again.
# What the ROM can settle is the SIZE OF THE MEASURED BLOCK, so that is the
# check now.
check("half-width katakana: the kana block really holds 46+9+1 = 56 cells",
      blocks[1][1] - blocks[1][0] + 1 == 46 + 9 + 1,
      "%d" % (blocks[1][1] - blocks[1][0] + 1))

# ---------------------------------------------------------------------------
# 5. LAST-ELEMENT tests.  Each identification is checked at the END of its
# range, where an off-by-one or a misread order shows up, not at the start.
# ---------------------------------------------------------------------------
# The last half-width kana, 0x58, is the chouonpu -- a single horizontal bar and
# nothing else.  That is the strongest single check in this file: it is the last
# cell of the block, and the gojuon reading predicts a bar there.
g = gl(HK, 14, 0x58)
check("last half-width kana 0x58 is ONE row of pixels (the chouonpu bar)",
      sum(1 for x in g if x) == 1 and g[5] == 0x7F, g.hex(" "))
# The last shared kana-face code, 0x65, must be identical in both faces.
check("last shared kana code 0x65 is identical in both 16x16 faces",
      gl(HIRA, 32, 0x65) == gl(KATA, 32, 0x65) and not blank(HIRA, 32, 0x65))
# The big kanji face's last cell, and the abutment that proves there is no more.
check("kanji 0xF22840: code 0xEF is defined and 0xF0 is where 0xF24640 starts",
      not blank(0xF22840, 32, 0xEF) and 0xF22840 + 0xF0 * 32 == 0xF24640)
check("kanji 0xF22840: all 224 cells 0x10..0xEF are defined, none blank",
      all(not blank(0xF22840, 32, c) for c in range(0x10, 0xF0)))
# The small kanji face's last cell, and its one blank tail cell.
check("kanji 0xF24640: 0x3A defined, 0x3B blank, and 0x3C*32 lands on 0xF24DC0",
      not blank(0xF24640, 32, 0x3A) and blank(0xF24640, 32, 0x3B)
      and 0xF24640 + 0x3C * 32 == 0xF24DC0)
k43 = [c for c in range(60) if not blank(0xF24640, 32, c)]
check("kanji 0xF24640: 43 cells, contiguous 0x10..0x3A",
      k43 == list(range(0x10, 0x3B)), "%d cells" % len(k43))

# ---------------------------------------------------------------------------
# 6. Codes 0x10-0x1F are NOT control codes.  Three of the six Latin faces
# define all sixteen of them; the other three define none.
# ---------------------------------------------------------------------------
pitch_of = {b: p for _, _, b, p, _ in TABLES}
nsym = {b: sum(1 for c in range(0x10, 0x20) if not blank(b, pitch_of[b], c))
        for b in LATIN}
check("four Latin faces define ALL sixteen of 0x10-0x1F",
      sorted(b for b in LATIN if nsym[b] == 16)
      == [0xF1B400, 0xF1BEF0, 0xF1CB70, 0xF1EAB0],
      str({hex(b): n for b, n in nsym.items()}))
check("the 8x8 proportional face defines twelve of the sixteen",
      nsym[0xF1E470] == 12, str(nsym[0xF1E470]))
check("the 8x8 face is missing exactly 0x1B-0x1E",
      [c for c in range(0x10, 0x20) if blank(0xF1E470, 8, c)] == [0x1B, 0x1C, 0x1D, 0x1E])
check("the 8x10 face defines NONE of 0x10-0x1F", nsym[0xF24DC0] == 0)
withsym = [b for b in LATIN if nsym[b] == 16]
check("every Latin face that has 0x10-0x1F also has 0x20 blank (the space)",
      all(blank(b, pitch_of[b], 0x20) for b in withsym))
# and the Latin faces carry codes above 0x7E, which is what the 0x20-0x7E
# window hid: the accented forms.
check("0xF1B400 defines codes above 0x7F (the accented block)",
      any(not blank(0xF1B400, 14, c) for c in range(0x80, 0xC8)))

# ---------------------------------------------------------------------------
# 7. The EXACT addresses the renamed service headers cite.  A header that says
# "the immediate at 0xF8F277" is wrong the moment it is off by one byte, and
# the byte gate cannot see that -- this tree's history has ~20 call sites cited
# one byte past the instruction.  Each address below must be the first byte of
# a `ld XIY,<base>` (0x45) or `ld XIX,<base>` (0x44).
# ---------------------------------------------------------------------------
CITED = [(0xF8F0C2, 0xF212B0, 0x45), (0xF8F245, 0xF22840, 0x45),
         (0xF8F2DB, 0xF203B0, 0x45), (0xF8F277, 0xF24640, 0x45),
         (0xF8F2A9, 0xF21940, 0x45), (0xF8F058, 0xF1B400, 0x45),
         (0xF90169, 0xF1E470, 0x44), (0xF902B2, 0xF1EAB0, 0x44)]
for site, base, op in CITED:
    want = bytes([op, base & 0xFF, (base >> 8) & 0xFF, (base >> 16) & 0xFF, 0x00])
    check("cited site 0x%06X really loads 0x%06X" % (site, base),
          A[site - 0xF80000:site - 0xF80000 + 5] == want,
          A[site - 0xF80000:site - 0xF80000 + 5].hex(" "))
check("svc 0x16 header: `ldw de,0x0e` is at 0xF8F0C9",
      A[0xF8F0C9 - 0xF80000:][:3] == bytes([0x32, 0x0E, 0x00]))

# ---------------------------------------------------------------------------
# 8. ★ The block above 0x7F in the Latin faces is ACCENTED ASCII, and that is
# proved by BYTE IDENTITY rather than by looking at the pixels: an accented
# lower-case glyph is the plain ASCII letter's bitmap UNCHANGED in rows 2..13,
# with the accent drawn in rows 0 and 1, which the plain letter leaves blank.
#
# The capitals do NOT match, and that is expected rather than a failure -- a
# capital fills rows 2..11, so there is no room, and A-acute at 0xB1 is a
# capital A REDRAWN one row shorter.  The check asserts both halves: the
# lower-case ones match, the three capitals do not.
# ---------------------------------------------------------------------------
def g14(code):
    o = 0xF1B400 - 0xF00000 + code * 14
    return B[o:o + 14]


PAIRS = [(0x9C, 'o'), (0x9D, 'a'), (0x9E, 'a'), (0x9F, 'e'), (0xA0, 'e'),
         (0xA1, 'e'), (0xA2, 'e'), (0xA3, 'u'), (0xA4, 'u'), (0xA5, 'u'),
         (0xA6, 'i'), (0xB4, 'a'), (0xB5, 'o'), (0xB6, 'u'), (0xB7, 'n'),
         (0xB8, 'i'), (0xB9, 'o')]
bad = [(hex(c), ch) for c, ch in PAIRS if g14(c)[2:] != g14(ord(ch))[2:]]
check("0xF1B400: 17 accented codes have a plain ASCII letter's exact bitmap "
      "in rows 2..13", not bad, str(bad))
# Every plain letter in that list leaves rows 0..1 blank so the accent has
# somewhere to go -- EXCEPT 'i', whose dot lives in exactly those two rows.
# That is not a wart: an accented i has no dot, and the accent takes the dot's
# place.  Asserting the exception is the point, because it is a prediction the
# typography makes and the bytes keep.
noroom = sorted({ch for _, ch in PAIRS
                 if g14(ord(ch))[0] or g14(ord(ch))[1]})
check("0xF1B400: the plain letters leave rows 0..1 blank -- except 'i'",
      noroom == ['i'], str(noroom))
check("0xF1B400: the plain 'i' has its DOT in rows 0..1",
      g14(ord('i'))[0] == 0x0C and g14(ord('i'))[1] == 0x0C,
      g14(ord('i')).hex(" "))
check("0xF1B400: the accented codes do NOT have rows 0..1 blank",
      all(g14(c)[0] or g14(c)[1] for c, _ in PAIRS))
# exactly five distinct accent marks are used across those 17 codes
marks = {bytes(g14(c)[:2]) for c, _ in PAIRS}
check("0xF1B400: the 17 use five distinct accent marks", len(marks) == 5,
      str(sorted(m.hex() for m in marks)))
check("0xF1B400: acute is `04 08` and grave is `10 08` (mirror images)",
      bytes([0x04, 0x08]) in marks and bytes([0x10, 0x08]) in marks)
# and the counter-check: the capitals are redrawn, not shifted
for c, ch in ((0xB1, 'A'), (0xB2, 'E'), (0xB3, 'N')):
    shifted = any(all(g14(c)[i] == g14(ord(ch))[i + sh]
                      for i in range(2, 12) if 0 <= i + sh < 14)
                  for sh in range(-4, 5))
    check("0xF1B400: capital 0x%02X is REDRAWN, not the plain %s shifted"
          % (c, ch), not shifted)

# ---------------------------------------------------------------------------
# 6. THE TWO KANJI SETS ARE DISJOINT.  FINDINGS-fonts.md said "0 shared glyph
# bitmaps out of 43 and 224" and nothing reproduced it; the round-1 audit
# measured it by hand and found it true.  A number nobody can re-run is not
# evidence, so it is re-derived here -- including the distinctness WITHIN each
# set, without which "0 shared" would be compatible with a set of duplicates.
# ---------------------------------------------------------------------------
KANJI_A, KANJI_B = 0xF22840, 0xF24640
ka = [gl(KANJI_A, 32, c) for c in range(240) if not blank(KANJI_A, 32, c)]
kb = [gl(KANJI_B, 32, c) for c in range(60) if not blank(KANJI_B, 32, c)]
check("kanji set A (0xF22840): 224 non-blank cells", len(ka) == 224, "%d" % len(ka))
check("kanji set B (0xF24640): 43 non-blank cells", len(kb) == 43, "%d" % len(kb))
check("kanji set A: all 224 bitmaps DISTINCT", len(set(ka)) == 224, "%d" % len(set(ka)))
check("kanji set B: all 43 bitmaps DISTINCT", len(set(kb)) == 43, "%d" % len(set(kb)))
check("the two kanji sets share ZERO bitmaps",
      len(set(ka) & set(kb)) == 0, "%d shared" % len(set(ka) & set(kb)))
# ...and neither shares one with any kana face, the other half of that sentence.
_kana = ({gl(HIRA, 32, c) for c in range(120) if not blank(HIRA, 32, c)}
         | {gl(KATA, 32, c) for c in range(120) if not blank(KATA, 32, c)})
check("no kanji bitmap equals any 16x16 kana bitmap",
      len((set(ka) | set(kb)) & _kana) == 0,
      "%d shared" % len((set(ka) | set(kb)) & _kana))

print("\n%d checks ran, %d failed" % (len(RAN), len(FAILS)))
sys.exit(1 if FAILS else 0)
