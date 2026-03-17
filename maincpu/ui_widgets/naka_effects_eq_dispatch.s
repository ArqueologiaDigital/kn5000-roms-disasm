// Sequencer/Effect/EQ dispatch data
// Extracted from kn5000_v10_program.s
// Contains: SqedtVal strings, EqualizerBox/EffectBox data,
// EvtEffDraw_PtrTable, EvtName_* event strings,
// MT_FuncName_PtrTable and all MT_* function name strings.

	jr	gt, 0x00
	aligned_string "SqedtVal2"
	aligned_string "^^jC"
	aligned_string "SqedtVal"
	jr	gt, 67
	.byte 0x00			; padding
	.byte 0xFF			; padding
	aligned_string "EqualizerBox"
	jr	gt, 66
	.byte 0x42, 0x43, 0x00, 0xff
	aligned_string "EffectBox"
	.byte 0x1a, 0x00
EvtEffDraw_PtrTable:
	.long EvtName_EffFixDraw
	.long EvtName_EffParaDraw
	.long EvtName_EqLineDraw
	.long EvtName_EqStrDraw
	.long EvtName_GraphDraw
	.byte 0x00			; padding
	.byte 0x00			; padding
	.byte 0x00			; padding
	.byte 0x00			; padding
EvtName_GraphDraw:	aligned_string "EV_GRAPHDRAW"
EvtName_EqStrDraw:	aligned_string "EV_EQSTRDRAW"
EvtName_EqLineDraw:	aligned_string "EV_EQLINEDRAW"
EvtName_EffParaDraw:	aligned_string "EV_EFFPARADRAW"
EvtName_EffFixDraw:	aligned_string "EV_EFFFIXDRAW"
	.byte 0x05, 0x00

