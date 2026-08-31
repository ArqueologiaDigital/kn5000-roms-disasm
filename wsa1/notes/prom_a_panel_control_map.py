#!/usr/bin/env python3
"""The 5-bit panel EVENT CODE -> physical control map, re-derived from prom_a's
side and checked against the answer prom_b's lane already reached.

⚠ READ THIS FIRST: THE MAP IS NOT THIS FILE'S DISCOVERY.
--------------------------------------------------------
Rounds 9-12 got there first, and this script found that out the hard way -- by
composing the map, writing it up as new, and only then grepping the tree.  The
record, so nobody re-runs the same lap:

  * round 9   notes/wave7_panel_button_codes.py -- LAYER 1, the wire numbering
              and (segment, bit) -> SW -> the manual's legend.
  * round 10  notes/wave7_panel_event_index.py -- the LAYER-2 machinery: the
              wire->group map and the per-group event lists.
  * round 11  notes/wave7_panel_names_round11.py --variant -- WHICH VARIANT THIS
              MACHINE IS, settled THREE ways (diode coverage, the power-on
              service chords, the number-pad value tables).
  * round 12  notes/prom_b_panel_names_round12.py -- SLOT_CONTROL, and 131
              labels in prom_b already named SoftKeyColN / LcdKeyRowN / ExitKey
              for exactly these codes.

WHAT THIS FILE IS FOR, THEN
---------------------------
1. ★ IT IS A REPLICATION, AND THE AGREEMENT IS A RESULT.  The route here is
   prom_a-side and different in kind: compose the wire->group map (0xF8A189)
   with the group event lists (0xF8B4B2) into (segment, bit) -> (class, code,
   pair position), then cross that with round 9's imported PANEL table.  The
   `--checks` run asserts the outcome matches round 12's SLOT_CONTROL on every
   shared code -- and it is looking for a DISAGREEMENT, because a disagreement
   would mean one of the two maps is wrong and every name built on it is unsafe.
   Every check it prints passes; run --checks for the current list.

2. It covers three codes round 12's table does not: 0x0D (the -1/+1 pair, whose
   direction bit `PanelButton_Accept` special-cases at 0xF86610), 0x1E
   (COMPARE) and 0x20 (mode/menu select, which is out of range for a 32-entry
   table and is taken by PanelEvent_Code20_SetScreen).

3. It carries the PAIR POSITION for every control, derived rather than asserted:
   `PanelEvent_ShiftThenRunAction` (0xF8A8A1) reads bit 4 of a record's shift
   byte as a direction and bits 0-2 as a count, and normalises a single-bit mask
   onto bit 0 or bit 1 of a two-bit field.  So "which of the two keys" is a
   computation over the ROM, not a reading of the panel.

4. ★ IT IS WHAT TIED prom_a's OWN 0xFF3800 MODULE TO THE LEGEND.  Fourteen
   dispatch-table headers there ended "⚠ Not one entry is tied to a legend"
   while prom_b's tables had been named for two rounds.  Check C9 is the
   prediction that closed it: four sibling tables whose live entries are exactly
   the five LCD rows and EXIT, which is what a menu screen looks like under this
   map and a coincidence under any other.  The names are applied by
   notes/prom_a_naming_wave8_apply.py.

THE COMPOSITION
---------------
    segment  --PanelWireGroupMap_VariantN (0xF8A109 / 0xF8A189)-->  group
    group    --PanelGroupEventLists_VariantN (0xF8B446 / 0xF8B4B2)-->
                                                  [class, code, shift, mask]*
    (segment, bit)  --SW = 8*seg + bit + 1-->  the manual's legend

The record is four bytes terminated by 0xFF in byte 0.  The (segment,bit) ->
legend table is IMPORTED from round 9 rather than copied, so a correction there
propagates here.

THE VARIANT, and whose answer it is
-----------------------------------
`cp (0xC4),0x01 / jr z` at 0xF8A851 takes variant 1 when (0xC4) == 1 and
variant 2 otherwise; (0xC4) is 1 when PORT B bit 0 reads HIGH and 2 when it
reads LOW (Variant_SetFromPB0, 0xF82882).  **VARIANT 2 IS THE SX-WSA1R** --
ROUND 11's result, three arguments, not this file's.  `--variant` re-derives it
by ONE of those three, the diode coverage: variant 2's group lists cover exactly
the fitted matrix positions on all twelve wire segments and variant 1
contradicts the manual on six of them.  So on the rack, PORT B BIT 0 READS LOW.

USAGE
-----
    python3 notes/prom_a_panel_control_map.py            # both variants
    python3 notes/prom_a_panel_control_map.py --map      # variant 2, code -> control
    python3 notes/prom_a_panel_control_map.py --variant  # the coverage argument
    python3 notes/prom_a_panel_control_map.py --checks   # the corroborations
    python3 notes/prom_a_panel_control_map.py --selftest
"""
import os
import re
import sys
import collections

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))

