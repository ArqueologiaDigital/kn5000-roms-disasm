; =============================================================================
; file_io/composer_filters.asm - Composer Load and Filter Operations
; =============================================================================
; Composer file loading and load/save filter routines.
;
; Key routines:
;   FmmComposerLoadFunc              - Composer file loading
;   FmmLoadFilterFunc                - Load filter settings
;   FmmSaveFilterFunc                - Save filter settings
; =============================================================================

FmmComposerLoadFunc:
	dec 2, xsp
	pushw iz
	cp xbc, 0x1C00018
	jrl z, CompLoad_HandleScroll
	cp xbc, 0x1C00017
	jrl z, CompLoad_HandleScroll
	cp xbc, 0x1C0000B
	jrl z, CompLoad_HandleShow
	cp xbc, 0x1E50004
	jrl z, CompLoad_HandleSelection
	cp xbc, 0x1C00013
	jrl nz, CompLoad_Return
	cp xde, 0x3
	jrl z, CompLoad_HandleAbort
	cp xde, 0x2
	jrl nz, CompLoad_Return
	stdi8 34046, 0
	lds wa, 1
	calr InitializeOperationState
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	cpdi16 34048, 0
	jr ge, CompLoad_DispatchState
	call 0xF89520
	extz hl
	stda16 34048, xhl
	calr SignalProgressUpdate

CompLoad_DispatchState:
	ldda16 xwa, 34048
	cps wa, 1
	jrl z, CompLoad_HandleSuccess
	cps wa, 0
	jr z, CompLoad_HandleError
	cps wa, 5
	jr z, CompLoad_HandleCancel
	cpdi16 34050, 0
	jr ge, CompLoad_ContinueWait
	call 0xF8987D
	stda16 34050, xhl
	call LABEL_F8958D
	call 0xF8953B
	calr SignalProgressUpdate

CompLoad_ContinueWait:
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0000A
	lds32 xde, 0
	jrl CompLoad_DispatchWidget

CompLoad_HandleCancel:
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call 0xFA9D58
	lds wa, 1
	call LABEL_F99463
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call 0xFA9D58
	stdi8 32578, 0
	ldw wa, 0xEE
	jr CompLoad_CallStatusDisplay

CompLoad_HandleError:
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0x7D
	call 0xF99490
	jrl CompLoad_Return

CompLoad_HandleSuccess:
	calr ResetProgressIndication
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call 0xFA9D58
	lds wa, 1
	call LABEL_F99463
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call 0xFA9D58
	stdi8 32578, 2
	ldw wa, 0xEE

CompLoad_CallStatusDisplay:
	call LABEL_F994BD
	jrl CompLoad_Return

CompLoad_HandleAbort:
	calr CancelOperationCleanup
	jrl CompLoad_Return

CompLoad_HandleSelection:
	stda32 32636, xde
	call 0xF895EF
	stda16 32640, xhl
	cps hl, 0
	jr lt, CompLoad_Selection_Negative
	exts xhl
	ldda32 xwa, 32636
	ld xbc, 0x1E50002
	ld xde, xhl
	jrl CompLoad_DispatchWidget

CompLoad_Selection_Negative:
	stdi16 32640, 0
	ldda32 xwa, 32636
	ld xbc, 0x1E50002
	lds32 xde, 0
	jrl CompLoad_DispatchWidget

CompLoad_HandleShow:
	lds iz, 0

CompLoad_DrawItemLoop:
	ld wa, iz
	ld hl, wa
	sll hl, 5
	ldada xde, 34060
	extz xhl
	add xhl, xde
	ldto_berp C, 0xF8
	ld (xhl), c
	lds bc, 3
	call LABEL_F89408
	cps l, 0
	jr z, CompLoad_DrawItem_Empty
	ld wa, iz
	call LABEL_F89623
	ld xbc, xhl
	jr CompLoad_DrawItem_Continue

CompLoad_DrawItem_Empty:
	lda_24 xbc, 0xea06ec

CompLoad_DrawItem_Continue:
	ld de, iz
	ld wa, de
	sll wa, 5
	lds hl, 1
	add hl, wa
	ldada xix, 34060
	extz xhl
	add xhl, xix
	inc 1, de
	pushw 0x6
	pushw 0x0
	ld xwa, xhl
	call LABEL_F891DD
	ld de, iz
	sll de, 5
	ldada xbc, 34060
	extz xde
	add xde, xbc
	ldda32 xwa, 32636
	ld xbc, 0x1C0000F
	call 0xFA9D58
	inc 1, iz
	cp iz, 0x14
	jr lt, CompLoad_DrawItemLoop
	jrl CompLoad_Return

