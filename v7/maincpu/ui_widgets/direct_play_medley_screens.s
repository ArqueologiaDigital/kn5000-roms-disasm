
; Direct Play, Medley, Step Record, Track Assign & Demo screen widgets (216 widgets, 12250 bytes)
; Source: maincpu/ui_widgets/naka_direct_play.c (C struct with named fields)
NakaBoxData_PsSongSelBox:
	.incbin "includes/generated/naka_direct_play.bin", 0, 0x50
NakaWidget_SmfDpContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0x50, 0x24
NakaWidget_SmfDpVolume:
	.incbin "includes/generated/naka_direct_play.bin", 0x74, 0x3E
NakaWidget_SmfDpGroup:
	.incbin "includes/generated/naka_direct_play.bin", 0xB2, 0x1A
NakaWidget_SmfDpMuteRow0:
	.incbin "includes/generated/naka_direct_play.bin", 0xCC, 0x24
NakaWidget_SmfDpMuteRow1:
	.incbin "includes/generated/naka_direct_play.bin", 0xF0, 0x24
NakaWidget_SmfDpLyricsToggle:
	.incbin "includes/generated/naka_direct_play.bin", 0x114, 0x28
NakaWidget_SmfDpMuteToggle:
	.incbin "includes/generated/naka_direct_play.bin", 0x13C, 0x3C
NakaWidget_SmfDpMeasureBox:
	.incbin "includes/generated/naka_direct_play.bin", 0x178, 0x1A
NakaWidget_SmfDpFileSelector:
	.incbin "includes/generated/naka_direct_play.bin", 0x192, 0x1A
NakaWidget_SmfDpFileList:
	.incbin "includes/generated/naka_direct_play.bin", 0x1AC, 0x34
NakaWidget_SmfDpMixer:
	.incbin "includes/generated/naka_direct_play.bin", 0x1E0, 0x38
NakaWidget_SmfDpMic:
	.incbin "includes/generated/naka_direct_play.bin", 0x218, 0x36
NakaWidget_SmfDpMuteChLabel:
	.incbin "includes/generated/naka_direct_play.bin", 0x24E, 0x2A
NakaWidget_SmfDpMuteChPanel:
	.incbin "includes/generated/naka_direct_play.bin", 0x278, 0x38
NakaWidget_SmfMedleyItem:
	.incbin "includes/generated/naka_direct_play.bin", 0x2B0, 0x3C
NakaWidget_SmfMixerItem:
	.incbin "includes/generated/naka_direct_play.bin", 0x2EC, 0x3A
NakaWidget_SmfLyricsItem:
	.incbin "includes/generated/naka_direct_play.bin", 0x326, 0x3E
NakaWidget_SmfDpSubPanel:
	.incbin "includes/generated/naka_direct_play.bin", 0x364, 0x24
NakaWidget_SmfDpDisplayMode:
	.incbin "includes/generated/naka_direct_play.bin", 0x388, 0x2C
NakaWidget_SmfDpSkipLabel:
	.incbin "includes/generated/naka_direct_play.bin", 0x3B4, 0x26
NakaWidget_SmfDpLyricsToggle2:
	.incbin "includes/generated/naka_direct_play.bin", 0x3DA, 0x28
NakaWidget_SmfDpChLabel:
	.incbin "includes/generated/naka_direct_play.bin", 0x402, 0x24
NakaWidget_SmfDpMuteGroup:
	.incbin "includes/generated/naka_direct_play.bin", 0x426, 0x1A
NakaWidget_SmfDpMuteSel1:
	.incbin "includes/generated/naka_direct_play.bin", 0x440, 0x24
NakaWidget_SmfDpMuteSel2:
	.incbin "includes/generated/naka_direct_play.bin", 0x464, 0x2E
NakaWidget_SmfDpMuteCtrl1:
	.incbin "includes/generated/naka_direct_play.bin", 0x492, 0x1A
NakaWidget_SmfDpMuteSel3:
	.incbin "includes/generated/naka_direct_play.bin", 0x4AC, 0x2E
NakaWidget_SmfDpMuteCtrl2:
	.incbin "includes/generated/naka_direct_play.bin", 0x4DA, 0x1A
NakaWidget_SmfDpMuteSel4:
	.incbin "includes/generated/naka_direct_play.bin", 0x4F4, 0x2E