_a = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
A_BASE = 0xF80000
A = lambda p, n=1: _a[p - A_BASE:p - A_BASE + n]
LA = lambda p: int.from_bytes(A(p, 4), "little")

# round 9's panel table, imported rather than copied: one source of truth for
# (segment, bit) -> legend, and if it is corrected this script follows.
import wave7_panel_button_codes as R9              # noqa: E402
PANEL, FITTED_SW, sw_of = R9.PANEL, R9.FITTED_SW, R9.sw_of

WIREMAP = {1: 0xF8A109, 2: 0xF8A189}      # 128 bytes each, prom_a
GROUPLISTS = {1: 0xF8B446, 2: 0xF8B4B2}   # 27 slots of LE32, prom_a
GROUP_BOUND = 0x18                        # `cp A,0x18` at 0xF8A83B


def wire_index(seg):
    """The map index the drain computes for wire byte 0xC0|seg.

    `and L,0x1F / and A,0xC0 / srl A,1 / or L,A` -- prom_a 0xF8A0A3-0xF8A0AC,
    quoted from PanelWireQueue_DrainToGroupQueue's own header."""
    wire = 0xC0 | seg
    return (wire & 0x1F) | ((wire & 0xC0) >> 1)


def group_of(variant, seg):
    return A(WIREMAP[variant] + wire_index(seg))[0]


def records(variant, group):
    """[(cls, code, shift, mask)] of one group's list, terminated by 0xFF."""
    if group > GROUP_BOUND:
        return []
    p = LA(GROUPLISTS[variant] + 4 * group) & 0xFFFFFF
    out = []
    while len(out) < 32:
        r = A(p, 4)
        if not r or r[0] == 0xFF:
            break
        out.append(tuple(r))
        p += 4
    return out


def pair_pos(shift, mask):
    """Which half of the two-bit field a SINGLE-bit mask lands on, or None.

    PanelEvent_ShiftThenRunAction (prom_a 0xF8A8A1) reads bit 4 of the shift
    byte as the direction and bits 0-2 as the count, and normalises the masked
    value down to bits 0-1.  So a one-bit mask ends on bit 0 or bit 1, and that
    is the pair position; a multi-bit mask is a whole field and has none."""
    if mask == 0 or mask & (mask - 1):
        return None
    bit = mask.bit_length() - 1
    n = shift & 0x07
    dest = bit + n if shift & 0x10 else bit - n
    return dest if dest in (0, 1) else None


def compose(variant):
    """{(seg, bit): (cls, code, pos_or_None, mask)} plus the whole-field rows."""
    out = {}
    fields = []
    for seg in range(0, 12):
        g = group_of(variant, seg)
        for (cls, code, shift, mask) in records(variant, g):
            pos = pair_pos(shift, mask)
            if mask and not (mask & (mask - 1)):
                out[(seg, mask.bit_length() - 1)] = (cls, code, pos, mask)
            else:
                fields.append((seg, mask, cls, code))
                for b in range(8):
                    if mask >> b & 1:
                        out.setdefault((seg, b), (cls, code, None, mask))
    return out, fields


def legend(seg, bit):
    v = PANEL.get((seg, bit))
    if v is None:
        return None, "UNLISTED"
    return v[0], v[1]


def covered_bits(variant, seg):
    """How many DISTINCT bits of one segment the variant's list mentions."""
    g = group_of(variant, seg)
    bits = set()
    for (_c, _k, _s, mask) in records(variant, g):
        for b in range(8):
            if mask >> b & 1:
                bits.add(b)
    return bits


def fitted_bits(seg):
    return {b for b in range(8) if sw_of(seg, b) in FITTED_SW}


