#!/usr/bin/env python3
"""prom_a round 11: SPEND THE SOLVED PANEL CHAIN -- name the layer-2 tables,
label the dead walker, read the seven non-wire producers, and REPORT that the
`sub_XXXXXX` census this round was asked for is ALREADY COMMITTED AND LIVE.

QUESTION IT ANSWERS
  "Round 10 proved, read-only, that the panel event mapping is a set of ROM
   TABLES.  Which bytes of prom_a are those tables exactly, what may be written
   into the .s about them, and what may NOT?"
  and, second,
  "prom_a has 2,822 `sub_XXXXXX`.  What does the tree already know about them,
   and what naming shapes are still unspent?"

★ WHAT THIS ROUND ADDS TO THE .s (all applied by --apply, all re-derived here)
  1. The 2,191-byte block that the tree emitted as ONE `.byte` region called
     `PanelTables_F8B325` is split into NINE named objects.  Their boundaries
     are not guessed: six of the nine are the operand of an `ld XIX/XIY,imm32`
     in the code above, and the other three are pinned by ABUTMENT -- each
     pointer table's length is exactly (next load - this load), and each pool
     runs from its first list to the byte before the next loaded table.
  2. `sub_F8A824` -> `PanelGroupQueue_ExpandToEvents`, the walker that turns
     the 0x2000 group queue into 0x2030 UI events.
  3. `0xF8A44B`  -> a LABEL for the never-relocated dead copy of that walker,
     with the three measurements that prove it dead.
  4. `sub_F8A088` -> `PanelWireQueue_DrainToGroupQueue`,
     `sub_F8A3B2` -> `PanelGroupQueue_Append`,
     `sub_F8A303` -> `PanelGroupQueue_AppendFlaggedGroups`,
     `sub_F8A8A1` -> `PanelEvent_ShiftThenRunAction`,
     `sub_F8A913` -> `LowestSetBitIndex1Based`,
     `sub_F8A927` -> `IndexToBitMask8`.
  5. Fourteen pure wrappers renamed `<callee>_Entry` -- see WRAPPERS below.

★★ AND IT READS THE SEVEN NON-WIRE PRODUCERS ROUND 10 DID NOT
  Round 10 left this open: "NOBODY PRODUCES CODE 0x0E, yet PanelButton_Route
  has an 0x0E arm.  The likely producers are the seven NON-WIRE appenders at
  0xF8A2D6..0xF8A3AE; nobody has read them."  This file reads them.

  SIX of the seven are one routine, `sub_F8A303`.  It tests bit 7 of six flag
  bytes at RAM 0x28EC-0x28F1; for each set bit it clears the bit, loads a FIXED
  group id and the value 0x7F, and calls the queue appender:

        (0x28EE) -> group 0x10      (0x28F1) -> group 0x13
        (0x28EF) -> group 0x11      (0x28EC) -> group 0x14
        (0x28F0) -> group 0x12      (0x28ED) -> group 0x15

  and the variant-1 lists for groups 0x10-0x15 emit classes BA, BB, B4, BD, B8,
  B9 -- every one of them with CODE 0x00.  So SIX OF THE SEVEN CANNOT PRODUCE
  CODE 0x0E, measured, not assumed.  ⚠ THE SEVENTH IS NOT STATICALLY
  ENUMERABLE: 0xF8A2D6 takes its group from RAM (0x219C) at run time
  (`ld E,(0x219C)` at 0xF8A2D2), so no static read of it can enumerate the
  groups it raises.  The 0x0E hole is NARROWED, NOT CLOSED, and the remaining
  suspect is named.

★ ROUND 10 ALSO PREDICTED THE GROUP RANGE AND WAS RIGHT
  It wrote that these appenders "are also the only plausible producers of
  groups 0x10-0x18".  Six of them produce 0x10-0x15 -- inside that range, and
  the prediction is now a measurement.  Groups 0x16, 0x17 and 0x18 still have
  no producer this file found.

⚠⚠ THREE THINGS THIS ROUND REFUSED TO WRITE INTO THE .s
  * NO ROUTINE IS NAMED FROM A COLLIDING CODE.  Variant-1 groups 0x03/0x04 and
    0x05/0x06 emit byte-identical lists, so the action handlers 0xF8AE68 and
    0xF8AEDB are reached from two wires with identical (class, code, position)
    and stay `sub_XXXXXX`.  --collisions prints the pairs.
  * THE GROUP/SEGMENT DISAGREEMENT for the dial is repeated in the header, not
    reconciled.  Layer 1 puts the -1/+1 pair at segment 3; layer 2 puts code
    0x0D at group 0x0A; group == segment for wires 0xC0-0xCA.  One is wrong.
  * (0x2250) IS NOT NAMED.  It indexes a 32-entry pointer table and the
    33-byte list at 0xF8B325 is its accept list, so the two objects are named
    for the CELL -- `Var2250_AcceptList`, `RecordFieldPtrs_RAM76A2_Plus20` --
    and not for a role nobody has established.

★ TWO CORRECTIONS TO TEXT ALREADY IN THE .s, applied in the same edit
  * The old `PanelTables_F8B325` header said the pointers at 0xF8B346 run
    "0x000076A2 step 0x40".  THIRTY of the thirty-one steps are 0x40 and ONE IS
    0x80: entry 7 is 0x7862 and entry 8 is 0x78E2, so the record at 0x78A2 is
    SKIPPED.  `--ptrtables` prints the deltas.  The tree already knew this from
    the other end -- the header of `RecordPtrs_RAM76A2` (0xFEB330) records "THE
    SAME SINGLE 0x80 STEP in the same place" for a table in a different module
    -- so this block is a THIRD independent witness to the same layout.
  * The `PanelWireGroupMap_Variant1` header ended "⚠ What a GROUP id then
    selects is NOT established here."  It is established now: the group indexes
    `PanelGroupEventLists_Variant1/2`.  The warning is replaced by the answer
    and the address that carries it.

★★ THE JOB-2 ANSWER IS A REFUSAL, AND IT IS THE HONEST ONE
  This round was asked to build "the census that is still owed" of prom_a's
  2,822 `sub_XXXXXX` -- call sites, caller shape, what the body touches, leaf,
  length, flow end, buckets, and the size of the last bucket.
  ⚠ THAT CENSUS EXISTS, IS COMMITTED, AND STILL RUNS: `notes/prom_a_census_round8.py`.
  Re-run at this round's start it printed, on the LIVE tree:

      S1 277  S2 47  S3 119  S4 15   (shape)
      T1 1  T2 6  T3 118  T4 67  T5 63  C1 30   (touch / caller)
      N 1932 of 2822 = 68.5%  -- no distinguishing evidence of any kind

  and re-run after this round's 36 names, on the same live tree:

      N 1921 of 2800 = 68.6%

  -- the COUNT fell by 11 and the RATIO did not move, which is exactly what
  round 8's docstring says to expect ("QUOTE THE RATIO, NOT THE COUNT").  Its
  C1 bucket rose 30 -> 38, because naming a routine hands every one of its
  callers a content-named caller it did not have before.

  Its `--dump` already prints, per routine, exactly the six columns asked
  for (`ext`, `n_ext`, `flw`, `leaf`, `end`, and d/s/t/c reference counts).
  Writing a second one would have produced a number to compare against itself.
  So `--census` here RE-RUNS round 8's and adds the one axis it does not have,
  below.

★ THE ONE NEW AXIS, AND IT IS ALSO A MEASURED REFUSAL
  A PURE WRAPPER is the one shape for which round 8's DISTINCTIVENESS filter is
  the wrong test.  A routine whose whole body is `call X; ret` IS X, so it can
  be named from X even when X is called by eighty others.  That is a real gap
  in the round-8 method, so this file measured what closing it buys:

      120 pure wrappers in prom_a  (108 `call/calr` + `ret`, 12 bare `jp/jrl`)
       97 of them forward to another `sub_XXXXXX`
        9 forward to an address carrying no top-level label at all
       14 forward to a CONTENT-named routine   <- the entire yield

  FOURTEEN of 2,822, 0.5%.  The mechanism is sound and nearly empty, which is
  worth writing down so round 12 does not re-derive it.

  ⚠ AND ONE OF ITS OWN NUMBERS WAS WRONG FIRST, so it is recorded here rather
  than quietly fixed.  The first run of this census said 190 wrappers, because
  the source parser required TWO spaces after a line's address comment and so
  dropped 2,989 `.byte` lines that end at the address with no gloss -- which
  in turn attached some labels to the wrong line.  The parser now accepts an
  address with no trailing comment; the 14-name yield did not change, the
  population did.  Check M1 exists because of the same class of error.  The 14 ARE applied
  (`--wrappers`), each verified to end at the next top-level label so the
  round-5 painter error -- scoping a routine to a source line instead of to its
  own `ret` -- cannot recur here.

RUN
    python3 notes/prom_a_panel_names_round11.py --selftest    # every check
    python3 notes/prom_a_panel_names_round11.py --tables      # the nine objects
    python3 notes/prom_a_panel_names_round11.py --producers   # the 0x0E hunt
    python3 notes/prom_a_panel_names_round11.py --ptrtables   # the 0x80 step
    python3 notes/prom_a_panel_names_round11.py --collisions  # what may not be named
    python3 notes/prom_a_panel_names_round11.py --wrappers    # the 14
    python3 notes/prom_a_panel_names_round11.py --census      # the JOB-2 answer
    python3 notes/prom_a_panel_names_round11.py --emit        # the block text
    python3 notes/prom_a_panel_names_round11.py --apply       # edit the .s
    python3 notes/prom_a_panel_names_round11.py --verify      # after the gate
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
A_BASE = 0xF80000
B_BASE = 0xF00000
A_SRC = os.path.join(ROOT, "prom_a", "wsa1_prom_a.s")
_a = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
_b = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()


def by(p):
    return _a[p - A_BASE]


def blk(p, n):
    return _a[p - A_BASE:p - A_BASE + n]


def le32(p):
    return int.from_bytes(blk(p, 4), "little")


# ---------------------------------------------------------------------------
# 1. THE SIX LOADS THAT FRAME THE BLOCK.  Every boundary below is either one of
#    these operands or an abutment against the next one.
# ---------------------------------------------------------------------------
LOADS = [
    (0xF8B2EE, 0x45, 0xF8B325, "ld XIY,0xF8B325  (accept-list scan, sub_F8B2EA)"),
    (0xF8B30F, 0x45, 0xF8B325, "ld XIY,0xF8B325  (accept-list scan, sub_F8B307)"),
    (0xF8AA31, 0x44, 0xF8B3C6, "ld XIX,0xF8B3C6  (record +0x20 pointers)"),
    (0xF8A84C, 0x44, 0xF8B446, "ld XIX,0xF8B446  (event lists, variant 1)"),
    (0xF8A857, 0x44, 0xF8B4B2, "ld XIX,0xF8B4B2  (event lists, variant 2)"),
    (0xF8A8CC, 0x45, 0xF8B74A, "ld XIY,0xF8B74A  (action table, variant 1)"),
    (0xF8A8D7, 0x45, 0xF8B7AE, "ld XIY,0xF8B7AE  (action table, variant 2)"),
]

BLOCK_LO = 0xF8B325
BLOCK_HI = 0xF8BBB4          # exclusive; 0xF8BBB4 begins 76 bytes of 0x0E pad

ACCEPT = 0xF8B325
PTRS_BASE = 0xF8B346
PTRS_P20 = 0xF8B3C6
EV1 = 0xF8B446
EV2 = 0xF8B4B2
EVPOOL = 0xF8B51E
AC1 = 0xF8B74A
AC2 = 0xF8B7AE
ACPOOL = 0xF8B812


def check_loads():
    """Every framing load really is the instruction this file says it is."""
    bad = []
    for addr, op, target, _ in LOADS:
        want = bytes([op, target & 0xFF, (target >> 8) & 0xFF, (target >> 16) & 0xFF, 0x00])
        if blk(addr, 5) != want:
            bad.append((addr, blk(addr, 5).hex(), want.hex()))
    return bad


# ---------------------------------------------------------------------------
# 2. THE TWO RAM POINTER TABLES.  32 entries each; the second is the first
#    plus 0x20, entry for entry; the steps are 0x40 THIRTY TIMES AND 0x80 ONCE.
# ---------------------------------------------------------------------------
def ptr_tables():
    t1 = [le32(PTRS_BASE + 4 * i) for i in range(32)]
    t2 = [le32(PTRS_P20 + 4 * i) for i in range(32)]
    return t1, t2


def ptr_facts():
    t1, t2 = ptr_tables()
    deltas = [t1[i + 1] - t1[i] for i in range(31)]
    odd = [i for i, d in enumerate(deltas) if d != 0x40]
    return t1, t2, deltas, odd


# ---------------------------------------------------------------------------
# 3. THE EVENT LISTS.  27 slots by abutment; 25 reachable, because the walker
#    rejects a group above 0x18 (`cp A,0x18` / `jr ugt` at 0xF8A83B).
#    A record is 4 bytes [class][code][shift][mask]; a list ends on 0xFF in
#    byte 0, and the terminator is ONE byte (the walker tests only byte 0).
# ---------------------------------------------------------------------------
EV_SLOTS = (EV2 - EV1) // 4              # 27
AC_SLOTS = (ACPOOL - AC2) // 4           # 25
GROUP_MAX = 0x18                         # `cp A,0x18` at 0xF8A83B


def ev_lists(base):
    out = []
    for g in range(EV_SLOTS):
        p = le32(base + 4 * g)
        recs = []
        q = p
        while by(q) != 0xFF:
            recs.append((q, tuple(blk(q, 4))))
            q += 4
        out.append((g, p, q, recs))
    return out


def ac_lists(base):
    out = []
    for g in range(AC_SLOTS):
        p = le32(base + 4 * g)
        recs = []
        q = p
        while by(q) != 0xFF:
            recs.append((q, by(q), by(q + 1), int.from_bytes(blk(q + 2, 4), "little")))
            q += 6
        out.append((g, p, q, recs))
    return out


def pool_extents():
    """The two pools' real extents, walked -- not assumed from the abutment."""
    ev = ev_lists(EV1) + ev_lists(EV2)
    ac = ac_lists(AC1) + ac_lists(AC2)
    ev_lo = min(p for _, p, _, _ in ev)
    ev_hi = max(q for _, _, q, _ in ev) + 1        # +1 for the 1-byte 0xFF
    ac_lo = min(p for _, p, _, _ in ac)
    ac_hi = max(q for _, _, q, _ in ac) + 6        # +6 for the 6-byte 0xFF record
    return ev_lo, ev_hi, ac_lo, ac_hi


