; =============================================================================
; Sound-editor title-function handlers (code; historical file name)
; =============================================================================
;
; CODE, not data: 3,422 TLCS-900 instructions and not one .byte/.ascii/.long
; directive, re-assembled byte-identical to the dump.  Entered at
; Scoop_SoundEditorData -- named by one `.long` of the pointer table
; GUI_DisplayStructData_0xAF8 in kn5000_v*_program.s,
; where 187 more `.long`s point into this file as bare numbers -- and at the
; 15 interior offsets that the title-function stubs of
; audio/sound_editor_routines.s reach by `jp Scoop_SoundEditorData_0x..`
; (e.g. SeAmpAmp1TitleFunc_DisplayData).  The body is almost all calls to
; SeMenu_* (SeMenu_SendEvent, SeMenu_LoadPartParam, SeMenu_LoadObjEntries...).
; Framing: control-flow trace, `scripts/converters/scoop_reframe.py plan`
; (commands in notes/scoop-lane-2026-09-25/README.md).  In v10 it reaches
; 9,162 of the 9,199 bytes from 16 named entries plus 185 it takes from
; pointer/`ld` references and anchored runs; the other 37 B are three short
; tails that decode cleanly and show no data evidence, so they stay code.
;
; CORRECTED 2026-09-25: this header used to say "Sound editor display data,
; performance mode parameter bytecode, Scoop oscilloscope editor configuration
; tables, and display dirty-region data."  No reader treats these bytes as
; data and every byte assembles back to the ROM as an instruction, so the
; claim is withdrawn (the 177 .byte/.long lines of the v10/v9 source and the 9
; romslices of v7 that it may have rested on are re-spelled as instructions).
; The label name Scoop_SoundEditorData is kept: it is referenced from files
; outside this lane.
; =============================================================================



Scoop_SoundEditorData:
	jp	SeMenu_CopyWriteUpdate_Step3_Join
	jp	SeMenu_CopyWriteUpdate_Step3_Return30
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	call	Scoop_SoundEditorData_Helper12
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
	ld	xbc, EVT_SW_IN
	jp	DeleteEvent
	jp	SeMenu_CopyWriteUpdate_Step3_Return31
Scoop_SoundEditorData_Join48:
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	Scoop_SoundEditorData_Helper7
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
Scoop_SoundEditorData_Join49:
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	Scoop_SoundEditorData_Helper7
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
Scoop_SoundEditorData_Join50:
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	Scoop_SoundEditorData_Helper7
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
Scoop_SoundEditorData_Join51:
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	Scoop_SoundEditorData_Helper7
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
Scoop_SoundEditorData_Join52:
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	Scoop_SoundEditorData_Helper7
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
	call	SeMenu_ApplyPartEdit_Helper5
	lda	xhl, (xsp+2)
	lda	xwa, (xhl+6)
	lda	xbc, (xhl+7)
	lda	xde, (xhl+8)
	lda	xhl, (xhl+9)
	cp	(xsp+14), 0
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
	call	SeMenu_ApplyPartEdit_Helper2
	cp	(xsp+14), 0
	jr	nz, Scoop_SoundEditorData_Skip3
	cp	l, 1:i3
	jr	nz, Scoop_SoundEditorData_Skip3
	ld	a, (xsp+16)
	extz	wa
	ld	c, (xsp+5)
	extz	bc
	call	SeMenu_StoreParamByte
Scoop_SoundEditorData_Skip3:
	ld	wa, 3:i3
	call	SeMenu_ApplyPartEdit_Helper4
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-18)
	push	qiz
	ld	(xsp+18), a
	lda	xwa, (xsp+14)
	call	SeMenu_LoadObjEntries
	lda	xwa, (xsp+16)
	call	SeMenu_ValidatePartNumber
	cp	(xsp+14), 0
	jr	nz, Scoop_SoundEditorData_Skip53
	ld	a, (xsp+16)
	inc	4, a
	ldfr_berp a, 251
	jr	Scoop_SoundEditorData_Join3
Scoop_SoundEditorData_Skip53:
	ld	a, (xsp+16)
	inc	2, a
	ldfr_berp a, 251
Scoop_SoundEditorData_Join3:
	ldto_berp a, 251
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xsp+12)
	call	SeMenu_ApplyPartEdit_Helper5
	lda	xhl, (xsp+2)
	lda	xwa, (xhl+6)
	lda	xbc, (xhl+7)
	lda	xde, (xhl+8)
	lda	xhl, (xhl+9)
	cp	(xsp+14), 0
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
	ldto_berp c, 251
	extz	bc
	ld	e, (xsp+16)
	extz	de
	extz	wa
	pushw	wa
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 43
	call	SeMenu_ApplyPartEdit_Helper2
	ld	wa, 4:i3
	call	SeMenu_ApplyPartEdit_Helper4
	pop qiz
	lda	xsp, (xsp+18)
	ret
	lda	xsp, (xsp-18)
	push	qiz
	ld	(xsp+18), a
	lda	xwa, (xsp+14)
	call	SeMenu_LoadObjEntries
	cp	(xsp+14), 1
	jr	z, Scoop_SoundEditorData_Epilogue36
	lda	xwa, (xsp+16)
	call	SeMenu_ValidatePartNumber
	ld	a, (xsp+16)
	inc	8, a
	ldfr_berp a, 251
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
	call	SeMenu_ApplyPartEdit_Helper5
	ldto_berp c, 251
	extz	bc
	ld	e, (xsp+16)
	extz	de
	pushw	25
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 43
	call	SeMenu_ApplyPartEdit_Helper2
	ld	wa, 5:i3
	call	SeMenu_ApplyPartEdit_Helper4
Scoop_SoundEditorData_Epilogue36:
	pop qiz
	lda	xsp, (xsp+18)
	ret
	cp	a, 0:i3
	jp	nz, (Scoop_SoundEditorData_Helper3:24)
	ldw	wa, 45
	ld	bc, 0:i3
	jp	SeMenu_SendEvent
	cp	a, 0:i3
	ret	z
	ldw	wa, 43
	ld	bc, 1:i3
	ld	de, 1:i3
	call	Scoop_SoundEditorData_Helper9
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Skip54
	cp	(xsp), 1
	jr	z, Scoop_SoundEditorData_Epilogue37
	ldw	wa, 47
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	jr	Scoop_SoundEditorData_Epilogue37
Scoop_SoundEditorData_Skip54:
	ldw	wa, 43
	ld	bc, 2:i3
	ld	de, 1:i3
	call	Scoop_SoundEditorData_Helper9
Scoop_SoundEditorData_Epilogue37:
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, Scoop_SoundEditorData_Epilogue38
	cp	(xsp+2), 0
	jr	z, Scoop_SoundEditorData_Epilogue38
	ldw	wa, 43
	ld	bc, 3:i3
	ld	de, 1:i3
	call	Scoop_SoundEditorData_Helper9
