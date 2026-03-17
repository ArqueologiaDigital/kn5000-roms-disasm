#!/usr/bin/env python3
"""Rename LABEL_* to semantic names in kn5000_v10_program.s (misc medium functions).

Covers 4 function groups across ~600 labels:
  1. VRAM Palette/Sprite rendering  (FAF316-FAFB48)  Palette bank rotation, clipped
     sprite rendering with color-mode dispatch, deferred rendering wrappers
  2. DrumVoice inline stubs         (F652A1-F669D3)  Drum voice dispatch table,
     tempo/beat counter manipulation, time-signature display strings
  3. SMF/MIDI file playback          (F28238-F29E48)  Standard MIDI File parsing,
     channel assignment, slot configuration, song bank I/O
  4. Accompaniment sequence engine   (F6E00B-F6EFEB)  Auto-accompaniment sequence
     processing, song-part MIDI event generation, fade-out, pedal handling

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
#
# Naming conventions (matches existing scripts):
#   - Function entry points: FunctionName or FunctionName_Impl
#   - Branch labels within a function: FunctionName_Description
#   - Data blocks: FunctionName_Table / _ParamBlock
#   - Shared helpers: HelperName
# ---------------------------------------------------------------------------

RENAMES = [

    # ======================================================================
    # 1. VRAM Palette/Sprite rendering (FAF316 - FAFB48)
    #    Palette bank rotation fade, clipped sprite/bitmap rendering with
    #    multiple color-combination modes, deferred callback wrappers.
    #    All render to OFFSCREEN_BUFFER_1 (0x43C00, 320x240 8bpp).
    # ======================================================================

    # --- FAF316: UI render loop iteration (called in a loop) ---
    ('LABEL_FAF316', 'UIRender_IterateCallbacks',
     'Loop body: dispatch each pending UI render callback from table'),

    # --- FAF344-FAF345: trivial ret stubs ---
    ('LABEL_FAF344', 'UIRender_RetStub1',
     'Trivial ret (no-op callback)'),

    ('LABEL_FAF345', 'UIRender_RetStub2',
     'Trivial ret (no-op callback)'),

    # --- FAF346-FAF3E0: Palette bank rotation (documented in source) ---
    ('LABEL_FAF346', 'PaletteBankRotate',
     'Palette bank rotation fade effect entry; deferred if not in render context'),

    ('LABEL_FAF360', 'PaletteBankRotate_Impl',
     'Palette bank rotation: save buffers, rotate pixel indices, write back'),

    ('LABEL_FAF396', 'PaletteBankRotate_RowLoop',
     'Outer loop: iterate rows DE=0..0xEF'),

    ('LABEL_FAF398', 'PaletteBankRotate_ColLoop',
     'Inner loop: iterate columns HL=0..0x13F'),

    ('LABEL_FAF3A2', 'PaletteBankRotate_LowBank',
     'Pixel < 0xE0: add 0x10 to shift to next higher palette bank'),

    ('LABEL_FAF3A5', 'PaletteBankRotate_NextCol',
     'Advance to next column'),

    # --- FAF3E0-FAF41A: Clipped blit wrapper pair 1 (mode 0: replace) ---
    ('LABEL_FAF3E0', 'ClipBlit_Replace',
     'Clipped blit wrapper 1: check render context, dispatch or defer'),

    ('LABEL_FAF3F9', 'ClipBlit_Replace_Deferred',
     'Deferred path: allocate param block, enqueue callback, return'),

    ('LABEL_FAF41A', 'ClipBlit_Replace_Return',
     'Common return: pop xiz, clean stack'),

    ('LABEL_FAF41E', 'ClipBlit_Replace_ParamBlock',
     'Callback stub: unpack params from block, call impl'),

    ('LABEL_FAF428', 'ClipBlit_Replace_Impl',
     'Main clipped blit routine 1: clip rect, copy scanlines with row skip table'),

    ('LABEL_FAF458', 'ClipBlit_Replace_ClipRight',
     'Clip X against right edge (0x140)'),

    ('LABEL_FAF46F', 'ClipBlit_Replace_ClipY',
     'Clip Y coordinate against screen bounds'),

    ('LABEL_FAF480', 'ClipBlit_Replace_ClipBottom',
     'Clip Y against bottom edge (0xF0)'),

    ('LABEL_FAF493', 'ClipBlit_Replace_CalcVRAMAddr',
     'Calculate VRAM destination address from clipped coords'),

    ('LABEL_FAF4C7', 'ClipBlit_Replace_ScanlineLoop',
     'Scanline copy loop body: look up row skip, copy pixels'),

    ('LABEL_FAF515', 'ClipBlit_Replace_ScanlineCond',
     'Scanline loop condition: check row against clipped height'),

    # --- FAF542-FAF580: Clipped blit wrapper pair 2 (mode 1: direct copy) ---
    ('LABEL_FAF542', 'ClipBlit_Direct',
     'Clipped blit wrapper 2: check render context, dispatch or defer'),

    ('LABEL_FAF55B', 'ClipBlit_Direct_Deferred',
     'Deferred path: allocate param block, enqueue callback'),

    ('LABEL_FAF57C', 'ClipBlit_Direct_Return',
     'Common return: pop xiz, clean stack'),

    ('LABEL_FAF580', 'ClipBlit_Direct_ParamBlock',
     'Callback stub 2: unpack params, call impl'),

    ('LABEL_FAF58A', 'ClipBlit_Direct_Impl',
     'Main clipped blit routine 2: clip rect, copy scanlines directly'),

    ('LABEL_FAF5B5', 'ClipBlit_Direct_ClipRight',
     'Clip X against right edge (0x140)'),

    ('LABEL_FAF5CC', 'ClipBlit_Direct_ClipY',
     'Clip Y coordinate against screen bounds'),

    ('LABEL_FAF5DA', 'ClipBlit_Direct_ClipBottom',
     'Clip Y against bottom edge (0xF0)'),

    ('LABEL_FAF5ED', 'ClipBlit_Direct_CalcVRAMAddr',
     'Calculate VRAM destination address from clipped coords'),

    ('LABEL_FAF624', 'ClipBlit_Direct_ScanlineLoop',
     'Scanline copy loop body'),

    ('LABEL_FAF647', 'ClipBlit_Direct_ScanlineCond',
     'Scanline loop condition'),

    # --- FAF674-FAF6CD: Color blit wrapper (mode with color lookup) ---
    ('LABEL_FAF674', 'ColorBlit',
     'Color blit wrapper: check context, read color mode byte, dispatch'),

    ('LABEL_FAF6A0', 'ColorBlit_Deferred',
     'Deferred path: allocate param block with color mode, enqueue'),

    ('LABEL_FAF6C9', 'ColorBlit_Return',
     'Common return'),

    ('LABEL_FAF6CD', 'ColorBlit_CallbackBlock',
     'Callback code block for deferred color blit'),

    ('LABEL_FAF6EC', 'ColorBlit_Impl',
     'Color blit impl: clamp coords, dispatch by color mode (0/1/2/F5/F7)'),

    ('LABEL_FAF6FC', 'ColorBlit_ClampTop',
     'Clamp top Y coordinate to >= 0'),

    ('LABEL_FAF706', 'ColorBlit_ClampLeft',
     'Clamp left X coordinate to >= 0'),

    ('LABEL_FAF719', 'ColorBlit_ClampRight',
     'Clamp right X to < 0x140'),

    ('LABEL_FAF72C', 'ColorBlit_ClampBottom',
     'Clamp bottom Y to < 0xF0; dispatch by color mode'),

    # --- ColorBlit mode 0: overlay with palette masking ---
    ('LABEL_FAF759', 'ColorBlit_Mode0_RowLoop',
     'Mode 0 row loop: compute VRAM addr per row'),

    ('LABEL_FAF77D', 'ColorBlit_Mode0_PixelLoop',
     'Mode 0 pixel loop: mask palette bits, overlay color, fix sign bit'),

    ('LABEL_FAF79C', 'ColorBlit_Mode0_PixelSignOK',
     'Sign bit matches: skip XOR fixup'),

    ('LABEL_FAF7A7', 'ColorBlit_Mode0_NextRow',
     'Advance to next row'),

    # --- ColorBlit mode F5: overlay with secondary buffer ---
    ('LABEL_FAF7B3', 'ColorBlit_ModeF5_Entry',
     'Mode F5 entry: overlay from secondary palette buffer'),

    ('LABEL_FAF7BB', 'ColorBlit_ModeF5_RowLoop',
     'Mode F5 row loop'),

    ('LABEL_FAF7EC', 'ColorBlit_ModeF5_PixelLoop',
     'Mode F5 pixel loop: AND+OR palette bits from secondary buffer'),

    ('LABEL_FAF807', 'ColorBlit_ModeF5_PixelSignOK',
     'Sign bit matches: skip XOR fixup'),

    ('LABEL_FAF814', 'ColorBlit_ModeF5_NextRow',
     'Advance to next row'),

    # --- ColorBlit mode 1: toggle bit 5 based on sign ---
    ('LABEL_FAF820', 'ColorBlit_Mode1_Entry',
     'Mode 1 entry: toggle bit 5 based on pixel MSB'),

    ('LABEL_FAF82A', 'ColorBlit_Mode1_RowLoop',
     'Mode 1 row loop'),

    ('LABEL_FAF84E', 'ColorBlit_Mode1_PixelLoop',
     'Mode 1 pixel loop: test bit 7, set/reset bit 5'),

    ('LABEL_FAF856', 'ColorBlit_Mode1_SetBit5',
     'Bit 7 clear: set bit 5'),

    ('LABEL_FAF858', 'ColorBlit_Mode1_NextPixel',
     'Advance to next pixel'),

    ('LABEL_FAF863', 'ColorBlit_Mode1_NextRow',
     'Advance to next row'),

    # --- ColorBlit mode 2: toggle bit 6 based on sign ---
    ('LABEL_FAF86E', 'ColorBlit_Mode2_Entry',
     'Mode 2 entry: toggle bit 6 based on pixel MSB'),

    ('LABEL_FAF877', 'ColorBlit_Mode2_RowLoop',
     'Mode 2 row loop'),

    ('LABEL_FAF89B', 'ColorBlit_Mode2_PixelLoop',
     'Mode 2 pixel loop: test bit 7, set/reset bit 6'),

    ('LABEL_FAF8A3', 'ColorBlit_Mode2_SetBit6',
     'Bit 7 clear: set bit 6'),

    ('LABEL_FAF8A5', 'ColorBlit_Mode2_NextPixel',
     'Advance to next pixel'),

    ('LABEL_FAF8B0', 'ColorBlit_Mode2_NextRow',
     'Advance to next row'),

    ('LABEL_FAF8B9', 'ColorBlit_Epilogue',
     'Common epilogue: call SetChangeRect, return'),

    ('LABEL_FAF8BC', 'ColorBlit_PopReturn',
     'Pop xiz, clean stack, ret'),

    # --- FAF8C0-FAF919: Second color blit wrapper (with saved mode) ---
    ('LABEL_FAF8C0', 'ColorBlit2',
     'Second color blit wrapper: similar to ColorBlit but saves mode byte'),

    ('LABEL_FAF8EC', 'ColorBlit2_Deferred',
     'Deferred path: allocate param block with saved mode'),

    ('LABEL_FAF915', 'ColorBlit2_Return',
     'Common return'),

    ('LABEL_FAF919', 'ColorBlit2_CallbackBlock',
     'Callback code block for deferred color blit 2'),

    ('LABEL_FAF938', 'ColorBlit2_Impl',
     'Color blit 2 impl: clamp coords, dispatch by mode'),

    ('LABEL_FAF948', 'ColorBlit2_ClampTop',
     'Clamp top Y >= 0'),

    ('LABEL_FAF952', 'ColorBlit2_ClampLeft',
     'Clamp left X >= 0'),

    ('LABEL_FAF965', 'ColorBlit2_ClampRight',
     'Clamp right X < 0x140'),

    ('LABEL_FAF978', 'ColorBlit2_ClampBottom',
     'Clamp bottom Y < 0xF0; dispatch by mode'),

    # --- ColorBlit2 mode 0: overlay with palette masking ---
    ('LABEL_FAF9A5', 'ColorBlit2_Mode0_RowLoop',
     'Mode 0 row loop'),

    ('LABEL_FAF9C9', 'ColorBlit2_Mode0_PixelLoop',
     'Mode 0 pixel loop'),

    ('LABEL_FAF9E8', 'ColorBlit2_Mode0_PixelSignOK',
     'Sign bit OK'),

    ('LABEL_FAF9F3', 'ColorBlit2_Mode0_NextRow',
     'Next row'),

    ('LABEL_FAF9FF', 'ColorBlit2_ModeF5_Entry',
     'Mode F5 entry'),

    ('LABEL_FAFA07', 'ColorBlit2_ModeF5_RowLoop',
     'Mode F5 row loop'),

    ('LABEL_FAFA38', 'ColorBlit2_ModeF5_PixelLoop',
     'Mode F5 pixel loop'),

    ('LABEL_FAFA53', 'ColorBlit2_ModeF5_PixelSignOK',
     'Sign bit OK'),

    ('LABEL_FAFA60', 'ColorBlit2_ModeF5_NextRow',
     'Next row'),

    # --- ColorBlit2 mode 1: toggle bit 5 (reversed sense vs mode 1 above) ---
    ('LABEL_FAFA6C', 'ColorBlit2_Mode1_Entry',
     'Mode 1 entry'),

    ('LABEL_FAFA76', 'ColorBlit2_Mode1_RowLoop',
     'Mode 1 row loop'),

    ('LABEL_FAFA9B', 'ColorBlit2_Mode1_PixelLoop',
     'Mode 1 pixel loop: test bit 7, set/reset bit 5'),

    ('LABEL_FAFAA3', 'ColorBlit2_Mode1_ResBit5',
     'Bit 7 clear: reset bit 5'),

    ('LABEL_FAFAA5', 'ColorBlit2_Mode1_NextPixel',
     'Next pixel'),

    ('LABEL_FAFAB0', 'ColorBlit2_Mode1_NextRow',
     'Next row'),

    # --- ColorBlit2 mode 2: fullscreen or clipped toggle bit 6 ---
    ('LABEL_FAFABC', 'ColorBlit2_Mode2_Entry',
     'Mode 2 entry: check if fullscreen (0xEF rows, 0x13F cols)'),

    ('LABEL_FAFAE1', 'ColorBlit2_Mode2_FullscreenLoop',
     'Fullscreen fast path: iterate all 0x12C00 pixels'),

    ('LABEL_FAFAE9', 'ColorBlit2_Mode2_FullscreenRes6',
     'Bit 7 clear: reset bit 6'),

    ('LABEL_FAFAEB', 'ColorBlit2_Mode2_FullscreenNext',
     'Advance to next pixel in fullscreen path'),

    ('LABEL_FAFAF9', 'ColorBlit2_Mode2_ClippedEntry',
     'Clipped path entry: iterate rows within clip rect'),

    ('LABEL_FAFAFF', 'ColorBlit2_Mode2_RowLoop',
     'Mode 2 clipped row loop'),

    ('LABEL_FAFB23', 'ColorBlit2_Mode2_PixelLoop',
     'Mode 2 clipped pixel loop'),

    ('LABEL_FAFB2B', 'ColorBlit2_Mode2_ResBit6',
     'Bit 7 clear: reset bit 6'),

    ('LABEL_FAFB2D', 'ColorBlit2_Mode2_NextPixel',
     'Next pixel'),

    ('LABEL_FAFB38', 'ColorBlit2_Mode2_NextRow',
     'Next row'),

    ('LABEL_FAFB41', 'ColorBlit2_Epilogue',
     'Common epilogue: SetChangeRect + return'),

    ('LABEL_FAFB44', 'ColorBlit2_PopReturn',
     'Pop xiz, clean stack, ret'),

    ('LABEL_FAFB48', 'ColorBlit2_LargeCodeBlock',
     'Large inline code block for complex sprite composition'),

    # ======================================================================
    # 2. DrumVoice inline stubs / Tempo-Beat region (F652A1 - F669D3)
    #    Drum voice dispatch table (7 handler addresses), tempo display
    #    string tables, beat counter inc/dec with range clamping.
    # ======================================================================

    # --- F652A1: DrumVoice dispatch ---
    ('LABEL_F652A1', 'DrumVoice_Dispatch',
     'Dispatch by low nibble of L: index into 15-entry jump table'),

    ('LABEL_F652BB', 'DrumVoice_DispatchTable',
     'Jump table: 15 handler addresses for drum voice commands'),

    ('LABEL_F652F7', 'DrumVoice_NullHandler',
     'Null handler (ret) for unused drum voice table entries'),

    ('LABEL_F652F8', 'DrumVoice_Handler0',
     'Drum voice handler 0: inline byte sequence'),

    ('LABEL_F65335', 'DrumVoice_Handler1',
     'Drum voice handler 1: inline byte sequence'),

    ('LABEL_F65372', 'DrumVoice_Handler2',
     'Drum voice handler 2: inline byte sequence'),

    ('LABEL_F653A4', 'DrumVoice_Handler3',
     'Drum voice handler 3: inline byte sequence'),

    ('LABEL_F653C0', 'DrumVoice_Handler5',
     'Drum voice handler 5: inline byte sequence'),

    ('LABEL_F653ED', 'DrumVoice_Handler4',
     'Drum voice handler 4: inline byte sequence'),

    ('LABEL_F6547E', 'DrumVoice_Handler6',
     'Drum voice handler 6: inline byte sequence'),

    ('LABEL_F654B0', 'DrumVoice_Handler7',
     'Drum voice handler 7: inline byte sequence'),

    # --- F658F2: Drum EE notification call ---
    ('LABEL_F658F2', 'DrumVoice_NotifyEE',
     'Save all regs, call F994BD with a=0xEE, restore regs'),

    # --- F65909: Time signature display strings ---
    ('LABEL_F65909', 'TimeSig_DisplayStrings',
     'Time signature display string table: (1/2), (2/4), etc.'),

    # --- F66263-F663C5: Tempo/beat counter manipulation ---
    ('LABEL_F66263', 'Tempo_AdjustStartMeasure',
     'Adjust start measure counter (14730) up/down with range clamping'),

    ('LABEL_F66288', 'Tempo_StartMeasureDec',
     'Decrement path for start measure'),

    ('LABEL_F66294', 'Tempo_StartMeasureSync',
     'Sync end-measure (14732) if start exceeds it'),

    ('LABEL_F662A6', 'Tempo_StartMeasureSyncFar',
     'End measure too far ahead: pull it closer to start+7'),

    ('LABEL_F662B0', 'Tempo_StartMeasureSetDirty',
     'Set dirty flag (bit 4 of 58336)'),

    ('LABEL_F662B4', 'Tempo_StartMeasureReturn',
     'Return from start measure adjust'),

    ('LABEL_F662B7', 'Tempo_AdjustEndMeasure',
     'Adjust end measure counter (14732) up/down with range clamping'),

    ('LABEL_F662DE', 'Tempo_EndMeasureDec',
     'Decrement path for end measure'),

    ('LABEL_F662EE', 'Tempo_EndMeasureSyncStart',
     'Sync start-measure (14730) if end goes below it'),

    ('LABEL_F662FC', 'Tempo_EndMeasureSyncFar',
     'Start measure too far behind: push it up'),

    ('LABEL_F66308', 'Tempo_EndMeasureSetDirty',
     'Set dirty flag'),

    ('LABEL_F6630C', 'Tempo_EndMeasureReturn',
     'Return from end measure adjust'),

    ('LABEL_F6630F', 'Tempo_AdjustQuantize',
     'Adjust quantize value (14734) up/down, max 0x31'),

    ('LABEL_F66333', 'Tempo_QuantizeDec',
     'Decrement path for quantize'),

    ('LABEL_F6633F', 'Tempo_QuantizeSetDirty',
     'Set dirty flag'),

    ('LABEL_F66343', 'Tempo_QuantizeReturn',
     'Return from quantize adjust'),

    ('LABEL_F66346', 'Tempo_AdjustEffect',
     'Adjust effect parameter (14736) via indirect table at E4A0A4'),

    ('LABEL_F66375', 'Tempo_EffectDec',
     'Decrement path for effect'),

    ('LABEL_F6637B', 'Tempo_EffectStore',
     'Store new value and set dirty flag'),

    ('LABEL_F66381', 'Tempo_EffectReturn',
     'Return from effect adjust'),

    ('LABEL_F66384', 'Tempo_IncrementTimeSigNum',
     'Increment time-signature numerator (14735), max 0x1D'),

    ('LABEL_F663A5', 'Tempo_DecrementTimeSigNum',
     'Decrement time-signature numerator (14735), min 0'),

    ('LABEL_F663C5', 'Tempo_TimeSigCodeBlock',
     'Code block for time-signature display mode switching'),

    # --- F6641B-F66450: Tempo BPM editor ---
    ('LABEL_F6641B', 'Tempo_EditBPM',
     'Tempo BPM editing function: handle up/down with clamping'),

    ('LABEL_F6643A', 'Tempo_EditBPMDec',
     'Decrement BPM path'),

    ('LABEL_F66447', 'Tempo_EditBPMClamp',
     'Clamp BPM within valid range'),

    ('LABEL_F66450', 'Tempo_EditBPMApply',
     'Apply new BPM value and set dirty flag'),

    # --- F66559-F6657D: Common display helper ---
    ('LABEL_F66559', 'Tempo_DisplayParamCommon',
     'Common helper: display parameter on LCD with position/format'),

    ('LABEL_F66567', 'Tempo_DisplayParamSkipClear',
     'Skip clear step'),

    ('LABEL_F66572', 'Tempo_DisplayParamFormat',
     'Format and display parameter value'),

    ('LABEL_F6657D', 'Tempo_DisplayParamReturn',
     'Return from display helper'),

    # --- F665C9-F666BA: Per-param display functions ---
    ('LABEL_F665C9', 'Tempo_DisplayStartMeasure',
     'Display start measure value on LCD'),

    ('LABEL_F66606', 'Tempo_DisplayEndMeasure',
     'Display end measure value on LCD'),

    ('LABEL_F66642', 'Tempo_DisplayQuantize',
     'Display quantize value on LCD'),

    ('LABEL_F6667E', 'Tempo_DisplayTimeSigNum',
     'Display time-signature numerator on LCD'),

    ('LABEL_F666BA', 'Tempo_DisplayEffect',
     'Display effect parameter on LCD'),

    ('LABEL_F666BD', 'Tempo_DisplayEffectLookup',
     'Look up effect name from table'),

    ('LABEL_F666C4', 'Tempo_DisplayEffectRender',
     'Render effect string to display'),

    # --- F666DD-F66779: Tempo value display helpers ---
    ('LABEL_F666DD', 'Tempo_FormatBPM',
     'Format BPM value for display'),

    ('LABEL_F666E9', 'Tempo_FormatBPMDigit',
     'Format single BPM digit'),

    ('LABEL_F666FB', 'Tempo_FormatBPMDone',
     'BPM formatting complete'),

    ('LABEL_F666FF', 'Tempo_FormatBPMOutput',
     'Output formatted BPM string'),

    ('LABEL_F66709', 'Tempo_FormatBPMPad',
     'Pad BPM display with leading spaces'),

    ('LABEL_F6670D', 'Tempo_DisplayBPMValue',
     'Display BPM integer value'),

    ('LABEL_F66721', 'Tempo_DisplayBPMFraction',
     'Display BPM fractional part'),

    ('LABEL_F6673A', 'Tempo_DisplayBPMNoFrac',
     'No fractional part: display as integer'),

    ('LABEL_F6673F', 'Tempo_DisplayBPMDecimal',
     'Display decimal point separator'),

    ('LABEL_F66748', 'Tempo_DisplayBPMWithDec',
     'Display BPM with decimal'),

    ('LABEL_F66750', 'Tempo_DisplayBPMFinal',
     'Final step of BPM display'),

    ('LABEL_F66767', 'Tempo_DisplayBPMClean',
     'Clean up BPM display area'),

    ('LABEL_F66775', 'Tempo_DisplayBPMExit',
     'Exit BPM display'),

    ('LABEL_F66779', 'Tempo_DisplayBPMReturn',
     'Return from BPM display function'),

    # --- F667D2-F66899: Multi-value display routines ---
    ('LABEL_F667D2', 'Tempo_DisplayMeasureRange',
     'Display full measure range (start-end) on LCD'),

    ('LABEL_F667EB', 'Tempo_DisplayMeasureStart',
     'Display start measure component'),

    ('LABEL_F66801', 'Tempo_DisplayMeasureSep',
     'Display separator between start and end'),

    ('LABEL_F6680D', 'Tempo_DisplayMeasureEnd',
     'Display end measure component'),

    ('LABEL_F66819', 'Tempo_DisplayQuantizeVal',
     'Display quantize value in context'),

    ('LABEL_F66825', 'Tempo_DisplayTimeSig',
     'Display time signature in context'),

    ('LABEL_F66831', 'Tempo_DisplayEffectVal',
     'Display effect value in context'),

    ('LABEL_F66836', 'Tempo_DisplayEffectValLookup',
     'Look up effect value for display'),

    # --- F66867-F66899: Screen refresh functions ---
    ('LABEL_F66867', 'Tempo_RefreshDisplay1',
     'Refresh tempo display variant 1'),

    ('LABEL_F66874', 'Tempo_RefreshDisplay2',
     'Refresh tempo display variant 2'),

    ('LABEL_F66881', 'Tempo_RefreshDisplay3',
     'Refresh tempo display variant 3'),

    ('LABEL_F6688E', 'Tempo_RefreshDisplay4',
     'Refresh tempo display variant 4'),

    ('LABEL_F66899', 'Tempo_RefreshDisplay5',
     'Refresh tempo display variant 5'),

    # --- F668F5-F669D3: Sequencer record/playback controls ---
    ('LABEL_F668F5', 'SeqRec_InitState',
     'Initialize sequencer recording state'),

    ('LABEL_F66904', 'SeqRec_InitChannels',
     'Initialize recording channel state'),

    ('LABEL_F66924', 'SeqRec_StartRecord',
     'Start recording to sequencer'),

    ('LABEL_F66929', 'SeqRec_StartRecordImpl',
     'Recording start implementation'),

    ('LABEL_F6694A', 'SeqRec_StopRecord',
     'Stop sequencer recording'),

    ('LABEL_F66956', 'SeqRec_StopRecordImpl',
     'Recording stop implementation'),

    ('LABEL_F66986', 'SeqRec_UpdateState',
     'Update recording state flags'),

    ('LABEL_F6698E', 'SeqRec_UpdateFlags',
     'Update individual state flags'),

    ('LABEL_F66992', 'SeqRec_CheckOverflow',
     'Check for recording buffer overflow'),

    ('LABEL_F669A2', 'SeqRec_HandleOverflow',
     'Handle recording buffer overflow'),

    ('LABEL_F669A9', 'SeqRec_OverflowCleanup',
     'Clean up after overflow'),

    ('LABEL_F669BE', 'SeqRec_CommitData',
     'Commit recorded data to buffer'),

    ('LABEL_F669C5', 'SeqRec_CommitFinalize',
     'Finalize committed data'),

    ('LABEL_F669CB', 'SeqRec_Validate',
     'Validate recorded sequence data'),

    ('LABEL_F669D3', 'SeqRec_ValidateDone',
     'Validation complete'),

    ('LABEL_F669FF', 'SeqRec_Cleanup',
     'Clean up sequencer recording resources'),

    # ======================================================================
    # 3. SMF/MIDI file playback (F28238 - F29E48)
    #    Standard MIDI File parsing, channel assignment, MIDI output
    #    formatting, song bank I/O, slot configuration.
    # ======================================================================

    # --- F28238-F2823A: Trivial return and MIDI header constants ---
    ('LABEL_F28238', 'SMF_PopReturn',
     'Pop wa, return from SMF parser'),

    ('LABEL_F2823A', 'SMF_HeaderConstants',
     'MIDI file header constants: MThd/MTrk markers, default params'),

    # --- F282A0-F283C6: Channel scan and assignment ---
    ('LABEL_F282A0', 'SMF_ScanChannels',
     'Scan all 15 MIDI channels for active/inactive status'),

    ('LABEL_F282A4', 'SMF_ScanChannels_Loop',
     'Channel scan loop: test channel bit, check special mode'),

    ('LABEL_F282ED', 'SMF_ScanChannels_Inactive',
     'Channel inactive: store and increment counter'),

    ('LABEL_F282FD', 'SMF_ScanChannels_Next',
     'Advance to next channel in scan'),

    ('LABEL_F28308', 'SMF_CountActiveChannels',
     'Count number of active channels across all 15'),

    ('LABEL_F2830C', 'SMF_CountActive_Loop',
     'Active channel count loop body'),

    ('LABEL_F28333', 'SMF_CountActive_Next',
     'Next channel in count loop'),

    ('LABEL_F28341', 'SMF_FindFreeChannel',
     'Find first free (inactive) MIDI channel'),

    ('LABEL_F2834D', 'SMF_FindFree_Next',
     'Next channel in free-channel search'),

    ('LABEL_F28354', 'SMF_FindFree_CheckPart',
     'Check channel part assignment for free channel'),

    ('LABEL_F28388', 'SMF_AssignRemainingChannels',
     'Assign remaining unassigned channels'),

    ('LABEL_F283BF', 'SMF_AssignRemaining_Next',
     'Next channel in remaining assignment'),

    ('LABEL_F283C6', 'SMF_AssignReturn',
     'Return from channel assignment'),

    # --- F283C7-F283DE: Memory clear + tempo calculation ---
    ('LABEL_F283C7', 'SMF_ClearWorkArea',
     'Clear 256-word work area at 0x11F9'),

    ('LABEL_F283D4', 'SMF_ClearWork_Loop',
     'Clear loop body'),

    ('LABEL_F283DE', 'SMF_CalcTempoRate',
     'Calculate tempo rate: divide 10176 by HL, multiply by 100, store'),

    # --- F28401-F2851D: MIDI SysEx/command output sequence ---
    ('LABEL_F28401', 'SMF_OutputCommandSeq',
     'Output sequence of MIDI commands with error checking'),

    ('LABEL_F2840A', 'SMF_OutputCmd_ReadByte',
     'Read next byte and output via WriteByte'),

    ('LABEL_F2842A', 'SMF_OutputCmd_ErrorCheck1',
     'Error check after first read: abort if error'),

    ('LABEL_F28430', 'SMF_OutputCmd_SendFF',
     'Send 0xFF byte (MIDI reset/meta)'),

    ('LABEL_F28454', 'SMF_OutputCmd_ErrorCheck2',
     'Error check after 0xFF'),

    ('LABEL_F2845A', 'SMF_OutputCmd_Send51',
     'Send 0x51 byte (tempo meta-event)'),

    ('LABEL_F28479', 'SMF_OutputCmd_ErrorCheck3',
     'Error check after 0x51'),

    ('LABEL_F2847F', 'SMF_OutputCmd_Send03',
     'Send 0x03 byte (track name length)'),

    ('LABEL_F2849E', 'SMF_OutputCmd_ErrorCheck4',
     'Error check after 0x03'),

    ('LABEL_F284A4', 'SMF_OutputCmd_SendTempoH',
     'Send tempo high byte from addr 3950'),

    ('LABEL_F284C5', 'SMF_OutputCmd_ErrorCheck5',
     'Error check after tempo high'),

    ('LABEL_F284CB', 'SMF_OutputCmd_SendTempoM',
     'Send tempo mid byte from addr 3949'),

    ('LABEL_F284EC', 'SMF_OutputCmd_ErrorCheck6',
     'Error check after tempo mid'),

    ('LABEL_F284F2', 'SMF_OutputCmd_SendTempoL',
     'Send tempo low byte from addr 3948'),

    ('LABEL_F28513', 'SMF_OutputCmd_ErrorCheck7',
     'Error check after tempo low'),

    ('LABEL_F28519', 'SMF_OutputCmd_Finalize',
     'Finalize: reload file pointer'),

    ('LABEL_F2851D', 'SMF_OutputCmd_Return',
     'Return from command output sequence'),

    # --- F2851E: File I/O write byte with buffer management ---
    ('LABEL_F2851E', 'SMF_WriteByte',
     'Write byte to MIDI file buffer; manage sector boundaries'),

    ('LABEL_F28538', 'SMF_WriteByte_SectorCheck',
     'Check if file pointer crossed sector boundary'),

    ('LABEL_F2855A', 'SMF_WriteByte_SectorError',
     'Sector boundary error path'),

    ('LABEL_F28560', 'SMF_WriteByte_SectorOK',
     'Sector OK: continue'),

    ('LABEL_F28562', 'SMF_WriteByte_NewSector',
     'Allocate new sector: increment counter, check alignment'),

    ('LABEL_F28580', 'SMF_WriteByte_AlignCheck',
     'Check 4-byte alignment'),

    ('LABEL_F2859C', 'SMF_WriteByte_AlignError',
     'Alignment error path'),

    ('LABEL_F285A2', 'SMF_WriteByte_AllocSector',
     'Allocate new sector: set file pointer to 0x13FA'),

    ('LABEL_F285B3', 'SMF_WriteByte_Done',
     'Write complete: restore regs, return'),

    # --- F285B6-F28672: Extended write with looping ---
    ('LABEL_F285B6', 'SMF_WriteByteLoop',
     'Write byte loop: process multiple bytes with channel tagging'),

    ('LABEL_F285C1', 'SMF_WriteLoop_ReadByte',
     'Read next byte for write loop'),

    ('LABEL_F285E3', 'SMF_WriteLoop_Error',
     'Write loop error: pop and abort'),

    ('LABEL_F285EA', 'SMF_WriteLoop_Continue',
     'Continue write loop after successful byte'),

    ('LABEL_F28613', 'SMF_WriteLoop_SendFF',
     'Send 0xFF in write loop'),

    ('LABEL_F28619', 'SMF_WriteLoop_AfterFF',
     'After 0xFF: check error, continue'),

    ('LABEL_F2863A', 'SMF_WriteLoop_Send51',
     'Send 0x51 in write loop'),

    ('LABEL_F28640', 'SMF_WriteLoop_After51',
     'After 0x51: send tempo bytes'),

    ('LABEL_F2866C', 'SMF_WriteLoop_FinalError',
     'Final error check in write loop'),

    ('LABEL_F28672', 'SMF_WriteLoop_Done',
     'Write loop complete'),

    # --- F28678-F286B7: Channel helpers ---
    ('LABEL_F28678', 'SMF_ChannelHelperReturn',
     'Return from channel helper'),

    ('LABEL_F28679', 'SMF_GetNextEvent',
     'Read next event from song bank; update position'),

    ('LABEL_F2868F', 'SMF_AdvancePosition',
     'Advance read position; handle 0xFF restart'),

    ('LABEL_F286B0', 'SMF_AdvancePos_Inc',
     'Simple increment path'),

    ('LABEL_F286B2', 'SMF_AdvancePos_Store',
     'Store new position'),

    ('LABEL_F286B7', 'SMF_CalcTimeDelta',
     'Calculate time delta between events for tempo tracking'),

    ('LABEL_F286D6', 'SMF_TimeDelta_CheckFirst',
     'Check if this is the first event (add 384 ticks)'),

    ('LABEL_F286F4', 'SMF_TimeDelta_Store',
     'Store computed time delta and call encoder'),

    # --- F28704-F2878F: Process and filter active channels ---
    ('LABEL_F28704', 'SMF_ProcessChannels',
     'Process active channels: filter events, sort by priority'),

    ('LABEL_F28718', 'SMF_ProcessCh_Loop',
     'Channel processing loop body'),

    ('LABEL_F2874F', 'SMF_ProcessCh_MoveToOutput',
     'Move channel data to output queue'),

    ('LABEL_F28779', 'SMF_ProcessCh_Next',
     'Advance to next channel'),

    ('LABEL_F2878F', 'SMF_ProcessCh_Finalize',
     'Finalize: clear accumulators, return'),

    # --- F2879C-F287D0: Channel config helpers ---
    ('LABEL_F2879C', 'SMF_SendChannelConfig',
     'Send channel config (0xB0 | channel) via extended write'),

    ('LABEL_F287AB', 'SMF_FlushToFile',
     'Flush current data to file (call F28C25)'),

    ('LABEL_F287B0', 'SMF_CheckAndFlush',
     'Check if sector count > 0, flush to file if so'),

    ('LABEL_F287D0', 'SMF_CheckFlush_Return',
     'Return from check-and-flush'),

    # --- F287D1-F28901: Event dispatcher ---
    ('LABEL_F287D1', 'SMF_DispatchEvent',
     'Main MIDI event dispatcher: resolve channel, check drum/special modes'),

    ('LABEL_F287F2', 'SMF_Dispatch_CheckDrumMode',
     'Check if channel is in drum mode (bit 2 of 64941)'),

    ('LABEL_F2881A', 'SMF_Dispatch_DrumChannel',
     'Handle drum channel: search for available drum slot'),

    ('LABEL_F28836', 'SMF_Dispatch_DrumSearch',
     'Drum channel search loop'),

    ('LABEL_F2887D', 'SMF_Dispatch_DrumFound',
     'Drum slot found: assign and continue'),

    ('LABEL_F28885', 'SMF_Dispatch_NoDrumMode',
     'Non-drum mode: check if channel 15 needs remapping'),

    ('LABEL_F2889B', 'SMF_Dispatch_Ch15Remap',
     'Channel 15 remapping search'),

    ('LABEL_F288B5', 'SMF_Dispatch_Ch15Search',
     'Channel 15 search loop body'),

    ('LABEL_F288FB', 'SMF_Dispatch_Ch15Found',
     'Channel 15 slot found'),

    # --- F28901-F28AC0: MIDI event type handler ---
    ('LABEL_F28901', 'SMF_HandleEventType',
     'Event type handler: set up output, branch by status byte'),

    ('LABEL_F2891C', 'SMF_EventType_Switch',
     'Switch on MIDI status byte (0x82, 0x84, 0xD0-D3, 0x80, 0x90, 0xB0, 0xC0)'),

    ('LABEL_F28956', 'SMF_Event_NoteOff82',
     'Handle 0x82 meta event: rewrite as 0x82'),

    ('LABEL_F2895E', 'SMF_Event_PartD0',
     'Handle 0xD0: set output 0xA0'),

    ('LABEL_F28962', 'SMF_Event_PartD1',
     'Handle 0xD1: set output 0xD0'),

    ('LABEL_F28966', 'SMF_Event_PartD2',
     'Handle 0xD2: set output 0xE0'),

    ('LABEL_F2896A', 'SMF_Event_PartD3',
     'Handle 0xD3: set output 0xF0'),

    ('LABEL_F2896E', 'SMF_Event_Part80',
     'Handle 0x80: set output 0xA0'),

    ('LABEL_F28972', 'SMF_Event_NoteOn',
     'Handle 0x90 note-on: set output 0x90'),

    ('LABEL_F28974', 'SMF_Event_OutputByte',
     'Output event byte with channel OR, check if note-on needs drum remap'),

    # --- F28999-F28ABD: Program change and control change ---
    ('LABEL_F28999', 'SMF_Event_ProgramChange',
     'Handle 0xC0 program change: advance 2 bytes, check special mode'),

    ('LABEL_F289EB', 'SMF_ProgChg_SearchPart',
     'Search for matching part in assignment table'),

    ('LABEL_F289F9', 'SMF_ProgChg_SearchNext',
     'Next entry in part search'),

    ('LABEL_F28A00', 'SMF_ProgChg_NotFound',
     'Part not found: default to 0x7F'),

    ('LABEL_F28A04', 'SMF_ProgChg_Found',
     'Part found: check channel bit, resolve'),

    ('LABEL_F28A23', 'SMF_ProgChg_UseDefault',
     'Use default channel assignment'),

    ('LABEL_F28A27', 'SMF_ProgChg_Write',
     'Write program change to output'),

    ('LABEL_F28A2D', 'SMF_Event_ControlChange',
     'Handle 0xB0 control change: advance bytes, resolve part'),

    ('LABEL_F28A81', 'SMF_CtrlChg_SearchPart',
     'Search for matching part'),

    ('LABEL_F28A8F', 'SMF_CtrlChg_SearchNext',
     'Next entry in part search'),

    ('LABEL_F28A96', 'SMF_CtrlChg_NotFound',
     'Part not found: default to 0x7F'),

    ('LABEL_F28A9A', 'SMF_CtrlChg_Found',
     'Part found: check channel bit, resolve'),

    ('LABEL_F28AB9', 'SMF_CtrlChg_UseDefault',
     'Use default channel'),

    ('LABEL_F28ABD', 'SMF_CtrlChg_Write',
     'Write control change to output'),

    ('LABEL_F28AC0', 'SMF_EventLoop_Continue',
     'Continue event processing loop'),

    ('LABEL_F28ACE', 'SMF_EventLoop_SpecialCC',
     'Check for special CC: 0x50 (sustain) or 0x51'),

    ('LABEL_F28AD8', 'SMF_EventLoop_SkipCC',
     'Skip special CC: continue loop'),

    ('LABEL_F28ADA', 'SMF_EventLoop_Return',
     'Return from event processing'),

    ('LABEL_F28ADB', 'SMF_PartAssignTable',
     'Part-to-channel assignment lookup table (24 bytes)'),

    # --- F28AF3-F28BA5: Time delta encoder ---
    ('LABEL_F28AF3', 'SMF_EncodeTimeDelta',
     'Encode time delta into variable-length MIDI delta format'),

    ('LABEL_F28B17', 'SMF_Encode_LargeValue',
     'Delta > 16383: 3-byte encoding'),

    ('LABEL_F28B2D', 'SMF_Encode_ThreeBytes',
     'Pack 3-byte variable-length delta'),

    ('LABEL_F28B6D', 'SMF_Encode_TwoBytes',
     'Delta 128-16383: 2-byte encoding'),

    ('LABEL_F28B96', 'SMF_Encode_OneByte',
     'Delta < 128: 1-byte encoding'),

    ('LABEL_F28BA5', 'SMF_Encode_Return',
     'Return from delta encoder'),

    # --- F28BA6-F28C24: Output queue management ---
    ('LABEL_F28BA6', 'SMF_ClearOutputQueue',
     'Clear output queue (96 entries at 0xFAE, fill with 0xFF)'),

    ('LABEL_F28BB2', 'SMF_ClearQueue_Loop',
     'Clear loop body'),

    ('LABEL_F28BBA', 'SMF_SortOutputQueue',
     'Sort output queue by priority (bubble sort)'),

    ('LABEL_F28BC7', 'SMF_Sort_OuterLoop',
     'Outer sort loop: scan entries at 0xFAE and 0xFB1'),

    ('LABEL_F28BE3', 'SMF_Sort_InnerLoop',
     'Inner sort loop: compare adjacent entries'),

    ('LABEL_F28BFF', 'SMF_Sort_Swap',
     'Swap two entries (3 bytes each)'),

    ('LABEL_F28C17', 'SMF_Sort_AdvanceOuter',
     'Advance outer loop index'),

    ('LABEL_F28C21', 'SMF_Sort_Finalize',
     'Sort done: call tempo updater'),

    ('LABEL_F28C24', 'SMF_Sort_Return',
     'Return from sort'),

    # --- F28C25-F28C76: File write helpers ---
    ('LABEL_F28C25', 'SMF_FileWrite',
     'Write to MIDI file via FileIO_WriteByte_Impl'),

    ('LABEL_F28C3E', 'SMF_FileWriteAndClear',
     'Write to file then clear buffer (F28E51)'),

    ('LABEL_F28C5B', 'SMF_LookupSongBank',
     'Look up song bank by page number (10415), compute address'),

    ('LABEL_F28C74', 'SMF_AdvanceMultipleEvents',
     'Advance past multiple events (read 2 bytes)'),

    ('LABEL_F28C76', 'SMF_AdvanceMulti_Loop',
     'Multi-advance loop body'),

    # --- F28C82-F28D6B: Channel resolution with drum mode ---
    ('LABEL_F28C82', 'SMF_ResolveChannel',
     'Resolve MIDI channel: handle drum mode remapping'),

    ('LABEL_F28CA1', 'SMF_Resolve_DrumCh9',
     'Channel is drum channel 9: search for free slot'),

    ('LABEL_F28CB6', 'SMF_Resolve_DrumSearch',
     'Drum channel search loop'),

    ('LABEL_F28CF9', 'SMF_Resolve_DrumFound',
     'Drum slot found: return channel number'),

    ('LABEL_F28CFD', 'SMF_Resolve_NoDrum',
     'Non-drum mode: check channel 15 remap'),

    ('LABEL_F28D10', 'SMF_Resolve_Ch15Check',
     'Channel 15 remap check'),

    ('LABEL_F28D24', 'SMF_Resolve_Ch15Search',
     'Channel 15 search loop'),

    ('LABEL_F28D67', 'SMF_Resolve_Ch15Found',
     'Channel 15 slot found'),

    ('LABEL_F28D6B', 'SMF_Resolve_Return',
     'Return resolved channel'),

    # --- F28D6C-F28DF3: Tempo update from output queue ---
    ('LABEL_F28D6C', 'SMF_UpdateTempo',
     'Update tempo from sorted output queue entries'),

    ('LABEL_F28D77', 'SMF_UpdateTempo_Loop',
     'Tempo update loop: process each queue entry'),

    ('LABEL_F28DA2', 'SMF_UpdateTempo_SubtractBase',
     'Subtract base rate from entry timing'),

    ('LABEL_F28DAE', 'SMF_UpdateTempo_ClampZero',
     'Clamp negative result to zero'),

    ('LABEL_F28DB2', 'SMF_UpdateTempo_Encode',
     'Encode delta, write channel, clear MSB'),

    ('LABEL_F28DF3', 'SMF_UpdateTempo_Finalize',
     'Finalize: adjust cumulative timing, clear accumulators'),

    # --- F28E19-F28E66: File position calculation ---
    ('LABEL_F28E19', 'SMF_CalcFilePosition',
     'Calculate absolute file position from sector count and pointer'),

    ('LABEL_F28E51', 'SMF_ClearFileBuffer',
     'Clear file buffer: 512 words at 0x13FA'),

    ('LABEL_F28E5B', 'SMF_ClearBuf_Loop',
     'Clear loop body'),

    # --- F28E66-F28F0F: Resolve global channel assignment ---
    ('LABEL_F28E66', 'SMF_ResolveGlobalChannel',
     'Resolve global channel: check drum mode, find free slot'),

    ('LABEL_F28E7E', 'SMF_GlobalCh_DrumMode',
     'Drum mode: assign channel 9 or 15'),

    ('LABEL_F28E91', 'SMF_GlobalCh_DrumCh15',
     'Assign channel 15 in drum mode'),

    ('LABEL_F28E9A', 'SMF_GlobalCh_NoDrum',
     'Non-drum: check channel 9 and 15 availability'),

    ('LABEL_F28EB1', 'SMF_GlobalCh_NonDrumCh15',
     'Non-drum channel 15 check'),

    ('LABEL_F28EBE', 'SMF_GlobalCh_FreeSearch',
     'Free channel search loop'),

    ('LABEL_F28ECA', 'SMF_GlobalCh_SearchLoop',
     'Search loop body'),

    ('LABEL_F28F09', 'SMF_GlobalCh_Found',
     'Free channel found: store result'),

    ('LABEL_F28F0F', 'SMF_GlobalCh_Return',
     'Return from global channel resolution'),

    # --- F28F15-F28F7E: Song bank load and playback init ---
    ('LABEL_F28F15', 'SMF_LoadSongBank',
     'Load song bank from disk: detect format version, iterate events'),

    ('LABEL_F28F35', 'SMF_LoadBank_ReadEntries',
     'Read song bank entries: set up read pointers'),

    ('LABEL_F28F67', 'SMF_LoadBank_EventLoop',
     'Event processing loop: read, parse, advance to next'),

    ('LABEL_F28F7E', 'SMF_LoadBank_Return',
     'Return from song bank load'),

    ('LABEL_F28F7F', 'SMF_SetupReadPointers',
     'Set up read pointers from song bank addresses'),

    ('LABEL_F28F94', 'SMF_ResetPlaybackState',
     'Reset all playback state flags'),

    # --- F28FC8-F2902B: Event parser main loop ---
    ('LABEL_F28FC8', 'SMF_ParseEvents',
     'Parse events: read status bytes, dispatch by type'),

    ('LABEL_F29006', 'SMF_Parse_ClearAutoFlag',
     'Clear auto-accomp flag'),

    ('LABEL_F2900D', 'SMF_Parse_NextChannel',
     'Advance to next channel in parse'),

    ('LABEL_F2902B', 'SMF_Parse_Complete',
     'Parsing complete: clear all state flags'),

    # --- F2905E-F2908D: Channel number translation ---
    ('LABEL_F2905E', 'SMF_TranslateChannel',
     'Translate internal channel number to MIDI channel'),

    ('LABEL_F29087', 'SMF_Translate_0xE',
     'Map 0x0E to 0x17'),

    ('LABEL_F29089', 'SMF_Translate_Apply',
     'Apply translated channel'),

    ('LABEL_F2908B', 'SMF_Translate_Return',
     'Return from translation'),

    ('LABEL_F2908D', 'SMF_ChannelTranslationTable',
     'Channel translation lookup table (64 bytes)'),

    # --- F290CD-F29474: Slot configuration engine ---
    ('LABEL_F290CD', 'SMF_ConfigSlot',
     'Configure slot: resolve slot number, process events'),

    ('LABEL_F290F1', 'SMF_ConfigSlot_Setup',
     'Set up slot state: store pointers, initialize counters'),

    ('LABEL_F2911A', 'SMF_ConfigSlot_EventLoop',
     'Slot event processing loop: dispatch by status byte'),

    ('LABEL_F29152', 'SMF_ConfigSlot_DefaultHandler',
     'Default handler: advance and continue'),

    ('LABEL_F2915D', 'SMF_ConfigSlot_WriteAndContinue',
     'Write event and continue'),

    ('LABEL_F29168', 'SMF_ConfigSlot_AdvanceEvent',
     'Advance past current event, check for more'),

    ('LABEL_F2918D', 'SMF_ConfigSlot_TypeB0',
     'Type 0xB0: set data count to 5'),

    ('LABEL_F29195', 'SMF_ConfigSlot_TypeC0',
     'Type 0xC0: set data count to 4'),

    ('LABEL_F2919D', 'SMF_ConfigSlot_TypeD2',
     'Type 0xD2: set data count to 2'),

    ('LABEL_F291A5', 'SMF_ConfigSlot_Type80',
     'Type 0x80: set data count to 3'),

    ('LABEL_F291AB', 'SMF_ConfigSlot_StoreType',
     'Store event type and format control bits'),

    ('LABEL_F291E0', 'SMF_ConfigSlot_ReadDataLoop',
     'Read data bytes for current event type'),

    # --- F29243-F29306: Format-specific handlers ---
    ('LABEL_F29243', 'SMF_Config_Format1',
     'Format 1: check event count, call handler'),

    ('LABEL_F29255', 'SMF_Config_Format1_Done',
     'Format 1 done'),

    ('LABEL_F29259', 'SMF_Config_Format2',
     'Format 2: check event count'),

    ('LABEL_F29268', 'SMF_Config_Format2_Done',
     'Format 2 done'),

    ('LABEL_F2926C', 'SMF_Config_Format3',
     'Format 3: check event count, call chain'),

    ('LABEL_F2927E', 'SMF_Config_Format3_Done',
     'Format 3 done'),

    ('LABEL_F29282', 'SMF_Config_ProcessSlotData',
     'Process slot data: dispatch by event count 2/3/4/5'),

    ('LABEL_F292AB', 'SMF_Config_Count2',
     'Event count=2: call handler, set flag'),

    ('LABEL_F292B5', 'SMF_Config_Count3',
     'Event count=3: call handler'),

    ('LABEL_F292BA', 'SMF_Config_Count5',
     'Event count=5: call full chain of 19 handlers'),

    ('LABEL_F292FA', 'SMF_Config_Count4',
     'Event count=4: call handler, set flag'),

    ('LABEL_F29302', 'SMF_Config_PopAndContinue',
     'Pop saved regs and continue'),

    ('LABEL_F29306', 'SMF_Config_Format4or5',
     'Format 4 or 5: call special handler'),

    ('LABEL_F29317', 'SMF_Config_Format5_Handler',
     'Format 5 specific handler'),

    ('LABEL_F29322', 'SMF_Config_WriteOutput',
     'Write slot output: iterate events, apply assignments'),

    ('LABEL_F2933E', 'SMF_Config_WriteLoop',
     'Write loop body'),

    ('LABEL_F29376', 'SMF_Config_HandleBit1',
     'Handle bit 1 flag: clear and jump to advance'),

    ('LABEL_F29383', 'SMF_Config_OutputOverride1',
     'Output override with w=1'),

    ('LABEL_F2938D', 'SMF_Config_OutputOverride6',
     'Output override with w=6'),

    ('LABEL_F29395', 'SMF_Config_SaveAndRestore',
     'Save channel state, call event handler, restore'),

    ('LABEL_F293E5', 'SMF_Config_GetTableEntry',
     'Get table entry from indexed position'),

    ('LABEL_F293F0', 'SMF_Config_CallHandler',
     'Call event handler (F22E12)'),

    ('LABEL_F2944C', 'SMF_Config_ClearFlags',
     'Clear processing flags and continue'),

    # --- F29459-F29474: End-of-slot handler ---
    ('LABEL_F29459', 'SMF_ConfigSlot_EndOfTrack',
     'End-of-track (0x82): output event, advance, return'),

    ('LABEL_F29474', 'SMF_ConfigSlot_Return',
     'Return from slot configuration'),

    ('LABEL_F29475', 'SMF_ConfigSlot_CodeBlock',
     'Inline code block for complex slot operations'),

    # --- F294C1-F294F9: Detect song bank format ---
    ('LABEL_F294C1', 'SMF_DetectFormat',
     'Detect song bank format version from header bytes'),

    ('LABEL_F294E6', 'SMF_Format_Version5',
     'Format version 5'),

    ('LABEL_F294ED', 'SMF_Format_Version4',
     'Format version 4'),

    ('LABEL_F294F4', 'SMF_Format_Version1',
     'Format version 1'),

    ('LABEL_F294F9', 'SMF_Format_Return',
     'Return from format detection'),

    # --- F294FA-F29563: Event advance helpers ---
    ('LABEL_F294FA', 'SMF_AdvanceReadPtr',
     'Advance read pointer (IX): handle page wrap'),

    ('LABEL_F29528', 'SMF_AdvanceRead_NewPage',
     'New page: reset IX to 5'),

    ('LABEL_F2952A', 'SMF_AdvanceRead_Return',
     'Return from read advance'),

    ('LABEL_F2952B', 'SMF_AdvanceWritePtr',
     'Advance write pointer (IY): handle page wrap'),

    ('LABEL_F29557', 'SMF_AdvanceWrite_NewPage',
     'New page: store new base, reset IY to 5'),

    ('LABEL_F2955D', 'SMF_AdvanceWrite_Return',
     'Return from write advance'),

    ('LABEL_F29563', 'SMF_CalcPageAddress',
     'Calculate page base address from page number'),

    # --- F29575-F29619: Slot event chain handlers ---
    ('LABEL_F29575', 'SMF_SlotChain_CheckInstr',
     'Check instrument assignment (handler 1 of chain)'),

    ('LABEL_F2959E', 'SMF_SlotChain_ResolveInstr',
     'Resolve instrument: translate and assign'),

    ('LABEL_F295B5', 'SMF_SlotChain_StoreInstr',
     'Store resolved instrument number'),

    ('LABEL_F295C1', 'SMF_SlotChain_InstrReturn',
     'Return from instrument check'),

    ('LABEL_F295C2', 'SMF_SlotChain_CheckVoice',
     'Check voice assignment (handler 2)'),

    ('LABEL_F295F2', 'SMF_SlotChain_ResolveVoice',
     'Resolve voice'),

    ('LABEL_F29609', 'SMF_SlotChain_StoreVoice',
     'Store resolved voice'),

    ('LABEL_F29618', 'SMF_SlotChain_VoiceReturn',
     'Return from voice check'),

    ('LABEL_F29619', 'SMF_SlotChain_ExtendedVoice',
     'Extended voice handler: check format 3, compute address'),

    ('LABEL_F29658', 'SMF_SlotChain_ExtVoiceDefault',
     'Extended voice: use default value 0'),

    ('LABEL_F2965A', 'SMF_SlotChain_ExtVoiceStore',
     'Store extended voice bytes'),

    ('LABEL_F29665', 'SMF_SlotChain_ExtVoiceReturn',
     'Return from extended voice'),

    # --- F29666-F296BB: Format 3 voice chain ---
    ('LABEL_F29666', 'SMF_SlotChain_Fmt3Voice',
     'Format 3 voice assignment chain'),

    ('LABEL_F296AF', 'SMF_SlotChain_Fmt3Resolve',
     'Format 3 resolve voice from ROM table'),

    ('LABEL_F296BB', 'SMF_SlotChain_Fmt3Return',
     'Return from format 3 voice'),

    # --- F296BC-F29B9E: Slot parameter chain (19 handlers for count=5) ---
    ('LABEL_F296BC', 'SMF_SlotParam_Volume',
     'Slot parameter: volume setting'),

    ('LABEL_F296EA', 'SMF_SlotParam_VolumeImpl',
     'Volume implementation'),

    ('LABEL_F29702', 'SMF_SlotParam_VolumeCalc',
     'Volume calculation'),

    ('LABEL_F2971D', 'SMF_SlotParam_VolumeScale',
     'Volume scaling'),

    ('LABEL_F2973A', 'SMF_SlotParam_VolumeStore',
     'Store computed volume'),

    ('LABEL_F29748', 'SMF_SlotParam_VolumeWrite',
     'Write volume to output'),

    ('LABEL_F29764', 'SMF_SlotParam_VolumeOutput',
     'Output volume event'),

    ('LABEL_F2977B', 'SMF_SlotParam_VolumeDone',
     'Volume done'),

    ('LABEL_F29787', 'SMF_SlotParam_VolumeReturn',
     'Return from volume'),

    ('LABEL_F29788', 'SMF_SlotParam_Pan',
     'Slot parameter: pan setting'),

    ('LABEL_F297B1', 'SMF_SlotParam_PanReturn',
     'Return from pan'),

    ('LABEL_F297B2', 'SMF_SlotParam_Expression',
     'Slot parameter: expression'),

    ('LABEL_F297DB', 'SMF_SlotParam_ExprReturn',
     'Return from expression'),

    ('LABEL_F297DC', 'SMF_SlotParam_Reverb',
     'Slot parameter: reverb send'),

    ('LABEL_F29805', 'SMF_SlotParam_ReverbReturn',
     'Return from reverb'),

    ('LABEL_F29806', 'SMF_SlotParam_Chorus',
     'Slot parameter: chorus send'),

    ('LABEL_F2982F', 'SMF_SlotParam_ChorusReturn',
     'Return from chorus'),

    ('LABEL_F29830', 'SMF_SlotParam_ModWheel',
     'Slot parameter: mod wheel'),

    ('LABEL_F29852', 'SMF_SlotParam_ModWheelImpl',
     'Mod wheel implementation'),

    ('LABEL_F2986F', 'SMF_SlotParam_ModWheelCalc',
     'Mod wheel calculation'),

    ('LABEL_F2989B', 'SMF_SlotParam_ModWheelStore',
     'Store mod wheel value'),

    ('LABEL_F298A8', 'SMF_SlotParam_ModWheelReturn',
     'Return from mod wheel'),

    ('LABEL_F298A9', 'SMF_SlotParam_PitchBend',
     'Slot parameter: pitch bend'),

    ('LABEL_F298CB', 'SMF_SlotParam_PitchBendImpl',
     'Pitch bend implementation'),

    ('LABEL_F298E8', 'SMF_SlotParam_PitchBendCalc',
     'Pitch bend calculation'),

    ('LABEL_F29902', 'SMF_SlotParam_PitchBendStore',
     'Store pitch bend'),

    ('LABEL_F29904', 'SMF_SlotParam_PitchBendReturn',
     'Return from pitch bend'),

    ('LABEL_F2991C', 'SMF_SlotParam_Detune',
     'Slot parameter: fine detune'),

    ('LABEL_F2991D', 'SMF_SlotParam_DetuneImpl',
     'Detune implementation'),

    ('LABEL_F29959', 'SMF_SlotParam_Aftertouch',
     'Slot parameter: aftertouch'),

    ('LABEL_F2998F', 'SMF_SlotParam_AftertouchImpl',
     'Aftertouch implementation'),

    ('LABEL_F299B1', 'SMF_SlotParam_AftertouchReturn',
     'Return from aftertouch'),

    ('LABEL_F299B2', 'SMF_SlotParam_PortamentoSwitch',
     'Slot parameter: portamento switch'),

    ('LABEL_F299D5', 'SMF_SlotParam_PortaImpl',
     'Portamento implementation'),

    ('LABEL_F299E4', 'SMF_SlotParam_PortaReturn',
     'Return from portamento switch'),

    ('LABEL_F299E5', 'SMF_SlotParam_PortamentoTime',
     'Slot parameter: portamento time'),

    ('LABEL_F29A22', 'SMF_SlotParam_Sustain',
     'Slot parameter: sustain pedal'),

    ('LABEL_F29A57', 'SMF_SlotParam_SustainImpl',
     'Sustain implementation'),

    ('LABEL_F29A63', 'SMF_SlotParam_SustainReturn',
     'Return from sustain'),

    ('LABEL_F29A64', 'SMF_SlotParam_Sostenuto',
     'Slot parameter: sostenuto pedal'),

    ('LABEL_F29A9A', 'SMF_SlotParam_SostenutoReturn1',
     'Sostenuto return path 1'),

    ('LABEL_F29A9B', 'SMF_SlotParam_SoftPedal',
     'Slot parameter: soft pedal'),

    ('LABEL_F29AC5', 'SMF_SlotParam_SoftPedalImpl',
     'Soft pedal implementation'),

    ('LABEL_F29AD1', 'SMF_SlotParam_SoftPedalReturn',
     'Return from soft pedal'),

    ('LABEL_F29AD2', 'SMF_SlotParam_Format5Handler',
     'Format 5 specific parameter handler'),

    ('LABEL_F29AF4', 'SMF_SlotParam_Format5Impl',
     'Format 5 implementation'),

    ('LABEL_F29B1B', 'SMF_SlotParam_Format5Check',
     'Format 5 check'),

    ('LABEL_F29B2F', 'SMF_SlotParam_Format5Return',
     'Return from format 5'),

    ('LABEL_F29B30', 'SMF_SlotParam_ReverbType',
     'Slot parameter: reverb type'),

    ('LABEL_F29B52', 'SMF_SlotParam_ReverbTypeImpl',
     'Reverb type implementation'),

    ('LABEL_F29B75', 'SMF_SlotParam_ReverbTypeCalc',
     'Reverb type calculation'),

    ('LABEL_F29B84', 'SMF_SlotParam_ReverbTypeOutput',
     'Output reverb type'),

    ('LABEL_F29B95', 'SMF_SlotParam_ReverbTypeDone',
     'Reverb type done'),

    ('LABEL_F29B9D', 'SMF_SlotParam_ReverbTypeReturn',
     'Return from reverb type'),

    ('LABEL_F29B9E', 'SMF_SlotParam_ChorusType',
     'Slot parameter: chorus type'),

    ('LABEL_F29BCE', 'SMF_SlotParam_ChorusTypeImpl',
     'Chorus type implementation'),

    ('LABEL_F29BDC', 'SMF_SlotParam_ChorusTypeCheck',
     'Chorus type check'),

    ('LABEL_F29BFE', 'SMF_SlotParam_ChorusTypeDone',
     'Chorus type done'),

    ('LABEL_F29BFF', 'SMF_SlotParam_ChorusTypeReturn',
     'Return from chorus type'),

    # --- F29C3A-F29D64: Additional slot chain handlers ---
    ('LABEL_F29C3A', 'SMF_SlotParam_BankSelect',
     'Slot parameter: bank select MSB'),

    ('LABEL_F29C64', 'SMF_SlotParam_BankSelectImpl',
     'Bank select implementation'),

    ('LABEL_F29C70', 'SMF_SlotParam_BankSelectDone',
     'Bank select done'),

    ('LABEL_F29C71', 'SMF_SlotParam_BankSelectReturn',
     'Return from bank select'),

    ('LABEL_F29C8C', 'SMF_SlotParam_BankSelectLSB',
     'Slot parameter: bank select LSB'),

    ('LABEL_F29CA3', 'SMF_SlotParam_BankLSBImpl',
     'Bank LSB implementation'),

    ('LABEL_F29CBE', 'SMF_SlotParam_BankLSBDone',
     'Bank LSB done'),

    ('LABEL_F29CBF', 'SMF_SlotParam_BankLSBReturn',
     'Return from bank LSB'),

    ('LABEL_F29CEF', 'SMF_SlotParam_RPN',
     'Slot parameter: RPN (Registered Parameter Number)'),

    ('LABEL_F29D0A', 'SMF_SlotParam_RPNDone',
     'RPN done'),

    ('LABEL_F29D0B', 'SMF_SlotParam_RPNReturn',
     'Return from RPN'),

    ('LABEL_F29D49', 'SMF_SlotParam_NRPN',
     'Slot parameter: NRPN (Non-Registered Parameter Number)'),

    ('LABEL_F29D60', 'SMF_SlotParam_NRPNImpl',
     'NRPN implementation'),

    ('LABEL_F29D63', 'SMF_SlotParam_NRPNDone',
     'NRPN done'),

    ('LABEL_F29D64', 'SMF_SlotParam_NRPNReturn',
     'Return from NRPN'),

    # --- F29D9C-F29E48: Final helpers ---
    ('LABEL_F29D9C', 'SMF_SlotParam_DataEntry',
     'Slot parameter: data entry (for RPN/NRPN)'),

    ('LABEL_F29DAA', 'SMF_SlotParam_DataEntryReturn',
     'Return from data entry'),

    ('LABEL_F29DAB', 'SMF_SlotParam_TypeD2Handler',
     'Handle type 0xD2 event in slot chain'),

    ('LABEL_F29DC5', 'SMF_SlotParam_TypeD2Impl',
     'Type D2 implementation'),

    ('LABEL_F29DCB', 'SMF_SlotParam_TypeD2Done',
     'Type D2 done'),

    ('LABEL_F29DCF', 'SMF_SlotParam_TypeD2Return',
     'Return from type D2'),

    ('LABEL_F29DD0', 'SMF_SlotParam_Type80Handler',
     'Handle type 0x80 event in slot chain'),

    ('LABEL_F29DF8', 'SMF_SetupSongBankRead',
     'Set up song bank read: initialize position from stored pointers'),

    ('LABEL_F29E0A', 'SMF_SetupRead_Adjust',
     'Adjust read position'),

    ('LABEL_F29E1F', 'SMF_SetupRead_Finalize',
     'Finalize read setup'),

    ('LABEL_F29E48', 'SMF_SetupRead_Return',
     'Return from read setup'),

    # ======================================================================
    # 4. Accompaniment sequence engine (F6E00B - F6EFEB)
    #    Auto-accompaniment MIDI sequence processing: parse events from
    #    style data, generate MIDI output, handle fade-out, pedal control.
    # ======================================================================

    # --- F6E00B-F6E03A: Song part transition ---
    ('LABEL_F6E00B', 'AccompSeq_PartTransitionDone',
     'Part transition complete: jump to main dispatch'),

    ('LABEL_F6E00D', 'AccompSeq_StopPart',
     'Stop current accompaniment part'),

    ('LABEL_F6E01B', 'AccompSeq_StopPartCh2',
     'Stop channel 2 only'),

    ('LABEL_F6E020', 'AccompSeq_CheckRestart',
     'Check if accompaniment should restart after stop'),

    ('LABEL_F6E039', 'AccompSeq_DispatchReturn',
     'Return from dispatch'),

    # --- F6E03A-F6E079: Delta time calculator ---
    ('LABEL_F6E03A', 'AccompSeq_CalcDeltaTime',
     'Calculate delta time for next event from position counters'),

    ('LABEL_F6E054', 'AccompSeq_DeltaZero',
     'Delta is zero: no time advancement'),

    ('LABEL_F6E058', 'AccompSeq_DeltaCompare',
     'Compare current position vs target position'),

    ('LABEL_F6E06A', 'AccompSeq_DeltaOneAhead',
     'Target is one measure ahead: compute fractional delta'),

    ('LABEL_F6E077', 'AccompSeq_DeltaFarBehind',
     'Target is far behind: return zero delta'),

    ('LABEL_F6E079', 'AccompSeq_DeltaReturn',
     'Return computed delta time'),

    # --- F6E07A-F6E15C: Parse and process accompaniment events ---
    ('LABEL_F6E07A', 'AccompSeq_ParseEvents',
     'Parse accompaniment events: dispatch by type (0x90, 0x91, 0xC0)'),

    ('LABEL_F6E080', 'AccompSeq_ParseLoop',
     'Event parse loop body'),

    ('LABEL_F6E098', 'AccompSeq_Parse_Type91',
     'Jump to 0x91 handler (8 data bytes)'),

    ('LABEL_F6E09C', 'AccompSeq_Parse_TypeC0',
     'Jump to 0xC0 handler (program change)'),

    ('LABEL_F6E0A0', 'AccompSeq_Parse_Type90',
     'Handle 0x90: read 6 params, compute size, dispatch'),

    ('LABEL_F6E0B3', 'AccompSeq_Parse_Type90_Large',
     'Type 90 with size > 16: use full processing'),

    ('LABEL_F6E0C0', 'AccompSeq_Parse_Done',
     'Parse complete: jump to return'),

    ('LABEL_F6E0C4', 'AccompSeq_Parse_Type91_Impl',
     'Type 0x91: read extra params, compute size'),

    ('LABEL_F6E0E5', 'AccompSeq_Parse_Type91_CalcSize',
     'Calculate 0x91 event size'),

    ('LABEL_F6E0F2', 'AccompSeq_Parse_Type91_Done',
     'Type 0x91 done'),

    ('LABEL_F6E0F6', 'AccompSeq_Parse_Fallthrough',
     'Fallthrough: unrecognized type'),

    ('LABEL_F6E12B', 'AccompSeq_Parse_TypeC0_CalcSize',
     'Type 0xC0: calculate event size'),

    ('LABEL_F6E138', 'AccompSeq_Parse_TypeC0_Done',
     'Type 0xC0 done'),

    ('LABEL_F6E13A', 'AccompSeq_Parse_TypeC0_Impl',
     'Type 0xC0 implementation'),

    ('LABEL_F6E14D', 'AccompSeq_Parse_TypeC0_Finalize',
     'Type 0xC0 finalize'),

    ('LABEL_F6E15A', 'AccompSeq_Parse_Return',
     'Return from event parse'),

    ('LABEL_F6E15C', 'AccompSeq_Ret',
     'Simple ret for accompaniment sequence'),

    # --- F6E15D-F6E188: Read parameter bytes ---
    ('LABEL_F6E15D', 'AccompSeq_ReadParams',
     'Read 6 parameter bytes from sequence into state (32340-32345)'),

    ('LABEL_F6E188', 'AccompSeq_CalcEventSize',
     'Calculate event size from position pointers'),

    ('LABEL_F6E1A0', 'AccompSeq_CalcSize_Negative',
     'Negative difference: handle wraparound'),

    ('LABEL_F6E1B0', 'AccompSeq_CalcSize_Positive',
     'Positive difference: simple subtraction'),

    ('LABEL_F6E1B3', 'AccompSeq_CalcSize_Store',
     'Store computed event size'),

    ('LABEL_F6E1B8', 'AccompSeq_ResetCounters',
     'Reset event counters to default initial values'),

    ('LABEL_F6E1D6', 'AccompSeq_InlineCodeBlock',
     'Inline code block for special event processing'),

    # --- F6E1F0-F6E2FF: Process note-on events (6 params) ---
    ('LABEL_F6E1F0', 'AccompSeq_ProcessNoteOn6',
     'Process 6-param note-on: channel, velocity, note, duration, etc.'),

    ('LABEL_F6E227', 'AccompSeq_NoteOn6_VelClamp',
     'Clamp velocity to minimum 1'),

    # --- F6E247-F6E2FF: Process note-on events (8 params) ---
    ('LABEL_F6E247', 'AccompSeq_ProcessNoteOn8',
     'Process 8-param note-on: extended with extra controls'),

    ('LABEL_F6E27D', 'AccompSeq_NoteOn8_VelClamp',
     'Clamp velocity to minimum 1'),

    # --- F6E2B5-F6E2FF: Process note with portamento ---
    ('LABEL_F6E2B5', 'AccompSeq_ProcessNotePorta',
     'Process note with portamento data'),

    ('LABEL_F6E2FF', 'AccompSeq_NotePorta_Done',
     'Note+portamento done; check D0/ch5 special case'),

    # --- F6E300-F6E363: Process note-on with 5 params ---
    ('LABEL_F6E300', 'AccompSeq_ProcessNoteOn5',
     'Process 5-param note-on: check 0xC0 program change storage'),

    ('LABEL_F6E35B', 'AccompSeq_NoteOn5_StoreProgram',
     'Store program change value in accompaniment state'),

    ('LABEL_F6E363', 'AccompSeq_NoteOn5_Return',
     'Return from 5-param note-on'),

    # --- F6E364-F6E39F: Channel resolution for accompaniment ---
    ('LABEL_F6E364', 'AccompSeq_ResolveChannel',
     'Resolve accompaniment channel with interrupt-safe wrapping'),

    ('LABEL_F6E381', 'AccompSeq_ResolveCh_Store',
     'Store resolved channel'),

    ('LABEL_F6E385', 'AccompSeq_ResolveCh_AddOffset',
     'Add channel offset and advance buffer pointer'),

    ('LABEL_F6E39F', 'AccompSeq_ResolveCh_Done',
     'Channel resolution done'),

    # --- F6E3A2-F6E3D3: Velocity/program check ---
    ('LABEL_F6E3A2', 'AccompSeq_CheckVelocityFlags',
     'Check velocity flags: set bits based on velocity and program range'),

    ('LABEL_F6E3B6', 'AccompSeq_VelFlags_CheckProgram',
     'Check program >= 0xF0: set additional flag'),

    ('LABEL_F6E3C7', 'AccompSeq_VelFlags_CallDispatch',
     'Call dispatch function F53310'),

    ('LABEL_F6E3D3', 'AccompSeq_CheckVelFlagsExtended',
     'Extended velocity flags with extra state bytes'),

    ('LABEL_F6E3F9', 'AccompSeq_ExtVelFlags_CheckProg',
     'Extended: check program >= 0xF0'),

    ('LABEL_F6E40A', 'AccompSeq_ExtVelFlags_Dispatch',
     'Extended: call dispatch function'),

    # --- F6E416-F6E41F: Buffer pointer advance ---
    ('LABEL_F6E416', 'AccompSeq_AdvanceBufferPtr',
     'Advance buffer pointer IY; wrap at BC limit'),

    ('LABEL_F6E41F', 'AccompSeq_AdvanceBuf_Return',
     'Return from buffer advance'),

    # --- F6E420-F6E455: Fade-out tick handler ---
    ('LABEL_F6E420', 'AccompSeq_FadeOutTick',
     'Fade-out tick: decrement counter, apply volume reduction'),

    ('LABEL_F6E428', 'AccompSeq_FadeOut_Active',
     'Fade-out active: decrement counter (32368)'),

    ('LABEL_F6E449', 'AccompSeq_FadeOut_Periodic',
     'Periodic update: check counter mod 8'),

    ('LABEL_F6E455', 'AccompSeq_FadeOut_Return',
     'Return from fade-out tick'),

    # --- F6E456-F6E4AA: Fade-out volume update ---
    ('LABEL_F6E456', 'AccompSeq_FadeOutApplyVol',
     'Apply fade-out volume: compute scaled volume for channels'),

    ('LABEL_F6E480', 'AccompSeq_FadeOut_Ch2Volume',
     'Apply fade-out to channel 2 (D2)'),

    ('LABEL_F6E4AA', 'AccompSeq_FadeOut_ChReturn',
     'Return from fade-out volume apply'),

    # --- F6E4AB-F6E4E0: Portamento fade-out ---
    ('LABEL_F6E4AB', 'AccompSeq_PortaFadeOut',
     'Portamento-specific fade-out: check D0/ch5 and compute volume'),

    ('LABEL_F6E4E0', 'AccompSeq_PortaFade_Return',
     'Return from portamento fade-out'),

    # --- F6E4E1-F6E52B: Manual MIDI mode handlers ---
    ('LABEL_F6E4E1', 'AccompSeq_ManualMidiMode1',
     'Manual MIDI mode 1: set flag bit 1'),

    ('LABEL_F6E4E8', 'AccompSeq_ManualMidiMode2',
     'Manual MIDI mode 2: set flag bit 3'),

    ('LABEL_F6E4ED', 'AccompSeq_ManualMidi_CheckAllNotes',
     'Check all-notes-off (l=0x7F, h=3)'),

    ('LABEL_F6E4FC', 'AccompSeq_ManualMidi_SaveAndCall',
     'Save state, call note-off/on handlers'),

    ('LABEL_F6E521', 'AccompSeq_ManualMidi_SetChannel',
     'Set MIDI channel for manual mode'),

    ('LABEL_F6E52B', 'AccompSeq_ManualMidi_ClearFlags',
     'Clear manual MIDI mode flags'),

    # --- F6E536: Large inline code block ---
    ('LABEL_F6E536', 'AccompSeq_LargeCodeBlock1',
     'Large inline code block for complex accompaniment logic'),

    # --- F6E607-F6E62E: Sequence position update ---
    ('LABEL_F6E607', 'AccompSeq_UpdatePosition',
     'Update sequence read position from stored pointers'),

    ('LABEL_F6E619', 'AccompSeq_UpdatePos_Part2',
     'Update for part 2 (secondary accompaniment)'),

    ('LABEL_F6E622', 'AccompSeq_UpdatePos_Store',
     'Store updated position'),

    ('LABEL_F6E62E', 'AccompSeq_JumpTable',
     'Jump/call table for sequence position functions'),

    # --- F6E63A-F6E649: Thin wrappers ---
    ('LABEL_F6E63A', 'AccompSeq_StopSequence',
     'Stop accompaniment sequence: call EB29 cleanup'),

    ('LABEL_F6E641', 'AccompSeq_SendMidiEvent',
     'Send MIDI event to sequence buffer (jump to EA37)'),

    ('LABEL_F6E645', 'AccompSeq_AllNotesOff',
     'All-notes-off for accompaniment (jump to EAAE)'),

    ('LABEL_F6E649', 'AccompSeq_ProcessAfterNote',
     'Process after note handling (jump to E6FC)'),

    ('LABEL_F6E64D', 'AccompSeq_LargeCodeBlock2',
     'Large inline code block for MIDI routing and filtering'),

    # --- F6E6FC-F6E70F: Post-note processing ---
    ('LABEL_F6E6FC', 'AccompSeq_PostNoteProcess',
     'Post-note: if active, call seq parser and chord analysis'),

    ('LABEL_F6E70E', 'AccompSeq_PostNote_Return',
     'Return from post-note'),

    ('LABEL_F6E70F', 'AccompSeq_InitPartFull',
     'Initialize accompaniment part: resolve, load, configure MIDI'),

    ('LABEL_F6E727', 'AccompSeq_ResetMidiState',
     'Reset MIDI state via F719F4'),

    # --- F6E72C-F6E76F: Style data lookup ---
    ('LABEL_F6E72C', 'AccompSeq_LookupStyleData',
     'Look up accompaniment style data address from index'),

    ('LABEL_F6E753', 'AccompSeq_LookupStyle_Internal',
     'Internal style: compute address from base + index*32'),

    ('LABEL_F6E76F', 'AccompSeq_LookupStyle_Return',
     'Return from style lookup'),

    # --- F6E770-F6E84D: Load accompaniment parameters ---
    ('LABEL_F6E770', 'AccompSeq_LoadParams',
     'Load accompaniment parameters from style data structure'),

    ('LABEL_F6E7BD', 'AccompSeq_LoadParams_Bit0Set',
     'Bit 0 set in flags: load secondary channel params'),

    ('LABEL_F6E7E1', 'AccompSeq_LoadParams_Alt',
     'Alternative param loading for >= 0x80 index'),

    ('LABEL_F6E7F8', 'AccompSeq_LoadParams_OverrideCheck',
     'Check if override table should be used'),

    ('LABEL_F6E84D', 'AccompSeq_LoadParams_Return',
     'Return from param loading'),

    # --- F6E84E-F6E91A: Initial MIDI event generation ---
    ('LABEL_F6E84E', 'AccompSeq_InitMidiEvents',
     'Generate initial MIDI events: program change, volume, controls'),

    ('LABEL_F6E88F', 'AccompSeq_InitMidi_Ch1Flags',
     'Channel 1: handle special flag bits'),

    ('LABEL_F6E8AA', 'AccompSeq_InitMidi_Ch1Reverb',
     'Channel 1: set reverb send'),

    ('LABEL_F6E8BD', 'AccompSeq_InitMidi_Ch1Chorus',
     'Channel 1: set chorus send'),

    ('LABEL_F6E8C4', 'AccompSeq_InitMidi_Ch2',
     'Channel 2: load secondary params'),

    ('LABEL_F6E8E5', 'AccompSeq_InitMidi_Ch2Flags',
     'Channel 2: handle flag bits'),

    ('LABEL_F6E900', 'AccompSeq_InitMidi_Ch2Reverb',
     'Channel 2: set reverb send'),

    ('LABEL_F6E913', 'AccompSeq_InitMidi_Ch2Chorus',
     'Channel 2: set chorus send'),

    ('LABEL_F6E91A', 'AccompSeq_InitMidi_Return',
     'Return from initial MIDI generation'),

    # --- F6E91B-F6E975: Playback state initialization ---
    ('LABEL_F6E91B', 'AccompSeq_InitPlayState',
     'Initialize accompaniment playback state and counters'),

    ('LABEL_F6E93B', 'AccompSeq_InitPlay_SetCounters',
     'Set playback counters and flags'),

    ('LABEL_F6E955', 'AccompSeq_InitPlay_Ch2Flag',
     'Set channel 2 active flag'),

    ('LABEL_F6E95D', 'AccompSeq_InitPlay_Store',
     'Store initialized state'),

    ('LABEL_F6E975', 'AccompSeq_InitPlay_Return',
     'Return from playback init'),

    # --- F6E976-F6E99E: Re-initialize with channel change ---
    ('LABEL_F6E976', 'AccompSeq_ReinitPart',
     'Re-initialize accompaniment part after channel change'),

    ('LABEL_F6E99E', 'AccompSeq_HandleSpecialMode',
     'Handle special accompaniment mode (mode 13/14)'),

    # --- F6E9FA-F6EA35: Event output dispatch ---
    ('LABEL_F6E9FA', 'AccompSeq_OutputEvent',
     'Output accompaniment event: check conditions, dispatch'),

    ('LABEL_F6EA1D', 'AccompSeq_Output_CheckFilter',
     'Check event filter flags'),

    ('LABEL_F6EA2B', 'AccompSeq_Output_CheckManual',
     'Check manual MIDI filter'),

    ('LABEL_F6EA35', 'AccompSeq_Output_Return',
     'Return from event output'),

    # --- F6EA37: Write 3 bytes to sequence event buffer ---
    ('LABEL_F6EA37', 'AccompSeq_WriteMidiToBuffer',
     'Write 3-byte MIDI event (status, param1, param2) to SeqEvtBuf'),

    ('LABEL_F6EA57', 'AccompSeq_WriteMidi_CodeBlock',
     'Code block for MIDI buffer management and routing'),

    # --- F6EAAE-F6EAD5: All-notes-off handler ---
    ('LABEL_F6EAAE', 'AccompSeq_AllNotesOffImpl',
     'All-notes-off: check active, optionally start fade, send note-off'),

    ('LABEL_F6EAD2', 'AccompSeq_AllNotesOff_Stop',
     'Stop variant: call sequence cleanup'),

    ('LABEL_F6EAD5', 'AccompSeq_AllNotesOff_Send',
     'Send all-notes-off MIDI message and dispatch'),

    # --- F6EADD-F6EB28: Guard check + call routines ---
    ('LABEL_F6EADD', 'AccompSeq_ClearPendingFlag',
     'Clear pending flag at 32523 if nonzero'),

    ('LABEL_F6EAEB', 'AccompSeq_ClearPending_Return',
     'Return from clear pending'),

    ('LABEL_F6EAEC', 'AccompSeq_GuardedNoteOff',
     'Multi-guard check then call F99490 with a=0xC8'),

    ('LABEL_F6EB28', 'AccompSeq_GuardedNote_Return',
     'Return from guarded note-off'),

    # --- F6EB29-F6EB57: Sequence cleanup ---
    ('LABEL_F6EB29', 'AccompSeq_CleanupSequence',
     'Clean up active accompaniment: clear flags, stop notes'),

    ('LABEL_F6EB4C', 'AccompSeq_Cleanup_ClearFlags',
     'Clear channel-active flags'),

    ('LABEL_F6EB57', 'AccompSeq_SendAllOff',
     'Send all-notes-off + reset program for both channels'),

    ('LABEL_F6EB9E', 'AccompSeq_SendAllOff_Loop1',
     'Clear 8 entries in voice state table 1 (0x7D6C)'),

    ('LABEL_F6EBB3', 'AccompSeq_SendAllOff_Loop2',
     'Clear 8 entries in voice state table 2 (0x7DB4)'),

    ('LABEL_F6EBC0', 'AccompSeq_MidiFilterCodeBlock',
     'Code block for MIDI channel filtering and state management'),

    # --- F6EC7A-F6ECE4: Chord change processing ---
    ('LABEL_F6EC7A', 'AccompSeq_ProcessChordChange',
     'Process chord change: clear flags, re-init, set up MIDI output'),

    ('LABEL_F6ECB0', 'AccompSeq_ChordChange_Reinit',
     'Chord change with active accomp: reinit part'),

    ('LABEL_F6ECC5', 'AccompSeq_ChordChange_CheckOverride',
     'Check if chord override is needed'),

    ('LABEL_F6ECDB', 'AccompSeq_ChordChange_ApplyOverride',
     'Apply chord override: clear bit, call updater'),

    ('LABEL_F6ECE4', 'AccompSeq_ChordChange_Return',
     'Return from chord change'),

    # --- F6ECE5-F6ED42: Chord comparison ---
    ('LABEL_F6ECE5', 'AccompSeq_CompareChord',
     'Compare current chord with style data chord'),

    ('LABEL_F6ED33', 'AccompSeq_CompareChord_Match',
     'Chord matches: set bit 0 of override'),

    ('LABEL_F6ED38', 'AccompSeq_CompareChord_RestorePos',
     'Restore saved position pointers'),

    ('LABEL_F6ED42', 'AccompSeq_CompareChord_Return',
     'Return from chord compare'),

    # --- F6ED43-F6EE25: Set up accompaniment channels ---
    ('LABEL_F6ED43', 'AccompSeq_SetupChannels',
     'Set up both accompaniment channels from style data'),

    ('LABEL_F6EDC5', 'AccompSeq_SetupCh2',
     'Set up accompaniment channel 2'),

    ('LABEL_F6EE25', 'AccompSeq_SetupCh_Return',
     'Return from channel setup'),

    # --- F6EE26-F6EFEB: Sequence data parser ---
    ('LABEL_F6EE26', 'AccompSeq_ParseSequenceData',
     'Parse accompaniment sequence data: iterate events by type'),

    ('LABEL_F6EE35', 'AccompSeq_SeqParse_Loop',
     'Sequence parse loop: check termination, dispatch'),

    ('LABEL_F6EE3F', 'AccompSeq_SeqParse_Dispatch',
     'Dispatch by event type byte'),

    ('LABEL_F6EE88', 'AccompSeq_SeqParse_EndMark',
     'Type 0x83: end of sequence, set termination flag'),

    ('LABEL_F6EE92', 'AccompSeq_SeqParse_TimeAdvance',
     'Type 0x81: advance time counter'),

    ('LABEL_F6EEA7', 'AccompSeq_SeqParse_TimeStore',
     'Store advanced time counter'),

    ('LABEL_F6EEB0', 'AccompSeq_SeqParse_MidiEvent',
     'MIDI event types (0x90, 0x91, 0xD1-D5, 0xD7, 0xC0)'),

    ('LABEL_F6EECA', 'AccompSeq_SeqParse_CheckNoteOn',
     'Check if event is 0x90 note-on'),

    ('LABEL_F6EEE7', 'AccompSeq_SeqParse_CheckNoteOn8',
     'Check if event is 0x91 (8-param note-on)'),

    ('LABEL_F6EF08', 'AccompSeq_SeqParse_CheckProgChg',
     'Check if event is 0xC0 (program change)'),

    ('LABEL_F6EF18', 'AccompSeq_SeqParse_ProgChg_SetCh',
     'Set channel for program change (1 or 2)'),

    ('LABEL_F6EF49', 'AccompSeq_SeqParse_ProgChg_Flags',
     'Handle program change flags and bit masking'),

    ('LABEL_F6EF6F', 'AccompSeq_SeqParse_ProgChg_Store',
     'Store program change value in accompaniment state'),

    ('LABEL_F6EF76', 'AccompSeq_SeqParse_CtrlChg',
     'Handle control change events (0xD0-0xD7)'),

    ('LABEL_F6EF88', 'AccompSeq_SeqParse_CtrlChg_SetCh',
     'Set channel for control change'),

    ('LABEL_F6EFC9', 'AccompSeq_SeqParse_CtrlChg_Loop',
     'Continue sequence parse loop after ctrl change'),

    ('LABEL_F6EFCD', 'AccompSeq_SeqParse_TempoReset',
     'Type 0x84: reset tempo from saved pointers'),

    ('LABEL_F6EFDC', 'AccompSeq_SeqParse_TempoStore',
     'Store reset tempo values'),

    ('LABEL_F6EFEB', 'AccompSeq_SeqParse_Return',
     'Return from sequence data parser'),

    ('LABEL_F6EFEC', 'AccompSeq_TempoScaleTable',
     'Tempo scale jump table: 8 entries for different time signatures'),
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
        print(f'  {old_label:35s} -> {new_label:45s} ({refs} refs)')

    with open(src, 'wb') as f:
        f.write(content.encode('latin-1'))

    print(f'\nRenamed {renamed} labels in maincpu')


if __name__ == '__main__':
    main()
