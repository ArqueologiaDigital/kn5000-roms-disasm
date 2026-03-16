; =============================================================================
; NAKA Debug Proc Name Table
; DbgStr_NakaProcName_Table and all DbgStr_* aligned strings
; Debug name lookup for NAKA widget proc handlers
; Extracted from kn5000_v10_program.s
; =============================================================================

DbgStr_NakaProcName_Table:
	.long DbgStr_AfterLangCheck
	.long DbgStr_TrAsPreLangCheck
	.long DbgStr_AtentionLangCheck
	.long DbgStr_AreYouSureLangCheck
	.long DbgStr_GmOnSureLangCheck
	.long DbgStr_GmOffSureLangCheck
	.long DbgStr_TrAsSureLangCheck
	.long DbgStr_SqTrAsPsSongFunc
	.long DbgStr_DemoSongSelFunc
	.long DbgStr_SmfMuteChSelFunc
	.long DbgStr_SqAftSetFunc
	.long DbgStr_MuteChSetFunc
	.long DbgStr_SMFMuteOnOffFunc
	.long DbgStr_Rt1MuteFunc
	.long DbgStr_Rt2MuteFunc
	.long DbgStr_DocOrchMuteFunc
	.long DbgStr_PdOrchMuteFunc
	.long DbgStr_SeqNamingCheck
	.long DbgStr_SeqNameOKFunc
	.long DbgStr_TrAsGridCheck
	.long DbgStr_DemoMedDspCheck
	.long DbgStr_DPPlayDspCheck
	.long DbgStr_DPPauseDspCheck
	.long DbgStr_MeasureBoxProc
	.long DbgStr_MeasureBoxFunc
	.long DbgStr_AcDiskFileNameBoxProc
	.long DbgStr_AcSmfFileNameBoxProc
	.long DbgStr_AcDocFileNoBoxProc
	.long DbgStr_AcPDFileNoBoxProc
	.long DbgStr_AcSmfSongNameBoxProc
	.long DbgStr_AcDocSongNameBoxProc
	.long DbgStr_AcPDSongNameBoxProc
	.long DbgStr_IvNamingExitProc
	.long DbgStr_AcModeSelBoxProc
	.long DbgStr_AcCurrentSongBoxProc
	.long DbgStr_AcCurSongNameBoxProc
	.long DbgStr_AcDemoSongBoxProc
	.long DbgStr_AcTrAsGridBoxProc
	.long DbgStr_AcMuteToggleBoxProc
	.long DbgStr_LyricsBoxProc
	.long DbgStr_LyricsBoxFuncProc
	.long DbgStr_SongNameBoxProc
	.long DbgStr_ComporserNameBoxProc
	.long DbgStr_AcDemoMedleyDispBoxProc
	.long DbgStr_IvExitModeTrSelProc
	.long DbgStr_EmptyProc
DbgStr_EmptyProc:			aligned_string ""
DbgStr_IvExitModeTrSelProc:			aligned_string "IvExitModeTrSelProc"
DbgStr_AcDemoMedleyDispBoxProc:			aligned_string "AcDemoMedleyDispBoxProc"
DbgStr_ComporserNameBoxProc:			aligned_string "ComporserNameBoxProc"
DbgStr_SongNameBoxProc:			aligned_string "SongNameBoxProc"
DbgStr_LyricsBoxFuncProc:			aligned_string "LyricsBoxFuncProc"
DbgStr_LyricsBoxProc:			aligned_string "LyricsBoxProc"
DbgStr_AcMuteToggleBoxProc:			aligned_string "AcMuteToggleBoxProc"
DbgStr_AcTrAsGridBoxProc:			aligned_string "AcTrAsGridBoxProc"
DbgStr_AcDemoSongBoxProc:			aligned_string "AcDemoSongBoxProc"
DbgStr_AcCurSongNameBoxProc:			aligned_string "AcCurSongNameBoxProc"
DbgStr_AcCurrentSongBoxProc:			aligned_string "AcCurrentSongBoxProc"
DbgStr_AcModeSelBoxProc:			aligned_string "AcModeSelBoxProc"
DbgStr_IvNamingExitProc:			aligned_string "IvNamingExitProc"
DbgStr_AcPDSongNameBoxProc:			aligned_string "AcPDSongNameBoxProc"
DbgStr_AcDocSongNameBoxProc:			aligned_string "AcDocSongNameBoxProc"
DbgStr_AcSmfSongNameBoxProc:			aligned_string "AcSmfSongNameBoxProc"
DbgStr_AcPDFileNoBoxProc:			aligned_string "AcPDFileNoBoxProc"
DbgStr_AcDocFileNoBoxProc:			aligned_string "AcDocFileNoBoxProc"
DbgStr_AcSmfFileNameBoxProc:			aligned_string "AcSmfFileNameBoxProc"
DbgStr_AcDiskFileNameBoxProc:			aligned_string "AcDiskFileNameBoxProc"
DbgStr_MeasureBoxFunc:		aligned_string "MeasureBoxFunc"
DbgStr_MeasureBoxProc:		aligned_string "MeasureBoxProc"
DbgStr_DPPauseDspCheck:		aligned_string "DPPauseDspCheck"
DbgStr_DPPlayDspCheck:		aligned_string "DPPlayDspCheck"
DbgStr_DemoMedDspCheck:		aligned_string "DemoMedDspCheck"
DbgStr_TrAsGridCheck:		aligned_string "TrAsGridCheck"
DbgStr_SeqNameOKFunc:		aligned_string "SeqNameOKFunc"
DbgStr_SeqNamingCheck:		aligned_string "SeqNamingCheck"
DbgStr_PdOrchMuteFunc:		aligned_string "PdOrchMuteFunc"
DbgStr_DocOrchMuteFunc:		aligned_string "DocOrchMuteFunc"
DbgStr_Rt2MuteFunc:		aligned_string "Rt2MuteFunc"
DbgStr_Rt1MuteFunc:		aligned_string "Rt1MuteFunc"
DbgStr_SMFMuteOnOffFunc:	aligned_string "SMFMuteOnOffFunc"
DbgStr_MuteChSetFunc:		aligned_string "MuteChSetFunc"
DbgStr_SqAftSetFunc:		aligned_string "SqAftSetFunc"
DbgStr_SmfMuteChSelFunc:	aligned_string "SmfMuteChSelFunc"
DbgStr_DemoSongSelFunc:		aligned_string "DemoSongSelFunc"
DbgStr_SqTrAsPsSongFunc:	aligned_string "SqTrAsPsSongFunc"
DbgStr_TrAsSureLangCheck:	aligned_string "TrAsSureLangCheck"
DbgStr_GmOffSureLangCheck:	aligned_string "GmOffSureLangCheck"
DbgStr_GmOnSureLangCheck:	aligned_string "GmOnSureLangCheck"
DbgStr_AreYouSureLangCheck:	aligned_string "AreYouSureLangCheck"
DbgStr_AtentionLangCheck:	aligned_string "AtentionLangCheck"
DbgStr_TrAsPreLangCheck:	aligned_string "TrAsPreLangCheck"
DbgStr_AfterLangCheck:		aligned_string "AfterLangCheck"
DbgStr_PartSelLangCheck:	aligned_string "PartSelLangCheck"
