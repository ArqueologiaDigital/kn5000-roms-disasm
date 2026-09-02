#!/usr/bin/env python3
"""Convert the 18-byte sound-parameter descriptor runs to C (lane w13/census-structs).

QUESTION THIS ANSWERS
  The v10 program ROM holds 972 descriptors of 18 bytes, registered at boot by
  SndParam_RegisterAllWidgets and reached afterwards through a hash table.  In
  the assembly they are 18 nameless `.byte` operands per record.  What is each
  field, and can the runs be written as a C array of a named struct that
  compiles byte-exact?

RUN
  python3 scripts/generators/gen_sndparam_records_c.py            # verify only
  python3 scripts/generators/gen_sndparam_records_c.py --write    # emit .c + patch .s

WHAT IT VERIFIES (asserts; refuses to write on failure)
  * each configured run's source lines are nothing but label lines, `.byte`
    rows and comment lines -- no instruction is silently retyped;
  * the bytes parsed out of the assembly equal the ROM bytes at that address,
    so a stale line/address pairing cannot slip through (this tree has been
    burned by exactly that);
  * every record is exactly 18 bytes and carries exactly one label;
  * every accessor index is inside the bound its dispatcher checks
    (+0x0C < 7, +0x0D < 9, +0x0E < 8, +0x10 < 3 raw / uses table slot n and
    n+3 for +0x0F), so a mis-parsed record cannot look plausible;
  * +0x03 is 0 in every record (the 32-bit key is effectively 24-bit).

FIELD PROVENANCE is written into sndparam_types.h, one citation per field.
"""
import argparse
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ROM = os.path.join(REPO, "original_ROMs", "kn5000_v10_program.rom")
ROM_BASE = 0xE00000
REC = 18
OUT_DIR = "v10/maincpu/audio/sndparam_records"
GEN_DIR = "v10/maincpu/includes/generated"

# source file, start address, record count.  Every run is a maximal stretch of
# consecutive 18-byte descriptors, taken from the pointer table at 0xEE0198 and
# split at the file boundary 0xEE0010 (extension_data.s ends there and
# widget_dispatch.s begins).  Runs shorter than 7 records are left in assembly:
# the surrounding lines interleave them with unrelated data and the line
# surgery would cost more than the 6 records it would move.
EXT = "v10/maincpu/extensions/extension_data.s"
WID = "v10/maincpu/ui_widgets/widget_dispatch.s"
# file, start address, record count, label of the first record
RUNS = [
    (EXT, 0xEDBAC0,  22, "VoiceCtrlR1_Entry_001"),
    (EXT, 0xEDBC9E,  78, "VoiceCtrlR1_Entry_027"),
    (EXT, 0xEDC2A4,  22, "MidiChParam_Entry_031"),
    (EXT, 0xEDC634,  19, "MidiChParam_Entry_065"),
    (EXT, 0xEDC7FA,   9, "MidiChParam_Entry_085"),
    (EXT, 0xEDC8A4,  10, "MidiChParam_Entry_094"),
    (EXT, 0xEDC980, 460, "MidiChParam_Entry_105"),
    (EXT, 0xEDE9FC, 314, "ExtPartParam_Entry_369"),
    (WID, 0xEE0010,  17, "NakaInst_Param_Bitmap80"),
]

# The four accessor tables and the codec table, read off widget_dispatch.s
# (Naka_MainDispatch_Table_0xDC0 / _0xDDC / _0xE00 / _0xE20 / _0xE38).
READ_ACC = ["SndParam_ReturnNotFound", "SndParam_ReadRegField",
            "SndParam_ReadRegWithLUT", "SndParam_CompareRegField",
            "SndParam_ReadRegWord", "SndParam_ReadRegBitfield",
            "SndParam_ReadRegAddress"]
REG_ACC = ["SndParam_ResetDefaultTable", "SndParam_RegisterEntry_Data",
           "SndParam_RegisterEntryAlt_Data", "SndParam_UpdateEntry_Data",
           "SndParam_RegisterMultiField_Data", "SndParam_RegisterBitfield_Data",
           "SndParam_RegisterLinked_Data", "SndParam_RegisterLinked2_Data",
           "SndParam_RegisterSimple_Data"]