NakaWidget_SmfDpMuteCtrl3:
	.incbin "includes/generated/naka_direct_play.bin", 0x522, 0x1A
NakaWidget_SmfDpMuteSel5:
	.incbin "includes/generated/naka_direct_play.bin", 0x53C, 0x2E
NakaWidget_SmfDpMuteCtrl4:
	.incbin "includes/generated/naka_direct_play.bin", 0x56A, 0x1A
NakaWidget_SmfDpMuteSel6:
	.incbin "includes/generated/naka_direct_play.bin", 0x584, 0x2E
NakaWidget_SmfDpMuteCtrl5:
	.incbin "includes/generated/naka_direct_play.bin", 0x5B2, 0x1A
NakaWidget_SmfDpMeasure:
	.incbin "includes/generated/naka_direct_play.bin", 0x5CC, 0x1A
NakaWidget_SmfDpRT1Selector:
	.incbin "includes/generated/naka_direct_play.bin", 0x5E6, 0x2C
NakaWidget_SmfDpRT2Selector:
	.incbin "includes/generated/naka_direct_play.bin", 0x612, 0x2C
NakaWidget_SmfDpOrchSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x63E, 0x24
NakaWidget_SmfDpRT1Display:
	.incbin "includes/generated/naka_direct_play.bin", 0x662, 0x28
NakaWidget_SmfDpMuteSwRow0:
	.incbin "includes/generated/naka_direct_play.bin", 0x68A, 0x1C
NakaWidget_SmfDpMuteSwRow1:
	.incbin "includes/generated/naka_direct_play.bin", 0x6A6, 0x26
NakaWidget_SmfDpMuteSwRow2:
	.incbin "includes/generated/naka_direct_play.bin", 0x6CC, 0x62
NakaWidget_DocDpContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0x72E, 0x24
NakaWidget_DocDpVolume:
	.incbin "includes/generated/naka_direct_play.bin", 0x752, 0x1A
NakaWidget_DocDpGroup:
	.incbin "includes/generated/naka_direct_play.bin", 0x76C, 0x24
NakaWidget_DocDpMuteRow0:
	.incbin "includes/generated/naka_direct_play.bin", 0x790, 0x24
NakaWidget_DocDpMeasure:
	.incbin "includes/generated/naka_direct_play.bin", 0x7B4, 0x1A
NakaWidget_DocDpFileSelector:
	.incbin "includes/generated/naka_direct_play.bin", 0x7CE, 0x1A
NakaWidget_DocDpFileList:
	.incbin "includes/generated/naka_direct_play.bin", 0x7E8, 0x34
NakaWidget_DocDpRT2Selector:
	.incbin "includes/generated/naka_direct_play.bin", 0x81C, 0x34
NakaWidget_DocDpOrchSelector:
	.incbin "includes/generated/naka_direct_play.bin", 0x850, 0x38
NakaWidget_DocDpMixer:
	.incbin "includes/generated/naka_direct_play.bin", 0x888, 0x38
NakaWidget_DocDpMic:
	.incbin "includes/generated/naka_direct_play.bin", 0x8C0, 0x36
NakaWidget_PdDpContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0x8F6, 0x46
NakaWidget_PdDpVolume:
	.incbin "includes/generated/naka_direct_play.bin", 0x93C, 0x24
NakaWidget_PdDpGroup:
	.incbin "includes/generated/naka_direct_play.bin", 0x960, 0x1A
NakaWidget_PdDpMuteRow0:
	.incbin "includes/generated/naka_direct_play.bin", 0x97A, 0x24
NakaWidget_PdDpMuteRow1:
	.incbin "includes/generated/naka_direct_play.bin", 0x99E, 0x24
NakaWidget_PdDpMeasure:
	.incbin "includes/generated/naka_direct_play.bin", 0x9C2, 0x1A
NakaWidget_PdDpFileSelector:
	.incbin "includes/generated/naka_direct_play.bin", 0x9DC, 0x1A
NakaWidget_PdDpFileList:
	.incbin "includes/generated/naka_direct_play.bin", 0x9F6, 0x34
NakaWidget_PdDpOrchSelector:
	.incbin "includes/generated/naka_direct_play.bin", 0xA2A, 0x2C
Str_ORCH:
	.incbin "includes/generated/naka_direct_play.bin", 0xA56, 0xC