# ---------------------------------------------------------------------------
# the corroborations.  Each returns (name, ok, detail); each CAN fail.
def checks():
    out = []

    # C1  the three CP2 segments, against the manual's diode list
    for seg in (7, 8, 9):
        want = len(fitted_bits(seg))
        got2 = len(covered_bits(2, seg))
        got1 = len(covered_bits(1, seg))
        out.append(("CP2 segment %d: variant 2 covers %d bits, fitted %d"
                    % (seg, got2, want), got2 == want,
                    "variant 1 covers %d" % got1))
    out.append(("variant 1 disagrees on at least one CP2 segment",
                any(len(covered_bits(1, s)) != len(fitted_bits(s))
                    for s in (7, 8, 9)),
                "the control: if this passed for BOTH variants the test is empty"))

    # C2  segment 6 and segment 10 carry no switch on this panel
    out.append(("variant 2 sends segment 6 to a group above the 0x18 bound",
                group_of(2, 6) > GROUP_BOUND, "group 0x%02X" % group_of(2, 6)))
    out.append(("variant 2 sends segment 10 to a group above the bound",
                group_of(2, 10) > GROUP_BOUND, "group 0x%02X" % group_of(2, 10)))
    out.append(("variant 1 does NOT (it expects switches there)",
                group_of(1, 6) <= GROUP_BOUND and group_of(1, 10) <= GROUP_BOUND,
                "groups 0x%02X / 0x%02X" % (group_of(1, 6), group_of(1, 10))))

    m2, _f = compose(2)

    # C3  SW24 is the one CP1 position with no diode, and variant 2 skips it
    out.append(("variant 2 has no record for segment 2 bit 7 (SW24, no diode)",
                7 not in covered_bits(2, 2),
                "covered bits %s" % sorted(covered_bits(2, 2))))

    # C4  the five LCD rows: one code each, LEFT and RIGHT at opposite positions
    lcd = []
    for b in range(5):
        r = m2.get((3, b))          # CP1 column beside the LCD, right-hand side
        l = m2.get((9, b))          # CP2 column beside the LCD, left-hand side
        lcd.append((b, r, l))
    same_code = all(r and l and r[1] == l[1] for _b, r, l in lcd)
    opp_pos = all(r and l and r[2] is not None and l[2] is not None
                  and r[2] != l[2] for _b, r, l in lcd)
    out.append(("the five LCD rows share one code between the two columns",
                same_code, ", ".join("row%d=%02X/%02X" % (b, r[1], l[1])
                                     for b, r, l in lcd if r and l)))
    out.append(("and the two columns sit at OPPOSITE pair positions",
                opp_pos, ", ".join("row%d=%s/%s" % (b, r[2], l[2])
                                   for b, r, l in lcd if r and l)))

    # C5  -1 and +1 are one code with a direction bit, and the firmware
    #     special-cases exactly that code
    minus, plus = m2.get((3, 5)), m2.get((3, 6))
    out.append(("-1 and +1 are one code with a direction bit",
                bool(minus and plus) and minus[1] == plus[1]
                and minus[2] != plus[2],
                "%s / %s" % (minus, plus)))
    # prom_a 0xF86610 `cp C,0x0d`, PanelButton_Accept's only per-code arm
    out.append(("PanelButton_Accept special-cases that same code at 0xF86610",
                A(0xF86610, 3) == bytes.fromhex("cbcf0d")
                and minus is not None and minus[1] == 0x0D,
                A(0xF86610, 3).hex()))

    # C6  PAGE v / PAGE ^ are a pair too
    pv, pu = m2.get((2, 4)), m2.get((2, 5))
    out.append(("PAGE v and PAGE ^ are one code with a direction bit",
                bool(pv and pu) and pv[1] == pu[1] and pv[2] != pu[2],
                "%s / %s" % (pv, pu)))

    # C7  the eight soft-key columns: upper and lower share a code
    ok, det = True, []
    for col in range(8):
        seg, b = (4, 2 * col) if col < 4 else (5, 2 * (col - 4))
        lo, hi = m2.get((seg, b)), m2.get((seg, b + 1))
        if not (lo and hi and lo[1] == hi[1] and lo[2] != hi[2]):
            ok = False
        else:
            det.append("col%d=%02X" % (col + 1, lo[1]))
    out.append(("each soft-key column's two keys share one code", ok,
                ", ".join(det)))

    # C8  no control on this panel emits code 0x0E -- which is why round 11
    #     could not find a producer for UiEvent_RouteByCode's 0x0E arm
    codes = {v[1] for v in m2.values()}
    out.append(("no variant-2 control emits code 0x0E", 0x0E not in codes,
                "codes seen: %s" % " ".join("%02X" % c for c in sorted(codes))))

    # C9  the four sibling tables of the 0xFF3800 module answer to exactly the
    #     five LCD rows and EXIT -- the map's prediction, tested against the
    #     listing rather than against itself
    live = _live_indices()
    want = {0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0F}
    for t in ("Dispatch_FF3800", "Dispatch_FF3880", "Dispatch_FF3900",
              "Dispatch_FF3980"):
        got = live.get(t, set())
        out.append(("%s answers only to the LCD rows and EXIT" % t,
                    bool(got) and got <= want,
                    "live %s" % sorted("%02X" % i for i in got)))
    # C11  ★★ THE CONSUMER-SIDE TEST, and it is the strongest one here because
    #      it looks at what the CODE DOES, not at what the tables contain.  In
    #      each of the four sibling tables, slot 0x0F's handler is the same
    #      five-instruction shape: test bit 7 of the forwarded argument and, if
    #      it is CLEAR, write the screen-request pair (0x2070)/(0x2071) -- i.e.
    #      LEAVE FOR ANOTHER SCREEN.  That is what an EXIT key does, and nothing
    #      in the derivation of the map knew it.
    exits = {"Dispatch_FF3800": 0xFF43ED, "Dispatch_FF3880": 0xFF4741,
             "Dispatch_FF3900": 0xFF4FDF, "Dispatch_FF3980": 0xFF546F}
    shape = bytes.fromhex("ee0c0000" "9e0821" "d9cc8000" "6e0a")
    for t, a in sorted(exits.items()):
        got = A(a, len(shape))
        ok = (got == shape and A(a + 13, 3) == bytes.fromhex("f17020")
              and A(a + 18, 3) == bytes.fromhex("f17120"))
        out.append(("%s slot 0x0F requests a screen on bit 7 clear" % t, ok,
                    got.hex()))
    # C12  and the position it acts on is the ONLY one the map produces for
    #      code 0x0F: bit 7 of the delivered code is SET at pair position 0,
    #      and no wire puts code 0x0F at position 0.
    pos0f = {v[2] for v in m2.values() if v[0] == 0xA9 and v[1] == 0x0F}
    out.append(("code 0x0F exists at pair position 1 only -- the position the "
                "four handlers act on", pos0f == {1}, "positions: %s" % pos0f))

    # C10  ★ THE AGREEMENT TEST.  Rounds 11 and 12 reached a code->control map
    #      from prom_b's side and applied it to 131 labels there.  This one is
    #      composed from the wire map and the group lists on prom_a's side.  If
    #      the two disagree anywhere, ONE OF THEM IS WRONG and no name built on
    #      either is safe -- so the disagreement, not the agreement, is what
    #      this row is looking for.
    try:
        import prom_b_panel_names_round12 as R12
        want = dict(R12.SLOT_CONTROL)
    except Exception as exc:                       # pragma: no cover
        out.append(("round-12 SLOT_CONTROL is readable", False, repr(exc)))
        want = {}
    mine = {}
    for (_seg, _bit), (cls, code, _pos, _mask) in m2.items():
        if cls == 0xA9 and code in SHORT:
            mine[code] = SHORT[code]
    # round 12's 0x12 entry is that family's REMAPPED slot for raw code 0x1B and
    # says so in its own comment, so it is compared against 0x1B here.
    want = {(0x1B if k == 0x12 else k): v for k, v in want.items()}
    shared = sorted(set(want) & set(mine))
    dis = [k for k in shared if want[k] != mine[k]]
    out.append(("agrees with prom_b round 12's SLOT_CONTROL on all %d shared "
                "codes" % len(shared), not dis and len(shared) >= 15,
                "disagree: %s" % [(hex(k), want[k], mine[k]) for k in dis]))
    out.append(("this map covers codes round 12 does not (0x1E, 0x20)",
                0x1E in mine and 0x20 in mine,
                "extra: %s" % sorted(hex(k) for k in set(mine) - set(want))))
    return out


