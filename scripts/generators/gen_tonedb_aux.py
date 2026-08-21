#!/usr/bin/env python3
"""Generate tone_database_aux.s — labeled disassembly of KN5000 table_data
ROM 0x855A48-0x87FFEF (auxiliary tone-database tables).

Every emitted byte is read from the original ROM; the script asserts full,
gapless coverage of the range. Output is LLVM/GNU syntax for llvm-mc
-triple=tlcs900.
"""
import struct, re, sys

import os
_REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ROM_PATH = os.path.join(_REPO, "original_ROMs", "kn5000_table_data.rom")
OUT_PATH = "tone_database_aux.s"  # written to the current directory
rom = open(ROM_PATH, "rb").read()

START = 0x855A48
END   = 0x87FFF0   # exclusive
BASE  = 0x830000   # ToneDB_Base (SubCPU alias 0x50000)

out = []
cursor = START     # running ROM address; every emitter must advance it

def emit(line=""):
    out.append(line)

def rd(addr, n):
    return rom[addr - 0x800000 : addr - 0x800000 + n]

def hexrow(b):
    return ", ".join(f"0x{x:02x}" for x in b)

def byterows(addr, n, per=16, indent="\t.byte\t"):
    """Emit n bytes at addr as .byte rows; advances cursor."""
    global cursor
    assert cursor == addr, f"cursor 0x{cursor:X} != 0x{addr:X}"
    b = rd(addr, n)
    for i in range(0, n, per):
        emit(indent + hexrow(b[i:i+per]))
    cursor += n

def shortrows(addr, count, per=8, comment_indices=True, slot_comment=None):
    """Emit count LE16 values as decimal .short rows; advances cursor."""
    global cursor
    assert cursor == addr, f"cursor 0x{cursor:X} != 0x{addr:X}"
    vals = [struct.unpack_from("<H", rom, addr - 0x800000 + 2*i)[0] for i in range(count)]
    for i in range(0, count, per):
        if slot_comment and i % 128 == 0:
            emit(f"\t; {slot_comment} {i // 128} (MIDI notes 0-127)")
        row = ", ".join(f"{v:5d}" for v in vals[i:i+per])
        cmt = f"\t; {i}-{min(i+per, count)-1}" if comment_indices else ""
        emit(f"\t.short\t{row}{cmt}")
    cursor += count * 2

def sanitize(name):
    s = re.sub(r"[^A-Za-z0-9]", "", name)
    return s if s else "Blank"

def ascname(addr, n):
    return rd(addr, n).decode("ascii")

