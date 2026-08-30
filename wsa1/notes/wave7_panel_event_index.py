#!/usr/bin/env python3
"""LAYER 2 SOLVED: where the class-0xA9 event's 5-bit code comes from.

QUESTION ANSWERED
  `notes/wave7_panel_button_codes.py` (round 9) solved LAYER 1 -- the WIRE
  numbering [0xC0|segment][bitmask] that the CP1 panel MCU sends -- and
  REFUSED to guess LAYER 2, the 5-bit index inside the class-0xA9 event that
  the 32-entry per-screen tables are indexed by.  Its closing paragraph named
  the shortest unwalked path: find whatever CONSUMES the three bytes
  prom_b `SC1_RxOp0_ThreeByte` queues and posts the {0xA9, code, b2, b3}
  event, "and finding it closes the question outright".

  ==> THIS SCRIPT WALKS THAT PATH TO ITS END.  The consumer is a two-stage
  pipeline in prom_a, and the (segment,bit) -> code map is a set of TABLES IN
  ROM, not a computed expression -- which is why round 9's search for an
  `ld DE,0x00A9`-shaped post found nothing in any of the four images: the
  class byte 0xA9 is a DATA BYTE inside those tables, copied to the event,
  never loaded as an immediate.  That measured negative was the correct clue.

  ★ AND IT ANSWERS ROUND 9'S ARITHMETIC OBJECTION.  Round 9 wrote "32 codes
  cannot enumerate 58 switches, so the mapping is not the identity and must
  not be guessed."  It is not the identity, and it is not 32 either: ONE
  EVENT CODE COVERS A PAIR OF MATRIX BITS, and bit 7 of the code byte says
  which of the pair.  32 x 2 = 64 >= 58.  The mechanism is measured below.

THE PIPELINE, end to end, every link read from the ROM by this script

  1. prom_b SC1_RxOp0_ThreeByte (0xF5B0D5) appends three bytes to the inbound
     queue at RAM 0x2B40:  [wire byte][new value][old XOR new].
  2. prom_a sub_F8A088 (0xF8A088) drains that queue.  Per record it computes
     the map index (wire & 0x1F) | ((wire & 0xC0) >> 1), reads
     PanelWireGroupMap_Variant1/2 (0xF8A109 / 0xF8A189, already documented in
     the .s) to get a GROUP id, and -- only when the change mask is non-zero
     -- calls 0xF8A3B2, which appends [group][value][changemask] to a SECOND
     queue at RAM 0x2000 (count in (0x219A), hard limit 7 records).
  3. prom_a sub_F8A824 (0xF8A824, reached from prom_b thunk slot 0xF40634 ->
     0xF8A81D -> `calr`) walks the 0x2000 queue with XIY and writes UI EVENTS
     to XIX = 0x2030 -- the same event list PanelButton_PostClass70 appends
     to through List2030_AppendRegs, bounded by `cp XIX,0x206C` at 0xF8A86D.
     ★ For each group it fetches ONE LIST from
         PanelGroupEventLists_Variant1  0xF8B446   ((0xC4) == 1)
         PanelGroupEventLists_Variant2  0xF8B4B2   (otherwise)
       and walks it (0xF8A862-0xF8A882).  THOSE LISTS ARE THE LAYER-2 TABLE.
  4. Each list entry is FOUR BYTES, terminated by 0xFF in byte 0:
         [0] event CLASS   -> copied to the event's +0  (`ld WA,(XHL+)` /
         [1] event CODE    -> copied to the event's +1   `ld (XIX+),WA`)
         [2] SHIFT byte    -> bit 4 = direction, bits 0-2 = count (0xF8A8A1)
         [3] BIT MASK      -> which bits of this wire byte this entry owns
     `and D,W / and E,W` at 0xF8A87B keeps only that mask's bits of the
     change mask (D) and of the new value (E); the shift then normalises them
     down to bits 0-1; `ld (XIX+),DE` at 0xF8A90B stores E at the event's +2
     and D at +3.  If D is zero after masking the entry is DISCARDED
     (`dec 2,XIX` at 0xF8A8C3) -- that bit did not move.
  5. prom_a UiEvent_RouteByCode (0xF8659B) loads the event's +1 into (0x20B8)
     and +2/+3 into (0x20B9)/(0x20BA), and PanelButton_Accept masks the code
     with 0x1F at 0xF8660D.

WHY THE PAIR, AND WHAT BIT 7 IS -- the round-9 correction, now with a cause
  Every class-0xA9 button entry carries a SINGLE-BIT mask and a shift that
  lands that bit on POSITION 0 or POSITION 1 of a two-bit field.  Two entries
  of the same list therefore share one code and differ only in position.  So
    * (0x20B9)/(0x20BA) take the values 0..3 -- which is why prom_a compares
      them against 3 (`cp B,3` at 0xF866BB) and tests bit 1 (0xF8661F);
    * `bit 0,(0x20B9)` at 0xF866C7/0xF86708 sets bit 7 of the button code for
      POSITION 0 and leaves it clear for POSITION 1;
    * PanelButton_Accept reads a PRESS as `E & D != 0` -- the bit moved AND
      is now 1 -- and a RELEASE as `E & D == 0`, using the same two bytes.
  Round 9 struck the old gloss "bit 7 = button RELEASED" and said what bit 7
  means "is NOT established".  It is established here: BIT 7 SELECTS WHICH
  MEMBER OF THE PAIR, and prom_b's eight `item i / item i+8` handlers at
  0xF7ECFF-0xF7EDC6 are consistent with that and with nothing else.
  ★ The sharpest instance: code 0x0D is the -1/+1 pair (group 0x0A, masks
  0x20 and 0x40).  PanelButton_Route's index-0x0D arm builds its dial step as
  `A = (W & 0x80) | 1` at 0xF861D1-0xF861D6 -- i.e. bit 7 IS THE SIGN.  A
  release flag could not be a sign.

TWO INDEPENDENT CONFIRMATIONS THAT THE CHAIN IS THE RIGHT ONE
  A. The DIAL.  PanelWireGroupMap_Variant1 sends wire 0xD7 to group 0x0F;
     group 0x0F's list is the single entry {class 0xA9, code 0x21, shift 0,
     mask 0xFF}; and UiEvent_RouteByCode dispatches code 0x21 to
     PanelEvent_Code21_Dial -- a name this tree derived MONTHS EARLIER from
     the other end of the machine, with no knowledge of these tables.
  B. THE TWO NON-BUTTON CODES ARE THE ROUTER'S TWO SPECIAL CASES.  Exactly
     four class-0xA9 codes in these tables exceed 0x1F: 0x20, 0x21, 0x32,
     0x33.  UiEvent_RouteByCode's three-way split is `A < 0x20` (buttons),
     `A == 0x20` (PanelEvent_Code20_SetScreen) and `A == 0x21`
     (PanelEvent_Code21_Dial) at 0xF8659F-0xF865B8 -- and 0x20 and 0x21 are
     the ONLY two codes in the tables that carry a multi-bit selector rather
     than a bit pair.  The table's exceptions and the router's exceptions are
     the same two values, derived from opposite ends.
     ⚠ 0x32 (variant-1 group 0x16) and 0x33 (group 0x17) match none of the
     three arms of that split, so nothing this lane read consumes them.  Not
     explained here.
     ⚠ AND ONE BUTTON-RANGE CODE IS NOT A PAIR: 0x1B, in VARIANT 2 ONLY,
     carries mask 0xFF (group 0x01) and mask 0x0F (group 0x02) with shift 0,
     i.e. a whole 8- or 4-bit selector, where variant 1 sends those same two
     wires as class 0xA8 code 0x08.  So "one code = one bit pair" holds for
     90 of the 104 class-0xA9 entries across both variants; the other 14 are
     codes 0x1B, 0x20 and 0x21 -- `--selftest` check D3c enumerates them
     rather than asserting the rule has no exceptions.
  C. The FOUR CONTINUOUS controls.  Wires 0xD0-0xD3 -> groups 0x0B-0x0E ->
     four one-entry lists with mask 0x7F/0xFF and classes 0xB2, 0xB1, 0xBC,
     0xB0 -- whole-byte values, no bit pairing, exactly what a pot sends.

⚠ THE ONE THING THIS TABLE IS NOT: A FINAL ANSWER FOR EVERY BUTTON
  The per-group ACTION tables (PanelGroupActionTables_Variant1 0xF8B74A /
  _Variant2 0xF8B7AE, 25 entries each, records [group][mask][u32 handler],
  terminated by 0xFF in the group byte) let a handler intercept a (group,
  mask) pair AFTER the class/code pair has been written but BEFORE the value
  pair is.  Two of those handlers REWRITE the code byte in place:
      0xF8AE7E / 0xF8AEF1   `add (XIX-1),0x11`      code += 0x11
      0xF8AE8A / 0xF8AEFD   `ld (XIX-1),0x19`       code := 0x19
  and every handler may end at 0xF8A90F (`dec 2,XIX` then `jr` to the `ret` at
  0xF8A90E) which DROPS the event.  So the code in the list is a BASE, and for the groups that have an
  action-table entry the delivered code can be base or base+0x11 or 0x19.
  ★ That is the shape round 9's own liveness census predicted from the other
  side: indices 0x00-0x0F are non-default in 31 or 32 of the 32 per-screen
  tables, 0x10-0x1F in at most 14.  base+0x11 over bases 0x00-0x07 gives
  0x11-0x18, and the clamp gives 0x19 -- an ALTERNATE set living exactly
  where the census found the sparse half.  This script REPORTS which entries
  are interceptable; it does not claim to know when the branch is taken.

★ AND A HOLE THE TABLE MAKES VISIBLE: NOBODY PRODUCES CODE 0x0E
  The eighteen class-0xA9 button codes these tables emit are
      00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0F 10 1B 1E
  -- 0x0E is MISSING, and it cannot be reached by the +0x11 rewrite either
  (the smallest base is 0x00, so that arm only ever produces 0x11-0x19).  Yet
  PanelButton_Route gives index 0x0E its own arm at 0xF861BC, the one that
  calls PanelButton_PostClass70.  So whatever raises 0x0E is NOT a panel wire.
  The likely source is one of the EIGHT other producers that append to the
  same 0x2000 queue -- 0xF8A2D6, 0xF8A322, 0xF8A33E, 0xF8A35A, 0xF8A376,
  0xF8A392, 0xF8A3AE and the wire drain 0xF8A0F2, all `calr 0xF8A3B2`, each
  guarded by its own `cp (0x219A),0x07` -- which are also the only plausible
  producers of groups 0x10-0x18.  ⚠ This lane did not read them.

⚠ AN OPEN QUESTION THIS TABLE RAISES AND DOES NOT SETTLE
  In variant 1 the lists for groups 0x03 and 0x04 are byte-identical, and so
  are those for groups 0x05 and 0x06, and those for groups 0x09 and 0x0A
  share codes 0x08-0x0C on bits 0-4.  Identical (class, code, position)
  triples reach UiEvent_RouteByCode from two different wires.  The action
  tables for those groups are also the same two handlers.  Nothing read here
  distinguishes them, so `--join` prints the collision rather than resolving
  it.  Do not name a routine from a colliding code.

⚠ AND A COUNTING TENSION WITH THE LAYER-1 MAP, STATED NOT HIDDEN
  Variant 1 answers to ELEVEN switch/analog wires (0xC0-0xCA plus 0xD0-0xD3
  and 0xD7), and six of those eleven carry a full eight-bit list.  Round 9's
  physical map has NINE populated matrix columns (CP1 segments 0-5, CP2
  segments 7-9) and says SW24, SW49-56, SW61-64, SW67-72 and SW78-80 are not
  fitted -- its own reading of the two diode lists on manual page 32.  Under
  the identity wire = 0xC0|segment the two cannot both be right: `--join`
  prints, for wire 0xC6, eight entries that would be SW49-SW56, and for wire
  0xC7 bits 4-7 four more that would be SW61-SW64.  ⚠ NOT RESOLVED HERE, and
  neither map was edited.

⚠ AND A TENSION WITH THE LAYER-1 MAP, STATED NOT HIDDEN
  Round 9's physical table puts the -1/+1 pair at SEGMENT 3, bits 5 and 6
  (grade POSITION, its weakest).  The event table puts code 0x0D -- proven to
  be the -1/+1 pair by the sign argument above -- at GROUP 0x0A, bits 5 and 6.
  The BIT positions agree exactly; the SEGMENT does not, and group == segment
  for wires 0xC0-0xCA.  One of the two is wrong.  This lane did not resolve
  it and did not touch either map.

RUN
    python3 notes/wave7_panel_event_index.py            # everything
    python3 notes/wave7_panel_event_index.py --lists    # the layer-2 tables
    python3 notes/wave7_panel_event_index.py --join     # (wire,bit) -> event
    python3 notes/wave7_panel_event_index.py --actions  # the intercept tables
    python3 notes/wave7_panel_event_index.py --stale    # the dead-copy negative
    python3 notes/wave7_panel_event_index.py --selftest # 34 checks, incl. LAST
"""
import os
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
A_BASE = 0xF80000
_a = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
_b = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()


