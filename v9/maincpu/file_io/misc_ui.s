; =============================================================================
; file_io/misc_ui.asm - Miscellaneous UI and Utilities
; =============================================================================
; Jump insert, file priority, setup, waiting, and filename box UI.
;
; Key routines:
;   JumpInsertFunc                   - Jump insert function
;   FilePriorityFunc                 - File priority handling
;   SetupOkFunc                      - Setup OK handler
;   SetupExitFunc                    - Setup exit handler
;   WaitingFunc                      - Waiting state handler
;   DiskMedleyShowHideFunc           - Disk medley show/hide
;   PsFileNameBoxProc                - Filename input box UI
; =============================================================================

JumpInsertFunc:
	push xiz
	ld xiz, xwa
	sub xbc, EVT_GET_LARGE_STEP
	cp xbc, 0x0
	jr lt, JumpInsert_Error
	cp xbc, 0x9
	jr gt, JumpInsert_Error
	add xbc, xbc
	add xbc, DiskWarning_ConfirmStrings_0xA38
	ld bc, (xbc)
	lda xix, (JumpInsert_DispatchBody:24)
	jp	t, (xix+bc)
JumpInsert_DispatchBody:
	ld	xwa, (xde+14)
	sll	xwa, 2
	ld	xbc, JumpInsert_DispatchBody_PtrTable
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	ld	xwa, (xde+18)
	push	xwa
	call	Strcpy
	inc	8, xsp
	ld	xhl, xiz
	jr	JumpInsert_Return
	ld	xhl, 1:i3
	jr	JumpInsert_Return
	ld	xhl, 4:i3
	jr	JumpInsert_Return

JumpInsert_Error:
	ld xhl, 0:i3
	jr JumpInsert_Return
	lda xhl, (0x0340f2:24)

JumpInsert_Return:
	pop xiz
	ret

FilePriorityFunc:
	push xiz
	ld xiz, xwa
	cp xbc, EVT_GET_DIRECTION
	jr z, FilePriority_DefaultReturn
	cp xbc, EVT_GET_BIT
	jr z, FilePriority_ReturnOne
	cp xbc, EVT_GET_BIT_ADDRESS
	jr z, FilePriority_ReturnPointer
	cp xbc, EVT_GET_BIT_STRING
	jr nz, FilePriority_DefaultReturn
	ld wa, (xde + 8)
	and wa, 0x1
	sla wa, 2
	lda xbc, (FilePriorityFunc_PtrTable:24)
	ld	xwa, (xbc+wa)
	push xwa
	ld xwa, (xde + 10)
	push xwa
	call Strcpy
	inc 8, xsp
	ld xhl, xiz
	jr FilePriority_Return

FilePriority_ReturnPointer:
	lda xhl, (0x0340f4:24)
	jr FilePriority_Return

FilePriority_ReturnOne:
	ld xhl, 1:i3
	jr FilePriority_Return

FilePriority_DefaultReturn:
	ld xhl, 0:i3

FilePriority_Return:
	pop xiz
	ret

SetupOkFunc:
	cp xbc, EVT_SW_IN
	jr nz, SetupOk_Return
	ld xwa, NAKA_MAINFUNC_SetupFlashFunc
	ld xbc, EVT_CHEAP_FLASH_WRITE
	call MainFuncCall

SetupOk_Return:
	ld xhl, 0:i3
	ret

SetupExitFunc:
	push xiz
	ld xiz, xde
	cp xbc, EVT_HIDE
	jr nz, SetupExit_Return
	ld xde, xiz
	call InheritedProc
	or xiz, xiz
	jr nz, SetupExit_Return
	ld wa, 6:i3
	call PanelDisplay_DispatchByMode
	cp hl, 0:i3
	jr z, SetupExit_Return
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 1:i3
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 0:i3
	call PostEvent
	ld (0x7f42:16), 72
	ld xwa, 0xffffffff
	ld xbc, EVT_INTERRUPT_TITLE
	ld xde, TITLE_MESAGE
	call PostEvent
	ld xwa, NAKA_MAINFUNC_SetupFlashFunc
	ld xbc, EVT_CHEAP_FLASH_LOAD
	ld xde, xiz
	call MainFuncCall