# ---------------------------------------------------------------- header ---
emit("; =============================================================================")
emit("; TONE DATABASE — AUXILIARY TABLES (ROM 0x855A48 - 0x87FFEF)")
emit("; =============================================================================")
emit("; Part of the tone database that SubCPU_Send_Payload copies to SubCPU RAM:")
emit("; ROM 0x830000-0x87FFFF -> SubCPU 0x50000-0x9FFFF (five 64KB E1 bulk transfers,")
emit("; see maincpu SubCPU_Send_Payload; SubCPU DSP_System_Init stores base 0x50000).")
emit("; All offsets inside the database are relative to ToneDB_Base (= ROM 0x830000,")
emit("; seen by the SubCPU at 0x50000).  The 64-entry directory at 0x830000 holds")
emit("; LE32 offsets to the structures below; the directory slot for each structure")
emit("; is noted as \"dir +0xNN\" in its header comment.")
emit(";")
emit("; STRUCTURE MAP OF THIS MODULE:")
emit(";   0x855A48  ToneDB_DefaultLayerParams      81 bytes        dir +0xAC")
emit(";   0x855A99  ToneDB_ToneIndexMapA           1024 x LE16     dir +0x0C")
emit(";   0x856299  ToneDB_ToneIndexMapB           1024 x LE16     dir +0x10")
emit(";   0x856A99  ToneDB_MixerDefaultTable       337 x 11 bytes  dir +0x18/+0x1C")
emit(";   0x857914  ToneDB_EnvDescTable            487 x 15 bytes  dir +0x30/34/38")
emit(";   0x85959D  ToneDB_ToneIndexMapC           1024 x LE16     dir +0x24/+0x9C")
emit(";   0x859D9D  ToneDB_ToneIndexMapD           1024 x LE16     dir +0x28/+0xA0")
emit(";   0x85A59D  ToneDB_DrumToneIndexMap        1024 x LE16     dir +0x2C/+0xA4")
emit(";   0x85AD9D  ToneDB_VelocityCurve_0..5      6 x 128 bytes  key->band maps")
emit(";   0x85B09D  ToneEnv_* data chunks          974 blobs, 32732 bytes")
emit(";   0x863079  DrumKit_* records              26 x 295 bytes")
emit(";   0x864E6F  PercInst_* records             610 x 58 bytes  dir +0x78")
emit(";   0x86D8A3  DrumKit_NoteMapA               4096 x LE16     dir +0x74")
emit(";   0x86F8A3  ToneDB_PercMixerDefaultTable   142 x 11 bytes  dir +0x20")
emit(";   0x86FEBD  ToneDB_PercSourceIndexMapA     1024 x LE16     dir +0x14")
emit(";   0x8706BD  DrawbarPreset_Jazz/_Rock       2 x 426 bytes")
emit(";   0x870A11  DrawbarPreset_EnvDescTable     4 x 15 bytes    dir +0x70")
emit(";   0x870A4D  DrawbarPreset_EnvData_0..2     8772 bytes")
emit(";   0x872C91  ToneDB_SourceNameList1         333 x 16 bytes  dir +0x50")
emit(";   0x874161  ToneDB_SourceIndexMapA         1024 x LE16     dir +0x44")
emit(";   0x874961  ToneDB_SourceIndexMapB         1024 x LE16     dir +0x48")
emit(";   0x875161  ToneDB_SourceList1_Footer      17 bytes        dir +0x54")
emit(";   0x875172  ToneDB_SourceNameList2         339 x 16 bytes  dir +0x64")
emit(";   0x8766A2  ToneDB_SourceIndexMapC         1024 x LE16     dir +0x58")
emit(";   0x876EA2  ToneDB_SourceIndexMapD         1024 x LE16     dir +0x5C")
emit(";   0x8776A2  ToneDB_SourceList2_Footer      17 bytes        dir +0x68")
emit(";   0x8776B3  ToneDB_PercSourceNameList1     141 x 16 bytes  dir +0x8C")
emit(";   0x877F83  ToneDB_PercList1_Footer        14 bytes        dir +0x90")
emit(";   0x877F91  ToneDB_PercSourceIndexMapB     1024 x LE16     dir +0x4C")
emit(";   0x878791  ToneDB_PercSourceNameList2     144 x 16 bytes  dir +0x94")
emit(";   0x879091  ToneDB_PercSourceIndexMapC     1024 x LE16     dir +0x60")
emit(";   0x879891  ToneDB_PercList2_Footer        14 bytes        dir +0x98")
emit(";   0x87989F  ToneDB_DrumSourceNameList      424 x 16 bytes  dir +0x80")
emit(";   0x87B31F  ToneDB_DrumList_Footer         3 bytes         dir +0x84")
emit(";   0x87B322  DrumKit_NoteMapB               4096 x LE16     dir +0x7C")
emit(";   0x87D322  PercName_Pack                  610 x 10 chars  dir +0xB0")
emit(";   0x87EAF6  unused fill (0xFF)             5370 bytes")
emit(";")
emit("; COUNT RELATIONS (evidence for the cross-indexing):")
emit(";   ToneDB_SourceIndexMapA/B  max value 332/331 < 333 = SourceNameList1 count")
emit(";   ToneDB_SourceIndexMapC/D  max value 338/337 < 339 = SourceNameList2 count")
emit(";   ToneDB_PercSourceIndexMapA/B max 141/140 <= 141 = PercSourceNameList1 count")
emit(";   ToneDB_PercSourceIndexMapC max 143 < 144 = PercSourceNameList2 count")
emit(";   DrumKit_NoteMapA/B  entries all < 610 = PercInst record count")
emit(";   PercName_Pack has 610 entries = PercInst record count; entries 0-423 are")
emit(";     10-char abbreviations, in order, of the 424-entry ToneDB_DrumSourceNameList")
emit(";   Each *_Footer starts with an LE16 equal to the record count of the name")
emit(";     list opening its group ({names, index maps..., footer} chain of 5 groups)")
emit("; =============================================================================")
emit()
emit("\t.org 0x855A48 - 0x800000, 0xff")
emit()
emit("; Offsets stored inside the tone database are relative to its load base")
emit("; ToneDB_Base (ROM 0x830000 = SubCPU RAM 0x50000), defined as a label in")
emit("; tone_database_directory.s.")
emit()

# ------------------------------------------------- 1. default layer params ---
emit("; -----------------------------------------------------------------------------")
emit("; 81-byte parameter block (dir +0xAC).  81 bytes is exactly the per-layer")
emit("; quantum of the variable-length tone records at 0x8324D4 (record strides are")
emit("; 102+81k bytes), so this is most likely the default/template layer parameter")
emit("; set.  Values follow MIDI conventions: 0x40 = center, 0x7f = max, 100/60/40 =")
emit("; typical level defaults.")
emit("ToneDB_DefaultLayerParams:")
byterows(0x855A48, 81)
emit()

# ------------------------------------------------- 2-3. tone index maps A/B ---
def tone_index_map(addr, label, dirslots, extra):
    emit("; -----------------------------------------------------------------------------")
    emit(f"; 1024 LE16 tone indices ({dirslots}).  {extra}")
    emit(f"{label}:")
    shortrows(addr, 1024)
    emit()

tone_index_map(0x855A99, "ToneDB_ToneIndexMapA", "dir +0x0C",
    "Values 1-336: entries of the 629-entry tone-record offset table at 0x831B00.")
tone_index_map(0x856299, "ToneDB_ToneIndexMapB", "dir +0x10",
    "Values 2-334; companion of ToneDB_ToneIndexMapA (alternate tone selection).")

# ------------------------------------------------- 4. mixer default table ---
def mixer_table(addr, label, count, dirslots, extra):
    global cursor
    emit("; -----------------------------------------------------------------------------")
    emit(f"; {count} records x 11 bytes ({dirslots}).  Record: 3 level bytes (0x7f = max)")
    emit("; followed by 4 LE16 controller values (0x0040 = centered).  Per-tone mixer /")
    emit(f"; controller power-on defaults.  {extra}")
    emit(f"{label}:")
    assert cursor == addr
    for i in range(count):
        b = rd(addr + i*11, 11)
        emit(f"\t.byte\t{hexrow(b)}\t; {i}")
    cursor += count*11
    emit()

