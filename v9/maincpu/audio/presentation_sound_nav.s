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
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00009
	call SendEvent
	ld xde, (xsp + 30)
	ld xwa, (xsp + 38)
	ld xbc, 0x1C00034
	call SendEvent

; Builds an SSF presentation workspace and sends event 0x1C0001C via direct
; SendEvent (FA9660).  This is the CRITICAL path that allows
; AcPresentationControlProc to pass its 0xB80A type-tag check and start
; SSF playback.
;
; The workspace (at XSP+14) is populated byte-by-byte from XSP+30/31:
;   workspace[0] = byte at (XSP+31)   -- must be 0x0A for tag 0x0000B80A
;   workspace[1] = byte at (XSP+30)   -- must be 0xB8
;   workspace[2..3] = shifted/zero bytes
;
; Reached via event 0x1C00038 (direct) or event 0x1C00030 (via
; GroupBoxProc_Ev1C00030 fall-through).
GroupBoxProc_StartSSFPresentation:
	ld xwa, (xsp + 38)
	call SetRootObject
	ld xwa, 0x1C0001C
	call SetRootEvent
	lda xwa, (xsp + 18)
	call SetRootParam
	lda xbc, (xsp + 30)
	ld xde, xbc
	inc 1, xde
	lda xwa, (xsp + 14)
	ld c, (xbc)
	ld (xwa + 3), c
	ld_spib C, 0xE8
	ld (xwa + 2), c
	ld_spib C, 0xE8
	ld (xwa + 1), c
	ld c, (xde)
	ld (xwa), c
	lda xbc, (xsp + 10)
	lda xde, (xsp + 8)
	call SndParam_ResolveWidget
	cp hl, 0xFFFF
	jrl z, GroupBox_ReturnZero

; Loop body: iterates over SSF items via FCD437, builds workspace fields,
; and sends event 0x1C0001C for each item via direct SendEvent.
; Loops until FCD4FF reports no more items (HL == 0xFFFF).
GroupBoxProc_SSFItemLoop:
	ld xwa, (xsp + 10)
	ld (xsp + 18), xwa
	ld xwa, (xsp + 10)
	call SndParam_LookupReadOnly
	lda xde, (xsp + 18)
	ld (xde + 4), hl
	ldw (xde + 6), 0x0
	lds32 xwa, 0
	ld (xde + 8), xwa
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0001C
	call SendEvent
	lda xwa, (xsp + 14)
	lda xbc, (xsp + 10)
	lda xde, (xsp + 8)
	call SndParam_ResolveWidget
	cp hl, 0xFFFF
	jr nz, GroupBoxProc_SSFItemLoop
	jrl GroupBox_ReturnZero

	; --- Event 0x1E0006E: Cancel/Back handler ---
	; Iterates the 17-entry widget structure array at 0x0274E8
	; (28-byte entries: stride = (ix*8 - ix)*4 = ix*28).
	; If event param (XWA) is nonzero: activates entries and sends 0x1C00026.
	; If event param is zero: deactivates entries and sends 0x1C00026.
	; Each entry has: byte[0]=active, byte[1]=enabled, dword[2]=workspace,
	; dword[6]=event(0x1C00007), dword[10]=focus_id, offset[14]=secondary.
GroupBox_CancelBack:
	lds iz, 0

GroupBox_CancelBack_Loop:
	ld ix, iz
	extz xix
	lda_24 xiy, 0x0274e8
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
	ld xwa, 0x1C00007
	ld (xbc + 6), xwa
	ld (xbc + 10), xix
	lda xwa, (xde + 14)
	add xiy, xwa
	ld xwa, (xsp + 38)
	ld (xiy + 2), xwa
	ld xwa, 0x1C00007
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
	ld xwa, 0x1C00026
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
	ld xwa, 0x274E8
	add xwa, xbc
	cp (xwa), 0x0
	jrl z, GroupBox_CancelBack_LoopNext
	inc 1, xwa
	cp (xwa), 0x0
	jrl nz, GroupBox_CancelBack_LoopNext
	ld (xwa), 0x1
	ld xwa, 0x1C00026
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
	ld xwa, 0x1C00026
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
	ld xwa, 0x274E8
	add xwa, xbc
	cp (xwa), 0x0
	jr z, GroupBox_CancelBack_LoopNext
	inc 1, xwa
	cp (xwa), 0x0
	jr z, GroupBox_CancelBack_LoopNext
	ld (xwa), 0x0
	ld xwa, 0x1C00026
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

	; --- Event 0x1E0006F: Dial Enable ---
	; Stores WA (from XBC param) into dial enable register at 0x03EF50.
