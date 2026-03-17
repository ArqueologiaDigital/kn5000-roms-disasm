#!/usr/bin/env python3
"""Rename LABEL_* to semantic names for SubCPU DSP parameter engine (038-03C range).

Based on analysis of the 0x038000-0x03CFFF address range in the SubCPU firmware.
This range covers DSP chip control, parameter encoding/scaling, filter coefficient
computation, floating-point curve approximation, and the DSP bytecode interpreter
dispatch tables.

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
#   038044-0381B8  EFF config load routines (with debug serial output)
#   0382EA-03835F  EFF volume update (zeroing stale param before reload)
#   038528-038533  DSP_WriteFreqParam_AlgoType fallback + return
#   0385F5-038600  DSP_WriteFreqParam fallback + return
#   0386D6-0387D5  DSP_WriteLUTParamSet table-base selectors + loop
#   0388A2-0388AD  DSP_WriteOscParam fallback + return
#   038A95-038CB5  DSP algo-select param write (two unlabeled routines)
#   038CF6-038CF9  DSP tune-offset increment/decrement
#   038E0F         Opaque inline data block
#   038E4C-038E9F  DSP state apply/load helpers
#   038ED7-038EF1  DSP_ParamFetch_AlgoTypeTable case arms
#   038F50-038F86  DSP_AlgoParam_Decode alternative path + return
#   039021-0391FD  DSP_VolumeParam_Scale piecewise segments (algo 0, 1, 2)
#   039206         DSP param interpolation (2-point with progress)
#   03925E         DSP param interpolation (with 0xAC44 scale factor)
#   0392AC         DSP param interpolation (with 0xB4 divisor)
#   0392F2-03941B  DSP volume curve (FP polynomial, two ranges)
#   03943B-0394CD  DSP frequency response curve (piecewise FP)
#   039525         DSP param interpolation (3-point with offset)
#   039599-0396C2  DSP reverb curve (FP polynomial, two ranges)
#   0396C2         DSP param interpolation (FP multi-step with sub/add)
#   0397F3-0398CD  DSP pan curve (piecewise linear, 5 segments)
#   0398CE-039A3A  DSP detune curve (signed FP, 4 magnitude ranges)
#   039ABD-039B1A  DSP biquad frequency warp (FP with two comparison tables)
#   039D26         DSP param interpolation (with 0xC6 divisor, progress)
#   039D98-03A204  DSP parametric EQ curve (FP multi-segment, 5 ranges)
#   03A22A         DSP param interpolation (identical to 039206)
#   03A282-03A497  DSP_VolumeParam_Scale variant B (same piecewise structure)
#   03A4A0         DSP simple pan scale (MulAccum + div 0x3E8)
#   03A4B7-03A5EF  DSP multi-step param interpolation (3 orderings)
#   03A620-03A909  DSP filter LUT fetch with FP scalar-to-DP conversion
#   03A933         DSP full biquad filter coefficient computation (algo 0 entry)
#   03AA65-03AB2F  Biquad coeff sign handling (CmpZero + CopyOrNegate)
#   03AC3E-03ACB1  Biquad algo 0 coefficient assembly (negative-coeff branch)
#   03AD1E         Biquad normalization fixup (1.0 substitution)
#   03AE72         Biquad algo 1 entry
#   03B08A         Biquad algo 2 entry
#   03B1D9-03B29B  Biquad algo 2 sign handling stages
#   03B3A6-03B419  Biquad algo 2 coefficient assembly branches
#   03B4F0         Biquad common epilogue (store state, return)
#   03B505         DSP second-order section LUT fetch (simpler variant)
#   03B596-03B646  Second-order LUT fetch case arms + SOS entry
#   03B7F4-03B901  SOS algo 0 zero-coeff branch and positive-coeff branch
#   03B9DD-03BC44  SOS algo 1 computation
#   03BB3F         SOS algo 1 nonzero-coeff branch
#   03BD18-03BF7D  SOS algo 2 computation
#   03BE78         SOS algo 2 nonzero-coeff branch
#   03C04F-03C067  SOS common epilogue + DSP mixer coefficient compute
#   03C1A3-03C24F  DSP_WriteParameter special-case handlers
#   03CA30-03CAA7  DSP bytecode param loop control flow
#   03CB18-03CBCC  DSP_PerParameterTranslator main loop + return
#   03CE9F-03CEFF  DSP param opcode dispatch targets (0x40, 0x24, 0x21)
#   03CF07         Stream decoder: read 3 signed bytes -> 24-bit word
#   03CF53-03CF9D  Table walker: search keyed entry in packed table
#   03CFA5-03CFE6  Table walker variant: search with state update
#   03CFED         Nop return (single ret instruction)
# ---------------------------------------------------------------------------

RENAMES = [
    # ------------------------------------------------------------------
    # 038044-0381B8  EFF config load + debug
    # Context: after EFF_WriteHeader, loads multiple DSP config blocks
    # via 0x3C181 (DSP_BytecodeRun), with serial debug output.
    # ------------------------------------------------------------------
    ('LABEL_038044', 'EFF_LoadConfigs_ForChannel',
     'Load DSP configs for channel IZ=1: multiple 0x3C181 calls with ROM block ptrs'),

    ('LABEL_0380EA', 'EFF_WriteHeader_Return',
     'Return from EFF_WriteHeader (skip zero-EFF case)'),

    ('LABEL_038142', 'EFF_Change_Case0xA',
     'EFF_Change effect=0xA: load two config blocks via 0x3C161'),

    ('LABEL_03815A', 'EFF_Change_GenericLookup',
     'EFF_Change generic: look up config ptrs from 0x1ED7C/0x1EF0C tables by effect index'),

    ('LABEL_03818A', 'EFF_Change_ChannelNot1',
     'EFF_Change for channel != 1: same table lookup as generic'),

    ('LABEL_0381B8', 'EFF_Change_Return',
     'Return from EFF_Change_WithDebug'),

    # ------------------------------------------------------------------
    # 0382EA-03835F  EFF volume update: zero stale param before reload
    # Context: inside EFF_VolumeUpdate_WithDebug. If voice struct +54
    # is non-zero, calls 0x3C190 directly; if zero, saves old param,
    # zeroes it, calls 0x3C190, then restores the saved value.
    # ------------------------------------------------------------------
    ('LABEL_0382EA', 'EFF_VolumeUpdate_ZeroAndReload',
     'Voice +54 is zero: save param, zero it, run bytecode, restore param'),

    ('LABEL_03835F', 'EFF_VolumeUpdate_Return',
     'Return from EFF_VolumeUpdate_WithDebug'),

    # ------------------------------------------------------------------
    # 038528-038533  DSP_WriteFreqParam_AlgoType internal labels
    # ------------------------------------------------------------------
    ('LABEL_038528', 'DSP_WriteFreqParam_AlgoType_UseCmd30',
     'Algo type == 1: use DSP_WriteParamCmd30 fallback instead of inline encoding'),

    ('LABEL_038533', 'DSP_WriteFreqParam_AlgoType_Return',
     'Return from DSP_WriteFreqParam_AlgoType'),

    # ------------------------------------------------------------------
    # 0385F5-038600  DSP_WriteFreqParam internal labels
    # ------------------------------------------------------------------
    ('LABEL_0385F5', 'DSP_WriteFreqParam_UseCmd30',
     'Algo type == 1: use DSP_WriteParamCmd30 fallback for freq param'),

    ('LABEL_038600', 'DSP_WriteFreqParam_Return',
     'Return from DSP_WriteFreqParam'),

    # ------------------------------------------------------------------
    # 0386D6-0387D5  DSP_WriteLUTParamSet table base selectors + main loop
    # Context: selects one of six ROM lookup tables based on (C, XDE)
    # pair, then iterates through entries calling DSP_UnpackParam3B
    # and the WriteFreqParam/WriteCoeffData_5B writers.
    # ------------------------------------------------------------------
    ('LABEL_0386D6', 'DSP_WriteLUT_AlgoC0_TypeDE1',
     'C != 1, DE == 1: use table base 0x01EB67'),

    ('LABEL_0386E0', 'DSP_WriteLUT_AlgoC0_TypeDE2',
     'C != 1, DE == 2: use table base 0x01EBD4'),

    ('LABEL_0386EA', 'DSP_WriteLUT_AlgoC1',
     'C == 1: select from second set of LUT tables (0x20 stride)'),

    ('LABEL_038709', 'DSP_WriteLUT_AlgoC1_TypeDE1',
     'C == 1, DE == 1: use table base 0x01ECA5'),

    ('LABEL_038713', 'DSP_WriteLUT_AlgoC1_TypeDE2',
     'C == 1, DE == 2: use table base 0x01ED09'),

    ('LABEL_03871B', 'DSP_WriteLUT_MainLoop_Init',
     'Load first table byte as entry count, init loop counter to 0'),

    ('LABEL_03873B', 'DSP_WriteLUT_MainLoop_Body',
     'Per-entry: send command header if not first, unpack 4 params, write freq + 3 coeffs'),

    ('LABEL_038764', 'DSP_WriteLUT_MainLoop_FirstEntry',
     'First entry (skip command header): jump straight to param unpack'),

    ('LABEL_0387D5', 'DSP_WriteLUT_MainLoop_Done',
     'Store updated table pointer and return from DSP_WriteLUTParamSet'),

    # ------------------------------------------------------------------
    # 0388A2-0388AD  DSP_WriteOscParam internal labels
    # ------------------------------------------------------------------
    ('LABEL_0388A2', 'DSP_WriteOscParam_UseCmd30',
     'Algo type == 1: use DSP_WriteParamCmd30 fallback for osc param'),

    ('LABEL_0388AD', 'DSP_WriteOscParam_Return',
     'Return from DSP_WriteOscParam'),

    # ------------------------------------------------------------------
    # 038A95-038B64  Two unlabeled DSP algo-select routines
    # These write DSP algorithm-selection parameters with different
    # command sequences depending on a channel-type field.
    # The first (at ~038A00) handles type==0x63 specially; the second
    # (~038B00 area) handles osc parameters.
    # ------------------------------------------------------------------
    ('LABEL_038A95', 'DSP_AlgoSelect_TypeEq63',
     'Channel type == 0x63: write 0x20 addr byte (special config) + zeroes'),

    ('LABEL_038ACD', 'DSP_AlgoSelect_WriteHeader',
     'After addr/data preamble: write channel-type-dependent header bytes'),

    ('LABEL_038B10', 'DSP_AlgoSelect_WriteHeaderNonZero',
     'Channel non-zero: extract bit fields from param and write 5 bytes'),

    ('LABEL_038B64', 'DSP_AlgoSelect_Return',
     'Return from first DSP algo-select routine'),

    # ------------------------------------------------------------------
    # 038C60-038CB5  Second DSP algo-select routine (osc variant)
    # ------------------------------------------------------------------
    ('LABEL_038C60', 'DSP_OscAlgoSelect_WriteHeaderNonZero',
     'Osc channel non-zero: extract bit fields and write 5 header bytes'),

    ('LABEL_038CB5', 'DSP_OscAlgoSelect_Return',
     'Return from second DSP algo-select (osc) routine'),

    # ------------------------------------------------------------------
    # 038CF6-038CF9  DSP tune-offset adjuster inside a third unlabeled routine
    # ------------------------------------------------------------------
    ('LABEL_038CF6', 'DSP_TuneOffset_Increment',
     'Tune param == 1: increment tune offset by 1'),

    ('LABEL_038CF9', 'DSP_TuneOffset_WriteSequence',
     'Write DSP tune command sequence: header + addr nibbles + freq data + coeff end'),

    # ------------------------------------------------------------------
    # 038E0F  Opaque inline data block (between DSP_State_DmaLoadPresets
    # and DSP_State_ApplyBuf). Not code — do not rename as a routine.
    # ------------------------------------------------------------------
    ('LABEL_038E0F', 'DSP_State_InlineData',
     'Inline data block between DSP_State_DmaLoadPresets and DSP_State_ApplyBuf'),

    # ------------------------------------------------------------------
    # 038E4C-038E9F  DSP state apply/load helpers
    # ------------------------------------------------------------------
    ('LABEL_038E4C', 'DSP_State_ApplyBuf_DoCopy',
     'Copy 0x91 words from XIZ to buffer, tag with E1 header, call LABEL_0204D1'),

    ('LABEL_038E9F', 'DSP_State_LoadAndApply_InlineData',
     'Inline data block after DSP_State_LoadAndApplyAll'),

    # ------------------------------------------------------------------
    # 038ED7-038EF1  DSP_ParamFetch_AlgoTypeTable internal labels
    # ------------------------------------------------------------------
    ('LABEL_038ED7', 'DSP_ParamFetch_AlgoType1',
     'Algo type == 1: fetch from table at 0x12613'),

    ('LABEL_038EE5', 'DSP_ParamFetch_AlgoType2',
     'Algo type == 2: fetch from table at 0x127A3'),

    ('LABEL_038EF1', 'DSP_ParamFetch_AlgoTypeReturn',
     'Increment state pointer and return XHL from DSP_ParamFetch_AlgoTypeTable'),

    # ------------------------------------------------------------------
    # 038F50-038F86  DSP_AlgoParam_Decode internal labels
    # ------------------------------------------------------------------
    ('LABEL_038F50', 'DSP_AlgoParam_Decode_Type1',
     'Algo type == 1: use 0x127A3 table (via XIZ), different ROM constant set'),

    ('LABEL_038F86', 'DSP_AlgoParam_Decode_Return',
     'Advance state pointer and return decoded XHL from DSP_AlgoParam_Decode'),

    # ------------------------------------------------------------------
    # 039021-0391FD  DSP_VolumeParam_Scale piecewise segments
    # The volume curve is split into segments by input value thresholds.
    # Algo 0: 4 segments (<=0x32, <=0x4B, <=0x58, >0x58) using 0x6BAA8/0x35D54 divisors
    # Algo 1: 4 segments (<=0xA, <=0x13, <=0x40, <=0x57, >0x57) using 0xAC44 divisor
    # Algo 2: 4 segments (<=0x32, <=0x4B, <=0x58, >0x58) with dynamic divisor
    # ------------------------------------------------------------------
    ('LABEL_039021', 'DSP_VolScale_Algo0_Seg2',
     'Algo 0 segment 2: value in (0x32, 0x4B], sub 0x19, div by 0x35D54'),

    ('LABEL_039043', 'DSP_VolScale_Algo0_Seg3',
     'Algo 0 segment 3: value in (0x4B, 0x58], mul*4 - 0xFA, div by 0x35D54'),

    ('LABEL_039068', 'DSP_VolScale_Algo0_Seg4',
     'Algo 0 segment 4: value > 0x58, mul*9 - 0x2B2, div by 0x35D54'),

    ('LABEL_039087', 'DSP_VolScale_Algo1_Seg1',
     'Algo 1 segment 1: value <= 0xA, div by 0xAC44'),

    ('LABEL_0390A3', 'DSP_VolScale_Algo1_Seg2',
     'Algo 1 segment 2: value in (0xA, 0x13], mul*10 - 0x5A, div by 0xAC44'),

    ('LABEL_0390CC', 'DSP_VolScale_Algo1_Seg3',
     'Algo 1 segment 3: value in (0x13, 0x40], mul*20 - 0x118, SLA 15, div by 0xAC44'),

    ('LABEL_0390F6', 'DSP_VolScale_Algo1_Seg4',
     'Algo 1 segment 4: value in (0x40, 0x57], MulAccum*0x190 - 0x60E0, SLA 15, div'),

    ('LABEL_039123', 'DSP_VolScale_Algo1_Seg5',
     'Algo 1 segment 5: value > 0x57, MulAccum*0x320 - 0xE8D0, SLA 15, div'),

    ('LABEL_039148', 'DSP_VolScale_Algo2_Seg1',
     'Algo 2 segment 1: value <= 0x32, dynamic divisor = 0xFA0 - 2*value'),

    ('LABEL_03916C', 'DSP_VolScale_Algo2_Seg2',
     'Algo 2 segment 2: value in (0x32, 0x4B], dynamic divisor = 0x79C - 2*(v-0x33)'),

    ('LABEL_03919B', 'DSP_VolScale_Algo2_Seg3',
     'Algo 2 segment 3: value in (0x4B, 0x58], dynamic divisor = 0x764 - 8*v + 0x260'),

    ('LABEL_0391CE', 'DSP_VolScale_Algo2_Seg4',
     'Algo 2 segment 4: value > 0x58, dynamic divisor = 0x6F2 - 18*v + 0x642'),

    ('LABEL_0391FD', 'DSP_VolScale_Return',
     'Store state pointer and return from DSP_VolumeParam_Scale'),

    # ------------------------------------------------------------------
    # 039206  DSP param linear interpolation (2-point with progress fraction)
    # Reads two target values via LABEL_03CF07 stream decoder, computes
    # (target2 - target1) * progress / 0x63 + target1.
    # ------------------------------------------------------------------
    ('LABEL_039206', 'DSP_ParamInterp_2Point',
     'Interpolate between two stream values: (v2-v1)*progress/0x63 + v1, return in XHL'),

    # ------------------------------------------------------------------
    # 03925E  DSP param interpolation with 0xAC44 FP scale factor
    # Similar to 039206 but applies a FP multiply by 0xAC44/0x3E8
    # instead of simple linear interp.
    # ------------------------------------------------------------------
    ('LABEL_03925E', 'DSP_ParamInterp_FPScale',
     'Interpolate with FP scale: MulAccum*0xAC44, div by 0x3E8, add base'),

    # ------------------------------------------------------------------
    # 0392AC  DSP param interpolation with 0xB4 divisor
    # ------------------------------------------------------------------
    ('LABEL_0392AC', 'DSP_ParamInterp_Div0xB4',
     'Interpolate with divisor 0xB4: read stream, MulAccum, div by 0xB4, return XHL'),

    # ------------------------------------------------------------------
    # 0392F2-03941B  DSP volume-to-FP conversion curve (polynomial approx)
    # Two branches: value <= 0x4B (5-term polynomial), value > 0x4B
    # (4-term polynomial). Uses FP_SP_* and VoiceFloat_* operations.
    # ------------------------------------------------------------------
    ('LABEL_0392F2', 'DSP_VolumeCurve_FP',
     'Convert volume value to FP coefficient: two-branch polynomial approximation'),

    ('LABEL_039391', 'DSP_VolumeCurve_FP_HighRange',
     'Volume > 0x4B: use 4-term FP polynomial with different ROM constants'),

    ('LABEL_03941B', 'DSP_VolumeCurve_FP_Finalize',
     'Add final FP offset, decode sign, return result in XHL'),

    # ------------------------------------------------------------------
    # 03943B-0394CD  DSP frequency response curve (piecewise FP)
    # 3 segments: <=0x14, <=0x32, >0x32. Uses dynamic divisor for
    # segments 1-2 and MulAccum for segment 3.
    # ------------------------------------------------------------------
    ('LABEL_03943B', 'DSP_FreqCurve_FP',
     'Piecewise frequency curve: 3 segments with FP division'),

    ('LABEL_039461', 'DSP_FreqCurve_FP_Seg2',
     'Freq segment 2: value in (0x14, 0x32], sub 0xA, dynamic divisor'),

    ('LABEL_03948E', 'DSP_FreqCurve_FP_Seg3',
     'Freq segment 3: value > 0x32, MulAccum*0x16/0xB then SLA 15, div by dynamic'),

    ('LABEL_0394C9', 'DSP_FreqCurve_FP_Return',
     'Return from DSP_FreqCurve_FP'),

    # ------------------------------------------------------------------
    # 0394CD  DSP freq param interpolation (2-point, same structure as 039206)
    # ------------------------------------------------------------------
    ('LABEL_0394CD', 'DSP_FreqInterp_2Point',
     'Frequency interpolation: (v2-v1)*progress/0x63 + v1 via stream decoder'),

    # ------------------------------------------------------------------
    # 039525  DSP param interpolation (3-point with XDE offset addition)
    # ------------------------------------------------------------------
    ('LABEL_039525', 'DSP_ParamInterp_3Point_WithOffset',
     'Interpolate with offset: (v2-v1)*progress/0x63 + XDE + v1, return shifted XHL'),

    # ------------------------------------------------------------------
    # 039599-0396A2  DSP reverb curve (FP polynomial, two ranges)
    # ------------------------------------------------------------------
    ('LABEL_039599', 'DSP_ReverbCurve_FP',
     'Reverb FP curve: two-range polynomial, value <= 0x59 vs > 0x59'),

    ('LABEL_039627', 'DSP_ReverbCurve_FP_HighRange',
     'Reverb high range (> 0x59): 3-term FP polynomial + VoiceFloat_SubSP'),

    ('LABEL_0396A2', 'DSP_ReverbCurve_FP_Finalize',
     'Add final FP offset, decode sign, return reverb coefficient in XHL'),

    # ------------------------------------------------------------------
    # 0396C2  DSP complex param interpolation (FP multi-step sub/add chain)
    # ------------------------------------------------------------------
    ('LABEL_0396C2', 'DSP_ParamInterp_FPComplex',
     'Complex FP interpolation: stream decode, VoiceFloat chain, polynomial combine'),

    # ------------------------------------------------------------------
    # 0397F3-0398CD  DSP pan/balance curve (piecewise linear, 5 segments)
    # ------------------------------------------------------------------
    ('LABEL_0397F3', 'DSP_PanCurve_PiecewiseLin',
     'Piecewise-linear pan curve: 5 segments with MulAccum scaling'),

    ('LABEL_03981C', 'DSP_PanCurve_Seg2',
     'Pan segment 2: value in (0x14, 0x1E], MulAccum*5 scale'),

    ('LABEL_039848', 'DSP_PanCurve_Seg3',
     'Pan segment 3: value in (0x1E, 0x46], MulAccum*10 scale'),

    ('LABEL_039875', 'DSP_PanCurve_Seg4',
     'Pan segment 4: value in (0x46, 0x50], MulAccum*50 then *0xAC44 scale'),

    ('LABEL_0398A6', 'DSP_PanCurve_Seg5',
     'Pan segment 5: value > 0x50, MulAccum*100 then *0xAC44 scale'),

    ('LABEL_0398CD', 'DSP_PanCurve_Return',
     'Return from DSP_PanCurve_PiecewiseLin'),

    # ------------------------------------------------------------------
    # 0398CE-039A3A  DSP detune/pitch curve (signed FP, 4 magnitude ranges)
    # Computes absolute value of signed input, dispatches to 4 ranges
    # by magnitude (<=0xA, <=0x13, <=0x1F, >0x1F), then negates if
    # original was negative.
    # ------------------------------------------------------------------
    ('LABEL_0398CE', 'DSP_DetuneCurve_SignedFP',
     'Signed detune FP curve: |input| dispatched to 4 ranges, negate if originally negative'),

    ('LABEL_0398E0', 'DSP_DetuneCurve_NegateInput',
     'Input < 0: negate to get absolute value'),

    ('LABEL_0398E9', 'DSP_DetuneCurve_CheckMagnitude',
     'Check |input| against magnitude thresholds: 0xA, 0x13, 0x1F'),

    ('LABEL_0398FE', 'DSP_DetuneCurve_Range1_NegArm',
     'Range 1 (|v|<=0xA), negative input: negate before FP conversion'),

    ('LABEL_03990A', 'DSP_DetuneCurve_Range1_Compute',
     'Range 1 compute: FP_SP_CallWithBuf8 + add constant 0x012D77'),

    ('LABEL_039926', 'DSP_DetuneCurve_CheckRange2',
     'Check if |input| > 0xA: resolve sign for range 2 dispatch'),

    ('LABEL_039932', 'DSP_DetuneCurve_Range2_NegArm',
     'Range 2, negative input: negate before conversion'),

    ('LABEL_03993B', 'DSP_DetuneCurve_CheckRange2Limit',
     'Range 2 limit check: |input| <= 0x13'),

    ('LABEL_039950', 'DSP_DetuneCurve_Range2_NegStore',
     'Range 2 store negated value for FP computation'),

    ('LABEL_03995C', 'DSP_DetuneCurve_Range2_Compute',
     'Range 2 compute: FP add + sub with two ROM constants'),

    ('LABEL_039987', 'DSP_DetuneCurve_CheckRange3',
     'Check if |input| > 0x13: resolve sign for range 3 dispatch'),

    ('LABEL_039993', 'DSP_DetuneCurve_Range3_NegArm',
     'Range 3, negative input: negate before conversion'),

    ('LABEL_03999C', 'DSP_DetuneCurve_CheckRange3Limit',
     'Range 3 limit check: |input| <= 0x1F'),

    ('LABEL_0399B1', 'DSP_DetuneCurve_Range3_NegStore',
     'Range 3 store negated value for FP computation'),

    ('LABEL_0399BD', 'DSP_DetuneCurve_Range3_Compute',
     'Range 3 compute: FP add + sub with ROM constants 0x012D83/0x012D87'),

    ('LABEL_0399E7', 'DSP_DetuneCurve_Range4_CheckSign',
     'Range 4 (|v|>0x1F): resolve sign for final range'),

    ('LABEL_0399F4', 'DSP_DetuneCurve_Range4_NegStore',
     'Range 4 store negated value for FP computation'),

    ('LABEL_039A00', 'DSP_DetuneCurve_Range4_Compute',
     'Range 4 compute: FP add + sub with ROM constants 0x012D8B/0x012D8F'),

    ('LABEL_039A28', 'DSP_DetuneCurve_ApplySign',
     'Apply original sign: if input < 0, negate FP result'),

    ('LABEL_039A3A', 'DSP_DetuneCurve_Finalize',
     'Final FP chain: VoiceFloat_SubSP, NegMantissa, CompareAndConvert, normalize, return'),

    # ------------------------------------------------------------------
    # 039ABD-039B1A  DSP biquad frequency warping (large FP computation)
    # Reads table entries, applies FP polynomial + comparison, computes
    # warped frequency for DSP biquad filter.
    # ------------------------------------------------------------------
    ('LABEL_039ABD', 'DSP_BiquadWarp_FP',
     'Biquad frequency warp: read table pair, FP polynomial, comparison tables, write coeffs'),

    ('LABEL_039AF2', 'DSP_BiquadWarp_ReadPrevEntry',
     'Read previous table entry (de-1) for warp computation'),

    ('LABEL_039B08', 'DSP_BiquadWarp_ClampHL',
     'Clamp HL to max 0x59'),

    ('LABEL_039B11', 'DSP_BiquadWarp_ClampIZ',
     'Clamp IZ to max 0x58'),

    ('LABEL_039B1A', 'DSP_BiquadWarp_ComputeCoeffs',
     'Compute warp coefficients: 99-hl, FP scalar-to-DP, polynomial chain, write osc+coeff'),

    # ------------------------------------------------------------------
    # 039D26  DSP param interpolation with 0xC6 divisor
    # ------------------------------------------------------------------
    ('LABEL_039D26', 'DSP_ParamInterp_Div0xC6',
     'Interpolate with divisor 0xC6: (v2-v1) * (progress+0x63) / 0xC6 + v1'),

    # ------------------------------------------------------------------
    # 039D98-03A204  DSP parametric EQ curve (FP multi-segment, 5 ranges)
    # Dispatches by input value: <=0xF, <=0x17, <=0x37, <=0x4B, >0x4B.
    # Each range computes filter coefficients via FP polynomial with
    # different ROM constant sets.
    # ------------------------------------------------------------------
    ('LABEL_039D98', 'DSP_ParamEQ_Curve_FP',
     'Parametric EQ FP curve: 5-range filter coefficient computation'),

    ('LABEL_039EDA', 'DSP_ParamEQ_Range1_NonzeroCoeff',
     'Range 1 (<=0xF) nonzero coeff: VoiceFloat multiply and FP chain'),

    ('LABEL_039F49', 'DSP_ParamEQ_Range2',
     'Range 2: value in (0xF, 0x17], FP sub + polynomial'),

    ('LABEL_03A003', 'DSP_ParamEQ_Range3',
     'Range 3: value in (0x17, 0x37], FP sub + polynomial'),

    ('LABEL_03A0BD', 'DSP_ParamEQ_Range4',
     'Range 4: value in (0x37, 0x4B], FP sub + polynomial'),

    ('LABEL_03A177', 'DSP_ParamEQ_Range5',
     'Range 5: value > 0x4B, FP sub + direct VoiceFloat chain'),

    ('LABEL_03A204', 'DSP_ParamEQ_Finalize',
     'Store state, add final FP offset, decode sign, return XHL'),

    # ------------------------------------------------------------------
    # 03A22A  DSP param interpolation (identical structure to 039206)
    # ------------------------------------------------------------------
    ('LABEL_03A22A', 'DSP_ParamInterp_2Point_B',
     'Second 2-point interpolation variant: (v2-v1)*progress/0x63 + v1'),

    # ------------------------------------------------------------------
    # 03A282-03A497  DSP_VolumeParam_Scale variant B
    # Same piecewise structure as 039000 range but at different address.
    # ------------------------------------------------------------------
    ('LABEL_03A282', 'DSP_VolScale_B',
     'Volume param scale variant B: same 3-algo piecewise structure as DSP_VolumeParam_Scale'),

    ('LABEL_03A2BB', 'DSP_VolScale_B_Algo0_Seg2',
     'Variant B algo 0 segment 2: value in (0x32, 0x4B]'),

    ('LABEL_03A2DD', 'DSP_VolScale_B_Algo0_Seg3',
     'Variant B algo 0 segment 3: value in (0x4B, 0x58]'),

    ('LABEL_03A302', 'DSP_VolScale_B_Algo0_Seg4',
     'Variant B algo 0 segment 4: value > 0x58'),

    ('LABEL_03A321', 'DSP_VolScale_B_Algo1_Seg1',
     'Variant B algo 1 segment 1: value <= 0xA'),

    ('LABEL_03A33D', 'DSP_VolScale_B_Algo1_Seg2',
     'Variant B algo 1 segment 2: value in (0xA, 0x13]'),

    ('LABEL_03A366', 'DSP_VolScale_B_Algo1_Seg3',
     'Variant B algo 1 segment 3: value in (0x13, 0x40]'),

    ('LABEL_03A390', 'DSP_VolScale_B_Algo1_Seg4',
     'Variant B algo 1 segment 4: value in (0x40, 0x57]'),

    ('LABEL_03A3BD', 'DSP_VolScale_B_Algo1_Seg5',
     'Variant B algo 1 segment 5: value > 0x57'),

    ('LABEL_03A3E2', 'DSP_VolScale_B_Algo2_Seg1',
     'Variant B algo 2 segment 1: value <= 0x32, dynamic divisor'),

    ('LABEL_03A406', 'DSP_VolScale_B_Algo2_Seg2',
     'Variant B algo 2 segment 2: value in (0x32, 0x4B]'),

    ('LABEL_03A435', 'DSP_VolScale_B_Algo2_Seg3',
     'Variant B algo 2 segment 3: value in (0x4B, 0x58]'),

    ('LABEL_03A468', 'DSP_VolScale_B_Algo2_Seg4',
     'Variant B algo 2 segment 4: value > 0x58'),

    ('LABEL_03A497', 'DSP_VolScale_B_Return',
     'Store state pointer and return from DSP_VolScale_B'),

    # ------------------------------------------------------------------
    # 03A4A0  Simple pan scale: MulAccum by 0xAC44, divide by 0x3E8
    # ------------------------------------------------------------------
    ('LABEL_03A4A0', 'DSP_PanScale_Simple',
     'Simple pan scale: MulAccum*0xAC44, divide by 0x3E8'),

    # ------------------------------------------------------------------
    # 03A4B7-03A5EF  DSP multi-step param interpolation
    # Reads a mode byte from stream, dispatches to 3 orderings of
    # 6 LABEL_03CF07 calls, then computes (v2-v1)*progress/0x63+v1.
    # ------------------------------------------------------------------
    ('LABEL_03A4B7', 'DSP_ParamInterp_MultiStep',
     'Multi-step param interpolation: mode-dependent 6-step stream decode then interp'),

    ('LABEL_03A4DB', 'DSP_ParamInterp_MultiStep_Mode0x10',
     'Mode 0x10: read (iz-1) table entry for source base'),

    ('LABEL_03A4EA', 'DSP_ParamInterp_MultiStep_Mode0x20',
     'Mode 0x20: read (iz-2) table entry for source base'),

    ('LABEL_03A4F7', 'DSP_ParamInterp_MultiStep_Dispatch',
     'Dispatch by mode: 0=order ABC, 1=order BCA, 2=order CAB'),

    ('LABEL_03A551', 'DSP_ParamInterp_MultiStep_Order1',
     'Order 1 (mode=1): decode sequence BBABCC'),

    ('LABEL_03A5A1', 'DSP_ParamInterp_MultiStep_Order2',
     'Order 2 (mode=2): decode sequence BBBBAC'),

    ('LABEL_03A5EF', 'DSP_ParamInterp_MultiStep_Compute',
     'Compute interpolation: (v2-v1)*progress/0x63 + v1, store state, return'),

    # ------------------------------------------------------------------
    # 03A620-03A909  DSP filter LUT fetch with FP scalar-to-DP conversion
    # Large routine that reads filter table entries, converts to FP,
    # applies DP multiplication, and stores results to multiple output
    # buffers. Mode byte selects 3 different computation paths.
    # ------------------------------------------------------------------
    ('LABEL_03A620', 'DSP_FilterLUT_Fetch',
     'Fetch filter LUT: read mode nibble, dispatch to 3 paths for FP coefficient computation'),

    ('LABEL_03A6F5', 'DSP_FilterLUT_Mode0x10',
     'Filter LUT mode 0x10: read (iz-1) base table, FP scalar-to-DP mul'),

    ('LABEL_03A77C', 'DSP_FilterLUT_Mode0x20',
     'Filter LUT mode 0x20 (or default): read (iz-2) base table, FP scalar-to-DP mul'),

    ('LABEL_03A803', 'DSP_FilterLUT_ModeType1',
     'Filter LUT type 1: load fixed 0x3DCCCCCD, read single table entry'),

    ('LABEL_03A82D', 'DSP_FilterLUT_ModeType2',
     'Filter LUT type 2: load fixed 0x40000000, dispatch sub-modes'),

    ('LABEL_03A8A6', 'DSP_FilterLUT_ModeType2_SubMode',
     'Filter LUT type 2 sub-mode: read (iz-1) base, FP scalar-to-DP mul'),

    ('LABEL_03A909', 'DSP_FilterLUT_StoreResults',
     'Store mode, coefficients A/B, DP result, return updated state pointer'),

    # ------------------------------------------------------------------
    # 03A933  DSP full biquad filter coefficient computation (algo 0 entry)
    # This is a massive routine (~0x600 bytes) that computes biquad
    # filter coefficients using floating-point polynomial approximation.
    # It dispatches to 3 algorithm types (0, 1, 2) at 03A933, 03AE72,
    # 03B08A respectively. Each variant goes through:
    #   1. Call DSP_FilterLUT_Fetch for base coefficients
    #   2. FP polynomial chain (NegMantissa, Add, CompareAndConvert, etc.)
    #   3. Sign-dependent coefficient assembly
    #   4. Write osc param + 4 coeff data words to DSP
    # ------------------------------------------------------------------
    ('LABEL_03A933', 'DSP_BiquadCoeff_Compute',
     'Full biquad filter coefficient computation: dispatch algo 0/1/2, write 5 DSP params'),

    ('LABEL_03AA65', 'DSP_BiquadCoeff_Algo0_SignZero',
     'Algo 0: FP coeff zero → copy raw value'),

    ('LABEL_03AA73', 'DSP_BiquadCoeff_Algo0_AfterSign',
     'Algo 0: after sign resolution, VoiceFloat subtract chain'),

    ('LABEL_03AB23', 'DSP_BiquadCoeff_Algo0_Sign2Zero',
     'Algo 0 second coefficient: FP zero → copy raw value'),

    ('LABEL_03AB2F', 'DSP_BiquadCoeff_Algo0_AfterSign2',
     'Algo 0: after second sign resolution, VoiceFloat chain + comparison'),

    ('LABEL_03AC3E', 'DSP_BiquadCoeff_Algo0_NegBranch',
     'Algo 0 negative-coefficient branch: reversed VoiceFloat subtract ordering'),

    ('LABEL_03ACB1', 'DSP_BiquadCoeff_Algo0_Assembly',
     'Algo 0: multiply coefficient pairs, subtract ROM constants, normalize'),

    ('LABEL_03AD1E', 'DSP_BiquadCoeff_Algo0_Fixup',
     'Algo 0: if normalization < threshold, substitute 1.0 (0x3F800000)'),

    ('LABEL_03AE72', 'DSP_BiquadCoeff_Algo1',
     'Biquad algo 1 entry: different FP polynomial constants + 5 VoiceFloat subs'),

    ('LABEL_03B08A', 'DSP_BiquadCoeff_Algo2',
     'Biquad algo 2 entry: 3-stage FP polynomial with intermediate normalization'),

    ('LABEL_03B1D9', 'DSP_BiquadCoeff_Algo2_Sign1Zero',
     'Algo 2 first sign: FP zero → copy raw value'),

    ('LABEL_03B1E5', 'DSP_BiquadCoeff_Algo2_AfterSign1',
     'Algo 2: after first sign, VoiceFloat subtract + comparison chain'),

    ('LABEL_03B28F', 'DSP_BiquadCoeff_Algo2_Sign2Zero',
     'Algo 2 second sign: FP zero → copy raw value'),

    ('LABEL_03B29B', 'DSP_BiquadCoeff_Algo2_AfterSign2',
     'Algo 2: after second sign, VoiceFloat subtract + comparison chain'),

    ('LABEL_03B3A6', 'DSP_BiquadCoeff_Algo2_NegBranch',
     'Algo 2 negative branch: reversed coefficient assembly order'),

    ('LABEL_03B419', 'DSP_BiquadCoeff_Algo2_WriteParams',
     'Algo 2: write osc param + 4 coefficient data words to DSP'),

    ('LABEL_03B4F0', 'DSP_BiquadCoeff_Epilogue',
     'Biquad common epilogue: store state pointer, return updated XHL'),

    # ------------------------------------------------------------------
    # 03B505-03B646  DSP second-order section (SOS) LUT fetch
    # Simpler variant of DSP_FilterLUT_Fetch for second-order sections.
    # ------------------------------------------------------------------
    ('LABEL_03B505', 'DSP_SOS_LUT_Fetch',
     'SOS LUT fetch: read mode byte, FP scalar-to-DP, optional raw copy for mode=2'),

    ('LABEL_03B596', 'DSP_SOS_LUT_Mode0x10',
     'SOS LUT mode 0x10: read (iz-1) base entry'),

    ('LABEL_03B5F9', 'DSP_SOS_LUT_CheckType2',
     'SOS LUT: if mode type == 2, extract 5-bit index for additional raw copy'),

    ('LABEL_03B624', 'DSP_SOS_LUT_StoreResults',
     'SOS LUT: store mode, coefficient, DP result, return'),

    ('LABEL_03B646', 'DSP_SOS_Coeff_Compute',
     'SOS full coefficient computation: call SOS_LUT_Fetch then dispatch algo 0/1/2'),

    # ------------------------------------------------------------------
    # 03B7F4-03B901  SOS algo 0 branches
    # ------------------------------------------------------------------
    ('LABEL_03B7F4', 'DSP_SOS_Algo0_NonzeroCoeff',
     'SOS algo 0 nonzero coeff: different FP polynomial path'),

    ('LABEL_03B901', 'DSP_SOS_Algo0_FinalChain',
     'SOS algo 0 final: ROM constant subtraction + coefficient cross-multiply'),

    # ------------------------------------------------------------------
    # 03B9DD-03BC44  SOS algo 1 computation
    # ------------------------------------------------------------------
    ('LABEL_03B9DD', 'DSP_SOS_Algo1',
     'SOS algo 1 entry: VoiceFloat comparison + conditional dispatch'),

    ('LABEL_03BB3F', 'DSP_SOS_Algo1_NonzeroCoeff',
     'SOS algo 1 nonzero coeff: different polynomial constants'),

    ('LABEL_03BC44', 'DSP_SOS_Algo1_FinalChain',
     'SOS algo 1 final: coefficient cross-multiply and assembly'),

    # ------------------------------------------------------------------
    # 03BD18-03BF7D  SOS algo 2 computation
    # ------------------------------------------------------------------
    ('LABEL_03BD18', 'DSP_SOS_Algo2',
     'SOS algo 2 entry: VoiceFloat comparison + conditional dispatch'),

    ('LABEL_03BE78', 'DSP_SOS_Algo2_NonzeroCoeff',
     'SOS algo 2 nonzero coeff: different polynomial constants'),

    ('LABEL_03BF7D', 'DSP_SOS_Algo2_FinalChain',
     'SOS algo 2 final: coefficient cross-multiply and assembly'),

    # ------------------------------------------------------------------
    # 03C04F-03C067  SOS/Biquad common epilogue + DSP mixer coeff
    # ------------------------------------------------------------------
    ('LABEL_03C04F', 'DSP_SOS_Coeff_Epilogue',
     'SOS common epilogue: store updated state to caller pointer, return XHL'),

    ('LABEL_03C067', 'DSP_MixerCoeff_Compute',
     'Compute DSP mixer coefficient: table lookup, MulAccum chain, write DSP2 via SPI'),

    # ------------------------------------------------------------------
    # 03C1A3-03C24F  DSP_WriteParameter special-case handlers
    # DSP_WriteParameter dispatches by (wa, bc) pair. wa==1 with
    # bc==9 or bc==0xA triggers special EFF config reload paths.
    # ------------------------------------------------------------------
    ('LABEL_03C1A3', 'DSP_WriteParam_EFFCase',
     'WA==1, BC==9 or 0xA: special EFF config reload via 0x3C9E6'),

    ('LABEL_03C1DF', 'DSP_WriteParam_EFFCase0xA',
     'BC==0xA: EFF config reload using table pair 0x01E40A/0x01E42D'),

    ('LABEL_03C20E', 'DSP_WriteParam_Generic',
     'Generic parameter write: look up table pointers from 0x1F22C/0x1F09C'),

    ('LABEL_03C24F', 'DSP_WriteParam_Return',
     'Return from DSP_WriteParameter'),

    # ------------------------------------------------------------------
    # 03CA30-03CAA7  DSP bytecode param loop control
    # Inside the DSP per-parameter translator. These labels manage
    # the iteration loop that processes each param entry in the
    # bytecode stream.
    # ------------------------------------------------------------------
    ('LABEL_03CA30', 'DSP_ParamLoop_CheckBound',
     'Check if iterator < bound: if so, loop back to process more entries'),

    ('LABEL_03CA35', 'DSP_ParamLoop_Iterate',
     'Begin iteration: check if skip-mode enabled, send DSP cmd header if needed'),

    ('LABEL_03CA61', 'DSP_ParamLoop_CallTranslator',
     'Push params and call DSP_PerParameterTranslator for current entry'),

    ('LABEL_03CA8F', 'DSP_ParamLoop_PostCall',
     'After translator call: check skip, optionally send DSP end command'),

    ('LABEL_03CAA2', 'DSP_ParamLoop_SendEndCmd',
     'Send DSP end command (0x36A2E with arg 3), check bound and loop'),

    ('LABEL_03CAA7', 'DSP_ParamLoop_Return',
     'Return from DSP param loop'),

    # ------------------------------------------------------------------
    # 03CB18-03CBCC  DSP_PerParameterTranslator main loop + dispatch
    # ------------------------------------------------------------------
    ('LABEL_03CB18', 'DSP_Translator_ReadOpcode',
     'Read next opcode byte from stream, decode parameter key, dispatch'),

    ('LABEL_03CB8E', 'DSP_Translator_JumpTable',
     'Inline opcode jump table data (bytecoded dispatch targets)'),

    ('LABEL_03CBA8', 'DSP_Translator_PostDispatch',
     'After dispatch: check if state-change notification needed, then check loop end'),

    ('LABEL_03CBB6', 'DSP_Translator_CheckEnd',
     'Read next stream byte: if 0x7A (end marker), exit loop; else process opcode'),

    ('LABEL_03CBCC', 'DSP_Translator_Return',
     'Store skip status, return updated stream pointer in XHL'),

    # ------------------------------------------------------------------
    # 03CE9F-03CEFF  DSP param opcode dispatch targets
    # These are the targets for opcode values 0x40, 0x24, 0x21 and
    # the unknown-opcode error handler in DSP_PerParameterTranslator.
    # ------------------------------------------------------------------
    ('LABEL_03CE9F', 'DSP_Op_0x40_PanScale',
     'Opcode 0x40: call DSP_PanScale_Simple then DSP_WriteOscParam'),

    ('LABEL_03CEBC', 'DSP_Op_0x24_MultiStepInterp',
     'Opcode 0x24: call DSP_ParamInterp_MultiStep then DSP_WriteOscParam'),

    ('LABEL_03CEE2', 'DSP_Op_0x21_Interp2Point',
     'Opcode 0x21: call DSP_ParamInterp_2Point then DSP_WriteOscParam'),

    ('LABEL_03CEFF', 'DSP_Op_Unknown_Error',
     'Unknown opcode: set error status 5, jump to return'),

    # ------------------------------------------------------------------
    # 03CF07  Stream decoder: read 3 signed bytes -> packed 24-bit word
    # Reads 3 consecutive bytes via st_dpib, sign-extends each to 32 bits,
    # shifts to 24/16/8 bit positions, ORs together, stores to (XBC).
    # Returns original XWA position in XHL.
    # ------------------------------------------------------------------
    ('LABEL_03CF07', 'DSP_StreamDecode_3ByteWord',
     'Read 3 signed bytes from stream -> 24-bit packed word in (XBC), advance stream ptr'),

    # ------------------------------------------------------------------
    # 03CF53-03CF9D  Table walker: search keyed entry in packed table
    # Scans a packed 2-byte-per-entry table for a matching key byte.
    # Returns status in BC (0=found in range, 3=end marker, 4=past end)
    # and XHL pointing past the matched entry.
    # ------------------------------------------------------------------
    ('LABEL_03CF53', 'DSP_TableWalk_Search',
     'Search packed table for key BC in DE-stride entries; return status + XHL position'),

    ('LABEL_03CF57', 'DSP_TableWalk_CheckEntry',
     'Check current entry: compare key, advance if match, skip to next if mismatch'),

    ('LABEL_03CF77', 'DSP_TableWalk_FoundInRange',
     'Entry found within range: set BC=0'),

    ('LABEL_03CF7B', 'DSP_TableWalk_SkipEntry',
     'Key mismatch: advance XHL past entry and check next'),

    ('LABEL_03CF7D', 'DSP_TableWalk_ReadHeader',
     'Read 2-byte entry header, extract 12-bit size field + 4-bit high nibble'),

    ('LABEL_03CF9D', 'DSP_TableWalk_Return',
     'Store status to caller pointer and return'),

    # ------------------------------------------------------------------
    # 03CFA5-03CFE6  Table walker variant: search with state update
    # Similar to DSP_TableWalk_Search but also updates a state pointer
    # stored at (XSP+4) with the matched entry address.
    # ------------------------------------------------------------------
    ('LABEL_03CFA5', 'DSP_TableWalk_SearchWithState',
     'Search packed table + update state pointer at (XSP+4) with match address'),

    ('LABEL_03CFA9', 'DSP_TableWalk_State_CheckEntry',
     'Check entry: if BC==0, found → store address; else advance by IY stride'),

    ('LABEL_03CFBE', 'DSP_TableWalk_State_Advance',
     'Add IY stride to current position and decrement BC counter'),

    ('LABEL_03CFC6', 'DSP_TableWalk_State_ReadHeader',
     'Read entry header, extract size + high nibble, check for 0xF0 end marker'),

    ('LABEL_03CFE6', 'DSP_TableWalk_State_Return',
     'Store status to (XHL), return XWA in XHL'),

    # ------------------------------------------------------------------
    # 03CFED  Nop return (single ret instruction)
    # Called as a placeholder / consumed-status sink.
    # ------------------------------------------------------------------
    ('LABEL_03CFED', 'DSP_NopReturn',
     'Single ret instruction, used as no-op callback'),
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

    # Check maincpu for cross-references (none expected for 038/03C range,
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
