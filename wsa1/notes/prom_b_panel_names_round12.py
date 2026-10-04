#!/usr/bin/env python3
"""APPLY the 117 panel-handler names to prom_b, and apply the 7 refusals too.

QUESTION IT ANSWERS
  Round 11 walked the panel chain end to end and emitted 117 naming proposals
  plus 7 refusals for the 124 sub_XXXXXX button handlers in prom_b
  0xF7E2D8-0xF80000 (notes/wave7_panel_names_round11.py --propose / --refuse).
  It is READ-ONLY and applied nothing.  The coordinator then settled the one
  dispute that blocked 90 of them (notes/wave7-round1/APPLIED.md, "the 90
  position-named panel proposals are ACCEPTED").  THIS script is the writer:
  it puts the names, the whole chain and the refusals into
  prom_b/wsa1_prom_b.s, and it audits the prose it leaves behind.

  ==> 92 routines renamed from sub_XXXXXX to a control name, each with the
      chain SW -> wire -> group -> record -> code -> `and L,0x1f` -> slot ->
      handler written into its header.
  ==> 25 were already named in round 11 (20 ExitKey_*, 5 NumberPadKey_*); this
      pass CONFIRMS them and leaves them untouched, which is what makes it
      idempotent.
  ==> 7 refusals applied: 6 headers rewritten to state the gap in VARIANT-2
      terms, and 1 name REMOVED -- see "THE DEMOTION" below.
  ==> 12 MORE, on the OTHER table family, where the same control vocabulary is
      legitimate under that family's OWN index rule -- see "THE SECOND FAMILY".

★ THE SECOND FAMILY, and what it reaches -- `--family2`
  The 32-entry tables above are indexed by the RAW code; prom_b also has FOUR
  23-entry tables indexed by the slot prom_b PanelCode_ToSlotAndFlags (0xF55019)
  returns.  ⚠ TWO TABLE FAMILIES, TWO INDEX RULES, and they are read here with
  their own rules, not welded: the remap is the IDENTITY below 0x11 (`cp
  (0x28B1),0x11 / jr C` at 0xF5505E skips the -0x11 arm, `cp (0x28B1),0x1a / jr
  C` at 0xF5507A skips the -9 arm, leaving HL as loaded at 0xF55023), which is
  WHY the same control vocabulary applies to slots 0x00-0x10 there.  Round 11
  reached the same conclusion from the consumer side alone and named slot 15
  ExitKey_DrawbarScreen and slot 16 PageKey_DrawbarScreen; those two are the
  independent corroboration and this pass leaves them untouched.
  The measurement, buckets disjoint and summing to the 36 distinct targets:
      2 already named
     12 NAMED HERE -- table 0xF54248, the DRAWBAR screen
     19 REFUSED, screen unknown: tables 0xF135FD / 0xF1394F / 0xF4C38D are read
        by ScreenButtonBody_DspEffect / ScreenButtonBody_MainOutEqualizer / ScreenButton_CreatorSelectController, whose own headers say "Unknown:
        what the routine is FOR", and NO vtable slot in any of the four images
        points at their thunks (T_F42F50, T_F42F6C, T_F434E8). A control name
        with no screen would be <Control>_<address> -- FRAMED, not
        understanding, and the round-3 lesson is that converting without naming
        makes the tree WORSE on the goal metric.
        ⚠ CORRECTED 2026-10-03 (notes/prom_ab_screen_vtable_methods.py): the third
        reader, then sub_F4C4B5, IS a screen's BUTTON method.  PanelScreen_VtableTable
        points at a thunk TRIPLE's first slot, never at its +8 slot, so a search for
        a vtable word equal to T_F434E8 could only come back empty: ViewB entry 0xAD
        points at T_F434E0, whose +8 slot is T_F434E8.  It is ScreenButton_CreatorSelectController now,
        so table 0xF4C38D belongs to screen 0xAD.  The other two readers' triples
        (T_F42F48 / T_F42F64) are pointed at by no vtable word, so their refusal stands.
      3 REFUSED, no label at that address at all (mid-routine entries); one of
        them, 0xF4C4DD, additionally sits in SIX control slots at once, so even
        with a label the slot would not distinguish it.
  ==> reaches 34 unnamed routines, names 12, declines 22 and says why.

★ SPELLING: THIS PASS USES `<Control>_<Screen>`, NOT ROUND 11'S `Btn_<Screen>_<Control>`
  Round 11 proposed `Btn_TrackAssign_StageZero_SoftKeyCol4`.  Round 11's OTHER
  lane had already committed 25 of the same family as `ExitKey_TrackAssign_
  StageZero` and `NumberPadKey_Quantize_StageZero`, control first.  Adopting
  `Btn_` for the other 92 would have meant either two spellings in one span or
  renaming 25 correct labels -- and that rename would have falsified sixteen
  committed prose lines that read "exactly as the twenty named ExitKey_*
  routines do" (prom_b :116482 and fifteen more), and would have had to leave
  ExitKey_DrawbarScreen alone because it belongs to the OTHER table family.
  So the mapping applied here is Btn_<Screen>_<Control> -> <Control>_<Screen>,
  it is a bijection (`--plan` proves it: 117 proposals, 117 distinct names),
  and every morpheme the coordinator accepted -- SoftKeyCol1..8, LcdKeyRow1..5,
  Exit, NumberPad, Page -- survives intact.

⚠⚠ A CORRECTION THIS LANE OWES THE COORDINATOR DECISION
  APPLIED.md justifies tier B with: 'the service manual's own legends for those
  switches are, verbatim: "LCD RIGHT 1 (top)" ... "SOFT KEY col 1 lower"' and
  '★ The number is printed on the instrument.'  THOSE TWO STRINGS ARE NOT
  PRINTED ON ANYTHING.  They are the legend column of notes/wave7_panel_button_
  codes.py's PANEL table, and that table carries a GRADE per row which says so
  outright: SW33 "SOFT KEY col 1 lower" is graded POSITION, whose definition in
  that script is "no printed legend; identity is the silkscreen POSITION matched
  against the panel drawing"; SW25 "LCD RIGHT 1 (top)" is graded LOCKED, which
  means the ROM confirms the switch's FUNCTION -- also not a printed legend.
  `--grades` prints the grade of every switch these 92 names rest on: 0 of them
  is graded LEGEND except the two PAGE keys.
  ★ THE DECISION SURVIVES, on its own second sentence rather than its first.
  The test the coordinator states is "whether the number has a REFERENT OUTSIDE
  THE CODE", and it does: page I-4/I-5 draws a ROW OF EIGHT soft keys under the
  display and a COLUMN OF FIVE keys down each side of it, so "the 4th soft key"
  and "the 3rd LCD key" are places a finger goes on a panel a person can point
  at, printed word or no printed word.  What changes is what the Evidence lines
  are allowed to SAY, and every one of the 92 written here says POSITION ON THE
  PANEL DRAWING, cites the grade, and never claims a printed legend.
  ⚠ If a future round finds the silkscreen does print "SOFT KEY 4", that upgrades
  these names; it does not currently.

★ THE DEMOTION: MinusPlusKey_TrackAssignPresets -> sub_F7E750
  Round 11's other lane named 0xF7E750 for the -1/+1 keys, on the ground that
  code 0x0D's only fitted producers are SW30/SW31.  That is true of the CODE and
  false of the SLOT, and this pass removes the name.  Re-derived here (`--0x0d`):
    * a single press cannot deliver 0x0D to a screen table.  prom_a
      PanelButton_Route tests `bit 0,(0x2075)` at 0xF861C6 and, when it is
      CLEAR, takes the dial arm at 0xF861CC-0xF861E4 and RETURNS without ever
      reaching the screen dispatch at 0xF86205.  When it is SET, prom_a
      PanelButton_Accept has already replaced the code: `cp C,0x0d` /
      `bit 0,(0x2075)` / `ld C,(0x209c)` or `ld C,(0x209b)` / `ld (0x20b8),C`
      at 0xF86610-0xF86629, and (0x2082) -- the byte PanelButton_Route routes --
      is loaded FROM (0x20b8) at 0xF86704-0xF86710.
    * every literal any image stores to (0x209B)/(0x209C) masks to 0x00-0x0C.
      There are 42 such stores and `--0x0d` decodes all of them.
  ⚠ AND A HOLE ROUND 11's REFUSAL TEXT DOES NOT MENTION, found here: there is a
    SECOND producer path.  prom_a PanelButton_SweepHeld (0xF8615C) walks bits
    0..31 of (0x2088) and routes each one, and bit 0x0D of (0x2088) IS set by
    PanelButton_Accept (`or (0x2088),XWA` at 0xF866B3) whenever 0x0D was accepted
    with bit 0 of (0x2075) clear.  So slot 0x0D would fire if bit 0 of (0x2075)
    were CLEAR at accept time and SET when the repeat sweep routed it -- and
    screens do set it, `or (0x2075),0x09` occurs 15 times in prom_b.  NOBODY HAS
    SHOWN THAT SEQUENCE HAPPENING.  The refusal stands and its reason is now the
    honest one: not "unreachable", but "reachable only through a transition no
    site has been shown to produce".

WHAT IS NOT TOUCHED
  The 25 already-named routines, every label outside 0xF7E2D8-0xF80000, and
  every byte of every ROM.  ExitKey_DrawbarScreen (0xF53683) is a DIFFERENT
  table family (the 23-entry one, indexed through sub_F55019's remap) and is
  deliberately left alone; `--audit` has a check that it still exists.

RUN
    python3 notes/prom_b_panel_names_round12.py --plan      # the 117 + the 7, no edit
    python3 notes/prom_b_panel_names_round12.py --grades    # the provenance grades
    python3 notes/prom_b_panel_names_round12.py --0x0d      # why the demotion
    python3 notes/prom_b_panel_names_round12.py --apply     # edit prom_b/wsa1_prom_b.s
    python3 notes/prom_b_panel_names_round12.py --family2   # the OTHER table family
    python3 notes/prom_b_panel_names_round12.py --cites     # citations, AT the address
    python3 notes/prom_b_panel_names_round12.py --audit     # the prose detectors
    python3 notes/prom_b_panel_names_round12.py --audit --prove
                                                # each detector fired on a planted fault
    python3 notes/prom_b_panel_names_round12.py --selftest  # checks, incl. the LAST element

AFTER --apply THE GATE MUST BE RUN:  python3 scripts/analysis/assert_byte_identical.py
"""
import os
import re
import sys
import textwrap

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path, write_part  # noqa: E402
sys.path.insert(0, HERE)