# ---------------------------------------------------------------------------
# 4. THE COLLISIONS.  Byte-identical lists reached from different wires.
# ---------------------------------------------------------------------------
def collisions():
    out = []
    for base, tag in ((EV1, "variant 1"), (EV2, "variant 2")):
        ls = ev_lists(base)
        seen = {}
        for g, p, q, recs in ls:
            if not recs:
                continue
            key = bytes(b for _, r in recs for b in r)
            if key in seen and seen[key][1] != p:
                out.append((tag, seen[key][0], g, len(recs)))
            seen.setdefault(key, (g, p))
    return out


# ---------------------------------------------------------------------------
# 5. THE SEVEN NON-WIRE PRODUCERS.  Six are inside sub_F8A303 and carry a fixed
#    group immediate; the seventh takes its group from RAM at run time.
# ---------------------------------------------------------------------------
APPENDER = 0xF8A3B2
# (call site, `ldb E,imm` site, `and (flag),0x7F` site, flag cell, group)
PRODUCERS = [
    (0xF8A322, 0xF8A31E, 0xF8A319, 0x28EE, 0x10),
    (0xF8A33E, 0xF8A33A, 0xF8A335, 0x28EF, 0x11),
    (0xF8A35A, 0xF8A356, 0xF8A351, 0x28F0, 0x12),
    (0xF8A376, 0xF8A372, 0xF8A36D, 0x28F1, 0x13),
    (0xF8A392, 0xF8A38E, 0xF8A389, 0x28EC, 0x14),
    (0xF8A3AE, 0xF8A3AA, 0xF8A3A5, 0x28ED, 0x15),
]
RUNTIME_PRODUCER = (0xF8A2D6, 0xF8A2D2, 0x219C)
WIRE_DRAIN_CALL = 0xF8A0F2


def calr_target(addr):
    """`calr disp16` (0x1E) -- target = addr + 3 + signed(disp)."""
    assert by(addr) == 0x1E, "%06X is not a calr" % addr
    d = int.from_bytes(blk(addr + 1, 2), "little")
    if d >= 0x8000:
        d -= 0x10000
    return addr + 3 + d


def producer_facts():
    rows = []
    for call, ldsite, andsite, cell, group in PRODUCERS:
        ok_call = calr_target(call) == APPENDER
        ok_ld = blk(ldsite, 2) == bytes([0x25, group])          # ldb E,imm8
        ok_and = blk(andsite, 5) == bytes([0xC1, cell & 0xFF, cell >> 8, 0x3C, 0x7F])
        rows.append((call, cell, group, ok_call, ok_ld, ok_and))
    return rows


def group_codes(group):
    """Which (class, code) pairs the variant-1 list for `group` emits."""
    for g, p, q, recs in ev_lists(EV1):
        if g == group:
            return [(r[0], r[1]) for _, r in recs]
    return []


# ---------------------------------------------------------------------------
# 6. THE STALE WALKER COPY at 0xF8A44B.  Three independent measurements.
# ---------------------------------------------------------------------------
STALE = 0xF8A44B
LIVE = 0xF8A84B
STALE_TABLES = (0xF8ADDD, 0xF8AD71, 0xF8AF9F)
LIVE_TABLES = (EV1, EV2, AC1)


def stale_facts():
    n = 0x7B
    diff = [i for i in range(n) if by(STALE + i) != by(LIVE + i)]
    inptr = {}
    for t in STALE_TABLES + LIVE_TABLES:
        inptr[t] = sum(1 for i in range(4)
                       if A_BASE <= le32(t + 4 * i) < A_BASE + len(_a))
    refs = ref_scan(STALE)
    return diff, inptr, refs


def ref_scan(target):
    """Every 24-bit little-endian mention of `target` in either of CPU 1's ROMs."""
    le = bytes([target & 0xFF, (target >> 8) & 0xFF, (target >> 16) & 0xFF])
    hits = []
    for nm, d, base in (("prom_a", _a, A_BASE), ("prom_b", _b, B_BASE)):
        i = 0
        while True:
            i = d.find(le, i)
            if i < 0:
                break
            hits.append((nm, base + i))
            i += 1
    return hits


# ---------------------------------------------------------------------------
# 7. THE EMITTER.  It re-derives every boundary above on each run and refuses
#    to print unless the nine objects TILE 0xF8B325-0xF8BBB3 exactly.
# ---------------------------------------------------------------------------
def _hdr(lines):
    out = ["; " + "-" * 69]
    out += ["; " + l if l else ";" for l in lines]
    out += ["; " + "-" * 69, ""]
    return out


def _bytes_line(p, n, comment=""):
    body = ", ".join("0x%02x" % by(p + i) for i in range(n))
    pad = max(1, 60 - len("\t.byte " + body))
    return "\t.byte %s%s; %06X%s" % (body, " " * pad, p, ("  " + comment) if comment else "")


def _long_line(p, comment=""):
    body = "0x%08x" % le32(p)
    pad = max(1, 53 - len("\t.long " + body))
    return "\t.long %s%s; %06X%s" % (body, " " * pad, p, ("  " + comment) if comment else "")


