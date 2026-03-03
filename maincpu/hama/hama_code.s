.macro RegObjTableHama ParamA, ParamB, ParamC, ParamD, ParamE
	.if \ParamA <= 7
	lds32 xwa, \ParamA
	.else
	ld xwa, \ParamA
	.endif
	ld (xsp + 256), xwa
	lda_24 xwa, \ParamB
	ld (xsp + 4), xwa
	ld16_24 xwa, \ParamC
	ld (xsp + 8), wa
	lda_24 xwa, \ParamD
	ld (xsp + 10), xwa
	mrid2 0xB7, 0x30
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
	lda_24 xwa, \ParamB
	ld (xsp + 4), xwa
	ldw (xsp + 8), \ParamC
	lda_24 xwa, \ParamD
	ld (xsp + 10), xwa
	mrid2 0xB7, 0x30
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
	lda_24 xwa, \ParamB
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
;   "TT_HDDEXT" (0xE1FD18) - FDD/HD extension test, widget table 0x7f
;   "TT_EXTAPR" (0xE1FD22) - Extension APR test, widget table 0xfc
; Both titles use TestTitleFunc (0xF1E39A) as their lifecycle callback.
; Title handler (TestTitleFunc) pointer is stored at 0xE1FD2C in fd_test_data.s.
InitializeHama:
	lda xsp, (xsp - 14)

	RegObjTableHama 0x1600004, 0xFA44E2, 0xE1F0BC, 0xE1F080, 0x169
	RegObjTableHama 0x160000c, 0xFA58FB, 0xE1F0D4, 0xE1F0BE, 0x1c9
	RegObjTableHama 0x160000d, 0xFA5948, 0xE1F0EA, 0xE1F0D6, 0x1e9
	RegObjTablHama 0x1600002, 0xFA496C, 0x2, 0xE1F04A, 0x129
	RegObjTablHama 0x1600002, 0xFA496C, 0x2, 0xE1F056, 0x429
	RegObjTablHama 0x1600001, 0xFA48A9, 0x4b, 0xE1F0EC, 0x109
	RegObjTablHama 0x1600001, 0xFA48A9, 0x4b, 0xE1F240, 0x409
	RegObjTablHama 0x1600003, 0xFA4A18, 0x1, 0xE1FD2C, 0x149
	RegObjTablHama 0x1600003, 0xFA4A18, 0x1, 0xE1FD34, 0x449
	RegObjTablHama 0x1600010, 0xFA5995, 0x0, 0xE1FBD0, 0x7f
	RegObjTablHama 0x160000f, 0xFA62CB, 0x0, 0xE1FC40, 0x37f
	RegObjTablHama 0x1600010, 0xFA5995, 0x1a, 0xE1FBD4, 0xfc
	RegObjTablHama 0x160000f, 0xFA62CB, 0x1a, 0xE1FC46, 0x3fc

	RegTitleHama 0x9, 0xE1FD18, 0x7f, 0x1490000, 0xfc0000
	RegTitleHama 0x9, 0xE1FD22, 0xfc, 0x1490000, 0xfc0000

	lda xsp, (xsp + 14)
	ret

FDTest_PrintDiag:
	jp LABEL_FFFEA1

; TestTitleFunc - Title lifecycle and action handler for FD diagnostic tests
; Dispatches on two event codes:
;   0x1C00007 (title lifecycle): xde selects handler from jump table at 0xE1FDFE
;     0=new, 1=old, 2=activate, 3=inactivate, 4-5=interrupt, 6=TBIOS test
;   0x1C00013 (user actions): xde selects handler from jump table at 0xE1FE0E
;     2=STOP, 3=START LOOP, 4=DIR listing, 5-6=debug test
TestTitleFunc:
	push xiz
	ld xiz, xwa
	lds wa, 0
	cp xbc, 0x1C00007
	jr z, LABEL_F1E41C
	cp xbc, 0x1C00013
	jrl nz, LABEL_F1E4BD
	ld xwa, xde
	dec 2, xwa
	cp xwa, 0x0
	jrl c, LABEL_F1E4BD
	cp xwa, 0x5
	jrl ugt, LABEL_F1E4BD
	add xwa, xwa
	add xwa, 0xE1FE0E
	ld wa, (xwa)
	lda_24 xix, 0xf1e3da
	jp_dri 8, 0x07, 0xF0, 0xE0

