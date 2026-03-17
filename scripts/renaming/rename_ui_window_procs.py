#!/usr/bin/env python3
"""
Rename LABEL_XXXXXX labels to semantic names in maincpu/ui/ui_window_procs.s.
Works in batches, verifying builds after each batch.
Uses binary I/O to preserve Latin-1 bytes.
"""

import os
import re
import sys
import subprocess

import time

REPO = "/mnt/shared/kn5000-roms-disasm"
TARGET_FILE = os.path.join(REPO, "maincpu/ui/ui_window_procs.s")

def atomic_replace(filepath, old_name, new_name):
    """Replace old_name with new_name in filepath using word-boundary-aware regex.
    Uses binary I/O to preserve Latin-1 bytes.
    Direct write (not rename) for NFS compatibility."""
    with open(filepath, 'rb') as f:
        content = f.read()
    old_bytes = old_name.encode('ascii')
    if old_bytes not in content:
        return False
    # Use regex with word boundaries to avoid substring matches
    pattern = rb'(?<![A-Za-z0-9_])' + re.escape(old_bytes) + rb'(?![A-Za-z0-9_])'
    new_bytes = new_name.encode('ascii')
    new_content = re.sub(pattern, new_bytes, content)
    if new_content == content:
        return False
    with open(filepath, 'wb') as f:
        f.write(new_content)
        f.flush()
        os.fsync(f.fileno())
    return True

def find_references(label):
    """Find all .s files in maincpu/ referencing a label (word-boundary match)."""
    result = subprocess.run(
        ["grep", "-rln", "--include=*.s", "-w", label, os.path.join(REPO, "maincpu/")],
        capture_output=True, text=True
    )
    files = [f.strip() for f in result.stdout.strip().split('\n') if f.strip()]
    return files

def rename_label(old_name, new_name):
    """Rename a label definition and all references across all files."""
    files = find_references(old_name)
    if not files:
        print(f"  WARNING: No files found referencing {old_name}")
        return False

    for filepath in files:
        atomic_replace(filepath, old_name, new_name)
    return True

def verify_build():
    """Run make clean + make all and verify 100% byte match. Returns True on success."""
    for attempt in range(3):
        subprocess.run(["sync"], capture_output=True)
        time.sleep(3)
        # Clean first to avoid stale NFS artifacts
        subprocess.run(["make", "clean"], cwd=REPO, capture_output=True, timeout=60)
        subprocess.run(["sync"], capture_output=True)
        time.sleep(3)
        result = subprocess.run(
            ["make", "all"],
            cwd=REPO,
            capture_output=True, text=True,
            timeout=300
        )
        output = result.stdout + result.stderr
        sim_count = output.count("Similarity: 100.00%")
        if sim_count == 6:
            return True
        # Print diagnostic info
        if "error:" in output:
            for line in output.split('\n'):
                if 'error:' in line:
                    print(f"  ERROR: {line.strip()}")
        if sim_count > 0:
            print(f"  Only {sim_count}/6 ROMs matched, retrying...")
        if attempt < 2:
            print(f"  Build attempt {attempt+1} incomplete, retrying after sleep...")
            time.sleep(5)
    return False

def commit_batch(batch_num, label_count, description):
    """Commit changes with descriptive message."""
    subprocess.run(["git", "add", "-A"], cwd=REPO)
    msg = f"""Rename {label_count} labels in ui_window_procs.s (batch {batch_num}): {description}

Semantic label renaming for UI window procedure handlers.
All references updated across maincpu/ files.
Build verified: 100% byte match on all 6 ROMs.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"""
    subprocess.run(["git", "commit", "-m", msg], cwd=REPO)

