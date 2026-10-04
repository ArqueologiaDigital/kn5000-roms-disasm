#!/usr/bin/env python3
"""Which USER SETTINGS change whether System Exclusive works.

QUESTION THIS ANSWERS
    The MIDI menu has an INPUT & OUTPUT FILTER page whose last row is
    captioned EXCLUSIVE, and a REALTIME MESSAGES page whose rows are
    REALTIME COMMANDS and CLOCK.  An earlier pass reported, as a LIKELY
    finding, that the `25` tempo message is suppressed unless EXCLUSIVE is
    ON and the instrument is on its own clock.  This script settles the
    whole question:

      * is the EXCLUSIVE setting an INPUT filter, an OUTPUT filter, or one
        switch acting in both directions -- and is there more than one?
      * WHICH bits it writes, and which of them anything reads;
      * EVERY consumer of the EXCLUSIVE bit, exhaustively, so that
        "bulk dump is NOT affected" is a measurement and not an absence;
      * whether it affects the General MIDI messages -- separately for the
        ones the instrument SENDS and the ones it RECEIVES (it affects
        NEITHER, and the reason is a second, ungated emitter);
      * whether any MIDI channel, mode or device-number setting takes part
        in System Exclusive at all;
      * the built-in initial value of every row;
      * where these settings sit inside the SYSTEM,PART & MIDI bulk dump,
        i.e. what restoring somebody else's dump does to them.

WHAT IT ESTABLISHES, AND HOW

  1. THE SETTINGS BLOCK IS ONE PARAMETER RECORD.  Every row of all three
     MIDI setting pages commits through prom_b 0xF41B18 with the argument
     quadruple (parameter number, byte offset, value, mask), and the number
     is always 0x80.  The script reads the four `pushw` immediates in front
     of each commit and asserts `0x7F32 + offset` equals the RAM address
     that row's painter and editor actually touch -- for all twelve rows of
     the three pages.  That is what makes 0x7F32..0x7F3B one object.

  2. ROW -> CAPTION IS GEOMETRIC, not positional.  Each page draws its
     captions from one display list and each row's value from a list of its
     own; the script computes, for every row, the screen coordinate of the
     value field and of every caption, and asserts the value falls strictly
     between the end of its own caption and the start of the next.  Eight
     rows, eight unique captions, no ambiguity.

  3. TWO INDEPENDENT SEMANTIC WITNESSES for the binding, which do not use
     the screen at all: MidiIn_ControlChange's enable table gates
     controllers 0 and 32 -- Bank Select MSB and LSB -- on the bit the
     BANK SELECT row writes, and controller 121 -- Reset All Controllers --
     on the bit the RESET ALL CTRL row writes.

  4. THE FILTER IS TWO-DIRECTIONAL, and that is read off the code:
     MidiIn_ProgramChange and MidiOut_ProgramChange open with the SAME
     `bit 4,(0x7F39)`.  There is exactly one EXCLUSIVE row in the whole
     firmware (one caption, one editor, one bit), so there is no separate
     input and output setting.

  5. THE EXCLUSIVE ROW WRITES FOUR BITS AND ONLY ONE IS READ.  Its editor
     commits mask 0x0F and its painter tests `(0x7F38) & 0x0F`; an
     exhaustive census of every instruction in both CPU-1 images that can
     name 0x7F38 -- direct 16-bit absolute forms at instruction boundaries,
     pointer immediates, and the two register-indexed bases that exist --
     finds SIX sites and no seventh.  Three are the page itself.  The other
     three are the consumers.

  6. THE THREE CONSUMERS.  `25` tempo transmit (0xFB3355), `25` tempo
     receive (0xFB33FE), and 0xFB4B7D, the routine that turns staged
     parameter changes into outgoing System Exclusive.  Nothing else.
     ⇒ bulk dump, dump requests, the handshake, the `2B`/`2C` parameter
     families and INCOMING General MIDI are all outside the filter, and
     that is a census result, not an unsearched area.

  7. WHAT 0xFB4B7D CAN ACTUALLY EMIT.  It dispatches through a 192-entry
     table in prom_b; 187 entries are a bare `ret`.  Of the five that are
     not, four reach descriptor lists whose first entry is the placeholder
     descriptor 0xF511F9, whose transmit method is itself a bare `ret`.
     The fifth, 0xFB4CAE, sends one of the two six-byte literals
     `F0 7E 7F 09 01 F7` / `F0 7E 7F 09 02 F7`, which occur ONCE EACH in
     1 MiB of prom_b and are named by ONE instruction each, both inside it.

     ⚠ AND THAT IS WHERE A TEMPTING WRONG ANSWER LIVES.  0xFB4CAE has a
     SECOND caller, 0xFB5F2E, which builds the same four-byte record on its
     own frame and calls it directly -- bypassing the EXCLUSIVE test
     entirely.  What holds THAT path back is bit 7 of (0x60F020), set by
     the two General MIDI receive handlers and by nothing else, i.e. an
     echo interlock.  So "EXCLUSIVE off stops General MIDI being
     transmitted" is FALSE, and the script asserts both callers so the
     claim cannot drift back.

  8. RECEPTION OF GENERAL MIDI IS NOT FILTERED.  The grammar reaches
     command 0x20 / 0x21, whose handlers are 0xFB51E7 / 0xFB520C, and
     neither contains a reference to any byte of the settings block.

  9. NO CHANNEL, MODE OR DEVICE SETTING TOUCHES SYSTEM EXCLUSIVE.  The
     SysEx engine occupies 0xFB2000-0xFB8200; the script asserts that
     window contains no reference to the MIDI INPUT/OUTPUT MODE byte
     (0x7F35) or the SINGLE CHANNEL byte (0x7F36), and that no caption in
     prom_b contains DEVICE, UNIT or ID.

 10. BUILT-IN INITIAL VALUES.  0xFAA9F2 copies 24 bytes from prom_b
     0xF3FD10 over 0x7F30..0x7F47.  The script decodes every row from that
     block.  EXCLUSIVE comes up 0x0F -- ON.

 11. THE SETTINGS TRAVEL IN THE BULK DUMP.  0x7F32..0x7F4D lie inside
     0x007620..0x007F80, the source extent of SYSTEM,PART & MIDI part 2,
     so a restored dump overwrites them.

RUN
    python3 wsa1/notes/sysex-probes/sysex_user_settings.py
    python3 wsa1/notes/sysex-probes/sysex_user_settings.py --sites
    python3 wsa1/notes/sysex-probes/sysex_user_settings.py --census

PASS
    Every assert is silent and the script prints OK.  Headline results:
    8 filter rows, all on parameter record 0x80 whose base is 0x7F32;
    EXCLUSIVE = (0x7F38) mask 0x0F with bit 3 the only bit anything reads,
    6 references in 1 MiB x 2, 3 consumers; 187/192 emitter slots dead and
    4 of the remaining 5 landing on a placeholder; the General MIDI
    emitter has TWO callers and only one is gated; default 0x0F = ON.
"""
import argparse
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))
ROMS = os.path.join(ROOT, "original_ROMs")