Scoop_SoundEditorData_Epilogue38:
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, Scoop_SoundEditorData_Epilogue39
	cp	(xsp+2), 0
	jr	z, Scoop_SoundEditorData_Epilogue39
	ldw	wa, 43
	ld	bc, 4:i3
	ld	de, 1:i3
	call	Scoop_SoundEditorData_Helper9
Scoop_SoundEditorData_Epilogue39:
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, Scoop_SoundEditorData_Epilogue40
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Epilogue40
	ldw	wa, 44
	ld	bc, 0:i3
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue40:
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Epilogue6
	cp	(xsp), 0
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
	call	SeMenu_ApplyPartEdit_Helper5
	ld	e, (xsp+14)
	extz	de
	pushw	29
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 44
	ld	bc, 3:i3
	call	SeMenu_ApplyPartEdit_Helper2
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
	call	SeMenu_ApplyPartEdit_Helper11
Scoop_SoundEditorData_Skip6:
	ld	wa, 3:i3
	call	SeMenu_ApplyPartEdit_Helper4
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
	call	SeMenu_ApplyPartEdit_Helper13
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
	call	SeMenu_ApplyPartEdit_Helper11
Scoop_SoundEditorData_Skip7:
	ld	wa, 4:i3
	call	SeMenu_ApplyPartEdit_Helper4
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
	call	SeMenu_ApplyPartEdit_Helper13
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
	call	SeMenu_ApplyPartEdit_Helper11
Scoop_SoundEditorData_Skip8:
	ld	wa, 5:i3
	call	SeMenu_ApplyPartEdit_Helper4
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
	call	SeMenu_ApplyPartEdit_Helper13
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
	call	SeMenu_ApplyPartEdit_Helper11
Scoop_SoundEditorData_Skip9:
	ld	wa, 6:i3
	call	SeMenu_ApplyPartEdit_Helper4
	inc	8, xsp
	ret
	cp	a, 0:i3
	jp	nz, (Scoop_SoundEditorData_Helper3:24)
	ldw	wa, 45
	ld	bc, 0:i3
	jp	SeMenu_SendEvent
	cp	a, 0:i3
	ret	z
	ld	wa, 1:i3
	call	Scoop_SoundEditorData_Helper5
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
	call	Scoop_SoundEditorData_Helper5
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
	call	Scoop_SoundEditorData_Helper5
	cp	l, 0:i3
	ret	z
	ldw	wa, 44
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	ret	z
	ld	wa, 4:i3
	call	Scoop_SoundEditorData_Helper5
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
	push	qiz
	ld	(xsp+18), a
	lda	xwa, (xsp+16)
	call	SeMenu_ValidatePartNumber
	lda	xwa, (xsp+14)
	call	SeMenu_LoadObjEntries
	cp	(xsp+14), 0
	scc8	nz, a
	ldfr_berp a, 251
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
	call	SeMenu_ApplyPartEdit_Helper5
	cp	(xsp+14), 0
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
	ldto_berp c, 251
	extz	bc
	ld	e, (xsp+16)
	extz	de
	extz	wa
	pushw	wa
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 45
	call	SeMenu_ApplyPartEdit_Helper2
	call	Scoop_SoundEditorData_Helper8
	ld	wa, 1:i3
	call	SeMenu_ApplyPartEdit_Helper4
	pop qiz
	lda	xsp, (xsp+18)
	ret
	lda	xsp, (xsp-18)
	push	qiz
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
	ldib_erp	251, 2
	cp	(xsp+14), 0
	jr	nz, Scoop_SoundEditorData_Skip55
	ldib_erp 251, 1
Scoop_SoundEditorData_Skip55:
	ld	(xwa), 127
	ld	(xbc), 0
	ld	(xde), 100
	ld	(xhl), 0
	ldto_berp a, 251
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xsp+12)
	call	SeMenu_ApplyPartEdit_Helper5
	cp	(xsp+14), 0
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
	ldto_berp c, 251
	extz	bc
	ld	e, (xsp+16)
	extz	de
	extz	wa
	pushw	wa
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 45
	call	SeMenu_ApplyPartEdit_Helper2
	call	Scoop_SoundEditorData_Helper8
	ld	wa, 2:i3
	call	SeMenu_ApplyPartEdit_Helper4
	pop qiz
	lda	xsp, (xsp+18)
	ret
	lda	xsp, (xsp-18)
	push	qiz
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
	ldib_erp	251, 3
	cp	(xsp+14), 0
	jr	nz, Scoop_SoundEditorData_Skip56
	ldib_erp 251, 2
Scoop_SoundEditorData_Skip56:
	ld	(xwa), 127
	ld	(xbc), 0
	ld	(xde), 100
	ld	(xhl), 0
	ldto_berp a, 251
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xsp+12)
	call	SeMenu_ApplyPartEdit_Helper5
	cp	(xsp+14), 0
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
	ldto_berp c, 251
	extz	bc
	ld	e, (xsp+16)
	extz	de
	extz	wa
	pushw	wa
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 45
	call	SeMenu_ApplyPartEdit_Helper2
	call	Scoop_SoundEditorData_Helper8
	ld	wa, 3:i3
	call	SeMenu_ApplyPartEdit_Helper4
	pop qiz
	lda	xsp, (xsp+18)
	ret
	lda	xsp, (xsp-18)
	push	qiz
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
	ldib_erp	251, 4
	cp	(xsp+14), 0
	jr	nz, Scoop_SoundEditorData_Skip57
	ldib_erp 251, 3
Scoop_SoundEditorData_Skip57:
	ld	(xwa), 127
	ld	(xbc), 0
	ld	(xde), 100
	ld	(xhl), 0
	ldto_berp a, 251
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xsp+12)
	call	SeMenu_ApplyPartEdit_Helper5
	cp	(xsp+14), 0
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
	ldto_berp c, 251
	extz	bc
	ld	e, (xsp+16)
	extz	de
	extz	wa
	pushw	wa
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 45
	call	SeMenu_ApplyPartEdit_Helper2
	call	Scoop_SoundEditorData_Helper8
	ld	wa, 4:i3
	call	SeMenu_ApplyPartEdit_Helper4
	pop qiz
	lda	xsp, (xsp+18)
	ret
	lda	xsp, (xsp-20)
	push	qiz
	ld	(xsp+20), a
	lda	xwa, (xsp+18)
	call	SeMenu_ValidatePartNumber
	lda	xwa, (xsp+16)
	call	SeMenu_LoadObjEntries
	cp	(xsp+16), 0
	jr	nz, Scoop_SoundEditorData_Skip58
	ldib_erp 251, 4
	lda	xwa, (xsp+2)
	ld	(xwa+6), 127
	ld	(xwa+7), 0
	ld	(xwa+8), 100
	jr	Scoop_SoundEditorData_Join11
Scoop_SoundEditorData_Skip58:
	lda	xbc, (xsp+14)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	bitm	5, (xsp+14)
	jr	z, Scoop_SoundEditorData_Epilogue41
	ldib_erp	251, 5
	lda	xwa, (xsp+2)
	ld	(xwa+6), 127
	ld	(xwa+7), 0
	ld	(xwa+8), 100
