#!/usr/bin/env python3
"""Rename LABEL_* to semantic names for the DSP floating-point library in subcpu
(03D-03E address range).

This range implements a software floating-point library used by the DSP parameter
translation engine (DSP_ParameterWriteEngine / DSP_PerParameterTranslator).
Two formats are used throughout:

  DP (double-precision internal): 12 bytes — exponent word + 4-byte low-mantissa
      + 4-byte high-mantissa, stored in (XWA), (XWA+4), (XWA+8).
  SP (single-precision internal): 8 bytes  — exponent word + 4-byte mantissa,
      stored in (XWA), (XWA+4).

The format is NOT standard IEEE-754; it is a custom fixed-exponent representation
used by the firmware's voice parameter interpolation system.

Address groups:
  03D008-03D013  Branches inside Audio_CmdHandler_A0_BF
  03D34D-03D98A  Voice float operation dispatcher (ToneGen region)
  03D98A-03DCDD  FP arithmetic core: compare, divide, copy
  03DCE6-03DF9C  FP primitives: copy, negate, decode, normalize
  03DF9C-03E10E  FP encode/decode (IEEE-like → internal, internal → IEEE-like)
  03E10E-03E290  FP multiply (DP and SP), voice register update
  03E290-03E4B4  FP add/align/multiply outer wrappers
  03E4B4-03E6CB  SP multiply, DP/SP subtract
  03E6CB-03E87E  Voice pitch slide and amplitude convergence engines
  03E884-03EA9C  DSP voice register update, float copy/decode variants
  03EA9C-03EE75  Voice frequency envelope, mantissa multiply, division, negate

Uses binary I/O to handle Latin-1 encoding safely.
"""

import os
import re

