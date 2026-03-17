; naka_property_descriptors.s - NAKA widget property descriptor tables
;
; String property descriptors (StrDesc_*), dispatch widgets, instance
; name strings, and method table (NakaMethodTable + MT_* strings).
;
; ROM address range: 0xE169AE - 0xE176D6
;

	.ascii "     Init       "
	.zero 16

	.include "sequencer/composer_msp_defaults.s"
StrDesc_Empty_0:
	.long StrVal_Empty_0
StrVal_Empty_0:	aligned_string ""
StrDesc_RecordBits:
	.long StrVal_RecBit
	.long StrVal_SoloBit
	.long StrVal_Empty_RecordBits
StrVal_Empty_RecordBits:	aligned_string ""
StrVal_SoloBit:			aligned_string "solobit"
StrVal_RecBit:			aligned_string "recbit"
StrDesc_Empty_1:
	.long StrVal_Empty_1
StrVal_Empty_1:	aligned_string ""
StrDesc_Empty_2:
	.long StrVal_Empty_2
StrVal_Empty_2:	aligned_string ""
StrDesc_Empty_3:
	.long StrVal_Empty_3
StrVal_Empty_3:	aligned_string ""
StrDesc_Empty_4:
	.long StrVal_Empty_4
StrVal_Empty_4:	aligned_string ""
StrDesc_Empty_5:
	.long StrVal_Empty_5
StrVal_Empty_5:	aligned_string ""
StrDesc_Empty_6:
	.long StrVal_Empty_6
StrVal_Empty_6:	aligned_string ""
StrDesc_Empty_7:
	.long StrVal_Empty_7
StrVal_Empty_7:	aligned_string ""
StrDesc_Empty_8:
	.long StrVal_Empty_8
StrVal_Empty_8:	aligned_string ""
StrDesc_BankPair_0:
	.long StrFld_BankPair_0_Bank
	.long StrVal_BankPair_0_Empty
StrVal_BankPair_0_Empty:	aligned_string ""
StrFld_BankPair_0_Bank:	aligned_string "bank"
StrDesc_BankPair_1:
	.long StrFld_BankPair_1_Bank
	.long StrVal_BankPair_1_Empty
StrVal_BankPair_1_Empty:	aligned_string ""
StrFld_BankPair_1_Bank:	aligned_string "bank"
StrDesc_RamField:
	.long StrVal_RamField_Empty
StrVal_RamField_Empty:	aligned_string ""
StrDesc_RamNamePair:
	.long StrFld_RamNamePair_Ram
	.long StrVal_RamNamePair_Empty
StrVal_RamNamePair_Empty:	aligned_string ""
StrFld_RamNamePair_Ram:	aligned_string "ram"
StrDesc_ApcDataPair:
	.long StrFld_ApcDataPair_ApcData
	.long StrVal_ApcDataPair_Empty
StrVal_ApcDataPair_Empty:	aligned_string ""
StrFld_ApcDataPair_ApcData:	aligned_string "apcdata"
StrDesc_MspBnkPair_0:
	jr	f, 0x6a
	.byte 0xe1, 0x00
	.long StrVal_MspBnkPair_0_Empty
StrVal_MspBnkPair_0_Empty:	aligned_string ""
StrFld_MspBnkPair_0_MspBnk:	aligned_string "mspbnk"
StrDesc_MspBnkPair_1:
	.long StrFld_MspBnkPair_1_MspBnk
	.long StrVal_MspBnkPair_1_Empty
StrVal_MspBnkPair_1_Empty:	aligned_string ""
StrFld_MspBnkPair_1_MspBnk:	aligned_string "mspbnk"
StrDesc_Empty_9:
	.long StrVal_Empty_9
StrVal_Empty_9:	aligned_string ""
StrDesc_Empty_10:
	.long StrVal_Empty_10
StrVal_Empty_10:	aligned_string ""
StrDesc_Empty_11:
	.long StrVal_Empty_11
StrVal_Empty_11:	aligned_string ""
StrDesc_Empty_12:
	.long StrVal_Empty_12
StrVal_Empty_12:	aligned_string ""
StrDesc_Empty_13:
	.long StrVal_Empty_13
