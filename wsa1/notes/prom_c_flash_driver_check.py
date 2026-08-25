#!/usr/bin/env python3
"""Every number the prom_c FLASH-DRIVER headers quote, re-derived from the ROM bytes.

QUESTION IT ANSWERS
  "Does the flash driver at 0xFC856C-0xFC89C4 really issue the command sequence, the sector
   map, the buffer address and the loop counts that its source headers claim?"

WHY IT EXISTS
  The headers for that block make quantified claims -- a 64 KiB staging buffer at 0x00010000,
  a 1 KiB programming slice, four boot sub-sectors at two different sets of offsets, and one
  loop whose count register is EIGHT bits wide where its two siblings' are sixteen.  This
  tree's rule is that a quoted number comes from a committed script.  This is that script.
  It reads the ROM image directly and matches BYTES, not unidasm's text, so it is independent
  of the disassembler.

  ⚠ The one place it cannot be byte-only is the register width of `djnz`: that is a property
  of the prefix byte, so the script checks the prefix byte itself (0xCA = the 8-bit register
  B, 0xD9 = the 16-bit register BC) and cites where that mapping is defined --
  mame/src/devices/cpu/tlcs900/900tbl.hxx, get_reg8_current()/oC8()/oD8().

RUN
  python3 notes/prom_c_flash_driver_check.py          # prints every check, exits non-zero on failure
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASE = 0xF80000
ROM = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28"), "rb").read()

FAILS = []


def at(addr, n):
    return ROM[addr - BASE: addr - BASE + n]


def check(label, cond, detail=""):
    print(("  ok   " if cond else "  FAIL ") + label + (("   " + detail) if detail else ""))
    if not cond:
        FAILS.append(label)


def u16(addr):
    b = at(addr, 2)
    return b[0] | (b[1] << 8)


def u32(addr):
    b = at(addr, 4)
    return b[0] | (b[1] << 8) | (b[2] << 16) | (b[3] << 24)


print("prom_c flash driver 0xFC856C-0xFC89C4 -- claims re-derived from the ROM")

# ---------------------------------------------------------------- unlock addresses
# `ld XBC,0x00e80000` = 41 00 00 e8 00 ; `add XBC,0x0000aaaa` = e9 c8 aa aa 00 00
check("0xFC8571 loads the flash base 0x00E80000 into XIX",
      at(0xFC8571, 5) == bytes.fromhex("440000e800"))
check("0xFC85A5 loads the same base into XBC in Flash_ReadDeviceId",
      at(0xFC85A5, 5) == bytes.fromhex("410000e800"))
check("0xFC8578 adds 0xAAAA  -> unlock cycle 1 address 0x00E8AAAA",
      at(0xFC8578, 6) == bytes.fromhex("e9c8aaaa0000"))
check("0xFC8619 adds 0x5554  -> unlock cycle 2 address 0x00E85554",
      at(0xFC8619, 6) == bytes.fromhex("e9c854550000"))
check("0xFC88FE loads 0x00E8AAAA as a literal (the word-program path)",
      at(0xFC88FE, 5) == bytes.fromhex("43aaaae800"))
check("0xFC8920 writes 0x0055 to the absolute address 0xE85554",
      at(0xFC8920, 7) == bytes.fromhex("f2545 5e8025500".replace(" ", "")))

# ---------------------------------------------------------------- command bytes
# `ld (XBC),0x00NN` = B1 02 NN 00
cmds = {0xFC8581: 0xAA, 0xFC858F: 0xF0,          # read/reset:   AA .. 55 .. F0
        0xFC85B9: 0xAA, 0xFC85CA: 0x90,          # autoselect:   AA .. 55 .. 90
        0xFC8613: 0xAA, 0xFC8622: 0x55, 0xFC8629: 0x80,
        0xFC8630: 0xAA, 0xFC8637: 0x55, 0xFC863E: 0x10,   # chip erase: 80 .. 10
        0xFC866B: 0xAA, 0xFC867B: 0x55, 0xFC8682: 0x80,
        0xFC8689: 0xAA, 0xFC8690: 0x55,
        0xFC86A8: 0x30, 0xFC870F: 0x30,          # sector erase: 80 .. 30
        0xFC891C: 0xAA, 0xFC8927: 0xA0,          # word program: AA .. 55 .. A0
        0xFC8970: 0xAA, 0xFC897B: 0xA0}
bad = [hex(a) for a, v in cmds.items()
       if not (at(a, 4)[0] in (0xB1, 0xB3) and at(a, 4)[1] == 0x02
               and at(a, 4)[2] == v and at(a, 4)[3] == 0x00)]
check("all 21 immediate command writes have the byte value the headers name", not bad,
      "bad: " + ", ".join(bad) if bad else "AA/55 unlock + F0,90,80,10,30,A0")

# ---------------------------------------------------------------- device identity
# `cp DE,1` = da d9 ; `cp DE,4` = da dc ; `cp HL,0x2223` = db cf 23 22
check("0xFC85DB compares the manufacturer word against 1", at(0xFC85DB, 2) == bytes([0xDA, 0xD9]))
check("0xFC85DF compares the manufacturer word against 4", at(0xFC85DF, 2) == bytes([0xDA, 0xDC]))
check("0xFC85E3 compares the device word against 0x2223",
      at(0xFC85E3, 4) == bytes([0xDB, 0xCF, 0x23, 0x22]))
check("0xFC85EB compares the device word against 0x22AB",
      at(0xFC85EB, 4) == bytes([0xDB, 0xCF, 0xAB, 0x22]))
check("0xFC85D3 stores the manufacturer word to 0x00E29F",
      at(0xFC85D3, 5) == bytes([0xF2, 0x9F, 0xE2, 0x00, 0x52]))
check("0xFC88A6 stores the returned device word to 0x00E29D",
      at(0xFC88A6, 5) == bytes([0xF2, 0x9D, 0xE2, 0x00, 0x50]))
check("0xFC8694 tests (0x00E29D) against 0x22AB to pick the boot-block map",
      at(0xFC8694, 7) == bytes([0xD2, 0x9D, 0xE2, 0x00, 0x3F, 0xAB, 0x22]))

# ---------------------------------------------------------------- the two boot maps
# bottom-boot arm: base+0, +0x4000, +0x6000, +0x8000, guarded by cp XIX,0x00E80000
check("bottom-boot arm is guarded by `cp XIX,0x00E80000`",
      at(0xFC869D, 6) == bytes.fromhex("eccf0000e800"))
check("bottom-boot sub-sector 2 offset is +0x4000",
      at(0xFC86AF, 7)[2:4] == bytes([0x00, 0x40]))
check("bottom-boot sub-sector 3 offset is +0x6000",
      at(0xFC86B9, 7)[2:4] == bytes([0x00, 0x60]))
check("bottom-boot sub-sector 4 offset is +0x8000",
      at(0xFC86C3, 6) == bytes.fromhex("e9c800800000"))
# top-boot arm: base + 0x70000, +0x78000, +0x7A000, +0x7C000, guarded by cp XIX,0x00EF0000
check("top-boot arm is guarded by `cp XIX,0x00EF0000`",
      at(0xFC86CF, 6) == bytes.fromhex("eccf0000ef00"))
tops = [(0xFC86DA, 0x00070000), (0xFC86E7, 0x00078000),
        (0xFC86F4, 0x0007A000), (0xFC8701, 0x0007C000)]
for a, want in tops:
    got = at(a, 6)
    val = got[2] | (got[3] << 8) | (got[4] << 16) | (got[5] << 24)
    check("top-boot sub-sector offset +0x%05X" % want, got[:2] == bytes([0xE9, 0xC8]) and val == want)

# The two maps as SIZES, and the total.  This is the check that matters: it is the internal
# corroboration of the 512 KiB flash window that FINDINGS-memory-map.md establishes separately.
bot = [0x0000, 0x4000, 0x6000, 0x8000, 0x10000]
top = [0x70000, 0x78000, 0x7A000, 0x7C000, 0x80000]
bot_sizes = [bot[i + 1] - bot[i] for i in range(4)]
top_sizes = [top[i + 1] - top[i] for i in range(4)]
check("bottom-boot block splits 64 KiB as 16K/8K/8K/32K",
      bot_sizes == [0x4000, 0x2000, 0x2000, 0x8000], str([hex(x) for x in bot_sizes]))
check("top-boot block splits 64 KiB as 32K/8K/8K/16K",
      top_sizes == [0x8000, 0x2000, 0x2000, 0x4000], str([hex(x) for x in top_sizes]))
check("the two maps are mirror images of each other", bot_sizes == top_sizes[::-1])
check("top-boot block starts at 0x70000, so 7 x 64 KiB precede it -> 512 KiB total",
      0x70000 // 0x10000 == 7 and top[-1] == 0x80000)

# ---------------------------------------------------------------- staging buffer
# `ld XIX,0x00010000` = 44 00 00 01 00 ; `and XIY,0x00ff0000` = ed cc 00 00 ff 00
for a in (0xFC8903, 0xFC8945, 0xFC89B3):
    check("0x%06X sets the staging buffer base to 0x00010000" % a,
          at(a, 5) == bytes.fromhex("4400000100"))
for a in (0xFC8908, 0xFC8951, 0xFC8992, 0xFC89B8):
    check("0x%06X masks the flash address to a 64 KiB sector (and 0x00FF0000)" % a,
          at(a, 6) == bytes.fromhex("edcc0000ff00"))
check("0xFC8656 masks the sector-erase argument the same way",
      at(0xFC8656, 5) == bytes.fromhex("4000 00ff 00".replace(" ", "")) and at(0xFC865B, 2) == bytes([0xE8, 0xC4]))

# the RAM window a caller-supplied flash address maps to: addr - 0x00E70000
for a in (0xFC87AE, 0xFC881B, 0xFC8851):
    check("0x%06X computes the buffer address as (flash address - 0x00E70000)" % a,
          at(a, 6) == bytes.fromhex("e9ca0000e700"))
check("that formula equals 0x00010000 + (addr - 0x00E80000)",
      0xE80000 - 0xE70000 == 0x010000)

# ---------------------------------------------------------------- loop counts and widths
# `ld BC,imm16` = 31 lo hi ; djnz prefix + 1C + disp8
check("0xFC890E sets BC = 0x8000 for the whole-sector program loop",
      at(0xFC890E, 3) == bytes([0x31, 0x00, 0x80]))
check("0xFC8935 counts that loop with the 16-bit BC (prefix 0xD9)",
      at(0xFC8935, 2) == bytes([0xD9, 0x1C]))
check("  -> 0x8000 words x 2 bytes = 65,536 bytes = one whole 64 KiB sector",
      0x8000 * 2 == 0x10000)

check("0xFC8962 sets BC = 0x0200 for the slice program loop",
      at(0xFC8962, 3) == bytes([0x31, 0x00, 0x02]))
check("0xFC8989 counts that loop with the 16-bit BC (prefix 0xD9)",
      at(0xFC8989, 2) == bytes([0xD9, 0x1C]))
check("0xFC8959 shifts the slice index left by 10 (`sll 0x0a,WA`)",
      at(0xFC8959, 3) == bytes([0xD8, 0xEE, 0x0A]))
check("  -> 0x200 words x 2 bytes = 1,024 = the 1 << 10 the index is scaled by",
      0x200 * 2 == 1 << 10)

check("0xFC8998 sets BC = 0x4000 in the blank check",
      at(0xFC8998, 3) == bytes([0x31, 0x00, 0x40]))
check("★ 0xFC89A5 counts that loop with the 8-BIT register B (prefix 0xCA), not BC",
      at(0xFC89A5, 2) == bytes([0xCA, 0x1C]))
check("  -> B is the HIGH byte of BC, so the count is 0x40 = 64, not 0x4000",
      (0x4000 >> 8) == 0x40)
check("  -> 64 iterations of a 32-bit compare = the FIRST 256 BYTES of the sector only",
      64 * 4 == 256)
check("0xFC899B loads XWA = 0xFFFFFFFF, the value each long is compared against",
      at(0xFC899B, 5) == bytes.fromhex("40ffffffff"))

check("0xFC89BE sets BC = 0x8000 for the sector->buffer copy",
      at(0xFC89BE, 3) == bytes([0x31, 0x00, 0x80]))
check("0xFC89C1 is LDIRW (95 11): destination XIX, source XIY, BC words",
      at(0xFC89C1, 2) == bytes([0x95, 0x11]))
check("  -> 0x8000 words = 65,536 bytes = one whole 64 KiB sector", 0x8000 * 2 == 0x10000)

# ---------------------------------------------------------------- the DSP trampoline
check("0xFC871A takes the address of DSP_ChannelRegs_Write8 (0x00F9804A)",
      at(0xFC871A, 5) == bytes([0xF2, 0x4A, 0x80, 0xF9, 0x34]))
chans = [(0xFC8725, 0), (0xFC8736, 1), (0xFC8747, 2), (0xFC8758, 3)]
for a, n in chans:
    check("0x%06X pushes channel %d" % (a, n), at(a, 3) == bytes([0x0B, n, 0x00]))
check("0xFC8763 drops 0x18 = 24 = 4 calls x 6 argument bytes",
      at(0xFC8763, 6) == bytes.fromhex("efc818000000") and 4 * 6 == 0x18)

print()
if FAILS:
    print("FAILURES: %d" % len(FAILS))
    for f in FAILS:
        print("   " + f)
    sys.exit(1)
print("ALL CHECKS PASS")
