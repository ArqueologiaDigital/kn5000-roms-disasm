; =============================================================================
; Scoop Editor & Display Parameter Data (1.2K lines)
; =============================================================================
;
; Sound editor display data, performance mode parameter
; bytecode, Scoop oscilloscope editor configuration tables,
; and display dirty-region data.
; =============================================================================



Scoop_SoundEditorData:
	jp	SeMenu_CopyWriteUpdate_Data_0xFA
	jp	SeMenu_CopyWriteUpdate_Data_0x348
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	call	SeMenu_CopyWriteUpdate_Data_0x1DD6
Scoop_SoundEditorData_Join:
	ld	wa, 1:i3
	call	AudioLock_GetCount
	cp	hl, 0:i3
	jr	z, Scoop_SoundEditorData_Skip
	ld	wa, 3:i3
	call	TaskSched_YieldToQueue
	jr	Scoop_SoundEditorData_Join
Scoop_SoundEditorData_Skip:
	ld	xwa, 0:i3
	ld	xbc, 0x01c00007
	jp	DeleteEvent
	jp	SeMenu_CopyWriteUpdate_Data_0x349
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeMenu_SetupPartDisplay_End_0x90
	cp	hl, 0xffff
	jr	z, Scoop_SoundEditorData_Epilogue
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda	xde, (GUI_DisplayStructData_0xCD8:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
Scoop_SoundEditorData_Epilogue:
	inc	4, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeMenu_SetupPartDisplay_End_0x90
	cp	hl, 0xffff
	jr	z, Scoop_SoundEditorData_Epilogue2
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda	xde, (GUI_DisplayStructData_0xD20:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
Scoop_SoundEditorData_Epilogue2:
	inc	4, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeMenu_SetupPartDisplay_End_0x90
	cp	hl, 0xffff
	jr	z, Scoop_SoundEditorData_Epilogue3
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda	xde, (GUI_DisplayStructData_0xD68:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
Scoop_SoundEditorData_Epilogue3:
	inc	4, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeMenu_SetupPartDisplay_End_0x90
	cp	hl, 0xffff
	jr	z, Scoop_SoundEditorData_Epilogue4
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda	xde, (GUI_DisplayStructData_0xDB0:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
Scoop_SoundEditorData_Epilogue4:
	inc	4, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeMenu_SetupPartDisplay_End_0x90
	cp	hl, 0xffff
	jr	z, Scoop_SoundEditorData_Epilogue5
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda	xde, (GUI_DisplayStructData_0xDF8:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
Scoop_SoundEditorData_Epilogue5:
	inc	4, xsp
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+18), a
	lda	xwa, (xsp+14)
	call	SeMenu_LoadObjEntries
	lda	xwa, (xsp+16)
	call	SeMenu_ValidatePartNumber
	ld	a, (xsp+16)
	ld	(xsp), a
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xsp+12)
	call	SeMenu_SetupPartDisplay_End_0x219
	lda	xhl, (xsp+2)
	lda	xwa, (xhl+6)
	lda	xbc, (xhl+7)
	lda	xde, (xhl+8)
	lda	xhl, (xhl+9)
	.byte 0x8f
	ret
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Skip2
	ld	(xwa), 127
	ld	(xbc), 0
	ld	(xde), 127
	ld	(xhl), 0
	ld	a, 23:opc
	jr	Scoop_SoundEditorData_Join2
Scoop_SoundEditorData_Skip2:
	ld	(xwa), 255
	ld	(xbc), 0
	ld	(xde), 50
	ld	(xhl), 206
	ld	a, (xsp+16)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	inc	6, xwa
	ld	(xsp+16), 0
Scoop_SoundEditorData_Join2:
	ld	c, (xsp)
	extz	bc
	ld	e, (xsp+16)
	extz	de
	extz	wa
	pushw	wa
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 43
	call	SeMenu_TransferPartValues_EndData_0x169
	.byte 0x8f
	ret
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Skip3
	cp	l, 1:i3
	jr	nz, 14
	ld	a, (xsp+16)
	extz	wa
	ld	c, (xsp+5)
	extz	bc
	call	SeMenu_StoreParamByte
Scoop_SoundEditorData_Skip3:
	ld	wa, 3:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-18)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+18), a
	lda	xwa, (xsp+14)
	call	SeMenu_LoadObjEntries
	lda	xwa, (xsp+16)
	call	SeMenu_ValidatePartNumber
	.byte 0x8f
	ret
	push	xsp
	nop
	jr	nz, 10
	ld	a, (xsp+16)
	inc	4, a
	ldb_erp a, 251
	jr	Scoop_SoundEditorData_Join3
	ld	a, (xsp+16)
	inc	2, a
	ldb_erp a, 251
Scoop_SoundEditorData_Join3:
	stb_erp a, 251
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xsp+12)
	call	SeMenu_SetupPartDisplay_End_0x219
	lda	xhl, (xsp+2)
	lda	xwa, (xhl+6)
	lda	xbc, (xhl+7)
	lda	xde, (xhl+8)
	lda	xhl, (xhl+9)
	.byte 0x8f
	ret
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Skip4
	ld	(xwa), 255
	ld	(xbc), 0
	ld	(xde), 50
	ld	(xhl), 206
	ld	a, 24:opc
	jr	Scoop_SoundEditorData_Join4
Scoop_SoundEditorData_Skip4:
	ld	(xwa), 7
	ld	(xbc), 5
	ld	(xde), 6
	ld	(xhl), 0
	ld	a, (xsp+16)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	inc	7, xwa
	ld	(xsp+16), 0
Scoop_SoundEditorData_Join4:
	stb_erp c, 251
	extz	bc
	ld	e, (xsp+16)
	extz	de
	extz	wa
	pushw	wa
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 43
	call	SeMenu_TransferPartValues_EndData_0x169
	ld	wa, 4:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	pop qiz
	lda	xsp, (xsp+18)
	ret
	lda	xsp, (xsp-18)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+18), a
	lda	xwa, (xsp+14)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	ret
	push	xsp
	normal
	jr	z, 85
	lda	xwa, (xsp+16)
	call	SeMenu_ValidatePartNumber
	ld	a, (xsp+16)
	inc	8, a
	ldb_erp a, 251
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp+2)
	ld	(xbc+6), 7
	ld	(xbc+7), 5
	ld	(xbc+8), 6
	ld	(xbc+9), 0
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	stb_erp c, 251
	extz	bc
	ld	e, (xsp+16)
	extz	de
	pushw	25
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 43
	call	SeMenu_TransferPartValues_EndData_0x169
	ld	wa, 5:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	pop qiz
	lda	xsp, (xsp+18)
	ret
	cp	a, 0:i3
	.byte 0xf2, 0x01
	jr	pl, -16
	.byte 0xde
	ldw	wa, 45
	ld	bc, 0:i3
	jp	SeMenu_SendEvent
	cp	a, 0:i3
	ret	z
	ldw	wa, 43
	ld	bc, 1:i3
	ld	de, 1:i3
	call	SeMenu_ApplyPartEdit_Data2_0x17C1
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, 16
	.byte 0x87
	push	xsp
	normal
	jr	z, 22
	ldw	wa, 47
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	jr	11
	ldw	wa, 43
	ld	bc, 2:i3
	ld	de, 1:i3
	call	SeMenu_ApplyPartEdit_Data2_0x17C1
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x87
	push	xsp
	normal
	jr	z, 17
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	z, 11
	ldw	wa, 43
	ld	bc, 3:i3
	ld	de, 1:i3
	call	SeMenu_ApplyPartEdit_Data2_0x17C1
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x87
	push	xsp
	normal
	jr	z, 17
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	z, 11
	ldw	wa, 43
	ld	bc, 4:i3
	ld	de, 1:i3
	call	SeMenu_ApplyPartEdit_Data2_0x17C1
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x87
	push	xsp
	normal
	jr	z, 15
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, 9
	ldw	wa, 44
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Epilogue6
	.byte 0x87
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Skip5
	ldw	wa, 32
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join5
Scoop_SoundEditorData_Skip5:
	ldw	wa, 61
	ld	bc, 0:i3
Scoop_SoundEditorData_Join5:
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue6:
	inc	4, xsp
	ret
	lda	xsp, (xsp-18)
	ld	(xsp+16), a
	lda	xwa, (xsp+14)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	ld	wa, 3:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	ld	e, (xsp+14)
	extz	de
	pushw	29
	.byte 0xbf
	push	sr
	.asciz "080,"
	ld	bc, 3:i3
	call	SeMenu_TransferPartValues_EndData_0x169
	cp	l, 1:i3
	jr	nz, Scoop_SoundEditorData_Skip6
	lda	xbc, (xsp+12)
	ld	wa, 3:i3
	call	SeMenu_LoadPartParam
	ld	c, (xsp+12)
	extz	bc
	ldw	wa, 10
	call	SeMenu_StorePartParam
	ld	wa, 0:i3
	ld	bc, 0:i3
	call	SeMenu_ApplyPartEdit_Data2_0x13DE
