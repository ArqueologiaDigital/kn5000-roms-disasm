#!/usr/bin/env python3
"""Adversarial re-derivation of the WSA1 memory-map report (2026-08-24).

QUESTION THIS ANSWERS
    Which load-bearing claims of "WSA1 memory map from the two reset paths"
    survive an independent re-derivation from the ROM bytes, and which do not?

RUN
    python3 scripts/analysis/refute_memory_map.py

Reads only original_ROMs/. Prints PASS/FAIL per byte-level assertion and then
the verdicts that depend on them. Every FAIL below is a defect in the report,
not in this script -- the EXPECTED-FAIL block is deliberate.

Register addresses are taken from MAME's symbol table, not from memory:
    mame/src/devices/cpu/tlcs900/tmp95c061.cpp:1359-1391
      0x12 P6  0x13 P7  0x15 P6FC  0x1E PA  0x20 TRUN
      0x3C MSAR0 0x3D MAMR0 0x3E MSAR1 0x3F MAMR1
      0x5A DREFCR 0x5B DMEMCR
      0x5C MSAR2 0x5D MAMR2 0x5E MSAR3 0x5F MAMR3
      0x68 B0CS 0x69 B1CS 0x6A B2CS 0x6B B3CS 0x6C BEXCS
      0x6E WDMOD 0x6F WDCR
      0x7C DMA0V 0x7D DMA1V 0x7E DMA2V 0x7F DMA3V     <-- 0x7E is DMA2V
MAME stores all of MSAR/MAMR/BnCS/BEXCS and never decodes them
(tmp95c061.cpp:1295-1335 are bare assignments), so no window size in the
report can have come from MAME.
"""

import os, re, struct, sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
ROMS = os.path.join(ROOT, "original_ROMs")
BASE = {"a": 0xF80000, "b": 0xF00000, "c": 0xF80000}
FILES = {"a": "wsa1_prom_a.ic12", "b": "wsa1_prom_b.ic13",
         "c": "wsa1_prom_c.ic28", "d": "wsa1_prom_d.bin"}
img = {k: open(os.path.join(ROMS, v), "rb").read() for k, v in FILES.items()}

fails = []


def at(rom, addr, n):
    off = addr - BASE[rom]
    assert 0 <= off < len(img[rom]), f"0x{addr:06X} outside prom_{rom}"
    return img[rom][off:off + n]


def check(label, rom, addr, expect, expect_fail=False):
    got = at(rom, addr, len(expect))
    ok = (got == expect)
    tag = "PASS" if ok else "FAIL"
    if expect_fail:
        tag = "as-predicted-FAIL" if not ok else "UNEXPECTED-PASS"
        if ok:
            fails.append(label)
    elif not ok:
        fails.append(label)
    print(f"  [{tag}] prom_{rom} 0x{addr:06X} (file 0x{addr-BASE[rom]:05X}): "
          f"{got.hex(' ')}   {label}")
    return ok


def note(s):
    print(f"      {s}")


print(__doc__.split("RUN")[0].strip())
print()

# ---------------------------------------------------------------- reset paths
print("1. RESET VECTORS AND INIT BLOCKS -- report CONFIRMED")
check("prom_a reset PC = 0x00F826A9", "a", 0xFFFF00, bytes.fromhex("a926f800"))
check("prom_c reset PC = 0x00FFF000", "c", 0xFFFF00, bytes.fromhex("00f0ff00"))
for addr, exp, name in (
        (0xF826A9, "086e04", "WDMOD=0x04"), (0xF826AC, "086fb1", "WDCR=0xB1"),
        (0xF826AF, "08121b", "P6=0x1B"),    (0xF826B2, "08151f", "P6FC=0x1F"),
        (0xF8272D, "083c78", "MSAR0=0x78"), (0xF82730, "083e00", "MSAR1=0x00"),
        (0xF82733, "085ce0", "MSAR2=0xE0"), (0xF82736, "085e60", "MSAR3=0x60"),
        (0xF82739, "083d3f", "MAMR0=0x3F"), (0xF8273C, "083f7f", "MAMR1=0x7F"),
        (0xF8273F, "085d3f", "MAMR2=0x3F"), (0xF82742, "085f0f", "MAMR3=0x0F"),
        (0xF82763, "085a71", "DREFCR=0x71"),(0xF82766, "085b8d", "DMEMCR=0x8D"),
        (0xF82769, "086814", "B0CS=0x14"),  (0xF8276C, "086917", "B1CS=0x17"),
        (0xF8276F, "086a1b", "B2CS=0x1B"),  (0xF82772, "086b19", "B3CS=0x19"),
        (0xF82775, "086c03", "BEXCS=0x03")):
    check("CPU1 " + name, "a", addr, bytes.fromhex(exp))
