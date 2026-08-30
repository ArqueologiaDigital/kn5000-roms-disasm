#!/usr/bin/env python3
"""Which physical panel switch is which panel CODE on the SX-WSA1R?

QUESTION ANSWERED
  The firmware indexes 32-entry per-screen tables by a "panel button number"
  (round 7) and 124 of one span's 210 routines stay sub_XXXXXX because nothing
  in any of the four images maps such a number to a legend on the front panel
  (round 8).  This script settles the question ONE LAYER DOWN -- at the WIRE --
  and states plainly what it does NOT settle.

  THERE ARE TWO SEPARATE NUMBERINGS, and conflating them is the trap:

    LAYER 1  THE WIRE.  The control panel (CP1, a Mitsubishi M37471M2196S)
             sends button packets [0xC0|segment][bitmask] up the SC1 link.
             ==> THIS LAYER IS NOW SOLVED.  segment = the switch matrix's
             COLUMN, bit = its ROW, and the service manual's own switch
             number is  SW = 8*segment + bit + 1.  Two independent ROM
             anchors below pin it; the manual gives every legend.

    LAYER 2  THE EVENT.  Something later turns a wire change into a class-0xA9
             event {0xA9, code, b2, b3} whose `code` is 5 bits of INDEX plus a
             FLAG bit, and it is that 5-bit index the 32-entry screen tables
             use (prom_a PanelButton_Route 0xF861AE `and L,0x1f`).
             ==> THIS LAYER IS STILL OPEN.  This script measures four things
             about it (below) but does NOT claim a single index->legend pair.
             32 codes cannot enumerate 58 fitted switches, so the mapping is
             not the identity and must not be guessed.

THE TWO ANCHORS THAT PIN LAYER 1 (both re-derived here from the ROM bytes)

  A. THE POWER-ON SERVICE CHORDS ARE NUMBER-PAD KEYS.  Service manual page
     I-11/I-12 lists four self-diagnostic modes, each entered by holding one
     NUMBER PAD key while switching on:
         key "2" -> CP1 CPU (IC1) check
         key "3" -> Wave ROM check / Generator IC Outsel check
         key "4" -> Control Panel LED check
         key "5" -> LCD check
     prom_a sub_F953CD reads (0x2B31) -- the shadow byte for wire SEGMENT 1 --
     and requests a screen id per bit:
         bit 2 -> 0xD9    bit 3 -> 0xDA    bit 4 -> 0xDB    bit 5 -> 0xDC
     PanelScreen_VtableTable_ViewB[0xD9..0xDB] resolve, through prom_b thunk
     slots 0xF400E0/0xF400F0/0xF40100, to prom_a
         Paint_PanelCpuCheck / Paint_SineWaveCheckMode / Paint_PanelSwLedCheck
     -- three names the tree derived MONTHS EARLIER from the screens' own text,
     with no knowledge of this question -- and they match the manual's key 2,
     key 3 and key 4 row for row.  Segment 1 is the matrix column holding
     SW9..SW16, whose PCB silkscreen legends are "0".."7" (page II-28), so
     bit b of segment 1 is the key printed b.  Four keys, four bits, in order.

  B. THE GENERATOR IC OUTSEL CHECK HAS FOUR LCD-SIDE BUTTONS.  Manual page
     I-12 draws the LCD with a column of boxes down its right edge and
     annotates exactly four of them, (1)..(4) = MAIN OUT, SUB OUT 1, SUB OUT 2,
     SUB OUT 3.  prom_a sub_F954AA reads (0x2B33) -- SEGMENT 3 -- masks it with
     0x0F and dispatches four ways, on bits 0,1,2,3, to four distinct targets.
     Segment 3 is the matrix column holding SW25..SW32, and the CP1 silkscreen
     (page II-28) puts SW25,26,27,28,29 in a vertical column at the board edge
     nearest the LCD -- the five unlabelled buttons the panel drawing (I-4/I-5)
     shows to the RIGHT of the display.  Top to bottom = bit 0 to bit 4.

  The two anchors are three segments apart and agree on one rule.

  ⚠ WHAT THE ANCHORS DO AND DO NOT PIN.  They pin segments 1 and 3 outright,
  and with them the BIT order inside a column (top of the column = bit 0, both
  times).  The other seven populated segments follow by LINEAR EXTRAPOLATION
  of the same rule, supported by three properties of the manufacturer's own
  numbering rather than by a second measurement: SW1..SW48 fill six columns of
  eight with no gap except the one position that has no switch (SW24, and the
  diode list omits D24 to match); CP2's three groups begin at 57, 65 and 73,
  i.e. exactly on 8-boundaries; and within every column the printed order runs
  top to bottom.  If the CP1 MCU scanned its columns in a permuted order, both
  anchors landing on the linear prediction would be a coincidence -- but only
  segments 1 and 3 are MEASURED, and the grades in the table say which is
  which.

WHAT THIS SCRIPT PRINTS / RUN
    python3 notes/wave7_panel_button_codes.py              # the map + the measurements
    python3 notes/wave7_panel_button_codes.py --selftest   # 26 checks, incl. LAST elements
    python3 notes/wave7_panel_button_codes.py --physical   # just the SW -> legend table
    python3 notes/wave7_panel_button_codes.py --layer2     # just the open-layer measurements

SOURCES FOR THE PHYSICAL TABLE (nothing here is inferred from plausibility)
  * "SX-WSA1R Service Manual.pdf" (Technics, ORDER NO. EMID951604), 42 pages,
    NO TEXT LAYER -- read as images.
      page 5   = I-4/I-5  ARRANGEMENT OF CONTROL PANEL (the panel drawing and
                          the English names of every control)
      page 11  = I-11     ABOUT THE SELF-DIAGNOSTIC FUNCTION (the four chords)
      page 12  = I-12     the wave-ROM / outsel check LCD-side buttons
      page 31  = II-27/28 CP1/CP2 P.C. Board -- the SILKSCREEN, which prints
                          the panel legend next to each SWnn
      page 32  = II-29/30 CP1/CP2 P.C. Diagram -- the switch MATRIX: 6 column
                          groups of 8 on CP1 (SW1..SW48, D24/SW24 not fitted:
                          the diode list reads "D1-23, 25-48"), and on CP2
                          SW57-60, SW65-66, SW73-77 ("D57-60,65,66,73-77").
  * The legends printed on the diagram AND on the silkscreen agree wherever
    both carry one (the whole number pad does: SW9="0" .. SW20="ENTER").

WHAT THE OTHER CANDIDATE SOURCES ACTUALLY CONTAIN -- a measured negative, so
nobody spends another round on them

  * THE ROM HAS NO SWITCH-NAME TABLE.  "COMPARE" -- printed on the panel and on
    both manual pages -- occurs ZERO times in all four images; prom_c and
    prom_d contain none of "RE-MAP", "ROM/EXT", "PAGE", "ENTER", "BANK",
    "COMBI", "USER 1" or "REALTIME" either.  The service screen that would be
    the natural place for a switch list, Paint_PanelSwLedCheck (prom_a
    0xF95990), draws four lines and none of them names a switch: "PANEL SW&LED
    CHECK"; "Please push a any button."; "If LED near the button turn";
    "ON/OFF. It is working OK."  ⚠ That last line says the LED response is the
    CP1 MCU's own doing, which is why the main firmware never needs the names.
  * THE KN7000 MAP DOES NOT TRANSFER, AND ITS SHAPE IS DIFFERENT.
    kn7000_mame/notes/panel-dispatch-table.md decodes a 2-byte frame
    [ADDR][bitmap] normalised to a `normSeg` 0..0x20 and then indexed into
    per-normSeg arrays of {event, mask, type} records on an MN10300.  There is
    no 5-bit index, no flag bit and no 32-entry per-screen table.  Nothing in
    it is portable here beyond the METHOD (find a chord or a service screen
    whose legend the manual states, then read what the firmware does with it),
    which is the method this script uses.
  * THE KN5000 SHARES THE PANEL MCU PART NUMBER AND THE FRAME, NOT THE MAP.
    kn5000-docs/control-panel-protocol.md names the same Mitsubishi
    M37471M2196S (the WSA1R fits ONE, on CP1; the KN5000 fits TWO), and gap E
    of notes/WSA1-EMULATION-DISASM-GAPS.md already settled that the WSA1's SC1
    module is the same driver.  But a segment/bit pair addresses a MATRIX
    POSITION on a particular panel PCB, and the KN5000's panel is a different
    board with different switches -- so not one assignment transfers.  This is
    the round-2 cross-tree trap in its exact shape (68 shared SFR names, one
    shared address) and the map below owes the KN5000 nothing.

WHAT THIS ANSWERS OUTSIDE THIS TREE
  notes/WSA1-EMULATION-DISASM-GAPS.md gap O ("Which panel button is which
  bit") asks for exactly the LAYER 1 table below, and says the MAME device
  wsa1_cpanel.cpp declares its matrix positionally ("Panel SEG3 SW5") because
  nobody had it.  Gap O's own "where to look" line says a better scan of the
  self-diagnostic pages "would give six (legend, bit) pairs at once"; the scan
  gave the four chords of anchor A and the four buttons of anchor B, and the
  matrix geometry then gives all 58.  The LED half of gap O is untouched here.

⚠ A CORRECTION THIS LANE OWES prom_a
  PanelButton_PostClass70's header (prom_a, near 0xF8623C) reads "1 when bit 7
  of W is set (button RELEASED)".  Bit 7 is not a release flag:
    * prom_a sub_F8BDC5 selects between TWO 32-bit enable masks on it,
      (0x2666) for bit 7 clear and (0x266A) for bit 7 set (0xF8BDD2-0xF8BDDE).
      A press/release flag does not need a second enable word.
    * prom_b 0xF7ECFF-0xF7EDC6, eight handlers for indices 0..7, use it to
      choose item i (clear) or item i+8 (set) -- on RELEASE that would select a
      different item than the press did.
  Whatever bit 7 means, "released" is not established by anything read here,
  and PanelButton_Accept computes it from bit 0 of (0x20B9) while testing
  release separately as (0x20B9) & (0x20BA) == 0 (0xF866F8-0xF86702).
  ⚠ This lane is READ-ONLY on the .s files and did not edit that header.

WHAT LAYER 2 STILL NEEDS -- the next lane's shortest path
  The three bytes SC1_RxOp0_ThreeByte queues are [wire][new value][change mask]
  (prom_b 0xF5B0D5-0xF5B12B).  Whatever consumes that queue and posts the
  class-0xA9 event holds the (segment, bit) -> 5-bit-index table, and finding
  it closes the question outright.  It was not found in this lane's time.

GRADES in the table below -- the grade is part of the finding:
  LOCKED   the ROM confirms this switch's FUNCTION (anchors A and B only)
  LEGEND   the manual PRINTS the legend beside this SWnn; position by the rule
  POSITION no printed legend; identity is the silkscreen POSITION matched
           against the panel drawing (the two 8-wide soft-key rows, the two
           five-button columns flanking the LCD, -1/+1, EXIT)
  RULE     CP2; no ROM anchor and no ambiguity in the silkscreen, but the
           segment/bit assignment rests on the rule alone
"""
import os
import re
import sys
import collections

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
A_BASE, B_BASE = 0xF80000, 0xF00000