# Renames: (old_label, new_label, brief_comment)
RENAMES = [

    # -----------------------------------------------------------------------
    # 03D008-03D013: Branch targets inside Audio_CmdHandler_A0_BF
    # -----------------------------------------------------------------------
    ('LABEL_03D008', 'CmdA0BF_CheckSubByte',
     'Branch: check sub-byte of command when byte 0 == 1'),
    ('LABEL_03D013', 'CmdA0BF_Return',
     'Common return path from Audio_CmdHandler_A0_BF'),

    # -----------------------------------------------------------------------
    # 03D34D-03D533: Voice float dispatcher — top-level operations
    # -----------------------------------------------------------------------
    ('LABEL_03D34D', 'VoiceFloat_DispatchMulAdd',
     'Dispatch: unpack two voice float pointers, call FP mul-add, then copy result'),
    ('LABEL_03D3A4', 'VoiceFloat_SubDP',
     'Unpack two DP floats into stack buffers, subtract, write result via FP_DP_Encode'),
    ('LABEL_03D3D4', 'VoiceFloat_SubSP',
     'Unpack two SP floats into stack buffers, subtract, write result via FP_SP_Encode'),

    # -----------------------------------------------------------------------
    # 03D404-03D42E: 8-byte / 4-byte float copy with in-place sign negate
    # -----------------------------------------------------------------------
    ('LABEL_03D404', 'FP_DP_CopyOrNegate8',
     'Copy 8 bytes XBC->XWA; if XWA==XBC, flip sign bit (byte 7 bit 7)'),
    ('LABEL_03D417', 'FP_DP_NegateInPlace8',
     'Flip sign bit of 8-byte float at XWA (called when src==dst)'),
    ('LABEL_03D41C', 'FP_SP_CopyOrNegate4',
     'Copy 4 bytes XBC->XWA; if XWA==XBC, flip sign bit (byte 3 bit 7)'),
    ('LABEL_03D429', 'FP_SP_NegateInPlace4',
     'Flip sign bit of 4-byte float at XWA (called when src==dst)'),

    # -----------------------------------------------------------------------
    # 03D42E-03D465: Compare-and-copy dispatcher
    # -----------------------------------------------------------------------
    ('LABEL_03D42E', 'FP_DP_CmpAndCopy',
     'Compare DP float via FP_DP_CmpZero64; if zero call FP_DP_Raw8Copy, else FP_DP_CopyOrNegate8'),
    ('LABEL_03D446', 'FP_DP_CmpAndCopy_Negate',
     'Branch: non-zero result path — call FP_DP_CopyOrNegate8'),
    ('LABEL_03D44B', 'FP_DP_CmpAndCopy_Pad',
     'Padding byte (0xFF) between routines'),
    ('LABEL_03D44C', 'FP_SP_Decode_ReadSign',
     'Decode SP float (XBC) to stack buffer, read sign via FP_SP_DecodeToInt; store integer at (XIZ)'),
    ('LABEL_03D465', 'FP_SP_Decode_ReadSign_Pad',
     'Padding byte (0xFF) between routines'),

    # -----------------------------------------------------------------------
    # 03D466-03D4BE: Compare DP or SP float to zero, return result code
    # Three-way result: equal=0, less=1, greater=2 (via lookup table at 03D978)
    # -----------------------------------------------------------------------
    ('LABEL_03D466', 'FP_DP_CmpZero64',
     'Compare 64-bit DP float at (XWA) to zero; return comparison result code in HL'),
    ('LABEL_03D484', 'FP_DP_CmpZero64_Less',
     'Result: 64-bit value < 0 — load less-than result from table 03D97E'),
    ('LABEL_03D48F', 'FP_DP_CmpZero64_Greater',
     'Result: 64-bit value > 0 — load greater-than result from table 03D984'),
    ('LABEL_03D49A', 'FP_SP_CmpZero32',
     'Compare 32-bit SP float at (XWA) to zero; return comparison result code in HL'),
    ('LABEL_03D4B3', 'FP_SP_CmpZero32_Less',
     'Result: 32-bit value < 0 — load less-than result from table 03D97E'),
    ('LABEL_03D4BE', 'FP_SP_CmpZero32_Greater',
     'Result: 32-bit value > 0 — load greater-than result from table 03D984'),

    # -----------------------------------------------------------------------
    # 03D4C9-03D84F: Voice float operation — main dispatcher
    # Performs range check (0x41E0), then dispatches to convergence sub-ops.
    # -----------------------------------------------------------------------
    ('LABEL_03D4C9', 'VoiceFloat_MulAddDispatch',
     'Top-level voice float op: range check, dispatch to sub-ops or copy constant'),
    ('LABEL_03D4F1', 'VoiceFloat_MulAddDispatch_InRange',
     'Within-range path: call sub-ops then blend result'),
    ('LABEL_03D52E', 'VoiceFloat_MulAddDispatch_Epilog',
     'Epilog: pop XIZ, restore stack, return'),
    ('LABEL_03D533', 'VoiceFloat_CompareAndConvert',
     'Compare voice float against two table ranges, convert or mark invalid'),
    ('LABEL_03D567', 'VoiceFloat_CompareAndConvert_Invalid',
     'Mark voice float as invalid (0xFFFFFFFF) when out of both table ranges'),
    ('LABEL_03D56F', 'VoiceFloat_CompareAndConvert_AfterRange',
     'Continue processing after table-range compare'),
    ('LABEL_03D5AC', 'VoiceFloat_CompareAndConvert_AltPath',
     'Alternate range path: compare against third table range'),
    ('LABEL_03D5DC', 'VoiceFloat_CompareAndConvert_AltPath2',
     'Second alternate path: extract signed delta, iterate toward target'),
    ('LABEL_03D60F', 'VoiceFloat_SignedDelta_Positive',
     'Signed delta is positive — load table 01F666 and store result'),
    ('LABEL_03D61E', 'VoiceFloat_IterationLoop',
     'Iteration loop: call FP_DP_FreqAdjust for each step of convergence'),
    ('LABEL_03D671', 'VoiceFloat_IterationLoop_GreaterPath',
     'Iteration: source > dest — call FP_DP_CopyOrNegate8 with table ptr 00F420'),
    ('LABEL_03D67A', 'VoiceFloat_IterationLoop_LessPath',
     'Iteration: source < dest — call FP_DP_Raw8Copy with table ptr 01F66E'),
    ('LABEL_03D686', 'VoiceFloat_IterationLoop_CopyResult',
     'Copy iteration result to output buffer via FP_DP_Raw8Copy'),
    ('LABEL_03D693', 'VoiceFloat_IterationLoop_LargeStep',
     'Large-step path (wa > 0x400): apply clamp, choose copy or negate'),
    ('LABEL_03D6BD', 'VoiceFloat_IterationLoop_LargeStep_NegPath',
     'Large-step negate path: call FP_DP_Raw8Copy with table ptr 00F420'),
    ('LABEL_03D6C9', 'VoiceFloat_IterationLoop_LargeStep_Copy',
     'Large-step copy result to output'),
    ('LABEL_03D6D6', 'VoiceFloat_IterationLoop_SmallStep',
     'Small-step path (wa <= 0x400): bit-test, then apply FP_DP_Add outer'),
    ('LABEL_03D6E7', 'VoiceFloat_IterationLoop_SmallStep_Add',
     'Small step: add XDE (from XBC) via FP_DP_Add_Outer, then arithmetic-shift delta'),
    ('LABEL_03D6FB', 'VoiceFloat_IterationLoop_CheckContinue',
     'Check if remaining delta is zero; if not, loop back to VoiceFloat_IterationLoop'),
    ('LABEL_03D71D', 'VoiceFloat_IterationLoop_DifferentPath',
     'Different-direction path: blend via VoiceFloat_SubDP with table 01F676'),
    ('LABEL_03D72F', 'VoiceFloat_ConvergenceLoop',
     'Convergence loop: bisect-blend until target == 0x0021 or steps exhausted'),
    ('LABEL_03D768', 'VoiceFloat_ConvergenceLoop_Body',
     'Convergence loop body: call FP_DP_FreqAdjust twice, sum results, check range'),
    ('LABEL_03D7B2', 'VoiceFloat_ConvergenceLoop_SumCheck',
     'Sum-check: if either component negative, negate sum; compare to ±0x400'),
    ('LABEL_03D7CB', 'VoiceFloat_ConvergenceLoop_RangeCheck',
     'Range check on IZ: > 0x400 → clamp; <= 0x400 → bit-step or cross-zero'),
    ('LABEL_03D7F3', 'VoiceFloat_ConvergenceLoop_NegResult',
     'Convergence result is negative — call FP_DP_Raw8Copy'),
    ('LABEL_03D7F7', 'VoiceFloat_ConvergenceLoop_StoreResult',
     'Store convergence result into output buffer via FP_DP_Raw8Copy'),
    ('LABEL_03D803', 'VoiceFloat_ConvergenceLoop_Clamp',
     'Clamp convergence step: iz <= ±0x400 — store constant table result'),
    ('LABEL_03D81E', 'VoiceFloat_ConvergenceLoop_CrossZero',
     'Cross-zero path: blend src and target via FP_DP_Add_Outer, then call FP_DP_FreqAdjust'),
    ('LABEL_03D84A', 'VoiceFloat_CompareAndConvert_Epilog',
     'Epilog: pop XIZ, restore large stack frame, return'),

    # -----------------------------------------------------------------------
    # 03D84F-03D8CA: Voice float op variant 2 (shorter frame, 3-arg)
    # -----------------------------------------------------------------------
    ('LABEL_03D84F', 'VoiceFloat_MulAddVariant2',
     'Voice float op variant 2: compare and dispatch like MulAddDispatch but 3-arg form'),
    ('LABEL_03D89A', 'VoiceFloat_MulAddVariant2_AltPath',
     'Variant 2 alt path: push 0 flag and call VoiceFloat_BlendAndMerge'),
    ('LABEL_03D8C5', 'VoiceFloat_MulAddVariant2_Epilog',
     'Epilog: pop XIZ, restore stack, return'),

    # -----------------------------------------------------------------------
    # 03D8CA: 64-bit multiply-add accumulator (integer, used in FP mul)
    # -----------------------------------------------------------------------
    ('LABEL_03D8CA', 'FP_MulAccum64',
     '64-bit multiply-accumulate: XHL:XDE += XWA*XBC (32x32 → 64 partial products)'),

    # -----------------------------------------------------------------------
    # 03D8E0-03D969: DP and SP floating-point subtract (internal format)
    # -----------------------------------------------------------------------
    ('LABEL_03D8E0', 'FP_DP_Sub',
     'Subtract two DP floats: decode XWA and (XDE) into stack, call FP_DP_Align+FP_DP_SubMantissa, encode'),
    ('LABEL_03D919', 'FP_DP_Sub_SameSign',
     'DP subtract: signs are equal — call FP_DP_AddMantissa (cancel)'),
    ('LABEL_03D91D', 'FP_DP_Sub_Done',
     'DP subtract epilog: encode result via FP_DP_Encode, restore stack'),
    ('LABEL_03D92B', 'FP_SP_Sub_Pad',
     'Padding byte (0xFF) between routines'),
    ('LABEL_03D92C', 'FP_SP_Sub',
     'Subtract two SP floats: decode XWA and (XDE) into stack, call FP_SP_Align+FP_SP_SubMantissa, encode'),
    ('LABEL_03D965', 'FP_SP_Sub_SameSign',
     'SP subtract: signs are equal — call FP_SP_AddMantissa (cancel)'),
    ('LABEL_03D969', 'FP_SP_Sub_Done',
     'SP subtract epilog: encode result via FP_SP_Encode, restore stack'),

    # -----------------------------------------------------------------------
    # 03D98A-03DC14: Voice float blend/merge dispatcher (largest function)
    # -----------------------------------------------------------------------
    ('LABEL_03D98A', 'VoiceFloat_BlendAndMerge',
     'Blend and merge two voice float structures: range-check, multi-phase copy+add+blend'),
    ('LABEL_03D9B5', 'VoiceFloat_BlendAndMerge_InRange',
     'Within-range path: setup scratch buffer, call FP_DP_Add_Outer, unpack pointers'),
    ('LABEL_03D9FF', 'VoiceFloat_BlendAndMerge_Phase2',
     'Phase 2: optional table range check, call FP_DP_Sub on first component'),
    ('LABEL_03DA1F', 'VoiceFloat_BlendAndMerge_Phase3',
     'Phase 3: store component B, call FP_DP_CmpAndCopy and FP_SP_Mul_Outer'),
    ('LABEL_03DA56', 'VoiceFloat_BlendAndMerge_Phase4',
     'Phase 4: iterate over six component pairs, apply sub/add/copy in sequence'),
    ('LABEL_03DBEF', 'VoiceFloat_BlendAndMerge_FinalCheck',
     'Final: if scratch flag set, negate or skip; call FP_DP_Raw8Copy for output'),
    ('LABEL_03DC01', 'VoiceFloat_BlendAndMerge_FinalCopy',
     'Final copy: load result pointer, call FP_DP_Raw8Copy'),
    ('LABEL_03DC0D', 'VoiceFloat_BlendAndMerge_Epilog',
     'Epilog: pop XIZ, store L to result byte, return'),

    # -----------------------------------------------------------------------
    # 03DC14-03DCDD: Signed integer division
    # -----------------------------------------------------------------------
    ('LABEL_03DC14', 'Int_SignedDiv',
     'Signed division: extract signs of XWA and XBC, call unsigned div, fix sign of result'),
    ('LABEL_03DC25', 'Int_SignedDiv_AfterSignA',
     'After extracting sign of A: check sign of B'),
    ('LABEL_03DC35', 'Int_SignedDiv_CallUnsigned',
     'Call unsigned division FP_UnsignedDiv, then correct result sign'),
    ('LABEL_03DC47', 'Int_SignedDiv_ResultCorr',
     'Result correction: if quotient sign == 3, return'),
    ('LABEL_03DC4B', 'Int_SignedDiv_NegResult',
     'Negate XHL if result should be negative'),
    ('LABEL_03DC5B', 'Int_SignedDiv_ConstData',
     'Constant data bytes used by division (0xFF pad / alignment)'),
    ('LABEL_03DC5F', 'Int_SignedDiv_AltEntry',
     'Alternate entry: set D=1, then signed divide via FP_UnsignedDiv'),
    ('LABEL_03DC69', 'FP_UnsignedDiv',
     'Unsigned integer division: XHL:XDE = XWA / XBC (handles BC=1, BC>WA, overflow)'),
    ('LABEL_03DC8C', 'FP_UnsignedDiv_Overflow',
     'Overflow path: two-phase division via upper/lower halves'),
    ('LABEL_03DCA2', 'FP_UnsignedDiv_ByOne',
     'Divisor == 1: return XWA unchanged in XHL, XDE = 0'),
    ('LABEL_03DCA7', 'FP_UnsignedDiv_Zero',
     'Divisor == 0 (or dividend < divisor): return quotient 0, remainder 0xFFFFFFFF'),
    ('LABEL_03DCAE', 'FP_UnsignedDiv_SmallDividend',
     'Dividend <= divisor: return quotient 1 and remainder, or 0 and dividend'),
    ('LABEL_03DCB9', 'FP_UnsignedDiv_General',
     'General case: shift divisor left until >= dividend, count shift'),
    ('LABEL_03DCBB', 'FP_UnsignedDiv_ShiftLoop',
     'Shift loop: double XBC until XBC >= XWA or overflow'),
    ('LABEL_03DCCD', 'FP_UnsignedDiv_ShiftLoopDone',
     'Shift done without overflow: shift right by 1 to correct'),
    ('LABEL_03DCD0', 'FP_UnsignedDiv_Subtract',
     'Initialize quotient accumulator XHL = 0'),
    ('LABEL_03DCD2', 'FP_UnsignedDiv_SubtractLoop',
     'Non-restoring subtraction loop: build quotient bit by bit'),
    ('LABEL_03DCDD', 'FP_UnsignedDiv_Done',
     'Division complete: XHL = quotient, XDE = remainder'),

    # -----------------------------------------------------------------------
    # 03DCE6-03DD50: Low-level FP data copy primitives
    # -----------------------------------------------------------------------
    ('LABEL_03DCE6', 'FP_DP_Raw8Copy',
     'Copy 8 bytes from (XBC) to (XWA): loads XBC[0..3] and XBC[4..7], stores to XWA'),
    ('LABEL_03DCF1', 'FP_DP_Raw8Copy_Pad',
     'Padding byte (0xFF) between routines'),
    ('LABEL_03DCF2', 'FP_DP_NegMantissaLS',
     'Negate low-significance mantissa of DP float: shift out 3 LSBs, flip, re-store'),
    ('LABEL_03DD28', 'FP_DP_NegMantissaLS_Store',
     'Store negated mantissa words back and encode result via FP_DP_Encode'),
    ('LABEL_03DD35', 'FP_ScalarToDP_Pad',
     'Padding byte (0xFF) between routines'),
    ('LABEL_03DD36', 'FP_ScalarToDP',
     'Convert 32-bit integer (XBC) to DP float internal format; write to (XWA) buffer'),

    # -----------------------------------------------------------------------
    # 03DD51-03DDCA: Stack-buffer call wrappers (CallWithBuffer pattern)
    # -----------------------------------------------------------------------
    ('LABEL_03DD51', 'FP_DP_CallWithBuf12',
     'Allocate 12-byte stack buffer, call function pointer from (XBC), encode result'),
    ('LABEL_03DD6C', 'FP_DP_NormalizeMantissa',
     'Normalize DP float mantissa: round three low bits, propagate carry to upper word'),
    ('LABEL_03DDB3', 'FP_DP_NormalizeMantissa_StoreHL',
     'Store normalized mantissa upper word (XHL) back to stack buffer'),
    ('LABEL_03DDB6', 'FP_DP_NormalizeMantissa_Encode',
     'Encode normalized DP float from stack buffer via FP_DP_Encode'),
    ('LABEL_03DDC3', 'FP_SP_Raw4Copy_Pad',
     'Padding byte (0xFF) between routines'),
    ('LABEL_03DDC4', 'FP_SP_Raw4Copy',
     'Copy 4 bytes from (XBC) to (XWA): ld xix,(xbc); ld (xwa),xix'),
    ('LABEL_03DDC9', 'FP_SP_CallWithBuf8_Pad',
     'Padding byte (0xFF) between routines'),
    ('LABEL_03DDCA', 'FP_SP_CallWithBuf8',
     'Allocate 8-byte stack buffer, call function pointer from (XBC), encode SP float result'),
    ('LABEL_03DDE5', 'FP_SP_CallWithBuf8b',
     'Allocate 8-byte stack buffer (variant b), call function pointer, encode SP float result'),

    # -----------------------------------------------------------------------
    # 03DE00-03DE88: DP float decode / integer conversion
    # -----------------------------------------------------------------------
    ('LABEL_03DE00', 'FP_DP_DecodeToInt',
     'Decode DP float at (XBC) into stack, read integer value via FP_DP_ShiftDecode; store in (XIZ)'),
    ('LABEL_03DE19', 'FP_DP_Normalize_Pad',
     'Padding byte (0xFF) between routines'),
    ('LABEL_03DE1A', 'FP_DP_Normalize',
     'Normalize DP float: extract sign of XBC, call FP_DP_NormCore, store sign byte at (XIY+3)'),
    ('LABEL_03DE2C', 'FP_DP_Normalize_StoreSign',
     'Store sign byte at (XIY+3) after normalization'),
    ('LABEL_03DE33', 'FP_DP_NormCore',
     'DP normalization core: find leading bit via BS1B, compute exponent offset, shift mantissa'),
    ('LABEL_03DE43', 'FP_DP_NormCore_Overflow',
     'Normalization overflow: use D9 prefix to extract upper bits'),
    ('LABEL_03DE45', 'FP_DP_NormCore_Shift',
     'Normalization shift: set exponent in (XIY+2), shift mantissa by computed amount'),
    ('LABEL_03DE6F', 'FP_DP_NormCore_ShiftLeft',
     'Shift-left path: exponent < 0x17, left-shift mantissa by (0x17 - exp) bits'),
    ('LABEL_03DE82', 'FP_DP_NormCore_ShiftLeftLoop',
     'Left-shift loop: SLL mantissa one bit at a time'),
    ('LABEL_03DE84', 'FP_DP_NormCore_StoreResult',
     'Store normalized mantissa (XBC) into (XIY+4)'),
    ('LABEL_03DE88', 'FP_DP_NormCore_Zero',
     'Zero mantissa case: store 1 in exponent byte at (XIY+2), return'),

    # -----------------------------------------------------------------------
    # 03DE8D-03DF5E: DP float shift-decode (exponent → integer via shift)
    # -----------------------------------------------------------------------
    ('LABEL_03DE8D', 'FP_DP_ShiftDecode_Pad',
     'Padding byte (0xFF) between routines'),
    ('LABEL_03DE8E', 'FP_DP_ShiftDecode',
     'Decode DP float at (XWA) to integer XHL by shifting mantissa by exponent; set overflow at 0x040C22'),
    ('LABEL_03DEB3', 'FP_DP_ShiftDecode_ShiftRight',
     'Shift-right path: exponent < 0x17, right-shift mantissa by (0x17 - exp) bits'),
    ('LABEL_03DEC6', 'FP_DP_ShiftDecode_ShiftRightLoop',
     'Right-shift loop: SRL mantissa one bit at a time'),
    ('LABEL_03DEC8', 'FP_DP_ShiftDecode_SignCorrect',
     'Apply sign correction to decoded integer result'),
    ('LABEL_03DED4', 'FP_DP_ShiftDecode_Return',
     'Return decoded integer in XHL (sign-corrected)'),
    ('LABEL_03DED7', 'FP_DP_ShiftDecode_Underflow',
     'Exponent underflow: return XHL = 0 (value too small)'),
    ('LABEL_03DEDB', 'FP_DP_ShiftDecode_Overflow',
     'Exponent overflow: return XHL = 0xFFFFFFFF (saturate), set error flag'),
    ('LABEL_03DEDF', 'FP_DP_ShiftDecode_SetError',
     'Set overflow/error flag at 0x040C22 = 0x0022'),
    ('LABEL_03DEE7', 'FP_DP_ShiftDecode_Zero',
     'NaN/special-flag set: return XHL = 0'),

    # -----------------------------------------------------------------------
    # 03DEEA-03DF5E: DP and SP floating-point add (mantissa level)
    # -----------------------------------------------------------------------
    ('LABEL_03DEEA', 'FP_DP_AddMantissa',
     'Add two DP float mantissas: XDE:XHL += (XBC+4):(XBC+8), normalize carry, store in (XWA)'),
    ('LABEL_03DF31', 'FP_DP_AddMantissa_Store',
     'Store addition result XDE:XHL back into (XWA+4):(XWA+8)'),
    ('LABEL_03DF38', 'FP_SP_AddMantissa',
     'Add two SP float mantissas: XIX += (XBC+4), normalize carry bit, store in (XWA+4)'),
    ('LABEL_03DF5B', 'FP_SP_AddMantissa_Store',
     'Store SP addition result XIX back into (XWA+4)'),
    ('LABEL_03DF5F', 'FP_DP_Decode_Pad',
     'Padding byte (0xFF) between routines'),

    # -----------------------------------------------------------------------
    # 03DF60-03DF9B: Decode IEEE-like DP float (XBC) to 12-byte internal format (XWA)
    # -----------------------------------------------------------------------
    ('LABEL_03DF60', 'FP_DP_Decode',
     'Decode 8-byte IEEE-like DP float at (XBC) to 12-byte internal format at (XWA): sign/exp/mantissa'),
    ('LABEL_03DF92', 'FP_DP_Decode_Zero',
     'Zero/denormal case: set NaN flag byte at (XWA+2), clear mantissa'),

    # -----------------------------------------------------------------------
    # 03DF9C-03DFD5: Decode IEEE-like SP float (XBC) to 8-byte internal format (XWA)
    # -----------------------------------------------------------------------
    ('LABEL_03DF9C', 'FP_SP_Decode',
     'Decode 4-byte IEEE-like SP float at (XBC) to 8-byte internal format at (XWA): sign/exp/mantissa'),
    ('LABEL_03DFC5', 'FP_SP_Decode_Store',
     'Store decoded SP float exponent and mantissa into (XWA) buffer'),
    ('LABEL_03DFCE', 'FP_SP_Decode_Zero',
     'Zero/denormal case: set XBC=0, set NaN/zero flag, jump to store'),

    # -----------------------------------------------------------------------
    # 03DFD6-03E017: SP float normalize + SP normalization core
    # -----------------------------------------------------------------------
    ('LABEL_03DFD6', 'FP_SP_Normalize',
     'Normalize SP float: extract sign of XBC, call FP_SP_NormCore, store sign at (XIY+3)'),
    ('LABEL_03DFE8', 'FP_SP_Normalize_StoreSign',
     'Store sign byte at (XIY+3) after SP normalization'),
    ('LABEL_03DFEF', 'FP_SP_NormCore',
     'SP normalization core: find leading bit, compute exponent offset, shift mantissa into XBC+XIX'),
    ('LABEL_03DFFF', 'FP_SP_NormCore_Overflow',
     'Normalization overflow: use D9 prefix to extract upper bits into XIX'),
    ('LABEL_03E001', 'FP_SP_NormCore_Shift',
     'Set exponent in (XIY+2), determine shift amount; XBC = main, XIX = low bits'),
    ('LABEL_03E017', 'FP_SP_NormCore_ShiftRight',
     'Right-shift loop: SRL XBC + RRC XIX by one bit per count'),
    ('LABEL_03E025', 'FP_SP_NormCore_ShiftLeft',
     'Left-shift path: exponent < 0x14, left-shift XBC by (0x14 - exp) bits'),
    ('LABEL_03E038', 'FP_SP_NormCore_ShiftLeftLoop',
     'Left-shift loop: SLL XBC one bit at a time'),
    ('LABEL_03E03A', 'FP_SP_NormCore_StoreResult',
     'Store normalized XBC into (XIY+8) and XIX into (XIY+4)'),
    ('LABEL_03E041', 'FP_SP_NormCore_Zero',
     'Zero mantissa: set NaN/zero byte at (XIY+2), return'),

    # -----------------------------------------------------------------------
    # 03E046-03E0AE: Encode 12-byte internal DP float → 8-byte IEEE-like format
    # -----------------------------------------------------------------------
    ('LABEL_03E046', 'FP_DP_Encode',
     'Encode 12-byte internal DP float at (XBC) to 8-byte IEEE-like format at (XWA)'),
    ('LABEL_03E073', 'FP_DP_Encode_Store',
     'Store encoded mantissa XIY and XIX into (XWA) and (XWA+4)'),
    ('LABEL_03E079', 'FP_DP_Encode_Zero',
     'Encode zero result: XIX=XIY=0, jump to store'),
    ('LABEL_03E07F', 'FP_DP_Encode_NaN',
     'Encode NaN/infinity: check NaN flag byte; if zero-flag, encode zero'),
    ('LABEL_03E085', 'FP_DP_Encode_Overflow',
     'Encode overflow: set XDE=0xFFFFFFFF (max), set sign from register, set error flag'),
    ('LABEL_03E0A5', 'FP_DP_Encode_NormCheck',
     'Post-encode normalization check: read 0x00F428, call MRID2 normalizer'),
    ('LABEL_03E0AF', 'FP_SP_Encode_Pad',
     'Padding byte (0xFF) between routines'),

    # -----------------------------------------------------------------------
    # 03E0B0-03E10D: Encode 8-byte internal SP float → 4-byte IEEE-like format
    # -----------------------------------------------------------------------
    ('LABEL_03E0B0', 'FP_SP_Encode',
     'Encode 8-byte internal SP float at (XBC) to 4-byte IEEE-like format at (XWA)'),
    ('LABEL_03E0DE', 'FP_SP_Encode_NaN',
     'Encode NaN/infinity: check NaN flag; if 0x08 (inf), set zero mantissa'),
    ('LABEL_03E0EA', 'FP_SP_Encode_Zero',
     'Encode zero: XDE=0, store at (XWA), return'),
    ('LABEL_03E0EF', 'FP_SP_Encode_Overflow',
     'Encode overflow: DE=0xFFFF, BC=0x7F7F, combine sign, set error flag'),
    ('LABEL_03E0FB', 'FP_SP_Encode_Overflow_Store',
     'Store SP overflow value at (XWA) and call MRID2 normalizer'),

    # -----------------------------------------------------------------------
    # 03E10E-03E1A4: DP and SP floating-point multiply (outer wrappers)
    # Each wrapper decodes both operands, aligns exponents, multiplies, encodes.
    # -----------------------------------------------------------------------
    ('LABEL_03E10E', 'FP_DP_Mul',
     'Multiply two DP floats: decode XWA and (XIZ) into stack, align, call FP_DP_MulMantissa, encode'),
    ('LABEL_03E13C', 'FP_DP_Mul_SameSign',
     'DP multiply: same sign — call FP_DP_AddMantissa for product accumulation'),
    ('LABEL_03E142', 'FP_DP_Mul_DiffSign',
     'DP multiply: different sign — call FP_DP_SubMantissa for product subtraction'),
    ('LABEL_03E14B', 'FP_DP_Mul_Encode',
     'DP multiply epilog: encode product from stack via FP_DP_Encode, restore frame'),
    ('LABEL_03E159', 'FP_SP_Mul_Pad',
     'Padding byte (0xFF) between routines'),
    ('LABEL_03E15A', 'FP_SP_Mul',
     'Multiply two SP floats: decode XWA and (XIZ) into stack, align, call FP_SP_MulMantissa, encode'),
    ('LABEL_03E188', 'FP_SP_Mul_SameSign',
     'SP multiply: same sign — call FP_SP_AddMantissa'),
    ('LABEL_03E18E', 'FP_SP_Mul_DiffSign',
     'SP multiply: different sign — call FP_SP_SubMantissa'),
    ('LABEL_03E197', 'FP_SP_Mul_Encode',
     'SP multiply epilog: encode product via FP_SP_Encode, restore frame'),

    # -----------------------------------------------------------------------
    # 03E1A5-03E1F0: DSP voice parameter blend (copy entry + apply table blend)
    # -----------------------------------------------------------------------
    ('LABEL_03E1A5', 'DSP_VoiceBlend',
     'Copy voice entry from table 0x1F6AE, call FP_DP_FreqAdjust, blend result into output'),

    # -----------------------------------------------------------------------
    # 03E1F1-03E28E: Voice frequency register adjust (exponent + fraction recombine)
    # -----------------------------------------------------------------------
    ('LABEL_03E1F1', 'FP_DP_FreqAdjust',
     'Adjust voice frequency register: recombine exponent+fraction nibbles, apply delta step'),
    ('LABEL_03E220', 'FP_DP_FreqAdjust_NonZeroExp',
     'Non-zero exponent path: extract upper/lower nibbles, compute delta adjustment'),
    ('LABEL_03E256', 'FP_DP_FreqAdjust_DecLoop',
     'Decrement loop: reduce IZ toward zero while IZ > target'),
    ('LABEL_03E25A', 'FP_DP_FreqAdjust_DecCheck',
     'Check IZ < target: continue decrement loop or exit'),
    ('LABEL_03E263', 'FP_DP_FreqAdjust_IncLoop',
     'Increment loop: increase IZ toward zero while IZ < target'),
    ('LABEL_03E267', 'FP_DP_FreqAdjust_IncCheck',
     'Check IZ > target: continue increment loop or exit'),
    ('LABEL_03E26E', 'FP_DP_FreqAdjust_Combine',
     'Combine adjusted nibbles back into frequency word, apply sign bit'),
    ('LABEL_03E281', 'FP_DP_FreqAdjust_StoreResult',
     'Store adjusted frequency word at (XBC) and copy result to dest via FP_DP_Raw8Copy'),
    ('LABEL_03E28B', 'FP_DP_FreqAdjust_Return',
     'Epilog: pop IZ, adjust SP, return'),
    ('LABEL_03E28F', 'FP_DP_Add_Outer_Pad',
     'Padding byte (0xFF) between routines'),

    # -----------------------------------------------------------------------
    # 03E290-03E2EF: DP and SP float add (outer wrappers — decode, add, encode)
    # -----------------------------------------------------------------------
    ('LABEL_03E290', 'FP_DP_Add_Outer',
     'DP float add outer: decode XWA and (XIZ) into stack, call FP_DP_AddMantissa (via FP_DP_Mul path), encode'),
    ('LABEL_03E2C0', 'FP_SP_Add_Outer',
     'SP float add outer: decode XWA and (XIZ) into stack, call FP_SP_AddMantissa, encode'),

    # -----------------------------------------------------------------------
    # 03E2F0-03E39E: DP and SP mantissa alignment (equalize exponents)
    # -----------------------------------------------------------------------
    ('LABEL_03E2F0', 'FP_DP_AlignMantissa',
     'Align two DP mantissas: equalize exponents by right-shifting the smaller, with rounding'),
    ('LABEL_03E30D', 'FP_DP_AlignMantissa_ShiftA',
     'Shift A path: (XWA) has smaller exponent — update exponent, shift mantissa right'),
    ('LABEL_03E314', 'FP_DP_AlignMantissa_Shift',
     'Common shift path: compute shift amount, do multi-precision right shift with rounding'),
    ('LABEL_03E332', 'FP_DP_AlignMantissa_Shift16',
     'Shift by >= 16 bits: move upper word to lower, zero upper, subtract 16 from count'),
    ('LABEL_03E34A', 'FP_DP_AlignMantissa_Shift8',
     'Shift by >= 8 bits: byte-shift via SRL, load low byte of upper, subtract 8 from count'),
    ('LABEL_03E35F', 'FP_DP_AlignMantissa_ShiftBit',
     'Bit-by-bit shift loop: SRL XHL + RRC XDE for remaining count'),
    ('LABEL_03E36B', 'FP_DP_AlignMantissa_Round',
     'Round: if low byte >= 0x80, increment mantissa; store result'),
    ('LABEL_03E389', 'FP_DP_AlignMantissa_Store',
     'Store aligned/rounded mantissa into (XWA+4):(XWA+8)'),
    ('LABEL_03E390', 'FP_DP_AlignMantissa_MaxShift',
     'Exponent difference > 0x35: mantissa is negligible — zero out all three words'),
    ('LABEL_03E39F', 'FP_SP_AlignMantissa_Pad',
     'Padding byte (0xFF) between routines'),

    # -----------------------------------------------------------------------
    # 03E3A0-03E3F5: SP mantissa alignment
    # -----------------------------------------------------------------------
    ('LABEL_03E3A0', 'FP_SP_AlignMantissa',
     'Align two SP mantissas: equalize exponents by right-shifting smaller, with rounding'),
    ('LABEL_03E3B8', 'FP_SP_AlignMantissa_ShiftA',
     'Shift A path: XWA has smaller exponent — swap pointers so larger is in XBC'),
    ('LABEL_03E3BA', 'FP_SP_AlignMantissa_Shift',
     'Common shift: compute shift amount (XHL-XIX), shift XDE mantissa right, round'),
    ('LABEL_03E3D7', 'FP_SP_AlignMantissa_Shift_Odd',
     'Shift odd count: shift one extra bit if bit 4 of count set'),
    ('LABEL_03E3DB', 'FP_SP_AlignMantissa_Round',
     'Round SP mantissa: if low byte >= 0x80, increment'),
    ('LABEL_03E3E7', 'FP_SP_AlignMantissa_Store',
     'Store aligned SP mantissa into (XBC+4)'),
    ('LABEL_03E3EB', 'FP_SP_AlignMantissa_MaxShift',
     'Exponent difference > 0x18: mantissa negligible — zero (XBC+4), set NaN flag'),

    # -----------------------------------------------------------------------
    # 03E3F6-03E4B2: DP float multiply (outer wrapper with sign/exponent handling)
    # -----------------------------------------------------------------------
    ('LABEL_03E3F6', 'FP_DP_Mul_Outer',
     'Multiply two DP floats (outer): check NaN, add exponents, call FP_DP_MulMantissaCore'),
    ('LABEL_03E41F', 'FP_DP_MulMantissaCore',
     'DP mantissa multiply core: 64-bit non-restoring multiply loop with rounding'),
    ('LABEL_03E459', 'FP_DP_MulMantissaCore_Round',
     'Rounding path: if low 8 bits >= 0x80, round up mantissa'),
    ('LABEL_03E4A8', 'FP_DP_MulMantissaCore_Store',
     'Store product XIY:XIX into (XWA+8):(XWA+4)'),
    ('LABEL_03E4B3', 'FP_SP_Mul_Outer_Pad',
     'Padding byte (0xFF) between routines'),

    # -----------------------------------------------------------------------
    # 03E4B4-03E54B: SP float multiply (outer wrapper)
    # -----------------------------------------------------------------------
    ('LABEL_03E4B4', 'FP_SP_Mul_Outer',
     'Multiply two SP floats (outer): check NaN, add exponents, call FP_SP_MulMantissaCore'),
    ('LABEL_03E4EF', 'FP_SP_MulMantissaCore_Loop',
     'SP mantissa multiply loop: 4-bit non-restoring multiply for 8 iterations'),
    ('LABEL_03E4F8', 'FP_SP_MulMantissaCore_Bit2',
     'SP mantissa bit 2 test: subtract XIY, set bit 2 of L if fits'),
    ('LABEL_03E501', 'FP_SP_MulMantissaCore_Bit1',
     'SP mantissa bit 1 test: subtract XIX, set bit 1 of L if fits'),
    ('LABEL_03E50A', 'FP_SP_MulMantissaCore_Bit0',
     'SP mantissa bit 0 test: subtract XBC, set bit 0 of L if fits'),
    ('LABEL_03E513', 'FP_SP_MulMantissaCore_IterDone',
     'Iteration done: check if all 8 iterations complete, else shift and loop'),
    ('LABEL_03E51F', 'FP_SP_MulMantissaCore_Round',
     'Rounding: check overflow bit; if set shift XHL right and adjust exponent'),
    ('LABEL_03E52C', 'FP_SP_MulMantissaCore_RoundUp',
     'Round up: if L >= 0x80, add 0x100 to XHL'),
    ('LABEL_03E53F', 'FP_SP_MulMantissaCore_Shift8',
     'Shift XHL right 8 to normalize product nibble-field'),
    ('LABEL_03E542', 'FP_SP_MulMantissaCore_Store',
     'Store SP product XHL into (XWA+4), pop XIZ'),
    ('LABEL_03E547', 'FP_SP_MulMantissaCore_Divisor1',
     'Divisor == 0x800000: product = dividend, pop and store'),

    # -----------------------------------------------------------------------
    # 03E54C-03E5F5: DP and SP float subtract (mantissa level)
    # -----------------------------------------------------------------------
    ('LABEL_03E54C', 'FP_DP_SubMantissa',
     'Subtract two DP mantissas: XDE:XHL -= (XBC+4):(XBC+8), negate if borrow, normalize'),
    ('LABEL_03E57F', 'FP_DP_SubMantissa_NoBorrow',
     'No borrow: check if result is zero'),
    ('LABEL_03E585', 'FP_DP_SubMantissa_Normalize',
     'Normalize subtraction result: find highest set bit via BS1B, shift mantissa'),
    ('LABEL_03E590', 'FP_DP_SubMantissa_NormLoop',
     'Normalization loop: shift mantissa up until leading bit found'),
    ('LABEL_03E5A6', 'FP_DP_SubMantissa_Shift',
     'Apply computed shift: >= 4 bits → shift sub-steps of 8 or 1 bit'),
    ('LABEL_03E5C2', 'FP_DP_SubMantissa_ShiftBit',
     'Bit-by-bit right shift loop for remaining count'),
    ('LABEL_03E5D0', 'FP_DP_SubMantissa_ShiftLeft',
     'Left-shift path: result needs to grow, shift up and decrement exponent'),
    ('LABEL_03E5E2', 'FP_DP_SubMantissa_StoreExp',
     'Restore IY (sign) and store updated exponent'),
    ('LABEL_03E5E7', 'FP_DP_SubMantissa_Store',
     'Store subtraction result XDE:XHL into (XWA+4):(XWA+8) with sign'),
    ('LABEL_03E5F1', 'FP_DP_SubMantissa_Zero',
     'Result is exactly zero: set zero flag at (XWA+2)'),

    # -----------------------------------------------------------------------
    # 03E5F6-03E64A: SP float subtract (mantissa level)
    # -----------------------------------------------------------------------
    ('LABEL_03E5F6', 'FP_SP_SubMantissa',
     'Subtract two SP mantissas: XIX = (XWA+4) - (XBC+4), handle borrow, normalize'),
    ('LABEL_03E61B', 'FP_SP_SubMantissa_Normalize',
     'Normalize SP subtraction: left-shift XIX until leading byte non-zero, track exponent'),
    ('LABEL_03E627', 'FP_SP_SubMantissa_AlignBits',
     'Align remaining bits: BS1B to find top bit position, shift XIX left accordingly'),
    ('LABEL_03E638', 'FP_SP_SubMantissa_Store',
     'Store normalized XIX into (XIY+4) and update exponent and sign'),
    ('LABEL_03E642', 'FP_SP_SubMantissa_Zero',
     'SP subtraction result is zero: store 0 and set NaN flag'),

    # -----------------------------------------------------------------------
    # 03E64B-03E72B: Voice pitch slide iteration engine
    # -----------------------------------------------------------------------
    ('LABEL_03E64B', 'VoicePitch_SlideEngine',
     'Voice pitch slide: compare sign of step, iterate convergence up to 0x12C steps'),
    ('LABEL_03E675', 'VoicePitch_SlideEngine_NonZero',
     'Slide non-zero path: copy alternate preset table and compare against range 0x1F6CE'),
    ('LABEL_03E6A9', 'VoicePitch_SlideEngine_LessPath',
     'Slide less-than path: compare against range 0x1F6CE variant 2'),
    ('LABEL_03E6C9', 'VoicePitch_SlideEngine_StartIter',
     'Initialize iteration counter IZ=1, begin slide loop'),
    ('LABEL_03E6CB', 'VoicePitch_SlideEngine_IterLoop',
     'Slide iteration loop: copy, scale step, blend via VoiceFloat_SubDP, compare convergence'),
    ('LABEL_03E722', 'VoicePitch_SlideEngine_Done',
     'Slide done: copy final result to output via FP_DP_Raw8Copy'),
    ('LABEL_03E72C', 'VoicePitch_SlideEngine_Epilog',
     'Slide engine epilog: pop IZ, restore stack frame, return'),

    # -----------------------------------------------------------------------
    # 03E731-03E87D: Voice amplitude convergence engine (bisection search)
    # -----------------------------------------------------------------------
    ('LABEL_03E731', 'VoiceAmp_ConvergeEngine',
     'Voice amplitude convergence: bisection search for target, up to N steps; set 0x040C22'),
    ('LABEL_03E758', 'VoiceAmp_ConvergeEngine_InRange',
     'Convergence in-range path: setup initial midpoint, begin bisection iterations'),
    ('LABEL_03E7E6', 'VoiceAmp_ConvergeEngine_IterLoop',
     'Bisection iteration loop: blend midpoint, compare against target, refine step'),
    ('LABEL_03E87E', 'VoiceAmp_ConvergeEngine_Epilog',
     'Convergence engine epilog: pop XIZ, restore stack frame, return'),

    # -----------------------------------------------------------------------
    # 03E883-03E88D: Padding / float NaN/error handler
    # -----------------------------------------------------------------------
    ('LABEL_03E883', 'FP_NaN_Handler_Pad',
     'Padding byte (0xFF) between routines'),
    ('LABEL_03E884', 'FP_NaN_Handler',
     'Float NaN/error handler: if (XBC+2) bit 0 set, write 0x08 (infinity) to (XWA+2)'),

    # -----------------------------------------------------------------------
    # 03E894-03E9FB: DSP voice register update (load preset, blend pitch)
    # -----------------------------------------------------------------------
    ('LABEL_03E894', 'DSP_VoiceRegUpdate',
     'DSP voice register update: load preset from 0x1F706, blend pitch exponent+fraction'),
    ('LABEL_03E8C7', 'DSP_VoiceRegUpdate_ZeroOrMax',
     'Voice register: exponent is 0 or 0x7FF — copy constant table 0x1F70E, return'),
    ('LABEL_03E8D6', 'DSP_VoiceRegUpdate_InRange',
     'Voice register in-range: compute normalized exponent offset, blend nibbles'),
    ('LABEL_03E920', 'DSP_VoiceRegUpdate_NegOffset',
     'Voice register negative offset: copy constant table 0x1F716, return'),
    ('LABEL_03E933', 'DSP_VoiceRegUpdate_LargeOffset',
     'Voice register large offset (>= 0x34): copy source table directly, return'),
    ('LABEL_03E946', 'DSP_VoiceRegUpdate_BlendLoop',
     'Voice register blend loop: walk backwards through nibble pairs, merge into output'),
    ('LABEL_03E96A', 'DSP_VoiceRegUpdate_ForwardScan',
     'Forward nibble scan: swap high/low nibbles of each byte, advance pointer'),
    ('LABEL_03E98E', 'DSP_VoiceRegUpdate_FillPad',
     'Fill padding bytes 0x00 at unfilled positions'),
    ('LABEL_03E99A', 'DSP_VoiceRegUpdate_BackScan',
     'Reverse nibble scan: walk backwards, merge nibbles into output register'),
    ('LABEL_03E9B6', 'DSP_VoiceRegUpdate_MaskLow',
     'Mask low nibble: (wa & 0xF) != 0 → shift mask left by wa bits'),
    ('LABEL_03E9BA', 'DSP_VoiceRegUpdate_ZeroLow',
     'Zero low nibble: store 0x00 at (XDE)'),
    ('LABEL_03E9BD', 'DSP_VoiceRegUpdate_BackScan2',
     'Second reverse scan: walk backwards through high nibbles, fill output'),
    ('LABEL_03E9C7', 'DSP_VoiceRegUpdate_BackScanLoop',
     'Back scan loop: swap nibbles and accumulate into XBC pointer'),
    ('LABEL_03E9FC', 'DSP_VoiceRegUpdate_Return',
     'Return: pop XIZ, restore stack, return'),

    # -----------------------------------------------------------------------
    # 03EA01-03EA32: Float copy variants (1-word and 3-word)
    # -----------------------------------------------------------------------
    ('LABEL_03EA01', 'FP_CopyVariant_Pad',
     'Padding byte (0xFF) between routines'),
    ('LABEL_03EA02', 'FP_DP_CopyNoSign',
     'DP float copy variant: D=0, copy 2 words (8 bytes) without sign flip'),
    ('LABEL_03EA06', 'FP_DP_CopyWithSign',
     'DP float copy variant: D=1, copy 2 words (8 bytes) with sign'),
    ('LABEL_03EA0E', 'FP_DP_CopyDispatch',
     'DP float copy dispatch: if D==0 copy 2 words, else copy 3 words (12 bytes)'),
    ('LABEL_03EA22', 'FP_DP_Copy3Words',
     'Copy 3 x 4-byte words (XBC → XWA): XWA[0..11] = XBC[0..11]'),
    ('LABEL_03EA33', 'FP_SP_DecodeToInt_Pad',
     'Padding byte (0xFF) between routines'),

    # -----------------------------------------------------------------------
    # 03EA34-03EA9B: SP float decode → integer (shift by exponent, return in XHL)
    # -----------------------------------------------------------------------
    ('LABEL_03EA34', 'FP_SP_DecodeToInt',
     'Decode SP float at (XWA) to integer XHL by exponent-based bit shift; set error at 0x040C22 on overflow'),
    ('LABEL_03EA56', 'FP_SP_DecodeToInt_ShiftLeft',
     'Left-shift loop: SLL IX + RLC XIY by one bit per count'),
    ('LABEL_03EA65', 'FP_SP_DecodeToInt_ShiftRight',
     'Right-shift path: exponent < 0x14, right-shift XIY by (0x14 - exp) bits'),
    ('LABEL_03EA78', 'FP_SP_DecodeToInt_ShiftRightLoop',
     'Right-shift loop: SRLA XIY one bit at a time'),
    ('LABEL_03EA7A', 'FP_SP_DecodeToInt_SignCorrect',
     'Apply sign correction to decoded SP integer result'),
    ('LABEL_03EA86', 'FP_SP_DecodeToInt_Return',
     'Return decoded SP integer in XHL (sign-corrected)'),
    ('LABEL_03EA89', 'FP_SP_DecodeToInt_Underflow',
     'Exponent underflow: return XHL = 0'),
    ('LABEL_03EA8D', 'FP_SP_DecodeToInt_Overflow',
     'Exponent overflow: return XHL = 0xFFFFFFFF'),
    ('LABEL_03EA91', 'FP_SP_DecodeToInt_SetError',
     'Set error flag at 0x040C22 = 0x0022'),
    ('LABEL_03EA99', 'FP_SP_DecodeToInt_NaN',
     'NaN/special-flag set: return XHL = 0'),

    # -----------------------------------------------------------------------
    # 03EA9C-03EBC7: Voice frequency envelope step engine
    # -----------------------------------------------------------------------
    ('LABEL_03EA9C', 'VoiceFreq_EnvelopeStep',
     'Voice frequency envelope step: compare to 5 (zero check), dispatch to pitch-step or clamp'),
    ('LABEL_03EAC8', 'VoiceFreq_EnvelopeStep_InRange',
     'Envelope in-range: load exponent BC from voice register, check vs 0x7FF'),
    ('LABEL_03EAF0', 'VoiceFreq_EnvelopeStep_ClampHigh',
     'Clamp high: exponent > 0x7FF — negate or copy to output based on sign bit'),
    ('LABEL_03EAF9', 'VoiceFreq_EnvelopeStep_ClampLow',
     'Clamp low: exponent < 0xF801 — copy zero-table 0x1F726, return'),
    ('LABEL_03EB0D', 'VoiceFreq_EnvelopeStep_NibbleAdjust',
     'Nibble adjust: compute new exponent IX = IY + BC delta, iterate to target'),
    ('LABEL_03EB40', 'VoiceFreq_EnvelopeStep_IncLoop',
     'Increment loop: increment IY toward target; clamp if > 0x7FF'),
    ('LABEL_03EB65', 'VoiceFreq_EnvelopeStep_IncClamp_Copy',
     'Increment clamped: sign=0 — copy constant table, return'),
    ('LABEL_03EB6D', 'VoiceFreq_EnvelopeStep_IncStep',
     'Increment one step: IY++, IZ++, compare to BC, continue'),
    ('LABEL_03EB77', 'VoiceFreq_EnvelopeStep_DecCheck',
     'Decrement check: BC <= 0, check if we need to go negative'),
    ('LABEL_03EB7B', 'VoiceFreq_EnvelopeStep_DecLoop',
     'Decrement loop: decrement IY toward target; clamp if == 1'),
    ('LABEL_03EB97', 'VoiceFreq_EnvelopeStep_DecStep',
     'Decrement one step: IY--, IZ--, compare to BC, continue'),
    ('LABEL_03EB9F', 'VoiceFreq_EnvelopeStep_StoreResult',
     'Store final IY (new frequency nibbles), combine with mantissa low nibble, write to XWA[6]'),
    ('LABEL_03EBB8', 'VoiceFreq_EnvelopeStep_SetHighBit',
     'Set high bit 15 of output word if source bit 7 was set'),
    ('LABEL_03EBC8', 'VoiceFreq_EnvelopeStep_Epilog',
     'Epilog: pop IZ, restore stack frame, return'),
    ('LABEL_03EBCD', 'FP_DP_MulAdd_Pad',
     'Padding byte (0xFF) between routines'),

    # -----------------------------------------------------------------------
    # 03EBCE-03EC9D: DP float multiply with exponent-add (128-bit intermediate)
    # -----------------------------------------------------------------------
    ('LABEL_03EBCE', 'FP_DP_MulAdd',
     'DP float multiply with exponent-add: 128-bit intermediate mantissa product, two-level sum'),
    ('LABEL_03EC1E', 'FP_DP_MulAdd_Sum1',
     'Accumulate first cross-product: (XWA+8)*(XBC+4) → add to running sum, propagate carry'),
    ('LABEL_03EC35', 'FP_DP_MulAdd_Sum2',
     'Accumulate second cross-product: (XWA+4)*(XBC+8) → add to running sum, propagate carry'),
    ('LABEL_03EC56', 'FP_DP_MulAdd_Round',
     'Round 128-bit product: combine byte offsets, check rounding bit, normalize'),
    ('LABEL_03EC93', 'FP_DP_MulAdd_Store',
     'Store DP multiply result XDE:XHL into (XWA+4):(XWA+8)'),

    # -----------------------------------------------------------------------
    # 03EC9E-03ED0D: SP float multiply with exponent-add
    # -----------------------------------------------------------------------
    ('LABEL_03EC9E', 'FP_SP_MulAdd',
     'SP float multiply with exponent-add: 32-bit mantissa product, multi-precision'),
    ('LABEL_03ECE6', 'FP_SP_MulAdd_NormCheck',
     'SP MulAdd normalization check: if high bit of XDE set, shift right and add exponent'),
    ('LABEL_03ECF0', 'FP_SP_MulAdd_Round',
     'Round SP product: if low byte >= 0x80, add 0x100, propagate carry'),
    ('LABEL_03ED06', 'FP_SP_MulAdd_Store',
     'Store SP multiply result (high bytes of XDE) into (XIZ+4)'),

    # -----------------------------------------------------------------------
    # 03ED0E: 64x64 mantissa multiply helper (used by FP_DP_MulAdd)
    # -----------------------------------------------------------------------
    ('LABEL_03ED0E', 'FP_MulMantissa64x64',
     '64x64-bit mantissa multiply: XDE += XHL*XIY + IX*XIZ + correction; returns carry in XDE'),

    # -----------------------------------------------------------------------
    # 03ED3C-03EE2C: Non-restoring division core (4-bit-per-iteration)
    # -----------------------------------------------------------------------
    ('LABEL_03ED3C', 'FP_Div_Step4Bits',
     'Non-restoring FP division: generate 4 quotient bits (bit 3,2,1,0) via subtract-shift'),
    ('LABEL_03ED64', 'FP_Div_Step_Bit3',
     'Division bit 3: check divisor high byte, subtract if fits, set bit 3 of XIZ'),
    ('LABEL_03ED75', 'FP_Div_Step_Bit3_Set',
     'Division bit 3 set: remainder fits, set bit 3 of XIZ quotient accumulator'),
    ('LABEL_03ED78', 'FP_Div_Step_Bit2_Entry',
     'Division bit 2 entry: shift left 1 bit, load next dividend chunk'),
    ('LABEL_03EDA0', 'FP_Div_Step_Bit2',
     'Division bit 2: check divisor, subtract if fits, set bit 2 of XIZ'),
    ('LABEL_03EDB1', 'FP_Div_Step_Bit2_Set',
     'Division bit 2 set'),
    ('LABEL_03EDB4', 'FP_Div_Step_Bit1_Entry',
     'Division bit 1 entry: shift left 1 bit, load next dividend chunk'),
    ('LABEL_03EDDC', 'FP_Div_Step_Bit1',
     'Division bit 1: check divisor, subtract if fits, set bit 1 of XIZ'),
    ('LABEL_03EDED', 'FP_Div_Step_Bit1_Set',
     'Division bit 1 set'),
    ('LABEL_03EDF0', 'FP_Div_Step_Bit0_Entry',
     'Division bit 0 entry: shift left 1 bit, load next dividend chunk'),
    ('LABEL_03EE18', 'FP_Div_Step_Bit0',
     'Division bit 0: check divisor, subtract if fits, set bit 0 of XIZ'),
    ('LABEL_03EE29', 'FP_Div_Step_Bit0_Set',
     'Division bit 0 set'),
    ('LABEL_03EE2C', 'FP_Div_Step_Continue',
     'Division step done: decrement C; if more bits remain, shift XIZ and loop'),

    # -----------------------------------------------------------------------
    # 03EE36-03EE6E: Float negate (sign flip) dispatch and variants
    # -----------------------------------------------------------------------
    ('LABEL_03EE36', 'FP_DP_NegNoSign',
     'DP float negate dispatch: D=0, copy 2 words and flip sign bit at (XWA+3)'),
    ('LABEL_03EE3A', 'FP_DP_NegWithSign',
     'DP float negate dispatch: D=1, copy 2 words and flip sign bit at (XWA+3)'),
    ('LABEL_03EE42', 'FP_DP_NegDispatch',
     'DP float negate: if D==0 copy 2 words, else copy 3 words; flip sign bit (XOR 0x80)'),
    ('LABEL_03EE5A', 'FP_DP_Neg3Words',
     'DP negate 3-word variant: copy all 3 words then XOR sign byte at (XWA+3) with 0x80'),
    ('LABEL_03EE6F', 'FP_Overflow_Handler_Pad',
     'Padding byte (0xFF) between routines'),

    # -----------------------------------------------------------------------
    # 03EE70-03EE74: Float overflow/NaN handler (shared error return)
    # -----------------------------------------------------------------------
    ('LABEL_03EE70', 'FP_Overflow_Handler',
     'Float overflow/NaN handler: set NaN flag at (XWA+2) = 1, return'),

    # -----------------------------------------------------------------------
    # 03EE75: Padding/alignment fill at end of FP library
    # -----------------------------------------------------------------------
    ('LABEL_03EE75', 'FP_Library_End_Pad',
     'End-of-library alignment fill: 139 bytes of 0xFF padding after FP routines'),

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

    # Check maincpu for cross-references (none expected per grep, but check anyway)
    maincpu_src = os.path.join(base, 'maincpu', 'kn5000_v10_program.s')
    with open(maincpu_src, 'rb') as f:
        maincpu_content = f.read().decode('latin-1')

    maincpu_renames = 0
    for old_label, new_label, _ in RENAMES:
        if old_label in maincpu_content:
            maincpu_content = re.sub(r'\b' + re.escape(old_label) + r'\b', new_label, maincpu_content)
            maincpu_renames += 1

    with open(src, 'wb') as f:
        f.write(content.encode('latin-1'))

    if maincpu_renames > 0:
        with open(maincpu_src, 'wb') as f:
            f.write(maincpu_content.encode('latin-1'))
        print(f'  ({maincpu_renames} cross-references also renamed in maincpu)')

    print(f'\nRenamed {renamed} labels in subcpu ({maincpu_renames} cross-refs in maincpu)')


if __name__ == '__main__':
    main()
