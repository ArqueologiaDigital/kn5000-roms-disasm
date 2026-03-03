#!/usr/bin/env python3
"""Rename LABEL_* to semantic names in kn5000_v10_program.s (DSP/sound param functions).

Covers two major function regions:

  1. SoundParam_NotifyChange (FCD256-FCF10E, ~277 labels)
     Sound parameter hash table lookup, UI notification dispatch,
     widget callback routing, parameter registration/deregistration,
     hash table management. Also includes preceding MIDI stream
     processing functions (FCC583-FCCB1C) that feed into the
     notification system.

  2. Audio_ConfigureDSP (FDBD89-FDC145, ~191 labels)
     DSP configuration setup, compressor interface input processing,
     DSP state bit management (reverb/chorus/EQ enable/disable),
     volume control, and DSP register parameter decode helpers.

Each rename was determined by analyzing instruction sequences, register
usage, called functions, memory addresses, and control flow patterns.

Uses binary I/O to handle Latin-1 encoding safely.
NEVER use the Edit tool on kn5000_v10_program.s -- it corrupts Latin-1.
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
    # MIDI Stream Processing (FCC583 - FCCB1C)
    # Processes incoming MIDI parameter changes from serial/buffer,
    # dispatches to sound param notification system.
    # ==================================================================
    ('LABEL_FCC583', 'MidiStream_ApplyPendingParams',
     'Apply pending MIDI param changes if not in special mode'),
    ('LABEL_FCC5AA', 'MidiStream_CallFilterAndAudio',
     'Call filter FCA153 and audio config FCA390'),
    ('LABEL_FCC5B2', 'MidiStream_ApplyDone',
     'Return point after MIDI param application'),
    ('LABEL_FCC5B3', 'MidiStream_DispatchData',
     '.byte block: MIDI stream dispatch logic'),

    ('LABEL_FCC75E', 'MidiStream_LoadAllPresets',
     'Load all preset types: B3 voices, B2 voices, B1 multi, pedal'),
    ('LABEL_FCC77C', 'MidiStream_LoadVoicePreset',
     'Loop 0x1F voice slots, load single-byte preset if bit7 set'),
    ('LABEL_FCC77E', 'MidiStream_LoadVoiceLoop',
     'Inner loop: read byte from IY table, check dirty bit'),
    ('LABEL_FCC7AA', 'MidiStream_LoadVoiceNext',
     'Advance to next voice slot in preset load loop'),
    ('LABEL_FCC7B2', 'MidiStream_LoadBankSelect',
     'Load bank select preset (IY+0x94F2), notify FCA2D9'),
    ('LABEL_FCC7E7', 'MidiStream_LoadBankDone',
     'Return after bank select load'),
    ('LABEL_FCC7E8', 'MidiStream_LoadMultiPartPreset',
     'Loop 0x1F multi-part slots, load 16-bit B1 presets'),
    ('LABEL_FCC7F1', 'MidiStream_LoadMultiLoop',
     'Inner loop: read word, check dirty bit7, write to FCA179'),
    ('LABEL_FCC816', 'MidiStream_LoadMultiNext',
     'Advance to next multi-part slot'),
    ('LABEL_FCC820', 'MidiStream_LoadPedalPreset',
     'Loop 0x1F pedal slots, load pedal controller presets'),
    ('LABEL_FCC827', 'MidiStream_LoadPedalLoop',
     'Inner loop: read pedal byte, check dirty, call FCA222+FCA153'),
    ('LABEL_FCC84E', 'MidiStream_LoadPedalNext',
     'Advance to next pedal slot'),

    ('LABEL_FCC856', 'MidiStream_ProcessRxBuffer',
     'Process incoming MIDI data from serial receive buffer'),
    ('LABEL_FCC868', 'MidiStream_DispatchLoop',
     'Loop reading MIDI data bytes, dispatch by status via jump table'),
    ('LABEL_FCC8AD', 'MidiStream_AdvanceRxPtr',
     'Increment receive buffer read pointer by 4'),
    ('LABEL_FCC8B3', 'MidiStream_ProcessDone',
     'Return from MIDI receive buffer processing'),
    ('LABEL_FCC8B4', 'MidiStream_StatusPrecheck',
     '.byte block: validate MIDI status before dispatch'),
    ('LABEL_FCC8CC', 'MidiStream_StatusJumpTable',
     'Jump table for MIDI status byte dispatch (12 entries)'),
    ('LABEL_FCC8FC', 'MidiStream_HandleNoteCC',
     'Handle note/CC MIDI messages: indexed lookup, FCA3F6, FCA450'),
    ('LABEL_FCC938', 'MidiStream_PostNoteCC',
     'Post-processing after note/CC: read data, call FCA1FE'),
    ('LABEL_FCC948', 'MidiStream_HandleNoteCC_Ret',
     'Return from note/CC handler'),
    ('LABEL_FCC949', 'MidiStream_HandlePgmChange',
     '.byte block: handle MIDI program change (status 0xC0)'),
    ('LABEL_FCC971', 'MidiStream_HandleChanPressure',
     '.byte block: handle MIDI channel pressure (status 0xD0)'),
    ('LABEL_FCC9AB', 'MidiStream_HandleSysMsg',
     '.byte block: handle MIDI system messages'),

    ('LABEL_FCC9E2', 'MidiStream_SysExJumpTable',
     'Jump table for SysEx sub-dispatch (4 entries)'),
    ('LABEL_FCC9F2', 'MidiStream_SysExNop',
     'SysEx handler: return immediately'),
    ('LABEL_FCC9F3', 'MidiStream_SysExData',
     '.byte block: SysEx data handler'),
    ('LABEL_FCCA24', 'MidiStream_CtrlJumpTable',
     'Jump table for controller sub-dispatch (2 entries)'),
    ('LABEL_FCCA2C', 'MidiStream_CtrlNop',
     'Controller handler: return immediately'),
    ('LABEL_FCCA2D', 'MidiStream_CtrlData',
     '.byte block: controller data handler'),
    ('LABEL_FCCA5D', 'MidiStream_CmdJumpTable',
     'Jump table for command sub-dispatch (12 entries)'),
    ('LABEL_FCCA8D', 'MidiStream_CmdNop',
     'Command handler: return immediately'),
    ('LABEL_FCCA8E', 'MidiStream_CmdMaskedNotify',
     'Command handler: D/E bit masking then call FCA1FE'),
    ('LABEL_FCCAA4', 'MidiStream_CmdMaskedDone',
     'Return from masked command handler'),
    ('LABEL_FCCAA5', 'MidiStream_CmdPedalNotify',
     'Command handler: pedal state, dec E, call FCA1FE'),
    ('LABEL_FCCAC8', 'MidiStream_CmdPedalDone',
     'Return from pedal notify handler'),
    ('LABEL_FCCAC9', 'MidiStream_HandlePartSelect',
     'Handle part select: set voice params B4/B2/B1, call FCA203'),
    ('LABEL_FCCB1B', 'MidiStream_PartSelectDone',
     'Return from part select handler'),
    ('LABEL_FCCB1C', 'MidiStream_ExtendedDispatch',
     '.byte block: extended MIDI dispatch (large block)'),
    ('LABEL_FCCE69', 'MidiStream_HandleRunningStatus',
     '.byte block: handle MIDI running status re-dispatch'),

    # ==================================================================
    # SoundParam_NotifyChange internal labels (FCD256 - FCD2F9)
    # Hash table probe loop and widget callback dispatch for the
    # primary notification function.
    # ==================================================================
    ('LABEL_FCD256', 'SndParam_ProbeCheckMatch',
     'Hash probe: compare xiz with entry key xde'),
    ('LABEL_FCD261', 'SndParam_ProbeMatchFound',
     'Hash probe: key matched, store callback ptr if first match'),
    ('LABEL_FCD26D', 'SndParam_ProbeAdvance',
     'Hash probe: advance to next slot, check table bounds'),
    ('LABEL_FCD282', 'SndParam_ProbeEntry',
     'Hash probe: load entry from hash table at 0x34100'),
    ('LABEL_FCD29A', 'SndParam_DispatchCallback',
     'Dispatch: got callback, check widget type (<9), call via vtable'),
    ('LABEL_FCD2E4', 'SndParam_CallbackType1',
     'Widget callback type 1: call FCED32 handler'),
    ('LABEL_FCD2EC', 'SndParam_NotFound',
     'No matching entry found: set result to 0xFFFF'),
    ('LABEL_FCD2F1', 'SndParam_Epilogue',
     'Epilogue: restore HL result, pop xiz, return'),
    ('LABEL_FCD2F9', 'SndParam_DispatchTypeDE5',
     'Dispatch for arg DE=5: check field +16, use vtable at 0xEE1148'),

    # ==================================================================
    # SndParam_NotifyAndReturn (FCD31B)
    # Wrapper: encode address, call SoundParam_NotifyChange, return.
    # ==================================================================
    ('LABEL_FCD31B', 'SndParam_NotifyAndReturn',
     'Encode params via FCEE7F then call SoundParam_NotifyChange'),

    # ==================================================================
    # SndParam_LookupByKey (FCD32F - FCD41B)
    # Second hash table lookup variant: same hash, different vtable.
    # ==================================================================
    ('LABEL_FCD32F', 'SndParam_LookupByKey',
     'Hash lookup variant 2: probe table, use vtable at 0xEE1110'),
    ('LABEL_FCD384', 'SndParam_Lkp2_ProbeCheck',
     'Variant 2 hash probe: compare xiz with entry key xde'),
    ('LABEL_FCD38F', 'SndParam_Lkp2_MatchFound',
     'Variant 2: key matched, store callback ptr'),
    ('LABEL_FCD39B', 'SndParam_Lkp2_ProbeAdvance',
     'Variant 2: advance to next hash slot'),
    ('LABEL_FCD3B0', 'SndParam_Lkp2_ProbeEntry',
     'Variant 2: load entry from hash table'),
    ('LABEL_FCD3C8', 'SndParam_Lkp2_Dispatch',
     'Variant 2: dispatch callback, check field +14 (<8)'),
    ('LABEL_FCD40E', 'SndParam_Lkp2_CallType1',
     'Variant 2 callback type 1: call FCED32 handler'),
    ('LABEL_FCD416', 'SndParam_Lkp2_NotFound',
     'Variant 2: no match, set result 0xFFFF'),
    ('LABEL_FCD41B', 'SndParam_Lkp2_Epilogue',
     'Variant 2: restore HL result, pop, return'),

    # ==================================================================
    # SndParam_WrapNotify (FCD423)
    # Wrapper variant 2.
    # ==================================================================
    ('LABEL_FCD423', 'SndParam_WrapNotify2',
     'Encode params, call SndParam_LookupByKey variant'),

    # ==================================================================
    # SndParam_LookupReadOnly (FCD437 - FCD4F0)
    # Read-only hash lookup: returns value without dispatch.
    # ==================================================================
    ('LABEL_FCD437', 'SndParam_LookupReadOnly',
     'Read-only hash lookup: probe table, use vtable at 0xEE10D0'),
    ('LABEL_FCD485', 'SndParam_RO_ProbeCheck',
     'Read-only probe: compare xiz with entry key'),
    ('LABEL_FCD490', 'SndParam_RO_MatchFound',
     'Read-only: key matched, store callback ptr'),
    ('LABEL_FCD49C', 'SndParam_RO_ProbeAdvance',
     'Read-only: advance to next hash slot'),
    ('LABEL_FCD4B1', 'SndParam_RO_ProbeEntry',
     'Read-only: load entry from hash table'),
    ('LABEL_FCD4C9', 'SndParam_RO_Dispatch',
     'Read-only: found match, check field +12 (<7), call vtable'),
    ('LABEL_FCD4F0', 'SndParam_RO_Epilogue',
     'Read-only: restore result, pop, return'),

    # ==================================================================
    # SndParam_LookupViaEncode (FCD4F7)
    # ==================================================================
    ('LABEL_FCD4F7', 'SndParam_LookupViaEncode',
     'Encode address via FCEE7F then call SndParam_LookupReadOnly'),

    # ==================================================================
    # SndParam_ResolveWidget (FCD4FF - FCD6AA)
    # Advanced hash lookup: resolves widget struct, chains through
    # linked list, extracts callback pointer and field data.
    # ==================================================================
    ('LABEL_FCD4FF', 'SndParam_ResolveWidget',
     'Resolve widget from param ID: hash lookup with linked-list chain'),
    ('LABEL_FCD5E4', 'SndParam_RW_ExactMatch',
     'Linked list: exact match found, set HL=0'),
    ('LABEL_FCD5E8', 'SndParam_RW_CheckFirstMatch',
     'Linked list: check if this is first match'),
    ('LABEL_FCD5F5', 'SndParam_RW_ChainNext',
     'Linked list: follow chain pointer at (xde+8)'),
    ('LABEL_FCD627', 'SndParam_RW_ChainExactMatch',
     'Chain node: exact match in linked list, set HL=0'),
    ('LABEL_FCD62B', 'SndParam_RW_ChainCheckFirst',
     'Chain node: check if first match found'),
    ('LABEL_FCD631', 'SndParam_RW_FoundCallback',
     'Load callback pointer from (xde+4)'),
    ('LABEL_FCD636', 'SndParam_RW_ChainContinue',
     'Continue chain traversal if not found'),
    ('LABEL_FCD63D', 'SndParam_RW_NoEntry',
     'No hash table entry: set xwa=0'),
    ('LABEL_FCD63F', 'SndParam_RW_ProcessResult',
     'Process lookup result: copy to output, dispatch callback'),
    ('LABEL_FCD683', 'SndParam_RW_HandleB1Type',
     'Handle B1 (0xB1) type: special field extraction (7-bit pairs)'),
    ('LABEL_FCD6A3', 'SndParam_RW_Success',
     'Successful resolution: set HL=0'),
    ('LABEL_FCD6A7', 'SndParam_RW_Fail',
     'Resolution failed: set HL=0xFFFF'),
    ('LABEL_FCD6AA', 'SndParam_RW_Epilogue',
     'Epilogue: pop xiz, restore stack, return'),

    # ==================================================================
    # SndParam_ResolveWidget data block (FCD6AF)
    # ==================================================================
    ('LABEL_FCD6AF', 'SndParam_ResolveWidgetEx_Data',
     '.byte block: extended widget resolution (variant with different table)'),

    # ==================================================================
    # SndParam_DecodeMidiAddr (FCD7C5 - FCD8F6)
    # Decode MIDI address to part/channel: extracts zone+channel
    # from param ID using hash lookup.
    # ==================================================================
    ('LABEL_FCD7C5', 'SndParam_DecodeMidiAddr',
     'Decode param ID to MIDI part/channel via hash table'),
    ('LABEL_FCD823', 'SndParam_DMA_ProbeCheck',
     'Decode probe: compare stored key with entry'),
    ('LABEL_FCD82F', 'SndParam_DMA_MatchFound',
     'Decode probe: key matched, store callback'),
    ('LABEL_FCD83B', 'SndParam_DMA_ProbeAdvance',
     'Decode probe: advance to next slot'),
    ('LABEL_FCD850', 'SndParam_DMA_ProbeEntry',
     'Decode probe: load entry from table'),
    ('LABEL_FCD868', 'SndParam_DMA_ExtractFields',
     'Extract MIDI zone/channel fields from resolved param'),
    ('LABEL_FCD8B1', 'SndParam_DMA_Zone2Check',
     'Check for zone 2 range (0x18000-0x27FFF), add 0x400 offset'),
    ('LABEL_FCD8F6', 'SndParam_DMA_Epilogue',
     'Decode epilogue: return result in HL'),

    # ==================================================================
    # Data/code blocks (FCD8FE - FCDF45)
    # Opaque .byte blocks -- hash table helper variants with
    # different table base addresses and field offsets.
    # ==================================================================
    ('LABEL_FCD8FE', 'SndParam_ResolveWidgetVariant2_Data',
     '.byte block: widget resolution variant with table 0x9780'),
    ('LABEL_FCD9BD', 'SndParam_ReturnNotFound',
     'Return HL=0xFFFF (not found sentinel)'),
    ('LABEL_FCD9C1', 'SndParam_ReadRegField',
     'Read register field from widget: vtable at 0xEE1160, bit ops'),
    ('LABEL_FCD9FF', 'SndParam_ReadRegWithLUT',
     'Read register via LUT at 0xEE0180, type-dependent decode'),
    ('LABEL_FCDA3B', 'SndParam_ReadRegMasked',
     'Masked read: AND field+6 with register value'),
    ('LABEL_FCDA42', 'SndParam_ReadRegReturn',
     'Return from register read'),
    ('LABEL_FCDA43', 'SndParam_CompareRegField',
     'Compare register field with stored value, return status 3/4/5'),
    ('LABEL_FCDA79', 'SndParam_CompareShifted',
     'Shifted compare: apply shift if field+9 bit mask set'),
    ('LABEL_FCDA92', 'SndParam_CompareStatus5',
     'Set compare status = 5 (field differs from value 2)'),
    ('LABEL_FCDA9B', 'SndParam_CompareAddOffset',
     'Add status offset to base pointer, load result byte'),
    ('LABEL_FCDAA2', 'SndParam_CompareNotFound',
     'Compare: widget not found, return 0xFFFF'),
    ('LABEL_FCDAA6', 'SndParam_ReadRegWord',
     'Read 16-bit register word from widget, scan table at 0xEE019C'),
    ('LABEL_FCDADD', 'SndParam_ReadRegScanLoop',
     'Scan loop: compare stack word with register, count matches'),
    ('LABEL_FCDAEB', 'SndParam_ReadRegBitfield',
     'Read register bitfield: XOR/mask/shift extraction'),
    ('LABEL_FCDB30', 'SndParam_BitfieldZeroCheck',
     'Bitfield: check if result is zero after shift'),
    ('LABEL_FCDB3B', 'SndParam_BitfieldNoShift',
     'Bitfield: no shift needed, XOR with mask'),
    ('LABEL_FCDB3F', 'SndParam_BitfieldPendingWrite',
     'Bitfield: set result to 3 (pending write)'),
    ('LABEL_FCDB41', 'SndParam_BitfieldReturn',
     'Bitfield: extend HL to 16-bit and return'),
    ('LABEL_FCDB44', 'SndParam_ReadRegAddress',
     'Read register address field (9 low bits of word at +8)'),
    ('LABEL_FCDB67', 'SndParam_ResetDefaultTable',
     'Reset default state: copy 6 words from 0x96D4 to 0xEDBA2C'),

    # .byte code blocks - hash table helper variants
    ('LABEL_FCDB7E', 'SndParam_RegisterEntry_Data',
     '.byte block: register hash table entry (with vtable 0xEE1130)'),
    ('LABEL_FCDC73', 'SndParam_RegisterEntryAlt_Data',
     '.byte block: alternate register entry (vtable 0xEE1134)'),
    ('LABEL_FCDD49', 'SndParam_UpdateEntry_Data',
     '.byte block: update existing hash table entry'),
    ('LABEL_FCDD9B', 'SndParam_RegisterMultiField_Data',
     '.byte block: register multi-field entry (vtable 0xEE0198)'),
    ('LABEL_FCDE86', 'SndParam_RegisterBitfield_Data',
     '.byte block: register bitfield entry (vtable 0xEE019C)'),
    ('LABEL_FCDF45', 'SndParam_RegisterLinked_Data',
     '.byte block: register linked-list entry (vtable 0xEE1160)'),
    ('LABEL_FCE06E', 'SndParam_RegisterLinked2_Data',
     '.byte block: register linked-list variant 2 (vtable 0xEE1164)'),
    ('LABEL_FCE1B5', 'SndParam_RegisterSimple_Data',
     '.byte block: register simple entry (offset-based)'),
    ('LABEL_FCE258', 'SndParam_DeregisterEntry_Data',
     '.byte block: deregister/remove hash table entry'),
    ('LABEL_FCE26F', 'SndParam_RegisterChained_Data',
     '.byte block: register chained entry with dual-field resolve'),
    ('LABEL_FCE384', 'SndParam_RegisterChained2_Data',
     '.byte block: register chained variant 2'),
    ('LABEL_FCE48F', 'SndParam_RegisterComplex_Data',
     '.byte block: register complex entry with sub-table resolve'),
    ('LABEL_FCE5C1', 'SndParam_NotifyQuick_Data',
     '.byte block: quick notification without full hash probe'),
    ('LABEL_FCE616', 'SndParam_RegisterDual_Data',
     '.byte block: register dual-key entry with cross-reference'),
    ('LABEL_FCE761', 'SndParam_RegisterOffset_Data',
     '.byte block: register offset-based entry'),
    ('LABEL_FCE821', 'SndParam_RegisterWide_Data',
     '.byte block: register wide (multi-byte) entry'),

    # ==================================================================
    # Sound Parameter Encoding Helpers (FCE94A - FCEB3F)
    # Pack/unpack parameter IDs, encode widget descriptors.
    # ==================================================================
    ('LABEL_FCE94A', 'SndParam_EncodeFieldDirect_Data',
     '.byte block: encode field descriptor directly from widget'),
    ('LABEL_FCE979', 'SndParam_EncodeFieldSub_Data',
     '.byte block: encode field descriptor with sub-table lookup'),
    ('LABEL_FCE9B0', 'SndParam_ClampReverbTime',
     'Clamp reverb time value to range [40, 300]'),
    ('LABEL_FCE9D1', 'SndParam_DecodeField_Data',
     '.byte block: decode field descriptor for read-back'),
    ('LABEL_FCEA00', 'SndParam_DecodeFieldAlt_Data',
     '.byte block: decode field descriptor alternate variant'),
    ('LABEL_FCEA43', 'SndParam_ClampDelayTime',
     'Clamp delay time value to range [40, 300]'),
    ('LABEL_FCEA64', 'SndParam_ReturnInvalid',
     'Return HL=0xFFFF (invalid parameter)'),
    ('LABEL_FCEA68', 'SndParam_WriteFieldDirect_Data',
     '.byte block: write field to hardware directly'),
    ('LABEL_FCEAA8', 'SndParam_WriteFieldSub_Data',
     '.byte block: write field with sub-table lookup'),
    ('LABEL_FCEB00', 'SndParam_PackAndWrite',
     'Pack 4 field bytes onto stack and call write routine'),
    ('LABEL_FCEB2C', 'SndParam_WriteViaHash_Data',
     '.byte block: write via hash table lookup'),
    ('LABEL_FCEB3F', 'SndParam_BatchUpdate_Data',
     '.byte block: batch update multiple parameters'),

    # ==================================================================
    # Widget Callback Handlers (FCEC75 - FCEE47)
    # Dispatch widget change notifications based on type code.
    # Called from SndParam hash table dispatch paths.
    # ==================================================================
    ('LABEL_FCEC75', 'SndParam_WidgetNotifyType0',
     'Widget notify type 0: check field+4=0x48 and +5=0x8 for special path'),
    ('LABEL_FCEC85', 'SndParam_WidgetCheckDirty',
     'Check widget dirty flag at field+7, skip if zero'),
    ('LABEL_FCEC8B', 'SndParam_WidgetCallHandler',
     'Call the actual widget change handler'),
    ('LABEL_FCEC8F', 'SndParam_WidgetDispatch',
     'Dispatch by update type (1-4): buffer append, buffer copy, or fn call'),
    ('LABEL_FCECEC', 'SndParam_WidgetAppendType2',
     'Type 2: append 4 field bytes to circular buffer (FCA14F3 overflow)'),
    ('LABEL_FCED1B', 'SndParam_WidgetAppendTail',
     'Append tail: write 0xFF terminator, increment buffer counter by 4'),
    ('LABEL_FCED24', 'SndParam_WidgetCallType3',
     'Type 3: push IX, call 0xFDB224 directly'),
    ('LABEL_FCED2B', 'SndParam_WidgetCallType4',
     'Type 4: push IX, call 0xFDB255 directly'),
    ('LABEL_FCED30', 'SndParam_WidgetDispatchDone',
     'Return from widget dispatch'),

    ('LABEL_FCED32', 'SndParam_WidgetNotifyType1',
     'Widget notify type 1: extended 8-byte update dispatch'),
    ('LABEL_FCEDAB', 'SndParam_Widget1_AppendType2',
     'Type 1/type 2: append 8 field bytes to circular buffer'),
    ('LABEL_FCEDF2', 'SndParam_Widget1_AppendTail',
     'Type 1 append tail: write 0xFF, increment by 8'),
    ('LABEL_FCEDFB', 'SndParam_Widget1_CallType3',
     'Type 1/type 3: dual call to 0xFDB224'),
    ('LABEL_FCEE21', 'SndParam_Widget1_CallType4',
     'Type 1/type 4: dual call to 0xFDB255 with AND mask'),
    ('LABEL_FCEE47', 'SndParam_Widget1_Done',
     'Return from type 1 widget dispatch'),

    # ==================================================================
    # Binary Search (FCEE49)
    # Generic binary search used for parameter table lookups.
    # ==================================================================
    ('LABEL_FCEE49', 'SndParam_BinarySearch',
     'Binary search: find byte A in sorted array at XBC (DE entries)'),

    # ==================================================================
    # Address Encoding (FCEE7F)
    # Encode part/channel into a hash-compatible parameter ID.
    # ==================================================================
    ('LABEL_FCEE7F', 'SndParam_EncodeAddress',
     'Encode WA=zone(6bit), BC=channel(10bit) into 24-bit param ID in XHL'),

    # ==================================================================
    # Hash Table Management (FCEEA6 - FCF10E)
    # Initialize, populate, clear, and allocate in the hash table.
    # ==================================================================
    ('LABEL_FCEEA6', 'SndParam_InitHashTable',
     'Init hash table: set base ptr at 0x34100, fill all slots'),
    ('LABEL_FCEEB2', 'SndParam_InitHashFillLoop',
     'Fill loop: copy 4 words per slot from 0xEDBA3C template'),
    ('LABEL_FCEEC4', 'SndParam_RegisterAllWidgets',
     'Register all 0x3CC widget entries into hash table'),
    ('LABEL_FCEEC7', 'SndParam_RegisterLoop',
     'Loop: load widget ptr from 0xEE01A0 table, call FCEEE6'),
    ('LABEL_FCEEE6', 'SndParam_InsertEntry',
     'Insert single entry into hash table: compute hash, find slot'),
    ('LABEL_FCEF2E', 'SndParam_InsertProbe',
     'Insert probe: check slot, insert if empty or chain'),
    ('LABEL_FCEF52', 'SndParam_InsertCheckKey',
     'Insert: compare key with existing entry'),
    ('LABEL_FCEF5B', 'SndParam_InsertIncSlot',
     'Insert: increment slot counter, check bounds'),
    ('LABEL_FCEF67', 'SndParam_InsertKeyMatch',
     'Insert: key already exists, skip to next'),
    ('LABEL_FCEF6F', 'SndParam_InsertNextSlot',
     'Insert: advance to next slot with wrapping'),
    ('LABEL_FCEF82', 'SndParam_InsertFail',
     'Insert failed: table full, return 0xFFFF'),
    ('LABEL_FCEF85', 'SndParam_InsertReturn',
     'Insert return: pop xiz, clean stack, return'),
    ('LABEL_FCEF89', 'SndParam_ClearHashTable',
     'Clear hash table: zero all entries, reset heap pointer'),
    ('LABEL_FCEF94', 'SndParam_ClearLoop',
     'Clear loop: write zero to each entry'),
    ('LABEL_FCEFAC', 'SndParam_ClearHeap',
     'Clear heap: zero allocation area from base to limit'),
    ('LABEL_FCEFB9', 'SndParam_ReregisterAll',
     'Re-register all widgets: read fields, call FCEFE3 for each'),
    ('LABEL_FCEFBC', 'SndParam_ReregisterLoop',
     'Loop: load widget from 0xEE01A0 table, extract fields, insert'),
    ('LABEL_FCEFE3', 'SndParam_AllocAndInsert',
     'Allocate heap node and insert into hash table'),
    ('LABEL_FCF015', 'SndParam_AllocBuildKey',
     'Build hash key from 3 field bytes, compute hash'),
    ('LABEL_FCF0C9', 'SndParam_AllocChainExisting',
     'Entry exists at hash slot: follow chain to end'),
    ('LABEL_FCF0D2', 'SndParam_AllocChainLoop',
     'Chain traversal: follow next pointers until null'),
    ('LABEL_FCF0DC', 'SndParam_AllocAppendToChain',
     'Append new node at end of chain'),
    ('LABEL_FCF0EF', 'SndParam_AllocSuccess',
     'Allocation success: return HL=0'),
    ('LABEL_FCF0F8', 'SndParam_HeapAlloc',
     'Heap allocator: allocate WA bytes from pool at 0x0380F8'),
    ('LABEL_FCF10B', 'SndParam_HeapAllocFail',
     'Heap alloc failed: size zero or pool full, return XHL=0'),
    ('LABEL_FCF10E', 'SndParam_HeapAllocOK',
     'Heap alloc success: compute pointer, advance heap watermark'),

    # ==================================================================
    # MIDI Serial Communication (FCF9AD - FCFACF)
    # Serial port processing, MIDI receive pump, status dispatch.
    # ==================================================================
    ('LABEL_FCF9AD', 'MidiSerial_RetStub',
     'Return stub (single 0x0E byte)'),
    ('LABEL_FCF9AE', 'MidiSerial_ProcessInput',
     'Process MIDI serial input: check bit4 of 0xFD50, pump buffer'),
    ('LABEL_FCF9BE', 'MidiSerial_PumpLoop',
     'Pump loop: read ring buffer, dispatch by status nibble via table'),
    ('LABEL_FCF9F0', 'MidiSerial_PumpDone',
     'Pump done: call FCC75E (load all presets), write result to buffer'),
    ('LABEL_FCFA03', 'MidiSerial_Return',
     'Return from MIDI serial processing'),
    ('LABEL_FCFA04', 'MidiSerial_StatusTable',
     'Status nibble dispatch table (8 entries, .byte data)'),
    ('LABEL_FCFA25', 'MidiSerial_WaitForData',
     'Wait for serial data: poll ring buffer until ready or bit7'),
    ('LABEL_FCFA33', 'MidiSerial_WaitLoop',
     'Wait loop: call EF27D8, check buffer, poll bit7'),
    ('LABEL_FCFA4C', 'MidiSerial_WaitDone',
     'Wait loop done: data available or timeout'),
    ('LABEL_FCFA4D', 'MidiSerial_ParseStatus_Data',
     '.byte block: parse MIDI status byte'),
    ('LABEL_FCFA67', 'MidiSerial_CmdJumpTable',
     'Command dispatch jump table (16 entries, .long pointers)'),
    ('LABEL_FCFAA7', 'MidiSerial_HandleSysReset_Data',
     '.byte block: handle MIDI system reset (0xFC)'),
    ('LABEL_FCFABD', 'MidiSerial_HandleSysCommon_Data',
     '.byte block: handle MIDI system common message'),
    ('LABEL_FCFACF', 'MidiSerial_HandleDefault_Data',
     '.byte block: default MIDI command handler'),

    # ==================================================================
    # Audio_ConfigureDSP input handler (FDBD89 - FDBFF7)
    # Processes DSP configuration input events:
    # dispatches by parameter type (0x48=scale, 0x70=compressor,
    # 0x98=DSP enable/disable), manages reverb/chorus/EQ state bits.
    # ==================================================================
    ('LABEL_FDBD89', 'DSPCfg_ProcessInput',
     'DSP config input handler: dispatch by param type 0x48/0x70/0x98'),
    ('LABEL_FDBDC7', 'DSPCfg_Reverb_CheckSustain',
     'Reverb active (bit0): check sustain bit6+7 for disable condition'),
    ('LABEL_FDBDDC', 'DSPCfg_Chorus_Active',
     'Chorus active (bit2): check bit7 for toggle, call FC79C7'),
    ('LABEL_FDBDF8', 'DSPCfg_Chorus_CheckSustain',
     'Chorus: check sustain bits, disable if released, set fade bit1'),
    ('LABEL_FDBE1E', 'DSPCfg_FadeOut_Active',
     'Fade-out active (bit1): check bit7 for re-enable reverb'),
    ('LABEL_FDBE37', 'DSPCfg_FadeOut_CheckSustain',
     'Fade-out: check sustain, clear bit1 if released'),
    ('LABEL_FDBE49', 'DSPCfg_EQ_Active',
     'EQ active (bit3): check bit7 for toggle, call FC79C7 with 0x4E'),
    ('LABEL_FDBE69', 'DSPCfg_EQ_CheckSustain',
     'EQ: check sustain, disable bit3, call FC79C7'),
    ('LABEL_FDBE82', 'DSPCfg_Idle_EnableChorus',
     'Idle state: enable chorus (set bit2), init 0x4D, mute volume'),
    ('LABEL_FDBEA1', 'DSPCfg_Idle_CheckSustain',
     'Idle: check sustain bits for additional actions'),
    ('LABEL_FDBEAD', 'DSPCfg_SetFadeBit',
     'Set fade-out bit1 in state register 49648'),
    ('LABEL_FDBEB1', 'DSPCfg_UpdateOutputVolume',
     'Update output: check bits 0+1, write volume 0x7F if both clear'),
    ('LABEL_FDBEC0', 'DSPCfg_CheckChorusMuted',
     'Check if chorus muted (bit2): write volume 0 if so'),

    # ==================================================================
    # DSPCfg compressor parameter handlers (FDBECC - FDBF92)
    # Handle different compressor parameter types (0x70 dispatch).
    # ==================================================================
    ('LABEL_FDBECC', 'DSPCfg_CompressorDispatch',
     'Compressor param dispatch: branch by sub-type E=5/6/7'),
    ('LABEL_FDBEFE', 'DSPCfg_CompParam_SubType6',
     'Sub-type 6: read param 0x2A01, scale, store normalized'),
    ('LABEL_FDBF27', 'DSPCfg_CompParam_SubType7',
     'Sub-type 7: process 3 enable/disable bits (bit0/1/2)'),
    ('LABEL_FDBF45', 'DSPCfg_CompParam_Bit1',
     'Sub-type 7 bit1: read param 0x2A11, set bit5 of state'),
    ('LABEL_FDBF64', 'DSPCfg_CompParam_Bit2',
     'Sub-type 7 bit2: read param 0x2A12, set bit6 of state'),

    # ==================================================================
    # DSPCfg scale factor handler (FDBF84 - FDBFBE)
    # Handle scale factor updates (0x48 dispatch).
    # ==================================================================
    ('LABEL_FDBF84', 'DSPCfg_ScaleFactor_Dispatch',
     'Scale factor dispatch: branch by E=8/9'),
    ('LABEL_FDBF8E', 'DSPCfg_ScaleFactor_Update',
     'Update scale factor: read param, normalize both L/R channels'),
    ('LABEL_FDBFBE', 'DSPCfg_ScaleFactor_StoreResult',
     'Store final scaled value to address 49660'),

    # ==================================================================
    # DSPCfg parameter decode helpers (FDBFC6 - FDBFF7)
    # Extract fields from parameter descriptors.
    # ==================================================================
    ('LABEL_FDBFC6', 'DSPCfg_LookupMidiMap',
     'Lookup MIDI map entry: index into table at 0xEE636C'),
    ('LABEL_FDBFD5', 'DSPCfg_ExtractFieldPair',
     'Extract hi/lo nibble pair from descriptor byte +4'),
    ('LABEL_FDBFF7', 'DSPCfg_ExtractAdjustType2',
     'Type 2 adjustment: extract 5-bit field from byte +5'),
    ('LABEL_FDBFFC', 'DSPCfg_ExtractFieldSingle',
     'Extract single nibble pair (hi=IY offset, lo=value) from +4'),

    # ==================================================================
    # DSPCfg parameter write handler (FDC013 - FDC145)
    # Write decoded parameter values to DSP hardware registers.
    # Dispatches by register type code (0x64/0x67/0x70/0x76).
    # ==================================================================
    ('LABEL_FDC013', 'DSPCfg_WriteParam',
     'Write DSP parameter: dispatch by type 0x64/0x67/0x70/0x76'),
    ('LABEL_FDC058', 'DSPCfg_WriteParam_SetMask',
     'Set output mask E=0xFF, proceed to common exit'),
    ('LABEL_FDC05A', 'DSPCfg_WriteParam_Exit',
     'Common exit: write old value, set mask, return HL=0'),
    ('LABEL_FDC070', 'DSPCfg_WriteParam_Type64_67',
     'Type 0x64/0x67: write L and C bytes to widget struct'),
    ('LABEL_FDC077', 'DSPCfg_WriteParam_Type70',
     'Type 0x70: extract nibble pair, dispatch by sub-command 0x10/0x20'),
    ('LABEL_FDC0B9', 'DSPCfg_WriteParam_Type70_Sub10',
     'Sub-cmd 0x10: shift left 3, mask 0xF8, combine with existing'),
    ('LABEL_FDC0D1', 'DSPCfg_WriteParam_Type70_Sub20',
     'Sub-cmd 0x20: mask 0x3F, combine with existing high bits'),
    ('LABEL_FDC0E4', 'DSPCfg_WriteParam_Type76',
     'Type 0x76: extract via FDBFD5, dispatch by sub-cmd 0x10'),
    ('LABEL_FDC11E', 'DSPCfg_WriteParam_SetMask7',
     'Set mask E=0x07, jump to common exit'),
    ('LABEL_FDC123', 'DSPCfg_WriteParam_Type76_Sub10',
     'Type 0x76 sub-cmd 0x10: mask 0x3F, check if type 2'),
    ('LABEL_FDC136', 'DSPCfg_WriteParam_Type76_NotType2',
     'Type 0x76 not type 2: write to indirect address'),
    ('LABEL_FDC142', 'DSPCfg_WriteParam_IncCounter',
     'Increment change counter at (xsp+4)'),
    ('LABEL_FDC145', 'DSPCfg_WriteParam_SetMask3F',
     'Set mask E=0x3F, jump to common exit'),
    ('LABEL_FDC14A', 'DSPCfg_PackAddress',
     'Pack 2 bytes from widget into 16-bit address (byte0<<8 + byte1)'),
]


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
        print(f'  {old_label:25s} -> {new_label:40s} ({refs} refs)')

    with open(src, 'wb') as f:
        f.write(content.encode('latin-1'))

    print(f'\nRenamed {renamed} labels in maincpu')


if __name__ == '__main__':
    main()
