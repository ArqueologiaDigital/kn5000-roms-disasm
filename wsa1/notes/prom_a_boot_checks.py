#!/usr/bin/env python3
"""Re-derive, from the ROM bytes, every quantified claim the boot block makes.

QUESTION IT ANSWERS: "prom_a 0xF80000-0xF826A8 and 0xF827C8-0xF82CFE say
`25 modules and a terminator`, `five phases four bytes apart`, `five blink
tables of 5/6/7/7/3 entries`, `the ASCII "WSA1 EXTBD"`, `(0xC4) comes from PB
bit 0`, `these six chord tests`, `entry[n] == 0x80 | bitrev4(n)<<3`, and
`remote 0x00F7FFF0 is prom_d` -- are they still true of the ROM?"

The byte gate proves the source rebuilds the ROM and is blind to every one of
those sentences.  Run this with the gate; neither catches what the other does.

★ THE ONE THAT MATTERS MOST is section 7: the tie between the version screen and
prom_d, which is emulation gap D.  It is checked from FOUR independent places --
the two remote source literals in the code, the three ASCII labels in the
display list, the four value records' pointer pairs, and the four ROM images'
own last sixteen bytes.  If any of them moves, this exits non-zero.

    python3 notes/prom_a_boot_checks.py        # non-zero exit on any failure
    python3 notes/prom_a_boot_checks.py -v
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
ORIG = os.path.join(ROOT, "original_ROMs")
A = open(os.path.join(ORIG, "wsa1_prom_a.ic12"), "rb").read()
B = open(os.path.join(ORIG, "wsa1_prom_b.ic13"), "rb").read()
C = open(os.path.join(ORIG, "wsa1_prom_c.ic28"), "rb").read()
D = open(os.path.join(ORIG, "wsa1_prom_d.bin"), "rb").read()
SRC = image_path(ROOT, "prom_a/wsa1_prom_a.s")
FAILS, RAN = [], []
VERBOSE = "-v" in sys.argv


def a(addr, n=1):
    return A[addr - 0xF80000:addr - 0xF80000 + n]


def b(addr, n=1):
    return B[addr - 0xF00000:addr - 0xF00000 + n]


def bt(addr):
    """The single byte at `addr` as an int.  a() returns bytes; comparing those
    to an int is silently False, which is how the first draft of this file
    produced 24 spurious failures."""
    return A[addr - 0xF80000]


def u16a(addr):
    return int.from_bytes(a(addr, 2), "little")


def u32a(addr):
    return int.from_bytes(a(addr, 4), "little")


def u32b(addr):
    return int.from_bytes(b(addr, 4), "little")


def check(name, cond, detail=""):
    RAN.append(name)
    if VERBOSE or not cond:
        print("%-4s %s%s" % ("ok" if cond else "FAIL", name,
                             ("  -- " + detail) if detail else ""))
    if not cond:
        FAILS.append(name)


# --- 1. the module-initialisation directory --------------------------------
DIR_LO, DIR_HI = 0xF82641, 0xF826A9
words = [u32a(x) for x in range(DIR_LO, DIR_HI, 4)]
check("1.1 the directory is 26 LE32 words, 0xF82641-0xF826A8",
      (DIR_HI - DIR_LO) == 26 * 4 and len(words) == 26, str(len(words)))
check("1.2 the LAST word is the terminator 0xFFFFFFFF, and it is the ONLY one",
      words[-1] == 0xFFFFFFFF and words.count(0xFFFFFFFF) == 1,
      "0x%08X, %d occurrences" % (words[-1], words.count(0xFFFFFFFF)))
mods = words[:-1]
check("1.3 all 25 module pointers are inside prom_b's directory 0xF40000-0xF44018",
      all(0xF40000 <= w < 0xF44018 for w in mods),
      str(["0x%06X" % w for w in mods if not 0xF40000 <= w < 0xF44018]))
vecs = [u32b(w) for w in mods]
check("1.4 every module pointer dereferences to an address inside prom_a or prom_b",
      all(0xF00000 <= v <= 0xFFFFFF for v in vecs),
      str(["0x%08X" % v for v in vecs if not 0xF00000 <= v <= 0xFFFFFF]))
check("1.5 the FIRST entry is 0x00F40000 and (0x00F40000) == 0x00F82010, the six "
      "`jp` slots in this very block",
      mods[0] == 0xF40000 and vecs[0] == 0xF82010,
      "0x%06X -> 0x%08X" % (mods[0], vecs[0]))
check("1.6 0xF82010 really is six `jp` slots (opcode 0x1B every 4 bytes)",
      all(bt(0xF82010 + 4 * k) == 0x1B for k in range(6)),
      str([hex(bt(0xF82010 + 4 * k)) for k in range(6)]))
# ★ LAST-ELEMENT test, spelled out on the last module rather than the terminator
check("1.7 LAST module entry is 0x00F402A0 and it names 0x00FE8046",
      mods[-1] == 0xF402A0 and vecs[-1] == 0xFE8046,
      "0x%06X -> 0x%08X" % (mods[-1], vecs[-1]))
# the walker itself
check("1.8 the walker loads the directory base at 0xF82848: `43 41 26 F8 00`",
      a(0xF82848, 5) == bytes([0x43, 0x41, 0x26, 0xF8, 0x00]), a(0xF82848, 5).hex())
check("1.9 the walker's absent-module test is `cp XIX,0x0E0E0E0E` at 0xF8285A",
      u32a(0xF8285C) == 0x0E0E0E0E, "0x%08X" % u32a(0xF8285C))
check("1.10 the walker's terminator test is `cp XIX,0xFFFFFFFF` at 0xF82850",
      u32a(0xF82852) == 0xFFFFFFFF, "0x%08X" % u32a(0xF82852))
# the five phase entry points: `ld A,imm / jr T,0xF82846`
PHASES = {0xF82832: 0x00, 0xF82836: 0x04, 0xF8283A: 0x08,
          0xF8283E: 0x0C, 0xF82842: 0x10}
bad = [("0x%06X" % k, a(k, 2).hex()) for k, v in PHASES.items()
       if a(k, 2) != bytes([0x21, v])]
check("1.11 five phase entry points set A to 0x00/04/08/0C/10 (`21 vv`)",
      not bad, str(bad))
bad = [("0x%06X" % k, a(k + 2, 2).hex()) for k in PHASES
       if bt(k + 2) != 0x68 or (k + 4 + bt(k + 3)) != 0xF82846]
check("1.12 each of the five falls into the walker at 0xF82846 (`jr T,+d`)",
      not bad, str(bad))

# --- 2. the five blink-argument tables -------------------------------------
BLINK = {
    0xF8024D: (5, 0xF8023B, 0x0DE5),
    0xF80754: (6, 0xF80742, 0x0DED),
    0xF80AAD: (7, 0xF80A96, 0x0DBC),
    0xF80E12: (7, 0xF80DFB, 0x0DDA),
    0xF81344: (3, 0xF81332, 0x0C0F),
}
for base, (n, loader, var) in sorted(BLINK.items()):
    # the loader really names this table
    check("2.%X loader 0x%06X is `ld XIY,0x00%06X`" % (base & 0xFFF, loader, base),
          bt(loader) == 0x45 and u32a(loader + 1) == base,
          "0x%08X" % u32a(loader + 1))
    ws = [u32a(base + 4 * k) for k in range(n)]
    ok = all(w == 0 or 0xF00000 <= w <= 0xFFFFFF for w in ws)
    check("2.%X.a all %d entries are NULL or a prom_a/prom_b address"
          % (base & 0xFFF, n), ok, str(["0x%08X" % w for w in ws]))
    # ★ LAST-ENTRY TEST: word n is NOT a pointer -- it is the resumed code
    nxt = u32a(base + 4 * n)
    check("2.%X.b LAST-ENTRY TEST: word %d (0x%06X) is not a pointer -- 0x%08X"
          % (base & 0xFFF, n, base + 4 * n, nxt),
          not (nxt == 0 or 0xF00000 <= nxt <= 0xFFFFFF), "0x%08X" % nxt)
# the shape all five share, checked once per site on the two fixed instructions
for base, (n, loader, var) in sorted(BLINK.items()):
    # `ld A,(var)`  = 88 lo hi   (0x88 = ld A,(nn))  -- located 0x13/0x0E back
    hit = None
    for back in range(4, 0x20):
        at = loader - back
        if bt(at) == 0xC1 and u16a(at + 1) == var and bt(at + 3) == 0x21:
            hit = at
    check("2.z 0x%06X: `ld A,(0x%04X)` (C1 lo hi 21) precedes the loader"
          % (base, var), hit is not None, "")
check("2.n the five tables hold 5+6+7+7+3 = 28 entries in all",
      sum(v[0] for v in BLINK.values()) == 28, str(sum(v[0] for v in BLINK.values())))

# --- 3. the 37-character set ------------------------------------------------
want = b"_" + bytes(range(ord("A"), ord("Z") + 1)) + b"0123456789"
check("3.1 CharSet_F81768 is exactly '_' + 'A'..'Z' + '0'..'9', 37 bytes",
      a(0xF81768, 37) == want and len(want) == 37, repr(a(0xF81768, 37)))
check("3.2 the byte after it, 0xF8178D, opens `cp (0x207B),0x0D` -- code again",
      bt(0xF8178D) == 0xC1, "0x%02X" % bt(0xF8178D))

# --- 4. the expansion-board magic ------------------------------------------
check("4.1 ExtBoardMagic_F828C7 is the ASCII 'WSA1 EXTBD', 10 bytes",
      a(0xF828C7, 10) == b"WSA1 EXTBD", repr(a(0xF828C7, 10)))
check("4.2 the compare loop's own count is 10 (`23 0a` = ld C,0x0A at 0xF828AC)",
      a(0xF828AC, 2) == bytes([0x23, 0x0A]), a(0xF828AC, 2).hex())
check("4.3 LAST-ENTRY TEST: 0xF828C7 + 10 = 0xF828D1 opens `cp (0x7FCA),0x5AA5`",
      bt(0xF828D1) == 0xD1 and u16a(0xF828D2) == 0x7FCA and
      int.from_bytes(a(0xF828D5, 2), "little") == 0x5AA5, a(0xF828D1, 6).hex())
check("4.4 the source it is compared against is remote 0x00C00000 "
      "(`ld XWA,0x00C00000` at 0xF8289B)", u32a(0xF8289C) == 0x00C00000,
      "0x%08X" % u32a(0xF8289C))
check("4.5 a match writes 0x5A to (0x00C5) at 0xF828C3 (`08 c5 5a`)",
      a(0xF828C3, 3) == bytes([0x08, 0xC5, 0x5A]), a(0xF828C3, 3).hex())

# --- 5. the variant strap and the three chords ------------------------------
# Variant_SetFromPB0: ld A,0x01 / bit 0,(PB=0x1F) / jr NZ / ld A,0x02 / ld (0xC4),A
check("5.1 Variant_SetFromPB0 tests bit 0 of PB (SFR 0x1F) at 0xF82884",
      a(0xF82884, 3) == bytes([0xF0, 0x1F, 0xC8]), a(0xF82884, 3).hex())
check("5.2 ...and stores 1 or 2 into (0x00C4) at 0xF8288B",
      a(0xF82882, 2) == bytes([0x21, 0x01]) and a(0xF82889, 2) == bytes([0x21, 0x02])
      and a(0xF8288B, 2) == bytes([0xF0, 0xC4]),
      "%s %s" % (a(0xF82882, 2).hex(), a(0xF82889, 2).hex()))
CHORDS = {
    "FACTORY CLEAR v1": (0xF828DF, 0x2B38),
    "FACTORY CLEAR v2": (0xF828E9, 0x2B38),
    "ROM VERSION v1":   (0xF82952, 0x2B32),
    "ROM VERSION v2":   (0xF8295F, 0x2B30),
    "third chord v1":   (0xF82A0A, 0x2B3A),
    "third chord v2":   (0xF82A18, 0x2B33),
}
for nm, (at, ram) in sorted(CHORDS.items()):
    check("5.3 %-18s reads (0x%04X) with `ld A,(nn)` at 0x%06X" % (nm, ram, at),
          bt(at) == 0xC1 and u16a(at + 1) == ram and bt(at + 3) == 0x21,
          a(at, 4).hex())
for at in (0xF828D9, 0xF8294C, 0xF82A04):
    check("5.4 chord test at 0x%06X opens `cp (0x00C4),0x01`" % at,
          a(at, 4) == bytes([0xC0, 0xC4, 0x3F, 0x01]), a(at, 4).hex())
check("5.5 FACTORY CLEAR writes 0x5AA5 to (0x7FCA) at 0xF8292A and jumps to "
      "0xF826A9 (`78 69 fd` = jrl T, -0x2D4)",
      a(0xF8292A, 6) == bytes([0xF1, 0xCA, 0x7F, 0x02, 0xA5, 0x5A]) and
      bt(0xF8293D) == 0x78 and
      (0xF82940 + (u16a(0xF8293E) - 0x10000)) == 0xF826A9,
      a(0xF8292A, 6).hex() + " / 0x%06X"
      % (0xF82940 + (u16a(0xF8293E) - 0x10000)))

# --- 6. the LED nibble-pattern table ---------------------------------------
def bitrev4(n):
    return sum(((n >> i) & 1) << (3 - i) for i in range(4))


tbl = a(0xF829F4, 16)
bad = [(k, tbl[k], 0x80 | (bitrev4(k) << 3)) for k in range(16)
       if tbl[k] != (0x80 | (bitrev4(k) << 3))]
check("6.1 LedNibblePatterns_F829F4[n] == 0x80 | (bitrev4(n) << 3) for ALL 16 n",
      not bad, str(bad))
check("6.2 the readers mask the index with `and C,0x0F` (0xF829AB, 0xF829CF)",
      a(0xF829AB, 3) == bytes([0xCB, 0xCC, 0x0F]) and
      a(0xF829CF, 3) == bytes([0xCB, 0xCC, 0x0F]),
      "%s %s" % (a(0xF829AB, 3).hex(), a(0xF829CF, 3).hex()))
check("6.3 LAST-ENTRY TEST: 0xF829F4 + 16 = 0xF82A04 opens `cp (0x00C4),0x01`",
      a(0xF82A04, 4) == bytes([0xC0, 0xC4, 0x3F, 0x01]), a(0xF82A04, 4).hex())
check("6.4 the two readers name the table (`ld XIY,0x00F829F4` at 0xF829AE and "
      "0xF829D2)", u32a(0xF829AF) == 0x00F829F4 and u32a(0xF829D3) == 0x00F829F4,
      "0x%08X 0x%08X" % (u32a(0xF829AF), u32a(0xF829D3)))

# --- 7. ★★★ THE VERSION SCREEN AND prom_d (emulation gap D) ----------------
check("7.1 VersionScreen_Show reads 11 bytes from remote 0x00FFFFF0 into 0x2640",
      u32a(0xF82A30) == 0x00002640 and u32a(0xF82A39) == 0x00FFFFF0 and
      int.from_bytes(a(0xF82A36, 2), "little") == 0x000B,
      "dst 0x%08X count 0x%04X src 0x%08X"
      % (u32a(0xF82A30), int.from_bytes(a(0xF82A36, 2), "little"), u32a(0xF82A39)))
check("7.2 ...and 11 bytes from remote 0x00F7FFF0 into 0x264C",
      u32a(0xF82A57) == 0x0000264C and u32a(0xF82A60) == 0x00F7FFF0 and
      int.from_bytes(a(0xF82A5D, 2), "little") == 0x000B,
      "dst 0x%08X count 0x%04X src 0x%08X"
      % (u32a(0xF82A57), int.from_bytes(a(0xF82A5D, 2), "little"), u32a(0xF82A60)))
dl = a(0xF82B03, 0xF82BB0 - 0xF82B03)
for lbl in (b"ROM VERSION", b"WSA-A:", b"WSA-C:", b"WSA-D:", b"Software Group"):
    check("7.3 the display list carries the ASCII %r" % lbl, lbl in dl, "")
# the four 17-byte value records and their pointer pairs
RECS = {0xF82B6C: (0x00002640, 0x00FFFFF5, 0x5E),
        0xF82B7D: (0x00002640, 0x00002645, 0x73),
        0xF82B8E: (0x0000264C, 0x00002651, 0x88),
        0xF82B9F: (0x00002640, 0x00FFFFF5, 0x5E)}
for at, (p1, p2, y) in sorted(RECS.items()):
    check("7.4 record 0x%06X: opcode 0x07 len 0x11, pointers 0x%08X / 0x%08X, y 0x%02X"
          % (at, p1, p2, y),
          a(at, 2) == bytes([0x07, 0x11]) and u32a(at + 2) == p1 and
          u32a(at + 7) == p2 and a(at + 0x0F)[0] == y,
          "%s" % a(at, 17).hex())
check("7.5 the three label records carry the same y values 0x5E/0x73/0x88",
      dl.find(b"WSA-A:") > 0 and dl[dl.find(b"WSA-A:") - 2] == 0x5E and
      dl[dl.find(b"WSA-C:") - 2] == 0x73 and dl[dl.find(b"WSA-D:") - 2] == 0x88,
      "%02X %02X %02X" % (dl[dl.find(b"WSA-A:") - 2], dl[dl.find(b"WSA-C:") - 2],
                          dl[dl.find(b"WSA-D:") - 2]))
# the ROM tails themselves
TAILS = {"prom_a": (A, b"wsaa_822\x02ssf"), "prom_c": (C, b"wsac_230\x02ssf"),
         "prom_d": (D, b"wsad_54.ssf")}
for nm, (img, tag) in sorted(TAILS.items()):
    check("7.6 %s's last 16 bytes begin %r at file 0x7FFF0" % (nm, tag),
          img[0x7FFF0:0x7FFF0 + len(tag)] == tag, repr(img[0x7FFF0:0x80000]))
check("7.7 prom_b's tail is NOT a tag -- so 'every image ends in one' is false "
      "and the three that do are a real signal",
      B[0x7FFF0:0x7FFF3] != b"wsa", repr(B[0x7FFF0:0x7FFF4]))
# ★ the prom_d-shaped special case
check("7.8 0xF82A93 tests the SECOND buffer at +9/+10 for the ASCII 'sf' "
      "(`cp (XIX+0x15),0x6673`, XIX = 0x2640)",
      a(0xF82A93, 5) == bytes([0x9C, 0x15, 0x3F, 0x73, 0x66]),
      a(0xF82A93, 5).hex())
check("7.9 ...and ONLY prom_d's tag has 'sf' at offset 9: prom_d %r, prom_c %r",
      D[0x7FFF0 + 9:0x7FFF0 + 11] == b"sf" and
      C[0x7FFF0 + 9:0x7FFF0 + 11] != b"sf",
      "prom_d %r prom_c %r" % (D[0x7FFF9:0x7FFFB], C[0x7FFF9:0x7FFFB]))
check("7.10 the local self-test at 0xF82AC7 is `d2 fa ff ff 3f 73 66` -- it "
      "reads prom_a's OWN 0xFFFFFA and compares it with 'sf'",
      a(0xF82AC7, 7) == bytes([0xD2, 0xFA, 0xFF, 0xFF, 0x3F, 0x73, 0x66]) and
      a(0xFFFFFA, 2) == b"sf", "%s / %r" % (a(0xF82AC7, 7).hex(), a(0xFFFFFA, 2))
      )
check("7.11 GAP D: remote 0x00F7FFF0 read + the label 'WSA-D:' + prom_d's tag "
      "'wsad_54.ssf' + the +9 'sf' branch all agree",
      u32a(0xF82A60) == 0x00F7FFF0 and b"WSA-D:" in dl and
      D[0x7FFF0:0x7FFFB] == b"wsad_54.ssf" and
      D[0x7FFF9:0x7FFFB] == b"sf")

# --- 8. the glyph block's boundaries ----------------------------------------
check("8.1 0xF82BB0 and 0x00F82C00 both appear as LE32 pointers INSIDE the "
      "display list, so the glyph block is what it points at",
      dl.find(bytes([0xB0, 0x2B, 0xF8, 0x00])) >= 0 and
      dl.find(bytes([0x00, 0x2C, 0xF8, 0x00])) >= 0, "")
check("8.2 0xF82C80 is a `calr` target from 0xF827D5, which pins the block's end",
      bt(0xF827D5) == 0x1E and (0xF827D8 + u16a(0xF827D6)) == 0xF82C80,
      "0x%06X" % (0xF827D8 + u16a(0xF827D6)))

# --- 9. the source really carries these names ------------------------------
LABELS = ["ModuleInitDirectory_F82641", "BlinkArgPtrs_F8024D",
          "BlinkArgPtrs_F80754", "BlinkArgPtrs_F80AAD", "BlinkArgPtrs_F80E12",
          "BlinkArgPtrs_F81344", "CharSet_F81768", "Data_F82000",
          "ExtBoardMagic_F828C7", "LedNibblePatterns_F829F4",
          "VersionScreen_DisplayLists", "VersionScreen_Glyphs"]
text = open(SRC, encoding="utf-8").read()
for nm in LABELS:
    check("9 source defines %s" % nm, re.search(r"^%s:" % nm, text, re.M) is not None)

print("\n%d checks ran" % len(RAN))
print("ALL CHECKS PASS" if not FAILS
      else "%d FAILED: %s" % (len(FAILS), ", ".join(FAILS)))
sys.exit(1 if FAILS else 0)