SetupExit_Return:
	ld xhl, 0:i3
	pop xiz
	ret

TechnicsFileNaming:
	dec 4, xsp
	push xiz
	ld xiz, xbc
	ld (xsp + 4), xwa
	cp xiz, EVT_SW_IN
	jr z, TechnicsFileNaming_HandleOk
	cp xiz, EVT_GET_STRING_LENGTH
	jr z, TechnicsFileNaming_Cancel
	cp xiz, EVT_GET_NAMING_MODE
	jr z, TechnicsFileNaming_Validate
	cp xiz, EVT_GET_STRING
	jr nz, TechnicsFileNaming_DefaultReturn
	call GetNamingWindowID
	ld xwa, NAKA_MAINFUNC_SaveFileNameFunc
	ld xbc, xiz
	ld xde, xhl
	call MainFuncCall
	ld xhl, (xsp + 4)
	jr TechnicsFileNaming_Return

TechnicsFileNaming_Validate:
	ld xhl, 1:i3
	jr TechnicsFileNaming_Return

TechnicsFileNaming_Cancel:
	ld xhl, 6:i3
	jr TechnicsFileNaming_Return

TechnicsFileNaming_HandleOk:
	call GetNamingWindowID
	ld xwa, xhl
	ld xbc, EVT_GET_STRING
	ld xde, 0x2742c
	call SendEvent
	ld xwa, NAKA_MAINFUNC_SaveFileNameFunc
	ld xbc, EVT_SET_STRING
	ld xde, 0x2742c
	call MainFuncCall
	ld xwa, 0xffffffff
	ld xbc, EVT_CHANGE_TITLE
	ld xde, TITLE_DKSV
	call SendEvent

TechnicsFileNaming_DefaultReturn:
	ld xhl, 0:i3

TechnicsFileNaming_Return:
	pop xiz
	inc 4, xsp
	ret

TechnicsFileRename:
	dec 4, xsp
	push xiz
	ld xiz, xbc
	ld (xsp + 4), xwa
	cp xiz, EVT_SW_IN
	jr z, TechnicsFileRename_HandleOk
	cp xiz, EVT_GET_STRING_LENGTH
	jr z, TechnicsFileRename_Cancel
	cp xiz, EVT_GET_NAMING_MODE
	jr z, TechnicsFileRename_Validate
	cp xiz, EVT_GET_STRING
	jr nz, TechnicsFileRename_DefaultReturn
	call GetNamingWindowID
	ld xwa, NAKA_MAINFUNC_FileRenameFunc
	ld xbc, xiz
	ld xde, xhl
	call MainFuncCall
	ld xhl, (xsp + 4)
	jr TechnicsFileRename_Return

TechnicsFileRename_Validate:
	ld xhl, 1:i3
	jr TechnicsFileRename_Return

TechnicsFileRename_Cancel:
	ld xhl, 6:i3
	jr TechnicsFileRename_Return

TechnicsFileRename_HandleOk:
	call GetNamingWindowID
	ld xwa, xhl
	ld xbc, EVT_GET_STRING
	ld xde, 0x2743e
	call SendEvent
	ld xwa, NAKA_MAINFUNC_FileRenameFunc
	ld xbc, EVT_SET_STRING
	ld xde, 0x2743e
	call MainFuncCall
	ld xwa, 0x7b0000
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	call PostEvent

TechnicsFileRename_DefaultReturn:
	ld xhl, 0:i3

TechnicsFileRename_Return:
	pop xiz
	inc 4, xsp
	ret

