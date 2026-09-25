#!/usr/bin/env python3
"""Spec for retype_data_objects.py: maincpu 0xEE2D6C-0xEE3678 -- MIDI/SysEx data
(what the tree called SeqChan_CommandDispatch_Table, SeqFormat_ReferenceData,
SeqData_SubDispatch_Table, MidiPkt_EventType_Table and ~60 positional
MidiPkt_EventType_Table_0xNN names).  Readers: midi/midi_dispatch_handlers.s,
midi/midipkt_routines.s, audio/dsp_config_sysex.s (v10 addresses)."""
import json

O = []


def obj(lo, hi, label, typ, header, **kw):
    d = dict(lo="0x%06X" % lo, hi="0x%06X" % hi, label=label, type=typ, header=header)
    d.update(kw)
    O.append(d)


def handlers(lo, n, label, reader, raddr, how, **kw):
    obj(lo, lo + 4 * n, label, "long", [
        "%d x u32 routine pointers; %s (0x%06X): %s." % (n, reader, raddr, how),
        "Extent: to the next object's base (loaded by its own reader)."], **kw)


def switch(lo, n, label, reader, raddr, base, basename=None):
    obj(lo, lo + 2 * n, label, "short", [
        "%d x s16 switch offsets.  %s (0x%06X): `ld_rrw ..,xix,..;" % (n, reader, raddr),
        "lda xix,(0x%06X); jp_rr 8,xix,..` -- targets 0x%06X%s + offset (no labels yet)."
        % (base, base, " (%s)" % basename if basename else "")],
        fmt_short="%d", signed=True, per_line=8)


def tmpl(lo, hi, label, reader, raddr, how):
    obj(lo, hi, label, "byte", [
        "%d-byte template: %s (0x%06X) copies it into its frame (%s)." % (hi - lo, reader, raddr, how),
        "Trailing 0xFF (if any) is padding the copy does not take."], per_line=16)


def sysex(lo, hi, label, reader, raddr, n, via="SeqBuf_FlushNoteOffs"):
    obj(lo, hi, label, "byte", [
        "MIDI system-exclusive bytes (0xF0 ...) sent by %s (0x%06X): `ld xwa,<this>;" % (reader, raddr),
        "ld bc,%d; call %s` queues the first %d bytes%s." % (
            n, via, n, "" if hi - lo == n else "; the rest is 0xFF padding")],
        per_line=16)


handlers(0xEE2D6C, 39, "SeqChan_CommandHandlers", "MidiTable_DispatchHelper", 0xFD7AF5,
         "`lda xbc,(<this>); ld_rrl xhl,xbc,wa; call (xhl)`",
         alias={"SeqChan_CommandDispatch_Table": 0})
handlers(0xEE2E08, 22, "SeqChan_StepCmdHandlers", "MidiPkt_ArpExtHandler_N_Data", 0xFD7E10,
         "`lda xbc,(<this>); ld_rrl xhl,xbc,hl; call (xhl)`")
handlers(0xEE2E60, 22, "SeqChan_WriteFieldHandlers", "SeqChan_DispatchByType_Data", 0xFD80B2,
         "`lda xbc,(<this>); ld_rrl xhl,xbc,wa; call (xhl)`")
tmpl(0xEE2EB8, 0xEE2EBE, "MidiSysEx_BlockTemplate", "MidiSysEx_ProcessBlock_Helper7", 0xFD81EE,
     "`ld xiy,<this>; ld xix,xsp; ld bc,3; ldirw`")
handlers(0xEE2EBE, 22, "MidiSysEx_BlockHandlers", "MidiSysEx_ProcessBlock_Helper11", 0xFD827D,
         "`lda xbc,(<this>); ld_rrl xhl,xbc,wa; call (xhl)` -- entries point 0-4 bytes apart"
         " into one run of short entry points at 0xFD829B")
tmpl(0xEE2F16, 0xEE2F26, "MidiChan_ZeroRegTemplate", "MidiChan_InitSoundRegisters", 0xFD8484,
     "`ld xiy,<this>; ld xix,<ram>; ldw bc,8; ldirw`, four times")
obj(0xEE2F26, 0xEE2F36, "SeqFormat_HandlerTable", "long", [
    "4 x u32 routine pointers (0xFD84F0, 0xFD84F2, 0xFD84F3, 0xFD84F4): entry 4 of",
    "Subsys_HandlerTableList, so VoiceInit_Dispatch (0xFDDB5A) calls entry",
    "[xde/4] of it with the other subsystems' tables.  Legacy name",
    "SeqFormat_ReferenceData kept (positional_labels.s derives from it)."],
    alias={"SeqFormat_ReferenceData": 0})
