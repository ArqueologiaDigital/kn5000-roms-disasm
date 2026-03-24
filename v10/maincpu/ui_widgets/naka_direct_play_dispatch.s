; =============================================================================
; NAKA Direct Play Dispatch Widgets
; Widget list, box names/data, event name table, and method name table
; for the direct play / medley UI system
; Extracted from kn5000_v10_program.s
; =============================================================================

	naka_header NAKA_TYPE_0x47
	ex_ff
	.byte 0x00			; padding
	.byte 0x00			; padding
	.byte 0x00			; padding
NakaWidgetList_AcModeBoxes:
	.long NakaBoxName_IvNamingExit
	.long NakaBoxData_IvNamingExit
	.long NakaPropTbl_IvNamingExit
	.long IvNamingExit_ScreenData
	naka_header NAKA_TYPE_0x11
	.byte 0x32, 0x00, 0x16, 0x00
	.long NakaBoxName_PsSongSelBoxProc
	.long NakaBoxEnc_PsSongSelBox
	.long NakaPropTbl_SelBox
	.long AcModeSelBoxProc
	naka_header NAKA_TYPE_0x15
	.byte 0x34, 0x00, 0x02, 0x00
	.long NakaBoxName_AcModeSelBox
	.long NakaBoxData_AcModeSelBox
	.long NakaPropTbl_Ram
	.long AcDemoSongBoxProc
	naka_header NAKA_TYPE_0x15
	.byte 0x36, 0x00, 0x04, 0x00
	.long NakaBoxName_AcDemoSongBox
	.long NakaBoxData_AcDemoSongBox
	.long NakaPropTbl_Func
	.long AcCurrentSongBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00, 0x00, 0x00
	.long NakaBoxName_AcCurrentSongBox
	.long NakaBoxData_AcCurrentSongBox
	.long NakaPropTbl_CurSongName
	.long AcCurSongNameBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00, 0x00, 0x00
	.long NakaBoxName_AcCurSongNameBox
	.long NakaBoxData_AcCurSongNameBox
	.long NakaPropTbl_TrAsGrid
	.long AcTrAsGridBoxProc
	naka_header NAKA_TYPE_0x54
	.byte 0x4a, 0x00, 0x0c, 0x00
	.long NakaBoxName_AcTrAsGridBox
	.long NakaBoxData_AcTrAsGridBox
	.long NakaPropTbl_Grid
	.long AcDiskFileNameBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00, 0x00, 0x00
	.long NakaBoxName_AcDiskFileNameBox
	.long NakaBoxData_AcDiskFileNameBox
	.long NakaPropTbl_SmfFileName
	.long AcSmfFileNameBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00, 0x00, 0x00
	.long NakaBoxName_AcSmfFileNameBox
	.long NakaBoxData_AcSmfFileNameBox
	.long NakaPropTbl_DocFileNo
	.long AcDocFileNoBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00, 0x00, 0x00
	.long NakaBoxName_AcDocFileNoBox
	.long NakaBoxData_AcDocFileNoBox
	.long NakaPropTbl_PdFileNo
	.long AcPDFileNoBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00, 0x00, 0x00
	.long NakaBoxName_AcPDFileNoBox
	.long NakaBoxData_AcPDFileNoBox
	.long NakaPropTbl_SmfSongName
	.long AcSmfSongNameBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00, 0x00, 0x00
	.long NakaBoxName_AcSmfSongNameBox
	.long NakaBoxData_AcSmfSongNameBox
	.long NakaPropTbl_DocSongName
	.long AcDocSongNameBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00, 0x00, 0x00
	.long NakaBoxName_AcDocSongNameBox
	.long NakaBoxData_AcDocSongNameBox
	.long NakaPropTbl_PdSongName
	.long AcPDSongNameBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00, 0x00, 0x00
	.long NakaBoxName_AcPDSongNameBox
	.long NakaBoxData_AcPDSongNameBox
	.long NakaPropTbl_MeasureBox
	.long MeasureBoxProc
	naka_header NAKA_TYPE_0x10
	.byte 0x1e, 0x00, 0x08, 0x00
	.long NakaBoxName_MeasureBox
	.long NakaBoxData_MeasureBox
	.long NakaPropTbl_MuteToggle
	.long AcMuteToggleBoxProc
	naka_header NAKA_TYPE_0x44
	.byte 0x2c, 0x00, 0x00, 0x00
	.long NakaBoxName_AcMuteToggleBox
	.long AlignedStr_AcMuteToggleBox
	.long NakaPropTbl_LyricsBox
	.long LyricsBoxProc
	naka_header NAKA_TYPE_0x11
	.byte 0x28, 0x00, 0x0c, 0x00
	.long NakaStr_LyricsBox
	.long NakaBoxData_LyricsBox
	.long NakaPropTbl_TextLabel
	.long SongNameBoxProc
	naka_header NAKA_TYPE_0x11
	.byte 0x26, 0x00, 0x0a, 0x00
	.long NakaBoxName_SongNameBox
	.long NakaBoxData_SongNameBox
	.long NakaPropTbl_TextLabel2
	.long ComporserNameBoxProc
	naka_header NAKA_TYPE_0x11
	.byte 0x26, 0x00, 0x0a, 0x00
	.long NakaBoxName_ComporserNameBox
	.long NakaBoxData_ComporserNameBox
	.long NakaDirectPlay_PropPtrTable
	.long LyricsBoxFuncProc
	naka_header NAKA_TYPE_0x27
	.byte 0x16, 0x00, 0x00, 0x00
	.long NakaBoxName_LyricsBoxFunc
	.long NakaBoxData_LyricsBoxFunc
	.long NakaPropTbl_DemoMedleyDisp
	.long AcDemoMedleyDispBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00, 0x00, 0x00
	.long NakaBoxName_AcDemoMedleyDisp
	.long NakaBoxData_AcDemoMedleyDisp
	.long NakaPropTbl_IvExitModeTrSel
	.long IvExitModeTrSelProc
	naka_header NAKA_TYPE_0x47
	.byte 0x16, 0x00, 0x00, 0x00
	.long NakaBoxName_IvExitModeTrSel
	.long NakaBoxData_IvExitModeTrSel
	.long NakaPropTbl_IvExitModeTrSelEnd
	.zero 24
