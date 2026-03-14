#!/usr/bin/env python3
"""Rename LABEL_XXXXXX labels in sequencer_engine.s to semantic names (batch 5).

Uses binary I/O to preserve Latin-1 bytes.
Updates all .s files in maincpu/ that reference renamed labels.
"""

import sys
import os
import glob

RENAMES = {
    # --- PartCtrl swap/dealloc area (lines ~11384-11549) ---
    "LABEL_F3F1DA": "PartCtrl_CompareWordValues",
    "LABEL_F3F1E9": "PartCtrl_SetupLinkedCopy",
    "LABEL_F3F209": "PartCtrl_CheckValue2",
    "LABEL_F3F242": "PartCtrl_CopyBlockLoop",
    "LABEL_F3F270": "PartCtrl_UpdateVoiceWord",
    "LABEL_F3F299": "PartCtrl_ReadAndRelinkNext",
    "LABEL_F3F2AF": "PartCtrl_WriteIndexedAndCheck",
    "LABEL_F3F345": "PartCtrl_CheckUnlinkFlag",
    "LABEL_F3F352": "PartCtrl_DeallocVoices",
    "LABEL_F3F355": "PartCtrl_DeallocReturn",

    # --- Part_ReleaseVoicesForRange area (lines ~11551-11670) ---
    "LABEL_F3F373": "PartRelRange_SetCurrentMode",
    "LABEL_F3F37C": "PartRelRange_CheckAllParts",
    "LABEL_F3F38C": "PartRelRange_SetSinglePart",
    "LABEL_F3F395": "PartRelRange_CheckInitChain",
    "LABEL_F3F3AE": "PartRelRange_OuterLoop",
    "LABEL_F3F3BA": "PartRelRange_InnerLoop",
    "LABEL_F3F3C6": "PartRelRange_ClearAndWrite",
    "LABEL_F3F41F": "PartRelRange_StealVoices",
    "LABEL_F3F424": "PartRelRange_WriteDefaults",
    "LABEL_F3F44A": "PartRelRange_InnerNext",
    "LABEL_F3F456": "PartRelRange_OuterNext",

    # --- LABEL_F3F469 - Part_ClearAndStealSingleVoice (lines ~11672-11703) ---
    "LABEL_F3F469": "Part_ClearAndStealSingleVoice",

    # --- Seq_ValidatePartNumber / Seq_ValidateTempoValue (lines ~11769-11825) ---
    "LABEL_F3F60E": "SeqValidate_PartFail",
    "LABEL_F3F612": "SeqValidate_PartOK",
    "LABEL_F3F61F": "SeqValidate_TempoFail",
    "LABEL_F3F623": "SeqValidate_TempoOK",

    # --- LABEL_F3F626 - Seq_ValidateAllParams (data block, lines ~11797) ---
    "LABEL_F3F626": "Seq_ValidateAllParams_DataBlock",

    # --- LABEL_F3F66D - Seq_ValidatePartAndTempo (lines ~11827-11861) ---
    "LABEL_F3F66D": "Seq_ValidatePartAndTempo",
    "LABEL_F3F68C": "SeqValPT_CheckTempoValues",
    "LABEL_F3F6B1": "SeqValPT_ReturnOK",

    # --- LABEL_F3F6B4 - Seq_ValidatePartTempoAndKey (lines ~11863-11895) ---
    "LABEL_F3F6B4": "Seq_ValidatePartTempoAndKey",
    "LABEL_F3F6C6": "SeqValPTK_CheckTempo",
    "LABEL_F3F6EC": "SeqValPTK_ClampKeyValue",
    "LABEL_F3F6EF": "SeqValPTK_LookupAndReturn",

    # --- LABEL_F3F6FC - Seq_ValidatePartTempoAndMode (lines ~11897-11929) ---
    "LABEL_F3F6FC": "Seq_ValidatePartTempoAndMode",
    "LABEL_F3F70E": "SeqValPTM_CheckTempo",

    # --- LABEL_F3F73B - Seq_ValidatePartAndTempoAlt (lines ~11931-11957) ---
    "LABEL_F3F73B": "Seq_ValidatePartAndTempoAlt",
    "LABEL_F3F74D": "SeqValPTA_CheckTempo",
    "LABEL_F3F763": "SeqValPTA_FailReturn",
    "LABEL_F3F767": "SeqValPTA_OKReturn",

    # --- LABEL_F3F76A - Seq_ValidateExtended_DataBlock ---
    "LABEL_F3F76A": "Seq_ValidateExtended_DataBlock",

    # --- LABEL_F3F799 - SeqPos_DecrementAndCheck (lines ~11979-12028) ---
    "LABEL_F3F799": "SeqPos_DecrementAndCheck",
    "LABEL_F3F7C7": "SeqPosDec_HandleInvalid",
    "LABEL_F3F7DD": "SeqPosDec_TestBit7",
    "LABEL_F3F7FA": "SeqPosDec_SetErrorCode",
    "LABEL_F3F7FF": "SeqPosDec_StorePosition",
    "LABEL_F3F809": "SeqPosDec_Return",

    # --- LABEL_F3F80D - data block ---
    "LABEL_F3F80D": "SeqPos_DataBlock",

    # --- LABEL_F3F854 - Seq_ValidatePartTempoAndRange (lines ~12041-12058) ---
    "LABEL_F3F854": "Seq_ValidatePartTempoAndRange",
    "LABEL_F3F866": "SeqValPTR_CheckTempo",

    # --- Later in file - various validation/dispatch labels ---
    "LABEL_F3F88E": "SeqValRange_CheckBounds",
    "LABEL_F3F891": "SeqValRange_ReturnOK",
    "LABEL_F3F8CF": "SeqDispatch_ValidateParam",
    "LABEL_F3F8D4": "SeqDispatch_ParamFail",
    "LABEL_F3F8D7": "SeqDispatch_ParamOK",

    # --- Seq tempo/timing area ---
    "LABEL_F3F900": "SeqTempo_CheckAndClamp",
    "LABEL_F3F90C": "SeqTempo_ClampedReturn",
    "LABEL_F3F93D": "SeqTempo_ApplyAndReturn",

    # --- Seq buffer/position area ---
    "LABEL_F3F9C5": "SeqBufPos_UpdateAndSync",
    "LABEL_F3F9EA": "SeqBufPos_CheckLimit",
    "LABEL_F3FA0C": "SeqBufPos_HandleOverflow",
    "LABEL_F3FA15": "SeqBufPos_WrapAround",
    "LABEL_F3FA1B": "SeqBufPos_StoreResult",
    "LABEL_F3FA2B": "SeqBufPos_Return",

    # --- Seq accomp/playback area ---
    "LABEL_F3FABF": "SeqAccPlay_InitAndDispatch",
    "LABEL_F3FAF0": "SeqAccPlay_Return",
}

def main():
    base_dir = "/mnt/shared/kn5000-roms-disasm"
    s_files = glob.glob(os.path.join(base_dir, "maincpu", "**", "*.s"), recursive=True)
    print(f"Found {len(s_files)} .s files to scan")

    file_contents = {}
    for path in s_files:
        with open(path, 'rb') as f:
            file_contents[path] = f.read()

    total_replacements = 0
    files_modified = set()

    for old_label, new_label in RENAMES.items():
        old_bytes = old_label.encode('ascii')
        new_bytes = new_label.encode('ascii')
        for path, content in file_contents.items():
            if old_bytes in content:
                count = content.count(old_bytes)
                file_contents[path] = content.replace(old_bytes, new_bytes)
                total_replacements += count
                files_modified.add(path)

    for path in files_modified:
        with open(path, 'wb') as f:
            f.write(file_contents[path])
        rel = os.path.relpath(path, base_dir)
        print(f"  Modified: {rel}")

    print(f"\nTotal: {len(RENAMES)} labels renamed, {total_replacements} replacements across {len(files_modified)} files")

if __name__ == "__main__":
    main()
