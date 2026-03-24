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
	sub xbc, 0x1e0003e
	cp xbc, 0x0
	jr lt, JumpInsert_Error
	cp xbc, 0x9
	jr gt, JumpInsert_Error
	add xbc, xbc
	add xbc, DiskWarning_ConfirmStrings_0xA38_
	ld bc, (xbc)
	lda_24 xix, JumpInsert_DispatchBody
	jp_dri 8, 0x07, 0xf0, 0xe4
JumpInsert_DispatchBody:
	ld	xwa, (xde+14)
	sll	xwa, 2
	ld	xbc, DiskWarning_ConfirmStrings_0x9DE_
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	ld	xwa, (xde+18)
	push	xwa
	call	Strcpy
	inc	8, xsp
	ld	xhl, xiz
	jr	17
	lds32	xhl, 1
	jr	13
	lds32	xhl, 4
	jr	9

JumpInsert_Error:
	lds32 xhl, 0
	jr JumpInsert_Return
	lda_24 xhl, 0x0340f2

JumpInsert_Return:
	pop xiz
	ret

FilePriorityFunc:
	push xiz
	ld xiz, xwa
	cp xbc, 0x1e00065
	jr z, FilePriority_DefaultReturn
	cp xbc, 0x1e00064
	jr z, FilePriority_ReturnOne
	cp xbc, 0x1e00063
	jr z, FilePriority_ReturnPointer
	cp xbc, 0x1e00062
	jr nz, FilePriority_DefaultReturn
	ld wa, (xde + 8)
	and wa, 0x1
	sla wa, 2
	lda_24 xbc, DiskWarning_ConfirmStrings_0xA4C_
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	ld xwa, (xde + 10)
	push xwa
	call Strcpy
	inc 8, xsp
	ld xhl, xiz
	jr FilePriority_Return

FilePriority_ReturnPointer:
	lda_24 xhl, 0x0340f4
	jr FilePriority_Return

FilePriority_ReturnOne:
	lds32 xhl, 1
	jr FilePriority_Return

FilePriority_DefaultReturn:
	lds32 xhl, 0

FilePriority_Return:
	pop xiz
	ret

SetupOkFunc:
	cp xbc, 0x1c00007
	jr nz, SetupOk_Return
	ld xwa, 0x1450030
	ld xbc, 0x1e5000b
	call MainFuncCall

SetupOk_Return:
	lds32 xhl, 0
	ret

SetupExitFunc:
	push xiz
	ld xiz, xde
	cp xbc, 0x1c00002
	jr nz, SetupExit_Return
	ld xde, xiz
	call InheritedProc
	or xiz, xiz
	jr nz, SetupExit_Return
	lds wa, 6
	call PanelDisplay_DispatchByMode
	cps hl, 0
	jr z, SetupExit_Return
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 1
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call PostEvent
	stdi8 0x7f42, 72
	ld xwa, 0xffffffff
	ld xbc, 0x1c00016
	ld xde, 0x1a000ee
	call PostEvent
	ld xwa, 0x1450030
	ld xbc, 0x1e5000c
	ld xde, xiz
	call MainFuncCall

SetupExit_Return:
	lds32 xhl, 0
	pop xiz
	ret

TechnicsFileNaming:
	dec 4, xsp
	push xiz
	ld xiz, xbc
	ld (xsp + 4), xwa
	cp xiz, 0x1c00007
	jr z, TechnicsFileNaming_HandleOk
	cp xiz, 0x1e0007c
	jr z, TechnicsFileNaming_Cancel
	cp xiz, 0x1e00084
	jr z, TechnicsFileNaming_Validate
	cp xiz, 0x1e0003a
	jr nz, TechnicsFileNaming_DefaultReturn
	call GetNamingWindowID
	ld xwa, 0x145000e
	ld xbc, xiz
	ld xde, xhl
	call MainFuncCall
	ld xhl, (xsp + 4)
	jr TechnicsFileNaming_Return

TechnicsFileNaming_Validate:
	lds32 xhl, 1
	jr TechnicsFileNaming_Return

