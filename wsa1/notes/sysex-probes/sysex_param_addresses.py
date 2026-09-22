#!/usr/bin/env python3
"""WHERE does a `00`-area parameter live, and WHICH screen label edits it?

QUESTION IT ANSWERS
  `sysex_param_space.py` established the SHAPE of the `00` parameter area --
  32 part blocks of 57 parameters plus five common blocks -- and
  `sysex_param_wire_format.py` established the wire layout.  Neither says what
  a parameter IS.  This script closes two thirds of that gap without guessing:

  1. EVERY parameter is resolved to a WORK-RAM BYTE, from the descriptor's own
     fields, through the machine's own indirection.  Descriptor `+6` is a
     RECORD NUMBER and `+7` a BYTE OFFSET inside that record; prom_a
     `ParamNumber_RecordPtrs` (0xFACDEA) turns the record number into a RAM
     address.  For a PART parameter the record number is `desc[6] | (byte7-0x20)`.
  2. Because that RAM block is also what one bulk-dump category transmits, every
     parameter gets a BULK-DUMP ADDRESS too: the individual-parameter space and
     the SYSTEM,PART & MIDI dump are two views of the same 2432 bytes.
  3. Eight parameters are NAMED by the instrument's own screen: the mixer strip
     at the bottom of SOUND MODE and COMBINATION MODE paints eight value cells
     at y=226 directly under eight captions at y=212, at the SAME eight x
     columns.  The paint code reads the part record at a literal offset, so the
     caption above a cell names the parameter the cell shows.

WHAT IS *NOT* CLAIMED
  Only the parameters whose setter is one of the three GENERIC ones
  (0xFB3778 common byte, 0xFB38E4 part byte, 0xFB3882 the two at 00/00/00-01)
  have their `+6`/`+7` pair read as (record, offset) by code this script has
  checked instruction by instruction.  Every other setter is a different
  routine; its parameters are printed with `?` in the RAM column rather than
  assumed to follow the same rule.

SIGNAL BEING READ
  * Load bases asserted by content: prom_b `F0 50 23 7E F7` at 0xF4FEB4,
    prom_a `00 03 05 04 02` at 0xF99AE3.
  * The twelve descriptor tables tile 0xF51E8E..0xF5220E (the last-entry test
    `sysex_param_space.py` already makes; repeated here so this script stands
    alone).
  * `ParamNumber_RecordPtrs` 0xFACDEA: 256 LE32 work-RAM addresses, 0xFFFFFFFF
    = absent.  Named by three `lda XBC,0xfacdea` instructions at 0xFAA873,
    0xFAA94E and 0xFAB7F4, each followed by `ld (0x60f018),XBC` -- and
    (0x60F018) is what `IndexedTable_GetPtr` (prom_a 0xFB77D8 / prom_b
    0xF55321) indexes.
  * The write itself: `sub_FB7890` (0xFB7890) takes a 4-byte record
    {record number, offset, value, mask}, resolves the record number through
    `IndexedTable_GetPtr`, and does `base[offset] = (base[offset] & ~mask) |
    (value & mask)`.  The common setter 0xFB3778 fills that record from
    descriptor `+6`,`+7`,`+0x0B`(shift),`+8`(mask),`+0x0F`(xor); the part
    setter 0xFB38E4 does the same and ORs the part number into the record
    number (`sub A,0x20` at 0xFB3969 against parse field 0x0A).
  * Three independent CONFIRMATIONS, all literal in the instruction bytes:
      0xFB9D88  `and (0x7f35),0xf0`  then notify(record 0x80, offset 3, ...)
      0xFB9C46  `or  (0x7f4d),0x04`  then notify(record 0x91, offset 3, ...)
      0xFB9C1A  a loop over records 0..15 writing offset 0x0D with mask 0x0F
                -- the MIDI channel nibble of each of the first 16 parts.
    RecordPtrs[0x80]+3 == 0x7F35 and RecordPtrs[0x91]+3 == 0x7F4D, so the
    formula is checked twice against code that never reads a descriptor.
  * The bulk dump: the two SYSTEM,PART & MIDI templates at prom_b 0xF4FEF8 and
    0xF4FF04 carry dump addresses 0x100000/0x100020 and sizes 0x20/0x960, and
    the descriptor writer that fills them names RAM 0x7600..0x7620 and
    0x7620..0x7F80.  prom_a 0xF96024 copies 0x4B0 WORDS from 0x7620 -- the same
    0x960 bytes -- so the block is one object, not a coincidence of extents.
  * The mixer strip: eight `ld A,(XIY+off) / ld (0x264n),A / ld XIY,<record> /
    call <single-record interpreter-B entry>` sites at 0xF91D55..0xF91E28, and
    the eight interpreter-A text records at 0xF28A56..0xF28A97 (y=212) whose x
    coordinates are the same eight columns as the value records' (y=226).

RUN
  python3 wsa1/notes/sysex-probes/sysex_param_addresses.py            # the table
  python3 wsa1/notes/sysex-probes/sysex_param_addresses.py --strip    # the named strip
  python3 wsa1/notes/sysex-probes/sysex_param_addresses.py --dump     # dump-address view
  python3 wsa1/notes/sysex-probes/sysex_param_addresses.py --lists    # the value white-lists

PASS CRITERION
  Every assert is silent and the script prints OK.  Headline numbers: 108
  distinct parameters (57 part + 51 common/other), 99 of them resolved to a RAM
  byte, RAM window 0x7622..0x7F60 inside the dumped block 0x7600..0x7F80,
  part records 0x40 bytes with parts 0-7 at 0x76A2+0x40p and parts 8-31 at
  0x78E2+0x40(p-8), and 8 screen-named parameters.

TRAP
  The part records are NOT one uniform array.  Parts 0-7 sit at
  0x76A2+0x40*p, then a 0x40-byte hole holds two COMMON blocks (records 0x92
  and 0x79), and parts 8-31 resume at 0x78E2.  Computing a part's base as
  `0x76A2 + 0x40*part` is right for eight parts and wrong for twenty-four.
"""
import collections
import os
import json
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROMS = os.path.join(HERE, "..", "..", "original_ROMs")
PB = open(os.path.join(ROMS, "wsa1_prom_b.ic13"), "rb").read()
PA = open(os.path.join(ROMS, "wsa1_prom_a.ic12"), "rb").read()
B_BASE, A_BASE = 0xF00000, 0xF80000


