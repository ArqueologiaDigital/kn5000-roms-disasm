#!/usr/bin/env python3
"""Every number quoted in the prom_b 0xF5B800-0xF5BBE6 headers, re-derived.

QUESTION IT ANSWERS
    "Is each figure in those two blocks' seven headers actually true of the
    ROM?"  Covers 0xF5B800-0xF5B8B5 (four stack-argument veneers) and
    0xF5BAB8-0xF5BBE6 (two screen painters and a third SWI7 veneer).
    The byte gate proves the LISTING rebuilds the ROM; it is blind to every
    claim in a comment.  This is the substitute for that block.

RUN
    python3 notes/prom_b_f5b800_checks.py            # one PASS/FAIL per claim
    python3 notes/prom_b_f5b800_checks.py --verbose
Exit status is non-zero if any claim fails.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
A = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
B = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
A_BASE, B_BASE = 0xF80000, 0xF00000

FAILS = []


def check(what, got, want):
    ok = got == want
    if not ok:
        FAILS.append("%s: got %r, want %r" % (what, got, want))
    print("  %-62s %-26s %s" % (what, repr(got)[:26], "OK" if ok else "FAIL"))


def gb(a, n):
    return B[a - B_BASE:a - B_BASE + n]


def ga(a, n):
    return A[a - A_BASE:a - A_BASE + n]


def refs(slot):
    """(prom_a, prom_b) opcode-anchored upper bound on references to a thunk
    slot: `1D`/`1B` + the slot's 24-bit address, at every byte offset."""
    n = 0, 0
    for op in (0x1D, 0x1B):
        pat = bytes([op]) + slot.to_bytes(3, "little")
        n = (n[0] + A.count(pat), n[1] + B.count(pat))
    return n


print("-- the four thunk slots and their reference upper bounds")
SLOTS = {0xF43330: 0xF5B800, 0xF41EEC: 0xF5B81C,
         0xF41EE4: 0xF5B84C, 0xF41EE8: 0xF5B881}
for slot, tgt in SLOTS.items():
    raw = gb(slot, 4)
    check("T_%06X targets 0x%06X" % (slot, tgt),
          (raw[0], int.from_bytes(raw[1:4], "little")), (0x1B, tgt))
counts = {s: refs(s) for s in SLOTS}
check("T_F43330 refs (prom_a, prom_b)", counts[0xF43330], (6, 2))
check("T_F41EEC refs (prom_a, prom_b)", counts[0xF41EEC], (1, 0))
check("T_F41EE4 refs (prom_a, prom_b)", counts[0xF41EE4], (23, 0))
check("T_F41EE8 refs (prom_a, prom_b)", counts[0xF41EE8], (9, 0))
check("total references", sum(sum(v) for v in counts.values()), 41)
check("of which in prom_a", sum(v[0] for v in counts.values()), 39)
check("of which in prom_b", sum(v[1] for v in counts.values()), 2)
check("the two line wrappers alone",
      sum(sum(counts[s]) for s in (0xF41EE4, 0xF41EE8)), 32)

print("-- the 13-byte label table at 0xF33022")
T = 0xF33022
check("mask in the code is `and A,0x3F`", gb(0xF5B804, 3), b"\xc9\xcc\x3f")
check("stride in the code is `mul A,0x0D`", gb(0xF5B807, 3), b"\xc9\x08\x0d")
check("copy length in the code is `ld BC,0x000D`", gb(0xF5B816, 3),
      b"\x31\x0d\x00")
check("destination is `ld XIX,0x000022F0`", gb(0xF5B811, 5),
      b"\x44\xf0\x22\x00\x00")
check("0xF33022 + 64*13", "0x%06X" % (T + 64 * 13), "0xF33362")
check("entry 0", gb(T, 13), b"-------------")
check("entry 49", gb(T + 49 * 13, 13), b"REV DYNAMIC  ")
check("LAST entry 63", gb(T + 63 * 13, 13), b"           63")
# The independent entry-count bound, taken from the ROM's OWN mask and stride
# bytes rather than from literals typed here.  (An earlier revision of this
# check compared 0x3F with 63 -- arithmetic on two constants, which cannot
# fail.  That is round-1 audit finding F13's defect; do not reintroduce it.)
mask = gb(0xF5B804, 3)[2]          # the operand of `and A,0x3F`
stride = gb(0xF5B807, 3)[2]        # the operand of `mul A,0x0D`
check("entry count the mask permits (mask+1)", mask + 1, 64)
check("table size (mask+1)*stride", (mask + 1) * stride, 832)
check("table end from the ROM's own mask and stride",
      "0x%06X" % (T + (mask + 1) * stride), "0xF33362")
