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


; InitializeHama - Register HAMA (file/disk) subsystem object tables and titles
; Registers widget tables, view handlers, and two diagnostic titles:
;   "TT_HDDEXT" (0xe1fd18) - FDD/HD extension test, widget table 0x7f
;   "TT_EXTAPR" (0xe1fd22) - Extension APR test, widget table 0xfc
; Both titles use TestTitleFunc (0xf1e39a) as their lifecycle callback.
; Title handler (TestTitleFunc) pointer is stored at 0xe1fd2c in fd_test_data.s.
InitializeHama:
	.byte 0xbf, 0xf2, 0x37, 0x40, 0x04, 0x00, 0x60, 0x01
	.byte 0xbf, 0x00, 0x60, 0xf2, 0xd5, 0x40, 0xfa, 0x30
	.byte 0xbf, 0x04, 0x60, 0xd2, 0xbc, 0xf0, 0xe1, 0x20
	.byte 0xbf, 0x08, 0x50, 0xf2, 0x80, 0xf0, 0xe1, 0x30
	.byte 0xbf, 0x0a, 0x60, 0xb7, 0x30, 0xe8, 0x89, 0x30
	.byte 0x69, 0x01, 0x1d, 0xee, 0x3e, 0xfa, 0x40, 0x0c
	.byte 0x00, 0x60, 0x01, 0xbf, 0x00, 0x60, 0xf2, 0xee
	.byte 0x54, 0xfa, 0x30, 0xbf, 0x04, 0x60, 0xd2, 0xd4
	.byte 0xf0, 0xe1, 0x20, 0xbf, 0x08, 0x50, 0xf2, 0xbe
	.byte 0xf0, 0xe1, 0x30, 0xbf, 0x0a, 0x60, 0xb7, 0x30
	.byte 0xe8, 0x89, 0x30, 0xc9, 0x01, 0x1d, 0xee, 0x3e
	.byte 0xfa, 0x40, 0x0d, 0x00, 0x60, 0x01, 0xbf, 0x00
	.byte 0x60, 0xf2, 0x3b, 0x55, 0xfa, 0x30, 0xbf, 0x04
	.byte 0x60, 0xd2, 0xea, 0xf0, 0xe1, 0x20, 0xbf, 0x08
	.byte 0x50, 0xf2, 0xd6, 0xf0, 0xe1, 0x30, 0xbf, 0x0a
	.byte 0x60, 0xb7, 0x30, 0xe8, 0x89, 0x30, 0xe9, 0x01
	.byte 0x1d, 0xee, 0x3e, 0xfa, 0x40, 0x02, 0x00, 0x60
	.byte 0x01, 0xbf, 0x00, 0x60, 0xf2, 0x5f, 0x45, 0xfa
	.byte 0x30, 0xbf, 0x04, 0x60, 0xbf, 0x08, 0x02, 0x02
	.byte 0x00, 0xf2, 0x4a, 0xf0, 0xe1, 0x30, 0xbf, 0x0a
	.byte 0x60, 0xb7, 0x30, 0xe8, 0x89, 0x30, 0x29, 0x01
	.byte 0x1d, 0xee, 0x3e, 0xfa, 0x40, 0x02, 0x00, 0x60
	.byte 0x01, 0xbf, 0x00, 0x60, 0xf2, 0x5f, 0x45, 0xfa
	.byte 0x30, 0xbf, 0x04, 0x60, 0xbf, 0x08, 0x02, 0x02
	.byte 0x00, 0xf2, 0x56, 0xf0, 0xe1, 0x30, 0xbf, 0x0a
	.byte 0x60, 0xb7, 0x30, 0xe8, 0x89, 0x30, 0x29, 0x04
	.byte 0x1d, 0xee, 0x3e, 0xfa, 0x40, 0x01, 0x00, 0x60
	.byte 0x01, 0xbf, 0x00, 0x60, 0xf2, 0x9c, 0x44, 0xfa
	.byte 0x30, 0xbf, 0x04, 0x60, 0xbf, 0x08, 0x02, 0x4b
	.byte 0x00, 0xf2, 0xec, 0xf0, 0xe1, 0x30, 0xbf, 0x0a
	.byte 0x60, 0xb7, 0x30, 0xe8, 0x89, 0x30, 0x09, 0x01
	.byte 0x1d, 0xee, 0x3e, 0xfa, 0x40, 0x01, 0x00, 0x60
	.byte 0x01, 0xbf, 0x00, 0x60, 0xf2, 0x9c, 0x44, 0xfa
	.byte 0x30, 0xbf, 0x04, 0x60, 0xbf, 0x08, 0x02, 0x4b
	.byte 0x00, 0xf2, 0x40, 0xf2, 0xe1, 0x30, 0xbf, 0x0a
	.byte 0x60, 0xb7, 0x30, 0xe8, 0x89, 0x30, 0x09, 0x04
	.byte 0x1d, 0xee, 0x3e, 0xfa, 0x40, 0x03, 0x00, 0x60
	.byte 0x01, 0xbf, 0x00, 0x60, 0xf2, 0x0b, 0x46, 0xfa
	.byte 0x30, 0xbf, 0x04, 0x60, 0xbf, 0x08, 0x02, 0x01
	.byte 0x00, 0xf2, 0x2c, 0xfd, 0xe1, 0x30, 0xbf, 0x0a
	.byte 0x60, 0xb7, 0x30, 0xe8, 0x89, 0x30, 0x49, 0x01
	.byte 0x1d, 0xee, 0x3e, 0xfa, 0x40, 0x03, 0x00, 0x60
	.byte 0x01, 0xbf, 0x00, 0x60, 0xf2, 0x0b, 0x46, 0xfa
	.byte 0x30, 0xbf, 0x04, 0x60, 0xbf, 0x08, 0x02, 0x01
	.byte 0x00, 0xf2, 0x34, 0xfd, 0xe1, 0x30, 0xbf, 0x0a
	.byte 0x60, 0xb7, 0x30, 0xe8, 0x89, 0x30, 0x49, 0x04
	.byte 0x1d, 0xee, 0x3e, 0xfa, 0x40, 0x10, 0x00, 0x60
	.byte 0x01, 0xbf, 0x00, 0x60, 0xf2, 0x88, 0x55, 0xfa
	.byte 0x30, 0xbf, 0x04, 0x60, 0xbf, 0x08, 0x02, 0x00
	.byte 0x00, 0xf2, 0xd0, 0xfb, 0xe1, 0x30, 0xbf, 0x0a
	.byte 0x60, 0xb7, 0x30, 0xe8, 0x89, 0x30, 0x7f, 0x00
	.byte 0x1d, 0xee, 0x3e, 0xfa, 0x40, 0x0f, 0x00, 0x60
	.byte 0x01, 0xbf, 0x00, 0x60, 0xf2, 0xbe, 0x5e, 0xfa
	.byte 0x30, 0xbf, 0x04, 0x60, 0xbf, 0x08, 0x02, 0x00
	.byte 0x00, 0xf2, 0x40, 0xfc, 0xe1, 0x30, 0xbf, 0x0a
	.byte 0x60, 0xb7, 0x30, 0xe8, 0x89, 0x30, 0x7f, 0x03
	.byte 0x1d, 0xee, 0x3e, 0xfa, 0x40, 0x10, 0x00, 0x60
	.byte 0x01, 0xbf, 0x00, 0x60, 0xf2, 0x88, 0x55, 0xfa
	.byte 0x30, 0xbf, 0x04, 0x60, 0xbf, 0x08, 0x02, 0x1a
	.byte 0x00, 0xf2, 0xd4, 0xfb, 0xe1, 0x30, 0xbf, 0x0a
	.byte 0x60, 0xb7, 0x30, 0xe8, 0x89, 0x30, 0xfc, 0x00
	.byte 0x1d, 0xee, 0x3e, 0xfa, 0x40, 0x0f, 0x00, 0x60
	.byte 0x01, 0xbf, 0x00, 0x60, 0xf2, 0xbe, 0x5e, 0xfa
	.byte 0x30, 0xbf, 0x04, 0x60, 0xbf, 0x08, 0x02, 0x1a
	.byte 0x00, 0xf2, 0x46, 0xfc, 0xe1, 0x30, 0xbf, 0x0a
	.byte 0x60, 0xb7, 0x30, 0xe8, 0x89, 0x30, 0xfc, 0x03
	.byte 0x1d, 0xee, 0x3e, 0xfa, 0x0b, 0x09, 0x00, 0xf2
	.byte 0x18, 0xfd, 0xe1, 0x30, 0x38, 0x40, 0x7f, 0x00
	.byte 0x00, 0x00, 0x41, 0x00, 0x00, 0x49, 0x01, 0x42
	.byte 0x00, 0x00, 0xfc, 0x00, 0x1d, 0x73, 0x49, 0xfa
	.byte 0x0b, 0x09, 0x00, 0xf2, 0x22, 0xfd, 0xe1, 0x30
	.byte 0x38, 0x40, 0xfc, 0x00, 0x00, 0x00, 0x41, 0x00
	.byte 0x00, 0x49, 0x01, 0x42, 0x00, 0x00, 0xfc, 0x00
	.byte 0x1d, 0x73, 0x49, 0xfa, 0xbf, 0x0e, 0x37, 0x0e
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
	lda_24 xix, (TitleFunc_ActionDispatch)
	jp_ind 8, 0x07, 0xf0, 0xe0