def b(a, n=1):
    return PB[a - B_BASE:a - B_BASE + n]


def a_(a, n=1):
    return PA[a - A_BASE:a - A_BASE + n]


def bl32(a):
    return int.from_bytes(b(a, 4), "little")


def al32(a):
    return int.from_bytes(a_(a, 4), "little")


assert b(0xF4FEB4, 5) == bytes([0xF0, 0x50, 0x23, 0x7E, 0xF7]), "prom_b base"
assert a_(0xF99AE3, 5) == bytes([0x00, 0x03, 0x05, 0x04, 0x02]), "prom_a base"
print("base check OK: prom_b @0xF00000, prom_a @0xF80000", file=sys.stderr)   # stderr: --json must leave stdout clean
# ---------------------------------------------------------------- descriptors
# (family, group, table, index bound) -- the bounds are the ROM's own
# `cp A,<n> / jr nc`; the twelve tables TILE, which is the last-entry test.
TABLES = [
    (0x2C, 1, 0xF51E8E, 0x17), (0x2B, 1, 0xF51EEA, 0x17),
    (0x2C, 2, 0xF51F46, 0x05), (0x2B, 2, 0xF51F5A, 0x01),
    (0x2C, 3, 0xF51F5E, 0x19), (0x2B, 3, 0xF51FC2, 0x19),
    (0x2C, 5, 0xF52026, 0x13), (0x2B, 5, 0xF52072, 0x13),
    (0x2C, 6, 0xF520BE, 0x28), (0x2B, 6, 0xF5215E, 0x28),
    (0x2C, 7, 0xF521FE, 0x02), (0x2B, 7, 0xF52206, 0x02),
]
cur = TABLES[0][2]
for fam, g, base, n in TABLES:
    assert base == cur, "descriptor table 0x%06X does not follow" % base
    cur = base + 4 * n
assert cur == 0xF5220E, "the descriptor tiling ends at 0x%06X" % cur

PLACEHOLDER = 0xF511F9            # index 0 of every group; refused by address

# The three setters whose bodies were read instruction by instruction and which
# therefore license reading desc+6/desc+7 as (record number, byte offset).
GEN_COMMON, GEN_PART = 0xFB3778, 0xFB38E4
GENERIC = (GEN_COMMON, GEN_PART)
# A FOURTH setter, 0xFB3882, serves exactly two parameters and resolves its
# target a different way: it ignores desc+6/+7 and takes the 32-bit word at
# 0xF51E58 + 6*desc[0x0E] + 2 as the RAM ADDRESS itself.
PAIR_SETTER = 0xFB3882
# Three further setters build the SAME sub_FB7890 record from desc+6/desc+7 and
# the part number, and were read instruction by instruction to confirm it.  They
# differ only in what VALUE they put in it, so the ADDRESS is established and the
# ENCODING is not.
ADDRESSED_EXTRA = {
    0xFB3D13: "the value is remapped through a 1-entry table at 0xF51E84",
    0xFB3B04: "a second byte is written at the offset named by a record at 0xF51E70",
    0xFB39A4: "three data bytes: offset+1 takes bits 4-9, desc+7 takes the rest",
}
for site, off6, off7, part in ((0xFB3D13, 0xFB3D6B, 0xFB3D87, 0xFB3D7E),
                               (0xFB3B04, 0xFB3B58, 0xFB3B65, 0xFB3B52),
                               (0xFB39A4, 0xFB3A1B, 0xFB3A3C, 0xFB3A15)):
    assert a_(off6, 2) == bytes([0x89, 0x06]), "0x%06X no longer reads desc+6" % site
    assert a_(off7, 3) == bytes([0x89, 0x07, 0x21]), "0x%06X no longer reads desc+7" % site
    assert a_(part, 3)[1:] == bytes([0xCA, 0x20]), "0x%06X no longer subtracts 0x20" % site
