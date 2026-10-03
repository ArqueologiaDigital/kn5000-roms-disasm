#!/usr/bin/env python3
"""How far does the SOLVED panel chain reach into prom_b's 2,031 sub_XXXXXX?

QUESTION IT ANSWERS
    Round 8 left 124 routines of the 0xF7E2D8 span as sub_XXXXXX because "what
    distinguishes one handler from the next is THE BUTTON NUMBER" and no
    vocabulary existed for that number.  Round 9 solved the WIRE (segment/bit ->
    SW -> legend) and round 10 solved the EVENT (the group event lists).  This
    script walks the finished chain from the wire to the handler and asks, per
    routine, whether the chain names it -- and it answers with a number that is
    FAR below 124, because most of the chain's exits are refusals.

    ==> 26 of the 124 are named.  The other 98 keep sub_XXXXXX with the exact
    reason printed in their own header.  `--refusals` prints the arithmetic.

★★ THE ONE NEW MEASUREMENT THAT MADE THE 26 POSSIBLE: VARIANT 2 IS THIS PANEL
    Round 10 listed three holes and forbade naming across them.  Two of the
    three are properties of PanelWireGroupMap_Variant1 ALONE, and this script
    measures that rather than asserting it (`--variants`):

        variant 1   87 matrix bits claimed, 29 of them NOT FITTED,
                    3 pairs of byte-identical group lists (the collisions)
        variant 2   58 matrix bits claimed,  0 of them NOT FITTED,
                    0 pairs of byte-identical group lists

    58 is exactly the number of switches the service manual's two diode lists
    fit (round 9, `FITTED_SW`), and variant 2's set of (segment,bit) pairs is
    EQUAL to that set -- a bijection, not a containment.  Variant 1 claims 29
    positions with no switch behind them, among them all eight of segment 6 and
    the whole of a segment 10 that the manual's numbering does not reach.

    ⚠ WHAT THIS DOES AND DOES NOT LICENCE.  It does NOT prove variant 1 is
    never selected: the selector is `cp (0xC4),0x01` at 0xF8A84D and nothing
    here reads (0xC4).  What it licences is narrower and enough: for the four
    codes named below, the FITTED producers are the same under BOTH maps,
    because every extra producer variant 1 adds for them sits at a position
    with no switch.  The names are therefore variant-independent, and
    `--selftest` checks that per code rather than trusting the bijection.

THE CHAIN, per named routine, every link re-read from the ROM by this script
    SW (matrix segment,bit; service manual page 32; round 9's PANEL table)
      -> wire byte 0xC0|segment, sent by CP1 up the SC1 link
      -> PanelWireGroupMap_Variant2 (0xF8A189)            -> group id
      -> PanelGroupEventLists_Variant2 (0xF8B4B2) record  -> class, code, pair
      -> prom_a PanelButton_Route `and L,0x1f` (0xF861AE) -> 5-bit slot
      -> ButtonTable_<Screen> slot, one of the 32 tables at 0xF7D2D8
      -> the handler.

★ THE FOUR CODES THE CHAIN NAMES, and why each survives every refusal
  0x0F  EXIT.  Fitted producers over BOTH variants: SW32 only (segment 3 bit 7,
        legend EXIT).  Variant 1 sources it from segment 10 bit 7 = SW88, which
        does not exist.  It cannot arrive by the action tables' rewrite either
        (that adds 0x11 to a base, so it only ever produces 0x11..0x19).
        ★★ AND THE CONSUMER SIDE AGREES WITHOUT BEING ASKED: slot 0x0F is the
        ONLY one of the 32 slots that is a real routine in ALL 32 tables (32
        distinct handlers, 0 `ret` stubs), and in the 23-entry dispatch-table
        family its slot -- 15, after the remap -- is likewise the only one
        filled in all four.  Every screen must handle EXIT; nothing else is
        universal.  ★ And 20 of 20 in-span handlers open `bit 0x07,W` and run
        their body only when that bit is CLEAR, which is pair position 1 --
        the only position code 0x0F is ever delivered at.
  0x1B  the NUMBER PAD.  Fitted producers: the whole of segment 1 (SW9-SW16,
        legends "0".."7") as one 8-bit field, and segment 2 bits 0-3
        (SW17-SW20, "8", "9", "+/-", ENTER) as a 4-bit field.  Variant 1 sends
        those two wires as class 0xA8 code 0x08 -- a DIFFERENT EVENT CLASS,
        which never reaches a button table -- so under variant 1 slot 0x1B is
        dead and under variant 2 it is the pad.  No third producer exists, and
        0x1B - 0x11 = 0x0A is not a rewritable base.
        ★ FIVE INDEPENDENT WITNESSES: all five in-span slot-0x1B handlers are
        one-line forwarders whose body's FIRST instruction is `ld A,(0x2267)`
        followed by a compare against 0x0F -- and prom_b's own selector
        splitter sets its flag bit 5 for exactly the pair (index == 0x1B,
        (0x2267) == 0x0F) at 0xF5508C-0xF5509A.  Two unrelated objects, the
        same two constants.
  0x0D  the -1/+1 pair.  Fitted producers: SW30 ("-1") and SW31 ("+1"), segment
        3 bits 5 and 6, pair positions 0 and 1.  Variant 1 sources it from
        segment 10, unfitted.  ⚠ NOT the rotary DATA dial: that is code 0x21,
        wire 0xD7, and it never reaches a per-screen button table because
        PanelButton_Route splits `A == 0x21` off before the table lookup.
  0x10  PAGE.  Fitted producers: SW21 ("PAGE v", position 0) and SW22
        ("PAGE ^", position 1).  Variant 1 sources it from SW79/SW80, unfitted.
        ⚠ IN THE 32-ENTRY FAMILY THIS CODE IS REFUSED ANYWAY -- see below.

★ AND THE REFUSALS, each with the arithmetic (`--refusals`)
  * 0x00-0x03 (16 routines).  Every fitted producer is a SOFT KEY, under both
    maps -- but variant 1 puts code 0x00 on column 5 and variant 2 on column 1.
    The class is established and the COLUMN is not, and the column is the only
    thing that would distinguish four sibling names.  A bare column number in a
    name is the shape round 6 refused (Write3602_Index5).  REFUSED.
  * 0x04-0x07 (16 routines).  Round 10's COLLISION, and the fitted union proves
    it is not a variant artefact: under variant 1 code 0x04 is produced by
    SW25/SW26 (LCD RIGHT 1 and 2) AND by SW33/SW34 (SOFT KEY column 1), both
    fitted, from two byte-identical group lists.  Two different legends, one
    code.  REFUSED.
  * 0x08-0x0C (62 routines).  Coherent: the LCD side keys, row 1..5, with bit 7
    of the code selecting the LEFT column (SW73-SW77) over the RIGHT
    (SW25-SW29).  The class is solid; the ROW is a bare number and it is the
    only thing separating five siblings.  REFUSED, and this is the largest
    single refusal in the round.
  * 0x0E (1 routine).  NOBODY PRODUCES IT, in either map.  ★ And the ROM says
    so twice over: of the 1,024 slots in the 32 tables, slot 0x0E holds exactly
    ONE routine that is not a bare `ret`, and that routine's two branches both
    fall into the same `ret`; in the 23-entry family its slot (14) is the
    do-nothing stub in all four tables.  REFUSED.
  * 0x15 and the {base, base+0x11} twins (7 routines).  0x15 is reachable only
    as base 0x04 rewritten, and 0x04 is the colliding code.  REFUSED.
  * {0x10, 0x19} (2 routines).  Two routines sit at BOTH slots.  0x10 is PAGE;
    0x19 is what the action handlers 0xF8AE68/0xF8AEDB write when a base in
    0x00..0x07 is pressed while its partner is already down (`ld (XIX-1),0x19`
    at 0xF8AE8A/0xF8AEFD).  One routine, two unrelated controls.  REFUSED --
    which is why PAGE is named only in the 23-entry family, where its slot 16
    is not shared.

★ A CONFIRMATION OF ROUND 10 FROM THE CONSUMER SIDE, WHICH IT DID NOT HAVE
  Round 10 read `add (XIX-1),0x11` at 0xF8AE7E/0xF8AEF1 and predicted an
  ALTERNATE code set at base+0x11.  It never checked a consumer.  In the 32
  button tables, 13 routines are installed at exactly TWO slot indices and
  those two are exactly {n, n+0x11}; no routine is installed at two slots in
  any other relation except the {0x10, 0x19} pair above.  And prom_b's own
  selector splitter is the INVERSE of that rewrite: it folds 0x11..0x19 back
  onto 0..8 while recording the fold in flag bit 2, so the 23-entry tables need
  no alternate slots at all.  `--rewrite`.

★ AND THE ANSWER TO A QUESTION 18 HEADERS IN THIS FILE ASK
  Sixteen 32-entry tables in the 0xF65000 module carry "Unknown: what indexes
  it".  It is the panel button code, five bits: the reader at 0xF677D5 is
  `ld HL,BC / cp HL,0x1F / jr UGT,<ret> / sla 2,HL / ld XIX,<table> /
  ld XHL,(XIX+HL) / call XHL`, prom_a 0xF8BDC5's shape inlined.  ★ And they
  pass the same falsifiable test the 0xF7D2D8 family passes: in all 16, the
  five slots whose codes NO WIRE PRODUCES (0x0E, 0x1A, 0x1C, 0x1D, 0x1F) hold
  the module's own do-nothing stub -- 80 of 80 -- while slot 0x0F holds one
  shared handler in 15 of the 16, and that handler writes the screen-request
  byte (0x2070) exactly as the 20 named EXIT handlers do.

RUN
    python3 notes/prom_b_panel_names_round11.py              # everything
    python3 notes/prom_b_panel_names_round11.py --variants   # the bijection
    python3 notes/prom_b_panel_names_round11.py --chain      # code -> producers
    python3 notes/prom_b_panel_names_round11.py --refusals   # the arithmetic
    python3 notes/prom_b_panel_names_round11.py --rewrite    # the +0x11 twins
    python3 notes/prom_b_panel_names_round11.py --apply      # edit prom_b .s
    python3 notes/prom_b_panel_names_round11.py --selftest   # 73 checks
"""
import os
import re
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path, write_part  # noqa: E402
sys.path.insert(0, os.path.join(ROOT, "notes"))
import wave7_panel_event_index as EI          # noqa: E402
import wave7_panel_button_codes as BC         # noqa: E402

