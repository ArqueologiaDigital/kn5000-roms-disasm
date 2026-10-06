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
	ld xbc, EVT_SW_OFF
	call SendEvent
	ld xde, (xsp + 30)
	ld xwa, (xsp + 38)
	ld xbc, EVT_SEND_SW_BOTH
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
	call	SetRootObject
	ld	xwa, EVT_LSW_DATA
	call	SetRootEvent
	lda	xwa, (xsp+18)
	call	SetRootParam
	lda	xbc, (xsp+30)
	ld	xde, xbc
	inc	1, xde
	lda	xwa, (xsp+14)
	ld	c, (xbc)
	ld	(xwa+3), c
	ld	c, (xde+)
	ld	(xwa+2), c
	ld	c, (xde+)
	ld	(xwa+1), c
	ld	c, (xde)
	ld	(xwa), c
	lda	xbc, (xsp+10)
	lda	xde, (xsp+8)
	call	SndParam_ResolveWidget
	cp	hl, 65535
	jrl	z, GroupBox_ReturnZero
GroupBoxProc_SSFItemLoop:
	ld	xwa, (xsp+10)
	ld	(xsp+18), xwa
	ld	xwa, (xsp+10)
	call	SndParam_LookupReadOnly
	lda	xde, (xsp+18)
	ld	(xde+4), hl
	ldw	(xde+6), 0
	ld	xwa, 0:i3
	ld	(xde+8), xwa
	ld	xwa, 4294967295
	ld	xbc, EVT_LSW_DATA
	call	SendEvent
	lda	xwa, (xsp+14)
	lda	xbc, (xsp+10)
	lda	xde, (xsp+8)
	call	SndParam_ResolveWidget
	cp	hl, 65535
	jr	nz, GroupBoxProc_SSFItemLoop	; -> 0xF99EAD
	jrl	GroupBox_ReturnZero	; -> 0xF9A119
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
	ld xwa, EVT_SW_IN
	ld (xbc + 6), xwa
	ld (xbc + 10), xix
	lda xwa, (xde + 14)
	add xiy, xwa
	ld xwa, (xsp + 38)
	ld (xiy + 2), xwa
	ld xwa, EVT_SW_IN
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
	ld xwa, EVT_AUTO_INC
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
	ld xwa, EVT_AUTO_INC
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
	ld xwa, EVT_AUTO_INC
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
	ld xwa, EVT_AUTO_INC
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
	ld xbc, EVT_SW_IN
	calr SetDialDown
	jrl GroupBox_ReturnZero

	; --- Event 0x1e00071: Dial Up ---
	; Registers up-direction parameters (workspace, event 0x1c00007, param)
	; into dial state at 0x03ef52/5A/62 and updates dial focus.
GroupBox_DialUp:
	ld xde, (xsp + 30)
	ld xwa, (xsp + 38)
	ld xbc, EVT_SW_IN
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
GroupBoxProc_Case5:
	call UIRender_RetStub1
	jrl GroupBox_ReturnZero
GroupBoxProc_Case6:
	call UIRender_RetStub2
	jrl GroupBox_ReturnZero
GroupBoxProc_OnRefreshApTask:
	ld wa, 0:i3
	calr SetDialEnable
	ld xwa, 0xffffffff
	ld (DIAL_FOCUS:24), xwa
	call InitializeTimer
	ld xwa, (xsp + 38)
	ld xbc, EVT_REFRESH_SW_EVENT
	ld xde, 0:i3

GroupBox_NavDispatch:
	call SendEvent
	jr GroupBox_ReturnZero
GroupBoxProc_OnRefreshSwEvent:
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
	ld xbc, EVT_SW_OFF
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
	ld xbc, EVT_SW_OFF
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
	ld (DIAL_ENABLE:24), wa
	ret

GetDialEnableState:
	ld hl, (DIAL_ENABLE:24)
	ret