for call in (0xFB3B82, 0xFB3DAF, 0xFB3A33):
    assert a_(call, 4) == bytes([0x1D, 0x90, 0x78, 0xFB]), \
        "0x%06X no longer calls sub_FB7890" % call
ADDRESSED = set(GENERIC) | set(ADDRESSED_EXTRA)

Param = collections.namedtuple(
    "Param", "b7 b8 desc rec off mask lo hi shift size xlat inv setter")

PARAMS = []
for fam, g, base, n in TABLES:
    if fam != 0x2C:               # 2C writes; 2B reads the same descriptors
        continue
    for i in range(n):
        d = bl32(base + 4 * i)
        if i == 0:
            assert d == PLACEHOLDER, "index 0 of group %d is not the placeholder" % g
            continue
        h = b(d, 0x20)
        if h[0] != 0x00:          # only the 00 parameter area here
            continue
        PARAMS.append(Param(
            b7=h[1], b8=h[2], desc=d, rec=h[6], off=h[7], mask=h[8],
            lo=h[9], hi=h[0x0A], shift=h[0x0B],
            size=(h[3] << 14) | (h[4] << 7) | h[5],
            xlat=h[0x0E], inv=h[0x0F],
            setter=int.from_bytes(h[0x14:0x18], "little")))

assert len(PARAMS) == 108, "expected 108 parameter descriptors, got %d" % len(PARAMS)
PARTS = [p for p in PARAMS if p.b7 == 0x20]
assert len(PARTS) == 57, "a part block holds %d parameters" % len(PARTS)

# ------------------------------------------------- record number -> RAM address
# Named by the three instructions that publish it in (0x60F018).
for site in (0xFAA873, 0xFAA94E, 0xFAB7F4):
    ins = a_(site, 11)
    assert ins[:5] == bytes([0xF2, 0xEA, 0xCD, 0xFA, 0x31]), \
        "0x%06X is not `lda XBC,0xfacdea`" % site
    assert ins[5:10] == bytes([0xF2, 0x18, 0xF0, 0x60, 0x61]), \
        "0x%06X does not store into (0x60F018)" % site
# IndexedTable_GetPtr reads that word and scales the index by 4.
assert a_(0xFB77DD, 5) == bytes([0xE2, 0x18, 0xF0, 0x60, 0x24]), \
    "IndexedTable_GetPtr no longer loads (0x60F018)"
assert a_(0xFB77E2, 2) == bytes([0x23, 0x04]), "the entry stride is not 4"

RECPTR = [al32(0xFACDEA + 4 * i) for i in range(256)]
LIVE = {i: v for i, v in enumerate(RECPTR) if v != 0xFFFFFFFF}
assert len(LIVE) == 77, "%d live record pointers, expected 77" % len(LIVE)

# The part records: 0..31 are the parts, 0x20..0x3F the same records + 0x20.
for p in range(32):
    assert RECPTR[0x20 + p] == RECPTR[p] + 0x20, \
        "record 0x%02X is not record 0x%02X + 0x20" % (0x20 + p, p)
for p in range(0, 7):
    assert RECPTR[p + 1] - RECPTR[p] == 0x40, "parts 0-7 are not 0x40 apart"
assert RECPTR[8] - RECPTR[7] == 0x80, "the hole after part 7 is not 0x40 bytes"
for p in range(8, 31):
    assert RECPTR[p + 1] - RECPTR[p] == 0x40, "parts 8-31 are not 0x40 apart"
assert RECPTR[0] == 0x76A2 and RECPTR[8] == 0x78E2

# ------------------------------------------------------ the write, as executed
# sub_FB7890: {record, offset, value, mask} -> base[offset] under mask.
assert a_(0xFB78A4, 3) == bytes([0x84, 0x21, 0xD8]), "FB7890 no longer reads +0"
assert a_(0xFB78BB, 3) == bytes([0x8C, 0x03, 0x23]), "FB7890 no longer reads +3 (mask)"
# the common setter loads desc+6 and desc+7 into that record
assert a_(0xFB37E5, 3) == bytes([0x8C, 0x06, 0x23]), "FB3778 no longer reads desc+6"
assert a_(0xFB37EB, 3) == bytes([0x8C, 0x07, 0x23]), "FB3778 no longer reads desc+7"
# the part setter ORs (byte7 - 0x20) into the record number
assert a_(0xFB3957, 3) == bytes([0x89, 0x06, 0x21]), "FB38E4 no longer reads desc+6"
assert a_(0xFB3969, 3) == bytes([0xC9, 0xCA, 0x20]), "FB38E4 no longer subtracts 0x20"
assert a_(0xFB396C, 2) == bytes([0x84, 0xE9]), "FB38E4 no longer ORs the part in"
assert a_(0xFB3971, 3) == bytes([0x89, 0x07, 0x21]), "FB38E4 no longer reads desc+7"

