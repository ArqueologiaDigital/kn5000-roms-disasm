#!/usr/bin/env python3
"""The THIRD region of the 2B / 2C families: what `byte 6 = 10 / 18 / 19` addresses.

QUESTION THIS ANSWERS
    `sysex_param_space.py` ends by printing three lines it cannot expand:

        THIRD REGION  (both families)   byte 6 = 10 / 18 / 19, rest wild
          2B -> CMD 0x19 ... 2C -> CMD 0x17 ...
          both unpack the address and count septets and are otherwise undecoded

    What does that address space CONTAIN, what does a message in it DO, and what
    does the instrument answer?

ANSWER, IN ONE LINE
    It is the live tone-edit image: TWO regions of one flat byte address space --
    0x040000 for 713 bytes of the melodic sound being edited, 0x060000 for 19608
    bytes of the drum kit -- `2C` writes exactly one byte of it, `2B` requests a
    run of bytes and is answered with a stream of `2C` messages.

WHERE THE SIGNAL IS
  * COMMAND SLOTS.  prom_b `0xF4F800` / `0xF4F888` entry 0x17 and 0x19 both hold
    prom_a 0xFB3483 / 0xFB3495.  Both are `ld XBC,(0x60FC80) / add XBC,0x0E /
    push / call <thunk>` -- 0x60FC80 is the collector struct and +0x0E is the
    received message's own `F0`, so the routines below index the WIRE bytes.
    ⚠ Neither handler tests the panel-mode byte (0x207A), unlike the bulk-dump
    default handler 0xFB2820 -- these messages need no screen and no session.
  * THE REQUEST, prom_b `sub_F36F8C` (0xF36F8C), reached through thunk
    `T_F41254`.  `Pack3x7BitFields_Bytes6To8` -> address, `..._Bytes9To11` ->
    count; `cp XBC,0x00060000` splits the two regions; `sub XWA,0x00040000 /
    cp XWA,0x000002c9` and `sub XWA,0x00060000 / cp XWA,0x00004c98` bound them.
    Accepted -> state word (0x000A00) |= 5 and return 0; refused -> return 1,
    and prom_a 0xFB34AD then transmits the 5-byte literal at prom_b 0xF4FEC8.
  * THE WRITE, prom_b `sub_F379AB` (0xF379AB), thunk `T_F41258`.  Same address
    split; `cp (0x000A07),0x0001` refuses any count but 1; the value is
    `(msg[12]<<4) | (msg[13]&0x0F)`; a ladder of `cp XIX,<n>` turns the offset
    into (block, index) and hands it to prom_a 0xFD616A (melodic) or 0xFD6704
    (drum), the SAME two routines the panel's own tone editor commits through
    (notes/FINDINGS-l7a1429-field-editors.md section 1c).
  * THE REPLY, prom_b `sub_F37DB4` / `sub_F37E1C` (0xF37DB4, 0xF37E1C): header
    `F0 50 2C 04 nn 11` (the literal is `00`, and sub_FB5F65 rewrites it to
    `01` on the rack), the chunk's own address septets, count `00 00 n`, then
    2n nibble bytes, a `00`, the checksum and `F7`.  `cp WA,0x0078` caps n.
  * THE CROSS-CHECK, prom_c: `Part_GetPercWaveSelectRecord` (0xFB456F) computes
    `0x0087D2 + 0x4A1 + 150*instrument + 43*index`, and prom_c's own staging
    regions tile `0x008A9B - 0x0087D2 == 713` and `0x008C33 - 0x0087D2 ==
    713 + 408` (notes/README-prom_c-tools.md).  So this protocol region is CPU
    2's tone-edit staging image, byte for byte, and the two halves are
    contiguous there.

RUN
    python3 wsa1/notes/sysex-probes/sysex_third_region.py           # tables
    python3 wsa1/notes/sysex-probes/sysex_third_region.py --map     # every block

PASS
    Every assert is silent and the script prints OK.  Headline numbers: region
    sizes 713 and 19608; melodic layout 217 + 4x81 + 4x43; drum layout 408 +
    128x150 with 150 = 64 + 43 + 43; count must be 1 on a write; at most 120
    bytes per reply message, which is exactly the largest that keeps the reply
    inside the receiver's own 256-byte ceiling.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROMS = os.path.join(HERE, "..", "..", "original_ROMs")

prom_a = open(os.path.join(ROMS, "wsa1_prom_a.ic12"), "rb").read()
prom_b = open(os.path.join(ROMS, "wsa1_prom_b.ic13"), "rb").read()
prom_c = open(os.path.join(ROMS, "wsa1_prom_c.ic28"), "rb").read()

A_BASE, B_BASE, C_BASE = 0xF80000, 0xF00000, 0xF80000


def rd(img, base, addr, n):
    o = addr - base
    assert 0 <= o and o + n <= len(img), "address 0x%06X outside the image" % addr
    return img[o:o + n]


def a(addr, n): return rd(prom_a, A_BASE, addr, n)
def b(addr, n): return rd(prom_b, B_BASE, addr, n)
def c(addr, n): return rd(prom_c, C_BASE, addr, n)


def le(buf): return int.from_bytes(buf, "little")


# ------------------------------------------------------------------ load bases
assert b(0xF4FEB4, 5) == bytes([0xF0, 0x50, 0x23, 0x7E, 0xF7]), "prom_b base"
assert a(0xF99AE3, 5) == bytes([0x00, 0x03, 0x05, 0x04, 0x02]), "prom_a base"
assert c(0xFB459E, 6) == bytes([0xE8, 0xC8, 0xA1, 0x04, 0x00, 0x00]), "prom_c base"
print("base check OK: prom_a @0xF80000, prom_b @0xF00000, prom_c @0xF80000")

# --------------------------------------------------- the two dispatcher entries
# Entry 0x17 (family 2C) and 0x19 (family 2B) of BOTH 34-entry outer tables.
for table in (0xF4F800, 0xF4F888):
    assert le(b(table + 4 * 0x17, 4)) == 0xFB3483, "cmd 0x17 slot moved"
    assert le(b(table + 4 * 0x19, 4)) == 0xFB3495, "cmd 0x19 slot moved"

# Both handlers: ld XBC,(0x60FC80) / add XBC,0x0E / push XBC / call <thunk>.
# 0x60FC80 is the collector struct; +0x0E is the received message's own F0.
PREFIX = bytes([0xE2, 0x80, 0xFC, 0x60, 0x21,             # ld XBC,(0x60fc80)
                0xE9, 0xC8, 0x0E, 0x00, 0x00, 0x00,       # add XBC,0x0000000e
                0x39])                                    # push XBC
assert a(0xFB3483, 12) == PREFIX and a(0xFB3495, 12) == PREFIX, "handler shape"
assert a(0xFB348F, 4) == bytes([0x1D, 0x58, 0x12, 0xF4]), "2C thunk"
assert a(0xFB34A1, 4) == bytes([0x1D, 0x54, 0x12, 0xF4]), "2B thunk"
# The thunks: `jp imm24` (opcode 0x1B) into prom_b.
assert b(0xF41254, 4) == bytes([0x1B, 0x8C, 0x6F, 0xF3]), "T_F41254"
assert b(0xF41258, 4) == bytes([0x1B, 0xAB, 0x79, 0xF3]), "T_F41258"
WRITE_SUB, READ_SUB = 0xF379AB, 0xF36F8C
assert le(b(0xF41258 + 1, 3)) == WRITE_SUB and le(b(0xF41254 + 1, 3)) == READ_SUB

# ⚠ NEITHER handler tests the panel mode byte.  The bulk-dump default handler
# does, at its second instruction; assert the contrast rather than assert it.
assert a(0xFB2826, 5) == bytes([0xC1, 0x7A, 0x20, 0x3F, 0x79]), "bulk-dump screen test"
SCREEN = a(0xFB282A, 1)[0]
assert SCREEN == 0x79, "SYSEX BULK DUMP screen id"
assert bytes([0x7A, 0x20]) not in a(0xFB3483, 0x12) + a(0xFB3495, 0x36)

# -------------------------------------------------------------- region bounds
# sub_F36F8C, the 2B request.  Every literal below is an instruction operand.
assert b(0xF36FD0, 6) == bytes([0xE9, 0xCF, 0x00, 0x00, 0x06, 0x00])   # cp XBC,0x60000
assert b(0xF36FE4, 6) == bytes([0xE8, 0xCA, 0x00, 0x00, 0x04, 0x00])   # sub XWA,0x40000
assert b(0xF36FEC, 6) == bytes([0xE8, 0xCF, 0xC9, 0x02, 0x00, 0x00])   # cp XWA,0x2c9
assert b(0xF37002, 6) == bytes([0xE8, 0xCA, 0x00, 0x00, 0x06, 0x00])   # sub XWA,0x60000
assert b(0xF3700A, 6) == bytes([0xE8, 0xCF, 0x98, 0x4C, 0x00, 0x00])   # cp XWA,0x4c98
SPLIT = le(b(0xF36FD2, 4))
A_ADDR, A_LEN = le(b(0xF36FE6, 4)), le(b(0xF36FEE, 4))
B_ADDR, B_LEN = le(b(0xF37004, 4)), le(b(0xF3700C, 4))
assert (SPLIT, A_ADDR, A_LEN, B_ADDR, B_LEN) == (0x60000, 0x40000, 713, 0x60000, 19608)

# The same two bounds again in the WRITE path, read independently.
assert le(b(0xF379DC, 4)) == SPLIT and le(b(0xF379E5, 4)) == A_ADDR
assert le(b(0xF379F0, 4)) == A_LEN
assert le(b(0xF37BAB, 4)) == B_ADDR and le(b(0xF37BB6, 4)) == B_LEN

# The grammar admits exactly three values of byte 6, and they are the septet
# pages these two regions occupy -- 0x10 -> 0x040000, 0x18/0x19 -> 0x060000 and
# 0x064000.  (The trie itself is walked by sysex_param_space.py.)
PAGES = (0x10, 0x18, 0x19)
assert [p << 14 for p in PAGES] == [0x040000, 0x060000, 0x064000]
assert A_ADDR <= 0x10 << 14 < A_ADDR + 0x4000
assert B_ADDR + B_LEN > 0x19 << 14, "the second page of region B is unreachable"

# ------------------------------------------------------- a write carries 1 byte
assert b(0xF379CB, 7) == bytes([0xD2, 0x07, 0x0A, 0x00, 0x3F, 0x01, 0x00])
assert le(b(0xF379D0, 2)) == 1, "the 2C count must be exactly 1"
# The value is the nibble pair at message bytes 12 and 13, high nibble first.
# Region A reads it through A/H, region B through C/H -- different registers,
# the same two offsets, the same mask and the same shift.
assert b(0xF379FA, 14) == bytes([0x89, 0x0D, 0x21, 0xC9, 0x8E, 0xCE, 0xCC, 0x0F,
                                 0x89, 0x0C, 0x21, 0xC9, 0xEE, 0x04])
assert b(0xF37BC0, 14) == bytes([0x88, 0x0D, 0x23, 0xCB, 0x8E, 0xCE, 0xCC, 0x0F,
                                 0x88, 0x0C, 0x23, 0xCB, 0xEE, 0x04])
HI_BYTE, LO_BYTE = b(0xF37A03, 1)[0], b(0xF379FB, 1)[0]
NIB_MASK, NIB_SHIFT = b(0xF37A01, 1)[0], b(0xF37A07, 1)[0]
assert (HI_BYTE, LO_BYTE, NIB_MASK, NIB_SHIFT) == (0x0C, 0x0D, 0x0F, 4)

# -------------------------------------------------------- MELODIC region layout
# sub_F379AB's ladder: `cp XIX,<threshold>` (EC CF imm32) then `push <selector>`
# (0B imm16).  Read both out of the instruction bytes rather than restating them.
MEL_LADDER = [(0xF37A19, 0xF37A34), (0xF37A3D, 0xF37A57),
              (0xF37A5D, 0xF37A77), (0xF37A7D, 0xF37A97),
              (0xF37A9D, 0xF37AB7), (0xF37ABD, 0xF37AD7),
              (0xF37ADD, 0xF37AF7), (0xF37AFD, 0xF37B17)]
mel = []
for cmp_site, push_site in MEL_LADDER:
    assert b(cmp_site, 2) == bytes([0xEC, 0xCF]), "no `cp XIX,imm32` at %06X" % cmp_site
    assert b(push_site, 1) == bytes([0x0B]), "no `push imm16` at %06X" % push_site
    mel.append((le(b(cmp_site + 2, 4)), le(b(push_site + 1, 2))))

# Four 43-byte blocks on selectors 0x11/0x21/0x31/0x41, four 81-byte blocks on
# selectors 1/2/3/4, and a common block below them.  The region ENDS on the last
# 43-byte block -- that is the last-entry test on the whole layout.
WAVESEL = [(t, s) for t, s in mel if s > 0x10]
ELEMENT = [(t, s) for t, s in mel if s <= 0x10]
assert len(WAVESEL) == 4 and len(ELEMENT) == 4
WSEL_SIZE = WAVESEL[0][0] - WAVESEL[1][0]
ELEM_SIZE = ELEMENT[0][0] - ELEMENT[1][0]
assert WSEL_SIZE == 43 and ELEM_SIZE == 81
for i in range(3):
    assert WAVESEL[i][0] - WAVESEL[i + 1][0] == WSEL_SIZE
    assert ELEMENT[i][0] - ELEMENT[i + 1][0] == ELEM_SIZE
WSEL_AT, ELEM_AT = WAVESEL[-1][0], ELEMENT[-1][0]
assert (WSEL_AT, ELEM_AT) == (0x21D, 0xD9)
assert ELEM_AT + 4 * ELEM_SIZE == WSEL_AT, "element blocks do not meet the wave-select ones"
assert WSEL_AT + 4 * WSEL_SIZE == A_LEN, "the melodic region does not end on its last block"
assert [s for _, s in WAVESEL] == [0x41, 0x31, 0x21, 0x11]
assert [s for _, s in ELEMENT] == [4, 3, 2, 1]
assert le(b(0xF37B9D + 1, 3)) == 0xF43470, "the melodic setter moved"
assert b(0xF43470, 4) == bytes([0x1B, 0x6A, 0x61, 0xFD]), "T_F43470 -> prom_a 0xFD616A"

# Inside the common block, one span is served by prom_b itself (thunk T_DspParam_WriteByNumber)
# and never leaves the panel processor; everything else goes out to CPU 2.
for site in (0xF37B1D, 0xF37B25, 0xF37B6A, 0xF37B72):
    assert b(site, 2) == bytes([0xEC, 0xCF]), "no `cp XIX,imm32` at %06X" % site
MEL_LOCAL = (le(b(0xF37B6C, 4)), le(b(0xF37B74, 4)))          # 139 .. 207
MEL_STRAY = (le(b(0xF37B1F, 4)), le(b(0xF37B27, 4)))          # 135..137, then 138
assert MEL_LOCAL == (139, 207) and MEL_STRAY == (135, 138)
for site, bias in ((0xF37B3C, 70), (0xF37B60, 69)):
    assert b(site, 2) == bytes([0xE9, 0xC8]) and le(b(site + 2, 4)) == bias
MEL_LOCAL_N = MEL_LOCAL[1] - MEL_LOCAL[0] + 1
assert MEL_LOCAL_N == 69, "%d locally served parameters" % MEL_LOCAL_N
assert le(b(0xF37CEC + 1, 3)) == 0xF434A0, "the locally served setter moved"
assert b(0xF434A0, 4) == bytes([0x1B, 0x30, 0x1C, 0xF1]), "T_DspParam_WriteByNumber -> prom_b 0xF11C30"

# --------------------------------------------------------- DRUM region layout
assert b(0xF37BDF, 6) == bytes([0xEC, 0xCF, 0x98, 0x01, 0x00, 0x00])   # cp XIX,408
assert b(0xF37BED, 6) == bytes([0xE9, 0xCA, 0x98, 0x01, 0x00, 0x00])   # sub XBC,408
assert b(0xF37BF6, 3) == bytes([0x0B, 0x96, 0x00]), "the record stride is not a literal"
KIT_COMMON = le(b(0xF37BE1, 4))
REC_SIZE = le(b(0xF37BF7, 2))
assert (KIT_COMMON, REC_SIZE) == (408, 150)
# Inside one record: three sub-blocks, found from `add XWA,<offset>` after the
# `150 * n` product.  Their order in the code is high offset first.
assert b(0xF37C17, 6) == bytes([0xE8, 0xC8, 0x03, 0x02, 0x00, 0x00])   # add XWA,515
assert b(0xF37C4B, 6) == bytes([0xE8, 0xC8, 0xD8, 0x01, 0x00, 0x00])   # add XWA,472
assert b(0xF37C7E, 6) == bytes([0xE8, 0xC8, 0x98, 0x01, 0x00, 0x00])   # add XWA,408
SUBS = [le(b(s, 4)) - KIT_COMMON for s in (0xF37C80, 0xF37C4D, 0xF37C19)]
assert SUBS == [0, 64, 107]
SUB_SIZES = [SUBS[1] - SUBS[0], SUBS[2] - SUBS[1], REC_SIZE - SUBS[2]]
assert SUB_SIZES == [64, 43, 43]
assert SUB_SIZES[1] == WSEL_SIZE and SUB_SIZES[2] == WSEL_SIZE
RECORDS, rem = divmod(B_LEN - KIT_COMMON, REC_SIZE)
assert rem == 0, "the drum region is not a whole number of records"
assert RECORDS == 128, "%d records" % RECORDS
assert le(b(0xF37D03 + 1, 3)) == 0xF43478, "the drum setter moved"
assert b(0xF43478, 4) == bytes([0x1B, 0x04, 0x67, 0xFD]), "T_F43478 -> prom_a 0xFD6704"

# Each record access is preceded by a `select this record` message to CPU 2.
assert le(b(0xF37C05 + 1, 3)) == 0xF43488
assert b(0xF43488, 4) == bytes([0x1B, 0x5C, 0x66, 0xFD]), "T_F43488 -> prom_a 0xFD665C"
assert a(0xFD6689, 4) == bytes([0xBC, 0x02, 0x00, 0x13]), "record selector is not parameter 0x13"
# prom_a 0xFDA160 defaults that record number when the panel has never set it.
assert a(0xFDA175, 3) == bytes([0xB1, 0x00, 0x24]), "the default record is not 36"
DEFAULT_RECORD = a(0xFDA177, 1)[0]
assert DEFAULT_RECORD == 36 and DEFAULT_RECORD < RECORDS

# The kit-common block has the same locally served span as the melodic region,
# and the same 69 parameters -- at a different offset.
for site in (0xF37CAC, 0xF37CCC, 0xF37CD4):
    assert b(site, 2) == bytes([0xEC, 0xCF]), "no `cp XIX,imm32` at %06X" % site
DRUM_LOCAL = (le(b(0xF37CCE, 4)), le(b(0xF37CD6, 4)))         # 83 .. 151
DRUM_STRAY = le(b(0xF37CAE, 4))                               # 82
assert DRUM_LOCAL == (83, 151) and DRUM_STRAY == 82
assert DRUM_LOCAL[1] - DRUM_LOCAL[0] + 1 == MEL_LOCAL_N
assert b(0xF37CC3, 2) == bytes([0xE9, 0xC8]) and le(b(0xF37CC5, 4)) == 69
assert le(b(0xF37CEC + 1, 3)) == 0xF434A0, "the drum region uses a different local setter"

# ------------------------------------------------------------------- the reply
HDR = b(0xF37DBC, 24)
assert [HDR[i] for i in (2, 6, 10, 14, 18, 22)] == [0xF0, 0x50, 0x2C, 0x04, 0x00, 0x11]
assert b(0xF37E00, 8) == bytes([0xBC, 0x09, 0x00, 0x00, 0xBC, 0x0A, 0x00, 0x00])
assert b(0xF37E0B, 3) == bytes([0xBC, 0x0B, 0x43]), "byte 11 is not the chunk count"
assert b(0xF37E10, 6) == bytes([0xE9, 0xC8, 0x0C, 0x00, 0x00, 0x00])   # payload at +12
PAYLOAD_AT = le(b(0xF37E12, 4))
assert PAYLOAD_AT == 12
# The chunk cap, in both chunkers, and the trailing F7.
assert b(0xF36B11, 4) == bytes([0xD8, 0xCF, 0x78, 0x00])               # cp WA,0x78
assert b(0xF36E03, 4) == bytes([0xD8, 0xCF, 0x78, 0x00])
CHUNK_CAP = le(b(0xF36B13, 2))
assert CHUNK_CAP == le(b(0xF36E05, 2)) == 120
assert b(0xF37EE7, 4) == bytes([0xB9, 0x01, 0x00, 0xF7]), "the reply does not end F7"
# Message length = 12 header + 2n payload + flag + checksum + F7.
WIRE = PAYLOAD_AT + 2 * CHUNK_CAP + 3
assert WIRE == 255, "a full reply is %d bytes" % WIRE
# The receiver's own ceiling (sysex_bulkdump_rx.py reads the same site).
assert a(0xFB610A, 4) == bytes([0xD8, 0xCF, 0xFF, 0x00])
CEILING = le(a(0xFB610C, 2)) + 1      # the F0 is counted, the closing F7 is not
assert WIRE <= CEILING, "a full reply would not survive reception"

# ⚠ The reply's model byte is NOT a constant.  It leaves through prom_a
# 0xFB7AC2 -> sub_FB7165, and the refusal through sub_FB71BB; both of those
# senders call sub_FB5F65 (calr displacements -0x1212 and -0x1268), which on the
# rack variant rewrites byte 4 of a 2C to 0x01 and recomputes the checksum --
# see sysex_model_variant.py.  So the reply header is `F0 50 2C 04 nn 11`.
assert a(0xFB7AD6, 3) == bytes([0x1E, 0x8C, 0xF6]), "the reply sender moved"
assert 0xFB7AD6 + 3 + int.from_bytes(a(0xFB7AD7, 2), "little", signed=True) == 0xFB7165
for site in (0xFB7174, 0xFB71CA):
    disp = int.from_bytes(a(site + 1, 2), "little", signed=True)
    assert a(site, 1) == bytes([0x1E]) and site + 3 + disp == 0xFB5F65

# The checksum helper: skip the F0, sum to the cursor, negate, clear bit 7.
assert a(0xFB7A9F, 2) == bytes([0xEC, 0x61])          # inc 1,XIX  (past the F0)
assert a(0xFB7AB9, 3) == bytes([0xC9, 0x30, 0x07])    # res 7,A
assert le(b(0xF4090C + 1, 3)) == 0xFB7A90

# ------------------------------------------------------------- refusal answer
assert a(0xFB34A6, 2) == bytes([0xD8, 0xD8]), "the request's return value is not tested"
assert a(0xFB34AA, 3) == bytes([0x0B, 0x05, 0x00]), "refusal message length"
assert le(a(0xFB34AE, 3)) == 0xF4FEC8
REFUSAL = b(0xF4FEC8, a(0xFB34AB, 1)[0])
assert REFUSAL == bytes([0xF0, 0x50, 0x29, 0x7E, 0xF7]), "refusal is not the abort message"
assert b(0xF4FEB4 + 5 * 4, 5) == REFUSAL, "that literal is not the 5th fixed message"

# ------------------------------------------ CROSS-CHECK against CPU 2's own map
# prom_c Part_GetPercWaveSelectRecord: 0x0087D2 + 0x4A1 + 150*inst + 43*idx, and
# ToneMsg_WriteWaveSelectParam: 0x0087D2 + 0x21D + 43*element.
assert c(0xFB4595, 2) == bytes([0x21, 0x96]), "ld A,0x96"
assert c(0xFB458C, 2) == bytes([0x23, 0x2B]), "ld C,0x2b"
assert c(0xFB459E, 6) == bytes([0xE8, 0xC8, 0xA1, 0x04, 0x00, 0x00])
assert c(0xFB45A4, 6) == bytes([0xE8, 0xC8, 0xD2, 0x87, 0x00, 0x00])
assert c(0xFBC97A, 3) == bytes([0xCB, 0x08, 0x2B]), "mul C,0x2b"
assert c(0xFBC97F, 6) == bytes([0xE9, 0xC8, 0x1D, 0x02, 0x00, 0x00])
STAGE = le(c(0xFB45A6, 4))
PERC_WSEL = le(c(0xFB45A0, 4))
assert (STAGE, PERC_WSEL) == (0x87D2, 0x4A1)
assert (c(0xFB4596, 1)[0], c(0xFB458D, 1)[0]) == (REC_SIZE, WSEL_SIZE)
assert c(0xFBC97C, 1)[0] == WSEL_SIZE and le(c(0xFBC981, 4)) == WSEL_AT
# The two protocol regions are contiguous in that staging image, in this order.
assert PERC_WSEL == A_LEN + KIT_COMMON + SUBS[1], \
    "the drum region does not follow the melodic one in CPU 2's staging image"

# ------------------------------------------------------------------- the tables
def fmt(addr): return "0x%06X" % addr


if "--map" in sys.argv:
    print()
    print("MELODIC REGION  base %s  %d bytes" % (fmt(A_ADDR), A_LEN))
    print("   offset  bytes  block")
    print("   %6d  %5d  common" % (0, ELEM_AT))
    print("           %5d    of which %d..%d are answered by the panel"
          % (MEL_LOCAL[1] - MEL_STRAY[0] + 1, MEL_STRAY[0], MEL_LOCAL[1]))
    print("                    processor itself and never reach the sound engine")
    for i in range(4):
        print("   %6d  %5d  element %d" % (ELEM_AT + i * ELEM_SIZE, ELEM_SIZE, i))
    for i in range(4):
        print("   %6d  %5d  element %d modelling block" % (
            WSEL_AT + i * WSEL_SIZE, WSEL_SIZE, i))
    print()
    print("DRUM REGION  base %s  %d bytes" % (fmt(B_ADDR), B_LEN))
    print("   offset  bytes  block")
    print("   %6d  %5d  kit common" % (0, KIT_COMMON))
    print("           %5d    of which %d and %d..%d are answered by the panel"
          % (MEL_LOCAL_N + 1, DRUM_STRAY, *DRUM_LOCAL))
    print("                    processor itself, the same parameters as above")
    for k, (off, size) in enumerate(zip(SUBS, SUB_SIZES)):
        print("   %d+%dn+%-3d %5d  %s" % (KIT_COMMON, REC_SIZE, off, size,
              "entry common" if k == 0 else "entry modelling block %d" % (k - 1)))
    print("   n = 0..%d -- one entry per note number (LIKELY: the count is 128 and"
          % (RECORDS - 1))
    print("   the panel's own default entry is %d, but no instruction decoded here"
          % DEFAULT_RECORD)
    print("   ties n to a note-on)")
    sys.exit(0)

print()
print("THE THIRD REGION IS ONE FLAT BYTE ADDRESS SPACE, IN TWO PARTS")
print("  %s .. %s   %5d bytes   the melodic sound being edited" % (
    fmt(A_ADDR), fmt(A_ADDR + A_LEN - 1), A_LEN))
print("  %s .. %s   %5d bytes   the drum kit being edited" % (
    fmt(B_ADDR), fmt(B_ADDR + B_LEN - 1), B_LEN))
print("  wire pages: byte 6 = %s" % ", ".join("%02X" % p for p in PAGES))
print()
print("  melodic: %d common + 4 x %d element + 4 x %d modelling = %d" % (
    ELEM_AT, ELEM_SIZE, WSEL_SIZE, A_LEN))
print("  drum:    %d common + %d x %d = %d, and %d = %d + %d + %d" % (
    KIT_COMMON, RECORDS, REC_SIZE, B_LEN, REC_SIZE, *SUB_SIZES))
print()
print("WRITE  F0 50 2C 04 nn 11 <addr3> 00 00 01 <hi> <lo> <flag> <sum> F7")
print("  the count triple must be exactly %d; the byte is the two nibbles," % 1)
print("  high first; there is no acknowledgement and no error answer.")
print()
print("REQUEST  F0 50 2B 04 nn 11 <addr3> <count3> <flag> <sum> F7")
print("  accepted -> a stream of 2C messages, at most %d bytes each," % CHUNK_CAP)
print("     %d bytes on the wire, each carrying its own chunk address" % WIRE)
print("  refused  -> %s (abort)" % " ".join("%02X" % x for x in REFUSAL))
print("  refused when: a transfer is already running; the count is 0;")
print("     the address is 0; or address+count runs past the region's end.")
print()
print("Neither message needs a bulk-dump session or the SYSEX BULK DUMP screen.")
print()
print("CPU 2 cross-check: staging image 0x%04X, percussion wave-select at +0x%03X"
      " == %d + %d + %d" % (STAGE, PERC_WSEL, A_LEN, KIT_COMMON, SUBS[1]))
print("OK")