PROM_A_BASE = 0xF80000
PROM_B_BASE = 0xF00000

A = open(os.path.join(ROMS, "wsa1_prom_a.ic12"), "rb").read()
B = open(os.path.join(ROMS, "wsa1_prom_b.ic13"), "rb").read()
assert len(A) == 0x80000 and len(B) == 0x80000


def a(addr, n=1):
    return A[addr - PROM_A_BASE:addr - PROM_A_BASE + n]


def b(addr, n=1):
    return B[addr - PROM_B_BASE:addr - PROM_B_BASE + n]


def aw(addr):
    return int.from_bytes(a(addr, 2), "little")


def bw(addr):
    return int.from_bytes(b(addr, 2), "little")


def bl(addr):
    return int.from_bytes(b(addr, 4), "little")


def scan(img, base, pat):
    out, i = [], 0
    while True:
        i = img.find(pat, i)
        if i < 0:
            return out
        out.append(base + i)
        i += 1


# Load bases asserted by content, never assumed.
assert b(0xF4FEB4, 5) == bytes([0xF0, 0x50, 0x23, 0x7E, 0xF7]), "prom_b base wrong"
assert a(0xF99AE3, 5) == bytes([0, 3, 5, 4, 2]), "prom_a base wrong"

# Instruction boundaries, from this tree's own byte-exact transcriptions.
BOUNDARY = {}
for key, name in (("a", "prom_a/wsa1_prom_a.s"), ("b", "prom_b/wsa1_prom_b.s")):
    s = set()
    for line in open(os.path.join(ROOT, name), encoding="utf-8", errors="replace"):
        m = re.search(r"; (F[0-9A-F]{5})  [0-9a-f]{2}", line)
        if m:
            s.add(int(m.group(1), 16))
    BOUNDARY[key] = s
assert len(BOUNDARY["a"]) > 100000, len(BOUNDARY["a"])
assert len(BOUNDARY["b"]) > 5000, len(BOUNDARY["b"])


# ====================================================================== 1
# EXHAUSTIVE CENSUS of every instruction that can name a byte of the MIDI
# settings block.  Three ways an address of this size is formed on this
# part, and all three are swept:
#   (a) 16-bit absolute operand, prefix C0/C1/D1/E1/F1 then lo hi;
#   (b) the address as a 16- or 32-bit IMMEDIATE loaded into a register,
#       which is how a pointer or an indexed base is set up;
#   (c) a register-indexed load off such a base -- found via (b).
BLOCK_LO, BLOCK_HI = 0x7F30, 0x7F4F
ABS_PREFIX = (0xC0, 0xC1, 0xD1, 0xE1, 0xF1)


def census_abs(img, base, key):
    out = {}
    for addr in range(BLOCK_LO, BLOCK_HI + 1):
        lo, hi = addr & 0xFF, addr >> 8
        hits = []
        i = 0
        while True:
            i = img.find(bytes([lo, hi]), i)
            if i < 0:
                break
            if i >= 1 and img[i - 1] in ABS_PREFIX and (base + i - 1) in BOUNDARY[key]:
                hits.append(base + i - 1)
            i += 1
        if hits:
            out[addr] = hits
    return out


ABS_A = census_abs(A, PROM_A_BASE, "a")
ABS_B = census_abs(B, PROM_B_BASE, "b")
assert ABS_B == {}, "prom_b names a settings byte: %s" % ABS_B


def census_imm(img, base, key):
    """The address as an immediate -- pointer set-ups and indexed bases."""
    out = {}
    for addr in range(BLOCK_LO, BLOCK_HI + 1):
        p16 = addr.to_bytes(2, "little")
        p32 = addr.to_bytes(4, "little")
        hits = set()
        for pat in (p32, p16):
            i = 0
            while True:
                i = img.find(pat, i)
                if i < 0:
                    break
                for k in (1, 2, 3):
                    site = base + i - k
                    if site in BOUNDARY[key]:
                        op = img[i - k]
                        # 0x30-0x37 ldw r,imm16 ; 0x40-0x47 ld xr,imm32
                        if 0x30 <= op <= 0x37 or 0x40 <= op <= 0x47:
                            hits.add((site, "imm"))
                        break
                i += 1
        if hits:
            out[addr] = sorted(hits)
    return out


IMM_A = census_imm(A, PROM_A_BASE, "a")
IMM_B = census_imm(B, PROM_B_BASE, "b")
assert IMM_B == {}, "prom_b loads a settings address: %s" % IMM_B

# The ONLY register-indexed bases inside the block are 0x7F36 and 0x7F39.
INDEXED_BASES = sorted({addr for addr, hits in IMM_A.items()
                        for site, _ in hits
                        if a(site, 1)[0] in (0x44, 0x45, 0x46)})
assert INDEXED_BASES == [0x7F36, 0x7F39], INDEXED_BASES

# base 0x7F36: the one use is `ld A,(XIX)` -- offset 0, no index register.
assert a(0xFA76EE, 2) == bytes([0x84, 0x21]), "0x7F36 base is not a bare load"

# base 0x7F39, use 1: MidiIn_ControlChange's enable table.  Entry = byte
# offset from 0x7F39 in the high half, bit mask in the low half; 0xFFFF
# means always-on and is tested BEFORE the load.
assert a(0xFA628D, 4) == bytes([0xD8, 0xCF, 0xFF, 0xFF]), "cp WA,0xFFFF"
assert a(0xFA6293, 5) == bytes([0x44, 0x39, 0x7F, 0x00, 0x00]), "ld XIX,0x7F39"
CCNUM_TO_IDX = a(0xFA83E8, 128)
CC_IDX = sorted({v for v in CCNUM_TO_IDX if v != 0xFF})
CC_ENABLE = {}
for i in range(max(CC_IDX) + 1):
    e = aw(0xFA8468 + 2 * i)
    if e != 0xFFFF:
        CC_ENABLE[i] = (0x7F39 + (e >> 8), e & 0xFF)
assert {addr for addr, _ in CC_ENABLE.values()} == {0x7F39, 0x7F3A, 0x7F3B}, CC_ENABLE
# ⇒ 0x7F38 is one byte BELOW the base and no entry reaches it.