NakaBoxData_IvExitModeTrSel:	aligned_string ""
NakaBoxName_IvExitModeTrSel:	aligned_string "IvExitModeTrSel"
NakaBoxData_AcDemoMedleyDisp:	aligned_string ""
NakaBoxName_AcDemoMedleyDisp:	aligned_string "AcDemoMedleyDispBox"
NakaBoxData_LyricsBoxFunc:	aligned_string ""
NakaBoxName_LyricsBoxFunc:	aligned_string "LyeicsBoxFunc"
NakaBoxData_ComporserNameBox:	aligned_string "c^dB"
NakaBoxName_ComporserNameBox:	aligned_string "ComporserNameBox"
NakaBoxData_SongNameBox:	aligned_string "c^dB"
NakaBoxName_SongNameBox:	aligned_string "SongNameBox"
NakaBoxData_LyricsBox:
	jr	ule, 0x5e
	pop xiz
	jr	pe, 66
	.byte 0x00			; padding
	aligned_string "LyricsBox"
	.byte 0x00			; padding
	.byte 0xff			; padding
NakaBoxName_AcMuteToggleBox:	aligned_string "AcMuteToggleBox"
NakaBoxData_MeasureBox:
	.byte 0x5e, 0x5e, 0x6a, 0x00
NakaBoxName_MeasureBox:		aligned_string "MeasureBox"
NakaBoxData_AcPDSongNameBox:	aligned_string ""
NakaBoxName_AcPDSongNameBox:	aligned_string "AcPDSongNameBox"
NakaBoxData_AcDocSongNameBox:	aligned_string ""
NakaBoxName_AcDocSongNameBox:	aligned_string "AcDocSongNameBox"
NakaBoxData_AcSmfSongNameBox:	aligned_string ""
NakaBoxName_AcSmfSongNameBox:	aligned_string "AcSmfSongNameBox"
NakaBoxData_AcPDFileNoBox:	aligned_string ""
NakaBoxName_AcPDFileNoBox:	aligned_string "AcPDFileNoBox"
NakaBoxData_AcDocFileNoBox:	aligned_string ""
NakaBoxName_AcDocFileNoBox:	aligned_string "AcDocFileNoBox"
NakaBoxData_AcSmfFileNameBox:	aligned_string ""
NakaBoxName_AcSmfFileNameBox:	aligned_string "AcSmfFileNameBox"
NakaBoxData_AcDiskFileNameBox:	aligned_string ""
NakaBoxName_AcDiskFileNameBox:	aligned_string "AcDiskFileNameBox"
NakaBoxData_AcTrAsGridBox:
	.byte 0x58, 0x58, 0x6a, 0x00