Scoop_SoundEditorData_Join11:
	ld	(xwa+9), 0
	ldto_berp a, 251
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	ld	a, (xsp+20)
	extz	wa
	lda	xbc, (xsp+12)
	call	SeMenu_ApplyPartEdit_Helper5
	cp	(xsp+16), 0
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
	ldto_berp c, 251
	extz	bc
	ld	e, (xsp+18)
	extz	de
	extz	wa
	pushw	wa
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 45
	call	SeMenu_ApplyPartEdit_Helper2
	call	Scoop_SoundEditorData_Helper8
	ld	wa, 5:i3
	call	SeMenu_ApplyPartEdit_Helper4
Scoop_SoundEditorData_Epilogue41:
	pop qiz
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-20)
	push	qiz
	ld	(xsp+20), a
	lda	xwa, (xsp+18)
	call	SeMenu_ValidatePartNumber
	lda	xwa, (xsp+16)
	call	SeMenu_LoadObjEntries
	cp	(xsp+16), 0
	jr	nz, Scoop_SoundEditorData_Skip59
	ldib_erp 251, 5
	lda	xwa, (xsp+2)
	ld	(xwa+6), 127
	ld	(xwa+7), 0
	ld	(xwa+8), 100
	jr	Scoop_SoundEditorData_Join13
Scoop_SoundEditorData_Skip59:
	lda	xbc, (xsp+14)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	bitm	5, (xsp+14)
	jr	z, Scoop_SoundEditorData_Epilogue42
	ldib_erp	251, 6
	lda	xwa, (xsp+2)
	ld	(xwa+6), 127
	ld	(xwa+7), 0
	ld	(xwa+8), 100
Scoop_SoundEditorData_Join13:
	ld	(xwa+9), 0
	ldto_berp a, 251
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	ld	a, (xsp+20)
	extz	wa
	lda	xbc, (xsp+12)
	call	SeMenu_ApplyPartEdit_Helper5
	cp	(xsp+16), 0
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
	ldto_berp c, 251
	extz	bc
	ld	e, (xsp+18)
	extz	de
	extz	wa
	pushw	wa
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 45
	call	SeMenu_ApplyPartEdit_Helper2
	call	Scoop_SoundEditorData_Helper8
	ld	wa, 6:i3
	call	SeMenu_ApplyPartEdit_Helper4
Scoop_SoundEditorData_Epilogue42:
	pop qiz
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-18)
	ld	(xsp+16), a
	lda	xwa, (xsp+12)
	call	SeMenu_LoadObjEntries
	cp	(xsp+12), 1
	jr	z, Scoop_SoundEditorData_Epilogue43
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
	call	SeMenu_ApplyPartEdit_Helper5
	ld	e, (xsp+14)
	extz	de
	pushw	45
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 45
	ld	bc, 6:i3
	call	SeMenu_ApplyPartEdit_Helper2
	call	Scoop_SoundEditorData_Helper8
	ld	wa, 7:i3
	call	SeMenu_ApplyPartEdit_Helper4
Scoop_SoundEditorData_Epilogue43:
	lda	xsp, (xsp+18)
	ret
	lda	xsp, (xsp-18)
	ld	(xsp+16), a
	lda	xwa, (xsp+12)
	call	SeMenu_LoadObjEntries
	cp	(xsp+12), 0
	jr	z, Scoop_SoundEditorData_Epilogue44
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
	call	SeMenu_ApplyPartEdit_Helper5
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
	call	SeMenu_ApplyPartEdit_Helper2
	ldw	wa, 8
	call	SeMenu_ApplyPartEdit_Helper4
Scoop_SoundEditorData_Epilogue44:
	lda	xsp, (xsp+18)
	ret
	cp	a, 0:i3
	ret	z
	call	Scoop_SoundEditorData_Helper3
	ret
	cp	a, 0:i3
	jr	nz, Scoop_SoundEditorData_Skip17
	ldw	wa, 43
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join15
Scoop_SoundEditorData_Skip17:
	ld	wa, 1:i3
	call	Scoop_SoundEditorData_Helper5
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
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Skip18
	cp	(xsp), 0
	jr	nz, Scoop_SoundEditorData_Epilogue7
	ldw	wa, 47
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join16
Scoop_SoundEditorData_Skip18:
	ld	wa, 2:i3
	call	Scoop_SoundEditorData_Helper5
	cp	l, 0:i3
	jr	z, Scoop_SoundEditorData_Epilogue7
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
	cp	(xsp), 1
	jr	z, Scoop_SoundEditorData_Epilogue45
	cp	(xsp+2), 0
	jr	z, Scoop_SoundEditorData_Epilogue45
	ld	wa, 3:i3
	call	Scoop_SoundEditorData_Helper5
	cp	l, 0:i3
	jr	z, Scoop_SoundEditorData_Epilogue45
	ldw	wa, 45
	ld	bc, 1:i3
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue45:
	inc	4, xsp
	ret
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp+2)
	call	SeMenu_LoadObjEntries
	cp	(xsp+4), 0
	jr	z, Scoop_SoundEditorData_Epilogue8
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Skip19
	ld	wa, 4:i3
	call	Scoop_SoundEditorData_Helper5
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
	bitm	5, (xsp)
	jr	z, Scoop_SoundEditorData_Skip60
	resm	5, (xsp)
	jr	Scoop_SoundEditorData_Join17
Scoop_SoundEditorData_Skip60:
	setm	5, (xsp)
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
	call	Scoop_SoundEditorData_Helper8