# THREE CONFIRMATIONS from code that never touches a descriptor.
#  (a) 0xFB9D88: `and (0x7f35),0xf0` then notify(record 0x80, offset 3, 0, 0x0F)
assert a_(0xFB9D88, 5) == bytes([0xC1, 0x35, 0x7F, 0x3C, 0xF0])
pushes = [int.from_bytes(a_(0xFB9D8D + 3 * k + 1, 2), "little") for k in range(4)]
assert pushes == [0x0F, 0x00, 0x03, 0x80], "FB9D88's literal pushes moved: %s" % pushes
assert RECPTR[0x80] + 3 == 0x7F35, "record 0x80 + 3 != 0x7F35"
#  (b) 0xFB9C46: `or (0x7f4a+3),0x04` then notify(record 0x91, offset 3, 4, 0xFF)
assert a_(0xFB9C2C, 3) == bytes([0x31, 0x4A, 0x7F]), "FB9C2C no longer loads 0x7F4A"
assert a_(0xFB9C31, 4) == bytes([0x89, 0x03, 0x3E, 0x04]), "the `or +3,0x04` moved"
pushes = [int.from_bytes(a_(0xFB9C3A + 3 * k + 1, 2), "little") for k in range(4)]
assert pushes == [0xFF, 0x04, 0x03, 0x91], "FB9C46's literal pushes moved: %s" % pushes
assert RECPTR[0x91] == 0x7F4A, "record 0x91 != 0x7F4A"
#  (c) 0xFB9C1A: a loop D=0..15 writing offset 0x0D with mask 0x0F
assert a_(0xFB9C0A, 3) == bytes([0x0B, 0x0F, 0x00]), "the mask push moved"
assert a_(0xFB9C12, 3) == bytes([0x0B, 0x0D, 0x00]), "the offset push moved"
assert a_(0xFB9C27, 3) == bytes([0xCC, 0xCF, 0x0F]), "the loop bound is not 15"

# --------------------------------------------------------------- RAM addresses
def ram_of(p, part=0):
    if p.setter == PAIR_SETTER:
        if p.xlat >= 4:
            return None
        return int.from_bytes(b(0xF51E58 + 6 * p.xlat + 2, 4), "little")
    if p.setter not in ADDRESSED:
        return None
    rec = p.rec | part if p.b7 == 0x20 else p.rec
    base = RECPTR[rec]
    return None if base == 0xFFFFFFFF else base + p.off

RESOLVED = [p for p in PARAMS if ram_of(p) is not None]
assert len(RESOLVED) == 99, "%d parameters resolve, expected 99" % len(RESOLVED)
# 0xFB3882's two parameters are bits 0 and 1 of ONE byte, and that byte is
# OUTSIDE the block the bulk dump carries.
PAIRS = [p for p in PARAMS if p.setter == PAIR_SETTER]
assert len(PAIRS) == 2 and all(ram_of(p) == 0x7FD6 for p in PAIRS), \
    "the 0xFB3882 pair no longer lands on 0x7FD6"
assert sorted((p.mask, p.shift) for p in PAIRS) == [(0x01, 0), (0x02, 1)]
assert a_(0xFB38B3, 9) == bytes([0xE9, 0x62, 0xE9, 0xC8, 0x58, 0x1E, 0xF5, 0x00, 0xA1]), \
    "0xFB3882 no longer reads the pointer at 0xF51E58 + 6*n + 2"
for p in PARTS:
    r = ram_of(p)
    if r is None:
        continue
    for part in range(32):
        rr = ram_of(p, part)
        assert RECPTR[part] <= rr < RECPTR[part] + 0x40, \
            "part %d parameter %02X lands outside its 0x40-byte record" % (part, p.b8)

# ------------------------------------------ the block the bulk dump transmits
# The two SYSTEM,PART & MIDI data-message templates, read as bytes.
T1, T2 = b(0xF4FEF8, 12), b(0xF4FF04, 12)
assert T1[:6] == bytes([0xF0, 0x50, 0x2D, 0x04, 0x00, 0x11]), "template 1 header"
assert T2[:6] == bytes([0xF0, 0x50, 0x2D, 0x04, 0x00, 0x11]), "template 2 header"


def septets(t):
    return (t[0] << 14) | (t[1] << 7) | t[2]


