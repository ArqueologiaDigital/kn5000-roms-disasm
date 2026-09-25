#!/usr/bin/env python3
"""Spec for scripts/converters/retype_data_objects.py: maincpu 0xEE8C7E-0xEEAE44
(the objects the tree called SystemConfig_PointerTable, AudioInit_VoiceDispatch_Table,
CharMap_ValueData_A/B and the first 4 bytes before SoundEffect_Dispatch_Table).

Every reader named below was read in audio/note_voice_mapping.s and
audio/audio_control_engine.s (v10); addresses are v10.  Reference sites were
found with an operand scan of `llvm-objdump -d` of the v10 ELF plus a scan of
the ROM for 32-bit data pointers (see notes/uimisc-specs/README.md).
Writes the spec JSON to stdout."""
import json

H = lambda *l: list(l)
O = []


def obj(lo, hi, label, typ, header, **kw):
    d = dict(lo="0x%06X" % lo, hi="0x%06X" % hi, label=label, type=typ, header=header)
    d.update(kw)
    O.append(d)


obj(0xEE8C7E, 0xEE8CCE, "Subsys_HandlerTableList", "long", H(
    "NULL-terminated list of 19 handler tables (19 x u32 + 0).  VoiceInit_Dispatch",
    "(0xFDDB5A) and ScreenGroup_WidgetLoop (0xFDDB7D) walk it: `ld xbc,<this>;",
    "add xbc,xwa; ld xwa,(xbc); add xwa,xde; ld xhl,(xwa); call (xhl)` -- entry i",
    "is a table of routine pointers and xde selects one routine in every table;",
    "the loop stops on the 0 entry (`or xwa,xwa`).  Legacy name kept: it is loaded",
    "by boot/screen_group_dispatch.s and is the base of shared/positional_labels.s",
    "SystemConfig_PointerTable_0x56/_0x76."),
    alias={"SystemConfig_PointerTable": 0})
obj(0xEE8CCE, 0xEE8CD4, "NoRef_Bytes_EE8CCE", "byte", H(
    "6 bytes 0,1,2,3,4,0xFF after the list's 0 terminator.  No reader: neither an",
    "instruction operand nor a 32-bit data pointer in the v10 ROM names 0xEE8CCE.",
    "Purpose not established."))
obj(0xEE8CD4, 0xEE8CF4, "Bit16Mask_Table", "short", H(
    "16 x u16 single-bit masks 1<<i (i = 0..15).  Read with `lda xix,(<this>);",
    "ld_rrw wa,xix,wa` by AudioInit_ChannelLoop_Body (0xFDF0DB) and five more",
    "AudioInit_* routines and and-ed with a channel mask (AudioInit_ChannelLoop_Body:",
    "`andda16 xwa,(0xF290)`)."),
    per_line=8)
obj(0xEE8CF4, 0xEE8D74, "AudioVoiceHandler_Table", "long", H(
    "32 x u32 routine pointers indexed by RAM byte 0x8D34.  AudioModeChange_Handler",
    "(0xFDDE1A), AudioSubsystem_Callback (0xFDDE9A), AudioVoice_Callback (0xFDDF67)",
    "and AudioVoiceReset_Handler (0xFDDFC1): `ldb_d8 a,(0x8d34); sla wa,2;",
    "lda xbc,(<this>); ld_rrl xhl,xbc,wa`, skip when the entry equals 0xFDEDEF,",
    "else `call (xhl)`.",
    "AudioInit_VoiceDispatch_Table (kept for positional_labels.s) is entry 1."),
    alias={"AudioInit_VoiceDispatch_Table": 4})
obj(0xEE8D74, 0xEE8DF4, "PartRecord_RamPtrTable", "long", H(
    "32 x u32 RAM addresses of 26-byte (0x1A) part records: 0xF9B6 + 0x1A*i for",
    "i = 0..22, then 0xFD62, 0xFD7C, then 0xF9B6 again.  UIState_ProcessMidiEvent",
    "(0xFDE084), UIStateEvt_DrumAssign_Set (0xFDE20A: `ld a,(xwa+13)`) and",
    "UIStateEvt_VolumeMixer_Data_Loop (0xFDE616: `bitm 0,(xwa+22)`) load an entry",
    "with `ld_rrl xwa,xbc,wa` and read record fields."))
