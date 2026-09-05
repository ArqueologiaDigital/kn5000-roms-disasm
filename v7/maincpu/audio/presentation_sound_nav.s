; =============================================================================
; Presentation System & Sound Navigation (1.8K lines)
; =============================================================================
;
; SSF presentation workspace building, sound navigation, voice
; control, presentation control proc, and visibility management.
; Routes between UI control panel and window procedures.
; =============================================================================

	call SendEvent
	ld xde, (xsp + 30)
	set 7, de
	ld xwa, 0xffffffff
	ld xbc, 0x1c00009
	call SendEvent
	ld xde, (xsp + 30)
	ld xwa, (xsp + 38)
	ld xbc, 0x1c00034
	call SendEvent

; Builds an SSF presentation workspace and sends event 0x1c0001c via direct
; SendEvent (FA9660).  This is the CRITICAL path that allows
; AcPresentationControlProc to pass its 0xb80a type-tag check and start
; SSF playback.
;
; The workspace (at XSP+14) is populated byte-by-byte from XSP+30/31:
;   workspace[0] = byte at (XSP+31)   -- must be 0x0a for tag 0x0000b80a
;   workspace[1] = byte at (XSP+30)   -- must be 0xb8
;   workspace[2..3] = shifted/zero bytes
;
; Reached via event 0x1c00038 (direct) or event 0x1c00030 (via
; GroupBoxProc_Ev1C00030 fall-through).
GroupBoxProc_StartSSFPresentation:
	ld	xwa, (xsp+38)
	call	16400561
	ld	xwa, 29360156
	call	16400567
	lda	xwa, (xsp+18)
	call	16400573
	lda	xbc, (xsp+30)
	ld	xde, xbc
	inc	1, xde
	lda	xwa, (xsp+14)
	ld	c, (xbc)
	ld	(xwa+3), c
	ldb_spi	c, 232
	ld	(xwa+2), c
	ldb_spi	c, 232
	ld	(xwa+1), c
	ld	c, (xde)
	ld	(xwa), c
	lda	xbc, (xsp+10)
	lda	xde, (xsp+8)
	call	16567598
	cp	hl, 65535
	jrl	z, 620
GroupBoxProc_SSFItemLoop:
	ld	xwa, (xsp+10)
	ld	(xsp+18), xwa
	ld	xwa, (xsp+10)
	call	16567398
	lda	xde, (xsp+18)
	ld	(xde+4), hl
	ldw	(xde+6), 0
	ld	xwa, 0:i3
	ld	(xde+8), xwa
	ld	xwa, 4294967295
	ld	xbc, 29360156
	call	SendEvent
	lda	xwa, (xsp+14)
	lda	xbc, (xsp+10)
	lda	xde, (xsp+8)
	call	16567598
	cp	hl, 65535
	jr	nz, -62	; -> 0xF99EAD
	jrl	555	; -> 0xF9A119
GroupBox_CancelBack:
	ld iz, 0:i3

GroupBox_CancelBack_Loop:
	ld ix, iz
	extz xix
	lda xiy, (0x0274e8:24)
	ld xde, xix
	sll xde, 3
	sub xde, xix
	sll xde, 2
	ld xbc, xiy
	add xbc, xde
	ld xwa, (xsp + 30)
	or xwa, xwa
	jrl z, GroupBox_CancelBack_Deactivate
	ld (xsp + 4), xix
	ld xhl, xbc
	ld xwa, (xsp + 38)
	ld (xbc + 2), xwa
	ld xwa, 0x1c00007
	ld (xbc + 6), xwa
	ld (xbc + 10), xix
	lda xwa, (xde + 14)
	add xiy, xwa
	ld xwa, (xsp + 38)
	ld (xiy + 2), xwa
	ld xwa, 0x1c00007
	ld (xiy + 6), xwa
	ld wa, iz
	add wa, 0x80
	extz xwa
	ld (xiy + 10), xwa
	cp (xbc), 0x0
	jr z, GroupBox_CancelBack_ActivateSecondary
	lda xwa, (xhl + 1)
	cp (xwa), 0x0
	jr nz, GroupBox_CancelBack_ActivateSecondary
	ld (xwa), 0x1
	ld xwa, 0x1c00026
	push xwa
	ld xwa, (xsp + 8)
	push xwa
	ld xwa, 0x10
	ld xbc, (xsp + 46)
	ld xde, (xsp + 46)
	call SetApTimer

GroupBox_CancelBack_ActivateSecondary:
	ld bc, iz
	extz xbc
	ld xwa, xbc
	sll xwa, 3
	sub xwa, xbc
	sll xwa, 2
	lda xbc, (xwa + 14)
	ld xwa, 0x274e8
	add xwa, xbc
	cp (xwa), 0x0
	jrl z, GroupBox_CancelBack_LoopNext
	inc 1, xwa
	cp (xwa), 0x0
	jrl nz, GroupBox_CancelBack_LoopNext
	ld (xwa), 0x1
	ld xwa, 0x1c00026
	push xwa
	ld wa, iz
	add wa, 0x80
	extz xwa
	push xwa
	ld xwa, 0x10
	ld xbc, (xsp + 46)
	ld xde, (xsp + 46)
	call SetApTimer
	jr GroupBox_CancelBack_LoopNext

GroupBox_CancelBack_Deactivate:
	ld xwa, xbc
	cp (xbc), 0x0
	jr z, GroupBox_CancelBack_DeactivateSecondary
	inc 1, xwa
	cp (xwa), 0x0
	jr z, GroupBox_CancelBack_DeactivateSecondary
	ld (xwa), 0x0
	ld xwa, 0x1c00026
	push xwa
	push xix
	ld xwa, 0x10
	ld xbc, (xsp + 46)
	ld xde, (xsp + 46)
	call KillApTimer

GroupBox_CancelBack_DeactivateSecondary:
	ld bc, iz
	extz xbc
	ld xwa, xbc
	sll xwa, 3
	sub xwa, xbc
	sll xwa, 2
	lda xbc, (xwa + 14)
	ld xwa, 0x274e8
	add xwa, xbc
	cp (xwa), 0x0
	jr z, GroupBox_CancelBack_LoopNext
	inc 1, xwa
	cp (xwa), 0x0
	jr z, GroupBox_CancelBack_LoopNext
	ld (xwa), 0x0
	ld xwa, 0x1c00026
	push xwa
	ld wa, iz
	add wa, 0x80
	extz xwa
	push xwa
	ld xwa, 0x10
	ld xbc, (xsp + 46)
	ld xde, (xsp + 46)
	call KillApTimer

GroupBox_CancelBack_LoopNext:
	inc 1, iz
	cp iz, 0x10
	jrl ule, GroupBox_CancelBack_Loop
	jrl GroupBox_ReturnZero

	; --- Event 0x1e0006f: Dial Enable ---
	; Stores WA (from XBC param) into dial enable register at 0x03ef50.