def emit_block():
    t1, t2, deltas, odd = ptr_facts()
    ev_lo, ev_hi, ac_lo, ac_hi = pool_extents()
    assert (ev_lo, ev_hi, ac_lo, ac_hi) == (EVPOOL, AC1, ACPOOL, BLOCK_HI), \
        "a pool moved: %06X %06X %06X %06X" % (ev_lo, ev_hi, ac_lo, ac_hi)
    assert not check_loads(), "a framing load moved"
    assert odd == [7] and deltas[7] == 0x80, "the record-pointer step changed"

    L = []
    L += _hdr([
        "THE PANEL LAYER-2 TABLES -- 0xF8B325-0xF8BBB3, 2,191 bytes, NINE objects.",
        "",
        "This block was one undifferentiated `.byte` region called",
        "PanelTables_F8B325 until round 11.  It is the table half of the panel",
        "event pipeline, and the pipeline is now readable end to end:",
        "",
        "  CP1 panel MCU  --3 bytes-->  prom_b SC1_RxOp0_ThreeByte (0xF5B0D5)",
        "     queues [wire][new value][old XOR new] at RAM 0x2B40",
        "  PanelWireQueue_DrainToGroupQueue (0xF8A088) drains it, maps the wire",
        "     through PanelWireGroupMap_Variant1/2 to a GROUP id, and calls",
        "  PanelGroupQueue_Append (0xF8A3B2), which appends",
        "     [group][value][change mask] to a second queue at RAM 0x2000",
        "     (count in (0x219A), hard limit 7 records)",
        "  PanelGroupQueue_ExpandToEvents (0xF8A824) walks that queue and, PER",
        "     GROUP, fetches ONE LIST from the tables below and writes UI events",
        "     to the fixed list at RAM 0x2030",
        "  UiEvent_RouteByCode (0xF8659B) then dispatches on the event's code.",
        "",
        "★ WHY THE BOUNDARIES ARE NOT GUESSES.  Six of the nine objects are the",
        "  operand of an `ld XIX/XIY,imm32` in the code above -- 0xF8B2EE and",
        "  0xF8B30F (accept list), 0xF8AA31, 0xF8A84C, 0xF8A857, 0xF8A8CC,",
        "  0xF8A8D7.  The other three are pinned by ABUTMENT: each pointer",
        "  table's length is exactly (next load - this load), and each pool runs",
        "  from its lowest list to the byte before the next loaded table.  The",
        "  nine tile the block with no byte left over, and",
        "  notes/prom_a_panel_names_round11.py asserts that tiling on every run.",
        "",
        "★ RECORD SHAPES, both pinned by GEOMETRY, not by a stride that looked",
        "  plausible: an event-list record is 4 bytes and all 39 gaps between",
        "  consecutive lists in the event pool are 1 mod 4; an action-list record",
        "  is 6 bytes; both pools end on the byte before the next object.",
        "",
        "⚠ WHAT IS STILL NOT KNOWN, stated rather than smoothed over:",
        "  * NOBODY FOUND PRODUCES EVENT CODE 0x0E, though UiEvent_RouteByCode",
        "    has an 0x0E arm.  The six fixed-group producers in",
        "    PanelGroupQueue_AppendFlaggedGroups emit code 0x00 only, and the",
        "    seventh producer (0xF8A2D6) takes its group from RAM (0x219C) at",
        "    run time, so no static read can enumerate it.",
        "  * THREE PAIRS OF VARIANT-1 LISTS ARE BYTE-IDENTICAL -- groups",
        "    0x01/0x02, 0x03/0x04 and 0x05/0x06 -- so identical (class, code,",
        "    position) triples arrive from two different wires.  NO ROUTINE IN",
        "    THIS MODULE IS NAMED FROM A COLLIDING CODE.",
        "  * THE GROUP NUMBERING AND THE PHYSICAL SEGMENT NUMBERING DISAGREE FOR",
        "    THE DIAL.  notes/wave7_panel_button_codes.py puts the -1/+1 pair at",
        "    matrix segment 3; the table below puts code 0x0D (proven to be that",
        "    pair by the sign argument in notes/wave7_panel_event_index.py) at",
        "    GROUP 0x0A, and group == segment for wires 0xC0-0xCA.  One of the",
        "    two maps is wrong.  Neither has been edited to hide it.",
        "  * WHAT (0x2250) HOLDS.  Two objects here are named for that cell",
        "    because it is the only thing established about them.",
        "",
        "Evidence: the seven framing loads listed above, `cp A,0x18` at 0xF8A83B,",
        "         `cp (XHL),0xff` at 0xF8A862, `ld WA,(XHL+)`/`ld (XIX+),WA` at",
        "         0xF8A867/0xF8A86A, `ld W,(XHL)` + `and D,W`/`and E,W` at",
        "         0xF8A877-0xF8A87D, `ld (XIX+),DE` at 0xF8A90B.",
    ])

    # --- 1. the accept list -------------------------------------------------
    n = PTRS_BASE - ACCEPT
    L += _hdr([
        "Var2250_AcceptList -- %d bytes: 0x00..0x%02X then a 0xFF terminator." % (n, n - 2),
        "",
        "It is a MEMBERSHIP LIST, not an identity map.  Two routines scan it",
        "for the byte in (0x2250) and CLAMP on a miss:",
        "  sub_F8B2EA  miss -> C = 0x20, then `or C,0x20`, then store to (XIX)",
        "  sub_F8B307  miss -> C = 0x00, then store to (XIX)",
        "★ AND THE RANGE IS NOT ARBITRARY.  0xF8AA31 uses the SAME cell as an",
        "  index into RecordFieldPtrs_RAM76A2_Plus20, which has exactly %d" % len(t2),
        "  entries -- so this list is the valid-index test for that table.",
        "⚠ What (0x2250) MEANS is not established; the name states the cell.",
        "Evidence: `ld XIY,0x00F8B325` at 0xF8B2EE and 0xF8B30F, the scan",
        "         `ld A,(XIY+)` / `cp A,C` / `cp A,0xFF` at 0xF8B2F3-0xF8B2FD,",
        "         `ld C,(0x2250)` at 0xF8B2EA and 0xF8B30B, and",
        "         `ld A,(0x2250)` / `sla A,2` at 0xF8AA36-0xF8AA3A.",
    ])
    L.append("Var2250_AcceptList:")
    p = ACCEPT
    while p < PTRS_BASE:
        w = min(16, PTRS_BASE - p)
        L.append(_bytes_line(p, w))
        p += w

    # --- 2/3. the two RAM record pointer tables -----------------------------
    L += _hdr([
        "RecordPtrs_RAM76A2_Panel -- %d x LE32 into the 64-byte RAM records" % len(t1),
        "at 0x%04X.  A THIRD COPY of a pointer array this tree already knows," % t1[0],
        "and the agreement is EXACT, not approximate: the first 32 of",
        "RecordPtrs_RAM76A2's 35 entries (0xFEB330) are byte-identical to these",
        "32, and 0xFF4251's 16 entries are these same bases plus 13.",
        "★ THE STEP IS NOT UNIFORM, and the header this replaced said it was.",
        "  Thirty of the thirty-one steps are 0x40; step %d is 0x80, so the" % odd[0],
        "  record at 0x%04X is SKIPPED (entry %d is 0x%04X, entry %d is 0x%04X)."
        % (t1[odd[0]] + 0x40, odd[0], t1[odd[0]], odd[0] + 1, t1[odd[0] + 1]),
        "  The 0xFEB330 header records the same single 0x80 step in the same",
        "  place, from a different module -- three witnesses, one layout.",
        "⚠ NO READER FOUND.  A scan of both of CPU 1's ROMs for `ld XRR,imm32`,",
        "  `call`, `jp` and a bare LE32 pointer naming 0xF8B346 returns NOTHING,",
        "  while the sibling below is loaded at 0xF8AA31.  The bound of the",
        "  reader that would use it is therefore unknown; %d is the ABUTMENT" % len(t1),
        "  against 0xF8B3C6, not a count read off a reader.",
        "Evidence: the abutment 0xF8B3C6 - 0xF8B346 = 0x%02X = %d x 4; the "
        % (PTRS_P20 - PTRS_BASE, len(t1)),
        "         entry-by-entry difference to the sibling is 0x20 for all %d." % len(t1),
    ])
    L.append("RecordPtrs_RAM76A2_Panel:")
    for i in range(len(t1)):
        L.append(_long_line(PTRS_BASE + 4 * i, "[%2d] RAM record %d" % (i, i)))

    L += _hdr([
        "RecordFieldPtrs_RAM76A2_Plus20 -- %d x LE32, each pointing 0x20 bytes" % len(t2),
        "into the same record the table above points at the base of.  The",
        "difference is 0x20 for every one of the %d entries." % len(t2),
        "Read by: 0xF8AA31 `ld XIX,0x00F8B3C6`, then `ld A,(0x2250)` /",
        "         `sla A,2` / `ld XIX,(XIX+A)` at 0xF8AA36-0xF8AA3D, then",
        "         `ld A,(XIX+0x18)` and `bit 0,A` at 0xF8AA42-0xF8AA46.",
        "         So the caller reads bit 0 of the record byte at +0x38.",
        "Evidence: the load at 0xF8AA31; the index cell (0x2250) is the same",
        "         cell Var2250_AcceptList validates.",
    ])
    L.append("RecordFieldPtrs_RAM76A2_Plus20:")
    for i in range(len(t2)):
        L.append(_long_line(PTRS_P20 + 4 * i, "[%2d] RAM record %d + 0x20" % (i, i)))

    # --- 4/5. the two event-list tables ------------------------------------
    for base, nxt, name, var, site in ((EV1, EV2, "PanelGroupEventLists_Variant1", 1, 0xF8A84C),
                                       (EV2, EVPOOL, "PanelGroupEventLists_Variant2", 2, 0xF8A857)):
        ls = ev_lists(base)
        live = sum(1 for g, _, _, r in ls if g <= GROUP_MAX and r)
        L += _hdr([
            "%s -- %d x LE32 list heads." % (name, EV_SLOTS),
            "",
            "★★ THIS IS THE LAYER-2 TABLE: the map from a panel GROUP id to the",
            "UI EVENTS that group's wire raises.  It is a TABLE, not a",
            "computation, which is why a search for an `ld DE,0x00A9`-shaped",
            "event post found nothing anywhere in the four images -- the class",
            "byte 0xA9 is a DATA BYTE in the lists below, copied to the event.",
            "",
            "Read by: PanelGroupQueue_ExpandToEvents.  `ld XIX,0x00F8B446` at",
            "         0xF8A84C and `ld XIX,0x00F8B4B2` at 0xF8A857; `cp (0xC4),",
            "         0x01` at 0xF8A851 picks between them -- (0xC4) is the",
            "         MODEL STRAP, the same byte PanelWireGroupMap picks on.",
            "         The index is the group id, `sla WA,2` at 0xF8A846.",
            "ENTRY COUNT %d is the ABUTMENT (0x%06X - 0x%06X) / 4, NOT a bound"
            % (EV_SLOTS, nxt, base),
            "         in the reader.  The reader's bound is LOWER: `cp A,0x18` /",
            "         `jr ugt` at 0xF8A83B rejects any group above 0x18, so",
            "         slots 0x19 and 0x1A CANNOT BE REACHED.  %d of the %d"
            % (live, EV_SLOTS),
            "         reachable slots have a non-empty list.",
            "Evidence: the load at 0x%06X; the terminator test `cp (XHL),0xff`" % site,
            "         at 0xF8A862; `ld WA,(XHL+)` / `ld (XIX+),WA` at",
            "         0xF8A867/0xF8A86A copy [class][code] into the event.",
        ])
        L.append("%s:" % name)
        for g, p, q, recs in ls:
            note = "[0x%02X] %d record%s" % (g, len(recs), "" if len(recs) == 1 else "s")
            if g > GROUP_MAX:
                note += "  UNREACHABLE (group > 0x%02X)" % GROUP_MAX
            elif not recs:
                note += "  (empty)"
            L.append(_long_line(base + 4 * g, note))

    # --- 6. the event-list pool --------------------------------------------
    starts = {}
    for base, var in ((EV1, 1), (EV2, 2)):
        for g, p, q, recs in ev_lists(base):
            starts.setdefault(p, []).append("v%d g%02X" % (var, g))
    L += _hdr([
        "PanelGroupEventListPool -- %d bytes, the lists both tables point into."
        % (AC1 - EVPOOL),
        "",
        "A RECORD IS FOUR BYTES:",
        "  [0] event CLASS   copied to the event's +0",
        "  [1] event CODE    copied to the event's +1  (a BASE -- an action",
        "                    handler may rewrite it, see the action tables)",
        "  [2] SHIFT byte    bit 4 = direction, bits 0-2 = count (0xF8A8AA,",
        "                    `and A,0x07` at 0xF8A8AF and 0xF8A8B8)",
        "  [3] BIT MASK      which bits of this wire byte the record owns",
        "and a list ends on 0xFF in byte 0 -- a ONE-byte terminator, because",
        "`cp (XHL),0xff` at 0xF8A862 tests byte 0 only.",
        "",
        "★ ONE CODE COVERS A PAIR OF MATRIX BITS.  Most button records carry a",
        "single-bit mask and a shift that lands that bit on position 0 or 1 of a",
        "two-bit field, so two records share a code and differ only in position;",
        "`bit 0,(0x20B9)` at 0xF866C7 and 0xF86708 sets bit 7 of the delivered",
        "code for position 0.  That is how 32 codes reach 58 switches.",
        "",
        "Evidence: the pool runs from the lowest list head (0x%06X) to the byte"
        % EVPOOL,
        "         before PanelGroupActionTable_Variant1 (0x%06X), and the 54"
        % AC1,
        "         list walks tile it with no byte left over.",
    ])
    L.append("PanelGroupEventListPool:")
    p = EVPOOL
    while p < AC1:
        if p in starts:
            L.append("\t; -- %s" % ", ".join(starts[p]))
        if by(p) == 0xFF:
            L.append(_bytes_line(p, 1, "end of list"))
            p += 1
        else:
            c, k, s, mk = blk(p, 4)
            L.append(_bytes_line(p, 4, "class %02X code %02X shift %02X mask %02X"
                                 % (c, k, s, mk)))
            p += 4

    # --- 7/8. the two action tables ----------------------------------------
    for base, nxt, name, site in ((AC1, AC2, "PanelGroupActionTable_Variant1", 0xF8A8CC),
                                  (AC2, ACPOOL, "PanelGroupActionTable_Variant2", 0xF8A8D7)):
        ls = ac_lists(base)
        L += _hdr([
            "%s -- %d x LE32 list heads." % (name, AC_SLOTS),
            "",
            "An ACTION list lets a handler intercept a (group, mask) pair AFTER",
            "the class/code pair has been written to the event but BEFORE the",
            "value pair is.  Two of the handlers REWRITE the code byte in place",
            "-- `add (XIX-1),0x11` at 0xF8AE7E/0xF8AEF1 and `ld (XIX-1),0x19` at",
            "0xF8AE8A/0xF8AEFD -- and any handler may end at 0xF8A90F",
            "(`dec 2,XIX`), which DROPS the event.  So a code in the event pool",
            "is a BASE, and the delivered code can be base, base+0x11 or 0x19.",
            "⚠ WHICH BRANCH IS TAKEN AT RUN TIME IS NOT ESTABLISHED.",
            "",
            "Read by: PanelEvent_ShiftThenRunAction.  `ld XIY,0x00F8B74A` at",
            "         0xF8A8CC and `ld XIY,0x00F8B7AE` at 0xF8A8D7, the same",
            "         (0xC4) strap test at 0xF8A8D1; the index is (0x2251), the",
            "         group the walker stored at 0xF8A840, `sla L,2` at 0xF8A8E0.",
            "ENTRY COUNT %d is the abutment (0x%06X - 0x%06X) / 4, and here it"
            % (AC_SLOTS, nxt, base),
            "         AGREES with the reader: groups 0x00-0x%02X inclusive is" % GROUP_MAX,
            "         exactly %d slots." % AC_SLOTS,
            "Evidence: the load at 0x%06X; the record walk `ld BC,(XIY+HL)` /" % site,
            "         `cp C,0xff` / `cp WA,BC` at 0xF8A8EA-0xF8A8F8 and the",
            "         handler fetch `ld XBC,(XIY+HL)` / `jp (XBC)` at",
            "         0xF8A902-0xF8A909.",
        ])
        L.append("%s:" % name)
        for g, p, q, recs in ls:
            note = "[0x%02X] %d record%s" % (g, len(recs), "" if len(recs) == 1 else "s")
            if not recs:
                note += "  (empty)"
            L.append(_long_line(base + 4 * g, note))

    # --- 9. the action-list pool -------------------------------------------
    astarts = {}
    for base, var in ((AC1, 1), (AC2, 2)):
        for g, p, q, recs in ac_lists(base):
            astarts.setdefault(p, []).append("v%d g%02X" % (var, g))
    L += _hdr([
        "PanelGroupActionListPool -- %d bytes, the lists both action tables"
        % (BLOCK_HI - ACPOOL),
        "point into.",
        "",
        "A RECORD IS SIX BYTES: [group][mask][LE32 handler], and a list ends on",
        "a record whose group byte is 0xFF.  The terminator is a WHOLE SIX-BYTE",
        "record, not one byte, because the walk steps by 6 (`inc 4,HL` after an",
        "`inc 2,HL` at 0xF8A8EF/0xF8A8FA) -- which is also why several empty",
        "lists share the single terminator at the end of the pool.",
        "The key compared is the 16-bit (mask:group) pair: `cp WA,BC` at",
        "0xF8A8F6 with BC loaded from the record and WA holding (mask, group).",
        "",
        "Evidence: the pool runs from the lowest list head (0x%06X) to the last"
        % ACPOOL,
        "         byte of the block (0x%06X), and the 50 list walks tile it" % (BLOCK_HI - 1),
        "         with no byte left over.",
    ])
    L.append("PanelGroupActionListPool:")
    p = ACPOOL
    while p < BLOCK_HI:
        if p in astarts:
            L.append("\t; -- %s" % ", ".join(astarts[p]))
        if by(p) == 0xFF:
            L.append(_bytes_line(p, 6, "end of list"))
        else:
            L.append(_bytes_line(p, 6, "group %02X mask %02X -> 0x%06X"
                                 % (by(p), by(p + 1), int.from_bytes(blk(p + 2, 4), "little"))))
        p += 6
    assert p == BLOCK_HI, "action pool did not tile: stopped at %06X" % p
    return L


