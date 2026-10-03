#!/usr/bin/env python3
"""What is a stored COMBINATION, and what are the eight 64-byte records inside it?

QUESTION IT ANSWERS
  A bulk dump's COMBINATION transfer is 90112 bytes and divides evenly two ways:
  16 blocks of 5632, or 128 blocks of 704.  Either reading tiles, so tiling
  cannot choose between them, and the wrong choice mis-names everything below
  it: pick 5632 and a 704-byte unit looks like "a part", and the eight 64-byte
  runs inside it look like eight sub-objects of a part.

  This settles it from the ROMs and then reads the 704-byte unit out:

  1. WHICH UNIT IS THE COMBINATION.  prom_a `CombiBank_RemoteCombiAddr` addresses the area as
     `base + 0x1600*H + 0x2C0*L`; the sibling `CombiBank_RemoteGroupNameAddr` addresses a SECOND
     table with `base-0x100 + 0x10*H`, indexed by H ALONE.  In prom_c -- the ROM
     `CombiBank_RemoteCombiAddr` names as its preset base -- that second table holds SIXTEEN
     printable 16-character strings ("FUSION COMBO1", "JAZZ COMBO", ...,
     "DRUM & EFFECT"), and each 704-byte unit under it holds its own printable
     16-character name ("Downtown Set", "Jazz Chops", ...).  A 5632-byte object
     does not have sixteen names and one apiece; a BANK of eight 704-byte
     combinations does.  So H is the bank, L is the memory inside it, and A
     COMBINATION IS 704 BYTES.

  2. WHAT IS INSIDE ONE.  The 704 bytes are a TLV stream -- {tag, length,
     payload}, terminated by 0xFF 0xFF -- of exactly 23 records that tile the
     704 with nothing left over.  The eight "64-byte records" are eight PARTS:
     each part k is TWO 30-byte records, tag 0x00+k and tag 0x20+k, and
     18+14+3*32 = 128 and 16+46+2 = 64 explain the "header" and the "tail"
     exactly.  The same 23 records, in the same order, open the SYSTEM,PART &
     MIDI bulk-dump block, where this project had already decoded them: they are
     the machine's parameter records, and the wire parameter numbers name their
     fields.

WHY IT IS A REAL TEST
  Four checks that cannot pass by accident, all printed:

  * 0xF8F500 - 0xF80300 is EXACTLY 11 * 0x1600 and 0xF90B00 - 0xF80300 is
    EXACTLY 12 * 0x1600 (same for the flash bases 0xECF500 / 0xED0B00 against
    0xEC0300).  `CombiBank_RemoteCombiAddr`'s three branches are therefore ONE linear array,
    and the H stride is a bank stride.
  * RANGE CONFORMANCE.  Sixteen per-part fields and six common fields are
    range-checked against the min/max the ROM's own parameter descriptors carry.
    Zero violations over every part of every combination in prom_c.
  * ORDER.  KEY LAYER LOW <= KEY LAYER HIGH and VELOCITY LAYER LOW <= VELOCITY
    LAYER HIGH in every part -- with a CONTROL: the adjacent byte pair
    (+0x0B,+0x0C) of the same record violates the same test in every part.
  * THE REVERB SLOT.  Twelve of the guide's 56 effects are annotated "(REV
    only)".  Record 0x63's TYPE byte is one of those twelve in almost every
    combination; records 0x61 and 0x62 never carry one.  The guide's annotation
    was written for a slot, and it lands on exactly one record.

WHAT IT DOES NOT CHECK
  The meaning of the bytes no parameter number reaches: record 0x60's +1..+11
  (always zero), record 0x79's +6..+43 (always zero), the effect blocks' +21 and
  +22, and record 0x20+k's +24..+29 (all live and varying, all unnamed).  They
  are printed as unnamed, not guessed at.  Which of 0x61 / 0x62 is EFFECT1 and
  which is EFFECT2 is NOT established here -- only that 0x63 is the reverb slot.

SIGNAL BEING READ
  original_ROMs/wsa1_prom_a.ic12 @0xF80000 (the two addressing routines, decoded
  from their instruction bytes), wsa1_prom_b.ic13 @0xF00000 (the parameter
  descriptors), wsa1_prom_c.ic28 @0xF80000 (the preset bank names and the 129
  preset combinations), and `param_names.json` / `effects.json` for the names
  Technics prints.  The bulk dump SND_CMBI.syx is used IF PRESENT (it is not
  committed; set SYSEX_CAPTURE) and adds the 128 user combinations to every
  corpus test.

RUN
  python3 wsa1/notes/sysex-probes/sysex_combination_layout.py
  python3 wsa1/notes/sysex-probes/sysex_combination_layout.py --presets
  python3 wsa1/notes/sysex-probes/sysex_combination_layout.py --fields

PASS CRITERION
  The bank arithmetic closes, 129 preset combinations TLV-walk to exactly the
  same 23 records ending on 0xFFFF at +0x2BE, the range and order checks report
  zero violations with the control failing everywhere, and OK.
"""
import collections
import json
import os
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROMS = os.path.abspath(os.path.join(HERE, "..", "..", "original_ROMs"))
PA = open(os.path.join(ROMS, "wsa1_prom_a.ic12"), "rb").read()
PB = open(os.path.join(ROMS, "wsa1_prom_b.ic13"), "rb").read()
PC = open(os.path.join(ROMS, "wsa1_prom_c.ic28"), "rb").read()
A_BASE, B_BASE, C_BASE = 0xF80000, 0xF00000, 0xF80000