NakaWidget_PdDpMixer:
	.incbin "includes/generated/naka_direct_play.bin", 0xA62, 0x38
NakaWidget_PdDpMic:
	.incbin "includes/generated/naka_direct_play.bin", 0xA9A, 0x36
NakaWidget_SmfMdlyContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0xAD0, 0x3C
NakaWidget_SmfMdlyVolume:
	.incbin "includes/generated/naka_direct_play.bin", 0xB0C, 0x24
NakaWidget_SmfMdlyMeasure:
	.incbin "includes/generated/naka_direct_play.bin", 0xB30, 0x1A
NakaWidget_SmfMdlyFileSelector:
	.incbin "includes/generated/naka_direct_play.bin", 0xB4A, 0x1A
NakaWidget_SmfMdlyMicWidget:
	.incbin "includes/generated/naka_direct_play.bin", 0xB64, 0x36
NakaWidget_SmfMdlyOrchSel:
	.incbin "includes/generated/naka_direct_play.bin", 0xB9A, 0x1A
NakaWidget_SmfMdlyOrchRow:
	.incbin "includes/generated/naka_direct_play.bin", 0xBB4, 0x16
NakaWidget_SmfMdlyContainer2:
	.incbin "includes/generated/naka_direct_play.bin", 0xBCA, 0x36
NakaWidget_SmfMdlyLyricsItem:
	.incbin "includes/generated/naka_direct_play.bin", 0xC00, 0x3E
NakaWidget_SmfMdlySubPanel:
	.incbin "includes/generated/naka_direct_play.bin", 0xC3E, 0x24
NakaWidget_SmfMdlyLyricsToggle:
	.incbin "includes/generated/naka_direct_play.bin", 0xC62, 0x28
NakaWidget_SmfMdlyGroup:
	.incbin "includes/generated/naka_direct_play.bin", 0xC8A, 0x1A
NakaWidget_SmfMdlyMuteRow0:
	.incbin "includes/generated/naka_direct_play.bin", 0xCA4, 0x24
NakaWidget_SmfMdlyMuteRow1:
	.incbin "includes/generated/naka_direct_play.bin", 0xCC8, 0x24
NakaWidget_SmfMdlyMuteToggle:
	.incbin "includes/generated/naka_direct_play.bin", 0xCEC, 0x2E
NakaWidget_SmfMdlySkipLabel:
	.incbin "includes/generated/naka_direct_play.bin", 0xD1A, 0x26
NakaWidget_SmfMdlyMutePanel:
	.incbin "includes/generated/naka_direct_play.bin", 0xD40, 0x3C
NakaWidget_SmfMdlyMeasureBox:
	.incbin "includes/generated/naka_direct_play.bin", 0xD7C, 0x1A
NakaWidget_SmfMdlyOffOnSel:
	.incbin "includes/generated/naka_direct_play.bin", 0xD96, 0x16
NakaWidget_SmfMdlyOffOnList:
	.incbin "includes/generated/naka_direct_play.bin", 0xDAC, 0x34
NakaWidget_SmfMdlyMixerWidget:
	.incbin "includes/generated/naka_direct_play.bin", 0xDE0, 0x38
NakaWidget_SmfMdlyMicWidget2:
	.incbin "includes/generated/naka_direct_play.bin", 0xE18, 0x36
NakaWidget_SmfMdlyMuteChLabel:
	.incbin "includes/generated/naka_direct_play.bin", 0xE4E, 0x60
NakaWidget_SmfMdlyRootContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0xEAE, 0x36
NakaWidget_DocMdlyContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0xEE4, 0x1A
NakaWidget_DocMdlyGroup:
	.incbin "includes/generated/naka_direct_play.bin", 0xEFE, 0x24
NakaWidget_DocMdlyMuteRow0:
	.incbin "includes/generated/naka_direct_play.bin", 0xF22, 0x24
NakaWidget_DocMdlySubPanel:
	.incbin "includes/generated/naka_direct_play.bin", 0xF46, 0x24
NakaWidget_DocMdlyMuteToggle:
	.incbin "includes/generated/naka_direct_play.bin", 0xF6A, 0x2E
NakaWidget_DocMdlySkipLabel:
	.incbin "includes/generated/naka_direct_play.bin", 0xF98, 0x26
NakaWidget_DocMdlyMeasureBox:
	.incbin "includes/generated/naka_direct_play.bin", 0xFBE, 0x1A
