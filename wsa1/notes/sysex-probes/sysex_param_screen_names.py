#!/usr/bin/env python3
"""WHICH PUBLISHED NAME belongs to a `00`-area SysEx parameter?

QUESTION IT ANSWERS
  `sysex_param_addresses.py` resolves 99 of the 108 parameters of the `r=00`
  area to a work-RAM byte.  It does not say what any of them IS.  This script
  names them from the instrument itself, by two mechanisms that never guess:

  A. THE MENU SCREENS.  A screen is a stream of compact records.  A caption is
         20 <len> <col> <row> <ASCII...>              (len = 4 + strlen)
     and an editable field is
         <kind> <len> <addr lo> <addr hi> <mask> <shift> <style> ... <col> <row>
     where `addr` is a 16-bit work-RAM address and `shift` is the bit position
     of the lowest set bit of `mask`.  Caption and field carry the SAME row, so
     the caption on a field's row is the label the instrument prints for that
     RAM byte -- and (mask, shift) identify the parameter exactly.

  B. THE MIDI IT EMITS / THE MIDI IT FILTERS.  A part-record bit that gates a
     routine which builds a control-change message names itself: the routine
     writes the controller number as a literal, and the manual's CONTROLLER
     ASSIGN page prints the same numbers (MODULATION1 #1, MODULATION2 #2,
     CTRL.PEDAL #4, HOLD #64, R.T.CREAT.X #16, .Y #17, R.T.CTRL.X #18, .Y #19).

SIGNAL BEING READ
  Every claim below is a literal byte string at a literal address, asserted
  here so it breaks loudly if either image is ever re-based or re-dumped.

WHAT IS *NOT* CLAIMED
  Only the rows asserted here are established.  Parameters this script does not
  mention are named elsewhere by weaker evidence (range, bit count, position)
  and must be labelled LIKELY or GUESS, not ESTABLISHED.

RUN
  python3 wsa1/notes/sysex-probes/sysex_param_screen_names.py

PASS CRITERION
  Every assert is silent and the script prints OK, then the established rows.
"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROMS = os.path.join(HERE, "..", "..", "original_ROMs")
PB = open(os.path.join(ROMS, "wsa1_prom_b.ic13"), "rb").read()
PA = open(os.path.join(ROMS, "wsa1_prom_a.ic12"), "rb").read()
B_BASE, A_BASE = 0xF00000, 0xF80000


def img(a):
    return (PB, B_BASE) if B_BASE <= a < B_BASE + len(PB) else (PA, A_BASE)


def rd(a, n):
    im, base = img(a)
    return im[a - base:a - base + n]


assert rd(0xF4FEB4, 5) == bytes([0xF0, 0x50, 0x23, 0x7E, 0xF7]), "prom_b base"
assert rd(0xF99AE3, 5) == bytes([0x00, 0x03, 0x05, 0x04, 0x02]), "prom_a base"
print("base check OK: prom_b @0xF00000, prom_a @0xF80000")


# --------------------------------------------------------------- the records
# A caption record is  [style?] [len] [col] [row] <ASCII...> : the two bytes
# immediately before the text are always its column and its text row, in both
# of the two header shapes the screens use.  Passing the ADDRESS OF THE TEXT
# therefore reads the position without having to know which shape it is.
def caption(text_addr, text):
    got = rd(text_addr, len(text)).decode("latin1")
    assert got == text, "0x%06X reads %r, expected %r" % (text_addr, got, text)
    col, row = rd(text_addr - 2, 2)
    return col, row


def field(a):
    """<kind> <len> <addr16> <mask> <shift> ... ; returns (addr, mask, shift)."""
    r = rd(a, 6)
    assert r[0] <= 0x05 and 8 <= r[1] <= 0x20, "0x%06X is not a field record" % a
    addr = r[2] | (r[3] << 8)
    mask, shift = r[4], r[5]
    lo = 0
    while not (mask >> lo) & 1:
        lo += 1
    assert shift == lo, "0x%06X: shift %d is not mask 0x%02X's low bit" % (a, shift, mask)
    return addr, mask, shift


def pos(a, off):
    """the (col, row) pair at `off` inside a field record."""
    return tuple(rd(a + off, 2))


def find(lo, hi, needle):
    """is this exact byte string anywhere in [lo, hi)?"""
    return rd(lo, hi - lo).find(needle) >= 0


# ------------------------------------------------------- A. named by a screen
# (parameter, caption text address, caption text, field record, offset of the
#  field's (col,row), expected RAM address, mask)
SCREENS = [
    # SYSTEM > TUNE & SCALE                          (prom_a 0xFA1F21..)
    ("10/00", 0xFA20CC, "KEY TRANSPOSE      :", 0xFA21D3, 0x07, 0x78B2, 0x7F),
    ("10/10", 0xFA20EE, "KEY SCALING MODE   :", 0xFA21DE, 0x0D, 0x78A3, 0x80),
    ("10/12", 0xFA2131, "KEY SCALING SHIFT  :", 0xFA21FC, 0x07, 0x78A3, 0x0F),
    # SYSTEM > OVERALL TOUCH SENSITIVITY             (prom_a 0xFA2540..)
    ("00/10", 0xFA2558, "VELOCITY CURVE        : ", 0xFA262B, 0x07, 0x7F5A, 0x0F),
    ("00/11", 0xFA2573, "VELOCITY OFFSET       : ", 0xFA2635, 0x07, 0x7F5C, 0x7F),
    ("00/12", 0xFA258E, "AFTER TOUCH CURVE     : ", 0xFA263F, 0x07, 0x7F5F, 0xFF),
    ("00/13", 0xFA25A9, "AFTER TOUCH THRESHOLD : ", 0xFA2649, 0x07, 0x7F60, 0x7F),
    # SYSTEM > SOUND/COMBI MANAGER > DATA LOAD FILTER (prom_a 0xFA4290..)
    ("00/30", 0xFA42AC, "EFFECT & OUTPUT : ", 0xFA43C9, 0x0D, 0x7EE4, 0x0F),
    ("00/31", 0xFA42C1, "R.T.CREATOR 1_6 : ", 0xFA43D8, 0x0D, 0x7EE4, 0xF0),
    ("00/32", 0xFA42E5, "OCTAVE          : ", 0xFA43E7, 0x0D, 0x7F07, 0x04),
    ("00/33", 0xFA42FA, "MIDI SETTING    : ", 0xFA43F6, 0x0D, 0x7F07, 0x02),
    ("00/34", 0xFA430F, "KEY&VEL LAYER   : ", 0xFA4405, 0x0D, 0x7F07, 0x01),
    ("00/35", 0xFA4324, "MAIN OUT EQ     : ", 0xFA4414, 0x0D, 0x7F07, 0x08),
    ("00/36", 0xFA4339, "KEY SCALING     : ", 0xFA4423, 0x0D, 0x7F07, 0x10),
    # SYSTEM > SOUND/COMBI MANAGER > MEMORY PROTECT   (prom_a 0xFA44EA..)
    ("00/01", 0xFA451F, "COMBINATION   : ", 0xFA459E, 0x0D, 0x7FD6, 0x02),
]
for pid, cap, text, fld, off, addr, mask in SCREENS:
    col, row = caption(cap, text)
    a, m, _ = field(fld)
    fcol, frow = pos(fld, off)
    assert (a, m) == (addr, mask), \
        "%s: field 0x%06X is 0x%04X/0x%02X, expected 0x%04X/0x%02X" % (
            pid, fld, a, m, addr, mask)
    assert frow == row and fcol > col, \
        "%s: the value cell is at (%d,%d), the caption at (%d,%d)" % (
            pid, fcol, frow, col, row)

# MEMORY PROTECT's SOUND row is the case that proves the position is ONE
# 16-bit number and not two bytes: the caption sits at column 240 and is 15
# characters long, so its value cell lands at 240+15+2 = 257, which the record
# stores as column 1 of the NEXT row.
assert caption(0xFA450C, "SOUND         :") == (0xF0, 0x0D), "MEMORY PROTECT > SOUND moved"
assert field(0xFA458F) == (0x7FD6, 0x01, 0) and pos(0xFA458F, 0x0D) == (0x01, 0x0E)

# SOUND MUTE, on the very next screen, reads 0x7F0B -- which is NOT one of the
# 108 parameters.  Recorded here so the negative is checkable.
assert caption(0xFA466C, "SOUND MUTE :") == (0x8C, 0x16), "SOUND MUTE moved"
assert field(0xFA46B4) == (0x7F0B, 0x01, 0)

# SYSTEM > TUNE & SCALE > MASTER TUNE.  The cell shows staging 0x264C/0x264D on
# the MASTER TUNE row, and prom_a 0xFA0525 fills exactly those two bytes from a
# reverse lookup of (0x7F4A) in the table at 0xFA1C5C: index H gives
# H/3 + 27 whole hertz and H%3 the tenth, so H=1 is 427.3 Hz and H=78 is
# 453.0 Hz -- the published range to the last digit.
assert caption(0xFA20A1, "MASTER TUNE        : ") == (0xE3, 0x06), "MASTER TUNE caption moved"
assert field(0xFA21BF)[0] == 0x264C and pos(0xFA21BF, 0x07) == (0xF9, 0x06)
assert field(0xFA21C9)[0] == 0x264D and pos(0xFA21C9, 0x07) == (0xFC, 0x06)
assert rd(0xFA052C, 4) == bytes([0xF1, 0x40, 0x26, 0x34]), "0xFA052C is not `lda XIX,0x2640`"
assert rd(0xFA0530, 2) == bytes([0x26, 0x01]), "the MASTER TUNE loop no longer starts at H=1"
assert rd(0xFA0538, 6) == bytes([0xE9, 0xC8, 0x5C, 0x1C, 0xFA, 0x00]), "the Hz table moved"
assert rd(0xFA0540, 4) == bytes([0xC1, 0x4A, 0x7F, 0x21]), "0xFA0540 no longer reads (0x7F4A)"
assert rd(0xFA0550, 6) == bytes([0xCB, 0x0A, 0x03, 0xCB, 0xC8, 0x1B]), "not `div C,3 / add C,27`"
assert rd(0xFA0556, 5) == bytes([0xEC, 0x12, 0xBC, 0x0C, 0x43]), "the whole-Hz digit left +0x0C"
HZ = rd(0xFA1C5C, 79)
assert HZ[1] == 0xC0 and HZ[78] == 0x3F and len(set(HZ)) > 60, "the Hz table changed"
assert (1 // 3 + 27, 1 % 3) == (27, 1) and (78 // 3 + 27, 78 % 3) == (53, 0), "427.3 .. 453.0"

# SYSTEM > DRUMS MAP.  (0x7F4E) selects one of THREE user note maps in RAM,
# and its SysEx white-list is exactly four values {0x00, 0x40, 0x41, 0x42}.
assert rd(0xFC25B8, 4) == bytes([0xC1, 0x4E, 0x7F, 0x20]), "0xFC25B8 no longer reads (0x7F4E)"
for site, val in ((0xFC25BF, 0x40), (0xFC25C4, 0x41), (0xFC25C9, 0x42)):
    assert rd(site, 3) == bytes([0xC8, 0xCF, val]), "0x%06X no longer compares 0x%02X" % (site, val)
for site, tbl in ((0xFC25D0, 0x5EE0), (0xFC25D7, 0x5F70), (0xFC25DE, 0x6000)):
    assert rd(site, 5) == bytes([0x44]) + tbl.to_bytes(4, "little"), \
        "0x%06X no longer names the user map at 0x%04X" % (site, tbl)

# MIDI > TOTAL MODE (prom_b 0xF0C980..).  The six value cells carry the six
# value LISTS, in the same order as the six parameters 01/00..01/05, and each
# caption shares its cell's row.  The first three lists have 3, 2 and 16
# entries, which is the parameter ranges 0..2, 0..1 and 0..15 exactly.
TOTAL_MODE = [
    ("01/00", 0xF0C996, "MIDI INPUT MODE :  ", 0xF0CA2F, 0xF0CA9F, 6),
    ("01/01", 0xF0C9AC, "MIDI OUTPUT MODE:  ", 0xF0CA3E, 0xF0CAB1, 6),
    ("01/02", 0xF0C9C2, "SINGLE CHANNEL  :  ", 0xF0CA4D, 0xF0CABD, 6),
    ("01/03", 0xF0CA1D, "LOCAL TOTAL     : ", 0xF0CA5C, 0xF0CB7D, 3),
    ("01/04", 0xF0C9D8, "PROG CHANGE MODE:  ", 0xF0CA6B, 0xF0CB83, 6),
    ("01/05", 0xF0C9EE, "SINGLE CH PROG CHANGE: ", 0xF0CA7A, 0xF0CB95, 5),
]
EXPECT = {0xF0CA9F: ["MULTI ", "SINGLE", "OMNI  "],
          0xF0CAB1: ["MULTI ", "SINGLE"],
          0xF0CB7D: ["ON ", "OFF"],
          0xF0CB83: ["NORMAL", "TECH  "],
          0xF0CB95: ["SOUND", "COMBI"]}
for pid, cap, text, fld, tbl, w in TOTAL_MODE:
    col, row = caption(cap, text)
    r = rd(fld, 0x0F)
    assert r[0] == 0x02 and r[1] == 0x0F, "%s: 0x%06X is not a list cell" % (pid, fld)
    assert int.from_bytes(r[7:11], "little") == tbl, "%s: the value list moved" % pid
    assert int.from_bytes(r[0x0B:0x0D], "little") == w, "%s: entry width" % pid
    assert r[0x0E] == row, "%s: field row %d != caption row %d" % (pid, r[0x0E], row)
    if tbl in EXPECT:
        got = [rd(tbl + i * w, w).decode("latin1") for i in range(len(EXPECT[tbl]))]
        assert got == EXPECT[tbl], "%s: value list is %r" % (pid, got)
assert rd(0xF0CABD, 12).decode("latin1") == "1 - 1 1 - 2 ", "the SINGLE CHANNEL list moved"

# ---------------------------------------- B. named by the MIDI they gate/emit
# Ten routines, each `bit n,(XIY+d)` on the part's record 0x20 followed by a
# call to a builder that writes a literal controller number.  XIY is the part
# record and `add XIY,0x20` has already been done, so d is the descriptor's
# own byte offset inside record 0x20.
CTRL = [
    ("20/70", 0xFC0718, 0x0B, 6, 0xFC170D, None, 0xE0, "PITCH BEND"),
    ("20/71", 0xFC073D, 0x0C, 1, 0xFC166C, 0x01, 0xB0, "MODULATION1"),
    ("20/72", 0xFC085E, 0x0E, 4, 0xFC16BA, 0x02, 0xB0, "MODULATION2"),
    ("20/73", 0xFC07CA, 0x0E, 0, 0xFC1686, 0x10, 0xB0, "CREATOR    X"),
    ("20/74", 0xFC07EF, 0x0E, 1, 0xFC1693, 0x11, 0xB0, "CREATOR    Y"),
    ("20/75", 0xFC0814, 0x0E, 2, 0xFC16A0, 0x12, 0xB0, "CONTROLLER X"),
    ("20/76", 0xFC0839, 0x0E, 3, 0xFC16AD, 0x13, 0xB0, "CONTROLLER Y"),
    ("20/77", 0xFC07A3, 0x0C, 0, 0xFC15C5, 0x40, 0xB0, "HOLD1"),
    ("20/78", 0xFC0883, 0x0E, 5, 0xFC16C7, 0x04, 0xB0, "CTL. PEDAL"),
    ("20/79", 0xFC077E, 0x0B, 5, 0xFC1700, None, 0xD0, "AFTER TOUCH"),
]
for pid, site, disp, bit, sub, cc, status, name in CTRL:
    assert rd(site - 6, 6) == bytes([0xED, 0xC8, 0x20, 0x00, 0x00, 0x00]), \
        "%s: 0x%06X is not preceded by `add XIY,0x20`" % (pid, site)
    assert rd(site, 3) == bytes([0xBD, disp, 0xC8 + bit]), \
        "%s: 0x%06X is not `bit %d,(XIY+0x%02X)`" % (pid, site, bit, disp)
    assert rd(site + 8, 1) == b"\x1e", "%s: 0x%06X+8 is not a `calr`" % (pid, site)
    disp16 = int.from_bytes(rd(site + 9, 2), "little")
    assert (site + 11 + disp16) & 0xFFFFFF == sub, \
        "%s: 0x%06X no longer calls 0x%06X" % (pid, site, sub)
    assert rd(sub, 3) == bytes([0xB4, 0x00, status]), \
        "%s: 0x%06X no longer emits status 0x%02X" % (pid, sub, status)
    if cc is not None:
        assert rd(sub + 3, 4) == bytes([0xBC, 0x02, 0x00, cc]), \
            "%s: 0x%06X no longer writes controller 0x%02X" % (pid, sub, cc)
# the AFTER TOUCH routine is additionally gated on AFTER TOUCH CURVE (00/12)
assert rd(0xFC075E, 5) == bytes([0xC1, 0x5F, 0x7F, 0x3F, 0x00]), \
    "the AFTER TOUCH routine no longer tests (0x7F5F)"
# these messages go to CPU 2 over the inter-CPU link, i.e. to the INTERNAL
# sound generator -- which is what makes 20/70..79 the INTERNAL SOUND page and
# their bit-for-bit mirror 20/55..5E the MIDI OUTPUT FILTER page.
assert rd(0xFC1A29, 4) == bytes([0x1D, 0xD4, 0x0E, 0xF4]), "0xFC1A29 no longer calls 0xF40ED4"

# The MIDI SOUND overrides: part+0x15 bit n chooses the INTERNAL byte or the
# override byte, which names each override by the internal byte it replaces.
OVERRIDE = [
    ("20/60", 0xF97459, 0, 0x00, 0x0E, "PROG CHANGE"),
    ("20/61", 0xF97489, 5, 0x01, 0x10, "BANK MSB / BANK LSB"),
    ("20/63", 0xF974DB, 1, 0x03, 0x11, "VOLUME"),
    ("20/64", 0xF9750B, 2, 0x08, 0x12, "PAN"),
    ("20/66", 0xF9753B, 3, 0x05, 0x13, "(the EFFECT1 SEND counterpart)"),
    ("20/65", 0xF9756B, 4, 0x07, 0x14, "REVERB DEPTH"),
]
for pid, site, bit, internal, override, name in OVERRIDE:
    assert rd(site, 3) == bytes([0xBC, 0x15, 0xC8 + bit]), \
        "%s: 0x%06X is not `bit %d,(XIX+0x15)`" % (pid, site, bit)
    assert find(site, site + 0x30, bytes([0x8C, internal, 0x25])), \
        "%s: the internal source is no longer (XIX+0x%02X)" % (pid, internal)
    assert find(site, site + 0x30, bytes([0x8C, override, 0x25])), \
        "%s: the override source is no longer (XIX+0x%02X)" % (pid, override)
# and the same bits are what the descriptors' own second-write records set
for pid, xlat, mask in (("20/60", 0, 0x01), ("20/63", 1, 0x02), ("20/64", 2, 0x04),
                        ("20/65", 3, 0x10), ("20/66", 4, 0x08)):
    rec = int.from_bytes(rd(0xF51E70 + 4 * xlat, 4), "little")
    assert rd(rec, 4) == bytes([0x00, 0x15, mask, mask]), \
        "%s: its second write is no longer {record 0, offset 0x15, 0x%02X}" % (pid, mask)

# The three MIDI-IN filters, each gating the receiver for one message type.
assert rd(0xFA6DB1, 3) == bytes([0xBC, 0x2F, 0xCC]), "PROG CHANGE gate moved"
assert rd(0xFA63B7, 3) == bytes([0xBC, 0x30, 0xCF]), "BANK SELECT gate moved"
assert rd(0xFA6613, 3) == bytes([0xBC, 0x30, 0xCA]), "VOLUME gate moved"
# The receiver dispatches on the status nibble: `and L,0x70 / srl 2,HL` turns
# a status byte into a 4-byte index into the table at 0xFA6242, so entry k
# serves status 0x80+0x10*k.  Entry 3 (0xBn) is the control-change dispatcher
# and entry 4 (0xCn) is the program-change handler whose body carries the
# +0x2F bit-4 gate.
assert rd(0xFA6229, 3) == bytes([0xCF, 0xCC, 0x70]), "the status mask is no longer 0x70"
assert rd(0xFA622C, 3) == bytes([0xDB, 0xEF, 0x02]), "the status index is no longer >>2"
assert rd(0xFA622F, 5) == bytes([0x44, 0x42, 0x62, 0xFA, 0x00]), "the status table moved"
STATUS = [int.from_bytes(rd(0xFA6242 + 4 * k, 4), "little") for k in range(8)]
assert STATUS[3] == 0xFA6267 and STATUS[4] == 0xFA6D58, "the status table moved: %r" % STATUS
assert 0xFA6D58 < 0xFA6DB1 < 0xFA6DE2, "the program-change gate left its handler"
assert rd(0xFA6267, 5) == bytes([0x44, 0xE8, 0x83, 0xFA, 0x00]), "the CC map moved"
assert rd(0xFA62AA, 5) == bytes([0x44, 0xB8, 0x62, 0xFA, 0x00]), "the handler table moved"
CCMAP = rd(0xFA83E8, 0x80)


def handler(cc):
    i = CCMAP[cc]
    assert i != 0xFF, "controller %d is unhandled" % cc
    return int.from_bytes(rd(0xFA62B8 + 4 * i, 4), "little")


assert handler(7) == 0xFA65F1, "CC 7 (volume) no longer reaches the +0x30 bit-2 gate"
assert 0xFA65F1 < 0xFA6613 < 0xFA664F, "the volume gate left its routine"
assert 0xFA6390 < 0xFA63B7 < 0xFA63E8, "the bank gate left its routine"
for cc in (0, 32):
    assert handler(cc) in (0xFA63E9, 0xFA6379), \
        "CC %d (bank select) no longer reaches 0xFA6390's routine" % cc
# the CONTROLLER ASSIGN defaults the manual prints, as this map holds them
for cc, idx in ((1, 0x01), (2, 0x0A), (4, 0x0B), (16, 0x0C), (17, 0x0D),
                (18, 0x0E), (19, 0x0F), (64, 0x00)):
    assert CCMAP[cc] == idx, "controller %d is no longer handler %d" % (cc, idx)

print("OK")

ESTABLISHED = [
    ("00/00", "MEMORY PROTECT > SOUND"),
    ("00/01", "MEMORY PROTECT > COMBINATION"),
    ("00/08", "MASTER TUNE (427.3 - 453.0 Hz)"),
    ("00/10", "TOUCH SENSITIVITY > VELOCITY CURVE"),
    ("00/11", "TOUCH SENSITIVITY > VELOCITY OFFSET"),
    ("00/12", "TOUCH SENSITIVITY > AFTER TOUCH CURVE"),
    ("00/13", "TOUCH SENSITIVITY > AFTER TOUCH THRESHOLD"),
    ("00/20", "DRUMS MAP (NORMAL / USER 1-3)"),
    ("00/30", "DATA LOAD FILTER > OVERALL > EFFECT & OUTPUT"),
    ("00/31", "DATA LOAD FILTER > OVERALL > R.T.CREATOR 1-6"),
    ("00/32", "DATA LOAD FILTER > COMBINATION > OCTAVE"),
    ("00/33", "DATA LOAD FILTER > COMBINATION > MIDI SETTING"),
    ("00/34", "DATA LOAD FILTER > COMBINATION > KEY&VEL LAYER"),
    ("00/35", "DATA LOAD FILTER > COMBINATION > MAIN OUT EQ"),
    ("00/36", "DATA LOAD FILTER > COMBINATION > KEY SCALING"),
    ("01/00", "MIDI > TOTAL MODE > MIDI INPUT MODE"),
    ("01/01", "MIDI > TOTAL MODE > MIDI OUTPUT MODE"),
    ("01/02", "MIDI > TOTAL MODE > SINGLE CHANNEL"),
    ("10/00", "KEY TRANSPOSE"),
    ("10/10", "KEY SCALING MODE"),
    ("10/12", "KEY SCALING SHIFT"),
    ("20/48", "PART > PROG CHANGE MIDI IN"),
    ("20/49", "PART > BANK SELECT MIDI IN"),
    ("20/4A", "PART > VOLUME MIDI IN"),
    ("20/60", "PART > MIDI SOUND > PROG CHANGE"),
    ("20/61", "PART > MIDI SOUND > BANK MSB / BANK LSB"),
    ("20/63", "PART > MIDI SOUND > VOLUME"),
    ("20/64", "PART > MIDI SOUND > PAN"),
    ("20/65", "PART > MIDI SOUND > REVERB DEPTH"),
]
ESTABLISHED += [(pid, "PART > INTERNAL SOUND (PAGE2/3) > " + name)
                for pid, _, _, _, _, _, _, name in CTRL]
print("\n  %d parameters named by the instrument itself:" % len(ESTABLISHED))
for pid, name in sorted(ESTABLISHED):
    print("    %s  %s" % (pid, name))