_a = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
_b = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
A = lambda p, n=1: _a[p - A_BASE:p - A_BASE + n]
B = lambda p, n=1: _b[p - B_BASE:p - B_BASE + n]
LA = lambda p: int.from_bytes(A(p, 4), "little")
LB = lambda p: int.from_bytes(B(p, 4), "little")

# ---------------------------------------------------------------------------
# THE PHYSICAL TABLE.  (segment, bit) -> (SWnn, legend, grade)
# SW = 8*segment + bit + 1 throughout; None = that matrix position is not fitted.
# ---------------------------------------------------------------------------
PANEL = {
    # --- CP1, segments 0..5 -------------------------------------------------
    (0, 0): ("PLAY MODE SOUND",  "LEGEND"),
    (0, 1): ("PLAY MODE COMBI",  "LEGEND"),
    (0, 2): ("EDIT MODE SOUND",  "LEGEND"),
    (0, 3): ("EDIT MODE COMBI",  "LEGEND"),
    (0, 4): ("BANK USER 1",      "LEGEND"),
    (0, 5): ("BANK USER 2",      "LEGEND"),
    (0, 6): ("BANK ROM/EXT",     "LEGEND"),
    (0, 7): ("BANK RE-MAP",      "LEGEND"),
    (1, 0): ('NUMBER PAD "0"',   "LEGEND"),
    (1, 1): ('NUMBER PAD "1"',   "LEGEND"),
    (1, 2): ('NUMBER PAD "2"',   "LOCKED"),
    (1, 3): ('NUMBER PAD "3"',   "LOCKED"),
    (1, 4): ('NUMBER PAD "4"',   "LOCKED"),
    (1, 5): ('NUMBER PAD "5"',   "LOCKED"),
    (1, 6): ('NUMBER PAD "6"',   "LEGEND"),
    (1, 7): ('NUMBER PAD "7"',   "LEGEND"),
    (2, 0): ('NUMBER PAD "8"',   "LEGEND"),
    (2, 1): ('NUMBER PAD "9"',   "LEGEND"),
    (2, 2): ('NUMBER PAD "+/-"', "LEGEND"),
    (2, 3): ("ENTER",            "LEGEND"),
    (2, 4): ("PAGE v",           "LEGEND"),
    (2, 5): ("PAGE ^",           "LEGEND"),
    (2, 6): ("COMPARE",          "LEGEND"),
    (2, 7): (None,               "NOT FITTED"),
    (3, 0): ("LCD RIGHT 1 (top)",    "LOCKED"),
    (3, 1): ("LCD RIGHT 2",          "LOCKED"),
    (3, 2): ("LCD RIGHT 3",          "LOCKED"),
    (3, 3): ("LCD RIGHT 4",          "LOCKED"),
    (3, 4): ("LCD RIGHT 5 (bottom)", "POSITION"),
    (3, 5): ("-1",               "POSITION"),
    (3, 6): ("+1",               "POSITION"),
    (3, 7): ("EXIT",             "POSITION"),
    (4, 0): ("SOFT KEY col 1 lower", "POSITION"),
    (4, 1): ("SOFT KEY col 1 upper", "POSITION"),
    (4, 2): ("SOFT KEY col 2 lower", "POSITION"),
    (4, 3): ("SOFT KEY col 2 upper", "POSITION"),
    (4, 4): ("SOFT KEY col 3 lower", "POSITION"),
    (4, 5): ("SOFT KEY col 3 upper", "POSITION"),
    (4, 6): ("SOFT KEY col 4 lower", "POSITION"),
    (4, 7): ("SOFT KEY col 4 upper", "POSITION"),
    (5, 0): ("SOFT KEY col 5 lower", "POSITION"),
    (5, 1): ("SOFT KEY col 5 upper", "POSITION"),
    (5, 2): ("SOFT KEY col 6 lower", "POSITION"),
    (5, 3): ("SOFT KEY col 6 upper", "POSITION"),
    (5, 4): ("SOFT KEY col 7 lower", "POSITION"),
    (5, 5): ("SOFT KEY col 7 upper", "POSITION"),
    (5, 6): ("SOFT KEY col 8 lower", "POSITION"),
    (5, 7): ("SOFT KEY col 8 upper", "POSITION"),
    # --- segment 6: SW49..SW56, none fitted --------------------------------
    # --- CP2, segments 7..9 -------------------------------------------------
    (7, 0): ("MENU PART",   "RULE"),
    (7, 1): ("MENU SYSTEM", "RULE"),
    (7, 2): ("MENU MIDI",   "RULE"),
    (7, 3): ("MENU DISK",   "RULE"),
    (8, 0): ("REALTIME CREATOR 1~6", "RULE"),
    (8, 1): ("RESET",                "RULE"),
    (9, 0): ("LCD LEFT 1 (top)",     "RULE"),
    (9, 1): ("LCD LEFT 2",           "RULE"),
    (9, 2): ("LCD LEFT 3",           "RULE"),
    (9, 3): ("LCD LEFT 4",           "RULE"),
    (9, 4): ("LCD LEFT 5 (bottom)",  "RULE"),
}
# switches present on the panel, as SW numbers, straight from the two diode
# lists on manual page 32:  CP1 "D1-23, 25-48"  and  CP2 "D57-60,65,66,73-77".
FITTED_SW = set(range(1, 24)) | set(range(25, 49)) | {57, 58, 59, 60, 65, 66} | set(range(73, 78))


