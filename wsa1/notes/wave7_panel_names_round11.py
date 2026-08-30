#!/usr/bin/env python3
"""WHICH PANEL BUTTON REACHES WHICH prom_b HANDLER -- the naming proposal, and
the refusals, for the 124 routines round 8 left as sub_XXXXXX.

QUESTION IT ANSWERS
  Round 8 converted prom_b 0xF7E2D8-0xF7FFFF and refused to name 124 of its 210
  routines, because "what distinguishes one handler from the next is THE BUTTON
  NUMBER" and no vocabulary mapped a number onto a legend.  Round 9 solved
  LAYER 1 (the wire), round 10 solved LAYER 2 (the ROM tables that turn a wire
  change into an event code), and both stopped short of the legend, leaving
  three stated holes.  This script walks the chain to the handler and answers,
  per routine: WHICH CONTROL ON THE FRONT PANEL PRESSES IT.

  ==> 117 of the 124 get a proposal with a full evidence chain.  7 are REFUSED,
  each with the reason, and the refusals are listed as carefully as the names.

★★ THE FINDING THAT UNBLOCKS IT: **VARIANT 2 IS THE SX-WSA1R**, and the three
holes were three symptoms of reading VARIANT 1 against a variant-2 machine.

  prom_a keeps two of everything -- two wire->group maps (0xF8A109/0xF8A189),
  two group->event-list tables (0xF8B446/0xF8B4B2), two action tables
  (0xF8B74A/0xF8B7AE) -- picked by `cp (0xC4),0x01` and (0xC4) is the model
  strap, PB bit 0, latched once at 0xF82882.  Round 10 read the tables and
  quoted VARIANT 1 throughout.  Three independent measurements say the machine
  whose service manual round 9's physical map came from is VARIANT 2:

  V1. THE FITTED-SWITCH SET MATCHES, POSITION FOR POSITION, AND ONLY FOR
      VARIANT 2.  Round 9 read the two diode lists on manual page 32 -- CP1
      "D1-23, 25-48", CP2 "D57-60,65,66,73-77" -- as 58 fitted switches with
      four holes (SW24; SW49-56; SW61-64; SW67-72; SW78-80).  Variant 2's wire
      map answers to wires 0xC0-0xC5, 0xC7, 0xC8, 0xC9 and its lists cover
      EXACTLY those 58 matrix positions and no others: wire 0xC2 stops at bit 6
      (SW24 absent), wire 0xC6 is not in the map at all (SW49-56), 0xC7 carries
      four bits (SW57-60), 0xC8 two (SW65-66), 0xC9 five (SW73-77).  Variant 1
      needs 0xC6 (SW49-56), 0xC7 bits 4-7 (SW61-64), 0xC8 bits 0-6 (SW65-71) and
      a wire 0xCA (SW81-88) -- a column the manual's own numbering has no room
      for, since CP2's last group starts at 73.  `--variant` prints both sides.
  V2. THE POWER-ON CHORDS.  Round 9's own committed check already found that two
      of the three variant-1 chords need switches this panel does not fit, and
      all three variant-2 chords are fitted
      (notes/wave7_panel_button_codes.py --selftest, d_poweron_chords).
  V3. ★ THE NUMBER PAD DECODES TO ITS OWN LEGENDS, AND ONLY UNDER VARIANT 2.
      Each variant's group-0x01/0x02 action handler ends with a 16-byte value
      table it indexes by BIT NUMBER (sub_F8A913 turns a one-bit mask into a
      1-based bit index; `add E,0x08` at 0xF8ADF8 / 0xF8AD07 folds segment 2's
      nibble in above segment 1's byte):
          variant 1, table 0xF8ADCD:  ff 01 02 03 04 05 06 07 08 09 00 80 0f ...
          variant 2, table 0xF8AE57:  ff 00 01 02 03 04 05 06 07 08 09 80 0f ...
      so segment-1 bit b decodes to digit b+1 under variant 1 and to DIGIT b
      under variant 2.  Round 9's silkscreen reading is SW9="0" .. SW16="7",
      i.e. segment-1 bit b = key b -- variant 2.  And the same table settles
      what the two non-digit values are, from the ROM and not from the legend:
        * 0x80 -> `ld XWA,0x2820 / cp (XWA),0x2b / ld (XWA),0x2b` else
          `ld (XWA),0x2d` (0xF8AE28/0xF8AE33): '+' <-> '-'.  THE SIGN KEY.
        * <=0x09 -> shift the three bytes at 0x2821 down one and store
          `E + 0x30` (0xF8AE4C): a DIGIT, in ASCII, into a numeric field.
        * 0x0F -> gated on (0x2823)==0x20 and stored to (0x2267): ENTER.
      Round 9 graded SW9-SW20 LEGEND, from the silkscreen alone.  The ROM now
      says the same twelve keys in the same order, `add A,0x30` included.
      ★ THIS IS THE BUTTON VOCABULARY ROUND 8 LOOKED FOR AND DID NOT FIND.

★★ WHAT THAT DOES TO THE THREE HOLES

  HOLE 1, THE COLLISION (variant-1 groups 0x03/0x04 and 0x05/0x06 emit
    byte-identical lists).  It is a VARIANT-1 phenomenon.  Under variant 2 no
    two button groups share a delivered code: the 32 single-bit class-0xA9
    button entries carry 32 DISTINCT delivered code bytes, one per fitted
    switch, and the 26 remaining fitted switches are covered by whole-field
    entries.  32 + 8 + 4 + 8 + 4 + 2 = 58 = the fitted count, exactly.
    ⚠ NOT DISMISSED: the collision still means a name taken from the WSA1R
    panel is WRONG for the SX-WSA1, so every proposal below is labelled
    VARIANT 2 and says what variant 1 sends to the same slot.
  HOLE 2, NOBODY PRODUCES CODE 0x0E.  Round 10 named the seven non-wire
    appenders at 0xF8A2D6..0xF8A3AE as the likely producers.  THEY ARE READ
    HERE AND THEY ARE ELIMINATED: six of them are one routine, sub_F8A303,
    which posts GROUPS 0x10-0x15 whose lists carry classes 0xBA, 0xBB, 0xB4,
    0xBD, 0xB8, 0xB9 -- never class 0xA9 -- and the seventh (0xF8A2D6) posts a
    group taken from the counter (0x219C).  `--appenders`.  The hole is
    narrowed, not closed, and the narrowing is stated in `--hole0e`.
  HOLE 3, GROUP vs SEGMENT FOR THE DIAL.  Round 10: "round 9 puts -1/+1 at
    SEGMENT 3 bits 5 and 6; the event table puts code 0x0D at GROUP 0x0A bits 5
    and 6; the BIT positions agree exactly, the SEGMENT does not; one of the two
    is wrong."  NEITHER IS.  That reading is variant 1's.  In VARIANT 2 code
    0x0D sits in GROUP 0x03, masks 0x20 and 0x40 -- segment 3, bits 5 and 6.
    The two maps agree outright, on the machine the manual describes.

★ AND THE WHOLE OF WIRE 0xC3 = SEGMENT 3 FALLS OUT AT ONCE, which is the check
  that makes the reading hard to have got by luck.  Round 9's eight legends for
  that column, four LOCKED against the manual's OUTSEL-check annotations and
  four graded POSITION (its weakest), against variant 2's eight records:
      bit 0..4  LCD RIGHT 1..5   ->  codes 0x08, 0x09, 0x0A, 0x0B, 0x0C
                                     five consecutive codes for five keys in a
                                     column
      bit 5,6   "-1", "+1"       ->  ONE code 0x0D, the two members of one pair,
                                     and PanelButton_Route builds its dial step
                                     as `(W & 0x80) | 1` at 0xF861D1 -- bit 7 is
                                     the SIGN, and bit 7 is set for bit 5 = "-1"
      bit 7     "EXIT"           ->  code 0x0F, the ONLY slot all 32 screen
                                     tables handle, and the one PanelButton_Route
                                     special-cases to clear bit 7 of (0x2075) on
                                     release (0xF861FB)
  Three independent properties of the ROM landing on three POSITION-graded
  guesses in the same eight bits.

★ WHAT BIT 7 OF THE CODE MEANS -- round 9 struck "released" and said it was not
  established; round 10 said "which member of the pair" without saying which
  member.  Per code family, on the SX-WSA1R:
      codes 0x00-0x07   bit 7 = the soft-key ROW.  Set = the LOWER of the two
                        (segment-4/5 even bits), clear = the UPPER.
      codes 0x08-0x0C   bit 7 = the SIDE of the LCD.  Set = the CP2 column
                        (SW73-77), clear = the CP1 column (SW25-29).
      code  0x0D        bit 7 = the SIGN of the +-1 step.
  And prom_b's eight `item i / item i+8` handlers at 0xF7ECFF-0xF7EDC6 are the
  eight soft-key COLUMNS of the TRACK CLEAR screen: bit 7 clear (upper row)
  selects items 0-7 and bit 7 set (lower row) items 8-15, which is a 16-entry
  list drawn as two rows of eight, read top row first.  ⚠ That the UPPER row is
  the odd bit is round 9's POSITION-grade guess; the item i / i+8 numbering
  CORROBORATES it (the other assignment would number the bottom row first) and
  does not prove it.

⚠⚠ A CORRECTION THIS LANE OWES THE ROUND BRIEF AND THE ROUND-8 BANNER
  1. THE 32-ENTRY BUTTON TABLES ARE NOT INDEXED THROUGH sub_F55019's REMAP.
     The brief for this round says the chain runs "code -> (through prom_b
     sub_F55019's remap) table slot -> handler".  It does not.  The screen's +8
     Button stub loads its table into XIX and calls T_F41B08 = prom_a
     sub_F8BDC5, which does `and L,0x1f / sla 0x02,L / ld XIX,(XIX+L) /
     call (XIX)` at 0xF8BDEA-0xF8BDF5: the slot is the RAW code, bit 7 removed.
     sub_F55019 is a different consumer on a different thunk (T_F42C74) and its
     23-slot remap belongs to the four 23-entry tables in prom_a
     (0xFA1690, 0xFA176E, 0xFA17CF, 0xFA1A02) that
     notes/wave7-verify-probes/wave7_r10_screen_table_entry_count.py measured.
     Two table families, two index rules; only the prom_a family is remapped.
  2. THE PRODUCER OF SLOTS 0x11-0x19 IS FOUND, AND IT IS NOT CLASS 0xA8.
     The round-8 banner above ButtonTable_Edit_0C10Zero says "slots 0x0E and
     0x11-0x19 are filled by a screen and NO template emits them ... The
     producer of those nine codes is unfound; class 0xA8 is where to look."
     The producer is the pair of variant-1 action handlers 0xF8AE68/0xF8AEDB:
     when the button's bit is ALREADY SET in the held bitmap (0x2252)/(0x2256)
     they rewrite the event's code byte in place with `add (XIX-1),0x11` at
     0xF8AE7E/0xF8AEF1 and shift the bit mask by the SAME 0x11 -- `sla 0x00,XDE`
     then `sla 0x01,XDE`, and a shift count of 0 means 16 on this core
     (mame/src/devices/cpu/tlcs900/900tbl.hxx:1011,
     `count = (s & 0x0f) ? (s & 0x0f) : 16`), so 16 + 1 = 17 = 0x11 -- clamping
     to code 0x19 and mask 0x02000000 = 1 << 0x19 when the bit shifts out.
     So codes 0x11-0x18 are the ALREADY-HELD forms of base codes 0x00-0x07, they
     exist ONLY under variant 1, and the fifteen prom_b handlers registered at
     BOTH slot i and slot i+0x11 are one handler serving the press and the
     repeat.  Class 0xA8 has nothing to do with it.
  3. SLOT 0x0E IS FILLED BY ONE SCREEN AND THAT IS NOT EVIDENCE OF A PRODUCER.
     The one table with code at slot 0x0E is TRACK ASSIGN PRESETS, and it fills
     ALL SIXTEEN of slots 0x00-0x0F with sixteen distinct handlers.  Its 0x0E
     entry is table completeness.

★ AND THE EMULATOR AGREED FIRST, FROM THE OTHER END.  The MAME driver already
  declares `init_wsa1r() { m_model = 2; }  // PB.0 low` and `1 = SX-WSA1
  (keyboard), 2 = SX-WSA1R (rack)` (kn7000_mame/src/mame/matsushita/wsa1.cpp
  :399, :408).  Nothing in V1/V2/V3 above used the driver, and nothing in the
  driver used these tables; two readings from opposite ends of the machine.

⚠ WHAT THIS LANE FOUND IN WORK COMMITTED EARLIER IN THIS SAME ROUND
  While this lane was reading, a writer lane applied round 10's five prom_a
  names -- all five are in prom_a now and `--five` re-verifies every one
  against the ROM.  Two things in what it wrote need correcting, and both are
  in the header of PanelGroupQueue_AppendFlaggedGroups (0xF8A303):
    * "the variant test skips the WHOLE ROUTINE" -- it skips the FIRST FOUR of
      six blocks (`jr Z,0x70` at 0xF8A307 lands on 0xF8A379), and the four it
      skips are exactly the four whose variant-2 lists are empty.  `--five`.
    * "the last remaining non-wire suspect is 0xF8A2D6 ... cannot be enumerated
      statically" -- it does not need to be.  `--hole0e`.

⚠⚠ A DISAGREEMENT WITH THE OTHER LANE OF THIS ROUND, STATED NOT SMOOTHED
  notes/prom_b_panel_names_round11.py walked the same chain independently in
  this round and reached the SAME variant finding by the same bijection -- and
  it names 26 of the 124 where this lane proposes 117.  The whole of the gap is
  ONE judgement, and the coordinator should decide it rather than average it:

    * IT REFUSES A NAME WHOSE DISTINGUISHING PART IS A POSITION NUMBER.
      `Btn_Quantize_207EZero_LcdKeyRow3` names the third of five key pairs
      beside the LCD; `..._SoftKeyCol5` names the fifth of eight keys under it.
      The sibling lane calls that the shape round 6 refused as
      `Write3602_Index5` -- a number that grades as content while stating
      nothing -- and refuses all 90.  This lane's counter-argument: the number
      in `Write3602_Index5` indexes an ARRAY IN RAM and means nothing outside
      the code, whereas the number here is a PLACE A FINGER GOES on a panel a
      service manual draws, and the routine really is "what QUANTIZE does when
      you press the third key down the right-hand side of the display".  Both
      readings are defensible; only one can be applied.  ==> The 90 are marked
      TIER B and the 27 legend-named ones TIER A, so either can be taken alone.
    * IT REFUSES CODES 0x04-0x07 because under VARIANT 1 those codes come from
      two byte-identical group lists whose producers -- SW25/SW26 (LCD RIGHT)
      and SW33/SW34 (SOFT KEY column 1) -- are BOTH fitted on this panel.  That
      refusal is correct if the WSA1R can run variant 1.  It cannot: see V1/V2/
      V3 above, and the sibling lane says outright that "nothing here reads
      (0xC4)".  This lane read it -- prom_a 0xF82882 sets (0xC4) from PB bit 0
      -- and still cannot MEASURE the strap resistor, so the argument is an
      inference and is labelled one below.
    * IT REFUSES THE TWO PAGE HANDLERS because each also sits at slot 0x19.
      This lane keeps them, on a measurement the sibling did not make: check D7
      shows slot 0x19 CANNOT FIRE.  The clamp `ld (XIX-1),0x19` needs a base
      above 0x0E and the only bases those handlers ever see are 0x00-0x07, so
      the 0x19 registration is dead and PAGE is the handler's only caller.

⚠ THE ONE THING NO ROM CAN SETTLE, said plainly.  (0xC4) is loaded from PB bit
  0 by Variant_SetFromPB0 (prom_a 0xF82882); which way that pin is strapped on
  a given main board is a HARDWARE fact and no image states it.  What V1/V2/V3
  establish is the contrapositive, which is enough: a machine wired to the
  panel the SX-WSA1R service manual draws MUST run variant 2, because variant
  1's tables decode that panel's number pad one key off and put the manual's
  four self-diagnostic chords on the wrong four keys.

RUN
    python3 notes/wave7_panel_names_round11.py            # everything
    python3 notes/wave7_panel_names_round11.py --variant   # V1/V2/V3, both sides
    python3 notes/wave7_panel_names_round11.py --slots     # slot -> control
    python3 notes/wave7_panel_names_round11.py --propose   # the 117 names
    python3 notes/wave7_panel_names_round11.py --refuse    # the 7 refusals
    python3 notes/wave7_panel_names_round11.py --appenders # the seven, read
    python3 notes/wave7_panel_names_round11.py --hole0e    # what is left of it
    python3 notes/wave7_panel_names_round11.py --five      # round 10's five names
    python3 notes/wave7_panel_names_round11.py --selftest  # 93 checks

READ-ONLY.  This script edits nothing.  Applying a wrong map would propagate
into 117 routine headers at once, so the proposal is emitted for a writer lane
to apply with the evidence in hand.
"""
import collections
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)