for addr, exp, name in (
        (0xFFF038, "083c10", "MSAR0=0x10"), (0xFFF03B, "083d07", "MAMR0=0x07"),
        (0xFFF03E, "083ec0", "MSAR1=0xC0"), (0xFFF041, "083f7f", "MAMR1=0x7F"),
        (0xFFF044, "085ce0", "MSAR2=0xE0"), (0xFFF047, "085d3f", "MAMR2=0x3F"),
        (0xFFF04A, "085e00", "MSAR3=0x00"), (0xFFF04D, "085f03", "MAMR3=0x03"),
        (0xFFF050, "086810", "B0CS=0x10"),  (0xFFF053, "086914", "B1CS=0x14"),
        (0xFFF056, "086a1b", "B2CS=0x1B"),  (0xFFF059, "086b1b", "B3CS=0x1B"),
        (0xFFF05C, "086c00", "BEXCS=0x00"), (0xFFF05F, "085a71", "DREFCR=0x71"),
        (0xFFF062, "085b89", "DMEMCR=0x89"),(0xFFF01A, "08151f", "P6FC=0x1F")):
    check("CPU2 " + name, "c", addr, bytes.fromhex(exp))
note("Both init blocks are unbroken runs of the 3-byte 0x08 'ldio' form; they")
note("reassemble byte-identically with llvm-mc -triple=tlcs900 (75 insns for")
note("prom_a 0x26A9-0x2789, 39 for prom_c 0x7F000/0x7F00B/0x7F06C runs), so")
note("no decode desync is possible in the memory-map tables.")
print()

# ---------------------------------------------------------------- refutations
print("2. REFUTED CLAIMS (the byte at the cited address is not what was claimed)")
check("report: 'DMA3 vector 0xF8E166 ld (DMA3V),0x12' -- 0x7E is DMA2V",
      "a", 0xF8E166, bytes.fromhex("087f12"), expect_fail=True)
check("  the actual byte pair is DMA2V (0x7E) = 0x12",
      "a", 0xF8E166, bytes.fromhex("087e12"))
check("  and CPU2 programs the SAME engine (report says CPU2 has none)",
      "c", 0xF99A2A, bytes.fromhex("087e12"))
check("  CPU2 also starts timer 2: set 2,(TRUN)",
      "c", 0xF99A2D, bytes.fromhex("f020ba"))
note("micro-DMA vector 0x12 -> (0x12&0x1f)<<2 = 0x48 = INTT2 "
     "(tmp95c061.cpp:338 + :353), so 'timer 2' is right, 'DMA3' is not.")

check("report: 'CPU2 busy-in at 0xF999A6 bit 3,(0x1e)'",
      "c", 0xF999A6, bytes.fromhex("f01ecb"), expect_fail=True)
check("  0xF999A5 is the instruction start: cp HL,0x0020",
      "c", 0xF999A5, bytes.fromhex("dbcf2000"))
check("  the real bit 3,(PA) polls are at 0xF999D0 ...",
      "c", 0xF999D0, bytes.fromhex("f01ecb"))
