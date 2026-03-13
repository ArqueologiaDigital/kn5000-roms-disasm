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

LABEL_F9A541:
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
	jr nz, LABEL_F9A573
	ld xhl, 0xFFFFFFFF
	ret

LABEL_F9A573:
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
	jr LABEL_F9A8FB

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

LABEL_F9A8FB:
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
	jr LABEL_F9A97A
	ldw wa, 0x13F

LABEL_F9A97A:
	ld (xbc), wa
	ldw (xde), 0x2B
	ret

; GetEditSwPoint handler: mode 1 (value=0x55)
EditSwParam_Mode1:
	lds wa, 0
	jr LABEL_F9A988
	ldw wa, 0x13F

LABEL_F9A988:
	ld (xbc), wa
	ldw (xde), 0x55
	ret

; GetEditSwPoint handler: mode 2 (value=0x7F)
EditSwParam_Mode2:
	lds wa, 0
	jr LABEL_F9A996
	ldw wa, 0x13F

LABEL_F9A996:
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
	.long LABEL_EF02B2
	.byte 0x0e

; GetEditSwPoint handler: default (value=0xA0/0x78)
EditSwParam_Default:
	ldw (xbc), 0xA0
	ldw (xde), 0x78
	ret

SetWallPaper:
	cps wa, 0
	jr mi, LABEL_F9AA16
	cps wa, 5
	jr gt, LABEL_F9AA16
	add wa, wa
	lda_24 xix, 0xea9b36
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0xf9aa0d
	jp_dri 8, 0x07, 0xF0, 0xE0

LABEL_F9AA0D:
	.byte 0xd2, 0xfe, 0x40, 0x03, 0x3f, 0x00, 0x00, 0x6e
	.byte 0x1c

LABEL_F9AA16:
	lds wa, 0
	jp ChangeWall
LABEL_F9AA1C:
	.byte 0xd2, 0xfa, 0x40, 0x03, 0x3f, 0x00, 0x00, 0x6e
	.byte 0x0d, 0xd8, 0xa9, 0x68, 0xef, 0xd2, 0xfc, 0x40
	.byte 0x03, 0x3f, 0x00, 0x00, 0x66, 0xf3, 0xd8, 0xaa
	jr	t, 0xe2

SetWallColor:
	cps wa, 1
	jr z, LABEL_F9AA5A
	cp wa, 0xF9
	jr z, LABEL_F9AA56
	cps wa, 2
	jr z, LABEL_F9AA52
	cp wa, 0xF8
	jr z, LABEL_F9AA4E
	lds wa, 0
	jr UI_ChangeWallPalette_Jump

LABEL_F9AA4E:
	lds wa, 2
	jr UI_ChangeWallPalette_Jump

LABEL_F9AA52:
	lds wa, 4
	jr UI_ChangeWallPalette_Jump

LABEL_F9AA56:
	lds wa, 6
	jr UI_ChangeWallPalette_Jump

LABEL_F9AA5A:
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
	jr z, LABEL_F9AA82
	ld xwa, xiz
	calr ScreenProc
	jr LABEL_F9AAC6

LABEL_F9AA82:
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

LABEL_F9AAC6:
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
	jr z, LABEL_F9AB04
	ldw (xsp + 10), 0x40

LABEL_F9AB04:
	ldw iz, 0x18
	ld xwa, (xsp + 42)
	or xwa, xwa
	jr nz, LABEL_F9AB10
	lds iz, 0

LABEL_F9AB10:
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
	jrl z, LABEL_F9ABF6
	cps e, 1
	jrl z, LABEL_F9ABE5
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
	jr z, LABEL_F9ABBD
	add de, (xhl)
	sub de, wa
	inc 4, de
	ld wa, (xsp + 10)
	exts xwa
	divs wa, 0x2
	cp de, wa
	jr le, LABEL_F9ABB9
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

LABEL_F9ABB9:
	sub (xhl), de
	jr StringCenter_Entry

LABEL_F9ABBD:
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

LABEL_F9ABE5:
	lds32 xde, 4
	push xde
	pushw 0xFF
	pushw 0xF7
	ld xde, xiz
	call DrawStringLeftJustify
	jr StringDraw_JoinPoint

LABEL_F9ABF6:
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
	jrl LABEL_F9AD62

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
	jr LABEL_F9AD62
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

LABEL_F9AD62:
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
	jr LABEL_F9ADEB
	ld xwa, (xsp + 4)
	cp xwa, 0xFF
	jr ugt, LABEL_F9ADC4
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

LABEL_F9ADC4:
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	jr LABEL_F9ADE8

; DirmdEmulator dispatch case D
DirmdEmu_CaseD:
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	calr ScreenProc
	inc 3, xhl
	jr LABEL_F9ADEB