GroupBox_DialEnable:
	ld wa, bc
	calr SetDialEnable
	jrl GroupBox_ReturnZero

	; --- Event 0x1E00070: Dial Down ---
	; Registers down-direction parameters (workspace, event 0x1C00007, param)
	; into dial state at 0x03EF56/5E/66 and updates dial focus.
GroupBox_DialDown:
	ld xde, (xsp + 30)
	ld xwa, (xsp + 38)
	ld xbc, 0x1C00007
	calr SetDialDown
	jrl GroupBox_ReturnZero

	; --- Event 0x1E00071: Dial Up ---
	; Registers up-direction parameters (workspace, event 0x1C00007, param)
	; into dial state at 0x03EF52/5A/62 and updates dial focus.
GroupBox_DialUp:
	ld xde, (xsp + 30)
	ld xwa, (xsp + 38)
	ld xbc, 0x1C00007
	calr SetDialUp
	jrl GroupBox_ReturnZero

	; --- Event 0x1E00088: Get Dial Focus ---
	; Returns current dial focus value from 0x03EF6A in XHL.
GroupBox_GetDialFocus:
	calr GetDialFocus
	jrl GroupBox_Epilogue

	; --- Event 0x1E00087: Set Dial Focus ---
	; Stores dial focus (XWA) at 0x03EF6A and broadcasts 0x1C0002C.
GroupBox_SetDialFocus:
	calr SetDialFocus
	jrl GroupBox_ReturnZero

	; --- Events 0x1E00079/0x1E00078: UP/DOWN Navigation ---
	; Calls 0xFA5867 (lookup), then dispatches 0x1E000B4 via FA9660.
	; Falls through to loop that broadcasts 0x1C00009 (close/hide) to
	; all active entries in the 0x0274E8 structure array.
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
	lds wa, 0
	calr SetDialEnable
	ld xwa, 0xFFFFFFFF
	st32_24 0x03ef6a, xwa
	call InitializeTimer
	ld xwa, (xsp + 38)
	ld xbc, 0x1E000B4
	lds32 xde, 0

GroupBox_NavDispatch:
	call SendEvent
	jr GroupBox_ReturnZero
	lds iz, 0

GroupBox_CloseAll_Loop:
	ld de, iz
	extz xde
	ld xwa, xde
	sll xwa, 3
	sub xwa, xde
	sll xwa, 2
	ld xbc, 0x274E8
	add xbc, xwa
	cp (xbc), 0x0
	jr z, GroupBox_CloseAll_Secondary
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00009
	call SendEvent

GroupBox_CloseAll_Secondary:
	ld wa, iz
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	sll xbc, 2
	lda xwa, (xbc + 14)
	ld xbc, 0x274E8
	add xbc, xwa
	cp (xbc), 0x0
	jr z, GroupBox_CloseAll_Next
	ld de, iz
	add de, 0x80
	extz xde
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00009
	call SendEvent

GroupBox_CloseAll_Next:
	inc 1, iz
	cp iz, 0x10
	jr ule, GroupBox_CloseAll_Loop
	jr GroupBox_ReturnZero

	; --- Event 0x1C00036: Display Update ---
	; Enables display (FAA761 with WA=1), calls UpdateScreen, then disables.
GroupBox_DisplayUpdate:
	lds wa, 1
	call SetNeedUpdate
	call UpdateScreen
	lds wa, 0

GroupBox_DisableDisplay:
	call SetNeedUpdate

GroupBox_ReturnZero:
	lds32 xhl, 0
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
	st16_24 0x03ef50, xwa
	ret

GetDialEnableState:
	ld16_24 xhl, 0x03ef50
	ret

SetDialFocus:
	ld xde, xwa
	cpdm32_24 257898, xde
	ret z
	st32_24 0x03ef6a, xde
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0002C
	call SendEvent
	ret

GetDialFocus:
	cpdi16_24 257872, 0
	jr nz, GetDialFocus_Active
	ld xhl, 0xFFFFFFFF
	ret

GetDialFocus_Active:
	ld32_24 xhl, 0x03ef6a
	ret

SetDialUp:
	st32_24 0x03ef52, xwa
	st32_24 0x03ef5a, xbc
	st32_24 0x03ef62, xde
	jr SetDialFocus

SetDialDown:
	st32_24 0x03ef56, xwa
	st32_24 0x03ef5e, xbc
	st32_24 0x03ef66, xde
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
	cp xhl, 0x1C00026
	jr z, EventParam_FetchPoint
	cp xhl, 0x1C00009
	jr z, EventParam_FetchPoint
	cp xhl, 0x1C00007
	jr z, EventParam_FetchPoint
	cp xhl, 0x1C00008
	jrl nz, ApTimer_SetupReturn