import wave7_panel_button_codes as L1        # noqa: E402
import wave7_panel_names_round11 as R11      # noqa: E402
from prom_b_names_session_53b889a2 import RENAMES as _S53  # noqa: E402  2026-10-03 renames
LATER = dict(_S53)   # a refusal a later pass renamed <Screen>_Button<k> (header still NOT NAMED)

# ⚠ A WRITE THROUGH THIS NAME IS GUARDED AND WILL REFUSE while the text
# it is handed is the whole image: write_part() sees the master's
# .include lines disappear.  That refusal is correct and is not the fix.
# The fix for a RENAME is asm_source.edit_image(ROOT, <primary>, fn),
# which applies the transform to every constituent file; for a SPLICE it
# is asm_source.locate() on the block's anchor.  See notes/asm_source.py.
SRC_MASTER = os.path.join(ROOT, "prom_b/wsa1_prom_b.s")   # the WRITE path: write_part() guards it
SRC = image_path(ROOT, "prom_b/wsa1_prom_b.s")  # the READ path: the image, not the master
RULE = "; " + "-" * 69
SPAN_LO, SPAN_HI = 0xF7E2D8, 0xF80000

# ---------------------------------------------------------------------------
# 1.  THE NAME MAP.  Btn_<Screen>_<Control>  ->  <Control>_<Screen>
#     The control morphemes are the coordinator's, unchanged; only the order
#     and the "Key" suffix on the two word-named controls differ, so that the
#     92 written here read as one family with the 25 round 11 already applied.
# ---------------------------------------------------------------------------
CONTROL_SPELLING = {"Exit": "ExitKey", "NumberPad": "NumberPadKey", "Page": "PageKey"}


def spell(control):
    return CONTROL_SPELLING.get(control, control)


def name_of(screen, control):
    return "%s_%s" % (spell(control), screen)


def targets():
    """[(addr, label, screen, control, base slot, all slots)] for the 117."""
    out = []
    for addr, _btn, slots, screen, bs, ctl in R11.proposals()[0]:
        out.append((addr, name_of(screen, ctl), screen, ctl, bs, slots))
    return out


def refusals():
    """[(addr, screen, slots, gap prose)] for the 7 -- reasons restated for variant 2."""
    out = []
    for addr, slots, screen, _reason in R11.proposals()[1]:
        out.append((addr, screen, slots, GAP[min(slots) if min(slots) < 0x11 else 0x15]))
    return out


# ---------------------------------------------------------------------------
# 2.  THE PROSE.  One generator per control family, so a wording fix lands in
#     all 92 at once and cannot drift between siblings.
# ---------------------------------------------------------------------------
ORD = "1st 2nd 3rd 4th 5th 6th 7th 8th".split()

GLOSS = {}
for _i in range(8):
    GLOSS["SoftKeyCol%d" % (_i + 1)] = (
        "the %s of the eight SOFT KEYS in the row under the LCD" % ORD[_i])
for _i in range(5):
    GLOSS["LcdKeyRow%d" % (_i + 1)] = (
        "row %d of the five key pairs flanking the LCD" % (_i + 1))
GLOSS["Exit"] = "the EXIT key"
GLOSS["NumberPad"] = "the twelve-key NUMBER PAD (0-9, +/-, ENTER)"
GLOSS["Page"] = "the PAGE ^ / PAGE v pair"

BIT7 = {
    "soft": ("bit 7 of the delivered code picks WHICH SWITCH OF THE COLUMN: set "
             "= the even matrix bit, clear = the odd one. ⚠ That the even bit "
             "is the LOWER key of the pair is round 9's POSITION-grade reading of "
             "the silkscreen, corroborated by the item i / item i+8 shape of the "
             "eight TRACK CLEAR handlers at 0xF7ECFF-0xF7EDC6 and proved by "
             "nothing."),
    "lcd": ("bit 7 of the delivered code picks THE SIDE OF THE DISPLAY: set = the "
            "CP2 column (SW73-77), clear = the CP1 column (SW25-29)."),
    "page": ("bit 7 of the delivered code picks the DIRECTION: set = SW21 PAGE v, "
             "clear = SW22 PAGE ^."),
    "pad": ("all twelve pad keys deliver the SAME code 0x1B; which key was pressed "
            "is carried in the panel's own segment shadow and decoded by prom_a's "
            "variant-2 value table at 0xF8AE57, not by this slot."),
}

EVIDENCE = {
    "soft": ("the number in this name has a REFERENT OUTSIDE THE CODE: service "
             "manual page I-4/I-5 draws a ROW OF EIGHT soft keys under the "
             "display; %s are the two switches of its %s column, matched to the CP1 "
             "silkscreen (page II-27/28) by position. ⚠ GRADE POSITION in "
             "notes/wave7_panel_button_codes.py --physical -- the manual prints "
             "NO legend beside %s, so \"col %d\" is a counted place on the panel "
             "and not a printed word."),
    "lcd_locked": ("the number in this name has a REFERENT OUTSIDE THE CODE and a "
                   "ROM anchor: page I-4/I-5 draws a COLUMN OF FIVE keys down "
                   "each side of the display, and rows 1-4 are graded LOCKED in "
                   "notes/wave7_panel_button_codes.py --physical because prom_a "
                   "sub_F954AA masks segment 3 with 0x0F and dispatches bits 0..3 "
                   "four separate ways -- the four boxes page I-12 annotates "
                   "(1)..(4) MAIN OUT / SUB OUT 1 / SUB OUT 2 / SUB OUT 3 for the "
                   "Generator IC Outsel check. %s is row %d of that column."),
    "lcd_position": ("the number in this name has a REFERENT OUTSIDE THE CODE: "
                     "page I-4/I-5 draws a COLUMN OF FIVE keys down each side of "
                     "the display and %s is the bottom one. ⚠ GRADE POSITION "
                     "in notes/wave7_panel_button_codes.py --physical -- row 5 is "
                     "the one row of the column the Outsel check does NOT "
                     "annotate, so unlike rows 1-4 it rests on the silkscreen "
                     "position alone."),
    "page": ("GRADE LEGEND in notes/wave7_panel_button_codes.py --physical: the "
             "manual PRINTS \"PAGE\" beside SW21/SW22 on the CP1 silkscreen (page "
             "II-27/28), so this name borrows a word from the instrument."),
    "pad": ("GRADE LEGEND/LOCKED in notes/wave7_panel_button_codes.py --physical: "
            "the silkscreen prints SW9=\"0\" .. SW20=\"ENTER\", and prom_a "
            "sub_F953CD turns segment-1 bits 2,3,4,5 into the four self-diagnostic "
            "screens manual page I-11 assigns to keys \"2\",\"3\",\"4\",\"5\" -- "
            "four keys, four bits, in order."),
    "exit": ("GRADE POSITION in notes/wave7_panel_button_codes.py --physical, with "
             "a consumer-side anchor: slot 0x0F is the ONLY one of the 32 slots "
             "that holds a real routine in ALL 32 screen tables."),
}