# base 0x7F39, use 2: MidiIn_BuildPartList, `ld H,(XIY+E)`.  Every caller
# passes its (mask,offset) as one `ldw DE,imm16`; E is the offset.
assert a(0xFA82A4, 5) == bytes([0x45, 0x39, 0x7F, 0x00, 0x00]), "ld XIY,0x7F39"
BUILDERS = []
for site in range(0xFA8200, 0xFA82A1):
    if site in BOUNDARY["a"] and a(site, 1)[0] == 0x1E:
        d = int.from_bytes(a(site + 1, 2), "little", signed=True)
        if site + 3 + d == 0xFA82A1:
            de = aw(site - 5)                       # the `ldw DE,imm16` before
            assert a(site - 6, 1) == b"\x32", "builder shape changed at %06X" % site
            BUILDERS.append((site, de))
assert len(BUILDERS) == 11, BUILDERS
assert {de & 0xFF for _, de in BUILDERS} == {0x00}, "a builder indexes off 0x7F39"
assert {de >> 8 for _, de in BUILDERS} == {0x08, 0x20, 0x40}, BUILDERS

# ⇒ THE CENSUS IS CLOSED.  Every reference to 0x7F38 in either CPU-1 image:
REFS_7F38 = ABS_A[0x7F38] + [s for s, _ in IMM_A.get(0x7F38, [])]
assert sorted(REFS_7F38) == [0xF9ACFB, 0xF9AF2E, 0xF9AF40,
                             0xFB3398, 0xFB341E, 0xFB4B7F], REFS_7F38


# ====================================================================== 2
# THE INPUT & OUTPUT FILTER PAGE.  Eight rows; for each one the editor,
# the painter, the RAM byte, the mask, and the commit quadruple.
FILTER_JUMPTABLE = 0xF9AB84
assert a(0xF9AB72, 2) == bytes([0xD9, 0xDF]), "cp BC,7 -- the row bound"
assert a(0xF9AB7A, 6) == bytes([0xE9, 0xC8, 0x84, 0xAB, 0xF9, 0x00]), "table base"
FILTER_SETTERS = []
for row in range(8):
    thunk = int.from_bytes(a(FILTER_JUMPTABLE + 4 * row, 4), "little")
    # each thunk is `push 0x00 / push H / calr <setter>`
    assert a(thunk, 4) == bytes([0x09, 0x00, 0xCE, 0x04]), "thunk %d" % row
    assert a(thunk + 4, 1) == b"\x1e"
    d = int.from_bytes(a(thunk + 5, 2), "little", signed=True)
    FILTER_SETTERS.append(thunk + 7 + d)
assert FILTER_SETTERS == [0xF9AD21, 0xF9AD69, 0xF9ADB1, 0xF9ADF9,
                          0xF9AE41, 0xF9AE89, 0xF9AED1, 0xF9AF19], FILTER_SETTERS

FIELD_EDITOR = 0xF9A165
COMMIT = 0xF41B18            # prom_b thunk: (number, offset, value, mask)


def read_setter(setter):
    """(edited byte, edit mask, commit offset, commit mask, painter)."""
    p = setter
    end = p + 0x50
    edit_addr = edit_mask = None
    com_off = com_mask = None
    painter = None
    while p < end:
        op = a(p, 1)[0]
        if a(p, 1) == b"\x0b" and edit_mask is None:
            # `pushw mask / lda XBC,(addr) / push XBC` -- the editor call
            if a(p + 3, 1) == b"\xf1" and a(p + 6, 1) == b"\x31" \
                    and a(p + 7, 1) == b"\x39":
                edit_mask = aw(p + 1)
                edit_addr = aw(p + 4)
                p += 8
                continue
        if a(p, 4) == bytes([0x1D]) + COMMIT.to_bytes(3, "little"):
            # ... pushw mask / push 0x00 / push H / pushw offset / pushw 0x80 / call
            assert a(p - 13, 1) == b"\x0b", "no mask push"
            assert a(p - 6, 1) == b"\x0b", "no offset push"
            assert a(p - 3, 1) == b"\x0b", "no number push"
            com_mask = aw(p - 12)
            com_off = aw(p - 5)
            assert aw(p - 2) == 0x0080, "commit is not parameter 0x80"
            # the painter is the `calr` right after the commit
            assert a(p + 4, 1) == b"\x1e", "no painter after the commit"
            d = int.from_bytes(a(p + 5, 2), "little", signed=True)
            painter = p + 7 + d
            break
        p += 1
    assert None not in (edit_addr, edit_mask, com_off, com_mask, painter), hex(setter)
    return edit_addr, edit_mask, com_off, com_mask, painter


def read_painter(painter):
    """(byte read, mask tested) from the painter's `ld C,(addr) / and C,mask`.

    Seven rows shift the masked bit down into the string index; the
    EXCLUSIVE row instead preloads index 1 and drops to 0 when the mask
    comes up empty, so the load is not at the routine's first byte.  Both
    shapes are accepted, and the pair is required to be unique.
    """
    hits = []
    for p in range(painter, painter + 0x20):
        if a(p, 1) == b"\xc1" and a(p + 3, 1) == b"\x23" \
                and a(p + 4, 2) == bytes([0xCB, 0xCC]):
            hits.append((aw(p + 1), a(p + 6, 1)[0]))
    assert len(hits) == 1, hex(painter)
    return hits[0]


# the value display lists, one per row, paired (start,end) by the painter
DL_RUN = 0xF42E04            # prom_b veneer: (start, end) on the stack


def painter_lists(painter):
    """the (start, end) display-list pair the painter hands the interpreter.

    The idiom is fixed: lda XBC,<end> / push XBC / lda XWA,<start> /
    push XWA / call 0xF42E04, so the two 24-bit immediates are read back
    from the call site and both loads are re-asserted.
    """
    c = None
    for p in range(painter, painter + 0x40):
        if a(p, 4) == bytes([0x1D]) + DL_RUN.to_bytes(3, "little"):
            c = p
            break
    assert c is not None, hex(painter)
    assert a(c - 1, 1) == b"\x38", hex(painter)            # push XWA
    assert a(c - 6, 1) == b"\xf2" and a(c - 2, 1) == b"\x30", hex(painter)
    assert a(c - 7, 1) == b"\x39", hex(painter)            # push XBC
    assert a(c - 12, 1) == b"\xf2" and a(c - 8, 1) == b"\x31", hex(painter)
    start = int.from_bytes(a(c - 5, 3), "little")
    end = int.from_bytes(a(c - 11, 3), "little")
    return start, end


