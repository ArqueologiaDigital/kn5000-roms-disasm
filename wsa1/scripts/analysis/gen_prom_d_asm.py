#!/usr/bin/env python3
"""Emit prom_d/wsa1_prom_d.s -- the whole 512 KiB image as structured assembly.

    python3 scripts/analysis/gen_prom_d_asm.py            # writes prom_d/wsa1_prom_d.s
    python3 scripts/analysis/gen_prom_d_asm.py --check    # regenerate to stdout only

prom_d is PURE DATA: 0 of its 64 vector slots are plausible, nothing in it
executes.  So this file is not a disassembly, it is a LAYOUT: every byte of the
image is emitted as .long / .short / .byte / .ascii inside a labelled region
whose record geometry is stated in a comment above it.

WHY A GENERATOR.  The payload is 330,505 bytes of records; hand-typing it would
be an unreviewable diff and would rot the first time a boundary moved.  The .s
it writes is the artefact the build consumes and the gate certifies -- this
script only produces it.  Re-running it must leave the gate green:

    python3 scripts/analysis/gen_prom_d_asm.py
    python3 scripts/analysis/assert_byte_identical.py

The region boundaries come from the image's own 48-slot directory at file
0x0000, plus the record strides established in
scripts/analysis/prom_d_tone_database.py.  Nothing is hard-coded that the
directory can supply, and the script ASSERTS that its region list tiles
0x00000-0x80000 with no gap and no overlap before it writes anything.

⚠ The gate is blind to a wrong NAME.  The region names here are transplanted
from ../kn5000-roms-disasm/table_data/tone_database_directory.s, which names the
same directory slots in the KN5000's tone database.  They are HYPOTHESES: no
WSA1 instruction that reads any of these structures has been found, and prom_d's
base address is not established.  Slots whose prom_d content does not match the
KN5000 role are named for what they contain, not for the KN5000 label.
"""
import collections
import itertools
import os
import re
import struct
import sys

# ⚠ THE notes MODULES LOADED BELOW PRINT THEIR CHECK RESULTS AT IMPORT TIME, and
# that chatter used to land in whatever this script wrote to stdout: the first
# `--monolithic` run put twelve lines of "all 78 checks held" at the top of what
# was supposed to be a byte-exact baseline.  When a machine-readable rendering is
# asked for, the chatter goes to stderr and the rendering goes to the real
# stdout.  (`--check` had the same latent defect and is fixed by the same line.)
_STDOUT = sys.stdout
if "--monolithic" in sys.argv or "--check" in sys.argv:
    sys.stdout = sys.stderr

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "original_ROMs", "wsa1_prom_d.bin")
OUT = os.path.join(ROOT, "prom_d", "wsa1_prom_d.s")

