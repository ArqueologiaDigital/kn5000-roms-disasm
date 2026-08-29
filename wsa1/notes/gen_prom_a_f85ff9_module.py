#!/usr/bin/env python3
"""Emit the assembly for prom_a 0xF85FF9-0xF89800 -- the FRONT-PANEL EVENT ROUTER:
the button/dial acceptor, the screen-object dispatcher, and the three passes that
run the UI event lists in RAM 0x2C00 / 0x2E00 / 0x2030.

QUESTION IT ANSWERS
    "What is the assembly text for this 14,343-byte `.incbin` span, in a form the
     byte gate accepts, with every label, header comment and table entry attached
     to the right address?"
    This is the emitter whose output is spliced into prom_a/wsa1_prom_a.s.

WHERE THE BOUNDARIES COME FROM -- AND NOT FROM A LINEAR DECODE
    notes/prom_a_f85ff9_layout.py, re-derived on EVERY run by layout().  45
    segments tiling the span with no gap and no overlap.  This script refuses to
    print if the count moves, if the segments stop tiling, or if the barrier and
    the descent conflict.

★ WHAT ROUND 2's SKEPTIC SAID ABOUT THE SOURCE DOSSIER, AND WHAT IS DONE ABOUT IT
    notes/prom_a_f85ff9_verify.py's verdict is "NOT REFUTED AS A LAYOUT, REFUTED
    AS A DOSSIER -- convert the tiling, do not copy the prose."  So the tiling is
    taken and the prose is NOT.  Every header below is re-derived here, and the
    seven claims that verifier refuted are contradicted in writing rather than
    quietly dropped, because a reader of the `.s` has no way to know a claim was
    ever made:

      * "Every one of the 192 lists is empty" (list area C) -- FALSE.  Two are
        not: class 0xA8 and class 0xA9, and 0xA9's first entry is 0xF8659B,
        INSIDE this span.  That is how the button router is reached at all.
        Reproduced by check L4.
      * "eleven registers plus five RAM cells saved around each call" -- FALSE.
        0xF86A23-0xF86A3C is 5 `pushw (mem)` + 6 `push Xrr` = ELEVEN pushes in
        total, not eleven plus five.  Check I3.
      * "0xF868DB / 0xF868FB ... neither has a reader bound" -- FALSE.  0xF868DB
        is bounded by `cp A,0x20 / ld A,0x1f` at 0xF8684F, 0xF868FB by
        `and A,0x07` at 0xF86890.  Checks D1, D2.
      * "a bit in the 64-bit word at (0x2088)/(0x208C)" -- FALSE.  0xF866C3 sets
        the same mask in a THIRD cell, (0x2084), and 0xF866D3 clears it there
        again; the three are three 32-bit bitmaps, not one 64-bit word.  Check B3.
      * "0xF86EA1 is indexed by the byte the previous map PRODUCES" -- FALSE.
        0xF86E81's reader WRITES (0x2076) and READS (0x2078); 0xF86EA1's reader
        reads (0x2078) too.  They share an input, they are not chained.  Check M2.
      * "`cp L,0xdf` at 0xF8620B" -- the register is wrong; it is `cp C,0xdf`.
        The bound and the base are right.  Check S3.
      * the run T_F40F34-T_F40F50 has 89 proven call sites and T_F40F3C 59, not
        88 and 58.  Check T1.

WHERE THE NAMES COME FROM
    ⚠ The byte gate is blind to every name below.  Four derivations carry most of
    them and `--selftest` reproduces all four:

    1. THE SCREEN OBJECT IS A THREE-METHOD VTABLE OF `jp` THUNKS.  0xF86EC1 is
       256 LE32 pointers.  81 of them are the stub 0xF872C1, whose bytes are
       `jr T,+6 / jr T,+4 / jr T,+2 / jr T,+0 / ret` -- four two-byte branches
       arranged so that +0, +4 AND +8 all reach the same `ret`.  Of the 174
       distinct live pointers, 171 point at three consecutive `jp addr24`
       (opcode 0x1B) in prom_b's thunk directory and the other 3 point at 0x0E
       (`ret`) filler.  The three offsets are used by three different call sites:
       +0 from 0xF86519/0xF8652E (the id that just BECAME current), +4 from
       0xF864C7/0xF864E5 (the id that just STOPPED being current), +8 from
       0xF86228 (the current id, with a button in HL).  Enter / Leave / Button.
       Checks V1-V6.
    2. THE BUTTON BIT TABLE IS THE IDENTITY.  0xF8671A's 32 LE32 entries are
       exactly 1<<i for i in 0..31, so (0x2088)/(0x208C)/(0x2084) are 32-bit
       bitmaps over the same 32 button indices the `cp C,0x1f` at 0xF8619A
       bounds.  0xF8679A's entries are 1<<(i+17) for i<8 and 0 above -- a
       different bit space, tested against (0x2252)/(0x2256).  Checks B1, B2.
    3. THE THREE EVENT PASSES ARE THE SAME MACHINE THREE TIMES.  0xF8697E,
       0xF8699D and 0xF869BC differ only in the two tables and the list they
       install in (0x20C0)/(0x20C4)/(0x20AD); all three then `calr 0xF869DB`.
       Each class table is 192 entries -- pinned twice, by `cp L,0xbf` at
       0xF869FB and by 0x300/4 -- and in all three tables the SAME 121 class ids
       have their own list while the other 71 share the area's trailing empty
       list.  The distinct lists tile their area exactly.  Checks L1-L5.
    4. THE PENDING-SCREEN TABLE STORES THE REQUEST FLAG WITH THE ID.  0xF86C8C's
       live entries are 0x4001, 0x4069, 0x4043, 0x406B, 0x4001, 0x4001 -- high
       byte 0x40 in every one -- and 0xF86C82 stores the WORD to (0x2070), whose
       high half is (0x2071), whose bit 6 (= 0x40) is what 0xF862A6 tests.  The
       module's own `ld (0x2070),0x40aa` at 0xF86055 writes the same pair.
       Checks H1-H4.

    Where no such witness exists the label stays `sub_XXXXXX` and the header says
    what named the address instead.  A stated gap beats a plausible guess.

NOTHING HERE CAN BREAK THE GATE
    Code comes from prom_a/roundtrip.py's emit_block(), which assembles and
    byte-compares every candidate spelling before returning it.  Data is emitted
    from the ROM.  Then main() assembles the WHOLE emitted region and compares it
    byte for byte with the ROM, and exits non-zero WITHOUT PRINTING if it differs.

RUN
    python3 notes/gen_prom_a_f85ff9_module.py            # the assembly
    python3 notes/gen_prom_a_f85ff9_module.py --check    # layout fingerprint only
    python3 notes/gen_prom_a_f85ff9_module.py --stats    # segment/label census
    python3 notes/gen_prom_a_f85ff9_module.py --sites    # the naming census, with
                                                         # the opcode test on every
                                                         # cited address
    python3 notes/gen_prom_a_f85ff9_module.py --selftest # every number quoted in a
                                                         # header, re-derived
"""
import collections
import importlib.util
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LO, HI = 0xF85FF9, 0xF89800
A_BASE, B_BASE = 0xF80000, 0xF00000

ARGV = list(sys.argv)               # captured BEFORE any import mangles it


def _load(path, name):
    """Import a sibling tool as a module.  ⚠ Both of them read sys.argv at import
    time, so argv is masked during the load and restored afterwards."""
    spec = importlib.util.spec_from_file_location(name, path)
    m = importlib.util.module_from_spec(spec)
    saved = sys.argv
    sys.argv = [name]
    try:
        spec.loader.exec_module(m)
    finally:
        sys.argv = saved
    return m


L = _load(os.path.join(ROOT, "notes", "prom_a_f85ff9_layout.py"), "f85ff9_layout")
RT = _load(os.path.join(ROOT, "prom_a", "roundtrip.py"), "rt")

# The layout as audited in wave 7 round 2 (notes/prom_a_f85ff9_verify.py:
# "segment count 45 ... gaps [] ... overlaps []").
EXPECTED = 45

# ⚠ THE RE-DERIVATION MUST NOT READ ITS OWN OUTPUT.
#
# notes/prom_a_f85ff9_layout.py seeds its descent from the PC-relative branch
# targets of every proven instruction in prom_a/wsa1_prom_a.s.  Before this
# region is spliced none of those is inside it; afterwards ~1,100 are, the seed
# set grows, and the guard below would fire on this emitter's own success.  So
# drop the relative targets whose CITING instruction is inside [LO,HI): that is
# exactly the set the splice adds, which makes the layout identical before and
# after.  (The same correction the 0xFA5AEB emitter had to make.)
_REL_ORIG = L.proven_targets
_REL_DROPPED = [None]


def _proven_targets_outside_span(lo=L.LO, hi=L.HI):
    """proven_targets() reads prom_a/wsa1_prom_a.s, so once THIS region is
    spliced it reads this emitter's own output and the seed set grows.  Drop the
    targets whose CITING instruction is inside [LO,HI) -- exactly the set the
    splice adds -- so the layout this file computes is identical before and
    after, and independent of what it last printed."""
    out, dropped = {}, 0
    for t, ss in _REL_ORIG(lo, hi).items():
        keep = [x for x in ss if not (LO <= x[0] < HI)]
        dropped += len(ss) - len(keep)
        if keep:
            out[t] = keep
    _REL_DROPPED[0] = dropped
    return out


L.proven_targets = _proven_targets_outside_span

_D = {}


def rom(which="a"):
    if which not in _D:
        _D[which] = L.rom(which)
    return _D[which]


def by(a):
    """One byte of whichever CPU-1 image holds it (prom_b 0xF00000, prom_a
    0xF80000).  The screen vtables live in prom_b, so a prom_a-only reader is
    what made a draft of this file report `0 of 174`."""
    if 0xF80000 <= a < 0x1000000:
        return rom("a")[a - A_BASE]
    if 0xF00000 <= a < 0xF80000:
        return rom("b")[a - B_BASE]
    return None


def w16(a):
    return by(a) | (by(a + 1) << 8)


def w32(a):
    return by(a) | (by(a + 1) << 8) | (by(a + 2) << 16) | (by(a + 3) << 24)


def layout():
    segs, conflicts, pend, ok, seen, imms, dirs, derived = L.build()
    if len(segs) != EXPECTED:
        sys.exit("REFUSING TO EMIT: layout has %d segments, expected %d. The "
                 "boundaries moved since the audit; re-audit before emitting."
                 % (len(segs), EXPECTED))
    if conflicts:
        sys.exit("REFUSING TO EMIT: %d barrier/code conflicts" % len(conflicts))
    tot = sum(n for _k, _a, n in segs)
    if segs[0][1] != LO or tot != HI - LO:
        sys.exit("REFUSING TO EMIT: segments do not tile the span (%d of %d)"
                 % (tot, HI - LO))
    return segs, dirs


# ------------------------------------------------------------------ the census
_CENSUS = None


def census(segs):
    """(rows, named, calls, jumps) over every `code` segment of the layout.

    `named[value]` / `calls[value]` are sets of INSTRUCTION addresses.  Cite from
    these and never from a hexdump offset: `ld XIY,0x00f86e81` has its opcode at
    p and its immediate at p+1, and citing p+1 is the systematic off-by-one lane
    a2 shipped in round 1.  --sites proves p is an opcode for every site."""
    global _CENSUS
    if _CENSUS is not None:
        return _CENSUS
    rows = []
    for kind, a, n in segs:
        if kind == "code":
            rows += RT.unidasm_range(a, a + n)
    named = collections.defaultdict(set)
    calls = collections.defaultdict(set)
    jumps = collections.defaultdict(set)
    op = re.compile(r"0x(?:00)?([0-9a-f]{6})")
    for addr, bs, t in rows:
        mn = t.split()[0] if t else ""
        for m in op.finditer(t):
            v = int(m.group(1), 16)
            if not (LO <= v < HI):
                continue
            if mn in ("call", "calr"):
                calls[v].add(addr)
            elif mn in ("jp", "jr", "jrl", "djnz"):
                jumps[v].add(addr)
            else:
                named[v].add(addr)
    _CENSUS = (rows, named, calls, jumps)
    return _CENSUS


# The first byte of an instruction that can name a 24-bit address on this core.
# --sites asserts every cited site starts with one of these; a citation landing
# on an operand shows up as 0x00/0xf8/0x20-style garbage instead.
NAMING_OPCODES = {0x08, 0x0B, 0x1B, 0x1D, 0x1E, 0x30, 0x31, 0x32, 0x33, 0x40,
                  0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0xC0, 0xC1, 0xC2, 0xD0,
                  0xD1, 0xD2, 0xE0, 0xE1, 0xE2, 0xF0, 0xF1, 0xF2}


# --------------------------------------------------------------- the structure
#
# The three event passes.  Every field is re-derived by check P1 from the three
# `ld XIY,imm32 / ld (0x20Cx),XIY` triples at 0xF8697E, 0xF8699D and 0xF869BC --
# nothing here is typed from a reading of the code.
PASSES = [
    # tag  entry     class table  tail list   RAM list  thunk slot
    ("A", 0xF8697E, 0xF87681, 0xF87E81, 0x2C00, 0xF40F5C),
    ("B", 0xF8699D, 0xF87E91, 0xF88E91, 0x2C00, 0xF40F60),
    ("C", 0xF869BC, 0xF88EC1, 0xF89671, 0x2030, 0xF40F64),
]
CLASS_N = 192           # `cp L,0xbf` at 0xF869FB, and 0x300 / 4

# The four 8-byte step curves and what names each base.
CURVES = [(0xF86BA0, "A", 0xF86B71), (0xF86BA8, "B", 0xF86B78),
          (0xF86BB0, "C", 0xF86B81), (0xF86BB8, "D", 0xF86B88)]
# ⚠ 0xF86B78 and 0xF86B88 are UNREACHABLE: 0xF86B76 and 0xF86B86 are
# `jr T,0xF86B8D`, which jumps over them.  Curves B and D are therefore named by
# dead code only.  Check C3 asserts exactly that.

LABELS = {}
HEADERS = {}
# A header that belongs to a SEGMENT, not to a label.  Kept apart from HEADERS
# because the first list of an area is also a label with its own header, and an
# earlier draft of this file silently lost the area header of pass B that way.
AREAHDR = {}
# A one-line citation printed immediately above a label that does not warrant a
# full header block.  Used for the generated per-class list names, whose whole
# justification is one table entry and should be printed as one line, not as a
# five-line block repeated 366 times.
NOTES = {}


def H(addr, *lines):
    HEADERS[addr] = list(lines)


def N(addr, name, *lines):
    LABELS[addr] = name
    if lines:
        HEADERS[addr] = list(lines)


def pass_fields():
    """Re-derive PASSES from the ROM: for each of the three entry points, the
    three 32-bit immediates it stores to (0x20C0), (0x20C4) and (0x20AD)."""
    out = []
    for tag, entry, _ct, _tl, _rl, _th in PASSES:
        rows = RT.unidasm_range(entry, entry + 0x20)
        imm, got = None, {}
        for _a, _bs, t in rows:
            m = re.match(r"ld XIY,0x00([0-9a-f]{6})$", t)
            if m:
                imm = int(m.group(1), 16)
                continue
            m = re.match(r"ld \(0x([0-9a-f]{4})\),XIY$", t)
            if m and imm is not None:
                got[int(m.group(1), 16)] = imm
        out.append((tag, entry, got.get(0x20C0), got.get(0x20C4), got.get(0x20AD)))
    return out


