#!/usr/bin/env python3
"""Rename LABEL_* to semantic names in subcpu (028-02D range).

Based on analysis of the 0x028000-0x02DFFF address range in the SubCPU
MIDI voice management subsystem. This block covers:
  - ToneGen 6-channel note param writes (027FD6-0280FE)
  - Voice MIDI CC handlers: volume, pan, expression, sustain, sostenuto,
    chorus, delay, polyphony, tune, pitch-bend, key-shift, rhythm mode (028xxx)
  - Voice iteration helpers: velocity update, pan write, amplitude write,
    sustain re-trigger (028Cxx-028Fxx)
  - AudioChannel dispatch table (029Exx)
  - Voice ModWheel, portamento, channel-pressure, pitch-bend handlers (02Axxx)
  - Voice SystemMsg, ResetAllControllers, portamento target routines (02Axxx)
  - Voice selector/priority/articulation helpers (02ABxx-02ADxx)
  - Voice pitch/amplitude computation (02B0xx-02B4xx)
  - Voice type init/allocate/noteOn/release for types 1-4 and rhythm (02B4xx-02C7xx)
  - Voice_SetPitch, NoteOff, SetVelocity, Allocate, Release, Cut (02C7xx-02CFxx)
  - Voice_NoteOn, SetPanning, ToneGen pan/voice-params write (02Cxxx-02D0xx)
  - ToneGen_WriteVoiceParams, WriteSingleReg, WriteNote, WriteGlobalConfig,
    WriteExtParams families (02D1xx-02DFxx)

Each rename was verified by analysing the routine's code, register usage,
called functions, and callers.

Uses binary I/O to handle encoding safely (Latin-1).
"""

import os
import re