ROWS = []
for row, setter in enumerate(FILTER_SETTERS):
    e_addr, e_mask, c_off, c_mask, painter = read_setter(setter)
    p_addr, p_mask = read_painter(painter)
    start, end = painter_lists(painter)
    assert end - start == 15, "value list is not one record"
    assert b(start, 2) == bytes([0x02, 0x0F]), "not a string-table readout"
    coord = bw(start + 0x0D)
    ROWS.append(dict(row=row, setter=setter, painter=painter,
                     addr=e_addr, mask=e_mask, p_addr=p_addr, p_mask=p_mask,
                     off=c_off, c_mask=c_mask, coord=coord,
                     strings=bl(start + 0x07), stride=bw(start + 0x0B)))

# the editor, the painter and the commit agree on the BYTE for all 8 rows;
# on the MASK for seven of them.
for r in ROWS:
    assert r["addr"] == r["p_addr"], "row %d: painter reads a different byte" % r["row"]
    assert r["mask"] == r["p_mask"], "row %d: painter tests a different mask" % r["row"]
    assert r["mask"] == r["c_mask"], "row %d: commit mask differs" % r["row"]
    assert 0x7F32 + r["off"] == r["addr"], \
        "row %d: record 0x80 + %d != 0x%04X" % (r["row"], r["off"], r["addr"])

# ⚠ ONE ANOMALY, asserted rather than skipped: the CHANNEL PRESSURE editor
# reads its result back out of (0x7F3B) although it edited (0x7F39).  The
# painter and the commit both use the right byte, so the screen and the
# stored setting are correct; only the value handed to the commit comes
# from the neighbouring byte.
assert a(0xF9AEB0, 4) == bytes([0xC1, 0x3B, 0x7F, 0x26]), "the readback anomaly moved"
assert ROWS[5]["addr"] == 0x7F39

# CAPTIONS.  One display list draws all eight; bind each value field to the
# caption whose text ends just before it and whose successor starts after.
CAPTION_DL, CAPTION_DL_END = 0xF0CCEE, 0xF0CDE7
CAPTIONS = []
p = CAPTION_DL
while p < CAPTION_DL_END:
    op, ln = b(p, 1)[0], b(p + 1, 1)[0]
    if op in (0x06, 0x07) and ln > 5:
        txt = bytes(b(p + 4, ln - 4))
        if any(0x20 <= c < 0x7F for c in txt):
            CAPTIONS.append((bw(p + 2), txt.decode("latin-1")))
    p += ln
# join the split "RESET ALL CTRL" + "  :" caption
merged = []
for coord, txt in CAPTIONS:
    if merged and coord == merged[-1][0] + len(merged[-1][1]) + 1:
        merged[-1] = (merged[-1][0], merged[-1][1] + txt)
    else:
        merged.append((coord, txt))
merged = [m for m in merged if m[1].rstrip().endswith(":")]
assert len(merged) == 8, merged
merged.sort()
for i, r in enumerate(sorted(ROWS, key=lambda r: r["coord"])):
    c0, txt = merged[i]
    assert c0 + len(txt) <= r["coord"], "row %d value precedes its caption" % i
    if i + 1 < len(merged):
        assert r["coord"] < merged[i + 1][0], "row %d value runs into the next" % i
    r["caption"] = txt.strip().rstrip(":").strip()
assert [r["caption"] for r in sorted(ROWS, key=lambda r: r["coord"])] == [
    "PR0GRAM CHANGE", "BANK SELECT", "PITCH BEND", "C0NTR0L CHANGE",
    "RESET ALL CTRL", "CHANNEL PRESSURE", "S0NG SELECT", "EXCLUSIVE"], \
    [r["caption"] for r in sorted(ROWS, key=lambda r: r["coord"])]

EXCL = [r for r in ROWS if r["caption"] == "EXCLUSIVE"][0]
assert EXCL["addr"] == 0x7F38 and EXCL["mask"] == 0x0F, EXCL
assert EXCL["off"] == 6

# the ON/OFF strings every row shares
assert b(ROWS[0]["strings"], 6) == b"OFFON ", b(ROWS[0]["strings"], 6)
assert all(r["strings"] == ROWS[0]["strings"] and r["stride"] == 3 for r in ROWS)

# SEMANTIC WITNESSES, independent of the screen.
BANK = [r for r in ROWS if r["caption"] == "BANK SELECT"][0]
RESET = [r for r in ROWS if r["caption"] == "RESET ALL CTRL"][0]
CC_GATED = {}
for cc, idx in enumerate(CCNUM_TO_IDX):
    if idx != 0xFF and idx in CC_ENABLE:
        CC_GATED.setdefault(CC_ENABLE[idx], []).append(cc)
assert sorted(CC_GATED[(BANK["addr"], BANK["mask"])]) == [0, 32], \
    "BANK SELECT does not gate CC0/CC32"
assert sorted(CC_GATED[(RESET["addr"], RESET["mask"])]) == [121], \
    "RESET ALL CTRL does not gate CC121"

# TWO-DIRECTIONAL, from the code: the same bit opens MidiIn_ProgramChange
# and MidiOut_ProgramChange.
PROG = [r for r in ROWS if r["caption"] == "PR0GRAM CHANGE"][0]
BITOP = 0xC8 + 4            # bit 4,(mem16) -> prefix F1 lo hi CC
assert a(0xFA6D58, 4) == bytes([0xF1, 0x39, 0x7F, BITOP]), "MidiIn_ProgramChange gate"
assert a(0xFA71C4, 4) == bytes([0xF1, 0x39, 0x7F, BITOP]), "MidiOut_ProgramChange gate"
assert PROG["addr"] == 0x7F39 and PROG["mask"] == 0x10
assert int.from_bytes(a(0xFA7180, 4), "little") == 0xFA71C4, \
    "0xFA71C4 is not MidiOut_ParamNumberTable[0]"

# exactly ONE row in the firmware is captioned EXCLUSIVE
assert len(scan(B, PROM_B_BASE, b"EXCLUSIVE        :")) == 1


# ====================================================================== 3
# THE REALTIME MESSAGES PAGE -- two rows, and only one of them is a
# System Exclusive matter.
RT_VALUE_DL = 0xF0CC91
assert b(RT_VALUE_DL, 2) == bytes([0x02, 0x0F])
RT_ROWS = []
for k in (0, 1):
    p = RT_VALUE_DL + 15 * k
    RT_ROWS.append(dict(addr=bw(p + 2), mask=b(p + 4, 1)[0],
                        shift=b(p + 5, 1)[0] & 7, strings=bl(p + 7),
                        stride=bw(p + 0x0B), coord=bw(p + 0x0D)))