LKP2_ACC = ["SndParam_DeregisterEntry_Data", "SndParam_RegisterChained_Data",
            "SndParam_RegisterChained2_Data", "SndParam_RegisterComplex_Data",
            "SndParam_NotifyQuick_Data", "SndParam_RegisterDual_Data",
            "SndParam_RegisterOffset_Data", "SndParam_RegisterWide_Data"]
CODEC = ["SndParam_EncodeFieldDirect_Data", "SndParam_EncodeFieldSub_Data",
         "SndParam_ClampReverbTime", "SndParam_DecodeField_Data",
         "SndParam_DecodeFieldAlt_Data", "SndParam_ClampDelayTime"]
WRITE_ACC = ["SndParam_ReturnInvalid", "SndParam_WriteFieldDirect_Data",
             "SndParam_WriteFieldSub_Data", "SndParam_PackAndWrite",
             "SndParam_WriteViaHash_Data", "SndParam_BatchUpdate_Data"]

# Comments that were in the assembly before the conversion and must survive it.
# Keyed by the ROM address they talk about; emitted above the record that
# contains that address.
CARRIED_COMMENTS = {
    0xEDC820: "data-as-code (v10_data_as_code_census.py, STRICT rule): "
              "0xEDC820-0xEDC830 (16 B), unreached CODE-territory, was "
              "disassembled as 12 plausible-but-dead instruction lines; "
              "per=67% dist=6 near MidiChParam_Entry_087+2",
    0xEDC924: "data-as-code (v10_data_as_code_census.py, STRICT rule): "
              "0xEDC924-0xEDC934 (16 B), unreached CODE-territory, was "
              "disassembled as 12 plausible-but-dead instruction lines; "
              "per=67% dist=6 near MidiChParam_Entry_101+2",
    0xEDC994: "data-as-code (v10_data_as_code_census.py, STRICT rule): "
              "0xEDC994-0xEDC9A4 (16 B), unreached CODE-territory, was "
              "disassembled as 11 plausible-but-dead instruction lines; "
              "per=67% dist=9 near MidiChParam_Entry_106+2",
    0xEDCBE6: "data-as-code (v10_data_as_code_census.py, STRICT rule): "
              "0xEDCBE6-0xEDCBF6 (16 B), unreached CODE-territory, was "
              "disassembled as 11 plausible-but-dead instruction lines; "
              "per=67% dist=9 near VoiceParamEx_Entry_027+2",
}

LABEL_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):\s*$")
BYTE_RE = re.compile(r"^\t\.byte ((?:0x[0-9a-f]{2}(?:, )?)+)$")
EQU_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*) = SndParamRun_[0-9A-F]+ \+ (\d+)$")


def run_name(start):
    return "run_%06x" % start


def find_range(src, start, count, label0):
    """Locate [first, last] source lines holding `count` records from label0.

    Returns None if the run is already converted (the label is an equate).
    Refuses anything but label / .byte / comment / blank lines, and refuses a
    run whose last record does not end exactly at the end of a source line.
    """
    for i, line in enumerate(src, 1):
        if EQU_RE.match(line) and EQU_RE.match(line).group(1) == label0:
            return None
    first = None
    for i, line in enumerate(src, 1):
        m = LABEL_RE.match(line)
        if m and m.group(1) == label0:
            first = i
            break
    assert first is not None, ("label not found", label0)
    want = count * REC
    got, last = 0, None
    for i in range(first + 1, len(src) + 1):
        line = src[i - 1]
        if LABEL_RE.match(line) or line.strip().startswith(";") or not line.strip():
            continue
        head, _, tail = line.partition("\t")
        if head.endswith(":") and tail:
            line = "\t" + tail
        st = line.strip()
        m = BYTE_RE.match(line)
        if m:
            got += len(m.group(1).split(", "))
        elif st == "nop":
            got += 1
        elif st == "swi\t7":
            got += 1
        elif st == 'aligned_string ""':
            got += 1
            if (got) % 2:
                got += 1
        else:
            raise AssertionError("unexpected line %d in run at 0x%X: %r"
                                 % (i, start, line))
        if got >= want:
            last = i
            break
    assert got == want, ("run at 0x%X ends mid-line: %d of %d bytes at line %d"
                         % (start, got, want, last))
    return first, last


SWI7 = re.compile(r"^\t?swi\t7$")


