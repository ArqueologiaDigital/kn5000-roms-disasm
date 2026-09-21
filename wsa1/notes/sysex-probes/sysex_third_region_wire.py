#!/usr/bin/env python3
"""r = 10 / 18 / 19 on the 2B and 2C families: the ADDRESS SPACE and the WIRE FORMAT.

QUESTION THIS ANSWERS
    The published reference says of the first address byte r:

        "Families 2B and 2C also accept r = 10, 18 and 19, which carry an
         address and a count.  What they address is not covered by this
         edition."

    What IS r?  How wide is the address, what is the count in, what is the
    biggest transfer, is it readable or writable, what answers a request, what
    happens off the end of it, and can a player at the panel get at any of it?

ANSWER, IN ONE LINE
    r is not a region selector at all: it is the TOP SEPTET of one 21-bit byte
    address, so 10 -> 0x040000, 18 -> 0x060000, 19 -> 0x064000.  The space is
    the LIVE TONE-EDIT IMAGE -- 713 bytes of the melodic sound being edited at
    0x040000 and 19608 bytes of the drum kit at 0x060000 (which needs both 18
    and 19 because it is longer than one septet page).  2B reads it, 2C writes
    one byte of it, and the write lands in the same two routines the panel's
    own tone editor commits through.

WHERE THE SIGNAL IS  (prom_b at 0xF00000, prom_a at 0xF80000, prom_c at 0xF80000)
  * THE GRAMMAR.  ROOT 0xF5115B -> family -> 04 -> nn -> 11 -> byte 6.  Under
    both families byte 6 admits exactly 00/10/18/19 (2B also has the four
    whole-area dump requests 20/40/50/60), and 10, 18 and 19 share ONE
    continuation node -- 0xF510EF for 2B, 0xF50F7B for 2C.  That single shared
    node is the evidence that the three are one space and not three regions.
    Below it sit FIVE wildcard (0xFE) records, bytes 7..11, and the fifth
    carries the command id: 0x19 for 2B, 0x17 for 2C.
  * THE ADDRESS is prom_b Pack3x7BitFields_Bytes6To8 (0xF36849), the count
    Pack3x7BitFields_Bytes9To11 (0xF36800).  They are NOT the same width: the
    address one rejoins its three septets with `or XWA,(XIZ+0xfc)` /
    `or XWA,XBC` and returns XIY -- 32 bits, a full 21-bit address -- while the
    count one rejoins with `ld IY,(XIZ+0xfc)` / `or DE,WA` / `or BC,DE` and
    returns WA, so the count is TRUNCATED TO 16 BITS.  Both callers store it
    with a 16-bit `ld (0x000a07),WA`.
  * THE REQUEST is sub_F36F8C (0xF36F8C), thunk T_F41254, command slot 0x19 of
    both receive tables (prom_a 0xFB3495).  Bounds `cp XBC,0x00060000`,
    `sub XWA,0x00040000 / cp XWA,0x000002c9`, `sub XWA,0x00060000 /
    cp XWA,0x00004c98`.
  * THE WRITE is sub_F379AB (0xF379AB), thunk T_F41258, command slot 0x17
    (prom_a 0xFB3483).  `cp (0x000a07),0x0001` -- the count must be 1.
  * ⚠ THE TWO HANDLERS ARE NOT SYMMETRIC.  0xFB3495 does `pop XIY / cp WA,0 /
    jr Z` and sends the five bytes at prom_b 0xF4FEC8 when the routine refused;
    0xFB3483 does `pop XBC / ret` and never looks.  So a refused READ is
    answered and a refused WRITE is silent.
  * THE REPLY is built by sub_F37DB4 (0xF37DB4) and sent by sub_F37E1C
    (0xF37E1C).  The header splits the CURRENT address back into septets with
    `and XBC,0x001fc000 / sra 14`, `and XBC,0x00003f80 / sra 7` and `res 7,C`
    -- the same 21-bit encoding, read off the transmit side.
  * THE PORTS DIFFER.  The reply goes out through prom_a sub_FB7165, which
    feeds ONE output path (0xF41DF8/0xF40724) and is the routine the bulk dump
    uses; the refusal goes out through sub_FB71BB, which feeds TWO
    (0xF41DF8/0xF40724 and 0xF41E1C/0xF40730).
  * THE CHECKSUM is prom_a sub_FB7A90: `inc 1,XIX / dec 1,HL` before the sum,
    so the leading 0xF0 is skipped, then `sub WA,WA / sub WA,BC / res 7,A`.
  * THE DESTINATION.  The write ladder ends in T_F43470 -> prom_a 0xFD616A
    (melodic) and T_F43478 -> prom_a 0xFD6704 (drum).  Those are the two
    routines ToneEdit_CommitField (0xFD7435) calls when the player turns the
    DATA dial (notes/FINDINGS-l7a1429-field-editors.md section 1c).
  * ⚠ NOT REACHABLE FROM THE PANEL.  The whole transfer lives in the state
    block 0x000A00..0x000A0B, and an instruction-boundary census of both CPU-1
    images finds every reference to it in prom_b and none in prom_a -- so no
    screen, menu row or button can arm a transfer.  The SYSEX BULK DUMP screen
    sends the four bulk categories (0x080000/0x100000/0x140000/0x180000) and
    none of them is in this space.

RUN
    python3 wsa1/notes/sysex-probes/sysex_third_region_wire.py            # tables
    python3 wsa1/notes/sysex-probes/sysex_third_region_wire.py --map      # blocks
    python3 wsa1/notes/sysex-probes/sysex_third_region_wire.py --census   # 0x0A00 block

PASS
    Every assert is silent and the script prints OK.  Headline numbers: pages
    {10,18,19} = 0x040000/0x060000/0x064000; 713 and 19608 bytes; address 21
    bits, count 16; write count exactly 1; reply <= 120 bytes = 255 on the
    wire; refusal F0 50 29 7E F7 for a read and NOTHING for a write; 63
    references to the state block, all of them in prom_b.
"""
import argparse
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))
ROMS = os.path.join(ROOT, "original_ROMs")

