; =============================================================================
; Sound-editor title-function handlers (code; historical file name)
; =============================================================================
;
; CODE, not data: 3,422 TLCS-900 instructions and not one .byte/.ascii/.long
; directive, re-assembled byte-identical to the dump.  Entered at
; SeWrtSndTitleFunc_OnDraw -- named by one `.long` of the pointer table
; SeTonTon1TitleFunc_Methods in kn5000_v*_program.s,
; where 187 more `.long`s point into this file as bare numbers -- and at the
; 15 interior offsets that the title-function stubs of
; audio/sound_editor_routines.s reach by `jp Scoop_SoundEditorData_0x..`
; (e.g. SeAmpAmp1TitleFunc_OnDraw).  The body is almost all calls to
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
; The label name SeWrtSndTitleFunc_OnDraw is kept: it is referenced from files
; outside this lane.
; =============================================================================



SeWrtSndTitleFunc_OnDraw:
	; Disassembled from the committed romslice (no source of any kind existed):
	; llvm-mc -triple=tlcs900 --disassemble round-trips these 51 B byte-exact.
	; v9/v10's SeWrtSndTitleFunc_OnDraw opens the same way (jp/jp/ld wa,(xsp+4)/
	; ld bc,(xsp+6)/...) confirming the framing; only the call targets differ,
	; unresolved to symbols because this v7 link never names them.
	jp	SeMenu_CopyWriteUpdate_Join
SeWrtSndTitleFunc_OnHide:
	jp	SeMenu_CopyWriteUpdate_Return
SeWrtSndTitleFunc_OnSwitchIn:
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	call	Scoop_SoundEditorData_Helper
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
SeWrtSndTitleFunc_Nop:
	jp	SeMenu_CopyWriteUpdate_Return2
SeAmpAmp1TitleFunc_DispatchSwitch:
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeTitle_DecodeSwitch
	cp HL,0xffff
	jr z, .Lc_f03db4
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (SeAmpAmp1TitleFunc_SwitchHandlers:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f03db4:
	inc 4,XSP
	ret
SeAmpAmp2TitleFunc_DispatchSwitch:
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeTitle_DecodeSwitch
	cp HL,0xffff
	jr z, .Lc_f03de2
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (SeAmpAmp2TitleFunc_SwitchHandlers:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f03de2:
	inc 4,XSP
	ret
SeAmpEnv1TitleFunc_DispatchSwitch:
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeTitle_DecodeSwitch
	cp HL,0xffff
	jr z, .Lc_f03e10
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (SeAmpEnv1TitleFunc_SwitchHandlers:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f03e10:
	inc 4,XSP
	ret
SeAmpEnv2TitleFunc_DispatchSwitch:
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeTitle_DecodeSwitch
	cp HL,0xffff
	jr z, .Lc_f03e3e
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (SeAmpEnv2TitleFunc_SwitchHandlers:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f03e3e:
	inc 4,XSP
	ret
SeAmpLfo1TitleFunc_DispatchSwitch:
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeTitle_DecodeSwitch
	cp HL,0xffff
	jr z, .Lc_f03e6c
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (SeAmpLfo1TitleFunc_SwitchHandlers:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f03e6c:
	inc 4,XSP
	ret
SeAmpAmp1_OnColumn3:
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
	call	SeMenu_ApplyPartEdit_Helper3
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
	call	SeMenu_ApplyPartEdit_Entry2_Code_Helper
	lda	xsp, (xsp+20)
	ret
SeAmpAmp1_OnColumn4:
	lda	xsp, (xsp-18)
	push	qiz
	ld	(xsp+18), a
	lda	xwa, (xsp+14)
	call	SeMenu_LoadObjEntries
	lda	xwa, (xsp+16)
	call	SeMenu_ValidatePartNumber
	cp	(xsp+14), 0
	jr	nz, Scoop_SoundEditorData_Skip4
	ld	a, (xsp+16)
	inc	4, a
	ldfr_berp	a, 251
	jr	Scoop_SoundEditorData_Join3
Scoop_SoundEditorData_Skip4:
	ld	a, (xsp+16)
	inc	2, a
	ldfr_berp	a, 251
Scoop_SoundEditorData_Join3:
	ldto_berp	a, 251
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
	jr	nz, Scoop_SoundEditorData_Skip5
	ld	(xwa), 255
	ld	(xbc), 0
	ld	(xde), 50
	ld	(xhl), 206
	ld	a, 24:opc
	jr	Scoop_SoundEditorData_Join4
Scoop_SoundEditorData_Skip5:
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
	ldto_berp	c, 251
	extz	bc
	ld	e, (xsp+16)
	extz	de
	extz	wa
	pushw	wa
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 43
	call	SeMenu_ApplyPartEdit_Helper3
	ld	wa, 4:i3
	call	SeMenu_ApplyPartEdit_Entry2_Code_Helper
	pop	qiz
	lda	xsp, (xsp+18)
	ret
SeAmpAmp1_OnColumn5:
	lda	xsp, (xsp-18)
	push	qiz
	ld	(xsp+18), a
	lda	xwa, (xsp+14)
	call	SeMenu_LoadObjEntries
	cp	(xsp+14), 1
	jr	z, Scoop_SoundEditorData_Epilogue
	lda	xwa, (xsp+16)
	call	SeMenu_ValidatePartNumber
	ld	a, (xsp+16)
	inc	8, a
	ldfr_berp	a, 251
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
	ldto_berp	c, 251
	extz	bc
	ld	e, (xsp+16)
	extz	de
	pushw	25
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 43
	call	SeMenu_ApplyPartEdit_Helper3
	ld	wa, 5:i3
	call	SeMenu_ApplyPartEdit_Entry2_Code_Helper
Scoop_SoundEditorData_Epilogue:
	pop	qiz
	lda	xsp, (xsp+18)
	ret
SeAmpAmp1_OnSideRow1:
	cp	a, 0:i3
	jp	nz, (SeMenu_CopyWriteUpdate_Helper3:24)
	ldw	wa, 45
	ld	bc, 0:i3
	jp	SeMenu_SendEvent
SeAmpAmp1_OnSideRow2:
	cp	a, 0:i3
	ret	z
	ldw	wa, 43
	ld	bc, 1:i3
	ld	de, 1:i3
	call	SeMenu_CopyWriteUpdate_Helper8
	ret
SeAmpAmp1_OnSideRow3:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Skip6
	cp	(xsp), 1
	jr	z, Scoop_SoundEditorData_Epilogue2
	ldw	wa, 47
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	jr	Scoop_SoundEditorData_Epilogue2
Scoop_SoundEditorData_Skip6:
	ldw	wa, 43
	ld	bc, 2:i3
	ld	de, 1:i3
	call	SeMenu_CopyWriteUpdate_Helper8
Scoop_SoundEditorData_Epilogue2:
	inc	4, xsp
	ret
SeAmpAmp1_OnSideRow4:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, Scoop_SoundEditorData_Epilogue3
	cp	(xsp+2), 0
	jr	z, Scoop_SoundEditorData_Epilogue3
	ldw	wa, 43
	ld	bc, 3:i3
	ld	de, 1:i3
	call	SeMenu_CopyWriteUpdate_Helper8
Scoop_SoundEditorData_Epilogue3:
	inc	4, xsp
	ret
SeAmpAmp1_OnSideRow5:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, Scoop_SoundEditorData_Epilogue4
	cp	(xsp+2), 0
	jr	z, Scoop_SoundEditorData_Epilogue4
	ldw	wa, 43
	ld	bc, 4:i3
	ld	de, 1:i3
	call	SeMenu_CopyWriteUpdate_Helper8
Scoop_SoundEditorData_Epilogue4:
	inc	4, xsp
	ret
SeAmpAmp1_OnSwitch25:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, Scoop_SoundEditorData_Epilogue5
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Epilogue5
	ldw	wa, 44
	ld	bc, 0:i3
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue5:
	inc	4, xsp
	ret
SeAmpAmp1_OnSwitch15:
	dec	4, xsp
	ld	(xsp+2), a
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Epilogue6
	cp	(xsp), 0
	jr	nz, Scoop_SoundEditorData_Skip7
	ldw	wa, 32
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join5
Scoop_SoundEditorData_Skip7:
	ldw	wa, 61
	ld	bc, 0:i3
Scoop_SoundEditorData_Join5:
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue6:
	inc	4, xsp
	ret
SeAmpAmp2_OnColumn3:
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
	call	SeMenu_ApplyPartEdit_Helper3
	cp	l, 1:i3
	jr	nz, Scoop_SoundEditorData_Skip8
	lda	xbc, (xsp+12)
	ld	wa, 3:i3
	call	SeMenu_LoadPartParam
	ld	c, (xsp+12)
	extz	bc
	ldw	wa, 10
	call	SeMenu_StorePartParam
	ld	wa, 0:i3
	ld	bc, 0:i3
	call	SeMenu_ApplyPartEdit_Helper12
Scoop_SoundEditorData_Skip8:
	ld	wa, 3:i3
	call	SeMenu_ApplyPartEdit_Entry2_Code_Helper
	lda	xsp, (xsp+18)
	ret
SeAmpAmp2_OnColumn4:
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
	call	SeMenu_ApplyPartEdit_Helper14
	cp	l, 1:i3
	jr	nz, Scoop_SoundEditorData_Skip9
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
	call	SeMenu_ApplyPartEdit_Helper12
Scoop_SoundEditorData_Skip9:
	ld	wa, 4:i3
	call	SeMenu_ApplyPartEdit_Entry2_Code_Helper
	inc	8, xsp
	ret
SeAmpAmp2_OnColumn5:
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
	call	SeMenu_ApplyPartEdit_Helper14
	cp	l, 1:i3
	jr	nz, Scoop_SoundEditorData_Skip10
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
	call	SeMenu_ApplyPartEdit_Helper12
Scoop_SoundEditorData_Skip10:
	ld	wa, 5:i3
	call	SeMenu_ApplyPartEdit_Entry2_Code_Helper
	lda	xsp, (xsp+10)
	ret
SeAmpAmp2_OnColumn6:
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
	call	SeMenu_ApplyPartEdit_Helper14
	cp	l, 1:i3
	jr	nz, Scoop_SoundEditorData_Skip11
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
	call	SeMenu_ApplyPartEdit_Helper12
Scoop_SoundEditorData_Skip11:
	ld	wa, 6:i3
	call	SeMenu_ApplyPartEdit_Entry2_Code_Helper
	inc	8, xsp
	ret
SeAmpAmp2_OnSideRow1:
	cp	a, 0:i3
	jp	nz, (SeMenu_CopyWriteUpdate_Helper3:24)
	ldw	wa, 45
	ld	bc, 0:i3
	jp	SeMenu_SendEvent
SeAmpAmp2_OnSideRow2:
	cp	a, 0:i3
	ret	z
	ld	wa, 1:i3
	call	SeMenu_CopyWriteUpdate_Helper5
	cp	l, 0:i3
	ret	z
	ldw	wa, 44
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
SeAmpAmp2_OnSideRow3:
	cp	a, 0:i3
	jr	nz, Scoop_SoundEditorData_Skip12
	ldw	wa, 47
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join6
Scoop_SoundEditorData_Skip12:
	ld	wa, 2:i3
	call	SeMenu_CopyWriteUpdate_Helper5
	cp	l, 0:i3
	ret	z
	ldw	wa, 44
	ld	bc, 1:i3
Scoop_SoundEditorData_Join6:
	call	SeMenu_SendEvent
	ret
SeAmpAmp2_OnSideRow4:
	cp	a, 0:i3
	ret	z
	ld	wa, 3:i3
	call	SeMenu_CopyWriteUpdate_Helper5
	cp	l, 0:i3
	ret	z
	ldw	wa, 44
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
SeAmpAmp2_OnSideRow5:
	cp	a, 0:i3
	ret	z
	ld	wa, 4:i3
	call	SeMenu_CopyWriteUpdate_Helper5
	cp	l, 0:i3
	ret	z
	ldw	wa, 44
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
SeAmpAmp2_OnSwitch25:
	cp	a, 0:i3
	ret	z
	ldw	wa, 43
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
SeAmpAmp2_OnSwitch15:
	cp	a, 0:i3
	ret	nz
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	ldw	wa, 32
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
SeAmpEnv1_OnColumn1:
	lda	xsp, (xsp-18)
	push	qiz
	ld	(xsp+18), a
	lda	xwa, (xsp+16)
	call	SeMenu_ValidatePartNumber
	lda	xwa, (xsp+14)
	call	SeMenu_LoadObjEntries
	cp	(xsp+14), 0
	scc	nz, a
	ldfr_berp	a, 251
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
	jr	nz, Scoop_SoundEditorData_Skip13
	ld	a, 39:opc
	jr	Scoop_SoundEditorData_Join7
Scoop_SoundEditorData_Skip13:
	ld	a, (xsp+16)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	inc	8, xwa
	ld	(xsp+16), 0
Scoop_SoundEditorData_Join7:
	ldto_berp	c, 251
	extz	bc
	ld	e, (xsp+16)
	extz	de
	extz	wa
	pushw	wa
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 45
	call	SeMenu_ApplyPartEdit_Helper3
	call	UpdSeSel_DetailedUpdate_Helper4
	ld	wa, 1:i3
	call	SeMenu_ApplyPartEdit_Entry2_Code_Helper
	pop	qiz
	lda	xsp, (xsp+18)
	ret
SeAmpEnv1_OnColumn2:
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
	jr	nz, Scoop_SoundEditorData_Skip14
	ldib_erp	251, 1
Scoop_SoundEditorData_Skip14:
	ld	(xwa), 127
	ld	(xbc), 0
	ld	(xde), 100
	ld	(xhl), 0
	ldto_berp	a, 251
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xsp+12)
	call	SeMenu_ApplyPartEdit_Helper5
	cp	(xsp+14), 0
	jr	nz, Scoop_SoundEditorData_Skip15
	ld	a, 40:opc
	jr	Scoop_SoundEditorData_Join8
Scoop_SoundEditorData_Skip15:
	ld	a, (xsp+16)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+9)
	ld	(xsp+16), 0
Scoop_SoundEditorData_Join8:
	ldto_berp	c, 251
	extz	bc
	ld	e, (xsp+16)
	extz	de
	extz	wa
	pushw	wa
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 45
	call	SeMenu_ApplyPartEdit_Helper3
	call	UpdSeSel_DetailedUpdate_Helper4
	ld	wa, 2:i3
	call	SeMenu_ApplyPartEdit_Entry2_Code_Helper
	pop	qiz
	lda	xsp, (xsp+18)
	ret
SeAmpEnv1_OnColumn3:
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
	jr	nz, Scoop_SoundEditorData_Skip16
	ldib_erp	251, 2
Scoop_SoundEditorData_Skip16:
	ld	(xwa), 127
	ld	(xbc), 0
	ld	(xde), 100
	ld	(xhl), 0
	ldto_berp	a, 251
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xsp+12)
	call	SeMenu_ApplyPartEdit_Helper5
	cp	(xsp+14), 0
	jr	nz, Scoop_SoundEditorData_Skip17
	ld	a, 41:opc
	jr	Scoop_SoundEditorData_Join9
Scoop_SoundEditorData_Skip17:
	ld	a, (xsp+16)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+10)
	ld	(xsp+16), 0
Scoop_SoundEditorData_Join9:
	ldto_berp	c, 251
	extz	bc
	ld	e, (xsp+16)
	extz	de
	extz	wa
	pushw	wa
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 45
	call	SeMenu_ApplyPartEdit_Helper3
	call	UpdSeSel_DetailedUpdate_Helper4
	ld	wa, 3:i3
	call	SeMenu_ApplyPartEdit_Entry2_Code_Helper
	pop	qiz
	lda	xsp, (xsp+18)
	ret
SeAmpEnv1_OnColumn4:
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
	jr	nz, Scoop_SoundEditorData_Skip18
	ldib_erp	251, 3
Scoop_SoundEditorData_Skip18:
	ld	(xwa), 127
	ld	(xbc), 0
	ld	(xde), 100
	ld	(xhl), 0
	ldto_berp	a, 251
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xsp+12)
	call	SeMenu_ApplyPartEdit_Helper5
	cp	(xsp+14), 0
	jr	nz, Scoop_SoundEditorData_Skip19
	ld	a, 42:opc
	jr	Scoop_SoundEditorData_Join10
