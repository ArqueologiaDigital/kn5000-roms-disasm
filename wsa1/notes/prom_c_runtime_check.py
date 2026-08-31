#!/usr/bin/env python3
"""Do the EEPROM driver and the soft-float runtime really say what their headers claim?

QUESTION IT ANSWERS
  "Every number quoted for prom_c 0xFC89C5-0xFC8BB1 (the serial EEPROM driver) and
   0xFCA0BA-0xFCB27D (the compiler runtime) -- is it in the ROM?"

  It reads `original_ROMs/wsa1_prom_c.ic28` and matches BYTES, never a disassembly,
  so nothing it asserts depends on unidasm or on llvm-mc.  Every check prints; the
  script exits non-zero if any fails.

WHAT IT CHECKS
  EEPROM   the four Microwire command words and the frame lengths that make them
           a 1+2+6 instruction; the three port bits and which of them is only ever
           READ; the 31/0x1F/0x20 word layout, the 0x5AA5 magic and the fact that
           the RAM shadow ends exactly where RamImage_Copy's destination begins;
           the write path's ready poll; the delay constants.
  RUNTIME  that the module is EXACTLY 38 routines, that each ends in `retd`, that
           the retd operands are what the headers say, that the routines tile
           0xFCA0BA-0xFCB27D with no gap, and that the module ends where the
           double constant pool begins; the seven IEEE-754 bias constants the
           identifications rest on; that Float32_Multiply contains two calls to
           Float32_Divide and no arithmetic; and that 0xFCB4E6 is float32 1.0.

RUN
  python3 notes/prom_c_runtime_check.py

WHAT IT CANNOT DO
  It cannot show that a routine computes what its name says -- only that the bytes
  the argument rests on are there.  The arguments themselves are in the headers.
"""
import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28"), "rb").read()
BASE = 0xF80000

fails = []


def at(a, n):
    return ROM[a - BASE:a - BASE + n]


def check(cond, what):
    print("  %-5s %s" % ("ok" if cond else "FAIL", what))
    if not cond:
        fails.append(what)


def find_all(pat, lo, hi):
    out, i = [], lo - BASE
    end = hi - BASE
    while True:
        j = ROM.find(pat, i, end)
        if j < 0:
            return out
        out.append(BASE + j)
        i = j + 1


# ---------------------------------------------------------------- EEPROM ----
print("EEPROM driver, prom_c 0xFC89C5-0xFC8BB1")

# `ldw de,imm16` = 32 lo hi ; `ldw h,imm8` = 26 nn ; `or de,imm16` = da ce lo hi
check(at(0xFC89C7, 3) == b"\x32\x30\x01", "EWEN sends 0x0130  (`ldw de,0x0130` at 0xFC89C7)")
check(at(0xFC89F9, 3) == b"\x32\x00\x01", "EWDS sends 0x0100  (`ldw de,0x0100` at 0xFC89F9)")
check(at(0xFC8A32, 4) == b"\xda\xce\x80\x01", "READ  ors 0x0180  (`or de,0x0180` at 0xFC8A32)")
check(at(0xFC8A6C, 4) == b"\xda\xce\x40\x01", "WRITE ors 0x0140  (`or de,0x0140` at 0xFC8A6C)")
# 1 start + 2 opcode + 6 address = 9; the opcode field of each is bits 7..6
for a, cmd, name in ((0xFC89C7, 0x130, "EWEN"), (0xFC89F9, 0x100, "EWDS"),
                     (0xFC8A32, 0x180, "READ"), (0xFC8A6C, 0x140, "WRITE")):
    check((cmd >> 8) == 1, "%s has the Microwire START bit set (bit 8 of 0x%03X)" % (name, cmd))
op = {0x130: 0, 0x100: 0, 0x180: 2, 0x140: 1}
for cmd, want in op.items():
    check(((cmd >> 6) & 3) == want, "0x%03X opcode field = %d" % (cmd, want))