obj(0xEE8DF4, 0xEE8E14, "PartIndex_ByteMap", "byte", H(
    "32 x u8, identity 0..31.  Read with `ld_rrb a,xbc,wa` by UIStateEvt_PartRouting",
    "(0xFDE0D0), UIStateEvt_VoiceAssign (0xFDE11C) and eight more UIStateEvt_*",
    "entry points before the byte is used as a part index."),
    fmt_byte="%d")
obj(0xEE8E14, 0xEE8E1C, "PartRouting_ByteTable", "byte", H(
    "8 x u8 (0,1,2,3,0,0xFD,0xFE,0xFF).  UIStateEvt_PartRouting (0xFDE0D0) reads",
    "an entry with `ld_rrb a,xbc,wa`, then `and a,7 / sla a,1`."), fmt_byte="%d", signed=True)
obj(0xEE8E1C, 0xEE8E28, "EffectSelect_StepTable", "byte", H(
    "12 x s8, -5..+6.  UIStateEvt_EffectSelect_Data_Skip2 (0xFDE723) reads an entry",
    "with `ld_rrb e,xbc,wa` (two call sites)."), fmt_byte="%d", signed=True)
obj(0xEE8E28, 0xEE8E48, "ParamEdit_WordTable", "short", H(
    "16 x u16 (0,1,2,4,0,0,0,0,0x10,0x11,0x12,0x14,0,0,0,0).  UIStateEvt_ParamEdit_Data",
    "(0xFDE2A8) and its _Entry path read it with `ld_rrw iz,xbc,wa` (12 sites)."),
    per_line=8)
obj(0xEE8E48, 0xEE8E56, "ParamEdit_SwitchOffsets", "short", H(
    "7 x u16 switch offsets.  UIStateEvt_ParamEdit_Data (0xFDE2A8): `ld_rrw wa,xix,wa;",
    "lda xix,(0xFDE2CF); jp_rr 8,xix,wa` -- targets 0xFDE2CF + offset (no labels yet)."),
    fmt_short="%d", signed=True, per_line=7)
obj(0xEE8E56, 0xEE8E62, "VolumeMixer_SwitchOffsets", "short", H(
    "6 x u16 switch offsets.  UIStateEvt_VolumeMixer_Data (0xFDE514): `ld_rrw wa,xix,wa;",
    "lda xix,(0xFDE538); jp_rr` -- targets 0xFDE538 + offset (no labels yet)."),
    fmt_short="%d", signed=True, per_line=6)
obj(0xEE8E62, 0xEE8E82, "AudioInit_ChannelMapA", "byte", H(
    "32 x u8: 0..15 then 16 x 0xFF (no mapping).  AudioInit_ConfigStereoVoice",
    "(0xFDE9AE, two sites) and AudioInit_LoadGroupVoice index it with",
    "`extz xwa; add xwa,xbc` after `lda xbc,(<this>)`."))
obj(0xEE8E82, 0xEE8EA2, "AudioInit_ChannelMapB", "byte", H(
    "32 x u8, same contents as AudioInit_ChannelMapA but a separate object:",
    "AudioInit_CheckSoundGroup51 (0xFDEC16) and AudioInit_LoadAndConfigure",
    "(0xFDECB6) read it with `ld_rrb c,xde,bc`."))
obj(0xEE8EA2, 0xEE8EB6, "AudioInit_SlotOrderMap", "byte", H(
    "20 x u8 slot map (0,2,1,7,8,9,10,11,4,5,6,3,15,0x15,0x15,0xFF,0x15,12,13,14).",
    "Read with `ld_rrb a,xix,wa` at 18 sites: AudioInit_ChannelLoop_Body (0xFDF0DB),",
    "AudioInit_CheckGroupA/B, AudioInit_GroupA/B_* and HdaeRom_AltCheckResult."))
obj(0xEE8EB6, 0xEE8EB8, "NoteMap_LinkByte_Table", "byte", H(
    "2 x u8 (0x21, 0x22).  NoteMap_AssignAllVoiceLinks (0xFE1D3C), LinkVoiceSlots_Block,",
    "NoteMap_LookupAndMergeVoice and Voice_LookupTableEntries read it with",
    "`ld_rrb a,xbc,wa` / `lda xhl,(<this>)`."))