SmfFileNaming:
	dec 4, xsp
	push xiz
	ld xiz, xbc
	ld (xsp + 4), xwa
	cp xiz, EVT_SW_IN
	jr z, SmfFileNaming_HandleOk
	cp xiz, EVT_GET_STRING_LENGTH
	jr z, SmfFileNaming_Cancel
	cp xiz, EVT_GET_NAMING_MODE
	jr z, SmfFileNaming_Validate
	cp xiz, EVT_GET_STRING
	jr nz, SmfFileNaming_DefaultReturn
	call GetNamingWindowID
	ld xwa, NAKA_MAINFUNC_SaveFileNameSmfFunc
	ld xbc, xiz
	ld xde, xhl
	call MainFuncCall
	ld xhl, (xsp + 4)
	jr SmfFileNaming_Return

SmfFileNaming_Validate:
	ld xhl, 1:i3
	jr SmfFileNaming_Return

SmfFileNaming_Cancel:
	ld xhl, 0x8
	jr SmfFileNaming_Return

SmfFileNaming_HandleOk:
	call GetNamingWindowID
	ld xwa, xhl
	ld xbc, EVT_GET_STRING
	ld xde, 0x27450
	call SendEvent
	ld xwa, NAKA_MAINFUNC_SaveFileNameSmfFunc
	ld xbc, EVT_SET_STRING
	ld xde, 0x27450
	call MainFuncCall
	ld xwa, 0xffffffff
	ld xbc, EVT_CHANGE_TITLE
	ld xde, TITLE_DKSVSMF
	call SendEvent

SmfFileNaming_DefaultReturn:
	ld xhl, 0:i3

SmfFileNaming_Return:
	pop xiz
	inc 4, xsp
	ret

SmfFileRename:
	dec 4, xsp
	push xiz
	ld xiz, xbc
	ld (xsp + 4), xwa
	cp xiz, EVT_SW_IN
	jr z, SmfFileRename_HandleOk
	cp xiz, EVT_GET_STRING_LENGTH
	jr z, SmfFileRename_Cancel
	cp xiz, EVT_GET_NAMING_MODE
	jr z, SmfFileRename_Validate
	cp xiz, EVT_GET_STRING
	jr nz, SmfFileRename_DefaultReturn
	call GetNamingWindowID
	ld xwa, NAKA_MAINFUNC_FileRenameSmfFunc
	ld xbc, xiz
	ld xde, xhl
	call MainFuncCall
	ld xhl, (xsp + 4)
	jr SmfFileRename_Return

SmfFileRename_Validate:
	ld xhl, 1:i3
	jr SmfFileRename_Return

SmfFileRename_Cancel:
	ld xhl, 0x8
	jr SmfFileRename_Return

SmfFileRename_HandleOk:
	call GetNamingWindowID
	ld xwa, xhl
	ld xbc, EVT_GET_STRING
	ld xde, 0x27462
	call SendEvent
	ld xwa, NAKA_MAINFUNC_FileRenameSmfFunc
	ld xbc, EVT_SET_STRING
	ld xde, 0x27462
	call MainFuncCall
	ld xwa, 0x7b0019
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	call PostEvent

SmfFileRename_DefaultReturn:
	ld xhl, 0:i3

SmfFileRename_Return:
	pop xiz
	inc 4, xsp
	ret

FormatDiskNaming:
	dec 4, xsp
	push xiz
	ld xiz, xbc
	ld (xsp + 4), xwa
	cp xiz, EVT_SW_IN
	jr z, FormatDiskNaming_HandleOk
	cp xiz, EVT_GET_STRING_LENGTH
	jr z, FormatDiskNaming_Cancel
	cp xiz, EVT_GET_NAMING_MODE
	jr z, FormatDiskNaming_Validate
	cp xiz, EVT_GET_STRING
	jr nz, FormatDiskNaming_DefaultReturn
	call GetNamingWindowID
	ld xwa, NAKA_MAINFUNC_DiskNameFunc
	ld xbc, xiz
	ld xde, xhl
	call MainFuncCall
	ld xhl, (xsp + 4)
	jr FormatDiskNaming_Return

FormatDiskNaming_Validate:
	ld xhl, 1:i3
	jr FormatDiskNaming_Return

FormatDiskNaming_Cancel:
	ld xhl, 0xb
	jr FormatDiskNaming_Return