check(((0x130 >> 4) & 3) == 3 and ((0x100 >> 4) & 3) == 0,
      "EWEN/EWDS are told apart by address bits 5..4 (11 vs 00), as Microwire specifies")

for a, n, what in ((0xFC89CD, 9, "EWEN"), (0xFC89FF, 9, "EWDS"),
                   (0xFC8A39, 9, "READ command"), (0xFC8A73, 9, "WRITE command"),
                   (0xFC8A9A, 16, "WRITE data"), (0xFC8AE1, 16, "read-back data")):
    check(at(a, 2) == bytes([0x26, n]), "%s is %d bits (`ldb h,%d` at 0x%06X)" % (what, n, n, a))

# the three port bits: `set/res b,(0x12|0x18)` = f0 <sfr> <b0|b8+bit>
SET6_5, RES6_5 = b"\xf0\x12\xbd", b"\xf0\x12\xb5"
SET8_3, RES8_3 = b"\xf0\x18\xbb", b"\xf0\x18\xb3"
SET8_4, RES8_4 = b"\xf0\x18\xbc", b"\xf0\x18\xb4"
BIT8_5 = b"\xf0\x18\xcd"
LO, HI = 0xFC89C5, 0xFC8BB2
cs_s, cs_r = len(find_all(SET6_5, LO, HI)), len(find_all(RES6_5, LO, HI))
sk_s, sk_r = len(find_all(SET8_3, LO, HI)), len(find_all(RES8_3, LO, HI))
di_s, di_r = len(find_all(SET8_4, LO, HI)), len(find_all(RES8_4, LO, HI))
n_do = len(find_all(BIT8_5, LO, HI))
# ⚠ These counts are DERIVED and printed, never asserted against a hand count -- a
# first draft of this script asserted 12/11/11/3 from eye and failed on all four.
print("        CS(P6.5) set=%d res=%d | SK(P8.3) set=%d res=%d | DI(P8.4) set=%d res=%d"
      " | DO(P8.5) bit-tests=%d" % (cs_s, cs_r, sk_s, sk_r, di_s, di_r, n_do))
# All three lines have exactly ONE more `res` than `set`, and all three extras are
# EEPROM_PortInit (0xFC8B9C), which parks the bus without ever driving it high.
check(cs_r == cs_s + 1 and sk_r == sk_s + 1 and di_r == di_s + 1,
      "each of CS/SK/DI has exactly one more `res` than `set` (%d/%d, %d/%d, %d/%d)"
      % (cs_r, cs_s, sk_r, sk_s, di_r, di_s))
check(at(0xFC8B9D, 9) == RES6_5 + RES8_3 + RES8_4,
      "and all three extras are EEPROM_PortInit's opening `res` trio at 0xFC8B9D")
check(cs_r - 1 == cs_s and len(find_all(RES6_5, 0xFC8B9C, 0xFC8BB2)) == 1
      and len(find_all(SET6_5, 0xFC8B9C, 0xFC8BB2)) == 0,
      "EEPROM_PortInit itself contains exactly one CS `res` and no CS `set`")
check(n_do > 0, "DO is read %d time(s) with `bit 5,(P8)`" % n_do)
for pat, name in ((b"\xf0\x18\xbd", "set 5,(P8)"), (b"\xf0\x18\xb5", "res 5,(P8)")):
    check(len(find_all(pat, LO, HI)) == 0,
          "DO is NEVER driven: no `%s` anywhere in the driver" % name)
check(cs_s + cs_r > 0 and len(find_all(b"\xf0\x12", LO, HI)) == cs_s + cs_r,
      "P6 is touched ONLY as bit 5: %d site(s), all of them CS" % (cs_s + cs_r))