def _live_indices():
    """{table: {index, ...}} for the 32-entry control tables of prom_a's
    listing -- the entries that are NOT the table's own default target."""
    import asm_source
    lab = re.compile(r'^(Dispatch_[A-Za-z0-9_]+|ScreenDispatch_[A-Za-z0-9_]+):')
    ent = re.compile(r'^\t\.long 0x([0-9a-f]{8})\s*;\s*[0-9A-F]{6}\s*\[\s*(\d+)\]')
    tables, cur = collections.OrderedDict(), None
    for ln in asm_source.image_lines(ROOT, "prom_a/wsa1_prom_a.s",
                                     skip=("kernel/kernel.s",)):
        g = lab.match(ln)
        if g:
            cur = g.group(1)
            tables[cur] = []
            continue
        if cur is None:
            continue
        h = ent.match(ln)
        if h:
            tables[cur].append((int(h.group(2)), int(h.group(1), 16) & 0xFFFFFF))
        elif ln.strip() and not ln.lstrip().startswith(";"):
            cur = None
    out = {}
    for t, rows in tables.items():
        if len(rows) != 32:
            continue
        cnt = collections.Counter(a for _i, a in rows)
        default = cnt.most_common(1)[0][0]
        out[t] = {i for i, a in rows if a != default}
    return out


