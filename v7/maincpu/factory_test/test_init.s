; =============================================================================
; Factory Diagnostic Tests (internal codename: "HAMA")
; =============================================================================
;
; This subsystem provides factory diagnostic test modes for hardware validation
; during manufacturing. It includes floppy disk read/write tests (FDD TEST)
; and hard disk extension tests (HDD EXT, EXT APR). These test screens are
; accessed through hidden button combinations and are not part of the normal
; user interface.
;
; "HAMA" is the Matsushita/Technics developer codename for this subsystem.
; All original symbol names (InitializeHama, RegObjTableHama, etc.) are preserved.
;
; Files in this directory:
;   test_init.s     - InitializeHama(): test mode registration
;   test_data.s     - Test UI configuration data
;   fd_test_code.s  - Floppy disk test execution routines
;   fd_test_data.s  - Floppy disk test parameters and dialog data
; =============================================================================

.macro RegObjTableHama ParamA, ParamB, ParamC, ParamD, ParamE
	.if \ParamA <= 7
	ld xwa, \ParamA:i3
	.else
	ld xwa, \ParamA
	.endif
	ld (xsp + 0:8), xwa
	lda xwa, (\ParamB:24)
	ld (xsp + 4), xwa
	ld wa, (\ParamC:24)	; was `ldw_da xwa, ...`: d2 nn nn nn 20 loads WA, not XWA
	ld (xsp + 8), wa
	lda xwa, (\ParamD:24)
	ld (xsp + 10), xwa
	mri_d2 0xb7, 0x30
	ld xbc, xwa
	.if \ParamE <= 7
	ld wa, \ParamE:i3
	.else
	ldw wa, \ParamE
	.endif
	call RegisterObjectTable
.endm


.macro RegObjTablHama ParamA, ParamB, ParamC, ParamD, ParamE
	.if \ParamA <= 7
	ld xwa, \ParamA:i3
	.else
	ld xwa, \ParamA
	.endif
	ld (xsp + 0:8), xwa
	lda xwa, (\ParamB:24)
	ld (xsp + 4), xwa
	ldw (xsp + 8), \ParamC
	lda xwa, (\ParamD:24)
	ld (xsp + 10), xwa
	mri_d2 0xb7, 0x30
	ld xbc, xwa
	.if \ParamE <= 7
	ld wa, \ParamE:i3
	.else
	ldw wa, \ParamE
	.endif
	call RegisterObjectTable
.endm


.macro RegTitleHama ParamA, ParamB, ParamC, ParamD, ParamE
	pushw \ParamA
	lda xwa, (\ParamB:24)
	push xwa
	.if \ParamC <= 7
	ld xwa, \ParamC:i3
	.else
	ld xwa, \ParamC
	.endif
	.if \ParamD <= 7
	ld xbc, \ParamD:i3
	.else
	ld xbc, \ParamD
	.endif
	.if \ParamE <= 7
	ld xde, \ParamE:i3
	.else
	ld xde, \ParamE
	.endif
	call RegisterTitle