# ============================================================================
# Batch 1: WndScroll/ListBox area - lines 15-660 (event dispatch, scroll handlers)
# ============================================================================
BATCH_1 = {
    # WndScroll init loop - copies data to buffer
    "LABEL_F9B573": "WndScroll_CopyLoop",
    # WndScroll init - formats buffer string
    "LABEL_F9B588": "WndScroll_InitBuffer",
    # WndScroll - calls WindowProc, sets dials
    "LABEL_F9B5A6": "WndScroll_InitWindowProc",
    # WndScroll - calls WindowProc, inits selection tracking
    "LABEL_F9B5D4": "WndScroll_InitSelectionTrack",
    # WndScroll - basic WindowProc + return
    "LABEL_F9B600": "WndScroll_BasicWindowProc",
    # WndScroll - handles selection change event
    "LABEL_F9B60F": "WndScroll_HandleSelectionChange",
    # WndScroll - draw current selected item
    "LABEL_F9B6BE": "WndScroll_DrawCurrentItem",
    # WndScroll - repaint all items
    "LABEL_F9B74B": "WndScroll_RepaintAll",
    # WndScroll - draw single item in list
    "LABEL_F9B789": "WndScroll_DrawSingleItem",
    # WndScroll - item count check loop
    "LABEL_F9B7DC": "WndScroll_ItemCountCheck",
    # WndScroll - string copy to buffer and send scroll event
    "LABEL_F9BE36": "WndScroll_CopyStringAndSend",
    # WndScroll - copy string from source to buffer
    "LABEL_F9BE53": "WndScroll_CopyFromSource",
    # WndScroll - store caller pointer
    "LABEL_F9BE66": "WndScroll_StoreCallerPtr",
    # WndScroll - handle index change with optional radio select
    "LABEL_F9BE71": "WndScroll_HandleIndexChange",
    # WndScroll - send selection events for index change
    "LABEL_F9BE93": "WndScroll_SendSelectionEvents",
    # WndScroll - handle keystroke/char input
    "LABEL_F9BEC6": "WndScroll_HandleCharInput",
    # WndScroll - char is uppercase letter
    "LABEL_F9BF23": "WndScroll_CharIsUppercase",
    # WndScroll - char is lowercase letter
    "LABEL_F9BF33": "WndScroll_CharIsLowercase",
    # WndScroll - set category zero
    "LABEL_F9BF48": "WndScroll_SetCategoryZero",
    # WndScroll - compute char offset and send page events
    "LABEL_F9BF4A": "WndScroll_ComputeCharOffset",
    # WndScroll - char is space
    "LABEL_F9BF61": "WndScroll_CharIsSpace",
    # WndScroll - set space offset
    "LABEL_F9BF80": "WndScroll_SetSpaceOffset",
    # WndScroll - char is underscore
    "LABEL_F9BF89": "WndScroll_CharIsUnderscore",
    # WndScroll - set underscore offset
    "LABEL_F9BF9E": "WndScroll_SetUnderscoreOffset",
    # WndScroll - search through char table
    "LABEL_F9BFA7": "WndScroll_SearchCharTable",
    # WndScroll - compare char in table loop
    "LABEL_F9BFB3": "WndScroll_CompareCharLoop",
    # WndScroll - char mismatch, next
    "LABEL_F9BFE7": "WndScroll_CharMismatch",
    # WndScroll - check table end
    "LABEL_F9BFE9": "WndScroll_CheckTableEnd",
    # WndScroll - handle char set event
    "LABEL_F9C028": "WndScroll_HandleCharSet",
    # WndScroll - handle dial event and page
    "LABEL_F9C04D": "WndScroll_HandleDialPage",
    # WndScroll - clamp page count
    "LABEL_F9C0A3": "WndScroll_ClampPageCount",
    # WndScroll - check string for SP marker
    "LABEL_F9C0F2": "WndScroll_CheckSPMarker",
    # WndScroll - set event as non-SP
    "LABEL_F9C0FE": "WndScroll_SendConfirmEvent",
    # WndScroll - forward to WindowProc
    "LABEL_F9C119": "WndScroll_ForwardToWindowProc",
    # WndScroll - epilogue (pop xiz, adjust sp, ret)
    "LABEL_F9C125": "WndScroll_Epilogue",
}

# ============================================================================
# Batch 2: ModeEdit, TitleEdit, StringBox procs - lines 759-1055
# ============================================================================
BATCH_2 = {
    # ModeEditProc - handle event 0x1C0000D
    "LABEL_F9C15B": "ModeEdit_HandlePaint",
    # ModeEditProc - handle event 0x1C00011
    "LABEL_F9C1CA": "ModeEdit_HandleViewUpdate",
    # ModeEdit view update - handle event 0x6A (store view field 0)
    "LABEL_F9C268": "ModeEdit_StoreField0",
    # ModeEdit view update - handle event 0x61 (store field 1)
    "LABEL_F9C27A": "ModeEdit_StoreField1",
    # ModeEdit view update - handle event 0x6C (store field 2)
    "LABEL_F9C28D": "ModeEdit_StoreField2",
    # ModeEdit view update - handle event 0x58 (store field 3)
    "LABEL_F9C2A0": "ModeEdit_StoreField3",
    # ModeEditProc epilogue
    "LABEL_F9C2B5": "ModeEdit_Epilogue",
    # TitleEditProc - handle paint event
    "LABEL_F9C2ED": "TitleEdit_HandlePaint",
    # TitleEdit view update handler
    "LABEL_F9C35C": "TitleEdit_HandleViewUpdate",
    # TitleEdit - store field 0x6A
    "LABEL_F9C3FA": "TitleEdit_StoreFieldJA",
    # TitleEdit - store field 0x4E
    "LABEL_F9C40C": "TitleEdit_StoreFieldNE",
    # TitleEdit - store field 0x6C
    "LABEL_F9C41F": "TitleEdit_StoreFieldLC",
    # TitleEdit - store field 0x58
    "LABEL_F9C432": "TitleEdit_StoreFieldX",
    # TitleEdit epilogue
    "LABEL_F9C447": "TitleEdit_Epilogue",
    # StringBoxProc - paint handler
    "LABEL_F9C463": "StringBox_HandlePaint",
    # StringBoxProc epilogue
    "LABEL_F9C4B1": "StringBox_Epilogue",
}