obj(0xEE8EB8, 0xEE8ED8, "NoteMap_ByteMap_81", "byte", H(
    "32 x u8, 0x81..0xA0.  NoteMap_AllocNewVoiceEntry (0xFE4C0D), NoteMap_SetChannelParam",
    "and SndParam_UpdateChannelTuning read it with `ld_rrb a,xbc,wa`; it is also",
    "the +8 map pointer of NoteMap_ChannelMapRecords 0-3.  Legacy name",
    "CharMap_ValueData_A kept (audio/note_voice_mapping.s loads it)."),
    alias={"CharMap_ValueData_A": 0})
obj(0xEE8ED8, 0xEE8EE8, "NoteMap_ByteMap_21", "byte", H(
    "16 x u8 (0x21..0x24, 4 x 0xFF, 0,1,2,0x15, 4 x 0xFF).  NoteMap_FindEntry (0xFE5567)",
    "reads it with `ld_rrb a,xbc,wa`; +8 map pointer of NoteMap_ChannelMapRecords 4.",
    "Legacy name CharMap_ValueData_B kept: shared/positional_labels.s derives 32",
    "names (CharMap_ValueData_B_0xNN) from it that other files use."),
    alias={"CharMap_ValueData_B": 0})
obj(0xEE8EE8, 0xEE8EEC, "AccNoteOn_FrameTemplateA", "byte", H(
    "4-byte template (0x7F,0xA8,0xFE,0x00): AccNoteOn_ProcessVoiceSetup (0xFE06E7)",
    "copies it into its frame at (xsp+10) with `ld xiy,<this>` + two `ldiw`."))
obj(0xEE8EEC, 0xEE8EF0, "AccNoteOn_FrameTemplateB", "byte", H(
    "4-byte template (0x53,0x00,0xFE,0x00): AccNoteOn_ProcessVoiceSetup copies it to",
    "(xsp+6) right after AccNoteOn_FrameTemplateA, the same way."))
obj(0xEE8EF0, 0xEE8EF8, "RhythmMidi_StatusMap", "byte", H(
    "8 x u8 (0x10..0x14, 3 x 0xFF).  RhythmMidi_DispatchByStatus (0xFE0B40) and the",
    "RhythmMidi_CC7D/7F/Default/Standard/PostLoop paths read it with `ld_rrb a,xbc,wa`."))
obj(0xEE8EF8, 0xEE8EFE, "RhythmMidi_FrameTemplate", "byte", H(
    "5-byte zero template + 0xFF.  RhythmMidi_Dispatcher (0xFE0B06): `ld xiy,<this>;",
    "lda xix,(xsp+6); ld bc,2; ldirw; ldi85` copies the first 5 bytes into its frame."))
obj(0xEE8EFE, 0xEE8F06, "RhythmMidi_SeqEvtMap", "byte", H(
    "8 x u8 (0x17, 0x18, 6 x 0xFF).  RhythmMidi_SeqEvt_Dispatch (0xFE0D7F) reads it",
    "with `ld_rrb e,xbc,wa` (5 sites)."))
obj(0xEE8F06, 0xEE8F22, "VoiceEvent_SwitchOffsets", "short", H(
    "14 x u16 switch offsets.  VoiceEvent_TypeDispatch (0xFE131B): `ld_rrw wa,xix,wa;",
    "lda xix,(0xFE127D); jp_rr` -- targets 0xFE127D + offset (no labels yet)."),
    fmt_short="%d", signed=True, per_line=7)
obj(0xEE8F22, 0xEE8F2E, "NoteMap_VoiceSlotRamPtrs", "long", H(
    "3 x u32 RAM addresses (0xCF5F, 0xCF77, 0xCE66).  NoteMap_InitVoiceSlots (0xFE3D2A)",
    "and a NoteMap_* sibling: `sla wa,2; lda xbc,(<this>)`, a 32-bit indexed load",
    "(`ld_sril3`) into xiz, then `cpw (xiz),0`."))