# ⚠ A WRITE THROUGH THIS NAME IS GUARDED AND WILL REFUSE while the text
# it is handed is the whole image: write_part() sees the master's
# .include lines disappear.  That refusal is correct and is not the fix.
# The fix for a RENAME is asm_source.edit_image(ROOT, <primary>, fn),
# which applies the transform to every constituent file; for a SPLICE it
# is asm_source.locate() on the block's anchor.  See notes/asm_source.py.
SRC_MASTER = os.path.join(ROOT, "prom_b/wsa1_prom_b.s")   # the WRITE path: write_part() guards it
SRC = image_path(ROOT, "prom_b/wsa1_prom_b.s")  # the READ path: the image, not the master
B_BASE = 0xF00000
A_BASE = 0xF80000
_b = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
_a = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()

TABLE0 = 0xF7D2D8          # first of the 32 per-screen button tables
NTABLE = 32
SPAN_LO, SPAN_HI = 0xF7E2D8, 0xF80000
NOOP_23 = 0xF42C70         # the thunk slot that is a bare `ret`


def bb(p):
    if B_BASE <= p < B_BASE + len(_b):
        return _b[p - B_BASE]
    if A_BASE <= p < A_BASE + len(_a):
        return _a[p - A_BASE]
    return None


def le32b(p):
    return struct.unpack_from("<I", _b, p - B_BASE)[0]


# ---------------------------------------------------------------------------
# LAYER 1 + LAYER 2, joined: which FITTED switches produce each 5-bit code
# ---------------------------------------------------------------------------
def producers():
    """code -> {variant: [(wire, seg, bit, mask, shift, pos, sw, legend, fitted)]}

    Only class 0xA9 (the button class) and only wires 0xC0-0xCF, which are the
    matrix columns; 0xD0-0xD7 are the pots and the rotary dial and have no
    (segment,bit).
    """
    out = {}
    for variant in (1, 2):
        for wire, g in sorted(EI.wire_map(variant).items()):
            if not (0xC0 <= wire <= 0xCF):
                continue
            seg = wire & 0x0F
            _, _, recs = EI.group_list(variant, g)
            for cls, code, shift, mask in recs:
                if cls != 0xA9:
                    continue
                pos = EI.position(mask, shift)
                for bit in range(8):
                    if not (mask & (1 << bit)):
                        continue
                    sw = BC.sw_of(seg, bit)
                    leg = BC.PANEL.get((seg, bit), (None, None))[0]
                    out.setdefault(code, {}).setdefault(variant, []).append(
                        (wire, seg, bit, mask, shift, pos, sw, leg, sw in BC.FITTED_SW))
    return out


def fitted_legends(code, prods):
    """The set of (SW, legend) that ACTUALLY EXIST and produce this code."""
    s = set()
    for variant, rows in prods.get(code, {}).items():
        for row in rows:
            if row[8]:
                s.add((row[6], row[7]))
    return sorted(s)


def variant_audit(variant):
    """(bits claimed, bits with no switch fitted, the SW set, identical lists)."""
    sws, unfitted = [], []
    for wire, g in sorted(EI.wire_map(variant).items()):
        if not (0xC0 <= wire <= 0xCF):
            continue
        seg = wire & 0x0F
        _, _, recs = EI.group_list(variant, g)
        for cls, code, shift, mask in recs:
            for bit in range(8):
                if mask & (1 << bit):
                    sw = BC.sw_of(seg, bit)
                    sws.append(sw)
                    if sw not in BC.FITTED_SW:
                        unfitted.append(sw)
    seen = {}
    for wire, g in sorted(EI.wire_map(variant).items()):
        _, _, recs = EI.group_list(variant, g)
        seen.setdefault(tuple(recs), []).append((wire, g))
    dupes = [v for v in seen.values() if len(v) > 1]
    return len(sws), len(unfitted), set(sws), dupes


# ---------------------------------------------------------------------------
# THE CONSUMER: the 32 tables at 0xF7D2D8 and the 23-entry dispatch family
# ---------------------------------------------------------------------------
def table_bases():
    return [TABLE0 + 0x80 * i for i in range(NTABLE)]


def table_owners():
    """Table index -> the screen suffix round 8 put on ButtonTable_<suffix>."""
    names = [m.group(1) for m in
             (re.match(r'^ButtonTable_(\S+):', l) for l in open(SRC))
             if m]
    if len(names) != NTABLE:
        raise RuntimeError("expected %d ButtonTable_ labels, found %d" % (NTABLE, len(names)))
    return names


def slot_map():
    """target address -> [(table index, slot), ...] over all 1,024 slots."""
    out = {}
    for ti, base in enumerate(table_bases()):
        for s in range(32):
            out.setdefault(le32b(base + 4 * s), []).append((ti, s))
    return out


def is_bare_ret(addr):
    return bb(addr) == 0x0E


def in_span_handlers():
    """address -> sorted set of slot indices, for the 124 real in-span targets."""
    out = {}
    for addr, hits in slot_map().items():
        if is_bare_ret(addr) or not (SPAN_LO <= addr < SPAN_HI):
            continue
        out[addr] = sorted({s for _, s in hits})
    return out


def dispatch_tables_23():
    """name -> 23 entries, from the .s (they are already framed and emitted)."""
    lines = open(SRC).read().split("\n")
    lab = re.compile(r'^(DispatchTable_[0-9A-F]+|PanelButtonTable_[A-Za-z0-9_]+):\s*$')
    ent = re.compile(r'^\s*\.long\s+0x([0-9A-Fa-f]+)\s*;\s*([0-9A-F]{6})\s+\[(\d+)\]')
    out, i = {}, 0
    while i < len(lines):
        m = lab.match(lines[i])
        if not m:
            i += 1
            continue
        name, j, ents = m.group(1), i + 1, []
        while j < len(lines):
            mm = ent.match(lines[j])
            if not mm:
                break
            ents.append(int(mm.group(1), 16))
            j += 1
        out[name] = ents
        i = j
    return out


def remap(raw):
    """prom_b sub_F55019's index remap, 0xF5501F-0xF5509F, re-stated.

    raw <= 0x10        -> raw            (untouched)
    0x11 <= raw <= 0x19 -> raw - 0x11    (0xF5506F-0xF55078)
    raw >= 0x1A         -> raw - 9       (0xF55081-0xF5508A)
    """
    if raw >= 0x1A:
        return raw - 9
    if 0x11 <= raw <= 0x19:
        return raw - 0x11
    return raw


def raw_of_slot23(slot):
    """The raw code that reaches slot `slot` of a 23-entry table, ignoring the
    rewritten aliases (which fold onto 0..8 and are marked in flag bit 2)."""
    return slot if slot <= 16 else slot + 9


def unproduced_codes(prods):
    """The 5-bit codes NOTHING can deliver -- no wire, and no rewrite either.

    A code absent from both variants' event lists is still reachable when the
    action handlers can WRITE it: 0x11..0x18 are bases 0x00..0x07 plus 0x11 and
    0x19 is their clamp (0xF8AE7E/0xF8AE8A and the 0xF8AEDB copies).  Excluding
    those is the difference between "no wire emits it" and "nothing delivers
    it", and only the second justifies expecting an empty table slot.
    """
    rew = {b + 0x11 for b in REWRITABLE_BASES()} | {0x19}
    return sorted(c for c in range(0x20) if c not in prods and c not in rew)


# ---------------------------------------------------------------------------
# THE NAMES THIS ROUND APPLIES
# ---------------------------------------------------------------------------
NAMED_SLOTS = {0x0F: "ExitKey", 0x1B: "NumberPadKey", 0x0D: "MinusPlusKey"}


def proposals():
    """[(addr, old label root, new label, slot, screen suffix)] for the span."""
    owners = table_owners()
    sm = slot_map()
    out = []
    for addr, slots in sorted(in_span_handlers().items()):
        if len(slots) != 1 or slots[0] not in NAMED_SLOTS:
            continue
        s = slots[0]
        tabs = sorted({ti for ti, ss in sm[addr] if ss == s})
        if len(tabs) != 1:
            continue                      # shared between screens: no screen name
        out.append((addr, "sub_%06X" % addr,
                    "%s_%s" % (NAMED_SLOTS[s], owners[tabs[0]]), s, owners[tabs[0]]))
    return out


# Names outside the span, in the 23-entry family, where the module IS named.
EXTRA_RENAMES = [
    # (old label, new label, why -- checked by --selftest)
    ("sub_F53683", "ExitKey_DrawbarScreen"),
    ("sub_F53641", "PageKey_DrawbarScreen"),
    ("sub_F55019", "PanelCode_ToSlotAndFlags"),
    ("DispatchTable_F54248", "PanelButtonTable_DrawbarScreen"),
]


# ---------------------------------------------------------------------------
# REPORTS
# ---------------------------------------------------------------------------
def print_variants():
    print("=== which wire map belongs to THIS panel (matrix wires 0xC0-0xCF only)")
    print("  %d switches are fitted, from the two diode lists on manual page 32"
          % len(BC.FITTED_SW))
    for v in (1, 2):
        n, unf, sws, dupes = variant_audit(v)
        print("  variant %d: %3d matrix bits, %2d with NO switch fitted, "
              "%2d distinct SW, set == FITTED_SW: %s, byte-identical lists: %d"
              % (v, n, unf, len(sws), sws == BC.FITTED_SW, len(dupes)))
        if unf:
            print("      unfitted positions claimed: %s"
                  % ", ".join("SW%d" % s for s in sorted(set(sws) - BC.FITTED_SW)))
        for d in dupes:
            print("      identical lists: %s"
                  % " == ".join("wire %02X/group %02X" % (w, g) for w, g in d))