; User action dispatch table (event 0x1C00013, xde=2..6)
; Each entry loads a string address and calls FDTest_PrintDiag, then exits
LABEL_F1E3DA:
	lda_24 xwa, 0xe1fd4c
	calr FDTest_PrintDiag
	jrl LABEL_F1E4BD
	lda_24 xwa, 0xe1fd58
	calr FDTest_PrintDiag
	jrl LABEL_F1E4BD
	lda_24 xwa, 0xe1fd64
	calr FDTest_PrintDiag
	jrl LABEL_F1E4BD
	lda_24 xwa, 0xe1fd74
	calr FDTest_PrintDiag
	jrl LABEL_F1E4BD
	lda_24 xwa, 0xe1fd86
	calr FDTest_PrintDiag
	jrl LABEL_F1E4BD
	lda_24 xwa, 0xe1fd96
	calr FDTest_PrintDiag
	jrl LABEL_F1E4BD

LABEL_F1E41C:
	ld xwa, xde
	cp xwa, 0x7
	jrl ugt, LABEL_F1E4BD
	add xwa, xwa
	add xwa, 0xE1FDFE
	ld wa, (xwa)
	lda_24 xix, 0xf1e43b
	jp_dri 8, 0x07, 0xF0, 0xE0

; Title lifecycle dispatch table (event 0x1C00007, xde=0..6)
; 0=new: print+call 0xF97EDB, 1=old: send event+call 0xFAA257
; 2=activate: run test stats+call 0xFAA135, 3=inactivate: print+DIR listing
; 4=interrupt: print+call LABEL_F1E89A, 5=interrupt return: print+call LABEL_F1E8AC
; 6=TBIOS test: call LABEL_F1E4C1
LABEL_F1E43B:
	lda_24 xwa, 0xe1fdae
	calr FDTest_PrintDiag
	call 0xf97edb
	jr LABEL_F1E4BD
	ld xwa, 0x01c00007
	push xwa
	lds32 xwa, 2
	push xwa
	ld xbc, xiz
	lds32 xwa, 0
	ld xde, 0xffffffff
	call 0xfaa257
	lda_24 xwa, 0xe1fdba
	calr FDTest_PrintDiag
	lds wa, 0
	jr LABEL_F1E4BD
	lda_24 xwa, 0xe1fdca
	calr FDTest_PrintDiag
	calr LABEL_F1E51B
	ld xwa, 0x01c00007
	push xwa
	lds32 xwa, 2
	push xwa
	ld xbc, xiz
	ld xwa, 0x53
	ld xde, 0xffffffff
	call 0xfaa135
	lds wa, 1
	jr LABEL_F1E4BD
	lda_24 xwa, 0xe1fde0
	calr FDTest_PrintDiag
	calr FDListDirectory
	jr LABEL_F1E4BD
	lda_24 xwa, 0xe1fde6
	calr FDTest_PrintDiag
	calr LABEL_F1E89A
	jr LABEL_F1E4BD
	lda_24 xwa, 0xe1fdf2
	calr FDTest_PrintDiag
	calr LABEL_F1E8AC
	jr LABEL_F1E4BD
	calr LABEL_F1E4C1

LABEL_F1E4BD:
	lds32 xhl, 0
	pop xiz
	ret

; ListDirectoryEntries2 — Opens directory, iterates all entries via
; ReadNextEntry, logging each via FDTest_PrintDiag. Similar to FDListDirectory
; but uses format string at 0xE1FE1A and compares dir handle against xiz directly.
; Args: (xsp+4) = directory path string pointer
; Returns: hl = 0 on success, 0xFFFF on open failure
; Stack frame: 266 bytes
LABEL_F1E4C1:
	lda xsp, (xsp - 266)
	push xiz
	lda_24 xwa, 0xe1fe1a
	lda xbc, (xsp + 4)
	call 0xf5298a
	ld xiz, xhl
	cp xiz, 0xffffffff
	jr nz, LABEL_F1E4E2
	ldw hl, 0xffff
	jr LABEL_F1E514
