; =============================================================================
; file_io/single_load.asm - Single File Load Operations
; =============================================================================
; Single file load mode with source/destination selection.
;
; Key routines:
;   SingleLoadModeFunc               - Single load mode entry
;   SingleLoadDstBankFunc            - Destination bank selection
;   SingleLoadDstMemFunc             - Destination memory selection
;   SingleLoadSrcBankFunc            - Source bank selection
;   SingleLoadSrcMemFunc             - Source memory selection
;   SingleLoadSrcFunc                - Source file selection
;   SingleLoadDstFunc                - Destination selection
;   CmpSingleLoadSrcFunc             - Composer single load source
;   CmpSingleLoadDstFunc             - Composer single load destination
;   CmpSingleLoadFileFunc            - Composer single load file
;   FmmCmpSingleLoadFunc             - Composer single load handler
; =============================================================================

SingleLoadModeFunc:
	cp xbc, EVT_PAINT
	jr z, SLMode_HandleShow
	cp xbc, EVT_PS_FILE_NAME_BOX_ID
	jr nz, SLMode_Return
	ld (0x81b6:16), xde
	jr SLMode_Return

SLMode_HandleShow:
	ld a, (0x89f8:16)
	extz wa
	sla wa, 2
	lda xbc, (StorageArea_NameTable:24)
	ld	xde, (xbc+wa)
	ld xwa, (0x81b6:16)
	ld xbc, EVT_PARA_DRAW
	call ApPostEvent

SLMode_Return:
	ld xhl, 0:i3
	ret

SingleLoadDstBankFunc:
	cp xbc, EVT_PAINT
	jr z, SLDstBank_HandleShow
	cp xbc, EVT_PS_FILE_NAME_BOX_ID
	jr nz, SLDstBank_Return
	ld (0x81ba:16), xde
	jr SLDstBank_Return

SLDstBank_HandleShow:
	ld a, (0x89f8:16)
	extz wa
	sla wa, 2
	lda xbc, (SLDstBank_HandleShow_PtrTable:24)
	ld	xde, (xbc+wa)
	ld xwa, (0x81ba:16)
	ld xbc, EVT_PARA_DRAW
	call ApPostEvent

SLDstBank_Return:
	ld xhl, 0:i3
	ret

SingleLoadDstMemFunc:
	cp xbc, EVT_PAINT
	jr z, SLDstMem_HandleShow
	cp xbc, EVT_PS_FILE_NAME_BOX_ID
	jr nz, SLDstMem_Return
	ld (0x81be:16), xde
	jr SLDstMem_Return

SLDstMem_HandleShow:
	ld xwa, (0x81be:16)
	lda xde, (SLDstMem_HandleShow_PtrTable:24)
	cp (0x89fa:16), 0
	jr z, SLDstMem_ShowFromBank
	cp (0x89f8:16), 1
	jr z, SLDstMem_ShowFromBank
	ld xde, (xde + 16)
	ld xbc, EVT_PARA_DRAW
	jr SLDstMem_DispatchShow

SLDstMem_ShowFromBank:
	ld c, (0x89f8:16)
	extz bc
	sla bc, 2
	ld	xde, (xde+bc)
	ld xbc, EVT_PARA_DRAW

SLDstMem_DispatchShow:
	call ApPostEvent

SLDstMem_Return:
	ld xhl, 0:i3
	ret

SingleLoadSrcBankFunc:
	cp xbc, EVT_PAINT
	jr z, SLSrcBank_HandleShow
	cp xbc, EVT_PS_FILE_NAME_BOX_ID
	jr nz, SLSrcBank_Return
	ld (0x81c2:16), xde
	jr SLSrcBank_Return

SLSrcBank_HandleShow:
	ld xwa, (0x81c2:16)
	lda xde, (SLDstBank_HandleShow_PtrTable:24)
	ld c, (0x89f8:16)
	cp c, 0:i3
	jr nz, SLSrcBank_ShowFromIndex
	cp (0x8a0a:16), 0
	jr z, SLSrcBank_ShowFromIndex
	ld xde, (xde + 16)
	ld xbc, EVT_PARA_DRAW
	jr SLSrcBank_DispatchShow

SLSrcBank_ShowFromIndex:
	extz bc
	sla bc, 2
	ld	xde, (xde+bc)
	ld xbc, EVT_PARA_DRAW

SLSrcBank_DispatchShow:
	call ApPostEvent

SLSrcBank_Return:
	ld xhl, 0:i3
	ret

SingleLoadSrcMemFunc:
	cp xbc, EVT_PAINT
	jr z, SLSrcMem_HandleShow
	cp xbc, EVT_PS_FILE_NAME_BOX_ID
	jr nz, SLSrcMem_Return
	ld (0x81c6:16), xde
	jr SLSrcMem_Return

SLSrcMem_HandleShow:
	ld xwa, (0x81c6:16)
	lda xde, (SLDstMem_HandleShow_PtrTable:24)
	ld c, (0x89f8:16)
	cp c, 1:i3
	jr z, SLSrcMem_ShowDirect
	cp (0x89fa:16), 0
	jr z, SLSrcMem_ShowFromIndex

SLSrcMem_ShowDirect:
	ld xde, (xde + 16)
	ld xbc, EVT_PARA_DRAW
	jr SLSrcMem_DispatchShow

SLSrcMem_ShowFromIndex:
	extz bc
	sla bc, 2
	ld	xde, (xde+bc)
	ld xbc, EVT_PARA_DRAW

SLSrcMem_DispatchShow:
	call ApPostEvent

SLSrcMem_Return:
	ld xhl, 0:i3
	ret

