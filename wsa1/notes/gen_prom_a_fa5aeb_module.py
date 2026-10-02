#!/usr/bin/env python3
"""Emit the assembly for prom_a 0xFA5AEB-0xFAA000 -- the MIDI module's tail plus
the whole MIDI<->part parameter router at 0xFA6000-0xFA9FFF.

QUESTION IT ANSWERS
    "What is the assembly text for this 17,685-byte `.incbin` span, in a form the
     byte gate accepts, with every label, header comment and table entry attached
     to the right address?"
    This is the emitter whose output is spliced into prom_a/wsa1_prom_a.s.

WHERE THE BOUNDARIES COME FROM -- AND NOT FROM A LINEAR DECODE
    notes/prom_a_fa5aeb_layout.py, re-derived on EVERY run by build().  This
    script refuses to print if the segment count moved, if the segments stop
    tiling the span, or if the barrier and the descent conflict.  That layout's
    own `--selftest` was 123 checks / 0 failures BEFORE this region was spliced
    and wave 7 round 1's skeptic found it NOT REFUTED.  ⚠ AFTER the splice three
    of its checks fail (`residue runs` 3 for 1, `residue bytes` 108 for 14,
    `branches whose destination the .s states` 10588 for 10037) and all three are
    corpus-growth artefacts, not defects: that file seeds its descent from
    prom_a/wsa1_prom_a.s and therefore now reads this emitter's own output.  The
    banner main() prints says so too.  THIS file is immune because it drops the
    relative targets whose citing instruction is inside its own span, so its
    layout is still 42 segments and its residue still one run of 14 bytes.
    Whoever owns that file needs to re-pin those three constants.

WHY THIS SPAN
    Top of prom_a by SUMMED thunk extent (16,799 -- `python3
    notes/wave7_frontier_table.py --sums`): three prom_b directory runs point
    into it and converting it retires fourteen slots.

WHERE THE NAMES COME FROM
    ⚠ The byte gate is blind to every name below, so each one is derived here
    rather than typed, and `--selftest` reproduces the derivation.  The two
    load-bearing derivations are:

      * MIDI CONTROLLER IDENTITY.  0xFA83E8 maps a 7-bit controller number to an
        internal index; 0xFA62B8 maps that index to a handler; 0xFA8FC8 maps it
        back to a controller number.  The last two are inverse on all 23 of the
        first map's live entries, so a handler's controller number has TWO
        independent witnesses.  Every `MidiIn_CCnn_*` name is generated from
        those tables, not written by hand.
      * THE ECHO PAIRING.  Nine `MidiIn_CCnn_*` handlers `calr` an out-bound
        routine which ends in `ld W,<index> / calr 0xFA7BF3`, and 0xFA7BF3 maps
        that index through 0xFA8FC8.  In all nine the controller number that
        SELECTED the in-handler equals the controller number the echo EMITS.
        That agreement is check E and it is what makes both halves nameable.

    Where no such witness exists the label stays `sub_XXXXXX` and the header
    says what named the address instead.  A stated gap beats a plausible guess.

NOTHING HERE CAN BREAK THE GATE
    Code segments come from prom_a/roundtrip.py's emit_block(), which assembles
    and byte-compares every candidate spelling before returning it.  Data is
    emitted from the ROM.  Then main() assembles the WHOLE emitted region and
    compares it byte for byte with the ROM, and exits non-zero WITHOUT PRINTING
    if it differs.  So the text this prints has already rebuilt the span.

RUN
    python3 notes/gen_prom_a_fa5aeb_module.py            # the assembly
    python3 notes/gen_prom_a_fa5aeb_module.py --check    # layout fingerprint only
    python3 notes/gen_prom_a_fa5aeb_module.py --stats    # segment/label census
    python3 notes/gen_prom_a_fa5aeb_module.py --sites    # the naming census, with
                                                         # the opcode test on every
                                                         # cited address
    python3 notes/gen_prom_a_fa5aeb_module.py --selftest # every number quoted in a
                                                         # header, re-derived
"""
import collections
import importlib.util
import os
import re
import sys
import textwrap

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
LO, HI = 0xFA5AEB, 0xFAA000
A_BASE = 0xF80000

ARGV = list(sys.argv)               # captured BEFORE any import mangles it


def _load(path, name):
    """Import a sibling tool as a module.  ⚠ Both of them read sys.argv at import
    time, so argv is masked during the load and restored afterwards -- without
    this, the flags to THIS script are silently eaten."""
    spec = importlib.util.spec_from_file_location(name, path)
    m = importlib.util.module_from_spec(spec)
    saved = sys.argv
    sys.argv = [name]
    try:
        spec.loader.exec_module(m)
    finally:
        sys.argv = saved
    return m


L = _load(os.path.join(ROOT, "notes", "prom_a_fa5aeb_layout.py"), "fa5aeb_layout")
RT = _load(os.path.join(ROOT, "prom_a", "roundtrip.py"), "rt")

# The layout as audited in wave 7 round 1 and re-run at the head of round 2.
EXPECTED = 42


# ⚠ THE RE-DERIVATION MUST NOT READ ITS OWN OUTPUT.
#
# notes/prom_a_fa5aeb_layout.py seeds its descent partly from the PC-relative
# branch targets of every proven instruction in prom_a/wsa1_prom_a.s.  Before
# this region is spliced, none of those instructions is inside it; afterwards,
# 2,807 of them are, the seed set grows, and build() returns 46 segments instead
# of 42 -- so the guard below would fire on the emitter's own success and the
# span could never be re-emitted.  Worse, an emitter whose layout depends on
# what it last printed is not re-deriving anything.
#
# So: drop the relative targets whose CITING INSTRUCTION is inside [LO,HI).
# That is exactly the set the splice added, which makes the layout this file
# computes identical before and after, and independent of its own output.
_REL_ORIG = L.rel_targets
_REL_DROPPED = [None]


def _rel_targets_outside_span(lo=L.LO, hi=L.HI, rev=None):
    out, dropped = {}, 0
    for t, ss in _REL_ORIG(lo, hi, rev).items():
        keep = [x for x in ss if not (LO <= x < HI)]
        dropped += len(ss) - len(keep)
        if keep:
            out[t] = keep
    _REL_DROPPED[0] = dropped
    return out


L.rel_targets = _rel_targets_outside_span

_D = None


def rom():
    global _D
    if _D is None:
        _D = L.rom("a")
    return _D


def by(a):
    return rom()[a - A_BASE]


def w16(a):
    return int.from_bytes(rom()[a - A_BASE:a - A_BASE + 2], "little")


def w32(a):
    return int.from_bytes(rom()[a - A_BASE:a - A_BASE + 4], "little")


def layout():
    segs, conflicts, pending, ok, seen, regs, named = L.build()
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
    return segs


# ------------------------------------------------------------------ the census
#
# ⚠ THIS DOES NOT REUSE the layout module's naming set.  That set is collected
# inside descend(), which (a) matches only the `0x00xxxxxx` immediate spelling
# and (b) never sees a run that accept() promoted -- both gaps are recorded in
# that file's own selftest.  Under those two gaps, TWO of the twenty-five
# 0xFA8FF8 blocks look unreferenced when in fact 0xFA97F8 is loaded at 0xFA790E
# and 0xFA9878 at 0xFA793E.  So the census below decodes EVERY code segment the
# layout declares and reads every operand spelling.

_CENSUS = None


def census(segs):
    """(rows, named, calls, jumps) over every `code` segment of the layout.

    `named[value]` / `calls[value]` are sets of INSTRUCTION addresses.  Cite from
    these and never from a hexdump offset: `ld XIX,0x00fa84c8` has its opcode at
    p and its immediate at p+1, and citing p+1 is the systematic off-by-one this
    project has now made twice.  --sites proves p is an opcode for every site."""
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
# on an operand shows up as 0x00/0xfa/0x60-style garbage instead.
NAMING_OPCODES = {0x08, 0x0B, 0x1B, 0x1D, 0x1E, 0x30, 0x31, 0x32, 0x33, 0x43,
                  0x44, 0x45, 0x46, 0xC0, 0xC1, 0xC2, 0xD0, 0xD1, 0xD2, 0xE0,
                  0xE1, 0xE2, 0xF0, 0xF1, 0xF2}


# --------------------------------------------------------------- the structure
#
# Every pointer table in the span, with the entry count and WHAT PINS IT.  The
# "bound" column is the literal the code compares the index against; the "abuts"
# column is the address the table ends at, which in every case is an object that
# something else names.  Two independent pins per table.
PTAB = [
    # base,      n,   bound instruction / literal,                     abuts
    (0xFA607A,   8,  "(status & 0x70) >> 2 at 0xFA603F-0xFA6042",       0xFA609A),
    (0xFA6164,  16,  "(status & 0x0F) << 2 at 0xFA614F-0xFA6152",       0xFA61A4),
    (0xFA6242,   8,  "(status & 0x70) >> 2 at 0xFA6229-0xFA622C",       0xFA6262),
    (0xFA62B8,  48,  "index from MidiIn_ControllerNumberToIndex",       0xFA6378),
    (0xFA7034,  16,  "((0x7F35) & 0x0F) << 2 at 0xFA7020-0xFA7023",     0xFA7074),
    (0xFA7180,  17,  "`ld A,0x10` at 0xFA713C/0xFA7154/0xFA716C/0xFA7177", 0xFA71C4),
    (0xFA7520,   4,  "`ld A,0x03` at 0xFA7519",                         0xFA7530),
    (0xFA753C,   4,  "`ld A,0x03` at 0xFA7536",                         0xFA754C),
    (0xFA80FE,  11,  "max live value of MidiOut_ChangeIndexMap is 10",  0xFA812A),
    (0xFA8CC8, 192,  "`cp C,0xbf` at 0xFA710B",                         0xFA8FC8),
]
PTAB_N = {b: n for b, n, _p, _a in PTAB}

# The LE32 tables that hold 16-bit RAM addresses rather than ROM pointers.
RAMTAB = [
    (0xFA82DE,  32, "`cp L,0x20` at 0xFA82D5",  0xFA835E),
    (0xFA83C0,  10, "`ld C,0x0a` at 0xFA83B3",  0xFA83E8),
]
# 0xFA8FF8 is 25 CONSECUTIVE 32-entry tables of the same shape; each has its own
# reader and its own base, and they are byte-identical to one another.
PARTTAB_BASE, PARTTAB_BLOCKS, PARTTAB_N = 0xFA8FF8, 25, 32

# The 23 per-controller parameter tables, 32 records each.  Filled in by
# structure() from the census, so the stride and the reader are re-derived.
RECARR_STRIDE3 = 0x60      # 32 records x 3 bytes
RECARR_STRIDE2 = 0x40      # 32 records x 2 bytes

STANDARD_CC = {
    0x00: "Bank Select MSB", 0x01: "Modulation wheel", 0x02: "Breath controller",
    0x04: "Foot controller", 0x06: "Data Entry MSB", 0x07: "Channel Volume",
    0x0A: "Pan", 0x0B: "Expression",
    0x10: "General Purpose 1", 0x11: "General Purpose 2",
    0x12: "General Purpose 3", 0x13: "General Purpose 4",
    0x20: "Bank Select LSB", 0x26: "Data Entry LSB",
    0x50: "General Purpose 5", 0x51: "General Purpose 6",
    0x52: "General Purpose 7",
    0x5B: "Effects 1 Depth", 0x5D: "Effects 3 Depth", 0x5E: "Effects 4 Depth",
    0x40: "Damper pedal (sustain)",
    0x64: "RPN LSB", 0x65: "RPN MSB",
    0x78: "All Sound Off", 0x79: "Reset All Controllers",
}
# Short, identifier-safe forms of the above, used to build label names.
CC_SLUG = {
    0x00: "BankSelMSB", 0x01: "Modulation", 0x02: "Breath", 0x04: "Foot",
    0x06: "DataEntMSB", 0x07: "Volume", 0x0A: "Pan", 0x0B: "Expression",
    0x10: "General1", 0x11: "General2", 0x12: "General3", 0x13: "General4",
    0x20: "BankSelLSB", 0x26: "DataEntLSB", 0x50: "General5",
    0x40: "Damper", 0x51: "General6", 0x52: "General7", 0x5B: "Effect1Depth",
    0x5D: "Effect3Depth", 0x5E: "Effect4Depth", 0x64: "RpnLSB", 0x65: "RpnMSB",
    0x78: "AllSoundOff", 0x79: "ResetAllCtrl",
}


def cc_maps():
    """(fwd, inv) -- controller number -> internal index, and back.

    fwd is the 128-byte map at 0xFA83E8 that MidiIn_ControlChange indexes with
    the first data byte; inv is the 48-byte map at 0xFA8FC8 that
    MidiOut_SendController indexes with the internal index."""
    fwd = {cc: by(0xFA83E8 + cc) for cc in range(128) if by(0xFA83E8 + cc) != 0xFF}
    inv = [by(0xFA8FC8 + i) for i in range(48)]
    return fwd, inv


def echo_index(rows, s, e):
    """The controller indices a routine hands to MidiOut_SendController.

    Reads `ld W,<imm>` immediately preceding a `calr 0xFA7BF3` inside [s,e)."""
    out, pend = [], None
    byaddr = {a: (bs, t) for a, bs, t in rows}
    p = s
    while p < e:
        if p not in byaddr:
            p += 1
            continue
        bs, t = byaddr[p]
        m = re.match(r"ld W,0x([0-9a-f]+)$", t)
        if m:
            pend = int(m.group(1), 16)
        elif t.startswith("calr 0xfa7bf3") and pend is not None:
            out.append(pend)
        p += len(bs)
    return out