check("  ... and 0xF99A06", "c", 0xF99A06, bytes.fromhex("f01ecb"))

check("report: 'prom_b thunk at file 0x000A4'",
      "b", 0xF000A4, bytes.fromhex("1ba5e9f8"), expect_fail=True)
check("  the vector 0x00F400A4 is prom_b file 0x400A4",
      "b", 0xF400A4, bytes.fromhex("1ba5e9f8"))
check("report: 'prom_b thunk at file 0x00EDC'",
      "b", 0xF00EDC, bytes.fromhex("1b7fe4f8"), expect_fail=True)
check("  the vector 0x00F40EDC is prom_b file 0x40EDC",
      "b", 0xF40EDC, bytes.fromhex("1b7fe4f8"))

nwsa = len(re.findall(rb"WSA", img["b"]))
ok = nwsa > 0
if ok:
    print(f"  [as-predicted-FAIL] report: \"prom_b has no 'wsa' string anywhere\""
          f" -- prom_b contains {nwsa} 'WSA' strings")
    for m in list(re.finditer(rb"WSA", img["b"]))[:4]:
        note(f"prom_b file 0x{m.start():05X}: {img['b'][m.start():m.start()+18]!r}")
    note("what prom_b really lacks is the lowercase wsaX_NNN build tag at "
         "0x7FFF0; its 0x7FFF0 is code (call 0xF42A78 / calr 0xF80086).")
else:
    fails.append("prom_b WSA strings")
check("  prom_b 0x7FFF0 is code", "b", 0xF7FFF0, bytes.fromhex("1d782af41e8f000e"))

check("report: 'WSA1 EXTBD in prom_c at file 0x612A0'",
      "c", 0xF80000 + 0x612A0, b"WSA1 EXTBD", expect_fail=True)
check("  the string starts at file 0x6129E",
      "c", 0xF80000 + 0x6129E, b"WSA1 EXTBD")
n = len(re.findall(rb"WSA1 EXTBD", img["c"]))
print(f"  [{'PASS' if n == 2 else 'FAIL'}] prom_c carries {n} copies of "
      f"'WSA1 EXTBD' (0x6129E and 0x61EC9), report cites one")
if n != 2:
    fails.append("EXTBD copies")
print()

# ------------------------------------------------------------- clear-loop gap
print("3. DOWNGRADED: CPU1 'work DRAM 0x600000-0x60FFFF zeroed at boot'")
check("first clear: XBC=0x0D00 words of 4 from 0x600000", "a", 0xF8279A,
      bytes.fromhex("41000d000044000060 00".replace(" ", "")))
check("second clear: XBC=0x3000 words of 4 from 0x604000", "a", 0xF827AF,
      bytes.fromhex("41003000004400406000"))
note("0x0D00*4 = 0x3400 -> 0x600000-0x6033FF; 0x3000*4 = 0xC000 -> "
     "0x604000-0x60FFFF.")
note("0x603400-0x603FFF (0xC00 bytes) is NEVER cleared -- a preserved region "
     "the report does not mention. It is a live structure base: prom_b "
     "0xF440A5 does ld XHL,0x00603400.")
print()

print("4. DOWNGRADED: 'B0CS retuned around a 512-iteration loop'")
check("B0CS 0x14 -> 0x10 (bit 2 clear)", "a", 0xFE509B, bytes.fromhex("086810"))
check("B0CS restored to 0x14",           "a", 0xFE50D5, bytes.fromhex("086814"))
check("loop bound: cp IZ,0x0200 with inc 2,IZ", "a", 0xFE50CD,
      bytes.fromhex("de62decf0002"))
note("IZ steps by 2 to 0x200 => 256 iterations, 2 bytes each = 0x200 bytes. "
     "The transfer size is right; '512-iteration' is not.")
print()

print("5. REFUTED: 'bit 3 of BnCS is set exactly on the areas that carry "
      "ROM/flash'")