FormatDiskNaming_HandleOk:
	call GetNamingWindowID
	ld xwa, xhl
	ld xbc, EVT_GET_STRING
	ld xde, 0x27474
	call SendEvent
	ld xwa, NAKA_MAINFUNC_DiskNameFunc
	ld xbc, EVT_SET_STRING
	ld xde, 0x27474
	call MainFuncCall

FormatDiskNaming_DefaultReturn:
	ld xhl, 0:i3

FormatDiskNaming_Return:
	pop xiz
	inc 4, xsp
	ret

DrawString_Centered:
	lda xsp, (xsp - 12)
	pushw iz
	ld (xsp + 4), de
	ld (xsp + 6), xbc
	ld (xsp + 10), xwa
	ld xwa, (xsp + 6)
	push xwa
	call Strlen
	inc 4, xsp
	ld (xsp + 2), hl
	ld de, 0:i3
	ld bc, (xsp + 18)
	cpw (xsp + 4), 0x0
	jr ule, DrawStr_Epilogue

DrawStr_LoopBody:
	ld iy, (xsp + 2)
	ld iz, de
	add iz, bc
	ld hl, bc
	extz xhl
	ld xwa, (xsp + 10)
	lda	xix, (xwa+de)
	lda	xwa, (xhl+de)
	add xwa, (xsp + 6)
	cp iz, iy
	jr nc, DrawStr_WrapAround
	ld a, (xwa)
	ld (xix), a
	jr DrawStr_LoopCheck

DrawStr_WrapAround:
	ld hl, (xsp + 2)
	exts xhl
	sub xwa, xhl
	ld a, (xwa)
	ld (xix), a

DrawStr_LoopCheck:
	inc 1, de
	ld wa, de
	cp wa, (xsp + 4)
	jr c, DrawStr_LoopBody

DrawStr_Epilogue:
	ld xwa, (xsp + 10)
	ld	(xwa+de), 0x00
	ld hl, 0:i3
	ld de, (xsp + 2)
	inc 1, bc
	cp bc, de
	jr nc, DrawStr_Return
	ld hl, bc

DrawStr_Return:
	popw iz
	lda xsp, (xsp + 12)
	retd 0x2

WaitingFunc:
	lda xsp, (xsp - 68)
	push xiz
	ld (xsp + 68), xde
	cp xbc, EVT_PAINT
	jr z, WaitingFunc_DrawMessage
	cp xbc, EVT_SHOW
	jr nz, WaitingFunc_Return
	ld xwa, (xsp + 68)
	ld (0x02748a:24), wa
	ldw (0x02748c:24), 0x0000
	jr WaitingFunc_Return

WaitingFunc_DrawMessage:
	ld a, (0x0340e4:24)
	extz wa
	sla wa, 2
	lda xbc, (WaitingFunc_DrawMessage_PtrTable:24)
	ld	xiz, (xbc+wa)
	push xiz
	call Strlen
	inc 4, xsp
	srl hl, 1
	pushw_da 0x8c, 0x74, 0x02
	lda xwa, (xsp + 6)
	ld xbc, xiz
	ld de, hl
	calr DrawString_Centered
	ld (0x02748c:24), hl
	ld xwa, (xsp + 68)
	lda xde, (xsp + 4)
	ld xbc, EVT_PARA_DRAW
	call SendEvent

WaitingFunc_Return:
	ld xhl, 0:i3
	pop xiz
	lda xsp, (xsp + 68)
	ret

DiskMedleyShowHideFunc:
	cp xbc, EVT_HIDE
	jr z, DiskMedley_Return
	cp xbc, EVT_SHOW
	jr nz, DiskMedley_Return
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 1:i3
	call SendEvent

DiskMedley_Return:
	ld xhl, 0:i3
	ret