GAP = {
    0x0D: ("NO NAME. Slot 0x0D cannot be reached by a single press: prom_a "
           "PanelButton_Route tests `bit 0,(0x2075)` at 0xF861C6 and, when it is "
           "CLEAR, takes the dial arm at 0xF861CC and returns without reaching the "
           "screen dispatch at 0xF86205; when it is SET, prom_a PanelButton_Accept "
           "has already substituted the code from (0x209B)/(0x209C) at "
           "0xF86610-0xF86629, and every literal any image stores there masks to "
           "0x00-0x0C. ⚠ THE REMAINING PATH, which round 11's refusal text "
           "does not mention: prom_a PanelButton_SweepHeld (0xF8615C) routes every "
           "bit set in (0x2088), and bit 0x0D of (0x2088) IS set by "
           "PanelButton_Accept (`or (0x2088),XWA` at 0xF866B3) when 0x0D is "
           "accepted with bit 0 of (0x2075) clear. So this routine runs if that bit "
           "is clear at accept time and set at repeat time. NO SITE HAS BEEN SHOWN "
           "TO PRODUCE THAT TRANSITION, so the -1/+1 keys are NOT claimed as this "
           "routine's caller -- the name MinusPlusKey_TrackAssignPresets, applied "
           "in round 11, is withdrawn here."),
    0x0E: ("NO NAME, for want of a PRODUCER. No template record in either "
           "variant's group lists carries code 0x0E, the variant-1 +0x11 rewrite "
           "cannot reach it (its minimum base 0x00 gives 0x11), the "
           "(0x209B)/(0x209C) substitution tops out at 0x0C, and no `ld DE,0x??A9` "
           "immediate exists in any of the four images. prom_a PanelButton_Route "
           "does have an 0x0E arm (0xF861BC), but it fires only with bit 5 of "
           "(0x2075) CLEAR and it never reaches a screen table. This is the only "
           "slot-0x0E entry in all 1,024 that is not a bare `ret`, and both of its "
           "branches fall into the same `ret`."),
    0x15: ("NO NAME. This routine is registered ONLY at slot 0x%02X, which is the "
           "VARIANT-1 already-held rewrite of base code 0x%02X (`add (XIX-1),0x11` "
           "at prom_a 0xF8AE7E/0xF8AEF1). The SX-WSA1R is VARIANT 2 "
           "(notes/wave7_panel_names_round11.py --variant), and the two rewriting "
           "action handlers are variant-1 handlers, so ON THIS MACHINE THE SLOT IS "
           "NEVER DELIVERED and the routine is unreachable. On the SX-WSA1, where "
           "it can fire, its base 0x04 is the code variant 1 produces from TWO "
           "byte-identical group lists -- SW25/SW26 (LCD RIGHT) and SW33/SW34 "
           "(SOFT KEY col 1), both fitted -- so even there the wire is ambiguous."),
}


def _screen_phrase(screen):
    """"...on the X screen" reads badly when X already ends in "Screen"."""
    return screen if screen.endswith("Screen") else screen + " screen"


def family(control):
    if control.startswith("SoftKeyCol"):
        return "soft"
    if control.startswith("LcdKeyRow"):
        return "lcd"
    return {"Exit": "exit", "NumberPad": "pad", "Page": "page"}[control]


def wrap(tag, body, first_prefix=None):
    """House style: `; Tag:      text`, continuations `;` + 11 spaces."""
    head = first_prefix if first_prefix is not None else "; %-9s " % (tag + ":")
    cont = "; " + " " * 10
    out = textwrap.wrap(body, width=78, initial_indent=head, subsequent_indent=cont,
                        break_long_words=False, break_on_hyphens=False)
    return out


def chain_sentence(bs, screen):
    """The whole chain for one slot, as one sentence, re-read from the ROM."""
    parts = []
    for wire, grp, seg, bit, sw, legend, grade, code, rec in R11.chain(bs, 2):
        parts.append('SW%d "%s" (matrix segment %d bit %d, wire 0x%02X) -> '
                     'PanelWireGroupMap_Variant2[0x%02X] = group 0x%02X -> record '
                     '0x%06X {class 0xA9, code 0x%02X} -> delivered code 0x%02X'
                     % (sw, legend, seg, bit, wire, (wire & 0x1F) | ((wire & 0xC0) >> 1),
                        grp, rec, bs, code))
    tail = ('. prom_a PanelButton_Route then does `and L,0x1f` at 0xF861AE and prom_a '
            'sub_F8BDC5 masks it AGAIN and indexes the table -- `and L,0x1f / sla 0x02,L / '
            'ld XIX,(XIX+L) / call (XIX)` at 0xF8BDEA-0xF8BDF5 -- '
            'so this is slot 0x%02X of ButtonTable_%s.' % (bs, screen))
    return "; ".join(parts) + tail


def variant1_sentence(bs):
    rows = R11.chain(bs, 1)
    if not rows:
        return ("no variant-1 record carries this code at all, so on the SX-WSA1 the "
                "slot is dead.")
    bits = []
    for _wire, _grp, seg, bit, sw, legend, _grade, _code, _rec in rows:
        fit = "fitted" if sw in L1.FITTED_SW else "NOT fitted on this panel"
        bits.append("SW%d %s (segment %d bit %d, %s)"
                    % (sw, legend if legend != "?" else "[no legend: matrix position "
                       "outside every diode list]", seg, bit, fit))
    return ("the SX-WSA1 (variant 1) feeds the same slot from " + "; ".join(bits) +
            ". The model strap is the RAM byte (0x00C4), latched from PB bit 0 by prom_a "
            "Variant_SetFromPB0 at 0xF82882; variant 2 is the SX-WSA1R "
            "(notes/wave7_panel_names_round11.py --variant, three independent "
            "measurements).")


def held_sentence(slots, bs):
    extra = [s for s in slots if 0x11 <= s <= 0x19]
    if not extra:
        return None
    if extra == [0x19]:
        return ("Also registered at slot 0x19, which is the CLAMP arm of the "
                "variant-1 rewriters 0xF8AE68/0xF8AEDB and fires only for a base "
                "above 0x0E; the only bases those two handlers ever see are "
                "0x00-0x07, so the 0x19 registration is dead in BOTH variants and "
                "this control is the routine's only caller.")
    return ("Also registered at slot 0x%02X, the VARIANT-1 already-held rewrite of "
            "base code 0x%02X (`add (XIX-1),0x11` at prom_a 0xF8AE7E/0xF8AEF1), so "
            "on the SX-WSA1 one routine serves the press and the auto-repeat; on "
            "the SX-WSA1R that slot is never delivered."
            % (extra[0], bs))