# the stored block
check(at(0xFC8B4F, 4) == b"\xdb\xcf\x1f\x00", "31 data words: `cp HL,0x001F` at 0xFC8B4F")
check(at(0xFC8B6B, 4) == b"\xd8\xcf\xa5\x5a", "magic 0x5AA5: `cp WA,0x5AA5` at 0xFC8B6B")
check(at(0xFC8B2C, 5) == b"\xf2\xa1\xe2\x00\x31", "shadow at 0x00E2A1: `lda XBC,0x00E2A1` at 0xFC8B2C")
check(0x00E2A1 + 31 * 2 == 0x00E2DF, "0x00E2A1 + 31*2 = 0x00E2DF, RamImage_Copy's destination")
check(at(0xF989F4, 5) == b"\xf2\xdf\xe2\x00\x34", "... and RamImage_Copy really loads 0x00E2DF")
check(at(0xFC8AC1, 2) == b"\x26\x20", "post-write settle = 32 counts (`ldb h,0x20` at 0xFC8AC1)")
check(at(0xFC8BA6, 3) == b"\x33\x70\x17", "EEPROM_PortInit delay = 0x1770 = 6000 (0xFC8BA6)")
check(at(0xFC8B91, 4) == b"\xdb\xcf\x1f\x00", "EEPROM_WriteIndexPattern writes 31 words (0xFC8B91)")
check(at(0xFC8BB1, 1) == b"\x0e", "0xFC8BB1 is a single 0x0E pad byte")

# ------------------------------------------------------------- RUNTIME ----
print()
print("compiler runtime, prom_c 0xFCA0BA-0xFCB27D")

# `retd imm16` = 0f lo hi.  Walk the module and collect them.
RUNTIME_LO, RUNTIME_HI = 0xFCA0BA, 0xFCB27E
retds = []
i = RUNTIME_LO
while i < RUNTIME_HI:
    j = ROM.find(b"\x0f", i - BASE, RUNTIME_HI - BASE)
    if j < 0:
        break
    a = BASE + j
    lo, hi = ROM[j + 1], ROM[j + 2]
    if hi == 0 and lo in (2, 4, 6, 8, 0x10):
        retds.append((a, lo))
        i = a + 3
    else:
        i = a + 1

EXPECT = [
    (0xFCA0BA, 4, "Shift16_Left"), (0xFCA0DB, 6, "Shift32_LogicalRight"),
    (0xFCA0FE, 6, "Shift32_Left"), (0xFCA121, 0x10, "Double_Compare"),
    (0xFCA1B6, 8, "Double_Negate"), (0xFCA1E5, 8, "Double_Classify"),
    (0xFCA252, 0x10, "Double_Multiply"), (0xFCA41F, 0x10, "Double_Add"),
    (0xFCA626, 0x10, "Double_Subtract"), (0xFCA661, 8, "Double_ToInt32"),
    (0xFCA6FD, 4, "Int32_ToDouble"), (0xFCA746, 4, "UInt32_ToDouble"),
    (0xFCA7A5, 0x10, "Double_Divide"), (0xFCA903, 8, "Double_ToInt16"),
    (0xFCA997, 2, "Int16_ToDouble"), (0xFCA9CF, 2, "UInt16_ToDouble"),
    (0xFCAA2F, 4, "Shift16_ArithRight"), (0xFCAA50, 4, "Float32_ToDouble"),
    (0xFCAB06, 6, "Shift32_ArithRight"), (0xFCAB29, 4, "Float32_ToInt32"),
    (0xFCABC6, 4, "Int32_ToFloat32"), (0xFCAC00, 4, "UInt32_ToFloat32"),
    (0xFCAC52, 8, "Float32_Add"), (0xFCADD6, 8, "Double_ToFloat32"),
    (0xFCAE60, 8, "Float32_Divide"), (0xFCAF8B, 2, "Int16_ToFloat32"),
    (0xFCAFB4, 2, "UInt16_ToFloat32"), (0xFCB005, 8, "Float32_Multiply"),
    (0xFCB02B, 8, "Float32_Subtract"), (0xFCB04A, 4, "Float32_Negate"),
    (0xFCB075, 4, "Float32_Classify"), (0xFCB0D3, 8, "Multiply32_Signed"),
    (0xFCB11B, 8, "Multiply32"), (0xFCB141, 8, "Divide32_Signed"),
    (0xFCB189, 8, "Divide32"), (0xFCB1BF, 8, "Float32_Compare"),
    (0xFCB23C, 4, "Shift8_LogicalRight"), (0xFCB25D, 4, "Shift8_Left"),
]
check(len(retds) == 38, "the module holds exactly 38 `retd` instructions (found %d)" % len(retds))
check(len(EXPECT) == 38, "the header table names exactly 38 routines")
ok_tile = True
for k, (start, argbytes, name) in enumerate(EXPECT):
    ra, rn = retds[k] if k < len(retds) else (0, -1)
    if rn != argbytes:
        ok_tile = False
        print("        %-24s expected retd 0x%02X, ROM has 0x%02X" % (name, argbytes, rn))
    nxt = EXPECT[k + 1][0] if k + 1 < len(EXPECT) else RUNTIME_HI
    if ra + 3 != nxt:
        ok_tile = False
        print("        %-24s ends at 0x%06X, next starts at 0x%06X" % (name, ra + 3, nxt))
