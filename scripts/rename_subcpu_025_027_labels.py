#!/usr/bin/env python3
"""Rename LABEL_* to semantic names for voice-parameter helpers in subcpu (025-027 range).

Based on analysis of the 0x025000-0x027FFF address range in the SubCPU
audio subsystem. This block contains voice-parameter computation and
hardware-register write helpers that are invoked during per-voice update
loops (e.g. LABEL_02B4E3, LABEL_02BCD6, LABEL_02C0B6) which process all
active voices on every note-on, note-off, and controller-change event.

Function grouping (by address range):
  025000-0251D9  Voice1_UpdatePitch / inner branch labels
  025229-0253F9  Voice2_UpdatePitch / inner branch labels
  0253FE-025493  Voice_ComputeExprPitchBend  (called from Voice_CC routines)
  025499-025524  Voice_ComputePitchBend2      (variant with osc pointer)
  02552A-025586  Voice_ApplyModeToPitchWord   (mode bits -> pitch word fields)
  025589-025588  Voice_SetPitchWord_Muted     (mute flag -> pitch word)
  0255F3-025801  Voice_SetPitchWord_Unmuted   (no mute flag -> pitch word)
  025636-025875  Voice_ComputeAndWritePan     (pan/pan-LFO -> DSP pan register)
  02591D-025A31  Voice_WriteChPanShift        (channel pan-shift offsets -> DSP)
  025A35-025B6A  Voice_UpdatePan_Simple       (simple pan update for mono voice)
  025B6F-025C83  Voice_WriteChPanShift2       (variant channel pan-shift write)
  025C87-025D50  Voice_UpdatePan_Full         (full pan computation with bend)
  025D77-025F6E  Voice_UpdatePan_Full2        (stereo variant with L/R channels)
  025F7F-026054  Voice_UpdatePan_Mono         (mono variant -- single-channel)
  026083-0260FA  inner tail labels of Voice_UpdatePan_Mono
  026099-026054  (continuation tail)
  0261BC-026282  inner labels of Voice_UpdatePan_Full2 tail
  026283-02630B  Voice_InterpolatePanCurve    (piecewise linear pan interpolation)
  02630C-026395  Voice_InterpolateNoteCurve   (piecewise linear note interpolation)
  026396-026511  Voice_ComputePitch           (full pitch computation with bend/LFO)
  026522          (data block -- 9 bytes, branch table or inline code snippet)
  026533-026611  Voice_ComputePitch_Mono      (mono-voice pitch computation)
  026637-026657  Voice_ApplyPortamento        (portamento glide adjustment)
  026684-0266D3  Voice_ApplyPortamento2       (variant with vibrato/LFO offset)
  0266D8-026764  Voice_WriteChPitchWithVib    (vibrato LFO -> DSP freq for channel)
  026769-026849  Voice_ComputeAndWriteVolume1 (volume 1: standard voice volume)
  02684A-02685A  Voice_WritePan_Passthrough   (copy stored pan straight to DSP)
  02685B-02686E  Voice_WriteVolume_SetFlag    (write DSP volume with set-7 flag)
  02686F-026974  Voice_ComputeVolume_CappedLFO (volume with soft-limited LFO)
  026975-026A49  Voice_ComputeAndWriteVolume2 (volume 2: aftertouch/mod-wheel)
  026A6E-026A48  inner labels of volume-2 tail
  026AAA-026BD3  Voice_ComputeAndWriteVolume3 (volume 3: secondary aftertouch)
  026BDC-026C15  Voice_WriteVolume_Muted      (all DSP volume regs zeroed + volume2 word)
  026C16-026C51  Voice_WriteVolume_OrPan      (pan pointer -> DSP f8/fa volume regs)
  026C52-026CAD  Voice_AdvanceLFOPhase        (advance LFO oscillator phase counter)
  026CAE-026E58  Voice_UpdateAllLFO           (iterate all 128 voices, tick LFO phases)
  026E5B-026EC2  Voice_UpdateNoteOff          (note-off countdown: trigger note-off when zero)
  026EC3-0271B8  Voice_UpdatePortamento       (portamento step & DSP freq write)
  0271BC-0271B8  Voice_ApplyTuningSysEx       (apply SysEx fine-tuning flags)
  0271FF-0272A2  Voice_ApplyTuningSysEx2      (variant tuning path: 2-step fine-tune)
  0272A3-027362  Voice_InitVoiceState         (zero/init all per-voice DSP state regs)
  027363-027338  Voice_TickNoteDecay          (decrement note-decay counter, init on zero)
  0273D8-027495  Voice_LoadPitchTable_Ch      (look up per-channel pitch table entry)
  027496-027528  (loop tail of Voice_LoadPitchTable_Ch)
  0274C7-027533  Voice_LoadPitchTable_All     (load pitch table for all channels)
  027534-027621  Voice_LoadFilterTable_Ch     (look up per-channel filter freq + LPF table)
  027623-027689  Voice_LoadFilterTable_All    (load filter table for all channels)
  027690-02773C  Voice_LoadToneTable_Ch       (look up per-channel tone table entry, write DCF)
  02773D-02783C  Voice_LoadToneTable_All      (load tone table for all channels)
  027798-027838  Voice_ToneTableRamp_Up       (increment tone table index, ramp up filter)
  027839          epilogue label of Voice_ToneTableRamp_Up
  02783D-0278C6  Voice_ToneTableRamp_Down     (decrement tone table index, ramp down filter)
  0278CB-027986  Voice_ToneTableApply_Pitch   (apply pitch->tone table transformation)
  027987-027A45  Voice_ToneTableApply_Filter  (apply filter->tone table transformation)
  027A46-027ABF  Voice_ScanAndCancelNoteOff   (scan all voices, cancel note-off if found)
  027AC4-027CBA  Voice_UpdateAllNoteStates    (full per-tick note-state machine for all voices)
  027CBE-027CC3  Voice_SetLFO_ActiveFlag      (set LFO active flag bit 5 in voice state word)
  027CD1-027CE3  Voice_ClearLFO_ActiveFlag    (clear LFO active flag bit 5 in voice state word)
  027CE4          (data block -- inline DSP microcode or LUT)
  027F74-027F95  DSP_WriteVoiceParam_Long     (write voice param to DSP via addr 0x100000 offset 0x400)
  027F96-027FB5  DSP_WriteVoiceParam_Short    (write voice param to DSP via addr 0x100000 offset 0x080)
  027FBB-027FD5  DSP_WriteVoiceParam_Direct   (write voice param direct to DSP addr 0x100000)
  027FD6-0280A6  DSP_WriteVoiceParam_6Words   (write 6 voice param words to DSP with consecutive offsets)

Uses binary I/O to handle Latin-1 encoding safely.
"""

import os
import re