A_BASE, B_BASE, C_BASE = 0xF80000, 0xF00000, 0xF80000
A = open(os.path.join(ROMS, "wsa1_prom_a.ic12"), "rb").read()
B = open(os.path.join(ROMS, "wsa1_prom_b.ic13"), "rb").read()
C = open(os.path.join(ROMS, "wsa1_prom_c.ic28"), "rb").read()
assert len(A) == len(B) == len(C) == 0x80000


def a(addr, n=1): return A[addr - A_BASE:addr - A_BASE + n]
def b(addr, n=1): return B[addr - B_BASE:addr - B_BASE + n]
def c(addr, n=1): return C[addr - C_BASE:addr - C_BASE + n]
def le(buf): return int.from_bytes(buf, "little")


# ------------------------------------------------------------------ 0. bases
assert b(0xF4FEB4, 5) == bytes([0xF0, 0x50, 0x23, 0x7E, 0xF7]), "prom_b base"
assert a(0xF99AE3, 5) == bytes([0x00, 0x03, 0x05, 0x04, 0x02]), "prom_a base"
assert c(0xFB459E, 6) == bytes([0xE8, 0xC8, 0xA1, 0x04, 0x00, 0x00]), "prom_c base"
print("base check OK: prom_a @0xF80000, prom_b @0xF00000, prom_c @0xF80000")
print()


# ------------------------------------------------- 1. the grammar, walked
# Record = [0] match byte, [1] command id (0 = descend), [2..5] LE32 next node.
# 0xFF ends a node; 0xFE is a wildcard.  (Layout from sysex_grammar_dump.py.)
def node_records(addr, cap=512):
    out, p = [], addr
    for _ in range(cap):
        r = b(p, 6)
        out.append((r[0], r[1], le(r[2:6])))
        if r[0] == 0xFF:
            return out
        p += 6
    raise AssertionError("node 0x%06X is not terminated within %d records" % (addr, cap))


def descend(addr, match):
    for m, cmd, nxt in node_records(addr):
        if m == match:
            return cmd, nxt
    return None


ROOT_NODE = 0xF5115B
FAMILY_NODE = {}
for fam in (0x2B, 0x2C):
    hit = descend(ROOT_NODE, fam)
    assert hit and hit[0] == 0, "family %02X is not a descend record" % fam
    FAMILY_NODE[fam] = hit[1]
assert FAMILY_NODE == {0x2B: 0xF5114F, 0x2C: 0xF50FC3}, FAMILY_NODE

PAGES = (0x10, 0x18, 0x19)
TERMINAL_CMD = {0x2B: 0x19, 0x2C: 0x17}
grammar = {}
for fam in (0x2B, 0x2C):
    hit = descend(FAMILY_NODE[fam], 0x04)
    assert hit and hit[0] == 0, "family %02X has no 04 record" % fam
    n04 = hit[1]
    models = [m for m, cmd, nxt in node_records(n04) if m != 0xFF]
    assert models == [0x00, 0x01], "model bytes under %02X: %r" % (fam, models)
    shared = set()
    b6_all = None
    for nn in models:
        _, nmodel = descend(n04, nn)
        hit11 = descend(nmodel, 0x11)
        assert hit11 and hit11[0] == 0
        n11 = hit11[1]
        seen = [m for m, cmd, nxt in node_records(n11) if m != 0xFF]
        b6_all = seen if b6_all is None else b6_all
        assert seen == b6_all, "byte 6 set differs between model bytes"
        for page in PAGES:
            hit6 = descend(n11, page)
            assert hit6 and hit6[0] == 0, "page %02X missing under %02X" % (page, fam)
            shared.add(hit6[1])
    # ALL THREE PAGES MUST LAND ON ONE NODE -- that is the "one space" proof.
    assert len(shared) == 1, "pages %s do not share a node: %r" % (PAGES, shared)
    chain_head = shared.pop()
    # five wildcard levels, bytes 7..11, the last one terminal
    node, depth, wild = chain_head, 7, []
    while True:
        rr = node_records(node)
        live = [x for x in rr if x[0] != 0xFF]
        assert len(live) == 1 and live[0][0] == 0xFE, \
            "byte %d under %02X is not a lone wildcard: %r" % (depth, fam, rr)
        wild.append(depth)
        if live[0][1] != 0:
            assert live[0][1] == TERMINAL_CMD[fam], \
                "family %02X terminates in cmd %02X" % (fam, live[0][1])
            break
        node = live[0][2]
        depth += 1
        assert depth <= 16, "wildcard chain runs away"
    assert wild == [7, 8, 9, 10, 11], wild
    grammar[fam] = (b6_all, chain_head, wild)

print("1. THE GRAMMAR, walked from ROOT 0xF5115B")
for fam in (0x2B, 0x2C):
    b6_all, head, wild = grammar[fam]
    print("  family %02X  byte 6 admits %s" % (fam, " ".join("%02X" % x for x in b6_all)))
    print("             %s -> ONE shared node 0x%06X, then wildcards on bytes %s,"
          % (" / ".join("%02X" % p for p in PAGES), head,
             "-".join(str(wild[0]) + ".." + str(wild[-1]) for _ in [0])))
    print("             the last of which terminates in command 0x%02X"
          % TERMINAL_CMD[fam])
print("  model byte nn is 00 or 01 and changes nothing here")
print()


