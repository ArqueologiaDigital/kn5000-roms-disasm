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
import os
import struct
import sys

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

CENSUS_N = len(_R3.ALL_HITS)
CENSUS_SLOTS = len({h[2] for h in _R3.ALL_HITS})
CENSUS_CHECKS = _R3.NCHECK[0]


def ev_slot(slot, extra=()):
    """Evidence: lines for a directory slot -- or an honest statement of none.

    Never invents a reader.  A slot with no reader gets the gap, spelled out,
    because an honest hole is worth more than a confident wrong name and this
    tree has paid for that lesson.
    """
    sites = _R3.readers(slot)
    if not sites:
        return ["",
                "⚠ Readers: NONE FOUND.  notes/prom_d_documentation_round3.py walks",
                "every load of prom_d's base (0x00F00000, RAM 0x00D7ED / 0x00D7F1)",
                "in prom_c and every directory slot read through it -- %d reads over"
                % CENSUS_N,
                "%d slots -- and directory slot +0x%02X is not among them.  So this"
                % (CENSUS_SLOTS, slot),
                "region's NAME is still the KN5000 transplant and NOTHING in the WSA1",
                "firmware confirms it.  (The census is a LOWER BOUND: it does not",
                "follow a base parked in a frame slot.)"] + list(extra)
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
        "⚠ NOT established: what any of the 43 bytes means, or what the head/tail",
        "split is FOR.",
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
    0x3C: ("ToneDB_MixerDefaultTable_3C", "64 x 43-byte wave-select records", "UNUSED in the KN5000"),
    0x40: ("ToneDB_MixerDefaultTable_3C", "(alias of +0x3C)", "UNUSED in the KN5000"),
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
    0xA8: ("Unk_0FC8_Table", "8 x 128-byte records, purpose UNKNOWN", "UNUSED in the KN5000"),
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
        W("")
        W("; --- row %d (%s) ---" % (b, "melodic" if b < 8 else "drum kits"))
        W("ToneNumBank_%d:" % b)
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
def emit_unk_fc8():
    banner("Unk_0FC8_Table -- directory slot +0xA8, PURPOSE UNKNOWN", 0xFC8, 0x13C8, [
        "8 records of 128 bytes.  The period is not assumed: the only non-zero",
        "bytes sit at record-relative +0x0E, +0x58..+0x5F, +0x7A and +0x7E, and",
        "they repeat on a 0x80 grid in all 8 records.  Values are 0xF4 (and 0x0C",
        "at +0x7A in five of the eight).  Everything else is zero.",
        "",
        "⚠ The KN5000 leaves directory slot +0xA8 UNUSED, so there is no name to",
        "transplant and none is invented here.",
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
        "⚠ STILL NOT ESTABLISHED: what a record MEANS, what selects one, or what",
        "the 16-bit word at the computed offset is for.  What round 3 adds is the",
        "RECORD SIZE and the fact that the block is reached at all.",
    ]))
    W("Unk_0FC8_Table:")
    for k in range(8):
        W("Unk_0FC8_Rec_%d:" % k)
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
    W("")
    if n is None:
        W("; ---- tone 0x%03X %r  %d B  -- NOT 217+N*124, see the DRAWBAR note ----"
          % (idx, NAME(p), size))
    else:
        W("; ---- tone 0x%03X %r  %d B = 217 + %d x (81+43),  mask +0x11 = 0x%02X ----"
          % (idx, NAME(p), size, n, D[p + 0x11]))
    W("ToneRec_%03X:" % idx)
    e_ascii(p, 16)
    if n is None:
        e_bytes(p + 16, end)
        return
    W("\t; common part")
    e_bytes(p + 16, p + 217)
    for i in range(n):
        a = p + 217 + 81 * i
        W("ToneRec_%03X_Elem%d:" % (idx, i))
        e_bytes(a, a + 81)
    for i in range(n):
        a = p + 217 + 81 * n + 43 * i
        W("ToneRec_%03X_WaveSel%d:" % (idx, i))
        e_bytes(a, a + 43)


