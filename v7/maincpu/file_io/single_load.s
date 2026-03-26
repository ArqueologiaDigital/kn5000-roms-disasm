; =============================================================================
; file_io/single_load.asm - Single File Load Operations
; =============================================================================
; Single file load mode with source/destination selection.
;
; Key routines:
;   SingleLoadModeFunc               - Single load mode entry
;   SingleLoadDstBankFunc            - Destination bank selection
;   SingleLoadDstMemFunc             - Destination memory selection
;   SingleLoadSrcBankFunc            - Source bank selection
;   SingleLoadSrcMemFunc             - Source memory selection
;   SingleLoadSrcFunc                - Source file selection
;   SingleLoadDstFunc                - Destination selection
;   CmpSingleLoadSrcFunc             - Composer single load source
;   CmpSingleLoadDstFunc             - Composer single load destination
;   CmpSingleLoadFileFunc            - Composer single load file
;   FmmCmpSingleLoadFunc             - Composer single load handler
; =============================================================================

SingleLoadModeFunc:
	.incbin "includes/generated/v7_transplant_SingleLoadModeFunc.bin"
SLMode_HandleShow:
	.incbin "includes/generated/v7_transplant_SLMode_HandleShow.bin"
SLMode_Return:
	lds32 xhl, 0
	ret

SingleLoadDstBankFunc:
	.incbin "includes/generated/v7_transplant_SingleLoadDstBankFunc.bin"
SLDstBank_HandleShow:
	.incbin "includes/generated/v7_transplant_SLDstBank_HandleShow.bin"
SLDstBank_Return:
	lds32 xhl, 0
	ret

SingleLoadDstMemFunc:
	.incbin "includes/generated/v7_transplant_SingleLoadDstMemFunc.bin"
SLDstMem_HandleShow:
	.incbin "includes/generated/v7_transplant_SLDstMem_HandleShow.bin"
SLDstMem_ShowFromBank:
	.incbin "includes/generated/v7_transplant_SLDstMem_ShowFromBank.bin"
SLDstMem_DispatchShow:
	call ApPostEvent

SLDstMem_Return:
	lds32 xhl, 0
	ret

SingleLoadSrcBankFunc:
	.incbin "includes/generated/v7_transplant_SingleLoadSrcBankFunc.bin"
SLSrcBank_HandleShow:
	.incbin "includes/generated/v7_transplant_SLSrcBank_HandleShow.bin"
SLSrcBank_ShowFromIndex:
	extz bc
	sla bc, 2
	ld_sril3 XDE, 0x07, 0xe8, 0xe4
	ld xbc, 0x1c0000f

SLSrcBank_DispatchShow:
	call ApPostEvent

SLSrcBank_Return:
	lds32 xhl, 0
	ret

SingleLoadSrcMemFunc:
	.incbin "includes/generated/v7_transplant_SingleLoadSrcMemFunc.bin"
SLSrcMem_HandleShow:
	.incbin "includes/generated/v7_transplant_SLSrcMem_HandleShow.bin"
SLSrcMem_ShowDirect:
	ld xde, (xde + 16)
	ld xbc, 0x1c0000f
	jr SLSrcMem_DispatchShow

SLSrcMem_ShowFromIndex:
	extz bc
	sla bc, 2
	ld_sril3 XDE, 0x07, 0xe8, 0xe4
	ld xbc, 0x1c0000f

SLSrcMem_DispatchShow:
	call ApPostEvent

SLSrcMem_Return:
	lds32 xhl, 0
	ret

SLSrcBankList_FuncBody:
	.incbin "includes/generated/v7_transplant_SLSrcBankList_FuncBody.bin"
SingleLoadSrcFunc:
	.incbin "includes/generated/v7_transplant_SingleLoadSrcFunc.bin"
SLSrc_HandleShow:
	.incbin "includes/generated/v7_transplant_SLSrc_HandleShow.bin"
SLSrc_HandleScroll:
	.incbin "includes/generated/v7_transplant_SLSrc_HandleScroll.bin"
SLSrc_ScrollMode5_Prev:
	.incbin "includes/generated/v7_transplant_SLSrc_ScrollMode5_Prev.bin"
SLSrc_ScrollMode5_Dispatch:
	.incbin "includes/generated/v7_transplant_SLSrc_ScrollMode5_Dispatch.bin"
SLSrc_ScrollMode6:
	.incbin "includes/generated/v7_transplant_SLSrc_ScrollMode6.bin"
SLSrc_ScrollMode6_NoStep:
	.incbin "includes/generated/v7_transplant_SLSrc_ScrollMode6_NoStep.bin"
SLSrc_ScrollMode6_Dispatch:
	.incbin "includes/generated/v7_transplant_SLSrc_ScrollMode6_Dispatch.bin"
SLSrc_ScrollMode7:
	.incbin "includes/generated/v7_transplant_SLSrc_ScrollMode7.bin"