obj(0xEE2F36, 0xEE2F76, "VoiceData_RamBlockPtrs", "long", [
    "16 x u32 RAM addresses 0xFDDA + 0x14*i.  VoiceData_ZeroFillAll (0xFD8A4E):",
    "`lda xbc,(<this>); ld xwa,xbc; lda xbc,(xbc+64)` -- walks the 16 entries",
    "(end = <this>+64) and clears each block."], per_line=4)
obj(0xEE2F76, 0xEE2F7E, "VoiceData_SyncCodeList", "byte", [
    "0xFF-terminated list of object codes (0x43, 0x64, 0x65, 0x66, 0x99, 0x98, 0x93).",
    "VoiceData_SyncLoop (0xFD8C35): `ld xbc,<this>; add xbc,xwa; ld a,(xbc);",
    "call VoiceData_LookupPtrByIndex` for each code until 0xFF."])
switch(0xEE2F7E, 7, "SysExSend_SwitchOffsets", "SysEx_InitiateSend", 0xFD8CAE, 0xFD8CF1,
       "SysEx_SendDispatch")
handlers(0xEE2F8C, 39, "SeqData_Handlers", "SeqData_DispatchHandler", 0xFD8DB4,
         "`lda xbc,(<this>); ld_rrl xhl,xbc,hl; call (xhl)`",
         alias={"SeqData_SubDispatch_Table": 0})
tmpl(0xEE3028, 0xEE302C, "SeqData_OutTemplate", "SeqData_DispatchLoop_Done", 0xFD8DFD,
     "`ld xiy,<this>; ld xix,xsp; ldi85; ldiw` -- 3 bytes")
switch(0xEE302C, 7, "SeqDataFmt_SwitchOffsets", "SeqData_FormatOutput_Data", 0xFD8F2A, 0xFD8F7E)
switch(0xEE303A, 7, "AssSwbMulti_SwitchOffsets", "VoiceParam_AssSwb_MultiBlock_Data", 0xFD9A0C, 0xFD9A3E)
tmpl(0xEE3048, 0xEE304C, "MidiPkt_ControlTemplate", "MidiPkt_BuildControl", 0xFD9DA0,
     "`ld xiy,<this>; lda xix,(xsp+6); ldi85; ldiw` -- 3 bytes")
obj(0xEE304C, 0xEE334C, "MidiPkt_EventType_Table", "long", [
    "MIDI packet event type dispatch table",
    "Index: event byte from queue (0x00-0xbf), entries: 192",
    "Called from MidiPkt_ProcessEventQueue (midipkt_routines.s:275)",
    "Most entries are Nop; active entries dispatch to sub-table handlers",
    "(the :275 line reference above predates later edits; the reader is below)",
    "192 x u32 handler pointers, one per queued event code 0x00-0xBF.",
    "MidiPkt_ProcessEventQueue_Loop (0xFDA03B): `lda xde,(<this>); exts xbc;",
    "add xbc,xde; ld xhl,(xbc); call (xhl)` with bc = code*4.  Most entries are",
    "MidiPkt_Nop; the rest dispatch to sub-table handlers.",
    "192 entries = exactly up to the next referenced object."],
    drop_comments=["MIDI packet event type dispatch table",
                   "Index: event byte from queue (0x00-0xbf), entries: 192",
                   "Called from MidiPkt_ProcessEventQueue (midipkt_routines.s:275)",
                   "Most entries are Nop; active entries dispatch to sub-table handlers"])
for a, rd, ra in [(0xEE334C, "MidiPkt_EnqueueControl_3354", 0xFDA278),
                  (0xEE3350, "MidiPkt_EnqueueExtended_Data", 0xFDA302),
                  (0xEE3354, "MidiPkt_EnqueueControl_335C", 0xFDA389)]:
    tmpl(a, a + 4, "MidiPkt_MsgTemplate_%04X" % (a & 0xFFFF), rd, ra,
         "`ld xiy,<this>; lda xix,(xsp+4); ldi85; ldiw` -- 3 bytes")