def routine_bounds(segs, entries):
    """[(start, end)] -- entry points cut each code segment into routines."""
    out = []
    for kind, a, n in segs:
        if kind != "code":
            continue
        pts = sorted(x for x in entries if a <= x < a + n)
        pts = pts or [a]
        if pts[0] != a:
            pts.insert(0, a)
        for i, s in enumerate(pts):
            out.append((s, pts[i + 1] if i + 1 < len(pts) else a + n))
    return out


def entry_points(segs):
    """addr -> [evidence strings] for every in-span address something outside the
    linear stream names."""
    rows, named, calls, jumps = census(segs)
    ev = collections.defaultdict(list)
    for slot, t in L.thunk_entries(LO, HI):
        ev[t].append("prom_b directory slot T_%06X" % slot)
    for t in L.directory_pointers(LO, HI):
        ev[t].append("prom_b directory bare pointer")
    for b, n, _pin, _ab in PTAB:
        for i in range(n):
            v = w32(b + 4 * i)
            if LO <= v < HI:
                ev[v].append("%s[%d]" % (LABELS.get(b, "0x%06X" % b), i))
    for t in sorted(calls):
        ss = sorted(calls[t])
        txt = ", ".join("0x%06X" % x for x in ss[:6])
        if len(ss) > 6:
            txt += ", +%d more" % (len(ss) - 6)
        ev[t].append("call from " + txt)
    return ev


# ------------------------------------------------------------------ the labels
#
# Filled by structure().  Kept as one dict so a collision test can run over all
# of it at once (check A2).
LABELS = {}
HEADERS = {}


def H(addr, *lines):
    HEADERS[addr] = list(lines)


# ---- ⚠⚠ NAMES THAT LIVE IN THE .s AND WOULD BE REVERTED BY A RE-EMIT ----
#
# Measured 2026-08-30 (round 12): 82 labels in the address range this file
# emits are spelled differently in prom_a/wsa1_prom_a.s than the generators
# above produce.  FORTY-THREE of them predate round 12 -- round 4's
# controller renames (CC40_Damper -> CC40_Hold, CC02_Breath ->
# CC02_Modulation2, CC10_General1 -> CC10_RTCreatX and their siblings, each
# argued from the instrument's own on-screen list at 0xFA2C13), the eleven
# MidiOut_ChangeRecord_* and the eleven MidiOut_PartRecordPtrs_* that were
# named from their readers.  Every one of those was applied to the LISTING
# ONLY, so `python3 notes/gen_prom_a_fa5aeb_module.py | insert_region` would
# have silently put the positional spellings back and the byte gate would
# have passed.  Round 9 already paid for this exact mistake once and wrote
# "THE FIX IS IN THE NAMES TABLE, NOT ONLY IN THE .s"; this is that fix, for
# the whole span rather than for one name.
#
# ★ HOW TO REGENERATE THIS TABLE rather than hand-edit it: emit the module,
# diff its labels against the .s over 0xFA5AEB-0xFAA000, and list every
# address where they disagree.  Check A9 below re-runs the comparison the
# cheap way -- it asserts that every address here is still inside the span
# and that no two entries collide -- and
# notes/prom_a_panel_names_round11.py --midi re-derives the round-12 half of
# it from MidiOut_ChangeRecordTable, from six agreeing readings.
#
# ⚠ The HEADERS above are NOT overridden here.  They still spell the old
# names in their prose, and the .s carries the corrected prose; a re-emit
# would restore stale sentences even with the labels right.  That is a
# smaller and louder failure than a silent rename, and it is stated rather
# than half-fixed.
LABELS_FROM_LISTING = {
0xFA645B: "MidiIn_CC40_Hold",
0xFA67E8: "MidiIn_CC02_Modulation2",
0xFA6872: "MidiIn_CC04_CtrlPedal",
0xFA68FC: "MidiIn_CC10_RTCreatX",
0xFA6986: "MidiIn_CC11_RTCreatY",
0xFA6A10: "MidiIn_CC12_RTCtrlX",
0xFA6A9A: "MidiIn_CC13_RTCtrlY",
0xFA767E: "MidiOut_PitchBend",
0xFA76BD: "MidiOut_PitchBend__partgate",
0xFA76EE: "MidiOut_PitchBend__emit",
0xFA775C: "MidiOut_CC01_Modulation__partgate",
0xFA77CA: "MidiOut_CC0B_Expression__partgate",
0xFA77FA: "MidiOut_ChannelPressure",
0xFA7839: "MidiOut_ChannelPressure__partgate",
0xFA786A: "MidiOut_ChannelPressure__emit",
0xFA7891: "MidiOut_CC40_Hold",
0xFA78D0: "MidiOut_CC40_Hold__partgate",
0xFA78F5: "MidiOut_CC40_Hold__emit",
0xFA78FF: "sub_FA78FF",   # NEW LABEL in the .s
0xFA792F: "sub_FA792F",   # NEW LABEL in the .s
0xFA795F: "MidiOut_CC10_RTCreatX",
0xFA799E: "MidiOut_CC10_RTCreatX__partgate",
0xFA79C3: "MidiOut_CC10_RTCreatX__emit",
0xFA79CD: "MidiOut_CC11_RTCreatY",
0xFA7A0C: "MidiOut_CC11_RTCreatY__partgate",
0xFA7A31: "MidiOut_CC11_RTCreatY__emit",
0xFA7A3B: "MidiOut_CC12_RTCtrlX",
0xFA7A7A: "MidiOut_CC12_RTCtrlX__partgate",
0xFA7A9F: "MidiOut_CC12_RTCtrlX__emit",
0xFA7AA9: "MidiOut_CC13_RTCtrlY",
0xFA7AE8: "MidiOut_CC13_RTCtrlY__partgate",
0xFA7B0D: "MidiOut_CC13_RTCtrlY__emit",
0xFA7B17: "MidiOut_CC02_Modulation2",
0xFA7B56: "MidiOut_CC02_Modulation2__partgate",
0xFA7B7B: "MidiOut_CC02_Modulation2__emit",
0xFA7B85: "MidiOut_CC04_CtrlPedal",
0xFA7BC4: "MidiOut_CC04_CtrlPedal__partgate",
0xFA7BE9: "MidiOut_CC04_CtrlPedal__emit",
0xFA812A: "MidiOut_ChangeRecord_CC01Modulation",
0xFA8136: "MidiOut_ChangeRecord_CC02Modulation2",
0xFA8142: "MidiOut_ChangeRecord_CC04CtrlPedal",
0xFA814E: "MidiOut_ChangeRecord_CC10RTCreatX",
0xFA815A: "MidiOut_ChangeRecord_CC11RTCreatY",
0xFA8166: "MidiOut_ChangeRecord_CC12RTCtrlX",
0xFA8172: "MidiOut_ChangeRecord_CC13RTCtrlY",
0xFA817E: "MidiOut_ChangeRecord_CC40Hold",
0xFA818A: "MidiOut_ChangeRecord_ChannelPressure",
0xFA8196: "MidiOut_ChangeRecord_PitchBend",
0xFA81A2: "MidiOut_ChangeRecord_CC0BExpression",
0xFA81FC: "MidiIn_BuildList_PitchBend",
0xFA820B: "MidiIn_BuildList_CC01Modulation",
0xFA821A: "MidiIn_BuildList_ChannelPressure",
0xFA8229: "MidiIn_BuildList_CC40Hold",
0xFA8238: "MidiIn_BuildList_CC10RTCreatX",
0xFA8247: "MidiIn_BuildList_CC11RTCreatY",
0xFA8256: "MidiIn_BuildList_CC12RTCtrlX",
0xFA8265: "MidiIn_BuildList_CC13RTCtrlY",
0xFA8274: "MidiIn_BuildList_CC02Modulation2",
0xFA8283: "MidiIn_BuildList_CC04CtrlPedal",
0xFA8292: "MidiIn_BuildList_CC0BExpression",
0xFA9078: "MidiOut_PartRecordPtrs_CC07Volume",
0xFA90F8: "MidiOut_PartRecordPtrs_CC5DEffect3Depth",
0xFA9178: "MidiOut_PartRecordPtrs_CC5EEffect4Depth",
0xFA91F8: "MidiOut_PartRecordPtrs_CC5BEffect1Depth",
0xFA9278: "MidiOut_PartRecordPtrs_CC0APan",
0xFA92F8: "MidiOut_PartRecordPtrs_Rpn02CoarseTune",
0xFA9378: "MidiOut_PartRecordPtrs_Rpn01FineTune",
0xFA93F8: "MidiOut_PartRecordPtrs_Rpn00PitchBendRange",
0xFA9478: "MidiOut_PartRecordPtrs_CC79ResetAllCtrl",
0xFA94F8: "MidiOut_PartRecordPtrs_CC78AllSoundOff",
0xFA9578: "MidiOut_PartRecordPtrs_PitchBend",
0xFA95F8: "MidiOut_PartRecordPtrs_CC01Modulation",
0xFA9678: "MidiOut_PartRecordPtrs_CC0BExpression",
0xFA96F8: "MidiOut_PartRecordPtrs_ChannelPressure",
0xFA9778: "MidiOut_PartRecordPtrs_CC40Hold",
0xFA98F8: "MidiOut_PartRecordPtrs_CC10RTCreatX",
0xFA9978: "MidiOut_PartRecordPtrs_CC11RTCreatY",
0xFA99F8: "MidiOut_PartRecordPtrs_CC12RTCtrlX",
0xFA9A78: "MidiOut_PartRecordPtrs_CC13RTCtrlY",
0xFA9AF8: "MidiOut_PartRecordPtrs_CC02Modulation2",
0xFA9B78: "MidiOut_PartRecordPtrs_CC04CtrlPedal",
0xFA9BF8: "MidiOut_PartRecordPtrs_CC51General6",
}