NakaWidget_DocMdlyOffOnSel:
	.incbin "includes/generated/naka_direct_play.bin", 0xFD8, 0x16
NakaWidget_DocMdlyOffOnList:
	.incbin "includes/generated/naka_direct_play.bin", 0xFEE, 0x34
NakaWidget_DocMdlyRT2Sel:
	.incbin "includes/generated/naka_direct_play.bin", 0x1022, 0x34
NakaWidget_DocMdlyOrchSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x1056, 0x38
NakaWidget_DocMdlyMixer:
	.incbin "includes/generated/naka_direct_play.bin", 0x108E, 0x38
NakaWidget_DocMdlyMic:
	.incbin "includes/generated/naka_direct_play.bin", 0x10C6, 0x76
NakaWidget_PdMdlyContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0x113C, 0x24
NakaWidget_PdMdlyGroup:
	.incbin "includes/generated/naka_direct_play.bin", 0x1160, 0x1A
NakaWidget_PdMdlyMuteRow0:
	.incbin "includes/generated/naka_direct_play.bin", 0x117A, 0x24
NakaWidget_PdMdlyMuteRow1:
	.incbin "includes/generated/naka_direct_play.bin", 0x119E, 0x24
NakaWidget_PdMdlyMuteToggle:
	.incbin "includes/generated/naka_direct_play.bin", 0x11C2, 0x2E
NakaWidget_PdMdlySkipLabel:
	.incbin "includes/generated/naka_direct_play.bin", 0x11F0, 0x26
NakaWidget_PdMdlyMeasureBox:
	.incbin "includes/generated/naka_direct_play.bin", 0x1216, 0x1A
NakaWidget_PdMdlyOffOnSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x1230, 0x16
NakaWidget_PdMdlyOffOnList:
	.incbin "includes/generated/naka_direct_play.bin", 0x1246, 0x34
NakaWidget_PdMdlyRT2Sel:
	.incbin "includes/generated/naka_direct_play.bin", 0x127A, 0x2C
NakaStr_PdMdlyOrcha:
	.incbin "includes/generated/naka_direct_play.bin", 0x12A6, 0xC
NakaWidget_PdMdlyMixer:
	.incbin "includes/generated/naka_direct_play.bin", 0x12B2, 0x38
NakaWidget_PdMdlyMic:
	.incbin "includes/generated/naka_direct_play.bin", 0x12EA, 0x6C
NakaWidget_SmfMdly2Container:
	.incbin "includes/generated/naka_direct_play.bin", 0x1356, 0x24
NakaWidget_SmfMdly2MuteToggle:
	.incbin "includes/generated/naka_direct_play.bin", 0x137A, 0x2E
NakaWidget_SmfMdly2SkipLabel:
	.incbin "includes/generated/naka_direct_play.bin", 0x13A8, 0x26
NakaWidget_SmfMdly2MeasureBox:
	.incbin "includes/generated/naka_direct_play.bin", 0x13CE, 0x1A
NakaWidget_SmfMdly2OffOnSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x13E8, 0x16
NakaWidget_SmfMdly2MicWidget:
	.incbin "includes/generated/naka_direct_play.bin", 0x13FE, 0x36
NakaWidget_SmfMdly2OrchSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x1434, 0x1A
NakaWidget_SongMdlyContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0x144E, 0x3E
NakaWidget_SongMdlyGroup:
	.incbin "includes/generated/naka_direct_play.bin", 0x148C, 0x1A
NakaWidget_SongMdlyVolume:
	.incbin "includes/generated/naka_direct_play.bin", 0x14A6, 0x24
NakaWidget_SongMdlySongSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x14CA, 0x24
NakaWidget_SongMdlySongList:
	.incbin "includes/generated/naka_direct_play.bin", 0x14EE, 0x1E
NakaWidget_SongMdlyRT1Sel:
	.incbin "includes/generated/naka_direct_play.bin", 0x150C, 0x2E
NakaWidget_SongMdlyMeasureBox:
	.incbin "includes/generated/naka_direct_play.bin", 0x153A, 0x1A
NakaWidget_SongMdlyFileList:
	.incbin "includes/generated/naka_direct_play.bin", 0x1554, 0x24
NakaWidget_SongMdlyMutePanel:
	.incbin "includes/generated/naka_direct_play.bin", 0x1578, 0x16