for rom, addr, name in ((("a", 0xF82769, "CPU1 B0CS")), ("a", 0xF8276C, "CPU1 B1CS"),
                        ("a", 0xF8276F, "CPU1 B2CS"), ("a", 0xF82772, "CPU1 B3CS"),
                        ("c", 0xFFF050, "CPU2 B0CS"), ("c", 0xFFF053, "CPU2 B1CS"),
                        ("c", 0xFFF056, "CPU2 B2CS"), ("c", 0xFFF059, "CPU2 B3CS")):
    v = at(rom, addr, 3)[2]
    print(f"      {name} = 0x{v:02X}  bit3={'set' if v & 8 else 'clear'}")
note("bit 3 is set on CS2 and CS3 of BOTH CPUs. CS3 is the DRAM area (the "
     "report's own LCAS argument), not ROM/flash. The set {CS2,CS3} is the "
     "set of areas that are 16 bits wide, which the flash unlock proves for "
     "CS2 independently.")
print()

# ------------------------------------------------------------------ the flash
print("6. REFUTED: \"the flash's size is not established\"")
check("base held in a local: ld XBC,0x00E80000", "c", 0xFC864B,
      bytes.fromhex("41000 0e800".replace(" ", "")))
check("caller address masked to 64 KB: and XIX,0x00FF0000", "c", 0xFC8656,
      bytes.fromhex("400000ff00e8c4"))
check("device-ID test: cp (0x00E29D),0x22AB", "c", 0xFC8694,
      bytes.fromhex("d29de2003fab22"))
check("ID matches -> bottom block: cp XIX,0x00E80000", "c", 0xFC869D,
      bytes.fromhex("eccf000 0e800".replace(" ", "")))
for a, e, w in ((0xFC86A8, "b1023000", "erase +0x0000"),
                (0xFC86AF, "f3e5004002 3000".replace(" ", ""), "erase +0x4000"),
                (0xFC86B9, "f3e5006002 3000".replace(" ", ""), "erase +0x6000"),
                (0xFC86C3, "e9c80080 0000".replace(" ", ""), "erase +0x8000")):
    check("  " + w, "c", a, bytes.fromhex(e))
check("ID differs -> top block: cp XIX,0x00EF0000", "c", 0xFC86CF,
      bytes.fromhex("eccf000 0ef00".replace(" ", "")))
for a, e, w in ((0xFC86DA, "e9c8000007 00".replace(" ", ""), "erase +0x70000"),
                (0xFC86E7, "e9c8008007 00".replace(" ", ""), "erase +0x78000"),
                (0xFC86F4, "e9c800a007 00".replace(" ", ""), "erase +0x7A000"),
                (0xFC8701, "e9c800c007 00".replace(" ", ""), "erase +0x7C000")):
    check("  " + w, "c", a, bytes.fromhex(e))
note("Highest sector base addressed is 0xE80000+0x7C000 = 0xEFC000, and both "
     "special-cased 64 KB blocks are 0xE8 (first) and 0xEF (last):")
note("  => the flash occupies exactly 0xE80000-0xEFFFFF = 512 KB = 4 Mbit.")
note("Unlock addresses 0xAAAA / 0x5554 = 2 x word addresses 0x5555 / 0x2AAA, "
     "so A0 is the CPU's byte-lane select: the part is x16.")
note("Two sector geometries (16/8/8/32 KB at the bottom vs 32/8/8/16 KB at the "
     "top) with a 16-bit ID test = an Am29F400-class bottom-boot/top-boot pair;")
note("0x22AB is the published word-mode ID of Am29F400B/MBM29F400B "
     "(INFERENCE from ID tables -- no datasheet is in these trees).")
print()

print("7. UPGRADED: prom_d as the 0xE80000 flash image")
d = img["d"]
last = max(i for i in range(len(d)) if d[i] != 0xFF)
runs = []
s = None
for i in range(len(d)):
    if d[i] == 0xFF:
        if s is None:
            s = i
    else:
        if s is not None and i - s >= 0x1000:
            runs.append((s, i))
        s = None