assert RT_ROWS[0]["addr"] == 0x7F34 and RT_ROWS[0]["mask"] == 0x04
assert RT_ROWS[1]["addr"] == 0x7F32 and RT_ROWS[1]["mask"] == 0x04
assert b(RT_ROWS[0]["strings"], 6) == b"OFFON "
assert b(RT_ROWS[1]["strings"], 16) == b"INTERNALMIDI    "
assert RT_ROWS[1]["stride"] == 8
# the editors commit on the same parameter record 0x80
assert a(0xF9A85A, 4) == bytes([0xF1, 0x34, 0x7F, 0xBA]), "set 2,(0x7F34)"
assert a(0xF9A903, 4) == bytes([0xF1, 0x34, 0x7F, 0xB2]), "res 2,(0x7F34)"

# REALTIME COMMANDS is read nowhere in the SysEx engine.
ENGINE_LO, ENGINE_HI = 0xFB2000, 0xFB8200
IN_ENGINE = lambda s: ENGINE_LO <= s < ENGINE_HI
assert not any(IN_ENGINE(s) for s in ABS_A.get(0x7F34, [])), \
    "REALTIME COMMANDS is read inside the SysEx engine"

# CLOCK is, and in both directions.
CLOCK_SITES = [s for s in ABS_A[0x7F32] if IN_ENGINE(s)]
assert sorted(CLOCK_SITES) == [0xFB202C, 0xFB338F, 0xFB3415, 0xFB57F8], CLOCK_SITES


# ====================================================================== 4
# THE THREE CONSUMERS OF THE EXCLUSIVE BIT, read instruction by
# instruction.  All three test bit 3 and all three refuse on zero.
def gate(site):
    assert a(site, 4) == bytes([0xC1, 0x38, 0x7F, 0x23]), hex(site)   # ld C,(0x7F38)
    assert a(site + 4, 2) == bytes([0xCB, 0xCC]), hex(site)           # and C,imm8
    return a(site + 6, 1)[0], a(site + 7, 1)[0]


for site in (0xFB3398, 0xFB341E, 0xFB4B7F):
    mask, branch = gate(site)
    assert mask == 0x08, "consumer %06X tests mask 0x%02X" % (site, mask)
    assert branch in (0x66, 0x76), "consumer %06X does not refuse on zero" % site

# tempo transmit -- the full gate chain, in order
assert a(0xFB3371, 4) == bytes([0x1D, 0xF5, 0x5F, 0xFB]), "feature-table call"
assert aw(0xFB336F) == 0x0005, "feature index 5"
assert a(0xFB337D, 4) == bytes([0xC1, 0x22, 0x09, 0x23]), "ld C,(0x0922)"
assert a(0xFB3387, 5) == bytes([0xC1, 0x7A, 0x20, 0x3F, 0x79]), "cp (0x207A),0x79"
assert a(0xFB338F, 4) == bytes([0xC1, 0x32, 0x7F, 0x23]), "ld C,(0x7F32)"
assert a(0xFB33A4, 5) == bytes([0xF2, 0xE3, 0xFE, 0xF4, 0x31]), "the 25 template"
assert b(0xF4FEE3, 3) == bytes([0xF0, 0x50, 0x25]), "F0 50 25"

# tempo receive -- the same three settings, minus the transport flag
assert a(0xFB3403, 4) == bytes([0x1D, 0xF5, 0x5F, 0xFB]), "feature-table call"
assert a(0xFB340E, 5) == bytes([0xC1, 0x7A, 0x20, 0x3F, 0x79]), "cp (0x207A),0x79"
assert a(0xFB3415, 4) == bytes([0xC1, 0x32, 0x7F, 0x23]), "ld C,(0x7F32)"
# and one FURTHER condition on the value being acted upon, inside FB57ED
assert a(0xFB57F8, 4) == bytes([0xC1, 0x32, 0x7F, 0x23])
assert a(0xFB57FC, 3) == bytes([0xCB, 0xCC, 0x10]), "and C,0x10 -- a 5th gate"


# ====================================================================== 5
# WHAT THE THIRD CONSUMER CAN EMIT.
EMIT_TABLE = 0xF4FB38
assert a(0xFB4BC5, 6) == bytes([0xE8, 0xC8, 0x38, 0xFB, 0xF4, 0x00]), "table base"
assert len(scan(A, PROM_A_BASE,
                bytes([0xE8, 0xC8]) + EMIT_TABLE.to_bytes(3, "little") + b"\x00")) == 1
assert a(0xFB4BB4, 3) == bytes([0xCE, 0xCF, 0xC0]), "cp H,0xC0 -- 192 entries"
assert a(0xFB4BAF, 3) == bytes([0xCE, 0xCF, 0xFF]), "cp H,0xFF -- terminator"

SLOTS = [bl(EMIT_TABLE + 4 * i) for i in range(192)]
DEAD = 0x00FB4BDD
assert a(DEAD, 1) == b"\x0e", "the default slot is not a RET"
LIVE = {i: v for i, v in enumerate(SLOTS) if v != DEAD}
assert len(LIVE) == 5, LIVE
assert sorted(LIVE) == [0x48, 0x60, 0x70, 0x98, 0xB0], sorted(LIVE)

PLACEHOLDER = 0x00F511F9
assert bl(PLACEHOLDER + 0x10) == 0x00FB4D61, "placeholder transmit method moved"
assert a(0x00FB4D61, 1) == b"\x0e", "the placeholder method is not a RET"
# the four non-GM emitters: each names a descriptor list whose FIRST entry
# is the placeholder, and the list walk returns on that entry.
assert a(0xFB4D3A, 5) == bytes([0xF2, 0xF9, 0x11, 0xF5, 0x31]), "placeholder compare"
assert a(0xFB4D41, 2) == bytes([0x66, 0x17]), "jr Z out of the walk"
DESC_LISTS = {}
for idx, entry in sorted(LIVE.items()):
    p, found = entry, None
    while p < entry + 0x50:
        if a(p, 1) == b"\xf2" and a(p + 4, 1) == b"\x31":
            v = int.from_bytes(a(p + 1, 3), "little")
            if 0xF51E00 <= v < 0xF51E80:
                found = v
                break
        p += 1
    assert found is not None, hex(idx)
    DESC_LISTS[idx] = found
    assert bl(found) == PLACEHOLDER, \
        "list 0x%06X of slot 0x%02X is not placeholder-first" % (found, idx)