TechnicsFileNaming_Cancel:
	lds32 xhl, 6
	jr TechnicsFileNaming_Return

TechnicsFileNaming_HandleOk:
	call GetNamingWindowID
	ld xwa, xhl
	ld xbc, 0x1e0003a
	ld xde, 0x2742c
	call SendEvent
	ld xwa, 0x145000e
	ld xbc, 0x1e00086
	ld xde, 0x2742c
	call MainFuncCall
	ld xwa, 0xffffffff
	ld xbc, 0x1c00015
	ld xde, 0x1a00067
	call SendEvent

TechnicsFileNaming_DefaultReturn:
	lds32 xhl, 0

TechnicsFileNaming_Return:
	pop xiz
	inc 4, xsp
	ret

TechnicsFileRename:
	dec 4, xsp
	push xiz
	ld xiz, xbc
	ld (xsp + 4), xwa
	cp xiz, 0x1c00007
	jr z, TechnicsFileRename_HandleOk
	cp xiz, 0x1e0007c
	jr z, TechnicsFileRename_Cancel
	cp xiz, 0x1e00084
	jr z, TechnicsFileRename_Validate
	cp xiz, 0x1e0003a
	jr nz, TechnicsFileRename_DefaultReturn
	call GetNamingWindowID
	ld xwa, 0x1450022
	ld xbc, xiz
	ld xde, xhl
	call MainFuncCall
	ld xhl, (xsp + 4)
	jr TechnicsFileRename_Return

TechnicsFileRename_Validate:
	lds32 xhl, 1
	jr TechnicsFileRename_Return

TechnicsFileRename_Cancel:
	lds32 xhl, 6
	jr TechnicsFileRename_Return

TechnicsFileRename_HandleOk:
	call GetNamingWindowID
	ld xwa, xhl
	ld xbc, 0x1e0003a
	ld xde, 0x2743e
	call SendEvent
	ld xwa, 0x1450022
	ld xbc, 0x1e00086
	ld xde, 0x2743e
	call MainFuncCall
	ld xwa, 0x7b0000
	ld xbc, 0x1c00001
	lds32 xde, 0
	call PostEvent

TechnicsFileRename_DefaultReturn:
	lds32 xhl, 0

TechnicsFileRename_Return:
	pop xiz
	inc 4, xsp
	ret

SmfFileNaming:
	dec 4, xsp
	push xiz
	ld xiz, xbc
	ld (xsp + 4), xwa
	cp xiz, 0x1c00007
	jr z, SmfFileNaming_HandleOk
	cp xiz, 0x1e0007c
	jr z, SmfFileNaming_Cancel
	cp xiz, 0x1e00084
	jr z, SmfFileNaming_Validate
	cp xiz, 0x1e0003a
	jr nz, SmfFileNaming_DefaultReturn
	call GetNamingWindowID
	ld xwa, 0x145002f
	ld xbc, xiz
	ld xde, xhl
	call MainFuncCall
	ld xhl, (xsp + 4)
	jr SmfFileNaming_Return

SmfFileNaming_Validate:
	lds32 xhl, 1
	jr SmfFileNaming_Return

SmfFileNaming_Cancel:
	ld xhl, 0x8
	jr SmfFileNaming_Return

SmfFileNaming_HandleOk:
	call GetNamingWindowID
	ld xwa, xhl
	ld xbc, 0x1e0003a
	ld xde, 0x27450
	call SendEvent
	ld xwa, 0x145002f
	ld xbc, 0x1e00086
	ld xde, 0x27450
	call MainFuncCall
	ld xwa, 0xffffffff
	ld xbc, 0x1c00015
	ld xde, 0x1a0006b
	call SendEvent

SmfFileNaming_DefaultReturn:
	lds32 xhl, 0

SmfFileNaming_Return:
	pop xiz
	inc 4, xsp
	ret