# ------------------------------------- 2. address 21 bits, count only 16
# Address packer, prom_b 0xF36849: the rejoin is 32-bit.
assert b(0xF3687D, 3) == bytes([0xAE, 0xFC, 0xE0]), "or XWA,(XIZ+0xfc) moved"   # MLD
assert b(0xF36880, 2) == bytes([0xE9, 0xE0]), "or XWA,XBC moved"                # 32-bit
assert b(0xF36882, 2) == bytes([0xE8, 0x8D]), "ld XIY,XWA moved"                # 32-bit
# Count packer, prom_b 0xF36800: the rejoin is 16-bit and drops the top 5 bits.
assert b(0xF36838, 3) == bytes([0x9E, 0xFC, 0x25]), "ld IY,(XIZ+0xfc) moved"    # 16-bit
assert b(0xF3683D, 2) == bytes([0xD8, 0xE2]), "or DE,WA moved"
assert b(0xF3683F, 2) == bytes([0xDA, 0xE1]), "or BC,DE moved"
assert b(0xF36841, 2) == bytes([0xD9, 0x88]), "ld WA,BC moved"
# both shift the first septet by 14 and the second by 7
for site in (0xF36814, 0xF3685B):
    assert b(site, 3) == bytes([0xE9, 0xEE, 0x0E]), "sll 14 moved at 0x%06X" % site
for site in (0xF36824, 0xF3686B):
    assert b(site, 3) == bytes([0xE8, 0xEE, 0x07]), "sll 7 moved at 0x%06X" % site
# both callers keep the count in a 16-bit store
for site in (0xF36FAF, 0xF379B8):
    assert b(site, 5) == bytes([0xF2, 0x07, 0x0A, 0x00, 0x50]), \
        "ld (0x000a07),WA moved at 0x%06X" % site

ADDR_BITS, COUNT_BITS = 21, 16
print("2. THE ADDRESS AND THE COUNT")
print("  bytes 6..8  address  (b6 & 7F) << 14 | (b7 & 7F) << 7 | (b8 & 7F)")
print("              rejoined 32-bit -> the full %d bits survive" % ADDR_BITS)
print("  bytes 9..11 count    same arithmetic, rejoined 16-BIT -> only the low")
print("              %d bits survive; the top five of byte 9 are dropped" % COUNT_BITS)
print("  the count is a number of BYTES of the address space, not of wire bytes")
print()


# ------------------------------------------------- 3. the bounds, read twice
# Request path, sub_F36F8C.
assert b(0xF36FD0, 6) == bytes([0xE9, 0xCF, 0x00, 0x00, 0x06, 0x00])   # cp XBC,0x60000
assert b(0xF36FE4, 6) == bytes([0xE8, 0xCA, 0x00, 0x00, 0x04, 0x00])   # sub XWA,0x40000
assert b(0xF36FEC, 6) == bytes([0xE8, 0xCF, 0xC9, 0x02, 0x00, 0x00])   # cp XWA,0x2c9
assert b(0xF37002, 6) == bytes([0xE8, 0xCA, 0x00, 0x00, 0x06, 0x00])   # sub XWA,0x60000
assert b(0xF3700A, 6) == bytes([0xE8, 0xCF, 0x98, 0x4C, 0x00, 0x00])   # cp XWA,0x4c98
SPLIT = le(b(0xF36FD2, 4))
MEL_ADDR, MEL_LEN = le(b(0xF36FE6, 4)), le(b(0xF36FEE, 4))
DRM_ADDR, DRM_LEN = le(b(0xF37004, 4)), le(b(0xF3700C, 4))
# Write path, sub_F379AB -- the same five numbers, read from different bytes.
assert le(b(0xF379DC, 4)) == SPLIT and le(b(0xF379E5, 4)) == MEL_ADDR
assert le(b(0xF379F0, 4)) == MEL_LEN
assert le(b(0xF37BAB, 4)) == DRM_ADDR and le(b(0xF37BB6, 4)) == DRM_LEN
assert (SPLIT, MEL_ADDR, MEL_LEN, DRM_ADDR, DRM_LEN) == \
    (0x60000, 0x040000, 713, 0x060000, 19608)

PAGE_SIZE = 1 << 14
REGIONS = (("melodic tone being edited", MEL_ADDR, MEL_LEN),
           ("drum kit being edited", DRM_ADDR, DRM_LEN))
cover = {}
for name, base, size in REGIONS:
    for page in PAGES:
        lo, hi = page << 14, (page << 14) + PAGE_SIZE - 1
        if lo < base + size and hi >= base:
            cover.setdefault(name, []).append(page)
# every page must be used by exactly one region, and every region covered
assert cover == {"melodic tone being edited": [0x10],
                 "drum kit being edited": [0x18, 0x19]}, cover
assert MEL_LEN <= PAGE_SIZE and PAGE_SIZE < DRM_LEN <= 2 * PAGE_SIZE

print("3. WHAT r IS: the top septet of one 21-bit byte address")
print("    r   page covers            region                       in use")
for page in PAGES:
    lo = page << 14
    hit = [(n, ba, sz) for n, ba, sz in REGIONS if ba <= lo < ba + sz]
    if hit:
        n, ba, sz = hit[0]
        first = lo - ba
        last = min(lo + PAGE_SIZE, ba + sz) - ba
        use = "offsets %5d .. %5d of the %s" % (first, last - 1, n)
    else:
        use = "-- never in range"
    print("   %02X   0x%06X-0x%06X   %s" % (page, lo, lo + PAGE_SIZE - 1, use))
print()
for name, base, size in REGIONS:
    print("  0x%06X .. 0x%06X  %6d bytes   %s"
          % (base, base + size - 1, size, name))
print("  the drum region is longer than one %d-byte septet page, which is the"
      % PAGE_SIZE)
print("  whole reason r takes two values for it")
print()


# ------------------------------------- 4. the two handlers, and the asymmetry
PREFIX = bytes([0xE2, 0x80, 0xFC, 0x60, 0x21,             # ld XBC,(0x60fc80)
                0xE9, 0xC8, 0x0E, 0x00, 0x00, 0x00,       # add XBC,0x0000000e
                0x39])                                    # push XBC
for table in (0xF4F800, 0xF4F888):
    assert le(b(table + 4 * 0x17, 4)) == 0xFB3483, "cmd 0x17 slot moved"
    assert le(b(table + 4 * 0x19, 4)) == 0xFB3495, "cmd 0x19 slot moved"
