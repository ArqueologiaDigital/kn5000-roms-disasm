#!/usr/bin/env python3
"""Batch 8: Rename remaining LABEL_XXXXXX labels in accompaniment_engine.s (53 labels - bank data, style conversion internals, UI title handlers)"""

import os

RENAMES = {
    # LABEL_F69CC2 and LABEL_F6D84D are referenced from widget_dispatch.s - DO NOT RENAME

    # AccBankData processing internals
    "LABEL_F6BEBE": "AccBankData_CopyLoop_NonZero",
    "LABEL_F6BEF1": "AccBankData_InitSlotScan",
    "LABEL_F6BEFD": "AccBankData_SlotScan_Loop",
    "LABEL_F6BF74": "AccBankData_SlotScan_Next",
    "LABEL_F6BF84": "AccBankData_SlotScan_ReInit",
    "LABEL_F6BF90": "AccBankData_ReInit_ScanLoop",
    "LABEL_F6BFBD": "AccBankData_NotifyAndUpdateTempo",
    "LABEL_F6BFD5": "AccBankData_PostModeChange",
    "LABEL_F6BFE2": "AccBankData_CopyDataBlock",

    # Style name/buffer management
    "LABEL_F6BFF4": "StyleBuf_ClearAllEntries",
    "LABEL_F6BFFF": "StyleBuf_ClearEntry_Outer",
    "LABEL_F6C004": "StyleBuf_ClearEntry_Inner",
    "LABEL_F6C01D": "StyleConv_ClearWorkBuf_Loop",
    "LABEL_F6C026": "StyleConv_ClearEntryTables",
    "LABEL_F6C035": "StyleConv_ClearEntry_Outer",
    "LABEL_F6C03A": "StyleConv_ClearEntry_Inner",

    # StyleConv_InitEntryTable internals
    "LABEL_F6C052": "StyleConvInit_OuterLoop",
    "LABEL_F6C071": "StyleConvInit_InnerLoop",
    "LABEL_F6C07E": "StyleConvInit_StoreChar",

    # SoundMem_ClearRegion loop
    "LABEL_F6C0AA": "SoundMem_ClearLoop",

    # Style file table management
    "LABEL_F6C0B7": "StyleFile_ClearAllTables",
    "LABEL_F6C0C6": "StyleFile_ClearTable_Outer",
    "LABEL_F6C0CB": "StyleFile_ClearTable_Inner",

    # DialUI_CalcProlog internals
    "LABEL_F6C108": "DialCalc_EventLoop",
    "LABEL_F6C127": "DialCalc_SetMode12",
    "LABEL_F6C12E": "DialCalc_SetMode15",
    "LABEL_F6C15C": "DialCalc_Return",
    "LABEL_F6C160": "__pad_F6C160",

    # StylCnvWaitTtlFunc internals
    "LABEL_F6C1A9": "StylCnvWait_SetStatus",
    "LABEL_F6C1B0": "StylCnvWait_CheckPending",
    "LABEL_F6C1CA": "StylCnvWait_HandleClose",
    "LABEL_F6C1D8": "StylCnvWait_RestoreDisplay",
    "LABEL_F6C1DE": "__pad_F6C1DE",

    # StylCnvTxtTtlFunc internals
    "LABEL_F6C21C": "StylCnvTxt_HandleClose",
    "LABEL_F6C229": "__pad_F6C229",

    # StylCnvContTtlFunc internals
    "LABEL_F6CB6D": "StylCnvCont_CheckPending",
    "LABEL_F6CB87": "StylCnvCont_HandleClose",
    "LABEL_F6CB93": "StylCnvCont_HandleOK",
    "LABEL_F6CBD5": "StylCnvCont_NotifyPart",

    # StylCnvStorTtlFunc internals
    "LABEL_F6CBDE": "__pad_F6CBDE",
    "LABEL_F6CBF1": "StylCnvStor_HandleClose",
    "LABEL_F6CBFB": "StylCnvStor_ReturnZero",
    "LABEL_F6CBFE": "__pad_F6CBFE",

    # MainStylCnvFunc / error reporting
    "LABEL_F6CC08": "StylCnv_ReportErrorAndReturn",

    # StyleConv_DispatchSoundMemState internals
    "LABEL_F6CC35": "StylCnvDisp_PostMode13",
    "LABEL_F6CC3B": "StylCnvDisp_CheckFE",
    "LABEL_F6CC4B": "StylCnvDisp_CheckType",
    "LABEL_F6CC7E": "StylCnvDisp_Type1_CopyPath",
    "LABEL_F6CC87": "StylCnvDisp_Type2_CheckSubtype",
    "LABEL_F6CCC6": "StylCnvDisp_Subtype10_Process",
    "LABEL_F6CCDF": "StylCnvDisp_CopyAndFinalize",
    "LABEL_F6CCE8": "StylCnvDisp_Subtype80_Process",
    "LABEL_F6CD07": "StylCnvDisp_ScanFileLoop",
}

def main():
    base = "/home/fsanches/compartilhado/kn5000-roms-disasm"
    target_file = os.path.join(base, "maincpu/sequencer/accompaniment_engine.s")

    with open(target_file, 'rb') as f:
        data = f.read()

    all_s_files = []
    skip_files = {'widget_dispatch.s', 'effects_sequencer_screens.s'}
    for root, dirs, files in os.walk(os.path.join(base, "maincpu")):
        for fn in files:
            if fn.endswith('.s'):
                all_s_files.append(os.path.join(root, fn))

    count = 0
    files_modified = set()

    for old_label, new_label in RENAMES.items():
        old_bytes = old_label.encode('ascii')
        new_bytes = new_label.encode('ascii')

        if old_bytes in data:
            data = data.replace(old_bytes, new_bytes)
            count += 1
            files_modified.add(target_file)

        for sf in all_s_files:
            if sf == target_file or os.path.basename(sf) in skip_files:
                continue
            with open(sf, 'rb') as f:
                sdata = f.read()
            if old_bytes in sdata:
                sdata = sdata.replace(old_bytes, new_bytes)
                with open(sf, 'wb') as f:
                    f.write(sdata)
                files_modified.add(sf)
                print(f"  Cross-ref: {old_label} -> {new_label} in {os.path.basename(sf)}")

    with open(target_file, 'wb') as f:
        f.write(data)

    print(f"\nRenamed {count} labels in {len(files_modified)} files")

if __name__ == "__main__":
    main()