Scoop_SoundEditorData_Epilogue8:
	inc	6, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, Scoop_SoundEditorData_Epilogue46
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Epilogue46
	ldw	wa, 46
	ld	bc, 0:i3
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue46:
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Epilogue9
	cp	(xsp), 0
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
	call	SeMenu_ApplyPartEdit_Helper5
	ld	e, (xsp+14)
	extz	de
	pushw	51
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 46
	ld	bc, 5:i3
	call	SeMenu_ApplyPartEdit_Helper2
	lda	xbc, (xsp+12)
	ld	wa, 5:i3
	call	SeMenu_LoadPartParam
	ld	c, (xsp+12)
	extz	bc
	ldw	wa, 10
	call	SeMenu_StorePartParam
	ld	wa, 2:i3
	ld	bc, 0:i3
	call	SeMenu_ApplyPartEdit_Helper11
	lda	xbc, (xsp+12)
	ldw	wa, 9
	call	SeMenu_LoadPartParam
	cp	(xsp+12), 0
	jr	z, Scoop_SoundEditorData_Skip61
	ldw	wa, 9
	ld	bc, 0:i3
	call	SeMenu_StorePartParam
	pushw	9
	pushw	46
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
Scoop_SoundEditorData_Skip61:
	ld	wa, 1:i3
	call	SeMenu_ApplyPartEdit_Helper4
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
	call	SeMenu_ApplyPartEdit_Helper5
	ld	e, (xsp+14)
	extz	de
	pushw	52
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 46
	ld	bc, 6:i3
	call	SeMenu_ApplyPartEdit_Helper2
	lda	xbc, (xsp+12)
	ld	wa, 6:i3
	call	SeMenu_LoadPartParam
	ld	c, (xsp+12)
	extz	bc
	ldw	wa, 10
	call	SeMenu_StorePartParam
	ld	wa, 2:i3
	ld	bc, 0:i3
	call	SeMenu_ApplyPartEdit_Helper11
	lda	xbc, (xsp+12)
	ldw	wa, 9
	call	SeMenu_LoadPartParam
	cp	(xsp+12), 1
	jr	z, Scoop_SoundEditorData_Skip62
	ldw	wa, 9
	ld	bc, 1:i3
	call	SeMenu_StorePartParam
	pushw	9
	pushw	46
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
Scoop_SoundEditorData_Skip62:
	ld	wa, 2:i3
	call	SeMenu_ApplyPartEdit_Helper4
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
	call	SeMenu_ApplyPartEdit_Helper5
	ld	e, (xsp+14)
	extz	de
	pushw	53
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 46
	ld	bc, 7:i3
	call	SeMenu_ApplyPartEdit_Helper2
	lda	xbc, (xsp+12)
	ld	wa, 7:i3
	call	SeMenu_LoadPartParam
	ld	c, (xsp+12)
	extz	bc
	ldw	wa, 10
	call	SeMenu_StorePartParam
	ld	wa, 2:i3
	ld	bc, 0:i3
	call	SeMenu_ApplyPartEdit_Helper11
	lda	xbc, (xsp+12)
	ldw	wa, 9
	call	SeMenu_LoadPartParam
	cp	(xsp+12), 2
	jr	z, Scoop_SoundEditorData_Skip63
	ldw	wa, 9
	ld	bc, 2:i3
	call	SeMenu_StorePartParam
	pushw	9
	pushw	46
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
Scoop_SoundEditorData_Skip63:
	ld	wa, 3:i3
	call	SeMenu_ApplyPartEdit_Helper4
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
	call	SeMenu_ApplyPartEdit_Helper13
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
	call	SeMenu_ApplyPartEdit_Helper11
Scoop_SoundEditorData_Skip21:
	ld	wa, 4:i3
	call	SeMenu_ApplyPartEdit_Helper4
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
	call	SeMenu_ApplyPartEdit_Helper13
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
	call	SeMenu_ApplyPartEdit_Helper11
Scoop_SoundEditorData_Skip22:
	ld	wa, 5:i3
	call	SeMenu_ApplyPartEdit_Helper4
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
	call	SeMenu_ApplyPartEdit_Helper13
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
	call	SeMenu_ApplyPartEdit_Helper11
Scoop_SoundEditorData_Skip23:
	ld	wa, 6:i3
	call	SeMenu_ApplyPartEdit_Helper4
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
	call	SeMenu_ApplyPartEdit_Helper5
	ld	e, (xsp+12)
	extz	de
	pushw	46
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 46
	ld	bc, 0:i3
	call	SeMenu_ApplyPartEdit_Helper2
	ld	wa, 7:i3
	call	SeMenu_ApplyPartEdit_Helper4
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
	call	SeMenu_ApplyPartEdit_Helper5
	ld	e, (xsp+12)
	extz	de
	pushw	47
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 46
	ld	bc, 1:i3
	call	SeMenu_ApplyPartEdit_Helper2
	ldw	wa, 8
	call	SeMenu_ApplyPartEdit_Helper4
	lda	xsp, (xsp+16)
	ret
	cp	a, 0:i3
	ret	z
	call	Scoop_SoundEditorData_Helper3
	ret
	cp	a, 0:i3
	jr	nz, Scoop_SoundEditorData_Skip24
	ldw	wa, 43
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join19
Scoop_SoundEditorData_Skip24:
	ld	wa, 1:i3
	call	Scoop_SoundEditorData_Helper5
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
	call	Scoop_SoundEditorData_Helper5
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
	call	Scoop_SoundEditorData_Helper5
	cp	l, 0:i3
	ret	z
	ldw	wa, 46
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	ret	z
	ld	wa, 4:i3
	call	Scoop_SoundEditorData_Helper5
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
	jp	SeMenu_ApplyPartEdit_AltStore_Join
	extz	wa
	ld	bc, 0:i3
	jp	SeMenu_ApplyPartEdit_AltStore_Join2
	extz	wa
	ld	bc, 0:i3
	jp	SeMenu_ApplyPartEdit_AltStore_Join3
	extz	wa
	ld	bc, 0:i3
	jp	SeMenu_ApplyPartEdit_AltStore_Join4
	extz	wa
	ld	bc, 0:i3
	jp	SeMenu_ApplyPartEdit_AltStore_Join5
	extz	wa
	ld	bc, 0:i3
	jp	SeMenu_ApplyPartEdit_AltStore_Join6
	cp	a, 0:i3
	jp	nz, (Scoop_SoundEditorData_Helper3:24)
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
	jp	Scoop_SoundEditorData_Helper6
	cp	a, 0:i3
	ret	z
	ld	wa, 0:i3
	ld	bc, 2:i3
	call	Scoop_SoundEditorData_Helper6
	ret
	cp	a, 0:i3
	ret	z
	ld	wa, 0:i3
	ld	bc, 3:i3
	call	Scoop_SoundEditorData_Helper6
	ret
	cp	a, 0:i3
	ret	z
	ld	wa, 0:i3
	ld	bc, 4:i3
	call	Scoop_SoundEditorData_Helper6
	ret
	cp	a, 0:i3
	ret	nz
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	ldw	wa, 32
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
Scoop_SoundEditorData_Join53:
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	Scoop_SoundEditorData_Helper7
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
Scoop_SoundEditorData_Join54:
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	Scoop_SoundEditorData_Helper7
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
Scoop_SoundEditorData_Join55:
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	Scoop_SoundEditorData_Helper7
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
Scoop_SoundEditorData_Join56:
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	Scoop_SoundEditorData_Helper7
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
Scoop_SoundEditorData_Join57:
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	Scoop_SoundEditorData_Helper7
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
Scoop_SoundEditorData_Join58:
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	Scoop_SoundEditorData_Helper7
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
Scoop_SoundEditorData_Join59:
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	Scoop_SoundEditorData_Helper7
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
Scoop_SoundEditorData_Join60:
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	Scoop_SoundEditorData_Helper7
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
Scoop_SoundEditorData_Join61:
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	Scoop_SoundEditorData_Helper7
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
Scoop_SoundEditorData_Join62:
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	Scoop_SoundEditorData_Helper7
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
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Helper4
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
	call	SeMenu_ApplyPartEdit_Helper5
	cp	(xsp+12), 0
	jr	nz, Scoop_SoundEditorData_Helper_Skip
	ld	c, 77:opc
	jr	Scoop_SoundEditorData_Helper_Join
Scoop_SoundEditorData_Helper_Skip:
	ld	a, (xsp+14)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+17)
	ld	c, a
	ld	(xsp+14), 0