# ============================================================================
# Batch 3: Label, Bitmap, Icon, Line, Frame, EditSw procs - lines 1057-1636
# ============================================================================
BATCH_3 = {
    # LabelProc - paint handler
    "LABEL_F9C4CC": "Label_HandlePaint",
    # LabelProc epilogue
    "LABEL_F9C50B": "Label_Epilogue",
    # BitmapProc - paint handler
    "LABEL_F9C525": "Bitmap_HandlePaint",
    # BitmapProc epilogue
    "LABEL_F9C548": "Bitmap_Epilogue",
    # VwUserBitmapProc - paint handler
    "LABEL_F9C562": "VwUserBitmap_HandlePaint",
    # VwUserBitmap - no bitmap data, draw fallback
    "LABEL_F9C5C5": "VwUserBitmap_DrawFallback",
    # VwUserBitmap - return zero
    "LABEL_F9C5CE": "VwUserBitmap_ReturnZero",
    # VwUserBitmap epilogue
    "LABEL_F9C5D0": "VwUserBitmap_Epilogue",
    # UserBitmapCheck - return bitmap table pointer
    "LABEL_F9C5F0": "UserBitmapCheck_ReturnTablePtr",
    # UserBitmapCheck - return size (0x18)
    "LABEL_F9C5F6": "UserBitmapCheck_ReturnSize",
    # VwUserBitmapByNameProc - handle create event
    "LABEL_F9C62F": "VwUserBitmapByName_HandleCreate",
    # VwUserBitmapByNameProc - handle paint event
    "LABEL_F9C639": "VwUserBitmapByName_HandlePaint",
    # VwUserBitmapByName - no file, draw default
    "LABEL_F9C68D": "VwUserBitmapByName_DrawDefault",
    # VwUserBitmapByName - handle close/palette change
    "LABEL_F9C695": "VwUserBitmapByName_HandleClose",
    # VwUserBitmapByName - call ViewableProc
    "LABEL_F9C6A3": "VwUserBitmapByName_CallViewable",
    # VwUserBitmapByName - return zero
    "LABEL_F9C6A7": "VwUserBitmapByName_ReturnZero",
    # VwUserBitmapByName epilogue
    "LABEL_F9C6A9": "VwUserBitmapByName_Epilogue",
    # IconProc - paint handler
    "LABEL_F9C6C4": "Icon_HandlePaint",
    # IconProc epilogue
    "LABEL_F9C71E": "Icon_Epilogue",
    # LineProc - paint handler
    "LABEL_F9C73B": "Line_HandlePaint",
    # LineProc - horizontal line
    "LABEL_F9C783": "Line_DrawHorizontal",
    # LineProc - draw and return
    "LABEL_F9C797": "Line_DrawAndReturn",
    # LineProc epilogue
    "LABEL_F9C7A0": "Line_Epilogue",
    # FrameProc - paint handler
    "LABEL_F9C7C9": "Frame_HandlePaint",
    # FrameProc - not visible, return 1
    "LABEL_F9C7D7": "Frame_DrawVisible",
    # FrameProc epilogue
    "LABEL_F9C7FA": "Frame_Epilogue",
    # GetClientFrame2 - process frame thickness
    "LABEL_F9C842": "ClientFrame2_ProcessThickness",
    # GetClientFrame2 - inset loop
    "LABEL_F9C85B": "ClientFrame2_InsetLoop",
    # DrawDesignFrame - draw frame loop
    "LABEL_F9C894": "DesignFrame_DrawLoop",
    # DrawDesignFrame epilogue
    "LABEL_F9C8B7": "DesignFrame_Epilogue",
    # EditSwProc - handle OK event
    "LABEL_F9C8DF": "EditSw_HandleOK",
    # EditSw - send dial down event
    "LABEL_F9C934": "EditSw_SendDialDown",
    # EditSw - send event (dial up or down)
    "LABEL_F9C93E": "EditSw_SendDialEvent",
    # EditSw - return zero after event
    "LABEL_F9C942": "EditSw_ReturnZero",
    # EditSw - index mismatch, forward to LabelProc
    "LABEL_F9C946": "EditSw_ForwardToLabel",
    # EditSw - call LabelProc
    "LABEL_F9C94E": "EditSw_CallLabelProc",
    # EditSw epilogue
    "LABEL_F9C951": "EditSw_Epilogue",
    # EditSw .byte data block
    "LABEL_F9C956": "EditSw_ByteData",
}