Scoop_SoundEditorData_Skip6:
	ld	wa, 3:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+18)
	ret
	dec	8, xsp
	ld	(xsp+6), a
	lda	xbc, (xsp+2)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+6)
	extz	wa
	ld	c, (xsp+2)
	dec	1, c
	extz	bc
	pushw	bc
	ld	bc, 1:i3
	ld	de, 0:i3
	call	SeMenu_PatchBank_Data_0x74
	cp	l, 1:i3
	jr	nz, Scoop_SoundEditorData_Skip7
	lda	xwa, (xsp+4)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	ld	wa, 1:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+4)
	extz	wa
	lda	xde, (xsp)
	pushw	127
	ldw	bc, 27
	call	SeMenu_RegisterElement_Extended
	pushw	1
	pushw	44
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	ld	wa, 0:i3
	ld	bc, 0:i3
	call	SeMenu_ApplyPartEdit_Data2_0x13DE
Scoop_SoundEditorData_Skip7:
	ld	wa, 4:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	inc	8, xsp
	ret
	lda	xsp, (xsp-10)
	ld	(xsp+8), a
	lda	xbc, (xsp+4)
	ld	wa, 1:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp+2)
	ld	wa, 2:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+8)
	extz	wa
	ld	e, (xsp+4)
	inc	1, e
	extz	de
	ld	c, (xsp+2)
	dec	1, c
	extz	bc
	pushw	bc
	ld	bc, 0:i3
	call	SeMenu_PatchBank_Data_0x74
	cp	l, 1:i3
	jr	nz, Scoop_SoundEditorData_Skip8
	lda	xwa, (xsp+6)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+6)
	extz	wa
	lda	xde, (xsp)
	pushw	127
	ldw	bc, 26
	call	SeMenu_RegisterElement_Extended
	pushw	0
	pushw	44
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	ld	wa, 0:i3
	ld	bc, 0:i3
	call	SeMenu_ApplyPartEdit_Data2_0x13DE
Scoop_SoundEditorData_Skip8:
	ld	wa, 5:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+10)
	ret
	dec	8, xsp
	ld	(xsp+6), a
	lda	xbc, (xsp+2)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+6)
	extz	wa
	ld	e, (xsp+2)
	inc	1, e
	extz	de
	pushw	127
	ld	bc, 2:i3
	call	SeMenu_PatchBank_Data_0x74
	cp	l, 1:i3
	jr	nz, Scoop_SoundEditorData_Skip9
	lda	xwa, (xsp+4)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	ld	wa, 2:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+4)
	extz	wa
	lda	xde, (xsp)
	pushw	127
	ldw	bc, 28
	call	SeMenu_RegisterElement_Extended
	pushw	2
	pushw	44
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	ld	wa, 0:i3
	ld	bc, 0:i3
	call	SeMenu_ApplyPartEdit_Data2_0x13DE
Scoop_SoundEditorData_Skip9:
	ld	wa, 6:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	inc	8, xsp
	ret
	cp	a, 0:i3
	.byte 0xf2, 0x01
	jr	pl, -16
	.byte 0xde
	ldw	wa, 45
	ld	bc, 0:i3
	jp	SeMenu_SendEvent
	cp	a, 0:i3
	ret	z
	ld	wa, 1:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 44
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	jr	nz, Scoop_SoundEditorData_Skip10
	ldw	wa, 47
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join6
Scoop_SoundEditorData_Skip10:
	ld	wa, 2:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 44
	ld	bc, 1:i3
Scoop_SoundEditorData_Join6:
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	ret	z
	ld	wa, 3:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 44
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	ret	z
	ld	wa, 4:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 44
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	ret	z
	ldw	wa, 43
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	ret	nz
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	ldw	wa, 32
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
	lda	xsp, (xsp-18)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+18), a
	lda	xwa, (xsp+16)
	call	SeMenu_ValidatePartNumber
	lda	xwa, (xsp+14)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	ret
	push	xsp
	nop
	scc8	nz, a
	ldb_erp a, 251
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp+2)
	ld	(xbc+6), 127
	ld	(xbc+7), 0
	ld	(xbc+8), 100
	ld	(xbc+9), 0
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	.byte 0x8f
	ret
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Skip11
	ld	a, 39:opc
	jr	Scoop_SoundEditorData_Join7
Scoop_SoundEditorData_Skip11:
	ld	a, (xsp+16)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	inc	8, xwa
	ld	(xsp+16), 0
Scoop_SoundEditorData_Join7:
	stb_erp c, 251
	extz	bc
	ld	e, (xsp+16)
	extz	de
	extz	wa
	pushw	wa
	.byte 0xbf, 0x04
	.asciz "080-"
	call	SeMenu_TransferPartValues_EndData_0x169
	call	SeMenu_ApplyPartEdit_Data2_0xA69
	ld	wa, 1:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	pop qiz
	lda	xsp, (xsp+18)
	ret
	lda	xsp, (xsp-18)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+18), a
	lda	xwa, (xsp+16)
	call	SeMenu_ValidatePartNumber
	lda	xwa, (xsp+14)
	call	SeMenu_LoadObjEntries
	lda	xhl, (xsp+2)
	lda	xwa, (xhl+6)
	lda	xbc, (xhl+7)
	lda	xde, (xhl+8)
	lda	xhl, (xhl+9)
	.byte 0xc7
	swi	3
	.byte 0xaa, 0x8f
	ret
	push	xsp
	nop
	jr	nz, 3
	ldib_erp 251, 1
	ld	(xwa), 127
	ld	(xbc), 0
	ld	(xde), 100
	ld	(xhl), 0
	stb_erp a, 251
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xsp+12)
	call	SeMenu_SetupPartDisplay_End_0x219
	.byte 0x8f
	ret
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Skip12
	ld	a, 40:opc
	jr	Scoop_SoundEditorData_Join8
Scoop_SoundEditorData_Skip12:
	ld	a, (xsp+16)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+9)
	ld	(xsp+16), 0
Scoop_SoundEditorData_Join8:
	stb_erp c, 251
	extz	bc
	ld	e, (xsp+16)
	extz	de
	extz	wa
	pushw	wa
	.byte 0xbf, 0x04
	.asciz "080-"
	call	SeMenu_TransferPartValues_EndData_0x169
	call	SeMenu_ApplyPartEdit_Data2_0xA69
	ld	wa, 2:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	pop qiz
	lda	xsp, (xsp+18)
	ret
	lda	xsp, (xsp-18)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+18), a
	lda	xwa, (xsp+16)
	call	SeMenu_ValidatePartNumber
	lda	xwa, (xsp+14)
	call	SeMenu_LoadObjEntries
	lda	xhl, (xsp+2)
	lda	xwa, (xhl+6)
	lda	xbc, (xhl+7)
	lda	xde, (xhl+8)
	lda	xhl, (xhl+9)
	.byte 0xc7
	swi	3
	.byte 0xab, 0x8f
	ret
	push	xsp
	nop
	jr	nz, 3
	ldib_erp 251, 2
	ld	(xwa), 127
	ld	(xbc), 0
	ld	(xde), 100
	ld	(xhl), 0
	stb_erp a, 251
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xsp+12)
	call	SeMenu_SetupPartDisplay_End_0x219
	.byte 0x8f
	ret
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Skip13
	ld	a, 41:opc
	jr	Scoop_SoundEditorData_Join9
Scoop_SoundEditorData_Skip13:
	ld	a, (xsp+16)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+10)
	ld	(xsp+16), 0
Scoop_SoundEditorData_Join9:
	stb_erp c, 251
	extz	bc
	ld	e, (xsp+16)
	extz	de
	extz	wa
	pushw	wa
	.byte 0xbf, 0x04
	.asciz "080-"
	call	SeMenu_TransferPartValues_EndData_0x169
	call	SeMenu_ApplyPartEdit_Data2_0xA69
	ld	wa, 3:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	pop qiz
	lda	xsp, (xsp+18)
	ret
	lda	xsp, (xsp-18)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+18), a
	lda	xwa, (xsp+16)
	call	SeMenu_ValidatePartNumber
	lda	xwa, (xsp+14)
	call	SeMenu_LoadObjEntries
	lda	xhl, (xsp+2)
	lda	xwa, (xhl+6)
	lda	xbc, (xhl+7)
	lda	xde, (xhl+8)
	lda	xhl, (xhl+9)
	.byte 0xc7
	swi	3
	.byte 0xac, 0x8f
	ret
	push	xsp
	nop
	jr	nz, 3
	ldib_erp 251, 3
	ld	(xwa), 127
	ld	(xbc), 0
	ld	(xde), 100
	ld	(xhl), 0
	stb_erp a, 251
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xsp+12)
	call	SeMenu_SetupPartDisplay_End_0x219
	.byte 0x8f
	ret
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Skip14
	ld	a, 42:opc
	jr	Scoop_SoundEditorData_Join10
Scoop_SoundEditorData_Skip14:
	ld	a, (xsp+16)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+11)
	ld	(xsp+16), 0