; User action dispatch table (event 0x1c00013, xde=2..6)
; Each entry loads a string address and calls FDTest_PrintDiag, then exits
TitleFunc_ActionDispatch:
	lda_24 xwa, (FDTest_String_TestTitleFunc_0xE)
	calr FDTest_PrintDiag
	jrl TitleFunc_Return
	lda_24 xwa, (FDTest_String_TestTitleFunc_0x1A)
	calr FDTest_PrintDiag
	jrl TitleFunc_Return
	lda_24 xwa, (FDTest_String_TestTitleFunc_0x26)
	calr FDTest_PrintDiag
	jrl TitleFunc_Return
	lda_24 xwa, (FDTest_String_TestTitleFunc_0x36)
	calr FDTest_PrintDiag
	jrl TitleFunc_Return
	lda_24 xwa, (FDTest_String_TestTitleFunc_0x48)
	calr FDTest_PrintDiag
	jrl TitleFunc_Return
	lda_24 xwa, (FDTest_String_TestTitleFunc_0x58)
	calr FDTest_PrintDiag
	jrl TitleFunc_Return

TitleFunc_LifecycleDispatch:
	ld xwa, xde
	cp xwa, 0x7
	jrl ugt, TitleFunc_Return
	add xwa, xwa
	add xwa, FDTest_String_TestTitleFunc_0xC0
	ld wa, (xwa)
	lda_24 xix, (TitleFunc_LifecycleTable)
	jp_ind 8, 0x07, 0xf0, 0xe0