assert a(0xFB3483, 12) == PREFIX and a(0xFB3495, 12) == PREFIX, "handler shape"
assert a(0xFB348F, 4) == bytes([0x1D, 0x58, 0x12, 0xF4]), "2C thunk"
assert a(0xFB34A1, 4) == bytes([0x1D, 0x54, 0x12, 0xF4]), "2B thunk"
assert b(0xF41254, 4) == bytes([0x1B, 0x8C, 0x6F, 0xF3]), "T_F41254"
assert b(0xF41258, 4) == bytes([0x1B, 0xAB, 0x79, 0xF3]), "T_F41258"
# 2C: `pop XBC / ret` -- the return value is DISCARDED.
assert a(0xFB3493, 2) == bytes([0x59, 0x0E]), "2C epilogue changed"
# 2B: `pop XIY / cp WA,0 / jr Z` then the five-byte literal at 0xF4FEC8.
assert a(0xFB34A5, 4) == bytes([0x5D, 0xD8, 0xD8, 0x66]), "2B epilogue changed"
assert a(0xFB34AD, 5) == bytes([0xF2, 0xC8, 0xFE, 0xF4, 0x31]), "lda xbc,0xf4fec8"
assert a(0xFB34AA, 3) == bytes([0x0B, 0x05, 0x00]), "push 0x0005 (the length)"
ABORT = b(0xF4FEC8, 5)
assert ABORT == bytes([0xF0, 0x50, 0x29, 0x7E, 0xF7]), ABORT
# neither handler tests the panel screen, while the bulk-dump handler does
assert a(0xFB2826, 5) == bytes([0xC1, 0x7A, 0x20, 0x3F, 0x79]), "bulk-dump screen test"
assert bytes([0x7A, 0x20]) not in a(0xFB3483, 0x12) + a(0xFB3495, 0x36)
# the request's own refusal conditions, every one an instruction operand
assert b(0xF36F9C, 4) == bytes([0xD9, 0xCC, 0x01, 0x00]), "and BC,0x0001 (busy)"
assert b(0xF36FBF, 7) == bytes([0xD2, 0x07, 0x0A, 0x00, 0x3F, 0x00, 0x00]), "count==0"
assert b(0xF36FCA, 2) == bytes([0xE9, 0xE1]), "or XBC,XBC (address==0)"
# the write's own: the count must be exactly 1
assert b(0xF379CB, 7) == bytes([0xD2, 0x07, 0x0A, 0x00, 0x3F, 0x01, 0x00]), "count==1"
WRITE_COUNT = le(b(0xF379D0, 2))
assert WRITE_COUNT == 1

print("4. DIRECTION, AND WHAT COMES BACK")
print("  2B -> command 0x19 -> prom_a 0xFB3495 -> prom_b 0xF36F8C   READ")
print("  2C -> command 0x17 -> prom_a 0xFB3483 -> prom_b 0xF379AB   WRITE")
print("  a READ is refused when: a transfer is already running, or the count")
print("     is 0, or the address is 0, or address+count runs past the region")
print("     end -- and the refusal is answered with %s"
      % " ".join("%02X" % x for x in ABORT))
print("  a WRITE is refused when: the count is not exactly %d, or the address"
      % WRITE_COUNT)
print("     is 0, or the offset is past the region end")
print("  ⚠ the refusal answer exists ONLY for 2B.  prom_a 0xFB3493 is")
print("     `pop XBC / ret`: the 2C handler never reads the routine's verdict,")
print("     so a refused write is SILENT, and an accepted one is not")
print("     acknowledged either")
print("  neither handler tests the panel screen byte (0x207A) that the")
print("     bulk-dump handler tests at its second instruction, so no session")
print("     and no screen is needed")
print()


# --------------------------------------------- 5. the reply frame, byte by byte
# sub_F37DB4 writes the header one immediate at a time.
HDR = []
for off, site, opl in ((0, 0xF37DBC, 3), (1, 0xF37DBF, 4), (2, 0xF37DC3, 4),
                       (3, 0xF37DC7, 4), (4, 0xF37DCB, 4), (5, 0xF37DCF, 4)):
    ins = b(site, opl)
    HDR.append(ins[-1])
assert HDR == [0xF0, 0x50, 0x2C, 0x04, 0x00, 0x11], HDR
# the address is split back into septets by the same 21-bit rule
assert b(0xF37DD8, 6) == bytes([0xE9, 0xCC, 0x00, 0xC0, 0x1F, 0x00])  # and XBC,0x1fc000
assert b(0xF37DDE, 3) == bytes([0xE9, 0xED, 0x0E])                    # sra 14,XBC
assert b(0xF37DE9, 6) == bytes([0xE9, 0xCC, 0x80, 0x3F, 0x00, 0x00])  # and XBC,0x3f80
assert b(0xF37DEF, 3) == bytes([0xE9, 0xED, 0x07])                    # sra 7,XBC
assert b(0xF37DFA, 3) == bytes([0xCB, 0x30, 0x07])                    # res 7,C
# bytes 9 and 10 of the reply are hard zero; byte 11 is this chunk's count
assert b(0xF37E00, 4) == bytes([0xBC, 0x09, 0x00, 0x00]), "reply byte 9 = 00"
assert b(0xF37E04, 4) == bytes([0xBC, 0x0A, 0x00, 0x00]), "reply byte 10 = 00"
assert b(0xF37E08, 3) == bytes([0x8E, 0x0C, 0x23]), "reply byte 11 = the count"
# the continuation flag the transmitter appends is 0
assert b(0xF37EBF, 3) == bytes([0xB4, 0x00, 0x00]), "continuation flag = 00"
# the chunk cap
assert b(0xF36E03, 4) == bytes([0xD8, 0xCF, 0x78, 0x00]), "cp WA,0x0078 moved"
assert b(0xF36E09, 5) == bytes([0xB9, 0x03, 0x02, 0x78, 0x00]), "ld (XBC+3),0x78"
CHUNK_MAX = le(b(0xF36E05, 2))
assert CHUNK_MAX == 120
# the length the transmitter hands the queue is 2n + 15, the checksum span 2n + 13
assert b(0xF37EEB, 5) == bytes([0xD2, 0x09, 0x0A, 0x00, 0x21])   # ld BC,(0x000a09)
assert b(0xF37EF0, 2) == bytes([0xD9, 0x81])                     # add BC,BC
assert b(0xF37EF2, 4) == bytes([0xD9, 0xC8, 0x0F, 0x00])         # add BC,0x000f
WIRE_OVERHEAD = le(b(0xF37EF4, 2))
assert b(0xF37ED0, 4) == bytes([0xDD, 0xC8, 0x0D, 0x00])         # add IY,0x000d
SUM_OVERHEAD = le(b(0xF37ED2, 2))
assert (WIRE_OVERHEAD, SUM_OVERHEAD) == (15, 13)
# the checksum itself: prom_a sub_FB7A90 skips the leading F0
assert a(0xFB7A9F, 2) == bytes([0xEC, 0x61]), "inc 1,XIX (skip the F0)"
assert a(0xFB7AA1, 2) == bytes([0xDB, 0x69]), "dec 1,HL"
assert a(0xFB7AB5, 5) == bytes([0xD8, 0xA0, 0xD9, 0xA0, 0xC9]), "sub WA,WA / sub WA,BC"
assert a(0xFB7AB9, 3) == bytes([0xC9, 0x30, 0x07]), "res 7,A"
MAX_WIRE = 2 * CHUNK_MAX + WIRE_OVERHEAD
assert MAX_WIRE == 255

