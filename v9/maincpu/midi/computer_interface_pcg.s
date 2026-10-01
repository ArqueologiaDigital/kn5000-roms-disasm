; =============================================================================
; computer_interface_pcg.asm - Computer Interface PCG Output
; =============================================================================
; This file contains PCG (Program Change) Output routines for the
; Computer Interface subsystem:
;   TtMdPcgOut            - PCG Output title handler
;   AcPcgOutGridBoxProc   - PCG Output grid box action processor
;   PcgOutGridCheck       - PCG Output grid validation
;   PcgOutSendFunc        - PCG Output send function handler
;   MainPcgOutSend        - Main PCG Output send dispatcher
;
; =============================================================================

TtMdPcgOut:
	cp xbc, 0x1c0000c
	jr z, TtMdPcgOut_Exit
	cp xbc, 0x1c0000b
	jr z, TtMdPcgOut_Exit
	cp xbc, EVT_SELECT_CONFIRM
	jr z, TtMdPcgOut_Exit
	cp xbc, EVT_MENU_OPEN
	jr nz, TtMdPcgOut_Exit
	or xde, xde
	jr nz, TtMdPcgOut_Exit
	ld xwa, 0x590001
	call GetViewInstance
	ld xwa, (xhl + 42)
	ldw (xwa), 0x0
	ld xwa, (xhl + 46)
	ldw (xwa), 0x1

TtMdPcgOut_Exit:
	ld xhl, 0:i3
	ret

AcPcgOutGridBoxProc:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 12), xde
	ld (xsp + 16), xbc
	ld xiz, xwa
	ld xbc, (xsp + 16)
	cp xbc, 0x1e0008d
	jrl z, PcgOutGrid_DispatchDelegate
	ld xwa, (xsp + 16)
	cp xwa, 0x1e0008b
	jrl z, PcgOutGrid_CopyStrBank1
	cp xwa, 0x1e0008a
	jrl z, PcgOutGrid_CopyStrBank0
	cp xwa, EVT_MENU_OPEN
	jr z, PcgOutGridBoxEventDispatch
	sub xbc, 0x1c00017
	cp xbc, 0x0
	jrl lt, PcgOutGrid_DefaultHandler
	cp xbc, 0x6
	jrl gt, PcgOutGrid_DefaultHandler
	add xbc, xbc
	add xbc, NakaInst_INITIAL_0x28
	ld bc, (xbc)
	lda xix, (PcgOutGridBoxEventDispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe4

PcgOutGridBoxEventDispatch:
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, xiz
	ld xbc, EVT_OBJECT_STATE_QUERY
	ld xde, 0:i3
	call SendEvent
	ld (xsp + 4), xhl
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, 0x1c00017
	call SetDialUp
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, 0x1c00018
	call SetDialDown
	ld wa, 1:i3
	jrl PcgOutGridDialConfirm
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1e00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, PcgOutGrid_CheckAltPrev
	ld xwa, xiz
	ld xbc, EVT_OBJECT_STATE_QUERY
	ld xde, 0:i3
	call SendEvent
	dec 1, hl
	extz xhl
	add xhl, 0xffff0000
	ld xwa, xiz
	ld xbc, 0x1c0000e
	ld xde, xhl
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl PcgOutGrid_ReturnZero

PcgOutGrid_CheckAltPrev:
	ld xwa, xiz
	ld xbc, 0x1e00091
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jrl z, PcgOutGrid_ReturnZero
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call ApFuncCall
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	ld xwa, xiz
	ld xbc, 0x1c00017
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, 0x1c00018
	ld xde, (xsp + 12)
	call SetDialDown
	ld wa, 1:i3
	jrl PcgOutGridDialConfirm
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1e00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, PcgOutGrid_CheckAltNext
	ld xwa, xiz
	ld xbc, EVT_OBJECT_STATE_QUERY
	ld xde, 0:i3
	call SendEvent
	cp hl, 3:i3
	jrl ge, PcgOutGrid_ReturnZero
	inc 1, hl
	extz xhl
	add xhl, 0xffff0000
	ld xwa, xiz
	ld xbc, 0x1c0000e
	ld xde, xhl
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl PcgOutGrid_ReturnZero

PcgOutGrid_CheckAltNext:
	ld xwa, xiz
	ld xbc, 0x1e00091
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jrl z, PcgOutGrid_ReturnZero
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call ApFuncCall
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	ld xwa, xiz
	ld xbc, 0x1c00017
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, 0x1c00018
	ld xde, (xsp + 12)
	call SetDialDown
	ld wa, 1:i3

PcgOutGridDialConfirm:
	call SetDialEnable
	jr PcgOutGrid_ReturnZero

PcgOutGrid_CopyStrBank0:
	ld xwa, xiz
	ld xiz, 0x3e
	jr PcgOutGrid_CopyStrCommon

PcgOutGrid_CopyStrBank1:
	ld xwa, xiz
	ld xiz, 0x42

PcgOutGrid_CopyStrCommon:
	call GetViewInstance
	add xhl, xiz
	ld xwa, (xhl)
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	jr PcgOutGrid_ReturnZero
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	jr PcgOutGrid_CallDelegate

PcgOutGrid_DispatchDelegate:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)