.endm
InitializeHama:
	lda	xsp, (xsp-14)
	ld	xwa, NAKA_CLASS_Class
	ld	(xsp+0:8), xwa
	lda	xwa, (ClassProc:24)
	ld	(xsp+4), xwa
	ld	wa, (InitializeHama_Data_3:24)
	ld	(xsp+8), wa
	lda	xwa, (InitializeHama_Data_2:24)
	ld	(xsp+10), xwa
	lda	xwa, (xsp)
	ld	xbc, xwa
	ldw	wa, 361
	call	RegisterObjectTable
	ld	xwa, NAKA_CLASS_ResEvent
	ld	(xsp+0:8), xwa
	lda	xwa, (ResEventProc:24)
	ld	(xsp+4), xwa
	ld	wa, (InitializeHama_Data_5:24)
	ld	(xsp+8), wa
	lda	xwa, (Hama_ResEventTable_1C9:24)
	ld	(xsp+10), xwa
	lda	xwa, (xsp)
	ld	xbc, xwa
	ldw	wa, 457
	call	RegisterObjectTable
	ld	xwa, NAKA_CLASS_ResMethod
	ld	(xsp+0:8), xwa
	lda	xwa, (ResMethodProc:24)
	ld	(xsp+4), xwa
	ld	wa, (InitializeHama_Data_7:24)
	ld	(xsp+8), wa
	lda	xwa, (Hama_ResMethodTable_1E9:24)
	ld	(xsp+10), xwa
	lda	xwa, (xsp)
	ld	xbc, xwa
	ldw	wa, 489
	call	RegisterObjectTable
	ld	xwa, NAKA_CLASS_ApFunction
	ld	(xsp+0:8), xwa
	lda	xwa, (ApFunctionProc:24)
	ld	(xsp+4), xwa
	ldw	(xsp+8), 2
	lda	xwa, (InitializeHama_PtrTable:24)
	ld	(xsp+10), xwa
	lda	xwa, (xsp)
	ld	xbc, xwa
	ldw	wa, 297
	call	RegisterObjectTable
	ld	xwa, NAKA_CLASS_ApFunction
	ld	(xsp+0:8), xwa
	lda	xwa, (ApFunctionProc:24)
	ld	(xsp+4), xwa
	ldw	(xsp+8), 2
	lda	xwa, (Hama_ApFuncTable_429:24)
	ld	(xsp+10), xwa
	lda	xwa, (xsp)
	ld	xbc, xwa
	ldw	wa, 1065
	call	RegisterObjectTable
	ld	xwa, NAKA_CLASS_Function
	ld	(xsp+0:8), xwa
	lda	xwa, (FunctionProc:24)
	ld	(xsp+4), xwa
	ldw	(xsp+8), 75
	lda	xwa, (Hama_FunctionTable_109:24)
	ld	(xsp+10), xwa
	lda	xwa, (xsp)
	ld	xbc, xwa
	ldw	wa, 265
	call	RegisterObjectTable
	ld	xwa, NAKA_CLASS_Function
	ld	(xsp+0:8), xwa
	lda	xwa, (FunctionProc:24)
	ld	(xsp+4), xwa
	ldw	(xsp+8), 75
	lda	xwa, (Hama_ModeParam_Table:24)
	ld	(xsp+10), xwa
	lda	xwa, (xsp)
	ld	xbc, xwa
	ldw	wa, 1033
	call	RegisterObjectTable
	ld	xwa, NAKA_CLASS_MainFunction
	ld	(xsp+0:8), xwa
	lda	xwa, (MainFunctionProc:24)
	ld	(xsp+4), xwa
	ldw	(xsp+8), 1
	lda	xwa, (InitializeHama_Data_11:24)
	ld	(xsp+10), xwa
	lda	xwa, (xsp)
	ld	xbc, xwa
	ldw	wa, 329
	call	RegisterObjectTable
	ld	xwa, NAKA_CLASS_MainFunction
	ld	(xsp+0:8), xwa
	lda	xwa, (MainFunctionProc:24)
	ld	(xsp+4), xwa
	ldw	(xsp+8), 1
	lda	xwa, (InitializeHama_Data_12:24)
	ld	(xsp+10), xwa
	lda	xwa, (xsp)
	ld	xbc, xwa
	ldw	wa, 1097
	call	RegisterObjectTable
	ld	xwa, NAKA_CLASS_Viewable
	ld	(xsp+0:8), xwa
	lda	xwa, (ViewableProc:24)
	ld	(xsp+4), xwa
	ldw	(xsp+8), 0
	lda	xwa, (InitializeHama_Str_Empty:24)
	ld	(xsp+10), xwa
	lda	xwa, (xsp)
	ld	xbc, xwa
	ldw	wa, 127
	call	RegisterObjectTable
	ld	xwa, NAKA_CLASS_ResName
	ld	(xsp+0:8), xwa
	lda	xwa, (ResNameProc:24)
	ld	(xsp+4), xwa
	ldw	(xsp+8), 0
	lda	xwa, (InitializeHama_Data_10:24)
	ld	(xsp+10), xwa
	lda	xwa, (xsp)
	ld	xbc, xwa
	ldw	wa, 895
	call	RegisterObjectTable
	ld	xwa, NAKA_CLASS_Viewable
	ld	(xsp+0:8), xwa
	lda	xwa, (ViewableProc:24)
	ld	(xsp+4), xwa
	ldw	(xsp+8), 26
	lda	xwa, (InitializeHama_Data_9:24)
	ld	(xsp+10), xwa
	lda	xwa, (xsp)
	ld	xbc, xwa
	ldw	wa, 252
	call	RegisterObjectTable
	ld	xwa, NAKA_CLASS_ResName
	ld	(xsp+0:8), xwa
	lda	xwa, (ResNameProc:24)
	ld	(xsp+4), xwa
	ldw	(xsp+8), 26
	lda	xwa, (FDTest_Config_Table:24)
	ld	(xsp+10), xwa
	lda	xwa, (xsp)
	ld	xbc, xwa
	ldw	wa, 1020
	call	RegisterObjectTable
	pushw 9
	lda	xwa, (InitializeHama_Str_TT_HDDEXT:24)
	push	xwa
	ld	xwa, 127
	ld	xbc, NAKA_MAINFUNC_TestTitleFunc
	ld	xde, NAKA_VIEW_FDD_TEST
	call	RegisterTitle
	pushw 9
	lda	xwa, (InitializeHama_Str_TT_EXTAPR:24)
	push	xwa
	ld	xwa, 252
	ld	xbc, NAKA_MAINFUNC_TestTitleFunc
	ld	xde, NAKA_VIEW_FDD_TEST
	call	RegisterTitle
	lda	xsp, (xsp+14)
	ret