def print_chain():
    prods = producers()
    print("=== every class-0xA9 code, and the FITTED switches that produce it")
    print("  code  verdict     fitted producers (union over BOTH wire maps)")
    for code in sorted(prods):
        fl = fitted_legends(code, prods)
        legs = {l for _, l in fl}
        if not fl:
            verdict = "NO SWITCH"
        elif code in NAMED_SLOTS:
            verdict = "NAMED"
        elif all("SOFT KEY" in (l or "") for l in legs):
            verdict = "class only"
        elif all("LCD" in (l or "") for l in legs):
            verdict = "row only"
        elif len({l.split()[0] for l in legs if l}) > 1:
            verdict = "COLLIDING"
        else:
            verdict = "-"
        print("   0x%02X  %-10s  %s" % (code, verdict,
              ", ".join("SW%d %s" % (s, l) for s, l in fl) or "(none fitted)"))
    print("  codes with no producer in either map: %s"
          % ", ".join("0x%02X" % c for c in unproduced_codes(prods)))


def print_refusals():
    hs = in_span_handlers()
    prods = producers()
    buckets = {}
    for addr, slots in hs.items():
        key = tuple(slots)
        buckets.setdefault(key, []).append(addr)
    named = {a for a, _, _, _, _ in proposals()}
    print("=== the 124 in-span handlers, by slot signature")
    tot_named = 0
    for key in sorted(buckets, key=lambda k: (-len(buckets[k]), k)):
        addrs = buckets[key]
        n = sum(1 for a in addrs if a in named)
        tot_named += n
        why = refusal_reason(key, prods)
        print("   slots %-9s %3d routines   %3d named   %s"
              % (",".join("%02X" % s for s in key), len(addrs), n, why))
    print("   ---- %d handlers, %d named by the chain, %d refused"
          % (len(hs), tot_named, len(hs) - tot_named))


def refusal_reason(slots, prods):
    if len(slots) == 1 and slots[0] in NAMED_SLOTS:
        return "NAMED %s" % NAMED_SLOTS[slots[0]]
    if len(slots) == 2 and slots[1] == slots[0] + 0x11:
        return "base 0x%02X and its base+0x11 twin" % slots[0]
    if slots == (0x10, 0x19):
        return "PAGE and the both-of-a-pair code 0x19: two unrelated controls"
    s = slots[0]
    if s in (0x15,):
        return "0x15 is base 0x04 rewritten, and 0x04 collides"
    if s <= 0x03:
        return "SOFT KEY, but the two maps disagree on the column"
    if s <= 0x07:
        return "COLLIDING: LCD RIGHT and SOFT KEY under variant 1"
    if 0x08 <= s <= 0x0C:
        return "LCD side key; the ROW is a bare number"
    if s == 0x0E:
        return "no wire produces code 0x0E, in either map"
    return "not reached by the chain"


def print_rewrite():
    hs = in_span_handlers()
    twins = [(a, s) for a, s in sorted(hs.items())
             if len(s) == 2 and s[1] == s[0] + 0x11]
    other = [(a, s) for a, s in sorted(hs.items()) if len(s) > 1
             and not (len(s) == 2 and s[1] == s[0] + 0x11)]
    print("=== routines installed at more than one slot of the 32 tables")
    print("  %d at exactly {n, n+0x11} -- the action tables' `add (XIX-1),0x11`"
          % len(twins))
    for a, s in twins:
        print("     0x%06X  {%02X, %02X}" % (a, s[0], s[1]))
    print("  %d in any other relation:" % len(other))
    for a, s in other:
        print("     0x%06X  {%s}" % (a, ", ".join("%02X" % x for x in s)))


def print_slots():
    print("=== the 32 slots of the 32 tables at 0xF7D2D8 (1,024 slots)")
    prods = producers()
    unp = set(unproduced_codes(prods))
    print("  slot  `ret` stubs  real handlers  distinct   producer")
    for s in range(32):
        stub = real = 0
        seen = set()
        for base in table_bases():
            v = le32b(base + 4 * s)
            if is_bare_ret(v):
                stub += 1
            else:
                real += 1
                seen.add(v)
        fl = fitted_legends(s, prods)
        tag = ("NO PRODUCER" if s in unp else
               (", ".join(sorted({l for _, l in fl})) if fl else
                "only via a rewritten base"))
        print("   0x%02X    %2d           %2d            %2d       %s"
              % (s, stub, real, len(seen), tag[:60]))


def main():
    if "--variants" in sys.argv:
        return print_variants()
    if "--chain" in sys.argv:
        return print_chain()
    if "--refusals" in sys.argv:
        return print_refusals()
    if "--rewrite" in sys.argv:
        return print_rewrite()
    if "--slots" in sys.argv:
        return print_slots()
    print_variants()
    print()
    print_chain()
    print()
    print_slots()
    print()
    print_refusals()
    print()
    print_rewrite()
    print()
    print("=== the names this round applies")
    for addr, old, new, slot, scr in proposals():
        print("   0x%06X  %-22s -> %s" % (addr, old, new))
    for old, new in EXTRA_RENAMES:
        print("   %-30s -> %s" % (old, new))


# ---------------------------------------------------------------------------
# APPLY: rewrite prom_b/wsa1_prom_b.s
# ---------------------------------------------------------------------------
WRAP = "; " + "-" * 69


def rec_addr(variant, group, want_code, want_mask):
    """Address of a group event-list record, re-read, never typed."""
    p, q, recs = EI.group_list(variant, group)
    for i, (cls, code, shift, mask) in enumerate(recs):
        if cls == 0xA9 and code == want_code and mask == want_mask:
            return p + 4 * i
    raise RuntimeError("no record for code %02X mask %02X" % (want_code, want_mask))


def producer_phrases(code):
    """Compact sentences naming the FITTED switches that produce `code`.

    Single-bit records are named switch by switch; a WHOLE-FIELD record (the
    number pad) is named as a run, because listing twelve keys one at a time
    says nothing the run does not.
    """
    prods = producers()
    rows, seen = [], set()
    for variant in (2, 1):
        groups = {}
        for wire, seg, bit, mask, shift, pos, sw, leg, fit in \
                prods.get(code, {}).get(variant, []):
            if fit:
                groups.setdefault((wire, seg, mask, shift, pos), []).append((bit, sw, leg))
        for (wire, seg, mask, shift, pos), members in sorted(groups.items()):
            members.sort()
            if len(members) == 1:
                bit, sw, leg = members[0]
                t = "SW%d %s (segment %d bit %d, wire 0x%02X, pair position %s)" % (
                    sw, leg, seg, bit, wire, pos if pos is not None else "-")
            else:
                t = ("SW%d..SW%d %s..%s (segment %d bits %d-%d, wire 0x%02X, one "
                     "%d-bit field, no pair position)" % (
                         members[0][1], members[-1][1], members[0][2], members[-1][2],
                         seg, members[0][0], members[-1][0], wire, len(members)))
            if t not in seen:
                seen.add(t)
                rows.append(t)
    return rows


def wrapc(prefix, text, width=78, cont=";           "):
    """Wrap into `; ` comment lines in the house style: an 11-space hanging
    indent, the same one `; Evidence: ` blocks in this file already use."""
    words = (prefix + " " + text).split()
    lines, cur = [], ""
    for w in words:
        cand = (cur + " " + w) if cur else w
        if len(cand) > width and cur:
            lines.append(cur)
            cur = cont + w
        else:
            cur = cand
    if cur:
        lines.append(cur)
    return lines


def reach_lines(slot):
    """The `Reached by:` block for one table slot."""
    ph = producer_phrases(slot)
    if ph:
        return wrapc("; Reached by: code 0x%02X from" % slot,
                     "; ".join(ph) + " -- then prom_a PanelButton_Route `and L,0x1f`"
                     " at 0xF861AE, then slot 0x%02X of the screen's button table."
                     % slot)
    if slot == 0x19:
        return wrapc("; Reached by: code 0x19, which no wire emits.",
                     "It is what the action handlers 0xF8AE68/0xF8AEDB write over a"
                     " base in 0x00..0x07 (`ld (XIX-1),0x19` at 0xF8AE8A and"
                     " 0xF8AEFD) on the arm reached when this code's bit is already"
                     " set in the held-code set (0x2252)/(0x2256) (`and XWA,XDE / jr"
                     " Z` at 0xF8AE7A) AND two left shifts of that bit leave zero"
                     " (`sla 0,XDE / sla 1,XDE / jr NZ` at 0xF8AE82).")
    if 0x11 <= slot <= 0x18:
        return wrapc("; Reached by: code 0x%02X, which no wire emits." % slot,
                     "It is base 0x%02X plus 0x11, written by the action handlers"
                     " 0xF8AE68/0xF8AEDB (`add (XIX-1),0x11` at 0xF8AE7E and"
                     " 0xF8AEF1) on the arm reached when this code's bit is already"
                     " set in the held-code set (0x2252)/(0x2256) -- `and XWA,XDE /"
                     " jr Z` at 0xF8AE7A." % (slot - 0x11))
    return wrapc("; Reached by: nothing.",
                 "No wire in either map emits code 0x%02X, and no rewrite"
                 " produces it either." % slot)