SetDialFocus:
	ld xde, xwa
	cp (DIAL_FOCUS:24), xde
	ret z
	ld (DIAL_FOCUS:24), xde
	ld xwa, 0xffffffff
	ld xbc, EVT_CHANGE_DIAL_FOCUS
	call SendEvent
	ret

GetDialFocus:
	cpw (DIAL_ENABLE:24), 0
	jr nz, GetDialFocus_Active
	ld xhl, 0xffffffff
	ret

GetDialFocus_Active:
	ld xhl, (DIAL_FOCUS:24)
	ret

SetDialUp:
	ld (DIAL_UP_CALLBACK:24), xwa
	ld (DIAL_UP_EVENT:24), xbc
	ld (DIAL_UP_PARAM:24), xde
	jr SetDialFocus

SetDialDown:
	ld (DIAL_DOWN_CALLBACK:24), xwa
	ld (DIAL_DOWN_EVENT:24), xbc
	ld (DIAL_DOWN_PARAM:24), xde
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
	cp xhl, EVT_AUTO_INC
	jr z, EventParam_FetchPoint
	cp xhl, EVT_SW_OFF
	jr z, EventParam_FetchPoint
	cp xhl, EVT_SW_IN
	jr z, EventParam_FetchPoint
	cp xhl, EVT_SW_ON
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
	ld xwa, EVT_AUTO_INC
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
	cp xwa, EVT_GET_PARENT_WINDOW
	jrl z, Screen_GetDefault
	cp xwa, EVT_SET_PARENT_WINDOW
	jrl z, Screen_ReturnZero
	cp xwa, EVT_GET_CHILD_WINDOW
	jrl z, Screen_GetStoredValue
	cp xwa, EVT_SET_CHILD_WINDOW
	jrl z, Screen_SetStoredValue
	cp xwa, EVT_SW_IN
	jrl z, Screen_OK
	cp xwa, EVT_SW_OFF
	jrl z, Screen_Deactivate
	cp xwa, EVT_DRAW
	jrl z, Screen_Paint
	cp xwa, EVT_HIDE
	jrl z, Screen_Close
	cp xwa, EVT_SHOW
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
	ld xbc, EVT_GET_CHILD_WINDOW
	ld xde, 0:i3
	call SendEvent
	cp xhl, 0xffffffff
	jr nz, Screen_Init_RegisterChild
	call GetCurrentTarget
	ld xwa, xhl
	ld xbc, EVT_CHECK_CLASS
	ld xde, NAKA_CLASS_Screen
	call SendEvent
	or xhl, xhl
	jr nz, Screen_Init_Setup

Screen_Init_CloseDeadChildren:
	ld xwa, 0xffffffff
	ld xbc, EVT_HIDE
	ld xde, xiz
	call SendEvent
	call GetCurrentTarget
	ld xwa, xhl
	ld xbc, EVT_CHECK_CLASS
	ld xde, NAKA_CLASS_Screen
	call SendEvent
	or xhl, xhl
	jr z, Screen_Init_CloseDeadChildren

Screen_Init_Setup:
	ld xwa, 0xffffffff
	ld xbc, EVT_HIDE
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
	ld xbc, EVT_GET_BOX_BORDER
	ld xde, 0:i3
	call SendEvent
	ld wa, hl
	calr SetWallPaper
	ld xwa, (xsp + 12)
	ld xbc, EVT_GET_BOX_COLOR
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
	ld xbc, EVT_SET_RETURN_SCREEN
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
	ld xbc, EVT_SEARCH_CLASS
	ld xde, NAKA_CLASS_IvExit
	call SendEvent
	or xhl, xhl
	jr nz, Screen_OK_Forward
	cp xiz, 0xf
	jr nz, Screen_OK_Forward
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_IS_INTERRUPT
	ld xde, 0:i3
	call SendEvent
	or xhl, xhl
	jr nz, Screen_OK_NavUp
	ld xwa, (xsp + 4)
	ld xde, (xwa + 26)
	cp xde, TITLE_PS
	jr z, Screen_OK_Forward
	ld xwa, 0xffffffff
	ld xbc, EVT_CHANGE_TITLE
	jr Screen_OK_PostAndDispatch