# Each entry: (old_label, new_label, brief_comment)
# Inner branch labels (loop bodies, if/else arms, tail returns) are named
# with a suffix indicating their role:  _BranchXxx, _NoXxx, _Done, _Loop, etc.
RENAMES = [

    # ------------------------------------------------------------------ #
    # 024F41-025228  Voice1_UpdatePitch                                   #
    #   Arg: xwa = voice struct ptr. Reads pitch-bend, key, LFO values,  #
    #   calls LABEL_02177E (voice_lookup?), writes 0x0451cc channel       #
    #   params, calls LABEL_02DCD0 / LABEL_02DEB0 / 0x2DC50.             #
    # ------------------------------------------------------------------ #
    ('LABEL_024F41', 'Voice1_UpdatePitch',
     'Compute and write pitch registers for voice group 1 (standard)'),

    ('LABEL_024FD4', 'Voice1_UpdatePitch_NoOsc7Flag',
     'Inner: path when oscillator-7 flag is clear'),

    ('LABEL_024FFF', 'Voice1_UpdatePitch_ChanEntry',
     'Inner: set up channel-table pointer, branch on voice-index < 0x40'),

    ('LABEL_025051', 'Voice1_UpdatePitch_WritePBend',
     'Inner: compute and write pitch-bend for voice group 1'),

    ('LABEL_025088', 'Voice1_UpdatePitch_CheckSustain',
     'Inner: check sustain-flag and bit 13 of secondary flags'),

    ('LABEL_02509C', 'Voice1_UpdatePitch_CheckBit5',
     'Inner: check bit 5 of channel-table byte (osc active flag)'),

    ('LABEL_0250A3', 'Voice1_UpdatePitch_DeactivateOsc',
     'Inner: deactivate osc entry, write 0 to DSP, call LABEL_02DCD0'),

    ('LABEL_0250CA', 'Voice1_UpdatePitch_CheckPhase',
     'Inner: check phase-count for zero, check note-off flag'),

    ('LABEL_0250DB', 'Voice1_UpdatePitch_CheckStateFlags',
     'Inner: check state-flags 0x38 for active voice'),

    ('LABEL_025100', 'Voice1_UpdatePitch_WriteFreq',
     'Inner: call LABEL_022F3C (compute freq), write 0x045204'),

    ('LABEL_025127', 'Voice1_UpdatePitch_AltEntry',
     'Inner: alternate pitch entry path (bit 15 set in flags)'),

    ('LABEL_025199', 'Voice1_UpdatePitch_WriteAltFreq',
     'Inner: write alternate freq words from voice struct offsets +95/+97'),

    ('LABEL_0251BA', 'Voice1_UpdatePitch_WriteStereoField',
     'Inner: compute stereo-field word, write 0x0451d8'),

    ('LABEL_0251DE', 'Voice1_UpdatePitch_StereoPart2',
     'Inner: stereo part-2 (algo type 2 path)'),

    ('LABEL_025206', 'Voice1_UpdatePitch_StereoFallthrough',
     'Inner: fallthrough stereo -- or in voice-struct byte +35'),

    ('LABEL_025219', 'Voice1_UpdatePitch_StoreStereo',
     'Inner: write stereo word to 0x0451d8 and return'),

    # ------------------------------------------------------------------ #
    # 025229-0253F9  Voice2_UpdatePitch                                   #
    #   Parallel to Voice1 but for secondary oscillator group.            #
    # ------------------------------------------------------------------ #
    ('LABEL_025229', 'Voice2_UpdatePitch',
     'Compute and write pitch registers for voice group 2 (secondary osc)'),

    ('LABEL_0252B8', 'Voice2_UpdatePitch_NoOsc7Flag',
     'Inner: path when secondary osc-7 flag is clear'),

    ('LABEL_0252E3', 'Voice2_UpdatePitch_ChanEntry',
     'Inner: set up secondary channel-table pointer'),

    ('LABEL_025331', 'Voice2_UpdatePitch_WritePBend',
     'Inner: compute and write pitch-bend for voice group 2'),

    ('LABEL_025363', 'Voice2_UpdatePitch_CheckSustain',
     'Inner: check sustain-flag for secondary osc'),

    ('LABEL_025377', 'Voice2_UpdatePitch_CheckBit5',
     'Inner: check bit 5 of secondary channel-table byte'),

    ('LABEL_02537E', 'Voice2_UpdatePitch_DeactivateOsc',
     'Inner: deactivate secondary osc, write 0 to DSP regs'),

    ('LABEL_0253AB', 'Voice2_UpdatePitch_CheckPhase',
     'Inner: check secondary phase-count'),

    ('LABEL_0253BC', 'Voice2_UpdatePitch_CheckStateFlags',
     'Inner: check secondary state-flags 0x38'),

    ('LABEL_0253DB', 'Voice2_UpdatePitch_WriteFreq',
     'Inner: call LABEL_023043 (compute secondary freq), write DSP'),

    ('LABEL_0253F9', 'Voice2_UpdatePitch_Done',
     'Inner: epilogue, return from Voice2_UpdatePitch'),

    # ------------------------------------------------------------------ #
    # 0253FE-025493  Voice_ComputeExprPitchBend                           #
    #   Called from Voice_CC routines and voice-setup paths.              #
    #   xwa = voice struct ptr. Reads +15 (pitch-bend), +18 (expr),      #
    #   +102 (fine), +92 (coarse). Writes to 0x0451d2 (pitch-bend reg).  #
    # ------------------------------------------------------------------ #
    ('LABEL_0253FE', 'Voice_ComputeExprPitchBend',
     'Compute expression+pitch-bend value and write to 0x0451d2'),

    ('LABEL_02541D', 'Voice_ComputeExprPitchBend_UseCoarse',
     'Inner: use coarse pitch-bend (+15) when mode != 6'),

    ('LABEL_025429', 'Voice_ComputeExprPitchBend_ZeroCoarse',
     'Inner: both coarse fields zero -- load base value from struct'),

    ('LABEL_025433', 'Voice_ComputeExprPitchBend_ApplyDetune',
     'Inner: apply detune offset from osc table (+92) to pitch-bend'),

    ('LABEL_025455', 'Voice_ComputeExprPitchBend_ClampHigh',
     'Inner: clamp pitch-bend to 0x7F (upper bound)'),

    ('LABEL_02545E', 'Voice_ComputeExprPitchBend_ShiftLeft',
     'Inner: shift result left 8 before OR-ing low byte'),

    ('LABEL_025461', 'Voice_ComputeExprPitchBend_CheckExpr',
     'Inner: check expression field (+18) for non-zero'),

    ('LABEL_025477', 'Voice_ComputeExprPitchBend_FullExpr',
     'Inner: mode 5 or 6 -- OR in 0x7F for full expression'),

    ('LABEL_02547D', 'Voice_ComputeExprPitchBend_PartialExpr',
     'Inner: partial expression -- OR in raw expr byte'),

    ('LABEL_025489', 'Voice_ComputeExprPitchBend_NoExpr',
     'Inner: expression field zero -- OR in raw byte anyway'),

    ('LABEL_025493', 'Voice_ComputeExprPitchBend_Write',
     'Inner: write assembled pitch-bend word to 0x0451d2 and return'),

    # ------------------------------------------------------------------ #
    # 025499-025524  Voice_ComputePitchBend2                              #
    #   Like Voice_ComputeExprPitchBend but receives xhl = osc ptr        #
    #   (voice struct +19) in addition to the voice struct in xwa.       #
    # ------------------------------------------------------------------ #
    ('LABEL_025499', 'Voice_ComputePitchBend2',
     'Pitch-bend+expression compute variant with explicit osc pointer'),

    ('LABEL_0254BB', 'Voice_ComputePitchBend2_UseCoarse',
     'Inner: use coarse bend when mode != 6'),

    ('LABEL_0254C7', 'Voice_ComputePitchBend2_ZeroCoarse',
     'Inner: coarse fields zero -- load base from struct'),

    ('LABEL_0254D1', 'Voice_ComputePitchBend2_ApplyDetune',
     'Inner: apply detune from osc table (+15) for variant 2'),

    ('LABEL_0254E6', 'Voice_ComputePitchBend2_ClampHigh',
     'Inner: clamp pitch-bend result to 0x7F'),

    ('LABEL_0254EF', 'Voice_ComputePitchBend2_ShiftLeft',
     'Inner: shift result left 8'),

    ('LABEL_0254F2', 'Voice_ComputePitchBend2_CheckExpr',
     'Inner: check expression field for non-zero'),

    ('LABEL_025508', 'Voice_ComputePitchBend2_FullExpr',
     'Inner: mode 5 or 6 -- OR 0x7F for full expression'),

    ('LABEL_02550E', 'Voice_ComputePitchBend2_PartialExpr',
     'Inner: partial expression -- OR raw byte'),

    ('LABEL_02551A', 'Voice_ComputePitchBend2_NoExpr',
     'Inner: no expression -- OR raw byte (zero path)'),

    ('LABEL_025524', 'Voice_ComputePitchBend2_Write',
     'Inner: write assembled word to 0x0451d2 and return'),

    # ------------------------------------------------------------------ #
    # 02552A-025586  Voice_ApplyModeToPitchWord                           #
    #   a = voice/part index, bc = initial pitch word.                    #
    #   Reads mode nibbles from 0x04138d indexed by part/algo type,       #
    #   sets/clears bits 9,12 in bc. Returns hl = modified pitch word.   #
    # ------------------------------------------------------------------ #
    ('LABEL_02552A', 'Voice_ApplyModeToPitchWord',
     'Read mode nibble from algo table, set/clear pitch-word mode bits'),

    ('LABEL_025551', 'Voice_ApplyModeToPitchWord_Mode2',
     'Inner: mode 2 -- clear bits 11:9, set bit 9'),

    ('LABEL_025558', 'Voice_ApplyModeToPitchWord_HighNibble',
     'Inner: read high algo-type nibble to set/clear bits 14:12'),

    ('LABEL_02557F', 'Voice_ApplyModeToPitchWord_Mode2High',
     'Inner: high nibble mode 2 -- clear bits 14:12, set bit 12'),

    ('LABEL_025586', 'Voice_ApplyModeToPitchWord_Done',
     'Inner: return modified pitch word in hl'),

    # ------------------------------------------------------------------ #
    # 025589-025588  Voice_SetPitchWord_Muted                             #
    #   xwa = voice struct ptr, sets mute flag in pitch word based on    #
    #   oscillator volume byte, calls Voice_ApplyModeToPitchWord.         #
    # ------------------------------------------------------------------ #
    ('LABEL_025589', 'Voice_SetPitchWord_Muted',
     'Build pitch-word with mute bit set based on osc volume byte'),

    ('LABEL_0255AA', 'Voice_SetPitchWord_Muted_CheckExpr',
     'Inner: check expression field (+18) for mode adjustment'),

    ('LABEL_0255C4', 'Voice_SetPitchWord_Muted_FullExpr',
     'Inner: mode 5/6 -- OR pitch word with 0xFE00'),

    ('LABEL_0255CF', 'Voice_SetPitchWord_Muted_PartialExpr',
     'Inner: other modes -- OR pitch word with 0xF000'),

    ('LABEL_0255DA', 'Voice_SetPitchWord_Muted_NoExpr',
     'Inner: zero expression -- OR pitch word with 0xF000'),

    ('LABEL_0255E3', 'Voice_SetPitchWord_Muted_ApplyMode',
     'Inner: call Voice_ApplyModeToPitchWord and store result'),

    # ------------------------------------------------------------------ #
    # 0255F3-025801  Voice_SetPitchWord_Unmuted                           #
    #   Like Voice_SetPitchWord_Muted but without setting mute bit.      #
    # ------------------------------------------------------------------ #
    ('LABEL_0255F3', 'Voice_SetPitchWord_Unmuted',
     'Build pitch-word without mute bit (unmuted voice)'),

    ('LABEL_025613', 'Voice_SetPitchWord_Unmuted_FullExpr',
     'Inner: mode 5/6 -- write 0xFE00 to pitch word'),

    ('LABEL_02561A', 'Voice_SetPitchWord_Unmuted_PartialExpr',
     'Inner: other modes -- write 0xF000 to pitch word'),

    ('LABEL_025621', 'Voice_SetPitchWord_Unmuted_NoExpr',
     'Inner: zero expression -- write 0xF000'),

    ('LABEL_025626', 'Voice_SetPitchWord_Unmuted_ApplyMode',
     'Inner: call Voice_ApplyModeToPitchWord and store result'),

    # ------------------------------------------------------------------ #
    # 025636-025875  Voice_ComputeAndWritePan                             #
    #   xwa = voice struct ptr. Reads pan, pan-LFO, key-track offsets.   #
    #   Calls LABEL_022B19 (clamp), writes 0x0451e4 (pan register).      #
    # ------------------------------------------------------------------ #
    ('LABEL_025636', 'Voice_ComputeAndWritePan',
     'Compute pan value with LFO/key-track and write to DSP pan register'),

    ('LABEL_02566A', 'Voice_ComputeAndWritePan_SetInvFlag',
     'Inner: set invert-pan flag (bit 15 of word +1)'),

    ('LABEL_025672', 'Voice_ComputeAndWritePan_ApplyKeyTrack',
     'Inner: apply key-track offset to pan, call LABEL_022B19 clamp'),

    ('LABEL_025716', 'Voice_ComputeAndWritePan_NoPanLFO',
     'Inner: no pan-LFO depth -- add base pan only'),

    ('LABEL_025727', 'Voice_ComputeAndWritePan_NoOscLFO',
     'Inner: no oscillator LFO -- apply pan-depth only'),

    ('LABEL_02575D', 'Voice_ComputeAndWritePan_CheckMax',
     'Inner: check if pan == 0xFF and bit 0 set (reduce by 1)'),

    ('LABEL_02576E', 'Voice_ComputeAndWritePan_WriteDSP',
     'Inner: look up pan table, build DSP word, write 0x0451e4 and +60'),

    ('LABEL_025851', 'Voice_ComputeAndWritePan_NoModDepth',
     'Inner: no mod depth -- apply simple LFO to both stereo channels'),

    ('LABEL_025875', 'Voice_ComputeAndWritePan_NoPanDepth2',
     'Inner: no pan depth when osc LFO is absent'),

    # ------------------------------------------------------------------ #
    # 0258BE-025A30  continuation of Voice_ComputeAndWritePan             #
    # ------------------------------------------------------------------ #
    ('LABEL_0258BE', 'Voice_ComputeAndWritePan_WriteChans',
     'Inner: write left/right channel pan words to voice struct +62/+64'),

    ('LABEL_0258DC', 'Voice_ComputeAndWritePan_ClampDepth',
     'Inner: clamp pan depth value (max 4)'),

    # ------------------------------------------------------------------ #
    # 02591D-025A31  Voice_WriteChPanShift                                #
    #   c = channel index, xwa = voice struct ptr. Checks stereo-shift   #
    #   bits at osc-table +24, adjusts pan shift up/down, writes        #
    #   0x0451e6/0x0451e8.                                               #
    # ------------------------------------------------------------------ #
    ('LABEL_02591D', 'Voice_WriteChPanShift',
     'Apply channel pan-shift (stereo spread) and write to 0x0451e6/e8'),

    ('LABEL_02598A', 'Voice_WriteChPanShift_AddShift',
     'Inner: add pan-shift offset (direction bit 9 clear)'),

    ('LABEL_0259C2', 'Voice_WriteChPanShift_ClampAndWrite',
     'Inner: clamp shift values to 0x7F, write 0x0451e6/e8'),

    ('LABEL_0259EE', 'Voice_WriteChPanShift_NoChanFlag',
     'Inner: c == 0 -- write shift without high-flag'),

    ('LABEL_025A03', 'Voice_WriteChPanShift_WriteL',
     'Inner: write left-channel pan word to 0x0451e6'),

    ('LABEL_025A1B', 'Voice_WriteChPanShift_Passthrough',
     'Inner: stereo-shift inactive -- passthrough stored pan values'),

    ('LABEL_025A31', 'Voice_WriteChPanShift_Done',
     'Inner: return from Voice_WriteChPanShift'),

    # ------------------------------------------------------------------ #
    # 025A35-025B6A  Voice_UpdatePan_Simple                               #
    #   xwa = voice struct ptr. Sets bit 15 of word +1, reads osc       #
    #   table pan fields. No bend/LFO. Writes struct +60/+62/+64.       #
    # ------------------------------------------------------------------ #
    ('LABEL_025A35', 'Voice_UpdatePan_Simple',
     'Simple (mono) pan update: compute volume+pan words, no bend/LFO'),

    ('LABEL_025A9E', 'Voice_UpdatePan_Simple_WritePan',
     'Inner: write pan word to 0x0451e4 and voice struct +60'),

    ('LABEL_025AFE', 'Voice_UpdatePan_Simple_WriteChans',
     'Inner: write L/R channel words to voice struct +62/+64'),

    ('LABEL_025B58', 'Voice_UpdatePan_Simple_NoChanFlag',
     'Inner: no stereo-flag -- store zero pan word to +64'),

    ('LABEL_025B6A', 'Voice_UpdatePan_Simple_Done',
     'Inner: epilogue'),

    # ------------------------------------------------------------------ #
    # 025B6F-025C83  Voice_WriteChPanShift2                               #
    #   Variant of Voice_WriteChPanShift for alternate stereo path.      #
    # ------------------------------------------------------------------ #
    ('LABEL_025B6F', 'Voice_WriteChPanShift2',
     'Alternate channel pan-shift write (stereo variant 2)'),

    ('LABEL_025BDC', 'Voice_WriteChPanShift2_AddShift',
     'Inner: add pan-shift (direction bit 9 clear, variant 2)'),

    ('LABEL_025C14', 'Voice_WriteChPanShift2_ClampAndWrite',
     'Inner: clamp and write pan-shift variant 2'),

    ('LABEL_025C40', 'Voice_WriteChPanShift2_NoChanFlag',
     'Inner: c == 0 path for variant 2'),

    ('LABEL_025C55', 'Voice_WriteChPanShift2_WriteL',
     'Inner: write left-channel word variant 2'),

    ('LABEL_025C6D', 'Voice_WriteChPanShift2_Passthrough',
     'Inner: passthrough stored pan values variant 2'),

    ('LABEL_025C83', 'Voice_WriteChPanShift2_Done',
     'Inner: epilogue variant 2'),

    # ------------------------------------------------------------------ #
    # 025C87-025DBE  Voice_UpdatePan_Full                                 #
    #   Full pan update with pitch-bend lookup and LFO. Two sub-paths    #
    #   depending on bit 11 of word +1 (uses key table or osc table).   #
    # ------------------------------------------------------------------ #
    ('LABEL_025C87', 'Voice_UpdatePan_Full',
     'Full pan update: bend LFO lookup, write pan + L/R channel words'),

    ('LABEL_025CAC', 'Voice_UpdatePan_Full_SetInvFlag',
     'Inner: set invert-pan flag (bit 15 clear path)'),

    ('LABEL_025CB4', 'Voice_UpdatePan_Full_CheckBit11',
     'Inner: check bit 11 of voice flags for alt-table path'),

    ('LABEL_025CCB', 'Voice_UpdatePan_Full_OscTablePath',
     'Inner: bit 11 clear -- use osc table for pan computation'),

    ('LABEL_025D77', 'Voice_UpdatePan_Full_NoPanDepth',
     'Inner: no pan-LFO depth -- simple sum and clamp'),

    ('LABEL_025D88', 'Voice_UpdatePan_Full_NoPanLFO',
     'Inner: no LFO depth -- direct pass without LFO term'),

    # ------------------------------------------------------------------ #
    # 025DBE-025F7E  continuation of Voice_UpdatePan_Full                #
    # ------------------------------------------------------------------ #
    ('LABEL_025DBE', 'Voice_UpdatePan_Full_CheckMax',
     'Inner: check max-pan and bit 0 (reduce)'),

    ('LABEL_025DD2', 'Voice_UpdatePan_Full_WriteDSP',
     'Inner: write pan word to 0x0451e4, L/R channel words from osc'),

    ('LABEL_025EB5', 'Voice_UpdatePan_Full_NoModDepth',
     'Inner: no mod depth -- apply LFO to both channels simple'),

    ('LABEL_025ED9', 'Voice_UpdatePan_Full_NoPanDepth2',
     'Inner: osc LFO absent -- apply only key-track bend'),

    ('LABEL_025F22', 'Voice_UpdatePan_Full_WriteChDepth',
     'Inner: write channel pan-depth words to 0x0451e6/e8'),

    ('LABEL_025F40', 'Voice_UpdatePan_Full_WriteCh2',
     'Inner: write second channel pan-depth word'),

    # ------------------------------------------------------------------ #
    # 025F7F-026082  Voice_UpdatePan_Mono                                 #
    #   Mono variant: only one oscillator, no stereo L/R channel split.  #
    # ------------------------------------------------------------------ #
    ('LABEL_025F7F', 'Voice_UpdatePan_Mono',
     'Mono pan update: single oscillator path, write pan to 0x0451e4'),

    ('LABEL_025FA4', 'Voice_UpdatePan_Mono_SetInvFlag',
     'Inner: set invert-pan flag for mono path'),

    ('LABEL_025FAC', 'Voice_UpdatePan_Mono_ComputePan',
     'Inner: look up pan table, start mono LFO computation'),

    ('LABEL_02603A', 'Voice_UpdatePan_Mono_NoPanDepth',
     'Inner: no pan-LFO depth -- direct sum'),

    ('LABEL_02604D', 'Voice_UpdatePan_Mono_NoPanLFO',
     'Inner: no LFO -- apply only portamento bend'),

    ('LABEL_026083', 'Voice_UpdatePan_Mono_CheckMax',
     'Inner: check max-pan (FF), reduce if flag bit 0 set'),

    ('LABEL_026099', 'Voice_UpdatePan_Mono_WriteDSP',
     'Inner: write mono pan word to 0x0451e4 and voice struct +60'),

    # ------------------------------------------------------------------ #
    # 0261BC-026282  inner labels of Voice_UpdatePan_Full2                #
    # ------------------------------------------------------------------ #
    ('LABEL_0261BC', 'Voice_UpdatePan_Full2_NoModDepth',
     'Inner (full2): no mod depth -- simple LFO sum'),

    ('LABEL_0261E0', 'Voice_UpdatePan_Full2_NoPanDepth',
     'Inner (full2): no LFO depth -- direct bend only'),

    ('LABEL_026226', 'Voice_UpdatePan_Full2_WriteChDepth',
     'Inner (full2): write channel pan-depth words'),

    ('LABEL_026244', 'Voice_UpdatePan_Full2_WriteCh2',
     'Inner (full2): write second channel depth word and return'),

    # ------------------------------------------------------------------ #
    # 026283-02630B  Voice_InterpolatePanCurve                            #
    #   xwa = voice struct ptr, xbc = osc ptr. Reads pan word at +8,    #
    #   interpolates between curve breakpoints at xbc+30..+33.           #
    #   Returns hl = interpolated pan value.                             #
    # ------------------------------------------------------------------ #
    ('LABEL_026283', 'Voice_InterpolatePanCurve',
     'Piecewise-linear interpolation of pan value against curve table'),

    ('LABEL_0262A4', 'Voice_InterpolatePanCurve_LowRange',
     'Inner: interpolate in lower range (below breakpoint +30)'),

    ('LABEL_0262C9', 'Voice_InterpolatePanCurve_HighCheck',
     'Inner: check upper breakpoint range'),

    ('LABEL_0262E0', 'Voice_InterpolatePanCurve_HighRange',
     'Inner: interpolate in upper range'),

    ('LABEL_026309', 'Voice_InterpolatePanCurve_Zero',
     'Inner: value in flat region -- return 0'),

    ('LABEL_02630B', 'Voice_InterpolatePanCurve_Done',
     'Inner: return interpolated value'),

    # ------------------------------------------------------------------ #
    # 02630C-026395  Voice_InterpolateNoteCurve                           #
    #   xwa = voice struct ptr, xbc = osc ptr. Reads note key at +12,   #
    #   interpolates against curve breakpoints at xbc+34..+37.           #
    #   Returns hl = interpolated note value.                            #
    # ------------------------------------------------------------------ #
    ('LABEL_02630C', 'Voice_InterpolateNoteCurve',
     'Piecewise-linear interpolation of key/note against curve table'),

    ('LABEL_02632E', 'Voice_InterpolateNoteCurve_LowRange',
     'Inner: interpolate note in lower range'),

    ('LABEL_026353', 'Voice_InterpolateNoteCurve_HighCheck',
     'Inner: check upper breakpoint for note curve'),

    ('LABEL_02636A', 'Voice_InterpolateNoteCurve_HighRange',
     'Inner: interpolate note in upper range'),

    ('LABEL_026393', 'Voice_InterpolateNoteCurve_Zero',
     'Inner: note in flat region -- return 0'),

    ('LABEL_026395', 'Voice_InterpolateNoteCurve_Done',
     'Inner: return note interpolated value'),

    # ------------------------------------------------------------------ #
    # 026396-026511  Voice_ComputePitch                                   #
    #   xwa = voice struct ptr. Full pitch computation: base tuning,     #
    #   SysEx tune, portamento, LFO, key-track, bend curves, algo flag.  #
    #   Writes pitch to voice struct +13 and clears porta-delta (+51).   #
    # ------------------------------------------------------------------ #
    ('LABEL_026396', 'Voice_ComputePitch',
     'Full pitch computation: SysEx/porta/LFO/bend, write to voice struct +13'),

    ('LABEL_0263BC', 'Voice_ComputePitch_CheckSysExTune',
     'Inner: check SysEx-tune mode for alternate pitch-table lookup'),

    ('LABEL_0263D3', 'Voice_ComputePitch_SysExTable',
     'Inner: use SysEx pitch table (0x11C96) for pitch lookup'),

    ('LABEL_0263EB', 'Voice_ComputePitch_CheckAltTune',
     'Inner: check alternate-tune bit for second table'),

    ('LABEL_02640C', 'Voice_ComputePitch_NormalTune',
     'Inner: normal tuning -- check portamento detune sign'),

    ('LABEL_026451', 'Voice_ComputePitch_PortaPositive',
     'Inner: portamento detune positive -- direct multiply'),

    ('LABEL_026476', 'Voice_ComputePitch_PortaScale',
     'Inner: scale portamento result, add base offset 0xD8'),

    ('LABEL_02647F', 'Voice_ComputePitch_ApplyLFO',
     'Inner: apply LFO and bend curve via LABEL_023279 and add results'),

    ('LABEL_026510', 'Voice_ComputePitch_WriteDone',
     'Inner: write final pitch to voice struct +13, clear +51, return'),

    # ------------------------------------------------------------------ #
    # 026522  (data: 9 bytes -- inline micro-code or branch table)        #
    # ------------------------------------------------------------------ #
    ('LABEL_026522', 'Voice_ComputePitch_InlineData',
     '9-byte inline data block (branch table or micro-sequence)'),

    # ------------------------------------------------------------------ #
    # 026533-026611  Voice_ComputePitch_Mono                              #
    #   Mono variant of Voice_ComputePitch: no stereo L/R split.        #
    # ------------------------------------------------------------------ #
    ('LABEL_026533', 'Voice_ComputePitch_Mono',
     'Mono pitch computation variant (single oscillator)'),

    ('LABEL_02655D', 'Voice_ComputePitch_Mono_SysExTable',
     'Inner (mono): SysEx pitch table path'),

    ('LABEL_026574', 'Voice_ComputePitch_Mono_CheckAltTune',
     'Inner (mono): check alternate tune bit'),

    ('LABEL_026593', 'Voice_ComputePitch_Mono_CheckPorta',
     'Inner (mono): check portamento sign'),

    ('LABEL_0265CD', 'Voice_ComputePitch_Mono_PortaPositive',
     'Inner (mono): portamento positive -- direct multiply'),

    ('LABEL_0265EA', 'Voice_ComputePitch_Mono_PortaScale',
     'Inner (mono): scale portamento and add offset'),

    ('LABEL_0265F1', 'Voice_ComputePitch_Mono_ApplyLFO',
     'Inner (mono): apply LFO, bend, SysEx tune, write pitch'),

    # ------------------------------------------------------------------ #
    # 026637-026656  Voice_ApplyPortamento                                #
    #   xwa = voice struct ptr. Reads de = current pitch, adjusts by    #
    #   portamento speed at osc-table +23, then calls LABEL_0232C7.      #
    # ------------------------------------------------------------------ #
    ('LABEL_026637', 'Voice_ApplyPortamento',
     'Adjust pitch with portamento speed (+23), call freq write helper'),

    ('LABEL_026653', 'Voice_ApplyPortamento_NoChanDetune',
     'Inner: no channel detune -- subtract fixed 0x200'),

    ('LABEL_026657', 'Voice_ApplyPortamento_ApplyDetune',
     'Inner: apply algo-tune detune and call LABEL_0232C7'),

    ('LABEL_02667B', 'Voice_ApplyPortamento_HighNote',
     'Inner: voice type > 1 -- subtract fixed 0x10'),

    ('LABEL_02667F', 'Voice_ApplyPortamento_Done',
     'Inner: branch to LABEL_0232C7 for final freq write'),

    # ------------------------------------------------------------------ #
    # 026684-0266D3  Voice_ApplyPortamento2                               #
    #   Variant that also reads osc-table LFO/vibrato offset (+5).      #
    # ------------------------------------------------------------------ #
    ('LABEL_026684', 'Voice_ApplyPortamento2',
     'Portamento variant 2: add vibrato LFO offset before freq write'),

    ('LABEL_02669D', 'Voice_ApplyPortamento2_NoChanDetune',
     'Inner (v2): no channel detune -- subtract 0x200'),

    ('LABEL_0266A1', 'Voice_ApplyPortamento2_ApplyDetune',
     'Inner (v2): apply LFO+vibrato detune'),

    ('LABEL_0266D1', 'Voice_ApplyPortamento2_AddVibrato',
     'Inner (v2): add vibrato offset to result'),

    ('LABEL_0266D3', 'Voice_ApplyPortamento2_Done',
     'Inner (v2): call LABEL_0232C7 for freq write'),

    # ------------------------------------------------------------------ #
    # 0266D8-026764  Voice_WriteChPitchWithVib                            #
    #   c = channel index; finds channel voice buffer, checks vibrato   #
    #   LFO flags, computes freq deviation, writes to 0x0451f8/fa.      #
    # ------------------------------------------------------------------ #
    ('LABEL_0266D8', 'Voice_WriteChPitchWithVib',
     'Write channel pitch freq to DSP 0x0451f8/fa with vibrato LFO'),

    ('LABEL_026737', 'Voice_WriteChPitchWithVib_Loop',
     'Inner: loop over voice-buffer slots checking channel match'),

    ('LABEL_02675E', 'Voice_WriteChPitchWithVib_NextSlot',
     'Inner: advance slot pointer and continue loop'),

    ('LABEL_026765', 'Voice_WriteChPitchWithVib_Done',
     'Inner: epilogue'),

    # ------------------------------------------------------------------ #
    # 026769-026848  Voice_ComputeAndWriteVolume1                         #
    #   xwa = voice struct ptr. Standard volume computation: reads       #
    #   osc-table volume, algo tuning limit, LFO depth. Calls           #
    #   LABEL_022BB8 (vibrato scale), writes 0x0451f8/fa.              #
    # ------------------------------------------------------------------ #
    ('LABEL_026769', 'Voice_ComputeAndWriteVolume1',
     'Volume 1: compute standard voice volume and write to 0x0451f8/fa'),

    ('LABEL_0267EE', 'Voice_ComputeAndWriteVolume1_ApplyLFO',
     'Inner: check LFO depth, apply amplitude LFO via LABEL_022BB8'),

    ('LABEL_02682F', 'Voice_ComputeAndWriteVolume1_WriteDSP',
     'Inner: write volume word with bit 7 set to 0x0451f8, plain to 0x0451fa'),

    # ------------------------------------------------------------------ #
    # 02684A-02685A  Voice_WritePan_Passthrough                           #
    #   xwa = voice struct ptr. Copies stored pan from +62/+64 direct   #
    #   to DSP 0x0451e6/e8. No computation.                             #
    # ------------------------------------------------------------------ #
    ('LABEL_02684A', 'Voice_WritePan_Passthrough',
     'Copy stored pan words from voice struct +62/+64 to 0x0451e6/e8'),

    # ------------------------------------------------------------------ #
    # 02685B-02686E  Voice_WriteVolume_SetFlag                            #
    #   xwa = voice struct ptr. Reads volume from +64, sets bit 7,     #
    #   writes to 0x0451f8; writes plain word to 0x0451fa.             #
    # ------------------------------------------------------------------ #
    ('LABEL_02685B', 'Voice_WriteVolume_SetFlag',
     'Write volume from +64 to 0x0451f8 (bit 7 set) and 0x0451fa (plain)'),

    # ------------------------------------------------------------------ #
    # 02686F-026974  Voice_ComputeVolume_CappedLFO                        #
    #   xwa = voice struct ptr. Reads algo-max volume, compares with    #
    #   LFO limit, applies volume LFO via LABEL_022BB8. Writes          #
    #   0x0451f8/fa (bit 7 set flag on f8).                            #
    # ------------------------------------------------------------------ #
    ('LABEL_02686F', 'Voice_ComputeVolume_CappedLFO',
     'Volume with soft-limited LFO: cap at algo max, write 0x0451f8/fa'),

    ('LABEL_0268E3', 'Voice_ComputeVolume_CappedLFO_UseOscMax',
     'Inner: bit 0 of algo flags clear -- use osc-table volume max'),

    ('LABEL_026919', 'Voice_ComputeVolume_CappedLFO_ApplyLFO',
     'Inner: apply amplitude LFO, write final volume words'),

    ('LABEL_02695A', 'Voice_ComputeVolume_CappedLFO_WriteDSP',
     'Inner: write capped volume to 0x0451f8/fa and return'),

    # ------------------------------------------------------------------ #
    # 026975-026A49  Voice_ComputeAndWriteVolume2                         #
    #   Volume 2: reads channel pan-gain at osc-table +15, applies LFO  #
    #   and key-track correction. Writes 0x0451fc/fe.                  #
    # ------------------------------------------------------------------ #
    ('LABEL_026975', 'Voice_ComputeAndWriteVolume2',
     'Volume 2: compute aftertouch/mod-wheel volume, write 0x0451fc/fe'),

    ('LABEL_0269CE', 'Voice_ComputeAndWriteVolume2_ApplyLFO',
     'Inner: check LFO depth, apply amplitude LFO'),

    ('LABEL_026A2E', 'Voice_ComputeAndWriteVolume2_NoKeyTrack',
     'Inner: no key-track term -- clamp volume directly'),

    ('LABEL_026A3C', 'Voice_ComputeAndWriteVolume2_NoLFO',
     'Inner: no LFO depth -- apply only key-track offset'),

    ('LABEL_026A6E', 'Voice_ComputeAndWriteVolume2_WriteDSP',
     'Inner: write volume word to 0x0451fc/fe and return'),

    ('LABEL_026A88', 'Voice_ComputeAndWriteVolume2_PositiveDetune',
     'Inner: positive detune -- pass through LABEL_022B68'),

    ('LABEL_026A93', 'Voice_ComputeAndWriteVolume2_WriteResult',
     'Inner: assemble and write 0x0451fc/fe'),

    # ------------------------------------------------------------------ #
    # 026AAA-026BD3  Voice_ComputeAndWriteVolume3                         #
    #   Volume 3: reads LFO byte at osc-table +69, applies algo-max    #
    #   cap and LFO amplitude. Writes 0x045200/02.                     #
    # ------------------------------------------------------------------ #
    ('LABEL_026AAA', 'Voice_ComputeAndWriteVolume3',
     'Volume 3: secondary aftertouch/LFO volume, write 0x045200/02'),

    ('LABEL_026B03', 'Voice_ComputeAndWriteVolume3_ApplyLFO',
     'Inner: check LFO depth, apply amplitude LFO and key-track'),

    ('LABEL_026B63', 'Voice_ComputeAndWriteVolume3_NoKeyTrack',
     'Inner: no key-track -- clamp volume only'),

    ('LABEL_026B71', 'Voice_ComputeAndWriteVolume3_NoLFO',
     'Inner: no LFO depth -- apply key-track only'),

    ('LABEL_026BA3', 'Voice_ComputeAndWriteVolume3_WriteDSP',
     'Inner: combine detune and write 0x045200/02'),

    # ------------------------------------------------------------------ #
    # 026BDC-026C15  Voice_WriteVolume_Muted                              #
    #   xwa = voice struct ptr. Zeros all volume DSP regs, then writes  #
    #   the secondary volume word from +70.                             #
    # ------------------------------------------------------------------ #
    ('LABEL_026BDC', 'Voice_WriteVolume_Muted',
     'Zero all DSP volume registers and write secondary volume from +70'),

    # ------------------------------------------------------------------ #
    # 026C16-026C51  Voice_WriteVolume_OrPan                              #
    #   xwa = voice struct ptr. Reads osc pointer from +19 and pan      #
    #   pointer from +23 via indirect chain. Reads pan-gain byte and    #
    #   writes volume to 0x0451f8/fa with/without mute flag.           #
    # ------------------------------------------------------------------ #
    ('LABEL_026C16', 'Voice_WriteVolume_OrPan',
     'Write volume to 0x0451f8/fa using pan-gain from osc struct +13'),

    ('LABEL_026C43', 'Voice_WriteVolume_OrPan_Muted',
     'Inner: osc not active -- write muted default 0x0451f8=0x0080, fa=0'),

    # ------------------------------------------------------------------ #
    # 026C52-026CAD  Voice_AdvanceLFOPhase                                #
    #   xwa = voice DSP slot struct. Reads mode bits 0x1C. Modes:       #
    #   0x08=incrementing triangle, 0x10=decrement+reset, else=idle.   #
    #   Returns hl = LFO level (0..0x100 range).                       #
    # ------------------------------------------------------------------ #
    ('LABEL_026C52', 'Voice_AdvanceLFOPhase',
     'Advance LFO oscillator phase and return level (0..0x100)'),

    ('LABEL_026C75', 'Voice_AdvanceLFOPhase_IncDone',
     'Inner: increment path done -- return 0'),

    ('LABEL_026C79', 'Voice_AdvanceLFOPhase_Triangle',
     'Inner: triangle mode (0x08) -- increment, compute ratio 0..0x100'),

    ('LABEL_026C9E', 'Voice_AdvanceLFOPhase_TriangleReset',
     'Inner: triangle peak reached -- reset to 0 and return 0x100'),

    ('LABEL_026CAB', 'Voice_AdvanceLFOPhase_Idle',
     'Inner: no active mode -- return 0'),

    ('LABEL_026CAD', 'Voice_AdvanceLFOPhase_Done',
     'Inner: return from Voice_AdvanceLFOPhase'),

    # ------------------------------------------------------------------ #
    # 026CAE-026E58  Voice_UpdateAllLFO                                   #
    #   Iterates voice slots 0..0x7F and 0..0x3F, ticks LFO phases,    #
    #   calls LABEL_022E2A (scale), then dispatches to the appropriate  #
    #   voice-update routine (LABEL_02DA96 / LABEL_02DCD0 / 02DE69).   #
    # ------------------------------------------------------------------ #
    ('LABEL_026CAE', 'Voice_UpdateAllLFO',
     'Iterate all voice slots, tick LFO phase, dispatch freq/vol update'),

    ('LABEL_026CB7', 'Voice_UpdateAllLFO_Loop1',
     'Inner: main loop for voice slots 0..0x7F'),

    ('LABEL_026D1A', 'Voice_UpdateAllLFO_DispatchVoice1',
     'Inner: dispatch voice-group-1 update after LFO'),

    ('LABEL_026D25', 'Voice_UpdateAllLFO_NextSlot1',
     'Inner: increment slot index for group 1'),

    ('LABEL_026D2D', 'Voice_UpdateAllLFO_Loop2',
     'Inner: secondary loop for voice slots 0..0x3F (group 2)'),

    ('LABEL_026D35', 'Voice_UpdateAllLFO_Loop2_Body',
     'Inner: body of group-2 LFO update loop'),

    ('LABEL_026D9A', 'Voice_UpdateAllLFO_DispatchVoice2',
     'Inner: dispatch voice-group-2 update after LFO'),

    ('LABEL_026DA5', 'Voice_UpdateAllLFO_NextSlot2',
     'Inner: increment slot index for group 2'),

    ('LABEL_026DAD', 'Voice_UpdateAllLFO_Loop3',
     'Inner: tertiary loop for voice slots 0..0x7F (group 3)'),

    ('LABEL_026DB6', 'Voice_UpdateAllLFO_Loop3_Body',
     'Inner: body of group-3 LFO update loop'),

    ('LABEL_026E1E', 'Voice_UpdateAllLFO_DispatchGroup3_High',
     'Inner: high-slot dispatch path for group 3'),

    ('LABEL_026E45', 'Voice_UpdateAllLFO_DispatchVoice3',
     'Inner: dispatch voice-group-3 update after LFO'),

    ('LABEL_026E50', 'Voice_UpdateAllLFO_NextSlot3',
     'Inner: increment slot index for group 3'),

    ('LABEL_026E59', 'Voice_UpdateAllLFO_Done',
     'Inner: epilogue of Voice_UpdateAllLFO'),

    # ------------------------------------------------------------------ #
    # 026E5B-026EC2  Voice_UpdateNoteOff                                  #
    #   xwa = voice struct ptr. Reads/writes note-off counter at +47.  #
    #   Decrements counter, triggers note-off at zero via calls to      #
    #   LABEL_02D41B (kill voice) and LABEL_022587 (release).          #
    # ------------------------------------------------------------------ #
    ('LABEL_026E5B', 'Voice_UpdateNoteOff',
     'Decrement note-off counter, trigger kill/release when zero'),

    ('LABEL_026E9B', 'Voice_UpdateNoteOff_CheckRelease',
     'Inner: check release flag (bit 7) and decrement'),

    ('LABEL_026EB9', 'Voice_UpdateNoteOff_StoreDone',
     'Inner: store updated counter and return'),

    # ------------------------------------------------------------------ #
    # 026EC3-0271B8  Voice_UpdatePortamento                               #
    #   xwa = voice struct ptr. Reads portamento state in +49, checks  #
    #   direction bits, writes DSP freq registers. Handles 3 ramp modes:#
    #     0x4000 = ascend with floor, 0x2000 = descend with floor,     #
    #     0x1000 = full release ramp. Also handles zero-state silence. #
    # ------------------------------------------------------------------ #
    ('LABEL_026EC3', 'Voice_UpdatePortamento',
     'Portamento step machine: advance pitch ramp and write DSP freq'),

    ('LABEL_026F1E', 'Voice_UpdatePortamento_ModeCheck2',
     'Inner: check second algo type for portamento dispatch'),

    ('LABEL_026F4A', 'Voice_UpdatePortamento_ModeDefault',
     'Inner: default mode -- use voice-group pan word for porta freq'),

    ('LABEL_026F78', 'Voice_UpdatePortamento_ZeroState',
     'Inner: portamento state is zero -- write freq and exit'),

    ('LABEL_026F89', 'Voice_UpdatePortamento_DispatchMode',
     'Inner: dispatch on mode bits 14:12 (0x1000/0x2000/0x4000)'),

    ('LABEL_026FDD', 'Voice_UpdatePortamento_Ascend_Tick',
     'Inner: ascending ramp tick -- write DSP channel select + freq word'),

    ('LABEL_026FFD', 'Voice_UpdatePortamento_Ascend_Tick2',
     'Inner: ascending ramp second DSP write (800/ff80)'),

    ('LABEL_027020', 'Voice_UpdatePortamento_Ascend_ClampFloor',
     'Inner: ascending ramp -- clamp iz to floor value at +58'),

    ('LABEL_027037', 'Voice_UpdatePortamento_Ascend_WritePitch',
     'Inner: ascending ramp -- store iz to +51, update via LABEL_026637'),

    ('LABEL_027059', 'Voice_UpdatePortamento_Descend_Tick',
     'Inner: descending ramp tick -- write DSP channel select + freq word'),

    ('LABEL_027079', 'Voice_UpdatePortamento_Descend_Tick2',
     'Inner: descending ramp second DSP write'),

    ('LABEL_02709C', 'Voice_UpdatePortamento_Descend_WritePitch',
     'Inner: descending ramp -- call LABEL_02D73F and store'),

    ('LABEL_0270B0', 'Voice_UpdatePortamento_Release_Start',
     'Inner: release ramp -- check floor at +56, begin countdown'),

    ('LABEL_0270E8', 'Voice_UpdatePortamento_Release_Tick',
     'Inner: release ramp tick -- write DSP channel select + freq'),

    ('LABEL_027108', 'Voice_UpdatePortamento_Release_Tick2',
     'Inner: release ramp second DSP write'),

    ('LABEL_02712B', 'Voice_UpdatePortamento_Release_WritePitch',
     'Inner: release ramp -- store iz to +51, dispatch LABEL_02D68F'),

    ('LABEL_02714F', 'Voice_UpdatePortamento_NullMode',
     'Inner: mode bits zero -- zero portamento state and return'),

    ('LABEL_027156', 'Voice_UpdatePortamento_ActiveCount',
     'Inner: portamento state byte non-zero -- decrement counter'),

    ('LABEL_027181', 'Voice_UpdatePortamento_CountTick',
     'Inner: active count tick -- write DSP channel select + freq'),

    ('LABEL_0271A4', 'Voice_UpdatePortamento_CountTick2',
     'Inner: count tick second DSP write, then decrement'),

    ('LABEL_0271AC', 'Voice_UpdatePortamento_CountDecrement',
     'Inner: decrement portamento counter byte'),

    ('LABEL_0271AF', 'Voice_UpdatePortamento_StoreDone',
     'Inner: store updated portamento word +49 and return'),

    # ------------------------------------------------------------------ #
    # 0271BC-0271FE  Voice_ApplyTuningSysEx                               #
    #   Checks tune flags in 0x041343 (bits 11-12). Increments counter  #
    #   0x04135C, updates note-tuning register 0x04135A.               #
    # ------------------------------------------------------------------ #
    ('LABEL_0271BC', 'Voice_ApplyTuningSysEx',
     'Apply SysEx fine-tuning flags (bits 11-12 of 0x041343)'),

    ('LABEL_0271E8', 'Voice_ApplyTuningSysEx_Bit12',
     'Inner: bit 12 set -- increment counter, clear flag'),

    ('LABEL_0271FF', 'Voice_ApplyTuningSysEx_Bit13Check',
     'Inner: check bits 13-15 for extended tuning mode'),

    ('LABEL_02723B', 'Voice_ApplyTuningSysEx_Bit14Clear',
     'Inner: bit 14 clear path -- use bit 15 for direction'),

    ('LABEL_02726E', 'Voice_ApplyTuningSysEx_ZeroPitch',
     'Inner: neither bit -- zero tuning pitch'),

    ('LABEL_02727C', 'Voice_ApplyTuningSysEx_CheckCounter',
     'Inner: check counter 0x04135C for wrap, update flags'),

    ('LABEL_02729B', 'Voice_ApplyTuningSysEx_ClearMode',
     'Inner: bits 13..15 all clear -- clear mode flag and return'),

    # ------------------------------------------------------------------ #
    # 0272A3-027362  Voice_InitVoiceState                                  #
    #   xwa = voice index. Zeros all 0x0451xx DSP state registers for  #
    #   one voice channel: pan, volume, freq, expression etc.           #
    # ------------------------------------------------------------------ #
    ('LABEL_0272A3', 'Voice_InitVoiceState',
     'Initialise per-voice DSP state registers to safe defaults'),

    # ------------------------------------------------------------------ #
    # 027363-027337  Voice_TickNoteDecay                                  #
    #   Uses a push/pop register backup. Reads decay counter 0x04135E/ #
    #   5F. On countdown zero calls LABEL_02D00D (reload), initialises  #
    #   voice state and fires note-event via LABEL_02D41B.             #
    # ------------------------------------------------------------------ #
    ('LABEL_027363', 'Voice_TickNoteDecay',
     'Decrement note-decay counter; on zero reload and dispatch note event'),

    ('LABEL_0273C6', 'Voice_TickNoteDecay_Reload',
     'Inner: reload decay table when counter reaches zero'),

    ('LABEL_0273D1', 'Voice_TickNoteDecay_Done',
     'Inner: restore registers and return'),

    # ------------------------------------------------------------------ #
    # 0273D8-027495  Voice_LoadPitchTable_Ch                              #
    #   a = part/channel, c = table index. Looks up pitch table entry  #
    #   at 0x04135C, compares against 0x0D limit, clamps to min 0x2C.  #
    #   Writes 0x045208/0413c5.                                        #
    # ------------------------------------------------------------------ #
    ('LABEL_0273D8', 'Voice_LoadPitchTable_Ch',
     'Load per-channel pitch table entry into 0x045208 and algo table'),

    ('LABEL_027424', 'Voice_LoadPitchTable_Ch_NoClamp',
     'Inner: value >= 0x2C -- store without clamping'),

    ('LABEL_02743E', 'Voice_LoadPitchTable_Ch_ScanLoop',
     'Inner: iterate pitch table entries via LABEL_0337D2'),

    ('LABEL_027496', 'Voice_LoadPitchTable_Ch_LoopBody',
     'Inner: loop body -- dispatch each pitch table word via LABEL_02DA16'),

    ('LABEL_0274AE', 'Voice_LoadPitchTable_Ch_LoopCheck',
     'Inner: loop check -- continue if high byte < 0x80'),

    # ------------------------------------------------------------------ #
    # 0274C7-027533  Voice_LoadPitchTable_All                             #
    #   Wrapper that loads pitch table for all channels simultaneously. #
    # ------------------------------------------------------------------ #
    ('LABEL_0274C7', 'Voice_LoadPitchTable_All',
     'Load pitch table for all channels (no explicit table index)'),

    ('LABEL_027503', 'Voice_LoadPitchTable_All_LoopBody',
     'Inner: dispatch each pitch-table word via LABEL_02DA16 in all-channel loop'),

    ('LABEL_02751C', 'Voice_LoadPitchTable_All_LoopCheck',
     'Inner: continue all-channel pitch loop if high byte < 0x80'),

    # ------------------------------------------------------------------ #
    # 027534-027621  Voice_LoadFilterTable_Ch                             #
    #   a = part, c = table index. Reads LPF table entries from        #
    #   LABEL_0337D2, writes 0x04520a (LPF base) and 0x04520e (LPF   #
    #   cutoff). Iterates via LABEL_0337D2 scan.                      #
    # ------------------------------------------------------------------ #
    ('LABEL_027534', 'Voice_LoadFilterTable_Ch',
     'Load per-channel LPF/filter table entry into 0x04520a/e'),

    ('LABEL_027580', 'Voice_LoadFilterTable_Ch_NoClamp',
     'Inner: filter value >= 0x1C -- store without clamping'),

    ('LABEL_02759A', 'Voice_LoadFilterTable_Ch_ScanFilter',
     'Inner: scan secondary filter table via LABEL_0337D2'),

    ('LABEL_0275F2', 'Voice_LoadFilterTable_Ch_LoopBody',
     'Inner: dispatch each filter word via LABEL_02DB33'),

    ('LABEL_02760A', 'Voice_LoadFilterTable_Ch_LoopCheck',
     'Inner: continue loop if high byte < 0x80'),

    # ------------------------------------------------------------------ #
    # 027623-027689  Voice_LoadFilterTable_All                            #
    #   Wrapper that loads filter table for all channels.              #
    # ------------------------------------------------------------------ #
    ('LABEL_027623', 'Voice_LoadFilterTable_All',
     'Load filter table for all channels'),

    ('LABEL_02765F', 'Voice_LoadFilterTable_All_LoopBody',
     'Inner: dispatch each filter word in all-channel loop'),

    ('LABEL_027678', 'Voice_LoadFilterTable_All_LoopCheck',
     'Inner: continue all-channel filter loop if high byte < 0x80'),

    # ------------------------------------------------------------------ #
    # 027690-02773C  Voice_LoadToneTable_Ch                               #
    #   a = part, c = table index. Reads DCF (dynamic filter) table    #
    #   entry via LABEL_033C6B, writes 0x045206 and iterates via       #
    #   LABEL_02DCF2 for secondary DSP dispatch.                       #
    # ------------------------------------------------------------------ #
    ('LABEL_027690', 'Voice_LoadToneTable_Ch',
     'Load per-channel tone/DCF table entry and write to 0x045206'),

    ('LABEL_0276DA', 'Voice_LoadToneTable_Ch_NoClamp',
     'Inner: DCF value >= 0x1C -- store without clamping'),

    ('LABEL_0276F4', 'Voice_LoadToneTable_Ch_ScanLoop',
     'Inner: iterate DCF table entries via LABEL_021A8E'),

    ('LABEL_02770B', 'Voice_LoadToneTable_Ch_LoopBody',
     'Inner: dispatch each DCF word via LABEL_02DCF2'),

    ('LABEL_027724', 'Voice_LoadToneTable_Ch_LoopCheck',
     'Inner: continue loop if high byte < 0x40'),

    # ------------------------------------------------------------------ #
    # 02773D-02783C  Voice_LoadToneTable_All                              #
    #   Wrapper that loads DCF table for all channels.                 #
    # ------------------------------------------------------------------ #
    ('LABEL_02773D', 'Voice_LoadToneTable_All',
     'Load DCF/tone table for all channels'),

    ('LABEL_027767', 'Voice_LoadToneTable_All_LoopBody',
     'Inner: dispatch each DCF word in all-channel loop'),

    ('LABEL_027780', 'Voice_LoadToneTable_All_LoopCheck',
     'Inner: continue all-channel DCF loop if high byte < 0x40'),

    # ------------------------------------------------------------------ #
    # 027798-027838  Voice_ToneTableRamp_Up                               #
    #   a = part, xbc = voice struct ptr. Increments tone-table index  #
    #   at +100 up to 0x4F limit (sets bit 3 flag), then calls        #
    #   Voice_LoadPitchTable_Ch and Voice_LoadFilterTable_All.         #
    # ------------------------------------------------------------------ #
    ('LABEL_027798', 'Voice_ToneTableRamp_Up',
     'Increment tone-table index and call pitch+filter table loaders'),

    ('LABEL_0277B3', 'Voice_ToneTableRamp_Up_Increment',
     'Inner: below limit -- increment index and call table loaders'),

    ('LABEL_0277DA', 'Voice_ToneTableRamp_Up_CheckFilter',
     'Inner: check filter-ramp counter at +101 against 0x96 limit'),

    ('LABEL_0277F2', 'Voice_ToneTableRamp_Up_FilterIncrement',
     'Inner: filter counter below limit -- increment, call filter loaders'),

    ('LABEL_027839', 'Voice_ToneTableRamp_Up_Done',
     'Inner: epilogue of Voice_ToneTableRamp_Up'),

    # ------------------------------------------------------------------ #
    # 02783D-0278C6  Voice_ToneTableRamp_Down                             #
    #   a = part, xbc = voice struct ptr. Decrements tone-table index  #
    #   at +100 to zero (sets bit 4 flag), then calls table loaders.   #
    # ------------------------------------------------------------------ #
    ('LABEL_02783D', 'Voice_ToneTableRamp_Down',
     'Decrement tone-table index and call pitch+filter table loaders'),

    ('LABEL_027850', 'Voice_ToneTableRamp_Down_Decrement',
     'Inner: above zero -- decrement index and call table loaders'),

    ('LABEL_02787A', 'Voice_ToneTableRamp_Down_CheckFilter',
     'Inner: check filter-ramp counter at +101 for decrement'),

    ('LABEL_0278C7', 'Voice_ToneTableRamp_Down_Done',
     'Inner: epilogue of Voice_ToneTableRamp_Down'),

    # ------------------------------------------------------------------ #
    # 0278CB-027986  Voice_ToneTableApply_Pitch                           #
    #   a = part, xbc = voice struct ptr. Walks pitch-table entries    #
    #   using loop, finds matching index from +100, calls loaders.     #
    # ------------------------------------------------------------------ #
    ('LABEL_0278CB', 'Voice_ToneTableApply_Pitch',
     'Apply pitch table transition: scan entries, match index, call loaders'),

    ('LABEL_0278F5', 'Voice_ToneTableApply_Pitch_Decrement',
     'Inner: decrement byte-pointer register'),

    ('LABEL_0278F8', 'Voice_ToneTableApply_Pitch_Loop',
     'Inner: loop comparing table pointer against target index'),

    # ------------------------------------------------------------------ #
    # 027987-027A45  Voice_ToneTableApply_Filter                          #
    #   Variant of Voice_ToneTableApply_Pitch for filter-table index.  #
    # ------------------------------------------------------------------ #
    ('LABEL_027987', 'Voice_ToneTableApply_Filter',
     'Apply filter table transition: scan entries, match index, call loaders'),

    ('LABEL_0279B3', 'Voice_ToneTableApply_Filter_Increment',
     'Inner: increment byte-pointer register'),

    ('LABEL_0279B6', 'Voice_ToneTableApply_Filter_Loop',
     'Inner: loop comparing filter pointer against target'),

    # ------------------------------------------------------------------ #
    # 027A46-027ABF  Voice_ScanAndCancelNoteOff                           #
    #   Iterates all active voice-buffer slots. If a slot has           #
    #   portamento-cancel flags set, calls Voice_UpdateNoteOff or      #
    #   cancels the note-off by clearing flags.                        #
    # ------------------------------------------------------------------ #
    ('LABEL_027A46', 'Voice_ScanAndCancelNoteOff',
     'Scan all voice slots; cancel queued note-off if portamento active'),

    ('LABEL_027A5B', 'Voice_ScanAndCancelNoteOff_Loop',
     'Inner: per-slot loop body -- check portamento flags'),

    ('LABEL_027A91', 'Voice_ScanAndCancelNoteOff_ClearSlot',
     'Inner: portamento inactive -- clear note-off flags'),

    ('LABEL_027AB3', 'Voice_ScanAndCancelNoteOff_NextSlot',
     'Inner: advance to next slot in scan'),

    ('LABEL_027AC0', 'Voice_ScanAndCancelNoteOff_Done',
     'Inner: epilogue'),

    # ------------------------------------------------------------------ #
    # 027AC4-027CBA  Voice_UpdateAllNoteStates                            #
    #   Main per-tick note-state machine. Calls Voice_TickNoteDecay,   #
    #   Voice_ApplyTuningSysEx. Then iterates all active voice-buffer  #
    #   slots checking portamento state bits and dispatching          #
    #   Voice_UpdateNoteOff / Voice_UpdatePortamento per slot.         #
    # ------------------------------------------------------------------ #
    ('LABEL_027AC4', 'Voice_UpdateAllNoteStates',
     'Per-tick note-state machine: decay, SysEx tune, porta, note-off'),

    ('LABEL_027AE8', 'Voice_UpdateAllNoteStates_LoopA',
     'Inner: loop A body -- check bit 10 for voiced update'),

    ('LABEL_027B1A', 'Voice_UpdateAllNoteStates_CheckPortaA',
     'Inner: check portamento flags for path A'),

    ('LABEL_027B3B', 'Voice_UpdateAllNoteStates_CheckPortamento2A',
     'Inner: portamento inactive path A -- check secondary porta'),

    ('LABEL_027B4C', 'Voice_UpdateAllNoteStates_ClearNoteOffA',
     'Inner: clear note-off flags when portamento done'),

    ('LABEL_027B70', 'Voice_UpdateAllNoteStates_ClearPorta2A',
     'Inner: clear secondary portamento flags'),

    ('LABEL_027B8F', 'Voice_UpdateAllNoteStates_NextSlotA',
     'Inner: advance to next slot in loop A'),

    ('LABEL_027BA0', 'Voice_UpdateAllNoteStates_LoopB_Start',
     'Inner: loop B start -- bit 10 clear, iterate all slots'),

    ('LABEL_027BB0', 'Voice_UpdateAllNoteStates_LoopB',
     'Inner: loop B body'),

    ('LABEL_027BE6', 'Voice_UpdateAllNoteStates_CheckPortamento2B',
     'Inner: portamento inactive path B -- check secondary'),

    ('LABEL_027BF7', 'Voice_UpdateAllNoteStates_ClearNoteOffB',
     'Inner: clear note-off flags path B'),

    ('LABEL_027C1B', 'Voice_UpdateAllNoteStates_ClearPorta2B',
     'Inner: clear secondary portamento flags path B'),

    ('LABEL_027C3A', 'Voice_UpdateAllNoteStates_NextSlotB',
     'Inner: advance to next slot in loop B'),

    ('LABEL_027C48', 'Voice_UpdateAllNoteStates_ScanLFO',
     'Inner: iterate LFO voice array (0..0x1A) after main loops'),

    ('LABEL_027C51', 'Voice_UpdateAllNoteStates_LFOLoopBody',
     'Inner: per-LFO-slot dispatch (ramp up/down, apply, init)'),

    ('LABEL_027C85', 'Voice_UpdateAllNoteStates_LFO_ApplyFilter',
     'Inner: LFO slot -- apply filter table transformation'),

    ('LABEL_027C92', 'Voice_UpdateAllNoteStates_LFO_CheckRampDown',
     'Inner: LFO slot -- check ramp-down flag'),

    ('LABEL_027CA6', 'Voice_UpdateAllNoteStates_LFO_RampDown',
     'Inner: LFO slot -- call tone-table ramp-down'),

    ('LABEL_027CB1', 'Voice_UpdateAllNoteStates_LFONextSlot',
     'Inner: advance LFO slot pointer'),

    ('LABEL_027CBA', 'Voice_UpdateAllNoteStates_Done',
     'Inner: epilogue of Voice_UpdateAllNoteStates'),

    # ------------------------------------------------------------------ #
    # 027CBE-027CC3  Voice_SetLFO_ActiveFlag                              #
    #   a = voice index. Sets bit 5 of word at voice state table entry. #
    # ------------------------------------------------------------------ #
    ('LABEL_027CBE', 'Voice_SetLFO_ActiveFlag',
     'Set bit 5 (LFO active) in voice state word at 0x04136a'),

    # ------------------------------------------------------------------ #
    # 027CD1-027CE3  Voice_ClearLFO_ActiveFlag                            #
    #   a = voice index. Clears bit 5 of the voice state word.         #
    # ------------------------------------------------------------------ #
    ('LABEL_027CD1', 'Voice_ClearLFO_ActiveFlag',
     'Clear bit 5 (LFO active) in voice state word at 0x04136a'),

    # ------------------------------------------------------------------ #
    # 027CE4  data block (inline DSP micro-code or LUT)                   #
    # ------------------------------------------------------------------ #
    ('LABEL_027CE4', 'Voice_DSP_InlineData',
     'Inline DSP micro-sequence or LUT data block (~380 bytes)'),

    # ------------------------------------------------------------------ #
    # 027F74-027F95  DSP_WriteVoiceParam_Long                             #
    #   wa = voice channel, xbc = DSP slot ptr. Writes voice param    #
    #   to DSP via addresses 0x100000 (+0x400 chan select) and         #
    #   0x100002 (param word from xbc+14). Surrounds write with       #
    #   res/set of bit 7 of CPU port 0x18.                            #
    # ------------------------------------------------------------------ #
    ('LABEL_027F74', 'DSP_WriteVoiceParam_Long',
     'Write voice param to DSP hardware: addr 0x100000+0x400, word from xbc+14'),

    ('LABEL_027F91', 'DSP_WriteVoiceParam_Long_NopGap',
     'Inner: 3-cycle NOP gap after DSP write sequence'),

    # ------------------------------------------------------------------ #
    # 027F96-027FB5  DSP_WriteVoiceParam_Short                            #
    #   wa = voice channel, xbc = DSP slot ptr. Writes voice param    #
    #   to DSP at 0x100000 (+0x080) and 0x100002 (word from xbc+4,   #
    #   bit 15 cleared).                                               #
    # ------------------------------------------------------------------ #
    ('LABEL_027F96', 'DSP_WriteVoiceParam_Short',
     'Write voice param to DSP: addr 0x100000+0x080, word from xbc+4'),

    ('LABEL_027FB6', 'DSP_WriteVoiceParam_Short_NopGap',
     'Inner: NOP gap after short DSP write'),

    # ------------------------------------------------------------------ #
    # 027FBB-027FD5  DSP_WriteVoiceParam_Direct                           #
    #   wa = DSP command word, bc = iz (DSP slot index). Writes wa    #
    #   directly to 0x100000 and iz to 0x100002 with bit-port guard.  #
    # ------------------------------------------------------------------ #
    ('LABEL_027FBB', 'DSP_WriteVoiceParam_Direct',
     'Write voice param directly to DSP: 0x100000=wa, 0x100002=iz'),

    ('LABEL_027FD1', 'DSP_WriteVoiceParam_Direct_NopGap',
     'Inner: NOP gap after direct DSP write'),

    # ------------------------------------------------------------------ #
    # 027FD6-0280A6  DSP_WriteVoiceParam_6Words                           #
    #   wa = voice index, xbc = voice struct ptr. Writes 6 consecutive #
    #   voice param words to DSP at offsets +840,+800,+940,+900,+9C0  #
    #   and +A00 from voice channel address 0x100000. Each pair uses   #
    #   res/set bit-port guard and a 3-NOP gap.                       #
    # ------------------------------------------------------------------ #
    ('LABEL_027FD6', 'DSP_WriteVoiceParam_6Words',
     'Write 6 voice param words to DSP with consecutive channel offsets'),

    ('LABEL_027FFD', 'DSP_WriteVoiceParam_6Words_Word2',
     'Inner: second word write (+940/+950 offset pair)'),
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

    # Check maincpu for cross-references (none expected but be safe)
    maincpu_src = os.path.join(base, 'maincpu', 'kn5000_v10_program.s')
    with open(maincpu_src, 'rb') as f:
        maincpu_content = f.read().decode('latin-1')

    maincpu_renames = 0
    for old_label, new_label, _ in RENAMES:
        if old_label in maincpu_content:
            maincpu_content = re.sub(r'\b' + re.escape(old_label) + r'\b', new_label, maincpu_content)
            maincpu_renames += 1
            print(f'  (maincpu) {old_label} -> {new_label}')

    with open(src, 'wb') as f:
        f.write(content.encode('latin-1'))

    if maincpu_renames > 0:
        with open(maincpu_src, 'wb') as f:
            f.write(maincpu_content.encode('latin-1'))

    print(f'\nRenamed {renamed} labels in subcpu ({maincpu_renames} cross-refs in maincpu)')


if __name__ == '__main__':
    main()
