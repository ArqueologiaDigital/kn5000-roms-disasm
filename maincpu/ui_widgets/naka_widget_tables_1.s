; =============================================================================
; NAKA Widget Pointer Tables - Part 1 (1.9K lines)
; =============================================================================
;
; Widget pointer tables for SmfDp, DocDp, PdDp, KssDp, DrumDp
; screen groups. NAKA type headers and NakaInst/NakaDesc references.
; =============================================================================

	xor	(xwa), xiz
	.byte 0x03, 0x00, 0x06, 0x00, 0x07, 0x00
	aligned_string "RHYTHM"
	aligned_string "RHYTHM"
NakaHdr_Perf2MeasureBoxData:


	naka_header NAKA_TYPE_0x29
	.byte 0x00, 0x00, 0xff, 0xff, 0x0b, 0x00
	.byte 0x09, 0x00, 0x18, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x1f, 0x00, 0x1f, 0x00, 0x1b, 0x00, 0x47, 0x01
NakaHdr_Perf2FileListData:
	.byte 0x14, 0x00, 0x67, 0x01, 0x00, 0x00, 0xff, 0xff
	.byte 0xff, 0xff, 0x0a, 0x00, 0x08, 0x00, 0x64, 0x00
	.byte 0x28, 0x00, 0xd5, 0x00, 0x3a, 0x00, 0xf5, 0x00
	.byte 0x00, 0x00, 0xff, 0xff, 0x04, 0x00, 0x00, 0x00
	.byte 0xff, 0x00, 0x00, 0x00, 0x90, 0x10, 0xe2, 0x00
NakaWidgetPtrTbl_SmfDp:
	.long NakaWidget_SmfDpContainer
	.long NakaWidget_SmfDpVolume
	.long NakaWidget_SmfDpGroup
	.long NakaWidget_SmfDpMuteRow0
	.long NakaWidget_SmfDpMuteRow1
	.long NakaWidget_SmfDpLyricsToggle
	.long NakaWidget_SmfDpMuteToggle
	.long NakaWidget_SmfDpMeasureBox
	.long NakaWidget_SmfDpFileSelector
	.long NakaWidget_SmfDpFileList
	.long NakaWidget_SmfDpMixer
	.long NakaWidget_SmfDpMic
	.long NakaWidget_SmfDpMuteChLabel
	.long NakaWidget_SmfDpMuteChPanel
	.long NakaWidget_SmfMedleyItem
	.long NakaWidget_SmfMixerItem
	.long NakaWidget_SmfLyricsItem
	.long NakaWidget_SmfDpSubPanel
	.long NakaWidget_SmfDpDisplayMode
	.long NakaWidget_SmfDpSkipLabel
	.long NakaWidget_SmfDpLyricsToggle2
	.long NakaWidget_SmfDpChLabel
	.long NakaWidget_SmfDpMuteGroup
	.long NakaWidget_SmfDpMuteSel1
	.long NakaWidget_SmfDpMuteSel2
	.long NakaWidget_SmfDpMuteCtrl1
	.long NakaWidget_SmfDpMuteSel3
	.long NakaWidget_SmfDpMuteCtrl2
	.long NakaWidget_SmfDpMuteSel4
	.long NakaWidget_SmfDpMuteCtrl3
	.long NakaWidget_SmfDpMuteSel5
	.long NakaWidget_SmfDpMuteCtrl4
	.long NakaWidget_SmfDpMuteSel6
	.long NakaWidget_SmfDpMuteCtrl5
	.long NakaWidget_SmfDpMeasure
	.long NakaWidget_SmfDpRT1Selector
	.long NakaWidget_SmfDpRT2Selector
	.long NakaWidget_SmfDpOrchSel
	.long NakaWidget_SmfDpRT1Display
	.long NakaWidget_SmfDpMuteSwRow0
	.long NakaWidget_SmfDpMuteSwRow1
	.long NakaWidget_SmfDpMuteSwRow2
	.byte 0x00, 0x00, 0x00, 0x00, 0x6e, 0x17, 0xe2, 0x00
NakaWidgetPtrTbl_DocDp:
	.long NakaWidget_DocDpContainer
	.long NakaWidget_DocDpVolume
	.long NakaWidget_DocDpGroup
	.long NakaWidget_DocDpMuteRow0
	.long NakaWidget_DocDpMeasure
	.long NakaWidget_DocDpFileSelector
	.long NakaWidget_DocDpFileList
	.long NakaWidget_DocDpRT2Selector
	.long NakaWidget_DocDpOrchSelector
	.long NakaWidget_DocDpMixer
	.long NakaWidget_DocDpMic
	.byte 0x00, 0x00, 0x00, 0x00
NakaWidgetPtrTbl_PdDp:
	.long NakaWidget_PdDpContainer
	.long NakaWidget_PdDpVolume
	.long NakaWidget_PdDpGroup
	.long NakaWidget_PdDpMuteRow0
	.long NakaWidget_PdDpMuteRow1
	.long NakaWidget_PdDpMeasure
	.long NakaWidget_PdDpFileSelector
	.long NakaWidget_PdDpFileList
	.long NakaWidget_PdDpOrchSelector
	.long NakaWidget_PdDpMixer
	.long NakaWidget_PdDpMic
	.byte 0x00, 0x00, 0x00, 0x00
NakaWidgetPtrTbl_SmfMdly:
	.long NakaWidget_SmfMdlyContainer
	.long NakaWidget_SmfMdlyVolume
	.long NakaWidget_SmfMdlyMeasure
	.long NakaWidget_SmfMdlyFileSelector
	.long NakaWidget_SmfMdlyMicWidget
	.long NakaWidget_SmfMdlyOrchSel
	.long NakaWidget_SmfMdlyOrchRow
	.byte 0x00, 0x00, 0x00, 0x00
NakaWidgetPtrTbl_DocMdly:
	.long NakaWidget_SmfMdlyContainer2
	.long NakaWidget_SmfMdlyLyricsItem
	.long NakaWidget_SmfMdlySubPanel
	.long NakaWidget_SmfMdlyLyricsToggle
	.long NakaWidget_SmfMdlyGroup
	.long NakaWidget_SmfMdlyMuteRow0
	.long NakaWidget_SmfMdlyMuteRow1
	.long NakaWidget_SmfMdlyMuteToggle
	.long NakaWidget_SmfMdlySkipLabel
	.long NakaWidget_SmfMdlyMutePanel
	.long NakaWidget_SmfMdlyMeasureBox
	.long NakaWidget_SmfMdlyOffOnSel
	.long NakaWidget_SmfMdlyOffOnList
	.long NakaWidget_SmfMdlyMixerWidget
	.long NakaWidget_SmfMdlyMicWidget2
	.long NakaWidget_SmfMdlyMuteChLabel
	.byte 0x00, 0x00, 0x00, 0x00, 0xf4, 0x1e, 0xe2, 0x00
NakaWidgetPtrTbl_PdMdly:
	.long NakaWidget_SmfMdlyRootContainer
	.long NakaWidget_DocMdlyContainer
	.long NakaWidget_DocMdlyGroup
	.long NakaWidget_DocMdlyMuteRow0
	.long NakaWidget_DocMdlySubPanel
	.long NakaWidget_DocMdlyMuteToggle
	.long NakaWidget_DocMdlySkipLabel
	.long NakaWidget_DocMdlyMeasureBox
	.long NakaWidget_DocMdlyOffOnSel
	.long NakaWidget_DocMdlyOffOnList
	.long NakaWidget_DocMdlyRT2Sel
	.long NakaWidget_DocMdlyOrchSel
	.long NakaWidget_DocMdlyMixer
	.long NakaWidget_DocMdlyMic
	.byte 0x00, 0x00, 0x00, 0x00, 0x78, 0x21, 0xe2, 0x00
NakaWidgetPtrTbl_SmfMdly2:
	.long NakaWidget_PdMdlyContainer
	.long NakaWidget_PdMdlyGroup
	.long NakaWidget_PdMdlyMuteRow0
	.long NakaWidget_PdMdlyMuteRow1
	.long NakaWidget_PdMdlyMuteToggle
	.long NakaWidget_PdMdlySkipLabel
	.long NakaWidget_PdMdlyMeasureBox
	.long NakaWidget_PdMdlyOffOnSel
	.long NakaWidget_PdMdlyOffOnList
	.long NakaWidget_PdMdlyRT2Sel
	.long NakaWidget_PdMdlyMixer
	.long NakaWidget_PdMdlyMic
	.byte 0x00, 0x00, 0x00, 0x00, 0x9c, 0x23, 0xe2, 0x00
NakaWidgetPtrTbl_SongMdly:
	.long NakaWidget_SmfMdly2Container
	.long NakaWidget_SmfMdly2MuteToggle
	.long NakaWidget_SmfMdly2SkipLabel
	.long NakaWidget_SmfMdly2MeasureBox
	.long NakaWidget_SmfMdly2OffOnSel
	.long NakaWidget_SmfMdly2MicWidget
	.long NakaWidget_SmfMdly2OrchSel
	.byte 0x00, 0x00, 0x00, 0x00
NakaWidgetPtrTbl_SongMdly2:
	.long NakaWidget_SongMdlyContainer
	.long NakaWidget_SongMdlyGroup
	.long NakaWidget_SongMdlyVolume
	.long NakaWidget_SongMdlySongSel
	.long NakaWidget_SongMdlySongList
	.long NakaWidget_SongMdlyRT1Sel
	.long NakaWidget_SongMdlyMeasureBox
	.long NakaWidget_SongMdlyFileList
	.long NakaWidget_SongMdlyMutePanel
	.long NakaWidget_SongMdlyMuteList
	.long NakaWidget_SongMdlySkipLabel
	.long NakaWidget_SongMdlyOffOnSel
	.long NakaWidget_SongMdlyMixer
	.long NakaWidget_SongMdlyOrchSel
	.long NakaWidget_SongMdlySongSel1
	.long NakaWidget_SongMdlySongSel2
	.long NakaWidget_SongMdlySongSel3
	.long NakaWidget_SongMdlySongSel4
	.long NakaWidget_SongMdlySongSel5
	.long NakaWidget_SongMdlySongSel6
	.long NakaWidget_SongMdlySongSel7
	.long NakaWidget_SongMdlySongSel8
	.long NakaWidget_SongMdlySongSel9
	.long NakaWidget_SongMdlySongSel10
	.long NakaWidget_SongMdlySongSel11
	.long NakaWidget_SongMdlySongSel12
	.long NakaWidget_SongMdlySongSel13
	.long NakaWidget_SongMdlySongSel14
	.long NakaWidget_SongMdlySongSel15
	.long NakaWidget_SongMdlySongSel16
	.byte 0x00, 0x00, 0x00, 0x00, 0x06, 0x29, 0xe2, 0x00
NakaWidgetPtrTbl_StepRec:
	.long NakaWidget_SongMdly2Group
	.long NakaWidget_SongMdly2Volume
	.long NakaWidget_SongMdly2SongList
	.long NakaWidget_SongMdly2SongSel
	.long NakaWidget_SongMdly2RT1Sel
	.long NakaWidget_SongMdly2SkipLabel
	.long NakaWidget_SongMdly2MeasureBox
	.long NakaWidget_SongMdly2FileList
	.long NakaWidget_SongMdly2MutePanel
	.long NakaWidget_SongMdly2OffOnSel
	.long NakaWidget_SongMdly2Mixer
	.byte 0x00, 0x00, 0x00, 0x00
NakaWidgetPtrTbl_TrAs:
	.long NakaWidget_StepRecContainer
	.long NakaWidget_StepRecPartLabel
	.long NakaWidget_StepRecPartPanel
	.long NakaWidget_StepRecPartList
	.long NakaWidget_StepRecOrchRow
	.byte 0x00, 0x00, 0x00, 0x00
	.long NakaWidget_StepRecSubPanel
	.byte 0x00, 0x00, 0x00, 0x00
	.long NakaWidget_TrAsContainer
	.long NakaWidget_TrAsPresetItem
	.long NakaWidget_TrAsFileList
	.byte 0xa2, 0xde, 0x03, 0x00
NakaWidgetPtrTbl_TrAsPreset:
	.long NakaWidget_TrAsGridDisplay
	.long NakaWidget_TrAsTrackAssign
	.long NakaWidget_TrAsLocalCont
	.long NakaWidget_TrAsMidiOut
	.long NakaWidget_TrAsMatrix
	.byte 0xce, 0xde, 0x03, 0x00
NakaWidgetPtrTbl_TrAsPreset2:
	.long NakaWidget_TrAsRT1Toggle
	.long NakaWidget_TrAsRT2Toggle
	.long NakaWidget_TrAsMeasureBox
	.long NakaWidget_TrAsSubContainer
	.long NakaWidget_TrAsGroup
	.long NakaWidget_TrAsPartList0
	.long NakaWidget_TrAsPartList1
	.long NakaWidget_TrAsPartList2
	.long NakaWidget_TrAsMeasureBox2
	.long NakaWidget_TrAsRT1Selector
	.long NakaWidget_TrAsRT2Selector
	.long NakaWidget_TrAsPresetSel
	.byte 0x00, 0x00, 0x00, 0x00, 0x50, 0x2f, 0xe2, 0x00