def structure():
    """Assign every label and header.  Called once, before emission."""
    if LABELS:
        return
    segs = layout()
    rows, named, calls, jumps = census(segs)
    fwd, inv = cc_maps()

    def sites(v):
        s = sorted(named.get(v, set()) | calls.get(v, set()))
        return ", ".join("0x%06X" % x for x in s) or "NOTHING FOUND"

    # ---------------------------------------------------- the MIDI module tail
    LABELS[0xFA5AEB] = "MIDI_Fg_SystemCommon"
    H(0xFA5AEB,
      "MIDI_Fg_SystemCommon -- the foreground parser's 0xFn System handler",
      "",
      "Called from: MIDI_Fg_System 0xFA5A82 (`calr`), and nothing else -- no",
      "         absolute call or jp in either image names this address, which is",
      "         why an absolute-site scanner sees this whole span as unreachable.",
      "Inputs:  (XIZ+0x08) the byte just received; (0x0960) the running status.",
      "Outputs: for a SysEx opening whose second byte is 0x50 or 0x7E, (0x0964)",
      "         = 3 and the two bytes {0xF0, that byte} are posted to ring",
      "         0x601C6E through 0xF41EAC (Ring601C6E_PutBlock).  Every other",
      "         System Common message falls through to `ld (0x0960),0x00`.",
      "Evidence: the three literals it tests are 0xF0, 0xF2 and 0xF3 (0xFA5B01,",
      "         0xFA5B07, 0xFA5B0D) -- SysEx, Song Position and Song Select, the",
      "         three System Common statuses this machine's interrupt-side",
      "         MIDI_RX_SystemCommon also singles out.  0x50 is Matsushita's MIDI",
      "         manufacturer ID and 0x7E the Universal Non-Real-Time ID.",
      "Note:    the word it loads from MIDI_SysExHeader is 0xF0,0x50; byte 1 is",
      "         then OVERWRITTEN at 0xFA5B24 with the received byte, so the 0x50",
      "         in the template is only the expected value, never the sent one.")

    LABELS[0xFA5B3D] = "MIDI_Fg_SysExData"
    H(0xFA5B3D,
      "MIDI_Fg_SysExData -- push one SysEx body byte into the receive queue",
      "",
      "Called from: MIDI_Fg_DataByte 0xFA5A0D (`calr`), and nothing else.",
      "Inputs:  (XIZ+0x08) the data byte; (0x0964) bits 1 and 5.",
      "Outputs: bit 0 of (0x216F) set and the byte posted to ring 0x601C6E via",
      "         0xF41EA8 (Ring601C6E_Put) -- but only when bit 1 of (0x0964) is",
      "         set and bit 5 clear.",
      "Evidence: bit 1 of (0x0964) is the flag MIDI_Fg_SystemCommon sets (it",
      "         writes the value 3 there) when it accepts a SysEx header, so the",
      "         gate here is literally `did we accept this SysEx`.  The queue it",
      "         writes is the same 0x601C6E the header went to.")

    LABELS[0xFA5B5F] = "MIDI_SendBankAndProgram"
    H(0xFA5B5F,
      "MIDI_SendBankAndProgram -- transmit Bank Select + Program Change",
      "",
      "Called from: prom_b directory slot T_F4072C (`jp 0xFA5B5F`).",
      "Inputs:  (XIZ+0x08) channel in bits 0-3 and the port select in bit 4;",
      "         (XIZ+0x0A) the program number; (XIZ+0x0C) a 16-bit bank number,",
      "         or 0xFFFF for `program change only`.",
      "Outputs: 7 bytes `Bn 00 <bank>>7> 20 <bank&0x7F> Cn <program>` on the",
      "         selected port, or just the last 2 when the bank is 0xFFFF.",
      "Evidence: it `ldir`s the seven bytes of MIDI_BankProgramTemplate",
      "         (0xFA5CBA = B0 00 00 20 00 C0 00) into the frame, then writes",
      "         bank>>7 to template byte 2 and bank&0x7F to byte 4 -- exactly the",
      "         two data slots of CC 0 and CC 32 -- and ORs the channel into",
      "         bytes 0 and 5, the two status bytes.  `ld DE,0x0002` before the",
      "         0xFFFF test and `ld DE,0x0007` after it are the two lengths.",
      "Note:    bit 4 of the first argument picks the destination: clear sends",
      "         through 0xF41DF8 (Ring601432_PutBlock) and wakes the transmitter",
      "         with MIDI_PostSendWork; set sends through 0xF40ED4, the block",
      "         sender that carries port B's stream to the other CPU.")

    LABELS[0xFA5BF7] = "MIDI_SendStart_PortB"
    H(0xFA5BF7,
      "MIDI_SendStart_PortB -- put the single byte 0xFA on port B",
      "",
      "Called from: MIDI_Reset 0xFA58C4, its only call site in either image.",
      "Outputs: one byte, 0xFA, handed to 0xF40ED4 with length 1 and stream 2.",
      "Evidence: the only byte it builds is the immediate 0xFA at 0xFA5BFB and",
      "         `push 0x0001` at 0xFA5C03 is the length.  0xFA is MIDI System",
      "         Real Time START, and the stream it goes to is the same one",
      "         MIDI_SendAllNotesOff_AllChannels uses for `Bn 7B 00 79 00`, so",
      "         the stream carries MIDI bytes rather than commands.",
      "Unknown: ⚠ that the far end acts on it AS a MIDI Start is inference. What",
      "         is proven is the byte, the length and the stream.")

    LABELS[0xFA5C12] = "MIDI_PostSendWork_PortB"
    H(0xFA5C12,
      "MIDI_PostSendWork_PortB -- drain port B's queue and forward it",
      "",
      "Called from: prom_b directory slot T_F40730 (`jp 0xFA5C12`).",
      "Outputs: every byte ring 0x60153C will give up, copied into a 256-byte",
      "         stack buffer and handed to 0xF40ED4 as one block, stream 2.",
      "Evidence: it loops on 0xF41E14 (Ring60153C_Get) until that returns",
      "         0xFFFF, and 0x60153C is the ring 0xF41E1C (Ring60153C_PutBlock)",
      "         fills.  It is the port-B twin of MIDI_PostSendWork: the pair",
      "         appears at 0xFA7D26/0xFA7D32 as `ld XIX,0x00F40724` (that",
      "         routine) versus `ld XIX,0x00F40730` (this one), selected by",
      "         `cp (0x194B),0x00` -- the same byte that selects between",
      "         Ring601432_PutBlock and Ring60153C_PutBlock ten instructions",
      "         earlier.")

    LABELS[0xFA5C54] = "MIDI_SendAllNotesOff_AllChannels"
    H(0xFA5C54,
      "MIDI_SendAllNotesOff_AllChannels -- CC 123 + CC 121 on all 16 channels,",
      "both ports",
      "",
      "Called from: prom_b directory slot T_F40734 (`jp 0xFA5C54`).",
      "Outputs: `Bn 7B 00 79 00` for n = 0..0x0F, first through 0xF41DF8",
      "         (Ring601432_PutBlock, port A) with MIDI_PostSendWork after each,",
      "         then again through 0xF40ED4 (port B).  Finally (0x9B) and",
      "         (0x091F), the two transmitter mailboxes, are cleared.",
      "Evidence: MIDI_AllNotesOffTemplate at 0xFA5CC1 is B0 7B 00 79 00 -- CC",
      "         123 All Notes Off followed, under running status, by CC 121 Reset",
      "         All Controllers.  The two loops both run `ld H,0x00` .. `cp",
      "         H,0x0F / jr ULE`, and `or C,0xB0` builds the status byte.")

    LABELS[0xFA5CB8] = "MIDI_SysExHeader"
    H(0xFA5CB8,
      "MIDI_SysExHeader -- the two bytes F0 50",
      "",
      "Read by: MIDI_Fg_SystemCommon 0xFA5AF3 (`ld BC,(0xfa5cb8)`), its only",
      "         reader.",
      "Layout:  0xF0 = SysEx status, 0x50 = the Matsushita manufacturer ID.",
      "Evidence: the two bytes are read as ONE 16-bit word into the outgoing",
      "         2-byte frame and byte 1 is then overwritten with the received ID,",
      "         which is why only 0xF0 survives to the wire.")

    LABELS[0xFA5CBA] = "MIDI_BankProgramTemplate"
    H(0xFA5CBA,
      "MIDI_BankProgramTemplate -- B0 00 00 20 00 C0 00",
      "",
      "Read by: MIDI_SendBankAndProgram 0xFA5B73 (`lda XIY,0xfa5cba`), its only",
      "         reader, with `ld BC,0x0007` + `ldir`.",
      "Layout:  CC 0 (Bank Select MSB), CC 32 (Bank Select LSB) under running",
      "         status, then Program Change.  Slots 2 and 4 take the bank halves,",
      "         slots 0 and 5 take the channel.",
      "Evidence: the seven bytes and the `ld BC,0x0007` agree; the writes at",
      "         0xFA5B99 and 0xFA5BA2 land on offsets 2 and 4.")

    LABELS[0xFA5CC1] = "MIDI_AllNotesOffTemplate"
    H(0xFA5CC1,
      "MIDI_AllNotesOffTemplate -- B0 7B 00 79 00",
      "",
      "Read by: MIDI_SendAllNotesOff_AllChannels 0xFA5C61 (`lda XIY,0xfa5cc1`),",
      "         its only reader, with `ld BC,0x0005` + `ldir`.",
      "Layout:  CC 123 All Notes Off then, under running status, CC 121 Reset",
      "         All Controllers.  Byte 0 takes 0xB0 | channel.",
      "Evidence: five bytes, `ld BC,0x0005`, and `push 0x0005` as the length.",
      "★ Together with the two objects above these fourteen bytes are the whole",
      "  of what notes/prom_a_fa5aeb_layout.py calls THE ONE HOLE (`Decodes, but",
      "  ... nothing reaches it`).  2 + 7 + 5 = 14 and each has exactly one",
      "  reader, so the hole is closed.")

    # -------------------------------------------------- the router: entry points
    LABELS[0xFA6000] = "MidiIn_EntryThunks"
    H(0xFA6000,
      "MidiIn_EntryThunks -- the module's six-slot entry table",
      "",
      "Read by: prom_b's directory, which holds the BARE pointer 0x00FA6000 at",
      "         T_F40740 and follows it with the run of live `jp` slots",
      "         T_F40744-T_F40760.  Same idiom as MIDI_EntryThunks at 0xFA5400.",
      "Layout:  slot 0 is `1b ae 83 fa` = `jp MidiIn_ModuleReset`; slots 1-5 are",
      "         `0e 00 00 00`, i.e. a bare RET followed by three pad bytes.")

    LABELS[0xFA6018] = "MidiIn_PumpPortA"
    H(0xFA6018,
      "MidiIn_PumpPortA -- drain MIDI IN port A and dispatch every message",
      "",
      "Called from: prom_b directory slot T_F40744 (`jp 0xFA6018`).",
      "Inputs:  ring 0x600C1E; (0x60F000) is zeroed on entry and used as a count.",
      "Outputs: for each message, the 0x1940 staging record is filled and one",
      "         entry of MidiIn_StatusClassTable is called; on exhaustion",
      "         0xF40898 runs and (0x2C00 + (0x60F000)) is set to 0xFF.",
      "Evidence: `ld XIX,0x00600C1E` and the head/tail compare `ld WA,(XIX+0xF6)",
      "         / cp WA,(XIX+0xFA)` are the ring-scan idiom; 0xF41DBC is",
      "         Ring600C1E_ScanRewind.  The dispatch index is",
      "         (status & 0x70) >> 2, so it is the message class 0x8n..0xFn.",
      "Twin:    MidiIn_PumpPortB is the same 97 bytes with FOUR bytes different",
      "         (measured, check T1): the ring base and the two thunk slots.")

    LABELS[0xFA6068] = "sub_FA6068"
    H(0xFA6068,
      "sub_FA6068 -- `call 0xF40004 / 0xF40008 / 0xF4000C / 0xF40010 / ret`",
      "",
      "Called from: NOTHING FOUND.  No thunk slot, no pointer-table entry and no",
      "         call or jp anywhere in prom_a or prom_b names 0xFA6068 -- a",
      "         searched negative, not an unsearched one.  It is inside a code",
      "         segment because it sits between MidiIn_PumpPortA's `ret` and the",
      "         table that follows, and it decodes exactly.",
      "Notes:   the four targets are Dev7F_WriteSlot8_Slot0..Slot3, four",
      "         consecutive directory slots.  sub_FA6112 is the same 17 bytes.",
      "Unknown: what calls it, and why the module carries it twice.")

    LABELS[0xFA607A] = "MidiIn_StatusClassTable"
    LABELS[0xFA609A] = "MidiIn_FetchMessage_PortA"
    H(0xFA609A,
      "MidiIn_FetchMessage_PortA -- copy one message from ring 0x600C1E to 0x1940",
      "",
      "Called from: MidiIn_PumpPortA 0xFA6034 (`calr`), its only caller.",
      "Outputs: (0x1940) status, (0x1941..) the data bytes, and (0x1943) = 0x00,",
      "         the PORT TAG.",
      "Evidence: `ld (XIY+0x03),0x00` at 0xFA60A4 pre-sets (0x1943); the port-B",
      "         twin writes 0x10 there instead, and MidiIn_RouteChannelMessage",
      "         ORs that byte into the channel to index a 32-entry map, so the",
      "         tag is the 0x10 bit that separates the two ports' 16 channels.",
      "         The copy loop calls 0xF41DC0 (Ring600C1E_Scan) and stops when the",
      "         NEXT byte has bit 7 set, i.e. at the next status byte.")

    LABELS[0xFA60C2] = "MidiIn_PumpPortB"
    H(0xFA60C2,
      "MidiIn_PumpPortB -- drain MIDI IN port B and dispatch every message",
      "",
      "Called from: prom_b directory slot T_F43358 (`jp 0xFA60C2`).",
      "Evidence: 97 bytes, of which FOUR differ from MidiIn_PumpPortA (check T1",
      "         re-derives the count): ring 0x601028 for 0x600C1E, and the",
      "         Ring601028 veneers 0xF41DE0/0xF41DE4 for 0xF41DBC/0xF41DC0.")

    LABELS[0xFA6112] = "sub_FA6112"
    H(0xFA6112,
      "sub_FA6112 -- the second copy of sub_FA6068, byte for byte",
      "",
      "Called from: NOTHING FOUND, same searched negative as sub_FA6068.")

    LABELS[0xFA6123] = "MidiIn_FetchMessage_PortB"
    H(0xFA6123,
      "MidiIn_FetchMessage_PortB -- copy one message from ring 0x601028 to 0x1940",
      "",
      "Called from: MidiIn_PumpPortB 0xFA60DE (`calr`), its only caller.",
      "Evidence: 0x28 bytes, of which FOUR differ from MidiIn_FetchMessage_PortA",
      "         (check T2): the ring base, the scan veneer, and the port tag",
      "         `ld (XIY+0x03),0x10` where port A writes 0x00.")

    LABELS[0xFA614B] = "MidiIn_SystemMessage"
    H(0xFA614B,
      "MidiIn_SystemMessage -- dispatch an 0xFn status on its low nibble",
      "",
      "Called from: MidiIn_StatusClassTable[7], the 0xFn slot.",
      "Evidence: `and L,0x0F / sla 2,L` then MidiIn_SystemSubTable, so the index",
      "         IS the System sub-type: 2 = Song Position, 3 = Song Select.")

    LABELS[0xFA6164] = "MidiIn_SystemSubTable"
    LABELS[0xFA61A4] = "MidiIn_SongPosition"
    H(0xFA61A4,
      "MidiIn_SongPosition -- MIDI 0xF2, Song Position Pointer",
      "",
      "Called from: MidiIn_SystemSubTable[2], and the index is the status byte's",
      "         low nibble, so this handler IS status 0xF2.",
      "Outputs: (0xA4) = data 1 (LSB), (0xA5) = data 2 (MSB), with bit 7 of",
      "         (0xA5) set when bit 2 of (0x7F34) is set.",
      "Evidence: `ld WA,(0x1941)` takes BOTH data bytes as one 16-bit load and",
      "         they are stored to adjacent bytes -- the two-data-byte shape of",
      "         Song Position, and the only System message with two.")

    LABELS[0xFA61B8] = "MidiIn_SongSelect"
    H(0xFA61B8,
      "MidiIn_SongSelect -- MIDI 0xF3, Song Select",
      "",
      "Called from: MidiIn_SystemSubTable[3], so this handler IS status 0xF3.",
      "Outputs: (0xA3) = the single data byte, bit 7 set when bit 3 of (0x7F33)",
      "         is set.",
      "Evidence: it reads (0x1941) only -- one data byte, which is Song Select's",
      "         shape and distinguishes it from the handler above.")

    LABELS[0xFA61C9] = "MidiIn_SystemIgnore"
    H(0xFA61C9,
      "MidiIn_SystemIgnore -- `or (0x9F),0x01` and return",
      "",
      "Called from: fourteen of MidiIn_SystemSubTable's sixteen slots -- every",
      "         System status except 0xF2 and 0xF3.")

    LABELS[0xFA61CE] = "MidiIn_RouteChannelMessage"
    H(0xFA61CE,
      "MidiIn_RouteChannelMessage -- run one channel message on every part",
      "listening to its channel",
      "",
      "Called from: seven of MidiIn_StatusClassTable's eight slots (0x8n..0xEn).",
      "Inputs:  (0x1940..0x1943) the staged message; the routing tables at",
      "         0x1800 (32 bytes) and 0x1820 (64 bytes).",
      "Outputs: (0x197E) = channel | port tag, (0x1974/0x1975/0x1977) the list",
      "         cursor and count, (0x1976) the current part index, then one call",
      "         of MidiIn_ChannelStatusTable per listening part.",
      "Evidence: `and A,0x0F / or A,(0x1943)` builds a 0..0x1F index -- 16",
      "         channels times two ports -- which selects an offset in 0x1800;",
      "         0x1820[offset] is the COUNT and 0x1820[offset+1..] the part",
      "         indices, because 0xFA620B increments the cursor and 0xFA623B",
      "         decrements (0x1977) until it hits zero.  Both tables are built by",
      "         MidiIn_BuildChannelRouteTable, which writes exactly that shape.")

    LABELS[0xFA6242] = "MidiIn_ChannelStatusTable"
    LABELS[0xFA6262] = "MidiIn_ChannelIgnore"
    H(0xFA6262,
      "MidiIn_ChannelIgnore -- `or (0x9F),0x01` and return",
      "",
      "Called from: MidiIn_ChannelStatusTable slots 0, 1, 2 and 7 -- Note Off,",
      "         Note On, Poly Key Pressure and 0xFn.",
      "★ Note On and Note Off are DELIBERATELY not handled here.  This module",
      "  routes controllers and per-part parameters; notes reach the tone",
      "  generator by another path.  That is a property of the table, not an",
      "  omission in this reading.")

    LABELS[0xFA6267] = "MidiIn_ControlChange"
    H(0xFA6267,
      "MidiIn_ControlChange -- MIDI 0xBn, Control Change",
      "",
      "Called from: MidiIn_ChannelStatusTable[3], the 0xBn slot.",
      "Inputs:  (0x1941) the controller number, (0x1942) its value.",
      "Outputs: (0x1963) = the internal controller index, then",
      "         MidiIn_ControllerHandlerTable[index] is called.",
      "Evidence: three tables in a row, each with its own bound.  (1) the",
      "         controller number indexes MidiIn_ControllerNumberToIndex; 0xFF",
      "         means `not ours` and returns.  (2) the index doubles into",
      "         MidiIn_ControllerEnableTable, whose 16-bit entry is a byte offset",
      "         from 0x7F39 in the high half and a bit mask in the low half --",
      "         `ld XIX,0x00007F39 / ld C,(XIX+W) / and C,A` -- and 0xFFFF means",
      "         `always enabled`.  (3) the index quadruples into",
      "         MidiIn_ControllerHandlerTable.")

    LABELS[0xFA62B8] = "MidiIn_ControllerHandlerTable"
    LABELS[0xFA6378] = "MidiIn_NullHandler"
    _n48 = sum(1 for i in range(48) if w32(0xFA62B8 + 4 * i) == 0xFA6378)
    _n17 = sum(1 for i in range(17) if w32(0xFA7180 + 4 * i) == 0xFA6378)
    H(0xFA6378,
      "MidiIn_NullHandler -- one byte, `ret`",
      "",
      "Called from: %d of MidiIn_ControllerHandlerTable's 48 slots and %d of"
      % (_n48, _n17),
      "         MidiOut_ParamClassTable's 17 (counts re-derived, check N1).",
      "★ Its address is also what pins MidiIn_ControllerHandlerTable's length:",
      "  0xFA62B8 + 48*4 = 0xFA6378, so the table ends exactly where the first",
      "  routine it points at begins.  A 49th entry would read this `ret`.")

    LABELS[0xFA6D27] = "sub_FA6D27"
    H(0xFA6D27,
      "sub_FA6D27 -- the special arm of the CC 0x5B handler",
      "",
      "Called from: 0xFA67E4 (`calr`), inside MidiIn_CC5B_Effect1Depth, taken",
      "         only when the parameter id byte the table yielded is 0x60.",
      "Evidence: it rewrites (0x1952) to 0 or to the table's third byte on a",
      "         threshold of 0x40 -- `cp A,0x40 / jr C` -- and then calls",
      "         0xF40858 instead of 0xF40888.  What the 0x60 id and the two",
      "         senders mean is a question for the 0xFAD800 module.")

    LABELS[0xFA6D58] = "MidiIn_ProgramChange"
    H(0xFA6D58,
      "MidiIn_ProgramChange -- MIDI 0xCn, Program Change",
      "",
      "Called from: MidiIn_ChannelStatusTable[4], the 0xCn slot.",
      "Evidence: it reads ONE data byte -- `ld E,(0x1941) / ld D,0xFF` at",
      "         0xFA6DC8 -- which is Program Change's shape, and it is gated on",
      "         bit 4 of (0x7F39), the same enable array MidiIn_ControlChange",
      "         indexes.  Its per-part table is MidiOut_PartFlagsTable's",
      "         neighbour at 0xFA8BA8.")

    LABELS[0xFA6DE3] = "MidiIn_PitchBend"
    H(0xFA6DE3,
      "MidiIn_PitchBend -- MIDI 0xEn, Pitch Bend",
      "",
      "Called from: MidiIn_ChannelStatusTable[6], the 0xEn slot.",
      "Evidence: it reads BOTH data bytes -- `ld E,(0x1941) / ld D,(0x1942)` at",
      "         0xFA6E1F -- and it is the only channel handler that does, which",
      "         is Pitch Bend's shape.  Gated on bit 6 of (0x7F39).")

    LABELS[0xFA6E6A] = "MidiIn_ChannelPressure"
    H(0xFA6E6A,
      "MidiIn_ChannelPressure -- MIDI 0xDn, Channel Pressure",
      "",
      "Called from: MidiIn_ChannelStatusTable[5], the 0xDn slot.",
      "Evidence: one data byte, `ld E,(0x1941) / ld D,0x7F` at 0xFA6EA6.  Gated",
      "         on bit 5 of (0x7F39) -- bits 4, 5 and 6 of that byte gate",
      "         Program Change, Channel Pressure and Pitch Bend in table order.")

    LABELS[0xFA6EEF] = "MidiIn_ReqRouteRebuild_Msg0D"
    H(0xFA6EEF,
      "MidiIn_ReqRouteRebuild_Msg0D -- ask for a channel-route rebuild",
      "",
      "Called from: prom_b directory slot T_F40754 (`jp 0xFA6EEF`).",
      "Outputs: bit 0 of (0x1978) set, but only when (0x20B8) == 0x0D and",
      "         (0x20BA) & 0xDF is non-zero.",
      "Evidence: (0x20B8) is the message/page number the 0xFC0000 module",
      "         dispatches on (notes/FINDINGS-prom_a-msg0716-module.md), so this",
      "         is a hook on one UI message.  Bit 0 of (0x1978) is exactly what",
      "         MidiIn_ServiceRouteRebuild tests and clears.")

    LABELS[0xFA6F04] = "MidiIn_ServiceDeferred"
    H(0xFA6F04,
      "MidiIn_ServiceDeferred -- run whatever (0x1978) has queued",
      "",
      "Called from: prom_b directory slot T_F40758 (`jp 0xFA6F04`).",
      "Evidence: two calls and a return -- MidiIn_ServiceRouteRebuild for bit 0",
      "         and MidiIn_ServicePartLists for bit 1.")

    LABELS[0xFA6F0B] = "MidiIn_ServiceRouteRebuild"
    LABELS[0xFA6F21] = "MidiIn_BuildChannelRouteTable"
    H(0xFA6F21,
      "MidiIn_BuildChannelRouteTable -- rebuild 0x1800/0x1820 from the part records",
      "",
      "Called from: MidiIn_ServiceRouteRebuild 0xFA6F1A (`calr`), its only caller.",
      "Outputs: 0x1800[0..0x1F] = the offset of that channel's list in 0x1820,",
      "         and each list is `count, part, part, ...`.",
      "Evidence: the outer loop runs W = 0..0x1F (`cp (0x197A),0x20`), the inner",
      "         one runs (0x197C) = 0..0x1F over the 32 part structures reached",
      "         through (0x60F018), and the channel it matches on is byte +0x0D",
      "         of each structure masked with 0x1F.  The count is written back",
      "         at 0xFA6FFF (`ld (XIY),E` with E = (0x197B), the match count) and",
      "         the offset at 0xFA7007.  That is precisely the shape",
      "         MidiIn_RouteChannelMessage reads.",
      "Note:    (0x1979) chooses between the 0x1800/0x1820 pair and a second",
      "         pair at 0x18A0/0x18C0.  MidiIn_ServiceRouteRebuild always sets it",
      "         to 0x80, so on that path only the first pair is written.")

    LABELS[0xFA701C] = "MidiIn_AfterRebuild"
    LABELS[0xFA7034] = "MidiIn_AfterRebuildTable"
    LABELS[0xFA7074] = "MidiIn_AfterRebuild_Nop"
    LABELS[0xFA7075] = "MidiIn_AfterRebuildTable_Nop1"
    H(0xFA7075,
      "MidiIn_AfterRebuildTable_Nop1 -- MidiIn_AfterRebuildTable[1]",
      "",
      "Called from: MidiIn_AfterRebuildTable[1], selected by (0x7F35) & 0x0F.",
      "Evidence: it walks 0x1800 from the entry named by (0x7F36) & 0x1F,",
      "         incrementing every non-0xFF offset, then opens a hole in the",
      "         0x1820 list by copying backwards and writing 0xFF -- an insert.",
      "Unknown: which list element is being inserted, and for what.  Named",
      "         sub_ deliberately.")

    LABELS[0xFA70CE] = "MidiIn_ResetChannelRouteTable"
    H(0xFA70CE,
      "MidiIn_ResetChannelRouteTable -- put 0x1800/0x1820 back to one entry per",
      "channel",
      "",
      "Called from: MidiIn_AfterRebuildTable[2].",
      "Evidence: 0x1800[k] = 3k for k = 0..0x1F (`xor A,A / ld (XIX+),A / inc",
      "         3,A`, 0x20 times) and 0x1820 gets 32 copies of the three bytes",
      "         02 FF 00 (`ld WA,0xff02 / ld E,0x00`), which is stride 3 and",
      "         matches the offsets exactly.")

    # ----------------------------------------------------------- the echo side
    LABELS[0xFA70F5] = "MidiOut_ParamChanged"
    H(0xFA70F5,
      "MidiOut_ParamChanged -- a parameter changed; maybe echo it as MIDI",
      "",
      "Called from: prom_b directory slot T_F40748 (`jp 0xFA70F5`).",
      "Inputs:  BC = the parameter id (C the number, B the class), DE the value.",
      "Outputs: (0x1958..0x195B) = BC,DE, then MidiOut_ParamNumberTable[C] is",
      "         called; bit 7 of (0x60F007) is cleared on the way out.",
      "Evidence: `cp C,0xbf / jr UGT` is the table's bound and 0xBF + 1 = 192 is",
      "         its entry count, which is also pinned by 0xFA8CC8 + 192*4 =",
      "         0xFA8FC8, the base of the next object.  The whole routine is",
      "         skipped when bit 0 of (0x0922) is set and bit 1 is clear.")

    LABELS[0xFA7129] = "MidiOut_Param_Ignore"
    H(0xFA7129,
      "MidiOut_Param_Ignore -- one byte, `ret`",
      "",
      "Called from: %d of MidiOut_ParamNumberTable's 192 slots (re-derived,"
      % sum(1 for i in range(192) if w32(0xFA8CC8 + 4 * i) == 0xFA7129),
      "         check N2).  Most parameter numbers are not echoed.")

    LABELS[0xFA712A] = "MidiOut_ParamGate_Part0"
    LABELS[0xFA7142] = "MidiOut_ParamGate_Part1"
    LABELS[0xFA715A] = "MidiOut_ParamGate_Part2"
    H(0xFA712A,
      "MidiOut_ParamGate_Part0/1/2 -- MidiOut_ParamNumberTable[0], [1] and [2]",
      "",
      "Called from: MidiOut_ParamNumberTable slots 0, 1 and 2.",
      "Evidence: each is 24 bytes and each tests bit 6 of ONE RAM byte -- 0x76AF,",
      "         0x76EF and 0x772F, which are entries [0], [1] and [2] of",
      "         MidiOut_PartRecordPtrs_00.  So parameter number k names part k's",
      "         record for k < 3.  All three then fall into the same",
      "         `ld XIY,MidiOut_ParamClassTable / ld A,0x10 / calr` dispatch that",
      "         MidiOut_ParamDispatch reaches unconditionally.")

    LABELS[0xFA7172] = "MidiOut_ParamDispatch"
    H(0xFA7172,
      "MidiOut_ParamDispatch -- the ungated dispatch on the parameter CLASS",
      "",
      "Called from: MidiOut_ParamNumberTable slots 3..31 (%d of them)."
      % sum(1 for i in range(192) if w32(0xFA8CC8 + 4 * i) == 0xFA7172),
      "Evidence: `ld XIY,0x00FA7180 / ld A,0x10 / calr MidiOut_DispatchByClass`,",
      "         the same three instructions the three gated twins end with.")

    LABELS[0xFA7180] = "MidiOut_ParamClassTable"
    LABELS[0xFA754C] = "MidiOut_DispatchByClass"
    H(0xFA754C,
      "MidiOut_DispatchByClass -- call table[(0x1959)] if the index is in range",
      "",
      "Called from: 0xFA713E, 0xFA7156, 0xFA716E, 0xFA7179, 0xFA751B, 0xFA7538.",
      "Inputs:  XIY = the table base, A = its HIGHEST legal index, (0x1959) = the",
      "         parameter class.",
      "Evidence: `cp L,A / jr UGT` is the bound test, so the caller's literal is",
      "         the entry count minus one.  Its four 0xFA7180 callers all pass",
      "         0x10, giving 17 entries, and 0xFA7180 + 17*4 = 0xFA71C4, which is",
      "         entry [0] of that very table -- the table ends where its first",
      "         handler begins.  The 0xFA7520 and 0xFA753C callers pass 3.",
      "Notes:   the same idiom as the two dispatchers of the 0xFC0000 module",
      "         (notes/FINDINGS-prom_a-msg0716-module.md), down to the `cp L,A`.")

    LABELS[0xFA7BF3] = "MidiOut_SendController"
    H(0xFA7BF3,
      "MidiOut_SendController -- emit `Bn <cc> <value>` for an internal index",
      "",
      "Called from: 19 sites, all inside this module.",
      "Inputs:  W = the internal controller index, E = the value, XIX = the",
      "         part's RAM record.",
      "Outputs: the message staged at 0x1948 and handed to",
      "         MidiOut_PostStagedMessage.",
      "Evidence: `cp W,0x2f / jr UGT` then `ld XIZ,0x00FA8FC8 / ld W,(XIZ+W)`",
      "         -- the index is looked up in MidiOut_IndexToControllerNumber and",
      "         0xFF means `no controller, drop it`.  0x2F + 1 = 48 is that map's",
      "         length and 0xFA8FC8 + 48 = 0xFA8FF8, the next object's base.",
      "         The status byte is built by `and A,0x0F / or A,0xB0`.")

    LABELS[0xFA7C3E] = "MidiOut_SendRpn"
    H(0xFA7C3E,
      "MidiOut_SendRpn -- emit a four-message RPN write",
      "",
      "Called from: 0xFA738B, 0xFA73CD, 0xFA7409 -- the class handlers for",
      "         classes 9, 10 and 11.",
      "Evidence: it stages four controller numbers in order, 0x64, 0x65, 0x06 and",
      "         0x26 (`ld W,0x64`, `ld A,0x65`, `ld A,0x06`, `ld A,0x26`), which",
      "         is RPN LSB, RPN MSB, Data Entry MSB, Data Entry LSB -- the",
      "         standard RPN sequence.  C and B carry the RPN number, D and E the",
      "         data.",
      "★ The three callers are classes 9, 10 and 11, and MidiIn_CC06_DataEntryMSB",
      "  writes exactly those three class numbers for RPN 0x0002, 0x0001 and",
      "  0x0000 -- coarse tune, fine tune and pitch-bend sensitivity.  The two",
      "  halves agree without either being written from the other.")

    LABELS[0xFA7C95] = "MidiOut_SendBankSelect"
    H(0xFA7C95,
      "MidiOut_SendBankSelect -- emit CC 0 then CC 32",
      "",
      "Called from: 0xFA7448, 0xFA7490, 0xFA74CC, 0xFA7580.",
      "Evidence: `ld W,0x00` with D, then `ld W,0x20` with E, each followed by",
      "         MidiOut_PostStagedMessage; both values have bit 7 cleared first.",
      "         Gated on bit 7 of (0x7F3A) and bit 7 of the part record's +0x27.")

    LABELS[0xFA7CE8] = "MidiOut_PostStagedMessage"
    H(0xFA7CE8,
      "MidiOut_PostStagedMessage -- put the 0x1948 message on the chosen port,",
      "waiting for room",
      "",
      "Called from: 13 sites, all inside this module.",
      "Inputs:  0x1948 = {status, controller, value, port, length}.",
      "Evidence: (0x194B) picks the port everywhere at once -- `cp (XIX+0x03),",
      "         0x00` selects 0xF41DF8 (Ring601432_PutBlock) with mailbox (0x9B)",
      "         and post-work 0xF40724 (MIDI_PostSendWork), or 0xF41E1C",
      "         (Ring60153C_PutBlock) with mailbox (0x091F) and post-work",
      "         0xF40730 (MIDI_PostSendWork_PortB).  Running status is honoured:",
      "         when the staged status equals the mailbox the status byte is",
      "         dropped and the length decremented (0xFA7D10-0xFA7D18).",
      "Notes:   on a full queue it spins up to 0xF0 times (`cp (0xA2),0xF0`)",
      "         re-testing the ring's free count, then re-initialises the ring",
      "         through 0xF41E00/0xF41E24 and retries.")

    LABELS[0xFA7D92] = "sub_FA7D92"
    H(0xFA7D92,
      "sub_FA7D92 -- set the port-A running-status mailbox, then fall through",
      "",
      "Called from: prom_b directory slot T_F4074C (`jp 0xFA7D92`).",
      "Evidence: three bytes, `ld (0x9B),A`, falling into sub_FA7D95.  (0x9B) is",
      "         the mailbox MIDI_PostSendWork and MidiOut_PostStagedMessage both",
      "         use for port A's running status.")

    LABELS[0xFA7D95] = "sub_FA7D95"
    H(0xFA7D95,
      "sub_FA7D95 -- push one byte through 0xF41DF4 (Ring601432_Put)",
      "",
      "Called from: prom_b directory slot T_F40750 (`jp 0xFA7D95`), and by",
      "         fall-through from sub_FA7D92.")

    LABELS[0xFA7DA3] = "sub_FA7DA3"
    H(0xFA7DA3,
      "sub_FA7DA3 -- two timeouts on the millisecond counter at (0x80)",
      "",
      "Called from: prom_b directory slot T_F4075C (`jp 0xFA7DA3`).",
      "Evidence: sub_FA7DAA compares (0x80) - (0x091C) against 0x0096 = 150 and",
      "         clears both transmitter mailboxes when it expires; sub_FA7DCA",
      "         compares (0x80) - (0x0920) against 0x05DC = 1500 and republishes",
      "         bit 0 of (0x0922) through 0xF40F3C.",
      "Unknown: what the 150 ms and 1500 ms deadlines protect.  Named sub_.")

    LABELS[0xFA7DAA] = "sub_FA7DAA"
    LABELS[0xFA7DCA] = "sub_FA7DCA"
    LABELS[0xFA7E0C] = "sub_FA7E0C"
    H(0xFA7E0C,
      "sub_FA7E0C -- the module's bulk `send everything again` entry",
      "",
      "Called from: prom_b directory slot T_F40760 (`jp 0xFA7E0C`).",
      "Evidence: it calls sub_FA7E1E, then sub_FA7E37 (344 bytes that walk every",
      "         part and re-emit its parameters through MidiOut_ChangeRecords),",
      "         then MidiIn_RebuildPartLists.")

    LABELS[0xFA7E1E] = "sub_FA7E1E"
    LABELS[0xFA7E37] = "sub_FA7E37"
    LABELS[0xFA7F8F] = "MidiOut_RunChangeRecord"
    H(0xFA7F8F,
      "MidiOut_RunChangeRecord -- look up (0x1968) and run its 12-byte record",
      "",
      "Called from: nine sites in sub_FA7E37, each of which loads (0x1968) with a",
      "         different source byte first.",
      "Evidence: (0x1968) indexes MidiOut_ChangeIndexMap; 0xFF means `nothing to",
      "         do`; the surviving value indexes MidiOut_ChangeRecordTable, whose",
      "         eleven entries are the eleven records at 0xFA812A.  The record is",
      "         then read field by field with post-increment (`ld XIY,(XIX+)`),",
      "         which is what makes it twelve bytes: two routine pointers, a",
      "         parameter id and a value, twice.")

    LABELS[0xFA7FFE] = "MidiOut_ChangeIndexMap"
    LABELS[0xFA80FE] = "MidiOut_ChangeRecordTable"
    for _i in range(PTAB_N[0xFA80FE]):
        LABELS[0xFA812A + 12 * _i] = "MidiOut_ChangeRecord_%02d" % _i
    H(0xFA812A,
      "The eleven MidiOut_ChangeRecord_* -- eleven 12-byte records",
      "",
      "Read by: MidiOut_RunChangeRecord, through MidiOut_ChangeRecordTable.",
      "Layout:  [0:4] a routine called with a 32-bit part mask, [4:8] a routine",
      "         called with the parameter staged, [8:10] the parameter id and",
      "         [10:12] its value.  The reader walks the record with",
      "         post-increment loads, then rewinds and walks it AGAIN with a",
      "         second mask and a second value, so one record drives two passes.",
      "         Entry [0] of the table is 0xFA812A and the eleven entries are",
      "         0x0C apart, so the stride is the table's own arithmetic; 11 * 12",
      "         = 132 = 0xFA81AE - 0xFA812A, and 0xFA81AE is",
      "         MidiIn_RebuildPartLists, which prom_b names.  Both ends pinned.",
      "★ Indices 8 and 9 are never produced by MidiOut_ChangeIndexMap (its live",
      "  values are 0,1,2,3,4,5,6,7,10), and round 12 EXPLAINS it: that map's nine",
      "  non-0xFF cells sit at map indices 0x01,0x02,0x04,0x0B,0x10,0x11,0x12,0x13",
      "  and 0x40, exactly the nine CONTROLLER NUMBERS of the nine records they",
      "  select, so the index is a controller number -- and records 8 and 9 are",
      "  MidiOut_ChangeRecord_ChannelPressure and MidiOut_ChangeRecord_PitchBend,",
      "  two channel messages that have no controller number.  They are reached",
      "  from MidiIn_ChannelPressure and MidiIn_PitchBend instead.",
      "⚠ NOT the same 8 and 9 as the two dead indices of",
      "  MidiOut_IndexToControllerNumber; different table, different index rule.")

    LABELS[0xFA81AE] = "MidiIn_RebuildPartLists"
    H(0xFA81AE,
      "MidiIn_RebuildPartLists -- rebuild the eleven part lists at 0x19F0..0x1A90",
      "",
      "Called from: sub_FA7E1A and MidiIn_ServicePartLists 0xFA83AA.",
      "Evidence: eleven `ld XWA,(0x19E0) / calr` pairs, one per list; each callee",
      "         is fifteen bytes that load its list address, a selector word and a",
      "         mask word and jump into MidiIn_BuildPartList.  The eleven bases",
      "         are 0x19F0, 0x1A00, ... 0x1A90, sixteen bytes apart.",
      "⚠ MidiIn_ModuleReset clears only TEN of them -- 0x1A90 is missing from",
      "  MidiIn_ResetPointerTable.  Re-derived by check R1.")

    LABELS[0xFA82A1] = "MidiIn_BuildPartList"
    H(0xFA82A1,
      "MidiIn_BuildPartList -- collect the parts that pass a mask into one list",
      "",
      "Called from: all eleven of the fifteen-byte veneers above.",
      "Inputs:  XIX the destination, XWA a 32-bit per-part selector, DE and BC",
      "         the byte offset and mask pair.",
      "Outputs: a 0xFF-terminated list of part indices.",
      "Evidence: `srl 1,XWA / jr NC` walks the 32 selector bits, `cp L,0x20`",
      "         bounds the loop at 32 parts, and the second test reads",
      "         MidiOut_PartFlagsTable[part] + C.  It writes 0xFF both before the",
      "         loop and after it, so an empty list is still terminated.")

    LABELS[0xFA82DE] = "MidiOut_PartFlagsTable"
    H(0xFA82DE,
      "MidiOut_PartFlagsTable -- 32 pointers to part record + 0x26",
      "",
      "Read by: MidiIn_BuildPartList 0xFA82B4.",
      "Layout:  32 LE32 words holding 16-bit RAM addresses, 0x76D5..0x7ED5.",
      "Evidence: entry k is exactly MidiOut_PartRecordPtrs_00[k] + 0x26 for all",
      "         32 k (check P2), including the one place both tables step by 0x80",
      "         instead of 0x40.  So this is the SAME 32 records seen at a fixed",
      "         field offset, and `cp L,0x20` in the reader is the entry count.")

    LABELS[0xFA835E] = "MidiIn_ReqListRebuild_Msg13_16"
    H(0xFA835E,
      "MidiIn_ReqListRebuild_Msg13_16 -- ask for a part-list rebuild",
      "",
      "Called from: prom_b directory slot T_MidiIn_ReqListRebuild_Msg13_16 (`jp 0xFA835E`).",
      "Evidence: sets bit 1 of (0x1978) when (0x20B8) is 0x13..0x16 and (0x20BA)",
      "         is non-zero.  Bit 1 is the bit MidiIn_ServicePartLists tests.")

    LABELS[0xFA8378] = "MidiIn_ReqRebuild_Msg03_0A"
    H(0xFA8378,
      "MidiIn_ReqRebuild_Msg03_0A -- ask for either rebuild, by message number",
      "",
      "Called from: prom_b directory slot T_F43354 (`jp 0xFA8378`).",
      "Evidence: (0x20B8) == 3 or 4 sets bit 0 of (0x1978), the channel-route",
      "         rebuild; 7..0x0A with (0x20BA) non-zero sets bit 1, the part-list",
      "         rebuild.  Same two bits as the two hooks above.")

    LABELS[0xFA83A0] = "MidiIn_ServicePartLists"
    LABELS[0xFA83AE] = "MidiIn_ModuleReset"
    H(0xFA83AE,
      "MidiIn_ModuleReset -- put 0xFF at the head of ten part lists",
      "",
      "Called from: MidiIn_EntryThunks slot 0 (`jp 0xFA83AE`), the module's",
      "         published reset entry.",
      "Evidence: `ld C,0x0a` is the loop count and `ld A,0xff` the value; the ten",
      "         destinations are the ten LE32 entries of MidiIn_ResetPointerTable,",
      "         read with post-increment.  Ten entries is also 0xFA83C0 + 10*4 =",
      "         0xFA83E8, the base of MidiIn_ControllerNumberToIndex, which the",
      "         code names independently at 0xFA6267.")

    LABELS[0xFA83C0] = "MidiIn_ResetPointerTable"
    LABELS[0xFA83E8] = "MidiIn_ControllerNumberToIndex"
    LABELS[0xFA8468] = "MidiIn_ControllerEnableTable"
    LABELS[0xFA8C68] = "MidiIn_PartIdentityMap"
    H(0xFA8C68,
      "MidiIn_PartIdentityMap -- 32 bytes, value == index",
      "",
      "Read by: MidiIn_CC06_DataEntryMSB 0xFA6B71 and MidiIn_CC26_DataEntryLSB",
      "         0xFA6C00, both as `ld C,(XIX+HL)` with HL the part index.",
      "Layout:  0x00..0x1F, checked whole (check I1), not at the ends.",
      "Notes:   the two readers use it exactly as the other controllers use their",
      "         32-record tables, so the parameter id for Data Entry is the part",
      "         index itself.")

    LABELS[0xFA8C88] = "MidiIn_BankSelect_ParamTable"
    H(0xFA8C88,
      "MidiIn_BankSelect_ParamTable -- 32 LE16 parameter ids, one per part",
      "",
      "Read by: MidiIn_CC00_BankSelectMSB 0xFA63BF and MidiIn_CC20_BankSelectLSB",
      "         0xFA642F -- the only 32-record table with two readers.",
      "Layout:  32 entries of 2 bytes; 0xFA8C88 + 64 = 0xFA8CC8, the base of",
      "         MidiOut_ParamNumberTable.")

    LABELS[0xFA8CC8] = "MidiOut_ParamNumberTable"
    LABELS[0xFA8FC8] = "MidiOut_IndexToControllerNumber"

    # ---- generated: the 25 part-record pointer blocks -----------------------
    for k in range(PARTTAB_BLOCKS):
        b = PARTTAB_BASE + k * 4 * PARTTAB_N
        LABELS[b] = "MidiOut_PartRecordPtrs_%02d" % k
    H(PARTTAB_BASE,
      "The 25 MidiOut_PartRecordPtrs_* -- 25 tables of 32 part-record pointers",
      "",
      "Read by: %d distinct instructions.  Block 00 is named at %d sites (%s)"
      % (sum(len(named.get(PARTTAB_BASE + 128 * k, ())) for k in range(25)),
         len(named[PARTTAB_BASE]), sites(PARTTAB_BASE)),
      "         and each of the other 24 blocks at exactly one; check B1 asserts",
      "         that no block is left without a reader.",
      "Layout:  each block is 32 LE32 words holding 16-bit RAM addresses, from",
      "         0x76AF in steps of 0x40 -- with ONE step of 0x80, between entries",
      "         7 and 8.  All 25 blocks are BYTE-IDENTICAL (check B2).",
      "★ The identity is not a redundancy in one table: these are 25 SEPARATE",
      "  32-entry tables, each named by its own `ld XIX,<base>` in a different",
      "  routine, all mapping the same part index to the same record.  Reading",
      "  the 3,200 bytes as `25 rows of one 800-entry table` is what makes the",
      "  row index look meaningless; it is not a row index.",
      "  ⚠ notes/prom_a_fa5aeb_layout.py's docstring still describes it the",
      "  other way, and its own --sites mode misses two of the 25 readers",
      "  (0xFA97F8 and 0xFA9878) because that mode only sees the `0x00xxxxxx`",
      "  immediate spelling inside descend().  This file's --sites finds all 25.")

    # ---- named outbound class handlers -------------------------------------
    LABELS[0xFA71C4] = "MidiOut_ProgramChange"
    H(0xFA71C4,
      "MidiOut_ProgramChange -- echo a program change outbound",
      "",
      "Called from: MidiOut_ParamClassTable[0].",
      "Evidence: it builds the status byte with `and A,0x0F / or A,0xC0` at",
      "         0xFA7210 -- 0xCn IS Program Change -- and stages (0x195A) as the",
      "         one data byte.  It is gated on bit 4 of (0x7F39), the same bit",
      "         that gates MidiIn_ProgramChange on the inbound side.")

    # The three RPN class handlers.  Which RPN each one writes is fixed by the
    # `ld BC,<n>` it hands MidiOut_SendRpn, and the SAME three numbers appear on
    # the inbound side as the three words MidiIn_CC06_DataEntryMSB compares
    # (0x8080/0x8081/0x8082, i.e. the RPN with bit 7 set in both halves).
    # Check E2 asserts the two agree.
    _RPN = {0xFA7353: (2, "Coarse Tune", "CoarseTune"),
            0xFA738F: (1, "Fine Tune", "FineTune"),
            0xFA73D1: (0, "Pitch Bend Sensitivity", "PitchBendRange")}
    for a2, (rpn, longname, slug) in _RPN.items():
        LABELS[a2] = "MidiOut_Rpn%02X_%s" % (rpn, slug)
        H(a2,
          "%s -- echo RPN 0x%04X (%s) outbound" % (LABELS[a2], rpn, longname),
          "",
          "Called from: MidiOut_ParamClassTable[%d]."
          % [i for i in range(17) if w32(0xFA7180 + 4 * i) == a2][0],
          "Evidence: `ld BC,0x%04x` is the RPN number it hands MidiOut_SendRpn,"
          % rpn,
          "         and MidiIn_CC06_DataEntryMSB routes RPN 0x%04X to exactly"
          % rpn,
          "         this class (it compares the stored RPN against 0x%04X, the"
          % (0x8080 | rpn),
          "         same number with bit 7 set in each half, and loads the class",
          "         number this table entry sits at).  Two witnesses, check E2.",
          "         Gated on bit 3 of (0x7F39).")

    # The four outbound bank-select shapes.  MidiOut_SendBankSelect puts D on
    # CC 0x00 and E on CC 0x20, so which half a routine fills IS its name.
    for a2, nm, why in (
        (0xFA740D, "MidiOut_BankSelect_LsbHalf",
         "it puts the incoming value (0x195A) in E -- the CC 0x20 half -- and "
         "takes the MSB from the stash at (0x196B); when the stash's bit 7 is "
         "still set it only remembers the value and sends nothing"),
        (0xFA7455, "MidiOut_BankSelect_MsbHalf",
         "the mirror image: the incoming value goes to D, the CC 0x00 half, and "
         "the LSB comes from the stash at (0x196A)"),
        (0xFA749D, "MidiOut_BankSelect_Packed",
         "one 6-bit value becomes both halves -- `and E,0x3F / sll 5,DE / "
         "srl 1,E` leaves D = value >> 3 and E = (value << 4) & 0x7F"),
        (0xFA7561, "MidiOut_BankSelect_Pair",
         "it loads BOTH halves at once, `ld DE,(0x195A)` as one 16-bit word")):
        LABELS[a2] = nm
        wrapped = textwrap.wrap("Evidence: " + why + ".", 68,
                                subsequent_indent="         ")
        H(a2,
          "%s -- send a Bank Select through MidiOut_SendBankSelect" % nm,
          "",
          *(textwrap.wrap("Called from: "
                          + entry_list(entry_points(segs).get(a2)) + ".", 68,
                          subsequent_indent="         ") + wrapped))

    LABELS[0xFA7D92] = "MidiOut_PutByteA_SetStatus"
    LABELS[0xFA7D95] = "MidiOut_PutByteA"
    H(0xFA7D95,
      "MidiOut_PutByteA -- push one byte into port A's transmit ring",
      "",
      "Called from: prom_b directory slot T_F40750, and by fall-through from",
      "         MidiOut_PutByteA_SetStatus (T_F4074C), which is the same routine",
      "         with `ld (0x9B),A` in front of it -- (0x9B) is port A's",
      "         running-status mailbox.",
      "Evidence: it pushes A zero-extended and calls 0xF41DF4, which prom_b's",
      "         directory resolves to Ring601432_Put, inside `ei 6` / `ei 0`.")

    # ---- the eleven part-list veneers, named by the list they fill ----------
    _ven = [int(t[7:], 16) for _a, _bs, t in rows
            if 0xFA81AE <= _a < 0xFA81FC and t.startswith("calr 0x")]
    for a2 in _ven:
        LABELS[a2] = "MidiIn_BuildList_%04X" % w32(a2 + 1)
    if _ven:
        H(_ven[0],
          "The eleven MidiIn_BuildList_* -- eleven fifteen-byte veneers",
          "",
          "Called from: MidiIn_RebuildPartLists, one `calr` each, in this order;",
          "         three of them are also called directly from sub_FA7E37.",
          "Layout:  `ld XIX,<list>` / `ld DE,<offset:mask>` / `ld BC,<mask pair>`",
          "         / `calr MidiIn_BuildPartList` / `ret`, fifteen bytes, and the",
          "         eleven list addresses are 0x19F0 in steps of 0x10.",
          "★ WITHDRAWN, round 12: this header used to end \"each veneer's name is",
          "         taken from the 32-bit immediate of its own first instruction, not",
          "         assigned by hand\".  That was true of the OLD names",
          "         MidiIn_BuildList_19F0.._1A90 and is FALSE of the ones the listing",
          "         now carries: each veneer is named for the outbound handler that",
          "         walks the list it fills, paired by MidiOut_ChangeRecordTable.  See",
          "         LABELS_FROM_LISTING below.  check R2 pins the eleven ADDRESSES",
          "         and is unaffected.",
          "Evidence: notes/prom_a_panel_names_round11.py --midi prints, for each of",
          "         the eleven, the change record that pairs the veneer with the",
          "         handler AND the handler's own `ld XIZ` at the same list address --",
          "         two witnesses per pairing, 11 of 11 (its checks X2 and X3).",
          "⚠ MidiIn_ModuleReset clears only the first TEN; 0x1A90 is not in",
          "  MidiIn_ResetPointerTable.  Check R1.")

    # ---- generated: the per-controller handlers and their tables -----------
    #
    # THREE PASSES, deliberately.  A header that names a table must be written
    # AFTER that table has a label, and a table's label is derived from the
    # routine that reads it -- so labels first, tables second, prose last.
    ents = entry_points(segs)
    bounds = {s2: e2 for s2, e2 in routine_bounds(segs, set(ents))}
    handler = {}
    for i in range(PTAB_N[0xFA62B8]):
        handler.setdefault(w32(0xFA62B8 + 4 * i), []).append(i)
    idx_of = {i: cc for cc, i in fwd.items()}

    # pass 1 -- the handler labels
    cc_of_handler = {}
    for v, idxs in sorted(handler.items()):
        if v == 0xFA6378:
            continue
        ccs = sorted(set(idx_of[i] for i in idxs if i in idx_of))
        if len(ccs) == 1:
            cc_of_handler[v] = ccs[0]
            LABELS[v] = "MidiIn_CC%02X_%s" % (ccs[0], CC_SLUG.get(ccs[0],
                                                                  "CC%02X" % ccs[0]))
        else:
            LABELS.setdefault(v, "sub_%06X" % v)

    # pass 1b -- the echo routines, named by the controller they emit.
    #
    # ROUND A is the routine that itself ends `ld W,<index> / calr
    # MidiOut_SendController`.  ROUND B is its CALLER, when that caller emits
    # nothing of its own and exactly one of its callees does: nine of the twelve
    # outbound routines are shaped that way, and it is the caller -- not the
    # ten-byte tail -- that MidiOut_ParamNumberTable and the inbound handler
    # name.  So the caller takes the controller's name and the tail takes the
    # same name with `__emit`, the way the MIDI_Fg_* group already spells a
    # continuation.
    own = {}
    for s2, e2 in sorted(bounds.items()):
        if s2 in LABELS:
            continue
        ws = echo_index(rows, s2, e2)
        ccs = sorted(set(inv[w] for w in ws if w < len(inv) and inv[w] != 0xFF))
        if len(ccs) == 1:
            own[s2] = ccs[0]

    def _cc_name(cc):
        return "MidiOut_CC%02X_%s" % (cc, CC_SLUG.get(cc, "CC%02X" % cc))

    promoted = {}
    for s2, e2 in sorted(bounds.items()):
        if s2 in LABELS or s2 in own:
            continue
        kids = [t for t in own
                if any(s2 <= x < e2 for x in calls.get(t, ()))]
        ccs = sorted(set(own[t] for t in kids))
        if len(ccs) == 1 and len(kids) == 1:
            promoted[s2] = (ccs[0], kids[0])
    for s2, (cc, kid) in promoted.items():
        LABELS[s2] = _cc_name(cc)
        LABELS[kid] = _cc_name(cc) + "__emit"
    for s2, cc in own.items():
        LABELS.setdefault(s2, _cc_name(cc))
    for a2, _e2 in bounds.items():
        LABELS.setdefault(a2, "sub_%06X" % a2)

    # pass 2 -- the 32-record parameter tables, one label per SINGLE reader
    reader_of = {}
    for t in sorted(named):
        if not (0xFA84C8 <= t < 0xFA8CC8):
            continue
        ss = sorted(named[t])
        owners = sorted(set(r for r in bounds if any(r <= x < bounds[r] for x in ss)))
        reader_of[t] = (ss, owners)
        if len(ss) == 1 and len(owners) == 1:
            r = owners[0]
            base = ("MidiIn_CC%02X" % cc_of_handler[r]) if r in cc_of_handler \
                else LABELS[r]
            LABELS.setdefault(t, base + "_ParamTable")

    # pass 3 -- the prose
    for v, idxs in sorted(handler.items()):
        if v == 0xFA6378:
            continue
        tabs = [t for t, (ss, owners) in sorted(reader_of.items())
                if owners == [v]]
        if v not in cc_of_handler:
            rev = [inv[i] for i in idxs if i < len(inv) and inv[i] != 0xFF]
            body = ["%s -- MidiIn_ControllerHandlerTable[%s]"
                    % (LABELS[v], ", ".join(map(str, idxs))),
                    "",
                    "Called from: that table only.",
                    "Unknown: MidiIn_ControllerNumberToIndex sends NO controller",
                    "         number to this index, so nothing inbound says which"]
            if rev:
                body += ["         controller it is.  MidiIn_IndexToControllerNumber",
                         "         does name it -- 0x%02X -- but that map is only read"
                         % rev[0],
                         "         on the OUTBOUND side, so it is one witness and this",
                         "         file's rule is two.  Named sub_ deliberately."]
            else:
                body += ["         controller it is, and the reverse map leaves the",
                         "         index 0xFF too.  Named sub_ deliberately."]
            if tabs:
                body.append("Reads:   %s."
                            % ", ".join(LABELS.get(t, "0x%06X" % t) for t in tabs))
            HEADERS[v] = body
            continue
        cc = cc_of_handler[v]
        body = [
            "%s -- MIDI controller 0x%02X, %s"
            % (LABELS[v], cc,
               STANDARD_CC.get(cc, "not a GM-standard controller")),
            "",
            "Called from: MidiIn_ControllerHandlerTable[%s], and nothing else."
            % entry_list(["T[%d]" % i for i in idxs]).replace("T[", "")
                       .replace("]", ""),
            "Evidence: TWO independent witnesses give the controller number.",
            "         MidiIn_ControllerNumberToIndex[0x%02X] = %d selects this slot,"
            % (cc, idxs[0]),
            "         and MidiIn_IndexToControllerNumber[%d] reads back 0x%02X."
            % (idxs[0], inv[idxs[0]] if idxs[0] < len(inv) else 0xFF),
            "         The two maps are inverse on all %d live entries of the"
            % len(fwd),
            "         first (check M1).",
        ]
        if tabs:
            body.append("Reads:   %s, indexed by the part number (0x1976), 32"
                        % ", ".join(LABELS.get(t, "0x%06X" % t) for t in tabs))
            body.append("         records of stride %d."
                        % (3 if tabs[0] < 0xFA8B28 else 2))
        HEADERS[v] = body

    for s2, e2 in sorted(bounds.items()):
        if s2 in HEADERS or not LABELS[s2].startswith("MidiOut_CC"):
            continue
        if s2 in promoted:
            cc, kid = promoted[s2]
            w = echo_index(rows, kid, bounds[kid])[0]
            where = "its tail %s at 0x%06X ends" % (LABELS[kid], kid)
        else:
            w = echo_index(rows, s2, e2)[0]
            cc = inv[w]
            where = "it ends"
        H(s2,
          "%s -- echo controller 0x%02X (%s) outbound"
          % (LABELS[s2], cc, STANDARD_CC.get(cc, "not a GM-standard controller")),
          "",
          *(textwrap.wrap("Called from: " + entry_list(ents.get(s2)) + ".", 68,
                          subsequent_indent="         ")
            + textwrap.wrap("Evidence: %s in `ld W,0x%02x / calr "
                            "MidiOut_SendController`, which" % (where, w), 68,
                            subsequent_indent="         ")),
          "         maps the index through MidiOut_IndexToControllerNumber; entry",
          "         0x%02x of that map is 0x%02X.  Check E asserts this agrees with"
          % (w, cc),
          "         the inbound handler's controller number wherever one calls it.")

    # the three tables read by handlers that are not per-CC, plus the two
    # tables with TWO readers, which therefore cannot be named after one.
    LABELS.setdefault(0xFA8BA8, "MidiIn_ProgramChange_ParamTable")
    LABELS.setdefault(0xFA8BE8, "MidiIn_PitchBend_ParamTable")
    LABELS.setdefault(0xFA8C28, "MidiIn_ChannelPressure_ParamTable")
    for a2, who in ((0xFA8BA8, "MidiIn_ProgramChange 0xFA6DB9"),
                    (0xFA8BE8, "MidiIn_PitchBend 0xFA6E10"),
                    (0xFA8C28, "MidiIn_ChannelPressure 0xFA6E97")):
        H(a2,
          "%s -- 32 LE16 parameter ids, one per part" % LABELS[a2],
          "",
          "Read by: %s, its only reader." % who)

    # ---- round 12: the listing's names win over the generated ones -------
    # (the table and its argument are at module scope, above structure())
    for _a2, _n in LABELS_FROM_LISTING.items():
        LABELS[_a2] = _n

