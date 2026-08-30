#!/usr/bin/env python3
"""Re-derive, from the ROM bytes, every quantified claim the 0xFCF000 module makes.

QUESTION IT ANSWERS: "prom_a 0xFCF000-0xFDE70E's banner and
notes/FINDINGS-prom_a-fcf000-module.md say `17 dispatch entries, and the count is
NOT bound-derived`, `a 96-character SET`, `two 8-entry inline jump tables that
share six targets`, `177 directory slots all on instruction boundaries`, `only
two decode starts in the last 128 bytes make 0xFE0000 a boundary` -- are they
still true of the ROM?"

The byte gate is blind to every one of those sentences.

    python3 notes/prom_a_fcf000_checks.py          # ROM + decode checks
    python3 notes/prom_a_fcf000_checks.py --fast   # skip the unidasm ones
    python3 notes/prom_a_fcf000_checks.py --tail   # + the 128-start tail sweep
                                                   #   (slow: 128 unidasm runs)
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
A = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
SRC = image_path(ROOT, "prom_a/wsa1_prom_a.s")
FAILS, RAN = [], []
VERBOSE = "-v" in sys.argv


def a(addr, n=1):
    return A[addr - 0xF80000:addr - 0xF80000 + n]


def u32(addr):
    return int.from_bytes(a(addr, 4), "little")


def check(name, cond, detail=""):
    RAN.append(name)
    if VERBOSE or not cond:
        print("%-4s %s%s" % ("ok" if cond else "FAIL", name,
                             ("   " + detail) if detail else ""))
    if not cond:
        FAILS.append(name)


# --- 1. the dispatch table --------------------------------------------------
ENT = [u32(0xFCF000 + 4 * k) for k in range(17)]
check("all 17 words at 0xFCF000 are addresses inside prom_a",
      all(0xF80000 <= w < 0x1000000 for w in ENT),
      " ".join("%06X" % w for w in ENT))
check("word 17, at 0xFCF044, is 0x00000000 -- which is what ENDS the table",
      u32(0xFCF044) == 0, "%08X" % u32(0xFCF044))
check("entry 0 is 0x00FCFE42", ENT[0] == 0xFCFE42, "%06X" % ENT[0])
check("entry 16 is 0x00FD6C93", ENT[16] == 0xFD6C93, "%06X" % ENT[16])
check("exactly three entries hold 0x00FD6C93 -- the shape of a default arm",
      ENT.count(0xFD6C93) == 3, str(ENT.count(0xFD6C93)))
check("the other fourteen are distinct",
      len({w for w in ENT if w != 0xFD6C93}) == 14)
check("the reader at 0xFCFE1D names the table in an `add XBC,0x00FCF000`",
      a(0xFCFE1D, 6).hex() == "e9c800f0fc00", a(0xFCFE1D, 6).hex())
check("...and it is a computed CALL: `lda XIY,(0xFCFE2D) / push XIY / jp (XBC)`",
      a(0xFCFE25, 5).hex() == "f22dfefc35" and a(0xFCFE2A, 3).hex() == "3db1d8",
      a(0xFCFE25, 8).hex())
# ⚠ the negative that makes the entry count WEAK evidence: no compare bounds it.
win = a(0xFCFE00, 0x1D)
check("⚠ NO `cp`/`cps` on the index appears in the 29 bytes before the add, so "
      "the 17 is NOT bound-derived",
      not re.search(rb"\xd9[\xcf\xd8-\xdf]", win), win.hex())

# --- 2. the character set ---------------------------------------------------
CS = a(0xFCF061, 96)
check("0xFCF061 is 96 bytes", len(CS) == 96)
check("...character 0 is a space", CS[0] == 0x20)
check("...characters 1..26 are 'A'..'Z'", CS[1:27] == b"ABCDEFGHIJKLMNOPQRSTUVWXYZ")
check("...characters 27..52 are 'a'..'z'", CS[27:53] == b"abcdefghijklmnopqrstuvwxyz")
check("...characters 53..62 are '0'..'9'", CS[53:63] == b"0123456789")
check("...every one of the 96 is printable ASCII except 0x7F, which appears once",
      sum(1 for c in CS if c == 0x7F) == 1
      and all(0x20 <= c <= 0x7F for c in CS))
check("...and it is NOT in ASCII order, so it is an index-to-glyph map",
      list(CS) != sorted(CS))
check("0xFCF0C1 is 34 bytes of 0x00", set(a(0xFCF0C1, 34)) == {0x00})

# --- 3. the two inline jump tables ------------------------------------------
for base, site, bound in ((0xFD70C5, 0xFD70BB, 0xFD70B2),
                          (0xFD710A, 0xFD7100, 0xFD70F7)):
    check("0x%06X: the reader at 0x%06X names it in an `add XBC,0x00%06X`"
          % (base, site, base), u32(site + 2) & 0xFFFFFF == base,
          "0x%06X" % (u32(site + 2) & 0xFFFFFF))
    check("0x%06X: bound is `dec 2,BC / cps bc,0x07 / jr ugt` at 0x%06X -- "
          "8 entries" % (base, bound),
          a(bound, 6).hex()[:8] == "d96ad9df" and a(bound + 4)[0] == 0x6B,
          a(bound, 6).hex())
    check("0x%06X: all 8 entries point inside 0xFCF000-0xFDFFFF" % base,
          all(0xFCF000 <= u32(base + 4 * k) < 0xFE0000 for k in range(8)),
          " ".join("%06X" % u32(base + 4 * k) for k in range(8)))
T1 = [u32(0xFD70C5 + 4 * k) for k in range(8)]
T2 = [u32(0xFD710A + 4 * k) for k in range(8)]
check("LAST-ENTRY TEST 0xFD70C5: base + 8*4 = 0xFD70E5, which is ENTRY 3",
      0xFD70C5 + 32 == 0xFD70E5 and T1[3] == 0xFD70E5, "%06X" % T1[3])
check("LAST-ENTRY TEST 0xFD710A: base + 8*4 = 0xFD712A, which is ENTRY 0",
      0xFD710A + 32 == 0xFD712A and T2[0] == 0xFD712A, "%06X" % T2[0])
check("the two tables share exactly six of their eight targets",
      len(set(T1) & set(T2)) == 6, str(sorted("%06X" % x for x in set(T1) & set(T2))))


# --- the "Read by: ONE site" claim, made runnable ----------------------------
# Every table header here says the base is named by exactly ONE instruction.
# That is a searched negative about the REST of both images, so it gets a census:
# the 4-byte little-endian immediate, over prom_a and prom_b, at every offset.
_Bimg = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()


def _imm_sites(v):
    le = bytes([v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, 0])
    out = []
    for img, base in ((A, 0xF80000), (_Bimg, 0xF00000)):
        i = img.find(le)
        while i >= 0:
            out.append(base + i)
            i = img.find(le, i + 1)
    return out

for base, site in ((0xFCF000, 0xFCFE1D), (0xFD70C5, 0xFD70BB),
                   (0xFD710A, 0xFD7100)):
    _h = _imm_sites(base)
    check("0x%06X: the immediate 0x00%06X occurs at exactly ONE offset in prom_a "
          "+ prom_b, and it is the reader's" % (base, base),
          _h == [site + 2], str(["0x%06X" % x for x in _h]))

# --- 4. the directory slots -------------------------------------------------
import prom_a_call_graph as CG                                    # noqa: E402
_a, _b = CG.load()
_vals = [v for v in CG.jp_slots(_b).values() if 0xFCF000 <= v < 0xFE0000]
slots = sorted(set(_vals))
# ⚠ SLOTS vs DISTINCT TARGETS -- the distinction the round-2 audit's F10 was
# about.  179 slots name 177 distinct addresses; two slots share one.
check("179 prom_b directory SLOTS point into 0xFCF000-0xFDFFFF",
      len(_vals) == 179, str(len(_vals)))
check("...naming 178 DISTINCT targets (two slots share 0xFDE1DD)",
      len(slots) == 178, str(len(slots)))
check("...and 0xFDE1DD is the one target two slots share",
      sorted(k for k in set(_vals) if _vals.count(k) > 1) == [0xFDE1DD])
check("...and the FIRST of them is 0xFCFDA7, which is what pins the start of the "
      "code", slots[0] == 0xFCFDA7, "0x%06X" % slots[0])
check("the LAST distinct target is 0xFDE70F, where the converted span stops",
      slots[-1] == 0xFDE70F, "0x%06X" % slots[-1])
# CORRECTED 2026-08-25 (audit F13): this message said "0xFDE710-0xFDFFFF".
# The 6,385 bytes left `.incbin` are 0xFDE70F-0xFDFFFF INCLUSIVE, and 0xFDE70F
# -- the last directory target -- is their FIRST byte, not one below them.
check("no directory target lies ABOVE 0xFDE70F, the first byte of the 6,385 "
      "bytes left `.incbin` (0xFDE70F-0xFDFFFF inclusive)",
      [s for s in slots if s > 0xFDE70F] == [])

# --- 5. the decode itself (needs unidasm) -----------------------------------
if "--fast" not in sys.argv:
    import prom_a_linear_decode_check as LC                       # noqa: E402
    rows = LC.decode(0xFCFDA7, 0xFDE720)
    bounds = {x for x, _, _ in rows}
    check("all 178 distinct directory targets are instruction boundaries of ONE "
          "decode from 0xFCFDA7", all(s in bounds for s in slots),
          str(["0x%06X" % s for s in slots if s not in bounds][:6]))
    check("...and so is 0xFDE70F, the address the converted span stops at",
          0xFDE70F in bounds)
    db = [x for x, _, t in rows if t == "db" and x < 0xFDE70F]
    check("the only undecodable byte is 0xFD70E1, inside JumpTable_FD70C5",
          db == [0xFD70E1], str(["0x%06X" % x for x in db]))
    # ★ the reason the span STOPS at 0xFDE70F, made runnable
    if "--tail" in sys.argv:
        ok = [s for s in range(0xFDFF80, 0xFE0000)
              if 0xFE0000 in {x for x, _, _ in LC.decode(s, 0xFE0010)}]
        check("of the 128 decode starts in 0xFDFF80-0xFDFFFF, only 0xFDFFFD and "
              "0xFDFFFF make 0xFE0000 a boundary -- which is why the tail is "
              "left .incbin", ok == [0xFDFFFD, 0xFDFFFF],
              str(["0x%06X" % x for x in ok]))

# --- 6. the source really carries the names this note quotes ----------------
LABELS = {0xFCF000: "DispatchTable_FCF000", 0xFCF044: "ModuleTables_FCF044",
          0xFD70C5: "JumpTable_FD70C5", 0xFD710A: "JumpTable_FD710A"}
found, pending = {}, []
for line in open(SRC, encoding="utf-8"):
    m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*):\s*$', line)
    if m:
        pending.append(m.group(1))
        continue
    m = re.search(r';\s*([0-9A-F]{6})\b', line)
    if m and pending:
        for n in pending:
            found.setdefault(n, int(m.group(1), 16))
        pending = []
for addr, nm in sorted(LABELS.items()):
    check("source label %s is at 0x%06X" % (nm, addr), found.get(nm) == addr,
          "found at %s" % ("0x%06X" % found[nm] if nm in found else "nowhere"))

# --- 7. ★ the module's SHAPE, asserted (round-2 audit F3) -------------------
# The note's shape table used to say the code block is 60,776 bytes in 23,622
# instructions.  Both were wrong and nothing checked them, so the three rows
# summed to 64,271 against the module's own stated 63,247.  These five checks
# make that class of error fail.
import re as _re
_ADDR = _re.compile(r";\s([0-9A-F]{6})(\s|$)")
_DIRECTIVE = (".byte", ".word", ".long", ".ascii", ".short", ".quad",
              ".fill", ".space", ".incbin", ".asciz")


def _tally(lo, hi):
    """(instruction lines, directive lines) whose address comment is in [lo,hi)."""
    ins = dirs = 0
    for line in open(SRC, encoding="utf-8"):
        line = line.rstrip("\n")
        if not line.startswith("\t"):
            continue
        m = _ADDR.search(line)
        if not m:
            continue
        if not (lo <= int(m.group(1), 16) < hi):
            continue
        t = line.strip().split(";")[0].strip()
        if not t:
            continue
        (dirs, ins) = (dirs + 1, ins) if t.split()[0] in _DIRECTIVE else (dirs, ins + 1)
    return ins, dirs


_DISP, _TAB, _CODE, _END = 0xFCF000, 0xFCF044, 0xFCFDA7, 0xFDE70F
check("S1 dispatch table is 68 bytes, 0xFCF000-0xFCF043", _TAB - _DISP == 68,
      str(_TAB - _DISP))
check("S2 table block is 3,427 bytes, 0xFCF044-0xFCFDA6", _CODE - _TAB == 3427,
      str(_CODE - _TAB))
check("S3 code block is 59,752 bytes, 0xFCFDA7-0xFDE70E (NOT 60,776)",
      _END - _CODE == 59752, str(_END - _CODE))
check("S4 the three parts sum to the module's own 63,247",
      68 + 3427 + (_END - _CODE) == _END - _DISP == 63247,
      "%d vs %d" % (68 + 3427 + (_END - _CODE), _END - _DISP))
_i, _d = _tally(_CODE, _END)
check("S5 code block holds 23,585 instruction lines (NOT 23,622) and 24 "
      "directive lines -- the two inline jump tables", _i == 23585 and _d == 24,
      "instructions %d, directives %d" % (_i, _d))
_i2, _d2 = _tally(_DISP, _CODE)
check("S6 the table block is all data: 0 instruction lines, 232 directive lines",
      _i2 == 0 and _d2 == 232, "instructions %d, directives %d" % (_i2, _d2))
check("S7 6,385 bytes left `.incbin`, 0xFDE70F-0xFDFFFF inclusive",
      0xFDFFFF - _END + 1 == 6385, str(0xFDFFFF - _END + 1))

print("\n%d checks ran" % len(RAN))
print("ALL CHECKS PASS" if not FAILS
      else "%d FAILED: %s" % (len(FAILS), ", ".join(FAILS)))
sys.exit(1 if FAILS else 0)