def sw_of(seg, bit):
    return 8 * seg + bit + 1


def shadow_of(seg):
    """RAM address of the per-segment shadow byte, from prom_b's own arithmetic."""
    return 0x2B20 + ((0xC0 | seg) & 0x0F | (((0xC0 | seg) & 0x40) >> 2))


# ---------------------------------------------------------------------------
# The re-derivations.  Each returns (facts, [(name, ok, detail), ...]).
# ---------------------------------------------------------------------------
def d_shadow_arithmetic():
    """prom_b SC1_RxOp0_ThreeByte: `and W,0x4F / ld XHL,0x2B20 / bit 6,W /
    jr Z / sub W,0x30 / add L,W` -- the index that makes shadow(seg)."""
    want = bytes.fromhex("c8cc4f" "43202b0000" "c83306" "6603" "c8ca30" "c887")
    got = B(0xF5B0FD, len(want))
    checks = [("shadow arithmetic bytes at prom_b 0xF5B0FD", got == want, got.hex())]
    checks.append(("shadow(seg 1) == 0x2B31", shadow_of(1) == 0x2B31, hex(shadow_of(1))))
    checks.append(("shadow(seg 3) == 0x2B33", shadow_of(3) == 0x2B33, hex(shadow_of(3))))
    # LAST element: the highest segment this panel populates
    checks.append(("shadow(seg 9) == 0x2B39 (LAST populated segment)",
                   shadow_of(9) == 0x2B39, hex(shadow_of(9))))
    return {"shadow": {s: shadow_of(s) for s in range(16)}}, checks