CAPTURE = [os.environ.get("SYSEX_CAPTURE", ""),
           os.path.join(HERE, "SND_CMBI.syx"),
           "/home/fsanches/compartilhado/KN7000/WSA1R_files/SND_CMBI.syx"]
CAPTURE_ZIP = "/home/fsanches/compartilhado/KN7000/WSA1R_files/SND_CMBI_syx.zip"

COMB = 0x2C0                      # a combination
BANK = 0x1600                     # eight of them
PARTS = 8


def a_(x, n=1):
    return PA[x - A_BASE:x - A_BASE + n]


def b_(x, n=1):
    return PB[x - B_BASE:x - B_BASE + n]


def c_(x, n=1):
    return PC[x - C_BASE:x - C_BASE + n]


def bl32(x):
    return int.from_bytes(b_(x, 4), "little")


# ------------------------------------------------------------------ base check
assert a_(0xF99AE3, 5) == bytes([0x00, 0x03, 0x05, 0x04, 0x02]), "prom_a base"
assert b_(0xF4FEB4, 5) == bytes([0xF0, 0x50, 0x23, 0x7E, 0xF7]), "prom_b base"
# prom_c is a SECOND ROM at 0xF80000 (CPU 2).  Its own base check is the thing
# this script is about: the 16-byte bank name table the preset branch names.
assert c_(0xF80200, 16) == b"FUSION COMBO1   ", "prom_c base / preset name table"
# Under --json the script still runs all of its checks, but everything it narrates goes
# to stderr so that stdout carries the JSON alone.
_REAL_STDOUT = sys.stdout
if "--json" in sys.argv:
    sys.stdout = sys.stderr

print("base check OK: prom_a @0xF80000, prom_b @0xF00000, prom_c @0xF80000")

# =========================================================== the two routines
# CombiBank_RemoteCombiAddr -- the COMBINATION pointer.  Every constant below is an operand of
# an instruction whose opcode bytes are asserted with it.
assert a_(0xF9F9BC, 4) == bytes([0xD9, 0x08, 0xC0, 0x02]), "mul BC,0x02c0"
assert a_(0xF9F9C6, 4) == bytes([0xD8, 0x08, 0x00, 0x16]), "mul WA,0x1600"
ROUTE = [
    # (address of the `add`, expected 32-bit operand, which branch)
    (0xF9F9CC, 0x00F80300, "preset H<=11", 0xE8),
    (0xF9F9DF, 0x00F8F500, "preset H==11,L>3", 0xE9),
    (0xF9FA08, 0x00F90B00, "preset H>=12", 0xE9),
    (0xF9FA35, 0x00EC0300, "user   H<=11", 0xE8),
    (0xF9FA48, 0x00ECF500, "user   H==11,L>3", 0xE9),
    (0xF9FA6F, 0x00ED0B00, "user   H>=12", 0xE9),
    (0xF9FAA4, 0x00C00300, "RAM working copy", 0xE9),
]
for site, want, what, reg in ROUTE:
    ins = a_(site, 6)
    assert ins[0] == reg and ins[1] == 0xC8, "0x%06X is not an add Xrr,imm32" % site
    got = int.from_bytes(ins[2:], "little")
    assert got == want, "0x%06X adds 0x%08X, expected 0x%08X" % (site, got, want)