GroupBox_DialEnable:
	ld wa, bc
	calr SetDialEnable
	jrl GroupBox_ReturnZero

	; --- Event 0x1e00070: Dial Down ---
	; Registers down-direction parameters (workspace, event 0x1c00007, param)
	; into dial state at 0x03ef56/5E/66 and updates dial focus.
GroupBox_DialDown:
	ld xde, (xsp + 30)
	ld xwa, (xsp + 38)
	ld xbc, 0x1c00007
	calr SetDialDown
	jrl GroupBox_ReturnZero

	; --- Event 0x1e00071: Dial Up ---
	; Registers up-direction parameters (workspace, event 0x1c00007, param)
	; into dial state at 0x03ef52/5A/62 and updates dial focus.
GroupBox_DialUp:
	ld xde, (xsp + 30)
	ld xwa, (xsp + 38)
	ld xbc, 0x1c00007
	calr SetDialUp
	jrl GroupBox_ReturnZero

	; --- Event 0x1e00088: Get Dial Focus ---
	; Returns current dial focus value from 0x03ef6a in XHL.
GroupBox_GetDialFocus:
	calr GetDialFocus
	jrl GroupBox_Epilogue

	; --- Event 0x1e00087: Set Dial Focus ---
	; Stores dial focus (XWA) at 0x03ef6a and broadcasts 0x1c0002c.
GroupBox_SetDialFocus:
	calr SetDialFocus
	jrl GroupBox_ReturnZero

	; --- Events 0x1e00079/0x1e00078: UP/DOWN Navigation ---
	; Calls 0xfa5867 (lookup), then dispatches 0x1e000b4 via FA9660.
	; Falls through to loop that broadcasts 0x1c00009 (close/hide) to
	; all active entries in the 0x0274e8 structure array.
GroupBox_NavUpDown:
	call GetTitleNow
	ld xwa, xhl
	ld xde, (xsp + 30)
	ld xbc, (xsp + 34)
	jr GroupBox_NavDispatch
	call UIRender_RetStub1
	jrl GroupBox_ReturnZero
	call UIRender_RetStub2
	jrl GroupBox_ReturnZero
	ld wa, 0:i3
	calr SetDialEnable
	ld xwa, 0xffffffff
	ld (0x03ef6a:24), xwa
	call InitializeTimer
	ld xwa, (xsp + 38)
	ld xbc, 0x1e000b4
	ld xde, 0:i3

GroupBox_NavDispatch:
	call SendEvent
	jr GroupBox_ReturnZero
	ld iz, 0:i3

GroupBox_CloseAll_Loop:
	ld de, iz
	extz xde
	ld xwa, xde
	sll xwa, 3
	sub xwa, xde
	sll xwa, 2
	ld xbc, 0x274e8
	add xbc, xwa
	cp (xbc), 0x0
	jr z, GroupBox_CloseAll_Secondary
	ld xwa, 0xffffffff
	ld xbc, 0x1c00009
	call SendEvent

GroupBox_CloseAll_Secondary:
	ld wa, iz
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	sll xbc, 2
	lda xwa, (xbc + 14)
	ld xbc, 0x274e8
	add xbc, xwa
	cp (xbc), 0x0
	jr z, GroupBox_CloseAll_Next
	ld de, iz
	add de, 0x80
	extz xde
	ld xwa, 0xffffffff
	ld xbc, 0x1c00009
	call SendEvent

GroupBox_CloseAll_Next:
	inc 1, iz
	cp iz, 0x10
	jr ule, GroupBox_CloseAll_Loop
	jr GroupBox_ReturnZero

	; --- Event 0x1c00036: Display Update ---
	; Enables display (FAA761 with WA=1), calls UpdateScreen, then disables.
GroupBox_DisplayUpdate:
	ld wa, 1:i3
	call SetNeedUpdate
	call UpdateScreen
	ld wa, 0:i3

GroupBox_DisableDisplay:
	call SetNeedUpdate

GroupBox_ReturnZero:
	ld xhl, 0:i3
	jr GroupBox_Epilogue

GroupBox_ForwardToBoxProc:
	ld xde, (xsp + 30)
	ld xwa, (xsp + 38)
	ld xbc, (xsp + 34)
	calr BoxProc

GroupBox_Epilogue:
	popw iz
	lda xsp, (xsp + 40)
	ret

SetDialEnable:
	ld (0x03ef50:24), wa
	ret

GetDialEnableState:
	ld hl, (0x03ef50:24)
	ret

SetDialFocus:
	ld xde, xwa
	cp (0x03ef6a:24), xde
	ret z
	ld (0x03ef6a:24), xde
	ld xwa, 0xffffffff
	ld xbc, 0x1c0002c
	call SendEvent
	ret

GetDialFocus:
	cpw (0x03ef50:24), 0
	jr nz, GetDialFocus_Active
	ld xhl, 0xffffffff
	ret

GetDialFocus_Active:
	ld xhl, (0x03ef6a:24)
	ret

SetDialUp:
	ld (0x03ef52:24), xwa
	ld (0x03ef5a:24), xbc
	ld (0x03ef62:24), xde
	jr SetDialFocus

SetDialDown:
	ld (0x03ef56:24), xwa
	ld (0x03ef5e:24), xbc
	ld (0x03ef66:24), xde
	jr SetDialFocus

SetAutoIncDefault:
	dec 4, xsp
	push xiz
	call GetRootObject
	ld xiz, xhl
	call GetRootEvent
	ld (xsp + 4), xhl
	call GetRootParam
	ld xde, xhl
	ld xwa, xiz
	ld xbc, (xsp + 4)
	calr SetAutoInc
	pop xiz
	inc 4, xsp
	ret

SetAutoInc:
	lda xsp, (xsp - 18)
	pushw iz
	ld (xsp + 8), xde
	ld (xsp + 12), xbc
	ld (xsp + 16), xwa
	call GetRootEvent
	cp xhl, 0x1c00026
	jr z, EventParam_FetchPoint
	cp xhl, 0x1c00009
	jr z, EventParam_FetchPoint
	cp xhl, 0x1c00007
	jr z, EventParam_FetchPoint
	cp xhl, 0x1c00008
	jrl nz, ApTimer_SetupReturn

EventParam_FetchPoint:
	call GetRootParam
	ld (xsp + 2), xhl
	ld xwa, (xsp + 2)
	cp xwa, 0xff
	jrl ugt, ApTimer_SetupReturn
	ld xwa, (xsp + 2)
	and xwa, 0x1f
	ld (xsp + 6), wa
	ld xwa, (xsp + 2)
	srl xwa, 7
	and xwa, 0x1
	ld iz, wa
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	ld de, (xsp + 6)
	extz xde
	ld xwa, xde
	sll xwa, 3
	sub xwa, xde
	sll xwa, 2
	add xwa, xbc
	ld xbc, 0x274e8
	add xbc, xwa
	ld xwa, (xsp + 16)
	ld (xbc + 2), xwa
	ld xwa, (xsp + 12)
	ld (xbc + 6), xwa
	ld xwa, (xsp + 8)
	ld (xbc + 10), xwa
	cp (xbc + 1), 0x0
	jr nz, ApTimer_SetupReturn
	call GetRootObject
	ld xde, xhl
	ld wa, iz
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	ld wa, (xsp + 6)
	extz xwa
	ld xhl, xwa
	sll xhl, 3
	sub xhl, xwa
	sll xhl, 2
	add xhl, xbc
	lda xwa, (0x0274e9:24)
	add xwa, xhl
	ld (xwa), 0x1
	ld xwa, 0x1c00026
	push xwa
	ld xwa, (xsp + 6)
	push xwa
	ld xwa, 0x10
	ld xbc, xde
	call SetApTimer