Screen_OK_NavUp:
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_INTERRUPT_EXIT
	ld xde, 0:i3
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_SET_HOLD
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
	lda xix, (GetEditSwPoint_CaseTable:24)
	ld	hl, (xix+hl)
	lda xix, (EditSwParam_Mode0:24)
	jp	t, (xix+hl)

; GetEditSwPoint handler: mode 0 (value=0x2b)
EditSwParam_Mode0:
	ld wa, 0:i3
	jr EditSwParam_StoreMode0
GetEditSwPoint_RightRow1:
	ldw wa, 0x13f

EditSwParam_StoreMode0:
	ld (xbc), wa
	ldw (xde), 0x2b
	ret

; GetEditSwPoint handler: mode 1 (value=0x55)
EditSwParam_Mode1:
	ld wa, 0:i3
	jr EditSwParam_StoreMode1
GetEditSwPoint_RightRow2:
	ldw wa, 0x13f

EditSwParam_StoreMode1:
	ld (xbc), wa
	ldw (xde), 0x55
	ret

; GetEditSwPoint handler: mode 2 (value=0x7f)
EditSwParam_Mode2:
	ld wa, 0:i3
	jr EditSwParam_StoreMode2
GetEditSwPoint_RightRow3:
	ldw wa, 0x13f

EditSwParam_StoreMode2:
	ld (xbc), wa
	ldw (xde), 0x7f
	ret

; GetEditSwPoint handler: mode 3 (value=0xa9)
EditSwParam_Mode3:
	ld wa, 0:i3
	jr EditSwParam_Mode3_Store
GetEditSwPoint_RightRow4:
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
GetEditSwPoint_RightRow5:
	ldw wa, 0x13f

; GetEditSwPoint: store mode 4 result
EditSwParam_Mode4_Store:
	ld (xbc), wa
	ldw (xde), 0xd3
	ret
; GetEditSwPoint handler: tempo table lookup
EditSwParam_TempoTable:
	ldw	wa, 20
	jr	GetEditSwPoint_Join
GetEditSwPoint_Column2:
	ldw	wa, 60
	jr	GetEditSwPoint_Join
GetEditSwPoint_Column3:
	ldw	wa, 100
	jr	GetEditSwPoint_Join
GetEditSwPoint_Column4:
	ldw	wa, 140
	jr	GetEditSwPoint_Join
GetEditSwPoint_Column5:
	ldw	wa, 180
	jr	GetEditSwPoint_Join
GetEditSwPoint_Column6:
	ldw	wa, 220
	jr	GetEditSwPoint_Join
GetEditSwPoint_Column7:
	ldw	wa, 260
	jr	GetEditSwPoint_Join
GetEditSwPoint_Column8:
	ldw	wa, 300
GetEditSwPoint_Join:
	ld	(xbc), wa
	ldw	(xde), 239
	ret
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
	lda xix, (SetWallPaper_CaseTable:24)
	ld	wa, (xix+wa)
	lda xix, (SetWallPaper_DispatchData:24)
	jp	t, (xix+wa)

SetWallPaper_DispatchData:
	cpw	(0x0340fe:24), 0
	jr	nz, SetWallPaper_Skip

SetWallPaper_Default:
	ld wa, 0:i3
SetWallPaper_Join:
	jp ChangeWall
SetWallPaper_CaseData:
	cpw	(0x0340fa:24), 0
	jr	nz, SetWallPaper_Skip
SetWallPaper_Loop:
	ld	wa, 1:i3
	jr	SetWallPaper_Join
SetWallPaper_MenuWallBorder:
	cpw	(0x0340fc:24), 0
	jr	z, SetWallPaper_Loop
SetWallPaper_Skip:
	ld	wa, 2:i3
	jr	t, SetWallPaper_Join

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
	cp xbc, EVT_DRAW
	jrl nz, ScreenProc
	ld xhl, 0:i3
	ret