PcgOutGrid_CallDelegate:
	call ApFuncCall

PcgOutGrid_ReturnZero:
	ld xhl, 0:i3
	jr PcgOutGrid_Epilogue

PcgOutGrid_DefaultHandler:
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc

PcgOutGrid_Epilogue:
	pop xiz
	lda xsp, (xsp + 16)
	ret

PcgOutGridCheck:
	lda xsp, (xsp - 44)
	push xiz
	ld xiz, xde
	ld (xsp + 44), xbc
	ld xiy, UserMemory_FormatStrings_0x16
	lda xix, (xsp + 12)
	ld bc, 5:i3
	ldirw
	ld xiy, MidiPart_PageStr_1of3_0xA
	lda xix, (xsp + 4)
	ld bc, 4:i3
	ldirw
	ld xix, (xsp + 44)
	lda xiy, (xsp + 12)
	lda xhl, (xsp + 4)
	lda xbc, (xhl + 2)
	lda xde, (xhl + 4)
	ld xwa, (xsp + 44)
	cp xwa, 0x1e0008d
	jrl z, PcgOutCheckGridDataStructure
	ld xwa, xix
	sub xwa, 0x1c00017
	cp xwa, 0x0
	jrl lt, PcgOutGridCheckComplete
	cp xwa, 0x6
	jrl gt, PcgOutGridCheckComplete
	add xwa, xwa
	add xwa, UserMemory_FormatStrings_0xC0
	ld wa, (xwa)
	lda xix, (PcgOutGridCheckJumpTable:24)
	jp_ind 8, 0x07, 0xf0, 0xe0
PcgOutGridCheckJumpTable:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_OBJECT_STATE_QUERY
	ld	xde, 0:i3
	call	SendEvent
	ld	xiz, xhl
	lda	xwa, (xsp+4)
	ld	xbc, xiz
	srl	xbc, 0
	ld	qbc, 0
	ld	(xwa), bc
	ld	bc, iz
	ld	(xwa+2), bc
	cpw	(xwa), 1
	jrl	nz, PcgOutGridCheckComplete
	ld	xde, (xsp+44)
	cp	bc, 3:i3
	jrl	z, PcgOutGridCheckJumpTable_Skip5
	cp	bc, 2:i3
	jr	z, PcgOutGridCheckJumpTable_Entry
	cp	bc, 1:i3
	jr	z, PcgOutGridCheckJumpTable_Skip2
	cp	bc, 0:i3
	jrl	nz, PcgOutGridCheckComplete
	ld	xiy, 15204142
	lda	xix, (xsp+22)
	ldw	bc, 11
	ldirw
	lda	xwa, (xsp+22)
	lda	xbc, (149354:24)
	ld	(xwa), xbc
	ld	xbc, 15
	ld	(xwa+6), xbc
	cp	xde, 29360153
	jr	nz, PcgOutGridCheckJumpTable_Skip
	ld	xbc, 4:i3
	ld	(xwa+14), xbc
PcgOutGridCheckJumpTable_Skip:
	jrl	PcgOutGridCheckJumpTable_Join4