NakaWidgetPtrTbl_TrAsPreset3:
	.long NakaWidget_TrAsPresetSong
	.long NakaWidget_TrAsPresetMatrix
	.long NakaWidget_TrAsPresetPanel
	.long NakaWidget_TrAsPresetInit
	.long NakaWidget_TrAsPresetGmRec
	.long NakaWidget_TrAsPresetMeasure
	.long NakaWidget_TrAsPresetRT2Sel
	.long NakaWidget_TrAsPresetList
	.long NakaWidget_TrAsPresetGroup
	.long NakaWidget_TrAsPresetContainer
	.long NakaWidget_TrAsPresetMeasure2
	.long NakaWidget_TrAsPresetRT1Sel
	.long NakaWidget_TrAsPresetRT2Sel2
	.long NakaWidget_TrAsPresetGroup2
	.long NakaWidget_TrAsPresetTypeSel
	.long NakaWidget_TrAsPresetList2
	.long NakaWidget_TrAsPresetList3
	.long NakaWidget_TrAsPresetList4
	.long NakaWidget_TrAsPresetContainer2
	.long NakaWidget_TrAsPresetGroup3
	.long NakaWidget_TrAsPresetTypeSel2
	.long NakaWidget_TrAsPresetList5
	.long NakaWidget_TrAsPresetList6
	.long NakaWidget_TrAsPresetList7
	.long NakaWidget_TrAsPresetMeasure3
	.long NakaWidget_TrAsPresetRT1Sel2
	.long NakaWidget_TrAsPresetRT2Sel3
	.byte 0x00, 0x00, 0x00, 0x00


NakaWidgetPtrTbl_SongSelNam:
	.long NakaWidget_SongSelNamContainer
	.long NakaWidget_SongSelNamNameItem
	.long NakaWidget_SongSelNamSongSel
	.long NakaWidget_SongSelNamNameEdit
	.long NakaWidget_SongSelNamDuration
	.byte 0x00, 0x00, 0x00, 0x00


NakaWidgetPtrTbl_Naming:
	.long NakaWidget_NamingContainer
	.long NakaWidget_NamingCharSel
	.long NakaWidget_NamingSeqLabel
	.long NakaWidget_NamingMeasureBox
	.long NakaWidget_NamingDisplayMode
	.long NakaWidget_NamingOrchRow
	.byte 0x00, 0x00, 0x00, 0x00, 0x20, 0x36, 0xe2, 0x00
	.long NakaWidget_AftTouchDuration
	.long NakaWidget_AftTouchChSel
	.long NakaWidget_AftTouchList
	.byte 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x04, 0x37, 0xe2, 0x00
NakaWidgetPtrTbl_AftTouch:
	.long NakaWidget_PartBal0
	.long NakaWidget_PartBal1
	.long NakaWidget_PartBal2
	.long NakaWidget_PartBal3
	.long NakaWidget_PartBal4
	.byte 0x00, 0x00, 0x00, 0x00


NakaWidgetPtrTbl_PartBal:
	.long NakaWidget_DemoContainer
	.long NakaWidget_DemoPerfItem
	.long NakaWidget_DemoFeatPresItem
	.long NakaWidget_DemoMeasureBox
	.byte 0x00, 0x00, 0x00, 0x00, 0xbe, 0x38, 0xe2, 0x00


NakaWidgetPtrTbl_Demo:
	.long NakaWidget_PerfMainMedley
	.long NakaWidget_PerfAccordionMedley
	.long NakaWidget_PerfFolkMedley
	.long NakaWidget_PerfClassical
	.long NakaWidget_PerfShow
	.long NakaWidget_PerfContemporary
	.long NakaWidget_PerfStyleSel
	.long NakaWidget_PerfSoundSel
	.long NakaWidget_PerfRhythmSel
	.long NakaWidget_PerfMeasureBox
	.long NakaWidget_PerfFileList
	.byte 0x00, 0x00, 0x00, 0x00


NakaWidgetPtrTbl_Perf:
	.long NakaWidget_Perf2Container
	.long NakaWidget_Perf2Strings
	.long NakaWidget_Perf2Gamelan
	.long NakaWidget_Perf2Flute
	.long NakaWidget_Perf2Guitar
	.long NakaWidget_Perf2SaxBrass
	.long NakaWidget_Perf2Piano
	.long NakaWidget_Perf2StyleSel
	.long NakaWidget_Perf2SoundSel
	.long NakaWidget_Perf2RhythmSel
	.long NakaWidget_Perf2MeasureBox
	.long NakaWidget_Perf2FileList
	.byte 0x00, 0x00, 0x00, 0x00, 0xf4, 0x3d, 0xe2, 0x00


NakaWidgetPtrTbl_Perf2:
	.long NakaWidget_Perf3HokieDance
	.long NakaWidget_Perf3JazzBand
	.long NakaWidget_Perf3LatinOrch
	.long NakaWidget_Perf3BigBand
	.long NakaWidget_Perf3SymphOrch
	.long NakaWidget_Perf3ModernBluegrass
	.long NakaWidget_Perf3StyleSel
	.long NakaWidget_Perf3SoundSel
	.long NakaWidget_Perf3RhythmSel
	.long NakaHdr_Perf2MeasureBoxData
	.long NakaHdr_Perf2FileListData
	.byte 0x00, 0x00, 0x00, 0x00


NakaWinStateTbl_DpSmf:
	.long NakaInst_DpSmf
	.long NakaWinStr_DpSmf_1
	.long NakaWinStr_DpSmf_2
	.long NakaWinStr_DpSmf_3
	.long NakaWinStr_DpSmf_4
	.long NakaWinStr_DpSmf_5
	.long NakaWinStr_DpSmf_6
	.long NakaWinStr_DpSmf_7
	.long NakaWinStr_DpSmf_8
	.long NakaWinStr_DpSmf_9
	.long NakaInst_SMFMuteSw
	.long NakaWinStr_DpSmf_11
	.long NakaWinStr_DpSmf_12
	.long NakaWinStr_DpSmf_13
	.long NakaWinStr_DpSmf_14
	.long NakaWinStr_DpSmf_15
	.long NakaWinStr_DpSmf_16
	.long NakaWinStr_DpSmf_17
	.long NakaWinStr_DpSmf_18
	.long NakaWinStr_DpSmf_19
	.long NakaWinStr_DpSmf_20
	.long NakaWinStr_DpSmf_21
	.long NakaWinStr_DpSmf_22
	.long NakaWinStr_DpSmf_23
	.long NakaInst_CDswWindow
	.long NakaWinStr_DpSmf_25
	.long NakaWinStr_DpSmf_26
	.long NakaWinStr_DpSmf_27
	.long NakaWinStr_DpSmf_28
	.long NakaWinStr_DpSmf_29
	.long NakaWinStr_DpSmf_30
	.long NakaWinStr_DpSmf_31
	.long NakaWinStr_DpSmf_32
	.long NakaWinStr_DpSmf_33
	.long NakaWinStr_DpSmf_34
	.long NakaWinStr_DpSmf_35
	.long NakaInst_PauseDisp
	.long NakaInst_PlayDisp
	.long NakaInst_Lyrics
	.long NakaInst_LyricsData
	.long NakaWinStr_DpSmf_40
	.long NakaInst_LyricsSong
	.long NakaInst_Comporser
	.long NakaWinStateStr_DpSmf_0
NakaWinStateStr_DpSmf_0:	aligned_string ""
NakaInst_Comporser:			aligned_string "Comporser"
NakaInst_LyricsSong:			aligned_string "LyricsSong"
NakaWinStr_DpSmf_40:			aligned_string ""
NakaInst_LyricsData:			aligned_string "LyricsData"
NakaInst_Lyrics:			aligned_string "Lyrics"
NakaInst_PlayDisp:			aligned_string "PlayDisp"
NakaInst_PauseDisp:			aligned_string "PauseDisp"
NakaWinStr_DpSmf_35:			aligned_string ""
NakaWinStr_DpSmf_34:			aligned_string ""
NakaWinStr_DpSmf_33:			aligned_string ""
NakaWinStr_DpSmf_32:			aligned_string ""
NakaWinStr_DpSmf_31:			aligned_string ""
NakaWinStr_DpSmf_30:			aligned_string ""
NakaWinStr_DpSmf_29:			aligned_string ""
NakaWinStr_DpSmf_28:			aligned_string ""
NakaWinStr_DpSmf_27:			aligned_string ""
NakaWinStr_DpSmf_26:			aligned_string ""
NakaWinStr_DpSmf_25:			aligned_string ""
NakaInst_CDswWindow:			aligned_string "CDswWindow"
NakaWinStr_DpSmf_23:			aligned_string ""
NakaWinStr_DpSmf_22:			aligned_string ""
NakaWinStr_DpSmf_21:			aligned_string ""
NakaWinStr_DpSmf_20:			aligned_string ""
NakaWinStr_DpSmf_19:			aligned_string ""
NakaWinStr_DpSmf_18:			aligned_string ""
NakaWinStr_DpSmf_17:			aligned_string ""
NakaWinStr_DpSmf_16:			aligned_string ""
NakaWinStr_DpSmf_15:			aligned_string ""
NakaWinStr_DpSmf_14:			aligned_string ""
NakaWinStr_DpSmf_13:			aligned_string ""
NakaWinStr_DpSmf_12:			aligned_string ""
NakaWinStr_DpSmf_11:			aligned_string ""
NakaInst_SMFMuteSw:			aligned_string "SMFMuteSw"
NakaWinStr_DpSmf_9:			aligned_string ""
NakaWinStr_DpSmf_8:			aligned_string ""
NakaWinStr_DpSmf_7:			aligned_string ""
NakaWinStr_DpSmf_6:			aligned_string ""
NakaWinStr_DpSmf_5:			aligned_string ""
NakaWinStr_DpSmf_4:			aligned_string ""
NakaWinStr_DpSmf_3:			aligned_string ""
NakaWinStr_DpSmf_2:			aligned_string ""
NakaWinStr_DpSmf_1:			aligned_string ""
NakaInst_DpSmf:			aligned_string "DpSmf"
NakaWinStateTbl_DpDoc:
	.long NakaInst_DpDoc
	.long NakaWinStateStr_DpDoc_9
	.long NakaWinStateStr_DpDoc_8
	.long NakaWinStateStr_DpDoc_7
	.long NakaWinStateStr_DpDoc_6
	.long NakaWinStateStr_DpDoc_5
	.long NakaWinStateStr_DpDoc_4
	.long NakaInst_DOCR1Sw
	.long NakaInst_DOCR2Sw
	.long NakaInst_DOCOrchSw
	.long NakaWinStateStr_DpDoc_2
	.long NakaWinStateStr_DpDoc_1
	.long NakaWinStateStr_DpDoc_0
NakaWinStateStr_DpDoc_0:	aligned_string ""
NakaWinStateStr_DpDoc_1:	aligned_string ""
NakaWinStateStr_DpDoc_2:	aligned_string ""
NakaInst_DOCOrchSw:			aligned_string "DOCOrchSw"
NakaInst_DOCR2Sw:			.asciz "DOCR2Sw"
NakaInst_DOCR1Sw:			.asciz "DOCR1Sw"
NakaWinStateStr_DpDoc_4:	aligned_string ""
NakaWinStateStr_DpDoc_5:	aligned_string ""
NakaWinStateStr_DpDoc_6:	aligned_string ""
NakaWinStateStr_DpDoc_7:	aligned_string ""
NakaWinStateStr_DpDoc_8:	aligned_string ""
NakaWinStateStr_DpDoc_9:	aligned_string ""
NakaInst_DpDoc:			aligned_string "DpDoc"
NakaWinStateTbl_DpPd:
	.long NakaInst_DpPd
	.long NakaWinStateStr_DpPd_9
	.long NakaWinStateStr_DpPd_8
	.long NakaWinStateStr_DpPd_7
	.long NakaWinStateStr_DpPd_6
	.long NakaWinStateStr_DpPd_5
	.long NakaWinStateStr_DpPd_4
	.long NakaInst_PDR1Sw
	.long NakaInst_PDOrchSw
	.long NakaWinStateStr_DpPd_2
	.long NakaWinStateStr_DpPd_1
	.long NakaWinStateStr_DpPd_0
NakaWinStateStr_DpPd_0:	aligned_string ""
NakaWinStateStr_DpPd_1:	aligned_string ""
NakaWinStateStr_DpPd_2:	aligned_string ""
NakaInst_PDOrchSw:		aligned_string "PDOrchSw"
NakaInst_PDR1Sw:		aligned_string "PDR1Sw"
NakaWinStateStr_DpPd_4:	aligned_string ""
NakaWinStateStr_DpPd_5:	aligned_string ""
NakaWinStateStr_DpPd_6:	aligned_string ""
NakaWinStateStr_DpPd_7:	aligned_string ""
NakaWinStateStr_DpPd_8:	aligned_string ""
NakaWinStateStr_DpPd_9:	aligned_string ""
NakaInst_DpPd:		aligned_string "DpPd"
NakaWinStateTbl_DpSmfLyr:
	.long NakaInst_DpSmfLyr
	.long NakaWinStateStr_DpSmfLyr_6
	.long NakaWinStateStr_DpSmfLyr_5
	.long NakaWinStateStr_DpSmfLyr_4
	.long NakaWinStateStr_DpSmfLyr_3
	.long NakaWinStateStr_DpSmfLyr_2
	.long NakaInst_LyricsFunc
	.long NakaWinStateStr_DpSmfLyr_0