Scoop_SoundEditorData_Join10:
	stb_erp c, 251
	extz	bc
	ld	e, (xsp+16)
	extz	de
	extz	wa
	pushw	wa
	.byte 0xbf, 0x04
	.asciz "080-"
	call	SeMenu_TransferPartValues_EndData_0x169
	call	SeMenu_ApplyPartEdit_Data2_0xA69
	ld	wa, 4:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	pop qiz
	lda	xsp, (xsp+18)
	ret
	lda	xsp, (xsp-20)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+20), a
	lda	xwa, (xsp+18)
	call	SeMenu_ValidatePartNumber
	lda	xwa, (xsp+16)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	rcf
	push	xsp
	nop
	jr	nz, 20
	ldib_erp 251, 4
	lda	xwa, (xsp+2)
	ld	(xwa+6), 127
	ld	(xwa+7), 0
	ld	(xwa+8), 100
	jr	Scoop_SoundEditorData_Join11
	lda	xbc, (xsp+14)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	.byte 0xbf
	ret
	inc	6, e
	jrl	lt, -1081
	.byte 0xad
	lda	xwa, (xsp+2)
	ld	(xwa+6), 127
	ld	(xwa+7), 0
	ld	(xwa+8), 100
Scoop_SoundEditorData_Join11:
	ld	(xwa+9), 0
	stb_erp a, 251
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	ld	a, (xsp+20)
	extz	wa
	lda	xbc, (xsp+12)
	call	SeMenu_SetupPartDisplay_End_0x219
	.byte 0x8f
	rcf
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Skip15
	ld	a, 43:opc
	jr	Scoop_SoundEditorData_Join12
Scoop_SoundEditorData_Skip15:
	ld	a, (xsp+18)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+12)
	ld	(xsp+18), 0
Scoop_SoundEditorData_Join12:
	stb_erp c, 251
	extz	bc
	ld	e, (xsp+18)
	extz	de
	extz	wa
	pushw	wa
	.byte 0xbf, 0x04
	.asciz "080-"
	call	SeMenu_TransferPartValues_EndData_0x169
	call	SeMenu_ApplyPartEdit_Data2_0xA69
	ld	wa, 5:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	pop qiz
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-20)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+20), a
	lda	xwa, (xsp+18)
	call	SeMenu_ValidatePartNumber
	lda	xwa, (xsp+16)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	rcf
	push	xsp
	nop
	jr	nz, 20
	ldib_erp 251, 5
	lda	xwa, (xsp+2)
	ld	(xwa+6), 127
	ld	(xwa+7), 0
	ld	(xwa+8), 100
	jr	Scoop_SoundEditorData_Join13
	lda	xbc, (xsp+14)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	.byte 0xbf
	ret
	inc	6, e
	jrl	lt, -1081
	.byte 0xae
	lda	xwa, (xsp+2)
	ld	(xwa+6), 127
	ld	(xwa+7), 0
	ld	(xwa+8), 100
Scoop_SoundEditorData_Join13:
	ld	(xwa+9), 0
	stb_erp a, 251
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	ld	a, (xsp+20)
	extz	wa
	lda	xbc, (xsp+12)
	call	SeMenu_SetupPartDisplay_End_0x219
	.byte 0x8f
	rcf
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Skip16
	ld	a, 44:opc
	jr	Scoop_SoundEditorData_Join14
Scoop_SoundEditorData_Skip16:
	ld	a, (xsp+18)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+13)
	ld	(xsp+18), 0
Scoop_SoundEditorData_Join14:
	stb_erp c, 251
	extz	bc
	ld	e, (xsp+18)
	extz	de
	extz	wa
	pushw	wa
	.byte 0xbf, 0x04
	.asciz "080-"
	call	SeMenu_TransferPartValues_EndData_0x169
	call	SeMenu_ApplyPartEdit_Data2_0xA69
	ld	wa, 6:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	pop qiz
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-18)
	ld	(xsp+16), a
	lda	xwa, (xsp+12)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	incf
	push	xsp
	normal
	jr	z, 76
	lda	xwa, (xsp+14)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	ld	wa, 6:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 127
	ld	(xbc+7), 0
	ld	(xbc+8), 100
	ld	(xbc+9), 0
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	ld	e, (xsp+14)
	extz	de
	pushw	45
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 45
	ld	bc, 6:i3
	call	SeMenu_TransferPartValues_EndData_0x169
	call	SeMenu_ApplyPartEdit_Data2_0xA69
	ld	wa, 7:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+18)
	ret
	lda	xsp, (xsp-18)
	ld	(xsp+16), a
	lda	xwa, (xsp+12)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	incf
	push	xsp
	nop
	jr	z, 89
	lda	xwa, (xsp+14)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	ld	wa, 7:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	ld	a, (xsp+14)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+14)
	extz	wa
	pushw	wa
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 45
	ld	bc, 7:i3
	ld	de, 0:i3
	call	SeMenu_TransferPartValues_EndData_0x169
	ldw	wa, 8
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+18)
	ret
	cp	a, 0:i3
	ret	z
	call	SeMenu_BitShiftMask_End_0x1A3
	ret
	cp	a, 0:i3
	jr	nz, Scoop_SoundEditorData_Skip17
	ldw	wa, 43
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join15
Scoop_SoundEditorData_Skip17:
	ld	wa, 1:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 45
	ld	bc, 1:i3
Scoop_SoundEditorData_Join15:
	call	SeMenu_SendEvent
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Skip18
	.byte 0x87
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Epilogue7
	ldw	wa, 47
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join16
Scoop_SoundEditorData_Skip18:
	ld	wa, 2:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	jr	z, 9
	ldw	wa, 45
	ld	bc, 1:i3
Scoop_SoundEditorData_Join16:
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue7:
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x87
	push	xsp
	normal
	jr	z, 25
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	z, 19
	ld	wa, 3:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	jr	z, 9
	ldw	wa, 45
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp+2)
	call	SeMenu_LoadObjEntries
	.byte 0x8f, 0x04
	push	xsp
	nop
	jr	z, Scoop_SoundEditorData_Epilogue8
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Skip19
	ld	wa, 4:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	jr	z, Scoop_SoundEditorData_Epilogue8
	ldw	wa, 45
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	jr	Scoop_SoundEditorData_Epilogue8
Scoop_SoundEditorData_Skip19:
	lda	xbc, (xsp)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	.byte 0xb7
	inc	6, e
	.byte 0x04, 0xb7, 0xb5
	jr	Scoop_SoundEditorData_Join17
	.byte 0xb7, 0xbd
Scoop_SoundEditorData_Join17:
	ld	c, (xsp)
	extz	bc
	ld	wa, 0:i3
	call	SeMenu_StorePartParam
	pushw	0
	pushw	45
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	lda	xde, (xsp)
	pushw	32
	ld	wa, 0:i3
	ldw	bc, 13
	call	SeMenu_SetupDisplayObject_Alt1
	call	SeMenu_ApplyPartEdit_Data2_0xA69
Scoop_SoundEditorData_Epilogue8:
	inc	6, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x87
	push	xsp
	normal
	jr	z, 15
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, 9
	ldw	wa, 46
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Epilogue9
	.byte 0x87
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Skip20
	ldw	wa, 32
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join18
Scoop_SoundEditorData_Skip20:
	ldw	wa, 61
	ld	bc, 0:i3
Scoop_SoundEditorData_Join18:
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue9:
	inc	4, xsp
	ret
	lda	xsp, (xsp-18)
	ld	(xsp+16), a
	lda	xwa, (xsp+14)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	ld	wa, 5:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	ld	e, (xsp+14)
	extz	de
	pushw	51
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 46
	ld	bc, 5:i3
	call	SeMenu_TransferPartValues_EndData_0x169
	lda	xbc, (xsp+12)
	ld	wa, 5:i3
	call	SeMenu_LoadPartParam
	ld	c, (xsp+12)
	extz	bc
	ldw	wa, 10
	call	SeMenu_StorePartParam
	ld	wa, 2:i3
	ld	bc, 0:i3
	call	SeMenu_ApplyPartEdit_Data2_0x13DE
	lda	xbc, (xsp+12)
	ldw	wa, 9
	call	SeMenu_LoadPartParam
	.byte 0x8f
	incf
	push	xsp
	nop
	jr	z, 21
	ldw	wa, 9
	ld	bc, 0:i3
	call	SeMenu_StorePartParam
	pushw	9
	pushw	46
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	ld	wa, 1:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+18)
	ret
	lda	xsp, (xsp-18)
	ld	(xsp+16), a
	lda	xwa, (xsp+14)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	ld	wa, 6:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	ld	e, (xsp+14)
	extz	de
	pushw	52
	.byte 0xbf
	push	sr
	.asciz "080."
	ld	bc, 6:i3
	call	SeMenu_TransferPartValues_EndData_0x169
	lda	xbc, (xsp+12)
	ld	wa, 6:i3
	call	SeMenu_LoadPartParam
	ld	c, (xsp+12)
	extz	bc
	ldw	wa, 10
	call	SeMenu_StorePartParam
	ld	wa, 2:i3
	ld	bc, 0:i3
	call	SeMenu_ApplyPartEdit_Data2_0x13DE
	lda	xbc, (xsp+12)
	ldw	wa, 9
	call	SeMenu_LoadPartParam
	.byte 0x8f
	incf
	push	xsp
	normal
	jr	z, 21
	ldw	wa, 9
	ld	bc, 1:i3
	call	SeMenu_StorePartParam
	pushw	9
	pushw	46
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	ld	wa, 2:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+18)
	ret
	lda	xsp, (xsp-18)
	ld	(xsp+16), a
	lda	xwa, (xsp+14)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	ld	wa, 7:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	ld	e, (xsp+14)
	extz	de
	pushw	53
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 46
	ld	bc, 7:i3
	call	SeMenu_TransferPartValues_EndData_0x169
	lda	xbc, (xsp+12)
	ld	wa, 7:i3
	call	SeMenu_LoadPartParam
	ld	c, (xsp+12)
	extz	bc
	ldw	wa, 10
	call	SeMenu_StorePartParam
	ld	wa, 2:i3
	ld	bc, 0:i3
	call	SeMenu_ApplyPartEdit_Data2_0x13DE
	lda	xbc, (xsp+12)
	ldw	wa, 9
	call	SeMenu_LoadPartParam
	.byte 0x8f
	incf
	push	xsp
	push	sr
	jr	z, 21
	ldw	wa, 9
	ld	bc, 2:i3
	call	SeMenu_StorePartParam
	pushw	9
	pushw	46
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	ld	wa, 3:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+18)
	ret
	dec	8, xsp
	ld	(xsp+6), a
	lda	xbc, (xsp+2)
	ld	wa, 2:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+6)
	extz	wa
	ld	c, (xsp+2)
	dec	1, c
	extz	bc
	pushw	bc
	ld	bc, 3:i3
	ld	de, 0:i3
	call	SeMenu_PatchBank_Data_0x74
	cp	l, 1:i3
	jr	nz, Scoop_SoundEditorData_Skip21
	lda	xwa, (xsp+4)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	ld	wa, 3:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+4)
	extz	wa
	lda	xde, (xsp)
	pushw	127
	ldw	bc, 49
	call	SeMenu_RegisterElement_Extended
	pushw	3
	pushw	46
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	ld	wa, 2:i3
	ld	bc, 0:i3
	call	SeMenu_ApplyPartEdit_Data2_0x13DE