def header_for(addr, slots, owners, sm, named):
    """The comment block this round writes above one in-span handler."""
    scr_tabs = sorted({ti for ti, s in sm[addr]})
    screens = ", ".join(owners[t] for t in scr_tabs)
    out = [WRAP]
    if named:
        title = {0x0F: "the EXIT key", 0x1B: "the NUMBER PAD",
                 0x0D: 'the "-1" / "+1" key pair'}[slots[0]]
        out += wrapc("; %s --" % named,
                     "%s on the %s screen" % (title, owners[scr_tabs[0]]))
    else:
        out += wrapc("; sub_%06X --" % addr,
                     "panel button slot %s of %s"
                     % (" and ".join("0x%02X" % s for s in slots), screens))
    for s in slots:
        out += reach_lines(s)
    if named:
        out += wrapc("; Evidence:", EVIDENCE_NAMED[slots[0]])
    else:
        out += wrapc("; Unknown:", "NO NAME, and the reason is exact -- "
                     + REFUSAL_TEXT(slots, refusal_reason(tuple(slots), producers())))
        out += wrapc("; Evidence:", "the table slot and the screen above are re-read"
                     " from the ROM, the producers from PanelWireGroupMap_Variant1/2"
                     " and PanelGroupEventLists_Variant1/2, by"
                     " notes/prom_b_panel_names_round11.py --chain --refusals"
                     " --selftest.")
    out.append(WRAP)
    return out


EVIDENCE_NAMED = {
    0x0F: ("code 0x0F's ONLY fitted producer is SW32 EXIT, under BOTH wire maps"
           " -- variant 1 sources it from segment 10 bit 7 = SW88, a position no"
           " diode list fits -- and no rewrite can reach it, because the action"
           " handlers only add 0x11 to a base or clamp to 0x19. On the consumer"
           " side slot 0x0F is the ONLY one of the 32 slots that holds a real"
           " routine in ALL 32 tables (32 distinct handlers, 0 `ret` stubs); in"
           " the 23-entry dispatch family its slot 15 is filled in all four too,"
           " though there slots 1, 2, 4 and 5 are as well, so the universality"
           " argument is the 32-table one. This body opens `bit 0x07,W` and runs only when"
           " that bit is CLEAR, which is pair position 1 -- the only position code"
           " 0x0F is ever delivered at; 20 of 20 in-span EXIT handlers do the"
           " same. Re-derived by notes/prom_b_panel_names_round11.py --selftest."),
    0x1B: ("code 0x1B is emitted only by PanelGroupEventLists_Variant2, from the"
           " two number-pad wires, as WHOLE FIELDS with no pair position; variant"
           " 1 sends those same wires as class 0xA8 code 0x08, a different event"
           " class that never reaches a button table, so no other control can"
           " reach this slot under either map. 0x1B - 0x11 = 0x0A is not a"
           " rewritable base. ★ And the body this forwards to opens"
           " `ld A,(0x2267) / cp A,0x0f` -- the same two constants prom_b's own"
           " PanelCode_ToSlotAndFlags pairs at 0xF5508C-0xF5509A when it sets flag"
           " bit 5 for index 0x1B. All five in-span slot-0x1B handlers do it."
           " Re-derived by notes/prom_b_panel_names_round11.py --selftest."),
    0x0D: ("code 0x0D's only fitted producers are SW30 (-1) and SW31 (+1),"
           " segment 3 bits 5 and 6, at pair positions 0 and 1; variant 1 sources"
           " the same code from segment 10, unfitted. ⚠ This is NOT the rotary"
           " DATA dial: that is code 0x21 on wire 0xD7, which prom_a"
           " PanelButton_Route splits off (`A == 0x21`) before any table lookup."
           " ⚠ Both branches of this body reach the same `ret`, so this screen"
           " accepts the key and does nothing with it."
           " Re-derived by notes/prom_b_panel_names_round11.py --selftest."),
}


def REFUSAL_TEXT(slots, reason):
    s = slots[0]
    if len(slots) == 2 and slots[1] == s + 0x11:
        tail = (" This routine is installed at BOTH slot 0x%02X and slot 0x%02X,"
                " its base+0x11 alternate, so it is one routine for the first"
                " press and the repeat." % (s, slots[1]))
        if s <= 3:
            return ("every fitted producer is a SOFT KEY under both maps, but"
                    " variant 1 puts code 0x%02X on column %d and variant 2 on"
                    " column %d. The class is established and the COLUMN is not,"
                    " and the column is the only thing that would separate four"
                    " sibling names -- a bare number, the shape round 6 refused"
                    " (Write3602_Index5)." % (s, s + 5, s + 1)) + tail
        return ("COLLISION. Under variant 1 code 0x%02X is produced by two"
                " different legends -- an LCD-RIGHT key and a SOFT KEY -- from two"
                " byte-identical group lists, and both switches are fitted, so it"
                " is not a variant artefact." % s) + tail
    if tuple(slots) == (0x10, 0x19):
        return ("this routine is installed at slot 0x10 (PAGE v / PAGE ^) AND at"
                " slot 0x19, the code the action handlers write when a soft-key"
                " base in 0x00..0x07 is pressed with its partner already down"
                " (`ld (XIX-1),0x19` at 0xF8AE8A/0xF8AEFD). Two unrelated"
                " controls reach one routine, so neither names it.")
    if s == 0x15:
        return ("slot 0x15 is reachable only as base 0x04 rewritten (+0x11), and"
                " code 0x04 is the COLLIDING code: under variant 1 it is produced"
                " by SW25/SW26 (LCD RIGHT) and by SW33/SW34 (SOFT KEY), from two"
                " byte-identical group lists.")
    if s <= 0x03:
        return ("every fitted producer is a SOFT KEY under both maps, but variant"
                " 1 puts code 0x%02X on column %d and variant 2 on column %d. The"
                " class is established and the COLUMN is not, and the column is"
                " the only thing that would separate four sibling names -- a bare"
                " number, the shape round 6 refused (Write3602_Index5)."
                % (s, s + 5, s + 1))
    if s <= 0x07:
        return ("COLLISION. Under variant 1 code 0x%02X is produced by two"
                " different legends -- an LCD-RIGHT key and a SOFT KEY -- from two"
                " byte-identical group lists, and both switches are fitted. Round"
                " 10 forbade naming from a colliding code and the fitted union"
                " shows the collision is not a variant artefact." % s)
    if 0x08 <= s <= 0x0C:
        return ("the control CLASS is established -- the LCD side keys, with bit 7"
                " of the code selecting the LEFT column over the RIGHT -- but the"
                " five siblings differ only by ROW, and a bare row number in a"
                " name grades as content while stating nothing (round 6's refusal"
                " of Write3602_Index5). This is the largest single refusal of the"
                " round: 62 of the span's 124 button handlers.")
    if s == 0x0E:
        return ("NO WIRE PRODUCES CODE 0x0E, in either map, yet prom_a"
                " PanelButton_Route has an 0x0E arm. Of the 1,024 slots in the 32"
                " tables this is the only slot-0x0E entry that is not a bare"
                " `ret`, and both of its branches fall into the same `ret`; in the"
                " 23-entry dispatch family the corresponding slot 14 is the"
                " do-nothing stub in all four tables. The likely producers are the"
                " seven non-wire appenders at 0xF8A2D6..0xF8A3AE, which nobody has"
                " read.")
    return "the chain does not reach this slot."


BANNER_OLD = """; ⚠ 180 OF THE 210 ROUTINES KEEP sub_XXXXXX, AND THE REASON IS ONE FACT.
; The 32 tables at 0xF7D2D8 are indexed by the PANEL BUTTON NUMBER (round 7
; established that: two independent 5-bit masks over a 128-byte table).  So
; what distinguishes one handler from the next is a bare number, and a name
; built on it -- ScreenBtn_Quantize_11 -- would grade as content while
; stating nothing.  Round 6 refused exactly that shape (Write3602_Index5)
; and this block refuses it again.  The ROM names only THREE of the 32
; codes, in prom_a's PanelButton_Route: 0x0D the data dial, 0x0E and 0x0F.
; The service screen that would be the natural place for a switch list,
; Paint_PanelSwLedCheck, draws "Please push a any button." and no per-switch
; text.  There is nothing to map an index onto, so the gap is stated instead
; of filled.  Each handler's own Evidence line names its screen and index.
"""

