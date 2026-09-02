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
	lds32 xwa, \ParamA
	.else
	ld xwa, \ParamA
	.endif
	ld (xsp + 256), xwa
	lda_24 xwa, (\ParamB)
	ld (xsp + 4), xwa
	ldw_da xwa, (\ParamC)
	ld (xsp + 8), wa
	lda_24 xwa, (\ParamD)
	ld (xsp + 10), xwa
	mri_d2 0xb7, 0x30
	ld xbc, xwa
	.if \ParamE <= 7
	lds wa, \ParamE
	.else
	ldw wa, \ParamE
	.endif
	call RegisterObjectTable
.endm


.macro RegObjTablHama ParamA, ParamB, ParamC, ParamD, ParamE
	.if \ParamA <= 7
	lds32 xwa, \ParamA
	.else
	ld xwa, \ParamA
	.endif
	ld (xsp + 256), xwa
	lda_24 xwa, (\ParamB)
	ld (xsp + 4), xwa
	ldw (xsp + 8), \ParamC
	lda_24 xwa, (\ParamD)
	ld (xsp + 10), xwa
	mri_d2 0xb7, 0x30
	ld xbc, xwa
	.if \ParamE <= 7
	lds wa, \ParamE
	.else
	ldw wa, \ParamE
	.endif
	call RegisterObjectTable
.endm


.macro RegTitleHama ParamA, ParamB, ParamC, ParamD, ParamE
	pushw \ParamA
	lda_24 xwa, (\ParamB)
	push xwa
	.if \ParamC <= 7
	lds32 xwa, \ParamC
	.else
	ld xwa, \ParamC
	.endif
	.if \ParamD <= 7
	lds32 xbc, \ParamD
	.else
	ld xbc, \ParamD
	.endif
	.if \ParamE <= 7
	lds32 xde, \ParamE
	.else
	ld xde, \ParamE
	.endif
	call RegisterTitle