ApTimer_SetupReturn:
	popw iz
	lda xsp, (xsp + 18)
	ret

ScreenProc:
	lda xsp, (xsp - 12)
	push xiz
	ld xiz, xde
	ld (xsp + 8), xbc
	ld (xsp + 12), xwa
	ld xwa, (xsp + 8)
	cp xwa, 0x1e0004a
	jrl z, Screen_GetDefault
	cp xwa, 0x1e00048
	jrl z, Screen_ReturnZero
	cp xwa, 0x1e0004b
	jrl z, Screen_GetStoredValue
	cp xwa, 0x1e00049
	jrl z, Screen_SetStoredValue
	cp xwa, 0x1c00007
	jrl z, Screen_OK
	cp xwa, 0x1c00009
	jrl z, Screen_Deactivate
	cp xwa, 0x1c0000d
	jrl z, Screen_Paint
	cp xwa, 0x1c00002
	jrl z, Screen_Close
	cp xwa, 0x1c00001
	jr z, Screen_Init
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, xiz
	jrl Screen_ForwardToGroupBox

Screen_Init_RegisterChild:
	ld xwa, xhl
	call SetCurrentTarget

Screen_Init:
	call GetCurrentTarget
	ld xwa, xhl
	ld xbc, 0x1e0004b
	ld xde, 0:i3
	call SendEvent
	cp xhl, 0xffffffff
	jr nz, Screen_Init_RegisterChild
	call GetCurrentTarget
	ld xwa, xhl
	ld xbc, 0x1e00014
	ld xde, 0x1600033
	call SendEvent
	or xhl, xhl
	jr nz, Screen_Init_Setup

Screen_Init_CloseDeadChildren:
	ld xwa, 0xffffffff
	ld xbc, 0x1c00002
	ld xde, xiz
	call SendEvent
	call GetCurrentTarget
	ld xwa, xhl
	ld xbc, 0x1e00014
	ld xde, 0x1600033
	call SendEvent
	or xhl, xhl
	jr z, Screen_Init_CloseDeadChildren

Screen_Init_Setup:
	ld xwa, 0xffffffff
	ld xbc, 0x1c00002
	ld xde, xiz
	call SendEvent
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld (xsp + 4), xhl
	cp xiz, 0x4
	jr z, Screen_Init_SetWall
	cp xiz, 0x3
	jr z, Screen_Init_ClearStoredValue
	cp xiz, 0x5
	jr z, Screen_Init_ClearStoredValue
	or xiz, xiz
	jr nz, Screen_Init_SetWall

Screen_Init_ClearStoredValue:
	ld xwa, (xsp + 4)
	ld xbc, (xwa + 30)
	ld xwa, 0xffffffff
	ld (xbc), xwa

Screen_Init_SetWall:
	calr PostTitle_Function
	cp hl, 0:i3
	call nz, (SleepMainTask:24)
	ld xwa, (xsp + 12)
	ld xbc, 0x1e000b1
	ld xde, 0:i3
	call SendEvent
	ld wa, hl
	calr SetWallPaper
	ld xwa, (xsp + 12)
	ld xbc, 0x1e000b2
	ld xde, 0:i3
	call SendEvent
	ld wa, hl
	calr SetWallColor
	calr PostTitle_Function
	cp hl, 0:i3
	call nz, (WakeUpMainTask:24)
	call GetTitleNow
	ld xwa, xhl
	ld xde, (xsp + 12)
	ld xbc, 0x1e00077
	call SendEvent
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, xiz
	calr GroupBoxProc
	cp xiz, 0x4
	jr nz, Screen_ReturnZero
	ld xwa, (xsp + 4)
	ld xbc, (xwa + 30)
	ld xwa, (xbc)
	cp xwa, 0xffffffff
	jr z, Screen_ReturnZero
	ld xwa, (xbc)
	ld xbc, (xsp + 8)
	ld xde, xiz
	call SendEvent

Screen_ReturnZero:
	ld xhl, 0:i3
	jrl Screen_Return

Screen_Close:
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, xiz
	calr GroupBoxProc
	ld xwa, (xsp + 12)
	call GetViewInstance
	cp xiz, 0x3
	jr z, Screen_ReturnZero
	cp xiz, 0x4
	jr z, Screen_Close_ClearValue
	cp xiz, 0x5
	jr z, Screen_Close_ClearValue
	or xiz, xiz
	jr nz, Screen_ReturnZero

Screen_Close_ClearValue:
	ld xbc, (xhl + 30)
	ld xwa, 0xffffffff
	ld (xbc), xwa
	jr Screen_ReturnZero

Screen_Paint:
	call DrawWall
	jr Screen_ReturnZero

Screen_Deactivate:
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, xiz
	calr GroupBoxProc
	ld wa, 1:i3
	call SetNeedUpdate
	call UpdateScreen
	ld wa, 0:i3
	call SetNeedUpdate
	jr Screen_ReturnZero

Screen_OK:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 12)
	ld xbc, 0x1e00024
	ld xde, 0x1600047
	call SendEvent
	or xhl, xhl
	jr nz, Screen_OK_Forward
	cp xiz, 0xf
	jr nz, Screen_OK_Forward
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e0007a
	ld xde, 0:i3
	call SendEvent
	or xhl, xhl
	jr nz, Screen_OK_NavUp
	ld xwa, (xsp + 4)
	ld xde, (xwa + 26)
	cp xde, 0x1a00000
	jr z, Screen_OK_Forward
	ld xwa, 0xffffffff
	ld xbc, 0x1c00015
	jr Screen_OK_PostAndDispatch

Screen_OK_NavUp:
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e00079
	ld xde, 0:i3
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e0009a
	ld xde, 0:i3

Screen_OK_PostAndDispatch:
	call SendEvent

Screen_OK_Forward:
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, xiz

Screen_ForwardToGroupBox:
	calr GroupBoxProc
	jr Screen_Return

Screen_SetStoredValue:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld xbc, (xhl + 30)
	ld (xbc), xiz
	jrl Screen_ReturnZero

Screen_GetStoredValue:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld xwa, (xhl + 30)
	ld xhl, (xwa)
	jr Screen_Return

Screen_GetDefault:
	ld xhl, 0xffffffff

Screen_Return:
	pop xiz
	lda xsp, (xsp + 12)
	ret