for a, rd, ra in [(0xEE3358, "MidiPkt_EnqueueControl_3358", 0xFDA40F),
                  (0xEE335E, "MidiPkt_EnqueueControl_335E", 0xFDA4EE)]:
    tmpl(a, a + 6, "MidiPkt_MsgTemplate_%04X" % (a & 0xFFFF), rd, ra,
         "`ld xiy,<this>; lda xix,(xsp+4); ld bc,2; ldirw; ldi85` -- 5 bytes")
for a, rd, ra in [(0xEE3364, "MidiPkt_EnqueueControl_3364", 0xFDA587),
                  (0xEE3368, "MidiPkt_EnqueueControl_3368", 0xFDA616),
                  (0xEE336C, "MidiPkt_BuildControl_Helper", 0xFDA6CE)]:
    tmpl(a, a + 4, "MidiPkt_MsgTemplate_%04X" % (a & 0xFFFF), rd, ra,
         "`ld xiy,<this>; lda xix,(xsp+4); ldi85; ldiw` -- 3 bytes")
switch(0xEE3370, 6, "SysExBulk_SwitchOffsets", "MidiPkt_SysExBulkTransfer_Data", 0xFDA921, 0xFDA94D)
obj(0xEE337C, 0xEE338C, "SysExBulk_SlotMap", "byte", [
    "16 x u8 (15, 0..8, 10..14, 9).  MidiPkt_SysExBulkTransfer_Data_Join (0xFDA9B1):",
    "`lda xbc,(<this>); ld_rrb a,xbc,wa`."], per_line=16)
for i, a in enumerate(range(0xEE338C, 0xEE33A4, 4)):
    tmpl(a, a + 4, "SysExBulk_FrameTemplate%d" % i, "MidiPkt_SysExBulkTransfer_Data_Join", 0xFDA9B1,
         "`ld xiy,<this>; lda xix,(xsp+..); ldiw; ldiw` -- 4 bytes, one of six")
obj(0xEE33A4, 0xEE33AC, "SysEx4B_VoiceIndexMap8", "byte", [
    "8 x u8.  SysEx_ClampVoiceIndex8_DoLookup (0xFDAB4B): index clamped to 0..7",
    "(`cp a,8; jr c` else 0), then `lda xbc,(<this>); ld_rrb l,xbc,wa`."], fmt_byte="%d")
obj(0xEE33AC, 0xEE342C, "SysEx4B_LevelCurve128", "byte", [
    "128 x u8 monotone curve 0..94.  SysEx_ClampVoiceIndex128_DoLookup (0xFDABCF):",
    "index clamped to 0..127, then `lda xbc,(<this>); ld_rrb l,xbc,wa`."], fmt_byte="%d", per_line=16)
obj(0xEE342C, 0xEE3434, "SysEx49_VoiceIndexMap8", "byte", [
    "8 x u8.  SysEx_ClampVoiceIndex8_49_DoLookup (0xFDAC59), same access as",
    "SysEx4B_VoiceIndexMap8."], fmt_byte="%d")
obj(0xEE3434, 0xEE34B4, "SysEx49_LevelCurve128", "byte", [
    "128 x u8, the same curve as SysEx4B_LevelCurve128 in a separate copy.",
    "SysEx_ClampVoiceIndex128_49_DoLookup (0xFDACDD), same access."], fmt_byte="%d", per_line=16)
T4B = [(0xEE34B4, 5), (0xEE34BE, 7), (0xEE34CC, 5), (0xEE34D6, 7), (0xEE34E4, 8),
       (0xEE34F4, 8), (0xEE3504, 7), (0xEE3512, 7)]
for k, (a, n) in enumerate(T4B):
    obj(a, a + 2 * n, "SysEx4B_ChannelWords%d" % k, "short", [
        "%d x u16 (count pinned by the `cp c,%d; ret nc` guard): case %d of" % (n, n, k),
        "SysEx_ChannelHandler_4B_Data (0xFDAD13) loads it (`ld xwa,<this>`) and",
        "returns word c (`ld_rrw hl,xwa,de`)."], fmt_short="%d", per_line=8)
switch(0xEE3520, 8, "SysEx4B_ChannelSwitch", "SysEx_DispatchByChannel", 0xFDACEA, 0xFDAD13,
       "SysEx_ChannelHandler_4B_Data")
T49 = [(0xEE3530, 5), (0xEE353A, 5), (0xEE3544, 5), (0xEE354E, 5), (0xEE3558, 5),
       (0xEE3562, 5), (0xEE356C, 6), (0xEE3578, 6)]