StrVal_Empty_13:	aligned_string ""
GridProperty_Config_Table:
	.long StrFld_GridConfig_FixedCol
	.long StrFld_GridConfig_FixedRow
	.long StrFld_GridConfig_Func
	.long StrVal_GridConfig_Empty
StrVal_GridConfig_Empty:	aligned_string ""
StrFld_GridConfig_Func:	aligned_string "func"
StrFld_GridConfig_FixedRow:	aligned_string "fixedrow"
StrFld_GridConfig_FixedCol:	aligned_string "fixedcol"
StrDesc_Empty_14:
	.long StrVal_Empty_14
StrVal_Empty_14:	aligned_string ""
GridProperty_AltConfig_Table:
	.long StrFld_AltGridConfig_FixedCol
	.long StrFld_AltGridConfig_FixedRow
	.long StrFld_AltGridConfig_Func
	.long StrVal_AltGridConfig_Empty
StrVal_AltGridConfig_Empty:	aligned_string ""
StrFld_AltGridConfig_Func:	aligned_string "func"
StrFld_AltGridConfig_FixedRow:	aligned_string "fixedrow"
StrFld_AltGridConfig_FixedCol:	aligned_string "fixedcol"
StrDesc_Empty_15:
	.long StrVal_Empty_15
StrVal_Empty_15:	aligned_string ""
StrDesc_Empty_16:
	.long StrVal_Empty_16
StrVal_Empty_16:	aligned_string ""
StrDesc_Empty_17:
	.long StrVal_Empty_17
StrVal_Empty_17:	aligned_string ""
StrDesc_Empty_18:
	.long StrVal_Empty_18
StrVal_Empty_18:	aligned_string ""
StrDesc_Empty_19:
	.long StrVal_Empty_19
StrVal_Empty_19:	aligned_string ""
StrDesc_CstmCpNameBox:
	.long StrFld_CstmCpName_CstmNo
	.long StrVal_Empty_CstmCpName
StrVal_Empty_CstmCpName:	aligned_string ""
StrFld_CstmCpName_CstmNo:	aligned_string "cstmno"
StrDesc_AcApcToggle:
	.long StrFld_ApcToggle_Func
	.long StrFld_ApcToggle_PmanAd
	.long StrVal_Empty_AcApcToggle
StrVal_Empty_AcApcToggle:	aligned_string ""
StrFld_ApcToggle_PmanAd:	aligned_string "pman_ad"
StrFld_ApcToggle_Func:		aligned_string "func"
StrDesc_AcSndArgGrid:
	.long StrFld_SndArgGrid_FixedCol
	.long StrFld_SndArgGrid_FixedRow
	.long StrFld_SndArgGrid_Func
	.long StrVal_Empty_AcSndArgGrid
StrVal_Empty_AcSndArgGrid:	aligned_string ""
StrFld_SndArgGrid_Func:		aligned_string "func"
StrFld_SndArgGrid_FixedRow:	aligned_string "fixedrow"
StrFld_SndArgGrid_FixedCol:	aligned_string "fixedcol"


StrDesc_PsParaListBox:
	.long StrFld_ParaList_Font
	.long StrFld_ParaList_FontColor
	.long StrFld_ParaList_Column
	.long StrFld_ParaList_Row
	.long StrFld_ParaList_SelNum
	.long StrVal_Empty_PsParaList
StrVal_Empty_PsParaList:	aligned_string ""
StrFld_ParaList_SelNum:		aligned_string "sel_num"
StrFld_ParaList_Row:
	jrl	le, 30575
	.byte 0x00			; padding
StrFld_ParaList_Column:		aligned_string "column"
StrFld_ParaList_FontColor:	aligned_string "fontcolor"
StrFld_ParaList_Font:
	jr	z, 0x6f
	jr	nz, 116
	.byte 0x00			; padding
	.byte 0xFF			; padding
	.byte 0xb0, 0x6b
	cpdm32	0, xsp
StrDesc_PsSCTxtBox2:
	.long StrVal_Empty_PsSCTxtBox2
