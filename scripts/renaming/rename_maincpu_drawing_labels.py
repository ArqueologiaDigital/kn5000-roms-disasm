#!/usr/bin/env python3
"""Rename LABEL_* to semantic names for maincpu drawing subsystem functions.

Based on analysis of the DrawLineEx, DrawFrameEx, DrawString, and surrounding
drawing functions in the ~FAA900-FAE800 address range of the main CPU program ROM.

This range covers the core 2D rendering engine: line drawing (Bresenham),
rectangle fill/frame, bitmap/sprite rendering, icon drawing, text rendering,
and decorative box drawing.  All functions render to OFFSCREEN_BUFFER_1 (0x43C00)
and call SetChangeRect to mark dirty regions.

Each rename was verified by analysing the routine's code, register usage, called
functions, and callers within the file.

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
# Naming conventions:
#   - Function entry points: FunctionName_Impl (for the inner implementation)
#   - Branch labels within a function: FunctionName_Description
#   - Data blocks: FunctionName_ParamBlock
#   - Shared helpers at the end: HelperName
#
# Widely-used shared infrastructure (LABEL_FAA444, LABEL_FAA36C, LABEL_FF0C0E,
# etc.) is NOT renamed here as those labels have 30+ references across the
# entire drawing subsystem and deserve their own rename pass.
#
#   FAA986          DrawLine helper epilogue
#   FAA9B2-FAA9E3   DrawLine deferred-rendering path + param block
#   FAA9FB-FAAF0D   DrawLine_Impl (Bresenham core)
#   FAAF48-FAB26C   DrawLineEx inner implementation
#   FAB295-FAB3D9   DrawBox inner paths
#   FAB400-FAB7FE   DrawFrame inner paths
#   FAB820-FABA4E   DrawFrameEx inner implementation
#   FABA75-FABB6E   MovePixels inner paths
#   FABB8A-FABBE7   DrawWall inner paths
#   FABC5E-FABE0E   DrawBitmap inner paths
#   FABE35-FABF3A   DrawBitmapFast inner paths
#   FABF61-FAC077   DrawIcons inner paths
#   FAC0A4-FAC1E8   DrawFrameSP inner paths
#   FAC217-FAC3D4   DrawBitmapSP inner paths
#   FAC406-FAC502   DrawBitmapSPFast inner paths
#   FAC53A-FAC690   DrawBitmapSP2 inner paths
#   FAC6B9-FACAC3   DrawBitmapFile inner paths
#   FACAFF-FACEA3   DrawString inner paths
#   FAD06E-FAD080   DrawStringAlignment dispatch
#   FAD0F7-FAD1D1   DrawStringReverse inner paths
#   FAD1D8-FAD213   Utility predicates (point/color range checks)
# ---------------------------------------------------------------------------

RENAMES = [
    # ==================================================================
    # DrawLine (FAA986-FAAF0D)
    # Bresenham line drawing from point A to point B on OFFSCREEN_BUFFER_1.
    # ==================================================================

    ('LABEL_FAA986', 'DrawLine_Epilogue',
     'Pop xiz, clean up stack, return from DrawLine fast path'),

    ('LABEL_FAA9B2', 'DrawLine_DeferredPath',
     'DrawLine deferred-rendering: allocate param block, copy coords, enqueue'),

    ('LABEL_FAA9DF', 'DrawLine_Return',
     'Common return point for DrawLine'),

    ('LABEL_FAA9E3', 'DrawLine_ParamBlock',
     'DrawLine parameter block template (24 bytes, for deferred rendering)'),

    ('LABEL_FAA9FB', 'DrawLine_Impl',
     'DrawLine inner implementation: Bresenham algorithm with fast-path branches'),

    ('LABEL_FAAA31', 'DrawLine_Impl_XStepPositive',
     'X step is positive (x2 >= x1)'),

    ('LABEL_FAAA55', 'DrawLine_Impl_YStepPositive',
     'Y step is positive (y2 >= y1)'),

    ('LABEL_FAAA6F', 'DrawLine_Impl_CalcDxReverse',
     'Calculate dx when x step is negative'),

    ('LABEL_FAAA79', 'DrawLine_Impl_CalcDxDone',
     'Extend dx to 32-bit and store'),

    ('LABEL_FAAA91', 'DrawLine_Impl_CalcDyReverse',
     'Calculate dy when y step is negative'),

    ('LABEL_FAAA97', 'DrawLine_Impl_CalcDyDone',
     'Extend dy to 32-bit; check if both dx,dy are zero'),

    ('LABEL_FAAAAB', 'DrawLine_Impl_CopyStartPos',
     'Copy start position, compute VRAM offset, prepare Bresenham fractions'),

    # -- Vertical line fast path (dx == 0) --
    ('LABEL_FAAB30', 'DrawLine_Impl_VerticalLoop',
     'Vertical line loop: plot pixel, advance y, repeat for dy iterations'),

    # -- Horizontal line fast path (dy == 0) --
    ('LABEL_FAAB69', 'DrawLine_Impl_HorizontalCheck',
     'dy==0: horizontal line; dispatch to memset or vertical step'),

    ('LABEL_FAABA2', 'DrawLine_Impl_HorzCalcNegDir',
     'Horizontal line with negative y direction: compute VRAM row offset'),

    ('LABEL_FAABB5', 'DrawLine_Impl_HorzMemset',
     'Call Memset to fill horizontal line span'),

    # -- Steep line (dy > dx): y-major Bresenham --
    ('LABEL_FAABBE', 'DrawLine_Impl_SteepCheck',
     'Check if line is steep (dy > dx) vs shallow'),

    ('LABEL_FAABFC', 'DrawLine_Impl_SteepLoop',
     'Steep line loop: plot pixel, accumulate x-error, step y each iteration'),

    # -- Shallow line (dx >= dy): x-major Bresenham --
    ('LABEL_FAAC43', 'DrawLine_Impl_ShallowSetup',
     'Shallow line setup: compute y-step fraction for x-major Bresenham'),

    ('LABEL_FAAC7E', 'DrawLine_Impl_ShallowLoop',
     'Shallow line loop: plot pixel, accumulate y-error, step x each iteration'),

    # -- Pattern mode (color 0xF5): read pixel from secondary buffer --
    ('LABEL_FAACBF', 'DrawLine_Impl_PatternSetup',
     'Pattern line setup: color 0xF5 reads source pixels from VRAM at 0x030452'),

    ('LABEL_FAACF1', 'DrawLine_Impl_PatternVertLoop',
     'Pattern vertical line loop: read source pixel, write to dest buffer'),

    ('LABEL_FAAD32', 'DrawLine_Impl_PatternNonVert',
     'Pattern mode: non-vertical line handling'),

    ('LABEL_FAAD7E', 'DrawLine_Impl_PatternHorzNegDir',
     'Pattern horizontal line: negative y-dir source pixel copy'),

    ('LABEL_FAADA7', 'DrawLine_Impl_PatternHorzMemcpy',
     'Pattern horizontal: call memcpy-like copy from source buffer'),

    ('LABEL_FAADB1', 'DrawLine_Impl_PatternDiagCheck',
     'Pattern diagonal: check steep vs shallow, dispatch'),

    ('LABEL_FAADF0', 'DrawLine_Impl_PatternSteepLoop',
     'Pattern steep line loop: copy source pixel for each step'),

    ('LABEL_FAAE55', 'DrawLine_Impl_PatternShallowSetup',
     'Pattern shallow line setup: compute y-step fraction'),

    ('LABEL_FAAE90', 'DrawLine_Impl_PatternShallowLoop',
     'Pattern shallow line loop: copy source pixel for each step'),

    ('LABEL_FAAEEC', 'DrawLine_Impl_BuildDirtyRect',
     'Build dirty rect from start/end points, call SetChangeRect'),

    ('LABEL_FAAF0D', 'DrawLine_Impl_Return',
     'Pop registers, restore stack, return from DrawLine_Impl'),

    # ==================================================================
    # DrawLineEx (FAAF48-FAB26C)
    # Extended line drawing with multiple drawing modes (write, XOR, etc).
    # Uses Bresenham with separate code paths for vertical, horizontal,
    # steep, and shallow lines.  Mode 0x201=write, 0x205=XOR.
    # ==================================================================

    ('LABEL_FAAF48', 'DrawLineEx_XStepPositive',
     'X step is positive (x2 >= x1) for DrawLineEx'),

    ('LABEL_FAAF70', 'DrawLineEx_YStepPositive',
     'Y step is positive (y2 >= y1) for DrawLineEx'),

    ('LABEL_FAAF8A', 'DrawLineEx_CalcDxReverse',
     'Calculate dx when x step is negative'),

    ('LABEL_FAAF94', 'DrawLineEx_CalcDxDone',
     'Extend dx result to 32-bit'),

    ('LABEL_FAAFAA', 'DrawLineEx_CalcDyReverse',
     'Calculate dy when y step is negative'),

    ('LABEL_FAAFAC', 'DrawLineEx_CalcDyDone',
     'Extend dy; check if both dx,dy are zero (degenerate line)'),

    ('LABEL_FAAFC0', 'DrawLineEx_CopyStartPos',
     'Copy start position to locals; check if dx is non-zero'),

    # -- Vertical line: dx == 0 --
    ('LABEL_FAAFE5', 'DrawLineEx_VertLoop',
     'Vertical line loop: dispatch to write or XOR mode per pixel'),

    ('LABEL_FAB01A', 'DrawLineEx_VertAdvance',
     'Vertical line: advance y, increment counter, check completion'),

    ('LABEL_FAB030', 'DrawLineEx_VertXorPixel',
     'Vertical line XOR mode: compute VRAM address and XOR pixel'),

    # -- Horizontal line: dy == 0 --
    ('LABEL_FAB056', 'DrawLineEx_HorzCheck',
     'Check dy==0 for horizontal line fast path'),

    ('LABEL_FAB06F', 'DrawLineEx_HorzLoop',
     'Horizontal line loop: dispatch to write or XOR mode per pixel'),

    ('LABEL_FAB0A4', 'DrawLineEx_HorzAdvance',
     'Horizontal line: advance x, increment counter, check completion'),

    ('LABEL_FAB0BA', 'DrawLineEx_HorzXorPixel',
     'Horizontal line XOR mode: compute VRAM address and XOR pixel'),

    # -- Diagonal line: both dx,dy non-zero --
    ('LABEL_FAB0E0', 'DrawLineEx_DiagSetup',
     'Diagonal line setup: compute step fractions for Bresenham'),

    # -- Steep diagonal (dy > dx): y-major --
    ('LABEL_FAB135', 'DrawLineEx_SteepLoop',
     'Steep line loop: load mode, compute VRAM addr, dispatch write/XOR'),

    ('LABEL_FAB169', 'DrawLineEx_SteepAdvance',
     'Steep line: accumulate x-error, step y, check completion'),

    ('LABEL_FAB18C', 'DrawLineEx_SteepXorPixel',
     'Steep line XOR mode: compute address and XOR pixel value'),

    # -- Shallow diagonal (dx >= dy): x-major --
    ('LABEL_FAB198', 'DrawLineEx_ShallowSetup',
     'Shallow line setup: compute y-step fraction for x-major stepping'),

    ('LABEL_FAB1E0', 'DrawLineEx_ShallowLoop',
     'Shallow line loop: load mode, compute VRAM addr, dispatch write/XOR'),

    ('LABEL_FAB216', 'DrawLineEx_ShallowAdvance',
     'Shallow line: accumulate y-error, step x, check completion'),

    ('LABEL_FAB236', 'DrawLineEx_BuildDirtyRect',
     'Build dirty rect from endpoints, call SetChangeRect'),

    ('LABEL_FAB25D', 'DrawLineEx_ShallowXorPixel',
     'Shallow line XOR mode: compute address and XOR pixel value'),

    ('LABEL_FAB26C', 'DrawLineEx_Return',
     'Pop registers, restore stack, retd from DrawLineEx'),

    # ==================================================================
    # DrawBox (FAB295-FAB3D9)
    # Fill a rectangle with a solid color on OFFSCREEN_BUFFER_1.
    # ==================================================================

    ('LABEL_FAB295', 'DrawBox_DeferredPath',
     'DrawBox deferred-rendering: allocate param block, copy bbox, enqueue'),

    ('LABEL_FAB2B6', 'DrawBox_Return',
     'Common return point for DrawBox'),

    ('LABEL_FAB2BA', 'DrawBox_ParamBlock',
     'DrawBox parameter block template (21 bytes)'),

    ('LABEL_FAB2CF', 'DrawBox_Impl',
     'DrawBox inner implementation: clip, fill rows with Memset or pattern copy'),

    ('LABEL_FAB2FE', 'DrawBox_Impl_ClipYMin',
     'Clip y_min to 0 if negative'),

    ('LABEL_FAB30B', 'DrawBox_Impl_ClipXMin',
     'Clip x_min to 0 if negative'),

    ('LABEL_FAB315', 'DrawBox_Impl_ClipXMax',
     'Clip x_max to 319 if >= 320'),

    ('LABEL_FAB31F', 'DrawBox_Impl_ClipYMax',
     'Clip y_max to 239 if >= 240'),

    ('LABEL_FAB363', 'DrawBox_Impl_FillRowLoop',
     'Solid fill: Memset one row, advance VRAM pointer by 320, repeat'),

    ('LABEL_FAB38A', 'DrawBox_Impl_PatternSetup',
     'Pattern fill (color 0xF5): set up source buffer pointer at 0x030452'),

    ('LABEL_FAB3A4', 'DrawBox_Impl_PatternRowLoop',
     'Pattern fill: copy one row from source buffer, advance, repeat'),

    ('LABEL_FAB3D3', 'DrawBox_Impl_SetChangeRect',
     'Call SetChangeRect with the filled bounding box'),

    ('LABEL_FAB3D9', 'DrawBox_Impl_Return',
     'Pop registers, restore stack, return from DrawBox_Impl'),

    # ==================================================================
    # DrawFrame (FAB400-FAB7FE)
    # Draw rectangle outline (4 edges) using solid color or pattern.
    # ==================================================================

    ('LABEL_FAB400', 'DrawFrame_DeferredPath',
     'DrawFrame deferred-rendering: allocate param block, enqueue'),

    ('LABEL_FAB421', 'DrawFrame_Return',
     'Common return point for DrawFrame'),

    ('LABEL_FAB425', 'DrawFrame_ParamBlock',
     'DrawFrame parameter block template (21 bytes)'),

    ('LABEL_FAB43A', 'DrawFrame_Impl',
     'DrawFrame inner implementation: clip bbox, draw 4 edges'),

    ('LABEL_FAB459', 'DrawFrame_Impl_ClipYMin',
     'Clip y_min to 0 if negative'),

    ('LABEL_FAB466', 'DrawFrame_Impl_ClipXMin',
     'Clip x_min to 0 if negative'),

    ('LABEL_FAB47B', 'DrawFrame_Impl_ClipXMax',
     'Clip x_max to 319 if >= 320'),

    ('LABEL_FAB490', 'DrawFrame_Impl_ClipYMax',
     'Clip y_max to 239 if >= 240'),

    # -- Solid color path --
    ('LABEL_FAB4EF', 'DrawFrame_Impl_SolidTwoEdges',
     'Solid: draw top+bottom edges with Memset, then vertical sides'),

    ('LABEL_FAB570', 'DrawFrame_Impl_SolidYStepPositive',
     'Determine y-step direction for vertical side drawing'),

    ('LABEL_FAB5BB', 'DrawFrame_Impl_SolidOneSideLoop',
     'Solid: draw one vertical side (same x for both left/right)'),

    ('LABEL_FAB5CF', 'DrawFrame_Impl_SolidOneSideCheck',
     'Check if row index has reached y_max for one-sided loop'),

    ('LABEL_FAB5E0', 'DrawFrame_Impl_SolidTwoSideLoop',
     'Solid: draw both left and right vertical sides simultaneously'),

    ('LABEL_FAB617', 'DrawFrame_Impl_SolidTwoSideCheck',
     'Check if row index has reached y_max for two-sided loop'),

    # -- Pattern (0xF5) path --
    ('LABEL_FAB628', 'DrawFrame_Impl_PatternSetup',
     'Pattern frame: setup VRAM source offsets for edge drawing'),

    ('LABEL_FAB66D', 'DrawFrame_Impl_PatternTwoEdges',
     'Pattern: draw top+bottom edges by copying from source buffer'),

    ('LABEL_FAB6F8', 'DrawFrame_Impl_PatternYStepPositive',
     'Pattern: determine y-step direction for vertical sides'),

    ('LABEL_FAB74E', 'DrawFrame_Impl_PatternOneSideLoop',
     'Pattern: draw one vertical side from source buffer'),

    ('LABEL_FAB774', 'DrawFrame_Impl_PatternOneSideCheck',
     'Pattern: check completion for one-sided loop'),

    ('LABEL_FAB784', 'DrawFrame_Impl_PatternTwoSideSetup',
     'Pattern: setup pointers for drawing both vertical sides'),

    ('LABEL_FAB7A4', 'DrawFrame_Impl_PatternTwoSideLoop',
     'Pattern: draw both left and right sides from source buffer'),

    ('LABEL_FAB7F0', 'DrawFrame_Impl_PatternTwoSideCheck',
     'Pattern: check completion for two-sided loop'),

    ('LABEL_FAB7FE', 'DrawFrame_Impl_SetChangeRect',
     'Call SetChangeRect, pop registers, return from DrawFrame_Impl'),

    # ==================================================================
    # DrawFrameEx (FAB820-FABA4E)
    # Extended frame drawing with XOR support.  Mode 0x201=write, 0x205=XOR.
    # ==================================================================

    ('LABEL_FAB820', 'DrawFrameEx_ClipYMin',
     'Clip y_min to 0 if negative'),

    ('LABEL_FAB82A', 'DrawFrameEx_ClipXMin',
     'Clip x_min to 0 if negative'),

    ('LABEL_FAB83D', 'DrawFrameEx_ClipXMax',
     'Clip x_max to 319 if >= 320'),

    ('LABEL_FAB850', 'DrawFrameEx_ClipYMax',
     'Clip y_max to 239 if >= 240'),

    # -- Single-row frame (y_min == y_max): draw top edge only --
    ('LABEL_FAB863', 'DrawFrameEx_SingleRowLoop',
     'Single-row: loop across x, dispatch write/XOR per pixel'),

    ('LABEL_FAB893', 'DrawFrameEx_SingleRowAdvance',
     'Single-row: increment x, check against x_max'),

    ('LABEL_FAB89F', 'DrawFrameEx_SingleRowXorPixel',
     'Single-row XOR mode: XOR pixel at computed VRAM address'),

    # -- Multi-row frame (y_min != y_max): draw top+bottom edges, then sides --
    ('LABEL_FAB8AD', 'DrawFrameEx_MultiRowTopBottom',
     'Multi-row: draw top and bottom edges simultaneously per x column'),

    ('LABEL_FAB8B6', 'DrawFrameEx_TopBottomLoop',
     'Top/bottom edge loop: compute row offsets for both y_min and y_max'),

    ('LABEL_FAB908', 'DrawFrameEx_TopBottomAdvance',
     'Top/bottom: increment x, check against x_max'),

    ('LABEL_FAB911', 'DrawFrameEx_SidesSetup',
     'Setup for vertical side drawing: compute y-step direction'),

    ('LABEL_FAB923', 'DrawFrameEx_SidesStepComputed',
     'Y-step computed; check if sides are zero-height'),

    ('LABEL_FAB949', 'DrawFrameEx_TopBottomXorPixel',
     'Top/bottom XOR mode: XOR both top and bottom edge pixels'),

    # -- Vertical sides when x_min == x_max (single column) --
    ('LABEL_FAB979', 'DrawFrameEx_SingleColLoop',
     'Single-column sides: one vertical edge per pixel row'),

    ('LABEL_FAB9AA', 'DrawFrameEx_SingleColAdvance',
     'Single-column: increment y'),

    ('LABEL_FAB9AC', 'DrawFrameEx_SingleColCheck',
     'Single-column: check if y has reached y_max'),

    ('LABEL_FAB9BA', 'DrawFrameEx_SingleColXorPixel',
     'Single-column XOR mode: XOR pixel at computed VRAM address'),

    # -- Vertical sides when x_min != x_max (two columns) --
    ('LABEL_FAB9D7', 'DrawFrameEx_TwoColSetup',
     'Two-column sides: store y-step, fall into loop'),

    ('LABEL_FAB9DC', 'DrawFrameEx_TwoColLoop',
     'Two-column loop: draw left and right side pixels per row'),

    ('LABEL_FABA1B', 'DrawFrameEx_TwoColAdvance',
     'Two-column: increment y'),

    ('LABEL_FABA1D', 'DrawFrameEx_TwoColCheck',
     'Two-column: check if y has reached y_max'),

    ('LABEL_FABA29', 'DrawFrameEx_SetChangeRect',
     'Call SetChangeRect for the frame bounding box'),

    ('LABEL_FABA2E', 'DrawFrameEx_TwoColXorPixel',
     'Two-column XOR mode: XOR left and right side pixels'),

    ('LABEL_FABA4E', 'DrawFrameEx_Return',
     'Pop registers, restore stack, retd from DrawFrameEx'),

    # ==================================================================
    # MovePixels (FABA75-FABB6E)
    # Copy a rectangular pixel region within the offscreen buffer.
    # ==================================================================

    ('LABEL_FABA75', 'MovePixels_DeferredPath',
     'MovePixels deferred-rendering: allocate param block, enqueue'),

    ('LABEL_FABA9C', 'MovePixels_Return',
     'Common return point for MovePixels'),

    ('LABEL_FABAA0', 'MovePixels_ParamBlock',
     'MovePixels parameter block template (21 bytes)'),

    ('LABEL_FABAB5', 'MovePixels_Impl',
     'MovePixels inner implementation: compute delta, nested row/col copy'),

    ('LABEL_FABAED', 'MovePixels_Impl_RowLoop',
     'Outer loop: iterate rows'),

    ('LABEL_FABAF6', 'MovePixels_Impl_ColLoop',
     'Inner loop: copy one pixel from src to dst within OFFSCREEN_BUFFER_1'),

    ('LABEL_FABB60', 'MovePixels_Impl_RowAdvance',
     'Increment row counter, check if all rows are done'),

    ('LABEL_FABB6B', 'MovePixels_Impl_SetChangeRect',
     'Call SetChangeRect for the moved region'),

    ('LABEL_FABB6E', 'MovePixels_Impl_Return',
     'Pop registers, restore stack, return from MovePixels_Impl'),

    # ==================================================================
    # DrawWall (FABB8A-FABBE7)
    # Copy full-screen wallpaper to offscreen buffer.
    # ==================================================================

    ('LABEL_FABB8A', 'DrawWall_DirectPath',
     'DrawWall direct: set copy-pending flags and wait for VRAM sync'),

    ('LABEL_FABB9A', 'DrawWall_WaitVblankBefore',
     'Wait loop: yield until VRAM access is clear before direct copy'),

    ('LABEL_FABBAF', 'DrawWall_SetCopyFlag',
     'Set copy-in-progress flag and wait for it to take effect'),

    ('LABEL_FABBBF', 'DrawWall_WaitVblankAfter',
     'Wait loop: yield until VRAM access resumes after flag set'),

    ('LABEL_FABBD4', 'DrawWall_Deferred',
     'DrawWall deferred path: allocate small param block, enqueue'),

    ('LABEL_FABBE7', 'DrawWall_DoCopy',
     'Perform the actual copy: 2x 38400 bytes from source to OFFSCREEN_BUFFER_1'),

    # ==================================================================
    # DrawBitmap (FABC5E-FABE0E)
    # Render indexed bitmap/sprite with transparency (0xF7 = transparent).
    # ==================================================================

    ('LABEL_FABC5E', 'DrawBitmap_DeferredPath',
     'DrawBitmap deferred-rendering: allocate param block, enqueue'),

    ('LABEL_FABC7F', 'DrawBitmap_Return',
     'Common return point for DrawBitmap'),

    ('LABEL_FABC83', 'DrawBitmap_ParamBlock',
     'DrawBitmap parameter block template (21 bytes)'),

    ('LABEL_FABC98', 'DrawBitmap_Impl',
     'DrawBitmap inner implementation: bounds check, lookup table entry, render'),

    ('LABEL_FABCCB', 'DrawBitmap_Impl_RowLoop',
     'Outer loop: iterate bitmap rows; compute VRAM row base address'),

    ('LABEL_FABD12', 'DrawBitmap_Impl_PixelPair',
     'Process one word (2 packed pixels); check transparency for each'),

    ('LABEL_FABD2B', 'DrawBitmap_Impl_HiTransparent',
     'High byte is 0xF7: only draw low pixel'),

    ('LABEL_FABD5A', 'DrawBitmap_Impl_LoTransparent',
     'Low byte is 0xF7: only draw high pixel'),

    ('LABEL_FABD87', 'DrawBitmap_Impl_PixelAdvance',
     'Advance source ptr by 2, dest ptr by 2, column counter'),

    ('LABEL_FABD90', 'DrawBitmap_Impl_ColLoop',
     'Inner loop: iterate width/2 pixel pairs per row'),

    ('LABEL_FABDDB', 'DrawBitmap_Impl_OddPixelSkip',
     'Odd-width: advance source past the odd trailing pixel'),

    ('LABEL_FABDDD', 'DrawBitmap_Impl_RowAdvance',
     'Increment row counter'),

    ('LABEL_FABDE0', 'DrawBitmap_Impl_RowCheck',
     'Check if current row < height, continue or exit'),

    ('LABEL_FABDEB', 'DrawBitmap_Impl_BuildDirtyRect',
     'Build dirty rect from position + dimensions, call SetChangeRect'),

    ('LABEL_FABE0E', 'DrawBitmap_Impl_Return',
     'Pop registers, restore stack, return from DrawBitmap_Impl'),

    # ==================================================================
    # DrawBitmapFast (FABE35-FABF3A)
    # Optimized bitmap drawing without transparency check.
    # ==================================================================

    ('LABEL_FABE35', 'DrawBitmapFast_DeferredPath',
     'DrawBitmapFast deferred-rendering: allocate param block, enqueue'),

    ('LABEL_FABE56', 'DrawBitmapFast_Return',
     'Common return point for DrawBitmapFast'),

    ('LABEL_FABE5A', 'DrawBitmapFast_ParamBlock',
     'DrawBitmapFast parameter block template (21 bytes)'),

    ('LABEL_FABE6F', 'DrawBitmapFast_Impl',
     'DrawBitmapFast inner impl: lookup bitmap, memcpy rows without transparency'),

    ('LABEL_FABEC9', 'DrawBitmapFast_Impl_RowLoop',
     'Row loop: if y < 240, memcpy row data; advance VRAM ptr by 320'),

    ('LABEL_FABF0D', 'DrawBitmapFast_Impl_RowCheck',
     'Check if current row < height, continue or exit'),

    ('LABEL_FABF17', 'DrawBitmapFast_Impl_BuildDirtyRect',
     'Build dirty rect from position + dimensions, call SetChangeRect'),

    ('LABEL_FABF3A', 'DrawBitmapFast_Impl_Return',
     'Pop registers, restore stack, return from DrawBitmapFast_Impl'),

    # ==================================================================
    # DrawIcons (FABF61-FAC077)
    # Draw icon sprite from icon descriptor table at 0x938000.
    # Icons are 12x24 pixels, drawn with palette lookup.
    # ==================================================================

    ('LABEL_FABF61', 'DrawIcons_DeferredPath',
     'DrawIcons deferred-rendering: allocate param block, enqueue'),

    ('LABEL_FABF82', 'DrawIcons_Return',
     'Common return point for DrawIcons'),

    ('LABEL_FABF86', 'DrawIcons_ParamBlock',
     'DrawIcons parameter block template (21 bytes)'),

    ('LABEL_FABF9B', 'DrawIcons_Impl',
     'DrawIcons inner implementation: lookup icon, render 12x24 with palette'),

    ('LABEL_FAC00B', 'DrawIcons_Impl_RowLoop',
     'Outer loop: iterate 24 rows; skip if y >= 240'),

    ('LABEL_FAC018', 'DrawIcons_Impl_ColLoop',
     'Inner loop: render 12 columns per row using palette at 0xEAABF2'),

    ('LABEL_FAC050', 'DrawIcons_Impl_BuildDirtyRect',
     'Build dirty rect from position + icon dimensions, call SetChangeRect'),

    ('LABEL_FAC077', 'DrawIcons_Impl_Return',
     'Pop registers, restore stack, return from DrawIcons_Impl'),

    # ==================================================================
    # DrawFrameSP (FAC0A4-FAC1E8)
    # Draw styled frame sprite using descriptor table at 0x934000.
    # ==================================================================

    ('LABEL_FAC0A4', 'DrawFrameSP_DeferredPath',
     'DrawFrameSP deferred-rendering: allocate param block, enqueue'),

    ('LABEL_FAC0CB', 'DrawFrameSP_Return',
     'Common return point for DrawFrameSP'),

    ('LABEL_FAC0CF', 'DrawFrameSP_ParamBlock',
     'DrawFrameSP parameter block template (24 bytes)'),

    ('LABEL_FAC0E7', 'DrawFrameSP_Impl',
     'DrawFrameSP inner impl: lookup sprite, render with transparency/color map'),

    ('LABEL_FAC123', 'DrawFrameSP_Impl_RowLoop',
     'Outer loop: iterate rows; compute dest VRAM position'),

    ('LABEL_FAC149', 'DrawFrameSP_Impl_ColLoop',
     'Inner loop: read sprite pixel, skip 0xF7, map 0xF6 to foreground color'),

    ('LABEL_FAC18A', 'DrawFrameSP_Impl_DrawNormal',
     'Normal pixel: copy sprite pixel directly to VRAM'),

    ('LABEL_FAC198', 'DrawFrameSP_Impl_PixelAdvance',
     'Advance source pointer, column counter'),

    ('LABEL_FAC1A2', 'DrawFrameSP_Impl_OddWidthPad',
     'Handle odd-width sprite: skip padding byte if width is odd'),

    ('LABEL_FAC1B4', 'DrawFrameSP_Impl_RowAdvance',
     'Increment row counter, check against height'),

    ('LABEL_FAC1C2', 'DrawFrameSP_Impl_BuildDirtyRect',
     'Build dirty rect from position + sprite dimensions, call SetChangeRect'),

    ('LABEL_FAC1E8', 'DrawFrameSP_Impl_Return',
     'Restore stack, return from DrawFrameSP_Impl'),

    # ==================================================================
    # DrawBitmapSP (FAC217-FAC3D4)
    # Bitmap with special per-pixel rendering (packed word pixels).
    # ==================================================================

    ('LABEL_FAC217', 'DrawBitmapSP_DeferredPath',
     'DrawBitmapSP deferred-rendering: allocate param block, enqueue'),

    ('LABEL_FAC244', 'DrawBitmapSP_Return',
     'Common return / retd for DrawBitmapSP'),

    ('LABEL_FAC268', 'DrawBitmapSP_Impl',
     'DrawBitmapSP inner impl: bounds check, iterate rows/pixel-pairs'),

    ('LABEL_FAC293', 'DrawBitmapSP_Impl_RowLoop',
     'Outer loop: compute VRAM row base, iterate pixel pairs'),

    ('LABEL_FAC2CD', 'DrawBitmapSP_Impl_PixelPair',
     'Process one word (2 packed pixels); check 0xF7 transparency'),

    ('LABEL_FAC2E9', 'DrawBitmapSP_Impl_HiTransparent',
     'High byte is 0xF7: only draw low pixel to VRAM'),

    ('LABEL_FAC318', 'DrawBitmapSP_Impl_LoTransparent',
     'Low byte is 0xF7: only draw high pixel to VRAM'),

    ('LABEL_FAC348', 'DrawBitmapSP_Impl_PixelAdvance',
     'Advance source ptr by 2, dest VRAM ptr by 2, column counter'),

    ('LABEL_FAC351', 'DrawBitmapSP_Impl_ColLoop',
     'Inner loop: iterate width/2 pixel pairs per row'),

    ('LABEL_FAC39E', 'DrawBitmapSP_Impl_OddPixelAdvance',
     'Odd-width trailing pixel: advance source ptr by 2'),

    ('LABEL_FAC3A3', 'DrawBitmapSP_Impl_RowAdvance',
     'Increment row counter, check against height'),

    ('LABEL_FAC3AF', 'DrawBitmapSP_Impl_BuildDirtyRect',
     'Build dirty rect, call SetChangeRect'),

    ('LABEL_FAC3D4', 'DrawBitmapSP_Impl_Return',
     'Pop registers, restore stack, retd from DrawBitmapSP_Impl'),

    # ==================================================================
    # DrawBitmapSPFast (FAC406-FAC502)
    # Fast bitmap SP without per-pixel transparency check.
    # ==================================================================

    ('LABEL_FAC406', 'DrawBitmapSPFast_DeferredPath',
     'DrawBitmapSPFast deferred-rendering: allocate param block, enqueue'),

    ('LABEL_FAC433', 'DrawBitmapSPFast_Return',
     'Common return / retd for DrawBitmapSPFast'),

    ('LABEL_FAC457', 'DrawBitmapSPFast_Impl',
     'DrawBitmapSPFast inner impl: memcpy rows without transparency check'),

    ('LABEL_FAC4A1', 'DrawBitmapSPFast_Impl_RowLoop',
     'Row loop: if y < 240, memcpy row data; advance pointers'),

    ('LABEL_FAC4DD', 'DrawBitmapSPFast_Impl_BuildDirtyRect',
     'Build dirty rect, call SetChangeRect'),

    ('LABEL_FAC502', 'DrawBitmapSPFast_Impl_Return',
     'Pop registers, restore stack, retd from DrawBitmapSPFast_Impl'),

    # ==================================================================
    # DrawBitmapSP2 (FAC53A-FAC690)
    # Bitmap SP variant with additional rendering parameters (mask-based).
    # ==================================================================

    ('LABEL_FAC53A', 'DrawBitmapSP2_DeferredPath',
     'DrawBitmapSP2 deferred-rendering: allocate param block, enqueue'),

    ('LABEL_FAC573', 'DrawBitmapSP2_Return',
     'Common return / retd for DrawBitmapSP2'),

    ('LABEL_FAC59D', 'DrawBitmapSP2_Impl',
     'DrawBitmapSP2 inner impl: bounds check, mask-based pixel rendering'),

    ('LABEL_FAC5C1', 'DrawBitmapSP2_Impl_RowLoop',
     'Outer loop: compute VRAM row, extract 16-pixel bitmask word'),

    ('LABEL_FAC608', 'DrawBitmapSP2_Impl_LoadMaskWord',
     'Load next 16-bit mask word from source data'),

    ('LABEL_FAC60B', 'DrawBitmapSP2_Impl_BitLoop',
     'Inner bit loop: test each bit of the mask word'),

    ('LABEL_FAC62F', 'DrawBitmapSP2_Impl_DrawPixel',
     'Mask bit set and within clip: draw foreground color pixel'),

    ('LABEL_FAC641', 'DrawBitmapSP2_Impl_BitAdvance',
     'Advance VRAM pointer, increment bit counter'),

    ('LABEL_FAC64D', 'DrawBitmapSP2_Impl_MaskWordAdvance',
     'Advance source by 2, increment mask-word counter'),

    ('LABEL_FAC654', 'DrawBitmapSP2_Impl_MaskWordCheck',
     'Check if all mask words processed for this row'),

    ('LABEL_FAC66C', 'DrawBitmapSP2_Impl_BuildDirtyRect',
     'Build dirty rect, call SetChangeRect'),

    ('LABEL_FAC690', 'DrawBitmapSP2_Impl_Return',
     'Pop registers, restore stack, retd from DrawBitmapSP2_Impl'),

    # ==================================================================
    # DrawBitmapFile (FAC6B9-FACAC3)
    # Load and render a BMP file from the filesystem.
    # Parses BMP headers, applies palette, renders to VRAM.
    # ==================================================================

    ('LABEL_FAC6B9', 'DrawBitmapFile_DeferredPath',
     'DrawBitmapFile deferred-rendering: allocate param block, enqueue'),

    ('LABEL_FAC6DA', 'DrawBitmapFile_Return',
     'Common return point for DrawBitmapFile'),

    ('LABEL_FAC6DE', 'DrawBitmapFile_ParamBlock',
     'DrawBitmapFile parameter block template (21 bytes)'),

    ('LABEL_FAC6F3', 'DrawBitmapFile_Impl',
     'DrawBitmapFile inner impl: open file, parse BMP header, render'),

    ('LABEL_FAC7AC', 'DrawBitmapFile_Impl_InitPalette',
     'Initialize 256-entry palette table to 0xFF000000 (default opaque black)'),

    ('LABEL_FAC7DF', 'DrawBitmapFile_Impl_LoadPalette',
     'Load BMP palette entries (BGR format) into 32-bit XRGB table'),

    ('LABEL_FAC821', 'DrawBitmapFile_Impl_ParseDimensions',
     'Parse BMP width/height, compute row stride and buffer allocation'),

    ('LABEL_FAC89C', 'DrawBitmapFile_Impl_SkipExtraRows',
     'Skip rows if image height > 240 (advance file pointer)'),

    ('LABEL_FAC8AE', 'DrawBitmapFile_Impl_ClampHeight',
     'Clamp height to 240'),

    ('LABEL_FAC8B6', 'DrawBitmapFile_Impl_ComputeStride',
     'Compute display stride (320 * height) for bottom-up BMP layout'),

    ('LABEL_FAC8E7', 'DrawBitmapFile_Impl_DecodeRowLoop',
     'Row decode loop: read row from file, apply palette, copy to temp buffer'),

    ('LABEL_FAC923', 'DrawBitmapFile_Impl_TileRow',
     'If width < 320: tile the row across screen width'),

    ('LABEL_FAC939', 'DrawBitmapFile_Impl_TileLoop',
     'Tile loop: memcpy row at each tile offset'),

    ('LABEL_FAC967', 'DrawBitmapFile_Impl_TileRemainder',
     'Copy remaining pixels after last full tile'),

    ('LABEL_FAC980', 'DrawBitmapFile_Impl_RowCopy',
     'Memcpy decoded row to temporary buffer, advance file pointer'),

    ('LABEL_FAC9A5', 'DrawBitmapFile_Impl_FillRemaining',
     'If height < 240: fill remaining screen rows from decoded data'),

    ('LABEL_FAC9D4', 'DrawBitmapFile_Impl_FillLoop',
     'Fill loop: memcpy 320 bytes per row to extend short images'),

    ('LABEL_FACA00', 'DrawBitmapFile_Impl_CopyToVRAM',
     'Free temp buffer, copy decoded image to OFFSCREEN_BUFFER_1'),

    ('LABEL_FACA65', 'DrawBitmapFile_Impl_VRAMRowLoop',
     'VRAM copy row loop: memcpy 320 bytes per row to VRAM'),

    ('LABEL_FACA97', 'DrawBitmapFile_Impl_BuildDirtyRect',
     'Build dirty rect from image dimensions, call SetChangeRect'),

    ('LABEL_FACAC3', 'DrawBitmapFile_Impl_Return',
     'Pop registers, restore stack, return from DrawBitmapFile_Impl'),

    # ==================================================================
    # DrawString (FACAFF-FACEA3)
    # Core text rendering: parse string, look up font glyphs, render
    # 1bpp glyph bitmaps to OFFSCREEN_BUFFER_1.
    # Font table at 0x945C00 (16 bytes/entry).
    # ==================================================================

    ('LABEL_FACAFF', 'DrawString_DeferredPath',
     'DrawString deferred-rendering: measure string, allocate, copy, enqueue'),

    ('LABEL_FACB62', 'DrawString_Return',
     'Common return / retd for DrawString'),

    ('LABEL_FACB8D', 'DrawString_DeferredDispatch',
     'Deferred dispatch epilogue: free string buffer, return'),

    ('LABEL_FACB95', 'DrawString_Impl',
     'DrawString inner implementation: clip, iterate chars, render glyphs'),

    ('LABEL_FACBC2', 'DrawString_Impl_ClipYMin',
     'Clip y_min to 0 if negative'),

    ('LABEL_FACBD1', 'DrawString_Impl_ClipXMin',
     'Clip x_min to 0 if negative'),

    ('LABEL_FACBE2', 'DrawString_Impl_ClipXMax',
     'Clip x_max to 319 if >= 320'),

    ('LABEL_FACBF4', 'DrawString_Impl_ClipYMax',
     'Clip y_max to 239 if >= 240; copy cursor state to locals'),

    ('LABEL_FACC0E', 'DrawString_Impl_ClipCursorXMin',
     'Clip cursor X min to 0 if negative'),

    ('LABEL_FACC1B', 'DrawString_Impl_ClipCursorYMin',
     'Clip cursor Y min to 0 if negative'),

    ('LABEL_FACC4E', 'DrawString_Impl_FixedWidthKerning',
     'No kerning table (xiz==0): store fixed glyph width and ascent'),

    ('LABEL_FACC51', 'DrawString_Impl_FontSetup',
     'Store glyph data pointer; save/restore cursor state in local frame'),

    ('LABEL_FACC80', 'DrawString_Impl_ClampDirtyTop',
     'Clamp dirty-rect top to clip-rect top'),

    ('LABEL_FACC88', 'DrawString_Impl_ClampDirtyBottom',
     'Clamp dirty-rect bottom to clip-rect bottom; compute text width'),

    ('LABEL_FACCB5', 'DrawString_Impl_VariableWidthLoop',
     'Variable-width: iterate string chars, sum kerning-table widths'),

    ('LABEL_FACCBD', 'DrawString_Impl_KerningLookup',
     'Look up character width from kerning table (4 bytes per char)'),

    ('LABEL_FACCE4', 'DrawString_Impl_KerningDone',
     'Load final accumulated width from kerning loop'),

    ('LABEL_FACCE7', 'DrawString_Impl_ComputeDirtyRect',
     'Add text width to cursor x; set up full dirty-rect from text bounds'),

    ('LABEL_FACD02', 'DrawString_Impl_ClampDirtyLeft',
     'Clamp dirty-rect left to clip-rect left'),

    ('LABEL_FACD11', 'DrawString_Impl_ClampDirtyRight',
     'Clamp dirty-rect right to clip-rect right'),

    ('LABEL_FACD22', 'DrawString_Impl_ClampDirtyRight2',
     'Secondary right-edge clamp against clip-rect'),

    ('LABEL_FACD33', 'DrawString_Impl_FillBackground',
     'If background color != 0xF7: fill text bounding box with DrawBox_Impl'),

    ('LABEL_FACD4D', 'DrawString_Impl_CharLoop',
     'Main character loop: process each char in the string'),

    ('LABEL_FACD70', 'DrawString_Impl_CharVariableWidth',
     'Variable-width char: look up glyph width and data offset from kerning table'),

    ('LABEL_FACD9E', 'DrawString_Impl_GlyphSetup',
     'Initialize column counter for glyph rendering (8-pixel wide columns)'),

    ('LABEL_FACDAB', 'DrawString_Impl_ColumnLoop',
     'Column loop: iterate 8-pixel-wide glyph columns'),

    ('LABEL_FACDBF', 'DrawString_Impl_ColumnSetup',
     'Compute VRAM base for current glyph column; set row counter'),

    ('LABEL_FACDF5', 'DrawString_Impl_RowLoop',
     'Row loop: iterate glyph rows; skip if glyph byte is zero'),

    ('LABEL_FACE26', 'DrawString_Impl_PixelLoop',
     'Pixel loop: test each bit of glyph byte against clip bounds'),

    ('LABEL_FACE4C', 'DrawString_Impl_TestBit',
     'Test bit (MSB first): AND with bitmask, write fg color if set'),

    ('LABEL_FACE5B', 'DrawString_Impl_PixelAdvance',
     'Advance VRAM ptr, increment pixel-within-column counter'),

    ('LABEL_FACE63', 'DrawString_Impl_RowAdvance',
     'Advance glyph data ptr, advance VRAM by 320, increment row counter'),

    ('LABEL_FACE70', 'DrawString_Impl_RowCheck',
     'Check if current row < font height, continue row loop'),

    ('LABEL_FACE7C', 'DrawString_Impl_ColumnAdvance',
     'Advance cursor x by column width, increment column counter'),

    ('LABEL_FACE8D', 'DrawString_Impl_CharAdvance',
     'Advance string pointer, check next char for null terminator'),

    ('LABEL_FACE9B', 'DrawString_Impl_SetChangeRect',
     'Finalize dirty rect, call SetChangeRect'),

    ('LABEL_FACEA3', 'DrawString_Impl_Return',
     'Pop registers, restore stack, retd from DrawString_Impl'),

    # ==================================================================
    # DrawStringAlignment (FAD06E-FAD080)
    # Dispatch labels for alignment mode selection.
    # ==================================================================

    ('LABEL_FAD06E', 'DrawStringAlignment_LeftJustify',
     'Mode 1: dispatch to DrawStringLeftJustify'),

    ('LABEL_FAD078', 'DrawStringAlignment_RightJustify',
     'Mode 2: dispatch to DrawStringRightJustify'),

    ('LABEL_FAD080', 'DrawStringAlignment_Return',
     'Common return / retd for DrawStringAlignment'),

    # ==================================================================
    # DrawStringReverse (FAD0F7-FAD1D1)
    # Draw text with inverted colors; supports all alignment modes.
    # ==================================================================

    ('LABEL_FAD0F7', 'DrawStringReverse_AlignLeft',
     'Left-align: x = rect.left + 4'),

    ('LABEL_FAD102', 'DrawStringReverse_AlignRight',
     'Right-align: x = rect.right - 4 - text_width'),

    ('LABEL_FAD10F', 'DrawStringReverse_ComputeTextBox',
     'Compute text bounding box from cursor, width, ascent, descent'),

    ('LABEL_FAD14D', 'DrawStringReverse_ClampLeft',
     'Clamp text box left to rect left'),

    ('LABEL_FAD15A', 'DrawStringReverse_ClampLeftX',
     'Clamp text box left x to rect x'),

    ('LABEL_FAD166', 'DrawStringReverse_ClampRight',
     'Clamp text box right to rect right'),

    ('LABEL_FAD172', 'DrawStringReverse_ClampBottom',
     'Clamp text box bottom to rect bottom; check if visible'),

    ('LABEL_FAD1A9', 'DrawStringReverse_DrawNonPattern',
     'Non-pattern (fg != 0xF5): push colors swapped and call DrawString'),

    ('LABEL_FAD1B6', 'DrawStringReverse_DrawNoHighlight',
     'No highlight box: fill with bg, draw text with fg/bg swapped'),

    ('LABEL_FAD1CE', 'DrawStringReverse_CallDrawString',
     'Call DrawString with computed parameters'),

    ('LABEL_FAD1D1', 'DrawStringReverse_Return',
     'Pop registers, restore stack, retd from DrawStringReverse'),

    # ==================================================================
    # Utility predicates (FAD1D8-FAD213)
    # Shared helper functions used by many drawing routines.
    # ==================================================================

    ('LABEL_FAD1D8', 'IsPointOnScreen',
     'Check if point at (xwa) is within screen bounds (0..319, 0..239)'),

    ('LABEL_FAD1F1', 'IsPointOnScreen_OutOfBounds',
     'Return HL=0: point is outside screen bounds'),

    ('LABEL_FAD1F4', 'IsPointOnScreen_InBounds',
     'Return HL=1: point is within screen bounds'),

    ('LABEL_FAD1F7', 'IsColorValid',
     'Check if color value in WA is in valid range (0..255 or exactly 0x100)'),

    ('LABEL_FAD201', 'IsColorValid_Check256',
     'Check for special color value 0x100'),

    ('LABEL_FAD20D', 'IsColorValid_Valid',
     'Return HL=1: color is valid'),

    ('LABEL_FAD210', 'IsColorValid_Invalid',
     'Return HL=0: color is invalid'),

    ('LABEL_FAD213', 'ClampColorToRange',
     'Clamp BC to 0..255 range; return result in HL'),
]


def main():
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    src = os.path.join(base, 'maincpu', 'kn5000_v10_program.s')

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

    with open(src, 'wb') as f:
        f.write(content.encode('latin-1'))

    print(f'\nRenamed {renamed} labels in maincpu')


if __name__ == '__main__':
    main()