CompLoad_HandleScroll:
	ldda16 xwa, 32640
	ld (xsp + 2), wa
	or xde, xde
	jr nz, CompLoad_PageScroll
	cp xbc, 0x1C00018
	jr nz, CompLoad_ScrollUp
	cp wa, 0x13
	jrl ge, CompLoad_GetSelection
	inc 1, wa
	jr CompLoad_StorePosition

CompLoad_ScrollUp:
	cp xbc, 0x1C00017
	jrl nz, CompLoad_GetSelection
	cps wa, 0
	jrl le, CompLoad_GetSelection
	dec 1, wa
	jr CompLoad_StorePosition

CompLoad_PageScroll:
	cp xde, 0x1
	jr nz, CompLoad_PageDown
	cp wa, 0xA
	jrl lt, CompLoad_GetSelection
	sub wa, 0xA
	jr CompLoad_StorePosition

CompLoad_PageDown:
	cp xde, 0x2
	jr nz, CompLoad_OpLoad
	ld bc, wa
	add bc, 0xA
	cp bc, 0x13
	jrl gt, CompLoad_GetSelection
	add wa, 0xA

CompLoad_StorePosition:
	stda16 32640, xwa
	jrl CompLoad_UpdateDisplay

CompLoad_OpLoad:
	cp xde, 0x3
	jrl nz, CompLoad_GetSelection
	call 0xF8943E
	cps hl, 0
	jr z, CompLoad_GetSelection
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	lds iz, 0

CompLoad_HideButtons_Loop:
	ldto_berp A, 0xF8
	extz wa
	call LABEL_F89335
	inc 1, iz
	cp iz, 0x8
	jr lt, CompLoad_HideButtons_Loop
	lds wa, 3
	call LABEL_F89321
	lds wa, 0
	calr InitializeOperationState
	call LABEL_F87A08
	ld wa, hl
	lds bc, 1
	calr LABEL_F8B48E
	stda8 32578, l
	calr SignalProgressUpdate
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call 0xFA9D58
	lds wa, 1
	call LABEL_F99463
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0xEE
	call LABEL_F994BD

CompLoad_GetSelection:
	ldda16 xwa, 32640

CompLoad_UpdateDisplay:
	cp (xsp + 2), wa
	jr z, CompLoad_Return
	call 0xF89605
	ldda16 xde, 32640
	exts xde
	ldda32 xwa, 32636
	ld xbc, 0x1E50002
	call 0xFA9D58
	ld de, (xsp + 2)
	sll de, 5
	ldada xbc, 34060
	extz xde
	add xde, xbc
	ldda32 xwa, 32636
	ld xbc, 0x1C0000F
	call 0xFA9D58
	ldda16 xde, 32640
	sll de, 5
	ldada xbc, 34060
	extz xde
	add xde, xbc
	ldda32 xwa, 32636
	ld xbc, 0x1C0000F

CompLoad_DispatchWidget:
	call 0xFA9D58

CompLoad_Return:
	lds32 xhl, 0
	popw iz
	inc 2, xsp
	ret

RenderFilterDisplay:
	dec 6, xsp
	ld (xsp), c
	ld (xsp + 2), xwa
	ld xwa, (xsp + 2)
	ld c, (xsp)
	lda_dpi XHL, 0xE0
	ld (xsp + 2), xwa
	cp (xsp), 0x0
	jr nz, RenderFilter_CheckType1
	call LABEL_F8964C
	cps l, 0
	jr z, RenderFilter_CheckType1
	ld xwa, (xsp + 2)
	ld xbc, 0xEA06EE
	jrl RenderFilter_CopyAndReturn

RenderFilter_CheckType1:
	cp (xsp), 0x1
	jr nz, RenderFilter_CheckGeneric
	call LABEL_F8964C
	cps l, 0
	jr z, RenderFilter_CheckGeneric
	lds wa, 0
	call LABEL_F893D1
	cps l, 0
	jr z, RenderFilter_Type1_Unavail
	lds wa, 0
	call LABEL_F892F5
	cps l, 0
	jr z, RenderFilter_Type1_Restricted
	ld xwa, (xsp + 2)
	ld xbc, 0xEA06F4
	jrl RenderFilter_CopyAndReturn