def d_service_chords():
    """prom_a sub_F953CD: (0x2B31) -> a requested screen id, one bit at a time.
    Decoded from the bytes, not transcribed: find each `cp BC,imm / jr Z,rel`
    and read the `ld (XIX),imm8` at the branch target (XIX = &(0x2070))."""
    checks = []
    checks.append(("sub_F953CD loads &(0x2070) then (0x2B31)",
                   A(0xF953CE, 8) == bytes.fromhex("f1702034c1312b23"), A(0xF953CE, 8).hex()))
    out = {}
    p = 0xF953D8
    while p < 0xF953F4:
        op = A(p, 2)
        if op[0] == 0xD9 and op[1] in (0xD8 | 0x02, 0xDA, 0xDC):      # cps bc,imm3 short forms
            imm = op[1] & 0x07
            p += 2
        elif op == b"\xd9\xcf":                                       # cp BC,imm16
            imm = int.from_bytes(A(p + 2, 2), "little")
            p += 4
        else:
            break
        if A(p, 1) != b"\x66":                                        # jr Z,rel8
            break
        tgt = p + 2 + A(p + 1, 1)[0]
        p += 2
        body = A(tgt, 3)
        if body[0] == 0xB4 and body[1] == 0x00:                       # ld (XIX),imm8
            out[imm] = body[2]
    checks.append(("four segment-1 bits select four screen ids", len(out) == 4, repr(out)))
    want = {0x04: 0xD9, 0x08: 0xDA, 0x10: 0xDB, 0x20: 0xDC}
    checks.append(("bits 2,3,4,5 -> screens 0xD9,0xDA,0xDB,0xDC", out == want, repr(out)))
    return {"chords": out}, checks