Scoop_SoundEditorData_Skip19:
	ld	a, (xsp+16)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+11)
	ld	(xsp+16), 0
Scoop_SoundEditorData_Join10:
	ldto_berp	c, 251
	extz	bc
	ld	e, (xsp+16)
	extz	de
	extz	wa
	pushw	wa
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 45
	call	SeMenu_ApplyPartEdit_Helper3
	call	UpdSeSel_DetailedUpdate_Helper4
	ld	wa, 4:i3
	call	SeMenu_ApplyPartEdit_Entry2_Code_Helper
	pop	qiz
	lda	xsp, (xsp+18)
	ret
SeAmpEnv1_OnColumn5:
	lda	xsp, (xsp-20)
	push	qiz
	ld	(xsp+20), a
	lda	xwa, (xsp+18)
	call	SeMenu_ValidatePartNumber
	lda	xwa, (xsp+16)
	call	SeMenu_LoadObjEntries
	cp	(xsp+16), 0
	jr	nz, Scoop_SoundEditorData_Skip20
	ldib_erp	251, 4
	lda	xwa, (xsp+2)
	ld	(xwa+6), 127
	ld	(xwa+7), 0
	ld	(xwa+8), 100
	jr	Scoop_SoundEditorData_Join11
Scoop_SoundEditorData_Skip20:
	lda	xbc, (xsp+14)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	bitm	5, (xsp+14)
	jr	z, Scoop_SoundEditorData_Epilogue7
	ldib_erp	251, 5
	lda	xwa, (xsp+2)
	ld	(xwa+6), 127
	ld	(xwa+7), 0
	ld	(xwa+8), 100
Scoop_SoundEditorData_Join11:
	ld	(xwa+9), 0
	ldto_berp	a, 251
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	ld	a, (xsp+20)
	extz	wa
	lda	xbc, (xsp+12)
	call	SeMenu_ApplyPartEdit_Helper5
	cp	(xsp+16), 0
	jr	nz, Scoop_SoundEditorData_Skip21
	ld	a, 43:opc
	jr	Scoop_SoundEditorData_Join12
Scoop_SoundEditorData_Skip21:
	ld	a, (xsp+18)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+12)
	ld	(xsp+18), 0
Scoop_SoundEditorData_Join12:
	ldto_berp	c, 251
	extz	bc
	ld	e, (xsp+18)
	extz	de
	extz	wa
	pushw	wa
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 45
	call	SeMenu_ApplyPartEdit_Helper3
	call	UpdSeSel_DetailedUpdate_Helper4
	ld	wa, 5:i3
	call	SeMenu_ApplyPartEdit_Entry2_Code_Helper
Scoop_SoundEditorData_Epilogue7:
	pop	qiz
	lda	xsp, (xsp+20)
	ret
SeAmpEnv1_OnColumn6:
	lda	xsp, (xsp-20)
	push	qiz
	ld	(xsp+20), a
	lda	xwa, (xsp+18)
	call	SeMenu_ValidatePartNumber
	lda	xwa, (xsp+16)
	call	SeMenu_LoadObjEntries
	cp	(xsp+16), 0
	jr	nz, Scoop_SoundEditorData_Skip22
	ldib_erp	251, 5
	lda	xwa, (xsp+2)
	ld	(xwa+6), 127
	ld	(xwa+7), 0
	ld	(xwa+8), 100
	jr	Scoop_SoundEditorData_Join13
Scoop_SoundEditorData_Skip22:
	lda	xbc, (xsp+14)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	bitm	5, (xsp+14)
	jr	z, Scoop_SoundEditorData_Epilogue8
	ldib_erp	251, 6
	lda	xwa, (xsp+2)
	ld	(xwa+6), 127
	ld	(xwa+7), 0
	ld	(xwa+8), 100
Scoop_SoundEditorData_Join13:
	ld	(xwa+9), 0
	ldto_berp	a, 251
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	ld	a, (xsp+20)
	extz	wa
	lda	xbc, (xsp+12)
	call	SeMenu_ApplyPartEdit_Helper5
	cp	(xsp+16), 0
	jr	nz, Scoop_SoundEditorData_Skip23
	ld	a, 44:opc
	jr	Scoop_SoundEditorData_Join14
Scoop_SoundEditorData_Skip23:
	ld	a, (xsp+18)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+13)
	ld	(xsp+18), 0
Scoop_SoundEditorData_Join14:
	ldto_berp	c, 251
	extz	bc
	ld	e, (xsp+18)
	extz	de
	extz	wa
	pushw	wa
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 45
	call	SeMenu_ApplyPartEdit_Helper3
	call	UpdSeSel_DetailedUpdate_Helper4
	ld	wa, 6:i3
	call	SeMenu_ApplyPartEdit_Entry2_Code_Helper
Scoop_SoundEditorData_Epilogue8:
	pop	qiz
	lda	xsp, (xsp+20)
	ret
SeAmpEnv1_OnColumn7:
	lda	xsp, (xsp-18)
	ld	(xsp+16), a
	lda	xwa, (xsp+12)
	call	SeMenu_LoadObjEntries
	cp	(xsp+12), 1
	jr	z, Scoop_SoundEditorData_Epilogue9
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
	call	SeMenu_ApplyPartEdit_Helper3
	call	UpdSeSel_DetailedUpdate_Helper4
	ld	wa, 7:i3
	call	SeMenu_ApplyPartEdit_Entry2_Code_Helper