Scoop_SoundEditorData_Helper_Join:
	ld	a, (xsp+16)
	extz	wa
	ld	e, (xsp+14)
	extz	de
	extz	bc
	pushw	bc
	lda	xbc, (xsp+2)
	push	xbc
	ld	bc, 2:i3
	call	SeMenu_ApplyPartEdit_Helper2
	ld	a, (xsp+18)
	extz	wa
	call	SeMenu_ApplyPartEdit_Helper4
	lda	xsp, (xsp+22)
	ret
	extz	wa
	ld	bc, 2:i3
	ldw	de, 48
	calr	Scoop_SoundEditorData_Helper2
	ld	wa, 0:i3
	ld	bc, 0:i3
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Helper4
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
	call	SeMenu_ApplyPartEdit_Helper5
	cp	(xsp+12), 0
	jr	nz, Scoop_SoundEditorData_Helper2_Skip
	ld	c, 78:opc
	jr	Scoop_SoundEditorData_Helper2_Join
Scoop_SoundEditorData_Helper2_Skip:
	ld	a, (xsp+14)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+18)
	ld	c, a
	ld	(xsp+14), 0
Scoop_SoundEditorData_Helper2_Join:
	ld	a, (xsp+16)
	extz	wa
	ld	e, (xsp+14)
	extz	de
	extz	bc
	pushw	bc
	lda	xbc, (xsp+2)
	push	xbc
	ld	bc, 3:i3
	call	SeMenu_ApplyPartEdit_Helper2
	ld	a, (xsp+18)
	extz	wa
	call	SeMenu_ApplyPartEdit_Helper4
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
	call	SeMenu_ApplyPartEdit_Helper5
	cp	(xsp+12), 0
	jr	nz, Scoop_SoundEditorData_Helper2_Skip2
	ld	c, 55:opc
	jr	Scoop_SoundEditorData_Helper2_Join2
Scoop_SoundEditorData_Helper2_Skip2:
	ld	a, (xsp+14)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+16)
	ld	c, a
	ld	(xsp+14), 0
Scoop_SoundEditorData_Helper2_Join2:
	ld	a, (xsp+16)
	extz	wa
	ld	e, (xsp+14)
	extz	de
	extz	bc
	pushw	bc
	lda	xbc, (xsp+2)
	push	xbc
	ld	bc, 1:i3
	call	SeMenu_ApplyPartEdit_Helper2
	ld	a, (xsp+18)
	extz	wa
	call	SeMenu_ApplyPartEdit_Helper4
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
	call	SeMenu_ApplyPartEdit_Helper5
	cp	(xsp+12), 0
	jr	nz, Scoop_SoundEditorData_Helper2_Skip3
	ld	c, 54:opc
	jr	Scoop_SoundEditorData_Helper2_Join3
Scoop_SoundEditorData_Helper2_Skip3:
	ld	a, (xsp+14)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+15)
	ld	c, a
	ld	(xsp+14), 0
Scoop_SoundEditorData_Helper2_Join3:
	ld	a, (xsp+16)
	extz	wa
	ld	e, (xsp+14)
	extz	de
	extz	bc
	pushw	bc
	lda	xbc, (xsp+2)
	push	xbc
	ld	bc, 0:i3
	call	SeMenu_ApplyPartEdit_Helper2
	ld	a, (xsp+18)
	extz	wa
	call	SeMenu_ApplyPartEdit_Helper4
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
	jr	nz, Scoop_SoundEditorData_Helper2_Skip4
	ld	(xwa), 1
	jr	Scoop_SoundEditorData_Helper2_Join4
Scoop_SoundEditorData_Helper2_Skip4:
	ld	(xwa), 255
Scoop_SoundEditorData_Helper2_Join4:
	cp	(xsp+12), 0
	jr	nz, Scoop_SoundEditorData_Helper2_Skip5
	ld	a, 80:opc
	jr	Scoop_SoundEditorData_Helper2_Join5
Scoop_SoundEditorData_Helper2_Skip5:
	ld	a, (xsp+14)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+20)
	ld	(xsp+14), 0
Scoop_SoundEditorData_Helper2_Join5:
	ld	e, (xsp+14)
	extz	de
	extz	wa
	pushw	wa
	push	xbc
	ldw	wa, 48
	ld	bc, 5:i3
	call	SeMenu_ApplyPartEdit_Helper2
	cp	l, 1:i3
	call	z, (Scoop_SoundEditorData_Helper10:24)
	ld	wa, 6:i3
	call	SeMenu_ApplyPartEdit_Helper4
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
	call	SeMenu_ApplyPartEdit_Helper5
	cp	(xsp+12), 0
	jr	nz, Scoop_SoundEditorData_Helper2_Skip6
	ld	a, 79:opc
	jr	Scoop_SoundEditorData_Helper2_Join6
Scoop_SoundEditorData_Helper2_Skip6:
	ld	a, (xsp+14)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+19)
	ld	(xsp+14), 0
Scoop_SoundEditorData_Helper2_Join6:
	ld	e, (xsp+14)
	extz	de
	extz	wa
	pushw	wa
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 48
	ld	bc, 4:i3
	call	SeMenu_ApplyPartEdit_Helper2
	cp	l, 1:i3
	call	z, (Scoop_SoundEditorData_Helper10:24)
	ld	wa, 7:i3
	call	SeMenu_ApplyPartEdit_Helper4
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
	call	SeMenu_ApplyPartEdit_Helper5
	cp	(xsp+12), 0
	jr	nz, Scoop_SoundEditorData_Helper2_Skip7
	ld	a, 80:opc
	jr	Scoop_SoundEditorData_Helper2_Join7
Scoop_SoundEditorData_Helper2_Skip7:
	ld	a, (xsp+14)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+20)
	ld	(xsp+14), 0
Scoop_SoundEditorData_Helper2_Join7:
	ld	e, (xsp+14)
	extz	de
	extz	wa
	pushw	wa
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 48
	ld	bc, 5:i3
	call	SeMenu_ApplyPartEdit_Helper2
	cp	l, 1:i3
	call	z, (Scoop_SoundEditorData_Helper10:24)
	ldw	wa, 8
	call	SeMenu_ApplyPartEdit_Helper4
	lda	xsp, (xsp+18)
	ret
Scoop_SoundEditorData_Join26:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Skip27
	cp	(xsp), 0
	jr	nz, Scoop_SoundEditorData_Epilogue20
	ldw	wa, 55
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	jr	Scoop_SoundEditorData_Epilogue20
Scoop_SoundEditorData_Skip27:
	call	Scoop_SoundEditorData_Helper3
Scoop_SoundEditorData_Epilogue20:
	inc	4, xsp
	ret