GetEditSwPoint:
	ld hl, wa
	lda xde, (xbc + 2)
	cp wa, 0x8c
	jr z, EditSwParam_Mode4
	cp wa, 0x8b
	jr z, EditSwParam_Mode3
	cp wa, 0x8a
	jr z, EditSwParam_Mode2
	cp wa, 0x89
	jr z, EditSwParam_Mode1
	cp wa, 0x88
	jr z, EditSwParam_Mode0
	cp hl, 0xc
	jrl ugt, EditSwParam_Default
	add hl, hl
	lda xix, (DiskWarning_ConfirmStrings_0xE70:24)
	ldw_sri HL, 0x07, 0xf0, 0xec
	lda xix, (EditSwParam_Mode0:24)
	jp_ind 8, 0x07, 0xf0, 0xec

; GetEditSwPoint handler: mode 0 (value=0x2b)
EditSwParam_Mode0:
	ld wa, 0:i3
	jr EditSwParam_StoreMode0
	ldw wa, 0x13f

EditSwParam_StoreMode0:
	ld (xbc), wa
	ldw (xde), 0x2b
	ret

; GetEditSwPoint handler: mode 1 (value=0x55)
EditSwParam_Mode1:
	ld wa, 0:i3
	jr EditSwParam_StoreMode1
	ldw wa, 0x13f

EditSwParam_StoreMode1:
	ld (xbc), wa
	ldw (xde), 0x55
	ret

; GetEditSwPoint handler: mode 2 (value=0x7f)
EditSwParam_Mode2:
	ld wa, 0:i3
	jr EditSwParam_StoreMode2
	ldw wa, 0x13f

EditSwParam_StoreMode2:
	ld (xbc), wa
	ldw (xde), 0x7f
	ret

; GetEditSwPoint handler: mode 3 (value=0xa9)
EditSwParam_Mode3:
	ld wa, 0:i3
	jr EditSwParam_Mode3_Store
	ldw wa, 0x13f

; GetEditSwPoint: store mode 3 result
EditSwParam_Mode3_Store:
	ld (xbc), wa
	ldw (xde), 0xa9
	ret

; GetEditSwPoint handler: mode 4 (value=0xd3)
EditSwParam_Mode4:
	ld wa, 0:i3
	jr EditSwParam_Mode4_Store
	ldw wa, 0x13f

; GetEditSwPoint: store mode 4 result
EditSwParam_Mode4_Store:
	ld (xbc), wa
	ldw (xde), 0xd3
	ret

; GetEditSwPoint handler: tempo table lookup
EditSwParam_TempoTable:
	.byte 0x30, 0x14, 0x00, 0x68, 0x21, 0x30, 0x3c, 0x00
	.byte 0x68, 0x1c, 0x30, 0x64, 0x00, 0x68, 0x17, 0x30
	.byte 0x8c, 0x00, 0x68, 0x12, 0x30, 0xb4, 0x00, 0x68
	.byte 0x0d, 0x30, 0xdc, 0x00, 0x68, 0x08, 0x30, 0x04
	.byte 0x01, 0x68, 0x03, 0x30, 0x2c, 0x01, 0xb1, 0x50
	.byte 0xb2, 0x02, 0xef, 0x00, 0x0e
EditSwParam_Default:
	ldw (xbc), 0xa0
	ldw (xde), 0x78
	ret

SetWallPaper:
	cp wa, 0:i3
	jr mi, SetWallPaper_Default
	cp wa, 5:i3
	jr gt, SetWallPaper_Default
	add wa, wa
	lda xix, (DiskWarning_ConfirmStrings_0xE8A:24)
	ldw_sri WA, 0x07, 0xf0, 0xe0
	lda xix, (SetWallPaper_DispatchData:24)
	jp_ind 8, 0x07, 0xf0, 0xe0

SetWallPaper_DispatchData:
	cpw	(0x0340fe:24), 0
	jr	nz, 28

SetWallPaper_Default:
	ld wa, 0:i3
	jp ChangeWall
SetWallPaper_CaseData:
	cpw	(0x0340fa:24), 0
	jr	nz, 13
	ld	wa, 1:i3
	jr	-17
	cpw	(0x0340fc:24), 0
	jr	z, -13
	ld	wa, 2:i3
	jr	t, 0xe2

SetWallColor:
	cp wa, 1:i3
	jr z, SetWallColor_01
	cp wa, 0xf9
	jr z, SetWallColor_F9
	cp wa, 2:i3
	jr z, SetWallColor_02
	cp wa, 0xf8
	jr z, SetWallColor_F8
	ld wa, 0:i3
	jr UI_ChangeWallPalette_Jump

SetWallColor_F8:
	ld wa, 2:i3
	jr UI_ChangeWallPalette_Jump

SetWallColor_02:
	ld wa, 4:i3
	jr UI_ChangeWallPalette_Jump

SetWallColor_F9:
	ld wa, 6:i3
	jr UI_ChangeWallPalette_Jump

SetWallColor_01:
	ldw wa, 0x8

UI_ChangeWallPalette_Jump:
	jp ChangeWallPalette

IvScreenProc:
	cp xbc, 0x1c0000d
	jrl nz, ScreenProc
	ld xhl, 0:i3
	ret

TtlScreenProc:
	lda xsp, (xsp - 12)
	push xiz
	ld xiz, xwa
	cp xbc, 0x1c0000d
	jr z, TtlScreen_PaintHandler
	ld xwa, xiz
	calr ScreenProc
	jr TtlScreen_Return

TtlScreen_PaintHandler:
	ld xwa, xiz
	calr ScreenProc
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	lda xiy, (xwa + 14)
	lda xix, (xsp + 8)
	ld bc, 4:i3
	ldirw
	ld xwa, xiz
	ld xbc, 0x1e00024
	ld xde, 0x1600024
	call SendEvent
	or xhl, xhl
	scc16 nz, de
	lda xwa, (xsp + 8)
	ld xhl, (xsp + 4)
	ld xbc, (xhl + 34)
	push xbc
	pushw de
	ld xbc, (xhl + 38)
	ld de, 0:i3
	calr DrawTitleBar
	ld xhl, 0:i3

TtlScreen_Return:
	pop xiz
	lda xsp, (xsp + 12)
	ret

DrawTitleBar:
	lda xsp, (xsp - 42)
	push xiz
	ld (xsp + 40), e
	ld (xsp + 42), xbc
	lda xbc, (xsp + 32)
	ld de, (xwa + 2)
	ld (xbc + 2), de
	add de, 0x1b
	ld (xbc + 6), de
	ld de, (xwa)
	inc 4, de
	ld (xbc), de
	ld wa, (xwa + 4)
	dec 4, wa
	ld (xbc + 4), wa
	ldw (xsp + 10), 0x0
	cpw (xsp + 50), 0x0
	jr z, DrawTitleBar_SetActiveOffset
	ldw (xsp + 10), 0x40

DrawTitleBar_SetActiveOffset:
	ldw iz, 0x18
	ld xwa, (xsp + 42)
	or xwa, xwa
	jr nz, DrawTitleBar_CalcLayout
	ld iz, 0:i3