# CombiBank_RemoteGroupNameAddr -- the BANK NAME pointer.  `ld c,0x10 / mul8rr c,h` is a 16-byte
# stride over ONE index; there is no second index anywhere in the routine.
assert a_(0xF9F92F, 2) == bytes([0x23, 0x10]), "ld c,0x10"
assert a_(0xF9F931, 2) == bytes([0xCE, 0x43]), "mul8rr c,h"
PAIRED = []
for site, want, what, comb in ((0xF9F935, 0x00F80200, "preset  (prom_c ROM)", 0x00F80300),
                               (0xF9F945, 0x00EC0200, "user    (CPU2 flash)", 0x00EC0300),
                               (0xF9F96C, 0x00C00200, "RAM working copy", 0x00C00300)):
    ins = a_(site, 6)
    assert ins[:2] == bytes([0xE9, 0xC8]), "0x%06X is not an add XBC,imm32" % site
    got = int.from_bytes(ins[2:], "little")
    assert got == want, "0x%06X adds 0x%08X, expected 0x%08X" % (site, got, want)
    assert comb - want == 0x100, "the name table is not 0x100 below the data"
    PAIRED.append((want, what, comb))

print("""
TWO ROUTINES, ONE AREA
  CombiBank_RemoteCombiAddr(mode, H, L) -> XIY = <combination base> + 0x%04X*H + 0x%03X*L
  CombiBank_RemoteGroupNameAddr(mode, H)    -> XIY = <name base>        + 0x10*H
  the second index is ABSENT from CombiBank_RemoteGroupNameAddr: there are 16 names, not 128, so
  H is the BANK and L the memory inside it.""" % (BANK, COMB))
for nb, what, cb in PAIRED:
    print("    %-20s names 0x%06X   combinations 0x%06X   (names 0x100 below)"
          % (what, nb, cb))

print("""
  the three branches of CombiBank_RemoteCombiAddr are ONE linear array -- the folded constants
  are the general formula with H substituted in:""")
for folded, base, h in ((0xF8F500, 0xF80300, 11), (0xF90B00, 0xF80300, 12),
                        (0xECF500, 0xEC0300, 11), (0xED0B00, 0xEC0300, 12)):
    assert folded - base == h * BANK, "0x%06X is not base + %d*0x1600" % (folded, h)
    print("    0x%06X - 0x%06X = 0x%05X = %2d * 0x%04X   exact"
          % (folded, base, folded - base, h, BANK))

# ============================================== the preset area, read directly
PRESET_NAMES = 0xF80200
PRESET_DATA = 0xF80300
BANKS = 16
bank_names = [c_(PRESET_NAMES + 0x10 * i, 16) for i in range(BANKS)]
for i, n in enumerate(bank_names):
    assert all(0x20 <= ch < 0x7F for ch in n), "bank %d name is not printable" % i
# the slot AFTER the last bank name is not a name -- it is the first combination
assert c_(PRESET_DATA, 2) == bytes([0x78, 0x10]), "0xF80300 does not open a TLV"

# The 23-record shape, as a stored combination must have it.
SHAPE = ([(0x78, 16), (0x60, 12), (0x61, 30), (0x62, 30), (0x63, 30)]
         + sum([[(k, 30), (0x20 + k, 30)] for k in range(PARTS)], [])
         + [(0x92, 14), (0x79, 44)])
assert sum(2 + l for _, l in SHAPE) + 2 == COMB, "the 23 records do not tile 704"
HEAD = sum(2 + l for _, l in SHAPE[:5])
TAIL = sum(2 + l for _, l in SHAPE[-2:]) + 2
assert HEAD == 128 and TAIL == 64 and HEAD + PARTS * 64 + TAIL == COMB, \
    "128 + 8*64 + 64 does not close"