def evidence_sentence(control, bs):
    fam = family(control)
    rows = R11.chain(bs, 2)
    if fam == "soft":
        n = int(control[len("SoftKeyCol"):])
        sws = "/".join("SW%d" % r[4] for r in rows)
        body = EVIDENCE["soft"] % (sws, ORD[n - 1], "SW%d" % rows[0][4], n)
    elif fam == "lcd":
        n = int(control[len("LcdKeyRow"):])
        if n <= 4:
            body = EVIDENCE["lcd_locked"] % ("SW%d" % rows[0][4], n)
        else:
            body = EVIDENCE["lcd_position"] % ("SW%d" % rows[0][4])
    else:
        body = EVIDENCE[fam]
    return (body + " The wire->group->record->code->slot chain above is re-derived "
            "from the ROM bytes by notes/prom_b_panel_names_round12.py --plan, which "
            "reads notes/wave7_panel_button_codes.py (layer 1) and "
            "notes/wave7_panel_event_index.py (layer 2).")


def header_for(name, screen, control, bs, slots):
    fam = family(control)
    out = [RULE]
    out += wrap(None, "%s -- %s, on the %s" % (name, GLOSS[control],
                                               _screen_phrase(screen)),
                first_prefix="; ")
    out += wrap("Reached by", chain_sentence(bs, screen))
    note = BIT7[{"soft": "soft", "lcd": "lcd", "page": "page", "pad": "pad",
                 "exit": "lcd"}[fam]] if fam != "exit" else None
    if note:
        out += wrap("Note", note)
    hs = held_sentence(slots, bs)
    if hs:
        out += wrap("Note", hs)
    out += wrap("Variant", "⚠ VARIANT 2 = the SX-WSA1R, and the chain above is "
                           "variant 2's; " + variant1_sentence(bs))
    out += wrap("Evidence", evidence_sentence(control, bs))
    out.append(RULE)
    return out


def refusal_header_for(addr, screen, slots, gap):
    bs = min(s for s in slots)
    if bs >= 0x11:
        gap = gap % (bs, bs - 0x11)
    out = [RULE]
    out += wrap(None, "%s -- panel button slot %s of %s, NOT NAMED"
                % (LATER.get("sub_%06X" % addr, "sub_%06X" % addr),
                   ", ".join("0x%02X" % s for s in slots), screen),
                first_prefix="; ")
    out += wrap("Unknown", gap)
    out += wrap("Evidence", "the table slot and the screen are re-read from the ROM, "
                            "and the reachability argument above is reproduced by "
                            "notes/prom_b_panel_names_round12.py --0x0d (slot 0x0D) "
                            "and --plan (the rest).")
    out.append(RULE)
    return out


# ---------------------------------------------------------------------------
# 2b. THE SECOND TABLE FAMILY -- measured, and applied only where the SCREEN
#     is known.  ⚠ TWO TABLE FAMILIES, TWO INDEX RULES: the 32-entry tables
#     above are indexed by the RAW code (prom_a sub_F8BDC5 `and L,0x1f`), and
#     these four 23-entry tables by the REMAPPED slot that prom_b
#     PanelCode_ToSlotAndFlags (0xF55019) returns.  They are not welded here;
#     each is read with its own rule, and the rules AGREE below 0x11 because
#     the remap is the identity there -- `cp (0x28B1),0x11 / jr C` at 0xF5505E
#     skips the -0x11 arm and `cp (0x28B1),0x1a / jr C` at 0xF5507A skips the
#     -9 arm, leaving HL exactly as loaded at 0xF55023.  `--family2` prints the
#     measurement and the refusal.
# ---------------------------------------------------------------------------
FAMILY2 = {0xF135FD: None, 0xF1394F: None,
           # 2026-10-03: its reader is ScreenButton_CreatorSelectController (see the correction above).
           # 2026-10-04: screen 0xAD was named CREATOR SELECT CONTROLLER from its title list, so its handlers are
           # <Control>_CreatorSelectController now, not <Control>_ScreenCodeAD.
           0xF4C38D: "CreatorSelectController",
           0xF54248: "DrawbarScreen"}
FAMILY2_READER = {0xF135FD: ("ScreenButtonBody_DspEffect", 0xF0F194), 0xF1394F: ("ScreenButtonBody_MainOutEqualizer", 0xF12347),
                  0xF4C38D: ("ScreenButton_CreatorSelectController", 0xF4C4C8),
                  0xF54248: ("DrawbarScreen_Dispatch", 0xF5303D)}
DEFAULT_THUNK = 0xF42C70
SLOT_CONTROL = {}
for _i in range(8):
    SLOT_CONTROL[_i] = "SoftKeyCol%d" % (_i + 1)
for _i in range(5):
    SLOT_CONTROL[8 + _i] = "LcdKeyRow%d" % (_i + 1)
SLOT_CONTROL[0x0F] = "Exit"
SLOT_CONTROL[0x10] = "Page"
SLOT_CONTROL[0x12] = "NumberPad"     # raw code 0x1B, minus the 9 the remap takes


def _lb32(p):
    return int.from_bytes(R11.B(p, 4), "little")


def family2_scan():
    """[(table, slot, target)] for every non-default entry in a control slot."""
    out = []
    for t in sorted(FAMILY2):
        for s in range(23):
            v = _lb32(t + 4 * s)
            if v != DEFAULT_THUNK and s in SLOT_CONTROL:
                out.append((t, s, v))
    return out


def family2_targets():
    """The subset this pass NAMES: known screen, currently sub_XXXXXX, one slot."""
    idx = label_index(read_lines())
    seen = {}
    for t, s, v in family2_scan():
        seen.setdefault(v, []).append((t, s))
    out = []
    for t, s, v in family2_scan():
        if FAMILY2[t] is None or len(seen[v]) != 1:
            continue
        if not idx.get(v, (0, ""))[1]:
            continue                     # no label at that address at all
        out.append((v, name_of(FAMILY2[t], SLOT_CONTROL[s]), FAMILY2[t],
                    SLOT_CONTROL[s], s, [s], t))
    return sorted(out)


def family2_header(name, screen, control, slot, table):
    rdr, site = FAMILY2_READER[table]
    out = [RULE]
    out += wrap(None, "%s -- %s, on the %s" % (name, GLOSS[control], _screen_phrase(screen)),
                first_prefix="; ")
    out += wrap("Reached by", chain_sentence(slot, screen).split(". prom_a "
                                                                "PanelButton_Route")[0] +
                ". prom_a PanelButton_Route masks the code `and L,0x1f` at 0xF861AE as "
                "always, but THIS screen is dispatched by the OTHER family: %s calls "
                "PanelCode_ToSlotAndFlags (prom_b 0xF55019) through thunk T_F42C74 and "
                "then `mul A,0x04 / add XWA,0x00%06x` at 0x%06X, so the index is the "
                "REMAPPED SLOT and this is slot %d of the 23."
                % (rdr, table, site, slot))
    out += wrap("Note", "⚠ TWO TABLE FAMILIES, TWO INDEX RULES, and this is the "
                        "23-entry one. The remap is the IDENTITY below 0x11: `cp "
                        "(0x28B1),0x11 / jr C` at 0xF5505E skips the -0x11 arm and `cp "
                        "(0x28B1),0x1a / jr C` at 0xF5507A skips the -9 arm, leaving HL "
                        "as loaded at 0xF55023, so slot 0x%02X IS code 0x%02X here. Two "
                        "names already in this table corroborate that independently: "
                        "slot 15 is ExitKey_DrawbarScreen (code 0x0F) and slot 16 is "
                        "PageKey_DrawbarScreen (code 0x10), both applied in round 11 "
                        "from the consumer side alone." % (slot, slot))
    out += wrap("Note", BIT7["soft" if control.startswith("SoftKeyCol") else "lcd"])
    out += wrap("Variant", "⚠ VARIANT 2 = the SX-WSA1R, and the chain above is variant "
                           "2's; " + variant1_sentence(slot))
    out += wrap("Evidence", evidence_sentence(control, slot))
    out.append(RULE)
    return out


def family2_classify():
    """Partition the distinct control-slot targets into exactly one bucket each."""
    idx = label_index(read_lines())
    seen = {}
    for t, s, v in family2_scan():
        seen.setdefault(v, []).append((t, s))
    named_now = {v for v, _n, _s, _c, _sl, _sls, _t in family2_targets()}
    buckets = {"done": [], "named": [], "nolabel": [], "multi": [], "noscreen": []}
    for v in sorted(seen):
        cur = idx.get(v, (0, ""))[1]
        if cur and not cur.startswith("sub_"):
            buckets["done"].append(v)
        elif not cur:
            buckets["nolabel"].append(v)
        elif len(seen[v]) > 1:
            buckets["multi"].append(v)
        elif v in named_now:
            buckets["named"].append(v)
        else:
            buckets["noscreen"].append(v)
    return seen, idx, buckets