NakaBoxName_AcTrAsGridBox:	aligned_string "AcTrAsGridBox"
NakaBoxData_AcCurSongNameBox:	aligned_string ""
NakaBoxName_AcCurSongNameBox:	aligned_string "AcCurSongNameBox"
NakaBoxData_AcCurrentSongBox:	aligned_string ""
NakaBoxName_AcCurrentSongBox:	aligned_string "AcCurrentSongBox"
NakaBoxData_AcDemoSongBox:
	.byte 0x6a, 0x00
NakaBoxName_AcDemoSongBox:	aligned_string "AcDemoSongBox"
NakaBoxData_AcModeSelBox:
	.byte 0x43, 0x00
NakaBoxName_AcModeSelBox:	aligned_string "AcModeSelBox"
NakaBoxEnc_PsSongSelBox:	aligned_string "c^kAAnGG"
NakaBoxName_PsSongSelBoxProc:	aligned_string "PsSongSelBox"
NakaBoxData_IvNamingExit:	aligned_string ""
NakaBoxName_IvNamingExit:	aligned_string "IvNamingExit"
	.byte 0x16, 0x00
EvtName_PtrTable:
	.long EvtName_CurSongName
	.long EvtName_DiskFileName
	.long EvtName_SmfFileName
	.long EvtName_SmfSongName
	.long EvtName_DocFileName
	.long EvtName_DocSongName
	.long EvtName_DocFileNo
	.long EvtName_PdSongName
	.long EvtName_PdFileNo
	.long EvtName_AllClear
	.long EvtName_AllDraw
	.long EvtName_Renew
	.long EvtName_Reverse
	.long EvtName_ScrollUp
	.long EvtName_ComporserWrite
	.long EvtName_SongWrite
	.long EvtName_PlayStartIni
	.long EvtName_PlayRequest
	.long EvtName_GetEvent
	.long EvtName_ChangeColor
	.byte 0x00			; padding
	.byte 0x00			; padding
	.byte 0x00			; padding
	.byte 0x00			; padding
EvtName_ChangeColor:	aligned_string "EV_ChangeColor"
EvtName_GetEvent:	aligned_string "EV_GetEvent"
EvtName_PlayRequest:	aligned_string "EV_PlayRequest"
EvtName_PlayStartIni:	aligned_string "EV_PlayStartIni"
EvtName_SongWrite:	aligned_string "EV_SONGWRITE"
EvtName_ComporserWrite:	aligned_string "EV_COMPORSERWRITE"
EvtName_ScrollUp:	aligned_string "EV_SCROLLUP"
EvtName_Reverse:	aligned_string "EV_REVERSE"
EvtName_Renew:		aligned_string "EV_RENEW"
EvtName_AllDraw:	aligned_string "EV_ALLDRAW"
EvtName_AllClear:	aligned_string "EV_ALLCLEAR"
EvtName_PdFileNo:	aligned_string "EV_PDFILENO"
EvtName_PdSongName:	aligned_string "EV_PDSONGNAME"
EvtName_DocFileNo:	aligned_string "EV_DOCFILENO"
EvtName_DocSongName:	aligned_string "EV_DOCSONGNAME"
EvtName_DocFileName:	aligned_string "EV_DOCFILENAME"
EvtName_SmfSongName:	aligned_string "EV_SMFSONGNAME"
EvtName_SmfFileName:	aligned_string "EV_SMFFILENAME"
EvtName_DiskFileName:	aligned_string "EV_DISKFILENAME"
EvtName_CurSongName:	aligned_string "EV_CURSONGNAME"
	push_a
	.byte 0x00			; padding
	pop	xde
	rcf
	.byte 0xe2, 0x00