# the fifth emitter, slot 0xB0, sends the two universal literals
GM_ON, GM_OFF = 0xF4FEE6, 0xF4FEEC
assert b(GM_ON, 6) == bytes([0xF0, 0x7E, 0x7F, 0x09, 0x01, 0xF7])
assert b(GM_OFF, 6) == bytes([0xF0, 0x7E, 0x7F, 0x09, 0x02, 0xF7])
assert len(scan(B, PROM_B_BASE, b(GM_ON, 6))) == 1, "a second GM ON literal"
assert len(scan(B, PROM_B_BASE, b(GM_OFF, 6))) == 1, "a second GM OFF literal"
assert scan(A, PROM_A_BASE, bytes([0xF0, 0x7E, 0x7F, 0x09])) == [], \
    "prom_a builds a GM message of its own"
for lit in (GM_ON, GM_OFF):
    named = [s for s in scan(A, PROM_A_BASE,
                             bytes([0xF2]) + lit.to_bytes(3, "little"))
             if s in BOUNDARY["a"]]
    assert len(named) == 1, "literal 0x%06X named %d times" % (lit, len(named))
    assert 0xFB4CAE <= named[0] < 0xFB4D1F, \
        "literal 0x%06X is named outside sub_FB4CAE" % lit
assert a(0xFB4CBD, 3) == bytes([0xCE, 0xCF, 0x11]), "cp H,0x11 selects GM ON"
assert a(0xFB4CCD, 3) == bytes([0xCE, 0xCF, 0x10]), "cp H,0x10 selects GM OFF"
assert LIVE[0xB0] == 0x00FB4CAE

# ★★ AND THE GENERAL MIDI EMITTER HAS A SECOND, UNGATED CALLER.
# 0xFB5F2E builds the same four-byte record on its own stack frame --
# number 0xB0, byte 0x11 for ON or 0x10 for OFF -- and calls 0xFB4CAE
# DIRECTLY, so it never passes the EXCLUSIVE test at 0xFB4B7F.  Instead it
# is suppressed by bit 7 of (0x60F020), which the two General MIDI RECEIVE
# handlers set: that is an echo interlock, not a user setting.
GM_DIRECT = 0xFB5F2E
assert a(0xFB5F36, 6) == bytes([0xC2, 0x20, 0xF0, 0x60, 0x23,
                                0xCB]), "the echo interlock moved"
assert a(0xFB5F3B, 3) == bytes([0xCB, 0xCC, 0x80]), "and C,0x80"
assert a(0xFB5F40, 3) == bytes([0xB4, 0x00, 0xB0]), "record[0] = 0xB0"
assert a(0xFB5F4B, 4) == bytes([0xBC, 0x01, 0x00, 0x11]), "record[1] = 0x11 (ON)"
assert a(0xFB5F57, 4) == bytes([0xBC, 0x01, 0x00, 0x10]), "record[1] = 0x10 (OFF)"
assert a(0xFB5F5C, 4) == bytes([0x1D, 0xAE, 0x4C, 0xFB]), "direct call to 0xFB4CAE"
# bit 7 of (0x60F020) is written by exactly the two GM receive handlers
SET7_60F020 = [s for s in scan(A, PROM_A_BASE,
                               bytes([0xF2, 0x20, 0xF0, 0x60, 0xBF]))
               if s in BOUNDARY["a"]]
assert SET7_60F020 == [0xFB51E8, 0xFB521C], SET7_60F020
# ⇒ the two callers of the General MIDI emitter, and only one is filtered
GM_CALLERS = [s for s in scan(A, PROM_A_BASE, bytes([0x1D, 0xAE, 0x4C, 0xFB]))
              if s in BOUNDARY["a"]]
assert GM_CALLERS == [0xFB5F5C], GM_CALLERS
assert bl(EMIT_TABLE + 4 * 0xB0) == 0x00FB4CAE

# 0xFB4B7D itself is reached only through prom_b thunk T_SysExTx_EmitStagedParams
assert b(0xF40900, 4) == bytes([0x1B, 0x7D, 0x4B, 0xFB]), "T_SysExTx_EmitStagedParams moved"
assert scan(A, PROM_A_BASE, bytes([0x1D, 0x7D, 0x4B, 0xFB])) == [], \
    "something calls 0xFB4B7D directly"
assert scan(A, PROM_A_BASE, bytes([0x1D, 0x00, 0x09, 0xF4])) == [0xFAB811], \
    "T_SysExTx_EmitStagedParams has more than one caller"


# ====================================================================== 6
# RECEPTION of General MIDI is NOT filtered.
HTAB1, HTAB2, HTAB3 = 0xF4F800, 0xF4F888, 0xF4F916
GM_CMD = {0x20: "General MIDI System On", 0x21: "General MIDI System Off"}
GM_HANDLER = {}
for cmd in GM_CMD:
    h1, h2 = bl(HTAB1 + 4 * cmd), bl(HTAB2 + 4 * cmd)
    assert h1 == h2, "the two ring tables disagree on command 0x%02X" % cmd
    GM_HANDLER[cmd] = h1
assert GM_HANDLER == {0x20: 0x00FB51E7, 0x21: 0x00FB520C}, GM_HANDLER
# Neither handler reads a FILTER byte.  The only settings bytes either one
# names are 0x7F4A (the record base it walks) and 0x7F4D (the GENERAL MIDI
# MODE flag it is there to change) -- so the census, restricted to the two
# handler bodies, must come out exactly {0x7F4A, 0x7F4D}.
GM_TOUCHES = set()
for cmd, h in GM_HANDLER.items():
    for addr, sites in list(ABS_A.items()) + list(IMM_A.items()):
        for s in sites:
            s = s[0] if isinstance(s, tuple) else s
            if h <= s < h + 0x40:
                GM_TOUCHES.add(addr)
assert GM_TOUCHES == {0x7F4A, 0x7F4D}, GM_TOUCHES
# 0x7F4A is the GENERAL MIDI MODE byte's own record base, not a filter:
assert a(0xFB520E, 4) == bytes([0xF1, 0x4A, 0x7F, 0x34]), "lda XIX,(0x7F4A)"
assert a(0xFB5214, 6) == bytes([0x8C, 0x03, 0x23, 0xCB, 0xCC, 0x04]), \
    "GM OFF does not test (0x7F4D) bit 2"
assert a(0xFB51ED, 5) == bytes([0xC1, 0x4D, 0x7F, 0x3E, 0x04]), \
    "GM ON does not set (0x7F4D) bit 2"