FDTest_PrintDiag:
	jp Debug_PrintString

; TestTitleFunc - Title lifecycle and action handler for FD diagnostic tests
; Dispatches on two event codes:
;   0x1c00007 (title lifecycle): xde selects handler from jump table at 0xe1fdfe
;     0=new, 1=old, 2=activate, 3=inactivate, 4-5=interrupt, 6=TBIOS test
;   0x1c00013 (user actions): xde selects handler from jump table at 0xe1fe0e
;     2=STOP, 3=START LOOP, 4=DIR listing, 5-6=debug test
TestTitleFunc:
	push xiz
	ld xiz, xwa
	ld wa, 0:i3
	cp xbc, EVT_SW_IN
	jr z, TitleFunc_LifecycleDispatch
	cp xbc, EVT_ACTIVATE_STATE
	jrl nz, TitleFunc_Return
	ld xwa, xde
	dec 2, xwa
	cp xwa, 0x0
	jrl c, TitleFunc_Return
	cp xwa, 0x5
	jrl ugt, TitleFunc_Return
	add xwa, xwa
	add xwa, TestTitleFunc_CaseTable
	ld wa, (xwa)
	lda xix, (TitleFunc_ActionDispatch:24)
	jp	t, (xix+wa)

; User action dispatch table (event 0x1c00013, xde=2..6)
; Each entry loads a string address and calls FDTest_PrintDiag, then exits
TitleFunc_ActionDispatch:
	lda xwa, (TitleFunc_ActionDispatch_Str_TitleNew:24)
	calr FDTest_PrintDiag
	jrl TitleFunc_Return
TestTitleFunc_OnTitleOld:
	lda xwa, (TestTitleFunc_OnTitleOld_Str_TitleOld:24)
	calr FDTest_PrintDiag
	jrl TitleFunc_Return