TtlScreenProc:
	lda xsp, (xsp - 12)
	push xiz
	ld xiz, xwa
	cp xbc, EVT_DRAW
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
	ld xbc, EVT_SEARCH_CLASS
	ld xde, NAKA_CLASS_PsPageBox
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
	cp xbc, EVT_GET_BOX_BORDER
	jrl z, IvDirmdScreenProc_OnGetBoxBorder
	ld xwa, (xsp + 8)
	cp xwa, EVT_OLD_TITLE
	jr z, IvDirmdScreenProc_OnOldTitle
	cp xwa, EVT_NEW_TITLE
	jr z, DirmdEmu_CaseB
	sub xbc, EVT_SHOW
	cp xbc, 0x0
	jrl lt, DirmdEmu_CaseE
	cp xbc, 0xe
	jrl gt, DirmdEmu_CaseE
	add xbc, xbc
	add xbc, IvDirmdScreenProc_Str_K
	ld bc, (xbc)
	lda xix, (DirmdEmu_CaseB:24)
	jp	t, (xix+bc)

; DirmdEmulator dispatch case B
DirmdEmu_CaseB:
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	jrl IvDirmd_ForwardToScreen

; DirmdEmulator dispatch case C
IvDirmdScreenProc_OnOldTitle:
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	calr ScreenProc
	call GetTitleOld
	ld xwa, xhl
	ld xbc, EVT_GET_TITLE_PROC_ID
	ld xde, 0:i3
	call SendEvent
	ld xiz, xhl
	call SleepMainTask
	ld xwa, xiz
	ld xbc, EVT_HIDE
	ld xde, (xsp + 4)
	call FuncCall
	call WakeUpMainTask
	ldw (DIRMD_FLAG:24), 0x0000
	jrl TaskWake_ZeroReturn
IvDirmdScreenProc_OnShow:
	ldw (DIRMD_FLAG:24), 0x0001
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	jr IvDirmd_ForwardToScreen
IvDirmdScreenProc_OnHide:
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	calr ScreenProc
	ld wa, 2:i3
	call ChangePalette
	jr TaskWake_ZeroReturn
IvDirmdScreenProc_OnAllPaint:
	ldw (DIRMD_FLAG:24), 0x0001
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_GET_TITLE_PROC_ID
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
IvDirmdScreenProc_OnParaDraw:
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_GET_TITLE_PROC_ID
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
IvDirmdScreenProc_OnSwIn:
	ld xwa, (xsp + 4)
	cp xwa, 0xff
	jr ugt, IvDirmd_ForwardAndReturn
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_GET_TITLE_PROC_ID
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
IvDirmdScreenProc_OnGetBoxBorder:
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
	ld hl, (DIRMD_FLAG:24)
	ret

DirmdTitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, DirmdTitleFunc_PtrTable
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	calr DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret
DirmdTitle_New:
	ld	a, (ACTIVE_TITLE:16)
	cp	a, (ACTIVE_TITLE_PREVIOUS:16)
	jr	z, PostTitle_Function_Skip
	ldw	wa, 255
	call	GraphicsRender_ByteData
	ldw	wa, 245
	call	Display_SetBackgroundColor
	call	Display_LoadFixedPaletteBands
	ldw	wa, 255
	call	Display_FillPaletteBandFromEntry
PostTitle_Function_Skip:
	ld	xwa, DirmdTitleFunc_Str_DirmdTitleNew
	call	DbMemo_PostString
	jp	PsMixer_CtlTypeProc8_Return
; DirmdTitle_Old: DirmdTitle emulator method [1] (Old), called by DirmdEmulator on EVT_HIDE: posts the trace memo
;   "DirmdTitleOld();" (DbMemo_PostString) and tail-jumps to an empty `ret` (PsMixer_CtlTypeProc8_Return2)
DirmdTitle_Old:
	ld	xwa, DirmdTitleFunc_Str_DirmdTitleOld
	call	DbMemo_PostString
	jp	PsMixer_CtlTypeProc8_Return2