MT_FuncName_PtrTable:
	.long MT_GetEffFixString_Name
	.long MT_GetEffDlt0Str_Name
	.long MT_GetEffDlt1Str_Name
	.long MT_GetEffDlt2Str_Name
	.long MT_GetEffDlt3Str_Name
	.long MT_GetEffDlt4Str_Name
	.long MT_GetEffDlt5Str_Name
	.long MT_GetEffDlt6Str_Name
	.long MT_GetEffDlt7Str_Name
	.long MT_GetItemExist_Name
	.long MT_SetItemOff_Name
	.long MT_GetItemOff_Name
	.long MT_SetItemTop_Name
	.long MT_GetItemTop_Name
	.long MT_RetEffFix_Name
	.long MT_RetEffPara_Name
	.long MT_GetParaSize_Name
	.long MT_CngEffType_Name
	.long MT_CngEffPara_Name
	.long MT_GetDispPos_Name
	.long MT_IncVal_Name
	.long MT_DecVal_Name
	.long MT_GetTrkString_Name
	.long MT_GetFMString_Name
	.long MT_GetLMString_Name
	.long MT_GetAdlyString_Name
	.long MT_GetTrnsString_Name
	.long MT_GetVeloString_Name
	.long MT_GetMersString_Name
	.long MT_GetQtzValString_Name
	.long MT_GetQtzStrString_Name
	.long MT_GetQtzWinString_Name
	.long MT_GetTnString_Name
	.long MT_GetCnString_Name
	.long MT_GetMrgTrAString_Name
	.long MT_GetMrgTrBString_Name
	.long MT_GetMrgTrCString_Name
	.long MT_GetMcpTrAString_Name
	.long MT_GetMcpFMString_Name
	.long MT_GetMcpLMString_Name
	.long MT_GetMcpTrBString_Name
	.long MT_GetMcpSMString_Name
	.long MT_GetMcpRepString_Name
	.long MT_GetMinsTrAString_Name
	.long MT_GetMinsFMString_Name
	.long MT_GetMinsLMString_Name
	.long MT_GetMinsTrBString_Name
	.long MT_GetMinsSMString_Name
	.long MT_GetMinsRepString_Name
	.long MT_GetScpFsngString_Name
	.long MT_GetScpFtrString_Name
	.long MT_GetScpTsngString_Name
	.long MT_GetScpTtrString_Name
	.long MT_SetCurPos_Name
	.long MT_GetCurPos_Name
	.long MT_CurToParam_Name
	.long MT_ChkCur_Name
	.long MT_ChkCur2_Name
	.long MT_GetFromCur_Name
	.long MT_SetFromCur_Name
	.long MT_GetToCur_Name
	.long MT_SetToCur_Name
	.long MT_GetMeasString_Name
	.long MT_GetBeatString_Name
	.long MT_GetMemString_Name
	.long MT_GetCycEnString_Name
	.long MT_GetCycSrtMString_Name
	.long MT_GetCycEndMString_Name
	.long MT_SetCycle_Name
	.long MT_SetMetro_Name
	.long MT_SetPunch_Name
	.long MT_GetSoloEnString_Name
	.long MT_GetSclrNoString_Name
	.long MT_GetSclrNameString_Name
	.long MT_GetSclrKbString_Name
	.long MT_GetSclrPerString_Name
	.long MT_GetAccLvlStr_Name
	.long MT_GetPMeasString_Name
	.long MT_GetPInMeasString_Name
	.long MT_GetPOutMeasString_Name
	.long MT_GetPCntInString_Name
	.long MT_GetEndPos_Name
	.long MT_GetTriPos_Name
	.long MT_GetLinePos_Name
	.long MT_GetHakuString_Name
	.long MT_GetPosString_Name
	.long MT_GetIncString_Name
	.long MT_GetNoteString_Name
	.long MT_GetVelString_Name
	.long MT_GetInputVelString_Name
	.long MT_GetLenString_Name
	.long MT_GetInputLenString_Name
	.long MT_GetMeasTopNumSv_Name
	.long MT_GetMeasCngSv_Name
	.long MT_NoteBarDisp_Name
	.long MT_NoteBarDisp2_Name
	.long MT_NoteHilightDisp_Name
	.long MT_GetEq0Str_Name
	.long MT_GetEq1Str_Name
	.long MT_GetEq2Str_Name
	.long MT_GetEq3Str_Name
	.long MT_GetEq4Str_Name
	.long MT_GetEq5Str_Name
	.long MT_GetEq6Str_Name
	.long MT_GetEq7Str_Name
	.long MT_GetTtlNow_Name
	.long MT_GetKb1Str_Name
	.long MT_GetKb2Str_Name
	.long MT_GetDrNumString_Name
	.long MT_GetDrNameString_Name
	.long MT_ChkToggleEditSw_Name
	.long MT_GetLang_Name
	.long MT_SetLang_Name
	.long MT_ChkLang_Name
	.long MT_GetFSngNameString_Name
	.long MT_GetTSngNameString_Name
	.long MT_FlashWrite_Name
	.long MT_FlashLoad_Name
	.long MT_Panic_Name
	.zero 4
