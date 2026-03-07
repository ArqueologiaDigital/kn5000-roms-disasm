# Batch 2: Rename jump tables in kn5000_v10_program.s

# Naka UI screen tables (Accompaniment/Composer section, E1B range)
s/LABEL_E1B80E\b/Naka_SeqToComposer_Screens/g
s/LABEL_E1B88E\b/Naka_SeqCopy_Screens/g
s/LABEL_E1B8A6\b/Naka_EasyComposer_Screens/g
s/LABEL_E1B8E2\b/Naka_EasyComposer2_Screens/g
s/LABEL_E1B8F6\b/Naka_ModeSelect_Screens/g
s/LABEL_E1B926\b/Naka_ExpandMode_Screens/g
s/LABEL_E1B9AE\b/Naka_Accomp7_Screens/g
s/LABEL_E1BA22\b/Naka_Accomp8_Screens/g
s/LABEL_E1BA62\b/Naka_Accomp9_Screens/g
s/LABEL_E1BA7E\b/Naka_Accomp10_Screens/g
s/LABEL_E1BA92\b/Naka_Accomp11_Screens/g
s/LABEL_E1BABA\b/Naka_Accomp12_Screens/g
s/LABEL_E1BADE\b/Naka_Accomp13_Screens/g
s/LABEL_E1BAFA\b/Naka_Accomp14_Screens/g

# Style Convert UI screens
s/LABEL_E1BB22\b/Naka_StylCnvWait_Screens/g
s/LABEL_E1BB80\b/Naka_StylCnvVer_Screens/g
s/LABEL_E1BBD2\b/Naka_StylCnvCnvtBox_Screens/g
s/LABEL_E1BC00\b/Naka_StylCnvStor_Screens/g
s/LABEL_E1BC2A\b/Naka_StylCnvTxt_Screens/g
s/LABEL_E1BC80\b/Naka_StylCnvSelBox_Screens/g
s/LABEL_E1BCC0\b/Naka_StylCnvCont_Screens/g

# Composer UI screens
s/LABEL_E1BD3A\b/Naka_CmpMenu_Screens/g
s/LABEL_E1BD98\b/Naka_CmpBookshelf_Screens/g
s/LABEL_E1BE58\b/Naka_CmpBookshelfSub_Screens/g
s/LABEL_E1BE9A\b/Naka_NamingMem_Screens/g
s/LABEL_E1BF7A\b/Naka_CmSetP1Grid_Screens/g
s/LABEL_E1C082\b/Naka_CmpMem_Screens/g

# Delay/Effect parameter screens
s/LABEL_E248D0\b/Naka_DigitalDelay_Screens/g
s/LABEL_E2493A\b/Naka_PDMedR1_Screens/g

# Rhythm/Style group tables (lists of styles per group)
s/LABEL_ECE2F0\b/StyleGroup_ModernDance_Table/g
s/LABEL_ECE980\b/StyleGroup_PopBallad_Table/g
s/LABEL_ECED38\b/StyleGroup_Swing_Table/g
s/LABEL_ECEF18\b/StyleGroup_FunkFusion_Table/g
s/LABEL_ECF228\b/StyleGroup_JazzCombo_Table/g
s/LABEL_ECF7E8\b/StyleGroup_WorldMusic_Table/g
s/LABEL_ECFCA8\b/StyleGroup_LatinDance_Table/g
s/LABEL_ECFEE0\b/Naka_MemoryC_Screens/g

# Multilingual message tables
s/LABEL_E9B280\b/Str_SongCapacityExceeded_Multilingual/g
s/LABEL_E9C528\b/Str_RKBLKBSpecialTracks_Multilingual/g
s/LABEL_E9CF18\b/Str_InitSettingWarning_Multilingual/g
s/LABEL_E9D846\b/Str_PleaseWait_Multilingual/g

# Scale/Tuning tables
s/LABEL_E9DA28\b/Naka_TechniChord1_Screens/g
s/LABEL_E9DBD6\b/Naka_Scale2_Screens/g
s/LABEL_E9DD16\b/Scale_Arabic2_NameTable/g
s/LABEL_E9DD76\b/Scale_Names_Table/g

# Sequencer/Sound parameter tables
s/LABEL_EA9E00\b/Naka_SoundEditor_Screens/g
s/LABEL_EAA40A\b/Naka_InternalVar_Screens/g
s/LABEL_EAA750\b/Naka_Debug3_Screens/g
s/LABEL_EAB2E8\b/Naka_SoundParam_Screens/g
s/LABEL_EAB3D0\b/Naka_LanguageCheck_Screens/g

# Large dispatch tables (EE range)
s/LABEL_EE0158\b/Naka_SubDispatch_A_Table/g
s/LABEL_EE0198\b/Naka_SubDispatch_B_Table/g
s/LABEL_EE0310\b/Naka_MainDispatch_Table/g

# EE7 region tables (likely display/rendering)
s/LABEL_EE7776\b/Naka_DisplayMode_Table/g
s/LABEL_EE7CA7\b/Naka_RenderMode_A_Table/g
s/LABEL_EE7D27\b/Naka_RenderMode_B_Table/g
s/LABEL_EE86D0\b/Naka_EventHandler_Table/g
