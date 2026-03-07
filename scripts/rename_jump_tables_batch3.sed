# Batch 3: Rename tables in naka_e0e974, naka_ea13cc, and other includes

# naka_e0e974_e15b20.s - Large Naka presentation tables
s/LABEL_E13456\b/Naka_PresentationReg_Table1/g
s/LABEL_E1360A\b/Naka_PresentationReg_Table2/g
s/LABEL_E1363A\b/Naka_PresentationReg_Table3/g
s/LABEL_E1366E\b/Naka_PresentationReg_Table4/g
s/LABEL_E137D6\b/Naka_PresentationReg_Table5/g
s/LABEL_E13BCA\b/Naka_PresentationReg_Table6/g
s/LABEL_E141AA\b/Naka_PresentationReg_Table7/g
s/LABEL_E14206\b/Naka_PresentationReg_Table8/g
s/LABEL_E1425A\b/Naka_PresentationReg_Table9/g
s/LABEL_E142AE\b/Naka_PresentationReg_Table10/g

# naka_e0e974_e15b20.s - Multilingual feature help tables (6 entries = 6 languages)
s/LABEL_E148A0\b/Str_BassPortSpeaker_Help/g
s/LABEL_E148E0\b/Str_Feature1_Help/g
s/LABEL_E14AD2\b/Str_Feature2_Help/g
s/LABEL_E14B4A\b/Str_HugeStyles_Help/g
s/LABEL_E14CBA\b/Str_MusicStylist_Help/g
s/LABEL_E14E50\b/Str_SoftwareMusic_Help/g
s/LABEL_E14FD8\b/Str_StyleConvert_Help/g
s/LABEL_E151BC\b/Str_CustomRhythm_Help/g
s/LABEL_E15240\b/Str_AccordionRegister_Help/g
s/LABEL_E153E2\b/Str_AccordionRegisterDesc_Help/g
s/LABEL_E15452\b/Str_DigitalDrawbar_Help/g
s/LABEL_E155B4\b/Str_DigitalDrawbarDesc_Help/g
s/LABEL_E1562E\b/Str_AcousticIllusion_Help/g
s/LABEL_E15790\b/Str_AcousticIllusionDesc_Help/g
s/LABEL_E15900\b/Str_StyleImages_Help/g
s/LABEL_E15960\b/Str_HugeStyles2_Help/g
s/LABEL_E159C0\b/Str_HugeStyles3_Help/g

# naka_ea13cc_ea8c9e.s - Disk/Song management tables
s/LABEL_EA7228\b/Naka_IntSongMedley_Screens/g
s/LABEL_EA75D8\b/Naka_DiskLoadPage_Screens/g
s/LABEL_EA7878\b/Naka_DiskSmfSave_Screens/g
s/LABEL_EA7EA8\b/Naka_DiskUtility_Screens/g
s/LABEL_EA80B6\b/Naka_DiskOps_Table/g
s/LABEL_EA85C8\b/Naka_SongMedleyFunc_Screens/g
s/LABEL_EA8696\b/Str_PasswordEntry_Multilingual/g
s/LABEL_EA883A\b/Str_CopyProtected_Multilingual/g
s/LABEL_EA8A10\b/Str_SeqCopyProtected_Multilingual/g
s/LABEL_EA8C60\b/Str_Attention2_Multilingual/g

# Additional tables in naka_e55e38_e5a38e.s
s/LABEL_E5A2A8\b/Naka_MidiPart_Table1/g

# Additional tables in naka_e812e8_e818e6.s
s/LABEL_E81590\b/Naka_Event_Table2/g
s/LABEL_E813A6\b/Naka_Event_Table3/g

# Additional tables in naka_e81cce_e85f46.s
s/LABEL_E854C8\b/Naka_SoundDemo_Table/g
s/LABEL_E85630\b/Naka_SoundList_Table/g
s/LABEL_E85730\b/Naka_SoundGroup_Table/g
s/LABEL_E857B8\b/Naka_SoundPreset_Table/g
s/LABEL_E857F8\b/Naka_SoundEdit_Table/g
s/LABEL_E858B0\b/Naka_SoundMixer_Table/g
s/LABEL_E85948\b/Naka_SoundEffect_Table/g
s/LABEL_E859A8\b/Naka_SoundCtrl_Table/g
s/LABEL_E859F8\b/Naka_SoundConfig_Table/g
s/LABEL_E85470\b/Naka_SoundSelect_Table/g
s/LABEL_E85D18\b/Naka_SoundParam2_Table/g

# Additional tables in naka_eb2afe_eb71be.s
s/LABEL_EB33E0\b/Naka_RhythmDisplay_Table1/g
s/LABEL_EB3378\b/Naka_RhythmDisplay_Table2/g
s/LABEL_EB3470\b/Naka_RhythmGroup_Table/g
s/LABEL_EB36D0\b/Naka_RhythmEdit_Table/g

# Additional tables in naka_ed803c_eda02c.s
s/LABEL_ED803C\b/Naka_EditorMenu_Screens/g
s/LABEL_ED8370\b/Naka_EditorParam_Screens/g
s/LABEL_ED8400\b/Naka_EditorSetting_Screens/g
s/LABEL_ED8520\b/Naka_EditorConfig_Screens/g
s/LABEL_ED85DE\b/Naka_PresetBankName_Label/g
s/LABEL_ED9EA8\b/Naka_EditorValue_Screens/g
s/LABEL_ED9FD0\b/Naka_EditorEffect_Screens/g

# Additional tables in naka_eee718_eef588.s
s/LABEL_EEE718\b/Naka_DrawbarOrgan_Screens/g
s/LABEL_EEED44\b/Naka_DrawbarControl_Table/g
s/LABEL_EEF350\b/Naka_DrawbarDisplay_Table1/g
s/LABEL_EEF3D0\b/Naka_DrawbarDisplay_Table2/g
s/LABEL_EEF588\b/Naka_DrawbarReg_Table/g

# Additional tables in hama/hama_data.s and fd_test_data.s
s/LABEL_E1F240\b/Hama_ModeParam_Table/g
s/LABEL_E1FBD8\b/FDTest_DataBlock_Table/g
s/LABEL_E1FC46\b/FDTest_Config_Table/g

# toshi_data.s remaining tables
s/LABEL_EDAA64\b/SoundProgram_DispatchTable/g
s/LABEL_EDB370\b/Naka_ToshiParam_Table/g
s/LABEL_E5A1D8\b/Naka_MidiChannel_Table/g

# Additional toshi_data tables (note-related string tables)
s/LABEL_ED0F48\b/NoteNameStr_Table_4/g
s/LABEL_ED1D4A\b/NoteNameStr_Table_5/g
s/LABEL_ED2D98\b/NoteNameStr_Table_6/g
s/LABEL_ED2FDA\b/NoteNameStr_Table_7/g
s/LABEL_ED32E6\b/NoteNameStr_Table_8/g