# ------------------------------------------------------------------- emission
_SLOT = re.compile(r"^(.*)\[(\d+)\]$")


def entry_tag(items):
    """`; entry: ...`, with consecutive slots of one table collapsed.

    MidiIn_NullHandler alone is named by 33 slots across four tables; printing
    them one by one buries the code, and truncating them loses the fact that
    they are RUNS."""
    if not items:
        return ""
    tabs, other = collections.OrderedDict(), []
    for it in items:
        m = _SLOT.match(it)
        if m:
            tabs.setdefault(m.group(1), []).append(int(m.group(2)))
        else:
            other.append(it)
    parts = []
    for t, idxs in tabs.items():
        runs, idxs = [], sorted(idxs)
        i = 0
        while i < len(idxs):
            j = i
            while j + 1 < len(idxs) and idxs[j + 1] == idxs[j] + 1:
                j += 1
            runs.append("%d" % idxs[i] if i == j else "%d-%d" % (idxs[i], idxs[j]))
            i = j + 1
        parts.append("%s[%s]" % (t, ",".join(runs)))
    return "   ; entry: " + "; ".join(parts + other)


def entry_list(items):
    """The same collapsing, for use inside a header's `Called from:` line."""
    return entry_tag(items)[len("   ; entry: "):] if items else "NOTHING FOUND"