def walk(buf, o):
    """The TLV stream at `o`: [(tag, length, payload_offset)], and where it ends."""
    out = []
    while buf[o] != 0xFF:
        t, l = buf[o], buf[o + 1]
        out.append((t, l, o + 2))
        o += 2 + l
    return out, o


def combination(buf, o):
    recs, end = walk(buf, o)
    assert [(t, l) for t, l, _ in recs] == SHAPE, \
        "the record sequence at 0x%X is not the combination shape" % o
    assert end - o == COMB - 2 and buf[end:end + 2] == b"\xFF\xFF", \
        "the stream at 0x%X does not end on 0xFFFF at +0x2BE" % o
    return {t: buf[p:p + l] for t, l, p in recs}


PRESETS = []
i = 0
while True:
    o = (PRESET_DATA - C_BASE) + i * COMB
    if o + COMB > len(PC):
        break
    try:
        PRESETS.append(combination(PC, o))
    except (AssertionError, IndexError):
        break
    i += 1
assert len(PRESETS) == BANKS * PARTS + 1, \
    "%d preset combinations, expected %d" % (len(PRESETS), BANKS * PARTS + 1)

print("""
THE PRESET AREA IN prom_c  (the base CombiBank_RemoteCombiAddr names for mode 0)
  0x%06X  %d bank names of 16 bytes
  0x%06X  %d combinations of 0x%03X, walked as TLV, every one the same 23 records
             = %d banks of %d, plus ONE extra at index %d (bank %d, memory 0)"""
      % (PRESET_NAMES, BANKS, PRESET_DATA, len(PRESETS), COMB,
         BANKS, PARTS, BANKS * PARTS, BANKS))


def name_of(rec):
    return rec[0x78].decode("latin1").strip()


for h in range(BANKS):
    row = [name_of(PRESETS[h * PARTS + l]) for l in range(PARTS)]
    print("   %2d %-16s | %s" % (h, bank_names[h].decode("latin1").strip(),
                                 " | ".join("%-16s" % x for x in row)))
print("   %2d %-16s | %s   <- no bank name; the INITIAL template"
      % (BANKS, "(unnamed)", name_of(PRESETS[BANKS * PARTS])))

# ============================================== the corpus: presets + capture
CORPUS = [("prom_c preset", PRESETS)]


def blocks(buf):
    """Every completed bulk-dump transfer in a capture, keyed by its ADR."""
    def msgs():
        i = 0
        while True:
            s = buf.find(b"\xF0", i)
            e = buf.find(b"\xF7", s) if s >= 0 else -1
            if s < 0 or e < 0:
                return
            yield buf[s:e + 1]
            i = e + 1

    def join(p):
        return bytes(((p[i] & 0x0F) << 4) | (p[i + 1] & 0x0F)
                     for i in range(0, len(p), 2))
    out, acc, adr = {}, None, None
    for m in msgs():
        if m[:3] == b"\xF0\x50\x2D":
            adr, acc = tuple(m[6:9]), bytearray(join(m[12:-3]))
            if m[-3] == 0x00:
                out[adr], acc = bytes(acc), None
        elif m[:3] == b"\xF0\x50\x7E" and acc is not None:
            acc += join(m[3:-3])
            if m[-3] == 0x00:
                out[adr], acc = bytes(acc), None
    return out


def capture():
    for p in CAPTURE:
        if p and os.path.exists(p):
            return open(p, "rb").read()
    if os.path.exists(CAPTURE_ZIP):
        with zipfile.ZipFile(CAPTURE_ZIP) as z:
            return z.read([n for n in z.namelist()
                           if n.lower().endswith(".syx")][0])
    return None