def parse_run(src, first, last):
    """-> (blob, [(label, offset)], {offset: [comment]}) over lines [first,last].

    Accepts label lines, `.byte` rows, comments, and the three FAKE-CODE forms
    that a previous pass left inside this data -- `nop`, `swi 7` and
    `aligned_string ""`.  Their byte widths are asserted against the ROM by
    verify(), which is what makes accepting them safe.
    """
    blob, labels, comments = bytearray(), [], {}
    for n in range(first, last + 1):
        line = src[n - 1]
        head, _, tail = line.partition("\t")
        m = LABEL_RE.match(line)
        if m:
            labels.append((m.group(1), len(blob)))
            continue
        if head.endswith(":") and tail:
            labels.append((head[:-1], len(blob)))
            line = "\t" + tail
        m = BYTE_RE.match(line)
        if m:
            blob.extend(int(x, 16) for x in m.group(1).split(", "))
            continue
        st = line.strip()
        if st.startswith(";"):
            comments.setdefault(len(blob), []).append(st)
            continue
        if st == "":
            continue
        if st == "nop":
            blob.append(0x00)
            continue
        if SWI7.match(line) or st == "swi\t7":
            blob.append(0xFF)   # swi 7 is a single byte, 0xF8|7
            continue
        if st == 'aligned_string ""':
            blob.append(0x00)
            if len(blob) % 2:
                blob.append(0xFF)
            continue
        raise AssertionError("unexpected source line %d: %r" % (n, line))
    return bytes(blob), labels, comments


def verify(blob, start, count, rom):
    assert len(blob) == count * REC, ("blob is %d bytes, want %d"
                                      % (len(blob), count * REC))
    assert rom[start - ROM_BASE:start - ROM_BASE + len(blob)] == blob, \
        ("bytes != ROM at 0x%X" % start)
    for i in range(count):
        d = blob[REC * i:REC * (i + 1)]
        where = "0x%06X" % (start + REC * i)
        assert d[3] == 0, ("key byte +0x03 not zero", where)
        assert d[0x0C] < len(READ_ACC), (where, "read accessor", d[0x0C])
        assert d[0x0D] < len(REG_ACC), (where, "register accessor", d[0x0D])
        assert d[0x0E] < len(LKP2_ACC), (where, "lookup2 accessor", d[0x0E])
        assert d[0x0F] + 3 < len(CODEC), (where, "codec", d[0x0F])
        assert d[0x10] < len(WRITE_ACC), (where, "write accessor", d[0x10])