SmfFileRename:
	dec 4, xsp
	push xiz
	ld xiz, xbc
	ld (xsp + 4), xwa
	cp xiz, 0x1c00007
	jr z, SmfFileRename_HandleOk
	cp xiz, 0x1e0007c
	jr z, SmfFileRename_Cancel
	cp xiz, 0x1e00084
	jr z, SmfFileRename_Validate
	cp xiz, 0x1e0003a
	jr nz, SmfFileRename_DefaultReturn
	call GetNamingWindowID
	ld xwa, 0x1450023
	ld xbc, xiz
	ld xde, xhl
	call MainFuncCall
	ld xhl, (xsp + 4)
	jr SmfFileRename_Return

SmfFileRename_Validate:
	lds32 xhl, 1
	jr SmfFileRename_Return

SmfFileRename_Cancel:
	ld xhl, 0x8
	jr SmfFileRename_Return

SmfFileRename_HandleOk:
	call GetNamingWindowID
	ld xwa, xhl
	ld xbc, 0x1e0003a
	ld xde, 0x27462
	call SendEvent
	ld xwa, 0x1450023
	ld xbc, 0x1e00086
	ld xde, 0x27462
	call MainFuncCall
	ld xwa, 0x7b0019
	ld xbc, 0x1c00001
	lds32 xde, 0
	call PostEvent

SmfFileRename_DefaultReturn:
	lds32 xhl, 0

SmfFileRename_Return:
	pop xiz
	inc 4, xsp
	ret

FormatDiskNaming:
	dec 4, xsp
	push xiz
	ld xiz, xbc
	ld (xsp + 4), xwa
	cp xiz, 0x1c00007
	jr z, FormatDiskNaming_HandleOk
	cp xiz, 0x1e0007c
	jr z, FormatDiskNaming_Cancel
	cp xiz, 0x1e00084
	jr z, FormatDiskNaming_Validate
	cp xiz, 0x1e0003a
	jr nz, FormatDiskNaming_DefaultReturn
	call GetNamingWindowID
	ld xwa, 0x145000b
	ld xbc, xiz
	ld xde, xhl
	call MainFuncCall
	ld xhl, (xsp + 4)
	jr FormatDiskNaming_Return

FormatDiskNaming_Validate:
	lds32 xhl, 1
	jr FormatDiskNaming_Return

FormatDiskNaming_Cancel:
	ld xhl, 0xb
	jr FormatDiskNaming_Return

FormatDiskNaming_HandleOk:
	call GetNamingWindowID
	ld xwa, xhl
	ld xbc, 0x1e0003a
	ld xde, 0x27474
	call SendEvent
	ld xwa, 0x145000b
	ld xbc, 0x1e00086
	ld xde, 0x27474
	call MainFuncCall

FormatDiskNaming_DefaultReturn:
	lds32 xhl, 0

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
	lds de, 0
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
	st_dri3b D, 0x07, 0xe0, 0xe8
	st_dri3b W, 0x07, 0xec, 0xe8
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
	stib_dri 0x07, 0xe0, 0xe8, 0x00
	lds hl, 0
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
	cp xbc, 0x1c0000b
	jr z, WaitingFunc_DrawMessage
	cp xbc, 0x1c00001
	jr nz, WaitingFunc_Return
	ld xwa, (xsp + 68)
	st16_24 0x02748a, xwa
	sti16_24 0x02748c, 0x0000
	jr WaitingFunc_Return

WaitingFunc_DrawMessage:
	ld8_24 a, 0x0340e4
	extz wa
	sla wa, 2
	lda_24 xbc, DiskWarning_ConfirmStrings_0xA6C_
	ld_sril3 XIZ, 0x07, 0xe4, 0xe0
	push xiz
	call Strlen
	inc 4, xsp
	srl hl, 1
	push_sd24w 0x8c, 0x74, 0x02
	lda xwa, (xsp + 6)
	ld xbc, xiz
	ld de, hl
	calr DrawString_Centered
	st16_24 0x02748c, xhl
	ld xwa, (xsp + 68)
	lda xde, (xsp + 4)
	ld xbc, 0x1c0000f
	call SendEvent

WaitingFunc_Return:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 68)
	ret

