#!/usr/bin/env python3
"""Spec for retype_data_objects.py: maincpu 0xEE49E8-0xEE4FC5 -- the MIDI control
records and the tables that select and dispatch them (what the tree called
ToneKit_FrequencyTable, WidgetParam_SelfRef_Table and 30 positional
ToneKit_FrequencyTable_0xNN / WidgetParam_SelfRef_Table_0xNN / WidgetParam_Entry_018_0xCE
names).  Readers in midi/midipkt_routines.s and midi/midi_dispatch_handlers.s
(v10 addresses).  Byte-identical in v10/v9/v7 except the three handler tables."""
import json

O = []
REC0 = [0xEE49E8, 0xEE49FC]
RECS = REC0 + list(range(0xEE4A5E, 0xEE4D6A, 20))
RECLAB = {a: ("MidiCtl_NullRecord" if a == 0xEE49E8 else "MidiCtl_Rec_%02d" % i)
          for i, a in enumerate(RECS)}


def obj(lo, hi, label, typ, header, **kw):
    d = dict(lo="0x%06X" % lo, hi="0x%06X" % hi, label=label, type=typ, header=header)
    d.update(kw)
    O.append(d)


HDR = [
    "MIDI control records, 20 bytes each (41: 0xEE49E8, 0xEE49FC, then 39 from",
    "0xEE4A5E).  Stride from the pointer lists below, which only ever point at",
    "these 41 addresses.  Fields a reader was seen to use:",
    "  +6/+7/+8  MidiPkt_MatchParamInTable (0xFDA258): `cp c,(xhl+7)` against the",
    "            message's data byte, `and c,(xhl+8)` mask; +6 holds status-like",
    "            values (0x90/0x91/0x98/0xB0 ...) or object codes (0x43, 0x48, 0x60-0x66)",
    "  +9/+10    lower / upper bound (SeqAlt_* `cp (xiz+9),l` / `cp l,(xiz+10)`)",
    "  +14       sub-table index, 0xFF = none (SeqAlt_*: `cp a,255`, `cp a,1`)",
    "  +16/+17/+18  handler indices into MidiCtl_Handlers (0-5),",
    "            MidiCtl_FormatHandlers (0-11), MidiCtl_AssSwbHandlers (0-5) --",
    "            `ld c,(xbc+16/17/18); sla bc,2; call (table+bc)`",
    "  +19       0xFF in every record.",
    "The value ranges of +16/+17/+18 over the 41 records equal the three tables'",
    "sizes.  MidiCtl_NullRecord (0xEE49E8) is the list terminator",
    "MidiPkt_MatchParamInTable stops on (`lda xix,(<this>)`, `cp xix,xhl; ret z`).",
    "The bytes at 0xEE4AF0 (+6..+9 of MidiCtl_Rec_09, 0x00FF0017) were typed as a",
    "`.long` \"SendPartDataBlock_Data3\" pointer: v7 has the same bytes although its",
    "SendPartDataBlock_Data3 is at 0xFEFC57, so they are not a pointer.",
]
obj(0xEE49E8, 0xEE49FC, "MidiCtl_NullRecord", "byte", HDR, per_line=20,
    retire=["MidiCtl_SentinelRecord"],
    drop_comments=["40 bytes of MIDI control records.  0xEE49E8 is the sentinel",
                   "MidiPkt_MatchParamInTable (0xFDA258) stops at (`lda xix,(<this>)`, `cp xix,xhl;",
                   "ret z`) and MidiPkt_EnqueueControl_3354 (0xFDA278) compares record pointers against;",
                   "readers take +2/+3/+7/+8/+11 of such records.  Record boundaries inside",
                   "these 40 bytes (and in the records after them) are not established yet."])
obj(0xEE49FC, 0xEE4A10, "MidiCtl_Rec_01", "byte", [
    "MIDI control record 1 (20 bytes, layout at MidiCtl_NullRecord);",
    "reached through the MidiCtl_SelectTable* pointers."], per_line=20)
obj(0xEE4A10, 0xEE4A5E, "MidiCtl_SignedRamp78", "byte", [
    "78 x s8 ramp -64 .. +63: the only sub-table of MidiCtl_SubTableDesc",
    "(length 0x4E = 78, pointer = this), used by SeqAlt_ApplyDescriptor_TypeA",
    "(0xFD91E1) when a record's +14 is 0.  Legacy name ToneKit_FrequencyTable kept",
    "as an alias: shared/positional_labels.s derives 16 _0xNN names from it."],
    fmt_byte="%d", signed=True, per_line=16, alias={"ToneKit_FrequencyTable": 0})