TYPES_H = '''/**
 * sndparam_types.h -- the 18-byte sound-parameter descriptor
 *
 * WHAT REGISTERS THESE.  SndParam_RegisterAllWidgets
 * (v10/maincpu/audio/sndparam_routines.s:3135-3151) walks 972 `.long` pointers
 * from Naka_SubDispatch_B_Table_0x8 (= 0xEE01A0, in ui_widgets/widget_dispatch.s),
 * reads the u32 at each record's +0x00 as a key, and hands the pair to
 * SndParam_InsertEntry, which hashes the key and stores {key, record pointer}
 * as an 8-byte slot in the RAM table at 0x34100.  Every later access re-hashes
 * a key (SndParam_LookupByKey / SndParam_ProbeEntry), recovers the record
 * pointer with `ld xwa, (xwa+4)`, and reads fields off it -- so every
 * `(xwa + N)` in the SndParam_* accessors is a read of the field at +N here.
 * Called once at boot from midi/midi_serial_routines.s (MIDI_INIT_SEQUENCES),
 * alongside a second pass, SndParam_ReregisterAll.
 *
 * FIELD PROVENANCE -- one citation per field, all in
 * v10/maincpu/audio/sndparam_routines.s unless stated:
 *
 *   +0x00 key           `ld xwa, (xbc)` :3145 -- the whole u32 is the lookup
 *                       key; the hash uses its low byte and its second byte
 *                       (:3159-3174, `and xhl,0xff` / `srl xhl,8` / `and 0x1f`,
 *                       then DivMod32 by 0x7FF), and the stored key is compared
 *                       whole at :3196 `cp xiz, xde`.  Byte +0x03 is 0 in all
 *                       972 records, so it is effectively 24-bit.
 *   +0x04 bank_index    `ld c,(xwa+4)` / `extz bc` / `sla bc,2` / `lda_24 xde,
 *                       (Naka_MainDispatch_Table_0xE50)` :813-816 -- x4 index
 *                       into the RAM-bank pointer table at 0xEE1160, whose
 *                       entries are 26 bytes apart (0xF9B6, 0xF9D0, ...).
 *                       `or xde,xde; ret z` -- a null bank aborts the access.
 *                       Same at :870-876, :917-923, :945, :1241-1246, :1996-1998.
 *   +0x05 bank_offset   `ld c,(xwa+5)` / `ld L,(XIX+BC)` :820-822 -- byte offset
 *                       inside that bank.  Word variant doubles it
 *                       (`add bc,bc`, :924-927).
 *   +0x06 mask          `ld l,(xbc+6)` / `and l,a` :2523-2524 (encode) and
 *                       `ld c,(xde+6)` / `and a,c` :2569-2572 (decode).  Also
 *                       used inverted to clear bits in a caller struct:
 *                       `cpl c` / `and (xwa+3),c` :475-478.
 *   +0x07 clamp_min     `ld a,(xbc+7)` / `cp a,l` / `jr ule,+2` / `ld l,a`
 *                       :2508-2511 -- RAISES the value to +0x07.
 *   +0x08 clamp_max     `ld a,(xbc+8)` / `cp a,l` / `jr nc,+2` / `ld l,a`
 *                       :2512-2515 -- LOWERS the value to +0x08.
 *   +0x09 shift         `ld a,(xbc+9)` / `and a,0xf` / `jr z,+2` / `sll A,L`
 *                       :2516-2520 on the encode path, `srl A,L` :2574-2578 on
 *                       the decode path.  Only the LOW NIBBLE is ever read; no
 *                       instruction reads the high nibble.
 *   +0x0A xor_value     `ld a,(xbc+10)` / `xor a,l` :2521-2522; also
 *                       `ld c,(xwa+10)` / `xor hl,bc` :826-828.
 *   +0x0B aux_index     x4 index into the SAME descriptor pointer table, giving
 *                       a second record R: six readers use base 0xEE0198
 *                       (:890-894, :1256-1268, :2012-2027, :2530-2542,
 *                       :2602-2619, :2671-2683) and two use base+4 = 0xEE019C
 *                       (:928-931, :1361-1371).  R is consumed as a small byte
 *                       map (`cp l,(xbc+1)` -> R[3] else `cp l,(xbc+2)` -> R[4]
 *                       else R[5], :894-907), as a 2-way map (:1265-1268), as a
 *                       bias (:2021-2027) or as an LE16 array
 *                       (`add xde,xde` / `ld de,(xde)`, :1369-1371).
 *                       0xFF in the large majority of records; :837-841 also
 *                       compares it against the literal 2.
 *                       !! Which of those shapes applies to a given record is
 *                       decided by the accessor selected below, not by this
 *                       byte, so no per-record aux TYPE is claimed here.
 *   +0x0C read_accessor      `ld a,(xwa+12)` / `cps a,7` / `sla wa,2` /
 *                       Naka_MainDispatch_Table_0xDC0 (0xEE10D0) :293-302.
 *   +0x0D register_accessor  `ld c,(xwa+13)` / `cp c,0x9` /
 *                       Naka_MainDispatch_Table_0xDDC (0xEE10EC) :48-58.
 *   +0x0E lookup2_accessor   `ld a,(xwa+14)` / `cp a,0x8` /
 *                       Naka_MainDispatch_Table_0xE00 (0xEE1110) :178-189.
 *   +0x0F codec         `ld e,(xwa+15)` / `sla de,2` /
 *                       Naka_MainDispatch_Table_0xE20 (0xEE1130) :585-592 picks
 *                       slot n (the ENCODER); :463-472 does `inc 3,a` first and
 *                       picks slot n+3 (the matching DECODER).
 *   +0x10 write_accessor     `ld c,(xwa+16)` / `cps c,6` /
 *                       Naka_MainDispatch_Table_0xE38 (0xEE1148) :86-95.
 *   +0x11 unknown_0x11  !! NO READER.  No `(X??+0x11)` load exists anywhere in
 *                       the 0xFCD200-0xFCF000 accessor region.  0xFF in almost
 *                       every record, which is consistent with padding or a
 *                       terminator -- but consistent is not evidenced, so the
 *                       field is left named for its offset.
 *
 * Cross-field use worth knowing: SndParam_ReregisterAll :3260-3264 reads
 * (+0x04, +0x05, +0x06) together and SndParam_AllocAndInsert :3290-3330 packs
 * them (`+0x05 << 8` | `+0x04` | `+0x06`) into a second hash table at RAM
 * 0x97D8; and SndParam_WriteFieldSub_Data :2684-2704 builds the 4-byte packet
 * {+0x04, +0x05, value & mask, mask} for SndParam_PackAndWrite.
 *
 * !! The record LABELS (ExtPartParam_*, SeqMixParam_*, PartParam_*,
 * MidiChParam_*, VoiceParamEx_*, VoiceCtrlR1_*) are NOT evidence of anything.
 * Commits feda55d9 and 16f0917a assigned those six prefixes by ADDRESS-RANGE
 * BUCKETING, not by any reader; nothing distinguishes the six kinds
 * structurally and no code references any of the labels.  They are preserved
 * here only because the pointer table names them.
 *
 * Generated-alongside: scripts/generators/gen_sndparam_records_c.py.
 */
#ifndef SNDPARAM_TYPES_H
#define SNDPARAM_TYPES_H

#include <stdint.h>

typedef struct __attribute__((packed)) {
    uint32_t key;                /* +0x00 hash key; +0x03 always 0 */
    uint8_t  bank_index;         /* +0x04 x4 index into the RAM-bank table */
    uint8_t  bank_offset;        /* +0x05 byte offset inside that bank */
    uint8_t  mask;               /* +0x06 AND mask */
    uint8_t  clamp_min;          /* +0x07 value is raised to this */
    uint8_t  clamp_max;          /* +0x08 value is lowered to this */
    uint8_t  shift;              /* +0x09 low nibble = shift count */
    uint8_t  xor_value;          /* +0x0A XORed with the value */
    uint8_t  aux_index;          /* +0x0B x4 index to a second record, 0xFF none */
    uint8_t  read_accessor;      /* +0x0C < 7  */
    uint8_t  register_accessor;  /* +0x0D < 9  */
    uint8_t  lookup2_accessor;   /* +0x0E < 8  */
    uint8_t  codec;              /* +0x0F encoder n, decoder n+3 */
    uint8_t  write_accessor;     /* +0x10 < 6  */
    uint8_t  unknown_0x11;       /* +0x11 NO READER FOUND */
} sndparam_descriptor_t;

_Static_assert(sizeof(sndparam_descriptor_t) == 18,
    "sndparam_descriptor_t must be exactly 18 bytes");

#endif /* SNDPARAM_TYPES_H */
'''


