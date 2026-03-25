; =============================================================================
; NAKA Direct Play Property Tables
; NakaPropTbl/NakaPropStr entries for direct play UI widgets
; Extracted from kn5000_v10_program.s
; =============================================================================

NakaPropTbl_IvNamingExit:
	.long NakaPropStr_IvNamingExit_0
NakaPropStr_IvNamingExit_0:	aligned_string ""
NakaPropTbl_SelBox:
	.long NakaPropStr_SelBox_Font
	.long NakaPropStr_SelBox_FontColor
	.long NakaPropStr_SelBox_MainFunc
	.long NakaPropStr_SelBox_Column
	.long NakaPropStr_SelBox_Row
	.long NakaPropStr_SelBox_SelNum
	.long NakaPropStr_SelBox_Dial
	.long NakaPropStr_SelBox_AutoInc
	.long NakaPropStr_SelBox_0
NakaPropStr_SelBox_0:	aligned_string ""
NakaPropStr_SelBox_AutoInc:		aligned_string "auto_inc"
NakaPropStr_SelBox_Dial:		aligned_string "dial"
NakaPropStr_SelBox_SelNum:		aligned_string "sel_num"
NakaPropStr_SelBox_Row:
	.byte 0x72, 0x6f, 0x77, 0x00
NakaPropStr_SelBox_Column:	aligned_string "column"
NakaPropStr_SelBox_MainFunc:	aligned_string "main_func"
NakaPropStr_SelBox_FontColor:	aligned_string "fontcolor"
NakaPropStr_SelBox_Font:	aligned_string "font"
NakaPropTbl_Ram:
	.long NakaPropStr_Ram_1
	.long NakaPropStr_Ram_0
NakaPropStr_Ram_0:	aligned_string ""
NakaPropStr_Ram_1:
	.byte 0x72, 0x61, 0x6d, 0x00
NakaPropTbl_Func:
	.long NakaPropStr_Func_Func
	.long NakaPropStr_Func_0
NakaPropStr_Func_0:	aligned_string ""
NakaPropStr_Func_Func:		aligned_string "func"
NakaPropTbl_CurSongName:
	.long NakaPropStr_CurSongName_0
NakaPropStr_CurSongName_0:	aligned_string ""
NakaPropTbl_TrAsGrid:
	.long NakaPropStr_TrAsGrid_0
NakaPropStr_TrAsGrid_0:	aligned_string ""
NakaPropTbl_Grid:
	.long NakaPropStr_Grid_FixedCol
	.long NakaPropStr_Grid_FixedRow
	.long NakaPropStr_Grid_Func
	.long NakaPropStr_Grid_0
NakaPropStr_Grid_0:	aligned_string ""
NakaPropStr_Grid_Func:		aligned_string "func"
NakaPropStr_Grid_FixedRow:		aligned_string "fixedrow"
NakaPropStr_Grid_FixedCol:		aligned_string "fixedcol"
NakaPropTbl_SmfFileName:
	.long NakaPropStr_SmfFileName_0
NakaPropStr_SmfFileName_0:	aligned_string ""
NakaPropTbl_DocFileNo:
	.long NakaPropStr_DocFileNo_0
NakaPropStr_DocFileNo_0:	aligned_string ""
NakaPropTbl_PdFileNo:
	.long NakaPropStr_PdFileNo_0
NakaPropStr_PdFileNo_0:	aligned_string ""
NakaPropTbl_SmfSongName:
	.long NakaPropStr_SmfSongName_0
NakaPropStr_SmfSongName_0:	aligned_string ""
NakaPropTbl_DocSongName:
	.long NakaPropStr_DocSongName_0
NakaPropStr_DocSongName_0:	aligned_string ""
NakaPropTbl_PdSongName:
	.long NakaPropStr_PdSongName_0
NakaPropStr_PdSongName_0:	aligned_string ""
NakaPropTbl_MeasureBox:
	.long NakaPropStr_MeasureBox_0