mixer_table(0x856A99, "ToneDB_MixerDefaultTable", 337, "dir +0x18/+0x1C", "")

# ------------------------------------------------- 5. envelope descriptors ---
# build chunk map first
recs = []
targets = {}
for i in range(487):
    off = 0x57914 + i*15
    r = rom[off:off+15]
    pA = struct.unpack("<I", r[1:5])[0]
    pB = struct.unpack("<I", r[5:9])[0]
    recs.append((r[0], pA, pB, r[9:15]))
    targets[pA] = f"ToneEnv_Rec{i:03d}_A"
    targets[pB] = f"ToneEnv_Rec{i:03d}_B"
assert len(targets) == 974

emit("; -----------------------------------------------------------------------------")
emit("; MULTISAMPLE SET DESCRIPTORS -- 487 records x 15 bytes (dir +0x30/+0x34/+0x38;")
emit("; the stride is the directory word +0xEC / +0xF2, both 15).")
emit(";")
emit("; One record describes one multisample SET: which recordings it is built from,")
emit("; where each one sits on the keyboard, and where the SET sits in pitch.  The")
emit("; subcpu keeps the pointer to it in the voice slot at +0x1F and in the per-part")
emit("; patch cache written by WaveSel_Cache_SetDescPtr (0x0328E2, cache word +0x76).")
emit(";")
emit("; RECORD LAYOUT")
emit(";   +0x00  u8    flags -- see below")
emit(";   +0x01  LE32  ToneDB_Base-relative offset of the SET key map (ToneEnv_*_A)")
emit(";   +0x05  LE32  ToneDB_Base-relative offset of the zone records (ToneEnv_*_B)")
emit(";   +0x09  u8    lowest key of the SET's range  (0..28; it is 12 in 462 of 487)")
emit(";   +0x0A  u8    highest key of the SET's range (65..120; it is 120 in 212)")
emit(";   +0x0B  u8    root key.  It sets the pitch pivot, root*256 + 0x80, on the")
emit(";                flags bit-1-CLEAR arm ONLY -- see FLAGS BIT 1 below.")
emit(";   +0x0C  LE16  base pitch, 8.8 log semitones -- the units of TG reg +0x400.")
emit(";                Also bit-1-CLEAR only in the portamento stage; see below.")
emit(";   +0x0E  u8    0x00 in 473 records, 1..5 in the other 14.  No reader located")
emit(";                in the v1.42 subcpu -- UNIDENTIFIED.")
emit("; +0x09 and +0x0A are the range that Pitch_Fold_Octaves_Into_Range (0x0229EC)")
emit("; and Pitch_Clamp_Into_Range (0x02299D) fold or clamp the computed pitch into.")
emit(";")
emit("; FLAGS BYTE (+0x00).  Census IN THIS TABLE: 0x00 x318, 0x80 x134, 0x02 x13,")
emit("; 0x08 x10, 0x81 x9, 0x01 x3 -- so only bits 0, 1, 3 and 7 are ever set here.")
emit("; The 15-byte format itself allows more: DrawbarPreset_EnvDescTable (dir +0x70)")
emit("; uses the same record with flags 0x92, i.e. bit 4 as well.")
emit(";   bit 7  zone-record stride: set -> 6 bytes (143 records), clear -> 4 bytes")
emit(";          (344 records).  WaveSel_StageB_Build_Reg040 (0x023849) tests bits")
emit(";          6, 7 and 5 and can also select strides 15, 12, 13 and 10, but bit 6")
emit(";          is clear in every record here, so those four forms never occur.")
emit(";   bit 1  PITCH TRAP -- see below.")
emit(";   bit 0  reserve level 0xFF: Voice_Calc_LevelPair_Full_CheckMax (0x025DBE)")
emit(";          and _Mono_CheckMax (0x026083) decrement an output level of exactly")
emit(";          0xFF when it is set.  12 records.")
emit(";   bit 3  set in 10 records; no reader located -- UNIDENTIFIED.")
emit(";")
emit("; HOW A SET IS REACHED (WaveSel_StageA2_FindSetDesc, subcpu 0x032750).  It")
emit("; takes two bytes, passed in C and A.  [INFERENCE] nothing in the ROM names")
emit("; them; C behaves as a family/sub-bank selector and A as a wave index.")
emit(";   family = C & 0xC0, sub = C & 0x0F, wave = A & 0x7F")
emit(";   set = u16[ dir[+0x24 | +0x28 | +0x2C] + 2*((sub << 7) | wave) ]")
emit(";         family 0x00/0xC0 -> +0x24 ToneDB_ToneIndexMapC")
emit(";         family 0x80      -> +0x28 ToneDB_ToneIndexMapD")
emit(";         family 0x40      -> +0x2C ToneDB_DrumToneIndexMap")
emit(";   descriptor = ToneDB_Base + dir[+0x30 | +0x34 | +0x38] + set*15")
emit("; Bit 2 of the global mode word 0x041343 substitutes slots +0x9C/+0xA0/+0xA4")
emit("; for the three index tables; those slots hold the same three offsets in this")
emit("; ROM, so the alternate path is a no-op here.  All three descriptor slots hold")
emit("; the same offset, so the three families share this one block.")
emit(";")
emit("; TWO POPULATIONS, split at record 341, and the index maps confirm the split:")
emit(";   000..340  MELODIC SETs.  ToneIndexMapC/D top out at 338 and 340 and never")
emit(";             reach 341.  223 are multi-zone, 143 use the 6-byte zone record.")
emit(";             All 328 with bit 1 clear carry root 0x42 and base pitch 0x4280,")
emit(";             i.e. base pitch - pivot = 0 exactly, so the note tracks the key.")
emit(";   341..486  PERCUSSION SETs, reached only from DrumToneIndexMap (whose 147")
emit(";             distinct values are exactly 335 and 341..486).  All 146 are")
emit(";             single-zone, 4-byte stride, range 12..120, root 0x42, and all")
emit(";             146 carry a base pitch other than 0x4280 -- so unlike the")
emit(";             melodic SETs they contribute a non-zero (base pitch - pivot)")
emit(";             transposition.  It is not a per-instrument tuning: only 18")
emit(";             distinct values occur, 94 sharing 0x4D44 and 22 sharing 0x4EBC.")
emit("; [INFERENCE] the split reads as an authoring convention.  It is proven as an")
emit("; indexing fact, but no code was found that enforces 341 as a boundary.")
emit(";")
emit("; FLAGS BIT 1 -- THE PITCH TRAP.  Exactly 13 records have it set: 49, 50, 52,")
emit("; 61, 63, 64, 66, 67, 68, 73, 74, 75 and 78.  They are exactly the 13 whose")
emit("; root byte is not the universal 0x42 (it is 0x00, 0x08 or 0x10), and all 13")
emit("; carry the same base pitch 0x417F.  On the bit-1 arm the portamento stage")
emit("; reads NEITHER field: Voice_Pitch_ApplyPortamento (0x023738) works around the")
emit("; literal 0x4280 instead -- Voice_Pitch_Portamento_Active_SubBias (0x023786)")
emit("; subtracts it and _AddBias restores it, and glide mode 7 loads it outright.")
emit("; So these SETs contribute no DESCRIPTOR-DERIVED pitch offset: the centre is")
emit("; 0x4280 whatever +0x0B and +0x0C hold, which is exactly why their contents")
emit("; are unconstrained AS PITCH DATA.  Anything that computes (base pitch -")
emit("; pivot) unconditionally therefore fabricates +48.996, +56.996 or +64.996")
emit("; semitones here, and these 13 SETs are the sole source of 112 of the 1444")
emit("; distinct recording selectors this table produces (7.8%).  That bug shipped")
emit("; in a generated pitch table used by an emulator until 2026-08-19.")
emit("; The bytes are not unread everywhere, though, so do not restate the trap as")
emit("; 'the fields are never read': Voice_Build_Partial_Descriptor (0x02B717) reads")
emit("; the root byte for keys >= 0x78 -- and only when bit 1 is SET, i.e. only for")
emit("; these 13 -- remapping the layer to key - 0x78 + root, while a layer whose")
emit("; SET has bit 1 clear is dropped at that key instead.  Voice_Pitch_CopyBase")
emit("; (0x023809, reached from Voice_Allocate_Typed and Voice_Allocate_Type2) reads")
emit("; the base pitch without testing bit 1 at all.  The trap is about the")
emit("; SUBTRACTION in the portamento stage, not about the bytes being unreachable.")
emit(";")
emit("; RETRACTED: this header used to say `487 records here + 142 records in")
emit("; ToneDB_PercMixerDefaultTable's sibling group = 629 ... suggesting one")
emit("; descriptor per tone`.  SETs are indexed by the 1024-entry maps above, not by")
emit("; the 629-entry tone-record table at 0x831B00; the arithmetic was a")
emit("; coincidence.")
emit(";")
emit("; Every census above is re-derived by analysis/wave7-probes/")
emit("; probe_set_descriptors.py (no arguments; reads original_ROMs).")
emit(";")
emit("; The 2x487 offsets are all distinct and exactly tile the ToneEnv data region")
emit("; 0x85B09D-0x863078 (974 chunks); the chunk header below has their layout.")
emit("ToneDB_EnvDescTable:")
assert cursor == 0x857914
for i, (fl, pA, pB, tail) in enumerate(recs):
    emit(f"\t.byte\t0x{fl:02x}\t; {i}")
    emit(f"\t.long\tToneEnv_Rec{i:03d}_A - ToneDB_Base, ToneEnv_Rec{i:03d}_B - ToneDB_Base")
    emit(f"\t.byte\t{hexrow(tail)}")