NakaWinStateStr_DpSmfLyr_0:	aligned_string ""
NakaInst_LyricsFunc:			aligned_string "LyricsFunc"
NakaWinStateStr_DpSmfLyr_2:	aligned_string ""
NakaWinStateStr_DpSmfLyr_3:	aligned_string ""
NakaWinStateStr_DpSmfLyr_4:	aligned_string ""
NakaWinStateStr_DpSmfLyr_5:	aligned_string ""
NakaWinStateStr_DpSmfLyr_6:	aligned_string ""
NakaInst_DpSmfLyr:			aligned_string "DpSmfLyr"
NakaWinStateTbl_DpMdlySmf:
	.long NakaInst_DpMdlySmf
	.long NakaWinStateStr_DpMdlySmf_15
	.long NakaWinStateStr_DpMdlySmf_14
	.long NakaWinStateStr_DpMdlySmf_13
	.long NakaWinStateStr_DpMdlySmf_12
	.long NakaWinStateStr_DpMdlySmf_11
	.long NakaWinStateStr_DpMdlySmf_10
	.long NakaWinStateStr_DpMdlySmf_9
	.long NakaWinStateStr_DpMdlySmf_8
	.long NakaWinStateStr_DpMdlySmf_7
	.long NakaWinStateStr_DpMdlySmf_6
	.long NakaWinStateStr_DpMdlySmf_5
	.long NakaInst_SMFMedMuteSw
	.long NakaWinStateStr_DpMdlySmf_3
	.long NakaWinStateStr_DpMdlySmf_2
	.long NakaWinStateStr_DpMdlySmf_1
	.long NakaWinStateStr_DpMdlySmf_0
NakaWinStateStr_DpMdlySmf_0:	aligned_string ""
NakaWinStateStr_DpMdlySmf_1:	aligned_string ""
NakaWinStateStr_DpMdlySmf_2:	aligned_string ""
NakaWinStateStr_DpMdlySmf_3:	aligned_string ""
NakaInst_SMFMedMuteSw:			aligned_string "SMFMedMuteSw"
NakaWinStateStr_DpMdlySmf_5:	aligned_string ""
NakaWinStateStr_DpMdlySmf_6:	aligned_string ""
NakaWinStateStr_DpMdlySmf_7:	aligned_string ""
NakaWinStateStr_DpMdlySmf_8:	aligned_string ""
NakaWinStateStr_DpMdlySmf_9:	aligned_string ""
NakaWinStateStr_DpMdlySmf_10:	aligned_string ""
NakaWinStateStr_DpMdlySmf_11:	aligned_string ""
NakaWinStateStr_DpMdlySmf_12:	aligned_string ""
NakaWinStateStr_DpMdlySmf_13:	aligned_string ""
NakaWinStateStr_DpMdlySmf_14:	aligned_string ""
NakaWinStateStr_DpMdlySmf_15:	aligned_string ""
NakaInst_DpMdlySmf:			aligned_string "DpMdlySmf"
	.long NakaHdr_DpMdlyDoc
NakaWinStateTbl_DpMdlyDoc:
	.long NakaInst_DpMdlyDoc
	.long NakaWinStr_DpMdlyDoc_1
	.long NakaWinStr_DpMdlyDoc_2
	.long NakaWinStr_DpMdlyDoc_3
	.long NakaWinStr_DpMdlyDoc_4
	.long NakaWinStr_DpMdlyDoc_5
	.long NakaWinStr_DpMdlyDoc_6
	.long NakaWinStr_DpMdlyDoc_7
	.long NakaWinStr_DpMdlyDoc_8
	.long NakaInst_DOCMedR1Sw
	.long NakaInst_DOCMedR2Sw
	.long NakaInst_DOCMedOrchSw
	.long NakaWinStr_DpMdlyDoc_12
	.long NakaWinStr_DpMdlyDoc_13
	.long NakaWinStr_DpMdlyDoc_14
NakaWinStr_DpMdlyDoc_14:	aligned_string ""
NakaWinStr_DpMdlyDoc_13:	aligned_string ""
NakaWinStr_DpMdlyDoc_12:	aligned_string ""
NakaInst_DOCMedOrchSw:	aligned_string "DOCMedOrchSw"
NakaInst_DOCMedR2Sw:	aligned_string "DOCMedR2Sw"
NakaInst_DOCMedR1Sw:	aligned_string "DOCMedR1Sw"
NakaWinStr_DpMdlyDoc_8:	aligned_string ""
NakaWinStr_DpMdlyDoc_7:	aligned_string ""
NakaWinStr_DpMdlyDoc_6:	aligned_string ""
NakaWinStr_DpMdlyDoc_5:	aligned_string ""
NakaWinStr_DpMdlyDoc_4:	aligned_string ""
NakaWinStr_DpMdlyDoc_3:	aligned_string ""
NakaWinStr_DpMdlyDoc_2:	aligned_string ""
NakaWinStr_DpMdlyDoc_1:	aligned_string ""
NakaInst_DpMdlyDoc:	aligned_string "DpMdlyDoc"
NakaHdr_DpMdlyDoc:	.byte 0x00, 0xff, 0x30, 0x49, 0xe2, 0x00
Naka_DigitalDelay_Screens:
	.long NakaWinStr_DpMdlyPd_0
	.long NakaWinStr_DpMdlyPd_1
	.long NakaWinStr_DpMdlyPd_2
	.long NakaWinStr_DpMdlyPd_3
	.long NakaWinStr_DpMdlyPd_4
	.long NakaWinStr_DpMdlyPd_5
	.long NakaWinStr_DpMdlyPd_6
	.long NakaWinStr_DpMdlyPd_7
	.long NakaInst_PDMedR1Sw
	.long NakaInst_PDMedOrchSw
	.long NakaWinStr_DpMdlyPd_10
	.long NakaWinStr_DpMdlyPd_11
	.long NakaWinStr_DpMdlyPd_12
NakaWinStr_DpMdlyPd_12:	aligned_string ""
NakaWinStr_DpMdlyPd_11:	aligned_string ""
NakaWinStr_DpMdlyPd_10:	aligned_string ""
NakaInst_PDMedOrchSw:	aligned_string "PDMedOrchSw"
NakaInst_PDMedR1Sw:	aligned_string "PDMedR1Sw"
NakaWinStr_DpMdlyPd_7:	aligned_string ""
NakaWinStr_DpMdlyPd_6:	aligned_string ""
NakaWinStr_DpMdlyPd_5:	aligned_string ""
NakaWinStr_DpMdlyPd_4:	aligned_string ""
NakaWinStr_DpMdlyPd_3:	aligned_string ""
NakaWinStr_DpMdlyPd_2:	aligned_string ""
NakaWinStr_DpMdlyPd_1:	aligned_string ""
NakaWinStr_DpMdlyPd_0:	aligned_string ""
NakaInst_DpMdlyPd:	aligned_string "DpMdlyPd"
Naka_PDMedR1_Screens:
	.long NakaInst_DpMdlySmfLyr
	.long NakaWinStr_DpMdlySmfLyr_1
	.long NakaWinStr_DpMdlySmfLyr_2
	.long NakaWinStr_DpMdlySmfLyr_3
	.long NakaWinStr_DpMdlySmfLyr_4
	.long NakaWinStr_DpMdlySmfLyr_5
	.long NakaWinStr_DpMdlySmfLyr_6
	.long NakaWinStr_DpMdlySmfLyr_7
	.long NakaWinStr_DpMdlySmfLyr_8
NakaWinStr_DpMdlySmfLyr_8:	aligned_string ""
NakaWinStr_DpMdlySmfLyr_7:	aligned_string ""
NakaWinStr_DpMdlySmfLyr_6:	aligned_string ""
NakaWinStr_DpMdlySmfLyr_5:	aligned_string ""
NakaWinStr_DpMdlySmfLyr_4:	aligned_string ""
NakaWinStr_DpMdlySmfLyr_3:	aligned_string ""
NakaWinStr_DpMdlySmfLyr_2:	aligned_string ""
NakaWinStr_DpMdlySmfLyr_1:	aligned_string ""
NakaInst_DpMdlySmfLyr:	aligned_string "DpMdlySmfLyr"
	.long DkMdlyPly_Name
NakaWinStateTbl_DkMdlyPly:
	.long DkMdlyPly_Str29
	.long DkMdlyPly_Str28
	.long DkMdlyPly_Str27
	.long DkMdlyPly_Str26
	.long DkMdlyPly_Str25
	.long DkMdlyPly_Str24
	.long DkMdlyPly_Str23
	.long DkMdlyPly_Str22
	.long DkMdlyPly_Str21
	.long DkMdlyPly_Str20
	.long DkMdlyPly_Str19
	.long DkMdlyPly_Str18
	.long DkMdlyPly_Str17
	.long DkMdlyPly_Str16
	.long DkMdlyPly_Str15
	.long DkMdlyPly_Str14
	.long DkMdlyPly_Str13
	.long DkMdlyPly_Str12
	.long DkMdlyPly_Str11
	.long DkMdlyPly_Str10
	.long DkMdlyPly_Str09
	.long DkMdlyPly_Str08
	.long DkMdlyPly_Str07
	.long DkMdlyPly_Str06
	.long DkMdlyPly_Str05
	.long DkMdlyPly_Str04
	.long DkMdlyPly_Str03
	.long DkMdlyPly_Str02
	.long DkMdlyPly_Str01
	.long DkMdlyPly_Str00
DkMdlyPly_Str00:	aligned_string ""
DkMdlyPly_Str01:	aligned_string ""
DkMdlyPly_Str02:	aligned_string ""
DkMdlyPly_Str03:	aligned_string ""
DkMdlyPly_Str04:	aligned_string ""
DkMdlyPly_Str05:	aligned_string ""
DkMdlyPly_Str06:	aligned_string ""
DkMdlyPly_Str07:	aligned_string ""
DkMdlyPly_Str08:	aligned_string ""
DkMdlyPly_Str09:	aligned_string ""
DkMdlyPly_Str10:	aligned_string ""
DkMdlyPly_Str11:	aligned_string ""
DkMdlyPly_Str12:	aligned_string ""
DkMdlyPly_Str13:	aligned_string ""
DkMdlyPly_Str14:	aligned_string ""
DkMdlyPly_Str15:	aligned_string ""
DkMdlyPly_Str16:	aligned_string ""
DkMdlyPly_Str17:	aligned_string ""
DkMdlyPly_Str18:	aligned_string ""
DkMdlyPly_Str19:	aligned_string ""
DkMdlyPly_Str20:	aligned_string ""
DkMdlyPly_Str21:	aligned_string ""
DkMdlyPly_Str22:	aligned_string ""
DkMdlyPly_Str23:	aligned_string ""
DkMdlyPly_Str24:	aligned_string ""
DkMdlyPly_Str25:	aligned_string ""
DkMdlyPly_Str26:	aligned_string ""
DkMdlyPly_Str27:	aligned_string ""
DkMdlyPly_Str28:	aligned_string ""
DkMdlyPly_Str29:	aligned_string ""
DkMdlyPly_Name:		aligned_string "DkMdlyPly"
DkMdlyPly_SubTable:
	.long SqMdlyPly_Name
	.long DkMdlyPly_SubStr11
	.long DkMdlyPly_SubStr10
	.long DkMdlyPly_SubStr09
	.long DkMdlyPly_SubStr08
	.long DkMdlyPly_SubStr07
	.long DkMdlyPly_SubStr06
	.long DkMdlyPly_SubStr05
	.long DkMdlyPly_SubStr04
	.long DkMdlyPly_SubStr03
	.long DkMdlyPly_SubStr02
	.long DkMdlyPly_SubStr01
	.long DkMdlyPly_SubStr00
DkMdlyPly_SubStr00:	aligned_string ""
DkMdlyPly_SubStr01:	aligned_string ""
DkMdlyPly_SubStr02:	aligned_string ""
DkMdlyPly_SubStr03:	aligned_string ""
DkMdlyPly_SubStr04:	aligned_string ""
DkMdlyPly_SubStr05:	aligned_string ""
DkMdlyPly_SubStr06:	aligned_string ""
DkMdlyPly_SubStr07:	aligned_string ""
DkMdlyPly_SubStr08:	aligned_string ""
DkMdlyPly_SubStr09:	aligned_string ""
DkMdlyPly_SubStr10:	aligned_string ""
DkMdlyPly_SubStr11:	aligned_string ""
SqMdlyPly_Name:		aligned_string "SqMdlyPly"
	.long SqTrSel_Name
SqMdlyPly_SubTable:
	.long SqMdlyPly_SubStr04
	.long SqMdlyPly_SubStr03
	.long SqMdlyPly_SubStr02
	.long SqMdlyPly_SubStr01
	.long SqMdlyPly_SubStr00