PsFileNameBoxProc:
	lda xsp, (xsp-170)
	push xiz
	ld	(xsp+162), xde
	ld	(xsp+166), xbc
	ld	(xsp+170), xwa
	ld	xwa, (xsp+166)
	cp xwa, EVT_NOT_POST_AIC
	jrl z, PsFileNameBox_HandleOkState
	cp xwa, EVT_NOT_PARA_DRAW
	jrl z, PsFileNameBox_HandleCancelState
	cp xwa, EVT_HIDE
	jrl z, PsFileNameBox_HandleClose
	cp xwa, EVT_INDEXSW_DOWN_AIC
	jrl z, PsFileNameBox_HandleScrollDone
	cp xwa, EVT_INDEXSW_UP_AIC
	jrl z, PsFileNameBox_HandleScrollDone
	cp xwa, EVT_INDEXSW_DOWN
	jrl z, PsFileNameBox_HandleScrollEvt
	cp xwa, EVT_INDEXSW_UP
	jrl z, PsFileNameBox_HandleScrollEvt
	cp xwa, EVT_SET_SELECTED_FILE_NUMBER
	jrl z, PsFileNameBox_HandleListSelect
	cp xwa, EVT_PARA_DRAW
	jrl z, PsFileNameBox_HandleConfirm
	cp xwa, EVT_PAINT
	jrl z, PsFileNameBox_HandleShow
	cp xwa, EVT_SHOW
	jrl nz, PsFileNameBox_DefaultHandler
	ld	xwa, (xsp+170)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 50)
	ldw (xwa), 0x1
	ld xwa, (xiz + 54)
	ldw (xwa), 0x1
	ld	xde, (xsp+170)
	ld xwa, (xiz + 34)
	ld xbc, EVT_PS_FILE_NAME_BOX_ID
	call MainFuncCall
	cpw (xiz + 46), 0x0
	jr z, PsFileNameBox_Init_Forward
	cpw (xiz + 40), 0x1
	jr nz, PsFileNameBox_Init_HideFirst
	cpw (xiz + 38), 0x1
	jr nz, PsFileNameBox_Init_HideFirst
	ld	xwa, (xsp+170)
	ld xbc, EVT_INDEXSW_UP
	ld xde, 0:i3
	call SetDialUp
	ld	xwa, (xsp+170)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, 0:i3
	jr PsFileNameBox_Init_Configure

PsFileNameBox_Init_HideFirst:
	ld	xwa, (xsp+170)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, 0:i3
	call SetDialUp
	ld	xwa, (xsp+170)
	ld xbc, EVT_INDEXSW_UP
	ld xde, 0:i3

PsFileNameBox_Init_Configure:
	call SetDialDown
	ld wa, 1:i3
	call SetDialEnable

PsFileNameBox_Init_Forward:
	ld	xwa, (xsp+170)
	ld	xbc, (xsp+166)
	ld	xde, (xsp+162)
	jrl PsFileNameBox_DispatchParent

PsFileNameBox_HandleShow:
	ld	xwa, (xsp+170)
	ld	xbc, (xsp+166)
	ld	xde, (xsp+162)
	call InheritedProc
	ld	xwa, (xsp+170)
	call GetViewInstance
	ld (xsp + 14), xhl
	ld xwa, (xsp + 14)
	ld xwa, (xwa + 34)
	ld	xbc, (xsp+166)
	ld	xde, (xsp+162)
	call MainFuncCall
	ld xwa, (xsp + 14)
	cpw (xwa + 38), 0x2
	jr lt, PsFileNameBox_CheckScrollButtons
	lda xbc, (xsp+146:16)
	ld	xwa, (xsp+170)
	call GetClientBox
	lda xde, (xsp+146:16)
	ld bc, (xde + 4)
	sub bc, (xde)
	exts xbc
	ld xwa, (xsp + 14)
	mrdw3 0x98, 0x26, 0x59
	ld (xsp + 8), bc
	ld wa, (xde + 2)
	inc 1, wa
	ld	(xsp+160), wa
	ld wa, (xde + 6)
	dec 1, wa
	ld	(xsp+156), wa
	ldw (xsp + 12), 0x1
	jr PsFileNameBox_DrawItem_Check

