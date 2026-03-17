#!/usr/bin/env python3
"""Rename LABEL_* to semantic names for SubCPU audio engine routines (02E-031 range).

Based on analysis of the 0x02E000-0x031FFF address range in the SubCPU audio engine.
This range covers tone generator configuration, DSP voice status checks, memory copy
helpers, DSP algo selection support, DSP voice parameter read/write, DSP coefficient
setup, voice parameter finalization/dispatch, and DSP voice buffer lookup tables.

Each rename was verified by analysing the routine's code, register usage, called
functions, and callers within the file.

Uses binary I/O to handle Latin-1 encoding safely.  Never use the Edit tool on
kn5000_subprogram_v142.s — it corrupts the Latin-1 encoding.
"""

import os
import re

# ---------------------------------------------------------------------------
# Rename table: (old_label, new_label, brief_comment)
#
# Groups follow the natural function boundaries visible in the source:
#
#   02E008-02E0B2  ToneGen_Config_Init continuation: per-voice HW register writes
#   02E0B6         Data block (opaque .byte data for ToneGen init variant)
#   02E18D-02E1ED  ToneGen voice pitch readback and scaling routine
#   02E1F4-02E233  Status bits [7:6] check predicates (zero, 0x40, 0x80, 0xC0)
#   02E273-02E27B  Block memory copy helper (dst=XHL, src=XBC, count=DE words)
#   02E288-02E308  Voice struct bulk initializer (base + 4 sub-slots)
#   02E30E         Data block (opaque .byte data for voice struct setup variant)
#   02E353         Voice sub-slot struct initializer (single sub-slot)
#   02E390         Data block (opaque .byte data for voice sub-slot variant)
#   02E3E9-02E57D  Voice full parameter setup: init structs, configure routing,
#                  copy param tables per sub-slot, count active slots
#   02E581         Data block (opaque .byte data for extended voice setup)
#   02EC0A-02ECBB  Voice allocation check: verify allocation state, set flags
#   02ECBE         Data block (opaque .byte data for allocation check variant)
#   02F50D-02F527  Voice allocation wrapper: call check, set/clear routing bit
#   02F52A         Data block (opaque .byte data for allocation dispatch)
#   030632-030635  DSP_EffectStateQuery continuation: write result 0 or 1
#   030638-030817  DSP voice parameter adjustment: iterate 4 sub-slots, apply
#                  portamento/reverb/chorus offsets with clamping
#   03087F         DSP parameter adjustment: vibrato depth (0x0451a8 offset)
#   0309C0-030A08  DSP_AlgoSelect continuation: write algo buffer, dispatch state
#   030A0A         Data block (opaque .byte data for DSP algo processing)
#   030FD3-031067  DSP_VoiceParamReadWrite: multi-slot loop body, result packing
#   03107F         Data block (opaque .byte data for DSP param read variant)
#   0311BC-03122A  DSP_SetVoiceCoefficients: coefficient table lookup, copy loop
#   03122F         Data block (opaque .byte data for DSP coefficient variant)
#   031A57-031A6C  DSP param write helper (block copy, DE words from XIZ to XBC)
#                  + NOP padding
#   031AA1         ToneCmd_Dispatcher: main tone command jump table body
#   031B39-031B5B  Voice_ParamFinalize: secondary dispatch table + body
#   031E2D-031E68  Voice_ParamFinalize epilogue: copy struct to work area, return
#   031ECF-031F00  DSP_WriteVoiceParam: mode dispatch (0x00/0x40/0x80/0xC0)
#   031F16         DSP voice buffer lookup variant A (coefficient table path)
#   031F71-031FE4  DSP voice buffer lookup variant B (param index validation)
# ---------------------------------------------------------------------------