LABEL_F1E4E2:
	lda xwa, (xsp + 10)
	calr FDTest_PrintDiag
	ld xbc, (xsp + 4)
	ld xwa, xiz
	call 0xf52ae8
	cp hl, 0xffff
	jr z, LABEL_F1E50C
LABEL_F1E4F7:
	lda xwa, (xsp + 10)
	calr FDTest_PrintDiag
	ld xbc, (xsp + 4)
	ld xwa, xiz
	call 0xf52ae8
	cp hl, 0xffff
	jr nz, LABEL_F1E4F7
LABEL_F1E50C:
	ld xwa, xiz
	call 0xf52aaa
	lds hl, 0
LABEL_F1E514:
	pop xiz
	lda xsp, (xsp + 266)
	ret

; RunTestAndUpdateCounters — Checks FD status (0xF525EC), runs FDLoadSaveTest
; if status is 2 or 3, increments TOTAL/OK/NG counters at 0x03DCFE-0x03DD02,
; then displays updated counts via NAKA widget system (0xFA9D58).
; Returns: l = 0xFF if status invalid, otherwise falls through to display
LABEL_F1E51B:
	call 0xf525ec
	cps l, 3
	jr z, LABEL_F1E527
	cps l, 2
	jr nz, LABEL_F1E53A
LABEL_F1E527:
	incdi16_24 1, 0x03dcfe
	calr FDLoadSaveTest
	cps hl, 0
	jr nz, LABEL_F1E53D
	incdi16_24 1, 0x03dd00
	jr LABEL_F1E542
LABEL_F1E53A:
	ldb l, 0xff
	ret
LABEL_F1E53D:
	incdi16_24 1, 0x03dd02
LABEL_F1E542:
	lda_24 xwa, 0xe1fe28
	calr FDTest_PrintDiag
	ld16_24 de, 0x03dcfe
	exts xde
	ld xwa, 0x00fc0001
	ld xbc, 0x01c0000f
	call 0xfa9d58
	ld16_24 de, 0x03dd00
	exts xde
	ld xwa, 0x00fc0003
	ld xbc, 0x01c0000f
	call 0xfa9d58
	ld16_24 de, 0x03dd02
	exts xde
	ld xwa, 0x00fc0002
	ld xbc, 0x01c0000f
	jp 0xfa9d58

; CreateAndRunFDOperation — Builds a 16-byte parameter struct on the stack,
; calls 0xF97CCA to execute the FD operation, then prints success/failure.
LABEL_F1E589:
	lda xsp, (xsp - 16)
	lda_24 xwa, 0xe1fe38
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
	call 0xf97cca
	inc 4, xsp
	cps hl, 0
	jr nz, LABEL_F1E5CE
	lda_24 xwa, 0xe1fe3e
	calr FDTest_PrintDiag
	jr LABEL_F1E5D6
LABEL_F1E5CE:
	lda_24 xwa, 0xe1fe42
	calr FDTest_PrintDiag
LABEL_F1E5D6:
	lda xsp, (xsp + 16)
	ret

.include "hama/fd_test_code.s"

; RegisterHamaTitle1 — Registers title with widget table 0x7F (FDD/HD test)
; Calls 0xF51E4F with WA=2, then 0xF5289C with string at 0xE1FF42
LABEL_F1E89A:
	lds wa, 2
	call 0xf51e4f
	lda_24 xwa, 0xe1ff42
	call 0xf5289c
	lds hl, 0
	ret

; RegisterHamaTitle2 — Registers title with widget table 0xFC (extension APR test)
; Calls 0xF51E4F with WA=3, then 0xF5289C with string at 0xE1FF4C
LABEL_F1E8AC:
	lds wa, 3
	call 0xf51e4f
	lda_24 xwa, 0xe1ff4c
	call 0xf5289c
	lds hl, 0
	ret

; SendEventWithParam — Sends event 0x1C00025 with xwa as parameter via 0xFA9660
; Args: xwa = event parameter (moved to xde)
LABEL_F1E8BE:
	ld xde, xwa
	ld xwa, 0xffffffff
	ld xbc, 0x01c00025
	jp 0xfa9660