check(ok_tile, "every routine's `retd` operand matches its header AND each ends exactly "
               "where the next begins (0xFCA0BA-0xFCB27D, no gap)")
check(retds[-1][0] + 3 == 0xFCB27E,
      "the last `retd` ends at 0xFCB27E, where the double constant pool begins")

# the seven bias constants the identifications rest on
BIAS = [
    (0xFCA2A3, b"\xdc\xca\xfe\x03", "Double_Multiply  `sub IX,0x03FE`   = 1023 - 1"),
    (0xFCA814, b"\xd8\xc8\x34\x04", "Double_Divide    `add WA,0x0434`   = 1023 + 53"),
    (0xFCAEDE, b"\xd8\xc8\x97\x00", "Float32_Divide   `add WA,0x0097`   = 127 + 24"),
    (0xFCADF9, b"\xd8\xca\x80\x03", "Double_ToFloat32 `sub WA,0x0380`   = 1023 - 127"),
    (0xFCA75A, b"\x32\x13\x04", "UInt32_ToDouble  starts at 0x0413  = 1023 + 20"),
    (0xFCA9E4, b"\x32\x03\x04", "UInt16_ToDouble  starts at 0x0403  = 1023 + 4"),
    (0xFCAC15, b"\x32\x96\x00", "UInt32_ToFloat32 starts at 0x0096  = 127 + 23"),
]
for a, pat, what in BIAS:
    check(at(a, len(pat)) == pat, what + "   (0x%06X)" % a)
check(0x3FE == 1023 - 1 and 0x434 == 1023 + 53 and 0x97 == 127 + 24
      and 0x380 == 1023 - 127 and 0x413 == 1023 + 20 and 0x403 == 1023 + 4
      and 0x96 == 127 + 23, "and those seven values really are those bias expressions")

# Float32_Multiply: two calls to Float32_Divide, one constant, no arithmetic
body = at(0xFCB005, 0xFCB02B - 0xFCB005)
calls = [i for i in range(len(body) - 3) if body[i] == 0x1D]
tgt = [struct.unpack("<I", body[i + 1:i + 4] + b"\x00")[0] for i in calls]
check(tgt == [0xFCAE60, 0xFCAE60],
      "Float32_Multiply's only two `call`s both go to Float32_Divide")
check(at(0xFCB009, 5) == b"\xe2\xe6\xb4\xfc\x21",
      "... and it loads the constant at 0xFCB4E6 (`ld XBC,(0xFCB4E6)` at 0xFCB009)")
c = at(0xFCB4E6, 4)
check(c == b"\x00\x00\x80\x3f" and struct.unpack("<f", c)[0] == 1.0,
      "0xFCB4E6 = 00 00 80 3F = IEEE-754 single 1.0")
check(len(body) == 0x26, "Float32_Multiply is 38 bytes -- loads, pushes and those two calls")