; Title lifecycle dispatch table (event 0x1c00007, xde=0..6)
; 0=new: print+call 0xf97edb, 1=old: send event+call 0xfaa257
; 2=activate: run test stats+call 0xfaa135, 3=inactivate: print+DIR listing
; 4=interrupt: print+call RegHamaTitle1_Entry, 5=interrupt return: print+call RegHamaTitle2_Entry
; 6=TBIOS test: call ListDir2_Entry
TitleFunc_LifecycleTable:
	lda_24 xwa, (FDTest_String_TestTitleFunc_0x70)
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
	lda_24 xwa, (FDTest_String_TestTitleFunc_0x7C)
	calr FDTest_PrintDiag
	lds wa, 0
	jr TitleFunc_Return
	lda_24 xwa, (FDTest_String_TestTitleFunc_0x8C)
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
	lda_24 xwa, (FDTest_String_TestTitleFunc_0xA2)
	calr FDTest_PrintDiag
	calr FDListDirectory
	jr TitleFunc_Return
	lda_24 xwa, (FDTest_String_TestTitleFunc_0xA8)
	calr FDTest_PrintDiag
	calr RegHamaTitle1_Entry
	jr TitleFunc_Return
	lda_24 xwa, (FDTest_String_TestTitleFunc_0xB4)
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
	lda_24 xwa, (FDTest_String_TestTitleFunc_0xDC)
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
	lda_24 xwa, (FDTest_String_TestTitleFunc_0xEA)
	calr FDTest_PrintDiag
	ldw_da de, (0x03dcfe)
	exts xde
	ld xwa, 0x00fc0001
	ld xbc, 0x01c0000f
	call ApPostEvent
	ldw_da de, (0x03dd00)
	exts xde
	ld xwa, 0x00fc0003
	ld xbc, 0x01c0000f
	call ApPostEvent
	ldw_da de, (0x03dd02)
	exts xde
	ld xwa, 0x00fc0002
	ld xbc, 0x01c0000f
	jp ApPostEvent