DrawTitleBar_CalcLayout:
	lda xde, (xsp + 24)
	ld wa, 7:i3
	calr GetClientBox2
	lda xwa, (xsp + 24)
	add (xwa), iz
	lda xbc, (xsp + 12)
	calr GetBoxCenter
	ld xwa, 4:i3
	ld (xsp + 4), xwa
	ld xiz, (xsp + 52)
	ld xwa, xiz
	ld xbc, 4:i3
	call CalcTotalWidth
	ld (xsp + 8), hl
	ld e, (xsp + 40)
	lda xwa, (xsp + 24)
	lda xbc, (xsp + 12)
	cp (xsp + 40), 0x2
	jrl z, DrawTitleBar_RightJustify
	cp e, 1:i3
	jrl z, DrawTitleBar_LeftJustify
	cp e, 0:i3
	jrl nz, StringDraw_JoinPoint
	ld xhl, xbc
	ld de, (xsp + 8)
	exts xde
	divs de, 0x2
	ld ix, de
	add ix, (xbc)
	ld wa, (xwa + 4)
	sub wa, (xsp + 10)
	dec 4, wa
	cp ix, wa
	jr le, StringCenter_Entry
	cpw (xsp + 50), 0x0
	jr z, DrawTitleBar_ShrinkFont
	add de, (xhl)
	sub de, wa
	inc 4, de
	ld wa, (xsp + 10)
	exts xwa
	divs wa, 0x2
	cp de, wa
	jr le, DrawTitleBar_AdjustLeft
	ld xwa, 1:i3
	ld (xsp + 4), xwa
	ld xwa, xiz
	ld xbc, 1:i3
	call CalcTotalWidth
	ld (xsp + 8), hl
	lda xbc, (xsp + 12)
	ld de, (xsp + 8)
	exts xde
	divs de, 0x2
	ld hl, de
	add hl, (xbc)
	ld wa, (xsp + 28)
	sub wa, (xsp + 10)
	dec 4, wa
	cp hl, wa
	jr le, StringCenter_Entry
	add de, (xbc)
	sub de, wa
	inc 4, de
	ld xhl, xbc

DrawTitleBar_AdjustLeft:
	sub (xhl), de
	jr StringCenter_Entry

DrawTitleBar_ShrinkFont:
	ld xwa, 1:i3
	ld (xsp + 4), xwa
	ld xwa, xiz
	ld xbc, 1:i3
	call CalcTotalWidth
	ld (xsp + 8), hl

StringCenter_Entry:
	lda xwa, (xsp + 24)
	lda xbc, (xsp + 12)
	ld xde, (xsp + 4)
	push xde
	pushw 0xff
	pushw 0xf7
	ld xde, xiz
	call DrawStringCentered
	jr StringDraw_JoinPoint

DrawTitleBar_LeftJustify:
	ld xde, 4:i3
	push xde
	pushw 0xff
	pushw 0xf7
	ld xde, xiz
	call DrawStringLeftJustify
	jr StringDraw_JoinPoint

DrawTitleBar_RightJustify:
	ld xde, 4:i3
	push xde
	pushw 0xff
	pushw 0xf7
	ld xde, xiz
	call DrawStringRightJustify

StringDraw_JoinPoint:
	ld xwa, (xsp + 42)
	or xwa, xwa
	jr z, DirmdEmu_CaseA
	lda xhl, (xsp + 12)
	ld wa, (xsp + 8)
	exts xwa
	divs wa, 0x2
	add wa, 0x1c
	sub (xhl), wa
	lda xde, (xhl + 2)
	submi16 (xde), 0xb
	lda xwa, (xsp + 16)
	ld bc, (xhl)
	dec 2, bc
	ld (xwa), bc
	ld bc, (xhl)
	add bc, 0x19
	ld (xwa + 4), bc
	ld bc, (xde)
	dec 2, bc
	ld (xwa + 2), bc
	ld bc, (xde)
	add bc, 0x19
	ld (xwa + 6), bc
	ldw bc, 0xc4
	ldw de, 0xf0
	call DrawDesignBox
	lda xwa, (xsp + 12)
	ld xbc, (xsp + 42)
	call DrawIcons

; DirmdEmulator dispatch case A
DirmdEmu_CaseA:
	pop xiz
	lda xsp, (xsp + 42)
	retd 0x6

IvDirmdScreenProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xbc
	ld (xsp + 12), xwa
	ld xbc, (xsp + 8)
	cp xbc, 0x1e000b1
	jrl z, DirmdEmu_CaseD
	ld xwa, (xsp + 8)
	cp xwa, 0x1c0003a
	jr z, DirmdEmu_CaseC
	cp xwa, 0x1c00039
	jr z, DirmdEmu_CaseB
	sub xbc, 0x1c00001
	cp xbc, 0x0
	jrl lt, DirmdEmu_CaseE
	cp xbc, 0xe
	jrl gt, DirmdEmu_CaseE
	add xbc, xbc
	add xbc, DiskWarning_ConfirmStrings_0xE96
	ld bc, (xbc)
	lda xix, (DirmdEmu_CaseB:24)
	jp_ind 8, 0x07, 0xf0, 0xe4

; DirmdEmulator dispatch case B
DirmdEmu_CaseB:
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	jrl IvDirmd_ForwardToScreen

; DirmdEmulator dispatch case C
DirmdEmu_CaseC:
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	calr ScreenProc
	call GetTitleOld
	ld xwa, xhl
	ld xbc, 0x1e00032
	ld xde, 0:i3
	call SendEvent
	ld xiz, xhl
	call SleepMainTask
	ld xwa, xiz
	ld xbc, 0x1c00002
	ld xde, (xsp + 4)
	call FuncCall
	call WakeUpMainTask
	ldw (0x0276c4:24), 0x0000
	jrl TaskWake_ZeroReturn
	ldw (0x0276c4:24), 0x0001
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	jr IvDirmd_ForwardToScreen
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	calr ScreenProc
	ld wa, 2:i3
	call ChangePalette
	jr TaskWake_ZeroReturn
	ldw (0x0276c4:24), 0x0001
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e00032
	ld xde, 0:i3
	call SendEvent
	ld xiz, xhl
	call SleepMainTask
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call FuncCall
	call WakeUpMainTask
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)

IvDirmd_ForwardToScreen:
	calr ScreenProc
	jr TaskWake_ZeroReturn
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e00032
	ld xde, 0:i3
	call SendEvent
	ld xiz, xhl
	call SleepMainTask
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call FuncCall
	call WakeUpMainTask

TaskWake_ZeroReturn:
	ld xhl, 0:i3
	jr IvDirmd_Epilogue
	ld xwa, (xsp + 4)
	cp xwa, 0xff
	jr ugt, IvDirmd_ForwardAndReturn
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e00032
	ld xde, 0:i3
	call SendEvent
	ld xiz, xhl
	call SleepMainTask
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call FuncCall
	call WakeUpMainTask