cursor += 487*15
emit()

# ------------------------------------------------- 6-8. more index maps ---
tone_index_map(0x85959D, "ToneDB_ToneIndexMapC", "dir +0x24/+0x9C",
    "Values 0-338; mostly ToneDB_ToneIndexMapA shifted down by 1.")
tone_index_map(0x859D9D, "ToneDB_ToneIndexMapD", "dir +0x28/+0xA0",
    "Values 3-340; companion of ToneDB_ToneIndexMapC.")
tone_index_map(0x85A59D, "ToneDB_DrumToneIndexMap", "dir +0x2C/+0xA4",
    "Values 335-486: the high band of the 0x831B00 table (drum/percussion tones).")

# ------------------------------------------------- 9. velocity curves ---
emit("; -----------------------------------------------------------------------------")
emit("; SET KEY->BAND TABLES -- six 128-byte tables.  THE LABEL NAME IS A MISNOMER")
emit("; KEPT FOR CONTINUITY: the input is the voice's PITCH, not the velocity.")
emit("; WaveSel_KeyTable_Lookup (subcpu 0x022A32) does `and bc,0x7F00 / sra bc,8` on")
emit("; the voice's pitch word (slot +0x06, i.e. after transpose, bend, glide and")
emit("; fine tune) and indexes one of these with the resulting integer semitone")
emit("; 0..127; the value returned is a band number that the owning SET's A chunk")
emit("; (see the ToneEnv chunk header below) turns into a zone-record index.")
emit("; A byte-by-byte scan of the whole 2 MB table ROM finds 488 LE32 values landing")
emit("; in this 768-byte block: the 487 SET A-chunk heads, every one of them on a")
emit("; table head, and one incidental match pointing 11 bytes into curve 3.  None")
emit("; of the six table addresses appears in any disassembled code either, in the")
emit("; ToneDB-relative form (0x2AD9D..) or in the subcpu view (0x7AD9D..).")
emit(";   curve 0  max  10, 11 bands   used by 274 SETs -- all 146 percussion SETs")
emit(";                                and 128 melodic ones")
emit(";   curve 1  max  20, 21 bands   used by  20 SETs")
emit(";   curve 2  max  27, 28 bands   referenced by no SET")
emit(";   curve 3  max  34, 35 bands   used by  27 SETs")
emit(";   curve 4  max  34, 35 bands   used by  15 SETs")
emit(";   curve 5  max 107, 108 bands  used by 151 SETs")
emit("; Curves 0-4 are stepped ramps of increasing depth; curve 5 is near-linear.")
emit("; Counts re-derived by analysis/wave7-probes/probe_set_descriptors.py.")
emit("; NOT RENAMED: whether these tables are ALSO used as velocity curves elsewhere")
emit("; was not checked, so only the description is corrected here.")
for k in range(6):
    a = 0x85AD9D + k*128
    b = rd(a, 128)
    emit(f"ToneDB_VelocityCurve_{k}:")
    for i in range(0, 128, 16):
        emit("\t.byte\t" + ", ".join(f"{x:3d}" for x in b[i:i+16]) + f"\t; v{i}-{i+15}")
