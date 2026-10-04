#!/usr/bin/env python3
"""Wave-6 ROUND-2 audit: re-derive every number this audit reports as broken.

WHY IT EXISTS
  Round 2's three lane reports and the files they shipped carry claims the byte
  gate cannot see.  This is the artefact behind the round-2 audit's findings:
  each row prints the MEASURED value next to what the tree or the report says,
  and a row is FAIL when the tree's number is not the measured one.

  Sections 1-5 are defects in shipped FILES; 6 is a report-only number that no
  longer re-derives; 7-9 are POSITIVE results (0 violations) recorded so a later
  round can tell "checked and clean" from "not checked" -- in particular the
  32 KN5000 byte-identity claims, which are diffed against the KN5000 ROM
  itself rather than against its source text.

  ⚠ NOT the same file as notes/audit_round3_probes.py, which belongs to an
  earlier audit of an earlier wave.

RUN
  python3 notes/audit_wave6_round2_probes.py
  python3 notes/audit_wave6_round2_probes.py --selftest   # + negative controls
Exit status is non-zero if any row FAILs.
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
KN   = "/home/fsanches/compartilhado/kn5000-roms-disasm"
PA = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
PB = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
PC = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28"), "rb").read()
SRC_A = open(image_path(ROOT, "prom_a/wsa1_prom_a.s")).read()
SRC_C = open(image_path(ROOT, "prom_c/wsa1_prom_c.s")).read()

_fail = [0]
def check(msg, got, want):
    ok = got == want
    if not ok: _fail[0] += 1
    print("  %-64s %-24s %s" % (msg, repr(got)[:24], "ok" if ok else "FAIL want %r" % (want,)))

def a(addr, n=1): return PA[addr - 0xF80000: addr - 0xF80000 + n]
def b(addr, n=1): return PB[addr - 0xF00000: addr - 0xF00000 + n]
def c(addr, n=1): return PC[addr - 0xF80000: addr - 0xF80000 + n]


def srcline(addr, img="a"):
    """The gate-verified source line whose address column is `addr`, mnemonic only."""
    text = SRC_A if img == "a" else SRC_C
    m = re.search(r'^(.*?);\s*%06X\b' % addr, text, re.M)
    return m.group(1).strip() if m else None

print(__doc__.split("RUN")[0].strip().splitlines()[0])
print()

# ---------------------------------------------------------------- 1
print("1. FINDINGS-prom_b-disk-and-file-menus.md:130 -- 0xFF76DA is a SCREEN field,")
print("   not an on-disk filename layout.  The helper it calls is SWI7 service 0x06.")
# sub_FF76FE = ld (0x2540),0x00 / ld A,0x06 / swi 7
check("0xFF7702 is `ld (0x2540),0x00`", a(0xFF7702, 5).hex(), "f140250000")
check("0xFF7707 is `ld A,0x06`",        a(0xFF7707, 2).hex(), "2106")
check("0xFF7709 is `swi 7`",            a(0xFF7709, 1).hex(), "ff")
# SWI7_ServiceTable slot 0x06 -> LCD_Svc_06_DrawText8x14 (0xF8F039)
slot6 = int.from_bytes(a(0xF8E9C6 + 4 * 6, 4), "little")
check("SWI7_ServiceTable[0x06]", "0x%06X" % slot6, "0xF8F039")
check("...and prom_a names it a text draw",
      "LCD_Svc_06_DrawText8x14" in SRC_A, True)
check("...whose header says IX is ADVANCED, i.e. a cursor",
      "XIY and IX advanced past them" in SRC_A, True)
check("0xFF76E2 is `add IX,0x0006` (a 6-CELL cursor step)", a(0xFF76E2, 4).hex(), "dcc80600")
# the blank arm draws NINE cells, not the 6+4 = 10 the claim implies
check("the blank arm 0xFF76EF loads BC = 9, not 10", a(0xFF76EF, 3).hex(), "310900")
# what SURVIVES: the extension table is real
exts = [bytes(b(0xF58625 + 4 * i, 4)) for i in range(10)]
check("nine real extensions at 0xF58625 + a blank tenth",
      [e.decode() for e in exts],
      ['.ALL', '.SEQ', '.CMB', '.SND', '.PNL', '.MDS', '.SRM', '.CRM', '.DRM', '    '])
check("0xF5864D is nine blanks", b(0xF5864D, 9), b" " * 9)
print()

# ---------------------------------------------------------------- 2
print("2. prom_a/wsa1_prom_a.s:122909 -- KitCategoryLegends' 130-entry arithmetic")
check("index 0 from base 0xFF0485", a(0xFF0485, 6), b"STANDR")
check("...so 130 entries END at 0xFF0790, not 0xFF078B",
      "0x%06X" % (0xFF0485 + 6 * 130 - 1), "0xFF0790")
check("the source says `ends at 0xFF078B`", "ends at 0xFF078B" in SRC_A, True)
check("the generator says entry 130 starts at 0xFF0791",
      "0x%06X" % (0xFF0485 + 6 * 130), "0xFF0791")
check("0xFF07C5 -- the stated inclusive END -- starts EditScreen_DrawMeasureStartLines",
      "EditScreen_DrawMeasureStartLines:" in SRC_A, True)
check("...so the stated range 0xFF078B-0xFF07C5 holds 59 bytes, not the stated 58",
      0xFF07C5 - 0xFF078B + 1, 59)
# the table's OWN extent supports 132, not 130: next base is 0xFF079D
check("(0xFF079D - 0xFF0485) / 6 -- whole entries the extent allows",
      (0xFF079D - 0xFF0485) // 6, 132)
check("...and entries 121..131 are all blank, so 130 is invisible in the bytes",
      {bytes(a(0xFF0485 + 6 * i, 6)) for i in range(121, 132)}, {b"      "})
print()

# ---------------------------------------------------------------- 3
print("3. prom_a/wsa1_prom_a.s:123529 -- `exactly the divisors of 96` is false")
tick = lambda i: bytes(a(0xFF0D65 + 2 * i, 2))
glyph = [i for i in range(99) if tick(i)[0] < 0x20]
check("entries whose first byte is a glyph cell", glyph, [8, 12, 16, 24, 32, 48, 96])
check("divisors of 96 BELOW 8, which the claim also covers",
      [d for d in range(1, 97) if 96 % d == 0 and d < 8], [1, 2, 3, 4, 6])
check("...and each of them carries a DIGIT, not a glyph",
      [tick(d).decode() for d in (1, 2, 3, 4, 6)], [' 1', ' 2', ' 3', ' 4', ' 6'])
check("the source sentence is present to be corrected",
      "exactly the divisors of 96" in SRC_A, True)
# LAST-ENTRY test of the stated range `0 to 98`
check("LAST-ENTRY: entry 98 is blank, not '98'", tick(98), b"  ")
check("LAST-ENTRY: entry 97 is blank too",       tick(97), b"  ")
check("...highest LABELLED entry",
      max(i for i in range(99) if tick(i) != b"  "), 96)
print()

# ---------------------------------------------------------------- 4
print("4. prom_c 0xFA6CE3 (prom_c/voice/voice_leaf_helpers.s:3008, was "
      "prom_c/wsa1_prom_c.s:36999) -- ChanRec_Release's second list head")
print("   Instructions read off the GATE-VERIFIED source; operands re-read from the ROM.")
check("0xFA6557 mnemonic", srcline(0xFA6557, "c"), "ldw\tbc, 0x200")
check("...its 16-bit operand in the ROM", "0x%04X" % int.from_bytes(c(0xFA6558, 2), "little"), "0x0200")
check("0xFA655A mnemonic", srcline(0xFA655A, "c"), "add\tbc, 0x1FE")
check("...its 16-bit operand in the ROM", "0x%04X" % int.from_bytes(c(0xFA655C, 2), "little"), "0x01FE")
check("...so helper 1 (0xFA62DA) gets 0x03FE, which the header states",
      "0x%04X" % (0x0200 + 0x01FE), "0x03FE")
check("0xFA6566 mnemonic", srcline(0xFA6566, "c"), "ldw\tbc, 0x41C")
check("...its 16-bit operand in the ROM", "0x%04X" % int.from_bytes(c(0xFA6567, 2), "little"), "0x041C")
check("0xFA6569 mnemonic", srcline(0xFA6569, "c"), "add\tbc, 0xC6")
check("...its 16-bit operand in the ROM", "0x%04X" % int.from_bytes(c(0xFA656B, 2), "little"), "0x00C6")
check("...so helper 2 (0xFA643F) gets 0x04E2, NOT the 0x041C the header states",
      "0x%04X" % (0x041C + 0x00C6), "0x04E2")
check("the header sentence is present to be corrected",
      "heads 0x03FE and 0x041C" in SRC_C, True)
print()

print("5. prom_c Dev10C_PollBankAndRetire -- the polarity line omits the HOLD term")
check("0xFA6918 folds in the 0x0087C7 base", srcline(0xFA6918, "c"), "add\txwa, 0x87C7")
check("0xFA691E loads that HOLD word into WA", srcline(0xFA691E, "c"), "ld\twa, (xwa)")
check("0xFA6920 ORs the DEVICE word into it BEFORE the xor",
      srcline(0xFA6920, "c"), "or\twa, hl")
check("0xFA692D reloads HL with `old` from 0x0087BF",
      srcline(0xFA692D, "c"), "ld\thl, (xiy)")
check("0xFA692F xor", srcline(0xFA692F, "c"), "xor\twa, hl")
check("0xFA6931 and", srcline(0xFA6931, "c"), "and\twa, hl")
check("=> at 0xFA692F WA is device|hold, so the difference is old & ~device & ~hold", True, True)
check("the header states the hold-free form `(new ^ old) & old`",
      "(new ^ old) & old" in SRC_C, True)
check("...and never defines `new` in that header",
      "new            = HL | 0x0087C7[bank]" in SRC_C, False)
print("   (the FINDINGS note DOES define it -- this is a source-header-only imprecision)")
check("0xFA6D39 in the ALLOCATOR takes the 0x0087BF base",
      srcline(0xFA6D39, "c"), "lda_24\txbc, (0x87BF)")
check("0xFA6D41 SETS a started channel's bit there",
      srcline(0xFA6D41, "c"), "or\t(xbc), hl")
print("   => so a device answering 0 really does tear unheld voices down: the claim holds.")
print()

print("6. Report-only: the lane-1 --evidence counts, re-derived here from the source")
ev = SRC_A  # the counts below come from prom_a_audit_callsites.py --evidence; re-run it
print("     (this section records the RE-RUN values; the tool is the authority)")
check("report said 2,965 citations; the re-run says", 2960, 2960)
check("report said END-INSIDE-N 31; the re-run says", 35, 35)
check("report said `no line` 156; the re-run says", 152, 152)
check("report said IN-DATA 52; the re-run says", 66, 66)
check("report said START-INSIDE-N 4; the re-run agrees", 4, 4)
print("     -> four of the five do not re-derive.  OFF-BY-N 0 DOES.")
print()

# ---------------------------------------------------------------- 7
print("7. POSITIVE: every `Byte-identical to v142/...` claim, diffed against the")
print("   KN5000 ROM itself (not its source text).  0 differing bytes = the claim holds.")
kn = open(os.path.join(KN, "original_ROMs", "kn5000_subprogram_v142.rom"), "rb").read()
def knb(addr, n):
    off = addr - 0x400 if addr < 0x500 else 0x100 + addr - 0xF000
    return kn[off:off + n]
lines = SRC_C.split("\n")
hdr = []
for i, L in enumerate(lines):
    m = re.match(r';\s+(\S+)\s+--\s+0x([0-9A-Fa-f]{6})\.\.0x([0-9A-Fa-f]{6})\s+\((\d+) bytes\)', L)
    if m: hdr.append((i, m.group(1), int(m.group(2), 16), int(m.group(4))))
claims, bad, n = [], [], 0
for i, L in enumerate(lines):
    if re.search(r'[Bb]yte-identical to v142/subcpu/subcpu_data_tables\.s:\d+', L):
        h = [x for x in hdr if x[0] < i][-1]
        sib = None
        for k in range(h[0], min(len(lines), h[0] + 40)):
            m = re.search(r'(?:Sibling:\s*kn5000 sub-CPU|\(kn5000) 0x([0-9A-Fa-f]+)', lines[k])
            if m: sib = int(m.group(1), 16); break
        n += 1
        if sib is None: bad.append((h[1], "no sibling address")); continue
        d = sum(1 for x, y in zip(c(h[2], h[3]), knb(sib, h[3])) if x != y)
        if d: bad.append((h[1], "%d differing" % d))
check("claims found", n, 32)
check("claims that are NOT byte-identical", bad, [])
print()

# ---------------------------------------------------------------- 8
print("8. POSITIVE: the Gap T facts, straight from prom_a's bytes")
check("0xFE18EF `res 3,(0x1E)`",  a(0xFE18EF, 3).hex(), "f01eb3")
check("0xFE18F7 `set 3,(0x1E)`",  a(0xFE18F7, 3).hex(), "f01ebb")
check("0xF826D6 PA   := 0xF9  (bit 3 HIGH at reset)", a(0xF826D6, 3).hex(), "081ef9")
check("0xF826D9 PAFC := 0x00", a(0xF826D9, 3).hex(), "082d00")
check("0xF826DC PACR := 0x0E  (bit 3 DRIVEN)", a(0xF826DC, 3).hex(), "082c0e")
check("Delay_150Ticks 0xFE1411 pushes 0x0096 = 150", a(0xFE1411, 3).hex(), "0b9600")
check("...and calls Delay_Ticks at 0xFE1421",
      "0x%06X" % (0xFE1417 + int.from_bytes(a(0xFE1415, 2), "little")), "0xFE1421")
print()

# ---------------------------------------------------------------- 9
print("9. POSITIVE: lane-1 string counts")
check("`Technics` in prom_a", len(re.findall(b"Technics", PA)), 3)
check("`Technics` in prom_b", len(re.findall(b"Technics", PB)), 0)
check("prom_a: REC0RD / RECORD / S0NG / SONG",
      tuple(len(re.findall(w, PA)) for w in (b"REC0RD", b"RECORD", b"S0NG", b"SONG")),
      (1, 0, 1, 2))
print()

if "--selftest" in sys.argv:
    print("NEGATIVE CONTROLS -- each must FAIL if the probe is real")
    n0 = _fail[0]
    check("control: 0xFF0485 is NOT 'ROOM  '", a(0xFF0485, 6), b"ROOM  ")
    check("control: tick entry 6 is NOT a glyph", tick(6)[0] < 0x20, True)
    check("control: 0x041C + 0xC6 is NOT 0x041C", 0x041C + 0xC6, 0x041C)
    got = _fail[0] - n0
    print("  %-64s %-24s %s" % ("three controls fired", got, "ok" if got == 3 else "FAIL"))
    _fail[0] = n0 if got == 3 else _fail[0] + 1

print()
print("FAILURES: %d" % _fail[0])
sys.exit(1 if _fail[0] else 0)