def d_service_screens():
    """PanelScreen_VtableTable_ViewB[0xD8..0xDD] -> prom_b thunk slot ->
    prom_a paint routine, and the label prom_b already gives that slot."""
    VIEWB = 0xF86F41                  # = PanelScreen_VtableTable + 0x80, the base
                                      # `ld XBC,0x00F86F41` at PanelButton_Route 0xF86215
    labels = {}
    src = open(os.path.join(ROOT, "prom_b", "wsa1_prom_b.s"), encoding="utf-8", errors="replace").read()
    for m in re.finditer(r"^(T_\w+):\s*jp 0x([0-9A-F]{6})\s*;\s*F([0-9A-F]{5})", src, re.M):
        labels[0xF00000 + int(m.group(3), 16)] = (m.group(1), int(m.group(2), 16))
    rows, checks = [], []
    checks.append(("ViewB entry 219 sits at prom_a 0xF872AD",
                   VIEWB + 4 * 219 == 0xF872AD, hex(VIEWB + 4 * 219)))
    for sid in range(0xD8, 0xDE):
        slot = LA(VIEWB + 4 * sid)
        lbl, tgt = labels.get(slot, ("(no prom_b label)", LB(slot) & 0xFFFFFF if 0xF00000 <= slot < 0xF80000 else 0))
        rows.append((sid, slot, lbl, tgt))
    want = {0xD9: "T_Paint_PanelCpuCheck", 0xDA: "T_Paint_SineWaveCheckMode",
            0xDB: "T_Paint_PanelSwLedCheck"}
    for sid, name in want.items():
        got = dict((r[0], r[2]) for r in rows)[sid]
        checks.append(("screen 0x%02X -> %s" % (sid, name), got == name, got))
    checks.append(("screen 0xDD is the LAST of the six service slots",
                   rows[-1][0] == 0xDD and rows[-1][1] == 0xF40130, hex(rows[-1][1])))
    return {"screens": rows}, checks


