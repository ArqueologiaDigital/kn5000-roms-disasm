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
        "⚠ NO WSA1 INSTRUCTION THAT READS THIS TABLE HAS BEEN FOUND.  The names",
        "are transplanted, not derived.  Where prom_d's content contradicts the",
        "KN5000 role the label follows the CONTENT and the note says so.",
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
    ])
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
    ])
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
    ])
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
    ])
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
    "block or the wave-select record.  No consumer code has been read.",
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
    ])
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
    ])
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
    ])
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
        ])
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
        ])
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
        ] + ([] if 3 + D[a + 2] == b - a else [
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
    "⚠ NO field inside a descriptor, a part A or a part B is identified, and no",
    "WSA1 instruction that reads any of this has been found.",
]


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
               DESC_HDR + [""] + extra + [
                   "",
                   "Here: %d descriptors x 14 = %d bytes, then a pool of %d bytes"
                   % (H, 14 * H, b - P),
                   "at 0x%05X..0x%05X, holding %d objects.  %d + %d = %d, the whole"
                   % (P, b - 1, len(lab), 14 * H, b - P, b - a),
                   "block, with nothing unaccounted for.",
                   "KN5000 label at the same directory slot: %s." % SLOT[slot][2],
               ])
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
    ])
    W("ToneDB_DescCurveBank:")
    for k in range(CURVE_N):
        c = a + CURVE_STRIDE * k
        W("ToneDB_DescCurve_%d:\t\t; 128 entries, 0 .. %d" % (k, D[c + 127]))
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
    ])
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
        ])
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
        "0x00E80000..0x00EFFFFF, below this image.  prom_d/prom_d.ld still carries",
        "the old argument; its ORIGIN 0 stays correct either way, because this",
        "image is addressed by 0-based offsets and holds no absolute pointers.",
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
; designator and is NOT asserted here.  DATA ONLY -- all 64 words at file offset
; 0x7FF00 are 0xFFFFFFFF, so it is not a boot image and nothing in it executes.
;
; BASE: **NOT ESTABLISHED.**  ORIGIN 0 in prom_d/prom_d.ld is a build
; convenience and asserts nothing; the leading hypothesis (the 512 KiB flash at
; 0xE80000 on CPU 2's bus) and the one link it is still missing are set out in
; full in that file.  Every offset in this source is therefore FILE-RELATIVE,
; which is also how the image itself addresses its contents: it holds no
; absolute pointers, only 0-based offsets.
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
;   * NO WSA1 INSTRUCTION THAT READS ANY OF THESE STRUCTURES HAS BEEN FOUND.
;     Every region NAME is transplanted from the KN5000 directory slot with the
;     same offset.  They are hypotheses with a stated basis, not derivations.
;   * The MEANING of individual fields -- inside a tone record, an element
;     block, a wave-select record, a drum-instrument record, a descriptor -- is
;     unknown throughout.  Where a comment states a field, it states a shape
;     (a count, an offset, a stride) that was measured, never a semantics.
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
;     What still resists: the 8 x 128-byte table at +0xA8 (the KN5000 leaves that
;     slot unused, so there is no name to transplant and none is invented), and
;     every FIELD inside a descriptor, a curve or a pool row.
;     notes/prom_d_structures_round2.py, 78 checks.
;   * Directory slot +0x88 holds 0x125.  In the KN5000 the same slot holds a
;     SCALAR, not an offset.  Nothing here decides which prom_d means.
;
; Reproduce every number quoted in this file:
;     python3 scripts/analysis/prom_d_tone_database.py
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

W(HEADER.rstrip("\n"))
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
