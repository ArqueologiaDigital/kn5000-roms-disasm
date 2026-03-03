#!/usr/bin/env python3
"""Rename LABEL_* to semantic names in kn5000_v10_program.s (DSP/audio config 2).

Covers three function regions (~700 labels total):

  1. DSPCfg_PackAddress continuation (FDC16E-FDD1B1, ~152 labels)
     DSP address packing, field extraction, parameter read/write with
     packed multi-field addressing, MIDI map range dispatch (0x4900-0x4F00),
     validation of parameter IDs, multi-param batch write with AssswbWr,
     and simplified read/write entry points.

  2. FileData_LoadAndParse / DataBuf region (FD268F-FD3679, ~413 labels)
     File data buffer allocation via malloc, data loading from storage,
     format-type dispatch (types 1/2/3), bitfield copy routines that
     transfer DSP voice parameters between source and destination buffers
     with per-bit masking (ldcfm/stcfm patterns), and bulk parameter
     transfer subroutines for different voice configurations.

  3. MIDI packet building (FD9D04-FDB12B, ~123 labels)
     MIDI control/status packet construction from parameter structs,
     dispatch table routing via EE4F52 jump tables, MIDI channel mask
     filtering, data byte encoding, SysEx-like multi-byte message
     building, and incoming SysEx data application to voice parameters.

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
    # Region 1: DSPCfg_PackAddress continuation (FDC16E - FDD1B1)
    # DSP parameter addressing, field extraction, read/write dispatch,
    # MIDI map range routing, validation, batch param update.
    # ==================================================================

    # --- DSPCfg_PackAddress helpers ---
    ('LABEL_FDC16E', 'DSPCfg_PackAddress_ReturnInput',
     'Return XWA unchanged when packed addr = 0xF0 (end marker)'),

    # --- DSPCfg_ReadField: Read a field from packed DSP param structure ---
    ('LABEL_FDC171', 'DSPCfg_ReadField',
     'Read a field value from packed DSP param, dispatch by type byte'),
    ('LABEL_FDC1C4', 'DSPCfg_ReadField_SetWidth1',
     'Set width=1 (single byte field)'),
    ('LABEL_FDC1C7', 'DSPCfg_ReadField_StoreAndReturn',
     'Store field result to output pointers and return'),
    ('LABEL_FDC1DE', 'DSPCfg_ReadField_GoWidth2',
     'Jump to set width=2'),
    ('LABEL_FDC1E0', 'DSPCfg_ReadField_Type68_Unsigned',
     'Type 0x68: unsigned byte, mask to 0xFF'),
    ('LABEL_FDC1EA', 'DSPCfg_ReadField_Type70',
     'Type 0x70: extract single field, dispatch by sub-width'),
    ('LABEL_FDC213', 'DSPCfg_ReadField_Type70_Width16',
     'Type 0x70 sub-width 0x10: return constant 0x0B'),
    ('LABEL_FDC218', 'DSPCfg_ReadField_Type70_Width32',
     'Type 0x70 sub-width 0x20: return low 6 bits of packed field'),
    ('LABEL_FDC21E', 'DSPCfg_ReadField_SetWidth2',
     'Set width=2 and return'),
    ('LABEL_FDC223', 'DSPCfg_ReadField_Type76',
     'Type 0x76: extract field pair, dispatch by sub-width'),
    ('LABEL_FDC234', 'DSPCfg_ReadField_Type76_ShiftAndMask',
     'Shift packed value by sub-width bits, mask to 5 bits'),
    ('LABEL_FDC23D', 'DSPCfg_ReadField_Type76_Mask5Bits',
     'Mask BC to 0x1F, store to HL, return'),
    ('LABEL_FDC245', 'DSPCfg_ReadField_Type76_Width16',
     'Type 0x76 sub-width 0x10: check pair type, extract high byte'),

    # --- DSPCfg_WriteMultiField: Write param iterating over packed fields ---
    ('LABEL_FDC25A', 'DSPCfg_WriteMultiField',
     'Iterate packed fields, read each then write final via WriteParam'),
    ('LABEL_FDC27C', 'DSPCfg_WriteMultiField_Loop',
     'Loop: accumulate offset, read field, advance address'),
    ('LABEL_FDC29A', 'DSPCfg_WriteMultiField_AccumXWA',
     'Inner loop: add 1 to XWA accumulator for each sub-field'),
    ('LABEL_FDC2A6', 'DSPCfg_WriteMultiField_AdvanceAddr',
     'Pack address and advance to next field group'),
    ('LABEL_FDC2B8', 'DSPCfg_WriteMultiField_Final',
     'Final iteration: read last field group and call WriteParam'),

    # --- DSPCfg_ReadMultiField: Read from packed multi-field structure ---
    ('LABEL_FDC2E8', 'DSPCfg_ReadMultiField',
     'Iterate packed fields reading each via ReadField'),
    ('LABEL_FDC30A', 'DSPCfg_ReadMultiField_Loop',
     'Loop: accumulate offset, read field, advance'),
    ('LABEL_FDC328', 'DSPCfg_ReadMultiField_AdvancePtr',
     'Advance XIZ pointer by field width'),
    ('LABEL_FDC331', 'DSPCfg_ReadMultiField_PackAndNext',
     'Pack address and loop to next group'),
    ('LABEL_FDC345', 'DSPCfg_ReadMultiField_Final',
     'Final read: process last field group'),

    # --- DSPCfg_GetParamCount: Read param count from table at EE5FE0 ---
    ('LABEL_FDC35F', 'DSPCfg_GetParamCount',
     'Look up param count byte from table 0xEE5FE0[wa]'),

    # --- DSPCfg_ReadViaTableLookup: Use EE75F6 jump table to read ---
    ('LABEL_FDC364', 'DSPCfg_ReadViaTableLookup',
     'Read field via EE75F6 table lookup, pass to ReadMultiField'),

    # --- DSPCfg_StoreAndReturn: Simple store byte, return HL=0 ---
    ('LABEL_FDC38C', 'DSPCfg_StoreByte_ReturnZero',
     'Store A to (XBC), return HL=0'),

    # --- DSPCfg_WriteViaTableLookup: Use EE75F6 table for write ---
    ('LABEL_FDC391', 'DSPCfg_WriteViaTableLookup',
     'Write multi-field via EE75F6 table, call WriteMultiField'),

    # --- DSPCfg_ExtractPairFromStruct: Extract packed pair from struct ---
    ('LABEL_FDC3C9', 'DSPCfg_ExtractPairFromStruct',
     'Extract two packed address fields from linked struct, store results'),

    # --- DSPCfg_LookupAndExtract: Combine table index + struct extract ---
    ('LABEL_FDC41D', 'DSPCfg_LookupAndExtract',
     'Index into EE6044 table, multiply, call ExtractPairFromStruct'),

    # --- Data block at FDC448 ---
    ('LABEL_FDC448', 'DSPCfg_Data_FDC448',
     '.byte data block (14 bytes)'),

    # --- DSPCfg_GetSlotCount: Lookup slot count from EE5FE0 ---
    ('LABEL_FDC456', 'DSPCfg_GetSlotCount',
     'Look up slot count from EE5FE0 + XWA, return in HL'),

    # --- Data block at FDC464 ---
    ('LABEL_FDC464', 'DSPCfg_Data_FDC464',
     '.byte data block (14 bytes)'),

    # --- DSPCfg_FindSlot63: Search for slot with type 0x63 ---
    ('LABEL_FDC472', 'DSPCfg_FindSlot63',
     'Iterate slots via EE75F6 table, find slot where offset+2 == 0x63'),
    ('LABEL_FDC49B', 'DSPCfg_FindSlot63_Loop',
     'Check if (xwa+2)==0x63, if so save position'),
    ('LABEL_FDC4A4', 'DSPCfg_FindSlot63_Next',
     'Pack address, advance to next slot'),
    ('LABEL_FDC4B0', 'DSPCfg_FindSlot63_Return',
     'Return found slot index or 0xFFFF'),

    # --- Data block at FDC4B7 ---
    ('LABEL_FDC4B7', 'DSPCfg_Data_FDC4B7',
     '.byte data block (search/iterate logic)'),

    # --- DSPCfg_DecodeParamIdRange: Decode param ID into range/offset ---
    ('LABEL_FDC504', 'DSPCfg_DecodeParamIdRange',
     'Decode DSP param ID (0x4900-0x4F00) to range index and offset'),
    ('LABEL_FDC564', 'DSPCfg_DecodeParamIdRange_4910',
     'Range 0x4910-0x4927: stride=1, base=0x4910'),
    ('LABEL_FDC572', 'DSPCfg_DecodeParamIdRange_4940',
     'Range 0x4940-0x4947: stride=4, base=0x4940'),
    ('LABEL_FDC57E', 'DSPCfg_DecodeParamIdRange_CalcOffset',
     'Compute offset = paramId - base'),
    ('LABEL_FDC589', 'DSPCfg_DecodeParamIdRange_Invalid',
     'Out of range: set all outputs to 0xFFFF'),
    ('LABEL_FDC59C', 'DSPCfg_DecodeParamIdRange_Return',
     'Store results and return'),

    # --- DSPCfg_ResolveParamToSlot: Full param resolution with MIDI map ---
    ('LABEL_FDC5AB', 'DSPCfg_ResolveParamToSlot',
     'Resolve param ID to slot via MIDI map lookup and range dispatch'),
    ('LABEL_FDC5C7', 'DSPCfg_ResolveParamToSlot_OutOfRange',
     'Param outside 0x4900-0x4F00: return 0xFFFF'),
    ('LABEL_FDC5CD', 'DSPCfg_ResolveParamToSlot_Range49',
     'Range 0x4900-0x49FF: map=0, decode directly'),
    ('LABEL_FDC5F5', 'DSPCfg_ResolveParamToSlot_Range4A',
     'Range 0x4A00-0x4AFF: map=1, subtract 0x200'),
    ('LABEL_FDC623', 'DSPCfg_ResolveParamToSlot_Range4B',
     'Range 0x4B00-0x4BFF: map=1, subtract 0x200'),
    ('LABEL_FDC650', 'DSPCfg_ResolveParamToSlot_Range4C',
     'Range 0x4C00-0x4CFF: map=4, subtract 0x300'),
    ('LABEL_FDC67D', 'DSPCfg_ResolveParamToSlot_Range4D',
     'Range 0x4D00-0x4DFF: map=2, subtract 0x400'),
    ('LABEL_FDC6AA', 'DSPCfg_ResolveParamToSlot_Range4E',
     'Range 0x4E00+: map=3, subtract 0x500'),
    ('LABEL_FDC6CD', 'DSPCfg_ResolveParamToSlot_CallDecode',
     'Call DecodeParamIdRange with adjusted param'),
    ('LABEL_FDC6D0', 'DSPCfg_ResolveParamToSlot_StoreResult',
     'Store resolved slot data and map index, return'),

    # --- DSPCfg_ResolveAndExtract: Resolve param then extract pair ---
    ('LABEL_FDC6E7', 'DSPCfg_ResolveAndExtract',
     'Resolve param to slot, then call LookupAndExtract'),
    ('LABEL_FDC70C', 'DSPCfg_ResolveAndExtract_Return',
     'Return from resolve-and-extract'),

    # --- DSPCfg_ResolveWithFallback: Resolve with secondary table ---
    ('LABEL_FDC710', 'DSPCfg_ResolveWithFallback',
     'Resolve param, if IZ flag set use EE61D4/EE637A secondary tables'),
    ('LABEL_FDC77A', 'DSPCfg_ResolveWithFallback_CheckType',
     'Check resolution type for dispatch (0/1/8/9)'),
    ('LABEL_FDC7A0', 'DSPCfg_ResolveWithFallback_Type1',
     'Type 1: read via table lookup, special case for 0x491D'),
    ('LABEL_FDC7CB', 'DSPCfg_ResolveWithFallback_SndParam4003',
     'Special: look up SndParam 0x4003 for program number'),
    ('LABEL_FDC7D9', 'DSPCfg_ResolveWithFallback_Type8',
     'Type 8: get slot count'),
    ('LABEL_FDC7E4', 'DSPCfg_ResolveWithFallback_Type9',
     'Type 9: find slot 63'),
    ('LABEL_FDC7EC', 'DSPCfg_ResolveWithFallback_UnknownType',
     'Unknown type: return 0xFFFF'),
    ('LABEL_FDC7F1', 'DSPCfg_ResolveWithFallback_Return',
     'Return result in HL'),

    # --- DSPCfg_ReadParam_Map0 / Map1: Entry points with map index ---
    ('LABEL_FDC7F9', 'DSPCfg_ReadParam_Map0',
     'Read param with MIDI map index 0 (BC=0)'),
    ('LABEL_FDC7FE', 'DSPCfg_ReadParam_Map1',
     'Read param with MIDI map index 1 (BC=1)'),

    # --- DSPCfg_ClampAndExtract: Clamp value to min/max, extract pair ---
    ('LABEL_FDC803', 'DSPCfg_ClampAndExtract',
     'Get slot count, extract pair, clamp value between min/max'),
    ('LABEL_FDC85C', 'DSPCfg_ClampAndExtract_CheckMax',
     'Value >= min, now check if <= max'),
    ('LABEL_FDC86F', 'DSPCfg_ClampAndExtract_InRange',
     'Value in range: return HL=0 (success)'),
    ('LABEL_FDC873', 'DSPCfg_ClampAndExtract_NoSlot',
     'Slot count exceeded: return 0xFFFF'),
    ('LABEL_FDC876', 'DSPCfg_ClampAndExtract_Return',
     'Store clamped value, return status'),

    # --- DSPCfg_ValidateSlotForWrite: Check slot type allows writing ---
    ('LABEL_FDC883', 'DSPCfg_ValidateSlotForWrite',
     'Validate that param WA with slot BC has writable EE75F6 entry'),
    ('LABEL_FDC8BD', 'DSPCfg_ValidateSlotForWrite_Invalid',
     'Invalid slot: return 0xFFFF'),
    ('LABEL_FDC8C0', 'DSPCfg_ValidateSlotForWrite_Ret',
     'Return from validation'),
    ('LABEL_FDC8C1', 'DSPCfg_ValidateSlotForWrite_Slot1',
     'Slot 1: allow WA=0x09, 0x0A, or 0x10-0x1B'),
    ('LABEL_FDC8DB', 'DSPCfg_ValidateSlotForWrite_Slot2',
     'Slot 2: allow WA=0x39-0x3C'),
    ('LABEL_FDC8E9', 'DSPCfg_ValidateSlotForWrite_Slot3',
     'Slot 3: allow WA=0x58-0x5B'),
    ('LABEL_FDC8F7', 'DSPCfg_ValidateSlotForWrite_Slot4',
     'Slot 4: allow WA=0x4F only'),
    ('LABEL_FDC8FD', 'DSPCfg_ValidateSlotForWrite_Valid',
     'Validation passed: return HL=0'),

    # --- DSPCfg_WriteParamFull: Full param write with validation + notify ---
    ('LABEL_FDC901', 'DSPCfg_WriteParamFull',
     'Resolve, validate, write param with AssswbWr and notification'),
    ('LABEL_FDC978', 'DSPCfg_WriteParamFull_Type1',
     'Type 1: clamp value, write via table lookup, notify AssswbWr'),
    ('LABEL_FDC9A8', 'DSPCfg_WriteParamFull_Type1_Clamped',
     'Type 1 after clamp: write multi-field when already clamped'),
    ('LABEL_FDC9B6', 'DSPCfg_WriteParamFull_Type1_Notify',
     'Compute notify params: channel, slot index, AssswbWr call'),
    ('LABEL_FDC9DE', 'DSPCfg_WriteParamFull_Check491D',
     'Special: if param 0x491D, check program num and notify 0x4003'),
    ('LABEL_FDC9FD', 'DSPCfg_WriteParamFull_Notify4003',
     'Notify SoundParam_NotifyChange for param 0x4003'),
    ('LABEL_FDCA0D', 'DSPCfg_WriteParamFull_UnknownType',
     'Unknown type: set IZ=0xFFFF'),
    ('LABEL_FDCA10', 'DSPCfg_WriteParamFull_Return',
     'Return write result in HL'),

    # --- DSPCfg_WriteParamSimple: Simplified write (no clamp error detail) ---
    ('LABEL_FDCA17', 'DSPCfg_WriteParamSimple',
     'Resolve, validate, write param; simplified version of WriteParamFull'),
    ('LABEL_FDCA6D', 'DSPCfg_WriteParamSimple_Type1',
     'Type 1: clamp and write multi-field'),
    ('LABEL_FDCA9D', 'DSPCfg_WriteParamSimple_Type1_Clamped',
     'Type 1 clamped: write via table lookup'),
    ('LABEL_FDCAAB', 'DSPCfg_WriteParamSimple_Check491D',
     'Check for 0x491D and notify if needed'),
    ('LABEL_FDCACA', 'DSPCfg_WriteParamSimple_Notify4003',
     'Notify SoundParam_NotifyChange for 0x4003'),
    ('LABEL_FDCADA', 'DSPCfg_WriteParamSimple_UnknownType',
     'Unknown resolution type: IZ=0xFFFF'),
    ('LABEL_FDCADD', 'DSPCfg_WriteParamSimple_Return',
     'Return write result in HL'),

    # --- DSPCfg_WriteParamDelta: Read current, add delta, write ---
    ('LABEL_FDCAE4', 'DSPCfg_WriteParamDelta',
     'Resolve param, read current value, add delta, call WriteParamFull'),
    ('LABEL_FDCB23', 'DSPCfg_WriteParamDelta_Type1',
     'Type 1: read via table lookup, add delta'),
    ('LABEL_FDCB33', 'DSPCfg_WriteParamDelta_CallWrite',
     'Call WriteParamFull with adjusted value'),
    ('LABEL_FDCB38', 'DSPCfg_WriteParamDelta_BadType',
     'Unsupported type: return 0xFFFF'),
    ('LABEL_FDCB3B', 'DSPCfg_WriteParamDelta_Return',
     'Return result in HL'),

    # --- DSPCfg_WriteAllSlots_Direct: Write value to all slots directly ---
    ('LABEL_FDCB40', 'DSPCfg_WriteAllSlots_Direct',
     'Validate slot, write A to all slots via table, AssswbWr each'),
    ('LABEL_FDCBA4', 'DSPCfg_WriteAllSlots_Direct_Loop',
     'Loop: read current via table, write multi-field, AssswbWr'),
    ('LABEL_FDCBEC', 'DSPCfg_WriteAllSlots_Direct_CheckCount',
     'Check if more slots remain (compare IZ < slot count)'),
    ('LABEL_FDCBF6', 'DSPCfg_WriteAllSlots_Direct_Return',
     'Return validation result in HL'),

    # --- DSPCfg_WriteAllSlots_Clamped: Write with clamp to each slot ---
    ('LABEL_FDCBFE', 'DSPCfg_WriteAllSlots_Clamped',
     'For each slot: clamp, write multi-field, track changed count'),
    ('LABEL_FDCC2B', 'DSPCfg_WriteAllSlots_Clamped_Loop',
     'Loop: read via table, clamp, write if changed'),
    ('LABEL_FDCC90', 'DSPCfg_WriteAllSlots_Clamped_Next',
     'Advance to next slot'),
    ('LABEL_FDCC92', 'DSPCfg_WriteAllSlots_Clamped_CheckCount',
     'Check if more slots remain'),

    # --- DSPCfg_WriteAllSlots_Combined: Combine direct + clamped ---
    ('LABEL_FDCCA4', 'DSPCfg_WriteAllSlots_Combined',
     'Call WriteAllSlots_Direct then WriteAllSlots_Clamped, sum results'),
    ('LABEL_FDCCD0', 'DSPCfg_WriteAllSlots_Combined_Done',
     'Return combined change count in HL'),

    # --- Data block at FDCCD7 (complex DSP param dispatch logic) ---
    ('LABEL_FDCCD7', 'DSPCfg_Data_ParamDispatch',
     '.byte data block: DSP parameter dispatch and field packing logic'),

    # --- DSPCfg_CheckParamTableEntry: Verify EE75F6 entry exists ---
    ('LABEL_FDCF6C', 'DSPCfg_CheckParamTableEntry',
     'Return 0 if param WA <= 0x63 has non-null EE75F6 entry, else 0xFFFF'),
    ('LABEL_FDCF86', 'DSPCfg_CheckParamTableEntry_NotFound',
     'No table entry: return 0xFFFF'),

    # --- DSPCfg_ReadFieldSimple: Simplified field read (no pair) ---
    ('LABEL_FDCF8A', 'DSPCfg_ReadFieldSimple',
     'Read field from packed param, simplified (types 0x64/0x67/0x70 only)'),
    ('LABEL_FDCFC9', 'DSPCfg_ReadFieldSimple_StoreReturn',
     'Store field width and result, return'),
    ('LABEL_FDCFE0', 'DSPCfg_ReadFieldSimple_Type64_67',
     'Types 0x64/0x67: return packed IZ directly'),
    ('LABEL_FDCFE4', 'DSPCfg_ReadFieldSimple_Type70',
     'Type 0x70: extract single field, dispatch by sub-width'),
    ('LABEL_FDD005', 'DSPCfg_ReadFieldSimple_SetWidth2',
     'Set width=2 and return'),

    # --- DSPCfg_ApplyParamStruct: Apply full param struct to DSP ---
    ('LABEL_FDD00A', 'DSPCfg_ApplyParamStruct',
     'Apply a param struct: check table, shift chain for types 0x10-0x1B'),
    ('LABEL_FDD06F', 'DSPCfg_ApplyParamStruct_Normal',
     'Normal path: iterate packed fields, dispatch by param type'),
    ('LABEL_FDD0A7', 'DSPCfg_ApplyParamStruct_ReadLoop',
     'Read loop: process each packed field group'),
    ('LABEL_FDD0C5', 'DSPCfg_ApplyParamStruct_AdvancePtr',
     'Advance pointer by field width'),
    ('LABEL_FDD0CE', 'DSPCfg_ApplyParamStruct_PackNext',
     'Pack address and loop to next group'),
    ('LABEL_FDD0E2', 'DSPCfg_ApplyParamStruct_CheckSpecial',
     'Check if param type needs 2-byte or 1-byte value offset'),
    ('LABEL_FDD125', 'DSPCfg_ApplyParamStruct_Offset2',
     'Special types (0x20-0x23,0x35,0x0F,0x60-0x63): offset=2'),
    ('LABEL_FDD129', 'DSPCfg_ApplyParamStruct_Offset1',
     'Other types: offset=1'),
    ('LABEL_FDD12B', 'DSPCfg_ApplyParamStruct_WriteLoop',
     'Write loop: store value then iterate write fields'),
    ('LABEL_FDD161', 'DSPCfg_ApplyParamStruct_WriteReadLoop',
     'Write-read loop: read field then write to struct'),
    ('LABEL_FDD18B', 'DSPCfg_ApplyParamStruct_WriteSkip2Byte',
     'Skip 2-byte write if width != 2'),
    ('LABEL_FDD194', 'DSPCfg_ApplyParamStruct_WriteAdvancePtr',
     'Advance write pointer by field width'),
    ('LABEL_FDD19D', 'DSPCfg_ApplyParamStruct_WritePackNext',
     'Pack address, loop to next write group'),
    ('LABEL_FDD1B1', 'DSPCfg_ApplyParamStruct_Return',
     'Return status in HL'),

    # --- DSPCfg_ApplyParamStructFull (FDD1B9): Full param struct apply ---
    ('LABEL_FDD1B9', 'DSPCfg_ApplyParamStructFull',
     'Full param struct application with 68-byte stack frame'),

    # ==================================================================
    # Region 2: FileData / Data Buffer (FD268F - FD53F0)
    # File loading, buffer allocation, format dispatch, bitfield copy
    # subroutines for DSP voice parameter transfer.
    # ==================================================================

    # --- FileData_ValidateFormat: Check format validity ---
    ('LABEL_FD268F', 'FileData_ValidateFormat',
     'Validate file format: call FEBF7A, check low nibble'),
    ('LABEL_FD26A3', 'FileData_ValidateFormat_CheckMatch',
     'Compare stored value at DA[1060] with input'),
    ('LABEL_FD26B4', 'FileData_ValidateFormat_Match',
     'Format matches: return value in HL'),
    ('LABEL_FD26B8', 'FileData_ValidateFormat_Return',
     'Clean up stack and return'),

    # --- FileData_LoadAndParse: Main file load + format dispatch ---
    ('LABEL_FD26BC', 'FileData_AllocLoadAndParse',
     'Allocate 32-byte buffer, load file, dispatch by format type 1/2/3'),

    # --- FileData_LoadFromSlot: Load from slot with format dispatch ---
    ('LABEL_FD2732', 'FileData_LoadFromSlot',
     'Compute slot address, call format detector, dispatch types 1/2/3'),
    ('LABEL_FD275E', 'FileData_LoadFromSlot_Type1or2',
     'Format type 1 or 2: call buffer reader FD2B5C'),
    ('LABEL_FD2763', 'FileData_LoadFromSlot_Type3',
     'Format type 3: call handler FD4625'),
    ('LABEL_FD2768', 'FileData_LoadFromSlot_UnknownFormat',
     'Unknown format: return 0xFF9A error'),
    ('LABEL_FD276B', 'FileData_LoadFromSlot_Return',
     'Clean up stack and return'),

    # --- FileData_RawDataBlock: Raw .byte data (mixed encoded instructions) ---
    ('LABEL_FD276E', 'FileData_RawDataBlock',
     '.byte data block: encoded file data processing instructions'),

    # --- DataBuf_AllocAndLoadFormatted: Allocate 2K buffer, parse formatted ---
    ('LABEL_FD2B5C', 'DataBuf_AllocAndLoadFormatted',
     'Allocate 0x800 buffer, load data, transfer to DSP voice params'),
    ('LABEL_FD2B7C', 'DataBuf_AllocAndLoadFormatted_AllocOk',
     'Buffer allocated: load data from slot and begin param transfer'),
    ('LABEL_FD2BD4', 'DataBuf_TransferVoiceParams_Loop',
     'Loop 0x18 iterations: transfer 32-byte voice param blocks'),
    ('LABEL_FD2C11', 'DataBuf_TransferEffectParams_Loop',
     'Loop 3 iterations: transfer 12-byte effect param blocks'),
    ('LABEL_FD2C7E', 'DataBuf_TransferAuxParams_Loop',
     'Loop 2 iterations: transfer auxiliary param blocks'),
    ('LABEL_FD2D35', 'DataBuf_AllocAndLoadFormatted_Return',
     'Pop XIZ, return result in HL'),

    # --- DataBuf_CopyVoiceBlock24: Copy 24-byte voice param with bitfield masking ---
    ('LABEL_FD2D3A', 'DataBuf_CopyVoiceBlock24',
     'Copy 24-byte voice block with 7-bit masking and ldcfm bit transfer'),

    # --- DataBuf_CopyEffectBlock12: Copy 12-byte effect param with nibble masking ---
    ('LABEL_FD2F74', 'DataBuf_CopyEffectBlock12',
     'Copy 12-byte effect block with nibble-wise (4-bit) field masking'),

    # --- DataBuf_CopyFilterParams: Copy filter parameters with bitfield masking ---
    ('LABEL_FD3055', 'DataBuf_CopyFilterBlock12',
     'Copy 12-byte filter block with per-bit ldcfm/stcfm masking'),

    # --- DataBuf_CopyReverbParams: Copy reverb parameters ---
    ('LABEL_FD31C0', 'DataBuf_CopyReverbBlock6',
     'Copy 6-byte reverb block with bit-level masking'),

    # --- DataBuf_CopySimpleBlock4: Copy simple 4-byte block ---
    ('LABEL_FD3253', 'DataBuf_CopySimpleBlock4',
     'Copy byte + bit7 from 4-byte source to dest'),

    # --- DataBuf_LoadAndDispatchFormat2: Format 2 with param-by-param transfer ---
    ('LABEL_FD3260', 'DataBuf_LoadAndDispatchFormat2',
     'Format-2 data load: dispatch by format type with voice param routing'),
    ('LABEL_FD32FA', 'DataBuf_Format2_Type61_UpdateLoop',
     'Type 0x61 format 1: iterate slots, read/write via 0x4910+'),
    ('LABEL_FD3324', 'DataBuf_Format2_Type61_RestoreSlotId',
     'Restore original slot ID from saved value'),
    ('LABEL_FD332A', 'DataBuf_Format2_Type63',
     'Type 0x63: write to 0x4B00 range, iterate 0x4B10+ sub-params'),
    ('LABEL_FD3377', 'DataBuf_Format2_Type63_UpdateLoop',
     'Type 0x63 format 1: iterate 0x4B10+ sub-params'),
    ('LABEL_FD33A1', 'DataBuf_Format2_Type63_RestoreSlotId',
     'Restore slot ID for type 0x63 path'),
    ('LABEL_FD33A7', 'DataBuf_Format2_FormatType2',
     'Format type 2 path: call FDD1B9 then re-dispatch'),
    ('LABEL_FD341F', 'DataBuf_FormatType2_Type61_UpdateLoop',
     'Format-2 type 0x61: iterate 0x4910+ slots via WriteParamSimple'),
    ('LABEL_FD3449', 'DataBuf_FormatType2_RestoreSlotId',
     'Restore slot ID for format-2 type 0x61'),
    ('LABEL_FD344C', 'DataBuf_StoreSlotId_Return',
     'Store slot ID to DA[64628] and return'),
    ('LABEL_FD3453', 'DataBuf_FormatType2_Type63',
     'Format-2 type 0x63: write 0x4B00 range, iterate sub-params'),
    ('LABEL_FD34A6', 'DataBuf_FormatType2_Type63_UpdateLoop',
     'Format-2 type 0x63: iterate 0x4B10+ sub-params'),
    ('LABEL_FD34D0', 'DataBuf_FormatType2_Type63_RestoreSlotId',
     'Restore slot ID for format-2 type 0x63'),
    ('LABEL_FD34D3', 'DataBuf_StoreSlotId63_Return',
     'Store slot ID to DA[64654] and return'),
    ('LABEL_FD34D7', 'DataBuf_LoadAndDispatchFormat2_Return',
     'Pop XIZ and return'),

    # --- DataBuf_CopyEQBlock: Copy EQ parameters ---
    ('LABEL_FD34DB', 'DataBuf_CopyEQBlock7',
     'Copy 7-byte EQ block with nibble + bit masking'),

    # --- DataBuf_CopyChorusBlock: Copy chorus parameters ---
    ('LABEL_FD354D', 'DataBuf_CopyChorusBlock16',
     'Copy 16-byte chorus block: bit7 masking, ldcfm per-byte'),

    # --- DataBuf_CopyCompressorBlock: Copy compressor parameters ---
    ('LABEL_FD35FC', 'DataBuf_CopyCompressorBlock16',
     'Copy 16-byte compressor block: bit7 + nibble masking'),

    # --- DataBuf_CopyDelayBit: Copy 2-bit delay parameter ---
    ('LABEL_FD366C', 'DataBuf_CopyDelayBit2',
     'Copy bit1 and bit0 from source+2 to dest+2'),

    # --- DataBuf_CopyMixerBlock12: Copy mixer block with full bit masking ---
    ('LABEL_FD3679', 'DataBuf_CopyMixerBlock12',
     'Copy 12-byte mixer block with comprehensive per-bit ldcfm masking'),

    # --- DataBuf_CopyBulkBitfields: Bulk bitfield copy subroutines ---
    ('LABEL_FD38FD', 'DataBuf_CopyBulkBitfields_Nop',
     'No-op return (placeholder for bulk copy)'),
    ('LABEL_FD38FE', 'DataBuf_CopyBulkBitfields_Stub',
     'Stub return (1 byte)'),
    ('LABEL_FD38FF', 'DataBuf_CopyBulkBitfields_944',
     'Bulk bitfield copy at offsets 944/1090 with full bit masking'),

    # --- DataBuf bulk copy at higher offsets ---
    ('LABEL_FD3A7C', 'DataBuf_CopyBulkBitfields_960',
     'Bulk bitfield copy at next offset pair'),
    ('LABEL_FD3BF9', 'DataBuf_CopyBulkBitfields_F980',
     'Bulk bitfield copy using base 0xF980'),
    ('LABEL_FD3D84', 'DataBuf_CopyBulkBitfields_Large',
     'Large bulk bitfield copy subroutine'),

    # --- FileData_LoadAndParseType3 ---
    ('LABEL_FD4625', 'FileData_LoadAndParseType3',
     'Format type 3: load and parse file data'),
    ('LABEL_FD464C', 'FileData_LoadAndParseType3_Continue',
     'Continue type 3 parse after initial load'),
    ('LABEL_FD46A4', 'FileData_LoadAndParseType3_Error',
     'Type 3 parse error path'),

    # --- DataBuf_FormatDetector subroutines ---
    ('LABEL_FD522E', 'DataBuf_TransferSlotBitfields',
     'Transfer slot bitfields with per-bit masking from source to dest'),
    ('LABEL_FD5250', 'DataBuf_TransferSlotBitfields_Loop',
     'Loop: copy bytes with bit7 mask, advance by 26'),

    # --- DataBuf_CheckFormatPair: Multi-branch format pair lookup ---
    ('LABEL_FD52A2', 'DataBuf_CheckFormatPair',
     'Check format pair: return 1/2/3/0xFFFF based on byte pairs'),
    ('LABEL_FD52B6', 'DataBuf_CheckFormatPair_NotM34',
     'Not 4D/34 pair: check next'),
    ('LABEL_FD52C5', 'DataBuf_CheckFormatPair_NotM36',
     'Not 4D/36 pair: check next'),
    ('LABEL_FD52D2', 'DataBuf_CheckFormatPair_NotN4E',
     'Not 4E/4E pair: return 0xFFFF'),

    # --- DataBuf_CheckSubFormat: Check sub-format type ---
    ('LABEL_FD52D6', 'DataBuf_CheckSubFormat',
     'Check sub-format: return 1/2/3/0xFFFF based on (xwa+5)/(xbc) values'),
    ('LABEL_FD52E8', 'DataBuf_CheckSubFormat_Not6',
     'Sub-format field != 6: check next'),
    ('LABEL_FD52F4', 'DataBuf_CheckSubFormat_Not7',
     'Sub-format field != 7: check next'),
    ('LABEL_FD5300', 'DataBuf_CheckSubFormat_Not3',
     'Sub-format field != 3: return 0xFFFF'),
    ('LABEL_FD5304', 'DataBuf_Data_FormatDispatch',
     '.byte data block: format dispatch and slot transfer logic'),

    # --- DataBuf_InitSlotFromPreset: Set up slot from preset number ---
    ('LABEL_FD53AA', 'DataBuf_InitSlotFromPreset',
     'Initialize DSP slot from preset number with base address calc'),
    ('LABEL_FD53F0', 'DataBuf_InitSlotFromPreset_Alt',
     'Alternate init path for different preset base'),

    # ==================================================================
    # Region 3: MIDI Packet Building (FD9D04 - FDB12B)
    # MIDI packet construction, dispatch table routing, channel mask
    # filtering, data encoding, SysEx handling.
    # ==================================================================

    # --- MidiPkt_ExtractAndPack: Extract fields from struct, pack into packet ---
    ('LABEL_FD9D04', 'MidiPkt_ExtractAndPack',
     'Extract fields from param struct, pack with shift, dispatch via EE4F52'),
    ('LABEL_FD9D50', 'MidiPkt_ExtractAndPack_StoreShifted',
     'Store shifted DE value into packet byte 4'),
    ('LABEL_FD9D63', 'MidiPkt_ExtractAndPack_Ret',
     'Simple return'),

    # --- MidiPkt_BuildDirect: Build 4-byte packet directly from struct ---
    ('LABEL_FD9D64', 'MidiPkt_BuildDirect',
     'Build 4-byte MIDI packet: status/ctrl/data/channel from (XIZ)'),

    # --- MidiPkt_BuildControl: Build MIDI control packet with map lookup ---
    ('LABEL_FD9DA0', 'MidiPkt_BuildControl',
     'Build MIDI control packet: map lookup, status|ctrl, data via 0xFD822D'),

    # --- MidiPkt_BuildStatusDirect: Build packet with direct field copy ---
    ('LABEL_FD9F85', 'MidiPkt_BuildStatusDirect',
     'Build MIDI packet: direct status/ctrl/data copy from struct fields'),

    # --- MidiPkt_BuildFromConstant: Build packet with constant data byte ---
    ('LABEL_FD9FC1', 'MidiPkt_BuildFromConstant',
     'Build packet: status/ctrl from struct, data byte from DA[36580]'),

    # --- MidiPkt_BuildZeroData: Build packet with data byte = 0 ---
    ('LABEL_FD9FEF', 'MidiPkt_BuildZeroData',
     'Build packet: status/ctrl from struct, data byte = 0'),

    # --- MidiPkt_ProcessEventQueue: Walk event queue and dispatch ---
    ('LABEL_FDA01A', 'MidiPkt_ProcessEventQueue',
     'Walk MIDI event queue, dispatch each via EE304C jump table'),
    ('LABEL_FDA03B', 'MidiPkt_ProcessEventQueue_Loop',
     'Loop: read event code, dispatch if < 0xC0, skip if >= 0xC0'),
    ('LABEL_FDA068', 'MidiPkt_ProcessEventQueue_Next',
     'Advance to next event (+4 bytes)'),
    ('LABEL_FDA06C', 'MidiPkt_ProcessEventQueue_Done',
     'Event queue complete: restore XIZ and return'),

    # --- MidiPkt_Nop: No-op handler ---
    ('LABEL_FDA06E', 'MidiPkt_Nop',
     'No-op return (unused handler slot)'),

    # --- MidiPkt_DispatchViaTable_4D6A: Dispatch using EE4D6A table ---
    ('LABEL_FDA06F', 'MidiPkt_DispatchViaTable_4D6A',
     'Match param in EE4D6A table, dispatch via EE4F52[type]'),

    # --- MidiPkt_DispatchViaTable_4D82 ---
    ('LABEL_FDA0A3', 'MidiPkt_DispatchViaTable_4D82',
     'Match param in EE4D82 table, dispatch via EE4F52[type]'),

    # --- MidiPkt_DispatchViaTable_4D8E ---
    ('LABEL_FDA0D7', 'MidiPkt_DispatchViaTable_4D8E',
     'Match param in EE4D8E table, dispatch via EE4F52[type]'),

    # --- MidiPkt_DispatchViaTable_4D9A ---
    ('LABEL_FDA10B', 'MidiPkt_DispatchViaTable_4D9A',
     'Match param in EE4D9A table, dispatch via EE4F52[type]'),

    # --- MidiPkt_DispatchViaTable_4DA6 ---
    ('LABEL_FDA13F', 'MidiPkt_DispatchViaTable_4DA6',
     'Match param in EE4DA6 table, dispatch via EE4F52[type]'),

    # --- MidiPkt_DispatchViaTable_4DAE: With mask clear ---
    ('LABEL_FDA173', 'MidiPkt_DispatchViaTable_4DAE',
     'Match EE4DAE, dispatch, then mask-clear if type=0x0B'),
    ('LABEL_FDA1E9', 'MidiPkt_DispatchViaTable_4DAE_Done',
     'Return after 4DAE dispatch'),

    # --- MidiPkt_DispatchSpecialType: Handle types 0x10/0x11 specially ---
    ('LABEL_FDA1ED', 'MidiPkt_DispatchSpecialType',
     'Special dispatch: type 0x10/0x11 use dedicated data addresses'),
    ('LABEL_FDA20B', 'MidiPkt_DispatchSpecialType_Type10',
     'Type 0x10: use EE35D6 data source'),
    ('LABEL_FDA21F', 'MidiPkt_DispatchSpecialType_SendAndUpdate',
     'Call FD6BFC/FD8428 to send MIDI and update state'),
    ('LABEL_FDA229', 'MidiPkt_DispatchSpecialType_Default',
     'Default: dispatch via EE4DC6 table'),
    ('LABEL_FDA254', 'MidiPkt_DispatchSpecialType_Return',
     'Return from special dispatch'),

    # --- MidiPkt_MatchParamInTable: Search param table for match ---
    ('LABEL_FDA258', 'MidiPkt_MatchParamInTable',
     'Search linked list for param matching byte+1 and bit mask'),
    ('LABEL_FDA25F', 'MidiPkt_MatchParamInTable_Loop',
     'Loop: advance via EE49E8 chain, compare fields'),

    # --- MidiPkt_EnqueueControlNop: No-op for control enqueue ---
    ('LABEL_FDA277', 'MidiPkt_EnqueueControlNop',
     'No-op return (placeholder)'),

    # --- MidiPkt_EnqueueControl_3354: Enqueue MIDI via EE3354 ---
    ('LABEL_FDA278', 'MidiPkt_EnqueueControl_3354',
     'Enqueue MIDI control: match param, encode channel mask bits'),
    ('LABEL_FDA2D6', 'MidiPkt_EnqueueControl_3354_ShiftBits',
     'Shift channel mask if shift count field nonzero'),
    ('LABEL_FDA2FE', 'MidiPkt_EnqueueControl_3354_Return',
     'Return from enqueue'),

    # --- MidiPkt_EnqueueExtended_Data (.byte block) ---
    ('LABEL_FDA302', 'MidiPkt_EnqueueExtended_Data',
     '.byte data block: extended MIDI enqueue logic'),

    # --- MidiPkt_EnqueueControl_3334: Enqueue via EE3334 ---
    ('LABEL_FDA389', 'MidiPkt_EnqueueControl_335C',
     'Enqueue via EE3354: data byte = 0x7F if mask nonzero, else 0'),
    ('LABEL_FDA3E6', 'MidiPkt_EnqueueControl_335C_ZeroData',
     'Mask is zero: data byte stays 0'),
    ('LABEL_FDA40B', 'MidiPkt_EnqueueControl_335C_Return',
     'Return from enqueue'),

    # --- MidiPkt_EnqueueControl_3358: Enqueue 6-byte MIDI via EE3358 ---
    ('LABEL_FDA40F', 'MidiPkt_EnqueueControl_3358',
     'Enqueue 6-byte MIDI: lookup via EE0EC table, 2-nibble data'),
    ('LABEL_FDA4B6', 'MidiPkt_EnqueueControl_3358_SplitNibbles',
     'Split data into high/low nibbles for packet bytes'),
    ('LABEL_FDA4EA', 'MidiPkt_EnqueueControl_3358_Return',
     'Return from enqueue'),

    # --- MidiPkt_EnqueueControl_335E: Enqueue with EE4AEA constant ---
    ('LABEL_FDA4EE', 'MidiPkt_EnqueueControl_335E',
     'Enqueue via EE335E with constant EE4AEA table source'),
    ('LABEL_FDA54E', 'MidiPkt_EnqueueControl_335E_SplitNibbles',
     'Split data into high/low nibbles'),
    ('LABEL_FDA582', 'MidiPkt_EnqueueControl_335E_Return',
     'Return from enqueue'),

    # --- MidiPkt_EnqueueControl_3364: Enqueue with channel masking ---
    ('LABEL_FDA587', 'MidiPkt_EnqueueControl_3364',
     'Enqueue via EE3364 with channel mask bit extraction'),
    ('LABEL_FDA5E5', 'MidiPkt_EnqueueControl_3364_NoShift',
     'No shift needed for channel mask'),
    ('LABEL_FDA5EA', 'MidiPkt_EnqueueControl_3364_FormatData',
     'Format data byte: split nibbles, send'),
    ('LABEL_FDA612', 'MidiPkt_EnqueueControl_3364_Return',
     'Return from enqueue'),

    # --- MidiPkt_EnqueueControl_3368: Enqueue with pedal check ---
    ('LABEL_FDA616', 'MidiPkt_EnqueueControl_3368',
     'Enqueue via EE3368 with pedal mode check (DA[64921])'),
    ('LABEL_FDA67A', 'MidiPkt_EnqueueControl_3368_PedalNoShift',
     'Pedal mode: no shift on channel mask'),
    ('LABEL_FDA67E', 'MidiPkt_EnqueueControl_3368_NoPedal',
     'Non-pedal: standard channel mask encoding'),
    ('LABEL_FDA69E', 'MidiPkt_EnqueueControl_3368_FormatData',
     'Format data byte and send'),
    ('LABEL_FDA6C9', 'MidiPkt_EnqueueControl_3368_Return',
     'Return from enqueue'),

    # --- MidiPkt_EnqueueExtended2_Data (.byte block) ---
    ('LABEL_FDA6CD', 'MidiPkt_EnqueueExtended2_Data',
     '.byte data block: extended MIDI enqueue logic (second block)'),

    # --- MidiPkt_CheckGateCondition: Check gate conditions for MIDI ---
    ('LABEL_FDA777', 'MidiPkt_CheckGateCondition',
     'Check gate conditions from EE4DF2/EE4E04 tables; return 0xFFFF if blocked'),
    ('LABEL_FDA79A', 'MidiPkt_CheckGateCondition_Second',
     'Check second gate condition (byte+13)'),
    ('LABEL_FDA7BD', 'MidiPkt_CheckGateCondition_Blocked',
     'Gate blocked: return 0xFFFF'),
    ('LABEL_FDA7C1', 'MidiPkt_CheckGateCondition_Pass',
     'Gate passed: return 0'),

    # --- MidiPkt_DispatchViaTable_4DCE ---
    ('LABEL_FDA7C4', 'MidiPkt_DispatchViaTable_4DCE',
     'Match param in EE4DCE table, dispatch via EE4F52[type]'),

    # --- MidiPkt_DispatchData various .byte blocks ---
    ('LABEL_FDA7F9', 'MidiPkt_DispatchData_Chan4',
     '.byte: dispatch for channel 4'),
    ('LABEL_FDA800', 'MidiPkt_DispatchData_Chan3',
     '.byte: dispatch for channel 3'),
    ('LABEL_FDA807', 'MidiPkt_DispatchData_Chan1',
     '.byte: dispatch for channel 1'),
    ('LABEL_FDA80E', 'MidiPkt_DispatchData_Chan2',
     '.byte: dispatch for channel 2'),
    ('LABEL_FDA815', 'MidiPkt_DispatchData_Chan5',
     '.byte: dispatch for channel 5'),
    ('LABEL_FDA81C', 'MidiPkt_DispatchData_Chan6',
     '.byte: dispatch for channel 6 + table data'),

    # --- MidiPkt_SendBankSelect: Send bank select MIDI message ---
    ('LABEL_FDA85C', 'MidiPkt_SendBankSelect',
     'Check bank select conditions via FD5EB6, send if 0x2B/0x2C'),
    ('LABEL_FDA87E', 'MidiPkt_SendBankSelect_Send',
     'Send bank select via EE35AC with FD6BFC/FD8428'),

    # --- MidiPkt complex .byte data blocks ---
    ('LABEL_FDA896', 'MidiPkt_SysExValidator_Data',
     '.byte data block: SysEx validation and parameter routing'),
    ('LABEL_FDA8D8', 'MidiPkt_SysExProcessor_Data',
     '.byte data block: SysEx processing logic'),
    ('LABEL_FDA921', 'MidiPkt_SysExBulkTransfer_Data',
     '.byte data block: SysEx bulk data transfer and param application'),

    # --- SysEx_LookupVoiceTable_4B: Voice slot lookup for 0x4B range ---
    ('LABEL_FDAB44', 'SysEx_ClampVoiceIndex8',
     'Clamp voice index A to 0-7, lookup from EE33A4'),
    ('LABEL_FDAB4B', 'SysEx_ClampVoiceIndex8_DoLookup',
     'Perform EE33A4 table lookup'),

    # --- SysEx apply data blocks ---
    ('LABEL_FDAB58', 'SysEx_ApplyToSlot4B_Data',
     '.byte data block: SysEx apply to 0x4B slot range'),

    # --- SysEx_LookupVoiceTable_4B_128: Voice slot lookup (128 range) ---
    ('LABEL_FDABC8', 'SysEx_ClampVoiceIndex128',
     'Clamp voice index A to 0-127, lookup from EE33AC'),
    ('LABEL_FDABCF', 'SysEx_ClampVoiceIndex128_DoLookup',
     'Perform EE33AC table lookup'),

    # --- SysEx apply to 0x49 slot ---
    ('LABEL_FDABDC', 'SysEx_ApplyToSlot49_Data',
     '.byte data block: SysEx apply to 0x49 slot range'),

    # --- SysEx_LookupVoiceTable_49: Voice slot lookup for 0x49 range ---
    ('LABEL_FDAC52', 'SysEx_ClampVoiceIndex8_49',
     'Clamp voice index A to 0-7, lookup from EE342C'),
    ('LABEL_FDAC59', 'SysEx_ClampVoiceIndex8_49_DoLookup',
     'Perform EE342C table lookup'),

    # --- SysEx apply with format dispatch ---
    ('LABEL_FDAC66', 'SysEx_ApplyToSlot49_Format_Data',
     '.byte data block: SysEx apply to 0x49 slot with format dispatch'),

    # --- SysEx_LookupVoiceTable_49_128: ---
    ('LABEL_FDACD6', 'SysEx_ClampVoiceIndex128_49',
     'Clamp voice index A to 0-127, lookup from EE3434'),
    ('LABEL_FDACDD', 'SysEx_ClampVoiceIndex128_49_DoLookup',
     'Perform EE3434 table lookup'),

    # --- SysEx_DispatchByChannel: Dispatch by channel + parameter ---
    ('LABEL_FDACEA', 'SysEx_DispatchByChannel',
     'Dispatch SysEx by channel: range check WA 0-7, jump via EE3520'),

    # --- SysEx_ChannelHandler_Data: Channel handler jump tables ---
    ('LABEL_FDAD13', 'SysEx_ChannelHandler_4B_Data',
     '.byte data block: channel handler dispatch for 0x4B range'),
    ('LABEL_FDAD71', 'SysEx_DispatchByChannel_49',
     'Dispatch SysEx by channel for 0x49 range via EE3584'),
    ('LABEL_FDAD9A', 'SysEx_ChannelHandler_49_Data',
     '.byte data block: channel handler dispatch for 0x49 range'),

    # --- SysEx_ValidateRolandHeader: Validate F0 41 42 12 40 01 header ---
    ('LABEL_FDADF6', 'SysEx_ValidateRolandHeader',
     'Validate SysEx Roland header: F0/41/42/12/40/01, dispatch by sub-cmd'),
    ('LABEL_FDAE34', 'SysEx_ValidateRolandHeader_NonZeroChan',
     'Non-zero channel: compute slot address from channel index'),
    ('LABEL_FDAE4C', 'SysEx_ValidateRolandHeader_Dispatch',
     'Dispatch by sub-command byte: 0x30/0x33/0x38/0x3A'),
    ('LABEL_FDAE69', 'SysEx_ValidateRolandHeader_Cmd33',
     'Sub-command 0x33: apply voice param (128-range)'),
    ('LABEL_FDAE70', 'SysEx_ValidateRolandHeader_Cmd38',
     'Sub-command 0x38: apply voice param to 0x49 range'),
    ('LABEL_FDAE77', 'SysEx_ValidateRolandHeader_Cmd3A',
     'Sub-command 0x3A: apply voice param (128-range, 0x49)'),

    # --- SysEx_ApplyVoiceParam_4B: Apply incoming SysEx to 0x4B voice slot ---
    ('LABEL_FDAE7F', 'SysEx_ApplyVoiceParam_4B',
     'Apply SysEx voice data to 0x4B range: lookup, write, update slots'),
    ('LABEL_FDAECB', 'SysEx_ApplyVoiceParam_4B_ReadSubParams',
     'Read sub-params via ReadParam_Map0 for 0x4B04'),
    ('LABEL_FDAEEA', 'SysEx_ApplyVoiceParam_4B_SkipRestore',
     'Skip restore if target == current slot'),
    ('LABEL_FDAEEC', 'SysEx_ApplyVoiceParam_4B_IterateSlots',
     'Iterate sub-parameter slots (0x4B10+)'),
    ('LABEL_FDAEF3', 'SysEx_ApplyVoiceParam_4B_SlotLoop',
     'Loop: dispatch by channel, write via WriteParamSimple'),
    ('LABEL_FDAF19', 'SysEx_ApplyVoiceParam_4B_SlotNext',
     'Advance to next slot'),
    ('LABEL_FDAF20', 'SysEx_ApplyVoiceParam_4B_RestoreSlotId',
     'Restore original slot ID if changed'),
    ('LABEL_FDAF2E', 'SysEx_ApplyVoiceParam_4B_Return',
     'Return from 0x4B voice param application'),

    # --- SysEx_ApplyVoiceParam_4B_128: Apply 128-range voice param ---
    ('LABEL_FDAF32', 'SysEx_ApplyVoiceParam_4B_128',
     'Apply 128-range SysEx voice data to 0x4B slots'),
    ('LABEL_FDAF68', 'SysEx_ApplyVoiceParam_4B_128_ReadSub',
     'Read sub-params via ReadParam_Map0 for 0x4B04'),
    ('LABEL_FDAF87', 'SysEx_ApplyVoiceParam_4B_128_SkipRestore',
     'Skip restore if target == current slot'),
    ('LABEL_FDAF89', 'SysEx_ApplyVoiceParam_4B_128_IterateSlots',
     'Iterate sub-param slots'),
    ('LABEL_FDAF90', 'SysEx_ApplyVoiceParam_4B_128_SlotLoop',
     'Loop: call ResolveAndExtract, write if type 1 or 2'),
    ('LABEL_FDAFA6', 'SysEx_ApplyVoiceParam_4B_128_WriteSlot',
     'Write slot via WriteParamSimple'),
    ('LABEL_FDAFBE', 'SysEx_ApplyVoiceParam_4B_128_SlotNext',
     'Advance to next slot'),
    ('LABEL_FDAFC5', 'SysEx_ApplyVoiceParam_4B_128_RestoreSlotId',
     'Restore original slot ID'),
    ('LABEL_FDAFD3', 'SysEx_ApplyVoiceParam_4B_128_Return',
     'Return from 128-range application'),

    # --- SysEx_ApplyVoiceParam_49: Apply incoming SysEx to 0x49 voice slot ---
    ('LABEL_FDAFD7', 'SysEx_ApplyVoiceParam_49',
     'Apply SysEx voice data to 0x49 range: lookup, write, update slots'),
    ('LABEL_FDB023', 'SysEx_ApplyVoiceParam_49_ReadSubParams',
     'Read sub-params via ReadParam_Map0 for 0x4904'),
    ('LABEL_FDB042', 'SysEx_ApplyVoiceParam_49_SkipRestore',
     'Skip restore if target == current slot'),
    ('LABEL_FDB044', 'SysEx_ApplyVoiceParam_49_IterateSlots',
     'Iterate sub-parameter slots (0x4910+)'),
    ('LABEL_FDB04B', 'SysEx_ApplyVoiceParam_49_SlotLoop',
     'Loop: dispatch by channel, write via WriteParamSimple'),
    ('LABEL_FDB071', 'SysEx_ApplyVoiceParam_49_SlotNext',
     'Advance to next slot'),
    ('LABEL_FDB078', 'SysEx_ApplyVoiceParam_49_RestoreSlotId',
     'Restore original slot ID'),
    ('LABEL_FDB086', 'SysEx_ApplyVoiceParam_49_Return',
     'Return from 0x49 voice param application'),

    # --- SysEx_ApplyVoiceParam_49_128: Apply 128-range to 0x49 slots ---
    ('LABEL_FDB08A', 'SysEx_ApplyVoiceParam_49_128',
     'Apply 128-range SysEx voice data to 0x49 slots'),
    ('LABEL_FDB0C0', 'SysEx_ApplyVoiceParam_49_128_ReadSub',
     'Read sub-params for 0x4904'),
    ('LABEL_FDB0DF', 'SysEx_ApplyVoiceParam_49_128_SkipRestore',
     'Skip restore if target == current slot'),
    ('LABEL_FDB0E1', 'SysEx_ApplyVoiceParam_49_128_IterateSlots',
     'Iterate sub-param slots'),
    ('LABEL_FDB0E8', 'SysEx_ApplyVoiceParam_49_128_SlotLoop',
     'Loop: call ResolveAndExtract, write if type 1 or 2'),
    ('LABEL_FDB0FE', 'SysEx_ApplyVoiceParam_49_128_WriteSlot',
     'Write slot via WriteParamSimple'),
    ('LABEL_FDB116', 'SysEx_ApplyVoiceParam_49_128_SlotNext',
     'Advance to next slot'),
    ('LABEL_FDB11D', 'SysEx_ApplyVoiceParam_49_128_RestoreSlotId',
     'Restore original slot ID'),
    ('LABEL_FDB12B', 'SysEx_ApplyVoiceParam_49_128_Return',
     'Return from 128-range application'),

    # --- SysEx_ApplyAndReloadPreset: Apply SysEx then reload all presets ---
    ('LABEL_FDB12F', 'SysEx_ApplyAndReloadPreset',
     'Apply SysEx data, then reload all presets for 0x49/0x4B slots'),
    ('LABEL_FDB142', 'SysEx_ApplyAndReloadPreset_Type61',
     'Type 0x61: write 0x4900 slot, iterate 0x4910+ sub-params'),
    ('LABEL_FDB16F', 'SysEx_ApplyAndReloadPreset_Type61_Loop',
     'Loop: read map1 for 0x4910+, write via WriteParamSimple'),
    ('LABEL_FDB19B', 'SysEx_ApplyAndReloadPreset_Type63',
     'Type 0x63: write 0x4B00 slot, iterate 0x4B10+ sub-params'),
    ('LABEL_FDB1C5', 'SysEx_ApplyAndReloadPreset_Type63_Loop',
     'Loop: read map1 for 0x4B10+, write via WriteParamSimple'),
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
        print(f'  {old_label:25s} -> {new_label:50s} ({refs} refs)')

    with open(src, 'wb') as f:
        f.write(content.encode('latin-1'))

    print(f'\nRenamed {renamed} labels in maincpu')


if __name__ == '__main__':
    main()