D = open(SRC, "rb").read()
assert len(D) == 0x80000
u16 = lambda o: struct.unpack_from("<H", D, o)[0]
u32 = lambda o: struct.unpack_from("<I", D, o)[0]
DIR = [u32(4 * i) for i in range(48)]
S = lambda slot: DIR[slot // 4]

PTRS = [u32(0xB80 + 4 * i) for i in range(274)]
NAME = lambda p: D[p:p + 16].decode("latin1")

# ---------------------------------------------------------------------------
# The descriptor-block layout is RE-DERIVED on every run by
# notes/prom_d_structures_round2.py, from the descriptors' own 32-bit offsets --
# it is never hard-coded here.  This emitter REFUSES to run if the shape it gets
# differs from the one that was audited, so a boundary cannot move silently
# between the audit and the assembly (the pattern of
# notes/gen_prom_a_fad800_module.py).
# ---------------------------------------------------------------------------
import importlib.util as _ilu

_spec = _ilu.spec_from_file_location(
    "prom_d_structures_round2",
    os.path.join(ROOT, "notes", "prom_d_structures_round2.py"))
_R2 = _ilu.module_from_spec(_spec)
_saved_argv, sys.argv = sys.argv, ["prom_d_structures_round2", "--quiet"]
try:
    _spec.loader.exec_module(_R2)
finally:
    sys.argv = _saved_argv

DESC_AUDITED = {0x30: (318, 0x23E9F), 0x38: (161, 0x4426A), 0x70: (4, 0x44B26)}
DESC = {}
for _slot in DESC_AUDITED:
    _H, _P, _recs = _R2.desc_layout(_slot)
    if (_H, _P) != DESC_AUDITED[_slot]:
        sys.exit("REFUSING TO EMIT: descriptor block +0x%02X is now %d records over a "
                 "pool at 0x%05X; audited as %d over 0x%05X.  Re-audit with "
                 "notes/prom_d_structures_round2.py before regenerating."
                 % (_slot, _H, _P, DESC_AUDITED[_slot][0], DESC_AUDITED[_slot][1]))
    DESC[_slot] = (_H, _P, _recs)

CURVE_BASE, CURVE_STRIDE, CURVE_N = _R2.CURVE_BASE, _R2.CURVE_STRIDE, _R2.CURVE_N
if CURVE_BASE != S(0x28) + 2048 or CURVE_N * CURVE_STRIDE != S(0x30) - CURVE_BASE:
    sys.exit("REFUSING TO EMIT: the curve bank moved.")

# ---------------------------------------------------------------------------
# ★ WAVE 7 ROUND 3.  Who READS this image?  notes/prom_d_documentation_round3.py
# runs the census -- every `ld X<r>,(0x00d7ed|0x00d7f1)` in prom_c, which is
# prom_d's base 0x00F00000, followed by a load from (X<r> + directory slot) --
# and re-decodes every hit from prom_c's ROM BYTES at the address it cites.
# The Evidence: lines below are GENERATED from that census, so a citation in the
# assembly cannot outlive the measurement that justifies it.  This emitter
# refuses to run if the census shape moved.
# ---------------------------------------------------------------------------
_spec3 = _ilu.spec_from_file_location(
    "prom_d_documentation_round3",
    os.path.join(ROOT, "notes", "prom_d_documentation_round3.py"))
_R3 = _ilu.module_from_spec(_spec3)
_saved_argv, sys.argv = sys.argv, ["prom_d_documentation_round3", "--quiet"]
try:
    _spec3.loader.exec_module(_R3)
finally:
    sys.argv = _saved_argv
if (len(_R3.ALL_HITS), len({h[2] for h in _R3.ALL_HITS})) != _R3.AUDITED:
    sys.exit("REFUSING TO EMIT: the prom_c directory-read census is now %d sites "
             "over %d slots; audited as %s.  Re-audit with "
             "notes/prom_d_documentation_round3.py before regenerating."
             % (len(_R3.ALL_HITS), len({h[2] for h in _R3.ALL_HITS}), _R3.AUDITED))

# ---------------------------------------------------------------------------
# ★ WAVE 7 ROUND 4.  What are these arrays FOR?  notes/prom_d_understanding_round4.py
# proves the descriptor pools are the two stages of a THREE-STAGE INDEX CHAIN --
# curve (128 entries) -> part A (exactly max(curve)+1 entries) -> part B (exactly
# max(part A)+1 elements of 6 or 8 bytes, chosen by the descriptor's tag bit 7) --
# with no slack at either join, in 318/318 and 161/161 descriptors.  That is what
# lets the pool labels below say what an object IS instead of where it sits.
# This emitter refuses to run if either join stopped holding.
# ---------------------------------------------------------------------------
_spec4 = _ilu.spec_from_file_location(
    "prom_d_understanding_round4",
    os.path.join(ROOT, "notes", "prom_d_understanding_round4.py"))
_R4 = _ilu.module_from_spec(_spec4)
_saved_argv, sys.argv = sys.argv, ["prom_d_understanding_round4", "--quiet"]
try:
    _spec4.loader.exec_module(_R4)
finally:
    sys.argv = _saved_argv
CHAIN = {}
for _slot, _audited in _R4.AUDITED_CHAIN.items():
    _rows = [r for r in _R4.chain(_slot) if r]
    _joined = sum(1 for r in _rows if r["ecount"] == max(r["a_tab"]) + 1)
    if (len(_rows), _joined) != _audited:
        sys.exit("REFUSING TO EMIT: the round-4 index chain at slot +0x%02X is now "
                 "%d descriptors with %d joins; audited as %s.  Re-audit with "
                 "notes/prom_d_understanding_round4.py before regenerating."
                 % (_slot, len(_rows), _joined, _audited))
    CHAIN[_slot] = {r["i"]: r for r in _rows}
# ---------------------------------------------------------------------------
# ★ WAVE 7 ROUND 5.  notes/prom_d_understanding_round5.py answers the question
# round 4 left: WHICH of the 622 still-framed labels sit on an object that
# carries a name at all.  614 do not and stay framed WITH THE GAP STATED; 8 are
# promoted, and both promotions DERIVE the label from the bytes rather than
# asserting it -- the program-map rows from what they select, the descriptor
# curves from their own run lengths.  This emitter refuses to run if either
# derivation stopped producing the audited names.
# ---------------------------------------------------------------------------
_spec5 = _ilu.spec_from_file_location(
    "prom_d_understanding_round5",
    os.path.join(ROOT, "notes", "prom_d_understanding_round5.py"))
_R5 = _ilu.module_from_spec(_spec5)
_saved_argv, sys.argv = sys.argv, ["prom_d_understanding_round5", "--quiet"]
try:
    _spec5.loader.exec_module(_R5)
finally:
    sys.argv = _saved_argv
CURVE_NAME = _R5.curve_names()
ROW_NAME = _R5.row_names()
PERC_OVERLAP = _R5.perc_overlap()
if tuple(CURVE_NAME[_k] for _k in sorted(CURVE_NAME)) != _R5.AUDITED_CURVES:
    sys.exit("REFUSING TO EMIT: the derived curve names are now %s; audited as %s.  "
             "Re-audit with notes/prom_d_understanding_round5.py."
             % (tuple(CURVE_NAME[_k] for _k in sorted(CURVE_NAME)), _R5.AUDITED_CURVES))
if tuple(ROW_NAME[_r] for _r in sorted(ROW_NAME)) != _R5.AUDITED_ROWS:
    sys.exit("REFUSING TO EMIT: the derived program-map row names are now %s; "
             "audited as %s.  Re-audit with notes/prom_d_understanding_round5.py."
             % (tuple(ROW_NAME[_r] for _r in sorted(ROW_NAME)), _R5.AUDITED_ROWS))
if PERC_OVERLAP != _R5.AUDITED_PERC:
    sys.exit("REFUSING TO EMIT: the slot +0x20 / drum-instrument overlap is now %s; "
             "audited as %s.  Re-audit with notes/prom_d_understanding_round5.py."
             % (PERC_OVERLAP, _R5.AUDITED_PERC))
# ---------------------------------------------------------------------------
# ★ WAVE 14.  What the +0x70 pools ARE.  notes/prom_d_drawbar_chain.py answers
# the question rounds 2-5 all left open, and it answers it FROM THE READER: the
# 6-byte stride is prom_c's literal `mul WA,0x0006` at 0xFA82C2 and the 729 is
# its base-9 index `n2*81 + n1*9 + n0` at 0xFC355B, over three 0..8 nibbles that
# sub_FC28B5 lifts out of the element block at 0xFC28F3/0xFC28FA.  Nothing here
# is a stride found in the bytes.  This emitter refuses to run if any of it
# moved.
# ---------------------------------------------------------------------------
_spec14 = _ilu.spec_from_file_location(
    "prom_d_drawbar_chain",
    os.path.join(ROOT, "notes", "prom_d_drawbar_chain.py"))
_R14 = _ilu.module_from_spec(_spec14)
_saved_argv, sys.argv = sys.argv, ["prom_d_drawbar_chain", "--quiet"]
try:
    _spec14.loader.exec_module(_R14)
finally:
    sys.argv = _saved_argv
DRAWBAR = _R14.DRAWBAR
if _R14.AUDIT != _R14.AUDITED_DRAWBAR:
    sys.exit("REFUSING TO EMIT: the slot +0x70 drawbar chain is now %s; audited "
             "as %s.  Re-audit with notes/prom_d_drawbar_chain.py."
             % (_R14.AUDIT, _R14.AUDITED_DRAWBAR))

# ---------------------------------------------------------------------------
# ★ WAVE 7 ROUND 6.  notes/prom_d_understanding_round6.py classifies ALL 614 of
# the labels round 5 left framed, and finds that 301 of them CAN be named after
# all -- by a mechanism round 5 ran and got a zero from.  Round 5 asked whether a
# wave-select record's 43 bytes occur anywhere else in the image and got 0 of 322,
# comparing all 43 bytes.  Round 5 had ALSO just proved that byte +0x0B is a
# preset number prom_c WRITES OVER.  Excluding that one field turns the zero into
# 167 records that are otherwise byte-identical to a NAMED tone record's own
# wave-select block -- and the difference is at +0x0B in 167 of 167, at no other
# position in any record, with 0 of 3,000 random windows matching.
# The same relation gives the +0x20 array 196 twins among the drum-instrument
# records, and prom_c's sub_FA72E9 names the +0xA8 table outright.
# This emitter refuses to run if any of the three shapes moved.
# ---------------------------------------------------------------------------
_spec6 = _ilu.spec_from_file_location(
    "prom_d_understanding_round6",
    os.path.join(ROOT, "notes", "prom_d_understanding_round6.py"))
_R6 = _ilu.module_from_spec(_spec6)
_saved_argv, sys.argv = sys.argv, ["prom_d_understanding_round6", "--quiet"]
try:
    _spec6.loader.exec_module(_R6)
finally:
    sys.argv = _saved_argv
for _slot, _aud in _R6.AUDITED_TWINS.items():
    _got = _R6._twin_shape(_slot)
    if _got != _aud:
        sys.exit("REFUSING TO EMIT: the wave-select twin census at slot +0x%02X is now "
                 "%s (records, twins, nameable); audited as %s.  Re-audit with "
                 "notes/prom_d_understanding_round6.py." % (_slot, _got, _aud))
if _R6._octave_shape() != _R6.AUDITED_OCTAVE:
    sys.exit("REFUSING TO EMIT: the +0xA8 octave table is now %s (rows, marked cells, "
             "values); audited as %s.  Re-audit with "
             "notes/prom_d_understanding_round6.py Q4."
             % (_R6._octave_shape(), _R6.AUDITED_OCTAVE))
TWIN = {_s: _R6.wavesel_twins(_s) for _s in (0x18, 0x20)}
# ---------------------------------------------------------------------------
# ★ WAVE 7 ROUND 7.  notes/prom_d_finish_round7.py is the whole-image inventory:
# every one of prom_d's labels gets one FINISHED verdict (witnessed, and how, or
# nameless, and why) and one PROVENANCE grade.  It also refines round 6's twin
# rule.  Round 6 accepted a shared stem when the candidate names differ only by a
# trailing DIGIT; the same catalogue spells the same relation with a trailing
# LETTER ('TimpaniA'..'TimpaniG'), which round 6's rule could not see.  Stated as
# a CamelCase WORD-BOUNDARY rule with a bounded remainder it names 10 more records
# and still refuses 60, including the truncations a looser rule would produce.
# This emitter refuses to run if that shape moved.
# ---------------------------------------------------------------------------
_spec7 = _ilu.spec_from_file_location(
    "prom_d_finish_round7",
    os.path.join(ROOT, "notes", "prom_d_finish_round7.py"))
_R7 = _ilu.module_from_spec(_spec7)
_saved_argv, sys.argv = sys.argv, ["prom_d_finish_round7", "--quiet"]
try:
    _spec7.loader.exec_module(_R7)
finally:
    sys.argv = _saved_argv
for _slot, _aud in _R7.AUDITED_R7.items():
    _got = _R7._r7_shape(_slot)
    if _got != _aud:
        sys.exit("REFUSING TO EMIT: the round-7 twin-label shape at slot +0x%02X is "
                 "now %s (round-6 names, round-7 names); audited as %s.  Re-audit "
                 "with notes/prom_d_finish_round7.py Q4."
                 % (_slot, _got, _aud))
# ★ WAVE 7 ROUND 8.  The DISJUNCTION: where the records carrying a mixer
# record's 43 bytes disagree on the name, the label now states ALL of them
# rather than none, when there are at most three.  It is the same measurement
# round 6 made and the same relation `_SameAs_` already claims; what changes is
# that the measured fact is in the label instead of only in the banner.
_spec8 = _ilu.spec_from_file_location(
    "prom_d_inventory_round8",
    os.path.join(ROOT, "notes", "prom_d_inventory_round8.py"))
_R8 = _ilu.module_from_spec(_spec8)
_saved_argv, sys.argv = sys.argv, ["prom_d_inventory_round8", "--quiet"]
try:
    _spec8.loader.exec_module(_R8)
finally:
    sys.argv = _saved_argv
for _slot, _aud in _R8.AUDITED_R8.items():
    _got = _R8._r8_shape(_slot)
    if _got != _aud:
        sys.exit("REFUSING TO EMIT: the round-8 label shape at slot +0x%02X is now "
                 "%s (round-7 names, round-8 names); audited as %s.  Re-audit with "
                 "notes/prom_d_inventory_round8.py Q3."
                 % (_slot, _got, _aud))
# ★ WAVE 7 ROUND 10.  M9, THE SELECTOR.  Round 6 measured the 1,024-entry map at
# slot +0x0C as a WITNESS for records the byte test had already named; it was
# never asked about the records the byte test MISSES, which is where every framed
# label in the +0x18 array is.  The label it produces says what it measured --
# `_SelectedFor_`, a statement about a MAP ENTRY, not about 43 bytes.
_got10 = _R8._r10_shape()
if _got10 != _R8.AUDITED_R10:
    sys.exit("REFUSING TO EMIT: the round-10 selector shape is now %s; audited as "
             "%s.  Re-audit with notes/prom_d_inventory_round8.py Q16-Q19."
             % (_got10, _R8.AUDITED_R10))
# ---------------------------------------------------------------------------
# ★★ WAVE 7 ROUND 11.  The SOUND GROUP.  notes/prom_d_inventory_round8.py Q21
# proves, from prom_a's own address arithmetic and prom_b's own tables, that
# this image's tone index is 8*group + member and that the group's name is
# prom_b's 16 ASCII bytes at 0xF068B4 + 16*group.  Nothing here is typed: the
# bases are the 32-bit immediates of prom_a instructions whose opcode byte is
# asserted at the cited address, the members-per-group is prom_a's own
# 16-byte/2-byte stride pair, and the group COUNT is where the inverse identity
# stops holding.  This emitter refuses to run if M10's label set moved.
# ---------------------------------------------------------------------------
_got11 = _R8._r11_shape()
if _got11 != _R8.AUDITED_R11:
    sys.exit("REFUSING TO EMIT: M10 now names %s; audited as %s.  Re-audit with "
             "notes/prom_d_inventory_round8.py Q22 before regenerating."
             % (_got11, _R8.AUDITED_R11))
# ---------------------------------------------------------------------------
# ★★ WAVE 7 ROUND 12.  THE COMPLETE INVENTORY OF WHAT IS STILL FRAMED, plus the
# two mechanisms nobody had run and the one cross-image find this round refused
# to spend.  notes/prom_d_finish_round12.py, 35 checks.
# ⚠ THE GUARD BELOW IS ON ROM FACTS, NOT ON A LABEL COUNT.  Round 6's Q8d was
# pinned to a framed count and went RED the moment a later round promoted a
# label -- a guard that punishes progress.  What is pinned here is the tail-only
# rule's zero, the size of prom_b's name table, and the phase test's direction:
# three things that must not move unless a ROM changed.
# ---------------------------------------------------------------------------
_spec12 = _ilu.spec_from_file_location(
    "prom_d_finish_round12",
    os.path.join(ROOT, "notes", "prom_d_finish_round12.py"))
_R12 = _ilu.module_from_spec(_spec12)
_saved_argv, sys.argv = sys.argv, ["prom_d_finish_round12", "--quiet"]
try:
    _spec12.loader.exec_module(_R12)
finally:
    sys.argv = _saved_argv
_m11 = _R12.m11()
_nm12, _n12, _pre12 = _R12.name_table()
_ph12 = _R12.pair_phase()
if (_m11[0], _m11[1]) != (0, 64) or _n12 != 64 or _pre12 or _ph12[2] < 0.85:
    sys.exit("REFUSING TO EMIT: a round-12 ROM fact moved -- tail-only rule %s, "
             "prom_b name table %d rows (row -1 printable: %s), phase AUC %.3f.  "
             "Re-audit with notes/prom_d_finish_round12.py --selftest."
             % (_m11[:2], _n12, _pre12, _ph12[2]))

GRP_LABEL = _R8.group_labels()
GRP_SETS = _R8.selector_groups()
GRP_NAME = _R8.group_name
GRP_MEMBERS = _R8.GROUP_MEMBERS
GRP_COUNT = _R8.GROUP_COUNT
GRP_RUN = _R8.GROUP_RUN
TONE_GROUP = _R8.tone_group
GRP_NAME_ADDR = _R8.GROUP_NAME_ADDR
GRP_MEMBER_ADDR = _R8.GROUP_MEMBER_ADDR
GRP_WORDHITS = len(_R8.group_word_alignment())
GRP_WORDNULL = max(len(_R8.group_word_alignment(_s))
                   for _s in range(2, _R8.GROUP_COUNT - 1))
GRP_BOUND = _R8.GROUP_BOUND

SEL_LABEL = _R8.selector_labels()
SEL_COLS = _R8.selector_columns()
SEL_NAMES = _R8.selector_names()
SEL_MAP_SLOT = _R8.SELECTOR_SLOT
MELODIC_ROWS = _R8.MELODIC_ROWS
SEL_MARGIN = _R8.selector_row_margin()      # (positions, best, best wrong) -- Q16d
SEL_READERS = _R8.selector_readers()        # (reads of +0x0C, reads of +0x18)
SEL_BUCKETS = _R8.selector_buckets()        # (named, unreached, too broad, digits)
SEL_NULL = _R8.selector_shuffle_null()      # (mean, max) over 20 shuffles -- Q16c
TWIN_LABEL = {_s: _R8.wavesel_labels_r8(_s) for _s in (0x18, 0x20)}
DISJ = {_s: _R8.disjunction_labels(_s) for _s in (0x18, 0x20)}
MAX_NAMES = _R8.MAX_NAMES
PRESET_REFS = _R8.preset_referrers()
ROW_DIFFS = {_r: _d for _r, _d in _R8.melodic_rows()}
ROW_NESTING = _R8.rows_are_nested()
MONOTONE = {_s: _R8.monotonicity(_s) for _s in (0x18, 0x20)}
ROUND8_CHECKS = _R8.AUDITED_CHECKS
ROUND7_LABELS = {_s: sorted(set(_R7.wavesel_labels_r7(_s)) - set(_R6.wavesel_labels(_s)))
                 for _s in (0x18, 0x20)}
ROUND7_CHECKS = _R7.NCHECK[0]
OCTAVE_ROWS = _R6.octave_rows()
ALIGN = _R6.catalogue_alignment()
if ALIGN != _R6.AUDITED_ALIGNMENT:
    sys.exit("REFUSING TO EMIT: the +0x8C catalogue alignment is now %s; audited as "
             "%s.  Re-audit with notes/prom_d_understanding_round6.py Q3e."
             % (ALIGN, _R6.AUDITED_ALIGNMENT))
ROUND6_CHECKS = _R6.NCHECK[0]


PRESET_IDX = _R5.wavesel_preset_index()
if PRESET_IDX != _R5.AUDITED_SELFIDX:
    sys.exit("REFUSING TO EMIT: the +0x3C array's self-index shape is now %s; audited "
             "as %s.  Re-audit with notes/prom_d_understanding_round5.py Q7."
             % (PRESET_IDX, _R5.AUDITED_SELFIDX))
ROUND5_CHECKS = _R5.NCHECK[0]


def CURVE_LABEL(k):
    """`ToneDB_DescCurve_<shape>` -- the suffix is DERIVED from the curve's own
    run lengths by notes/prom_d_understanding_round5.py curve_names(), which is
    why no curve name is typed anywhere in this file."""
    return "ToneDB_DescCurve_%s" % CURVE_NAME[k]


_TONE_NAMES, _PERC_NAMES = _R4.names()
if (len(_TONE_NAMES), len(_PERC_NAMES)) != _R4.AUDITED_NAMES:
    sys.exit("REFUSING TO EMIT: the record name census is now %s; audited as %s."
             % ((len(_TONE_NAMES), len(_PERC_NAMES)), _R4.AUDITED_NAMES))
CHAIN_CHECKS = _R4.NCHECK[0]


_PROG_SEL = _R4.prog_selectors()
_DRUM_A, _DRUM_B = _R4.drum_selectors()


def tone_hdr_lines(p, idx, extra):
    """The per-record header block: what it is called, and what can select it.

    Both numbers are measured, not decorative: the name is the record's own 16
    bytes and the selector count is how many of the 1,280 program-map entries at
    directory slot +0x04 hold this record's index.  round 4 Q6.
    """
    n = _PROG_SEL.get(idx, 0)
    # ★ ROUND 11: and what the PANEL calls it.  The group is not a property of
    # these bytes -- it is this record's INDEX read as GRP_MEMBERS*group + member,
    # which prom_a's own address arithmetic establishes (Q21).  Records outside the
    # table's identity run get the gap said, not a group guessed.
    g = TONE_GROUP(idx)
    grp = (["; ★ SOUND GROUP %d %r, member %d of %d -- what the panel calls this"
            % (g[0], GRP_NAME(g[0]).strip(), g[1], GRP_MEMBERS),
            "; tone.  Evidence: prom_b's group/member table at 0x%06X, entry k of"
            % GRP_MEMBER_ADDR,
            "; which is the (program, bank) pair that this image's own BankMap and",
            "; ToneNumBanks resolve to tone k (%d of %d consecutive entries); prom_a"
            % (GRP_RUN, GRP_RUN),
            "; strides it 16 bytes per group and 2 per member at 0xFC230C/0xFC2317,",
            "; so the index is %d*group + member; the name is prom_b's own 16 ASCII"
            % GRP_MEMBERS,
            "; bytes at 0x%06X + 16*%d.  notes/prom_d_inventory_round8.py Q21."
            % (GRP_NAME_ADDR, g[0])]
           if g is not None else
           ["; ⚠ NO SOUND GROUP: tone index %d is past the %d-entry run of prom_b's"
            % (idx, GRP_RUN),
            "; group/member table, so nothing in that table places it.  Q21."])
    return ["",
            "; ---- tone 0x%03X %r ----" % (idx, NAME(p)),
            "; %s" % extra,
            "; Selected by %d of the %d entries of the program map at directory"
            % (n, 10 * 128),
            "; slot +0x04.",
            "; Evidence: the record's address is ToneDB_ToneOffsetTable entry %d,"
            % idx,
            "; file 0x%05X; the program map holds no 0xFFFF and its values run"
            % (0xB80 + 4 * idx),
            "; 0..273 over that table's 274 entries, so the count above is the",
            "; number of times this record's index appears in it.  round 4 Q6a-Q6c."] + grp


def tone_name(p):
    """The CamelCase label suffix a tone record's OWN 16 ASCII bytes give it."""
    return _TONE_NAMES[p][1]


def perc_name(i):
    """The CamelCase label suffix drum-instrument record i's OWN 13 bytes give it."""
    return _PERC_NAMES[i][1]


CENSUS_N = len(_R3.ALL_HITS)
CENSUS_SLOTS = len({h[2] for h in _R3.ALL_HITS})
CENSUS_CHECKS = _R3.NCHECK[0]


# ---------------------------------------------------------------------------
# ★ SLOTS THE CENSUS CANNOT SEE, AND WHERE THEIR READER ACTUALLY IS.
#
# ⚠ THIS TABLE CORRECTS A SENTENCE THAT STOOD ON TWELVE BANNERS.  They read
# "⚠ Readers: NONE FOUND ... NOTHING in the WSA1 firmware confirms it", which
# turned round 3's own stated LOWER BOUND into an absence.  prom_c parks the base
# in a frame slot -- `ld (XIZ+0xF6),XWA` at 0xFB4616, three instructions after
# `ld XWA,(0x00D7F1)` at 0xFB4611 -- and reads six directory slots back through
# it.  Round 3's walk stops at the store, by design, so those six reads were
# never in the census and never could be.
#
# ⚠ THE CENSUS IS NOT CHANGED and neither is the provenance grade that rests on
# it: 99 reads over 33 slots is what THAT instrument measures, and re-scoping it
# is a round of its own.  What is corrected here is the SENTENCE, which claimed
# more than the instrument could support.  Every citation below re-decodes from
# prom_c's ROM bytes and is re-derived by notes/prom_d_desc_tag_bit67.py Q3.
PARKED_READER = {
    0x24: ["★ BUT A READER EXISTS OUTSIDE IT.  prom_c parks the base with",
           "`ld (XIZ+0xF6),XWA` at 0xFB4616 and reads this slot through the frame",
           "slot: `ld XWA,(XBC+0x24)` at 0xFB4668, feeding the tone-index lookup",
           "that produces a descriptor pointer.  The KN5000 name is no longer",
           "unconfirmed-by-everything, though the FIELD meanings still are."],
    0x28: ["★ BUT A READER EXISTS OUTSIDE IT: `ld XWA,(XBC+0x28)` at 0xFB46B3,",
           "through the base parked by `ld (XIZ+0xF6),XWA` at 0xFB4616."],
    0x2C: ["★ BUT A READER EXISTS OUTSIDE IT: `ld XWA,(XBC+0x2C)` at 0xFB468C,",
           "through the base parked by `ld (XIZ+0xF6),XWA` at 0xFB4616."],
    0x30: ["★ BUT A READER EXISTS OUTSIDE IT, and it is this block's: prom_c",
           "reads the slot with `ld XIY,(XBC+0x30)` at 0xFB466E through the base",
           "parked by `ld (XIZ+0xF6),XWA` at 0xFB4616, multiplies an index-map",
           "entry by the stride word with `mul XWA,(XIZ+0xEC)` at 0xFB46EB, adds",
           "the array and then the base, and hands the result to",
           "Voice_SelectKeyZone_Reg0040, which dereferences the descriptor's tag",
           "with `ld H,(XBC)` at 0xFA81F6.  So this block IS read, and the",
           "KN5000 name is corroborated rather than merely transplanted."],
    0x34: ["★ BUT A READER EXISTS OUTSIDE IT: `ld XIY,(XBC+0x34)` at 0xFB46B9,",
           "through the base parked by `ld (XIZ+0xF6),XWA` at 0xFB4616."],
    0x38: ["★ BUT A READER EXISTS OUTSIDE IT: `ld XIY,(XBC+0x38)` at 0xFB4692,",
           "through the base parked by `ld (XIZ+0xF6),XWA` at 0xFB4616, with the",
           "stride taken from +0xF2 by `ld WA,(XBC+0x00F2)` at 0xFB469D."],
}


def ev_slot(slot, extra=()):
    """Evidence: lines for a directory slot -- or an honest statement of none.

    Never invents a reader.  A slot with no reader gets the gap, spelled out,
    because an honest hole is worth more than a confident wrong name and this
    tree has paid for that lesson.
    """
    sites = _R3.readers(slot)
    if not sites:
        return ["",
                "⚠ Readers: NONE IN THE CENSUS.  notes/prom_d_documentation_round3.py",
                "walks every load of prom_d's base (0x00F00000, RAM 0x00D7ED /",
                "0x00D7F1) in prom_c and every directory slot read through it -- %d"
                % CENSUS_N,
                "reads over %d slots -- and directory slot +0x%02X is not among them."
                % (CENSUS_SLOTS, slot),
                "The census is a LOWER BOUND: by its own rule it does not follow a",
                "base parked in a frame slot."] + PARKED_READER.get(slot, [
                "So this region's NAME is still the KN5000 transplant and NOTHING in",
                "the WSA1 firmware confirms it."]) + list(extra)
    first = sites[0]
    breg = _R3.RSEQ[_R3.C[first[0] - _R3.PROM_C_BASE + 4] & 7]
    alias = [h for h in sites if h[2] != slot]
    lines = ["",
             "Evidence: prom_c reads directory slot +0x%02X at %d site%s.  The first is"
             % (slot, len(sites), "" if len(sites) == 1 else "s"),
             "0x%06X `ld X%s,(0x%06X)` -- prom_d's base 0x00F00000 -- followed at"
             % (first[0], breg, first[5]),
             "0x%06X by `ld %s,(X%s+0x%02X)`.  All %d: %s."
             % (first[1], first[4], breg, first[2], len(sites),
                ", ".join("0x%06X" % h[1] for h in sites)),
             "Every one re-decoded from prom_c's ROM bytes at the cited address by",
             "notes/prom_d_documentation_round3.py Q2 (%d reads over %d slots, 0 that"
             % (CENSUS_N, CENSUS_SLOTS),
             "fail to decode).  The base is a compile-time constant: the only two",
             "instructions in prom_c that write 0x00D7ED / 0x00D7F1 are 0xFB0523 and",
             "0xFB0528, both storing the 0x00F00000 loaded at 0xFB051E."]
    if alias:
        lines += ["Sites through alias slot%s %s are counted here: the alias holds the"
                  % ("" if len({h[2] for h in alias}) == 1 else "s",
                     ", ".join(sorted({"+0x%02X" % h[2] for h in alias}))),
                  "same value and therefore names the same object."]
    return lines + list(extra)


def ev_none(what, why):
    """A stated gap for something the census cannot speak to at all."""
    return ["", "⚠ NOT ESTABLISHED: %s." % what, "  %s" % why]


# --- the decoded chains, each one re-derived by round 3 from prom_c's bytes ---

def INDEXMAP_CHAIN(slot):
    if slot != 0x4C:
        return ["",
                "The chain this reader belongs to has NOT been decoded end to end.",
                "For the one that has -- slot +0x4C -- see its banner: the map value",
                "turns out to be a ROW NUMBER in a catalogue.  Whether that reading",
                "carries over to this map is NOT asserted here."]
    return [
        "",
        "★ AND ROUND 3 GIVES THIS MAP A ROLE, not just a value range.  One prom_c",
        "routine reads the map and then the catalogue at slot +0x8C, and what it",
        "does with the value is multiply it by the catalogue's row stride:",
        "    0xFC156D  ld XIY,(XWA+0x4c)     this map's file offset",
        "    0xFC1573  sll 0x07,BC           row * 128",
        "    0xFC1576  add BC,(XIZ+0x08)     + column",
        "    0xFC1579  mul BC,0x0002         * 2, so entries are LE16",
        "    0xFC157F  add XIY,(0x00d7ed)    + base",
        "    0xFC1584  ld BC,(XIY)           THE MAP VALUE",
        "    0xFC1589  cp BC,0xffff          0xFFFF is the 'no entry' sentinel",
        "    0xFC1594  ld XIY,(XWA+0x008c)   the +0x8C catalogue",
        "    0xFC163F  ld BC,0x0010          16 = that catalogue's ROW STRIDE",
        "    0xFC1642  mul XBC,(XIZ+0xf0)    * the map value",
        "    0xFC1645  add XBC,(XIZ+0xfc)    + the catalogue base -> the row",
        "So: (row, column) -> a row of ToneDB_PercSourceNameList1, 0xFFFF = none.",
        "notes/prom_d_documentation_round3.py Q4g decodes all sixteen instructions",
        "from the ROM bytes and checks 16 x %d against that catalogue's own footer."
        % (u16(S(0x90))),
    ]


def _pair(foot):
    for f, c, lb, lf, lc, cm, lcat in _R3.PAIRS:
        if f == foot:
            return (f, c, lb, lf, lc, cm, lcat)
    return None


def CATALOGUE_CHAIN(cat, foot):
    p = _pair(foot)
    if not p:
        return []
    _f, _c, lb, lf, lc, cm, lcat = p
    return [
        "",
        "★ AND THE COUNT IS ENFORCED BY prom_c, not just declared by the footer.",
        "One routine loads the footer, reads its first word, compares the caller's",
        "row index against it, and only then addresses THIS catalogue:",
        "    0x%06X  ld X..,(base+0x%02X)   the footer at slot +0x%02X" % (lf, foot, foot),
        "    0x%06X  ld IY,(X..)            its leading LE16 = %d" % (lc, u16(S(foot))),
        "    0x%06X  cp (XIZ+0x0a),IY       the row index against that count" % cm,
        "    0x%06X  ld X..,(base+0x%02X)   this catalogue" % (lcat, cat),
        "and %d is exactly the row count measured from the image (span / 16)."
        % u16(S(foot)),
        "All five catalogue/footer pairs are read this way; the five chains are",
        "checked byte for byte in notes/prom_d_documentation_round3.py Q4c.",
    ]


def FOOTER_CHAIN(foot, cat):
    p = _pair(foot)
    if not p:
        return []
    _f, _c, lb, lf, lc, cm, lcat = p
    return [
        "",
        "★ AND prom_c USES IT AS A BOUND.  0x%06X loads this footer, 0x%06X reads"
        % (lf, lc),
        "its leading LE16, 0x%06X compares the caller's row index against it, and" % cm,
        "0x%06X addresses the +0x%02X catalogue only on the in-range arm.  So the"
        % (lcat, cat),
        "LE16 is not merely equal to the row count: it IS the row count the",
        "firmware checks against.  notes/prom_d_documentation_round3.py Q4c.",
        "0xFC1967 / 0xFC196C additionally read the count AND the length byte at",
        "+0x02 of the +0x98 footer, which is this block's declared two-field head.",
    ]


def DESC_CHAIN(slot):
    if slot == 0x70:
        return [
            "",
            "★ AND THE 14-BYTE STRIDE IS prom_c's.  Its one reader does not use a",
            "literal; it reads the directory's OWN stride word and multiplies:",
            "    0xFC2995  ld XIY,(XWA+0x70)     this block's file offset",
            "    0xFC299A  ld BC,(XWA+0x00ec)    the stride word = %d" % u16(0xEC),
            "    0xFC299F  mul XBC,HL            * the descriptor index",
            "    0xFC29A1  add XIY,XBC",
            "    0xFC29A5  add XIX,(0x00d7ed)    + base",
            "That is the array framing of round 2, asserted by the firmware rather",
            "than by the descriptors' own pointers.",
            "notes/prom_d_documentation_round3.py Q4e.",
        ]
    return [
        "",
        "⚠ No reader was found for THIS block.  What round 3 adds is indirect and",
        "is stated as such: the stride word this block uses (directory +0x%02X = %d)"
        % (0xEC if slot == 0x30 else 0xF2, u16(0xEC if slot == 0x30 else 0xF2)),
        "IS read by prom_c -- at 0x%s -- and at 0xFC299A the SAME stride word is"
        % ", 0x".join("%06X" % h[1] for h in _R3.readers(0xEC if slot == 0x30 else 0xF2)),
        "multiplied by a record index to walk the descriptor array at slot +0x70,",
        "which is the same record class.  That corroborates the 14-byte array; it",
        "does NOT show anything reading this block, and the label stays a KN5000",
        "transplant on that basis.",
    ]


def DESC_INTERNAL_EV(slot, H, P, recs):
    a = S(slot)
    last = a + 14 * (H - 1)
    tg = [o for _t, o1, o2, _x, _y, _z in recs for o in (o1, o2) if o]
    return [
        "",
        "Evidence: (image-internal, NOT from code) the array's end is fixed",
        "by the records' own 32-bit offsets.  The smallest non-null offset over all",
        "%d descriptors is 0x%05X, which is 0x%05X + 14 x %d exactly -- so the"
        % (H, min(tg), a, H),
        "array cannot be one record longer or shorter.  The LAST descriptor, at",
        "0x%05X, points its part B at 0x%05X, which is the last object in the pool"
        % (last, recs[-1][2]),
        "(%d bytes short of the block end).  Both ends are pinned, first record and"
        % (NEXT[a] - recs[-1][2]),
        "last.  Re-derived on every run by notes/prom_d_structures_round2.py, which",
        "this emitter refuses to run without.",
    ]


def WAVESEL_EV(slot, a, b, n):
    """In-image evidence for a wave-select array: both ends, and the stride word."""
    return [
        "",
        "Evidence: (image-internal, NOT from code) the array's last record starts",
        "0x%05X and ends at 0x%05X, which is the next directory value, so the"
        % (a + 43 * (n - 1), b),
        "count %d is fixed at BOTH ends and is not a stride guess.  43 is the" % n,
        "directory's own word at +0x%02X, and prom_c reads that word at %d sites."
        % (0xF0 if slot == 0x20 else 0xEA, len(_R3.readers(0xF0 if slot == 0x20 else 0xEA))),
    ]


def WAVESEL_GAP(slot):
    """★ ROUND 5: why every record in this array keeps a NUMBER, stated with the
    measurements that make it a gap rather than an omission."""
    n, per, els = _R5.wavesel_gap(slot)
    lines = [
        "",
        "★ WHY EVERY RECORD BELOW IS `_%03d` AND NOT A NAME -- round 5 asked the" % (n - 1),
        "question directly instead of leaving it implied.",
        "",
        "  1. THE RECORD CARRIES NO NAME.  Round 4 named 778 tone and drum records",
        "     from their own ASCII fields.  These have none: over all %d records" % n,
        "     the widest run of printable bytes anywhere in a record is %d, against" % per,
        "     the 13 bytes of the narrowest name field this image uses.  No column",
        "     is printable in every record.  The test is not blind -- run on the",
        "     208-row catalogue at slot +0x8C it finds 14 printable columns of 16.",
    ]
    if slot == 0x20:
        recs, carried, uniq, agree = _R5.perc_overlap()
        lines += [
            "",
            "  2. AND THIS ARRAY IS THE ONE THAT LOOKED NAMEABLE, WHICH IS WHY THE",
            "     REFUSAL IS WORTH STATING.  Two independent proposals exist for it:",
            "       (a) POSITIONAL -- ToneDB_PercSourceNameList1 at slot +0x8C holds",
            "           exactly %d rows, the same count as this array;" % recs,
            "       (b) BY CONTENT -- %d of these %d records are byte-identical to"
            % (carried, recs),
            "           the LAST 43 BYTES of one of the 504 drum-instrument records",
            "           at slot +0x78 (150-byte stride, so bytes +107..+149), and",
            "           %d of them to exactly ONE such record, whose own 13-byte" % uniq,
            "           name would then be the obvious label.",
            "     Where both proposals exist and are unique they AGREE IN ONLY %d OF"
            % agree,
            "     %d.  Two derivations that contradict each other are better evidence"
            % uniq,
            "     than either alone, and what they are evidence FOR is that neither",
            "     may be used: a name taken from either source would be wrong %d"
            % (uniq - agree),
            "     times in %d.  So both are refused and the index stands." % uniq,
            "     ⚠ The byte overlap itself is real and is NOT retracted -- it is a",
            "     fact about the image worth having.  What is refused is naming an",
            "     object after a different object that happens to hold equal bytes.",
        ]
    else:
        lines += [
            "",
            "  2. AND THERE IS NO SECOND COPY TO BORROW FROM.  Every 43-byte window",
            "     of the whole %s-byte payload was indexed and matched against these"
            % format(0x50B09, ","),
            "     records: %d of %d occur anywhere else in the image.  (The array at"
            % (els, n),
            "     slot +0x20 is different -- see its own banner -- and that",
            "     difference is what makes this zero informative.)",
        ]
    if slot in (0x18, 0x20):
        # ★★ ROUND 6.  The heading above says "WHY EVERY RECORD BELOW IS A NUMBER"
        # and for this array that is no longer true of every record.  The paragraph
        # is kept, because its measurements are still correct AS MEASURED, and it is
        # CORRECTED here rather than deleted -- the tree's rule is that a superseded
        # claim and the evidence that supersedes it live side by side.
        _lab, _tw = TWIN_LABEL[slot], TWIN[slot]
        _n = len(_tw)
        _twinned = sum(1 for v in _tw.values() if v)
        lines += [
            "",
            "  3. ★★ CORRECTED IN ROUND 6 -- %d OF THESE %d RECORDS DO HAVE A NAME,"
            % (len(_R6.wavesel_labels(slot)), _n),
            "     and point 2 above is why it was missed.  That test asked whether a",
            "     record's 43 bytes occur ELSEWHERE IN THE IMAGE and compared all 43.",
            "     Round 5 had just proved that byte +0x0B is a preset number prom_c",
            "     WRITES OVER (0xFBC7D6).  A copy of a record may therefore differ",
            "     there and nowhere else, and excluding that one field is not a free",
            "     parameter -- it is the field the firmware is known to rewrite.",
            "",
        ]
        if slot == 0x18:
            lines += [
                "     Excluding it, %d of the %d records are identical to the" % (_twinned, _n),
                "     WAVE-SELECT BLOCK OF A NAMED TONE RECORD in the other 42 bytes.",
                "     The evidence that this is a relation and not a coincidence:",
                "       * the differing byte is +0x0B in %d of %d -- NO record of this"
                % (_twinned, _twinned),
                "         array differs from a tone's block in exactly one byte at any",
                "         other position, at any of the 43 positions;",
                "       * the tone side of a twin carries +0x0B = 0 (`no preset`) in",
                "         214 of 215 blocks, and this array's copies carry 1..7;",
                "       * 0 of 3,000 random 43-byte windows of the payload match under",
                "         the same rule, with both sets excluded from the corpus;",
                "       * and the 1,024-entry map at slot +0x0C -- the ONLY map in the",
                "         image whose range reaches %d, this array's last index -- puts"
                % (_n - 1),
                "         911 entries on a twinned record, and in 637 of those the",
                "         program map's tone at the same position is the tone the byte",
                "         test assigned (69.9%, against 1.0-1.3% for the same map",
                "         shuffled and 0.0-3.3% for the other twelve maps).",
                "     ⚠ THE MAP IS CORROBORATION, NOT THE NAME: 69.9% is not 100%, one",
                "     map entry cannot name all four records of a four-element tone,",
                "     and the slot +0x0C banner is NOT renamed on it.",
            ]
        else:
            lines += [
                "     %d of the %d records are byte-identical to the wave-select tail"
                % (_twinned, _n),
                "     of a named drum-instrument record -- which is point 2's proposal",
                "     (b), and round 5 refused it because proposal (a) contradicted it.",
                "     ★ WHAT ROUND 6 ADDS is the reason the two disagree, and it is not",
                "     that either match is wrong: THE CATALOGUE IS A DIFFERENT LIST.",
                "     Row 1 of it is 'Square Wave' where the identical bytes come from",
                "     'Square Click'; rows 7 and 8 are 'PowerBassDrmL' and",
                "     'PowerBassDrmR' where record 7 of this array matches NOTHING and",
                "     record 8 matches 'PowerBassDrm1/2'.  Across the %d rows this"
                % ALIGN[0],
                "     round can resolve, the catalogue carries the same name at the",
                "     same index %d times, carries it at a DIFFERENT index %d times,"
                % (ALIGN[1], ALIGN[2]),
                "     and %d times names something no drum record has; the alignment"
                % ALIGN[3],
                "     is not monotone, so it is not a simple drift either.",
                "     ★ AND THE MELODIC SIDE IS WHAT TELLS THEM APART.  The same",
                "     relation holds at slot +0x18, where there is NO competing",
                "     catalogue at all.  The POSITIONAL transfer stays REFUSED; the",
                "     byte identity is what the labels below use.",
            ]
        lines += [
            "",
            "     ⚠ AND WHAT A LABEL CLAIMS IS EXACTLY WHAT WAS MEASURED.  It reads",
            "     `_SameAs_<name>`: these bytes and that record's bytes are the same.",
            "     It does NOT say this record BELONGS to that tone or instrument --",
            "     nothing here reaches this array with an index whose meaning is",
            "     known.  ⚠ CORRECTED IN ROUND 8: this line used to end `Where the",
            "     twins disagree on the name, no label is given`, and point 5 below",
            "     is why that is no longer true of every such record.",
            "  notes/prom_d_understanding_round6.py Q1, Q2, Q2b, Q3, Q8.",
        ]
        # ★ ROUND 7.  Round 6's stem rule was stated as a CHARACTER CLASS (trailing
        # digits) when the thing it was actually recognising is a WORD BOUNDARY.
        # Saying it correctly names more records here and none at slot +0x18, and
        # both halves of that are printed rather than only the half that gained.
        _r7 = ROUND7_LABELS[slot]
        # ⚠ THE AMBIGUOUS COUNT ROUND 7 FACED, not the one round 8 leaves.  A
        # sentence about round 7 that quotes round 8's residue would be a
        # number drifting under its own paragraph.
        _amb = sum(1 for _k, _v in _tw.items()
                   if _v and _k not in _R6.wavesel_labels(slot))
        lines += [
            "",
            "  4. ★ ROUND 7 -- ROUND 6's RULE, STATED CORRECTLY, NAMES %d MORE." % len(_r7),
            "     Round 6 took the shared stem when the candidate names differ only by",
            "     a TRAILING DIGIT ('RoomBassDrm1'/'RoomBassDrm2').  This catalogue",
            "     spells the same relation with a trailing LETTER as well, and that",
            "     rule could not see it.  The rule round 7 uses instead: take the",
            "     longest common prefix, accept it only if in EVERY candidate the next",
            "     character starts a new CamelCase word (an upper-case letter or a",
            "     digit) AND at most %d characters follow it." % _R7.MAX_REMAINDER,
        ]
        if _r7:
            lines += ["     What that names here, in full:"]
            for _k in _r7:
                _who = sorted(set(x[2] for x in _tw[_k]))
                lines.append("       record %3d  ->  _SameAs_%-13s  from %d names: %s%s"
                             % (_k, _lab[_k], len(_who), ", ".join(_who[:3]),
                                ", +%d more" % (len(_who) - 3) if len(_who) > 3 else ""))
        else:
            lines += ["     It names NOTHING in this array -- 0 of the %d ambiguous"
                      % _amb,
                      "     records -- and that zero is reported, not omitted."]
        lines += [
            "     ⚠ THE BOUND OF %d IS NOT DECORATION.  Without it the same prefix"
            % _R7.MAX_REMAINDER,
            "     rule takes 'HiHat' from twelve names that split into HiHatOpen and",
            "     HiHatHfOpen, and 'Dance' from six that are a whole kit -- stems that",
            "     drop a WORD rather than a variant.  notes/prom_d_finish_round7.py Q4",
            "     prints what every bound from 1 to 8 would have named.",
            "  notes/prom_d_finish_round7.py Q4, and %d checks in that file."
            % _R7.AUDITED_CHECKS,
        ]
        # ★ ROUND 8.  The DISJUNCTION, and the four mechanisms it refused.
        _dj = DISJ[slot]
        _left = sum(1 for _k, _v in _tw.items() if _v and _k not in _lab)
        _anch, _viol = MONOTONE[slot]
        lines += [
            "",
            "  5. ★ ROUND 8 -- THE DISJUNCTION NAMES %d MORE, BY REFUSING TO CHOOSE."
            % len(_dj),
            "     Round 6 gave no label when the records carrying these 43 bytes",
            "     disagreed on the name, because `nothing here picks one of them`.",
            "     It does not have to pick.  The banner over each such record ALREADY",
            "     PRINTS the candidate names, derived by the same code, so keeping",
            "     them out of the label withheld a fact that had been measured and",
            "     left the object identified only by its position.  A label of the",
            "     form `_SameAs_A_Or_B` claims exactly the measurement: these bytes",
            "     are the wave-select block A carries and the one B carries.  It",
            "     picks no owner, and `_Or_` is what says so.",
            "     THE BOUND IS %d NAMES.  notes/prom_d_inventory_round8.py Q3 prints"
            % MAX_NAMES,
            "     what every bound from 1 to 12 would have named; at 4 the longest",
            "     label passes 100 characters, and at 6 one label enumerates twelve",
            "     hi-hats -- a whole family, which is what round 7's stem rule",
            "     already refused to compress into one word.",
            "     %d record%s of this array still carr%s a number: their candidate"
            % (_left, "" if _left == 1 else "s", "ies" if _left == 1 else "y"),
            "     sets are larger than %d." % MAX_NAMES,
            "",
            "  5b. ★ AND FOUR MORE MECHANISMS MEASURED AND REJECTED IN ROUND 8, for",
            "     the same reason round 7 wrote its three down here: so the next",
            "     round finds them before re-inventing them.",
            "     M4  the CROSS-FAMILY twin -- matching this array against the OTHER",
            "         family's records, which round 6 never did.  0 matches, on both",
            "         arrays, over %d records with no twin in their own family."
            % sum(1 for _v in _tw.values() if not _v),
            "     M5  widening round 6's mask to byte +0x0C as well.  It would name 3",
            "         more records at slot +0x18 and 0 at +0x20.  Refused by the same",
            "         instruction that refused M2: prom_c writes byte 11 and bytes",
            "         13..42, so byte 12 is content and a record differing in it is a",
            "         different record.",
            "     M6  naming a no-twin record from the run of consecutive records that",
            "         share its +0x0B.  The runs are real -- see the region banner --",
            "         but no run has a word common to every one of its named members,",
            "         including the 16-record run whose twins are all brass.",
            "     M7  ★ THE MONOTONE INTERVAL, the strongest of the four.  This array",
            "         has %d records whose bytes name exactly one owner, and reading" % _anch,
            "         their owner indices in array order gives %d backward steps out"
            % _viol,
            "         of %d.  Where that is 0 the array is SORTED, so an ambiguous"
            % (_anch - 1),
            "         record's owner is confined to the interval between its",
            "         neighbours -- which would break the tie with a mechanism.",
            "         Measured, it leaves exactly one candidate 0 times: where the",
            "         order holds every candidate is inside the interval, and where it",
            "         does not, none is.  Refuted by its own measurement.",
            "  notes/prom_d_inventory_round8.py Q3, Q4, Q5; %d checks."
            % ROUND8_CHECKS,
        ]
        if slot == 0x18:
            # ★ ROUND 7's REFUSALS.  Three mechanisms that would each have named
            # some of the records still numbered below, measured and rejected.
            # They are written HERE, next to the records they would have touched,
            # so the next round finds them before re-inventing them.
            _ag, _dis, _nv, _brk, _nam = _R7.m1_calibration()
            _gain, _wide = _R7.m2_reach()
            _m18, _m20, _mt, _ntails = _R7.m3_reach()
            lines += [
                "",
                "  4b. ★ AND THREE MECHANISMS ROUND 7 MEASURED AND REJECTED, recorded",
                "     next to the records they would have named so they are not",
                "     re-invented.  Each one WOULD have moved the number.",
                "",
                "     M1  THE MAP AT SLOT +0x0C AS A TIE-BREAKER.  Round 6 showed it",
                "         lands on a twinned record far more often than chance, so it",
                "         looks like the thing that could pick one of the several tone",
                "         names an ambiguous record matches.  CALIBRATED on the %d"
                % (_ag + _dis + _nv),
                "         records where the byte identity already gives ONE name, it",
                "         agrees %d times, DISAGREES %d and has no vote %d times -- so"
                % (_ag, _dis, _nv),
                "         on a set where the answer is already known it is wrong in %d"
                % _dis,
                "         of the %d records it votes on." % (_ag + _dis),
                "         REJECTED, though it would have broken %d of the %d ties."
                % (_brk, _nam),
                "",
                "     M2  WIDENING THE ONE-BYTE MASK TO BYTES 3..10.  It would bring %d"
                % _gain,
                "         more records within reach, and the positions are structured,",
                "         not scattered: %d records differ from their nearest tone block"
                % _wide.get((3, 5, 7, 9, 11), 0),
                "         at exactly {3,5,7,9,11} and %d at exactly {4,6,8,10,11} -- the"
                % _wide.get((4, 6, 8, 10, 11), 0),
                "         low and the high bytes of four 16-bit fields.  REJECTED by the",
                "         SAME instruction that justified the one-byte mask: prom_c",
                "         sub_FBC725 is the only writer of a wave-select record and it",
                "         writes byte 11 (0xFBC7D6) and bytes 13..42 (0xFBC7D9 sets the",
                "         index to 13, 0xFBC7E3 fetches the stride word as the bound).",
                "         Bytes 3..10 are written by NOTHING, so a record that differs",
                "         in them is a different record and not a rewritten copy.",
                "",
                "     M3  A RECORD'S 30-BYTE TAIL EQUALLING ONE OF THE %d STORED"
                % _ntails,
                "         PRESETS, which would have named a record `<tone> + preset N`.",
                "         %d of %d here, %d of %d at slot +0x20, %d of %d tone blocks."
                % (_m18[1], _m18[0], _m20[1], _m20[0], _mt[1], _mt[0]),
                "         REJECTED at zero: the preset apply is a RUNTIME operation on",
                "         a RAM copy (0xFBC738 computes the destination as",
                "         0x000087d2 + 43*n) and leaves no stored relation at all.",
                "  notes/prom_d_finish_round7.py Q5.",
            ]
            # ★★ ROUND 10.  The same map as M1, asked a different question.
            _nm, _unr, _brd, _dig = SEL_BUCKETS
            lines += [
                "",
                "  6. ★★ ROUND 10 -- M9, THE SELECTOR, NAMES %d MORE, WITH THE MAP M1"
                % _nm,
                "     REJECTED.  M1 above asked it to BREAK A TIE: to pick one of the",
                "     several tone names a record's BYTES already match.  Calibrated",
                "     where the answer was known it was wrong %d times in %d, and it"
                % (_R7.m1_calibration()[1],
                   _R7.m1_calibration()[0] + _R7.m1_calibration()[1]),
                "     stays rejected for that job.  M9 asks it about the records the",
                "     byte rule reaches NOT AT ALL -- the ones numbered below -- where",
                "     there is no tie and nothing to pick between, and it asks for a",
                "     DIFFERENT relation: not `whose block is this` but `what does the",
                "     map put this record under`.",
                "",
                "     THE INDEX.  A map entry sits at row*128 + program.  The PROGRAM",
                "     half is pinned hard: the agreement with the byte rule is %d of"
                % _R8.selector_byte_agreement(_R8.selector_map())[1],
                "     %d at the true reading, and mis-reading the program by one in"
                % _R8.selector_byte_agreement(_R8.selector_map())[0],
                "     either direction gives %d or %d, by two %d or %d."
                % tuple(_R8.selector_byte_agreement(_R8.selector_map(), progshift=_d)[1]
                        for _d in (-1, 1, -2, 2)),
                "     Shuffling the map gives a mean of %.1f (max %d) over 20 draws."
                % SEL_NULL,
                "     ⚠ THE ROW HALF IS NOT PINNED, and that is why the labels below",
                "     read a whole COLUMN: the true row alignment beats the best wrong",
                "     one by %d of %d positions, %.1f%% against %.1f%%, because the"
                % (SEL_MARGIN[1] - SEL_MARGIN[2], SEL_MARGIN[0],
                   100.0 * SEL_MARGIN[1] / SEL_MARGIN[0],
                   100.0 * SEL_MARGIN[2] / SEL_MARGIN[0]),
                "     eight melodic rows are near-copies of one another.  A name over",
                "     the column is invariant under all 8 row rotations; a name over",
                "     one position would rest on that margin.",
                "",
                "     THE CALIBRATION.  Where BOTH rules reach a record they agree 110",
                "     of 120 against a shuffled null of 5.8 -- and 13 of those 110 are",
                "     bought by the column being wider than M1's per-position vote,",
                "     which notes/prom_d_inventory_round8.py Q17c prices rather than",
                "     banks.  The 10 disagreements are printed there in full; M9 is",
                "     applied to NONE of them, because it labels only records with no",
                "     twin, so no label here contradicts another.",
                "",
                "     ⚠ AND THE HOLE, said here and not left to a reviewer: the 99-read",
                "     directory census finds %d prom_c reads of slot +0x%02X and %d of"
                % (SEL_READERS[0], _R8.SELECTOR_SLOT, SEL_READERS[1]),
                "     slot +0x18.  M9 is a relation between two TABLES, derived from",
                "     their contents; it is not evidence about what the machine does",
                "     with either, and `_SelectedFor_` is worded to claim only that.",
                "",
                "     WHAT IT LEAVES, and the four outcomes sum to the framed total:",
                "     %d named, %d selected by NO entry of the map (a census over all"
                % (_nm, _unr),
                "     1,024 entries, not a rule failing to fire), %d whose columns"
                % _brd,
                "     carry more than %d tone names, and %d that would have been named"
                % (MAX_NAMES, _dig),
                "     `161` -- tone record 0x05D's own `    16\' & 1\'    ` -- and are",
                "     refused rather than spelled some other way.",
                "     ★ AND THE SAME RULE ON THE PERCUSSION ARRAY IS REFUSED: see that",
                "     array's own banner.",
                "  notes/prom_d_inventory_round8.py Q16-Q20, and %d checks in that file."
                % _R8.AUDITED_CHECKS,
            ]
        if slot == 0x20:
            # ★★ ROUND 10.  The SAME mechanism, on this array, REFUSED -- written
            # here rather than only in the notes, because this is the array whose
            # 37 framed records it would have named.
            _ptot, _pok, _pmean, _pmax, _pag, _pdis, _pwould = _R8.perc_selector_refusal()
            lines += [
                "",
                "  6. ★★ ROUND 10 -- THE MECHANISM THAT NAMED %d RECORDS AT SLOT +0x18"
                % _R8.selector_buckets()[0],
                "     WAS RUN HERE AND IS REFUSED.  The shape is there: a 1,024-entry",
                "     map at slot +0x14 whose range is exactly 0..%d, and the"
                % (_R8.selector_map(0x14) and max(_R8.selector_map(0x14))),
                "     2,048-entry drum note map at +0x74 to read names out of.  It",
                "     would have named %d records -- EVERY framed record of this array."
                % _pwould,
                "",
                "     WHY NOT.  The test that licenses the melodic version is `does the",
                "     map's record equal that instrument's own bytes`.  Here it scores",
                "     %d of %d -- against a SHUFFLED NULL OF %d (max %d).  The drum"
                % (_pok, _ptot, round(_pmean), _pmax),
                "     records' 43-byte tails repeat so heavily that a shuffled map",
                "     scores almost as well, so a hit is not evidence of anything.  And",
                "     calibrated against the byte rule the way Q17 calibrates the",
                "     melodic one, it agrees %d time%s and differs %d."
                % (_pag, "" if _pag == 1 else "s", _pdis),
                "     ⚠ THE MELODIC ARRAY IS THE OPPOSITE CASE (shuffled mean %.1f"
                % _R8.selector_shuffle_null()[0],
                "     against %d), and that contrast is what makes the melodic number"
                % _R8.selector_byte_agreement(_R8.selector_map())[1],
                "     worth quoting and this one worthless.  %d names refused."
                % _pwould,
                "  notes/prom_d_inventory_round8.py Q18.",
            ]
    if slot == 0x3C:
        lines += [
            "",
            "  3. ★ BUT THE NUMBER IS NOT MERELY POSITIONAL HERE, and that is the",
            "     difference between this array and the other two.  Round 5 Q7 shows",
            "     the suffix IS the preset number prom_c indexes this array by, and",
            "     that each record carries that number in the low 6 bits of its own",
            "     byte +0x0B (%d of %d).  So `_%03d` is derived from the object, the"
            % (PRESET_IDX[1], PRESET_IDX[0], PRESET_IDX[0] - 1),
            "     way round 4's names were -- it is simply a number rather than a",
            "     string, so the documentation metric still counts it as framed.",
            "     WHAT IS STILL OPEN: what a preset MEANS (nothing here reads audio",
            "     state) and every byte of the record except +0x0B.",
            "  notes/prom_d_understanding_round5.py Q1a, Q4d, Q7.",
        ]
        # ★★ ROUND 12.  Two measurements on THIS array specifically, and a
        # candidate that is deliberately not spent.  All three numbers come out
        # of notes/prom_d_finish_round12.py at generation time.
        _r12h, _r12n, _r12pop, _r12c, _x = _R12.m11()
        _r12e, _r12o, _r12auc, _y, _z = _R12.pair_phase()
        _r12names, _r12n64, _r12pre = _R12.name_table()
        _r12tabs = _R12.dl_mask3f_tables()
        _r12mine = [t for t in _r12tabs
                    if t[2] == _R12.PROM_B_BASE + _R12.NAME_TABLE]
        lines += [
            "",
            "  4. ★ ROUND 12: THE TWIN RULE RUN ON THE 30 BYTES THAT ARE ACTUALLY",
            "     COPIED.  Point 2's zero, and round 9's Q12, compared WHOLE records.",
            "     A preset supplies only bytes 13..42 (prom_c 0xFBC7D9 sets i = 13,",
            "     0xFBC7E3 reads the stride word 43 as the bound), so the head has",
            "     nothing it must match.  Compared on those 30 bytes alone against",
            "     the %s wave-select records that are NOT this array: %d of %d."
            % (format(_r12pop, ","), _r12h, _r12n),
            "     The test is not inert -- %s of those %s records DO share a tail"
            % (format(_r12c, ","), format(_r12pop, ",")),
            "     with another record.  This array shares none.",
            "",
            "  5. ★ ROUND 12: THIS ARRAY IS BUILT IN EVEN-ALIGNED PAIRS.  Over records",
            "     38..63 the mean Hamming distance of a record to its neighbour is",
            "     %.2f of 43 bytes when the lower index is EVEN and %.2f when it is"
            % (_r12e, _r12o),
            "     ODD (AUC %.3f).  A positive finding about the array's own bytes,"
            % _r12auc,
            "     and it is a PARITY witness only -- the shift sweep in Q32 scores",
            "     every EVEN shift the same, so it says nothing about which record",
            "     is which.",
            "",
            "  6. ⚠ ROUND 12: A CANDIDATE NAME SET EXISTS AND IS NOT USED.  prom_b",
            "     0x%06X holds exactly %d rows of %d printable bytes"
            % (_R12.PROM_B_BASE + _R12.NAME_TABLE, _r12n64, _R12.NAME_W),
            "     (%r .. %r),"
            % (_r12names[0].strip(), _r12names[_r12n64 - 1].strip()),
            "     read by exactly %d display-list records on the consecutive"
            % len(_r12mine),
            "     variables %s, each masking with 0x%02X --"
            % (" ".join("0x%04X" % t[1] for t in _r12mine), _R12.DL_MASK),
            "     the same mask prom_c applies at 0xFBC744 before indexing THIS",
            "     array; and rows 38..63 of it are 13 `X L` / `X H` pairs, on the",
            "     parity point 5 measures.  If the panel variable is this record's",
            "     +0x0B, all %d labels below are named at once." % _r12n,
            "     ⚠⚠ AND NOTHING SHOWS THAT IT IS.  The panel variable is in one",
            "     CPU's RAM at 0x2808..0x280B; +0x0B is in a 43-byte record in the",
            "     other CPU's RAM at 0x87D2 + 43*n; no instruction in the four",
            "     images has been shown to carry one into the other, and a second",
            "     %d-row table is reached with the same mask.  The names are NOT"
            % _r12n64,
            "     applied.  notes/prom_d_finish_round12.py Q29, Q31, Q32.",
        ]
    else:
        lines += [
            "",
            # ⚠ RENUMBERED IN ROUND 7.  This paragraph was "3." and so was the
            # round-6 block above it; the list read 3, 3 for two rounds.
            "  5. WHAT WOULD SETTLE IT: a prom_c instruction that reaches a record of",
            "     THIS array with an index whose meaning is known -- exactly what",
            "     round 5 Q7 found for the array at slot +0x3C and did NOT find here.",
            "     Round 3's census of 99 directory reads found no reader for slot",
            "     +0x%02X at all." % slot,
            "  notes/prom_d_understanding_round5.py Q1a, Q4c, Q4d.",
        ]
    return lines


def WAVESEL_CHAIN(slot):
    lead = ["",
            "★ AND 43 IS THE RECORD LENGTH, not just a divisor.  One prom_c routine"]
    if slot != 0x3C:
        lead = ["",
                "⚠ NO reader was found for THIS array.  What follows is about the",
                "array at slot +0x3C, which has the same record shape, and is quoted",
                "as corroboration for the 43 -- not as evidence about this block.",
                "One prom_c routine"]
    return lead + [
        "reaches a record by multiplying the directory's stride word, and then",
        "uses the SAME word as the loop bound of a byte copy out of it:",
        "    0xFBC7B6  ld XIY,(XWA+0x3c)     the +0x3C array's file offset",
        "    0xFBC7BE  ld IY,(XWA+0x00ea)    the stride word = 43",
        "    0xFBC7C3  mul XIY,(XIZ+0xf2)    * the record index",
        "    0xFBC7C6  add XBC,XIY           => the record",
        "    0xFBC7CE  ld A,(XBC+0x0b)       field +0x0B, handled on its own",
        "    0xFBC7D9  ld (XIZ+0xf0),0x000d  i = 13",
        "    0xFBC7E3  ld WA,(XBC+0x00ea)    the stride word AS THE LOOP BOUND",
        "    0xFBC7E8  cp (XIZ+0xf0),WA      while i < 43: copy byte i",
        "So the record is 43 bytes long AND is cut into a 13-byte head that is",
        "handled field by field and a 30-byte tail that is copied wholesale --",
        "which is where round 2's `7D 80 54 at +0x0D` sits: at the first byte the",
        "loop touches.  notes/prom_d_documentation_round3.py Q4h decodes all",
        "twelve instructions from prom_c's ROM bytes.",
        "",
        "★★ AND IN ROUND 5 THAT ROUTINE ANSWERED THE QUESTION THIS LINE USED TO",
        "REFUSE.  ⚠ CORRECTED: this paragraph ended `NOT established: what any of",
        "the 43 bytes means, or what the head/tail split is FOR`, and BOTH halves",
        "of that sentence are now wrong.  The same routine begins by reading the",
        "field it is about to compute an index from:",
        "    0xFBC72B  ld C,0x2b             43, the record length",
        "    0xFBC72D  mul BC,(XIZ+0x0a)     * the caller's record number",
        "    0xFBC738  add XBC,0x000087d2    => the DESTINATION record, in RAM",
        "    0xFBC741  ld A,(XBC+0x0b)       ★ its field +0x0B",
        "    0xFBC744  and A,0x3f            ★ the LOW 6 BITS",
        "    0xFBC74C  cp WA,0 / jr NZ       0 takes a different arm entirely",
        "    0xFBC7C3  mul XIY,(XIZ+0xf2)    ★ that value INDEXES the +0x3C array",
        "    0xFBC7D6  ld (XWA+0x0b),H       the chosen record's own +0x0B, back",
        "    0xFBC7D9..0xFBC805              then bytes 13..42, copied over",
        "So FIELD +0x0B IS A 6-BIT PRESET NUMBER: 0 means `not from that array`",
        "(prom_c builds the tail from a live RAM block at 0x1523 instead,",
        "0xFBC750-0xFBC7A7) and 1..63 name one of the 64 records of",
        "ToneDB_WaveSelTailPresets, which then supplies this record's +0x0B and",
        "its whole 30-byte tail.  The 13/30 split is therefore not a curiosity:",
        "the tail is exactly what a preset REPLACES.",
        "",
        "★ AND THE ARRAY CONFIRMS IT WITHOUT THE CODE.  Its own record N carries N",
        "in the low 6 bits of its own +0x0B, %d of %d -- the exception is record 0,"
        % (PRESET_IDX[1], PRESET_IDX[0]),
        "which holds 1 and which that routine can never select because index 0",
        "takes the other arm.  %d of the 64 also set bit 6, which `and A,0x3f`" % PRESET_IDX[2],
        "strips; without the mask those %d would index past the array's end.  The"
        % PRESET_IDX[2],
        "same self-index test scores 2 of 322 on the +0x18 array and 1 of 208 on",
        "+0x20, so it is specific and not an artefact.  round 5 Q7.",
        "",
        "⚠ STILL NOT ESTABLISHED: any of bytes 0..10 or byte 12, and what a preset",
        "SOUNDS like -- nothing here reads audio state.",
    ]


def NOTEMAP_CHAIN(slot):
    if slot == 0x74:
        return [
            "",
            "★ AND prom_c SCALES IT AS 128 ENTRIES PER KIT:",
            "    0xFB4931  ld XBC,(XIX+0x74)     this map's file offset",
            "    0xFB4947  sll 0x07,BC           kit * 128",
            "    0xFB494C  mul BC,0x0002         * 2, so entries are LE16",
            "    0xFB4953  add XBC,(0x00d7ed)    + base",
            "    0xFB4958  ld WA,(XBC)           a drum-instrument index",
            "    0xFB495A  mul XIY,WA            * the stride word +0xEE = %d,"
            % u16(0xEE),
            "                                    which 0xFB493D loaded",
            "so the value read here really is an index into the 150-byte drum-",
            "instrument records at slot +0x78.  notes/prom_d_documentation_round3.py",
            "Q4d decodes all nine instructions from the ROM bytes.",
        ]
    return [
        "",
        "★ AND prom_c SCALES IT THE SAME WAY as +0x74: 0xFC10FE `sll 0x07,BC`,",
        "0xFC1101 `add BC,(XIZ+0x08)`, 0xFC1104 `mul BC,0x0002`, 0xFC110A add the",
        "base, 0xFC110F `ld BC,(XIY)`, then 0xFC1114 `cp BC,0xffff` -- the same",
        "'no entry' sentinel -- before 0xFC111F addresses the +0x80 catalogue.",
        "⚠ that chain is NOT decoded byte for byte by round 3; only the slot read",
        "at 0xFC10F8 is.  It is quoted from the listing and labelled as such.",
    ]


# ---------------------------------------------------------------------------
# emitters
# ---------------------------------------------------------------------------
OUTBUF = []
W = OUTBUF.append


def hx(v, n):
    return "0x%0*X" % (n, v)


def e_bytes(a, b, per=16, note=None):
    o = a
    while o < b:
        row = D[o:min(o + per, b)]
        txt = "".join(chr(c) if 0x20 <= c < 0x7F else "." for c in row)
        W("\t.byte %s\t; %05X  |%s|" % (", ".join("0x%02X" % c for c in row), o, txt))
        o += len(row)
    if note:
        W("\t; %s" % note)


def e_shorts(a, b, per=8, comment=None):
    """comment(index) -> str or None"""
    n = (b - a) // 2
    if comment is None:
        i = 0
        while i < n:
            k = min(per, n - i)
            W("\t.short %s\t; %05X  [%d]" %
              (", ".join("0x%04X" % u16(a + 2 * (i + j)) for j in range(k)), a + 2 * i, i))
            i += k
    else:
        for i in range(n):
            c = comment(i)
            W("\t.short 0x%04X\t; %05X  [%3d] %s" % (u16(a + 2 * i), a + 2 * i, i, c))
    assert a + 2 * n == b, (hex(a), hex(b))


def e_ascii(a, n):
    s = D[a:a + n]
    if all(0x20 <= c < 0x7F for c in s) and b'"' not in s and b"\\" not in s:
        W('\t.ascii "%s"\t; %05X' % (s.decode("ascii"), a))
    else:
        e_bytes(a, a + n, per=n)


def e_gap(a, b):
    if b > a:
        e_bytes(a, b)


def banner(title, a, b, lines):
    W("")
    W("; " + "=" * 74)
    W("; %s" % title)
    W("; file 0x%05X .. 0x%05X   (%d bytes)" % (a, b - 1, b - a))
    W("; " + "-" * 74)
    for ln in lines:
        W("; %s" % ln)
    W("; " + "=" * 74)


# ---------------------------------------------------------------------------
# region table -- built from the directory, then asserted to tile the image
# ---------------------------------------------------------------------------
REGIONS = []          # (start, end, emit_fn)


def region(a, b, fn):
    REGIONS.append((a, b, fn))


# slot -> (label, one-line role, KN5000 label at the same slot)
SLOT = {
    0x04: ("ToneDB_ToneNumBanks", "10 x 128 LE16 tone numbers (program map)", "ToneDB_BankMap_Main"),
    0x08: ("ToneDB_ToneOffsetTable", "274 LE32 offsets -> tone records", "ToneDB_ToneOffsetTable"),
    0x0C: ("ToneDB_ToneIndexMapA", "1024 LE16 index map", "ToneDB_ToneIndexMapA"),
    0x10: ("ToneDB_ToneIndexMapB", "1024 LE16 index map", "ToneDB_ToneIndexMapB"),
    0x14: ("ToneDB_PercSourceIndexMapA", "1024 LE16 index map", "ToneDB_PercSourceIndexMapA"),
    0x18: ("ToneDB_MixerDefaultTable", "322 x 43-byte wave-select records", "ToneDB_MixerDefaultTable"),
    0x1C: ("ToneDB_MixerDefaultTable", "(alias of +0x18)", "ToneDB_MixerDefaultTable"),
    0x20: ("ToneDB_PercMixerDefaultTable", "208 x 43-byte wave-select records", "ToneDB_PercMixerDefaultTable"),
    0x24: ("ToneDB_ToneIndexMapC", "1024 LE16 index map", "ToneDB_ToneIndexMapC"),
    0x28: ("ToneDB_ToneIndexMapD", "1024 LE16 index map + 768 unaccounted bytes", "ToneDB_ToneIndexMapD"),
    0x2C: ("ToneDB_DrumToneIndexMap", "1024 LE16 index map", "ToneDB_DrumToneIndexMap"),
    0x30: ("ToneDB_EnvDescTable", "descriptor block, stride word +0xEC = 14", "ToneDB_EnvDescTable"),
    0x34: ("ToneDB_EnvDescTable", "(alias of +0x30)", "ToneDB_EnvDescTable"),
    0x38: ("ToneDB_EnvDescTable_Perc", "descriptor block, stride word +0xF2 = 14", "ToneDB_EnvDescTable (shared)"),
    # ★ RENAMED IN WAVE 7 ROUND 5.  This block was ToneDB_MixerDefaultTable_3C --
    # a name copied from the +0x18 array's shape for a slot the KN5000 does not use,
    # i.e. a guess.  prom_c's sub_FBC725 now says what it is: 64 alternative TAILS
    # for a wave-select record, chosen by that record's own field +0x0B & 0x3F, and
    # the array's records carry their own index in that same field, 63 of 64.
    # notes/prom_d_understanding_round5.py Q7.
    0x3C: ("ToneDB_WaveSelTailPresets", "64 x 43-byte wave-select records", "UNUSED in the KN5000"),
    0x40: ("ToneDB_WaveSelTailPresets", "(alias of +0x3C)", "UNUSED in the KN5000"),
    0x44: ("ToneDB_SourceIndexMapA", "1024 LE16 index map", "ToneDB_SourceIndexMapA"),
    0x48: ("ToneDB_SourceIndexMapB", "1024 LE16 index map", "ToneDB_SourceIndexMapB"),
    0x4C: ("ToneDB_PercSourceIndexMapB", "1024 LE16 index map", "ToneDB_PercSourceIndexMapB"),
    0x50: ("ToneDB_SourceNameList1", "307 x 16-byte named wave-catalogue rows", "ToneDB_SourceNameList1"),
    0x54: ("ToneDB_SourceList1_Footer", "count 307 + 15 bytes", "ToneDB_SourceList1_Footer"),
    0x58: ("ToneDB_SourceIndexMapC", "1024 LE16 index map", "ToneDB_SourceIndexMapC"),
    0x5C: ("ToneDB_SourceIndexMapD", "1024 LE16 index map", "ToneDB_SourceIndexMapD"),
    0x60: ("ToneDB_PercSourceIndexMapC", "1024 LE16 index map", "ToneDB_PercSourceIndexMapC"),
    0x64: ("ToneDB_SourceNameList2", "314 x 16-byte named wave-catalogue rows", "ToneDB_SourceNameList2"),
    0x68: ("ToneDB_SourceList2_Footer", "count 314 + 15 bytes", "ToneDB_SourceList2_Footer"),
    0x6C: ("ToneDB_BankMap", "128-byte bank-select map", "ToneDB_BankMap_Coeff"),
    0x70: ("DrawbarPreset_EnvDescTable", "descriptor block, framing NOT established", "DrawbarPreset_EnvDescTable"),
    0x74: ("DrumKit_NoteMapA", "2048 LE16 drum-instrument indices", "DrumKit_NoteMapA"),
    0x78: ("PercInst_000_Silent", "504 x 150-byte drum-instrument records", "PercInst_000_Silent"),
    0x7C: ("DrumKit_NoteMapB", "2048 LE16 drum-instrument indices", "DrumKit_NoteMapB"),
    0x80: ("ToneDB_DrumSourceNameList", "503 x 16-byte named wave-catalogue rows", "ToneDB_DrumSourceNameList"),
    0x84: ("ToneDB_DrumList_Footer", "count 503 + 11 bytes", "ToneDB_DrumList_Footer"),
    0x88: ("(scalar or offset 0x125)", "unresolved -- see the notes", "338, a SCALAR (DSP1 stream bias)"),
    0x8C: ("ToneDB_PercSourceNameList1", "208 x 16-byte named wave-catalogue rows", "ToneDB_PercSourceNameList1"),
    0x90: ("ToneDB_PercList1_Footer", "count 208 + 11 bytes", "ToneDB_PercList1_Footer"),
    0x94: ("ToneDB_PercSourceNameList2", "161 x 16-byte named wave-catalogue rows", "ToneDB_PercSourceNameList2"),
    0x98: ("ToneDB_PercList2_Footer", "count 161 + 11 bytes", "ToneDB_PercList2_Footer"),
    0x9C: ("ToneDB_ToneIndexMapC", "(alias of +0x24, exactly as in the KN5000)", "ToneDB_ToneIndexMapC alias"),
    0xA0: ("ToneDB_ToneIndexMapD", "(alias of +0x28, exactly as in the KN5000)", "ToneDB_ToneIndexMapD alias"),
    0xA4: ("ToneDB_DrumToneIndexMap", "(alias of +0x2C, exactly as in the KN5000)", "ToneDB_DrumToneIndexMap alias"),
    # ★ ROUND 6: named by its READER, not transplanted and not invented -- see
    # emit_unk_fc8().  It was "Unk_0FC8_Table, purpose UNKNOWN" from round 1 to 5.
    0xA8: ("ToneDB_OctaveShiftByProgram", "8 banks x 128 programs, signed octave shift",
           "UNUSED in the KN5000"),
    0xAC: ("ToneDB_DefaultLayerParams", "one 81-byte element block + one 43-byte wave-select record",
           "ToneDB_DefaultLayerParams"),
    0xB0: ("ToneRec_Template_Clear", "a 713-byte 4-element tone record named 'Clear'", "PercName_Pack (DIFFERENT)"),
    0xB4: ("PercInst_Template_Silent", "a 150-byte drum-instrument record named 'Silent'", "UNUSED in the KN5000"),
}


def slot_label(slot):
    return SLOT[slot][0]


# --- 0x0000 directory ------------------------------------------------------
def emit_directory():
    banner("ToneDB_Directory -- the 48-slot section directory", 0x00, 0x100, [
        "Every other region in this file is reached from here.  Each slot is a",
        "4-byte little-endian FILE OFFSET (0-based; prom_d holds no absolute",
        "pointers), except that some slots in the KN5000's equivalent table are",
        "SCALARS -- see slot +0x88 below, which is the one prom_d slot whose",
        "reading is genuinely ambiguous.",
        "",
        "The KN5000 has the same table, slot for slot, at its ToneDB_Base",
        "(ROM 0x830000) -- ../kn5000-roms-disasm/table_data/tone_database_directory.s.",
        "The 'KN5000:' note on each line is that file's label for the SAME slot.",
        "Cross-checks that hold: slot +0x08 is the tone-record offset table in",
        "both; +0x9C/+0xA0/+0xA4 alias +0x24/+0x28/+0x2C in both; +0x18==+0x1C",
        "and +0x30==+0x34 in both; the tail scalars +0xD0..+0xDA and +0xE8 have",
        "IDENTICAL values in both.",
        "",
        "⚠ The NAMES are still transplanted, not derived.  Where prom_d's content",
        "contradicts the KN5000 role the label follows the CONTENT and says so.",
        "",
        "Evidence: ★ THIS TABLE IS READ BY prom_c, and that is new in wave 7 round 3.",
        "prom_d's base is 0x00F00000 on CPU 2's bus, held in RAM 0x00D7ED and",
        "0x00D7F1; the ONLY two instructions in prom_c that write either address",
        "are 0xFB0523 and 0xFB0528, both storing the 0x00F00000 that 0xFB051E loads",
        "as an immediate, so the base is a compile-time constant everywhere.",
        "notes/prom_d_documentation_round3.py then finds %d reads of this table --"
        % CENSUS_N,
        "a load of that base immediately followed by a load from (base + slot) --",
        "covering %d distinct slots, and RE-DECODES every one from prom_c's ROM"
        % CENSUS_SLOTS,
        "bytes at the address it cites.  Which slots, and which sites, is printed",
        "on each region's own banner below.",
        "",
        "★ AND THE POINTER/SCALAR SPLIT IS prom_c's TOO.  Every read of a slot",
        "BELOW +0xC0 loads a 32-BIT register; every read of a slot AT OR ABOVE",
        "+0xC0 loads a 16-BIT one.  %d of %d, no exception.  Until round 3 the"
        % (CENSUS_N, CENSUS_N),
        "'offsets here, scalars there' reading was borrowed from the KN5000's",
        "table; it is now this machine's own instruction encodings that say it.",
        "",
        "The 0-BASED reading is prom_c's as well: at 0xFB429D it loads a tone",
        "record's entry out of the table at slot +0x08 and at 0xFB429F it ADDS THE",
        "BASE AGAIN.  A stored absolute address would not need that second add.",
        "",
        "⚠ WHAT IS STILL NOT ESTABLISHED: %d of the 39 filled primary slots have no"
        % (39 - len([x for x in range(0, 0xB8, 4)
                     if DIR[x // 4] != 0xFFFFFFFF and x not in _R3.ALIAS
                     and _R3.readers(x)])),
        "reader at all -- they are named on each banner, and every one of them",
        "keeps its transplanted name on that basis.  And no FIELD inside any",
        "record these slots point at is identified by anything.",
    ])
    W("ToneDB_Base:")
    W("ToneDB_Directory:")
    for i in range(48):
        off = 4 * i
        v = DIR[i]
        if v == 0xFFFFFFFF:
            W("\t.long 0xFFFFFFFF\t\t\t; +0x%02X  unused" % off)
        elif off in SLOT:
            lab, role, kn = SLOT[off]
            W("\t.long 0x%08X\t\t\t; +0x%02X  %-28s %s" % (v, off, lab, role))
            W("\t\t\t\t\t;        KN5000: %s" % kn)
        else:
            W("\t.long 0x%08X\t\t\t; +0x%02X  UNIDENTIFIED" % (v, off))
    W("")
    W("; Directory tail -- scalars, read as 16-bit words.  The KN5000's reader")
    W("; takes +0xEA/+0xEC/+0xEE/+0xF0/+0xF2 as record STRIDES for the blocks")
    W("; behind the pointer slots; the values here differ from the KN5000's but")
    W("; three of them are confirmed by this image's own geometry (43, 150).")
    W(";")
    W("; Evidence: ★ prom_c reads SIX of these tail words, always into a 16-bit")
    W("; register, and it uses two of them AS STRIDES rather than as data:")
    W(";   +0xEC = %d  0xFC299A `ld BC,(XWA+0x00ec)` then 0xFC299F `mul XBC,HL`,"
      % u16(0xEC))
    W(";               walking the 14-byte descriptor array at slot +0x70;")
    W(";   +0xEE = %d 0xFB493D `ld IY,(XIX+0x00ee)` then 0xFB495A `mul XIY,WA`,"
      % u16(0xEE))
    W(";               scaling a drum-instrument index into the 150-byte records.")
    W("; The other four (+0xE0, +0xEA, +0xF0, +0xF2) are read at %d sites in all"
      % sum(len(_R3.readers(x)) for x in (0xE0, 0xEA, 0xF0, 0xF2)))
    W("; and parked in a frame slot; what they are then multiplied BY is not")
    W("; traced, so they are NOT claimed as strides on the strength of the reads.")
    W("; Sites and byte-level decodes: notes/prom_d_documentation_round3.py Q3/Q4.")
    KNTAIL = {0xD0: "3, same in the KN5000", 0xD2: "0", 0xD4: "3, same in the KN5000", 0xD6: "2, same",
              0xD8: "3, same in the KN5000", 0xDA: "2, same", 0xE0: "24 (KN5000: 28)",
              0xE8: "426 -- IDENTICAL to the KN5000, where it is 21+5*81, its longest tone record",
              0xEA: "43 = the wave-select record stride, CONFIRMED (KN5000: 11)",
              0xEC: "14 = descriptor stride (KN5000: 15)",
              0xEE: "150 = the drum-instrument record stride, CONFIRMED (KN5000: 58)",
              0xF0: "43 = wave-select stride, percussion family (KN5000: 11)",
              0xF2: "14 = descriptor stride, percussion family (KN5000: 15)"}
    for off in range(0xC0, 0x100, 2):
        note = KNTAIL.get(off, "")
        W("\t.short %-6d\t\t\t\t; +0x%02X  %s" % (u16(off), off, note))


region(0x00, 0x100, emit_directory)


# --- 0x0100 bank map -------------------------------------------------------
def emit_bankmap():
    banner("ToneDB_BankMap -- directory slot +0x6C", 0x100, 0x180, [
        "128 bytes, indexed by a MIDI-style bank selector; the value is the row",
        "of ToneDB_ToneNumBanks (below) to use.  Only 10 selectors resolve:",
        "0..7 -> rows 0..7 (the melodic rows), 0x20 -> row 8 and 0x27 -> row 9",
        "(the two drum rows).  Every other selector reads 0.",
        "",
        "This is the KN5000's ToneDB_BankMap_Main / _Coeff structure and it sits",
        "exactly 0x80 below the tone-number banks there too.  ⚠ In the KN5000 it",
        "is directory slot +0x04 that names this table and +0x6C that names the",
        "second copy; in prom_d it is +0x6C that names THIS table and +0x04 that",
        "names the tone-number banks 0x80 above it.  There is only one copy here.",
    ] + ev_slot(0x6C))
    W("ToneDB_BankMap:")
    e_bytes(0x100, 0x180)


region(0x100, 0x180, emit_bankmap)


# --- 0x0180 tone-number banks ---------------------------------------------
def emit_numbanks():
    banner("ToneDB_ToneNumBanks -- directory slot +0x04", 0x180, 0xB80, [
        "10 rows x 128 LE16.  Row r, program p gives the TONE INDEX into",
        "ToneDB_ToneOffsetTable.  Rows 0-7 only ever name melodic tones",
        "(index 0x000-0x0FF); rows 8-9 only ever name drum kits (0x100-0x111).",
        "Asserted over all 1280 entries by scripts/analysis/prom_d_tone_database.py.",
        "",
        "★ NEW IN ROUND 5 -- TWO OF THE TEN ROW LABELS NOW SAY WHAT THE ROW IS,",
        "and they say it from what the row SELECTS, since every record a row",
        "selects carries its own 16-byte ASCII name:",
        "",
        "  ToneNumBank_DrumKits      row 8.  All 128 of its entries name a record",
        "                            whose own name ENDS IN 'Kit' -- 128 of 128,",
        "                            checked at program 127 as well as program 0.",
        "  ToneNumBank_SpecialSound  row 9.  127 of its entries hold tone 0x100",
        "                            'Jazz Kit'; the entry at program 127 holds",
        "                            tone 0x110 ' Special sound ', and row 9 is the",
        "                            ONLY row in all 1,280 entries in which 0x110",
        "                            occurs.  That one entry is the whole of what",
        "                            distinguishes this row, so it is what names it.",
        "",
        "⚠ AND ROWS 0-7 KEEP A NUMBER, deliberately.  What they share is measured",
        "(no entry >= 256 in any of the 1,024) and it is not enough to tell them",
        "apart; against row 0 they differ in %s of 128 entries"
        % "/".join(str(sum(1 for _p in range(128)
                           if u16(0x180 + 0x100 * _r + 2 * _p) != u16(0x180 + 2 * _p)))
                   for _r in range(1, 8)),
        "respectively, and NOTHING in this image says what that variation means.",
        "`Melodic_<r>` states the class and admits the gap; it is not a name.",
        "The row-name rule is derived, not typed: notes/prom_d_understanding_round5.py",
        "row_names(), and this generator refuses to emit if it stops producing the",
        "audited ten.  round 5 Q2.",
        "",
        "The program ORDER is NOT General MIDI: program 1 of row 0 is",
        "'Honky-Tonk Piano' where GM has Bright Acoustic Piano, and programs",
        "32-39 are Harp/Banjo/Harp/Mandolin/Shamisen/Koto/Sitar/Kalimba where GM",
        "has the bass family.  It is a Technics-internal ordering; nothing here",
        "identifies which panel control it corresponds to.",
    ] + ev_slot(0x04, [
        "",
        "★ AND THE 10 x 128 SHAPE IS prom_c's, not an inference from the span.",
        "The reader scales the index before it adds the table:",
        "    0xFB4271  sll 0x07,BC          row * 128",
        "    0xFB4274  add BC,DE            + program number",
        "    0xFB4276  add BC,BC            * 2, so the entry is an LE16",
        "    0xFB427C  add XIY,(0x00d7ed)   + the base  => the absolute entry",
        "    0xFB4281  ld HL,(XIY)          the tone index",
        "and the value it produces goes straight into ToneDB_ToneOffsetTable at",
        "0xFB4283.  notes/prom_d_documentation_round3.py Q4a decodes all fifteen",
        "instructions of that chain from the ROM bytes.",
    ]))
    W("ToneDB_ToneNumBanks:")
    for b in range(10):
        base = 0x180 + 0x100 * b
        _t = [u16(base + 2 * i) for i in range(128)]
        _nm = [NAME(PTRS[t]).strip() for t in _t]
        W("")
        W("; --- row %d (%s) ---" % (b, "melodic" if b < 8 else "drum kits"))
        # ★ ROUND 7: EVERY ROW NOW CARRIES ITS OWN WITNESS OR ITS OWN GAP, in the
        # file rather than only in a script.  Rows 8 and 9 were named by round 5
        # from what they SELECT and the derivation lived only in the banner above,
        # so the two labels that round 5 promoted were the only labels in this
        # image with a semantic name and no evidence line of their own --
        # notes/prom_d_finish_round7.py Q1 found them by looking for exactly that.
        if b >= 8:
            _kit = sum(1 for x in _nm if x.endswith("Kit"))
            _uniq = sorted(set(_t))
            W("; Evidence: this row's own 128 LE16 entries, at file 0x%05X..0x%05X,"
              % (base, base + 0xFF))
            W("; and the 16-byte ASCII name of every record they select.")
            if _kit == 128:
                W("; All 128 select a record whose own name ends in 'Kit' -- checked")
                W("; at program 127 (%r) as well as program 0 (%r)."
                  % (_nm[127], _nm[0]))
            else:
                _cnt = collections.Counter(_t)
                _dom = _cnt.most_common(1)[0][0]
                _rest = [i for i in range(128) if _t[i] != _dom]
                _all = [u16(0x180 + 2 * i) for i in range(1280)]
                W("; %d of the 128 hold tone 0x%03X %r.  The %s at"
                  % (_cnt[_dom], _dom, _nm[_t.index(_dom)],
                     "one that does not is" if len(_rest) == 1
                     else "%d that do not are" % len(_rest)))
                W("; program %s, holding tone 0x%03X %r -- which occurs %d time%s"
                  % (", ".join(str(i) for i in _rest[:4]), _t[_rest[0]],
                     _nm[_rest[0]], _all.count(_t[_rest[0]]),
                     "" if _all.count(_t[_rest[0]]) == 1 else "s"))
                W("; in all 1,280 entries of this table, so it is unique to this")
                W("; row.  That %s the whole of what distinguishes this row, so it"
                  % ("entry is" if len(_rest) == 1 else "handful of entries is"))
                W("; is what names it.")
            W("; %d distinct tone indices in the row.  round 5 Q2 row_names()."
              % len(_uniq))
        else:
            # ⚠ CORRECTED IN ROUND 8.  This banner used to say, for EVERY row
            # including row 0, "%d of the 128 differ from row 0's -- so the rows
            # are NOT copies of one another".  On row 0 that reads "0 of the 128
            # differ ... so the rows are NOT copies", a sentence refuted by its
            # own number four words earlier.  It is the shape a round-3 reviewer
            # found twice in prom_a, and notes/prom_d_inventory_round8.py Q8 is
            # the detector that now fires on it.
            _d = sum(1 for i in range(128) if u16(base + 2 * i) != u16(0x180 + 2 * i))
            W("; ⚠ NO NAME, and the gap is measured rather than assumed: all 128")
            W("; entries select a melodic tone (index < 0x100), which is what")
            W("; `Melodic` states.")
            if b == 0:
                W("; This is the row the other seven are compared against; they")
                W("; differ from it in %s of their 128 entries"
                  % ", ".join(str(len(ROW_DIFFS[r])) for r in range(1, 8)))
                W("; respectively, so the eight rows are not copies of one another.")
            else:
                W("; %d of the 128 differ from row 0's, so this row is not a copy of"
                  % _d)
                W("; it.")
            W("; Nothing in this image says what the variation between them means,")
            W("; and the BankMap at 0x%05X maps bank-select value %d to this row,"
              % (S(0x6C), b))
            W("; which is what the suffix already says.")
            # ★ ROUND 8: the reading that had never been TESTED, tested.
            W("; ★ ROUND 8 RULES OUT THE OBVIOUS READING, which round 6 left")
            W("; standing by not testing it: that the rows are an ORDERED LADDER,")
            W("; row r being the r-th alternative wherever one exists.  If they")
            W("; were, the programs at which row r+1 differs would be a SUBSET of")
            W("; those at which row r does.  They are not, at %d of the 6 steps"
              % len(ROW_NESTING))
            W("; -- row %d differs at program %d where row %d does not."
              % (ROW_NESTING[0][0], ROW_NESTING[0][2][0], ROW_NESTING[0][1]))
            W("; round 6 Q1, verdict NAMELESS-UNDIFFERENTIATED; round 7 Q1;")
            W("; notes/prom_d_inventory_round8.py Q6.")
        W("ToneNumBank_%s:" % ROW_NAME[b])
        e_shorts(base, base + 0x100,
                 comment=lambda i, base=base: "prog %3d -> tone 0x%03X %r"
                 % (i, u16(base + 2 * i), NAME(PTRS[u16(base + 2 * i)])))


region(0x180, 0xB80, emit_numbanks)


# --- 0x0B80 offset table ---------------------------------------------------
def emit_offtable():
    banner("ToneDB_ToneOffsetTable -- directory slot +0x08", 0xB80, 0xFC8, [
        "274 LE32 file offsets.  Entry i is tone index i; the scan that finds the",
        "end stops on the zero word at 0x0FC8, which is the FIRST BYTES OF THE NEXT",
        "REGION, not a terminator inside this one.  Entry i is tone",
        "index i; the first 16 bytes at the target are the tone's displayed name,",
        "space-padded and centred.  Indices 0x000-0x0FF are melodic tone records,",
        "0x100-0x111 are the 18 drum kits.  All 274 offsets are distinct.",
        "",
        "Same structure and same directory slot as the KN5000's table of the same",
        "name (629 entries there).",
        "",
        "\u2605\u2605 WAVE 7 ROUND 11 -- THE INDEX ORDER IS THE PANEL'S SOUND GROUP ORDER.",
        "Rounds 4-10 left this table's ORDER unexplained.  It is %d groups of %d:"
        % (GRP_COUNT, GRP_MEMBERS),
        "tone index k is group k/%d, member k%%%d, and the group's displayed name is"
        % (GRP_MEMBERS, GRP_MEMBERS),
        "prom_b's 16 ASCII bytes at 0x%06X + 16*group.  The %d groups, in this"
        % (GRP_NAME_ADDR, GRP_COUNT),
        "table's own order:",
    ] + ["    %s"
         % "  ".join("%2d %-17s" % (_g, GRP_NAME(_g).strip())
                     for _g in range(_g0, min(_g0 + 3, GRP_COUNT)))
         for _g0 in range(0, GRP_COUNT, 3)] + [
        "",
        "Evidence: prom_a 0xFC231D `add XBC,0x00F06EF4` reaches prom_b's",
        "group/member table after 0xFC230C `mul WA,0x0010` (group) and 0xFC2317",
        "`mul BC,0x0002` (member), so a group's row holds 16/2 = %d entries; entry"
        % GRP_MEMBERS,
        "k of that table is a (program, bank-select) pair which THIS image's own",
        "ToneDB_BankMap and ToneDB_ToneNumBanks resolve to tone k, for %d"
        % GRP_RUN,
        "consecutive entries k = 0..%d (entry %d is the first that is not its own"
        % (GRP_RUN - 1, GRP_RUN),
        "index); %d/%d = %d, and prom_b's name table has exactly %d named rows"
        % (GRP_RUN, GRP_MEMBERS, GRP_COUNT, GRP_COUNT),
        "before row %d becomes `----------------`." % GRP_COUNT,
        "\u26a0 WHICH NAME GOES WITH WHICH OCTET is a separate claim and is witnessed",
        "twice: %d of the %d group names share a word with one of the %d tone names"
        % (GRP_WORDHITS, GRP_COUNT, GRP_MEMBERS),
        "in their octet against a best rotation of %d, and the %d tone names ending"
        % (GRP_WORDNULL, len(_R8.group_kit_witness()[0])),
        "in `Kit` occupy exactly the groups whose names spell DRUM.  %d groups"
        % (GRP_COUNT - GRP_WORDHITS),
        "share no word; Q21 lists them.",
        "\u26a0 AND THE PROGRAM ORDER OF ToneDB_ToneNumBanks IS A DIFFERENT THING and is",
        "still unexplained -- it is not General MIDI (round 9 Q14) and this finding",
        "says nothing about it.",
        "notes/prom_d_inventory_round8.py Q21.",
    ] + ev_slot(0x08, [
        "",
        "★ THE ENTRY WIDTH AND THE 0-BASED READING ARE prom_c's TOO:",
        "    0xFB4288  ld XWA,(XBC+0x08)    this table's file offset",
        "    0xFB4290  sll 0x02,IY          tone index * 4, so entries are LE32",
        "    0xFB4298  add XIY,(0x00d7ed)   + base => the absolute entry",
        "    0xFB429D  ld XWA,(XIY)         the entry: a tone record's FILE OFFSET",
        "    0xFB429F  add XWA,(0x00d7ed)   + base AGAIN => the record itself",
        "That second add is the whole argument for `0-based file offsets`: the",
        "value stored here is NOT an address, and prom_c adds the base to it.",
        "notes/prom_d_documentation_round3.py Q4a.",
    ]))
    W("ToneDB_ToneOffsetTable:")
    for i in range(274):
        W("\t.long 0x%08X\t; tone 0x%03X  %r" % (PTRS[i], i, NAME(PTRS[i])))


region(0xB80, 0xFC8, emit_offtable)


# --- 0x0FC8 unknown --------------------------------------------------------
OCTAVE_LABEL = SLOT[0xA8][0]


def emit_unk_fc8():
    banner("%s -- directory slot +0xA8" % OCTAVE_LABEL, 0xFC8, 0x13C8, [
        "8 records of 128 bytes.  The period is not assumed: the only non-zero",
        "bytes sit at record-relative +0x0E, +0x58..+0x5F, +0x7A and +0x7E, and",
        "they repeat on a 0x80 grid in all 8 records.  Values are 0xF4 (and 0x0C",
        "at +0x7A in five of the eight).  Everything else is zero.",
        "",
        "⚠ The KN5000 leaves directory slot +0xA8 UNUSED, so there is no name to",
        "transplant.  ⚠ CORRECTED IN ROUND 6: this sentence used to end 'and none is",
        "invented here', and the block was called Unk_0FC8_Table.  The name it now",
        "carries is not invented and not transplanted either -- it is DERIVED from",
        "the one prom_c routine that reads the block; see the round-6 section below.",
        "",
        "★ ROUND 5 adds the two facts that a per-record label could not then carry.",
        "  (a) THE EIGHT RECORDS ARE ONLY %d DISTINCT BYTE STRINGS: %s."
        % (len(_R5.fc8_classes()),
           "; ".join("{%s}" % ",".join(str(k) for k in g) for g in _R5.fc8_classes())),
        "      A table whose eight rows take three values is not eight independent",
        "      settings, whatever it is.",
        "  (b) AND THERE IS NO NAME IN IT TO TAKE: 0 of the %d bytes are printable"
        % (8 * 128),
        "      at all, so the round-4 mechanism has nothing to work with here.",
        "      ⚠ (b) IS STILL TRUE and round 6 does not overturn it: this block is",
        "      named by its READER, not by its content.  And (a) now has a reading --",
        "      the three classes differ only at programs 14 and 122, which is what",
        "      the per-record comments below list.",
        "  notes/prom_d_understanding_round5.py Q1c.",
    ] + ev_slot(0xA8, [
        "",
        "★ NEW in wave 7 round 3: the 128-byte RECORD SIZE is now prom_c's, not",
        "just a zero/non-zero column pattern.  The one reader indexes it by 128:",
        "    0xFA7332  ld XIY,(XWA+0x00a8)  this table's file offset",
        "    0xFA734A  add XIY,XBC          + a byte fetched from RAM 0x1523",
        "    0xFA7351  sll 0x07,BC          record index * 128",
        "    0xFA7356  add XIY,XBC",
        "    0xFA7358  add XIY,(0x00d7ed)   + base",
        "    0xFA735D  ld BC,(XIY)          a 16-bit word out of the record",
        "notes/prom_d_documentation_round3.py Q4f decodes all of it from bytes.",
        "",
        "⚠ THE THREE LINES ABOVE ARE ROUND 3'S AND ARE NOW SUPERSEDED: they ended",
        "'STILL NOT ESTABLISHED: what a record MEANS, what selects one, or what the",
        "16-bit word at the computed offset is for.'  Round 6 answers all three, out",
        "of the SAME routine, by reading what it does with the value and what its",
        "other arm does instead.",
        "",
        "★★ THE BLOCK IS AN OCTAVE-SHIFT TABLE, INDEXED [BANK][PROGRAM].",
        "",
        "  * sub_FA72E9 is called from ONE place, Voice_ComputePitch (0xFA7F7A), and",
        "    both of its arms return a pitch offset in WA.",
        "  * ITS OTHER ARM reads a 16-entry table at prom_c 0xFDF22A --",
        "        %s" % ", ".join("%+d" % v for v in _R6.oct_sibling()),
        "    -- with `and C,0x0f` (0xFA7375), `ld A,(XBC)`, `exts WA`, `sll 0x08,WA`.",
        "    Every entry is a multiple of 12.  It is an OCTAVE SELECT, centred on",
        "    entry 8 = 0.",
        "  * THIS ARM produces the value the same way: 0xFA735D `ld BC,(XIY)` then",
        "    0xFA735F `sll 0x08,BC`.  The shift discards the word's high byte, which",
        "    is why a byte table can be read with a word instruction -- and why the",
        "    0xF4 at +0x58..+0x5F reads as -12 eight times over rather than as",
        "    0xF4F4.  The two shifts are the SAME opcode with a different count:",
        "    prom_c bytes d9 ee 07 at 0xFA7351 and d9 ee 08 at 0xFA735F.",
        "  * SO THE VALUES ARE OCTAVES.  This table holds only 0xF4 (-12) and 0x0C",
        "    (+12), in %d cells of %d." % (_R6.AUDITED_OCTAVE[1], 8 * 128),
        "  * AND THE TWO INDICES ARE A BANK AND A PROGRAM.  0xFA7301 reads directory",
        "    slot +0x6C -- ToneDB_BankMap -- and turns a byte from the voice's RAM",
        "    block into a bank ROW; 0xFA7351 `sll 0x07,BC` scales that row by 128,",
        "    which is this table's record size AND the program map's row width; the",
        "    within-record byte comes from the ADJACENT byte of the same RAM block",
        "    (+27 against +28).  A tone index cannot be the second index: it runs",
        "    0..273 and would address the next bank's record for 146 of 274 tones.",
        "",
        "★ AND THE MARKED CELLS NAME THEMSELVES, which is what makes the reading",
        "checkable rather than merely consistent.  The %d marks fall in only %d"
        % (_R6.AUDITED_OCTAVE[1], len(set(p for r in OCTAVE_ROWS.values()
                                          for p, _v, _n in r))),
        "columns of 128 -- 85 marks placed at random would fill about 62 -- and eight",
        "of the eleven columns are ONE CONSECUTIVE RUN, programs 88-95, which the",
        "program map fills with the drawbar/organ family in every one of the 8 banks:",
        "",
    ] + ["    prog %3d  %s  %s"
         % (_p,
            ", ".join("%+d" % x for x in sorted(set(
                w for r in OCTAVE_ROWS.values() for q, w, _n in r if q == _p))),
            ", ".join(sorted(set(
                n for r in OCTAVE_ROWS.values() for q, _w, n in r if q == _p))))
         for _p in sorted(set(q for r in OCTAVE_ROWS.values()
                              for q, _v, _n in r))] + [
        "",
        "Program 122 is the only +12 in the image.  The column structure and the",
        "values are MEASURED; notes/prom_d_understanding_round6.py Q4 and Q8c, where",
        "the shift bytes are re-decoded from prom_c's ROM.",
        "⚠ That these particular instruments are ones a player expects an octave away",
        "from written pitch is an INTERPRETATION of the list and is not measured.  It",
        "is why the list is printed in full rather than summarised: a reader who",
        "disagrees with it can see exactly what the table marks.",
        "",
        "⚠ NOT established: the numeric UNIT.  What is measured is that the two arms",
        "encode identically and that prom_c's arm holds only multiples of 12.  Also",
        "NOT established: what the RAM byte at voice+27 is set from -- the reading",
        "'program number' comes from the record size, the BankMap and the marked",
        "columns, not from a write to that byte.",
    ]))
    W("%s:" % OCTAVE_LABEL)
    for k in range(8):
        W("")
        W("; --- bank %d: the octave shift for each of the 128 programs of"
          " ToneNumBank_Melodic_%d ---" % (k, k))
        marks = OCTAVE_ROWS[k]
        W("; %d nonzero cell%s: %s"
          % (len(marks), "" if len(marks) == 1 else "s",
             "; ".join("prog %d %+d %r" % (p, v, n) for p, v, n in marks)))
        W("%s_Bank%d:" % (OCTAVE_LABEL, k))
        e_bytes(0xFC8 + 128 * k, 0xFC8 + 128 * (k + 1))


region(0xFC8, 0x13C8, emit_unk_fc8)


# --- tone records ----------------------------------------------------------
TONE_END = {}          # ptr -> end offset
GUNSHOT_END = S(0xAC)
DRAWBAR_END = S(0x70)
MEL = sorted(PTRS[:256])
for i, p in enumerate(MEL):
    nxt = MEL[i + 1] if i + 1 < len(MEL) else None
    if p >= 0x40000:
        TONE_END[p] = (nxt if nxt and nxt >= 0x40000 else DRAWBAR_END)
    else:
        TONE_END[p] = (nxt if nxt and nxt < 0x40000 else GUNSHOT_END)
IDX_OF = {p: i for i, p in enumerate(PTRS)}

NAMING_RULE = [
    "",
    "★ WAVE 7 ROUND 4 -- THESE LABELS NOW CARRY THE RECORD'S OWN NAME.",
    "A label used to read `ToneRec_017`, which says WHERE the record sits and",
    "nothing about what it is.  It now reads `ToneRec_017_<Name>`, where <Name>",
    "is the CamelCase form of the record's OWN 16 ASCII bytes at offset 0 --",
    "data read out of the image, not a guess about it.  The ordinal stays in",
    "front so the label is still unique and still sorts in record order.",
    "",
    "Evidence: the name is the record's first 16 bytes, and every one of the 274",
    "tone records and 504 drum-instrument records has a fully printable one",
    "(notes/prom_d_understanding_round4.py Q3a/Q3b).  The 274 CamelCase forms are",
    "distinct, so a tone label names exactly one record (Q3c); the drum forms are",
    "NOT distinct -- 'TublarBellC' occurs four times -- which is why the ordinal",
    "must stay (Q3c').  ★ AND THE NAMES CROSS AN ARCHITECTURE BOUNDARY: 202 of",
    "the 274 tone names and 101 of the 504 drum names occur VERBATIM in the",
    "KN7000's table ROM, an MN10300 machine (Q3e/Q3f), so they are strings this",
    "family of instruments really uses and not an artefact of reading these bytes",
    "as text.",
    "⚠ A name says what the record is CALLED.  It does not identify one field",
    "inside the record, and nothing below claims it does.",
]


TONE_HDR = [
    "TONE RECORD.  Layout, established in scripts/analysis/prom_d_tone_database.py:",
    "",
    "    +0x000  16 B   name, ASCII, space-padded and centred",
    "    +0x010   1 B   RECORD-TYPE byte.  Not identified, but not free either:",
    "                  it is 0x80 in all 18 drum kits and in no melodic record,",
    "                  0x10 in 248 of the 254 melodic records, 0x00 in 6 and",
    "                  0x71 in the two Drawbar ones.  The KN5000 sub-CPU branches",
    "                  on bits 7:6 of the SAME byte of ITS tone record -- see",
    "                  ../kn5000-roms-disasm/symbols/proposals/subcpu-region-12.txt",
    "                  line 136.  That is the KN5000's code, not this machine's.",
    "    +0x011   1 B   ELEMENT MASK -- four 2-bit fields, one per element slot.",
    "                   A field is 01 when that slot is present, 00 when absent;",
    "                   the number of set fields is exactly N below, over all 253",
    "                   fixed-layout records, with no value shared between two",
    "                   different N.  The KN5000 tone record carries the SAME",
    "                   mask at the SAME offset, but its set-field count is N-1:",
    "                   it has an implicit first element (519 records, N=1..4,",
    "                   no exception).",
    "    +0x012 199 B   common part, fields unidentified",
    "    +0x0D9  81*N   N element blocks (the 81-byte block below)",
    "    +0x0D9   43*N  N wave-select records, 43 bytes each",
    "           +81*N   (43 = the directory's own stride word at +0xEA)",
    "",
    "so the record is 217 + N*124 bytes, N = 1..4: 341/465/589/713.",
    "",
    "The 81/43 cut is not an assumption.  Sweeping the split of the 124-byte",
    "per-element budget over W = 20..104 and scoring by total column entropy of",
    "the two stacked populations puts W=81 at 221.1 bits against 324.2 for the",
    "next best W -- a 103-bit gap -- and an interleaved reading (A0 B0 A1 B1 ...)",
    "costs a further 117 bits.  Independently, directory slot +0xAC points at a",
    "single 124-byte default block that is exactly one 81-byte element block",
    "followed by one 43-byte wave-select record.",
    "",
    "The 81-byte element block IS THE KN5000'S.  KN5000 tone records are",
    "21 + 81*N (../kn5000-roms-disasm/analysis/disk-format-probes/"
    "README-lsw-voice-selector-names.md), and stacking all 1637 KN5000 element",
    "blocks against all 451 WSA1 ones, 63 of 81 columns share their modal byte,",
    "against 18-29 for every byte-shift and every rotation null.  What differs",
    "between the two machines is the head (217 B here, 21 B there) and the extra",
    "per-element 43-byte wave-select array, which the KN5000 does not have.",
    "",
    "⚠ NOT established: the meaning of any field inside the head, the element",
    "block or the wave-select record.  Round 3 reads a consumer's ADDRESS",
    "arithmetic; it does not read a field.",
    "",
    "Evidence: ★ 217 AND 81 ARE LITERALS IN prom_c.  One routine computes an",
    "element block's address as record + 217 + 81*index:",
    "    0xFB436D  ld C,0x51             81, the element-block stride",
    "    0xFB436F  mul BC,H              * the element index",
    "    0xFB4373  add XBC,0x000000d9    + 217, the record head",
    "    0xFB4379  add XBC,(XIZ+0x08)    + the tone record",
    "and its other arm, taken when the element index is the sentinel 0xFF",
    "(0xFB4351 `cp A,0xff`), loads directory slot +0xAC instead -- which is why",
    "ToneDB_DefaultLayerParams is called a fallback.  The record itself is",
    "reached from ToneDB_ToneOffsetTable at 0xFB429D/0xFB429F.  Every instruction",
    "quoted is re-decoded from prom_c's ROM bytes by",
    "notes/prom_d_documentation_round3.py Q4a/Q4b.",
    "",
    "So the 81-byte cut, which this file used to justify by an entropy sweep and",
    "by the 124-byte block at slot +0xAC, now has a third and independent",
    "witness in the firmware; and a FOURTH from another CPU architecture entirely:",
    "",
    "★ CROSS-TREE.  The KN7000 (2002) is an MN10300 machine -- a different",
    "instruction set -- and its table ROM shares data with this image.  195 of the",
    "252 distinct sixteen-character 0x10-terminated name fields in the four WSA1",
    "images occur VERBATIM in that ROM, and every one of the 195 is in prom_d",
    "(0 in prom_a, prom_b or prom_c).  Of the 250 guarded binary runs prom_d",
    "shares with it, 74 -- the modal gap, and the largest class by a factor of",
    "2.6 over the next -- are exactly 81 BYTES APART: the per-element stride",
    "derived here from prom_d alone.  Two methods, two CPU architectures, one",
    "number.  notes/wave7_xref_mn10300_family.py section 4 (the runs need its",
    "entropy AND first-difference guards); the 195/252 is re-derived by a second",
    "path, off the collection's already-linear table image, in",
    "notes/prom_d_documentation_round3.py Q6.",
    "⚠ NOT claimed: which way the data travelled, or what any shared field means.",
]


def emit_tone_record(p, end):
    idx = IDX_OF[p]
    size = end - p
    n = (size - 217) // 124 if (size - 217) % 124 == 0 else None
    if n is None:
        extra = ("%d B -- NOT 217 + N x 124; see the DRAWBAR note" % size)
    else:
        extra = ("%d B = 217 + %d x (81+43),  element mask +0x11 = 0x%02X"
                 % (size, n, D[p + 0x11]))
    for ln in tone_hdr_lines(p, idx, extra):
        W(ln)
    lab = "ToneRec_%03X_%s" % (idx, tone_name(p))
    W("%s:" % lab)
    e_ascii(p, 16)
    if n is None:
        e_bytes(p + 16, end)
        return
    W("\t; common part")
    e_bytes(p + 16, p + 217)
    for i in range(n):
        a = p + 217 + 81 * i
        W("%s_Elem%d:" % (lab, i))
        e_bytes(a, a + 81)
    for i in range(n):
        a = p + 217 + 81 * n + 43 * i
        W("%s_WaveSel%d:" % (lab, i))
        e_bytes(a, a + 43)


def emit_melodic_block():
    banner("MELODIC TONE RECORDS -- tone indices 0x000-0x0FF (254 of the 256 here)",
           0x13C8, GUNSHOT_END, TONE_HDR + NAMING_RULE + [
               "",
               "Records appear in file order, not tone-index order.  The two missing",
               "indices are 0x058 and 0x059, the 541-byte '<<< Drawbar n>>>' records,",
               "which live at 0x446B4 with the drawbar descriptor block.",
           ])
    for p in MEL:
        if p < 0x40000:
            emit_tone_record(p, TONE_END[p])


region(0x13C8, GUNSHOT_END, emit_melodic_block)


# --- +0xAC / +0xB0 / +0xB4 templates --------------------------------------
def emit_default_layer():
    banner("ToneDB_DefaultLayerParams -- directory slot +0xAC", S(0xAC), S(0xB0), [
        "Exactly 124 bytes: one 81-byte element block followed by one 43-byte",
        "wave-select record.  The KN5000's slot +0xAC has the same name and the",
        "same role -- 'fallback descriptor bound when a patch partial is absent'.",
        "This block is the second, independent witness for the 81+43 cut.",
    ] + ev_slot(0xAC, [
        "",
        "★ AND `FALLBACK` IS NOW prom_c's WORD, not a borrowed one.  0xFB4351",
        "`cp A,0xff` / 0xFB4354 `jr NZ` splits two arms of one routine:",
        "  A == 0xFF -> 0xFB435B `ld XWA,(XBC+0x00ac)`, i.e. THIS block;",
        "  otherwise -> 0xFB436D `ld C,0x51` (81) / 0xFB436F `mul BC,H` /",
        "               0xFB4373 `add XBC,0x000000d9` (217) / 0xFB4379 add the",
        "               tone record, i.e. record + 217 + 81*index.",
        "So the sentinel 0xFF selects this 124-byte block IN PLACE OF an element",
        "block, which is exactly what a fallback is.",
        "notes/prom_d_documentation_round3.py Q4b decodes both arms from bytes.",
    ]))
    W("ToneDB_DefaultLayerParams:")
    W("ToneDB_DefaultLayerParams_Elem:")
    e_bytes(S(0xAC), S(0xAC) + 81)
    W("ToneDB_DefaultLayerParams_WaveSel:")
    e_bytes(S(0xAC) + 81, S(0xB0))


region(S(0xAC), S(0xB0), emit_default_layer)


def emit_clear_template():
    p, end = S(0xB0), S(0xB4)
    banner("ToneRec_Template_Clear -- directory slot +0xB0", p, end, [
        "A tone record in the ordinary 217 + N*124 layout with N = 4 (713 bytes),",
        "named '     Clear      '.  It is NOT in the offset table, so it is not a",
        "selectable tone: it reads as the blank template a user tone starts from,",
        "the same role the 'Clear' entry plays in the IC28 combination bank",
        "(../technics_roms/tools/wsa1_rom_anatomy.py, Q4a).",
        "",
        "⚠ The KN5000's slot +0xB0 is PercName_Pack, packed 10-char percussion",
        "names.  prom_d's content is not that, so the KN5000 name is NOT used.",
    ] + ev_slot(0xB0, [
        "",
        "⚠ The reader proves the slot is FETCHED, not what the record is FOR.",
        "'the blank template a user tone starts from' remains an inference from",
        "the name and from the IC28 combination bank, and is labelled as one.",
    ]))
    emit_tone_record_named("ToneRec_Template_Clear", p, end)


def emit_tone_record_named(label, p, end):
    size = end - p
    n = (size - 217) // 124
    assert (size - 217) % 124 == 0
    W("%s:" % label)
    e_ascii(p, 16)
    e_bytes(p + 16, p + 217)
    for i in range(n):
        a = p + 217 + 81 * i
        W("%s_Elem%d:" % (label, i))
        e_bytes(a, a + 81)
    for i in range(n):
        a = p + 217 + 81 * n + 43 * i
        W("%s_WaveSel%d:" % (label, i))
        e_bytes(a, a + 43)


region(S(0xB0), S(0xB4), emit_clear_template)

PERC_STRIDE = u16(0xEE)
PERC_HDR = [
    "DRUM-INSTRUMENT RECORD, stride %d = the directory's own word at +0xEE." % PERC_STRIDE,
    "",
    "    +0x00  13 B   name, ASCII, space-padded  ('Rock Bass Drm', 'Slap Shot')",
    "    +0x0D 137 B   parameters, unidentified",
    "",
    "Same directory slot and same shape as the KN5000's PercInst_000_Silent",
    "block (stride 58 there).  Every one of the 504 records in this image starts",
    "with 13 printable bytes.",
]


def emit_silent_template():
    p, end = S(0xB4), S(0x0C)
    banner("PercInst_Template_Silent -- directory slot +0xB4", p, end, PERC_HDR + [
        "",
        "One record, byte-identical to drum-instrument record 0 at slot +0x78.",
        "⚠ The KN5000 leaves slot +0xB4 unused.",
    ] + ev_slot(0xB4, [
        "",
        "The reader at 0xFBA5C9 is followed at 0xFBA5DD by `ld C,0x96` and",
        "0xFBA5DF `mul BC,(XIZ+0xc2)` -- 150, this record class's stride -- so the",
        "same routine addresses both this template and the 150-byte array.",
    ]))
    W("PercInst_Template_Silent:")
    e_ascii(p, 13)
    e_bytes(p + 13, p + PERC_STRIDE)
    e_gap(p + PERC_STRIDE, end)


region(S(0xB4), S(0x0C), emit_silent_template)


# --- generic emitters for the repeated section kinds ----------------------
def mk_indexmap(slot, extra_note=None):
    def fn():
        a, b = S(slot), NEXT[S(slot)]
        n = (b - a) // 2
        vals = [u16(a + 2 * i) for i in range(min(1024, n))]
        real = [v for v in vals if v != 0xFFFF]
        lines = [
            "%d LE16 entries." % n,
            "The first 1024 form the index map proper: max value %d, %d distinct."
            % (max(real), len(set(real))),
            "KN5000 label at the same directory slot: %s." % SLOT[slot][2],
            "⚠ What the index SELECTS is not established here; the value ranges are",
            "recorded because they pin which catalogue or record array each map can",
            "possibly address (see notes/FINDINGS-prom-d-tone-database.md).",
        ]
        if extra_note:
            lines.extend(extra_note if isinstance(extra_note, list) else [extra_note])
        # ⚠ THE HIGH END IS NOT ALWAYS A DIRECTORY VALUE, AND THIS USED TO CLAIM IT
        # WAS AT ALL TWELVE SITES.  At slot +0x28 the cut is 0x22A3B, which is NOT
        # among the 44 directory words -- the next one after 0x2223B is 0x22D3B --
        # and what actually ends the map there is ToneDB_DescCurveBank starting at
        # that address (2,816 - 2,048 = 768 = its six 128-byte curves).
        # The correction was made once by hand in the GENERATED .s (commit 1706229)
        # and regenerating this file silently put the false wording back. That is
        # why it now lives here, in the generator, and is DERIVED per slot rather
        # than asserted: emitting the "directory" sentence for a cut that is not a
        # directory value is impossible by construction.
        b_is_dir = b in set(DIR)
        if b_is_dir:
            high = ["0x%05X, which is directory slot +0x%02X's value, and ends at 0x%05X,"
                    % (a, slot, b),
                    "which IS the next value in the same directory.  So the entry count %d"
                    % n,
                    "is pinned at BOTH ends by the image's own table and is not a stride",
                    "guess -- the failure mode this tree has paid for."]
        else:
            high = ["0x%05X, which is directory slot +0x%02X's value.  It ends at 0x%05X,"
                    % (a, slot, b),
                    "which is ⚠ NOT a directory value -- the next directory word after",
                    "0x%05X is 0x%05X.  The high end is pinned instead by the object that"
                    % (a, min([v for v in DIR if v > a], default=0)),
                    "begins at 0x%05X.  So the low end is directory-pinned, the high end" % b,
                    "is pinned by its neighbour, and the count %d still stands -- but not" % n,
                    "for the reason this header used to give."]
        lines += [
            "",
            "Evidence: (image-internal, NOT from code) this region begins at",
        ] + high + [
            "The value range above is measured over all %d entries, first to last." % n,
        ] + ev_slot(slot, INDEXMAP_CHAIN(slot) if _R3.readers(slot) else ())
        banner("%s -- directory slot +0x%02X" % (slot_label(slot), slot), a, b, lines)
        W("%s:" % slot_label(slot))
        e_shorts(a, b)
    return fn



_WS_BLOCKS = _R6.tone_wavesel_blocks()
_WS_BY_KEY = {(t, j): b for t, j, b, _nm in _WS_BLOCKS}


def _tone_wavesel_byte(twin_entry):
    """The tone side's own +0x0B, for the one-byte difference a header states."""
    return _WS_BY_KEY[(twin_entry[0], twin_entry[1])][0x0B]


def _nearest_tone_distance(off):
    """Hamming distance from a 43-byte record to the closest tone wave-select block.

    Stated per record so "no twin" is a MEASUREMENT and not an absence of one.
    """
    r = D[off:off + 43]
    return min(sum(1 for x, y in zip(r, b) if x != y) for _t, _j, b, _n in _WS_BLOCKS)


def mk_wavesel_array(slot):
    def fn():
        a, b = S(slot), NEXT[S(slot)]
        n = (b - a) // 43
        assert (b - a) % 43 == 0
        banner("%s -- directory slot +0x%02X" % (slot_label(slot), slot), a, b, [
            "%d wave-select records of 43 bytes -- the span divides exactly, and 43" % n,
            "is the directory's own stride word at +0xEA / +0xF0.",
            "The same 43-byte record is the second per-element array of every tone",
            "record and the tail of ToneDB_DefaultLayerParams.",
            "KN5000 label at the same directory slot: %s." % SLOT[slot][2],
            "⚠ Field meanings NOT established -- EXCEPT +0x0B, which wave 7 round 5",
            "identified as a 6-bit preset number; see below.  And ⚠ CORRECTED in round 2:",
            "the leading 7F 7F 7F and the 7D 80 54 at +0x0D are NOT in every record.",
            "Counted over this array, first record to last: %d of %d start 7F 7F 7F"
            % (sum(1 for i in range(n) if D[a + 43 * i:a + 43 * i + 3] == b"\x7f\x7f\x7f"), n),
            "and %d of %d carry 7D 80 54 at +0x0D.  The earlier text said 'every"
            % (sum(1 for i in range(n) if D[a + 43 * i + 13:a + 43 * i + 16] == b"\x7d\x80\x54"), n),
            "record examined', which was the first record quoted as a universal.",
            "Re-derived by notes/prom_d_structures_round2.py section Q4b.",
        ] + WAVESEL_EV(slot, a, b, n) + ev_slot(slot, WAVESEL_CHAIN(slot))
          + WAVESEL_GAP(slot))
        W("%s:" % slot_label(slot))
        # ★ ROUND 5: the +0x20 array is the ONE of the three where a per-record
        # header can say something that DIFFERS per record -- which drum-instrument
        # records carry these exact 43 bytes.  The other two arrays get no
        # per-record header, because there the only true statement ("no copy
        # anywhere in the payload") is the same 322 and 64 times over and repeating
        # it would be padding, not prose.  That asymmetry is deliberate.
        car = _R5.perc_carriers() if slot == 0x20 else None
        # ★ ROUND 6 makes the +0x18 array per-record-headed too.  Round 5's reason
        # for leaving it bare was that the only true statement about a record ("no
        # copy anywhere in the payload") was the same 322 times over.  That is no
        # longer the only true statement: 167 of them now have a DIFFERENT fact
        # each -- which tone's wave-select block they duplicate -- and the other
        # 155 have the measured distance that says no tone's does.
        twin = TWIN.get(slot)
        for i in range(n):
            if slot == 0x3C:
                # ★ ROUND 5: this array's records SELF-IDENTIFY.  Each header states
                # the record's own +0x0B and whether its low 6 bits are its index --
                # a different fact per record, and the one that makes the numeric
                # suffix a MEANING rather than a position.
                _b = D[a + 43 * i + 0x0B]
                W("")
                W("; %s_%03d -- file 0x%05X..0x%05X"
                  % (slot_label(slot), i, a + 43 * i, a + 43 * (i + 1) - 1))
                if i:
                    W("; Selected when a wave-select record's field +0x0B & 0x3F == %d."
                      % i)
                else:
                    W("; ⚠ NOT SELECTABLE by prom_c's sub_FBC725: the index this")
                    W("; record would need is 0, and 0xFBC74E `jr NZ` sends index 0")
                    W("; down the other arm, which builds the tail from RAM 0x1523")
                    W("; instead of from this array.  What this record is FOR is")
                    W("; therefore open.  round 5 Q7b.")
                if (_b & 0x3F) == i:
                    W("; This record's own +0x0B is 0x%02X, and 0x%02X & 0x3F = %d --"
                      % (_b, _b, i))
                    W("; it carries its own index.%s"
                      % ("  Bit 6 is SET and the mask strips it."
                         if _b & 0x40 else ""))
                else:
                    W("; ⚠ Its own +0x0B is 0x%02X, whose low 6 bits are %d, NOT %d."
                      % (_b, _b & 0x3F, i))
                    W("; This is the ONE record of the %d that does not carry its own"
                      % n)
                    W("; index, and prom_c's 0xFBC74E `jr NZ` can never reach it:")
                    W("; index 0 takes the other arm.  round 5 Q7b.")
                # ★ ROUND 8: what SELECTS this preset, counted over the whole
                # image rather than asserted.  The only stored field that can is
                # +0x0B of a wave-select record, so the census is exact.
                _who = PRESET_REFS.get(i, [])
                if _who:
                    W("; ★ %d stored record%s in this image hold%s %d in the low 6"
                      % (len(_who), "" if len(_who) == 1 else "s",
                         "s" if len(_who) == 1 else "", i))
                    W("; bits of their own +0x0B, so they select this record.  The")
                    W("; first is %s.  round 8 Q2." % _who[0])
                else:
                    W("; ⚠ AND NO STORED RECORD EVER DOES.  Every")
                    W("; wave-select record in prom_d was read -- the three 43-byte")
                    W("; arrays, the tone records' per-element blocks and the drum")
                    W("; records' tails -- and none holds %d in the low 6 bits of" % i)
                    W("; its +0x0B.  Only a value written at runtime can reach this")
                    W("; record.  round 8 Q2.")
                W("; Evidence: this record's own byte +0x0B is at file 0x%05X and"
                  % (a + 43 * i + 0x0B))
                W("; holds 0x%02X; prom_c 0xFBC744 `and A,0x3f` (bytes c9 cc 3f) is"
                  % _b)
                W("; what makes its low 6 bits, %d, the index into this array."
                  % (_b & 0x3F))
            if slot == 0x18:
                t = twin[i]
                W("")
                W("; %s_%03d -- file 0x%05X..0x%05X"
                  % (slot_label(slot), i, a + 43 * i, a + 43 * (i + 1) - 1))
                if t:
                    _who = sorted(set(x[2] for x in t))
                    W("; These 43 bytes are the wave-select block of %s,"
                      % ("tone record %s, element %d" % (t[0][2], t[0][1])
                         if len(t) == 1 else
                         "%d tone-record elements (%s%s)"
                         % (len(t), ", ".join(_who[:3]),
                            ", +%d more" % (len(_who) - 3) if len(_who) > 3 else "")))
                    W("; with ONE byte changed: +0x0B, which round 5 proved is the")
                    W("; preset number prom_c writes over.  This record holds 0x%02X"
                      % D[a + 43 * i + 0x0B])
                    W("; there; the tone's own block holds 0x%02X."
                      % _tone_wavesel_byte(t[0]))
                    if DISJ[slot].get(i):
                        W("; ★ THE LABEL NAMES ALL %d OF THEM, joined by `_Or_`: these"
                          % len(_who))
                        W("; 43 bytes are the block %s carries and the block%s %s"
                          % (_who[0], "" if len(_who) == 2 else "s",
                             " and ".join(_who[1:])))
                        W("; carr%s.  Nothing here picks one, and the label does not"
                          % ("ies" if len(_who) == 2 else "y"))
                        W("; pretend to.  round 8 Q3, bound %d names." % MAX_NAMES)
                        W("; Evidence: the 43-byte runs, compared byte for byte;")
                        W("; each name in the label is that TONE record's own 16")
                        W("; ASCII bytes.  notes/prom_d_inventory_round8.py Q3.")
                    elif TWIN_LABEL[slot].get(i):
                        W("; Evidence: the two 43-byte runs, compared byte for byte;")
                        W("; the tone name is that record's own 16 ASCII bytes.")
                        W("; notes/prom_d_understanding_round6.py Q2.")
                    else:
                        W("; ⚠ NO LABEL: the %d blocks that carry these bytes belong to"
                          % len(t))
                        W("; %d DIFFERENTLY NAMED tone records -- more than round 8's"
                          % len(_who))
                        W("; bound of %d, so a disjunction would enumerate a family"
                          % MAX_NAMES)
                        W("; rather than name an object.  round 6 Q1, verdict")
                        W("; NAMELESS-AMBIGUOUS; round 8 Q3.")
                        _m10_conflict(i, t)
                else:
                    W("; ⚠ NO tone wave-select block is within one byte of these 43")
                    W("; bytes -- one of the %d records of this array with no twin,"
                      % sum(1 for v in twin.values() if not v))
                    W("; against %d that have one.  The nearest tone block differs in"
                      % sum(1 for v in twin.values() if v))
                    W("; %d of the 43.  round 6 Q1, verdict NAMELESS-NO-TWIN."
                      % _nearest_tone_distance(a + 43 * i))
                    # ★ ROUND 10.  The SECOND route, asked of exactly these records.
                    _cols = SEL_COLS.get(i)
                    _nms = SEL_NAMES.get(i, ())
                    if not _cols:
                        W("; ⚠ AND NOTHING SELECTS IT EITHER.  All 1,024 entries of")
                        W("; ToneDB_ToneIndexMapA (slot +0x%02X) were read and NONE"
                          % SEL_MAP_SLOT)
                        W("; holds %d.  That is a census over the whole map, not a" % i)
                        W("; rule failing to fire.  round 10 Q19.")
                    elif SEL_LABEL.get(i):
                        W("; ★ BUT SOMETHING SELECTS IT, and that is this label.")
                        W("; ToneDB_ToneIndexMapA holds %d at program column%s %s"
                          % (i, "" if len(_cols) == 1 else "s",
                             ", ".join(str(c) for c in _cols[:6])))
                        W("; of its 8 x 128 grid, and across all %d melodic rows"
                          % MELODIC_ROWS)
                        W("; %s of ToneNumBank_Melodic carr%s %d tone"
                          % ("that column" if len(_cols) == 1 else "those columns",
                             "ies" if len(_cols) == 1 else "y", len(_nms)))
                        W("; name%s: %s." % ("" if len(_nms) == 1 else "s",
                                             ", ".join(_nms)))
                        W("; ⚠ WHAT `_SelectedFor_` CLAIMS is exactly that and no")
                        W("; more.  It does NOT say this record is that tone's")
                        W("; mixer setting: the 99-read directory census finds %d"
                          % SEL_READERS[0])
                        W("; prom_c reads of slot +0x%02X and %d of slot +0x%02X, so"
                          % (SEL_MAP_SLOT, SEL_READERS[1], 0x18))
                        W("; this is a relation between two TABLES and not evidence")
                        W("; about what the machine does with either; the array's")
                        W("; role is still a transplanted KN5000 name.  The name is")
                        W("; taken over the whole COLUMN because the ROW half of the")
                        W("; index is not pinned -- the true row alignment beats the")
                        W("; best wrong one by only %d of %d positions (%.1f%% vs"
                          % (SEL_MARGIN[1] - SEL_MARGIN[2], SEL_MARGIN[0],
                             100.0 * SEL_MARGIN[1] / SEL_MARGIN[0]))
                        W("; %.1f%%, round 10 Q16d), so a label that needed the row"
                          % (100.0 * SEL_MARGIN[2] / SEL_MARGIN[0]))
                        W("; to be right would rest on that margin.  Over the column")
                        W("; it is invariant under all %d rotations." % MELODIC_ROWS)
                        W("; Evidence: map entries at file 0x%05X + 2*(row*128 + col)"
                          % S(SEL_MAP_SLOT))
                        W("; for col in %s; the tone names are those tone records'"
                          % ", ".join(str(c) for c in _cols[:6]))
                        W("; own 16 ASCII bytes.  notes/prom_d_inventory_round8.py")
                        W("; Q16-Q19; the same map is round 6 Q2b's second witness.")
                    elif len(_nms) > MAX_NAMES:
                        W("; ★ AND THE SELECTOR IS ASKED TOO, and refuses: the map")
                        W("; holds %d at %d program column%s, and across the %d"
                          % (i, len(_cols), "" if len(_cols) == 1 else "s",
                             MELODIC_ROWS))
                        W("; melodic rows %s carr%s %d different tone"
                          % ("that column" if len(_cols) == 1 else "those columns",
                             "ies" if len(_cols) == 1 else "y", len(_nms)))
                        W("; names -- more than round 8's bound of %d, so a" % MAX_NAMES)
                        W("; disjunction would enumerate a family rather than name")
                        W("; an object.  round 10 Q19.")
                        _m10_lines(i)
                    else:
                        W("; ★ AND THE SELECTOR IS ASKED TOO, and refuses for the")
                        W("; other reason: the map holds %d at program column%s %s,"
                          % (i, "" if len(_cols) == 1 else "s",
                             ", ".join(str(c) for c in _cols[:6])))
                        W("; and the only tone name there is %r, which is what this"
                          % " / ".join(_nms))
                        W("; tree's CamelCase rule makes of tone record 0x05D's own")
                        W("; 16 bytes, \"    16' & 1'    \".  A label ending in")
                        W("; digits reads as positional, so the name is refused")
                        W("; rather than spelled some other way -- inventing a")
                        W("; morpheme is round 3's `Home` failure.  round 10 Q19e.")
                        _m10_lines(i)
            if car is not None:
                ks = car[i]
                W("")
                W("; %s_%03d -- file 0x%05X..0x%05X"
                  % (slot_label(slot), i, a + 43 * i, a + 43 * (i + 1) - 1))
                if ks:
                    W("; The last 43 bytes of %d drum-instrument record%s are these"
                      % (len(ks), "" if len(ks) == 1 else "s"))
                    W("; bytes exactly: %s."
                      % ", ".join("PercInst_%03d_%s" % (k, perc_name(k) if k else "Silent")
                                  for k in ks[:4])
                      + ("  (+%d more)" % (len(ks) - 4) if len(ks) > 4 else ""))
                    _pb = S(0x78) + PERC_STRIDE * ks[0]
                    W("; Evidence: drum-instrument record %d at file 0x%05X, its"
                      % (ks[0], _pb))
                    W("; bytes +107..+149 (file 0x%05X..0x%05X), compared byte for"
                      % (_pb + 107, _pb + 149))
                    W("; byte against this record.  round 5 perc_carriers().")
                    # ⚠ CORRECTED IN ROUND 6.  These three lines used to read "A
                    # carrier is NOT a name for this record", which contradicts the
                    # label the same record now carries.  What round 5 refused, and
                    # round 6 still refuses, is the POSITIONAL transfer from the
                    # +0x8C catalogue -- not the byte identity.
                    if DISJ[slot].get(i):
                        _nm = sorted(set(perc_name(k) if k else "Silent" for k in ks))
                        W("; ★ THE LABEL NAMES ALL %d OF THEM, joined by `_Or_`."
                          % len(_nm))
                        W("; Round 6 gave no label here because the %d names disagree;"
                          % len(_nm))
                        W("; round 8 states them all instead of stating none.  The")
                        W("; label picks no owner and `_Or_` is what says so.")
                        W("; Evidence: the 43-byte runs, compared byte for byte;")
                        W("; every name in the label is a drum-instrument record's")
                        W("; own 13 ASCII bytes.  notes/prom_d_inventory_round8.py Q3.")
                    elif TWIN_LABEL[slot].get(i):
                        _nm = sorted(set(perc_name(k) if k else "Silent" for k in ks))
                        if len(_nm) > 1:
                            # ⚠ CORRECTED IN ROUND 7.  These two lines used to read
                            # "differ only by a trailing digit", which was true of
                            # every record round 6 named and FALSE of the ten round 7
                            # adds -- TimpaniA..TimpaniG differ by a trailing LETTER.
                            # The remainders are derived per record and printed, so
                            # the sentence cannot go stale against its own labels.
                            _st = TWIN_LABEL[slot][i]
                            _rem = sorted(set(x[len(_st):] for x in _nm if x != _st))
                            W("; The %d names share the stem `%s` and differ"
                              % (len(_nm), _st))
                            W("; only in what follows it: %s."
                              % ", ".join("`%s`" % r for r in _rem[:8]))
                            W("; Each remainder begins with an upper-case letter or a")
                            W("; digit -- a CamelCase word boundary -- and is at most")
                            W("; %d characters.  That is round 7's rule; round 6 stated"
                              % _R7.MAX_REMAINDER)
                            W("; the same thing as `differ by a trailing digit`, which")
                            W("; the letter cases above do not satisfy.")
                        W("; ★ THE LABEL USES THIS, and it claims only what was")
                        W("; measured: `_SameAs_` means these bytes and that record's")
                        W("; bytes are the same, NOT that this record belongs to that")
                        W("; instrument.  ⚠ CORRECTED in round 6: these lines used to")
                        W("; say a carrier is not a name.  What is refused is the")
                        W("; POSITIONAL transfer from the %d-row catalogue at slot"
                          % PERC_OVERLAP[0])
                        W("; +0x8C, which names the same thing at the same index in")
                        W("; only %d of the %d rows the byte identity resolves, names"
                          % (ALIGN[1], ALIGN[0]))
                        W("; it at a DIFFERENT index %d times and names something no"
                          % ALIGN[2])
                        W("; drum record has %d times -- because it is a DIFFERENT"
                          % ALIGN[3])
                        W("; LIST.  round 6 Q3e.")
                    else:
                        _nm2 = sorted(set(perc_name(k) if k else "Silent" for k in ks))
                        W("; ⚠ NO LABEL: %d differently named drum-instrument records"
                          % len(_nm2))
                        W("; carry these same bytes -- more than round 8's bound of %d,"
                          % MAX_NAMES)
                        W("; so a disjunction would enumerate a family rather than")
                        W("; name an object.  round 6 Q1, verdict")
                        W("; NAMELESS-AMBIGUOUS; round 8 Q3.")
                else:
                    W("; NO drum-instrument record carries these bytes -- one of the")
                    W("; %d records of this array with no carrier at all, against %d"
                      % (sum(1 for v in car.values() if not v), PERC_OVERLAP[1]))
                    W("; that have one.  round 5 Q4c; round 6 Q1, verdict")
                    W("; NAMELESS-NO-TWIN.")
            # ★ ROUND 6: the label carries the twin's own name when the twins
            # agree on one, and stays a number when they do not.  Neither half is
            # typed here: both come from notes/prom_d_understanding_round6.py.
            _suffix = TWIN_LABEL.get(slot, {}).get(i)
            if _suffix:
                _tail = "_SameAs_" + _suffix
            elif slot == 0x18 and SEL_LABEL.get(i):
                # ★ ROUND 10.  A record with no twin, named by what POINTS AT it.
                _tail = "_SelectedFor_" + SEL_LABEL[i]
            elif slot == 0x18 and GRP_LABEL.get(i):
                # ★ ROUND 11.  The same pointer, read one level coarser: every
                # program column that reaches this record lies in ONE sound group,
                # and the group is an object the panel names.
                _tail = "_SelectedForGroup_" + GRP_LABEL[i]
            else:
                _tail = ""
            W("%s_%03d%s:" % (slot_label(slot), i, _tail))
            e_bytes(a + 43 * i, a + 43 * (i + 1), per=43)
    return fn


def _wrap72(text, indent=""):
    """Wrap prose to fit the file's 80-column comment width, with a fixed indent."""
    out, cur = [], indent
    for word in text.split():
        if len(cur) + len(word) + 1 > 76 and cur.strip():
            out.append(cur)
            cur = indent + word
        else:
            cur = (cur + " " + word) if cur.strip() else cur + word
    if cur.strip():
        out.append(cur)
    return out


def _m10_conflict(i, twins):
    """★ ROUND 11's refusal on a record whose TWO routes disagree.

    Emitted only where M10's bound is met but the record has a byte twin, which
    is the case round 10's rule -- never label a record that has one -- exists to
    prevent.  The disagreement is printed rather than left implicit.
    """
    gs = GRP_SETS.get(i, [])
    if not (1 <= len(gs) <= GRP_BOUND):
        return
    tg = sorted(set(TONE_GROUP(t)[0] for t, _j, _n in twins if TONE_GROUP(t)))
    W("; ★ AND ROUND 11's COARSER QUESTION SPLITS THE TWO WITNESSES, which is")
    W("; why this record keeps its number.  The map's columns all lie in sound")
    W("; group %d %r, so M10's bound of %d is met -- but the %d blocks that"
      % (gs[0], GRP_NAME(gs[0]).strip(), GRP_BOUND, len(twins)))
    for _ln in _wrap72("carry these bytes span group%s %s."
                       % ("" if len(tg) == 1 else "s",
                          ", ".join("%d %r" % (g, GRP_NAME(g).strip()) for g in tg)),
                       ""):
        W("; " + _ln)
    W("; Round 10's rule is never to label a record that HAS a twin, so that no")
    W("; derived name can contradict another,")
    W("; and this is the record that rule is for.")
    W("; notes/prom_d_inventory_round8.py Q22f.")


def _m10_lines(i):
    """★ ROUND 11's paragraph on one record of ToneDB_MixerDefaultTable.

    Emitted only where round 10 refused, and it says which of the two answers
    the coarser question got.  Both branches are derived from the same object --
    the sound groups of the tones in this record's map columns.
    """
    gs = GRP_SETS.get(i, [])
    if GRP_LABEL.get(i):
        W("; ★ ROUND 11 ASKS THE SAME COLUMNS A COARSER QUESTION and gets an")
        W("; answer: every tone above lies in ONE sound group, %r --"
          % GRP_NAME(gs[0]).strip())
        W("; number %d of the %d groups the panel selects with.  That is what"
          % (gs[0], GRP_COUNT))
        W("; `_SelectedForGroup_` claims, and it claims nothing else: the group")
        W("; holds %d tones and this label does not say which." % GRP_MEMBERS)
        W("; Evidence: tone index = %d*group + member (prom_a 0xFC230C `mul"
          % GRP_MEMBERS)
        W("; WA,0x0010` and 0xFC2317 `mul BC,0x0002` over the table at")
        W("; 0x%06X, whose entry k is the (program, bank) pair prom_d's own"
          % GRP_MEMBER_ADDR)
        W("; BankMap and ToneNumBanks resolve to tone k, %d of %d); the group's"
          % (GRP_RUN, GRP_RUN))
        W("; name is prom_b's own 16 ASCII bytes at 0x%06X + %d*%d."
          % (GRP_NAME_ADDR, 16, gs[0]))
        W("; notes/prom_d_inventory_round8.py Q21, Q22.")
    elif gs:
        W("; ★ AND ROUND 11's COARSER QUESTION IS ASKED TOO, and refuses: those")
        W("; columns span %d sound groups (%s), above" % (len(gs),
          ", ".join(GRP_NAME(g).strip() for g in gs[:4])))
        W("; M10's bound of %d.  A label naming %d groups would claim %d tones."
          % (GRP_BOUND, len(gs), len(gs) * GRP_MEMBERS))
        W("; notes/prom_d_inventory_round8.py Q22.")


def mk_catalogue(slot, foot_slot):
    def fn():
        a, b = S(slot), NEXT[S(slot)]
        n = (b - a) // 16
        assert (b - a) % 16 == 0
        banner("%s -- directory slot +0x%02X" % (slot_label(slot), slot), a, b, [
            "%d rows of 16 bytes: a 13-character ASCII name followed by 3 bytes." % n,
            "The row count is CONFIRMED by the block's own footer at directory slot",
            "+0x%02X, whose leading LE16 is %d." % (foot_slot, n),
            "KN5000 label at the same directory slot: %s." % SLOT[slot][2],
        ] + ev_slot(slot, CATALOGUE_CHAIN(slot, foot_slot)))
        W("%s:" % slot_label(slot))
        for i in range(n):
            e_ascii(a + 16 * i, 13)
            e_bytes(a + 16 * i + 13, a + 16 * i + 16, per=3)
    return fn


def mk_footer(slot, of_slot):
    def fn():
        a, b = S(slot), NEXT[S(slot)]
        banner("%s -- directory slot +0x%02X" % (slot_label(slot), slot), a, b, [
            "Self-sized: LE16 value, then a length byte n, then n bytes.",
            "The LE16 is %d, which is exactly the row count of the catalogue at" % u16(a),
            "directory slot +0x%02X.  That is what identifies these blocks." % of_slot,
            "KN5000 label at the same directory slot: %s." % SLOT[slot][2],
        ] + ev_slot(slot, FOOTER_CHAIN(slot, of_slot)) + ([] if 3 + D[a + 2] == b - a else [
            "⚠ 3 + %d = %d, but this region is %d bytes.  The %d extra byte(s) after"
            % (D[a + 2], 3 + D[a + 2], b - a, b - a - 3 - D[a + 2]),
            "the declared payload are the LAST bytes of the whole payload (it ends at",
            "0x50B08) and are not accounted for.",
        ]))
        W("%s:" % slot_label(slot))
        W("\t.short %d\t\t\t\t; row count of the +0x%02X catalogue" % (u16(a), of_slot))
        W("\t.byte 0x%02X\t\t\t\t; length of the payload that follows" % D[a + 2])
        e_bytes(a + 3, b)
    return fn


DESC_HDR = [
    "⚠ REFRAMED in wave 7 round 2.  This block used to be emitted as 'N x 14 +",
    "a remainder' and called SUPPORTED-not-proved, because nothing placed the",
    "leftover byte(s).  There is no remainder.  The block is an ARRAY of 14-byte",
    "descriptor records followed by a DATA POOL, and the descriptors' own 32-bit",
    "offsets say where the array stops:",
    "",
    "    descriptor  +0x00  1 B    tag",
    "                +0x01  LE32   file offset of part A   (0 = none)",
    "                +0x05  LE32   file offset of part B",
    "                +0x09  1 B    unidentified -- sub_FA73EB arg 2 (0xFA818C)",
    "                +0x0A  LE16   unidentified -- sub_FA73EB arg 3 (0xFA818C)",
    "                +0x0C  LE16   ★ the BASE PITCH: sub_FA814C reads it with",
    "                               `ld DE,(XWA+0x0C)` at 0xFA8160 through",
    "                               voice[+0x1F] and the sum lands in",
    "                               voice[+0x06], the pitch.  WAVE 14.",
    "",
    "Every non-null offset lands past the array and inside the block, and the",
    "SMALLEST of them is exactly where the array ends -- that is what proves the",
    "split, not a stride sweep.  The LAST descriptor's part-B offset is the last",
    "object in the pool, so both ends are pinned.  All of it is re-derived on",
    "every run of this generator by notes/prom_d_structures_round2.py, which",
    "refuses to emit if a boundary moved.",
    "",
    "⚠ ROUND 2 ENDED HERE with 'NO field inside a descriptor, a part A or a part",
    "B is identified'.  That sentence is now WRONG for three of them and is",
    "corrected rather than left standing: see THE INDEX CHAIN below, which",
    "identifies tag bit 7 and the ROLE of both offsets.  ⚠ AND CORRECTED AGAIN IN",
    "WAVE 14: +0x0C is the base pitch (above), and at slot +0x70 every field of",
    "an element is placed as well.  What is still unidentified is +0x09/+0x0A,",
    "and every byte of an element at slots +0x30 and +0x38.",
]


def chain_hdr(slot):
    """The round-4 index chain, stated with the counts that prove it."""
    if slot not in CHAIN:
        d = DRAWBAR
        e = d["elems"][:4]
        return ["",
                "★★ WAVE 14 -- WHAT THESE POOLS ARE.  This banner used to say THE",
                "INDEX CHAIN DOES NOT REACH THIS BLOCK and leave the objects with a",
                "positional name and a 'role NOT established'.  That was true of the",
                "curve -> stage 2 -> element chain, which needs a part A and finds",
                "four nulls -- and it was the wrong chain.  This block has a DIFFERENT",
                "reader and a different chain, and every step of it below is an",
                "instruction operand re-decoded from prom_c's ROM at the address",
                "cited.  notes/prom_d_drawbar_chain.py, %d checks with two nulls."
                % 65,
                "",
                "  A pool object is a %d x %d x %d TABLE OF DRAWBAR COMBINATIONS:"
                % (d["radix"], d["radix"], d["radix"]),
                "  %d records of %d bytes, one per setting of THREE drawbars of %d"
                % (d["ncombo"], d["stride"], d["radix"]),
                "  positions each, giving the composite waveform, the level trim and",
                "  the octave transpose for that combination.",
                "",
                "  stage 1  tone record +0x10 bits 7:6 == 0x40 marks a DRAWBAR tone.",
                "           0xFB47F3 `ld A,(XIY+0x10)` / `and A,0xC0` picks the arm in",
                "           sub_FB47C4; MidiNote_OnByPartMode tests the same field at",
                "           0xFB3877 and routes 0x40 to VoiceRegs_Stage_B.  Exactly %d"
                % len(d["tones"]),
                "           of the 274 tone records carry it: %s, the two Drawbar"
                % ", ".join("0x%02X" % t for t in d["tones"]),
                "           records immediately above this block.",
                "  stage 2  each of the tone's four element blocks carries THREE",
                "           NIBBLES at +0x02/+0x03.  sub_FC28B5 packs them --",
                "           0xFC28F3 `ld C,(XWA+0x02)`, 0xFC28FA `ld C,(XWA+0x03)` /",
                "           `sll 8`, 0xFC2906 `and DE,0x%04X` -- into RAM 0x00DC0E +"
                % d["mask"],
                "           23*part + 2*element, which is the LIVE drawbar setting.",
                "           All %d nibbles in both tones are 0..%d, the radix; over"
                % (3 * len(e) * len(d["tones"]), d["radix"] - 1),
                "           ordinary elements the same test passes only 57.7%.",
                "  stage 3  bits 5:4 of that SAME byte +0x03 pick one of the four",
                "           descriptors -- 0xFC2983 `ld C,(XWA+0x03)` / `and C,0x%02X` /"
                % d["sel_mask"],
                "           `srl 4,C` in DrawbarPreset_GetDescriptor, which multiplies",
                "           by the directory's own stride word +0xEC (14) and parks the",
                "           descriptor where voice[+0x1F] is loaded from (0xFB2078,",
                "           0xFB20F4).  Element i selects descriptor i, in both tones.",
                "  stage 4  Voice_StageRegs_0040_B takes the descriptor's PART B alone",
                "           -- 0xFA8278 `ld XBC,(XDE+0x1F)`, 0xFA827B `ld XWA,(XBC+0x05)`,",
                "           0xFA8281 `add XIX,(0x00D7ED)` -- converts the three nibbles",
                "           to a linear index with sub_FC355B's base %d,"
                % d["radix"],
                "           `mul BC,0x0051` (81) at 0xFC356E and `mul IY,0x0009` at",
                "           0xFC357D, i.e. n2*81 + n1*9 + n0, and indexes the table with",
                "           `mul WA,0x0006` at 0xFA82C2 and again at 0xFA82D0.",
                "",
                "★ THE STRIDE AND THE RADIX ARE THE READER'S, NOT THE POOL'S.  %d has"
                % (d["ncombo"] * d["stride"]),
                "%d divisors and any of them would reproduce these bytes, so a stride"
                % 15,
                "swept out of the data would have proved nothing.  6 and 9 are `ld`",
                "and `mul` operands in prom_c.",
                "",
                "★ AND THE CODOMAIN CLOSES, the way the +0x30 chain's joins do: the",
                "wave field of the two %d-record tables takes EXACTLY the contiguous"
                % d["ncombo"],
                "interval [0x%03X,0x%03X] -- %d values, no gap, nothing outside, and the"
                % (d["wave_lo"], d["wave_hi"], d["nwave"]),
                "two tables partition it (0x%03X..0x%03X, then 0x%03X..0x%03X)."
                % (d["wave_lo"], 0x27C, 0x27D, d["wave_hi"]),
                "",
                "★ KEYBOARD FOLDBACK, and it lands on the right elements.  prom_c",
                "folds the drawbar digits before the base-%d conversion: sub_FC3407"
                % d["radix"],
                "(element 0) merges the two low digits BELOW note %d -- 0xFC3427"
                % d["bass_fold"],
                "`ld IY,(XWA+0x3BCF)` / `srl 8` is the note number, 0xFC3440",
                "`cp HL,0x0024` is the threshold -- while sub_FC3480 (elements 1 and 2)",
                "folds the HIGH digit down in 12-semitone steps above note 96",
                "(0xFC34AD `sub BC,0x000C`, 0xFC34BC `cp DE,0x0054`).  The elements'",
                "own coarse transposes are %s semitones: the element that folds"
                % ", ".join("%+d" % c for c in d["coarse"]),
                "at the BASS end is the one transposed DOWN and the two that fold at",
                "the TREBLE end are the two transposed UP.  Nothing arranged that.",
                "",
                "★ AND THE TABLE PRECOMPUTES THE SAME FOLD.  Field +0x04 is non-zero",
                "in exactly the cells whose low digit is 0, and only ever 0x0C00 or",
                "0x1800 = one or two octaves in the pitch word's note<<8 units.",
                "",
                "★ THE LEVEL TRIM IS A MONOTONE MIXING SURFACE.  Read signed, as",
                "0xFAB66B `exts WA` reads it, descriptor 0's cube is non-decreasing on",
                "ALL 243 axis-parallel lines and descriptors 1/2's on 164 with a worst",
                "backward step of 3 in a 128-wide range -- rounding, not structure.",
                "Null: the wave field is monotone on 240 of the same 486 lines.",
                "",
                "⚠ WHAT IS STILL NOT ESTABLISHED.  That the nine values are 'the nine",
                "Hammond drawbars': what is measured is four elements, transposes",
                "%s, three 0..%d nibbles each.  The FOOTAGE reading"
                % (", ".join("%+d" % c for c in d["coarse"]), d["radix"] - 1),
                "(-12 = 16', 0 = 8', +7 = 5 1/3', +12 = 4') is an inference from the",
                "intervals and is marked as one.  Nor what descriptor 3's %d-record"
                % (d["pool"][2][1] // d["stride"]),
                "table selects: its element takes prom_c's h >= 3 arm at 0xFA82CC,",
                "where the slot word is used RAW with no base-%d conversion, so an"
                % d["radix"],
                "index space of 0..%d is exactly the right size and nothing says what"
                % (d["pool"][2][1] // d["stride"] - 1),
                "the four choices are.  Nor descriptor +0x09/+0x0A -- arguments 2 and 3",
                "of sub_FA73EB at 0xFA818C.  +0x0C IS placed: 0xFA8160",
                "`ld DE,(XWA+0x0C)` makes it the base pitch."]
    rows = CHAIN[slot]
    n = len(rows)
    e6 = sum(1 for r in rows.values() if r["esize"] == 6)
    e8 = n - e6
    # ⚠ P5.  The tag is TWO bits, not one -- prom_c tests bit 6 before bit 7.
    # These counts are what makes the one-bit reading correct FOR THIS BLOCK, so
    # they are derived here rather than asserted in the prose.
    _tags = [r[0] for r in DESC[slot][2]]
    _b6set = sum(1 for t in _tags if t & 0x40)
    _b6clear = len(_tags) - _b6set
    _odd = next(((i, t) for i, t in enumerate(_tags) if not t & 0x40), None)
    lines = [
        "",
        "★ THE INDEX CHAIN -- what the two pool objects per descriptor ARE.",
        "",
        "  stage 1  a ToneDB_DescCurve_*   %d entries, non-decreasing.  The" % CURVE_STRIDE,
        "                                  descriptor's part A begins with a 32-bit",
        "                                  file offset naming one of the %d curves." % CURVE_N,
        "  stage 2  part A, after that     a byte table, one entry per distinct",
        "                                  curve OUTPUT, yielding an element index.",
        "  stage 3  part B                 the element array itself.",
        "",
        "Each stage's codomain is EXACTLY the next stage's domain, with nothing",
        "unused and nothing missing.  That is the whole claim, and it is two",
        "joins measured over every descriptor in this block:",
        "",
    ]
    if slot == 0x30:
        lines += [
            "  JOIN 1   len(part A) - 4 == max(curve) + 1        %d of %d" % (n, n),
        ]
    else:
        r0 = next(iter(rows.values()))
        lines += [
            "  JOIN 1   all %d descriptors share ONE part A, a full %d-entry table"
            % (n, CURVE_STRIDE),
            "           of which max(curve)+1 = %d are addressable.  Nothing is"
            % (r0["curve_max"] + 1),
            "           packed after it, so its extent is not its used length and",
            "           the +0x30 form of this join is NOT claimed here.",
        ]
    # ⚠ A JOIN THAT SCORES n OF n IS NOT EVIDENCE IF ITS NULL ALSO SCORES n OF n.
    # At slot +0x38 the shared part-A table is ALL ZERO, so max(part A) is 0 for
    # every one of the 161 records, every part B is a single 6-byte element, and a
    # permutation null scores 161/161 as well -- the join cannot fail there and so
    # says nothing. At +0x30 it is real: 318/318 against a permutation null of
    # 64.2/318. The generator now states which case it is instead of printing the
    # same triumphant fraction for both.
    _amax = max((max(r["a_tab"]) if r.get("a_tab") else 0) for r in rows.values())
    lines += [
        "  JOIN 2   elements == max(part A) + 1               %d of %d" % (n, n),
    ] + ([
        "           ⚠ NOT INDEPENDENT EVIDENCE HERE: max(part A) is 0 in all %d" % n,
        "           records, every part B is one element, and a permutation null",
        "           scores %d of %d too.  A criterion that cannot fail is not a" % (n, n),
        "           pass.  Stated, not hidden." ] if _amax == 0 else []) + [
        "",
        "and the element SIZE is read out of the descriptor's own tag.  In THIS",
        "block that is bit 7 -- 6 bytes when it is clear (%d records here) and 8"
        % e6,
        "when it is set (%d).  ⚠ BUT THAT IS ONE ROW OF A TWO-BIT TABLE, and this"
        % e8,
        "block only ever shows the one row.",
        "",
        "★ WHAT prom_c ACTUALLY DOES -- ⚠ NEW, AND IT CORRECTS A SENTENCE THAT",
        "STOOD HERE.  Voice_SelectKeyZone_Reg0040 fetches the tag with",
        "`ld H,(XBC)` at 0xFA81F6 and tests BIT 6 FIRST -- `and W,0x40` at",
        "0xFA81FA -- and only then bit 7, once on each arm: `and D,0x80` at",
        "0xFA8203 and `and D,0x80` at 0xFA821C.  The four arms call four routines",
        "that are byte-identical over their first 0x1C bytes except ONE operand,",
        "the element size: `ld C,0x08` at 0xFA7470 against `ld C,0x06` at",
        "0xFA74B4, `ld C,0x06` at 0xFA74F6 and `ld C,0x04` at 0xFA7538.",
        "",
        "      tag bit6  bit7    routine     element size",
        "         1        1     0xFA7467          8",
        "         1        0     0xFA74AB          6",
        "         0        1     0xFA74ED          6",
        "         0        0     0xFA752F          4",
        "",
        "and bit 6 is SET in %d of the %d descriptors here, which is the whole"
        % (_b6set, n),
        "reason bit 7 alone describes this block.",
        "",
        "⚠ SO THE KN5000'S NOTE IS NOT AN OPPOSITE POLARITY.  What stood here read",
        "`⚠ ../kn5000-roms-disasm's note on the same field states the OPPOSITE",
        "polarity.  It is measured here, not borrowed`, and it reported a MISSING",
        "VARIABLE as a contradiction.  That tree says `bit 7 set -> 6, clear -> 4`",
        "and GUARDS it with `bit 6 is clear in every record here` -- and it is: 0 of",
        "its 487 descriptors have bit 6 set, against %d of %d here.  Its sub-CPU"
        % (_b6set, n),
        "routine WaveSel_StageB_Build_Reg040 (0x023893) tests bit 6, then bit 7,",
        "then bit 5, and its bit-6-CLEAR arm is the WSA1's exactly.  Two",
        "populations on opposite sides of bit 6; one table; neither measurement",
        "wrong.  The KN5000 tree is NOT corrected, because it is not wrong.",
        "",
        "★ AND THE COUNTER-EXAMPLE WAS ALREADY IN THIS FILE.  Slot +0x70's banner",
        "refuses the bit-7 rule because `tag 0x92 has bit 7 SET yet every object is",
        "a multiple of 6`.  0x92 has bit 6 CLEAR, so the two-bit table predicts 6:",
        "the refusal was right and what it refused was the incomplete rule.  Both",
        "machines' +0x70 descriptors carry that same 0x92.",
        "",
    ] + ([
        "⚠ THE SIZES EMITTED BELOW ARE STILL BIT 7's, and that is deliberate.  It",
        "is what this block's part-B LENGTHS say: JOIN 2 holds %d of %d with them"
        % (n, n),
        "and %d of %d with the two-bit rule.  The one record that separates them is"
        % (n - _b6clear, n),
        "descriptor %d, tag 0x%02X -- the only one here with bit 6 clear.  Its pool"
        % _odd,
        "object is 8 bytes and part A gives ONE element, so a 6-byte element would",
        "leave 2 bytes of slack, and a pool measured by DISTANCE TO THE NEXT OBJECT",
        "cannot see slack.  With one element the stride is multiplied by zero, so",
        "both readings address the SAME bytes at run time.  Nothing in this image",
        "separates them and neither is asserted over the other.",
    ] if _odd else [
        "⚠ HERE THE TWO READINGS CANNOT DISAGREE: bit 6 is set in all %d records," % n,
        "so the one-bit and the two-bit rule return the same size for every one of",
        "them, and this block is no evidence either way.  Said so it is not read as",
        "a confirmation.",
    ]) + [
        "",
        "Evidence: every instruction quoted above re-decodes from prom_c's ROM at",
        "the address cited; the four-way table, both machines' tag censuses and the",
        "KN5000's own dispatch are re-derived by notes/prom_d_desc_tag_bit67.py",
        "(13 checks, 7 controls).",
        "",
        "⚠ WHAT THIS DOES NOT SAY: what an element MEANS (no byte inside one is",
        "identified), and that the curve's index is a MIDI note -- %d entries is" % CURVE_STRIDE,
        "the note range and that is suggestive, but nothing here reads a note.",
        "",
        "Evidence: (image-internal, NOT from code) the two joins above, %d of %d"
        % (n, n),
        "and %d of %d, re-derived on every run of this generator by" % (n, n),
        "notes/prom_d_understanding_round4.py Q1, which refuses to emit if either",
        "count moves.  The LAST descriptor of the block is checked by name as well",
        "as the first, because a rule verified only on element 0 has been wrong in",
        "this tree before.",
    ]
    return lines


def desc_hdr(slot):
    """DESC_HDR plus the one line that differs per block: is it READ?"""
    if _R3.readers(slot):
        if slot in CHAIN:
            return DESC_HDR + ["⚠ And no field is identified even though the block "
                               "IS reached: see the Evidence",
                               "line below, which pins the ARRAY STRIDE and nothing "
                               "else."]
        # ★ WAVE 14: at slot +0x70 the reader DOES say what the fields are, and
        # the sentence above -- written when it did not -- would now be false.
        return DESC_HDR + ["★ AND AT THIS SLOT THE READER SAYS WHAT THE FIELDS "
                           "ARE.  The Evidence line",
                           "below pins the ARRAY STRIDE; THE INDEX CHAIN further "
                           "down pins the element",
                           "stride, the index, and every field of an element."]
    return DESC_HDR + ["⚠ And no prom_c instruction that reads THIS block has been "
                       "found; the Evidence",
                       "note below states what that leaves standing and what it does not."]


def desc_pool_labels(slot):
    """Address -> (label, comment) for every object in this block's pool."""
    H, P, recs = DESC[slot]
    lab = {}
    pts = sorted({o for t, o1, o2, b9, w10, w12 in recs for o in (o1, o2) if o})
    HERE_END = NEXT[S(slot)]
    nxt = {pts[k]: pts[k + 1] for k in range(len(pts) - 1)}
    owner = {}
    for i, (t, o1, o2, b9, w10, w12) in enumerate(recs):
        if o1:
            owner.setdefault(o1, ("A", i))
        if o2:
            owner.setdefault(o2, ("B", i))
    base = slot_label(slot)
    ch = CHAIN.get(slot)
    for p in pts:
        kind, i = owner[p]
        shared = sum(1 for _t, a1, a2, _b, _w, _v in recs
                     if (a1 if kind == "A" else a2) == p)
        if ch is None or i not in ch:
            # ★ WAVE 14.  Slot +0x70 has no part-A object at all, so round 4's
            # curve -> stage 2 -> element chain cannot start there -- and for
            # three rounds that left these objects with a POSITIONAL name and a
            # "role NOT established".  They are not positional any more: the
            # reader is Voice_StageRegs_0040_B, which takes part B alone, and
            # notes/prom_d_drawbar_chain.py derives the whole shape from it.
            n = (nxt.get(p, HERE_END) - p) // DRAWBAR["stride"]
            if n == DRAWBAR["ncombo"]:
                note = ("descriptor %d: %d records of %d B = %d^3 drawbar "
                        "settings, 0..%d each"
                        % (i, n, DRAWBAR["stride"], DRAWBAR["radix"],
                           DRAWBAR["radix"] - 1))
            else:
                note = ("descriptor %d: %d records of %d B -- element %d takes "
                        "prom_c's h >= 3 arm" % (i, n, DRAWBAR["stride"], i))
            if shared > 1:
                note += " (shared by %d descriptors)" % shared
            lab[p] = ("%s_%03d_ComboTable" % (base, i), note)
            continue
        r = ch[i]
        if kind == "A":
            name = "%s_%03d_CurveStepToElem" % (base, i)
            # ⚠ WAVE 7 ROUND 9.  This line used to state max(curve)+1 as THE ENTRY
            # COUNT.  That is true only where each descriptor has its own part A
            # (all 318 at slot +0x30).  The ONE part-A table that slot +0x38's 161
            # descriptors SHARE holds 128 entries and the curve reaches 108, so the
            # sentence stated 108 over a 132-byte object -- a number refuted by its
            # own object, which is the exact shape of the round-3 review failures.
            # The count is now the object's OWN length, and the curve's reach is a
            # second clause.  notes/prom_d_inventory_round8.py Q10d re-derives every
            # one of these sentences from the pool tiling and fails if one drifts.
            n_ent = r["a_len"] - 4
            note = ("descriptor %d stage 2: %s step -> element, %d entries"
                    % (i, CURVE_LABEL(r["curve_k"]), n_ent))
            note += (" = max(curve)+1" if n_ent == r["curve_max"] + 1 else
                     ", of which the curve reaches %d (max(curve)+1)" % (r["curve_max"] + 1))
        else:
            name = "%s_%03d_ElemArray" % (base, i)
            note = ("descriptor %d stage 3: %d element%s of %d B = max(stage 2)+1, "
                    "size from tag 0x%02X bit 7"
                    % (i, r["ecount"], "" if r["ecount"] == 1 else "s",
                       r["esize"], r["tag"]))
        if shared > 1:
            note += " (shared by %d descriptors)" % shared
        lab[p] = (name, note)
    return lab


def mk_desc_block(slot, extra):
    def fn():
        a, b = S(slot), NEXT[S(slot)]
        H, P, recs = DESC[slot]
        lab = desc_pool_labels(slot)
        banner("%s -- directory slot +0x%02X" % (slot_label(slot), slot), a, b,
               desc_hdr(slot) + [""] + extra + [
                   "",
                   "Here: %d descriptors x 14 = %d bytes, then a pool of %d bytes"
                   % (H, 14 * H, b - P),
                   "at 0x%05X..0x%05X, holding %d objects.  %d + %d = %d, the whole"
                   % (P, b - 1, len(lab), 14 * H, b - P, b - a),
                   "block, with nothing unaccounted for.",
                   "KN5000 label at the same directory slot: %s." % SLOT[slot][2],
               ] + chain_hdr(slot)
               + DESC_INTERNAL_EV(slot, H, P, recs) + ev_slot(slot, DESC_CHAIN(slot)))
        W("%s:" % slot_label(slot))
        for i in range(H):
            t, o1, o2, b9, w10, w12 = recs[i]
            W("%s_Desc%03d:\t\t; tag 0x%02X  A=%s  B=0x%05X"
              % (slot_label(slot), i, t, ("0x%05X" % o1) if o1 else "none", o2))
            e_bytes(a + 14 * i, a + 14 * (i + 1), per=14)
        W("")
        W("; ---- the pool ----")
        W("%s_Pool:" % slot_label(slot))
        pts = sorted(lab)
        ch = CHAIN.get(slot)
        for j, p in enumerate(pts):
            e = pts[j + 1] if j + 1 < len(pts) else b
            name, note = lab[p]
            W("")
            W("; %s -- file 0x%05X..0x%05X (%d bytes)" % (name, p, e - 1, e - p))
            W("; %s" % note)
            if name.endswith("_ComboTable"):
                d = DRAWBAR
                n = (e - p) // d["stride"]
                if n == d["ncombo"]:
                    W("; index = n2*%d + n1*%d + n0, each digit 0..%d -- prom_c's"
                      % (d["radix"] ** 2, d["radix"], d["radix"] - 1))
                    W("; sub_FC355B (`mul BC,0x0051` 0xFC356E, `mul IY,0x0009`")
                    W("; 0xFC357D), the digits being the element block's +0x02/+0x03")
                    W("; nibbles after keyboard foldback.")
                else:
                    W("; index arrives RAW from the slot record -- prom_c takes the")
                    W("; h >= 3 arm at 0xFA82CC, with no base-%d conversion, so the"
                      % d["radix"])
                    W("; index space is 0..%d.  What the %d choices ARE is NOT"
                      % (n - 1, n))
                    W("; established.")
                W(";")
                W("; struct DrawbarCombo {           /* %d B; stride from prom_c"
                  % d["stride"])
                W(";                                    `mul WA,0x0006` 0xFA82C2 */")
                W(";     uint16_t wave;              /* +0x00 -> RAM 0x00D760 ->")
                W(";                                    TG register chan+0x0040;")
                W(";                                    4-bit bank | 12-bit payload */")
                W(";     uint8_t  level_override;    /* +0x02 bit 7 = present, bits")
                W(";                                    6..4 = level; read by")
                W(";                                    Voice_StageLevel_Reg0080 at")
                W(";                                    0xFA7DE5.  0 in every record")
                W(";                                    of this block. */")
                W(";     int8_t   level_trim;        /* +0x03 sign-extended at")
                W(";                                    0xFAB66B and summed into")
                W(";                                    voice[+0x0D] -> register")
                W(";                                    0x0080 */")
                W(";     uint16_t pitch_offset;      /* +0x04 -> RAM 0x005A4F, which")
                W(";                                    Voice_PitchAddZoneOffset_AB")
                W(";                                    adds to the note pitch at")
                W(";                                    0xFA8330; 0x0C00 = 12")
                W(";                                    semitones */")
                W("; };")
                W("; notes/prom_d_drawbar_chain.py Q2, Q3, Q7.")
            if ch is not None and name.endswith("_CurveStepToElem"):
                r = ch[int(name.split("_")[-2])]
                sharers = sorted(k for k, q in ch.items() if q["a_at"] == p)
                W("; Its entries index %s_%03d_ElemArray, and they reach every"
                  % (slot_label(slot), r["i"]))
                W("; element of it and no further.")
                W("; Evidence: this table's largest entry is %d; that array is %d"
                  % (max(r["a_tab"]), r["b_len"]))
                W("; bytes / %d = %d elements, and %d + 1 = %d."
                  % (r["esize"], r["ecount"], max(r["a_tab"]), r["ecount"]))
                if len(sharers) > 1:
                    # ⚠ WAVE 7 ROUND 9.  The two lines above name ONE descriptor's
                    # part B.  Where a table is shared, saying only that reads as a
                    # claim about the table and is true only of that descriptor, so
                    # the sharing and the range are stated instead of implied.
                    W("; ⚠ AND THIS TABLE IS SHARED by descriptors %d..%d, so the"
                      % (min(sharers), max(sharers)))
                    W("; sentence above is descriptor %d's join, not the table's."
                      % r["i"])
                    W("; The same join holds for all %d of them: their part-B arrays"
                      % len(sharers))
                    _ec = sorted({ch[q]["ecount"] for q in sharers})
                    W("; hold %s element%s each."
                      % ("/".join(str(x) for x in _ec),
                         "" if _ec == [1] else "s"))
                W("; notes/prom_d_understanding_round4.py Q1, join 2.")
            elif ch is not None and name.endswith("_ElemArray"):
                r = ch[int(name.split("_")[-2])]
                # ⚠ This used to name %s_%03d_CurveStepToElem, a label that IS NOT
                # DEFINED anywhere -- 160 of 958 references in this prose dangled.
                # The stage-2 step table is not emitted as its own label at slot
                # +0x38 (all 161 records share ONE part-A table), so the prose now
                # names the object that actually exists.
                W("; Reached as %s[i] -> the shared stage-2 step"
                  % CURVE_LABEL(r["curve_k"]))
                W("; table of %s, entry %d -> this array."
                  % (slot_label(slot), r["i"]))
                W("; Evidence: %d bytes / %d = %d element%s, and the stage-2 table's"
                  % (r["b_len"], r["esize"], r["ecount"],
                     "" if r["ecount"] == 1 else "s"))
                W("; largest entry is %d, so %d + 1 = %d matches exactly.  The"
                  % (max(r["a_tab"]), max(r["a_tab"]), r["ecount"]))
                W("; element size %d is this descriptor's tag 0x%02X, bit 7 %s"
                  % (r["esize"], r["tag"], "SET" if r["esize"] == 8 else "CLEAR"))
                W("; (round 4 Q1c).  ⚠ No byte inside an element is identified.")
            W("%s:" % name)
            e_bytes(p, e)
    return fn


def emit_curves():
    a, b = CURVE_BASE, CURVE_BASE + CURVE_N * CURVE_STRIDE
    tops = [D[a + CURVE_STRIDE * k + CURVE_STRIDE - 1] for k in range(CURVE_N)]
    banner("ToneDB_DescCurveBank -- the 768 bytes formerly 'unexplained'", a, b, [
        "⚠ NEW in wave 7 round 2.  These 768 bytes used to be counted as part of",
        "the index map at directory slot +0x28, whose 2816-byte span was 768 more",
        "than its eleven siblings' 2048 and was recorded as NOT ESTABLISHED.  They",
        "are not part of that map.  They are %d tables of %d bytes, and the thing"
        % (CURVE_N, CURVE_STRIDE),
        "that says so is inside the image: the head word of EVERY one of the 318",
        "part-A objects in the descriptor pool at slot +0x30 is a 32-bit file",
        "offset naming one of these six addresses, 318 of 318, and the set of",
        "values used is exactly this set of six.  The shared part-A object of the",
        "161 descriptors at slot +0x38 names the last one.",
        "",
        "Each table is 128 bytes, starts at 0, and is monotonically NON-DECREASING",
        "over its whole length.  Their end values are %s, i.e. six curves of" % tops,
        "rising slope; curve 0 is exactly index//12.  Curves 3 and 4 share both",
        "their end value and their sum but differ in 14 of 128 bytes.",
        "",
        "★ AND THAT IS WHERE THE SIX LABELS BELOW COME FROM -- NEW IN ROUND 5.",
        "These tables used to be called ToneDB_DescCurve_0..5, which says where a",
        "curve sits and nothing about what it is.  A staircase IS its step width,",
        "so each one is now named for the run length that dominates it:",
        "",
        "    %s" % "  ".join("%s(%d zones)" % (CURVE_NAME[k], max(D[a + CURVE_STRIDE * k:
                                                                  a + CURVE_STRIDE * (k + 1)]) + 1)
                             for k in range(CURVE_N)),
        "",
        "The suffix is DERIVED, not typed: notes/prom_d_understanding_round5.py",
        "curve_names() counts run lengths and takes the strict plurality, or the",
        "two-way tie spelled `<hi>And<lo>` -- which is why curve 4, whose interior",
        "alternates 4,2,2,4 so that 4 and 2 each occur 14 times, is Step4And2 and",
        "not Step4.  This generator refuses to emit if the derivation stops",
        "producing the audited six names.",
        "",
        "★ AND THE INTERIOR IS PERIODIC WITH PERIOD 12, in all six: over entries",
        "24..119 each 12-wide block carries exactly 1, 2, 3, 4, 4 and 12 distinct",
        "values respectively.  So the six curves are six RESOLUTIONS of one 12-wide",
        "unit, and Step4And2 differs from Step3 in how it cuts the block (4+2+2+4",
        "against 3+3+3+3) and not in how many pieces it cuts it into.",
        "⚠ 12 is NOT claimed to be an octave, and the domain is NOT claimed to be a",
        "note number.  Round 4 refused that and round 5 refuses it again: the",
        "period is arithmetic, measured over 96 entries of every curve, and the",
        "meaning of the index is still nobody's.  round 5 Q3.",
        "",
        "★ WHAT THE CURVE'S OUTPUT IS FOR -- NEW IN ROUND 4, and it upgrades the",
        "paragraph that used to stand here.  Round 2 could only say the descriptors",
        "POINT here.  The curve's VALUE is now placed as well: in 318 of the 318",
        "descriptors at slot +0x30, the number of bytes in the part-A object AFTER",
        "its 4-byte curve pointer is exactly this curve's largest entry PLUS ONE.",
        "So the curve's codomain is precisely the part-A table's index space -- no",
        "entry of that table is unreachable and no curve value runs past its end.",
        "The part-A table's own largest value then indexes the descriptor's element",
        "array with the same exactness (round 4 join 2), so the bank is stage 1 of",
        "a three-stage index chain.  notes/prom_d_understanding_round4.py Q1.",
        "",
        "⚠ WHAT IS STILL NOT ESTABLISHED: what the curve's INPUT means.  128",
        "entries is the MIDI note range and prom_c's Voice_SelectKeyZone_Reg0040",
        "walks a 128-byte key map indexed by the played note (notes/FINDINGS-",
        "prom_c-dev10c-register-meanings.md §4b), which is why 'note-indexed curve'",
        "is the natural reading -- but no WSA1 instruction has been shown to read",
        "THIS table, so nothing below claims a synthesis role.  Nor is any byte of",
        "an element identified.",
        "",
        "Re-derived by notes/prom_d_structures_round2.py section Q2.",
        "",
        "Evidence: (image-internal, NOT from code) every one of the 318",
        "part-A objects in the descriptor pool at slot +0x30 begins with a 32-bit",
        "file offset, and the set of values those 318 words take is EXACTLY the",
        "set of these %d addresses -- no other value appears and no curve is" % CURVE_N,
        "unused.  That is what makes the boundary at 0x%05X real rather than a" % a,
        "convenient place to cut.",
        "⚠ No prom_c instruction reads this bank: the census in",
        "notes/prom_d_documentation_round3.py finds no reader for slot +0x30, the",
        "only slot from which this bank is reachable.",
    ])
    W("ToneDB_DescCurveBank:")
    _heads = collections.Counter(u32(p) for p, _e, kd, _i in _R2.desc_segments(0x30)
                                 if kd == "A")
    for k in range(CURVE_N):
        c = a + CURVE_STRIDE * k
        W("")
        W("; %s -- file 0x%05X..0x%05X (%d bytes)"
          % (CURVE_LABEL(k), c, c + CURVE_STRIDE - 1, CURVE_STRIDE))
        _row = list(D[c:c + CURVE_STRIDE])
        _runs = collections.Counter(len(list(_g)) for _v, _g in itertools.groupby(_row))
        W("; %d entries, non-decreasing, v[0] = 0, v[127] = %d, %d zones.%s"
          % (CURVE_STRIDE, D[c + 127], max(_row) + 1,
             "  Exactly index//12." if k == 0 else ""))
        W("; Run lengths: %s -- which is what the label's suffix says, and it is"
          % ", ".join("%d x %d" % (n, w) for w, n in sorted(_runs.items(), reverse=True)))
        W("; derived by notes/prom_d_understanding_round5.py curve_names(), not typed.")
        _users = [r for r in CHAIN[0x30].values() if r["curve"] == c]
        if _users:
            W("; Consumers' stage-2 tables are all %d bytes long = this curve's"
              % (max(D[c:c + CURVE_STRIDE]) + 1))
            W("; largest entry + 1, in %d of %d cases -- round 4 join 1."
              % (sum(1 for r in _users if len(r["a_tab"]) == max(D[c:c + CURVE_STRIDE]) + 1),
                 len(_users)))
        W("; Evidence: %d of the 318 part-A objects at slot +0x30 name THIS curve"
          % _heads.get(c, 0))
        W("; in their leading LE32; the first is the object at 0x%05X.  %s"
          % (min(p for p, _e, kd, _i in _R2.desc_segments(0x30)
                 if kd == "A" and u32(p) == c),
             "The 161 descriptors at slot +0x38 share one part A, and it names "
             "this curve too." if c == a + CURVE_STRIDE * (CURVE_N - 1) else ""))
        W("%s:" % CURVE_LABEL(k))
        e_bytes(c, c + CURVE_STRIDE)


def emit_drumkits():
    a, b = 0x2B2AC, S(0x74)
    banner("DRUM-KIT RECORDS -- tone indices 0x100-0x111", a, b, [
        "18 records of 408 bytes, reached from ToneDB_ToneOffsetTable entries",
        "256..273.  Layout:",
        "",
        "    +0x000  16 B   name, ASCII, space-padded  ('   Jazz Kit     ')",
        "    +0x010 136 B   common part -- see the note below",
        "    +0x098 128 x LE16   one entry per MIDI note 0..127",
        "",
        "The per-note LE16 selects a drum instrument.  Values run up to 0x0530,",
        "beyond the 504 drum-instrument records, so it is not a direct index into",
        "them; it is consistent with an index into DrumKit_NoteMapA/B (slots +0x74",
        "/+0x7C, 2048 entries each, whose values ARE valid drum-instrument",
        "indices), but that chain has NOT been confirmed against code.",
        "",
        "The head is RELATED to the melodic tone-record head but is not the same",
        "structure.  The 8-byte token 11 00 01 63 1E 06 00 54 sits at melodic",
        "record +138 (246 of 254 records) and at drum-kit record +82 (18 of 18),",
        "so the drum head reaches that landmark 56 bytes earlier.  Past it the two",
        "agree: 55 of 70 columns share a modal byte, against 17-27 for every shift",
        "null.  But the melodic head runs 79 bytes past the landmark and the drum",
        "head only 70, so the two heads are NOT interchangeable.",
        "",
        "Evidence: these 18 records are named by ToneDB_ToneOffsetTable entries",
        "256..273 (file 0x%05X..0x%05X), and that table is the one prom_c walks at"
        % (0xB80 + 4 * 256, 0xB80 + 4 * 273),
        "0xFB4288/0xFB4290/0xFB429D -- index x 4, entry, plus the base -- so the",
        "records are reached the same way a melodic tone record is.",
        "★ AND THE 128-ENTRY NOTE MAP IS CONFIRMED FROM THE OTHER END: 0xFB4947",
        "`sll 0x07,BC` scales a kit number by 128 into DrumKit_NoteMapA (slot",
        "+0x74) and 0xFB495A multiplies the value it finds by the +0xEE stride",
        "word, 150, i.e. into the drum-instrument records.  That is the chain this",
        "banner previously said had NOT been confirmed against code, for the note",
        "map; it is still NOT confirmed for the per-record map emitted below.",
        "notes/prom_d_documentation_round3.py Q4a and Q4d.",
    ] + NAMING_RULE)
    for k in range(18):
        p = a + 408 * k
        idx = IDX_OF[p]
        for ln in tone_hdr_lines(p, idx, "408 B = 16 name + 136 common + 128 x LE16"):
            W(ln)
        lab = "DrumKit_%03X_%s" % (idx, tone_name(p))
        W("%s:" % lab)
        e_ascii(p, 16)
        e_bytes(p + 16, p + 152)
        W("%s_NoteMap:" % lab)
        e_shorts(p + 152, p + 408, comment=lambda i: "note %3d" % i)


def emit_percinst():
    a, b = S(0x78), NEXT[S(0x78)]
    n = (b - a) // PERC_STRIDE
    banner("PercInst -- directory slot +0x78", a, b, PERC_HDR + NAMING_RULE + [
        "",
        "%d records here; the span divides exactly by %d." % (n, PERC_STRIDE),
    ] + ev_slot(0x78, [
        "",
        "★ AND THE STRIDE IS prom_c's.  It does not use a literal 150 here; it",
        "reads the directory's OWN stride word and multiplies by it:",
        "    0xFB48FE  ld XIX,(0x00d7f1)    the base, parked for the routine",
        "    0xFB4937  ld XWA,(XIX+0x78)    this array's file offset",
        "    0xFB493D  ld IY,(XIX+0x00ee)   the stride word = %d" % PERC_STRIDE,
        "    0xFB4958  ld WA,(XBC)          a drum-instrument index",
        "    0xFB495A  mul XIY,WA           index * the stride word",
        "which is why the +0xEE line on the directory says CONFIRMED.",
        "notes/prom_d_documentation_round3.py Q4d.",
    ]))
    for i in range(n):
        p = a + PERC_STRIDE * i
        na, nb = _DRUM_A.get(i, 0), _DRUM_B.get(i, 0)
        W("")
        W("; ---- drum instrument %3d %r ----" % (i, D[p:p + 13].decode("latin1")))
        W("; %d B: 13-byte name then %d bytes of parameters, none identified."
          % (PERC_STRIDE, PERC_STRIDE - 13))
        W("; Named by %d of the 2,048 DrumKit_NoteMapA entries (slot +0x74) and %d"
          % (na, nb))
        W("; of DrumKit_NoteMapB's (slot +0x7C).  Evidence: map A's values run")
        W("; 0..503 over exactly these 504 records and name every one of them;")
        W("; map B names 503 of the 504.  round 4 Q6d/Q6e.%s"
          % ("  ⚠ THIS record is one" if nb == 0 else ""))
        if nb == 0:
            W("; map B never names -- the honest asymmetry, not a rounding.")
        if i:
            W("PercInst_%03d_%s:" % (i, perc_name(i)))
        else:
            W("PercInst_000_Silent:")
        e_ascii(p, 13)
        e_bytes(p + 13, p + PERC_STRIDE)


def mk_notemap(slot):
    def fn():
        a, b = S(slot), NEXT[S(slot)]
        banner("%s -- directory slot +0x%02X" % (slot_label(slot), slot), a, b, [
            "2048 LE16.  Every non-0xFFFF value is a valid index into the 504",
            "drum-instrument records at slot +0x78 (max %d)."
            % max(v for v in (u16(a + 2 * i) for i in range((b - a) // 2)) if v != 0xFFFF),
            "KN5000 label at the same directory slot: %s." % SLOT[slot][2],
        ] + ev_slot(slot, NOTEMAP_CHAIN(slot) if _R3.readers(slot) else ()))
        W("%s:" % slot_label(slot))
        e_shorts(a, b)
    return fn


def emit_drawbars():
    a, b = 0x446B4, S(0x70)
    banner("DRAWBAR TONE RECORDS -- tone indices 0x058 and 0x059", a, b, [
        "Two records of 541 bytes named '<<< Drawbar 1>>>' and '<<< Drawbar 2>>>'.",
        "",
        "⚠ RESOLVED in wave 7 round 2.  This note used to say the records were 172",
        "bytes SHORT of the 217 + 4*124 = 713 their mask implies, and left it open.",
        "They are not short of anything: 541 = 217 + 4*81 EXACTLY.  A drawbar",
        "record carries its four 81-byte element blocks and NO wave-select records",
        "at all, and the 172 missing bytes are precisely the 4 x 43 that are absent.",
        "",
        "The four blocks really are element blocks, not unclassified bytes: each",
        "matches the modal-byte profile of the 451 ordinary element blocks in 53-54",
        "of 81 columns (those 451 average 57.2 among themselves), while the same",
        "windows shifted by -7,-5,-3,+3,+5,+7 score 20-32.  So they are emitted with",
        "element labels.  Their mask at +0x11 is 0x55, four slots set, agreeing.",
        "notes/prom_d_structures_round2.py section Q4.",
        "",
        "The KN5000 also treats drawbar presets specially: its directory slot +0x70",
        "is DrawbarPreset_EnvDescTable, and prom_d's +0x70 points at the descriptor",
        "block immediately after these two records.",
        "",
        "Evidence: (image-internal) ToneDB_ToneOffsetTable entries 0x058 and",
        "0x059, at file 0x%05X and 0x%05X, hold 0x%05X and 0x%05X; the second plus"
        % (0xB80 + 4 * 0x58, 0xB80 + 4 * 0x59, 0x446B4, 0x448D1),
        "541 is exactly directory slot +0x70, so BOTH ends are pinned by something",
        "other than the stride.  The 81-byte element cut inside them is the same",
        "one prom_c uses at 0xFB436D (`ld C,0x51`) for every other tone record.",
        "⚠ Nothing has been found that reads these two records specifically, and",
        "nothing explains why they carry no wave-select array.",
    ])
    for k in range(2):
        p = a + 541 * k
        idx = IDX_OF[p]
        for ln in tone_hdr_lines(p, idx, "541 B = 217 + 4 x 81, and NO wave-select array"):
            W(ln)
        lab = "ToneRec_%03X_%s" % (idx, tone_name(p))
        W("%s:" % lab)
        e_ascii(p, 16)
        e_bytes(p + 16, p + 217)
        for j in range(4):
            W("%s_Elem%d:\t\t; 81-byte element block" % (lab, j))
            e_bytes(p + 217 + 81 * j, p + 217 + 81 * (j + 1))
        assert p + 217 + 4 * 81 == p + 541


def emit_tail():
    banner("ERASED TAIL and BUILD TAG", 0x50B09, 0x80000, [
        "The payload's last byte is at 0x50B08.  From 0x50B09 to 0x7FFEF the image",
        "is ONE unbroken 0xFF run of 0x2F4E7 bytes -- the shape of an erased flash",
        "device.  The last 16 bytes are the build tag, and they are what ties this",
        "image to an address: VersionScreen_Show (prom_a 0xF82A28) reads eleven",
        "bytes from remote 0x00F7FFF0 and shows them as WSA-D:, so the base is",
        "0x00F00000 on CPU 2's bus (notes/FINDINGS-memory-map.md §5).",
        "⚠ This banner used to end 'the 512 KiB flash at 0xE80000', which is the",
        "REFUTED reading -- prom_c's own Flash_SectorErase bounds that part at",
        "0x00E80000..0x00EFFFFF, below this image.  ORIGIN 0 in prom_d/prom_d.ld",
        "stays correct anyway, because this image is addressed by 0-based offsets",
        "and holds no absolute pointers -- which round 3 turned from an argument",
        "about content into a fact about the firmware (see the directory banner:",
        "prom_c adds the base to a value it read out of this image).",
        "",
        "Evidence: prom_a 0xF82A5F is `ld XWA,0x00F7FFF0` (bytes 40 f0 ff f7 00)",
        "and the eleven bytes at prom_d file 0x7FFF0 are `wsad_54.ssf`.",
        "0x00F7FFF0 - 0x7FFF0 = 0x00F00000, the same base prom_c installs in RAM",
        "0x00D7ED / 0x00D7F1 from the immediate at 0xFB051E.  Two processors, two",
        "independent routes, one base.  notes/prom_d_base_checks.py (12 checks)",
        "and notes/prom_d_documentation_round3.py Q1.",
    ])
    W("erased_tail:")
    W("\t.fill 0x%X, 1, 0xFF" % (0x7FFF0 - 0x50B09))
    W("")
    # ★ ROUND 7: this label had no evidence line of its own.  The banner above
    # carries the argument, but the banner introduces `erased_tail`, and a reader
    # arriving at `build_tag` from a cross-reference saw a semantic name with
    # nothing under it.  notes/prom_d_finish_round7.py Q1 lists exactly that.
    _A = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
    _insn = _A[0xF82A5F - 0xF80000:0xF82A5F - 0xF80000 + 5]
    W("; Evidence: the %d bytes at file 0x7FFF0 are the ASCII %r, followed by %d"
      % (len(D[0x7FFF0:0x7FFFB]), D[0x7FFF0:0x7FFFB].decode("latin1"),
         len(D[0x7FFFB:0x80000])))
    W("; bytes of 0x00.  prom_a 0xF82A5F is `ld XWA,0x00F7FFF0` -- bytes %s,"
      % _insn.hex(" "))
    W("; read out of wsa1_prom_a.ic12 by this generator -- and 0x00F7FFF0 minus")
    W("; this object's file offset 0x7FFF0 is 0x00F00000, the base prom_c installs")
    W("; from its own immediate at 0xFB051E.  Two processors, one base.")
    W("; notes/prom_d_base_checks.py checks 1-4.")
    W("build_tag:")
    W('\t.ascii "wsad_54.ssf"')
    W("\t.byte 0x00, 0x00, 0x00, 0x00, 0x00")


# ---------------------------------------------------------------------------
# assemble the region list
# ---------------------------------------------------------------------------
BOUND = sorted(set(v for v in DIR if v != 0xFFFFFFFF)
               | {0x13C8, CURVE_BASE, 0x2B2AC, 0x446B4, 0x50B09, 0x80000})
NEXT = {BOUND[i]: BOUND[i + 1] for i in range(len(BOUND) - 1)}

for slot in (0x0C, 0x10, 0x14, 0x24, 0x2C, 0x44, 0x48, 0x4C, 0x58, 0x5C, 0x60):
    region(S(slot), NEXT[S(slot)], mk_indexmap(slot))
region(S(0x28), NEXT[S(0x28)], mk_indexmap(
    0x28, ["⚠ CORRECTED in wave 7 round 2.  This map is 2048 bytes, exactly like",
           "its eleven siblings.  The 768 bytes that used to be counted into it,",
           "and recorded as 'what the extra 384 entries are is NOT established',",
           "are a separate object: see ToneDB_DescCurveBank immediately below."]))
region(CURVE_BASE, NEXT[CURVE_BASE], emit_curves)
for slot in (0x18, 0x20, 0x3C):
    region(S(slot), NEXT[S(slot)], mk_wavesel_array(slot))
for cat, foot in ((0x50, 0x54), (0x64, 0x68), (0x80, 0x84), (0x8C, 0x90), (0x94, 0x98)):
    region(S(cat), NEXT[S(cat)], mk_catalogue(cat, foot))
    region(S(foot), NEXT[S(foot)], mk_footer(foot, cat))
region(S(0x30), 0x2B2AC, mk_desc_block(0x30, [
    "This is the LARGEST of the three, and the only one whose descriptors each own",
    "a PRIVATE part A.  Its 318 (part A, part B) pairs partition the pool exactly:",
    "0 bytes uncovered, 0 bytes covered twice.  Part A is 15, 25, 32, 39 or 112",
    "bytes and always begins with a curve offset; part B is 6 to 144 bytes, and its",
    "length is governed by BIT 7 OF THE TAG -- clear in 187 records and then always",
    "a multiple of 6, set in 131 and then always a multiple of 8, with no exception.",
    "That rule is discriminating (not just arithmetic luck) for 264 of the 318: the",
    "other 54 lengths are multiples of 24 and decide nothing.",
]))
region(S(0x38), 0x446B4, mk_desc_block(0x38, [
    "All 161 descriptors here point their part A at ONE shared 132-byte object,",
    "which itself names the steepest curve; their part-B offsets are an arithmetic",
    "run of step 6, so this block is 132 + 161*6 = 1098 bytes of pool with nothing",
    "left over.  Every tag is 0x40, bit 7 clear, agreeing with the 6-byte rows.",
]))
region(S(0x70), NEXT[S(0x70)], mk_desc_block(0x70, [
    "A DIFFERENT record class: tag 0x92 in all four, part A null in all four, and",
    "the four part-B offsets name only THREE objects -- %d, %d and %d bytes,"
    % (DRAWBAR["pool"][0][1], DRAWBAR["pool"][1][1], DRAWBAR["pool"][2][1]),
    "the first two being %d rows of %d.  The row size is NOT a period picked out"
    % (DRAWBAR["ncombo"], DRAWBAR["stride"]),
    "of the bytes: it is `mul WA,0x0006` in prom_c's Voice_StageRegs_0040_B, the",
    "routine that reads these objects.  See THE INDEX CHAIN below.",
    "★ Tag 0x92 has bit 6 CLEAR and bit 7 SET, which is the two-bit table's",
    "6-byte row -- so the element size agrees with the reader as well.  (The",
    "one-bit rule stated on slot +0x30 predicts 8 here and is still not claimed.)",
]))
region(0x2B2AC, S(0x74), emit_drumkits)
region(S(0x74), NEXT[S(0x74)], mk_notemap(0x74))
region(S(0x7C), NEXT[S(0x7C)], mk_notemap(0x7C))
region(S(0x78), NEXT[S(0x78)], emit_percinst)
region(0x446B4, S(0x70), emit_drawbars)
region(0x50B09, 0x80000, emit_tail)

REGIONS.sort()
cur = 0
for a, b, _ in REGIONS:
    assert a == cur, "region gap/overlap at 0x%05X (expected 0x%05X)" % (a, cur)
    assert b > a
    cur = b
assert cur == 0x80000, "regions stop at 0x%05X" % cur

# ---------------------------------------------------------------------------
HEADER = '''\t.text

; ==============================================================================
; Technics SX-WSA1R -- wsa1_prom_d.bin -- THE TONE DATABASE
; ==============================================================================
;
; Reference designator not legible in the manual scan; this image is
; wsa1_os_v2.ic21 of the redistributed v2 firmware set, so IC21 is the likely
; designator and is NOT asserted here.  DATA ONLY -- 60 of the 64 words at file
; offset 0x7FF00 are 0xFFFFFFFF and the other four are the build tag, so there is
; no vector table: it is not a boot image and nothing in it executes.
; (⚠ this line used to say "all 64"; corrected against notes/prom_d_base_checks.py.)
;
; BASE: **0x00F00000 on CPU 2's bus** -- ⚠ CHANGED IN WAVE 7 ROUND 3, where this
; paragraph used to read "NOT ESTABLISHED".  What establishes it:
;
;   * prom_c installs 0x00F00000 in RAM 0x00D7ED and 0x00D7F1 (0xFB051E loads
;     the immediate, 0xFB0523 and 0xFB0528 store it).  Those two stores are the
;     ONLY instructions in prom_c that write either address, so the value is a
;     compile-time constant at every use.
;   * prom_c then reads THIS IMAGE'S 48-slot directory through that base at 99
;     instruction pairs covering 33 slots, and adds the base to the offsets it
;     finds there.  Every one of the 99 is re-decoded from prom_c's ROM bytes.
;   * independently, prom_a 0xF82A5F `ld XWA,0x00F7FFF0` reads eleven bytes that
;     are this image's build tag at file 0x7FFF0, "wsad_54.ssf"; the difference
;     is 0x00F00000.  Two processors, two routes, one base.
;   * the earlier "512 KiB flash at 0xE80000" reading is REFUTED: prom_c's own
;     Flash_SectorErase bounds that part at 0x00E80000..0x00EFFFFF, below this
;     image, and ExtBoard_ProbeAndInstallBases installs the two addresses in
;     SEPARATE slots.  notes/prom_d_base_checks.py, 12 checks.
;
; ORIGIN in prom_d/prom_d.ld nevertheless STAYS 0, and that is deliberate: this
; image's own directory is 0-BASED, and what proves that is not a statistic but
; an instruction sequence -- prom_c reads a tone-record entry out of the table at
; slot +0x08 (0xFB429D) and then ADDS THE BASE TO IT (0xFB429F), having already
; added the base to reach the table (0xFB4298).  A stored absolute address needs
; neither add.  Every offset in this source is therefore FILE-RELATIVE, which is
; how the hardware reads it.  (⚠ the older argument from bank statistics is kept
; in prom_d/prom_d.ld but DOWNGRADED there: round 3 Q8 shows it does not
; discriminate -- prom_c is a code ROM and scores like prom_d on it.)
;
; ★ "DATA ONLY" WAS ATTACKED ON 2026-09-02 AND HELD.  A falsification lane took
; the claim that this image contains no code as something to BREAK, because the
; way it could be false is invisible to the byte gate: code typed as data
; re-assembles to the same bytes.  55 checks,
; notes/prom_cd_falsification_2026_09_02.py, summarised in
; notes/FINDINGS-prom_cd-falsification.md:
;
;   * this image IS on a CPU bus -- wsa1.cpp maps it .rom() in CPU 2's program
;     space -- so "no code" is a real claim and not a tautology;
;   * none of prom_c's 33 vectors lands in it (null: all 33 land in prom_c);
;   * exactly ONE prom_c instruction literal falls in its window, the base
;     itself (null: the same scanner finds many in two other windows);
;   * prom_c's BYTES hold no pointer table into it -- 741 LE32 words in its
;     window against 901 and 675 in windows with NO DEVICE, and 1977 in prom_c's
;     own, so it is at address-space noise while prom_c is enriched;
;   * llvm-mc emits ZERO instruction statements from this source and 76,647 from
;     prom_c's;
;   * and its BYTES do not behave like code: branch-target coherence normalised
;     by boundary density scores 0.29-1.16 here, against 0.81-1.34 for prom_c
;     data and 2.42-3.09 for prom_c code.  Splicing 8 KiB of real prom_c code in
;     scores 2.58, which is how the test is shown to be able to fail.
;
; ⚠ THE REACH OF THAT LAST TEST IS ABOUT 2 KiB.  A shorter routine would evade
; it, and file 0x26000-0x2BFFF (ToneDB_EnvDescTable) has too few branches in its
; decode to be scored at all.  Those 24 KiB are the part of this image least
; attacked.
;
; ⚠ What is still open is which PHYSICAL PART this is.  The base fixes the
; address the firmware reads it at, not the device.
;
; ------------------------------------------------------------------------------
; WHAT THIS IMAGE IS
; ------------------------------------------------------------------------------
; It is a TONE DATABASE of the same design as the KN5000's, which is documented
; in ../kn5000-roms-disasm/table_data/tone_database_directory.s.  A 48-slot
; directory at file 0x0000 names every other region; the KN5000 has the same
; table at its ToneDB_Base, and the correspondences that hold are listed on the
; directory itself below.  The strongest of them:
;
;   * slot +0x08 is the tone-record offset table in both;
;   * slots +0x9C/+0xA0/+0xA4 alias +0x24/+0x28/+0x2C in both;
;   * the tail scalars at +0xD0, +0xD4, +0xD6, +0xD8, +0xDA and +0xE8 hold
;     IDENTICAL values in both (+0xE8 = 426 in each);
;   * slot +0x50 is a catalogue of 16-byte named wave rows starting "Piano L",
;     "Piano R", "Mono Piano" in both;
;   * the 81-byte per-element block inside a tone record is the SAME STRUCTURE
;     in both: 63 of its 81 byte columns share their modal value across the two
;     ROMs' entire populations (1637 KN5000 blocks, 451 WSA1 blocks), against
;     18-29 columns for every shift and rotation null.
;
; And it reaches ACROSS THE ARCHITECTURE BOUNDARY as well: 195 of the 252
; distinct 16-character name fields in the WSA1 images are verbatim in the
; KN7000's (MN10300) table ROM and all 195 are in prom_d, while 74 of the 250
; shared binary runs sit exactly 81 bytes apart -- prom_d's own per-element
; stride, derived on this side without reference to any KN7000.  See the
; MELODIC TONE RECORDS banner; notes/wave7_xref_mn10300_family.py section 4.
;
; Contents, by count:
;     274 tones           256 melodic + 18 drum kits, named and reachable from
;                         the offset table at 0x0B80
;     504 drum instruments 150-byte records with 13-char names
;    1493 wave-catalogue rows across 5 catalogues (307/314/503/208/161), each
;                         count CONFIRMED by that catalogue's own footer block
;     594 wave-select records of 43 bytes in three arrays
;    1280 program-map entries (10 rows x 128 LE16)
;
; ------------------------------------------------------------------------------
; WHAT IS NOT ESTABLISHED -- read this before quoting anything below
; ------------------------------------------------------------------------------
; The byte gate certifies BYTES.  It is blind to a wrong label and a wrong
; comment.  For this file specifically:
;
;   * ⚠ WAVE 7 ROUND 3 RETIRED THE HEADLINE CAVEAT.  This bullet used to read
;     "NO WSA1 INSTRUCTION THAT READS ANY OF THESE STRUCTURES HAS BEEN FOUND",
;     and it appeared four times in this file.  It is now FALSE and is retracted.
;     prom_c reads this image's directory at 99 instruction pairs over 33 slots
;     (notes/prom_d_documentation_round3.py, %d checks, every citation re-decoded
;     from prom_c's ROM bytes).  What that changed, region by region, is on each
;     banner as an `Evidence:` line.  The headline consequences:
;       - the base, the 0-based offsets and the pointer/scalar split of the
;         directory are now prom_c's own encodings, not a KN5000 transplant;
;       - 81 and 217 (the element block and the tone-record head), 16 (the
;         catalogue row), 128 (the +0xA8 record and the index-map row) and 4/2
;         (the LE32/LE16 entry widths) appear as literals or shifts in prom_c;
;       - the stride words at +0xEC and +0xEE are read and MULTIPLIED BY;
;       - a catalogue's row count is not merely equal to its footer's LE16, it
;         is bounded by it at run time, in all five catalogue/footer pairs;
;       - an index map's VALUE is a catalogue row number, 0xFFFF meaning none.
;     ⚠ BUT 13 of the 39 filled primary slots still have NO reader -- including
;     the two largest structures, the descriptor blocks at +0x30/+0x38 and the
;     wave-select arrays at +0x18/+0x20.  Those keep their transplanted names,
;     and their banners say so in as many words.
;   * The MEANING of individual fields -- inside a tone record, an element
;     block, a wave-select record, a drum-instrument record, a descriptor -- is
;     STILL unknown throughout.  Round 3 read a consumer's ADDRESS ARITHMETIC;
;     it did not read one field.  Where a comment states a field, it states a
;     shape (a count, an offset, a stride) that was measured, never a semantics.
;   * ⚠ WAVE 7 ROUND 2 changed this bullet.  It used to read "Three regions
;     resist framing": the descriptor blocks at slots +0x30/+0x38/+0x70, the 768
;     extra bytes in the index map at +0x28, and the 8 x 128-byte table at +0xA8.
;     The first four are now FRAMED, each from evidence inside the image itself:
;       - +0x30/+0x38/+0x70 are an ARRAY of 14-byte descriptors over a POOL, and
;         the descriptors' own 32-bit offsets say where the array ends.  318, 161
;         and 4 descriptors; header + pool tiles each block exactly; the LAST
;         descriptor's offset is the last object in its pool.
;       - the 768 bytes at 0x22A3B are SIX 128-byte monotone curves, and what
;         says so is that all 318 part-A objects of slot +0x30 begin with a
;         32-bit offset naming one of exactly those six addresses.
;     What still resists: the PURPOSE of the 8 x 128-byte table at +0xA8 (the
;     KN5000 leaves that slot unused, so there is no name to transplant and none
;     is invented -- though round 3 confirmed its 128-byte RECORD SIZE from
;     prom_c's own indexing), and every FIELD inside a descriptor, a curve or a
;     pool row.
;     notes/prom_d_structures_round2.py, 78 checks.
;   * Directory slot +0x88 holds 0x125.  In the KN5000 the same slot holds a
;     SCALAR, not an offset.  Nothing here decides which prom_d means.
;
; Reproduce every number quoted in this file:
;     python3 scripts/analysis/prom_d_tone_database.py
;     python3 notes/prom_d_structures_round2.py        # the record framing, 78 checks
;     python3 notes/prom_d_documentation_round3.py     # who READS it, %d checks
;     python3 notes/prom_d_base_checks.py              # the base, 12 checks
; Regenerate this file:
;     python3 scripts/analysis/gen_prom_d_asm.py
; Then, always:
;     python3 scripts/analysis/assert_byte_identical.py
;
; PROVENANCE: this is not a chip read.  It is the publicly redistributed v2
; firmware set (../technics_roms/roms/wsa1/PROVENANCE.md).
; ==============================================================================

wsa1_prom_d:
'''

# ---------------------------------------------------------------------------
# ★ WAVE 7 ROUND 7.  The file's own top banner now carries the whole-image
# inventory and, next to it, the two things a percentage hides: how many of these
# names are the SIBLING MACHINE'S rather than this one's, and what the percentage
# is not robust to.  Every number is read out of notes/prom_d_finish_round7.py at
# generation time, so the banner cannot drift away from the census.
# ---------------------------------------------------------------------------
def _round7_header_lines():
    fin, prov = _R7.inventory_summary()
    n_content, n_glued, _fams = _R7.glued_digit_audit()
    tot = sum(fin.values())
    slots = sorted(set(_R7.region_slot(l.addr) for l in _R7.LABS
                       if l.prov == "KN5000-TRANSPLANT") - set([None]))
    lo_now = 100.0 * n_content / tot
    lo_strict = 100.0 * (n_content - n_glued) / tot
    L = [
        "; " + "-" * 78,
        "; ★ WAVE 7 ROUND 7 -- THE WHOLE-IMAGE INVENTORY, AND THE HONEST HALF OF IT",
        "; " + "-" * 78,
        "; Every label in this file carries either a WITNESS -- a route from the bytes",
        "; to the name -- or a stated REASON for having none, and ONE command re-checks",
        "; all %s of them:" % format(tot, ","),
        ";",
        ";     python3 notes/prom_d_finish_round7.py",
        ";",
        ";   witnessed  %5s   the name has a route: the object's own ASCII, an"
        % format(fin.get("WITNESSED", 0), ","),
        ";                      Evidence: line, or a witnessed object it is part of",
        ";   nameless   %5s   NOT named -- and the reason is stated PER OBJECT, in"
        % format(fin.get("NAMELESS", 0), ","),
        ";                      this file, next to the object it is about",
        ";   boundary   %5s   prom_d_end, a zero-length end marker, not an object"
        % format(fin.get("BOUNDARY", 0), ","),
        ";   ★ NO WITNESS AT ALL: %d" % fin.get("UNWITNESSED", 0),
        ";",
        "; ⚠ AND GRADED BY PROVENANCE, WHICH IS WHAT A PERCENTAGE HIDES.  A name can",
        "; rest on very different things, and this image's rest mostly on two:",
        ";   self-named        %5s  the object's own 13- or 16-byte ASCII field"
        % format(prov.get("SELF-NAMED", 0), ","),
        ";   KN5000 transplant %5s  ⚠ the name is the SIBLING MACHINE'S, and NO prom_c"
        % format(prov.get("KN5000-TRANSPLANT", 0), ","),
        ";                            instruction reads the directory slot the region",
        ";                            it sits in hangs off.  The slots, in full:",
        ";                            %s" % " ".join("+0x%02X" % x for x in slots[:6]),
        ";                            %s" % " ".join("+0x%02X" % x for x in slots[6:]),
        ";   image-internal    %5s  a relation measured inside this image"
        % format(prov.get("IMAGE-INTERNAL", 0), ","),
        ";   reader-backed     %5s  prom_c reads the slot and the read says what it is"
        % format(prov.get("READER-BACKED", 0), ","),
        ";   nameless          %5s  the %d above, kept in the same denominator"
        % (format(prov.get("NAMELESS", 0), ","), fin.get("NAMELESS", 0)),
        "; So a reader who wants only what THIS machine's firmware confirms should",
        "; discount %s of the %s labels below.  That is the number, said once, here."
        % (format(prov.get("KN5000-TRANSPLANT", 0), ","), format(tot, ",")),
        ";",
        "; ⚠ AND THE %.1f%%%% CONTENT FIGURE THIS FILE SCORES ON" % lo_now,
        "; notes/wave7_documentation_metrics.py IS NOT ROBUST TO SPELLING.  %d of the"
        % n_glued,
        "; labels it grades CONTENT are <stem>_<Word><digits> whose digits run 0..n-1",
        "; over three or more siblings with no self-named ancestor -- the same shape as",
        "; `PercInst_17`, which the same metric grades FRAMED.  The difference is an",
        "; underscore before the number.  Counting those as framed instead, this file",
        "; reads %.1f%%%%.  Both are true of a stated rule and neither is quoted without"
        % lo_strict,
        "; the other.  notes/prom_d_finish_round7.py Q1, Q2, Q8; %d checks."
        % _R7.AUDITED_CHECKS,
        ";",
    ]
    return "\n".join(L)


def _round8_header_lines():
    """The round-8 block: the three questions, and what is left after them."""
    rows = _R8.three_questions()
    named = [r for r in rows if r.verdict == "NAMED"]
    nameless = [r for r in rows if r.verdict == "NAMELESS"]
    fourth = sum(1 for r in named if not r.a and not r.b and not r.c)
    dj = sum(len(_R8.disjunction_labels(_s)) for _s in (0x18, 0x20))
    refs = _R8.preset_referrers()
    npre = _R6.array_records(0x3C)[1]
    unref = [k for k in range(npre) if k not in refs]
    return "\n".join([
        "; " + "-" * 78,
        "; ★ WAVE 7 ROUND 8 -- THE THREE QUESTIONS, AND WHAT SURVIVES THEM",
        "; " + "-" * 78,
        "; Round 7 gave every label a verdict.  What it did not do is ask the same",
        "; three questions of each, so a nameless object was nameless because ONE",
        "; naming rule had failed on it.  Round 8 asks, of all %s:" % format(len(rows), ","),
        ";     A  does the object CONTAIN a name -- its own ASCII?",
        ";     B  does a prom_c READER reach the region it is in?",
        ";     C  does anything POINT AT it -- a stored index, one of this image's",
        ";        own %s pointer fields, or an address spelling?"
        % format(len(_R8.pointer_fields()), ","),
        "; %s NAMED, %s NAMELESS -- and every nameless object carries all three"
        % (format(len(named), ","), format(len(nameless), ",")),
        "; answers below, not one mechanism's failure.",
        ";",
        "; ⚠ AND THE TABLE ADMITS ITS OWN GAP: %d objects are NAMED while answering" % fourth,
        "; NO to all three.  They are named by round 6's fourth route -- the object",
        "; CONTAINS A COPY of a named object's bytes -- which is why the three answers",
        "; are printed as facts about routes and NOT as a verdict.",
        ";",
        "; ★ WHAT ROUND 8 NAMED: %d records whose bytes are carried by two or three" % dj,
        "; DIFFERENTLY NAMED records.  Round 6 gave them no label because `nothing",
        "; picks one of them`; round 8 states all of them instead of stating none, and",
        "; `_Or_` is what says no owner was picked.  The bound is %d names."
        % _R8.MAX_NAMES,
        ";",
        "; ★ WHAT THE STORED-INDEX CENSUS SETTLED, and it is the census round 7's own",
        "; conclusion implied: a record here is reached by an INDEX, so the question",
        "; is which stored index values exist.  Only one field in the image can select",
        "; a wave-select preset.  ⚠ WAVE 7 ROUND 9 CORRECTED THIS SENTENCE'S",
        "; DENOMINATOR: over all %s wave-select records the field takes %d distinct"
        % (format(len(_R8.wavesel_preset_fields()), ","),
           len(set(v & 0x3F for _w, _k, v in _R8.wavesel_preset_fields()))),
        "; values, because the preset array's OWN +0x0B carries each record's own",
        "; index.  Over the %s records that are not the preset array itself it takes"
        % format(len(_R8.preset_referring_fields()), ","),
        "; %d -- so %d of the %d records of ToneDB_WaveSelTailPresets are"
        % (len(refs), len(unref), npre),
        "; selected by NOTHING STORED in this image, and each says so on itself.",
        ";",
        "; ⚠ FOUR MORE MECHANISMS MEASURED AND REJECTED (Q4), including the strongest",
        "; one this image offers: the +0x20 array is in its owners' index order with",
        "; %d backward steps over %d anchors, so an ambiguous record's owner is"
        % (_R8.monotonicity(0x20)[1], _R8.monotonicity(0x20)[0]),
        "; confined to an interval -- and the interval leaves exactly one candidate 0",
        "; times.  Refuted by its own measurement, and written down so it is not",
        "; re-invented.",
        ";",
        "; ⚠ ORIGIN in prom_d/prom_d.ld is NOT changed.  Round 8 re-attacked it from",
        "; the image's own pointers: %s directory slots, tone-record offsets and"
        % format(len(_R8.pointer_fields()), ","),
        "; descriptor pointers, and 0 of them is an absolute address.",
        ";",
    ])


# ---------------------------------------------------------------------------
# ★★ WAVE 7 ROUND 9.  The image is territorially complete and every label has a
# verdict; what it did NOT have was anything that re-reads the FILE against the
# ROM.  Round 9's audit does, in one command, and this block records what it
# reports plus the two false numbers it found in prose that four rounds of
# self-checks had left standing.  Every figure comes out of
# notes/prom_d_inventory_round8.py at generation time.
# ---------------------------------------------------------------------------
def _round9_header_lines():
    a = _R8.AUDITED_R9
    tot = sum(a.values())
    anch18, back18 = _R8.monotonicity(0x18)
    _a3c, n3c, _r3c = _R6.array_records(0x3C)
    return "\n".join([
        ";",
        "; " + "-" * 78,
        "; ★★ WAVE 7 ROUND 9 -- THE WHOLE-IMAGE LABEL AUDIT, AND WHAT IT FOUND",
        "; " + "-" * 78,
        ";",
        "; Rounds 2-8 each measured something new and wrote it here.  None of them",
        "; ever re-read THIS FILE against the ROM.  That is the gap round 9 closes,",
        "; and it is the gap the byte gate is blind to by construction: the gate",
        "; certifies the .byte directives and says nothing about the label above them",
        "; or the sentence above that.",
        ";",
        "; ★ ONE COMMAND NOW RE-CHECKS THE WHOLE IMAGE:",
        ";       python3 notes/prom_d_inventory_round8.py --selftest",
        "; It re-derives every one of the %s labels below -- its INDEX, its ADDRESS"
        % format(tot, ","),
        "; and its NAME -- from prom_d's own bytes and compares the result with the",
        "; text in this file.  %d are REFUTED and %d are unreached." % (a["REFUTED"], a["RESIDUE"]),
        ";",
        "; ★★ AND IT PUBLISHES A HARSHER NUMBER THAN THE GOAL METRIC'S UPPER BOUND",
        "; OF 100 PER CENT:",
        ";       %s of %s labels have their NAME re-derived from this image's own"
        % (format(a["DERIVED"], ","), format(tot, ",")),
        ";       bytes -- a record's ASCII name field, a measured byte identity, a",
        ";       curve's own run lengths, a descriptor's own 32-bit offsets;",
        ";       %s have only their ADDRESS derived.  Those names are structural"
        % format(a["ADDRESS"], ","),
        ";       or transplanted and this image does not spell them.",
        ";     Framing is not naming, and that split is the honest reading of a",
        ";     file with zero sub_XXXXXX.",
        ";",
        "; ⚠ WHAT THE AUDIT FOUND IN ALREADY-COMMITTED PROSE -- both corrected in",
        ";   scripts/analysis/gen_prom_d_asm.py, which is the only place a fix",
        ";   survives a regeneration:",
        ";     * the stage-2 table shared by descriptors 0..160 of slot +0x38 is 132",
        ";       bytes -- 128 entries -- and its comment said `108 entries`, which is",
        ";       max(curve)+1 and true only where each descriptor has its OWN table.",
        ";       A sentence refuted by its own object.  The count is now the object's",
        ";       length and the curve's reach is a second clause; Q10d re-derives all",
        ";       319 of these sentences from the pool tiling.",
        ";     * the stored-index census above quoted 1,549 as the denominator for",
        ";       `7 distinct values`.  Over 1,549 the field takes 64, because a",
        ";       preset record's own +0x0B is its own index at 63 of its 64 records",
        ";       (round 9 Q11).  7 is the figure over the other 1,485.",
        ";",
        "; ⚠ AND ROUND 9 PROMOTED NOTHING.  Three mechanisms that would have moved",
        ";   the count were measured and refused, so a later round need not re-invent",
        ";   them:",
        ";     * the twin rule -- the one that named 194 records in the +0x18 and",
        ";       +0x20 arrays -- run for the first time on the %d records of" % n3c,
        ";       ToneDB_WaveSelTailPresets: 0 carried, against the melodic blocks",
        ";       AND against the drum tails.  Those %d labels stay framed for a" % n3c,
        ";       measured reason now, not for want of trying.  (Q12)",
        ";     * M8, the mechanism after round 8's M7: place a record NO byte",
        ";       identity reaches by the monotone owner order.  0 of 12 on the +0x20",
        ";       array, whose order holds; on the +0x18 array, which has %d backward"
        % back18,
        ";       steps over %d anchors, it proposes ONE owner for THREE different"
        % anch18,
        ";       records, which refutes it.  (Q13)",
        ";     * General MIDI, the obvious route to naming a program-map row.  Round",
        ";       5 refused it by citing two programs; round 9 refuses it with a count",
        ";       and reads the 16 family names out of prom_b's own `GM RE-MAP` screen",
        ";       instead of typing them: the best row aligns on 18 of 128 programs",
        ";       where a deliberately rotated null aligns on 11, and the eight rows",
        ";       score 15..18, so it does not tell them apart either.  (Q14)",
        ";",
        "; ⚠ ORIGIN STAYS 0 and round 9 proposes no change to it.  What is still open",
        ";   is WHICH PHYSICAL PART this is -- a document question, not a disassembly",
        ";   one, and no census of these bytes can answer it.",
        ";",
    ])


def _round11_header_lines():
    """The round-11 block: the sound group, and what it did and did not name."""
    kits, kitgroups, drumrows = _R8.group_kit_witness()
    _n3c = _R6.array_records(0x3C)[1]
    _cens = _R8.map_selector_census()
    _CENS_SEL = [r for r in _cens if r[0] == _R8.SELECTOR_SLOT][0]
    _CENS_OTH = [r for r in _cens if r[0] != _R8.SELECTOR_SLOT]
    _n20 = _R6.array_records(0x20)[1]
    _fr20 = sum(1 for _k in range(_n20) if _k not in _R8.wavesel_labels_r8(0x20))
    _tg = _R8.tone_group(0x5D)
    return "\n".join([
        ";",
        "; " + "-" * 78,
        "; \u2605\u2605 WAVE 7 ROUND 11 -- THE SOUND GROUP: WHAT THE PANEL CALLS TONE k",
        "; " + "-" * 78,
        ";",
        "; Every round from 4 to 10 asked this image about itself, or about prom_c,",
        "; which is the only image that READS it.  Round 11 asked the two images",
        "; nobody had opened: prom_a, which paints the panel, and prom_b, which",
        "; stores the panel's text.  They settle a sentence that had stood over this",
        "; image's tone table since round 4 -- that its index order is `a Technics-",
        "; internal ordering; nothing here identifies which panel control it",
        "; corresponds to`.",
        ";",
        "; \u2605\u2605 THE TONE INDEX IS %d*GROUP + MEMBER, and it is a proof rather than an"
        % GRP_MEMBERS,
        "; alignment:",
        ";   * prom_a addresses prom_b's group/member table at 0x%06X as 0xFC230C"
        % GRP_MEMBER_ADDR,
        ";     `mul WA,0x0010` + 0xFC2317 `mul BC,0x0002` + 0xFC231D `add XBC,",
        ";     0x00F06EF4` -- 16 bytes per group over 2 bytes per member, so a",
        ";     group's row holds %d members.  prom_b's own" % GRP_MEMBERS,
        ";     GroupMaxMemberIndex_ToneGroups at 0x%06X holds 0x%02X in all 16 of its"
        % (_R8.GROUP_MAXMEM_ADDR, GRP_MEMBERS - 1),
        ";     bytes, which is the same number said a second way.",
        ";   * entry k of that table is a (program, bank-select) pair, and resolving",
        ";     it through THIS image's own ToneDB_BankMap (+0x6C) and",
        ";     ToneDB_ToneNumBanks (+0x04) gives tone k -- %d consecutive entries,"
        % GRP_RUN,
        ";     entry 0 and entry %d both checked, and entry %d is the first that is"
        % (GRP_RUN - 1, GRP_RUN),
        ";     not its own index.  So the table is the INVERSE of this image's",
        ";     program map and is indexed by TONE INDEX.",
        ";   * %d / %d = %d groups, and prom_b's 16-byte name table at 0x%06X has"
        % (GRP_RUN, GRP_MEMBERS, GRP_COUNT, GRP_NAME_ADDR),
        ";     EXACTLY %d named rows before row %d turns into `----------------`:"
        % (GRP_COUNT, GRP_COUNT),
        ";     PIANO, E.PIANO, HARPSI. & MALLET ... PERCUSSION, EFFECT, DRUMS 1,",
        ";     DRUMS 2.",
        ";",
        "; \u26a0 WHICH NAME GOES WITH WHICH OCTET is a SEPARATE claim from that, and it",
        ";   has two independent witnesses rather than an assertion: %d of the %d"
        % (GRP_WORDHITS, GRP_COUNT),
        ";   group names share a word of >=3 letters with one of the %d tone names"
        % GRP_MEMBERS,
        ";   their octet holds, where rotating the numbering scores at most %d -- and"
        % GRP_WORDNULL,
        ";   the +/-1 shifts are NOT independent nulls, because the list has runs like",
        ";   GUITAR 1/2/3, which Q21 states rather than hides.  And at the END of the",
        ";   table, where a rule that stops early shows, the %d tone names ending in"
        % len(kits),
        ";   `Kit` occupy exactly groups %s, which are exactly the rows whose text"
        % kitgroups,
        ";   spells DRUM.  %d groups share no word and are listed by name in Q21."
        % (GRP_COUNT - GRP_WORDHITS),
        ";",
        "; \u26a0 WHAT IT DOES NOT SAY: it names no BYTE of a tone record and says",
        ";   nothing about what a group means to the synthesis.  It says what the",
        ";   PANEL calls tone k, and every banner below claims only that.",
        ";",
        "; \u2605 WHAT IT NAMED: %d framed records of ToneDB_MixerDefaultTable, as"
        % len(GRP_LABEL),
        ";   `_SelectedForGroup_<GROUP>` -- the records whose map columns ALL lie in",
        ";   one group.  The bound is 1 and not round 8's 3 because a group already",
        ";   names %d tones; the sweep to 5 is printed in Q22.  Two of the %d are the"
        % (GRP_MEMBERS, len(GRP_LABEL)),
        ";   records round 10 refused because the only tone name there CamelCases to",
        ";   `161`, and one is the LAST record of the array, which round 10 refused",
        ";   for carrying four names.",
        ";   \u26a0 AND THE RULE COSTS ONE NAME, printed rather than left implicit:",
        ";   round 10 never labels a record that HAS a byte twin, so that no derived",
        ";   name can contradict another, and M10 keeps that rule.",
    ] + ["; " + _w for _w in _wrap72(
        "  ".join("record %d's map columns are all %s, while the tone blocks that "
                  "carry its bytes reach %s."
                  % (_k, _R8.group_name(_g[0]).strip(),
                     " and ".join(_R8.group_name(_x).strip() for _x in _t))
                  for _k, _g, _t in _R8.group_twin_conflicts()), "   ")] + [
        ";   That is the record the rule is for.  (Q22f)",
        ";",
        "; \u26a0 AND WHAT IT REFUSED, measured rather than skipped:",
        ";   * the %d records of ToneDB_WaveSelTailPresets.  The %d presets anything"
        % (_n3c, len(_R8.preset_referrers())),
        ";     selects at all are selected by records of the +0x18 array, and none",
        ";     reaches one group by either route.  The nearest miss is preset 4, ALL",
        ";     16 of whose records are identified and which spans BRASS, TRUMPET and",
        ";     DEEP BRASS -- three groups, %d tones.  (Q24)" % (3 * GRP_MEMBERS),
        ";   * the %d framed records of ToneDB_PercMixerDefaultTable: a drum record's"
        % _fr20,
        ";     group can only be one of the %d rows spelling DRUM, so the coarser"
        % len(drumrows),
        ";     question is coarser than the array itself.  (Q25)",
        ";   * tone record 0x05D, whose own 16 bytes are the drawbar registration",
        ";     this tree's CamelCase rule turns into `161`.  It is member %d of group"
        % _tg[1],
        ";     %d %r -- so the object is PLACED -- and it KEEPS the `161` label,"
        % (_tg[0], _R8.group_name(_tg[0]).strip()),
        ";     because spelling the apostrophes would invent a morpheme.  (Q26)",
        ";",
        "; \u2605\u2605 AND A CENSUS ROUND 10 RAN ON ONE MAP, RUN ON ALL TEN.  Of the ten",
        ";   1,024-entry maps whose range fits the %d-record array, ONLY slot +0x%02X"
        % (_R6.array_records(0x18)[1], _R8.SELECTOR_SLOT),
        ";   is a selector: it agrees with the byte rule on %.1f%%%% of its asked"
        % (100.0 * _CENS_SEL[5] / _CENS_SEL[4]),
        ";   positions and the best of the other %d reaches %.1f%%%%, each within a"
        % (len(_CENS_OTH), max(100.0 * r[5] / r[4] for r in _CENS_OTH)),
        ";   few points of its own shuffled null.  It reaches 0 of the %d unreached"
        % _CENS_SEL[10],
        ";   records, while the maps that DO reach them are exactly the ones that",
        ";   fail the test.  So `unreached` is now a statement about the only map",
        ";   that IS a selector, not about the only map anyone tried.  (Q23)",
        ";",
    ])


def _round12_header_lines():
    """The round-12 block: the complete framed inventory, two refused mechanisms,
    and one cross-image candidate this round deliberately did not spend.

    Every number below is computed by notes/prom_d_finish_round12.py at
    generation time.  Nothing here is typed."""
    _fr = _R12.FRAMED
    _fam = _R12.FAMILY
    hits, n3c, pop, ctrl, _cn = _R12.m11()
    props, agree, disagree, _conf, _runs, _r2r = _R12.m12()
    sg = _R8.selector_groups()
    both = [k for k in props if sg.get(k)]
    names, n64, _pre = _R12.name_table()
    tabs = _R12.dl_mask3f_tables()
    mine = [t for t in tabs if t[2] == _R12.PROM_B_BASE + _R12.NAME_TABLE]
    e, o, auc, _ne, _no = _R12.pair_phase()
    d18 = _R12.framed_distinctness(0x18)
    d20 = _R12.framed_distinctness(0x20)
    other64 = sorted(set(t[2] for t in tabs if t[4] == n64
                         and t[2] != _R12.PROM_B_BASE + _R12.NAME_TABLE))
    return "\n".join([
        ";",
        "; " + "-" * 78,
        "; \u2605\u2605 WAVE 7 ROUND 12 -- EVERY REMAINING FRAMED LABEL, WITH A REASON EACH",
        "; " + "-" * 78,
        ";",
        "; Rounds 4-11 each measured something new.  What this image did not have is",
        "; the thing a FINISHED image needs: one table that names every object still",
        "; carrying a kind-plus-a-number and states, per object, why.  Round 12 is",
        "; that table -- %s objects in %d families, a reason DERIVED for each, and one"
        % (format(len(_fr), ","), len(_fam)),
        "; command that re-checks it:",
        ";       python3 notes/prom_d_finish_round12.py            # the inventory",
        ";       python3 notes/prom_d_finish_round12.py --selftest # %d checks"
        % _R12.AUDITED_CHECKS,
        ";",
        "; \u2605\u2605 AND IT PROMOTES NOTHING, ON PURPOSE.  Three mechanisms were run for",
        "; the first time and none of them is spent:",
        ";",
        ";   * M11, THE TAIL-ONLY TWIN RULE.  Round 9's Q12 ran the twin rule on the",
        ";     +0x3C array over WHOLE records and got 0 of %d.  But a preset supplies" % n3c,
        ";     only bytes 13..42 -- prom_c 0xFBC7D9 sets i = 13 and 0xFBC7E3 reads",
        ";     the stride word 43 as the bound -- so the head has nothing it must",
        ";     match and the old test was harder than the mechanism needs.  Run on",
        ";     the exact 30 bytes prom_c copies, against the %s wave-select records"
        % format(pop, ","),
        ";     that are not this array: %d of %d.  \u2605 AND THE TEST IS NOT INERT --"
        % (hits, n3c),
        ";     %s of those %s records DO share a tail with another record, so a"
        % (format(ctrl, ","), format(pop, ",")),
        ";     30-byte match is something this corpus produces in quantity.  The",
        ";     preset array shares none of them.",
        ";",
        ";   * M12, ROUND 8's M6 WITH ROUND 11's GROUP.  M6 named a no-twin record",
        ";     from the preset RUN it sits in and was refused for want of a common",
        ";     WORD; round 11 then supplied GROUPS, which are coarser, and nobody",
        ";     re-ran it.  Run here it proposes %d names -- and it is REFUSED, by the"
        % len(props),
        ";     witness it would have to agree with: where the run route and round",
        ";     11's map route both give exactly one group they DISAGREE on %d of %d,"
        % (disagree, agree + disagree),
        ";     and on the only proposal the map reaches at all (record %d) the run's"
        % (both[0] if both else -1),
        ";     answer, %r, is not even among the map's %d groups."
        % (_R8.group_name(props[both[0]]).strip() if both else "-",
           len(sg[both[0]]) if both else 0),
        ";     \u26a0 %d of the %d proposals come from ONE run with a single identified"
        % (max(collections.Counter(_r2r[k] for k in props).values()), len(props)),
        ";     member.  M12 IS REFUSED; a later round need not re-invent it.",
        ";",
        ";   * \u2605\u2605 prom_b's 64-ENTRY NAME TABLE -- A CANDIDATE, AND THE GAP THAT",
        ";     KEEPS IT ONE.  prom_b 0x%06X holds exactly %d rows of %d printable"
        % (_R12.PROM_B_BASE + _R12.NAME_TABLE, n64, _R12.NAME_W),
        ";     bytes and stops (%r .. %r).  It is read by exactly"
        % (names[0].strip(), names[n64 - 1].strip()),
        ";     %d display-list records, on the consecutive variables" % len(mine),
        ";     %s, " % " ".join("0x%04X" % t[1] for t in mine),
        ";     each masking with 0x%02X -- the same mask prom_c applies at"
        % _R12.DL_MASK,
        ";     0xFBC744 before indexing this image's %d-record" % n3c,
        ";     ToneDB_WaveSelTailPresets; rows 38..63 of it are 13 `X L` /",
        ";     `X H` pairs on the parity the paragraph below measures; and",
        ";     prom_a clamps that variable's edit range to 0..0x3F at 0xFD4176.",
        ";     If the panel variable IS that field, all %d framed records of the" % n3c,
        ";     +0x3C array are named at once.",
        ";     \u26a0\u26a0 NOTHING IN THE FOUR IMAGES SHOWS THAT IT IS.  The panel variable",
        ";     lives in one CPU's RAM at 0x2808..0x280B; the field is byte +0x0B of",
        ";     a 43-byte record in the other CPU's RAM at 0x87D2 + 43*n, and no",
        ";     instruction has been shown to carry the first into the second.  Two",
        ";     6-bit fields with the same mask and the same range are not the same",
        ";     field.  Nor is the candidate forced by elimination: %d other table%s"
        % (len(other64), "" if len(other64) == 1 else "s"),
        ";     of %d rows %s reached with the same mask (%s)."
        % (n64, "is" if len(other64) == 1 else "are",
           ", ".join("0x%06X" % t for t in other64) or "none"),
        ";     \u2605 WHAT WOULD CLOSE IT: an instruction chain from Arr2808_Set1",
        ";     (prom_a 0xFDA85E) to the link message prom_c decodes into",
        ";     (record + 0x0B).  Q31 states it so a later round can go straight at it.",
        ";",
        "; \u2605 WHAT DOES STAND ON THIS IMAGE'S OWN BYTES: the +0x3C array is built in",
        "; EVEN-ALIGNED PAIRS.  Over records 38..63 a record's mean Hamming distance",
        "; to its neighbour is %.2f of 43 bytes when the lower index is even and %.2f"
        % (e, o),
        "; when it is odd (AUC %.3f) -- and rows 38..63 of prom_b's table are 13"
        % auc,
        "; `X L` / `X H` pairs on that same parity.  \u26a0 IT IS A PARITY WITNESS AND",
        "; NOT AN ALIGNMENT PROOF: Q32 prints the shift sweep and EVERY EVEN SHIFT",
        "; scores the same.  Quoting it as an alignment result would be quoting it",
        "; wrong, so the refutation is printed beside it.",
        ";",
        "; \u2605 AND THE UNREACHED RECORDS ARE NOT PADDING.  The easiest way to dismiss",
        "; the %d records of the +0x18 array the selector map reaches at no entry is"
        % len(d18[0]),
        "; to suppose the array is over-allocated.  Measured: all %d are byte-DISTINCT"
        % d18[1],
        "; from one another (largest identical group %d), one run of them %d records"
        % (d18[2], max(h - l + 1 for l, h in d18[3])),
        "; long; the +0x20 array's %d framed records are likewise %d distinct."
        % (len(d20[0]), d20[1]),
        "; Padding repeats; these do not.  The hole here is real data whose selector",
        "; this tree has not found, and saying so is the honest version of the score.",
        ";",
    ])


_HDR = HEADER
_MARK = "; Reproduce every number quoted in this file:"
assert _MARK in _HDR
_HDR = _HDR.replace(_MARK, _round7_header_lines() + "\n"
                    + _round8_header_lines() + "\n"
                    + _round9_header_lines() + "\n"
                    + _round11_header_lines() + "\n"
                    + _round12_header_lines() + "\n" + _MARK, 1)
_HDR = _HDR.replace(
    ";     python3 notes/prom_d_base_checks.py              # the base, 12 checks",
    ";     python3 notes/prom_d_base_checks.py              # the base, 12 checks\n"
    ";     python3 notes/prom_d_split_probe.py              # \u2605 THE SPLIT LOST NOTHING\n"
    ";     python3 notes/prom_d_finish_round7.py --selftest # the inventory, %d checks\n"
    ";     python3 notes/prom_d_inventory_round8.py --selftest # ★ THE WHOLE IMAGE, "
    "%d checks\n"
    ";     python3 notes/prom_d_finish_round12.py --selftest  # \u2605 THE FRAMED SET, "
    "%d checks" % (_R7.AUDITED_CHECKS, _R8.AUDITED_CHECKS, _R12.AUDITED_CHECKS), 1)
MAIN_TEXT = (_HDR % (CENSUS_CHECKS, CENSUS_CHECKS)).rstrip("\n")

# ---------------------------------------------------------------------------
# ★ THE THREE-WAY SPLIT -- ONE IMAGE, FOUR FILES
# ---------------------------------------------------------------------------
# ../kn5000-roms-disasm/table_data/ already cuts the SAME tone database into
# three modules, and prom_d's regions fall into the same three groups.  This
# generator writes that split instead of one 56,000-line file:
#
#     prom_d/wsa1_prom_d.s              the documentation header, and the three
#                                       .include lines that build the image
#     prom_d/tone_database_directory.s  directory, program maps, offset table
#     prom_d/tone_database_records.s    the melodic tone records
#     prom_d/tone_database_aux.s        everything from directory slot +0xAC on
#
# ⚠ BOTH CUT POINTS ARE READ OUT OF THE IMAGE'S OWN DIRECTORY, never typed in,
# so a boundary cannot drift away from the structure it is meant to follow:
#     MEL[0]   the smallest offset in the tone-record table at slot +0x08 --
#              the first tone record, which is where the KN5000's directory
#              module ends too (its 0x8324D4 is ToneRec_000).
#     S(0xAC)  ToneDB_DefaultLayerParams -- which is ALSO the first object of
#              the KN5000's aux module (its 0x855A48, dir +0xAC).  Two trees,
#              same directory slot, arrived at independently.
#
# `--monolithic` still prints the single-file rendering, and that is not a
# convenience: it is the BASELINE the split is proved against.  See
# notes/prom_d_split_probe.py.
SPLIT_AT_RECORDS = MEL[0]
SPLIT_AT_AUX = S(0xAC)
assert 0 < SPLIT_AT_RECORDS < SPLIT_AT_AUX < 0x80000

_LABEL = re.compile(r"^[A-Za-z_][A-Za-z_0-9]*:")
_RULE_EQ = "; " + "=" * 74
_RULE_DA = "; " + "-" * 74


def _structure_map(lines):
    """(title, file-range) for every region banner in a part's OWN output.

    Read back out of the emitted text rather than out of the region table, so
    a part's contents listing cannot disagree with the part.
    """
    out = []
    for i in range(len(lines) - 3):
        if (lines[i] == _RULE_EQ and lines[i + 2].startswith("; file 0x")
                and lines[i + 3] == _RULE_DA):
            out.append((lines[i + 1][2:].strip(), lines[i + 2][2:].strip()))
    return out


def _part_header(title, body, lines, lo, hi):
    """The header of one included part.  Every part says the same four things:
    it is generated, it is not a translation unit, where its provenance lives,
    and what it contains -- the last read back out of its own banners."""
    h = ["; " + "=" * 78,
         "; Technics SX-WSA1R -- prom_d -- THE TONE DATABASE",
         "; %s" % title,
         "; " + "=" * 78,
         ";",
         "; ⚠ GENERATED.  Edit scripts/analysis/gen_prom_d_asm.py, never this file;",
         "; then run the gate:",
         ";     python3 scripts/analysis/gen_prom_d_asm.py",
         ";     python3 scripts/analysis/assert_byte_identical.py",
         ";",
         "; ⚠ NOT A TRANSLATION UNIT.  It is `.include`d by prom_d/wsa1_prom_d.s,",
         "; which carries this image's whole provenance -- how the base 0x00F00000",
         "; was established two independent ways, why prom_d/prom_d.ld's ORIGIN stays",
         "; 0, the label census graded by provenance, and every standing caveat.",
         "; READ THAT FILE FIRST.  None of it is repeated here, and none of it was",
         "; reworded to make this split: the split MOVES lines, it does not edit them.",
         ";",
         "; file 0x%05X .. 0x%05X   (%s bytes)" % (lo, hi - 1, format(hi - lo, ",")),
         ";"]
    h.extend("; " + b if b else ";" for b in body)
    sm = _structure_map(lines)
    h.extend([";",
              "; WHAT IS IN IT -- read back out of this file's own region banners:"])
    for t, r in sm:
        h.append(";   %-58s %s" % (t[:58], r.replace("file ", "")))
    h.append("; " + "=" * 78)
    return "\n".join(h)


_DIR_BODY = [
    "First of the three, mirroring",
    "../kn5000-roms-disasm/table_data/tone_database_directory.s, which holds the",
    "same three things for the KN5000: the slot directory, the program maps and",
    "the tone-record offset table (its ROM 0x830000-0x8324D3).",
    "",
    "★ THE BOUNDARY IS THE IMAGE'S OWN.  This file ends at 0x%05X, the smallest"
    % SPLIT_AT_RECORDS,
    "offset in the tone-record table at directory slot +0x08 -- i.e. at the first",
    "tone record.  That is the same rule the KN5000 module follows; over there the",
    "first record is ToneRec_000 at 0x8324D4.",
    "",
    "⚠ ONE REGION HERE HAS NO KN5000 COUNTERPART.  Slot +0xA8 is UNUSED in the",
    "KN5000, so ToneDB_OctaveShiftByProgram has no sibling region to mirror and no",
    "name to transplant.  It is in this file because the boundary rule is `the head",
    "of the database, up to the first tone record`, and because it is a",
    "program-indexed map like the two tables above it -- not because the KN5000",
    "puts anything there.  Its own banner below states what is established about it",
    "and what is not.",
]

_REC_BODY = [
    "Second of the three, mirroring",
    "../kn5000-roms-disasm/table_data/tone_database_records.s -- there, 579 tone",
    "records tiling ROM 0x8324D4-0x855A47; here, the melodic records of tone",
    "indices 0x000-0x0FF.",
    "",
    "★ BOTH BOUNDARIES ARE THE DIRECTORY'S, not a stride sweep:",
    "  * it starts at 0x%05X, the smallest offset in the tone-record table at slot"
    % SPLIT_AT_RECORDS,
    "    +0x08;",
    "  * it ends at 0x%05X, directory slot +0xAC (ToneDB_DefaultLayerParams) -- and"
    % SPLIT_AT_AUX,
    "    the KN5000's aux module starts at exactly the same slot, its 0x855A48.",
    "    The two trees put this boundary in the same place without either having",
    "    been told, which is the strongest reason to think the cut is the design's",
    "    and not this generator's.",
    "",
    "⚠ WHAT IS DELIBERATELY *NOT* HERE, and the KN5000 makes the same three cuts:",
    "  * the DRUM-KIT records (tone indices 0x100-0x111, file 0x2B2AC) and the",
    "    DRAWBAR records (0x058/0x059, file 0x446B4).  They ARE tone records and",
    "    they ARE in the offset table, but they sit past slot +0xAC and so live in",
    "    tone_database_aux.s -- exactly where the KN5000 keeps its DrumKit_* and",
    "    DrawbarPreset_* records.",
    "  * ToneRec_Template_Clear (slot +0xB0).  It is a tone record in the ordinary",
    "    217 + N*124 layout, but it is NOT in the offset table, so it is not part of",
    "    that table's payload and is not a selectable tone.",
    "The rule that decides all three is the KN5000 module's own sentence: this file",
    "is `the payload behind the offset table`, in address order.",
]

_AUX_BODY = [
    "Third of the three, mirroring",
    "../kn5000-roms-disasm/table_data/tone_database_aux.s (its ROM",
    "0x855A48-0x87FFEF): everything after the melodic records -- templates, index",
    "maps, wave-select arrays, the descriptor blocks and their pools, drum kits,",
    "drum instruments, the name-list/index-map/footer groups, the drawbar records,",
    "and the erased tail.",
    "",
    "★ IT STARTS AT DIRECTORY SLOT +0xAC, ToneDB_DefaultLayerParams, and so does",
    "the KN5000's aux module -- both files' first object is the +0xAC record.  The",
    "boundary is read from this image's directory, not copied across.",
    "",
    "⚠ THE ERASED TAIL IS IN THIS FILE.  0x50B09..0x7FFEF is one unbroken 0xFF run",
    "and 0x7FFF0 is the build tag; the KN5000's aux module likewise ends on its own",
    "unused 0xFF fill.  `prom_d_end` is NOT here -- it is in wsa1_prom_d.s, after",
    "the last .include, so that the end marker stays with the file that defines the",
    "image.",
]

PARTS = [
    ("tone_database_directory.s", 0x00000, SPLIT_AT_RECORDS,
     "DIRECTORY, PROGRAM MAPS AND THE TONE-RECORD OFFSET TABLE", _DIR_BODY),
    ("tone_database_records.s", SPLIT_AT_RECORDS, SPLIT_AT_AUX,
     "THE MELODIC TONE RECORDS", _REC_BODY),
    ("tone_database_aux.s", SPLIT_AT_AUX, 0x80000,
     "AUXILIARY TABLES", _AUX_BODY),
]

BUCKET = {name: [] for name, _lo, _hi, _t, _b in PARTS}
for a, b, fn in REGIONS:
    del OUTBUF[:]
    fn()
    assert OUTBUF, "region 0x%05X emitted nothing" % a
    for name, lo, hi, _t, _b in PARTS:
        if lo <= a < hi:
            assert b <= hi, "region 0x%05X..0x%05X straddles a split boundary" % (a, b)
            BUCKET[name].extend(OUTBUF)
            break
    else:
        raise AssertionError("region 0x%05X is in no part" % a)

SPLIT_BANNER = "\n".join([
    "",
    "; " + "=" * 78,
    "; ★ THE IMAGE ITSELF IS IN THREE INCLUDED FILES",
    "; " + "=" * 78,
    ";",
    "; Everything the header above says about `this file` -- the %s labels, the"
    % format(sum(1 for name, _lo, _hi, _t, _b in PARTS for ln in BUCKET[name]
                 if _LABEL.match(ln)), ","),
    "; census graded by provenance, every `below` and every `banner` -- now means",
    "; THESE FOUR FILES TOGETHER.  Not one sentence of it was reworded for the",
    "; split; the split moves lines between files and adds each file a header.",
    ";",
    "; The three parts mirror ../kn5000-roms-disasm/table_data/, which cuts the",
    "; SAME database the same way, and both cut points are read out of this image's",
    "; own directory rather than typed in:",
    ";",
    ";   tone_database_directory.s  0x%05X..0x%05X  directory, program maps, the"
    % (0, SPLIT_AT_RECORDS - 1),
    ";                                               tone-record offset table",
    ";   tone_database_records.s    0x%05X..0x%05X  the melodic tone records; ends"
    % (SPLIT_AT_RECORDS, SPLIT_AT_AUX - 1),
    ";                                               at directory slot +0xAC, where",
    ";                                               the KN5000's aux module starts",
    ";                                               too",
    ";   tone_database_aux.s        0x%05X..0x%05X  everything else, ending in the"
    % (SPLIT_AT_AUX, 0x7FFFF),
    ";                                               erased tail and the build tag",
    ";",
    "; ⚠ ORDER IS LOAD-BEARING.  This image is 0 .align directives and 0 .org: the",
    "; address of every byte is the sum of the lengths before it, so swapping two",
    "; .include lines silently moves 512 KiB of data.  The byte gate is what",
    "; catches that, and it is the only thing that would.",
    "; " + "=" * 78,
    "",
    '\t.include "tone_database_directory.s"',
    '\t.include "tone_database_records.s"',
    '\t.include "tone_database_aux.s"',
])

END_LINES = ["", "prom_d_end:"]


def _monolithic():
    """The single-file rendering this split is proved against.

    It is byte-for-byte what this generator emitted before the split, and
    notes/prom_d_split_probe.py compares it with the four files line by line.
    Keeping it is what makes `no comment and no label was lost` checkable
    rather than asserted.
    """
    body = []
    for name, _lo, _hi, _t, _b in PARTS:
        body.extend(BUCKET[name])
    return "\n".join([MAIN_TEXT] + body + END_LINES) + "\n"


if "--monolithic" in sys.argv:
    _STDOUT.write(_monolithic())
    sys.exit(0)

FILES = [(OUT, "\n".join([MAIN_TEXT, SPLIT_BANNER] + END_LINES) + "\n")]
for name, lo, hi, title, body in PARTS:
    lines = BUCKET[name]
    FILES.append((os.path.join(ROOT, "prom_d", name),
                  "\n".join([_part_header(title, body, lines, lo, hi)] + lines) + "\n"))

if "--check" in sys.argv:
    for path, text in FILES:
        _STDOUT.write(text)
else:
    for path, text in FILES:
        open(path, "w").write(text)
        print("wrote %-40s (%d lines, %.1f MB)"
              % (os.path.relpath(path, ROOT), text.count("\n"), len(text) / 1e6))