assert cursor == 0x85AD9D
cursor += 6*128
emit()

# ------------------------------------------------- 10. ToneEnv data chunks ---
emit("; -----------------------------------------------------------------------------")
emit("; SET KEY MAPS AND ZONE RECORDS -- 974 variable-length chunks, one per LE32")
emit("; offset in ToneDB_EnvDescTable (chunk N ends where the next referenced offset")
emit("; begins).  Every SET descriptor owns exactly two: its key map (ToneEnv_*_A)")
emit("; and its zone-record array (ToneEnv_*_B).  Chunk size census: 15 x274,")
emit("; 4 x179, 112 x151, 6 x85, 39 x42, 36 x32, ...")
emit(";")
emit("; A CHUNK -- the SET's key map, walked by WaveSel_StageB_Build_Reg040")
emit("; (subcpu 0x023849):")
emit(";   +0x00  LE32  ToneDB_Base-relative offset of a 128-byte key->band table.")
emit(";                All 487 point at one of the five in-use tables in the")
emit(";                ToneDB_VelocityCurve_0..5 block above (whose name is a")
emit(";                misnomer -- see its header).")
emit(";   +0x04  u8[]  band -> zone-record index.  Its length is always")
emit(";                max(key table) + 1: 11, 21, 35 or 108 bytes, which is exactly")
emit(";                the four A-chunk sizes 15, 25, 39 and 112.  Its largest value")
emit(";                is always (number of zone records in the B chunk) - 1, in all")
emit(";                487 SETs -- the check that ties A, B and the flags together.")
emit(";   Lookup: band = keytable[(voice pitch >> 8) & 0x7F], by")
emit(";   WaveSel_KeyTable_Lookup (0x022A32); zone index = A[+0x04 + band].")
emit(";")
emit("; B CHUNK -- the zone records.  Stride 6 when descriptor flags bit 7 is set,")
emit("; stride 4 when it is clear; 2134 records in all, 1444 distinct selectors.")
emit(";   +0x00  LE16  recording selector, (class << 12) | entry.  Copied verbatim to")
emit(";                the staging word 0x0451CE = tone-generator register +0x040.")
emit(";                Class census 0..7: 311, 278, 229, 536, 312, 263, 77, 128.")
emit(";                [INFERENCE] what a class MEANS at the chip is not established")
emit(";                here -- the nibble is passed through, not decoded.")
emit(";   +0x02  u8    output-level field select, read by Voice_Build_OutputLevel")
emit(";                (0x0232C7):")
emit(";                  bit 7 SET   -> bits 6..4 are shifted into bits 14..12 of")
emit(";                                 tone-generator register +0x080 VERBATIM")
emit(";                                 (and wa,0x70 / sll wa,8);")
emit(";                  bit 7 CLEAR -> those three bits come from the subcpu table")
emit(";                                 at 0x00FBE4 indexed by the folded note.")
emit(";                Only nine values occur and they are exactly the ones that")
emit(";                encoding permits: 0x00 x1451, then 0x80 | (f << 4) for")
emit(";                f = 0..7 (190, 83, 91, 38, 113, 40, 92, 36).  The low nibble")
emit(";                is zero in all 2134 records, and no value has bit 7 clear")
emit(";                with bits 6..4 set.")
emit(";   +0x03  s8    pitch fine trim, 1/256 semitone per count (~0.39 cent), added")
emit(";                to the pitch accumulator by Voice_ComputePitch_ApplyLFO")
emit(";                (0x02647F) and _Mono_ApplyLFO (0x0265F1), which reach it")
emit(";                through the voice slot pointer at +0x0F.  Range -64..+16,")
emit(";                mean -10.4, negative in 2053 of the 2134 records.")
emit(";   +0x04  LE16  coarse pitch trim, 8.8 semitones -- STRIDE-6 RECORDS ONLY.")
emit(";                WaveSel_Emit_ZoneRecord_S6 (0x022AC5) stages it at 0x293E and")
emit(";                Pitch_Apply_Zone_Trim (0x023A8E) adds it; the stride-4 emitter")
emit(";                (0x022AE7) stores 0 there instead, so 4-byte zones carry no")
emit(";                coarse trim.  518 values, -33.00 .. +41.00 semitones, 80 zero.")
emit("; Both emitters also store the record's address in the voice slot at +0x0F,")
emit("; which is how Voice_Build_OutputLevel and Voice_ComputePitch_*_ApplyLFO reach")
emit("; +0x02 and +0x03 later.")
emit(";")
emit("; A SECOND CONSUMER of the same B chunk: WaveSel_StageB_Build_Reg040_Footage")
emit("; takes the array base from descriptor +0x05 too, but indexes it from a")
emit("; drawbar/footage state rather than the key map, and hard-codes stride 6 (the")
emit("; index is tripled and doubled inline).  Its store, WaveSel_StageB_Store_Reg040")
emit("; (0x02399D), additionally doubles the top nibble of 0x0451CE in place when bit")
emit("; 2 of the global mode word 0x041343 is set.")
emit(";")
emit("; CORRECTED 2026-08-21: this header used to say that larger chunks are built")
emit("; from 6-byte segments of the form 70 00 xx xx xx NN with NN incrementing, and")
emit("; called them envelope segment lists (rate/level pairs).  That framing was off")
emit("; by one byte: the segments are the zone records above, and the incrementing")
emit("; byte is the low half of the selector at +0x00 -- ToneEnv_Rec000_B runs")
emit("; 0x7000, 0x7001, 0x7002, ...  Nothing in these chunks is an envelope.")
emit("; Every census above is re-derived by analysis/wave7-probes/")
emit("; probe_set_descriptors.py (no arguments; reads original_ROMs).")
assert cursor == 0x85B09D
st = sorted(targets)
assert st[0] == 0x2B09D
bounds = st + [0x33079]
for idx in range(974):
    a = 0x830000 + bounds[idx]
    n = bounds[idx+1] - bounds[idx]
    emit(f"{targets[bounds[idx]]}:")
    b = rd(a, n)
    for i in range(0, n, 16):
        emit("\t.byte\t" + hexrow(b[i:i+16]))
    cursor += n