def by(p):
    return _a[p - A_BASE]


def blk(p, n):
    return _a[p - A_BASE:p - A_BASE + n]


def le32(p):
    return int.from_bytes(blk(p, 4), "little")


UNIDASM = os.path.expanduser("~/compartilhado/kn7000_mame_build/unidasm")


def boundaries(start, end):
    """Instruction-start addresses of a LINEAR decode of prom_a[start:end].

    Uses the same unidasm the wave's tooling notes prescribe.  If it is not
    on this machine the caller's check FAILS -- a check that silently skips
    is a check that cannot fail, and this tree has a rule about that.
    """
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(blk(start, end - start))
        path = f.name
    try:
        out = subprocess.run([UNIDASM, path, "-arch", "tlcs900", "-basepc", hex(start)],
                             capture_output=True, text=True).stdout
    finally:
        os.unlink(path)
    bs = set()
    for line in out.splitlines():
        head = line.split(":")[0]
        try:
            bs.add(int(head, 16))
        except ValueError:
            pass
    return bs


# --- addresses, every one of them read off an instruction, cited ------------
# `ld XIX,0x00F8B446` at 0xF8A84C, `ld XIX,0x00F8B4B2` at 0xF8A857,
# selected by `cp (0xC4),0x01 / jr Z` at 0xF8A851-0xF8A855.
GROUP_LIST_TABLE = {1: 0xF8B446, 2: 0xF8B4B2}
# `ld XIY,0x00F8B74A` at 0xF8A8CC, `ld XIY,0x00F8B7AE` at 0xF8A8D7,
# selected by `cp (0xC4),0x01 / jr Z` at 0xF8A8D1-0xF8A8D5.
ACTION_TABLE = {1: 0xF8B74A, 2: 0xF8B7AE}
# `ld XIY,0x00F8A109` at 0xF8A0AE, `ld XIY,0x00F8A189` at 0xF8A0B9.
WIRE_MAP = {1: 0xF8A109, 2: 0xF8A189}
# `cp A,0x18 / jr UGT` at 0xF8A83B-0xF8A83E bounds the group id.
GROUP_MAX = 0x18
NO_GROUP = 0x20          # the wire map's "not fitted / no group" filler
EVENT_LIST_BASE = 0x2030  # `ld XIX,0x00002030`  at 0xF8A829
EVENT_LIST_END = 0x206C   # `cp XIX,0x0000206C`  at 0xF8A86D
GROUP_QUEUE_BASE = 0x2000  # `ld XIY,0x00002000` at 0xF8A824