MT_Panic_Name:			aligned_string "MT_PANIC"
MT_FlashLoad_Name:		aligned_string "MT_FLASHLOAD"
MT_FlashWrite_Name:		aligned_string "MT_FLASHWRITE"
MT_GetTSngNameString_Name:	aligned_string "MT_GetTSngNameString"
MT_GetFSngNameString_Name:	aligned_string "MT_GetFSngNameString"
MT_ChkLang_Name:		aligned_string "MT_ChkLang"
MT_SetLang_Name:		aligned_string "MT_SetLang"
MT_GetLang_Name:		aligned_string "MT_GetLang"
MT_ChkToggleEditSw_Name:	aligned_string "MT_ChkToggleEditSw"
MT_GetDrNameString_Name:	aligned_string "MT_GetDrNameString"
MT_GetDrNumString_Name:		aligned_string "MT_GetDrNumString"
MT_GetKb2Str_Name:		aligned_string "MT_GetKb2Str"
MT_GetKb1Str_Name:		aligned_string "MT_GetKb1Str"
MT_GetTtlNow_Name:		aligned_string "MT_GetTtlNow"
MT_GetEq7Str_Name:		aligned_string "MT_GetEq7Str"
MT_GetEq6Str_Name:		aligned_string "MT_GetEq6Str"
MT_GetEq5Str_Name:		aligned_string "MT_GetEq5Str"
MT_GetEq4Str_Name:		aligned_string "MT_GetEq4Str"
MT_GetEq3Str_Name:		aligned_string "MT_GetEq3Str"
MT_GetEq2Str_Name:		aligned_string "MT_GetEq2Str"
MT_GetEq1Str_Name:		aligned_string "MT_GetEq1Str"
MT_GetEq0Str_Name:		aligned_string "MT_GetEq0Str"
MT_NoteHilightDisp_Name:	aligned_string "MT_NoteHilightDisp"
MT_NoteBarDisp2_Name:		aligned_string "MT_NoteBarDisp2"
MT_NoteBarDisp_Name:		aligned_string "MT_NoteBarDisp"
MT_GetMeasCngSv_Name:		aligned_string "MT_GetMeasCngSv"
MT_GetMeasTopNumSv_Name:	aligned_string "MT_GetMeasTopNumSv"
MT_GetInputLenString_Name:	aligned_string "MT_GetInputLenString"
MT_GetLenString_Name:		aligned_string "MT_GetLenString"
MT_GetInputVelString_Name:	aligned_string "MT_GetInputVelString"
MT_GetVelString_Name:		aligned_string "MT_GetVelString"
MT_GetNoteString_Name:		aligned_string "MT_GetNoteString"
MT_GetIncString_Name:		aligned_string "MT_GetIncString"
MT_GetPosString_Name:		aligned_string "MT_GetPosString"
MT_GetHakuString_Name:		aligned_string "MT_GetHakuString"
MT_GetLinePos_Name:		aligned_string "MT_GetLinePos"
MT_GetTriPos_Name:		aligned_string "MT_GetTriPos"
MT_GetEndPos_Name:		aligned_string "MT_GetEndPos"
MT_GetPCntInString_Name:	aligned_string "MT_GetPCntInString"
MT_GetPOutMeasString_Name:	aligned_string "MT_GetPOutMeasString"
MT_GetPInMeasString_Name:	aligned_string "MT_GetPInMeasString"
MT_GetPMeasString_Name:		aligned_string "MT_GetPMeasString"
MT_GetAccLvlStr_Name:		aligned_string "MT_GetAccLvlStr"
MT_GetSclrPerString_Name:	aligned_string "MT_GetSclrPerString"
MT_GetSclrKbString_Name:	aligned_string "MT_GetSclrKbString"
MT_GetSclrNameString_Name:	aligned_string "MT_GetSclrNameString"
MT_GetSclrNoString_Name:	aligned_string "MT_GetSclrNoString"
MT_GetSoloEnString_Name:	aligned_string "MT_GetSoloEnString"
MT_SetPunch_Name:		aligned_string "MT_SetPunch"
MT_SetMetro_Name:		aligned_string "MT_SetMetro"
MT_SetCycle_Name:		aligned_string "MT_SetCycle"
MT_GetCycEndMString_Name:	aligned_string "MT_GetCycEndMString"
MT_GetCycSrtMString_Name:	aligned_string "MT_GetCycSrtMString"
MT_GetCycEnString_Name:		aligned_string "MT_GetCycEnString"
MT_GetMemString_Name:		aligned_string "MT_GetMemString"
MT_GetBeatString_Name:		aligned_string "MT_GetBeatString"
MT_GetMeasString_Name:		aligned_string "MT_GetMeasString"
MT_SetToCur_Name:		aligned_string "MT_SetToCur"
MT_GetToCur_Name:		aligned_string "MT_GetToCur"
MT_SetFromCur_Name:		aligned_string "MT_SetFromCur"
MT_GetFromCur_Name:		aligned_string "MT_GetFromCur"
MT_ChkCur2_Name:		aligned_string "MT_ChkCur2"
MT_ChkCur_Name:			aligned_string "MT_ChkCur"
MT_CurToParam_Name:		aligned_string "MT_CurToParam"
MT_GetCurPos_Name:		aligned_string "MT_GetCurPos"
MT_SetCurPos_Name:		aligned_string "MT_SetCurPos"
MT_GetScpTtrString_Name:	aligned_string "MT_GetScpTtrString"
MT_GetScpTsngString_Name:	aligned_string "MT_GetScpTsngString"
MT_GetScpFtrString_Name:	aligned_string "MT_GetScpFtrString"
MT_GetScpFsngString_Name:	aligned_string "MT_GetScpFsngString"
MT_GetMinsRepString_Name:	aligned_string "MT_GetMinsRepString"
MT_GetMinsSMString_Name:	aligned_string "MT_GetMinsSMString"
MT_GetMinsTrBString_Name:	aligned_string "MT_GetMinsTrBString"
MT_GetMinsLMString_Name:	aligned_string "MT_GetMinsLMString"
MT_GetMinsFMString_Name:	aligned_string "MT_GetMinsFMString"
MT_GetMinsTrAString_Name:	aligned_string "MT_GetMinsTrAString"
MT_GetMcpRepString_Name:	aligned_string "MT_GetMcpRepString"
MT_GetMcpSMString_Name:		aligned_string "MT_GetMcpSMString"
MT_GetMcpTrBString_Name:	aligned_string "MT_GetMcpTrBString"
MT_GetMcpLMString_Name:		aligned_string "MT_GetMcpLMString"
MT_GetMcpFMString_Name:		aligned_string "MT_GetMcpFMString"
MT_GetMcpTrAString_Name:	aligned_string "MT_GetMcpTrAString"
MT_GetMrgTrCString_Name:	aligned_string "MT_GetMrgTrCString"
MT_GetMrgTrBString_Name:	aligned_string "MT_GetMrgTrBString"
MT_GetMrgTrAString_Name:	aligned_string "MT_GetMrgTrAString"
MT_GetCnString_Name:		aligned_string "MT_GetCnString"
MT_GetTnString_Name:		aligned_string "MT_GetTnString"
MT_GetQtzWinString_Name:	aligned_string "MT_GetQtzWinString"
MT_GetQtzStrString_Name:	aligned_string "MT_GetQtzStrString"
MT_GetQtzValString_Name:	aligned_string "MT_GetQtzValString"
MT_GetMersString_Name:		aligned_string "MT_GetMersString"
MT_GetVeloString_Name:		aligned_string "MT_GetVeloString"
MT_GetTrnsString_Name:		aligned_string "MT_GetTrnsString"
MT_GetAdlyString_Name:		aligned_string "MT_GetAdlyString"
MT_GetLMString_Name:		aligned_string "MT_GetLMString"
MT_GetFMString_Name:		aligned_string "MT_GetFMString"
MT_GetTrkString_Name:		aligned_string "MT_GetTrkString"
MT_DecVal_Name:			aligned_string "MT_DecVal"
MT_IncVal_Name:			aligned_string "MT_IncVal"
MT_GetDispPos_Name:		aligned_string "MT_GetDispPos"
MT_CngEffPara_Name:		aligned_string "MT_CngEffPara"
MT_CngEffType_Name:		aligned_string "MT_CngEffType"
MT_GetParaSize_Name:		aligned_string "MT_GetParaSize"
MT_RetEffPara_Name:		aligned_string "MT_RetEffPara"
MT_RetEffFix_Name:		aligned_string "MT_RetEffFix"
MT_GetItemTop_Name:		aligned_string "MT_GetItemTop"
MT_SetItemTop_Name:		aligned_string "MT_SetItemTop"
MT_GetItemOff_Name:		aligned_string "MT_GetItemOff"
MT_SetItemOff_Name:		aligned_string "MT_SetItemOff"
MT_GetItemExist_Name:		aligned_string "MT_GetItemExist"
MT_GetEffDlt7Str_Name:		aligned_string "MT_GetEffDlt7Str"
MT_GetEffDlt6Str_Name:		aligned_string "MT_GetEffDlt6Str"
MT_GetEffDlt5Str_Name:		aligned_string "MT_GetEffDlt5Str"
MT_GetEffDlt4Str_Name:		aligned_string "MT_GetEffDlt4Str"
MT_GetEffDlt3Str_Name:		aligned_string "MT_GetEffDlt3Str"
MT_GetEffDlt2Str_Name:		aligned_string "MT_GetEffDlt2Str"
MT_GetEffDlt1Str_Name:		aligned_string "MT_GetEffDlt1Str"
MT_GetEffDlt0Str_Name:

	aligned_string "MT_GetEffDlt0Str"

MT_GetEffFixString_Name:	aligned_string "MT_GetEffFixString"

EffectsEditor_GapByte:
	.byte 0x77, 0x00