for k, (a, n) in enumerate(T49):
    obj(a, a + 2 * n, "SysEx49_ChannelWords%d" % k, "short", [
        "%d x s16 (count pinned by the `cp c,%d; ret nc` guard): case %d of" % (n, n, k),
        "SysEx_ChannelHandler_49_Data (0xFDAD9A) loads it (`ld xwa,<this>`) and",
        "returns word c (`ld_rrw hl,xwa,de`)."], fmt_short="%d", signed=True, per_line=8)
switch(0xEE3584, 8, "SysEx49_ChannelSwitch", "SysEx_DispatchByChannel_49", 0xFDAD71, 0xFDAD9A,
       "SysEx_ChannelHandler_49_Data")
for a, rd, ra in [(0xEE3594, "MidiTable_FlushArpNotes", 0xFD7B2F),
                  (0xEE359A, "MidiTable_UseDefaultBuf", 0xFD7B5B),
                  (0xEE35A0, "MidiPkt_ArpConfigChain_Data_Helper18", 0xFD7A34),
                  (0xEE35A6, "MidiPkt_ArpConfigChain_Data_0x34C", 0xFD7A59),
                  (0xEE35AC, "MidiPkt_ArpConfigChain_Data_0x34C", 0xFD7A59),
                  (0xEE35B2, "MidiTable_CheckSpecialSlot", 0xFD7B4D)]:
    sysex(a, a + 6, "SysEx_Msg_%04X" % (a & 0xFFFF), rd, ra, 5)
sysex(0xEE35B8, 0xEE35BC, "SysEx_Msg_35B8", "ArpQueue_ProcessAndSort_Data_Helper", 0xFD6AD2, 3)
sysex(0xEE35BC, 0xEE35C4, "SysEx_Msg_35BC", "MidiPkt_ArpPassLoop", 0xFD7673, 7)
sysex(0xEE35C4, 0xEE35CC, "SysEx_Msg_35C4", "MidiPkt_ArpSecondLoop", 0xFD76DA, 7)
sysex(0xEE35CC, 0xEE35D0, "SysEx_Msg_35CC", "SeqData_DispatchLoop_Done", 0xFD8DFD, 3)
obj(0xEE35D0, 0xEE35D6, "SysEx_GmSystemOn", "byte", [
    "Universal Non-Real-Time SysEx F0 7E 7F 09 01 F7 = General MIDI System On.",
    "MidiPkt_DispatchSpecialType (0xFDA1ED) sends it: `ld xwa,<this>; ld bc,6; call ArpQueue_Enqueue`."])
obj(0xEE35D6, 0xEE35DC, "SysEx_GmSystemOff", "byte", [
    "F0 7E 7F 09 02 F7 = General MIDI System Off.  MidiPkt_DispatchSpecialType_Type10 (0xFDA20B)",
    "sends it: `ld xwa,<this>; ld bc,6; call ArpQueue_Enqueue`."])
sysex(0xEE35DC, 0xEE35E2, "SysEx_Msg_35DC", "MidiPkt_BuildControl_Skip", 0xFD9EA7, 6,
      via="ArpQueue_Enqueue")
TECH = [(0xEE35E2, 12, "Helper2"), (0xEE35EE, 12, "Helper3"), (0xEE35FA, 12, "Helper5"),
        (0xEE3606, 12, "Helper6"), (0xEE3612, 12, "Helper8"), (0xEE361E, 12, "Helper9"),
        (0xEE362A, 10, "Helper10"), (0xEE3634, 12, "Helper11"), (0xEE3640, 12, "Helper12"),
        (0xEE364C, 10, "Helper13"), (0xEE3656, 12, "Helper15"), (0xEE3662, 12, "Helper16"),
        (0xEE366E, 10, "Helper17")]
for a, size, h in TECH:
    n = 12 if size == 12 else 9
    obj(a, a + size, "SysEx_TechMsg_%04X" % (a & 0xFFFF), "byte", [
        "SysEx F0 50 2D 01 28 12 + address/data (%d bytes, no F7: the sender appends" % n,
        "the rest).  MidiPkt_ArpConfigChain_Data_%s: `ld xwa,<this>; ldw bc,%d;" % (h, n),
        "call SeqBuf_FlushNoteOffs`%s." % ("" if size == n else "; trailing 0xFF is padding")],
        per_line=16)

print(json.dumps({"objects": O}, indent=1))