PcgOutGridCheckJumpTable_Skip2:
	ld	xiy, 15204142
	lda	xix, (xsp+22)
	ldw	bc, 11
	ldirw
	lda	xwa, (xsp+22)
	lda	xbc, (149356:24)
	ld	(xwa), xbc
	ld	xbc, 127
	ld	(xwa+6), xbc
	cp	xde, 29360153
	jr	nz, PcgOutGridCheckJumpTable_Skip3
	ld	xbc, 4:i3
	ld	(xwa+14), xbc
PcgOutGridCheckJumpTable_Skip3:
	jrl	PcgOutGridCheckJumpTable_Join4
PcgOutGridCheckJumpTable_Entry:
	cp	(0x24770:24), 255
	jrl	z, PcgOutGridCheckComplete
	ld	xiy, 15204142
	lda	xix, (xsp+22)
	ldw	bc, 11
	ldirw
	lda	xwa, (xsp+22)
	lda	xbc, (149358:24)
	ld	(xwa), xbc
	ld	xbc, 127
	ld	(xwa+6), xbc
	cp	xde, 29360153
	jr	nz, PcgOutGridCheckJumpTable_Skip4
	ld	xbc, 4:i3
	ld	(xwa+14), xbc
PcgOutGridCheckJumpTable_Skip4:
	jrl	PcgOutGridCheckJumpTable_Join4
PcgOutGridCheckJumpTable_Skip5:
	ld	xiy, 15204142
	lda	xix, (xsp+22)
	ldw	bc, 11
	ldirw
	lda	xwa, (xsp+22)
	lda	xbc, (149360:24)
	ld	(xwa), xbc
	ld	xbc, 127
	ld	(xwa+6), xbc
	ld	xbc, 4294967295
	ld	(xwa+10), xbc
	cp	xde, 29360153
	jr	nz, PcgOutGridCheckJumpTable_Skip6
	ld	xbc, 4:i3
	ld	(xwa+14), xbc
PcgOutGridCheckJumpTable_Skip6:
	jrl	PcgOutGridCheckJumpTable_Join4
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_OBJECT_STATE_QUERY
	ld	xde, 0:i3
	call	SendEvent
	ld	xiz, xhl
	lda	xwa, (xsp+4)
	ld	xbc, xiz
	srl	xbc, 0
	ld	qbc, 0
	ld	(xwa), bc
	ld	bc, iz
	ld	(xwa+2), bc
	cpw	(xwa), 1
	jrl	nz, PcgOutGridCheckComplete
	ld	xde, (xsp+44)
	cp	bc, 3:i3
	jrl	z, PcgOutGridCheckJumpTable_Skip11
	cp	bc, 2:i3
	jrl	z, PcgOutGridCheckJumpTable_Entry2
	cp	bc, 1:i3
	jr	z, PcgOutGridCheckJumpTable_Skip8
	cp	bc, 0:i3
	jrl	nz, PcgOutGridCheckComplete
	ld	xiy, 15204142
	lda	xix, (xsp+22)
	ldw	bc, 11
	ldirw
	lda	xwa, (xsp+22)
	lda	xbc, (149354:24)
	ld	(xwa), xbc
	ld	xbc, 15
	ld	(xwa+6), xbc
	lda	xhl, (xwa+14)
	cp	xde, 29360154
	jr	nz, PcgOutGridCheckJumpTable_Skip7
	ld	xbc, 4294967292
	ld	(xhl), xbc
	jr	PcgOutGridCheckJumpTable_Join
PcgOutGridCheckJumpTable_Skip7:
	ld	xbc, 4294967295
	ld	(xhl), xbc
PcgOutGridCheckJumpTable_Join:
	jrl	PcgOutGridCheckJumpTable_Join4
PcgOutGridCheckJumpTable_Skip8:
	ld	xiy, 15204142
	lda	xix, (xsp+22)
	ldw	bc, 11
	ldirw
	lda	xwa, (xsp+22)
	lda	xbc, (149356:24)
	ld	(xwa), xbc
	ld	xbc, 127
	ld	(xwa+6), xbc
	lda	xhl, (xwa+14)
	cp	xde, 29360154
	jr	nz, PcgOutGridCheckJumpTable_Skip9
	ld	xbc, 4294967292
	ld	(xhl), xbc
	jr	PcgOutGridCheckJumpTable_Join2