; DirmdEmulator dispatch case E
DirmdEmu_CaseE:
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)

LABEL_F9ADE8:
	calr ScreenProc

LABEL_F9ADEB:
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
	.byte 0xc1, 0x38, 0x8d, 0x21, 0xc1, 0x39, 0x8d, 0xf1
	.byte 0x66, 0x19, 0x30, 0xff, 0x00, 0x1d, 0x50, 0x14
	.byte 0xfb, 0x30, 0xf5, 0x00, 0x1d, 0x4a, 0x14, 0xfb
	.byte 0x1d, 0xb7, 0x14, 0xfb, 0x30, 0xff, 0x00, 0x1d
	.byte 0x56, 0x14, 0xfb, 0x40, 0x70, 0x9b, 0xea, 0x00
	.byte 0x1d, 0xa1, 0x2e, 0xfa, 0x1b, 0xc0, 0x24, 0xf8
	.byte 0x40, 0x82, 0x9b, 0xea, 0x00, 0x1d, 0xa1, 0x2e
	.byte 0xfa, 0x1b, 0xc1, 0x24, 0xf8, 0xf3, 0xfd, 0x00
	.byte 0xff, 0x37, 0x2e, 0xd3, 0xfd, 0x08, 0x01, 0x04
	.byte 0xd3, 0xfd, 0x08, 0x01, 0x26, 0x2e, 0x0b, 0xea
	.byte 0x00, 0x0b, 0x94, 0x9b, 0xbf, 0x0a, 0x30, 0x38
	.byte 0x1d, 0x72, 0x0a, 0xff, 0xbf, 0x0c, 0x37, 0xbf
	.byte 0x02, 0x30, 0x1d, 0xa1, 0x2e, 0xfa, 0xde, 0x88
	.byte 0xd3, 0xfd, 0x08, 0x01, 0x21, 0x1d, 0xc2, 0x24
	.byte 0xf8, 0x4e, 0xf3, 0xfd, 0x00, 0x01, 0x37, 0x0e
	.byte 0x40, 0xac, 0x9b, 0xea, 0x00, 0x1d, 0xa1, 0x2e
	.byte 0xfa, 0x1b, 0xc3, 0x24, 0xf8
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
	.byte 0xae, 0x04, 0x20, 0xb0
	.byte 0xe8
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
	jr z, LABEL_F9AF56
	ldda8 a, 58332
	extz wa
	call UI_PostPartChangeEvent

LABEL_F9AF56:
	bitda 7, 58334
	jr z, LABEL_F9AF66
	ldda8 a, 58332
	extz wa
	call UI_PostModeChangeEvent

LABEL_F9AF66:
	bitda 6, 58334
	jr z, LABEL_F9AF76
	ldda8 a, 58332
	extz wa
	call SoundCtrl_SendCommand

LABEL_F9AF76:
	bitda 4, 58334
	call_24 nz, 0xF994EA
	bitda 4, 58336
	call_24 nz, 0xF994FA
	bitda 3, 58338
	jr z, LABEL_F9AF94
	lds wa, 1
	call UI_PostEvent_0x6E