# the six signed/unsigned wrapper pairs: the unsigned kernel is called from exactly
# ONE place in the whole image, and that place is inside its signed wrapper.
PAIRS = [(0xFCA6FD, 0xFCA746, "Int32_ToDouble / UInt32_ToDouble"),
         (0xFCA997, 0xFCA9CF, "Int16_ToDouble / UInt16_ToDouble"),
         (0xFCABC6, 0xFCAC00, "Int32_ToFloat32 / UInt32_ToFloat32"),
         (0xFCAF8B, 0xFCAFB4, "Int16_ToFloat32 / UInt16_ToFloat32"),
         (0xFCB0D3, 0xFCB11B, "Multiply32_Signed / Multiply32"),
         (0xFCB141, 0xFCB189, "Divide32_Signed / Divide32")]
ENDS = dict((a, b) for (a, _, __), b in zip(EXPECT, [e[0] for e in EXPECT[1:]] + [RUNTIME_HI]))
for wrapper, kernel, what in PAIRS:
    lit = struct.pack("<I", kernel)[:3]
    sites = [a for a in find_all(b"\x1d" + lit, BASE, BASE + len(ROM))]
    inside = [a for a in sites if wrapper <= a < ENDS[wrapper]]
    # ⚠ EXACTLY ONE call INSIDE the wrapper is the invariant that survives; being the
    # wrapper's ONLY caller image-wide does not.  Multiply32 is called from 28 places
    # -- it is a general 32x32 helper as well as Multiply32_Signed's kernel -- and a
    # first draft of this check asserted "one site image-wide" and failed on it.
    check(len(inside) == 1,
          "%s: the kernel is called exactly once from inside its wrapper "
          "(%d image-wide, %d inside)" % (what, len(sites), len(inside)))

# how heavily the runtime is used, image-wide.  A `call` to any of the 38 entries is
# the four bytes 1D <24-bit little-endian target>, so this is a byte census and does
# not depend on a disassembler.
#
# *** UPPER BOUND, NOT A COUNT (round-2 audit F12) ***
# The scan runs over EVERY byte offset of the image with no instruction-boundary
# filter, so a 0x1D that is itself the operand byte of some other instruction, followed
# by three bytes that happen to spell one of the 38 entry addresses, is indistinguishable
# from a real call.  The sibling tools (prom_a_call_graph.py, prom_b_call_graph.py,
# gen_prom_b_songstore_module.py's direct_refs) label the identical scan an upper bound
# and this one printed it as a measured total, which is the error being corrected here.
# The figure is probably very close -- a 4-byte coincidence is rare and two independent
# spot checks landed exactly (Double_Compare 37, Float32_Divide 2) -- but "probably very
# close" is not "measured", and this tree's history is exactly that distinction.
# The assertion is kept as a REGRESSION check on the census, not as a claim of truth.
total = 0
per = []
for start, _, name in EXPECT:
    n = len(find_all(b"\x1d" + struct.pack("<I", start)[:3], BASE, BASE + len(ROM)))
    per.append((n, name))
    total += n
per.sort(reverse=True)
print("        busiest: " + ", ".join("%s %d" % (nm, n) for n, nm in per[:6]))
check(total == 1274,
      "1,274 `1D <target>` byte sites for the 38 runtime entries, image-wide -- an "
      "UPPER BOUND on the call count, not a decode (found %d)" % total)
check(all(n > 0 for n, _ in per), "every one of the 38 entries has at least one caller")

# the double constant pool the math library (still .incbin) reads
POOL = [(0xFCB27E, 1.5707963267948966, "pi/2"), (0xFCB286, 1.0, "1.0"),
        (0xFCB28E, 0.0, "0.0"), (0xFCB29E, 3.141592653589793, "pi"),
        (0xFCB2A6, 0.5, "0.5"), (0xFCB2AE, 0.3183098861837907, "1/pi")]
for a, v, name in POOL:
    got = struct.unpack("<d", at(a, 8))[0]
    check(got == v, "0x%06X decodes as the double %s (%r)" % (a, name, got))

print()
if fails:
    print("FAILED %d check(s)" % len(fails))
    sys.exit(1)
print("ALL CHECKS PASS")