RenderFilter_Type1_Restricted:
	ld xwa, (xsp + 2)
	ld xbc, 0xEA06FA
	jr RenderFilter_CopyAndReturn

RenderFilter_Type1_Unavail:
	ld xwa, (xsp + 2)
	ld xbc, 0xEA0700
	jr RenderFilter_CopyAndReturn

RenderFilter_CheckGeneric:
	ld a, (xsp)
	extz wa
	call LABEL_F893D1
	cps l, 0
	jr z, RenderFilter_CheckType2
	ld a, (xsp)
	extz wa
	call LABEL_F892F5
	cps l, 0
	jr z, RenderFilter_Generic_Restricted
	ld xwa, (xsp + 2)
	ld xbc, 0xEA0706
	jr RenderFilter_CopyAndReturn

RenderFilter_Generic_Restricted:
	ld xwa, (xsp + 2)
	ld xbc, 0xEA070C
	jr RenderFilter_CopyAndReturn

RenderFilter_CheckType2:
	cp (xsp), 0x2
	jr nz, RenderFilter_Default
	ldw wa, 0x8
	call LABEL_F893D1
	cps l, 0
	jr z, RenderFilter_Default
	ldw wa, 0x9
	call LABEL_F893D1
	cps l, 0
	jr z, RenderFilter_Default
	ld a, (xsp)
	extz wa
	call LABEL_F892F5
	cps l, 0
	jr z, RenderFilter_Type2_Restricted
	ld xwa, (xsp + 2)
	ld xbc, 0xEA0712
	jr RenderFilter_CopyAndReturn

RenderFilter_Type2_Restricted:
	ld xwa, (xsp + 2)
	ld xbc, 0xEA0718
	jr RenderFilter_CopyAndReturn

RenderFilter_Default:
	ld xwa, (xsp + 2)
	ld xbc, 0xEA071E

RenderFilter_CopyAndReturn:
	call LABEL_F890DC
	inc 6, xsp
	ret

FmmLoadFilterFunc:
	dec 6, xsp
	ld (xsp + 2), xde
	cp xbc, 0x1C00018
	jr z, LoadFilter_HandleScroll
	cp xbc, 0x1C00017
	jr z, LoadFilter_HandleScroll
	cp xbc, 0x1C0000B
	jr z, LoadFilter_HandleShow
	cp xbc, 0x1E50004
	jrl nz, LoadFilter_Return
	ld xwa, (xsp + 2)
	stda32 32642, xwa
	jrl LoadFilter_Return

LoadFilter_HandleShow:
	ldw (xsp), 0x0

LoadFilter_DrawLoop:
	ld wa, (xsp)
	sll wa, 4
	ldada xbc, 32646
	extz xwa
	add xwa, xbc
	ld bc, (xsp)
	extz bc
	calr RenderFilterDisplay
	ld de, (xsp)
	sll de, 4
	ldada xbc, 32646
	extz xde
	add xde, xbc
	ldda32 xwa, 32642
	ld xbc, 0x1C0000F
	call 0xFA9D58
	incm 1, (xsp)
	cpw (xsp), 0x8
	jr lt, LoadFilter_DrawLoop
	jrl LoadFilter_Return

LoadFilter_HandleScroll:
	ld xwa, (xsp + 2)
	cp xwa, 0x8
	jrl nc, LoadFilter_OpLoad
	cp xbc, 0x1C00017
	jr nz, LoadFilter_ScrollDown
	cp xwa, 0x1
	jr nz, LoadFilter_ScrollUp_CheckZero
	call LABEL_F8964C
	cps l, 0
	jr z, LoadFilter_ScrollUp_CheckZero
	lds wa, 0
	jr LoadFilter_ShowButton

LoadFilter_ScrollUp_CheckZero:
	ld xwa, (xsp + 2)
	or xwa, xwa
	jr nz, LoadFilter_ScrollUp_Restore
	call LABEL_F8964C
	cps l, 0
	jr nz, LoadFilter_UpdateDisplay

LoadFilter_ScrollUp_Restore:
	ld xwa, (xsp + 2)
	extz wa