SqMdlyPly_SubStr00:	aligned_string ""
SqMdlyPly_SubStr01:	aligned_string ""
SqMdlyPly_SubStr02:	aligned_string ""
SqMdlyPly_SubStr03:	aligned_string ""
SqMdlyPly_SubStr04:	aligned_string ""
SqTrSel_Name:		aligned_string "SqTrSel"
	muls8rr b, w
	.byte 0xe2, 0x00
	.long SqTrSel_Str00
SqTrSel_Str00:	aligned_string ""
SqTrSel_Str01:	aligned_string ""
SqTrAs_StrTable:
	.long SqTrAs_Name
	.long SqTrAs_Str13
	.long SqTrAs_Str12
	.long TrAsOkSw_Name
	.long TrAsGrid_Name
	.long TrAsGrid_Str03
	.long TrAsGrid_Str02
	.long TrAsGrid_Str01
	.long TrAsGrid_Str00
	.long TrAsPartSelSw_Name
	.long SqTrAs_Str11
	.long SqTrAs_Str10
	.long SqTrAs_Str09
	.long SqTrAsSure_Name
	.long SqTrAs_Str08
	.long SqTrAs_Str07
	.long SqTrAs_Str06
	.long SqTrAs_Str05
	.long SqTrAs_Str04
	.long SqTrAs_Str03
	.long SqTrAs_Str02
	.long SqTrAs_Str01
	.long SqTrAs_Str00
SqTrAs_Str00:		aligned_string ""
SqTrAs_Str01:		aligned_string ""
SqTrAs_Str02:		aligned_string ""
SqTrAs_Str03:		aligned_string ""
SqTrAs_Str04:		aligned_string ""
SqTrAs_Str05:		aligned_string ""
SqTrAs_Str06:		aligned_string ""
SqTrAs_Str07:		aligned_string ""
SqTrAs_Str08:		aligned_string ""
SqTrAsSure_Name:	aligned_string "SqTrAsSure"
SqTrAs_Str09:		aligned_string ""
SqTrAs_Str10:		aligned_string ""
SqTrAs_Str11:		aligned_string ""
TrAsPartSelSw_Name:	aligned_string "TrAsPartSelSw"
TrAsGrid_Str00:		aligned_string ""
TrAsGrid_Str01:		aligned_string ""
TrAsGrid_Str02:		aligned_string ""
TrAsGrid_Str03:		aligned_string ""
TrAsGrid_Name:		aligned_string "TrAsGrid"
TrAsOkSw_Name:		aligned_string "TrAsOkSw"
SqTrAs_Str12:		aligned_string ""
SqTrAs_Str13:		aligned_string ""
SqTrAs_Name:		aligned_string "SqTrAs"
SqTrAsPs_StrTable:
	.long SqTrAsPs_Name
	.long SqTrAsPs_Str22
	.long SqTrAsPs_Str21
	.long SqTrAsPs_Str20
	.long TrAsPsIniSel_Name
	.long TrAsPsTechSel_Name
	.long TrAsPsGmSel_Name
	.long SqTrAsPs_Str19
	.long SqTrAsPs_Str18
	.long SqTrAsPs_Str17
	.long SqTrAsPsSure1_Name
	.long SqTrAsPs_Str16
	.long SqTrAsPs_Str15
	.long SqTrAsPs_Str14
	.long SqTrAsPs_Str13
	.long SqTrAsPs_Str12
	.long SqTrAsPs_Str11
	.long SqTrAsPs_Str10
	.long SqTrAsPs_Str09
	.long SqTrAsPsSure2_Name
	.long SqTrAsPs_Str08
	.long SqTrAsPs_Str07
	.long SqTrAsPs_Str06
	.long SqTrAsPs_Str05
	.long SqTrAsPs_Str04
	.long SqTrAsPs_Str03
	.long SqTrAsPs_Str02
	.long SqTrAsPs_Str01
	.long SqTrAsPs_Str00
SqTrAsPs_Str00:		aligned_string ""
SqTrAsPs_Str01:		aligned_string ""
SqTrAsPs_Str02:		aligned_string ""
SqTrAsPs_Str03:		aligned_string ""
SqTrAsPs_Str04:		aligned_string ""
SqTrAsPs_Str05:		aligned_string ""
SqTrAsPs_Str06:		aligned_string ""
SqTrAsPs_Str07:		aligned_string ""
SqTrAsPs_Str08:		aligned_string ""
SqTrAsPsSure2_Name:	aligned_string "SqTrAsPsSure2"
SqTrAsPs_Str09:		aligned_string ""
SqTrAsPs_Str10:		aligned_string ""
SqTrAsPs_Str11:		aligned_string ""
SqTrAsPs_Str12:		aligned_string ""
SqTrAsPs_Str13:		aligned_string ""
SqTrAsPs_Str14:		aligned_string ""
SqTrAsPs_Str15:		aligned_string ""
SqTrAsPs_Str16:		aligned_string ""
SqTrAsPsSure1_Name:	aligned_string "SqTrAsPsSure1"
SqTrAsPs_Str17:		aligned_string ""
SqTrAsPs_Str18:		aligned_string ""
SqTrAsPs_Str19:		aligned_string ""
TrAsPsGmSel_Name:	aligned_string "TrAsPsGmSel"
TrAsPsTechSel_Name:	aligned_string "TrAsPsTechSel"
TrAsPsIniSel_Name:	aligned_string "TrAsPsIniSel"
SqTrAsPs_Str20:		aligned_string ""
SqTrAsPs_Str21:		aligned_string ""
SqTrAsPs_Str22:		aligned_string ""
SqTrAsPs_Name:		aligned_string "SqTrAsPs"
SqSngSel_StrTable:
	.long SqSngSel_Name
	.long SqSngSel_Str04
	.long SqSngSel_Str03
	.long SqSngSel_Str02
	.long SqSngSel_Str01
	.long SqSngSel_Str00
SqSngSel_Str00:	aligned_string ""
SqSngSel_Str01:	aligned_string ""
SqSngSel_Str02:	aligned_string ""
SqSngSel_Str03:	aligned_string ""
SqSngSel_Str04:	aligned_string ""
SqSngSel_Name:	aligned_string "SqSngSel"
	.long SqNameing_Name
SqNameing_StrTable:
	.long SqNameing_Str05
	.long SqNameing_Str04
	.long SqNameing_Str03
	.long SqNameing_Str02
	.long SqNameing_Str01
	.long SqNameing_Str00
SqNameing_Str00:	aligned_string ""
SqNameing_Str01:	aligned_string ""
SqNameing_Str02:	aligned_string ""
SqNameing_Str03:	aligned_string ""
SqNameing_Str04:	aligned_string ""
SqNameing_Str05:	aligned_string ""
SqNameing_Name:		aligned_string "SqNameing"
AfterTouchSet_StrTable:
	.long AfterTouchSet_Name
	.long AfterTouchSet_Str03
	.long AfterTouchSet_Str02
	.long AfterTouchSet_Str01
	.long AfterTouchSet_Str00
AfterTouchSet_Str00:	aligned_string ""
AfterTouchSet_Str01:	aligned_string ""
AfterTouchSet_Str02:	aligned_string ""
AfterTouchSet_Str03:	aligned_string ""
AfterTouchSet_Name:	aligned_string "AfterTouchSet"
	.long AfterTouchSet_Pad
AfterTouchSet_Pad:	aligned_string ""
StepPartBal_StrTable:
	.long StepPartBal_Name
	.long StepPartBal_Str05
	.long StepPartBal_Str04
	.long StepPartBal_Str03
	.long StepPartBal_Str02
	.long StepPartBal_Str01
	.long StepPartBal_Str00
StepPartBal_Str00:	aligned_string ""
StepPartBal_Str01:	aligned_string ""
StepPartBal_Str02:	aligned_string ""
StepPartBal_Str03:	aligned_string ""
StepPartBal_Str04:	aligned_string ""
StepPartBal_Str05:	aligned_string ""
StepPartBal_Name:	aligned_string "StepPartBal"
DemoMenu_StrTable:
	.long DemoMenu_Name
	.long DemoMenu_Str03
	.long DemoMenu_Str02
	.long DemoMenu_Str01
	.long DemoMenu_Str00
DemoMenu_Str00:	aligned_string ""
DemoMenu_Str01:	aligned_string ""
DemoMenu_Str02:	aligned_string ""
DemoMenu_Str03:	aligned_string ""
DemoMenu_Name:	aligned_string "DemoMenu"
DemoStyle_StrTable:
	.long DemoStyle_Name
	.long DemoSong0_Name
	.long DemoSong1_Name
	.long DemoSong2_Name
	.long DemoSong3_Name
	.long DemoSong4_Name
	.long DemoSong5_Name
	.long DemoStyle_Str03
	.long DemoStyle_Str02
	.long DemoStyle_Str01
	.long DemoStyle_Str00
	.long DemoMed1_Name
	.long DemoMed1_Str00
DemoMed1_Str00:		aligned_string ""
DemoMed1_Name:		aligned_string "DemoMed1"
DemoStyle_Str00:	aligned_string ""
DemoStyle_Str01:	aligned_string ""
DemoStyle_Str02:	aligned_string ""
DemoStyle_Str03:	aligned_string ""
DemoSong5_Name:		aligned_string "DemoSong5"
DemoSong4_Name:		aligned_string "DemoSong4"
DemoSong3_Name:		aligned_string "DemoSong3"
DemoSong2_Name:		aligned_string "DemoSong2"
DemoSong1_Name:		aligned_string "DemoSong1"
DemoSong0_Name:		aligned_string "DemoSong0"
DemoStyle_Name:		aligned_string "DemoStyle"
DemoSound_StrTable:
	.long DemoSound_Name
	.long DemoSong6_Name
	.long DemoSong7_Name
	.long DemoSong8_Name
	.long DemoSong9_Name
	.long DemoSong10_Name
	.long DemoSong11_Name
	.long DemoSound_Str03
	.long DemoSound_Str02
	.long DemoSound_Str01
	.long DemoSound_Str00
	.long DemoMed2_Name
	.long DemoMed2_Str00
DemoMed2_Str00:		aligned_string ""
DemoMed2_Name:		aligned_string "DemoMed2"
DemoSound_Str00:	aligned_string ""
DemoSound_Str01:	aligned_string ""
DemoSound_Str02:	aligned_string ""
DemoSound_Str03:	aligned_string ""
DemoSong11_Name:	aligned_string "DemoSong11"
DemoSong10_Name:	aligned_string "DemoSong10"
DemoSong9_Name:		aligned_string "DemoSong9"
DemoSong8_Name:		aligned_string "DemoSong8"
DemoSong7_Name:		aligned_string "DemoSong7"
DemoSong6_Name:		aligned_string "DemoSong6"
DemoSound_Name:		aligned_string "DemoSound"
DemoRhy_StrTable:
	.long DemoRhy_Name
	.long DemoSong12_Name
	.long DemoSong13_Name
	.long DemoSong14_Name
	.long DemoSong15_Name
	.long DemoSong16_Name
	.long DemoSong17_Name
	.long DemoRhy_Str03
	.long DemoRhy_Str02
	.long DemoRhy_Str01
	.long DemoRhy_Str00
	.long DemoMed3_Name
	.long DemoMed3_Str00