DirmdTitle_ESw:
	lda	xsp, (xsp-256)
	pushw	iz
	pushw	(xsp+264)
	ld	iz, (xsp+264)
	pushw	iz
	pushw DirmdTitleFunc_Str_DirmdTitleESw_Fmtd_Fmtd@hi16
	pushw DirmdTitleFunc_Str_DirmdTitleESw_Fmtd_Fmtd@lo16
	lda	xwa, (xsp+10)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+12)
	lda	xwa, (xsp+2)
	call	DbMemo_PostString
	ld	wa, iz
	ld	bc, (xsp+264)
	call	DirmdTitle_SwitchInNullRet
	popw	iz
	lda	xsp, (xsp+256)
	ret
; DirmdTitle_Cur: DirmdTitle emulator method [3] (Cur): posts the trace memo "DirmdTitleCur();" and tail-jumps to an
;   empty `ret` (PsMixer_CtlTypeProc8_Return3); DirmdEmulator never calls slot 3
DirmdTitle_Cur:
	ld	xwa, DirmdTitleFunc_Str_DirmdTitleCur
	call	DbMemo_PostString
	jp	PsMixer_CtlTypeProc8_Return3
DirmdEmulator_Entry:

DirmdEmulator:
	push xiz
	ld xiz, xwa
	sub xbc, EVT_NONE
	cp xbc, 0x0
	jrl lt, DirmdEmu_DefaultCase
	cp xbc, 0xf
	jrl gt, DirmdEmu_DefaultCase
	add xbc, xbc
	add xbc, DirmdEmulator_CaseTable
	ld bc, (xbc)
	lda xix, (DirmdEmulator_Dispatch:24)
	jp	t, (xix+bc)
DirmdEmulator_Dispatch:	; EVT_HIDE: method 1
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
	jr	DirmdEmu_DefaultCase
DirmdEmu_OnAllPaint:	; EVT_ALL_PAINT: clear the redraw mode, reset the drawing state, method 0
	ld	(58138:16), 0
	ldw	wa, 255
	call	GraphicsRender_ByteData
	ldw	wa, 245
	call	Display_SetBackgroundColor
	call	Display_LoadFixedPaletteBands
	ldw	wa, 255
	call	Display_FillPaletteBandFromEntry
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
	jr	DirmdEmu_DefaultCase
DirmdEmu_OnParaDraw:	; EVT_PARA_DRAW: method 0 with the redraw mode at 16
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
	jr	DirmdEmu_DefaultCase
DirmdEmu_OnSwitchIn:	; EVT_SW_IN: switches 0..255 only; method 2 (switch & 31, bit 7)
	cp	xde, 255
	jr	ugt, DirmdEmu_DefaultCase
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
	cp xbc, EVT_DIAL
	jrl z, WindowProc_ForwardToGroupBoxes
	ld xwa, (xsp + 20)
	cp xwa, EVT_RETURN_TITLE
	jrl z, WindowProc_ForwardToGroupBoxes
	cp xwa, EVT_INTERRUPT_TITLE
	jrl z, WindowProc_ForwardToGroupBoxes
	cp xwa, EVT_CHANGE_TITLE
	jrl z, WindowProc_ForwardToGroupBoxes
	cp xwa, EVT_CHANGE_MODE
	jrl z, WindowProc_ForwardToGroupBoxes
	cp xwa, EVT_SW_IN_MODE
	jrl z, WindowProc_ForwardToGroupBoxes
	cp xwa, EVT_AUTO_INC
	jrl z, WindowProc_ForwardToGroupBoxes
	cp xwa, EVT_CHECK_SHOW_WINDOW
	jrl z, WindowField_GetChildCount
	cp xwa, EVT_GET_CHILD_WINDOW
	jrl z, WindowField_ReadValue
	cp xwa, EVT_SET_CHILD_WINDOW
	jrl z, WindowField_Focus
	cp xwa, EVT_GET_PARENT_WINDOW
	jrl z, WindowField_GetValue
	cp xwa, EVT_SET_PARENT_WINDOW
	jrl z, WindowField_SetValue
	sub xbc, EVT_SHOW
	cp xbc, 0x0
	jrl lt, WindowProc_DefaultHandler
	cp xbc, 0x9
	jrl gt, WindowProc_DefaultHandler
	add xbc, xbc
	add xbc, WindowProc_CaseTable
	ld bc, (xbc)
	lda xix, (WindowProc_EventDispatch:24)
	jp	t, (xix+bc)
