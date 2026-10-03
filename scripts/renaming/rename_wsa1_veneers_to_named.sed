# WSA1: sub_ routines whose whole body is a jump to, or a (register-saving) call of, a named routine;
# named <target>_Veneer / _SaveRegs / _Call (T_ prefix dropped; a number when the name is taken).
# Finder: research-scratch sessions/2026-10-03_53b889a2/wsa1_veneers.py.
s/\bsub_F44039\b/Nop_CallsEmptyDirectorySlot_Veneer/g
s/\bsub_F67450\b/MsgLine_PartVolume_Veneer/g
s/\bsub_F67454\b/MsgLine_PartEffect_Veneer/g
s/\bsub_F67458\b/MsgLine_NoteName_Veneer/g
s/\bsub_F67468\b/MsgLine_TotalReverb_Veneer/g
s/\bsub_F73840\b/Smf_WriteFile_Veneer/g
s/\bsub_F7A408\b/BStore_LatchHeapBase_Veneer/g
s/\bsub_F7AA00\b/BStore_AppendBytes_Join3_Veneer/g
s/\bsub_F7AA02\b/BStore_AppendBytes_Join4_Veneer/g
s/\bsub_FA5935\b/PanelLed_ToggleActivityLed_SaveRegs/g
s/\bsub_FAAB1B\b/Queue2C00_DrainPassB_SaveRegs2/g
s/\bsub_FAB911\b/List2030_PartBendRange_Apply_Call/g
s/\bsub_FB203C\b/SoundGroup_ReloadSelection_SaveRegs/g
s/\bsub_FB313C\b/ParamImage_QueueDiffAll_SaveRegs/g
s/\bsub_FB7AE4\b/Mode_SwitchToCombination_SaveRegs/g
s/\bsub_FB7AF1\b/Mode_SwitchToSound_SaveRegs/g
s/\bsub_FB7AFE\b/PanelLed_ToggleActivityLed_SaveRegs2/g
s/\bsub_FB7E9B\b/MessageScreen_Paint_SaveRegs/g
s/\bsub_FE0060\b/ParamImage_WriteRecordHeaders_Entry_SaveRegs/g
s/\bsub_FE0083\b/ParamImage_SanitizeAllAndHook_Entry_SaveRegs/g
s/\bsub_FE009D\b/ParamImage_QueueDiffAll_SaveRegs2/g
s/\bsub_FE00C4\b/Queue2C00_DrainPassB_SaveRegs3/g
s/\bsub_FE01FA\b/MessageScreen_Paint_SaveRegs2/g
s/\bsub_FE1BCA\b/SysPartMidi_ResetBlock1Default_Call/g