StrVal_Empty_PsSCTxtBox2:	aligned_string ""
StrDesc_VwVariBox:
	.long StrFld_VwVari_Font
	.long StrFld_VwVari_FontColor
	.long StrFld_VwVari_Align
	.long StrFld_VwVari_EditSw
	.long StrFld_VwVari_Selected
	.long StrFld_VwVari_MspBnk
	.long StrVal_Empty_VwVariBox
StrVal_Empty_VwVariBox:		aligned_string ""
StrFld_VwVari_MspBnk:		aligned_string "mspbnk"
StrFld_VwVari_Selected:		aligned_string "selected"
StrFld_VwVari_EditSw:		aligned_string "editsw"
StrFld_VwVari_Align:		aligned_string "align"
StrFld_VwVari_FontColor:	aligned_string "fontcolor"
StrFld_VwVari_Font:		aligned_string "font"


StrDesc_YajirushiBox:
	.long StrFld_Yajirushi_Color
	.long StrFld_Yajirushi_FrameOnly
	.long StrFld_Yajirushi_Dir
	.long StrFld_Yajirushi_TailXRate
	.long StrFld_Yajirushi_TailYRate
	.long StrVal_Empty_Yajirushi
StrVal_Empty_Yajirushi:		aligned_string ""
StrFld_Yajirushi_TailYRate:	aligned_string "tail_y_rate"
StrFld_Yajirushi_TailXRate:	aligned_string "tail_x_rate"
StrFld_Yajirushi_Dir:
	.byte 0x64, 0x69, 0x72, 0x00
StrFld_Yajirushi_FrameOnly:	aligned_string "frame_only"
StrFld_Yajirushi_Color:		aligned_string "color"
StrDesc_CmpNameMenuBox:
	.long StrVal_Empty_CmpNameMenu
StrVal_Empty_CmpNameMenu:	aligned_string ""
StrDesc_S2cGridBox:
	.long StrFld_S2cGrid_FixedCol
	.long StrFld_S2cGrid_FixedRow
	.long StrFld_S2cGrid_Func
	.long StrVal_Empty_S2cGridBox
StrVal_Empty_S2cGridBox:	aligned_string ""
StrFld_S2cGrid_Func:		aligned_string "func"
StrFld_S2cGrid_FixedRow:	aligned_string "fixedrow"
StrFld_S2cGrid_FixedCol:	aligned_string "fixedcol"
StrDesc_PsStylCnvVer:
	.long StrVal_Empty_PsStylCnvVer