for i, a in enumerate(RECS[2:], 2):
    obj(a, a + 20, RECLAB[a], "byte", [
        "MIDI control record %d (20 bytes, layout at MidiCtl_NullRecord);" % i,
        "reached through the MidiCtl_MatchList*/MidiCtl_SelectTable* pointers."],
        per_line=20, drop_comments=["SendPartDataBlock_Data3 (widget descriptor pointer)"])
LISTS = [(0xEE4D6A, 6, "MidiPkt_DispatchViaTable_4D6A", 0xFDA06F),
         (0xEE4D82, 3, "MidiPkt_DispatchViaTable_4D82", 0xFDA0A3),
         (0xEE4D8E, 3, "MidiPkt_DispatchViaTable_4D8E", 0xFDA0D7),
         (0xEE4D9A, 3, "MidiPkt_DispatchViaTable_4D9A", 0xFDA10B),
         (0xEE4DA6, 2, "MidiPkt_DispatchViaTable_4DA6", 0xFDA13F),
         (0xEE4DAE, 6, "MidiPkt_DispatchViaTable_4DAE", 0xFDA173),
         (0xEE4DC6, 2, "MidiPkt_DispatchSpecialType_Default", 0xFDA229),
         (0xEE4DCE, 9, "MidiPkt_DispatchViaTable_4DCE", 0xFDA7C4)]
for i, (a, n, rd, ra) in enumerate(LISTS):
    obj(a, a + 4 * n, "MidiCtl_MatchList%d" % i, "long", [
        "%d record pointers ending with MidiCtl_NullRecord: %s (0x%06X) passes" % (n, rd, ra),
        "`ld xbc,<this>` to MidiPkt_MatchParamInTable, which walks it until the null",
        "record, then calls MidiCtl_Handlers[match +16]."])
obj(0xEE4DF2, 0xEE4E16, "MidiCtl_GateRecords", "struct", [
    "6 x {u32 RAM address, u8 mask, u8 value}.  MidiPkt_CheckGateCondition (0xFDA777,",
    "base +0) and MidiPkt_CheckGateCondition_Second (0xFDA79A, base +0x12 = record 3):",
    "`lda_rr xde,xde,bc; ld xhl,(xde); ld c,(xde+4); and c,(xhl); cp (xde+5),c`."],
    fields=[4, 1, 1], count=6, record_comment="gate %d")
obj(0xEE4E16, 0xEE4E1C, "MidiCtl_SubTableDesc", "struct", [
    "1 x {u16 length, u32 pointer} = {78, MidiCtl_SignedRamp78}.  SeqAlt_ApplyDescriptor_TypeA",
    "(0xFD91E1): record +14 must be < 1, `muls wa,6; lda xbc,(<this>); ld de,(xwa);",
    "ld xbc,(xwa+2)`; SeqAlt_DescriptorBlock_Data (0xFD9339) reads +2 as a u32 table."],
    fields=[2, 4], count=1)
obj(0xEE4E1C, 0xEE4E20, "MidiCtl_SubTableB", "byte", [
    "4 bytes (0, 0x15, 1, 1), the only entry reachable through MidiCtl_SubTableBPtr",
    "(SeqAlt_NibbleSearch, index = record +14 < 1).  Legacy name",
    "WidgetParam_SelfRef_Table kept as an alias (positional_labels.s base)."],
    alias={"WidgetParam_SelfRef_Table": 0})
obj(0xEE4E20, 0xEE4E24, "MidiCtl_SubTableBPtr", "long", [
    "1 x u32 -> MidiCtl_SubTableB.  Read at 0xFD9569 (after SeqAlt_NibbleSearch_Epilogue2):",
    "`sla wa,2; lda xbc,(<this>); ld_rrl xwa,xbc,wa` with wa = record +14 (< 1)."])
obj(0xEE4E24, 0xEE4E26, "MidiCtl_SubTableC", "byte", [
    "2 bytes (0, 0x7F), the only entry reachable through MidiCtl_SubTableCPtr."])
obj(0xEE4E26, 0xEE4E2A, "MidiCtl_SubTableCPtr", "long", [
    "1 x u32 -> MidiCtl_SubTableC.  Read at 0xFD9639 (after SeqAlt_NibbleSearch_Join):",
    "`sla wa,2; lda xbc,(<this>); ld_rrl xwa,xbc,wa`, wa = record +14 (< 1)."])