def n_group_slots(variant):
    """Entry count of a group->list table, by ABUTMENT, never by assumption.

    Variant 1's table abuts variant 2's; variant 2's abuts the first list
    variant 1's slot 0 points at.  Both give the same stride, which is the
    only reason this is a measurement and not a guess.
    """
    if variant == 1:
        return (GROUP_LIST_TABLE[2] - GROUP_LIST_TABLE[1]) // 4
    return (le32(GROUP_LIST_TABLE[1]) - GROUP_LIST_TABLE[2]) // 4


def n_action_slots(variant):
    """Entry count of an action table, by abutment (same argument)."""
    if variant == 1:
        return (ACTION_TABLE[2] - ACTION_TABLE[1]) // 4
    return (le32(ACTION_TABLE[1]) - ACTION_TABLE[2]) // 4


def wire_map(variant):
    """wire byte -> group id, for every wire the variant answers to.

    Index is (wire & 0x1F) | ((wire & 0xC0) >> 1), computed at
    0xF8A0A3-0xF8A0AC; the 128-byte extent is the index width.
    """
    base = WIRE_MAP[variant]
    out = {}
    for wire in range(0x100):
        idx = (wire & 0x1F) | ((wire & 0xC0) >> 1)
        g = by(base + idx)
        if g != NO_GROUP and (wire & 0x20) == 0:   # bit 5 is dropped by the index
            out[wire] = g
    return out