# ⚠ ON A RACK the model byte is rewritten on the way out.  Both output
# routines open with `calr sub_FB5F65` (a 16-bit RELATIVE call, which is why
# no absolute reference to 0xFB5F65 exists anywhere in either image).
assert a(0xFB7174, 3) == bytes([0x1E, 0xEE, 0xED]), "calr from sub_FB7165"
assert a(0xFB71CA, 3) == bytes([0x1E, 0x98, 0xED]), "calr from sub_FB71BB"
for site, disp in ((0xFB7174, -0x1212), (0xFB71CA, -0x1268)):
    assert (site + 3 + disp) & 0xFFFFFF == 0xFB5F65, "calr target moved"
assert a(0xFB5F6D, 4) == bytes([0xC0, 0xC4, 0x3F, 0x02]), "cp (0x00c4),2 (the strap)"
assert a(0xFB5F95, 4) == bytes([0xD9, 0xCF, 0x2C, 0x00]), "family 2C tested"
assert a(0xFB5FA6, 4) == bytes([0xB9, 0x04, 0x00, 0x01]), "ld (XBC+0x04),0x01"

# --------------------------------------------------- 5b. the 120 cap has a hole
# The message is assembled at 0x000A0B and the data it encodes is read from
# 0x000B0B, so the message has exactly 256 bytes before it reaches its own
# source -- which is why 2*120 + 15 = 255 is the designed ceiling.
for site in (0xF37E28, 0xF37ED5, 0xF37EF7):
    assert b(site, 4) == bytes([0xF2, 0x0B, 0x0A, 0x00]), "message buffer moved"
assert b(0xF36EE0, 4) == bytes([0xF2, 0x0B, 0x0B, 0x00]), "source buffer moved"
MSG_BUF, SRC_BUF = 0x000A0B, 0x000B0B
BUF_ROOM = SRC_BUF - MSG_BUF
assert BUF_ROOM == 256 and MAX_WIRE < BUF_ROOM
# ⚠ BUT every chunk-sizing arm has the SAME two branches, and only one of them
# caps.  Melodic common block, prom_b 0xF36AFE:
assert b(0xF36AFE, 3) == bytes([0xDC, 0xF0, 0x63]), "cp WA,IX (remaining vs asked)"
assert b(0xF36B02, 3) == bytes([0xB9, 0x03, 0x54]), "chunk := the asked-for count"
assert b(0xF36B11, 4) == bytes([0xD8, 0xCF, 0x78, 0x00]), "the 120 test"
assert b(0xF36B17, 5) == bytes([0xB9, 0x03, 0x02, 0x78, 0x00]), "chunk := 120"
assert b(0xF36AE0, 5) == bytes([0xB9, 0x05, 0x02, 0xD9, 0x00]), "block end := 217"
BIG_BLOCK = le(b(0xF36AE3, 2))
assert BIG_BLOCK == 217
# the 43- and 81-byte block helpers have the same shape and no 120 test at all
for site in (0xF368C3, 0xF3691B):
    assert b(site, 5) == bytes([0x9E, 0x0C, 0xF1, 0x63, 0x08]), "cp BC,(XIZ+0x0c)"
for site in (0xF368C8, 0xF36920):
    assert b(site, 6) == bytes([0x9E, 0x0C, 0x21, 0xBC, 0x03, 0x51]), "chunk := asked"
assert bytes([0xD8, 0xCF, 0x78, 0x00]) not in b(0xF36888, 0x58)
assert bytes([0xD8, 0xCF, 0x78, 0x00]) not in b(0xF368E0, 0x58)
# so the LARGEST single reply is not 255: it is the largest block minus one
WORST_N = BIG_BLOCK - 1
WORST_WIRE = 2 * WORST_N + WIRE_OVERHEAD
assert WORST_WIRE == 447 and WORST_WIRE > BUF_ROOM

print("5. THE REPLY")
print("  header  %s + <addr3> + 00 00 <n>" % " ".join("%02X" % x for x in HDR))
print("     the address is THIS CHUNK's address, re-split into the same three")
print("     septets, so a reply stream is self-describing")
print("  body    2 bytes per data byte, high nibble first, then a 00")
print("          continuation flag, the checksum and F7")
print("  length  2n + %d bytes on the wire; the checksum covers 2n + %d, i.e."
      % (WIRE_OVERHEAD, SUM_OVERHEAD))
print("          everything from the 50 through the continuation flag")
print("  n is capped at %d, and clipped to the end of the block it is reading,"
      % CHUNK_MAX)