# ============================================================================
# Batch 4: DrawEditSw, TextBox, VwBox, PsParaBox - lines 1638-2060
# ============================================================================
BATCH_4 = {
    # DrawEditSw - check left edge, select string variant A
    "LABEL_F9CAB9": "DrawEditSw_SelectVariantA",
    # DrawEditSw - check right edge position
    "LABEL_F9CAC0": "DrawEditSw_SelectVariantC",
    # DrawEditSw - copy selected variant string
    "LABEL_F9CAC5": "DrawEditSw_CopyVariant",
    # DrawEditSw - position at left edge
    "LABEL_F9CAFE": "DrawEditSw_PositionLeft",
    # DrawEditSw - position at right edge
    "LABEL_F9CB13": "DrawEditSw_PositionRight",
    # DrawEditSw - position at bottom edge
    "LABEL_F9CB34": "DrawEditSw_FinalPosition",
    # DrawEditSw - invalid value, skip drawing
    "LABEL_F9CB61": "DrawEditSw_SkipDraw",
    # TextBoxProc - paint handler
    "LABEL_F9CB7E": "TextBox_HandlePaint",
    # TextBox - fill buffer with 0xF8
    "LABEL_F9CBCD": "TextBox_FillBufferLoop",
    # TextBox - setup wordwrap
    "LABEL_F9CBD7": "TextBox_SetupWordwrap",
    # TextBox - draw line loop
    "LABEL_F9CC2A": "TextBox_DrawLineLoop",
    # TextBox - check if more text
    "LABEL_F9CC7E": "TextBox_CheckMoreText",
    # TextBox - free buffer and return
    "LABEL_F9CCD5": "TextBox_FreeBuffer",
    # TextBox epilogue
    "LABEL_F9CCE1": "TextBox_Epilogue",
    # VwBoxProc - handle get focus event
    "LABEL_F9CD40": "VwBox_HandleGetFocus",
    # VwBoxProc - unfocused, use default color
    "LABEL_F9CD61": "VwBox_UseFocusColor",
    # VwBoxProc - call DrawDesignFrame
    "LABEL_F9CD68": "VwBox_CallDrawDesignFrame",
    # VwBoxProc - return zero from box draw
    "LABEL_F9CD6B": "VwBox_DrawReturnZero",
    # VwBoxProc - handle get width event
    "LABEL_F9CD6F": "VwBox_HandleGetWidth",
    # VwBoxProc - handle hit test event
    "LABEL_F9CD78": "VwBox_HandleHitTest",
    # VwBoxProc - handle get height event (offset 0x18)
    "LABEL_F9CD8C": "VwBox_HandleGetHeight",
    # VwBoxProc - handle get color event (offset 0x16)
    "LABEL_F9CD95": "VwBox_HandleGetColor",
    # VwBox - get view instance field at offset
    "LABEL_F9CD9C": "VwBox_GetFieldAtOffset",
    # VwBoxProc - default event handler
    "LABEL_F9CDA8": "VwBox_DefaultHandler",
    # PsParaBoxProc - handle confirm event
    "LABEL_F9CDE7": "PsParaBox_HandleConfirm",
    # PsParaBox - use event data as text
    "LABEL_F9CE3B": "PsParaBox_UseEventText",
    # PsParaBox - draw text with alignment
    "LABEL_F9CE48": "PsParaBox_DrawAligned",
    # PsParaBox - handle get text event (clear buffer)
    "LABEL_F9CE6D": "PsParaBox_HandleGetText",
    # PsParaBox - return zero
    "LABEL_F9CE75": "PsParaBox_ReturnZero",
    # PsParaBox epilogue
    "LABEL_F9CE77": "PsParaBox_Epilogue",
}

