#!/usr/bin/env python3
"""Spec for retype_data_objects.py: maincpu 0xEED118-0xEEDD35 -- what the tree
covered with CharMap_FullPermutation (v7: the romslice
v7_data_charmap_fullpermutation.bin) and ~40 positional
CharMap_FullPermutation_0xNN names.  Readers named per object (v10)."""
import json

O = []


def obj(lo, hi, label, typ, header, **kw):
    d = dict(lo="0x%06X" % lo, hi="0x%06X" % hi, label=label, type=typ, header=header)
    d.update(kw)
    O.append(d)


def switch(lo, n, label, reader, raddr, base, tail=0):
    obj(lo, lo + 2 * n + tail, label, "short", [
        "%d x s16 switch offsets.  %s (0x%06X): `ld_rrw ..,xix,..; lda xix,(0x%06X);"
        % (n, reader, raddr, base),
        "jp_rr 8,xix,..` -- targets 0x%06X + offset (no labels yet)." % base],
        fmt_short="%d", signed=True, per_line=8,
        **({"tail": tail, "tail_comment": "pad"} if tail else {}))


def bytemap(lo, hi, label, lines, **kw):
    obj(lo, hi, label, "byte", lines, per_line=16, **kw)


bytemap(0xEED118, 0xEED198, "CharMap_FullPermutation", [
    "128-byte permutation of 0..127: entry 11 of CharMap_ModeDispatchTable",
    "(ui/charmap_dispatch_table.s).  That 42-entry table's reader is not in any",
    "instruction operand; CharMap_ActivePreamb_Prologue (note_voice_mapping.s)",
    "indexes a 128-byte map through a RAM pointer (0xE14E)+0x3C..0x4C, which is",
    "consistent with it but was not traced to this table."])
bytemap(0xEED198, 0xEED218, "NoteMap_ConvergeMapA", [
    "128 x u8 (0xFF = unmapped).  LoadTableConverge_LoadReg (0xFEEB3F) and",
    "LookupTableConverge_LoadReg (0xFEEBC4): `ld xwa,<this>; ld_rrb l,xwa,de`."])
bytemap(0xEED218, 0xEED298, "NoteMap_ConvergeMapB", [
    "128 x u8 (0xFF = unmapped).  LoadTableConverge_LoadReg2 (0xFEEB46) and",
    "LookupTableConverge_LoadReg2: `ld xwa,<this>; ld_rrb l,xwa,de`."])
obj(0xEED298, 0xEED2A8, "Msg_WrongSwNumber", "byte", [
    "Text \"WRONG SW NUMBER!\" (16 bytes, no NUL): StoreDRAMInit_Block4 (0xFEE635)",
    "copies from <this> to <this>+16 (`lda xwa,(<this>); lda xhl,(xwa+16)`)."],
    per_line=16)
obj(0xEED2A8, 0xEED2B9, "Msg_SoundNameError", "asciz", [
    "Text \"Sound Name Error\": SndParam_ApplyProgramChangeAsync (0xFEE64A) copies",
    "<this>..<this>+17 (`lda xhl,(xwa+17)`)."])
obj(0xEED2B9, 0xEED2C6, "Msg_SNameError", "byte", [
    "Text \"SName Error!!\" (13 bytes, no NUL): ApplyProgramChangeAs_Prologue2",
    "(0xFEE712) copies from <this> (`lda xwa,(<this>); lda xhl,(xwa+10)`)."], per_line=13)
bytemap(0xEED2C6, 0xEED346, "NoRef_ExpCurve128", [
    "128 x u8 rising curve 1..0x7F (slow start, fast end).  No reader: no",
    "instruction operand and no 32-bit data pointer in the v10 ROM names it."],
    fmt_byte="%d")
bytemap(0xEED346, 0xEED3C6, "SndParam_LogCurve128", [
    "128 x u8 rising curve 0..0x7F (fast start).  SndParam_CompactLookupStub",
    "(0xFEEA13): `lda xbc,(<this>); ld_rrb a,xbc,wa; extz wa; ld l,a; ret`."],
    fmt_byte="%d")
switch(0xEED3C6, 6, "SndParamChan_SwitchOffsets", "SndParam_LookupByChannel", 0xFEEAC7, 0xFEEB06)
switch(0xEED3D2, 6, "SndParamOffs_SwitchOffsets", "SndParam_OffsetHandler", 0xFEEB59, 0xFEEB97)
obj(0xEED3DE, 0xEED3EE, "Subsys_HandlerTable11", "long", [
    "4 x u32 routine pointers: entry 11 of Subsys_HandlerTableList, so",
    "VoiceInit_Dispatch calls one entry of it with every subsystem's table.",
    "(kn5000_v10_program.s also names this address CharMap_PermutationPtrTable_A",
    "as an absolute .set; it is not a permutation table.)"])
obj(0xEED3EE, 0xEED43B, "ParamSx_CaseMapA", "byte", [
    "77 x u8 case numbers 0..6.  Param_SignExtendReturn_Skip3 (0xFEED58):",
    "`add xbc,<this>; ld bc,(xbc); extz bc; sll bc,1; ld xix,<ParamSx_SwitchA>;",
    "ld_rrw ..; jp` -- a two-level switch: this byte, then the offset table."])