def d_outsel_chord():
    """prom_a sub_F954AA: (0x2B33) & 0x0F dispatched four ways -- the four
    LCD-side buttons the manual annotates for GENERATOR IC OUTSEL CHECK."""
    checks = []
    checks.append(("sub_F954AA reads (0x2B33) and masks 0x0F",
                   A(0xF954AF, 7) == bytes.fromhex("c1332b23cbcc0f"), A(0xF954AF, 7).hex()))
    imms, p = [], 0xF954B8
    while p < 0xF954CA:
        op = A(p, 2)
        if op[0] == 0xD9 and op[1] in (0xD9, 0xDA, 0xDC):
            imms.append(op[1] & 7); p += 2
        elif op == b"\xd9\xcf":
            imms.append(int.from_bytes(A(p + 2, 2), "little")); p += 4
        else:
            break
        if A(p, 1) != b"\x66":
            break
        p += 2
    checks.append(("four single-bit compares, bits 0..3", imms == [1, 2, 4, 8], repr(imms)))
    return {"outsel": imms}, checks


def d_sine_menu():
    """The SINE WAVE CHECK screen's own display list, prom_b 0xF2C88B-0xF2C9C2,
    drawn by prom_a Paint_SineWaveCheckMode (site 0xF9580E/0xF95808)."""
    raw = B(0xF2C88B, 0xF2C9C2 - 0xF2C88B)
    items = re.findall(rb"\(\d\)[ -~]+", raw)
    checks = [("seven numbered CHECK MODE items", len(items) == 7, str(len(items)))]
    checks.append(("LAST item is (7) EXT BOARD WAVE CHECK",
                   items[-1] == b"(7) EXT BOARD WAVE CHECK", items[-1].decode()))
    return {"menu": [i.decode() for i in items]}, checks