DiskMedleyShowHideFunc:
	cp xbc, 0x1c00002
	jr z, DiskMedley_Return
	cp xbc, 0x1c00001
	jr nz, DiskMedley_Return
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 1
	call SendEvent

DiskMedley_Return:
	lds32 xhl, 0
	ret

PsFileNameBoxProc:
	st_dri3b L, 0xfd, 0x56, 0xff
	push xiz
	st_dri3l XDE, 0xfd, 0xa2, 0x00
	st_dri3l XBC, 0xfd, 0xa6, 0x00
	st_dri3l XWA, 0xfd, 0xaa, 0x00
	ld_sril XWA, (xsp + 0x00a6)
	cp xwa, 0x1c50001
	jrl z, PsFileNameBox_HandleOkState
	cp xwa, 0x1c50000
	jrl z, PsFileNameBox_HandleCancelState
	cp xwa, 0x1c00002
	jrl z, PsFileNameBox_HandleClose
	cp xwa, 0x1c0001a
	jrl z, PsFileNameBox_HandleScrollDone
	cp xwa, 0x1c00019
	jrl z, PsFileNameBox_HandleScrollDone
	cp xwa, 0x1c00018
	jrl z, PsFileNameBox_HandleScrollEvt
	cp xwa, 0x1c00017
	jrl z, PsFileNameBox_HandleScrollEvt
	cp xwa, 0x1e50002
	jrl z, PsFileNameBox_HandleListSelect
	cp xwa, 0x1c0000f
	jrl z, PsFileNameBox_HandleConfirm
	cp xwa, 0x1c0000b
	jrl z, PsFileNameBox_HandleShow
	cp xwa, 0x1c00001
	jrl nz, PsFileNameBox_DefaultHandler
	ld_sril XWA, (xsp + 0x00aa)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 50)
	ldw (xwa), 0x1
	ld xwa, (xiz + 54)
	ldw (xwa), 0x1
	ld_sril XDE, (xsp + 0x00aa)
	ld xwa, (xiz + 34)
	ld xbc, 0x1e50004
	call MainFuncCall
	cpw (xiz + 46), 0x0
	jr z, PsFileNameBox_Init_Forward
	cpw (xiz + 40), 0x1
	jr nz, PsFileNameBox_Init_HideFirst
	cpw (xiz + 38), 0x1
	jr nz, PsFileNameBox_Init_HideFirst
	ld_sril XWA, (xsp + 0x00aa)
	ld xbc, 0x1c00017
	lds32 xde, 0
	call SetDialUp
	ld_sril XWA, (xsp + 0x00aa)
	ld xbc, 0x1c00018
	lds32 xde, 0
	jr PsFileNameBox_Init_Configure

PsFileNameBox_Init_HideFirst:
	ld_sril XWA, (xsp + 0x00aa)
	ld xbc, 0x1c00018
	lds32 xde, 0
	call SetDialUp
	ld_sril XWA, (xsp + 0x00aa)
	ld xbc, 0x1c00017
	lds32 xde, 0

PsFileNameBox_Init_Configure:
	call SetDialDown
	lds wa, 1
	call SetDialEnable

PsFileNameBox_Init_Forward:
	ld_sril XWA, (xsp + 0x00aa)
	ld_sril XBC, (xsp + 0x00a6)
	ld_sril XDE, (xsp + 0x00a2)
	jrl PsFileNameBox_DispatchParent