cap = capture()
if cap is not None:
    bl = blocks(cap)
    data, names = bl.get((0x50, 0x06, 0x00)), bl.get((0x50, 0x00, 0x00))
    if data is not None:
        assert len(data) == BANKS * BANK, "the user area is not 16 banks"
        CORPUS.append(("user flash", [combination(data, i * COMB)
                                      for i in range(BANKS * PARTS)]))
        # the flash header the dump also carries: the SAME name table, 0x100
        # below the data, exactly as CombiBank_RemoteGroupNameAddr says.
        assert names is not None and len(names) == 0x300, "flash header"
        ub = [names[0x200 + 0x10 * i:0x200 + 0x10 * i + 16] for i in range(BANKS)]
        for i, n in enumerate(ub):
            assert all(0x20 <= ch < 0x7F for ch in n), "user bank %d" % i
        print("""
THE USER AREA IN THE CAPTURE  (the base CombiBank_RemoteCombiAddr names for mode 8)
  0x%06X  %d bank names, the LAST 0x100 of the 768-byte flash header
  0x%06X  %d combinations of 0x%03X, the same 23 records every one
    %s""" % (0xEC0200, BANKS, 0xEC0300, BANKS * PARTS, COMB,
             ", ".join(x.decode("latin1").strip() for x in ub)))
else:
    print("\n  (no bulk-dump capture found; the ROM presets alone are the corpus)")

ALL = [c for _, cs in CORPUS for c in cs]

# ==================================== the 23 records, and the eight 64-byte runs
RECNAME = {
    0x78: ("COMBINATION NAME", "16 ASCII characters"),
    0x60: ("EFFECT COMMON", "+0 bit0 EFFECT COMMON ALGORITHM; +1..+11 always 0"),
    0x61: ("EFFECT block 1", "+0 TYPE, then VALUE slots"),
    0x62: ("EFFECT block 2", "+0 TYPE, then VALUE slots"),
    0x63: ("REVERB block", "+0 TYPE -- the only slot the guide's (REV only) "
                           "algorithms appear in"),
    0x92: ("KEY SCALING / SCALE TUNING", "all 14 bytes named"),
    0x79: ("PART COMMON REAL TIME", "+0 KEY TRANSPOSE, +1..+4 MAIN OUT EQ, "
                                    "+5 EFFECT1/2 OUTPUT SELECT"),
}

if "--json" in sys.argv:
    # The 704-byte combination as a record table, for a consumer outside this repo. SHAPE is
    # the TLV stream the machine itself writes; RECNAME names the records that are not a part.
    import json as _json
    _recs, _o = [], 0
    for _t, _l in SHAPE:
        if _t in RECNAME:
            _nm, _note = RECNAME[_t]
        elif _t < 0x08:
            _nm, _note = "PART %d BLOCK A" % _t, "individual block A"
        elif 0x20 <= _t < 0x28:
            _nm, _note = "PART %d BLOCK B" % (_t - 0x20), "individual block B"
        else:
            _nm, _note = "TAG %02X" % _t, ""
        _recs.append({"at": _o, "tag": _t, "len": _l, "name": _nm, "note": _note})
        _o += _l + 2
    sys.stdout = _REAL_STDOUT
    _json.dump({
        "_comment": [
            "GENERATED by notes/sysex-probes/sysex_combination_layout.py --json.",
            "A COMBINATION is 704 bytes: 16 banks of 8, settled from the ROMs rather than from",
            "tiling -- 90112 divides evenly as 16x5632 AND as 128x704, and only the sixteen bank",
            "names and one name per 704-byte unit choose between them.",
            "'at' is the offset of the record's TAG byte; its payload starts at at+2.",
        ],
        "size": 0x2C0, "banks": 16, "per_bank": 8,
        "records": _recs,
    }, sys.stdout, indent=1)
    sys.stdout.write("\n")
    sys.exit(0)
print("""
THE 704 BYTES, AS THE MACHINE WRITES THEM
  at    tag len  what""")
o = 0
for t, l in SHAPE:
    if t in RECNAME:
        what = "%s -- %s" % RECNAME[t]
    elif t < 0x08:
        what = "PART %d, individual block A" % t
    else:
        what = "PART %d, individual block B" % (t - 0x20)
    print("  %04X   %02X  %3d  %s" % (o, t, l, what))
    o += 2 + l