EventParam_FetchPoint:
	call GetRootParam
	ld (xsp + 2), xhl
	ld xwa, (xsp + 2)
	cp xwa, 0xFF
	jrl ugt, ApTimer_SetupReturn
	ld xwa, (xsp + 2)
	and xwa, 0x1F
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
	ld xbc, 0x274E8
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
	lda_24 xwa, 0x0274e9
	add xwa, xhl
	ld (xwa), 0x1
	ld xwa, 0x1C00026
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
	cp xwa, 0x1E0004A
	jrl z, Screen_GetDefault
	cp xwa, 0x1E00048
	jrl z, Screen_ReturnZero
	cp xwa, 0x1E0004B
	jrl z, Screen_GetStoredValue
	cp xwa, 0x1E00049
	jrl z, Screen_SetStoredValue
	cp xwa, 0x1C00007
	jrl z, Screen_OK
	cp xwa, 0x1C00009
	jrl z, Screen_Deactivate
	cp xwa, 0x1C0000D
	jrl z, Screen_Paint
	cp xwa, 0x1C00002
	jrl z, Screen_Close
	cp xwa, 0x1C00001
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
	ld xbc, 0x1E0004B
	lds32 xde, 0
	call SendEvent
	cp xhl, 0xFFFFFFFF
	jr nz, Screen_Init_RegisterChild
	call GetCurrentTarget
	ld xwa, xhl
	ld xbc, 0x1E00014
	ld xde, 0x1600033
	call SendEvent
	or xhl, xhl
	jr nz, Screen_Init_Setup

Screen_Init_CloseDeadChildren:
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00002
	ld xde, xiz
	call SendEvent
	call GetCurrentTarget
	ld xwa, xhl
	ld xbc, 0x1E00014
	ld xde, 0x1600033
	call SendEvent
	or xhl, xhl
	jr z, Screen_Init_CloseDeadChildren

Screen_Init_Setup:
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00002
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
	ld xwa, 0xFFFFFFFF
	ld (xbc), xwa

Screen_Init_SetWall:
	calr PostTitle_Function
	cps hl, 0
	call_24 nz, 0xF9883C
	ld xwa, (xsp + 12)
	ld xbc, 0x1E000B1
	lds32 xde, 0
	call SendEvent
	ld wa, hl
	calr SetWallPaper
	ld xwa, (xsp + 12)
	ld xbc, 0x1E000B2
	lds32 xde, 0
	call SendEvent
	ld wa, hl
	calr SetWallColor
	calr PostTitle_Function
	cps hl, 0
	call_24 nz, 0xF9884B
	call GetTitleNow
	ld xwa, xhl
	ld xde, (xsp + 12)
	ld xbc, 0x1E00077
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
	cp xwa, 0xFFFFFFFF
	jr z, Screen_ReturnZero
	ld xwa, (xbc)
	ld xbc, (xsp + 8)
	ld xde, xiz
	call SendEvent

Screen_ReturnZero:
	lds32 xhl, 0
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
	ld xwa, 0xFFFFFFFF
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
	lds wa, 1
	call SetNeedUpdate
	call UpdateScreen
	lds wa, 0
	call SetNeedUpdate
	jr Screen_ReturnZero

Screen_OK:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 12)
	ld xbc, 0x1E00024
	ld xde, 0x1600047
	call SendEvent
	or xhl, xhl
	jr nz, Screen_OK_Forward
	cp xiz, 0xF
	jr nz, Screen_OK_Forward
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1E0007A
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr nz, Screen_OK_NavUp
	ld xwa, (xsp + 4)
	ld xde, (xwa + 26)
	cp xde, 0x1A00000
	jr z, Screen_OK_Forward
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00015
	jr Screen_OK_PostAndDispatch

Screen_OK_NavUp:
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1E00079
	lds32 xde, 0
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1E0009A
	lds32 xde, 0

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
	ld xhl, 0xFFFFFFFF

Screen_Return:
	pop xiz
	lda xsp, (xsp + 12)
	ret

GetEditSwPoint:
	ld hl, wa
	lda xde, (xbc + 2)
	cp wa, 0x8C
	jr z, EditSwParam_Mode4
	cp wa, 0x8B
	jr z, EditSwParam_Mode3
	cp wa, 0x8A
	jr z, EditSwParam_Mode2
	cp wa, 0x89
	jr z, EditSwParam_Mode1
	cp wa, 0x88
	jr z, EditSwParam_Mode0
	cp hl, 0xC
	jrl ugt, EditSwParam_Default
	add hl, hl
	lda_24 xix, 0xea9b1c
	ld_sriw3 HL, 0x07, 0xF0, 0xEC
	lda_24 xix, 0xf9a973
	jp_dri 8, 0x07, 0xF0, 0xEC

; GetEditSwPoint handler: mode 0 (value=0x2B)
EditSwParam_Mode0:
	lds wa, 0
	jr EditSwParam_StoreMode0
	ldw wa, 0x13F