def emit_c(name, start, blob, labels, comments):
    count = len(blob) // REC
    at = {}
    for lbl, off in labels:
        at.setdefault(off, []).append(lbl)
    out = ['/* %s.c -- %d sound-parameter descriptors, ROM 0x%06X-0x%06X.\n'
           ' * Generated by scripts/generators/gen_sndparam_records_c.py.\n'
           ' * Field meanings and their provenance: sndparam_types.h.\n */\n'
           % (name, count, start, start + len(blob)),
           '#include "sndparam_types.h"\n\n',
           'const sndparam_descriptor_t %s[%d]\n'
           '    __attribute__((section(".text"), used)) = {\n' % (name, count)]
    for i in range(count):
        d = blob[REC * i:REC * (i + 1)]
        for off in range(REC * i, REC * (i + 1)):
            for c in comments.get(off, []):
                out.append("    /* %s */\n" % c.lstrip("; ").rstrip())
        for a, c in sorted(CARRIED_COMMENTS.items()):
            if start + REC * i <= a < start + REC * (i + 1):
                out.append("    /* %s */\n" % c)
        names = []
        for off in range(REC * i, REC * (i + 1)):
            for lbl in at.get(off, []):
                names.append(lbl if off == REC * i else "%s(+%d)" % (lbl, off - REC * i))
        key = d[0] | (d[1] << 8) | (d[2] << 16) | (d[3] << 24)
        out.append("    /* [%3d] 0x%06X  %s */\n"
                   % (i, start + REC * i, ", ".join(names) or "(unlabelled)"))
        out.append("    { .key = 0x%08X," % key)
        out.append(" .bank_index = 0x%02X, .bank_offset = 0x%02X,\n" % (d[4], d[5]))
        out.append("      .mask = 0x%02X, .clamp_min = 0x%02X, .clamp_max = 0x%02X,"
                   " .shift = 0x%02X, .xor_value = 0x%02X,\n"
                   % (d[6], d[7], d[8], d[9], d[10]))
        out.append("      .aux_index = 0x%02X,\n" % d[11])
        out.append("      .read_accessor     = %d, /* %s */\n" % (d[12], READ_ACC[d[12]]))
        out.append("      .register_accessor = %d, /* %s */\n" % (d[13], REG_ACC[d[13]]))
        out.append("      .lookup2_accessor  = %d, /* %s */\n" % (d[14], LKP2_ACC[d[14]]))
        out.append("      .codec             = %d, /* %s / %s */\n"
                   % (d[15], CODEC[d[15]], CODEC[d[15] + 3]))
        out.append("      .write_accessor    = %d, /* %s */\n" % (d[16], WRITE_ACC[d[16]]))
        out.append("      .unknown_0x11 = 0x%02X },\n" % d[17])
    out.append("};\n")
    return "".join(out)