StrVal_Empty_PsStylCnvVer:	aligned_string ""
	.long AcMemNoBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_AcMemNoBox
	.long StrEmpty_AcMemNoBox
	.long StrDesc_Empty_0
	.long AcCmpRecBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x26, 0x00
	.byte 0x02, 0x00
	.long StrName_AcCmpRecBox
	.long StrPrefix_AcCmpRecBox
	.long StrDesc_RecordBits
	.long PsCmpQtzBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_PsCmpQtzBox
	.long StrEmpty_PsCmpQtzBox
	.long StrDesc_Empty_1
	.long PsCmpMeasBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_PsCmpMeasBox
	.long StrEmpty_PsCmpMeasBox
	.long StrDesc_Empty_2
	.long PsCmpMemBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_PsCmpMemBox
	.long StrEmpty_PsCmpMemBox
	.long StrDesc_Empty_3
	.long AcS2cMemNoBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_AcS2cMemNoBox
	.long StrEmpty_AcS2cMemNoBox
	.long StrDesc_Empty_4
	.long PsS2cFmeasBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_PsS2cFmeasBox
	.long StrEmpty_PsS2cFmeasBox
	.long StrDesc_Empty_5
	.long PsS2cLmeasBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_PsS2cLmeasBox
	.long StrEmpty_PsS2cLmeasBox
	.long StrDesc_Empty_6
	.long PsSeqSongNoBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_PsSeqSongNoBox
	.long StrEmpty_PsSeqSongNoBox
	.long StrDesc_Empty_7
	.long PsS2cTransBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_PsS2cTransBox
	.long StrEmpty_PsS2cTransBox
	.long StrDesc_Empty_8
	.long PsCstmCpBnkBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x26, 0x00
	.byte 0x02, 0x00
	.long StrName_PsCstmCpBnkBox
	.long StrPrefix_PsCstmCpBnkBox
	.long StrDesc_BankPair_0
	.long PsCstmCpSwBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x26, 0x00
	.byte 0x02, 0x00
	.long StrName_PsCstmCpSwBox
	.long StrPrefix_PsCstmCpSwBox
	.long StrDesc_BankPair_1
	.long PsCtmAttStrBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_PsCtmAttStrBox
	.long StrEmpty_PsCtmAttStrBox
	.long StrDesc_RamField
	.long AcCmpMdBoxProc
	naka_header NAKA_TYPE_0x15
	.byte 0x34, 0x00
	.byte 0x02, 0x00
	.long StrName_AcCmpMdBox
	.long StrPrefix_AcCmpMdBox
	.long StrDesc_RamNamePair
	.long AcApcMdBoxProc
	naka_header NAKA_TYPE_0x15
	.byte 0x34, 0x00
	.byte 0x02, 0x00
	.long StrName_AcApcMdBox
	.long StrPrefix_AcApcMdBox
	.long StrDesc_ApcDataPair
	.long AcMspBnkSlBoxProc
	naka_header NAKA_TYPE_0x15
	.byte 0x34, 0x00
	.byte 0x02, 0x00
	.long StrName_AcMspBnkSlBox
	.long StrPrefix_AcMspBnkSlBox
	.long StrDesc_MspBnkPair_0
	.long PsMspBnkNameBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x26, 0x00
	.byte 0x02, 0x00
	.long StrName_PsMspBnkNameBox
	.long StrPrefix_PsMspBnkNameBox
	.long StrDesc_MspBnkPair_1
	.long AcCmpTempoBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_AcCmpTempoBox
	.long StrEmpty_AcCmpTempoBox
	.long StrDesc_Empty_9
	.long PsCmpCpFGrpBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_PsCmpCpFGrpBox
	.long StrEmpty_PsCmpCpFGrpBox
	.long StrDesc_Empty_10
	.long PsCmpCpFVariBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_PsCmpCpFVariBox
	.long StrEmpty_PsCmpCpFVariBox
	.long StrDesc_Empty_11
	.long PsCmpCpFPtnBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_PsCmpCpFPtnBox
	.long StrEmpty_PsCmpCpFPtnBox
	.long StrDesc_Empty_12
	.long PsNameMemBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_PsNameMemBox
	.long StrEmpty_PsNameMemBox
	.long StrDesc_Empty_13
	.long AcCmpSetGridBoxProc
	naka_header NAKA_TYPE_0x54
	.byte 0x4a, 0x00
	.byte 0x0c, 0x00
	.long StrName_AcCmpSetGridBox
	.long StrPrefix_AcCmpSetGrid
	.long GridProperty_Config_Table
	.long PsRgpSetBnkBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_PsRgpSetBnkBox
	.long StrEmpty_PsRgpSetBnkBox
	.long StrDesc_Empty_14
	.long AcEasyCmpGridBoxProc
	naka_header NAKA_TYPE_0x54
	.byte 0x4a, 0x00
	.byte 0x0c, 0x00
	.long StrName_AcEasyCmpGridBox
	.long StrPrefix_AcEasyCmpGrid
	.long GridProperty_AltConfig_Table
	.long PsMspMeasBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_PsMspMeasBox
	.long StrEmpty_PsMspMeasBox
	.long StrDesc_Empty_15
	.long PsMspMemBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_PsMspMemBox
	.long StrEmpty_PsMspMemBox
	.long StrDesc_Empty_16
	.long PsMspRecPadBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_PsMspRecPadBox
	.long StrEmpty_PsMspRecPadBox
	.long StrDesc_Empty_17
	.long PsMspRecBnkBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_PsMspRecBnkBox
	.long StrEmpty_PsMspRecBnkBox
	.long StrDesc_Empty_18
	.long PsMspNameBnkProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_PsMspNameBnk
	.long StrEmpty_PsMspNameBnk
	.long StrDesc_Empty_19
	.long PsCstmCpNameBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x26, 0x00
	.byte 0x02, 0x00
	.long StrName_PsCstmCpNameBox
	.long NakaInst_AcApcToggle_0x0C
	.long StrDesc_CstmCpNameBox
	.long AcApcToggleProc
	naka_header NAKA_TYPE_0x26
	.byte 0x30, 0x00
	.byte 0x08, 0x00
	.long NakaInst_AcApcToggle
	.long StrPrefix_AcApcToggle
	.long StrDesc_AcApcToggle
	.long AcSndArgGridBoxProc
	naka_header NAKA_TYPE_0x54
	.byte 0x4a, 0x00
	.byte 0x0c, 0x00
	.long StrName_AcSndArgGridBox
	.long StrPrefix_AcSndArgGrid
	.long StrDesc_AcSndArgGrid
	.long PsParaListBoxProc
	naka_header NAKA_TYPE_0x11
	.byte 0x2a, 0x00
	.byte 0x0e, 0x00
	.long StrName_PsParaListBox
	.long StrExtra_ParaList_JpChars
	.long StrDesc_PsParaListBox
	.long PsSCTxtBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_PsSCTxtBox
	.long StrEmpty_PsSCTxtBox
	.long StrFld_ParaList_Font_0x06
	.long PsSCTxtBox2Proc
	naka_header NAKA_TYPE_0x65
	.byte 0x26, 0x00
	.byte 0x00, 0x00
	.long StrName_PsSCTxtBox2
	.long StrEmpty_PsSCTxtBox2
	.long StrDesc_PsSCTxtBox2
	.long VwVariBoxProc
	naka_header NAKA_TYPE_0x11
	.byte 0x2c, 0x00
	.byte 0x10, 0x00