print("     so the largest reply message is %d bytes" % MAX_WIRE)
print("  the stream continues until the requested count is exhausted, so one")
print("     request can pull a whole region: %d bytes melodic, %d drum"
      % (MEL_LEN, DRM_LEN))
print("  ⚠ the 120 cap is on ONE of the two sizing branches only.  When the")
print("     block has MORE left than the request asked for, the chunk is the")
print("     whole request, uncapped (prom_b 0xF36B02).  A request for %d..%d"
      % (CHUNK_MAX + 1, WORST_N))
print("     bytes inside the %d-byte melodic common block therefore produces"
      % BIG_BLOCK)
print("     ONE reply of up to %d bytes -- past the %d bytes the message has"
      % (WORST_WIRE, BUF_ROOM))
print("     between its own buffer (0x%06X) and the data it is encoding"
      % MSG_BUF)
print("     (0x%06X).  Asking for the block's full %d bytes does NOT do this:"
      % (SRC_BUF, BIG_BLOCK))
print("     that takes the capped branch and comes back as %d + %d."
      % (CHUNK_MAX, BIG_BLOCK - CHUNK_MAX))
print("  ⚠ byte 4 is the literal 00 in the builder, but prom_a sub_FB5F65")
print("     rewrites it to 01 and recomputes the checksum when the model")
print("     strap (0x00C4) reads 2, so a rack's reply carries 04 01 11")
print()


# ------------------------------------------------------------ 6. which port
# The reply path: prom_b T_F40910 -> prom_a sub_FB7AC2 -> sub_FB6F24 + sub_FB7165.
assert b(0xF40910, 4) == bytes([0x1B, 0xC2, 0x7A, 0xFB]), "T_F40910"
assert b(0xF4090C, 4) == bytes([0x1B, 0x90, 0x7A, 0xFB]), "T_F4090C"
assert a(0xFB7ACD, 3) == bytes([0x1E, 0x54, 0xF4]), "calr sub_FB6F24 from FB7AC2"
assert a(0xFB7AD6, 3) == bytes([0x1E, 0x8C, 0xF6]), "calr sub_FB7165 from FB7AC2"
# The refusal path: prom_a 0xFB34B3 sub_FB6F24, 0xFB34BD sub_FB71BB.
assert a(0xFB34B3, 4) == bytes([0x1D, 0x24, 0x6F, 0xFB]), "call sub_FB6F24"
assert a(0xFB34BD, 4) == bytes([0x1D, 0xBB, 0x71, 0xFB]), "call sub_FB71BB"
# sub_FB7165 drives ONE output pair; sub_FB71BB drives TWO.
ONE = a(0xFB7165, 0x56)
TWO = a(0xFB71BB, 0xB5)
P1 = bytes([0x1D, 0xF8, 0x1D, 0xF4])   # call 0xf41df8
P1B = bytes([0x1D, 0x24, 0x07, 0xF4])  # call 0xf40724
P2 = bytes([0x1D, 0x1C, 0x1E, 0xF4])   # call 0xf41e1c
P2B = bytes([0x1D, 0x30, 0x07, 0xF4])  # call 0xf40730
assert P1 in ONE and P1B in ONE and P2 not in ONE and P2B not in ONE, \
    "sub_FB7165 no longer drives exactly one output path"
assert P1 in TWO and P1B in TWO and P2 in TWO and P2B in TWO, \
    "sub_FB71BB no longer drives two output paths"
# the bulk dump uses the same single-path routine
BULK_TX = [s for s in (0xFB6ED8, 0xFB6F99, 0xFB6FEA) if a(s, 1) == b"\x1e"]
assert len(BULK_TX) == 3

print("6. WHICH MIDI OUTPUT")
print("  the REPLY goes out through prom_a sub_FB7165, ONE output path -- the")
print("     same routine the SYSEX BULK DUMP transmitter uses")
print("  the REFUSAL goes out through sub_FB71BB, TWO output paths")
print("  (the published manual says bulk dump is MIDI 1 only; the reply shares")
print("     that routine, the refusal does not)")
print()


# ------------------------------------------------- 7. the block maps (ladders)
def imm32_at(addr):
    return le(b(addr, 4))


def imm16_at(addr):
    return le(b(addr, 2))


# Melodic ladder, sub_F379AB: `cp XIX,<n>` (EC CF imm32) then `push <sel>` (0B imm16)
MEL_LADDER = []
for cp_site, push_site in ((0xF37A19, 0xF37A34), (0xF37A3D, 0xF37A57),
                           (0xF37A5D, 0xF37A77), (0xF37A7D, 0xF37A97),
                           (0xF37A9D, 0xF37AB7), (0xF37ABD, 0xF37AD7),
                           (0xF37ADD, 0xF37AF7), (0xF37AFD, 0xF37B17)):
    assert b(cp_site, 2) == bytes([0xEC, 0xCF]), "cp XIX,imm32 moved at %06X" % cp_site
    assert b(push_site, 1) == bytes([0x0B]), "push imm16 moved at %06X" % push_site
    MEL_LADDER.append((imm32_at(cp_site + 2), imm16_at(push_site + 1)))
assert [t for t, s in MEL_LADDER] == [670, 627, 584, 541, 460, 379, 298, 217]
assert [s for t, s in MEL_LADDER] == [0x41, 0x31, 0x21, 0x11, 4, 3, 2, 1]
# the element blocks are 81 bytes, the modelling blocks 43, and they tile
ELEM = [MEL_LADDER[i][0] - MEL_LADDER[i + 1][0] for i in (4, 5, 6)]
MODEL = [MEL_LADDER[i][0] - MEL_LADDER[i + 1][0] for i in (0, 1, 2)]
assert set(ELEM) == {81} and set(MODEL) == {43}
MEL_COMMON = MEL_LADDER[-1][0]
assert MEL_COMMON == 217 == BIG_BLOCK
assert MEL_COMMON + 4 * 81 == 541 and 541 + 4 * 43 == MEL_LEN, "melodic does not tile"
# the melodic offsets answered by the panel processor, not the sound engine
assert b(0xF37B1D, 6) == bytes([0xEC, 0xCF, 0x87, 0x00, 0x00, 0x00])  # cp XIX,135
assert b(0xF37B72, 6) == bytes([0xEC, 0xCF, 0xCF, 0x00, 0x00, 0x00])  # cp XIX,207
MEL_LOCAL = (imm32_at(0xF37B1F), imm32_at(0xF37B74))
assert MEL_LOCAL == (135, 207)