.endm
InitializeHama:
	lda	xsp, (xsp-14)
	ld	xwa, 23068676
	ld	(xsp+256), xwa
	lda	xwa, (16400597:24)
	ld	(xsp+4), xwa
	ld	wa, (14807228:24)
	ld	(xsp+8), wa
	lda	xwa, (14807168:24)
	ld	(xsp+10), xwa
	lda	xwa, (xsp)
	ld	xbc, xwa
	ldw	wa, 361
	call	16400110
	ld	xwa, 23068684
	ld	(xsp+256), xwa
	lda	xwa, (16405742:24)
	ld	(xsp+4), xwa
	ld	wa, (14807252:24)
	ld	(xsp+8), wa
	lda	xwa, (14807230:24)
	ld	(xsp+10), xwa
	lda	xwa, (xsp)
	ld	xbc, xwa
	ldw	wa, 457
	call	16400110
	ld	xwa, 23068685
	ld	(xsp+256), xwa
	lda	xwa, (16405819:24)
	ld	(xsp+4), xwa
	ld	wa, (14807274:24)
	ld	(xsp+8), wa
	lda	xwa, (14807254:24)
	ld	(xsp+10), xwa
	lda	xwa, (xsp)
	ld	xbc, xwa
	ldw	wa, 489
	call	16400110
	ld	xwa, 23068674
	ld	(xsp+256), xwa
	lda	xwa, (16401759:24)
	ld	(xsp+4), xwa
	ldw	(xsp+8), 2
	lda	xwa, (14807114:24)
	ld	(xsp+10), xwa
	lda	xwa, (xsp)
	ld	xbc, xwa
	ldw	wa, 297
	call	16400110
	ld	xwa, 23068674
	ld	(xsp+256), xwa
	lda	xwa, (16401759:24)
	ld	(xsp+4), xwa
	ldw	(xsp+8), 2
	lda	xwa, (14807126:24)
	ld	(xsp+10), xwa
	lda	xwa, (xsp)
	ld	xbc, xwa
	ldw	wa, 1065
	call	16400110
	ld	xwa, 23068673
	ld	(xsp+256), xwa
	lda	xwa, (16401564:24)
	ld	(xsp+4), xwa
	ldw	(xsp+8), 75
	lda	xwa, (14807276:24)
	ld	(xsp+10), xwa
	lda	xwa, (xsp)
	ld	xbc, xwa
	ldw	wa, 265
	call	16400110
	ld	xwa, 23068673
	ld	(xsp+256), xwa
	lda	xwa, (16401564:24)
	ld	(xsp+4), xwa
	ldw	(xsp+8), 75
	lda	xwa, (14807616:24)
	ld	(xsp+10), xwa
	lda	xwa, (xsp)
	ld	xbc, xwa
	ldw	wa, 1033
	call	16400110
	ld	xwa, 23068675
	ld	(xsp+256), xwa
	lda	xwa, (16401931:24)
	ld	(xsp+4), xwa
	ldw	(xsp+8), 1
	lda	xwa, (14810412:24)
	ld	(xsp+10), xwa
	lda	xwa, (xsp)
	ld	xbc, xwa
	ldw	wa, 329
	call	16400110
	ld	xwa, 23068675
	ld	(xsp+256), xwa
	lda	xwa, (16401931:24)
	ld	(xsp+4), xwa
	ldw	(xsp+8), 1
	lda	xwa, (14810420:24)
	ld	(xsp+10), xwa
	lda	xwa, (xsp)
	ld	xbc, xwa
	ldw	wa, 1097
	call	16400110
	ld	xwa, 23068688
	ld	(xsp+256), xwa
	lda	xwa, (16405896:24)
	ld	(xsp+4), xwa
	ldw	(xsp+8), 0
	lda	xwa, (14810064:24)
	ld	(xsp+10), xwa
	lda	xwa, (xsp)
	ld	xbc, xwa
	ldw	wa, 127
	call	16400110
	ld	xwa, 23068687
	ld	(xsp+256), xwa
	lda	xwa, (16408254:24)
	ld	(xsp+4), xwa
	ldw	(xsp+8), 0
	lda	xwa, (14810176:24)
	ld	(xsp+10), xwa
	lda	xwa, (xsp)
	ld	xbc, xwa
	ldw	wa, 895
	call	16400110
	ld	xwa, 23068688
	ld	(xsp+256), xwa
	lda	xwa, (16405896:24)
	ld	(xsp+4), xwa
	ldw	(xsp+8), 26
	lda	xwa, (14810068:24)
	ld	(xsp+10), xwa
	lda	xwa, (xsp)
	ld	xbc, xwa
	ldw	wa, 252
	call	16400110
	ld	xwa, 23068687
	ld	(xsp+256), xwa
	lda	xwa, (16408254:24)
	ld	(xsp+4), xwa
	ldw	(xsp+8), 26
	lda	xwa, (14810182:24)
	ld	(xsp+10), xwa
	lda	xwa, (xsp)
	ld	xbc, xwa
	ldw	wa, 1020
	call	16400110
	pushw 9
	lda	xwa, (14810392:24)
	push	xwa
	ld	xwa, 127
	ld	xbc, 21561344
	ld	xde, 16515072
	call	16402803
	pushw 9
	lda	xwa, (14810402:24)
	push	xwa
	ld	xwa, 252
	ld	xbc, 21561344
	ld	xde, 16515072
	call	16402803
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
	lds wa, 0
	cp xbc, 0x1c00007
	jr z, TitleFunc_LifecycleDispatch
	cp xbc, 0x1c00013
	jrl nz, TitleFunc_Return
	ld xwa, xde
	dec 2, xwa
	cp xwa, 0x0
	jrl c, TitleFunc_Return
	cp xwa, 0x5
	jrl ugt, TitleFunc_Return
	add xwa, xwa
	add xwa, FDTest_String_TestTitleFunc_0xD0
	ld wa, (xwa)
	lda xix, (TitleFunc_ActionDispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe0

; User action dispatch table (event 0x1c00013, xde=2..6)
; Each entry loads a string address and calls FDTest_PrintDiag, then exits
TitleFunc_ActionDispatch:
	lda xwa, (FDTest_String_TestTitleFunc_0xE:24)
	calr FDTest_PrintDiag
	jrl TitleFunc_Return
	lda xwa, (FDTest_String_TestTitleFunc_0x1A:24)
	calr FDTest_PrintDiag
	jrl TitleFunc_Return
	lda xwa, (FDTest_String_TestTitleFunc_0x26:24)
	calr FDTest_PrintDiag
	jrl TitleFunc_Return
	lda xwa, (FDTest_String_TestTitleFunc_0x36:24)
	calr FDTest_PrintDiag
	jrl TitleFunc_Return
	lda xwa, (FDTest_String_TestTitleFunc_0x48:24)
	calr FDTest_PrintDiag
	jrl TitleFunc_Return
	lda xwa, (FDTest_String_TestTitleFunc_0x58:24)
	calr FDTest_PrintDiag
	jrl TitleFunc_Return

TitleFunc_LifecycleDispatch:
	ld xwa, xde
	cp xwa, 0x7
	jrl ugt, TitleFunc_Return
	add xwa, xwa
	add xwa, FDTest_String_TestTitleFunc_0xC0
	ld wa, (xwa)
	lda xix, (TitleFunc_LifecycleTable:24)
	jp_ind 8, 0x07, 0xf0, 0xe0

; Title lifecycle dispatch table (event 0x1c00007, xde=0..6)
; 0=new: print+call 0xf97edb, 1=old: send event+call 0xfaa257
; 2=activate: run test stats+call 0xfaa135, 3=inactivate: print+DIR listing
; 4=interrupt: print+call RegHamaTitle1_Entry, 5=interrupt return: print+call RegHamaTitle2_Entry
; 6=TBIOS test: call ListDir2_Entry
TitleFunc_LifecycleTable:
	lda xwa, (FDTest_String_TestTitleFunc_0x70:24)
	calr FDTest_PrintDiag
	call Reset_Floppy_Disk_Controller_0x12
	jr TitleFunc_Return
	ld xwa, 0x01c00007
	push xwa
	lds32 xwa, 2
	push xwa
	ld xbc, xiz
	lds32 xwa, 0
	ld xde, 0xffffffff
	call KillApTimer
	lda xwa, (FDTest_String_TestTitleFunc_0x7C:24)
	calr FDTest_PrintDiag
	lds wa, 0
	jr TitleFunc_Return
	lda xwa, (FDTest_String_TestTitleFunc_0x8C:24)
	calr FDTest_PrintDiag
	calr RunTestCounters_Entry
	ld xwa, 0x01c00007
	push xwa
	lds32 xwa, 2
	push xwa
	ld xbc, xiz
	ld xwa, 0x53
	ld xde, 0xffffffff
	call SetApTimer
	lds wa, 1
	jr TitleFunc_Return
	lda xwa, (FDTest_String_TestTitleFunc_0xA2:24)
	calr FDTest_PrintDiag
	calr FDListDirectory
	jr TitleFunc_Return
	lda xwa, (FDTest_String_TestTitleFunc_0xA8:24)
	calr FDTest_PrintDiag
	calr RegHamaTitle1_Entry
	jr TitleFunc_Return
	lda xwa, (FDTest_String_TestTitleFunc_0xB4:24)
	calr FDTest_PrintDiag
	calr RegHamaTitle2_Entry
	jr TitleFunc_Return
	calr ListDir2_Entry

TitleFunc_Return:
	lds32 xhl, 0
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
	lda xwa, (FDTest_String_TestTitleFunc_0xDC:24)
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
	lds hl, 0
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
	cps l, 3
	jr z, RunTestCounters_RunTest
	cps l, 2
	jr nz, RunTestCounters_BadStatus
RunTestCounters_RunTest:
	incdi16_24 1, (0x03dcfe)
	calr FDLoadSaveTest
	cps hl, 0
	jr nz, RunTestCounters_IncrNG
	incdi16_24 1, (0x03dd00)
	jr RunTestCounters_Display
RunTestCounters_BadStatus:
	ldb l, 0xff
	ret
RunTestCounters_IncrNG:
	incdi16_24 1, (0x03dd02)
RunTestCounters_Display:
	lda xwa, (FDTest_String_TestTitleFunc_0xEA:24)
	calr FDTest_PrintDiag
	ld de, (0x03dcfe:24)
	exts xde
	ld xwa, 0x00fc0001
	ld xbc, 0x01c0000f
	call ApPostEvent
	ld de, (0x03dd00:24)
	exts xde
	ld xwa, 0x00fc0003
	ld xbc, 0x01c0000f
	call ApPostEvent
	ld de, (0x03dd02:24)
	exts xde
	ld xwa, 0x00fc0002
	ld xbc, 0x01c0000f
	jp ApPostEvent

; CreateAndRunFDOperation -- Builds a 16-byte parameter struct on the stack,
; calls 0xf97cca to execute the FD operation, then prints success/failure.
CreateRunFDOp_Entry:
	lda xsp, (xsp - 16)
	lda xwa, (FDTest_String_TestTitleFunc_0xFA:24)
	calr FDTest_PrintDiag
	ldw (xsp+256), 0
	ldw (xsp + 6), 0xe0
	ldw (xsp + 2), 0x0
	ldw (xsp + 4), 0x0
	ldw (xsp + 8), 0x0
	ldw (xsp + 10), 0x0
	lds32 xwa, 0
	ld (xsp + 12), xwa
	lda xwa, (xsp)
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	cps hl, 0
	jr nz, CreateRunFDOp_Fail
	lda xwa, (FDTest_String_TestTitleFunc_0x100:24)
	calr FDTest_PrintDiag
	jr CreateRunFDOp_Return
CreateRunFDOp_Fail:
	lda xwa, (FDTest_String_TestTitleFunc_0x104:24)
	calr FDTest_PrintDiag
CreateRunFDOp_Return:
	lda xsp, (xsp + 16)
	ret

.include "factory_test/fd_test_code.s"

; RegisterHamaTitle1 -- Registers title with widget table 0x7f (FDD/HD test)
; Calls 0xf51e4f with WA=2, then 0xf5289c with string at 0xe1ff42
RegHamaTitle1_Entry:
	lds wa, 2
	call format_FD
	lda xwa, (FDTest_String_TestTitleFunc_0x204:24)
	call FileIO_CheckPathAndVolumeLabel
	lds hl, 0
	ret

; RegisterHamaTitle2 -- Registers title with widget table 0xfc (extension APR test)
; Calls 0xf51e4f with WA=3, then 0xf5289c with string at 0xe1ff4c
RegHamaTitle2_Entry:
	lds wa, 3
	call format_FD
	lda xwa, (FDTest_String_TestTitleFunc_0x20E:24)
	call FileIO_CheckPathAndVolumeLabel
	lds hl, 0
	ret

; SendEventWithParam -- Sends event 0x1c00025 with xwa as parameter via 0xfa9660
; Args: xwa = event parameter (moved to xde)
SendEvent_Entry:
	ld xde, xwa
	ld xwa, 0xffffffff
	ld xbc, 0x01c00025
	jp SendEvent

; HamaEventDispatcher -- Dispatches events for HAMA subsystem
; Handles 0x1c00007 (title lifecycle) and 0x1e00085 (extension event)
; For 0x1c00007: dispatches on xde (0x8a=file ops, 0x8b=extension bootstrap)
HamaEvtDisp_Entry:
	cp xbc, 0x01c00007
	jr z, HamaEvtDisp_LifecycleCheck
	cp xbc, 0x01e00085
	jr nz, HamaEvtDisp_Return
	lds32 xhl, 0
	ret
HamaEvtDisp_LifecycleCheck:
	cp xde, 0x8b
	jr z, HamaEvtDisp_ExtBootstrap
	cp xde, 0x8a
	jr nz, HamaEvtDisp_Return
	lda xwa, (FDTest_String_TestTitleFunc_0x21A:24)
	calr SendEvent_Entry
	calr CheckFDStatusLoad_Entry
	lda xwa, (FDTest_String_TestTitleFunc_0x220:24)
	calr SendEvent_Entry
	jr HamaEvtDisp_Return
HamaEvtDisp_ExtBootstrap:
	lda xwa, (FDTest_String_TestTitleFunc_0x22A:24)
	calr SendEvent_Entry
	calr LoadExtROM_Entry
	lda xwa, (FDTest_String_TestTitleFunc_0x22E:24)
	calr SendEvent_Entry
HamaEvtDisp_Return:
	lds32 xhl, 0
	ret

; CheckFDStatusAndLoadFile -- Checks FD status, loads file from disk into
; extension DRAM (0x200000) if status is 2 or 3
CheckFDStatusLoad_Entry:
	push xiz
	call GetMediaType
	extz hl
	cps hl, 2
	jr z, CheckFDStatusLoad_DoLoad
	cps hl, 3
	jr z, CheckFDStatusLoad_DoLoad
	lda xwa, (FDTest_String_TestTitleFunc_0x236:24)
	calr SendEvent_Entry
	jr CheckFDStatusLoad_Return
CheckFDStatusLoad_DoLoad:
	lda xwa, (FDTest_String_TestTitleFunc_0x242:24)
	push xwa
	pushw 0xe1
	pushw 0xff84
	call FileOpen
	inc 8, xsp
	ld xiz, xhl
	or xiz, xiz
	jr nz, CheckFDStatusLoad_Transfer
	lda xwa, (FDTest_String_TestTitleFunc_0x252:24)
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
	pushw	225
	pushw	65436
	ld	xwa, 2097152
	push	xwa
	call	16712932
	add	xsp, 10
	cps	hl, 0
	jr	z, 8
	lda	xwa, (14811042:24)
	jrl	-217
LoadExtROM_JumpEntry:
	ld xhl, 0x200008
	lda xwa, (0x027ed2:24)
	jp (xhl)

GetAprStatus_Entry:
	ldb_da l, (0x03dd04)
	ret

LoadXaprInit_Entry:
	pushw	4
	pushw	225
	pushw	65456
	ld	xwa, 2621440
	push	xwa
	call	16712932
	add	xsp, 10
	cps	hl, 0
	ret	nz
	stib_da	(253188), 1
	ret
HamaStub1_Entry:
	ret

HamaStub2_Entry:
	ret

HamaStub3_Entry:
	ret

CallExtIfActive_Entry:
	cpib_da (0x03dd04), 0x00
	ret z
	ld xhl, 0x280010
	call (xhl)
	ret

LoadAndRunXapr_Entry:
	pushw	4
	pushw	225
	pushw	65478
	ld	xwa, 2621440
	push	xwa
	call	16712932
	add	xsp, 10
	cps	hl, 0
	jr	nz, 8
	stib_da	(253188), 1
	jr	6
LoadAndRunXapr_ClearFlag:
	stib_da (0x03dd04), 0x00

LoadAndRunXapr_CallIfActive:
	cpib_da (0x03dd04), 0x00
	ret z
	ld xhl, 0x280008
	lda xwa, (0x027ed2:24)
	call (xhl)
	ret