Scoop_SoundEditorData_Skip21:
	ld	wa, 4:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	inc	8, xsp
	ret
	lda	xsp, (xsp-10)
	ld	(xsp+8), a
	lda	xbc, (xsp+2)
	ld	wa, 4:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp+4)
	ld	wa, 3:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+8)
	extz	wa
	ld	e, (xsp+4)
	inc	1, e
	extz	de
	ld	c, (xsp+2)
	dec	1, c
	extz	bc
	pushw	bc
	ld	bc, 2:i3
	call	SeMenu_PatchBank_Data_0x74
	cp	l, 1:i3
	jr	nz, Scoop_SoundEditorData_Skip22
	lda	xwa, (xsp+6)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	ld	wa, 2:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+6)
	extz	wa
	lda	xde, (xsp)
	pushw	127
	ldw	bc, 48
	call	SeMenu_RegisterElement_Extended
	pushw	2
	pushw	46
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	ld	wa, 2:i3
	ld	bc, 0:i3
	call	SeMenu_ApplyPartEdit_Data2_0x13DE
Scoop_SoundEditorData_Skip22:
	ld	wa, 5:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+10)
	ret
	dec	8, xsp
	ld	(xsp+6), a
	lda	xbc, (xsp+2)
	ld	wa, 2:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+6)
	extz	wa
	ld	e, (xsp+2)
	inc	1, e
	extz	de
	pushw	127
	ld	bc, 4:i3
	call	SeMenu_PatchBank_Data_0x74
	cp	l, 1:i3
	jr	nz, Scoop_SoundEditorData_Skip23
	lda	xwa, (xsp+4)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	ld	wa, 4:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+4)
	extz	wa
	lda	xde, (xsp)
	pushw	127
	ldw	bc, 50
	call	SeMenu_RegisterElement_Extended
	pushw	4
	pushw	46
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	ld	wa, 2:i3
	ld	bc, 0:i3
	call	SeMenu_ApplyPartEdit_Data2_0x13DE
Scoop_SoundEditorData_Skip23:
	ld	wa, 6:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	inc	8, xsp
	ret
	lda	xsp, (xsp-16)
	ld	(xsp+14), a
	lda	xwa, (xsp+12)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+14)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	ld	e, (xsp+12)
	extz	de
	pushw	46
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 46
	ld	bc, 0:i3
	call	SeMenu_TransferPartValues_EndData_0x169
	ld	wa, 7:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+16)
	ret
	lda	xsp, (xsp-16)
	ld	(xsp+14), a
	lda	xwa, (xsp+12)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	ld	wa, 1:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+14)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	ld	e, (xsp+12)
	extz	de
	pushw	47
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 46
	ld	bc, 1:i3
	call	SeMenu_TransferPartValues_EndData_0x169
	ldw	wa, 8
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+16)
	ret
	cp	a, 0:i3
	ret	z
	call	SeMenu_BitShiftMask_End_0x1A3
	ret
	cp	a, 0:i3
	jr	nz, Scoop_SoundEditorData_Skip24
	ldw	wa, 43
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join19
Scoop_SoundEditorData_Skip24:
	ld	wa, 1:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 46
	ld	bc, 1:i3
Scoop_SoundEditorData_Join19:
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	jr	nz, Scoop_SoundEditorData_Skip25
	ldw	wa, 47
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join20
Scoop_SoundEditorData_Skip25:
	ld	wa, 2:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 46
	ld	bc, 1:i3
Scoop_SoundEditorData_Join20:
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	ret	z
	ld	wa, 3:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 46
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	ret	z
	ld	wa, 4:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 46
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	ret	z
	ldw	wa, 45
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	ret	nz
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	ldw	wa, 32
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
	extz	wa
	ld	bc, 0:i3
	jp	SeMenu_ApplyPartEdit_Data2
	extz	wa
	ld	bc, 0:i3
	jp	SeMenu_ApplyPartEdit_Data2_0x39
	extz	wa
	ld	bc, 0:i3
	jp	SeMenu_ApplyPartEdit_Data2_0xB6
	extz	wa
	ld	bc, 0:i3
	jp	SeMenu_ApplyPartEdit_Data2_0x133
	extz	wa
	ld	bc, 0:i3
	jp	SeMenu_ApplyPartEdit_Data2_0x1B0
	extz	wa
	ld	bc, 0:i3
	jp	SeMenu_ApplyPartEdit_Data2_0x22B
	extz	wa
	ld	bc, 0:i3
	jp	SeMenu_ApplyPartEdit_Data2_0x292
	cp	a, 0:i3
	.byte 0xf2, 0x01
	jr	pl, -16
	.byte 0xde
	ldw	wa, 45
	ld	bc, 0:i3
	jp	SeMenu_SendEvent
	cp	a, 0:i3
	jr	nz, Scoop_SoundEditorData_Skip26
	ldw	wa, 43
	ld	bc, 0:i3
	jp	SeMenu_SendEvent
