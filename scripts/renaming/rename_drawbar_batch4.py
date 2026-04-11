#!/usr/bin/env python3
"""Rename LABEL_XXXXXX to semantic names in drawbar_panel_ui.s (batch 4)
Handles labels in PsLabelBoxProc, LswMasterTuning, IvSdscltyp2Proc,
LswScalingType/Shift/Shift2/Mode/KeyX, IvSoftverProc, IvMPverProc,
and the beginning of the PsMixer/AudioCtrl region."""

import sys
import os

RENAMES = {
    # === PsLabelBoxProc sub-labels (lines 8813-8972) ===
    "LABEL_F7EBA8": "PsLabel_Confirm",                # Handle confirm (0x1C0000F)
    "LABEL_F7EBF2": "PsLabel_CopyDataStr",            # Copy data string from xde
    "LABEL_F7EBFF": "PsLabel_DrawReverse",             # Draw string in reverse mode
    "LABEL_F7EC2A": "PsLabel_Select",                  # Handle select (0x1C0000E)
    "LABEL_F7EC47": "PsLabel_Notify",                  # Handle notify (0x1C0001B)
    "LABEL_F7EC86": "PsLabel_CheckSecondWidget",       # Check second widget (offset 44)
    "LABEL_F7EC9F": "PsLabel_HandleWidget1",           # Handle widget 1 (0x1E0004D)
    "LABEL_F7ECD5": "PsLabel_StoreWidget1",            # Store widget 1 value
    "LABEL_F7ECED": "PsLabel_HandleWidget2",           # Handle widget 2 (0x1E00087)
    "LABEL_F7ED22": "PsLabel_StoreWidget2",            # Store widget 2 value
    "LABEL_F7ED3E": "PsLabel_GetText",                 # Get text (0x1E0003A)
    "LABEL_F7ED5B": "PsLabel_ForwardToBase",           # Forward to InheritedProc
    "LABEL_F7ED69": "PsLabel_Epilogue",                # Pop xiz, ret

    # === LswMasterTuning sub-labels (lines 9008-9066) ===
    "LABEL_F7EDDD": "LswTuning_SearchLoop",           # Search loop for matching part
    "LABEL_F7EE2A": "LswTuning_Octave3",              # Store octave character '3'
    "LABEL_F7EE2F": "LswTuning_Octave6",              # Store octave character '6'
    "LABEL_F7EE34": "LswTuning_SearchNext",           # Increment and continue search
    "LABEL_F7EE52": "LswTuning_StepSize",             # Return step size 3

    # === IvSdscltyp2Proc sub-labels (lines 9156-9258) ===
    "LABEL_F7EF63": "Sdscltyp2_ScrollDown",           # Handle scroll down (0x1C00019/17)
    "LABEL_F7EFC6": "Sdscltyp2_SetAutoIncDown",       # SetAutoInc for scroll down
    "LABEL_F7EFD3": "Sdscltyp2_ScrollUp",             # Handle scroll up (0x1C0001A/18)
    "LABEL_F7F034": "Sdscltyp2_SetAutoIncUp",         # SetAutoInc for scroll up
    "LABEL_F7F03F": "Sdscltyp2_SetAutoInc",           # Common SetAutoInc call point
    "LABEL_F7F045": "Sdscltyp2_Paint",                # Handle paint (0x1C0000D)
    "LABEL_F7F061": "Sdscltyp2_GetText",              # Get text (0x1E0003A) - Strcpy 0xE9DBB0
    "LABEL_F7F075": "Sdscltyp2_ForwardToBase",        # Forward to InheritedProc
    "LABEL_F7F081": "Sdscltyp2_Epilogue",             # Pop xiz, clean stack, ret

    # === LswScalingType sub-labels (lines 9292-9315) ===
    "LABEL_F7F0E1": "LswScaleType_StrDefault",        # Default string 0xE9DD08
    "LABEL_F7F0E7": "LswScaleType_StrCopyReturn",     # Strcpy+return via PopIzRet
    "LABEL_F7F0F3": "LswScaleType_SubParam",          # Return sub-parameter 0x4281
    "LABEL_F7F0FA": "LswScaleType_StepSize",          # Return step size 3
    "LABEL_F7F0FE": "LswScaleType_ReturnOne",         # Return 1 (enabled/toggle)
    "LABEL_F7F102": "LswScaleType_ReturnZero",        # Return zero (default)

    # === LswScalingShift sub-labels (lines 9350-9362) ===
    "LABEL_F7F15A": "LswScaleShift_SubParam",         # Return sub-parameter 0x4282
    "LABEL_F7F161": "LswScaleShift_StepSize",         # Return step size 3
    "LABEL_F7F165": "LswScaleShift_ReturnOne",        # Return 1 (enabled/toggle)
    "LABEL_F7F169": "LswScaleShift_ReturnZero",       # Return zero (default)

    # === LswScalingShift2 sub-labels (lines 9396-9408) ===
    "LABEL_F7F1BF": "LswScaleShift2_SubParam",        # Return sub-parameter 0x4282
    "LABEL_F7F1C6": "LswScaleShift2_StepSize",        # Return step size 3
    "LABEL_F7F1CA": "LswScaleShift2_ReturnOne",       # Return 1 (enabled/toggle)
    "LABEL_F7F1CE": "LswScaleShift2_ReturnZero",      # Return zero (default)

    # === LswScalingMode sub-labels (lines 9442-9454) ===
    "LABEL_F7F224": "LswScaleMode_SubParam",          # Return sub-parameter 0x4280
    "LABEL_F7F22B": "LswScaleMode_StepSize",          # Return step size 3
    "LABEL_F7F22F": "LswScaleMode_ReturnOne",         # Return 1 (enabled/toggle)
    "LABEL_F7F233": "LswScaleMode_ReturnZero",        # Return zero (default)

    # === LswScalingKeyX sub-labels (lines 9501-9559) ===
    "LABEL_F7F2BD": "LswScaleKeyX_StrZero",           # String for zero value
    "LABEL_F7F2CA": "LswScaleKeyX_LoadReturn",        # Load return value from stack
    "LABEL_F7F2CF": "LswScaleKeyX_FindFocus",         # Find focus object loop init
    "LABEL_F7F2D3": "LswScaleKeyX_LoopBody",          # Focus search loop body
    "LABEL_F7F2F5": "LswScaleKeyX_LoopNext",          # Increment loop counter
    "LABEL_F7F2F7": "LswScaleKeyX_LoopCheck",         # Check loop termination
    "LABEL_F7F30F": "LswScaleKeyX_ReturnZero",        # Return zero (default)
    "LABEL_F7F313": "LswScaleKeyX_StepSize",          # Return step size 3
    "LABEL_F7F317": "LswScaleKeyX_ReturnFour",        # Return 4 (enabled check)
    "LABEL_F7F31B": "LswScaleKeyX_ReturnOne",         # Return 1 (toggle)
    "LABEL_F7F31F": "LswScaleKeyX_ReturnRange",       # Return range 0x80

    # === IvSoftverProc sub-labels (lines 9583-9655) ===
    "LABEL_F7F359": "Softver_ShowHide",               # Handle show/hide (0x1C0000C/B)
    "LABEL_F7F3F9": "Softver_Paint",                  # Handle paint (0x1C0000D)
    "LABEL_F7F408": "Softver_SendEvent",              # Common SendEvent call point
    "LABEL_F7F40E": "Softver_GetText",                # Get text (0x1E0003A) - Strcpy 0xE9DE4E
    "LABEL_F7F41B": "Softver_ReturnZero",             # Return zero
    "LABEL_F7F41D": "Softver_Epilogue",               # Pop xiz, clean stack, ret

    # === IvMPverProc sub-labels (lines 9676-9714) ===
    "LABEL_F7F450": "MPver_ShowHide",                 # Handle show/hide (0x1C0000C/B)
    "LABEL_F7F47D": "MPver_Paint",                    # Handle paint (0x1C0000D)
    "LABEL_F7F48C": "MPver_SendEvent",                # Common SendEvent call point
    "LABEL_F7F492": "MPver_GetText",                  # Get text (0x1E0003A) - Strcpy 0xE9DE5C
    "LABEL_F7F49F": "MPver_ReturnZero",               # Return zero
    "LABEL_F7F4A1": "MPver_Epilogue",                 # Pop xiz, clean stack, ret

    # === AudioCtrl / PsMixer region sub-labels (lines 10112-10560) ===
    "LABEL_F7FB3C": "AudioCtrl_InitCounters",         # Initialize mixer counters to zero
    "LABEL_F7FB5D": "AudioCtrl_ScanLoop",             # Scan loop for active channel
    "LABEL_F7FB7A": "AudioCtrl_ScanNext",             # Next iteration of scan loop
    "LABEL_F7FB86": "AudioCtrl_SendB3Event",          # Send 0x1E000B3 event
    "LABEL_F7FBE2": "PsMixer_Case1_SetupA0",          # Setup 0x1E000A0 MainFuncCall (case 5/0)
    "LABEL_F7FBF3": "PsMixer_Case1_PartSelect",       # Part select for case 4
    "LABEL_F7FC04": "PsMixer_Case1_MainFuncCall",     # MainFuncCall shared path
    "LABEL_F7FC08": "PsMixer_Case1_ReturnAB",         # Return via 0x1E000AB MainFuncCall
    "LABEL_F7FD1F": "PsMixer_GridSetup",              # Grid setup (init iz from 0x024794)
    "LABEL_F7FDC5": "PsMixer_FindActiveLoop",         # Find active channel loop
    "LABEL_F7FDE2": "PsMixer_FindActiveNext",         # Next iteration of find loop
    "LABEL_F7FDEF": "PsMixer_ShowEventAndForward",    # Send show event and forward
    "LABEL_F7FEC6": "PsMixer_Case5_DialSetup",        # Dial setup for same position
    "LABEL_F7FEEA": "PsMixer_Case5_DialUp",           # SetDialUp path
    "LABEL_F7FEF2": "PsMixer_Case5_SendEvent",        # SendEvent after dial
    "LABEL_F7FEF6": "PsMixer_Case5_SetAutoInc",       # SetAutoInc and return
    "LABEL_F7FFFB": "AudioCtrl_PageHandler",          # Page handler (0x8F check)
    "LABEL_F8003D": "AudioCtrl_PageAdvance",           # Advance page position
    "LABEL_F80062": "AudioCtrl_SetupPartDisplay",     # Setup part display after page
}

def main():
    files_to_update = set()
    main_file = "/home/fsanches/compartilhado/kn5000-roms-disasm/maincpu/ui/drawbar_panel_ui.s"
    files_to_update.add(main_file)

    total_replacements = 0
    for filepath in sorted(files_to_update):
        with open(filepath, 'rb') as f:
            data = f.read()

        original = data
        file_replacements = 0
        for old_label, new_label in RENAMES.items():
            old_bytes = old_label.encode('ascii')
            new_bytes = new_label.encode('ascii')
            count = data.count(old_bytes)
            if count > 0:
                data = data.replace(old_bytes, new_bytes)
                file_replacements += count

        if data != original:
            with open(filepath, 'wb') as f:
                f.write(data)
            print(f"  {filepath}: {file_replacements} replacements")
            total_replacements += file_replacements
        else:
            print(f"  {filepath}: no changes")

    print(f"\nTotal: {total_replacements} replacements across {len(files_to_update)} files")
    print(f"Labels renamed: {len(RENAMES)}")

if __name__ == "__main__":
    main()