# ---------------------------------------------------------------------------
# 8. THE THREE BIT-MASK LOOKUP SIBLINGS at 0xF8A93B-0xF8AA17.
#    The .s decodes the three DATA tables as instructions, which desynchronises
#    the stream and HIDES two routine entries (0xF8A944 and 0xF8A97D) inside
#    bogus `ld XWA,imm32` operands.  The bytes are right; the meaning is not.
# ---------------------------------------------------------------------------
BM = [
    # (table addr, entry width, entries, table name, routine addr, routine name, clamp)
    (0xF8A93B, 1,  9, "BitMask8ByIndex",  0xF8A927, "IndexToBitMask8",  0x08),
    (0xF8A95B, 2, 17, "BitMask16ByIndex", 0xF8A944, "IndexToBitMask16", 0x10),
    (0xF8A994, 4, 33, "BitMask32ByIndex", 0xF8A97D, "IndexToBitMask32", 0x20),
]
BM_LO, BM_HI = 0xF8A93B, 0xF8AA18


def bitmask_facts():
    """Each table really is 0 then 1<<(i-1); each routine really clamps to it."""
    rows = []
    for tab, w, n, tn, rt, rn, clamp in BM:
        vals = [int.from_bytes(blk(tab + w * i, w), "little") for i in range(n)]
        want = [0] + [1 << i for i in range(n - 1)]
        ok_tab = vals == want
        ok_len = n == clamp + 1
        ok_clamp = blk(rt + 1, 3) == bytes([0xCD, 0xCF, clamp])      # cp E,clamp
        ldsite = rt + (8 if w == 1 else 11)          # after the clamp (+ the sla)
        ok_load = by(ldsite) == 0x44                 # ld XIX,imm32
        ok_ptr = int.from_bytes(blk(ldsite + 1, 3), "little") == tab
        rows.append((tn, rn, tab, rt, n, ok_tab, ok_len, ok_clamp, ok_ptr, vals[-1]))
    return rows


def roundtrip(lo, hi):
    """Certified assembly for a code range -- prom_a/roundtrip.py has already
    assembled it and compared it to the ROM byte for byte."""
    r = subprocess.run([sys.executable, os.path.join(ROOT, "prom_a", "roundtrip.py"),
                        "0x%X" % lo, "0x%X" % hi, "--block"],
                       capture_output=True, text=True, check=True)
    assert "round-trip: OK" in (r.stdout + r.stderr), (r.stdout[:200], r.stderr[:200])
    out = [l for l in r.stdout.split("\n") if l.strip()
           and not l.strip().startswith("round-trip:")]
    # AND CHECK IT OURSELVES: every emitted line's address+bytes must be the ROM.
    p = lo
    for l in out:
        m = _ADDR.search(l)
        if not m:
            continue                       # a label line
        a = int(m.group(1), 16)
        bs = [int(x, 16) for x in m.group(2).split()
              if re.fullmatch(r"[0-9a-fA-F]{2}", x)]
        assert a == p, "roundtrip gap: expected %06X got %06X" % (p, a)
        assert bytes(bs) == blk(a, len(bs)), "roundtrip byte mismatch at %06X" % a
        p += len(bs)
    assert p == hi, "roundtrip stopped at %06X, wanted %06X" % (p, hi)
    return out


def emit_bitmask_block():
    rows = bitmask_facts()
    assert all(r[5] and r[6] and r[7] and r[8] for r in rows), rows
    L = []
    L += _hdr([
        "THE THREE BIT-MASK LOOKUP SIBLINGS -- 0x%06X-0x%06X." % (BM_LO, BM_HI - 1),
        "",
        "⚠ THIS RANGE WAS MIS-DECODED UNTIL ROUND 11.  Three DATA tables were",
        "emitted as instructions, and because a table byte pair like `40 80`",
        "starts a 5-byte `ld XWA,imm32`, the decode ran PAST the end of each",
        "table and swallowed the entry of the routine that follows it.  Two",
        "routine entry points -- 0x%06X and 0x%06X -- were inside a bogus"
        % (BM[1][4], BM[2][4]),
        "operand and had no label.  The bytes were always right; the gate",
        "cannot see a wrong decode, which is exactly why this was invisible.",
        "",
        "Each routine converts an INDEX to a ONE-HOT MASK by table lookup:",
        "  IndexToBitMask8   `cp E,0x08` clamps,  9 x u8  -> E",
        "  IndexToBitMask16  `cp E,0x10` clamps, 17 x u16 -> DE",
        "  IndexToBitMask32  `cp E,0x20` clamps, 33 x u32 -> XDE",
        "and the result always lands in the E/DE/XDE register the index",
        "arrived in (`r5`, `r2`, `r2` at 0xF8A934, 0xF8A954 and 0xF8A98D).",
        "and index 0 maps to 0 in all three, so entry i is 1 << (i-1).  An",
        "out-of-range index is forced to 0 (`xor E,E`), i.e. to the zero mask,",
        "not clamped to the top entry.",
        "★ LowestSetBitIndex1Based (0xF8A913) is the INVERSE of the 8-bit one:",
        "  it returns the 1-based position of the lowest set bit, which is the",
        "  index this table turns back into a mask.",
        "Evidence: the clamp `cp E,0x%02X` at 0x%06X, 0x%06X and 0x%06X; the"
        % (BM[0][6], BM[0][4] + 1, BM[1][4] + 1, BM[2][4] + 1),
        "         table loads `ld XIX,imm32` at 0xF8A92F, 0xF8A94F and 0xF8A988;",
        "         the last entry of each table is 0x%02X, 0x%04X and 0x%08X."
        % (rows[0][9], rows[1][9], rows[2][9]),
    ])

    def table(tab, w, n, name, comment):
        L.append("%s:" % name)
        directive = {1: ".byte", 2: ".short", 4: ".long"}[w]
        fmt = {1: "0x%02x", 2: "0x%04x", 4: "0x%08x"}[w]
        per = {1: 9, 2: 8, 4: 4}[w]
        i = 0
        while i < n:
            k = min(per, n - i)
            vals = [int.from_bytes(blk(tab + w * (i + j), w), "little") for j in range(k)]
            body = ", ".join(fmt % v for v in vals)
            pad = max(1, 60 - len("\t%s %s" % (directive, body)))
            L.append("\t%s %s%s; %06X  [%2d..%2d]%s"
                     % (directive, body, " " * pad, tab + w * i, i, i + k - 1,
                        ("  " + comment) if i == 0 else ""))
            i += k

    table(BM[0][0], 1, 9, "BitMask8ByIndex", "index -> 1 << (index-1), 0 for 0")
    L.append("")
    L += _hdr([
        "IndexToBitMask16 -- E (0..16) -> DE = one-hot 16-bit mask.",
        "Entry was HIDDEN inside a mis-decoded table until round 11.",
        "Evidence: `push XIX` at 0x%06X, `cp E,0x10` at 0x%06X, `xor E,E` at"
        % (BM[1][4], BM[1][4] + 1),
        "         0x%06X, `sla E,1` at 0x%06X, `ld XIX,0x00F8A95B` at 0x%06X."
        % (BM[1][4] + 6, BM[1][4] + 8, BM[1][4] + 11),
    ])
    L.append("IndexToBitMask16:")
    # ⚠ the .s carried a top-level label `sub_F8A954` at an INTERIOR instruction
    # of this routine; it is kept as an internal branch label so any citation of
    # that address still resolves, and so the sub_ count does not fall for a
    # label that was never an object.
    for l in roundtrip(BM[1][4], BM[1][0]):
        if "; F8A954" in l:
            L.append("IndexToBitMask16__F8A954:")
        L.append(l)
    L.append("")
    table(BM[1][0], 2, 17, "BitMask16ByIndex", "index -> 1 << (index-1), 0 for 0")
    L.append("")
    L += _hdr([
        "IndexToBitMask32 -- E (0..32) -> XDE = one-hot 32-bit mask.",
        "Entry was HIDDEN inside a mis-decoded table until round 11.",
        "Evidence: `push XIX` at 0x%06X, `cp E,0x20` at 0x%06X, `xor E,E` at"
        % (BM[2][4], BM[2][4] + 1),
        "         0x%06X, `sla E,2` at 0x%06X, `ld XIX,0x00F8A994` at 0x%06X."
        % (BM[2][4] + 6, BM[2][4] + 8, BM[2][4] + 11),
    ])
    L.append("IndexToBitMask32:")
    L += roundtrip(BM[2][4], BM[2][0])
    L.append("")
    table(BM[2][0], 4, 33, "BitMask32ByIndex", "index -> 1 << (index-1), 0 for 0")
    return L


# ---------------------------------------------------------------------------
# 9. THE PURE WRAPPERS.  A routine whose whole body is `call X; ret` (or a bare
#    `jp X`) IS X, so it can be named from X even when X is popular -- the one
#    shape for which round 8's DISTINCTIVENESS filter is the wrong test.
#    ⚠ The extent is taken to the NEXT TOP-LEVEL LABEL, never to a source line;
#    scoping to a source line is how the round-5 painter pass mis-attributed 6
#    of 24 names.
# ---------------------------------------------------------------------------
_LABEL = re.compile(r'^([A-Za-z_.][A-Za-z0-9_.]*):')
# ⚠ the trailing comment is OPTIONAL: an emitted `.byte` line with no gloss
# ends at the address, and requiring two spaces after it silently dropped every
# such line from the parse (which made the citation check below miss 0xF8B325).
_ADDR = re.compile(r';\s+([0-9A-F]{6})(?:\s\s(.*))?$')
_UNNAMED = re.compile(r'^sub_[0-9A-Fa-f]{6}$')
_INTERNAL = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*__[0-9A-Fa-f]{4,6}$')
_FRAMED = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*_'
                     r'(?:[0-9A-Fa-f]{2}x[0-9A-Fa-f]{2}_)?'
                     r'(?:[0-9A-Fa-f]{4,6}|[0-9]{1,4})$')


def parse_src(path=None):
    """(labels: addr -> [top-level names], items: [(addr, text, bytes)])."""
    lines = open(path or A_SRC).read().split("\n")
    labels, items, pending = {}, [], []
    for ln in lines:
        lm = _LABEL.match(ln)
        if lm:
            pending.append(lm.group(1))
            continue
        m = _ADDR.search(ln)
        if not m:
            continue
        a = int(m.group(1), 16)
        bs = [int(x, 16) for x in (m.group(2) or "").split()
              if re.fullmatch(r'[0-9a-fA-F]{2}', x)]
        for p in pending:
            labels.setdefault(a, []).append(p)
        pending = []
        items.append((a, ln.strip(), bs))
    return labels, items


def grade(nm):
    if _INTERNAL.match(nm):
        return "internal"
    if _UNNAMED.match(nm):
        return "sub"
    if _FRAMED.match(nm):
        return "framed"
    return "content"


def wrappers(path=None):
    """Every `sub_XXXXXX` in prom_a whose entire extent is one call plus a ret,
    or one unconditional jump.  Returns (all_rows, nameable_rows)."""
    labels, items = parse_src(path)
    idx = {a: i for i, (a, _, _) in enumerate(items)}

    def top(a):
        return [n for n in labels.get(a, []) if not n.startswith(".L")]

    rows = []
    for a, names in sorted(labels.items()):
        for n in names:
            # `_Entry` is the name --apply gives a wrapper, so the census stays
            # reproducible after the edit instead of silently emptying.
            if not (_UNNAMED.match(n) or n.endswith("_Entry")):
                continue
            i = idx.get(a)
            if i is None:
                continue
            b = items[i][2]
            if not b:
                continue
            if b[0] in (0x1D, 0x1B) and len(b) >= 4:
                dst = b[1] | b[2] << 8 | b[3] << 16
                kind = "call" if b[0] == 0x1D else "jp"
            elif b[0] in (0x1E, 0x1C) and len(b) >= 3:
                d = b[1] | b[2] << 8
                if d >= 0x8000:
                    d -= 0x10000
                dst = a + 3 + d
                kind = "calr" if b[0] == 0x1E else "jrl"
            else:
                continue
            if kind in ("call", "calr"):
                if i + 2 >= len(items) or items[i + 1][2] != [0x0E]:
                    continue
                end = items[i + 2][0]
            else:
                if i + 1 >= len(items):
                    continue
                end = items[i + 1][0]
            # THE EXTENT TEST: the routine must end where the next top-level
            # label begins, or on a `jp` (which cannot fall through).
            if kind in ("call", "calr") and not top(end):
                continue
            tn = top(dst)[0] if top(dst) else None
            rows.append((a, n, kind, dst, tn, grade(tn) if tn else "nolabel", end))
    return rows, [r for r in rows if r[5] == "content"]


