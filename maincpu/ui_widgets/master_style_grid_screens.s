	naka_header NAKA_TYPE_CONTAINER
	.byte 0x2a, 0x00, 0x00, 0x00
	.long NakaInst_VariScreen
	.long NakaDesc_VariScreen
	.long NakaParam_VariScreen
	.long VariScreenProc
	naka_header NAKA_TYPE_0x33
	.byte 0x44, 0x00, 0x22, 0x00
	.long NakaInst_RVariScreen
	.long NakaDesc_RVariScreen
	.long NakaParam_RVariScreen
	.long RVariScreenProc
	naka_header NAKA_TYPE_0x33
	.byte 0x44, 0x00, 0x22, 0x00
	.long NakaInst_AcTransposeBox
	.long NakaDesc_AcTransposeBox
	.long ParamStr_Table_09
	.long AcTransposeBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00, 0x00, 0x00
	.long NakaInst_AcChordBox
	.long NakaDesc_AcChordBox
	.long NakaParam_AcChordBox
	.long AcChordBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00, 0x00, 0x00
	.long NakaInst_AcFreeSplitBox
	.long NakaDesc_AcFreeSplitBox
	.long NakaParam_AcFreeSplitBox
	.long AcFreeSplitBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00, 0x00, 0x00
	.long NakaInst_AcBkNoBox
	.long NakaDesc_AcBkNoBox
	.long NakaParam_AcBkNoBox
	.long AcBkNoBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00, 0x00, 0x00
	.long NakaInst_AcPmBkNoBox
	.long NakaDesc_AcPmBkNoBox
	.long NakaParam_AcPmBkNoBox
	.long AcPmBkNoBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00, 0x00, 0x00
	.long NakaInst_PmBankScreen
	.long NakaDesc_PmBankScreen
	.long NakaParam_PmBankScreen
	.long PmBankScreenProc
	naka_header NAKA_TYPE_0x33
	.byte 0x38, 0x00, 0x16, 0x00
	.long NakaInst_AcPmBkEditBox
	.long NakaDesc_AcPmBkEditBox
	.long ParamStr_Table_10
	.long AcPmBkEditBoxProc
	naka_header NAKA_TYPE_0x15
	.byte 0x3a, 0x00, 0x08, 0x00
	.long NakaInst_MsaModeScreen
	.long NakaDesc_MsaModeScreen
	.long ParamStr_Table_11
	.long MsaModeScreenProc
	naka_header NAKA_TYPE_0x33
	.byte 0x34, 0x00, 0x12, 0x00
	.long NakaInst_PmemModeBox
	.long NakaDesc_PmemModeBox
	.long ParamStr_Table_12
	.long PmemModeBoxProc
	naka_header NAKA_TYPE_GROUP
	.byte 0x2c, 0x00, 0x12, 0x00
	.long NakaInst_IvWindowPageControl
	.long NakaDesc_IvWindowPageControl
	.long ParamStr_Table_13
	.long IvWindowPageControlProc
	naka_header NAKA_TYPE_0x27
	.byte 0x1a, 0x00, 0x04, 0x00
	.long NakaInst_IvPmemWindowPageCtl
	.long NakaDesc_IvPmemWindowPageCtl
	.long NakaParam_IvPmemWindowPageCtl
	.long IvPmemWindowPageCtlProc
	naka_header NAKA_TYPE_0x27
	.byte 0x1a, 0x00, 0x04, 0x00
	.long NakaInst_IvMstStyleWindowPgCtl
	.long NakaDesc_IvMstStyleWindowPgCtl
	.long NakaParam_IvMstStyleWindowPgCtl
	.long IvMstStyleWindowPgCtlProc
	naka_header NAKA_TYPE_0x27
	.byte 0x1a, 0x00, 0x04, 0x00
	.long NakaInst_AcTchSensGridBox
	.long NakaDesc_AcTchSensGridBox
	.long NakaParam_AcTchSensGridBox
	.long AcTchSensGridBoxProc
	naka_header NAKA_TYPE_0x54
	.byte 0x4a, 0x00, 0x0c, 0x00
	.long NakaInst_AcFSWAssGridBox
	.long NakaDesc_AcFSWAssGridBox
	.long ParamStr_Table_14
	.long AcFSWAssGridBoxProc
	naka_header NAKA_TYPE_0x54
	.byte 0x4a, 0x00, 0x0c, 0x00
	.long NakaInst_AcPmExpFilterGridBox
	.long NakaDesc_AcPmExpFilterGridBox
	.long ParamStr_Table_15
	.long AcPmExpFilterGridBoxProc
	naka_header NAKA_TYPE_0x54
	.byte 0x4a, 0x00, 0x0c, 0x00
	.long NakaInst_AcDispTimeSetGridBox
	.long NakaDesc_AcDispTimeSetGridBox
	.long ParamStr_Table_16
	.long AcDispTimeSetGridBoxProc
	naka_header NAKA_TYPE_0x54
	.byte 0x4a, 0x00, 0x0c, 0x00
	.long NakaInst_AcMstSugAlpGridBox
	.long NakaDesc_AcMstSugAlpGridBox
	.long ParamStr_Table_17
	.long AcMstSugAlpGridBoxProc
	naka_header NAKA_TYPE_0x54
	.byte 0x66, 0x00, 0x28, 0x00
	.long NakaInst_AcMstStyleAlpGridBox
	.long NakaDesc_AcMstStyleAlpGridBox
	.long NakaParam_AcMstStyleAlpGridBox
	.long AcMstStyleAlpGridBoxProc
	naka_header NAKA_TYPE_0x54
	.byte 0x5e, 0x00, 0x20, 0x00
	.long NakaInst_AcMstStyle1GridBox
	.long NakaDesc_AcMstStyle1GridBox
	.long ParamStr_Table_18
	.long AcMstStyle1GridBoxProc
	naka_header NAKA_TYPE_0x54
	.byte 0x56, 0x00, 0x18, 0x00
	.long NakaInst_AcMstStyle1SubGridBox
	.long NakaDesc_AcMstStyle1SubGridBox
	.long NakaParam_AcMstStyle1SubGridBox
	.long AcMstStyle1SubGridBoxProc
	naka_header NAKA_TYPE_0x54
	.byte 0x56, 0x00, 0x18, 0x00
	.long NakaInst_AcMstStyle2GridBox
	.long NakaDesc_AcMstStyle2GridBox
	.long ParamStr_Table_20
	.long AcMstStyle2GridBoxProc
	naka_header NAKA_TYPE_0x54
	.byte 0x66, 0x00, 0x28, 0x00
	.long NakaInst_AcMstSong1GridBox
	.long NakaDesc_AcMstSong1GridBox
	.long ParamStr_Table_21
	.long AcMstSong1GridBoxProc
	naka_header NAKA_TYPE_0x54
	.byte 0x56, 0x00, 0x18, 0x00
	.long NakaInst_AcMstSong2GridBox
	.long NakaDesc_AcMstSong2GridBox
	.long NakaParam_AcMstSong2GridBox
	.long AcMstSong2GridBoxProc
	naka_header NAKA_TYPE_0x54
	.byte 0x66, 0x00, 0x28, 0x00
	.long NakaInst_SineWaveScreen
	.long NakaDesc_SineWaveScreen
	.long ParamStr_Table_22
	.long SineWaveScreenProc
	naka_header NAKA_TYPE_0x33
	.byte 0x34, 0x00, 0x12, 0x00
	.long NakaInst_IvPageOverWr
	.long NakaDesc_IvPageOverWr
	.long ParamStr_Table_23
	.long IvPageOverWrProc
	naka_header NAKA_TYPE_0x27
	.byte 0x1c, 0x00, 0x06, 0x00
	.long NakaInst_IvPageOverWr_ED2AA0
	.long NakaDesc_IvPageOverWr_ED2A9C
	.long ParamStr_Table_24
	.zero 24
