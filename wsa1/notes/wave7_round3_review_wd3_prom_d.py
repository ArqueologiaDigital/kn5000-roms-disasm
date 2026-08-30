#!/usr/bin/env python3
"""REVIEW-WD3 -- do prom_d's round-3 Evidence: lines carry the names they justify?

QUESTION IT ANSWERS
    Wave 7 round 3 added 47 `Evidence:` lines to prom_d/wsa1_prom_d.s.  The byte
    gate is blind to every one of them.  This script attacks them from outside
    notes/prom_d_documentation_round3.py, i.e. it never imports the lane's code:
    it re-reads the ROMs and the committed .s text and asks whether each claim
    is true.

WHAT IT CHECKS (run it; do not quote this list)
    R1  every prom_c/prom_a address cited anywhere in prom_d's comments is an
        INSTRUCTION START in that image's listing -- and the check is shown to
        be able to fail, by re-running it on the same citations shifted by
        -2,-1,+1..+5.  (This is the a2-class off-by-one that shipped twice.)
    R2  ★ THE BOUNDARY TEMPLATE.  Twelve index-map banners say the region
        "ends at 0xNNNNN, which is the next value in the same directory".
        For ELEVEN that is true.  For slot +0x28 it is FALSE: 0x22A3B is not a
        directory value at all (the next one is 0x22D3B), and the same banner
        says so itself four lines earlier.  The 1024 count is right; the stated
        MECHANISM is not.  gen_prom_d_asm.py:1382 injects five non-directory
        cuts into BOUND, and mk_indexmap's prose hardcodes "directory".
    R3  the five catalogue/footer pairs: span/16 == the footer's leading LE16,
        measured from the image, all five.
    R4  slot +0x4C's map values are exactly the row indices of the +0x8C
        catalogue it is claimed to index (max 207, 208 distinct, 208 rows).
    R5  the six DescCurve counts (136/27/7/11/7/130 = 318 of 318) and the first
        part-A object cited for each curve.
    R6  the three descriptor arrays' ends, each pinned by the records' own
        offsets -- checked on all three, including the LAST.
    R7  the erased tail, the build tag, and the prom_a citation that fixes the
        base from the other processor.
    R8  the 18 drum kits are tone-offset-table entries 256..273.

HOW TO RUN
    python3 notes/wave7_round3_review_wd3_prom_d.py
    Exit status is non-zero if any check fails.  R2 is EXPECTED TO FAIL until
    gen_prom_d_asm.py stops calling a non-directory cut a directory value; it
    is the finding, not a regression.
"""
import os
import re
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
R = lambda n: open(os.path.join(ROOT, "original_ROMs", n), "rb").read()
D, C, A = R("wsa1_prom_d.bin"), R("wsa1_prom_c.ic28"), R("wsa1_prom_a.ic12")
u16 = lambda o: struct.unpack_from("<H", D, o)[0]
u32 = lambda o: struct.unpack_from("<I", D, o)[0]
DIR = [u32(4 * i) for i in range(48)]
DIRSET = set(DIR)
S = lambda s: DIR[s // 4]
NEXT_DIR = lambda a: min((v for v in DIRSET if a < v < 0x80000), default=None)

FAILED, N = [], [0]


def check(label, cond, detail=""):
    N[0] += 1
    print("  %s  %-68s %s" % ("PASS" if cond else "FAIL", label, detail))
    if not cond:
        FAILED.append(label)


SRC = open(image_path(ROOT, "prom_d/wsa1_prom_d.s")).read().split("\n")
ADDR = re.compile(r';\s([0-9A-F]{6})\s\s')


def starts(rel):
    # ⚠ image_path, not os.path.join: prom_c is a 2,517-line master plus 26
    # included sources, and reading the master alone scored 6 of 20 cited
    # addresses as "not an instruction start" when 210 of 210 are.
    out = set()
    for ln in open(image_path(ROOT, rel)):
        m = ADDR.search(ln)
        if m:
            out.add(int(m.group(1), 16))
    return out


print("== R1  every cited code address is an instruction start ==")
cited = set()
for ln in SRC:
    if ln.startswith(";"):
        for m in re.finditer(r'0x(F[0-9A-F]{5})\b', ln):
            cited.add(int(m.group(1), 16))
# ⚠ prom_b BELONGS IN THIS UNION and was missing.  The citation pattern above
# is `0xF?????`, and prom_b is based at 0xF00000, so prom_d's prose cites prom_b
# addresses too -- three of them, all in round 11's sound-group argument, which
# postdates this check.  Scoring them against prom_a and prom_c alone counted
# them as misses for a reason that had nothing to do with the citation.
ST = (starts("prom_c/wsa1_prom_c.s") | starts("prom_a/wsa1_prom_a.s")
      | starts("prom_b/wsa1_prom_b.s"))
# ★ AND THE CHECK STILL FAILS, ON THREE, WHICH IS LEFT STANDING ON PURPOSE.
# Reading the IMAGE instead of the 494-line header took the citation census from
# 20 addresses to 210 and the misses from 6 to 3.  The three that remain are not
# citation errors and are not split collateral -- they are DATA addresses being
# scored by a CODE criterion, and only became visible once the census could see
# all 210:
#     0xF03241  prom_b's 64-row name table, 142 bytes into a span prom_b still
#               holds as .incbin, so it has no decoded row start to land on
#     0xF33022  12 bytes INTO the decoded 16-byte row at 0xF33016 -- a field
#               inside a table row, cited as a field
#     0xFDF22A  Instrument_OctaveShift_Semitones, past prom_c's last decoded
#               row (0xFCB27B); the tail zone around it is still .incbin
# Relaxing the criterion to "lands anywhere in decoded source" would turn this
# red into a green by redefining the question, so it is NOT done here.  What is
# needed is either those spans converted, or a separate DATA-citation check.
miss = sorted(a for a in cited if a not in ST)
check("all %d cited addresses land on an instruction start" % len(cited),
      not miss, "%d/%d%s" % (len(cited) - len(miss), len(cited),
                             ("  miss " + " ".join("0x%06X" % a for a in miss))
                             if miss else ""))
worst = max(sum(1 for a in cited if a + d in ST) for d in (-2, -1, 1, 2, 3, 4, 5))
check("...and the check CAN fail: the best wrong frame scores strictly lower",
      worst < len(cited), "best shifted frame %d/%d" % (worst, len(cited)))

print("\n== R2  ★ the 'next value in the same directory' boundary template ==")
blocks, cur, start = [], [], 0
for i, l in enumerate(SRC):
    if l.startswith(";"):
        if not cur:
            start = i + 1
        cur.append(l[1:].strip())
    elif cur:
        blocks.append((start, " ".join(cur)))
        cur = []
PAT = re.compile(r"this region begins at 0x([0-9A-F]+), which is directory slot "
                 r"\+0x([0-9A-F]{2})'s value, and ends at 0x([0-9A-F]+), which is "
                 r"the next value in the same directory")
seen, bad = 0, []
for ln, b in blocks:
    for m in PAT.finditer(b):
        seen += 1
        a, slot, e = int(m.group(1), 16), int(m.group(2), 16), int(m.group(3), 16)
        if not (a in DIRSET and e in DIRSET and e == NEXT_DIR(a)):
            bad.append((ln, slot, a, e, NEXT_DIR(a)))
check("the template is used %d times and every use names a real directory value" % seen,
      seen == 12 and not bad,
      "" if not bad else "FALSE at " + ", ".join(
          "line %d slot +0x%02X: claims 0x%05X, actual next directory value 0x%05X"
          % (ln, s, e, n) for ln, s, a, e, n in bad))
check("...the counterexample is the +0x28 cut at the curve bank, and 0x22A3B is "
      "NOT a directory value", 0x22A3B not in DIRSET and NEXT_DIR(0x2223B) == 0x22D3B,
      "next directory value after 0x2223B is 0x%05X, span %d bytes not 2048"
      % (NEXT_DIR(0x2223B), NEXT_DIR(0x2223B) - 0x2223B))

print("\n== R3  the five catalogue/footer pairs ==")
for cat, ft, claim in ((0x50, 0x54, 307), (0x64, 0x68, 314), (0x80, 0x84, 503),
                       (0x8C, 0x90, 208), (0x94, 0x98, 161)):
    a = S(cat)
    n = (NEXT_DIR(a) - a) / 16.0
    check("catalogue +0x%02X: span/16 == footer +0x%02X's LE16 == %d" % (cat, ft, claim),
          n == u16(S(ft)) == claim, "span/16 = %s, footer = %d" % (n, u16(S(ft))))

print("\n== R4  slot +0x4C's values ARE row indices of the +0x8C catalogue ==")
a = S(0x4C)
vals = [u16(a + 2 * i) for i in range((NEXT_DIR(a) - a) // 2)]
real = [v for v in vals if v != 0xFFFF]
rows = (NEXT_DIR(S(0x8C)) - S(0x8C)) // 16
check("max value %d < %d rows, and the %d distinct values are exactly 0..%d"
      % (max(real), rows, len(set(real)), rows - 1),
      max(real) == rows - 1 and set(real) == set(range(rows)),
      "%d entries, %d are the 0xFFFF sentinel" % (len(vals), vals.count(0xFFFF)))

print("\n== R5  the six DescCurve populations ==")
base30, CURVES = 0x22D3B, [0x22A3B + 128 * i for i in range(6)]
PA = [u32(base30 + 14 * i + 1) for i in range(318)]
heads = [u32(x) for x in PA]
counts = [heads.count(c) for c in CURVES]
check("136/27/7/11/7/130 over 318 part-A objects, and NO other head value",
      counts == [136, 27, 7, 11, 7, 130] and set(heads) == set(CURVES),
      "counts %s sum %d" % (counts, sum(counts)))
firsts = {}
for x in PA:
    firsts.setdefault(u32(x), x)
check("...and the FIRST object cited for each curve is the right one",
      [firsts[c] for c in CURVES] == [0x23E9F, 0x246B6, 0x27415, 0x247D2, 0x24D0B, 0x23EDE],
      " ".join("0x%05X" % firsts[c] for c in CURVES))
check("the 161 descriptors at +0x38 share ONE part A, and it names curve 5",
      len(set(u32(0x4399C + 14 * i + 1) for i in range(161))) == 1
      and u32(0x4426A) == CURVES[5], "part A 0x4426A -> 0x%05X" % u32(0x4426A))

print("\n== R6  the three descriptor arrays' ends, LAST one included ==")
for slot, n, end in ((0x30, 318, 0x2B2AC), (0x38, 161, 0x446B4), (0x70, 4, 0x46D6A)):
    a = S(slot)
    offs = [x for i in range(n) for x in (u32(a + 14 * i + 1), u32(a + 14 * i + 5)) if x]
    check("+0x%02X: %d x 14 ends exactly at the smallest non-null offset" % (slot, n),
          a + 14 * n == min(offs), "0x%05X" % min(offs))
    check("   ...and the last pool object sits %d bytes short of the block end"
          % (end - max(offs)), max(offs) < end, "max 0x%05X, end 0x%05X" % (max(offs), end))

print("\n== R7  the erased tail and the build tag ==")
check("0x50B09..0x7FFEF is one unbroken 0xFF run of 0x2F4E7 bytes",
      set(D[0x50B09:0x7FFF0]) == {0xFF} and len(D[0x50B09:0x7FFF0]) == 0x2F4E7)
check("prom_a 0xF82A5F is `ld XWA,0x00F7FFF0` and 0x7FFF0 is 'wsad_54.ssf'",
      A[0xF82A5F - 0xF80000:0xF82A5F - 0xF80000 + 5] == bytes([0x40, 0xF0, 0xFF, 0xF7, 0x00])
      and D[0x7FFF0:0x7FFFB] == b"wsad_54.ssf", "0x00F7FFF0 - 0x7FFF0 = 0x%06X" % (0xF7FFF0 - 0x7FFF0))
check("prom_c 0xFB051E is `ld XBC,0x00F00000` and 0xFB0523/0xFB0528 store it",
      C[0xFB051E - 0xF80000:0xFB051E - 0xF80000 + 5] == bytes([0x41, 0x00, 0x00, 0xF0, 0x00])
      and C[0xFB0523 - 0xF80000] == 0xF2 and C[0xFB0528 - 0xF80000] == 0xF2)

print("\n== R8  the 18 drum kits are offset-table entries 256..273 ==")
tb = S(0x08)
kits = [u32(tb + 4 * i) for i in range(256, 274)]
check("18 entries at file 0x%05X..0x%05X, and 0x2B2AC is entry 259 (tone 0x103)"
      % (tb + 256 * 4, tb + 273 * 4),
      len(kits) == 18 and u32(tb + 4 * 259) == 0x2B2AC and tb + 256 * 4 == 0xF80,
      "entry 259 -> %r" % D[0x2B2AC:0x2B2BC])
check("+0xA8's 8 x 128 = 1024 bytes is bounded by the SMALLEST tone-record offset",
      min(u32(tb + 4 * i) for i in range(274)) - S(0xA8) == 1024,
      "0x%05X..0x%05X" % (S(0xA8), min(u32(tb + 4 * i) for i in range(274))))

print("\nREVIEW-WD3: %d checks, %d FAILED" % (N[0], len(FAILED)))
for f in FAILED:
    print("   - " + f)
sys.exit(1 if FAILED else 0)
