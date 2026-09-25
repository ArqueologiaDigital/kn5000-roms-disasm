#!/usr/bin/env python3
"""Spec for retype_data_objects.py: maincpu 0xEE0142-0xEE1574, the sound-parameter
(SndParam) registry and its dispatch tables -- what the tree called
NakaInst_Param_IdxA0_01, Naka_SubDispatch_A_Table, Naka_SubDispatch_B_Table and the
3,768-byte Naka_MainDispatch_Table.  Readers: audio/sndparam_routines.s (v10
addresses), found with scripts/analysis/data_readers_profile.py."""
import json

O = []


def obj(lo, hi, label, typ, header, **kw):
    d = dict(lo="0x%06X" % lo, hi="0x%06X" % hi, label=label, type=typ, header=header)
    d.update(kw)
    O.append(d)


obj(0xEE0142, 0xEE0154, "NakaInst_Param_IdxA0_01", "byte", [
    "18-byte sound-parameter descriptor -- the same record type as the 17 compiled",
    "from audio/sndparam_records/run_ee0010.c just above (0xEE0010-0xEE0141);",
    "SndParam_Registry entry 971 points at it."], per_line=9)
obj(0xEE0154, 0xEE0180, "SndParam_LinkTargetPtrs", "long", [
    "11 x u32 pointers into the 0xEDxxxx sound-parameter value tables.",
    "SndParam_RegisterLinked2_Data (0xFCE06E) and SndParam_RegisterDual_Data",
    "(0xFCE616): `lda xbc,(<this>); ld a,(xde+11); cp a,255; ... sla a,2;",
    "ld_rr8l xiy,xbc,a` -- the record's +11 byte selects the entry (0xFF = none).",
    "Legacy name Naka_SubDispatch_A_Table (= entry 1) kept as an alias."],
    alias={"Naka_SubDispatch_A_Table": 4})
obj(0xEE0180, 0xEE0198, "SndParam_RegRamPtrs", "long", [
    "6 x u32 RAM addresses (0x8EE4, 0x8EE6, 0x8EE8, 0x8EEA, 0x8EF4, 0xC1EC).",
    "SndParam_ReadRegWithLUT (0xFCD9FF): `lda xhl,(<this>); ld_rr8l xbc,xhl,c;",
    "ld c,(xbc)` -- reads the byte at the selected RAM address."])
obj(0xEE0198, 0xEE01A0, "SndParam_ValueTablePtrPair", "long", [
    "2 x u32 pointers (0xEDC89C, 0xEDC430) into the value tables.  Two readers use",
    "two bases: SndParam_CompareShifted (0xFCDA79) / SndParam_RegisterMultiField_Data",
    "(0xFCDD9B) index from +0 (`lda xbc,(<this>); ld_rr8l xbc,xbc,a`, then compare",
    "with (xbc+1)/(xbc+2)); SndParam_ReadRegWord (0xFCDAA6) and",
    "SndParam_RegisterBitfield_Data_Skip2 index from +4.  audio/sndparam_routines.s",
    "loads this address as Naka_SubDispatch_B_Table (alias kept); index ranges not",
    "traced, so whether either base reads past +8 into SndParam_Registry is open."],
    alias={"Naka_SubDispatch_B_Table": 0})
obj(0xEE01A0, 0xEE10D0, "SndParam_Registry", "long", [
    "972 x u32 pointers to sound-parameter descriptor records.  Count pinned by",
    "SndParam_RegisterAllWidgets / SndParam_RegisterLoop (0xFCEEC7): `ld xbc,xiz;",
    "sll xbc,2; ld xwa,<this>; add xwa,xbc; ld xbc,(xwa); ...; inc 1,xiz;",
    "cp xiz,972; jr c` -- every entry is registered once at start-up;",
    "SndParam_ReregisterLoop (0xFCEFBC) walks it again reading record +4/+5/+6.",
    "Legacy name Naka_MainDispatch_Table (= entry 92) kept as an alias: shared/",
    "positional_labels.s derives Naka_MainDispatch_Table_0xNN names from it."],
    alias={"Naka_MainDispatch_Table": 0x170})
HT = [(0xEE10D0, 7, "SndParam_ReadHandlers", "SndParam_RO_Dispatch", 0xFCD4C9,
       "`lda xbc,(<this>); lda_rr xbc,xbc,wa; ld xhl,(xbc); call (xhl)`"),
      (0xEE10EC, 9, "SndParam_RegisterHandlers", "SndParam_DispatchCallback", 0xFCD29A,
       "`lda xde,(<this>); lda_rr xhl,xde,bc; ld xhl,(xhl); call (xhl)`"),
      (0xEE1110, 8, "SndParam_Register2Handlers", "SndParam_Lkp2_Dispatch", 0xFCD3C8,
       "`lda xbc,(<this>); lda_rr xhl,xbc,wa; ld xhl,(xhl); call (xhl)`"),
      (0xEE1130, 6, "SndParam_EncodeHandlers", "SndParam_RW_ProcessResult", 0xFCD63F,
       "`lda xbc,(<this>); lda_rr xde,xbc,wa; ld xix,(xde); call (xix)` (also"
       " SndParam_ResolveWidget_Skip2)"),
      (0xEE1148, 6, "SndParam_WriteHandlers", "SndParam_DispatchTypeDE5", 0xFCD2F9,
       "`lda xde,(<this>); lda_rr xde,xde,bc; ld xhl,(xde); call (xhl)`")]
for lo, n, lab, rd, ra, how in HT:
    obj(lo, lo + 4 * n, lab, "long", [
        "%d x u32 routine pointers, one per record type; %s (0x%06X):" % (n, rd, ra),
        how + ".",
        "Extent: up to the next table's base (each base is loaded by its own reader)."])
obj(0xEE1160, 0xEE1560, "SndParam_BlockRamPtrs", "long", [
    "256 x u32 RAM block addresses, 0 = no block, indexed by a descriptor's +4 byte:",
    "SndParam_ReadRegField (0xFCD9C1) does `ld c,(xwa+4); sla bc,2; lda xde,(<this>);",
    "ld_rrl xde,xde,bc; or xde,xde; ret z` (20 sites in all, e.g.",
    "SndParam_DecodeMidiAddr_Skip2 0xFCD990).  Entry 0x48 is also read directly by",
    "SndParam_ClampReverbTime (0xFCE9B0) and SndParam_ClampDelayTime (0xFCEA43)",
    "(`ldl_da xwa,(<this>+0x120)`).  Entries 0-22 equal PartRecord_RamPtrTable's",
    "(0xF9B6 + 0x1A*i).  256 entries = exactly up to the string that follows."],
    per_line=4, row_index="0x%02X")
obj(0xEE1560, 0xEE1574, "SndParam_OutOfMemoryMsg", "asciz", [
    "Debug message \"Out of Memory !!!\\n\": SndParam_AllocAndInsert (0xFCEFE3) passes",
    "it in xwa (`ld xwa,<this>`) to the routine at 0xFFFEA1 when an allocation",
    "fails.  NUL + 0xFF pad."], tail=1, tail_comment="pad")

print(json.dumps({"objects": O}, indent=1))