LABEL_F9AF94:
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
	.byte 0xaf, 0x18, 0x20, 0x1d, 0x66, 0x62, 0xfa, 0xbf
	.byte 0x0c, 0x63, 0xaf, 0x10, 0x20, 0xe8, 0xcf, 0x04
	.byte 0x00, 0x00, 0x00, 0x66, 0x7a, 0xe8, 0xcf, 0x03
	.byte 0x00, 0x00, 0x00, 0x66, 0x0c, 0xe8, 0xcf, 0x05
	.byte 0x00, 0x00, 0x00, 0x66, 0x04, 0xe8, 0xe0, 0x6e
	.byte 0x66, 0xaf, 0x0c, 0x20, 0xa8, 0x1c, 0x20, 0xa0
	.byte 0x20, 0xe8, 0xcf, 0xff, 0xff, 0xff, 0xff, 0x66
	.byte 0x0e, 0xaf, 0x18, 0x20, 0x41, 0x02, 0x00, 0xc0
	.byte 0x01, 0xea, 0xa8, 0x1d, 0x60, 0x96, 0xfa, 0x1d
	.byte 0x77, 0x9a, 0xfa, 0xeb, 0x8e, 0xee, 0x88, 0x41
	.byte 0x4b, 0x00, 0xe0, 0x01, 0xea, 0xa8, 0x1d, 0x60
	.byte 0x96, 0xfa, 0xeb, 0xcf, 0xff, 0xff, 0xff, 0xff
	.byte 0x66, 0x17, 0xeb, 0x8e, 0xee, 0x88, 0x41, 0x4b
	.byte 0x00, 0xe0, 0x01, 0xea, 0xa8, 0x1d, 0x60, 0x96
	.byte 0xfa, 0xeb, 0xcf, 0xff, 0xff, 0xff, 0xff, 0x6e
	.byte 0xe9, 0xaf, 0x18, 0x22, 0xee, 0x88, 0x41, 0x49
	.byte 0x00, 0xe0, 0x01, 0x1d, 0x60, 0x96, 0xfa, 0xaf
	.byte 0x0c, 0x20, 0xa8, 0x1c, 0x20, 0xb0, 0x66, 0xaf
	.byte 0x18, 0x20, 0xaf, 0x14, 0x21, 0xaf, 0x10, 0x22
	.byte 0x1e, 0x43, 0xe7, 0xaf, 0x10, 0x20, 0xe8, 0xcf
	.byte 0x04, 0x00, 0x00, 0x00, 0x7e, 0xd4, 0x02, 0xaf
	.byte 0x0c, 0x20, 0xa8, 0x20, 0x21, 0xa1, 0x20, 0xe8
	.byte 0xcf, 0xff, 0xff, 0xff, 0xff, 0x76, 0xc3, 0x02
	.byte 0xa1, 0x20, 0xaf, 0x14, 0x21, 0xaf, 0x10, 0x22
	.byte 0x1d, 0x60, 0x96, 0xfa, 0x78, 0xb4, 0x02, 0xaf
	.byte 0x18, 0x20, 0xaf, 0x14, 0x21, 0xaf, 0x10, 0x22
	.byte 0x1e, 0x0b, 0xe7, 0xaf, 0x18, 0x20, 0x1d, 0x66
	.byte 0x62, 0xfa, 0xbf, 0x0c, 0x63, 0xaf, 0x10, 0x20
	.byte 0xe8, 0xcf, 0x03, 0x00, 0x00, 0x00, 0x76, 0x90
	.byte 0x00, 0xe8, 0xcf, 0x04, 0x00, 0x00, 0x00, 0x66
	.byte 0x1e, 0xe8, 0xcf, 0x05, 0x00, 0x00, 0x00, 0x66
	.byte 0x05, 0xe8, 0xe0, 0x7e, 0x7d, 0x02, 0xaf, 0x0c
	.byte 0x20, 0xa8, 0x1c, 0x20, 0xa0, 0x20, 0xe8, 0xcf
	.byte 0xff, 0xff, 0xff, 0xff, 0x76, 0x6c, 0x02, 0xaf
	.byte 0x0c, 0x22, 0xaa, 0x1c, 0x21, 0xa1, 0x20, 0xe8
	.byte 0xcf, 0xff, 0xff, 0xff, 0xff, 0x66, 0x10, 0xaa
	.byte 0x20, 0x20, 0xa0, 0x22, 0xa1, 0x20, 0x41, 0x49
	.byte 0x00, 0xe0, 0x01, 0x1d, 0x60, 0x96, 0xfa, 0xaf
	.byte 0x0c, 0x22, 0xaa, 0x20, 0x21, 0xa1, 0x20, 0xe8
	.byte 0xcf, 0xff, 0xff, 0xff, 0xff, 0x66, 0x10, 0xaa
	.byte 0x1c, 0x20, 0xa0, 0x22, 0xa1, 0x20, 0x41, 0x48
	.byte 0x00, 0xe0, 0x01, 0x1d, 0x60, 0x96, 0xfa, 0x1d
	.byte 0x77, 0x9a, 0xfa, 0xaf, 0x18, 0xf3, 0x6e, 0x0c
	.byte 0xaf, 0x0c, 0x20, 0xa8, 0x1c, 0x20, 0xa0, 0x20
	.byte 0x1d, 0x7d, 0x9a, 0xfa, 0xaf, 0x0c, 0x22, 0xaa
	.byte 0x1c, 0x21, 0x40, 0xff, 0xff, 0xff, 0xff, 0xb1
	.byte 0x60, 0xaa, 0x20, 0x21, 0xb1, 0x60, 0x78, 0x02
	.byte 0x02, 0x1d, 0x77, 0x9a, 0xfa, 0xaf, 0x18, 0xf3
	.byte 0x7e, 0xf8, 0x01, 0xaf, 0x0c, 0x20, 0xa8, 0x1c
	.byte 0x20, 0xa0, 0x20, 0x78, 0xe9, 0x01

; WindowProc field set value handler (event 0x1C00048)
WindowField_SetValue:
	ld xwa, (xsp + 24)
	ld xiz, 0x1C
	jr LABEL_F9B20B

; WindowProc field get value handler (event 0x1C0004A)
WindowField_GetValue:
	ld xwa, (xsp + 24)
	ld xiz, 0x1C
	jr LABEL_F9B223