obj(0xEE8F2E, 0xEE8F70, "NoteMap_ChannelMapRecords", "struct", H(
    "5 records x 13 bytes {+0 u32 RAM ptr, +4 u32 RAM ptr, +8 u32 byte-map ptr,",
    "+12 u8 flags} + one 0xFF pad.  LookupTableEntries_Prologue (0xFE43E4) scales",
    "the index with `muls hl,0xd` and reads +0/+4/+8 through positional names",
    "CharMap_ValueData_B_0x56/_0x5A/_0x5E (= this+0/+4/+8); the +8 map is then",
    "indexed with `ldb_sri`.  Flags: 0x80 x4, 0x20."),
    fields=[4, 4, 4, 1], count=5, tail=1, tail_comment="pad", record_comment="record %d")
obj(0xEE8F70, 0xEE8F78, "SetChannelParam_ByteMap", "byte", H(
    "8 x u8 (0,1,2,3,0,0,0,0xFF).  SetChannelParam_LoadParam (0xFE4F49),",
    "_LoadDRAM and _LoadDRAM2: `ld wa,(ram); extz xwa; ld xbc,<this>; add xbc,xwa;",
    "ld a,(xbc)` with the index from RAM 0xCF01 / 0xCF31 / 0xCE24."))
obj(0xEE8F78, 0xEE8F80, "NoteOn_ChannelByVoice", "byte", H(
    "8 x u8 (0,8,0,0,0,0,0,0xFF).  BuildNoteOn_VoiceLoop (0xFE5228): `ld_rrb a,xde,wa;",
    "or a,0x90` -- the byte is the MIDI channel of a Note-On status."))
obj(0xEE8F80, 0xEE8F9A, "NoteThreshold_PairTable", "byte", H(
    "13 x {u8, u8}.  MarkEntriesAboveThre_LoadParam (0xFE5938): `sub a,0x54; add wa,wa;",
    "lda xbc,(<this>)` / `(<this>+1)`; `ldb_sri` -- one pair per value 0x54..0x60",
    "of the byte it indexes with (13 pairs to the next referenced object)."),
    per_line=2)
obj(0xEE8F9A, 0xEE8FA4, "Rhythm_EventMapA", "byte", H(
    "10 x u8 (4 x 0xFF, 0x10..0x14, 0xFF).  Rhythm_ProcessEventDispatch (0xFE8433)",
    "reads it with `ld_rrb a,xbc,wa` (2 sites)."))
obj(0xEE8FA4, 0xEE8FAE, "Rhythm_EventMapB", "byte", H(
    "10 x u8 (0xFF, 0x17, 0x18, 7 x 0xFF).  NonNoteDispatchLoop_ReadAlt (0xFE8800)",
    "reads it with `ld_rrb a,xbc,wa` (2 sites)."))
obj(0xEE8FAE, 0xEE8FC0, "RhythmBuf_SwitchOffsets", "short", H(
    "9 x u16 switch offsets.  RhythmBuf_EventDispatchLoop (0xFE83DD): `ld_rrw wa,xix,wa;",
    "lda xix,(0xFE8633); jp_rr` -- targets 0xFE8633 + offset (no labels yet)."),
    fmt_short="%d", signed=True, per_line=9)
obj(0xEE8FC0, 0xEE8FCE, "SeqEvtBuf_SwitchOffsets", "short", H(
    "7 x u16 switch offsets.  SeqEvtBuf_NoteDispatch (0xFE894D): `ld_rrw wa,xix,wa;",
    "lda xix,(0xFE8BA8); jp_rr` -- targets 0xFE8BA8 + offset (no labels yet)."),
    fmt_short="%d", signed=True, per_line=7)