Scoop_SoundEditorData_Epilogue9:
	lda	xsp, (xsp+18)
	ret
SeAmpEnv1_OnColumn8:
	lda	xsp, (xsp-18)
	ld	(xsp+16), a
	lda	xwa, (xsp+12)
	call	SeMenu_LoadObjEntries
	cp	(xsp+12), 0
	jr	z, Scoop_SoundEditorData_Epilogue10
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
	call	SeMenu_ApplyPartEdit_Helper3
	ldw	wa, 8
	call	SeMenu_ApplyPartEdit_Entry2_Code_Helper
Scoop_SoundEditorData_Epilogue10:
	lda	xsp, (xsp+18)
	ret
SeAmpEnv1_OnSideRow1:
	cp	a, 0:i3
	ret	z
	call	SeMenu_CopyWriteUpdate_Helper3
	ret
SeAmpEnv1_OnSideRow2:
	cp	a, 0:i3
	jr	nz, Scoop_SoundEditorData_Skip24
	ldw	wa, 43
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join15
Scoop_SoundEditorData_Skip24:
	ld	wa, 1:i3
	call	SeMenu_CopyWriteUpdate_Helper5
	cp	l, 0:i3
	ret	z
	ldw	wa, 45
	ld	bc, 1:i3
Scoop_SoundEditorData_Join15:
	call	SeMenu_SendEvent
	ret
SeAmpEnv1_OnSideRow3:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Skip25
	cp	(xsp), 0
	jr	nz, Scoop_SoundEditorData_Epilogue11
	ldw	wa, 47
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join16
Scoop_SoundEditorData_Skip25:
	ld	wa, 2:i3
	call	SeMenu_CopyWriteUpdate_Helper5
	cp	l, 0:i3
	jr	z, Scoop_SoundEditorData_Epilogue11
	ldw	wa, 45
	ld	bc, 1:i3
Scoop_SoundEditorData_Join16:
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue11:
	inc	4, xsp
	ret
SeAmpEnv1_OnSideRow4:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, Scoop_SoundEditorData_Epilogue12
	cp	(xsp+2), 0
	jr	z, Scoop_SoundEditorData_Epilogue12
	ld	wa, 3:i3
	call	SeMenu_CopyWriteUpdate_Helper5
	cp	l, 0:i3
	jr	z, Scoop_SoundEditorData_Epilogue12
	ldw	wa, 45
	ld	bc, 1:i3
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue12:
	inc	4, xsp
	ret
SeAmpEnv1_OnSideRow5:
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp+2)
	call	SeMenu_LoadObjEntries
	cp	(xsp+4), 0
	jr	z, Scoop_SoundEditorData_Epilogue13
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Skip26
	ld	wa, 4:i3
	call	SeMenu_CopyWriteUpdate_Helper5
	cp	l, 0:i3
	jr	z, Scoop_SoundEditorData_Epilogue13
	ldw	wa, 45
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	jr	Scoop_SoundEditorData_Epilogue13
Scoop_SoundEditorData_Skip26:
	lda	xbc, (xsp)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	bitm	5, (xsp)
	jr	z, Scoop_SoundEditorData_Skip27
	resm	5, (xsp)
	jr	Scoop_SoundEditorData_Join17
Scoop_SoundEditorData_Skip27:
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
	call	UpdSeSel_DetailedUpdate_Helper4
Scoop_SoundEditorData_Epilogue13:
	inc	6, xsp
	ret
SeAmpEnv1_OnSwitch25:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, Scoop_SoundEditorData_Epilogue14
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Epilogue14
	ldw	wa, 46
	ld	bc, 0:i3
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue14:
	inc	4, xsp
	ret
SeAmpEnv1_OnSwitch15:
	dec	4, xsp
	ld	(xsp+2), a
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Epilogue15
	cp	(xsp), 0
	jr	nz, Scoop_SoundEditorData_Skip28
	ldw	wa, 32
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join18
Scoop_SoundEditorData_Skip28:
	ldw	wa, 61
	ld	bc, 0:i3
Scoop_SoundEditorData_Join18:
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue15:
	inc	4, xsp
	ret
SeAmpEnv2_OnColumn1:
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
	call	SeMenu_ApplyPartEdit_Helper3
	lda	xbc, (xsp+12)
	ld	wa, 5:i3
	call	SeMenu_LoadPartParam
	ld	c, (xsp+12)
	extz	bc
	ldw	wa, 10
	call	SeMenu_StorePartParam
	ld	wa, 2:i3
	ld	bc, 0:i3
	call	SeMenu_ApplyPartEdit_Helper12
	lda	xbc, (xsp+12)
	ldw	wa, 9
	call	SeMenu_LoadPartParam
	cp	(xsp+12), 0
	jr	z, Scoop_SoundEditorData_Skip29
	ldw	wa, 9
	ld	bc, 0:i3
	call	SeMenu_StorePartParam
	pushw	9
	pushw	46
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
Scoop_SoundEditorData_Skip29:
	ld	wa, 1:i3
	call	SeMenu_ApplyPartEdit_Entry2_Code_Helper
	lda	xsp, (xsp+18)
	ret
SeAmpEnv2_OnColumn2:
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
	call	SeMenu_ApplyPartEdit_Helper3
	lda	xbc, (xsp+12)
	ld	wa, 6:i3
	call	SeMenu_LoadPartParam
	ld	c, (xsp+12)
	extz	bc
	ldw	wa, 10
	call	SeMenu_StorePartParam
	ld	wa, 2:i3
	ld	bc, 0:i3
	call	SeMenu_ApplyPartEdit_Helper12
	lda	xbc, (xsp+12)
	ldw	wa, 9
	call	SeMenu_LoadPartParam
	cp	(xsp+12), 1
	jr	z, Scoop_SoundEditorData_Skip30
	ldw	wa, 9
	ld	bc, 1:i3
	call	SeMenu_StorePartParam
	pushw	9
	pushw	46
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
Scoop_SoundEditorData_Skip30:
	ld	wa, 2:i3
	call	SeMenu_ApplyPartEdit_Entry2_Code_Helper
	lda	xsp, (xsp+18)
	ret
SeAmpEnv2_OnColumn3:
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
	call	SeMenu_ApplyPartEdit_Helper3
	lda	xbc, (xsp+12)
	ld	wa, 7:i3
	call	SeMenu_LoadPartParam
	ld	c, (xsp+12)
	extz	bc
	ldw	wa, 10
	call	SeMenu_StorePartParam
	ld	wa, 2:i3
	ld	bc, 0:i3
	call	SeMenu_ApplyPartEdit_Helper12
	lda	xbc, (xsp+12)
	ldw	wa, 9
	call	SeMenu_LoadPartParam
	cp	(xsp+12), 2
	jr	z, Scoop_SoundEditorData_Skip31
	ldw	wa, 9
	ld	bc, 2:i3
	call	SeMenu_StorePartParam
	pushw	9
	pushw	46
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
Scoop_SoundEditorData_Skip31:
	ld	wa, 3:i3
	call	SeMenu_ApplyPartEdit_Entry2_Code_Helper
	lda	xsp, (xsp+18)
	ret
SeAmpEnv2_OnColumn4:
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
	call	SeMenu_ApplyPartEdit_Helper14
	cp	l, 1:i3
	jr	nz, Scoop_SoundEditorData_Skip32
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
	call	SeMenu_ApplyPartEdit_Helper12
Scoop_SoundEditorData_Skip32:
	ld	wa, 4:i3
	call	SeMenu_ApplyPartEdit_Entry2_Code_Helper
	inc	8, xsp
	ret
SeAmpEnv2_OnColumn5:
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
	call	SeMenu_ApplyPartEdit_Helper14
	cp	l, 1:i3
	jr	nz, Scoop_SoundEditorData_Skip33
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
	call	SeMenu_ApplyPartEdit_Helper12
Scoop_SoundEditorData_Skip33:
	ld	wa, 5:i3
	call	SeMenu_ApplyPartEdit_Entry2_Code_Helper
	lda	xsp, (xsp+10)
	ret
SeAmpEnv2_OnColumn6:
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
	call	SeMenu_ApplyPartEdit_Helper14
	cp	l, 1:i3
	jr	nz, Scoop_SoundEditorData_Skip34
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
	call	SeMenu_ApplyPartEdit_Helper12
Scoop_SoundEditorData_Skip34:
	ld	wa, 6:i3
	call	SeMenu_ApplyPartEdit_Entry2_Code_Helper
	inc	8, xsp
	ret
SeAmpEnv2_OnColumn7:
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
	call	SeMenu_ApplyPartEdit_Helper3
	ld	wa, 7:i3
	call	SeMenu_ApplyPartEdit_Entry2_Code_Helper
	lda	xsp, (xsp+16)
	ret
SeAmpEnv2_OnColumn8:
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
	call	SeMenu_ApplyPartEdit_Helper3
	ldw	wa, 8
	call	SeMenu_ApplyPartEdit_Entry2_Code_Helper
	lda	xsp, (xsp+16)
	ret
SeAmpEnv2_OnSideRow1:
	cp	a, 0:i3
	ret	z
	call	SeMenu_CopyWriteUpdate_Helper3
	ret
SeAmpEnv2_OnSideRow2:
	cp	a, 0:i3
	jr	nz, Scoop_SoundEditorData_Skip35
	ldw	wa, 43
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join19
Scoop_SoundEditorData_Skip35:
	ld	wa, 1:i3
	call	SeMenu_CopyWriteUpdate_Helper5
	cp	l, 0:i3
	ret	z
	ldw	wa, 46
	ld	bc, 1:i3
Scoop_SoundEditorData_Join19:
	call	SeMenu_SendEvent
	ret
SeAmpEnv2_OnSideRow3:
	cp	a, 0:i3
	jr	nz, Scoop_SoundEditorData_Skip36
	ldw	wa, 47
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join20
Scoop_SoundEditorData_Skip36:
	ld	wa, 2:i3
	call	SeMenu_CopyWriteUpdate_Helper5
	cp	l, 0:i3
	ret	z
	ldw	wa, 46
	ld	bc, 1:i3
Scoop_SoundEditorData_Join20:
	call	SeMenu_SendEvent
	ret
SeAmpEnv2_OnSideRow4:
	cp	a, 0:i3
	ret	z
	ld	wa, 3:i3
	call	SeMenu_CopyWriteUpdate_Helper5
	cp	l, 0:i3
	ret	z
	ldw	wa, 46
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
SeAmpEnv2_OnSideRow5:
	cp	a, 0:i3
	ret	z
	ld	wa, 4:i3
	call	SeMenu_CopyWriteUpdate_Helper5
	cp	l, 0:i3
	ret	z
	ldw	wa, 46
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
SeAmpEnv2_OnSwitch25:
	cp	a, 0:i3
	ret	z
	ldw	wa, 45
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
SeAmpEnv2_OnSwitch15:
	cp	a, 0:i3
	ret	nz
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	ldw	wa, 32
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
SeAmpLfo1_OnColumn2:
	extz	wa
	ld	bc, 0:i3
	jp	SeMenu_ApplyPartEdit_Data2