# ============================================================================
# Batch 5: AcLswBox, AcRamBox, AcTempoBox - lines 2061-2510
# ============================================================================
BATCH_5 = {
    # AcLswBox - handle create event
    "LABEL_F9CF17": "AcLswBox_HandleCreate",
    # AcLswBox - handle close event
    "LABEL_F9CF1F": "AcLswBox_HandleClose",
    # AcLswBox - call PsParaBoxProc
    "LABEL_F9CF25": "AcLswBox_CallPsParaBox",
    # AcLswBox - handle show/hide events
    "LABEL_F9CF2B": "AcLswBox_HandleShowHide",
    # AcLswBox - handle confirm/write-back event
    "LABEL_F9CF51": "AcLswBox_HandleWriteBack",
    # AcLswBox - handle scroll up event
    "LABEL_F9CFA2": "AcLswBox_HandleScrollUp",
    # AcLswBox - handle scroll down event
    "LABEL_F9CFCD": "AcLswBox_HandleScrollDown",
    # AcLswBox - handle page up event
    "LABEL_F9CFF7": "AcLswBox_HandlePageUp",
    # AcLswBox - handle page down event
    "LABEL_F9D028": "AcLswBox_HandlePageDown",
    # AcLswBox - default handler forward
    "LABEL_F9D05F": "AcLswBox_DefaultHandler",
    # AcLswBox epilogue
    "LABEL_F9D068": "AcLswBox_Epilogue",
    # AcRamBox - handle show/hide events
    "LABEL_F9D0FE": "AcRamBox_HandleShowHide",
    # AcRamBox - handle data refresh
    "LABEL_F9D107": "AcRamBox_HandleDataRefresh",
    # AcRamBox - handle write-back event
    "LABEL_F9D13A": "AcRamBox_HandleWriteBack",
    # AcRamBox - handle scroll up event
    "LABEL_F9D18B": "AcRamBox_HandleScrollUp",
    # AcRamBox - handle scroll down event
    "LABEL_F9D1B6": "AcRamBox_HandleScrollDown",
    # AcRamBox - handle page up event
    "LABEL_F9D1E0": "AcRamBox_HandlePageUp",
    # AcRamBox - handle page down event
    "LABEL_F9D211": "AcRamBox_HandlePageDown",
    # AcRamBox - default handler forward
    "LABEL_F9D248": "AcRamBox_DefaultHandler",
    # AcRamBox epilogue
    "LABEL_F9D251": "AcRamBox_Epilogue",
    # AcTempoBox - handle create event
    "LABEL_F9D298": "AcTempoBox_HandleCreate",
    # AcTempoBox - handle close event
    "LABEL_F9D2A1": "AcTempoBox_HandleClose",
    # AcTempoBox - call PsParaBox
    "LABEL_F9D2A8": "AcTempoBox_CallPsParaBox",
    # AcTempoBox - handle show/hide events
    "LABEL_F9D2AD": "AcTempoBox_HandleShowHide",
    # AcTempoBox - handle confirm event
    "LABEL_F9D2BE": "AcTempoBox_HandleConfirm",
    # AcTempoBox - match tempo ID 4 or 0x2200
    "LABEL_F9D2DC": "AcTempoBox_MatchTempoID",
    # AcTempoBox - send audio command for unknown tempo
    "LABEL_F9D303": "AcTempoBox_CopyTempoString",
    # AcTempoBox - send confirm event
    "LABEL_F9D313": "AcTempoBox_SendConfirmEvent",
    # AcTempoBox epilogue
    "LABEL_F9D326": "AcTempoBox_Epilogue",
}

# ============================================================================
# Batch 6: AcStrRadioBox, DrawDesignBox, draw internals - lines 2832-4050
# ============================================================================
BATCH_6 = {
    # AcStrRadioBox - get text handler
    "LABEL_F9D71B": "AcStrRadioBox_GetText",
    # AcStrRadioBox epilogue
    "LABEL_F9D72C": "AcStrRadioBox_Epilogue",
    # DrawDesignBox large .byte block
    "LABEL_FAD220": "DrawDesignBox_ByteData",
    # DrawDesignBox - check if in 4K region, call queued
    "LABEL_FAD581": "DrawDesignBox_QueuedPath",
    # DrawDesignBox epilogue (direct path)
    "LABEL_FAD5A8": "DrawDesignBox_DirectEpilogue",
    # DrawDesignBox - queued callback .byte data
    "LABEL_FAD5AC": "DrawDesignBox_QueueCallback",
    # DrawDesignBox - main impl (74-byte stack frame)
    "LABEL_FAD5C4": "DrawDesignBox_Impl",
    # DrawDesignBox impl - check style >= 0xA1
    "LABEL_FAD5F4": "DrawDesignBox_CheckStyleA0",
    # DrawDesignBox impl - check style >= 0x81
    "LABEL_FAD608": "DrawDesignBox_CheckStyle80",
    # DrawDesignBox styled - after 2-frame inset
    "LABEL_FAD692": "DrawDesignBox_After2Frame",
    # DrawDesignBox styled - after 3-frame inset
    "LABEL_FAD6AC": "DrawDesignBox_After3Frame",
    # DrawDesignBox styled - 4-frame with cross lines
    "LABEL_FAD6FC": "DrawDesignBox_4FrameCross",
    # DrawDesignBox - setup frame colors C0/C1
    "LABEL_FAD76D": "DrawDesignBox_ColorsC0C1",
    # DrawDesignBox - setup non-C0/C1 colors
    "LABEL_FAD779": "DrawDesignBox_ColorsDefault",
    # DrawDesignBox - apply frame colors
    "LABEL_FAD783": "DrawDesignBox_ApplyColors",
    # DrawDesignBox - border drawing loop
    "LABEL_FAD79D": "DrawDesignBox_BorderLoop",
    # DrawDesignBox - C4/C5 first pass check
    "LABEL_FAD854": "DrawDesignBox_BorderC4C5Check",
    # DrawDesignBox - C4/C5 first pass colors
    "LABEL_FAD862": "DrawDesignBox_C4C5FirstPass",
    # DrawDesignBox - first pass, check single width
    "LABEL_FAD87E": "DrawDesignBox_C4C5SingleWidth",
    # DrawDesignBox - first pass done, set highlight colors
    "LABEL_FAD885": "DrawDesignBox_C4C5Highlight",
    # DrawDesignBox - C6/C7 style handler
    "LABEL_FAD891": "DrawDesignBox_C6C7Style",
    # DrawDesignBox - C6/C7 non-first pass
    "LABEL_FAD8AF": "DrawDesignBox_C6C7NonFirst",
    # DrawDesignBox - C6/C7 shadow color
    "LABEL_FAD8B4": "DrawDesignBox_C6C7Shadow",
}