BANNER_TEMPLATE = """; ★★ ROUND 11: THE BUTTON NUMBER NOW HAS A VOCABULARY, AND IT NAMES %(named)d OF
; THE %(total)d HANDLERS -- NOT %(total)d.  The chain is SW -> wire -> group ->
; event-list record -> 5-bit code -> table slot -> handler, and every link is
; read from the ROM by notes/prom_b_panel_names_round11.py.
;
; ★ WHICH WIRE MAP BELONGS TO THIS PANEL, measured, not assumed.  prom_a picks
; between two maps at 0xF8A851 (`cp (0xC4),0x01`; variant 1 on equal, variant 2
; otherwise).  Over the matrix wires 0xC0-0xCF, variant 2's event lists claim
; 58 matrix bits and the set of switches they name is EQUAL to the 58 the
; service manual's two diode lists fit -- a bijection.  Variant 1 claims 87,
; of which 29 sit at positions with no switch (all of segment 6, and a segment
; 10 the manual's numbering never reaches), and it has three pairs of
; byte-identical group lists where variant 2 has none.
; ⚠ That does NOT prove variant 1 is never selected -- nothing here reads
; (0xC4).  It licences something narrower: for the codes named below the
; FITTED producers are identical under both maps, because every extra producer
; variant 1 adds for them has no switch behind it.
;
; ★ THE FOUR CODES THAT SURVIVE EVERY REFUSAL
;   0x0F  EXIT (SW32).  Slot 0x0F is the ONLY one of the 32 slots that holds a
;         real routine in ALL 32 tables, and its 32 handlers are 32 DISTINCT
;         routines -- every screen must handle EXIT.  (In the 23-entry
;         dispatch family its slot 15 is also filled in all four tables, but
;         so are slots 1, 2, 4 and 5, so that family proves nothing extra.)
;   0x1B  the NUMBER PAD (SW9-SW20), delivered as whole fields.
;   0x0D  the -1/+1 pair (SW30, SW31).  ⚠ NOT the rotary DATA dial: that is
;         code 0x21 on wire 0xD7, split off before any table lookup.  The
;         paragraph this replaces called 0x0D "the data dial" and was wrong.
;   0x10  PAGE (SW21, SW22) -- named only in the 23-entry dispatch family,
;         because in THIS family its two handlers also sit at slot 0x19.
;
; ⚠ AND THE %(refused)d REFUSALS, each stated in its own header rather than left blank:
;   * %(lcd)d are the LCD SIDE KEYS (codes 0x08-0x0C).  The class is solid and the
;     five siblings differ only by ROW -- a bare number, which is the shape
;     round 6 refused (Write3602_Index5).
;   * %(coll)d are codes 0x04-0x07 and their base+0x11 twins -- round 10's
;     COLLISION.  Under variant 1 two byte-identical group lists send an
;     LCD-RIGHT key and a SOFT KEY to one code, and both switches are fitted,
;     so the collision is not a variant artefact.
;   * %(soft)d are codes 0x00-0x03 and their twins: SOFT KEYS under both maps,
;     but variant 1 puts code 0x00 on column 5 and variant 2 on column 1, and
;     the column is the only thing that would separate four sibling names.
;   * %(zeroE)d is code 0x0E, WHICH NO WIRE PRODUCES in either map.  Of the 1,024
;     slots here it is the only slot-0x0E entry that is not a bare `ret`, and
;     both its branches reach the same `ret`.
;   * %(page)d are the {0x10, 0x19} pair -- one routine serving PAGE and also
;     the code the action handlers write over a held soft-key base.
;
; ★ A CONFIRMATION ROUND 10 COULD NOT MAKE.  It read `add (XIX-1),0x11` at
; 0xF8AE7E and predicted an alternate code set; it never checked a consumer.
; Here, %(twins)d routines are installed at exactly two slots and those two are
; exactly {n, n+0x11}; no routine is installed at two slots in any other
; relation except the {0x10, 0x19} pair.
;
; The service screen that would be the natural place for a switch list,
; Paint_PanelSwLedCheck, draws "Please push a any button." and no per-switch
; text; the vocabulary came from the service manual's page 32 instead.
"""


BANNER_FIRST = "; ★★ ROUND 11: THE BUTTON NUMBER NOW HAS A VOCABULARY"
BANNER_LAST = "; text; the vocabulary came from the service manual's page 32 instead."


def banner_text():
    """The banner, with EVERY count computed from the tables, not typed.

    The first draft of this banner typed "16" for two buckets that measure 22
    and 11.  Numbers in prose go stale or were never right; these are formatted
    from the same census `--refusals` prints.
    """
    hs = in_span_handlers()
    named = {a for a, _, _, _, _ in proposals()}
    def n(pred):
        return sum(1 for a, s in hs.items() if pred(tuple(s)))
    lcd = n(lambda k: len(k) == 1 and 0x08 <= k[0] <= 0x0C)
    coll = n(lambda k: (k[0] in (4, 5, 6, 7)) or k == (0x15,))
    soft = n(lambda k: k[0] in (0, 1, 2, 3))
    page = n(lambda k: k == (0x10, 0x19))
    zeroE = n(lambda k: k == (0x0E,))
    twins = n(lambda k: len(k) == 2 and k[1] == k[0] + 0x11)
    total = len(hs)
    assert lcd + coll + soft + page + zeroE + len(named) == total, (
        "the banner's buckets must partition the %d handlers" % total)
    return BANNER_TEMPLATE % dict(lcd=lcd, coll=coll, soft=soft, page=page,
                                  zeroE=zeroE, twins=twins, total=total,
                                  named=len(named),
                                  refused=total - len(named))


def install_banner(txt):
    """Replace BANNER_OLD, or an already-installed banner, with a fresh one."""
    new = banner_text()
    if new in txt:
        return txt, 0
    if BANNER_OLD in txt:
        return txt.replace(BANNER_OLD, new, 1), 1
    lines = txt.split("\n")
    # ⚠ PREFIX match, not equality: an earlier draft of this banner wrapped its
    # first line differently, and an exact-line search silently found nothing
    # and left the stale numbers in place.
    i = next((k for k, l in enumerate(lines) if l.startswith(BANNER_FIRST)), None)
    j = next((k for k, l in enumerate(lines) if l == BANNER_LAST), None)
    if i is None or j is None or j < i:
        return txt, 0
    lines[i:j + 1] = new.rstrip("\n").split("\n")
    return "\n".join(lines), 1


F542A4_OLD = """; Evidence: read from the ROM.  If they are empty slots of
;           DispatchTable_F54248 that table would have 32 entries and end at
;           0xF542C8; nothing in the code bounds the index, so the layout
;           stops the table at 23 and this stays a separate object.
; Unknown: whether they belong to the table before them."""

F542A4_NEW = """; Evidence: read from the ROM.  If they were empty slots of
;           the table before them that table would have 32 entries and end at
;           0xF542C8.
; ⚠ CORRECTED, round 11.  This paragraph used to read "nothing in the code
;           bounds the index, so the layout stops the table at 23".  SOMETHING
;           BOUNDS IT: the dispatcher calls PanelCode_ToSlotAndFlags (0xF55019)
;           first, which rejects a raw index above 0x1F (`cp HL,0x001f` at
;           0xF55026) and then REMAPS what is left -- 0x11..0x19 lose 0x11
;           (0xF5506F-0xF55078) and 0x1A..0x1F lose 9 (0xF55081-0xF5508A) --
;           so what reaches `mul A,0x04` is 0..22.  Twenty-three slots is the
;           INDEX SPACE, not a layout accident, and these nine words are below
;           it.  Checked by notes/wave7-verify-probes/
;           wave7_r10_screen_table_entry_count.py and by
;           notes/prom_b_panel_names_round11.py --selftest.
; Unknown: whether they belong to the table before them."""

F67_OLD = "; Unknown: what indexes it, and what the handlers do."
F67_NEW = """; ⚠ ANSWERED, round 11: THE PANEL BUTTON CODE indexes it, five bits of it.
;          The reader is `ld HL,BC / cp HL,0x1F / jr UGT,<ret> / sla 2,HL /
;          ld XIX,<this table> / ld XHL,(XIX+HL) / call XHL` -- prom_a
;          0xF8BDC5's shape inlined, e.g. at 0xF677D5 for 0xF677EF -- and the
;          same five-bit mask prom_a PanelButton_Route applies at 0xF861AE.
;          ★ The tables pass a test that could have failed: in all 16 of this
;          module's 32-entry tables, the five slots whose codes NO WIRE EMITS
;          (0x0E, 0x1A, 0x1C, 0x1D, 0x1F) hold the module's own do-nothing
;          stub -- 80 of 80 -- while slot 0x0F, the EXIT key, holds one shared
;          handler in 15 of the 16, and that handler writes the screen-request
;          byte (0x2070) exactly as the twenty named ExitKey_* routines do.
;          notes/prom_b_panel_names_round11.py --selftest.
; Unknown: what the handlers do."""