NakaDesc_IvPageOverWr_ED2A9C:
	.byte 0x41, 0x74, 0x00, 0xff
NakaInst_IvPageOverWr_ED2AA0:	aligned_string "IvPageOverWr"
NakaDesc_IvPageOverWr:	.asciz "kc^nn"
NakaInst_IvPageOverWr:	aligned_string "SineWaveScreen"
NakaDesc_SineWaveScreen:	aligned_string "XXjnnnnnnn"
NakaInst_SineWaveScreen:	aligned_string "AcMstSong2GridBox"
NakaDesc_AcMstSong2GridBox:	aligned_string "XXjnnn"
NakaInst_AcMstSong2GridBox:	aligned_string "AcMstSong1GridBox"
NakaDesc_AcMstSong1GridBox:	aligned_string "XXjnnnnnnn"
NakaInst_AcMstSong1GridBox:	aligned_string "AcMstStyle2GridBox"
NakaDesc_AcMstStyle2GridBox:	aligned_string "XXjnnn"
NakaInst_AcMstStyle2GridBox:	aligned_string "AcMstStyle1SubGridBox"
NakaDesc_AcMstStyle1SubGridBox:	aligned_string "XXjnnn"
NakaInst_AcMstStyle1SubGridBox:	aligned_string "AcMstStyle1GridBox"
NakaDesc_AcMstStyle1GridBox:	aligned_string "XXjnnnnn"
NakaInst_AcMstStyle1GridBox:	aligned_string "AcMstStyleAlpGridBox"
NakaDesc_AcMstStyleAlpGridBox:	aligned_string "XXjnnnnnnn"
NakaInst_AcMstStyleAlpGridBox:	aligned_string "AcMstSugAlpGridBox"
NakaDesc_AcMstSugAlpGridBox:
	.byte 0x58, 0x58