print("  %04X   FF FF    end of stream" % o)
print("""
  the framing that makes it look like eight 64-byte records:
    0x0000..0x007F  128 = the first five records (18+14+32+32+32)
    0x0080..0x027F  eight 64-byte runs; run k = record 0x%02X+k THEN record 0x%02X+k
    0x0280..0x02BF   64 = the last two records plus the terminator (16+46+2)
  so within a 64-byte run, byte 0 is the TLV tag of block A (= the part number),
  byte 32 is the TLV tag of block B, and bytes 23..31 are block A's payload
  +0x15..+0x1D -- past +0x14, the last byte any parameter number reaches.""" % (0, 0x20))

# ============================ the fields, from the ROM's own parameter descriptors
# Descriptor tables and the (rec, off, mask, lo, hi) reading of a descriptor are
# established by sysex_param_addresses.py; this re-walks them so a change there
# cannot silently desynchronise this script.
TABLES = [(0xF51E8E, 0x17), (0xF51F46, 0x05), (0xF51F5E, 0x19),
          (0xF52026, 0x13), (0xF520BE, 0x28), (0xF521FE, 0x02)]
PLACEHOLDER = 0xF511F9
# A descriptor's +6/+7 is (record, offset) only for the setters that were read
# instruction by instruction; the rest resolve their target some other way, and
# this script must not pretend otherwise.  Same list as sysex_param_addresses.py.
ADDRESSED = {0xFB3778, 0xFB38E4, 0xFB3D13, 0xFB3B04, 0xFB39A4}
Param = collections.namedtuple("Param", "b7 b8 rec off mask lo hi setter")
DESC = []
for base, n in TABLES:
    for i in range(n):
        d = bl32(base + 4 * i)
        if i == 0:
            assert d == PLACEHOLDER, "group at 0x%06X lost its placeholder" % base
            continue
        h = b_(d, 0x20)
        if h[0] != 0x00:
            continue
        DESC.append(Param(h[1], h[2], h[6], h[7], h[8], h[9], h[0x0A],
                          int.from_bytes(h[0x14:0x18], "little")))
assert len(DESC) == 108, "%d descriptors, expected 108" % len(DESC)
assert len([p for p in DESC if p.b7 == 0x20]) == 57, "a part block is not 57 parameters"

GUIDE = json.load(open(os.path.join(HERE, "param_names.json")))


def gname(p):
    return GUIDE.get("%02X/%02X" % (p.b7, p.b8), {}).get("name", "(unnamed)")


def shift(mask):
    return (mask & -mask).bit_length() - 1


COMBRECS = {0x60, 0x79, 0x92}
FIELDS = [p for p in DESC
          if (p.b7 == 0x20 and p.rec in (0x00, 0x20)) or p.rec in COMBRECS]

viol = unresolved = 0
rows = []
for p in FIELDS:
    per_part = p.b7 == 0x20
    lo, hi, bad, n = 0xFFFF, -1, 0, 0
    for c in ALL:
        for k in (range(PARTS) if per_part else (0,)):
            v = (c[p.rec + k][p.off] & p.mask) >> shift(p.mask)
            lo, hi, n = min(lo, v), max(hi, v), n + 1
            if not p.lo <= v <= p.hi:
                bad += 1
    # A descriptor can falsify only when its setter is one of the five that
    # were read, AND its declared max is narrower than its own mask.
    live = p.setter in ADDRESSED and p.hi and p.hi < (p.mask >> shift(p.mask))
    if live:
        viol += bad
    elif bad:
        unresolved += 1
        assert (p.b7, p.b8) == (0x10, 0x20), \
            "an UNRESOLVED descriptor other than 10/20 disagrees: %02X/%02X" \
            % (p.b7, p.b8)
    rows.append((p.rec, p.off, p.mask,
                 "%02X%s" % (p.rec, "+k" if per_part else "  "),
                 p.lo, p.hi, lo, hi, bad,
                 "gate " if live else ("     " if p.setter in ADDRESSED else "UNRES"),
                 gname(p)))

print("""
EVERY FIELD OF A COMBINATION RECORD, AGAINST %d COMBINATIONS (%s)
  `gate` marks the rows this script ASSERTS on: the setter is one of the five
  that were read instruction by instruction, and the declared max is narrower
  than the field's own mask, so a wrong offset would show.  `UNRES` marks a
  descriptor whose setter does NOT build its target from +6/+7 -- its record and
  offset are unproven, and it is printed, not trusted.
  rec   off mask  declared   observed  bad       the name Technics prints"""
      % (len(ALL), " + ".join("%d %s" % (len(cs), n) for n, cs in CORPUS)))