; WindowProc event dispatch
WindowProc_EventDispatch:
	ld	xwa, (xsp+24)
	call	GetViewInstance
	ld	(xsp+12), xhl
	ld	xwa, (xsp+16)
	cp	xwa, 4
	jr	z, WindowProc_Skip4
	cp	xwa, 3
	jr	z, WindowProc_Skip
	cp	xwa, 5
	jr	z, WindowProc_Skip
	or	xwa, xwa
	jr	nz, WindowProc_Skip4
WindowProc_Skip:
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+28)
	ld	xwa, (xwa)
	cp	xwa, 0xffffffff
	jr	z, WindowProc_Skip2
	ld	xwa, (xsp+24)
	ld	xbc, EVT_HIDE
	ld	xde, 0:i3
	call	SendEvent
WindowProc_Skip2:
	call	GetCurrentTarget
	ld	xiz, xhl
	ld	xwa, xiz
	ld	xbc, EVT_GET_CHILD_WINDOW
	ld	xde, 0:i3
	call	SendEvent
	cp	xhl, 0xffffffff
	jr	z, WindowProc_Skip3
WindowProc_Loop:
	ld	xiz, xhl
	ld	xwa, xiz
	ld	xbc, EVT_GET_CHILD_WINDOW
	ld	xde, 0:i3
	call	SendEvent
	cp	xhl, 0xffffffff
	jr	nz, WindowProc_Loop
WindowProc_Skip3:
	ld	xde, (xsp+24)
	ld	xwa, xiz
	ld	xbc, EVT_SET_CHILD_WINDOW
	call	SendEvent
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+28)
	ld	(xwa), xiz
WindowProc_Skip4:
	ld	xwa, (xsp+24)
	ld	xbc, (xsp+20)
	ld	xde, (xsp+16)
	calr	GroupBoxProc
	ld	xwa, (xsp+16)
	cp	xwa, 4
	jrl	nz, AcNaming_ReturnZero
	ld	xwa, (xsp+12)
	ld	xbc, (xwa+32)
	ld	xwa, (xbc)
	cp	xwa, 0xffffffff
	jrl	z, AcNaming_ReturnZero
	ld	xwa, (xbc)
	ld	xbc, (xsp+20)
	ld	xde, (xsp+16)
	call	SendEvent
	jrl	AcNaming_ReturnZero
WindowProc_OnHide:
	ld	xwa, (xsp+24)
	ld	xbc, (xsp+20)
	ld	xde, (xsp+16)
	calr	GroupBoxProc
	ld	xwa, (xsp+24)
	call	GetViewInstance
	ld	(xsp+12), xhl
	ld	xwa, (xsp+16)
	cp	xwa, 3
	jrl	z, WindowProc_Skip10
	cp	xwa, 4
	jr	z, WindowProc_Skip6
	cp	xwa, 5
	jr	z, WindowProc_Skip5
	or	xwa, xwa
	jrl	nz, AcNaming_ReturnZero
WindowProc_Skip5:
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+28)
	ld	xwa, (xwa)
	cp	xwa, 0xffffffff
	jrl	z, AcNaming_ReturnZero
WindowProc_Skip6:
	ld	xde, (xsp+12)
	ld	xbc, (xde+28)
	ld	xwa, (xbc)
	cp	xwa, 0xffffffff
	jr	z, WindowProc_Skip7
	ld	xwa, (xde+32)
	ld	xde, (xwa)
	ld	xwa, (xbc)
	ld	xbc, EVT_SET_CHILD_WINDOW
	call	SendEvent