Scoop_SoundEditorData_Join27:
	cp	a, 0:i3
	ret	z
	ld	wa, 1:i3
	call	Scoop_SoundEditorData_Helper5
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
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Skip28
	cp	(xsp), 0
	jr	nz, Scoop_SoundEditorData_Epilogue21
	ldw	wa, 57
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join29
Scoop_SoundEditorData_Skip28:
	ld	wa, 2:i3
	call	Scoop_SoundEditorData_Helper5
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
	cp	(xsp+4), 0
	jr	nz, Scoop_SoundEditorData_Helper2_Skip8
	lda	xbc, (xsp+2)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	andmi8	(xsp+2), 248
	setm	1, (xsp+2)
	ld	a, (xsp+2)
	extz	wa
	call	Scoop_SoundEditorData_Helper4
	ldw	wa, 48
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Helper2_Join8
Scoop_SoundEditorData_Helper2_Skip8:
	cp	(xsp), 1
	jr	z, Scoop_SoundEditorData_Helper2_Epilogue
	ld	wa, 3:i3
	call	Scoop_SoundEditorData_Helper5
	cp	l, 0:i3
	jr	z, Scoop_SoundEditorData_Helper2_Epilogue
	ldw	wa, 48
	ld	bc, 0:i3
Scoop_SoundEditorData_Helper2_Join8:
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Helper2_Epilogue:
	inc	6, xsp
	ret
Scoop_SoundEditorData_Join30:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 0
	jr	z, Scoop_SoundEditorData_Helper2_Epilogue2
	cp	(xsp), 1
	jr	z, Scoop_SoundEditorData_Helper2_Epilogue2
	ld	wa, 4:i3
	call	Scoop_SoundEditorData_Helper5
	cp	l, 0:i3
	jr	z, Scoop_SoundEditorData_Helper2_Epilogue2
	ldw	wa, 48
	ld	bc, 0:i3
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Helper2_Epilogue2:
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, Scoop_SoundEditorData_Helper2_Epilogue3
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Helper2_Epilogue3
	ldw	wa, 54
	ld	bc, 0:i3
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Helper2_Epilogue3:
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Epilogue22
	cp	(xsp), 0
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
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Helper4
	extz	wa
	ld	bc, 2:i3
	ldw	de, 49
	calr	Scoop_SoundEditorData_Helper2
	ld	wa, 1:i3
	ld	bc, 0:i3
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Helper4
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
	cp	(xsp+4), 0
	jr	nz, Scoop_SoundEditorData_Helper2_Skip9
	lda	xbc, (xsp+2)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	andmi8	(xsp+2), 248
	ormi8	(xsp+2), 3
	ld	a, (xsp+2)
	extz	wa
	call	Scoop_SoundEditorData_Helper4
	ldw	wa, 48
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Helper2_Join9
Scoop_SoundEditorData_Helper2_Skip9:
	cp	(xsp), 0
	jr	nz, Scoop_SoundEditorData_Epilogue23
	ld	wa, 3:i3
	call	Scoop_SoundEditorData_Helper5
	cp	l, 0:i3
	jr	z, Scoop_SoundEditorData_Epilogue23
	ldw	wa, 48
	ld	bc, 0:i3
Scoop_SoundEditorData_Helper2_Join9:
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
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Epilogue24
	cp	(xsp), 0
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
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Epilogue25
	cp	(xsp), 0
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
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Helper4
	extz	wa
	ld	bc, 4:i3
	ldw	de, 50
	calr	Scoop_SoundEditorData_Helper2
	ld	wa, 0:i3
	ld	bc, 1:i3
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Helper4
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
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Skip31
	cp	(xsp), 0
	jr	nz, Scoop_SoundEditorData_Epilogue26
	ldw	wa, 55
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	jr	Scoop_SoundEditorData_Epilogue26
Scoop_SoundEditorData_Skip31:
	call	Scoop_SoundEditorData_Helper3
Scoop_SoundEditorData_Epilogue26:
	inc	4, xsp
	ret
Scoop_SoundEditorData_Join34:
	cp	a, 0:i3
	ret	z
	ld	wa, 1:i3
	call	Scoop_SoundEditorData_Helper5
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
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Skip32
	cp	(xsp), 0
	jr	nz, Scoop_SoundEditorData_Epilogue27
	ldw	wa, 57
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join36
Scoop_SoundEditorData_Skip32:
	ld	wa, 2:i3
	call	Scoop_SoundEditorData_Helper5
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
	cp	(xsp+4), 0
	jr	nz, Scoop_SoundEditorData_Helper2_Skip10
	lda	xbc, (xsp+2)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	andmi8	(xsp+2), 248
	setm	2, (xsp+2)
	ld	a, (xsp+2)
	extz	wa
	call	Scoop_SoundEditorData_Helper4
	ldw	wa, 48
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Helper2_Join10
Scoop_SoundEditorData_Helper2_Skip10:
	cp	(xsp), 1
	jr	z, Scoop_SoundEditorData_Helper2_Epilogue4
	ld	wa, 3:i3
	call	Scoop_SoundEditorData_Helper5
	cp	l, 0:i3
	jr	z, Scoop_SoundEditorData_Helper2_Epilogue4
	ldw	wa, 48
	ld	bc, 0:i3
Scoop_SoundEditorData_Helper2_Join10:
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Helper2_Epilogue4:
	inc	6, xsp
	ret
Scoop_SoundEditorData_Helper2_Join11:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, Scoop_SoundEditorData_Helper2_Epilogue5
	cp	(xsp+2), 0
	jr	z, Scoop_SoundEditorData_Helper2_Epilogue5
	ld	wa, 4:i3
	call	Scoop_SoundEditorData_Helper5
	cp	l, 0:i3
	jr	z, Scoop_SoundEditorData_Helper2_Epilogue5
	ldw	wa, 48
	ld	bc, 0:i3
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Helper2_Epilogue5:
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, Scoop_SoundEditorData_Helper2_Epilogue6
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Helper2_Epilogue6
	ldw	wa, 54
	ld	bc, 0:i3
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Helper2_Epilogue6:
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Epilogue28
	cp	(xsp), 0
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
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Helper4
	extz	wa
	ld	bc, 4:i3
	ldw	de, 51
	calr	Scoop_SoundEditorData_Helper2
	ld	wa, 1:i3
	ld	bc, 1:i3
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Helper4
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
	cp	(xsp+4), 0
	jr	nz, Scoop_SoundEditorData_Helper2_Skip11
	lda	xbc, (xsp+2)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	andmi8	(xsp+2), 248
	ormi8	(xsp+2), 5
	ld	a, (xsp+2)
	extz	wa
	call	Scoop_SoundEditorData_Helper4
	ldw	wa, 48
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Helper2_Join12
Scoop_SoundEditorData_Helper2_Skip11:
	cp	(xsp), 1
	jr	z, Scoop_SoundEditorData_Helper2_Epilogue7
	ld	wa, 3:i3
	call	Scoop_SoundEditorData_Helper5
	cp	l, 0:i3
	jr	z, Scoop_SoundEditorData_Helper2_Epilogue7
	ldw	wa, 48
	ld	bc, 0:i3
Scoop_SoundEditorData_Helper2_Join12:
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Helper2_Epilogue7:
	inc	6, xsp
	ret
	extz	wa
	jrl	Scoop_SoundEditorData_Helper2_Join11
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, Scoop_SoundEditorData_Helper2_Epilogue8
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Helper2_Epilogue8
	ldw	wa, 54
	ld	bc, 0:i3
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Helper2_Epilogue8:
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Epilogue29
	cp	(xsp), 0
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
	call	SeMenu_ApplyPartEdit_Helper5
	cp	(xsp+12), 0
	jr	nz, Scoop_SoundEditorData_Helper2_Skip12
	ld	a, 77:opc
	jr	Scoop_SoundEditorData_Helper2_Join13