PcgOutGridCheckJumpTable_Skip9:
	ld	xbc, 4294967295
	ld	(xhl), xbc
PcgOutGridCheckJumpTable_Join2:
	jrl	PcgOutGridCheckJumpTable_Join4
PcgOutGridCheckJumpTable_Entry2:
	cp	(0x24770:24), 255
	jrl	z, PcgOutGridCheckComplete
	ld	xiy, 15204142
	lda	xix, (xsp+22)
	ldw	bc, 11
	ldirw
	lda	xwa, (xsp+22)
	lda	xbc, (149358:24)
	ld	(xwa), xbc
	ld	xbc, 127
	ld	(xwa+6), xbc
	lda	xhl, (xwa+14)
	cp	xde, 29360154
	jr	nz, PcgOutGridCheckJumpTable_Skip10
	ld	xbc, 4294967292
	ld	(xhl), xbc
	jr	PcgOutGridCheckJumpTable_Join3
PcgOutGridCheckJumpTable_Skip10:
	ld	xbc, 4294967295
	ld	(xhl), xbc
PcgOutGridCheckJumpTable_Join3:
	jr	PcgOutGridCheckJumpTable_Join4
PcgOutGridCheckJumpTable_Skip11:
	ld	xiy, 15204142
	lda	xix, (xsp+22)
	ldw	bc, 11
	ldirw
	lda	xwa, (xsp+22)
	lda	xbc, (149360:24)
	ld	(xwa), xbc
	ld	xbc, 127
	ld	(xwa+6), xbc
	ld	xbc, 4294967295
	ld	(xwa+10), xbc
	lda	xhl, (xwa+14)
	cp	xde, 29360154
	jr	nz, PcgOutGridCheckJumpTable_Skip12
	ld	xbc, 4294967292
	ld	(xhl), xbc
	jr	PcgOutGridCheckJumpTable_Join4
PcgOutGridCheckJumpTable_Skip12:
	ld	xbc, 4294967295
	ld	(xhl), xbc
PcgOutGridCheckJumpTable_Join4:
	call	MainRamAdd
	jrl	PcgOutGridCheckComplete
	ldw	(xhl), 1
	ld	xhl, xiy
	ld	(xde), xiy
	lda	xde, (149354:24)
	lda	xwa, (xiz+14)
	cp	xde, (xiz)
	jr	nz, PcgOutGridCheckJumpTable_Entry_Code_Skip
	ldw	(xbc), 0
	ld	xwa, (xwa)
	inc	1, xwa
	push	xwa
	pushw	231
	pushw	65358
	push	xhl
	call	Sprintf_Locked
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 0x1e0008c
	jrl	PcgOutCheck_SetFinalProp
PcgOutGridCheckJumpTable_Entry_Code_Skip:
	lda	xde, (0x2476c:24)
	cp	xde, (xiz)
	jr	nz, PcgOutGridCheckJumpTable_Entry_Code_Skip2
	ldw	(xbc), 1
	ld	xwa, (xwa)
	inc	1, xwa
	push	xwa
	pushw	231
	pushw	0xff54
	push	xhl
	call	Sprintf_Locked
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 0x1e0008c
	jrl	PcgOutCheck_SetFinalProp
PcgOutGridCheckJumpTable_Entry_Code_Skip2:
	lda	xde, (0x2476e:24)
	cp	xde, (xiz)
	jrl	nz, PcgOutGridCheckJumpTable_Entry_Code_Skip4
	ldw	(xbc), 2
	cp	(0x24770:24), 255
	jr	nz, PcgOutGridCheckJumpTable_Entry_Code_Skip3
	pushw	231
	pushw	0xff5a
	push	xhl
	call	Strcpy
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 0x1e0008c
	call	SendEvent
	ldw	(xsp+6), 4
	pushw	231
	pushw	0xff60
	lda	xwa, (xsp+16)
	push	xwa
	call	Strcpy
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 0x1e0008c
	jrl	PcgOutCheck_SetFinalProp