PsFileNameBox_DrawItem_Body:
	ld wa, (xsp + 8)
	mrdw3 0x9f, 0x0c, 0x40
	ld	bc, (xsp+146)
	add bc, wa
	dec 1, bc
	lda xwa, (xsp+158:16)
	ld (xwa), bc
	lda xbc, (xsp+154:16)
	ld de, (xwa)
	ld (xbc), de
	ld de, 7:i3
	call DrawLine
	incw 1, (xsp + 12)

PsFileNameBox_DrawItem_Check:
	ld xwa, (xsp + 14)
	ld wa, (xwa + 38)
	cp (xsp + 12), wa
	jr c, PsFileNameBox_DrawItem_Body

PsFileNameBox_CheckScrollButtons:
	ld xwa, (xsp + 14)
	cpw (xwa + 46), 0x0
	jrl z, PsFileNameBox_ReturnZero
	cpw (xwa + 40), 0x1
	jr nz, PsFileNameBox_Scroll_HideDown
	cpw (xwa + 38), 0x1
	jr nz, PsFileNameBox_Scroll_HideDown
	ld	xwa, (xsp+170)
	ld xbc, EVT_INDEXSW_UP
	ld xde, 0:i3
	call SetDialUp
	ld	xwa, (xsp+170)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, 0:i3
	jr PsFileNameBox_Scroll_Apply

PsFileNameBox_Scroll_HideDown:
	ld	xwa, (xsp+170)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, 0:i3
	call SetDialUp
	ld	xwa, (xsp+170)
	ld xbc, EVT_INDEXSW_UP
	ld xde, 0:i3

PsFileNameBox_Scroll_Apply:
	call SetDialDown
	ld wa, 1:i3
	call SetDialEnable
	jrl PsFileNameBox_ReturnZero

PsFileNameBox_HandleConfirm:
	ld	xwa, (xsp+170)
	call GetViewInstance
	ld (xsp + 10), xhl
	ld xwa, (xsp + 10)
	ld (xsp + 4), xwa
	ld xwa, (xwa + 50)
	cpw (xwa), 0x0
	jrl z, PsFileNameBox_ReturnZero
	ld	xwa, (xsp+170)
	ld	xbc, (xsp+166)
	ld	xde, (xsp+162)
	call InheritedProc
	ld	xwa, (xsp+162)
	or xwa, xwa
	jrl z, PsFileNameBox_ReturnZero
	ld xwa, (xsp + 10)
	lda xhl, (xwa + 38)
	ld de, (xwa + 40)
	lda xbc, (xsp+146:16)
	cp de, 1:i3
	jrl nz, PsFileNameBox_Confirm_MultiItem
	cpw (xhl), 0x1
	jr nz, PsFileNameBox_Confirm_MultiItem
	ld	xwa, (xsp+170)
	call GetClientBox
	lda xwa, (xsp+146:16)
	lda xbc, (xsp+158:16)
	call GetBoxCenter
	ld	xwa, (xsp+162)
	inc 1, xwa
	push xwa
	lda xwa, (xsp + 22)
	push xwa
	call Strcpy
	inc 8, xsp
	ld xhl, (xsp + 10)
	ld xbc, (xhl + 42)
	lda xde, (xsp + 18)
	lda xix, (xhl + 22)
	ld xwa, (xsp + 4)
	lda xiy, (xwa + 32)
	lda xhl, (xhl + 28)
	cpw (xbc), 0x0
	jr nz, PsFileNameBox_Confirm_Existing
	lda xwa, (xsp+146:16)
	lda xbc, (xsp+158:16)
	ld xhl, (xhl)
	push xhl
	pushm (xiy)
	pushm (xix)
	pushw 0x0
	pushw 0x1
	jr PsFileNameBox_Confirm_Execute

PsFileNameBox_Confirm_Existing:
	lda xwa, (xsp+146:16)
	lda xbc, (xsp+158:16)
	ld xhl, (xhl)
	push xhl
	pushm (xiy)
	pushm (xix)
	pushw 0x0
	pushw 0x0