NakaDesc_VwVariBox_DataPtrs:
	.long StrName_VwVariBox
	.long StrExtra_Yajirushi_JpChars2
	.long StrDesc_VwVariBox
	.long StylCnvStorBnk_ProcDataBlock
	naka_header NAKA_TYPE_0x10
	.byte 0x20, 0x00
	.byte 0x0a, 0x00
	.long StrName_YajirushiBox
	.long StrExtra_Yajirushi_JpChars
	.long StrDesc_YajirushiBox
	.long CmpNameMenuBoxProc
	naka_header NAKA_TYPE_0x3D
	.byte 0x32, 0x00
	.byte 0x00, 0x00
	.long StrName_CmpNameMenuBox
	.long AlignedStr_CmpNameMenuBox
	.long StrDesc_CmpNameMenuBox
	.long S2cGridBoxProc
	naka_header NAKA_TYPE_0x54
	.byte 0x4a, 0x00
	.byte 0x0c, 0x00
	.long Str_S2cGridBox
	.long StrPrefix_S2cGridBox
	.long StrDesc_S2cGridBox
	.long PsStylCnvVerProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_PsStylCnvVer
	.long StrEmpty_PsStylCnvVer
	.long StrDesc_PsStylCnvVer
	.zero 24
StrEmpty_PsStylCnvVer:	aligned_string ""
StrName_PsStylCnvVer:	aligned_string "PsStylCnvVer"
StrPrefix_S2cGridBox:
	pop xwa
	pop xwa
	jr	gt, 0x00
	aligned_string "S2cGridBox"
	.byte 0x00			; padding
	.byte 0xFF			; padding
StrName_CmpNameMenuBox:		aligned_string "CmpNameMenuBox"
StrExtra_Yajirushi_JpChars:	aligned_string "^GBBB"
StrName_YajirushiBox:		aligned_string "Yajirushi"
StrExtra_Yajirushi_JpChars2:	aligned_string "c^demC"
StrName_VwVariBox:		aligned_string "VwVariBox"
StrEmpty_PsSCTxtBox2:		aligned_string ""
StrName_PsSCTxtBox2:		aligned_string "PSSCTxtBox2"
StrEmpty_PsSCTxtBox:		aligned_string ""
StrName_PsSCTxtBox:		aligned_string "PsSCTxtBox"
StrExtra_ParaList_JpChars:	.asciz "c^AAn"
StrName_PsParaListBox:		aligned_string "PsParaListBox"
StrPrefix_AcSndArgGrid:
	pop	xwa
	pop	xwa
	jr	gt, 0