Scoop_SoundEditorData_Skip26:
	ld	wa, 0:i3
	ld	bc, 1:i3
	jp	SeMenu_TransferPartValues_EndData_0x20E
	cp	a, 0:i3
	ret	z
	ld	wa, 0:i3
	ld	bc, 2:i3
	call	SeMenu_TransferPartValues_EndData_0x20E
	ret
	cp	a, 0:i3
	ret	z
	ld	wa, 0:i3
	ld	bc, 3:i3
	call	SeMenu_TransferPartValues_EndData_0x20E
	ret
	cp	a, 0:i3
	ret	z
	ld	wa, 0:i3
	ld	bc, 4:i3
	call	SeMenu_TransferPartValues_EndData_0x20E
	ret
	cp	a, 0:i3
	ret	nz
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	ldw	wa, 32
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeMenu_SetupPartDisplay_End_0x90
	cp	hl, 0xffff
	jr	z, Scoop_SoundEditorData_Epilogue10
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda	xde, (GUI_DisplayStructData_0xE40:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
Scoop_SoundEditorData_Epilogue10:
	inc	4, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeMenu_SetupPartDisplay_End_0x90
	cp	hl, 0xffff
	jr	z, Scoop_SoundEditorData_Epilogue11
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda	xde, (GUI_DisplayStructData_0xE88:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
Scoop_SoundEditorData_Epilogue11:
	inc	4, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeMenu_SetupPartDisplay_End_0x90
	cp	hl, 0xffff
	jr	z, Scoop_SoundEditorData_Epilogue12
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda	xde, (GUI_DisplayStructData_0xED0:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
Scoop_SoundEditorData_Epilogue12:
	inc	4, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeMenu_SetupPartDisplay_End_0x90
	cp	hl, 0xffff
	jr	z, Scoop_SoundEditorData_Epilogue13
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda	xde, (GUI_DisplayStructData_0xF18:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
Scoop_SoundEditorData_Epilogue13:
	inc	4, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeMenu_SetupPartDisplay_End_0x90
	cp	hl, 0xffff
	jr	z, Scoop_SoundEditorData_Epilogue14
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda	xde, (GUI_DisplayStructData_0xF60:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
Scoop_SoundEditorData_Epilogue14:
	inc	4, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeMenu_SetupPartDisplay_End_0x90
	cp	hl, 0xffff
	jr	z, Scoop_SoundEditorData_Epilogue15
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda	xde, (GUI_DisplayStructData_0xFA8:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
Scoop_SoundEditorData_Epilogue15:
	inc	4, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeMenu_SetupPartDisplay_End_0x90
	cp	hl, 0xffff
	jr	z, Scoop_SoundEditorData_Epilogue16
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda	xde, (GUI_DisplayStructData_0xFF0:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
Scoop_SoundEditorData_Epilogue16:
	inc	4, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeMenu_SetupPartDisplay_End_0x90
	cp	hl, 0xffff
	jr	z, Scoop_SoundEditorData_Epilogue17
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda	xde, (GUI_DisplayStructData_0x1038:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
Scoop_SoundEditorData_Epilogue17:
	inc	4, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeMenu_SetupPartDisplay_End_0x90
	cp	hl, 0xffff
	jr	z, Scoop_SoundEditorData_Epilogue18
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda	xde, (GUI_DisplayStructData_0x1080:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
Scoop_SoundEditorData_Epilogue18:
	inc	4, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeMenu_SetupPartDisplay_End_0x90
	cp	hl, 0xffff
	jr	z, Scoop_SoundEditorData_Epilogue19
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda	xde, (GUI_DisplayStructData_0x10C8:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
Scoop_SoundEditorData_Epilogue19:
	inc	4, xsp
	ret
	extz	wa
	ld	bc, 1:i3
	ldw	de, 48
	calr	Scoop_SoundEditorData_Helper
	ld	wa, 0:i3
	ld	bc, 0:i3
	jp	SeMenu_ApplyPartEdit_Data2_0x1815
Scoop_SoundEditorData_Helper:
	lda	xsp, (xsp-22)
	ld	(xsp+16), e
	ld	(xsp+18), c
	ld	(xsp+20), a
	lda	xwa, (xsp+14)
	call	SeMenu_ValidatePartNumber
	lda	xwa, (xsp+12)
	call	SeMenu_LoadObjEntries
	lda	xbc, (xsp)
	ld	wa, 2:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 127
	ld	(xbc+9), 0
	ld	a, (xsp+20)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	.byte 0x8f
	incf
	push	xsp
	nop
	jr	nz, 4
	ld	c, 77:opc
	jr	25
	ld	a, (xsp+14)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+17)
	ld	c, a
	ld	(xsp+14), 0
	ld	a, (xsp+16)
	extz	wa
	ld	e, (xsp+14)
	extz	de
	extz	bc
	pushw	bc
	lda	xbc, (xsp+2)
	push	xbc
	ld	bc, 2:i3
	call	SeMenu_TransferPartValues_EndData_0x169
	ld	a, (xsp+18)
	extz	wa
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+22)
	ret
	extz	wa
	ld	bc, 2:i3
	ldw	de, 48
	calr	Scoop_SoundEditorData_Helper2
	ld	wa, 0:i3
	ld	bc, 0:i3
	jp	SeMenu_ApplyPartEdit_Data2_0x1815
Scoop_SoundEditorData_Helper2:
	lda	xsp, (xsp-22)
	ld	(xsp+16), e
	ld	(xsp+18), c
	ld	(xsp+20), a
	lda	xwa, (xsp+14)
	call	SeMenu_ValidatePartNumber
	lda	xwa, (xsp+12)
	call	SeMenu_LoadObjEntries
	lda	xbc, (xsp)
	ld	wa, 3:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 127
	ld	(xbc+7), 0
	ld	(xbc+8), 5
	ld	(xbc+9), 0
	ld	a, (xsp+20)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	.byte 0x8f
	incf
	push	xsp
	nop
	jr	nz, 4
	ld	c, 78:opc
	jr	25
	ld	a, (xsp+14)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+18)
	ld	c, a
	ld	(xsp+14), 0
	ld	a, (xsp+16)
	extz	wa
	ld	e, (xsp+14)
	extz	de
	extz	bc
	pushw	bc
	lda	xbc, (xsp+2)
	push	xbc
	ld	bc, 3:i3
	call	SeMenu_TransferPartValues_EndData_0x169
	ld	a, (xsp+18)
	extz	wa
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+22)
	ret
	extz	wa
	ld	bc, 3:i3
	ldw	de, 48
	jr	Scoop_SoundEditorData_Join21
Scoop_SoundEditorData_Join21:
	lda	xsp, (xsp-22)
	ld	(xsp+16), e
	ld	(xsp+18), c
	ld	(xsp+20), a
	lda	xwa, (xsp+14)
	call	SeMenu_ValidatePartNumber
	lda	xwa, (xsp+12)
	call	SeMenu_LoadObjEntries
	lda	xbc, (xsp)
	ld	wa, 1:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 63
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 0
	ld	a, (xsp+20)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	.byte 0x8f
	incf
	push	xsp
	nop
	jr	nz, 4
	ld	c, 55:opc
	jr	25
	ld	a, (xsp+14)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+16)
	ld	c, a
	ld	(xsp+14), 0
	ld	a, (xsp+16)
	extz	wa
	ld	e, (xsp+14)
	extz	de
	extz	bc
	pushw	bc
	lda	xbc, (xsp+2)
	push	xbc
	ld	bc, 1:i3
	call	SeMenu_TransferPartValues_EndData_0x169
	ld	a, (xsp+18)
	extz	wa
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+22)
	ret
	extz	wa
	ld	bc, 4:i3
	ldw	de, 48
	jr	Scoop_SoundEditorData_Join22
Scoop_SoundEditorData_Join22:
	lda	xsp, (xsp-22)
	ld	(xsp+16), e
	ld	(xsp+18), c
	ld	(xsp+20), a
	lda	xwa, (xsp+14)
	call	SeMenu_ValidatePartNumber
	lda	xwa, (xsp+12)
	call	SeMenu_LoadObjEntries
	lda	xbc, (xsp)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 7
	ld	(xbc+7), 5
	ld	(xbc+8), 6
	ld	(xbc+9), 0
	ld	a, (xsp+20)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	.byte 0x8f
	incf
	push	xsp
	nop
	jr	nz, 4
	ld	c, 54:opc
	jr	25
	ld	a, (xsp+14)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+15)
	ld	c, a
	ld	(xsp+14), 0
	ld	a, (xsp+16)
	extz	wa
	ld	e, (xsp+14)
	extz	de
	extz	bc
	pushw	bc
	lda	xbc, (xsp+2)
	push	xbc
	ld	bc, 0:i3
	call	SeMenu_TransferPartValues_EndData_0x169
	ld	a, (xsp+18)
	extz	wa
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+22)
	ret
Scoop_SoundEditorData_Join23:
	lda	xsp, (xsp-18)
	ld	(xsp+16), a
	lda	xwa, (xsp+14)
	call	SeMenu_ValidatePartNumber
	lda	xwa, (xsp+12)
	call	SeMenu_LoadObjEntries
	lda	xbc, (xsp)
	ld	wa, 5:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 1
	ld	(xbc+7), 7
	ld	(xbc+8), 1
	ld	(xbc+9), 0
	ld	e, (xsp+16)
	res	7, e
	lda	xwa, (xbc+10)
	cp	e, 0:i3
	jr	nz, 5
	ld	(xwa), 1
	jr	3
	ld	(xwa), 255
	.byte 0x8f
	incf
	push	xsp
	nop
	jr	nz, 4
	ld	a, 80:opc
	jr	23
	ld	a, (xsp+14)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+20)
	ld	(xsp+14), 0
	ld	e, (xsp+14)
	extz	de
	extz	wa
	pushw	wa
	push	xbc
	ldw	wa, 48
	ld	bc, 5:i3
	call	SeMenu_TransferPartValues_EndData_0x169
	cp	l, 1:i3
	.byte 0xf2
	pushw	bc
	.byte 0x90, 0xf0, 0xe6
	ld	wa, 6:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+18)
	ret
Scoop_SoundEditorData_Join24:
	lda	xsp, (xsp-18)
	ld	(xsp+16), a
	lda	xwa, (xsp+14)
	call	SeMenu_ValidatePartNumber
	lda	xwa, (xsp+12)
	call	SeMenu_LoadObjEntries
	lda	xbc, (xsp)
	ld	wa, 4:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 127
	ld	(xbc+7), 0
	ld	(xbc+8), 127
	ld	(xbc+9), 0
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	.byte 0x8f
	incf
	push	xsp
	nop
	jr	nz, 4
	ld	a, 79:opc
	jr	23
	ld	a, (xsp+14)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+19)
	ld	(xsp+14), 0
	ld	e, (xsp+14)
	extz	de
	extz	wa
	pushw	wa
	.byte 0xbf
	push	sr
	.asciz "0800"
	ld	bc, 4:i3
	call	SeMenu_TransferPartValues_EndData_0x169
	cp	l, 1:i3
	.byte 0xf2
	pushw	bc
	.byte 0x90, 0xf0, 0xe6
	ld	wa, 7:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+18)
	ret
Scoop_SoundEditorData_Join25:
	lda	xsp, (xsp-18)
	ld	(xsp+16), a
	lda	xwa, (xsp+14)
	call	SeMenu_ValidatePartNumber
	lda	xwa, (xsp+12)
	call	SeMenu_LoadObjEntries
	lda	xbc, (xsp)
	ld	wa, 5:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 127
	ld	(xbc+7), 0
	ld	(xbc+8), 13
	ld	(xbc+9), 0
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	.byte 0x8f
	incf
	push	xsp
	nop
	jr	nz, 4
	ld	a, 80:opc
	jr	23
	ld	a, (xsp+14)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+20)
	ld	(xsp+14), 0
	ld	e, (xsp+14)
	extz	de
	extz	wa
	pushw	wa
	.byte 0xbf
	push	sr
	.asciz "0800"
	ld	bc, 5:i3
	call	SeMenu_TransferPartValues_EndData_0x169
	cp	l, 1:i3
	.byte 0xf2
	pushw	bc
	.byte 0x90, 0xf0, 0xe6
	ldw	wa, 8
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+18)
	ret