def family2():
    seen, idx, bk = family2_classify()
    scan = family2_scan()
    print("WHAT THE CONTROL VOCABULARY REACHES ON THE OTHER TABLE FAMILY")
    print("  four 23-entry tables, %d non-default entries in a control slot,"
          " %d distinct targets" % (len(scan), len(seen)))
    print("  the five buckets below are DISJOINT and sum to %d." % len(seen))
    print("    %2d already named          %s"
          % (len(bk["done"]), sorted(idx[v][1] for v in bk["done"])))
    print("    %2d NAMED BY THIS PASS -- table 0xF54248, the DRAWBAR screen, the one"
          % len(bk["named"]))
    print("       table of the four whose owning screen the tree already knows")
    print("    %2d REFUSED, SCREEN UNKNOWN. Their dispatchers are" % len(bk["noscreen"]))
    for t in (0xF135FD, 0xF1394F, 0xF4C38D):
        print("         0x%06X <- %-12s whose own header says \"Unknown: what the "
              "routine is FOR\"" % (t, FAMILY2_READER[t][0]))
    print("       and no vtable slot in any of the four images points at their thunks")
    print("       (T_F42F50, T_F42F6C, T_F434E8), so the screen cannot be read off the")
    print("       tree. <Control>_<address> would be a kind plus an address -- FRAMED,")
    print("       not understanding. Left sub_XXXXXX with this gap stated.")
    print("    %2d REFUSED, ONE ROUTINE IN SEVERAL CONTROL SLOTS: %s"
          % (len(bk["multi"]), [("0x%06X" % v, ["0x%02X" % s for _t, s in seen[v]])
                                for v in bk["multi"]]))
    print("    %2d REFUSED, NO LABEL AT THAT ADDRESS (a mid-routine entry point): %s"
          % (len(bk["nolabel"]), ["0x%06X" % v for v in bk["nolabel"]]))
    for v in bk["nolabel"]:
        if len(seen[v]) > 1:
            print("       and 0x%06X is ALSO in %d control slots at once (%s), so even "
                  "with a" % (v, len(seen[v]),
                              ", ".join("0x%02X" % s for _t, s in seen[v])))
            print("       label the slot would not distinguish it.")
    reach = len(bk["named"]) + len(bk["noscreen"]) + len(bk["multi"]) + len(bk["nolabel"])
    print("\n  ==> the mechanism REACHES %d prom_b routines that are not yet named,"
          % reach)
    print("      and %d of them can be given a CONTENT name today. The other %d are"
          % (len(bk["named"]), reach - len(bk["named"])))
    print("      measured and DECLINED -- the round-8 outcome, and the right one:")
    print("      converting a name to <kind>_<address> would move the metric and not")
    print("      the understanding.")


# ---------------------------------------------------------------------------
# 3.  THE EDIT
# ---------------------------------------------------------------------------
def read_lines():
    return open(SRC, encoding="utf-8", errors="replace").read().split("\n")


ADDRC = re.compile(r"^\t.*?;\s([0-9A-F]{6})\s")
LABELL = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):\s*$")


def label_index(lines):
    """{address: (line index of its label, label text)} for column-0 labels."""
    out, pend = {}, []
    for i, ln in enumerate(lines):
        m = LABELL.match(ln)
        if m:
            pend.append((i, m.group(1)))
            continue
        m2 = ADDRC.match(ln)
        if m2 and pend:
            a = int(m2.group(1), 16)
            for i2, nm in pend:
                out[a] = (i2, nm)
            pend = []
        elif ln.strip() and not ln.startswith(";"):
            pend = []
    return out


RULE_RE = re.compile(r"^; -{20,}\s*$")


def header_bounds(lines, li):
    """(lo, hi) inclusive line range of the `; ---` header block above line li.

    ⚠ The file uses TWO rule widths (69 dashes and 74).  Matching the literal
    string missed every 74-dash block, which is how the first draft of this
    pass crashed on sub_F53136; the replacement keeps whichever rule the block
    already had, so the two styles are not stirred together.
    """
    if not RULE_RE.match(lines[li - 1]):
        return None
    k = li - 2
    while k >= 0 and not RULE_RE.match(lines[k]):
        if not lines[k].startswith(";"):
            return None
        k -= 1
    return (k, li - 1)


def apply(dry=False):
    lines = read_lines()
    idx = label_index(lines)
    renames, edits = [], 0
    blocks = []           # (lo, hi, new_lines) header replacements, applied back to front

    for addr, name, screen, control, bs, slots in targets():
        li, cur = idx[addr]
        if cur.startswith("sub_"):
            renames.append((cur, name))
            b = header_bounds(lines, li)
            assert b, "no header block above %s" % cur
            blocks.append((b[0], b[1], header_for(name, screen, control, bs, slots)))
            lines[li] = name + ":"
            edits += 1
        elif cur != name:
            # round 11 already named it; confirm the family, do not churn
            assert cur.split("_")[0] == name.split("_")[0], (cur, name)

    for addr, name, screen, control, slot, slots, table in family2_targets():
        li, cur = idx[addr]
        if cur == name:
            continue                     # round 11 applied it; nothing to do
        assert cur.startswith("sub_"), (cur, name)
        renames.append((cur, name))
        b = header_bounds(lines, li)
        assert b, "no header block above %s" % cur
        blocks.append((b[0], b[1], family2_header(name, screen, control, slot, table)))
        lines[li] = name + ":"
        edits += 1

    for addr, screen, slots, gap in refusals():
        li, cur = idx[addr]
        want = LATER.get("sub_%06X" % addr, "sub_%06X" % addr)
        if cur != want:
            renames.append((cur, want))
            lines[li] = want + ":"
            edits += 1
        b = header_bounds(lines, li)
        assert b, "no header block above %s" % cur
        blocks.append((b[0], b[1], refusal_header_for(addr, screen, slots, gap)))

    # ★ RENAME FIRST, SPLICE SECOND.  The 0x0D refusal header has to be able to
    # NAME the label it withdraws; if the rename ran last it would rewrite that
    # sentence into "the name sub_F7E750 ... is withdrawn", which says nothing.
    if renames:
        table = dict(renames)
        rx = re.compile(r"\b(?:%s)\b" % "|".join(re.escape(o) for o, _n in renames))
        for i, ln in enumerate(lines):
            if "sub_" in ln or "Key_" in ln:
                lines[i] = rx.sub(lambda m: table[m.group(0)], ln)

    for lo, hi, new in sorted(blocks, reverse=True):
        rule = lines[hi]                      # keep the block's own rule width
        new = [rule] + new[1:-1] + [rule]
        lines[lo:hi + 1] = new

    text = "\n".join(lines)
    if not dry:
        write_part(SRC_MASTER, text)
    return edits, renames, text


# ---------------------------------------------------------------------------
# 4.  THE PROSE AUDIT.  Every detector is paired with a planted fault under
#     --prove, because a detector nobody has seen fire is not a detector.
# ---------------------------------------------------------------------------
def _named_set():
    """Every label THIS pass is responsible for -- both table families.

    ⚠ It must include the family-2 names.  While it did not, the D2 and D3
    planted faults landed on SoftKeyCol1_DrawbarScreen -- the first such label
    in the file -- and neither detector looked at it, so both reported "0
    findings" on a fault that was really there.  That is exactly the failure
    --prove exists to catch, and it caught it.
    """
    return ({name for _a, name, _s, _c, _b, _sl in targets()} |
            {name for _a, name, _s, _c, _sl, _sls, _t in family2_targets()})


def det_stale_sub(text):
    """Prose still naming a sub_XXXXXX whose address is now a real name."""
    bad = []
    for addr, name, _s, _c, _b, _sl in targets():
        lab = "sub_%06X" % addr
        if re.search(r"\b%s\b" % lab, text):
            bad.append("%s survives in the text but 0x%06X is now %s" % (lab, addr, name))
    return bad