switch(0xEED43B, 7, "ParamSx_SwitchA", "Param_SignExtendReturn_Skip3", 0xFEED58, 0xFEED91)
obj(0xEED449, 0xEED496, "ParamSx_CaseMapB", "byte", [
    "77 x u8 case numbers 0..6.  Param_SignExtendReturn_Skip (0xFEEC96), same",
    "two-level switch as ParamSx_CaseMapA with ParamSx_SwitchB."])
switch(0xEED496, 7, "ParamSx_SwitchB", "Param_SignExtendReturn_Skip", 0xFEEC96, 0xFEECDA)
obj(0xEED4A4, 0xEED4B8, "ParamSx_SwitchC", "short", [
    "10 x s16 offsets.  Param_SignExtendReturn_Helper3 (0xFEEC48): `add xhl,<this>;",
    "ld hl,(xhl); lda xix,(0xFEEC84); jp_rr` -- targets 0xFEEC84 + offset."],
    fmt_short="%d", signed=True, per_line=10)
obj(0xEED4B8, 0xEED4CF, "ParamSx_CaseMapD", "byte", [
    "23 x u8 case numbers 0..2.  Param_SignExtendReturn_Skip10 (0xFEEF73): byte,",
    "then ParamSx_SwitchD."], per_line=23)
switch(0xEED4CF, 3, "ParamSx_SwitchD", "Param_SignExtendReturn_Skip10", 0xFEEF73, 0xFEEFAA)
obj(0xEED4D5, 0xEED4FE, "ParamSx_CaseMapE", "byte", [
    "41 x u8 case numbers 0..6.  Param_SignExtendReturn_Skip7 (0xFEEEB2): byte,",
    "then ParamSx_SwitchE."], per_line=21)
switch(0xEED4FE, 7, "ParamSx_SwitchE", "Param_SignExtendReturn_Skip7", 0xFEEEB2, 0xFEEEEB)
obj(0xEED50C, 0xEED520, "ParamSx_SwitchF", "short", [
    "10 x s16 offsets.  Param_SignExtendReturn_Skip5 (0xFEEE0B): `add xhl,<this>;",
    "ld hl,(xhl); lda xix,(0xFEEE7F); jp_rr` -- targets 0xFEEE7F + offset."],
    fmt_short="%d", signed=True, per_line=10)
obj(0xEED520, 0xEED52B, "TmFlash_ByteMap", "byte", [
    "11 x u8 (0,2,4,5,3,0,1,1,4,2,3).  TmFlash_Return_Prologue (0xFEF507):",
    "`ld xbc,<this>; add xbc,xwa; ld a,(xbc)`."], fmt_byte="%d", per_line=11)
obj(0xEED52B, 0xEED53B, "Subsys_HandlerTable01", "long", [
    "4 x u32 routine pointers: entry 1 of Subsys_HandlerTableList (see",
    "Subsys_HandlerTable11; kn5000_v10_program.s's absolute .set",
    "CharMap_PermutationPtrTable_B names the same address)."])
for lo, hi, lab, rd, ra, txt in [
        (0xEED53B, 0xEED542, "SoundRam_Id_KN2000", "SendPartDataBlock_InitVal7", 0xFF01AC, "KN2000"),
        (0xEED542, 0xEED546, "SoundRam_Id_MKA", "SendPartDataBlock_InitVal8", 0xFF01D8, "MKA"),
        (0xEED546, 0xEED54A, "SoundRam_Id_MKB", "SendPartDataBlock_InitVal9", 0xFF0204, "MKB"),
        (0xEED54A, 0xEED55B, "SoundRam_Id_KN3000", "SendPartDataBlock_InitVal6", 0xFF0182, "KN3000 SOUND RAM"),
        (0xEED55B, 0xEED56C, "SoundRam_Id_KN1500", "SendPartDataBlock_InitVal5", 0xFF0158, "KN1500 SOUND RAM"),
        (0xEED56C, 0xEED57D, "SoundRam_Id_KN5000", "SendPartDataBlock_ClearByte4", 0xFEF950, "KN5000 SOUND RAM")]:
    obj(lo, hi, lab, "asciz", [
        "Sound-RAM data identifier \"%s\": %s (0x%06X)" % (txt, rd, ra),
        "loads it (`lda_24 xhl,(<this>)`) and compares/copies it byte by byte."])
obj(0xEED57D, 0xEED58D, "SoundRam_HandlerTable", "long", [
    "4 x u32 routine pointers: entry 16 of Subsys_HandlerTableList (VoiceInit_Dispatch",
    "calls one entry of it with every subsystem's table)."])
obj(0xEED58D, 0xEED59D, "HdaeRom_DataByteMap", "byte", [
    "16 x u8.  HdaeRom_DataHandler_Helper (0xFEFC28): `lda xhl,(<this>);",
    "ld_rrb c,xhl,bc`."], fmt_byte="%d")