DemoMed3_Str00:		aligned_string ""
DemoMed3_Name:		aligned_string "DemoMed3"
DemoRhy_Str00:		aligned_string ""
DemoRhy_Str01:		aligned_string ""
DemoRhy_Str02:		aligned_string ""
DemoRhy_Str03:		aligned_string ""
DemoSong17_Name:	aligned_string "DemoSong17"
DemoSong16_Name:	aligned_string "DemoSong16"
DemoSong15_Name:	aligned_string "DemoSong15"
DemoSong14_Name:	aligned_string "DemoSong14"
DemoSong13_Name:	aligned_string "DemoSong13"
DemoSong12_Name:	aligned_string "DemoSong12"
DemoRhy_Name:		aligned_string "DemoRhy"
	aligned_string "MD_SEQ_STEP"
	.byte 0x4d, 0x44, 0x5f, 0x44
	.byte 0x45, 0x4d, 0x4f, 0x00
	aligned_string "TT_DPSMF"
	aligned_string "TT_DPDOC"
	aligned_string "TT_DPPD"
	aligned_string "TT_DPSMFLYR"
	aligned_string "TT_DPMDLYSMF"
	aligned_string "TT_DPMDLYDOC"
	aligned_string "TT_DPMDLYPD"
	aligned_string "TT_DPMDLYSMFLYR"
	aligned_string "TT_DKMDLYPLY"
	aligned_string "TT_SQMDLYPLY"
	aligned_string "TT_SQTRSEL"
	aligned_string "TT_SQSTEP"
	aligned_string "TT_SQTRAS"
	aligned_string "TT_SQTRASPS"
	aligned_string "TT_SQSNGSEL"
	aligned_string "TT_SQSNGNAME"
	aligned_string "TT_SQAFTSET"
	aligned_string "TT_SQEASYNAME"
	aligned_string "TT_SQSTEPBAL"
	aligned_string "TT_DEMOMENU"
	aligned_string "TT_DEMOSTYLE"
	aligned_string "TT_DEMOSOUND"
	aligned_string "TT_DEMORHY"
	.byte 0xa0, 0x26, 0xf2, 0x00, 0x1c, 0x28
	.byte 0xf2, 0x00, 0x34, 0x18, 0xf2, 0x00, 0xbb, 0x0c
	.byte 0xf2, 0x00, 0xbe, 0x0c, 0xf2, 0x00, 0x09, 0x0d
	.byte 0xf2, 0x00, 0x54, 0x0d, 0xf2, 0x00, 0x34, 0x0e
	.byte 0xf2, 0x00, 0x86, 0x0e, 0xf2, 0x00, 0x20, 0x0f
	.byte 0xf2, 0x00, 0x99, 0x0f, 0xf2, 0x00, 0x2d, 0x10
	.byte 0xf2, 0x00, 0x4b, 0x12, 0xf2, 0x00, 0xfb, 0x12
	.byte 0xf2, 0x00, 0xab, 0x13, 0xf2, 0x00, 0x68, 0x14
	.byte 0xf2, 0x00, 0x0f, 0x1d, 0xf2, 0x00, 0x3e, 0x1e
	.byte 0xf2, 0x00, 0x6d, 0x1f, 0xf2, 0x00, 0xc3, 0x20
	.byte 0xf2, 0x00, 0xe6, 0x21, 0xf2, 0x00, 0x17, 0x22
	.byte 0xf2, 0x00, 0xaf, 0x22, 0xf2, 0x00, 0xcc, 0x22
	.byte 0xf2, 0x00, 0xfd, 0x22, 0xf2, 0x00, 0x00, 0x23
	.byte 0xf2, 0x00, 0xcb, 0x23, 0xf2, 0x00, 0x91, 0x24
	.byte 0xf2, 0x00, 0x57, 0x25, 0xf2, 0x00, 0x4c, 0x15
	.byte 0xf2, 0x00, 0xb8, 0x5a, 0xf4, 0x00, 0x00, 0x00
	.byte 0x00, 0x00
TtlFunc_PtrTable:
	.long SeqSongNameFunc_Name
	.long SeqSongMemoryFunc_Name
	.long CDlikeSwTtlFunc_Name
	.long SqAftSetTtlFunc_Name
	.long SqSngSelTtlFunc_Name
	.long SqSngNameTtlFunc_Name
	.long SqTrAsTtlFunc_Name
	.long SqTrAsSureFunc_Name
	.long SqTrAsPsTtlFunc_Name
	.long SqTrAsPsSureFunc_Name
	.long SqMdlyPlyTtlFunc_Name
	.long DkMdlyPlyTtlFunc_Name
	.long DpMdlyDocTtlFunc_Name
	.long DpMdlyPdTtlFunc_Name
	.long DpMdlySmfTtlFunc_Name
	.long DpMdlySmfLyrTtlFunc_Name
	.long DpDocTtlFunc_Name
	.long DpPdTtlFunc_Name
	.long DpSmfTtlFunc_Name
	.long DpSmfLyrTtlFunc_Name
	.long SeqStepModeFunc_Name
	.long SqTrSelTtlFunc_Name
	.long SqStepTtlFunc_Name
	.long DemoModeFunc_Name
	.long DemoMenuTtlFunc_Name
	.long DemoStyleTtlFunc_Name
	.long DemoSoundTtlFunc_Name
	.long DemoRhyTtlFunc_Name
	.long MiddleFuncCall_Name
	.long NameGetFuncCall_Name
	.long ApPlaySyori_Name
	.long ApPlaySyori_Str00
ApPlaySyori_Str00:		aligned_string ""
ApPlaySyori_Name:		aligned_string "ApPlaySyori"
NameGetFuncCall_Name:		aligned_string "NameGetFuncCall"
MiddleFuncCall_Name:		aligned_string "MiddleFuncCall"
DemoRhyTtlFunc_Name:		aligned_string "DemoRhyTtlFunc"
DemoSoundTtlFunc_Name:		aligned_string "DemoSoundTtlFunc"
DemoStyleTtlFunc_Name:		aligned_string "DemoStyleTtlFunc"
DemoMenuTtlFunc_Name:		aligned_string "DemoMenuTtlFunc"
DemoModeFunc_Name:		aligned_string "DemoModeFunc"
SqStepTtlFunc_Name:		aligned_string "SqStepTtlFunc"
SqTrSelTtlFunc_Name:		aligned_string "SqTrSelTtlFunc"
SeqStepModeFunc_Name:		aligned_string "SeqStepModeFunc"
DpSmfLyrTtlFunc_Name:		aligned_string "DpSmfLyrTtlFunc"
DpSmfTtlFunc_Name:		aligned_string "DpSmfTtlFunc"
DpPdTtlFunc_Name:		aligned_string "DpPdTtlFunc"
DpDocTtlFunc_Name:		aligned_string "DpDocTtlFunc"
DpMdlySmfLyrTtlFunc_Name:	aligned_string "DpMdlySmfLyrTtlFunc"
DpMdlySmfTtlFunc_Name:		aligned_string "DpMdlySmfTtlFunc"
DpMdlyPdTtlFunc_Name:		aligned_string "DpMdlyPdTtlFunc"
DpMdlyDocTtlFunc_Name:		aligned_string "DpMdlyDocTtlFunc"
DkMdlyPlyTtlFunc_Name:		aligned_string "DkMdlyPlyTtlFunc"
SqMdlyPlyTtlFunc_Name:		aligned_string "SqMdlyPlyTtlFunc"
SqTrAsPsSureFunc_Name:		aligned_string "SqTrAsPsSureFunc"
SqTrAsPsTtlFunc_Name:		aligned_string "SqTrAsPsTtlFunc"
SqTrAsSureFunc_Name:		aligned_string "SqTrAsSureFunc"
SqTrAsTtlFunc_Name:		aligned_string "SqTrAsTtlFunc"
SqSngNameTtlFunc_Name:		aligned_string "SqSngNameTtlFunc"
SqSngSelTtlFunc_Name:		aligned_string "SqSngSelTtlFunc"
SqAftSetTtlFunc_Name:		aligned_string "SqAftSetTtlFunc"
CDlikeSwTtlFunc_Name:		aligned_string "CDlikeSwTtlFunc"
SeqSongMemoryFunc_Name:		aligned_string "SeqSongMemoryFunc"
SeqSongNameFunc_Name:		aligned_string "SeqSongNameFunc"
MsgStepRec_En:			.asciz "Press the up/down button under the screen corresponding to the track that you want to STEP RECORD."
	.byte 0xff
MsgStepRec_De:		aligned_string "Drücken Sie eine der Doppeltasten unter dem Display, entsprechend der Spur, die Sie per STEP RECORD aufnehmen möchten."
MsgStepRec_Fr:		aligned_string "Press the up/down button under the screen corresponding to the track that you want to STEP RECORD."
MsgStepRec_Es:		aligned_string "Press the up/down button under the screen corresponding to the track that you want to STEP RECORD."
MsgStepRec_Id:		aligned_string "Press the up/down button under the screen corresponding to the track that you want to STEP RECORD."
MsgStepRec_En2:		aligned_string "Press the up/down button under the screen corresponding to the track that you want to STEP RECORD."
MsgAftTchRec_En:	aligned_string "Select whether or not After Touch is recorded by Sequencer."
MsgAftTchRec_De:	.asciz "Wählen Sie, ob After Touch Effekte vom Sequenzer aufgezeichnet werden sollen."
MsgAftTchRec_Fr:	aligned_string "Select whether or not After Touch is recorded by Sequencer."
MsgAftTchRec_Es:	aligned_string "Select whether or not After Touch is recorded by Sequencer."
MsgAftTchRec_Id:	aligned_string "Select whether or not After Touch is recorded by Sequencer."
MsgAftTchRec_En2:	aligned_string "Select whether or not After Touch is recorded by Sequencer."
MsgSongClr_En:		aligned_string "Any existing song will be cleared. Press OK to proceed."
MsgSongClr_De:		aligned_string "Jeder Song im Arbeitsspeicher wird gelöscht. Drücken Sie OK zur Bestätigung."
MsgSongClr_Fr:		aligned_string "Any existing song will be cleared. Press OK to proceed."
MsgSongClr_Es:		aligned_string "Any existing song will be cleared. Press OK to proceed."
MsgSongClr_Id:		aligned_string "Any existing song will be cleared. Press OK to proceed."
MsgSongClr_En2:		aligned_string "Any existing song will be cleared. Press OK to proceed."
MsgAttention_En:	aligned_string "ATTENTION!"
MsgAttention_De:	aligned_string "ACHTUNG !"
MsgAttention_Fr:	aligned_string "ATTENTION!"
MsgAttention_Es:	aligned_string "¡ATENCIÓN!"
MsgAttention_Id:	aligned_string "ATTENTION!"
MsgAttention_Id2:	aligned_string "Perhatian !"
MsgAreYouSure_En:	aligned_string "Are You Sure?"
MsgAreYouSure_De:	aligned_string "Sind Sie sicher ?"
MsgAreYouSure_Fr:	aligned_string "Etes vous sûr?"
MsgAreYouSure_Es:	.asciz "¿Está seguro?"
MsgAreYouSure_Id:	aligned_string "Are You Sure?"
MsgAreYouSure_Id2:	aligned_string "Apakah yakin akan dihapus ?"
MsgGmModeOn_En:		aligned_string "Turning on GENERAL MIDI MODE will replace your current settings with GENERAL MIDI settings!"
MsgGmModeOn_De:		.asciz "Durch das Einschalten des GENERAL MIDI MODE werden alle Einstellungen zu GENERAL MIDI Einstellungen geändert!"
MsgGmModeOn_Fr:		aligned_string "L'activation du mode GENERAL MIDI MODE remplacera tous les réglages actuels par les réglages GENERAL MIDI!"
MsgGmModeOn_Es:		.asciz "¡Al activar el modo MIDI General se reemplazan las configuraciones actuales por configuraciones MIDI Generales!"
MsgGmModeOn_En2:	aligned_string "Turning on GENERAL MIDI MODE will replace your current settings with GENERAL MIDI settings!"
MsgGmModeOn_Id:		aligned_string "Aktifkan GENERAL MIDI MODE untuk kembali ke  susunan GENERAL MIDI yang sekarang. "
MsgGmModeOff_En:	aligned_string "Turning off GENERAL MIDI MODE will replace the GENERAL MIDI settings with the original factory settings!"
MsgGmModeOff_De:	aligned_string "Durch das Ausschalten des GENERAL MIDI MODE werden die GENERAL MIDI Einstellungen durch die Werkseinstellungen ersetzt."
MsgGmModeOff_Fr:	aligned_string "La désactivation du mode GENERAL MIDI MODE remplacera tous les réglages GENERAL MIDI par les réglages d'usines!"
MsgGmModeOff_Es:	aligned_string "¡Al desconectar el modo MIDI General se reemplazan las configuraciones MIDI Generales por las configuraciones originales de fábrica!"
MsgGmModeOff_En2:	aligned_string "Turning off GENERAL MIDI MODE will replace the GENERAL MIDI settings with the original factory settings!"
MsgGmModeOff_Id:	aligned_string "Non-aktifkan fungsi GENERAL MIDI MODE bila akan kembali ke susunan GENERAL MIDI sesuai susunan dari pabrik(originil factory settings)."
MsgTrkAssignChg_PtrTable:
	.long MsgTrkAssignChg_En2
	.long MsgTrkAssignChg_De
	.long MsgTrkAssignChg_Fr
	.long MsgTrkAssignChg_Es
	.long MsgTrkAssignChg_En
	.long MsgTrkAssignChg_Id