assert cursor == 0x863079, hex(cursor)
emit()

# ------------------------------------------------- 11. drum kits ---
emit("; -----------------------------------------------------------------------------")
emit("; 26 drum-kit records x 295 bytes: 16-char display name + 279 parameter bytes.")
emit("; Kits 0-13 are the first bank (Standard..MSP), kits 14-25 the second bank")
emit("; (Standard..Sound Effect).  Only ~19 parameter bytes differ between kits;")
emit("; per-note instrument assignment lives in DrumKit_NoteMapA/B (below), whose")
emit("; entries index the PercInst_* records.")
assert cursor == 0x863079
for i in range(26):
    a = 0x863079 + i*295
    name = ascname(a, 16)
    emit(f"DrumKit_{i:02d}_{sanitize(name)}:")
    emit(f'\t.ascii\t"{name}"')
    b = rd(a+16, 279)
    for j in range(0, 279, 16):
        emit("\t.byte\t" + hexrow(b[j:j+16]))
    cursor += 295
emit()

# ------------------------------------------------- 12. percussion instruments ---
emit("; -----------------------------------------------------------------------------")
emit("; 610 percussion-instrument records x 58 bytes (dir +0x78).")
emit("; Record: 13-char name, 3 header bytes, then two 21-byte layer parameter")
emit("; blocks.  The two layers are byte-identical in 609 of 610 records (the")
emit("; exception is flagged below).  DrumKit_NoteMapA/B entries index this table;")
emit("; PercName_Pack (0x87D322) also has exactly 610 entries.")
assert cursor == 0x864E6F
for i in range(610):
    a = 0x864E6F + i*58
    name = ascname(a, 13)
    hdr = rd(a+13, 3)
    l1 = rd(a+16, 21)
    l2 = rd(a+37, 21)
    emit(f"PercInst_{i:03d}_{sanitize(name)}:")
    emit(f'\t.ascii\t"{name}"')
    emit(f"\t.byte\t{hexrow(hdr)}")
    emit(f"\t.byte\t{hexrow(l1)}")
    if l1 == l2:
        emit(f"\t.byte\t{hexrow(l2)}")
    else:
        emit(f"\t.byte\t{hexrow(l2)}\t; only record whose two layers differ")
    cursor += 58