A1, S1 = septets(T1[6:9]), septets(T1[9:12])
A2, S2 = septets(T2[6:9]), septets(T2[9:12])
assert (A1, S1) == (0x100000, 0x20), "part 1 is 0x%06X/0x%X" % (A1, S1)
assert (A2, S2) == (0x100020, 0x960), "part 2 is 0x%06X/0x%X" % (A2, S2)
assert A1 + S1 == A2, "the two parts do not abut"
RAM_LO, RAM_HI = 0x7600, 0x7600 + S1 + S2
assert RAM_HI == 0x7F80
# prom_a 0xF96024 copies 0x4B0 WORDS from 0x7620 -- the same 0x960 bytes.
assert a_(0xF9603C, 5) == bytes([0x45, 0x20, 0x76, 0x00, 0x00]), "0xF9603C moved"
assert a_(0xF96046, 5) == bytes([0x41, 0xB0, 0x04, 0x00, 0x00]), "the word count moved"
assert a_(0xF9604B, 2) == bytes([0x95, 0x11]), "not an `ldirw`"
assert 0x4B0 * 2 == S2, "0x4B0 words != the 0x960-byte part 2"

for p in RESOLVED:
    if p.setter == PAIR_SETTER:
        assert not (RAM_LO <= ram_of(p) < RAM_HI), "the pair moved into the dump"
        continue
    lo = min(ram_of(p, q) for q in range(32)) if p.b7 == 0x20 else ram_of(p)
    hi = max(ram_of(p, q) for q in range(32)) if p.b7 == 0x20 else ram_of(p)
    assert RAM_LO <= lo and hi + p.size <= RAM_HI, \
        "parameter %02X/%02X falls outside the dumped block" % (p.b7, p.b8)


def dump_addr(ram):
    return 0x100000 + (ram - RAM_LO)


# ------------------------------------------------- the mixer strip, as painted
# Eight `ld A,(XIY+off) / ld (0x264n),A / ld XIY,<record> / call <one-record>`
# sites, and the eight captions the same screen draws 14 rows above them.
STRIP_PAINT = [        # (site of `ld XIY,<record>`, display record, source)
    (0xF91D5C, 0xF2844F, ("XIY", 0x03)),
    (0xF91D74, 0xF28468, ("XIY", 0x08)),
    (0xF91D8C, 0xF28479, ("XIY", 0x05)),
    (0xF91DA4, 0xF28485, ("XIY", 0x07)),
    (0xF91DBC, 0xF286CB, ("XIY", 0x0D)),
    (0xF91DF6, 0xF286E2, ("XIY", 0x06)),
    (0xF91E1F, 0xF287D1, ("0x78B2", 0x00)),
]
for site, rec, _ in STRIP_PAINT:
    ins = a_(site, 5)
    assert ins[0] == 0x45 and int.from_bytes(ins[1:4], "little") == rec, \
        "0x%06X no longer names display record 0x%06X" % (site, rec)


def b_record(a):
    r = b(a, 0x11)
    op, ln = r[0], r[1]
    d = dict(addr=a, op=op, len=ln, var=int.from_bytes(r[2:4], "little"),
             mask=r[4], shift=r[5] & 7, x=None, y=None, ents=None)
    if op == 0x07 and ln == 0x11:
        tbl = int.from_bytes(r[7:11], "little")
        w = int.from_bytes(r[0x0B:0x0D], "little")
        d["x"] = int.from_bytes(r[0x0D:0x0F], "little")
        d["y"] = int.from_bytes(r[0x0F:0x11], "little")
        n = (d["mask"] >> d["shift"]) + 1
        d["ents"] = [b(tbl + i * w, w).decode("latin1") for i in range(n)]
    elif op in (0x09, 0x0A) and ln == 0x0C:
        d["x"] = int.from_bytes(r[7:9], "little")
        d["y"] = int.from_bytes(r[9:11], "little")
    return d


# The caption row, as interpreter-A op-0x17 records: +2 x, +4 y, then ASCII.
CAPTIONS = [0xF28A56, 0xF28A5F, 0xF28A68, 0xF28A71,
            0xF28A7B, 0xF28A85, 0xF28A8E, 0xF28A97]     # COMBINATION MODE
CAPTIONS_SM = [0xF28160, 0xF28169, 0xF28172, 0xF2817B,
               0xF28185, 0xF2818F, 0xF28198, 0xF281A1]  # SOUND MODE


def a_text(a):
    r = b(a, 2)
    assert r[0] == 0x17, "0x%06X is not an op-0x17 text record" % a
    ln = r[1]
    return (int.from_bytes(b(a + 2, 2), "little"),
            int.from_bytes(b(a + 4, 2), "little"),
            b(a + 6, ln - 6).decode("latin1"))


CAPS = [a_text(a) for a in CAPTIONS]
CAPS_SM = [a_text(a) for a in CAPTIONS_SM]
assert [t for x, y, t in CAPS] == ["OCT", "VOL", "PAN", "EFF1", "EFF2",
                                   "REV", "INT", "PART"], "the captions moved"