check("stride equals the ldir length", stride,
      int.from_bytes(gb(0xF5B816, 3)[1:3], "little"))

print("-- the two line veneers are one routine with one byte changed")
x, y = gb(0xF5B84C, 53), gb(0xF5B881, 53)
d = [i for i, (p, q) in enumerate(zip(x, y)) if p != q]
check("both veneers are 53 bytes", (len(x), len(y)), (53, 53))
check("differing byte offsets", d, [43])
check("the differing byte (solid, dashed)", (x[43], y[43]), (0x00, 0x15))
check("identical bytes of 53", 53 - len(d), 52)
check("(0x2540) store is the 8-bit form `F1 40 25 00 00`",
      gb(0xF5B871, 5), b"\xf1\x40\x25\x00\x00")

print("-- the SWI7 services those two veneers invoke")
ST = 0xF8E9C6
for svc, want in ((0x00, 0xF8EAC7), (0x15, 0xF900B0)):
    o = ST - A_BASE + svc * 4
    check("SWI7 slot 0x%02X" % svc,
          "0x%06X" % int.from_bytes(A[o:o + 4], "little"), "0x%06X" % want)

print("-- T_F40F40's callee, prom_a 0xF86AC7 (UNCONVERTED -- shape only)")
check("T_F40F40 targets 0xF86AC7", gb(0xF40F40, 4), b"\x1b\xc7\x6a\xf8")
check("list base `ld XHL,0x00002030`", ga(0xF86AC7, 5), b"\x43\x30\x20\x00\x00")
check("terminator test `cp (XHL),0xFF`", ga(0xF86ACC, 3), b"\x83\x3f\xff")
check("step `add HL,0x0004`", ga(0xF86AD1, 4), b"\xdb\xc8\x04\x00")
check("upper bound `cp XHL,0x0000206B`", ga(0xF86AD7, 6),
      b"\xeb\xcf\x6b\x20\x00\x00")