TestTitleFunc_OnTitleActivate:
	lda xwa, (TestTitleFunc_OnTitleActivate_Str_TitleActivate:24)
	calr FDTest_PrintDiag
	jrl TitleFunc_Return
TestTitleFunc_OnTitleInactivate:
	lda xwa, (TestTitleFunc_OnTitleInactivate_Str_TitleInactivate:24)
	calr FDTest_PrintDiag
	jrl TitleFunc_Return
TestTitleFunc_OnTitleInterrupt:
	lda xwa, (TestTitleFunc_OnTitleInterrupt_Str_TitleINTERUPT:24)
	calr FDTest_PrintDiag
	jrl TitleFunc_Return
TestTitleFunc_OnTitleInterruptReturn:
	lda xwa, (TestTitleFunc_OnTitleInterruptReturn_Str_TitleINTERUPT_RETURN:24)
	calr FDTest_PrintDiag
	jrl TitleFunc_Return

TitleFunc_LifecycleDispatch:
	ld xwa, xde
	cp xwa, 0x7
	jrl ugt, TitleFunc_Return
	add xwa, xwa
	add xwa, TitleFunc_LifecycleDispatch_CaseTable
	ld wa, (xwa)
	lda xix, (TitleFunc_LifecycleTable:24)
	jp	t, (xix+wa)

; Title lifecycle dispatch table (event 0x1c00007, xde=0..6)
; 0=new: print+call 0xf97edb, 1=old: send event+call 0xfaa257
; 2=activate: run test stats+call 0xfaa135, 3=inactivate: print+DIR listing
; 4=interrupt: print+call RegHamaTitle1_Entry, 5=interrupt return: print+call RegHamaTitle2_Entry
; 6=TBIOS test: call ListDir2_Entry
TitleFunc_LifecycleTable:
	lda xwa, (TitleFunc_LifecycleTable_Str_TBIOS_Test:24)
	calr FDTest_PrintDiag
	call TitleFunc_LifecycleTable_Helper
	jr TitleFunc_Return
TitleFunc_LifecycleDispatch_OnStopFddTest:
	ld xwa, EVT_SW_IN
	push xwa
	ld xwa, 2:i3
	push xwa
	ld xbc, xiz
	ld xwa, 0:i3
	ld xde, 0xffffffff
	call KillApTimer
	lda xwa, (TitleFunc_LifecycleDispatch_OnStopFddTest_Str_STOP_FDD_TEST:24)
	calr FDTest_PrintDiag
	ld wa, 0:i3
	jr TitleFunc_Return
TitleFunc_LifecycleDispatch_OnFddTestLoop:
	lda xwa, (TitleFunc_LifecycleDispatch_OnFddTestLoop_Str_START_FDD_TEST_LOOP:24)
	calr FDTest_PrintDiag
	calr RunTestCounters_Entry
	ld xwa, EVT_SW_IN
	push xwa
	ld xwa, 2:i3
	push xwa
	ld xbc, xiz
	ld xwa, 0x53
	ld xde, 0xffffffff
	call SetApTimer
	ld wa, 1:i3
	jr TitleFunc_Return
TitleFunc_LifecycleDispatch_OnListDirectory:
	lda xwa, (TitleFunc_LifecycleDispatch_OnListDirectory_Str_DIR:24)
	calr FDTest_PrintDiag
	calr FDListDirectory
	jr TitleFunc_Return
TitleFunc_LifecycleDispatch_OnFormat2dd:
	lda xwa, (TitleFunc_LifecycleDispatch_OnFormat2dd_Str_Debug_Test:24)
	calr FDTest_PrintDiag
	calr RegHamaTitle1_Entry
	jr TitleFunc_Return
TitleFunc_LifecycleDispatch_OnFormat2hd:
	lda xwa, (TitleFunc_LifecycleDispatch_OnFormat2hd_Str_Debug_Test:24)
	calr FDTest_PrintDiag
	calr RegHamaTitle2_Entry
	jr TitleFunc_Return