EditSwParam_StoreMode0:
	ld (xbc), wa
	ldw (xde), 0x2B
	ret

; GetEditSwPoint handler: mode 1 (value=0x55)
EditSwParam_Mode1:
	lds wa, 0
	jr EditSwParam_StoreMode1
	ldw wa, 0x13F

EditSwParam_StoreMode1:
	ld (xbc), wa
	ldw (xde), 0x55
	ret

; GetEditSwPoint handler: mode 2 (value=0x7F)
EditSwParam_Mode2:
	lds wa, 0
	jr EditSwParam_StoreMode2
	ldw wa, 0x13F

EditSwParam_StoreMode2:
	ld (xbc), wa
	ldw (xde), 0x7F
	ret

; GetEditSwPoint handler: mode 3 (value=0xA9)
EditSwParam_Mode3:
	lds wa, 0
	jr EditSwParam_Mode3_Store
	ldw wa, 0x13F

; GetEditSwPoint: store mode 3 result
EditSwParam_Mode3_Store:
	ld (xbc), wa
	ldw (xde), 0xA9
	ret

; GetEditSwPoint handler: mode 4 (value=0xD3)
EditSwParam_Mode4:
	lds wa, 0
	jr EditSwParam_Mode4_Store
	ldw wa, 0x13F

; GetEditSwPoint: store mode 4 result
EditSwParam_Mode4_Store:
	ld (xbc), wa
	ldw (xde), 0xD3
	ret

; GetEditSwPoint handler: tempo table lookup
EditSwParam_TempoTable:
	ldw	wa, 0x0014
	.asciz "h!0<"
	jr	28
	ldw	wa, 100
	jr	23
	ldw	wa, 140
	jr	18
	ldw	wa, 180
	jr	13
	ldw	wa, 220
	jr	8
	ldw	wa, 260
	jr	3
	ldw	wa, 300
	ld	(xbc), wa
	.long NakaState_PresentationTail
	ret

; GetEditSwPoint handler: default (value=0xA0/0x78)
EditSwParam_Default:
	ldw (xbc), 0xA0
	ldw (xde), 0x78
	ret

SetWallPaper:
	cps wa, 0
	jr mi, SetWallPaper_Default
	cps wa, 5
	jr gt, SetWallPaper_Default
	add wa, wa
	lda_24 xix, 0xea9b36
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0xf9aa0d
	jp_dri 8, 0x07, 0xF0, 0xE0

SetWallPaper_DispatchData:
	cpdi16_24	213246, 0
	jr	nz, 28

SetWallPaper_Default:
	lds wa, 0
	jp ChangeWall
SetWallPaper_CaseData:
	cpdi16_24	213242, 0
	jr	nz, 13
	lds	wa, 1
	jr	-17
	cpdi16_24	213244, 0
	jr	z, -13
	lds	wa, 2
	jr	t, 0xe2

SetWallColor:
	cps wa, 1
	jr z, SetWallColor_01
	cp wa, 0xF9
	jr z, SetWallColor_F9
	cps wa, 2
	jr z, SetWallColor_02
	cp wa, 0xF8
	jr z, SetWallColor_F8
	lds wa, 0
	jr UI_ChangeWallPalette_Jump

SetWallColor_F8:
	lds wa, 2
	jr UI_ChangeWallPalette_Jump

SetWallColor_02:
	lds wa, 4
	jr UI_ChangeWallPalette_Jump

SetWallColor_F9:
	lds wa, 6
	jr UI_ChangeWallPalette_Jump

SetWallColor_01:
	ldw wa, 0x8

UI_ChangeWallPalette_Jump:
	jp ChangeWallPalette

IvScreenProc:
	cp xbc, 0x1C0000D
	jrl nz, ScreenProc
	lds32 xhl, 0
	ret

TtlScreenProc:
	lda xsp, (xsp - 12)
	push xiz
	ld xiz, xwa
	cp xbc, 0x1C0000D
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
	lds bc, 4
	ldirw
	ld xwa, xiz
	ld xbc, 0x1E00024
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
	lds de, 0
	calr DrawTitleBar
	lds32 xhl, 0

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
	add de, 0x1B
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
	lds iz, 0