# ---------------------------------------------------------------------------
# Four headers the round makes FALSE unless it also rewrites them.  Each anchor
# is a sentence that does not contain a renamed label, so the pair works on a
# clean tree and on a tree this script has already touched.
# ---------------------------------------------------------------------------
HEADER_FIXES = [
    # the two Drawbar handlers: their headers said the name IS the address
    ("""; Evidence: 0xF53683 is an instruction boundary of this transcription, re-
;           asserted on every emit, and the reference above names it.  That
;           is ALL the name rests on -- the name IS the address.
; Unknown: what the routine is FOR.  Left as sub_XXXXXX with the gap stated,
;          per this tree's rule that a stated gap beats a plausible guess.""",
     """; What it does: reads flag bit 0 of (0x28B0) -- the pair position
;          PanelCode_ToSlotAndFlags copied there from bit 7 of the code -- and on
;          the position-1 arm sets (0x2071) and requests screen 1 in (0x2070),
;          the screen-request pair prom_a documents at 0xF86055.
; Evidence: it is entry 15 of this screen's button table, and slot 15 is the
;           REMAPPED slot of raw panel code 0x0F, whose only fitted producer is
;           SW32 EXIT under both wire maps (segment 3 bit 7, service manual page
;           32).  The remap is PanelCode_ToSlotAndFlags, which leaves 0x00..0x10
;           alone; slot 15 is filled in all four of this file's 23-entry
;           dispatch tables and slot 0x0F is filled in all 32 of the 0xF7D2D8
;           button tables, which is what a key every screen must handle looks
;           like.  notes/prom_b_panel_names_round11.py --selftest.
; Unknown: which screen the request lands on -- (0x2070) is set to 1 here and
;          nothing in this file says what screen 1 is."""),

    ("""; Evidence: 0xF53641 is an instruction boundary of this transcription, re-
;           asserted on every emit, and the reference above names it.  That
;           is ALL the name rests on -- the name IS the address.
; Unknown: what the routine is FOR.  Left as sub_XXXXXX with the gap stated,
;          per this tree's rule that a stated gap beats a plausible guess.""",
     """; Evidence: it is entry 16 of this screen's button table, and slot 16 is the
;           REMAPPED slot of raw panel code 0x10, whose only fitted producers
;           are SW21 "PAGE v" (pair position 0) and SW22 "PAGE ^" (position 1),
;           segment 2 bits 4 and 5.  Variant 1 sources the same code from
;           SW79/SW80, which no diode list fits, so the pair is the same under
;           both wire maps.  The remap is PanelCode_ToSlotAndFlags, which leaves
;           0x00..0x10 alone.  notes/prom_b_panel_names_round11.py --selftest.
; ⚠ NOT named in the 0xF7D2D8 family.  There the two slot-0x10 handlers are
;           ALSO installed at slot 0x19, the code the action handlers write over
;           a soft-key base, so nothing there names them.  Here slot 16 is not
;           shared.
; Unknown: what (0x2896) holds -- the nibble this routine pages through."""),

    # the table's own entry-count paragraph
    ("""; Entry count: 23 is where the layout's chain rule stops, because entry 23
;              is a zero word and a zero is not an address.  ⚠ Nothing in
;              the code bounds the index, so 23 is a READING of the data,
;              not a measurement of the table.""",
     """; Entry count: 23, and ⚠ CORRECTED round 11 -- this paragraph used to end
;              "Nothing in the code bounds the index, so 23 is a READING of
;              the data, not a measurement of the table."  SOMETHING BOUNDS
;              IT.  DrawbarScreen_Dispatch calls PanelCode_ToSlotAndFlags
;              (0xF55019) before `mul A,4`, and that routine rejects a raw
;              index above 0x1F (`cp HL,0x001f` at 0xF55026) and then folds
;              what is left -- 0x11..0x19 lose 0x11, 0x1A..0x1F lose 9 -- so
;              the index space really is 0..22.  ★ And the table agrees: the
;              five slots whose raw codes NOTHING delivers (14, 17, 19, 20,
;              22 <- codes 0x0E, 0x1A, 0x1C, 0x1D, 0x1F) hold the default
;              thunk here and in all four of this file's 23-entry tables --
;              20 of 20 -- while slot 15, raw code 0x0F, the EXIT key, is
;              filled in all four.  notes/prom_b_panel_names_round11.py
;              --selftest."""),

    # the splitter itself
    ("""; Called from: not yet traced to a specific caller
; Inputs:  (XIZ+8) = 16-bit index, (XIZ+0x0A) = 16-bit flags""",
     """; Called from: thunk T_F42C74 (0xF42C74), which four screen-module
;              dispatchers call before `mul A,4 / add XWA,<their table>`:
;              sub_F0F17C (0xF0F194), sub_F12334 (0xF12347), ScreenButton_CodeAD and
;              DrawbarScreen_Dispatch (0xF5303D).  prom_a's Screen_*_Button
;              methods reach it the same way.
; Inputs:  (XIZ+8) = 16-bit index, (XIZ+0x0A) = 16-bit flags"""),

    ("""; Unknown:  what the index enumerates, and what 0x208C and 0x2267 hold.""",
     """; ★ WHAT THE INDEX ENUMERATES, answered round 11: it is the PANEL BUTTON
;           CODE, the five bits prom_a PanelButton_Route masks out at 0xF861AE.
;           This routine is the far end of the panel chain, and each flag bit
;           says which link the event came down:
;             bit 0 = the PAIR POSITION -- bit 7 of the code byte, which selects
;                     which member of a two-switch pair moved;
;             bit 2 = the event was REWRITTEN by the action handlers 0xF8AE68/
;                     0xF8AEDB (`add (XIX-1),0x11`), and the fold that sets it
;                     is the exact inverse of that rewrite;
;             bit 5 = the number-pad code 0x1B with (0x2267) == 0x0F, the same
;                     two constants the five number-pad handlers in the 0xF7E2D8
;                     span open with (`ld A,(0x2267) / cp A,0x0f`).
;           So 0..22 is a SLOT, not a code: the 23-entry dispatch tables are not
;           indexed by the raw event code.
;           notes/prom_b_panel_names_round11.py --selftest;
;           notes/wave7_panel_event_index.py; notes/wave7_panel_button_codes.py.
; Unknown:  what 0x208C and 0x2267 hold."""),

    ('; Entry count: 23, and it is NOT a byte extent divided by four.  The chain\n;              rule that finds it stops at the first word that is not an\n;              0x00F0xxxx-0x00F7xxxx address; that word is at 0xF13659.\n;              Entry 22, the last, is 0x00F42C70.',
     "; Entry count: 23, and it is NOT a byte extent divided by four.  The chain\n;              rule that finds it stops at the first word that is not an\n;              0x00F0xxxx-0x00F7xxxx address; that word is at 0xF13659.\n;              Entry 22, the last, is 0x00F42C70.\n;              ★ AND SOMETHING BOUNDS THE INDEX, round 11: the dispatcher\n;              calls PanelCode_ToSlotAndFlags (0xF55019) through T_F42C74\n;              before `mul A,4`, and that routine rejects a raw index above\n;              0x1F (`cp HL,0x001f` at 0xF55026) and folds what is left --\n;              0x11..0x19 lose 0x11, 0x1A..0x1F lose 9 -- so the index space\n;              is 0..22 and 23 is a MEASUREMENT, not only a reading.  ★ The\n;              table agrees: the five slots whose raw codes NOTHING delivers\n;              (14, 17, 19, 20, 22 <- panel codes 0x0E, 0x1A, 0x1C, 0x1D,\n;              0x1F) hold the default thunk here, and in all four of this\n;              file's 23-entry tables -- 20 of 20.\n;              notes/prom_b_panel_names_round11.py --selftest."),
    ('; Entry count: 23, and it is NOT a byte extent divided by four.  The chain\n;              rule that finds it stops at the first word that is not an\n;              0x00F0xxxx-0x00F7xxxx address; that word is at 0xF139AB.\n;              Entry 22, the last, is 0x00F42C70.',
     "; Entry count: 23, and it is NOT a byte extent divided by four.  The chain\n;              rule that finds it stops at the first word that is not an\n;              0x00F0xxxx-0x00F7xxxx address; that word is at 0xF139AB.\n;              Entry 22, the last, is 0x00F42C70.\n;              ★ AND SOMETHING BOUNDS THE INDEX, round 11: the dispatcher\n;              calls PanelCode_ToSlotAndFlags (0xF55019) through T_F42C74\n;              before `mul A,4`, and that routine rejects a raw index above\n;              0x1F (`cp HL,0x001f` at 0xF55026) and folds what is left --\n;              0x11..0x19 lose 0x11, 0x1A..0x1F lose 9 -- so the index space\n;              is 0..22 and 23 is a MEASUREMENT, not only a reading.  ★ The\n;              table agrees: the five slots whose raw codes NOTHING delivers\n;              (14, 17, 19, 20, 22 <- panel codes 0x0E, 0x1A, 0x1C, 0x1D,\n;              0x1F) hold the default thunk here, and in all four of this\n;              file's 23-entry tables -- 20 of 20.\n;              notes/prom_b_panel_names_round11.py --selftest."),
    ('; Unknown: what indexes it.  15 of the 23 slots being the default stub says\n;          the index space is sparse, but nothing decoded here gives its\n;          bound.',
     '; ⚠ ANSWERED round 11, and the old text -- "nothing decoded here gives its\n;          bound" -- is struck.  The PANEL BUTTON CODE indexes it, through\n;          PanelCode_ToSlotAndFlags (0xF55019, thunk T_F42C74), which the\n;          reader calls before `mul A,4`: it rejects a raw index above 0x1F\n;          and folds 0x11..0x19 onto 0..8 and 0x1A..0x1F onto 17..22, so the\n;          index space is 0..22.  ★ And the sparseness has a cause: the five\n;          slots whose raw codes NOTHING delivers (14, 17, 19, 20, 22 <-\n;          codes 0x0E, 0x1A, 0x1C, 0x1D, 0x1F) are the default stub here and\n;          in all four of this file\'s 23-entry tables, 20 of 20, while slot\n;          15 -- the EXIT key, raw code 0x0F -- is filled in all four.\n;          notes/prom_b_panel_names_round11.py --selftest.\n; Unknown: what the handlers do.'),

]


def apply_header_fixes(txt):
    """Replace each stale paragraph with its corrected one, ONCE.

    ⚠ Several of these corrections APPEND to the paragraph they fix, so the
    replacement's own output still contains its anchor.  Without the `new not
    in txt` guard a second --apply appended the correction a second time, and
    it did: four copies of one paragraph, caught by re-running --apply and
    diffing.  Idempotence is checked, not assumed.
    """
    n = 0
    for old, new in HEADER_FIXES:
        if new in txt:
            continue
        if old in txt:
            txt = txt.replace(old, new, 1)
            n += 1
    return txt, n

def verified_f67_tables():
    """The 32-entry tables of the 0xF65000 module this script actually checked.

    A table qualifies only if it has 32 entries, its commonest entry is the
    module's 0xF675CB `ret` stub, and all five slots whose codes nothing can
    deliver hold that stub.  Fifteen OTHER tables in this file carry the same
    "Unknown: what indexes it" line and are NOT touched: nobody has checked
    them, and answering a question for an object you did not measure is how
    this tree earns retractions.
    """
    unp = set(unproduced_codes(producers()))
    out = set()
    for n, e in dispatch_tables_23().items():
        if len(e) != 32 or max(set(e), key=e.count) != 0xF675CB:
            continue
        if all(e[s] == 0xF675CB for s in unp):
            out.add(n)
    return out