StrName_AcSndArgGridBox:	aligned_string "AcSndArgGridBox"
StrPrefix_AcApcToggle:
	jr	gt, 0x46
	.byte 0x00			; padding
	.byte 0xFF			; padding
	aligned_string "AcApcToggle"
	.byte 0x43, 0x00
StrName_PsCstmCpNameBox:	aligned_string "PsCstmCpNameBox"
StrEmpty_PsMspNameBnk:		aligned_string ""
StrName_PsMspNameBnk:		aligned_string "PsMspNameBnk"
StrEmpty_PsMspRecBnkBox:	aligned_string ""
StrName_PsMspRecBnkBox:		aligned_string "PsMspRecBnkBox"
StrEmpty_PsMspRecPadBox:	aligned_string ""
StrName_PsMspRecPadBox:		aligned_string "PsMspRecPadBox"
StrEmpty_PsMspMemBox:		aligned_string ""
StrName_PsMspMemBox:		aligned_string "PsMspMemBox"
StrEmpty_PsMspMeasBox:		aligned_string ""
StrName_PsMspMeasBox:		aligned_string "PsMspMeasBox"
StrPrefix_AcEasyCmpGrid:
	pop	xwa
	pop	xwa
	jr	gt, 0
StrName_AcEasyCmpGridBox:	aligned_string "AcEasyCmpGridBox"
StrEmpty_PsRgpSetBnkBox:	aligned_string ""
StrName_PsRgpSetBnkBox:		aligned_string "PsRgpSetBnkBox"
StrPrefix_AcCmpSetGrid:
	pop	xwa
	pop	xwa
	jr	gt, 0
StrName_AcCmpSetGridBox:	aligned_string "AcCmpSetGridBox"
StrEmpty_PsNameMemBox:		aligned_string ""
StrName_PsNameMemBox:		aligned_string "PsNameMemBox"
StrEmpty_PsCmpCpFPtnBox:	aligned_string ""
StrName_PsCmpCpFPtnBox:		aligned_string "PsCmpCpFPtnBox"
StrEmpty_PsCmpCpFVariBox:	aligned_string ""
StrName_PsCmpCpFVariBox:	aligned_string "PsCmpCpFVariBox"
StrEmpty_PsCmpCpFGrpBox:	aligned_string ""
StrName_PsCmpCpFGrpBox:		aligned_string "PsCmpCpFGrpBox"
StrEmpty_AcCmpTempoBox:		aligned_string ""
StrName_AcCmpTempoBox:		aligned_string "AcCmpTempoBox"
StrPrefix_PsMspBnkNameBox:
	.byte 0x43, 0x00
StrName_PsMspBnkNameBox:	aligned_string "PsMspBnkNameBox"
StrPrefix_AcMspBnkSlBox:
	.byte 0x43, 0x00
StrName_AcMspBnkSlBox:	aligned_string "AcMspBnkSlBox"
StrPrefix_AcApcMdBox:
	.byte 0x43, 0x00
StrName_AcApcMdBox:	aligned_string "AcApcMdBox"
StrPrefix_AcCmpMdBox:
	.byte 0x43, 0x00
StrName_AcCmpMdBox:		aligned_string "AcCmpMdBox"
StrEmpty_PsCtmAttStrBox:	aligned_string ""
StrName_PsCtmAttStrBox:		aligned_string "PsCtmAttStrBox"
StrPrefix_PsCstmCpSwBox:
	.byte 0x43, 0x00
StrName_PsCstmCpSwBox:	aligned_string "PsCstmCpSwBox"
StrPrefix_PsCstmCpBnkBox:
	.byte 0x43, 0x00