LoadFilter_ShowButton:
	call LABEL_F89321
	jr LoadFilter_UpdateDisplay

LoadFilter_ScrollDown:
	ld xwa, (xsp + 2)
	cp xwa, 0x1
	jr nz, LoadFilter_ScrollDown_CheckZero
	call LABEL_F8964C
	cps l, 0
	jr z, LoadFilter_ScrollDown_CheckZero
	lds wa, 0
	jr LoadFilter_HideButton

LoadFilter_ScrollDown_CheckZero:
	ld xwa, (xsp + 2)
	or xwa, xwa
	jr nz, LoadFilter_ScrollDown_Restore
	call LABEL_F8964C
	cps l, 0
	jr nz, LoadFilter_UpdateDisplay

LoadFilter_ScrollDown_Restore:
	ld xwa, (xsp + 2)
	extz wa

LoadFilter_HideButton:
	call LABEL_F89335

LoadFilter_UpdateDisplay:
	ld xwa, (xsp + 2)
	ld c, a
	extz bc
	ld wa, bc
	sla wa, 4
	ldada xde, 32646
	exts xwa
	add xwa, xde
	calr RenderFilterDisplay
	ld xwa, (xsp + 2)
	extz wa
	sla wa, 4
	ldada xbc, 32646
	st_dri3b B, 0x07, 0xE4, 0xE0
	ldda32 xwa, 32642
	ld xbc, 0x1C0000F
	call 0xFA9D58
	jrl LoadFilter_Return

LoadFilter_OpLoad:
	ld xwa, (xsp + 2)
	cp xwa, 0xA
	jrl nz, LoadFilter_Return
	call 0xF8943E
	cps hl, 0
	jrl z, LoadFilter_Return
	call LABEL_F892EF
	cps hl, 0
	jrl z, LoadFilter_Return
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	call 0xF895EF
	extz hl
	ld wa, hl
	calr LABEL_F8B337
	lds wa, 0
	calr InitializeOperationState
	call LABEL_F87A08
	ld wa, hl
	lds bc, 1
	calr LABEL_F8B48E
	stda8 32578, l
	calr SignalProgressUpdate
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call 0xFA9D58
	cpdi16 61854, 0
	jr z, LoadFilter_Load_ShowCode1
	lds wa, 2
	call LABEL_F892F5
	cps l, 0
	jr z, LoadFilter_Load_ShowCode1
	lds wa, 2
	call LABEL_F893D1
	cps l, 0
	jr nz, LoadFilter_Load_ShowCodeA
	ldw wa, 0x8
	call LABEL_F893D1
	cps l, 0
	jr z, LoadFilter_Load_ShowCode1

LoadFilter_Load_ShowCodeA:
	ldw wa, 0xA
	jr LoadFilter_Load_CallHandler

LoadFilter_Load_ShowCode1:
	lds wa, 1

LoadFilter_Load_CallHandler:
	call LABEL_F99463
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0xEE
	call LABEL_F994BD

LoadFilter_Return:
	lds32 xhl, 0
	inc 6, xsp
	ret

RenderSaveFilterDisplay:
	dec 6, xsp
	ld (xsp), c
	ld (xsp + 2), xwa
	ld xwa, (xsp + 2)
	ld c, (xsp)
	lda_dpi XHL, 0xE0
	ld (xsp + 2), xwa
	ld a, c
	extz wa
	call LABEL_F89353
	cps l, 0
	jr z, RenderSaveFilter_Unavail
	cp (xsp), 0x1
	jr nz, RenderSaveFilter_Available
	call LABEL_F893AB
	cps l, 0
	jr z, RenderSaveFilter_Available
	ld xwa, (xsp + 2)
	ld xbc, 0xEA0724
	jr RenderSaveFilter_CopyAndReturn

RenderSaveFilter_Available:
	ld xwa, (xsp + 2)
	ld xbc, 0xEA072A
	jr RenderSaveFilter_CopyAndReturn

RenderSaveFilter_Unavail:
	ld xwa, (xsp + 2)
	ld xbc, 0xEA0730

RenderSaveFilter_CopyAndReturn:
	call LABEL_F890DC
	inc 6, xsp
	ret