Scoop_SoundEditorData_Join26:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Skip27
	.byte 0x87
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Epilogue20
	ldw	wa, 55
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	jr	Scoop_SoundEditorData_Epilogue20
Scoop_SoundEditorData_Skip27:
	call	SeMenu_BitShiftMask_End_0x1A3
Scoop_SoundEditorData_Epilogue20:
	inc	4, xsp
	ret
Scoop_SoundEditorData_Join27:
	cp	a, 0:i3
	ret	z
	ld	wa, 1:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 48
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
Scoop_SoundEditorData_Join28:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Skip28
	.byte 0x87
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Epilogue21
	ldw	wa, 57
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join29
Scoop_SoundEditorData_Skip28:
	ld	wa, 2:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	jr	z, Scoop_SoundEditorData_Epilogue21
	ldw	wa, 48
	ld	bc, 0:i3
Scoop_SoundEditorData_Join29:
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue21:
	inc	4, xsp
	ret
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f, 0x04
	push	xsp
	nop
	jr	nz, 32
	lda	xbc, (xsp+2)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	.byte 0x8f
	push	sr
	push	xix
	swi	0
	.byte 0xbf
	push	sr
	ldw (xbc-113), 55329
	ccf
	call	SeMenu_BitShiftMask_End_0x1C4
	ldw	wa, 48
	ld	bc, 0:i3
	jr	20
	.byte 0x87
	push	xsp
	normal
	jr	z, 19
	ld	wa, 3:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	jr	z, 9
	ldw	wa, 48
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	inc	6, xsp
	ret
Scoop_SoundEditorData_Join30:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	z, 24
	.byte 0x87
	push	xsp
	normal
	jr	z, 19
	ld	wa, 4:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	jr	z, 9
	ldw	wa, 48
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x87
	push	xsp
	normal
	jr	z, 15
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, 9
	ldw	wa, 54
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Epilogue22
	.byte 0x87
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Skip29
	ldw	wa, 32
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join31
Scoop_SoundEditorData_Skip29:
	ldw	wa, 61
	ld	bc, 0:i3
Scoop_SoundEditorData_Join31:
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue22:
	inc	4, xsp
	ret
	extz	wa
	ld	bc, 1:i3
	ldw	de, 49
	calr	Scoop_SoundEditorData_Helper
	ld	wa, 1:i3
	ld	bc, 0:i3
	jp	SeMenu_ApplyPartEdit_Data2_0x1815
	extz	wa
	ld	bc, 2:i3
	ldw	de, 49
	calr	Scoop_SoundEditorData_Helper2
	ld	wa, 1:i3
	ld	bc, 0:i3
	jp	SeMenu_ApplyPartEdit_Data2_0x1815
	extz	wa
	ld	bc, 3:i3
	ldw	de, 49
	jrl	Scoop_SoundEditorData_Join21
	extz	wa
	ld	bc, 4:i3
	ldw	de, 49
	jrl	Scoop_SoundEditorData_Join22
	extz	wa
	jrl	Scoop_SoundEditorData_Join23
	extz	wa
	jrl	Scoop_SoundEditorData_Join24
	extz	wa
	jrl	Scoop_SoundEditorData_Join25
	extz	wa
	jrl	Scoop_SoundEditorData_Join26
	extz	wa
	jrl	Scoop_SoundEditorData_Join27
	extz	wa
	jrl	Scoop_SoundEditorData_Join28
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f, 0x04
	push	xsp
	nop
	jr	nz, 33
	lda	xbc, (xsp+2)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	.byte 0x8f
	push	sr
	push	xix
	swi	0
	.byte 0x8f
	push	sr
	push	xiz
	pop	sr
	ld	a, (xsp+2)
	extz	wa
	call	SeMenu_BitShiftMask_End_0x1C4
	ldw	wa, 48
	ld	bc, 0:i3
	jr	20
	.byte 0x87
	push	xsp
	nop
	jr	nz, 19
	ld	wa, 3:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	jr	z, Scoop_SoundEditorData_Epilogue23
	ldw	wa, 48
	ld	bc, 0:i3
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue23:
	inc	6, xsp
	ret
	extz	wa
	jrl	Scoop_SoundEditorData_Join30
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Epilogue24
	.byte 0x87
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Epilogue24
	ldw	wa, 54
	ld	bc, 0:i3
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue24:
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Epilogue25
	.byte 0x87
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Skip30
	ldw	wa, 32
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join32
Scoop_SoundEditorData_Skip30:
	ldw	wa, 61
	ld	bc, 0:i3
Scoop_SoundEditorData_Join32:
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue25:
	inc	4, xsp
	ret
	extz	wa
	ld	bc, 3:i3
	ldw	de, 50
	calr	Scoop_SoundEditorData_Helper
	ld	wa, 0:i3
	ld	bc, 1:i3
	jp	SeMenu_ApplyPartEdit_Data2_0x1815
	extz	wa
	ld	bc, 4:i3
	ldw	de, 50
	calr	Scoop_SoundEditorData_Helper2
	ld	wa, 0:i3
	ld	bc, 1:i3
	jp	SeMenu_ApplyPartEdit_Data2_0x1815
	extz	wa
	ld	bc, 5:i3
	ldw	de, 50
	jrl	Scoop_SoundEditorData_Join21
	extz	wa
	ld	bc, 6:i3
	ldw	de, 50
	jrl	Scoop_SoundEditorData_Join22
Scoop_SoundEditorData_Join33:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Skip31
	.byte 0x87
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Epilogue26
	ldw	wa, 55
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	jr	Scoop_SoundEditorData_Epilogue26
Scoop_SoundEditorData_Skip31:
	call	SeMenu_BitShiftMask_End_0x1A3
Scoop_SoundEditorData_Epilogue26:
	inc	4, xsp
	ret
Scoop_SoundEditorData_Join34:
	cp	a, 0:i3
	ret	z
	ld	wa, 1:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 48
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
Scoop_SoundEditorData_Join35:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Skip32
	.byte 0x87
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Epilogue27
	ldw	wa, 57
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join36
Scoop_SoundEditorData_Skip32:
	ld	wa, 2:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	jr	z, Scoop_SoundEditorData_Epilogue27
	ldw	wa, 48
	ld	bc, 0:i3
Scoop_SoundEditorData_Join36:
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue27:
	inc	4, xsp
	ret
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f, 0x04
	push	xsp
	nop
	jr	nz, 32
	lda	xbc, (xsp+2)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	.byte 0x8f
	push	sr
	push	xix
	swi	0
	.byte 0xbf
	push	sr
	ldw (xde-113), 55329
	ccf
	call	SeMenu_BitShiftMask_End_0x1C4
	ldw	wa, 48
	ld	bc, 0:i3
	jr	20
	.byte 0x87
	push	xsp
	normal
	jr	z, 19
	ld	wa, 3:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	jr	z, 9
	ldw	wa, 48
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	inc	6, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x87
	push	xsp
	normal
	jr	z, 25
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	z, 19
	ld	wa, 4:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	jr	z, 9
	ldw	wa, 48
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x87
	push	xsp
	normal
	jr	z, 15
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, 9
	ldw	wa, 54
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Epilogue28
	.byte 0x87
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Skip33
	ldw	wa, 32
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join37
Scoop_SoundEditorData_Skip33:
	ldw	wa, 61
	ld	bc, 0:i3
Scoop_SoundEditorData_Join37:
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue28:
	inc	4, xsp
	ret
	extz	wa
	ld	bc, 3:i3
	ldw	de, 51
	calr	Scoop_SoundEditorData_Helper
	ld	wa, 1:i3
	ld	bc, 1:i3
	jp	SeMenu_ApplyPartEdit_Data2_0x1815
	extz	wa
	ld	bc, 4:i3
	ldw	de, 51
	calr	Scoop_SoundEditorData_Helper2
	ld	wa, 1:i3
	ld	bc, 1:i3
	jp	SeMenu_ApplyPartEdit_Data2_0x1815
	extz	wa
	ld	bc, 5:i3
	ldw	de, 51
	jrl	Scoop_SoundEditorData_Join21
	extz	wa
	ld	bc, 6:i3
	ldw	de, 51
	jrl	Scoop_SoundEditorData_Join22
	extz	wa
	jrl	Scoop_SoundEditorData_Join33
	extz	wa
	jrl	Scoop_SoundEditorData_Join34
	extz	wa
	jrl	Scoop_SoundEditorData_Join35
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f, 0x04
	push	xsp
	nop
	jr	nz, 33
	lda	xbc, (xsp+2)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	.byte 0x8f
	push	sr
	push	xix
	swi	0
	.byte 0x8f
	push	sr
	push	xiz
	halt
	ld	a, (xsp+2)
	extz	wa
	call	SeMenu_BitShiftMask_End_0x1C4
	ldw	wa, 48
	ld	bc, 0:i3
	jr	20
	.byte 0x87
	push	xsp
	normal
	jr	z, 19
	ld	wa, 3:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	jr	z, 9
	ldw	wa, 48
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	inc	6, xsp
	ret
	extz	wa
	jrl	-278
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x87
	push	xsp
	normal
	jr	z, 15
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, 9
	ldw	wa, 54
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Epilogue29
	.byte 0x87
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Skip34
	ldw	wa, 32
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join38
Scoop_SoundEditorData_Skip34:
	ldw	wa, 61
	ld	bc, 0:i3