WRAPPER_EXPECT = [0xF92710, 0xF92C50, 0xF93541, 0xF93823, 0xF9982D, 0xF99844,
                  0xF9985B, 0xF9985F, 0xFBC5C1, 0xFC0000, 0xFC043C, 0xFC8000,
                  0xFE1CC4, 0xFE300C]


# ---------------------------------------------------------------------------
# 10. THE EDIT.  Every rename below carries a header block ending in an
#     `Evidence:` line naming an ADDRESS and a MECHANISM.
# ---------------------------------------------------------------------------
RENAMES = [
    ("sub_F8A088", "PanelWireQueue_DrainToGroupQueue"),
    ("sub_F8A303", "PanelGroupQueue_AppendFlaggedGroups"),
    ("sub_F8A3B2", "PanelGroupQueue_Append"),
    ("sub_F8A824", "PanelGroupQueue_ExpandToEvents"),
    ("sub_F8A8A1", "PanelEvent_ShiftThenRunAction"),
    ("sub_F8A913", "LowestSetBitIndex1Based"),
    ("sub_F8A927", "IndexToBitMask8"),
]

HEADERS = {
"PanelWireQueue_DrainToGroupQueue": [
 "PanelWireQueue_DrainToGroupQueue -- drain the CP1 wire queue at RAM 0x2B40",
 "and re-post each change as a GROUP record on the queue at RAM 0x2000.",
 "",
 "Called from: 0xF8A07E (`calr`), inside the arm that Dispatch_F8A05F slot 0",
 "         and slot 2 reach.",
 "Produces: it is the FIRST of the eight producers that call",
 "         PanelGroupQueue_Append; the other seven are the six fixed-group",
 "         appenders in PanelGroupQueue_AppendFlaggedGroups and the run-time",
 "         one at 0xF8A2D6.",
 "Body:    XIZ = 0x2B40, a ring whose put/get cursors are at +0x04/+0x06 and",
 "         whose wrap limit is at +0x02.  Per THREE-byte record it reads",
 "         [wire][new value][old XOR new], computes the map index",
 "         (wire & 0x1F) | ((wire & 0xC0) >> 1), reads",
 "         PanelWireGroupMap_Variant1/2 for the GROUP, and -- only when the",
 "         change byte is non-zero -- calls PanelGroupQueue_Append.",
 "Refuses: `cp (0x219A),0x07` at 0xF8A090 stops the drain when the group",
 "         queue already holds seven records; the wire queue keeps its",
 "         unread bytes and the drain resumes next tick.",
 "Sibling: prom_b SC1_RxOp0_ThreeByte (0xF5B0D5) is what FILLS 0x2B40.",
 "⚠ prom_b's comments at :98479 and :156427, and two notes scripts, still",
 "         cite this routine as `prom_a sub_F8A088`; those files belong to",
 "         other lanes and were not edited.",
 "Evidence: `ld XIZ,0x00002B40` at 0xF8A088, `cp (0x219A),0x07` at 0xF8A090,",
 "         the index expression `and L,0x1F` / `and A,0xC0` / `srl A,1` /",
 "         `or L,A` at 0xF8A0A3-0xF8A0AC, `ld XIY,0x00F8A109` at 0xF8A0AE,",
 "         `calr` to 0xF8A3B2 at 0xF8A0F2, `ld (XIZ+0x06),IX` at 0xF8A103.",
],
"PanelGroupQueue_AppendFlaggedGroups": [
 "PanelGroupQueue_AppendFlaggedGroups -- raise a group event for each of six",
 "RAM FLAG BYTES whose bit 7 is set, then clear that bit.",
 "",
 "★★ THESE ARE SIX OF THE SEVEN NON-WIRE PRODUCERS round 10 located and did",
 "not read.  Each arm is the same five steps: test bit 7 of the flag byte,",
 "check the group queue has room, clear bit 7, and call",
 "PanelGroupQueue_Append with a FIXED group id in E, the flag byte ITSELF",
 "as the value (A), and 0x7F as the change mask (W).  The six pairs are",
 "  (0x28EE) -> group 0x10    (0x28F1) -> group 0x13",
 "  (0x28EF) -> group 0x11    (0x28EC) -> group 0x14",
 "  (0x28F0) -> group 0x12    (0x28ED) -> group 0x15",
 "and the variant-1 lists for groups 0x10-0x15 emit classes BA, BB, B4, BD,",
 "B8, B9 -- every one with CODE 0x00 and a 0x7F whole-field mask.  So the",
 "delivered event carries the flag byte's LOW SEVEN BITS as a value: six",
 "continuous-controller-shaped events, not buttons.",
 "★ SO SIX OF THE SEVEN CANNOT BE THE MISSING PRODUCER OF CODE 0x0E.",
 "  UiEvent_RouteByCode has an 0x0E arm that nothing found raises; the last",
 "  remaining non-wire suspect is 0xF8A2D6, which takes its group from",
 "  (0x219C) at RUN TIME and therefore cannot be enumerated statically.",
 "⚠ Groups 0x16, 0x17 and 0x18 have no producer this tree has found.",
 "Variant: `cp (0xC4),0x02` at 0xF8A303 skips the whole routine on one",
 "         model strap.",
 "Evidence: the six `ldb E,imm8` at 0xF8A31E/0xF8A33A/0xF8A356/0xF8A372/",
 "         0xF8A38E/0xF8A3AA, the six `and (flag),0x7F` at 0xF8A319/0xF8A335/",
 "         0xF8A351/0xF8A36D/0xF8A389/0xF8A3A5, the six `cp (0x219A),0x07`",
 "         guards, and the six `calr` to 0xF8A3B2 at 0xF8A322/0xF8A33E/",
 "         0xF8A35A/0xF8A376/0xF8A392/0xF8A3AE.",
],
"PanelGroupQueue_Append": [
 "PanelGroupQueue_Append -- append [group][value][change mask] to the group",
 "queue at RAM 0x2000 and bump the count at (0x219A).",
 "",
 "Called from: eight sites, all `calr` -- 0xF8A0F2 (the wire drain), 0xF8A2D6",
 "         (the run-time-group producer) and the six fixed-group arms of",
 "         PanelGroupQueue_AppendFlaggedGroups.",
 "Capacity: SEVEN records.  `cp (XIY),0x07` at 0xF8A3C4 refuses when the",
 "         count is already 7; the record offset is count*3 (`muls HL,3` at",
 "         0xF8A3CE), so the queue occupies 0x2000-0x2014 and the terminator",
 "         one byte past the last record.",
 "Body:    stores E, W and A in that order through XIX+HL, writes a 0xFF",
 "         terminator after them, and increments (0x219A).",
 "Read by: PanelGroupQueue_ExpandToEvents, which is the only consumer.",
 "⚠ It also has a variant gate (`cp (0x207A),0xDB` at 0xF8A3B2) and, on one",
 "         path, calls prom_b through the thunk 0xF434D4 before storing; what",
 "         that call does is not established here.",
 "Evidence: `ld XIY,0x0000219A` at 0xF8A3BA, `ld XIX,0x00002000` at 0xF8A3BF,",
 "         `cp (XIY),0x07` at 0xF8A3C4, `muls HL,0x0003` at 0xF8A3CE, the",
 "         three stores at 0xF8A42D/0xF8A434/0xF8A43B, the 0xFF terminator at",
 "         0xF8A442 and `inc (XIY)` at 0xF8A448.",
],
"PanelGroupQueue_ExpandToEvents": [
 "PanelGroupQueue_ExpandToEvents -- turn the group queue at RAM 0x2000 into",
 "UI events in the fixed list at RAM 0x2030.  ★★ THIS IS THE ROUTINE THAT",
 "READS THE LAYER-2 TABLES.",
 "",
 "Called from: sub_F8A81D (`calr` at 0xF8A81D), which prom_b's routine",
 "         directory publishes as slot 0xF40634.  No 24-bit reference to",
 "         0xF8A824 itself exists in either of CPU 1's ROMs.",
 "Body:    XIY = 0x2000, XIX = 0x2030.  Per queue record it reads the GROUP",
 "         byte, stops on 0xFF or 0xFE, REJECTS a group above 0x18, stores",
 "         the group to (0x2251) for the action-table lookup, and indexes",
 "         PanelGroupEventLists_Variant1/2 with group*4.  It then walks that",
 "         list: [class] and [code] are copied straight into the event,",
 "         [mask] selects which bits of the wire byte the record owns, and",
 "         [shift] normalises those bits down to positions 0-1.  A record",
 "         whose masked CHANGE is zero is discarded (`dec 2,XIX`).",
 "Bounds:  `cp XIX,0x0000206C` at 0xF8A86D is the 15-record capacity of the",
 "         0x2030 list -- the same ceiling List2030_AppendRegs enforces.  On",
 "         exit it writes 0xFF to (XIX), 0xFF to (0x2000) and 0 to (0x219A),",
 "         emptying the group queue.",
 "Variant: `cp (0xC4),0x01` at 0xF8A851 picks variant 1 or 2; (0xC4) is the",
 "         MODEL STRAP that prom_a 0xF82882 loads from PB bit 0.",
 "⚠ A NEVER-RELOCATED COPY of this routine's list walker sits 0x400 lower at",
 "         PanelGroupQueue_ExpandToEvents_DeadCopy (0xF8A44B).",
 "Evidence: `ld XIY,0x00002000` at 0xF8A824, `ld XIX,0x00002030` at 0xF8A829,",
 "         `cp A,0x18` at 0xF8A83B, `ld (0x2251),A` at 0xF8A840,",
 "         `ld XIX,0x00F8B446` at 0xF8A84C, `ld XIX,0x00F8B4B2` at 0xF8A857,",
 "         `cp (XHL),0xff` at 0xF8A862, `cp XIX,0x0000206C` at 0xF8A86D,",
 "         `ld (XIX+),DE` at 0xF8A90B.",
],
"PanelEvent_ShiftThenRunAction": [
 "PanelEvent_ShiftThenRunAction -- normalise one event-list record's two bits,",
 "then give the per-group ACTION list a chance to intercept before the value",
 "pair is committed.",
 "",
 "Called from: PanelGroupQueue_ExpandToEvents, `calr` at 0xF8A87F, once per",
 "         surviving list record.",
 "Body, in order:",
 "  1. read the record's SHIFT byte; a zero shift skips to the action lookup;",
 "  2. `bit 4` picks direction and `and A,0x07` the count, then D (the masked",
 "     change) and E (the masked value) are shifted together;",
 "  3. if D is now zero the event is DROPPED -- `dec 2,XIX` at 0xF8A8C3 backs",
 "     the event pointer up over the class/code pair already written;",
 "  4. otherwise index PanelGroupActionTable_Variant1/2 by (0x2251), walk its",
 "     6-byte records for a matching (mask, group) pair, and `jp (XBC)` to the",
 "     handler if one matches;",
 "  5. with no match, fall through to 0xF8A90B, which commits `ld (XIX+),DE`.",
 "★ A HANDLER MAY REWRITE THE CODE the walker already stored -- `add",
 "  (XIX-1),0x11` at 0xF8AE7E/0xF8AEF1 and `ld (XIX-1),0x19` at",
 "  0xF8AE8A/0xF8AEFD -- or drop the event by ending at 0xF8A90F.",
 "⚠ WHICH BRANCH RUNS is a run-time property; nothing here establishes it.",
 "Evidence: `ld A,(XHL-1)` at 0xF8A8A1, `bit 0x04,A` at 0xF8A8AA, `and A,0x07`",
 "         at 0xF8A8AF and 0xF8A8B8, `dec 2,XIX` at 0xF8A8C3,",
 "         `ld L,(0x2251)` at 0xF8A8DC, `ld XIY,0x00F8B74A` at 0xF8A8CC,",
 "         `cp C,0xff` at 0xF8A8F1, `cp WA,BC` at 0xF8A8F6, `jp (XBC)` at",
 "         0xF8A909.",
],
"LowestSetBitIndex1Based": [
 "LowestSetBitIndex1Based -- E := 1-based position of E's lowest set bit.",
 "",
 "E = 0 returns 0 unchanged (`cps E,0x00` / `jr z` at 0xF8A913).  Otherwise C is",
 "counted up from 0 while E is shifted right until the carry comes out set,",
 "so bit 0 gives 1 and bit 7 gives 8; C is copied back into E.  C is saved",
 "and restored, so the only register the caller sees changed is E.",
 "★ IT IS THE INVERSE OF IndexToBitMask8, 20 bytes above it.",
 "Evidence: `cps E,0x00` at 0xF8A913, `inc 1,C` at 0xF8A91B, `srl E,1` at",
 "         0xF8A91D, `jr nc,-7` at 0xF8A920, `ld E,C` at 0xF8A922.",
],
"IndexToBitMask8": [
 "IndexToBitMask8 -- E (0..8) -> E = one-hot 8-bit mask, by table lookup.",
 "",
 "`cp E,0x08` / `jr ule` at 0xF8A928 lets 0..8 through and forces anything",
 "larger to 0, which selects entry 0 -- the ZERO mask, not the top entry.",
 "The table is BitMask8ByIndex immediately below.",
 "★ It is the inverse of LowestSetBitIndex1Based, and the two sit 20 bytes",
 "  apart, which is what makes the pairing more than a coincidence of shape.",
 "Evidence: `cp E,0x08` at 0xF8A928, `xor E,E` at 0xF8A92D,",
 "         `ld XIX,0x00F8A93B` at 0xF8A92F, `ld E,(XIX+E)` at 0xF8A934 --",
 "         the result lands in E, the same register the index arrived in.",
],
}

