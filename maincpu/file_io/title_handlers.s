; =============================================================================
; file_io/title_handlers.asm - Load/Save Title Entry Handlers
; =============================================================================
; Entry point handlers for file manager dialogs.
;
; Key routines:
;   LoadTtlJgFunc, SaveTtlJgFunc     - Load/Save title handlers
;   SaveSmfTtlJgFunc                 - SMF save handler
;   DirectPlayTtlJgFunc              - Direct play handler
;   SongMedleyTtlJgFunc              - Song medley handler
;   SetupFlashFunc                   - Flash setup
;   FmmUtilityTitleFunc              - File Manager utility menu
;   FmmSmfUtilityTitleFunc           - SMF utility menu
; =============================================================================

LoadTtlJgFunc:
	cp xbc, 0x1C00007
	jr nz, LABEL_F8B808
	ldw wa, 0x61
	ldw bc, 0x64
	calr LABEL_F8B36E

LABEL_F8B808:
	lds32 xhl, 0
	ret

SaveTtlJgFunc:
	cp xbc, 0x1C00007
	jr nz, LABEL_F8B819
	ldw wa, 0x67
	calr LABEL_F8B435

LABEL_F8B819:
	lds32 xhl, 0
	ret

SaveSmfTtlJgFunc:
	cp xbc, 0x1C00007
	jr nz, LABEL_F8B82A
	ldw wa, 0x6B
	calr LABEL_F8B435

LABEL_F8B82A:
	lds32 xhl, 0
	ret

DirectPlayTtlJgFunc:
	cp xbc, 0x1C00007
	call_24 z, 0xF8B3D8
	lds32 xhl, 0
	ret

SongMedleyTtlJgFunc:
	cp xbc, 0x1C00007
	jr nz, LABEL_F8B849
	ldw wa, 0x77
	calr LABEL_F8B435

LABEL_F8B849:
	lds32 xhl, 0
	ret

SetupFlashFunc:
	cp xbc, 0x1E5000C
	jr z, LABEL_F8B87C
	cp xbc, 0x1E5000B
	jr nz, LABEL_F8B882
	stdi8 32578, 37
	ldw wa, 0xEE
	call LABEL_F994BD
	lds wa, 6
	call LABEL_FC55A9
	stdi8 32578, 35
	ldw wa, 0xEE
	call LABEL_F994BD
	jr LABEL_F8B882

LABEL_F8B87C:
	lds wa, 6
	call LABEL_FC5625

LABEL_F8B882:
	lds32 xhl, 0
	ret

FmmUtilityTitleFunc:
	cp xbc, 0x1C00013
	jrl nz, LABEL_F8BA11
	cp xde, 0x3
	jrl z, LABEL_F8BA0E
	cp xde, 0x2
	jrl nz, LABEL_F8BA11
	stdi8 34046, 0
	lds wa, 1
	calr InitializeOperationState
	ld xwa, 0x7B0013
	ld xbc, 0x1E50005
	lds32 xde, 0
	call 0xFA9E07
	ldmm8 32604, 36151
	cpdi16 34048, 0
	jr ge, LABEL_F8B8D5
	call 0xF89520
	extz hl
	stda16 34048, xhl
	calr SignalProgressUpdate

LABEL_F8B8D5:
	ldda16 xwa, 34048
	cps wa, 1
	jrl z, LABEL_F8B9A1
	cps wa, 0
	jrl z, LABEL_F8B988
	cps wa, 5
	jr z, LABEL_F8B944
	cpdi16 34050, 0
	jr ge, LABEL_F8B902
	call 0xF8987D
	stda16 34050, xhl
	call LABEL_F8958D
	call 0xF8953B
	calr SignalProgressUpdate

LABEL_F8B902:
	cpdi16 34050, 0
	jrl nz, LABEL_F8B9EC
	cpdi16 34052, 0
	jr ge, LABEL_F8B91E
	call 0xF89C78
	stda16 34052, xhl
	calr SignalProgressUpdate

LABEL_F8B91E:
	cpdi16 34052, 0
	jrl le, LABEL_F8B9EC
	cpdi8 32604, 124
	jrl z, LABEL_F8B9EC
	ld xwa, 0x7B0013
	ld xbc, 0x1E50006
	lds32 xde, 0
	call 0xFA9E07
	ldw wa, 0x7C
	jr LABEL_F8B99B

LABEL_F8B944:
	ld xwa, 0x7B0013
	ld xbc, 0x1E50006
	lds32 xde, 0
	call 0xFA9E07
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call 0xFA9D58
	ldda8 a, 32604
	extz wa
	call 0xF99490
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call 0xFA9D58
	stdi8 32578, 0
	ldw wa, 0xEE
	jr LABEL_F8B9E6