print(f"      prom_d size 0x{len(d):X}; last non-0xFF byte 0x{last:X}")
print(f"      0xFF runs >= 0x1000: {[(hex(a), hex(b)) for a, b in runs]}")
hdr = [struct.unpack_from("<I", d, i)[0] for i in range(0, 0xB4, 4)]
print(f"      header 0x00-0xB0: {len(hdr)} words, [0]=0x{hdr[0]:08X}, "
      f"max of the rest = 0x{max(hdr[1:]):06X}")
note("content ends at 0x50B08, exactly 14 bytes past the header's largest "
     "offset 0x050AFA; then erased 0xFF to 0x7FFEF; then the build tag at "
     "0x7FFF0. That is a flash image, and its size is the flash's size.")
note("report's 'header at 0x00-0xB0 is 45 0-based offsets ... all < 0x80000' "
     "is 44/45: word[0] is 0xFFFFFFFF.")
print()

print("8. CONFIRMED, re-derived independently")
for rom, addr, exp, lab in (
        ("a", 0xF827C4, "1b602df4", "reset path jp 0xF42D60"),
        ("b", 0xF42D60, "1b0656f8", "prom_b 0x42D60 = jp 0xF85606"),
        ("a", 0xF85606, "4780eb6000", "0xF85606 = ld XSP,0x0060EB80"),
        ("a", 0xF80007, "1e3bf2", "0xF80007 calr 0xF7F245 (crosses into prom_b)"),
        ("b", 0xF7F245, "0b00001d282ef4", "prom_b 0x7F245 is a real function"),
        ("b", 0xF40EF0, "1bfee0f8", "thunk 0xF40EF0 -> jp 0xF8E0FE (the 0xE2 read)"),
        ("a", 0xF8ECF4, "f2000079ce", "bit 6,(0x790000) display busy poll"),
        ("a", 0xF8ECFB, "f2010079 0046".replace(" ", ""), "ld (0x790001),0x46"),
        ("a", 0xFE680F, "c2000 07a23".replace(" ", ""), "ld C,(0x7A0000)"),
        ("a", 0xFE54B6, "c204007b27", "ld L,(0x7B0004)"),
        ("a", 0xF8319A, "44000 07f00".replace(" ", ""), "ld XIX,0x007F0000"),
        ("a", 0xFE4CF8, "e8c8000 07e00".replace(" ", ""), "add XWA,0x007E0000"),
        ("a", 0xF8E0AF, "41000 07c00".replace(" ", ""), "CPU1 link port 0x7C0000"),
        ("c", 0xF999F9, "41000 01000".replace(" ", ""), "CPU2 link port 0x100000"),
        ("a", 0xF830AC, "085b2d", "power-down DMEMCR=0x2D"),
        ("a", 0xF830B0, "f012bd05", "set 5,(P6) ; halt"),
        ("c", 0xFB7802, "41004 01000".replace(" ", ""), "CPU2 0x104000"),
        ("c", 0xFAC132, "b9020200ff0000000000", "0x10C000+2 write then five nops"),
        ("c", 0xFB6B6E, "44000 0c000".replace(" ", ""), "CPU2 expansion 0xC00000"),
        ("c", 0xF98057, "41000 0e000".replace(" ", ""), "CPU2 0xE00000 addr/data pair"),
        ("a", 0xF82892, "40402600 00".replace(" ", ""), "EXTBD read dest = 0x2640"),
        ("a", 0xF8289B, "40000 0c000".replace(" ", ""), "EXTBD remote addr 0xC00000"),
        ("a", 0x00F828C7, None, None)):
    if exp is None:
        continue
    check(lab, rom, addr, bytes.fromhex(exp))
check("prom_a holds the 'WSA1 EXTBD' comparand", "a", 0xF828C7, b"WSA1 EXTBD")
print()