SLSrc_ScrollMode8:
	.incbin "includes/generated/v7_transplant_SLSrc_ScrollMode8.bin"
SLSrc_ScrollMode40:
	.incbin "includes/generated/v7_transplant_SLSrc_ScrollMode40.bin"
SLSrc_Return:
	lds32 xhl, 0
	jr SLSrc_Epilogue

SLSrc_ReturnCapture:
	ld xhl, 0xffffffff

SLSrc_Epilogue:
	pop xiz
	inc 4, xsp
	ret

SLDstBankList_FuncBody:
	.incbin "includes/generated/v7_transplant_SLDstBankList_FuncBody.bin"
SingleLoadDstFunc:
	.incbin "includes/generated/v7_transplant_SingleLoadDstFunc.bin"
SLDst_ShowHide_Internal:
	ld xwa, 0x61004a
	ld xbc, 0x1e0009c
	lds32 xde, 0

SLDst_ShowHide_Dispatch:
	.incbin "includes/generated/v7_transplant_SLDst_ShowHide_Dispatch.bin"
SLDst_ClearFloppyFlag:
	.incbin "includes/generated/v7_transplant_SLDst_ClearFloppyFlag.bin"
SLDst_Return:
	lds32 xhl, 0
	jrl SLDst_Epilogue

SLDst_HandleShow:
	.incbin "includes/generated/v7_transplant_SLDst_HandleShow.bin"
SLDst_HandleConfirm:
	.incbin "includes/generated/v7_transplant_SLDst_HandleConfirm.bin"
SLDst_HandleScroll:
	.incbin "includes/generated/v7_transplant_SLDst_HandleScroll.bin"
SLDst_ScrollMode4:
	.incbin "includes/generated/v7_transplant_SLDst_ScrollMode4.bin"
SLDst_ScrollMode4_Internal:
	ld xwa, 0x61004a
	ld xbc, 0x1e0009c
	lds32 xde, 0

SLDst_ScrollMode4_Dispatch:
	.incbin "includes/generated/v7_transplant_SLDst_ScrollMode4_Dispatch.bin"
SLDst_ScrollMode3_CallSrcMem:
	calr SingleLoadSrcFunc
	jrl SLDst_Return

SLDst_ScrollDispatch:
	.incbin "includes/generated/v7_transplant_SLDst_ScrollDispatch.bin"
SLDst_Scroll_ChildReturn:
	.incbin "includes/generated/v7_transplant_SLDst_Scroll_ChildReturn.bin"
SLDst_Scroll_SubMode:
	.incbin "includes/generated/v7_transplant_SLDst_Scroll_SubMode.bin"
SLDst_Scroll_SubMode2:
	.incbin "includes/generated/v7_transplant_SLDst_Scroll_SubMode2.bin"
SLDst_Scroll_SubMode3:
	.incbin "includes/generated/v7_transplant_SLDst_Scroll_SubMode3.bin"
SLDst_Scroll_SubMode4:
	.incbin "includes/generated/v7_transplant_SLDst_Scroll_SubMode4.bin"
SLDst_Scroll_SubMode5:
	.incbin "includes/generated/v7_transplant_SLDst_Scroll_SubMode5.bin"
SLDst_Scroll_SubMode6:
	.incbin "includes/generated/v7_transplant_SLDst_Scroll_SubMode6.bin"
SLDst_ReturnCapture:
	ld xhl, 0xffffffff

SLDst_Epilogue:
	pop xiz
	inc 8, xsp
	ret

CmpSingleLoadSrcFunc:
	.incbin "includes/generated/v7_transplant_CmpSingleLoadSrcFunc.bin"
CmpSrc_HandleShow:
	.incbin "includes/generated/v7_transplant_CmpSrc_HandleShow.bin"
CmpSrc_HandleScroll:
	.incbin "includes/generated/v7_transplant_CmpSrc_HandleScroll.bin"
CmpSrc_ScrollMode6:
	.incbin "includes/generated/v7_transplant_CmpSrc_ScrollMode6.bin"
CmpSrc_ScrollMode6_NoStep:
	.incbin "includes/generated/v7_transplant_CmpSrc_ScrollMode6_NoStep.bin"
CmpSrc_ScrollMode7:
	.incbin "includes/generated/v7_transplant_CmpSrc_ScrollMode7.bin"
CmpSrc_ScrollMode8:
	.incbin "includes/generated/v7_transplant_CmpSrc_ScrollMode8.bin"
CmpSrc_ScrollMode40:
	.incbin "includes/generated/v7_transplant_CmpSrc_ScrollMode40.bin"
CmpSrc_Return:
	lds32 xhl, 0
	jr CmpSrc_Epilogue

CmpSrc_ReturnCapture:
	ld xhl, 0xffffffff

CmpSrc_Epilogue:
	pop xiz
	inc 4, xsp
	ret