IvDirmd_ForwardAndReturn:
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	jr IvDirmd_ScreenForward

; DirmdEmulator dispatch case D
DirmdEmu_CaseD:
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	calr ScreenProc
	inc 3, xhl
	jr IvDirmd_Epilogue

; DirmdEmulator dispatch case E
DirmdEmu_CaseE:
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)

IvDirmd_ScreenForward:
	calr ScreenProc

IvDirmd_Epilogue:
	pop xiz
	lda xsp, (xsp + 12)
	ret
PostTitle_Function:

GetDirmdFlag:
	ld hl, (0x0276c4:24)
	ret

DirmdTitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, DiskWarning_ConfirmStrings_0xEB4
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	calr DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret
DirmdEmu_CaseF:
	ld	a, (35996:16)
	cp	a, (35997:16)
	jr	z, 25
	ldw	wa, 255
	call	16453699
	ldw	wa, 245
	call	16453693
	call	16453802
	ldw	wa, 255
	call	16453705
	ld	xwa, 15375216
	call	16394900
	jp	16261308
	ld	xwa, 15375234
	call	16394900
	jp	16261309
	lda	xsp, (xsp-256)
	pushw	iz
	.byte 0xd3, 0xfd, 0x08, 0x01, 0x04
	ld	iz, (xsp+264)
	pushw	iz
	pushw 234
	pushw 39828
	lda	xwa, (xsp+10)
	push	xwa
	call	16712341
	lda	xsp, (xsp+12)
	lda	xwa, (xsp+2)
	call	16394900
	ld	wa, iz
	ld	bc, (xsp+264)
	call	16261310
	popw	iz
	.byte 0xf3, 0xfd, 0x00, 0x01, 0x37
	ret
	ld	xwa, 15375276
	call	16394900
	jp	16261311
DirmdEmulator_Entry:

DirmdEmulator:
	push xiz
	ld xiz, xwa
	sub xbc, 0x1c00000
	cp xbc, 0x0
	jrl lt, DirmdEmu_DefaultCase
	cp xbc, 0xf
	jrl gt, DirmdEmu_DefaultCase
	add xbc, xbc
	add xbc, DiskWarning_ConfirmStrings_0xF12
	ld bc, (xbc)
	lda xix, (DirmdEmulator_Dispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe4
DirmdEmulator_Dispatch:
	push	xde
	push	xhl
	push	xix
	push	xiz
	ld	xwa, (xiz+4)
	call	(xwa)
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jr	113
	ld	(58138:16), 0
	ldw	wa, 255
	call	16453699
	ldw	wa, 245
	call	16453693
	call	16453802
	ldw	wa, 255
	call	16453705
	push	xde
	push	xhl
	push	xix
	push	xiz
	ld	xwa, (xiz)
	call	(xwa)
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jr	69
	ld	(58138:16), 16
	push	xde
	push	xhl
	push	xix
	push	xiz
	ld	xwa, (xiz)
	call	(xwa)
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	(58138:16), 0
	jr	45
	cp	xde, 255
	jr	ugt, 37
	push	xde
	push	xhl
	push	xix
	push	xiz
	ld	xbc, xde
	and	xbc, 128
	ld	b, c
	pushw	bc
	and	xde, 31
	ld	xhl, xde
	pushw	de
	ld	xde, (xwa+8)
	ld	wa, bc
	call	(xde)
	inc	4, xsp
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
DirmdEmu_DefaultCase:
	bit 1, (0xe318:16)
	jr z, .Lc_f9ab49
	ld a, (0xe316:16)
	extz WA
	call UI_PostPartChangeEvent
DirmdEmu_CheckModeChange:
.Lc_f9ab49:
	bit 7, (0xe318:16)
	jr z, .Lc_f9ab59
	ld a, (0xe316:16)
	extz WA
	call UI_PostModeChangeEvent
DirmdEmu_CheckSoundCtrl:
.Lc_f9ab59:
	bit 6, (0xe318:16)
	jr z, .Lc_f9ab69
	ld a, (0xe316:16)
	extz WA
	call SoundCtrl_SendCommand
DirmdEmu_CheckBit4:
.Lc_f9ab69:
	bit 4, (0xe318:16)
	call nz, (UI_PostRefreshEvent:24)
	bit 4, (0xe31a:16)
	call nz, (UI_PostTimerResetEvent:24)
	bit 3, (0xe31c:16)
	jr z, DirmdEmu_ClearAllFlags
	ld wa, 1:i3
	call UI_PostEvent_0x6E
DirmdEmu_ClearAllFlags:
	ld	(58136:16), 0
	ld	(58134:16), 0
	ld	(58138:16), 0
	ld	(58140:16), 0
	ld	(58142:16), 255
	ld	(58144:16), 255
	ld	xhl, 0:i3
	pop	xiz
	ret
WindowProc:
	lda xsp, (xsp - 24)
	push xiz
	ld (xsp + 16), xde
	ld (xsp + 20), xbc
	ld (xsp + 24), xwa
	ld xbc, (xsp + 20)
	cp xbc, 0x1c0001f
	jrl z, WindowProc_ForwardToGroupBoxes
	ld xwa, (xsp + 20)
	cp xwa, 0x1c00028
	jrl z, WindowProc_ForwardToGroupBoxes
	cp xwa, 0x1c00016
	jrl z, WindowProc_ForwardToGroupBoxes
	cp xwa, 0x1c00015
	jrl z, WindowProc_ForwardToGroupBoxes
	cp xwa, 0x1c00014
	jrl z, WindowProc_ForwardToGroupBoxes
	cp xwa, 0x1c0003b
	jrl z, WindowProc_ForwardToGroupBoxes
	cp xwa, 0x1c00026
	jrl z, WindowProc_ForwardToGroupBoxes
	cp xwa, 0x1e00094
	jrl z, WindowField_GetChildCount
	cp xwa, 0x1e0004b
	jrl z, WindowField_ReadValue
	cp xwa, 0x1e00049
	jrl z, WindowField_Focus
	cp xwa, 0x1e0004a
	jrl z, WindowField_GetValue
	cp xwa, 0x1e00048
	jrl z, WindowField_SetValue
	sub xbc, 0x1c00001
	cp xbc, 0x0
	jrl lt, WindowProc_DefaultHandler
	cp xbc, 0x9
	jrl gt, WindowProc_DefaultHandler
	add xbc, xbc
	add xbc, DiskWarning_ConfirmStrings_0xF32
	ld bc, (xbc)
	lda xix, (WindowProc_EventDispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe4
; WindowProc event dispatch
WindowProc_EventDispatch:
	ld	xwa, (xsp+24)
	call	GetViewInstance
	ld	(xsp+12), xhl
	ld	xwa, (xsp+16)
	cp	xwa, 4
	jr	z, 122
	cp	xwa, 3
	jr	z, 12
	cp	xwa, 5
	jr	z, 4
	or	xwa, xwa
	jr	nz, 102
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+28)
	ld	xwa, (xwa)
	cp	xwa, 0xffffffff
	jr	z, 14
	ld	xwa, (xsp+24)
	ld	xbc, 0x01c00002
	ld	xde, 0:i3
	call	SendEvent
	call	GetCurrentTarget
	ld	xiz, xhl
	ld	xwa, xiz
	ld	xbc, 0x01e0004b
	ld	xde, 0:i3
	call	SendEvent
	cp	xhl, 0xffffffff
	jr	z, 23
	ld	xiz, xhl
	ld	xwa, xiz
	ld	xbc, 0x01e0004b
	ld	xde, 0:i3
	call	SendEvent
	cp	xhl, 0xffffffff
	jr	nz, -23
	ld	xde, (xsp+24)
	ld	xwa, xiz
	ld	xbc, 0x01e00049
	call	SendEvent
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+28)
	ld	(xwa), xiz
	ld	xwa, (xsp+24)
	ld	xbc, (xsp+20)
	ld	xde, (xsp+16)
	calr	59203
	ld	xwa, (xsp+16)
	cp	xwa, 4
	jrl	nz, 724
	ld	xwa, (xsp+12)
	ld	xbc, (xwa+32)
	ld	xwa, (xbc)
	cp	xwa, 0xffffffff
	jrl	z, 707
	ld	xwa, (xbc)
	ld	xbc, (xsp+20)
	ld	xde, (xsp+16)
	call	SendEvent
	jrl	692
	ld	xwa, (xsp+24)
	ld	xbc, (xsp+20)
	ld	xde, (xsp+16)
	calr	59147
	ld	xwa, (xsp+24)
	call	GetViewInstance
	ld	(xsp+12), xhl
	ld	xwa, (xsp+16)
	cp	xwa, 3
	jrl	z, 144
	cp	xwa, 4
	jr	z, 30
	cp	xwa, 5
	jr	z, 5
	or	xwa, xwa
	jrl	nz, 637
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+28)
	ld	xwa, (xwa)
	cp	xwa, 0xffffffff
	jrl	z, 620
	ld	xde, (xsp+12)
	ld	xbc, (xde+28)
	ld	xwa, (xbc)
	cp	xwa, 0xffffffff
	jr	z, 16
	ld	xwa, (xde+32)
	ld	xde, (xwa)
	ld	xwa, (xbc)
	ld	xbc, 0x01e00049
	call	SendEvent
	ld	xde, (xsp+12)
	ld	xbc, (xde+32)
	ld	xwa, (xbc)
	cp	xwa, 0xffffffff
	jr	z, 16
	ld	xwa, (xde+28)
	ld	xde, (xwa)
	ld	xwa, (xbc)
	ld	xbc, 0x01e00048
	call	SendEvent
	call	GetCurrentTarget
	cp	xhl, (xsp+24)
	jr	nz, 12
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+28)
	ld	xwa, (xwa)
	call	SetCurrentTarget
	ld	xde, (xsp+12)
	ld	xbc, (xde+28)
	ld	xwa, 0xffffffff
	ld	(xbc), xwa
	ld	xbc, (xde+32)
	ld	(xbc), xwa
	jrl	514
	call	GetCurrentTarget
	cp	xhl, (xsp+24)
	jrl	nz, 504
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+28)
	ld	xwa, (xwa)
	jrl	489