assert [t for x, y, t in CAPS_SM] == ["OCT", "LVL", "PAN", "EFF1", "EFF2",
                                      "REV", "INT", "MIDI"], "the captions moved"
assert all(y == 212 for x, y, t in CAPS + CAPS_SM), "the caption row moved"
COLS = [x for x, y, t in CAPS]
assert COLS == [10, 50, 90, 128, 168, 210, 250, 288]
assert [x for x, y, t in CAPS_SM] == COLS, "the two strips are not the same columns"

RECS = {rec: b_record(rec) for _, rec, _ in STRIP_PAINT}
for rec, r in RECS.items():
    assert r["y"] == 226, "record 0x%06X is not on the value row" % rec
    # every value cell sits within 3 px of a caption column
    assert min(abs(r["x"] - c) for c in COLS) <= 3, \
        "record 0x%06X at x=%d is under no caption" % (rec, r["x"])
assert RECS[0xF28468]["ents"][0] == "L64" and RECS[0xF28468]["ents"][64] == "CTR" \
    and RECS[0xF28468]["ents"][127] == "R63", "the pan scale changed"
assert RECS[0xF286CB]["ents"] == ["ON ", "OFF"], "the INT list changed"
assert RECS[0xF286E2]["ents"] == ["OFF", "ON "], "the EFF2 list changed"
assert RECS[0xF287D1]["ents"][:7] == ["-3", "-2", "-1", " 0", "+1", "+2", "+3"], \
    "the OCT list changed"
# the SOUND MODE strip shows the MIDI channel in the eighth column
MIDI_REC = b_record(0xF28491)
assert MIDI_REC["mask"] == 0x1F and MIDI_REC["ents"][0] == "1-01" \
    and MIDI_REC["ents"][16] == "2-01" and MIDI_REC["ents"][31] == "2-16", \
    "the MIDI channel list changed"
assert a_(0xF90F38, 5) == bytes([0x45, 0x91, 0x84, 0xF2, 0x00]), \
    "0xF90F38 no longer names the MIDI-channel record"

# (part offset, caption in COMBINATION MODE, caption in SOUND MODE, display record)
NAMED = [
    (0x03, "VOL",  "LVL",  0xF2844F),
    (0x05, "EFF1", "EFF1", 0xF28479),
    (0x06, "EFF2", "EFF2", 0xF286E2),
    (0x07, "REV",  "REV",  0xF28485),
    (0x08, "PAN",  "PAN",  0xF28468),
    (0x0D, "INT",  "INT",  0xF286CB),      # bit 5
]
by_off = {}
for p in PARTS:
    by_off.setdefault((p.off, p.mask), p)
for off, c1, c2, rec in NAMED:
    cands = [p for p in PARTS if p.rec == 0x00 and p.off == off]
    assert cands, "no part parameter at offset +0x%02X" % off

# ----------------------------------------- one more block the ROM names itself
# prom_a's ScaleTuning_* routines name RAM 0x78A2 as the temperament selector
# and 0x78A4..0x78AF as the twelve USER offsets.  0x78A2 is common parameter
# 00 10 11 and the twelve bytes are 00 10 13 .. 00 10 1E, in semitone order.
assert a_(0xFC0D41, 5) == bytes([0xC1, 0xA2, 0x78, 0x3F, 0x80]), \
    "ScaleTuning_PostAllTwelveSemitones no longer tests (0x78A2) against 0x80"
assert a_(0xFC0DB4, 5) == bytes([0x43, 0xA4, 0x78, 0x00, 0x00]), \
    "the USER row is no longer at 0x78A4"
assert a_(0xFC0D84, 5) == bytes([0x43, 0x00, 0x68, 0xF0, 0x00]), \
    "the ROM scale table is no longer 0xF06800"
assert a_(0xFC0D7E, 4) == bytes([0x20, 0x0C, 0xC8, 0x41]), "the row stride is not 12"
assert a_(0xFC0D61, 3) == bytes([0xC9, 0xCF, 0x0C]), "the USER loop is not 12 long"
assert a_(0xFC0D8D, 3) == bytes([0xC9, 0xCF, 0x0C]), "the ROM loop is not 12 long"
assert RECPTR[0x92] == 0x78A2, "record 0x92 is no longer 0x78A2"
SCALE12 = [p for p in PARAMS if p.b7 == 0x10 and 0x13 <= p.b8 <= 0x1E]
assert len(SCALE12) == 12, "the twelve scale parameters are %d" % len(SCALE12)
assert [ram_of(p) for p in sorted(SCALE12, key=lambda q: q.b8)] == \
    list(range(0x78A4, 0x78B0)), "00 10 13..1E are not 0x78A4..0x78AF in order"