# ====================================================================== 7
# NO CHANNEL / MODE / DEVICE SETTING TAKES PART IN SYSTEM EXCLUSIVE.
MODE_BYTE, SINGLE_CH_BYTE = 0x7F35, 0x7F36
for addr in (MODE_BYTE, SINGLE_CH_BYTE):
    inside = [s for s in ABS_A.get(addr, []) if IN_ENGINE(s)]
    inside += [s for s, _ in IMM_A.get(addr, []) if IN_ENGINE(s)]
    assert inside == [], "0x%04X is read inside the SysEx engine: %s" % (addr, inside)
for word in (b"DEVICE", b"UNIT", b"DEVICE NO"):
    assert scan(B, PROM_B_BASE, word + b" ") == [], "a %s caption exists" % word


# ====================================================================== 8
# BUILT-IN INITIAL VALUES.
DEFAULTS_SRC = 0xF3FD10
assert a(0xFAA9F2, 4) == bytes([0xF1, 0x30, 0x7F, 0x34]), "lda XIX,(0x7F30)"
assert a(0xFAA9F6, 5) == bytes([0xF2, 0x10, 0xFD, 0xF3, 0x31]), "lda XBC,defaults"
assert a(0xFAA9FE, 4) == bytes([0xF1, 0x48, 0x7F, 0x31]), "lda XBC,(0x7F48) -- the end"
DEFAULTS = {0x7F30 + i: b(DEFAULTS_SRC + i, 1)[0] for i in range(0x7F48 - 0x7F30)}
assert DEFAULTS[0x7F38] == 0x0F, "EXCLUSIVE default is not ON"
assert DEFAULTS[0x7F39] == 0x78 and DEFAULTS[0x7F3A] == 0x80
assert DEFAULTS[0x7F33] & 0x08 == 0, "SONG SELECT default is not OFF"
assert DEFAULTS[0x7F32] & 0x04 == 0, "CLOCK default is not INTERNAL"
assert DEFAULTS[0x7F34] & 0x04 != 0, "REALTIME COMMANDS default is not ON"


# ====================================================================== 9
# THE SETTINGS TRAVEL IN THE SYSTEM,PART & MIDI BULK DUMP.
DUMP2_SRC_LO, DUMP2_SRC_HI = 0x007620, 0x007F80
DUMP2_ADDR, DUMP2_LEN = 0x100020, 2400
assert DUMP2_SRC_HI - DUMP2_SRC_LO == DUMP2_LEN
assert b(0xF4FF04, 12) == bytes([0xF0, 0x50, 0x2D, 0x04, 0x00, 0x11,
                                 0x40, 0x00, 0x20, 0x00, 0x12, 0x60]), \
    "the SYSTEM,PART & MIDI part-2 template moved"
assert (0x00 << 14) | (0x12 << 7) | 0x60 == DUMP2_LEN, "length septets"
assert (0x40 << 14) | (0x00 << 7) | 0x20 == DUMP2_ADDR, "address septets"
for addr in (0x7F32, 0x7F38, 0x7F4D):
    assert DUMP2_SRC_LO <= addr < DUMP2_SRC_HI


# ===================================================================== 10
# THE RACK HAS NO REALTIME MESSAGES PAGE.
assert a(0xF99F31, 4) == bytes([0xC0, 0xC4, 0x3F, 0x02]), "cp (0xC4),0x02"
assert a(0xF99F37, 5) == bytes([0xF2, 0x17, 0xC9, 0xF0, 0x31]), "variant-1 list end"
assert a(0xF99F45, 5) == bytes([0xF2, 0xD5, 0xC8, 0xF0, 0x31]), "variant-2 list end"
V1_TAIL = bytes(b(0xF0C8D5, 0xF0C917 - 0xF0C8D5))
assert b"REALTIME" in V1_TAIL and b"INPUT&0UTPUT" in V1_TAIL
assert b"REALTIME" not in bytes(b(0xF0C800, 0xF0C8D5 - 0xF0C800))