# Drum ladder, sub_F379AB from 0xF37BA4.
assert b(0xF37BED, 6) == bytes([0xE9, 0xCA, 0x98, 0x01, 0x00, 0x00])  # sub XBC,408
assert b(0xF37BF6, 3) == bytes([0x0B, 0x96, 0x00])                    # push 150
DRM_COMMON = imm32_at(0xF37BEF)
DRM_STRIDE = imm16_at(0xF37BF7)
assert (DRM_COMMON, DRM_STRIDE) == (408, 150)
SUB = []
for site, sel_site in ((0xF37C17, 0xF37C3D), (0xF37C4B, 0xF37C70), (0xF37C7E, 0xF37CA4)):
    assert b(site, 2) == bytes([0xE8, 0xC8]), "add XWA,imm32 moved at %06X" % site
    assert b(sel_site, 1) == bytes([0x0B])
    SUB.append((imm32_at(site + 2) - DRM_COMMON, imm16_at(sel_site + 1)))
assert SUB == [(107, 2), (64, 1), (0, 0)], SUB
assert (DRM_LEN - DRM_COMMON) % DRM_STRIDE == 0
DRM_ENTRIES = (DRM_LEN - DRM_COMMON) // DRM_STRIDE
assert DRM_ENTRIES == 128
assert 64 + 43 + 43 == DRM_STRIDE, "the drum entry does not tile"
assert b(0xF37CAC, 6) == bytes([0xEC, 0xCF, 0x52, 0x00, 0x00, 0x00])  # cp XIX,82
assert b(0xF37CD4, 6) == bytes([0xEC, 0xCF, 0x97, 0x00, 0x00, 0x00])  # cp XIX,151
DRM_LOCAL = (imm32_at(0xF37CAE), imm32_at(0xF37CD6))
assert DRM_LOCAL == (82, 151)

# where a write finally lands
assert b(0xF43470, 4) == bytes([0x1B, 0x6A, 0x61, 0xFD]), "T_F43470 -> 0xFD616A"
assert b(0xF43478, 4) == bytes([0x1B, 0x04, 0x67, 0xFD]), "T_F43478 -> 0xFD6704"
assert b(0xF434A0, 4) == bytes([0x1B, 0x30, 0x1C, 0xF1]), "T_F434A0 -> prom_b 0xF11C30"
# and prom_c's own arithmetic on the same image, which no byte of prom_b knows
assert c(0xFB459E, 6) == bytes([0xE8, 0xC8, 0xA1, 0x04, 0x00, 0x00])
C_OFFSET = le(c(0xFB45A0, 4))
assert C_OFFSET == MEL_LEN + DRM_COMMON + 64, \
    "prom_c's 0x4A1 no longer equals 713 + 408 + 64"

print("7. WHAT IS AT EACH OFFSET")
print("  melodic, base 0x%06X, %d bytes" % (MEL_ADDR, MEL_LEN))
print("     0    .. %3d   common          (selector 00, parameter = offset)" % (MEL_COMMON - 1))
for thr, sel in reversed(MEL_LADDER[4:]):
    print("     %-4d .. %3d   element %d       (selector %02X, parameter = offset - %d)"
          % (thr, thr + 80, sel - 1, sel, thr))
for thr, sel in reversed(MEL_LADDER[:4]):
    print("     %-4d .. %3d   element %d model (selector %02X, parameter = offset - %d)"
          % (thr, thr + 42, (sel >> 4) - 1, sel, thr))
print("     ⚠ offsets %d..%d never reach the sound engine; prom_b answers them"
      % MEL_LOCAL)
print("        itself through T_F434A0")
print("  drum, base 0x%06X, %d bytes" % (DRM_ADDR, DRM_LEN))
print("     0    .. %3d   kit common      (selector 03, parameter = offset)" % (DRM_COMMON - 1))
print("     %d + %d*n + 0   .. +63    entry common      (selector 00)"
      % (DRM_COMMON, DRM_STRIDE))
print("     %d + %d*n + 64  .. +106   entry model 0     (selector 01)"
      % (DRM_COMMON, DRM_STRIDE))
print("     %d + %d*n + 107 .. +149   entry model 1     (selector 02)"
      % (DRM_COMMON, DRM_STRIDE))
print("     n = 0 .. %d, and %d + %d x %d == %d exactly"
      % (DRM_ENTRIES - 1, DRM_COMMON, DRM_ENTRIES, DRM_STRIDE, DRM_LEN))
print("     ⚠ offsets %d..%d are answered by prom_b itself, as above" % DRM_LOCAL)
print("  a write reaches prom_a 0xFD616A (melodic) or 0xFD6704 (drum) -- the")
print("     two routines the panel's own tone editor commits a dial turn")
print("     through (FINDINGS-l7a1429-field-editors.md section 1c)")
print("  prom_c reaches the same image at 0x0087D2 and its percussion")
print("     wave-select record sits at +0x%03X == %d + %d + %d"
      % (C_OFFSET, MEL_LEN, DRM_COMMON, 64))
print()


# ----------------------------------------------- 8. is the panel anywhere near
def boundaries(path):
    s = set()
    for line in open(path, encoding="utf-8", errors="replace"):
        m = re.search(r";\s(F[0-9A-F]{5})\s\s", line)
        if m:
            s.add(int(m.group(1), 16))
    return s


BLOCK_LO, BLOCK_HI = 0x000A00, 0x000A0B
ABS24_PREFIX = (0xC2, 0xD2, 0xE2, 0xF2)