PcgOutGridCheckJumpTable_Entry_Code_Skip3:
	ld	xwa, (xwa)
	push	xwa
	pushw	231
	pushw	0xff68
	push	xhl
	call	Sprintf_Locked
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 0x1e0008c
	call	SendEvent
	ldw	(xsp+6), 4
	ld	c, (0x24770:24)
	exts	bc
	ld	xwa, (xiz+14)
	sll	wa, 7
	add	wa, bc
	pushw	wa
	pushw	231
	pushw	0xff6e
	lda	xwa, (xsp+18)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 0x1e0008c
	jrl	PcgOutCheck_SetFinalProp
PcgOutGridCheckJumpTable_Entry_Code_Skip4:
	lda	xde, (0x24770:24)
	cp	xde, (xiz)
	jrl	nz, PcgOutGridCheckComplete
	ldw	(xbc), 2
	ld	xwa, (xwa)
	cp	xwa, 0xffffffff
	jr	nz, PcgOutGridCheckJumpTable_Entry_Code_Skip5
	pushw	231
	pushw	0xff76
	push	xhl
	call	Strcpy
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 0x1e0008c
	call	SendEvent
	ldw	(xsp+6), 3
	pushw	231
	pushw	0xff7c
	lda	xwa, (xsp+16)
	push	xwa
	call	Strcpy
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 0x1e0008c
	call	SendEvent
	ldw	(xsp+6), 4
	pushw	231
	pushw	0xff82
	lda	xwa, (xsp+16)
	push	xwa
	call	Strcpy
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 0x1e0008c
	jrl	PcgOutCheck_SetFinalProp
PcgOutGridCheckJumpTable_Entry_Code_Skip5:
	ld	a, (0x2476e:24)
	exts	wa
	pushw	wa
	pushw	231
	pushw	0xff8a
	push	xhl
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 0x1e0008c
	call	SendEvent
	ldw	(xsp+6), 3
	ld	xwa, (xiz+14)
	push	xwa
	pushw	231
	pushw	0xff90
	lda	xwa, (xsp+20)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 0x1e0008c
	call	SendEvent
	ldw	(xsp+6), 4
	ld	xbc, (xiz+14)
	ld	a, (0x2476e:24)
	exts	wa
	sll	wa, 7
	add	wa, bc
	pushw	wa
	pushw	231
	pushw	0xff96
	lda	xwa, (xsp+18)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 0x1e0008c
	jrl	PcgOutCheck_SetFinalProp

PcgOutCheckGridDataStructure:
	ld xwa, xiz
	srl xwa, 0
	ldiw_erp 0xe2, 0
	ld (xhl), wa
	ld xwa, xbc
	ld ix, iz
	ld (xbc), ix
	ld xbc, xiy
	ld (xde), xiy
	cpw (xhl), 0x1
	jrl nz, PcgOutGridCheckComplete
	ld de, (xwa)
	cp de, 3:i3
	jrl z, PcgOutCheck_SendPreset3
	cp de, 2:i3
	jr z, PcgOutCheck_SendPreset2
	cp de, 1:i3
	jr z, PcgOutCheck_SendPreset1
	cp de, 0:i3
	jrl nz, PcgOutGridCheckComplete
	ld a, (0x02476a:24)
	inc 1, a
	extz wa
	pushw wa
	pushw 0xe7
	pushw 0xff9e
	push xbc
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 4)
	ld xbc, 0x1e0008c
	jrl PcgOutCheck_SetFinalProp

PcgOutCheck_SendPreset1:
	ld a, (0x02476c:24)
	inc 1, a
	extz wa
	pushw wa
	pushw 0xe7
	pushw 0xffa4
	push xbc
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 4)
	ld xbc, 0x1e0008c
	jrl PcgOutCheck_SetFinalProp