TitleFunc_LifecycleDispatch_OnListLswFiles:
	calr ListDir2_Entry

TitleFunc_Return:
	ld xhl, 0:i3
	pop xiz
	ret

; ListDirectoryEntries2 -- Opens directory, iterates all entries via
; ReadNextEntry, logging each via FDTest_PrintDiag. Similar to FDListDirectory
; but uses format string at 0xe1fe1a and compares dir handle against xiz directly.
; Args: (xsp+4) = directory path string pointer
; Returns: hl = 0 on success, 0xffff on open failure
; Stack frame: 266 bytes
ListDir2_Entry:
	lda xsp, (xsp - 266)
	push xiz
	lda xwa, (ListDir2_Entry_Str_A_HAMA_LSW:24)
	lda xbc, (xsp + 4)
	call _findfirst
	ld xiz, xhl
	cp xiz, 0xffffffff
	jr nz, ListDir2_LogEntry
	ldw hl, 0xffff
	jr ListDir2_Return
ListDir2_LogEntry:
	lda xwa, (xsp + 10)
	calr FDTest_PrintDiag
	ld xbc, (xsp + 4)
	ld xwa, xiz
	call _findnext
	cp hl, 0xffff
	jr z, ListDir2_CloseDir
ListDir2_NextEntry:
	lda xwa, (xsp + 10)
	calr FDTest_PrintDiag
	ld xbc, (xsp + 4)
	ld xwa, xiz
	call _findnext
	cp hl, 0xffff
	jr nz, ListDir2_NextEntry
ListDir2_CloseDir:
	ld xwa, xiz
	call _findclose
	ld hl, 0:i3
ListDir2_Return:
	pop xiz
	lda xsp, (xsp + 266)
	ret

; RunTestAndUpdateCounters -- Checks FD status (0xf525ec), runs FDLoadSaveTest
; if status is 2 or 3, increments TOTAL/OK/NG counters at 0x03dcfe-0x03dd02,
; then displays updated counts via NAKA widget system (0xfa9d58).
; Returns: l = 0xff if status invalid, otherwise falls through to display
RunTestCounters_Entry:
	call GetMediaType
	cp l, 3:i3
	jr z, RunTestCounters_RunTest
	cp l, 2:i3
	jr nz, RunTestCounters_BadStatus
RunTestCounters_RunTest:
	incw 1, (0x03dcfe:24)
	calr FDLoadSaveTest
	cp hl, 0:i3
	jr nz, RunTestCounters_IncrNG
	incw 1, (0x03dd00:24)
	jr RunTestCounters_Display
RunTestCounters_BadStatus:
	ld l, 0xff:opc
	ret
RunTestCounters_IncrNG:
	incw 1, (0x03dd02:24)
RunTestCounters_Display:
	lda xwa, (RunTestCounters_Display_Str_TEST_Finishd:24)
	calr FDTest_PrintDiag
	ld de, (0x03dcfe:24)
	exts xde
	ld xwa, NAKA_VIEW_TOTAL
	ld xbc, EVT_PARA_DRAW
	call ApPostEvent
	ld de, (0x03dd00:24)
	exts xde
	ld xwa, NAKA_VIEW_OK
	ld xbc, EVT_PARA_DRAW
	call ApPostEvent
	ld de, (0x03dd02:24)
	exts xde
	ld xwa, NAKA_VIEW_NG
	ld xbc, EVT_PARA_DRAW
	jp ApPostEvent