# ============================================================================
# Batch 7: More DrawDesignBox internals (icon style) - lines 4051-4666
# ============================================================================
BATCH_7 = {
    # DrawDesignBox - icon style (0x80/0xA0)
    "LABEL_FAD94C": "DrawDesignBox_IconStyle",
    # DrawDesignBox - icon style 0xA0
    "LABEL_FAD970": "DrawDesignBox_IconA0",
    # DrawDesignBox - icon style check both flags
    "LABEL_FAD97A": "DrawDesignBox_IconCheckFlags",
    # DrawDesignBox - icon style get frame size
    "LABEL_FAD988": "DrawDesignBox_IconGetFrameSize",
    # DrawDesignBox - icon style check left flag
    "LABEL_FAD995": "DrawDesignBox_IconCheckLeft",
    # DrawDesignBox - icon style check right flag
    "LABEL_FAD9CF": "DrawDesignBox_IconCheckRight",
    # DrawDesignBox - icon style adjust frame positions
    "LABEL_FADA0F": "DrawDesignBox_IconAdjustFrame",
    # DrawDesignBox - icon left flag adds frame width
    "LABEL_FADA23": "DrawDesignBox_IconLeftWidth",
    # DrawDesignBox - icon apply left/right adjustments
    "LABEL_FADA26": "DrawDesignBox_IconApplyAdjust",
    # DrawDesignBox - icon adjust right side
    "LABEL_FADA3F": "DrawDesignBox_IconAdjustRight",
    # DrawDesignBox - icon compute fill box
    "LABEL_FADA46": "DrawDesignBox_IconComputeFill",
    # DrawDesignBox - icon draw left border line
    "LABEL_FADAB4": "DrawDesignBox_IconLeftBorder",
    # DrawDesignBox - part group style (0x01-0x0B, 0x81-0xA8)
    "LABEL_FADAD6": "DrawDesignBox_PartGroupStyle",
    # Part group - style 8 setup
    "LABEL_FADB4C": "DrawPartGroup_Style8",
    # Part group - style 9 setup
    "LABEL_FADB5E": "DrawPartGroup_Style9",
    # Part group - style A setup
    "LABEL_FADB73": "DrawPartGroup_StyleA",
    # Part group - style B setup
    "LABEL_FADB88": "DrawPartGroup_StyleB",
    # Part group - check alt/flag then call GetFrameSPSize
    "LABEL_FADD65": "DrawPartGroup_CheckAltFlag",
    # Part group - copy box rect and proceed
    "LABEL_FADD72": "DrawPartGroup_CopyBoxRect",
    # Part group - no left flag, draw top corners
    "LABEL_FADDCC": "DrawPartGroup_NoLeftFlag",
    # Part group - after left/right adjust, draw sides
    "LABEL_FADE0B": "DrawPartGroup_DrawSides",
    # Part group - with right flag, center right icon
    "LABEL_FADE62": "DrawPartGroup_CenterRightIcon",
    # Part group - fill box and draw border lines
    "LABEL_FADEA2": "DrawPartGroup_FillAndBorder",
    # Part group - check left flag for top-left corner
    "LABEL_FADF0B": "DrawPartGroup_CheckLeftTopCorner",
    # Part group - set top-left x position
    "LABEL_FADF15": "DrawPartGroup_SetTopLeftX",
    # Part group - check right flag for bottom-right
    "LABEL_FADF2F": "DrawPartGroup_CheckRightBR",
    # Part group - set right x position
    "LABEL_FADF36": "DrawPartGroup_DrawBorderLines",
    # Part group - draw left border
    "LABEL_FADF9F": "DrawPartGroup_DrawLeftBorder",
    # Part group - CA style icon setup
    "LABEL_FADFE5": "DrawPartGroup_StyleCA",
    # Part group - draw CA/CB frame sprites
    "LABEL_FAE001": "DrawPartGroup_DrawCAFrames",
}