DEAD_HEADER = [
 "PanelGroupQueue_ExpandToEvents_DeadCopy -- 0xF8A44B-0xF8A4C5, 123 bytes: a",
 "NEVER-RELOCATED, UNREACHABLE second copy of the live list walker at",
 "0xF8A84B, exactly 0x400 bytes lower.",
 "",
 "★★ THIS IS DEAD CODE, and three independent measurements say so.",
 "  1. ITS TABLE POINTERS POINT AT NOTHING.  The two copies differ in exactly",
 "     9 of their first 123 bytes, and all 9 are inside three `imm32` operands",
 "     or the selector between them.  The live copy's immediates are",
 "     0xF8B446 / 0xF8B4B2 / 0xF8B74A, whose first four words are 4-of-4",
 "     in-image pointers.  This copy's are 0xF8ADDD / 0xF8AD71 / 0xF8AF9F,",
 "     whose first four words are 0-of-4 in-image pointers -- they land in the",
 "     middle of the action HANDLERS, not in a table.",
 "  2. ITS BACK EDGE LANDS MID-INSTRUCTION.  The `68 A6` at 0xF8A486 resolves",
 "     to 0xF8A42E, the SECOND byte of the 5-byte instruction at 0xF8A42D; no",
 "     linear decode starting anywhere in 0xF8A100-0xF8A42D puts a boundary",
 "     there (814 starts tried).  The live copy's identical `68 A6` at",
 "     0xF8A886 resolves to 0xF8A82E, which IS its loop head.",
 "  3. NOTHING NAMES IT.  A scan of both of CPU 1's ROMs for the 24-bit value",
 "     0xF8A44B returns ZERO hits; the live entry 0xF8A81D is named by",
 "     prom_b's routine directory at 0xF40635.",
 "",
 "★ THE TWO RUNS EVEN CARRY LABELS AT THE SAME OFFSETS: sub_F8A49D and",
 "  sub_F8A4A1 sit at +0x52 and +0x56, exactly where the live run carries",
 "  sub_F8A89D and PanelEvent_ShiftThenRunAction.  They are their dead twins.",
 "  ⚠ The twinning stops at +0x7B: 0xF8A4C6 onward is NOT a copy of 0xF8A8C6",
 "  onward, so sub_F8A4A1 shares only its first 37 bytes with the live one and",
 "  is NOT renamed here.",
 "",
 "The likely history is a relocated build in which this copy's operands were",
 "never re-pointed; nothing here proves that, and it is offered as a guess,",
 "not as a finding.",
 "Evidence: the nine differing bytes are at 0xF8A44D, 0xF8A44E, 0xF8A451-",
 "         0xF8A455, 0xF8A458 and 0xF8A459; the in-image-pointer counts and",
 "         the reference scan are reproduced by",
 "         notes/prom_a_panel_names_round11.py --stale.",
]

WGM_OLD = "; ⚠ What a GROUP id then selects is NOT established here."
WGM_NEW = [
 "; ★ WHAT A GROUP ID SELECTS -- established in round 10, applied in round 11:",
 ";   it indexes PanelGroupEventLists_Variant1 (0xF8B446) or _Variant2",
 ";   (0xF8B4B2), whose list says which UI event class and code that wire",
 ";   raises.  PanelGroupQueue_ExpandToEvents does the indexing at 0xF8A846.",
 "; ⚠ AND THE TWO NUMBERINGS DISAGREE FOR THE DIAL.  The physical map in",
 ";   notes/wave7_panel_button_codes.py puts the -1/+1 pair at matrix SEGMENT",
 ";   3; the event table puts its code (0x0D) at GROUP 0x0A, and group ==",
 ";   segment for wires 0xC0-0xCA.  One of the two is wrong; neither has been",
 ";   edited to hide it.",
]


def _find(lines, pred, what):
    hits = [i for i, l in enumerate(lines) if pred(l)]
    assert len(hits) == 1, "%s: %d matches, wanted 1" % (what, len(hits))
    return hits[0]


def _block(header_lines):
    return ["; " + "-" * 69] + ["; " + l if l else ";" for l in header_lines] \
        + ["; " + "-" * 69, ""]


def apply():
    lines = open(A_SRC).read().split("\n")

    # --- the 14 pure wrappers, computed BEFORE any rename ------------------
    _, nameable = wrappers()
    got = sorted(r[0] for r in nameable)
    assert got == WRAPPER_EXPECT, "the wrapper set moved: %s" % ["%06X" % a for a in got]
    nameable = [r for r in nameable if _UNNAMED.match(r[1])]

    # --- 1. the PanelTables block -----------------------------------------
    lab = _find(lines, lambda l: l == "PanelTables_F8B325:", "PanelTables label")
    # ⚠ walk back over the WHOLE comment block, not to the first `; ---` above
    # the label -- that one is the block's CLOSING rule, and stopping there
    # leaves the entire stale header in the file (it did, once).
    top = lab
    while top and (lines[top - 1].startswith(";") or lines[top - 1].strip() == ""):
        top -= 1
    end = lab
    while end + 1 < len(lines) and lines[end + 1].startswith("\t.byte"):
        end += 1
    assert lines[end].rstrip().endswith("; F8BBA5"), lines[end][-40:]
    lines[top:end + 1] = emit_block()

    # --- 2. the bit-mask siblings -----------------------------------------
    lo = _find(lines, lambda l: l.rstrip().endswith("; F8A93B  00"), "0xF8A93B")
    hi = _find(lines, lambda l: l.rstrip().endswith("; F8AA13  40 00 00 00 80"), "0xF8AA13")
    lines[lo:hi + 1] = emit_bitmask_block()

    # --- 4. the dead copy --------------------------------------------------
    i = _find(lines, lambda l: l.rstrip().endswith("; F8A44B  3c"), "0xF8A44B")
    lines[i:i] = _block(DEAD_HEADER) + ["PanelGroupQueue_ExpandToEvents_DeadCopy:"]

    # --- 5. the seven renames.  References first (CODE LINES ONLY, so the
    #        header prose that deliberately quotes an OLD name survives), then
    #        the header blocks above the already-renamed definitions.
    for i, l in enumerate(lines):
        if l.lstrip().startswith(";"):
            continue
        for old, nw in RENAMES:
            if re.search(r'\b%s\b' % old, lines[i]):
                lines[i] = re.sub(r'\b%s\b' % old, nw, lines[i])
    for old, nw in RENAMES:
        i = _find(lines, lambda l, o=nw: l == o + ":", nw)
        lines[i:i] = _block(HEADERS[nw])

    # --- 6. the PanelWireGroupMap correction -------------------------------
    hits = [i for i, l in enumerate(lines) if l == WGM_OLD]
    assert len(hits) == 2, "PanelWireGroupMap warning: %d, wanted 2" % len(hits)
    for i in reversed(hits):                 # both variants carried it
        lines[i:i + 1] = WGM_NEW

    # --- 7. the fourteen wrappers -----------------------------------------
    for a, n, kind, dst, tn, _g, end in nameable:
        i = _find(lines, lambda l, o=n: l == o + ":", n)
        nw = tn + "_Entry"
        if kind in ("call", "calr"):
            shape = ["one `%s` and the `ret` that follows it, and the routine" % kind,
                     "ends at 0x%06X, where the next top-level label begins." % end]
        else:
            shape = ["a single unconditional `%s`, which cannot fall through," % kind,
                     "so the routine is that one instruction."]
        lines[i] = nw + ":"
        lines[i:i] = _block([
            "%s -- a PURE WRAPPER for %s: it IS that" % (nw, tn),
            "routine, so it is named for it.  Its whole extent is",
        ] + shape + [
            "Evidence: the `%s` at 0x%06X targets 0x%06X, which carries the"
            % (kind, a, dst),
            "         label %s.  The extent is measured to the next top-level" % tn,
            "         label, never to a source line -- notes/wave7-verify-probes/",
            "         wave7_r5_prom_a_painter_scope.py records what scoping to a",
            "         source line cost the round-5 pass.",
        ])

    open(A_SRC, "w").write("\n".join(lines))
    print("applied: 1 block split into 9 objects, 3 mis-decoded tables reframed,")
    print("         %d routines renamed, %d wrappers renamed, 1 dead copy labelled,"
          % (len(RENAMES) + 2, len(nameable)))
    print("         1 stale warning replaced by the answer.")
    print("NOW RUN: python3 scripts/analysis/assert_byte_identical.py")


EXPECT_LABELS = [
    "Var2250_AcceptList", "RecordPtrs_RAM76A2_Panel",
    "RecordFieldPtrs_RAM76A2_Plus20", "PanelGroupEventLists_Variant1",
    "PanelGroupEventLists_Variant2", "PanelGroupEventListPool",
    "PanelGroupActionTable_Variant1", "PanelGroupActionTable_Variant2",
    "PanelGroupActionListPool", "PanelGroupQueue_ExpandToEvents",
    "PanelGroupQueue_ExpandToEvents_DeadCopy", "PanelWireQueue_DrainToGroupQueue",
    "PanelGroupQueue_Append", "PanelGroupQueue_AppendFlaggedGroups",
    "PanelEvent_ShiftThenRunAction", "LowestSetBitIndex1Based",
    "IndexToBitMask8", "IndexToBitMask16", "IndexToBitMask32",
    "BitMask8ByIndex", "BitMask16ByIndex", "BitMask32ByIndex",
]


def verify():
    src = open(A_SRC).read()
    ok = True
    for n in EXPECT_LABELS:
        if ("\n%s:" % n) not in src:
            print("MISSING  %s" % n)
            ok = False
    # A mention inside a COMMENT is deliberate -- two headers quote an old name
    # on purpose (prom_b still cites `sub_F8A088`; the block records what it was
    # called before round 11).  Only a CODE line may not carry one.
    code = [l for l in src.split("\n") if not l.lstrip().startswith(";")]
    for old, _new in RENAMES + [("PanelTables_F8B325", "")]:
        bad = [l for l in code if re.search(r'\b%s\b' % old, l)]
        if bad:
            print("STALE    %s still appears on a code line: %r" % (old, bad[0][:60]))
            ok = False
    if WGM_OLD in src:
        print("STALE    the PanelWireGroupMap warning was not replaced")
        ok = False
    if src.count("★ WHAT A GROUP ID SELECTS") != 2:
        print("MISSING  the replacement is not on both variant headers")
        ok = False
    for a in WRAPPER_EXPECT:
        if ("\nsub_%06X:" % a) in src:
            print("MISSING  wrapper rename at %06X" % a)
            ok = False
    print("verify: %s (%d labels checked)" % ("OK" if ok else "FAILED", len(EXPECT_LABELS)))
    return ok