NakaWidget_SongMdlyMuteList:
	.incbin "includes/generated/naka_direct_play.bin", 0x158E, 0x24
NakaWidget_SongMdlySkipLabel:
	.incbin "includes/generated/naka_direct_play.bin", 0x15B2, 0x26
NakaWidget_SongMdlyOffOnSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x15D8, 0x16
NakaWidget_SongMdlyMixer:
	.incbin "includes/generated/naka_direct_play.bin", 0x15EE, 0x38
NakaWidget_SongMdlyOrchSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x1626, 0x24
NakaWidget_SongMdlySongSel1:
	.incbin "includes/generated/naka_direct_play.bin", 0x164A, 0x24
NakaWidget_SongMdlySongSel2:
	.incbin "includes/generated/naka_direct_play.bin", 0x166E, 0x24
NakaWidget_SongMdlySongSel3:
	.incbin "includes/generated/naka_direct_play.bin", 0x1692, 0x24
NakaWidget_SongMdlySongSel4:
	.incbin "includes/generated/naka_direct_play.bin", 0x16B6, 0x24
NakaWidget_SongMdlySongSel5:
	.incbin "includes/generated/naka_direct_play.bin", 0x16DA, 0x24
NakaWidget_SongMdlySongSel6:
	.incbin "includes/generated/naka_direct_play.bin", 0x16FE, 0x24
NakaWidget_SongMdlySongSel7:
	.incbin "includes/generated/naka_direct_play.bin", 0x1722, 0x24
NakaWidget_SongMdlySongSel8:
	.incbin "includes/generated/naka_direct_play.bin", 0x1746, 0x24
NakaWidget_SongMdlySongSel9:
	.incbin "includes/generated/naka_direct_play.bin", 0x176A, 0x24
NakaWidget_SongMdlySongSel10:
	.incbin "includes/generated/naka_direct_play.bin", 0x178E, 0x24
NakaWidget_SongMdlySongSel11:
	.incbin "includes/generated/naka_direct_play.bin", 0x17B2, 0x24
NakaWidget_SongMdlySongSel12:
	.incbin "includes/generated/naka_direct_play.bin", 0x17D6, 0x24
NakaWidget_SongMdlySongSel13:
	.incbin "includes/generated/naka_direct_play.bin", 0x17FA, 0x24
NakaWidget_SongMdlySongSel14:
	.incbin "includes/generated/naka_direct_play.bin", 0x181E, 0x24
NakaWidget_SongMdlySongSel15:
	.incbin "includes/generated/naka_direct_play.bin", 0x1842, 0x24
NakaWidget_SongMdlySongSel16:
	.incbin "includes/generated/naka_direct_play.bin", 0x1866, 0x5A
NakaWidget_SongMdly2Group:
	.incbin "includes/generated/naka_direct_play.bin", 0x18C0, 0x1A
NakaWidget_SongMdly2Volume:
	.incbin "includes/generated/naka_direct_play.bin", 0x18DA, 0x24
NakaWidget_SongMdly2SongList:
	.incbin "includes/generated/naka_direct_play.bin", 0x18FE, 0x1E
NakaWidget_SongMdly2SongSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x191C, 0x24
NakaWidget_SongMdly2RT1Sel:
	.incbin "includes/generated/naka_direct_play.bin", 0x1940, 0x2E
NakaWidget_SongMdly2SkipLabel:
	.incbin "includes/generated/naka_direct_play.bin", 0x196E, 0x26
NakaWidget_SongMdly2MeasureBox:
	.incbin "includes/generated/naka_direct_play.bin", 0x1994, 0x1A
NakaWidget_SongMdly2FileList:
	.incbin "includes/generated/naka_direct_play.bin", 0x19AE, 0x24
NakaWidget_SongMdly2MutePanel:
	.incbin "includes/generated/naka_direct_play.bin", 0x19D2, 0x16
NakaWidget_SongMdly2OffOnSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x19E8, 0x16
NakaWidget_SongMdly2Mixer:
	.incbin "includes/generated/naka_direct_play.bin", 0x19FE, 0x38
NakaWidget_StepRecContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0x1A36, 0x3E
NakaWidget_StepRecPartLabel:
	.incbin "includes/generated/naka_direct_play.bin", 0x1A74, 0x2E
NakaWidget_StepRecPartPanel:
	.incbin "includes/generated/naka_direct_play.bin", 0x1AA2, 0x16
