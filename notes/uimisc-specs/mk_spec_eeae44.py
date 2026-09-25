#!/usr/bin/env python3
"""Spec for retype_data_objects.py: maincpu 0xEEAE44-0xEEC288 (what the tree
covered with SoundEffect_Dispatch_Table and 36 positional
SoundEffect_Dispatch_Table_0xNN names).  Readers: audio/note_voice_mapping.s,
midi/*, sequencer/* (v10 addresses).  Found with
scripts/analysis/data_readers_profile.py and data_pointer_scan.py."""
import json

O = []


def obj(lo, hi, label, typ, header, **kw):
    d = dict(lo="0x%06X" % lo, hi="0x%06X" % hi, label=label, type=typ, header=header)
    d.update(kw)
    O.append(d)


def switch(lo, n, label, reader, raddr, base):
    obj(lo, lo + 2 * n, label, "short", [
        "%d x s16 switch offsets.  %s (0x%06X): `ld_rrw wa,xix,wa;" % (n, reader, raddr),
        "lda xix,(0x%06X); jp_rr 8,xix,wa` -- targets 0x%06X + offset (no labels yet)."
        % (base, base)], fmt_short="%d", signed=True, per_line=8)


obj(0xEEAE44, 0xEEBE44, "ChordRecog_IntervalMaskTable", "byte", [
    "2048 x {u8, u8}, indexed by an 11-bit interval mask.  Voice_ComputeNoteBitPosition",
    "(0xFE981C) sets one bit per held note relative to the lowest one and ORs in",
    "0x800; Voice_LookupNoteAndComputePitch (0xFE9D91), LookupNoteAndCompute_Prologue",
    "(0xFE9DCE), NoteDisplay_ScanLoop (0xFE9E36) and NoteDisplay_AlternateLookup",
    "(0xFE9E91) then do `and hl,0x7ff; sla hl,1; ld xiz,<this>; add xiz,xhl;",
    "ld a,(xiz); ld w,(xiz+1)`: +0 = code (0 = no match, the scan then tries the",
    "next lowest note), +1 = bit 7 flag, bits 0-6 value (`and w,0x7f`).",
    "4096 bytes = 2048 x 2 exactly up to the next referenced object.",
    "[INFERENCE] the fingered-chord recognition table (chord type, root offset)."],
    per_line=16)
obj(0xEEBE44, 0xEEC044, "NoteMask9_ClassTable", "byte", [
    "512 x u8, indexed by a 9-bit mask: ComputeNoteBitPositi_Block (0xFE98C3) and",
    "ComputeNoteBitPositi_TestBit9 (0xFE98E3) do `and hl,511; ld xiz,<this>;",
    "ld_rrb a,xiz,hl` and branch on the value (0, 1, 5 ...); Voice_UpdateNoteBitmap",
    "(0xFE99DE) and VoiceSlot_LoadResult_Data (0xFE9A11) load the same base.",
    "512 bytes exactly up to the next referenced object."], per_line=16)
switch(0xEEC044, 13, "KeyEvent_SwitchOffsets", "UIState_ProcessKeyEvent", 0xFEA812, 0xFEA84F)
switch(0xEEC05E, 8, "HdaeRomEntry2_SwitchOffsets", "HdaeRom_TableEntry2", 0xFEABD9, 0xFEAC14)
switch(0xEEC06E, 15, "SendEpilogueA_SwitchOffsets", "SendEpilogue_Data_Skip14", 0xFEB4C6, 0xFEB4EE)
switch(0xEEC08C, 7, "SendEpilogueB_SwitchOffsets", "SendEpilogue_Data_Skip7", 0xFEB3DC, 0xFEB40D)
TUNE = [(0xEEC09A, "A"), (0xEEC0A6, "B"), (0xEEC0B2, "C"), (0xEEC0BE, "D")]
first = True
for a, s in TUNE:
    obj(a, a + 12, "SemitoneBias_Table%s" % s, "byte", ([
        "12-byte per-semitone tables (one byte per pitch class C..B; 0x80 = centre).",
        "SeqVoice_CheckAndRet_Data (0xFEBC56) maps its selector byte (0x80, 5, 4, 3,",
        "0x40-0x42, 0, 0x10-0x16 through SeqVoiceSel_SwitchOffsets) to one of them",
        "and returns its address in xhl (`lda_24 xhl,(table)` at 14 case labels;",
        "the 15th returns RAM 0xFD1E).  [INFERENCE] scale-tuning presets."] if first else
        ["12 x u8 semitone table (one byte per pitch class, 0x80 centre): a",
         "SeqVoice_CheckAndRet_Data (0xFEBC56) case returns it (`lda_24 xhl,(<this>)`)."]))
    first = False
