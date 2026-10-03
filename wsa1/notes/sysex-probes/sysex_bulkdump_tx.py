#!/usr/bin/env python3
"""What does the WSA1R put on the wire when SYSEX BULK DUMP -> SEND is pressed?

Re-derives, from the two original ROM images alone, every number the
transmit-path write-up quotes:

  * the five UI job codes and which dump routine each one runs;
  * the nine literal SysEx templates the transmitter prepends, and the
    21-bit address / size the six septets in each one spell;
  * the RAM (or streamed-block) extent each template describes, read back
    out of the prom_a instruction stream as immediates;
  * the checksum's two-byte tail literal, the block cap and the chunk size.

Run:  python3 wsa1/notes/sysex-probes/sysex_bulkdump_tx.py
      python3 wsa1/notes/sysex-probes/sysex_bulkdump_tx.py --frames

Pass criterion: every assert is silent and the script prints OK.
The interesting asserts are the three CONSECUTIVE-ADDRESS ones: for each
category that is sent in two or three parts, the septet address of part
N+1 minus that of part N must equal the septet SIZE of part N.  Those three
independent agreements are what establish that the six bytes after the
model id really are <address><size>, each an MSB-first 21-bit septet triple,
counted in SOURCE bytes (not in transmitted nibbles).
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROMS = os.path.normpath(os.path.join(HERE, "..", "..", "original_ROMs"))

PROM_A_BASE = 0xF80000          # wsa1_prom_a.ic12
PROM_B_BASE = 0xF00000          # wsa1_prom_b.ic13


def load(name, base, size=0x80000):
    data = open(os.path.join(ROMS, name), "rb").read()
    assert len(data) == size, (name, hex(len(data)))
    return data, base


A, AB = load("wsa1_prom_a.ic12", PROM_A_BASE)
B, BB = load("wsa1_prom_b.ic13", PROM_B_BASE)


def a(addr, n=1):
    return A[addr - AB:addr - AB + n]


def b(addr, n=1):
    return B[addr - BB:addr - BB + n]


def le32(buf, off=0):
    return int.from_bytes(buf[off:off + 4], "little")


# ---------------------------------------------------------------- load base
# Both bases are asserted, not assumed.  prom_b must carry the literal
# template block; prom_a must carry the UI job-code table.
assert b(0xF4FEB4, 5) == bytes([0xF0, 0x50, 0x23, 0x7E, 0xF7]), "prom_b base wrong"
assert a(0xF99AE3, 8) == bytes([0, 3, 5, 4, 2, 0, 0, 0]), "prom_a base wrong"


# ------------------------------------------------- 1. the UI -> job mapping
# prom_a 0xF99A9E reads (0x2720), masks it with 7, and indexes the 8-byte
# table at 0xF99AE3; the result becomes (0x60F802) | 0x80 and prom_b thunk
# T_F408E4 (0xF408E4 -> prom_a 0xFB2049) runs it.  0xFB2049 masks with 7,
# bounds the index with `cp BC,5 / jr ugt` and jumps through JumpTable_FB2081.
ROW_NAMES = ["TOTAL KEYBOARD", "SOUND", "COMBINATION",
             "SYSTEM,PART & MIDI", "SEQUENCER"]
ROW_TO_JOB = list(a(0xF99AE3, 5))
assert ROW_TO_JOB == [0, 3, 5, 4, 2]

JUMP_FB2081 = [le32(a(0xFB2081 + 4 * i, 4)) for i in range(6)]
assert JUMP_FB2081[0] == 0xFB2099 and JUMP_FB2081[5] == 0xFB20B7
# ★ last-entry test: 0xFB2081 + 6*4 == entry 0's own target
assert 0xFB2081 + 6 * 4 == JUMP_FB2081[0]
# each arm is `call abs16/24 ; jr` -- the callee is the 3 bytes after 0x1D
JOB_ROUTINE = {}
for i, arm in enumerate(JUMP_FB2081):
    op = a(arm, 4)
    assert op[0] == 0x1D, (i, op.hex())
    JOB_ROUTINE[i] = int.from_bytes(op[1:4], "little")
assert JOB_ROUTINE == {0: 0xFB22CD, 1: 0xFB22E6, 2: 0xFB22E7,
                       3: 0xFB22F6, 4: 0xFB2305, 5: 0xFB2314}
assert a(0xFB22E6, 1) == b"\x0e", "job 1 is meant to be a bare RET"


# --------------------------------------------- 2. the transmit templates
def septets(triple):
    return (triple[0] << 14) | (triple[1] << 7) | triple[2]


# addr, name, length, what the firmware site is
TEMPLATES = [
    (0xF4FEB4, "ACK (reply)",              5, "0xFB28D9 sub_FB28BE"),
    (0xF4FEB9, "NAK (reply)",              5, "0xFB28F1 sub_FB28BE"),
    (0xF4FEBE, "end of category",          5, "0xFB279C SysExDump_SendCategoryDone"),
    (0xF4FEC3, "end of dump",              5, "0xFB27CD SysExDump_SendJobDone"),
    (0xF4FEC8, "abort / gave up",          5, "0xFB2812, 0xFB34AD, 0xFB3EBB, 0xFB51C9"),
    (0xF4FECD, "memory-full reply",        5, "0xFB28E9 sub_FB28BE"),
    (0xF4FED2, "continuation header",      3, "0xFB7034 SysExTx_AppendContHeaderIfCont"),
    (0xF4FED5, "enquiry",                  7, "0xFB2334 SysExDump_Handshake"),
    (0xF4FEDC, "start transfer",           7, "0xFB23AD SysExDump_Handshake, 0xFB2910"),
]
EXPECT = {
    0xF4FEB4: "f050237ef7", 0xF4FEB9: "f050247ef7", 0xF4FEBE: "f050277ef7",
    0xF4FEC3: "f050287ef7", 0xF4FEC8: "f050297ef7", 0xF4FECD: "f0502a7ef7",
    0xF4FED2: "f0507e",     0xF4FED5: "f050210400 11f7".replace(" ", ""),
    0xF4FEDC: "f050220400" "11f7",
}
for addr, name, ln, site in TEMPLATES:
    got = b(addr, ln).hex()
    assert got == EXPECT[addr], (hex(addr), got)

# The six-septet data headers.  Each is `F0 50 2D 04 00 11` + addr + size,
# except the last, whose size is appended at run time by SysExTx_AppendRemainingSize.
DATA_HEADERS = [
    # template  len  what it is                   step id  per-frame source
    #                                             (field3) descriptor, xN
    (0xF4FEF2,   6, "(bare 2C header)",           None,  None,     1),
    (0xF4FEF8,  12, "SYSTEM,PART & MIDI part 1",  0x01,  0xFB75BA, 1),
    (0xF4FF04,  12, "SYSTEM,PART & MIDI part 2",  0x02,  0xFB75E4, 1),
    (0xF4FF10,  12, "(unreferenced sibling)",     0x04,  0xFB7629, 1),
    (0xF4FF1C,  12, "SOUND",                      0x05,  0xFB7649, 32),
    (0xF4FF28,  12, "SEQUENCER part 1",           0x0B,  0xFB766F, 1),
    (0xF4FF34,  12, "SEQUENCER part 2",           0x0C,  0xFB7692, 1),
    (0xF4FF40,   9, "SEQUENCER part 3",           0x0D,  0xFB76B5, 1),
    (0xF4FF49,  12, "COMBINATION part 1",         0x0F,  0xFB76F2, 1),
    (0xF4FF55,  12, "COMBINATION part 2",         0x10,  0xFB7722, 16),
]
for addr, ln, name, step, writer, mult in DATA_HEADERS:
    head = b(addr, 6)
    assert head[:2] == b"\xf0\x50", (hex(addr), head.hex())
    assert head[2] == 0x2D or addr == 0xF4FEF2, head.hex()
    assert head[3] == 0x04 and head[4] == 0x00 and head[5] == 0x11, head.hex()

# ------- 3. the source extents, read back out of the prom_a instruction
# stream.  Each of these routines writes three longs into the struct whose
# address the caller pushes:  +0 start pointer, +4 end pointer, +8 size.
# The probe takes the literals and then CHECKS end - start == size, so a
# transcription slip in the table below cannot pass silently.
def imm24_at(addr):
    """`lda xbc,(imm24)` = F2 lo mi hi 31 (or 30/34/35 for xwa/xix/xiy)"""
    op = a(addr, 5)
    assert op[0] == 0xF2 and op[4] in (0x30, 0x31, 0x34, 0x35), (hex(addr), op.hex())
    return int.from_bytes(op[1:4], "little")


def imm32_at(addr):
    """`ld XBC,imm32` = 41 <lo..hi>"""
    op = a(addr, 5)
    assert op[0] == 0x41, (hex(addr), op.hex())
    return le32(op, 1)


EXTENTS = {
    # writer  : (start, end, size)
    0xFB75BA: (0x007600, 0x007620, 0x000020),   # SYS,PART&MIDI part 1
    0xFB75E4: (0x007620, 0x007F80, 0x000960),   # SYS,PART&MIDI part 2
    0xFB766F: (0x603400, 0x604000, 0x000C00),   # SEQUENCER part 1
    0xFB7692: (0x610000, 0x617800, 0x007800),   # SEQUENCER part 2
    0xFB76B5: (0x617800, 0x668400, 0x050C00),   # SEQUENCER part 3 (static form)
    0xFB76F2: (0x609D00, 0x60A000, 0x000300),   # COMBINATION part 1
    0xFB7722: (0x60A000, 0x60B600, 0x001600),   # COMBINATION part 2, ONE block
    0xFB7649: (0x60A000, 0x60C000, 0x002000),   # SOUND, ONE block
    0xFB7629: (0x60A000, 0x60A000, 0x000000),   # the unreferenced sibling
}
# anchor four of the nine directly in the instruction stream
assert imm24_at(0xFB7649 + 0x08) == 0x60A000
assert imm32_at(0xFB7649 + 0x17) == 0x00002000
assert imm24_at(0xFB7692 + 0x08) == 0x610000
assert imm32_at(0xFB7692 + 0x17) == 0x00007800
for w, (s_, e_, n_) in EXTENTS.items():
    assert e_ - s_ == n_, (hex(w), hex(e_ - s_), hex(n_))

# the WHOLE-category extents, written into the progress struct at 0x60FCE8
# by the five job routines; these are what the menu row measures
JOB_EXTENTS = {
    0xFB74D7: ("SYSTEM,PART & MIDI", 0x007600, 0x000980),
    0xFB751A: ("SOUND",              0x60A000, 0x040000),
    0xFB758A: ("COMBINATION",        0x609D00, 0x016300),
    0xFB753E: ("SEQUENCER",          0x603400, 0x059000),
}
assert imm24_at(0xFB751A + 0x08) == 0x60A000
assert imm32_at(0xFB751A + 0x17) == 0x00040000
# SYS,PART&MIDI total == part1 + part2
assert JOB_EXTENTS[0xFB74D7][2] == 0x20 + 0x960
# COMBINATION total == part1 + part2
assert JOB_EXTENTS[0xFB758A][2] == 0x300 + 0x16000

# ★ the headline agreement: septet SIZE == (per-frame source size x blocks).
# ⚠ ONE documented exception, and it is the one the tree already flags: the
# 0xF4FF10 template belongs to the UNREFERENCED routine at 0xFB248A, which
# passes count 0x0000 to the link read while its template still says 0x10
# bytes.  Nothing names 0xFB248A, so nothing reconciles the two.
ORPHAN = 0xF4FF10
for addr, ln, name, step, writer, mult in DATA_HEADERS:
    if ln != 12 or writer is None:
        continue
    size = septets(b(addr + 9, 3))
    if addr == ORPHAN:
        assert size == 0x10 and EXTENTS[writer][2] == 0, "orphan anomaly changed"
        continue
    assert size == EXTENTS[writer][2] * mult, (name, hex(size))

# the two block counts are literals: `ldb h,0x0f` / `ldb h,0x1f`, each one
# loop pass short because one more block follows the loop
assert a(0xFB271F, 2) == bytes([0x26, 0x0F]), "ldb h,0x0f at 0xFB271F"
assert a(0xFB2524, 2) == bytes([0x26, 0x1F]), "ldb h,0x1f at 0xFB2524"
assert (15 + 1) == 16 and (31 + 1) == 32

# ★ and the four CONSECUTIVE-ADDRESS checks
PAIRS = [("SYSTEM,PART & MIDI", 0xF4FEF8, 0xF4FF04),
         ("COMBINATION",        0xF4FF49, 0xF4FF55),
         ("SEQUENCER 1->2",     0xF4FF28, 0xF4FF34),
         ("SEQUENCER 2->3",     0xF4FF34, 0xF4FF40)]
for name, first, second in PAIRS:
    a1, s1 = septets(b(first + 6, 3)), septets(b(first + 9, 3))
    a2 = septets(b(second + 6, 3))
    assert a2 - a1 == s1, (name, hex(a2 - a1), hex(s1))


# ------------------------------------------- 4. checksum, cap, chunk size
# SysExTx_AppendChecksumF7 (0xFB7111): H = sum of the message bytes from buffer+0x0F up to
# the write cursor; then `sub WA,WA / sub WA,BC / res 7,A` = (0 - sum) & 0x7F.
# The two bytes it appends come from the word at prom_b 0xF4FE68.
assert b(0xF4FE68, 2) == bytes([0x00, 0xF7]), "checksum tail literal"
assert a(0xFB7119, 5) == bytes([0xD2, 0x68, 0xFE, 0xF4, 0x21]), "ld bc,(0xF4FE68)"
assert a(0xFB7126, 6) == bytes([0xEC, 0xC8, 0x0F, 0, 0, 0]), "add XIX,0x0F"
assert a(0xFB714A, 5) == bytes([0xD8, 0xA0, 0xD9, 0xA0, 0xC9]), "sub WA,WA / sub WA,BC"
assert a(0xFB714E, 3) == bytes([0xC9, 0x30, 0x07]), "res 7,A"


def checksum(payload):
    """payload = the frame's bytes AFTER the leading 0xF0, up to but not
    including the checksum byte itself."""
    return (-sum(payload)) & 0x7F


# SysExTx_AppendNibbles: the pack loop stops once the message byte count reaches 0xFC
assert a(0xFB70A3, 4) == bytes([0xD8, 0xCF, 0xFC, 0x00]), "cp WA,0x00FC"
BLOCK_CAP = 0xFC
# SysExTx_SendFrameMidi1: the frame goes to MIDI-out ring 0x601432 in 0x20-byte chunks
assert a(0xFB71A0, 4) == bytes([0xDB, 0xCF, 0x20, 0x00]), "cp HL,0x0020"
CHUNK = 0x20
# that ring is 0x100 bytes: Ring_Put_0100 wraps with `minc1_16 ix,0x00ff`
assert a(0xF841E9, 4) == bytes([0xDC, 0x38, 0xFF, 0x00]), "ring mask 0x00FF"
RING = 0x100


def frame_shape(header_len):
    """How many SOURCE bytes fit in one frame, and how long the frame is."""
    count = header_len
    src = 0
    while count < BLOCK_CAP:
        count += 2          # one source byte -> two nibbles
        src += 1
    return src, count + 3   # + continuation flag + checksum + 0xF7


FIRST = frame_shape(12)
CONT = frame_shape(3)
assert FIRST == (120, 255), FIRST
assert CONT == (125, 256), CONT
# ★ the cap is exactly what keeps a whole frame inside the 0x100-byte ring
assert CONT[1] == RING

# the two timeouts, both counted in 488.28 Hz timer-1 ticks (0x0080)
assert a(0xFB778A, 3) == bytes([0x33, 0xC4, 0x09]), "ldw hl,0x09C4"
assert a(0xFB7794, 3) == bytes([0x33, 0xE8, 0x03]), "ldw hl,0x03E8"
TIMEOUT_DATA, TIMEOUT_HANDSHAKE = 0x09C4, 0x03E8
# and the no-handshake inter-frame gap
assert a(0xFB77D0, 4) == bytes([0xD9, 0xCF, 0x19, 0x00]), "cp BC,0x0019"
GAP = 0x19


# ---------------------------------------------------------------- report
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--frames", action="store_true",
                    help="print the frame arithmetic and a worked checksum")
    args = ap.parse_args()

    print("base check OK: prom_a @0x%06X, prom_b @0x%06X" % (AB, BB))
    print()
    print("SYSEX BULK DUMP menu row -> job code -> dump routine")
    for row, name in enumerate(ROW_NAMES):
        job = ROW_TO_JOB[row]
        print("  row %d  %-20s job %d  -> 0x%06X" % (row, name, job, JOB_ROUTINE[job]))
    print()
    print("Literal templates (prom_b)")
    for addr, name, ln, site in TEMPLATES:
        print("  0x%06X  %-22s %-22s %s"
              % (addr, name, b(addr, ln).hex(" ").upper(), site))
    print()
    print("Data headers: F0 50 2D 04 <dev> 11 <addr septets> <size septets>")
    for addr, ln, name, step, writer, mult in DATA_HEADERS:
        raw = b(addr, ln).hex(" ").upper()
        if ln == 12:
            adr = septets(b(addr + 6, 3))
            size = septets(b(addr + 9, 3))
            extra = "addr 0x%06X  size 0x%06X (%d)" % (adr, size, size)
        elif ln == 9:
            adr = septets(b(addr + 6, 3))
            extra = "addr 0x%06X  size APPENDED AT RUN TIME" % adr
        else:
            extra = ""
        src = ("src 0x%06X..0x%06X x%d" % (EXTENTS[writer][0], EXTENTS[writer][1], mult)) if writer else ""
        print("  0x%06X  %-26s %-38s %s %s" % (addr, name, raw, extra, src))
    print()
    if args.frames:
        print("Frame arithmetic")
        print("  block cap (message bytes)      0x%02X" % BLOCK_CAP)
        print("  first frame  header 12 bytes ->%4d source bytes, %3d-byte frame" % FIRST)
        print("  continuation header  3 bytes ->%4d source bytes, %3d-byte frame" % CONT)
        print("  MIDI-out ring 0x601432 capacity 0x%03X, put in 0x%02X-byte chunks"
              % (RING, CHUNK))
        print()
        # SYNTHETIC frame: the real header, one made-up source byte 0xF1
        # as its two nibbles, and the "more follows" flag.  It exercises the
        # formula, it is not a capture.
        demo = list(b(0xF4FEF8, 12))[1:] + [0x0F, 0x01] + [0x01]
        print("  synthetic frame, bytes after the leading F0:")
        print("    %s" % bytes(demo).hex(" ").upper())
        print("  checksum = (0 - sum) & 0x7F = 0x%02X" % checksum(demo))
        print("  (sum + checksum) mod 128 = %d   <- always 0"
              % ((sum(demo) + checksum(demo)) % 128))
        print()
    print("OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