def d_poweron_chords():
    """The three power-on chords, both hardware variants, gated on (0xC4)==1."""
    rows = [("FACTORY CLEAR",   0xF828DF, 1, 8, 0x07, "== 0x07 exactly"),
            ("FACTORY CLEAR",   0xF828E9, 2, 8, 0x03, "& 0x03 == 0x03"),
            ("ROM version",     0xF82952, 1, 2, 0x07, "& 0x07 == 0x07"),
            ("ROM version",     0xF8295F, 2, 0, 0x70, "& 0x70 == 0x70"),
            ("VersionScreen",   0xF82A0A, 1, 10, 0xE0, "& 0xE0 == 0xE0"),
            ("VersionScreen",   0xF82A18, 2, 3, 0xE0, "& 0xE0 == 0xE0")]
    checks = []
    for _, addr, _, seg, _, _ in rows:
        ok = A(addr, 4) == bytes([0xC1, shadow_of(seg) & 0xFF, 0x2B, 0x21])
        checks.append(("chord site 0x%06X reads shadow(seg %d)" % (addr, seg), ok, A(addr, 4).hex()))
    out = []
    for name, addr, var, seg, mask, how in rows:
        need = [b for b in range(8) if mask >> b & 1]
        legends = [PANEL.get((seg, b), (None,))[0] for b in need]
        reach = all(sw_of(seg, b) in FITTED_SW for b in need)
        out.append((name, var, seg, how, need, legends, reach))
    v1 = [r for r in out if r[1] == 1]
    v2 = [r for r in out if r[1] == 2]
    checks.append(("2 of the 3 variant-1 chords need switches NOT fitted here",
                   sum(not r[6] for r in v1) == 2, repr([r[6] for r in v1])))
    checks.append(("variant-2 chords are all fitted",
                   all(r[6] for r in v2), repr([r[6] for r in v2])))
    return {"poweron": out}, checks


# ---------------------------------------------------------------------------
# LAYER 2 -- what is measured about the 5-bit event index, and nothing more
# ---------------------------------------------------------------------------
def d_layer2():
    tabs = [[LB(0xF7D2D8 + 0x80 * t + 4 * i) for i in range(32)] for t in range(32)]
    live = [0] * 32
    for T in tabs:
        dflt = collections.Counter(T).most_common(1)[0][0]
        for i in range(32):
            if T[i] != dflt:
                live[i] += 1
    checks = [("indices 0x00-0x0F live in >=31 of the 32 screen tables",
               min(live[:16]) >= 31, repr(live[:16])),
              ("indices 0x10-0x1F live in <=14 of them",
               max(live[16:]) <= 14, repr(live[16:])),
              ("index 0x1F is the LAST slot and is live in 10 tables",
               live[31] == 10, str(live[31]))]
    # the flag bit has its OWN 32-bit enable mask
    two = A(0xF8BDD2, 13)
    checks.append(("prom_a 0xF8BDD2: `ld XBC,(0x2666) / bit 7,W / jr Z / ld XBC,(0x266A)`",
                   two == bytes.fromhex("e1662621c833076604e16a2621"), two.hex()))
    # a screen handler that uses the flag bit to pick item i vs item i+8
    h = B(0xF7ECFF, 0x19)
    checks.append(("prom_b 0xF7ECFF picks (0x3602)=0 or 0x08 on bit 7 of W",
                   h == bytes.fromhex("c833076e07f10236000068 08 cbc808f1023600081dc40cf40e".replace(" ", "")),
                   h.hex()))
    # the same shape at index 7, the LAST of that run of eight
    h7 = B(0xF7ECFF + 7 * 0x19, 0x0B)
    checks.append(("the LAST of that run of eight (index 7) writes 0x07 to (0x3602)",
                   h7[:3] == bytes.fromhex("c83307") and h7[5:10] == bytes.fromhex("f102360007"),
                   h7.hex()))
    # arithmetic: 32 codes cannot enumerate the fitted switches
    checks.append(("58 switches are fitted, more than the 32 five-bit codes",
                   len(FITTED_SW) == 58, str(len(FITTED_SW))))
    return {"live": live}, checks