import wave7_panel_button_codes as L1          # noqa: E402  (layer 1: the wire)
import wave7_panel_event_index as L2           # noqa: E402  (layer 2: the tables)

A_BASE, B_BASE = 0xF80000, 0xF00000
_a = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
_b = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()


def A(p, n=1):
    return _a[p - A_BASE:p - A_BASE + n]


def B(p, n=1):
    return _b[p - B_BASE:p - B_BASE + n]


def bb(p):
    return _b[p - B_BASE]


def le32b(p):
    return int.from_bytes(B(p, 4), "little")


# --- the prom_b objects, addresses read off instructions -------------------
# `ld XIX,0x00f7d2d8` at 0xF7D032 is the first of the 32 `ld XIX` immediates
# the +8 Button stubs load; the stride is the table size, 32 * 4 = 0x80, and
# 0xF7E258 + 0x80 = 0xF7E2D8 is where the run ends and the code span begins.
BTN_LO, BTN_STRIDE, N_TABLES = 0xF7D2D8, 0x80, 32
SPAN_LO, SPAN_HI = 0xF7E2D8, 0xF80000
RET = 0x0E

# --- the seven non-wire appenders, every one an `calr 0xF8A3B2` ------------
APPENDERS = [0xF8A2D6, 0xF8A322, 0xF8A33E, 0xF8A35A, 0xF8A376, 0xF8A392, 0xF8A3AE]
# sub_F8A303's six blocks, in file order: (calr site, group, source byte)
AUX_BLOCKS = [(0xF8A322, 0x10, 0x28EE), (0xF8A33E, 0x11, 0x28EF),
              (0xF8A35A, 0x12, 0x28F0), (0xF8A376, 0x13, 0x28F1),
              (0xF8A392, 0x14, 0x28EC), (0xF8A3AE, 0x15, 0x28ED)]
