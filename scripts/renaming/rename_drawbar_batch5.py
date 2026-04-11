#!/usr/bin/env python3
"""Rename LABEL_XXXXXX to semantic names in drawbar_panel_ui.s (batch 5)
Handles labels in AudioCtrl/PsMixer continuation, AcPartMixerProc,
AcTrackMixerProc, AcResetPageProc, utility functions,
AcDrawComboBoxProc, AcDrawEditBoxProc, LswPercDecay/Level,
LswDrawAttack/Release sub-labels."""

import sys
import os

RENAMES = {
    # === AudioCtrl / PsMixer continuation (lines 10604-10782) ===
    "LABEL_F800F5": "AudioCtrl_CheckEventF",          # Check event == 0x0F
    "LABEL_F800F8": "AudioCtrl_HandleEventF",         # Handle event 0x0F (title query)
    "LABEL_F80149": "AudioCtrl_PostMode7",             # Post mode 7 event (0x1A000D6)
    "LABEL_F80168": "AudioCtrl_QueryTitle",            # Query title (0x1E00079, 0x1E0009A)

    # === PsMixer case 6 sub-labels (lines 10684-10734) ===
    "LABEL_F801DB": "PsMixer_Case6_ScrollDown",        # Scroll down path (bit 7 clear)
    "LABEL_F801E3": "PsMixer_Case6_SendScroll",        # Send scroll event
    "LABEL_F801F9": "PsMixer_Case6_Forward",           # Forward to InheritedProc

    # === PsMixer case 7 sub-labels (line 10734) ===
    "LABEL_F80268": "PsMixer_Case7_Forward",           # Forward to InheritedProc

    # === PsMixer case 8/9/10 sub-labels (lines 10782-11027) ===
    "LABEL_F802F1": "PsMixer_MidiScanOuterLoop",      # Outer loop for MIDI part scan
    "LABEL_F80406": "PsMixer_UnmatchedPartScan",       # Unmatched part scan (hl == 0xFFFF)
    "LABEL_F804E5": "PsMixer_ScanArrayNext",           # Next iteration of scan array loop
    "LABEL_F80559": "PsMixer_VolSel_SearchGrid",       # Volume select: search grid positions
    "LABEL_F80566": "PsMixer_VolSel_SearchLoop",       # Volume select: search loop body
    "LABEL_F8057E": "PsMixer_VolSel_CheckFound",       # Volume select: check if found
    "LABEL_F80592": "PsMixer_VolSel_SearchFallback",   # Volume select: fallback search

    # === PsMixer event forward region (lines 11121-11180) ===
    "LABEL_F806AE": "PsMixer_EventFwd_Setup",         # Event forward setup
    "LABEL_F80704": "PsMixer_EventFwd_Next",           # Event forward next iteration
    "LABEL_F80734": "AudioCtrl_Epilogue",              # Pop xiz, clean stack, ret

    # === AcPartMixerProc sub-labels (lines 11200-11211) ===
    "LABEL_F8075D": "PartMixer_Init",                 # Handle init (0x1C00001)
    "LABEL_F8077B": "PartMixer_Epilogue",             # Pop xiz, clean stack, ret

    # === AcTrackMixerProc sub-labels (lines 11241-11303) ===
    "LABEL_F807CC": "TrackMixer_Init",                # Handle init (0x1C00001)
    "LABEL_F807DE": "TrackMixer_InitPartLoop",        # Init part loop (0 to 0xF)
    "LABEL_F80803": "TrackMixer_ShowHide",            # Handle show/hide (0x1C0000C/B)
    "LABEL_F8080C": "TrackMixer_CallInherited",       # Call InheritedProc shared path
    "LABEL_F80812": "TrackMixer_UpdateHandler",       # Handle update (0x1C0002D)
    "LABEL_F80864": "TrackMixer_ReturnZero",          # Return zero
    "LABEL_F80866": "TrackMixer_Epilogue",            # Pop iz, clean stack, ret

    # === AcResetPageProc sub-labels (lines 11323-11343) ===
    "LABEL_F8088F": "ResetPage_Init",                 # Handle init (0x1C00001)
    "LABEL_F8089E": "ResetPage_SendViewEvent",        # Send view event (0x1E0007F)
    "LABEL_F808AB": "ResetPage_CallInherited",        # Call InheritedProc and return
    "LABEL_F808B9": "ResetPage_Epilogue",             # Pop xiz, clean stack, ret

    # === Utility functions (lines 11357-11372) ===
    "LABEL_F808CE": "Util_StorePartArrayBase",        # Store to 0x03EA30
    "LABEL_F808E0": "Util_StoreGridArrayBase",        # Store to 0x03EA34
    "LABEL_F808E6": "AudioCtrl_DataBlock",            # Data block (.byte region)

    # === AcDrawComboBoxProc sub-labels (lines 12776-12819) ===
    "LABEL_F82A8F": "DrawCombo_CheckVisible",         # Check visibility + query
    "LABEL_F82AD0": "DrawCombo_ReturnZero",           # Return zero (no update needed)
    "LABEL_F82AD4": "DrawCombo_ForwardToBase",        # Forward to InheritedProc
    "LABEL_F82ADC": "DrawCombo_CallInherited",        # Call InheritedProc shared
    "LABEL_F82AE2": "DrawCombo_GetWidgetValue",       # Get widget value (offset 40)
    "LABEL_F82AEF": "DrawCombo_CompareMatch",         # Compare match with xde

    # === AcDrawComboBox sub-proc labels (lines 13130-13212) ===
    "LABEL_F82E1F": "DrawCombo_Paint",                # Handle paint (0x1C0000D)
    "LABEL_F82E39": "DrawCombo_GetText",              # Get text (0x1E0003A) - Strcpy 0xE9F930
    "LABEL_F82E4C": "DrawCombo_InitWidget",           # Init widget (check 0x1E00094)
    "LABEL_F82E75": "DrawCombo_InitForward",          # Init: forward to InheritedProc
    "LABEL_F82E98": "DrawCombo_CloseWidget",          # Close widget (check 0x1E00094)
    "LABEL_F82EC1": "DrawCombo_CloseForward",         # Close: forward to InheritedProc
    "LABEL_F82EE2": "DrawCombo_SendEvent",            # Common SendEvent call point
    "LABEL_F82EE8": "DrawCombo_Epilogue",             # Pop xiz, clean stack, ret

    # === AcDrawEditBoxProc sub-labels (lines 13231-13290) ===
    "LABEL_F82F0F": "EditBox_CheckDialEvent",         # Check if dial event in mode 0x1800003
    "LABEL_F82F3F": "EditBox_ShowHide",               # Handle show/hide (0x1C0000C/B)
    "LABEL_F82F7D": "EditBox_DialForward",            # Dial: forward to InheritedProc
    "LABEL_F82F85": "EditBox_CallInherited",          # Call InheritedProc shared
    "LABEL_F82F89": "EditBox_ReturnZero",             # Return zero
    "LABEL_F82F8D": "EditBox_ForwardToBase",          # Forward to InheritedProc (default)
    "LABEL_F82F95": "EditBox_CallInherited2",         # Call InheritedProc (alt path)
    "LABEL_F82F99": "EditBox_Epilogue",               # Pop xiz, clean stack, ret

    # === LswPercDecay sub-labels (lines 13334-13408) ===
    "LABEL_F83023": "LswPercDecay_PartIdLookup",      # Part ID lookup from 0xE953CE
    "LABEL_F83036": "LswPercDecay_SubParam",           # Return sub-parameter 0x2CC
    "LABEL_F8303D": "LswPercDecay_StepSize",           # Return step size 3
    "LABEL_F83041": "LswPercDecay_StoreDE",            # Store xde to 0x0247C6
    "LABEL_F83088": "SdpartClamp_CheckUpper",          # Check upper bound (wa <= 5)
    "LABEL_F83092": "SdpartClamp_ReturnZero",          # Return zero (out of range)
    "LABEL_F83095": "SdpartClamp_Apply",               # Apply delta and check range
    "LABEL_F830A9": "SdpartClamp_StoreResult",         # Store result

    # === LswPercLevel sub-labels (lines 13451-13471) ===
    "LABEL_F83132": "LswPercLevel_PartIdLookup",      # Part ID lookup from 0xE953CE
    "LABEL_F83145": "LswPercLevel_SubParam",           # Return sub-parameter 0x2CB
    "LABEL_F8314C": "LswPercLevel_StepSize",           # Return step size 3
    "LABEL_F83150": "LswPercLevel_StoreDE",            # Store xde to 0x0247C8

    # === LswDrawAttack sub-labels (lines 13538-13558) ===
    "LABEL_F83213": "LswDrawAttack_PartIdLookup",     # Part ID lookup from 0xE953CE
    "LABEL_F83226": "LswDrawAttack_SubParam",          # Return sub-parameter 0x294
    "LABEL_F8322D": "LswDrawAttack_StepSize",          # Return step size 3
    "LABEL_F83231": "LswDrawAttack_StoreDE",           # Store xde to 0x0247CC

    # === LswDrawRelease sub-labels (lines 13625-13645) ===
    "LABEL_F832F4": "LswDrawRelease_PartIdLookup",    # Part ID lookup from 0xE953CE
    "LABEL_F83307": "LswDrawRelease_SubParam",         # Return sub-parameter 0x293
    "LABEL_F8330E": "LswDrawRelease_StepSize",         # Return step size 3
    "LABEL_F83312": "LswDrawRelease_StoreDE",          # Store xde to 0x0247CA
}

def main():
    files_to_update = set()
    main_file = "/home/fsanches/compartilhado/kn5000-roms-disasm/maincpu/ui/drawbar_panel_ui.s"
    files_to_update.add(main_file)

    # Cross-file references
    cross_refs = {
        "LABEL_F800F8": ["/home/fsanches/compartilhado/kn5000-roms-disasm/maincpu/ui_widgets/widget_descriptors.s"],
    }
    for label, ref_files in cross_refs.items():
        if label in RENAMES:
            for f in ref_files:
                files_to_update.add(f)

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