PsFileNameBox_HandleShow:
	ld_sril XWA, (xsp + 0x00aa)
	ld_sril XBC, (xsp + 0x00a6)
	ld_sril XDE, (xsp + 0x00a2)
	call InheritedProc
	ld_sril XWA, (xsp + 0x00aa)
	call GetViewInstance
	ld (xsp + 14), xhl
	ld xwa, (xsp + 14)
	ld xwa, (xwa + 34)
	ld_sril XBC, (xsp + 0x00a6)
	ld_sril XDE, (xsp + 0x00a2)
	call MainFuncCall
	ld xwa, (xsp + 14)
	cpw (xwa + 38), 0x2
	jr lt, PsFileNameBox_CheckScrollButtons
	st_dri3b A, 0xfd, 0x92, 0x00
	ld_sril XWA, (xsp + 0x00aa)
	call GetClientBox
	st_dri3b B, 0xfd, 0x92, 0x00
	ld bc, (xde + 4)
	sub bc, (xde)
	exts xbc
	ld xwa, (xsp + 14)
	mrdw3 0x98, 0x26, 0x59
	ld (xsp + 8), bc
	ld wa, (xde + 2)
	inc 1, wa
	st_dri3w WA, 0xfd, 0xa0, 0x00
	ld wa, (xde + 6)
	dec 1, wa
	st_dri3w WA, 0xfd, 0x9c, 0x00
	ldw (xsp + 12), 0x1
	jr PsFileNameBox_DrawItem_Check

PsFileNameBox_DrawItem_Body:
	ld wa, (xsp + 8)
	mrdw3 0x9f, 0x0c, 0x40
	ld_sriw BC, (xsp + 0x0092)
	add bc, wa
	dec 1, bc
	st_dri3b W, 0xfd, 0x9e, 0x00
	ld (xwa), bc
	st_dri3b A, 0xfd, 0x9a, 0x00
	ld de, (xwa)
	ld (xbc), de
	lds de, 7
	call DrawLine
	incm 1, (xsp + 12)

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
	ld_sril XWA, (xsp + 0x00aa)
	ld xbc, 0x1c00017
	lds32 xde, 0
	call SetDialUp
	ld_sril XWA, (xsp + 0x00aa)
	ld xbc, 0x1c00018
	lds32 xde, 0
	jr PsFileNameBox_Scroll_Apply

PsFileNameBox_Scroll_HideDown:
	ld_sril XWA, (xsp + 0x00aa)
	ld xbc, 0x1c00018
	lds32 xde, 0
	call SetDialUp
	ld_sril XWA, (xsp + 0x00aa)
	ld xbc, 0x1c00017
	lds32 xde, 0

PsFileNameBox_Scroll_Apply:
	call SetDialDown
	lds wa, 1
	call SetDialEnable
	jrl PsFileNameBox_ReturnZero

PsFileNameBox_HandleConfirm:
	ld_sril XWA, (xsp + 0x00aa)
	call GetViewInstance
	ld (xsp + 10), xhl
	ld xwa, (xsp + 10)
	ld (xsp + 4), xwa
	ld xwa, (xwa + 50)
	cpw (xwa), 0x0
	jrl z, PsFileNameBox_ReturnZero
	ld_sril XWA, (xsp + 0x00aa)
	ld_sril XBC, (xsp + 0x00a6)
	ld_sril XDE, (xsp + 0x00a2)
	call InheritedProc
	ld_sril XWA, (xsp + 0x00a2)
	or xwa, xwa
	jrl z, PsFileNameBox_ReturnZero
	ld xwa, (xsp + 10)
	lda xhl, (xwa + 38)
	ld de, (xwa + 40)
	st_dri3b A, 0xfd, 0x92, 0x00
	cps de, 1
	jrl nz, PsFileNameBox_Confirm_MultiItem
	cpw (xhl), 0x1
	jr nz, PsFileNameBox_Confirm_MultiItem
	ld_sril XWA, (xsp + 0x00aa)
	call GetClientBox
	st_dri3b W, 0xfd, 0x92, 0x00
	st_dri3b A, 0xfd, 0x9e, 0x00
	call GetBoxCenter
	ld_sril XWA, (xsp + 0x00a2)
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
	st_dri3b W, 0xfd, 0x92, 0x00
	st_dri3b A, 0xfd, 0x9e, 0x00
	ld xhl, (xhl)
	push xhl
	pushm (xiy)
	pushm (xix)
	pushw 0x0
	pushw 0x1
	jr PsFileNameBox_Confirm_Execute