for _r, off, mask, rec, dlo, dhi, olo, ohi, bad, tag, nm in sorted(rows):
    print("  %-5s +%02X 0x%02X  %3d..%-3d  %4d..%-4d %3d %-5s %s"
          % (rec, off, mask, dlo, dhi, olo, ohi, bad, tag, nm))
assert viol == 0, "%d values fall outside the range their descriptor declares" % viol
# The one descriptor the data contradicts is `10/20 MAIN OUT EQUALIZER LOW-FREQ`,
# and it is one of exactly two whose setter sysex_param_addresses.py already
# reports as NOT building its target from +6/+7.  Every combination puts 24 in
# that field against a declared 0..17, so record 0x79 +1 is the LOW-GAIN byte
# and the LOW-FREQ byte is elsewhere.  That the failure lands on an already-
# flagged descriptor, and on no other, is itself a check on the field map.
assert unresolved == 1, \
    "%d UNRESOLVED descriptors disagree with the data, expected the known 1" % unresolved

# ----------------------------------------------------- order, with its control
kbad = vbad = ctrl = n = 0
for c in ALL:
    for k in range(PARTS):
        b = c[0x20 + k]
        n += 1
        kbad += b[0x07] > b[0x08]          # KEY LAYER LOW > HIGH
        vbad += b[0x09] > b[0x0A]          # VELOCITY LAYER LOW > HIGH
        ctrl += b[0x0B] > b[0x0C]          # control: the adjacent byte pair
print("""
  order, over %d parts:
    KEY LAYER LOW      > KEY LAYER HIGH        %4d
    VELOCITY LAYER LOW > VELOCITY LAYER HIGH   %4d
    CONTROL  +0x0B     > +0x0C                 %4d   (the test can fail)"""
      % (n, kbad, vbad, ctrl))
assert kbad == 0 and vbad == 0, "a layer's LOW exceeds its HIGH"
assert ctrl == n, "the control no longer fails; the order test proves nothing"

# --------------------------------------------------------- the reverb slot
CAT = json.load(open(os.path.join(HERE, "effects.json")))["effects"]
REV_ONLY = {e["prog"] for e in CAT if "(REV only)" in e["guide_name"]}
KNOWN = {e["prog"]: e["guide_name"] for e in CAT}
assert len(REV_ONLY) == 12, "%d (REV only) effects" % len(REV_ONLY)
hits = {t: sum(1 for c in ALL if c[t][0] in REV_ONLY) for t in (0x61, 0x62, 0x63)}
print("""
  the reverb slot, over %d combinations:
    record 0x61 TYPE is one of the twelve (REV only) effects   %4d
    record 0x62 TYPE is one of the twelve (REV only) effects   %4d
    record 0x63 TYPE is one of the twelve (REV only) effects   %4d"""
      % (len(ALL), hits[0x61], hits[0x62], hits[0x63]))
assert hits[0x61] == 0 and hits[0x62] == 0, \
    "a (REV only) effect appears outside record 0x63"

# The parameter family that writes the effect blocks is the ONE wildcard of the
# 2B/2C grammar: byte 7 = 0x11, byte 8 looked up in prom_b 0xF4FA9C (0xFF = drop
# the message).  Its admitted values fall into exactly THREE runs, and the guide
# names the first run's first slot EFFECT1 TYPE.  Three runs, three records, in
# the same order -- which is what puts EFFECT1 on 0x61 and EFFECT2 on 0x62.
XLAT = b_(0xF4FA9C, 0x80)
runs, cur = [], None
for i, v in enumerate(XLAT):
    if v == 0xFF:
        if cur:
            runs.append(cur)
        cur = None
    elif cur is None:
        cur = [i, i]
    else:
        cur[1] = i
if cur:
    runs.append(cur)
