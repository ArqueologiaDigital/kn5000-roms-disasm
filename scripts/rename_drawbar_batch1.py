#!/usr/bin/env python3
"""Rename LABEL_XXXXXX to semantic names in drawbar_panel_ui.s (batch 1)
Handles the first ~100 labels covering AcSendEditSwProc through Bitmap handlers."""

import sys
import os

# Mapping of old label -> new label
RENAMES = {
    # === AcSendEditSwProc (lines 12-136) ===
    # Event handler for edit switch proc - handles events 0x1C0000D, 0x1C00008, 0x1C00009
    "LABEL_F77E36": "AcSendEditSw_EventD",        # Handles event 0x1C0000D (paint/redraw)
    "LABEL_F77E83": "AcSendEditSw_DrawAlt",        # Alternate draw path (xbc != 0xC1)
    "LABEL_F77E91": "AcSendEditSw_DrawString",     # Call DrawStringCentered
    "LABEL_F77E98": "AcSendEditSw_Event8",         # Handles event 0x1C00008
    "LABEL_F77ED9": "AcSendEditSw_FwdInherited",   # Forward to InheritedProc
    "LABEL_F77EE4": "AcSendEditSw_Event9",         # Handles event 0x1C00009
    "LABEL_F77F14": "AcSendEditSw_SendEvent",      # Call SendEvent
    "LABEL_F77F18": "AcSendEditSw_ReturnZero",     # Return zero (lds32 xhl, 0)
    "LABEL_F77F1C": "AcSendEditSw_FwdInherited2",  # Forward to InheritedProc (alternate)
    "LABEL_F77F25": "AcSendEditSw_CallInherited",  # call InheritedProc
    "LABEL_F77F29": "AcSendEditSw_Epilogue",       # pop xiz, restore stack, ret

    # === ComSetGridCheck jump table data (line 187) ===
    "LABEL_F77FC4": "ComSetGridCheck_JumpTable",   # Jump table .byte data block

    # === ComSetGridCheck param handlers (lines 308-364) ===
    "LABEL_F78251": "ComSetGrid_CopyStrAndDispatch",  # Push xwa, strcpy, GetFocusObject, SendEvent
    "LABEL_F78269": "ComSetGrid_CheckC0Param",        # Check param 0xC0 via SndParam_LookupReadOnly
    "LABEL_F7827D": "ComSetGrid_LookupByColumn",      # Lookup param by column via SndParam_LookupReadOnly
    "LABEL_F782A4": "ComSetGrid_ParamStr1",            # Load string 0xE800A2 (param lookup == 1)
    "LABEL_F782AB": "ComSetGrid_ParamStr3",            # Load string 0xE800AC (param lookup == 3)
    "LABEL_F782B2": "ComSetGrid_ParamStrDefault",      # Load string 0xE800B6 (default)
    "LABEL_F782D0": "ComSetGrid_SendEventReturn",      # Call SendEvent then UI_ReturnZero

    # === PmemOutLGridCheck jump table (line 1048) ===
    "LABEL_F78A11": "PmemOutLGridCheck_JumpTable",  # Jump table .byte data block

    # === PmemOutL grid check handlers (lines 1324-1354) ===
    "LABEL_F7916A": "PmemOutL_BitCheckDisplay",     # Read byte, check bit, display string
    "LABEL_F7918E": "PmemOutL_LoadOffStr",          # Load off-state string 0xE801C0
    "LABEL_F79193": "PmemOutL_StrCopyAndDispatch",  # Strcpy then GetFocusObject, SendEvent
    "LABEL_F791AE": "PmemOutL_ColumnParamDisplay",  # Lookup by column, display param string

    # === CtlMsg grid handlers (lines 1706-1785) ===
    "LABEL_F799D2": "CtlMsg_SendAudioCommand",      # Read byte, Audio_SendCommand 0x25A
    "LABEL_F799E8": "CtlMsg_GetFocusAndDispatch",   # GetFocusObject, SendEvent
    "LABEL_F799F9": "CtlMsg_ReadOffsetAndSend",     # Read offset+15, Audio_SendCommand 0x260
    "LABEL_F79A2D": "CtlMsg_ComputeAndCheck",       # Compute address, check bit 7
    "LABEL_F79A69": "CtlMsg_SendParamValue",        # Read byte, Audio_SendCommand 0x26C
    "LABEL_F79A7F": "CtlMsg_DispatchFocusEvent",    # GetFocusObject, dispatch event
    "LABEL_F79A8D": "CtlMsg_SendEventReturn",       # Call SendEvent then TtMdCtlMsg_ReturnZero2

    # === CtlMsgGrid title dispatch (line 2279) ===
    "LABEL_F79FF0": "CtlMsgGridCheck_JumpTable",    # Jump table .byte data block

    # === MidiSetup title handler (line 2350) ===
    "LABEL_F7A16A": "MidiSetup_CopyStrAndDispatch", # Strcpy, GetFocusObject, SendEvent

    # === AcMidiPartGridBox handlers (lines 2542-2940) ===
    "LABEL_F7A38E": "MidiPart_StorePartIndex",      # Store part index to 0x024778, send events
    "LABEL_F7A3D9": "MidiPart_DecrementPart",       # Decrement part counter, store
    "LABEL_F7A3ED": "MidiPart_StoreAndNotify",      # Store part, send events, call MainFuncCall
    "LABEL_F7A436": "MidiPart_CallMainFunc",        # Call MainFuncCall then return
    "LABEL_F7A495": "MidiPart_AutoDec_StorePart",   # Store decremented part, notify
    "LABEL_F7A51D": "MidiPart_Part2ColumnNav",      # Part 2 column navigation handling
    "LABEL_F7A584": "MidiPart_GenericColumnNav",    # Generic column nav (dec iz, compute index)
    "LABEL_F7A5C5": "MidiPart_CallMainFuncSetAuto", # Call MainFuncCall, set auto inc
    "LABEL_F7A5D5": "MidiPart_SendShowQuery",       # Send 0x1E00091 query
    "LABEL_F7A628": "MidiPart_InitGridBox",         # InheritedProc, GetViewInstance, init
    "LABEL_F7A681": "MidiPart_AutoInc_StorePart",   # Store incremented part, notify
    "LABEL_F7A6DA": "MidiPart_Part2ColumnNavUp",    # Part 2 upward column nav
    "LABEL_F7A73D": "MidiPart_GenericColumnNavUp",  # Generic upward column nav
    "LABEL_F7A77E": "MidiPart_CallMainFuncAutoUp",  # Call MainFuncCall for up nav
    "LABEL_F7A792": "MidiPart_SendShowQueryUp",     # Send 0x1E00091 query (up direction)
    "LABEL_F7A7E2": "MidiPart_SetDialEnable",       # Call SetDialEnable

    # === MidiSetup grid box handlers (lines 2930-2940) ===
    "LABEL_F7A814": "MidiSetup_GridStr1",           # Load grid string 0xE80492 (part 1)
    "LABEL_F7A81B": "MidiSetup_GridStr2",           # Load grid string 0xE804D4 (part 2)
    "LABEL_F7A820": "MidiSetup_PushGridStr",        # Push grid string pointer
    "LABEL_F7A821": "MidiSetup_CopyStrAndReturn",   # Strcpy and return

    # === MidiPartGridCheck jump table (line 3015) ===
    "LABEL_F7A8D4": "MidiPartGridCheck_JumpTable",  # Jump table .byte data block

    # === MidiPartGridCheck handlers (lines 3165-3239) ===
    "LABEL_F7AC8E": "MidiPart_AudioCmdDisplay",     # SndParam_LookupReadOnly, Audio_SendCommand
    "LABEL_F7ACA9": "MidiPart_GridDispatchEvent",   # GetFocusObject, SendEvent dispatch
    "LABEL_F7ACBA": "MidiPart_LookupColumnParam",   # Lookup column param, display string
    "LABEL_F7ACFB": "MidiPart_LookupFromTable",     # Lookup from table at 0xE80528
    "LABEL_F7AD25": "MidiPart_CopyParamStr",        # Copy param string, GetFocusObject
    "LABEL_F7AD3E": "MidiPart_SendEventReturn",     # SendEvent then MidiSetup_ReturnZero
    "LABEL_F7AD49": "MidiPart_DataBlock",           # Data block (.byte, referenced from widget_dispatch)

    # === Bitmap handlers (lines 3318-3472) ===
    # BitmapAccita16
    "LABEL_F7B488": "BitmapAccita16_DataPtr",       # Return data pointer 0xE86676
    "LABEL_F7B48E": "BitmapAccita16_Width",         # Return width 0x78
    "LABEL_F7B494": "BitmapAccita16_Height",        # Return height 0x5F
    # BitmapAccger16
    "LABEL_F7B4B5": "BitmapAccger16_DataPtr",       # Return data pointer 0xE892FE
    "LABEL_F7B4BB": "BitmapAccger16_Width",         # Return width 0x78
    "LABEL_F7B4C1": "BitmapAccger16_Height",        # Return height 0x5F
    # BitmapDrawsw
    "LABEL_F7B4E2": "BitmapDrawsw_DataPtr",         # Return data pointer 0xE8BF86
    "LABEL_F7B4E8": "BitmapDrawsw_Width",           # Return width 0x126
    "LABEL_F7B4EE": "BitmapDrawsw_Height",          # Return height 6
    # Bitmap_QueryProperties (3 identical handlers)
    "LABEL_F7B4F1": "Bitmap_QueryProperties3x",     # 3 identical bitmap query handlers
    # BitmapTechnics
    "LABEL_F7B593": "BitmapTechnics_DataPtr",       # Return data pointer 0xE8FFA6
    "LABEL_F7B599": "BitmapTechnics_Width",         # Return width 0x138
    "LABEL_F7B59F": "BitmapTechnics_Height",        # Return height 0x2D
    # BitmapKn5000
    "LABEL_F7B5C0": "BitmapKn5000_DataPtr",         # Return data pointer 0xE9367E
    "LABEL_F7B5C6": "BitmapKn5000_Width",           # Return width 0xC7
    "LABEL_F7B5CC": "BitmapKn5000_Height",          # Return height 0x24
    "LABEL_F7B5D2": "BitmapKn5000_Tail",            # Single byte 0x0e after BitmapKn5000

    # === AcSndEMenuProc (lines 3535-3574) ===
    "LABEL_F7B685": "AcSndEMenu_CheckModified",     # Check 0x1E00053 query, SndParam 0xC0
    "LABEL_F7B6A8": "AcSndEMenu_ForwardInherited",  # Forward to InheritedProc
    "LABEL_F7B6B0": "AcSndEMenu_CallInherited",     # call InheritedProc
    "LABEL_F7B6B4": "AcSndEMenu_Epilogue",          # pop xiz, return

    # === LswLeftHold handlers (lines 3576-3614) ===
    "LABEL_F7B6E7": "LswLeftHold_Case42",           # Handle 0x1E00042 event
    "LABEL_F7B705": "LswLeftHold_DefaultStr",       # Load default string 0xE952A6
    "LABEL_F7B70B": "LswLeftHold_CopyAndReturn",    # Strcpy and return
}

def main():
    # Files to process - the main file and any cross-references
    files_to_update = set()
    main_file = "/mnt/shared/kn5000-roms-disasm/maincpu/ui/drawbar_panel_ui.s"
    files_to_update.add(main_file)

    # Cross-file references for labels in this batch
    cross_refs = {
        "LABEL_F7AD49": ["/mnt/shared/kn5000-roms-disasm/maincpu/ui_widgets/widget_dispatch.s"],
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