def fmt_code(a, e, ev):
    lines, okk, _stats = RT.emit_block(a, e)
    if not okk:
        sys.exit("REFUSING TO EMIT: roundtrip could not prove 0x%06X-0x%06X" % (a, e))
    u = {addr: t for addr, _bs, t in RT.unidasm_range(a, e)}
    out = []
    for text, addr, bs, why in lines:
        if addr is None:
            out.append(text)
            continue
        if addr in HEADERS:
            out.append("")
            out.append("; " + "-" * 69)
            for l in HEADERS[addr]:
                out.append(("; " + l).rstrip())
            out.append("; " + "-" * 69)
        if addr in LABELS:
            out.append("%s:%s" % (LABELS[addr], entry_tag(ev.get(addr))))
        raw = " ".join("%02x" % b for b in bs)
        note = ""
        if why in ("llvm", "macro", "byte") and u.get(addr):
            note = "   " + u[addr]
        out.append("%-46s ; %06X  %s%s" % (text, addr, raw, note))
    return out


def records_of(a, e):
    """The eleven 12-byte MidiOut_ChangeRecords, one row each, with the two
    routine pointers resolved."""
    out = []
    for x in range(a, e, 12):
        if x in HEADERS:
            out.append("")
            out.append("; " + "-" * 69)
            for l in HEADERS[x]:
                out.append(("; " + l).rstrip())
            out.append("; " + "-" * 69)
        if x in LABELS:
            out.append(LABELS[x] + ":")
        row = rom()[x - A_BASE:x + 12 - A_BASE]
        f1, f2 = w32(x), w32(x + 4)
        out.append("\t.byte " + ", ".join("0x%02x" % b for b in row)
                   + "   ; %06X  %s / %s  id 0x%04X val 0x%04X"
                   % (x, LABELS.get(f1, "0x%06X" % f1),
                      LABELS.get(f2, "0x%06X" % f2), w16(x + 8), w16(x + 10)))
    return out