RENAMES = [
    # ------------------------------------------------------------------
    # 02E008-02E0B2  ToneGen_Config_Init loop body — per-voice HW register writes
    # Context: inside the ToneGen_Config_Init loop (iz = 0..0x3F).
    # Writes voice params to tone gen registers at 0x100000/0x100002
    # via ToneGen_WriteVoiceParams, WriteSingleReg, WriteExtParams_*.
    # Falls through several stages with NOP gaps for hardware timing.
    # ------------------------------------------------------------------
    ('LABEL_02E008', 'ToneGen_ConfigInit_WriteVoiceRegs',
     'Write voice params/single reg to tone gen for current voice index'),

    ('LABEL_02E038', 'ToneGen_ConfigInit_WriteAddr800',
     'Write 0xFF00 to tone gen reg at voice+0x840, then read voice+0x800'),

    ('LABEL_02E056', 'ToneGen_ConfigInit_WriteAddrC0',
     'Write 0x0000 to tone gen reg at voice+0xC0'),

    ('LABEL_02E074', 'ToneGen_ConfigInit_WriteAddr00',
     'Write 0x7E00 to tone gen reg at voice+0x000'),

    ('LABEL_02E08E', 'ToneGen_ConfigInit_WriteExtParams',
     'Write ext params (15, 56, 56b) then increment iz, loop or exit'),

    ('LABEL_02E0B2', 'ToneGen_ConfigInit_Return',
     'Pop iz, clean up stack, return from DSP/ToneGen config init'),

    # ------------------------------------------------------------------
    # 02E0B6  Data block — opaque .byte data
    # Appears to be an alternate ToneGen init routine encoded as raw
    # bytes (not yet disassembled).  Only referenced as a label anchor.
    # ------------------------------------------------------------------
    ('LABEL_02E0B6', 'ToneGen_ConfigInit_AltData',
     'Opaque .byte data block: alternate ToneGen config init routine'),

    # ------------------------------------------------------------------
    # 02E18D-02E1ED  Voice pitch readback + FP_MulAccum64 scaling
    # Reads tone gen registers at voice+0xC0 and voice+0x000, performs
    # multiply-accumulate via FP_MulAccum64 with stride 0x47, looks up
    # a table at 0x0430BB, clears bit 15 of result, stores to output.
    # ------------------------------------------------------------------
    ('LABEL_02E18D', 'ToneGen_ReadPitch_AndScale',
     'Read tone gen pitch regs, scale via FP_MulAccum64, store to output buffer'),

    ('LABEL_02E1B4', 'ToneGen_ReadPitch_Compute',
     'Read tone gen base reg, multiply by 0x47, lookup table at 0x0430BB'),

    ('LABEL_02E1ED', 'ToneGen_ReadPitch_Return',
     'Pop iz, clean up stack, return from pitch readback'),

    # ------------------------------------------------------------------
    # 02E1F4  CheckStatusBits_Zero: check if voice struct status bits
    # [7:6] == 0b00.  Loads voice struct via FP_MulAccum64 * 287,
    # reads byte at +16, masks with 0xC0, returns HL = (result == 0).
    # ------------------------------------------------------------------
    ('LABEL_02E1F4', 'CheckStatusBits_Zero',
     'Return HL=1 if voice status bits [7:6] are 0b00, else HL=0'),

    # ------------------------------------------------------------------
    # 02E213  CheckStatusBits_40: check if voice struct status bits
    # [7:6] == 0b01 (0x40).  Same structure as CheckStatusBits_Zero
    # but compares against 0x40.
    # ------------------------------------------------------------------
    ('LABEL_02E213', 'CheckStatusBits_40',
     'Return HL=1 if voice status bits [7:6] are 0x40, else HL=0'),

    # ------------------------------------------------------------------
    # 02E233  CheckStatusBits_80: check if status bits == 0b10 (0x80).
    # Comment already present in source.
    # Followed immediately (no label) by CheckStatusBits_C0 (0xC0 case).
    # ------------------------------------------------------------------
    ('LABEL_02E233', 'CheckStatusBits_80',
     'Return HL=1 if voice status bits [7:6] are 0x80, else HL=0'),

    # ------------------------------------------------------------------
    # 02E273-02E27B  Block memory copy helper
    # Copies DE words from address pointed to by XBC (src) into XHL (dst).
    # Uses ld_spib/lda_dpi idiom for post-increment copy loop.
    # IX is the loop counter.
    # ------------------------------------------------------------------
    ('LABEL_02E273', 'BlockCopy_Words_BC_to_HL',
     'Copy DE words from XBC (src) to XHL (dst) using post-increment loop'),

    ('LABEL_02E27B', 'BlockCopy_Words_BC_to_HL_Loop',
     'Per-word copy body: ld_spib + lda_dpi, increment IX, loop'),

    # ------------------------------------------------------------------
    # 02E288-02E308  Voice struct bulk initializer
    # For a given voice index (A), computes base address in 0x041368
    # struct array (stride 0x11F), copies 0x66 words of base data from
    # 0x044FCE, then iterates 4 sub-slots (0xFB counter 0..3), copying
    # 0x51 words each at stride 0x25 into sub-slot region.
    # ------------------------------------------------------------------
    ('LABEL_02E288', 'VoiceStruct_BulkInit',
     'Bulk-initialize voice struct: copy base (0x66 words) + 4 sub-slots (0x51 words each)'),

    ('LABEL_02E2BA', 'VoiceStruct_BulkInit_SubSlotLoop',
     'Per-sub-slot loop: compute offset 0x25*slot+0x6E, copy 0x51 words'),

    ('LABEL_02E308', 'VoiceStruct_BulkInit_Return',
     'Pop WERP 0xFA, clean up stack, return'),

    # ------------------------------------------------------------------
    # 02E30E  Data block — opaque .byte data
    # Raw bytes for an alternate voice struct init variant (undisassembled).
    # ------------------------------------------------------------------
    ('LABEL_02E30E', 'VoiceStruct_BulkInit_AltData',
     'Opaque .byte data block: alternate voice struct init variant'),

    # ------------------------------------------------------------------
    # 02E353  Voice sub-slot struct initializer
    # Given voice (A) and sub-slot (C), calls LABEL_0325FC to resolve
    # sub-slot address, then copies 0xB words from resolved struct
    # into 0x044FCE work area via BlockCopy_Words_BC_to_HL.
    # ------------------------------------------------------------------
    ('LABEL_02E353', 'VoiceSubSlot_Init',
     'Init single voice sub-slot: resolve via 0325FC, copy 0xB words from 0x045314'),

    # ------------------------------------------------------------------
    # 02E390  Data block — opaque .byte data
    # Raw bytes for voice sub-slot init variant.
    # ------------------------------------------------------------------
    ('LABEL_02E390', 'VoiceSubSlot_Init_AltData',
     'Opaque .byte data block: alternate voice sub-slot init variant'),

    # ------------------------------------------------------------------
    # 02E3E9-02E57D  Voice full parameter setup
    # For voice index (A):
    #   1. Call VoiceStruct_BulkInit to init base struct + sub-slots
    #   2. Loop sub-slots calling VoiceSubSlot_Init
    #   3. Read voice struct flag word, set/clear bit 7 at 0x044FAB
    #   4. Loop 8 iterations copying param bytes from 0x00F95D LUT
    #   5. Count active sub-slots (status bits [7:6]==0, bit5==0)
    #   6. If all 4 active, clear 0x0451A7
    #   7. Loop sub-slots copying per-slot param arrays from voice struct
    # ------------------------------------------------------------------
    ('LABEL_02E3E9', 'VoiceParam_FullSetup',
     'Full voice param setup: bulk init, sub-slot init, routing flags, param tables'),

    ('LABEL_02E3FF', 'VoiceParam_FullSetup_SubSlotInitLoop',
     'Per-sub-slot: call VoiceSubSlot_Init for each of 4 sub-slots'),

    ('LABEL_02E41A', 'VoiceParam_FullSetup_SetRoutingBit',
     'Read flag word, set/clear bit 7 at 0x044FAB based on bit 15'),

    ('LABEL_02E43B', 'VoiceParam_FullSetup_ClearRoutingBit',
     'Clear bit 7 at 0x044FAB (flag word bit 15 is zero)'),

    ('LABEL_02E440', 'VoiceParam_FullSetup_CopyLUT',
     'Loop 8 times: copy param bytes from 0x00F95D to 0x044FCE+offset'),

    ('LABEL_02E449', 'VoiceParam_FullSetup_CopyLUT_Body',
     'Per-iteration: resolve LUT address, copy byte via ld_srib3/lda_dri3'),

    ('LABEL_02E476', 'VoiceParam_FullSetup_CountActive',
     'Count active sub-slots: check status bits and bit 5 for each'),

    ('LABEL_02E480', 'VoiceParam_FullSetup_CountActive_Loop',
     'Per-sub-slot: read status byte, skip if bits [7:6] nonzero or bit 5 set'),

    ('LABEL_02E4B7', 'VoiceParam_FullSetup_CountActive_Next',
     'Increment 0xFB counter and loop back'),

    ('LABEL_02E4BF', 'VoiceParam_FullSetup_CheckAllActive',
     'If active count != 4, clear 0x0451A7 to zero'),

    ('LABEL_02E4C9', 'VoiceParam_FullSetup_CopySlotParams',
     'Outer loop: iterate 4 sub-slots copying per-slot param arrays'),

    ('LABEL_02E4D2', 'VoiceParam_FullSetup_CopySlotParams_Body',
     'Per-sub-slot: read voice struct type, compute slot offsets, inner copy loop'),

    ('LABEL_02E51D', 'VoiceParam_FullSetup_CopySlotParams_Inner',
     'Inner loop: copy per-slot param words via ld/st with multi-reg addressing'),

    ('LABEL_02E574', 'VoiceParam_FullSetup_CopySlotParams_OuterNext',
     'Increment 0xFB outer counter and loop back to CopySlotParams_Body'),

    ('LABEL_02E57D', 'VoiceParam_FullSetup_Return',
     'Pop xiz, clean up stack, return from VoiceParam_FullSetup'),

    # ------------------------------------------------------------------
    # 02E581  Data block — opaque .byte data
    # Extended voice setup variant (raw bytes, not yet disassembled).
    # ------------------------------------------------------------------
    ('LABEL_02E581', 'VoiceParam_FullSetup_ExtData',
     'Opaque .byte data block: extended voice setup variant'),

    # ------------------------------------------------------------------
    # 02EC0A-02ECBB  Voice allocation check
    # For voice index (A), checks current allocation state:
    #   - If current voice matches 0x0451A4 and index > 2, check flag
    #     bits [1:0]; if == 3, skip (already fully allocated)
    #   - Else: set OR bit 0 in flag word, then if bit 0 was previously
    #     clear, call VoiceParam_FullSetup, then call LABEL_032938 for
    #     voice state dispatch
    # ------------------------------------------------------------------
    ('LABEL_02EC0A', 'VoiceAlloc_CheckAndInit',
     'Check voice allocation state; if newly allocated, init via VoiceParam_FullSetup'),

    ('LABEL_02EC38', 'VoiceAlloc_SetFlagBit0',
     'Set flag bit 0 in voice struct; check if it was already set'),

    ('LABEL_02EC65', 'VoiceAlloc_InitNewAllocation',
     'Flag bit 0 was clear: set it, call VoiceParam_FullSetup + voice state dispatch'),

    ('LABEL_02ECBB', 'VoiceAlloc_CheckAndInit_Return',
     'Clean up stack and return from VoiceAlloc_CheckAndInit'),

    ('LABEL_02ECBE', 'VoiceAlloc_CheckAndInit_ExtData',
     'Opaque .byte data block: extended voice allocation variant'),

    # ------------------------------------------------------------------
    # 02F50D-02F527  Voice allocation wrapper
    # Wrapper around VoiceAlloc_CheckAndInit: calls it, then sets or
    # clears bit 7 at memory address 282667 (0x044FAB) based on the
    # C register arg (0 -> clear, nonzero -> set).
    # ------------------------------------------------------------------
    ('LABEL_02F50D', 'VoiceAlloc_WithRoutingFlag',
     'Call VoiceAlloc_CheckAndInit, then set/clear routing bit at 0x044FAB'),

    ('LABEL_02F522', 'VoiceAlloc_WithRoutingFlag_Clear',
     'C==0 path: clear bit 7 at 0x044FAB'),

    ('LABEL_02F527', 'VoiceAlloc_WithRoutingFlag_Return',
     'Clean up stack and return'),

    ('LABEL_02F52A', 'VoiceAlloc_WithRoutingFlag_ExtData',
     'Opaque .byte data block: extended voice allocation/routing variant'),

    # ------------------------------------------------------------------
    # 030632-030635  DSP_EffectStateQuery continuation
    # Short tail of DSP_EffectStateQuery: writes 0 or 1 to (XBC)
    # based on bit 0 of voice struct flag word.
    # ------------------------------------------------------------------
    ('LABEL_030632', 'DSP_EffectStateQuery_WriteZero',
     'Bit 0 clear path: write 0 to (XBC)'),

    ('LABEL_030635', 'DSP_EffectStateQuery_SetResult',
     'Set HL=1 (success) and return'),

    # ------------------------------------------------------------------
    # 030638-030817  DSP voice parameter adjustment
    # Iterates 4 sub-slots (WERP 0xFA counter), for each:
    #   - Reads voice struct type byte (offset +54) bits [2:0]
    #   - Dispatches: type 1-4 -> apply portamento (offset +77) with
    #     ClampS8_0_to_78; type 5 -> also apply second portamento (+79)
    #   - Applies reverb send (+39) and chorus send (+45) adjustments
    #     via ClampS16_WA_To_DEBC with [0, 0xFF] range
    # After the loop, applies vibrato depth offsets (+43, +59) from
    # 0x0451A7 and filter offsets (+44, +60) from 0x0451A8.
    # ------------------------------------------------------------------
    ('LABEL_030638', 'DSP_AdjustVoiceParams',
     'Iterate 4 sub-slots: apply portamento/reverb/chorus/vibrato parameter adjustments'),

    ('LABEL_03066F', 'DSP_AdjustVoiceParams_SlotLoop',
     'Per-sub-slot: read type, dispatch to appropriate param adjustment path'),

    ('LABEL_0306A3', 'DSP_AdjustVoiceParams_Type1to4',
     'Type 1-4: apply portamento offset (+77) via ClampS8_0_to_78'),

    ('LABEL_0306EC', 'DSP_AdjustVoiceParams_Type5',
     'Type 5: apply portamento (+77) AND second portamento (+79)'),

    ('LABEL_030778', 'DSP_AdjustVoiceParams_ReverbChorus',
     'Apply reverb send (+39) and chorus send (+45) via ClampS16 [0, 0xFF]'),

    ('LABEL_030817', 'DSP_AdjustVoiceParams_Vibrato',
     'After loop: apply vibrato depth from 0x0451A7 to offsets +43/+59'),

    ('LABEL_03087F', 'DSP_AdjustVoiceParams_Filter',
     'Apply filter depth from 0x0451A8 to offsets +44/+60 and +46/+62'),

    # ------------------------------------------------------------------
    # 0309C0-030A08  DSP_AlgoSelect continuation
    # After algo allocation succeeds: write algo buffer, dispatch voice
    # state, clear result byte, return.  Also: DSP_MixSendConfig
    # helper copy loop.
    # ------------------------------------------------------------------
    ('LABEL_0309C0', 'DSP_AlgoSelect_WriteAndDispatch',
     'Write algo buffer, dispatch voice state (0xFF, 0xFF), clear result'),

    ('LABEL_0309E4', 'DSP_AlgoSelect_Return',
     'Set HL=1, pop xiz, clean up stack, return from DSP_AlgoSelect'),

    ('LABEL_0309FC', 'DSP_MixSendConfig_CopyLoop',
     'Copy loop body: ld_spib/lda_dpi, copy 0x11 bytes'),

    ('LABEL_030A08', 'DSP_MixSendConfig_Return',
     'Pop xiz and return from DSP_MixSendConfig'),

    ('LABEL_030A0A', 'DSP_MixSendConfig_ExtData',
     'Opaque .byte data block: extended DSP mix/send routing variant'),

    # ------------------------------------------------------------------
    # 030FD3-031067  DSP_VoiceParamReadWrite multi-slot path
    # Loop body for the multi-slot parameter read.  For each of 4
    # sub-slots, checks if slot is active (status bits and bit 5).
    # After loop, reads default param from 0x0F95D LUT if all 4 slots
    # are inactive.
    # ------------------------------------------------------------------
    ('LABEL_030FD3', 'DSP_VoiceParam_MultiSlot_LoopBody',
     'Per-sub-slot: resolve struct, check status bits [7:6] and bit 5 for activity'),

    ('LABEL_031041', 'DSP_VoiceParam_MultiSlot_LoopNext',
     'Increment sub-slot counter and loop back'),

    ('LABEL_03104B', 'DSP_VoiceParam_MultiSlot_CheckResult',
     'After loop: check active count, read from LUT if all 4 inactive'),

    ('LABEL_031065', 'DSP_VoiceParam_MultiSlot_StoreResult',
     'Store param value to (XDE) output pointer'),

    ('LABEL_031067', 'DSP_VoiceParamReadWrite_Return',
     'Load HL from stack, pop xiz, clean up, return from DSP_VoiceParamReadWrite'),

    # ------------------------------------------------------------------
    # 03107F  Data block — opaque .byte data for DSP param read variant
    # ------------------------------------------------------------------
    ('LABEL_03107F', 'DSP_VoiceParam_ExtData',
     'Opaque .byte data block: extended DSP voice param read variant'),

    # ------------------------------------------------------------------
    # 0311BC-03122A  DSP_SetVoiceCoefficients inner logic
    # Coefficient table lookup: based on IX bits [7:6] and [5], selects
    # one of several coefficient data sources.  0xC0/0x80/0x40/0x00
    # modes use table at 0x045314+124 (ptr -> coefficient ROM data).
    # Bit 5 set (0x20) path uses LABEL_032AE0 for direct coefficient
    # lookup.  Finally copies 0xA words from resolved source to
    # output via ld_spib/lda_dpi loop.
    # ------------------------------------------------------------------
    ('LABEL_0311BC', 'DSP_SetCoeff_LoadTableBase',
     'Load coefficient table base pointer from 0x045314+124'),

    ('LABEL_0311C7', 'DSP_SetCoeff_ComputeIndex',
     'Compute table index: (DE<<7 + BC) * 2, lookup coefficient set'),

    ('LABEL_0311FD', 'DSP_SetCoeff_DirectLookup',
     'Bit 5 set: use LABEL_032AE0 for direct coefficient resolution'),

    ('LABEL_03120F', 'DSP_SetCoeff_CopyLoop',
     'Copy 0xA words from resolved coefficient source to output buffer'),

    ('LABEL_031218', 'DSP_SetCoeff_CopyLoop_Body',
     'Per-word: ld_spib from XIZ, lda_dpi to output, increment DE'),

    ('LABEL_03122A', 'DSP_SetCoeff_Return',
     'Pop xiz, clean up stack, return from DSP_SetVoiceCoefficients'),

    ('LABEL_03122F', 'DSP_SetCoeff_ExtData',
     'Opaque .byte data block: extended DSP coefficient setup variant'),

    # ------------------------------------------------------------------
    # 031A57-031A6C  DSP param write helper + NOP padding
    # Block copy helper: copies WA words from XIZ (src) to XBC (dst)
    # using ld_spib/lda_dpi post-increment copy.  IX is loop counter.
    # Followed by a 6-byte NOP padding (.fill 6, 1, 0x0e).
    # ------------------------------------------------------------------
    ('LABEL_031A57', 'DSP_ParamWrite_BlockCopy',
     'Copy WA words from XIZ to XBC via post-increment ld_spib/lda_dpi loop'),

    ('LABEL_031A5F', 'DSP_ParamWrite_BlockCopy_Loop',
     'Per-word copy body: ld_spib + lda_dpi, increment IX, loop'),

    ('LABEL_031A6C', 'DSP_ParamWrite_NopPad',
     '6-byte NOP padding (.fill 6, 1, 0x0e) between routines'),

    # ------------------------------------------------------------------
    # 031AA1  ToneCmd_Dispatcher jump table body
    # Main tone/MIDI command dispatch: routes commands to note-on/off
    # handlers, velocity processors, channel assignment (BC=0-3), and
    # special command handlers via calr targets.
    # Already has a source comment; this label is the jump target from
    # Voice_ParamFinalize's dispatch table at 0x00FB2E.
    # ------------------------------------------------------------------
    ('LABEL_031AA1', 'ToneCmd_DispatchTable_Body',
     'Tone command dispatch: route by type to note-on/off/velocity/channel handlers'),

    # ------------------------------------------------------------------
    # 031B39-031B5B  Voice_ParamFinalize secondary dispatch
    # When bit 3 of (xiz) is clear, dispatches on bits [2:0] using
    # a second jump table at 0x00FB1E.  The body at 031B5B contains
    # the actual per-type handler logic (in .byte form).
    # ------------------------------------------------------------------
    ('LABEL_031B39', 'VoiceParamFinalize_SecondaryDispatch',
     'Bit 3 clear path: dispatch on bits [2:0] via jump table at 0x00FB1E'),

    ('LABEL_031B5B', 'VoiceParamFinalize_SecondaryBody',
     'Secondary dispatch handler body (opaque .byte data with embedded logic)'),

    # ------------------------------------------------------------------
    # 031E2D-031E68  Voice_ParamFinalize epilogue
    # Copies 6 bytes from XIZ struct to work area at 0x045210, then
    # calls function at 0x20C6B with the count and work area pointer.
    # ------------------------------------------------------------------
    ('LABEL_031E2D', 'VoiceParamFinalize_CopyToWorkArea',
     'Copy 6 bytes from XIZ to work area at 0x045210'),

    ('LABEL_031E33', 'VoiceParamFinalize_CopyLoop',
     'Per-byte copy: (XIZ+IX) -> (0x045210+IX), IX=0..5'),

    ('LABEL_031E50', 'VoiceParamFinalize_CallDispatch',
     'Call function at 0x20C6B with work area params'),

    ('LABEL_031E68', 'VoiceParamFinalize_Return',
     'Pop xiz and return from Voice_ParamFinalize'),

    # ------------------------------------------------------------------
    # 031ECF-031F00  DSP_WriteVoiceParam mode dispatch
    # Dispatches on voice status bits [7:6] to select write mode:
    #   0x00 -> copy params via DSP_ParamWrite_BlockCopy
    #   0x40 -> return HL=0 (no write)
    #   0x80 -> copy params via DSP_ParamWrite_BlockCopy (alt offset)
    #   0xC0 -> return HL=0 (no write)
    # ------------------------------------------------------------------
    ('LABEL_031ECF', 'DSP_WriteVoiceParam_Mode40',
     'Mode 0x40: return HL=0 (no write for this voice state)'),

    ('LABEL_031ED3', 'DSP_WriteVoiceParam_Mode80',
     'Mode 0x80: resolve voice struct, copy params via BlockCopy'),

    ('LABEL_031EFE', 'DSP_WriteVoiceParam_ModeC0',
     'Mode 0xC0: return HL=0 (no write for this voice state)'),

    ('LABEL_031F00', 'DSP_WriteVoiceParam_Return',
     'Pop iz, clean up stack, retd 4 from DSP_WriteVoiceParam'),

    # ------------------------------------------------------------------
    # 031F16  DSP voice buffer lookup variant A (coefficient table path)
    # Called from DSP_LookupVoiceBuffer when flag at 0x041343 bit 0 is set.
    # Resolves a voice buffer pointer via coefficient ROM tables:
    # index -> table at 0x045314+108 -> bank byte -> shift/add -> ptr.
    # Returns XHL = resolved buffer pointer.
    # ------------------------------------------------------------------
    ('LABEL_031F16', 'DSP_LookupVoiceBuffer_CoeffPath',
     'Voice buffer lookup via coefficient ROM tables at 0x045314+108'),

    # ------------------------------------------------------------------
    # 031F71-031FE4  DSP voice buffer lookup variant B
    # Called from DSP_LookupVoiceBuffer when flag bit 0 is clear.
    # Validates param index BC: 0-7, 0x40, 0x41, 0x70 are valid;
    # all others fall through to a different lookup at 031FE4+.
    # For valid indices, uses table at 0x045314+4.
    # ------------------------------------------------------------------
    ('LABEL_031F71', 'DSP_LookupVoiceBuffer_ParamPath',
     'Voice buffer lookup via param index validation and table at 0x045314+4'),

    ('LABEL_031F87', 'DSP_LookupVoiceBuffer_ParamPath_Valid',
     'Valid param index: resolve via 0x045314+4 table, shift/add, return XHL'),

    ('LABEL_031FE4', 'DSP_LookupVoiceBuffer_ParamPath_Special',
     'Special param indices (0x10, 0x15, 0x50, 0x55): alternate lookup paths'),
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
            print(f'  {old_label:25s} -> {new_label:45s} ({refs} refs)')

    # Check maincpu for cross-references (none expected for 02E/031 range,
    # but guard against surprises).
    maincpu_src = os.path.join(base, 'maincpu', 'kn5000_v10_program.s')
    with open(maincpu_src, 'rb') as f:
        maincpu_content = f.read().decode('latin-1')

    maincpu_renames = 0
    for old_label, new_label, _ in RENAMES:
        if old_label in maincpu_content:
            maincpu_content = re.sub(r'\b' + re.escape(old_label) + r'\b', new_label,
                                     maincpu_content)
            maincpu_renames += 1

    with open(src, 'wb') as f:
        f.write(content.encode('latin-1'))

    if maincpu_renames > 0:
        with open(maincpu_src, 'wb') as f:
            f.write(maincpu_content.encode('latin-1'))
        print(f'  (also updated {maincpu_renames} cross-refs in maincpu)')

    print(f'\nRenamed {renamed} labels in subcpu ({maincpu_renames} cross-refs in maincpu)')


if __name__ == '__main__':
    main()