emit()

# ------------------------------------------------- 13. note map A ---
emit("; -----------------------------------------------------------------------------")
emit("; Drum-kit note map bank A (dir +0x74): 32 slots x 128 MIDI notes, each entry")
emit("; a LE16 PercInst_* record index (0 = Silent).  All values < 610.")
emit("DrumKit_NoteMapA:")
shortrows(0x86D8A3, 4096, comment_indices=False, slot_comment="note-map slot")
emit()

# ------------------------------------------------- 14. perc mixer defaults ---
mixer_table(0x86F8A3, "ToneDB_PercMixerDefaultTable", 142, "dir +0x20",
            "Percussion counterpart of ToneDB_MixerDefaultTable.")

# ------------------------------------------------- 15. perc source index map A ---
tone_index_map(0x86FEBD, "ToneDB_PercSourceIndexMapA", "dir +0x14",
    "Values 0-141: indices into the 141-entry ToneDB_PercSourceNameList1.")

# ------------------------------------------------- 16. drawbar presets ---
emit("; -----------------------------------------------------------------------------")
emit("; Two 426-byte drawbar organ preset records: 16-char display name + 410")
emit("; parameter bytes (drawbar footage levels, percussion/click settings).")
assert cursor == 0x8706BD
for i, lbl in enumerate(["DrawbarPreset_Jazz", "DrawbarPreset_Rock"]):
    a = 0x8706BD + i*426
    name = ascname(a, 16)
    emit(f"{lbl}:")
    emit(f'\t.ascii\t"{name}"')
    b = rd(a+16, 410)
    for j in range(0, 410, 16):
        emit("\t.byte\t" + hexrow(b[j:j+16]))
    cursor += 426
emit()

# ------------------------------------------------- 17. drawbar env descriptors ---
emit("; -----------------------------------------------------------------------------")
emit("; 4 drawbar envelope descriptor records x 15 bytes (dir +0x70), same layout")
emit("; as ToneDB_EnvDescTable records but with flags 0x92 and a null A-offset.")
emit("; The B-offsets select the DrawbarPreset_EnvData_* blobs below (records 1 and")
emit("; 2 share DrawbarPreset_EnvData_1).")
emit("DrawbarPreset_EnvDescTable:")
assert cursor == 0x870A11
dbl = {0x40A4D: "DrawbarPreset_EnvData_0", 0x41B63: "DrawbarPreset_EnvData_1",
       0x42C79: "DrawbarPreset_EnvData_2"}
for i in range(4):
    a = 0x870A11 + i*15
    r = rd(a, 15)
    pA = struct.unpack("<I", r[1:5])[0]
    pB = struct.unpack("<I", r[5:9])[0]
    assert pA == 0 and pB in dbl
    emit(f"\t.byte\t0x{r[0]:02x}\t; {i}")
    emit(f"\t.long\t0, {dbl[pB]} - ToneDB_Base")
    emit(f"\t.byte\t{hexrow(r[9:15])}")
cursor += 60
emit()
emit("; Drawbar envelope data blobs (6-byte segment lists, same 70 60 00 xx xx xx")
emit("; format family as the ToneEnv chunks).")
for a, n, lbl in [(0x870A4D, 0x1116, "DrawbarPreset_EnvData_0"),
                  (0x871B63, 0x1116, "DrawbarPreset_EnvData_1"),
                  (0x872C79, 0x18,   "DrawbarPreset_EnvData_2")]:
    emit(f"{lbl}:")
    byterows(a, n)
emit()

# ------------------------------------------------- name list helpers ---
def name_list(addr, count, label, dirslot, desc):
    global cursor
    emit("; -----------------------------------------------------------------------------")
    emit(f"; {count} records x 16 bytes ({dirslot}): 13-char source name + 3 id/flag bytes.")
    for d in desc:
        emit(f"; {d}")
    emit(f"{label}:")
    assert cursor == addr, f"{label}: cursor 0x{cursor:X} != 0x{addr:X}"
    for i in range(count):
        a = addr + i*16
        emit(f'\t.ascii\t"{ascname(a, 13)}"\t; {i}')
        emit(f"\t.byte\t{hexrow(rd(a+13, 3))}")
    cursor += count*16
    emit()

def footer(addr, label, dirslot, listname, count):
    global cursor
    emit("; -----------------------------------------------------------------------------")
    emit(f"; Group footer ({dirslot}): LE16 record count of {listname}")
    emit(f"; ({count}) followed by small per-category subdivision values.")
    emit(f"{label}:")
    assert cursor == addr
    n = struct.unpack_from("<H", rom, addr - 0x800000)[0]
    assert n == count, f"{label}: {n} != {count}"
    emit(f"\t.short\t{n}")
    cursor += 2
    return  # caller emits the remaining bytes

# ------------------------------------------------- 19. source name list 1 ---
name_list(0x872C91, 333, "ToneDB_SourceNameList1", "dir +0x50",
          ["PCM source (wave) names: Piano L/R, guitars, ... indexed by",
           "ToneDB_SourceIndexMapA/B."])