def emit_melodic_block():
    banner("MELODIC TONE RECORDS -- tone indices 0x000-0x0FF (254 of the 256 here)",
           0x13C8, GUNSHOT_END, TONE_HDR + [
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
        lines += [
            "",
            "Evidence: (image-internal, NOT from code) this region begins at",
            "0x%05X, which is directory slot +0x%02X's value, and ends at 0x%05X,"
            % (a, slot, b),
            "which is the next value in the same directory.  So the entry count %d"
            % n,
            "is pinned at BOTH ends by the image's own table and is not a stride",
            "guess -- the failure mode this tree has paid for.  The value range",
            "above is measured over all %d entries, first to last." % n,
        ] + ev_slot(slot, INDEXMAP_CHAIN(slot) if _R3.readers(slot) else ())
        banner("%s -- directory slot +0x%02X" % (slot_label(slot), slot), a, b, lines)
        W("%s:" % slot_label(slot))
        e_shorts(a, b)
    return fn


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
            "⚠ Field meanings NOT established, and ⚠ CORRECTED in wave 7 round 2:",
            "the leading 7F 7F 7F and the 7D 80 54 at +0x0D are NOT in every record.",
            "Counted over this array, first record to last: %d of %d start 7F 7F 7F"
            % (sum(1 for i in range(n) if D[a + 43 * i:a + 43 * i + 3] == b"\x7f\x7f\x7f"), n),
            "and %d of %d carry 7D 80 54 at +0x0D.  The earlier text said 'every"
            % (sum(1 for i in range(n) if D[a + 43 * i + 13:a + 43 * i + 16] == b"\x7d\x80\x54"), n),
            "record examined', which was the first record quoted as a universal.",
            "Re-derived by notes/prom_d_structures_round2.py section Q4b.",
        ] + WAVESEL_EV(slot, a, b, n) + ev_slot(slot, WAVESEL_CHAIN(slot)))
        W("%s:" % slot_label(slot))
        for i in range(n):
            W("%s_%03d:" % (slot_label(slot), i))
            e_bytes(a + 43 * i, a + 43 * (i + 1), per=43)
    return fn


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
    "                +0x09  1 B    unidentified",
    "                +0x0A  LE16   unidentified",
    "                +0x0C  LE16   unidentified",
    "",
    "Every non-null offset lands past the array and inside the block, and the",
    "SMALLEST of them is exactly where the array ends -- that is what proves the",
    "split, not a stride sweep.  The LAST descriptor's part-B offset is the last",
    "object in the pool, so both ends are pinned.  All of it is re-derived on",
    "every run of this generator by notes/prom_d_structures_round2.py, which",
    "refuses to emit if a boundary moved.",
    "",
    "⚠ NO field inside a descriptor, a part A or a part B is identified.",
]


def desc_hdr(slot):
    """DESC_HDR plus the one line that differs per block: is it READ?"""
    if _R3.readers(slot):
        return DESC_HDR + ["⚠ And no field is identified even though the block "
                           "IS reached: see the Evidence",
                           "line below, which pins the ARRAY STRIDE and nothing else."]
    return DESC_HDR + ["⚠ And no prom_c instruction that reads THIS block has been "
                       "found; the Evidence",
                       "note below states what that leaves standing and what it does not."]