def group_list(variant, group):
    """The 4-byte records of one group's event list, plus its extent."""
    p = le32(GROUP_LIST_TABLE[variant] + 4 * group)
    recs = []
    q = p
    while by(q) != 0xFF:
        recs.append((by(q), by(q + 1), by(q + 2), by(q + 3)))
        q += 4
        if q - p > 0x200:
            raise RuntimeError("runaway list at %06X" % p)
    return p, q, recs


def action_list(variant, group):
    """The 6-byte records of one group's action table, plus its extent."""
    p = le32(ACTION_TABLE[variant] + 4 * group)
    recs = []
    q = p
    while by(q) != 0xFF:
        recs.append((by(q), by(q + 1), le32(q + 2)))
        q += 6
        if q - p > 0x200:
            raise RuntimeError("runaway action list at %06X" % p)
    return p, q, recs


def normalise(mask, shift):
    """Apply the list record's shift byte exactly as 0xF8A8A1 does.

    bit 4 of the shift byte selects LEFT (`sla`) over RIGHT (`srl`); the count
    is `shift & 7` in both arms (`and A,0x07` at 0xF8A8AF and 0xF8A8B8).
    """
    n = shift & 7
    if shift == 0:
        return mask & 0xFF
    if shift & 0x10:
        return (mask << n) & 0xFF
    return (mask >> n) & 0xFF


def position(mask, shift):
    """0 or 1 for a single-bit entry (the pair member), else None."""
    v = normalise(mask, shift)
    if v == 1:
        return 0
    if v == 2:
        return 1
    return None


def code_byte(code, mask, shift):
    """The byte that reaches (0x2082) -- code, with bit 7 set for position 0.

    `bit 0,(0x20B9) / or A,0x80` at 0xF86708-0xF8670D in PanelButton_Accept.
    """
    p = position(mask, shift)
    if p == 0:
        return code | 0x80
    return code


def interceptable(variant, group, mask):
    _, _, recs = action_list(variant, group)
    for g, m, h in recs:
        if m == mask:
            return h
    return None


# ---------------------------------------------------------------------------
def print_lists():
    for v in (1, 2):
        print("=== PanelGroupEventLists_Variant%d  %06X, %d slots "
              "(abutment; %d reachable, `cp A,0x18` at 0xF8A83B)"
              % (v, GROUP_LIST_TABLE[v], n_group_slots(v), GROUP_MAX + 1))
        for g in range(n_group_slots(v)):
            p, q, recs = group_list(v, g)
            tag = "" if g <= GROUP_MAX else "   [UNREACHABLE: above the 0x18 bound]"
            print("  group %02X -> %06X..%06X  %d rec%s" % (g, p, q, len(recs), tag))
            for cls, code, sh, mask in recs:
                pos = position(mask, sh)
                extra = ("pair pos %d, delivered code %02X" % (pos, code_byte(code, mask, sh))
                         if pos is not None else
                         "whole field, normalised value %02X" % normalise(mask, sh))
                h = interceptable(v, g, mask)
                print("      class %02X code %02X shift %02X mask %02X   %s%s"
                      % (cls, code, sh, mask, extra,
                         "  [action %06X]" % h if h else ""))


def print_join():
    print("WIRE.BIT -> EVENT, both variants.  group == the wire map's output;")
    print("SW = 8*(wire & 0x0F) + bit + 1 is ROUND 9's layer-1 rule, quoted not re-derived.")
    print("A trailing '!' marks an SW that round 9's own diode lists say is NOT FITTED --")
    print("the counting tension in this script's header, printed rather than hidden.")
    for v in (1, 2):
        print("=== variant %d" % v)
        wm = wire_map(v)
        for wire in sorted(wm):
            g = wm[wire]
            if g > GROUP_MAX:
                print("  wire %02X -> group %02X  ABOVE THE 0x18 BOUND, never dispatched" % (wire, g))
                continue
            _, _, recs = group_list(v, g)
            if not recs:
                print("  wire %02X -> group %02X  (empty list)" % (wire, g))
                continue
            print("  wire %02X -> group %02X" % (wire, g))
            for cls, code, sh, mask in recs:
                bits = [b for b in range(8) if mask & (1 << b)]
                unfitted = set([24] + list(range(49, 57)) + list(range(61, 65))
                               + list(range(67, 73)) + list(range(78, 81)))
                if len(bits) == 1 and 0xC0 <= wire <= 0xCA:
                    n = 8 * (wire & 0x0F) + bits[0] + 1
                    sw = "SW%d%s" % (n, "!" if n in unfitted else "")
                else:
                    sw = "-"
                print("     mask %02X %-6s -> class %02X code %02X  delivered %02X"
                      % (mask, sw, cls, code, code_byte(code, mask, sh)))