print("9. THE ONE CLAIM THAT CANNOT BE CHECKED HERE: the MAMR window table")
note("MAME never decodes MAMR (tmp95c061.cpp:1313-1335 are bare stores) and no "
     "TMP95C061 datasheet exists in any of these trees.")
note("The report's table (size = 32 KB x (MAMR+1); MAMR bit k masks A(15+k)) is "
     "NOT a new derivation: it is verbatim the reconstruction already recorded "
     "in technics-docs/tmp94c241-memory-controller.md, which grades itself "
     "'strong, not proven' and records that a competing 64 KB-granularity "
     "reading was ALSO 'confirmed' by two exact fits before the contradiction "
     "was noticed.")
note("The report's cited corroboration, kn7000_mame/notes/kn1500-lcd.md:46-52, "
     "states the OPPOSITE decode for the very row it is cited for: "
     "'MSAR3=0x00, MAMR3=0x0f -> ~1 MB CS window', and the KN1500 driver was "
     "fixed to map 512 KB with mirror(0x080000) inside a 1 MB window.")
note("Same file line 49 puts KN1500 CS0 at 0x780000 from MSAR0=0x78 with "
     "MAMR0=0x3F -- a start address NEITHER reading reproduces.")
print()

print("10. AN OBSERVATION THE REPORT MISSED, bearing on 9")
res = {}
for nm, base in (("a", 0xF80000), ("b", 0xF00000)):
    dd = img[nm]
    for i in range(len(dd) - 6):
        a = None
        if dd[i] in (0xC2, 0xD2, 0xE2, 0xF2):
            a = dd[i+1] | dd[i+2] << 8 | dd[i+3] << 16
        elif 0x40 <= dd[i] <= 0x47 and dd[i+4] == 0x00:
            a = dd[i+1] | dd[i+2] << 8 | dd[i+3] << 16
        elif dd[i] == 0xE8 and dd[i+1] == 0xC8 and dd[i+5] == 0x00:
            a = dd[i+2] | dd[i+3] << 8 | dd[i+4] << 16
        if a is not None and 0x680000 <= a < 0x800000:
            res[a] = res.get(a, 0) + 1
hot = sorted((a for a, n in res.items() if n >= 4))
print(f"      CPU1 operand addresses in 0x680000-0x7FFFFF seen >= 4 times"
      f" (CS0 territory under either MAMR reading):")
for a in hot:
    print(f"        0x{a:06X}: {res[a]}")
note("0x72F2D2 is a repeating 'f2 d2 f2 72' data pattern (prom_a 0xF54C98+), "
     "not a device. Every real CS0 device lies in 0x790000-0x7FFFFF, i.e. "
     "inside MSAR0<<16 = 0x780000; nothing at all is referenced in "
     "0x680000-0x78FFFF. "
     "*** PARTLY SUPERSEDED: this refutation closed by saying no candidate "
     "MAMR reading makes the CS0 window START at 0x780000, so MSAR0=0x78 was "
     "unexplained. That was true of the two readings then on the table, both "
     "of which truncate the base to the window. "
     "scripts/analysis/mamr_reading_elimination.py adds the third variable the "
     "refutation did not consider -- whether MSAR is truncated at all -- and "
     "finds exactly two of eight decoders survive this machine's own firmware: "
     "32 KB per MAMR unit with higher-numbered-CS-wins, in a truncated-base "
     "and a literal-base flavour. The literal-base survivor puts CS0 at "
     "0x780000-0x97FFFF and explains MSAR0=0x78 exactly. So the 64 KB reading "
     "is dead, and MSAR0=0x78 is no longer unexplained -- it is one of two "
     "surviving explanations. Which of the two is right remains open. ***")
print()

if fails:
    print("FAIL: " + "; ".join(fails))
    sys.exit(1)
print("PASS: every byte this refutation cites is present as quoted, "
      "and every predicted mismatch mismatched.")