SLSrcBankList_FuncBody:
	dec	6, xsp
	push	xiz
	ld	(xsp+4), c
	ld	(xsp+6), xwa
	lda	xwa, (0x894e:16)
	ld (xwa+), 0
	ld	c, (0x89f8:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLDstBank_HandleShow_PtrTable:24)
	ld	xbc, (xde+bc)
	inc	1, xbc
	call	FileIO_CopyString
	lda	xwa, (0x894f:16)
	ld	xbc, SLSrcBankList_FuncBody_Str_Colon
	call	FileIO_BuildFilePath
	lda	xiz, (0x894f:16)
	ld	a, (0x89fc:16)
	extz	wa
	div	wa, (xsp+0x4)
	inc	1, a
	extz	wa
	ld	bc, 0:i3
	calr	NumToAscii_FormatNumber
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_BuildFilePath
	lda	xwa, (0x894f:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	ld	xwa, (xsp+6)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 0x894e
	call	ApPostEvent
	pop	xiz
	inc	6, xsp
	ret
SLSrcBankList_FuncBody_Helper:
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xwa
	lda	xwa, (0x894e:16)
	ld	(xwa+21), 1
	lda	xiz, (xwa+22)
	ld	a, (0x89fc:16)
	extz	wa
	div	wa, c
	extz	wa
	call	SLSrcBankList_FuncBody_Helper12
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_CopyString
	lda	xwa, (0x8964:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xde, (0x8963:16)
	ld	xwa, (xsp+4)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	pop	xiz
	inc	4, xsp
	ret
SLSrcBankList_FuncBody_Helper2:
	dec	6, xsp
	push	xiz
	ld	(xsp+4), c
	ld	(xsp+6), xwa
	lda	xwa, (0x894e:16)
	ld	(xwa+42), 2
	lda	xwa, (xwa+43)
	ld	c, (0x89f8:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLDstMem_HandleShow_PtrTable:24)
	ld	xbc, (xde+bc)
	inc	1, xbc
	call	FileIO_CopyString
	lda	xwa, (0x8979:16)
	ld	xbc, SLSrcBankList_FuncBody_Str_Colon_2
	call	FileIO_BuildFilePath
	cp	(0x89fa:16), 0
	jr	nz, SLSrcBankList_FuncBody_Helper2_Skip
	lda	xiz, (0x8979:16)
	ld	a, (0x89fc:16)
	extz	wa
	div	wa, (xsp+0x4)
	ld	a, w
	inc	1, a
	extz	wa
	ld	bc, 0:i3
	calr	NumToAscii_FormatNumber
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_BuildFilePath
SLSrcBankList_FuncBody_Helper2_Skip:
	lda	xwa, (0x8979:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xde, (0x8978:16)
	ld	xwa, (xsp+6)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	cp	(0x89fa:16), 0
	jr	z, SLSrcBankList_FuncBody_Helper2_Epilogue
	lda	xwa, (0x894e:16)
	ld	(xwa+63), 3
	lda	xwa, (xwa+64)
	ld	xbc, SLSrcBankList_FuncBody_Str_ALL
	call	FileIO_CopyString
	lda	xde, (0x898d:16)
	ld	xwa, (xsp+6)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
SLSrcBankList_FuncBody_Helper2_Epilogue:
	pop	xiz
	inc	6, xsp
	ret
SLSrcBankList_FuncBody_Helper3:
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xwa
	cp	(0x89fa:16), 0
	jr	nz, SLSrcBankList_FuncBody_Helper3_Epilogue
	lda	xwa, (0x894e:16)
	ld	(xwa+63), 3
	lda	xiz, (xwa+64)
	ld	a, (0x89fc:16)
	extz	wa
	call	SLSrcBankList_FuncBody_Helper13
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_CopyString
	lda	xwa, (0x898e:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xde, (0x898d:16)
	ld	xwa, (xsp+4)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
SLSrcBankList_FuncBody_Helper3_Epilogue:
	pop	xiz
	inc	4, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xde
	ld	xiz, xwa
	cp	xbc, EVT_INDEXSW_DOWN
	jr	z, SLSrcBankList_FuncBody_Skip2
	cp	xbc, EVT_INDEXSW_UP
	jr	z, SLSrcBankList_FuncBody_Skip2
	cp	xbc, EVT_PAINT
	jrl	nz, SLSrcBankList_FuncBody_Join4
	cp	(0x8a0a:16), 0
	jr	z, SLSrcBankList_FuncBody_Skip
	ld	a, (0x89fc:16)
	extz	wa
	div	wa, (SLSrcBankList_FuncBody_Data:24)
	ld	(0x89fc:16), w
SLSrcBankList_FuncBody_Skip:
	ld	c, (SLSrcBankList_FuncBody_Data:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody
	ld	c, (SLSrcBankList_FuncBody_Data:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper2
	ld	c, (SLSrcBankList_FuncBody_Data:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper
	ld	c, (SLSrcBankList_FuncBody_Data:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper3
	ld	xwa, 0:i3
	ld	(0x81ca:16), xwa
	ld	(0x81ce:16), 0
	ld	(0x81d0:16), 0
	jrl	SLSrcBankList_FuncBody_Join4
SLSrcBankList_FuncBody_Skip2:
	ld	e, (0x89fc:16)
	ld	xwa, (xsp+4)
	cp	xwa, 5
	jrl	nz, SLSrcBankList_FuncBody_Skip5
	cp	(0x8a0a:16), 0
	jr	nz, SLSrcBankList_FuncBody_Skip4
	ld	xix, xbc
	cp	xbc, EVT_INDEXSW_UP
	jr	nz, SLSrcBankList_FuncBody_Skip3
	ld	l, (SLSrcBankList_FuncBody_Data:24)
	ld	a, l
	ld	c, e
	add	a, e
	cp a, (SLSrcBankList_FuncBody_Data_2:24)
	jr	nc, SLSrcBankList_FuncBody_Skip3
	add	c, l
	ld	(0x89fc:16), c
	ld	c, (SLSrcBankList_FuncBody_Data:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody
	ld	c, (SLSrcBankList_FuncBody_Data:24)
	ld	xwa, xiz
	jr	SLSrcBankList_FuncBody_Join
SLSrcBankList_FuncBody_Skip3:
	cp	xix, EVT_INDEXSW_DOWN
	jr	nz, SLSrcBankList_FuncBody_Skip4
	ld	a, e
	ld	c, (SLSrcBankList_FuncBody_Data:24)
	cp	e, c
	jr	c, SLSrcBankList_FuncBody_Skip4
	sub	a, c
	ld	(0x89fc:16), a
	ld	c, (SLSrcBankList_FuncBody_Data:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody
	ld	c, (SLSrcBankList_FuncBody_Data:24)
	ld	xwa, xiz
SLSrcBankList_FuncBody_Join:
	calr	SLSrcBankList_FuncBody_Helper2
	ld	(0x81d0:16), 1
	ld	(0x81ce:16), 1
SLSrcBankList_FuncBody_Skip4:
	ld	xwa, (0x81ca:16)
	cp	xwa, (xsp+0x4)
	jrl	z, SLSrcBankList_FuncBody_Join4
	lda	xde, (0x8963:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (0x898d:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	jrl	SLSrcBankList_FuncBody_Join3
SLSrcBankList_FuncBody_Skip5:
	ld	xwa, (xsp+4)
	cp	xwa, 6
	jrl	nz, SLSrcBankList_FuncBody_Skip8
	ld	xhl, xbc
	cp	xbc, EVT_INDEXSW_UP
	jr	nz, SLSrcBankList_FuncBody_Skip6
	ld	c, e
	ld	a, e
	inc	1, a
	cp a, (SLSrcBankList_FuncBody_Data_2:24)
	jr	nc, SLSrcBankList_FuncBody_Skip6
	ld	e, (SLSrcBankList_FuncBody_Data:24)
	ld	l, e
	ld	a, c
	extz	wa
	div	wa, l
	ld	a, w
	inc	1, a
	cp	a, e
	jr	nc, SLSrcBankList_FuncBody_Skip7
	inc	1, c
	ld	(0x89fc:16), c
	ld	c, (SLSrcBankList_FuncBody_Data:24)
	ld	xwa, xiz
	jr	SLSrcBankList_FuncBody_Join2
SLSrcBankList_FuncBody_Skip6:
	cp	xhl, EVT_INDEXSW_DOWN
	jr	nz, SLSrcBankList_FuncBody_Skip7
	ld	c, e
	cp	e, 0:i3
	jr	z, SLSrcBankList_FuncBody_Skip7
	ld	e, (SLSrcBankList_FuncBody_Data:24)
	ld	a, c
	extz	wa
	div	wa, e
	ld	a, w
	cp	a, 0:i3
	jr	z, SLSrcBankList_FuncBody_Skip7
	dec	1, c
	ld	(0x89fc:16), c
	ld	c, (SLSrcBankList_FuncBody_Data:24)
	ld	xwa, xiz
SLSrcBankList_FuncBody_Join2:
	calr	SLSrcBankList_FuncBody_Helper2
	ld	(0x81ce:16), 1
SLSrcBankList_FuncBody_Skip7:
	ld	xwa, (0x81ca:16)
	cp	xwa, (xsp+0x4)
	jrl	z, SLSrcBankList_FuncBody_Join4
	lda	xde, (0x8963:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (0x898d:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	jr	SLSrcBankList_FuncBody_Join3
SLSrcBankList_FuncBody_Skip8:
	ld	xwa, (xsp+4)
	cp	xwa, 7
	jr	z, SLSrcBankList_FuncBody_Skip9
	cp	xwa, 8
	jr	nz, SLSrcBankList_FuncBody_Skip10
SLSrcBankList_FuncBody_Skip9:
	ld	xwa, (0x81ca:16)
	cp	xwa, (xsp+0x4)
	jr	z, SLSrcBankList_FuncBody_Join4
	lda	xde, (0x8963:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (0x898d:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
SLSrcBankList_FuncBody_Join3:
	call	ApPostEvent
	ld	xwa, (xsp+4)
	ld	(0x81ca:16), xwa
	jr	SLSrcBankList_FuncBody_Join4
SLSrcBankList_FuncBody_Skip10:
	ld	xwa, (xsp+4)
	cp	xwa, 40
	jr	nz, SLSrcBankList_FuncBody_Join4
	cp	(0x81d0:16), 0
	jr	z, SLSrcBankList_FuncBody_Entry
	ld	c, (SLSrcBankList_FuncBody_Data:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper
	ld	(0x81d0:16), 0
SLSrcBankList_FuncBody_Entry:
	cp	(0x81ce:16), 0
	jr	z, SLSrcBankList_FuncBody_Join4
	ld	c, (SLSrcBankList_FuncBody_Data:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper3
	ld	(0x81ce:16), 0
SLSrcBankList_FuncBody_Join4:
	ld	xhl, 0:i3
	pop	xiz
	inc	4, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xwa
	cp	xbc, EVT_PAINT
	jrl	nz, SLSrcBankList_FuncBody_Skip11
	lda	xwa, (0x894e:16)
	ld (xwa+), 0
	ld	(xwa), 0
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xwa, (0x894e:16)
	ld	(xwa+21), 1
	lda	xwa, (xwa+22)
	ld	c, (0x89f8:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLDstMem_HandleShow_PtrTable:24)
	ld	xbc, (xde+bc)
	inc	1, xbc
	call	FileIO_CopyString
	lda	xwa, (0x8964:16)
	ld	xbc, SLSrcBankList_FuncBody_Entry_Str_Colon
	call	FileIO_BuildFilePath
	lda	xwa, (0x8964:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xwa, (0x894e:16)
	ld	(xwa+42), 2
	lda	xiz, (xwa+43)
	ld	wa, 0:i3
	call	SLSrcBankList_FuncBody_Helper14
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_CopyString
	lda	xwa, (0x8979:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xwa, (0x894e:16)
	ld	(xwa+63), 3
	lda	xwa, (xwa+64)
	ld	(xwa), 0
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	ld	xwa, (xsp+4)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 0x894e
	call	ApPostEvent
	lda	xde, (0x8963:16)
	ld	xwa, (xsp+4)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (0x8978:16)
	ld	xwa, (xsp+4)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (0x898d:16)
	ld	xwa, (xsp+4)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
SLSrcBankList_FuncBody_Skip11:
	ld	xhl, 0:i3
	pop	xiz
	inc	4, xsp
	ret
SLSrcBankList_FuncBody_Helper4:
	dec	2, xsp
	push	xiz
	ld	(xsp+4), c
	ld	xiz, xwa
	lda	xwa, (0x894e:16)
	ld (xwa+), 0
	ld	c, (0x89f8:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLDstBank_HandleShow_PtrTable:24)
	ld	xbc, (xde+bc)
	inc	1, xbc
	call	FileIO_CopyString
	lda	xwa, (0x894f:16)
	ld	xbc, SLSrcBankList_FuncBody_Entry_Str_Colon_2
	call	FileIO_BuildFilePath
	lda	xwa, (0x894f:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xwa, (0x8963:16)
	ld	c, (0x89fe:16)
	extz	bc
	div	bc, (xsp+0x4)
	extz	bc
	ld	de, 1:i3
	calr	WP_GetPresetName1
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 0x894e
	call	ApPostEvent
	lda	xde, (0x8963:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	pop	xiz
	inc	2, xsp
	ret
SLSrcBankList_FuncBody_Helper5:
	dec	8, xsp
	push	xiz
	ld	(xsp+6), c
	ld	(xsp+8), xwa
	ld	a, (0x89fe:16)
	extz	wa
	div	wa, (xsp+0x6)
	ld	a, w
	extz	wa
	ld	(xsp+4), wa
	lda	xwa, (0x894e:16)
	ld	(xwa+42), 2
	lda	xwa, (xwa+43)
	ld	c, (0x89f8:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLDstMem_HandleShow_PtrTable:24)
	ld	xbc, (xde+bc)
	inc	1, xbc
	call	FileIO_CopyString
	lda	xwa, (0x8979:16)
	ld	xbc, SLSrcBankList_FuncBody_Entry_Str_Colon_3
	call	FileIO_BuildFilePath
	cp	(0x89fa:16), 0
	jr	nz, SLSrcBankList_FuncBody_Helper5_Skip
	lda	xiz, (0x8979:16)
	ld	wa, (xsp+4)
	calr	WP_GetPresetPtr
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_BuildFilePath
SLSrcBankList_FuncBody_Helper5_Skip:
	lda	xwa, (0x8979:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xde, (0x8978:16)
	ld	xwa, (xsp+8)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xbc, (0x894e:16)
	lda	xwa, (xbc+63)
	cp	(0x89fa:16), 0
	jr	z, SLSrcBankList_FuncBody_Helper5_Skip2
	ld	(xwa), 3
	lda	xwa, (xbc+64)
	ld	xbc, SLSrcBankList_FuncBody_Entry_Str_ALL
	call	FileIO_CopyString
	lda	xde, (0x898d:16)
	ld	xwa, (xsp+8)
	ld	xbc, EVT_PARA_DRAW
	jr	SLSrcBankList_FuncBody_Helper5_Join
SLSrcBankList_FuncBody_Helper5_Skip2:
	cpw	(xsp+0x4), 4
	jr	c, SLSrcBankList_FuncBody_Helper5_Epilogue
	ld	c, (0x89fe:16)
	extz	bc
	div	bc, (xsp+0x6)
	extz	bc
	pushw	3
	ld	de, (xsp+6)
	calr	WP_GetBankMemName
	lda	xde, (0x898d:16)
	ld	xwa, (xsp+8)
	ld	xbc, EVT_PARA_DRAW
SLSrcBankList_FuncBody_Helper5_Join:
	call	ApPostEvent
SLSrcBankList_FuncBody_Helper5_Epilogue:
	pop	xiz
	inc	8, xsp
	ret
SLSrcBankList_FuncBody_Helper6:
	dec	4, xsp
	push	xiz
	ld	e, c
	ld	(xsp+4), xwa
	ld	a, (0x89fe:16)
	extz	wa
	div	wa, e
	ld	c, w
	extz	bc
	cp	(0x89fa:16), 0
	jr	nz, SLSrcBankList_FuncBody_Helper6_Epilogue
	cp	bc, 4:i3
	jr	nc, SLSrcBankList_FuncBody_Helper6_Epilogue
	lda	xwa, (0x894e:16)
	ld	(xwa+63), 3
	lda	xiz, (xwa+64)
	ld	a, (0x89fe:16)
	extz	wa
	div	wa, e
	extz	wa
	call	SLSrcBankList_FuncBody_Helper15
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_CopyString
	lda	xwa, (0x898e:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xde, (0x898d:16)
	ld	xwa, (xsp+4)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
SLSrcBankList_FuncBody_Helper6_Epilogue:
	pop	xiz
	inc	4, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xde
	ld	xde, xbc
	ld	xiz, xwa
	ld	c, (SLSrcBankList_FuncBody_Entry_Data:24)
	cp	xde, EVT_INDEXSW_DOWN
	jr	z, SLSrcBankList_FuncBody_Skip12
	cp	xde, EVT_INDEXSW_UP
	jr	z, SLSrcBankList_FuncBody_Skip12
	cp	xde, EVT_PAINT
	jrl	nz, SLSrcBankList_FuncBody_Join9
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper5
	ld	c, (SLSrcBankList_FuncBody_Entry_Data:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper4
	ld	c, (SLSrcBankList_FuncBody_Entry_Data:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper6
	ld	xwa, 0:i3
	ld	(0x81d2:16), xwa
	jrl	SLSrcBankList_FuncBody_Join8
SLSrcBankList_FuncBody_Skip12:
	ld	l, (0x89fe:16)
	ld	xwa, (xsp+4)
	cp	xwa, 5
	jrl	nz, SLSrcBankList_FuncBody_Skip15
	ld	xix, xde
	cp	xde, EVT_INDEXSW_UP
	jr	nz, SLSrcBankList_FuncBody_Skip13
	ld	e, (SLSrcBankList_FuncBody_Entry_Data:24)
	ld	a, e
	ld	c, l
	add	a, l
	cp a, (SLSrcBankList_FuncBody_Data_3:24)
	jr	nc, SLSrcBankList_FuncBody_Skip13
	add	c, e
	ld	(0x89fe:16), c
	ld	c, (SLSrcBankList_FuncBody_Entry_Data:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper4
	ld	c, (SLSrcBankList_FuncBody_Entry_Data:24)
	ld	xwa, xiz
	jr	SLSrcBankList_FuncBody_Join5
SLSrcBankList_FuncBody_Skip13:
	cp	xix, EVT_INDEXSW_DOWN
	jr	nz, SLSrcBankList_FuncBody_Skip14
	ld	a, l
	ld	c, (SLSrcBankList_FuncBody_Entry_Data:24)
	cp	l, c
	jr	c, SLSrcBankList_FuncBody_Skip14
	sub	a, c
	ld	(0x89fe:16), a
	ld	c, (SLSrcBankList_FuncBody_Entry_Data:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper4
	ld	c, (SLSrcBankList_FuncBody_Entry_Data:24)
	ld	xwa, xiz
SLSrcBankList_FuncBody_Join5:
	calr	SLSrcBankList_FuncBody_Helper5
	ld	(0x81d6:16), 1
SLSrcBankList_FuncBody_Skip14:
	ld	xwa, (0x81d2:16)
	cp	xwa, (xsp+0x4)
	jrl	z, SLSrcBankList_FuncBody_Join9
	lda	xde, (0x8963:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (0x898d:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	jrl	SLSrcBankList_FuncBody_Join7
SLSrcBankList_FuncBody_Skip15:
	ld	xwa, (xsp+4)
	cp	xwa, 6
	jrl	nz, SLSrcBankList_FuncBody_Skip18
	ld	xix, xde
	cp	xde, EVT_INDEXSW_UP
	jr	nz, SLSrcBankList_FuncBody_Skip16
	ld	c, l
	ld	a, l
	inc	1, a
	cp a, (SLSrcBankList_FuncBody_Data_3:24)
	jr	nc, SLSrcBankList_FuncBody_Skip16
	ld	e, (SLSrcBankList_FuncBody_Entry_Data:24)
	ld	l, e
	ld	a, c
	extz	wa
	div	wa, l
	ld	a, w
	inc	1, a
	cp	a, e
	jr	nc, SLSrcBankList_FuncBody_Skip17
	inc	1, c
	ld	(0x89fe:16), c
	ld	c, (SLSrcBankList_FuncBody_Entry_Data:24)
	ld	xwa, xiz
	jr	SLSrcBankList_FuncBody_Join6
SLSrcBankList_FuncBody_Skip16:
	cp	xix, EVT_INDEXSW_DOWN
	jr	nz, SLSrcBankList_FuncBody_Skip17
	ld	c, l
	cp	l, 0:i3
	jr	z, SLSrcBankList_FuncBody_Skip17
	ld	e, (SLSrcBankList_FuncBody_Entry_Data:24)
	ld	a, c
	extz	wa
	div	wa, e
	ld	a, w
	cp	a, 0:i3
	jr	z, SLSrcBankList_FuncBody_Skip17
	dec	1, c
	ld	(0x89fe:16), c
	ld	c, (SLSrcBankList_FuncBody_Entry_Data:24)
	ld	xwa, xiz
SLSrcBankList_FuncBody_Join6:
	calr	SLSrcBankList_FuncBody_Helper5
	ld	(0x81d6:16), 1
SLSrcBankList_FuncBody_Skip17:
	ld	xwa, (0x81d2:16)
	cp	xwa, (xsp+0x4)
	jr	z, SLSrcBankList_FuncBody_Join9
	lda	xde, (0x8963:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (0x898d:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	jr	SLSrcBankList_FuncBody_Join7
SLSrcBankList_FuncBody_Skip18:
	ld	xwa, (xsp+4)
	cp	xwa, 7
	jr	z, SLSrcBankList_FuncBody_Skip19
	cp	xwa, 8
	jr	nz, SLSrcBankList_FuncBody_Skip20
SLSrcBankList_FuncBody_Skip19:
	ld	xwa, (0x81d2:16)
	cp	xwa, (xsp+0x4)
	jr	z, SLSrcBankList_FuncBody_Join9
	lda	xde, (0x8963:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (0x898d:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
SLSrcBankList_FuncBody_Join7:
	call	ApPostEvent
	ld	xwa, (xsp+4)
	ld	(0x81d2:16), xwa
	jr	SLSrcBankList_FuncBody_Join9
SLSrcBankList_FuncBody_Skip20:
	ld	xwa, (xsp+4)
	cp	xwa, 40
	jr	nz, SLSrcBankList_FuncBody_Join9
	cp	(0x81d6:16), 0
	jr	z, SLSrcBankList_FuncBody_Join9
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper6
SLSrcBankList_FuncBody_Join8:
	ld	(0x81d6:16), 0
SLSrcBankList_FuncBody_Join9:
	ld	xhl, 0:i3
	pop	xiz
	inc	4, xsp
	ret
SLSrcBankList_FuncBody_Helper7:
	ld	xix, (xsp+4)
	ld	l, c
	add	l, c
	cp	(xde), l
	jr	nc, SLSrcBankList_FuncBody_Skip21
	cp	(xix), l
	jr	c, SLSrcBankList_FuncBody_Return
SLSrcBankList_FuncBody_Skip21:
	cp	(xde), l
	jr	c, SLSrcBankList_FuncBody_Skip22
	cp	(xix), l
	jr	nc, SLSrcBankList_FuncBody_Return
SLSrcBankList_FuncBody_Skip22:
	cp	xwa, 8
	jr	z, SLSrcBankList_FuncBody_Skip24
	cp	xwa, 7
	jr	z, SLSrcBankList_FuncBody_Skip24
	cp	xwa, 6
	jr	z, SLSrcBankList_FuncBody_Skip23
	cp	xwa, 5
	jr	nz, SLSrcBankList_FuncBody_Return
SLSrcBankList_FuncBody_Skip23:
	ld	a, (xde)
	ld	(xix), a
	ld	xwa, 0:i3
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 0:i3
	calr	SingleLoadDstFunc
	jr	SLSrcBankList_FuncBody_Return
SLSrcBankList_FuncBody_Skip24:
	ld	a, (xix)
	ld	(xde), a
	ld	xwa, 0:i3
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	calr	SingleLoadSrcFunc
SLSrcBankList_FuncBody_Return:
	retd	4
SLSrcBankList_FuncBody_Helper8:
	dec	6, xsp
	ld	(xsp), c
	ld	(xsp+2), xwa
	lda	xwa, (0x894e:16)
	ld (xwa+), 0
	ld	c, (0x89f8:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLDstBank_HandleShow_PtrTable:24)
	ld	xbc, (xde+bc)
	inc	1, xbc
	call	FileIO_CopyString
	lda	xwa, (0x894f:16)
	ld	xbc, SLSrcBankList_FuncBody_Entry_Str_Colon_4
	call	FileIO_BuildFilePath
	lda	xwa, (0x894f:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	ld	xwa, (xsp+2)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 0x894e
	call	ApPostEvent
	ld	a, (xsp)
	add	a, (xsp)
	ld	c, (0x8a00:16)
	cp	c, a
	jr	nc, SLSrcBankList_FuncBody_Epilogue
	lda	xwa, (0x8963:16)
	extz	bc
	div	bc, (xsp)
	extz	bc
	ld	de, 1:i3
	calr	WP_GetPresetName3
	lda	xde, (0x8963:16)
	ld	xwa, (xsp+2)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
SLSrcBankList_FuncBody_Epilogue:
	inc	6, xsp
	ret
SLSrcBankList_FuncBody_Helper9:
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xwa
	ld	a, c
	add	a, c
	cp	(0x8a00:16), a
	jr	c, SLSrcBankList_FuncBody_Epilogue2
	lda	xwa, (0x894e:16)
	ld	(xwa+21), 1
	lda	xiz, (xwa+22)
	call	SLSrcBankList_FuncBody_Helper17
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_CopyString
	lda	xwa, (0x8964:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xde, (0x8963:16)
	ld	xwa, (xsp+4)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
SLSrcBankList_FuncBody_Epilogue2:
	pop	xiz
	inc	4, xsp
	ret
SLSrcBankList_FuncBody_Helper10:
	dec	6, xsp
	push	xiz
	ld	(xsp+4), c
	ld	(xsp+6), xwa
	lda	xwa, (0x894e:16)
	ld	(xwa+42), 2
	lda	xwa, (xwa+43)
	ld	c, (0x89f8:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLDstMem_HandleShow_PtrTable:24)
	ld	xbc, (xde+bc)
	inc	1, xbc
	call	FileIO_CopyString
	lda	xwa, (0x8979:16)
	ld	xbc, SLSrcBankList_FuncBody_Entry_Str_Colon_5
	call	FileIO_BuildFilePath
	cp	(0x89fa:16), 0
	jr	nz, SLSrcBankList_FuncBody_Helper10_Skip2
	ld	e, (xsp+4)
	add	e, (xsp+0x4)
	ld	c, (0x8a00:16)
	lda	xwa, (0x8979:16)
	cp	c, e
	jr	c, SLSrcBankList_FuncBody_Helper10_Skip
	ld	xiz, xwa
	sub	c, e
	inc	1, c
	extz	bc
	ld	wa, bc
	ld	bc, 0:i3
	calr	NumToAscii_FormatNumber
	ld	xbc, xhl
	ld	xwa, xiz
	jr	SLSrcBankList_FuncBody_Join10
SLSrcBankList_FuncBody_Helper10_Skip:
	ld	xiz, xwa
	extz	bc
	div	bc, (xsp+0x4)
	ld	a, b
	inc	1, a
	extz	wa
	ld	bc, 0:i3
	calr	NumToAscii_FormatNumber
	ld	xbc, xhl
	ld	xwa, xiz
SLSrcBankList_FuncBody_Join10:
	call	FileIO_BuildFilePath
SLSrcBankList_FuncBody_Helper10_Skip2:
	lda	xwa, (0x8979:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xde, (0x8978:16)
	ld	xwa, (xsp+6)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	cp	(0x89fa:16), 0
	jr	z, SLSrcBankList_FuncBody_Helper10_Epilogue
	lda	xwa, (0x894e:16)
	ld	(xwa+63), 3
	lda	xwa, (xwa+64)
	ld	xbc, Str_AllOption_EA0980
	call	FileIO_CopyString
	lda	xde, (0x898d:16)
	ld	xwa, (xsp+6)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
SLSrcBankList_FuncBody_Helper10_Epilogue:
	pop	xiz
	inc	6, xsp
	ret
SLSrcBankList_FuncBody_Helper11:
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xwa
	cp	(0x89fa:16), 0
	jr	nz, SLSrcBankList_FuncBody_Helper11_Epilogue
	lda	xwa, (0x894e:16)
	ld	(xwa+63), 3
	ld	e, c
	add	e, c
	lda	xiz, (xwa+64)
	ld	a, (0x8a00:16)
	cp	a, e
	jr	c, SLSrcBankList_FuncBody_Helper11_Skip
	sub	a, e
	extz	wa
	call	SLSrcBankList_FuncBody_Helper18
	ld	xbc, xhl
	ld	xwa, xiz
	jr	SLSrcBankList_FuncBody_Join11
SLSrcBankList_FuncBody_Helper11_Skip:
	extz	wa
	call	SLSrcBankList_FuncBody_Helper16
	ld	xbc, xhl
	ld	xwa, xiz
SLSrcBankList_FuncBody_Join11:
	call	FileIO_CopyString
	lda	xwa, (0x898e:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xde, (0x898d:16)
	ld	xwa, (xsp+4)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
SLSrcBankList_FuncBody_Helper11_Epilogue:
	pop	xiz
	inc	4, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xde
	ld	xiz, xwa
	ld	e, (SLSrcBankList_FuncBody_Entry_Data_2:24)
	cp	xbc, EVT_INDEXSW_DOWN
	jr	z, SLSrcBankList_FuncBody_Skip25
	cp	xbc, EVT_INDEXSW_UP
	jr	z, SLSrcBankList_FuncBody_Skip25
	cp	xbc, EVT_PAINT
	jrl	nz, SLSrcBankList_FuncBody_Join17
	ld	xwa, xiz
	ld	c, e
	calr	SLSrcBankList_FuncBody_Helper8
	ld	c, (SLSrcBankList_FuncBody_Entry_Data_2:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper10
	ld	c, (SLSrcBankList_FuncBody_Entry_Data_2:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper9
	ld	c, (SLSrcBankList_FuncBody_Entry_Data_2:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper11
	ld	xwa, 0:i3
	ld	(0x81d8:16), xwa
	ld	(0x81dc:16), 0
	ld	(0x81de:16), 0
	jrl	SLSrcBankList_FuncBody_Join17
SLSrcBankList_FuncBody_Skip25:
	ld	l, (0x8a00:16)
	ld	xwa, (xsp+4)
	cp	xwa, 5
	jrl	nz, SLSrcBankList_FuncBody_Skip30
	ld	xde, xbc
	cp	xbc, EVT_INDEXSW_UP
	jr	nz, SLSrcBankList_FuncBody_Skip27
	ld	c, (SLSrcBankList_FuncBody_Entry_Data_2:24)
	ld	w, c
	add	w, c
	ld	a, l
	cp	l, w
	jr	nc, SLSrcBankList_FuncBody_Skip27
	cp	a, c
	jr	nc, SLSrcBankList_FuncBody_Skip26
	add	a, c
	ld	(0x8a00:16), a
	jr	SLSrcBankList_FuncBody_Join12
SLSrcBankList_FuncBody_Skip26:
	ld	(0x8a00:16), w
SLSrcBankList_FuncBody_Join12:
	ld	c, (SLSrcBankList_FuncBody_Entry_Data_2:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper8
	ld	c, (SLSrcBankList_FuncBody_Entry_Data_2:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper10
	ld	c, (SLSrcBankList_FuncBody_Entry_Data_2:24)
	pushw	0
	pushw	0x8a08
	ld	xwa, (xsp+8)
	ld	xde, 0x8a00
	jr	SLSrcBankList_FuncBody_Join14
SLSrcBankList_FuncBody_Skip27:
	cp	xde, EVT_INDEXSW_DOWN
	jr	nz, SLSrcBankList_FuncBody_Skip29
	ld	c, l
	ld	e, (SLSrcBankList_FuncBody_Entry_Data_2:24)
	cp	l, e
	jr	c, SLSrcBankList_FuncBody_Skip29
	ld	a, e
	add	a, e
	cp	c, a
	jr	nc, SLSrcBankList_FuncBody_Skip28
	sub	c, e
	ld	(0x8a00:16), c
	jr	SLSrcBankList_FuncBody_Join13
SLSrcBankList_FuncBody_Skip28:
	ld	(0x8a00:16), e
SLSrcBankList_FuncBody_Join13:
	ld	c, (SLSrcBankList_FuncBody_Entry_Data_2:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper8
	ld	c, (SLSrcBankList_FuncBody_Entry_Data_2:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper10
	ld	c, (SLSrcBankList_FuncBody_Entry_Data_2:24)
	pushw	0
	pushw	0x8a08
	ld	xwa, (xsp+8)
	ld	xde, 0x8a00
SLSrcBankList_FuncBody_Join14:
	calr	SLSrcBankList_FuncBody_Helper7
	ld	(0x81de:16), 1
	ld	(0x81dc:16), 1
SLSrcBankList_FuncBody_Skip29:
	ld	xwa, (0x81d8:16)
	cp	xwa, (xsp+0x4)
	jrl	z, SLSrcBankList_FuncBody_Join17
	lda	xde, (0x8963:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (0x898d:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	jrl	SLSrcBankList_FuncBody_Join16
SLSrcBankList_FuncBody_Skip30:
	ld	xwa, (xsp+4)
	cp	xwa, 6
	jrl	nz, SLSrcBankList_FuncBody_Skip35
	ld	xde, xbc
	cp	xbc, EVT_INDEXSW_UP
	jr	nz, SLSrcBankList_FuncBody_Skip32
	ld	c, l
	ld	a, l
	inc	1, a
	cp a, (SLSrcBankList_FuncBody_Data_4:24)
	jr	nc, SLSrcBankList_FuncBody_Skip32
	ld	e, (SLSrcBankList_FuncBody_Entry_Data_2:24)
	ld	a, e
	add	a, e
	cp	c, a
	jr	nc, SLSrcBankList_FuncBody_Skip31
	ld	l, e
	ld	a, c
	extz	wa
	div	wa, l
	ld	a, w
	inc	1, a
	cp	a, e
	jrl	nc, SLSrcBankList_FuncBody_Skip34
	inc	1, c
	ld	(0x8a00:16), c
	ld	c, (SLSrcBankList_FuncBody_Entry_Data_2:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper10
	ld	c, (SLSrcBankList_FuncBody_Entry_Data_2:24)
	pushw	0
	pushw	0x8a08
	ld	xwa, (xsp+8)
	ld	xde, 0x8a00
	jrl	SLSrcBankList_FuncBody_Join15
SLSrcBankList_FuncBody_Skip31:
	inc	1, c
	ld	(0x8a00:16), c
	ld	c, (SLSrcBankList_FuncBody_Entry_Data_2:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper10
	ld	c, (SLSrcBankList_FuncBody_Entry_Data_2:24)
	pushw	0
	pushw	0x8a08
	ld	xwa, (xsp+8)
	ld	xde, 0x8a00
	jr	SLSrcBankList_FuncBody_Join15
SLSrcBankList_FuncBody_Skip32:
	cp	xde, EVT_INDEXSW_DOWN
	jr	nz, SLSrcBankList_FuncBody_Skip34
	ld	c, l
	cp	l, 0:i3
	jr	z, SLSrcBankList_FuncBody_Skip34
	ld	e, (SLSrcBankList_FuncBody_Entry_Data_2:24)
	ld	a, e
	add	a, e
	cp	c, a
	jr	nc, SLSrcBankList_FuncBody_Skip33
	ld	a, c
	extz	wa
	div	wa, e
	ld	a, w
	cp	a, 0:i3
	jr	z, SLSrcBankList_FuncBody_Skip34
	dec	1, c
	ld	(0x8a00:16), c
	ld	c, (SLSrcBankList_FuncBody_Entry_Data_2:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper10
	ld	c, (SLSrcBankList_FuncBody_Entry_Data_2:24)
	pushw	0
	pushw	0x8a08
	ld	xwa, (xsp+8)
	ld	xde, 0x8a00
	jr	SLSrcBankList_FuncBody_Join15
SLSrcBankList_FuncBody_Skip33:
	cp	c, a
	jr	ule, SLSrcBankList_FuncBody_Skip34
	dec	1, c
	ld	(0x8a00:16), c
	ld	c, (SLSrcBankList_FuncBody_Entry_Data_2:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper10
	ld	c, (SLSrcBankList_FuncBody_Entry_Data_2:24)
	pushw	0
	pushw	0x8a08
	ld	xwa, (xsp+8)
	ld	xde, 0x8a00
SLSrcBankList_FuncBody_Join15:
	calr	SLSrcBankList_FuncBody_Helper7
	ld	(0x81dc:16), 1
SLSrcBankList_FuncBody_Skip34:
	ld	xwa, (0x81d8:16)
	cp	xwa, (xsp+0x4)
	jrl	z, SLSrcBankList_FuncBody_Join17
	lda	xde, (0x8963:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (0x898d:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	jr	SLSrcBankList_FuncBody_Join16
SLSrcBankList_FuncBody_Skip35:
	ld	xwa, (xsp+4)
	cp	xwa, 7
	jr	z, SLSrcBankList_FuncBody_Skip36
	cp	xwa, 8
	jr	nz, SLSrcBankList_FuncBody_Skip37
SLSrcBankList_FuncBody_Skip36:
	ld	xwa, (0x81d8:16)
	cp	xwa, (xsp+0x4)
	jr	z, SLSrcBankList_FuncBody_Join17
	lda	xde, (0x8963:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (0x898d:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
SLSrcBankList_FuncBody_Join16:
	call	ApPostEvent
	ld	xwa, (xsp+4)
	ld	(0x81d8:16), xwa
	jr	SLSrcBankList_FuncBody_Join17
SLSrcBankList_FuncBody_Skip37:
	ld	xwa, (xsp+4)
	cp	xwa, 40
	jr	nz, SLSrcBankList_FuncBody_Join17
	cp	(0x81de:16), 0
	jr	z, SLSrcBankList_FuncBody_Entry2
	ld	xwa, xiz
	ld	c, e
	calr	SLSrcBankList_FuncBody_Helper9
	ld	(0x81de:16), 0
SLSrcBankList_FuncBody_Entry2:
	cp	(0x81dc:16), 0
	jr	z, SLSrcBankList_FuncBody_Join17
	ld	c, (SLSrcBankList_FuncBody_Entry_Data_2:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper11
	ld	(0x81dc:16), 0
SLSrcBankList_FuncBody_Join17:
	ld	xhl, 0:i3
	pop	xiz
	inc	4, xsp
	ret
	dec	4, xsp
	pushw	iz
	ld	(xsp+2), xwa
	cp	xbc, EVT_PAINT
	jr	nz, SLSrcBankList_FuncBody_Skip38
	ld	iz, 0:i3
SLSrcBankList_FuncBody_Loop:
	ld	de, iz
	mul	de, 21
	lda	xbc, (0x894e:16)
	ld	hl, de
	extz	xhl
	add	xhl, xbc
	ldto_berp a, 248
	ld	(xhl), a
	ld	wa, 1:i3
	add	wa, de
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 0
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	ld	de, iz
	mul	de, 21
	lda	xwa, (0x894e:16)
	extz	xde
	add	xde, xwa
	ld	xwa, (xsp+2)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	inc	1, iz
	cp	iz, 4:i3
	jr	c, SLSrcBankList_FuncBody_Loop
SLSrcBankList_FuncBody_Skip38:
	ld	xhl, 0:i3
	popw	iz
	inc	4, xsp
	ret

SingleLoadSrcFunc:
	dec 4, xsp
	push xiz
	ld xiz, xde
	ld (xsp + 4), xbc
	ld xwa, (xsp + 4)
	cp xwa, EVT_GET_SELECTED_FILE_NUMBER
	jrl z, SLSrc_ReturnCapture
	cp xwa, EVT_INDEXSW_DOWN
	jr z, SLSrc_HandleScroll
	cp xwa, EVT_INDEXSW_UP
	jr z, SLSrc_HandleScroll
	cp xwa, EVT_PAINT
	jr z, SLSrc_HandleShow
	cp xwa, EVT_PS_FILE_NAME_BOX_ID
	jrl nz, SLSrc_Return
	ld xwa, xiz
	ld (0x81e0:16), xwa
	ld xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld xde, 0xffffffff
	call ApPostEvent
	jrl SLSrc_Return

SLSrc_HandleShow:
	ld xwa, (0x81e0:16)
	ld xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld xde, 0xffffffff
	call ApPostEvent
	ld xwa, (0x81e0:16)
	ld c, (0x89f8:16)
	extz bc
	sla bc, 2
	lda xde, (SLSrc_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld xbc, (xsp + 4)
	ld xde, xiz
	ld xhl, (xhl)
	call (xhl)
	calr SignalProgressUpdate
	jrl SLSrc_Return

SLSrc_HandleScroll:
	cp xiz, 0x5
	jr nz, SLSrc_ScrollMode6
	cp (0x89f8:16), 1
	jr z, SLSrc_ScrollMode5_Prev
	ld xwa, (0x81e0:16)
	ld xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld xde, 1:i3
	jr SLSrc_ScrollMode5_Dispatch

SLSrc_ScrollMode5_Prev:
	ld xwa, (0x81e0:16)
	ld xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld xde, 0xffffffff

SLSrc_ScrollMode5_Dispatch:
	call ApPostEvent
	ld xwa, (0x81e0:16)
	ld c, (0x89f8:16)
	extz bc
	sla bc, 2
	lda xde, (SLSrc_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld xbc, (xsp + 4)
	ld xde, xiz
	ld xhl, (xhl)
	call (xhl)
	jrl SLSrc_Return

SLSrc_ScrollMode6:
	cp xiz, 0x6
	jr nz, SLSrc_ScrollMode7
	cp (0x89f8:16), 1
	jr z, SLSrc_ScrollMode6_NoStep
	cp (0x89fa:16), 0
	jr nz, SLSrc_ScrollMode6_NoStep
	ld xwa, (0x81e0:16)
	ld xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld xde, 3:i3
	jr SLSrc_ScrollMode6_Dispatch

SLSrc_ScrollMode6_NoStep:
	ld xwa, (0x81e0:16)
	ld xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld xde, 0xffffffff

SLSrc_ScrollMode6_Dispatch:
	call ApPostEvent
	ld xwa, (0x81e0:16)
	ld c, (0x89f8:16)
	extz bc
	sla bc, 2
	lda xde, (SLSrc_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld xbc, (xsp + 4)
	ld xde, xiz
	ld xhl, (xhl)
	call (xhl)
	jrl SLSrc_Return

SLSrc_ScrollMode7:
	ld xwa, (0x81e0:16)
	cp xiz, 0x7
	jr nz, SLSrc_ScrollMode8
	ld xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld xde, 0xffffffff
	call ApPostEvent
	ld xwa, (0x81e0:16)
	ld c, (0x89f8:16)
	extz bc
	sla bc, 2
	lda xde, (SLSrc_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld xbc, (xsp + 4)
	ld xde, xiz
	ld xhl, (xhl)
	call (xhl)
	jr SLSrc_Return

SLSrc_ScrollMode8:
	cp xiz, 0x8
	jr nz, SLSrc_ScrollMode40
	ld xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld xde, 0xffffffff
	call ApPostEvent
	ld xwa, (0x81e0:16)
	ld c, (0x89f8:16)
	extz bc
	sla bc, 2
	lda xde, (SLSrc_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld xbc, (xsp + 4)
	ld xde, xiz
	ld xhl, (xhl)
	call (xhl)
	jr SLSrc_Return

SLSrc_ScrollMode40:
	cp xiz, 0x28
	jr nz, SLSrc_Return
	ld c, (0x89f8:16)
	extz bc
	sla bc, 2
	lda xde, (SLSrc_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld xbc, (xsp + 4)
	ld xde, xiz
	ld xhl, (xhl)
	call (xhl)

SLSrc_Return:
	ld xhl, 0:i3
	jr SLSrc_Epilogue

SLSrc_ReturnCapture:
	ld xhl, 0xffffffff

SLSrc_Epilogue:
	pop xiz
	inc 4, xsp
	ret

SLDstBankList_FuncBody:
	dec	6, xsp
	push	xiz
	ld	(xsp+4), c
	ld	(xsp+6), xwa
	lda	xwa, (0x89a2:16)
	ld (xwa+), 0
	ld	c, (0x89f8:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLDstBank_HandleShow_PtrTable:24)
	ld	xbc, (xde+bc)
	inc	1, xbc
	call	FileIO_CopyString
	lda	xwa, (0x89a3:16)
	ld	xbc, SLDstBankList_FuncBody_Str_Colon
	call	FileIO_BuildFilePath
	lda	xiz, (0x89a3:16)
	ld	a, (0x8a02:16)
	extz	wa
	div	wa, (xsp+0x4)
	inc	1, a
	extz	wa
	ld	bc, 0:i3
	calr	NumToAscii_FormatNumber
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_BuildFilePath
	lda	xwa, (0x89a3:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xwa, (0x89b7:16)
	ld	c, (0x8a02:16)
	extz	bc
	div	bc, (xsp+0x4)
	extz	bc
	ld	de, 1:i3
	calr	WP_GetConfigName
	lda	xwa, (0x89b8:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	ld	xwa, (xsp+6)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 0x89a2
	call	ApPostEvent
	lda	xde, (0x89b7:16)
	ld	xwa, (xsp+6)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	pop	xiz
	inc	6, xsp
	ret
SLDstBankList_FuncBody_Helper:
	dec	6, xsp
	push	xiz
	ld	(xsp+4), c
	ld	(xsp+6), xwa
	lda	xde, (0x89a2:16)
	ld	(xde+42), 2
	ld	(xde+63), 3
	ld	a, (0x89f8:16)
	extz	wa
	lda	xhl, (SLDstMem_HandleShow_PtrTable:24)
	ld	bc, wa
	sla	bc, 2
	lda	xwa, (xde+43)
	ld	xbc, (xhl+bc)
	inc	1, xbc
	cp	(0x89fa:16), 0
	jr	z, SLDstBankList_FuncBody_Helper_Skip
	call	FileIO_CopyString
	lda	xwa, (0x89cd:16)
	ld	xbc, SLDstBankList_FuncBody_Str_Colon_2
	call	FileIO_BuildFilePath
	lda	xwa, (0x89cd:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xwa, (0x89e2:16)
	.byte 0x41
	.long Str_AllOption_EA09B2
	call	FileIO_CopyString
	jr	SLDstBankList_FuncBody_Join
SLDstBankList_FuncBody_Helper_Skip:
	call	FileIO_CopyString
	lda	xwa, (0x89cd:16)
	ld	xbc, SLDstBankList_FuncBody_Str_Colon_3
	call	FileIO_BuildFilePath
	lda	xiz, (0x89cd:16)
	ld	a, (0x8a02:16)
	extz	wa
	div	wa, (xsp+0x4)
	ld	a, w
	inc	1, a
	extz	wa
	ld	bc, 0:i3
	calr	NumToAscii_FormatNumber
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_BuildFilePath
	lda	xwa, (0x89cd:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xwa, (0x89e1:16)
	ld	c, (0x8a02:16)
	extz	bc
	ld	de, 3:i3
	calr	WP_GetNameByOffset
SLDstBankList_FuncBody_Join:
	lda	xde, (0x89cc:16)
	ld	xwa, (xsp+6)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (0x89e1:16)
	ld	xwa, (xsp+6)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	pop	xiz
	inc	6, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xde
	ld	xde, xbc
	ld	xiz, xwa
	ld	c, (SLDstBankList_FuncBody_Data:24)
	cp	xde, EVT_INDEXSW_DOWN
	jr	z, SLDstBankList_FuncBody_Skip
	cp	xde, EVT_INDEXSW_UP
	jr	z, SLDstBankList_FuncBody_Skip
	cp	xde, EVT_PAINT
	jrl	nz, SLDstBankList_FuncBody_Loop
	ld	xwa, xiz
	calr	SLDstBankList_FuncBody
	ld	c, (SLDstBankList_FuncBody_Data:24)
	ld	xwa, xiz
	calr	SLDstBankList_FuncBody_Helper
	ld	xwa, 0:i3
	ld	(0x81e4:16), xwa
	jrl	SLDstBankList_FuncBody_Loop
SLDstBankList_FuncBody_Skip:
	ld	l, (0x8a02:16)
	ld	xwa, (xsp+4)
	cp	xwa, 7
	jrl	nz, SLDstBankList_FuncBody_Skip4
	ld	xix, xde
	cp	xde, EVT_INDEXSW_UP
	jr	nz, SLDstBankList_FuncBody_Skip2
	ld	e, (SLDstBankList_FuncBody_Data:24)
	ld	a, e
	ld	c, l
	add	a, l
	cp a, (SLDstBankList_FuncBody_Data_5:24)
	jr	nc, SLDstBankList_FuncBody_Skip2
	add	c, e
	ld	(0x8a02:16), c
	ld	c, (SLDstBankList_FuncBody_Data:24)
	ld	xwa, xiz
	calr	SLDstBankList_FuncBody
	ld	c, (SLDstBankList_FuncBody_Data:24)
	ld	xwa, xiz
	jr	SLDstBankList_FuncBody_Join2
SLDstBankList_FuncBody_Skip2:
	cp	xix, EVT_INDEXSW_DOWN
	jr	nz, SLDstBankList_FuncBody_Skip3
	ld	a, l
	ld	c, (SLDstBankList_FuncBody_Data:24)
	cp	l, c
	jr	c, SLDstBankList_FuncBody_Skip3
	sub	a, c
	ld	(0x8a02:16), a
	ld	c, (SLDstBankList_FuncBody_Data:24)
	ld	xwa, xiz
	calr	SLDstBankList_FuncBody
	ld	c, (SLDstBankList_FuncBody_Data:24)
	ld	xwa, xiz
SLDstBankList_FuncBody_Join2:
	calr	SLDstBankList_FuncBody_Helper
SLDstBankList_FuncBody_Skip3:
	ld	xwa, (0x81e4:16)
	cp	xwa, (xsp+0x4)
	jr	z, SLDstBankList_FuncBody_Loop
	lda	xde, (0x89b7:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (0x89e1:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
SLDstBankList_FuncBody_Join3:
	call	ApPostEvent
	ld	xwa, (xsp+4)
	ld	(0x81e4:16), xwa
SLDstBankList_FuncBody_Loop:
	ld	xhl, 0:i3
	jrl	SLDstBankList_FuncBody_Epilogue
SLDstBankList_FuncBody_Skip4:
	ld	xwa, (xsp+4)
	cp	xwa, 8
	jrl	nz, SLDstBankList_FuncBody_Skip7
	ld	xix, xde
	cp	xde, EVT_INDEXSW_UP
	jr	nz, SLDstBankList_FuncBody_Skip5
	ld	c, l
	ld	a, l
	inc	1, a
	cp a, (SLDstBankList_FuncBody_Data_5:24)
	jr	nc, SLDstBankList_FuncBody_Skip5
	ld	e, (SLDstBankList_FuncBody_Data:24)
	ld	l, e
	ld	a, c
	extz	wa
	div	wa, l
	ld	a, w
	inc	1, a
	cp	a, e
	jr	nc, SLDstBankList_FuncBody_Skip6
	inc	1, c
	ld	(0x8a02:16), c
	ld	c, (SLDstBankList_FuncBody_Data:24)
	ld	xwa, xiz
	jr	SLDstBankList_FuncBody_Join4
SLDstBankList_FuncBody_Skip5:
	cp	xix, EVT_INDEXSW_DOWN
	jr	nz, SLDstBankList_FuncBody_Skip6
	ld	c, l
	cp	l, 0:i3
	jr	z, SLDstBankList_FuncBody_Skip6
	ld	e, (SLDstBankList_FuncBody_Data:24)
	ld	a, c
	extz	wa
	div	wa, e
	ld	a, w
	cp	a, 0:i3
	jr	z, SLDstBankList_FuncBody_Skip6
	dec	1, c
	ld	(0x8a02:16), c
	ld	c, (SLDstBankList_FuncBody_Data:24)
	ld	xwa, xiz
SLDstBankList_FuncBody_Join4:
	calr	SLDstBankList_FuncBody_Helper
SLDstBankList_FuncBody_Skip6:
	ld	xwa, (0x81e4:16)
	cp	xwa, (xsp+0x4)
	jrl	z, SLDstBankList_FuncBody_Loop
	lda	xde, (0x89b7:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (0x89e1:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	jrl	SLDstBankList_FuncBody_Join3
SLDstBankList_FuncBody_Skip7:
	ld	xwa, (xsp+4)
	cp	xwa, 5
	jr	z, SLDstBankList_FuncBody_Skip8
	cp	xwa, 6
	jr	nz, SLDstBankList_FuncBody_Skip9
SLDstBankList_FuncBody_Skip8:
	ld	xwa, (0x81e4:16)
	cp	xwa, (xsp+0x4)
	jrl	z, SLDstBankList_FuncBody_Loop
	lda	xde, (0x89b7:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (0x89e1:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	jrl	SLDstBankList_FuncBody_Join3
SLDstBankList_FuncBody_Skip9:
	ld	xwa, (xsp+4)
	cp	xwa, 10
	jrl	nz, SLDstBankList_FuncBody_Loop
	cp	(0x89fa:16), 0
	jr	z, SLDstBankList_FuncBody_Helper_Skip2
	ld	a, (0x89fc:16)
	extz	wa
	div	wa, c
	extz	wa
	ld	e, (0x8a02:16)
	extz	de
	div	de, c
	extz	de
	ld	bc, de
	call	SLDstBankList_FuncBody_Helper7
	exts	xhl
	jr	SLDstBankList_FuncBody_Epilogue
SLDstBankList_FuncBody_Helper_Skip2:
	ld	a, (0x89fc:16)
	extz	wa
	ld	c, (0x8a02:16)
	extz	bc
	call	FileIO_ByteBlock_DemoProc1
	exts	xhl
SLDstBankList_FuncBody_Epilogue:
	pop	xiz
	inc	4, xsp
	ret
SLDstBankList_FuncBody_Helper2:
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xwa
	lda	xwa, (0x89a2:16)
	ld	(xwa+21), 1
	lda	xwa, (xwa+22)
	ld	c, (0x89f8:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLDstMem_HandleShow_PtrTable:24)
	ld	xbc, (xde+bc)
	inc	1, xbc
	call	FileIO_CopyString
	lda	xwa, (0x89b8:16)
	ld	xbc, SLDstBankList_FuncBody_Str_Colon_4
	call	FileIO_BuildFilePath
	lda	xiz, (0x89b8:16)
	ld	a, (0x8a04:16)
	inc	1, a
	extz	wa
	ld	bc, 0:i3
	calr	NumToAscii_FormatNumber
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_BuildFilePath
	lda	xwa, (0x89b8:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xiz, (0x89cc:16)
	ld	a, (0x8a04:16)
	extz	wa
	ld	bc, 2:i3
	ld	de, 0:i3
	calr	BuildSlotLabel
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_CopyString
	lda	xde, (0x89b7:16)
	ld	xwa, (xsp+4)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (0x89cc:16)
	ld	xwa, (xsp+4)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	pop	xiz
	inc	4, xsp
	ret
	push	xiz
	ld	xiz, xwa
	cp	xbc, EVT_INDEXSW_DOWN
	jr	z, SLDstBankList_FuncBody_Skip10
	cp	xbc, EVT_INDEXSW_UP
	jr	z, SLDstBankList_FuncBody_Skip10
	cp	xbc, EVT_PAINT
	jr	nz, SLDstBankList_FuncBody_Loop2
	lda	xwa, (0x89a2:16)
	ld (xwa+), 0
	ld	(xwa), 0
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xwa, (0x89a2:16)
	ld	(xwa+63), 3
	lda	xwa, (xwa+64)
	ld	(xwa), 0
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 0x89a2
	call	ApPostEvent
	lda	xde, (0x89e1:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	ld	xwa, xiz
	jr	SLDstBankList_FuncBody_Join5
SLDstBankList_FuncBody_Skip10:
	ld	w, (0x8a04:16)
	lda	xhl, (0x89cc:16)
	cp	xde, 8
	jr	nz, SLDstBankList_FuncBody_Skip13
	ld	xde, xbc
	cp	xde, EVT_INDEXSW_UP
	jr	nz, SLDstBankList_FuncBody_Skip11
	ld	c, w
	ld	a, w
	inc	1, a
	cp a, (SLDstBankList_FuncBody_Data_6:24)
	jr	nc, SLDstBankList_FuncBody_Skip11
	inc	1, c
	ld	(0x8a04:16), c
	ld	xwa, xiz
SLDstBankList_FuncBody_Join5:
	calr	SLDstBankList_FuncBody_Helper2
SLDstBankList_FuncBody_Loop2:
	ld	xhl, 0:i3
	jr	SLDstBankList_FuncBody_Epilogue2
SLDstBankList_FuncBody_Skip11:
	cp	xde, EVT_INDEXSW_DOWN
	jr	nz, SLDstBankList_FuncBody_Skip12
	ld	a, w
	cp	w, 0:i3
	jr	z, SLDstBankList_FuncBody_Skip12
	dec	1, a
	ld	(0x8a04:16), a
	ld	xwa, xiz
	jr	SLDstBankList_FuncBody_Join5
SLDstBankList_FuncBody_Skip12:
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	ld	xde, xhl
	jr	SLDstBankList_FuncBody_Join6
SLDstBankList_FuncBody_Skip13:
	cp	xde, 5
	jr	c, SLDstBankList_FuncBody_Skip14
	cp	xde, 7
	jr	ugt, SLDstBankList_FuncBody_Skip14
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	ld	xde, xhl
SLDstBankList_FuncBody_Join6:
	call	ApPostEvent
	jr	SLDstBankList_FuncBody_Loop2
SLDstBankList_FuncBody_Skip14:
	cp	xde, 10
	jr	nz, SLDstBankList_FuncBody_Loop2
	ld	a, (0x8a04:16)
	extz	wa
	call	SLDstBankList_FuncBody_Helper8
	exts	xhl
SLDstBankList_FuncBody_Epilogue2:
	pop	xiz
	ret
SLDstBankList_FuncBody_Helper3:
	dec	2, xsp
	push	xiz
	ld	(xsp+4), c
	ld	xiz, xwa
	lda	xwa, (0x89a2:16)
	ld (xwa+), 0
	ld	c, (0x89f8:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLDstBank_HandleShow_PtrTable:24)
	ld	xbc, (xde+bc)
	inc	1, xbc
	call	FileIO_CopyString
	lda	xwa, (0x89a3:16)
	ld	xbc, SLDstBankList_FuncBody_Str_Colon_5
	call	FileIO_BuildFilePath
	lda	xwa, (0x89a3:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xwa, (0x89b7:16)
	ld	c, (0x8a06:16)
	extz	bc
	div	bc, (xsp+0x4)
	extz	bc
	ld	de, 1:i3
	calr	WP_GetPresetName1
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 0x89a2
	call	ApPostEvent
	lda	xde, (0x89b7:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	pop	xiz
	inc	2, xsp
	ret
SLDstBankList_FuncBody_Helper4:
	dec	6, xsp
	push	xiz
	ld	(xsp+4), c
	ld	(xsp+6), xwa
	lda	xwa, (0x89a2:16)
	ld	(xwa+42), 2
	lda	xwa, (xwa+43)
	ld	c, (0x89f8:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLDstMem_HandleShow_PtrTable:24)
	ld	xbc, (xde+bc)
	inc	1, xbc
	call	FileIO_CopyString
	lda	xwa, (0x89cd:16)
	ld	xbc, SLDstBankList_FuncBody_Str_Colon_6
	call	FileIO_BuildFilePath
	cp	(0x89fa:16), 0
	jr	nz, SLDstBankList_FuncBody_Helper4_Skip
	lda	xiz, (0x89cd:16)
	ld	a, (0x8a06:16)
	extz	wa
	div	wa, (xsp+0x4)
	ld	a, w
	extz	wa
	calr	WP_GetPresetPtr
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_BuildFilePath
SLDstBankList_FuncBody_Helper4_Skip:
	lda	xwa, (0x89cd:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xbc, (0x89a2:16)
	lda	xwa, (xbc+63)
	cp	(0x89fa:16), 0
	jr	z, SLDstBankList_FuncBody_Helper4_Skip2
	ld	(xwa), 3
	lda	xwa, (xbc+64)
	ld	xbc, SLDstBankList_FuncBody_Str_ALL
	call	FileIO_CopyString
	jr	SLDstBankList_FuncBody_Helper4_Join
SLDstBankList_FuncBody_Helper4_Skip2:
	ld	e, (0x8a06:16)
	ld	c, e
	extz	bc
	div	bc, (xsp+0x4)
	extz	bc
	extz	de
	div	de, (xsp+0x4)
	ld	e, d
	extz	de
	pushw	3
	calr	WP_GetBankMemName
SLDstBankList_FuncBody_Helper4_Join:
	lda	xde, (0x89cc:16)
	ld	xwa, (xsp+6)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (0x89e1:16)
	ld	xwa, (xsp+6)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	pop	xiz
	inc	6, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xde
	ld	xde, xbc
	ld	xiz, xwa
	ld	c, (SLDstBankList_FuncBody_Data_2:24)
	cp	xde, EVT_INDEXSW_DOWN
	jr	z, SLDstBankList_FuncBody_Skip15
	cp	xde, EVT_INDEXSW_UP
	jr	z, SLDstBankList_FuncBody_Skip15
	cp	xde, EVT_PAINT
	jrl	nz, SLDstBankList_FuncBody_Loop3
	ld	xwa, xiz
	calr	SLDstBankList_FuncBody_Helper3
	ld	c, (SLDstBankList_FuncBody_Data_2:24)
	ld	xwa, xiz
	calr	SLDstBankList_FuncBody_Helper4
	ld	xwa, 0:i3
	ld	(0x81e8:16), xwa
	jrl	SLDstBankList_FuncBody_Loop3
SLDstBankList_FuncBody_Skip15:
	ld	l, (0x8a06:16)
	ld	xwa, (xsp+4)
	cp	xwa, 7
	jrl	nz, SLDstBankList_FuncBody_Skip18
	ld	xix, xde
	cp	xde, EVT_INDEXSW_UP
	jr	nz, SLDstBankList_FuncBody_Skip16
	ld	e, (SLDstBankList_FuncBody_Data_2:24)
	ld	a, e
	ld	c, l
	add	a, l
	cp a, (SLDstBankList_FuncBody_Data_7:24)
	jr	nc, SLDstBankList_FuncBody_Skip16
	add	c, e
	ld	(0x8a06:16), c
	ld	c, (SLDstBankList_FuncBody_Data_2:24)
	ld	xwa, xiz
	calr	SLDstBankList_FuncBody_Helper3
	ld	c, (SLDstBankList_FuncBody_Data_2:24)
	ld	xwa, xiz
	jr	SLDstBankList_FuncBody_Join7
SLDstBankList_FuncBody_Skip16:
	cp	xix, EVT_INDEXSW_DOWN
	jr	nz, SLDstBankList_FuncBody_Skip17
	ld	a, l
	ld	c, (SLDstBankList_FuncBody_Data_2:24)
	cp	l, c
	jr	c, SLDstBankList_FuncBody_Skip17
	sub	a, c
	ld	(0x8a06:16), a
	ld	c, (SLDstBankList_FuncBody_Data_2:24)
	ld	xwa, xiz
	calr	SLDstBankList_FuncBody_Helper3
	ld	c, (SLDstBankList_FuncBody_Data_2:24)
	ld	xwa, xiz
SLDstBankList_FuncBody_Join7:
	calr	SLDstBankList_FuncBody_Helper4
SLDstBankList_FuncBody_Skip17:
	ld	xwa, (0x81e8:16)
	cp	xwa, (xsp+0x4)
	jr	z, SLDstBankList_FuncBody_Loop3
	lda	xde, (0x89b7:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (0x89e1:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
SLDstBankList_FuncBody_Join8:
	call	ApPostEvent
	ld	xwa, (xsp+4)
	ld	(0x81e8:16), xwa
SLDstBankList_FuncBody_Loop3:
	ld	xhl, 0:i3
	jrl	SLDstBankList_FuncBody_Epilogue3
SLDstBankList_FuncBody_Skip18:
	ld	xwa, (xsp+4)
	cp	xwa, 8
	jrl	nz, SLDstBankList_FuncBody_Skip21
	ld	xix, xde
	cp	xde, EVT_INDEXSW_UP
	jr	nz, SLDstBankList_FuncBody_Skip19
	ld	c, l
	ld	a, l
	inc	1, a
	cp a, (SLDstBankList_FuncBody_Data_7:24)
	jr	nc, SLDstBankList_FuncBody_Skip19
	ld	e, (SLDstBankList_FuncBody_Data_2:24)
	ld	l, e
	ld	a, c
	extz	wa
	div	wa, l
	ld	a, w
	inc	1, a
	cp	a, e
	jr	nc, SLDstBankList_FuncBody_Skip20
	inc	1, c
	ld	(0x8a06:16), c
	ld	c, (SLDstBankList_FuncBody_Data_2:24)
	ld	xwa, xiz
	jr	SLDstBankList_FuncBody_Join9
SLDstBankList_FuncBody_Skip19:
	cp	xix, EVT_INDEXSW_DOWN
	jr	nz, SLDstBankList_FuncBody_Skip20
	ld	c, l
	cp	l, 0:i3
	jr	z, SLDstBankList_FuncBody_Skip20
	ld	e, (SLDstBankList_FuncBody_Data_2:24)
	ld	a, c
	extz	wa
	div	wa, e
	ld	a, w
	cp	a, 0:i3
	jr	z, SLDstBankList_FuncBody_Skip20
	dec	1, c
	ld	(0x8a06:16), c
	ld	c, (SLDstBankList_FuncBody_Data_2:24)
	ld	xwa, xiz
SLDstBankList_FuncBody_Join9:
	calr	SLDstBankList_FuncBody_Helper4
SLDstBankList_FuncBody_Skip20:
	ld	xwa, (0x81e8:16)
	cp	xwa, (xsp+0x4)
	jrl	z, SLDstBankList_FuncBody_Loop3
	lda	xde, (0x89b7:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (0x89e1:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	jrl	SLDstBankList_FuncBody_Join8
SLDstBankList_FuncBody_Skip21:
	ld	xwa, (xsp+4)
	cp	xwa, 5
	jr	z, SLDstBankList_FuncBody_Skip22
	cp	xwa, 6
	jr	nz, SLDstBankList_FuncBody_Skip23
SLDstBankList_FuncBody_Skip22:
	ld	xwa, (0x81e8:16)
	cp	xwa, (xsp+0x4)
	jrl	z, SLDstBankList_FuncBody_Loop3
	lda	xde, (0x89b7:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (0x89e1:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	jrl	SLDstBankList_FuncBody_Join8
SLDstBankList_FuncBody_Skip23:
	ld	xwa, (xsp+4)
	cp	xwa, 10
	jrl	nz, SLDstBankList_FuncBody_Loop3
	cp	(0x89fa:16), 0
	jr	z, SLDstBankList_FuncBody_Helper4_Skip3
	ld	a, (0x89fe:16)
	extz	wa
	div	wa, c
	add	a, 30
	extz	wa
	ld	e, (0x8a06:16)
	extz	de
	div	de, c
	add	e, 30
	extz	de
	ld	bc, de
	jr	SLDstBankList_FuncBody_Join10
SLDstBankList_FuncBody_Helper4_Skip3:
	ld	a, (0x89fe:16)
	extz	wa
	ld	c, (0x8a06:16)
	extz	bc
SLDstBankList_FuncBody_Join10:
	call	SLDstBankList_FuncBody_Helper9
	exts	xhl
SLDstBankList_FuncBody_Epilogue3:
	pop	xiz
	inc	4, xsp
	ret
SLDstBankList_FuncBody_Helper5:
	dec	6, xsp
	ld	(xsp), c
	ld	(xsp+2), xwa
	lda	xwa, (0x89a2:16)
	ld (xwa+), 0
	ld	c, (0x89f8:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLDstBank_HandleShow_PtrTable:24)
	ld	xbc, (xde+bc)
	inc	1, xbc
	call	FileIO_CopyString
	lda_d16	xwa, (0x89a3)
	ld	xbc, Data_SaveLoadMenuTable
	call	FileIO_BuildFilePath
	lda	xwa, (0x89a3:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	ld	e, (xsp)
	add	e, (xsp)
	ld	c, (0x8a08:16)
	lda	xwa, (0x89b7:16)
	cp	c, e
	jr	nc, SLDstBankList_FuncBody_Helper5_Skip
	extz	bc
	div	bc, (xsp)
	extz	bc
	ld	de, 1:i3
	calr	WP_GetPresetName3
	jr	SLDstBankList_FuncBody_Join11
SLDstBankList_FuncBody_Helper5_Skip:
	ld	bc, 1:i3
	calr	WP_GetUserName2
SLDstBankList_FuncBody_Join11:
	ld	xwa, (xsp+2)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 0x89a2
	call	ApPostEvent
	lda	xde, (0x89b7:16)
	ld	xwa, (xsp+2)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	inc	6, xsp
	ret
SLDstBankList_FuncBody_Helper6:
	dec	6, xsp
	push	xiz
	ld	(xsp+4), c
	ld	(xsp+6), xwa
	lda	xde, (SLDstMem_HandleShow_PtrTable:24)
	cp	(0x89fa:16), 0
	jr	z, SLDstBankList_FuncBody_Helper6_Skip
	lda	xwa, (0x89a2:16)
	ld	(xwa+42), 2
	lda	xwa, (xwa+43)
	ld	c, (0x89f8:16)
	extz	bc
	sla	bc, 2
	ld	xbc, (xde+bc)
	inc	1, xbc
	call	FileIO_CopyString
	lda	xwa, (0x89cd:16)
	ld	xbc, SLDstBankList_FuncBody_Str_Colon_7
	call	FileIO_BuildFilePath
	lda	xwa, (0x89cd:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xwa, (0x89a2:16)
	ld	(xwa+63), 3
	lda	xwa, (xwa+64)
	ld	xbc, SLDstBankList_FuncBody_Str_ALL_2
	call	FileIO_CopyString
	jrl	SLDstBankList_FuncBody_Helper6_Join
SLDstBankList_FuncBody_Helper6_Skip:
	ld	l, (xsp+4)
	add	l, (xsp+0x4)
	lda	xbc, (0x89a2:16)
	lda	xwa, (xbc+43)
	ld	(xbc+42), 2
	cp	(0x8a08:16), l
	jr	c, SLDstBankList_FuncBody_Helper6_Skip2
	ld	c, (0x89f8:16)
	extz	bc
	sla	bc, 2
	ld	xbc, (xde+bc)
	inc	1, xbc
	call	FileIO_CopyString
	lda	xwa, (0x89cd:16)
	ld	xbc, SLDstBankList_FuncBody_Str_Colon_8
	call	FileIO_BuildFilePath
	lda	xiz, (0x89cd:16)
	ld	c, (xsp+4)
	add	c, (xsp+0x4)
	ld	a, (0x8a08:16)
	sub	a, c
	inc	1, a
	extz	wa
	ld	bc, 0:i3
	calr	NumToAscii_FormatNumber
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_BuildFilePath
	lda	xwa, (0x89cd:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xwa, (0x89e1:16)
	ld	e, (xsp+4)
	add	e, (xsp+0x4)
	ld	c, (0x8a08:16)
	sub	c, e
	extz	bc
	ld	de, 3:i3
	calr	WP_GetUserName3
	jr	SLDstBankList_FuncBody_Helper6_Join
SLDstBankList_FuncBody_Helper6_Skip2:
	ld	c, (0x89f8:16)
	extz	bc
	sla	bc, 2
	ld	xbc, (xde+bc)
	inc	1, xbc
	call	FileIO_CopyString
	lda	xwa, (0x89cd:16)
	ld	xbc, SLDstBankList_FuncBody_Data_3
	call	FileIO_BuildFilePath
	lda	xiz, (0x89cd:16)
	ld	a, (0x8a08:16)
	extz	wa
	div	wa, (xsp+0x4)
	ld	a, w
	inc	1, a
	extz	wa
	ld	bc, 0:i3
	calr	NumToAscii_FormatNumber
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_BuildFilePath
	lda	xwa, (0x89cd:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xwa, (0x89e1:16)
	ld	c, (0x8a08:16)
	extz	bc
	ld	de, 3:i3
	calr	WP_GetUserName1
SLDstBankList_FuncBody_Helper6_Join:
	lda	xde, (0x89cc:16)
	ld	xwa, (xsp+6)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (0x89e1:16)
	ld	xwa, (xsp+6)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	pop	xiz
	inc	6, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xde
	ld	xiz, xwa
	ld	e, (SLDstBankList_FuncBody_Data_4:24)
	cp	xbc, EVT_INDEXSW_DOWN
	jr	z, SLDstBankList_FuncBody_Skip24
	cp	xbc, EVT_INDEXSW_UP
	jr	z, SLDstBankList_FuncBody_Skip24
	cp	xbc, EVT_PAINT
	jrl	nz, SLDstBankList_FuncBody_Loop4
	ld	xwa, xiz
	ld	c, e
	calr	SLDstBankList_FuncBody_Helper5
	ld	c, (SLDstBankList_FuncBody_Data_4:24)
	ld	xwa, xiz
	calr	SLDstBankList_FuncBody_Helper6
	ld	xwa, 0:i3
	ld	(0x81ec:16), xwa
	jrl	SLDstBankList_FuncBody_Loop4
SLDstBankList_FuncBody_Skip24:
	ld	l, (0x8a08:16)
	ld	xwa, (xsp+4)
	cp	xwa, 7
	jrl	nz, SLDstBankList_FuncBody_Skip29
	ld	xde, xbc
	cp	xbc, EVT_INDEXSW_UP
	jr	nz, SLDstBankList_FuncBody_Skip26
	ld	c, (SLDstBankList_FuncBody_Data_4:24)
	ld	w, c
	add	w, c
	ld	a, l
	cp	l, w
	jr	nc, SLDstBankList_FuncBody_Skip26
	cp	a, c
	jr	nc, SLDstBankList_FuncBody_Skip25
	add	a, c
	ld	(0x8a08:16), a
	jr	SLDstBankList_FuncBody_Join12
SLDstBankList_FuncBody_Skip25:
	ld	(0x8a08:16), w
SLDstBankList_FuncBody_Join12:
	ld	c, (SLDstBankList_FuncBody_Data_4:24)
	ld	xwa, xiz
	calr	SLDstBankList_FuncBody_Helper5
	ld	c, (SLDstBankList_FuncBody_Data_4:24)
	ld	xwa, xiz
	calr	SLDstBankList_FuncBody_Helper6
	ld	c, (SLDstBankList_FuncBody_Data_4:24)
	pushw	0
	pushw	0x8a08
	ld	xwa, (xsp+8)
	ld	xde, 0x8a00
	jr	SLDstBankList_FuncBody_Join14
SLDstBankList_FuncBody_Skip26:
	cp	xde, EVT_INDEXSW_DOWN
	jr	nz, SLDstBankList_FuncBody_Skip28
	ld	c, l
	ld	e, (SLDstBankList_FuncBody_Data_4:24)
	cp	l, e
	jr	c, SLDstBankList_FuncBody_Skip28
	ld	a, e
	add	a, e
	cp	c, a
	jr	nc, SLDstBankList_FuncBody_Skip27
	sub	c, e
	ld	(0x8a08:16), c
	jr	SLDstBankList_FuncBody_Join13
SLDstBankList_FuncBody_Skip27:
	cp	c, a
	jr	c, SLDstBankList_FuncBody_Join13
	ld	(0x8a08:16), e
SLDstBankList_FuncBody_Join13:
	ld	c, (SLDstBankList_FuncBody_Data_4:24)
	ld	xwa, xiz
	calr	SLDstBankList_FuncBody_Helper5
	ld	c, (SLDstBankList_FuncBody_Data_4:24)
	ld	xwa, xiz
	calr	SLDstBankList_FuncBody_Helper6
	ld	c, (SLDstBankList_FuncBody_Data_4:24)
	pushw	0
	pushw	0x8a08
	ld	xwa, (xsp+8)
	ld	xde, 0x8a00
SLDstBankList_FuncBody_Join14:
	calr	SLSrcBankList_FuncBody_Helper7
SLDstBankList_FuncBody_Skip28:
	ld	xwa, (0x81ec:16)
	cp	xwa, (xsp+0x4)
	jr	z, SLDstBankList_FuncBody_Loop4
	lda	xde, (0x89b7:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (0x89e1:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
SLDstBankList_FuncBody_Join15:
	call	ApPostEvent
	ld	xwa, (xsp+4)
	ld	(0x81ec:16), xwa
SLDstBankList_FuncBody_Loop4:
	ld	xhl, 0:i3
	jrl	SLDstBankList_FuncBody_Epilogue4
SLDstBankList_FuncBody_Skip29:
	ld	xwa, (xsp+4)
	cp	xwa, 8
	jrl	nz, SLDstBankList_FuncBody_Skip34
	ld	xde, xbc
	cp	xbc, EVT_INDEXSW_UP
	jr	nz, SLDstBankList_FuncBody_Skip31
	ld	c, l
	ld	a, l
	inc	1, a
	cp	a, (SLDstBankList_FuncBody_Data_8:24)
	jr	nc, SLDstBankList_FuncBody_Skip31
	ld	e, (SLDstBankList_FuncBody_Data_4:24)
	ld	a, e
	add	a, e
	cp	c, a
	jr	nc, SLDstBankList_FuncBody_Skip30
	ld	l, e
	ld	a, c
	extz	wa
	div	wa, l
	ld	a, w
	inc	1, a
	cp	a, e
	jrl	nc, SLDstBankList_FuncBody_Skip33
	inc	1, c
	ld	(0x8a08:16), c
	ld	c, (SLDstBankList_FuncBody_Data_4:24)
	ld	xwa, xiz
	calr	SLDstBankList_FuncBody_Helper6
	ld	c, (SLDstBankList_FuncBody_Data_4:24)
	pushw	0
	pushw	0x8a08
	ld	xwa, (xsp+8)
	ld	xde, 0x8a00
	jrl	SLDstBankList_FuncBody_Join16
SLDstBankList_FuncBody_Skip30:
	inc	1, c
	ld	(0x8a08:16), c
	ld	c, (SLDstBankList_FuncBody_Data_4:24)
	ld	xwa, xiz
	calr	SLDstBankList_FuncBody_Helper6
	ld	c, (SLDstBankList_FuncBody_Data_4:24)
	pushw	0
	pushw	0x8a08
	ld	xwa, (xsp+8)
	ld	xde, 0x8a00
	jr	SLDstBankList_FuncBody_Join16
SLDstBankList_FuncBody_Skip31:
	cp	xde, EVT_INDEXSW_DOWN
	jr	nz, SLDstBankList_FuncBody_Skip33
	ld	c, l
	cp	l, 0:i3
	jr	z, SLDstBankList_FuncBody_Skip33
	ld	e, (SLDstBankList_FuncBody_Data_4:24)
	ld	a, e
	add	a, e
	cp	c, a
	jr	nc, SLDstBankList_FuncBody_Skip32
	ld	a, c
	extz	wa
	div	wa, e
	ld	a, w
	cp	a, 0:i3
	jr	z, SLDstBankList_FuncBody_Skip33
	dec	1, c
	ld	(0x8a08:16), c
	ld	c, (SLDstBankList_FuncBody_Data_4:24)
	ld	xwa, xiz
	calr	SLDstBankList_FuncBody_Helper6
	ld	c, (SLDstBankList_FuncBody_Data_4:24)
	pushw	0
	pushw	0x8a08
	ld	xwa, (xsp+8)
	ld	xde, 0x8a00
	jr	SLDstBankList_FuncBody_Join16
SLDstBankList_FuncBody_Skip32:
	cp	c, a
	jr	ule, SLDstBankList_FuncBody_Skip33
	dec	1, c
	ld	(0x8a08:16), c
	ld	c, (SLDstBankList_FuncBody_Data_4:24)
	ld	xwa, xiz
	calr	SLDstBankList_FuncBody_Helper6
	ld	c, (SLDstBankList_FuncBody_Data_4:24)
	pushw	0
	pushw	0x8a08
	ld	xwa, (xsp+8)
	ld	xde, 0x8a00
SLDstBankList_FuncBody_Join16:
	calr	SLSrcBankList_FuncBody_Helper7
SLDstBankList_FuncBody_Skip33:
	ld	xwa, (0x81ec:16)
	cp	xwa, (xsp+0x4)
	jrl	z, SLDstBankList_FuncBody_Loop4
	lda	xde, (0x89b7:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (0x89e1:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	jrl	SLDstBankList_FuncBody_Join15
SLDstBankList_FuncBody_Skip34:
	ld	xwa, (xsp+4)
	cp	xwa, 5
	jr	z, SLDstBankList_FuncBody_Skip35
	cp	xwa, 6
	jr	nz, SLDstBankList_FuncBody_Skip36
SLDstBankList_FuncBody_Skip35:
	ld	xwa, (0x81ec:16)
	cp	xwa, (xsp+0x4)
	jrl	z, SLDstBankList_FuncBody_Loop4
	lda	xde, (0x89b7:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (0x89e1:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	jrl	SLDstBankList_FuncBody_Join15
SLDstBankList_FuncBody_Skip36:
	ld	xwa, (xsp+4)
	cp	xwa, 10
	jrl	nz, SLDstBankList_FuncBody_Loop4
	cp	(0x89fa:16), 0
	jr	z, SLDstBankList_FuncBody_Helper6_Skip3
	ld	a, (0x8a00:16)
	extz	wa
	div	wa, e
	extz	wa
	ld	c, (0x8a08:16)
	extz	bc
	div	bc, e
	extz	bc
	call	SLDstBankList_FuncBody_Helper11
	exts	xhl
	jr	SLDstBankList_FuncBody_Epilogue4
SLDstBankList_FuncBody_Helper6_Skip3:
	ld	a, (0x8a00:16)
	extz	wa
	ld	c, (0x8a08:16)
	extz	bc
	call	SLDstBankList_FuncBody_Helper10
	exts	xhl
SLDstBankList_FuncBody_Epilogue4:
	pop	xiz
	inc	4, xsp
	ret
CmpDst_HandleShow_PtrTable_Target0:
	dec	4, xsp
	pushw	iz
	ld	(xsp+2), xwa
	cp	xbc, EVT_PAINT
	jr	nz, SLDstBankList_FuncBody_Skip37
	ld	iz, 0:i3
SLDstBankList_FuncBody_Loop5:
	ld	de, iz
	mul	de, 21
	lda	xbc, (0x89a2:16)
	ld	hl, de
	extz	xhl
	add	xhl, xbc
	ldto_berp a, 248
	ld	(xhl), a
	ld	wa, 1:i3
	add	wa, de
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 0
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	ld	de, iz
	mul	de, 21
	lda	xwa, (0x89a2:16)
	extz	xde
	add	xde, xwa
	ld	xwa, (xsp+2)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	inc	1, iz
	cp	iz, 4:i3
	jr	c, SLDstBankList_FuncBody_Loop5
SLDstBankList_FuncBody_Skip37:
	ld	xhl, 0:i3
	popw	iz
	inc	4, xsp
	ret

SingleLoadDstFunc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xbc
	ld xiz, xwa
	ld xwa, (xsp + 8)
	cp xwa, EVT_GET_SELECTED_FILE_NUMBER
	jrl z, SLDst_ReturnCapture
	cp xwa, EVT_INDEXSW_DOWN
	jrl z, SLDst_HandleScroll
	cp xwa, EVT_INDEXSW_UP
	jrl z, SLDst_HandleScroll
	cp xwa, EVT_PARA_DRAW
	jrl z, SLDst_HandleConfirm
	cp xwa, EVT_PAINT
	jr z, SLDst_HandleShow
	cp xwa, EVT_PS_FILE_NAME_BOX_ID
	jr nz, SLDst_Return
	ld xwa, (xsp + 4)
	ld (0x81f0:16), xwa
	ld wa, 0:i3
	calr InitializeOperationState
	calr SignalProgressUpdate
	calr WP_ScanAvailability
	calr SignalProgressUpdate
	cp (0x89f8:16), 1
	jr z, SLDst_ShowHide_Internal
	ld xwa, 0x61004a
	ld xbc, EVT_SET_VISIBLE
	ld xde, 1:i3
	jr SLDst_ShowHide_Dispatch

SLDst_ShowHide_Internal:
	ld xwa, 0x61004a
	ld xbc, EVT_SET_VISIBLE
	ld xde, 0:i3

SLDst_ShowHide_Dispatch:
	call ApPostEvent
	ld xwa, (0x81f0:16)
	ld xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld xde, 0xffffffff
	call ApPostEvent
	cp (0x89f8:16), 0
	jr nz, SLDst_ClearFloppyFlag
	call FileIO_ValidateWithExtHeader
	cp hl, 0:i3
	jr z, SLDst_ClearFloppyFlag
	ld (0x8a0a:16), 1
	jr SLDst_Return

SLDst_ClearFloppyFlag:
	ld (0x8a0a:16), 0

SLDst_Return:
	ld xhl, 0:i3
	jrl SLDst_Epilogue

SLDst_HandleShow:
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	calr SingleLoadModeFunc
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	calr SingleLoadSrcBankFunc
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	calr SingleLoadSrcMemFunc
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	calr SingleLoadDstBankFunc
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	calr SingleLoadDstMemFunc
	ld xwa, (0x81f0:16)
	ld xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld xde, 0xffffffff
	call ApPostEvent
	ld xwa, 0x610036
	ld xbc, EVT_SET_PARAM
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, (0x81f0:16)
	ld c, (0x89f8:16)
	extz bc
	sla bc, 2
	lda xde, (SLDst_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl SLDst_Return

SLDst_HandleConfirm:
	ld xwa, (0x81f0:16)
	ld xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld xde, 0xffffffff
	call ApPostEvent
	ld xwa, (0x81f0:16)
	ld c, (0x89f8:16)
	extz bc
	sla bc, 2
	lda xde, (SLDst_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	ld xhl, (xhl)
	call (xhl)
	jrl SLDst_Return

SLDst_HandleScroll:
	ld xwa, (xsp + 4)
	cp xwa, 0x3
	jr nz, SLDst_ScrollMode4
	cp (0x89f8:16), 1
	jr z, SLDst_ScrollMode4
	ld xwa, (xsp + 8)
	cp xwa, EVT_INDEXSW_UP
	scc8 z, a
	ld (0x89fa:16), a
	ld xwa, xiz
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	calr SingleLoadSrcMemFunc
	ld xwa, xiz
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	calr SingleLoadDstMemFunc
	ld xwa, (0x81f0:16)
	ld xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld xde, 0xffffffff
	call ApPostEvent
	ld xwa, 0x610036
	ld xbc, EVT_SET_PARAM
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, (0x81f0:16)
	ld c, (0x89f8:16)
	extz bc
	sla bc, 2
	lda xde, (SLDst_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	ld xhl, (xhl)
	call (xhl)
	ld xwa, xiz
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	jrl SLDst_ScrollMode3_CallSrcMem

SLDst_ScrollMode4:
	ld xwa, (xsp + 4)
	cp xwa, 0x4
	jrl nz, SLDst_ScrollDispatch
	calr WP_FindNextSlot
	cp l, 0:i3
	jrl z, SLDst_Return
	cp (0x89f8:16), 1
	jr z, SLDst_ScrollMode4_Internal
	ld xwa, 0x61004a
	ld xbc, EVT_SET_VISIBLE
	ld xde, 1:i3
	jr SLDst_ScrollMode4_Dispatch

SLDst_ScrollMode4_Internal:
	ld xwa, 0x61004a
	ld xbc, EVT_SET_VISIBLE
	ld xde, 0:i3

SLDst_ScrollMode4_Dispatch:
	call ApPostEvent
	ld xwa, xiz
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	calr SingleLoadModeFunc
	ld xwa, xiz
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	calr SingleLoadSrcBankFunc
	ld xwa, xiz
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	calr SingleLoadSrcMemFunc
	ld xwa, xiz
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	calr SingleLoadDstBankFunc
	ld xwa, xiz
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	calr SingleLoadDstMemFunc
	ld xwa, (0x81f0:16)
	ld xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld xde, 0xffffffff
	call ApPostEvent
	ld xwa, 0x610036
	ld xbc, EVT_SET_PARAM
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, (0x81f0:16)
	ld c, (0x89f8:16)
	extz bc
	sla bc, 2
	lda xde, (SLDst_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	ld xhl, (xhl)
	call (xhl)
	ld xwa, xiz
	ld xbc, EVT_PAINT
	ld xde, 0:i3

SLDst_ScrollMode3_CallSrcMem:
	calr SingleLoadSrcFunc
	jrl SLDst_Return

SLDst_ScrollDispatch:
	ld xwa, (xsp + 4)
	cp xwa, 0xa
	jr nz, SLDst_Scroll_ChildReturn
	cp (0x89f8:16), 4
	jr z, SLDst_Scroll_ChildReturn
	ld xwa, 0x600026
	ld xbc, EVT_SHOW
	ld xde, 5:i3
	call ApPostEvent
	ld wa, 0:i3
	calr InitializeOperationState
	ld xwa, (0x81f0:16)
	ld c, (0x89f8:16)
	extz bc
	sla bc, 2
	lda xde, (SLDst_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xix, (xhl)
	call (xix)
	ld wa, hl
	ld bc, 1:i3
	calr FileIO_ValidateSignedValue
	ld (0x7f42:16), l
	ld xwa, 0x600026
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	ldw wa, 0xee
	call SoundCtrl_SendCommand
	jrl SLDst_Return

SLDst_Scroll_ChildReturn:
	ld xwa, (xsp + 4)
	cp xwa, 0x7
	jr nz, SLDst_Scroll_SubMode2
	cp (0x89f8:16), 1
	jr z, SLDst_Scroll_SubMode
	ld xwa, (0x81f0:16)
	ld xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld xde, 1:i3
	call ApPostEvent
	ld xwa, (0x81f0:16)
	ld c, (0x89f8:16)
	extz bc
	sla bc, 2
	lda xde, (SLDst_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl SLDst_Return

SLDst_Scroll_SubMode:
	ld xwa, (0x81f0:16)
	ld xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld xde, 0xffffffff
	call ApPostEvent
	ld xwa, (0x81f0:16)
	ld c, (0x89f8:16)
	extz bc
	sla bc, 2
	lda xde, (SLDst_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl SLDst_Return

SLDst_Scroll_SubMode2:
	ld xwa, (0x81f0:16)
	ld xbc, (xsp + 4)
	cp xbc, 0x8
	jrl nz, SLDst_Scroll_SubMode5
	cp (0x89f8:16), 1
	jr nz, SLDst_Scroll_SubMode3
	ld xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld xde, 2:i3
	call ApPostEvent
	ld xwa, (0x81f0:16)
	ld c, (0x89f8:16)
	extz bc
	sla bc, 2
	lda xde, (SLDst_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl SLDst_Return

SLDst_Scroll_SubMode3:
	cp (0x89fa:16), 0
	jr nz, SLDst_Scroll_SubMode4
	ld xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld xde, 3:i3
	call ApPostEvent
	ld xwa, (0x81f0:16)
	ld c, (0x89f8:16)
	extz bc
	sla bc, 2
	lda xde, (SLDst_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl SLDst_Return

SLDst_Scroll_SubMode4:
	ld xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld xde, 0xffffffff
	call ApPostEvent
	ld xwa, (0x81f0:16)
	ld c, (0x89f8:16)
	extz bc
	sla bc, 2
	lda xde, (SLDst_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl SLDst_Return

SLDst_Scroll_SubMode5:
	ld xbc, (xsp + 4)
	cp xbc, 0x5
	jr nz, SLDst_Scroll_SubMode6
	ld xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld xde, 0xffffffff
	call ApPostEvent
	ld xwa, (0x81f0:16)
	ld c, (0x89f8:16)
	extz bc
	sla bc, 2
	lda xde, (SLDst_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl SLDst_Return

SLDst_Scroll_SubMode6:
	ld xbc, (xsp + 4)
	cp xbc, 0x6
	jrl nz, SLDst_Return
	ld xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld xde, 0xffffffff
	call ApPostEvent
	ld xwa, (0x81f0:16)
	ld c, (0x89f8:16)
	extz bc
	sla bc, 2
	lda xde, (SLDst_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl SLDst_Return

SLDst_ReturnCapture:
	ld xhl, 0xffffffff

SLDst_Epilogue:
	pop xiz
	inc 8, xsp
	ret

CmpSingleLoadSrcFunc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	cp xiz, EVT_GET_SELECTED_FILE_NUMBER
	jrl z, CmpSrc_ReturnCapture
	cp xiz, EVT_INDEXSW_DOWN
	jr z, CmpSrc_HandleScroll
	cp xiz, EVT_INDEXSW_UP
	jr z, CmpSrc_HandleScroll
	cp xiz, EVT_PAINT
	jr z, CmpSrc_HandleShow
	cp xiz, EVT_PS_FILE_NAME_BOX_ID
	jrl nz, CmpSrc_Return
	ld xwa, (xsp + 4)
	ld (0x81f4:16), xwa
	ld xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld xde, 0xffffffff
	call ApPostEvent
	jrl CmpSrc_Return

CmpSrc_HandleShow:
	ld xwa, (0x81f4:16)
	ld xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld xde, 0xffffffff
	call ApPostEvent
	ld xwa, (0x81f4:16)
	ld c, (0x89f8:16)
	extz bc
	sla bc, 2
	lda xde, (CmpSrc_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld xbc, xiz
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl CmpSrc_Return

CmpSrc_HandleScroll:
	ld xwa, (xsp + 4)
	cp xwa, 0x5
	jr nz, CmpSrc_ScrollMode6
	ld xwa, (0x81f4:16)
	ld xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld xde, 1:i3
	call ApPostEvent
	ld xwa, (0x81f4:16)
	ld c, (0x89f8:16)
	extz bc
	sla bc, 2
	lda xde, (CmpSrc_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld xbc, xiz
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl CmpSrc_Return

CmpSrc_ScrollMode6:
	ld xwa, (xsp + 4)
	cp xwa, 0x6
	jr nz, CmpSrc_ScrollMode7
	cp (0x89fa:16), 0
	jr nz, CmpSrc_ScrollMode6_NoStep
	ld xwa, (0x81f4:16)
	ld xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld xde, 3:i3
	call ApPostEvent
	ld xwa, (0x81f4:16)
	ld c, (0x89f8:16)
	extz bc
	sla bc, 2
	lda xde, (CmpSrc_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld xbc, xiz
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl CmpSrc_Return

CmpSrc_ScrollMode6_NoStep:
	ld xwa, (0x81f4:16)
	ld xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld xde, 0xffffffff
	call ApPostEvent
	ld xwa, (0x81f4:16)
	ld c, (0x89f8:16)
	extz bc
	sla bc, 2
	lda xde, (CmpSrc_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld xbc, xiz
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl CmpSrc_Return

CmpSrc_ScrollMode7:
	ld xwa, (0x81f4:16)
	ld xbc, (xsp + 4)
	cp xbc, 0x7
	jr nz, CmpSrc_ScrollMode8
	ld xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld xde, 0xffffffff
	call ApPostEvent
	ld xwa, (0x81f4:16)
	ld c, (0x89f8:16)
	extz bc
	sla bc, 2
	lda xde, (CmpSrc_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld xbc, xiz
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jr CmpSrc_Return

CmpSrc_ScrollMode8:
	ld xbc, (xsp + 4)
	cp xbc, 0x8
	jr nz, CmpSrc_ScrollMode40
	cp (0x89fa:16), 0
	jr nz, CmpSrc_ScrollMode40
	ld xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld xde, 0xffffffff
	call ApPostEvent
	ld xwa, (0x81f4:16)
	ld c, (0x89f8:16)
	extz bc
	sla bc, 2
	lda xde, (CmpSrc_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld xbc, xiz
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jr CmpSrc_Return

CmpSrc_ScrollMode40:
	ld xbc, (xsp + 4)
	cp xbc, 0x28
	jr nz, CmpSrc_Return
	ld c, (0x89f8:16)
	extz bc
	sla bc, 2
	lda xde, (CmpSrc_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld xbc, xiz
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)

CmpSrc_Return:
	ld xhl, 0:i3
	jr CmpSrc_Epilogue

CmpSrc_ReturnCapture:
	ld xhl, 0xffffffff

CmpSrc_Epilogue:
	pop xiz
	inc 4, xsp
	ret

CmpSingleLoadDstFunc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xbc
	ld xiz, xwa
	ld xwa, (xsp + 8)
	cp xwa, EVT_GET_SELECTED_FILE_NUMBER
	jrl z, CmpDst_ReturnCapture
	cp xwa, EVT_INDEXSW_DOWN
	jrl z, CmpDst_HandleScroll
	cp xwa, EVT_INDEXSW_UP
	jrl z, CmpDst_HandleScroll
	cp xwa, EVT_PAINT
	jr z, CmpDst_HandleShow
	cp xwa, EVT_PS_FILE_NAME_BOX_ID
	jrl nz, CmpDst_Return
	ld xwa, (xsp + 4)
	ld (0x81f8:16), xwa
	ld xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld xde, 0xffffffff
	call ApPostEvent
	jrl CmpDst_Return

CmpDst_HandleShow:
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	calr SingleLoadSrcMemFunc
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	calr SingleLoadSrcBankFunc
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	calr SingleLoadDstMemFunc
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	calr SingleLoadDstBankFunc
	ld xwa, (0x81f8:16)
	ld xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld xde, 0xffffffff
	call ApPostEvent
	ld xwa, 0x61007e
	ld xbc, EVT_SET_PARAM
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, (0x81f8:16)
	ld c, (0x89f8:16)
	extz bc
	sla bc, 2
	lda xde, (CmpDst_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl CmpDst_Return

CmpDst_HandleScroll:
	ld xwa, (xsp + 4)
	cp xwa, 0x3
	jr nz, CmpDst_ScrollModeA
	ld xwa, (xsp + 8)
	cp xwa, EVT_INDEXSW_UP
	scc8 z, a
	ld (0x89fa:16), a
	ld xwa, xiz
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	calr SingleLoadSrcMemFunc
	ld xwa, xiz
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	calr SingleLoadDstMemFunc
	ld xwa, (0x81f8:16)
	ld xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld xde, 0xffffffff
	call ApPostEvent
	ld xwa, 0x61007e
	ld xbc, EVT_SET_PARAM
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, (0x81f8:16)
	ld c, (0x89f8:16)
	extz bc
	sla bc, 2
	lda xde, (CmpDst_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	ld xhl, (xhl)
	call (xhl)
	ld xwa, xiz
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	calr CmpSingleLoadSrcFunc
	jrl CmpDst_Return

CmpDst_ScrollModeA:
	ld xwa, (xsp + 4)
	cp xwa, 0xa
	jr nz, CmpDst_ScrollMode7
	cp (0x89f8:16), 4
	jr z, CmpDst_ScrollMode7
	ld xwa, 0x600026
	ld xbc, EVT_SHOW
	ld xde, 5:i3
	call ApPostEvent
	ld wa, 0:i3
	calr InitializeOperationState
	ld xwa, (0x81f8:16)
	ld c, (0x89f8:16)
	extz bc
	sla bc, 2
	lda xde, (CmpDst_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xix, (xhl)
	call (xix)
	ld wa, hl
	ld bc, 1:i3
	calr FileIO_ValidateSignedValue
	ld (0x7f42:16), l
	ld xwa, 0x600026
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	ldw wa, 0xee
	call SoundCtrl_SendCommand
	jrl CmpDst_Return

CmpDst_ScrollMode7:
	ld xwa, (xsp + 4)
	cp xwa, 0x7
	jr nz, CmpDst_ScrollMode8
	ld xwa, (0x81f8:16)
	ld xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld xde, 1:i3
	call ApPostEvent
	ld xwa, (0x81f8:16)
	ld c, (0x89f8:16)
	extz bc
	sla bc, 2
	lda xde, (CmpDst_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl CmpDst_Return

CmpDst_ScrollMode8:
	ld xwa, (0x81f8:16)
	ld xbc, (xsp + 4)
	cp xbc, 0x8
	jr nz, CmpDst_ScrollMode5
	cp (0x89fa:16), 0
	jr nz, CmpDst_ScrollMode8_NoStep
	ld xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld xde, 3:i3
	call ApPostEvent
	ld xwa, (0x81f8:16)
	ld c, (0x89f8:16)
	extz bc
	sla bc, 2
	lda xde, (CmpDst_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl CmpDst_Return

CmpDst_ScrollMode8_NoStep:
	ld xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld xde, 0xffffffff
	call ApPostEvent
	ld xwa, (0x81f8:16)
	ld c, (0x89f8:16)
	extz bc
	sla bc, 2
	lda xde, (CmpDst_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jr CmpDst_Return

CmpDst_ScrollMode5:
	ld xbc, (xsp + 4)
	cp xbc, 0x5
	jr nz, CmpDst_ScrollMode6
	ld xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld xde, 0xffffffff
	call ApPostEvent
	ld xwa, (0x81f8:16)
	ld c, (0x89f8:16)
	extz bc
	sla bc, 2
	lda xde, (CmpDst_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jr CmpDst_Return

CmpDst_ScrollMode6:
	ld xbc, (xsp + 4)
	cp xbc, 0x6
	jr nz, CmpDst_Return
	cp (0x89fa:16), 0
	jr nz, CmpDst_Return
	ld xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld xde, 0xffffffff
	call ApPostEvent
	ld xwa, (0x81f8:16)
	ld c, (0x89f8:16)
	extz bc
	sla bc, 2
	lda xde, (CmpDst_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)

CmpDst_Return:
	ld xhl, 0:i3
	jr CmpDst_Epilogue

CmpDst_ReturnCapture:
	ld xhl, 0xffffffff

CmpDst_Epilogue:
	pop xiz
	inc 8, xsp
	ret

CmpSingleLoadFileFunc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xwa
	cp xbc, EVT_INDEXSW_DOWN
	jrl z, CmpFile_HandleScroll
	cp xbc, EVT_INDEXSW_UP
	jr z, CmpFile_HandleScroll
	cp xbc, EVT_PAINT
	jr z, CmpFile_HandleShow
	cp xbc, EVT_PS_FILE_NAME_BOX_ID
	jrl nz, CmpFile_Return
	ld (0x81fc:16), xde
	call GetCurrentFileIndex
	ld (0x8200:16), hl
	cp hl, 0:i3
	jr ge, CmpFile_Selection_Clamp
	ldw (0x8200:16), 0

CmpFile_Selection_Clamp:
	ld xwa, (0x81fc:16)
	ld xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld xde, 0xffffffff
	jr CmpFile_ShowDispatch

CmpFile_HandleShow:
	ld (0x8870:16), 0
	cp (0x89f8:16), 2
	jr nz, CmpFile_ShowDefault
	ld wa, (0x8200:16)
	call GetFileEntryPtr
	ld xiz, xhl
	jr CmpFile_ShowDraw

CmpFile_ShowDefault:
	lda xiz, (CmpFile_ShowDefault_Data:24)

CmpFile_ShowDraw:
	lda xwa, (0x8871:16)
	ld de, (0x8200:16)
	inc 1, de
	pushw 0x6
	pushw 0x0
	ld xbc, xiz
	call FileIO_ReadHeader_ParseLoop
	ld xwa, (0x81fc:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x8870

CmpFile_ShowDispatch:
	call ApPostEvent
	jrl CmpFile_Return

CmpFile_HandleScroll:
	ld wa, (0x8200:16)
	ld hl, wa
	or xde, xde
	jr nz, CmpFile_ScrollDown
	ld bc, wa
	inc 1, bc
	cp bc, 0x14
	jr ge, CmpFile_ScrollRedraw
	inc 1, wa
	jr CmpFile_ScrollStore

CmpFile_ScrollDown:
	cp xde, 0x1
	jr nz, CmpFile_ScrollRedraw
	cp wa, 0:i3
	jr le, CmpFile_ScrollRedraw
	dec 1, wa

CmpFile_ScrollStore:
	ld (0x8200:16), wa

CmpFile_ScrollRedraw:
	ld wa, (0x8200:16)
	cp wa, hl
	jr z, CmpFile_Return
	call NotifyUIOfSelectionChange
	ld (0x8870:16), 0
	lda xiz, (CmpFile_ShowDefault_Data:24)
	ld (0x89f8:16), 4
	ld wa, 3:i3
	call FileIO_CheckRecordValid
	cp l, 0:i3
	jr z, CmpFile_RedrawDispatch
	call FileIO_ValidateAndOpenFile
	cp hl, 0:i3
	jr z, CmpFile_RedrawDispatch
	ld (0x89f8:16), 2
	ld wa, (0x8200:16)
	call GetFileEntryPtr
	ld xiz, xhl

CmpFile_RedrawDispatch:
	lda xwa, (0x8871:16)
	ld de, (0x8200:16)
	inc 1, de
	pushw 0x6
	pushw 0x0
	ld xbc, xiz
	call FileIO_ReadHeader_ParseLoop
	ld xwa, (0x81fc:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x8870
	call ApPostEvent
	ld xwa, (xsp + 4)
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	calr CmpSingleLoadSrcFunc
	ld xwa, (xsp + 4)
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	calr CmpSingleLoadDstFunc

CmpFile_Return:
	ld xhl, 0:i3
	pop xiz
	inc 4, xsp
	ret

FmmCmpSingleLoadFunc:
	cp xbc, EVT_ACTIVATE_STATE
	jrl nz, FmmCmpLoad_Return
	cp xde, 0x3
	jrl z, FmmCmpLoad_HandleAbort
	cp xde, 0x2
	jrl nz, FmmCmpLoad_Return
	ld wa, 1:i3
	calr InitializeOperationState
	ld xwa, 0x61004a
	ld xbc, EVT_SET_VISIBLE
	ld xde, 1:i3
	call ApPostEvent
	ld xwa, 0x600026
	ld xbc, EVT_SHOW
	ld xde, 5:i3
	call ApPostEvent
	cpw (0x8500:16), 0
	jr ge, FmmCmpLoad_DispatchState
	call GetDiskSizeInfo
	extz hl
	ld (0x8500:16), hl
	calr SignalProgressUpdate

FmmCmpLoad_DispatchState:
	ld wa, (0x8500:16)
	cp wa, 1:i3
	jrl z, FmmCmpLoad_HandleSuccess
	cp wa, 0:i3
	jrl z, FmmCmpLoad_HandleError
	cp wa, 5:i3
	jr z, FmmCmpLoad_HandleCancel
	cpw (0x8502:16), 0
	jr ge, FmmCmpLoad_ContinueLoad
	call GetEncodedFileSizeData
	ld (0x8502:16), hl
	call FileIO_SearchAndLoadFile
	call GetEncodedFreeSpaceData
	calr SignalProgressUpdate

FmmCmpLoad_ContinueLoad:
	ld (0x89f8:16), 4
	ld wa, 3:i3
	call FileIO_CheckRecordValid
	cp l, 0:i3
	jr z, FmmCmpLoad_CloseProgress
	call FileIO_ValidateAndOpenFile
	cp hl, 0:i3
	jr z, FmmCmpLoad_SignalProgress
	ld (0x89f8:16), 2

FmmCmpLoad_SignalProgress:
	calr SignalProgressUpdate

FmmCmpLoad_CloseProgress:
	ld xwa, 0x600026
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_ALL_PAINT
	ld xde, 0:i3
	call ApPostEvent
	ld (0x89fe:16), 0
	ld (0x8a06:16), 0
	jr FmmCmpLoad_Return

FmmCmpLoad_HandleCancel:
	ld xwa, 0x600026
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	ldw wa, 0xb0
	call UI_PostModeChangeEvent
	ld (0x7f42:16), 0
	ldw wa, 0xee
	jr FmmCmpLoad_CallStatusDisplay

FmmCmpLoad_HandleError:
	ld xwa, 0x600026
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	ldw wa, 0x7d
	call UI_PostModeChangeEvent
	jr FmmCmpLoad_Return

FmmCmpLoad_HandleSuccess:
	calr ResetProgressIndication
	ld xwa, 0x600026
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	ldw wa, 0xb0
	call UI_PostModeChangeEvent
	ld (0x7f42:16), 2
	ldw wa, 0xee

FmmCmpLoad_CallStatusDisplay:
	call SoundCtrl_SendCommand
	jr FmmCmpLoad_Return

FmmCmpLoad_HandleAbort:
	calr CancelOperationCleanup

FmmCmpLoad_Return:
	ld xhl, 0:i3
	ret

BuildSlotLabel:
	dec 2, xsp
	push xiz
	ld hl, bc
	ld (xsp + 4), wa
	lda xbc, (0x0ab000:24)
	ld wa, (xsp + 4)
	extz xwa
	sll xwa, 11
	add xbc, xwa
	lda xbc, (xbc+256)
	ld wa, (xsp + 4)
	mul wa, 0x15
	lda xix, (0x8202:16)
	ld iz, wa
	extz xiz
	add xiz, xix
	ld (xiz+), l
	cp e, 0:i3
	jr z, BuildSlotLabel_WriteContent
	cpw (xsp + 4), 0x9
	jr nz, BuildSlotLabel_WriteLetter
	ld (xiz+), 0x31
	ld (xiz), 0x30
	jr BuildSlotLabel_WriteColon

BuildSlotLabel_WriteLetter:
	ld (xiz+), 0x20
	ld wa, (xsp + 4)
	add a, 0x31
	ld (xiz), a

BuildSlotLabel_WriteColon:
	inc 1, xiz
	ld (xiz+), 0x3a

BuildSlotLabel_WriteContent:
	ld xwa, xiz
	ldw de, 0x10
	call FileIO_CopyString_WriteNull
	ld (xiz + 16), 0x0
	ld wa, (xsp + 4)
	mul wa, 0x15
	lda xbc, (0x8202:16)
	extz xwa
	add xwa, xbc
	ld xhl, xwa
	pop xiz
	inc 2, xsp
	ret