MtName_PtrTable:
	.long MtName_SongNameSet
	.long MtName_PsSongSelBoxID
	.long MtName_SetSelectedFileNum
	.long MtName_TrAsTrackInc
	.long MtName_TrAsTrackDec
	.long MtName_TrAsPartInc
	.long MtName_TrAsPartDec
	.long MtName_TrAsPageInc
	.long MtName_TrAsPageDec
	.long MtName_AmdCall
	.long MtName_DirectPlayMute
	.long MtName_TrackMidiCall
	.long MtName_GetCurSongName
	.long MtName_GetDiskFileName
	.long MtName_GetSmfFileName
	.long MtName_GetSmfSongName
	.long MtName_GetDocFileName
	.long MtName_GetDocSongName
	.long MtName_GetDocFileNo
	.long MtName_GetPDSongName
	.long MtName_GetPDFileNo
	.long MtName_GetMeasString
	.long MtName_GetToggleSw
	.long MtName_LyricsCharaReq
	.long MtName_GetLyricsSongName
	.long MtName_GetComporserName
	.byte 0x00			; padding
	.byte 0x00			; padding
	.byte 0x00			; padding
	.byte 0x00			; padding
MtName_GetComporserName:	aligned_string "MT_GetComporserName"
MtName_GetLyricsSongName:	aligned_string "MT_GetLyricsSongName"
MtName_LyricsCharaReq:		aligned_string "MT_LyricsCharaReq"
MtName_GetToggleSw:		aligned_string "MT_GetToggleSw"
MtName_GetMeasString:		aligned_string "MT_GetMeasString"
MtName_GetPDFileNo:		aligned_string "MT_GetPDFileNo"
MtName_GetPDSongName:		aligned_string "MT_GetPDSongName"
MtName_GetDocFileNo:		aligned_string "MT_GetDocFileNo"
MtName_GetDocSongName:		aligned_string "MT_GetDocSongName"
MtName_GetDocFileName:		aligned_string "MT_GetDocFileName"
MtName_GetSmfSongName:		aligned_string "MT_GetSmfSongName"
MtName_GetSmfFileName:		aligned_string "MT_GetSmfFileName"
MtName_GetDiskFileName:		aligned_string "MT_GetDiskFileName"
MtName_GetCurSongName:		aligned_string "MT_GetCurSongName"
MtName_TrackMidiCall:		aligned_string "MT_TrackMidiCall"
MtName_DirectPlayMute:		aligned_string "MT_DirectPlayMute"
MtName_AmdCall:			aligned_string "MT_AmdCall"
MtName_TrAsPageDec:		aligned_string "MT_TrAsPageDec"
MtName_TrAsPageInc:		aligned_string "MT_TrAsPageInc"
MtName_TrAsPartDec:		aligned_string "MT_TrAsPartDec"
MtName_TrAsPartInc:		aligned_string "MT_TrAsPartInc"
MtName_TrAsTrackDec:		aligned_string "MT_TrAsTrackDec"
MtName_TrAsTrackInc:		aligned_string "MT_TrAsTrackInc"
MtName_SetSelectedFileNum:	aligned_string "MT_SetSelectedFileNum"
MtName_PsSongSelBoxID:		aligned_string "MT_PsSongSelBoxID"
MtName_SongNameSet:		aligned_string "MT_SongNameSet"
	aligned_string "MT_DemoSongSel"
	jp	0xBBF900
	.byte 0xf2, 0x00, 0x00, 0x00, 0x00, 0x00, 0x7e, 0x10
	.byte 0xe2
	.byte 0x00			; padding
	.long NakaBoxData_PsSongSelBox