PsFileNameBox_Confirm_Existing:
	st_dri3b W, 0xfd, 0x92, 0x00
	st_dri3b A, 0xfd, 0x9e, 0x00
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
	muls xwa, xde
	ld de, wa
	ld_sril XWA, (xsp + 0x00a2)
	ld a, (xwa)
	exts wa
	cp wa, de
	jrl ge, PsFileNameBox_ReturnZero
	ld_sril XWA, (xsp + 0x00aa)
	call GetClientBox
	st_dri3b A, 0xfd, 0x92, 0x00
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
	divs xiz, xde
	ld_sril XWA, (xsp + 0x00a2)
	ld a, (xwa)
	exts wa
	exts xwa
	divs xwa, xde
	ldto_werp WA, 0xe2
	ldfr_werp WA, 0xea
	ld_sril XWA, (xsp + 0x00a2)
	ld a, (xwa)
	exts wa
	exts xwa
	divs xwa, xde
	ld de, wa
	ld wa, iz
	mul_werp WA, 0xea
	inc 2, wa
	add hl, wa
	ld (xix), hl
	add hl, iz
	ld (xiy), hl
	ld wa, (xsp + 8)
	mul xwa, xde
	inc 2, wa
	add (xbc), wa
	ld de, (xbc)
	add de, (xsp + 8)
	ld xwa, (xsp + 14)
	ld (xwa), de
	st_dri3b B, 0xfd, 0x9e, 0x00
	ld wa, (xbc)
	ld (xde), wa
	ld wa, (xix)
	ld (xde + 2), wa
	ld_sril XWA, (xsp + 0x00a2)
	inc 1, xwa
	push xwa
	lda xwa, (xsp + 22)
	push xwa
	call Strcpy
	inc 8, xsp
	ld xwa, (xsp + 10)
	ld xix, (xwa + 42)
	ld_sril XWA, (xsp + 0x00a2)
	ld a, (xwa)
	ldfr_berp A, 0xf4
	exts iy
	ld xwa, (xsp + 4)
	lda xhl, (xwa + 28)
	st_dri3b A, 0xfd, 0x9e, 0x00
	lda xde, (xsp + 18)
	cp iy, (xix)
	jr nz, PsFileNameBox_Confirm_NewItem
	st_dri3b W, 0xfd, 0x92, 0x00
	ld xhl, (xhl)
	push xhl
	pushw 0x0
	pushw 0xff
	jr PsFileNameBox_Confirm_Finish

PsFileNameBox_Confirm_NewItem:
	st_dri3b W, 0xfd, 0x92, 0x00
	ld xhl, (xhl)
	push xhl
	ld xhl, (xsp + 14)
	pushm (xhl + 32)
	pushm (xhl + 22)

PsFileNameBox_Confirm_Finish:
	call DrawString
	jrl PsFileNameBox_ReturnZero

PsFileNameBox_HandleListSelect:
	ld_sril XWA, (xsp + 0x00aa)
	call GetViewInstance
	ld xbc, (xhl + 42)
	ld_sril XWA, (xsp + 0x00a2)
	ld (xbc), wa
	jrl PsFileNameBox_ReturnZero

PsFileNameBox_HandleScrollEvt:
	ld_sril XWA, (xsp + 0x00aa)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 34)
	ld_sril XBC, (xsp + 0x00a6)
	ld_sril XDE, (xsp + 0x00a2)
	call MainFuncCall
	ld_sril XWA, (xsp + 0x00aa)
	ld_sril XBC, (xsp + 0x00a6)
	ld_sril XDE, (xsp + 0x00a2)
	call InheritedProc
	cpw (xiz + 48), 0x0
	jrl z, PsFileNameBox_ReturnZero
	ld_sril XWA, (xsp + 0x00a2)
	or xwa, xwa
	jrl nz, PsFileNameBox_ReturnZero
	ld_sril XWA, (xsp + 0x00a6)
	cp xwa, 0x1c00017
	jr nz, PsFileNameBox_ScrollEvt_Down
	ld_sril XWA, (xsp + 0x00aa)
	ld xbc, 0x1c00019
	ld_sril XDE, (xsp + 0x00a2)
	jr PsFileNameBox_ScrollEvt_Send