DERIVATIONS = [("wire shadow arithmetic", d_shadow_arithmetic),
               ("segment-1 service chords", d_service_chords),
               ("service screen names", d_service_screens),
               ("segment-3 outsel chord", d_outsel_chord),
               ("SINE WAVE CHECK menu", d_sine_menu),
               ("power-on chords, both variants", d_poweron_chords),
               ("LAYER 2 measurements", d_layer2)]


def print_physical():
    print("SEGMENT/BIT -> SWITCH -> LEGEND   (SW = 8*segment + bit + 1)")
    print("  seg.bit  SW   grade     legend")
    for seg in range(10):
        for bit in range(8):
            sw = sw_of(seg, bit)
            if sw not in FITTED_SW:
                continue
            legend, grade = PANEL.get((seg, bit), ("?", "?"))
            print("   %d.%d    SW%-3d %-8s  %s" % (seg, bit, sw, grade, legend))
    print("\n  not fitted: SW24, SW49-SW56 (segment 6 entirely), SW61-64, SW67-72,")
    print("  SW78-80 -- from the two diode lists on manual page 32.")
    print("  fitted switches: %d.  Five-bit event codes: 32." % len(FITTED_SW))


def main():
    argv = sys.argv[1:]
    if "--physical" in argv:
        print_physical(); return 0
    allchecks = []
    for name, fn in DERIVATIONS:
        if "--layer2" in argv and name != "LAYER 2 measurements":
            continue
        facts, checks = fn()
        allchecks += checks
        print("=== %s" % name)
        for k, v in facts.items():
            if k == "screens":
                for sid, slot, lbl, tgt in v:
                    print("    screen 0x%02X -> thunk 0x%06X %-28s -> prom_a 0x%06X" % (sid, slot, lbl, tgt))
            elif k == "chords":
                for imm, sid in sorted(v.items()):
                    bit = imm.bit_length() - 1
                    print("    segment 1 bit %d (%s) -> screen 0x%02X"
                          % (bit, PANEL[(1, bit)][0], sid))
            elif k == "poweron":
                for nm, var, seg, how, need, legends, reach in v:
                    print("    %-14s variant %d  seg %-2d %-16s bits %-9s %s%s"
                          % (nm, var, seg, how, need,
                             " + ".join(str(l) for l in legends),
                             "" if reach else "   <- NOT FITTED on the WSA1R panel"))
            elif k == "menu":
                for it in v:
                    print("    %s" % it)
            elif k == "live":
                print("    per-index liveness over the 32 screen tables (of 32):")
                for r in range(4):
                    print("      " + "  ".join("%02X:%2d" % (r * 8 + c, v[r * 8 + c]) for c in range(8)))
            elif k == "shadow":
                print("    shadow(segment s) = 0x%04X + s" % 0x2B30)
            else:
                print("    %s = %s" % (k, v))
        print()
    if "--selftest" in argv:
        bad = 0
        print("=== SELFTEST (%d checks)" % len(allchecks))
        for name, ok, detail in allchecks:
            print("  [%s] %s%s" % ("ok" if ok else "FAIL", name, "" if ok else "   got %s" % detail))
            bad += not ok
        print("%d/%d passed" % (len(allchecks) - bad, len(allchecks)))
        return 1 if bad else 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