Scoop_SoundEditorData_Join38:
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue29:
	inc	4, xsp
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+18), a
	lda	xwa, (xsp+16)
	call	SeMenu_ValidatePartNumber
	lda	xwa, (xsp+12)
	call	SeMenu_LoadObjEntries
	lda	xbc, (xsp+14)
	ld	wa, 4:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	wa, 2:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	a, (xsp+14)
	dec	1, a
	ld	(xbc+8), a
	ld	(xbc+9), 0
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	.byte 0x8f
	incf
	push	xsp
	nop
	jr	nz, 4
	ld	a, 77:opc
	jr	23
	ld	a, (xsp+16)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+17)
	ld	(xsp+16), 0
	ld	e, (xsp+16)
	extz	de
	extz	wa
	pushw	wa
	.byte 0xbf
	push	sr
	.asciz "0804"
	ld	bc, 2:i3
	call	SeMenu_TransferPartValues_EndData_0x169
	call	SeMenu_ApplyPartEdit_Data2_0x1AAD
	ld	wa, 2:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+20)
	ret
	extz	wa
	ld	bc, 3:i3
	ldw	de, 52
	calr	Scoop_SoundEditorData_Helper2
	jp	SeMenu_ApplyPartEdit_Data2_0x1AAD
	lda	xsp, (xsp-20)
	ld	(xsp+18), a
	lda	xwa, (xsp+16)
	call	SeMenu_ValidatePartNumber
	lda	xwa, (xsp+12)
	call	SeMenu_LoadObjEntries
	lda	xbc, (xsp+14)
	ld	wa, 2:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	wa, 4:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 127
	ld	a, (xsp+14)
	inc	1, a
	ld	(xbc+9), a
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	lda	xbc, (xsp)
	.byte 0x8f
	incf
	push	xsp
	nop
	jr	nz, 16
	ld	e, (xsp+16)
	extz	de
	pushw	79
	push	xbc
	ldw	wa, 52
	ld	bc, 4:i3
	jr	30
	ld	a, (xsp+16)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+19)
	extz	wa
	pushw	wa
	push	xbc
	ldw	wa, 52
	ld	bc, 4:i3
	ld	de, 0:i3
	call	SeMenu_TransferPartValues_EndData_0x169
	call	SeMenu_ApplyPartEdit_Data2_0x1AAD
	ld	wa, 4:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-18)
	ld	(xsp+16), a
	lda	xwa, (xsp+14)
	call	SeMenu_ValidatePartNumber
	lda	xwa, (xsp+12)
	call	SeMenu_LoadObjEntries
	lda	xbc, (xsp)
	ld	wa, 5:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 15
	ld	(xbc+7), 0
	ld	(xbc+8), 5
	ld	(xbc+9), 0
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	lda	xbc, (xsp)
	.byte 0x8f
	incf
	push	xsp
	nop
	jr	nz, 16
	ld	e, (xsp+14)
	extz	de
	pushw	80
	push	xbc
	ldw	wa, 52
	ld	bc, 5:i3
	jr	30
	ld	a, (xsp+14)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+20)
	extz	wa
	.asciz "(904"
	ld	bc, 5:i3
	ld	de, 0:i3
	call	SeMenu_TransferPartValues_EndData_0x169
	call	SeMenu_ApplyPartEdit_Data2_0x1AAD
	ld	wa, 5:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+18)
	ret
	extz	wa
	ld	bc, 6:i3
	ldw	de, 52
	jrl	Scoop_SoundEditorData_Join21
	extz	wa
	ld	bc, 7:i3
	ldw	de, 52
	jrl	Scoop_SoundEditorData_Join22
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Skip35
	.byte 0x87
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Epilogue30
	ldw	wa, 55
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	jr	Scoop_SoundEditorData_Epilogue30
Scoop_SoundEditorData_Skip35:
	call	SeMenu_BitShiftMask_End_0x1A3
Scoop_SoundEditorData_Epilogue30:
	inc	4, xsp
	ret
	cp	a, 0:i3
	ret	z
	ld	wa, 1:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 48
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Skip36
	.byte 0x87
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Epilogue31
	ldw	wa, 57
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join39
Scoop_SoundEditorData_Skip36:
	ld	wa, 2:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	jr	z, Scoop_SoundEditorData_Epilogue31
	ldw	wa, 48
	ld	bc, 0:i3
Scoop_SoundEditorData_Join39:
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue31:
	inc	4, xsp
	ret
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f, 0x04
	push	xsp
	nop
	jr	nz, 29
	lda	xbc, (xsp+2)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	.byte 0x8f
	push	sr
	push	xix
	swi	0
	ld	a, (xsp+2)
	extz	wa
	call	SeMenu_BitShiftMask_End_0x1C4
	ldw	wa, 48
	ld	bc, 0:i3
	jr	20
	.byte 0x87
	push	xsp
	normal
	jr	z, 19
	ld	wa, 3:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	jr	z, 9
	ldw	wa, 48
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	inc	6, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x87
	push	xsp
	normal
	jr	z, 25
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	z, 19
	ld	wa, 4:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	jr	z, 9
	ldw	wa, 48
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x87
	push	xsp
	normal
	jr	z, 15
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, 9
	ldw	wa, 54
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Epilogue32
	.byte 0x87
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Skip37
	ldw	wa, 32
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join40
Scoop_SoundEditorData_Skip37:
	ldw	wa, 61
	ld	bc, 0:i3
Scoop_SoundEditorData_Join40:
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue32:
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Skip38
	.byte 0x87
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Epilogue33
	ldw	wa, 55
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	jr	Scoop_SoundEditorData_Epilogue33
Scoop_SoundEditorData_Skip38:
	call	SeMenu_BitShiftMask_End_0x1A3
Scoop_SoundEditorData_Epilogue33:
	inc	4, xsp
	ret
	cp	a, 0:i3
	ret	z
	ld	wa, 1:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 48
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Skip39
	.byte 0x87
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Epilogue34
	ldw	wa, 57
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join41
Scoop_SoundEditorData_Skip39:
	ld	wa, 2:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	jr	z, Scoop_SoundEditorData_Epilogue34
	ldw	wa, 48
	ld	bc, 0:i3
Scoop_SoundEditorData_Join41:
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue34:
	inc	4, xsp
	ret
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f, 0x04
	push	xsp
	nop
	jr	nz, 32
	lda	xbc, (xsp+2)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	.byte 0x8f
	push	sr
	push	xix
	swi	0
	.byte 0xbf
	push	sr
	ldw (xwa-113), 55329
	ccf
	call	SeMenu_BitShiftMask_End_0x1C4
	ldw	wa, 48
	ld	bc, 0:i3
	jr	20
	.byte 0x87
	push	xsp
	normal
	jr	z, 19
	ld	wa, 3:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	jr	z, 9
	ldw	wa, 48
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	inc	6, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x87
	push	xsp
	normal
	jr	z, 25
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	z, 19
	ld	wa, 4:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	jr	z, 9
	ldw	wa, 48
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x87
	push	xsp
	normal
	jr	z, 15
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, 9
	ldw	wa, 54
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Epilogue35
	.byte 0x87
	push	xsp
	nop
	jr	nz, Scoop_SoundEditorData_Skip40
	ldw	wa, 32
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join42
Scoop_SoundEditorData_Skip40:
	ldw	wa, 61
	ld	bc, 0:i3
Scoop_SoundEditorData_Join42:
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue35:
	inc	4, xsp
	ret
	lda	xsp, (xsp-18)
	ld	(xsp+16), a
	lda	xwa, (xsp+14)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	ld	wa, 3:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	ld	e, (xsp+14)
	extz	de
	pushw	60
	.byte 0xbf
	push	sr
	.asciz "0806"
	ld	bc, 3:i3
	call	SeMenu_TransferPartValues_EndData_0x169
	cp	l, 1:i3
	jr	nz, Scoop_SoundEditorData_Skip41
	lda	xbc, (xsp+12)
	ld	wa, 3:i3
	call	SeMenu_LoadPartParam
	ld	c, (xsp+12)
	extz	bc
	ldw	wa, 10
	call	SeMenu_StorePartParam
	ld	wa, 0:i3
	ld	bc, 0:i3
	call	SeMenu_ApplyPartEdit_Data2_0x13DE