# ============================================================================
# Batch 8: Gfx/Flash/Splash screen, file I/O, palette - lines 5412-6524
# ============================================================================
BATCH_8 = {
    # Gfx .byte data block (image decode setup)
    "LABEL_FAE7DE": "Gfx_ImageDecodeByteData",
    # BMP file loader (splash screen from file)
    "LABEL_FAE86D": "Gfx_LoadSplashBMP",
    # BMP loader - validate file size
    "LABEL_FAE907": "SplashBMP_ValidateSize",
    # BMP loader - clear palette region loop
    "LABEL_FAE935": "SplashBMP_ClearPalette",
    # BMP loader - decode palette entries
    "LABEL_FAE954": "SplashBMP_DecodePalette",
    # BMP loader - read BMP info header fields
    "LABEL_FAE997": "SplashBMP_ReadInfoHeader",
    # BMP loader - skip excess rows loop
    "LABEL_FAEA00": "SplashBMP_SkipExcessRows",
    # BMP loader - check skip count
    "LABEL_FAEA1B": "SplashBMP_CheckSkipCount",
    # BMP loader - clamp height to 0xF0
    "LABEL_FAEA2E": "SplashBMP_ClampHeight",
    # BMP loader - prepare row buffer
    "LABEL_FAEA36": "SplashBMP_PrepareRowBuffer",
    # BMP loader - read row data loop
    "LABEL_FAEA67": "SplashBMP_ReadRowLoop",
    # BMP loader - free buffer on error
    "LABEL_FAEA80": "SplashBMP_FreeOnError",
    # BMP loader - process row data
    "LABEL_FAEA8B": "SplashBMP_ProcessRow",
    # BMP loader - wide image, copy full width
    "LABEL_FAEAB1": "SplashBMP_WideImage",
    # BMP loader - narrow image, tile to fill
    "LABEL_FAEACA": "SplashBMP_TileNarrow",
    # BMP loader - after tiling, copy remainder
    "LABEL_FAEAFD": "SplashBMP_CopyRemainder",
    # BMP loader - copy row to framebuffer
    "LABEL_FAEB17": "SplashBMP_CopyToFramebuffer",
    # BMP loader - pad remaining rows if short
    "LABEL_FAEB34": "SplashBMP_PadRows",
    # BMP loader - pad copy loop
    "LABEL_FAEB66": "SplashBMP_PadCopyLoop",
    # BMP loader - finish (decode, save, palette)
    "LABEL_FAEB93": "SplashBMP_Finish",
    # BMP loader return
    "LABEL_FAEBA0": "SplashBMP_Return",
    # Gfx_ProcessSplashData - 4bpp path
    "LABEL_FAEC15": "SplashData_4bppLoop",
    # Gfx_ProcessSplashData - done with 4bpp, free
    "LABEL_FAEC45": "SplashData_4bppFree",
    # Gfx_ProcessSplashData - 1bpp path
    "LABEL_FAEC4C": "SplashData_1bppSetup",
    # Gfx_ProcessSplashData - 1bpp decode loop
    "LABEL_FAEC81": "SplashData_1bppLoop",
    # Gfx_ProcessSplashData - 1bpp done, free
    "LABEL_FAED18": "SplashData_1bppFree",
    # Gfx_ProcessSplashData - free temp buffer
    "LABEL_FAED1C": "SplashData_FreeTempBuffer",
    # Gfx_ProcessSplashData epilogue
    "LABEL_FAED22": "SplashData_Epilogue",
    # Gfx_DecodeImageToBuffer - clear palette loop
    "LABEL_FAED40": "ImageDecode_ClearPaletteLoop",
    # Gfx_DecodeImageToBuffer - outer row loop
    "LABEL_FAED50": "ImageDecode_RowLoop",
    # Gfx_DecodeImageToBuffer - inner pixel loop
    "LABEL_FAED52": "ImageDecode_PixelLoop",
    # Gfx_DecodeImageToBuffer - second pass palette setup
    "LABEL_FAED88": "ImageDecode_SecondPassSetup",
    # Gfx_DecodeImageToBuffer - count non-zero entries
    "LABEL_FAED9C": "ImageDecode_CountNonZero",
    # Gfx_DecodeImageToBuffer - check next entry
    "LABEL_FAEDA5": "ImageDecode_CheckNextEntry",
    # Gfx_DecodeImageToBuffer - palette reduce loop
    "LABEL_FAEDB0": "ImageDecode_PaletteReduceLoop",
    # Palette reduce - special case (count=10 or 9)
    "LABEL_FAEDE4": "PaletteReduce_SpecialCase",
    # Palette reduce - start sort pass
    "LABEL_FAEDE9": "PaletteReduce_StartSortPass",
    # Palette reduce - sort inner comparison loop
    "LABEL_FAEE05": "PaletteReduce_SortCompare",
    # Palette reduce - no swap needed
    "LABEL_FAEE62": "PaletteReduce_NoSwap",
    # Palette reduce - check if done sorting
    "LABEL_FAEE69": "PaletteReduce_CheckDone",
    # Palette reduce - remap pixel values
    "LABEL_FAEE88": "PaletteReduce_RemapPixels",
    # Palette reduce - high color count, reduce
    "LABEL_FAEEC1": "PaletteReduce_HighColorReduce",
    # Palette reduce - find closest color loop
    "LABEL_FAEED1": "PaletteReduce_FindClosest",
    # Palette reduce - update minimum distance
    "LABEL_FAEF68": "PaletteReduce_UpdateMinDist",
    # Gfx_DecodeImageToBuffer - copy palette to DAC
    "LABEL_FAEF9E": "ImageDecode_CopyPaletteToDAC",
    # Palette copy reverse order loop
    "LABEL_FAEFAD": "ImageDecode_PaletteCopyLoop",
    # Gfx decode - process framebuffer rows
    "LABEL_FAEFCC": "ImageDecode_ProcessRowsOuter",
    # Gfx decode - process pixels in row
    "LABEL_FAEFD0": "ImageDecode_ProcessPixels",
    # Gfx decode - pixel >= 0xC0, add offset
    "LABEL_FAEFE8": "ImageDecode_PixelHighBank",
    # Gfx decode - pixel processed, next
    "LABEL_FAEFF0": "ImageDecode_PixelNext",
    # CaptureLcd - write palette entries loop (with or94)
    "LABEL_FAF11B": "CaptureLcd_WritePaletteOr94",
    # CaptureLcd - write palette entries loop (without or94)
    "LABEL_FAF168": "CaptureLcd_WritePaletteNoOr94",
    # CaptureLcd - write pixel data
    "LABEL_FAF1B3": "CaptureLcd_WritePixelData",
    # CaptureLcd - write row loop
    "LABEL_FAF1CA": "CaptureLcd_WriteRowLoop",
    # CaptureLcd - write failed, return 0
    "LABEL_FAF1F4": "CaptureLcd_WriteFailed",
    # CaptureLcd - next row or done
    "LABEL_FAF1F8": "CaptureLcd_NextRow",
    # CaptureLcd epilogue
    "LABEL_FAF204": "CaptureLcd_Epilogue",
    # ChangeWall - queue path
    "LABEL_FAF21C": "ChangeWall_QueuedPath",
    # ChangeWall epilogue
    "LABEL_FAF230": "ChangeWall_Epilogue",
    # ChangeWall - queued callback .byte data
    "LABEL_FAF232": "ChangeWall_QueueCallback",
    # ChangeWall - impl (lookup + store)
    "LABEL_FAF237": "ChangeWall_Impl",
    # ChangeWallPalette - queue path
    "LABEL_FAF26C": "ChangeWallPalette_QueuedPath",
    # ChangeWallPalette epilogue
    "LABEL_FAF280": "ChangeWallPalette_Epilogue",
    # ChangeWallPalette - queued callback .byte data
    "LABEL_FAF282": "ChangeWallPalette_QueueCallback",
    # ChangeWallPalette - impl
    "LABEL_FAF287": "ChangeWallPalette_Impl",
    # ChangeWallPalette - wall index 2, skip
    "LABEL_FAF299": "WallPalette_SetupLoop",
    # ChangeWallPalette - iterate palette entries
    "LABEL_FAF29E": "WallPalette_IterateEntries",
    # ChangeWallPalette - done
    "LABEL_FAF2C5": "WallPalette_Done",
    # ChangePalette - queue path
    "LABEL_FAF2D8": "ChangePalette_QueuedPath",
    # ChangePalette epilogue
    "LABEL_FAF2EC": "ChangePalette_Epilogue",
    # ChangePalette - queued callback .byte data
    "LABEL_FAF2EE": "ChangePalette_QueueCallback",
    # ChangePalette - impl (load palette table)
    "LABEL_FAF2F3": "ChangePalette_Impl",
}