StrName_PsCstmCpBnkBox:		aligned_string "PsCstmCpBnkBox"
StrEmpty_PsS2cTransBox:		aligned_string ""
StrName_PsS2cTransBox:		aligned_string "PsS2cTransBox"
StrEmpty_PsSeqSongNoBox:	aligned_string ""
StrName_PsSeqSongNoBox:		aligned_string "PsSeqSongNoBox"
StrEmpty_PsS2cLmeasBox:		aligned_string ""
StrName_PsS2cLmeasBox:		aligned_string "PsS2cLmeasBox"
StrEmpty_PsS2cFmeasBox:		aligned_string ""
StrName_PsS2cFmeasBox:		aligned_string "PsS2cFmeasBox"
StrEmpty_AcS2cMemNoBox:		aligned_string ""
StrName_AcS2cMemNoBox:		aligned_string "AcS2cMemNoBox"
StrEmpty_PsCmpMemBox:		aligned_string ""
StrName_PsCmpMemBox:		aligned_string "PsCmpMemBox"
StrEmpty_PsCmpMeasBox:		aligned_string ""
StrName_PsCmpMeasBox:		aligned_string "PsCmpMeasBox"
StrEmpty_PsCmpQtzBox:		aligned_string ""
StrName_PsCmpQtzBox:		aligned_string "PsCmpQtzBox"
StrPrefix_AcCmpRecBox:
	.byte 0x43, 0x43, 0x00, 0xff
StrName_AcCmpRecBox:	aligned_string "AcCmpRecBox"
StrEmpty_AcMemNoBox:	aligned_string ""
StrName_AcMemNoBox:	aligned_string "AcMemNoBox"
	pushw	bc
	.byte 0x00			; padding
	.byte 0x00			; padding
	.byte 0x00			; padding
	.byte 0x00			; padding
	.byte 0x00			; padding
	.byte 0x00			; padding
	.byte 0x00			; padding
NakaMethodTable_PtrsStart:
	.long MTStr_CmpNameSet
	.long MTStr_MspNameSet
	.long MTStr_RhyGrpNmGet
	.long MTStr_RhyVariNmGet
	.long MTStr_APRHYGRPNM
	.long MTStr_APRHYVARINM
	.long MTStr_CmpClrYes
	.long MTStr_CmpClrNo
	.long MTStr_PanUp
	.long MTStr_PanDn
	.long MTStr_RLmtUp
	.long MTStr_RLmtDn
	.long MTStr_PanValGet
	.long MTStr_RLmtValGet
	.long MTStr_CmpSetP1Up
	.long MTStr_CmpSetP1Dn
	.long MTStr_S2cTrUp
	.long MTStr_S2cTrDn
	.long MTStr_RgpBnkUp
	.long MTStr_RgpBnkDn
	.long MTStr_RgpPadUp
	.long MTStr_RgpPadDn
	.long MTStr_CstmCpOk
	.long MTStr_MspUsr1NmGet
	.long MTStr_MspUsr2NmGet
	.long MTStr_MspRgp1NmGet
	.long MTStr_MspRgp2NmGet
	.long MTStr_MspUsr1NmDisp
	.long MTStr_MspUsr2NmDisp
	.long MTStr_MspRgp1NmDisp
	.long MTStr_MspRgp2NmDisp
	.long MTStr_MspPlyMdSet
	.long MTStr_ArgToneNmGet
	.long MTStr_ArgChoGet
	.long MTStr_ArgToneNmDisp
	.long MTStr_ArgChoDisp
	.long MTStr_SetPtSel
	.long MTStr_EsCmpPartUp
	.long MTStr_EsCmpPartDn
	.long MTStr_EsCmpStylUp
	.long MTStr_EsCmpStylDn
	.long MTStr_EsCmpVariUp
	.long MTStr_EsCmpVariDn
	.long MTStr_CstmFNmGet
	.long MTStr_CstmTNmGet
	.long MTStr_CstmFNmDisp
	.long MTStr_CstmTNmDisp
	.long MTStr_SetSelectedLine
	.long MTStr_StylCnvStor
	.long MTStr_ClrGridHanten
	.byte 0x00			; padding
	.byte 0x00			; padding
	.byte 0x00			; padding
	.byte 0x00			; padding