; WindowProc field focus handler (event 0x1C00049)
WindowField_Focus:
	ld xwa, (xsp + 24)
	ld xiz, 0x20

LABEL_F9B20B:
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

LABEL_F9B223:
	call GetViewInstance
	add xhl, xiz
	ld xwa, (xhl)
	ld xhl, (xwa)
	jrl LABEL_F9B3DE

; WindowProc get child count handler (event 0x1E00094)
WindowField_GetChildCount:
	ld xwa, (xsp + 24)
	call GetViewInstance
	ld xwa, (xhl + 28)
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	scc16 nz, hl
	extz xhl
	jrl LABEL_F9B3DE
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
	jr nz, LABEL_F9B296
	ld xwa, (xsp + 12)
	ld xwa, (xwa + 28)
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, LABEL_F9B296
	ld xwa, (xsp + 4)
	call SetCurrentTarget

LABEL_F9B296:
	ld xwa, (xsp + 24)
	ld xbc, (xsp + 20)
	ld xde, (xsp + 16)
	jr LABEL_F9B2AA

WindowProc_ForwardToGroupBoxes:
	ld xwa, (xsp + 24)
	ld xbc, (xsp + 20)
	ld xde, (xsp + 16)

LABEL_F9B2AA:
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
	jrl LABEL_F9B3D8

; WindowProc default handler (returns 0)
WindowProc_DefaultHandler:
	ld xwa, (xsp + 20)
	srl xwa, 0
	and xwa, 0xFFF
	cp wa, 0x1E0
	jr c, LABEL_F9B347
	cp wa, 0x1FF
	jr ugt, LABEL_F9B347
	ld xwa, (xsp + 24)
	ld xbc, (xsp + 20)
	ld xde, (xsp + 16)
	calr GroupBoxProc
	jrl LABEL_F9B3DE

LABEL_F9B347:
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

LABEL_F9B3D8:
	call SetCurrentTarget

AcNaming_ReturnZero:
	lds32 xhl, 0

LABEL_F9B3DE:
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
	jrl z, LABEL_F9C04D
	cp xwa, 0x1E00081
	jrl z, LABEL_F9C028
	cp xwa, 0x1E00080
	jrl z, LABEL_F9BEC6
	ld xhl, (xsp + 42)
	ld de, hl
	cp xwa, 0x1E0007F
	jrl z, LABEL_F9BE71
	cp xwa, 0x1E0007B
	jrl z, LABEL_F9BE66
	cp xwa, 0x1E0003A
	jrl z, LABEL_F9BE53
	cp xwa, 0x1E00086
	jrl z, LABEL_F9BE36
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
	jrl z, LABEL_F9B74B
	cp xwa, 0x1C0000E
	jrl z, LABEL_F9B60F
	cp xwa, 0x1C00002
	jrl z, LABEL_F9B600
	cp xwa, 0x1C0000C
	jrl z, LABEL_F9B5D4
	cp xwa, 0x1C0000B
	jrl z, LABEL_F9B5D4
	cp xwa, 0x1C00001
	jrl nz, LABEL_F9C119
	or xhl, xhl
	jr z, LABEL_F9B4AB
	ld xwa, xhl
	cp xwa, 0x3
	jr z, LABEL_F9B4AB
	cp xwa, 0x5
	jrl nz, LABEL_F9B5A6

LABEL_F9B4AB:
	ld32_24 xwa, 0x0274d2
	or xwa, xwa
	jr nz, LABEL_F9B4BE
	ld xwa, 0x1200005
	st32_24 0x0274d2, xwa

LABEL_F9B4BE:
	sti16_24 0x0274d8, 0x0000
	sti16_24 0x0274da, 0x0000
	ld32_24 xwa, 0x0274d2
	ld xbc, 0x1E0007C
	lds32 xde, 0
	call ApFuncCall
	st16_24 0x0274d6, xhl
	cp hl, 0x20
	jr ule, LABEL_F9B4EE
	sti16_24 0x0274d6, 0x0020

LABEL_F9B4EE:
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
	jr z, LABEL_F9B53B
	ld xwa, 0x17
	lds bc, 0
	call SetVisible
	ld xwa, 0x18
	lds bc, 0
	call SetVisible
	ld xwa, 0x19
	lds bc, 0
	jr LABEL_F9B558

LABEL_F9B53B:
	ld xwa, 0x17
	lds bc, 1
	call SetVisible
	ld xwa, 0x18
	lds bc, 1
	call SetVisible
	ld xwa, 0x19
	lds bc, 1

LABEL_F9B558:
	call SetVisible
	lds iz, 0
	cpdi16_24 160982, 0
	jr ule, LABEL_F9B588

; --- UI Window Procs, Graphics & Mode Screens ---