def det_no_name_over_named(lines):
    """A header saying NO NAME / Unknown: sitting above a NAMED label."""
    bad, names = [], _named_set()
    for i, ln in enumerate(lines):
        m = LABELL.match(ln)
        if m and m.group(1) in names:
            b = header_bounds(lines, i)
            # ⚠ "NO NAME" is the refusal marker; a plain `Unknown:` line is NOT.
            # An honest residual gap ("Unknown: what (0x2896) holds") belongs in
            # a NAMED routine's header and flagging it was a false positive that
            # --prove exposed on ExitKey_DrawbarScreen and PageKey_DrawbarScreen.
            if b and any("NO NAME" in x for x in lines[b[0]:b[1] + 1]):
                bad.append("%s carries a refusal header" % m.group(1))
    return bad


def det_title_matches(lines):
    """The header's first prose line must open with the label it sits above."""
    bad, names = [], _named_set() | {"sub_%06X" % a for a, _s, _sl, _g in refusals()}
    for i, ln in enumerate(lines):
        m = LABELL.match(ln)
        if m and m.group(1) in names:
            b = header_bounds(lines, i)
            if not b:
                bad.append("%s has no header block" % m.group(1))
                continue
            head = lines[b[0] + 1]
            hm = re.match(r"^; ([A-Za-z_][A-Za-z0-9_]*) -- ", head)
            if hm:
                if hm.group(1) != m.group(1):
                    bad.append("%s: header opens on %s" % (m.group(1), hm.group(1)))
            elif not any(m.group(1) in x for x in lines[b[0]:b[1] + 1]):
                # a title without the " -- gloss" form is house style, not a
                # fault; a header that never names its label IS one
                bad.append("%s: header never names the label" % m.group(1))
    return bad


def det_range_shorthand(lines, text):
    """Committed counting prose about these families must still be true."""
    bad = []
    inspan = [nm for a, (_i, nm) in label_index(lines).items()
              if SPAN_LO <= a < SPAN_HI and nm.startswith("ExitKey_")]
    n = text.count("the twenty named ExitKey_* routines")
    if n and len(inspan) != 20:
        bad.append("%d lines say \"the twenty named ExitKey_* routines\" but the span "
                   "now holds %d" % (n, len(inspan)))
    if "ExitKey_DrawbarScreen" not in text:
        bad.append("ExitKey_DrawbarScreen was renamed; it is the OTHER table family")
    m = re.search(r"largest single refusal of the round: 62 of the span's", text)
    if m:
        bad.append("the '62 of 124' refusal shorthand survives, but 62 LcdKeyRow "
                   "handlers were just named")
    return bad


def det_tautology(lines):
    """A gloss that only restates its own label with the underscores taken out."""
    bad = []
    for i, ln in enumerate(lines):
        m = re.match(r"^; ([A-Za-z_][A-Za-z0-9_]*) -- (.*)$", ln)
        if not m:
            continue
        lab, gloss = m.group(1), m.group(2)
        if not (lab.startswith(("SoftKeyCol", "LcdKeyRow", "ExitKey", "NumberPadKey",
                                "PageKey"))):
            continue
        flat = re.sub(r"[^a-z0-9]", "", gloss.lower())
        if flat == re.sub(r"[^a-z0-9]", "", lab.lower()):
            bad.append("%s: the gloss only restates the label" % lab)
    return bad


def det_evidence_claim(lines):
    """No Evidence line may claim a PRINTED legend for a POSITION-graded switch."""
    bad = []
    for i, ln in enumerate(lines):
        if "Evidence" not in ln and not ln.startswith("; " + " " * 10):
            continue
    for i, ln in enumerate(lines):
        m = LABELL.match(ln)
        if not m or not m.group(1).startswith(("SoftKeyCol", "LcdKeyRow")):
            continue
        b = header_bounds(lines, i)
        if not b:
            continue
        blk = " ".join(x[1:].strip() for x in lines[b[0]:b[1] + 1])
        if "GRADE POSITION" not in blk and "graded LOCKED" not in blk:
            bad.append("%s: header states no provenance grade" % m.group(1))
        if re.search(r"manual (?:PRINTS|prints) .{0,20}(?:SOFT KEY|LCD RIGHT)", blk):
            bad.append("%s: claims the manual prints a legend it does not" % m.group(1))
    return bad


DETECTORS = [
    ("D1 stale sub_XXXXXX in prose", lambda L, T: det_stale_sub(T)),
    ("D2 refusal header over a named label", lambda L, T: det_no_name_over_named(L)),
    ("D3 header title != label", lambda L, T: det_title_matches(L)),
    ("D4 counting prose still true", lambda L, T: det_range_shorthand(L, T)),
    ("D5 tautological gloss", lambda L, T: det_tautology(L)),
    ("D6 evidence overclaims a legend", lambda L, T: det_evidence_claim(L)),
]

# For --prove: a one-line mutation of the text that MUST make each detector fire.
FAULTS = [
    ("D1", lambda L: L + ["; see sub_F7E547 for the shape"]),
    ("D2", lambda L: _plant_no_name(L)),
    ("D3", lambda L: _plant_bad_title(L)),
    # D4 has THREE sub-checks; the fault breaks all three at once and the proof
    # asserts three findings, so no sub-check rides along unexercised.
    ("D4", lambda L: [x.replace("ExitKey_DrawbarScreen", "Zzz_DrawbarScreen")
                      .replace("ExitKey_TrackAssign_StageZero:", "Zzz_A:")
                      for x in L] +
                     ["; This is the largest single refusal of the round: 62 of "
                      "the span's 124"]),
    ("D5", lambda L: _plant_tautology(L)),
    ("D6", lambda L: _plant_overclaim(L)),
]


def _first_named_header(lines, pred=lambda n: n.startswith(("SoftKeyCol", "LcdKeyRow"))):
    for i, ln in enumerate(lines):
        m = LABELL.match(ln)
        if m and pred(m.group(1)):
            b = header_bounds(lines, i)
            if b:
                return i, b, m.group(1)
    return None


def _plant_no_name(lines):
    out = list(lines)
    i, b, _n = _first_named_header(out)
    out.insert(b[1], "; Unknown: NO NAME, and the reason is exact")
    return out


def _plant_bad_title(lines):
    out = list(lines)
    i, b, _n = _first_named_header(out)
    out[b[0] + 1] = "; Something_Else -- a gloss"
    return out


def _plant_tautology(lines):
    out = list(lines)
    i, b, n = _first_named_header(out)
    out[b[0] + 1] = "; %s -- %s" % (n, n.replace("_", " "))
    return out


def _plant_overclaim(lines):
    out = list(lines)
    i, b, n = _first_named_header(out, lambda x: x.startswith("SoftKeyCol"))
    out[b[0] + 1] = ("; %s -- the manual PRINTS \"SOFT KEY col 1 lower\" beside it" % n)
    for k in range(b[0], b[1] + 1):
        out[k] = out[k].replace("GRADE POSITION", "grade")
    return out


def audit(prove=False):
    lines = read_lines()
    text = "\n".join(lines)
    ok = True
    print("PROSE AUDIT of %s" % SRC)
    for tag, fn in DETECTORS:
        bad = fn(lines, text)
        print("  [%s] %-42s %s" % ("ok" if not bad else "FAIL", tag,
                                   "clean" if not bad else "%d finding(s)" % len(bad)))
        for x in bad[:6]:
            print("        - %s" % x)
        ok &= not bad
    if prove:
        print("\nPROOF THAT EACH DETECTOR FIRES -- the same detector, on a planted fault")
        for (tag, fn), (ftag, mut) in zip(DETECTORS, FAULTS):
            assert tag.startswith(ftag)
            ml = mut(lines)
            bad = fn(ml, "\n".join(ml))
            want = 3 if ftag == "D4" else 1
            hit = len(bad) >= want
            print("  [%s] %-42s planted fault -> %d finding(s), wanted >= %d"
                  % ("ok" if hit else "FAIL", tag, len(bad), want))
            ok &= hit
    return ok