FmmSaveFilterFunc:
	dec 6, xsp
	ld (xsp + 2), xde
	cp xbc, 0x1C00018
	jr z, SaveFilter_HandleScroll
	cp xbc, 0x1C00017
	jr z, SaveFilter_HandleScroll
	cp xbc, 0x1C0000B
	jr z, SaveFilter_HandleShow
	cp xbc, 0x1E50004
	jrl nz, SaveFilter_Return
	ld xwa, (xsp + 2)
	stda32 32774, xwa
	jrl SaveFilter_Return

SaveFilter_HandleShow:
	ldw (xsp), 0x0

SaveFilter_DrawLoop:
	ld wa, (xsp)
	sll wa, 4
	ldada xbc, 32778
	extz xwa
	add xwa, xbc
	ld bc, (xsp)
	extz bc
	calr RenderSaveFilterDisplay
	ld de, (xsp)
	sll de, 4
	ldada xbc, 32778
	extz xde
	add xde, xbc
	ldda32 xwa, 32774
	ld xbc, 0x1C0000F
	call 0xFA9D58
	incm 1, (xsp)
	cpw (xsp), 0x8
	jr lt, SaveFilter_DrawLoop
	jrl SaveFilter_Return

SaveFilter_HandleScroll:
	ld xwa, (xsp + 2)
	cp xwa, 0x8
	jrl nc, SaveFilter_SelectAll
	cp xwa, 0x1
	jr nz, SaveFilter_ScrollOther
	cp xbc, 0x1C00017
	jr nz, SaveFilter_ScrollDown
	call LABEL_F893AB
	cps l, 0
	jr z, SaveFilter_ScrollUp_Unavail
	call LABEL_F893CA
	ld xwa, (xsp + 2)
	extz wa
	jr SaveFilter_UnlockFilter

SaveFilter_ScrollUp_Unavail:
	ld xwa, (xsp + 2)
	extz wa
	jr SaveFilter_LockFilter

SaveFilter_ScrollDown:
	ld xwa, (xsp + 2)
	extz wa
	call LABEL_F89353
	cps l, 0
	jr z, SaveFilter_ScrollDown_Unlock
	call LABEL_F893AB
	cps l, 0
	jr nz, SaveFilter_UpdateDisplay
	ld xwa, (xsp + 2)
	extz wa
	jr SaveFilter_UnlockFilter

SaveFilter_ScrollDown_Unlock:
	call LABEL_F893AB
	cps l, 0
	jr nz, SaveFilter_UpdateDisplay
	call LABEL_F893C3
	ld xwa, (xsp + 2)
	extz wa
	jr SaveFilter_LockFilter

SaveFilter_ScrollOther:
	ld xwa, (xsp + 2)
	extz wa
	cp xbc, 0x1C00017
	jr nz, SaveFilter_UnlockFilter

SaveFilter_LockFilter:
	call LABEL_F8937F
	jr SaveFilter_UpdateDisplay

SaveFilter_UnlockFilter:
	call LABEL_F89393

SaveFilter_UpdateDisplay:
	ld xwa, (xsp + 2)
	ld c, a
	extz bc
	ld wa, bc
	sla wa, 4
	ldada xde, 32778
	exts xwa
	add xwa, xde
	calr RenderSaveFilterDisplay
	ld xwa, (xsp + 2)
	extz wa
	sla wa, 4
	ldada xbc, 32778
	st_dri3b B, 0x07, 0xE4, 0xE0
	ldda32 xwa, 32774
	ld xbc, 0x1C0000F
	jrl SaveFilter_DispatchWidget

SaveFilter_SelectAll:
	ld xwa, (xsp + 2)
	cp xwa, 0x8
	jr nz, SaveFilter_DeselectAll
	call LABEL_F893CA
	ldw (xsp), 0x0

SaveFilter_SelectAll_Loop:
	ld wa, (xsp)
	extz wa
	cpw (xsp), 0x6
	jr ge, SaveFilter_SelectAll_Unlock
	call LABEL_F8937F
	jr SaveFilter_SelectAll_Update

SaveFilter_SelectAll_Unlock:
	call LABEL_F89393

SaveFilter_SelectAll_Update:
	ld wa, (xsp)
	sll wa, 4
	ldada xbc, 32778
	extz xwa
	add xwa, xbc
	ld bc, (xsp)
	extz bc
	calr RenderSaveFilterDisplay
	ld de, (xsp)
	sll de, 4
	ldada xbc, 32778
	extz xde
	add xde, xbc
	ldda32 xwa, 32774
	ld xbc, 0x1C0000F
	call 0xFA9D58
	incm 1, (xsp)
	cpw (xsp), 0x8
	jr lt, SaveFilter_SelectAll_Loop
	jrl SaveFilter_Return