def desc_pool_labels(slot):
    """Address -> (label, comment) for every object in this block's pool."""
    H, P, recs = DESC[slot]
    lab = {}
    pts = sorted({o for t, o1, o2, b9, w10, w12 in recs for o in (o1, o2) if o})
    owner = {}
    for i, (t, o1, o2, b9, w10, w12) in enumerate(recs):
        if o1:
            owner.setdefault(o1, ("A", i))
        if o2:
            owner.setdefault(o2, ("B", i))
    base = slot_label(slot)
    for p in pts:
        kind, i = owner[p]
        shared = sum(1 for _t, a1, a2, _b, _w, _v in recs
                     if (a1 if kind == "A" else a2) == p)
        note = "part %s of descriptor %d" % (kind, i)
        if shared > 1:
            note += " (shared by %d descriptors)" % shared
        lab[p] = ("%s_Pool_%s%03d" % (base, kind, i), note)
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
               ] + DESC_INTERNAL_EV(slot, H, P, recs) + ev_slot(slot, DESC_CHAIN(slot)))
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
        for j, p in enumerate(pts):
            e = pts[j + 1] if j + 1 < len(pts) else b
            name, note = lab[p]
            W("%s:\t\t; %s, %d bytes" % (name, note, e - p))
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
        "⚠ WHAT IS NOT ESTABLISHED: what the index MEANS.  128 entries is the MIDI",
        "note range and prom_c's Voice_SelectKeyZone_Reg0040 walks a 128-byte key",
        "map indexed by the played note (notes/FINDINGS-prom_c-dev10c-register-",
        "meanings.md §4b), which is why 'note-indexed curve' is the natural",
        "reading -- but no WSA1 instruction has been shown to read THIS table, so",
        "the label states the RELATIONSHIP that is proved (the descriptors point",
        "here) and not a synthesis role.",
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
        W("; ToneDB_DescCurve_%d -- file 0x%05X..0x%05X (%d bytes)"
          % (k, c, c + CURVE_STRIDE - 1, CURVE_STRIDE))
        W("; %d entries, non-decreasing, v[0] = 0, v[127] = %d.%s"
          % (CURVE_STRIDE, D[c + 127],
             "  Exactly index//12." if k == 0 else ""))
        W("; Evidence: %d of the 318 part-A objects at slot +0x30 name THIS curve"
          % _heads.get(c, 0))
        W("; in their leading LE32; the first is the object at 0x%05X.  %s"
          % (min(p for p, _e, kd, _i in _R2.desc_segments(0x30)
                 if kd == "A" and u32(p) == c),
             "The 161 descriptors at slot +0x38 share one part A, and it names "
             "this curve too." if c == a + CURVE_STRIDE * (CURVE_N - 1) else ""))
        W("ToneDB_DescCurve_%d:" % k)
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
    ])
    for k in range(18):
        p = a + 408 * k
        idx = IDX_OF[p]
        W("")
        W("; ---- tone 0x%03X %r ----" % (idx, NAME(p)))
        W("DrumKit_%03X:" % idx)
        e_ascii(p, 16)
        e_bytes(p + 16, p + 152)
        W("DrumKit_%03X_NoteMap:" % idx)
        e_shorts(p + 152, p + 408, comment=lambda i: "note %3d" % i)


def emit_percinst():
    a, b = S(0x78), NEXT[S(0x78)]
    n = (b - a) // PERC_STRIDE
    banner("PercInst -- directory slot +0x78", a, b, PERC_HDR + [
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
    W("PercInst_000_Silent:")
    for i in range(n):
        p = a + PERC_STRIDE * i
        if i:
            W("PercInst_%03d:" % i)
        W("\t; ---- drum instrument %3d %r ----" % (i, D[p:p + 13].decode("latin1")))
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
        W("")
        W("; ---- tone 0x%03X %r  541 B ----" % (idx, NAME(p)))
        W("ToneRec_%03X:" % idx)
        e_ascii(p, 16)
        e_bytes(p + 16, p + 217)
        for j in range(4):
            W("ToneRec_%03X_Elem%d:\t\t; 81-byte element block" % (idx, j))
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
    "the four part-B offsets name only THREE objects -- 4374, 4374 and 24 bytes,",
    "the first two being 729 rows of 6.  A column census over the first object",
    "picks period 6 (3 near-constant columns) over 4, 5, 7 and 8 (0 each).",
    "⚠ Tag 0x92 has bit 7 SET yet every object is a multiple of 6, so the bit-7",
    "rule stated on slot +0x30 is NOT claimed for this block.",
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

W((HEADER % (CENSUS_CHECKS, CENSUS_CHECKS)).rstrip("\n"))
for a, b, fn in REGIONS:
    before = len(OUTBUF)
    fn()
    assert len(OUTBUF) > before, "region 0x%05X emitted nothing" % a
W("")
W("prom_d_end:")

text = "\n".join(OUTBUF) + "\n"
if "--check" in sys.argv:
    sys.stdout.write(text)
else:
    open(OUT, "w").write(text)
    print("wrote %s  (%d lines, %.1f MB)" % (OUT, text.count("\n"), len(text) / 1e6))
