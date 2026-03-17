#!/usr/bin/env python3
"""Rename LABEL_* to semantic names in kn5000_v10_program.s (rhythm/drum functions).

Covers 3 function groups:
  1. RhythmROM_LoadDrumKit  (F6449F-F65293)  Drum kit loading, rhythm config, auto-accomp drum dispatch
  2. Rhythm_SendByte        (F54E04-F55BAB)  Rhythm note processing, transposition, velocity
  3. SetWall_X              (F1EE11-F20293)  Wallpaper/accompaniment style slot configuration

Each rename was verified by analysing the routine's code, register usage,
called functions, and callers within the file.

Uses binary I/O to handle Latin-1 encoding safely.  Never use the Edit tool on
kn5000_v10_program.s -- it corrupts the Latin-1 encoding.
"""

import os
import re

# ---------------------------------------------------------------------------
# Rename table: (old_label, new_label, brief_comment)
#
# Groups follow the natural function boundaries visible in the source.
# ---------------------------------------------------------------------------

RENAMES = [

    # ==================================================================
    # 1. RhythmROM_LoadDrumKit region (lines ~185750-186800)
    #    Drum kit loading from ROM, rhythm channel/pattern configuration,
    #    auto-accompaniment drum dispatch, fill-in, tempo control.
    # ==================================================================

    # --- Pre-LoadDrumKit: error fallback path from earlier function ---
    ('LABEL_F6449F', 'DrumKit_ErrorFallbackLoop',
     'On pattern error: loop through all 10 drum kit slots using fallback table'),

    ('LABEL_F644A6', 'DrumKit_ErrorFallbackSlotIter',
     'Inner loop body: compute slot offset, load kit, increment counter'),

    ('LABEL_F644E3', 'DrumKit_SetErrorCode20',
     'Set global error code 20 (success) and call error handler'),

    ('LABEL_F644EC', 'DrumKit_RestoreRegisters',
     'Restore saved WA/HL to state variables 13549-13551/13526'),

    ('LABEL_F644FE', 'DrumKit_Return',
     'Return from drum kit function'),

    ('LABEL_F644FF', 'DrumKit_GroupAssignTable',
     'Data: drum group assignment table (81 bytes, maps kit index to group 0-8)'),

    # --- RhythmROM_LoadDrumKit main body ---

    ('LABEL_F646CA', 'DrumKit_PatternLoadFailed',
     'Pattern load failed: iterate 10 slots with fallback table F6472A'),

    ('LABEL_F646D1', 'DrumKit_FallbackSlotLoop',
     'Loop body: compute 10-entry offset from drum group, load kit slot'),

    ('LABEL_F6470E', 'DrumKit_AllPatternsOK',
     'All patterns loaded OK: set error code 20, call error handler'),

    ('LABEL_F64717', 'DrumKit_Epilogue',
     'Restore saved regs to state vars and return'),

    ('LABEL_F6472A', 'DrumKit_FallbackSlotTable',
     'Data: fallback drum slot ordering (30 bytes, 10 entries x 3 groups)'),

    # --- Drum parameter lookup ---
    ('LABEL_F64748', 'DrumParam_Wrapper',
     'Wrapper: calr to DrumParam_Lookup, ret'),

    ('LABEL_F6474C', 'DrumParam_Lookup',
     'Look up drum parameter: index by (w & 7)*4 into pointer table, add offset, read byte'),

    ('LABEL_F64769', 'DrumParam_PointerTableAndData',
     'Data: pointer table (8x4 bytes) + drum parameter arrays (velocity/pan/reverb etc.)'),

    # --- Drum kit initialization (open/enter) ---
    ('LABEL_F64A3B', 'DrumKitInit_Wrapper',
     'Wrapper: push XIZ, call DrumKitInit_Entry, pop XIZ, ret'),

    ('LABEL_F64A42', 'DrumKitInit_Entry',
     'Entry: validate channel 0x48, check state 36149==14 for early return'),

    ('LABEL_F64A52', 'DrumKitInit_Setup',
     'Initialize drum kit state: clear flags, set counters, store current drum/bank'),

    ('LABEL_F64AA8', 'DrumKitInit_ClearAssignFlags',
     'Clear drum assign bits 2-3 in port 64607, post event d=5 e=0x48'),

    ('LABEL_F64AB7', 'DrumKitInit_CheckExtAssign',
     'Check extended assign bit 2 in port 64608, clear and post event d=6 e=0x48'),

    ('LABEL_F64ACC', 'DrumKitInit_FinalSetup',
     'Final setup: call init helpers, clear counters, reset flags'),

    ('LABEL_F64AED', 'DrumKitInit_Return',
     'Return from drum kit init'),

    ('LABEL_F64AEE', 'DrumKit_SendProgramChange',
     'Compute program change: map bank (13526) to MIDI program, send via F64C24'),

    ('LABEL_F64AFF', 'DrumKit_SendPC_MaskAndSend',
     'Mask bank to 5 bits, add 0x80, dispatch program + bank change events'),

    # --- Drum kit exit ---
    ('LABEL_F64B24', 'DrumKitExit_Wrapper',
     'Wrapper: push XIZ, call DrumKitExit_Entry, pop XIZ, ret'),

    ('LABEL_F64B2B', 'DrumKitExit_Entry',
     'Entry: validate channel, check state 36148==14 for early return'),

    ('LABEL_F64B3B', 'DrumKitExit_CheckState1',
     'Check state==1: if not, clear bit 0 of 36232'),

    ('LABEL_F64B47', 'DrumKitExit_ClearFlags',
     'Clear rhythm config flag, mask status bits, reset state, call init routines'),

    ('LABEL_F64B9D', 'DrumKitExit_PostRestore',
     'Post-restore: call init, validate bank, check pending events'),

    ('LABEL_F64BBA', 'DrumKitExit_ExtraInit',
     'Extra init call when events pending'),

    ('LABEL_F64BBE', 'DrumKitExit_CheckAutoPlay',
     'Check auto-play bit (12931 bit 0): if clear, set flag 13517 bit 7'),

    ('LABEL_F64BC9', 'DrumKitExit_Return',
     'Return from drum kit exit'),

    ('LABEL_F64BCA', 'DrumKitExit_DataPad',
     'Data: 8-byte padding/jump stub'),

    # --- Drum bank validation ---
    ('LABEL_F64BD2', 'DrumKit_ValidateBank',
     'Validate drum bank: range-check port 64602, clamp to nearest valid bank'),

    ('LABEL_F64BE9', 'DrumKit_ValidateBank_Mid',
     'Mid-range check: bank 0x91-0x97 -> base 0x84'),

    ('LABEL_F64BF2', 'DrumKit_ValidateBank_High',
     'High range: bank > 0x97 -> base 0x88'),

    ('LABEL_F64BF4', 'DrumKit_ValidateBank_Apply',
     'Apply validated bank: store, compute program change, send MIDI'),

    ('LABEL_F64C05', 'DrumKit_ValidateBank_Return',
     'Return (bank already valid)'),

    ('LABEL_F64C06', 'DrumKit_StoreAndSendBank',
     'Store bank to port 64602, clear program bits in 64603, send program change'),

    # --- Drum MIDI event dispatch ---
    ('LABEL_F64C24', 'DrumKit_PostMidiEvents',
     'Post two SwbtWr events: bank (d=1) and program (d=0) for channel 0x48'),

    # --- Drum status flags update ---
    ('LABEL_F64C62', 'DrumKit_UpdateStatusFlags',
     'Update drum status flags (13553): merge assignment bits from 14235 into w'),

    ('LABEL_F64C7A', 'DrumKit_StatusBit3',
     'Check 14235 bit 3: if set, OR w with 0x39'),

    ('LABEL_F64C82', 'DrumKit_StatusBit0',
     'Check 14235 bit 0: if set, OR w with 0x35'),

    ('LABEL_F64C8A', 'DrumKit_StatusBit1',
     'Check 14235 bit 1: if set, OR w with 0x2D'),

    ('LABEL_F64C92', 'DrumKit_StatusBit2',
     'Check 14235 bit 2: if set, OR w with 0x1D'),

    ('LABEL_F64C9A', 'DrumKit_StoreStatus',
     'Store updated status byte to 13553'),

    ('LABEL_F64C9F', 'DrumKit_InlineCode1',
     'Data/inline code: misc drum operations'),

    # --- Drum kit dispatch by slot ---
    ('LABEL_F64D51', 'DrumSlot_DispatchWrapper',
     'Wrapper: push XIZ, call DrumSlot_Dispatch, pop XIZ, ret'),

    ('LABEL_F64D58', 'DrumSlot_Dispatch',
     'Dispatch drum slot: clamp HL to 0-9, lookup handler in table, call it'),

    ('LABEL_F64D60', 'DrumSlot_ClampAndLookup',
     'Lookup: shift HL*4 into pointer table F64D75, call via (xwa)'),

    ('LABEL_F64D75', 'DrumSlot_HandlerTable',
     'Data: 10-entry dispatch table for drum slots 0-9'),

    ('LABEL_F64D9D', 'DrumSlot_Handler_Type0',
     'Handler for slots 0-3: simple calr stub (4 bytes)'),

    ('LABEL_F64DA1', 'DrumSlot_Handler_Type1',
     'Handler for slots 4-9: calr to offset calc routine'),

    ('LABEL_F64DA5', 'DrumSlot_OffsetCalc_Simple',
     'Offset calc: add 0/4/8 to L based on 13517 bits 5:4'),

    ('LABEL_F64DB2', 'DrumSlot_OffsetCalc_Check20',
     'Check if bits == 0x20: add 4 to L'),

    ('LABEL_F64DBC', 'DrumSlot_OffsetCalc_AddHigh',
     'Bits != 0x20: add 8 to L'),

    ('LABEL_F64DBF', 'DrumSlot_OffsetCalc_StoreAndRet',
     'Store computed L to 13526 and return'),

    ('LABEL_F64DC4', 'DrumSlot_OffsetCalc_Extended',
     'Extended offset calc: add 8/0x0E/0x14 based on 13517 bits 5:4'),

    ('LABEL_F64DD4', 'DrumSlot_ExtOffset_Check20',
     'Check if bits == 0x20: add 0x0E to L'),

    ('LABEL_F64DDE', 'DrumSlot_ExtOffset_AddHigh',
     'Bits != 0x20: add 0x14 to L'),

    ('LABEL_F64DE1', 'DrumSlot_ExtOffset_StoreAndRet',
     'Store extended L to 13526 and return'),

    # --- Rhythm pattern init (conditional) ---
    ('LABEL_F64DE6', 'RhythmPatInit_Wrapper',
     'Wrapper: push XIZ, call RhythmPatInit_Entry, pop XIZ, ret'),

    ('LABEL_F64DED', 'RhythmPatInit_Entry',
     'Entry: check (0x8D37)==0xB2, init pattern data, optionally call F59AB9'),

    ('LABEL_F64E0E', 'RhythmPatInit_Cleanup',
     'Cleanup: mask status flags and return'),

    ('LABEL_F64E14', 'RhythmPatInit_LoadParams',
     'Load rhythm parameters from XIY: drum count, kit index, tempo, channels'),

    ('LABEL_F64E48', 'RhythmPatInit_FlagBit7',
     'Check param byte bit 7: set/clear 13518 bit 7'),

    ('LABEL_F64E63', 'RhythmPatInit_Tempo4',
     'Check bit 4: set/clear 13546 bit 4'),

    ('LABEL_F64E6D', 'RhythmPatInit_Tempo5',
     'Check bit 5: set/clear 13546 bit 5'),

    ('LABEL_F64E77', 'RhythmPatInit_CopyChannels',
     'Check bit 6, then copy 13 bytes from XIY+0x40 to 0x34BC'),

    ('LABEL_F64E95', 'RhythmPatInit_KitIndexTable',
     'Data: kit count-to-index mapping table (20 bytes) + inline code'),

    # --- Rhythm fill-in select ---
    ('LABEL_F64F1F', 'RhythmFillIn_Wrapper',
     'Wrapper: push XIZ, call RhythmFillIn_Select, pop XIZ, ret'),

    ('LABEL_F64F26', 'RhythmFillIn_Select',
     'Select fill-in pattern: mask flags, lookup from F64F4D table, update status'),

    ('LABEL_F64F38', 'RhythmFillIn_LookupAndApply',
     'Lookup fill pattern value, store to 14235, update status flags'),

    ('LABEL_F64F4D', 'RhythmFillIn_PatternTable',
     'Data: fill-in pattern lookup table (8 bytes) + inline code'),

    # --- Rhythm mute toggle ---
    ('LABEL_F64F8D', 'RhythmMute_Wrapper',
     'Wrapper: push XIZ, call RhythmMute_Toggle, pop XIZ, ret'),

    ('LABEL_F64F94', 'RhythmMute_Toggle',
     'Toggle rhythm mute: calr to state machine'),

    ('LABEL_F64F98', 'RhythmMute_StateMachine',
     'Mute state machine: cycle 13531 through 0->1->4->8->0'),

    ('LABEL_F64FAF', 'RhythmMute_State1',
     'State check: 13531 == 1 -> set to 4'),

    ('LABEL_F64FBD', 'RhythmMute_State8',
     'State check: 13531 == 8 -> set to 1'),

    ('LABEL_F64FC9', 'RhythmMute_StateDone',
     'Return from mute state machine'),

    ('LABEL_F64FCA', 'RhythmMute_InlineCode',
     'Data/inline code: mute-related operations'),

    # --- Rhythm solo toggle ---
    ('LABEL_F65025', 'RhythmSolo_Wrapper',
     'Wrapper: push XIZ, calr to RhythmSolo_Toggle, pop XIZ, ret'),

    ('LABEL_F6502B', 'RhythmSolo_Toggle',
     'Toggle rhythm solo mode: flip bit 7 of 13553'),

    ('LABEL_F65038', 'RhythmSolo_Disable',
     'Solo mode was on: clear 13553 to 0'),

    ('LABEL_F6503D', 'RhythmSolo_UpdateStatus',
     'Update status flags and set auto-play bit if needed'),

    ('LABEL_F6504B', 'RhythmSolo_Return',
     'Return from solo toggle'),

    # --- Rhythm variation select ---
    ('LABEL_F6504C', 'RhythmVariation_Wrapper',
     'Wrapper: push XIZ, calr to RhythmVariation_Select, pop XIZ, ret'),

    ('LABEL_F65052', 'RhythmVariation_Select',
     'Select rhythm variation: check state bits in 13519, update 14235'),

    ('LABEL_F65088', 'RhythmVariation_PostDispatch',
     'Post-dispatch: call FDDEEF + FDDFA7'),

    ('LABEL_F65090', 'RhythmVariation_Return',
     'Return from variation select'),

    ('LABEL_F65091', 'RhythmVariation_InlineCode',
     'Data/inline code: variation-related operations'),

    ('LABEL_F65239', 'RhythmConfig_ReturnStub',
     'Return stub (single ret instruction)'),

    ('LABEL_F6523A', 'RhythmConfig_InlineCode2',
     'Data/inline code: rhythm config operations'),

    # --- Drum tempo adjust ---
    ('LABEL_F6524C', 'DrumTempo_Adjust',
     'Adjust drum tempo: increment/decrement 13632 with range clamping'),

    ('LABEL_F65271', 'DrumTempo_CheckMax',
     'Compare A to max (L), branch to done if at limit'),

    ('LABEL_F65279', 'DrumTempo_Decrement',
     'Decrement path: check if A==1 (minimum), dec if not'),

    ('LABEL_F6527F', 'DrumTempo_Store',
     'Store adjusted tempo value to 13632'),

    ('LABEL_F65283', 'DrumTempo_Done',
     'Return from tempo adjust'),

    # --- Drum voice select ---
    ('LABEL_F65286', 'DrumVoice_Select',
     'Select drum voice: clamp 13632, decrement, dispatch via table'),

    ('LABEL_F65293', 'DrumVoice_ClampMin',
     'Clamp voice index minimum to 1, decrement for 0-based dispatch'),

    ('LABEL_F6529A', 'DrumVoice_InlineStub',
     'Data/inline code stub before dispatch routine'),

    # ==================================================================
    # 2. Rhythm_SendByte region (lines ~162864-164260)
    #    Rhythm note processing: MIDI note transformation, transposition,
    #    velocity scaling, channel routing for drum/perc parts.
    # ==================================================================

    # --- Rhythm MIDI event processing ---
    ('LABEL_F54E04', 'RhythmEvt_ProcessNote',
     'Process rhythm MIDI event: check fill counter, verify phrase match, dispatch'),

    ('LABEL_F54E5D', 'RhythmEvt_AlternateProcess',
     'Alternate processing path: call via LABEL_F54ED8'),

    ('LABEL_F54E61', 'RhythmEvt_Return',
     'Return from rhythm event processing'),

    ('LABEL_F54E62', 'RhythmEvt_IterateNoteOn',
     'Iterate note-on events: load IY from (XHL+6), BC from (XHL+2)'),

    ('LABEL_F54E68', 'RhythmEvt_NoteOnLoop',
     'Note-on loop: compare position, read note, call processor'),

    ('LABEL_F54E8C', 'RhythmEvt_NoteOn90',
     'Note-on 0x90: call velocity lookup, advance, read next'),

    ('LABEL_F54E95', 'RhythmEvt_NoteOn91',
     'Note-on 0x91: call velocity lookup twice (multi-channel)'),

    ('LABEL_F54E9B', 'RhythmEvt_ApplyTranspose',
     'Apply transposition: read param, check velocity threshold, apply note correction'),

    ('LABEL_F54EB2', 'RhythmEvt_ApplyNoteRange',
     'Apply note range correction via LABEL_F55030'),

    ('LABEL_F54EB5', 'RhythmEvt_PostProcess',
     'Post-process: call LABEL_F552D1, advance position'),

    ('LABEL_F54ECB', 'RhythmEvt_SkipUnknown',
     'Skip unknown message type: restore IY, advance'),

    ('LABEL_F54ED7', 'RhythmEvt_IterDone',
     'Iteration complete: return'),

    ('LABEL_F54ED8', 'RhythmEvt_FullProcess',
     'Full rhythm event processing: handle 0x90, 0x91, and unknown types'),

    ('LABEL_F54EDE', 'RhythmEvt_FullLoop',
     'Full processing loop: compare position, dispatch by message type'),

    ('LABEL_F54F15', 'RhythmEvt_Full90_PostRange',
     'After note range correction for 0x90'),

    ('LABEL_F54F18', 'RhythmEvt_Full90_PostTransp',
     'After transposition for 0x90: apply velocity via LABEL_F55053'),

    ('LABEL_F54F2E', 'RhythmEvt_Full91',
     'Handle 0x91 (multi-channel note-on): read offset, velocity, apply transposition'),

    ('LABEL_F54F7D', 'RhythmEvt_Full91_PostRange',
     'After note range correction for 0x91'),

    ('LABEL_F54F80', 'RhythmEvt_Full91_PostTransp',
     'After transposition for 0x91: apply voice via LABEL_F551BD'),

    ('LABEL_F54F9F', 'RhythmEvt_FullSkip',
     'Skip unknown message: advance one position'),

    ('LABEL_F54FA6', 'RhythmEvt_FullDone',
     'Full processing done: return'),

    # --- Velocity threshold check ---
    ('LABEL_F54FA7', 'Rhythm_CheckVelocityThreshold',
     'Check velocity threshold: if A >= 0x78, set bit 4 in 13044'),

    ('LABEL_F54FB6', 'Rhythm_VelThreshReturn',
     'Return from velocity threshold check'),

    # --- Position advance (3-byte messages) ---
    ('LABEL_F54FB7', 'Rhythm_AdvancePosition',
     'Advance IY by 1; if past BC, wrap to (XHL+256)+2'),

    ('LABEL_F54FC4', 'Rhythm_AdvancePos_Step2',
     'Second step: advance again, wrap if past BC with +1 offset'),

    ('LABEL_F54FD1', 'Rhythm_AdvancePos_Step3',
     'Third step: advance again, wrap if past BC with +0 offset'),

    ('LABEL_F54FDA', 'Rhythm_AdvanceDone',
     'Return from position advance'),

    # --- Cross-voice note correction ---
    ('LABEL_F54FDB', 'Rhythm_CrossVoiceCorrect',
     'Cross-voice note correction: adjust note for split voice boundaries'),

    ('LABEL_F54FFE', 'Rhythm_CrossVoice_Apply',
     'Apply correction: compute modular note offset, set LABEL_F5515D params'),

    ('LABEL_F5502A', 'Rhythm_CrossVoice_ClearFlag',
     'Clear cross-voice flag (13043 bit 5)'),

    # --- Note range check ---
    ('LABEL_F55030', 'Rhythm_NoteRangeCheck',
     'Note range check: if bit 0 of 13015 set, apply instrument base correction'),

    ('LABEL_F55050', 'Rhythm_NoteRangeReturn',
     'Return from note range check'),

    ('LABEL_F55051', 'Rhythm_NoteRangeData',
     'Data: 2-byte padding'),

    # --- Velocity lookup (note-on 0x90 style) ---
    ('LABEL_F55053', 'Rhythm_VelocityLookup_A',
     'Velocity lookup type A: resolve velocity via table lookup + instrument base'),

    ('LABEL_F55065', 'Rhythm_VelLookA_CheckEmpty',
     'Check if instrument (13016) is empty (0): return 0 if so'),

    ('LABEL_F55074', 'Rhythm_VelLookA_CheckRange',
     'Check instrument range: if >= 0x30, reset to 0'),

    ('LABEL_F5507F', 'Rhythm_VelLookA_SelectTable',
     'Select velocity table: F550CA (default) or F550FB (bit 2 of 13044)'),

    ('LABEL_F5508F', 'Rhythm_VelLookA_CheckBit3',
     'Check bit 3 of 13044: select F5512C table'),

    ('LABEL_F5509A', 'Rhythm_VelLookA_TableLookup',
     'Look up velocity in selected instrument table, apply base'),

    ('LABEL_F550B8', 'Rhythm_VelLookA_Done',
     'Done: pop saved regs and return'),

    # --- Instrument base lookup ---
    ('LABEL_F550BB', 'Rhythm_InstrBaseLookup',
     'Look up instrument base note from table at E461C2'),

    ('LABEL_F550CA', 'Rhythm_InstrMapTable_Default',
     'Data: default instrument map table (48+48+48 bytes)'),

    # --- Note transposition ---
    ('LABEL_F5515D', 'Rhythm_TransposeNote',
     'Transpose note: apply instrument transpose from 13017/13018'),

    ('LABEL_F5516B', 'Rhythm_Transp_CheckZero',
     'Check if transpose is 0: return A=0 directly'),

    ('LABEL_F55173', 'Rhythm_Transp_Apply',
     'Apply transpose: dec, compare to threshold, add/subtract octave offset'),

    ('LABEL_F55185', 'Rhythm_Transp_JumpToWrap',
     'Jump to wrap check'),

    ('LABEL_F55187', 'Rhythm_Transp_NegativeOctave',
     'Negative octave path: subtract 12, add transpose'),

    ('LABEL_F55194', 'Rhythm_Transp_WrapCheck',
     'Wrap check: clamp to max range (13004) by subtracting 12'),

    ('LABEL_F5519B', 'Rhythm_Transp_WrapLoop',
     'Wrap loop: subtract 12 until within range'),

    ('LABEL_F551A6', 'Rhythm_Transp_FinalCheck',
     'Final check: apply octave-up correction if bit 0 of 13101 set'),

    ('LABEL_F551B7', 'Rhythm_Transp_Done',
     'Clear bit 0 of 13101 and return'),

    # --- Voice map lookup (note-on 0x91 style) ---
    ('LABEL_F551BD', 'Rhythm_VoiceMapLookup',
     'Voice map lookup type B: complex transposition with pitch shift tables'),

    ('LABEL_F551CB', 'Rhythm_VoiceMap_CheckInstr',
     'Check instrument (13016): if zero, return 0'),

    ('LABEL_F551D9', 'Rhythm_VoiceMap_CheckBit4',
     'Check bit 4 of 13044: if set, clear and return'),

    ('LABEL_F551E4', 'Rhythm_VoiceMap_ClampInstr',
     'Clamp instrument index to 0-0x2F range'),

    ('LABEL_F551F4', 'Rhythm_VoiceMap_SelectTable',
     'Select pitch shift table: F5526F (default) or F552A0 (bit 3)'),

    ('LABEL_F55209', 'Rhythm_VoiceMap_CheckMute',
     'Check mute bit 5 in pitch shift: if set, return 0'),

    ('LABEL_F55212', 'Rhythm_VoiceMap_CheckDir',
     'Check direction bit 4: positive (add) or negative (subtract) shift'),

    ('LABEL_F5521E', 'Rhythm_VoiceMap_SubShift',
     'Subtract pitch shift amount from note'),

    ('LABEL_F55223', 'Rhythm_VoiceMap_ApplyBase',
     'Apply instrument base: call LABEL_F550BB, then secondary table lookup'),

    ('LABEL_F55233', 'Rhythm_VoiceMap_Inst2Clamp',
     'Clamp instrument for secondary table'),

    ('LABEL_F55243', 'Rhythm_VoiceMap_Inst2Bit2',
     'Check bit 2 of 13044: select F550FB table for secondary lookup'),

    ('LABEL_F5524E', 'Rhythm_VoiceMap_Inst2Bit3',
     'Check bit 3 of 13044: select F5512C table for secondary lookup'),

    ('LABEL_F5526C', 'Rhythm_VoiceMap_Done',
     'Pop saved regs and return from voice map lookup'),

    ('LABEL_F5526F', 'Rhythm_PitchShiftTable_Default',
     'Data: default pitch shift table (48+48 bytes)'),

    # --- Note velocity computation (0x90 note-on post-process) ---
    ('LABEL_F552D1', 'Rhythm_VelocityCompute',
     'Compute final velocity: apply instrument map + base correction'),

    ('LABEL_F552E3', 'Rhythm_VelComp_CheckBit4',
     'Check bit 4 of 13044: if set, clear and return original'),

    ('LABEL_F552F2', 'Rhythm_VelComp_ClampInstr',
     'Clamp instrument for velocity table'),

    ('LABEL_F552FD', 'Rhythm_VelComp_SelectTable',
     'Select velocity table: F5532E or F5535F (bit 2)'),

    ('LABEL_F5530D', 'Rhythm_VelComp_Lookup',
     'Look up in selected table, apply base via LABEL_F5515D'),

    ('LABEL_F5532B', 'Rhythm_VelComp_Done',
     'Pop saved regs and return'),

    ('LABEL_F5532E', 'Rhythm_VelocityTable_A',
     'Data: velocity mapping table A (48+48 bytes)'),

    # --- Four-channel rhythm dispatch ---
    ('LABEL_F55390', 'Rhythm_FourChannelDispatch',
     'Dispatch rhythm across 4 channels: D7, D4, D5, D6'),

    ('LABEL_F5539D', 'Rhythm_DispatchCh_D7',
     'Channel D7: load params from 12995/12999, set mask, iterate 0x30F4-0x313C'),

    ('LABEL_F553BE', 'Rhythm_DispatchCh_D7_Loop',
     'D7 loop body: set mask 4, call LABEL_F55473, advance IX by 9'),

    ('LABEL_F553D5', 'Rhythm_DispatchCh_D4',
     'Channel D4: load from 12996/13000, iterate 0x313C-0x3184'),

    ('LABEL_F553F6', 'Rhythm_DispatchCh_D4_Loop',
     'D4 loop body: set mask 8, call LABEL_F55473, advance IX by 9'),

    ('LABEL_F5540D', 'Rhythm_DispatchCh_D5',
     'Channel D5: load from 12997/13001, iterate 0x3184-0x31CC'),

    ('LABEL_F55429', 'Rhythm_DispatchCh_D5_Loop',
     'D5 loop body: set mask 16, call LABEL_F55473, advance IX by 9'),

    ('LABEL_F55440', 'Rhythm_DispatchCh_D6',
     'Channel D6: load from 12998/13002, iterate 0x31CC-0x3214'),

    ('LABEL_F5545C', 'Rhythm_DispatchCh_D6_Loop',
     'D6 loop body: set mask 32, call LABEL_F55473, advance IX by 9'),

    # --- Single note event handler ---
    ('LABEL_F55473', 'Rhythm_SingleNoteHandler',
     'Handle single rhythm note: check bit 7 at (XIX), send status + note + velocity'),

    ('LABEL_F55496', 'Rhythm_SingleNote_ClampVelocity',
     'Clamp velocity: if (XIX+3)-0x10 <= 0, set to 1'),

    ('LABEL_F5549A', 'Rhythm_SingleNote_Return',
     'Return from single note handler (bit 7 was clear)'),

    # --- Rhythm send validation ---
    ('LABEL_F554B1', 'Rhythm_ValidateAndSend',
     'Validate rhythm before sending: check fill counter, phrase match, dispatch'),

    ('LABEL_F55509', 'Rhythm_Validate_Mismatch',
     'Phrase mismatch: call alternate handler'),

    ('LABEL_F5550C', 'Rhythm_Validate_Done',
     'Return from validation'),

    # --- Matched phrase handler ---
    ('LABEL_F5550D', 'Rhythm_MatchedPhrase',
     'Matched phrase: check 0x90 vs other, apply velocity + transposition'),

    ('LABEL_F5551A', 'Rhythm_MatchedPhrase_NonNote',
     'Non-note (not 0x90): use offset 8 for velocity source'),

    ('LABEL_F5551D', 'Rhythm_MatchedPhrase_Process',
     'Process: check velocity threshold, apply corrections'),

    ('LABEL_F5552F', 'Rhythm_MatchedPhrase_PostRange',
     'Post note-range correction: apply note output via LABEL_F55030'),

    ('LABEL_F55532', 'Rhythm_MatchedPhrase_Output',
     'Output: compute velocity via LABEL_F552D1, store to (XIX+2)'),

    # --- Mismatched phrase handler ---
    ('LABEL_F5553A', 'Rhythm_MismatchedPhrase',
     'Mismatched phrase: check 0x90, apply velocity + transposition differently'),

    ('LABEL_F55557', 'Rhythm_Mismatch90_PostRange',
     'Post range for 0x90 mismatch'),

    ('LABEL_F5555A', 'Rhythm_Mismatch90_Output',
     'Output for 0x90 mismatch: via LABEL_F55053'),

    ('LABEL_F55563', 'Rhythm_MismatchOther',
     'Non-0x90 mismatch: store offsets 3/6/7/8 to temp vars, apply transposition'),

    ('LABEL_F5558E', 'Rhythm_MismatchOther_PostRange',
     'Post range for other mismatch'),

    ('LABEL_F55591', 'Rhythm_MismatchOther_Output',
     'Output for other mismatch: via LABEL_F551BD, restore offset 3'),

    ('LABEL_F5559F', 'Rhythm_MismatchOther_Return',
     'Return from mismatch handler'),

    # --- MIDI send helpers (specific channels) ---
    ('LABEL_F555A0', 'Rhythm_Send_Ch90_7F_7E',
     'Send MIDI: channel 0x90, velocity 0x7F, CC 0x7E'),

    ('LABEL_F555AB', 'Rhythm_Send_Ch90_7F_04',
     'Send MIDI: channel 0x90, velocity 0x7F, CC 0x04'),

    ('LABEL_F555B6', 'Rhythm_Send_Ch90_7F_05',
     'Send MIDI: channel 0x90, velocity 0x7F, CC 0x05'),

    ('LABEL_F555C1', 'Rhythm_Send_Ch90_7F_06',
     'Send MIDI: channel 0x90, velocity 0x7F, CC 0x06'),

    ('LABEL_F555CC', 'Rhythm_Send_Ch90_7F_07',
     'Send MIDI: channel 0x90, velocity 0x7F, CC 0x07'),

    # --- Four-channel all-notes-off (zero velocity) ---
    ('LABEL_F555D7', 'Rhythm_AllNotesOff_Dispatch',
     'Dispatch all-notes-off across 4 channels (D7/D4/D5/D6)'),

    ('LABEL_F555E4', 'Rhythm_AllNotesOff_D7',
     'All-notes-off D7: if 13103 != 0, send (0xD7, 3, 0)'),

    ('LABEL_F555F5', 'Rhythm_AllNotesOff_D7_Skip',
     'Skip D7 (inactive)'),

    ('LABEL_F555F6', 'Rhythm_AllNotesOff_D4',
     'All-notes-off D4: if 13104 != 0, send (0xD4, 3, 0)'),

    ('LABEL_F55607', 'Rhythm_AllNotesOff_D4_Skip',
     'Skip D4 (inactive)'),

    ('LABEL_F55608', 'Rhythm_AllNotesOff_D5',
     'All-notes-off D5: if 13105 != 0, send (0xD5, 3, 0)'),

    ('LABEL_F55619', 'Rhythm_AllNotesOff_D5_Skip',
     'Skip D5 (inactive)'),

    ('LABEL_F5561A', 'Rhythm_AllNotesOff_D6',
     'All-notes-off D6: if 13106 != 0, send (0xD6, 3, 0)'),

    ('LABEL_F5562B', 'Rhythm_AllNotesOff_D6_Done',
     'Done (D6 inactive or sent)'),

    # --- Four-channel volume send ---
    ('LABEL_F5562C', 'Rhythm_SendVolume_Dispatch',
     'Dispatch volume send across 4 channels (D7/D4/D5/D6)'),

    ('LABEL_F55639', 'Rhythm_SendVolume_D7',
     'Volume D7: if 13103 != 0, send (0xD7, 3, vol)'),

    ('LABEL_F5564C', 'Rhythm_SendVolume_D7_Skip',
     'Skip D7 volume (inactive)'),

    ('LABEL_F5564D', 'Rhythm_SendVolume_D4',
     'Volume D4: if 13104 != 0, send (0xD4, 3, vol)'),

    ('LABEL_F55660', 'Rhythm_SendVolume_D4_Skip',
     'Skip D4 volume (inactive)'),

    ('LABEL_F55661', 'Rhythm_SendVolume_D5',
     'Volume D5: if 13105 != 0, send (0xD5, 3, vol)'),

    ('LABEL_F55674', 'Rhythm_SendVolume_D5_Skip',
     'Skip D5 volume (inactive)'),

    ('LABEL_F55675', 'Rhythm_SendVolume_D6',
     'Volume D6: if 13106 != 0, send (0xD6, 3, vol)'),

    ('LABEL_F55688', 'Rhythm_SendVolume_D6_Done',
     'Done (D6 volume inactive or sent)'),

    # --- Four-channel note-off max velocity ---
    ('LABEL_F55689', 'Rhythm_NoteOffMax_Dispatch',
     'Dispatch note-off max velocity across 4 channels'),

    ('LABEL_F55696', 'Rhythm_NoteOffMax_D7',
     'Note-off max D7: if 13103 != 0, send (0x90, 0x7F, 0x77)'),

    ('LABEL_F556A7', 'Rhythm_NoteOffMax_D7_Skip',
     'Skip D7 note-off max'),

    ('LABEL_F556A8', 'Rhythm_NoteOffMax_D4',
     'Note-off max D4: if 13104 != 0, send (0x90, 0x7F, 0x74)'),

    ('LABEL_F556B9', 'Rhythm_NoteOffMax_D4_Skip',
     'Skip D4 note-off max'),

    ('LABEL_F556BA', 'Rhythm_NoteOffMax_D5',
     'Note-off max D5: if 13105 != 0, send (0x90, 0x7F, 0x75)'),

    ('LABEL_F556CB', 'Rhythm_NoteOffMax_D5_Skip',
     'Skip D5 note-off max'),

    ('LABEL_F556CC', 'Rhythm_NoteOffMax_D6',
     'Note-off max D6: if 13106 != 0, send (0x90, 0x7F, 0x76)'),

    ('LABEL_F556DD', 'Rhythm_NoteOffMax_D6_Done',
     'Done (D6 note-off max)'),

    # --- Rhythm tick/position advance ---
    ('LABEL_F556DE', 'Rhythm_AdvanceTick',
     'Advance rhythm tick position: add 0x18, wrap at 0x60, increment beat counter'),

    ('LABEL_F55707', 'Rhythm_AdvanceTick_Store',
     'Store updated tick position'),

    # --- Rhythm state snapshot ---
    ('LABEL_F5570C', 'Rhythm_SaveState',
     'Save rhythm state: copy current params to shadow registers for later comparison'),

    ('LABEL_F5578B', 'Rhythm_SaveState_StoreBits',
     'Store computed status bits to 12931'),

    ('LABEL_F557A7', 'Rhythm_SaveState_CheckFx',
     'Check FX flags in 13067: check sustain/resonance bits'),

    ('LABEL_F557B6', 'Rhythm_SaveState_FxActive',
     'FX active: check if FX parameter (13094) is non-zero'),

    ('LABEL_F557CB', 'Rhythm_SaveState_ClearFx',
     'FX inactive: clear FX bits in 13094'),

    ('LABEL_F557D0', 'Rhythm_SaveState_CheckFx2',
     'Check second FX group (13065/13066)'),

    ('LABEL_F557E2', 'Rhythm_SaveState_Fx2Active',
     'FX2 active: check parameter (13095)'),

    ('LABEL_F557F3', 'Rhythm_SaveState_ClearFx2',
     'FX2 inactive: clear bits in 13095'),

    # --- Rhythm voice assign detection ---
    ('LABEL_F557F8', 'Rhythm_VoiceAssignDetect',
     'Detect voice on/off transitions for drum/perc parts A/B and ext'),

    ('LABEL_F55822', 'Rhythm_VoiceAssign_PartAOn',
     'Part A voice became active: post event (d=5, e=0x48)'),

    ('LABEL_F5585E', 'Rhythm_VoiceAssign_PartBDetect',
     'Detect part B voice transition'),

    ('LABEL_F55888', 'Rhythm_VoiceAssign_PartBOn',
     'Part B voice became active: post event'),

    ('LABEL_F558C4', 'Rhythm_VoiceAssign_Ext1Detect',
     'Detect ext1 voice transition (13078/13085)'),

    ('LABEL_F5590D', 'Rhythm_VoiceAssign_Ext2Detect',
     'Detect ext2 voice transition (13079/13086)'),

    ('LABEL_F55956', 'Rhythm_VoiceAssign_Ext3Detect',
     'Detect ext3 voice transition (13080/13087)'),

    ('LABEL_F5599F', 'Rhythm_VoiceAssign_Perc1Detect',
     'Detect perc1 voice transition (13076/13083)'),

    ('LABEL_F559CB', 'Rhythm_VoiceAssign_Perc2Detect',
     'Detect perc2 voice transition (13077/13084)'),

    ('LABEL_F559F7', 'Rhythm_VoiceAssign_SaveShadow',
     'Save current voice states to shadow registers for next comparison'),

    # --- Rhythm sequencer reset ---
    ('LABEL_F55A47', 'Rhythm_SeqResetCheck',
     'Check if rhythm sequencer needs reset: verify bits in 13519'),

    ('LABEL_F55A78', 'Rhythm_SeqReset_UpdateFlags',
     'Update sequencer flags: sync bit 4 from bit 2 in 13519'),

    ('LABEL_F55A87', 'Rhythm_SeqReset_Store',
     'Store updated flags to 13519'),

    ('LABEL_F55A8C', 'Rhythm_SeqResetTable',
     'Data: sequencer reset pointer table (80 bytes)'),

    # --- Rhythm transpose with modulation ---
    ('LABEL_F55AD0', 'Rhythm_TransposeWithMod',
     'Transpose with modulation: check instrument, apply mod table correction'),

    ('LABEL_F55AF3', 'Rhythm_TranspMod_ApplyBoth',
     'Apply both base transpose and modulation'),

    ('LABEL_F55AF9', 'Rhythm_TranspMod_Return',
     'Return from transpose with modulation'),

    ('LABEL_F55AFA', 'Rhythm_TranspMod_ModCheck',
     'Modulation check: look up pitch mod table F5526F, apply shift'),

    ('LABEL_F55B0A', 'Rhythm_TranspMod_LookupTable',
     'Look up modulation table entry for current instrument'),

    ('LABEL_F55B24', 'Rhythm_TranspMod_Offset1',
     'Modulation source 1: use 13286 for mod offset'),

    ('LABEL_F55B32', 'Rhythm_TranspMod_MuteCheck',
     'Check mute bit 5: if set, return 0 and set flag'),

    ('LABEL_F55B3E', 'Rhythm_TranspMod_SubOffset',
     'Subtract modulation offset (direction bit 4 set)'),

    ('LABEL_F55B43', 'Rhythm_TranspMod_Done',
     'Return from modulation check'),

    ('LABEL_F55B44', 'Rhythm_TranspMod_BaseApply',
     'Apply base transpose: lookup instrument base, compute via secondary table'),

    ('LABEL_F55B5B', 'Rhythm_TranspMod_BaseLookup',
     'Look up base note from F550FB table, apply E461C2 base'),

    ('LABEL_F55B7E', 'Rhythm_TranspMod_OctaveWrap',
     'Octave wrap: clamp transposed note within valid octave range'),

    ('LABEL_F55B92', 'Rhythm_TranspMod_WrapJump',
     'Jump to wrap loop'),

    ('LABEL_F55B94', 'Rhythm_TranspMod_WrapNeg',
     'Negative wrap: subtract 12, add back if still negative'),

    ('LABEL_F55BA1', 'Rhythm_TranspMod_WrapClamp',
     'Clamp loop: subtract 12 while > 0x7F'),

    ('LABEL_F55BAB', 'Rhythm_TranspMod_WrapDone',
     'Return final transposed note'),

    # ==================================================================
    # 3. SetWall_X region (lines ~83609-85530)
    #    Wallpaper/background style slot configuration:
    #    accompaniment style setup, AC slot management, pattern reading,
    #    event parsing, and bank switching.
    # ==================================================================

    # --- Data and init helpers ---
    ('LABEL_F1EE11', 'SetWall_JumpStubData',
     'Data: inline code/jump stub (19 bytes)'),

    ('LABEL_F1EE24', 'SetWall_UpdateSlotIndex',
     'Update slot index: read 3295, lookup via F1A0 table, store to 10355'),

    ('LABEL_F1EE3B', 'SetWall_InlineCodeBlock',
     'Data: inline code block (various set/check operations)'),

    # --- Wall select event handler ---
    ('LABEL_F1EF1C', 'SetWall_EventHandler',
     'Wall select event handler: check bit 2 of 1056, dispatch to slot change'),

    ('LABEL_F1EF26', 'SetWall_EventHandler_Active',
     'Active: read current slot, compare to stored 10355, branch on match'),

    ('LABEL_F1EF47', 'SetWall_EventHandler_Dispatch',
     'Dispatch by slot type: 0xD=panel, 0x10=list, 0xF=list, 0xE=search'),

    ('LABEL_F1EF62', 'SetWall_SearchForPanel',
     'Search for panel slot (0xE): iterate slots looking for 0xD'),

    ('LABEL_F1EF69', 'SetWall_SearchForPanel_Loop',
     'Search loop: compare slot to 0xD, increment IY'),

    ('LABEL_F1EF7D', 'SetWall_SearchForSearch',
     'Search for search slot (0xD): iterate looking for 0xE'),

    ('LABEL_F1EF84', 'SetWall_SearchForSearch_Loop',
     'Search loop: compare slot to 0xE, increment IY'),

    ('LABEL_F1EF96', 'SetWall_SearchSelf',
     'Search for self: iterate looking for current slot value'),

    ('LABEL_F1EF9D', 'SetWall_SearchSelf_Loop',
     'Self-search loop: compare to 10355, increment IY'),

    ('LABEL_F1EFB2', 'SetWall_MatchedSameSlot',
     'Matched same slot as current 3295: jump to copy if no change'),

    ('LABEL_F1EFBF', 'SetWall_NewSlotSelected',
     'New slot selected: set error 26, determine slot type, call event handler'),

    ('LABEL_F1EFEB', 'SetWall_DispatchSlotEvent',
     'Dispatch slot event: call LABEL_F994BD with slot type code'),

    ('LABEL_F1EFF3', 'SetWall_ToReturn',
     'Jump to return'),

    ('LABEL_F1EFF7', 'SetWall_CompareAndSwap',
     'Compare current vs new slot: lookup mappings, check compatibility'),

    ('LABEL_F1F033', 'SetWall_CopySlotData',
     'Copy slot data: store to 3297/4438, dispatch to handler'),

    ('LABEL_F1F05D', 'SetWall_DirectHandler',
     'Direct handler: call LABEL_F1F092 for slot without extended bank'),

    ('LABEL_F1F065', 'SetWall_IncompatibleSlot',
     'Incompatible slot: call LABEL_F1F413 for cross-type change'),

    ('LABEL_F1F069', 'SetWall_Return',
     'Return from wall select event'),

    ('LABEL_F1F06A', 'SetWall_InitCallSequences',
     'Init call sequences: multiple call chains for different startup modes'),

    # --- Slot setup routine ---
    ('LABEL_F1F092', 'SetWall_SlotSetup',
     'Slot setup: check bit 2 of 1056, initialize slot bank data'),

    ('LABEL_F1F09C', 'SetWall_SlotSetup_Active',
     'Active setup: call update helpers, store bank pointers, update slot index'),

    ('LABEL_F1F0E4', 'SetWall_SlotSetup_Return',
     'Return from slot setup'),

    ('LABEL_F1F0E5', 'SetWall_SlotUpdate',
     'Slot update: check bit 2, update slot references'),

    ('LABEL_F1F0EF', 'SetWall_SlotUpdate_Active',
     'Active update: call update helpers, refresh slot index'),

    ('LABEL_F1F0FB', 'SetWall_SlotUpdate_Return',
     'Return from slot update'),

    ('LABEL_F1F0FC', 'SetWall_DataBlock1',
     'Data: config parameters (18 bytes)'),

    # --- AC slot change dispatcher ---
    ('LABEL_F1F10E', 'SetWall_ACSlotChange',
     'AC slot change: check slot 10 (all), compare to stored value'),

    ('LABEL_F1F120', 'SetWall_ACSlot_CheckPanel',
     'Check panel bit: bit 2 of 64941, check slot 3390==3'),

    ('LABEL_F1F138', 'SetWall_ACSlot_NoPanel',
     'No panel: check slot count 3390==3 for direct/normal path'),

    ('LABEL_F1F14A', 'SetWall_ACSlot_Direct',
     'Direct path: check extended bank (0x0340EA), call appropriate handler'),

    ('LABEL_F1F15A', 'SetWall_ACSlot_DirectLocal',
     'Direct local: call LABEL_F1F2EB for local slot change'),

    ('LABEL_F1F162', 'SetWall_ACSlot_PanelChange',
     'Panel change: check extended bank, call appropriate handler'),

    ('LABEL_F1F172', 'SetWall_ACSlot_PanelLocal',
     'Panel local: call LABEL_F1F2EB for local panel change'),

    ('LABEL_F1F17A', 'SetWall_ACSlot_IndexChange',
     'Index change: call LABEL_F1F193, jump to finalize'),

    ('LABEL_F1F182', 'SetWall_ACSlot_NormalChange',
     'Normal change: call LABEL_F1F239'),

    ('LABEL_F1F18A', 'SetWall_ACSlot_AllChange',
     'All-slot change (slot 10): call LABEL_F1F246'),

    ('LABEL_F1F18E', 'SetWall_ACSlot_PostFinalize',
     'Post-finalize: call LABEL_F22BC4'),

    ('LABEL_F1F192', 'SetWall_ACSlot_Return',
     'Return from AC slot change'),

    # --- Single slot data write ---
    ('LABEL_F1F193', 'SetWall_WriteSingleSlot',
     'Write single slot: save 10360, call voice assign, copy 16 bytes to tone gen'),

    ('LABEL_F1F1EA', 'SetWall_WriteSingle_SetMode',
     'Set mode byte: 0x00 (default) or 0xFF (slot 3)'),

    # --- Multi-slot write wrapper ---
    ('LABEL_F1F239', 'SetWall_WriteSlotAndSync',
     'Write slot data + sync: call WriteSingleSlot, LABEL_F2021A, LABEL_FC9E29'),

    # --- All-slot write (slot 10 / "all") ---
    ('LABEL_F1F246', 'SetWall_WriteAllSlots',
     'Write all slots: init banks, iterate 10 slots, copy data to tone gen'),

    ('LABEL_F1F266', 'SetWall_WriteAll_Loop',
     'All-slot loop: compute tone gen address, copy 16 bytes, set mode, set 0xFFFF marker'),

    ('LABEL_F1F2A7', 'SetWall_WriteAll_ModeSet',
     'Mode byte: 0x00 or 0xFF (slot 3)'),

    ('LABEL_F1F2E5', 'SetWall_NopPadding',
     'Data: 6 bytes NOP/ret padding'),

    # --- Local slot change handler ---
    ('LABEL_F1F2EB', 'SetWall_LocalSlotChange',
     'Local slot change: check slot 10 for all-slot path vs single'),

    ('LABEL_F1F2FA', 'SetWall_LocalSingle',
     'Single local slot: call LABEL_F1F303'),

    ('LABEL_F1F2FE', 'SetWall_LocalFinalize',
     'Finalize local change: call LABEL_F22BC4'),

    ('LABEL_F1F303', 'SetWall_LocalSingle_Exec',
     'Execute single local change: write + sync'),

    # --- Local all-slot write ---
    ('LABEL_F1F310', 'SetWall_LocalWriteAll',
     'Local all-slot write: init banks, iterate 10 slots with local data'),

    ('LABEL_F1F330', 'SetWall_LocalWriteAll_Loop',
     'Local all-slot loop: copy 16 bytes, set mode, set 0xFFFF, iterate'),

    ('LABEL_F1F371', 'SetWall_LocalWriteAll_Mode',
     'Mode byte for local all-slot write'),

    ('LABEL_F1F3AF', 'SetWall_ExternalSync',
     'External sync: call LABEL_F2298B'),

    ('LABEL_F1F3B4', 'SetWall_InlineCodeBlock2',
     'Data: inline code block (95 bytes)'),

    # --- Cross-type slot change (incompatible slot) ---
    ('LABEL_F1F413', 'SetWall_CrossTypeChange',
     'Cross-type slot change: read old/new types, dispatch to LABEL_F1F45B'),

    ('LABEL_F1F447', 'SetWall_SlotTypeMap',
     'Data: slot type mapping table (20 bytes, maps slot index to type ID)'),

    ('LABEL_F1F45B', 'SetWall_CrossType_Validate',
     'Validate cross-type: range-check slot (0-15) and type (0-19), compare'),

    ('LABEL_F1F4B8', 'SetWall_CrossType_ClearBit0',
     'Clear bit 0 of 10361 (source is not type 0xC)'),

    ('LABEL_F1F4BD', 'SetWall_CrossType_CheckDest',
     'Check if dest type is 0xC: set bit 1 of 10361 if so'),

    ('LABEL_F1F4CB', 'SetWall_CrossType_ClearBit1',
     'Clear bit 1 of 10361 (dest is not type 0xC)'),

    ('LABEL_F1F4D0', 'SetWall_CrossType_MapLookup',
     'Map lookup: translate type via F1F447, check 0xFF (invalid)'),

    ('LABEL_F1F4FC', 'SetWall_CrossType_Reset',
     'Reset: call LABEL_F41803, clear bits in 10361'),

    ('LABEL_F1F50A', 'SetWall_SlotOrderTable',
     'Data: slot order mapping tables (3x16 bytes for 3 modes)'),

    # --- Slot bit-field management ---
    ('LABEL_F1F53A', 'SetWall_SlotBitUpdate',
     'Update slot bit-field: read/set/clear bit for current slot in FFEC'),

    # --- Pattern stream parser ---
    ('LABEL_F1F558', 'SetWall_ParsePatternStream',
     'Parse pattern stream: iterate through stream events, dispatch by type'),

    ('LABEL_F1F57C', 'SetWall_ParseStream_Init',
     'Init parser: load stream pointer (4349), save state'),

    ('LABEL_F1F5A0', 'SetWall_ParseStream_MainLoop',
     'Main parser loop: read byte, dispatch by type (0x82/0x81/0x80/0xD2/0xD1/etc.)'),

    ('LABEL_F1F5E8', 'SetWall_ParseStream_Advance',
     'Advance stream: call LABEL_F1F805, check error, loop or exit'),

    ('LABEL_F1F5F6', 'SetWall_ParseStream_CheckD1D2',
     'Check D1/D2 type: test bit 0 of 10361 for skip condition'),

    ('LABEL_F1F5FC', 'SetWall_ParseStream_ReadEvent',
     'Read event: load from stream (10369), call LABEL_F1F838, advance'),

    ('LABEL_F1F63A', 'SetWall_ParseStream_TypeC0',
     'Handle type 0xC0: program change / bank select event'),

    ('LABEL_F1F67C', 'SetWall_ParseStream_TypeC0_Loop',
     'C0 loop: iterate program change bytes with slot override'),

    ('LABEL_F1F67E', 'SetWall_ParseStream_C0_Iter',
     'C0 iteration: check counter, apply slot override for byte 2'),

    ('LABEL_F1F686', 'SetWall_ParseStream_C0_Read',
     'C0 read: get event from stream, write to output, advance'),

    ('LABEL_F1F6CA', 'SetWall_ParseStream_TypeB0',
     'Handle type 0xB0: control change event, parse CC bytes'),

    ('LABEL_F1F6E2', 'SetWall_ParseStream_B0_ShiftLoop',
     'B0 shift loop: shift 6 times for CC bit extraction'),

    ('LABEL_F1F730', 'SetWall_ParseStream_B0_Iter',
     'B0 iteration: process CC bytes with conditional modifications'),

    ('LABEL_F1F732', 'SetWall_ParseStream_B0_ByteLoop',
     'B0 byte loop: check counter, apply modifications per byte index'),

    ('LABEL_F1F741', 'SetWall_ParseStream_B0_Byte1',
     'B0 byte 1: check specific CC numbers (181-183) for skip'),

    ('LABEL_F1F75E', 'SetWall_ParseStream_B0_Byte3',
     'B0 byte 3: check bit 1 of 4393, load fallback from 3388'),

    ('LABEL_F1F76E', 'SetWall_ParseStream_B0_Byte4',
     'B0 byte 4: check 3387 != 0xFF, apply if not'),

    ('LABEL_F1F783', 'SetWall_ParseStream_B0_Write',
     'B0 write: store CC byte to output stream, advance'),

    # --- Stream end handler ---
    ('LABEL_F1F7C6', 'SetWall_ParseStream_End',
     'Stream end (0x82): store final values, call setup + advance routines'),

    ('LABEL_F1F7E1', 'SetWall_ParseStream_Return',
     'Return from pattern stream parser'),

    # --- Parser state init ---
    ('LABEL_F1F7E2', 'SetWall_ParserInit',
     'Initialize parser state: set counters, load stream pointers'),

    # --- Stream position advance ---
    ('LABEL_F1F805', 'SetWall_AdvanceStreamPos',
     'Advance stream read position (IY): check bounds, wrap or set error'),

    ('LABEL_F1F835', 'SetWall_AdvanceStream_Reset',
     'Reset IY to 5 (beginning of data)'),

    ('LABEL_F1F837', 'SetWall_AdvanceStream_Return',
     'Return from stream advance'),

    # --- Stream write position advance ---
    ('LABEL_F1F838', 'SetWall_AdvanceWritePos',
     'Advance stream write position (IX): save state, check bounds'),

    ('LABEL_F1F865', 'SetWall_AdvanceWrite_Reset',
     'Reset IX: store new pointer, set IX to 5'),

    ('LABEL_F1F86B', 'SetWall_AdvanceWrite_Return',
     'Restore state and return'),

    # --- Skip C0 events scanner ---
    ('LABEL_F1F871', 'SetWall_SkipC0Scanner',
     'Scan stream for C0 (program change): advance twice, read, check length > 0'),

    ('LABEL_F1F8B2', 'SetWall_SkipC0_Return',
     'Return from C0 scanner'),

    # --- B0 control change parser ---
    ('LABEL_F1F8B3', 'SetWall_ParseB0ControlChange',
     'Parse B0 control change: extract CC number, check type 0x48, handle bank/mode'),

    ('LABEL_F1F947', 'SetWall_B0CC_BankSelect',
     'Bank select detected: set flag 10397 bit 0, store to 3388'),

    ('LABEL_F1F958', 'SetWall_B0CC_ClearFlags',
     'Clear bank flags (10397 bits 0-2)'),

    ('LABEL_F1F963', 'SetWall_B0CC_Type48',
     'CC type 0x48: special drum channel processing'),

    ('LABEL_F1F9BD', 'SetWall_B0CC_Type48_SetFlag',
     'Set CC flag: OR 4 into 10397'),

    ('LABEL_F1F9C4', 'SetWall_B0CC_Type48_Check12',
     'Check CC type 12: clear bit, compare to slot 0x0C'),

    ('LABEL_F1F9E3', 'SetWall_B0CC_Return',
     'Return from B0 CC parser'),

    # --- Event output to slot ---
    ('LABEL_F1F9E4', 'SetWall_EventOutput',
     'Output event to slot: write index, store write position to tables'),

    # --- Event advance check ---
    ('LABEL_F1FA3E', 'SetWall_EventAdvanceCheck',
     'Check event advance: verify not past end, call sync if needed'),

    ('LABEL_F1FA62', 'SetWall_EventAdvance_Sync',
     'Sync: load IY from 10402, call LABEL_F22BFB'),

    ('LABEL_F1FA6C', 'SetWall_EventAdvance_Return',
     'Return from event advance check'),

    # --- Slot resolve and iterate ---
    ('LABEL_F1FA6D', 'SetWall_SlotResolve',
     'Resolve slot: find pattern bank, load stream pointer, iterate events'),

    ('LABEL_F1FA83', 'SetWall_SlotResolve_Init',
     'Init: set IY=5, save stream pointer, begin event scanning'),

    ('LABEL_F1FAAB', 'SetWall_SlotResolve_CheckDone',
     'Check if iteration complete: compare DE to target count (10367)'),

    ('LABEL_F1FAB7', 'SetWall_SlotResolve_ScanNext',
     'Scan next: call LABEL_F1FE17 to skip forward, check error'),

    ('LABEL_F1FAC8', 'SetWall_SlotResolve_FoundMatch',
     'Found match: store IX to 3383, save state, call LABEL_F1FE5D'),

    ('LABEL_F1FAFB', 'SetWall_SlotResolve_Return',
     'Return from slot resolve'),

    # --- Stream index resolve ---
    ('LABEL_F1FAFC', 'SetWall_StreamIndexResolve',
     'Resolve stream index: compute pointer from slot HL into bank (4349)'),

    # --- Bank init ---
    ('LABEL_F1FB0E', 'SetWall_BankInit',
     'Initialize AC bank: set up 0x110A block, resolve streams, init slot tables'),

    ('LABEL_F1FB39', 'SetWall_BankInit_SlotLoop',
     'Slot init loop: clear bit 7, set positions, mark 0x82 end, link to next'),

    ('LABEL_F1FB6A', 'SetWall_BankInit_ClearF250',
     'Clear F250 table (16 entries): set bit 7 = 0, set position = 0xFFFF'),

    ('LABEL_F1FB83', 'SetWall_BankInit_ClearC9E',
     'Clear 0xC9E table (16 entries): set all to 0xFFFF'),

    ('LABEL_F1FB94', 'SetWall_BankInit_FillCAE',
     'Fill 0xCAE table (16 entries): set all to 5'),

    ('LABEL_F1FBA4', 'SetWall_BankInit_ClearF1F8',
     'Clear F1F8 table (16 entries): set all to 0xFFFF'),

    ('LABEL_F1FBB5', 'SetWall_BankInit_FillF218',
     'Fill F218 table (16 entries): set all to 5'),

    # --- Full reset (all 10 slots) ---
    ('LABEL_F1FBBE', 'SetWall_FullReset',
     'Full slot reset: clear all 10 tone gen slots, reset tables'),

    ('LABEL_F1FBC0', 'SetWall_FullReset_SlotLoop',
     'Slot reset loop: compute tone gen address, clear data, init fields'),

    ('LABEL_F1FBE3', 'SetWall_FullReset_VoiceLoop',
     'Voice clear loop: write 0 + 0xFFFF for each voice (48 entries)'),

    ('LABEL_F1FC06', 'SetWall_FullReset_ClearNotes',
     'Clear note table (16 entries): write 0xFFFF'),

    ('LABEL_F1FC17', 'SetWall_FullReset_ClearCtrl',
     'Clear control table (16 entries): set default (5)'),

    ('LABEL_F1FC57', 'SetWall_FullReset_ClearGlobal1',
     'Clear global table 1 (CEF, 16 entries)'),

    ('LABEL_F1FC64', 'SetWall_FullReset_ClearGlobal2',
     'Clear global table 2 (D0F, 16 entries)'),

    # --- Single slot resolve ---
    ('LABEL_F1FC80', 'SetWall_SingleSlotResolve',
     'Resolve single slot: check if F250 entry is valid, load position'),

    ('LABEL_F1FC9F', 'SetWall_SingleSlot_LoadPos',
     'Load position: read from F250+1, check bounds'),

    ('LABEL_F1FCBA', 'SetWall_SingleSlot_InvalidPos',
     'Invalid position (0xFFFF): set error 2'),

    ('LABEL_F1FCC7', 'SetWall_SingleSlot_CheckBounds',
     'Check bounds: compare to 10402, set error 10 if exceeded'),

    ('LABEL_F1FCDE', 'SetWall_SingleSlot_Return',
     'Return from single slot resolve'),

    # --- Dual-pass event scanner ---
    ('LABEL_F1FCDF', 'SetWall_DualPassScanner',
     'Dual-pass event scanner: first pass reads headers, second resolves data'),

    ('LABEL_F1FD13', 'SetWall_DualPass_InitLoop',
     'Init: save stream pointer (4349) to 10383, set IY=5'),

    ('LABEL_F1FD21', 'SetWall_DualPass_MainLoop',
     'Main scan loop: read byte, dispatch by type (0xC0/0x82/0x84/0x81)'),

    ('LABEL_F1FD54', 'SetWall_DualPass_TypeC0',
     'Handle type 0xC0: extract bank/mode bits, scan program change bytes'),

    ('LABEL_F1FDFA', 'SetWall_DualPass_Type81',
     'Handle type 0x81: call LABEL_F1FFF7'),

    ('LABEL_F1FE00', 'SetWall_DualPass_Error',
     'Error in scan: set error=0, restore default, set flag bit 5'),

    ('LABEL_F1FE12', 'SetWall_DualPass_Done',
     'Done: pop saved context and return'),

    # --- Event skip (forward scan) ---
    ('LABEL_F1FE17', 'SetWall_SkipEvents',
     'Skip events: advance past C events until target count reached'),

    ('LABEL_F1FE19', 'SetWall_SkipEvents_CheckCount',
     'Check count: compare C to target B'),

    ('LABEL_F1FE1D', 'SetWall_SkipEvents_ReadLoop',
     'Read loop: read byte, check for 0x84 (reset) or 0x82 (end) or 0x81 (count)'),

    ('LABEL_F1FE30', 'SetWall_SkipEvents_EndMarker',
     'End marker (0x84/0x82): set error 8'),

    ('LABEL_F1FE37', 'SetWall_SkipEvents_CheckEnd',
     'Check 0x81: if not, advance stream and loop'),

    ('LABEL_F1FE49', 'SetWall_SkipEvents_IncCount',
     'Increment skip counter C, advance stream'),

    ('LABEL_F1FE58', 'SetWall_SkipEvents_Return',
     'Return from skip events (add BC to IX)'),

    # --- Replay event scanner ---
    ('LABEL_F1FE5D', 'SetWall_ReplayScanner',
     'Replay event scanner: re-scan from saved position for event data'),

    ('LABEL_F1FE7D', 'SetWall_Replay_MainLoop',
     'Replay main loop: read byte, dispatch by type'),

    ('LABEL_F1FE99', 'SetWall_Replay_Type84',
     'Handle type 0x84: reset IY=5, reload pointer from 10383'),

    ('LABEL_F1FEBF', 'SetWall_Replay_TypeC0',
     'Handle type 0xC0: extract bank bits, advance through CC bytes'),

    ('LABEL_F1FEE3', 'SetWall_Replay_C0_Byte2',
     'C0 advance byte 2: check error'),

    ('LABEL_F1FEF6', 'SetWall_Replay_C0_Byte3',
     'C0 advance byte 3: check error'),

    ('LABEL_F1FF09', 'SetWall_Replay_C0_Byte4',
     'C0 advance byte 4: check error'),

    ('LABEL_F1FF1B', 'SetWall_Replay_C0_ReadBank',
     'Read bank: combine with mode bits, advance'),

    ('LABEL_F1FF3E', 'SetWall_Replay_C0_ReadCC',
     'Read CC byte: call LABEL_F532ED for voice dispatch'),

    ('LABEL_F1FF7E', 'SetWall_Replay_Type81',
     'Handle type 0x81: call LABEL_F1FFF7 to skip forward'),

    ('LABEL_F1FF82', 'SetWall_Replay_Done',
     'Done: pop context, clear error, return'),

    # --- Panel control send ---
    ('LABEL_F1FF8C', 'SetWall_SendPanelCtrl',
     'Send panel control: clear bit in 64941, post event (0x91, d=3, w=1)'),

    # --- Stream pointer resolve ---
    ('LABEL_F1FF9E', 'SetWall_ResolveStreamPtr',
     'Resolve stream pointer: compute from IY-1 * 256 + bank offset (4362)'),

    # --- Stream advance with bounds check ---
    ('LABEL_F1FFB2', 'SetWall_StreamAdvanceBounded',
     'Advance stream IY with full bounds checking: wrap, error on overflow'),

    ('LABEL_F1FFCE', 'SetWall_StreamAdv_CheckBounds',
     'Bounds check: compare to 10402, error 10 if exceeded'),

    ('LABEL_F1FFDB', 'SetWall_StreamAdv_LoadNext',
     'Load next: store position (10415), resolve pointer, check bit 7'),

    ('LABEL_F1FFF4', 'SetWall_StreamAdv_Reset',
     'Reset IY to 5'),

    ('LABEL_F1FFF6', 'SetWall_StreamAdv_Return',
     'Return from bounded stream advance'),

    # --- Forward skip (type 0x81) ---
    ('LABEL_F1FFF7', 'SetWall_ForwardSkip',
     'Forward skip: iterate stream, compare target, handle 0x82/0x84/0x81 markers'),

    ('LABEL_F1FFF9', 'SetWall_ForwardSkip_Loop',
     'Forward skip loop: check target vs current'),

    ('LABEL_F20012', 'SetWall_ForwardSkip_CheckType',
     'Check byte type: 0x82/0x84 = end, 0x81 = count, else advance'),

    ('LABEL_F2002F', 'SetWall_ForwardSkip_Type84',
     'Type 0x84: reset IY=5, reload pointer from 10383'),

    ('LABEL_F2003B', 'SetWall_ForwardSkip_Type81',
     'Type 0x81: increment C, advance stream'),

    ('LABEL_F2004A', 'SetWall_ForwardSkip_TargetFound',
     'Target found: check for 0x82 end marker'),

    ('LABEL_F2005D', 'SetWall_ForwardSkip_Check84',
     'Check 0x84: reset IY/pointer if so'),

    ('LABEL_F2006B', 'SetWall_ForwardSkip_SaveState',
     'Save state: store IY/pointer to 10391/10395'),

    ('LABEL_F2007B', 'SetWall_ForwardSkip_Error',
     'Error: set flag bit 5 in 10363, clear error'),

    ('LABEL_F20085', 'SetWall_ForwardSkip_Return',
     'Return from forward skip'),

    ('LABEL_F20086', 'SetWall_InlineCodeBlock3',
     'Data: inline code block (various operations)'),

    # --- Tone gen data load ---
    ('LABEL_F200D5', 'SetWall_LoadToneGenData',
     'Load tone gen data: call bank resolve, set tone gen index, sync to AB000'),

    ('LABEL_F200ED', 'SetWall_RetStub1',
     'Return stub (single ret)'),

    ('LABEL_F200EE', 'SetWall_RetStub2',
     'Return stub (single ret)'),

    ('LABEL_F200EF', 'SetWall_MiscDataAndCode',
     'Data: misc code + data block'),

    # --- Tone gen sync to DRAM ---
    ('LABEL_F2021A', 'SetWall_SyncToneGenToDRAM',
     'Sync tone gen to DRAM: copy 0x800 bytes from F180 to AB000, update pointers'),

    ('LABEL_F2026C', 'SetWall_Sync_CheckPanelBit',
     'Check panel bit: compare 62013 for panel state change notification'),

    ('LABEL_F20286', 'SetWall_Sync_PanelOff',
     'Panel off: check bit 2 of 64941, set flag, post event'),

    ('LABEL_F20293', 'SetWall_Sync_PostEvent',
     'Post sync event: (0x91, d=3, w=4), call voice update helpers'),

    ('LABEL_F202A6', 'SetWall_Sync_FinalUpdate',
     'Final update: call FDB57F, F3C903, FDDE6F for full refresh'),

    ('LABEL_F202C7', 'SetWall_LoadBankToToneGen',
     'Load AC bank data to tone gen: copy from AB000 to internal DRAM tables'),
]

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    src = os.path.join(base, 'maincpu', 'kn5000_v10_program.s')

    with open(src, 'rb') as f:
        content = f.read().decode('latin-1')

    renamed = 0
    for old_label, new_label, comment in RENAMES:
        refs = len(re.findall(r'\b' + re.escape(old_label) + r'\b', content))
        if refs == 0:
            print(f'  WARNING: {old_label} not found, skipping')
            continue
        content = re.sub(r'\b' + re.escape(old_label) + r'\b', new_label, content)
        renamed += 1
        print(f'  {old_label:25s} -> {new_label:45s} ({refs} refs)')

    with open(src, 'wb') as f:
        f.write(content.encode('latin-1'))

    print(f'\nRenamed {renamed} labels in maincpu')


if __name__ == '__main__':
    main()