def rows_of(a, e, width, kind):
    """Emit `.byte` rows of at most `width`, never crossing a label."""
    out, x = [], a
    d = rom()
    while x < e:
        stop = min(x + width, e)
        for y in range(x + 1, stop):
            if y in LABELS:
                stop = y
                break
        if x in HEADERS:
            out.append("")
            out.append("; " + "-" * 69)
            for l in HEADERS[x]:
                out.append(("; " + l).rstrip())
            out.append("; " + "-" * 69)
        if x in LABELS:
            out.append(LABELS[x] + ":")
        row = d[x - A_BASE:stop - A_BASE]
        out.append("\t.byte " + ", ".join("0x%02x" % b for b in row)
                   + "   ; %06X" % x)
        x = stop
    return out


def longs_of(a, e, kind):
    out = []
    n = PTAB_N.get(a)
    for x in range(a, e, 4):
        if x in HEADERS:
            out.append("")
            out.append("; " + "-" * 69)
            for l in HEADERS[x]:
                out.append(("; " + l).rstrip())
            out.append("; " + "-" * 69)
        if x in LABELS:
            out.append(LABELS[x] + ":")
        v = w32(x)
        base = max([b for b in sorted(LABELS) if b <= x and (b in PTAB_N or
                    PARTTAB_BASE <= b < 0xFA9C78 or b in (0xFA82DE, 0xFA83C0))]
                   or [a])
        i = (x - base) // 4
        tag = ""
        if kind == "ptrtab":
            if LO <= v < HI:
                tag = "   -> %s" % LABELS.get(v, "0x%06X" % v)
            elif v == 0xFFFFFFFF:
                tag = "   empty slot"
        else:
            tag = "   RAM 0x%04X" % v if v < 0x10000 else ""
        out.append("\t.long 0x%08X                            ; %06X  [%d]%s"
                   % (v, x, i, tag))
    return out