NakaPropStr_MeasureBox_0:	aligned_string ""
NakaPropTbl_MuteToggle:
	.long NakaPropStr_MuteToggle_Color
	.long NakaPropStr_MuteToggle_FontColor
	.long NakaPropStr_MuteToggle_Func
	.long NakaPropStr_MuteToggle_0
NakaPropStr_MuteToggle_0:	aligned_string ""
NakaPropStr_MuteToggle_Func:			aligned_string "func"
NakaPropStr_MuteToggle_FontColor:			aligned_string "fontcolor"
NakaPropStr_MuteToggle_Color:			aligned_string "color"
NakaPropTbl_LyricsBox:
	.long NakaPropStr_LyricsBox_0
NakaPropStr_LyricsBox_0:	aligned_string ""
NakaPropTbl_TextLabel:
	.long NakaPropStr_TextLabel_Font
	.long NakaPropStr_TextLabel_FontColor
	.long NakaPropStr_TextLabel_ReverseColor
	.long NakaPropStr_TextLabel_Alignment
	.long NakaPropStr_TextLabel_Lines
	.long NakaPropStr_TextLabel_0
NakaPropStr_TextLabel_0:	aligned_string ""
NakaPropStr_TextLabel_Lines:			aligned_string "lines"
NakaPropStr_TextLabel_Alignment:			aligned_string "alignment"
NakaPropStr_TextLabel_ReverseColor:			aligned_string "reversecolor"
NakaPropStr_TextLabel_FontColor:			aligned_string "fontcolor"
NakaPropStr_TextLabel_Font:			aligned_string "font"


NakaPropTbl_TextLabel2:
	.long NakaPropStr_TextLabel2_Font
	.long NakaPropStr_TextLabel2_FontColor
	.long NakaPropStr_TextLabel2_Alignment
	.long NakaPropStr_TextLabel2_Lines
	.long NakaPropStr_TextLabel2_0
NakaPropStr_TextLabel2_0:	aligned_string ""
NakaPropStr_TextLabel2_Lines:			aligned_string "lines"
NakaPropStr_TextLabel2_Alignment:			aligned_string "alignment"
NakaPropStr_TextLabel2_FontColor:			aligned_string "fontcolor"
NakaPropStr_TextLabel2_Font:
	jr	z, 0x6f
	jr	nz, 116
	.byte 0x00			; padding
	.byte 0xff			; padding
	.byte 0xd4, 0x08, 0xe2
	.byte 0x00			; padding


NakaPropTbl_LyricsBoxFunc:
	.long NakaPropStr_LyricsBoxFunc_FontColor
	.long NakaPropStr_LyricsBoxFunc_Alignment
	.long NakaPropStr_LyricsBoxFunc_Lines
	.long NakaPropStr_LyricsBoxFunc_0
NakaPropStr_LyricsBoxFunc_0:	aligned_string ""
NakaPropStr_LyricsBoxFunc_Lines:			aligned_string "lines"
NakaPropStr_LyricsBoxFunc_Alignment:			aligned_string "alignment"
NakaPropStr_LyricsBoxFunc_FontColor:			aligned_string "fontcolor"
NakaPropStr_LyricsBoxFunc_Font:			aligned_string "font"
NakaPropTbl_DemoMedleyDisp:
	.long NakaPropStr_DemoMedleyDisp_0
NakaPropStr_DemoMedleyDisp_0:	aligned_string ""
NakaPropTbl_IvExitModeTrSel:
	.long NakaPropStr_IvExitModeTrSel_0
NakaPropStr_IvExitModeTrSel_0:	aligned_string ""
NakaPropTbl_IvExitModeTrSelEnd:
	.long NakaPropStr_IvExitModeTrSelEnd_0
NakaPropStr_IvExitModeTrSelEnd_0:	.byte 0x00, 0xff, 0x37, 0xbb, 0xf2, 0x00