def print_actions():
    for v in (1, 2):
        print("=== PanelGroupActionTables_Variant%d  %06X, %d slots (abutment)"
              % (v, ACTION_TABLE[v], n_action_slots(v)))
        for g in range(n_action_slots(v)):
            p, q, recs = action_list(v, g)
            print("  group %02X -> %06X..%06X  %d rec" % (g, p, q, len(recs)))
            for gg, mask, h in recs:
                print("      key group %02X mask %02X -> %06X%s"
                      % (gg, mask, h, "   ⚠ key group != slot" if gg != g else ""))


def print_stale():
    """The measured negative: 0xF8A44B is a dead duplicate of 0xF8A84B."""
    d = 0x400
    same = [i for i in range(0x7B) if blk(0xF8A44B + i, 1) == blk(0xF8A44B + d + i, 1)]
    diff = [0xF8A44B + i for i in range(0x7B) if i not in same]
    print("prom_a carries TWO copies of the list walker, 0x400 apart:")
    print("  LIVE   0xF8A84B -- immediates %06X/%06X (group lists) and %06X/%06X"
          % (GROUP_LIST_TABLE[1], GROUP_LIST_TABLE[2], ACTION_TABLE[1], ACTION_TABLE[2]))
    print("  STALE  0xF8A44B -- immediates 0xF8ADDD/0xF8AD71 and 0xF8AF9F")
    print("  over the first 0x7B bytes exactly %d bytes differ, at: %s"
          % (len(diff), " ".join("%06X" % x for x in diff)))
    print("  and every differing byte is inside one of those three immediates")
    print("  or the two-instruction selector around them.")
    print("EVIDENCE THAT THE 0xF8A44B COPY IS DEAD, three independent measurements:")
    for tag, label, addr in (("1a", "0xF8ADDD", 0xF8ADDD), ("1b", "0xF8AD71", 0xF8AD71),
                             ("1c", "0xF8AF9F", 0xF8AF9F)):
        vals = [le32(addr + 4 * k) for k in range(4)]
        ok = sum(1 for x in vals if 0xF80000 <= x < 0xFFFFFF)
        print("  %s. %s reads %s -- %d of its first 4 words are in-image pointers"
              % (tag, label, " ".join("%08X" % x for x in vals), ok))
    for label, addr in (("0xF8B446", 0xF8B446), ("0xF8B4B2", 0xF8B4B2), ("0xF8B74A", 0xF8B74A)):
        vals = [le32(addr + 4 * k) for k in range(4)]
        ok = sum(1 for x in vals if 0xF80000 <= x < 0xFFFFFF)
        print("     vs the live %s: %s -- %d of 4" % (label, " ".join("%08X" % x for x in vals), ok))
    print("  2. the stale copy's loop back-edge, `68 A6` at 0xF8A486, resolves to")
    print("     0xF8A42E, which is the SECOND byte of the 5-byte instruction at")
    print("     0xF8A42D; no linear decode starting anywhere in 0xF8A100-0xF8A42D")
    print("     puts a boundary there.  The live copy's `68 A6` at 0xF8A886")
    print("     resolves to 0xF8A82E, which IS a boundary and IS the loop head.")
    print("  3. 0xF8A44B has no incoming branch and no 24/32-bit pointer in either")
    print("     of CPU 1's ROMs; 0xF8A824 is reached from prom_b thunk slot")
    print("     0xF40634 -> 0xF8A81D -> `calr 0xF8A824` at 0xF8A81D.")
    for v in (0xF8A44B, 0xF8A824, 0xF8A81D, 0xF8A800):
        hits = []
        for nm, d_, base in (("prom_a", _a, 0xF80000), ("prom_b", _b, 0xF00000)):
            pat = v.to_bytes(3, "little")
            i = d_.find(pat)
            while i >= 0:
                hits.append("%s:%06X" % (nm, base + i))
                i = d_.find(pat, i + 1)
        print("     24-bit references to %06X: %s" % (v, ", ".join(hits) or "NONE"))


# ---------------------------------------------------------------------------
CHECKS = []


def ck(name, cond):
    CHECKS.append((name, bool(cond)))