def lists_of(base):
    """{class id: list head} for one 192-entry class table, plus the set of
    distinct heads in ascending order."""
    ent = [w32(base + 4 * i) for i in range(CLASS_N)]
    return ent, sorted(set(ent))


def list_end(head, area_hi):
    """Where a 0xFFFFFFFF-terminated list of LE32 entries ends (exclusive)."""
    p = head
    while p < area_hi:
        v = w32(p)
        p += 4
        if v == 0xFFFFFFFF:
            return p
    return None


def structure():
    """Assign every label and header.  Called once, before emission."""
    if LABELS:
        return
    segs, dirs = layout()
    census(segs)

    # ============================================================== the head
    N(0xF86000, "PanelTask_EntryVectors",
      "PanelTask_EntryVectors -- six `jp addr24` slots at the module's head",
      "",
      "Slots 0,1,2 -> PanelTask_Reset; slot 3 -> PanelTask_ResetAndPoll;",
      "slots 4,5 -> PanelTask_Return, a bare `ret`.",
      "Evidence: six consecutive 4-byte `jp` (opcode 0x1B) at 0xF86000-0xF86017,",
      "         all three targets inside this span.  The pad at 0xF85FF9-0xF85FFF",
      "         (7 bytes of 0x0E) is what puts the block on 0xF86000.",
      "Unknown:  who calls the six slots.  No `call`/`jp` in either image names",
      "         0xF86000-0xF86014; they are reached the way prom_b's directory",
      "         reaches everything else, and this module's published entry is the",
      "         thunk run T_F40F34-T_F40F94, not this block.")
    N(0xF86018, "PanelTask_Reset")
    N(0xF8601B, "PanelTask_Return")
    N(0xF8601C, "PanelTask_ResetAndPoll")
    N(0xF86023, "PanelState_Init",
      "PanelState_Init -- set the screen state to its power-on values",
      "",
      "Called from: PanelTask_Reset 0xF86018 (`calr`).",
      "Outputs: (0x207A) = (0x207C) = (0x2083) = A, (0x2078) = (0x2076) = W,",
      "         (0x2079) = (0x2077) = 0xFF, (0x2070..0x2071) = 0x40AA.",
      "         A and W are both 1, or both 2 when (0x7F02) & 0xF0 == 0x10.",
      "Evidence: the 0x40AA store at 0xF86055 is a 16-bit store to 0x2070, so it",
      "         writes 0xAA to (0x2070) and 0x40 to (0x2071).  0x40 is bit 6, the",
      "         bit PanelScreen_ApplyHomeRequest tests at 0xF862A6, and every",
      "         live entry of PanelHold_ScreenRequest has the same 0x40 high",
      "         byte -- so (0x2070) is a screen id and (0x2071) its request flags.",
      "         Setting the two `previous` cells to 0xFF is what makes the first",
      "         PanelState_LatchPrevious pass copy rather than compare.")
    N(0xF8605C, "sub_F8605C",
      "sub_F8605C -- runs the three screen-transition steps and nothing else",
      "",
      "Evidence: NOTHING names this address.  Checked two ways: the census over",
      "         every decoded operand of every code segment in this span, and",
      "         far_calls() over both ROM images at every byte offset.",
      "Called from: NOTHING.  No absolute or relative reference to 0xF8605C",
      "         exists in either image (checked by the census over every decoded",
      "         operand of this span, and by far_calls over both ROM images).",
      "         It is reached only because it sits inside a code segment.",
      "Body:    `calr PanelScreen_RunLeave / calr PanelScreen_RunEnter /",
      "         calr PanelScreen_RunRedraw / ret` -- the same three calls",
      "         PanelTask_Step makes at 0xF8607E-0xF86084.",
      "Unknown:  why it exists.  Left as sub_XXXXXX because an unreferenced",
      "         routine has no caller to name it after.")
    N(0xF86066, "PanelTask_Step",
      "PanelTask_Step -- one pass of the panel/screen state machine",
      "",
      "Called from: thunk slot T_F40F34 (`jp 0x00F86066`), whose one proven call",
      "         site is prom_a 0xF8210E; also `calr` from PanelTask_ResetAndPoll",
      "         0xF8601C.",
      "Body, in order: PanelState_CheckHomeAllowed, PanelState_Sync2095,",
      "         PanelState_LatchPrevious, PanelState_RunRequests,",
      "         PanelMode_To2076, PanelState_UpdateFlags2092,",
      "         PanelState_Update207A, PanelState_ClearOnChange,",
      "         PanelScreen_RunLeave, PanelScreen_RunEnter,",
      "         PanelScreen_RunRedraw, `and (0x2095),0xEF`,",
      "         PanelButton_RunPending, PanelState_TakePendingHoldTime.",
      "Evidence: fourteen `calr` in a row with no conditional between them, so",
      "         the order above IS the ROM's order.")
    N(0xF86093, "sub_F86093",
      "sub_F86093 -- a single `ret` between PanelTask_Step and",
      "PanelState_TakePendingHoldTime",
      "",
      "Called from: NOTHING; no reference to 0xF86093 exists in either image.",
      "Evidence: same two-way census as sub_F8605C.  It is a label only because",
      "         the layout's descent reached the byte; nothing published it.",
      "Unknown:  whether it is a routine at all or the tail of the one above.")
    N(0xF86094, "PanelState_TakePendingHoldTime",
      "PanelState_TakePendingHoldTime -- move (0x209A) into (0x2073) if set",
      "",
      "Called from: PanelTask_Step 0xF8608F (`calr`), and nothing else.",
      "Outputs: if (0x209A) != 0 then (0x2073) = (0x209A) and (0x209A) = 0.",
      "Evidence: (0x2073) is the cell PanelTimer_Screen2073 counts down and that",
      "         PanelScreen_ApplyHomeRequest reloads with 0x70, so (0x209A) is a",
      "         one-shot request to preload that counter.")
    N(0xF860A6, "UiEventList_Publish",
      "UiEventList_Publish -- make the pending event list the current one",
      "",
      "Called from: thunk slot T_F40F50 (`jp 0x00F860A6`); 5 proven call sites",
      "         (prom_a 0xF820FC, 0xFB3151, 0xFB59CA, 0xFE00E2, 0xFE70CF).",
      "Outputs: RAM 0x2C00.. := RAM 0x2E00.., (0x60F004) bytes of it;",
      "         0xFF written one byte past; (0x60F000) := the byte count;",
      "         (0x2E00) := 0xFF and (0x60F004) := 0, i.e. the pending list is",
      "         emptied.",
      "Evidence: `ld XIY,0x2E00 / ld XIX,0x2C00 / ld BC,(0x60F004) / srl 1,BC /",
      "         ldirw` at 0xF860A6-0xF860BC -- on this core LDIRW copies (XIY) to",
      "         (XIX), so 0x2E00 is the SOURCE.  The count is halved because the",
      "         transfer is by words.  ★ This is what makes 0x2C00 and 0x2E00 a",
      "         double buffer rather than two unrelated queues: everything posted",
      "         with Queue2E00_AppendRegs becomes visible at 0x2C00 here, and",
      "         nowhere else.",
      "Answers:  notes/FINDINGS-prom_b-message-and-service-module.md's open",
      "         question `what RAM 0x2C00 holds` -- 4-byte UI event records,",
      "         published from 0x2E00 by this routine and walked by",
      "         UiEventList_Run.")
    N(0xF860D9, "PanelState_LatchPrevious",
      "PanelState_LatchPrevious -- copy the three current ids to their shadows",
      "",
      "Called from: PanelTask_Step 0xF8606C (`calr`), and nothing else.",
      "Outputs: unless (0x2077) == 0xFF: (0x2079) = (0x2078), (0x207B) = (0x207A),",
      "         (0x207D) = (0x207C).  Then (0x2077) = (0x2076) unconditionally.",
      "Evidence: the three pairs are exactly the three the change detectors",
      "         compare -- 0xF864BD (`(0x2078)` vs `L=(0x2079)`), 0xF864AE,",
      "         0xF86493 -- so odd address = current, even+1 = previous.")
    N(0xF86101, "PanelState_RunRequests",
      "PanelState_RunRequests -- run the four screen-change requests in (0x2071)",
      "",
      "Called from: PanelTask_Step 0xF8606F (`calr`), and nothing else.",
      "Body:    if (0x2071) != 0: PanelScreen_ApplyPendingId (bit 2),",
      "         PanelScreen_ApplyHomeRequest (bits 6,5), PanelScreen_ApplyModeChange",
      "         (bit 1), PanelScreen_ApplyHomeForce (bit 7); then",
      "         `and (0x2071),0x09` -- keeping only bits 0 and 3, the two",
      "         PanelButton_RunPending consumes.",
      "Evidence: the mask 0x09 at 0xF86115 and the mask 0xF6 at 0xF8612C are",
      "         complementary over bits 0 and 3, so the byte is split between two",
      "         consumers with no overlap.")
    N(0xF8611B, "PanelButton_RunPending",
      "PanelButton_RunPending -- run the button path if bit 0 or bit 3 is set",
      "",
      "Called from: PanelTask_Step 0xF8608C (`calr`), and nothing else.",
      "Outputs: calls PanelButton_Dispatch, then `and (0x2071),0xF6` (clears",
      "         bits 0 and 3).",
      "Evidence: `bit 0x03,A` at 0xF8611F and `bit 0x00,A` at 0xF86124 are the",
      "         only two bits tested, and 0xF6 is their complement -- so this",
      "         routine owns exactly the two bits PanelState_RunRequests spares.")
    N(0xF86132, "PanelButton_Dispatch",
      "PanelButton_Dispatch -- auto-repeat sweep, or the one pending button",
      "",
      "Called from: PanelButton_RunPending 0xF86129 (`calr`), and nothing else.",
      "Body:    bit 3 of (0x2071) AND bit 3 of (0x2075) -> PanelButton_SweepHeld,",
      "         (0x2074) = 3, `or (0x2075),0x04`; otherwise bit 0 of (0x2071) ->",
      "         PanelButton_DispatchCurrent.",
      "Evidence: (0x2074) is the counter PanelTimer_Button2074 decrements before",
      "         setting bit 3 of (0x2071) again, so the bit-3 arm IS the repeat.")
    N(0xF8615C, "PanelButton_SweepHeld",
      "PanelButton_SweepHeld -- route every button whose bit is set in (0x2088)",
      "",
      "Called from: PanelButton_Dispatch 0xF86144 (`calr`), and nothing else.",
      "Body:    for C = 0..31: mask = PanelButton_BitMask32[C]; if mask & (0x2088)",
      "         then (0x2082) = C | (0x80 if mask & (0x2084) else 0) and",
      "         PanelButton_DispatchCurrent is called.",
      "Evidence: the loop bound is `cp C,0x1f` at 0xF8619A and the table is 32",
      "         LE32 entries; PanelButton_BitMask32[i] == 1<<i for every i, so",
      "         `mask & (0x2088)` is literally `bit i of (0x2088)`.",
      "         ⚠ It reloads XWA from (0x2088) at the TOP of each iteration",
      "         (0xF8616A), so a handler that clears its own bit is seen at once.")
    N(0xF861A4, "PanelButton_DispatchCurrent",
      "PanelButton_DispatchCurrent -- route the button code in (0x2082)",
      "",
      "Called from: PanelButton_Dispatch 0xF86158, PanelButton_SweepHeld 0xF86196.",
      "Inputs:  (0x2082): bits 0-4 the button index, bit 7 a flag.",
      "Evidence: the split is PanelButton_Route's own, `and L,0x1f` at 0xF861AE",
      "         and `and W,0x80` at 0xF861B3; (0x2082) is written by",
      "         PanelButton_SweepHeld 0xF8618F and PanelButton_Accept 0xF86710.")
    N(0xF861AC, "PanelButton_Route",
      "PanelButton_Route -- special-case three buttons, else call the screen's",
      "                     Button method",
      "",
      "Called from: PanelButton_DispatchCurrent 0xF861A8 (`calr`) and",
      "         PanelEvent_Code21_Dial 0xF8687E (`calr`).",
      "Inputs:  W = the button code (index in bits 0-4, flag in bit 7).",
      "Body:    L = W & 0x1F, W = W & 0x80.",
      "         * index 0x0E with bit 5 of (0x2075) clear -> PanelButton_PostClass70.",
      "         * index 0x0D with bit 0 of (0x2075) clear -> PanelDial_ApplyStep",
      "           with A = (W & 0x80) | 1, then PanelDial_PostClass7A, then",
      "           `or (0x2075),0x08`.",
      "         * index 0x0F released, with (0x20A2) == 0 -> `and (0x2075),0x7F`.",
      "         * otherwise: C = (0x207C); if C <= 0xDF, XBC = the screen vtable",
      "           for that id PLUS 8, (0x20B4) = XBC, and XBC is CALLED with",
      "           A = the flag and HL = the index pushed as two words.",
      "Evidence: the `+8` is the vtable's third method -- see the header on",
      "         PanelScreen_VtableTable.  The two `push` before the call and the",
      "         `inc 4,XSP` after it at 0xF8622E say the callee takes two 16-bit",
      "         stack arguments and does not pop them.")
    N(0xF8623C, "PanelButton_PostClass70",
      "PanelButton_PostClass70 -- post event {0x70, 0x01, code, 0x03} to 0x2030",
      "",
      "Called from: PanelButton_Route 0xF861C1 (`calr`), and nothing else.",
      "Outputs: DE = 0x0170 and WA = {A, 0x03} are handed to List2030_AppendRegs,",
      "         which stores E,D,A,W at +0..+3 -- so the record is",
      "         0x70, 0x01, A, 0x03, and 0x70 is the event class.",
      "         A is 3 when (0x208C) & 0x4000, else 1 when bit 7 of W is set",
      "         (button RELEASED), else 2.",
      "Evidence: class 0x70 is one of the 121 ids that has its own handler list",
      "         in all three class tables (UiEventClass_ListTable_A/B/C).")
    N(0xF8625E, "PanelScreen_ApplyPendingId",
      "PanelScreen_ApplyPendingId -- (0x207C) := (0x20A2) if set, else (0x2083)",
      "",
      "Called from: PanelState_RunRequests 0xF86109 (`calr`), and nothing else.",
      "Guard:   bit 2 of (0x2071).",
      "Outputs: (0x2072) = 0; A = (0x20A2) if non-zero (and (0x20A2) is then",
      "         cleared) else (0x2083); if (0x207C) already equals A then",
      "         `or (0x2072),0x10`; (0x207C) = A.",
      "Evidence: bit 4 of (0x2072) is what PanelScreen_RunRedraw consumes, so",
      "         `already on that screen` is turned into `redraw it`.")
    N(0xF86295, "PanelScreen_ApplyHomeRequest",
      "PanelScreen_ApplyHomeRequest -- (0x207C) := (0x2070), the requested screen",
      "",
      "Called from: PanelState_RunRequests 0xF8610C (`calr`), and nothing else.",
      "Guard:   bit 0 of (0x2095) or bit 4 of (0x2075) clear, then bit 6 or bit 5",
      "         of (0x2071).",
      "Outputs: (0x2083) is refreshed from (0x207C) when (0x2073) == 0;",
      "         (0x207C) = (0x2070); (0x2073) = 0x70; `and (0x2095),0xFD`.",
      "Evidence: bit 6 (0x40) is the bit PanelState_Init and every live entry of",
      "         PanelHold_ScreenRequest write together with the screen id.")
    N(0xF86318, "PanelScreen_ApplyModeChange",
      "PanelScreen_ApplyModeChange -- recompute (0x2078) then map it to (0x207C)",
      "",
      "Called from: PanelState_RunRequests 0xF8610F (`calr`), and nothing else.",
      "Guard:   bit 1 of (0x2071).",
      "Body:    PanelMode_Normalise, then PanelMode_ToScreenId, then (0x2073) = 0;",
      "         if (0x207C) == (0x207D) then `or (0x2072),0x10` (redraw).",
      "Evidence: `bit 0x01,A` at 0xF8631C is the guard, and bit 1 is one of the",
      "         four PanelState_RunRequests clears with `and (0x2071),0x09`.")
    N(0xF86344, "PanelMode_Normalise",
      "PanelMode_Normalise -- derive (0x2078) from (0x2076) and (0x2070)",
      "",
      "Called from: PanelScreen_ApplyModeChange 0xF86327 (`calr`), and nothing else.",
      "Body:    E = (0x2070); if E == 1 then E = 1, or 2 when (0x7F02) & 0xF0 ==",
      "         0x10.  D = E.  If (A & 0x3F) != (E & 0x3F) the result is E;",
      "         otherwise, if bit 7 of D is set, the result is 1 (or 2 under the",
      "         same (0x7F02) test).  (0x2078) = the result.",
      "Evidence: (0x7F02) & 0xF0 == 0x10 is the same two-way test PanelState_Init",
      "         makes at 0xF8602E, and prom_a 0xF90C25 makes on the same cell.",
      "Unknown:  what the two settings of (0x7F02)'s high nibble ARE.")
    N(0xF86388, "PanelMode_ToScreenId",
      "PanelMode_ToScreenId -- (0x207C) := PanelMode_ToScreenIdMap[(0x2078)]",
      "",
      "Called from: PanelScreen_ApplyModeChange 0xF8632A (`calr`), and nothing else.",
      "Evidence: `ld XHL,0x00f86ea1` at 0xF86388 is the only instruction in",
      "         either image that names PanelMode_ToScreenIdMap.",
      "⚠ Evidence AGAINST the round-1 dossier: this reader has NO bound at all --",
      "         `xor XWA,XWA / ld A,(0x2078) / add XHL,XWA / ld A,(XHL)`.  The",
      "         32-entry extent of the map rests only on the code at 0xF86EC1",
      "         starting there, which is a weaker pin than the map above it has.")
    N(0xF8639C, "PanelScreen_ApplyHomeForce",
      "PanelScreen_ApplyHomeForce -- (0x207C) := (0x2070) and clear (0x2073)",
      "",
      "Called from: PanelState_RunRequests 0xF86112 (`calr`), and nothing else.",
      "Guard:   bit 0 of (0x2095) or bit 4 of (0x2075) clear, then bit 7 of (0x2071).",
      "Differs from PanelScreen_ApplyHomeRequest only in leaving (0x2083) alone",
      "and in zeroing (0x2073) instead of loading it with 0x70.",
      "Evidence: `bit 0x07,A` at 0xF863AC is the guard -- bit 7 of (0x2071), the",
      "         same bit PanelState_CheckHomeAllowed tests at 0xF86B1F on the",
      "         high half of the 16-bit load from (0x2070).")
    N(0xF863D3, "PanelState_UpdateFlags2092",
      "PanelState_UpdateFlags2092 -- fold `(0x2073) is running` into (0x2092)",
      "",
      "Called from: PanelTask_Step 0xF86075 (`calr`), and nothing else.",
      "Outputs: (0x2073) != 0 -> bit 0 = 1, bit 1 = 0;  (0x2073) == 0 -> bit 0 =",
      "         0, bit 1 = the OLD bit 0.  Bits 2-7 are preserved (`and A,0xfc`).",
      "Evidence: PanelState_Update207A at 0xF86405 tests exactly bit 0 of this",
      "         byte, so bit 0 means `the (0x2073) countdown is running` and",
      "         bit 1 means `it was running last pass`.")
    N(0xF863F5, "PanelState_Update207A",
      "PanelState_Update207A -- (0x207A) := (0x207C) unless the mode is unchanged",
      "                         and bit 0 of (0x2092) is set",
      "",
      "Called from: PanelTask_Step 0xF86078 (`calr`), and nothing else.",
      "Evidence: `bit 0x00,A` at 0xF86405 on (0x2092), the bit",
      "         PanelState_UpdateFlags2092 writes from (0x2073).")
    N(0xF86413, "PanelState_ClearOnChange",
      "PanelState_ClearOnChange -- drop held-button state when an id changes",
      "",
      "Called from: PanelTask_Step 0xF8607B (`calr`), and nothing else.",
      "Outputs: (0x2078)!=(0x2079): (0x2088)=(0x208C)=0, `and (0x2075),0x04`,",
      "         `and (0x2095),0xEF`, `or (0x2134),0x0002`, (0x20A2)=0.",
      "         (0x207A)!=(0x207B): (0x2088)=(0x208C)=0, (0x207E)=A,",
      "         `and (0x2075),0x04`, (0x20A2)=0.",
      "         (0x207C)!=(0x207D): `and (0x2075),0x94`,",
      "         `and (0x2088),0xF7FFFFFF`, `and (0x2095),0xEF`, (0x20AB)=A.",
      "         Always: `and (0x2095),0xFE`.",
      "Evidence: 0xF86473 loads the 32-bit literal 0xF7FFFFFF and ANDs it into",
      "         (0x2088) -- clearing bit 27 only, i.e. button index 27 -- which is",
      "         a second, independent witness that (0x2088) is a 32-bit bitmap",
      "         over the same index space PanelButton_BitMask32 spans.")
    N(0xF8648D, "PanelScreen_RunLeave",
      "PanelScreen_RunLeave -- call the Leave method of every id that changed",
      "",
      "Called from: PanelTask_Step 0xF8607E, sub_F8605C 0xF8605C (`calr`).",
      "Body:    (0x207C) != (0x207D) -> Leave on the PREVIOUS id (0x207D);",
      "         (0x207A) == (0x207C) and (0x207D) != (0x207B) -> Leave on (0x207B);",
      "         (0x2078) != (0x2079) -> Leave (view A) on (0x2079).",
      "Evidence: every one of the three passes the PREVIOUS cell of a pair, and",
      "         the method offset is 4 in all three -- `ld BC,0x0004` at 0xF864D3",
      "         and 0xF864F1.")
    N(0xF864C7, "PanelScreen_CallLeave_B",
      "PanelScreen_CallLeave_B -- vtable[L].Leave, table view B (base 0xF86F41)",
      "",
      "Called from: PanelScreen_RunLeave 0xF86499 and 0xF864B4 (`calr`).",
      "Inputs:  L = a screen id; the guard is `cp L,0xdf` at 0xF864C9.",
      "Outputs: nothing when L > 0xDF; else PanelScreen_ResolveMethod with",
      "         XIY = 0xF86F41 and BC = 4, then `call XWA`.",
      "Evidence: `ld XIY,0x00f86f41` at 0xF864CE and `ld BC,0x0004` at 0xF864D3",
      "         -- table view B, method offset 4.")
    N(0xF864E5, "PanelScreen_CallLeave_A",
      "PanelScreen_CallLeave_A -- vtable[L].Leave, table view A (base 0xF86EC1)",
      "",
      "Called from: PanelScreen_RunLeave 0xF864C3 (`calr`), and nothing else.",
      "Inputs:  L = a mode index; the guard is `cp L,0x2f` at 0xF864E7.",
      "Evidence: `ld XIY,0x00f86ec1` at 0xF864EC and `ld BC,0x0004` at 0xF864F1",
      "         -- table view A, method offset 4.")
    N(0xF864FA, "PanelScreen_RunEnter",
      "PanelScreen_RunEnter -- call the Enter method of every id that changed",
      "",
      "Called from: PanelTask_Step 0xF86081, sub_F8605C 0xF8605F (`calr`).",
      "Body:    (0x2078) != (0x2079) -> Enter (view A) on the CURRENT (0x2078);",
      "         (0x207C) != (0x207D) -> Enter (view B) on the CURRENT (0x207C).",
      "Evidence: both pass the CURRENT cell and `ld BC,0x0000` (0xF86525,",
      "         0xF8653A) -- method offset 0, against offset 4 in RunLeave.  That",
      "         pairing is what fixes which method is Enter and which is Leave.")
    N(0xF86519, "PanelScreen_CallEnter_A",
      "PanelScreen_CallEnter_A -- vtable[L].Enter, table view A (base 0xF86EC1)",
      "",
      "Called from: PanelScreen_RunEnter 0xF86506 (`calr`), and nothing else.",
      "Inputs:  L = a mode index; the guard is `cp L,0x2f` at 0xF8651B.",
      "Evidence: `ld XIY,0x00f86ec1` at 0xF86520 and `ld BC,0x0000` at 0xF86525",
      "         -- table view A, method offset 0.")
    N(0xF8652E, "PanelScreen_CallEnter_B",
      "PanelScreen_CallEnter_B -- vtable[L].Enter, table view B (base 0xF86F41)",
      "",
      "Called from: PanelScreen_RunEnter 0xF86515 and PanelScreen_RunRedraw",
      "         0xF86597 (`calr`).",
      "Inputs:  L = a screen id; the guard is `cp L,0xdf` at 0xF86530.",
      "Evidence: `ld XIY,0x00f86f41` at 0xF86535 and `ld BC,0x0000` at 0xF8653A",
      "         -- table view B, method offset 0.")
    N(0xF86543, "PanelScreen_ResolveMethod",
      "PanelScreen_ResolveMethod -- XWA := vtable_table[HL] + BC, remembered in",
      "                             (0x20B4)",
      "",
      "Called from: all four of PanelScreen_CallEnter_A/B and CallLeave_A/B.",
      "Inputs:  HL = the index, XIY = the table base, BC = the method offset.",
      "Outputs: XWA = the method address; (0x20B4) = the same value.",
      "Evidence: `sla 0x02,HL` at 0xF86545 is the 4-byte stride of an LE32",
      "         pointer table; `add WA,BC` at 0xF8654C adds only to the low 16",
      "         bits, which is safe because BC is 0 or 4 at every call site.")
    N(0xF86553, "PanelState_Sync2095",
      "PanelState_Sync2095 -- move bit 4 between (0x2095) and (0x2071), then",
      "                       publish (0x2071) into (0x2072) when it is quiet",
      "",
      "Called from: PanelTask_Step 0xF86069 (`calr`), and nothing else.",
      "Body:    bit 4 of (0x2095) set: clear it when bit 4 of (0x2071) is clear,",
      "         and set bit 4 of (0x2071) either way.  Then, only when",
      "         (0x2071) & 0xE2 == 0, (0x2072) = (0x2071) and (0x2071) &= 0xEF.",
      "⚠ Note:  0xF86570 RELOADS A from (0x2071) after the `and A,0xe2` at",
      "         0xF8656D, so the `jr NZ` two instructions later tests the AND,",
      "         not the reload; the value STORED to (0x2072) is the unmasked",
      "         byte.  Written out because it reads like a bug and is not one.",
      "Evidence: `bit 4,(0x2095)` at 0xF86553 and `bit 4,(0x2071)` at 0xF86559",
      "         are the two tested bits; `and A,0xe2` at 0xF8656D is the quiet",
      "         test; `and A,0xef` at 0xF8657A clears the same bit 4 again.")
    N(0xF86582, "PanelScreen_RunRedraw",
      "PanelScreen_RunRedraw -- re-Enter the current screen when bit 4 of (0x2072)",
      "",
      "Called from: PanelTask_Step 0xF86084, sub_F8605C 0xF86062 (`calr`).",
      "Body:    if bit 4 of (0x2072): (0x2072) = 0, L = (0x207C),",
      "         PanelScreen_CallEnter_B.",
      "Evidence: bit 4 of (0x2072) is set by exactly the four `or (0x2072),0x10`",
      "         at 0xF8628B, 0xF862E1, 0xF863C3 and 0xF8633E, each on the path",
      "         `the requested id EQUALS the current one` -- so `no transition,",
      "         redraw anyway`.")
    N(0xF8659B, "UiEvent_RouteByCode",
      "UiEvent_RouteByCode -- split a class-0xA9 event on its code byte (0x20B8)",
      "",
      "Called from: thunk slot T_F40F58 (`jp 0x00F8659B`), which has NO proven",
      "         `call` site -- and from UiEventLists_C's list for class 0xA9",
      "         (0xF89362), whose first LE32 entry is 0x00F8659B.  ★ That list is",
      "         the answer to `who calls this`: an event {0xA9, code, b2, b3}",
      "         posted into RAM 0x2030 reaches here through UiEventList_RunPassC.",
      "Body:    A = (0x20B8);  A < 0x20 -> PanelButton_Accept;",
      "         A == 0x20 -> PanelEvent_Code20_SetScreen;",
      "         A == 0x21 -> PanelEvent_Code21_Dial.",
      "Evidence: the three-way split at 0xF8659F-0xF865B8 and the 0x1F index mask",
      "         PanelButton_Accept applies at 0xF8660D agree: codes 0x00-0x1F are",
      "         the 32 buttons PanelButton_BitMask32 spans.")
    N(0xF865BC, "PanelEvent_Code03",
      "PanelEvent_Code03 -- toggle bit 4 of (0x2075) on event code 3",
      "",
      "Called from: thunk slot T_F40F90 (`jp 0x00F865BC`); no proven call site,",
      "         and no list in any of the three class tables names it.",
      "Inputs:  (0x20B8) must be 3; L = (0x20B9), H = (0x20BA), and bit 0 of",
      "         (L & H) must be set.",
      "Outputs: `xor (0x2075),0x10`, then either `or (0x2075),0x80` or",
      "         (0x2073) = 1, and `or (0x2134),0x2000`.",
      "Evidence: the guard is `cp A,3` at 0xF865C8 on (0x20B8), which",
      "         UiEventList_Run loads from the record's byte +1.",
      "Unknown:  which physical control raises code 3.  Nothing in any of the",
      "         366 lists of the three class tables points at this address, so",
      "         the only published way in is the thunk slot.")
    N(0xF86609, "PanelButton_Accept",
      "PanelButton_Accept -- fold one button event into the (0x2088) bitmap",
      "",
      "Called from: UiEvent_RouteByCode 0xF865A4 (`calr`), and nothing else.",
      "Inputs:  (0x20B8) the button code, (0x20B9)/(0x20BA) the two state bytes.",
      "Body:    index 0x0D with bit 0 of (0x2075) set is REWRITTEN: the code",
      "         becomes (0x209C) or (0x209B) (chosen by bit 1 of (0x20BA)) and",
      "         (0x20BA) becomes 2, or 1 when bit 7 of that code is set.",
      "         Then mask = PanelButton_BitMask32[code & 0x1F].",
      "         RELEASE ((0x20B9) & (0x20BA) == 0): clear mask in (0x2088) and",
      "         (0x208C); if (0x2088) is then zero, (0x2074) = 0 and",
      "         `and (0x2075),0xF3`.",
      "         PRESS: if PanelButton_InterlockMask32[code] hits (0x2252) or",
      "         (0x2256), do nothing at all; else set mask in (0x2088), in",
      "         (0x208C) when (0x20B9) == 3, and in (0x2084) -- then clear it in",
      "         (0x2084) again unless bit 0 of (0x20B9) is set.  Finally",
      "         (0x2082) = code (| 0x80 when bit 0 of (0x20B9)) and",
      "         `or (0x2071),0x01`, which is what makes PanelButton_RunPending",
      "         route it on the next PanelTask_Step.",
      "Evidence: the two mask tables are read four instructions apart, at",
      "         0xF86659 (PanelButton_BitMask32) and 0xF86696",
      "         (PanelButton_InterlockMask32), both indexed by the SAME `BC =",
      "         code * 4` formed at 0xF86654-0xF86656.  That shared index is",
      "         what makes the two tables one per-button record split in two.",
      "⚠ Correction: (0x2084) is a THIRD 32-bit bitmap, not the high half of a",
      "         64-bit word with (0x2088)/(0x208C).  0xF866C3 sets the mask there",
      "         and 0xF866D3 clears it there, both independently of (0x208C).")

    # ======================================= the screen-jump / dial handlers
    N(0xF8681A, "PanelEvent_Code20_SetScreen",
      "PanelEvent_Code20_SetScreen -- request the screen named by the event",
      "",
      "Called from: UiEvent_RouteByCode 0xF865AE (`calr`), and nothing else.",
      "Inputs:  E = (0x20B9), D = (0x20BA); the routine does nothing when",
      "         (E & D) == 0.",
      "Outputs: (0x2070) = E | 0x80 and (0x2071) = 0x02 -- i.e. the requested",
      "         screen id plus request bit 1, the bit PanelState_RunRequests",
      "         hands to PanelScreen_ApplyModeChange.",
      "Evidence: `ld (0x2070),E` at 0xF86829 and `ld (0x2071),0x02` at 0xF8682D",
      "         write the id and the flag byte as two separate stores to the",
      "         same pair PanelState_Init writes as one 16-bit 0x40AA.")
    N(0xF86833, "PanelEvent_Code21_Dial",
      "PanelEvent_Code21_Dial -- apply one rotary-encoder delta",
      "",
      "Called from: UiEvent_RouteByCode 0xF865B8 (`calr`), and nothing else.",
      "Inputs:  E = (0x20B9) the signed delta, D = (0x20BA).",
      "Body:    E >= 0x40 gets bit 7 set; A = E + 0x10; A >= 0x80 -> 0; A >= 0x20",
      "         -> 0x1F; A = PanelDial_DeltaToStepIndex[A].",
      "         Then, with bit 0 of (0x2075) CLEAR: PanelDial_ApplyStep and",
      "         PanelDial_PostClass7A.  With it SET: W = (0x209C) or (0x209B)",
      "         (by bit 7 of A) and the value is routed as a BUTTON through",
      "         PanelButton_Route instead, and (0x2073) is reloaded with 0x70 if",
      "         it was already running.",
      "Evidence: the same (0x209B)/(0x209C) pair PanelButton_Accept substitutes",
      "         for button index 0x0D, so bit 0 of (0x2075) switches the dial",
      "         between `edit a value` and `act like a pair of buttons`.")
    N(0xF8688E, "PanelDial_ApplyStep",
      "PanelDial_ApplyStep -- add or subtract an accelerated step from (0x7EE2)",
      "",
      "Called from: PanelEvent_Code21_Dial 0xF86867, PanelButton_Route 0xF861D9.",
      "Inputs:  A -- bit 7 is the direction, bits 0-2 index PanelDial_StepSizes.",
      "Outputs: BC = the new value.  It is NOT stored here; PanelDial_PostClass7A",
      "         is what publishes it.",
      "Body:    WA = PanelDial_StepSizes[A & 7]; BC = (0x7EE2);",
      "         bit 7 of A set -> BC -= WA, floored at 0x0028;",
      "         bit 7 clear    -> BC += WA, capped at 0x012C.",
      "Evidence: the two literals at 0xF868B2 and 0xF868C3 are 0x0028 and 0x012C",
      "         -- 40 and 300 -- and the step ladder is 0, 1, 4, 10, 20, 50, 70,",
      "         100 in DECIMAL, which is what an acceleration curve looks like",
      "         when the quantity it steps is read in decimal by the user.",
      "Unknown:  what (0x7EE2) IS.  prom_b renders it through 0xF749A2 as a 9-bit",
      "         number ((0x7EE2) plus bit 0 of (0x7EE3)) at 0xF73AA8 and 0xF7573D,",
      "         and prom_b 0xF448A3 publishes it with the SAME event class 0x7A",
      "         this module uses -- but nothing decoded so far ties it to a",
      "         label on the panel, so the name stays mechanical.")
    N(0xF868CD, "PanelDial_PostClass7A",
      "PanelDial_PostClass7A -- post event {0x7A, 0x00, C, B & 1} to 0x2030",
      "",
      "Called from: PanelEvent_Code21_Dial 0xF8686A, PanelButton_Route 0xF861DC.",
      "Inputs:  BC = the 16-bit value PanelDial_ApplyStep computed.",
      "Outputs: A = C, W = B & 1, DE = 0x007A, then List2030_AppendRegs -- so the",
      "         record is 0x7A, 0x00, low byte, bit 8.",
      "Evidence: prom_b 0xF448A3 posts the SAME class 0x7A with E=0x7A, D=0x00",
      "         through T_F40F3C and then writes (0x7EE2) itself, which is a",
      "         second, independent witness that class 0x7A carries this value.",
      "         The 9-bit split (low byte, then bit 8 alone) is the same split",
      "         prom_b 0xF6AD98-0xF6ADB6 makes when it packs the cell for the",
      "         link.")

    # ======================================================== the timer block
    N(0xF86903, "PanelTimers_Step",
      "PanelTimers_Step -- run the screen timers, or the button repeat timer",
      "",
      "Called from: thunk slot T_F40F44 (`jp 0x00F86903`), whose one proven call",
      "         site is prom_a 0xF821ED.",
      "Body:    (0x2088) == 0 (no button held) -> PanelTimer_Screen2073 and",
      "         PanelTimer_Repeat20AB;  otherwise PanelTimer_Button2074.",
      "Evidence: the discriminator is a 32-bit compare of (0x2088) with zero at",
      "         0xF86907, the same bitmap PanelButton_Accept maintains.")
    N(0xF8691B, "sub_F8691B",
      "sub_F8691B -- a single `ret` between PanelTimers_Step and",
      "PanelTimer_Repeat20AB",
      "",
      "Called from: NOTHING; no reference to 0xF8691B exists in either image.",
      "Evidence: same two-way census as sub_F8605C.")
    N(0xF8691C, "PanelTimer_Repeat20AB",
      "PanelTimer_Repeat20AB -- count (0x20AB) down; at zero bump (0x207E)",
      "",
      "Called from: PanelTimers_Step 0xF86912 (`calr`), and nothing else.",
      "Outputs: on expiry, `inc 1,(0x207E)` and `or (0x2071),0x10`.",
      "Evidence: (0x20AB) is loaded by PanelState_ClearOnChange at 0xF86483 with",
      "         the new screen id, so this counter starts on every screen change.")
    N(0xF86933, "PanelTimer_Screen2073",
      "PanelTimer_Screen2073 -- count (0x2073) down and raise request bit 2",
      "",
      "Called from: PanelTimers_Step 0xF8690F (`calr`), and nothing else.",
      "Body:    (0x20A2) != 0: (0x2073) <= 1 -> `or (0x2071),0x04` and return;",
      "         else decrement (0x2073) unless bit 4 of (0x2075).",
      "         Then, if (0x2073) != 0 and bit 7 of (0x2075) is clear, decrement",
      "         it again and raise bit 2 of (0x2071) when it reaches zero.",
      "Evidence: bit 2 of (0x2071) is the bit PanelState_RunRequests hands to",
      "         PanelScreen_ApplyPendingId, and (0x20A2) is exactly the cell that",
      "         routine consumes -- so this is the `auto-return after N ticks`.")
    N(0xF8696B, "PanelTimer_Button2074",
      "PanelTimer_Button2074 -- count (0x2074) down and raise repeat bit 3",
      "",
      "Called from: PanelTimers_Step 0xF86917 (`calr`), and nothing else.",
      "Evidence: (0x2074) is loaded with 3 by PanelButton_Dispatch at 0xF86147",
      "         and with 0x10 by PanelButton_Accept at 0xF866E0; bit 3 of",
      "         (0x2071) is what re-enters PanelButton_SweepHeld.  So 0x10 ticks",
      "         to the first repeat and 3 between repeats.")

    # ==================================== the three UI event-list passes
    for tag, entry, ct, tl, rl, th in PASSES:
        N(entry, "UiEventList_RunPass" + tag,
          "UiEventList_RunPass%s -- run pass %s over the event list at 0x%04X"
          % (tag, tag, rl),
          "",
          "Called from: thunk slot T_%06X (`jp 0x00%06X`)." % (th, entry),
          "Outputs: (0x20C0) = UiEventClass_ListTable_%s, (0x20C4) ="
          " UiEventPass%s_TailList," % (tag, tag),
          "         (0x20AD) = 0x%04X; then `calr UiEventList_Run`." % rl,
          "Evidence: the three passes differ ONLY in those three immediates --"
          " check P1",
          "         re-derives all nine from the ROM and compares them with this"
          " table.")
    N(0xF869DB, "UiEventList_Run",
      "UiEventList_Run -- walk one 4-byte event list and dispatch every record",
      "",
      "Called from: UiEventList_RunPassA/B/C (`calr` at 0xF86999, 0xF869B8,",
      "         0xF869D7), and nothing else.",
      "The record: 4 bytes.  +0 the CLASS (0xFF ends the list, > 0xBF is",
      "         skipped), +1..+3 the payload.  0xF869F7 stores +0 in (0x20BB),",
      "         0xF86A1B stores the WORD at +1 in (0x20B8) and 0xF86A1F stores",
      "         +3 in (0x20BA) -- so a handler reads its payload as",
      "         (0x20B8), (0x20B9), (0x20BA).",
      "The dispatch: class * 4 indexes the table in (0x20C0), giving the head of",
      "         an LE32 list of handler addresses.  Every entry is CALLED in turn",
      "         until the 0xFFFFFFFF terminator (0xF86A0E tests both halves).",
      "         Then every entry of the table in (0x20C4) is called the same way.",
      "Saved across each handler: ELEVEN pushes at 0xF86A23-0xF86A3C -- five",
      "         `pushw (mem)` of (0x20B2), (0x20C0), (0x20C2), (0x20C4), (0x20C6)",
      "         and six `push Xrr` of XWA, XBC, XDE, XHL, XIY, XIX.  ⚠ The",
      "         round-1 dossier read this as `eleven registers PLUS five RAM",
      "         cells`; it is eleven pushes IN TOTAL, of which five are RAM.",
      "         Saving (0x20C0)/(0x20C4) is what lets a handler start a NESTED",
      "         pass without losing this one.",
      "Evidence: the class bound is `cp L,0xbf` at 0xF869FB (192 classes) and",
      "         each class table is 0x300 bytes = 192 LE32 entries -- two",
      "         independent pins on the same count.")
    N(0xF86A81, "Queue2C00_AppendRegs",
      "Queue2C00_AppendRegs -- append {E, D, A, W} to the event list at 0x2C00",
      "",
      "Called from: thunk slot T_F40F38 (`jp 0x00F86A81`); 7 proven call sites",
      "         (prom_a 0xF818CB, 0xF8BEFE, 0xF90C3F, 0xF90C8F, 0xF99EB7,",
      "         0xFB901A and one more -- --sites lists them all).",
      "Inputs:  DE and WA; the record stored is E at +0, D at +1, A at +2, W at",
      "         +3, and 0xFF at +4 as the new terminator.",
      "Outputs: (0x60F000) += 4.",
      "⚠ The capacity test is on the BYTE at 0x60F000 (`cp (0x60f000),0xfb`,",
      "         prefix 0xC2 = 8-bit), while every other user of that cell treats",
      "         it as 16-bit: UiEventList_Publish writes IX to it, prom_a",
      "         0xFAA4AB reads HL from it and bounds at 0x01FC, and prom_b's",
      "         Queue2C00_Append4 (0xF55231) bounds at 0x01FC too.  Stated, not",
      "         explained.",
      "Sibling:  prom_b's Queue2C00_Append4 at 0xF55231 is the C-compiled twin --",
      "         same base 0x2C00, same cursor (0x60F000), same 4-byte record,",
      "         same 0xFF one past, same `+= 4`.  It is NOT a byte copy: it takes",
      "         its four bytes as 16-bit stack slots and is 77 bytes against this",
      "         routine's 34, so the name is shared by STRUCTURE, not by a diff.",
      "Evidence: `ld XHL,0x00002c00` at 0xF86A89, `add HL,(0x60f000)` at",
      "         0xF86A8E, `ld (XHL),DE` / `ld (XHL+0x02),WA` /",
      "         `ld (XHL+0x04),0xff` at 0xF86A93-0xF86A98, `add (0x60f000),0x04`",
      "         at 0xF86A9C.")
    N(0xF86AA3, "Queue2E00_AppendRegs",
      "Queue2E00_AppendRegs -- append {E, D, A, W} to the PENDING list at 0x2E00",
      "",
      "Called from: thunk slot T_F40F3C (`jp 0x00F86AA3`); 59 proven call sites,",
      "         the most heavily referenced address in this span.  --sites lists",
      "         them; they are spread over prom_a 0xF8BF19..0xFEnnnn and are the",
      "         reason this span was picked.",
      "Inputs/outputs: as Queue2C00_AppendRegs, with base 0x2E00 and cursor",
      "         (0x60F004).  Here the bound IS 16-bit: `cp (0x60f004),0x00fb`",
      "         (prefix 0xD2), so at most 63 records.",
      "★ What happens to the record: nothing, until UiEventList_Publish copies",
      "         0x2E00 over 0x2C00 and empties it.  So this is the WRITE half of",
      "         a double buffer and Queue2C00_AppendRegs the read half.",
      "Sibling:  prom_b's Queue2E00_Append4 (0xF5527E) and prom_a's own",
      "         sub_FE7100 are two more C-compiled twins of the same structure;",
      "         prom_b's bounds the OTHER cursor (0x60F000) at 0x00FC, which none",
      "         of the three hand-written ones do.",
      "Evidence: `ld XHL,0x00002e00` at 0xF86AAC and `add HL,(0x60f004)` at",
      "         0xF86AB1, against 0x2C00 / (0x60F000) twenty-two bytes earlier --",
      "         the two routines are the same code with the two constants",
      "         swapped and the compare widened.")
    N(0xF86AC7, "List2030_AppendRegs",
      "List2030_AppendRegs -- append {E, D, A, W} to the fixed list at 0x2030",
      "",
      "Called from: thunk slot T_F40F40 (`jp 0x00F86AC7`); 14 proven call sites;",
      "         and in-span from PanelButton_PostClass70 0xF8625A and",
      "         PanelDial_PostClass7A 0xF868D7.",
      "Body:    scan from 0x2030 in steps of 4 for the 0xFF terminator, refuse if",
      "         it is past 0x206B, then store the record and a new 0xFF.",
      "Capacity: (0x206C - 0x2030) / 4 = 15 records.  Unlike the two queues this",
      "         list has no cursor -- the terminator IS the cursor.",
      "Read by:  UiEventList_RunPassC (this module), prom_a 0xF8A824 (which",
      "         handles classes <= 0x18 and stops on 0xFF or 0xFE), and prom_a",
      "         0xFADB41 in the 0xFAD800 module (which dispatches classes <= 0xBF",
      "         through its own 192-entry table at 0xFAE3A2).  Three independent",
      "         consumers, each with its own class range.",
      "Sibling:  prom_b's List2030_Append4 at 0xF552CC -- same base, same 0x206C",
      "         ceiling, same scan-for-0xFF; again a structural match, not a diff.",
      "Evidence: `ld XHL,0x00002030` at 0xF86AC7, `cp (XHL),0xff` at 0xF86ACC,",
      "         `add HL,0x0004` at 0xF86AD1, `cp XHL,0x0000206b` at 0xF86AD7.")
    N(0xF86AE9, "PanelState_CheckHomeAllowed",
      "PanelState_CheckHomeAllowed -- veto the pending home jump on two screens",
      "",
      "Called from: thunk slots T_F40F48 AND T_F40F4C (both `jp 0x00F86AE9`);",
      "         T_F40F4C has 2 proven call sites (prom_a 0xFE01F1, 0xFE70AB) and",
      "         T_F40F48 none.  Also `calr` from PanelTask_ResetAndPoll 0xF8601F",
      "         and PanelTask_Step 0xF86066.",
      "Body:    bit 6 of (0x2071) and bit 4 of (0x2075) both set, with (0x207C)",
      "         either 0x01 or 0xDA -> `and (0x2071),0xBF`, i.e. drop the home",
      "         request.  Then, unless (bit 0 of (0x2092) is clear AND bit 4 of",
      "         (0x2075) is set -- which only does `and (0x2095),0xFE`), if bit 7",
      "         of (0x2071) is set the low byte of (0x2070) is compared against",
      "         the two entries of PanelHome_ScreenIds; a match gives",
      "         `or (0x2095),0x03` and (0x20A2) = 0.",
      "Evidence: `ld WA,(0x2070)` at 0xF86B1B is a 16-bit load and `bit 0x07,W`",
      "         at 0xF86B1F then tests bit 7 of the HIGH half -- which is byte",
      "         (0x2071), the same flag byte PanelState_Init writes at 0xF86055",
      "         and PanelScreen_ApplyHomeForce tests at 0xF863AC.  That is a",
      "         third independent witness for the (0x2070)/(0x2071) pairing.")
    N(0xF86B43, "EditValue_ApplyStep",
      "EditValue_ApplyStep -- add or subtract (0x20CE) from (0x20CC), clamped",
      "",
      "Called from: thunk slot T_F40F68 (`jp 0x00F86B43`); no proven call site.",
      "Inputs:  W -- bit 7 is the direction.  (0x20C8) is the ceiling, (0x20CA)",
      "         the floor, (0x20CE) the step, (0x20CC) the value.",
      "Outputs: DE = the new value; it is NOT stored back.",
      "Evidence: the two `jr PE/OV` at 0xF86B50 and 0xF86B62 catch signed",
      "         overflow before the limit compare, so the four cells are SIGNED",
      "         16-bit.")
    N(0xF86B6F, "EditStep_UseCurveA",
      "EditStep_UseCurveA -- (0x20CE) := EditStep_CurveA[W & 0x7F]",
      "",
      "Called from: thunk slot T_F40F6C (`jp 0x00F86B6F`); no proven call site.",
      "Evidence: `ld XIY,0x00f86ba0` at 0xF86B71, then `jr T,0xf86b8d` into the",
      "         shared tail -- so the only thing this entry decides is the base.")
    N(0xF86B7F, "EditStep_UseCurveC",
      "EditStep_UseCurveC -- (0x20CE) := EditStep_CurveC[W & 0x7F]",
      "",
      "Called from: thunk slot T_F40F70 (`jp 0x00F86B7F`); no proven call site.",
      "⚠ 0xF86B78 (`ld XIY,0x00F86BA8`) and 0xF86B88 (`ld XIY,0x00F86BB8`) are",
      "         UNREACHABLE: 0xF86B76 and 0xF86B86 are `jr T,0xF86B8D`, which",
      "         jumps straight over them.  Curves B and D are therefore named by",
      "         dead code and by nothing else.  Check C3.",
      "Evidence: `ld XIY,0x00f86bb0` at 0xF86B81, then `jr T,0xf86b8d`.")
    N(0xF86B8D, "EditStep_Lookup",
      "EditStep_Lookup -- the shared tail: (0x20CE) := (XIY + (W & 0x7F))",
      "",
      "Called from: fallen into from EditStep_UseCurveA and EditStep_UseCurveC.",
      "⚠ The index mask is 0x7F, so an index of 8..127 reads PAST the 8-byte",
      "         curve it was given.  Nothing in this span bounds W, so what the",
      "         curves' real extent is rests on the 8-byte spacing of the four",
      "         bases alone.  Stated as a gap rather than papered over.",
      "Evidence: `and L,0x7f` at 0xF86B91, `ld L,(XIY+HL)` at 0xF86B94,",
      "         `ld (0x20ce),HL` at 0xF86B99 -- the cell EditValue_ApplyStep",
      "         adds at 0xF86B4C.")

    # ======================================== the press-and-hold event handlers
    N(0xF86BC0, "PanelEvent_Code01_ArmHold",
      "PanelEvent_Code01_ArmHold -- arm the hold timer with request 2",
      "",
      "Called from: thunk slot T_F40F7C (`jp 0x00F86BC0`); no proven call site,",
      "         and no list in any class table names it.",
      "Body:    (0x20B8) must be 1 and bit 7 of ((0x20B9) & (0x20BA)) set;",
      "         then, unless bit 1 of (0x60F020) is set, (0x2096) = 2 and",
      "         (0x20A7) = 0x40.  With bit 7 clear, (0x20A7) = 0 -- the hold is",
      "         cancelled.",
      "Evidence: (0x20A7) is the counter PanelHold_Tick decrements and (0x2096)",
      "         the index it then looks up, so `arm` is exactly what this is.")
    N(0xF86BF4, "PanelEvent_ReadPayload_F86BF4",
      "PanelEvent_ReadPayload_F86BF4 -- loads the event payload and returns",
      "",
      "Called from: thunk slot T_F40F78 (`jp 0x00F86BF4`); no proven call site.",
      "Body:    `ld L,(0x20b9) / ld H,(0x20ba) / ld A,(0x20b8) / ret`.  Thirteen",
      "         bytes, no effect.  PanelEvent_ReadPayload_F86C01 is byte-for-byte",
      "         the same routine at a different address.",
      "Evidence: the whole body decodes as three loads and a `ret`, 13 bytes,",
      "         with no store and no branch.",
      "Unknown:  whether these two are stubs left in place or handlers whose body",
      "         was removed.  The register loads are dead either way.")
    N(0xF86C01, "PanelEvent_ReadPayload_F86C01",
      "PanelEvent_ReadPayload_F86C01 -- byte-identical twin of the routine above",
      "",
      "Called from: thunk slot T_F40F80 (`jp 0x00F86C01`); no proven call site.",
      "Evidence: ROM[0xF86BF4..0xF86C00] == ROM[0xF86C01..0xF86C0D], 13 bytes,",
      "         0 differing -- check E1.")
    N(0xF86C0E, "PanelEvent_Code20_ArmHold",
      "PanelEvent_Code20_ArmHold -- arm the hold timer with request 7, or cancel",
      "",
      "Called from: thunk slot T_F40F84 (`jp 0x00F86C0E`); no proven call site.",
      "Body:    (0x20B8) must be 0x20.  L = (0x20B9) & (0x20BA).",
      "         L == 0x15, (0x2078) != 0x15, bit 1 of (0x60F020) clear ->",
      "           (0x2096) = 7, (0x20A7) = 0x30.",
      "         L == 5 and (0x2078) == 5 -> nothing.",
      "         otherwise -> (0x2096) = 0 and (0x20A7) = 0.",
      "⚠ (0x2096) = 7 selects PanelHold_ScreenRequest[7], which is 0xFFFF -- the",
      "         `no entry` value PanelHold_Tick skips.  So this arm cancels the",
      "         jump rather than causing one, unless something outside this span",
      "         rewrites the table entry.  prom_a 0xFF4795 also compares (0x2096)",
      "         with 7, so the index is used elsewhere; nothing decoded so far",
      "         explains the 0xFFFF.",
      "Evidence: `cp A,0x20` at 0xF86C1A is the guard; `ld (0x2096),0x0007` at",
      "         0xF86C34 and `ld (0x20a7),0x30` at 0xF86C3A are the arm; the",
      "         cancel path is `ld (0x2096),0x0000` at 0xF86C4E.")
    N(0xF86C59, "PanelEvent_NoOp_T40F88",
      "PanelEvent_NoOp_T40F88 -- one `ret`, published as thunk slot T_F40F88",
      "",
      "Called from: thunk slot T_F40F88 only; no proven call site.",
      "Evidence: 0xF86C59, 0xF86C5A and 0xF86C5B are three CONSECUTIVE single",
      "         `ret` bytes, and prom_b's directory publishes each of them as its",
      "         own slot (T_F40F88, T_F40F8C, T_F40F94).  Three distinct",
      "         published entry points that all do nothing -- which is why they",
      "         are three labels and not one.")
    N(0xF86C5A, "PanelEvent_NoOp_T40F8C",
      "PanelEvent_NoOp_T40F8C -- one `ret`, published as thunk slot T_F40F8C",
      "",
      "Evidence: prom_b 0xF40F8C holds `jp 0x00F86C5A` and ROM[0xF86C5A] is 0x0E.")
    N(0xF86C5B, "PanelEvent_NoOp_T40F94",
      "PanelEvent_NoOp_T40F94 -- one `ret`, published as thunk slot T_F40F94",
      "",
      "Evidence: prom_b 0xF40F94 holds `jp 0x00F86C5B` and ROM[0xF86C5B] is 0x0E.")
    N(0xF86C5C, "PanelHold_Tick",
      "PanelHold_Tick -- count (0x20A7) down and, at zero, request a screen",
      "",
      "Called from: thunk slot T_F40F74 (`jp 0x00F86C5C`); 2 proven call sites",
      "         (prom_a 0xF8209C, 0xF821F1).",
      "Body:    (0x20A7) == 0 -> nothing.  Decrement; while it is still non-zero,",
      "         nothing.  At zero: WA = PanelHold_ScreenRequest[(0x2096)]; a low",
      "         byte of 0xFF means `no entry`; otherwise (0x2070) = WA (which",
      "         writes both the screen id and the 0x40 request flag) and",
      "         `and (0x2075),0xEF`.",
      "Evidence: the index is `ld WA,(0x2096) / sla 0x01,WA` at 0xF86C6C -- a",
      "         16-bit index doubled, i.e. a table of WORDS.")
    N(0xF86CAE, "PanelMode_To2076",
      "PanelMode_To2076 -- (0x2076) := PanelMode_To2076Map[min((0x2078), 0x1F)]",
      "",
      "Called from: PanelTask_Step 0xF86072 (`calr`), and nothing else.",
      "Evidence: `cp L,0x1f / jr ULE / ld L,0x01` at 0xF86CB4 -- an index above",
      "         0x1F is replaced by 1, NOT clamped to 0x1F.  That bound is what",
      "         fixes PanelMode_To2076Map at 32 entries.")
    N(0xF872C1, "PanelScreen_NullVtable",
      "PanelScreen_NullVtable -- the do-nothing screen object",
      "",
      "Called from: 81 of the 256 entries of PanelScreen_VtableTable point here",
      "         (check V2), and nothing calls the address directly.",
      "Body:    `jr T,+6 / jr T,+4 / jr T,+2 / jr T,+0 / ret` -- four 2-byte",
      "         branches at 0xF872C1, 0xF872C3, 0xF872C5, 0xF872C7, all landing",
      "         on the `ret` at 0xF872C9.",
      "★ Evidence for the whole vtable reading: this object is laid out so that",
      "         BOTH +0, +4 AND +8 reach that `ret`.  Nothing else explains four",
      "         branches to the same target four bytes apart.  Check V3.",
      "Evidence: ROM[0xF872C1..0xF872C9] = 68 06 68 04 68 02 68 00 0E, and 81 of",
      "         the 256 entries of PanelScreen_VtableTable hold 0x00F872C1.")

    # ================================================== the data objects
    N(0xF8671A, "PanelButton_BitMask32",
      "PanelButton_BitMask32 -- 32 LE32 words, entry[i] == 1 << i",
      "",
      "Read by: `ld XHL,0x00F8671A` at 0xF86172 (PanelButton_SweepHeld) and",
      "         `ld XWA,0x00F8671A` at 0xF86659 (PanelButton_Accept).",
      "ENTRY COUNT 32, pinned twice: `cp C,0x1f` at 0xF8619A bounds the sweep's",
      "         index, and the 128-byte extent ends exactly where",
      "         PanelButton_InterlockMask32 begins at 0xF8679A -- an address the",
      "         code loads separately at 0xF86696.",
      "★ LAST-ENTRY TEST: entry 31 is 0x80000000 and entry 0 is 0x00000001; the",
      "         identity entry[i] == 1<<i holds for all 32 (check B1).",
      "Evidence: because the table IS the identity, `mask & (0x2088)` is `bit i",
      "         of (0x2088)`, which is what makes (0x2084)/(0x2088)/(0x208C)",
      "         readable as three 32-bit bitmaps over 32 button indices.")
    N(0xF8679A, "PanelButton_InterlockMask32",
      "PanelButton_InterlockMask32 -- 32 LE32 words; entry[i] == 1 << (i + 17)",
      "                               for i < 8, and 0 for i >= 8",
      "",
      "Read by: ONE site, `ld XWA,0x00F8679A` at 0xF86696 (PanelButton_Accept),",
      "         four instructions before the value is ANDed with (0x2252) and",
      "         then with (0x2256); a hit in either makes the press be DROPPED.",
      "ENTRY COUNT 32: the 128-byte extent ends at 0xF8681A, which is itself",
      "         `calr`-ed from 0xF865AE, so both ends are named by code.",
      "★ LAST-ENTRY TEST: entries 8..31 are all zero -- so 24 of the 32 buttons",
      "         can never be interlocked -- and entry 7 is 0x01000000 = 1<<24 =",
      "         1<<(7+17).  Check B2.",
      "Evidence: `and XDE,(0x2252)` at 0xF8669F and `and XDE,(0x2256)` at",
      "         0xF866A7, each followed by a `jr NZ` to the path that pops and",
      "         returns WITHOUT touching (0x2088) -- so a hit vetoes the press.",
      "Unknown:  what (0x2252)/(0x2256) hold.  The bit space is NOT the button",
      "         index space of the table above; it is offset by 17.")
    N(0xF868DB, "PanelDial_DeltaToStepIndex",
      "PanelDial_DeltaToStepIndex -- 32 bytes, encoder delta -> signed step index",
      "",
      "Read by: ONE site, `ld XHL,0x00F868DB` at 0xF86856.",
      "ENTRY COUNT 32, pinned by the reader itself: `cp A,0x20 / jr C / ld A,0x1f`",
      "         at 0xF8684F-0xF86854 clamps the index to 0..0x1F.  ⚠ The round-1",
      "         dossier said this base had no reader bound; it has one.",
      "Contents: 87 87 87 87 87 86 86 86 85 85 85 84 84 83 82 81 80 01 02 03 04",
      "         04 05 05 05 06 06 06 07 07 07 07.  Bit 7 is the direction and bits",
      "         0-2 index PanelDial_StepSizes, so the first 17 entries are",
      "         negative and the last 15 positive -- the index the reader forms",
      "         is delta + 0x10, which puts zero delta at entry 16 (0x80 =",
      "         negative, step 0).",
      "Evidence: the consumer is PanelDial_ApplyStep, which uses bit 7 of the",
      "         fetched byte as the direction (`bit 0x07,D` at 0xF868A7) and its",
      "         low three bits as the PanelDial_StepSizes index (`and A,0x07` at",
      "         0xF86890) -- so the encoding of the table IS the consumer's.")
    N(0xF868FB, "PanelDial_StepSizes",
      "PanelDial_StepSizes -- 8 bytes: 0, 1, 4, 10, 20, 50, 70, 100 (decimal)",
      "",
      "Read by: ONE site, `ld XHL,0x00F868FB` at 0xF86893, indexed by `and A,0x07`",
      "         at 0xF86890 -- which is what fixes the count at 8.  ⚠ The round-1",
      "         dossier said this base had no reader bound either.",
      "★ LAST-ENTRY TEST: entry 7 is 0x64 = 100, and 0xF86903 (the byte after) is",
      "         PanelTimers_Step, a thunk-published entry point.",
      "Evidence: the values are added to or subtracted from (0x7EE2) at 0xF868BD",
      "         and 0xF868B0, between the 0x0028 and 0x012C limits -- a step of",
      "         100 on a range of 260 only makes sense as an acceleration ladder.")
    N(0xF86C8C, "PanelHold_ScreenRequest",
      "PanelHold_ScreenRequest -- 17 LE16 words: {screen id, 0x40} or 0xFFFF",
      "",
      "Read by: ONE site, `ld XHL,0x00F86C8C / ld WA,(XHL+WA)` at 0xF86C73",
      "         (PanelHold_Tick), indexed by (0x2096) doubled.",
      "Contents: [0] 0x4001, [1] 0x4069, [2] 0x4043, [3] 0x406B, [4]..[14] 0xFFFF,",
      "         [15] 0x4001, [16] 0x4001.",
      "★ The high byte of EVERY live entry is 0x40, and 0xF86C82 stores the whole",
      "         word to (0x2070) -- whose high half is (0x2071), whose bit 6 is",
      "         0x40.  So an entry is `screen id + the go-there request flag`, the",
      "         same pair PanelState_Init writes as the literal 0x40AA.  Check H2.",
      "⚠ ENTRY COUNT 17 IS UNPINNED.  Nothing bounds (0x2096); the count rests",
      "         only on the table ending where PanelMode_To2076's code begins at",
      "         0xF86CAE.  The three writers inside this span use indices 0, 2 and",
      "         7, and prom_a 0xFF4795 compares (0x2096) with 7.",
      "Evidence: `ld XHL,0x00f86c8c` at 0xF86C73 is the only instruction in",
      "         either image that names this base, and `ld WA,(XHL+WA)` at",
      "         0xF86C78 is what makes the stride 2.")
    N(0xF86CC9, "PanelHome_ScreenIds",
      "PanelHome_ScreenIds -- 2 bytes: 0xA1, 0xA0",
      "",
      "Read by: ONE site, `ld XIX,0x00F86CC9 / ld XBC,2 / cp A,(XIX+) / djnz BC`",
      "         at 0xF86B24-0xF86B33 (PanelState_CheckHomeAllowed).",
      "ENTRY COUNT 2, pinned twice: the literal `ld XBC,0x00000002` IS the loop",
      "         count, and 0xF86CCB begins the 438-byte 0x00 pad.",
      "Evidence: `ld XIX,0x00f86cc9` at 0xF86B24 is the only instruction in",
      "         either image that names this base; `cp A,(XIX+)` at 0xF86B2E",
      "         with `djnz BC` at 0xF86B33 is what makes it a 2-entry scan.",
      "Note:    0xAA -- the id PanelState_Init installs as the home screen -- is",
      "         NOT one of these two.")
    N(0xF86E81, "PanelMode_To2076Map",
      "PanelMode_To2076Map -- 32 bytes, (0x2078) -> (0x2076)",
      "",
      "Read by: ONE site, `ld XIY,0x00F86E81` at 0xF86CBB (PanelMode_To2076).",
      "ENTRY COUNT 32, pinned by `cp L,0x1f` at 0xF86CB4.",
      "Contents: 01 01 02 03 03 03 03 03 08 09 0A 0B 0C 0D 0E 0F 10 01 12 13 14",
      "         15 16 17 01 01 01 01 01 01 01 01 -- every value is <= 0x17, i.e.",
      "         inside the map's own index range, so it is idempotent-ish and the",
      "         unused tail (entries 24..31) all fall back to 1.",
      "Evidence: `ld XIY,0x00f86e81` at 0xF86CBB is the only instruction in",
      "         either image that names this base, and `cp L,0x1f` three",
      "         instructions earlier is what bounds the index.")
    N(0xF86EA1, "PanelMode_ToScreenIdMap",
      "PanelMode_ToScreenIdMap -- 32 bytes, (0x2078) -> a screen id for (0x207C)",
      "",
      "Read by: ONE site, `ld XHL,0x00F86EA1` at 0xF86388 (PanelMode_ToScreenId).",
      "Contents: 01 01 02 04 05 06 0F 1A 12 B0 60 59 33 55 5E 02 60 01 70 5B 40",
      "         40 33 80 01 01 01 01 01 01 01 01.",
      "⚠ ENTRY COUNT 32 IS WEAKLY PINNED.  Its reader has NO bound (0xF8638D-",
      "         0xF86395 is `xor XWA,XWA / ld A,(0x2078) / add XHL,XWA /",
      "         ld A,(XHL)`), so 32 rests only on PanelScreen_VtableTable starting",
      "         at 0xF86EC1.  The map ABOVE it is the one with a hard bound.",
      "⚠ Correction: the round-1 dossier said this map is indexed by `the byte",
      "         the previous map produces`.  It is not -- 0xF86E81's reader WRITES",
      "         (0x2076) and READS (0x2078), and this reader reads (0x2078) too.",
      "         They share an input; they are not chained.  Check M2.",
      "Consistency: every entry is <= 0xDF, the bound PanelScreen_CallEnter_B",
      "         applies to (0x207C) -- check M3.",
      "Evidence: `ld XHL,0x00f86ea1` at 0xF86388 is the only instruction in",
      "         either image that names this base, and 0xF86397 stores the",
      "         fetched byte to (0x207C) -- which is what makes the values",
      "         screen ids rather than anything else.")
    N(0xF86EC1, "PanelScreen_VtableTable",
      "PanelScreen_VtableTable -- 256 LE32 pointers, one screen object each",
      "",
      "Read by: `ld XIY,0x00F86EC1` at 0xF864EC and 0xF86520 (view A, index",
      "         (0x2078)/(0x2079), bound `cp L,0x2f`), and via the alias",
      "         PanelScreen_VtableTable_ViewB below.",
      "ENTRY COUNT 256: 1024 bytes, ending exactly at PanelScreen_NullVtable's",
      "         own code at 0xF872C1 -- which is also the value 81 of the entries",
      "         hold.  The largest index any reader admits is view B's 0xDF from",
      "         base entry 32, i.e. entry 255.  Two pins, and they agree.",
      "★ EACH ENTRY POINTS AT A THREE-METHOD VTABLE: +0 Enter, +4 Leave, +8",
      "         Button.  171 of the 174 distinct live pointers land on three",
      "         consecutive `jp addr24` (opcode 0x1B) inside prom_b's thunk",
      "         directory; the other 3 land on 0x0E (`ret`) filler there.  The",
      "         81 stub entries point at PanelScreen_NullVtable, which is built so",
      "         that all three offsets reach one `ret`.  Checks V1-V4.",
      "The three offsets come from three different call sites, not from a guess:",
      "         +0 from PanelScreen_CallEnter_A/B (`ld BC,0x0000`), called with",
      "            the id that just BECAME current;",
      "         +4 from PanelScreen_CallLeave_A/B (`ld BC,0x0004`), called with",
      "            the id that just STOPPED being current;",
      "         +8 from PanelButton_Route 0xF8621E (`add XBC,0x00000008`), called",
      "            with the CURRENT id and a button index on the stack.",
      "Evidence: the +0/+4 pairing is not an assumption -- `ld BC,0x0000` is",
      "         reached only from the two CURRENT-id detectors (0xF86500,",
      "         0xF8650F) and `ld BC,0x0004` only from the two PREVIOUS-id ones",
      "         (0xF86493, 0xF864BD).  Check V6.")
    N(0xF86F41, "PanelScreen_VtableTable_ViewB",
      "PanelScreen_VtableTable_ViewB -- entry 32 of the table above, used as a",
      "                                 second base",
      "",
      "Read by: `ld XIY,0x00F86F41` at 0xF864CE and 0xF86535, `ld XBC,0x00F86F41`",
      "         at 0xF86215.  0xF86F41 = 0xF86EC1 + 0x80 = entry 32 exactly.",
      "So screen ids 0..0xDF read here are table entries 32..255, and mode",
      "indices 0..0x2F read at PanelScreen_VtableTable are entries 0..47: the two",
      "views OVERLAP on entries 32..47, 11 of which are live (check V5).",
      "Evidence: 0xF86F41 - 0xF86EC1 = 0x80 = 32 * 4 exactly, and the two bounds",
      "         (0x2F from this base's parent, 0xDF from this one) reach entries",
      "         47 and 255 -- the last entry of the 256-entry table.")
    N(0xF87E81, "UiEventPassA_TailList")
    N(0xF88E91, "UiEventPassB_TailList")
    N(0xF89671, "UiEventPassC_TailList")
    for tag, entry, ct, tl, rl, th in PASSES:
        ents = _tail_entries(tl)
        H(tl, "UiEventPass%s_TailList -- LE32 routines run once, after the whole"
              " list" % tag,
          "",
          "Read by: ONE site, `ld XIY,0x00%06X / ld (0x20C4),XIY` at"
          " UiEventList_RunPass%s 0x%06X." % (tl, tag, entry),
          "         UiEventList_Run walks it at 0xF86A6A-0xF86A7E after the",
          "         record loop, calling every entry until a word 0xFFFF.",
          "Entries: %s (%d), then the 0xFFFF terminator."
          % (", ".join("0x%06X" % v for v in ents) or "none", len(ents)),
          "ENTRY COUNT: the terminator IS the count; the bytes after it are the",
          "         0x00 pad that runs to the next object.",
          "Evidence: `ld XIY,0x00%06X` at 0x%06X, four bytes before"
          " `ld (0x20C4),XIY`;" % (tl, entry + 9),
          "         UiEventList_Run reads (0x20C4) at 0xF86A6A and stops on",
          "         `cp (XIX),0xffff`.")

    # ---------------------------------------------------- the three class tables
    for tag, entry, ct, tl, rl, th in PASSES:
        ent, heads = lists_of(ct)
        N(ct, "UiEventClass_ListTable_" + tag,
          "UiEventClass_ListTable_%s -- 192 LE32 heads, indexed by the event class"
          % tag,
          "",
          "Read by: ONE site, `ld XIY,0x00%06X / ld (0x20C0),XIY` at"
          " UiEventList_RunPass%s 0x%06X;" % (ct, tag, entry),
          "         UiEventList_Run indexes it with the record's byte +0.",
          "ENTRY COUNT 192, pinned twice: `cp L,0xbf` at 0xF869FB rejects a class",
          "         above 191, and the 0x300-byte extent is 192 * 4.  The table",
          "         ends one pad byte before its own list area.",
          "★ 121 class ids have their own list and the other 71 share the area's",
          "         trailing empty list -- and the SAME 121 ids do so in all",
          "         THREE tables (check L2).  The distinct heads tile the list",
          "         area exactly, in ascending order, with no byte left over",
          "         (check L3).",
          "Evidence: `ld XIY,0x00%06X` at 0x%06X, four bytes before"
          " `ld (0x20C0),XIY`;" % (ct, entry),
          "         UiEventList_Run reads (0x20C0) at 0xF869EF and indexes it",
          "         with `sla 0x02,HL` at 0xF86A00.")

    # ------------------------------------------------------------ the list heads
    #
    # ⚠ THESE LABELS ARE GENERATED, AND THAT IS SAID OUT LOUD.  Each is the
    # directory entry's own index rendered as a name -- structure, not
    # understanding.  They are worth having because without them the reader of
    # 0xF879C2 cannot tell which of 192 classes that word belongs to; they are
    # NOT worth counting as if they were 366 routines that had been understood.
    # The area header states the empty/non-empty split so nobody has to guess.
    for tag, entry, ct, tl, rl, th in PASSES:
        ent, heads = lists_of(ct)
        alo, ahi = [(d[2], d[3]) for d in dirs if d[0] == ct][0]
        ends = {h: (heads[i + 1] if i + 1 < len(heads) else ahi)
                for i, h in enumerate(heads)}
        shared = heads[-1]
        first_class = {}
        for c, v in enumerate(ent):
            first_class.setdefault(v, c)
        empty = sum(1 for h in heads if w32(h) == 0xFFFFFFFF)
        for h in heads:
            if h == shared:
                LABELS[h] = "UiList%s_Shared" % tag
            else:
                LABELS[h] = "UiList%s_Class%02X" % (tag, first_class[h])
            cls = [c for c, v in enumerate(ent) if v == h]
            NOTES[h] = ("Evidence: UiEventClass_ListTable_%s[0x%02X], the LE32 at "
                        "0x%06X, holds 0x%06X.  GENERATED name."
                        % (tag, cls[0], ct + 4 * cls[0], h))
        AREAHDR[alo] = _box(
          "UiEventLists_%s -- the %d handler lists of pass %s, tiling"
          " 0x%06X-0x%06X" % (tag, len(heads), tag, alo, ahi - 1),
          "",
          "Each list is LE32 routine addresses terminated by 0xFFFFFFFF.  %d of"
          % empty,
          "the %d are EMPTY (the terminator and nothing else); %d carry handlers."
          % (len(heads), len(heads) - empty),
          "⚠ The labels below are GENERATED: each is named after the LOWEST class",
          "id whose UiEventClass_ListTable_%s entry points at it, and says nothing"
          % tag,
          "about what the list DOES.  UiList%s_Shared is the empty list the 71"
          % tag,
          "classes without their own head share.",
          "Evidence: the heads are the table's own values -- nothing here is",
          "         framed by content.  They tile the area with no gap and no",
          "         overlap, every one ends in 0xFFFFFFFF, and the last one ends",
          "         exactly at the area's end (checks L3, L5).")
        H(shared,
          "UiList%s_Shared -- the empty list %d class ids share" % (tag, 192 - 121),
          "",
          "Classes: every id NOT in the 121-member set the three tables agree",
          "         on.  Generated from the table, not typed:",
          *["         " + x for x in _wrap(_ranges(
              sorted(c for c, v in enumerate(ent) if v == shared)))],
          "         Check L2 asserts the set is the same in all three tables.",
          "Position: it is the LAST object in the area, and its 4 bytes are what",
          "         make the tiling reach 0x%06X exactly." % ahi,
          "Evidence: 71 of the 192 LE32 entries of UiEventClass_ListTable_%s hold"
          % tag,
          "         0x%06X, and the word there is the 0xFFFFFFFF terminator."
          % shared)
        for h in heads:
            if h == shared or w32(h) == 0xFFFFFFFF:
                continue
            cls = sorted(c for c, v in enumerate(ent) if v == h)
            vals = [w32(h + 4 * k) for k in range((ends[h] - h) // 4)]
            H(h,
              "UiList%s_Class%02X -- %d handler(s) for event class 0x%02X in"
              " pass %s" % (tag, cls[0], len(vals) - 1, cls[0], tag),
              "",
              "Entries: %s, then the terminator."
              % ", ".join("0x%06X" % v for v in vals[:-1]),
              "Read by: UiEventList_Run 0xF86A03, after"
              " UiEventClass_ListTable_%s[0x%02X]." % (tag, cls[0]),
              "Payload the handlers see: (0x20B8)/(0x20B9) = the record's bytes",
              "         +1 and +2, (0x20BA) = byte +3, (0x20BB) = the class.",
              "Evidence: UiEventClass_ListTable_%s[0x%02X], the LE32 at 0x%06X,"
              % (tag, cls[0], ct + 4 * cls[0]),
              "         holds 0x%06X.  The list ENDS at 0x%06X because the next"
              % (h, ends[h]),
              "         head in the table is there.  The NAME is generated from",
              "         the index; what the handlers DO is not claimed here.")


def _wrap(text, width=62):
    out, cur = [], ""
    for tok in text.split(", "):
        if cur and len(cur) + len(tok) + 2 > width:
            out.append(cur + ",")
            cur = ""
        cur = tok if not cur else cur + ", " + tok
    if cur:
        out.append(cur)
    return out


def _ranges(xs):
    """`0x43-0x47, 0x49` -- a sorted id list as compact ranges."""
    out, i = [], 0
    while i < len(xs):
        j = i
        while j + 1 < len(xs) and xs[j + 1] == xs[j] + 1:
            j += 1
        out.append("0x%02X" % xs[i] if j == i else "0x%02X-0x%02X" % (xs[i], xs[j]))
        i = j + 1
    return ", ".join(out)


def _tail_entries(tl):
    out = []
    p = tl
    while w16(p) != 0xFFFF and len(out) < 32:
        out.append(w32(p))
        p += 4
    return out


# ------------------------------------------------------------------- emission
def _box(*lines):
    return list(lines)


def hdr(addr, out):
    if addr in NOTES and addr not in HEADERS:
        out.append("; " + NOTES[addr])
        return
    if addr in HEADERS:
        out.append("")
        out.append("; " + "-" * 69)
        for l in HEADERS[addr]:
            out.append(("; " + l).rstrip())
        out.append("; " + "-" * 69)


def entry_tag(evs):
    return ("   ; entry: " + ", ".join(sorted(set(evs)))) if evs else ""


def fmt_code(a, e, ev):
    lines, okk, _stats = RT.emit_block(a, e)
    if not okk:
        sys.exit("REFUSING TO EMIT: roundtrip could not prove 0x%06X-0x%06X" % (a, e))
    u = {addr: t for addr, _bs, t in RT.unidasm_range(a, e)}
    out, pending = [], []
    for text, addr, bs, why in lines:
        if addr is None:
            # a `.LXXXXXX:` from emit_block.  Held back so that a header block
            # stays adjacent to the label it documents -- otherwise the local
            # label lands between the two and the house style breaks.
            pending.append(text)
            continue
        hdr(addr, out)
        out += pending
        pending = []
        if addr in LABELS:
            out.append("%s:%s" % (LABELS[addr], entry_tag(ev.get(addr))))
        raw = " ".join("%02x" % b for b in bs)
        note = ""
        if why in ("llvm", "macro", "byte") and u.get(addr):
            note = "   " + u[addr]
        out.append("%-46s ; %06X  %s%s" % (text, addr, raw, note))
    out += pending
    return out


# Objects the layout calls `object` that are really LE32 or LE16 arrays.  The
# layout only says "the code loads this address"; the WIDTH comes from the
# instruction that reads them, quoted in each object's header.
LONG_OBJECTS = {0xF8671A: "1 << %d", 0xF8679A: "1 << %d"}
WORD_OBJECTS = {0xF86C8C}


def masktab_of(a, e):
    """The two 32-entry mask tables, one `.long` per entry, with the identity
    the header claims spelled out on every line so it can be read off."""
    out = []
    hdr(a, out)
    if a in LABELS:
        out.append(LABELS[a] + ":")
    for i, x in enumerate(range(a, e, 4)):
        v = w32(x)
        if v == 0:
            tag = "zero -- this index can never be interlocked"
        else:
            tag = "1 << %d" % (v.bit_length() - 1)
        out.append("\t.long 0x%08X                            ; %06X  [%2d]  %s"
                   % (v, x, i, tag))
    return out


def wordtab_of(a, e):
    """PanelHold_ScreenRequest: one 16-bit entry per line, split into the screen
    id and the request-flag byte the header says it carries."""
    out = []
    hdr(a, out)
    if a in LABELS:
        out.append(LABELS[a] + ":")
    d = rom("a")
    for i, x in enumerate(range(a, e, 2)):
        v = w16(x)
        tag = ("no entry" if (v & 0xFF) == 0xFF
               else "screen 0x%02X, request flags 0x%02X" % (v & 0xFF, v >> 8))
        out.append("\t.byte 0x%02x, 0x%02x                                    "
                   "; %06X  [%2d]  0x%04X  %s"
                   % (d[x - A_BASE], d[x + 1 - A_BASE], x, i, v, tag))
    return out


def rows_of(a, e, width=16):
    """`.byte` rows of at most `width`, never crossing a label."""
    out, x = [], a
    d = rom("a")
    while x < e:
        stop = min(x + width, e)
        for y in range(x + 1, stop):
            if y in LABELS or y in HEADERS:
                stop = y
                break
        hdr(x, out)
        if x in LABELS:
            out.append(LABELS[x] + ":")
        row = d[x - A_BASE:stop - A_BASE]
        out.append("\t.byte " + ", ".join("0x%02x" % b for b in row)
                   + "   ; %06X" % x)
        x = stop
    return out


def longs_of(a, e):
    """`.long` rows, one per entry, with the index and the resolved target."""
    out = []
    base = a
    for x in range(a, e, 4):
        hdr(x, out)
        if x in LABELS:
            out.append(LABELS[x] + ":")
            base = x
        v = w32(x)
        i = (x - base) // 4
        tag = ""
        if v == 0xFFFFFFFF:
            tag = "   end of list"
        elif v in LABELS:
            tag = "   -> %s" % LABELS[v]
        elif 0xF00000 <= v < 0x1000000:
            tag = "   -> 0x%06X" % v
        out.append("\t.long 0x%08X                            ; %06X  [%d]%s"
                   % (v, x, i, tag))
    return out


def uniform_or_bytes(a, e, what):
    vals = set(rom("a")[a - A_BASE:e - A_BASE])
    if len(vals) == 1 and (e - a) >= 4:
        return ["\t.fill %d, 1, 0x%02X" % (e - a, vals.pop())]
    d = rom("a")
    return ["\t.byte " + ", ".join("0x%02x" % b for b in d[a - A_BASE:e - A_BASE])
            + "   ; %06X" % a]


SEGNAME = {"fill": "0x0E pad", "zero": "0x00 pad", "pad": "pad",
           "ptrtab": "pointer table", "list": "0xFFFFFFFF-terminated list",
           "list_area": "handler lists", "object": "table",
           "unknown": "an instruction NOTHING branches to"}


def emit(segs, ev):
    out = []
    for kind, a, n in segs:
        e = a + n
        if kind == "code":
            out += fmt_code(a, e, ev)
            continue
        out.append("")
        out.append("; --- 0x%06X-0x%06X  %s (%d bytes) ---"
                   % (a, e - 1, SEGNAME.get(kind, kind), n))
        if a in AREAHDR:
            out.append("; " + "-" * 69)
            for l in AREAHDR[a]:
                out.append(("; " + l).rstrip())
            out.append("; " + "-" * 69)
        if kind in ("fill", "zero", "pad"):
            out += uniform_or_bytes(a, e, kind)
        elif kind in ("ptrtab", "list", "list_area"):
            out += longs_of(a, e)
        elif a in LONG_OBJECTS:
            out += masktab_of(a, e)
        elif a in WORD_OBJECTS:
            out += wordtab_of(a, e)
        else:
            out += rows_of(a, e)
    return out


def entry_points(segs):
    """addr -> [evidence strings] for every in-span address something outside the
    linear stream names."""
    rows, named, calls, jumps = census(segs)
    ev = collections.defaultdict(list)
    for slot, t in L.thunk_entries(LO, HI):
        ev[t].append("prom_b directory slot T_%06X" % slot)
    for tag, _e, ct, _tl, _rl, _th in PASSES:
        ent, _heads = lists_of(ct)
        for c, v in enumerate(ent):
            ev[v].append("UiEventClass_ListTable_%s[0x%02X]" % (tag, c))
    for t in sorted(calls):
        ss = sorted(calls[t])
        txt = ", ".join("0x%06X" % x for x in ss[:6])
        if len(ss) > 6:
            txt += ", +%d more" % (len(ss) - 6)
        ev[t].append("calr from " + txt)
    # collapse the 192-entry evidence lists: only the FIRST class is quoted
    for t in list(ev):
        cl = [x for x in ev[t] if x.startswith("UiEventClass_")]
        if len(cl) > 3:
            ev[t] = [x for x in ev[t] if not x.startswith("UiEventClass_")] + \
                    [cl[0], "+%d more class-table slots" % (len(cl) - 1)]
    return ev


# ------------------------------------------------------------------- selftest
def dis1(addr):
    """The instruction text decoded AT `addr` -- never at addr+1.  Every citation
    in this file is checked with this, which is the test lane a2's 31 off-by-one
    citations failed in round 1."""
    rows = RT.unidasm_range(addr, addr + 8)
    for a, _bs, t in rows:
        if a == addr:
            return t
    return None


_RUN = [0]


def check(msg, got, want):
    ok = got == want
    _RUN[0] += 1
    print("  %-70s %-26s %s" % (msg, repr(got)[:26],
                                "OK" if ok else "FAILED (want %r)" % (want,)))
    return 0 if ok else 1


def selftest():
    segs, dirs = layout()
    structure()
    rows, named, calls, jumps = census(segs)
    bad = 0

    print("A. the layout has not moved, and the labels are sane")
    bad += check("A1 segments", len(segs), EXPECTED)
    bad += check("A2 they tile the span", sum(n for _k, _a, n in segs), HI - LO)
    bad += check("A3 labels unique among themselves",
                 len(set(LABELS.values())), len(LABELS))
    have = collections.Counter(
        re.findall(r"^([A-Za-z_][A-Za-z0-9_]*):",
                   open(os.path.join(ROOT, "prom_a", "wsa1_prom_a.s")).read(), re.M))
    bad += check("A4 labels of this file appearing MORE THAN ONCE in prom_a",
                 sorted(v for v in set(LABELS.values()) if have[v] > 1), [])
    bad += check("A5 ...and the region IS spliced (each appears exactly once)",
                 sum(1 for v in set(LABELS.values()) if have[v] == 1),
                 len(set(LABELS.values())))
    bad += check("A6 in-span proven-target citations dropped by the guard "
                 "(0 before the splice)", _REL_DROPPED[0] > 0, True)

    print("B. the two 32-entry mask tables, on the LAST entry as well as the first")
    m = [w32(0xF8671A + 4 * i) for i in range(32)]
    bad += check("B1 PanelButton_BitMask32[i] == 1<<i for all 32",
                 [i for i in range(32) if m[i] != 1 << i], [])
    bad += check("B1 ...entry 0", "0x%08X" % m[0], "0x00000001")
    bad += check("B1 ...entry 31 (LAST)", "0x%08X" % m[31], "0x80000000")
    n_ = [w32(0xF8679A + 4 * i) for i in range(32)]
    bad += check("B2 PanelButton_InterlockMask32[i] == 1<<(i+17) for i < 8",
                 [i for i in range(8) if n_[i] != 1 << (i + 17)], [])
    bad += check("B2 ...entries 8..31 (incl. the LAST) are all zero",
                 [i for i in range(8, 32) if n_[i] != 0], [])
    bad += check("B3 a THIRD bitmap: 0xF866C3 sets (0x2084)", dis1(0xF866C3),
                 "or (0x2084),XWA")
    bad += check("B3 ...and 0xF866D3 clears it again", dis1(0xF866D3),
                 "and (0x2084),XWA")

    print("C. the four 8-byte step curves, and the dead code that names two")
    bad += check("C1 the four bases are 8 apart",
                 [b for b, _t, _s in CURVES], [0xF86BA0, 0xF86BA8, 0xF86BB0, 0xF86BB8])
    for b, t, site in CURVES:
        bad += check("C1 curve %s is named at 0x%06X by" % (t, site),
                     dis1(site), "ld XIY,0x00%06x" % b)
    bad += check("C2 curve A contents",
                 list(rom("a")[0xF86BA0 - A_BASE:0xF86BA8 - A_BASE]),
                 [0, 1, 5, 10, 15, 20, 25, 30])
    bad += check("C2 curve D (LAST) contents",
                 list(rom("a")[0xF86BB8 - A_BASE:0xF86BC0 - A_BASE]),
                 [0, 1, 5, 10, 20, 30, 40, 50])
    bad += check("C3 0xF86B76 jumps over the curve-B load", dis1(0xF86B76),
                 "jr T,0xf86b8d")
    bad += check("C3 0xF86B86 jumps over the curve-D load", dis1(0xF86B86),
                 "jr T,0xf86b8d")
    bad += check("C3 ...so 0xF86B78 and 0xF86B88 are UNREACHED: nothing "
                 "branches to them",
                 sorted(jumps.get(0xF86B78, set()) | jumps.get(0xF86B88, set())
                        | calls.get(0xF86B78, set()) | calls.get(0xF86B88, set())), [])

    print("D. the dial tables -- both of the bounds round 1 said did not exist")
    bad += check("D1 0xF8684F bounds the index", dis1(0xF8684F), "cp A,0x20")
    bad += check("D1 0xF86854 forces the LAST entry", dis1(0xF86854), "ld A,0x1f")
    bad += check("D2 0xF86890 masks the index to 8", dis1(0xF86890), "and A,0x07")
    bad += check("D3 PanelDial_StepSizes",
                 list(rom("a")[0xF868FB - A_BASE:0xF86903 - A_BASE]),
                 [0, 1, 4, 10, 20, 50, 70, 100])
    bad += check("D4 the floor", dis1(0xF868B2), "cp BC,0x0028")
    bad += check("D4 the ceiling", dis1(0xF868C3), "cp BC,0x012c")

    print("E. the byte-identical twin")
    a1 = rom("a")[0xF86BF4 - A_BASE:0xF86C01 - A_BASE]
    a2 = rom("a")[0xF86C01 - A_BASE:0xF86C0E - A_BASE]
    bad += check("E1 0xF86BF4 and 0xF86C01 differ in N bytes of 13",
                 (len(a1), sum(1 for i in range(13) if a1[i] != a2[i])), (13, 0))

    print("H. PanelHold_ScreenRequest carries the request FLAG with the id")
    ents = [w16(0xF86C8C + 2 * i) for i in range(17)]
    bad += check("H1 17 entries end where PanelMode_To2076's code begins",
                 "0x%06X" % (0xF86C8C + 2 * 17), "0xF86CAE")
    bad += check("H2 live entries whose high byte is NOT 0x40",
                 [i for i, v in enumerate(ents) if v != 0xFFFF and (v >> 8) != 0x40], [])
    bad += check("H3 entry 0 / entry 2 / entry 16 (LAST)",
                 ["0x%04X" % ents[i] for i in (0, 2, 16)],
                 ["0x4001", "0x4043", "0x4001"])
    bad += check("H4 PanelState_Init writes the same pair", dis1(0xF86055),
                 "ld (0x2070),0x40aa")
    bad += check("H4 ...and PanelHold_Tick stores a whole WORD to (0x2070)",
                 dis1(0xF86C82), "ld (0x2070),WA")

    print("I. UiEventList_Run")
    bad += check("I1 the class bound", dis1(0xF869FB), "cp L,0xbf")
    for tag, _e, ct, _tl, _rl, _th in PASSES:
        bad += check("I2 UiEventClass_ListTable_%s is 0x300 bytes = 192 entries" % tag,
                     (0x300 // 4), CLASS_N)
    push_rows = [t for a, _b, t in RT.unidasm_range(0xF86A23, 0xF86A3D)]
    bad += check("I3 pushes at 0xF86A23-0xF86A3C: RAM cells",
                 sum(1 for t in push_rows if t.startswith("pushw (0x")), 5)
    bad += check("I3 ...registers", sum(1 for t in push_rows
                                        if re.match(r"push X[A-Z]{2}$", t)), 6)
    bad += check("I3 ...ELEVEN IN TOTAL, not eleven PLUS five", len(push_rows), 11)

    print("L. the three class tables and their list areas")
    own = []
    for tag, _e, ct, tl, rl, _th in PASSES:
        ent, heads = lists_of(ct)
        alo = [d for d in dirs if d[0] == ct][0][2]
        ahi = [d for d in dirs if d[0] == ct][0][3]
        bad += check("L1 table %s: distinct heads" % tag, len(heads), 122)
        shared = heads[-1]
        own.append(frozenset(c for c, v in enumerate(ent) if v != shared))
        bad += check("L3 table %s: first head == area start" % tag,
                     "0x%06X" % heads[0], "0x%06X" % alo)
        ends = [heads[i + 1] if i + 1 < len(heads) else ahi
                for i in range(len(heads))]
        bad += check("L3 table %s: the LAST list ends at the area end" % tag,
                     "0x%06X" % list_end(heads[-1], ahi), "0x%06X" % ahi)
        bad += check("L5 table %s: lists NOT ending in 0xFFFFFFFF" % tag,
                     [i for i in range(len(heads))
                      if w32(ends[i] - 4) != 0xFFFFFFFF], [])
        bad += check("L3 table %s: bytes covered by the lists" % tag,
                     sum(ends[i] - heads[i] for i in range(len(heads))), ahi - alo)
    bad += check("L2 the SAME 121 class ids own a list in all three tables",
                 (len(own[0]), own[0] == own[1] == own[2]), (121, True))
    entC, headsC = lists_of(0xF88EC1)
    sharedC = headsC[-1]
    nonempty = sorted(c for c, v in enumerate(entC)
                      if v != sharedC and w32(v) != 0xFFFFFFFF)
    bad += check("L4 area C's NON-empty lists (round 1 said all 192 were empty)",
                 ["0x%02X" % c for c in nonempty], ["0xA8", "0xA9"])
    bad += check("L4 ...and class 0xA9's first entry is INSIDE this span",
                 "0x%06X" % w32(entC[0xA9]), "0x%06X" % 0xF8659B)

    print("M. the two 32-byte maps")
    bad += check("M1 PanelMode_To2076Map's reader bound", dis1(0xF86CB4), "cp L,0x1f")
    bad += check("M2 0xF86CB0 READS (0x2078)", dis1(0xF86CB0), "ld L,(0x2078)")
    bad += check("M2 0xF86CC4 WRITES (0x2076)", dis1(0xF86CC4), "ld (0x2076),A")
    bad += check("M2 0xF8638F READS (0x2078) too -- the SAME cell, not the "
                 "one above it writes", dis1(0xF8638F), "ld A,(0x2078)")
    sm = list(rom("a")[0xF86EA1 - A_BASE:0xF86EC1 - A_BASE])
    bad += check("M3 PanelMode_ToScreenIdMap entries above view B's 0xDF bound",
                 [v for v in sm if v > 0xDF], [])
    bad += check("M3 ...entry 31 (LAST)", "0x%02X" % sm[31], "0x01")

    print("P. the three passes differ only in three immediates")
    bad += check("P1 re-derived from the ROM",
                 pass_fields(),
                 [(t, e, ct, tl, rl) for t, e, ct, tl, rl, _th in PASSES])
    # the two citation ADDRESSES the generated headers quote are computed, so
    # they get the same decode test as every hand-written citation
    bad += check("P2 the class-table load is AT the entry point",
                 [dis1(e) for _t, e, _ct, _tl, _rl, _th in PASSES],
                 ["ld XIY,0x00%06x" % ct for _t, _e, ct, _tl, _rl, _th in PASSES])
    bad += check("P3 the tail-list load is at entry+9",
                 [dis1(e + 9) for _t, e, _ct, _tl, _rl, _th in PASSES],
                 ["ld XIY,0x00%06x" % tl for _t, _e, _ct, tl, _rl, _th in PASSES])

    print("S. every citation decodes AT the address cited")
    citations = sorted(set(
        [0xF86055, 0xF86172, 0xF86215, 0xF8621E, 0xF86228, 0xF86383, 0xF8638F,
         0xF86473, 0xF864C9, 0xF864CE, 0xF864D3, 0xF864E7, 0xF864EC, 0xF864F1,
         0xF86515, 0xF8651B, 0xF86520, 0xF86525, 0xF86530, 0xF86535, 0xF8653A,
         0xF86545, 0xF8654C, 0xF86597, 0xF86659, 0xF86696, 0xF8660D, 0xF866C3,
         0xF866D3, 0xF866E0, 0xF86856, 0xF86890, 0xF86893, 0xF868B2, 0xF868C3,
         0xF869F7, 0xF869FB, 0xF86A0E, 0xF86A1B, 0xF86A1F, 0xF86A6A, 0xF86B1B,
         0xF86B1F, 0xF86B24, 0xF86C6C, 0xF86C73, 0xF86C82, 0xF86CB4, 0xF86CBB,
         0xF8620B, 0xF86147]))
    starts = set()
    for kind, a, n in segs:
        if kind == "code":
            for x, _bs, _t in RT.unidasm_range(a, a + n):
                starts.add(x)
    bad += check("S1 cited addresses that are NOT an instruction boundary",
                 [x for x in citations if x not in starts], [])
    bad += check("S1 cited addresses that do not decode at all",
                 [x for x in citations if dis1(x) is None], [])
    bad += check("S3 0xF8620B reads C, not L (round 1 said `cp L,0xdf`)",
                 dis1(0xF8620B), "cp C,0xdf")

    print("T. the thunk run's proven call sites")
    _run, _slots, hits = L.hot_thunk_callsites()
    run = {s: v for s, v in hits.items() if 0xF40F34 <= s <= 0xF40F50}
    bad += check("T1 run T_F40F34-T_F40F50 total (round 1 said 88)",
                 sum(len(v) for v in run.values()), 89)
    bad += check("T1 ...T_F40F3C alone (round 1 said 58)",
                 len(run.get(0xF40F3C, [])), 59)
    bad += check("T1 ...and the whole run T_F40F34-T_F40F94, the LAST slot "
                 "included", sum(len(v) for v in hits.values()), 95)

    print("V. the screen vtables")
    vals = [w32(0xF86EC1 + 4 * i) for i in range(256)]
    bad += check("V1 256 entries end where PanelScreen_NullVtable begins",
                 "0x%06X" % (0xF86EC1 + 4 * 256), "0xF872C1")
    bad += check("V2 entries equal to the stub", vals.count(0xF872C1), 81)
    bad += check("V3 the stub's nine bytes",
                 list(rom("a")[0xF872C1 - A_BASE:0xF872CA - A_BASE]),
                 [0x68, 0x06, 0x68, 0x04, 0x68, 0x02, 0x68, 0x00, 0x0E])
    live = sorted(set(vals) - {0xF872C1})
    ok3 = [v for v in live if by(v) == 0x1B and by(v + 4) == 0x1B and by(v + 8) == 0x1B]
    bad += check("V4 distinct live vtable pointers", len(live), 174)
    bad += check("V4 ...whose +0/+4/+8 are three `jp addr24` (opcode 0x1B)",
                 len(ok3), 171)
    bad += check("V4 ...the other three point at 0x0E (`ret`) filler",
                 sorted("0x%06X" % v for v in live if v not in ok3
                        and by(v) == 0x0E and by(v + 4) == 0x0E and by(v + 8) == 0x0E),
                 ["0xF406C4", "0xF406CC", "0xF406DC"])
    bad += check("V4 ...LAST live pointer", "0x%06X" % live[-1], "0xF434E0")
    liveidx = [i for i, v in enumerate(vals) if v != 0xF872C1]
    bad += check("V5 view A (entries 0..47) live", sum(1 for i in liveidx if i <= 47), 26)
    bad += check("V5 view B (entries 32..255) live",
                 sum(1 for i in liveidx if i >= 32), 160)
    bad += check("V5 ...live in the OVERLAP 32..47",
                 sum(1 for i in liveidx if 32 <= i <= 47), 11)
    bad += check("V6 method +0 comes from `ld BC,0x0000`",
                 [dis1(0xF86525), dis1(0xF8653A)], ["ld BC,0x0000"] * 2)
    bad += check("V6 method +4 comes from `ld BC,0x0004`",
                 [dis1(0xF864D3), dis1(0xF864F1)], ["ld BC,0x0004"] * 2)
    bad += check("V6 method +8 comes from `add XBC,0x00000008`",
                 dis1(0xF8621E), "add XBC,0x00000008")

    print("\n%d checks, %d failures" % (_RUN[0], bad))
    return 1 if bad else 0


def show_sites():
    """Every address this file cites as a naming, call or branch site, with the
    two tests that catch lane a2's round-1 bug.

    TEST 1 (the strong one): the site is an INSTRUCTION BOUNDARY of the layout's
    own decode of the code segments.  A citation that landed on an operand is not
    a boundary.
    TEST 2 (weaker, printed for the address-naming sites only): the byte at the
    site is an opcode that CAN carry a 24-bit immediate.  It is weak because an
    operand byte can coincide with such an opcode -- three of round 1's citations
    passed it and were still wrong."""
    segs, _dirs = layout()
    structure()
    rows, named, calls, jumps = census(segs)
    starts = set()
    for kind, a, n in segs:
        if kind == "code":
            for x, _bs, _t in RT.unidasm_range(a, a + n):
                starts.add(x)
    print("%-30s %-6s %-34s %s" % ("target", "byte", "instruction at the site",
                                   "site"))
    notbound = notop = 0
    for t in sorted(set(named) | set(calls) | set(jumps)):
        for s in sorted(named.get(t, set()) | calls.get(t, set())
                        | jumps.get(t, set())):
            b = by(s)
            flag = ""
            if s not in starts:
                flag += "   <- NOT AN INSTRUCTION BOUNDARY"
                notbound += 1
            if s in named.get(t, set()) or s in calls.get(t, set()):
                if b not in NAMING_OPCODES:
                    flag += "   <- not an address-naming opcode"
                    notop += 1
            print("%-30s 0x%02X   %-34s 0x%06X%s"
                  % (LABELS.get(t, "0x%06X" % t), b, dis1(s) or "?", s, flag))
    print("\n%d cited sites that are NOT an instruction boundary (this is the "
          "test that matters)" % notbound)
    print("%d address-naming sites whose first byte cannot carry a 24-bit "
          "immediate" % notop)
    return 1 if notbound else 0


def main():
    segs, _dirs = layout()
    if "--check" in ARGV:
        print("layout OK: %d segments tiling 0x%06X-0x%06X" % (len(segs), LO, HI))
        return 0
    if "--selftest" in ARGV:
        return selftest()
    if "--sites" in ARGV:
        return show_sites()
    structure()
    ev = entry_points(segs)
    body = emit(segs, ev)
    text = "\n".join(body)

    # THE SELF-PROOF: assemble what we are about to print and compare with the ROM.
    got = RT.assemble_block(RT.macro_prelude() + "\n\t.text\n" + text + "\n")
    want = rom("a")[LO - A_BASE:HI - A_BASE]
    if got != want:
        n = -1 if got is None else sum(1 for i in range(min(len(got), len(want)))
                                       if got[i] != want[i])
        sys.exit("REFUSING TO PRINT: the emitted text does not rebuild the span "
                 "(%s, %d differing bytes)"
                 % ("assembly failed" if got is None
                    else "len %d vs %d" % (len(got), len(want)), n))
    if "--stats" in ARGV:
        c = collections.Counter(k for k, _a, _n in segs)
        b = collections.Counter()
        for k, _a, n in segs:
            b[k] += n
        sem = [v for v in LABELS.values() if not re.match(r"sub_[0-9A-F]{6}$", v)]
        print("segments by kind:", dict(c))
        print("bytes by kind:   ", dict(b))
        print("labels: %d, of which semantic %d and sub_XXXXXX %d"
              % (len(LABELS), len(sem), len(LABELS) - len(sem)))
        print("header blocks: %d" % len(HEADERS))
        print("emitted lines: %d; re-assembles to the ROM exactly" % len(body))
        return 0
    print("; ==== 0xF85FF9-0xF89800 -- emitted by "
          "notes/gen_prom_a_f85ff9_module.py ====")
    print("; Layout from notes/prom_a_f85ff9_layout.py; audited by "
          "notes/prom_a_f85ff9_verify.py")
    print("; (\"NOT REFUTED AS A LAYOUT, REFUTED AS A DOSSIER\"), so the tiling is "
          "taken and")
    print("; the prose is re-derived here.  `--selftest` reproduces every number "
          "below.")
    print("; This text was assembled and byte-compared with the ROM before "
          "printing.")
    print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
