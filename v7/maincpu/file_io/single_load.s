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
	cp	xbc, EVT_PAINT
	jr	z, SLMode_HandleShow
	cp	xbc, EVT_PS_FILE_NAME_BOX_ID
	jr	nz, SLMode_Return
	ld	(33050:16), xde
	jr	SLMode_Return
SLMode_HandleShow:
	ld	a, (35164:16)
	extz	wa
	sla	wa, 2
	lda	xbc, (StorageArea_NameTable:24)
	ld_rrl	xde, xbc, wa
	ld	xwa, (33050:16)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
SLMode_Return:
	ld xhl, 0:i3
	ret

SingleLoadDstBankFunc:
	cp	xbc, EVT_PAINT
	jr	z, SLDstBank_HandleShow
	cp	xbc, EVT_PS_FILE_NAME_BOX_ID
	jr	nz, SLDstBank_Return
	ld	(33054:16), xde
	jr	SLDstBank_Return
SLDstBank_HandleShow:
	ld	a, (35164:16)
	extz	wa
	sla	wa, 2
	lda	xbc, (SLDstBank_HandleShow_PtrTable:24)
	ld_rrl	xde, xbc, wa
	ld	xwa, (33054:16)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
SLDstBank_Return:
	ld xhl, 0:i3
	ret

SingleLoadDstMemFunc:
	cp	xbc, EVT_PAINT
	jr	z, SLDstMem_HandleShow
	cp	xbc, EVT_PS_FILE_NAME_BOX_ID
	jr	nz, SLDstMem_Return
	ld	(33058:16), xde
	jr	SLDstMem_Return
SLDstMem_HandleShow:
	ld	xwa, (0x8122:16)
	lda	xde, (SLDstMem_HandleShow_PtrTable:24)
	cp	(0x895e:16), 0
	jr	z, SLDstMem_ShowFromBank
	cp	(0x895c:16), 1
	jr	z, SLDstMem_ShowFromBank
	ld	xde, (xde + 16)
	ld	xbc, EVT_PARA_DRAW
	jr	SLDstMem_DispatchShow
SLDstMem_ShowFromBank:
	ld c, (35164:16)

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
	cp	xbc, EVT_PAINT
	jr	z, SLSrcBank_HandleShow
	cp	xbc, EVT_PS_FILE_NAME_BOX_ID
	jr	nz, SLSrcBank_Return
	ld	(33062:16), xde
	jr	SLSrcBank_Return
SLSrcBank_HandleShow:
	ld	xwa, (33062:16)
	lda	xde, (SLDstBank_HandleShow_PtrTable:24)
	ld	c, (35164:16)
	cp	c, 0:i3
	jr	nz, SLSrcBank_ShowFromIndex
	cp	(35182:16), 0
	jr	z, SLSrcBank_ShowFromIndex
	ld	xde, (xde+16)
	ld	xbc, EVT_PARA_DRAW
	jr	SLSrcBank_DispatchShow
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
	cp	xbc, EVT_PAINT
	jr	z, SLSrcMem_HandleShow
	cp	xbc, EVT_PS_FILE_NAME_BOX_ID
	jr	nz, SLSrcMem_Return
	ld	(33066:16), xde
	jr	SLSrcMem_Return