# Renames: (old_label, new_label, brief_comment)
RENAMES = [

    # -----------------------------------------------------------------------
    # 027FD6 block — ToneGen 6-channel note amplitude register write (6 regs)
    # Function at 027FD6 writes voice data[46/50/54/44/48/52] to the six
    # hardware amplitude registers 0x840/0x940/0xA00/0x800/0x900/0x9C0.
    # Each LABEL_ is the post-NOP continuation after a bus write cycle.
    # -----------------------------------------------------------------------
    ('LABEL_02801F', 'ToneGen_WriteNote6ch_NopCont1',
     'Post-NOP continuation after write to reg 0x940 in ToneGen_WriteNote6ch'),
    ('LABEL_028041', 'ToneGen_WriteNote6ch_NopCont2',
     'Post-NOP continuation after write to reg 0xA00 in ToneGen_WriteNote6ch'),
    ('LABEL_028063', 'ToneGen_WriteNote6ch_NopCont3',
     'Post-NOP continuation after write to reg 0x800 in ToneGen_WriteNote6ch'),
    ('LABEL_028085', 'ToneGen_WriteNote6ch_NopCont4',
     'Post-NOP continuation after write to reg 0x900 in ToneGen_WriteNote6ch'),
    ('LABEL_0280A7', 'ToneGen_WriteNote6ch_NopCont5',
     'Post-NOP continuation (exit) after write to reg 0x9C0 in ToneGen_WriteNote6ch'),

    ('LABEL_0280AE', 'ToneGen_WriteNote2ch',
     'Write voice amplitude regs 0x840 and 0x800 from data[46] and data[44]'),
    ('LABEL_0280D5', 'ToneGen_WriteNote2ch_NopCont1',
     'Post-NOP continuation after write to reg 0x840 in ToneGen_WriteNote2ch'),
    ('LABEL_0280F7', 'ToneGen_WriteNote2ch_NopCont2',
     'Post-NOP continuation (exit) after write to reg 0x800 in ToneGen_WriteNote2ch'),

    ('LABEL_0280FE', 'VoiceCC_DataTable_0280FE',
     'Byte data table used by voice CC handlers'),

    # -----------------------------------------------------------------------
    # 028xxx — Voice MIDI CC handler branch targets
    # -----------------------------------------------------------------------

    # Voice_CC_SetVolume branches
    ('LABEL_02886A', 'VoiceCC_SetVolume_Bit1Set',
     'Bit 1 set path in Voice_CC_SetVolume: scale and store volume'),
    ('LABEL_028897', 'VoiceCC_SetVolume_RawSub',
     'Raw-subtract path in Voice_CC_SetVolume: direct sub/store without bit check'),
    ('LABEL_0288B2', 'VoiceCC_SetVolume_Mute',
     'Mute path in Voice_CC_SetVolume: store 0xFE00 as volume'),

    # Voice_CC_SetExpression branches
    ('LABEL_028907', 'VoiceCC_SetExpression_Bit1Set',
     'Bit 1 set path in Voice_CC_SetExpression: scale and store expression'),
    ('LABEL_028934', 'VoiceCC_SetExpression_RawSub',
     'Raw-subtract path in Voice_CC_SetExpression: direct sub/store'),
    ('LABEL_02894F', 'VoiceCC_SetExpression_Mute',
     'Mute path in Voice_CC_SetExpression: store 0xFE00'),

    # Voice_CC_SetSustain / Voice_CC_SetSostenutoFlag branches
    ('LABEL_028979', 'VoiceCC_SetSustain_ClearBit',
     'Sustain-off path in Voice_CC_SetSustain: clear sustain bit in voice state'),
    ('LABEL_0289C5', 'VoiceCC_SetSostenuto_ClearFlag',
     'Sostenuto-off path in Voice_CC_SetSostenutoFlag: clear sostenuto flag'),

    # Voice_CC_SetChorusEnable / Voice_CC_SetDelayEnable branches
    ('LABEL_028A6C', 'VoiceCC_SetChorus_ClearBit',
     'Chorus-off path in Voice_CC_SetChorusEnable: clear chorus enable bit'),
    ('LABEL_028AB8', 'VoiceCC_SetDelay_ClearBit',
     'Delay-off path in Voice_CC_SetDelayEnable: clear delay enable bit'),

    # -----------------------------------------------------------------------
    # 028ADC — Polyphony-mode toggle handler and helpers
    # -----------------------------------------------------------------------
    ('LABEL_028ADC', 'Voice_SetPolyphonyMode',
     'Toggle polyphony-mode bit at 267075, iterate all voices to apply'),
    ('LABEL_028AF2', 'Voice_SetPolyphonyMode_Else',
     'Else branch (bit clear) in Voice_SetPolyphonyMode'),
    ('LABEL_028AFF', 'Voice_SetPolyphonyMode_Apply',
     'Continuation after polyphony bit update: loop all voices'),
    ('LABEL_028B0C', 'Voice_SetPolyphonyMode_LoopBody',
     'Per-voice loop body in Voice_SetPolyphonyMode: call per-voice update'),
    ('LABEL_028B1D', 'Voice_SetPolyphonyMode_LoopExit',
     'Loop exit of Voice_SetPolyphonyMode'),

    # Stub return-only functions
    ('LABEL_028B21', 'VoiceCC_Stub_Ret1',
     'Stub: single ret instruction (no-op handler placeholder)'),
    ('LABEL_028B22', 'VoiceCC_Stub_Ret2',
     'Stub: single ret instruction (no-op handler placeholder)'),

    # -----------------------------------------------------------------------
    # 028B23–028BF9 — Global MIDI parameter setters
    # -----------------------------------------------------------------------
    ('LABEL_028B23', 'Voice_SetMasterTune',
     'Set master tune: subtract 0x40, shift, store at 0x041347'),
    ('LABEL_028B30', 'Voice_SetPitchBendRange',
     'Set pitch bend range: shift value up 8 bits, store at 0x041349'),
    ('LABEL_028B3B', 'Voice_SetKeyShiftEnable',
     'Set or clear key-shift enable bit (bit 12) at 267075'),
    ('LABEL_028B58', 'Voice_SetKeyShiftRange',
     'Select key-shift range: compare cpd and set bits 13-15 at 267075'),
    ('LABEL_028B80', 'Voice_SetKeyShiftRange_BranchA',
     'Branch A in Voice_SetKeyShiftRange: set bit pattern for range group A'),
    ('LABEL_028B83', 'Voice_SetKeyShiftRange_BranchB',
     'Branch B in Voice_SetKeyShiftRange: set bit pattern for range group B'),
    ('LABEL_028B90', 'Voice_SetParam_04134D',
     'Store byte parameter to address 0x04134D'),
    ('LABEL_028B96', 'Voice_GetParam_04134D',
     'Read byte parameter from address 0x04134D'),
    ('LABEL_028B9C', 'Voice_SetRhythmMode',
     'Set rhythm mode: store type bytes at 0x04135E/5F, lookup rate from table'),
    ('LABEL_028BA9', 'Voice_SetRhythmMode_BranchA',
     'Branch A in Voice_SetRhythmMode (rhythm type select path A)'),
    ('LABEL_028BAF', 'Voice_SetRhythmMode_BranchB',
     'Branch B in Voice_SetRhythmMode (rhythm type select path B)'),
    ('LABEL_028BDE', 'Voice_SetRhythmMode_BranchC',
     'Branch C in Voice_SetRhythmMode (rate store path)'),
    ('LABEL_028BE5', 'Voice_SetRhythmMode_BranchD',
     'Branch D in Voice_SetRhythmMode (alternate rate store path)'),
    ('LABEL_028BF9', 'Voice_SetParam_04134B',
     'Store byte parameter to address 0x04134B'),

    # -----------------------------------------------------------------------
    # 028BFF–028C28 — CC-max flag and channel assignment helpers
    # -----------------------------------------------------------------------
    ('LABEL_028BFF', 'Voice_SetCCMaxFlag',
     'Set or clear CC-max flag (bit 1) at 267075 based on value == 0x7F'),
    ('LABEL_028C0C', 'Voice_SetCCMaxFlag_Clear',
     'Clear-flag path in Voice_SetCCMaxFlag (value < 0x7F)'),
    ('LABEL_028C14', 'Voice_WriteChannelAssign',
     'Write channel assignment byte to voice structure at computed offset'),
    ('LABEL_028C28', 'Voice_ReadChannelAssign',
     'Read channel assignment byte from voice structure at computed offset'),

    # -----------------------------------------------------------------------
    # 028C39 — Iterate all voices: apply velocity update
    # -----------------------------------------------------------------------
    ('LABEL_028C39', 'Voice_AllVoices_UpdateVelocity',
     'Iterate all active voice slots, trigger velocity update for each'),
    ('LABEL_028C4F', 'Voice_AllVoices_UpdateVelocity_LoopStart',
     'Outer loop start in Voice_AllVoices_UpdateVelocity'),
    ('LABEL_028C7C', 'Voice_AllVoices_UpdateVelocity_InnerLoop',
     'Inner loop in Voice_AllVoices_UpdateVelocity: per-slot velocity dispatch'),
    ('LABEL_028CBA', 'Voice_AllVoices_UpdateVelocity_TypeA',
     'Type-A branch in velocity inner loop (voice type check path A)'),
    ('LABEL_028CE6', 'Voice_AllVoices_UpdateVelocity_TypeB',
     'Type-B branch in velocity inner loop (voice type check path B)'),
    ('LABEL_028D10', 'Voice_AllVoices_UpdateVelocity_NextOuter',
     'Outer loop advance in Voice_AllVoices_UpdateVelocity'),
    ('LABEL_028D20', 'Voice_AllVoices_UpdateVelocity_InnerStep',
     'Inner loop step in Voice_AllVoices_UpdateVelocity'),
    ('LABEL_028D2A', 'Voice_AllVoices_UpdateVelocity_Exit',
     'Exit of Voice_AllVoices_UpdateVelocity'),

    # -----------------------------------------------------------------------
    # 028D2E–028D42 — Mono-mode flag accessors
    # -----------------------------------------------------------------------
    ('LABEL_028D2E', 'Voice_SetMonoMode',
     'Set or clear mono-mode flag (bit 9) at 267075'),
    ('LABEL_028D3A', 'Voice_SetMonoMode_Clear',
     'Clear-flag path in Voice_SetMonoMode (mono off)'),
    ('LABEL_028D42', 'Voice_GetMonoMode',
     'Read mono-mode flag (bit 9) from 267075 into WA'),

    # -----------------------------------------------------------------------
    # 028D4C — Iterate all voices: write pan register to hardware
    # -----------------------------------------------------------------------
    ('LABEL_028D4C', 'Voice_AllVoices_WritePan',
     'Iterate all active voice slots, write panning register to tone generator'),
    ('LABEL_028D60', 'Voice_AllVoices_WritePan_LoopBody',
     'Per-voice loop body in Voice_AllVoices_WritePan'),
    ('LABEL_028D8E', 'Voice_AllVoices_WritePan_BranchA',
     'Branch A in Voice_AllVoices_WritePan loop (voice type check)'),
    ('LABEL_028DA2', 'Voice_AllVoices_WritePan_BranchB',
     'Branch B in Voice_AllVoices_WritePan loop (alternate pan path)'),
    ('LABEL_028DB4', 'Voice_AllVoices_WritePan_LoopStep',
     'Loop step in Voice_AllVoices_WritePan'),
    ('LABEL_028DBB', 'Voice_AllVoices_WritePan_Exit',
     'Exit of Voice_AllVoices_WritePan'),

    # -----------------------------------------------------------------------
    # 028DBF — Iterate all voices: write amplitude register to hardware
    # -----------------------------------------------------------------------
    ('LABEL_028DBF', 'Voice_AllVoices_WriteAmplitude',
     'Iterate all active voice slots, write amplitude register to tone generator'),
    ('LABEL_028DD3', 'Voice_AllVoices_WriteAmplitude_LoopBody',
     'Per-voice loop body in Voice_AllVoices_WriteAmplitude'),
    ('LABEL_028E01', 'Voice_AllVoices_WriteAmplitude_BranchA',
     'Branch A in Voice_AllVoices_WriteAmplitude loop (voice type check)'),
    ('LABEL_028E09', 'Voice_AllVoices_WriteAmplitude_BranchB',
     'Branch B in Voice_AllVoices_WriteAmplitude loop (alternate amplitude path)'),
    ('LABEL_028E0F', 'Voice_AllVoices_WriteAmplitude_LoopStep',
     'Loop step in Voice_AllVoices_WriteAmplitude'),
    ('LABEL_028E22', 'Voice_AllVoices_WriteAmplitude_Exit',
     'Exit of Voice_AllVoices_WriteAmplitude'),

    # -----------------------------------------------------------------------
    # 028E26 — Iterate notes: handle sustain re-trigger
    # -----------------------------------------------------------------------
    ('LABEL_028E26', 'Voice_AllNotes_SustainRetrigger',
     'Iterate all notes, re-trigger any that are sustained/pending release'),
    ('LABEL_028E40', 'Voice_AllNotes_SustainRetrigger_LoopBody',
     'Per-note loop body in Voice_AllNotes_SustainRetrigger'),
    ('LABEL_028E74', 'Voice_AllNotes_SustainRetrigger_BranchA',
     'Branch A in sustain retrigger loop (check sustain state)'),
    ('LABEL_028E89', 'Voice_AllNotes_SustainRetrigger_BranchB',
     'Branch B in sustain retrigger loop (voice allocation check)'),
    ('LABEL_028EC7', 'Voice_AllNotes_SustainRetrigger_BranchC',
     'Branch C in sustain retrigger loop (slot type dispatch)'),
    ('LABEL_028EEA', 'Voice_AllNotes_SustainRetrigger_BranchD',
     'Branch D in sustain retrigger loop (note re-trigger path)'),
    ('LABEL_028F27', 'Voice_AllNotes_SustainRetrigger_BranchE',
     'Branch E in sustain retrigger loop (alternate re-trigger path)'),
    ('LABEL_028F47', 'Voice_AllNotes_SustainRetrigger_BranchF',
     'Branch F in sustain retrigger loop (note-off pending path)'),
    ('LABEL_028F62', 'Voice_AllNotes_SustainRetrigger_LoopStep',
     'Loop step in Voice_AllNotes_SustainRetrigger'),
    ('LABEL_028F70', 'Voice_AllNotes_SustainRetrigger_Exit',
     'Exit of Voice_AllNotes_SustainRetrigger'),

    ('LABEL_028F75', 'VoiceCC_DataTable_028F75',
     'Byte data table used by sustain/retrigger handlers'),

    # -----------------------------------------------------------------------
    # 029xxx — AudioChannel dispatch
    # -----------------------------------------------------------------------
    ('LABEL_029E31', 'AudioChannel_Dispatch',
     'Dispatch audio channel command by channel index via lookup table'),
    ('LABEL_029E5B', 'AudioChannel_DispatchTable',
     '25-entry dispatch table: each entry pushes channel 0-3 and calr to handler'),

    # Voice_ModWheel_Apply internal branches (function itself is already named)
    ('LABEL_029FAA', 'Voice_ModWheel_Apply_StereoPath',
     'Stereo-voice path in Voice_ModWheel_Apply'),
    ('LABEL_029FB7', 'Voice_ModWheel_Apply_PolyPath',
     'Poly-mode path in Voice_ModWheel_Apply'),

    # -----------------------------------------------------------------------
    # 02Axxx — Voice ModWheel, portamento, channel pressure, pitch bend
    # -----------------------------------------------------------------------
    ('LABEL_02A004', 'Voice_ModWheel_Apply_StereoLoopA',
     'Stereo loop path A in Voice_ModWheel_Apply'),
    ('LABEL_02A026', 'Voice_ModWheel_Apply_StereoLoopB',
     'Stereo loop path B in Voice_ModWheel_Apply'),
    ('LABEL_02A05C', 'Voice_ModWheel_Apply_Exit',
     'Exit of Voice_ModWheel_Apply'),

    ('LABEL_02A061', 'VoiceModWheel_DataTable_02A061',
     'Byte data table for ModWheel param scaling'),

    ('LABEL_02A0E9', 'Voice_Portamento_OnHandler',
     'Portamento-on CC handler: save sostenuto flags, apply portamento'),
    ('LABEL_02A11C', 'Voice_Portamento_OnHandler_C0Mode',
     'C0-mode branch in Voice_Portamento_OnHandler'),
    ('LABEL_02A18C', 'Voice_Portamento_OnHandler_Exit',
     'Exit of Voice_Portamento_OnHandler'),

    ('LABEL_02A18F', 'Voice_PortamentoSlots_WriteHW',
     'Iterate all portamento slots for current voice, write HW pitch registers'),
    ('LABEL_02A1BA', 'Voice_PortamentoSlots_WriteHW_LoopBody',
     'Per-slot loop body in Voice_PortamentoSlots_WriteHW'),
    ('LABEL_02A1E9', 'Voice_PortamentoSlots_WriteHW_NopCont1',
     'Post-NOP continuation 1 in Voice_PortamentoSlots_WriteHW HW write sequence'),
    ('LABEL_02A208', 'Voice_PortamentoSlots_WriteHW_NopCont2',
     'Post-NOP continuation 2 in Voice_PortamentoSlots_WriteHW HW write sequence'),
    ('LABEL_02A22A', 'Voice_PortamentoSlots_WriteHW_NopCont3',
     'Post-NOP continuation 3 in Voice_PortamentoSlots_WriteHW HW write sequence'),
    ('LABEL_02A22F', 'Voice_PortamentoSlots_WriteHW_BranchSkip',
     'Skip-write branch in Voice_PortamentoSlots_WriteHW (inactive slot)'),
    ('LABEL_02A24E', 'Voice_PortamentoSlots_WriteHW_NopCont4',
     'Post-NOP continuation 4 in Voice_PortamentoSlots_WriteHW HW write sequence'),
    ('LABEL_02A270', 'Voice_PortamentoSlots_WriteHW_NopCont5',
     'Post-NOP continuation 5 in Voice_PortamentoSlots_WriteHW HW write sequence'),
    ('LABEL_02A273', 'Voice_PortamentoSlots_WriteHW_LoopStep',
     'Loop step in Voice_PortamentoSlots_WriteHW'),
    ('LABEL_02A27F', 'Voice_PortamentoSlots_WriteHW_Exit',
     'Exit of Voice_PortamentoSlots_WriteHW'),

    # Voice_ChanPressure internal branches (function itself is already named)
    ('LABEL_02A530', 'Voice_ChanPressure_StereoLoopStart',
     'Stereo-voice loop start in Voice_ChanPressure'),
    ('LABEL_02A54F', 'Voice_ChanPressure_StereoLoopBody',
     'Stereo-voice loop body in Voice_ChanPressure'),
    ('LABEL_02A589', 'Voice_ChanPressure_MonoLoopStart',
     'Mono-voice loop start in Voice_ChanPressure'),
    ('LABEL_02A5A7', 'Voice_ChanPressure_MonoLoopBody',
     'Mono-voice loop body in Voice_ChanPressure'),
    ('LABEL_02A5DF', 'Voice_ChanPressure_Exit',
     'Exit of Voice_ChanPressure'),

    # Voice_PitchBend internal branches
    ('LABEL_02A62E', 'Voice_PitchBend_BranchA',
     'Branch A in Voice_PitchBend: dispatch based on pitch-bend source'),
    ('LABEL_02A64C', 'Voice_PitchBend_BranchB',
     'Branch B in Voice_PitchBend: alternate pitch-bend path'),

    # -----------------------------------------------------------------------
    # 02A668 — All-voices portamento HW reset and per-voice portamento update
    # -----------------------------------------------------------------------
    ('LABEL_02A668', 'Voice_AllVoices_PortamentoReset',
     'Iterate all active voices, clear portamento pitch in hardware'),
    ('LABEL_02A672', 'Voice_AllVoices_PortamentoReset_LoopBody',
     'Per-voice loop body in Voice_AllVoices_PortamentoReset'),
    ('LABEL_02A684', 'Voice_AllVoices_PortamentoReset_NopCont1',
     'Post-NOP continuation 1 in portamento reset HW write'),
    ('LABEL_02A692', 'Voice_AllVoices_PortamentoReset_NopCont2',
     'Post-NOP continuation 2 in portamento reset HW write'),
    ('LABEL_02A6AF', 'Voice_AllVoices_PortamentoReset_NopCont3',
     'Post-NOP continuation 3 in portamento reset HW write'),
    ('LABEL_02A6CF', 'Voice_AllVoices_PortamentoReset_LoopStep',
     'Loop step in Voice_AllVoices_PortamentoReset'),
    ('LABEL_02A6D9', 'Voice_AllVoices_PortamentoReset_Exit',
     'Exit of Voice_AllVoices_PortamentoReset'),

    ('LABEL_02A6DB', 'Voice_SetPitchBendRangeAndApply',
     'Set pitch bend range and key-shift, then call Voice_AllVoices_WritePan to apply'),
    ('LABEL_02A6F7', 'Voice_PerVoice_PortamentoPitchUpdate',
     'Per-voice portamento pitch update: read slot data, compute and write pitch to HW'),
    ('LABEL_02A771', 'Voice_PerVoice_PortamentoPitchUpdate_BranchA',
     'Branch A in Voice_PerVoice_PortamentoPitchUpdate (slot state check)'),
    ('LABEL_02A77B', 'Voice_PerVoice_PortamentoPitchUpdate_BranchB',
     'Branch B in Voice_PerVoice_PortamentoPitchUpdate (alternate path)'),
    ('LABEL_02A78B', 'Voice_PerVoice_PortamentoPitchUpdate_Exit',
     'Exit of Voice_PerVoice_PortamentoPitchUpdate'),

    ('LABEL_02A78E', 'Voice_AllVoices_PortamentoUpdate',
     'Iterate all active voice slots, call per-voice portamento pitch update'),
    ('LABEL_02A79A', 'Voice_AllVoices_PortamentoUpdate_LoopBody',
     'Per-voice loop body in Voice_AllVoices_PortamentoUpdate'),
    ('LABEL_02A7AB', 'Voice_AllVoices_PortamentoUpdate_Exit',
     'Exit of Voice_AllVoices_PortamentoUpdate'),

    # Voice_SystemMsg dispatch table entries (function itself is already named)
    ('LABEL_02A7E6', 'Voice_SystemMsg_DispatchJump',
     'Dispatch-table jump in Voice_SystemMsg: index into table and jump'),
    ('LABEL_02A7FC', 'Voice_SystemMsg_DispatchTable',
     'Inline dispatch table for Voice_SystemMsg (calr targets per sysex type)'),
    ('LABEL_02A838', 'Voice_SystemMsg_DispatchEntry0',
     'Dispatch entry 0 in Voice_SystemMsg table'),
    ('LABEL_02A840', 'Voice_SystemMsg_DispatchEntry1',
     'Dispatch entry 1 in Voice_SystemMsg table'),
    ('LABEL_02A843', 'Voice_SystemMsg_DispatchEntry2',
     'Dispatch entry 2 in Voice_SystemMsg table'),

    # -----------------------------------------------------------------------
    # 02A8F3 — Voice_ResetAllControllers and portamento target setup
    # -----------------------------------------------------------------------
    ('LABEL_02A8F3', 'Voice_ResetAllControllers',
     'Iterate all voice slots, reset all CC parameters to factory defaults'),
    ('LABEL_02A900', 'Voice_ResetAllControllers_LoopBody',
     'Per-voice loop body in Voice_ResetAllControllers: reset CC state'),
    ('LABEL_02A9D3', 'Voice_ResetAllControllers_PostLoop',
     'Post-loop continuation in Voice_ResetAllControllers: reset global params'),
    ('LABEL_02AA17', 'Voice_ResetAllControllers_ChanModeLoop',
     'Inner channel-mode reset loop in Voice_ResetAllControllers'),
    ('LABEL_02AA2A', 'Voice_ResetAllControllers_ChanModeExit',
     'Exit of channel-mode reset loop in Voice_ResetAllControllers'),

    ('LABEL_02AA38', 'Voice_PortamentoTargets_SetAll',
     'Set portamento pitch targets for all 4 slots from lookup table'),
    ('LABEL_02AA47', 'Voice_PortamentoTargets_SetAll_LoopBody',
     'Per-slot loop body in Voice_PortamentoTargets_SetAll'),
    ('LABEL_02AAE3', 'Voice_PortamentoTargets_SetAll_Exit',
     'Exit of Voice_PortamentoTargets_SetAll'),

    ('LABEL_02AAE7', 'Voice_PortamentoTarget_SetSlot',
     'Set portamento pitch target for a single slot from LUT with key+channel index'),
    ('LABEL_02AB10', 'Voice_PortamentoTarget_ComputePitch',
     'Compute portamento target pitch from LUT using key and channel index'),

    # -----------------------------------------------------------------------
    # 02AB83 — Update voice flags from portamento slot data
    # -----------------------------------------------------------------------
    ('LABEL_02AB83', 'Voice_UpdateFlagsFromSlot',
     'Update voice state flags from current portamento slot data'),
    ('LABEL_02ABB7', 'Voice_UpdateFlagsFromSlot_BranchA',
     'Branch A in Voice_UpdateFlagsFromSlot (flag bit 0 path)'),
    ('LABEL_02ABBB', 'Voice_UpdateFlagsFromSlot_BranchB',
     'Branch B in Voice_UpdateFlagsFromSlot (flag bit 1 path)'),
    ('LABEL_02ABC8', 'Voice_UpdateFlagsFromSlot_BranchC',
     'Branch C in Voice_UpdateFlagsFromSlot (flag bit 2 path)'),
    ('LABEL_02ABCC', 'Voice_UpdateFlagsFromSlot_BranchD',
     'Branch D in Voice_UpdateFlagsFromSlot (flag bit 3 path)'),
    ('LABEL_02ABD9', 'Voice_UpdateFlagsFromSlot_BranchE',
     'Branch E in Voice_UpdateFlagsFromSlot (flag bit 4 path)'),
    ('LABEL_02ABDD', 'Voice_UpdateFlagsFromSlot_BranchF',
     'Branch F in Voice_UpdateFlagsFromSlot (flag bit 5 path)'),
    ('LABEL_02ABE9', 'Voice_UpdateFlagsFromSlot_Exit',
     'Exit of Voice_UpdateFlagsFromSlot'),

    # -----------------------------------------------------------------------
    # 02ABEE — Voice selector/priority routines
    # -----------------------------------------------------------------------
    ('LABEL_02ABEE', 'Voice_Selector_Unpack3Groups',
     'Unpack 3-group voice selector bits (rhythm/chord type, nibble-packed)'),
    ('LABEL_02AC54', 'Voice_Selector_FindBestSlot',
     'Iterate 3 selector groups, find slot with highest priority'),
    ('LABEL_02AC91', 'Voice_Selector_FindBestSlot_InnerLoop',
     'Inner loop in Voice_Selector_FindBestSlot: compare priority of each slot'),
    ('LABEL_02ACA7', 'Voice_Selector_FindBestSlot_SlotCheck',
     'Slot validity check branch in Voice_Selector_FindBestSlot'),
    ('LABEL_02ACC2', 'Voice_Selector_FindBestSlot_Update',
     'Best-slot update branch in Voice_Selector_FindBestSlot'),
    ('LABEL_02ACC9', 'Voice_Selector_FindBestSlot_InnerStep',
     'Inner loop step in Voice_Selector_FindBestSlot'),
    ('LABEL_02ACE6', 'Voice_Selector_FindBestSlot_OuterStep',
     'Outer loop step in Voice_Selector_FindBestSlot'),
    ('LABEL_02ACFC', 'Voice_Selector_FindBestSlot_Exit',
     'Exit of Voice_Selector_FindBestSlot'),

    ('LABEL_02AD03', 'Voice_Selector_ComputeMixWeights',
     'Compute channel mix weights from 3 selector groups'),

    # -----------------------------------------------------------------------
    # 02ADC1 — Voice init from slot data
    # -----------------------------------------------------------------------
    ('LABEL_02ADC1', 'Voice_InitFromSlot',
     'Init voice from slot: call Voice_UpdateFlagsFromSlot + ComputeMixWeights, clear fields'),

    ('LABEL_02AE22', 'VoiceSlot_DataTable_02AE22',
     'Byte data table for voice slot articulation / portamento defaults'),

    # -----------------------------------------------------------------------
    # 02AFF7 — Signed-clamp and articulation param routines
    # -----------------------------------------------------------------------
    ('LABEL_02AFF7', 'Voice_SignedClamp',
     'Compute C + signed delta, clamp result to [min, max] range'),
    ('LABEL_02B007', 'Voice_SignedClamp_ClampHi',
     'Clamp-to-max branch in Voice_SignedClamp (result > max)'),
    ('LABEL_02B00F', 'Voice_SignedClamp_ClampLo',
     'Clamp-to-min branch in Voice_SignedClamp (result < min)'),

    ('LABEL_02B014', 'Voice_Slot_CalcArticParams',
     'Compute voice slot articulation parameters from portamento data'),
    ('LABEL_02B066', 'Voice_Slot_CalcArticParams_LoopBody',
     'Per-slot loop body in Voice_Slot_CalcArticParams'),
    ('LABEL_02B0D3', 'Voice_Slot_CalcArticParams_Type3Branch',
     'Alternate branch in Voice_Slot_CalcArticParams loop for slot type 3'),
    ('LABEL_02B142', 'Voice_Slot_CalcArticParams_LoopStep',
     'Loop step in Voice_Slot_CalcArticParams'),
    ('LABEL_02B150', 'Voice_Slot_CalcArticParams_Exit',
     'Exit of Voice_Slot_CalcArticParams'),

    # -----------------------------------------------------------------------
    # 02B154 — Amplitude select nibble and octave offset routines
    # -----------------------------------------------------------------------
    ('LABEL_02B154', 'Voice_Slot_CalcAmpNibble',
     'Compute amplitude-select nibble for voice slot from priority table'),
    ('LABEL_02B195', 'Voice_Slot_CalcAmpNibble_BranchA',
     'Branch A in Voice_Slot_CalcAmpNibble (priority level check)'),
    ('LABEL_02B1CB', 'Voice_Slot_CalcAmpNibble_BranchB',
     'Branch B in Voice_Slot_CalcAmpNibble (alternate priority path)'),
    ('LABEL_02B1DF', 'Voice_Slot_CalcAmpNibble_Exit',
     'Exit of Voice_Slot_CalcAmpNibble'),

    ('LABEL_02B1E0', 'Voice_Slot_FindOctaveOffset',
     'Find octave offset for voice amplitude from slot/LUT data'),
    ('LABEL_02B216', 'Voice_Slot_FindOctaveOffset_BranchA',
     'Branch A in Voice_Slot_FindOctaveOffset'),
    ('LABEL_02B222', 'Voice_Slot_FindOctaveOffset_BranchB',
     'Branch B in Voice_Slot_FindOctaveOffset'),
    ('LABEL_02B234', 'Voice_Slot_FindOctaveOffset_BranchC',
     'Branch C in Voice_Slot_FindOctaveOffset'),
    ('LABEL_02B278', 'Voice_Slot_FindOctaveOffset_BranchD',
     'Branch D in Voice_Slot_FindOctaveOffset'),
    ('LABEL_02B2B7', 'Voice_Slot_FindOctaveOffset_BranchE',
     'Branch E in Voice_Slot_FindOctaveOffset'),
    ('LABEL_02B2BB', 'Voice_Slot_FindOctaveOffset_BranchF',
     'Branch F in Voice_Slot_FindOctaveOffset'),
    ('LABEL_02B2C1', 'Voice_Slot_FindOctaveOffset_Exit',
     'Exit of Voice_Slot_FindOctaveOffset'),

    ('LABEL_02B2C2', 'Voice_KeyIndex_Pack3Nibbles',
     'Convert 3-nibble key value to linear slot index'),

    # -----------------------------------------------------------------------
    # 02B2E9 — Pitch offset load and portamento pitch delta routines
    # -----------------------------------------------------------------------
    ('LABEL_02B2E9', 'Voice_Slot_LoadPitchOffset_A',
     'Load pitch offset value from slot table at base+0x10E'),
    ('LABEL_02B2F5', 'Voice_Slot_LoadPitchOffset_B',
     'Load pitch offset value from slot table at base+0x110'),

    ('LABEL_02B301', 'Voice_Slot_ApplyPortamentoDelta',
     'Apply portamento pitch delta to voice with timer/LUT-based smoothing'),
    ('LABEL_02B333', 'Voice_Slot_ApplyPortamentoDelta_BranchA',
     'Branch A in Voice_Slot_ApplyPortamentoDelta (timer threshold check)'),
    ('LABEL_02B359', 'Voice_Slot_ApplyPortamentoDelta_BranchB',
     'Branch B in Voice_Slot_ApplyPortamentoDelta (delta direction check)'),
    ('LABEL_02B37C', 'Voice_Slot_ApplyPortamentoDelta_BranchC',
     'Branch C in Voice_Slot_ApplyPortamentoDelta (positive delta path)'),
    ('LABEL_02B386', 'Voice_Slot_ApplyPortamentoDelta_BranchD',
     'Branch D in Voice_Slot_ApplyPortamentoDelta (negative delta path)'),
    ('LABEL_02B3B4', 'Voice_Slot_ApplyPortamentoDelta_BranchE',
     'Branch E in Voice_Slot_ApplyPortamentoDelta (clamp and store path)'),
    ('LABEL_02B3BC', 'Voice_Slot_ApplyPortamentoDelta_Exit',
     'Exit of Voice_Slot_ApplyPortamentoDelta'),

    ('LABEL_02B3C0', 'Voice_Slot_ApplyPitchJitter',
     'Apply random pitch jitter to voice slot using 8-sample timer modulo'),

    # -----------------------------------------------------------------------
    # 02B3DD — Compute voice pitch from oscillator state
    # -----------------------------------------------------------------------
    ('LABEL_02B3DD', 'Voice_Slot_ComputePitch',
     'Compute final voice pitch from oscillator state: sum osc + portamento + jitter'),

    # -----------------------------------------------------------------------
    # 02B490 — Clamp WA and write note-key register to hardware
    # -----------------------------------------------------------------------
    ('LABEL_02B490', 'Voice_Pitch_ClampRange',
     'Clamp WA to [DE, BC] range, return result in HL'),
    ('LABEL_02B498', 'Voice_Pitch_ClampRange_Hi',
     'Clamp-to-max branch in Voice_Pitch_ClampRange (WA > BC)'),
    ('LABEL_02B49E', 'Voice_Pitch_ClampRange_Lo',
     'Clamp-to-min branch in Voice_Pitch_ClampRange (WA < DE)'),

    ('LABEL_02B4A1', 'ToneGen_WriteNoteKey',
     'Write note key number+0xC0 to HW address register for voice n, then write 0x0000'),
    ('LABEL_02B4C1', 'ToneGen_WriteNoteKey_NopCont1',
     'Post-NOP continuation 1 in ToneGen_WriteNoteKey HW write sequence'),
    ('LABEL_02B4DD', 'ToneGen_WriteNoteKey_NopCont2',
     'Post-NOP continuation (exit) 2 in ToneGen_WriteNoteKey HW write sequence'),

    # -----------------------------------------------------------------------
    # 02B4E3–02BF1B — Voice type init / allocate / noteOn / release
    # -----------------------------------------------------------------------
    ('LABEL_02B4E3', 'Voice_Init_Type4',
     'Full init sequence for type 4 (stereo 4-slot) voice'),
    ('LABEL_02B576', 'Voice_Allocate_Typed',
     'Allocate and fully set up a typed voice slot (type 3 variant)'),
    ('LABEL_02B6EA', 'Voice_Allocate_Typed_ExitA',
     'Exit path A of Voice_Allocate_Typed (allocation failed)'),
    ('LABEL_02B6FC', 'Voice_Allocate_Typed_ExitB',
     'Exit path B of Voice_Allocate_Typed (allocation succeeded)'),

    ('LABEL_02B717', 'Voice_Setup_Typed',
     'Set up typed voice with note data: allocate slot, write params'),
    ('LABEL_02B83A', 'Voice_Setup_Typed_BranchA',
     'Branch A in Voice_Setup_Typed (slot index check)'),
    ('LABEL_02B861', 'Voice_Setup_Typed_BranchB',
     'Branch B in Voice_Setup_Typed (param copy path)'),
    ('LABEL_02B8BA', 'Voice_Setup_Typed_BranchC',
     'Branch C in Voice_Setup_Typed (voice flag update)'),
    ('LABEL_02B8D3', 'Voice_Setup_Typed_BranchD',
     'Branch D in Voice_Setup_Typed (HW write path)'),
    ('LABEL_02B9D9', 'Voice_Setup_Typed_BranchE',
     'Branch E in Voice_Setup_Typed (articulation param path)'),
    ('LABEL_02B9ED', 'Voice_Setup_Typed_BranchF',
     'Branch F in Voice_Setup_Typed (alternate param path)'),
    ('LABEL_02BA01', 'Voice_Setup_Typed_ExitA',
     'Exit path A of Voice_Setup_Typed'),
    ('LABEL_02BA25', 'Voice_Setup_Typed_ExitB',
     'Exit path B of Voice_Setup_Typed'),

    ('LABEL_02BA2C', 'Voice_NoteOn_Type4',
     'Process note-on for type 4 (stereo 4-slot) voice: allocate and set up all slots'),
    ('LABEL_02BA92', 'Voice_NoteOn_Type4_BranchA',
     'Branch A in Voice_NoteOn_Type4 (first slot path)'),
    ('LABEL_02BAB6', 'Voice_NoteOn_Type4_BranchB',
     'Branch B in Voice_NoteOn_Type4 (second slot path)'),
    ('LABEL_02BAF6', 'Voice_NoteOn_Type4_BranchC',
     'Branch C in Voice_NoteOn_Type4 (third slot path)'),
    ('LABEL_02BB1A', 'Voice_NoteOn_Type4_BranchD',
     'Branch D in Voice_NoteOn_Type4 (fourth slot path)'),
    ('LABEL_02BB75', 'Voice_NoteOn_Type4_SlotLoop',
     'Per-slot loop in Voice_NoteOn_Type4'),
    ('LABEL_02BBD5', 'Voice_NoteOn_Type4_AltSlotPath',
     'Alternate slot path in Voice_NoteOn_Type4'),
    ('LABEL_02BC38', 'Voice_NoteOn_Type4_BranchE',
     'Branch E in Voice_NoteOn_Type4 (slot param write)'),
    ('LABEL_02BC3A', 'Voice_NoteOn_Type4_BranchF',
     'Branch F in Voice_NoteOn_Type4'),
    ('LABEL_02BC6A', 'Voice_NoteOn_Type4_BranchG',
     'Branch G in Voice_NoteOn_Type4'),
    ('LABEL_02BC6D', 'Voice_NoteOn_Type4_BranchH',
     'Branch H in Voice_NoteOn_Type4'),
    ('LABEL_02BC7F', 'Voice_NoteOn_Type4_BranchI',
     'Branch I in Voice_NoteOn_Type4'),
    ('LABEL_02BCB1', 'Voice_NoteOn_Type4_BranchJ',
     'Branch J in Voice_NoteOn_Type4'),
    ('LABEL_02BCC5', 'Voice_NoteOn_Type4_BranchK',
     'Branch K in Voice_NoteOn_Type4'),
    ('LABEL_02BCCF', 'Voice_NoteOn_Type4_Exit',
     'Exit of Voice_NoteOn_Type4'),

    ('LABEL_02BCD6', 'Voice_Release_Type4',
     'Release all slots for a type 4 (stereo 4-slot) voice'),
    ('LABEL_02BD5D', 'Voice_Release_Type4_BranchA',
     'Branch A in Voice_Release_Type4'),
    ('LABEL_02BD75', 'Voice_Release_Type4_BranchB',
     'Branch B in Voice_Release_Type4'),

    ('LABEL_02BD87', 'Voice_NoteOn_Type3',
     'Process note-on for type 3 (stereo single-slot) voice: allocate and set up slot'),
    ('LABEL_02BE62', 'Voice_NoteOn_Type3_BranchA',
     'Branch A in Voice_NoteOn_Type3 (slot validity check)'),
    ('LABEL_02BEF1', 'Voice_NoteOn_Type3_ExitA',
     'Exit path A of Voice_NoteOn_Type3 (allocation failed)'),
    ('LABEL_02BF03', 'Voice_NoteOn_Type3_ExitB',
     'Exit path B of Voice_NoteOn_Type3 (allocation succeeded)'),

    ('LABEL_02BF1B', 'Voice_NoteOn_Type2',
     'Process note-on for type 2 (dual-slot) voice: call Type3 twice'),

    # -----------------------------------------------------------------------
    # 02Cxxx — Voice type 2/1/rhythm init/allocate/noteOn, SetPitch etc.
    # -----------------------------------------------------------------------
    ('LABEL_02BF55', 'Voice_NoteOn_Type2_BranchA',
     'Branch A in Voice_NoteOn_Type2 (first slot allocation)'),
    ('LABEL_02BF68', 'Voice_NoteOn_Type2_BranchB',
     'Branch B in Voice_NoteOn_Type2 (second slot allocation)'),
    ('LABEL_02C00E', 'Voice_NoteOn_Type2_BranchC',
     'Branch C in Voice_NoteOn_Type2'),
    ('LABEL_02C030', 'Voice_NoteOn_Type2_BranchD',
     'Branch D in Voice_NoteOn_Type2'),
    ('LABEL_02C03D', 'Voice_NoteOn_Type2_BranchE',
     'Branch E in Voice_NoteOn_Type2'),
    ('LABEL_02C0A9', 'Voice_NoteOn_Type2_LoopStep',
     'Loop step in Voice_NoteOn_Type2'),
    ('LABEL_02C0AF', 'Voice_NoteOn_Type2_Exit',
     'Exit of Voice_NoteOn_Type2'),

    ('LABEL_02C0B6', 'Voice_Init_Type2',
     'Full init sequence for type 2 (dual-slot) voice'),
    ('LABEL_02C12B', 'Voice_Allocate_Type2',
     'Allocate and fully set up a type 2 voice with both slots'),
    ('LABEL_02C21A', 'Voice_Allocate_Type2_BranchA',
     'Branch A in Voice_Allocate_Type2 (second slot path)'),
    ('LABEL_02C295', 'Voice_Allocate_Type2_ExitA',
     'Exit path A of Voice_Allocate_Type2 (allocation failed)'),
    ('LABEL_02C2A7', 'Voice_Allocate_Type2_ExitB',
     'Exit path B of Voice_Allocate_Type2 (allocation succeeded)'),

    ('LABEL_02C2C0', 'Voice_NoteOn_Type1',
     'Process note-on for type 1 (single-slot) voice: call Voice_Allocate_Type2'),
    ('LABEL_02C353', 'Voice_NoteOn_Type1_LoopBody',
     'Per-slot loop body in Voice_NoteOn_Type1'),
    ('LABEL_02C3BF', 'Voice_NoteOn_Type1_LoopStep',
     'Loop step in Voice_NoteOn_Type1'),
    ('LABEL_02C3C5', 'Voice_NoteOn_Type1_Exit',
     'Exit of Voice_NoteOn_Type1'),

    ('LABEL_02C3CC', 'Voice_Init_Type1',
     'Full init sequence for type 1 (single-slot) voice'),

    ('LABEL_02C450', 'Voice_Allocate_1of4',
     'Allocate one of 4 rhythm sub-voices with full parameter setup'),
    ('LABEL_02C5BD', 'Voice_Allocate_1of4_ExitA',
     'Exit path A of Voice_Allocate_1of4 (sub-voice allocation failed)'),
    ('LABEL_02C5CF', 'Voice_Allocate_1of4_ExitB',
     'Exit path B of Voice_Allocate_1of4 (sub-voice allocation succeeded)'),

    ('LABEL_02C5D8', 'Voice_NoteOn_Rhythm',
     'Process note-on for rhythm voice: call Voice_Allocate_1of4 for 1 or 4 sub-voices'),
    ('LABEL_02C625', 'Voice_NoteOn_Rhythm_BranchA',
     'Branch A in Voice_NoteOn_Rhythm (sub-voice count check)'),
    ('LABEL_02C653', 'Voice_NoteOn_Rhythm_BranchB',
     'Branch B in Voice_NoteOn_Rhythm (multi-sub-voice path)'),
    ('LABEL_02C6C7', 'Voice_NoteOn_Rhythm_Exit',
     'Exit of Voice_NoteOn_Rhythm'),

    # Voice_SetPitch internal labels (function itself is already named)
    ('LABEL_02C780', 'Voice_SetPitch_NopCont1',
     'Post-NOP continuation 1 in Voice_SetPitch HW pitch write'),
    ('LABEL_02C7A1', 'Voice_SetPitch_NopCont2',
     'Post-NOP continuation 2 in Voice_SetPitch HW pitch write'),
    ('LABEL_02C7CE', 'Voice_SetPitch_Exit',
     'Exit of Voice_SetPitch'),

    # Voice_NoteOff internal labels (function itself is already named)
    ('LABEL_02C884', 'Voice_NoteOff_NopCont1',
     'Post-NOP continuation 1 in Voice_NoteOff HW amplitude write'),
    ('LABEL_02C8A5', 'Voice_NoteOff_NopCont2',
     'Post-NOP continuation 2 in Voice_NoteOff HW amplitude write'),
    ('LABEL_02C8DB', 'Voice_NoteOff_Exit',
     'Exit of Voice_NoteOff'),

    # Voice_SetVelocity internal labels (function itself is already named)
    # Type-0 (mono) path
    ('LABEL_02C96B', 'Voice_SetVelocity_Type0_SlotLoop',
     'Per-slot loop start in Voice_SetVelocity for type-0 (mono) voice'),
    ('LABEL_02C9A3', 'Voice_SetVelocity_Type0_NopCont1',
     'Post-NOP continuation 1 in Voice_SetVelocity type-0 HW write'),
    ('LABEL_02C9C4', 'Voice_SetVelocity_Type0_NopCont2',
     'Post-NOP continuation 2 in Voice_SetVelocity type-0 HW write'),
    ('LABEL_02C9E9', 'Voice_SetVelocity_Type0_BranchA',
     'Branch A in Voice_SetVelocity type-0 slot loop'),
    ('LABEL_02C9F1', 'Voice_SetVelocity_Type0_BranchB',
     'Branch B in Voice_SetVelocity type-0 slot loop'),
    ('LABEL_02C9FA', 'Voice_SetVelocity_Type0_Loop2Start',
     'Second loop start in Voice_SetVelocity type-0 path'),
    ('LABEL_02CA02', 'Voice_SetVelocity_Type0_Loop2Body',
     'Second loop body in Voice_SetVelocity type-0 path'),
    ('LABEL_02CA78', 'Voice_SetVelocity_Type0_Loop2Step',
     'Second loop step in Voice_SetVelocity type-0 path'),
    ('LABEL_02CA80', 'Voice_SetVelocity_Type0_Loop2Exit',
     'Second loop exit in Voice_SetVelocity type-0 path'),
    # Type-0x40 (stereo 2-ch) path
    ('LABEL_02CA8C', 'Voice_SetVelocity_Type40_Entry',
     'Type-0x40 voice path entry in Voice_SetVelocity: call Voice_NoteOn_Type2'),
    ('LABEL_02CACF', 'Voice_SetVelocity_Type40_SlotLoop',
     'Per-slot loop in Voice_SetVelocity type-0x40 path'),
    ('LABEL_02CB07', 'Voice_SetVelocity_Type40_NopCont1',
     'Post-NOP continuation 1 in Voice_SetVelocity type-0x40 HW write'),
    ('LABEL_02CB28', 'Voice_SetVelocity_Type40_NopCont2',
     'Post-NOP continuation 2 in Voice_SetVelocity type-0x40 HW write'),
    ('LABEL_02CB33', 'Voice_SetVelocity_Type40_LoopStep',
     'Loop step in Voice_SetVelocity type-0x40 path'),
    ('LABEL_02CB3B', 'Voice_SetVelocity_Type40_Loop2Start',
     'Second loop start in Voice_SetVelocity type-0x40 path'),
    ('LABEL_02CB43', 'Voice_SetVelocity_Type40_Loop2Body',
     'Second loop body in Voice_SetVelocity type-0x40 path'),
    ('LABEL_02CB7F', 'Voice_SetVelocity_Type40_Loop2Step',
     'Second loop step in Voice_SetVelocity type-0x40 path'),
    ('LABEL_02CB87', 'Voice_SetVelocity_Type40_Loop2Exit',
     'Second loop exit in Voice_SetVelocity type-0x40 path'),
    # Type-0x80 (stereo 4-ch) path
    ('LABEL_02CB93', 'Voice_SetVelocity_Type80_Entry',
     'Type-0x80 voice path entry in Voice_SetVelocity: call Voice_NoteOn_Type1'),
    ('LABEL_02CBBA', 'Voice_SetVelocity_Type80_SlotLoop',
     'Per-slot loop in Voice_SetVelocity type-0x80 path'),
    ('LABEL_02CC06', 'Voice_SetVelocity_Type80_NopCont1',
     'Post-NOP continuation 1 in Voice_SetVelocity type-0x80 HW write'),
    ('LABEL_02CC27', 'Voice_SetVelocity_Type80_NopCont2',
     'Post-NOP continuation 2 in Voice_SetVelocity type-0x80 HW write'),
    ('LABEL_02CC32', 'Voice_SetVelocity_Type80_LoopStep',
     'Loop step in Voice_SetVelocity type-0x80 path'),
    ('LABEL_02CC3A', 'Voice_SetVelocity_Type80_Loop2Start',
     'Second loop start in Voice_SetVelocity type-0x80 path'),
    ('LABEL_02CC42', 'Voice_SetVelocity_Type80_Loop2Body',
     'Second loop body in Voice_SetVelocity type-0x80 path'),
    ('LABEL_02CC7E', 'Voice_SetVelocity_Type80_Loop2Step',
     'Second loop step in Voice_SetVelocity type-0x80 path'),
    ('LABEL_02CC86', 'Voice_SetVelocity_Type80_Loop2Exit',
     'Second loop exit in Voice_SetVelocity type-0x80 path'),
    # Common exit
    ('LABEL_02CC8F', 'Voice_SetVelocity_Exit',
     'Common exit of Voice_SetVelocity: clear voice status bits'),

    # -----------------------------------------------------------------------
    # 02CCxx — Voice allocation helpers
    # -----------------------------------------------------------------------
    ('LABEL_02CCD3', 'Voice_AllocateForRelease',
     'Allocate voice slot matching a note in release state (for re-trigger)'),
    ('LABEL_02CCF5', 'Voice_AllocateForSustain',
     'Allocate voice slot matching a sustained (half-released) note'),
    ('LABEL_02CD14', 'VoiceAllocate_DataTable_02CD14',
     'Byte data table used by voice allocation helpers'),
    ('LABEL_02CD36', 'Voice_AllocateForFull',
     'Allocate voice slot for full note (searches with note == 0xFF)'),
    ('LABEL_02CD55', 'Voice_AllocateForAny',
     'Allocate any matching voice slot (searches with note == 0x1FFF)'),

    # -----------------------------------------------------------------------
    # 02CD71 — Voice release, cut, and simplified release
    # -----------------------------------------------------------------------
    ('LABEL_02CD71', 'Voice_Release',
     'Release a single voice slot by index: put slot into release state'),
    ('LABEL_02CDA2', 'Voice_Release_BranchA',
     'Branch A in Voice_Release (voice type check)'),
    ('LABEL_02CDDA', 'Voice_Release_BranchB',
     'Branch B in Voice_Release (sustain flag path)'),
    ('LABEL_02CDFC', 'Voice_Release_BranchC',
     'Branch C in Voice_Release (HW register write)'),
    ('LABEL_02CE34', 'Voice_Release_BranchD',
     'Branch D in Voice_Release (alternate HW write path)'),
    ('LABEL_02CE48', 'Voice_Release_Exit',
     'Exit of Voice_Release'),

    ('LABEL_02CE4C', 'Voice_Cut',
     'Hard-cut a voice slot by index: immediately silence and free the slot'),
    ('LABEL_02CE85', 'Voice_Cut_BranchA',
     'Branch A in Voice_Cut (voice type check)'),
    ('LABEL_02CE9A', 'Voice_Cut_BranchB',
     'Branch B in Voice_Cut (slot state clear)'),
    ('LABEL_02CEA8', 'Voice_Cut_BranchC',
     'Branch C in Voice_Cut (HW mute write)'),
    ('LABEL_02CEAE', 'Voice_Cut_BranchD',
     'Branch D in Voice_Cut (alternate HW mute path)'),
    ('LABEL_02CEC8', 'Voice_Cut_Exit',
     'Exit of Voice_Cut'),

    ('LABEL_02CED5', 'Voice_ReleaseSingle',
     'Simplified release: put a single voice slot into release state without checks'),
    ('LABEL_02CF04', 'Voice_ReleaseSingle_Exit',
     'Exit of Voice_ReleaseSingle'),

    # Voice_ParamInit internal labels (function itself is already named)
    ('LABEL_02CF1B', 'Voice_ParamInit_LoopBody',
     'Per-slot loop body in Voice_ParamInit: reset individual param fields'),
    ('LABEL_02CF57', 'Voice_ParamInit_BranchA',
     'Branch A in Voice_ParamInit loop (field type A)'),
    ('LABEL_02CF6A', 'Voice_ParamInit_BranchB',
     'Branch B in Voice_ParamInit loop (field type B)'),
    ('LABEL_02CF73', 'Voice_ParamInit_BranchC',
     'Branch C in Voice_ParamInit loop (field type C)'),
    ('LABEL_02CF7C', 'Voice_ParamInit_BranchD',
     'Branch D in Voice_ParamInit loop (field type D)'),
    ('LABEL_02CF85', 'Voice_ParamInit_BranchE',
     'Branch E in Voice_ParamInit loop (field type E)'),
    ('LABEL_02CF8C', 'Voice_ParamInit_BranchF',
     'Branch F in Voice_ParamInit loop (field type F)'),
    ('LABEL_02CF93', 'Voice_ParamInit_LoopStep',
     'Loop step in Voice_ParamInit'),

    # Voice_NoteOn internal labels (function itself is already named)
    ('LABEL_02CFE7', 'Voice_NoteOn_ZeroVelocity',
     'Zero-velocity path in Voice_NoteOn: allocate, init, then noteoff'),
    ('LABEL_02D009', 'Voice_NoteOn_Exit',
     'Exit of Voice_NoteOn'),

    # -----------------------------------------------------------------------
    # 02D00D — Voice_SetPanning and ToneGen pan register write
    # -----------------------------------------------------------------------
    ('LABEL_02D00D', 'Voice_SetPanning',
     'Set panning for all active voice slots from global panning state, write to HW'),
    ('LABEL_02D0B8', 'Voice_SetPanning_Exit',
     'Exit of Voice_SetPanning'),

    ('LABEL_02D0BA', 'ToneGen_WritePanReg',
     'Write panning register to tone generator HW at voice base + 0x400 + iz*14'),
    ('LABEL_02D0D7', 'ToneGen_WritePanReg_NopCont',
     'Post-NOP continuation (exit) of ToneGen_WritePanReg HW write'),

    ('LABEL_02D0DC', 'ToneGen_PanTable_02D0DC',
     'Byte data table for panning register values'),

    # -----------------------------------------------------------------------
    # 02D12A-02D414 — ToneGen_WriteVoiceParams internal NOP continuations
    # ToneGen_WriteVoiceParams writes ~22 sequential hardware register pairs
    # to 0x100000/0x100002. Each LABEL_ is the post-NOP landing pad.
    # -----------------------------------------------------------------------
    ('LABEL_02D12A', 'ToneGen_WriteVoiceParams_NopCont01',
     'Post-NOP continuation 01 in ToneGen_WriteVoiceParams register write sequence'),
    ('LABEL_02D14F', 'ToneGen_WriteVoiceParams_NopCont02',
     'Post-NOP continuation 02 in ToneGen_WriteVoiceParams register write sequence'),
    ('LABEL_02D171', 'ToneGen_WriteVoiceParams_NopCont03',
     'Post-NOP continuation 03 in ToneGen_WriteVoiceParams register write sequence'),
    ('LABEL_02D193', 'ToneGen_WriteVoiceParams_NopCont04',
     'Post-NOP continuation 04 in ToneGen_WriteVoiceParams register write sequence'),
    ('LABEL_02D1B5', 'ToneGen_WriteVoiceParams_NopCont05',
     'Post-NOP continuation 05 in ToneGen_WriteVoiceParams register write sequence'),
    ('LABEL_02D1D7', 'ToneGen_WriteVoiceParams_NopCont06',
     'Post-NOP continuation 06 in ToneGen_WriteVoiceParams register write sequence'),
    ('LABEL_02D1F9', 'ToneGen_WriteVoiceParams_NopCont07',
     'Post-NOP continuation 07 in ToneGen_WriteVoiceParams register write sequence'),
    ('LABEL_02D21B', 'ToneGen_WriteVoiceParams_NopCont08',
     'Post-NOP continuation 08 in ToneGen_WriteVoiceParams register write sequence'),
    ('LABEL_02D23D', 'ToneGen_WriteVoiceParams_NopCont09',
     'Post-NOP continuation 09 in ToneGen_WriteVoiceParams register write sequence'),
    ('LABEL_02D25F', 'ToneGen_WriteVoiceParams_NopCont10',
     'Post-NOP continuation 10 in ToneGen_WriteVoiceParams register write sequence'),
    ('LABEL_02D281', 'ToneGen_WriteVoiceParams_NopCont11',
     'Post-NOP continuation 11 in ToneGen_WriteVoiceParams register write sequence'),
    ('LABEL_02D2A3', 'ToneGen_WriteVoiceParams_NopCont12',
     'Post-NOP continuation 12 in ToneGen_WriteVoiceParams register write sequence'),
    ('LABEL_02D2BD', 'ToneGen_WriteVoiceParams_NopCont13',
     'Post-NOP continuation 13 in ToneGen_WriteVoiceParams register write sequence'),
    ('LABEL_02D2DF', 'ToneGen_WriteVoiceParams_NopCont14',
     'Post-NOP continuation 14 in ToneGen_WriteVoiceParams register write sequence'),
    ('LABEL_02D301', 'ToneGen_WriteVoiceParams_NopCont15',
     'Post-NOP continuation 15 in ToneGen_WriteVoiceParams register write sequence'),
    ('LABEL_02D323', 'ToneGen_WriteVoiceParams_NopCont16',
     'Post-NOP continuation 16 in ToneGen_WriteVoiceParams register write sequence'),
    ('LABEL_02D345', 'ToneGen_WriteVoiceParams_NopCont17',
     'Post-NOP continuation 17 in ToneGen_WriteVoiceParams register write sequence'),
    ('LABEL_02D367', 'ToneGen_WriteVoiceParams_NopCont18',
     'Post-NOP continuation 18 in ToneGen_WriteVoiceParams register write sequence'),
    ('LABEL_02D389', 'ToneGen_WriteVoiceParams_NopCont19',
     'Post-NOP continuation 19 in ToneGen_WriteVoiceParams register write sequence'),
    ('LABEL_02D3AB', 'ToneGen_WriteVoiceParams_NopCont20',
     'Post-NOP continuation 20 in ToneGen_WriteVoiceParams register write sequence'),
    ('LABEL_02D3CD', 'ToneGen_WriteVoiceParams_NopCont21',
     'Post-NOP continuation 21 in ToneGen_WriteVoiceParams register write sequence'),
    ('LABEL_02D3EF', 'ToneGen_WriteVoiceParams_NopCont22',
     'Post-NOP continuation 22 in ToneGen_WriteVoiceParams register write sequence'),
    ('LABEL_02D414', 'ToneGen_WriteVoiceParams_Exit',
     'Exit of ToneGen_WriteVoiceParams after all register writes'),

    # ToneGen_WriteSingleReg internal label (function itself is already named)
    ('LABEL_02D431', 'ToneGen_WriteSingleReg_NopCont',
     'Post-NOP continuation (exit) of ToneGen_WriteSingleReg HW write'),

    # -----------------------------------------------------------------------
    # 02D436-02D507 — ToneGen_WriteNote (6 amplitude registers: 0x840-0x9C0)
    # ToneGen_WriteNote function at 02D436, with 5 NOP continuation labels.
    # -----------------------------------------------------------------------
    ('LABEL_02D436', 'ToneGen_WriteNote',
     'Write voice amplitude to all 6 tone generator regs: 0x840/0x940/0xA00/0x800/0x900/0x9C0'),
    ('LABEL_02D45D', 'ToneGen_WriteNote_NopCont1',
     'Post-NOP continuation 1 in ToneGen_WriteNote (after reg 0x940)'),
    ('LABEL_02D47F', 'ToneGen_WriteNote_NopCont2',
     'Post-NOP continuation 2 in ToneGen_WriteNote (after reg 0xA00)'),
    ('LABEL_02D4A1', 'ToneGen_WriteNote_NopCont3',
     'Post-NOP continuation 3 in ToneGen_WriteNote (after reg 0x800)'),
    ('LABEL_02D4C3', 'ToneGen_WriteNote_NopCont4',
     'Post-NOP continuation 4 in ToneGen_WriteNote (after reg 0x900)'),
    ('LABEL_02D4E5', 'ToneGen_WriteNote_NopCont5',
     'Post-NOP continuation 5 in ToneGen_WriteNote (after reg 0x9C0)'),
    ('LABEL_02D507', 'ToneGen_WriteNote_NopCont6',
     'Post-NOP continuation 6 (exit) in ToneGen_WriteNote'),

    # -----------------------------------------------------------------------
    # 02D50E-02D557 — ToneGen_WriteNote_2Regs (regs 0x840 and 0x800 only)
    # -----------------------------------------------------------------------
    ('LABEL_02D50E', 'ToneGen_WriteNote_2Regs',
     'Write voice amplitude to 2 tone generator regs only: 0x840 and 0x800'),
    ('LABEL_02D535', 'ToneGen_WriteNote_2Regs_NopCont1',
     'Post-NOP continuation 1 in ToneGen_WriteNote_2Regs (after reg 0x840)'),
    ('LABEL_02D557', 'ToneGen_WriteNote_2Regs_NopCont2',
     'Post-NOP continuation (exit) 2 in ToneGen_WriteNote_2Regs (after reg 0x800)'),

    ('LABEL_02D55E', 'ToneGen_NoteTable_02D55E',
     'Byte data table for note amplitude register values'),

    # -----------------------------------------------------------------------
    # 02D5D0-02D669 — ToneGen stereo / hold note write variants
    # -----------------------------------------------------------------------
    ('LABEL_02D5D0', 'ToneGen_WriteNote_Stereo',
     'Write stereo voice amplitude: reg 0x840 and 0x880'),
    ('LABEL_02D5F7', 'ToneGen_WriteNote_Stereo_NopCont1',
     'Post-NOP continuation 1 in ToneGen_WriteNote_Stereo (after reg 0x840)'),
    ('LABEL_02D619', 'ToneGen_WriteNote_Stereo_NopCont2',
     'Post-NOP continuation (exit) 2 in ToneGen_WriteNote_Stereo (after reg 0x880)'),

    ('LABEL_02D620', 'ToneGen_WriteNote_Hold',
     'Write and hold voice amplitude: write 0x840 twice then 0x880'),
    ('LABEL_02D647', 'ToneGen_WriteNote_Hold_NopCont1',
     'Post-NOP continuation 1 in ToneGen_WriteNote_Hold'),
    ('LABEL_02D669', 'ToneGen_WriteNote_Hold_NopCont2',
     'Post-NOP continuation (exit) 2 in ToneGen_WriteNote_Hold'),

    # -----------------------------------------------------------------------
    # 02D670–02D7C0 — ToneGen extended parameter write variants
    # -----------------------------------------------------------------------
    ('LABEL_02D670', 'ToneGen_WriteSingleReg_180',
     'Write single 16-bit register to tone generator at voice base + 0x180'),
    ('LABEL_02D68A', 'ToneGen_WriteSingleReg_180_NopCont',
     'Post-NOP continuation (exit) of ToneGen_WriteSingleReg_180 HW write'),

    ('LABEL_02D68F', 'ToneGen_WriteVoiceParams_Ext',
     'Write extended voice params: regs at base+0x800/0x840/0x80 from xde/xbc'),
    ('LABEL_02D6B9', 'ToneGen_WriteVoiceParams_Ext_NopCont1',
     'Post-NOP continuation 1 in ToneGen_WriteVoiceParams_Ext'),
    ('LABEL_02D6D3', 'ToneGen_WriteVoiceParams_Ext_NopCont2',
     'Post-NOP continuation 2 in ToneGen_WriteVoiceParams_Ext'),
    ('LABEL_02D6F5', 'ToneGen_WriteVoiceParams_Ext_NopCont3',
     'Post-NOP continuation 3 in ToneGen_WriteVoiceParams_Ext'),
    ('LABEL_02D71A', 'ToneGen_WriteVoiceParams_Ext_NopCont4',
     'Post-NOP continuation 4 in ToneGen_WriteVoiceParams_Ext'),
    ('LABEL_02D738', 'ToneGen_WriteVoiceParams_Ext_NopCont5',
     'Post-NOP continuation (exit) 5 in ToneGen_WriteVoiceParams_Ext'),

    ('LABEL_02D73F', 'ToneGen_WriteVoiceParams_Ext2',
     'Write extended voice params variant 2: regs at base+0x800/0x840/base'),
    ('LABEL_02D766', 'ToneGen_WriteVoiceParams_Ext2_NopCont1',
     'Post-NOP continuation 1 in ToneGen_WriteVoiceParams_Ext2'),
    ('LABEL_02D780', 'ToneGen_WriteVoiceParams_Ext2_NopCont2',
     'Post-NOP continuation 2 in ToneGen_WriteVoiceParams_Ext2'),
    ('LABEL_02D7A2', 'ToneGen_WriteVoiceParams_Ext2_NopCont3',
     'Post-NOP continuation 3 in ToneGen_WriteVoiceParams_Ext2'),
    ('LABEL_02D7C0', 'ToneGen_WriteVoiceParams_Ext2_NopCont4',
     'Post-NOP continuation (exit) 4 in ToneGen_WriteVoiceParams_Ext2'),

    # ToneGen_WriteGlobalConfig internal labels (function itself is already named)
    ('LABEL_02D7DA', 'ToneGen_WriteGlobalConfig_BranchA',
     'Branch A in ToneGen_WriteGlobalConfig (config word select)'),
    ('LABEL_02D7DE', 'ToneGen_WriteGlobalConfig_BranchB',
     'Branch B in ToneGen_WriteGlobalConfig (alternate config word)'),
    ('LABEL_02D7F5', 'ToneGen_WriteGlobalConfig_NopCont01',
     'Post-NOP continuation 01 in ToneGen_WriteGlobalConfig write sequence'),
    ('LABEL_02D810', 'ToneGen_WriteGlobalConfig_NopCont02',
     'Post-NOP continuation 02 in ToneGen_WriteGlobalConfig write sequence'),
    ('LABEL_02D82B', 'ToneGen_WriteGlobalConfig_NopCont03',
     'Post-NOP continuation 03 in ToneGen_WriteGlobalConfig write sequence'),
    ('LABEL_02D846', 'ToneGen_WriteGlobalConfig_NopCont04',
     'Post-NOP continuation 04 in ToneGen_WriteGlobalConfig write sequence'),
    ('LABEL_02D861', 'ToneGen_WriteGlobalConfig_NopCont05',
     'Post-NOP continuation 05 in ToneGen_WriteGlobalConfig write sequence'),
    ('LABEL_02D87C', 'ToneGen_WriteGlobalConfig_NopCont06',
     'Post-NOP continuation 06 in ToneGen_WriteGlobalConfig write sequence'),
    ('LABEL_02D897', 'ToneGen_WriteGlobalConfig_NopCont07',
     'Post-NOP continuation 07 in ToneGen_WriteGlobalConfig write sequence'),
    ('LABEL_02D8B2', 'ToneGen_WriteGlobalConfig_NopCont08',
     'Post-NOP continuation 08 in ToneGen_WriteGlobalConfig write sequence'),
    ('LABEL_02D8CD', 'ToneGen_WriteGlobalConfig_NopCont09',
     'Post-NOP continuation 09 in ToneGen_WriteGlobalConfig write sequence'),
    ('LABEL_02D8E8', 'ToneGen_WriteGlobalConfig_NopCont10',
     'Post-NOP continuation 10 in ToneGen_WriteGlobalConfig write sequence'),
    ('LABEL_02D903', 'ToneGen_WriteGlobalConfig_NopCont11',
     'Post-NOP continuation 11 in ToneGen_WriteGlobalConfig write sequence'),
    ('LABEL_02D91E', 'ToneGen_WriteGlobalConfig_NopCont12',
     'Post-NOP continuation 12 in ToneGen_WriteGlobalConfig write sequence'),
    ('LABEL_02D939', 'ToneGen_WriteGlobalConfig_NopCont13',
     'Post-NOP continuation 13 (exit) in ToneGen_WriteGlobalConfig write sequence'),

    ('LABEL_02D93E', 'ToneGen_GlobalConfigTable_02D93E',
     'Byte data table for ToneGen_WriteGlobalConfig (global config register values)'),

    # ToneGen_WriteExtParams_56 internal labels (function itself is already named)
    ('LABEL_02DA48', 'ToneGen_WriteExtParams_56_NopCont1',
     'Post-NOP continuation 1 in ToneGen_WriteExtParams_56 write sequence'),
    ('LABEL_02DA4B', 'ToneGen_WriteExtParams_56_BranchSkip',
     'Skip-write branch in ToneGen_WriteExtParams_56 (bit 15 not set)'),
    ('LABEL_02DA6A', 'ToneGen_WriteExtParams_56_NopCont2',
     'Post-NOP continuation 2 in ToneGen_WriteExtParams_56 write sequence'),
    ('LABEL_02DA8F', 'ToneGen_WriteExtParams_56_NopCont3',
     'Post-NOP continuation (exit) 3 in ToneGen_WriteExtParams_56'),

    ('LABEL_02DA96', 'ToneGen_WriteExtParam_600',
     'Write single extended parameter to tone generator at voice base + 0x600'),
    ('LABEL_02DAB3', 'ToneGen_WriteExtParam_600_NopCont',
     'Post-NOP continuation (exit) of ToneGen_WriteExtParam_600 HW write'),

    # -----------------------------------------------------------------------
    # 02DAB8 onwards — Extended param write variants (stereo, mute, type-dispatch)
    # -----------------------------------------------------------------------
    ('LABEL_02DAB8', 'ToneGen_WriteExtParams_56_Alt',
     'Write ext param 56 variant: choose 0x580 (set) or 0x580+clr-bit15 (clear)'),
    ('LABEL_02DAEA', 'ToneGen_WriteExtParams_56_Alt_NopCont1',
     'Post-NOP continuation 1 in ToneGen_WriteExtParams_56_Alt (set-bit path)'),
    ('LABEL_02DAED', 'ToneGen_WriteExtParams_56_Alt_ClearPath',
     'Clear-bit-15 path in ToneGen_WriteExtParams_56_Alt'),
    ('LABEL_02DB0F', 'ToneGen_WriteExtParams_56_Alt_NopCont2',
     'Post-NOP continuation (exit) 2 in ToneGen_WriteExtParams_56_Alt'),

    ('LABEL_02DB16', 'ToneGen_WriteExtParam_600_Mute',
     'Write mute (0x8100) to tone generator ext param at voice base + 0x600'),
    ('LABEL_02DB2F', 'ToneGen_WriteExtParam_600_Mute_NopCont',
     'Post-NOP continuation (exit) of ToneGen_WriteExtParam_600_Mute HW write'),

    # ToneGen_WriteExtParams_56b internal labels (function itself is already named)
    ('LABEL_02DB65', 'ToneGen_WriteExtParams_56b_NopCont1',
     'Post-NOP continuation 1 in ToneGen_WriteExtParams_56b (set-bit 0x5C0 path)'),
    ('LABEL_02DB68', 'ToneGen_WriteExtParams_56b_ClearPath',
     'Clear-bit-15 path in ToneGen_WriteExtParams_56b: write 0x640 then 0x5C0'),
    ('LABEL_02DB87', 'ToneGen_WriteExtParams_56b_NopCont2',
     'Post-NOP continuation 2 in ToneGen_WriteExtParams_56b (after 0x640 write)'),
    ('LABEL_02DBAC', 'ToneGen_WriteExtParams_56b_NopCont3',
     'Post-NOP continuation (exit) 3 in ToneGen_WriteExtParams_56b'),

    ('LABEL_02DBB3', 'ToneGen_ExtParams56b_DataTable',
     'Byte data table for ToneGen_WriteExtParams_56b'),

    # ToneGen_WriteExtParams_15 internal labels (function itself is already named)
    ('LABEL_02DC82', 'ToneGen_WriteExtParams_15_NopCont1',
     'Post-NOP continuation 1 in ToneGen_WriteExtParams_15 (set-bit 0x540 path)'),
    ('LABEL_02DC85', 'ToneGen_WriteExtParams_15_ClearPath',
     'Clear path in ToneGen_WriteExtParams_15: write 0x1C0 then 0x540 with clr-bit15'),
    ('LABEL_02DCA4', 'ToneGen_WriteExtParams_15_NopCont2',
     'Post-NOP continuation 2 in ToneGen_WriteExtParams_15 (after 0x1C0 write)'),
    ('LABEL_02DCC9', 'ToneGen_WriteExtParams_15_NopCont3',
     'Post-NOP continuation (exit) 3 in ToneGen_WriteExtParams_15'),

    ('LABEL_02DCD0', 'ToneGen_WriteExtParam_1C0_Single',
     'Write single extended parameter to tone generator at voice base + 0x1C0'),
    ('LABEL_02DCED', 'ToneGen_WriteExtParam_1C0_Single_NopCont',
     'Post-NOP continuation (exit) of ToneGen_WriteExtParam_1C0_Single HW write'),

    ('LABEL_02DCF2', 'ToneGen_WriteExtParams_15_Alt',
     'Write ext param 15 variant: choose 0x540 (set) or 0x540+clr-bit15 (clear)'),
    ('LABEL_02DD24', 'ToneGen_WriteExtParams_15_Alt_NopCont1',
     'Post-NOP continuation 1 in ToneGen_WriteExtParams_15_Alt (set-bit path)'),
    ('LABEL_02DD27', 'ToneGen_WriteExtParams_15_Alt_ClearPath',
     'Clear-bit-15 path in ToneGen_WriteExtParams_15_Alt'),
    ('LABEL_02DD49', 'ToneGen_WriteExtParams_15_Alt_NopCont2',
     'Post-NOP continuation (exit) 2 in ToneGen_WriteExtParams_15_Alt'),

    ('LABEL_02DD50', 'ToneGen_WriteExtParam_540_Mute',
     'Write mute (0x8100) to tone generator ext param at voice base + 0x540'),
    ('LABEL_02DD69', 'ToneGen_WriteExtParam_540_Mute_NopCont',
     'Post-NOP continuation (exit) of ToneGen_WriteExtParam_540_Mute HW write'),

    ('LABEL_02DD6D', 'ToneGen_ExtParams15_DataTable',
     'Byte data table for ToneGen_WriteExtParams_15 handler dispatch'),

    # -----------------------------------------------------------------------
    # 02DE69 — Type-dispatched extended parameter write functions
    # -----------------------------------------------------------------------
    ('LABEL_02DE69', 'ToneGen_WriteExtParam_TypeDispatch_Single',
     'Write ext param: if wa < 0x40 write 0x1C0, else write 0x600 (single reg)'),
    ('LABEL_02DE8C', 'ToneGen_WriteExtParam_TypeDispatch_Single_NopCont1',
     'Post-NOP continuation 1 in ToneGen_WriteExtParam_TypeDispatch_Single (0x1C0 path)'),
    ('LABEL_02DE91', 'ToneGen_WriteExtParam_TypeDispatch_Single_HiPath',
     'High-type path (wa >= 0x40) in ToneGen_WriteExtParam_TypeDispatch_Single: write 0x600'),
    ('LABEL_02DEAB', 'ToneGen_WriteExtParam_TypeDispatch_Single_NopCont2',
     'Post-NOP continuation 2 in ToneGen_WriteExtParam_TypeDispatch_Single (0x600 path)'),
    ('LABEL_02DEAE', 'ToneGen_WriteExtParam_TypeDispatch_Single_Exit',
     'Exit of ToneGen_WriteExtParam_TypeDispatch_Single'),

    ('LABEL_02DEB0', 'ToneGen_WriteExtParams_TypeDispatch',
     'Write ext params: if wa < 0x40 use 0x540, else use 0x580; with set/clr-bit15 select'),
    ('LABEL_02DEE8', 'ToneGen_WriteExtParams_TypeDispatch_NopCont1',
     'Post-NOP continuation 1 in ToneGen_WriteExtParams_TypeDispatch (lo set-bit path)'),
    ('LABEL_02DEEB', 'ToneGen_WriteExtParams_TypeDispatch_LoClearPath',
     'Lo clear-bit-15 path in ToneGen_WriteExtParams_TypeDispatch (wa < 0x40)'),
    ('LABEL_02DF0D', 'ToneGen_WriteExtParams_TypeDispatch_NopCont2',
     'Post-NOP continuation 2 in ToneGen_WriteExtParams_TypeDispatch (lo clear path)'),
    ('LABEL_02DF12', 'ToneGen_WriteExtParams_TypeDispatch_HiPath',
     'High-type path (wa >= 0x40) in ToneGen_WriteExtParams_TypeDispatch: use 0x580'),
    ('LABEL_02DF3C', 'ToneGen_WriteExtParams_TypeDispatch_NopCont3',
     'Post-NOP continuation 3 in ToneGen_WriteExtParams_TypeDispatch (hi set-bit path)'),
    ('LABEL_02DF3F', 'ToneGen_WriteExtParams_TypeDispatch_HiClearPath',
     'Hi clear-bit-15 path in ToneGen_WriteExtParams_TypeDispatch (wa >= 0x40)'),
    ('LABEL_02DF61', 'ToneGen_WriteExtParams_TypeDispatch_NopCont4',
     'Post-NOP continuation 4 in ToneGen_WriteExtParams_TypeDispatch (hi clear path)'),
    ('LABEL_02DF64', 'ToneGen_WriteExtParams_TypeDispatch_Exit',
     'Exit of ToneGen_WriteExtParams_TypeDispatch'),

    ('LABEL_02DF68', 'ToneGen_WriteExtParam_Mute_TypeDispatch',
     'Write mute (0x8100): if wa < 0x40 write to 0x540, else write to 0x580'),
    ('LABEL_02DF87', 'ToneGen_WriteExtParam_Mute_TypeDispatch_NopCont1',
     'Post-NOP continuation 1 in ToneGen_WriteExtParam_Mute_TypeDispatch (lo path)'),
    ('LABEL_02DF8B', 'ToneGen_WriteExtParam_Mute_TypeDispatch_HiPath',
     'High-type path (wa >= 0x40) in ToneGen_WriteExtParam_Mute_TypeDispatch: write 0x580'),
    ('LABEL_02DFA4', 'ToneGen_WriteExtParam_Mute_TypeDispatch_NopCont2',
     'Post-NOP continuation (exit) 2 in ToneGen_WriteExtParam_Mute_TypeDispatch'),

    # ToneGen_Config_Init internal label (function itself is already named)
    ('LABEL_02DFEA', 'ToneGen_Config_Init_NopCont1',
     'Post-NOP continuation 1 in ToneGen_Config_Init initial register clear sequence'),
]