MTStr_ClrGridHanten:	aligned_string "MT_ClrGridHanten"
MTStr_StylCnvStor:	aligned_string "MT_StylCnvStor"
MTStr_SetSelectedLine:	aligned_string "MT_SetSelectedLine"
MTStr_CstmTNmDisp:	aligned_string "MT_CstmTNmDisp"
MTStr_CstmFNmDisp:	aligned_string "MT_CstmFNmDisp"
MTStr_CstmTNmGet:	aligned_string "MT_CstmTNmGet"
MTStr_CstmFNmGet:	aligned_string "MT_CstmFNmGet"
MTStr_EsCmpVariDn:	aligned_string "MT_EsCmpVariDn"
MTStr_EsCmpVariUp:	aligned_string "MT_EsCmpVariUp"
MTStr_EsCmpStylDn:	aligned_string "MT_EsCmpStylDn"
MTStr_EsCmpStylUp:	aligned_string "MT_EsCmpStylUp"
MTStr_EsCmpPartDn:	aligned_string "MT_EsCmpPartDn"
MTStr_EsCmpPartUp:	aligned_string "MT_EsCmpPartUp"
MTStr_SetPtSel:	aligned_string "MT_SetPtSel"
MTStr_ArgChoDisp:	aligned_string "MT_ArgChoDisp"
MTStr_ArgToneNmDisp:	aligned_string "MT_ArgToneNmDisp"
MTStr_ArgChoGet:	aligned_string "MT_ArgChoGet"
MTStr_ArgToneNmGet:	aligned_string "MT_ArgToneNmGet"
MTStr_MspPlyMdSet:	aligned_string "MT_MspPlyMdSet"
MTStr_MspRgp2NmDisp:	aligned_string "MT_MspRgp2NmDisp"
MTStr_MspRgp1NmDisp:	aligned_string "MT_MspRgp1NmDisp"
MTStr_MspUsr2NmDisp:	aligned_string "MT_MspUsr2NmDisp"
MTStr_MspUsr1NmDisp:	aligned_string "MT_MspUsr1NmDisp"
MTStr_MspRgp2NmGet:	aligned_string "MT_MspRgp2NmGet"
MTStr_MspRgp1NmGet:	aligned_string "MT_MspRgp1NmGet"
MTStr_MspUsr2NmGet:	aligned_string "MT_MspUsr2NmGet"
MTStr_MspUsr1NmGet:	aligned_string "MT_MspUsr1NmGet"
MTStr_CstmCpOk:	aligned_string "MT_CstmCpOk"
MTStr_RgpPadDn:	aligned_string "MT_RgpPadDn"
MTStr_RgpPadUp:	aligned_string "MT_RgpPadUp"
MTStr_RgpBnkDn:	aligned_string "MT_RgpBnkDn"
MTStr_RgpBnkUp:	aligned_string "MT_RgpBnkUp"
MTStr_S2cTrDn:	aligned_string "MT_S2cTrDn"
MTStr_S2cTrUp:	aligned_string "MT_S2cTrUp"
MTStr_CmpSetP1Dn:	aligned_string "MT_CmpSetP1Dn"
MTStr_CmpSetP1Up:	aligned_string "MT_CmpSetP1Up"
MTStr_RLmtValGet:	aligned_string "MT_RLmtValGet"
MTStr_PanValGet:	aligned_string "MT_PanValGet"
MTStr_RLmtDn:	aligned_string "MT_RLmtDn"
MTStr_RLmtUp:	aligned_string "MT_RLmtUp"
MTStr_PanDn:	aligned_string "MT_PanDn"
MTStr_PanUp:	aligned_string "MT_PanUp"
MTStr_CmpClrNo:	aligned_string "MT_CmpClrNo"
MTStr_CmpClrYes:	aligned_string "MT_CmpClrYes"
MTStr_APRHYVARINM:	aligned_string "MT_APRHYVARINM"
MTStr_APRHYGRPNM:	aligned_string "MT_APRHYGRPNM"
MTStr_RhyVariNmGet:	aligned_string "MT_RhyVariNmGet"
MTStr_RhyGrpNmGet:	aligned_string "MT_RhyGrpNmGet"
MTStr_MspNameSet:	aligned_string "MT_MspNameSet"
MTStr_CmpNameSet:	aligned_string "MT_CmpNameSet"

; PaintArrowProc dispatch entry (last entry in property descriptor tables)
; 18 bytes: dispatch fields (5) + zero padding (5) + two pointers (8)
	.byte 0x32, 0x00, 0xb1, 0xdf, 0xf1	; dispatch fields
	.zero 5					; zero padding
	.long NakaStr_PaintArrowProc_Empty + 2	; -> "PaintArrowProc" name string
	.long NakaStr_PaintArrowProc_Empty	; -> empty code string