def emit_asm(name, start, blob, labels):
    count = len(blob) // REC
    sym = "SndParamRun_%06X" % start
    out = [";  %d x 18-byte sound-parameter descriptors, 0x%06X-0x%06X.\n"
           ";  The record structure and every field name are in\n"
           ";  audio/sndparam_records/%s.c + sndparam_types.h, which\n"
           ";  `clang -target tlcs900` compiles to the byte-identical blob below.\n"
           ";  The %d labels are kept as absolute equates so the pointer table in\n"
           ";  ui_widgets/widget_dispatch.s still resolves them.\n"
           % (count, start, start + len(blob), name, len(labels)),
           "%s:\n" % sym,
           "\t.incbin \"includes/generated/sndparam_%s.bin\"\n" % name]
    for lbl, off in labels:
        out.append("%s = %s + %d\n" % (lbl, sym, off))
    return "".join(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--write", action="store_true")
    args = ap.parse_args()
    rom = open(ROM, "rb").read()
    parsed = []
    for path, start, count, label0 in RUNS:
        name = run_name(start)
        src = open(os.path.join(REPO, path), encoding="latin-1").read().split("\n")
        sym = "SndParamRun_%06X" % start
        already = any(l.startswith(sym + ":") for l in src)
        blob = rom[start - ROM_BASE:start - ROM_BASE + count * REC]
        if already:
            labels = [(m.group(1), int(m.group(2))) for m in
                      (EQU_RE.match(l) for l in src)
                      if m and m.group(0).split(" = ")[1].startswith(sym + " ")]
            verify(blob, start, count, rom)
            parsed.append((name, path, None, None, start, blob, labels, {}))
            print("%-12s 0x%06X  %3d records  %5d bytes  %3d labels  already converted, re-verified"
                  % (name, start, count, count * REC, len(labels)))
            continue
        first, last = find_range(src, start, count, label0)
        blob, labels, comments = parse_run(src, first, last)
        verify(blob, start, count, rom)
        parsed.append((name, path, first, last, start, blob, labels, comments))
        print("%-12s %s:%d-%d  0x%06X  %3d records  %5d bytes  %3d labels  VERIFIED vs ROM"
              % (name, os.path.basename(path), first, last, start,
                 count, count * REC, len(labels)))
    total = sum(len(r[5]) // REC for r in parsed)
    print("total %d records, %d bytes" % (total, total * REC))
    if not args.write:
        print("(dry run; pass --write)")
        return 0

    os.makedirs(os.path.join(REPO, OUT_DIR), exist_ok=True)
    with open(os.path.join(REPO, OUT_DIR, "sndparam_types.h"), "w",
              encoding="ascii") as fh:
        fh.write(TYPES_H)
    for name, path, first, last, start, blob, labels, comments in parsed:
        with open(os.path.join(REPO, OUT_DIR, name + ".c"), "w",
                  encoding="ascii") as fh:
            fh.write(emit_c(name, start, blob, labels, comments))
        print("wrote", os.path.join(OUT_DIR, name + ".c"))

    # patch the .s files, highest line range first so earlier ranges stay valid
    by_file = {}
    for name, path, first, last, start, blob, labels, comments in parsed:
        if first is None:
            continue
        by_file.setdefault(path, []).append(
            (first, last, emit_asm(name, start, blob, labels)))
    for path, edits in by_file.items():
        full = os.path.join(REPO, path)
        src = open(full, encoding="latin-1").read().split("\n")
        before = len(src)
        for first, last, text in sorted(edits, reverse=True):
            src[first - 1:last] = text.rstrip("\n").split("\n")
        open(full, "w", encoding="latin-1").write("\n".join(src))
        print("patched %s: %d -> %d lines" % (path, before, len(src)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