DrawTitleBar_CalcLayout:
	lda xde, (xsp + 24)
	lds wa, 7
	calr GetClientBox2
	lda xwa, (xsp + 24)
	add (xwa), iz
	lda xbc, (xsp + 12)
	calr GetBoxCenter
	lds32 xwa, 4
	ld (xsp + 4), xwa
	ld xiz, (xsp + 52)
	ld xwa, xiz
	lds32 xbc, 4
	call CalcTotalWidth
	ld (xsp + 8), hl
	ld e, (xsp + 40)
	lda xwa, (xsp + 24)
	lda xbc, (xsp + 12)
	cp (xsp + 40), 0x2
	jrl z, DrawTitleBar_RightJustify
	cps e, 1
	jrl z, DrawTitleBar_LeftJustify
	cps e, 0
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
	lds32 xwa, 1
	ld (xsp + 4), xwa
	ld xwa, xiz
	lds32 xbc, 1
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
	lds32 xwa, 1
	ld (xsp + 4), xwa
	ld xwa, xiz
	lds32 xbc, 1
	call CalcTotalWidth
	ld (xsp + 8), hl

StringCenter_Entry:
	lda xwa, (xsp + 24)
	lda xbc, (xsp + 12)
	ld xde, (xsp + 4)
	push xde
	pushw 0xFF
	pushw 0xF7
	ld xde, xiz
	call DrawStringCentered
	jr StringDraw_JoinPoint

DrawTitleBar_LeftJustify:
	lds32 xde, 4
	push xde
	pushw 0xFF
	pushw 0xF7
	ld xde, xiz
	call DrawStringLeftJustify
	jr StringDraw_JoinPoint

DrawTitleBar_RightJustify:
	lds32 xde, 4
	push xde
	pushw 0xFF
	pushw 0xF7
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
	add wa, 0x1C
	sub (xhl), wa
	lda xde, (xhl + 2)
	submi16 (xde), 0xB
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
	ldw bc, 0xC4
	ldw de, 0xF0
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
	cp xbc, 0x1E000B1
	jrl z, DirmdEmu_CaseD
	ld xwa, (xsp + 8)
	cp xwa, 0x1C0003A
	jr z, DirmdEmu_CaseC
	cp xwa, 0x1C00039
	jr z, DirmdEmu_CaseB
	sub xbc, 0x1C00001
	cp xbc, 0x0
	jrl lt, DirmdEmu_CaseE
	cp xbc, 0xE
	jrl gt, DirmdEmu_CaseE
	add xbc, xbc
	add xbc, 0xEA9B42
	ld bc, (xbc)
	lda_24 xix, 0xf9acba
	jp_dri 8, 0x07, 0xF0, 0xE4

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
	ld xbc, 0x1E00032
	lds32 xde, 0
	call SendEvent
	ld xiz, xhl
	call SleepMainTask
	ld xwa, xiz
	ld xbc, 0x1C00002
	ld xde, (xsp + 4)
	call FuncCall
	call WakeUpMainTask
	sti16_24 0x0276c4, 0x0000
	jrl TaskWake_ZeroReturn
	sti16_24 0x0276c4, 0x0001
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	jr IvDirmd_ForwardToScreen
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	calr ScreenProc
	lds wa, 2
	call ChangePalette
	jr TaskWake_ZeroReturn
	sti16_24 0x0276c4, 0x0001
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1E00032
	lds32 xde, 0
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
	ld xbc, 0x1E00032
	lds32 xde, 0
	call SendEvent
	ld xiz, xhl
	call SleepMainTask
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call FuncCall
	call WakeUpMainTask

TaskWake_ZeroReturn:
	lds32 xhl, 0
	jr IvDirmd_Epilogue
	ld xwa, (xsp + 4)
	cp xwa, 0xFF
	jr ugt, IvDirmd_ForwardAndReturn
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1E00032
	lds32 xde, 0
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
	ld16_24 xhl, 0x0276c4
	ret

DirmdTitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, 0xEA9B60
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	calr DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

; DirmdEmulator dispatch case F
DirmdEmu_CaseF:
	ldda8	a, 36152
	cpda8	a, 36153
	jr	z, 25
	ldw	wa, 255
	call	16454736
	ldw	wa, 245
	call	16454730
	call	16454839
	ldw	wa, 255
	call	16454742
	ld	xwa, 15375216
	call	16395937
	jp	16262336
	ld	xwa, 15375234
	call	16395937
	jp	16262337
	lda	xsp, (xsp-256)
	pushw	iz
	pushm	(xsp+264)
	ld	iz, (xsp+264)
	pushw	iz
	pushw 234
	pushw 39828
	lda	xwa, (xsp+10)
	push	xwa
	call	16714340
	lda	xsp, (xsp+12)
	lda	xwa, (xsp+2)
	call	16395937
	ld	wa, iz
	ld	bc, (xsp+264)
	call	16262338
	popw	iz
	.byte 0xf3, 0xfd, 0x00, 0x01, 0x37
	ret
	ld	xwa, 15375276
	call	16395937
	jp	16262339
DirmdEmulator_Entry:

DirmdEmulator:
	push xiz
	ld xiz, xwa
	sub xbc, 0x1C00000
	cp xbc, 0x0
	jrl lt, DirmdEmu_DefaultCase
	cp xbc, 0xF
	jrl gt, DirmdEmu_DefaultCase
	add xbc, xbc
	add xbc, 0xEA9BBE
	ld bc, (xbc)
	lda_24 xix, 0xf9aec6
	jp_dri 8, 0x07, 0xF0, 0xE4
DirmdEmulator_Dispatch:	.ascii ":;<>"
	ld	xwa, (xiz+4)
	call	(xwa)
	.ascii "^\\[Zhqñ"
	.byte 0xe0, 0xe3, 0x00, 0x00, 0x30, 0xff, 0x00, 0x1d
	.byte 0x50, 0x14, 0xfb, 0x30, 0xf5, 0x00, 0x1d, 0x4a
	.byte 0x14, 0xfb, 0x1d, 0xb7, 0x14, 0xfb, 0x30, 0xff
	.byte 0x00, 0x1d, 0x56, 0x14, 0xfb, 0x3a, 0x3b, 0x3c
	.byte 0x3e, 0xa6, 0x20, 0xb0, 0xe8, 0x5e, 0x5c, 0x5b
	.byte 0x5a, 0x68, 0x45, 0xf1, 0xe0, 0xe3, 0x00, 0x10
	.byte 0x3a, 0x3b, 0x3c, 0x3e
	.byte 0xa6, 0x20, 0xb0, 0xe8
	.byte 0x5e, 0x5c, 0x5b, 0x5a
	.byte 0xf1, 0xe0, 0xe3, 0x00
	.byte 0x00, 0x68, 0x2d, 0xea, 0xcf, 0xff, 0x00, 0x00
	.byte 0x00
	.ascii "k%:;<>ê"
	.byte 0x89, 0xe9, 0xcc, 0x80, 0x00, 0x00, 0x00, 0xcb
	.byte 0x8a, 0x29, 0xea, 0xcc, 0x1f, 0x00, 0x00, 0x00
	.byte 0xea, 0x8b, 0x2a, 0xa8, 0x08, 0x22, 0xd9, 0x88
	.byte 0xb2, 0xe8, 0xef
	.ascii "d^\\[Z"

; DirmdEmulator default/fallthrough case
DirmdEmu_DefaultCase:
	bitda 1, 58334
	jr z, DirmdEmu_CheckModeChange
	ldda8 a, 58332
	extz wa
	call UI_PostPartChangeEvent

DirmdEmu_CheckModeChange:
	bitda 7, 58334
	jr z, DirmdEmu_CheckSoundCtrl
	ldda8 a, 58332
	extz wa
	call UI_PostModeChangeEvent

DirmdEmu_CheckSoundCtrl:
	bitda 6, 58334
	jr z, DirmdEmu_CheckBit4
	ldda8 a, 58332
	extz wa
	call SoundCtrl_SendCommand

DirmdEmu_CheckBit4:
	bitda 4, 58334
	call_24 nz, 0xF994EA
	bitda 4, 58336
	call_24 nz, 0xF994FA
	bitda 3, 58338
	jr z, DirmdEmu_ClearAllFlags
	lds wa, 1
	call UI_PostEvent_0x6E

DirmdEmu_ClearAllFlags:
	stdi8 58334, 0
	stdi8 58332, 0
	stdi8 58336, 0
	stdi8 58338, 0
	stdi8 58340, 255
	stdi8 58342, 255
	lds32 xhl, 0
	pop xiz
	ret

WindowProc:
	lda xsp, (xsp - 24)
	push xiz
	ld (xsp + 16), xde
	ld (xsp + 20), xbc
	ld (xsp + 24), xwa
	ld xbc, (xsp + 20)
	cp xbc, 0x1C0001F
	jrl z, WindowProc_ForwardToGroupBoxes
	ld xwa, (xsp + 20)
	cp xwa, 0x1C00028
	jrl z, WindowProc_ForwardToGroupBoxes
	cp xwa, 0x1C00016
	jrl z, WindowProc_ForwardToGroupBoxes
	cp xwa, 0x1C00015
	jrl z, WindowProc_ForwardToGroupBoxes
	cp xwa, 0x1C00014
	jrl z, WindowProc_ForwardToGroupBoxes
	cp xwa, 0x1C0003B
	jrl z, WindowProc_ForwardToGroupBoxes
	cp xwa, 0x1C00026
	jrl z, WindowProc_ForwardToGroupBoxes
	cp xwa, 0x1E00094
	jrl z, WindowField_GetChildCount
	cp xwa, 0x1E0004B
	jrl z, WindowField_ReadValue
	cp xwa, 0x1E00049
	jrl z, WindowField_Focus
	cp xwa, 0x1E0004A
	jrl z, WindowField_GetValue
	cp xwa, 0x1E00048
	jrl z, WindowField_SetValue
	sub xbc, 0x1C00001
	cp xbc, 0x0
	jrl lt, WindowProc_DefaultHandler
	cp xbc, 0x9
	jrl gt, WindowProc_DefaultHandler
	add xbc, xbc
	add xbc, 0xEA9BDE
	ld bc, (xbc)
	lda_24 xix, 0xf9b061
	jp_dri 8, 0x07, 0xF0, 0xE4