; CreateAndRunFDOperation -- Builds a 16-byte parameter struct on the stack,
; calls 0xf97cca to execute the FD operation, then prints success/failure.
CreateRunFDOp_Entry:
	lda xsp, (xsp - 16)
	lda_24 xwa, (FDTest_String_TestTitleFunc_0xFA)
	calr FDTest_PrintDiag
	.byte 0xbf, 0x00, 0x02, 0x00, 0x00	; ldw (xsp + 0), 0x0 (force d8 displacement)
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
	lda_24 xwa, (FDTest_String_TestTitleFunc_0x100)
	calr FDTest_PrintDiag
	jr CreateRunFDOp_Return
CreateRunFDOp_Fail:
	lda_24 xwa, (FDTest_String_TestTitleFunc_0x104)
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
	lda_24 xwa, (FDTest_String_TestTitleFunc_0x204)
	call FileIO_CheckPathAndVolumeLabel
	lds hl, 0
	ret

; RegisterHamaTitle2 -- Registers title with widget table 0xfc (extension APR test)
; Calls 0xf51e4f with WA=3, then 0xf5289c with string at 0xe1ff4c
RegHamaTitle2_Entry:
	lds wa, 3
	call format_FD
	lda_24 xwa, (FDTest_String_TestTitleFunc_0x20E)
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
	lda_24 xwa, (FDTest_String_TestTitleFunc_0x21A)
	calr SendEvent_Entry
	calr CheckFDStatusLoad_Entry
	lda_24 xwa, (FDTest_String_TestTitleFunc_0x220)
	calr SendEvent_Entry
	jr HamaEvtDisp_Return
HamaEvtDisp_ExtBootstrap:
	lda_24 xwa, (FDTest_String_TestTitleFunc_0x22A)
	calr SendEvent_Entry
	calr LoadExtROM_Entry
	lda_24 xwa, (FDTest_String_TestTitleFunc_0x22E)
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
	lda_24 xwa, (FDTest_String_TestTitleFunc_0x236)
	calr SendEvent_Entry
	jr CheckFDStatusLoad_Return
CheckFDStatusLoad_DoLoad:
	lda_24 xwa, (FDTest_String_TestTitleFunc_0x242)
	push xwa
	pushw 0xe1
	pushw 0xff84
	call FileOpen
	inc 8, xsp
	ld xiz, xhl
	or xiz, xiz
	jr nz, CheckFDStatusLoad_Transfer
	lda_24 xwa, (FDTest_String_TestTitleFunc_0x252)
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
	lda_24	xwa, (14811042)
	jrl	-217
LoadExtROM_JumpEntry:
	ld xhl, 0x200008
	lda_24 xwa, (0x027ed2)
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
	lda_24 xwa, (0x027ed2)
	call (xhl)
	ret