def emit(segs, ev):
    out = []
    for kind, a, n in segs:
        e = a + n
        if kind == "code":
            out += fmt_code(a, e, ev)
            continue
        label = {"fill": "0x0E pad", "zero": "0x00 pad", "align": "alignment pad",
                 "ptrtab": "pointer table", "ramtab": "RAM-address table",
                 "holey": "sparse byte map", "recarr": "32-record parameter tables",
                 "recblock": "12-byte records", "ident": "identity map",
                 "thunktab": "entry thunks", "data": "message templates"}.get(kind, kind)
        out.append("")
        out.append("; --- 0x%06X-0x%06X  %s (%d bytes) ---" % (a, e - 1, label, n))
        if kind in ("fill", "zero"):
            vals = set(rom()[a - A_BASE:e - A_BASE])
            if len(vals) != 1:
                sys.exit("REFUSING TO EMIT: 0x%06X-0x%06X is not one value" % (a, e))
            out.append("\t.fill %d, 1, 0x%02X" % (n, vals.pop()))
        elif kind in ("ptrtab", "ramtab"):
            out += longs_of(a, e, kind)
        elif kind == "recblock":
            out += records_of(a, e)
        elif kind == "recarr":
            out += rows_of(a, e, 12, kind)
        else:
            out += rows_of(a, e, 16, kind)
    return out


# ------------------------------------------------------------------- selftest
def check(msg, got, want):
    ok = got == want
    print("  %-66s %-24s %s" % (msg, repr(got)[:24], "OK" if ok else
                                "FAILED (want %r)" % (want,)))
    return 0 if ok else 1