# the two number-pad value tables, each at the tail of its own action handler
NUMPAD_TABLE = {1: 0xF8ADCD, 2: 0xF8AE57}
NUMPAD_HANDLER = {1: 0xF8ACE8, 2: 0xF8ADDE}
# the two code-rewriting action handlers (variant 1 only)
REWRITERS = {0xF8AE68, 0xF8AEDB}


# ==========================================================================
# 1.  WHICH VARIANT IS THE SX-WSA1R
# ==========================================================================
def variant_positions(v):
    """{(segment, bit)} the variant's own tables can distinguish, from the ROM.

    A wire 0xC0|s is matrix column s.  A list record's MASK names the bits of
    that column the record owns; a single-bit mask names one switch, a
    multi-bit mask names all the switches in it (a whole-field selector still
    reaches every one of them -- the number pad is the proof, and its value
    table has one entry per bit).
    """
    out = set()
    for wire, g in L2.wire_map(v).items():
        if not (0xC0 <= wire <= 0xCF):        # 0xD0.. are the continuous controls
            continue
        seg = wire & 0x0F
        if g > L2.GROUP_MAX:
            continue
        for _cls, _code, _sh, mask in L2.group_list(v, g)[2]:
            for bit in range(8):
                if mask & (1 << bit):
                    out.add((seg, bit))
    return out