; CreateAndRunFDOperation -- Builds a 16-byte parameter struct on the stack,
; calls 0xf97cca to execute the FD operation, then prints success/failure.
CreateRunFDOp_Entry:
	lda xsp, (xsp - 16)
	lda xwa, (CreateRunFDOp_Entry_Str_init:24)
	calr FDTest_PrintDiag
	ldw (xsp+0:8), 0
	ldw (xsp + 6), 0xe0
	ldw (xsp + 2), 0x0
	ldw (xsp + 4), 0x0
	ldw (xsp + 8), 0x0
	ldw (xsp + 10), 0x0
	ld xwa, 0:i3
	ld (xsp + 12), xwa
	lda xwa, (xsp)
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	cp hl, 0:i3
	jr nz, CreateRunFDOp_Fail
	lda xwa, (CreateRunFDOp_Entry_Str_OK:24)
	calr FDTest_PrintDiag
	jr CreateRunFDOp_Return
CreateRunFDOp_Fail:
	lda xwa, (CreateRunFDOp_Fail_Str_NG:24)
	calr FDTest_PrintDiag
CreateRunFDOp_Return:
	lda xsp, (xsp + 16)
	ret

.include "factory_test/fd_test_code.s"

; RegisterHamaTitle1 -- Registers title with widget table 0x7f (FDD/HD test)
; Calls 0xf51e4f with WA=2, then 0xf5289c with string at 0xe1ff42
RegHamaTitle1_Entry:
	ld wa, 2:i3
	call format_FD
	lda xwa, (RegHamaTitle1_Entry_Str_TEST_HAMA:24)
	call FileIO_CheckPathAndVolumeLabel
	ld hl, 0:i3
	ret

; RegisterHamaTitle2 -- Registers title with widget table 0xfc (extension APR test)
; Calls 0xf51e4f with WA=3, then 0xf5289c with string at 0xe1ff4c
RegHamaTitle2_Entry:
	ld wa, 3:i3
	call format_FD
	lda xwa, (RegHamaTitle2_Entry_Str_TESTHAMA2HD:24)
	call FileIO_CheckPathAndVolumeLabel
	ld hl, 0:i3
	ret

; SendEventWithParam -- Sends event 0x1c00025 with xwa as parameter via 0xfa9660
; Args: xwa = event parameter (moved to xde)
SendEvent_Entry:
	ld xde, xwa
	ld xwa, 0xffffffff
	ld xbc, EVT_MEMO_DRAW
	jp SendEvent

; HamaEventDispatcher -- Dispatches events for HAMA subsystem
; Handles 0x1c00007 (title lifecycle) and 0x1e00085 (extension event)
; For 0x1c00007: dispatches on xde (0x8a=file ops, 0x8b=extension bootstrap)
HamaDeb_HdaeDebugScreenFunc:
	cp xbc, EVT_SW_IN
	jr z, HamaEvtDisp_LifecycleCheck
	cp xbc, EVT_ARE_YOU_CLASS_PROC
	jr nz, HamaEvtDisp_Return
	ld xhl, 0:i3
	ret
HamaEvtDisp_LifecycleCheck:
	cp xde, 0x8b
	jr z, HamaEvtDisp_ExtBootstrap
	cp xde, 0x8a
	jr nz, HamaEvtDisp_Return
	lda xwa, (HamaEvtDisp_LifecycleCheck_Str_LOAD:24)
	calr SendEvent_Entry
	calr CheckFDStatusLoad_Entry
	lda xwa, (HamaEvtDisp_LifecycleCheck_Str_LOAD_END:24)
	calr SendEvent_Entry
	jr HamaEvtDisp_Return
HamaEvtDisp_ExtBootstrap:
	lda xwa, (HamaEvtDisp_ExtBootstrap_Str_GO:24)
	calr SendEvent_Entry
	calr LoadExtROM_Entry
	lda xwa, (HamaEvtDisp_ExtBootstrap_Str_Finishd:24)
	calr SendEvent_Entry
HamaEvtDisp_Return:
	ld xhl, 0:i3
	ret