def selftest():
    segs = layout()
    structure()
    rows, named, calls, jumps = census(segs)
    fwd, inv = cc_maps()
    bad = 0
    print("A. the layout has not moved")
    bad += check("segments", len(segs), EXPECTED)
    bad += check("they tile the span", sum(n for _k, _a, n in segs), HI - LO)
    print("A2. no label of this file appears TWICE in prom_a/wsa1_prom_a.s")
    # ⚠ Written as `at most once`, not `absent`, on purpose: once the region is
    # spliced every label below IS in that file, and a check that only passes
    # before the splice stops being a check the moment it matters.
    have = collections.Counter(
        re.findall(r"^([A-Za-z_][A-Za-z0-9_]*):",
                   open(image_path(ROOT, "prom_a/wsa1_prom_a.s")).read(), re.M))
    bad += check("labels appearing more than once",
                 sorted(v for v in set(LABELS.values()) if have[v] > 1), [])
    bad += check("... and the region is spliced in (each appears once)",
                 sum(1 for v in set(LABELS.values()) if have[v] == 1),
                 len(set(LABELS.values())))
    bad += check("A3 in-span relative targets dropped so the layout cannot read "
                 "its own output", _REL_DROPPED[0] > 0, True)
    bad += check("labels are unique among themselves",
                 len(set(LABELS.values())), len(LABELS))
    print("B. the 25 part-record pointer blocks")
    miss = [k for k in range(PARTTAB_BLOCKS)
            if not named.get(PARTTAB_BASE + k * 128)]
    bad += check("B1 blocks with no naming instruction", miss, [])
    bad += check("B1 the two the layout's --sites misses are named here",
                 sorted("0x%06X" % s for s in
                        named[0xFA97F8] | named[0xFA9878]),
                 ["0x%06X" % 0xFA790E, "0x%06X" % 0xFA793E])
    blk0 = rom()[PARTTAB_BASE - A_BASE:PARTTAB_BASE - A_BASE + 128]
    bad += check("B2 all 25 blocks byte-identical",
                 all(rom()[PARTTAB_BASE - A_BASE + k * 128:
                           PARTTAB_BASE - A_BASE + (k + 1) * 128] == blk0
                     for k in range(PARTTAB_BLOCKS)), True)
    bad += check("B3 the cycle ends where the 0x00 pad starts",
                 "0x%06X" % (PARTTAB_BASE + PARTTAB_BLOCKS * 128), "0xFA9C78")
    vals = [w32(PARTTAB_BASE + 4 * i) for i in range(PARTTAB_N)]
    bad += check("B4 first entry", "0x%X" % vals[0], "0x76AF")
    bad += check("B4 LAST entry", "0x%X" % vals[-1], "0x7EAF")
    steps = collections.Counter(vals[i + 1] - vals[i] for i in range(31))
    bad += check("B4 steps", dict(steps), {0x40: 30, 0x80: 1})
    print("C. every pointer table's length has two independent pins")
    for b, n, pin, ab in PTAB:
        bad += check("C %s: %d entries end at" % (LABELS.get(b, "0x%06X" % b), n),
                     "0x%06X" % (b + 4 * n), "0x%06X" % ab)
    for b, n, pin, ab in RAMTAB:
        bad += check("C %s: %d entries end at" % (LABELS.get(b, "0x%06X" % b), n),
                     "0x%06X" % (b + 4 * n), "0x%06X" % ab)
    print("D. the controller maps")
    bad += check("M1 live entries of MidiIn_ControllerNumberToIndex", len(fwd), 23)
    bad += check("M1 they are inverse on every one of them",
                 [cc for cc, i in fwd.items() if inv[i] != cc], [])
    extra = [i for i in range(48) if inv[i] != 0xFF and inv[i] not in fwd]
    bad += check("M1 indices the reverse map adds", extra, [16, 17])
    bad += check("M1 ... and both of those point at a bare `ret`",
                 ["0x%06X" % w32(0xFA62B8 + 4 * i) for i in extra],
                 ["0xFA6459", "0xFA645A"])
    bad += check("M1 those two bytes ARE `ret`",
                 [by(0xFA6459), by(0xFA645A)], [0x0E, 0x0E])
    print("E. the echo pairing -- the check that makes both halves nameable")
    ents = entry_points(segs)
    bounds = {s: e for s, e in routine_bounds(segs, set(ents))}
    pairs, mism = 0, []
    handler = {}
    for i in range(48):
        handler.setdefault(w32(0xFA62B8 + 4 * i), []).append(i)
    for v, idxs in handler.items():
        ccs = set(inv[i] for i in idxs if inv[i] != 0xFF)
        if len(ccs) != 1 or v not in bounds:
            continue
        cc_in = ccs.pop()
        for t in sorted(calls):
            if not any(v <= s < bounds[v] for s in calls[t]):
                continue
            ws = echo_index(rows, t, bounds.get(t, t))
            if not ws:
                # the echo routine calls a helper; follow one level
                sub = [x for x in calls if any(t <= s < bounds.get(t, t)
                                               for s in calls[x])]
                ws = [w for x in sub for w in echo_index(rows, x, bounds.get(x, x))]
            outs = set(inv[w] for w in ws if w < 48 and inv[w] != 0xFF)
            if not outs:
                continue
            pairs += 1
            if outs != {cc_in}:
                mism.append((cc_in, sorted(outs), "0x%06X" % t))
    bad += check("E pairs found", pairs, 9)
    bad += check("E in-controller == out-controller in every pair", mism, [])
    print("E2. the RPN pairing -- inbound compare literal == outbound BC literal")
    for a2, rpn in ((0xFA7353, 2), (0xFA738F, 1), (0xFA73D1, 0)):
        cls = [i for i in range(17) if w32(0xFA7180 + 4 * i) == a2]
        bad += check("E2 %s is class %s" % (LABELS[a2], cls), len(cls), 1)
    # The inbound side pairs `cp WA,0x808n` with `jr Z,<addr>` and the class
    # number is the `ld B,<n>` AT THAT ADDRESS -- the three compares all precede
    # the three loads, so reading them in address order pairs them wrongly.
    body = {a2: t for a2, _bs, t in rows if 0xFA6B65 <= a2 < 0xFA6BF5}
    seq = sorted(body)
    inb = {}
    for i, a2 in enumerate(seq[:-1]):
        m = re.match(r"cp WA,0x80([0-9a-f]{2})$", body[a2])
        if not m:
            continue
        j = re.match(r"jr Z,0x([0-9a-f]{6})$", body[seq[i + 1]])
        if not j:
            continue
        tgt = body.get(int(j.group(1), 16), "")
        k = re.match(r"ld B,0x([0-9a-f]+)$", tgt)
        if k:
            inb[int(m.group(1), 16) & 0x7F] = int(k.group(1), 16)
    bad += check("E2 inbound RPN -> class", inb, {0: 11, 1: 10, 2: 9})
    bad += check("E2 outbound class -> RPN",
                 {[i for i in range(17) if w32(0xFA7180 + 4 * i) == a2][0]: r
                  for a2, r in ((0xFA7353, 2), (0xFA738F, 1), (0xFA73D1, 0))},
                 {9: 2, 10: 1, 11: 0})
    print("F. counts quoted in headers")
    n_null = sum(1 for i in range(48) if w32(0xFA62B8 + 4 * i) == 0xFA6378)
    bad += check("N1 MidiIn_NullHandler slots in the 48-entry table", n_null, 21)
    n_null2 = sum(1 for i in range(17) if w32(0xFA7180 + 4 * i) == 0xFA6378)
    bad += check("N1 ... and in the 17-entry class table", n_null2, 5)
    n_ign = sum(1 for i in range(192) if w32(0xFA8CC8 + 4 * i) == 0xFA7129)
    bad += check("N2 MidiOut_Param_Ignore slots of 192", n_ign, 111)
    bad += check("N2 MidiOut_ParamDispatch slots of 192",
                 sum(1 for i in range(192) if w32(0xFA8CC8 + 4 * i) == 0xFA7172), 29)
    print("G. the twins, with the differing count stated")
    t1 = sum(1 for i in range(97) if by(0xFA6018 + i) != by(0xFA60C2 + i))
    bad += check("T1 MidiIn_PumpPortA vs PumpPortB over 97 bytes", t1, 4)
    t2 = sum(1 for i in range(0x28) if by(0xFA609A + i) != by(0xFA6123 + i))
    bad += check("T2 FetchMessage_PortA vs PortB over 0x28 bytes", t2, 4)
    bad += check("T2 the port tag is one of them",
                 (by(0xFA60A7), by(0xFA6130)), (0x00, 0x10))
    t3 = sum(1 for i in range(17) if by(0xFA6068 + i) != by(0xFA6112 + i))
    bad += check("T3 sub_FA6068 vs sub_FA6112 over 17 bytes", t3, 0)
    print("H. the fourteen-byte hole is fully accounted for")
    seg = [s for s in segs if s[0] == "data"]
    bad += check("H one data segment", [("0x%06X" % a, n) for _k, a, n in seg],
                 [("0xFA5CB8", 14)])
    bad += check("H 2 + 7 + 5 = 14", 2 + 7 + 5, 14)
    bad += check("H MIDI_SysExHeader", list(rom()[0xFA5CB8 - A_BASE:0xFA5CBA - A_BASE]),
                 [0xF0, 0x50])
    bad += check("H MIDI_BankProgramTemplate",
                 list(rom()[0xFA5CBA - A_BASE:0xFA5CC1 - A_BASE]),
                 [0xB0, 0x00, 0x00, 0x20, 0x00, 0xC0, 0x00])
    bad += check("H MIDI_AllNotesOffTemplate",
                 list(rom()[0xFA5CC1 - A_BASE:0xFA5CC6 - A_BASE]),
                 [0xB0, 0x7B, 0x00, 0x79, 0x00])
    bad += check("H each has exactly one naming site",
                 [len(named[x]) for x in (0xFA5CB8, 0xFA5CBA, 0xFA5CC1)], [1, 1, 1])
    print("I. the small maps")
    bad += check("I1 MidiIn_PartIdentityMap is 0x00..0x1F, checked whole",
                 list(rom()[0xFA8C68 - A_BASE:0xFA8C88 - A_BASE]), list(range(32)))
    live = [i for i in range(256) if by(0xFA7FFE + i) != 0xFF]
    bad += check("I2 MidiOut_ChangeIndexMap live positions", len(live), 9)
    bad += check("I2 its live VALUES, max 10",
                 sorted(set(by(0xFA7FFE + i) for i in live)),
                 [0, 1, 2, 3, 4, 5, 6, 7, 10])
    bad += check("I2 so records 8 and 9 are unreachable through it",
                 sorted(set(range(11)) - set(by(0xFA7FFE + i) for i in live)), [8, 9])
    print("J. MidiOut_PartFlagsTable is the same records at +0x26")
    bad += check("P2 all 32 entries", [w32(0xFA82DE + 4 * i) - w32(PARTTAB_BASE + 4 * i)
                                       for i in range(32)], [0x26] * 32)
    print("K. the reset table")
    bad += check("R1 ten entries, 0x19F0 in steps of 0x10",
                 [w32(0xFA83C0 + 4 * i) for i in range(10)],
                 [0x19F0 + 0x10 * i for i in range(10)])
    ven = [int(t[7:], 16) for a2, _bs, t in rows
           if 0xFA81AE <= a2 < 0xFA81FC and t.startswith("calr 0x")]
    bad += check("R2 the eleven veneers fill 0x19F0 in steps of 0x10",
                 [w32(v + 1) for v in ven], [0x19F0 + 0x10 * i for i in range(11)])
    bad += check("R2 and the tenth+first ten are exactly the reset table",
                 [w32(v + 1) for v in ven[:10]],
                 [w32(0xFA83C0 + 4 * i) for i in range(10)])
    bad += check("R1 MidiIn_RebuildPartLists builds ELEVEN, one more than that",
                 len([1 for a, _bs, t in rows if 0xFA81AE <= a < 0xFA81FC
                      and t.startswith("calr")]), 11)
    print("S. the census this file ships")
    sem = sum(1 for v in LABELS.values() if not v.startswith("sub_"))
    # ⚠ RE-PINNED IN ROUND 12, and the reason is stated so the new numbers are
    # not a tolerance chosen to pass.  LABELS_FROM_LISTING adds the two labels
    # this file never had (sub_FA78FF, sub_FA792F) and turns fifteen sub_XXXXXX
    # into content names, so 227 -> 229 and 192 -> 207 = 192 + 15.  The
    # DECOMPOSITION is asserted below, not just the totals, because a bare
    # constant bumped until it passes is not a check.
    bad += check("S1 labels", len(LABELS), 229)
    bad += check("S1 of which semantic", sem, 207)
    bad += check("S1 and the two non-semantic ADDITIONS are the two dead gates",
                 sorted(a2 for a2, v in LABELS_FROM_LISTING.items()
                        if v.startswith("sub_")), [0xFA78FF, 0xFA792F])
    bad += check("S1 routine/object headers", len(HEADERS), 122)
    bad += check("S1 semantic labels with an Evidence: line in their header",
                 sum(1 for a2, h in HEADERS.items()
                     if not LABELS.get(a2, "sub_").startswith("sub_")
                     and any(l.startswith("Evidence:") for l in h)), 100)
    _emits = sorted(v for v in LABELS.values() if v.endswith("__emit"))
    bad += check("S2 `__emit` tails: check E's 9 controller echoes PLUS the two "
                 "that post a staged message", len(_emits), 11)
    bad += check("S2 and those two are exactly PitchBend and ChannelPressure",
                 [v for v in _emits if "CC" not in v],
                 ["MidiOut_ChannelPressure__emit", "MidiOut_PitchBend__emit"])
    print("L. every citation is at an INSTRUCTION, not at an operand")
    n, off = 0, 0
    for v in sorted(set(named) | set(calls)):
        for s in named.get(v, set()) | calls.get(v, set()):
            n += 1
            if by(s) not in NAMING_OPCODES:
                off += 1
    bad += check("L sites checked", n > 200, True)
    bad += check("L sites whose first byte is not a naming opcode", off, 0)
    print()
    print("%d checks, %d FAILED" % (n_checks(), bad))
    return 1 if bad else 0


_NC = [0]


def n_checks():
    return _NC[0]


_orig_check = check


def check(msg, got, want):        # noqa: F811  (counted wrapper)
    _NC[0] += 1
    return _orig_check(msg, got, want)


def sites_mode():
    segs = layout()
    structure()
    rows, named, calls, jumps = census(segs)
    print("named address   named by (INSTRUCTION addresses)")
    off = 0
    tot = 0
    for v in sorted(set(named) | set(calls)):
        s = sorted(named.get(v, set()) | calls.get(v, set()))
        tot += len(s)
        for x in s:
            if by(x) not in NAMING_OPCODES:
                off += 1
        print("  0x%06X %-34s %s" % (v, LABELS.get(v, ""),
                                     ", ".join("0x%06X" % x for x in s)))
    print("\n%d named addresses, %d naming sites; %d whose first byte is not a "
          "naming opcode" % (len(set(named) | set(calls)), tot, off))
    print("(0 means every citation is at an instruction, not at its operand)")


def main():
    segs = layout()
    if "--check" in ARGV:
        print("layout OK: %d segments tiling 0x%06X-0x%06X" % (len(segs), LO, HI))
        return 0
    if "--selftest" in ARGV:
        return selftest()
    if "--sites" in ARGV:
        sites_mode()
        return 0
    structure()
    ev = entry_points(segs)
    body = emit(segs, ev)
    text = "\n".join(body)

    # THE SELF-PROOF: assemble what we are about to print, compare with the ROM.
    got = RT.assemble_block(RT.macro_prelude() + "\n\t.text\n" + text + "\n")
    want = rom()[LO - A_BASE:HI - A_BASE]
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
        named_sem = sum(1 for v in LABELS.values() if not v.startswith("sub_"))
        print("segments by kind:", dict(c))
        print("bytes by kind:   ", dict(b))
        print("labels: %d  (%d semantic, %d sub_XXXXXX)"
              % (len(LABELS), named_sem, len(LABELS) - named_sem))
        ev_hdr = sum(1 for a2, h in HEADERS.items()
                     if not LABELS.get(a2, "sub_").startswith("sub_")
                     and any(l.startswith("Evidence:") for l in h))
        print("routine/object headers: %d" % len(HEADERS))
        print("semantic labels whose header carries an Evidence: line: %d" % ev_hdr)
        print("emitted lines: %d; re-assembles to the ROM exactly" % len(body))
        return 0
    print("; ==== 0xFA5AEB-0xFAA000 -- emitted by notes/gen_prom_a_fa5aeb_module.py ====")
    print("; Layout from notes/prom_a_fa5aeb_layout.py; names and counts from this")
    print("; emitter's --selftest (67 checks).  Run it before trusting any number in a")
    print("; header below.  This text was assembled and byte-compared with the ROM")
    print("; before printing.")
    print(";")
    print("; ⚠ SPLICING THIS REGION BREAKS THREE OF prom_a_fa5aeb_layout.py's OWN 123")
    print("; CHECKS, and none of them is a defect in the layout: `branches whose")
    print("; destination the .s states` pins 10037 and now reads 10588 because this")
    print("; region added its own relative branches to the corpus, and `residue runs`")
    print("; / `residue bytes` pin 1 and 14 and now read 3 and 108 because that file's")
    print("; build() seeds its descent from the .s and therefore now reads this text.")
    print("; This emitter neutralises that by dropping the relative targets whose citing")
    print("; instruction is inside the span (see _rel_targets_outside_span), which is")
    print("; why its own layout is still 42 segments and its residue still 1 run of 14")
    print("; bytes.  The three constants in that file need re-pinning by whoever owns it.")
    print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