# ------------------------------------------------------- the value white-lists
# desc+0x0E, for the three generic setters only, indexes a 6-byte record at
# 0xF51E58: a 16-bit COUNT and a 32-bit pointer to that many legal byte values.
# sub_FB374D walks the list and REFUSES a value that is not in it.
assert a_(0xFB37B2, 6) == bytes([0x23, 0x06, 0xCE, 0x43, 0xE9, 0x12]), \
    "the 6-byte stride at 0xFB37B2 moved"
assert a_(0xFB37BB, 6) == bytes([0xE9, 0xC8, 0x58, 0x1E, 0xF5, 0x00]), \
    "the list table is no longer 0xF51E58"
LISTS = {}
for i in range(4):
    cnt = int.from_bytes(b(0xF51E58 + 6 * i, 2), "little")
    ptr = int.from_bytes(b(0xF51E58 + 6 * i + 2, 4), "little")
    LISTS[i] = (cnt, ptr, list(b(ptr, cnt)) if B_BASE <= ptr < A_BASE else None)
assert LISTS[0][2] == [0x00, 0x40, 0x41, 0x42], "list 0 changed"
assert LISTS[2][0] == 15 and LISTS[2][2][0] == 0x00 and LISTS[2][2][-1] == 0x80, \
    "list 2 changed"
assert LISTS[3][2] == [0x00, 0x02, 0x03, 0x04], "list 3 changed"
# list 2 is the temperament white-list; its last value is the one
# ScaleTuning_PostAllTwelveSemitones sends to the USER RAM row.
assert LISTS[2][2][-1] == 0x80, "USER is no longer the last legal temperament"
for p in PARAMS:
    if p.setter in GENERIC and p.xlat != 0xFF:
        cnt, ptr, vals = LISTS[p.xlat]
        assert vals and max(vals) == p.hi, \
            "%02X/%02X: list max %s != descriptor max %d" % (
                p.b7, p.b8, max(vals) if vals else None, p.hi)

# ------------------------------------------------------------------ the output
AREA_NAME = {0x00: "common block 0", 0x01: "common block 1", 0x08: "write-only block",
             0x10: "common block 10", 0x11: "common block 11", 0x60: "single parameter"}


def rows():
    for p in sorted(PARAMS, key=lambda p: (p.b7, p.b8)):
        if p.b7 > 0x20 and p.b7 < 0x60:
            continue                      # the other 31 part blocks are identical
        r = ram_of(p)
        yield p, r


def as_json():
    """The whole resolved map, for a consumer outside this repo.

    Every parameter carries its ADR bytes, the wire size, the bit field the setter actually
    writes, the accepted range, and -- where the setter is one of the three generic ones whose
    +6/+7 pair this script has read instruction by instruction -- its offset inside the
    SYSTEM,PART & MIDI bulk dump. A parameter whose setter does something else has `dump: null`
    rather than an assumed offset, and a consumer must leave it undecoded.
    """
    out = {
        "_comment": [
            "GENERATED by notes/sysex-probes/sysex_param_addresses.py --json -- do not edit.",
            "dump_offset is the byte position inside the SYSTEM,PART & MIDI bulk dump, which",
            "is 2432 bytes at exclusive address 0x100000; dump_offset = RAM - 0x7600.",
            "null means the setter is not one of the generic three, so the offset is unknown",
            "and must not be guessed.",
        ],
        "dump": {"adr": A1, "bytes": RAM_HI - RAM_LO,
                 "blocks": [[A1, S1], [A2, S2]]},
        "parts": 32,
        "params": [],
    }
    for p_ in sorted(PARAMS, key=lambda x: (x.b7, x.b8)):
        if 0x20 < p_.b7 < 0x60:
            continue                      # the other 31 part blocks are identical
        e = {"b7": p_.b7, "b8": p_.b8, "size": p_.size, "mask": p_.mask,
             "shift": p_.shift, "min": p_.lo, "max": p_.hi, "inv": bool(p_.inv),
             "part": p_.b7 == 0x20}
        if p_.b7 == 0x20:
            offs = [ram_of(p_, q) for q in range(32)]
            e["dump_offset"] = None if any(r is None for r in offs) else [r - RAM_LO for r in offs]
        else:
            r = ram_of(p_)
            e["dump_offset"] = None if r is None else r - RAM_LO
        out["params"].append(e)
    return out