RF = ["** RE-FRAMED 2026-08-30 (lane B4). Was a 48-byte CODE island sitting between",
      "a `.byte` run and a `.zero 232` in a zone that is otherwise pure data. The",
      "record at 0xEED642 repeats, byte for byte, the shape the tree ALREADY spells",
      "as data at 0xEED60C: `1e 00 1e 00 1e 00 1e 00 00 00 42 00 00 00`. The tree",
      "framed that repeat as two `calr 7680`, which is how run 8 of the reachability",
      "work list (0xEEF445) got a STRONG `branch` seed -- from a constant."]
obj(0xEED59D, 0xEED747, "SoundRam_DefaultRecord", "byte", [
    "426-byte default record (213 words) beginning with the 16-character name",
    "\"    Initial     \": SendPartDataBlock_Return5_Helper (0xFEFD28) copies it",
    "into its frame (`ld xiy,<this>; ld xix,xsp; ldw bc,213; ldirw`)."], per_line=16,
    anchors={"0xEED628": {"before": RF, "eol": "|...d<dPd(..B....|"},
             "0xEED638": {"eol": "|.a..B...........|"},
             "0xEED648": {"eol": "|....B...`.@.....|"},
             "0xEED658": {}},
    drop_comments=RF + ["|...d<dPd(..B....|", "|.a..B...........|", "|....B...`.@.....|"])
switch(0xEED747, 6, "HdaeRomData_SwitchOffsets", "HdaeRom_DataHandler", 0xFF024E, 0xFF028F)
switch(0xEED753, 6, "HdaeRomAlt_SwitchOffsets", "HdaeRom_AltHandler", 0xFF0445, 0xFF0470)
switch(0xEED75F, 6, "TmFlashBulkA_SwitchOffsets", "TmFlash_BulkTransferToSubCPU_Skip2", 0xFF07A8, 0xFF07FB)
switch(0xEED76B, 6, "TmFlashBulkB_SwitchOffsets", "TmFlash_BulkTransferToSubCPU_Epilogue2", 0xFF086C,
       0xFF08A9, tail=1)
bytemap(0xEED778, 0xEED878, "CType_ClassTable", [
    "256-entry character-class table in the C-library <ctype.h> layout: 0x01 upper,",
    "0x02 lower, 0x04 digit, 0x08 space, 0x10 punct, 0x20 control, 0x40 blank,",
    "0x80 hex (e.g. 'A' = 0x81, 'a' = 0x82, '0' = 0x84, ' ' = 0x48).",
    "FileOpen_NormalizeName (0xF4EC45) and 14 more sites: `lda xbc,(<this>);",
    "ld_rrb a,xbc,wa; bit 1,a` (islower) and similar bit tests."])
switch(0xEED878, 22, "Sprintf_TypeSwitch", "Sprintf_DispatchType", 0xFF11F4, 0xFF1237)
obj(0xEED8A4, 0xEED8B6, "Sprintf_HexDigitsLower", "asciz", [
    "\"0123456789abcdef\" + pad: Sprintf_HexToStr (0xFF19C2) uses it for %x",
    "(`ld xwa,<this>`; `cpw (xsp+12),120` picks the table)."], tail=1, tail_comment="pad")
obj(0xEED8B6, 0xEED8C8, "Sprintf_HexDigitsUpper", "asciz", [
    "\"0123456789ABCDEF\" + pad: Sprintf_HexToStr uses it for %X."], tail=1, tail_comment="pad")
obj(0xEED8C8, 0xEEDD36, "WorkRamInit_Image", "byte", [
    "ROM image of initialised RAM: Boot_InitWorkRAM_ROMCopy1_Start (0xEF0BB0) copies",
    "8,606 bytes from here to RAM 0x3D524 (`ld xde,0x3D524; ld xhl,<this>;",
    "ld xbc,8606; ldir`) -- so byte <this>+k is the power-on value of RAM",
    "0x3D524+k.  The image runs on through the RamInit_* tables and into",
    "ui_widgets/sequencer_channel_containers.s (to 0xEEFA65).  The code reads",
    "the RAM copy, not these bytes: RAM 0x3D528 / 0x3D52C are Heap_Alloc's and",
    "Free's variables; 213 more cells up to 0x3D991 are named by 32-bit pointers",
    "in the NAKA widget descriptors (GUI_FormatStrings, GUI_DisplayStructData,",
    "NAKA_PerfReg_Container_Root, NakaNode_* ...), i.e. per-widget state.",
    "Each line's comment gives the RAM address of its first byte.  The three",
    "0x00FF0000 words at 0xEEDBE8/0xEEDCA0/0xEEDCE8 were typed as `.long` pointers",
    "to SendPartDataBlock_Data2; that label is 0xFF0000 in v10, 0xFEFFF5 in v9 and",
    "0xFEFC40 in v7 while these bytes are identical in all three, so they are",
    "not pointers."],
    per_line=16, row_ram="0x3D524",
    drop_comments=["SendPartDataBlock_Data2 (widget descriptor pointer)"])

print(json.dumps({"objects": O}, indent=1))