def apply_edits():
    txt = open(SRC).read()
    lines = txt.split("\n")
    owners = table_owners()
    sm = slot_map()
    props = {a: (new, slot) for a, _, new, slot, _ in proposals()}
    hs = in_span_handlers()

    # Index every label line BY THE ADDRESS OF THE INSTRUCTION UNDER IT, not by
    # its name: a previous run may already have renamed it, and keying on the
    # name made --apply crash the first time a name was revised.
    labre = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):\s*$')
    addrre = re.compile(r';\s*([0-9A-F]{6})\b')
    where = {}
    for i, l in enumerate(lines):
        if not labre.match(l):
            continue
        for k in range(i + 1, min(i + 3, len(lines))):
            m = addrre.search(lines[k])
            if m:
                where.setdefault(int(m.group(1), 16), i)
                break

    edits = []                      # (start, end, replacement lines)
    for addr, slots in sorted(hs.items()):
        name = "sub_%06X" % addr
        new = props.get(addr, (None, None))[0]
        cur = where.get(addr)
        if cur is None:
            raise RuntimeError("no label line for 0x%06X" % addr)
        j = cur - 1
        while j >= 0 and lines[j].startswith(";"):
            j -= 1
        blk = header_for(addr, slots, owners, sm, new)
        edits.append((j + 1, cur, blk + [(new or name) + ":"]))

    for start, end, repl in sorted(edits, reverse=True):
        lines[start:end + 1] = repl
    txt = "\n".join(lines)

    txt, n_banner = install_banner(txt)
    n_542 = txt.count(F542A4_OLD)
    if n_542:
        txt = txt.replace(F542A4_OLD, F542A4_NEW)
    # ⚠ 31 headers in this file carry F67_OLD; only the SIXTEEN whose table this
    # script actually VERIFIED (32 entries, the 0xF675CB stub, and the five
    # unproduced-code slots holding it) may have it answered.  Replacing all 31
    # would assert a reader for fifteen tables nobody checked.
    verified = verified_f67_tables()
    tl = txt.split("\n")
    labre = re.compile(r'^(DispatchTable_[0-9A-F]+):\s*$')
    n_f67 = 0
    for i, l in enumerate(tl):
        if l != F67_OLD:
            continue
        j = i + 1
        while j < len(tl) and (tl[j].startswith(";") or tl[j].strip() == ""):
            j += 1
        m = labre.match(tl[j]) if j < len(tl) else None
        if m and m.group(1) in verified:
            tl[i] = F67_NEW
            n_f67 += 1
    txt = "\n".join(tl)
    txt, n_hdr = apply_header_fixes(txt)

    # ⚠ THE RENAMES RUN LAST ON PURPOSE.  When they ran first they renamed
    # DispatchTable_F54248 inside the Table_F542A4 paragraph this round has to
    # correct, and the correction then matched nothing and silently did not
    # happen.  Order is part of the edit, so it is stated here.
    for old, new in EXTRA_RENAMES:
        txt = re.sub(r'\b%s\b' % re.escape(old), new, txt)

    write_part(SRC_MASTER, txt)
    print("applied: %d in-span headers rewritten, %d of them renamed;" % (len(hs), len(props)))
    print("         %d extra renames; banner %d; Table_F542A4 %d; F67 headers %d;"
          " header fixes %d"
          % (len(EXTRA_RENAMES), n_banner, n_542, n_f67, n_hdr))
    return 0


# ---------------------------------------------------------------------------
_ok = _fail = 0


def ck(desc, cond, extra=""):
    global _ok, _fail
    print(("  ok   " if cond else "  FAIL ") + desc + (("   " + extra) if extra else ""))
    if cond:
        _ok += 1
    else:
        _fail += 1