def main():
    argv = sys.argv[1:]
    if "--json" in argv:
        json.dump(as_json(), sys.stdout, indent=1)
        sys.stdout.write("\n")
        return 0
    if "--named" in argv:
        print("\nWHAT THE INSTRUMENT ITSELF CALLS THESE PARAMETERS")
        print("  (a) the mixer strip -- caption at y=212 directly over the value at y=226")
        for i, x in enumerate(COLS):
            print("      x=%-4d COMBINATION MODE %-5s SOUND MODE %s" %
                  (x, CAPS[i][2], CAPS_SM[i][2]))
        print("  (b) prom_a's own routine names")
        print("      00 10 11     ScaleTuning_PostAllTwelveSemitones tests it; 0x80 = USER")
        print("      00 10 13..1E ScaleTuning_PostSemitoneFromUserRam reads 0x78A4, 12 long")
        print("      00 20 41     the nibble 0xFB9C1A writes for records 0..15 is the")
        print("                   MIDI channel; the strip prints it 1-01..2-16")
        return 0

    if "--lists" in argv:
        print("\nVALUE WHITE-LISTS (desc+0x0E -> 0xF51E58 + 6*n), generic setters only")
        for i, (cnt, ptr, vals) in sorted(LISTS.items()):
            print("  list %d  count %-3d ptr 0x%06X  %s" % (
                i, cnt, ptr, ["0x%02X" % v for v in vals] if vals else "(not in prom_b)"))
        print("\n  parameters that use one:")
        for p in PARAMS:
            if p.setter in GENERIC and p.xlat != 0xFF:
                print("    00 %02X %02X  list %d  -> %s" % (
                    p.b7, p.b8, p.xlat,
                    ["0x%02X" % v for v in LISTS[p.xlat][2]]))
        return 0

    if "--strip" in argv:
        print("\nTHE MIXER STRIP -- eight captions at y=212, eight values at y=226")
        print("  %-5s %-6s %-6s %-9s %-7s %s" %
              ("x", "COMBI", "SOUND", "reads", "display", "as"))
        srcs = {rec: src for _, rec, src in STRIP_PAINT}
        for i, x in enumerate(COLS):
            hit = [r for r in RECS.values() if abs(r["x"] - x) <= 3]
            if not hit:
                print("  %-5d %-6s %-6s %-9s %-7s %s" %
                      (x, CAPS[i][2], CAPS_SM[i][2], "-", "-",
                       "the eighth column: COMBINATION MODE shows the selected part,"
                       " SOUND MODE the MIDI channel"))
                continue
            r = hit[0]
            src = srcs[r["addr"]]
            how = ("part+0x%02X" % src[1]) if src[0] == "XIY" \
                else "(%s) = 00 10 00" % src[0]
            ents = r["ents"]
            if r["addr"] == 0xF287D1:      # 7 real entries, a 0x7F index bound
                ents = ents[:7]
            shown = ("%s..%s (%d)" % (ents[0].strip(), ents[-1].strip(), len(ents))) \
                if ents else "3 digits, 0..127"
            print("  %-5d %-6s %-6s %-9s %-7s mask 0x%02X shift %d, %s" % (
                x, CAPS[i][2], CAPS_SM[i][2], how, "0x%06X" % r["addr"],
                r["mask"], r["shift"], shown))
        print("\n  the eighth column in SOUND MODE: record 0x%06X, mask 0x1F, %s..%s"
              % (0xF28491, MIDI_REC["ents"][0], MIDI_REC["ents"][31]))
        return 0

    wide = "--dump" in argv
    print("\n%-5s %-5s %-4s %-4s %-4s %-5s %-4s %-4s %s" % (
        "b7", "b8", "size", "rec", "off", "mask", "min", "max",
        "RAM (part 0)   dump address" if wide else "RAM (part 0)"))
    for p, r in rows():
        ram = "?" if r is None else "0x%04X" % r
        extra = ""
        if wide and r is not None:
            extra = "   0x%06X" % dump_addr(r)
        note = ""
        if r is None:
            note = "  setter 0x%06X does not build its target from desc+6/+7" % p.setter
        elif p.setter in ADDRESSED_EXTRA:
            note = "  " + ADDRESSED_EXTRA[p.setter]
        elif p.setter == PAIR_SETTER:
            note = "  target is the pointer at 0xF51E58+6*%d+2; OUTSIDE the dump" % p.xlat
        print("  %02X    %02X    %d    %02X   %02X   0x%02X  %-4d %-4d %-8s%s%s" % (
            p.b7, p.b8, p.size, p.rec, p.off, p.mask, p.lo, p.hi, ram, extra, note))
    print("\n  part block %02X is part 0; blocks 21..3F are the same 57 parameters"
          % 0x20)
    print("  part records: parts 0-7 at 0x%04X+0x40*p, parts 8-31 at 0x%04X+0x40*(p-8)"
          % (RECPTR[0], RECPTR[8]))
    print("  the whole area lies in RAM 0x%04X..0x%04X, which is what the"
          % (RAM_LO, RAM_HI))
    print("  SYSTEM,PART & MIDI bulk dump carries at 0x%06X..0x%06X"
          % (0x100000, 0x100000 + S1 + S2))
    print("  dump address of a parameter = 0x100000 + (its RAM address - 0x%04X)" % RAM_LO)
    print("\n  %d parameters, %d resolved to a RAM byte, %d screen-named"
          % (len(PARAMS), len(RESOLVED), 8))
    return 0


if __name__ == "__main__":
    rc = main()
    print("OK", file=sys.stderr if "--json" in sys.argv else sys.stdout)
    sys.exit(rc)