# ---------------------------------------------------------------------------
# 11. REPORT MODES
# ---------------------------------------------------------------------------
def mode_tables():
    ev_lo, ev_hi, ac_lo, ac_hi = pool_extents()
    t1, t2, deltas, odd = ptr_facts()
    print("THE NINE OBJECTS OF 0x%06X-0x%06X (%d bytes)"
          % (BLOCK_LO, BLOCK_HI - 1, BLOCK_HI - BLOCK_LO))
    rows = [
        (ACCEPT, PTRS_BASE, "Var2250_AcceptList", "load 0xF8B2EE / 0xF8B30F"),
        (PTRS_BASE, PTRS_P20, "RecordPtrs_RAM76A2_Panel", "ABUTMENT -- no reader found"),
        (PTRS_P20, EV1, "RecordFieldPtrs_RAM76A2_Plus20", "load 0xF8AA31"),
        (EV1, EV2, "PanelGroupEventLists_Variant1", "load 0xF8A84C"),
        (EV2, EVPOOL, "PanelGroupEventLists_Variant2", "load 0xF8A857"),
        (EVPOOL, AC1, "PanelGroupEventListPool", "ABUTMENT -- walked, tiles exactly"),
        (AC1, AC2, "PanelGroupActionTable_Variant1", "load 0xF8A8CC"),
        (AC2, ACPOOL, "PanelGroupActionTable_Variant2", "load 0xF8A8D7"),
        (ACPOOL, BLOCK_HI, "PanelGroupActionListPool", "ABUTMENT -- walked, tiles exactly"),
    ]
    tot = 0
    for lo, hi, name, why in rows:
        print("  %06X-%06X  %5d  %-32s %s" % (lo, hi - 1, hi - lo, name, why))
        tot += hi - lo
    print("  %d bytes, %d of %d accounted for" % (tot, tot, BLOCK_HI - BLOCK_LO))
    print("  pools walked: event %06X-%06X, action %06X-%06X"
          % (ev_lo, ev_hi - 1, ac_lo, ac_hi - 1))
    print("  record-pointer steps: %d x 0x40 and %d x 0x80 (at index %s)"
          % (deltas.count(0x40), deltas.count(0x80), odd))


def mode_producers():
    print("THE EIGHT PRODUCERS THAT APPEND TO THE GROUP QUEUE AT 0x2000")
    print("  0x%06X  the wire drain (group comes from the wire map)" % WIRE_DRAIN_CALL)
    call, ldsite, cell = RUNTIME_PRODUCER
    print("  0x%06X  group from RAM (0x%04X) at RUN TIME -- `ld E,(0x%04X)` at 0x%06X"
          % (call, cell, cell, ldsite))
    print("           ⚠ NOT STATICALLY ENUMERABLE.  This is the only remaining")
    print("             non-wire suspect for the missing event code 0x0E.")
    for callsite, cellad, group, a, b, c in producer_facts():
        codes = group_codes(group)
        print("  0x%06X  flag (0x%04X) bit 7 -> group 0x%02X -> %s   [%s]"
              % (callsite, cellad, group,
                 ", ".join("class %02X code %02X" % ck for ck in codes) or "(no list)",
                 "checks pass" if (a and b and c) else "CHECK FAILED"))
    allcodes = set()
    for _, _, g, _, _, _ in producer_facts():
        allcodes |= {k for _, k in group_codes(g)}
    print("  codes these six can raise: %s -- 0x0E is %sin that set"
          % (sorted("%02X" % c for c in allcodes), "" if 0x0E in allcodes else "NOT "))


def mode_ptrtables():
    t1, t2, deltas, odd = ptr_facts()
    print("RecordPtrs_RAM76A2_Panel (0x%06X) and _Plus20 (0x%06X), %d entries each"
          % (PTRS_BASE, PTRS_P20, len(t1)))
    for i, (x, y) in enumerate(zip(t1, t2)):
        d = "" if i == 0 else "  step 0x%02X%s" % (t1[i] - t1[i - 1],
                                                   "  <== NOT 0x40" if i - 1 in odd else "")
        print("  [%2d] 0x%04X   +0x20 -> 0x%04X%s" % (i, x, y, d))
    print("  differences _Plus20 - _Panel: %s" % sorted(set(b - a for a, b in zip(t1, t2))))
    print("  ⚠ the old header said 'step 0x40'; %d steps are 0x40 and %d is 0x80"
          % (deltas.count(0x40), deltas.count(0x80)))


def mode_collisions():
    print("BYTE-IDENTICAL EVENT LISTS -- do not name a routine from these codes")
    for tag, g1, g2, n in collisions():
        print("  %s: groups 0x%02X and 0x%02X emit identical %d-record lists"
              % (tag, g1, g2, n))
    print("  ⚠ round 10's docstring named 0x03/0x04 and 0x05/0x06; 0x01/0x02 is")
    print("    a third pair it did not list.")


def mode_stale():
    diff, inptr, refs = stale_facts()
    print("THE DEAD WALKER COPY AT 0x%06X (live: 0x%06X)" % (STALE, LIVE))
    print("  %d of the first 0x7B bytes differ, at %s"
          % (len(diff), " ".join("%06X" % (STALE + i) for i in diff)))
    for t in STALE_TABLES:
        print("  stale table 0x%06X: %d of 4 first words are in-image pointers" % (t, inptr[t]))
    for t in LIVE_TABLES:
        print("  live  table 0x%06X: %d of 4 first words are in-image pointers" % (t, inptr[t]))
    print("  24-bit references to 0x%06X anywhere in prom_a+prom_b: %s"
          % (STALE, refs if refs else "NONE"))
    print("  24-bit references to 0x%06X (the live entry): %s"
          % (0xF8A81D, ["%s:%06X" % r for r in ref_scan(0xF8A81D)]))


def mode_wrappers():
    rows, nameable = wrappers()
    kinds = {}
    for r in rows:
        kinds[r[5]] = kinds.get(r[5], 0) + 1
    call = sum(1 for r in rows if r[2] in ("call", "calr"))
    print("PURE WRAPPERS IN prom_a -- the one shape a popular callee may name")
    print("  %d wrappers: %d `call/calr`+`ret`, %d bare `jp/jrl`"
          % (len(rows), call, len(rows) - call))
    for k in ("sub", "nolabel", "framed", "content"):
        print("    %-8s %4d" % (k, kinds.get(k, 0)))
    labels, _ = parse_src()
    nsub = sum(1 for ns in labels.values() for n in ns if _UNNAMED.match(n))
    print("  ★ THE YIELD IS %d, AGAINST %d sub_XXXXXX STILL IN prom_a (%.1f%%)."
          % (len(nameable), nsub, 100.0 * len(nameable) / max(nsub, 1)))
    print("    The mechanism is sound and nearly empty; that is the finding.")
    for a, n, kind, dst, tn, _g, end in nameable:
        print("    %06X %-14s %-5s -> %06X %s" % (a, n, kind, dst, tn))


def mode_census():
    print("JOB 2, ANSWERED BY POINTING AT WHAT IS ALREADY COMMITTED")
    print()
    print("  The per-routine census of prom_a's sub_XXXXXX -- call-site count,")
    print("  caller shape, what the body touches, leaf, length, flow end,")
    print("  buckets, and the size of the LAST bucket -- EXISTS:")
    print("      notes/prom_a_census_round8.py --census   (buckets)")
    print("      notes/prom_a_census_round8.py --dump     (all six columns, per routine)")
    print("      notes/prom_a_census_round8.py --nothing  (the terminal bucket)")
    print("  Re-run live at this round's start it printed:")
    print("      S1 277  S2 47  S3 119  S4 15 | T1 1  T2 6  T3 118  T4 67  T5 63")
    print("      C1 30 | N 1932 of 2822 = 68.5%  no distinguishing evidence")
    print("  and re-run AFTER this round's 36 names it printed")
    print("      N 1921 of 2800 = 68.6%  -- the COUNT fell by 11, the RATIO did")
    print("      not move, which is round 8's own warning about that number;")
    print("      C1 rose 30 -> 38 because naming a routine gives its callers a")
    print("      content-named caller they did not have.")
    print("  ⚠ Writing a second census would have produced a number whose only")
    print("    check is itself.  This round did not write one.")
    print()
    mode_wrappers()
    print()
    print("  ⚠ AND A SHAPE THIS ROUND DECLINED TO APPLY.  Round 8's S1/S3/S4")
    print("    buckets (277 one-byte `ret` stubs, 119 forwarders, 15 tail jumps)")
    print("    are mechanically nameable, but the only name their shape supports")
    print("    is a KIND plus an ADDRESS -- RetStub_F8xxxx.  411 such labels")
    print("    would grade FRAMED, not CONTENT, in")
    print("    notes/wave7_documentation_metrics.py, moving prom_a's UPPER bound")
    print("    up while its LOWER bound stands still.  That is the exact trade")
    print("    the 0xFAD800 span made and the briefing warns against.")


# ---------------------------------------------------------------------------
# 12. SELFTEST.  Every quantified claim this file or its edits make, checked --
#     and, where a claim is about a sequence, checked ON THE LAST ELEMENT.
# ---------------------------------------------------------------------------
OK = FAIL = 0


def ck(msg, cond):
    global OK, FAIL
    if cond:
        OK += 1
        print("  PASS  %s" % msg)
    else:
        FAIL += 1
        print("  FAIL  %s" % msg)