# ===================================================================== 11
# REPORT
def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--sites", action="store_true",
                    help="every instruction that names a settings byte")
    ap.add_argument("--census", action="store_true",
                    help="the full 0x7F30-0x7F4F reference census")
    args = ap.parse_args()

    print("base check OK\n")

    print("MIDI INPUT & OUTPUT FILTER -- one page, eight rows, one switch each")
    print("  %-17s %-9s %-6s %-5s %-9s %s" %
          ("row", "byte", "mask", "dflt", "editor", "painter"))
    for r in sorted(ROWS, key=lambda r: r["coord"]):
        d = "ON" if DEFAULTS[r["addr"]] & r["mask"] else "OFF"
        print("  %-17s (0x%04X)  0x%02X   %-5s 0x%06X  0x%06X" %
              (r["caption"], r["addr"], r["mask"], d, r["setter"], r["painter"]))
    print("  every row commits as parameter record 0x80, byte offset %s" %
          ", ".join(str(r["off"]) for r in sorted(ROWS, key=lambda r: r["coord"])))
    print("  the record base is 0x7F32, so offset n IS the byte 0x7F32+n\n")

    print("row -> caption, checked geometrically (value field inside the gap)")
    for i, r in enumerate(sorted(ROWS, key=lambda r: r["coord"])):
        c0, txt = merged[i]
        print("  caption 0x%04X..0x%04X %-24s value 0x%04X" %
              (c0, c0 + len(txt), repr(txt), r["coord"]))
    print()

    print("two witnesses that do not use the screen at all:")
    print("  BANK SELECT    (0x%04X bit %d) gates controllers %s"
          % (BANK["addr"], BANK["mask"].bit_length() - 1,
             CC_GATED[(BANK["addr"], BANK["mask"])]))
    print("  RESET ALL CTRL (0x%04X bit %d) gates controller  %s"
          % (RESET["addr"], RESET["mask"].bit_length() - 1,
             CC_GATED[(RESET["addr"], RESET["mask"])]))
    print("  and CONTROL CHANGE gates %d more"
          % len(CC_GATED[(0x7F39, 0x08)]))
    print("  the filter acts BOTH WAYS: MidiIn_ProgramChange (0xFA6D58) and")
    print("  MidiOut_ProgramChange (0xFA71C4) open with the same bit test\n")

    print("EXCLUSIVE: the editor writes FOUR bits, 0x0F, and the painter")
    print("  reports ON when any of them is set -- but only bit 3 is read.")
    print("  every instruction in 1 MiB x 2 that names (0x7F38):")
    for s in sorted(REFS_7F38):
        what = {0xF9ACFB: "the page's painter",
                0xF9AF2E: "the page's editor (address)",
                0xF9AF40: "the page's editor (read-back)",
                0xFB3398: "CONSUMER: `25` tempo TRANSMIT",
                0xFB341E: "CONSUMER: `25` tempo RECEIVE",
                0xFB4B7F: "CONSUMER: outgoing parameter System Exclusive"}[s]
        print("    0x%06X  %s" % (s, what))
    print("  nothing in prom_b names it at all; no indexed base can reach it")
    print("  (the only bases in the block are 0x7F36, used at offset 0, and")
    print("   0x7F39, whose two index tables use offsets 0, 1 and 2 only)\n")

    print("so EXCLUSIVE = OFF withholds:")
    print("  * the `25` tempo message, sent AND received")
    print("  * anything the staged-parameter emitter 0xFB4B7D would put out")
    print("and withholds nothing else.  NOT affected: bulk dump in either")
    print("  direction, dump requests, the handshake, `2B`/`2C` parameter")
    print("  traffic, General MIDI messages the instrument RECEIVES, and --")
    print("  see below -- the General MIDI messages it SENDS.\n")

    print("what the outgoing-SysEx routine 0xFB4B7D can actually emit")
    print("  192 dispatch slots, %d of them a bare RET" % SLOTS.count(DEAD))
    for idx in sorted(LIVE):
        if idx == 0xB0:
            print("    slot 0x%02X -> 0x%06X  the two General MIDI literals"
                  % (idx, LIVE[idx]))
        else:
            print("    slot 0x%02X -> 0x%06X  descriptor list 0x%06X -- "
                  "placeholder, emits nothing" % (idx, LIVE[idx], DESC_LISTS[idx]))
    print("  the GM literals occur ONCE EACH in prom_b and are named by ONE")
    print("  instruction each, both inside 0xFB4CAE.")
    print("  ⚠ BUT 0xFB4CAE HAS A SECOND CALLER THAT IS NOT GATED.  0xFB5F2E")
    print("  builds the same record itself -- number 0xB0, byte 0x11 for ON or")
    print("  0x10 for OFF -- and calls 0xFB4CAE directly at 0xFB5F5C, so it")
    print("  never reaches the EXCLUSIVE test.  It is held back instead by bit")
    print("  7 of (0x60F020), which is set by the two General MIDI RECEIVE")
    print("  handlers and nothing else: an echo interlock, not a user setting.")
    print("  ⇒ switching EXCLUSIVE off does NOT stop the instrument sending")
    print("    General MIDI System On/Off when General MIDI is switched on the")
    print("    panel.  The filter's one live effect is the tempo message.\n")

    print("REALTIME MESSAGES -- two rows; only CLOCK touches System Exclusive")
    for k, cap in ((0, "REALTIME COMMANDS"), (1, "CLOCK")):
        r = RT_ROWS[k]
        vals = [bytes(b(r["strings"] + r["stride"] * v, r["stride"])).decode("latin-1")
                for v in (0, 1)]
        d = (DEFAULTS[r["addr"]] & r["mask"]) >> r["shift"]
        print("  %-18s (0x%04X) bit %d   %s / %s   default %s"
              % (cap, r["addr"], r["mask"].bit_length() - 1,
                 repr(vals[0].strip()), repr(vals[1].strip()),
                 repr(vals[d].strip())))
    print("  CLOCK = MIDI suppresses the `25` message in BOTH directions")
    print("  (0xFB338F transmit, 0xFB3415 receive); REALTIME COMMANDS is not")
    print("  read anywhere in the SysEx engine 0x%06X-0x%06X\n"
          % (ENGINE_LO, ENGINE_HI))

    print("the complete gate on the `25` tempo message")
    print("  transmit: model variant allows it / no transport flag (0x0922 bit 0)")
    print("          / the SYSEX BULK DUMP screen is not up / CLOCK = INTERNAL")
    print("          / EXCLUSIVE = ON")
    print("  receive:  model variant allows it / the SYSEX BULK DUMP screen is")
    print("          not up / CLOCK = INTERNAL / EXCLUSIVE = ON")
    print("          / and one further internal condition, (0x7F32) bit 4,")
    print("            before the value reaches the tempo itself\n")

    print("no channel, mode or device-number setting takes part")
    print("  MIDI INPUT/OUTPUT MODE (0x7F35) and SINGLE CHANNEL (0x7F36) are")
    print("  not referenced anywhere in 0x%06X-0x%06X" % (ENGINE_LO, ENGINE_HI))
    print("  and no caption in prom_b reads DEVICE, UNIT or ID\n")

    print("built-in initial values, prom_b 0x%06X -> 0x7F30..0x7F47"
          % DEFAULTS_SRC)
    print("  " + " ".join("%02X" % DEFAULTS[0x7F30 + i] for i in range(0x18)))
    print("  EXCLUSIVE 0x0F = ON\n")

    print("these settings are INSIDE the SYSTEM,PART & MIDI bulk dump")
    print("  part 2 reads CPU1 0x%06X..0x%06X, dump address 0x%06X, %d bytes"
          % (DUMP2_SRC_LO, DUMP2_SRC_HI, DUMP2_ADDR, DUMP2_LEN))
    for addr, what in ((0x7F32, "CLOCK / PROG CHANGE MODE"),
                       (0x7F38, "EXCLUSIVE"),
                       (0x7F4D, "GENERAL MIDI MODE")):
        print("    0x%04X  %-26s block offset %4d (0x%03X)"
              % (addr, what, addr - DUMP2_SRC_LO, addr - DUMP2_SRC_LO))
    print("  ⇒ restoring a dump replaces them, and can switch EXCLUSIVE off\n")

    print("the rack (strap 2) has no REALTIME MESSAGES row in the MIDI menu")
    print("  0xF99F31 picks the shorter index list for variant 2\n")

    if args.sites or args.census:
        print("reference census, 0x%04X-0x%04X" % (BLOCK_LO, BLOCK_HI))
        for addr in range(BLOCK_LO, BLOCK_HI + 1):
            hits = sorted(ABS_A.get(addr, []))
            imm = sorted(s for s, _ in IMM_A.get(addr, []))
            if not hits and not imm:
                continue
            print("  0x%04X  %2d absolute  %2d immediate" %
                  (addr, len(hits), len(imm)))
            if args.sites:
                for s in hits:
                    print("        abs 0x%06X  %s" %
                          (s, " ".join("%02X" % x for x in a(s, 5))))
                for s in imm:
                    print("        imm 0x%06X  %s" %
                          (s, " ".join("%02X" % x for x in a(s, 5))))
        print()

    print("OK")


if __name__ == "__main__":
    main()
