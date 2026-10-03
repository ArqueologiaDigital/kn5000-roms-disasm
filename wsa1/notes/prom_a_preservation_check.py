#!/usr/bin/env python3
"""Did this pass DESTROY anything in prom_a's listing, or only ADD to it?

QUESTION IT ANSWERS
-------------------
  "Every comment line and every label that was in prom_a at commit REF -- is it
   still there, verbatim?"

★ WHY THE BYTE GATE IS NOT ENOUGH.  `scripts/analysis/assert_byte_identical.py`
proves the file still assembles to the ROM.  Comments and label NAMES assemble
to nothing, so a pass that deleted a 400-line documentation header, or quietly
renamed a semantic label back to `sub_XXXXXX`, would pass the gate in silence.
This is the instrument for that, and it is the one a naming pass owes a
reviewer.

WHAT IT CHECKS
  COMMENTS  every `;`-comment line of REF's copy, compared as a MULTISET after
            stripping trailing whitespace.  A multiset, not a set: deleting one
            of two identical lines is a deletion.
  LABELS    every column-0 label of REF's copy is still defined.  A label that
            is gone must be declared in RENAMES below, and its new name must be
            present -- so a rename is ALLOWED but must be DECLARED, and an
            undeclared disappearance fails.
  ⚠ It says nothing about lines that were ADDED.  Adding is the point.

USAGE
    python3 notes/prom_a_preservation_check.py              # vs HEAD
    python3 notes/prom_a_preservation_check.py --ref <rev>  # vs any commit
    python3 notes/prom_a_preservation_check.py --list       # the deltas
"""
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_text, image_text_at_rev      # noqa: E402

PATH = "prom_a/wsa1_prom_a.s"
LABEL = re.compile(r'^([A-Za-z_.][A-Za-z0-9_.]*):')