check("slots from 0x2030 to the last accepted, step 4",
      (0x206B - 0x2030) // 4 + 1, 15)

print("-- 0xF5BAB8-0xF5BBE6: the two painters and the third veneer")
SLOTS2 = {0xF41ED8: 0xF5BAB8, 0xF41EDC: 0xF5BB00, 0xF41EE0: 0xF5BBB2}
for slot, tgt in SLOTS2.items():
    raw = gb(slot, 4)
    check("T_%06X targets 0x%06X" % (slot, tgt),
          (raw[0], int.from_bytes(raw[1:4], "little")), (0x1B, tgt))
check("T_F41ED8 refs (prom_a, prom_b)", refs(0xF41ED8), (1, 0))
check("T_F41EDC refs -- NO caller found anywhere", refs(0xF41EDC), (0, 0))
check("T_F41EE0 refs (prom_a, prom_b)", refs(0xF41EE0), (7, 0))

# the UI engine thunk
check("T_F417F0 targets DisplayList_Run 0xF31A09", gb(0xF417F0, 4),
      b"\x1b\x09\x1a\xf3")
check("T_F417F0 reference upper bound", sum(refs(0xF417F0)), 392)

# the layer byte takes BOTH values in this block -- the whole point of the
# banner's claim about (0x2540).  Addresses are instruction starts.
for a in (0xF5BABF, 0xF5BB0E, 0xF5BB25):
    check("(0x2540) <- 0 at 0x%06X" % a, gb(a, 5), b"\xf1\x40\x25\x00\x00")
for a in (0xF5BAE5, 0xF5BB8E):
    check("(0x2540) <- 1 at 0x%06X" % a, gb(a, 5), b"\xf1\x40\x25\x00\x01")

# the draw/erase pair: same four operand words, different op
check("DL_F02FD9 op and length", gb(0xF02FD9, 2), b"\x05\x0a")
check("DL_F02FE3 op and length", gb(0xF02FE3, 2), b"\x1b\x0a")
check("their four operand words are identical",
      gb(0xF02FD9 + 2, 8), gb(0xF02FE3 + 2, 8))
check("and those words are 8, 0x21, 0x28, 0x2C",
      [int.from_bytes(gb(0xF02FD9 + 2 + 2 * i, 2), "little") for i in range(4)],
      [0x0008, 0x0021, 0x0028, 0x002C])

# the two self-terminating pointer tables
for base, want in ((0xF02F52, [0xF02F22, 0xF02F36, 0xF02F3D, 0xF02F44,
                               0xF02F4B, 0xF02F52]),
                   (0xF02F9A, [0xF02F6A, 0xF02F6A, 0xF02F76, 0xF02F82,
                               0xF02F8E, 0xF02F9A])):
    got = [int.from_bytes(gb(base + 4 * i, 4), "little") for i in range(6)]
    check("table 0x%06X, 6 entries" % base, got, want)
    check("  its LAST entry is its own base", got[-1], base)
    # ...and that is exactly one past the end of the list entry 4 starts,
    # taken from THAT RECORD'S OWN LENGTH BYTE.  (Comparing got[-1] with base
    # a second time would be the same assertion twice; this one can fail.)
    last_list = got[4]
    reclen = gb(last_list + 1, 1)[0]
    check("  last list 0x%06X + its length byte %d" % (last_list, reclen),
          "0x%06X" % (last_list + reclen), "0x%06X" % base)
check("the '1st' row is op 0x20, 7 bytes, one word, ASCII",
      gb(0xF02F36, 7), b"\x20\x07\x91\x0b1st")
check("LAST of the four ordinal rows is '4th'", gb(0xF02F4B, 7),
      b"\x20\x07\x11\x1d4th")
check("the 0xF02F9A rows carry 32-bit pointers",
      [int.from_bytes(gb(a + 2, 4), "little")
       for a in (0xF02F6A, 0xF02F76, 0xF02F82, 0xF02F8E)],
      [0xF0191A, 0xF01938, 0xF01956, 0xF01974])

# the bit-select arithmetic, read off the code rather than asserted
check("`ld A,C` / `sla 0x01,A` / `dec 1,A` / `srl A,W`",
      gb(0xF5BB3E, 9), b"\xcb\x89\xc9\xec\x01\xc9\x69\xc8\xff")
# The derivation "count = 2C-1" rests on the MNEMONICS, so check the
# mnemonics -- as the byte-verified transcription in the .s spells them, which
# is the same text llvm_roundtrip_autoforce.py proved reassembles to these
# bytes.  (An earlier draft "checked" [2*c-1 for c in 1..4] == [1,3,5,7]:
# arithmetic on literals, round-1 audit finding F13's cannot-fail defect.)
SRC = image_path(ROOT, "prom_b/wsa1_prom_b.s")
seq = []
for line in open(SRC):
    m = re.search(r";\s*(F5BB3[EF]|F5BB4[0-9A-F])\s+(.*?)(?:\s+\[llvm-mc.*)?$",
                  line.rstrip("\n"))
    if m:
        seq.append((m.group(1), m.group(2).strip()))
seq = sorted(set(seq))[:4]
check("the four instructions that build the shift count",
      [t for _, t in seq],
      ["ld A,C", "sla 0x01,A", "dec 1,A", "srl A,W"])

# the third veneer
z = gb(0xF5BBB2, 53)
d3 = [i for i, (p_, q_) in enumerate(zip(x, z)) if p_ != q_]
check("Gfx_EraseRect vs Gfx_DrawLine_Solid: differing offsets", d3, [43])
check("  the differing byte (solid, erase)", (x[43], z[43]), (0x00, 0x1B))
check("  identical bytes of 53", 53 - len(d3), 52)
SVC = 0xF8E9C6
check("SWI7 slot 0x1B",
      "0x%06X" % int.from_bytes(
          A[SVC - A_BASE + 0x1B * 4:SVC - A_BASE + 0x1B * 4 + 4], "little"),
      "0xF8F8BD")

print()
if FAILS:
    for f in FAILS:
        print("FAILED: " + f)
    print("%d of the blocks' claims do NOT hold." % len(FAILS))
    sys.exit(1)
print("all claims in the 0xF5B800-0xF5B8B5 and 0xF5BAB8-0xF5BBE6 headers hold.")