ALL_BATCHES = [
    (1, BATCH_1, "WndScroll event handlers and scroll navigation"),
    (2, BATCH_2, "ModeEdit, TitleEdit, StringBox procs"),
    (3, BATCH_3, "Label, Bitmap, Icon, Line, Frame, EditSw procs"),
    (4, BATCH_4, "DrawEditSw, TextBox, VwBox, PsParaBox procs"),
    (5, BATCH_5, "AcLswBox, AcRamBox, AcTempoBox procs"),
    (6, BATCH_6, "AcStrRadioBox, DrawDesignBox internals"),
    (7, BATCH_7, "DrawDesignBox icon/part group styles"),
    (8, BATCH_8, "Graphics, splash screen, palette, capture"),
]

def main():
    start_batch = int(sys.argv[1]) if len(sys.argv) > 1 else 1

    total_renamed = 0
    for batch_num, batch_dict, description in ALL_BATCHES:
        if batch_num < start_batch:
            continue

        print(f"\n=== Batch {batch_num}: {description} ({len(batch_dict)} labels) ===")

        for old_name, new_name in batch_dict.items():
            print(f"  {old_name} -> {new_name}")
            if not rename_label(old_name, new_name):
                print(f"  FAILED: Could not rename {old_name}")
                return 1

        print(f"\nVerifying build...")
        # Clean first
        subprocess.run(["make", "clean"], cwd=REPO, capture_output=True)
        if not verify_build():
            print(f"BUILD FAILED after batch {batch_num}!")
            return 1

        print(f"Build verified. Committing batch {batch_num}...")
        commit_batch(batch_num, len(batch_dict), description)
        total_renamed += len(batch_dict)
        print(f"Committed. Total renamed so far: {total_renamed}")

    print(f"\nAll done! Renamed {total_renamed} labels total.")
    return 0

if __name__ == "__main__":
    sys.exit(main())