# ---------------------------------------------------------------------------
# 5.  THE 0x0D DEMOTION, reproduced
# ---------------------------------------------------------------------------
def zero_d():
    print("WHY SLOT 0x0D IS NOT NAMED -- every claim re-read from the tree\n")
    # ⚠ image_path: prom_a `.include`s kernel/kernel.s and two shared
    # maincpu sources, and a split would leave its primary a header.
    a = open(image_path(ROOT, "prom_a/wsa1_prom_a.s"), encoding="utf-8",
             errors="replace").read()
    for what, pat in [
            ("PanelButton_Route tests bit 0 of (0x2075)", r"F861C6\s+f1 75 20 c8"),
            ("and compares the slot with 0x0d", r"F861CC\s+cf cf 0d"),
            ("the dial arm returns without the screen dispatch", r"F861E4\s+68 55"),
            ("PanelButton_Accept compares (0x20b8)&0x1f with 0x0d", r"F86610\s+cb cf 0d"),
            ("and substitutes (0x209c)", r"F8661B\s+c1 9c 20 23"),
            ("or (0x209b)", r"F86625\s+c1 9b 20 23"),
            ("storing it back to (0x20b8)", r"F86629\s+f1 b8 20 43"),
            ("which is what (0x2082) is loaded from", r"F86704\s+c1 b8 20 21"),
            ("PanelButton_SweepHeld reloads (0x2088) per iteration", r"F8616A\s+e1 88 20 20"),
            ("and PanelButton_Accept sets a bit there", r"F866B3\s+e1 88 20 e8"),
    ]:
        print("  [%s] %s" % ("ok" if re.search(pat, a) else "??", what))
    lits, bad = [], []
    for path in ("prom_a/wsa1_prom_a.s", "prom_b/wsa1_prom_b.s", "prom_c/wsa1_prom_c.s",
                 "prom_d/wsa1_prom_d.s"):
        t = open(image_path(ROOT, path), encoding="utf-8", errors="replace").read()
        for m in re.finditer(r"ld \(0x209[bc]\),0x([0-9a-f]{2,4})\b", t):
            v = int(m.group(1), 16)
            vals = [v & 0xFF, (v >> 8) & 0xFF] if len(m.group(1)) == 4 else [v]
            for x in vals:
                lits.append(x)
                if (x & 0x1F) > 0x0C:
                    bad.append(x)
    print("\n  %d literal bytes are stored to (0x209B)/(0x209C) across the four images;"
          % len(lits))
    print("  masked with 0x1f they span 0x%02X..0x%02X, and %d of them exceed 0x0C."
          % (min(x & 0x1F for x in lits), max(x & 0x1F for x in lits), len(bad)))
    print("  ==> the substitution can never yield 0x0D, so a single press cannot")
    print("      deliver code 0x0D to a screen table.")
    print("\n  ⚠ THE PATH THAT IS NOT CLOSED: PanelButton_SweepHeld routes bit")
    print("      0x0D of (0x2088) if it is ever set, and PanelButton_Accept sets it")
    print("      when 0x0D is accepted with bit 0 of (0x2075) clear. prom_b contains")
    b = open(image_path(ROOT, "prom_b/wsa1_prom_b.s"), encoding="utf-8",
             errors="replace").read()
    print("      %d `or (0x2075),0x09` sites, each of which SETS that bit."
          % len(re.findall(r"or \(0x2075\),0x09", b)))
    print("      Nobody has shown the clear->set transition happening between an")
    print("      accept and a repeat, so the routine keeps sub_XXXXXX.")


# ---------------------------------------------------------------------------
# 5b. THE CITATIONS.  Round 1 shipped 31 citations one byte past the
#     instruction, and the signature was that the byte at cited-1 was an
#     opcode.  Every instruction address these headers print is listed here and
#     checked against the line that CARRIES that address comment, so an
#     off-by-one cannot survive a run.
# ---------------------------------------------------------------------------
CITES = [
    ("prom_a", 0xF861AE, r"and L,0x1f"),
    ("prom_a", 0xF861BC, r"cp L,0x0e"),
    ("prom_a", 0xF861C6, r"bit 0,\(0x2075\)"),
    ("prom_a", 0xF861CC, r"cp L,0x0d"),
    ("prom_a", 0xF86205, r"xor XBC,XBC"),
    ("prom_a", 0xF86610, r"cp C,0x0d"),
    ("prom_a", 0xF8661B, r"ld C,\(0x209c\)"),
    ("prom_a", 0xF86625, r"ld C,\(0x209b\)"),
    ("prom_a", 0xF86629, r"ld \(0x20b8\),C"),
    ("prom_a", 0xF86704, r"ld A,\(0x20b8\)"),
    ("prom_a", 0xF8615C, r"ld XWA,\(0x2088\)"),
    ("prom_a", 0xF866B3, r"e1 88 20 e8"),                 # or (0x2088),XWA
    ("prom_a", 0xF82882, r"ldb a, 0x01"),
    ("prom_a", 0xF8AE7E, r"8c ff 38 11"),                 # add (XIX-1),0x11
    ("prom_a", 0xF8AEF1, r"8c ff 38 11"),
    ("prom_a", 0xF8BDEA, r"and L,0x1f"),
    ("prom_a", 0xF8BDED, r"sla l, 0x02"),
    ("prom_a", 0xF8BDF0, r"e3 03 f0 ec 24"),              # ld XIX,(XIX+L)
    ("prom_a", 0xF8BDF5, r"call \(xix\)"),
    ("prom_b", 0xF7ECFF, r"bit 0x07,W"),
    ("prom_b", 0xF7EDC6, r"ret"),
]
SFILE = {"prom_a": "prom_a/wsa1_prom_a.s", "prom_b": "prom_b/wsa1_prom_b.s"}


def _line_at(image, addr):
    pat = re.compile(r";\s*%06X\b" % addr)
    for ln in open(os.path.join(ROOT, SFILE[image]), encoding="utf-8",
                   errors="replace"):
        if pat.search(ln) and not ln.startswith(";"):
            return ln.rstrip("\n")
    return None


def cites():
    """Every hardcoded instruction address, checked AT the address."""
    ok = True
    print("A. HARDCODED INSTRUCTION CITATIONS -- the line carrying that address")
    for image, addr, want in CITES:
        ln = _line_at(image, addr)
        hit = bool(ln and re.search(want, ln))
        ok &= hit
        print("  [%s] %s 0x%06X  %s" % ("ok" if hit else "FAIL", image, addr,
                                        (ln.strip()[:70] if ln else "NO SUCH ADDRESS")))
    print("\nB. EVERY EVENT RECORD THE 117 HEADERS PRINT, re-read from prom_a")
    rows = []
    for _a, _n, _s, _c, bs, _sl in targets():
        for r in R11.chain(bs, 2):
            rows.append((r[8], bs, r[7]))
    bad = []
    for rec, slot, code in rows:
        b = R11.A(rec, 4)
        if b[0] != 0xA9 or b[1] != slot:
            bad.append((rec, slot, list(b)))
    print("  %d record citations across the 117; %d disagree with the ROM."
          % (len(rows), len(bad)))
    last = rows[-1]
    lb = R11.A(last[0], 4)
    print("  ★ the LAST one, 0x%06X: %s -- class 0x%02X, code 0x%02X, slot 0x%02X"
          % (last[0], " ".join("%02X" % x for x in lb), lb[0], lb[1], last[1]))
    ok &= not bad
    return ok


def grades():
    print("PROVENANCE GRADE of every switch the 92 new names rest on")
    print("(grades are notes/wave7_panel_button_codes.py's own; LEGEND = the manual")
    print(" prints the word, LOCKED = the ROM pins the function, POSITION/RULE = neither)\n")
    seen = {}
    for _a, name, _s, ctl, bs, _sl in targets():
        for row in R11.chain(bs, 2):
            seen.setdefault((row[4], row[5], row[6]), set()).add(ctl)
    import collections
    tally = collections.Counter(g for (_sw, _lg, g) in seen)
    for (sw, legend, grade) in sorted(seen):
        print("  SW%-3d %-24s %-9s <- %s" % (sw, legend, grade,
                                             ", ".join(sorted(seen[(sw, legend, grade)]))))
    print("\n  tally: %s" % dict(tally))
    print("  ==> the tier-B names (SoftKeyCol*, LcdKeyRow*) rest on POSITION and")
    print("      LOCKED rows, NOT on printed legends. APPLIED.md's word \"verbatim\"")
    print("      is wrong about provenance; its \"referent outside the code\" test is")
    print("      what carries them, and every Evidence line written here says so.")