obj(0xEEC0CA, 0xEEC0E2, "NoRef_SemitoneBias_EEC0CA", "byte", [
    "24 bytes shaped like two more 12-byte semitone tables, but no reader: no",
    "instruction operand and no 32-bit data pointer in the v10 ROM names",
    "0xEEC0CA..0xEEC0E1.  Purpose not established."], per_line=12)
for a, s in [(0xEEC0E2, "E"), (0xEEC0EE, "F"), (0xEEC0FA, "G"), (0xEEC106, "H"), (0xEEC112, "I"),
             (0xEEC11E, "J"), (0xEEC12A, "K"), (0xEEC136, "L"), (0xEEC142, "M"), (0xEEC14E, "N")]:
    obj(a, a + 12, "SemitoneBias_Table%s" % s, "byte",
        ["12 x u8 semitone table (one byte per pitch class, 0x80 centre): a",
         "SeqVoice_CheckAndRet_Data (0xFEBC56) case returns it (`lda_24 xhl,(<this>)`)."])
switch(0xEEC15A, 7, "SeqVoiceSel_SwitchOffsets", "SeqVoice_CheckAndRet_Data", 0xFEBC56, 0xFEBCA0)
switch(0xEEC168, 7, "SendEpilogueC_SwitchOffsets", "SendEpilogue_Data_Helper", 0xFEBD0E, 0xFEBD57)
switch(0xEEC176, 9, "ChannelData_SwitchOffsets", "MIDI_WriteChannelData_Block", 0xFEBF1D, 0xFEBF45)
obj(0xEEC188, 0xEEC1A8, "SendPacket_BitMaskTemplateA", "short", [
    "16 x u16 1<<i template: MIDI_SendSinglePacket (0xFEC505) copies it into its",
    "frame with `ld xiy,<this>; lda xix,(xsp+4); ldw bc,16; ldirw`."], per_line=8)
obj(0xEEC1A8, 0xEEC1C8, "SendPacket_BitMaskTemplateB", "short", [
    "Same 16 x u16 1<<i contents, a separate copy: SendSinglePacket_Data (0xFEC57A)",
    "copies it the same way (`ldw bc,16; ldirw`)."], per_line=8)
obj(0xEEC1C8, 0xEEC1CE, "Smf_ChunkId_MThd", "asciz", [
    "Standard MIDI File header chunk id: SendSinglePacket_WriteReg (0xFEC5D6) copies",
    "the 4 bytes (`ld bc,2; ldirw`) into its frame at (xsp+136).  NUL + 0xFF pad."],
    tail=1, tail_comment="pad")
obj(0xEEC1CE, 0xEEC1D4, "Smf_ChunkId_MTrk", "asciz", [
    "Standard MIDI File track chunk id: SendSinglePacket_WriteReg copies these 4",
    "bytes to (xsp+130) the same way.  NUL + 0xFF pad."], tail=1, tail_comment="pad")
obj(0xEEC1D4, 0xEEC1DE, "SeekRecord_ZeroTemplate", "byte", [
    "10 zero bytes: SeekRecord_PopReturn_Prologue (0xFECB8F) copies them into its",
    "frame with `ld xiy,<this>; ld bc,5; ldirw`."], per_line=10)
obj(0xEEC1DE, 0xEEC1E8, "ESeq_FileSignature", "asciz", [
    "File signature \"COM-ESEQ\": SeqPlay_ReadFileRecord (0xFED0A8) copies its 8",
    "bytes into its frame (`ld bc,4; ldirw`) to compare with a file header.",
    "NUL + 0xFF pad."], tail=1, tail_comment="pad")
switch(0xEEC1E8, 16, "MidiSysMsg_SwitchOffsets", "MidiSysMsg_Handler", 0xFED63B, 0xFED772)
for i, a in enumerate(range(0xEEC208, 0xEEC268, 16)):
    obj(a, a + 16, "SoundParam_DefaultBankMap%d" % i, "byte", ([
        "Six 16-byte slot maps (permutations of 0..0x13): SoundParam_InitDefaultBanks",
        "(0xFEDDA2) copies each into its frame (`ld xiy,<map>; lda xix,(xsp+82/66/",
        "50/34/18/2); ldw bc,8; ldirw`)."] if i == 0 else
        ["16-byte slot map %d (a permutation of 0..0x13), copied into a frame slot by" % i,
         "SoundParam_InitDefaultBanks (0xFEDDA2) with `ldw bc,8; ldirw`."]),
        per_line=16)
obj(0xEEC268, 0xEEC288, "Disk_DefaultPath", "byte", [
    "32-byte path buffer template \"A:\\\" + 29 NULs: NotifyChangeComplete_Prologue",
    "(0xFEDF6D) copies it into its frame (`ld xiy,<this>; ld xix,xsp; ldw bc,16;",
    "ldirw`)."], per_line=16)

print(json.dumps({"objects": O}, indent=1))