; WindowProc event dispatch
WindowProc_EventDispatch:
	ld	xwa, (xsp+24)
	call	16409190
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
	cp	xwa, 4294967295
	jr	z, 14
	ld	xwa, (xsp+24)
	ld	xbc, 29360130
	lds32	xde, 0
	call	16422496
	call	16423543
	ld	xiz, xhl
	ld	xwa, xiz
	ld	xbc, 31457355
	lds32	xde, 0
	call	16422496
	cp	xhl, 4294967295
	jr	z, 23
	ld	xiz, xhl
	ld	xwa, xiz
	ld	xbc, 31457355
	lds32	xde, 0
	call	16422496
	cp	xhl, 4294967295
	jr	nz, -23
	ld	xde, (xsp+24)
	ld	xwa, xiz
	ld	xbc, 31457353
	call	16422496
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+28)
	ld	(xwa), xiz
	ld	xwa, (xsp+24)
	ld	xbc, (xsp+20)
	ld	xde, (xsp+16)
	calr	-6333
	ld	xwa, (xsp+16)
	cp	xwa, 4
	jrl	nz, 724
	ld	xwa, (xsp+12)
	ld	xbc, (xwa+32)
	ld	xwa, (xbc)
	cp	xwa, 4294967295
	jrl	z, 707
	ld	xwa, (xbc)
	ld	xbc, (xsp+20)
	ld	xde, (xsp+16)
	call	16422496
	jrl	692
	ld	xwa, (xsp+24)
	ld	xbc, (xsp+20)
	ld	xde, (xsp+16)
	calr	-6389
	ld	xwa, (xsp+24)
	call	16409190
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
	cp	xwa, 4294967295
	jrl	z, 620
	ld	xde, (xsp+12)
	ld	xbc, (xde+28)
	ld	xwa, (xbc)
	cp	xwa, 4294967295
	jr	z, 16
	ld	xwa, (xde+32)
	ld	xde, (xwa)
	ld	xwa, (xbc)
	ld	xbc, 31457353
	call	16422496
	ld	xde, (xsp+12)
	ld	xbc, (xde+32)
	ld	xwa, (xbc)
	cp	xwa, 4294967295
	jr	z, 16
	ld	xwa, (xde+28)
	ld	xde, (xwa)
	ld	xwa, (xbc)
	ld	xbc, 31457352
	call	16422496
	call	16423543
	cp	xhl, (xsp+24)
	jr	nz, 12
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+28)
	ld	xwa, (xwa)
	call	16423549
	ld	xde, (xsp+12)
	ld	xbc, (xde+28)
	ld	xwa, 4294967295
	ld	(xbc), xwa
	ld	xbc, (xde+32)
	ld	(xbc), xwa
	jrl	514
	call	16423543
	cp	xhl, (xsp+24)
	jrl	nz, 504
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+28)
	ld	xwa, (xwa)
	jrl	489

; WindowProc field set value handler (event 0x1C00048)
WindowField_SetValue:
	ld xwa, (xsp + 24)
	ld xiz, 0x1C
	jr WindowField_StoreToView

; WindowProc field get value handler (event 0x1C0004A)
WindowField_GetValue:
	ld xwa, (xsp + 24)
	ld xiz, 0x1C
	jr WindowField_ReadFromView

; WindowProc field focus handler (event 0x1C00049)
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

; WindowProc field read value handler (event 0x1C0004B)
WindowField_ReadValue:
	ld xwa, (xsp + 24)
	ld xiz, 0x20

WindowField_ReadFromView:
	call GetViewInstance
	add xhl, xiz
	ld xwa, (xhl)
	ld xhl, (xwa)
	jrl WindowProc_Epilogue

; WindowProc get child count handler (event 0x1E00094)
WindowField_GetChildCount:
	ld xwa, (xsp + 24)
	call GetViewInstance
	ld xwa, (xhl + 28)
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
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
	ld xwa, 0xFFFFFFFF
	ld xbc, (xsp + 20)
	ld xde, (xsp + 16)
	call SendEvent
	call GetCurrentTarget
	cp xhl, xiz
	jr nz, WindowField_ForwardAfterChild
	ld xwa, (xsp + 12)
	ld xwa, (xwa + 28)
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
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
	cp xwa, 0xFFFFFFFF
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
	cp xwa, 0xFFFFFFFF
	jrl z, AcNaming_ReturnZero
	ld xwa, (xsp + 4)
	jrl WindowProc_RestoreTarget

