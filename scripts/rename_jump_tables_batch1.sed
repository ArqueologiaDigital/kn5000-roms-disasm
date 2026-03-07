# Batch 1: Rename jump tables with semantic names based on analysis
# Tables in naka_e27fa4_e30932.s (Sequencer/Recording UI screens)
s/LABEL_E2E800\b/Naka_CyclePlay_Screens/g
s/LABEL_E2E868\b/Naka_CreateScreen_Items/g
s/LABEL_E2E8E8\b/Naka_RealtimeRecord_Controls/g
s/LABEL_E2E900\b/Naka_SeqControls_Widgets/g
s/LABEL_E2EB60\b/Naka_DrumEdit_Screens/g
s/LABEL_E2EC08\b/Naka_SongMode_Items/g
s/LABEL_E2EF90\b/Naka_EnterTrainer_Screens/g
s/LABEL_E2F898\b/Naka_NTBitmap_WidgetRefs/g
s/LABEL_E2F9A0\b/Naka_DRBitmap_WidgetRefs/g
s/LABEL_E2FA68\b/Naka_TrkClrSure_Display/g
s/LABEL_E3001A\b/Naka_SwitchControls_Table/g

# Tables in naka_e1ab58_e1b7d2.s (Accompaniment/Style UI screens)
s/LABEL_E1B4F2\b/Naka_Accomp1_Screens/g
s/LABEL_E1B516\b/Naka_Accomp2_Screens/g
s/LABEL_E1B536\b/Naka_Accomp3_Screens/g
s/LABEL_E1B54A\b/Naka_Accomp4_Screens/g
s/LABEL_E1B55E\b/Naka_Accomp5_Screens/g
s/LABEL_E1B582\b/Naka_Accomp6_Screens/g
s/LABEL_E1B67E\b/Naka_VariationNaming_Screens/g
s/LABEL_E1B76A\b/Naka_PartBalance_Screens/g
s/LABEL_E1B7D2\b/Naka_ComposerMenu_Screens/g

# Tables in naka_ed803c_eda02c.s (Control system / Song management)
s/LABEL_ED8238\b/Naka_ControlSys_StateTable/g
s/LABEL_ED8478\b/Naka_SongList_PageTable/g
s/LABEL_ED84B8\b/Naka_SongSlot_SelectTable/g
s/LABEL_ED84F0\b/Naka_PresetBank_SelectTable/g
s/LABEL_ED85B0\b/Naka_PresetBank_InfoTable/g
s/LABEL_ED9D68\b/SoundParam_EncoderHandlers/g
s/LABEL_ED9FA8\b/Encoder_ValueQuantizeTable/g
s/LABEL_EDA02C\b/EffectMode_DispatchTable/g

# Tables in naka_e81cce_e85f46.s (Sound demo / UI component)
s/LABEL_E85618\b/Naka_AudioDemo_ModeTable/g
s/LABEL_E85718\b/Naka_UIComponent_UpdateTable/g
s/LABEL_E859D8\b/Naka_SongDisplay_FormatTable/g
s/LABEL_E85CF0\b/Naka_SDMenu_TuneTable/g

# Tables in other naka files
s/LABEL_EB3448\b/Naka_RhythmStyle_DisplayTable/g
s/LABEL_E5A350\b/Naka_MIDI_PartEditorTable/g
s/LABEL_E812E8\b/Naka_EventDispatch_Table/g
s/LABEL_E14347\b/Naka_DrawbarSlider_Resources/g

# Tables in hama_data.s
s/LABEL_E1F032\b/Hama_ModeInit_Table/g
