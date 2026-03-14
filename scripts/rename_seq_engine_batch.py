#!/usr/bin/env python3
"""Rename LABEL_XXXXXX labels in sequencer_engine.s to semantic names (batch 12).

Uses binary I/O to preserve Latin-1 bytes.
Updates all .s files in maincpu/ that reference renamed labels.
"""

import sys
import os
import glob

RENAMES = {
    "LABEL_F46532": "NoteEditSy_Dispatch85",
    "LABEL_F46540": "NoteEditSy_Dispatch87",
    "LABEL_F46560": "NoteEditSy_DeliverParam7",
    "LABEL_F4656B": "NoteEditSy_DeliverReturn",
    "LABEL_F4658D": "SeqMode_Status85",
    "LABEL_F4659B": "SeqMode_Status87",
    "LABEL_F465A7": "SeqMode_StatusDeliver",
    "LABEL_F465BA": "SeqAccomp_StopNotifyDeliver",
    "LABEL_F46600": "SngSel_HandlePrevSong",
    "LABEL_F46630": "SngSel_HandleNextSong",
    "LABEL_F4665D": "SngSel_SendVoiceUpdate",
    "LABEL_F46A7D": "SeqErec_ClearPlayFlags",
    "LABEL_F46AAC": "SeqErecFunc_SetIndicator",
    "LABEL_F46AAF": "SeqErecFunc_CallSetIndicator",
    "LABEL_F46AB3": "SeqErecFunc_ReturnZero",
    "LABEL_F46AE3": "SeqPlayMode_SaveAndCleanup",
    "LABEL_F46B2C": "SeqReal_CopyBarFromSaved",
    "LABEL_F46B32": "SeqReal_InitStartState",
    "LABEL_F46B39": "SeqReal_HandleActivation",
    "LABEL_F46BA3": "SeqReal_SetBarFlag",
    "LABEL_F46BA9": "SeqReal_CheckAccompBit",
    "LABEL_F46BE7": "SeqEdit_RestoreAndClear",
    "LABEL_F46BEF": "SeqEdit_ReturnZero",
    "LABEL_F46C2E": "SqRealRec_SetBitMaskLoop",
    "LABEL_F46C69": "SqRealRec_DetectAndInit",
    "LABEL_F46C7C": "SqRealRec_HandleExitState",
    "LABEL_F46CCA": "SqPlay_HandleExitState",
    "LABEL_F46CFD": "SqQtz_ClearBit4",
    "LABEL_F46D29": "SqMdel_ClearBit0",
    "LABEL_F46D55": "SqMers_ClearBit1",
    "LABEL_F46D81": "SqVcng_ClearBit5",
    "LABEL_F46DD5": "SqMcpy_ClearBit3",
    "LABEL_F46DDB": "SqMcpy_HandleExitState",
    "LABEL_F46E0C": "SqMins_ClearBit2",
    "LABEL_F46E12": "SqMins_HandleExitState",
    "LABEL_F46E3C": "SqTrcl_HandleExitState",
    "LABEL_F46E92": "SqTrmg_ReturnZero",
    "LABEL_F46EB6": "SqPunch_HandleTickOnExit",
    "LABEL_F46EDB": "SqPunchm_HandleStopOnExit",
    "LABEL_F46F14": "SqNoteEdt_ReturnZero",
    "LABEL_F46F4D": "SqDrmEdt_ReturnZero",
    "LABEL_F46F68": "SdRevset_ClearFlag",
    "LABEL_F46F6D": "SdRevset_ReturnZero",
    "LABEL_F46F88": "SdDspeff_ClearFlag",
    "LABEL_F46F8D": "SdDspeff_ReturnZero",
    "LABEL_F46FA8": "SdAccill_ClearFlag",
    "LABEL_F46FAD": "SdAccill_ReturnZero",
    "LABEL_F46FC3": "SqNoteCycp_ReturnZero",
    "LABEL_F46FD9": "SqDrmCycp_ReturnZero",
    "LABEL_F46FF3": "HelpMode_ReturnZero",
    "LABEL_F47667": "HelpLang_DispatchDataBlock",
    "LABEL_F47664": "MainPanic_ReturnZero",
    "LABEL_F4778A": "HelpLang_SetRegion5",
    "LABEL_F47796": "HelpLang_PostEvent",
    "LABEL_F477BA": "HelpLang_LoadSlide",
    "LABEL_F477D3": "HelpLang_ParseSlideHeader",
    "LABEL_F477D7": "HelpLangChk_ReturnZero",
    "LABEL_F477FE": "HelpFlash_DispatchAudio",
    "LABEL_F47804": "HelpFlash_ReturnZero",
    "LABEL_F47807": "SeqIndicator_HideBoth",
    "LABEL_F47864": "SeqLoad_PostInitParts",
    "LABEL_F47899": "SeqLoad_PostSetPositions",
    "LABEL_F478A2": "SeqLoad_PostCheckAutoAccomp",
    "LABEL_F478BA": "SeqLoad_JumpInitFromPreset",
    "LABEL_F478BE": "SeqLoad_PostAltEntry",
    "LABEL_F478CA": "SeqLoad_AltInitParts",
    "LABEL_F47902": "SeqLoad_AltSetPositions",
    "LABEL_F4790B": "SeqLoad_AltCheckAutoAccomp",
    "LABEL_F47958": "SeqSave_PostReturn",
    "LABEL_F4795A": "SeqLoad_ProcessDataBlock",
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