SeAmpLfo1_OnColumn3:
	extz	wa
	ld	bc, 0:i3
	jp	SeMenu_ApplyPartEdit_AltStore_Join
SeAmpLfo1_OnColumn4:
	extz	wa
	ld	bc, 0:i3
	jp	SeMenu_ApplyPartEdit_AltStore_Join2
SeAmpLfo1_OnColumn5:
	extz	wa
	ld	bc, 0:i3
	jp	SeMenu_ApplyPartEdit_AltStore_Join3
SeAmpLfo1_OnColumn6:
	extz	wa
	ld	bc, 0:i3
	jp	SeMenu_ApplyPartEdit_AltStore_Join4
SeAmpLfo1_OnColumn7:
	extz	wa
	ld	bc, 0:i3
	jp	SeMenu_ApplyPartEdit_AltStore_Join5
SeAmpLfo1_OnColumn8:
	extz	wa
	ld	bc, 0:i3
	jp	SeMenu_ApplyPartEdit_AltStore_Join6
SeAmpLfo1_OnSideRow1:
	cp	a, 0:i3
	jp	nz, (SeMenu_CopyWriteUpdate_Helper3:24)
	ldw	wa, 45
	ld	bc, 0:i3
	jp	SeMenu_SendEvent
SeAmpLfo1_OnSideRow2:
	cp	a, 0:i3
	jr	nz, Scoop_SoundEditorData_Skip37
	ldw	wa, 43
	ld	bc, 0:i3
	jp	SeMenu_SendEvent
Scoop_SoundEditorData_Skip37:
	ld	wa, 0:i3
	ld	bc, 1:i3
	jp	Scoop_SoundEditorData_Helper5
SeAmpLfo1_OnSideRow3:
	cp	a, 0:i3
	ret	z
	ld	wa, 0:i3
	ld	bc, 2:i3
	call	Scoop_SoundEditorData_Helper5
	ret
SeAmpLfo1_OnSideRow4:
	cp	a, 0:i3
	ret	z
	ld	wa, 0:i3
	ld	bc, 3:i3
	call	Scoop_SoundEditorData_Helper5
	ret
SeAmpLfo1_OnSideRow5:
	cp	a, 0:i3
	ret	z
	ld	wa, 0:i3
	ld	bc, 4:i3
	call	Scoop_SoundEditorData_Helper5
	ret