PsFileNameBox_ScrollEvt_Down:
	ld_sril XWA, (xsp + 0x00aa)
	ld xbc, 0x1c0001a
	ld_sril XDE, (xsp + 0x00a2)

PsFileNameBox_ScrollEvt_Send:
	call SetAutoInc
	jr PsFileNameBox_ReturnZero

PsFileNameBox_HandleScrollDone:
	ld_sril XWA, (xsp + 0x00aa)
	ld_sril XBC, (xsp + 0x00a6)
	ld_sril XDE, (xsp + 0x00a2)
	call InheritedProc
	ld_sril XWA, (xsp + 0x00aa)
	call GetViewInstance
	cpw (xhl + 48), 0x0
	jr z, PsFileNameBox_ReturnZero
	ld_sril XWA, (xsp + 0x00a2)
	or xwa, xwa
	jr nz, PsFileNameBox_ReturnZero
	ld xwa, (xhl + 54)
	cpw (xwa), 0x0
	jr z, PsFileNameBox_ReturnZero
	ld_sril XBC, (xsp + 0x00a6)
	ld xwa, (xhl + 34)
	cp xbc, 0x1c00019
	jr nz, PsFileNameBox_ScrollDone_PairDown
	ld xbc, 0x1c00017
	ld_sril XDE, (xsp + 0x00a2)
	jr PsFileNameBox_ScrollDone_Forward

PsFileNameBox_ScrollDone_PairDown:
	ld xbc, 0x1c00018
	ld_sril XDE, (xsp + 0x00a2)

PsFileNameBox_ScrollDone_Forward:
	call MainFuncCall

PsFileNameBox_ReturnZero:
	lds32 xhl, 0
	jrl PsFileNameBox_Return

PsFileNameBox_HandleClose:
	ld_sril XWA, (xsp + 0x00aa)
	call GetViewInstance
	ld xwa, (xhl + 50)
	ldw (xwa), 0x0
	ld_sril XWA, (xsp + 0x00aa)
	ld_sril XBC, (xsp + 0x00a6)
	ld_sril XDE, (xsp + 0x00a2)
	jr PsFileNameBox_DispatchParent

PsFileNameBox_HandleCancelState:
	ld_sril XWA, (xsp + 0x00aa)
	call GetViewInstance
	ld xbc, (xhl + 50)
	ld_sril XWA, (xsp + 0x00a2)
	or xwa, xwa
	jr z, PsFileNameBox_CancelState_Set
	ldw (xbc), 0x0
	jr PsFileNameBox_CancelState_Forward

PsFileNameBox_CancelState_Set:
	ldw (xbc), 0x1

PsFileNameBox_CancelState_Forward:
	ld_sril XWA, (xsp + 0x00aa)
	ld_sril XBC, (xsp + 0x00a6)
	ld_sril XDE, (xsp + 0x00a2)
	jr PsFileNameBox_DispatchParent

PsFileNameBox_HandleOkState:
	ld_sril XWA, (xsp + 0x00aa)
	call GetViewInstance
	ld xbc, (xhl + 54)
	ld_sril XWA, (xsp + 0x00a2)
	or xwa, xwa
	jr z, PsFileNameBox_OkState_Set
	ldw (xbc), 0x0
	jr PsFileNameBox_OkState_Forward

PsFileNameBox_OkState_Set:
	ldw (xbc), 0x1

PsFileNameBox_OkState_Forward:
	ld_sril XWA, (xsp + 0x00aa)
	ld_sril XBC, (xsp + 0x00a6)
	ld_sril XDE, (xsp + 0x00a2)
	jr PsFileNameBox_DispatchParent

PsFileNameBox_DefaultHandler:
	ld_sril XWA, (xsp + 0x00aa)
	ld_sril XBC, (xsp + 0x00a6)
	ld_sril XDE, (xsp + 0x00a2)

PsFileNameBox_DispatchParent:
	call InheritedProc

PsFileNameBox_Return:
	pop xiz
	st_dri3b L, 0xfd, 0xaa, 0x00
	ret