; WindowProc field set value handler (event 0x1c00048)
WindowField_SetValue:
	ld xwa, (xsp + 24)
	ld xiz, 0x1c
	jr WindowField_StoreToView

; WindowProc field get value handler (event 0x1c0004a)
WindowField_GetValue:
	ld xwa, (xsp + 24)
	ld xiz, 0x1c
	jr WindowField_ReadFromView

; WindowProc field focus handler (event 0x1c00049)
WindowField_Focus:
	ld xwa, (xsp + 24)
	ld xiz, 0x20

WindowField_StoreToView:
	call GetViewInstance
	add xhl, xiz
	ld xbc, (xhl)
	ld xwa, (xsp + 16)
	ld (xbc), xwa
	jrl AcNaming_ReturnZero

; WindowProc field read value handler (event 0x1c0004b)
WindowField_ReadValue:
	ld xwa, (xsp + 24)
	ld xiz, 0x20

WindowField_ReadFromView:
	call GetViewInstance
	add xhl, xiz
	ld xwa, (xhl)
	ld xhl, (xwa)
	jrl WindowProc_Epilogue

; WindowProc get child count handler (event 0x1e00094)
WindowField_GetChildCount:
	ld xwa, (xsp + 24)
	call GetViewInstance
	ld xwa, (xhl + 28)
	ld xwa, (xwa)
	cp xwa, 0xffffffff
	scc16 nz, hl
	extz xhl
	jrl WindowProc_Epilogue
	ld xwa, (xsp + 24)
	call GetViewInstance
	ld (xsp + 12), xhl
	call GetCurrentTarget
	ld (xsp + 4), xhl
	ld xwa, (xsp + 12)
	ld xwa, (xwa + 28)
	ld xiz, (xwa)
	ld xwa, xiz
	call SetCurrentTarget
	ld xwa, 0xffffffff
	ld xbc, (xsp + 20)
	ld xde, (xsp + 16)
	call SendEvent
	call GetCurrentTarget
	cp xhl, xiz
	jr nz, WindowField_ForwardAfterChild
	ld xwa, (xsp + 12)
	ld xwa, (xwa + 28)
	ld xwa, (xwa)
	cp xwa, 0xffffffff
	jr z, WindowField_ForwardAfterChild
	ld xwa, (xsp + 4)
	call SetCurrentTarget

WindowField_ForwardAfterChild:
	ld xwa, (xsp + 24)
	ld xbc, (xsp + 20)
	ld xde, (xsp + 16)
	jr WindowProc_GroupBoxForward

WindowProc_ForwardToGroupBoxes:
	ld xwa, (xsp + 24)
	ld xbc, (xsp + 20)
	ld xde, (xsp + 16)

WindowProc_GroupBoxForward:
	calr GroupBoxProc
	jrl AcNaming_ReturnZero
	ld xwa, (xsp + 24)
	ld xbc, (xsp + 20)
	ld xde, (xsp + 16)
	calr GroupBoxProc
	ld xwa, (xsp + 24)
	call GetViewInstance
	ld (xsp + 12), xhl
	ld xbc, (xsp + 12)
	ld xwa, (xbc + 28)
	ld xwa, (xwa)
	cp xwa, 0xffffffff
	jrl z, AcNaming_ReturnZero
	cpw (xbc + 26), 0x0
	jrl nz, AcNaming_ReturnZero
	call GetCurrentTarget
	ld (xsp + 4), xhl
	ld xwa, (xsp + 12)
	ld xwa, (xwa + 28)
	ld xiz, (xwa)
	ld xwa, xiz
	call SetCurrentTarget
	ld xwa, xiz
	ld xbc, (xsp + 20)
	ld xde, (xsp + 16)
	call SendEvent
	call GetCurrentTarget
	cp xhl, xiz
	jrl nz, AcNaming_ReturnZero
	ld xwa, (xsp + 12)
	ld xwa, (xwa + 28)
	ld xwa, (xwa)
	cp xwa, 0xffffffff
	jrl z, AcNaming_ReturnZero
	ld xwa, (xsp + 4)
	jrl WindowProc_RestoreTarget