# Renames this pass declares.  old -> new.  A label missing from the working
# copy is a FAILURE unless it is a key here and its value is present.
# ⚠ DECLARED STATICALLY, not read back from the applier.  The applier's --plan
# is empty once --apply has run -- there is nothing left to rename -- so a probe
# that asked it would forgive every loss the moment the work was done.  A
# declaration has to survive the thing it declares.
RENAMES = {
    "sub_F95765": "ScreenLeave_GateArrayCheck",
    "sub_F95766": "ScreenButton_GateArrayCheck",
    "sub_F95795": "ScreenLeave_PanelCpuCheck",
    "sub_F95796": "ScreenButton_PanelCpuCheck",
    "sub_F95890": "ScreenLeave_SineWaveCheckMode",
    "sub_F95891": "ScreenButton_SineWaveCheckMode",
    "sub_F959BD": "ScreenLeave_PanelSwLedCheck",
    "sub_F959BE": "ScreenButton_PanelSwLedCheck",
    "sub_F99831": "ScreenLeave_SysexBulkDump_Entry",
    "sub_F99835": "ScreenButton_SysexBulkDump_Entry",
    "sub_F99848": "ScreenLeave_GeneralMidiMode_Entry",
    "sub_F9984C": "ScreenButton_GeneralMidiMode_Entry",
    "sub_F9A26D": "ScreenLeave_MidiTotalMode",
    "sub_F9A26F": "ScreenButton_MidiTotalMode",
    "sub_F9A754": "ScreenLeave_MidiRealtimeMessages",
    "sub_F9A756": "ScreenButton_MidiRealtimeMessages",
    "sub_F9AA4F": "ScreenLeave_MidiInputOutputFilter",
    "sub_F9AA51": "ScreenButton_MidiInputOutputFilter",
    "sub_F9B05E": "ScreenLeave_MidiOutProgramChange",
    "sub_F9B060": "ScreenButton_MidiOutProgramChange",
    "sub_FE8060": "ScreenButton_Sequencer",
    "sub_FE8165": "ScreenLeave_Sequencer",
    "sub_FF431C": "PanelButtonDispatch_DiskMenu",
    "sub_FF457C": "ScreenLeave_MidiFileDirectPlay",
    "sub_FF4596": "PanelButtonDispatch_MidiFileDirectPlay",
    "sub_FF45F6": "LcdKeyRow2_MidiFileDirectPlay",
    "sub_FF4986": "ScreenLeave_DiskL0adFile",
    "sub_FF4995": "PanelButtonDispatch_DiskL0adFile",
    "sub_FF4A91": "LcdKeyRow3_DiskL0adFile",
    "sub_FF4ACB": "LcdKeyRow4_DiskL0adFile",
    "sub_FF4D5D": "LcdKeyRow5_DiskL0adFile",
    "sub_FF520C": "ScreenLeave_MidiFileL0ad",
    "sub_FF522F": "PanelButtonDispatch_MidiFileL0ad",
    "sub_FF52E2": "LcdKeyRow2_MidiFileL0ad",
    "sub_FF548A": "PageDispatch_DiskSaveFile",
    "sub_FF572E": "PanelButtonDispatch_DiskSaveFile",
    "sub_FF5A69": "LcdKeyRow2_DiskSaveFile_Page1",
    "sub_FF5C3E": "PageDispatch_MidiFileSave",
    "sub_FF5ED1": "PanelButtonDispatch_MidiFileSave",
    "sub_FF654F": "ScreenLeave_FloppyDiskFormatSelectType",
    "sub_FF6550": "PanelButtonDispatch_FloppyDiskFormatSelectType",
    "sub_FF66A9": "ScreenLeave_FloppyDiskFormatAreYouSure",
    "sub_FF66AA": "PanelButtonDispatch_FloppyDiskFormatAreYouSure",
    "sub_FF672D": "PageDispatch_L0adSingleS0und",
    "sub_FF68D8": "PanelButtonDispatch_L0adSingleS0und",
    "sub_FF6DB7": "PageDispatch_L0adSingleC0mbination",
    "sub_FF6F21": "PanelButtonDispatch_L0adSingleC0mbination",
    # 2026-10-03, session 53b889a2: the WSA1 naming passes of scripts/renaming/rename_wsa1_{panel_dial,
    # var27a3_slot,u8rec16,var27a3_var27db,tonemsg,ff75_wrappers,ff77_disk,veneers_to_named,table_entries,
    # screen_code_methods}.sed.  sub_FD644D / sub_FD649A were unreferenced labels inside ToneMsg80_Id00 /
    # ToneMsg80_Id04 and were removed, so they map to the routine that now covers their address.
    "sub_FD7BC3": "PanelDial_SetButtonMode",
    "sub_FD7BDE": "PanelDial_SetDirectionButton",
    "sub_FD7C01": "PanelDial_ActAsButton",
    "sub_FD6B4D": "Var27A3_GetValidSlot",
    "sub_FD6C34": "Var27A4_SlotEnabled",
    "sub_FD6C94": "U8_ShiftLeft",
    "sub_FD6CBA": "U8_ShiftRight",
    "sub_FB6219": "U8Rec16_SetField",
    "sub_FB62D3": "U8Rec16_GetField",
    "JumpTable_FB6240": "U8Rec16_SetField_Cases",
    "JumpTable_FB62F6_Code_Skip": "U8Rec16_GetField_OutOfRange",
    "JumpTable_FB62F6": "U8Rec16_GetField_Cases",
    "sub_FB6280": "U8Rec16_SetField_Case0",
    "sub_FB6285": "U8Rec16_SetField_Case1",
    "sub_FB628A": "U8Rec16_SetField_Case2",
    "sub_FB628F": "U8Rec16_SetField_Case3",
    "sub_FB6294": "U8Rec16_SetField_Case4",
    "sub_FB6299": "U8Rec16_SetField_Case5",
    "sub_FB629E": "U8Rec16_SetField_Case6",
    "sub_FB62A3": "U8Rec16_SetField_Case7",
    "sub_FB62A8": "U8Rec16_SetField_Case8",
    "sub_FB62AD": "U8Rec16_SetField_Case9",
    "sub_FB62B2": "U8Rec16_SetField_Case10",
    "sub_FB62B7": "U8Rec16_SetField_Case11",
    "sub_FB62BC": "U8Rec16_SetField_Case12",
    "sub_FB62C1": "U8Rec16_SetField_Case13",
    "sub_FB62C6": "U8Rec16_SetField_Case14",
    "sub_FB62CB": "U8Rec16_SetField_Case15",
    "sub_FB6336": "U8Rec16_GetField_Case0",
    "sub_FB633D": "U8Rec16_GetField_Case1",
    "sub_FB6345": "U8Rec16_GetField_Case2",
    "sub_FB634D": "U8Rec16_GetField_Case3",
    "sub_FB6355": "U8Rec16_GetField_Case4",
    "sub_FB635C": "U8Rec16_GetField_Case5",
    "sub_FB6363": "U8Rec16_GetField_Case6",
    "sub_FB636A": "U8Rec16_GetField_Case7",
    "sub_FB6371": "U8Rec16_GetField_Case8",
    "sub_FB6378": "U8Rec16_GetField_Case9",
    "sub_FB637F": "U8Rec16_GetField_Case10",
    "sub_FB6386": "U8Rec16_GetField_Case11",
    "sub_FB638D": "U8Rec16_GetField_Case12",
    "sub_FB6394": "U8Rec16_GetField_Case13",
    "sub_FB639B": "U8Rec16_GetField_Case14",
    "sub_FB63A2": "U8Rec16_GetField_Case15",
    "sub_FD6B2E": "Var27A3_SetSlot",
    "sub_FD74AE": "Var27A3_ChangeSlot",
    "sub_FD7719": "Var27DB_Increment",
    "sub_FD6132": "ToneMsg_Send",
    "sub_FD6917": "ToneMsg_ApplySelector",
    "sub_FD616A": "ToneMsg_SendParam",
    "sub_FD61CF": "ToneMsg80_SendParam",
    "sub_FD622B": "ToneMsg80_Id01",
    "sub_FD62B4": "ToneMsg80_Id12",
    "sub_FD6316": "ToneMsg80_Id13",
    "sub_FD638B": "ToneMsg80_Id10",
    "sub_FD63D7": "ToneMsg85_SendParam",
    "sub_FD6447": "ToneMsg80_Id00",
    "sub_FD648D": "ToneMsg80_Id04",
    "sub_FD64D1": "ToneMsg80_Id15_Part0",
    "sub_FD6513": "ToneMsg80_Id16",
    "sub_FD655D": "ToneMsg88_Id15",
    "sub_FD65D8": "ToneMsg88_Id16",
    "sub_FD6669": "ToneMsg88_Id13",
    "sub_FD66A6": "ToneMsg88_Id14",
    "sub_FD6704": "ToneMsg8D_SendParam",
    "sub_FD677F": "ToneMsg88_Id00",
    "sub_FD67C9": "ToneMsg88_Id0D",
    "sub_FD6811": "ToneMsg88_Id1A",
    "sub_FD686B": "ToneMsg80_Id0B_Part0",
    "sub_FF75D3": "DisplayList_RunOnLayer_SaveRegs",
    "sub_FF75EF": "DisplayListB_Run_SaveRegs",
    "sub_FF7604": "LCD_BlankAndSetPanel3Layer_SaveRegs",
    "sub_FF7623": "DLB_Array8_2_OnLayer1_SaveRegs",
    "sub_FF763F": "DLB_Array8_SaveRegs",
    "sub_FF767F": "Disk_DrawDirectory20",
    "sub_FF76B5": "Disk_DrawDirEntry",
    "sub_FF770F": "LCD_DrawDiskFileName6_SaveRegs",
    "sub_FF7729": "LCD_DrawDiskFileName8_SaveRegs",
    "sub_FF7743": "UI_ScreenItem_StepByDial",
    "sub_FF7776": "Disk_FormatSelectedEntry_SaveRegs",
    "sub_FF7783": "Disk_FormatSelectedEntry",
    "sub_FF77A7": "Disk_DirEntryPtr",
    "sub_FF77BC": "Disk_SetStatusFromCheck",
    "sub_FF77E3": "Disk_CheckSelectedEntrySignature",
    "sub_FF7826": "Disk_CopyDirEntryToFileName",
    "sub_FF7832": "Disk_CopyEntry2724HeadToFileName_SaveRegs",
    "sub_FF7846": "LCD_DrawVar272ENumberTag_SaveRegs",
    "sub_FF7895": "LCD_SwiTextCall_SaveRegs",
    "sub_FF78B5": "MemCpy_C",
    "sub_F44039": "Nop_CallsEmptyDirectorySlot_Veneer",
    "sub_F67450": "MsgLine_PartVolume_Veneer",
    "sub_F67454": "MsgLine_PartEffect_Veneer",
    "sub_F67458": "MsgLine_NoteName_Veneer",
    "sub_F67468": "MsgLine_TotalReverb_Veneer",
    "sub_F73840": "Smf_WriteFile_Veneer",
    "sub_F7A408": "BStore_LatchHeapBase_Veneer",
    "sub_F7AA00": "BStore_AppendBytes_Join3_Veneer",
    "sub_F7AA02": "BStore_AppendBytes_Join4_Veneer",
    "sub_FA5935": "PanelLed_ToggleActivityLed_SaveRegs",
    "sub_FAAB1B": "Queue2C00_DrainPassB_SaveRegs2",
    "sub_FAB911": "List2030_PartBendRange_Apply_Call",
    "sub_FB203C": "SoundGroup_ReloadSelection_SaveRegs",
    "sub_FB313C": "ParamImage_QueueDiffAll_SaveRegs",
    "sub_FB7AE4": "Mode_SwitchToCombination_SaveRegs",
    "sub_FB7AF1": "Mode_SwitchToSound_SaveRegs",
    "sub_FB7AFE": "PanelLed_ToggleActivityLed_SaveRegs2",
    "sub_FB7E9B": "MessageScreen_Paint_SaveRegs",
    "sub_FE0060": "ParamImage_WriteRecordHeaders_Entry_SaveRegs",
    "sub_FE0083": "ParamImage_SanitizeAllAndHook_Entry_SaveRegs",
    "sub_FE009D": "ParamImage_QueueDiffAll_SaveRegs2",
    "sub_FE00C4": "Queue2C00_DrainPassB_SaveRegs3",
    "sub_FE01FA": "MessageScreen_Paint_SaveRegs2",
    "sub_FE1BCA": "SysPartMidi_ResetBlock1Default_Call",
    "sub_F7C743": "SongStore_DispatchA_Case1",
    "sub_F7C75C": "SongStore_DispatchA_Case2",
    "sub_F7C78C": "SongStore_DispatchA_Case3",
    "sub_F7C7BC": "SongStore_DispatchA_Case4",
    "sub_F7C9B0": "SongStore_DispatchB_Case1",
    "sub_F7C9C9": "SongStore_DispatchB_Case2",
    "sub_F7C9F5": "SongStore_DispatchB_Case3",
    "sub_F7CA21": "SongStore_DispatchB_Case4",
    "sub_F7CA48": "SongStore_DispatchB_Case5",
    "sub_F7CBE1": "SongStore_DispatchC_Case1",
    "sub_F7CBFA": "SongStore_DispatchC_Case2",
    "sub_F7CC27": "SongStore_DispatchC_Case3",
    "sub_F7CC54": "SongStore_DispatchC_Case4",
    "sub_F7F0E7": "MeasureDelete_StageZero_Button21",
    "sub_F7F3E2": "MeasureErase_StageZero_Button21",
    "sub_F7F74E": "Quantize_StageZero_Button21",
    "sub_F7FA43": "Vel0cityChange_StageZero_Button21",
    "sub_F7FD8A": "Transp0se_StageZero_Button21",
    "sub_FA7531": "MidiOut_Param70",
    "sub_FA7584": "MidiOut_Param98",
    "sub_FD3FE0": "ToneEditPage_A0_Op0",
    "sub_FD4039": "ToneEditPage_A0_Op1",
    "sub_FD40D4": "ToneEditPage_A0_Op2",
    "sub_FD43C6": "ToneEditPage_A0_Op8",
    "sub_FD43E4": "ToneEditPage_A0_Op9",
    "sub_FD440A": "ToneEditPage_A0_Op10",
    "sub_FD4430": "ToneEditPage_A0_Op11",
    "sub_FD4468": "ToneEditPage_A0_Op12",
    "sub_FD4493": "ToneEditPage_A0_Op15",
    "sub_FD4712": "ToneEditPage_A3_Op8",
    "sub_FD4730": "ToneEditPage_A3_Op9",
    "sub_FD475C": "ToneEditPage_A3_Op10",
    "sub_FD4780": "ToneEditPage_A3_Op11",
    "sub_FD47AC": "ToneEditPage_A3_Op12",
    "sub_FD47D0": "ToneEditPage_A3_Op16",
    "sub_FD47E8": "ToneEditPage_A3_Op15",
    "sub_FD49D8": "ToneEditPage_A4_Op8",
    "sub_FD49F6": "ToneEditPage_A4_Op9",
    "sub_FD4A22": "ToneEditPage_A4_Op10",
    "sub_FD4A46": "ToneEditPage_A4_Op11",
    "sub_FD4A72": "ToneEditPage_A4_Op12",
    "sub_FD4A96": "ToneEditPage_A4_Op16",
    "sub_FD4AAE": "ToneEditPage_A4_Op15",
    "sub_FD501D": "ToneEditPage_A5_Op8",
    "sub_FD503B": "ToneEditPage_A5_Op9",
    "sub_FD5067": "ToneEditPage_A5_Op10",
    "sub_FD5093": "ToneEditPage_A5_Op11",
    "sub_FD5114": "ToneEditPage_A5_Op12",
    "sub_FD5141": "ToneEditPage_A5_Op16",
    "sub_FD5159": "ToneEditPage_A5_Op15",
    "sub_FD546F": "ToneEditPage_A6_Op8",
    "sub_FD548D": "ToneEditPage_A6_Op9",
    "sub_FD54B9": "ToneEditPage_A6_Op10",
    "sub_FD54E5": "ToneEditPage_A6_Op11",
    "sub_FD5512": "ToneEditPage_A6_Op12",
    "sub_FD553F": "ToneEditPage_A6_Op16",
    "sub_FD555C": "ToneEditPage_A6_Op15",
    "sub_FD5B63": "ToneEditPage_A7_Op8",
    "sub_FD5B81": "ToneEditPage_A7_Op9",
    "sub_FD5BAD": "ToneEditPage_A7_Op10",
    "sub_FD5BD9": "ToneEditPage_A7_Op11",
    "sub_FD5C06": "ToneEditPage_A7_Op12",
    "sub_FD5C33": "ToneEditPage_A7_Op16",
    "sub_FD5C4B": "ToneEditPage_A7_Op15",
    "sub_FD5C63": "ToneEditPage_A8_Op1",
    "sub_FD5CB8": "ToneEditPage_A8_Op2",
    "sub_FD5D01": "ToneEditPage_A8_Op3",
    "sub_FD5D56": "ToneEditPage_A8_Op4",
    "sub_FD5DA3": "ToneEditPage_A8_Op5",
    "sub_FD5F3E": "ToneEditPage_A8_Op6",
    "sub_FD6043": "ToneEditPage_A8_Op7",
    "sub_FD6057": "ToneEditPage_A8_Op15",
    "sub_FDAD44": "ScreenCode80_Handler",
    "sub_FDB22F": "ScreenCode87_Handler",
    "sub_FDB38C": "ScreenCode88_Handler",
    "sub_FDB44D": "ScreenCode89_Handler",
    "sub_FDB529": "ScreenCode8A_Handler",
    "sub_FDB693": "ScreenCode8B_Handler",
    "sub_FDB8D9": "ScreenCode8C_Handler",
    "sub_FDB9AB": "ScreenCode8D_Handler",
    "sub_FDBAE7": "ScreenCode8E_Handler",
    "sub_FDBBC3": "ScreenCode8F_Handler",
    "sub_FDBBD6": "ScreenCodeCD_Handler",
    "sub_FDBEDE": "ScreenCode9B_Handler",
    "sub_FDC0E1": "ScreenCode9C_Handler",
    "sub_FDC0ED": "ScreenCode90_Handler",
    "sub_FDC27B": "ScreenCode91_Handler",
    "sub_FDC2A7": "ScreenCode92_Handler",
    "sub_FDC2CF": "ScreenCode93_Handler",
    "sub_FDC2F7": "ScreenCode94_Handler",
    "sub_FDC317": "ScreenCode95_Handler",
    "sub_FDC333": "ScreenCode96_Handler",
    "sub_FDC405": "ScreenCode97_Handler",
    "sub_FDC4C6": "ScreenCode98_Handler",
    "sub_FDC5A2": "ScreenCode99_Handler",
    "sub_FDC5B5": "ScreenCode82_Handler",
    "sub_FDC84C": "ScreenCode83_Handler",
    "sub_FDC95B": "ScreenCode84_Handler",
    "sub_FDCA77": "ScreenCode85_Handler",
    "sub_FDCB93": "ScreenCode86_Handler",
    "sub_FDCDE0": "ScreenCode9E_Handler",
    "sub_FDCFEB": "ScreenCode9F_Handler",
    "sub_FDD0D4": "ScreenCode9D_Handler",
    "sub_FDD272": "ScreenCodeCA_Handler",
    "sub_FDD27F": "ScreenCodeCB_Handler",
    "sub_FDD437": "ScreenCodeC0_Handler",
    "sub_FDDF36": "ScreenCodeC8_Handler",
    "sub_FCFDA7": "ScreenButton_Code80",
    "sub_FD053D": "ScreenButton_CodeCD",
    "sub_FD058E": "ScreenButton_Code9B",
    "sub_FD0AA5": "ScreenButton_Code82",
    "sub_FD0AF6": "ScreenButton_Code83",
    "sub_FD0B47": "ScreenButton_Code84",
    "sub_FD0BA7": "ScreenButton_Code85",
    "sub_FD0C07": "ScreenButton_Code86",
    "sub_FD2751": "ScreenButton_Code8B",
    "sub_FD27A2": "ScreenButton_Code8C",
    "sub_FD27F2": "ScreenButton_Code8D",
    "sub_FD2852": "ScreenButton_Code8E",
    "sub_FD28B2": "ScreenButton_Code8F",
    "sub_FDE152": "ScreenLeave_Code80",
    "sub_FDE160": "ScreenLeave_Code87",
    "sub_FDE16E": "ScreenLeave_Code88",
    "sub_FDE17C": "ScreenLeave_Code89",
    "sub_FDE18A": "ScreenLeave_Code8A",
    "sub_FDE198": "ScreenLeave_Code8B",
    "sub_FDE1A6": "ScreenLeave_Code8C",
    "sub_FDE1B4": "ScreenLeave_Code8D",
    "sub_FDE1C2": "ScreenLeave_Code8E",
    "sub_FDE1D0": "ScreenLeave_Code8F",
    "sub_FDE1DE": "ScreenLeave_CodeCD",
    "sub_FDE1EC": "ScreenLeave_Code9B",
    "sub_FDE1FA": "ScreenLeave_Code9C",
    "sub_FDE208": "ScreenLeave_Code82",
    "sub_FDE216": "ScreenLeave_Code83",
    "sub_FDE224": "ScreenLeave_Code84",
    "sub_FDE232": "ScreenLeave_Code85",
    "sub_FDE240": "ScreenLeave_Code86",
    "sub_FDE24E": "ScreenLeave_Code90",
    "sub_FDE25C": "ScreenLeave_Code91",
    "sub_FDE26A": "ScreenLeave_Code92",
    "sub_FDE278": "ScreenLeave_Code93",
    "sub_FDE286": "ScreenLeave_Code94",
    "sub_FDE294": "ScreenLeave_Code95",
    "sub_FDE2A2": "ScreenLeave_Code96",
    "sub_FDE2B0": "ScreenLeave_Code97",
    "sub_FDE2BE": "ScreenLeave_Code98",
    "sub_FDE2CC": "ScreenLeave_Code99",
    "sub_FDE2FA": "ScreenLeave_Code9D",
    "sub_FDE308": "ScreenLeave_CodeCA",
    "sub_FDE316": "ScreenLeave_CodeCB",
    "sub_FDE332": "ScreenLeave_CodeC0",
    "sub_FDE3A2": "ScreenLeave_CodeC8",
    "sub_FDE3BE": "ScreenButton_Code90",
    "sub_FDE41E": "ScreenButton_Code91",
    "sub_FDE47E": "ScreenButton_Code92",
    "sub_FDE4DE": "ScreenButton_Code93",
    "sub_FDE53E": "ScreenButton_Code94",
    "sub_FDE59E": "ScreenButton_Code95",
    "sub_FDE5EF": "ScreenButton_Code96",
    "sub_FDE64F": "ScreenButton_Code97",
    "sub_FDE6AF": "ScreenButton_Code98",
    "sub_FDE70F": "ScreenButton_Code99",
    "sub_FD644D": "ToneMsg80_Id00",
    "sub_FD649A": "ToneMsg80_Id04",
    "sub_FEAA86": "UI_GotoScreen24",
    "sub_FEAA8D": "UI_GotoScreen27",
    "sub_FE8CEE": "BStore_CursorSlot_Save",
    "sub_FE8D15": "BStore_CursorSlot_Restore",
    "sub_FE8BF8": "BStore_CursorSlot_RestoreMark",
    "sub_FF712A": "PanelDial_SetButtonPair",
    "sub_FF759C": "UI_StatusCode_Is0or2or4",
    "sub_FF7525": "Var2728_Is2or3",
    "sub_FF753B": "Var7FD6_IsBitClear",
    "sub_F99F1A": "Var2134_SetBit1",
    "sub_F99F1F": "Var2134_SetBit1_2",
    "sub_FBFDF0": "Var277E_Set02",
    "sub_FE2EF2": "Var220D_SetW4157",
    "sub_FE2FB9": "Var2216_SetW145C",
    "sub_FE2FC0": "Var2216_SetW145A",
    "sub_FF42C0": "Var2134_SetBit1_3",
    "sub_F009A8": "Var20D4_ClearBitsC0",
    "sub_F45FAE": "Var20A9_SetBits01",
    "sub_F45FC4": "Var34D1_SetBits20",
    "sub_F4C4B0": "UI_RequestBits_ClearBit7",
    "sub_F4EC25": "Var34BB_ClearBits04",
    "sub_F7F1C2": "Var2820_Set2B",
    "sub_F7F4EE": "Var2820_Set2B_2",
    "sub_F7F85A": "Var2820_Set2B_3",
    "sub_FD7693": "Arr27D6_GetForSlot",
    "sub_FD76BF": "Var27A3_GetPackedSlot",
    "sub_FD7744": "Rec2330_CopyData",
    "sub_FD69E0": "ToneMsg_SendP23FromArr2800",
    "sub_FDAC5B": "LCD_SetPanelDarkFlag",
    "sub_FD6B07": "Var27A2_SetBool",
    "sub_FD6E90": "Var27A2_ToggleWithP23",
    "sub_FD9863": "Var27A3_SelectSlot",
    "sub_FB6F24": "SysExTx_Append",
    "sub_FB6E7F": "SysExTx_AppendAndSendOnF7",
    "sub_FB6EE9": "SysExTx_AppendRemainingSize",
    "sub_FB7025": "SysExTx_AppendContHeaderIfCont",
    "sub_FB7040": "SysExTx_AppendNibbles",
    "sub_FB70AE": "SysExTx_AppendContFlag",
    "sub_FB70E6": "SysExTx_AppendContFlagOne",
    "sub_FB7111": "SysExTx_AppendChecksumF7",
    "sub_FB7165": "SysExTx_SendFrameMidi1",
    "sub_FB71BB": "SysExTx_SendFrameBothPorts",
    "sub_FB5F65": "SysExTx_PatchModelByteVariant2",
    "sub_FB8081": "SysExTx_SwapBuffers",
    "sub_FB8105": "SysExTx_ResetBuffer",
    "sub_FB8028": "SysExRx_SwapBuffers",
    "sub_FB80F3": "SysExRx_ResetBuffer",
    "sub_FB7FEB": "SysExBuf_Reset",
    "sub_FB7F42": "SysExBuf_InitAll",
    "sub_FB6165": "SysExRx_AppendByte",
    "sub_FB61B1": "SysExBuf_ReadByte",
    "sub_FB20CE": "SysExRx_PollRing601646",
    "sub_FB21CB": "SysExRx_PollRing601C6E",
    "sub_FB2160": "SysExRx_ParseDispatch_Ring601646",
    "sub_FB225D": "SysExRx_ParseDispatch_Ring601C6E",
    "sub_FB63AF": "SysExRx_ParseMessage",
    "sub_FB63D1": "SysExRx_MatchTrie",
    "sub_FB6B87": "SysExRx_CheckCommandClass",
    "sub_FB6BF4": "SysExRx_CheckAddress",
    "sub_FB6CFC": "SysExRx_CheckBodyLength",
    "sub_FB6DBD": "SysExRx_VerifyChecksum",
    "sub_FB6098": "SysExRx_ReceiveBlocking",
    "sub_FB6072": "SysExRx_AwaitReply",
    "sub_FB775F": "SysExRx_CheckMidiErrors",
    "sub_FB7785": "SysExRx_CheckReplyTimeout",
    "sub_FB77C7": "SysEx_Wait25Ticks",
    "sub_FB6026": "SysExDump_AwaitFrameAck",
    "sub_FB6F6B": "SysExDump_SendFrames",
    "sub_FB6FB2": "SysExDump_SendFramesStreamed",
    "sub_FB2323": "SysExDump_Handshake",
    "sub_FB277E": "SysExDump_SendCategoryDone",
    "sub_FB27AD": "SysExDump_SendJobDone",
    "JumpTable_FB2081": "SysExDump_JobTable",
    "sub_FB2099": "SysExDump_Job0_TotalKeyboard",
    "sub_FB209F": "SysExDump_Job1_None",
    "sub_FB20A5": "SysExDump_Job2_Sequencer",
    "sub_FB20AB": "SysExDump_Job3_Sound",
    "sub_FB20B1": "SysExDump_Job4_SystemPartMidi",
    "sub_FB20B7": "SysExDump_Job5_Combination",
    "sub_FB22CD": "SysExJob_TotalKeyboard",
    "sub_FB22E7": "SysExJob_Sequencer",
    "sub_FB22F6": "SysExJob_Sound",
    "sub_FB2305": "SysExJob_SystemPartMidi",
    "sub_FB2314": "SysExJob_Combination",
    "sub_FB23E2": "SysExDump_SendAllCategories",
    "sub_FB23EF": "SysExDump_SendSystemPartMidi",
    "sub_FB23F9": "SysExDump_SendSystemPart1",
    "sub_FB243E": "SysExDump_SendSystemPart2",
    "sub_FB2483": "SysExDump_SendSound",
    "sub_FB2587": "SysExDump_SendSequencer",
    "sub_FB25A2": "SysExDump_SendSequencerPart1",
    "sub_FB25E7": "SysExDump_SendSequencerPart2",
    "sub_FB262C": "SysExDump_SendSequencerPart3",
    "sub_FB2675": "SysExDump_SendCombination",
    "sub_FB267F": "SysExDump_SendCombinationPart1",
    "sub_FB26E7": "SysExDump_SendCombinationPart2",
    "sub_FB749B": "SysExXfer_SetJobTotal_TotalKeyboard",
    "sub_FB74D7": "SysExXfer_SetJobTotal_SystemPartMidi",
    "sub_FB751A": "SysExXfer_SetJobTotal_Sound",
    "sub_FB753E": "SysExXfer_SetJobTotal_Sequencer",
    "sub_FB758A": "SysExXfer_SetJobTotal_Combination",
    "sub_FB75BA": "SysExXfer_SetPart_SystemPart1",
    "sub_FB75E4": "SysExXfer_SetPart_SystemPart2",
    "sub_FB7629": "SysExXfer_SetPart_SoundOrphan",
    "sub_FB7649": "SysExXfer_SetPart_SoundBlock",
    "sub_FB766F": "SysExXfer_SetPart_Sequencer1",
    "sub_FB7692": "SysExXfer_SetPart_Sequencer2",
    "sub_FB76B5": "SysExXfer_SetPart_Sequencer3",
    "sub_FB76F2": "SysExXfer_SetPart_Combination1",
    "sub_FB7722": "SysExXfer_SetPart_CombinationBlock",
    "sub_FB7748": "SysExDump_SequencerUsedBytes",
    "sub_FB7DFE": "SysExDump_ShowResult",
    "sub_FB7E29": "SysExDump_ShowCompleted",
    "sub_FB7E38": "SysExDump_ShowScreenB3",
    "sub_FB7E43": "SysExDump_ShowStatusMessage",
    "AsciiRun_F511C7": "SysExStatus_MessageIdMap",
    "sub_FB8156": "SysEx_ResetSession",
    "sub_FB7F1F": "SysEx_ClearRemoteId",
    "sub_FB5FF5": "SysEx_FeatureWordForVariant",
    "sub_FB2877": "SysExSession_DispatchCommand",
    "sub_FAB337": "ParamRecord_MergeFieldIfChanged",
    "sub_FB782B": "IndexedTable_MergeMaskedByte",
    "sub_FB7890": "IndexedTable_MergeMaskedByteAndPost",
    "sub_FB791C": "IndexedTable_MergeMaskedWordAndPost",
    "sub_FB7A02": "IndexedTable_GetByteOr0",
    "sub_FB77F3": "SysExBuf_ReadNibblePair",
    "sub_FB7A90": "SysEx_Checksum",
    "sub_FB7AC2": "SysExTx_SendBytes",
    "sub_FB34F1": "SysExParam_Set_DispatchGroup",
    "JumpTable_FB3517": "SysExParam_Set_GroupTable",
    "sub_FB3533": "SysExParam_Set_Group1",
    "sub_FB3538": "SysExParam_Set_Group2",
    "sub_FB353D": "SysExParam_Set_Group3",
    "sub_FB3547": "SysExParam_Set_Group5",
    "sub_FB354C": "SysExParam_Set_Group6",
    "sub_FB3551": "SysExParam_Set_Group7",
    "JumpTable_FB42D1": "SysExParam_Request_GroupTable",
    "sub_FB42ED": "SysExParam_Request_Group1",
    "sub_FB42F2": "SysExParam_Request_Group2",
    "sub_FB42F7": "SysExParam_Request_Group3",
    "sub_FB4301": "SysExParam_Request_Group5",
    "sub_FB4306": "SysExParam_Request_Group6",
    "sub_FB430B": "SysExParam_Request_Group7",
    "sub_FB3555": "SysExParam_Set_Area00_01",
    "sub_FB35A9": "SysExParam_Set_Area08",
    "sub_FB35FC": "SysExParam_Set_Area10_11",
    "sub_FB3651": "SysExParam_Set_PartGroup5",
    "sub_FB36A5": "SysExParam_Set_PartGroup6",
    "sub_FB36F9": "SysExParam_Set_Area60",
    "sub_FB430F": "SysExParam_Request_Area00_01",
    "sub_FB4363": "SysExParam_Request_Area08",
    "sub_FB43B6": "SysExParam_Request_Area10_11",
    "sub_FB440B": "SysExParam_Request_PartGroup5",
    "sub_FB445F": "SysExParam_Request_PartGroup6",
    "sub_FB44B3": "SysExParam_Request_Area60",
    "sub_FB5066": "SysExParam_CheckConditions",
    "PtrTable_F4F99E": "SysExSession_ContinuationTable",
    "PtrTable_F4F9E6": "SysExSession_CategoryEndTable",
    "PtrTable_F4FA2E": "SysExSession_AbortTable",
    "PtrTable_F4FB38": "SysExTx_StagedParamHandlers",
    "sub_FB2CAD": "SysExSession_RecvBody_SystemPart1",
    "sub_FB2CE7": "SysExSession_RecvBody_SystemPart2",
    "sub_FB2D21": "SysExSession_RecvBody_SoundOrphan",
    "sub_FB328D": "SysExSession_RecvBody_Sound",
    "sub_FB2D72": "SysExSession_RecvBody_Stub0F",
    "sub_FB2DAC": "SysExSession_RecvBody_Stub10",
    "sub_FB2DE6": "SysExSession_RecvBody_Stub11",
    "sub_FB2E20": "SysExSession_RecvBody_SequencerPart1",
    "sub_FB2E69": "SysExSession_RecvBody_SequencerPart2",
    "sub_FB2EB2": "SysExSession_RecvBody_SequencerPart3",
    "sub_FB2EFB": "SysExSession_RecvBody_CombinationPart1",
    "sub_FB2F35": "SysExSession_RecvBody_CombinationPart2",
    "sub_FB3251": "SysExSession_AbortByStep",
    "sub_FB7EA8": "SysExSession_OnAbort_SystemPartMidi",
    "sub_FB7ED2": "SysExSession_OnAbort_Sound",
    "sub_FB7EE5": "SysExSession_OnAbort_Sequencer",
    "sub_FB72B5": "SysExRx_UnpackBody",
    "sub_FB7365": "SysExRx_UnpackBodyToBlock",
    "sub_FB741A": "SysExRx_SetRunTimeSize",
    "sub_FB4B7D": "SysExTx_EmitStagedParams",
    "sub_FB7270": "StagedQueue_ReadRecord",
    "sub_FE88AA": "EditScreen_EnterNoteEdit",
    "sub_FE8868": "EditScreen_EnterDrumEdit",
    "sub_FE9DB4": "EditCursor_TickPlus1",
    "sub_FE9DD5": "EditCursor_TickPlus5",
    "sub_FE9E04": "EditCursor_NextBeat",
    "sub_FE9F23": "EditCursor_BeatsInMeasure",
    "sub_FEAAB6": "EditCursor_MeasurePlus10",
    "sub_FEAAE0": "EditCursor_MeasureMinus10",
}