assert len(runs) == 3, "the 0x11 family has %d runs, expected 3" % len(runs)
assert runs[0][0] == 0x20, "the first run does not start at byte8 0x20"
assert GUIDE["11/20"]["name"] == "EFFECT1 TYPE", "11/20 is no longer EFFECT1 TYPE"
span = {t: max(i for c in ALL for i, v in enumerate(c[t]) if v) + 1
        for t in (0x61, 0x62, 0x63)}
print("""
  the family that writes them -- byte7 0x11, the grammar's ONE wildcard, whose
  byte 8 is looked up in prom_b 0xF4FA9C.  Three runs, three records:""")
for (lo, hi), t, nm in zip(runs, (0x61, 0x62, 0x63),
                           ("EFFECT1 (11/20 is EFFECT1 TYPE)", "EFFECT2", "REVERB")):
    print("    byte8 0x%02X..0x%02X  %2d slots   record 0x%02X uses +0x00..+0x%02X"
          " (%d bytes)   %s" % (lo, hi, hi - lo + 1, t, span[t] - 1, span[t], nm))
assert [hi - lo + 1 for lo, hi in runs] == [23, 23, 22], "the run sizes changed"
assert [span[t] for t in (0x61, 0x62, 0x63)] == [23, 23, 23], "the record spans changed"
assert hits[0x63] > 0.9 * len(ALL), \
    "only %d of %d combinations put a (REV only) effect in 0x63" % (hits[0x63], len(ALL))
for t in (0x61, 0x62, 0x63):
    bad = [c[t][0] for c in ALL if c[t][0] not in KNOWN]
    assert not bad, "record 0x%02X carries type %r, not in the catalogue" % (t, bad[:4])

# ------------------------------------------------- what is live and unnamed
named = collections.defaultdict(set)
for p in DESC:
    if p.b7 == 0x20:
        for k in range(PARTS):
            named[p.rec + k].add(p.off)
    else:
        named[p.rec].add(p.off)
live = collections.defaultdict(set)
for c in ALL:
    for t, pl in c.items():
        for i, v in enumerate(pl):
            if v:
                live[t].add(i)
print("""
  live but unnamed -- bytes some combination writes that no 00-AREA parameter
  descriptor reaches.  Two caveats the table cannot show: 00+k +00 is a THREE
  byte field (PROGRAM CHANGE & BANK) so +01 and +02 belong to it, and the three
  effect blocks are written by the `11/any` wildcard family, which is not in the
  00 area at all -- their +00 is the TYPE and the rest are its VALUE slots:""")
for t, l in SHAPE:
    if t == 0x78:
        continue
    gap = sorted(live[t] - named[t])
    dead = sorted(set(range(l)) - live[t])
    lbl = ("PART %d block %s" % (t & 7, "A" if t < 8 else "B")) if t < 0x40 \
        else RECNAME[t][0]
    if t < 0x40 and t not in (0x00, 0x20):
        continue                                # one part is enough to show it
    print("    %02X %-28s live+unnamed %-22s always zero %s"
          % (t, lbl, ",".join("+%02X" % i for i in gap) or "-",
             ",".join("+%02X" % i for i in dead) or "-"))

if "--presets" in sys.argv:
    print("\nEVERY PRESET COMBINATION")
    for i, c in enumerate(PRESETS):
        h, l = divmod(i, PARTS)
        e = [KNOWN.get(c[t][0], "?") for t in (0x61, 0x62, 0x63)]
        liveparts = [k for k in range(PARTS) if not (c[k][0x0D] & 0x20)]
        print("  0x%06X  %2d-%d  %-17s parts %-18s %s"
              % (PRESET_DATA + i * COMB, h, l, name_of(c),
                 ",".join(map(str, liveparts)), " / ".join(e)))

if "--fields" in sys.argv:
    print("\nEVERY DESCRIBED FIELD OF A COMBINATION RECORD")
    for p in sorted(FIELDS, key=lambda q: (q.rec, q.off, q.mask)):
        tag = "%02X+k" % p.rec if p.b7 == 0x20 else "%02X" % p.rec
        print("  rec %-5s +%02X mask 0x%02X  %3d..%-3d  %02X/%02X  %s"
              % (tag, p.off, p.mask, p.lo, p.hi, p.b7, p.b8, gname(p)))

print("\nOK")