; WindowProc default handler (returns 0)
WindowProc_DefaultHandler:
	ld xwa, (xsp + 20)
	srl xwa, 0
	and xwa, 0xfff
	cp wa, 0x1e0
	jr c, WindowProc_GroupBoxAndChild
	cp wa, 0x1ff
	jr ugt, WindowProc_GroupBoxAndChild
	ld xwa, (xsp + 24)
	ld xbc, (xsp + 20)
	ld xde, (xsp + 16)
	calr GroupBoxProc
	jrl WindowProc_Epilogue

WindowProc_GroupBoxAndChild:
	ld xwa, (xsp + 24)
	ld xbc, (xsp + 20)
	ld xde, (xsp + 16)
	calr GroupBoxProc
	ld xwa, (xsp + 24)
	call GetViewInstance
	ld (xsp + 12), xhl
	ld xwa, (xsp + 12)
	ld xwa, (xwa + 28)
	ld xwa, (xwa)
	cp xwa, 0xffffffff
	jr z, AcNaming_ReturnZero
	call GetRootObject
	cp xhl, (xsp + 24)
	jr nz, AcNaming_ReturnZero
	call GetRootEvent
	cp xhl, (xsp + 20)
	jr nz, AcNaming_ReturnZero
	call GetRootParam
	cp xhl, (xsp + 16)
	jr nz, AcNaming_ReturnZero
	call GetCurrentTarget
	ld (xsp + 4), xhl
	ld xwa, (xsp + 12)
	ld xwa, (xwa + 28)
	ld xiz, (xwa)
	ld xwa, xiz
	call SetCurrentTarget
	call GetRootObject
	ld (xsp + 8), xhl
	ld xwa, xiz
	call SetRootObject
	ld xwa, xiz
	ld xbc, (xsp + 20)
	ld xde, (xsp + 16)
	call SendEvent
	call GetCurrentTarget
	cp xhl, xiz
	jr nz, AcNaming_ReturnZero
	ld xwa, (xsp + 12)
	ld xwa, (xwa + 28)
	ld xwa, (xwa)
	cp xwa, 0xffffffff
	jr z, AcNaming_ReturnZero
	ld xwa, (xsp + 8)
	call SetRootObject
	ld xwa, (xsp + 4)

WindowProc_RestoreTarget:
	call SetCurrentTarget

AcNaming_ReturnZero:
	ld xhl, 0:i3

WindowProc_Epilogue:
	pop xiz
	lda xsp, (xsp + 24)
	ret

AcNamingWindowProc:
	lda xsp, (xsp - 50)
	push xiz
	ld (xsp + 42), xde
	ld (xsp + 46), xbc
	ld (xsp + 50), xwa
	ld xwa, (xsp + 46)
	cp xwa, 0x1c00029
	jrl z, WndScroll_HandleDialPage
	cp xwa, 0x1e00081
	jrl z, WndScroll_HandleCharSet
	cp xwa, 0x1e00080
	jrl z, WndScroll_HandleCharInput
	ld xhl, (xsp + 42)
	ld de, hl
	cp xwa, 0x1e0007f
	jrl z, WndScroll_HandleIndexChange
	cp xwa, 0x1e0007b
	jrl z, WndScroll_StoreCallerPtr
	cp xwa, 0x1e0003a
	jrl z, WndScroll_CopyFromSource
	cp xwa, 0x1e00086
	jrl z, WndScroll_CopyStringAndSend
	cp xwa, 0x1c00018
	jrl z, WndEvt_DispatchByEventCode
	cp xwa, 0x1c0001a
	jrl z, WndEvt_DispatchByEventCode
	cp xwa, 0x1c00017
	jrl z, WndEvt_DispatchByEventCode
	cp xwa, 0x1c00019
	jrl z, WndEvt_DispatchByEventCode
	lda xbc, (xsp + 34)
	cp xwa, 0x1c0000f
	jrl z, WndScroll_RepaintAll
	cp xwa, 0x1c0000e
	jrl z, WndScroll_HandleSelectionChange
	cp xwa, 0x1c00002
	jrl z, WndScroll_BasicWindowProc
	cp xwa, 0x1c0000c
	jrl z, WndScroll_InitSelectionTrack
	cp xwa, 0x1c0000b
	jrl z, WndScroll_InitSelectionTrack
	cp xwa, 0x1c00001
	jrl nz, WndScroll_ForwardToWindowProc
	or xhl, xhl
	jr z, AcNaming_CheckDefaultWidget
	ld xwa, xhl
	cp xwa, 0x3
	jr z, AcNaming_CheckDefaultWidget
	cp xwa, 0x5
	jrl nz, WndScroll_InitWindowProc

AcNaming_CheckDefaultWidget:
	ld xwa, (0x0274d2:24)
	or xwa, xwa
	jr nz, AcNaming_InitScrollState
	ld xwa, 0x1200005
	ld (0x0274d2:24), xwa

AcNaming_InitScrollState:
	ldw (0x0274d8:24), 0x0000
	ldw (0x0274da:24), 0x0000
	ld xwa, (0x0274d2:24)
	ld xbc, 0x1e0007c
	ld xde, 0:i3
	call ApFuncCall
	ld (0x0274d6:24), hl
	cp hl, 0x20
	jr ule, AcNaming_QueryCharSet
	ldw (0x0274d6:24), 0x0020

AcNaming_QueryCharSet:
	ld xwa, (0x0274d2:24)
	ld xbc, 0x1e00084
	ld xde, 0:i3
	call ApFuncCall
	ld (0x0274e2:24), hl
	ld wa, hl
	extz xwa
	sll xwa, 2
	ld xbc, Data_SoundEditorCharsLayout_0x18
	add xbc, xwa
	ld xwa, (xbc)
	ld (0x0274e4:24), xwa
	cp hl, 0:i3
	jr z, AcNaming_ShowNavButtons
	ld xwa, 0x17
	ld bc, 0:i3
	call SetVisible
	ld xwa, 0x18
	ld bc, 0:i3
	call SetVisible
	ld xwa, 0x19
	ld bc, 0:i3
	jr AcNaming_SetVisibleAndInit

AcNaming_ShowNavButtons:
	ld xwa, 0x17
	ld bc, 1:i3
	call SetVisible
	ld xwa, 0x18
	ld bc, 1:i3
	call SetVisible
	ld xwa, 0x19
	ld bc, 1:i3

AcNaming_SetVisibleAndInit:
	call SetVisible
	ld iz, 0:i3
	cpw (0x0274d6:24), 0
	jr ule, WndScroll_InitBuffer

; --- UI Window Procs, Graphics & Mode Screens ---
