#!/usr/bin/env python3
"""Rename LABEL_XXXXXX to semantic names in drawbar_panel_ui.s (batch 6 - final)
Handles remaining labels in IvDrawbar2Proc, IvDrawbarNormProc,
IvDrawbarSndEProc, DrawbarBitmapHelper, MainMemDrawControl,
PsVariBoxProc, VwUserBitmapSpProc, AcFdemoScreenProc,
IvDemofeature1/2Proc, AcPresentationBoxProc, AcPresentationControlProc."""

import sys
import os

RENAMES = {
    # === IvDrawbar2Proc sub-labels (lines 14154-14302) ===
    "LABEL_F83859": "IvDrawbar2_ShowHideHandler",     # Show/hide handler (0x1C0000C/B)
    "LABEL_F83881": "IvDrawbar2_PaintHandler",        # Paint handler (0x1C0000D)
    "LABEL_F83897": "IvDrawbar2_SendEventShared",     # Shared SendEvent call point
    "LABEL_F8389E": "IvDrawbar2_LoadValsHandler",     # Load values handler (0x1E10008)
    "LABEL_F838F1": "IvDrawbar2_LoadMode3",           # Load mode 3 (MainFuncCall path)
    "LABEL_F83900": "IvDrawbar2_MatchHandler",        # Match handler (0x1C0001C)
    "LABEL_F83928": "IvDrawbar2_MatchCheck2CB",       # Match check for 0x82CB
    "LABEL_F8393D": "IvDrawbar2_MatchCheck294",       # Match check for 0x8294
    "LABEL_F83952": "IvDrawbar2_MatchCheck293",       # Match check for 0x8293
    "LABEL_F83969": "IvDrawbar2_CallInherited",       # Call InheritedProc shared
    "LABEL_F8396F": "IvDrawbar2_OKHandler",           # OK handler (0x1C00007)
    "LABEL_F839BB": "IvDrawbar2_MainFuncCallShared",  # Shared MainFuncCall point
    "LABEL_F839C1": "IvDrawbar2_GetText",             # Get text (0x1E0003A) - Strcpy 0xE9F93C
    "LABEL_F839D5": "IvDrawbar2_ForwardToBase",       # Forward to InheritedProc
    "LABEL_F839E1": "IvDrawbar2_Epilogue",            # Pop xiz, clean stack, ret

    # === IvDrawbarNormProc sub-labels (lines 14330-14441) ===
    "LABEL_F83A35": "DrawbarNorm_ShowHide",           # Show/hide (0x1C0000C/B)
    "LABEL_F83A5C": "DrawbarNorm_Paint",              # Paint (0x1C0000D)
    "LABEL_F83A75": "DrawbarNorm_Update",             # Update (0x1E000A7)
    "LABEL_F83A9F": "DrawbarNorm_UpdateCase4",        # Update case 4 (part display)
    "LABEL_F83ABD": "DrawbarNorm_Notify",             # Notify (0x1C0001B)
    "LABEL_F83ADF": "DrawbarNorm_Match",              # Match (0x1C0001C)
    "LABEL_F83AFA": "DrawbarNorm_MatchForward",       # Match: forward to InheritedProc
    "LABEL_F83B08": "DrawbarNorm_Refresh",            # Refresh (0x1C0002F)
    "LABEL_F83B2D": "DrawbarNorm_GetText",            # Get text (0x1E0003A) - Strcpy 0xE9F942
    "LABEL_F83B41": "DrawbarNorm_ForwardToBase",      # Forward to InheritedProc
    "LABEL_F83B4D": "DrawbarNorm_Epilogue",           # Pop xiz, clean stack, ret

    # === IvDrawbarSndEProc sub-labels (lines 14457-14476) ===
    "LABEL_F83B6C": "DrawbarSndE_Paint",              # Paint (0x1C0000D)
    "LABEL_F83B81": "DrawbarSndE_GetText",            # Get text (0x1E0003A) - Strcpy 0xE9F948
    "LABEL_F83B8E": "DrawbarSndE_ReturnZero",         # Return zero
    "LABEL_F83B90": "DrawbarSndE_Epilogue",           # Pop xiz, ret

    # === Drawbar bitmap helper (line 14480) ===
    "LABEL_F83B92": "DrawbarBitmapHelper",            # Build bitmap workspace and draw

    # === MainMemDrawControl sub-labels (lines 14541-14599) ===
    "LABEL_F83C43": "MemDraw_InitParamLoop",          # Init parameter loop (iz = 0)
    "LABEL_F83C45": "MemDraw_ParamLoopBody",          # Parameter loop body
    "LABEL_F83C6B": "MemDraw_UpdateItem",             # Update item (0x1E1000A)
    "LABEL_F83C97": "MemDraw_SendExtVoice",           # Send ext voice params
    "LABEL_F83CA5": "MemDraw_RestoreAll",             # Restore all (0x1E10008)
    "LABEL_F83CA7": "MemDraw_RestoreLoop",            # Restore loop body
    "LABEL_F83CBD": "MemDraw_CheckVoiceState",        # Check voice state (0x1E1000E)

    # === DemoMenu descriptor dispatch labels (lines 14737-14791) ===
    "LABEL_F83DE9": "DemoDesc_DispatchTable",         # Descriptor dispatch table entry
    "LABEL_F83E10": "DemoDesc_BuildCompactParams",    # Build compact params from registers
    "LABEL_F83E7C": "DemoDesc_DataByte",              # Single data byte (0x0E)

    # === PsVariBoxProc sub-labels (lines 14830-14992) ===
    "LABEL_F83EFF": "PsVari_Paint",                   # Paint (0x1C0000D)
    "LABEL_F83F29": "PsVari_PaintEmpty",              # Paint empty (draw box only)
    "LABEL_F83F43": "PsVari_DrawEditSw",              # Draw edit switch after paint
    "LABEL_F83F5C": "PsVari_Confirm",                 # Confirm (0x1C0000F)
    "LABEL_F83FCC": "PsVari_DrawInactive",            # Draw inactive string
    "LABEL_F83FDA": "PsVari_DrawStringCall",          # DrawStringAlignment call point
    "LABEL_F83FE3": "PsVari_GetText",                 # Get text (0x1E0003A) - Sprintf_Locked
    "LABEL_F84004": "PsVari_OK",                      # OK handler (0x1C00007)
    "LABEL_F84040": "PsVari_OKForward",               # OK: forward to InheritedProc
    "LABEL_F8404E": "PsVari_Notify",                  # Notify (0x1C0001B)
    "LABEL_F84091": "PsVari_CheckDirty",              # Check dirty (0x1E0003C)
    "LABEL_F840B5": "PsVari_ForwardToBase",           # Forward to InheritedProc
    "LABEL_F840C1": "PsVari_CallInherited",           # Call InheritedProc shared
    "LABEL_F840C5": "PsVari_Epilogue",                # Pop xiz, ret

    # === VwUserBitmapSpProc sub-labels (lines 15006-15046) ===
    "LABEL_F840DE": "UserBitmapSp_Paint",             # Paint (0x1C0000D)
    "LABEL_F84139": "UserBitmapSp_DrawEmpty",         # Draw empty bitmap
    "LABEL_F84142": "UserBitmapSp_ReturnZero",        # Return zero
    "LABEL_F84144": "UserBitmapSp_Epilogue",          # Pop xiz, clean stack, ret

    # === AcFdemoScreenProc sub-labels (lines 15069-15113) ===
    "LABEL_F84178": "FdemoScreen_Init",               # Init (0x1C00001)
    "LABEL_F841A3": "FdemoScreen_InitForward",        # Init: forward to InheritedProc
    "LABEL_F841D8": "FdemoScreen_StartPanel2",        # Start panel E40002
    "LABEL_F841E4": "FdemoScreen_SendStart",          # Send start event
    "LABEL_F841E8": "FdemoScreen_ReturnZero",         # Return zero
    "LABEL_F841EA": "FdemoScreen_Epilogue",           # Pop xiz, clean stack, ret

    # === IvDemofeature1Proc sub-labels (lines 15129-15148) ===
    "LABEL_F84209": "Demofeat1_Paint",                # Paint (0x1C0000D)
    "LABEL_F8421E": "Demofeat1_GetText",              # Get text (0x1E0003A) - Strcpy 0xE9F9A6
    "LABEL_F8422B": "Demofeat1_ReturnZero",           # Return zero
    "LABEL_F8422D": "Demofeat1_Epilogue",             # Pop xiz, ret

    # === IvDemofeature2Proc sub-labels (lines 15169-15207) ===
    "LABEL_F84262": "Demofeat2_Init",                 # Init (0x1C00001)
    "LABEL_F8426A": "Demofeat2_ShowHide",             # Show/hide (0x1C0000C/B)
    "LABEL_F8428E": "Demofeat2_Paint",                # Paint (0x1C0000D)
    "LABEL_F8429D": "Demofeat2_SendEvent",            # Common SendEvent call point
    "LABEL_F842A3": "Demofeat2_GetText",              # Get text (0x1E0003A) - Strcpy 0xE9F9AC
    "LABEL_F842B0": "Demofeat2_ReturnZero",           # Return zero
    "LABEL_F842B2": "Demofeat2_Epilogue",             # Pop xiz, ret

    # === AcPresentationBoxProc sub-labels (lines 15250-15391) ===
    "LABEL_F84337": "PresBox_Paint",                  # Paint (0x1C0000D)
    "LABEL_F8436C": "PresBox_Select",                 # Select (0x1C0000E)
    "LABEL_F8438C": "PresBox_HandleWidget",           # Handle widget (0x1E0004D)
    "LABEL_F843B5": "PresBox_OK",                     # OK handler (0x1C00007)
    "LABEL_F843FD": "PresBox_OKForward",              # OK: forward to InheritedProc
    "LABEL_F84408": "PresBox_TimerExpired",           # Timer expired (0x1C10005)
    "LABEL_F8445A": "PresBox_TimerTick",              # Timer tick (0x1C10006)
    "LABEL_F84489": "PresBox_Notify",                 # Notify (0x1C0001B)
    "LABEL_F844C2": "PresBox_GetText",                # Get text (0x1E0003A) - Strcpy from view

    # === AcPresentationControlProc sub-labels (lines 15491-15582) ===
    "LABEL_F845D1": "AcPresCtrl_ChangePalette",       # Call ChangePalette shared
    "LABEL_F8464A": "AcPresCtrl_SendEventReturn",     # SendEvent then return
    "LABEL_F84697": "AcPresCtrl_Epilogue",            # Pop xiz, clean stack, ret
    "LABEL_F8469B": "Seq_DispatchEventType5",         # Dispatch event type 5 helper
}

def main():
    files_to_update = set()
    main_file = "/mnt/shared/kn5000-roms-disasm/maincpu/ui/drawbar_panel_ui.s"
    files_to_update.add(main_file)

    # Cross-file references
    cross_refs = {
        "LABEL_F83E10": ["/mnt/shared/kn5000-roms-disasm/maincpu/demo/fdemotext_routines.s"],
        "LABEL_F8469B": ["/mnt/shared/kn5000-roms-disasm/maincpu/demo/file_demo_proc.s"],
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