Scoop_SoundEditorData_Helper2_Skip12:
	ld	a, (xsp+16)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+17)
	ld	(xsp+16), 0
Scoop_SoundEditorData_Helper2_Join13:
	ld	e, (xsp+16)
	extz	de
	extz	wa
	pushw	wa
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 52
	ld	bc, 2:i3
	call	SeMenu_ApplyPartEdit_Helper2
	call	Scoop_SoundEditorData_Helper11
	ld	wa, 2:i3
	call	SeMenu_ApplyPartEdit_Helper4
	lda	xsp, (xsp+20)
	ret
	extz	wa
	ld	bc, 3:i3
	ldw	de, 52
	calr	Scoop_SoundEditorData_Helper2
	jp	Scoop_SoundEditorData_Helper11
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
	call	SeMenu_ApplyPartEdit_Helper5
	lda	xbc, (xsp)
	cp	(xsp+12), 0
	jr	nz, Scoop_SoundEditorData_Helper2_Skip13
	ld	e, (xsp+16)
	extz	de
	pushw	79
	push	xbc
	ldw	wa, 52
	ld	bc, 4:i3
	jr	Scoop_SoundEditorData_Helper2_Join14
Scoop_SoundEditorData_Helper2_Skip13:
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
Scoop_SoundEditorData_Helper2_Join14:
	call	SeMenu_ApplyPartEdit_Helper2
	call	Scoop_SoundEditorData_Helper11
	ld	wa, 4:i3
	call	SeMenu_ApplyPartEdit_Helper4
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
	call	SeMenu_ApplyPartEdit_Helper5
	lda	xbc, (xsp)
	cp	(xsp+12), 0
	jr	nz, Scoop_SoundEditorData_Helper2_Skip14
	ld	e, (xsp+14)
	extz	de
	pushw	80
	push	xbc
	ldw	wa, 52
	ld	bc, 5:i3
	jr	Scoop_SoundEditorData_Helper2_Join15
Scoop_SoundEditorData_Helper2_Skip14:
	ld	a, (xsp+14)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+20)
	extz	wa
	pushw	wa
	push	xbc
	ldw	wa, 52
	ld	bc, 5:i3
	ld	de, 0:i3
Scoop_SoundEditorData_Helper2_Join15:
	call	SeMenu_ApplyPartEdit_Helper2
	call	Scoop_SoundEditorData_Helper11
	ld	wa, 5:i3
	call	SeMenu_ApplyPartEdit_Helper4
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
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Skip35
	cp	(xsp), 0
	jr	nz, Scoop_SoundEditorData_Epilogue30
	ldw	wa, 55
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	jr	Scoop_SoundEditorData_Epilogue30
Scoop_SoundEditorData_Skip35:
	call	Scoop_SoundEditorData_Helper3
Scoop_SoundEditorData_Epilogue30:
	inc	4, xsp
	ret
	cp	a, 0:i3
	ret	z
	ld	wa, 1:i3
	call	Scoop_SoundEditorData_Helper5
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
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Skip36
	cp	(xsp), 0
	jr	nz, Scoop_SoundEditorData_Epilogue31
	ldw	wa, 57
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join39
Scoop_SoundEditorData_Skip36:
	ld	wa, 2:i3
	call	Scoop_SoundEditorData_Helper5
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
	cp	(xsp+4), 0
	jr	nz, Scoop_SoundEditorData_Helper2_Skip15
	lda	xbc, (xsp+2)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	andmi8	(xsp+2), 248
	ld	a, (xsp+2)
	extz	wa
	call	Scoop_SoundEditorData_Helper4
	ldw	wa, 48
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Helper2_Join16
Scoop_SoundEditorData_Helper2_Skip15:
	cp	(xsp), 1
	jr	z, Scoop_SoundEditorData_Helper2_Epilogue9
	ld	wa, 3:i3
	call	Scoop_SoundEditorData_Helper5
	cp	l, 0:i3
	jr	z, Scoop_SoundEditorData_Helper2_Epilogue9
	ldw	wa, 48
	ld	bc, 0:i3
Scoop_SoundEditorData_Helper2_Join16:
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Helper2_Epilogue9:
	inc	6, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, Scoop_SoundEditorData_Helper2_Epilogue10
	cp	(xsp+2), 0
	jr	z, Scoop_SoundEditorData_Helper2_Epilogue10
	ld	wa, 4:i3
	call	Scoop_SoundEditorData_Helper5
	cp	l, 0:i3
	jr	z, Scoop_SoundEditorData_Helper2_Epilogue10
	ldw	wa, 48
	ld	bc, 0:i3
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Helper2_Epilogue10:
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, Scoop_SoundEditorData_Helper2_Epilogue11
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Helper2_Epilogue11
	ldw	wa, 54
	ld	bc, 0:i3
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Helper2_Epilogue11:
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Epilogue32
	cp	(xsp), 0
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
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Skip38
	cp	(xsp), 0
	jr	nz, Scoop_SoundEditorData_Epilogue33
	ldw	wa, 55
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	jr	Scoop_SoundEditorData_Epilogue33
Scoop_SoundEditorData_Skip38:
	call	Scoop_SoundEditorData_Helper3
Scoop_SoundEditorData_Epilogue33:
	inc	4, xsp
	ret
	cp	a, 0:i3
	ret	z
	ld	wa, 1:i3
	call	Scoop_SoundEditorData_Helper5
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
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Skip39
	cp	(xsp), 0
	jr	nz, Scoop_SoundEditorData_Epilogue34
	ldw	wa, 57
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join41
Scoop_SoundEditorData_Skip39:
	ld	wa, 2:i3
	call	Scoop_SoundEditorData_Helper5
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
	cp	(xsp+4), 0
	jr	nz, Scoop_SoundEditorData_Helper2_Skip16
	lda	xbc, (xsp+2)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	andmi8	(xsp+2), 248
	setm	0, (xsp+2)
	ld	a, (xsp+2)
	extz	wa
	call	Scoop_SoundEditorData_Helper4
	ldw	wa, 48
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Helper2_Join17
Scoop_SoundEditorData_Helper2_Skip16:
	cp	(xsp), 1
	jr	z, Scoop_SoundEditorData_Helper2_Epilogue12
	ld	wa, 3:i3
	call	Scoop_SoundEditorData_Helper5
	cp	l, 0:i3
	jr	z, Scoop_SoundEditorData_Helper2_Epilogue12
	ldw	wa, 48
	ld	bc, 0:i3