def selftest():
    # A. the framing loads
    ck("A1 all seven framing loads decode as stated", not check_loads())
    ck("A2 the LAST framing load is `ld XIY,0x00F8B7AE` at 0xF8A8D7",
       LOADS[-1][0] == 0xF8A8D7 and blk(0xF8A8D7, 5) == bytes([0x45, 0xAE, 0xB7, 0xF8, 0x00]))

    # B. the tiling
    ev_lo, ev_hi, ac_lo, ac_hi = pool_extents()
    ck("B1 event pool walks to exactly 0xF8B51E-0xF8B749",
       (ev_lo, ev_hi) == (EVPOOL, AC1))
    ck("B2 action pool walks to exactly 0xF8B812-0xF8BBB3",
       (ac_lo, ac_hi) == (ACPOOL, BLOCK_HI))
    ck("B3 the nine objects tile the block with nothing left over",
       (PTRS_BASE - ACCEPT) + (PTRS_P20 - PTRS_BASE) + (EV1 - PTRS_P20)
       + (EV2 - EV1) + (EVPOOL - EV2) + (AC1 - EVPOOL) + (AC2 - AC1)
       + (ACPOOL - AC2) + (BLOCK_HI - ACPOOL) == BLOCK_HI - BLOCK_LO == 2191)
    ck("B4 the byte AFTER the block is the 0x0E module pad", by(BLOCK_HI) == 0x0E)
    ck("B5 the LAST byte of the block is the action pool's terminator",
       by(BLOCK_HI - 1) == 0xFF)

    # C. the event lists
    e1, e2 = ev_lists(EV1), ev_lists(EV2)
    ck("C1 27 slots each, from the abutment", len(e1) == len(e2) == EV_SLOTS == 27)
    ck("C2 slot 0x00 of variant 1 is the 6-record list at 0xF8B51E",
       e1[0][1] == EVPOOL and len(e1[0][3]) == 6)
    ck("C3 THE LAST slot of variant 1 (0x1A) is unreachable and empty",
       e1[-1][0] == 0x1A and not e1[-1][3] and e1[-1][0] > GROUP_MAX)
    ck("C4 THE LAST slot of variant 2 (0x1A) likewise",
       e2[-1][0] == 0x1A and not e2[-1][3])
    ck("C5 the reader's bound really is `cp A,0x18` / `jr ugt` at 0xF8A83B",
       blk(0xF8A83B, 5) == bytes([0xC9, 0xCF, 0x18, 0x6B, 0x44]))
    _st = sorted({p for _, p, _, _ in e1 + e2})
    _gaps = [b - a for a, b in zip(_st, _st[1:])]
    ck("C6 every event record is 4 bytes: EXACTLY 39 inter-list gaps and every "
       "one of them is 1 mod 4 (40 distinct list heads)",
       len(_st) == 40 and len(_gaps) == 39 and all(g % 4 == 1 for g in _gaps))
    ck("C7 THE LAST record of the LAST non-empty variant-2 list decodes",
       [r for _, _, _, r in e2 if r][-1][-1][1] == (0xB9, 0x00, 0x00, 0x7F))

    # D. the action tables
    a1, a2 = ac_lists(AC1), ac_lists(AC2)
    ck("D1 25 slots each, and here the abutment AGREES with the reader",
       len(a1) == len(a2) == AC_SLOTS == GROUP_MAX + 1 == 25)
    ck("D2 THE LAST slot of variant 1 (0x18) is empty",
       a1[-1][0] == 0x18 and not a1[-1][3])
    ck("D3 THE LAST non-empty variant-2 action record is group 0x15 mask 0x7F "
       "-> 0xF8AFD0",
       [r for _, _, _, r in a2 if r][-1][-1][1:] == (0x15, 0x7F, 0xF8AFD0))
    ck("D4 the two code-rewriting handlers really rewrite (XIX-1): "
       "`add (XIX-1),0x11` and `ld (XIX-1),0x19`, each in two copies",
       blk(0xF8AE7E, 4) == blk(0xF8AEF1, 4) == bytes([0x8C, 0xFF, 0x38, 0x11])
       and blk(0xF8AE8A, 4) == blk(0xF8AEFD, 4) == bytes([0xBC, 0xFF, 0x00, 0x19]))

    # E. the collisions
    col = collisions()
    ck("E1 three byte-identical variant-1 list pairs, not two",
       len(col) == 3 and [(c[1], c[2]) for c in col] == [(1, 2), (3, 4), (5, 6)])
    ck("E2 THE LAST of them is groups 0x05/0x06, 8 records", col[-1][3] == 8)

    # F. the producers
    pf = producer_facts()
    ck("F1 all six fixed-group producers check out",
       all(a and b and c for _, _, _, a, b, c in pf))
    ck("F2 THE LAST producer is (0x28ED) -> group 0x15, calling 0xF8A3B2 at 0xF8A3AE",
       pf[-1][:3] == (0xF8A3AE, 0x28ED, 0x15) and calr_target(0xF8A3AE) == APPENDER)
    ck("F3 the six groups' lists emit code 0x00 only, so none can raise 0x0E",
       {k for _, _, g, _, _, _ in pf for _, k in group_codes(g)} == {0x00})
    ck("F4 the seventh producer's group is a RAM load, `ld E,(0x219C)` at 0xF8A2D2",
       blk(0xF8A2D2, 4) == bytes([0xC1, 0x9C, 0x21, 0x25])
       and calr_target(0xF8A2D6) == APPENDER)
    ck("F5 the wire drain is the eighth, `calr` to 0xF8A3B2 at 0xF8A0F2",
       calr_target(WIRE_DRAIN_CALL) == APPENDER)
    ck("F6 the appender's capacity really is 7 records of 3 bytes",
       blk(0xF8A3C4, 3) == bytes([0x85, 0x3F, 0x07])
       and blk(0xF8A3CE, 4) == bytes([0xDB, 0x09, 0x03, 0x00]))

    # G. the record-pointer tables
    t1, t2, deltas, odd = ptr_facts()
    ck("G1 32 entries each and the +0x20 relation holds for ALL of them",
       len(t1) == len(t2) == 32 and set(b - a for a, b in zip(t1, t2)) == {0x20})
    ck("G2 the step is 0x40 thirty times and 0x80 ONCE, at index 7 -- the old "
       "header's 'step 0x40' was wrong",
       deltas.count(0x40) == 30 and deltas.count(0x80) == 1 and odd == [7])
    ck("G3 THE LAST entry is 0x7EA2 / 0x7EC2", (t1[-1], t2[-1]) == (0x7EA2, 0x7EC2))
    ck("G4 0xF8B346 has NO reader: no ld/call/jp/ptr32 names it",
       not [h for h in ref_scan(PTRS_BASE)
            if by(h[1] - 1) in (0x43, 0x44, 0x45, 0x46) or by(h[1] - 1) in (0x1B, 0x1D)])
    ck("G6 the first 32 entries of RecordPtrs_RAM76A2 (0xFEB330) are IDENTICAL "
       "to these 32 -- the 'third copy' claim, checked not asserted",
       [le32(0xFEB330 + 4 * i) for i in range(32)] == t1)
    ck("G7 0xFF4251's 16 entries are these bases + 13, ALL SIXTEEN including "
       "the last",
       [le32(0xFF4251 + 4 * i) - t1[i] for i in range(16)] == [13] * 16)
    ck("G5 0xF8B3C6 IS loaded, at 0xF8AA31, and indexed by (0x2250)",
       blk(0xF8AA31, 5) == bytes([0x44, 0xC6, 0xB3, 0xF8, 0x00])
       and blk(0xF8AA36, 4) == bytes([0xC1, 0x50, 0x22, 0x21]))

    # H. the accept list
    n = PTRS_BASE - ACCEPT
    ck("H1 the accept list is 0x00..0x1F then 0xFF, %d bytes" % n,
       list(blk(ACCEPT, n)) == list(range(0x20)) + [0xFF])
    ck("H2 its LAST byte is the 0xFF the scan stops on", by(PTRS_BASE - 1) == 0xFF)
    ck("H3 its accepted range is exactly the index range of the 32-entry table",
       (n - 1) == len(t1))

    # I. the dead copy
    diff, inptr, refs = stale_facts()
    ck("I1 exactly 9 of the first 123 bytes differ", len(diff) == 9)
    ck("I2 all nine are inside the three immediates or the selector",
       diff == [2, 3, 6, 7, 8, 9, 10, 13, 14])
    ck("I3 the stale tables hold 0 of 4 in-image pointers, the live ones 4 of 4",
       all(inptr[t] == 0 for t in STALE_TABLES) and all(inptr[t] == 4 for t in LIVE_TABLES))
    ck("I4 nothing anywhere in prom_a+prom_b spells 0xF8A44B", not refs)
    ck("I5 prom_b DOES spell the live entry 0xF8A81D",
       any(nm == "prom_b" for nm, _ in ref_scan(0xF8A81D)))
    ck("I6 the twinning stops at +0x7B, so sub_F8A4A1 is NOT renamed",
       by(STALE + 0x7B) != by(LIVE + 0x7B))
    ck("I7 the two runs carry labels at the SAME offsets (+0x52, +0x56)",
       (STALE + 0x52, STALE + 0x56) == (0xF8A49D, 0xF8A4A1)
       and (LIVE + 0x52, LIVE + 0x56) == (0xF8A89D, 0xF8A8A1))

    # J. the bit-mask siblings
    bm = bitmask_facts()
    ck("J1 all three tables are 0 then 1<<(i-1) and all three clamps agree",
       all(r[5] and r[6] and r[7] and r[8] for r in bm))
    ck("J2 THE LAST table's LAST entry is 0x80000000 at 0xF8AA14",
       bm[-1][9] == 0x80000000 and le32(0xF8AA14) == 0x80000000)
    ck("J3 the byte after the LAST table is code again (`cps E,0x00` at 0xF8AA18)",
       blk(0xF8AA18, 2) == bytes([0xCD, 0xD8]))
    ck("J4 the two hidden entries really begin with `push XIX`",
       by(0xF8A944) == 0x3C and by(0xF8A97D) == 0x3C)
    ck("J5 LowestSetBitIndex1Based is the inverse: `srl E,1` + `jr nc,-7`",
       blk(0xF8A91D, 5) == bytes([0xCD, 0xEF, 0x01, 0x6F, 0xF9]))

    # K. the wrappers
    rows, nameable = wrappers()
    ck("K1 the wrapper set is the 14 recorded ones",
       sorted(r[0] for r in nameable) == WRAPPER_EXPECT)
    ck("K2 THE LAST of them is 0xFE300C -> Fdc_ServiceDataByte_Isr, a bare `jp`",
       nameable[-1][0] == 0xFE300C and nameable[-1][2] == "jp"
       and nameable[-1][4] == "Fdc_ServiceDataByte_Isr")
    ck("K3 every one of the 14 targets a CONTENT-graded label",
       all(grade(r[4]) == "content" for r in nameable))
    ck("K4 the yield really is 14 of %d wrappers, the rest reaching sub_ or nothing"
       % len(rows), len(nameable) == 14 and len(rows) == 120)
    ck("K5 the citation is the INSTRUCTION address, not one byte past it: every "
       "wrapper's first byte is a call/jp opcode",
       all(by(r[0]) in (0x1B, 0x1C, 0x1D, 0x1E) for r in rows))

    # L. the edit is byte-neutral by construction
    ck("L1 the emitted block re-derives and asserts its own tiling",
       len(emit_block()) > 700)
    ck("L2 the bit-mask emitter's code halves are certified by prom_a/roundtrip.py",
       len(emit_bitmask_block()) > 50)
    ck("L3 the emitter still re-derives the EXACT text now in the .s -- if any "
       "boundary moved, this fails before the gate ever sees it",
       "\n".join(emit_block()) in open(A_SRC).read())

    # M. every address this round writes into the .s is a real boundary
    cits, bad = citation_check()
    ck("M1 all %d six-digit prom_a citations in this round's prose are LINE "
       "STARTS in the gate-verified source (%d listed exceptions, each with a "
       "reason)" % (len(cits), len(NOT_A_BOUNDARY)),
       not bad)
    for a, t in sorted(bad.items())[:6]:
        print("        %06X  %s" % (a, t))
    ck("M2 the check can actually fail: 0xF8A84D (one byte into the `ld "
       "XIX,0x00F8B446` at 0xF8A84C) is NOT a line start",
       0xF8A84D not in {x for x, _, _ in parse_src()[1]})
    ck("M3 more than 100 citations were checked, so M1 is not vacuous",
       len(cits) > 100)

    print("\n%d checks, %d failures" % (OK + FAIL, FAIL))
    return 1 if FAIL else 0


# ---------------------------------------------------------------------------
# 13. THE CITATION CHECK.  Round 1 of this wave shipped ~31 citations that named
#     the imm32 instead of the opcode -- one byte past the instruction, and
#     gate-clean forever.  This check re-derives EVERY six-hex-digit prom_a
#     address in the prose this round writes into the .s and asserts it is a
#     LINE START in the gate-verified source, i.e. a real instruction or data
#     boundary.  The addresses that are deliberately NOT boundaries are listed
#     here with the reason, so the exception is auditable rather than silent.
# ---------------------------------------------------------------------------
NOT_A_BOUNDARY = {
    0xF8A42E: "the stale copy's back edge lands here ON PURPOSE mid-instruction",
    0xF8A44D: "a differing BYTE of the dead copy, not an instruction",
    0xF8A44E: "a differing BYTE of the dead copy",
    0xF8A455: "a differing BYTE of the dead copy",
    0xF8A458: "a differing BYTE of the dead copy",
    0xF8A459: "a differing BYTE of the dead copy",
    0xF8A4C6: "the byte AFTER the dead run -- an end, not a start",
    0xF8A8C6: "the matching byte in the live run",
    0xF8AA17: "the last byte of BitMask32ByIndex -- a range end",
    0xF8AF9F: "a STALE table pointer; it lands inside handler code, which is the point",
    0xF8AD71: "a stale table pointer",
    0xF8ADDD: "a stale table pointer",
    0xF8BBB3: "the last byte of the table block -- a range end",
    0xF8A100: "the low end of the decode-start sweep, quoted as a range",
    0xF8A42D: "quoted as the instruction the stale back edge lands INSIDE",
}
_HEX6 = re.compile(r'(?<![0-9A-Fa-f])0x([0-9A-F]{6})(?![0-9A-Fa-f])')


def my_prose():
    out = []
    for h in HEADERS.values():
        out += h
    out += DEAD_HEADER + [l.lstrip("; ") for l in WGM_NEW]
    out += [l for l in emit_block() if l.startswith(";")]
    out += [l for l in emit_bitmask_block() if l.startswith(";")]
    return out


def citation_check():
    _, items = parse_src()
    starts = {a for a, _, _ in items}
    cits = {}
    for ln in my_prose():
        for m in _HEX6.finditer(ln):
            a = int(m.group(1), 16)
            if 0xF80000 <= a <= 0xFFFFFF:
                cits.setdefault(a, ln.strip()[:90])
    bad = {a: t for a, t in cits.items() if a not in starts and a not in NOT_A_BOUNDARY}
    return cits, bad


if __name__ == "__main__":
    a = sys.argv[1:]
    if "--apply" in a:
        apply()
    elif "--verify" in a:
        sys.exit(0 if verify() else 1)
    elif "--emit" in a:
        print("\n".join(emit_block()))
    elif "--emit-bitmask" in a:
        print("\n".join(emit_bitmask_block()))
    elif "--tables" in a:
        mode_tables()
    elif "--producers" in a:
        mode_producers()
    elif "--ptrtables" in a:
        mode_ptrtables()
    elif "--collisions" in a:
        mode_collisions()
    elif "--stale" in a:
        mode_stale()
    elif "--wrappers" in a:
        mode_wrappers()
    elif "--census" in a:
        mode_census()
    else:
        sys.exit(selftest())