TABS = [(0xEE4E2A, 11, "SeqData_FormatOutput_Data", 0xFD8F2A), (0xEE4E56, 11, "VoiceParam_AssSwb_MultiBlock_Data", 0xFD9A0C),
        (0xEE4E82, 1, "SeqData_FormatOutput_Data_Code_Epilogue", 0), (0xEE4E86, 1, "VoiceParam_AssSwb_MultiBlock_Data_Code_Epilogue", 0),
        (0xEE4E8A, 12, "SeqData_FormatOutput_Data_Code_Epilogue2", 0), (0xEE4EBA, 12, "VoiceParam_AssSwb_MultiBlock_Data_Code_Epilogue2", 0),
        (0xEE4EEA, 1, "SeqData_FormatOutput_Data_Code_Epilogue3", 0), (0xEE4EEE, 1, "VoiceParam_AssSwb_MultiBlock_Data_Code_Epilogue3", 0),
        (0xEE4EF2, 1, "SeqData_FormatOutput_Data_Code_Epilogue4", 0), (0xEE4EF6, 1, "VoiceParam_AssSwb_MultiBlock_Data_Code_Epilogue4", 0),
        (0xEE4EFA, 14, "SeqData_FormatOutput_Data_Code_Epilogue5", 0), (0xEE4F32, 7, "VoiceParam_AssSwb_MultiBlock_Data_Code_Epilogue5", 0)]
for i, (a, n, rd, ra) in enumerate(TABS):
    obj(a, a + 4 * n, "MidiCtl_SelectTable%d" % i, "long", [
        "%d record pointer%s indexed by the caller (`sla wa,2` / `lda xwa,(<this>);" % (n, "s" if n > 1 else ""),
        "ld_rrl xwa,xwa,bc`) in the code after %s; the selected record's +17" % rd,
        "(or +18) then picks the handler.  Extent: to the next table's base."])
obj(0xEE4F4E, 0xEE4F52, "NoRef_EnqueueNopPtr", "long", [
    "1 x u32 = MidiPkt_EnqueueControlNop (a lone `ret`).  No reader: MidiCtl_Handlers",
    "is indexed from 0xEE4F52 with an unsigned byte, and nothing else names 0xEE4F4E."])
obj(0xEE4F52, 0xEE4F6A, "MidiCtl_Handlers", "long", [
    "6 x u32 routines selected by a record's +16 (values 0-5): MidiPkt_DispatchViaTable_*",
    "(9 sites): `ld c,(xbc+16); extz bc; sla bc,2; lda xde,(<this>); add xbc,xde;",
    "ld xhl,(xbc); call (xhl)`."])
obj(0xEE4F6A, 0xEE4F9A, "MidiCtl_FormatHandlers", "long", [
    "12 x u32 routines selected by a record's +17 (values 0-11): SeqData_FormatOutput_Data",
    "(0xFD8F2A) and its _Code_Epilogue* siblings: `ld c,(xbc+17); sla bc,2;",
    "lda xde,(<this>); ... call (xhl)`."])
obj(0xEE4F9A, 0xEE4FB2, "MidiCtl_AssSwbHandlers", "long", [
    "6 x u32 routines selected by a record's +18 (values 0-5):",
    "VoiceParam_AssSwb_MultiBlock_Data (0xFD9A0C) and siblings: `ld c,(xbc+18);",
    "sla bc,2; lda xde,(<this>); ... call (xhl)`."])
obj(0xEE4FB2, 0xEE4FBA, "Midi_BankProgramTemplate", "byte", [
    "B0 00 00 20 00 C0 00 + 0xFF: control change 0 (bank MSB) = 0, CC 0x20 (bank",
    "LSB) = 0, program change 0 on channel 1.  No reader found by the operand scan."])
obj(0xEE4FBA, 0xEE4FC2, "Midi_AllOffTemplate", "byte", [
    "B0 7B 00 78 00 79 00 + 0xFF: CC 123 All Notes Off, CC 120 All Sound Off, CC 121",
    "Reset All Controllers (running status).  MIDI_BroadcastControlChange (0xFDB99B)",
    "copies the 7 bytes (`ld xiy,<this>; ld bc,3; ldirw; ldi85`)."])
obj(0xEE4FC2, 0xEE4FC4, "CompIface_PortByte_F4", "byte", [
    "0xF4 + pad: CompIface_SendActiveSensing_PC2 (0xFDBA28) passes it (`ld xde,<this>`)",
    "to the send routine at 0xEF32F4."])
obj(0xEE4FC4, 0xEE4FC6, "CompIface_PortByte_F5", "byte", [
    "0xF5 + pad: CompIface_SendActiveSensing_PC1MAC (0xFDBA16) passes it the same way."])

spec = {"objects": O}
print(json.dumps(spec, indent=1))