PsFileNameBox_Confirm_Execute:
	call DrawStringReverse
	jrl PsFileNameBox_ReturnZero

PsFileNameBox_Confirm_MultiItem:
	ld wa, (xhl)
	muls xwa, de
	ld de, wa
	ld	xwa, (xsp+162)
	ld a, (xwa)
	exts wa
	cp wa, de
	jrl ge, PsFileNameBox_ReturnZero
	ld	xwa, (xsp+170)
	call GetClientBox
	lda xbc, (xsp+146:16)
	lda xwa, (xbc + 4)
	ld (xsp + 14), xwa
	ld de, (xwa)
	sub de, (xbc)
	exts xde
	ld xwa, (xsp + 10)
	mrdw3 0x98, 0x26, 0x5a
	ld (xsp + 8), de
	lda xiy, (xbc + 6)
	lda xix, (xbc + 2)
	ld hl, (xix)
	ld iz, (xiy)
	sub iz, hl
	ld xwa, (xsp + 4)
	ld de, (xwa + 40)
	exts xiz
	divs xiz, de
	ld	xwa, (xsp+162)
	ld a, (xwa)
	exts wa
	exts xwa
	divs xwa, de
	ldto_werp WA, 0xe2
	ldfr_werp WA, 0xea
	ld	xwa, (xsp+162)
	ld a, (xwa)
	exts wa
	exts xwa
	divs xwa, de
	ld de, wa
	ld wa, iz
	mul xwa, qde
	inc 2, wa
	add hl, wa
	ld (xix), hl
	add hl, iz
	ld (xiy), hl
	ld wa, (xsp + 8)
	mul xwa, de
	inc 2, wa
	add (xbc), wa
	ld de, (xbc)
	add de, (xsp + 8)
	ld xwa, (xsp + 14)
	ld (xwa), de
	lda xde, (xsp+158:16)
	ld wa, (xbc)
	ld (xde), wa
	ld wa, (xix)
	ld (xde + 2), wa
	ld	xwa, (xsp+162)
	inc 1, xwa
	push xwa
	lda xwa, (xsp + 22)
	push xwa
	call Strcpy
	inc 8, xsp
	ld xwa, (xsp + 10)
	ld xix, (xwa + 42)
	ld	xwa, (xsp+162)
	ld a, (xwa)
	ldfr_berp A, 0xf4
	exts iy
	ld xwa, (xsp + 4)
	lda xhl, (xwa + 28)
	lda xbc, (xsp+158:16)
	lda xde, (xsp + 18)
	cp iy, (xix)
	jr nz, PsFileNameBox_Confirm_NewItem
	lda xwa, (xsp+146:16)
	ld xhl, (xhl)
	push xhl
	pushw 0x0
	pushw 0xff
	jr PsFileNameBox_Confirm_Finish

PsFileNameBox_Confirm_NewItem:
	lda xwa, (xsp+146:16)
	ld xhl, (xhl)
	push xhl
	ld xhl, (xsp + 14)
	pushm (xhl + 32)
	pushm (xhl + 22)

PsFileNameBox_Confirm_Finish:
	call DrawString
	jrl PsFileNameBox_ReturnZero

PsFileNameBox_HandleListSelect:
	ld	xwa, (xsp+170)
	call GetViewInstance
	ld xbc, (xhl + 42)
	ld	xwa, (xsp+162)
	ld (xbc), wa
	jrl PsFileNameBox_ReturnZero

PsFileNameBox_HandleScrollEvt:
	ld	xwa, (xsp+170)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 34)
	ld	xbc, (xsp+166)
	ld	xde, (xsp+162)
	call MainFuncCall
	ld	xwa, (xsp+170)
	ld	xbc, (xsp+166)
	ld	xde, (xsp+162)
	call InheritedProc
	cpw (xiz + 48), 0x0
	jrl z, PsFileNameBox_ReturnZero
	ld	xwa, (xsp+162)
	or xwa, xwa
	jrl nz, PsFileNameBox_ReturnZero
	ld	xwa, (xsp+166)
	cp xwa, EVT_INDEXSW_UP
	jr nz, PsFileNameBox_ScrollEvt_Down
	ld	xwa, (xsp+170)
	ld xbc, EVT_INDEXSW_UP_AIC
	ld	xde, (xsp+162)
	jr PsFileNameBox_ScrollEvt_Send