def fitted_positions_clean():
    return {((sw - 1) // 8, (sw - 1) % 8) for sw in L1.FITTED_SW}


def numpad_values(v):
    """The variant's number-pad value table, entries 1..12 (bit index 1-based)."""
    t = NUMPAD_TABLE[v]
    return [A(t + i, 1)[0] for i in range(1, 13)]


# ==========================================================================
# 2.  SLOT -> CONTROL, on the SX-WSA1R (variant 2)
# ==========================================================================
CONTROL = {}
for _i in range(8):
    CONTROL[_i] = ("SoftKeyCol%d" % (_i + 1),
                   "the %s of the eight soft keys under the LCD; bit 7 of the "
                   "code picks the LOWER (set) or UPPER (clear) of the column's "
                   "two switches" % ("1st 2nd 3rd 4th 5th 6th 7th 8th".split()[_i]))
for _i in range(5):
    CONTROL[8 + _i] = ("LcdKeyRow%d" % (_i + 1),
                       "row %d of the five key pairs flanking the LCD; bit 7 of "
                       "the code picks the CP2 side (set) or the CP1 side "
                       "(clear)" % (_i + 1))
CONTROL[0x0F] = ("Exit", "the EXIT key")
CONTROL[0x10] = ("Page", "the PAGE pair; bit 7 set = PAGE down, clear = PAGE up")
CONTROL[0x1B] = ("NumberPad", "the twelve-key number pad (0-9, +/-, ENTER)")

REFUSE_SLOT = {
    0x0D: ("code 0x0D never reaches a screen table on a single event: with bit 0 "
           "of (0x2075) CLEAR PanelButton_Route takes the dial arm at 0xF861CC "
           "and never dispatches to the screen, and with it SET PanelButton_Accept "
           "has already substituted (0x209B)/(0x209C) at 0xF8661B, whose every "
           "literal masks to 0x00-0x0C"),
    0x0E: ("no producer: no template record in either variant carries code 0x0E, "
           "the +0x11 rewrite cannot reach it (min base 0x00 -> min 0x11), the "
           "(0x209B)/(0x209C) substitution tops out at 0x0C, and no `ld DE,0x??A9` "
           "immediate exists in any of the four images"),
    0x19: ("unreachable in both variants: 0x19 is the CLAMP arm of 0xF8AE68 / "
           "0xF8AEDB, which fires only when base + 0x11 leaves the 32-bit mask, "
           "i.e. base > 0x0E -- and the only groups those two handlers serve "
           "(variant-1 0x03-0x06) carry bases 0x00-0x07"),
}


# TIER A -- the control is named by a LEGEND printed on the panel, so the name
#           carries no bare number.  The sibling lane notes/prom_b_panel_names_
#           round11.py, working the same chain independently in this round,
#           names this set too.
# TIER B -- the control is named by a POSITION IN A ROW OR COLUMN, so the name
#           ends in a number.  That is the shape round 6 refused
#           (Write3602_Index5) and the sibling lane refuses it here.  This lane
#           proposes it anyway, with the argument stated, and marks it TIER B so
#           the coordinator can take one tier without the other.
TIER = {}
for _s in range(8):
    TIER[_s] = "B"
for _s in range(8, 13):
    TIER[_s] = "B"
TIER[0x0F] = "A"
TIER[0x10] = "A"
TIER[0x1B] = "A"


def held_alias(slot):
    """slot -> the base code it is the variant-1 already-held rewrite of."""
    return slot - 0x11 if 0x11 <= slot <= 0x18 else None


# ==========================================================================
# 3.  THE prom_b BUTTON CENSUS
# ==========================================================================
_c = {}


def screen_names():
    """The 32 ButtonTable_<Screen> labels, in table order, from prom_b's text.

    Order is the file's, and the file emits the 32 tables in address order --
    checked, not assumed: `--selftest` re-reads the `; --- table N of 32`
    banner line above each label and compares N with the label's position.
    """
    if "sn" not in _c:
        src = open(os.path.join(ROOT, "prom_b", "wsa1_prom_b.s"),
                   encoding="utf-8", errors="replace").read()
        labs = re.findall(r"^(ButtonTable_\w+):", src, re.M)
        banners = [int(m) for m in re.findall(r"^; --- table\s+(\d+) of 32:", src, re.M)]
        _c["sn"] = (labs, banners)
    return _c["sn"]


def tables():
    return [BTN_LO + BTN_STRIDE * i for i in range(N_TABLES)]


def census():
    """{handler address: [(screen index, slot), ...]} for the in-span targets."""
    if "cs" not in _c:
        out = collections.defaultdict(list)
        for t_i, t in enumerate(tables()):
            for slot in range(32):
                v = le32b(t + 4 * slot)
                if SPAN_LO <= v < SPAN_HI:
                    out[v].append((t_i, slot))
        _c["cs"] = dict(out)
    return _c["cs"]


def code_handlers():
    """The 124: in-span button targets whose first byte is not a bare `ret`."""
    return sorted(v for v in census() if bb(v) != RET)


def base_slot(slots):
    """The slot a handler is NAMED from: the lowest that is not a 0x11.. alias."""
    low = [s for s in slots if s < 0x11 or s > 0x19]
    return min(low) if low else min(slots)


def proposals():
    """[(addr, name, slots, screen, control, note)] and [(addr, slots, reason)]."""
    labs, _ = screen_names()
    good, bad = [], []
    for v in code_handlers():
        slots = sorted({s for _t, s in census()[v]})
        t_i = census()[v][0][0]
        screen = labs[t_i][len("ButtonTable_"):]
        bs = base_slot(slots)
        if bs in REFUSE_SLOT:
            bad.append((v, slots, screen, REFUSE_SLOT[bs]))
            continue
        if bs not in CONTROL:
            al = held_alias(bs)
            bad.append((v, slots, screen,
                        "registered ONLY at slot 0x%02X, which is the VARIANT-1 "
                        "already-held rewrite of base code 0x%02X -- and that base "
                        "arrives from variant-1 groups 0x03/0x04 or 0x05/0x06, the "
                        "pair that emits BYTE-IDENTICAL lists, so the wire is "
                        "ambiguous even on the machine that can reach it"
                        % (bs, al if al is not None else 0)))
            continue
        ctl, _gloss = CONTROL[bs]
        good.append((v, "Btn_%s_%s" % (screen, ctl), slots, screen, bs, ctl))
    return good, bad


# ==========================================================================
# 4.  THE CHAIN, per slot, rendered
# ==========================================================================
def chain(slot, variant=2):
    """[(wire, seg, bit, SW, legend, grade, delivered code, record addr)]."""
    rows = []
    for wire, g in sorted(L2.wire_map(variant).items()):
        if not (0xC0 <= wire <= 0xCF) or g > L2.GROUP_MAX:
            continue
        p, _q, recs = L2.group_list(variant, g)
        for k, (cls, code, sh, mask) in enumerate(recs):
            # ⚠ codes 0x20 (SetScreen) and 0x21 (Dial) alias onto slots 0x00
            # and 0x01 under `and L,0x1f`, but they never get there:
            # UiEvent_RouteByCode splits them off at 0xF8659F / 0xF865B3
            # BEFORE PanelButton_Accept masks anything.  Button codes only.
            if cls != 0xA9 or code > 0x1F or code != slot:
                continue
            seg = wire & 0x0F
            bits = [b for b in range(8) if mask & (1 << b)]
            for b in bits:
                sw = 8 * seg + b + 1
                legend, grade = L1.PANEL.get((seg, b), ("?", "?"))
                rows.append((wire, g, seg, b, sw, legend, grade,
                             L2.code_byte(code, mask, sh), p + 4 * k))
    return rows


# ==========================================================================
# OUTPUT
# ==========================================================================
def print_variant():
    fit = fitted_positions_clean()
    print("V1  WHICH VARIANT'S TABLES COVER THE MANUAL'S 58 FITTED SWITCHES")
    print("    round 9's diode lists -> %d matrix positions" % len(fit))
    for v in (1, 2):
        got = variant_positions(v)
        extra = sorted(got - fit)
        miss = sorted(fit - got)
        print("    variant %d: %3d positions, %2d NOT fitted here, %2d fitted but "
              "unreachable" % (v, len(got), len(extra), len(miss)))
        if extra:
            print("        not fitted: %s" % ", ".join(
                "SW%d" % (8 * s + b + 1) for s, b in extra))
        if miss:
            print("        unreachable: %s" % ", ".join(
                "SW%d" % (8 * s + b + 1) for s, b in miss))
    print()
    print("V2  THE POWER-ON CHORDS -- round 9's own committed check, quoted")
    print("    notes/wave7_panel_button_codes.py --selftest, d_poweron_chords:")
    print("    two of the three VARIANT-1 chords need switches not fitted here;")
    print("    all three VARIANT-2 chords are fitted.")
    print()
    print("V3  THE NUMBER-PAD VALUE TABLES, entries for bit index 1..12")
    for v in (1, 2):
        vals = numpad_values(v)
        print("    variant %d  table 0x%06X  %s"
              % (v, NUMPAD_TABLE[v], " ".join("%02X" % x for x in vals)))
        print("        segment 1 bits 0..7 -> %s"
              % " ".join(("'%d'" % x) if x <= 9 else "?" for x in vals[:8]))
        print("        segment 2 bits 0..3 -> %s"
              % " ".join(("'%d'" % x) if x <= 9 else
                         ("+/-" if x == 0x80 else ("ENTER" if x == 0x0F else "?"))
                         for x in vals[8:12]))
    print("    round 9's silkscreen reading is SW9=\"0\" .. SW16=\"7\", i.e.")
    print("    segment-1 bit b = key b.  Only variant 2's table does that.")


def print_slots():
    print("SLOT -> CONTROL on the SX-WSA1R (variant 2), and what variant 1 sends")
    print("⚠ THE `v1` ROWS BORROW WSA1R LEGENDS TO NAME A MATRIX POSITION AND")
    print("  NOTHING MORE.  Variant 1 is a DIFFERENT PRODUCT with a different")
    print("  control-panel board; the SWnn numbering and every legend below come")
    print("  from the SX-WSA1R service manual, so a v1 row saying \"EXIT\" means")
    print("  \"the position the WSA1R calls EXIT\", not that the SX-WSA1 prints it")
    print("  there.  The v1 rows are here to show WHY a name must state its")
    print("  variant, not to name anything.")
    for slot in range(32):
        rows2 = chain(slot, 2)
        rows1 = chain(slot, 1)
        if not rows2 and not rows1 and slot not in REFUSE_SLOT:
            continue
        ctl = CONTROL.get(slot, ("(no name proposed)", ""))[0]
        print("  slot %02X  %s" % (slot, ctl))
        for tag, rows in (("v2", rows2), ("v1", rows1)):
            for wire, g, seg, b, sw, legend, grade, deliv, rec in rows:
                fitted = sw in L1.FITTED_SW
                print("      %s wire %02X grp %02X seg %d bit %d  SW%-3d %-8s %-24s "
                      "delivered %02X   record %06X%s"
                      % (tag, wire, g, seg, b, sw, grade, legend, deliv, rec,
                         "" if fitted else "   <- NOT FITTED on the WSA1R"))
        if slot in REFUSE_SLOT:
            print("      REFUSED: %s" % REFUSE_SLOT[slot])
        if held_alias(slot) is not None:
            print("      (also the variant-1 already-held rewrite of code %02X)"
                  % held_alias(slot))


def print_propose():
    good, bad = proposals()
    print("%d PROPOSALS.  Every one is anchored to VARIANT 2 = the SX-WSA1R."
          % len(good))
    print("Apply as the label; put the chain below in the header's Evidence: line.")
    print("⚠ Each header MUST say `variant 2`: the SX-WSA1 (variant 1) routes a")
    print("different -- and, for slots 0x00-0x07, an AMBIGUOUS -- wire to the same")
    print("slot, because its groups 0x03/0x04 and 0x05/0x06 emit identical lists.")
    print()
    by_ctl = collections.Counter(c for *_x, c in good)
    for ctl, n in sorted(by_ctl.items(), key=lambda kv: -kv[1]):
        t = [TIER[bs] for *_x, bs, c in good if c == ctl][0]
        print("   tier %s  %-14s %3d" % (t, ctl, n))
    na = sum(1 for *_x, bs, _c in good if TIER[bs] == "A")
    print("   ---------------------------")
    print("   tier A (legend-named)  %3d" % na)
    print("   tier B (position-named) %3d" % (len(good) - na))
    print()
    for addr, name, slots, screen, bs, ctl in good:
        rows = chain(bs, 2)
        print("  0x%06X  %s   [tier %s]" % (addr, name, TIER[bs]))
        print("      slots %s in ButtonTable_%s"
              % (",".join("0x%02X" % s for s in slots), screen))
        for wire, g, seg, b, sw, legend, grade, deliv, rec in rows:
            print("      chain: SW%d (%s, grade %s) = CP wire 0x%02X bit %d "
                  "-> PanelWireGroupMap_Variant2[0x%02X] = group 0x%02X "
                  "-> record 0x%06X {A9,%02X,..} -> delivered code 0x%02X "
                  "-> `and L,0x1f` 0xF861AE -> slot 0x%02X -> `ld XIX,(XIX+L)` "
                  "0xF8BDF0"
                  % (sw, legend, grade, wire, b,
                     (wire & 0x1F) | ((wire & 0xC0) >> 1), g, rec, bs, deliv, bs))
        extra = [s for s in slots if s != bs]
        if extra:
            print("      also registered at %s -- the VARIANT-1 already-held "
                  "rewrite of the same base code (0xF8AE7E / 0xF8AEF1)"
                  % ",".join("0x%02X" % s for s in extra))


def print_refuse():
    good, bad = proposals()
    print("%d REFUSALS, per routine." % len(bad))
    for addr, slots, screen, why in bad:
        print("  0x%06X  ButtonTable_%s slots %s"
              % (addr, screen, ",".join("0x%02X" % s for s in slots)))
        print("      %s" % why)
    print()
    print("AND THE FOUR SLOTS NO ROUTINE IS PROPOSED FOR AT ALL:")
    print("  0x1A, 0x1C, 0x1D, 0x1F -- no screen table has code there and no")
    print("  template emits them.")
    print("  0x1E -- COMPARE (SW23, LEGEND).  Variant 2 group 0x02 mask 0x40 emits")
    print("  it; NO screen table handles it, so there is nothing here to name.")


def print_appenders():
    print("THE SEVEN NON-WIRE APPENDERS, read.  All seven are `calr 0xF8A3B2`,")
    print("which appends [group][value][change mask] at RAM 0x2000 and bumps")
    print("(0x219A) -- the store is `ld (XIX+HL),E / +1,A / +2,W / +3,0xFF` at")
    print("0xF8A42D-0xF8A442, so E is the GROUP.")
    print()
    print("  SIX OF THEM ARE ONE ROUTINE, sub_F8A303, and it is VARIANT-GATED:")
    print("  `cp (0xC4),0x02 / jr Z,0xF8A379` at 0xF8A303 skips the first FOUR")
    print("  blocks on variant 2, so the SX-WSA1R posts only groups 0x14 and 0x15.")
    print()
    print("  calr site  group  source byte  variant-1 list        variant-2 list")
    for site, g, src in AUX_BLOCKS:
        l1 = L2.group_list(1, g)[2]
        l2 = L2.group_list(2, g)[2]
        f = lambda L: ("class %02X code %02X mask %02X" % (L[0][0], L[0][1], L[0][3])
                       if L else "(empty)")
        print("   0x%06X   0x%02X   (0x%04X)     %-22s %s" % (site, g, src, f(l1), f(l2)))
    print()
    print("  Each block is: `ld A,(src) / bit 7,A / jr Z` (skip if not flagged),")
    print("  `cp (0x219A),0x07 / jr NC` (skip if the queue is full),")
    print("  `and (src),0x7F` (clear the flag), `ld E,<group> / ld W,0x7F`.")
    print("  So bit 7 of the source byte is a CHANGED flag and the low 7 bits are")
    print("  the value -- the same shape as the four pots on wires 0xD0-0xD3.")
    print()
    print("  THE SEVENTH, 0xF8A2D6, takes its group from the counter (0x219C)")
    print("  (`ld E,(0x219C)` at 0xF8A2D2, `inc (0x219C)` at 0xF8A2F7).")
    print()
    print("  ==> NOT ONE OF THE SEVEN CAN PRODUCE A CLASS-0xA9 EVENT: the classes")
    print("  their groups' lists carry are %s."
          % ", ".join("0x%02X" % L2.group_list(1, g)[2][0][0]
                      for _s, g, _x in AUX_BLOCKS))
    print("  Round 10's hypothesis for code 0x0E is ELIMINATED.")


def print_hole0e():
    print("WHAT IS LEFT OF HOLE 2 (nobody produces code 0x0E)")
    print("  A class-0xA9 event reaches PanelButton_Route through exactly two")
    print("  gates, and neither can carry 0x0E:")
    print("  (a) the template tables.  Codes emitted, both variants:")
    codes = sorted({c for v in (1, 2) for g in range(L2.GROUP_MAX + 1)
                    for cls, c, _s, _m in L2.group_list(v, g)[2]
                    if cls == 0xA9 and c <= 0x1F})
    print("      %s  -- 0x0E absent." % " ".join("%02X" % c for c in codes))
    print("  (b) List2030_AppendRegs, whose callers build the class/code pair as")
    print("      one `ld DE,imm16` (PanelButton_PostClass70 does it at 0xF86257,")
    print("      `ld DE,0x0170`).  A class-0xA9 post would be `32 A9 xx`:")
    for nm, d, base in (("prom_a", _a, 0xF80000), ("prom_b", _b, 0xF00000)):
        n = sum(1 for i in range(len(d) - 2) if d[i] == 0x32 and d[i + 1] == 0xA9)
        print("      %s: %d occurrences of `32 A9 xx`" % (nm, n))
    print("  and (0x2082), the byte PanelButton_Route actually reads, has exactly")
    print("  TWO writers in either image -- 0xF8618F (PanelButton_SweepHeld) and")
    print("  0xF86710 (PanelButton_Accept) -- so nothing injects a code sideways.")
    print("  SweepHeld can only re-dispatch a bit already set in (0x2088), and the")
    print("  only setter is 0xF866B3 with PanelButton_BitMask32[code].")
    print()
    print("  ==> On the evidence read here PanelButton_Route's index-0x0E arm, and")
    print("  with it PanelButton_PostClass70, is DEAD on both variants.  That is a")
    print("  stronger claim than round 10's and this lane does NOT assert it as")
    print("  settled: a record could be built byte by byte rather than by an")
    print("  immediate, and this census does not see that.  What IS settled is")
    print("  that the seven appenders are not the producer.")


def print_five():
    print("ROUND 10's FIVE prom_a NAMES -- ★ ALREADY APPLIED by a writer lane in")
    print("this same round.  Re-verified here against the ROM bytes, so the tree")
    print("has the check as well as the name.")
    rows = [
        (0xF8B446, "PanelGroupEventLists_Variant1",
         "`ld XIX,0x00F8B446` at 0xF8A84C", bytes([0x44, 0x46, 0xB4, 0xF8, 0x00]), 0xF8A84C,
         "27 LE32 slots (abutment with 0xF8B4B2); slot g is the head of group g's "
         "list of 4-byte {class, code, shift, mask} records, terminated by 0xFF"),
        (0xF8B4B2, "PanelGroupEventLists_Variant2",
         "`ld XIX,0x00F8B4B2` at 0xF8A857", bytes([0x44, 0xB2, 0xB4, 0xF8, 0x00]), 0xF8A857,
         "27 LE32 slots (abutment with the pool the sibling's slot 0 points at); "
         "same record shape.  ★ THIS is the SX-WSA1R's table"),
        (0xF8B74A, "PanelGroupActionTable_Variant1",
         "`ld XIY,0x00F8B74A` at 0xF8A8CC", bytes([0x45, 0x4A, 0xB7, 0xF8, 0x00]), 0xF8A8CC,
         "25 LE32 slots (abutment with 0xF8B7AE); slot g heads 6-byte "
         "{group, mask, LE32 handler} records terminated by 0xFF.  Only THIS "
         "variant's table reaches the two code-rewriting handlers"),
        (0xF8B7AE, "PanelGroupActionTable_Variant2",
         "`ld XIY,0x00F8B7AE` at 0xF8A8D7", bytes([0x45, 0xAE, 0xB7, 0xF8, 0x00]), 0xF8A8D7,
         "25 LE32 slots; same record shape"),
        (0xF8A824, "PanelGroupQueue_ExpandToEvents",
         "`ld XIY,0x00002000` at 0xF8A824 and `ld XIX,0x00002030` at 0xF8A829",
         bytes([0x45, 0x00, 0x20, 0x00, 0x00]), 0xF8A824,
         "walks the 7-record group queue at 0x2000 and writes 4-byte UI events "
         "into the list at 0x2030, bounded by `cp XIX,0x0000206C` at 0xF8A86D "
         "(15 records)"),
    ]
    src = open(os.path.join(ROOT, "prom_a", "wsa1_prom_a.s")).read()
    for addr, name, cite, want, site, what in rows:
        ok = A(site, len(want)) == want
        applied = re.search(r"^%s:" % name, src, re.M) is not None
        print("  0x%06X  %s   [%s] [%s]"
              % (addr, name, "bytes match" if ok else "BYTES DIFFER",
                 "APPLIED in prom_a" if applied else "NOT APPLIED"))
        print("      %s" % cite)
        print("      %s" % what)
    print()
    print("★ AND ONE DEFECT IN A HEADER THE SAME LANE APPLIED, found by reading")
    print("  the branch rather than the prose.  PanelGroupQueue_AppendFlaggedGroups")
    print("  (0xF8A303) carries the line")
    print("      Variant: `cp (0xC4),0x02` at 0xF8A303 skips the whole routine on")
    print("               one model strap.")
    print("  It does not skip the whole routine.  `jr Z,0x70` at 0xF8A307 targets")
    print("  0xF8A309 + 0x70 = 0xF8A379, which is the FIFTH of the six blocks")
    print("  (`ld A,(0x28EC)`), not the `ret` at 0xF8A3B1.  On variant 2 the")
    print("  routine still posts GROUPS 0x14 and 0x15 and skips only 0x10-0x13 --")
    print("  and that is exactly right, because in the VARIANT-2 event-list table")
    print("  groups 0x10-0x13 have EMPTY lists while 0x14 and 0x15 do not.  The")
    print("  corrected line: `cp (0xC4),0x02` skips the FIRST FOUR blocks on")
    print("  variant 2, leaving groups 0x14 and 0x15 -- the only two that variant")
    print("  has lists for.")
    print()
    print("★ AND ONE CLAIM THE SAME HEADER MAKES WEAKER THAN IT NEEDS TO BE.  It")
    print("  says the seventh appender 0xF8A2D6 `takes its group from (0x219C) at")
    print("  RUN TIME and therefore cannot be enumerated statically`.  It does not")
    print("  need to be: PanelGroupQueue_ExpandToEvents copies [class] and [code]")
    print("  out of the group's TEMPLATE RECORD (`ld WA,(XHL+)` / `ld (XIX+),WA`")
    print("  at 0xF8A867/0xF8A86A), and NO record in either variant's pool is")
    print("  {0xA9, 0x0E}.  Whatever group 0xF8A2D6 queues, it cannot raise code")
    print("  0x0E.  That closes the queue path outright -- see `--hole0e`.")
    print()
    print("  ⚠ ONE SPELLING NOTE, not a defect: 0xF8B446/0xF8B4B2 are TABLES OF")
    print("  LIST HEADS, and the same file spells that shape")
    print("  `UiEventClass_ListTable_A/B/C`.  `PanelGroupEventListTable_VariantN`")
    print("  would be the consistent name.  Not worth a churn on its own.")


# ==========================================================================
# SELFTEST
# ==========================================================================
CHECKS = []


def ck(name, cond, detail=""):
    CHECKS.append((name, bool(cond), detail))


def selftest():
    fit = fitted_positions_clean()
    p2, p1 = variant_positions(2), variant_positions(1)
    # --- A: the variant identification --------------------------------------
    ck("A1 round 9's diode lists give 58 fitted matrix positions", len(fit) == 58,
       str(len(fit)))
    ck("A2 variant 2 covers EXACTLY those 58, none missing", p2 == fit,
       "extra %s missing %s" % (sorted(p2 - fit), sorted(fit - p2)))
    ck("A3 variant 1 reaches positions this panel does not fit", bool(p1 - fit),
       str(len(p1 - fit)))
    ck("A4 and one of them is a whole column beyond the manual's numbering "
       "(SW81-88, wire 0xCA)",
       all((10, b) in p1 for b in range(8)) and 0xCA in L2.wire_map(1))
    ck("A5 variant 2 does not answer to wire 0xC6 at all (SW49-56 unfitted)",
       0xC6 not in L2.wire_map(2))
    ck("A6 variant 2's wire 0xC2 leaves bit 7 (SW24) uncovered",
       (2, 7) not in p2 and 24 not in L1.FITTED_SW)
    # LAST element of the fitted set
    ck("A7 the LAST fitted switch, SW77, is covered by variant 2",
       (9, 4) in p2 and 77 == max(L1.FITTED_SW))
    # --- B: the number-pad tables -------------------------------------------
    v1n, v2n = numpad_values(1), numpad_values(2)
    ck("B1 variant-2 table: segment-1 bit b decodes to DIGIT b",
       v2n[:8] == list(range(8)), repr(v2n[:8]))
    ck("B2 variant-1 table: segment-1 bit b decodes to digit b+1",
       v1n[:8] == list(range(1, 9)), repr(v1n[:8]))
    ck("B3 both tables end the pad with 0x80 then 0x0F (sign, ENTER)",
       v1n[10:12] == [0x80, 0x0F] and v2n[10:12] == [0x80, 0x0F],
       repr((v1n[10:12], v2n[10:12])))
    ck("B4 variant 2's twelfth (LAST) pad entry is 0x0F", v2n[11] == 0x0F)
    ck("B5 the 0x80 arm toggles (0x2820) between '+' (0x2B) and '-' (0x2D)",
       A(0xF8AE1E, 11) == bytes([0x40, 0x20, 0x28, 0x00, 0x00, 0x80, 0x3F, 0x2B,
                                 0x66, 0x05]) + bytes([0xB0]) and
       A(0xF8AE28, 3) == bytes([0xB0, 0x00, 0x2B]) and
       A(0xF8AE2D, 3) == bytes([0xB0, 0x00, 0x2D]),
       A(0xF8AE1E, 18).hex())
    ck("B6 the digit arm stores E + 0x30 -- ASCII (`ld A,E / add A,0x30 / "
       "ld (XBC+0x02),A` at 0xF8AE44)",
       A(0xF8AE44, 8) == bytes([0xCD, 0x89, 0xC9, 0xC8, 0x30, 0xB9, 0x02, 0x41]),
       A(0xF8AE44, 8).hex())
    ck("B7 sub_F8A913 turns a one-bit mask into a 1-BASED bit index "
       "(`xor C,C / inc 1,C / srl 0x01,E / jr NC`)",
       A(0xF8A919, 9) == bytes([0xCB, 0xD3, 0xCB, 0x61, 0xCD, 0xEF, 0x01, 0x6F, 0xF9]),
       A(0xF8A919, 9).hex())
    ck("B8 `add E,0x08` folds segment 2's nibble above segment 1's byte "
       "(variant 2, 0xF8ADF8)",
       A(0xF8ADF8, 3) == bytes([0xCD, 0xC8, 0x08]), A(0xF8ADF8, 3).hex())
    ck("B9 each variant's pad handler reads its OWN table "
       "(`add XDE,imm32` at 0xF8AD75 / 0xF8ADFF)",
       A(0xF8AD75, 6) == bytes([0xEA, 0xC8, 0xCD, 0xAD, 0xF8, 0x00]) and
       A(0xF8ADFF, 6) == bytes([0xEA, 0xC8, 0x57, 0xAE, 0xF8, 0x00]))
    for v in (1, 2):
        t = NUMPAD_TABLE[v]
        ck("B10.%d variant %d's table has exactly ONE reference in prom_a" % (v, v),
           _a.count(t.to_bytes(3, "little")) == 1)
    # --- C: the index rule, and the correction to the round brief ------------
    ck("C1 sub_F8BDC5 indexes the screen table with the RAW code "
       "(`and L,0x1f / sla 0x02,L / ld XIX,(XIX+L) / call (XIX)` at 0xF8BDEA)",
       A(0xF8BDEA, 13) == bytes([0xCF, 0xCC, 0x1F, 0xCF, 0xEC, 0x02,
                                 0xE3, 0x03, 0xF0, 0xEC, 0x24, 0xB4, 0xE8]),
       A(0xF8BDEA, 13).hex())
    ck("C1b the variant branch is `cp (0xC4),0x01 / jr Z` with variant 1 loaded "
       "FIRST and overwritten when the strap is not 1 -- at the wire map "
       "(0xF8A0B3) and at the event-list table (0xF8A851)",
       A(0xF8A0B3, 6) == bytes([0xC0, 0xC4, 0x3F, 0x01, 0x66, 0x05]) and
       A(0xF8A851, 6) == bytes([0xC0, 0xC4, 0x3F, 0x01, 0x66, 0x05]) and
       A(0xF8A0B9, 5) == bytes([0x45, 0x89, 0xA1, 0xF8, 0x00]) and
       A(0xF8A857, 5) == bytes([0x44, 0xB2, 0xB4, 0xF8, 0x00]))
    ck("C2 PanelButton_Route hands the screen L = code & 0x1F, A = bit 7",
       A(0xF861AC, 8) == bytes([0xC8, 0x8F, 0xCF, 0xCC, 0x1F, 0xDB, 0x12, 0xC8]),
       A(0xF861AC, 8).hex())
    ck("C3 sub_F55019's remap is a DIFFERENT consumer: it rejects >0x1F and "
       "subtracts 0x11 / 9 (`cp HL,0x001f` 0xF55026, `cp (0x28B1),0x11` 0xF5505E)",
       B(0xF55026, 4) == bytes([0xDB, 0xCF, 0x1F, 0x00]) and
       B(0xF5505E, 5) == bytes([0xC1, 0xB1, 0x28, 0x3F, 0x11]))
    ck("C4 the 32 prom_b tables are 32 slots of 4 bytes: the stride between two "
       "consecutive `ld XIX` immediates in the Button stubs is 0x80",
       B(0xF7D032, 5) == bytes([0x44, 0xD8, 0xD2, 0xF7, 0x00]) and
       B(0xF7D03E, 5) == bytes([0x44, 0x58, 0xD3, 0xF7, 0x00]) and
       0xF7D358 - 0xF7D2D8 == BTN_STRIDE)
    # --- D: the +0x11 rewrite ------------------------------------------------
    ck("D1 both rewriters do `add (XIX-1),0x11`",
       A(0xF8AE7E, 4) == bytes([0x8C, 0xFF, 0x38, 0x11]) and
       A(0xF8AEF1, 4) == bytes([0x8C, 0xFF, 0x38, 0x11]))
    ck("D2 and shift the mask by the SAME 0x11 -- `sla 0x00,XDE` (= 16, "
       "900tbl.hxx:1011) then `sla 0x01,XDE`",
       A(0xF8AE82, 6) == bytes([0xEA, 0xEC, 0x00, 0xEA, 0xEC, 0x01]) and
       A(0xF8AEF5, 6) == bytes([0xEA, 0xEC, 0x00, 0xEA, 0xEC, 0x01]))
    ck("D3 the clamp writes code 0x19 and mask 0x02000000 = 1 << 0x19",
       A(0xF8AE8A, 4) == bytes([0xBC, 0xFF, 0x00, 0x19]) and
       A(0xF8AE8E, 5) == bytes([0x42, 0x00, 0x00, 0x00, 0x02]) and
       (0x02000000 == 1 << 0x19))
    r1 = {h for g in range(25) for _gg, _m, h in L2.action_list(1, g)[2]}
    r2 = {h for g in range(25) for _gg, _m, h in L2.action_list(2, g)[2]}
    ck("D4 the two rewriters appear in variant 1's action table", REWRITERS <= r1)
    ck("D5 and in variant 2's, NOT AT ALL", not (REWRITERS & r2), str(REWRITERS & r2))
    bases = sorted({c for g in range(25)
                    for (cls, c, _s, m), (_gg, _mm, h)
                    in [(rec, act) for rec in L2.group_list(1, g)[2]
                        for act in L2.action_list(1, g)[2] if act[1] == rec[3]]
                    if cls == 0xA9 and h in REWRITERS})
    ck("D6 the bases the rewriters serve are exactly 0x00-0x07",
       bases == list(range(8)), repr(bases))
    ck("D7 so the reachable rewritten codes are 0x11-0x18, and the clamp 0x19 "
       "can never fire (it needs a base above 0x0E)",
       max(bases) + 0x11 == 0x18 and max(bases) <= 0x0E)
    # --- E: the prom_b census ------------------------------------------------
    labs, banners = screen_names()
    ck("E1 prom_b carries 32 ButtonTable_ labels", len(labs) == 32, str(len(labs)))
    ck("E2 their banners number 0..31 in file order", banners == list(range(32)),
       repr(banners[:5]))
    ck("E3 the LAST is ButtonTable_SequencerMedley",
       labs[-1] == "ButtonTable_SequencerMedley", labs[-1])
    cs = census()
    ck("E4 314 in-span targets, 190 of them a bare `ret`, 124 real code",
       len(cs) == 314 and sum(1 for v in cs if bb(v) == RET) == 190 and
       len(code_handlers()) == 124,
       "%d/%d/%d" % (len(cs), sum(1 for v in cs if bb(v) == RET),
                     len(code_handlers())))
    ck("E5 every one of the 124 is reached from exactly ONE screen",
       all(len({t for t, _s in cs[v]}) == 1 for v in code_handlers()))
    multi = [v for v in code_handlers() if len({s for _t, s in cs[v]}) > 1]
    ck("E6 fifteen are registered at two slots", len(multi) == 15, str(len(multi)))
    ck("E7 and in every one of the fifteen the second slot is base + 0x11",
       all(sorted({s for _t, s in cs[v]})[1] ==
           min(0x19, sorted({s for _t, s in cs[v]})[0] + 0x11) for v in multi),
       repr([sorted({s for _t, s in cs[v]}) for v in multi]))
    ck("E8 slot 0x0F is handled by every one of the 32 tables (no `ret` there)",
       sum(1 for t in tables() if SPAN_LO <= le32b(t + 4 * 0x0F) < SPAN_HI
           and bb(le32b(t + 4 * 0x0F)) == RET) == 0)
    ck("E9 the ONE table with code at slot 0x0E fills all sixteen of 0x00-0x0F",
       len([t for t in tables()
            if SPAN_LO <= le32b(t + 4 * 0x0E) < SPAN_HI
            and bb(le32b(t + 4 * 0x0E)) != RET]) == 1 and
       all(SPAN_LO <= le32b(0xF7D658 + 4 * s) < SPAN_HI and
           bb(le32b(0xF7D658 + 4 * s)) != RET for s in range(16)))
    # --- F: the proposal itself ----------------------------------------------
    good, bad = proposals()
    ck("F1 117 proposals and 7 refusals, 124 in all",
       len(good) == 117 and len(bad) == 7 and len(good) + len(bad) == 124,
       "%d + %d" % (len(good), len(bad)))
    ck("F2 every proposed name is unique",
       len({n for _a, n, *_r in good}) == len(good))
    ck("F3 no proposed name would grade FRAMED (it must not end in _<number>)",
       not any(re.search(r"_(?:[0-9A-Fa-f]{4,6}|[0-9]{1,4})$", n)
               for _a, n, *_r in good))
    ck("F4 every proposal's base slot has a variant-2 chain that reaches a "
       "FITTED switch",
       all(chain(bs, 2) and all(sw in L1.FITTED_SW
                                for *_x, sw, _l, _g, _d, _r in chain(bs, 2))
           for *_y, bs, _c in good))
    ck("F5 the 20 Exit proposals are the slot-0x0F handlers",
       sum(1 for *_x, c in good if c == "Exit") == 20)
    ck("F6 the 5 NumberPad proposals are slot 0x1B, a VARIANT-2-ONLY code",
       sum(1 for *_x, c in good if c == "NumberPad") == 5 and
       not any(c == 0x1B for g in range(25)
               for cls, c, _s, _m in L2.group_list(1, g)[2] if cls == 0xA9) and
       any(c == 0x1B for g in range(25)
           for cls, c, _s, _m in L2.group_list(2, g)[2] if cls == 0xA9))
    ck("F7 the LAST proposal in address order is 0xF7FFFB, and it is a "
       "LcdKeyRow1 on ADVANCE/DELAY",
       good[-1][0] == 0xF7FFFB and good[-1][1] == "Btn_AdvanceDelay_207EZero_LcdKeyRow1",
       "%06X %s" % (good[-1][0], good[-1][1]))
    ck("F8 the five refusals at slot 0x15 only are the variant-1 held forms of "
       "code 0x04", sum(1 for _a, s, _sc, _w in bad if s == [0x15]) == 5)
    ck("F9 and the other two refusals are slots 0x0D and 0x0E",
       sorted(s[0] for _a, s, _sc, _w in bad if s != [0x15]) == [0x0D, 0x0E])
    # --- G: wire 0xC3, the eight-way agreement -------------------------------
    c3 = L2.group_list(2, L2.wire_map(2)[0xC3])[2]
    ck("G1 variant 2's wire 0xC3 has eight records, one per bit", len(c3) == 8)
    ck("G2 bits 0-4 carry codes 0x08-0x0C, one each",
       [r[1] for r in c3[:5]] == [0x08, 0x09, 0x0A, 0x0B, 0x0C], repr(c3[:5]))
    ck("G3 bits 5 and 6 carry ONE code 0x0D, two positions",
       c3[5][1] == 0x0D and c3[6][1] == 0x0D and
       sorted(L2.position(r[3], r[2]) for r in c3[5:7]) == [0, 1])
    ck("G4 bit 7 carries code 0x0F", c3[7][1] == 0x0F and c3[7][3] == 0x80)
    ck("G5 and round 9 reads that column as LCD RIGHT 1..5, -1, +1, EXIT",
       [L1.PANEL[(3, b)][0] for b in range(8)] ==
       ["LCD RIGHT 1 (top)", "LCD RIGHT 2", "LCD RIGHT 3", "LCD RIGHT 4",
        "LCD RIGHT 5 (bottom)", "-1", "+1", "EXIT"])
    ck("G6 PanelButton_Route builds the 0x0D step as `(W & 0x80) | 1`, so bit 7 "
       "is the sign -- and bit 7 is SET for bit 5 = \"-1\"",
       A(0xF861D1, 8) == bytes([0xC8, 0x89, 0xC9, 0xCC, 0x80, 0xC9, 0xCE, 0x01]) and
       L2.code_byte(c3[5][1], c3[5][3], c3[5][2]) == 0x8D)
    ck("G7 PanelButton_Route's 0x0F arm clears bit 7 of (0x2075) on release",
       A(0xF861FB, 5) == bytes([0xC1, 0x75, 0x20, 0x3C, 0x7F]))
    # --- H: the soft keys and the item i / i+8 handlers -----------------------
    c4 = L2.group_list(2, L2.wire_map(2)[0xC4])[2]
    c5 = L2.group_list(2, L2.wire_map(2)[0xC5])[2]
    ck("H1 variant 2's wires 0xC4 and 0xC5 carry codes 0x00-0x03 and 0x04-0x07, "
       "two bits each",
       [r[1] for r in c4] == [0, 0, 1, 1, 2, 2, 3, 3] and
       [r[1] for r in c5] == [4, 4, 5, 5, 6, 6, 7, 7])
    ck("H2 the EVEN bit of each pair delivers bit 7 SET",
       all(L2.code_byte(r[1], r[3], r[2]) & 0x80 for r in c4[0::2] + c5[0::2]))
    ck("H3 round 9 calls those even bits the LOWER soft key",
       all(L1.PANEL[(4, b)][0].endswith("lower") for b in range(0, 8, 2)))
    ck("H4 prom_b's eight item-i/item-i+8 handlers are 0x19 bytes apart, "
       "0xF7ECFF..0xF7EDAE",
       all(le32b(0xF7D458 + 4 * i) == 0xF7ECFF + 0x19 * i for i in range(8)),
       repr([hex(le32b(0xF7D458 + 4 * i)) for i in range(8)]))
    ck("H5 and each of the eight is ALSO registered at its slot + 0x11",
       all(le32b(0xF7D458 + 4 * (i + 0x11)) == 0xF7ECFF + 0x19 * i
           for i in range(8)))
    ck("H6 the LAST of the eight writes 0x07 to (0x3602) when bit 7 is clear",
       B(0xF7ECFF + 7 * 0x19, 3) == bytes([0xC8, 0x33, 0x07]))
    # --- I: the appenders -----------------------------------------------------
    ck("I1 all seven appender sites are `calr` (opcode 0x1E)",
       all(A(s, 1) == b"\x1e" for s in APPENDERS))
    ck("I2 and all seven resolve to 0xF8A3B2",
       all(s + 3 + int.from_bytes(A(s + 1, 2), "little", signed=True) == 0xF8A3B2
           for s in APPENDERS),
       repr([hex(s + 3 + int.from_bytes(A(s + 1, 2), "little", signed=True))
             for s in APPENDERS]))
    ck("I3 sub_F8A303 skips its first four blocks on variant 2 "
       "(`cp (0xC4),0x02 / jr Z,0xF8A379`)",
       A(0xF8A303, 6) == bytes([0xC0, 0xC4, 0x3F, 0x02, 0x66, 0x70]) and
       0xF8A309 + 0x70 == 0xF8A379)
    ck("I4 each of the six blocks loads its own group id into E",
       all(A(s - 4, 2) == bytes([0x25, g]) for s, g, _x in AUX_BLOCKS),
       repr([A(s - 4, 2).hex() for s, _g, _x in AUX_BLOCKS]))
    ck("I5 and its change mask 0x7F into W", all(A(s - 2, 2) == bytes([0x20, 0x7F])
                                                 for s, _g, _x in AUX_BLOCKS))
    ck("I6 NOT ONE of the six groups' lists is class 0xA9, in either variant",
       all(all(r[0] != 0xA9 for r in L2.group_list(v, g)[2])
           for v in (1, 2) for _s, g, _x in AUX_BLOCKS),
       repr([[r[0] for r in L2.group_list(1, g)[2]] for _s, g, _x in AUX_BLOCKS]))
    ck("I7 the LAST of the six (group 0x15, source (0x28ED)) carries class 0xB9",
       L2.group_list(1, 0x15)[2][0][0] == 0xB9)
    ck("I8 the seventh takes its group from (0x219C) (`ld E,(0x219C)` 0xF8A2D2)",
       A(0xF8A2D2, 4) == bytes([0xC1, 0x9C, 0x21, 0x25]))
    ck("I9 sub_F8A3B2 stores E at the record's +0 (`ld (XIX+HL),E` 0xF8A42D)",
       A(0xF8A42D, 5) == bytes([0xF3, 0x07, 0xF0, 0xEC, 0x45]))
    # --- J: hole 2 ------------------------------------------------------------
    codes = sorted({c for v in (1, 2) for g in range(L2.GROUP_MAX + 1)
                    for cls, c, _s, _m in L2.group_list(v, g)[2]
                    if cls == 0xA9 and c <= 0x1F})
    ck("J1 no template in either variant emits code 0x0E", 0x0E not in codes)
    ck("J2 no `ld DE,0x??A9` immediate exists in prom_a or prom_b",
       sum(1 for d in (_a, _b) for i in range(len(d) - 2)
           if d[i] == 0x32 and d[i + 1] == 0xA9) == 0)
    def w2082(d, base):
        return [base + i for i in range(len(d) - 5)
                if d[i] == 0xF1 and d[i + 1] == 0x82 and d[i + 2] == 0x20
                and (d[i + 3] == 0x00 or 0x40 <= d[i + 3] <= 0x47)]
    ck("J3 (0x2082) has exactly two writers, both in the panel path",
       w2082(_a, 0xF80000) == [0xF8618F, 0xF86710] and w2082(_b, 0xF00000) == [],
       repr(w2082(_a, 0xF80000)))
    subs = set()
    src = open(os.path.join(ROOT, "prom_a", "wsa1_prom_a.s")).read() + \
        open(os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")).read()
    for m in re.finditer(r"ld \(0x209([bc])\),0x([0-9a-f]+)", src):
        val = int(m.group(2), 16)
        subs.add(val & 0xFF)
        if val > 0xFF:
            subs.add((val >> 8) & 0xFF)
    ck("J4 every literal ever written to (0x209B)/(0x209C) masks to 0x00-0x0C, "
       "so the code-0x0D substitution cannot make 0x0E",
       subs and max(v & 0x1F for v in subs) == 0x0C,
       repr(sorted(hex(v) for v in subs)))
    # --- K: round 10's five ---------------------------------------------------
    ck("K1 `ld XIX,0x00F8B446` at 0xF8A84C",
       A(0xF8A84C, 5) == bytes([0x44, 0x46, 0xB4, 0xF8, 0x00]))
    ck("K2 `ld XIX,0x00F8B4B2` at 0xF8A857",
       A(0xF8A857, 5) == bytes([0x44, 0xB2, 0xB4, 0xF8, 0x00]))
    ck("K3 `ld XIY,0x00F8B74A` at 0xF8A8CC",
       A(0xF8A8CC, 5) == bytes([0x45, 0x4A, 0xB7, 0xF8, 0x00]))
    ck("K4 `ld XIY,0x00F8B7AE` at 0xF8A8D7",
       A(0xF8A8D7, 5) == bytes([0x45, 0xAE, 0xB7, 0xF8, 0x00]))
    ck("K5 `ld XIY,0x00002000` / `ld XIX,0x00002030` open 0xF8A824",
       A(0xF8A824, 10) == bytes([0x45, 0x00, 0x20, 0x00, 0x00,
                                 0x44, 0x30, 0x20, 0x00, 0x00]))
    # ★ ALL FIVE ARE ALREADY APPLIED -- a writer lane in this same round landed
    # them while this lane was reading.  So the check is on the APPLIED text.
    for n, lbl in enumerate(("PanelGroupEventLists_Variant1",
                             "PanelGroupEventLists_Variant2",
                             "PanelGroupActionTable_Variant1",
                             "PanelGroupActionTable_Variant2",
                             "PanelGroupQueue_ExpandToEvents"), start=6):
        ck("K%d prom_a now carries the label %s" % (n, lbl),
           re.search(r"^%s:" % lbl, src, re.M) is not None)
    ck("K11 and `sub_F8A824` is gone, so 0xF8A824 was renamed rather than "
       "duplicated", re.search(r"^sub_F8A824:", src, re.M) is None)
    # --- L: the defect in the applied header, and the stronger 0x0E closure ---
    ck("L1 the applied PanelGroupQueue_AppendFlaggedGroups header says the "
       "variant test `skips the whole routine`; the branch target is 0xF8A379, "
       "the FIFTH block, not the `ret` at 0xF8A3B1",
       0xF8A309 + A(0xF8A308, 1)[0] == 0xF8A379 and
       A(0xF8A379, 4) == bytes([0xC1, 0xEC, 0x28, 0x21]),
       hex(0xF8A309 + A(0xF8A308, 1)[0]))
    ck("L2 so on variant 2 the routine still posts groups 0x14 and 0x15 -- and "
       "those are exactly the two whose variant-2 lists are non-empty",
       all(L2.group_list(2, g)[2] == [] for g in (0x10, 0x11, 0x12, 0x13)) and
       all(L2.group_list(2, g)[2] != [] for g in (0x14, 0x15)))
    ck("L3 every event ExpandToEvents emits copies [class][code] from a template "
       "record (`ld WA,(XHL+)` / `ld (XIX+),WA` at 0xF8A867/0xF8A86A)",
       A(0xF8A867, 6) == bytes([0xD5, 0xED, 0x20, 0xF5, 0xF1, 0x50]))
    ck("L4 and NO template record in either variant is {0xA9, 0x0E} -- so the "
       "one appender whose group is a run-time value (0xF8A2D6) cannot raise "
       "code 0x0E either, whatever group it queues",
       not any(cls == 0xA9 and code == 0x0E
               for v in (1, 2) for g in range(L2.GROUP_MAX + 1)
               for cls, code, _s, _m in L2.group_list(v, g)[2]))

    # --- M: the tier split, the number this lane reports ---------------------
    na = sum(1 for *_x, bs, _c in good if TIER[bs] == "A")
    ck("M1 tier A (legend-named) is 27 and tier B (position-named) is 90",
       na == 27 and len(good) - na == 90, "%d + %d" % (na, len(good) - na))
    ck("M2 no TIER A name ends in a bare number",
       not any(re.search(r"[0-9]$", n) for _a, n, _s, _sc, bs, _c in good
               if TIER[bs] == "A"))
    ck("M3 every TIER B name does -- that is exactly what is in dispute",
       all(re.search(r"[0-9]$", n) for _a, n, _s, _sc, bs, _c in good
           if TIER[bs] == "B"))
    ck("M4 the 27 tier-A routines are the slot-0x0F, slot-0x10 and slot-0x1B "
       "handlers and nothing else",
       sorted({bs for *_x, bs, _c in good if TIER[bs] == "A"}) == [0x0F, 0x10, 0x1B])

    bad_n = sum(1 for _n, c, _d in CHECKS if not c)
    print("=== SELFTEST (%d checks)" % len(CHECKS))
    for name, c, detail in CHECKS:
        print("  [%s] %s%s" % ("ok" if c else "FAIL", name,
                               "" if c else "   got %s" % detail))
    print("%d/%d passed" % (len(CHECKS) - bad_n, len(CHECKS)))
    return 1 if bad_n else 0


def main():
    a = sys.argv[1:]
    if "--selftest" in a:
        return selftest()
    for flag, fn in (("--variant", print_variant), ("--slots", print_slots),
                     ("--propose", print_propose), ("--refuse", print_refuse),
                     ("--appenders", print_appenders), ("--hole0e", print_hole0e),
                     ("--five", print_five)):
        if flag in a:
            fn()
            return 0
    for fn in (print_variant, print_slots, print_refuse, print_appenders,
               print_hole0e, print_five, print_propose):
        fn()
        print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