WindowProc_Skip7:
	ld	xde, (xsp+12)
	ld	xbc, (xde+32)
	ld	xwa, (xbc)
	cp	xwa, 0xffffffff
	jr	z, WindowProc_Skip8
	ld	xwa, (xde+28)
	ld	xde, (xwa)
	ld	xwa, (xbc)
	ld	xbc, EVT_SET_PARENT_WINDOW
	call	SendEvent
WindowProc_Skip8:
	call	GetCurrentTarget
	cp	xhl, (xsp+24)
	jr	nz, WindowProc_Skip9
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+28)
	ld	xwa, (xwa)
	call	SetCurrentTarget
WindowProc_Skip9:
	ld	xde, (xsp+12)
	ld	xbc, (xde+28)
	ld	xwa, 0xffffffff
	ld	(xbc), xwa
	ld	xbc, (xde+32)
	ld	(xbc), xwa
	jrl	AcNaming_ReturnZero
WindowProc_Skip10:
	call	GetCurrentTarget
	cp	xhl, (xsp+24)
	jrl	nz, AcNaming_ReturnZero
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+28)
	ld	xwa, (xwa)
	jrl	WindowProc_RestoreTarget

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
WindowProc_OnAllPaint:
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
WindowProc_OnSwIn:	; cases 29360135, 29360136, 29360137
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
	srl xwa, 16
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
	cp xwa, EVT_I_AM_SELECTED
	jrl z, WndScroll_HandleDialPage
	cp xwa, EVT_SET_CHARA
	jrl z, WndScroll_HandleCharSet
	cp xwa, EVT_SET_CURSOR
	jrl z, WndScroll_HandleCharInput
	ld xhl, (xsp + 42)
	ld de, hl
	cp xwa, EVT_SET_PAGE
	jrl z, WndScroll_HandleIndexChange
	cp xwa, EVT_SET_AP_FUNCTION
	jrl z, WndScroll_StoreCallerPtr
	cp xwa, EVT_GET_STRING
	jrl z, WndScroll_CopyFromSource
	cp xwa, EVT_SET_STRING
	jrl z, WndScroll_CopyStringAndSend
	cp xwa, EVT_INDEXSW_DOWN
	jrl z, WndEvt_DispatchByEventCode
	cp xwa, EVT_INDEXSW_DOWN_AIC
	jrl z, WndEvt_DispatchByEventCode
	cp xwa, EVT_INDEXSW_UP
	jrl z, WndEvt_DispatchByEventCode
	cp xwa, EVT_INDEXSW_UP_AIC
	jrl z, WndEvt_DispatchByEventCode
	lda xbc, (xsp + 34)
	cp xwa, EVT_PARA_DRAW
	jrl z, WndScroll_RepaintAll
	cp xwa, EVT_SELE_DRAW
	jrl z, WndScroll_HandleSelectionChange
	cp xwa, EVT_HIDE
	jrl z, WndScroll_BasicWindowProc
	cp xwa, EVT_REPAINT
	jrl z, WndScroll_InitSelectionTrack
	cp xwa, EVT_PAINT
	jrl z, WndScroll_InitSelectionTrack
	cp xwa, EVT_SHOW
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
	ld xwa, NAKA_APFUNC_NamingCheck
	ld (0x0274d2:24), xwa

AcNaming_InitScrollState:
	ldw (0x0274d8:24), 0x0000
	ldw (0x0274da:24), 0x0000
	ld xwa, (0x0274d2:24)
	ld xbc, EVT_GET_STRING_LENGTH
	ld xde, 0:i3
	call ApFuncCall
	ld (0x0274d6:24), hl
	cp hl, 0x20
	jr ule, AcNaming_QueryCharSet
	ldw (0x0274d6:24), 0x0020

AcNaming_QueryCharSet:
	ld xwa, (0x0274d2:24)
	ld xbc, EVT_GET_NAMING_MODE
	ld xde, 0:i3
	call ApFuncCall
	ld (0x0274e2:24), hl
	ld wa, hl
	extz xwa
	sll xwa, 2
	ld xbc, AcNaming_FillCharByMode
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
