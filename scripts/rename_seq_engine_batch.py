#!/usr/bin/env python3
"""Rename LABEL_XXXXXX labels in sequencer_engine.s to semantic names (batch 11).

Uses binary I/O to preserve Latin-1 bytes.
Updates all .s files in maincpu/ that reference renamed labels.
"""

import sys
import os
import glob

RENAMES = {
    # --- SeqVoice_DispatchAllEvents area (lines ~20567-20578) ---
    "LABEL_F44FA2": "SeqVoice_DispatchLoop",

    # --- SeqVoice_ComputeStatusFlags area (lines ~20613-20686) ---
    "LABEL_F45025": "SeqStatus_CheckState9A",
    "LABEL_F45049": "SeqStatus_CheckActiveVoice",
    "LABEL_F45079": "SeqStatus_CheckHighState",
    "LABEL_F45085": "SeqStatus_CheckHighFallback",
    "LABEL_F45093": "SeqStatus_SetActiveFlag",
    "LABEL_F45097": "SeqStatus_Handle9AState",

    # --- LABEL_F450A1 area - app event handler (lines ~20688-20915) ---
    "LABEL_F450A1": "AppEvent_HandleChannelEvent",
    "LABEL_F450EB": "AppEvent_ToggleChannel",
    "LABEL_F45107": "AppEvent_ToggleShiftDone",
    "LABEL_F45111": "AppEvent_ToggleSetStatus",
    "LABEL_F45136": "AppEvent_HandleStateChange",
    "LABEL_F45231": "AppEvent_HandleRecordState",
    "LABEL_F4523F": "AppEvent_RecordClampLow",
    "LABEL_F45242": "AppEvent_RecordDispatch",
    "LABEL_F45279": "AppEvent_Handle9AToggle",
    "LABEL_F45285": "AppEvent_9AShiftDone",
    "LABEL_F45297": "AppEvent_9ASetOff",
    "LABEL_F4529B": "AppEvent_9AStoreAndPost",

    # --- EffEditMain area - DSP param dispatch (lines ~20917-21153) ---
    "LABEL_F4531C": "EffEdit_DispatchTypeB",
    "LABEL_F4531E": "EffEdit_TypeBLoop",
    "LABEL_F45339": "EffEdit_DispatchTypeE",
    "LABEL_F4534A": "EffEdit_DispatchTypeD6",
    "LABEL_F4534C": "EffEdit_TypeD6Loop",
    "LABEL_F45365": "EffEdit_HandleParamChange",
    "LABEL_F4538B": "EffEdit_ParamChangeD6",
    "LABEL_F45398": "EffEdit_ParamChangeA",
    "LABEL_F453C2": "EffEdit_ParamAPositive",
    "LABEL_F453DB": "EffEdit_ParamANegative",
    "LABEL_F453F5": "EffEdit_DeliveryLoopBody",
    "LABEL_F45410": "EffEdit_ParamChangeB",
    "LABEL_F45439": "EffEdit_ParamBPositive",
    "LABEL_F45451": "EffEdit_ParamBNegative",
    "LABEL_F4546F": "EffEdit_DeliveryNoRetLoop",
    "LABEL_F45489": "EffEdit_HandleDirectWrite",
    "LABEL_F454C8": "EffEdit_DirectWriteB",
    "LABEL_F454D0": "EffEdit_DirectWriteC",
    "LABEL_F454D8": "EffEdit_DirectWriteE",
    "LABEL_F454DF": "EffEdit_DirectWriteD6",
    "LABEL_F454E7": "EffEdit_CallWriteParam",

    # --- LABEL_F454F1 - large .byte DSP config block ---
    "LABEL_F454F1": "EffEdit_DSPConfigBlock",

    # --- EffEdit validation area (lines ~21254-21265) ---
    "LABEL_F457CF": "EffEdit_ValidateAndReadParams",
    "LABEL_F457DF": "EffEdit_ValidateLoop",

    # --- EffEdit DSP read area (lines ~21287-21404) ---
    "LABEL_F45831": "EffEdit_ReadParamA_Body",
    "LABEL_F45871": "EffEdit_ReadParamA_Check",
    "LABEL_F45884": "EffEdit_ReadParamA_Fixup",
    "LABEL_F458A7": "EffEdit_ReadParamB",
    "LABEL_F458CA": "EffEdit_ReadParamB_Body",
    "LABEL_F4590A": "EffEdit_ReadParamB_Check",
    "LABEL_F4591D": "EffEdit_ReadParamB_Fixup",
    "LABEL_F45937": "EffEdit_ReadParamC",
    "LABEL_F4593A": "EffEdit_ReadParamC_Loop",

    # --- EffEdit DSP read continued (lines ~21406-21453) ---
    "LABEL_F45965": "EffEdit_ReadParamE",
    "LABEL_F45986": "EffEdit_ReadParamD6",
    "LABEL_F4599A": "EffEdit_ReadParamD6_Loop",
    "LABEL_F459E2": "EffEdit_ReturnError",
    "LABEL_F459E5": "EffEdit_PopAndReturn",

    # --- EffEdit range validation (lines ~21455-21532) ---
    "LABEL_F459E9": "EffEdit_ValidateRangeDelta",
    "LABEL_F45A3C": "EffEdit_RangeCheck4C12",
    "LABEL_F45A59": "EffEdit_RangeCheckDE",
    "LABEL_F45A5F": "EffEdit_RangeCheck4C14",
    "LABEL_F45A79": "EffEdit_RangeCheckHL",
    "LABEL_F45A89": "EffEdit_RangeCheck4C16",

    # --- MimeSyori area (lines ~21534-21544) ---
    "LABEL_F45AB5": "MimeSyori_ReturnZero",

    # --- SeqPlay alloc/visible area (lines ~21636-21706) ---
    "LABEL_F45BF7": "SeqPlay_AllocHideIndicator",
    "LABEL_F45C10": "SeqPlay_AllocPostEvent",
    "LABEL_F45CB7": "SeqPlay_AllocAdjustBar",

    # --- SeqAccomp start helper area (lines ~21975-22052) ---
    "LABEL_F46224": "SeqAccomp_TogglePlayback",
    "LABEL_F46232": "SeqAccomp_ToggleSetZero",
    "LABEL_F46237": "SeqAccomp_ToggleSendStatus",
    "LABEL_F46240": "SeqAccomp_HandleStartStop",
    "LABEL_F46283": "SeqAccomp_ActivateAndAssign",
    "LABEL_F46298": "SeqAccomp_HandleOtherState",
    "LABEL_F462B1": "SeqAccomp_OtherClearBit",
    "LABEL_F462B8": "SeqAccomp_OtherActivate",
    "LABEL_F462C0": "SeqAccomp_SendVoiceAndReturn",
    "LABEL_F462C6": "SeqAccomp_OtherSetBit",
    "LABEL_F462CD": "SeqAccomp_PostModeAndInit",

    # --- NoteEditSy mode scroll area (lines ~22054-22123) ---
    "LABEL_F462E2": "NoteEdit_ScrollToggle",
    "LABEL_F462F0": "NoteEdit_ScrollSetZero",
    "LABEL_F462F5": "NoteEdit_ScrollDispatchMode",
    "LABEL_F46301": "NoteEdit_ScrollCallReset",
    "LABEL_F46306": "NoteEdit_ScrollCheck86",
    "LABEL_F46313": "NoteEdit_ScrollCheck87",
    "LABEL_F46320": "NoteEdit_ScrollCheck88",
    "LABEL_F4632D": "NoteEdit_ScrollInactive",
    "LABEL_F4633D": "NoteEdit_ScrollActivate",

    # --- NoteEditSy mode scroll return area (lines ~22125-22152) ---
    "LABEL_F4636E": "NoteEdit_ReturnSetZero",
    "LABEL_F46373": "NoteEdit_ReturnGetParam",
    "LABEL_F46378": "NoteEdit_ReturnSendToggle",

    # --- LABEL_F46381 area - voice reassign (lines ~22154-22248) ---
    "LABEL_F46381": "SeqAccomp_ReassignVoiceState",
    "LABEL_F46392": "SeqAccomp_ReassignClearAndSetup",
    "LABEL_F463EB": "SeqAccomp_ReassignCopyLoop",
    "LABEL_F46424": "SeqAccomp_ReassignWriteLoop",
    "LABEL_F46469": "SeqAccomp_ReassignDone",
    "LABEL_F4646B": "SeqAccomp_ReassignEpilogue",
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