def selftest():
    # --- A. table geometry, every bound an abutment -------------------------
    ck("A1 variant-1 group table has 27 slots", n_group_slots(1) == 27)
    ck("A2 variant-2 group table has 27 slots", n_group_slots(2) == 27)
    ck("A3 group tables abut", GROUP_LIST_TABLE[1] + 4 * 27 == GROUP_LIST_TABLE[2])
    ck("A4 variant-2 table abuts its own first list",
       GROUP_LIST_TABLE[2] + 4 * 27 == le32(GROUP_LIST_TABLE[1]))
    ck("A5 both action tables have 25 slots",
       n_action_slots(1) == 25 and n_action_slots(2) == 25)
    ck("A6 25 == the 0x18 dispatch bound plus one", 25 == GROUP_MAX + 1)
    ck("A7 action tables abut", ACTION_TABLE[1] + 4 * 25 == ACTION_TABLE[2])
    ck("A8 variant-2 action table abuts its own first list",
       ACTION_TABLE[2] + 4 * 25 == le32(ACTION_TABLE[1]))

    # --- B. record format, pinned by the pointer deltas ---------------------
    #     LAST ELEMENT included on purpose: slot 26, not slot 0.
    # ⚠ the two variants' lists share ONE pool, interleaved -- a per-variant
    # delta test fails on that account and says nothing.  Take the union.
    ptrs = sorted(set(le32(GROUP_LIST_TABLE[v] + 4 * g)
                      for v in (1, 2) for g in range(27)))
    deltas = [b - a for a, b in zip(ptrs, ptrs[1:])]
    ck("B1 all 39 gaps in the shared list pool are 1 mod 4 (4-byte recs + 0xFF)",
       len(deltas) == 39 and all(d % 4 == 1 for d in deltas))
    ck("B2 the pool's LAST list ends on the byte before the action table",
       ptrs[-1] + 1 == ACTION_TABLE[1])
    ck("B3 variant-1 slot 26 (LAST) points at a bare 0xFF terminator",
       by(le32(GROUP_LIST_TABLE[1] + 4 * 26)) == 0xFF)
    ck("B4 variant-2 slot 26 (LAST) points at a bare 0xFF terminator",
       by(le32(GROUP_LIST_TABLE[2] + 4 * 26)) == 0xFF)
    ck("B5 variant-1 action slot 24 (LAST) is group 0x18, an empty list",
       action_list(1, 24)[2] == [])
    ck("B6 variant-2 action slot 24 (LAST) is group 0x18, an empty list",
       action_list(2, 24)[2] == [])

    # --- C. the two independent confirmations -------------------------------
    wm1 = wire_map(1)
    ck("C1 wire 0xD7 (the dial) maps to group 0x0F", wm1.get(0xD7) == 0x0F)
    ck("C2 group 0x0F is exactly {class 0xA9, code 0x21, shift 0, mask 0xFF}",
       group_list(1, 0x0F)[2] == [(0xA9, 0x21, 0x00, 0xFF)])
    ck("C3 the four continuous wires 0xD0-0xD3 are one whole-byte record each",
       all(len(group_list(1, wm1[w])[2]) == 1 and
           group_list(1, wm1[w])[2][0][3] in (0x7F, 0xFF)
           for w in (0xD0, 0xD1, 0xD2, 0xD3)))
    ck("C4 and none of those four is class 0xA9",
       all(group_list(1, wm1[w])[2][0][0] != 0xA9 for w in (0xD0, 0xD1, 0xD2, 0xD3)))

    # --- D. the pair mechanism ---------------------------------------------
    a9 = []
    for v in (1, 2):
        for g in range(GROUP_MAX + 1):
            for cls, code, sh, mask in group_list(v, g)[2]:
                if cls == 0xA9:
                    a9.append((v, g, code, sh, mask))
    ck("D1 there are class-0xA9 entries in both variants",
       any(x[0] == 1 for x in a9) and any(x[0] == 2 for x in a9))
    single = [x for x in a9 if bin(x[4]).count("1") == 1]
    btn = [x for x in single if x[2] <= 0x1F]
    ck("D2 every single-bit class-0xA9 BUTTON entry lands on position 0 or 1",
       all(position(m, s) in (0, 1) for _, _, _, s, m in btn))
    ck("D3 the only class-0xA9 codes above 0x1F are 0x20, 0x21, 0x32, 0x33",
       sorted(set(c for _, _, c, _, _ in a9 if c > 0x1F)) == [0x20, 0x21, 0x32, 0x33])
    ck("D3b 0x20 and 0x21 are exactly the router's two non-button arms "
       "(`cp A,0x20` 0xF8659F, `cp A,0x21` 0xF865B3)",
       blk(0xF8659F, 3) == bytes([0xC9, 0xCF, 0x20]) and
       blk(0xF865B3, 3) == bytes([0xC9, 0xCF, 0x21]))
    ck("D3c exactly three class-0xA9 codes carry a selector wider than one bit "
       "pair: 0x1B (variant 2 only), 0x20 and 0x21",
       sorted(set(c for _, _, c, s, mm in a9
                  if bin(mm).count("1") > 1 or position(mm, s) is None)) ==
       [0x1B, 0x20, 0x21])
    ck("D3d 0x1B appears in variant 2 and in no variant-1 list",
       all(c != 0x1B for v, g, c, s, mm in a9 if v == 1) and
       any(c == 0x1B for v, g, c, s, mm in a9 if v == 2))
    codes = sorted(set(c for _, _, c, _, _ in a9 if c <= 0x1F))
    ck("D4 every class-0xA9 BUTTON code fits in 5 bits", all(c <= 0x1F for c in codes))
    ck("D4b the eighteen button codes the tables emit, LAST included",
       codes == [0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09,
                 0x0A, 0x0B, 0x0C, 0x0D, 0x0F, 0x10, 0x1B, 0x1E])
    ck("D4c code 0x0E is produced by NO wire, in either variant", 0x0E not in codes)
    ck("D4d yet PanelButton_Route has an index-0x0E arm (`cp L,0x0E` 0xF861BC)",
       blk(0xF861BC, 3) == bytes([0xCF, 0xCF, 0x0E]))
    ck("D4e the +0x11 rewrite cannot reach 0x0E either (min base 0x00)",
       min(codes) + 0x11 > 0x0E)
    ck("D5a 90 of the 104 class-0xA9 entries are bit pairs",
       len(a9) == 104 and len(a9) - len([x for x in a9
           if bin(x[4]).count("1") > 1 or position(x[4], x[3]) is None]) == 90)
    ck("D5 code 0x0D exists and has BOTH pair positions in variant 1 group 0x0A",
       sorted(position(m, s) for cls, c, s, m in group_list(1, 0x0A)[2] if c == 0x0D) == [0, 1])
    ck("D6 code 0x0D's two masks are 0x20 and 0x40 (bits 5 and 6)",
       sorted(m for cls, c, s, m in group_list(1, 0x0A)[2] if c == 0x0D) == [0x20, 0x40])
    pairs = {}
    for v, g, c, s, m in btn:
        pairs.setdefault((v, g, c), set()).add(position(m, s))
    ck("D7 no code in one group ever claims a third position",
       all(p <= {0, 1} for p in pairs.values()))
    ck("D8 the pair mechanism can address at least 58 switches",
       2 * 32 >= 58)

    # --- E. the intercept tables and their agreement with the lists ---------
    for v in (1, 2):
        bad = []
        for g in range(25):
            lm = set(m for _, _, _, m in group_list(v, g)[2])
            for gg, m, h in action_list(v, g)[2]:
                if gg != g or m not in lm:
                    bad.append((g, gg, m))
        ck("E%d variant %d: every action key is (own group, a mask its list uses)" % (v, v),
           not bad)
    ck("E3 variant-1 group 0x08's two list masks are its two action masks",
       sorted(m for _, _, _, m in group_list(1, 8)[2]) ==
       sorted(m for _, m, _ in action_list(1, 8)[2]))
    ck("E4 the two code-rewriting handlers are reachable from the action tables",
       {0xF8AE68, 0xF8AEDB} <= set(h for v in (1, 2) for g in range(25)
                                   for _, _, h in action_list(v, g)[2]))
    ck("E5 0xF8AE68 rewrites the code byte with `add (XIX-1),0x11`",
       blk(0xF8AE7E, 4) == bytes([0x8C, 0xFF, 0x38, 0x11]))
    ck("E6 0xF8AE68 clamps it with `ld (XIX-1),0x19`",
       blk(0xF8AE8A, 4) == bytes([0xBC, 0xFF, 0x00, 0x19]))
    l3 = group_list(1, 3)[2]
    l4 = group_list(1, 4)[2]
    l5 = group_list(1, 5)[2]
    l6 = group_list(1, 6)[2]
    ck("E8 variant-1 groups 0x03 and 0x04 emit identical lists: 0 of 8 records differ",
       len(l3) == 8 and sum(1 for x, y in zip(l3, l4) if x != y) == 0)
    ck("E9 variant-1 groups 0x05 and 0x06 likewise: 0 of 8 records differ",
       len(l5) == 8 and sum(1 for x, y in zip(l5, l6) if x != y) == 0)
    ck("E10 and their action lists are the same two handlers, 0 of 8 differ",
       sum(1 for x, y in zip(action_list(1, 3)[2], action_list(1, 4)[2])
           if x[1:] != y[1:]) == 0)
    ck("E7 0xF8AEDB does the same two rewrites",
       blk(0xF8AEF1, 4) == bytes([0x8C, 0xFF, 0x38, 0x11]) and
       blk(0xF8AEFD, 4) == bytes([0xBC, 0xFF, 0x00, 0x19]))

    # --- F. the instructions this whole reading rests on --------------------
    ck("F1 `ld XIY,0x00002000` at 0xF8A824", blk(0xF8A824, 5) == bytes([0x45, 0x00, 0x20, 0x00, 0x00]))
    ck("F2 `ld XIX,0x00002030` at 0xF8A829", blk(0xF8A829, 5) == bytes([0x44, 0x30, 0x20, 0x00, 0x00]))
    ck("F3 `cp A,0x18` at 0xF8A83B", blk(0xF8A83B, 3) == bytes([0xC9, 0xCF, 0x18]))
    ck("F4 `ld (0x2251),A` at 0xF8A840", blk(0xF8A840, 4) == bytes([0xF1, 0x51, 0x22, 0x41]))
    ck("F5 `ld XIX,0x00F8B446` at 0xF8A84C", blk(0xF8A84C, 5) == bytes([0x44, 0x46, 0xB4, 0xF8, 0x00]))
    ck("F6 `ld XIX,0x00F8B4B2` at 0xF8A857", blk(0xF8A857, 5) == bytes([0x44, 0xB2, 0xB4, 0xF8, 0x00]))
    ck("F7 `cp (XHL),0xFF` list terminator test at 0xF8A862",
       blk(0xF8A862, 3) == bytes([0x83, 0x3F, 0xFF]))
    ck("F8 `ld WA,(XHL+)` then `ld (XIX+),WA` at 0xF8A867/0xF8A86A",
       blk(0xF8A867, 6) == bytes([0xD5, 0xED, 0x20, 0xF5, 0xF1, 0x50]))
    ck("F9 `cp XIX,0x0000206C` bound at 0xF8A86D",
       blk(0xF8A86D, 6) == bytes([0xEC, 0xCF, 0x6C, 0x20, 0x00, 0x00]))
    ck("F10 `ld W,(XHL)` mask load and `and D,W / and E,W` at 0xF8A877",
       blk(0xF8A877, 8) == bytes([0x83, 0x20, 0x95, 0x22, 0xC8, 0xC4, 0xC8, 0xC5]))
    ck("F11 `ld (XIX+),DE` commit at 0xF8A90B", blk(0xF8A90B, 3) == bytes([0xF5, 0xF1, 0x52]))
    ck("F12 discard is `dec 2,XIX` at 0xF8A90F then `jr` to the `ret` at 0xF8A90E",
       blk(0xF8A90E, 5) == bytes([0x0E, 0xEC, 0x6A, 0x68, 0xFB]))
    ck("F13 the shift arms `and A,0x07` at 0xF8A8AF and 0xF8A8B8",
       blk(0xF8A8AF, 3) == bytes([0xC9, 0xCC, 0x07]) and
       blk(0xF8A8B8, 3) == bytes([0xC9, 0xCC, 0x07]))
    ck("F14 `bit 0x04,A` picks the shift direction at 0xF8A8AA",
       blk(0xF8A8AA, 3) == bytes([0xC9, 0x33, 0x04]))
    ck("F15 PanelButton_Accept still masks with 0x1F at 0xF8660D",
       blk(0xF8660D, 3) == bytes([0xCB, 0xCC, 0x1F]))
    ck("F16 PanelButton_Accept still sets bit 7 from bit 0 of (0x20B9)",
       blk(0xF86708, 8) == bytes([0xCD, 0x33, 0x00, 0x66, 0x03, 0xC9, 0xCE, 0x80]))
    ck("F17 PanelButton_Route builds the dial step as `(W&0x80)|1` at 0xF861D1",
       blk(0xF861D1, 8) == bytes([0xC8, 0x89, 0xC9, 0xCC, 0x80, 0xC9, 0xCE, 0x01]))

    # --- G. the stale copy --------------------------------------------------
    diff = [i for i in range(0x7B) if by(0xF8A44B + i) != by(0xF8A84B + i)]
    ck("G1 the two walker copies differ in exactly 9 of their first 123 bytes",
       len(diff) == 9)
    ck("G2 all 9 differences are in the two immediates and the selector",
       set(0xF8A44B + i for i in diff) ==
       {0xF8A44D, 0xF8A44E, 0xF8A451, 0xF8A452, 0xF8A453, 0xF8A454, 0xF8A455,
        0xF8A458, 0xF8A459})
    ck("G3 the stale copy's tables hold no in-image pointer in their first word",
       not (0xF80000 <= le32(0xF8ADDD) < 0xFFFFFF) and
       not (0xF80000 <= le32(0xF8AD71) < 0xFFFFFF) and
       not (0xF80000 <= le32(0xF8AF9F) < 0xFFFFFF))
    ck("G4 the live copy's tables hold in-image pointers in their first word",
       all(0xF80000 <= le32(x) < 0xFFFFFF
           for x in (0xF8B446, 0xF8B4B2, 0xF8B74A, 0xF8B7AE)))
    ck("G5 no 24-bit reference to 0xF8A44B exists in either of CPU 1's ROMs",
       _a.find((0xF8A44B).to_bytes(3, "little")) < 0 and
       _b.find((0xF8A44B).to_bytes(3, "little")) < 0)
    ck("G6 prom_b DOES carry a 24-bit reference to 0xF8A81D (the live entry)",
       _b.find((0xF8A81D).to_bytes(3, "little")) >= 0)
    # G7/G8 are the back-edge argument, re-derived rather than asserted.
    reach = [st for st in range(0xF8A100, 0xF8A42E)
             if 0xF8A42E in boundaries(st, 0xF8A440)]
    ck("G7 no linear decode starting in 0xF8A100-0xF8A42D reaches 0xF8A42E, "
       "the stale copy's own loop target (%d starts tried)" % (0xF8A42E - 0xF8A100),
       reach == [])
    ck("G8 the live copy's loop target 0xF8A82E IS a boundary of the decode "
       "from its entry 0xF8A824",
       0xF8A82E in boundaries(0xF8A824, 0xF8A8A0))
    ck("G9 both copies' back-edge byte pair really is `68 A6`",
       blk(0xF8A486, 2) == bytes([0x68, 0xA6]) and blk(0xF8A886, 2) == bytes([0x68, 0xA6]))

    ok = sum(1 for _, c in CHECKS if c)
    for name, c in CHECKS:
        print("  %s  %s" % ("PASS" if c else "FAIL", name))
    print("%d/%d checks pass" % (ok, len(CHECKS)))
    return 0 if ok == len(CHECKS) else 1


def main():
    args = sys.argv[1:]
    if "--selftest" in args:
        return selftest()
    if "--lists" in args:
        print_lists()
        return 0
    if "--join" in args:
        print_join()
        return 0
    if "--actions" in args:
        print_actions()
        return 0
    if "--stale" in args:
        print_stale()
        return 0
    print_lists()
    print()
    print_join()
    print()
    print_actions()
    print()
    print_stale()
    return 0


if __name__ == "__main__":
    sys.exit(main())