Scoop_SoundEditorData_Helper2_Join17:
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Helper2_Epilogue12:
	inc	6, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, Scoop_SoundEditorData_Helper2_Epilogue13
	cp	(xsp+2), 0
	jr	z, Scoop_SoundEditorData_Helper2_Epilogue13
	ld	wa, 4:i3
	call	Scoop_SoundEditorData_Helper5
	cp	l, 0:i3
	jr	z, Scoop_SoundEditorData_Helper2_Epilogue13
	ldw	wa, 48
	ld	bc, 0:i3
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Helper2_Epilogue13:
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, Scoop_SoundEditorData_Helper2_Epilogue14
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Helper2_Epilogue14
	ldw	wa, 54
	ld	bc, 0:i3
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Helper2_Epilogue14:
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Epilogue35
	cp	(xsp), 0
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
	call	SeMenu_ApplyPartEdit_Helper5
	ld	e, (xsp+14)
	extz	de
	pushw	60
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 54
	ld	bc, 3:i3
	call	SeMenu_ApplyPartEdit_Helper2
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
	call	SeMenu_ApplyPartEdit_Helper11
Scoop_SoundEditorData_Skip41:
	ld	wa, 3:i3
	call	SeMenu_ApplyPartEdit_Helper4
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
	call	SeMenu_ApplyPartEdit_Helper13
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
	call	SeMenu_ApplyPartEdit_Helper11
Scoop_SoundEditorData_Skip42:
	ld	wa, 4:i3
	call	SeMenu_ApplyPartEdit_Helper4
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
	call	SeMenu_ApplyPartEdit_Helper13
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
	call	SeMenu_ApplyPartEdit_Helper11
Scoop_SoundEditorData_Skip43:
	ld	wa, 5:i3
	call	SeMenu_ApplyPartEdit_Helper4
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
	call	SeMenu_ApplyPartEdit_Helper13
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
	call	SeMenu_ApplyPartEdit_Helper11
Scoop_SoundEditorData_Skip44:
	ld	wa, 6:i3
	call	SeMenu_ApplyPartEdit_Helper4
	inc	8, xsp
	ret
	cp	a, 0:i3
	jp	nz, (Scoop_SoundEditorData_Helper3:24)
	ldw	wa, 55
	ld	bc, 0:i3
	jp	SeMenu_SendEvent
	cp	a, 0:i3
	ret	z
	ld	wa, 1:i3
	call	Scoop_SoundEditorData_Helper5
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
	call	Scoop_SoundEditorData_Helper5
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
	call	Scoop_SoundEditorData_Helper5
	cp	l, 0:i3
	ret	z
	ldw	wa, 54
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	ret	z
	ld	wa, 4:i3
	call	Scoop_SoundEditorData_Helper5
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
	jp	SeMenu_ApplyPartEdit_AltStore_Join8
	extz	wa
	ldw	bc, 64
	ld	de, 0:i3
	jp	SeMenu_ApplyPartEdit_AltStore_Join9
	extz	wa
	ldw	bc, 62
	ldw	de, 65
	jp	SeMenu_ApplyPartEdit_AltStore_Join10
	extz	wa
	ldw	bc, 66
	ld	de, 0:i3
	jp	SeMenu_ApplyPartEdit_AltStore_Join11
	extz	wa
	ldw	bc, 70
	ldw	de, 67
	jp	SeMenu_ApplyPartEdit_AltStore_Join12
	extz	wa
	ldw	bc, 68
	ld	de, 0:i3
	jp	SeMenu_ApplyPartEdit_AltStore_Join13
	extz	wa
	ldw	bc, 61
	ldw	de, 69
	jp	SeMenu_ApplyPartEdit_AltStore_Join14
	cp	a, 0:i3
	ret	z
	call	Scoop_SoundEditorData_Helper3
	ret
	cp	a, 0:i3
	jr	nz, Scoop_SoundEditorData_Skip46
	ldw	wa, 48
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join44
Scoop_SoundEditorData_Skip46:
	ld	wa, 1:i3
	call	Scoop_SoundEditorData_Helper5
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
	call	Scoop_SoundEditorData_Helper5
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
	jp	SeMenu_ApplyPartEdit_AltStore_Join7
Scoop_SoundEditorData_Skip48:
	ld	wa, 3:i3
	call	Scoop_SoundEditorData_Helper5
	cp	l, 0:i3
	ret	z
	ldw	wa, 55
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	jr	nz, Scoop_SoundEditorData_Skip49
	ld	wa, 1:i3
	jp	SeMenu_ApplyPartEdit_AltStore_Join7
Scoop_SoundEditorData_Skip49:
	ld	wa, 4:i3
	call	Scoop_SoundEditorData_Helper5
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
	jp	SeMenu_ApplyPartEdit_AltStore_Join15
	extz	wa
	ldw	bc, 75
	jp	SeMenu_ApplyPartEdit_AltStore_Join16
	extz	wa
	ldw	bc, 76
	jp	SeMenu_ApplyPartEdit_AltStore_Join17
	extz	wa
	ldw	bc, 73
	jp	SeMenu_ApplyPartEdit_AltStore_Join18
	extz	wa
	ldw	bc, 71
	jp	SeMenu_ApplyPartEdit_AltStore_Join19
	extz	wa
	ldw	bc, 72
	jp	SeMenu_ApplyPartEdit_AltStore_Join20
	cp	a, 0:i3
	ret	z
	call	Scoop_SoundEditorData_Helper3
	ret
	cp	a, 0:i3
	jr	nz, Scoop_SoundEditorData_Skip50
	ldw	wa, 48
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join46
Scoop_SoundEditorData_Skip50:
	ld	wa, 1:i3
	call	Scoop_SoundEditorData_Helper5
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
	call	Scoop_SoundEditorData_Helper5
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
	call	Scoop_SoundEditorData_Helper5
	cp	l, 0:i3
	ret	z
	ldw	wa, 56
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	ret	z
	ld	wa, 4:i3
	call	Scoop_SoundEditorData_Helper5
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
	jp	SeMenu_ApplyPartEdit_AltStore_Join
	extz	wa
	ld	bc, 2:i3
	jp	SeMenu_ApplyPartEdit_AltStore_Join2
	extz	wa
	ld	bc, 2:i3
	jp	SeMenu_ApplyPartEdit_AltStore_Join3
	extz	wa
	ld	bc, 2:i3
	jp	SeMenu_ApplyPartEdit_AltStore_Join4
	extz	wa
	ld	bc, 2:i3
	jp	SeMenu_ApplyPartEdit_AltStore_Join5
	extz	wa
	ld	bc, 2:i3
	jp	SeMenu_ApplyPartEdit_AltStore_Join6
	cp	a, 0:i3
	jp	nz, (Scoop_SoundEditorData_Helper3:24)
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
	jp	Scoop_SoundEditorData_Helper6
	cp	a, 0:i3
	ret	z
	ld	wa, 2:i3
	ld	bc, 2:i3
	call	Scoop_SoundEditorData_Helper6
	ret
	cp	a, 0:i3
	ret	z
	ld	wa, 2:i3
	ld	bc, 3:i3
	call	Scoop_SoundEditorData_Helper6
	ret
	cp	a, 0:i3
	ret	z
	ld	wa, 2:i3
	ld	bc, 4:i3
	call	Scoop_SoundEditorData_Helper6
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