HARM = [  # lo, hi, label, voices, handler, handler address
    (0xEE8FCE, 0xEE911E, "Harmony_Offsets1_A", 1, "SoundFX_Handler_2", 0xFE8E38),
    (0xEE911E, 0xEE93BE, "Harmony_Offsets2", 2, "SoundFX_Handler_4", 0xFE8F0A),
    (0xEE93BE, 0xEE98FE, "Harmony_Offsets4_A", 4, "SoundFX_Handler_6", 0xFE9075),
    (0xEE98FE, 0xEE9A4E, "Harmony_Offsets1_B", 1, "SoundFX_Handler_3", 0xFE8EA1),
    (0xEE9A4E, 0xEE9E3E, "Harmony_Offsets3_A", 3, "SoundFX_Handler_5", 0xFE8FA5),
    (0xEE9E3E, 0xEEA22E, "Harmony_Offsets3_B", 3, "SoundFX_Handler_7", 0xFE9171),
]
for lo, hi, lab, k, h, ha in HARM:
    assert hi - lo == 28 * 12 * k, lab
    obj(lo, hi, lab, "byte", H(
        "28 rows x 12 columns x %d byte%s = %d bytes.  %s (0x%06X): row = RAM byte"
        % (k, "s" if k > 1 else "", hi - lo, h, ha),
        "0xCEDF - 1 (`muls wa,0x%x`), column = (0xCEAA - 0xCEE0 + VoiceBank_MapNoteToOffset"
        % (12 * k),
        "+ 1) mod 12 (`div a,0xc`)%s; each byte is subtracted from RAM 0xCEAA and the"
        % (", x%d" % k if k > 1 else ""),
        "result stored at (xiz+5)%s.  28 rows pinned: every table here is exactly"
        % ("".join(", +%d" % (5 + 2 * j) for j in range(1, k)) if k > 1 else ""),
        "28 x 12 x k up to the next referenced one.  [INFERENCE] harmony notes below",
        "the melody note per chord row; UIParam_CallbackDispatch selects %s." % h),
        per_line=12 * k if k <= 2 else 12)
obj(0xEEA22E, 0xEEA8BE, "NoRef_HarmonyLike_EEA22E", "byte", H(
    "1680 bytes that group as 3-byte note offsets like Harmony_Offsets3_A/B, but",
    "1680 is not a multiple of their 36-byte row.  No reader: no instruction",
    "operand, positional name or 32-bit data pointer in the v10 ROM names any",
    "address in it, and SoundFX_Handler_7 (the last 36-byte-row reader) only",
    "reaches its own 1008 bytes.  Purpose not established."),
    per_line=12)
obj(0xEEA8BE, 0xEEADFE, "Harmony_Offsets4_B", "byte", H(
    "28 rows x 12 columns x 4 bytes = 1344 bytes.  SoundFX_Handler_8 (0xFE9241): row =",
    "RAM byte 0xCEDF - 1 (`muls wa,0x30`), column x4 (`sla de,2`); the four bytes",
    "(`ldb_sri`, `ld c,(xwa+1..3)`) are subtracted from RAM 0xCEAA like the tables",
    "above.  UIParam_CallbackDispatch selects SoundFX_Handler_8."),
    per_line=12)
obj(0xEEADFE, 0xEEAE04, "Harmony_FixedIntervals", "byte", H(
    "6 x s8 (-12, 12, 5, 12, -10, -5), read one at a time with `ldb_da e,(addr)`",
    "and subtracted from RAM 0xCEAA: SoundFX_Handler_9 (0xFE933D) uses +0/+1,",
    "SoundFX_Handler_10 (0xFE9360) +2/+3, SoundFX_Handler_11 (0xFE9383) +4/+5."),
    fmt_byte="%d", signed=True)

obj(0xEEAE04, 0xEEAE44, "Harmony_HandlerTable", "long", H(
    "16 x u32 routine pointers, indexed by RAM byte 0xE9BE: UIParam_CallbackDispatch",
    "(0xFE8C1B) does `ld c,(0xe9be); sla bc,2; lda xde,(<this>); add xbc,xde;",
    "ld xix,(xbc); call (xix)`.  Entry 0 is NoteMap_SearchVoiceEntry, entries 1-13",
    "SoundFX_Handler_0..12 (the readers of the Harmony_* tables above), 14-15 repeat",
    "SoundFX_Handler_6.  Extent pinned by the next referenced object (0xEEAE44).",
    "Legacy name SoundEffect_Dispatch_Table (= entry 1) kept: shared/",
    "positional_labels.s derives 36 SoundEffect_Dispatch_Table_0xNN names from it."),
    alias={"SoundEffect_Dispatch_Table": 4})

spec = {"renames": {"CharMap_ValueData_A": "NoteMap_ByteMap_81",
                    "CharMap_ValueData_B": "NoteMap_ByteMap_21"},
        "objects": O}
print(json.dumps(spec, indent=1))