SLSrcMem_HandleShow:
	ld	xwa, (33066:16)
	lda	xde, (SLDstMem_HandleShow_PtrTable:24)
	ld	c, (35164:16)
	cp	c, 1:i3
	jr	z, SLSrcMem_ShowDirect
	cp	(35166:16), 0
	jr	z, SLSrcMem_ShowFromIndex
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
	lda	xwa, (34994:16)
	ld	(xwa+), 0
	ld	c, (35164:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLDstBank_HandleShow_PtrTable:24)
	ld_rrl	xbc, xde, bc
	inc	1, xbc
	call	FileIO_CopyString
	lda	xwa, (34995:16)
	ld	xbc, SLSrcBankList_FuncBody_Str_Colon
	call	FileIO_BuildFilePath
	lda	xiz, (34995:16)
	ld	a, (35168:16)
	extz	wa
	div	wa, (xsp+0x4)
	inc	1, a
	extz	wa
	ld	bc, 0:i3
	calr	NumToAscii_FormatNumber
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_BuildFilePath
	lda	xwa, (34995:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	ld	xwa, (xsp+6)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 34994
	call	ApPostEvent
	pop	xiz
	inc	6, xsp
	ret
SLSrcBankList_FuncBody_Helper8:
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xwa
	lda	xwa, (34994:16)
	ld	(xwa+21), 1
	lda	xiz, (xwa+22)
	ld	a, (35168:16)
	extz	wa
	div	wa, c
	extz	wa
	call	SLSrcBankList_FuncBody_Helper
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_CopyString
	lda	xwa, (35016:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xde, (35015:16)
	ld	xwa, (xsp+4)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	pop	xiz
	inc	4, xsp
	ret
SLSrcBankList_FuncBody_Helper9:
	dec	6, xsp
	push	xiz
	ld	(xsp+4), c
	ld	(xsp+6), xwa
	lda	xwa, (34994:16)
	ld	(xwa+42), 2
	lda	xwa, (xwa+43)
	ld	c, (35164:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLDstMem_HandleShow_PtrTable:24)
	ld_rrl	xbc, xde, bc
	inc	1, xbc
	call	FileIO_CopyString
	lda	xwa, (35037:16)
	ld	xbc, SLSrcBankList_FuncBody_Str_Colon_2
	call	FileIO_BuildFilePath
	cp	(35166:16), 0
	jr	nz, SLSrcBankList_FuncBody_Skip
	lda	xiz, (35037:16)
	ld	a, (35168:16)
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
SLSrcBankList_FuncBody_Skip:
	lda	xwa, (35037:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xde, (35036:16)
	ld	xwa, (xsp+6)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	cp	(35166:16), 0
	jr	z, SLSrcBankList_FuncBody_Epilogue
	lda	xwa, (34994:16)
	ld	(xwa+63), 3
	lda	xwa, (xwa+64)
	ld	xbc, SLSrcBankList_FuncBody_Str_ALL
	call	FileIO_CopyString
	lda	xde, (35057:16)
	ld	xwa, (xsp+6)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
SLSrcBankList_FuncBody_Epilogue:
	pop	xiz
	inc	6, xsp
	ret
SLSrcBankList_FuncBody_Helper10:
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xwa
	cp	(35166:16), 0
	jr	nz, SLSrcBankList_FuncBody_Epilogue2
	lda	xwa, (34994:16)
	ld	(xwa+63), 3
	lda	xiz, (xwa+64)
	ld	a, (35168:16)
	extz	wa
	call	SLSrcBankList_FuncBody_Helper2
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_CopyString
	lda	xwa, (35058:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xde, (35057:16)
	ld	xwa, (xsp+4)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
SLSrcBankList_FuncBody_Epilogue2:
	pop	xiz
	inc	4, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xde
	ld	xiz, xwa
	cp	xbc, EVT_INDEXSW_DOWN
	jr	z, SLSrcBankList_FuncBody_Skip3
	cp	xbc, EVT_INDEXSW_UP
	jr	z, SLSrcBankList_FuncBody_Skip3
	cp	xbc, EVT_PAINT
	jrl	nz, SLSrcBankList_FuncBody_Join4
	cp	(35182:16), 0
	jr	z, SLSrcBankList_FuncBody_Skip2
	ld	a, (35168:16)
	extz	wa
	.byte 0xc2, 0x52, 0x09, 0xea, 0x51
	ld	(35168:16), w
SLSrcBankList_FuncBody_Skip2:
	ld	c, (PtrTbl_DrumKitNames_0x7A:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody
	ld	c, (PtrTbl_DrumKitNames_0x7A:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper9
	ld	c, (PtrTbl_DrumKitNames_0x7A:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper8
	ld	c, (PtrTbl_DrumKitNames_0x7A:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper10
	ld	xwa, 0:i3
	ld	(33070:16), xwa
	ld	(33074:16), 0
	ld	(33076:16), 0
	jrl	SLSrcBankList_FuncBody_Join4
SLSrcBankList_FuncBody_Skip3:
	ld	e, (35168:16)
	ld	xwa, (xsp+4)
	cp	xwa, 5
	jrl	nz, SLSrcBankList_FuncBody_Skip6
	cp	(35182:16), 0
	jr	nz, SLSrcBankList_FuncBody_Skip5
	ld	xix, xbc
	cp	xbc, EVT_INDEXSW_UP
	jr	nz, SLSrcBankList_FuncBody_Skip4
	ld	l, (PtrTbl_DrumKitNames_0x7A:24)
	ld	a, l
	ld	c, e
	add	a, e
	cp a, (15337812:24)
	jr	nc, SLSrcBankList_FuncBody_Skip4
	add	c, l
	ld	(35168:16), c
	ld	c, (PtrTbl_DrumKitNames_0x7A:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody
	ld	c, (PtrTbl_DrumKitNames_0x7A:24)
	ld	xwa, xiz
	jr	SLSrcBankList_FuncBody_Join
SLSrcBankList_FuncBody_Skip4:
	cp	xix, EVT_INDEXSW_DOWN
	jr	nz, SLSrcBankList_FuncBody_Skip5
	ld	a, e
	ld	c, (PtrTbl_DrumKitNames_0x7A:24)
	cp	e, c
	jr	c, SLSrcBankList_FuncBody_Skip5
	sub	a, c
	ld	(35168:16), a
	ld	c, (PtrTbl_DrumKitNames_0x7A:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody
	ld	c, (PtrTbl_DrumKitNames_0x7A:24)
	ld	xwa, xiz
SLSrcBankList_FuncBody_Join:
	calr	SLSrcBankList_FuncBody_Helper9
	ld	(33076:16), 1
	ld	(33074:16), 1
SLSrcBankList_FuncBody_Skip5:
	ld	xwa, (33070:16)
	cp	xwa, (xsp+0x4)
	jrl	z, SLSrcBankList_FuncBody_Join4
	lda	xde, (35015:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (35057:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	jrl	SLSrcBankList_FuncBody_Join3
SLSrcBankList_FuncBody_Skip6:
	ld	xwa, (xsp+4)
	cp	xwa, 6
	jrl	nz, SLSrcBankList_FuncBody_Skip9
	ld	xhl, xbc
	cp	xbc, EVT_INDEXSW_UP
	jr	nz, SLSrcBankList_FuncBody_Skip7
	ld	c, e
	ld	a, e
	inc	1, a
	cp a, (15337812:24)
	jr	nc, SLSrcBankList_FuncBody_Skip7
	ld	e, (PtrTbl_DrumKitNames_0x7A:24)
	ld	l, e
	ld	a, c
	extz	wa
	div	wa, l
	ld	a, w
	inc	1, a
	cp	a, e
	jr	nc, SLSrcBankList_FuncBody_Skip8
	inc	1, c
	ld	(35168:16), c
	ld	c, (PtrTbl_DrumKitNames_0x7A:24)
	ld	xwa, xiz
	jr	SLSrcBankList_FuncBody_Join2
SLSrcBankList_FuncBody_Skip7:
	cp	xhl, EVT_INDEXSW_DOWN
	jr	nz, SLSrcBankList_FuncBody_Skip8
	ld	c, e
	cp	e, 0:i3
	jr	z, SLSrcBankList_FuncBody_Skip8
	ld	e, (PtrTbl_DrumKitNames_0x7A:24)
	ld	a, c
	extz	wa
	div	wa, e
	ld	a, w
	cp	a, 0:i3
	jr	z, SLSrcBankList_FuncBody_Skip8
	dec	1, c
	ld	(35168:16), c
	ld	c, (PtrTbl_DrumKitNames_0x7A:24)
	ld	xwa, xiz
SLSrcBankList_FuncBody_Join2:
	calr	SLSrcBankList_FuncBody_Helper9
	ld	(33074:16), 1
SLSrcBankList_FuncBody_Skip8:
	ld	xwa, (33070:16)
	cp	xwa, (xsp+0x4)
	jrl	z, SLSrcBankList_FuncBody_Join4
	lda	xde, (35015:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (35057:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	jr	SLSrcBankList_FuncBody_Join3
SLSrcBankList_FuncBody_Skip9:
	ld	xwa, (xsp+4)
	cp	xwa, 7
	jr	z, SLSrcBankList_FuncBody_Skip10
	cp	xwa, 8
	jr	nz, SLSrcBankList_FuncBody_Skip11
SLSrcBankList_FuncBody_Skip10:
	ld	xwa, (33070:16)
	cp	xwa, (xsp+0x4)
	jr	z, SLSrcBankList_FuncBody_Join4
	lda	xde, (35015:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (35057:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
SLSrcBankList_FuncBody_Join3:
	call	ApPostEvent
	ld	xwa, (xsp+4)
	ld	(33070:16), xwa
	jr	SLSrcBankList_FuncBody_Join4
SLSrcBankList_FuncBody_Skip11:
	ld	xwa, (xsp+4)
	cp	xwa, 40
	jr	nz, SLSrcBankList_FuncBody_Join4
	cp	(33076:16), 0
	jr	z, SLSrcBankList_FuncBody_Skip12
	ld	c, (PtrTbl_DrumKitNames_0x7A:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper8
	ld	(33076:16), 0
SLSrcBankList_FuncBody_Skip12:
	cp	(33074:16), 0
	jr	z, SLSrcBankList_FuncBody_Join4
	ld	c, (PtrTbl_DrumKitNames_0x7A:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper10
	ld	(33074:16), 0
SLSrcBankList_FuncBody_Join4:
	ld	xhl, 0:i3
	pop	xiz
	inc	4, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xwa
	cp	xbc, EVT_PAINT
	jrl	nz, SLSrcBankList_FuncBody_Skip13
	lda	xwa, (34994:16)
	ld	(xwa+), 0
	ld	(xwa), 0
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xwa, (34994:16)
	ld	(xwa+21), 1
	lda	xwa, (xwa+22)
	ld	c, (35164:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLDstMem_HandleShow_PtrTable:24)
	ld_rrl	xbc, xde, bc
	inc	1, xbc
	call	FileIO_CopyString
	lda	xwa, (35016:16)
	ld	xbc, SLSrcBankList_FuncBody_Entry_Str_Colon
	call	FileIO_BuildFilePath
	lda	xwa, (35016:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xwa, (34994:16)
	ld	(xwa+42), 2
	lda	xiz, (xwa+43)
	ld	wa, 0:i3
	call	SLSrcBankList_FuncBody_Helper3
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_CopyString
	lda	xwa, (35037:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xwa, (34994:16)
	ld	(xwa+63), 3
	lda	xwa, (xwa+64)
	ld	(xwa), 0
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	ld	xwa, (xsp+4)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 34994
	call	ApPostEvent
	lda	xde, (35015:16)
	ld	xwa, (xsp+4)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (35036:16)
	ld	xwa, (xsp+4)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (35057:16)
	ld	xwa, (xsp+4)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
SLSrcBankList_FuncBody_Skip13:
	ld	xhl, 0:i3
	pop	xiz
	inc	4, xsp
	ret
SLSrcBankList_FuncBody_Helper11:
	dec	2, xsp
	push	xiz
	ld	(xsp+4), c
	ld	xiz, xwa
	lda	xwa, (34994:16)
	ld	(xwa+), 0
	ld	c, (35164:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLDstBank_HandleShow_PtrTable:24)
	ld_rrl	xbc, xde, bc
	inc	1, xbc
	call	FileIO_CopyString
	lda	xwa, (34995:16)
	ld	xbc, SLSrcBankList_FuncBody_Entry_Str_Colon_2
	call	FileIO_BuildFilePath
	lda	xwa, (34995:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xwa, (35015:16)
	ld	c, (35170:16)
	extz	bc
	div	bc, (xsp+0x4)
	extz	bc
	ld	de, 1:i3
	calr	WP_GetPresetName1
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 34994
	call	ApPostEvent
	lda	xde, (35015:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	pop	xiz
	inc	2, xsp
	ret
SLSrcBankList_FuncBody_Helper12:
	dec	8, xsp
	push	xiz
	ld	(xsp+6), c
	ld	(xsp+8), xwa
	ld	a, (35170:16)
	extz	wa
	div	wa, (xsp+0x6)
	ld	a, w
	extz	wa
	ld	(xsp+4), wa
	lda	xwa, (34994:16)
	ld	(xwa+42), 2
	lda	xwa, (xwa+43)
	ld	c, (35164:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLDstMem_HandleShow_PtrTable:24)
	ld_rrl	xbc, xde, bc
	inc	1, xbc
	call	FileIO_CopyString
	lda	xwa, (35037:16)
	ld	xbc, SLSrcBankList_FuncBody_Entry_Str_Colon_3
	call	FileIO_BuildFilePath
	cp	(35166:16), 0
	jr	nz, SLSrcBankList_FuncBody_Skip14
	lda	xiz, (35037:16)
	ld	wa, (xsp+4)
	calr	WP_GetPresetPtr
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_BuildFilePath
SLSrcBankList_FuncBody_Skip14:
	lda	xwa, (35037:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xde, (35036:16)
	ld	xwa, (xsp+8)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xbc, (34994:16)
	lda	xwa, (xbc+63)
	cp	(35166:16), 0
	jr	z, SLSrcBankList_FuncBody_Entry
	ld	(xwa), 3
	lda	xwa, (xbc+64)
	ld	xbc, SLSrcBankList_FuncBody_Entry_Str_ALL
	call	FileIO_CopyString
	lda	xde, (35057:16)
	ld	xwa, (xsp+8)
	ld	xbc, EVT_PARA_DRAW
	jr	SLSrcBankList_FuncBody_Join5
SLSrcBankList_FuncBody_Entry:
	cpw	(xsp+0x4), 4
	jr	c, SLSrcBankList_FuncBody_Epilogue3
	ld	c, (35170:16)
	extz	bc
	div	bc, (xsp+0x6)
	extz	bc
	pushw 3
	ld	de, (xsp+6)
	calr	WP_GetBankMemName
	lda	xde, (35057:16)
	ld	xwa, (xsp+8)
	ld	xbc, EVT_PARA_DRAW
SLSrcBankList_FuncBody_Join5:
	call	ApPostEvent
SLSrcBankList_FuncBody_Epilogue3:
	pop	xiz
	inc	8, xsp
	ret
SLSrcBankList_FuncBody_Helper13:
	dec	4, xsp
	push	xiz
	ld	e, c
	ld	(xsp+4), xwa
	ld	a, (35170:16)
	extz	wa
	div	wa, e
	ld	c, w
	extz	bc
	cp	(35166:16), 0
	jr	nz, SLSrcBankList_FuncBody_Epilogue4
	cp	bc, 4:i3
	jr	nc, SLSrcBankList_FuncBody_Epilogue4
	lda	xwa, (34994:16)
	ld	(xwa+63), 3
	lda	xiz, (xwa+64)
	ld	a, (35170:16)
	extz	wa
	div	wa, e
	extz	wa
	call	SLSrcBankList_FuncBody_Helper4
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_CopyString
	lda	xwa, (35058:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xde, (35057:16)
	ld	xwa, (xsp+4)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
SLSrcBankList_FuncBody_Epilogue4:
	pop	xiz
	inc	4, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xde
	ld	xde, xbc
	ld	xiz, xwa
	ld	c, (PtrTbl_DrumKitNames_0x9C:24)
	cp	xde, EVT_INDEXSW_DOWN
	jr	z, SLSrcBankList_FuncBody_Skip15
	cp	xde, EVT_INDEXSW_UP
	jr	z, SLSrcBankList_FuncBody_Skip15
	cp	xde, EVT_PAINT
	jrl	nz, SLSrcBankList_FuncBody_Join10
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper12
	ld	c, (PtrTbl_DrumKitNames_0x9C:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper11
	ld	c, (PtrTbl_DrumKitNames_0x9C:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper13
	ld	xwa, 0:i3
	ld	(33078:16), xwa
	jrl	SLSrcBankList_FuncBody_Join9
SLSrcBankList_FuncBody_Skip15:
	ld	l, (35170:16)
	ld	xwa, (xsp+4)
	cp	xwa, 5
	jrl	nz, SLSrcBankList_FuncBody_Skip18
	ld	xix, xde
	cp	xde, EVT_INDEXSW_UP
	jr	nz, SLSrcBankList_FuncBody_Skip16
	ld	e, (PtrTbl_DrumKitNames_0x9C:24)
	ld	a, e
	ld	c, l
	add	a, l
	cp a, (15337846:24)
	jr	nc, SLSrcBankList_FuncBody_Skip16
	add	c, e
	ld	(35170:16), c
	ld	c, (PtrTbl_DrumKitNames_0x9C:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper11
	ld	c, (PtrTbl_DrumKitNames_0x9C:24)
	ld	xwa, xiz
	jr	SLSrcBankList_FuncBody_Join6
SLSrcBankList_FuncBody_Skip16:
	cp	xix, EVT_INDEXSW_DOWN
	jr	nz, SLSrcBankList_FuncBody_Skip17
	ld	a, l
	ld	c, (PtrTbl_DrumKitNames_0x9C:24)
	cp	l, c
	jr	c, SLSrcBankList_FuncBody_Skip17
	sub	a, c
	ld	(35170:16), a
	ld	c, (PtrTbl_DrumKitNames_0x9C:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper11
	ld	c, (PtrTbl_DrumKitNames_0x9C:24)
	ld	xwa, xiz
SLSrcBankList_FuncBody_Join6:
	calr	SLSrcBankList_FuncBody_Helper12
	ld	(33082:16), 1
SLSrcBankList_FuncBody_Skip17:
	ld	xwa, (33078:16)
	cp	xwa, (xsp+0x4)
	jrl	z, SLSrcBankList_FuncBody_Join10
	lda	xde, (35015:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (35057:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	jrl	SLSrcBankList_FuncBody_Join8
SLSrcBankList_FuncBody_Skip18:
	ld	xwa, (xsp+4)
	cp	xwa, 6
	jrl	nz, SLSrcBankList_FuncBody_Skip21
	ld	xix, xde
	cp	xde, EVT_INDEXSW_UP
	jr	nz, SLSrcBankList_FuncBody_Skip19
	ld	c, l
	ld	a, l
	inc	1, a
	cp a, (15337846:24)
	jr	nc, SLSrcBankList_FuncBody_Skip19
	ld	e, (PtrTbl_DrumKitNames_0x9C:24)
	ld	l, e
	ld	a, c
	extz	wa
	div	wa, l
	ld	a, w
	inc	1, a
	cp	a, e
	jr	nc, SLSrcBankList_FuncBody_Skip20
	inc	1, c
	ld	(35170:16), c
	ld	c, (PtrTbl_DrumKitNames_0x9C:24)
	ld	xwa, xiz
	jr	SLSrcBankList_FuncBody_Join7
SLSrcBankList_FuncBody_Skip19:
	cp	xix, EVT_INDEXSW_DOWN
	jr	nz, SLSrcBankList_FuncBody_Skip20
	ld	c, l
	cp	l, 0:i3
	jr	z, SLSrcBankList_FuncBody_Skip20
	ld	e, (PtrTbl_DrumKitNames_0x9C:24)
	ld	a, c
	extz	wa
	div	wa, e
	ld	a, w
	cp	a, 0:i3
	jr	z, SLSrcBankList_FuncBody_Skip20
	dec	1, c
	ld	(35170:16), c
	ld	c, (PtrTbl_DrumKitNames_0x9C:24)
	ld	xwa, xiz
SLSrcBankList_FuncBody_Join7:
	calr	SLSrcBankList_FuncBody_Helper12
	ld	(33082:16), 1
SLSrcBankList_FuncBody_Skip20:
	ld	xwa, (33078:16)
	cp	xwa, (xsp+0x4)
	jr	z, SLSrcBankList_FuncBody_Join10
	lda	xde, (35015:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (35057:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	jr	SLSrcBankList_FuncBody_Join8
SLSrcBankList_FuncBody_Skip21:
	ld	xwa, (xsp+4)
	cp	xwa, 7
	jr	z, SLSrcBankList_FuncBody_Skip22
	cp	xwa, 8
	jr	nz, SLSrcBankList_FuncBody_Skip23
SLSrcBankList_FuncBody_Skip22:
	ld	xwa, (33078:16)
	cp	xwa, (xsp+0x4)
	jr	z, SLSrcBankList_FuncBody_Join10
	lda	xde, (35015:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (35057:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
SLSrcBankList_FuncBody_Join8:
	call	ApPostEvent
	ld	xwa, (xsp+4)
	ld	(33078:16), xwa
	jr	SLSrcBankList_FuncBody_Join10
SLSrcBankList_FuncBody_Skip23:
	ld	xwa, (xsp+4)
	cp	xwa, 40
	jr	nz, SLSrcBankList_FuncBody_Join10
	cp	(33082:16), 0
	jr	z, SLSrcBankList_FuncBody_Join10
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper13
SLSrcBankList_FuncBody_Join9:
	ld	(33082:16), 0
SLSrcBankList_FuncBody_Join10:
	ld	xhl, 0:i3
	pop	xiz
	inc	4, xsp
	ret
SLSrcBankList_FuncBody_Helper14:
	ld	xix, (xsp+4)
	ld	l, c
	add	l, c
	cp	(xde), l
	jr	nc, SLSrcBankList_FuncBody_Skip24
	cp	(xix), l
	jr	c, SLSrcBankList_FuncBody_Return
SLSrcBankList_FuncBody_Skip24:
	cp	(xde), l
	jr	c, SLSrcBankList_FuncBody_Skip25
	cp	(xix), l
	jr	nc, SLSrcBankList_FuncBody_Return
SLSrcBankList_FuncBody_Skip25:
	cp	xwa, 8
	jr	z, SLSrcBankList_FuncBody_Skip27
	cp	xwa, 7
	jr	z, SLSrcBankList_FuncBody_Skip27
	cp	xwa, 6
	jr	z, SLSrcBankList_FuncBody_Skip26
	cp	xwa, 5
	jr	nz, SLSrcBankList_FuncBody_Return
SLSrcBankList_FuncBody_Skip26:
	ld	a, (xde)
	ld	(xix), a
	ld	xwa, 0:i3
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 0:i3
	calr	SingleLoadDstFunc
	jr	SLSrcBankList_FuncBody_Return
SLSrcBankList_FuncBody_Skip27:
	ld	a, (xix)
	ld	(xde), a
	ld	xwa, 0:i3
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	calr	SingleLoadSrcFunc
SLSrcBankList_FuncBody_Return:
	retd	0x0004
SLSrcBankList_FuncBody_Helper15:
	dec	6, xsp
	ld	(xsp), c
	ld	(xsp+2), xwa
	lda	xwa, (34994:16)
	ld	(xwa+), 0
	ld	c, (35164:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLDstBank_HandleShow_PtrTable:24)
	ld_rrl	xbc, xde, bc
	inc	1, xbc
	call	FileIO_CopyString
	lda	xwa, (34995:16)
	ld	xbc, SLSrcBankList_FuncBody_Entry_Str_Colon_4
	call	FileIO_BuildFilePath
	lda	xwa, (34995:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	ld	xwa, (xsp+2)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 34994
	call	ApPostEvent
	ld	a, (xsp)
	add	a, (xsp)
	ld	c, (35172:16)
	cp	c, a
	jr	nc, SLSrcBankList_FuncBody_Epilogue5
	lda	xwa, (35015:16)
	extz	bc
	div	bc, (xsp)
	extz	bc
	ld	de, 1:i3
	calr	WP_GetPresetName3
	lda	xde, (35015:16)
	ld	xwa, (xsp+2)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
SLSrcBankList_FuncBody_Epilogue5:
	inc	6, xsp
	ret
SLSrcBankList_FuncBody_Helper16:
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xwa
	ld	a, c
	add	a, c
	cp	(35172:16), a
	jr	c, SLSrcBankList_FuncBody_Epilogue6
	lda	xwa, (34994:16)
	ld	(xwa+21), 1
	lda	xiz, (xwa+22)
	call	SLSrcBankList_FuncBody_Helper6
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_CopyString
	lda	xwa, (35016:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xde, (35015:16)
	ld	xwa, (xsp+4)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
SLSrcBankList_FuncBody_Epilogue6:
	pop	xiz
	inc	4, xsp
	ret
SLSrcBankList_FuncBody_Helper17:
	dec	6, xsp
	push	xiz
	ld	(xsp+4), c
	ld	(xsp+6), xwa
	lda	xwa, (34994:16)
	ld	(xwa+42), 2
	lda	xwa, (xwa+43)
	ld	c, (35164:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLDstMem_HandleShow_PtrTable:24)
	ld_rrl	xbc, xde, bc
	inc	1, xbc
	call	FileIO_CopyString
	lda	xwa, (35037:16)
	ld	xbc, SLSrcBankList_FuncBody_Entry_Str_Colon_5
	call	FileIO_BuildFilePath
	cp	(35166:16), 0
	jr	nz, SLSrcBankList_FuncBody_Skip29
	ld	e, (xsp+4)
	add	e, (xsp+0x4)
	ld	c, (35172:16)
	lda	xwa, (35037:16)
	cp	c, e
	jr	c, SLSrcBankList_FuncBody_Skip28
	ld	xiz, xwa
	sub	c, e
	inc	1, c
	extz	bc
	ld	wa, bc
	ld	bc, 0:i3
	calr	NumToAscii_FormatNumber
	ld	xbc, xhl
	ld	xwa, xiz
	jr	SLSrcBankList_FuncBody_Join11
SLSrcBankList_FuncBody_Skip28:
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
SLSrcBankList_FuncBody_Join11:
	call	FileIO_BuildFilePath
SLSrcBankList_FuncBody_Skip29:
	lda	xwa, (35037:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xde, (35036:16)
	ld	xwa, (xsp+6)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	cp	(35166:16), 0
	jr	z, SLSrcBankList_FuncBody_Epilogue7
	lda	xwa, (34994:16)
	ld	(xwa+63), 3
	lda	xwa, (xwa+64)
	ld	xbc, Str_AllOption_EA0980
	call	FileIO_CopyString
	lda	xde, (35057:16)
	ld	xwa, (xsp+6)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
SLSrcBankList_FuncBody_Epilogue7:
	pop	xiz
	inc	6, xsp
	ret
SLSrcBankList_FuncBody_Helper18:
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xwa
	cp	(35166:16), 0
	jr	nz, SLSrcBankList_FuncBody_Epilogue8
	lda	xwa, (34994:16)
	ld	(xwa+63), 3
	ld	e, c
	add	e, c
	lda	xiz, (xwa+64)
	ld	a, (35172:16)
	cp	a, e
	jr	c, SLSrcBankList_FuncBody_Skip30
	sub	a, e
	extz	wa
	call	SLSrcBankList_FuncBody_Helper7
	ld	xbc, xhl
	ld	xwa, xiz
	jr	SLSrcBankList_FuncBody_Join12
SLSrcBankList_FuncBody_Skip30:
	extz	wa
	call	SLSrcBankList_FuncBody_Helper5
	ld	xbc, xhl
	ld	xwa, xiz
SLSrcBankList_FuncBody_Join12:
	call	FileIO_CopyString
	lda	xwa, (35058:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xde, (35057:16)
	ld	xwa, (xsp+4)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
SLSrcBankList_FuncBody_Epilogue8:
	pop	xiz
	inc	4, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xde
	ld	xiz, xwa
	ld	e, (Str_AllOption_EA0980_0x12:24)
	cp	xbc, EVT_INDEXSW_DOWN
	jr	z, SLSrcBankList_FuncBody_Skip31
	cp	xbc, EVT_INDEXSW_UP
	jr	z, SLSrcBankList_FuncBody_Skip31
	cp	xbc, EVT_PAINT
	jrl	nz, SLSrcBankList_FuncBody_Join18
	ld	xwa, xiz
	ld	c, e
	calr	SLSrcBankList_FuncBody_Helper15
	ld	c, (Str_AllOption_EA0980_0x12:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper17
	ld	c, (Str_AllOption_EA0980_0x12:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper16
	ld	c, (Str_AllOption_EA0980_0x12:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper18
	ld	xwa, 0:i3
	ld	(33084:16), xwa
	ld	(33088:16), 0
	ld	(33090:16), 0
	jrl	SLSrcBankList_FuncBody_Join18
SLSrcBankList_FuncBody_Skip31:
	ld	l, (35172:16)
	ld	xwa, (xsp+4)
	cp	xwa, 5
	jrl	nz, SLSrcBankList_FuncBody_Skip36
	ld	xde, xbc
	cp	xbc, EVT_INDEXSW_UP
	jr	nz, SLSrcBankList_FuncBody_Skip33
	ld	c, (Str_AllOption_EA0980_0x12:24)
	ld	w, c
	add	w, c
	ld	a, l
	cp	l, w
	jr	nc, SLSrcBankList_FuncBody_Skip33
	cp	a, c
	jr	nc, SLSrcBankList_FuncBody_Skip32
	add	a, c
	ld	(35172:16), a
	jr	SLSrcBankList_FuncBody_Join13
SLSrcBankList_FuncBody_Skip32:
	ld	(35172:16), w
SLSrcBankList_FuncBody_Join13:
	ld	c, (Str_AllOption_EA0980_0x12:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper15
	ld	c, (Str_AllOption_EA0980_0x12:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper17
	ld	c, (Str_AllOption_EA0980_0x12:24)
	pushw 0
	pushw 35180
	ld	xwa, (xsp+8)
	ld	xde, 35172
	jr	SLSrcBankList_FuncBody_Join15
SLSrcBankList_FuncBody_Skip33:
	cp	xde, EVT_INDEXSW_DOWN
	jr	nz, SLSrcBankList_FuncBody_Skip35
	ld	c, l
	ld	e, (Str_AllOption_EA0980_0x12:24)
	cp	l, e
	jr	c, SLSrcBankList_FuncBody_Skip35
	ld	a, e
	add	a, e
	cp	c, a
	jr	nc, SLSrcBankList_FuncBody_Skip34
	sub	c, e
	ld	(35172:16), c
	jr	SLSrcBankList_FuncBody_Join14
SLSrcBankList_FuncBody_Skip34:
	ld	(35172:16), e
SLSrcBankList_FuncBody_Join14:
	ld	c, (Str_AllOption_EA0980_0x12:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper15
	ld	c, (Str_AllOption_EA0980_0x12:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper17
	ld	c, (Str_AllOption_EA0980_0x12:24)
	pushw 0
	pushw 35180
	ld	xwa, (xsp+8)
	ld	xde, 35172
SLSrcBankList_FuncBody_Join15:
	calr	SLSrcBankList_FuncBody_Helper14
	ld	(33090:16), 1
	ld	(33088:16), 1
SLSrcBankList_FuncBody_Skip35:
	ld	xwa, (33084:16)
	cp	xwa, (xsp+0x4)
	jrl	z, SLSrcBankList_FuncBody_Join18
	lda	xde, (35015:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (35057:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	jrl	SLSrcBankList_FuncBody_Join17
SLSrcBankList_FuncBody_Skip36:
	ld	xwa, (xsp+4)
	cp	xwa, 6
	jrl	nz, SLSrcBankList_FuncBody_Skip41
	ld	xde, xbc
	cp	xbc, EVT_INDEXSW_UP
	jr	nz, SLSrcBankList_FuncBody_Skip38
	ld	c, l
	ld	a, l
	inc	1, a
	cp a, (15337876:24)
	jr	nc, SLSrcBankList_FuncBody_Skip38
	ld	e, (Str_AllOption_EA0980_0x12:24)
	ld	a, e
	add	a, e
	cp	c, a
	jr	nc, SLSrcBankList_FuncBody_Skip37
	ld	l, e
	ld	a, c
	extz	wa
	div	wa, l
	ld	a, w
	inc	1, a
	cp	a, e
	jrl	nc, SLSrcBankList_FuncBody_Skip40
	inc	1, c
	ld	(35172:16), c
	ld	c, (Str_AllOption_EA0980_0x12:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper17
	ld	c, (Str_AllOption_EA0980_0x12:24)
	pushw 0
	pushw 35180
	ld	xwa, (xsp+8)
	ld	xde, 35172
	jrl	SLSrcBankList_FuncBody_Join16
SLSrcBankList_FuncBody_Skip37:
	inc	1, c
	ld	(35172:16), c
	ld	c, (Str_AllOption_EA0980_0x12:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper17
	ld	c, (Str_AllOption_EA0980_0x12:24)
	pushw 0
	pushw 35180
	ld	xwa, (xsp+8)
	ld	xde, 35172
	jr	SLSrcBankList_FuncBody_Join16
SLSrcBankList_FuncBody_Skip38:
	cp	xde, EVT_INDEXSW_DOWN
	jr	nz, SLSrcBankList_FuncBody_Skip40
	ld	c, l
	cp	l, 0:i3
	jr	z, SLSrcBankList_FuncBody_Skip40
	ld	e, (Str_AllOption_EA0980_0x12:24)
	ld	a, e
	add	a, e
	cp	c, a
	jr	nc, SLSrcBankList_FuncBody_Skip39
	ld	a, c
	extz	wa
	div	wa, e
	ld	a, w
	cp	a, 0:i3
	jr	z, SLSrcBankList_FuncBody_Skip40
	dec	1, c
	ld	(35172:16), c
	ld	c, (Str_AllOption_EA0980_0x12:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper17
	ld	c, (Str_AllOption_EA0980_0x12:24)
	pushw 0
	pushw 35180
	ld	xwa, (xsp+8)
	ld	xde, 35172
	jr	SLSrcBankList_FuncBody_Join16
SLSrcBankList_FuncBody_Skip39:
	cp	c, a
	jr	ule, SLSrcBankList_FuncBody_Skip40
	dec	1, c
	ld	(35172:16), c
	ld	c, (Str_AllOption_EA0980_0x12:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper17
	ld	c, (Str_AllOption_EA0980_0x12:24)
	pushw 0
	pushw 35180
	ld	xwa, (xsp+8)
	ld	xde, 35172
SLSrcBankList_FuncBody_Join16:
	calr	SLSrcBankList_FuncBody_Helper14
	ld	(33088:16), 1
SLSrcBankList_FuncBody_Skip40:
	ld	xwa, (33084:16)
	cp	xwa, (xsp+0x4)
	jrl	z, SLSrcBankList_FuncBody_Join18
	lda	xde, (35015:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (35057:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	jr	SLSrcBankList_FuncBody_Join17
SLSrcBankList_FuncBody_Skip41:
	ld	xwa, (xsp+4)
	cp	xwa, 7
	jr	z, SLSrcBankList_FuncBody_Skip42
	cp	xwa, 8
	jr	nz, SLSrcBankList_FuncBody_Skip43
SLSrcBankList_FuncBody_Skip42:
	ld	xwa, (33084:16)
	cp	xwa, (xsp+0x4)
	jr	z, SLSrcBankList_FuncBody_Join18
	lda	xde, (35015:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (35057:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
SLSrcBankList_FuncBody_Join17:
	call	ApPostEvent
	ld	xwa, (xsp+4)
	ld	(33084:16), xwa
	jr	SLSrcBankList_FuncBody_Join18
SLSrcBankList_FuncBody_Skip43:
	ld	xwa, (xsp+4)
	cp	xwa, 40
	jr	nz, SLSrcBankList_FuncBody_Join18
	cp	(33090:16), 0
	jr	z, SLSrcBankList_FuncBody_Skip44
	ld	xwa, xiz
	ld	c, e
	calr	SLSrcBankList_FuncBody_Helper16
	ld	(33090:16), 0
SLSrcBankList_FuncBody_Skip44:
	cp	(33088:16), 0
	jr	z, SLSrcBankList_FuncBody_Join18
	ld	c, (Str_AllOption_EA0980_0x12:24)
	ld	xwa, xiz
	calr	SLSrcBankList_FuncBody_Helper18
	ld	(33088:16), 0
SLSrcBankList_FuncBody_Join18:
	ld	xhl, 0:i3
	pop	xiz
	inc	4, xsp
	ret
	dec	4, xsp
	pushw	iz
	ld	(xsp+2), xwa
	cp	xbc, EVT_PAINT
	jr	nz, SLSrcBankList_FuncBody_Skip45
	ld	iz, 0:i3
SLSrcBankList_FuncBody_Loop:
	ld	de, iz
	mul	de, 21
	lda	xbc, (34994:16)
	ld	hl, de
	extz	xhl
	add	xhl, xbc
	ldto_berp	a, 248
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
	lda	xwa, (34994:16)
	extz	xde
	add	xde, xwa
	ld	xwa, (xsp+2)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	inc	1, iz
	cp	iz, 4:i3
	jr	c, SLSrcBankList_FuncBody_Loop
SLSrcBankList_FuncBody_Skip45:
	ld	xhl, 0:i3
	popw	iz
	inc	4, xsp
	ret
SingleLoadSrcFunc:
	dec	4, xsp
	push	xiz
	ld	xiz, xde
	ld	(xsp+4), xbc
	ld	xwa, (xsp+4)
	cp	xwa, EVT_GET_SELECTED_FILE_NUMBER
	jrl	z, SLSrc_ReturnCapture
	cp	xwa, EVT_INDEXSW_DOWN
	jr	z, SLSrc_HandleScroll
	cp	xwa, EVT_INDEXSW_UP
	jr	z, SLSrc_HandleScroll
	cp	xwa, EVT_PAINT
	jr	z, SLSrc_HandleShow
	cp	xwa, EVT_PS_FILE_NAME_BOX_ID
	jrl	nz, SLSrc_Return
	ld	xwa, xiz
	ld	(33092:16), xwa
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld	xde, 4294967295
	call	ApPostEvent
	jrl	SLSrc_Return
SLSrc_HandleShow:
	ld	xwa, (33092:16)
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld	xde, 4294967295
	call	ApPostEvent
	ld	xwa, (33092:16)
	ld	c, (35164:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLSrc_HandleShow_PtrTable:24)
	lda_rr	xhl, xde, bc
	ld	xbc, (xsp+4)
	ld	xde, xiz
	ld	xhl, (xhl)
	call (xhl)
	calr	SignalProgressUpdate
	jrl	SLSrc_Return
SLSrc_HandleScroll:
	cp	xiz, 5
	jr	nz, SLSrc_ScrollMode6
	cp	(35164:16), 1
	jr	z, SLSrc_ScrollMode5_Prev
	ld	xwa, (33092:16)
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld	xde, 1:i3
	jr	SLSrc_ScrollMode5_Dispatch
SLSrc_ScrollMode5_Prev:
	ld	xwa, (33092:16)
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld	xde, 4294967295
SLSrc_ScrollMode5_Dispatch:
	call	ApPostEvent
	ld	xwa, (33092:16)
	ld	c, (35164:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLSrc_HandleShow_PtrTable:24)
	lda_rr	xhl, xde, bc
	ld	xbc, (xsp+4)
	ld	xde, xiz
	ld	xhl, (xhl)
	call (xhl)
	jrl	SLSrc_Return
SLSrc_ScrollMode6:
	cp	xiz, 6
	jr	nz, SLSrc_ScrollMode7
	cp	(35164:16), 1
	jr	z, SLSrc_ScrollMode6_NoStep
	cp	(35166:16), 0
	jr	nz, SLSrc_ScrollMode6_NoStep
	ld	xwa, (33092:16)
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld	xde, 3:i3
	jr	SLSrc_ScrollMode6_Dispatch
SLSrc_ScrollMode6_NoStep:
	ld	xwa, (33092:16)
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld	xde, 4294967295
SLSrc_ScrollMode6_Dispatch:
	call	ApPostEvent
	ld	xwa, (33092:16)
	ld	c, (35164:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLSrc_HandleShow_PtrTable:24)
	lda_rr	xhl, xde, bc
	ld	xbc, (xsp+4)
	ld	xde, xiz
	ld	xhl, (xhl)
	call	(xhl)
	jrl	SLSrc_Return	; -> 0xF8FC5B
SLSrc_ScrollMode7:
	ld	xwa, (33092:16)
	cp	xiz, 7
	jr	nz, SLSrc_ScrollMode8	; -> 0xF8FBFF
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld	xde, 4294967295
	call	ApPostEvent
	ld	xwa, (33092:16)
	ld	c, (35164:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLSrc_HandleShow_PtrTable:24)
	lda_rr	xhl, xde, bc
	ld	xbc, (xsp+4)
	ld	xde, xiz
	ld	xhl, (xhl)
	call	(xhl)
	jr	SLSrc_Return	; -> 0xF8FC5B
SLSrc_ScrollMode8:
	cp	xiz, 8
	jr	nz, SLSrc_ScrollMode40	; -> 0xF8FC37
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld	xde, 4294967295
	call	ApPostEvent
	ld	xwa, (33092:16)
	ld	c, (35164:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLSrc_HandleShow_PtrTable:24)
	lda_rr	xhl, xde, bc
	ld	xbc, (xsp+4)
	ld	xde, xiz
	ld	xhl, (xhl)
	call	(xhl)
	jr	SLSrc_Return	; -> 0xF8FC5B
SLSrc_ScrollMode40:
	cp	xiz, 40
	jr	nz, SLSrc_Return	; -> 0xF8FC5B
	ld	c, (35164:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLSrc_HandleShow_PtrTable:24)
	lda_rr	xhl, xde, bc
	ld	xbc, (xsp+4)
	ld	xde, xiz
	ld	xhl, (xhl)
	call	(xhl)
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
	lda	xwa, (35078:16)
	ld	(xwa+), 0
	ld	c, (35164:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLDstBank_HandleShow_PtrTable:24)
	ld_rrl	xbc, xde, bc
	inc	1, xbc
	call	FileIO_CopyString
	lda	xwa, (35079:16)
	ld	xbc, SLDstBankList_FuncBody_Str_Colon
	call	FileIO_BuildFilePath
	lda	xiz, (35079:16)
	ld	a, (35174:16)
	extz	wa
	div	wa, (xsp+0x4)
	inc	1, a
	extz	wa
	ld	bc, 0:i3
	calr	NumToAscii_FormatNumber
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_BuildFilePath
	lda	xwa, (35079:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xwa, (35099:16)
	ld	c, (35174:16)
	extz	bc
	div	bc, (xsp+0x4)
	extz	bc
	ld	de, 1:i3
	calr	WP_GetConfigName
	lda	xwa, (35100:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	ld	xwa, (xsp+6)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 35078
	call	ApPostEvent
	lda	xde, (35099:16)
	ld	xwa, (xsp+6)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	pop	xiz
	inc	6, xsp
	ret
SLDstBankList_FuncBody_Helper6:
	dec	6, xsp
	push	xiz
	ld	(xsp+4), c
	ld	(xsp+6), xwa
	lda	xde, (35078:16)
	ld	(xde+42), 2
	ld	(xde+63), 3
	ld	a, (35164:16)
	extz	wa
	lda	xhl, (SLDstMem_HandleShow_PtrTable:24)
	ld	bc, wa
	sla	bc, 2
	lda	xwa, (xde+43)
	ld_rrl	xbc, xhl, bc
	inc	1, xbc
	cp	(35166:16), 0
	jr	z, SLDstBankList_FuncBody_Skip
	call	FileIO_CopyString
	lda	xwa, (35121:16)
	ld	xbc, SLDstBankList_FuncBody_Str_Colon_2
	call	FileIO_BuildFilePath
	lda	xwa, (35121:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xwa, (35142:16)
	ld	xbc, Str_AllOption_EA09B2
	call	FileIO_CopyString
	jr	SLDstBankList_FuncBody_Join
SLDstBankList_FuncBody_Skip:
	call	FileIO_CopyString
	lda	xwa, (35121:16)
	ld	xbc, SLDstBankList_FuncBody_Str_Colon_3
	call	FileIO_BuildFilePath
	lda	xiz, (35121:16)
	ld	a, (35174:16)
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
	lda	xwa, (35121:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xwa, (35141:16)
	ld	c, (35174:16)
	extz	bc
	ld	de, 3:i3
	calr	WP_GetNameByOffset
SLDstBankList_FuncBody_Join:
	lda	xde, (35120:16)
	ld	xwa, (xsp+6)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (35141:16)
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
	ld	c, (Str_AllOption_EA09B2_0x16:24)
	cp	xde, EVT_INDEXSW_DOWN
	jr	z, SLDstBankList_FuncBody_Skip2
	cp	xde, EVT_INDEXSW_UP
	jr	z, SLDstBankList_FuncBody_Skip2
	cp	xde, EVT_PAINT
	jrl	nz, SLDstBankList_FuncBody_Loop
	ld	xwa, xiz
	calr	SLDstBankList_FuncBody
	ld	c, (Str_AllOption_EA09B2_0x16:24)
	ld	xwa, xiz
	calr	SLDstBankList_FuncBody_Helper6
	ld	xwa, 0:i3
	ld	(33096:16), xwa
	jrl	SLDstBankList_FuncBody_Loop
SLDstBankList_FuncBody_Skip2:
	ld	l, (35174:16)
	ld	xwa, (xsp+4)
	cp	xwa, 7
	jrl	nz, SLDstBankList_FuncBody_Skip5
	ld	xix, xde
	cp	xde, EVT_INDEXSW_UP
	jr	nz, SLDstBankList_FuncBody_Skip3
	ld	e, (Str_AllOption_EA09B2_0x16:24)
	ld	a, e
	ld	c, l
	add	a, l
	cp a, (15337930:24)
	jr	nc, SLDstBankList_FuncBody_Skip3
	add	c, e
	ld	(35174:16), c
	ld	c, (Str_AllOption_EA09B2_0x16:24)
	ld	xwa, xiz
	calr	SLDstBankList_FuncBody
	ld	c, (Str_AllOption_EA09B2_0x16:24)
	ld	xwa, xiz
	jr	SLDstBankList_FuncBody_Join2
SLDstBankList_FuncBody_Skip3:
	cp	xix, EVT_INDEXSW_DOWN
	jr	nz, SLDstBankList_FuncBody_Skip4
	ld	a, l
	ld	c, (Str_AllOption_EA09B2_0x16:24)
	cp	l, c
	jr	c, SLDstBankList_FuncBody_Skip4
	sub	a, c
	ld	(35174:16), a
	ld	c, (Str_AllOption_EA09B2_0x16:24)
	ld	xwa, xiz
	calr	SLDstBankList_FuncBody
	ld	c, (Str_AllOption_EA09B2_0x16:24)
	ld	xwa, xiz
SLDstBankList_FuncBody_Join2:
	calr	SLDstBankList_FuncBody_Helper6
SLDstBankList_FuncBody_Skip4:
	ld	xwa, (33096:16)
	cp	xwa, (xsp+0x4)
	jr	z, SLDstBankList_FuncBody_Loop
	lda	xde, (35099:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (35141:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
SLDstBankList_FuncBody_Join3:
	call	ApPostEvent
	ld	xwa, (xsp+4)
	ld	(33096:16), xwa
SLDstBankList_FuncBody_Loop:
	ld	xhl, 0:i3
	jrl	SLDstBankList_FuncBody_Epilogue
SLDstBankList_FuncBody_Skip5:
	ld	xwa, (xsp+4)
	cp	xwa, 8
	jrl	nz, SLDstBankList_FuncBody_Skip8
	ld	xix, xde
	cp	xde, EVT_INDEXSW_UP
	jr	nz, SLDstBankList_FuncBody_Skip6
	ld	c, l
	ld	a, l
	inc	1, a
	cp a, (15337930:24)
	jr	nc, SLDstBankList_FuncBody_Skip6
	ld	e, (Str_AllOption_EA09B2_0x16:24)
	ld	l, e
	ld	a, c
	extz	wa
	div	wa, l
	ld	a, w
	inc	1, a
	cp	a, e
	jr	nc, SLDstBankList_FuncBody_Skip7
	inc	1, c
	ld	(35174:16), c
	ld	c, (Str_AllOption_EA09B2_0x16:24)
	ld	xwa, xiz
	jr	SLDstBankList_FuncBody_Join4
SLDstBankList_FuncBody_Skip6:
	cp	xix, EVT_INDEXSW_DOWN
	jr	nz, SLDstBankList_FuncBody_Skip7
	ld	c, l
	cp	l, 0:i3
	jr	z, SLDstBankList_FuncBody_Skip7
	ld	e, (Str_AllOption_EA09B2_0x16:24)
	ld	a, c
	extz	wa
	div	wa, e
	ld	a, w
	cp	a, 0:i3
	jr	z, SLDstBankList_FuncBody_Skip7
	dec	1, c
	ld	(35174:16), c
	ld	c, (Str_AllOption_EA09B2_0x16:24)
	ld	xwa, xiz
SLDstBankList_FuncBody_Join4:
	calr	SLDstBankList_FuncBody_Helper6
SLDstBankList_FuncBody_Skip7:
	ld	xwa, (33096:16)
	cp	xwa, (xsp+0x4)
	jrl	z, SLDstBankList_FuncBody_Loop
	lda	xde, (35099:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (35141:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	jrl	SLDstBankList_FuncBody_Join3
SLDstBankList_FuncBody_Skip8:
	ld	xwa, (xsp+4)
	cp	xwa, 5
	jr	z, SLDstBankList_FuncBody_Skip9
	cp	xwa, 6
	jr	nz, SLDstBankList_FuncBody_Skip10
SLDstBankList_FuncBody_Skip9:
	ld	xwa, (33096:16)
	cp	xwa, (xsp+0x4)
	jrl	z, SLDstBankList_FuncBody_Loop
	lda	xde, (35099:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (35141:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	jrl	SLDstBankList_FuncBody_Join3
SLDstBankList_FuncBody_Skip10:
	ld	xwa, (xsp+4)
	cp	xwa, 10
	jrl	nz, SLDstBankList_FuncBody_Loop
	cp	(35166:16), 0
	jr	z, SLDstBankList_FuncBody_Skip11
	ld	a, (35168:16)
	extz	wa
	div	wa, c
	extz	wa
	ld	e, (35174:16)
	extz	de
	div	de, c
	extz	de
	ld	bc, de
	call	SLDstBankList_FuncBody_Helper
	exts	xhl
	jr	SLDstBankList_FuncBody_Epilogue
SLDstBankList_FuncBody_Skip11:
	ld	a, (35168:16)
	extz	wa
	ld	c, (35174:16)
	extz	bc
	call	FileIO_ByteBlock_DemoProc1
	exts	xhl
SLDstBankList_FuncBody_Epilogue:
	pop	xiz
	inc	4, xsp
	ret
SLDstBankList_FuncBody_Helper7:
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xwa
	lda	xwa, (35078:16)
	ld	(xwa+21), 1
	lda	xwa, (xwa+22)
	ld	c, (35164:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLDstMem_HandleShow_PtrTable:24)
	ld_rrl	xbc, xde, bc
	inc	1, xbc
	call	FileIO_CopyString
	lda	xwa, (35100:16)
	ld	xbc, SLDstBankList_FuncBody_Str_Colon_4
	call	FileIO_BuildFilePath
	lda	xiz, (35100:16)
	ld	a, (35176:16)
	inc	1, a
	extz	wa
	ld	bc, 0:i3
	calr	NumToAscii_FormatNumber
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_BuildFilePath
	lda	xwa, (35100:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xiz, (35120:16)
	ld	a, (35176:16)
	extz	wa
	ld	bc, 2:i3
	ld	de, 0:i3
	calr	BuildSlotLabel
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_CopyString
	lda	xde, (35099:16)
	ld	xwa, (xsp+4)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (35120:16)
	ld	xwa, (xsp+4)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	pop	xiz
	inc	4, xsp
	ret
	push	xiz
	ld	xiz, xwa
	cp	xbc, EVT_INDEXSW_DOWN
	jr	z, SLDstBankList_FuncBody_Skip12
	cp	xbc, EVT_INDEXSW_UP
	jr	z, SLDstBankList_FuncBody_Skip12
	cp	xbc, EVT_PAINT
	jr	nz, SLDstBankList_FuncBody_Loop2
	lda	xwa, (35078:16)
	ld	(xwa+), 0
	ld	(xwa), 0
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xwa, (35078:16)
	ld	(xwa+63), 3
	lda	xwa, (xwa+64)
	ld	(xwa), 0
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 35078
	call	ApPostEvent
	lda	xde, (35141:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	ld	xwa, xiz
	jr	SLDstBankList_FuncBody_Join5
SLDstBankList_FuncBody_Skip12:
	ld	w, (35176:16)
	lda	xhl, (35120:16)
	cp	xde, 8
	jr	nz, SLDstBankList_FuncBody_Skip15
	ld	xde, xbc
	cp	xde, EVT_INDEXSW_UP
	jr	nz, SLDstBankList_FuncBody_Skip13
	ld	c, w
	ld	a, w
	inc	1, a
	cp a, (15337936:24)
	jr	nc, SLDstBankList_FuncBody_Skip13
	inc	1, c
	ld	(35176:16), c
	ld	xwa, xiz
SLDstBankList_FuncBody_Join5:
	calr	SLDstBankList_FuncBody_Helper7
SLDstBankList_FuncBody_Loop2:
	ld	xhl, 0:i3
	jr	SLDstBankList_FuncBody_Epilogue2
SLDstBankList_FuncBody_Skip13:
	cp	xde, EVT_INDEXSW_DOWN
	jr	nz, SLDstBankList_FuncBody_Skip14
	ld	a, w
	cp	w, 0:i3
	jr	z, SLDstBankList_FuncBody_Skip14
	dec	1, a
	ld	(35176:16), a
	ld	xwa, xiz
	jr	SLDstBankList_FuncBody_Join5
SLDstBankList_FuncBody_Skip14:
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	ld	xde, xhl
	jr	SLDstBankList_FuncBody_Join6
SLDstBankList_FuncBody_Skip15:
	cp	xde, 5
	jr	c, SLDstBankList_FuncBody_Skip16
	cp	xde, 7
	jr	ugt, SLDstBankList_FuncBody_Skip16
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	ld	xde, xhl
SLDstBankList_FuncBody_Join6:
	call	ApPostEvent
	jr	SLDstBankList_FuncBody_Loop2
SLDstBankList_FuncBody_Skip16:
	cp	xde, 10
	jr	nz, SLDstBankList_FuncBody_Loop2
	ld	a, (35176:16)
	extz	wa
	call	SLDstBankList_FuncBody_Helper2
	exts	xhl
SLDstBankList_FuncBody_Epilogue2:
	pop	xiz
	ret
SLDstBankList_FuncBody_Helper8:
	dec	2, xsp
	push	xiz
	ld	(xsp+4), c
	ld	xiz, xwa
	lda	xwa, (35078:16)
	ld	(xwa+), 0
	ld	c, (35164:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLDstBank_HandleShow_PtrTable:24)
	ld_rrl	xbc, xde, bc
	inc	1, xbc
	call	FileIO_CopyString
	lda	xwa, (35079:16)
	ld	xbc, SLDstBankList_FuncBody_Str_Colon_5
	call	FileIO_BuildFilePath
	lda	xwa, (35079:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xwa, (35099:16)
	ld	c, (35178:16)
	extz	bc
	div	bc, (xsp+0x4)
	extz	bc
	ld	de, 1:i3
	calr	WP_GetPresetName1
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 35078
	call	ApPostEvent
	lda	xde, (35099:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	pop	xiz
	inc	2, xsp
	ret
SLDstBankList_FuncBody_Helper9:
	dec	6, xsp
	push	xiz
	ld	(xsp+4), c
	ld	(xsp+6), xwa
	lda	xwa, (35078:16)
	ld	(xwa+42), 2
	lda	xwa, (xwa+43)
	ld	c, (35164:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLDstMem_HandleShow_PtrTable:24)
	ld_rrl	xbc, xde, bc
	inc	1, xbc
	call	FileIO_CopyString
	lda	xwa, (35121:16)
	ld	xbc, SLDstBankList_FuncBody_Str_Colon_6
	call	FileIO_BuildFilePath
	cp	(35166:16), 0
	jr	nz, SLDstBankList_FuncBody_Skip17
	lda	xiz, (35121:16)
	ld	a, (35178:16)
	extz	wa
	div	wa, (xsp+0x4)
	ld	a, w
	extz	wa
	calr	WP_GetPresetPtr
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_BuildFilePath
SLDstBankList_FuncBody_Skip17:
	lda	xwa, (35121:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xbc, (35078:16)
	lda	xwa, (xbc+63)
	cp	(35166:16), 0
	jr	z, SLDstBankList_FuncBody_Skip18
	ld	(xwa), 3
	lda	xwa, (xbc+64)
	ld	xbc, SLDstBankList_FuncBody_Str_ALL
	call	FileIO_CopyString
	jr	SLDstBankList_FuncBody_Join7
SLDstBankList_FuncBody_Skip18:
	ld	e, (35178:16)
	ld	c, e
	extz	bc
	div	bc, (xsp+0x4)
	extz	bc
	extz	de
	div	de, (xsp+0x4)
	ld	e, d
	extz	de
	pushw 3
	calr	WP_GetBankMemName
SLDstBankList_FuncBody_Join7:
	lda	xde, (35120:16)
	ld	xwa, (xsp+6)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (35141:16)
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
	ld	c, (Str_AllOption_EA09B2_0x3A:24)
	cp	xde, EVT_INDEXSW_DOWN
	jr	z, SLDstBankList_FuncBody_Skip19
	cp	xde, EVT_INDEXSW_UP
	jr	z, SLDstBankList_FuncBody_Skip19
	cp	xde, EVT_PAINT
	jrl	nz, SLDstBankList_FuncBody_Loop3
	ld	xwa, xiz
	calr	SLDstBankList_FuncBody_Helper8
	ld	c, (Str_AllOption_EA09B2_0x3A:24)
	ld	xwa, xiz
	calr	SLDstBankList_FuncBody_Helper9
	ld	xwa, 0:i3
	ld	(33100:16), xwa
	jrl	SLDstBankList_FuncBody_Loop3
SLDstBankList_FuncBody_Skip19:
	ld	l, (35178:16)
	ld	xwa, (xsp+4)
	cp	xwa, 7
	jrl	nz, SLDstBankList_FuncBody_Skip22
	ld	xix, xde
	cp	xde, EVT_INDEXSW_UP
	jr	nz, SLDstBankList_FuncBody_Skip20
	ld	e, (Str_AllOption_EA09B2_0x3A:24)
	ld	a, e
	ld	c, l
	add	a, l
	cp a, (15337966:24)
	jr	nc, SLDstBankList_FuncBody_Skip20
	add	c, e
	ld	(35178:16), c
	ld	c, (Str_AllOption_EA09B2_0x3A:24)
	ld	xwa, xiz
	calr	SLDstBankList_FuncBody_Helper8
	ld	c, (Str_AllOption_EA09B2_0x3A:24)
	ld	xwa, xiz
	jr	SLDstBankList_FuncBody_Join8
SLDstBankList_FuncBody_Skip20:
	cp	xix, EVT_INDEXSW_DOWN
	jr	nz, SLDstBankList_FuncBody_Skip21
	ld	a, l
	ld	c, (Str_AllOption_EA09B2_0x3A:24)
	cp	l, c
	jr	c, SLDstBankList_FuncBody_Skip21
	sub	a, c
	ld	(35178:16), a
	ld	c, (Str_AllOption_EA09B2_0x3A:24)
	ld	xwa, xiz
	calr	SLDstBankList_FuncBody_Helper8
	ld	c, (Str_AllOption_EA09B2_0x3A:24)
	ld	xwa, xiz
SLDstBankList_FuncBody_Join8:
	calr	SLDstBankList_FuncBody_Helper9
SLDstBankList_FuncBody_Skip21:
	ld	xwa, (33100:16)
	cp	xwa, (xsp+0x4)
	jr	z, SLDstBankList_FuncBody_Loop3
	lda	xde, (35099:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (35141:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
SLDstBankList_FuncBody_Join9:
	call	ApPostEvent
	ld	xwa, (xsp+4)
	ld	(33100:16), xwa
SLDstBankList_FuncBody_Loop3:
	ld	xhl, 0:i3
	jrl	SLDstBankList_FuncBody_Epilogue3
SLDstBankList_FuncBody_Skip22:
	ld	xwa, (xsp+4)
	cp	xwa, 8
	jrl	nz, SLDstBankList_FuncBody_Skip25
	ld	xix, xde
	cp	xde, EVT_INDEXSW_UP
	jr	nz, SLDstBankList_FuncBody_Skip23
	ld	c, l
	ld	a, l
	inc	1, a
	cp a, (15337966:24)
	jr	nc, SLDstBankList_FuncBody_Skip23
	ld	e, (Str_AllOption_EA09B2_0x3A:24)
	ld	l, e
	ld	a, c
	extz	wa
	div	wa, l
	ld	a, w
	inc	1, a
	cp	a, e
	jr	nc, SLDstBankList_FuncBody_Skip24
	inc	1, c
	ld	(35178:16), c
	ld	c, (Str_AllOption_EA09B2_0x3A:24)
	ld	xwa, xiz
	jr	SLDstBankList_FuncBody_Join10
SLDstBankList_FuncBody_Skip23:
	cp	xix, EVT_INDEXSW_DOWN
	jr	nz, SLDstBankList_FuncBody_Skip24
	ld	c, l
	cp	l, 0:i3
	jr	z, SLDstBankList_FuncBody_Skip24
	ld	e, (Str_AllOption_EA09B2_0x3A:24)
	ld	a, c
	extz	wa
	div	wa, e
	ld	a, w
	cp	a, 0:i3
	jr	z, SLDstBankList_FuncBody_Skip24
	dec	1, c
	ld	(35178:16), c
	ld	c, (Str_AllOption_EA09B2_0x3A:24)
	ld	xwa, xiz
SLDstBankList_FuncBody_Join10:
	calr	SLDstBankList_FuncBody_Helper9
SLDstBankList_FuncBody_Skip24:
	ld	xwa, (33100:16)
	cp	xwa, (xsp+0x4)
	jrl	z, SLDstBankList_FuncBody_Loop3
	lda	xde, (35099:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (35141:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	jrl	SLDstBankList_FuncBody_Join9
SLDstBankList_FuncBody_Skip25:
	ld	xwa, (xsp+4)
	cp	xwa, 5
	jr	z, SLDstBankList_FuncBody_Skip26
	cp	xwa, 6
	jr	nz, SLDstBankList_FuncBody_Skip27
SLDstBankList_FuncBody_Skip26:
	ld	xwa, (33100:16)
	cp	xwa, (xsp+0x4)
	jrl	z, SLDstBankList_FuncBody_Loop3
	lda	xde, (35099:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (35141:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	jrl	SLDstBankList_FuncBody_Join9
SLDstBankList_FuncBody_Skip27:
	ld	xwa, (xsp+4)
	cp	xwa, 10
	jrl	nz, SLDstBankList_FuncBody_Loop3
	cp	(35166:16), 0
	jr	z, SLDstBankList_FuncBody_Skip28
	ld	a, (35170:16)
	extz	wa
	div	wa, c
	add	a, 30
	extz	wa
	ld	e, (35178:16)
	extz	de
	div	de, c
	add	e, 30
	extz	de
	ld	bc, de
	jr	SLDstBankList_FuncBody_Join11
SLDstBankList_FuncBody_Skip28:
	ld	a, (35170:16)
	extz	wa
	ld	c, (35178:16)
	extz	bc
SLDstBankList_FuncBody_Join11:
	call	SLDstBankList_FuncBody_Helper3
	exts	xhl
SLDstBankList_FuncBody_Epilogue3:
	pop	xiz
	inc	4, xsp
	ret
SLDstBankList_FuncBody_Helper10:
	dec	6, xsp
	ld	(xsp), c
	ld	(xsp+2), xwa
	lda	xwa, (35078:16)
	ld	(xwa+), 0
	ld	c, (35164:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLDstBank_HandleShow_PtrTable:24)
	ld_rrl	xbc, xde, bc
	inc	1, xbc
	call	FileIO_CopyString
	lda	xwa, (35079:16)
	ld	xbc, Data_SaveLoadMenuTable
	call	FileIO_BuildFilePath
	lda	xwa, (35079:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	ld	e, (xsp)
	add	e, (xsp)
	ld	c, (35180:16)
	lda	xwa, (35099:16)
	cp	c, e
	jr	nc, SLDstBankList_FuncBody_Skip29
	extz	bc
	div	bc, (xsp)
	extz	bc
	ld	de, 1:i3
	calr	WP_GetPresetName3
	jr	SLDstBankList_FuncBody_Join12
SLDstBankList_FuncBody_Skip29:
	ld	bc, 1:i3
	calr	WP_GetUserName2
SLDstBankList_FuncBody_Join12:
	ld	xwa, (xsp+2)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 35078
	call	ApPostEvent
	lda	xde, (35099:16)
	ld	xwa, (xsp+2)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	inc	6, xsp
	ret
SLDstBankList_FuncBody_Helper11:
	dec	6, xsp
	push	xiz
	ld	(xsp+4), c
	ld	(xsp+6), xwa
	lda	xde, (SLDstMem_HandleShow_PtrTable:24)
	cp	(35166:16), 0
	jr	z, SLDstBankList_FuncBody_Skip30
	lda	xwa, (35078:16)
	ld	(xwa+42), 2
	lda	xwa, (xwa+43)
	ld	c, (35164:16)
	extz	bc
	sla	bc, 2
	ld_rrl	xbc, xde, bc
	inc	1, xbc
	call	FileIO_CopyString
	lda	xwa, (35121:16)
	ld	xbc, SLDstBankList_FuncBody_Str_Colon_7
	call	FileIO_BuildFilePath
	lda	xwa, (35121:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xwa, (35078:16)
	ld	(xwa+63), 3
	lda	xwa, (xwa+64)
	ld	xbc, SLDstBankList_FuncBody_Str_ALL_2
	call	FileIO_CopyString
	jrl	SLDstBankList_FuncBody_Join13
SLDstBankList_FuncBody_Skip30:
	ld	l, (xsp+4)
	add	l, (xsp+0x4)
	lda	xbc, (35078:16)
	lda	xwa, (xbc+43)
	ld	(xbc+42), 2
	cp	(35180:16), l
	jr	c, SLDstBankList_FuncBody_Skip31
	ld	c, (35164:16)
	extz	bc
	sla	bc, 2
	ld_rrl	xbc, xde, bc
	inc	1, xbc
	call	FileIO_CopyString
	lda	xwa, (35121:16)
	ld	xbc, SLDstBankList_FuncBody_Str_Colon_8
	call	FileIO_BuildFilePath
	lda	xiz, (35121:16)
	ld	c, (xsp+4)
	add	c, (xsp+0x4)
	ld	a, (35180:16)
	sub	a, c
	inc	1, a
	extz	wa
	ld	bc, 0:i3
	calr	NumToAscii_FormatNumber
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_BuildFilePath
	lda	xwa, (35121:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xwa, (35141:16)
	ld	e, (xsp+4)
	add	e, (xsp+0x4)
	ld	c, (35180:16)
	sub	c, e
	extz	bc
	ld	de, 3:i3
	calr	WP_GetUserName3
	jr	SLDstBankList_FuncBody_Join13
SLDstBankList_FuncBody_Skip31:
	ld	c, (35164:16)
	extz	bc
	sla	bc, 2
	ld_rrl	xbc, xde, bc
	inc	1, xbc
	call	FileIO_CopyString
	lda	xwa, (35121:16)
	ld	xbc, SLDstBankList_FuncBody_Str_Colon_9
	call	FileIO_BuildFilePath
	lda	xiz, (35121:16)
	ld	a, (35180:16)
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
	lda	xwa, (35121:16)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xwa, (35141:16)
	ld	c, (35180:16)
	extz	bc
	ld	de, 3:i3
	calr	WP_GetUserName1
SLDstBankList_FuncBody_Join13:
	lda	xde, (35120:16)
	ld	xwa, (xsp+6)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (35141:16)
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
	ld	e, (Data_SaveLoadMenuTable_0x22:24)
	cp	xbc, EVT_INDEXSW_DOWN
	jr	z, SLDstBankList_FuncBody_Skip32
	cp	xbc, EVT_INDEXSW_UP
	jr	z, SLDstBankList_FuncBody_Skip32
	cp	xbc, EVT_PAINT
	jrl	nz, SLDstBankList_FuncBody_Loop4
	ld	xwa, xiz
	ld	c, e
	calr	SLDstBankList_FuncBody_Helper10
	ld	c, (Data_SaveLoadMenuTable_0x22:24)
	ld	xwa, xiz
	calr	SLDstBankList_FuncBody_Helper11
	ld	xwa, 0:i3
	ld	(33104:16), xwa
	jrl	SLDstBankList_FuncBody_Loop4
SLDstBankList_FuncBody_Skip32:
	ld	l, (35180:16)
	ld	xwa, (xsp+4)
	cp	xwa, 7
	jrl	nz, SLDstBankList_FuncBody_Skip37
	ld	xde, xbc
	cp	xbc, EVT_INDEXSW_UP
	jr	nz, SLDstBankList_FuncBody_Skip34
	ld	c, (Data_SaveLoadMenuTable_0x22:24)
	ld	w, c
	add	w, c
	ld	a, l
	cp	l, w
	jr	nc, SLDstBankList_FuncBody_Skip34
	cp	a, c
	jr	nc, SLDstBankList_FuncBody_Skip33
	add	a, c
	ld	(35180:16), a
	jr	SLDstBankList_FuncBody_Join14
SLDstBankList_FuncBody_Skip33:
	ld	(35180:16), w
SLDstBankList_FuncBody_Join14:
	ld	c, (Data_SaveLoadMenuTable_0x22:24)
	ld	xwa, xiz
	calr	SLDstBankList_FuncBody_Helper10
	ld	c, (Data_SaveLoadMenuTable_0x22:24)
	ld	xwa, xiz
	calr	SLDstBankList_FuncBody_Helper11
	ld	c, (Data_SaveLoadMenuTable_0x22:24)
	pushw 0
	pushw 35180
	ld	xwa, (xsp+8)
	ld	xde, 35172
	jr	SLDstBankList_FuncBody_Join16
SLDstBankList_FuncBody_Skip34:
	cp	xde, EVT_INDEXSW_DOWN
	jr	nz, SLDstBankList_FuncBody_Skip36
	ld	c, l
	ld	e, (Data_SaveLoadMenuTable_0x22:24)
	cp	l, e
	jr	c, SLDstBankList_FuncBody_Skip36
	ld	a, e
	add	a, e
	cp	c, a
	jr	nc, SLDstBankList_FuncBody_Skip35
	sub	c, e
	ld	(35180:16), c
	jr	SLDstBankList_FuncBody_Join15
SLDstBankList_FuncBody_Skip35:
	cp	c, a
	jr	c, SLDstBankList_FuncBody_Join15
	ld	(35180:16), e
SLDstBankList_FuncBody_Join15:
	ld	c, (Data_SaveLoadMenuTable_0x22:24)
	ld	xwa, xiz
	calr	SLDstBankList_FuncBody_Helper10
	ld	c, (Data_SaveLoadMenuTable_0x22:24)
	ld	xwa, xiz
	calr	SLDstBankList_FuncBody_Helper11
	ld	c, (Data_SaveLoadMenuTable_0x22:24)
	pushw 0
	pushw 35180
	ld	xwa, (xsp+8)
	ld	xde, 35172
SLDstBankList_FuncBody_Join16:
	calr	SLSrcBankList_FuncBody_Helper14
SLDstBankList_FuncBody_Skip36:
	ld	xwa, (33104:16)
	cp	xwa, (xsp+0x4)
	jr	z, SLDstBankList_FuncBody_Loop4
	lda	xde, (35099:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (35141:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
SLDstBankList_FuncBody_Join17:
	call	ApPostEvent
	ld	xwa, (xsp+4)
	ld	(33104:16), xwa
SLDstBankList_FuncBody_Loop4:
	ld	xhl, 0:i3
	jrl	SLDstBankList_FuncBody_Epilogue4
SLDstBankList_FuncBody_Skip37:
	ld	xwa, (xsp+4)
	cp	xwa, 8
	jrl	nz, SLDstBankList_FuncBody_Skip42
	ld	xde, xbc
	cp	xbc, EVT_INDEXSW_UP
	jr	nz, SLDstBankList_FuncBody_Skip39
	ld	c, l
	ld	a, l
	inc	1, a
	cp a, (15338004:24)
	jr	nc, SLDstBankList_FuncBody_Skip39
	ld	e, (Data_SaveLoadMenuTable_0x22:24)
	ld	a, e
	add	a, e
	cp	c, a
	jr	nc, SLDstBankList_FuncBody_Skip38
	ld	l, e
	ld	a, c
	extz	wa
	div	wa, l
	ld	a, w
	inc	1, a
	cp	a, e
	jrl	nc, SLDstBankList_FuncBody_Skip41
	inc	1, c
	ld	(35180:16), c
	ld	c, (Data_SaveLoadMenuTable_0x22:24)
	ld	xwa, xiz
	calr	SLDstBankList_FuncBody_Helper11
	ld	c, (Data_SaveLoadMenuTable_0x22:24)
	pushw 0
	pushw 35180
	ld	xwa, (xsp+8)
	ld	xde, 35172
	jrl	SLDstBankList_FuncBody_Join18
SLDstBankList_FuncBody_Skip38:
	inc	1, c
	ld	(35180:16), c
	ld	c, (Data_SaveLoadMenuTable_0x22:24)
	ld	xwa, xiz
	calr	SLDstBankList_FuncBody_Helper11
	ld	c, (Data_SaveLoadMenuTable_0x22:24)
	pushw 0
	pushw 35180
	ld	xwa, (xsp+8)
	ld	xde, 35172
	jr	SLDstBankList_FuncBody_Join18
SLDstBankList_FuncBody_Skip39:
	cp	xde, EVT_INDEXSW_DOWN
	jr	nz, SLDstBankList_FuncBody_Skip41
	ld	c, l
	cp	l, 0:i3
	jr	z, SLDstBankList_FuncBody_Skip41
	ld	e, (Data_SaveLoadMenuTable_0x22:24)
	ld	a, e
	add	a, e
	cp	c, a
	jr	nc, SLDstBankList_FuncBody_Skip40
	ld	a, c
	extz	wa
	div	wa, e
	ld	a, w
	cp	a, 0:i3
	jr	z, SLDstBankList_FuncBody_Skip41
	dec	1, c
	ld	(35180:16), c
	ld	c, (Data_SaveLoadMenuTable_0x22:24)
	ld	xwa, xiz
	calr	SLDstBankList_FuncBody_Helper11
	ld	c, (Data_SaveLoadMenuTable_0x22:24)
	pushw 0
	pushw 35180
	ld	xwa, (xsp+8)
	ld	xde, 35172
	jr	SLDstBankList_FuncBody_Join18
SLDstBankList_FuncBody_Skip40:
	cp	c, a
	jr	ule, SLDstBankList_FuncBody_Skip41
	dec	1, c
	ld	(35180:16), c
	ld	c, (Data_SaveLoadMenuTable_0x22:24)
	ld	xwa, xiz
	calr	SLDstBankList_FuncBody_Helper11
	ld	c, (Data_SaveLoadMenuTable_0x22:24)
	pushw 0
	pushw 35180
	ld	xwa, (xsp+8)
	ld	xde, 35172
SLDstBankList_FuncBody_Join18:
	calr	SLSrcBankList_FuncBody_Helper14
SLDstBankList_FuncBody_Skip41:
	ld	xwa, (33104:16)
	cp	xwa, (xsp+0x4)
	jrl	z, SLDstBankList_FuncBody_Loop4
	lda	xde, (35099:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (35141:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	jrl	SLDstBankList_FuncBody_Join17
SLDstBankList_FuncBody_Skip42:
	ld	xwa, (xsp+4)
	cp	xwa, 5
	jr	z, SLDstBankList_FuncBody_Skip43
	cp	xwa, 6
	jr	nz, SLDstBankList_FuncBody_Skip44
SLDstBankList_FuncBody_Skip43:
	ld	xwa, (33104:16)
	cp	xwa, (xsp+0x4)
	jrl	z, SLDstBankList_FuncBody_Loop4
	lda	xde, (35099:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	lda	xde, (35141:16)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	jrl	SLDstBankList_FuncBody_Join17
SLDstBankList_FuncBody_Skip44:
	ld	xwa, (xsp+4)
	cp	xwa, 10
	jrl	nz, SLDstBankList_FuncBody_Loop4
	cp	(35166:16), 0
	jr	z, SLDstBankList_FuncBody_Skip45
	ld	a, (35172:16)
	extz	wa
	div	wa, e
	extz	wa
	ld	c, (35180:16)
	extz	bc
	div	bc, e
	extz	bc
	call	SLDstBankList_FuncBody_Helper5
	exts	xhl
	jr	SLDstBankList_FuncBody_Epilogue4
SLDstBankList_FuncBody_Skip45:
	ld	a, (35172:16)
	extz	wa
	ld	c, (35180:16)
	extz	bc
	call	SLDstBankList_FuncBody_Helper4
	exts	xhl
SLDstBankList_FuncBody_Epilogue4:
	pop	xiz
	inc	4, xsp
	ret
	dec	4, xsp
	pushw	iz
	ld	(xsp+2), xwa
	cp	xbc, EVT_PAINT
	jr	nz, SLDstBankList_FuncBody_Skip46
	ld	iz, 0:i3
SLDstBankList_FuncBody_Loop5:
	ld	de, iz
	mul	de, 21
	lda	xbc, (35078:16)
	ld	hl, de
	extz	xhl
	add	xhl, xbc
	ldto_berp	a, 248
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
	lda	xwa, (35078:16)
	extz	xde
	add	xde, xwa
	ld	xwa, (xsp+2)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	inc	1, iz
	cp	iz, 4:i3
	jr	c, SLDstBankList_FuncBody_Loop5
SLDstBankList_FuncBody_Skip46:
	ld	xhl, 0:i3
	popw	iz
	inc	4, xsp
	ret
SingleLoadDstFunc:
	dec	8, xsp
	push	xiz
	ld	(xsp+4), xde
	ld	(xsp+8), xbc
	ld	xiz, xwa
	ld	xwa, (xsp+8)
	cp	xwa, EVT_GET_SELECTED_FILE_NUMBER
	jrl	z, SLDst_ReturnCapture
	cp	xwa, EVT_INDEXSW_DOWN
	jrl	z, SLDst_HandleScroll
	cp	xwa, EVT_INDEXSW_UP
	jrl	z, SLDst_HandleScroll
	cp	xwa, EVT_PARA_DRAW
	jrl	z, SLDst_HandleConfirm
	cp	xwa, EVT_PAINT
	jr	z, SLDst_HandleShow
	cp	xwa, EVT_PS_FILE_NAME_BOX_ID
	jr	nz, SLDst_Return
	ld	xwa, (xsp+4)
	ld	(33108:16), xwa
	ld	wa, 0:i3
	calr	InitializeOperationState
	calr	SignalProgressUpdate
	calr	WP_ScanAvailability
	calr	SignalProgressUpdate
	cp	(35164:16), 1
	jr	z, SLDst_ShowHide_Internal
	ld	xwa, 6357066
	ld	xbc, EVT_SET_VISIBLE
	ld	xde, 1:i3
	jr	SLDst_ShowHide_Dispatch
SLDst_ShowHide_Internal:
	ld xwa, 0x61004a
	ld xbc, EVT_SET_VISIBLE
	ld xde, 0:i3

SLDst_ShowHide_Dispatch:
	call	ApPostEvent
	ld	xwa, (33108:16)
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld	xde, 4294967295
	call	ApPostEvent
	cp	(35164:16), 0
	jr	nz, SLDst_ClearFloppyFlag
	call	FileIO_ValidateWithExtHeader
	cp	hl, 0:i3
	jr	z, SLDst_ClearFloppyFlag
	ld	(35182:16), 1
	jr	SLDst_Return
SLDst_ClearFloppyFlag:
	ld	(35182:16), 0
SLDst_Return:
	ld xhl, 0:i3
	jrl SLDst_Epilogue
SLDst_HandleShow:
	ld	xwa, xiz
	ld	xbc, (xsp+8)
	ld	xde, (xsp+4)
	calr	SingleLoadModeFunc
	ld	xwa, xiz
	ld	xbc, (xsp+8)
	ld	xde, (xsp+4)
	calr	SingleLoadSrcBankFunc
	ld	xwa, xiz
	ld	xbc, (xsp+8)
	ld	xde, (xsp+4)
	calr	SingleLoadSrcMemFunc
	ld	xwa, xiz
	ld	xbc, (xsp+8)
	ld	xde, (xsp+4)
	calr	SingleLoadDstBankFunc
	ld	xwa, xiz
	ld	xbc, (xsp+8)
	ld	xde, (xsp+4)
	calr	SingleLoadDstMemFunc
	ld	xwa, (33108:16)
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld	xde, 4294967295
	call	ApPostEvent
	ld	xwa, 6357046
	ld	xbc, EVT_SET_PARAM
	ld	xde, 0:i3
	call	ApPostEvent
	ld	xwa, (33108:16)
	ld	c, (35164:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLDst_HandleShow_PtrTable:24)
	lda_rr	xhl, xde, bc
	ld	xbc, (xsp+8)
	ld	xde, (xsp+4)
	ld	xhl, (xhl)
	call (xhl)
	jrl	SLDst_Return
SLDst_HandleConfirm:
	ld	xwa, (33108:16)
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld	xde, 4294967295
	call	ApPostEvent
	ld	xwa, (33108:16)
	ld	c, (35164:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLDst_HandleShow_PtrTable:24)
	lda_rr	xhl, xde, bc
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	ld	xhl, (xhl)
	call (xhl)
	jrl	SLDst_Return
SLDst_HandleScroll:
	ld	xwa, (xsp+4)
	cp	xwa, 3
	jr	nz, SLDst_ScrollMode4
	cp	(35164:16), 1
	jr	z, SLDst_ScrollMode4
	ld	xwa, (xsp+8)
	cp	xwa, EVT_INDEXSW_UP
	scc	z, a
	ld	(35166:16), a
	ld	xwa, xiz
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	calr	SingleLoadSrcMemFunc
	ld	xwa, xiz
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	calr	SingleLoadDstMemFunc
	ld	xwa, (33108:16)
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld	xde, 4294967295
	call	ApPostEvent
	ld	xwa, 6357046
	ld	xbc, EVT_SET_PARAM
	ld	xde, 0:i3
	call	ApPostEvent
	ld	xwa, (33108:16)
	ld	c, (35164:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLDst_HandleShow_PtrTable:24)
	lda_rr	xhl, xde, bc
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	ld	xhl, (xhl)
	call (xhl)
	ld	xwa, xiz
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	jrl	SLDst_ScrollMode3_CallSrcMem
SLDst_ScrollMode4:
	ld	xwa, (xsp+4)
	cp	xwa, 4
	jrl	nz, SLDst_ScrollDispatch
	calr	WP_FindNextSlot
	cp	l, 0:i3
	jrl	z, SLDst_Return
	cp	(35164:16), 1
	jr	z, SLDst_ScrollMode4_Internal
	ld	xwa, 6357066
	ld	xbc, EVT_SET_VISIBLE
	ld	xde, 1:i3
	jr	SLDst_ScrollMode4_Dispatch
SLDst_ScrollMode4_Internal:
	ld xwa, 0x61004a
	ld xbc, EVT_SET_VISIBLE
	ld xde, 0:i3

SLDst_ScrollMode4_Dispatch:
	call	ApPostEvent
	ld	xwa, xiz
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	calr	SingleLoadModeFunc
	ld	xwa, xiz
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	calr	SingleLoadSrcBankFunc
	ld	xwa, xiz
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	calr	SingleLoadSrcMemFunc
	ld	xwa, xiz
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	calr	SingleLoadDstBankFunc
	ld	xwa, xiz
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	calr	SingleLoadDstMemFunc
	ld	xwa, (33108:16)
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld	xde, 4294967295
	call	ApPostEvent
	ld	xwa, 6357046
	ld	xbc, EVT_SET_PARAM
	ld	xde, 0:i3
	call	ApPostEvent
	ld	xwa, (33108:16)
	ld	c, (35164:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLDst_HandleShow_PtrTable:24)
	lda_rr	xhl, xde, bc
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	ld	xhl, (xhl)
	call	(xhl)
	ld	xwa, xiz
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
SLDst_ScrollMode3_CallSrcMem:
	calr SingleLoadSrcFunc
	jrl SLDst_Return
SLDst_ScrollDispatch:
	ld	xwa, (xsp+4)
	cp	xwa, 10
	jr	nz, SLDst_Scroll_ChildReturn
	cp	(35164:16), 4
	jr	z, SLDst_Scroll_ChildReturn
	ld	xwa, 6291494
	ld	xbc, EVT_SHOW
	ld	xde, 5:i3
	call	ApPostEvent
	ld	wa, 0:i3
	calr	InitializeOperationState
	ld	xwa, (33108:16)
	ld	c, (35164:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLDst_HandleShow_PtrTable:24)
	lda_rr	xhl, xde, bc
	ld	xbc, (xsp+8)
	ld	xde, (xsp+4)
	ld	xix, (xhl)
	call (xix)
	ld	wa, hl
	ld	bc, 1:i3
	calr	FileIO_ValidateSignedValue
	ld	(32422:16), l
	ld	xwa, 6291494
	ld	xbc, EVT_HIDE
	ld	xde, 0:i3
	call	ApPostEvent
	ldw	wa, 238
	call	SoundCtrl_SendCommand
	jrl	SLDst_Return
SLDst_Scroll_ChildReturn:
	ld	xwa, (xsp+4)
	cp	xwa, 7
	jr	nz, SLDst_Scroll_SubMode2
	cp	(35164:16), 1
	jr	z, SLDst_Scroll_SubMode
	ld	xwa, (33108:16)
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld	xde, 1:i3
	call	ApPostEvent
	ld	xwa, (33108:16)
	ld	c, (35164:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLDst_HandleShow_PtrTable:24)
	lda_rr	xhl, xde, bc
	ld	xbc, (xsp+8)
	ld	xde, (xsp+4)
	ld	xhl, (xhl)
	call (xhl)
	jrl	SLDst_Return
SLDst_Scroll_SubMode:
	ld	xwa, (33108:16)
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld	xde, 4294967295
	call	ApPostEvent
	ld	xwa, (33108:16)
	ld	c, (35164:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLDst_HandleShow_PtrTable:24)
	lda_rr	xhl, xde, bc
	ld	xbc, (xsp+8)
	ld	xde, (xsp+4)
	ld	xhl, (xhl)
	call (xhl)
	jrl	SLDst_Return
SLDst_Scroll_SubMode2:
	ld	xwa, (33108:16)
	ld	xbc, (xsp+4)
	cp	xbc, 8
	jrl	nz, SLDst_Scroll_SubMode5
	cp	(35164:16), 1
	jr	nz, SLDst_Scroll_SubMode3
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld	xde, 2:i3
	call	ApPostEvent
	ld	xwa, (33108:16)
	ld	c, (35164:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLDst_HandleShow_PtrTable:24)
	lda_rr	xhl, xde, bc
	ld	xbc, (xsp+8)
	ld	xde, (xsp+4)
	ld	xhl, (xhl)
	call (xhl)
	jrl	SLDst_Return
SLDst_Scroll_SubMode3:
	cp	(35166:16), 0
	jr	nz, SLDst_Scroll_SubMode4
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld	xde, 3:i3
	call	ApPostEvent
	ld	xwa, (33108:16)
	ld	c, (35164:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLDst_HandleShow_PtrTable:24)
	lda_rr	xhl, xde, bc
	ld	xbc, (xsp+8)
	ld	xde, (xsp+4)
	ld	xhl, (xhl)
	call (xhl)
	jrl	SLDst_Return
SLDst_Scroll_SubMode4:
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld	xde, 4294967295
	call	ApPostEvent
	ld	xwa, (33108:16)
	ld	c, (35164:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLDst_HandleShow_PtrTable:24)
	lda_rr	xhl, xde, bc
	ld	xbc, (xsp+8)
	ld	xde, (xsp+4)
	ld	xhl, (xhl)
	call (xhl)
	jrl	SLDst_Return
SLDst_Scroll_SubMode5:
	ld	xbc, (xsp+4)
	cp	xbc, 5
	jr	nz, SLDst_Scroll_SubMode6
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld	xde, 4294967295
	call	ApPostEvent
	ld	xwa, (33108:16)
	ld	c, (35164:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLDst_HandleShow_PtrTable:24)
	lda_rr	xhl, xde, bc
	ld	xbc, (xsp+8)
	ld	xde, (xsp+4)
	ld	xhl, (xhl)
	call (xhl)
	jrl	SLDst_Return
SLDst_Scroll_SubMode6:
	ld	xbc, (xsp+4)
	cp	xbc, 6
	jrl	nz, SLDst_Return
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld	xde, 4294967295
	call	ApPostEvent
	ld	xwa, (33108:16)
	ld	c, (35164:16)
	extz	bc
	sla	bc, 2
	lda	xde, (SLDst_HandleShow_PtrTable:24)
	lda_rr	xhl, xde, bc
	ld	xbc, (xsp+8)
	ld	xde, (xsp+4)
	ld	xhl, (xhl)
	call (xhl)
	jrl	SLDst_Return
SLDst_ReturnCapture:
	ld xhl, 0xffffffff

SLDst_Epilogue:
	pop xiz
	inc 8, xsp
	ret

CmpSingleLoadSrcFunc:
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xde
	ld	xiz, xbc
	cp	xiz, EVT_GET_SELECTED_FILE_NUMBER
	jrl	z, CmpSrc_ReturnCapture
	cp	xiz, EVT_INDEXSW_DOWN
	jr	z, CmpSrc_HandleScroll
	cp	xiz, EVT_INDEXSW_UP
	jr	z, CmpSrc_HandleScroll
	cp	xiz, EVT_PAINT
	jr	z, CmpSrc_HandleShow
	cp	xiz, EVT_PS_FILE_NAME_BOX_ID
	jrl	nz, CmpSrc_Return
	ld	xwa, (xsp+4)
	ld	(33112:16), xwa
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld	xde, 4294967295
	call	ApPostEvent
	jrl	CmpSrc_Return
CmpSrc_HandleShow:
	ld	xwa, (33112:16)
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld	xde, 4294967295
	call	ApPostEvent
	ld	xwa, (33112:16)
	ld	c, (35164:16)
	extz	bc
	sla	bc, 2
	lda	xde, (CmpSrc_HandleShow_PtrTable:24)
	lda_rr	xhl, xde, bc
	ld	xbc, xiz
	ld	xde, (xsp+4)
	ld	xhl, (xhl)
	call	(xhl)
	jrl	CmpSrc_Return	; -> 0xF9105C
CmpSrc_HandleScroll:
	ld	xwa, (xsp+4)
	cp	xwa, 5
	jr	nz, CmpSrc_ScrollMode6	; -> 0xF90F3B
	ld	xwa, (33112:16)
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld	xde, 1:i3
	call	ApPostEvent
	ld	xwa, (33112:16)
	ld	c, (35164:16)
	extz	bc
	sla	bc, 2
	lda	xde, (CmpSrc_HandleShow_PtrTable:24)
	lda_rr	xhl, xde, bc
	ld	xbc, xiz
	ld	xde, (xsp+4)
	ld	xhl, (xhl)
	call	(xhl)
	jrl	CmpSrc_Return	; -> 0xF9105C
CmpSrc_ScrollMode6:
	ld	xwa, (xsp + 4)
	cp	xwa, 0x6
	jr	nz, CmpSrc_ScrollMode7
	cp	(0x895e:16), 0
	jr	nz, CmpSrc_ScrollMode6_NoStep
	ld	xwa, (0x8158:16)
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld	xde, 3:i3
	call	ApPostEvent
	ld	xwa, (0x8158:16)
	ld	c, (0x895c:16)
	extz	bc
	sla	bc, 2
	lda	xde, (CmpSrc_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld	xbc, xiz
	ld	xde, (xsp + 4)
	ld	xhl, (xhl)
	call	(xhl)
	jrl	CmpSrc_Return
CmpSrc_ScrollMode6_NoStep:
	ld	xwa, (33112:16)
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld	xde, 4294967295
	call	ApPostEvent
	ld	xwa, (33112:16)
	ld	c, (35164:16)
	extz	bc
	sla	bc, 2
	lda	xde, (CmpSrc_HandleShow_PtrTable:24)
	lda_rr	xhl, xde, bc
	ld	xbc, xiz
	ld	xde, (xsp+4)
	ld	xhl, (xhl)
	call	(xhl)
	jrl	CmpSrc_Return	; -> 0xF9105C
CmpSrc_ScrollMode7:
	ld	xwa, (33112:16)
	ld	xbc, (xsp+4)
	cp	xbc, 7
	jr	nz, CmpSrc_ScrollMode8	; -> 0xF90FF3
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld	xde, 4294967295
	call	ApPostEvent
	ld	xwa, (33112:16)
	ld	c, (35164:16)
	extz	bc
	sla	bc, 2
	lda	xde, (CmpSrc_HandleShow_PtrTable:24)
	lda_rr	xhl, xde, bc
	ld	xbc, xiz
	ld	xde, (xsp+4)
	ld	xhl, (xhl)
	call	(xhl)
	jr	CmpSrc_Return	; -> 0xF9105C
CmpSrc_ScrollMode8:
	ld	xbc, (xsp + 4)
	cp	xbc, 0x8
	jr	nz, CmpSrc_ScrollMode40
	cp	(0x895e:16), 0
	jr	nz, CmpSrc_ScrollMode40
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld	xde, 0xffffffff
	call	ApPostEvent
	ld	xwa, (0x8158:16)
	ld	c, (0x895c:16)
	extz	bc
	sla	bc, 2
	lda	xde, (CmpSrc_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld	xbc, xiz
	ld	xde, (xsp + 4)
	ld	xhl, (xhl)
	call	(xhl)
	jr	CmpSrc_Return
CmpSrc_ScrollMode40:
	ld	xbc, (xsp+4)
	cp	xbc, 40
	jr	nz, CmpSrc_Return	; -> 0xF9105C
	ld	c, (35164:16)
	extz	bc
	sla	bc, 2
	lda	xde, (CmpSrc_HandleShow_PtrTable:24)
	lda_rr	xhl, xde, bc
	ld	xbc, xiz
	ld	xde, (xsp+4)
	ld	xhl, (xhl)
	call	(xhl)
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
	dec	8, xsp
	push	xiz
	ld	(xsp+4), xde
	ld	(xsp+8), xbc
	ld	xiz, xwa
	ld	xwa, (xsp+8)
	cp	xwa, EVT_GET_SELECTED_FILE_NUMBER
	jrl	z, CmpDst_ReturnCapture
	cp	xwa, EVT_INDEXSW_DOWN
	jrl	z, CmpDst_HandleScroll
	cp	xwa, EVT_INDEXSW_UP
	jrl	z, CmpDst_HandleScroll
	cp	xwa, EVT_PAINT
	jr	z, CmpDst_HandleShow
	cp	xwa, EVT_PS_FILE_NAME_BOX_ID
	jrl	nz, CmpDst_Return
	ld	xwa, (xsp+4)
	ld	(33116:16), xwa
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld	xde, 4294967295
	call	ApPostEvent
	jrl	CmpDst_Return
CmpDst_HandleShow:
	ld	xwa, xiz
	ld	xbc, (xsp+8)
	ld	xde, (xsp+4)
	calr	SingleLoadSrcMemFunc
	ld	xwa, xiz
	ld	xbc, (xsp+8)
	ld	xde, (xsp+4)
	calr	SingleLoadSrcBankFunc
	ld	xwa, xiz
	ld	xbc, (xsp+8)
	ld	xde, (xsp+4)
	calr	SingleLoadDstMemFunc
	ld	xwa, xiz
	ld	xbc, (xsp+8)
	ld	xde, (xsp+4)
	calr	SingleLoadDstBankFunc
	ld	xwa, (33116:16)
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld	xde, 4294967295
	call	ApPostEvent
	ld	xwa, 6357118
	ld	xbc, EVT_SET_PARAM
	ld	xde, 0:i3
	call	ApPostEvent
	ld	xwa, (33116:16)
	ld	c, (35164:16)
	extz	bc
	sla	bc, 2
	lda	xde, (CmpDst_HandleShow_PtrTable:24)
	lda_rr	xhl, xde, bc
	ld	xbc, (xsp+8)
	ld	xde, (xsp+4)
	ld	xhl, (xhl)
	call	(xhl)
	jrl	CmpDst_Return	; -> 0xF91350
CmpDst_HandleScroll:
	ld XWA,(XSP+0x04)
	cp XWA,0x00000003
	jr nz, .Lc_f911b2
	ld XWA,(XSP+0x08)
	cp XWA,EVT_INDEXSW_UP
	scc Z,A
	ld (0x895e:16), a
	ld XWA,XIZ
	ld XBC,EVT_PAINT
	ld xde, 0:i3
	calr SingleLoadSrcMemFunc
	ld XWA,XIZ
	ld XBC,EVT_PAINT
	ld xde, 0:i3
	calr SingleLoadDstMemFunc
	ld xwa, (0x815c:16)
	ld XBC,EVT_SET_SELECTED_FILE_NUMBER
	ld XDE,0xffffffff
	call ApPostEvent
	ld XWA,0x0061007e
	ld XBC,EVT_SET_PARAM
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, (0x815c:16)
	ld c, (0x895c:16)
	extz BC
	sla BC, 0x02
	lda xde, (CmpDst_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld XBC,EVT_PAINT
	ld xde, 0:i3
	ld XHL,(XHL)
	call (XHL)
	ld XWA,XIZ
	ld XBC,EVT_PAINT
	ld xde, 0:i3
	calr CmpSingleLoadSrcFunc
	jrl t, CmpDst_Return
CmpDst_ScrollModeA:
.Lc_f911b2:
	ld XWA,(XSP+0x04)
	cp XWA,0x0000000a
	jr nz, .Lc_f9121f
	cp (0x895c:16), 0x04
	jr z, .Lc_f9121f
	ld XWA,0x00600026
	ld XBC,EVT_SHOW
	ld xde, 5:i3
	call ApPostEvent
	ld wa, 0:i3
	calr InitializeOperationState
	ld xwa, (0x815c:16)
	ld c, (0x895c:16)
	extz BC
	sla BC, 0x02
	lda xde, (CmpDst_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld XBC,(XSP+0x08)
	ld XDE,(XSP+0x04)
	ld XIX,(XHL)
	call (XIX)
	ld WA,HL
	ld bc, 1:i3
	calr FileIO_ValidateSignedValue
	ld (0x7ea6:16), l
	ld XWA,0x00600026
	ld XBC,EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	ldw WA, 0x00ee
	call SoundCtrl_SendCommand
	jrl t, CmpDst_Return
CmpDst_ScrollMode7:
.Lc_f9121f:
	ld XWA,(XSP+0x04)
	cp XWA,0x00000007
	jr nz, .Lc_f9125d
	ld xwa, (0x815c:16)
	ld XBC,EVT_SET_SELECTED_FILE_NUMBER
	ld xde, 1:i3
	call ApPostEvent
	ld xwa, (0x815c:16)
	ld c, (0x895c:16)
	extz BC
	sla BC, 0x02
	lda xde, (CmpDst_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld XBC,(XSP+0x08)
	ld XDE,(XSP+0x04)
	ld XHL,(XHL)
	call (XHL)
	jrl t, CmpDst_Return
CmpDst_ScrollMode8:
.Lc_f9125d:
	ld xwa, (0x815c:16)
	ld XBC,(XSP+0x04)
	cp XBC,0x00000008
	jr nz, .Lc_f912d3
	cp (0x895e:16), 0x00
	jr nz, .Lc_f912a2
	ld XBC,EVT_SET_SELECTED_FILE_NUMBER
	ld xde, 3:i3
	call ApPostEvent
	ld xwa, (0x815c:16)
	ld c, (0x895c:16)
	extz BC
	sla BC, 0x02
	lda xde, (CmpDst_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld XBC,(XSP+0x08)
	ld XDE,(XSP+0x04)
	ld XHL,(XHL)
	call (XHL)
	jrl t, CmpDst_Return
CmpDst_ScrollMode8_NoStep:
.Lc_f912a2:
	ld XBC,EVT_SET_SELECTED_FILE_NUMBER
	ld XDE,0xffffffff
	call ApPostEvent
	ld xwa, (0x815c:16)
	ld c, (0x895c:16)
	extz BC
	sla BC, 0x02
	lda xde, (CmpDst_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld XBC,(XSP+0x08)
	ld XDE,(XSP+0x04)
	ld XHL,(XHL)
	call (XHL)
	jr t, CmpDst_Return
CmpDst_ScrollMode5:
.Lc_f912d3:
	ld XBC,(XSP+0x04)
	cp XBC,0x00000005
	jr nz, .Lc_f9130f
	ld XBC,EVT_SET_SELECTED_FILE_NUMBER
	ld XDE,0xffffffff
	call ApPostEvent
	ld xwa, (0x815c:16)
	ld c, (0x895c:16)
	extz BC
	sla BC, 0x02
	lda xde, (CmpDst_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld XBC,(XSP+0x08)
	ld XDE,(XSP+0x04)
	ld XHL,(XHL)
	call (XHL)
	jr t, CmpDst_Return
CmpDst_ScrollMode6:
.Lc_f9130f:
	ld XBC,(XSP+0x04)
	cp XBC,0x00000006
	jr nz, CmpDst_Return
	cp (0x895e:16), 0x00
	jr nz, CmpDst_Return
	ld XBC,EVT_SET_SELECTED_FILE_NUMBER
	ld XDE,0xffffffff
	call ApPostEvent
	ld xwa, (0x815c:16)
	ld c, (0x895c:16)
	extz BC
	sla BC, 0x02
	lda xde, (CmpDst_HandleShow_PtrTable:24)
	lda	xhl, (xde+bc)
	ld XBC,(XSP+0x08)
	ld XDE,(XSP+0x04)
	ld XHL,(XHL)
	call (XHL)
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
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xwa
	cp	xbc, EVT_INDEXSW_DOWN
	jrl	z, CmpFile_HandleScroll
	cp	xbc, EVT_INDEXSW_UP
	jr	z, CmpFile_HandleScroll
	cp	xbc, EVT_PAINT
	jr	z, CmpFile_HandleShow
	cp	xbc, EVT_PS_FILE_NAME_BOX_ID
	jrl	nz, CmpFile_Return
	ld	(33120:16), xde
	call	GetCurrentFileIndex
	ld	(33124:16), hl
	cp	hl, 0:i3
	jr	ge, CmpFile_Selection_Clamp
	ldw	(33124:16), 0
CmpFile_Selection_Clamp:
	ld	xwa, (33120:16)
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld	xde, 4294967295
	jr	CmpFile_ShowDispatch
CmpFile_HandleShow:
	ld	(34772:16), 0
	cp	(35164:16), 2
	jr	nz, CmpFile_ShowDefault
	ld	wa, (33124:16)
	call	GetFileEntryPtr
	ld	xiz, xhl
	jr	CmpFile_ShowDraw
CmpFile_ShowDefault:
	lda xiz, (Data_SaveLoadMenuTable_0x62:24)

CmpFile_ShowDraw:
	lda	xwa, (34773:16)
	ld	de, (33124:16)
	inc	1, de
	pushw	6
	pushw	0
	ld	xbc, xiz
	call	FileIO_ReadHeader_ParseLoop
	ld	xwa, (33120:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 34772
CmpFile_ShowDispatch:
	call ApPostEvent
	jrl CmpFile_Return

CmpFile_HandleScroll:
	ld	wa, (33124:16)
	ld	hl, wa
	or	xde, xde
	jr	nz, CmpFile_ScrollDown
	ld	bc, wa
	inc	1, bc
	cp	bc, 20
	jr	ge, CmpFile_ScrollRedraw
	inc	1, wa
	jr	CmpFile_ScrollStore
CmpFile_ScrollDown:
	cp xde, 0x1
	jr nz, CmpFile_ScrollRedraw
	cp wa, 0:i3
	jr le, CmpFile_ScrollRedraw
	dec 1, wa

CmpFile_ScrollStore:
	ld	(33124:16), wa
CmpFile_ScrollRedraw:
	ld	wa, (33124:16)
	cp	wa, hl
	jr	z, CmpFile_Return
	call	NotifyUIOfSelectionChange
	ld	(34772:16), 0
	lda	xiz, (Data_SaveLoadMenuTable_0x62:24)
	ld	(35164:16), 4
	ld	wa, 3:i3
	call	FileIO_CheckRecordValid
	cp	l, 0:i3
	jr	z, CmpFile_RedrawDispatch
	call	FileIO_ValidateAndOpenFile
	cp	hl, 0:i3
	jr	z, CmpFile_RedrawDispatch
	ld	(35164:16), 2
	ld	wa, (33124:16)
	call	GetFileEntryPtr
	ld	xiz, xhl
CmpFile_RedrawDispatch:
	lda	xwa, (34773:16)
	ld	de, (33124:16)
	inc	1, de
	pushw	6
	pushw	0
	ld	xbc, xiz
	call	FileIO_ReadHeader_ParseLoop
	ld	xwa, (33120:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 34772
	call	ApPostEvent
	ld	xwa, (xsp+4)
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	calr	CmpSingleLoadSrcFunc
	ld	xwa, (xsp+4)
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	calr	CmpSingleLoadDstFunc
CmpFile_Return:
	ld xhl, 0:i3
	pop xiz
	inc 4, xsp
	ret
FmmCmpSingleLoadFunc:
	cp	xbc, EVT_ACTIVATE_STATE
	jrl	nz, FmmCmpLoad_Return
	cp	xde, 3
	jrl	z, FmmCmpLoad_HandleAbort
	cp	xde, 2
	jrl	nz, FmmCmpLoad_Return
	ld	wa, 1:i3
	calr	InitializeOperationState
	ld	xwa, 6357066
	ld	xbc, EVT_SET_VISIBLE
	ld	xde, 1:i3
	call	ApPostEvent
	ld	xwa, 6291494
	ld	xbc, EVT_SHOW
	ld	xde, 5:i3
	call	ApPostEvent
	cpw	(33892:16), 0
	jr	ge, FmmCmpLoad_DispatchState
	call	GetDiskSizeInfo
	extz	hl
	ld	(33892:16), hl
	calr	SignalProgressUpdate
FmmCmpLoad_DispatchState:
	ld	wa, (33892:16)
	cp	wa, 1:i3
	jrl	z, FmmCmpLoad_HandleSuccess
	cp	wa, 0:i3
	jrl	z, FmmCmpLoad_HandleError
	cp	wa, 5:i3
	jr	z, FmmCmpLoad_HandleCancel
	cpw	(33894:16), 0
	jr	ge, FmmCmpLoad_ContinueLoad
	call	GetEncodedFileSizeData
	ld	(33894:16), hl
	call	FileIO_SearchAndLoadFile
	call	GetEncodedFreeSpaceData
	calr	SignalProgressUpdate
FmmCmpLoad_ContinueLoad:
	ld	(35164:16), 4
	ld	wa, 3:i3
	call	FileIO_CheckRecordValid
	cp	l, 0:i3
	jr	z, FmmCmpLoad_CloseProgress
	call	FileIO_ValidateAndOpenFile
	cp	hl, 0:i3
	jr	z, FmmCmpLoad_SignalProgress
	ld	(35164:16), 2
FmmCmpLoad_SignalProgress:
	calr SignalProgressUpdate

FmmCmpLoad_CloseProgress:
	ld	xwa, 6291494
	ld	xbc, EVT_HIDE
	ld	xde, 0:i3
	call	ApPostEvent
	ld	xwa, 4294967295
	ld	xbc, EVT_ALL_PAINT
	ld	xde, 0:i3
	call	ApPostEvent
	ld	(35170:16), 0
	ld	(35178:16), 0
	jr	FmmCmpLoad_Return
FmmCmpLoad_HandleCancel:
	ld	xwa, 6291494
	ld	xbc, EVT_HIDE
	ld	xde, 0:i3
	call	ApPostEvent
	ldw	wa, 176
	call	UI_PostModeChangeEvent
	ld	(32422:16), 0
	ldw	wa, 238
	jr	FmmCmpLoad_CallStatusDisplay
FmmCmpLoad_HandleError:
	ld xwa, 0x600026
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	ldw wa, 0x7d
	call UI_PostModeChangeEvent
	jr FmmCmpLoad_Return

FmmCmpLoad_HandleSuccess:
	calr	ResetProgressIndication
	ld	xwa, 6291494
	ld	xbc, EVT_HIDE
	ld	xde, 0:i3
	call	ApPostEvent
	ldw	wa, 176
	call	UI_PostModeChangeEvent
	ld	(32422:16), 2
	ldw	wa, 238
FmmCmpLoad_CallStatusDisplay:
	call SoundCtrl_SendCommand
	jr FmmCmpLoad_Return

FmmCmpLoad_HandleAbort:
	calr CancelOperationCleanup

FmmCmpLoad_Return:
	ld xhl, 0:i3
	ret

BuildSlotLabel:
	dec 2,XSP
	push XIZ
	ld HL,BC
	ld (XSP+0x04),WA
	lda xbc, (0x0ab000:24)
	ld WA,(XSP+0x04)
	extz XWA
	sll XWA, 0x0b
	add XBC,XWA
	lda	xbc, (xbc+256)
	ld	wa, (xsp + 4)
	mul	wa, 0x15
	lda	xix, (0x8166:16)
	ld	iz, wa
	extz	xiz
	add	xiz, xix
	ld	(xiz+), l
	cp	e, 0:i3
	jr	z, BuildSlotLabel_WriteContent
	cpw	(xsp + 4), 0x9
	jr	nz, BuildSlotLabel_WriteLetter
	ld	(xiz+), 0x31
	ld	(xiz), 0x30
	jr	BuildSlotLabel_WriteColon
BuildSlotLabel_WriteLetter:
	ld (xiz+), 0x20
	ld wa, (xsp + 4)
	add a, 0x31
	ld (xiz), a

BuildSlotLabel_WriteColon:
	inc 1, xiz
	ld (xiz+), 0x3a

BuildSlotLabel_WriteContent:
	; Disassembled from the committed romslice (no source of any kind existed):
	; llvm-mc round-trips these 34 B byte-exact. v9/v10's BuildSlotLabel_WriteContent
	; is line-for-line identical in shape (ld xwa,xiz / ldw de,0x10 /
	; call FileIO_CopyString_WriteNull / ld (xiz+16),0x0 / ...); the call target
	; and table-base address are left numeric because this v7 link doesn't name them.
	ld	xwa, xiz
	ldw	de, 16
	call	FileIO_CopyString_WriteNull
	ld	(xiz+16), 0
	ld	wa, (xsp+4)
	mul	wa, 21
	lda	xbc, (33126:16)
	extz	xwa
	add	xwa, xbc
	ld	xhl, xwa
	pop	xiz
	inc	2, xsp
	ret