Scoop_SoundEditorData_Skip41:
	ld	wa, 3:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+18)
	ret
	dec	8, xsp
	ld	(xsp+6), a
	lda	xbc, (xsp+2)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+6)
	extz	wa
	ld	c, (xsp+2)
	dec	1, c
	extz	bc
	pushw	bc
	ld	bc, 1:i3
	ld	de, 0:i3
	call	SeMenu_PatchBank_Data_0x74
	cp	l, 1:i3
	jr	nz, Scoop_SoundEditorData_Skip42
	lda	xwa, (xsp+4)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	ld	wa, 1:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+4)
	extz	wa
	lda	xde, (xsp)
	pushw	127
	ldw	bc, 58
	call	SeMenu_RegisterElement_Extended
	pushw	1
	pushw	54
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	ld	wa, 0:i3
	ld	bc, 0:i3
	call	SeMenu_ApplyPartEdit_Data2_0x13DE
Scoop_SoundEditorData_Skip42:
	ld	wa, 4:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	inc	8, xsp
	ret
	lda	xsp, (xsp-10)
	ld	(xsp+8), a
	lda	xbc, (xsp+4)
	ld	wa, 1:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp+2)
	ld	wa, 2:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+8)
	extz	wa
	ld	e, (xsp+4)
	inc	1, e
	extz	de
	ld	c, (xsp+2)
	dec	1, c
	extz	bc
	pushw	bc
	ld	bc, 0:i3
	call	SeMenu_PatchBank_Data_0x74
	cp	l, 1:i3
	jr	nz, Scoop_SoundEditorData_Skip43
	lda	xwa, (xsp+6)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+6)
	extz	wa
	lda	xde, (xsp)
	pushw	127
	ldw	bc, 57
	call	SeMenu_RegisterElement_Extended
	pushw	0
	pushw	54
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	ld	wa, 0:i3
	ld	bc, 0:i3
	call	SeMenu_ApplyPartEdit_Data2_0x13DE
Scoop_SoundEditorData_Skip43:
	ld	wa, 5:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+10)
	ret
	dec	8, xsp
	ld	(xsp+6), a
	lda	xbc, (xsp+2)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+6)
	extz	wa
	ld	e, (xsp+2)
	inc	1, e
	extz	de
	pushw	127
	ld	bc, 2:i3
	call	SeMenu_PatchBank_Data_0x74
	cp	l, 1:i3
	jr	nz, Scoop_SoundEditorData_Skip44
	lda	xwa, (xsp+4)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	ld	wa, 2:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+4)
	extz	wa
	lda	xde, (xsp)
	pushw	127
	ldw	bc, 59
	call	SeMenu_RegisterElement_Extended
	pushw	2
	pushw	54
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	ld	wa, 0:i3
	ld	bc, 0:i3
	call	SeMenu_ApplyPartEdit_Data2_0x13DE
Scoop_SoundEditorData_Skip44:
	ld	wa, 6:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	inc	8, xsp
	ret
	cp	a, 0:i3
	.byte 0xf2, 0x01
	jr	pl, -16
	.byte 0xde
	ldw	wa, 55
	ld	bc, 0:i3
	jp	SeMenu_SendEvent
	cp	a, 0:i3
	ret	z
	ld	wa, 1:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 54
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	jr	nz, Scoop_SoundEditorData_Skip45
	ldw	wa, 57
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join43
Scoop_SoundEditorData_Skip45:
	ld	wa, 2:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 54
	ld	bc, 1:i3
Scoop_SoundEditorData_Join43:
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	ret	z
	ld	wa, 3:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 54
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	ret	z
	ld	wa, 4:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 54
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	ret	z
	ldw	wa, 48
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	ret	nz
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	ldw	wa, 32
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
	extz	wa
	ldw	bc, 63
	ld	de, 0:i3
	jp	SeMenu_ApplyPartEdit_Data2_0x332
	extz	wa
	ldw	bc, 64
	ld	de, 0:i3
	jp	SeMenu_ApplyPartEdit_Data2_0x396
	extz	wa
	ldw	bc, 62
	ldw	de, 65
	jp	SeMenu_ApplyPartEdit_Data2_0x3FA
	extz	wa
	ldw	bc, 66
	ld	de, 0:i3
	jp	SeMenu_ApplyPartEdit_Data2_0x498
	extz	wa
	ldw	bc, 70
	ldw	de, 67
	jp	SeMenu_ApplyPartEdit_Data2_0x4FC
	extz	wa
	ldw	bc, 68
	ld	de, 0:i3
	jp	SeMenu_ApplyPartEdit_Data2_0x59C
	extz	wa
	ldw	bc, 61
	ldw	de, 69
	jp	SeMenu_ApplyPartEdit_Data2_0x602
	cp	a, 0:i3
	ret	z
	call	SeMenu_BitShiftMask_End_0x1A3
	ret
	cp	a, 0:i3
	jr	nz, Scoop_SoundEditorData_Skip46
	ldw	wa, 48
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join44
Scoop_SoundEditorData_Skip46:
	ld	wa, 1:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 55
	ld	bc, 1:i3
Scoop_SoundEditorData_Join44:
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	jr	nz, Scoop_SoundEditorData_Skip47
	ldw	wa, 57
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join45
Scoop_SoundEditorData_Skip47:
	ld	wa, 2:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 55
	ld	bc, 1:i3
Scoop_SoundEditorData_Join45:
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	jr	nz, Scoop_SoundEditorData_Skip48
	ld	wa, 0:i3
	jp	SeMenu_ApplyPartEdit_Data2_0x2FA
Scoop_SoundEditorData_Skip48:
	ld	wa, 3:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 55
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	jr	nz, Scoop_SoundEditorData_Skip49
	ld	wa, 1:i3
	jp	SeMenu_ApplyPartEdit_Data2_0x2FA
Scoop_SoundEditorData_Skip49:
	ld	wa, 4:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 55
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	ret	nz
	ldw	wa, 56
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	ret	nz
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	ldw	wa, 32
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
	extz	wa
	ldw	bc, 74
	jp	SeMenu_ApplyPartEdit_Data2_0x6A2
	extz	wa
	ldw	bc, 75
	jp	SeMenu_ApplyPartEdit_Data2_0x732
	extz	wa
	ldw	bc, 76
	jp	SeMenu_ApplyPartEdit_Data2_0x7C2
	extz	wa
	ldw	bc, 73
	jp	SeMenu_ApplyPartEdit_Data2_0x852
	extz	wa
	ldw	bc, 71
	jp	SeMenu_ApplyPartEdit_Data2_0x8A1
	extz	wa
	ldw	bc, 72
	jp	SeMenu_ApplyPartEdit_Data2_0x8F4
	cp	a, 0:i3
	ret	z
	call	SeMenu_BitShiftMask_End_0x1A3
	ret
	cp	a, 0:i3
	jr	nz, Scoop_SoundEditorData_Skip50
	ldw	wa, 48
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join46
Scoop_SoundEditorData_Skip50:
	ld	wa, 1:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 56
	ld	bc, 1:i3
Scoop_SoundEditorData_Join46:
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	jr	nz, Scoop_SoundEditorData_Skip51
	ldw	wa, 57
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join47
Scoop_SoundEditorData_Skip51:
	ld	wa, 2:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 56
	ld	bc, 1:i3
Scoop_SoundEditorData_Join47:
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	ret	z
	ld	wa, 3:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 56
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	ret	z
	ld	wa, 4:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 56
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	ret	z
	ldw	wa, 55
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	ret	nz
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	ldw	wa, 32
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
	extz	wa
	ld	bc, 2:i3
	jp	SeMenu_ApplyPartEdit_Data2
	extz	wa
	ld	bc, 2:i3
	jp	SeMenu_ApplyPartEdit_Data2_0x39
	extz	wa
	ld	bc, 2:i3
	jp	SeMenu_ApplyPartEdit_Data2_0xB6
	extz	wa
	ld	bc, 2:i3
	jp	SeMenu_ApplyPartEdit_Data2_0x133
	extz	wa
	ld	bc, 2:i3
	jp	SeMenu_ApplyPartEdit_Data2_0x1B0
	extz	wa
	ld	bc, 2:i3
	jp	SeMenu_ApplyPartEdit_Data2_0x22B
	extz	wa
	ld	bc, 2:i3
	jp	SeMenu_ApplyPartEdit_Data2_0x292
	cp	a, 0:i3
	.byte 0xf2, 0x01
	jr	pl, -16
	.byte 0xde
	ldw	wa, 55
	ld	bc, 0:i3
	jp	SeMenu_SendEvent
	cp	a, 0:i3
	jr	nz, Scoop_SoundEditorData_Skip52
	ldw	wa, 48
	ld	bc, 0:i3
	jp	SeMenu_SendEvent
Scoop_SoundEditorData_Skip52:
	ld	wa, 2:i3
	ld	bc, 1:i3
	jp	SeMenu_TransferPartValues_EndData_0x20E
	cp	a, 0:i3
	ret	z
	ld	wa, 2:i3
	ld	bc, 2:i3
	call	SeMenu_TransferPartValues_EndData_0x20E
	ret
	cp	a, 0:i3
	ret	z
	ld	wa, 2:i3
	ld	bc, 3:i3
	call	SeMenu_TransferPartValues_EndData_0x20E
	ret
	cp	a, 0:i3
	ret	z
	ld	wa, 2:i3
	ld	bc, 4:i3
	call	SeMenu_TransferPartValues_EndData_0x20E
	ret
	cp	a, 0:i3
	ret	nz
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	ldw	wa, 32
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret


; --- Sound Editor ---