tone_index_map(0x874161, "ToneDB_SourceIndexMapA", "dir +0x44",
    "Values 0-332: indices into the 333-entry ToneDB_SourceNameList1.")
tone_index_map(0x874961, "ToneDB_SourceIndexMapB", "dir +0x48",
    "Values 223-331 only (the source list's high band).")

footer(0x875161, "ToneDB_SourceList1_Footer", "dir +0x54", "ToneDB_SourceNameList1", 333)
emit("\t.byte\t" + ", ".join(str(x) for x in rd(0x875163, 14)))
emit("\t.byte\t0x49")
cursor += 15
emit()

name_list(0x875172, 339, "ToneDB_SourceNameList2", "dir +0x64",
          ["Same list as ToneDB_SourceNameList1 plus 6 extra entries (Samba",
           "Whistle, Wind Chime, Orch.Gong, MetronomeBell, Metronome Tap, Silent)."])

tone_index_map(0x8766A2, "ToneDB_SourceIndexMapC", "dir +0x58",
    "Values 0-338: indices into the 339-entry ToneDB_SourceNameList2.")
tone_index_map(0x876EA2, "ToneDB_SourceIndexMapD", "dir +0x5C",
    "Values 228-337 only (the source list's high band).")

footer(0x8776A2, "ToneDB_SourceList2_Footer", "dir +0x68", "ToneDB_SourceNameList2", 339)
emit("\t.byte\t" + ", ".join(str(x) for x in rd(0x8776A4, 14)))
emit("\t.byte\t0x49")
cursor += 15
emit()

name_list(0x8776B3, 141, "ToneDB_PercSourceNameList1", "dir +0x8C",
          ["Synth/percussion source names (Silent, Square Wave, Rock Bass Drm, ...)",
           "indexed by ToneDB_PercSourceIndexMapA/B."])

footer(0x877F83, "ToneDB_PercList1_Footer", "dir +0x90", "ToneDB_PercSourceNameList1", 141)
emit("\t.byte\t" + ", ".join(str(x) for x in rd(0x877F85, 12)))
cursor += 12
emit()

tone_index_map(0x877F91, "ToneDB_PercSourceIndexMapB", "dir +0x4C",
    "Values 0-140: indices into the 141-entry ToneDB_PercSourceNameList1.")

name_list(0x878791, 144, "ToneDB_PercSourceNameList2", "dir +0x94",
          ["Variant of ToneDB_PercSourceNameList1 with 3 extra entries; indexed by",
           "ToneDB_PercSourceIndexMapC."])

tone_index_map(0x879091, "ToneDB_PercSourceIndexMapC", "dir +0x60",
    "Values 0-143: indices into the 144-entry ToneDB_PercSourceNameList2.")

footer(0x879891, "ToneDB_PercList2_Footer", "dir +0x98", "ToneDB_PercSourceNameList2", 144)
emit("\t.byte\t" + ", ".join(str(x) for x in rd(0x879893, 12)))
cursor += 12
emit()

name_list(0x87989F, 424, "ToneDB_DrumSourceNameList", "dir +0x80",
          ["Drum/percussion source names (Silent, Rock Bass Drm, ...); PercName_Pack",
           "entries 0-423 are 10-char abbreviations of this list, in order."])

footer(0x87B31F, "ToneDB_DrumList_Footer", "dir +0x84", "ToneDB_DrumSourceNameList", 424)
emit("\t.byte\t0x00")
cursor += 1
emit()

# ------------------------------------------------- 35. note map B ---
emit("; -----------------------------------------------------------------------------")
emit("; Drum-kit note map bank B (dir +0x7C): same 32 x 128 LE16 layout and nearly")
emit("; identical content as DrumKit_NoteMapA (slot 15 is cleared here).")
emit("DrumKit_NoteMapB:")
shortrows(0x87B322, 4096, comment_indices=False, slot_comment="note-map slot")
emit()

# ------------------------------------------------- 36. percussion name pack ---
emit("; -----------------------------------------------------------------------------")
emit("; Packed percussion-source display names (dir +0xB0): 610 x 10 chars, no")
emit("; terminators.  Entries 0-423 abbreviate ToneDB_DrumSourceNameList in order;")
emit("; entries 424+ are mostly blank with a band of sound-effect names near the")
emit("; end (Applause, Helicopter, ..., Fret Noise).  610 = PercInst record count.")
emit("PercName_Pack:")
assert cursor == 0x87D322
for i in range(610):
    emit(f'\t.ascii\t"{ascname(0x87D322 + i*10, 10)}"\t; {i}')
cursor += 6100
emit()

# ------------------------------------------------- 37. fill ---
emit("; Unused space to the end of the preset-bank area (Feature Demo data starts")
emit("; at 0x87FFF0).")
emit("ToneDB_UnusedFill:\t.fill\t5370, 1, 0xff")
assert cursor == 0x87EAF6
cursor += 5370

assert cursor == END, f"final cursor 0x{cursor:X} != 0x{END:X}"

open(OUT_PATH, "w").write("\n".join(out) + "\n")
print(f"wrote {OUT_PATH}: {len(out)} lines, covers 0x{START:X}-0x{END:X}")