def selftest():
    global _ok, _fail
    prods = producers()
    owners = table_owners()

    # --- layer 1 / layer 2 join --------------------------------------------
    n1, u1, s1, d1 = variant_audit(1)
    n2, u2, s2, d2 = variant_audit(2)
    ck("variant 2 claims 58 matrix bits", n2 == 58, "got %d" % n2)
    ck("variant 2 claims ZERO unfitted positions", u2 == 0, "got %d" % u2)
    ck("variant 2's switch set EQUALS the 58 fitted switches", s2 == BC.FITTED_SW)
    ck("variant 2 has no byte-identical group lists", d2 == [], "got %d" % len(d2))
    ck("variant 1 claims 87 matrix bits", n1 == 87, "got %d" % n1)
    ck("variant 1 claims 29 unfitted positions", u1 == 29, "got %d" % u1)
    ck("variant 1 has 3 byte-identical group-list pairs", len(d1) == 3, "got %d" % len(d1))
    ck("the variant selector is `cp (0xC4),0x01` at 0xF8A851",
       _a[0xF8A851 - A_BASE:0xF8A855 - A_BASE] == bytes([0xC0, 0xC4, 0x3F, 0x01]))

    # --- the four named codes ----------------------------------------------
    ck("code 0x0F's fitted producers are SW32 EXIT and nothing else",
       fitted_legends(0x0F, prods) == [(32, "EXIT")], str(fitted_legends(0x0F, prods)))
    ck("code 0x0D's fitted producers are exactly SW30 -1 and SW31 +1",
       fitted_legends(0x0D, prods) == [(30, "-1"), (31, "+1")])
    ck("code 0x10's fitted producers are exactly SW21 PAGE v and SW22 PAGE ^",
       fitted_legends(0x10, prods) == [(21, "PAGE v"), (22, "PAGE ^")])
    ck("code 0x1B's fitted producers are the twelve number-pad keys SW9..SW20",
       [s for s, _ in fitted_legends(0x1B, prods)] == list(range(9, 21)))
    ck("code 0x04's fitted producers span TWO legends (the collision)",
       len({l.split()[0] for _, l in fitted_legends(0x04, prods)}) > 1,
       str(fitted_legends(0x04, prods)))
    ck("code 0x0E has no producer at all", 0x0E not in prods)
    ck("the codes with no producer are 0x0E,0x1A,0x1C,0x1D,0x1F",
       unproduced_codes(prods) == [0x0E, 0x1A, 0x1C, 0x1D, 0x1F],
       str(["%02X" % c for c in unproduced_codes(prods)]))
    ck("no rewrite can reach 0x0F, 0x0D or 0x1B (base+0x11 >= 0x11, clamp = 0x19)",
       all(c < 0x11 or c == 0x1B for c in (0x0F, 0x0D, 0x1B)) and 0x1B - 0x11 == 0x0A
       and 0x0A not in REWRITABLE_BASES())

    # --- the 32-table consumer ---------------------------------------------
    bases = table_bases()
    ck("the 32 button tables run 0xF7D2D8..0xF7E2D7, last base 0xF7E258",
       bases[-1] == 0xF7E258 and bases[-1] + 0x80 == SPAN_LO)
    ck("every one of the 1,024 slots is a ROM address", all(
        0xF00000 <= le32b(b + 4 * s) <= 0xFFFFFF for b in bases for s in range(32)))
    filled = {s: sum(1 for b in bases if not is_bare_ret(le32b(b + 4 * s)))
              for s in range(32)}
    ck("slot 0x0F is filled in all 32 tables", filled[0x0F] == 32, "got %d" % filled[0x0F])
    ck("slot 0x0F is the ONLY slot filled in all 32 tables",
       [s for s in range(32) if filled[s] == 32] == [0x0F])
    ck("slot 0x0F's 32 handlers are 32 DISTINCT routines",
       len({le32b(b + 4 * 0x0F) for b in bases}) == 32)
    empty = [s for s in range(32) if filled[s] == 0]
    ck("the slots with no handler in any table are 0x1A,0x1C,0x1D,0x1E,0x1F",
       empty == [0x1A, 0x1C, 0x1D, 0x1E, 0x1F], str(["%02X" % s for s in empty]))
    ck("slot 0x0E holds exactly one non-`ret` routine in 1,024 slots",
       filled[0x0E] == 1, "got %d" % filled[0x0E])
    ck("that one slot-0x0E routine reaches its `ret` on both branches",
       _b[0xF7E758 - B_BASE:0xF7E760 - B_BASE] ==
       bytes([0xC8, 0x33, 0x07, 0x6E, 0x02, 0x68, 0x00, 0x0E]))
    hs = in_span_handlers()
    ck("124 real handlers live in 0xF7E2D8-0xF80000", len(hs) == 124, "got %d" % len(hs))

    # --- the twenty EXIT handlers ------------------------------------------
    ex = sorted(a for a, s in hs.items() if s == [0x0F])
    ck("20 of them are slot-0x0F-only", len(ex) == 20, "got %d" % len(ex))
    ck("all 20 open `bit 0x07,W` (c8 33 07)",
       all(_b[a - B_BASE:a - B_BASE + 3] == bytes([0xC8, 0x33, 0x07]) for a in ex))
    ck("all 20 run their body only when bit 7 is CLEAR = pair position 1",
       all(_b[a - B_BASE + 3] in (0x6E, 0x66) for a in ex))
    ck("the LAST of the 20, 0xF7FDDD, is TRANSP0SE's and reads `jr NZ`",
       ex[-1] == 0xF7FDDD and _b[ex[-1] - B_BASE + 3] == 0x6E)
    ck("each of the 20 is reached from exactly ONE of the 32 tables",
       all(len({t for t, s in slot_map()[a] if s == 0x0F}) == 1 for a in ex))

    # --- the five NUMBER PAD handlers --------------------------------------
    npd = sorted(a for a, s in hs.items() if s == [0x1B])
    ck("5 handlers are slot-0x1B-only", len(npd) == 5, "got %d" % len(npd))
    ok = True
    for a in npd:
        op = _b[a - B_BASE]
        if op == 0x1E:              # calr rel16
            tgt = a + 3 + int.from_bytes(_b[a - B_BASE + 1:a - B_BASE + 3], "little", signed=False)
            tgt &= 0xFFFFFF
        else:
            ok = False
            break
        if _b[tgt - B_BASE:tgt - B_BASE + 4] != bytes([0xC1, 0x67, 0x22, 0x21]):
            ok = False
    ck("all five forward to a body opening `ld A,(0x2267)`", ok)
    ck("the LAST of the five is 0xF7FDB2 (TRANSP0SE)", npd[-1] == 0xF7FDB2)
    ck("PanelCode_ToSlotAndFlags pairs 0x1B with (0x2267)==0x0F at 0xF5508C",
       _b[0xF5508C - B_BASE:0xF55098 - B_BASE] ==
       bytes([0xC1, 0xB1, 0x28, 0x3F, 0x1B, 0x6E, 0x0A,
              0xC1, 0x67, 0x22, 0x3F, 0x0F]))

    # --- the remap, and the +0x11 rewrite it inverts ------------------------
    ck("the remap bound is `cp HL,0x001f` at 0xF55026",
       _b[0xF55026 - B_BASE:0xF5502A - B_BASE] == bytes([0xDB, 0xCF, 0x1F, 0x00]))
    ck("remap folds 0x11..0x19 onto 0..8", [remap(r) for r in range(0x11, 0x1A)] == list(range(9)))
    ck("remap folds 0x1A..0x1F onto 17..22", [remap(r) for r in range(0x1A, 0x20)] == list(range(17, 23)))
    ck("remap leaves 0x00..0x10 alone", [remap(r) for r in range(0x11)] == list(range(0x11)))
    ck("the rewrite `add (XIX+0xff),0x11` sits at 0xF8AE7E and 0xF8AEF1",
       _a[0xF8AE7E - A_BASE:0xF8AE82 - A_BASE] == bytes([0x8C, 0xFF, 0x38, 0x11]) and
       _a[0xF8AEF1 - A_BASE:0xF8AEF5 - A_BASE] == bytes([0x8C, 0xFF, 0x38, 0x11]))
    ck("the clamp `ld (XIX+0xff),0x19` sits at 0xF8AE8A and 0xF8AEFD",
       _a[0xF8AE8A - A_BASE:0xF8AE8E - A_BASE] == bytes([0xBC, 0xFF, 0x00, 0x19]) and
       _a[0xF8AEFD - A_BASE:0xF8AF01 - A_BASE] == bytes([0xBC, 0xFF, 0x00, 0x19]))
    ck("only 0xF8AE68/0xF8AEDB rewrite, and they serve only bases 0x00-0x07",
       REWRITABLE_BASES() == set(range(8)), str(sorted(REWRITABLE_BASES())))
    twins = [(a, s) for a, s in sorted(hs.items()) if len(s) == 2 and s[1] == s[0] + 0x11]
    other = [(a, s) for a, s in sorted(hs.items())
             if len(s) > 1 and not (len(s) == 2 and s[1] == s[0] + 0x11)]
    ck("13 in-span routines sit at exactly {n, n+0x11}", len(twins) == 13, "got %d" % len(twins))
    ck("the only other multi-slot routines are the two at {0x10, 0x19}",
       [s for _, s in other] == [[0x10, 0x19], [0x10, 0x19]], str(other))
    ck("the LAST twin's slots really differ by 0x11",
       twins[-1][1][1] - twins[-1][1][0] == 0x11)

    # --- the 23-entry dispatch family --------------------------------------
    d23 = {n: e for n, e in dispatch_tables_23().items() if len(e) == 23}
    ck("there are four 23-entry DispatchTables in prom_b", len(d23) == 4, str(sorted(d23)))
    unp = set(unproduced_codes(prods))
    checks = sum(1 for e in d23.values() for j in range(23) if raw_of_slot23(j) in unp)
    good = sum(1 for e in d23.values() for j in range(23)
               if raw_of_slot23(j) in unp and e[j] == NOOP_23)
    ck("every slot of an unproduced code is the do-nothing stub, in all four",
       checks == good == 20, "%d of %d" % (good, checks))
    ck("slot 15 (raw 0x0F, EXIT) is filled in all four",
       all(e[15] != NOOP_23 for e in d23.values()))
    ck("slots 1, 2, 4, 5 and 15 are the ones filled in all four -- 15 is NOT alone",
       [j for j in range(23) if all(e[j] != NOOP_23 for e in d23.values())]
       == [1, 2, 4, 5, 15],
       str([j for j in range(23) if all(e[j] != NOOP_23 for e in d23.values())]))
    ck("the LAST slot of the LAST table (F54248[22], raw 0x1F) is the stub",
       d23["PanelButtonTable_DrawbarScreen" if "PanelButtonTable_DrawbarScreen" in d23
           else "DispatchTable_F54248"][22] == NOOP_23)

    # --- the 0xF65000 module's 32-entry family ------------------------------
    d32 = {n: e for n, e in dispatch_tables_23().items() if len(e) == 32}
    ck("sixteen 32-entry DispatchTables carry the 0xF675CB stub",
       len([n for n, e in d32.items() if max(set(e), key=e.count) == 0xF675CB]) == 16)
    tot = good = 0
    for n, e in d32.items():
        if max(set(e), key=e.count) != 0xF675CB:
            continue
        for s in unp:
            tot += 1
            good += (e[s] == 0xF675CB)
    ck("their unproduced-code slots are the stub, 80 of 80", tot == good == 80,
       "%d of %d" % (good, tot))
    ck("slot 0x0F holds ONE shared handler 0xF67696 in 15 of the 16",
       sum(1 for n, e in d32.items()
           if max(set(e), key=e.count) == 0xF675CB and e[0x0F] == 0xF67696) == 15)
    ck("0xF67696 opens `bit 0x07,W` and writes (0x2070), like the named ExitKeys",
       _b[0xF67696 - B_BASE:0xF67699 - B_BASE] == bytes([0xC8, 0x33, 0x07]) and
       bytes([0xF1, 0x70, 0x20]) in _b[0xF67696 - B_BASE:0xF67696 - B_BASE + 0x20])
    ck("the 0xF677D5 reader masks the index to five bits, prom_a 0xF8BDC5's shape",
       _b[0xF677D7 - B_BASE:0xF677DB - B_BASE] == bytes([0xDB, 0xCF, 0x1F, 0x00]))

    # --- what --apply must find, and what it must leave behind -------------
    src = open(SRC).read()
    ck("every proposed new label is unused so far, or already applied",
       all(src.count("\n" + new + ":") <= 1 for _, _, new, _, _ in proposals()))
    ck("the 26 proposals are 20 ExitKey + 5 NumberPadKey + 1 MinusPlusKey",
       sorted(n.split("_")[0] for _, _, n, _, _ in proposals()).count("ExitKey") == 20
       and len(proposals()) == 26, "%d proposals" % len(proposals()))
    # ★ THE ROUND-3 LESSON: round 3 shipped five prom_a labels built on the
    # morpheme "Home", which occurs ZERO times in all four images.  Every
    # morpheme this round coins a name from is checked against the ROM bytes.
    ck("the morpheme EXIT occurs in prom_b as its own display string (twice)",
       _b.count(b"EXIT") == 2)
    ck("the morpheme PAGE occurs in both prom_a and prom_b",
       _a.count(b"PAGE") > 0 and _b.count(b"PAGE") > 0)
    ck("COMPARE occurs in NO image -- which is why nothing here is named for it",
       _a.count(b"COMPARE") == _b.count(b"COMPARE") == 0)
    ck("DRAWBAR occurs in prom_b, so ExitKey_DrawbarScreen borrows a real word",
       _b.count(b"DRAWBAR") > 0)
    ck('the "-1"/"+1" pair is named from the PANEL legends, which round 9 grades',
       BC.PANEL[(3, 5)][0] == "-1" and BC.PANEL[(3, 6)][0] == "+1")

    # --- what the .s must look like AFTER --apply --------------------------
    applied = ("\nExitKey_TrackAssign_StageZero:" in src)
    ck("the round is applied to prom_b/wsa1_prom_b.s", applied)
    if applied:
        for _, _, new, _, _ in proposals():
            if src.count("\n" + new + ":") != 1:
                ck("label %s appears exactly once" % new, False,
                   "%d times" % src.count("\n" + new + ":"))
                break
        else:
            ck("all 26 new labels appear exactly once each", True)
        for old_lab, new_lab in EXTRA_RENAMES:
            ck("%s is gone and %s is present" % (old_lab, new_lab),
               ("\n" + old_lab + ":") not in src and ("\n" + new_lab + ":") in src)
        ck("the round-11 banner appears exactly once",
           src.count(BANNER_FIRST) == 1, "%d" % src.count(BANNER_FIRST))
        ck("no corrected paragraph got appended twice",
           all(src.count(new) <= 1 for _, new in HEADER_FIXES),
           str([new[:40] for _, new in HEADER_FIXES if src.count(new) > 1]))
        # ⚠ three of the corrections APPEND to the paragraph they fix, so their
        # anchor legitimately survives inside the corrected text.  The test is
        # that the CORRECTION is present, not that the anchor is absent.
        ck("every correction this round makes is present in the file",
           all(new in src for _, new in HEADER_FIXES) and BANNER_OLD not in src)
        ck("exactly 16 headers carry the answered-index paragraph, not 31",
           src.count(F67_NEW) == 16 and src.count(F67_OLD) == 15,
           "%d answered, %d left" % (src.count(F67_NEW), src.count(F67_OLD)))
        ck("the banner's buckets still partition the 124 (banner_text asserts it)",
           bool(banner_text()))
        owners2, sm2, hs2 = table_owners(), slot_map(), in_span_handlers()
        pr2 = {a: n for a, _, n, _, _ in proposals()}
        widest = max(len(l) for a, sl in hs2.items()
                     for l in header_for(a, sl, owners2, sm2, pr2.get(a)))
        ck("no line of the 124 headers this round generates exceeds 80 columns",
           widest <= 80, "widest %d" % widest)

    print("\n%d ok, %d FAILED" % (_ok, _fail))
    return 1 if _fail else 0


def REWRITABLE_BASES():
    """Which class-0xA9 base codes can the +0x11 / 0x19 handlers rewrite?

    A base is rewritable when its (group, mask) has an action-table entry whose
    handler is 0xF8AE68 or 0xF8AEDB -- the only two that contain
    `add (XIX-1),0x11`.  Read from both variants' action tables.
    """
    out = set()
    for variant in (1, 2):
        for wire, g in EI.wire_map(variant).items():
            _, _, recs = EI.group_list(variant, g)
            for cls, code, shift, mask in recs:
                if cls != 0xA9:
                    continue
                h = EI.interceptable(variant, g, mask)
                if h in (0xF8AE68, 0xF8AEDB):
                    out.add(code)
    return out


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        sys.exit(selftest())
    if "--apply" in sys.argv:
        sys.exit(apply_edits())
    main()