SeAmpLfo1_OnSwitch15:
	cp	a, 0:i3
	ret	nz
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	ldw	wa, 32
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
SeFilLpq1TitleFunc_DispatchSwitch:
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeTitle_DecodeSwitch
	cp HL,0xffff
	jr z, .Lc_f04e5f
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (SeFilLpq1TitleFunc_SwitchHandlers:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f04e5f:
	inc 4,XSP
	ret
SeFilHpq1TitleFunc_DispatchSwitch:
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeTitle_DecodeSwitch
	cp HL,0xffff
	jr z, .Lc_f04e8d
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (SeFilHpq1TitleFunc_SwitchHandlers:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f04e8d:
	inc 4,XSP
	ret
SeFilL241TitleFunc_DispatchSwitch:
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeTitle_DecodeSwitch
	cp HL,0xffff
	jr z, .Lc_f04ebb
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (SeFilL241TitleFunc_SwitchHandlers:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f04ebb:
	inc 4,XSP
	ret
SeFilH241TitleFunc_DispatchSwitch:
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeTitle_DecodeSwitch
	cp HL,0xffff
	jr z, .Lc_f04ee9
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (SeFilH241TitleFunc_SwitchHandlers:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f04ee9:
	inc 4,XSP
	ret
SeFilBpf1TitleFunc_DispatchSwitch:
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeTitle_DecodeSwitch
	cp HL,0xffff
	jr z, .Lc_f04f17
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (SeFilBpf1TitleFunc_SwitchHandlers:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f04f17:
	inc 4,XSP
	ret
SeFilBcf1TitleFunc_DispatchSwitch:
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeTitle_DecodeSwitch
	cp HL,0xffff
	jr z, .Lc_f04f45
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (SeFilBcf1TitleFunc_SwitchHandlers:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f04f45:
	inc 4,XSP
	ret
SeFilFil2TitleFunc_DispatchSwitch:
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeTitle_DecodeSwitch
	cp HL,0xffff
	jr z, .Lc_f04f73
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (SeFilFil2TitleFunc_SwitchHandlers:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f04f73:
	inc 4,XSP
	ret
SeFilEnv1TitleFunc_DispatchSwitch:
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeTitle_DecodeSwitch
	cp HL,0xffff
	jr z, .Lc_f04fa1
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (SeFilEnv1TitleFunc_SwitchHandlers:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f04fa1:
	inc 4,XSP
	ret
SeFilEnv2TitleFunc_DispatchSwitch:
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeTitle_DecodeSwitch
	cp HL,0xffff
	jr z, .Lc_f04fcf
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (SeFilEnv2TitleFunc_SwitchHandlers:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f04fcf:
	inc 4,XSP
	ret
SeFilLfo1TitleFunc_DispatchSwitch:
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeTitle_DecodeSwitch
	cp HL,0xffff
	jr z, .Lc_f04ffd
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (SeFilLfo1TitleFunc_SwitchHandlers:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f04ffd:
	inc 4,XSP
	ret
SeFilLpq1_OnColumn1:
	extz	wa
	ld	bc, 1:i3
	ldw	de, 48
	calr	Scoop_SoundEditorData_Helper2
	ld	wa, 0:i3
	ld	bc, 0:i3
	jp	UpdSeSel_DetailedUpdate_Helper5
Scoop_SoundEditorData_Helper2:
	lda xsp, (xsp - 0x16)
	ld (XSP+0x10),E
	ld (XSP+0x12),C
	ld (XSP+0x14),A
	lda xwa, (xsp + 0x0e)
	call SeMenu_ValidatePartNumber
	lda xwa, (xsp + 0x0c)
	call SeMenu_LoadObjEntries
	lda XBC, (XSP)
	ld wa, 2:i3
	call SeMenu_LoadPartParam
	lda XBC, (XSP)
	ld (XBC+0x06),0xff
	ld (XBC+0x07),0x00
	ld (XBC+0x08),0x7f
	ld (XBC+0x09),0x00
	ld A,(XSP+0x14)
	extz WA
	lda xbc, (xbc + 0x0a)
	call SeMenu_ApplyPartEdit_Helper5
	cp (XSP+0x0c),0x00
	jr nz, .Lc_f0505c
	ld C, 0x4d:opc
	jr t, .Lc_f05075
.Lc_f0505c:
	ld A,(XSP+0x0e)
	dec 1,A
	extz WA
	muls WA,0x0015
	extz XWA
	lda xwa, (xwa + 0x10)
	lda xwa, (xwa + 0x11)
	ld C,A
	ld (XSP+0x0e),0x00
.Lc_f05075:
	ld A,(XSP+0x10)
	extz WA
	ld E,(XSP+0x0e)
	extz DE
	extz BC
	pushw bc
	lda xbc, (xsp + 0x02)
	push XBC
	ld bc, 2:i3
	call SeMenu_ApplyPartEdit_Helper3
	ld A,(XSP+0x12)
	extz WA
	call SeMenu_ApplyPartEdit_Entry2_Code_Helper
	lda xsp, (xsp + 0x16)
	ret
SeFilLpq1_OnColumn2:
	extz	wa
	ld	bc, 2:i3
	ldw	de, 48
	calr	Scoop_SoundEditorData_Helper3
	ld	wa, 0:i3
	ld	bc, 0:i3
	jp	UpdSeSel_DetailedUpdate_Helper5
Scoop_SoundEditorData_Helper3:
	lda xsp, (xsp - 0x16)
	ld (XSP+0x10),E
	ld (XSP+0x12),C
	ld (XSP+0x14),A
	lda xwa, (xsp + 0x0e)
	call SeMenu_ValidatePartNumber
	lda xwa, (xsp + 0x0c)
	call SeMenu_LoadObjEntries
	lda XBC, (XSP)
	ld wa, 3:i3
	call SeMenu_LoadPartParam
	lda XBC, (XSP)
	ld (XBC+0x06),0x7f
	ld (XBC+0x07),0x00
	ld (XBC+0x08),0x05
	ld (XBC+0x09),0x00
	ld A,(XSP+0x14)
	extz WA
	lda xbc, (xbc + 0x0a)
	call SeMenu_ApplyPartEdit_Helper5
	cp (XSP+0x0c),0x00
	jr nz, .Lc_f050f5
	ld C, 0x4e:opc
	jr t, .Lc_f0510e
.Lc_f050f5:
	ld A,(XSP+0x0e)
	dec 1,A
	extz WA
	muls WA,0x0015
	extz XWA
	lda xwa, (xwa + 0x10)
	lda xwa, (xwa + 0x12)
	ld C,A
	ld (XSP+0x0e),0x00
.Lc_f0510e:
	ld A,(XSP+0x10)
	extz WA
	ld E,(XSP+0x0e)
	extz DE
	extz BC
	pushw bc
	lda xbc, (xsp + 0x02)
	push XBC
	ld bc, 3:i3
	call SeMenu_ApplyPartEdit_Helper3
	ld A,(XSP+0x12)
	extz WA
	call SeMenu_ApplyPartEdit_Entry2_Code_Helper
	lda xsp, (xsp + 0x16)
	ret
SeFilLpq1_OnColumn3:
	extz	wa
	ld	bc, 3:i3
	ldw	de, 48
	jr	Scoop_SoundEditorData_Join21
Scoop_SoundEditorData_Join21:
	lda xsp, (xsp - 0x16)
	ld (XSP+0x10),E
	ld (XSP+0x12),C
	ld (XSP+0x14),A
	lda xwa, (xsp + 0x0e)
	call SeMenu_ValidatePartNumber
	lda xwa, (xsp + 0x0c)
	call SeMenu_LoadObjEntries
	lda XBC, (XSP)
	ld wa, 1:i3
	call SeMenu_LoadPartParam
	lda XBC, (XSP)
	ld (XBC+0x06),0x3f
	ld (XBC+0x07),0x00
	ld (XBC+0x08),0x32
	ld (XBC+0x09),0x00
	ld A,(XSP+0x14)
	extz WA
	lda xbc, (xbc + 0x0a)
	call SeMenu_ApplyPartEdit_Helper5
	cp (XSP+0x0c),0x00
	jr nz, .Lc_f05185
	ld C, 0x37:opc
	jr t, .Lc_f0519e
.Lc_f05185:
Scoop_SoundEditorData_Helper2_Skip2:
	ld A,(XSP+0x0e)
	dec 1,A
	extz WA
	muls WA,0x0015
	extz XWA
	lda xwa, (xwa + 0x10)
	lda xwa, (xwa + 0x10)
	ld C,A
	ld (XSP+0x0e),0x00
.Lc_f0519e:
Scoop_SoundEditorData_Helper2_Join2:
	ld A,(XSP+0x10)
	extz WA
	ld E,(XSP+0x0e)
	extz DE
	extz BC
	pushw bc
	lda xbc, (xsp + 0x02)
	push XBC
	ld bc, 1:i3
	call SeMenu_ApplyPartEdit_Helper3
	ld A,(XSP+0x12)
	extz WA
	call SeMenu_ApplyPartEdit_Entry2_Code_Helper
	lda xsp, (xsp + 0x16)
	ret
SeFilLpq1_OnColumn4:
	extz	wa
	ld	bc, 4:i3
	ldw	de, 48
	jr	Scoop_SoundEditorData_Join22
Scoop_SoundEditorData_Join22:
	lda xsp, (xsp - 0x16)
	ld (XSP+0x10),E
	ld (XSP+0x12),C
	ld (XSP+0x14),A
	lda xwa, (xsp + 0x0e)
	call SeMenu_ValidatePartNumber
	lda xwa, (xsp + 0x0c)
	call SeMenu_LoadObjEntries
	lda XBC, (XSP)
	ld wa, 0:i3
	call SeMenu_LoadPartParam
	lda XBC, (XSP)
	ld (XBC+0x06),0x07
	ld (XBC+0x07),0x05
	ld (XBC+0x08),0x06
	ld (XBC+0x09),0x00
	ld A,(XSP+0x14)
	extz WA
	lda xbc, (xbc + 0x0a)
	call SeMenu_ApplyPartEdit_Helper5
	cp (XSP+0x0c),0x00
	jr nz, .Lc_f05215
	ld C, 0x36:opc
	jr t, .Lc_f0522e
.Lc_f05215:
Scoop_SoundEditorData_Helper2_Skip3:
	ld A,(XSP+0x0e)
	dec 1,A
	extz WA
	muls WA,0x0015
	extz XWA
	lda xwa, (xwa + 0x10)
	lda xwa, (xwa + 0x0f)
	ld C,A
	ld (XSP+0x0e),0x00
.Lc_f0522e:
Scoop_SoundEditorData_Helper2_Join3:
	ld A,(XSP+0x10)
	extz WA
	ld E,(XSP+0x0e)
	extz DE
	extz BC
	pushw bc
	lda xbc, (xsp + 0x02)
	push XBC
	ld bc, 0:i3
	call SeMenu_ApplyPartEdit_Helper3
	ld A,(XSP+0x12)
	extz WA
	call SeMenu_ApplyPartEdit_Entry2_Code_Helper
	lda xsp, (xsp + 0x16)
	ret
Scoop_SoundEditorData_Join23:
	lda xsp, (xsp - 0x12)
	ld (XSP+0x10),A
	lda xwa, (xsp + 0x0e)
	call SeMenu_ValidatePartNumber
	lda xwa, (xsp + 0x0c)
	call SeMenu_LoadObjEntries
	lda XBC, (XSP)
	ld wa, 5:i3
	call SeMenu_LoadPartParam
	lda XBC, (XSP)
	ld (XBC+0x06),0x01
	ld (XBC+0x07),0x07
	ld (XBC+0x08),0x01
	ld (XBC+0x09),0x00
	ld E,(XSP+0x10)
	res 0x07,E
	lda xwa, (xbc + 0x0a)
	cp e, 0:i3
	jr nz, .Lc_f05292
	ld (XWA),0x01
	jr t, .Lc_f05295
.Lc_f05292:
Scoop_SoundEditorData_Helper2_Skip4:
	ld (XWA),0xff
.Lc_f05295:
Scoop_SoundEditorData_Helper2_Join4:
	cp (XSP+0x0c),0x00
	jr nz, .Lc_f0529f
	ld A, 0x50:opc
	jr t, .Lc_f052b6
.Lc_f0529f:
Scoop_SoundEditorData_Helper2_Skip5:
	ld A,(XSP+0x0e)
	dec 1,A
	extz WA
	muls WA,0x0015
	extz XWA
	lda xwa, (xwa + 0x10)
	lda xwa, (xwa + 0x14)
	ld (XSP+0x0e),0x00
.Lc_f052b6:
Scoop_SoundEditorData_Helper2_Join5:
	ld E,(XSP+0x0e)
	extz DE
	extz WA
	pushw wa
	push XBC
	ldw WA, 0x0030
	ld bc, 5:i3
	call SeMenu_ApplyPartEdit_Helper3
	cp l, 1:i3
	call z, (UpdSeSel_DetailedUpdate_Helper6:24)
	ld wa, 6:i3
	call SeMenu_ApplyPartEdit_Entry2_Code_Helper
	lda xsp, (xsp + 0x12)
	ret
Scoop_SoundEditorData_Join24:
	lda xsp, (xsp - 0x12)
	ld (XSP+0x10),A
	lda xwa, (xsp + 0x0e)
	call SeMenu_ValidatePartNumber
	lda xwa, (xsp + 0x0c)
	call SeMenu_LoadObjEntries
	lda XBC, (XSP)
	ld wa, 4:i3
	call SeMenu_LoadPartParam
	lda XBC, (XSP)
	ld (XBC+0x06),0x7f
	ld (XBC+0x07),0x00
	ld (XBC+0x08),0x7f
	ld (XBC+0x09),0x00
	ld A,(XSP+0x10)
	extz WA
	lda xbc, (xbc + 0x0a)
	call SeMenu_ApplyPartEdit_Helper5
	cp (XSP+0x0c),0x00
	jr nz, .Lc_f0531d
	ld A, 0x4f:opc
	jr t, .Lc_f05334
.Lc_f0531d:
Scoop_SoundEditorData_Helper2_Skip6:
	ld A,(XSP+0x0e)
	dec 1,A
	extz WA
	muls WA,0x0015
	extz XWA
	lda xwa, (xwa + 0x10)
	lda xwa, (xwa + 0x13)
	ld (XSP+0x0e),0x00
.Lc_f05334:
Scoop_SoundEditorData_Helper2_Join6:
	ld E,(XSP+0x0e)
	extz DE
	extz WA
	pushw wa
	lda xwa, (xsp + 0x02)
	push XWA
	ldw WA, 0x0030
	ld bc, 4:i3
	call SeMenu_ApplyPartEdit_Helper3
	cp l, 1:i3
	call z, (UpdSeSel_DetailedUpdate_Helper6:24)
	ld wa, 7:i3
	call SeMenu_ApplyPartEdit_Entry2_Code_Helper
	lda xsp, (xsp + 0x12)
	ret
Scoop_SoundEditorData_Join25:
	lda xsp, (xsp - 0x12)
	ld (XSP+0x10),A
	lda xwa, (xsp + 0x0e)
	call SeMenu_ValidatePartNumber
	lda xwa, (xsp + 0x0c)
	call SeMenu_LoadObjEntries
	lda XBC, (XSP)
	ld wa, 5:i3
	call SeMenu_LoadPartParam
	lda XBC, (XSP)
	ld (XBC+0x06),0x7f
	ld (XBC+0x07),0x00
	ld (XBC+0x08),0x0d
	ld (XBC+0x09),0x00
	ld A,(XSP+0x10)
	extz WA
	lda xbc, (xbc + 0x0a)
	call SeMenu_ApplyPartEdit_Helper5
	cp (XSP+0x0c),0x00
	jr nz, .Lc_f0539e
	ld A, 0x50:opc
	jr t, .Lc_f053b5
.Lc_f0539e:
Scoop_SoundEditorData_Helper2_Skip7:
	ld A,(XSP+0x0e)
	dec 1,A
	extz WA
	muls WA,0x0015
	extz XWA
	lda xwa, (xwa + 0x10)
	lda xwa, (xwa + 0x14)
	ld (XSP+0x0e),0x00
.Lc_f053b5:
Scoop_SoundEditorData_Helper2_Join7:
	ld E,(XSP+0x0e)
	extz DE
	extz WA
	pushw wa
	lda xwa, (xsp + 0x02)
	push XWA
	ldw WA, 0x0030
	ld bc, 5:i3
	call SeMenu_ApplyPartEdit_Helper3
	cp l, 1:i3
	call z, (UpdSeSel_DetailedUpdate_Helper6:24)
	ldw WA, 0x0008
	call SeMenu_ApplyPartEdit_Entry2_Code_Helper
	lda xsp, (xsp + 0x12)
	ret
Scoop_SoundEditorData_Join26:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Skip38
	cp	(xsp), 0
	jr nz, .Lc_f05401
	ldw WA, 0x0037
	ld bc, 0:i3
	call SeMenu_SendEvent
	jr t, .Lc_f05401
Scoop_SoundEditorData_Skip38:
	call SeMenu_CopyWriteUpdate_Helper3
.Lc_f05401:
	inc 4,XSP
	ret
Scoop_SoundEditorData_Join27:
	cp	a, 0:i3
	ret	z
	ld	wa, 1:i3
	call	SeMenu_CopyWriteUpdate_Helper5
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
	cp (XSP+0x02),0x00
	jr nz, .Lc_f05439
	cp (XSP),0x00
	jr nz, .Lc_f0544c
	ldw WA, 0x0039
	ld bc, 0:i3
	jr t, .Lc_f05448
.Lc_f05439:
	ld wa, 2:i3
	call SeMenu_CopyWriteUpdate_Helper5
	cp l, 0:i3
	jr z, .Lc_f0544c
	ldw WA, 0x0030
	ld bc, 0:i3
.Lc_f05448:
	call SeMenu_SendEvent
.Lc_f0544c:
	inc 4,XSP
	ret
SeFilLpq1_OnSideRow4:
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+4), 0
	jr	nz, Scoop_SoundEditorData_Skip39
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
	jr	Scoop_SoundEditorData_Join29
Scoop_SoundEditorData_Skip39:
	cp	(xsp), 1
	jr	z, Scoop_SoundEditorData_Epilogue16
	ld	wa, 3:i3
	call	SeMenu_CopyWriteUpdate_Helper5
	cp	l, 0:i3
	jr	z, Scoop_SoundEditorData_Epilogue16
	ldw	wa, 48
	ld	bc, 0:i3
Scoop_SoundEditorData_Join29:
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue16:
	inc	6, xsp
	ret
Scoop_SoundEditorData_Join30:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 0
	jr	z, Scoop_SoundEditorData_Epilogue17
	cp	(xsp), 1
	jr	z, Scoop_SoundEditorData_Epilogue17
	ld	wa, 4:i3
	call	SeMenu_CopyWriteUpdate_Helper5
	cp	l, 0:i3
	jr	z, Scoop_SoundEditorData_Epilogue17
	ldw	wa, 48
	ld	bc, 0:i3
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue17:
	inc	4, xsp
	ret
SeFilLpq1_OnSwitch25:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, Scoop_SoundEditorData_Epilogue18
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Epilogue18
	ldw	wa, 54
	ld	bc, 0:i3
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue18:
	inc	4, xsp
	ret
SeFilLpq1_OnSwitch15:
	dec	4, xsp
	ld	(xsp+2), a
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Epilogue19
	cp (XSP),0x00
	jr nz, .Lc_f0550c
	ldw WA, 0x0020
	ld bc, 0:i3
	jr t, .Lc_f05511
.Lc_f0550c:
	ldw WA, 0x003d
	ld bc, 0:i3
.Lc_f05511:
	call SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue19:
	inc 4,XSP
	ret
SeFilHpq1_OnColumn1:
	extz	wa
	ld	bc, 1:i3
	ldw	de, 49
	calr	Scoop_SoundEditorData_Helper2
	ld	wa, 1:i3
	ld	bc, 0:i3
	jp	UpdSeSel_DetailedUpdate_Helper5
SeFilHpq1_OnColumn2:
	extz	wa
	ld	bc, 2:i3
	ldw	de, 49
	calr	Scoop_SoundEditorData_Helper3
	ld	wa, 1:i3
	ld	bc, 0:i3
	jp	UpdSeSel_DetailedUpdate_Helper5
SeFilHpq1_OnColumn3:
	extz	wa
	ld	bc, 3:i3
	ldw	de, 49
	jrl	Scoop_SoundEditorData_Join21
SeFilHpq1_OnColumn4:
	extz	wa
	ld	bc, 4:i3
	ldw	de, 49
	jrl	Scoop_SoundEditorData_Join22
SeFilHpq1_OnColumn6:
	extz	wa
	jrl	Scoop_SoundEditorData_Join23
SeFilHpq1_OnColumn7:
	extz	wa
	jrl	Scoop_SoundEditorData_Join24
SeFilHpq1_OnColumn8:
	extz	wa
	jrl	Scoop_SoundEditorData_Join25
SeFilHpq1_OnSideRow1:
	extz	wa
	jrl	Scoop_SoundEditorData_Join26
SeFilHpq1_OnSideRow2:
	extz	wa
	jrl	Scoop_SoundEditorData_Join27
SeFilHpq1_OnSideRow3:
	extz	wa
	jrl	Scoop_SoundEditorData_Join28
SeFilHpq1_OnSideRow4:
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+4), 0
	jr	nz, Scoop_SoundEditorData_Skip40
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
	jr	Scoop_SoundEditorData_Join31
Scoop_SoundEditorData_Skip40:
	cp	(xsp), 0
	jr	nz, Scoop_SoundEditorData_Epilogue20
	ld	wa, 3:i3
	call	SeMenu_CopyWriteUpdate_Helper5
	cp	l, 0:i3
	jr	z, Scoop_SoundEditorData_Epilogue20
	ldw	wa, 48
	ld	bc, 0:i3
Scoop_SoundEditorData_Join31:
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue20:
	inc	6, xsp
	ret
SeFilHpq1_OnSideRow5:
	extz	wa
	jrl	Scoop_SoundEditorData_Join30
SeFilHpq1_OnSwitch25:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Epilogue21
	cp	(xsp), 0
	jr	nz, Scoop_SoundEditorData_Epilogue21
	ldw	wa, 54
	ld	bc, 0:i3
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue21:
	inc	4, xsp
	ret
SeFilHpq1_OnSwitch15:
	dec	4, xsp
	ld	(xsp+2), a
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Epilogue22
	cp	(xsp), 0
	jr	nz, Scoop_SoundEditorData_Skip41
	ldw	wa, 32
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join32
Scoop_SoundEditorData_Skip41:
	ldw	wa, 61
	ld	bc, 0:i3
Scoop_SoundEditorData_Join32:
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue22:
	inc	4, xsp
	ret
SeFilL241_OnColumn3:
	extz	wa
	ld	bc, 3:i3
	ldw	de, 50
	calr	Scoop_SoundEditorData_Helper2
	ld	wa, 0:i3
	ld	bc, 1:i3
	jp	UpdSeSel_DetailedUpdate_Helper5
SeFilL241_OnColumn4:
	extz	wa
	ld	bc, 4:i3
	ldw	de, 50
	calr	Scoop_SoundEditorData_Helper3
	ld	wa, 0:i3
	ld	bc, 1:i3
	jp	UpdSeSel_DetailedUpdate_Helper5
SeFilL241_OnColumn5:
	extz	wa
	ld	bc, 5:i3
	ldw	de, 50
	jrl	Scoop_SoundEditorData_Join21
SeFilL241_OnColumn6:
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
	jr	nz, Scoop_SoundEditorData_Skip42
	cp	(xsp), 0
	jr	nz, Scoop_SoundEditorData_Epilogue23
	ldw	wa, 55
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	jr	Scoop_SoundEditorData_Epilogue23
Scoop_SoundEditorData_Skip42:
	call	SeMenu_CopyWriteUpdate_Helper3
Scoop_SoundEditorData_Epilogue23:
	inc	4, xsp
	ret
Scoop_SoundEditorData_Join34:
	cp	a, 0:i3
	ret	z
	ld	wa, 1:i3
	call	SeMenu_CopyWriteUpdate_Helper5
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
	jr	nz, Scoop_SoundEditorData_Skip43
	cp	(xsp), 0
	jr	nz, Scoop_SoundEditorData_Epilogue24
	ldw	wa, 57
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join36
Scoop_SoundEditorData_Skip43:
	ld	wa, 2:i3
	call	SeMenu_CopyWriteUpdate_Helper5
	cp	l, 0:i3
	jr	z, Scoop_SoundEditorData_Epilogue24
	ldw	wa, 48
	ld	bc, 0:i3
Scoop_SoundEditorData_Join36:
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue24:
	inc	4, xsp
	ret
SeFilL241_OnSideRow4:
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+4), 0
	jr	nz, Scoop_SoundEditorData_Skip44
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
	jr	Scoop_SoundEditorData_Join37
Scoop_SoundEditorData_Skip44:
	cp	(xsp), 1
	jr	z, Scoop_SoundEditorData_Epilogue25
	ld	wa, 3:i3
	call	SeMenu_CopyWriteUpdate_Helper5
	cp	l, 0:i3
	jr	z, Scoop_SoundEditorData_Epilogue25
	ldw	wa, 48
	ld	bc, 0:i3
Scoop_SoundEditorData_Join37:
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue25:
	inc	6, xsp
	ret
Scoop_SoundEditorData_Join38:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, Scoop_SoundEditorData_Epilogue26
	cp	(xsp+2), 0
	jr	z, Scoop_SoundEditorData_Epilogue26
	ld	wa, 4:i3
	call	SeMenu_CopyWriteUpdate_Helper5
	cp	l, 0:i3
	jr	z, Scoop_SoundEditorData_Epilogue26
	ldw	wa, 48
	ld	bc, 0:i3
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue26:
	inc	4, xsp
	ret
SeFilL241_OnSwitch25:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, Scoop_SoundEditorData_Epilogue27
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Epilogue27
	ldw	wa, 54
	ld	bc, 0:i3
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue27:
	inc	4, xsp
	ret
SeFilL241_OnSwitch15:
	dec	4, xsp
	ld	(xsp+2), a
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Epilogue28
	cp	(xsp), 0
	jr	nz, Scoop_SoundEditorData_Skip45
	ldw	wa, 32
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join39
Scoop_SoundEditorData_Skip45:
	ldw	wa, 61
	ld	bc, 0:i3
Scoop_SoundEditorData_Join39:
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue28:
	inc	4, xsp
	ret
SeFilH241_OnColumn3:
	extz	wa
	ld	bc, 3:i3
	ldw	de, 51
	calr	Scoop_SoundEditorData_Helper2
	ld	wa, 1:i3
	ld	bc, 1:i3
	jp	UpdSeSel_DetailedUpdate_Helper5
SeFilH241_OnColumn4:
	extz	wa
	ld	bc, 4:i3
	ldw	de, 51
	calr	Scoop_SoundEditorData_Helper3
	ld	wa, 1:i3
	ld	bc, 1:i3
	jp	UpdSeSel_DetailedUpdate_Helper5
SeFilH241_OnColumn5:
	extz	wa
	ld	bc, 5:i3
	ldw	de, 51
	jrl	Scoop_SoundEditorData_Join21
SeFilH241_OnColumn6:
	extz	wa
	ld	bc, 6:i3
	ldw	de, 51
	jrl	Scoop_SoundEditorData_Join22
SeFilH241_OnSideRow1:
	extz	wa
	jrl	Scoop_SoundEditorData_Join33
SeFilH241_OnSideRow2:
	extz	wa
	jrl	Scoop_SoundEditorData_Join34
SeFilH241_OnSideRow3:
	extz	wa
	jrl	Scoop_SoundEditorData_Join35
SeFilH241_OnSideRow4:
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+4), 0
	jr	nz, Scoop_SoundEditorData_Skip46
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
	jr	Scoop_SoundEditorData_Join40
Scoop_SoundEditorData_Skip46:
	cp	(xsp), 1
	jr	z, Scoop_SoundEditorData_Epilogue29
	ld	wa, 3:i3
	call	SeMenu_CopyWriteUpdate_Helper5
	cp	l, 0:i3
	jr	z, Scoop_SoundEditorData_Epilogue29
	ldw	wa, 48
	ld	bc, 0:i3
Scoop_SoundEditorData_Join40:
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue29:
	inc	6, xsp
	ret
SeFilH241_OnSideRow5:
	extz	wa
	jrl	Scoop_SoundEditorData_Join38
SeFilH241_OnSwitch25:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, Scoop_SoundEditorData_Epilogue30
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Epilogue30
	ldw	wa, 54
	ld	bc, 0:i3
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue30:
	inc	4, xsp
	ret
SeFilH241_OnSwitch15:
	dec	4, xsp
	ld	(xsp+2), a
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Epilogue31
	cp	(xsp), 0
	jr	nz, Scoop_SoundEditorData_Skip47
	ldw	wa, 32
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join41
Scoop_SoundEditorData_Skip47:
	ldw	wa, 61
	ld	bc, 0:i3
Scoop_SoundEditorData_Join41:
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue31:
	inc	4, xsp
	ret
SeFilBpf1_OnColumn2:
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
	jr	nz, Scoop_SoundEditorData_Skip48
	ld	a, 77:opc
	jr	Scoop_SoundEditorData_Join42
Scoop_SoundEditorData_Skip48:
	ld	a, (xsp+16)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+17)
	ld	(xsp+16), 0
Scoop_SoundEditorData_Join42:
	ld	e, (xsp+16)
	extz	de
	extz	wa
	pushw	wa
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 52
	ld	bc, 2:i3
	call	SeMenu_ApplyPartEdit_Helper3
	call	Scoop_SoundEditorData_Helper7
	ld	wa, 2:i3
	call	SeMenu_ApplyPartEdit_Entry2_Code_Helper
	lda	xsp, (xsp+20)
	ret
SeFilBpf1_OnColumn3:
	extz	wa
	ld	bc, 3:i3
	ldw	de, 52
	calr	Scoop_SoundEditorData_Helper3
	jp	Scoop_SoundEditorData_Helper7
SeFilBpf1_OnColumn4:
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
	jr	nz, Scoop_SoundEditorData_Skip49
	ld	e, (xsp+16)
	extz	de
	pushw	79
	push	xbc
	ldw	wa, 52
	ld	bc, 4:i3
	jr	Scoop_SoundEditorData_Join43
Scoop_SoundEditorData_Skip49:
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
Scoop_SoundEditorData_Join43:
	call	SeMenu_ApplyPartEdit_Helper3
	call	Scoop_SoundEditorData_Helper7
	ld	wa, 4:i3
	call	SeMenu_ApplyPartEdit_Entry2_Code_Helper
	lda	xsp, (xsp+20)
	ret
SeFilBpf1_OnColumn5:
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
	jr	nz, Scoop_SoundEditorData_Skip50
	ld	e, (xsp+14)
	extz	de
	pushw	80
	push	xbc
	ldw	wa, 52
	ld	bc, 5:i3
	jr	Scoop_SoundEditorData_Join44
Scoop_SoundEditorData_Skip50:
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
Scoop_SoundEditorData_Join44:
	call	SeMenu_ApplyPartEdit_Helper3
	call	Scoop_SoundEditorData_Helper7
	ld	wa, 5:i3
	call	SeMenu_ApplyPartEdit_Entry2_Code_Helper
	lda	xsp, (xsp+18)
	ret
SeFilBpf1_OnColumn6:
	extz	wa
	ld	bc, 6:i3
	ldw	de, 52
	jrl	Scoop_SoundEditorData_Join21
SeFilBpf1_OnColumn7:
	extz	wa
	ld	bc, 7:i3
	ldw	de, 52
	jrl	Scoop_SoundEditorData_Join22
SeFilBpf1_OnSideRow1:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Skip51
	cp	(xsp), 0
	jr	nz, Scoop_SoundEditorData_Epilogue32
	ldw	wa, 55
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	jr	Scoop_SoundEditorData_Epilogue32
Scoop_SoundEditorData_Skip51:
	call	SeMenu_CopyWriteUpdate_Helper3
Scoop_SoundEditorData_Epilogue32:
	inc	4, xsp
	ret
SeFilBpf1_OnSideRow2:
	cp	a, 0:i3
	ret	z
	ld	wa, 1:i3
	call	SeMenu_CopyWriteUpdate_Helper5
	cp	l, 0:i3
	ret	z
	ldw	wa, 48
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
SeFilBpf1_OnSideRow3:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Skip52
	cp	(xsp), 0
	jr	nz, Scoop_SoundEditorData_Epilogue33
	ldw	wa, 57
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join45
Scoop_SoundEditorData_Skip52:
	ld	wa, 2:i3
	call	SeMenu_CopyWriteUpdate_Helper5
	cp	l, 0:i3
	jr	z, Scoop_SoundEditorData_Epilogue33
	ldw	wa, 48
	ld	bc, 0:i3
Scoop_SoundEditorData_Join45:
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue33:
	inc	4, xsp
	ret
SeFilBpf1_OnSideRow4:
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+4), 0
	jr	nz, Scoop_SoundEditorData_Skip53
	lda	xbc, (xsp+2)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	andmi8	(xsp+2), 248
	ld	a, (xsp+2)
	extz	wa
	call	Scoop_SoundEditorData_Helper4
	ldw	wa, 48
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join46
Scoop_SoundEditorData_Skip53:
	cp	(xsp), 1
	jr	z, Scoop_SoundEditorData_Epilogue34
	ld	wa, 3:i3
	call	SeMenu_CopyWriteUpdate_Helper5
	cp	l, 0:i3
	jr	z, Scoop_SoundEditorData_Epilogue34
	ldw	wa, 48
	ld	bc, 0:i3
Scoop_SoundEditorData_Join46:
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue34:
	inc	6, xsp
	ret
SeFilBpf1_OnSideRow5:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, Scoop_SoundEditorData_Epilogue35
	cp	(xsp+2), 0
	jr	z, Scoop_SoundEditorData_Epilogue35
	ld	wa, 4:i3
	call	SeMenu_CopyWriteUpdate_Helper5
	cp	l, 0:i3
	jr	z, Scoop_SoundEditorData_Epilogue35
	ldw	wa, 48
	ld	bc, 0:i3
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue35:
	inc	4, xsp
	ret
SeFilBpf1_OnSwitch25:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, Scoop_SoundEditorData_Epilogue36
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Epilogue36
	ldw	wa, 54
	ld	bc, 0:i3
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue36:
	inc	4, xsp
	ret
SeFilBpf1_OnSwitch15:
	dec	4, xsp
	ld	(xsp+2), a
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Epilogue37
	cp	(xsp), 0
	jr	nz, Scoop_SoundEditorData_Skip54
	ldw	wa, 32
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join47
Scoop_SoundEditorData_Skip54:
	ldw	wa, 61
	ld	bc, 0:i3
Scoop_SoundEditorData_Join47:
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue37:
	inc	4, xsp
	ret
SeFilBcf1_OnSideRow1:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Skip55
	cp	(xsp), 0
	jr	nz, Scoop_SoundEditorData_Epilogue38
	ldw	wa, 55
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	jr	Scoop_SoundEditorData_Epilogue38
Scoop_SoundEditorData_Skip55:
	call	SeMenu_CopyWriteUpdate_Helper3
Scoop_SoundEditorData_Epilogue38:
	inc	4, xsp
	ret
SeFilBcf1_OnSideRow2:
	cp	a, 0:i3
	ret	z
	ld	wa, 1:i3
	call	SeMenu_CopyWriteUpdate_Helper5
	cp	l, 0:i3
	ret	z
	ldw	wa, 48
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
SeFilBcf1_OnSideRow3:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Skip56
	cp	(xsp), 0
	jr	nz, Scoop_SoundEditorData_Epilogue39
	ldw	wa, 57
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join48
Scoop_SoundEditorData_Skip56:
	ld	wa, 2:i3
	call	SeMenu_CopyWriteUpdate_Helper5
	cp	l, 0:i3
	jr	z, Scoop_SoundEditorData_Epilogue39
	ldw	wa, 48
	ld	bc, 0:i3
Scoop_SoundEditorData_Join48:
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue39:
	inc	4, xsp
	ret
SeFilBcf1_OnSideRow4:
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+4), 0
	jr	nz, Scoop_SoundEditorData_Skip57
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
	jr	Scoop_SoundEditorData_Join49
Scoop_SoundEditorData_Skip57:
	cp	(xsp), 1
	jr	z, Scoop_SoundEditorData_Epilogue40
	ld	wa, 3:i3
	call	SeMenu_CopyWriteUpdate_Helper5
	cp	l, 0:i3
	jr	z, Scoop_SoundEditorData_Epilogue40
	ldw	wa, 48
	ld	bc, 0:i3
Scoop_SoundEditorData_Join49:
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue40:
	inc	6, xsp
	ret
SeFilBcf1_OnSideRow5:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, Scoop_SoundEditorData_Epilogue41
	cp	(xsp+2), 0
	jr	z, Scoop_SoundEditorData_Epilogue41
	ld	wa, 4:i3
	call	SeMenu_CopyWriteUpdate_Helper5
	cp	l, 0:i3
	jr	z, Scoop_SoundEditorData_Epilogue41
	ldw	wa, 48
	ld	bc, 0:i3
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue41:
	inc	4, xsp
	ret
SeFilBcf1_OnSwitch25:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, Scoop_SoundEditorData_Epilogue42
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Epilogue42
	ldw	wa, 54
	ld	bc, 0:i3
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue42:
	inc	4, xsp
	ret
SeFilBcf1_OnSwitch15:
	dec	4, xsp
	ld	(xsp+2), a
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 0
	jr	nz, Scoop_SoundEditorData_Epilogue43
	cp	(xsp), 0
	jr	nz, Scoop_SoundEditorData_Skip58
	ldw	wa, 32
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join50
Scoop_SoundEditorData_Skip58:
	ldw	wa, 61
	ld	bc, 0:i3
Scoop_SoundEditorData_Join50:
	call	SeMenu_SendEvent
Scoop_SoundEditorData_Epilogue43:
	inc	4, xsp
	ret
SeFilFil2_OnColumn3:
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
	call	SeMenu_ApplyPartEdit_Helper3
	cp	l, 1:i3
	jr	nz, Scoop_SoundEditorData_Skip59
	lda	xbc, (xsp+12)
	ld	wa, 3:i3
	call	SeMenu_LoadPartParam
	ld	c, (xsp+12)
	extz	bc
	ldw	wa, 10
	call	SeMenu_StorePartParam
	ld	wa, 0:i3
	ld	bc, 0:i3
	call	SeMenu_ApplyPartEdit_Helper12
Scoop_SoundEditorData_Skip59:
	ld	wa, 3:i3
	call	SeMenu_ApplyPartEdit_Entry2_Code_Helper
	lda	xsp, (xsp+18)
	ret
SeFilFil2_OnColumn4:
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
	call	SeMenu_ApplyPartEdit_Helper14
	cp	l, 1:i3
	jr	nz, Scoop_SoundEditorData_Skip60
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
	call	SeMenu_ApplyPartEdit_Helper12
Scoop_SoundEditorData_Skip60:
	ld	wa, 4:i3
	call	SeMenu_ApplyPartEdit_Entry2_Code_Helper
	inc	8, xsp
	ret
SeFilFil2_OnColumn5:
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
	call	SeMenu_ApplyPartEdit_Helper14
	cp	l, 1:i3
	jr	nz, Scoop_SoundEditorData_Skip61
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
	call	SeMenu_ApplyPartEdit_Helper12
Scoop_SoundEditorData_Skip61:
	ld	wa, 5:i3
	call	SeMenu_ApplyPartEdit_Entry2_Code_Helper
	lda	xsp, (xsp+10)
	ret
SeFilFil2_OnColumn6:
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
	call	SeMenu_ApplyPartEdit_Helper14
	cp	l, 1:i3
	jr	nz, Scoop_SoundEditorData_Skip62
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
	call	SeMenu_ApplyPartEdit_Helper12
Scoop_SoundEditorData_Skip62:
	ld	wa, 6:i3
	call	SeMenu_ApplyPartEdit_Entry2_Code_Helper
	inc	8, xsp
	ret
SeFilFil2_OnSideRow1:
	cp	a, 0:i3
	jp	nz, (SeMenu_CopyWriteUpdate_Helper3:24)
	ldw	wa, 55
	ld	bc, 0:i3
	jp	SeMenu_SendEvent
SeFilFil2_OnSideRow2:
	cp	a, 0:i3
	ret	z
	ld	wa, 1:i3
	call	SeMenu_CopyWriteUpdate_Helper5
	cp	l, 0:i3
	ret	z
	ldw	wa, 54
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
SeFilFil2_OnSideRow3:
	cp	a, 0:i3
	jr	nz, Scoop_SoundEditorData_Skip63
	ldw	wa, 57
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join51
Scoop_SoundEditorData_Skip63:
	ld	wa, 2:i3
	call	SeMenu_CopyWriteUpdate_Helper5
	cp	l, 0:i3
	ret	z
	ldw	wa, 54
	ld	bc, 1:i3
Scoop_SoundEditorData_Join51:
	call	SeMenu_SendEvent
	ret
SeFilFil2_OnSideRow4:
	cp	a, 0:i3
	ret	z
	ld	wa, 3:i3
	call	SeMenu_CopyWriteUpdate_Helper5
	cp	l, 0:i3
	ret	z
	ldw	wa, 54
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
SeFilFil2_OnSideRow5:
	cp	a, 0:i3
	ret	z
	ld	wa, 4:i3
	call	SeMenu_CopyWriteUpdate_Helper5
	cp	l, 0:i3
	ret	z
	ldw	wa, 54
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
SeFilFil2_OnSwitch25:
	cp	a, 0:i3
	ret	z
	ldw	wa, 48
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
SeFilFil2_OnSwitch15:
	cp	a, 0:i3
	ret	nz
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	ldw	wa, 32
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
SeFilEnv1_OnColumn1:
	extz	wa
	ldw	bc, 63
	ld	de, 0:i3
	jp	SeMenu_ApplyPartEdit_AltStore_Join8
SeFilEnv1_OnColumn2:
	extz	wa
	ldw	bc, 64
	ld	de, 0:i3
	jp	SeMenu_ApplyPartEdit_AltStore_Join9
SeFilEnv1_OnColumn3:
	extz	wa
	ldw	bc, 62
	ldw	de, 65
	jp	SeMenu_ApplyPartEdit_AltStore_Join10
SeFilEnv1_OnColumn4:
	extz	wa
	ldw	bc, 66
	ld	de, 0:i3
	jp	SeMenu_ApplyPartEdit_AltStore_Join11
SeFilEnv1_OnColumn5:
	extz	wa
	ldw	bc, 70
	ldw	de, 67
	jp	SeMenu_ApplyPartEdit_AltStore_Join12
SeFilEnv1_OnColumn6:
	extz	wa
	ldw	bc, 68
	ld	de, 0:i3
	jp	SeMenu_ApplyPartEdit_AltStore_Join13
SeFilEnv1_OnColumn7:
	extz	wa
	ldw	bc, 61
	ldw	de, 69
	jp	SeMenu_ApplyPartEdit_AltStore_Join14
SeFilEnv1_OnSideRow1:
	cp	a, 0:i3
	ret	z
	call	SeMenu_CopyWriteUpdate_Helper3
	ret
SeFilEnv1_OnSideRow2:
	cp	a, 0:i3
	jr	nz, Scoop_SoundEditorData_Skip64
	ldw	wa, 48
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join52
Scoop_SoundEditorData_Skip64:
	ld	wa, 1:i3
	call	SeMenu_CopyWriteUpdate_Helper5
	cp	l, 0:i3
	ret	z
	ldw	wa, 55
	ld	bc, 1:i3
Scoop_SoundEditorData_Join52:
	call	SeMenu_SendEvent
	ret
SeFilEnv1_OnSideRow3:
	cp	a, 0:i3
	jr	nz, Scoop_SoundEditorData_Skip65
	ldw	wa, 57
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join53
Scoop_SoundEditorData_Skip65:
	ld	wa, 2:i3
	call	SeMenu_CopyWriteUpdate_Helper5
	cp	l, 0:i3
	ret	z
	ldw	wa, 55
	ld	bc, 1:i3
Scoop_SoundEditorData_Join53:
	call	SeMenu_SendEvent
	ret
SeFilEnv1_OnSideRow4:
	cp	a, 0:i3
	jr	nz, Scoop_SoundEditorData_Skip66
	ld	wa, 0:i3
	jp	SeMenu_ApplyPartEdit_AltStore_Join7
Scoop_SoundEditorData_Skip66:
	ld	wa, 3:i3
	call	SeMenu_CopyWriteUpdate_Helper5
	cp	l, 0:i3
	ret	z
	ldw	wa, 55
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
SeFilEnv1_OnSideRow5:
	cp	a, 0:i3
	jr	nz, Scoop_SoundEditorData_Skip67
	ld	wa, 1:i3
	jp	SeMenu_ApplyPartEdit_AltStore_Join7
Scoop_SoundEditorData_Skip67:
	ld	wa, 4:i3
	call	SeMenu_CopyWriteUpdate_Helper5
	cp	l, 0:i3
	ret	z
	ldw	wa, 55
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
SeFilEnv1_OnSwitch25:
	cp	a, 0:i3
	ret	nz
	ldw	wa, 56
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
SeFilEnv1_OnSwitch15:
	cp	a, 0:i3
	ret	nz
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	ldw	wa, 32
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
SeFilEnv2_OnColumn2:
	extz	wa
	ldw	bc, 74
	jp	SeMenu_ApplyPartEdit_AltStore_Join15
SeFilEnv2_OnColumn3:
	extz	wa
	ldw	bc, 75
	jp	SeMenu_ApplyPartEdit_AltStore_Join16
SeFilEnv2_OnColumn4:
	extz	wa
	ldw	bc, 76
	jp	SeMenu_ApplyPartEdit_AltStore_Join17
SeFilEnv2_OnColumn5:
	extz	wa
	ldw	bc, 73
	jp	SeMenu_ApplyPartEdit_AltStore_Join18
SeFilEnv2_OnColumn7:
	extz	wa
	ldw	bc, 71
	jp	SeMenu_ApplyPartEdit_AltStore_Join19
SeFilEnv2_OnColumn8:
	extz	wa
	ldw	bc, 72
	jp	SeMenu_ApplyPartEdit_AltStore_Join20
SeFilEnv2_OnSideRow1:
	cp	a, 0:i3
	ret	z
	call	SeMenu_CopyWriteUpdate_Helper3
	ret
SeFilEnv2_OnSideRow2:
	cp	a, 0:i3
	jr	nz, Scoop_SoundEditorData_Skip68
	ldw	wa, 48
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join54
Scoop_SoundEditorData_Skip68:
	ld	wa, 1:i3
	call	SeMenu_CopyWriteUpdate_Helper5
	cp	l, 0:i3
	ret	z
	ldw	wa, 56
	ld	bc, 1:i3
Scoop_SoundEditorData_Join54:
	call	SeMenu_SendEvent
	ret
SeFilEnv2_OnSideRow3:
	cp	a, 0:i3
	jr	nz, Scoop_SoundEditorData_Skip69
	ldw	wa, 57
	ld	bc, 0:i3
	jr	Scoop_SoundEditorData_Join55
Scoop_SoundEditorData_Skip69:
	ld	wa, 2:i3
	call	SeMenu_CopyWriteUpdate_Helper5
	cp	l, 0:i3
	ret	z
	ldw	wa, 56
	ld	bc, 1:i3
Scoop_SoundEditorData_Join55:
	call	SeMenu_SendEvent
	ret
SeFilEnv2_OnSideRow4:
	cp	a, 0:i3
	ret	z
	ld	wa, 3:i3
	call	SeMenu_CopyWriteUpdate_Helper5
	cp	l, 0:i3
	ret	z
	ldw	wa, 56
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
SeFilEnv2_OnSideRow5:
	cp	a, 0:i3
	ret	z
	ld	wa, 4:i3
	call	SeMenu_CopyWriteUpdate_Helper5
	cp	l, 0:i3
	ret	z
	ldw	wa, 56
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
SeFilEnv2_OnSwitch25:
	cp	a, 0:i3
	ret	z
	ldw	wa, 55
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
SeFilEnv2_OnSwitch15:
	cp	a, 0:i3
	ret	nz
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	ldw	wa, 32
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
SeFilLfo1_OnColumn2:
	extz	wa
	ld	bc, 2:i3
	jp	SeMenu_ApplyPartEdit_Data2
SeFilLfo1_OnColumn3:
	extz	wa
	ld	bc, 2:i3
	jp	SeMenu_ApplyPartEdit_AltStore_Join
SeFilLfo1_OnColumn4:
	extz	wa
	ld	bc, 2:i3
	jp	SeMenu_ApplyPartEdit_AltStore_Join2
SeFilLfo1_OnColumn5:
	extz	wa
	ld	bc, 2:i3
	jp	SeMenu_ApplyPartEdit_AltStore_Join3
SeFilLfo1_OnColumn6:
	extz	wa
	ld	bc, 2:i3
	jp	SeMenu_ApplyPartEdit_AltStore_Join4
SeFilLfo1_OnColumn7:
	extz	wa
	ld	bc, 2:i3
	jp	SeMenu_ApplyPartEdit_AltStore_Join5
SeFilLfo1_OnColumn8:
	extz	wa
	ld	bc, 2:i3
	jp	SeMenu_ApplyPartEdit_AltStore_Join6
SeFilLfo1_OnSideRow1:
	cp	a, 0:i3
	jp	nz, (SeMenu_CopyWriteUpdate_Helper3:24)
	ldw	wa, 55
	ld	bc, 0:i3
	jp	SeMenu_SendEvent
SeFilLfo1_OnSideRow2:
	cp	a, 0:i3
	jr	nz, Scoop_SoundEditorData_Skip70
	ldw	wa, 48
	ld	bc, 0:i3
	jp	SeMenu_SendEvent
Scoop_SoundEditorData_Skip70:
	ld	wa, 2:i3
	ld	bc, 1:i3
	jp	Scoop_SoundEditorData_Helper5
SeFilLfo1_OnSideRow3:
	cp	a, 0:i3
	ret	z
	ld	wa, 2:i3
	ld	bc, 2:i3
	call	Scoop_SoundEditorData_Helper5
	ret
SeFilLfo1_OnSideRow4:
	cp	a, 0:i3
	ret	z
	ld	wa, 2:i3
	ld	bc, 3:i3
	call	Scoop_SoundEditorData_Helper5
	ret
SeFilLfo1_OnSideRow5:
	cp	a, 0:i3
	ret	z
	ld	wa, 2:i3
	ld	bc, 4:i3
	call	Scoop_SoundEditorData_Helper5
	ret
	cp	a, 0:i3
	ret	nz
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	ldw	wa, 32
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