CmpSingleLoadDstFunc:
	.incbin "includes/generated/v7_transplant_CmpSingleLoadDstFunc.bin"
CmpDst_HandleShow:
	.incbin "includes/generated/v7_transplant_CmpDst_HandleShow.bin"
CmpDst_HandleScroll:
	.incbin "includes/generated/v7_transplant_CmpDst_HandleScroll.bin"
CmpDst_ScrollModeA:
	.incbin "includes/generated/v7_transplant_CmpDst_ScrollModeA.bin"
CmpDst_ScrollMode7:
	.incbin "includes/generated/v7_transplant_CmpDst_ScrollMode7.bin"
CmpDst_ScrollMode8:
	.incbin "includes/generated/v7_transplant_CmpDst_ScrollMode8.bin"
CmpDst_ScrollMode8_NoStep:
	.incbin "includes/generated/v7_transplant_CmpDst_ScrollMode8_NoStep.bin"
CmpDst_ScrollMode5:
	.incbin "includes/generated/v7_transplant_CmpDst_ScrollMode5.bin"
CmpDst_ScrollMode6:
	.incbin "includes/generated/v7_transplant_CmpDst_ScrollMode6.bin"
CmpDst_Return:
	lds32 xhl, 0
	jr CmpDst_Epilogue

CmpDst_ReturnCapture:
	ld xhl, 0xffffffff

CmpDst_Epilogue:
	pop xiz
	inc 8, xsp
	ret

CmpSingleLoadFileFunc:
	.incbin "includes/generated/v7_transplant_CmpSingleLoadFileFunc.bin"
CmpFile_Selection_Clamp:
	.incbin "includes/generated/v7_transplant_CmpFile_Selection_Clamp.bin"
CmpFile_HandleShow:
	.incbin "includes/generated/v7_transplant_CmpFile_HandleShow.bin"
CmpFile_ShowDefault:
	lda_24 xiz, (Data_SaveLoadMenuTable_0x62)

CmpFile_ShowDraw:
	.incbin "includes/generated/v7_transplant_CmpFile_ShowDraw.bin"
CmpFile_ShowDispatch:
	call ApPostEvent
	jrl CmpFile_Return

CmpFile_HandleScroll:
	.incbin "includes/generated/v7_transplant_CmpFile_HandleScroll.bin"
CmpFile_ScrollDown:
	cp xde, 0x1
	jr nz, CmpFile_ScrollRedraw
	cps wa, 0
	jr le, CmpFile_ScrollRedraw
	dec 1, wa

CmpFile_ScrollStore:
	.incbin "includes/generated/v7_transplant_CmpFile_ScrollStore.bin"
CmpFile_ScrollRedraw:
	.incbin "includes/generated/v7_transplant_CmpFile_ScrollRedraw.bin"
CmpFile_RedrawDispatch:
	.incbin "includes/generated/v7_transplant_CmpFile_RedrawDispatch.bin"
CmpFile_Return:
	lds32 xhl, 0
	pop xiz
	inc 4, xsp
	ret

FmmCmpSingleLoadFunc:
	.incbin "includes/generated/v7_transplant_FmmCmpSingleLoadFunc.bin"
FmmCmpLoad_DispatchState:
	.incbin "includes/generated/v7_transplant_FmmCmpLoad_DispatchState.bin"
FmmCmpLoad_ContinueLoad:
	.incbin "includes/generated/v7_transplant_FmmCmpLoad_ContinueLoad.bin"
FmmCmpLoad_SignalProgress:
	calr SignalProgressUpdate

FmmCmpLoad_CloseProgress:
	.incbin "includes/generated/v7_transplant_FmmCmpLoad_CloseProgress.bin"
FmmCmpLoad_HandleCancel:
	.incbin "includes/generated/v7_transplant_FmmCmpLoad_HandleCancel.bin"
FmmCmpLoad_HandleError:
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0x7d
	call UI_PostModeChangeEvent
	jr FmmCmpLoad_Return

FmmCmpLoad_HandleSuccess:
	.incbin "includes/generated/v7_transplant_FmmCmpLoad_HandleSuccess.bin"
FmmCmpLoad_CallStatusDisplay:
	call SoundCtrl_SendCommand
	jr FmmCmpLoad_Return

FmmCmpLoad_HandleAbort:
	calr CancelOperationCleanup

FmmCmpLoad_Return:
	lds32 xhl, 0
	ret

BuildSlotLabel:
	.incbin "includes/generated/v7_transplant_BuildSlotLabel.bin"
BuildSlotLabel_WriteLetter:
	stib_dsp 0xf8, 0x20
	ld wa, (xsp + 4)
	add a, 0x31
	ld (xiz), a

BuildSlotLabel_WriteColon:
	inc 1, xiz
	stib_dsp 0xf8, 0x3a

BuildSlotLabel_WriteContent:
	.incbin "includes/generated/v7_fix_buildslotlabel_writecontent.bin"