NakaWidget_StepRecPartList:
	.incbin "includes/generated/naka_direct_play.bin", 0x1AB8, 0x2A
NakaWidget_StepRecOrchRow:
	.incbin "includes/generated/naka_direct_play.bin", 0x1AE2, 0x16
NakaWidget_StepRecSubPanel:
	.incbin "includes/generated/naka_direct_play.bin", 0x1AF8, 0x22
NakaWidget_TrAsContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0x1B1A, 0x3A
NakaWidget_TrAsPresetItem:
	.incbin "includes/generated/naka_direct_play.bin", 0x1B54, 0x3E
NakaWidget_TrAsFileList:
	.incbin "includes/generated/naka_direct_play.bin", 0x1B92, 0x26
NakaWidget_TrAsGridDisplay:
	.incbin "includes/generated/naka_direct_play.bin", 0x1BB8, 0x86
NakaWidget_TrAsTrackAssign:
	.incbin "includes/generated/naka_direct_play.bin", 0x1C3E, 0x38
NakaWidget_TrAsLocalCont:
	.incbin "includes/generated/naka_direct_play.bin", 0x1C76, 0x36
NakaWidget_TrAsMidiOut:
	.incbin "includes/generated/naka_direct_play.bin", 0x1CAC, 0x34
NakaWidget_TrAsMatrix:
	.incbin "includes/generated/naka_direct_play.bin", 0x1CE0, 0x2A
NakaWidget_TrAsRT1Toggle:
	.incbin "includes/generated/naka_direct_play.bin", 0x1D0A, 0x28
NakaWidget_TrAsRT2Toggle:
	.incbin "includes/generated/naka_direct_play.bin", 0x1D32, 0x28
NakaWidget_TrAsMeasureBox:
	.incbin "includes/generated/naka_direct_play.bin", 0x1D5A, 0x1A
NakaWidget_TrAsSubContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0x1D74, 0x38
NakaWidget_TrAsGroup:
	.incbin "includes/generated/naka_direct_play.bin", 0x1DAC, 0x1A
NakaWidget_TrAsPartList0:
	.incbin "includes/generated/naka_direct_play.bin", 0x1DC6, 0x2A
NakaWidget_TrAsPartList1:
	.incbin "includes/generated/naka_direct_play.bin", 0x1DF0, 0x2A
NakaWidget_TrAsPartList2:
	.incbin "includes/generated/naka_direct_play.bin", 0x1E1A, 0x2A
NakaWidget_TrAsMeasureBox2:
	.incbin "includes/generated/naka_direct_play.bin", 0x1E44, 0x1A
NakaWidget_TrAsRT1Selector:
	.incbin "includes/generated/naka_direct_play.bin", 0x1E5E, 0x2E
NakaWidget_TrAsRT2Selector:
	.incbin "includes/generated/naka_direct_play.bin", 0x1E8C, 0x2E
NakaWidget_TrAsPresetSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x1EBA, 0x58
NakaWidget_TrAsPresetSong:
	.incbin "includes/generated/naka_direct_play.bin", 0x1F12, 0x26
NakaWidget_TrAsPresetMatrix:
	.incbin "includes/generated/naka_direct_play.bin", 0x1F38, 0x2A
NakaWidget_TrAsPresetPanel:
	.incbin "includes/generated/naka_direct_play.bin", 0x1F62, 0x44
NakaWidget_TrAsPresetInit:
	.incbin "includes/generated/naka_direct_play.bin", 0x1FA6, 0x3C
NakaWidget_TrAsPresetGmRec:
	.incbin "includes/generated/naka_direct_play.bin", 0x1FE2, 0x4E
NakaWidget_TrAsPresetMeasure:
	.incbin "includes/generated/naka_direct_play.bin", 0x2030, 0x48
NakaWidget_TrAsPresetRT2Sel:
	.incbin "includes/generated/naka_direct_play.bin", 0x2078, 0x1A
NakaWidget_TrAsPresetList:
	.incbin "includes/generated/naka_direct_play.bin", 0x2092, 0x2E
NakaWidget_TrAsPresetGroup:
	.incbin "includes/generated/naka_direct_play.bin", 0x20C0, 0x2A
NakaWidget_TrAsPresetContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0x20EA, 0x3E
NakaWidget_TrAsPresetMeasure2:
	.incbin "includes/generated/naka_direct_play.bin", 0x2128, 0x1A