MsgTrkAssignChg_Id:	aligned_string "Ubahlah assignment dari Tracks %2d dari %s ke %s akan menghapus semua data yang sekarang."
MsgTrkAssignChg_En:	aligned_string "Changing the assignment of Track %2d from %s to %s will erase all the current data."
MsgTrkAssignChg_Es:	.asciz "Al cambiar la asignación de pistas %2d de %s a %s se borrarán todos los datos actuales."
MsgTrkAssignChg_Fr:	aligned_string "Tout changement d'assignation des pistes %2d de%s à%s effacera toutes les données actuelles."
MsgTrkAssignChg_De:	aligned_string "Das Ändern der Spurzuordnung %2d von %s nach %s hat einen Verlust der Daten zur folge."
MsgTrkAssignChg_En2:	aligned_string "Changing the assignment of Track %2d from %s to %s will erase all the current data."
Msg_LangPtrTable:
	.long MsgStepRec_En
	.long MsgStepRec_De
	.long MsgStepRec_Fr
	.long MsgStepRec_Es
	.long MsgStepRec_Id
	.long MsgStepRec_En2
	.long MsgAftTchRec_En
	.long MsgAftTchRec_De
	.long MsgAftTchRec_Fr
	.long MsgAftTchRec_Es
	.long MsgAftTchRec_Id
	.long MsgAftTchRec_En2
	.long MsgSongClr_En
	.long MsgSongClr_De
	.long MsgSongClr_Fr
	.long MsgSongClr_Es
	.long MsgSongClr_Id
	.long MsgSongClr_En2
	.long MsgAttention_En
	.long MsgAttention_De
	.long MsgAttention_Fr
	.long MsgAttention_Es
	.long MsgAttention_Id
	.long MsgAttention_Id2
	.long MsgAreYouSure_En
	.long MsgAreYouSure_De
	.long MsgAreYouSure_Fr
	.long MsgAreYouSure_Es
	.long MsgAreYouSure_Id
	.long MsgAreYouSure_Id2
	.long MsgGmModeOn_En
	.long MsgGmModeOn_De
	.long MsgGmModeOn_Fr
	.long MsgGmModeOn_Es
	.long MsgGmModeOn_En2
	.long MsgGmModeOn_Id
	.long MsgGmModeOff_En
	.long MsgGmModeOff_De
	.long MsgGmModeOff_Fr
	.long MsgGmModeOff_Es
	.long MsgGmModeOff_En2
	.long MsgGmModeOff_Id
	.long TrkName_Right1
	.long TrkName_Left
	.long TrkName_Right2
	.long TrkName_Part8
	.long TrkName_Part9
	.long TrkName_Part10
	.long TrkName_Part11
	.long TrkName_Part12
	.long TrkName_Part5
	.long TrkName_Part6
	.long TrkName_Part7
	.long TrkName_Part4
	.long TrkName_Drums
	.long TrkName_Chord
	.long TrkName_APC
	.long TrkName_Control
	.long TrkName_Rhythm
	.long TrkName_Part13
	.long TrkName_Part14
	.long TrkName_Part15
TrkName_Part15:		aligned_string "PART15"
TrkName_Part14:		aligned_string "PART14"
TrkName_Part13:		aligned_string "PART13"
TrkName_Rhythm:		aligned_string "RHYTHM"
TrkName_Control:	aligned_string "CONTROL"
TrkName_APC:
	.byte 0x41, 0x50, 0x43, 0x00
TrkName_Chord:	.asciz "CHORD"
TrkName_Drums:	aligned_string "DRUMS"
TrkName_Part4:	aligned_string "PART4"
TrkName_Part7:	.asciz "PART7"
TrkName_Part6:	.asciz "PART6"
TrkName_Part5:	aligned_string "PART5"
TrkName_Part12:	aligned_string "PART12"
TrkName_Part11:	aligned_string "PART11"
TrkName_Part10:	aligned_string "PART10"
TrkName_Part9:	aligned_string "PART9"
TrkName_Part8:	.asciz "PART8"
TrkName_Right2:	aligned_string "RIGHT2"
TrkName_Left:	aligned_string "LEFT"
TrkName_Right1:	aligned_string "RIGHT1"
	aligned_string "Lyrc"
	aligned_string "MEASURE = %3d"
	ldb	w, 0x20
	aligned_string "                       "
	aligned_string "                         "
	aligned_string "                         "
	aligned_string "                         "
	ldb	w, 0x20
	aligned_string "                       "
	aligned_string "                         "
	aligned_string "                         "
	aligned_string "ExMD"


ExMD_PartName_PtrTable:
	.long ExMD_PartName_Right1
	.long ExMD_PartName_Left
	.long ExMD_PartName_Right2
	.long ExMD_PartName_Part8
	.long ExMD_PartName_Part9
	.long ExMD_PartName_Part10
	.long ExMD_PartName_Part11
	.long ExMD_PartName_Part12
	.long ExMD_PartName_Part5
	.long ExMD_PartName_Part6
	.long ExMD_PartName_Part7
	.long ExMD_PartName_Part4
	.long ExMD_PartName_Drums
	.long ExMD_PartName_Chord
	.long ExMD_PartName_APC
	.long ExMD_PartName_Control
	.long ExMD_PartName_Rhythm
	.long ExMD_PartName_Part13
	.long ExMD_PartName_Part14
	.long ExMD_PartName_Part15
ExMD_PartName_Part15:	aligned_string " PART 15 "
ExMD_PartName_Part14:	aligned_string " PART 14 "
ExMD_PartName_Part13:	aligned_string " PART 13 "
ExMD_PartName_Rhythm:	aligned_string " RHYTHM  "
ExMD_PartName_Control:	aligned_string " CONTROL "
ExMD_PartName_APC:	aligned_string " APC     "
ExMD_PartName_Chord:	aligned_string " CHORD   "
ExMD_PartName_Drums:	aligned_string " DRUMS   "
ExMD_PartName_Part4:	aligned_string " PART 4  "
ExMD_PartName_Part7:	aligned_string " PART 7  "
ExMD_PartName_Part6:	aligned_string " PART 6  "
ExMD_PartName_Part5:	aligned_string " PART 5  "
ExMD_PartName_Part12:	aligned_string " PART 12 "
ExMD_PartName_Part11:	aligned_string " PART 11 "
ExMD_PartName_Part10:	aligned_string " PART 10 "
ExMD_PartName_Part9:	aligned_string " PART 9  "
ExMD_PartName_Part8:	aligned_string " PART 8  "
ExMD_PartName_Right2:	aligned_string " RIGHT2  "
ExMD_PartName_Left:	aligned_string " LEFT    "
ExMD_PartName_Right1:	aligned_string " RIGHT1  "
	aligned_string "|-|TR 1|TR 2|TR 3|TR 4|TR 5|TR 6|TR 7|TR 8"
	aligned_string "|-|TR 9|TR10|TR11|TR12|TR13|TR14|TR15|TR16"
	.byte 0x8d, 0x00, 0xfa, 0x01, 0x8d, 0x00
	.byte 0xfa, 0x01, 0x70, 0x04, 0x96, 0x03, 0x96, 0x03
	.byte 0x01, 0x00, 0x02, 0x00, 0x04, 0x00, 0x08, 0x00
	.byte 0x10, 0x00, 0x20, 0x00, 0x40, 0x00, 0x80, 0x00
	.byte 0x00, 0x01, 0x00, 0x02, 0x00, 0x04, 0x00, 0x08
	.byte 0x00, 0x10, 0x00, 0x20, 0x00, 0x40, 0x00, 0x80
	.byte 0x00, 0x02, 0x01, 0x07, 0x08, 0x09, 0x0a, 0x0b
	.byte 0x04, 0x05, 0x06, 0x03, 0x0f, 0x12, 0x10, 0x11
	.byte 0x13, 0x0c, 0x0d, 0x0e, 0x00, 0x02, 0x01, 0x0b
	.byte 0x08, 0x09, 0x0a, 0x03, 0x04, 0x05, 0x06, 0x07
	.byte 0x11, 0x12, 0x13, 0x0c, 0x0e, 0x0f, 0x0d, 0x10
	.asciz "ON "
	.asciz "OFF"
	.asciz "-- "
	.asciz "-- "
	.asciz "ON "
	.asciz "OFF"
	.asciz "-- "
	.asciz "-- "
	.asciz "ON "
	.asciz "OFF"
	.asciz "-- "
	.asciz "-- "
	.asciz "ON "
	.asciz "OFF"
	.asciz "-- "
	.asciz "-- "
	.byte 0x00, 0x00, 0x3c, 0x01, 0x00, 0x00, 0x3c, 0x01
	.byte 0xe2, 0x04, 0xe2, 0x04, 0xe2, 0x04, 0x00, 0x01
	.byte 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09
	.byte 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10, 0x11
	aligned_string "SONG%2d"
	aligned_string "                      "
SongNum_PtrTable:
	.long SongNum_01
	.long SongNum_02
	.long SongNum_03
	.long SongNum_04
	.long SongNum_05
	.long SongNum_06
	.long SongNum_07
	.long SongNum_08
	.long SongNum_09
	.long SongNum_10
	.long SongNum_11
	.long SongNum_12
	.long SongNum_13
	.long SongNum_14
	.long SongNum_15
	.long SongNum_16
SongNum_16:	aligned_string " 16 "
SongNum_15:	aligned_string " 15 "
SongNum_14:	aligned_string " 14 "
SongNum_13:	aligned_string " 13 "
SongNum_12:	aligned_string " 12 "
SongNum_11:	aligned_string " 11 "
SongNum_10:	aligned_string " 10 "
SongNum_09:	aligned_string "  9 "
SongNum_08:	aligned_string "  8 "
SongNum_07:	aligned_string "  7 "
SongNum_06:	aligned_string "  6 "
SongNum_05:	aligned_string "  5 "
SongNum_04:	aligned_string "  4 "
SongNum_03:	aligned_string "  3 "
SongNum_02:	aligned_string "  2 "
SongNum_01:	aligned_string "  1 "
	.byte 0x1e, 0x00, 0x1e, 0x00, 0x29, 0x00, 0x29, 0x00
	.byte 0x29, 0x00, 0x22, 0x00, 0x29, 0x00, 0x2d, 0x00
	.byte 0x1e, 0x00, 0x00, 0x00, 0x54, 0x66, 0xe2, 0x00
SongName_PtrTable:
	.long SongName_02
	.long SongName_03
	.long SongName_04
	.long SongName_05
	.long SongName_06
	.long SongName_07
	.long SongName_08
	.long SongName_09
	.long SongName_10
	.long SongName_All
SongName_All:	aligned_string "  ALL   "
SongName_10:	aligned_string " SONG10 "
SongName_09:	aligned_string " SONG 9 "
SongName_08:	aligned_string " SONG 8 "
SongName_07:	aligned_string " SONG 7 "
SongName_06:	aligned_string " SONG 6 "
SongName_05:	aligned_string " SONG 5 "
SongName_04:	aligned_string " SONG 4 "
SongName_03:	aligned_string " SONG 3 "
SongName_02:	aligned_string " SONG 2 "
SongName_01:	aligned_string " SONG 1 "
	.byte 0x1e, 0x00
	.byte 0x1e, 0x00, 0x29, 0x00, 0x29, 0x00, 0x29, 0x00
	.byte 0x22, 0x00, 0x29, 0x00, 0x2d, 0x00, 0x1e, 0x00
	.byte 0x00, 0x00
	.long ToggleStr_OFF
	.long ToggleStr_ON
ToggleStr_ON:	aligned_string " ON  "
ToggleStr_OFF:	aligned_string " OFF "
	.byte 0x01, 0x00
	.byte 0x02, 0x00, 0x04, 0x00, 0x08, 0x00, 0x10, 0x00
	.byte 0x20, 0x00, 0x40, 0x00, 0x80, 0x00, 0x00, 0x01
	.byte 0x00, 0x02, 0x00, 0x04, 0x00, 0x08, 0x00, 0x10
	.byte 0x00, 0x20, 0x00, 0x40, 0x00, 0x80
MidiCh_PtrTable:
	.long MidiCh_01
	.long MidiCh_02
	.long MidiCh_03
	.long MidiCh_04
	.long MidiCh_05
	.long MidiCh_06
	.long MidiCh_07
	.long MidiCh_08
	.long MidiCh_09
	.long MidiCh_10
	.long MidiCh_11
	.long MidiCh_12
	.long MidiCh_13
	.long MidiCh_14
	.long MidiCh_15
	.long MidiCh_16
MidiCh_16:	aligned_string " CH16 "
MidiCh_15:	aligned_string " CH15 "
MidiCh_14:	aligned_string " CH14 "
MidiCh_13:	aligned_string " CH13 "
MidiCh_12:	aligned_string " CH12 "
MidiCh_11:	aligned_string " CH11 "
MidiCh_10:	aligned_string " CH10 "
MidiCh_09:	aligned_string " CH 9 "
MidiCh_08:	aligned_string " CH 8 "
MidiCh_07:	aligned_string " CH 7 "
MidiCh_06:	aligned_string " CH 6 "
MidiCh_05:	aligned_string " CH 5 "
MidiCh_04:	aligned_string " CH 4 "
MidiCh_03:	aligned_string " CH 3 "
MidiCh_02:	aligned_string " CH 2 "
MidiCh_01:	aligned_string " CH 1 "
	.byte 0x1e, 0x00
	.byte 0x1e, 0x00, 0x52, 0x00, 0x52, 0x00, 0x52, 0x00
	.byte 0x22, 0x00, 0x52, 0x00, 0x29, 0x00, 0x1e, 0x00
	.byte 0x00, 0x00
	aligned_string "( MEDLEY )"
	aligned_string "          "
MedleyDisp_Blank:	aligned_string "          "
	aligned_string "( MEDLEY )"
	.byte 0x20, 0x00, 0x24, 0x00, 0x3d, 0x00
	.byte 0x3d, 0x00, 0x3d, 0x00, 0x28, 0x00, 0x2f, 0x00
	.byte 0x36, 0x00, 0x24, 0x00, 0x00, 0x00
PlayModeStr_Play:	aligned_string "    "
	.byte 0x50, 0x4c, 0x41, 0x59
	.byte 0x00, 0xff, 0x20, 0x00, 0x24, 0x00, 0x3d, 0x00
	.byte 0x3d, 0x00, 0x3d, 0x00, 0x28, 0x00, 0x2f, 0x00
	.byte 0x36, 0x00, 0x24, 0x00, 0x00, 0x00
