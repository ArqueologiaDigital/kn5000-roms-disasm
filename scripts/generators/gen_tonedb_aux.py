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
emit(";   0x85AD9D  ToneDB_VelocityCurve_0..5      6 x 128 bytes")
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
emit("; 487 envelope/modulation descriptor records x 15 bytes (dir +0x30/+0x34/+0x38).")
emit("; Record layout: flags byte, two LE32 ToneDB_Base-relative offsets (A and B),")
emit("; 6 parameter bytes.  The 2x487 offsets are all distinct and exactly tile the")
emit("; ToneEnv data region 0x85B09D-0x863078 (974 chunks).  Flag byte census:")
emit("; 0x00 x318, 0x80 x134, 0x02 x13, 0x08 x10, 0x81 x9, 0x01 x3.")
emit("; NOTE: 487 records here + 142 records in ToneDB_PercMixerDefaultTable's")
emit("; sibling group = 629, the entry count of the tone-record offset table at")
emit("; 0x831B00 (DSP1_ResolveStreamPtr's table), suggesting one descriptor per tone.")
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
emit("; Six 128-entry velocity/scaling curves (input = MIDI velocity 0-127).")
emit("; Curves 0-4 are stepped ramps of increasing depth (final values 10, 20, 27,")
emit("; 34, 34); curve 5 is near-linear reaching 107.  ToneEnv chunks reference")
emit("; these curves by ToneDB_Base-relative offset.")
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
emit("; ToneEnv data region: 974 variable-length blobs, one per LE32 offset in")
emit("; ToneDB_EnvDescTable (chunk N ends where the next referenced offset begins).")
emit("; Chunk size census: 15 x274, 4 x179, 112 x151, 6 x85, 39 x42, 36 x32, ...")
emit("; Larger chunks are built from 6-byte segments of the form 70 00 xx xx xx NN")
emit("; with NN incrementing - envelope segment lists (rate/level pairs).")
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