def main():
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    src = os.path.join(base, 'subcpu', 'kn5000_subprogram_v142.s')

    with open(src, 'rb') as f:
        content = f.read().decode('latin-1')

    renamed = 0
    for old_label, new_label, comment in RENAMES:
        if old_label + ':' not in content:
            print(f'  WARNING: {old_label} not found, skipping')
            continue

        refs = len(re.findall(r'\b' + re.escape(old_label) + r'\b', content))
        new_content = re.sub(r'\b' + re.escape(old_label) + r'\b', new_label, content)

        if new_content != content:
            content = new_content
            renamed += 1
            print(f'  {old_label:25s} -> {new_label:50s} ({refs} refs)')

    # Check maincpu for cross-references
    maincpu_src = os.path.join(base, 'maincpu', 'kn5000_v10_program.s')
    with open(maincpu_src, 'rb') as f:
        maincpu_content = f.read().decode('latin-1')

    maincpu_renames = 0
    for old_label, new_label, _ in RENAMES:
        if old_label in maincpu_content:
            maincpu_content = re.sub(
                r'\b' + re.escape(old_label) + r'\b', new_label, maincpu_content
            )
            maincpu_renames += 1

    with open(src, 'wb') as f:
        f.write(content.encode('latin-1'))

    if maincpu_renames > 0:
        with open(maincpu_src, 'wb') as f:
            f.write(maincpu_content.encode('latin-1'))

    print(
        f'\nRenamed {renamed} labels in subcpu '
        f'({maincpu_renames} cross-refs in maincpu)'
    )


if __name__ == '__main__':
    main()