; HamaEventDispatcher — Dispatches events for HAMA subsystem
; Handles 0x1C00007 (title lifecycle) and 0x1E00085 (extension event)
; For 0x1C00007: dispatches on xde (0x8A=file ops, 0x8B=extension bootstrap)
LABEL_F1E8CE:
	cp xbc, 0x01c00007
	jr z, LABEL_F1E8E1
	cp xbc, 0x01e00085
	jr nz, LABEL_F1E919
	lds32 xhl, 0
	ret
LABEL_F1E8E1:
	cp xde, 0x8b
	jr z, LABEL_F1E906
	cp xde, 0x8a
	jr nz, LABEL_F1E919
	lda_24 xwa, 0xe1ff58
	calr LABEL_F1E8BE
	calr LABEL_F1E91C
	lda_24 xwa, 0xe1ff5e
	calr LABEL_F1E8BE
	jr LABEL_F1E919
LABEL_F1E906:
	lda_24 xwa, 0xe1ff68
	calr LABEL_F1E8BE
	calr LABEL_F1E972
	lda_24 xwa, 0xe1ff6c
	calr LABEL_F1E8BE
LABEL_F1E919:
	lds32 xhl, 0
	ret

; CheckFDStatusAndLoadFile — Checks FD status, loads file from disk into
; extension DRAM (0x200000) if status is 2 or 3
LABEL_F1E91C:
	push xiz
	call 0xf525ec
	extz hl
	cps hl, 2
	jr z, LABEL_F1E935
	cps hl, 3
	jr z, LABEL_F1E935
	lda_24 xwa, 0xe1ff74
	calr LABEL_F1E8BE
	jr LABEL_F1E970
LABEL_F1E935:
	lda_24 xwa, 0xe1ff80
	push xwa
	pushw 0xe1
	pushw 0xff84
	call 0xf4eb97
	inc 8, xsp
	ld xiz, xhl
	or xiz, xiz
	jr nz, LABEL_F1E957
	lda_24 xwa, 0xe1ff90
	calr LABEL_F1E8BE
	jr LABEL_F1E970
LABEL_F1E957:
	push xiz
	pushw 0x8000
	pushw 0x1
	ld xwa, 0x200000
	push xwa
	call 0xf4ee70
	push xiz
	call 0xf4f05a
	lda xsp, (xsp + 16)
LABEL_F1E970:
	pop xiz
	ret

; LoadExtensionROM — Loads 4 bytes from extension ROM path at 0xE1FF9C
; into DRAM at 0x200000, checks result, jumps to extension entry point
LABEL_F1E972:
	pushw 0x4
	pushw 0xe1
	pushw 0xff9c
	ld xwa, 0x200000
	push xwa
	call 0xff0cc1
	add xsp, 0xa
	cps hl, 0
	jr z, LABEL_F1E997
	lda_24 xwa, 0xe1ffa2
	jrl LABEL_F1E8BE
LABEL_F1E997:
	ld xhl, 0x200008
	lda_24 xwa, 0x027ed2
	jp (xhl)

LABEL_F1E9A3:
	ld8_24 l, 0x03dd04
	ret

LABEL_F1E9A9:
	pushw 0x4	; 4 bytes
	pushw 0xE1
	pushw 0xFFB0	; "XAPR"
	ld xwa, 0x280000
	push xwa
	call 0xFF0CC1
	add xsp, 0xA
	cps hl, 0
	ret nz
	sti8_24 0x03dd04, 0x01
	ret

LABEL_F1E9CD:
	ret

LABEL_F1E9CE:
	ret

LABEL_F1E9CF:
	ret

LABEL_F1E9D0:
	cpi8_24 0x03dd04, 0x00
	ret z
	ld xhl, 0x280010
	call (xhl)
	ret

LABEL_F1E9E0:
	pushw 0x4	; 4 bytes
	pushw 0xE1
	pushw 0xFFC6	; "XAPR"
	ld xwa, 0x280000
	push xwa
	call 0xFF0CC1
	add xsp, 0xA
	cps hl, 0
	jr nz, LABEL_F1EA05
	sti8_24 0x03dd04, 0x01
	jr LABEL_F1EA0B

LABEL_F1EA05:
	sti8_24 0x03dd04, 0x00

LABEL_F1EA0B:
	cpi8_24 0x03dd04, 0x00
	ret z
	ld xhl, 0x280008
	lda_24 xwa, 0x027ed2
	call (xhl)
	ret