NakaWidget_TrAsPresetRT1Sel:
	.incbin "includes/generated/naka_direct_play.bin", 0x2142, 0x2E
NakaWidget_TrAsPresetRT2Sel2:
	.incbin "includes/generated/naka_direct_play.bin", 0x2170, 0x2E
NakaWidget_TrAsPresetGroup2:
	.incbin "includes/generated/naka_direct_play.bin", 0x219E, 0x1A
NakaWidget_TrAsPresetTypeSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x21B8, 0x1A
NakaWidget_TrAsPresetList2:
	.incbin "includes/generated/naka_direct_play.bin", 0x21D2, 0x2A
NakaWidget_TrAsPresetList3:
	.incbin "includes/generated/naka_direct_play.bin", 0x21FC, 0x2A
NakaWidget_TrAsPresetList4:
	.incbin "includes/generated/naka_direct_play.bin", 0x2226, 0x2A
NakaWidget_TrAsPresetContainer2:
	.incbin "includes/generated/naka_direct_play.bin", 0x2250, 0x3E
NakaWidget_TrAsPresetGroup3:
	.incbin "includes/generated/naka_direct_play.bin", 0x228E, 0x1A
NakaWidget_TrAsPresetTypeSel2:
	.incbin "includes/generated/naka_direct_play.bin", 0x22A8, 0x1A
NakaWidget_TrAsPresetList5:
	.incbin "includes/generated/naka_direct_play.bin", 0x22C2, 0x2A
NakaWidget_TrAsPresetList6:
	.incbin "includes/generated/naka_direct_play.bin", 0x22EC, 0x2A
NakaWidget_TrAsPresetList7:
	.incbin "includes/generated/naka_direct_play.bin", 0x2316, 0x2A
NakaWidget_TrAsPresetMeasure3:
	.incbin "includes/generated/naka_direct_play.bin", 0x2340, 0x1A
NakaWidget_TrAsPresetRT1Sel2:
	.incbin "includes/generated/naka_direct_play.bin", 0x235A, 0x2E
NakaWidget_TrAsPresetRT2Sel3:
	.incbin "includes/generated/naka_direct_play.bin", 0x2388, 0x2E
NakaWidget_SongSelNamContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0x23B6, 0x3E
NakaWidget_SongSelNamNameItem:
	.incbin "includes/generated/naka_direct_play.bin", 0x23F4, 0x3E
NakaWidget_SongSelNamSongSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x2432, 0x32
NakaWidget_SongSelNamNameEdit:
	.incbin "includes/generated/naka_direct_play.bin", 0x2464, 0x32
NakaWidget_SongSelNamDuration:
	.incbin "includes/generated/naka_direct_play.bin", 0x2496, 0x2A
NakaWidget_NamingContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0x24C0, 0x32
NakaWidget_NamingCharSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x24F2, 0x24
NakaWidget_NamingSeqLabel:
	.incbin "includes/generated/naka_direct_play.bin", 0x2516, 0x32
NakaWidget_NamingMeasureBox:
	.incbin "includes/generated/naka_direct_play.bin", 0x2548, 0x1A
NakaWidget_NamingDisplayMode:
	.incbin "includes/generated/naka_direct_play.bin", 0x2562, 0x2C
NakaWidget_NamingOrchRow:
	.incbin "includes/generated/naka_direct_play.bin", 0x258E, 0x40
Str_AFTER_TOUCH_SETTING:
	.incbin "includes/generated/naka_direct_play.bin", 0x25CE, 0x14
NakaWidget_AftTouchDuration:
	.incbin "includes/generated/naka_direct_play.bin", 0x25E2, 0x2A
NakaWidget_AftTouchChSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x260C, 0x52
NakaWidget_AftTouchList:
	.incbin "includes/generated/naka_direct_play.bin", 0x265E, 0x62
NakaWidget_PartBal0:
	.incbin "includes/generated/naka_direct_play.bin", 0x26C0, 0x20
NakaWidget_PartBal1:
	.incbin "includes/generated/naka_direct_play.bin", 0x26E0, 0x20
NakaWidget_PartBal2:
	.incbin "includes/generated/naka_direct_play.bin", 0x2700, 0x20
NakaWidget_PartBal3:
	.incbin "includes/generated/naka_direct_play.bin", 0x2720, 0x20