PlayModeStr_Pause:	.asciz "     "
	.byte 0x50, 0x41, 0x55, 0x53
	.byte 0x45, 0x00, 0x20, 0x00, 0x24, 0x00, 0x3d, 0x00
	.byte 0x3d, 0x00, 0x3d, 0x00, 0x28, 0x00, 0x2f, 0x00
	.byte 0x36, 0x00, 0x24, 0x00, 0x00, 0x00, 0x45, 0x78
	.byte 0x4d, 0x44, 0x00, 0xff, 0x4e, 0x34, 0xf3, 0x00
	.byte 0xb0, 0x3f, 0xf3, 0x00, 0x73, 0x10, 0xf3, 0x00
	.byte 0x55, 0x22, 0xf3, 0x00, 0x4f, 0x15, 0xf3, 0x00
	.byte 0x3f, 0x09, 0xf3, 0x00, 0x6f, 0x0a, 0xf3, 0x00
	.byte 0x97, 0x1e, 0xf3, 0x00, 0x37, 0x31, 0xf3, 0x00
	.byte 0x48, 0x00, 0xf3, 0x00, 0xab, 0xfd, 0xf2, 0x00
	.byte 0x48, 0xfd, 0xf2, 0x00, 0x74, 0xf0, 0xf2, 0x00
	.byte 0xe4, 0x45, 0xf3, 0x00, 0xfa, 0xef, 0xf2, 0x00
	.byte 0xf1, 0xec, 0xf2, 0x00, 0x76, 0xeb, 0xf2, 0x00
	.byte 0xa4, 0xe8, 0xf2, 0x00, 0xd7, 0x09, 0xf3, 0x00
	.byte 0x7e, 0xe9, 0xf2, 0x00, 0x1d, 0xea, 0xf2, 0x00
	.byte 0xd8, 0xea, 0xf2, 0x00, 0xff, 0xeb, 0xf2, 0x00
	.byte 0x74, 0xec, 0xf2, 0x00, 0x32, 0xe5, 0xf2, 0x00
	.byte 0x90, 0xe4, 0xf2, 0x00, 0x27, 0x55, 0xf3, 0x00
	.byte 0x0d, 0x58, 0xf3, 0x00, 0xd3, 0x49, 0xf3, 0x00
	.byte 0xcb, 0x59, 0xf3, 0x00, 0x99, 0x5c, 0xf3, 0x00
	.byte 0xb2, 0x5c, 0xf3, 0x00, 0x55, 0x46, 0xf3, 0x00
	.byte 0x26, 0x03, 0xf3, 0x00, 0x09, 0xff, 0xf2, 0x00
	.byte 0x94, 0xff, 0xf2, 0x00, 0x17, 0x00, 0xf3, 0x00
	.byte 0xdf, 0x5c, 0xf3, 0x00, 0x5a, 0xfa, 0xf2, 0x00
	.byte 0x0c, 0x5d, 0xf3, 0x00, 0x4c, 0x5d, 0xf3, 0x00
	.byte 0x8f, 0x5d, 0xf3, 0x00, 0x62, 0x5d, 0xf3, 0x00
	.byte 0xe9, 0x5d, 0xf3, 0x00, 0xbc, 0x5d, 0xf3, 0x00
	.byte 0x33, 0x5d, 0xf3, 0x00, 0x1d, 0xef, 0xf2, 0x00
	.byte 0x2e, 0xef, 0xf2, 0x00, 0x3f, 0xef, 0xf2, 0x00
	.byte 0x50, 0xef, 0xf2, 0x00, 0x61, 0xef, 0xf2, 0x00
	.byte 0x72, 0xef, 0xf2, 0x00, 0x83, 0xef, 0xf2, 0x00
	.byte 0x94, 0xef, 0xf2, 0x00, 0xa5, 0xef, 0xf2, 0x00
	.byte 0xb6, 0xef, 0xf2, 0x00, 0xc7, 0xef, 0xf2, 0x00
	.byte 0xd8, 0xef, 0xf2, 0x00, 0xe0, 0xee, 0xf2, 0x00
	.byte 0x2e, 0xe9, 0xf2, 0x00, 0x29, 0xe7, 0xf2, 0x00
	.byte 0x69, 0xe6, 0xf2, 0x00, 0x91, 0xe6, 0xf2, 0x00
	.byte 0xbe, 0xe6, 0xf2, 0x00, 0xeb, 0xe6, 0xf2, 0x00
	.byte 0x18, 0xe7, 0xf2, 0x00, 0x8b, 0xe8, 0xf2, 0x00
	.byte 0xda, 0xe7, 0xf2, 0x00, 0xe9, 0xef, 0xf2, 0x00
	.byte 0xaf, 0xe7, 0xf2, 0x00, 0xdf, 0x59, 0xf3, 0x00
	.byte 0x50, 0xe6, 0xf2, 0x00, 0x6c, 0xe4, 0xf2, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0xc0, 0x6e, 0xe2, 0x00
FuncDesc_PtrTable:
	.long EqualizerBoxProc_Name
	.long SqedtValProc_Name
	.long SqedtVal2Proc_Name
	.long SqedtFixProc_Name
	.long IvSongCopyExitProc_Name
	.long SqplyValProc_Name
	.long SqedtVal3Proc_Name
	.long AccIllProc_Name
	.long AcEntertainerGridBoxProc_Name
	.long SngSelProc_Name
	.long SngSel2Proc_Name
	.long NoteEditBoxProc_Name
	.long EqOnOffFuncToggleProc_Name
	.long MsgToTtlProc_Name
	.long AcIndexWideToggleProc_Name
	.long IvPlayExitProc_Name
	.long HelpTtlProc_Name
	.long IvPnlWrExitProc_Name
	.long IvSdrevProc_Name
	.long IvSddspProc_Name
	.long IvSdaccProc_Name
	.long IvPunchExitProc_Name
	.long IvAutoPunchExitProc_Name
	.long AcPanicEditSwProc_Name
	.long IvRealRecExitProc_Name
	.long DspItem0CngFunc_Name
	.long EqualizerCngFunc_Name
	.long SqedtFunc_Name
	.long MainExeFunc_Name
	.long CycleOnOffFunc_Name
	.long MetroOnOffFunc_Name
	.long SqplyFunc_Name
	.long EntertainerGridCheck_Name
	.long SngSelFunc_Name
	.long PlySngSelFunc_Name
	.long PlySngSel2Func_Name
	.long PunchInOutFunc_Name
	.long NoteEditFunc_Name
	.long EqInOutFunc_Name
	.long TrkMixerIntTtlFunc_Name
	.long BitmapNtedt0d_Name
	.long BitmapNtedt0k_Name
	.long BitmapDredt0d_Name
	.long BitmapDredt0k_Name
	.long MimeOnOffFunc_Name
	.long AttAreYouSureCheck_Name
	.long AttAttentionCheck_Name
	.long StsSeqMenu1Check_Name
	.long StsSeqMenu2Check_Name
	.long StsEasyRec1Check_Name
	.long StsEasyRec2Check_Name
	.long StsPnlWrtCheck_Name
	.long StsTrkClr1Check_Name
	.long StsTrkClr2Check_Name
	.long StsNtDrEditCheck_Name
	.long AttTrkClrCheck_Name
	.long AttSongClrCheck_Name
	.long AcIndexWideToggleFunc_Name
	.long HelpTtlFunc_Name
	.long HelpLangChkFunc_Name
	.long HelpStsCheck_Name
	.long HelpStsP2Check_Name
	.long HelpStsP3Check_Name
	.long HelpStsP4Check_Name
	.long HelpMenuCheck_Name
	.long HelpOkSwFunc_Name
	.long HelpFuncChkFunc_Name
	.long StsAtPunchCheck_Name
	.long EdMenuPageFunc_Name
	.long SureJudgeFunc_Name
	.long PanicFunc_Name
	.long AutoPunchTtlRqFunc_Name
	.long AutoPunchTtlRqFunc_Pad
AutoPunchTtlRqFunc_Pad:		aligned_string ""
AutoPunchTtlRqFunc_Name:	aligned_string "AutoPunchTtlRqFunc"
PanicFunc_Name:			aligned_string "PanicFunc"
SureJudgeFunc_Name:		aligned_string "SureJudgeFunc"
EdMenuPageFunc_Name:		aligned_string "EdMenuPageFunc"
StsAtPunchCheck_Name:		aligned_string "StsAtPunchCheck"
HelpFuncChkFunc_Name:		aligned_string "HelpFuncChkFunc"
HelpOkSwFunc_Name:		aligned_string "HelpOkSwFunc"
HelpMenuCheck_Name:		aligned_string "HelpMenuCheck"
HelpStsP4Check_Name:		aligned_string "HelpStsP4Check"
HelpStsP3Check_Name:		aligned_string "HelpStsP3Check"
HelpStsP2Check_Name:		aligned_string "HelpStsP2Check"
HelpStsCheck_Name:		aligned_string "HelpStsCheck"
HelpLangChkFunc_Name:		aligned_string "HelpLangChkFunc"
HelpTtlFunc_Name:		aligned_string "HelpTtlFunc"
AcIndexWideToggleFunc_Name:	aligned_string "AcIndexWideToggleFunc"
AttSongClrCheck_Name:		aligned_string "AttSongClrCheck"
AttTrkClrCheck_Name:		aligned_string "AttTrkClrCheck"
StsNtDrEditCheck_Name:		aligned_string "StsNtDrEditCheck"
StsTrkClr2Check_Name:		aligned_string "StsTrkClr2Check"
StsTrkClr1Check_Name:		aligned_string "StsTrkClr1Check"
StsPnlWrtCheck_Name:		aligned_string "StsPnlWrtCheck"
StsEasyRec2Check_Name:		aligned_string "StsEasyRec2Check"
StsEasyRec1Check_Name:		aligned_string "StsEasyRec1Check"
StsSeqMenu2Check_Name:		aligned_string "StsSeqMenu2Check"
StsSeqMenu1Check_Name:		aligned_string "StsSeqMenu1Check"
AttAttentionCheck_Name:		aligned_string "AttAttentionCheck"
AttAreYouSureCheck_Name:	aligned_string "AttAreYouSureCheck"
MimeOnOffFunc_Name:		aligned_string "MimeOnOffFunc"
BitmapDredt0k_Name:		aligned_string "BitmapDredt0k"
BitmapDredt0d_Name:		aligned_string "BitmapDredt0d"
BitmapNtedt0k_Name:		aligned_string "BitmapNtedt0k"
BitmapNtedt0d_Name:		aligned_string "BitmapNtedt0d"
TrkMixerIntTtlFunc_Name:	aligned_string "TrkMixerIntTtlFunc"
EqInOutFunc_Name:		aligned_string "EqInOutFunc"
NoteEditFunc_Name:		aligned_string "NoteEditFunc"
PunchInOutFunc_Name:		aligned_string "PunchInOutFunc"
PlySngSel2Func_Name:		aligned_string "PlySngSel2Func"
PlySngSelFunc_Name:		aligned_string "PlySngSelFunc"
SngSelFunc_Name:		aligned_string "SngSelFunc"
EntertainerGridCheck_Name:	aligned_string "EntertainerGridCheck"
SqplyFunc_Name:			aligned_string "SqplyFunc"
MetroOnOffFunc_Name:		aligned_string "MetroOnOffFunc"
CycleOnOffFunc_Name:		aligned_string "CycleOnOffFunc"
MainExeFunc_Name:		aligned_string "MainExeFunc"
SqedtFunc_Name:			aligned_string "SqedtFunc"
EqualizerCngFunc_Name:		aligned_string "EqualizerCngFunc"
DspItem0CngFunc_Name:		aligned_string "DspItem0CngFunc"
IvRealRecExitProc_Name:		aligned_string "IvRealRecExitProc"
AcPanicEditSwProc_Name:		aligned_string "AcPanicEditSwProc"
IvAutoPunchExitProc_Name:	aligned_string "IvAutoPunchExitProc"
IvPunchExitProc_Name:		aligned_string "IvPunchExitProc"
IvSdaccProc_Name:		aligned_string "IvSdaccProc"
IvSddspProc_Name:		aligned_string "IvSddspProc"
IvSdrevProc_Name:		aligned_string "IvSdrevProc"
IvPnlWrExitProc_Name:		aligned_string "IvPnlWrExitProc"
HelpTtlProc_Name:		aligned_string "HelpTtlProc"
IvPlayExitProc_Name:		aligned_string "IvPlayExitProc"
AcIndexWideToggleProc_Name:	aligned_string "AcIndexWideToggleProc"
MsgToTtlProc_Name:		aligned_string "MsgToTtlProc"
EqOnOffFuncToggleProc_Name:	aligned_string "EqOnOffFuncToggleProc"
NoteEditBoxProc_Name:		aligned_string "NoteEditBoxProc"
SngSel2Proc_Name:		aligned_string "SngSel2Proc"
SngSelProc_Name:		aligned_string "SngSelProc"
AcEntertainerGridBoxProc_Name:	aligned_string "AcEntertainerGridBoxProc"
AccIllProc_Name:		aligned_string "AccIllProc"
SqedtVal3Proc_Name:		aligned_string "SqedtVal3Proc"
SqplyValProc_Name:		aligned_string "SqplyValProc"
IvSongCopyExitProc_Name:	aligned_string "IvSongCopyExitProc"
SqedtFixProc_Name:		aligned_string "SqedtFixProc"
SqedtVal2Proc_Name:		aligned_string "SqedtVal2Proc"
SqedtValProc_Name:		aligned_string "SqedtValProc"
EqualizerBoxProc_Name:		aligned_string "EqualizerBoxProc"
EffectBoxProc_Name:		aligned_string "EffectBoxProc"