; WindowProc default handler (returns 0)
WindowProc_DefaultHandler:
	ld xwa, (xsp + 20)
	srl xwa, 0
	and xwa, 0xFFF
	cp wa, 0x1E0
	jr c, WindowProc_GroupBoxAndChild
	cp wa, 0x1FF
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
	cp xwa, 0xFFFFFFFF
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
	cp xwa, 0xFFFFFFFF
	jr z, AcNaming_ReturnZero
	ld xwa, (xsp + 8)
	call SetRootObject
	ld xwa, (xsp + 4)

WindowProc_RestoreTarget:
	call SetCurrentTarget

AcNaming_ReturnZero:
	lds32 xhl, 0

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
	cp xwa, 0x1C00029
	jrl z, WndScroll_HandleDialPage
	cp xwa, 0x1E00081
	jrl z, WndScroll_HandleCharSet
	cp xwa, 0x1E00080
	jrl z, WndScroll_HandleCharInput
	ld xhl, (xsp + 42)
	ld de, hl
	cp xwa, 0x1E0007F
	jrl z, WndScroll_HandleIndexChange
	cp xwa, 0x1E0007B
	jrl z, WndScroll_StoreCallerPtr
	cp xwa, 0x1E0003A
	jrl z, WndScroll_CopyFromSource
	cp xwa, 0x1E00086
	jrl z, WndScroll_CopyStringAndSend
	cp xwa, 0x1C00018
	jrl z, WndEvt_DispatchByEventCode
	cp xwa, 0x1C0001A
	jrl z, WndEvt_DispatchByEventCode
	cp xwa, 0x1C00017
	jrl z, WndEvt_DispatchByEventCode
	cp xwa, 0x1C00019
	jrl z, WndEvt_DispatchByEventCode
	lda xbc, (xsp + 34)
	cp xwa, 0x1C0000F
	jrl z, WndScroll_RepaintAll
	cp xwa, 0x1C0000E
	jrl z, WndScroll_HandleSelectionChange
	cp xwa, 0x1C00002
	jrl z, WndScroll_BasicWindowProc
	cp xwa, 0x1C0000C
	jrl z, WndScroll_InitSelectionTrack
	cp xwa, 0x1C0000B
	jrl z, WndScroll_InitSelectionTrack
	cp xwa, 0x1C00001
	jrl nz, WndScroll_ForwardToWindowProc
	or xhl, xhl
	jr z, AcNaming_CheckDefaultWidget
	ld xwa, xhl
	cp xwa, 0x3
	jr z, AcNaming_CheckDefaultWidget
	cp xwa, 0x5
	jrl nz, WndScroll_InitWindowProc

AcNaming_CheckDefaultWidget:
	ld32_24 xwa, 0x0274d2
	or xwa, xwa
	jr nz, AcNaming_InitScrollState
	ld xwa, 0x1200005
	st32_24 0x0274d2, xwa

AcNaming_InitScrollState:
	sti16_24 0x0274d8, 0x0000
	sti16_24 0x0274da, 0x0000
	ld32_24 xwa, 0x0274d2
	ld xbc, 0x1E0007C
	lds32 xde, 0
	call ApFuncCall
	st16_24 0x0274d6, xhl
	cp hl, 0x20
	jr ule, AcNaming_QueryCharSet
	sti16_24 0x0274d6, 0x0020

AcNaming_QueryCharSet:
	ld32_24 xwa, 0x0274d2
	ld xbc, 0x1E00084
	lds32 xde, 0
	call ApFuncCall
	st16_24 0x0274e2, xhl
	ld wa, hl
	extz xwa
	sll xwa, 2
	ld xbc, 0xEA9EEA
	add xbc, xwa
	ld xwa, (xbc)
	st32_24 0x0274e4, xwa
	cps hl, 0
	jr z, AcNaming_ShowNavButtons
	ld xwa, 0x17
	lds bc, 0
	call SetVisible
	ld xwa, 0x18
	lds bc, 0
	call SetVisible
	ld xwa, 0x19
	lds bc, 0
	jr AcNaming_SetVisibleAndInit

AcNaming_ShowNavButtons:
	ld xwa, 0x17
	lds bc, 1
	call SetVisible
	ld xwa, 0x18
	lds bc, 1
	call SetVisible
	ld xwa, 0x19
	lds bc, 1

AcNaming_SetVisibleAndInit:
	call SetVisible
	lds iz, 0
	cpdi16_24 160982, 0
	jr ule, WndScroll_InitBuffer

; --- UI Window Procs, Graphics & Mode Screens ---