NakaWidget_PartBal4:
	.incbin "includes/generated/naka_direct_play.bin", 0x2740, 0x20
NakaWidget_DemoContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0x2760, 0x38
NakaWidget_DemoPerfItem:
	.incbin "includes/generated/naka_direct_play.bin", 0x2798, 0x44
NakaWidget_DemoFeatPresItem:
	.incbin "includes/generated/naka_direct_play.bin", 0x27DC, 0x4C
NakaWidget_DemoMeasureBox:
	.incbin "includes/generated/naka_direct_play.bin", 0x2828, 0x52
NakaWidget_PerfMainMedley:
	.incbin "includes/generated/naka_direct_play.bin", 0x287A, 0x42
NakaWidget_PerfAccordionMedley:
	.incbin "includes/generated/naka_direct_play.bin", 0x28BC, 0x48
NakaWidget_PerfFolkMedley:
	.incbin "includes/generated/naka_direct_play.bin", 0x2904, 0x42
NakaWidget_PerfClassical:
	.incbin "includes/generated/naka_direct_play.bin", 0x2946, 0x40
NakaWidget_PerfShow:
	.incbin "includes/generated/naka_direct_play.bin", 0x2986, 0x3C
NakaWidget_PerfContemporary:
	.incbin "includes/generated/naka_direct_play.bin", 0x29C2, 0x44
NakaWidget_PerfStyleSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x2A06, 0x36
NakaWidget_PerfSoundSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x2A3C, 0x36
NakaWidget_PerfRhythmSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x2A72, 0x3A
NakaWidget_PerfMeasureBox:
	.incbin "includes/generated/naka_direct_play.bin", 0x2AAC, 0x1A
NakaWidget_PerfFileList:
	.incbin "includes/generated/naka_direct_play.bin", 0x2AC6, 0x24
NakaWidget_Perf2Container:
	.incbin "includes/generated/naka_direct_play.bin", 0x2AEA, 0x38
NakaWidget_Perf2Strings:
	.incbin "includes/generated/naka_direct_play.bin", 0x2B22, 0x3E
NakaWidget_Perf2Gamelan:
	.incbin "includes/generated/naka_direct_play.bin", 0x2B60, 0x36
NakaStr_Gamelan:
	.incbin "includes/generated/naka_direct_play.bin", 0x2B96, 0x46
NakaWidget_Perf2Guitar:
	.incbin "includes/generated/naka_direct_play.bin", 0x2BDC, 0x3C
NakaWidget_Perf2SaxBrass:
	.incbin "includes/generated/naka_direct_play.bin", 0x2C18, 0x36
Str_SaxBrass:
	.incbin "includes/generated/naka_direct_play.bin", 0x2C4E, 0x40
NakaStr_Organ:
	.incbin "includes/generated/naka_direct_play.bin", 0x2C8E, 0x6
NakaWidget_Perf2StyleSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x2C94, 0x36
NakaWidget_Perf2SoundSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x2CCA, 0x36
NakaWidget_Perf2RhythmSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x2D00, 0x3A
NakaWidget_Perf2MeasureBox:
	.incbin "includes/generated/naka_direct_play.bin", 0x2D3A, 0x1A
NakaWidget_Perf2FileList:
	.incbin "includes/generated/naka_direct_play.bin", 0x2D54, 0x5C
NakaWidget_Perf3HokieDance:
	.incbin "includes/generated/naka_direct_play.bin", 0x2DB0, 0x36
Str_HokieDance:
	.incbin "includes/generated/naka_direct_play.bin", 0x2DE6, 0x42
Str_GospelRevival:
	.incbin "includes/generated/naka_direct_play.bin", 0x2E28, 0x46
Str_OrganCombo:
	.incbin "includes/generated/naka_direct_play.bin", 0x2E6E, 0x42
Str_BigBandMid:
	.incbin "includes/generated/naka_direct_play.bin", 0x2EB0, 0x54
NakaWidget_Perf3ModernBluegrass:
	.incbin "includes/generated/naka_direct_play.bin", 0x2F04, 0x48
NakaWidget_Perf3StyleSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x2F4C, 0x36
NakaWidget_Perf3SoundSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x2F82, 0x36
NakaWidget_Perf3RhythmSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x2FB8, 0x22
; External label offsets within the binary blob above.