def _renames():
    return RENAMES


def ref_text(ref):
    """★ BOTH SIDES ARE READ AS THE IMAGE, not as the file.

    A `git show <rev>:prom_a/wsa1_prom_a.s` on one side and an `open()` on the
    other compares two FILES, and this tree splits images into a primary plus
    included parts.  The day prom_a is split, that comparison would report the
    entire body as LOST -- or, worse, as unchanged in a tree where the primary
    is a header.  asm_source resolves both sides the way llvm-mc does, so the
    answer is about the IMAGE and survives a split on either side."""
    return image_text_at_rev(ROOT, PATH, ref)


def comments(text):
    out = collections.Counter()
    for ln in text.splitlines():
        s = ln.rstrip()
        if s.lstrip().startswith(";"):
            out[s] += 1
    return out


def labels(text):
    return {m.group(1) for m in
            (LABEL.match(ln) for ln in text.splitlines()) if m}


def main():
    argv = sys.argv[1:]
    ref = argv[argv.index("--ref") + 1] if "--ref" in argv else "HEAD"
    old = ref_text(ref)
    new = image_text(ROOT, PATH)

    co, cn = comments(old), comments(new)
    lost = co - cn                       # Counter subtraction: multiset delta

    # ⚠ A DECLARED RENAME REWRITES THE COMMENTS THAT CITE THE OLD NAME, and a
    # naive multiset diff would call every one of those a deletion.  A lost line
    # that becomes a PRESENT line under the declared substitutions is an UPDATE,
    # not a loss -- and it is counted and printed separately rather than
    # forgiven silently, because "how many comments did this pass rewrite" is
    # itself a number a reviewer wants.
    updated = collections.Counter()
    for line, n in list(lost.items()):
        sub = line
        for o, w in RENAMES.items():
            sub = re.sub(r'\b%s\b' % o, w, sub)
        if sub != line and cn.get(sub, 0) >= 1:
            updated[line] += n
            del lost[line]
    lo, ln_ = labels(old), labels(new)
    gone = sorted(lo - ln_)
    undeclared = [g for g in gone if RENAMES.get(g) not in ln_]
    declared = [g for g in gone if RENAMES.get(g) in ln_]

    print("prom_a preservation, working tree vs %s" % ref)
    print("  comment lines   %6d -> %6d   (+%d added)"
          % (sum(co.values()), sum(cn.values()),
             sum(cn.values()) - sum(co.values())))
    print("  comment lines REWRITTEN by a declared rename: %d"
          % sum(updated.values()))
    print("  LOST comment lines: %d" % sum(lost.values()))
    print("  labels          %6d -> %6d" % (len(lo), len(ln_)))
    print("  labels gone: %d, of which DECLARED renames: %d, UNDECLARED: %d"
          % (len(gone), len(declared), len(undeclared)))
    if "--list" in argv:
        for line, n in lost.items():
            print("    LOST x%d  %s" % (n, line[:110]))
        for g in undeclared:
            print("    UNDECLARED LABEL LOSS  %s" % g)
        for g in declared:
            print("    renamed  %s -> %s" % (g, RENAMES[g]))
        for line, n in updated.items():
            print("    rewritten x%d  %s" % (n, line[:110]))
    bad = sum(lost.values()) + len(undeclared)
    print("FAILURES: %d" % bad)
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