LABEL_F8B988:
	ld xwa, 0x7B0013
	ld xbc, 0x1E50006
	lds32 xde, 0
	call 0xFA9E07
	ldw wa, 0x7D

LABEL_F8B99B:
	call 0xF99490
	jr LABEL_F8BA11

LABEL_F8B9A1:
	calr ResetProgressIndication
	ld xwa, 0x7B0013
	ld xbc, 0x1E50006
	lds32 xde, 0
	call 0xFA9E07
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call 0xFA9D58
	ldda8 a, 32604
	extz wa
	call 0xF99490
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call 0xFA9D58
	stdi8 32578, 2
	ldw wa, 0xEE

LABEL_F8B9E6:
	call LABEL_F994BD
	jr LABEL_F8BA11

LABEL_F8B9EC:
	ld xwa, 0x7B0013
	ld xbc, 0x1E50006
	lds32 xde, 0
	call 0xFA9E07
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0000A
	lds32 xde, 0
	call 0xFA9D58
	jr LABEL_F8BA11

LABEL_F8BA0E:
	calr CancelOperationCleanup

LABEL_F8BA11:
	lds32 xhl, 0
	ret

FmmSmfUtilityTitleFunc:
	cp xbc, 0x1C00013
	jrl nz, LABEL_F8BBA0
	cp xde, 0x3
	jrl z, LABEL_F8BB9D
	cp xde, 0x2
	jrl nz, LABEL_F8BBA0
	stdi8 34046, 0
	lds wa, 1
	calr InitializeOperationState
	ld xwa, 0x7B002A
	ld xbc, 0x1E50005
	lds32 xde, 0
	call 0xFA9E07
	ldmm8 32606, 36151
	cpdi16 34048, 0
	jr ge, LABEL_F8BA64
	call 0xF89520
	extz hl
	stda16 34048, xhl
	calr SignalProgressUpdate

LABEL_F8BA64:
	ldda16 xwa, 34048
	cps wa, 1
	jrl z, LABEL_F8BB30
	cps wa, 0
	jrl z, LABEL_F8BB17
	cps wa, 5
	jr z, LABEL_F8BAD3
	cpdi16 34052, 0
	jr ge, LABEL_F8BA91
	call 0xF89C78
	stda16 34052, xhl
	call LABEL_F8958D
	call 0xF8953B
	calr SignalProgressUpdate

LABEL_F8BA91:
	cpdi16 34052, 0
	jrl nz, LABEL_F8BB7B
	cpdi16 34050, 0
	jr ge, LABEL_F8BAAD
	call 0xF8987D
	stda16 34050, xhl
	calr SignalProgressUpdate

LABEL_F8BAAD:
	cpdi16 34050, 0
	jrl le, LABEL_F8BB7B
	cpdi8 32606, 123
	jrl z, LABEL_F8BB7B
	ld xwa, 0x7B002A
	ld xbc, 0x1E50006
	lds32 xde, 0
	call 0xFA9E07
	ldw wa, 0x7B
	jr LABEL_F8BB2A

LABEL_F8BAD3:
	ld xwa, 0x7B002A
	ld xbc, 0x1E50006
	lds32 xde, 0
	call 0xFA9E07
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call 0xFA9D58
	ldda8 a, 32606
	extz wa
	call 0xF99490
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call 0xFA9D58
	stdi8 32578, 0
	ldw wa, 0xEE
	jr LABEL_F8BB75

LABEL_F8BB17:
	ld xwa, 0x7B002A
	ld xbc, 0x1E50006
	lds32 xde, 0
	call 0xFA9E07
	ldw wa, 0x7D

LABEL_F8BB2A:
	call 0xF99490
	jr LABEL_F8BBA0

LABEL_F8BB30:
	calr ResetProgressIndication
	ld xwa, 0x7B002A
	ld xbc, 0x1E50006
	lds32 xde, 0
	call 0xFA9E07
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call 0xFA9D58
	ldda8 a, 32606
	extz wa
	call 0xF99490
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call 0xFA9D58
	stdi8 32578, 2
	ldw wa, 0xEE

LABEL_F8BB75:
	call LABEL_F994BD
	jr LABEL_F8BBA0

LABEL_F8BB7B:
	ld xwa, 0x7B002A
	ld xbc, 0x1E50006
	lds32 xde, 0
	call 0xFA9E07
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0000A
	lds32 xde, 0
	call 0xFA9D58
	jr LABEL_F8BBA0

LABEL_F8BB9D:
	calr CancelOperationCleanup

LABEL_F8BBA0:
	lds32 xhl, 0
	ret