SaveFilter_DeselectAll:
	ld xwa, (xsp + 2)
	cp xwa, 0x9
	jr nz, SaveFilter_OpSave
	call LABEL_F893CA
	ldw (xsp), 0x0

SaveFilter_DeselectAll_Loop:
	ld wa, (xsp)
	extz wa
	call LABEL_F8937F
	ld wa, (xsp)
	sll wa, 4
	ldada xbc, 32778
	extz xwa
	add xwa, xbc
	ld bc, (xsp)
	extz bc
	calr RenderSaveFilterDisplay
	ld de, (xsp)
	sll de, 4
	ldada xbc, 32778
	extz xde
	add xde, xbc
	ldda32 xwa, 32774
	ld xbc, 0x1C0000F
	call 0xFA9D58
	incm 1, (xsp)
	cpw (xsp), 0x8
	jr lt, SaveFilter_DeselectAll_Loop
	jrl SaveFilter_Return

SaveFilter_OpSave:
	ld xwa, (xsp + 2)
	cp xwa, 0xA
	jrl nz, SaveFilter_OpFormat
	call LABEL_F8934D
	cps hl, 0
	jrl z, SaveFilter_OpFormat
	calr SelectPasswordMode
	cps hl, 0
	jr z, SaveFilter_Save_NoPwd
	lds32 xde, 0
	ldda8 e, 35340
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C50004
	jr SaveFilter_DispatchWidget

SaveFilter_Save_NoPwd:
	call 0xF8943E
	cps hl, 0
	jr z, SaveFilter_Save_Execute
	cpi8_24 0x0340ea, 0x00
	jr z, SaveFilter_Save_Execute
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C50000
	lds32 xde, 1
	call 0xFA9D58
	ld xwa, 0x600037
	ld xbc, 0x1C00001
	lds32 xde, 0

SaveFilter_DispatchWidget:
	call 0xFA9D58
	jrl SaveFilter_Return

SaveFilter_Save_Execute:
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	lds wa, 0
	calr InitializeOperationState
	call LABEL_F87EAD
	ld wa, hl
	lds bc, 5
	calr LABEL_F8B48E
	stda8 32578, l
	call LABEL_F89568
	call 0xF8953B
	call 0xF8987D
	stda16 34050, xhl
	calr SignalProgressUpdate
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call 0xFA9D58
	lds wa, 1
	call LABEL_F99463
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0xEE
	jr SaveFilter_CallStatusDisplay

SaveFilter_OpFormat:
	ld xwa, (xsp + 2)
	cp xwa, 0x32
	jr nz, SaveFilter_ResetAll
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	lds wa, 0
	calr InitializeOperationState
	call LABEL_F87EAD
	ld wa, hl
	lds bc, 5
	calr LABEL_F8B48E
	stda8 32578, l
	call LABEL_F89568
	call 0xF8953B
	call 0xF8987D
	stda16 34050, xhl
	calr SignalProgressUpdate
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call 0xFA9D58
	lds wa, 1
	call LABEL_F99463
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0xEE

SaveFilter_CallStatusDisplay:
	call LABEL_F994BD
	jr SaveFilter_Return

SaveFilter_ResetAll:
	ld xwa, (xsp + 2)
	cp xwa, 0xB
	jr nz, SaveFilter_Return
	call LABEL_F893CA
	ldw (xsp), 0x0

SaveFilter_ResetAll_Loop:
	ld wa, (xsp)
	extz wa
	call LABEL_F89393
	ld wa, (xsp)
	sll wa, 4
	ldada xbc, 32778
	extz xwa
	add xwa, xbc
	ld bc, (xsp)
	extz bc
	calr RenderSaveFilterDisplay
	ld de, (xsp)
	sll de, 4
	ldada xbc, 32778
	extz xde
	add xde, xbc
	ldda32 xwa, 32774
	ld xbc, 0x1C0000F
	call 0xFA9D58
	incm 1, (xsp)
	cpw (xsp), 0x8
	jr lt, SaveFilter_ResetAll_Loop

SaveFilter_Return:
	lds32 xhl, 0
	inc 6, xsp
	ret