PsFileNameBox_ScrollEvt_Down:
	ld	xwa, (xsp+170)
	ld xbc, EVT_INDEXSW_DOWN_AIC
	ld	xde, (xsp+162)

PsFileNameBox_ScrollEvt_Send:
	call SetAutoInc
	jr PsFileNameBox_ReturnZero

PsFileNameBox_HandleScrollDone:
	ld	xwa, (xsp+170)
	ld	xbc, (xsp+166)
	ld	xde, (xsp+162)
	call InheritedProc
	ld	xwa, (xsp+170)
	call GetViewInstance
	cpw (xhl + 48), 0x0
	jr z, PsFileNameBox_ReturnZero
	ld	xwa, (xsp+162)
	or xwa, xwa
	jr nz, PsFileNameBox_ReturnZero
	ld xwa, (xhl + 54)
	cpw (xwa), 0x0
	jr z, PsFileNameBox_ReturnZero
	ld	xbc, (xsp+166)
	ld xwa, (xhl + 34)
	cp xbc, EVT_INDEXSW_UP_AIC
	jr nz, PsFileNameBox_ScrollDone_PairDown
	ld xbc, EVT_INDEXSW_UP
	ld	xde, (xsp+162)
	jr PsFileNameBox_ScrollDone_Forward

PsFileNameBox_ScrollDone_PairDown:
	ld xbc, EVT_INDEXSW_DOWN
	ld	xde, (xsp+162)

PsFileNameBox_ScrollDone_Forward:
	call MainFuncCall

PsFileNameBox_ReturnZero:
	ld xhl, 0:i3
	jrl PsFileNameBox_Return

PsFileNameBox_HandleClose:
	ld	xwa, (xsp+170)
	call GetViewInstance
	ld xwa, (xhl + 50)
	ldw (xwa), 0x0
	ld	xwa, (xsp+170)
	ld	xbc, (xsp+166)
	ld	xde, (xsp+162)
	jr PsFileNameBox_DispatchParent

PsFileNameBox_HandleCancelState:
	ld	xwa, (xsp+170)
	call GetViewInstance
	ld xbc, (xhl + 50)
	ld	xwa, (xsp+162)
	or xwa, xwa
	jr z, PsFileNameBox_CancelState_Set
	ldw (xbc), 0x0
	jr PsFileNameBox_CancelState_Forward

PsFileNameBox_CancelState_Set:
	ldw (xbc), 0x1

PsFileNameBox_CancelState_Forward:
	ld	xwa, (xsp+170)
	ld	xbc, (xsp+166)
	ld	xde, (xsp+162)
	jr PsFileNameBox_DispatchParent

PsFileNameBox_HandleOkState:
	ld	xwa, (xsp+170)
	call GetViewInstance
	ld xbc, (xhl + 54)
	ld	xwa, (xsp+162)
	or xwa, xwa
	jr z, PsFileNameBox_OkState_Set
	ldw (xbc), 0x0
	jr PsFileNameBox_OkState_Forward

PsFileNameBox_OkState_Set:
	ldw (xbc), 0x1

PsFileNameBox_OkState_Forward:
	ld	xwa, (xsp+170)
	ld	xbc, (xsp+166)
	ld	xde, (xsp+162)
	jr PsFileNameBox_DispatchParent

PsFileNameBox_DefaultHandler:
	ld	xwa, (xsp+170)
	ld	xbc, (xsp+166)
	ld	xde, (xsp+162)

PsFileNameBox_DispatchParent:
	call InheritedProc

PsFileNameBox_Return:
	pop xiz
	lda xsp, (xsp+170:16)
	ret