CODE_NAMES = {}          # filled by build_code_names()


def build_code_names():
    """{code: (short name, [legends], worst grade)} for the WSA1R panel."""
    m2, _f = compose(2)
    by = collections.defaultdict(list)
    for (seg, bit), (cls, code, pos, mask) in sorted(m2.items()):
        name, grade = legend(seg, bit)
        by[(cls, code)].append((seg, bit, pos, name, grade, mask))
    return by


# ★ THE SPELLING IS ROUND 12's, not this file's -- see the agreement check.
SHORT = {
    0x00: "SoftKeyCol1", 0x01: "SoftKeyCol2", 0x02: "SoftKeyCol3",
    0x03: "SoftKeyCol4", 0x04: "SoftKeyCol5", 0x05: "SoftKeyCol6",
    0x06: "SoftKeyCol7", 0x07: "SoftKeyCol8",
    0x08: "LcdKeyRow1", 0x09: "LcdKeyRow2", 0x0A: "LcdKeyRow3",
    0x0B: "LcdKeyRow4", 0x0C: "LcdKeyRow5",
    0x0D: "MinusPlus", 0x0F: "Exit", 0x10: "Page",
    0x1B: "NumberPad", 0x1E: "Compare", 0x20: "ModeSelect",
}


def show_map():
    by = build_code_names()
    print("SX-WSA1R (variant 2) -- 5-bit event code -> panel control")
    print("%-6s %-12s %-6s %s" % ("code", "short name", "grade", "controls"))
    for (cls, code) in sorted(by):
        rows = by[(cls, code)]
        grades = {g for _s, _b, _p, _n, g, _m in rows}
        worst = ("RULE" if "RULE" in grades else
                 "POSITION" if "POSITION" in grades else
                 "LEGEND" if "LEGEND" in grades else sorted(grades)[0])
        txt = "; ".join("%s%s" % (n, "" if p is None else " [pos %d]" % p)
                        for _s, _b, p, n, _g, _m in rows)
        print("%02X/%02X  %-12s %-6s %s"
              % (cls, code, SHORT.get(code, "-") if cls == 0xA9 else "-",
                 worst, txt))


def show_variant():
    print("VARIANT ADJUDICATION -- covered bits per segment vs the diode lists")
    print("%-4s %-10s %-16s %-16s" % ("seg", "fitted", "variant 1", "variant 2"))
    for seg in range(0, 12):
        f = sorted(fitted_bits(seg))
        print("%-4d %-10s %-16s %-16s"
              % (seg, f or "-",
                 "g%02X %s" % (group_of(1, seg), sorted(covered_bits(1, seg))),
                 "g%02X %s" % (group_of(2, seg), sorted(covered_bits(2, seg)))))


def show_checks():
    rows = checks()
    for name, ok, detail in rows:
        print("%-4s %-62s %s" % ("ok" if ok else "FAIL", name, detail))
    bad = sum(1 for _n, ok, _d in rows if not ok)
    print("\nFAILURES: %d of %d" % (bad, len(rows)))
    return bad


def main():
    argv = sys.argv[1:]
    if "--map" in argv:
        return show_map()
    if "--variant" in argv:
        return show_variant()
    if "--checks" in argv:
        return 1 if show_checks() else 0
    if "--selftest" in argv:
        bad = show_checks()
        # two invariants of the composition itself
        m1, _ = compose(1)
        m2, _ = compose(2)
        extra = [("both variants decode to a non-empty map",
                  bool(m1) and bool(m2), "%d / %d rows" % (len(m1), len(m2))),
                 ("the two maps DIFFER (else the adjudication is vacuous)",
                  m1 != m2, "")]
        for n, ok, d in extra:
            print("%-4s %-62s %s" % ("ok" if ok else "FAIL", n, d))
            bad += 0 if ok else 1
        print("TOTAL FAILURES: %d" % bad)
        return 1 if bad else 0
    show_variant()
    print()
    show_map()
    print()
    show_checks()
    return 0


if __name__ == "__main__":
    sys.exit(main())