NakaDesc_FuncData2TtlNo:
	.long NakaFld_Func_A
	.long NakaFld_Data
	.long NakaFld_Data2
	.long NakaFld_TtlNo_A
	.long NakaFld_FuncData2TtlNo_Pad
NakaFld_FuncData2TtlNo_Pad:	aligned_string ""
NakaFld_TtlNo_A:		aligned_string "ttl_no"
NakaFld_Data2:			aligned_string "data2"
NakaFld_Data:			aligned_string "data"
NakaFld_Func_A:			aligned_string "func"
NakaDesc_FuncTtlNo:
	.long NakaFld_Func_B
	.long NakaFld_TtlNo_B
	.long NakaFld_FuncTtlNo_Pad
NakaFld_FuncTtlNo_Pad:	aligned_string ""
NakaFld_TtlNo_B:	aligned_string "ttl_no"
NakaFld_Func_B:		aligned_string "func"
NakaDesc_ColorFontFuncTtlNo:
	.long NakaFld_Color_A
	.long NakaFld_Fontcolor_A
	.long NakaFld_Func_C
	.long NakaFld_TtlNo_C
	.long NakaFld_ColorFontFuncTtlNo_Pad
NakaFld_ColorFontFuncTtlNo_Pad:	aligned_string ""
NakaFld_TtlNo_C:		aligned_string "ttl_no"
NakaFld_Func_C:			aligned_string "func"
NakaFld_Fontcolor_A:		aligned_string "fontcolor"
NakaFld_Color_A:		aligned_string "color"


NakaDesc_ColorFontFunc:
	.long NakaFld_Color_B
	.long NakaFld_Fontcolor_B
	.long NakaFld_Func_D
	.long NakaFld_ColorFontFunc_Pad
NakaFld_ColorFontFunc_Pad:	aligned_string ""
NakaFld_Func_D:			aligned_string "func"
NakaFld_Fontcolor_B:		aligned_string "fontcolor"
NakaFld_Color_B:		aligned_string "color"


NakaDesc_ColorFontBorder:
	.long NakaFld_Color_C
	.long NakaFld_Fontcolor_C
	.long NakaFld_Border
	.long NakaFld_ColorFontBorder_Pad
NakaFld_ColorFontBorder_Pad:	aligned_string ""
NakaFld_Border:			aligned_string "border"
NakaFld_Fontcolor_C:		aligned_string "fontcolor"
NakaFld_Color_C:		aligned_string "color"
NakaDesc_Empty_A:
	.long NakaFld_Empty_A
NakaFld_Empty_A:	aligned_string ""
NakaDesc_ColorFontFuncTtlNo_B:
	.long NakaFld_Color_D
	.long NakaFld_Fontcolor_D
	.long NakaFld_Func_E
	.long NakaFld_TtlNo_D
	.long NakaFld_ColorFontFuncTtlNo_B_Pad
NakaFld_ColorFontFuncTtlNo_B_Pad:	aligned_string ""
NakaFld_TtlNo_D:			aligned_string "ttl_no"
NakaFld_Func_E:				aligned_string "func"
NakaFld_Fontcolor_D:			aligned_string "fontcolor"
NakaFld_Color_D:			aligned_string "color"


NakaDesc_ColorFontFunc_B:
	.long NakaFld_Color_E
	.long NakaFld_Fontcolor_E
	.long NakaFld_Func_F
	.long NakaFld_ColorFontFunc_B_Pad
NakaFld_ColorFontFunc_B_Pad:	aligned_string ""
NakaFld_Func_F:			aligned_string "func"
NakaFld_Fontcolor_E:		aligned_string "fontcolor"
NakaFld_Color_E:		aligned_string "color"


NakaDesc_ColorFontFuncTtlNo_C:
	.long NakaFld_Color_F
	.long NakaFld_Fontcolor_F
	.long NakaFld_Func_G
	.long NakaFld_TtlNo_E
	.long NakaFld_ColorFontFuncTtlNo_C_Pad
NakaFld_ColorFontFuncTtlNo_C_Pad:	aligned_string ""
NakaFld_TtlNo_E:			aligned_string "ttl_no"
NakaFld_Func_G:				aligned_string "func"
NakaFld_Fontcolor_F:			aligned_string "fontcolor"
NakaFld_Color_F:			aligned_string "color"


NakaDesc_FixedColRow:
	.long NakaFld_Fixedcol
	.long NakaFld_Fixedrow
	.long NakaFld_Func_H
	.long NakaFld_FixedColRow_Pad
NakaFld_FixedColRow_Pad:	aligned_string ""
NakaFld_Func_H:			aligned_string "func"
NakaFld_Fixedrow:		aligned_string "fixedrow"
NakaFld_Fixedcol:		aligned_string "fixedcol"


NakaDesc_FontColorFuncTtlNo:
	.long NakaFld_Font_A
	.long NakaFld_Color_G
	.long NakaFld_Fontcolor_G
	.long NakaFld_Func_I
	.long NakaFld_TtlNo_F
	.long NakaFld_FontColorFuncTtlNo_Pad
NakaFld_FontColorFuncTtlNo_Pad:	aligned_string ""
NakaFld_TtlNo_F:		aligned_string "ttl_no"
NakaFld_Func_I:			aligned_string "func"
NakaFld_Fontcolor_G:		aligned_string "fontcolor"
NakaFld_Color_G:		aligned_string "color"
NakaFld_Font_A:			aligned_string "font"
NakaDesc_Empty_B:
	.long NakaFld_Empty_B
NakaFld_Empty_B:	aligned_string ""
NakaDesc_FuncTtlNo_B:
	.long NakaFld_Func_J
	.long NakaFld_TtlNo_G
	.long NakaFld_FuncTtlNo_B_Pad
NakaFld_FuncTtlNo_B_Pad:	aligned_string ""
NakaFld_TtlNo_G:		aligned_string "ttl_no"
NakaFld_Func_J:			aligned_string "func"
NakaDesc_Empty_C:
	.long NakaFld_Empty_C
NakaFld_Empty_C:	aligned_string ""
NakaDesc_Empty_D:
	.long NakaFld_Empty_D
NakaFld_Empty_D:	aligned_string ""
NakaDesc_FuncIndex:
	.long NakaFld_TabIndexFunc
	.long NakaFld_TabIndex
	.long NakaFld_Func_K
	.long NakaFld_FuncIndex_Pad
NakaFld_FuncIndex_Pad:	aligned_string ""
NakaFld_Func_K:		aligned_string "func"
NakaFld_TabIndex:
	.byte 0x74, 0x61
	jr	c, 0x00
	aligned_string "index"
NakaDesc_Mode:
	.long NakaFld_Mode
	.long NakaFld_Mode_Pad
NakaFld_Mode_Pad:	aligned_string ""
NakaFld_Mode:		aligned_string "mode"
NakaDesc_ColorFontPageFunc:
	.long NakaFld_Color_H_Data
	.long NakaFld_Fontcolor_H
	.long NakaFld_Font_B
	.long NakaFld_Page
	.long NakaFld_Func_L
	.long NakaFld_ColorFontPageFunc_Pad
NakaFld_ColorFontPageFunc_Pad:	aligned_string ""
NakaFld_Func_L:			aligned_string "func"
NakaFld_Page:			aligned_string "page"
NakaFld_Font_B:			aligned_string "font"
NakaFld_Fontcolor_H:		aligned_string "fontcolor"
NakaFld_Color_H_Data:
	jr	ule, 0x6f
	.byte 0x6c, 0x6f, 0x72, 0x00, 0x40, 0x71, 0xe2, 0x00
	.byte 0x00, 0xff
NakaDesc_Empty_E:
	.long NakaFld_Empty_E
NakaFld_Empty_E:	aligned_string ""
NakaDesc_Empty_F:
	.long NakaFld_Empty_F
NakaFld_Empty_F:	aligned_string ""
NakaDesc_Empty_G:
	.long NakaFld_Empty_G
NakaFld_Empty_G:	aligned_string ""
NakaDesc_Empty_H:
	.long NakaFld_Empty_H
NakaFld_Empty_H:	aligned_string ""
NakaDesc_Empty_I:
	.long NakaFld_Empty_I
NakaFld_Empty_I:	aligned_string ""
NakaDesc_StyleFunc:
	.long NakaFld_Style
	.long NakaFld_Func_M
	.long NakaFld_StyleFunc_Pad
NakaFld_StyleFunc_Pad:	aligned_string ""
NakaFld_Func_M:		aligned_string "func"
NakaFld_Style:		aligned_string "style"
NakaDesc_Empty_J:
	.long NakaFld_Empty_J
NakaFld_Empty_J:	aligned_string ""
	.byte 0x4e, 0x34, 0xf3, 0x00


	naka_header NAKA_TYPE_0x11
	.byte 0x26, 0x00, 0x0a, 0x00, 0x8c, 0x75, 0xe2, 0x00
	.long NakaInst_EqualizerBox
	.long NakaDesc_FuncData2TtlNo
	.byte 0xb0, 0x3f, 0xf3, 0x00


	naka_header NAKA_TYPE_0x11
	.byte 0x22, 0x00, 0x06, 0x00, 0x78, 0x75, 0xe2, 0x00
	.long NakaInst_SqedtVal_B
	.long NakaDesc_FuncTtlNo
	.byte 0x73, 0x10, 0xf3, 0x00


	naka_header NAKA_TYPE_0x10
	.byte 0x20, 0x00, 0x0a, 0x00, 0x6a, 0x75, 0xe2, 0x00
	.long NakaInst_SqedtVal
	.long NakaDesc_ColorFontFuncTtlNo
	.byte 0x55, 0x22, 0xf3, 0x00


	naka_header NAKA_TYPE_0x10
	.byte 0x1e, 0x00, 0x08, 0x00, 0x5a, 0x75, 0xe2, 0x00
	.long NakaInst_SqedtVal2_End
	.long NakaDesc_ColorFontFunc
	.byte 0x4f, 0x15, 0xf3, 0x00


	naka_header NAKA_TYPE_0x10
	.byte 0x1c, 0x00, 0x06, 0x00, 0x4c, 0x75, 0xe2, 0x00
	.long NakaInst_SqedtFix
	.long NakaDesc_ColorFontBorder
	.byte 0x3f, 0x09, 0xf3, 0x00


	naka_header NAKA_TYPE_0x47
	.byte 0x16, 0x00, 0x00, 0x00, 0x38, 0x75, 0xe2, 0x00
	.long NakaInst_IvSongCopyExit
	.long NakaDesc_Empty_A
	.byte 0x6f, 0x0a, 0xf3, 0x00


	naka_header NAKA_TYPE_0x10
	.byte 0x20, 0x00, 0x0a, 0x00, 0x2c, 0x75, 0xe2, 0x00
	.long NakaInst_SqplyVal
	.long NakaDesc_ColorFontFuncTtlNo_B
	.byte 0x97, 0x1e, 0xf3, 0x00


	naka_header NAKA_TYPE_0x10
	.byte 0x1e, 0x00, 0x08, 0x00, 0x1c, 0x75, 0xe2, 0x00
	.long NakaInst_SqedtVal3
	.long NakaDesc_ColorFontFunc_B
	.byte 0x37, 0x31, 0xf3, 0x00


	naka_header NAKA_TYPE_0x10
	.byte 0x20, 0x00, 0x0a, 0x00, 0x10, 0x75, 0xe2, 0x00
	.long NakaInst_AccIll
	.long NakaDesc_ColorFontFuncTtlNo_C
	.byte 0x48, 0x00, 0xf3, 0x00


	naka_header NAKA_TYPE_0x54
	.byte 0x4a, 0x00, 0x0c, 0x00, 0xf4, 0x74, 0xe2, 0x00
	.long NakaInst_AcEntertainerGridBox
	.long NakaDesc_FixedColRow
	.byte 0xab, 0xfd, 0xf2, 0x00


	naka_header NAKA_TYPE_0x10
	.byte 0x24, 0x00, 0x0e, 0x00, 0xe8, 0x74, 0xe2, 0x00
	.long NakaInst_SngSel
	.long NakaDesc_FontColorFuncTtlNo
	.byte 0x48, 0xfd, 0xf2, 0x00


	naka_header NAKA_TYPE_0x10
	.byte 0x16, 0x00, 0x00, 0x00, 0xda, 0x74, 0xe2, 0x00
	.long NakaInst_SngSel2
	.long NakaDesc_Empty_B
	.byte 0x74, 0xf0, 0xf2, 0x00