PcgOutCheck_SendPreset2:
	cp (0x024770:24), 0xff
	jr nz, PcgOutCheck_SendPreset2Named
	pushw 0xe7
	pushw 0xffaa
	push xbc
	call Strcpy
	inc 8, xsp
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 4)
	ld xbc, 0x1e0008c
	call SendEvent
	ldw (xsp + 6), 0x4
	pushw 0xe7
	pushw 0xffb0
	lda xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 4)
	ld xbc, 0x1e0008c
	jrl PcgOutCheck_SetFinalProp

PcgOutCheck_SendPreset2Named:
	ld a, (0x02476e:24)
	exts wa
	pushw wa
	pushw 0xe7
	pushw 0xffb8
	push xbc
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 4)
	ld xbc, 0x1e0008c
	call SendEvent
	ldw (xsp + 6), 0x4
	ld c, (0x024770:24)
	exts bc
	ld a, (0x02476e:24)
	exts wa
	sll wa, 7
	add wa, bc
	pushw wa
	pushw 0xe7
	pushw 0xffbe
	lda xwa, (xsp + 18)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 4)
	ld xbc, 0x1e0008c
	jrl PcgOutCheck_SetFinalProp

PcgOutCheck_SendPreset3:
	ldw (xwa), 0x2
	cp (0x024770:24), 0xff
	jr nz, PcgOutCheck_SendPreset3Named
	pushw 0xe7
	pushw 0xffc6
	push xbc
	call Strcpy
	inc 8, xsp
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 4)
	ld xbc, 0x1e0008c
	call SendEvent
	ldw (xsp + 6), 0x3
	pushw 0xe7
	pushw 0xffcc
	lda xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 4)
	ld xbc, 0x1e0008c
	call SendEvent
	ldw (xsp + 6), 0x4
	pushw 0xe7
	pushw 0xffd2
	lda xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 4)
	ld xbc, 0x1e0008c
	jrl PcgOutCheck_SetFinalProp

PcgOutCheck_SendPreset3Named:
	ld a, (0x02476e:24)
	exts wa
	pushw wa
	pushw 0xe7
	pushw 0xffda
	push xbc
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 4)
	ld xbc, 0x1e0008c
	call SendEvent
	ldw (xsp + 6), 0x3
	ld a, (0x024770:24)
	exts wa
	pushw wa
	pushw 0xe7
	pushw 0xffe0
	lda xwa, (xsp + 18)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 4)
	ld xbc, 0x1e0008c
	call SendEvent
	ldw (xsp + 6), 0x4
	ld c, (0x024770:24)
	exts bc
	ld a, (0x02476e:24)
	exts wa
	sll wa, 7
	add wa, bc
	pushw wa
	pushw 0xe7
	pushw 0xffe6
	lda xwa, (xsp + 18)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 4)
	ld xbc, 0x1e0008c

PcgOutCheck_SetFinalProp:
	call SendEvent

PcgOutGridCheckComplete:
	ld xhl, 0:i3
	pop xiz
	lda xsp, (xsp + 44)
	ret

PcgOutSendFunc:
	cp xbc, EVT_ACTIVATE
	jr nz, PcgOutSendFunc_Exit
	lda xde, (0x024752:24)
	ld a, (0x02476a:24)
	ld (xde), a
	ld a, (0x02476c:24)
	ld (xde + 1), a
	lda xbc, (xde + 2)
	ld l, (0x024770:24)
	cp l, 0xff
	jr nz, PcgOutSend_StoreBankIndex
	ldw (xbc), 0xffff
	jr PcgOutSend_TransmitMidi

PcgOutSend_StoreBankIndex:
	exts hl
	ld a, (0x02476e:24)
	exts wa
	sla wa, 7
	add wa, hl
	ld (xbc), wa

PcgOutSend_TransmitMidi:
	ld xwa, 0x1430000
	ld xbc, 0x1e30000
	call MainFuncCall

PcgOutSendFunc_Exit:
	ld xhl, 0:i3
	ret

MainPcgOutSend:
	cp xbc, 0x1e30000
	jr nz, MainPcgOutSend_Exit
	ld a, (xde)
	extz wa
	ld c, (xde + 1)
	extz bc
	ld de, (xde + 2)
	call MidiSysEx_BuildAndSend

MainPcgOutSend_Exit:
	ld xhl, 0:i3
	ret

; End of Computer Interface PCG routines