def plan():
    t = targets()
    idx = label_index(read_lines())
    done = sum(1 for a, n, _s, _c, _b, _sl in t if idx.get(a, (0, ""))[1] == n)
    print("%d names -- %d already carried by the file, %d still sub_XXXXXX -- "
          "and %d refusals\n" % (len(t), done, len(t) - done, len(refusals())))
    for addr, name, screen, ctl, bs, slots in t:
        print("  0x%06X  %-44s slots %s" % (addr, name,
                                            ",".join("0x%02X" % s for s in slots)))
    print("\nREFUSALS")
    for addr, screen, slots, _g in refusals():
        print("  0x%06X  sub_%06X  %-34s slots %s"
              % (addr, addr, screen, ",".join("0x%02X" % s for s in slots)))


# ---------------------------------------------------------------------------
# 6.  SELFTEST
# ---------------------------------------------------------------------------
_CK = []


def ck(name, cond, detail=""):
    _CK.append(bool(cond))
    print("  [%s] %s%s" % ("ok" if cond else "FAIL", name,
                           ("  -- " + detail) if detail and not cond else ""))


def selftest():
    t = targets()
    lines = read_lines()
    text = "\n".join(lines)
    idx = label_index(lines)
    print("A. THE MAP")
    ck("A1 117 proposals come through", len(t) == 117, str(len(t)))
    ck("A2 117 distinct names", len({n for _a, n, _s, _c, _b, _sl in t}) == 117)
    ck("A3 the map is a bijection of round 11's",
       {n for _a, n, _s, _c, _b, _sl in t} ==
       {name_of(s, c) for _a, _n, _sl, s, _b, c in
        [(a, n, sl, s, b, c) for a, n, sl, s, b, c in R11.proposals()[0]]})
    ck("A4 7 refusals", len(refusals()) == 7)
    ck("A5 every accepted morpheme survives",
       all(any(m in n for _a, n, _s, _c, _b, _sl in t)
           for m in ["SoftKeyCol1", "SoftKeyCol8", "LcdKeyRow1", "LcdKeyRow5",
                     "ExitKey", "NumberPadKey", "PageKey"]))

    print("B. THE FIRST ELEMENT, in the file")
    a0, n0 = t[0][0], t[0][1]
    ck("B1 0x%06X carries %s" % (a0, n0), idx.get(a0, (0, ""))[1] == n0,
       idx.get(a0, (0, "?"))[1])

    print("C. THE LAST ELEMENT, in the file  ★ tested because round 1's did not")
    aL, nL, sL, cL, bL, slL = t[-1]
    ck("C1 the last proposal is 0x%06X %s" % (aL, nL), True)
    ck("C2 it carries the name", idx.get(aL, (0, ""))[1] == nL, idx.get(aL, (0, "?"))[1])
    bnd = header_bounds(lines, idx[aL][0]) if aL in idx else None
    ck("C3 it has a header block", bnd is not None)
    if bnd:
        blk = lines[bnd[0]:bnd[1] + 1]
        ck("C4 whose title line is the label", blk[1].startswith("; %s -- " % nL), blk[1])
        ck("C5 which carries an Evidence: line", any("Evidence:" in x for x in blk))
        ck("C6 and names the switch that presses it",
           any("SW%d" % R11.chain(bL, 2)[0][4] in x for x in blk))
        ck("C7 and states the slot", any("slot 0x%02X" % bL in x for x in blk))
    lastR = refusals()[-1]
    ck("C8 the last refusal 0x%06X is sub_%06X (or the NOT-NAMED label a later pass declared)" % (lastR[0], lastR[0]),
       idx.get(lastR[0], (0, ""))[1] == LATER.get("sub_%06X" % lastR[0], "sub_%06X" % lastR[0]))

    print("D. THE DEMOTION")
    ck("D1 0xF7E750 is sub_F7E750 again", idx.get(0xF7E750, (0, ""))[1] == "sub_F7E750")
    ck("D2 MinusPlusKey_TrackAssignPresets is no longer a LABEL",
       "\nMinusPlusKey_TrackAssignPresets:" not in text)
    ck("D3 but the refusal header still SAYS which name it withdrew",
       "the name MinusPlusKey_TrackAssignPresets," in text)

    print("D4. THE SECOND TABLE FAMILY  ★ its LAST element too")
    f2 = [x for x in family2_targets() if x[6] == 0xF54248]   # the DRAWBAR table (0xF4C38D's screen became known 2026-10-03)
    ck("D4a 14 DrawbarScreen control slots resolve to a labelled routine",
       len(f2) == 14, str(len(f2)))
    ck("D4a2 two of them were already named in round 11 and are untouched",
       sum(1 for _a, n, _s, _c, _sl, _sls, _t in f2
           if n in ("ExitKey_DrawbarScreen", "PageKey_DrawbarScreen")) == 2)
    mine = [x for x in f2 if x[1] not in ("ExitKey_DrawbarScreen",
                                          "PageKey_DrawbarScreen")]
    ck("D4b0 12 of the 14 are this pass's", len(mine) == 12, str(len(mine)))
    fa, fn = mine[-1][0], mine[-1][1]
    ck("D4b the last of them, 0x%06X, carries %s" % (fa, fn),
       idx.get(fa, (0, ""))[1] == fn, idx.get(fa, (0, "?"))[1])
    fb = header_bounds(lines, idx[fa][0]) if fa in idx else None
    ck("D4c and its header states the 23-entry index rule",
       bool(fb) and any("TWO TABLE FAMILIES, TWO INDEX RULES" in x
                        for x in lines[fb[0]:fb[1] + 1]))
    ck("D4d and keeps the 74-dash rule its block already had",
       bool(fb) and lines[fb[0]] == lines[fb[1]] and len(lines[fb[0]]) == 76,
       repr(lines[fb[0]]) if fb else "")
    _seen, _idx, bk = family2_classify()
    ck("D4e the five buckets are disjoint and sum to the distinct-target count",
       sum(len(v) for v in bk.values()) == len(_seen))

    print("E. WHAT MUST NOT HAVE MOVED")
    ck("E1 ExitKey_DrawbarScreen survives (the OTHER table family)",
       "\nExitKey_DrawbarScreen:" in text)
    ck("E2 the 20 in-span ExitKey_* are still 20",
       sum(1 for a, (_i, nm) in idx.items()
           if SPAN_LO <= a < SPAN_HI and nm.startswith("ExitKey_")) == 20)
    ck("E3 the 5 NumberPadKey_* are still 5",
       sum(1 for a, (_i, nm) in idx.items()
           if SPAN_LO <= a < SPAN_HI and nm.startswith("NumberPadKey_")) == 5)
    ck("E4 the 32 ButtonTable_* labels are intact",
       len(re.findall(r"^ButtonTable_\w+:", text, re.M)) == 32)

    print("F. IDEMPOTENCE")
    _e, _r, again = apply(dry=True)
    ck("F1 a second --apply changes nothing", again == text,
       "%d bytes differ" % sum(1 for x, y in zip(again, text) if x != y))

    print("G. THE CITATIONS")
    ck("G0 every cited instruction address decodes at that address", cites())

    print("H. THE PROSE AUDIT")
    ck("H1 all six detectors clean", audit(prove=False))

    print("\n%d/%d passed" % (sum(_CK), len(_CK)))
    return all(_CK)


def main():
    args = sys.argv[1:]
    if "--plan" in args:
        plan()
    elif "--grades" in args:
        grades()
    elif "--0x0d" in args:
        zero_d()
    elif "--family2" in args:
        family2()
    elif "--cites" in args:
        sys.exit(0 if cites() else 1)
    elif "--apply" in args:
        n, ren, _t = apply()
        print("applied: %d labels rewritten, %d headers regenerated" % (n, len(ren)))
        print("★ NOW RUN: python3 scripts/analysis/assert_byte_identical.py")
    elif "--audit" in args:
        sys.exit(0 if audit("--prove" in args) else 1)
    elif "--selftest" in args:
        sys.exit(0 if selftest() else 1)
    else:
        print(__doc__)


if __name__ == "__main__":
    main()