; CheckFDStatusAndLoadFile -- Checks FD status, loads file from disk into
; extension DRAM (0x200000) if status is 2 or 3
CheckFDStatusLoad_Entry:
	push xiz
	call GetMediaType
	extz hl
	cp hl, 2:i3
	jr z, CheckFDStatusLoad_DoLoad
	cp hl, 3:i3
	jr z, CheckFDStatusLoad_DoLoad
	lda xwa, (CheckFDStatusLoad_Entry_Str_Media_Error:24)
	calr SendEvent_Entry
	jr CheckFDStatusLoad_Return
CheckFDStatusLoad_DoLoad:
	lda xwa, (CheckFDStatusLoad_DoLoad_Str_rb:24)
	push xwa
	pushw CheckFDStatusLoad_DoLoad_Str_A_HKEXT_XAP@hi16
	pushw CheckFDStatusLoad_DoLoad_Str_A_HKEXT_XAP@lo16
	call FileOpen
	inc 8, xsp
	ld xiz, xhl
	or xiz, xiz
	jr nz, CheckFDStatusLoad_Transfer
	lda xwa, (CheckFDStatusLoad_DoLoad_Str_Cannot_open:24)
	calr SendEvent_Entry
	jr CheckFDStatusLoad_Return
CheckFDStatusLoad_Transfer:
	push xiz
	pushw 0x8000
	pushw 0x1
	ld xwa, 0x200000
	push xwa
	call FileRead
	push xiz
	call FileClose
	lda xsp, (xsp + 16)
CheckFDStatusLoad_Return:
	pop xiz
	ret

; LoadExtensionROM -- Loads 4 bytes from extension ROM path at 0xe1ff9c
; into DRAM at 0x200000, checks result, jumps to extension entry point
LoadExtROM_Entry:
	pushw	4
	pushw	LoadExtROM_Entry_Str_XAPR@hi16
	pushw	LoadExtROM_Entry_Str_XAPR@lo16
	ld	xwa, 2097152
	push	xwa
	call	String_Compare
	add	xsp, 10
	cp	hl, 0:i3
	jr	z, LoadExtROM_JumpEntry
	lda	xwa, (LoadExtROM_Entry_Str_Different_ID:24)
	jrl	SendEvent_Entry
LoadExtROM_JumpEntry:
	ld xhl, 0x200008
	lda xwa, (0x027ed2:24)
	jp (xhl)

Xapr_GetPresentFlag:
	ld l, (XAPR_PRESENT_FLAG:24)
	ret

Xapr_DetectOnInit:
	pushw	4
	pushw	LoadExtROM_JumpEntry_Str_XAPR@hi16
	pushw	LoadExtROM_JumpEntry_Str_XAPR@lo16
	ld	xwa, 2621440
	push	xwa
	call	String_Compare
	add	xsp, 10
	cp	hl, 0:i3
	ret	nz
	ld	(XAPR_PRESENT_FLAG:24), 1
	ret
Xapr_InitPhase1_NullRet:
	ret

Xapr_InitPhase2_NullRet:
	ret

Xapr_InitPhase3_NullRet:
	ret

Xapr_CallFrameHandler:
	cp (XAPR_PRESENT_FLAG:24), 0x00
	ret z
	ld xhl, 0x280010
	call (xhl)
	ret

Xapr_DetectAndCallBootInit:
	pushw	4
	pushw	LoadExtROM_JumpEntry_Data@hi16
	pushw	LoadExtROM_JumpEntry_Data@lo16
	ld	xwa, 2621440
	push	xwa
	call	String_Compare
	add	xsp, 10
	cp	hl, 0:i3
	jr	nz, LoadAndRunXapr_ClearFlag
	ld	(XAPR_PRESENT_FLAG:24), 1
	jr	LoadAndRunXapr_CallIfActive
LoadAndRunXapr_ClearFlag:
	ld (XAPR_PRESENT_FLAG:24), 0x00

LoadAndRunXapr_CallIfActive:
	cp (XAPR_PRESENT_FLAG:24), 0x00
	ret z
	ld xhl, 0x280008
	lda xwa, (0x027ed2:24)
	call (xhl)
	ret