def census(img, base, bounds):
    hits = []
    for addr in range(BLOCK_LO, BLOCK_HI + 1):
        key = bytes([addr & 0xFF, (addr >> 8) & 0xFF, (addr >> 16) & 0xFF])
        i = 0
        while True:
            i = img.find(key, i)
            if i < 0:
                break
            if i >= 1 and img[i - 1] in ABS24_PREFIX and (base + i - 1) in bounds:
                hits.append((base + i - 1, addr))
            i += 1
    return sorted(hits)


BND_A = boundaries(os.path.join(ROOT, "prom_a", "wsa1_prom_a.s"))
BND_B = boundaries(os.path.join(ROOT, "prom_b", "wsa1_prom_b.s"))
assert len(BND_A) > 100000 and len(BND_B) > 5000
HITS_A = census(A, A_BASE, BND_A)
HITS_B = census(B, B_BASE, BND_B)
assert HITS_A == [], "prom_a now names the transfer state block: %r" % HITS_A[:5]
assert len(HITS_B) >= 60, len(HITS_B)
SPAN = (min(x for x, _ in HITS_B), max(x for x, _ in HITS_B))
assert SPAN[0] >= 0xF36000 and SPAN[1] <= 0xF38000, SPAN

print("8. CAN A PLAYER GET AT THIS FROM THE PANEL?")
print("  the transfer lives entirely in the state block 0x%06X..0x%06X"
      % (BLOCK_LO, BLOCK_HI))
print("  instruction-boundary census of BOTH CPU-1 images, 24-bit absolute")
print("     operands, %d + %d boundaries swept:" % (len(BND_A), len(BND_B)))
print("       prom_a (panel, screens, menus, bulk dump)   %d references" % len(HITS_A))
print("       prom_b (the System Exclusive engine)        %d references, all"
      % len(HITS_B))
print("          inside 0x%06X..0x%06X" % SPAN)
print("  ⇒ nothing a button can reach arms a transfer.  The SYSEX BULK DUMP")
print("     screen's five rows send 0x080000 / 0x100000 / 0x140000 / 0x180000")
print("     and none of them is in this space.")
print("  the DATA the space exposes is of course reachable -- it is the tone")
print("     editor's own working copy -- but the MESSAGES are remote-only.")
print()


# ------------------------------------------------------------- 9. worked wire
def septets(v):
    return [(v >> 14) & 0x7F, (v >> 7) & 0x7F, v & 0x7F]


def checksum(body):
    return (-sum(body)) & 0x7F


def frame(fam, nn, addr, count, data=()):
    body = [0x50, fam, 0x04, nn, 0x11] + septets(addr) + septets(count)
    for d in data:
        body += [(d >> 4) & 0x0F, d & 0x0F]
    body += [0x00]                       # continuation flag
    return [0xF0] + body + [checksum(body), 0xF7]


READ8 = frame(0x2B, 0x00, MEL_ADDR, 8)
WRITE1 = frame(0x2C, 0x00, MEL_ADDR + 217, 1, [100])
DRUMX = frame(0x2B, 0x00, DRM_ADDR + 16384, 64)
for f in (READ8, WRITE1, DRUMX):
    assert f[0] == 0xF0 and f[-1] == 0xF7
    assert sum(f[1:-1]) % 128 == 0, "the worked example does not check out"
    assert all(x < 0x80 for x in f[1:-1])
assert len(WRITE1) == WIRE_OVERHEAD + 2 * 1
assert DRUMX[6] == 0x19, "the drum example does not use page 19"
assert WRITE1[6] == 0x10 and READ8[6] == 0x10

print("9. THE WIRE, WORKED")
print("  READ  8 bytes from the start of the melodic image (offset 0)")
print("        %s" % " ".join("%02X" % x for x in READ8))
print("        answered by  F0 50 2C 04 00 11 10 00 00 00 00 08 <16 nibbles> 00 <sum> F7")
print("  WRITE 100 into melodic offset 217 (element 0, parameter 0)")
print("        %s" % " ".join("%02X" % x for x in WRITE1))
print("        offset 217 -> septets %s; value 100 -> nibbles 06 04"
      % " ".join("%02X" % x for x in septets(MEL_ADDR + 217)))
print("        no answer of any kind comes back")
print("  READ  64 bytes from drum offset 16384 -- the page-19 case")
print("        %s" % " ".join("%02X" % x for x in DRUMX))
print("        16384 = entry %d, sub-block +%d, so this is that entry's"
      % ((16384 - DRM_COMMON) // DRM_STRIDE, (16384 - DRM_COMMON) % DRM_STRIDE))
print("        modelling block 0")
print()

if "--map" in sys.argv:
    print("EVERY MELODIC BLOCK")
    print("   offset  bytes  selector  block")
    print("   %6d  %5d        00  common" % (0, MEL_COMMON))
    for thr, sel in reversed(MEL_LADDER[4:]):
        print("   %6d  %5d        %02X  element %d" % (thr, 81, sel, sel - 1))
    for thr, sel in reversed(MEL_LADDER[:4]):
        print("   %6d  %5d        %02X  element %d modelling" % (thr, 43, sel, (sel >> 4) - 1))
    print()
    print("EVERY DRUM BLOCK  (first three entries and the last)")
    print("   offset  bytes  selector  block")
    print("   %6d  %5d        03  kit common" % (0, DRM_COMMON))
    for n in (0, 1, 2, DRM_ENTRIES - 1):
        for rel, sel in reversed(SUB):
            size = 64 if rel == 0 else 43
            print("   %6d  %5d        %02X  entry %d %s"
                  % (DRM_COMMON + DRM_STRIDE * n + rel, size, sel, n,
                     "common" if rel == 0 else "modelling %d" % (sel - 1)))
        if n == 2:
            print("      ...")
    print()

if "--census" in sys.argv:
    print("EVERY REFERENCE TO THE TRANSFER STATE BLOCK")
    for site, addr in HITS_B:
        print("  prom_b 0x%06X  names 0x%06X" % (site, addr))
    print("  prom_a: none")
    print()

print("OK")
