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
	call	SeWrtSndTitleFunc_DispatchSwitch
SeWrtSndTitleFunc_OnSwitchIn_Join:
	ld	wa, 1:i3
	call	AudioLock_GetCount
	cp	hl, 0:i3
	jr	z, SeWrtSndTitleFunc_OnSwitchIn_Skip
	ld	wa, 3:i3
	call	TaskSched_YieldToQueue
	jr	SeWrtSndTitleFunc_OnSwitchIn_Join
SeWrtSndTitleFunc_OnSwitchIn_Skip:
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
SeAmpAmp1TitleFunc_DispatchSwitch_Epilogue:
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
SeAmpAmp2TitleFunc_DispatchSwitch_Epilogue2:
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
SeAmpEnv1TitleFunc_DispatchSwitch_Epilogue3:
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
SeAmpEnv2TitleFunc_DispatchSwitch_Epilogue4:
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
SeAmpLfo1TitleFunc_DispatchSwitch_Epilogue5:
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
	call	SeMenu_SwitchToValueStep
	lda	xhl, (xsp+2)
	lda	xwa, (xhl+6)
	lda	xbc, (xhl+7)
	lda	xde, (xhl+8)
	lda	xhl, (xhl+9)
	cp	(xsp+14), 0
	jr	nz, SeAmpAmp1_OnColumn3_Skip2
	ld	(xwa), 127
	ld	(xbc), 0
	ld	(xde), 127
	ld	(xhl), 0
	ld	a, 23:opc
	jr	SeAmpAmp1_OnColumn3_Join2
SeAmpAmp1_OnColumn3_Skip2:
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
SeAmpAmp1_OnColumn3_Join2:
	ld	c, (xsp)
	extz	bc
	ld	e, (xsp+16)
	extz	de
	extz	wa
	pushw	wa
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 43
	call	SeMenu_StepParamFieldAndSend
	cp	(xsp+14), 0
	jr	nz, SeAmpAmp1_OnColumn3_Skip3
	cp	l, 1:i3
	jr	nz, SeAmpAmp1_OnColumn3_Skip3
	ld	a, (xsp+16)
	extz	wa
	ld	c, (xsp+5)
	extz	bc
	call	SeMenu_StoreParamByte
SeAmpAmp1_OnColumn3_Skip3:
	ld	wa, 3:i3
	call	SeMenu_BindDialToColumn
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
	jr	nz, SeAmpAmp1_OnColumn4_Skip53
	ld	a, (xsp+16)
	inc	4, a
	ldfr_berp	a, 251
	jr	SeAmpAmp1_OnColumn4_Join3
SeAmpAmp1_OnColumn4_Skip53:
	ld	a, (xsp+16)
	inc	2, a
	ldfr_berp	a, 251
SeAmpAmp1_OnColumn4_Join3:
	ldto_berp	a, 251
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xsp+12)
	call	SeMenu_SwitchToValueStep
	lda	xhl, (xsp+2)
	lda	xwa, (xhl+6)
	lda	xbc, (xhl+7)
	lda	xde, (xhl+8)
	lda	xhl, (xhl+9)
	cp	(xsp+14), 0
	jr	nz, SeAmpAmp1_OnColumn4_Skip4
	ld	(xwa), 255
	ld	(xbc), 0
	ld	(xde), 50
	ld	(xhl), 206
	ld	a, 24:opc
	jr	SeAmpAmp1_OnColumn4_Join4
SeAmpAmp1_OnColumn4_Skip4:
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
SeAmpAmp1_OnColumn4_Join4:
	ldto_berp	c, 251
	extz	bc
	ld	e, (xsp+16)
	extz	de
	extz	wa
	pushw	wa
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 43
	call	SeMenu_StepParamFieldAndSend
	ld	wa, 4:i3
	call	SeMenu_BindDialToColumn
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
	jr	z, SeAmpAmp1_OnColumn5_Epilogue
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
	call	SeMenu_SwitchToValueStep
	ldto_berp	c, 251
	extz	bc
	ld	e, (xsp+16)
	extz	de
	pushw	25
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 43
	call	SeMenu_StepParamFieldAndSend
	ld	wa, 5:i3
	call	SeMenu_BindDialToColumn
SeAmpAmp1_OnColumn5_Epilogue:
	pop	qiz
	lda	xsp, (xsp+18)
	ret
SeAmpAmp1_OnSideRow1:
	cp	a, 0:i3
	jp	nz, (SeMenu_ToggleSolo:24)
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
	jr	nz, SeAmpAmp1_OnSideRow3_Skip54
	cp	(xsp), 1
	jr	z, SeAmpAmp1_OnSideRow3_Epilogue2
	ldw	wa, 47
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	jr	SeAmpAmp1_OnSideRow3_Epilogue2
SeAmpAmp1_OnSideRow3_Skip54:
	ldw	wa, 43
	ld	bc, 2:i3
	ld	de, 1:i3
	call	SeMenu_CopyWriteUpdate_Helper8
SeAmpAmp1_OnSideRow3_Epilogue2:
	inc	4, xsp
	ret
SeAmpAmp1_OnSideRow4:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, SeAmpAmp1_OnSideRow4_Epilogue3
	cp	(xsp+2), 0
	jr	z, SeAmpAmp1_OnSideRow4_Epilogue3
	ldw	wa, 43
	ld	bc, 3:i3
	ld	de, 1:i3
	call	SeMenu_CopyWriteUpdate_Helper8
SeAmpAmp1_OnSideRow4_Epilogue3:
	inc	4, xsp
	ret
SeAmpAmp1_OnSideRow5:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, SeAmpAmp1_OnSideRow5_Epilogue4
	cp	(xsp+2), 0
	jr	z, SeAmpAmp1_OnSideRow5_Epilogue4
	ldw	wa, 43
	ld	bc, 4:i3
	ld	de, 1:i3
	call	SeMenu_CopyWriteUpdate_Helper8
SeAmpAmp1_OnSideRow5_Epilogue4:
	inc	4, xsp
	ret
SeAmpAmp1_OnSwitch25:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, SeAmpAmp1_OnSwitch25_Epilogue5
	cp	(xsp+2), 0
	jr	nz, SeAmpAmp1_OnSwitch25_Epilogue5
	ldw	wa, 44
	ld	bc, 0:i3
	call	SeMenu_SendEvent
SeAmpAmp1_OnSwitch25_Epilogue5:
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
	jr	nz, SeAmpAmp1_OnSwitch15_Epilogue6
	cp	(xsp), 0
	jr	nz, SeAmpAmp1_OnSwitch15_Skip5
	ldw	wa, 32
	ld	bc, 0:i3
	jr	SeAmpAmp1_OnSwitch15_Join5
SeAmpAmp1_OnSwitch15_Skip5:
	ldw	wa, 61
	ld	bc, 0:i3
SeAmpAmp1_OnSwitch15_Join5:
	call	SeMenu_SendEvent
SeAmpAmp1_OnSwitch15_Epilogue6:
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
	call	SeMenu_SwitchToValueStep
	ld	e, (xsp+14)
	extz	de
	pushw	29
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 44
	ld	bc, 3:i3
	call	SeMenu_StepParamFieldAndSend
	cp	l, 1:i3
	jr	nz, SeAmpAmp2_OnColumn3_Skip6
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
SeAmpAmp2_OnColumn3_Skip6:
	ld	wa, 3:i3
	call	SeMenu_BindDialToColumn
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
	call	SeMenu_StepNoteParamInRange
	cp	l, 1:i3
	jr	nz, SeAmpAmp2_OnColumn4_Skip7
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
SeAmpAmp2_OnColumn4_Skip7:
	ld	wa, 4:i3
	call	SeMenu_BindDialToColumn
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
	call	SeMenu_StepNoteParamInRange
	cp	l, 1:i3
	jr	nz, SeAmpAmp2_OnColumn5_Skip8
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
SeAmpAmp2_OnColumn5_Skip8:
	ld	wa, 5:i3
	call	SeMenu_BindDialToColumn
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
	call	SeMenu_StepNoteParamInRange
	cp	l, 1:i3
	jr	nz, SeAmpAmp2_OnColumn6_Skip9
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
SeAmpAmp2_OnColumn6_Skip9:
	ld	wa, 6:i3
	call	SeMenu_BindDialToColumn
	inc	8, xsp
	ret
SeAmpAmp2_OnSideRow1:
	cp	a, 0:i3
	jp	nz, (SeMenu_ToggleSolo:24)
	ldw	wa, 45
	ld	bc, 0:i3
	jp	SeMenu_SendEvent
SeAmpAmp2_OnSideRow2:
	cp	a, 0:i3
	ret	z
	ld	wa, 1:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	ret	z
	ldw	wa, 44
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
SeAmpAmp2_OnSideRow3:
	cp	a, 0:i3
	jr	nz, SeAmpAmp2_OnSideRow3_Skip10
	ldw	wa, 47
	ld	bc, 0:i3
	jr	SeAmpAmp2_OnSideRow3_Join6
SeAmpAmp2_OnSideRow3_Skip10:
	ld	wa, 2:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	ret	z
	ldw	wa, 44
	ld	bc, 1:i3
SeAmpAmp2_OnSideRow3_Join6:
	call	SeMenu_SendEvent
	ret
SeAmpAmp2_OnSideRow4:
	cp	a, 0:i3
	ret	z
	ld	wa, 3:i3
	call	SeMenu_SelectPartIfEnabled
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
	call	SeMenu_SelectPartIfEnabled
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
	call	SeMenu_SwitchToValueStep
	cp	(xsp+14), 0
	jr	nz, SeAmpEnv1_OnColumn1_Skip11
	ld	a, 39:opc
	jr	SeAmpEnv1_OnColumn1_Join7
SeAmpEnv1_OnColumn1_Skip11:
	ld	a, (xsp+16)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	inc	8, xwa
	ld	(xsp+16), 0
SeAmpEnv1_OnColumn1_Join7:
	ldto_berp	c, 251
	extz	bc
	ld	e, (xsp+16)
	extz	de
	extz	wa
	pushw	wa
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 45
	call	SeMenu_StepParamFieldAndSend
	call	UpdSeSel_DetailedUpdate_Helper4
	ld	wa, 1:i3
	call	SeMenu_BindDialToColumn
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
	jr	nz, SeAmpEnv1_OnColumn2_Skip55
	ldib_erp	251, 1
SeAmpEnv1_OnColumn2_Skip55:
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
	call	SeMenu_SwitchToValueStep
	cp	(xsp+14), 0
	jr	nz, SeAmpEnv1_OnColumn2_Skip12
	ld	a, 40:opc
	jr	SeAmpEnv1_OnColumn2_Join8
SeAmpEnv1_OnColumn2_Skip12:
	ld	a, (xsp+16)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+9)
	ld	(xsp+16), 0
SeAmpEnv1_OnColumn2_Join8:
	ldto_berp	c, 251
	extz	bc
	ld	e, (xsp+16)
	extz	de
	extz	wa
	pushw	wa
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 45
	call	SeMenu_StepParamFieldAndSend
	call	UpdSeSel_DetailedUpdate_Helper4
	ld	wa, 2:i3
	call	SeMenu_BindDialToColumn
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
	jr	nz, SeAmpEnv1_OnColumn3_Skip56
	ldib_erp	251, 2
SeAmpEnv1_OnColumn3_Skip56:
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
	call	SeMenu_SwitchToValueStep
	cp	(xsp+14), 0
	jr	nz, SeAmpEnv1_OnColumn3_Skip13
	ld	a, 41:opc
	jr	SeAmpEnv1_OnColumn3_Join9
SeAmpEnv1_OnColumn3_Skip13:
	ld	a, (xsp+16)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+10)
	ld	(xsp+16), 0
SeAmpEnv1_OnColumn3_Join9:
	ldto_berp	c, 251
	extz	bc
	ld	e, (xsp+16)
	extz	de
	extz	wa
	pushw	wa
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 45
	call	SeMenu_StepParamFieldAndSend
	call	UpdSeSel_DetailedUpdate_Helper4
	ld	wa, 3:i3
	call	SeMenu_BindDialToColumn
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
	jr	nz, SeAmpEnv1_OnColumn4_Skip57
	ldib_erp	251, 3
SeAmpEnv1_OnColumn4_Skip57:
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
	call	SeMenu_SwitchToValueStep
	cp	(xsp+14), 0
	jr	nz, SeAmpEnv1_OnColumn4_Skip14
	ld	a, 42:opc
	jr	SeAmpEnv1_OnColumn4_Join10
SeAmpEnv1_OnColumn4_Skip14:
	ld	a, (xsp+16)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+11)
	ld	(xsp+16), 0
SeAmpEnv1_OnColumn4_Join10:
	ldto_berp	c, 251
	extz	bc
	ld	e, (xsp+16)
	extz	de
	extz	wa
	pushw	wa
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 45
	call	SeMenu_StepParamFieldAndSend
	call	UpdSeSel_DetailedUpdate_Helper4
	ld	wa, 4:i3
	call	SeMenu_BindDialToColumn
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
	jr	nz, SeAmpEnv1_OnColumn5_Skip58
	ldib_erp	251, 4
	lda	xwa, (xsp+2)
	ld	(xwa+6), 127
	ld	(xwa+7), 0
	ld	(xwa+8), 100
	jr	SeAmpEnv1_OnColumn5_Join11
SeAmpEnv1_OnColumn5_Skip58:
	lda	xbc, (xsp+14)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	bitm	5, (xsp+14)
	jr	z, SeAmpEnv1_OnColumn5_Epilogue41
	ldib_erp	251, 5
	lda	xwa, (xsp+2)
	ld	(xwa+6), 127
	ld	(xwa+7), 0
	ld	(xwa+8), 100
SeAmpEnv1_OnColumn5_Join11:
	ld	(xwa+9), 0
	ldto_berp	a, 251
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	ld	a, (xsp+20)
	extz	wa
	lda	xbc, (xsp+12)
	call	SeMenu_SwitchToValueStep
	cp	(xsp+16), 0
	jr	nz, SeAmpEnv1_OnColumn5_Skip15
	ld	a, 43:opc
	jr	SeAmpEnv1_OnColumn5_Join12
SeAmpEnv1_OnColumn5_Skip15:
	ld	a, (xsp+18)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+12)
	ld	(xsp+18), 0
SeAmpEnv1_OnColumn5_Join12:
	ldto_berp	c, 251
	extz	bc
	ld	e, (xsp+18)
	extz	de
	extz	wa
	pushw	wa
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 45
	call	SeMenu_StepParamFieldAndSend
	call	UpdSeSel_DetailedUpdate_Helper4
	ld	wa, 5:i3
	call	SeMenu_BindDialToColumn
SeAmpEnv1_OnColumn5_Epilogue41:
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
	jr	nz, SeAmpEnv1_OnColumn6_Skip59
	ldib_erp	251, 5
	lda	xwa, (xsp+2)
	ld	(xwa+6), 127
	ld	(xwa+7), 0
	ld	(xwa+8), 100
	jr	SeAmpEnv1_OnColumn6_Join13
SeAmpEnv1_OnColumn6_Skip59:
	lda	xbc, (xsp+14)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	bitm	5, (xsp+14)
	jr	z, SeAmpEnv1_OnColumn6_Epilogue42
	ldib_erp	251, 6
	lda	xwa, (xsp+2)
	ld	(xwa+6), 127
	ld	(xwa+7), 0
	ld	(xwa+8), 100
SeAmpEnv1_OnColumn6_Join13:
	ld	(xwa+9), 0
	ldto_berp	a, 251
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	ld	a, (xsp+20)
	extz	wa
	lda	xbc, (xsp+12)
	call	SeMenu_SwitchToValueStep
	cp	(xsp+16), 0
	jr	nz, SeAmpEnv1_OnColumn6_Skip16
	ld	a, 44:opc
	jr	SeAmpEnv1_OnColumn6_Join14
SeAmpEnv1_OnColumn6_Skip16:
	ld	a, (xsp+18)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+13)
	ld	(xsp+18), 0
SeAmpEnv1_OnColumn6_Join14:
	ldto_berp	c, 251
	extz	bc
	ld	e, (xsp+18)
	extz	de
	extz	wa
	pushw	wa
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 45
	call	SeMenu_StepParamFieldAndSend
	call	UpdSeSel_DetailedUpdate_Helper4
	ld	wa, 6:i3
	call	SeMenu_BindDialToColumn
SeAmpEnv1_OnColumn6_Epilogue42:
	pop	qiz
	lda	xsp, (xsp+20)
	ret
SeAmpEnv1_OnColumn7:
	lda	xsp, (xsp-18)
	ld	(xsp+16), a
	lda	xwa, (xsp+12)
	call	SeMenu_LoadObjEntries
	cp	(xsp+12), 1
	jr	z, SeAmpEnv1_OnColumn7_Epilogue43
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
	call	SeMenu_SwitchToValueStep
	ld	e, (xsp+14)
	extz	de
	pushw	45
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 45
	ld	bc, 6:i3
	call	SeMenu_StepParamFieldAndSend
	call	UpdSeSel_DetailedUpdate_Helper4
	ld	wa, 7:i3
	call	SeMenu_BindDialToColumn
SeAmpEnv1_OnColumn7_Epilogue43:
	lda	xsp, (xsp+18)
	ret
SeAmpEnv1_OnColumn8:
	lda	xsp, (xsp-18)
	ld	(xsp+16), a
	lda	xwa, (xsp+12)
	call	SeMenu_LoadObjEntries
	cp	(xsp+12), 0
	jr	z, SeAmpEnv1_OnColumn8_Epilogue44
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
	call	SeMenu_SwitchToValueStep
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
	call	SeMenu_StepParamFieldAndSend
	ldw	wa, 8
	call	SeMenu_BindDialToColumn
SeAmpEnv1_OnColumn8_Epilogue44:
	lda	xsp, (xsp+18)
	ret
SeAmpEnv1_OnSideRow1:
	cp	a, 0:i3
	ret	z
	call	SeMenu_ToggleSolo
	ret
SeAmpEnv1_OnSideRow2:
	cp	a, 0:i3
	jr	nz, SeAmpEnv1_OnSideRow2_Skip17
	ldw	wa, 43
	ld	bc, 0:i3
	jr	SeAmpEnv1_OnSideRow2_Join15
SeAmpEnv1_OnSideRow2_Skip17:
	ld	wa, 1:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	ret	z
	ldw	wa, 45
	ld	bc, 1:i3
SeAmpEnv1_OnSideRow2_Join15:
	call	SeMenu_SendEvent
	ret
SeAmpEnv1_OnSideRow3:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 0
	jr	nz, SeAmpEnv1_OnSideRow3_Skip18
	cp	(xsp), 0
	jr	nz, SeAmpEnv1_OnSideRow3_Epilogue11
	ldw	wa, 47
	ld	bc, 0:i3
	jr	SeAmpEnv1_OnSideRow3_Join16
SeAmpEnv1_OnSideRow3_Skip18:
	ld	wa, 2:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	jr	z, SeAmpEnv1_OnSideRow3_Epilogue11
	ldw	wa, 45
	ld	bc, 1:i3
SeAmpEnv1_OnSideRow3_Join16:
	call	SeMenu_SendEvent
SeAmpEnv1_OnSideRow3_Epilogue11:
	inc	4, xsp
	ret
SeAmpEnv1_OnSideRow4:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, SeAmpEnv1_OnSideRow4_Epilogue45
	cp	(xsp+2), 0
	jr	z, SeAmpEnv1_OnSideRow4_Epilogue45
	ld	wa, 3:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	jr	z, SeAmpEnv1_OnSideRow4_Epilogue45
	ldw	wa, 45
	ld	bc, 1:i3
	call	SeMenu_SendEvent
SeAmpEnv1_OnSideRow4_Epilogue45:
	inc	4, xsp
	ret
SeAmpEnv1_OnSideRow5:
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp+2)
	call	SeMenu_LoadObjEntries
	cp	(xsp+4), 0
	jr	z, SeAmpEnv1_OnSideRow5_Epilogue13
	cp	(xsp+2), 0
	jr	nz, SeAmpEnv1_OnSideRow5_Skip19
	ld	wa, 4:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	jr	z, SeAmpEnv1_OnSideRow5_Epilogue13
	ldw	wa, 45
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	jr	SeAmpEnv1_OnSideRow5_Epilogue13
SeAmpEnv1_OnSideRow5_Skip19:
	lda	xbc, (xsp)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	bitm	5, (xsp)
	jr	z, SeAmpEnv1_OnSideRow5_Skip60
	resm	5, (xsp)
	jr	SeAmpEnv1_OnSideRow5_Join17
SeAmpEnv1_OnSideRow5_Skip60:
	setm	5, (xsp)
SeAmpEnv1_OnSideRow5_Join17:
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
SeAmpEnv1_OnSideRow5_Epilogue13:
	inc	6, xsp
	ret
SeAmpEnv1_OnSwitch25:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, SeAmpEnv1_OnSwitch25_Epilogue14
	cp	(xsp+2), 0
	jr	nz, SeAmpEnv1_OnSwitch25_Epilogue14
	ldw	wa, 46
	ld	bc, 0:i3
	call	SeMenu_SendEvent
SeAmpEnv1_OnSwitch25_Epilogue14:
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
	jr	nz, SeAmpEnv1_OnSwitch15_Epilogue9
	cp	(xsp), 0
	jr	nz, SeAmpEnv1_OnSwitch15_Skip20
	ldw	wa, 32
	ld	bc, 0:i3
	jr	SeAmpEnv1_OnSwitch15_Join18
SeAmpEnv1_OnSwitch15_Skip20:
	ldw	wa, 61
	ld	bc, 0:i3
SeAmpEnv1_OnSwitch15_Join18:
	call	SeMenu_SendEvent
SeAmpEnv1_OnSwitch15_Epilogue9:
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
	call	SeMenu_SwitchToValueStep
	ld	e, (xsp+14)
	extz	de
	pushw	51
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 46
	ld	bc, 5:i3
	call	SeMenu_StepParamFieldAndSend
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
	jr	z, SeAmpEnv2_OnColumn1_Skip61
	ldw	wa, 9
	ld	bc, 0:i3
	call	SeMenu_StorePartParam
	pushw	9
	pushw	46
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
SeAmpEnv2_OnColumn1_Skip61:
	ld	wa, 1:i3
	call	SeMenu_BindDialToColumn
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
	call	SeMenu_SwitchToValueStep
	ld	e, (xsp+14)
	extz	de
	pushw	52
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 46
	ld	bc, 6:i3
	call	SeMenu_StepParamFieldAndSend
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
	jr	z, SeAmpEnv2_OnColumn2_Skip62
	ldw	wa, 9
	ld	bc, 1:i3
	call	SeMenu_StorePartParam
	pushw	9
	pushw	46
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
SeAmpEnv2_OnColumn2_Skip62:
	ld	wa, 2:i3
	call	SeMenu_BindDialToColumn
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
	call	SeMenu_SwitchToValueStep
	ld	e, (xsp+14)
	extz	de
	pushw	53
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 46
	ld	bc, 7:i3
	call	SeMenu_StepParamFieldAndSend
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
	jr	z, SeAmpEnv2_OnColumn3_Skip63
	ldw	wa, 9
	ld	bc, 2:i3
	call	SeMenu_StorePartParam
	pushw	9
	pushw	46
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
SeAmpEnv2_OnColumn3_Skip63:
	ld	wa, 3:i3
	call	SeMenu_BindDialToColumn
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
	call	SeMenu_StepNoteParamInRange
	cp	l, 1:i3
	jr	nz, SeAmpEnv2_OnColumn4_Skip21
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
SeAmpEnv2_OnColumn4_Skip21:
	ld	wa, 4:i3
	call	SeMenu_BindDialToColumn
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
	call	SeMenu_StepNoteParamInRange
	cp	l, 1:i3
	jr	nz, SeAmpEnv2_OnColumn5_Skip22
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
SeAmpEnv2_OnColumn5_Skip22:
	ld	wa, 5:i3
	call	SeMenu_BindDialToColumn
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
	call	SeMenu_StepNoteParamInRange
	cp	l, 1:i3
	jr	nz, SeAmpEnv2_OnColumn6_Skip23
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
SeAmpEnv2_OnColumn6_Skip23:
	ld	wa, 6:i3
	call	SeMenu_BindDialToColumn
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
	call	SeMenu_SwitchToValueStep
	ld	e, (xsp+12)
	extz	de
	pushw	46
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 46
	ld	bc, 0:i3
	call	SeMenu_StepParamFieldAndSend
	ld	wa, 7:i3
	call	SeMenu_BindDialToColumn
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
	call	SeMenu_SwitchToValueStep
	ld	e, (xsp+12)
	extz	de
	pushw	47
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 46
	ld	bc, 1:i3
	call	SeMenu_StepParamFieldAndSend
	ldw	wa, 8
	call	SeMenu_BindDialToColumn
	lda	xsp, (xsp+16)
	ret
SeAmpEnv2_OnSideRow1:
	cp	a, 0:i3
	ret	z
	call	SeMenu_ToggleSolo
	ret
SeAmpEnv2_OnSideRow2:
	cp	a, 0:i3
	jr	nz, SeAmpEnv2_OnSideRow2_Skip24
	ldw	wa, 43
	ld	bc, 0:i3
	jr	SeAmpEnv2_OnSideRow2_Join19
SeAmpEnv2_OnSideRow2_Skip24:
	ld	wa, 1:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	ret	z
	ldw	wa, 46
	ld	bc, 1:i3
SeAmpEnv2_OnSideRow2_Join19:
	call	SeMenu_SendEvent
	ret
SeAmpEnv2_OnSideRow3:
	cp	a, 0:i3
	jr	nz, SeAmpEnv2_OnSideRow3_Skip25
	ldw	wa, 47
	ld	bc, 0:i3
	jr	SeAmpEnv2_OnSideRow3_Join20
SeAmpEnv2_OnSideRow3_Skip25:
	ld	wa, 2:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	ret	z
	ldw	wa, 46
	ld	bc, 1:i3
SeAmpEnv2_OnSideRow3_Join20:
	call	SeMenu_SendEvent
	ret
SeAmpEnv2_OnSideRow4:
	cp	a, 0:i3
	ret	z
	ld	wa, 3:i3
	call	SeMenu_SelectPartIfEnabled
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
	call	SeMenu_SelectPartIfEnabled
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
	jp	SeLfo1_StepSelectorAndReload
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
	jp	nz, (SeMenu_ToggleSolo:24)
	ldw	wa, 45
	ld	bc, 0:i3
	jp	SeMenu_SendEvent
SeAmpLfo1_OnSideRow2:
	cp	a, 0:i3
	jr	nz, SeAmpLfo1_OnSideRow2_Skip26
	ldw	wa, 43
	ld	bc, 0:i3
	jp	SeMenu_SendEvent
SeAmpLfo1_OnSideRow2_Skip26:
	ld	wa, 0:i3
	ld	bc, 1:i3
	jp	SeMenu_CyclePartLfoState
SeAmpLfo1_OnSideRow3:
	cp	a, 0:i3
	ret	z
	ld	wa, 0:i3
	ld	bc, 2:i3
	call	SeMenu_CyclePartLfoState
	ret
SeAmpLfo1_OnSideRow4:
	cp	a, 0:i3
	ret	z
	ld	wa, 0:i3
	ld	bc, 3:i3
	call	SeMenu_CyclePartLfoState
	ret
SeAmpLfo1_OnSideRow5:
	cp	a, 0:i3
	ret	z
	ld	wa, 0:i3
	ld	bc, 4:i3
	call	SeMenu_CyclePartLfoState
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
SeFilLpq1TitleFunc_DispatchSwitch_Epilogue10:
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
SeFilHpq1TitleFunc_DispatchSwitch_Epilogue11:
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
SeFilL241TitleFunc_DispatchSwitch_Epilogue12:
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
SeFilH241TitleFunc_DispatchSwitch_Epilogue13:
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
SeFilBpf1TitleFunc_DispatchSwitch_Epilogue14:
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
SeFilBcf1TitleFunc_DispatchSwitch_Epilogue15:
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
SeFilFil2TitleFunc_DispatchSwitch_Epilogue16:
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
SeFilEnv1TitleFunc_DispatchSwitch_Epilogue17:
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
SeFilEnv2TitleFunc_DispatchSwitch_Epilogue18:
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
SeFilLfo1TitleFunc_DispatchSwitch_Epilogue19:
	inc 4,XSP
	ret
SeFilLpq1_OnColumn1:
	extz	wa
	ld	bc, 1:i3
	ldw	de, 48
	calr	SeMenu_EditFilterCutoff
	ld	wa, 0:i3
	ld	bc, 0:i3
	jp	UpdSeSel_DetailedUpdate_Helper5
SeMenu_EditFilterCutoff:
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
	call SeMenu_SwitchToValueStep
	cp (XSP+0x0c),0x00
	jr nz, .Lc_f0505c
	ld C, 0x4d:opc
	jr t, .Lc_f05075
.Lc_f0505c:
SeMenu_EditFilterCutoff_Skip:
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
SeMenu_EditFilterCutoff_Join:
	ld A,(XSP+0x10)
	extz WA
	ld E,(XSP+0x0e)
	extz DE
	extz BC
	pushw bc
	lda xbc, (xsp + 0x02)
	push XBC
	ld bc, 2:i3
	call SeMenu_StepParamFieldAndSend
	ld A,(XSP+0x12)
	extz WA
	call SeMenu_BindDialToColumn
	lda xsp, (xsp + 0x16)
	ret
SeFilLpq1_OnColumn2:
	extz	wa
	ld	bc, 2:i3
	ldw	de, 48
	calr	SeMenu_EditFilterResonance
	ld	wa, 0:i3
	ld	bc, 0:i3
	jp	UpdSeSel_DetailedUpdate_Helper5
SeMenu_EditFilterResonance:
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
	call SeMenu_SwitchToValueStep
	cp (XSP+0x0c),0x00
	jr nz, .Lc_f050f5
	ld C, 0x4e:opc
	jr t, .Lc_f0510e
.Lc_f050f5:
SeMenu_EditFilterResonance_Skip:
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
SeMenu_EditFilterResonance_Join:
	ld A,(XSP+0x10)
	extz WA
	ld E,(XSP+0x0e)
	extz DE
	extz BC
	pushw bc
	lda xbc, (xsp + 0x02)
	push XBC
	ld bc, 3:i3
	call SeMenu_StepParamFieldAndSend
	ld A,(XSP+0x12)
	extz WA
	call SeMenu_BindDialToColumn
	lda xsp, (xsp + 0x16)
	ret
SeFilLpq1_OnColumn3:
	extz	wa
	ld	bc, 3:i3
	ldw	de, 48
	jr	SeFilLpq1_OnColumn3_Join21
SeFilLpq1_OnColumn3_Join21:
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
	call SeMenu_SwitchToValueStep
	cp (XSP+0x0c),0x00
	jr nz, .Lc_f05185
	ld C, 0x37:opc
	jr t, .Lc_f0519e
.Lc_f05185:
SeFilLpq1_OnColumn3_Skip2:
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
SeFilLpq1_OnColumn3_Join2:
	ld A,(XSP+0x10)
	extz WA
	ld E,(XSP+0x0e)
	extz DE
	extz BC
	pushw bc
	lda xbc, (xsp + 0x02)
	push XBC
	ld bc, 1:i3
	call SeMenu_StepParamFieldAndSend
	ld A,(XSP+0x12)
	extz WA
	call SeMenu_BindDialToColumn
	lda xsp, (xsp + 0x16)
	ret
SeFilLpq1_OnColumn4:
	extz	wa
	ld	bc, 4:i3
	ldw	de, 48
	jr	SeFilLpq1_OnColumn4_Join22
SeFilLpq1_OnColumn4_Join22:
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
	call SeMenu_SwitchToValueStep
	cp (XSP+0x0c),0x00
	jr nz, .Lc_f05215
	ld C, 0x36:opc
	jr t, .Lc_f0522e
.Lc_f05215:
SeFilLpq1_OnColumn4_Skip3:
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
SeFilLpq1_OnColumn4_Join3:
	ld A,(XSP+0x10)
	extz WA
	ld E,(XSP+0x0e)
	extz DE
	extz BC
	pushw bc
	lda xbc, (xsp + 0x02)
	push XBC
	ld bc, 0:i3
	call SeMenu_StepParamFieldAndSend
	ld A,(XSP+0x12)
	extz WA
	call SeMenu_BindDialToColumn
	lda xsp, (xsp + 0x16)
	ret
SeFilLpq1_OnColumn4_Join23:
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
SeFilLpq1_OnColumn4_Skip4:
	ld (XWA),0xff
.Lc_f05295:
SeFilLpq1_OnColumn4_Join4:
	cp (XSP+0x0c),0x00
	jr nz, .Lc_f0529f
	ld A, 0x50:opc
	jr t, .Lc_f052b6
.Lc_f0529f:
SeFilLpq1_OnColumn4_Skip5:
	ld A,(XSP+0x0e)
	dec 1,A
	extz WA
	muls WA,0x0015
	extz XWA
	lda xwa, (xwa + 0x10)
	lda xwa, (xwa + 0x14)
	ld (XSP+0x0e),0x00
.Lc_f052b6:
SeFilLpq1_OnColumn4_Join5:
	ld E,(XSP+0x0e)
	extz DE
	extz WA
	pushw wa
	push XBC
	ldw WA, 0x0030
	ld bc, 5:i3
	call SeMenu_StepParamFieldAndSend
	cp l, 1:i3
	call z, (UpdSeSel_DetailedUpdate_Helper6:24)
	ld wa, 6:i3
	call SeMenu_BindDialToColumn
	lda xsp, (xsp + 0x12)
	ret
SeFilLpq1_OnColumn4_Join24:
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
	call SeMenu_SwitchToValueStep
	cp (XSP+0x0c),0x00
	jr nz, .Lc_f0531d
	ld A, 0x4f:opc
	jr t, .Lc_f05334
.Lc_f0531d:
SeFilLpq1_OnColumn4_Skip6:
	ld A,(XSP+0x0e)
	dec 1,A
	extz WA
	muls WA,0x0015
	extz XWA
	lda xwa, (xwa + 0x10)
	lda xwa, (xwa + 0x13)
	ld (XSP+0x0e),0x00
.Lc_f05334:
SeFilLpq1_OnColumn4_Join6:
	ld E,(XSP+0x0e)
	extz DE
	extz WA
	pushw wa
	lda xwa, (xsp + 0x02)
	push XWA
	ldw WA, 0x0030
	ld bc, 4:i3
	call SeMenu_StepParamFieldAndSend
	cp l, 1:i3
	call z, (UpdSeSel_DetailedUpdate_Helper6:24)
	ld wa, 7:i3
	call SeMenu_BindDialToColumn
	lda xsp, (xsp + 0x12)
	ret
SeFilLpq1_OnColumn4_Join25:
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
	call SeMenu_SwitchToValueStep
	cp (XSP+0x0c),0x00
	jr nz, .Lc_f0539e
	ld A, 0x50:opc
	jr t, .Lc_f053b5
.Lc_f0539e:
SeFilLpq1_OnColumn4_Skip7:
	ld A,(XSP+0x0e)
	dec 1,A
	extz WA
	muls WA,0x0015
	extz XWA
	lda xwa, (xwa + 0x10)
	lda xwa, (xwa + 0x14)
	ld (XSP+0x0e),0x00
.Lc_f053b5:
SeFilLpq1_OnColumn4_Join7:
	ld E,(XSP+0x0e)
	extz DE
	extz WA
	pushw wa
	lda xwa, (xsp + 0x02)
	push XWA
	ldw WA, 0x0030
	ld bc, 5:i3
	call SeMenu_StepParamFieldAndSend
	cp l, 1:i3
	call z, (UpdSeSel_DetailedUpdate_Helper6:24)
	ldw WA, 0x0008
	call SeMenu_BindDialToColumn
	lda xsp, (xsp + 0x12)
	ret
SeFilLpq1_OnColumn4_Join26:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 0
	jr	nz, SeFilLpq1_OnColumn4_Skip27
	cp	(xsp), 0
	jr nz, .Lc_f05401
	ldw WA, 0x0037
	ld bc, 0:i3
	call SeMenu_SendEvent
	jr t, .Lc_f05401
SeFilLpq1_OnColumn4_Skip27:
	call SeMenu_ToggleSolo
.Lc_f05401:
	inc 4,XSP
	ret
SeFilLpq1_OnColumn4_Join27:
	cp	a, 0:i3
	ret	z
	ld	wa, 1:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	ret	z
	ldw	wa, 48
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
SeFilLpq1_OnColumn4_Join28:
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
SeFilLpq1_OnColumn4_Skip28:
	ld wa, 2:i3
	call SeMenu_SelectPartIfEnabled
	cp l, 0:i3
	jr z, .Lc_f0544c
	ldw WA, 0x0030
	ld bc, 0:i3
.Lc_f05448:
SeFilLpq1_OnColumn4_Join29:
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
	jr	nz, SeFilLpq1_OnSideRow4_Skip8
	lda	xbc, (xsp+2)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	andmi8	(xsp+2), 248
	setm	1, (xsp+2)
	ld	a, (xsp+2)
	extz	wa
	call	SeMenu_SetFilterType
	ldw	wa, 48
	ld	bc, 0:i3
	jr	SeFilLpq1_OnSideRow4_Join8
SeFilLpq1_OnSideRow4_Skip8:
	cp	(xsp), 1
	jr	z, SeFilLpq1_OnSideRow4_Epilogue16
	ld	wa, 3:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	jr	z, SeFilLpq1_OnSideRow4_Epilogue16
	ldw	wa, 48
	ld	bc, 0:i3
SeFilLpq1_OnSideRow4_Join8:
	call	SeMenu_SendEvent
SeFilLpq1_OnSideRow4_Epilogue16:
	inc	6, xsp
	ret
SeFilLpq1_OnSideRow4_Join30:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 0
	jr	z, SeFilLpq1_OnSideRow4_Epilogue17
	cp	(xsp), 1
	jr	z, SeFilLpq1_OnSideRow4_Epilogue17
	ld	wa, 4:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	jr	z, SeFilLpq1_OnSideRow4_Epilogue17
	ldw	wa, 48
	ld	bc, 0:i3
	call	SeMenu_SendEvent
SeFilLpq1_OnSideRow4_Epilogue17:
	inc	4, xsp
	ret
SeFilLpq1_OnSwitch25:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, SeFilLpq1_OnSwitch25_Epilogue18
	cp	(xsp+2), 0
	jr	nz, SeFilLpq1_OnSwitch25_Epilogue18
	ldw	wa, 54
	ld	bc, 0:i3
	call	SeMenu_SendEvent
SeFilLpq1_OnSwitch25_Epilogue18:
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
	jr	nz, SeFilLpq1_OnSwitch15_Epilogue22
	cp (XSP),0x00
	jr nz, .Lc_f0550c
	ldw WA, 0x0020
	ld bc, 0:i3
	jr t, .Lc_f05511
.Lc_f0550c:
SeFilLpq1_OnSwitch15_Skip29:
	ldw WA, 0x003d
	ld bc, 0:i3
.Lc_f05511:
SeFilLpq1_OnSwitch15_Join31:
	call SeMenu_SendEvent
SeFilLpq1_OnSwitch15_Epilogue22:
	inc 4,XSP
	ret
SeFilHpq1_OnColumn1:
	extz	wa
	ld	bc, 1:i3
	ldw	de, 49
	calr	SeMenu_EditFilterCutoff
	ld	wa, 1:i3
	ld	bc, 0:i3
	jp	UpdSeSel_DetailedUpdate_Helper5
SeFilHpq1_OnColumn2:
	extz	wa
	ld	bc, 2:i3
	ldw	de, 49
	calr	SeMenu_EditFilterResonance
	ld	wa, 1:i3
	ld	bc, 0:i3
	jp	UpdSeSel_DetailedUpdate_Helper5
SeFilHpq1_OnColumn3:
	extz	wa
	ld	bc, 3:i3
	ldw	de, 49
	jrl	SeFilLpq1_OnColumn3_Join21
SeFilHpq1_OnColumn4:
	extz	wa
	ld	bc, 4:i3
	ldw	de, 49
	jrl	SeFilLpq1_OnColumn4_Join22
SeFilHpq1_OnColumn6:
	extz	wa
	jrl	SeFilLpq1_OnColumn4_Join23
SeFilHpq1_OnColumn7:
	extz	wa
	jrl	SeFilLpq1_OnColumn4_Join24
SeFilHpq1_OnColumn8:
	extz	wa
	jrl	SeFilLpq1_OnColumn4_Join25
SeFilHpq1_OnSideRow1:
	extz	wa
	jrl	SeFilLpq1_OnColumn4_Join26
SeFilHpq1_OnSideRow2:
	extz	wa
	jrl	SeFilLpq1_OnColumn4_Join27
SeFilHpq1_OnSideRow3:
	extz	wa
	jrl	SeFilLpq1_OnColumn4_Join28
SeFilHpq1_OnSideRow4:
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+4), 0
	jr	nz, SeFilHpq1_OnSideRow4_Skip9
	lda	xbc, (xsp+2)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	andmi8	(xsp+2), 248
	ormi8	(xsp+2), 3
	ld	a, (xsp+2)
	extz	wa
	call	SeMenu_SetFilterType
	ldw	wa, 48
	ld	bc, 0:i3
	jr	SeFilHpq1_OnSideRow4_Join9
SeFilHpq1_OnSideRow4_Skip9:
	cp	(xsp), 0
	jr	nz, SeFilHpq1_OnSideRow4_Epilogue23
	ld	wa, 3:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	jr	z, SeFilHpq1_OnSideRow4_Epilogue23
	ldw	wa, 48
	ld	bc, 0:i3
SeFilHpq1_OnSideRow4_Join9:
	call	SeMenu_SendEvent
SeFilHpq1_OnSideRow4_Epilogue23:
	inc	6, xsp
	ret
SeFilHpq1_OnSideRow5:
	extz	wa
	jrl	SeFilLpq1_OnSideRow4_Join30
SeFilHpq1_OnSwitch25:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 0
	jr	nz, SeFilHpq1_OnSwitch25_Epilogue21
	cp	(xsp), 0
	jr	nz, SeFilHpq1_OnSwitch25_Epilogue21
	ldw	wa, 54
	ld	bc, 0:i3
	call	SeMenu_SendEvent
SeFilHpq1_OnSwitch25_Epilogue21:
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
	jr	nz, SeFilHpq1_OnSwitch15_Epilogue25
	cp	(xsp), 0
	jr	nz, SeFilHpq1_OnSwitch15_Skip30
	ldw	wa, 32
	ld	bc, 0:i3
	jr	SeFilHpq1_OnSwitch15_Join32
SeFilHpq1_OnSwitch15_Skip30:
	ldw	wa, 61
	ld	bc, 0:i3
SeFilHpq1_OnSwitch15_Join32:
	call	SeMenu_SendEvent
SeFilHpq1_OnSwitch15_Epilogue25:
	inc	4, xsp
	ret
SeFilL241_OnColumn3:
	extz	wa
	ld	bc, 3:i3
	ldw	de, 50
	calr	SeMenu_EditFilterCutoff
	ld	wa, 0:i3
	ld	bc, 1:i3
	jp	UpdSeSel_DetailedUpdate_Helper5
SeFilL241_OnColumn4:
	extz	wa
	ld	bc, 4:i3
	ldw	de, 50
	calr	SeMenu_EditFilterResonance
	ld	wa, 0:i3
	ld	bc, 1:i3
	jp	UpdSeSel_DetailedUpdate_Helper5
SeFilL241_OnColumn5:
	extz	wa
	ld	bc, 5:i3
	ldw	de, 50
	jrl	SeFilLpq1_OnColumn3_Join21
SeFilL241_OnColumn6:
	extz	wa
	ld	bc, 6:i3
	ldw	de, 50
	jrl	SeFilLpq1_OnColumn4_Join22
SeFilL241_OnColumn6_Join33:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 0
	jr	nz, SeFilL241_OnColumn6_Skip31
	cp	(xsp), 0
	jr	nz, SeFilL241_OnColumn6_Epilogue23
	ldw	wa, 55
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	jr	SeFilL241_OnColumn6_Epilogue23
SeFilL241_OnColumn6_Skip31:
	call	SeMenu_ToggleSolo
SeFilL241_OnColumn6_Epilogue23:
	inc	4, xsp
	ret
SeFilL241_OnColumn6_Join34:
	cp	a, 0:i3
	ret	z
	ld	wa, 1:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	ret	z
	ldw	wa, 48
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
SeFilL241_OnColumn6_Join35:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 0
	jr	nz, SeFilL241_OnColumn6_Skip32
	cp	(xsp), 0
	jr	nz, SeFilL241_OnColumn6_Epilogue24
	ldw	wa, 57
	ld	bc, 0:i3
	jr	SeFilL241_OnColumn6_Join36
SeFilL241_OnColumn6_Skip32:
	ld	wa, 2:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	jr	z, SeFilL241_OnColumn6_Epilogue24
	ldw	wa, 48
	ld	bc, 0:i3
SeFilL241_OnColumn6_Join36:
	call	SeMenu_SendEvent
SeFilL241_OnColumn6_Epilogue24:
	inc	4, xsp
	ret
SeFilL241_OnSideRow4:
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+4), 0
	jr	nz, SeFilL241_OnSideRow4_Skip10
	lda	xbc, (xsp+2)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	andmi8	(xsp+2), 248
	setm	2, (xsp+2)
	ld	a, (xsp+2)
	extz	wa
	call	SeMenu_SetFilterType
	ldw	wa, 48
	ld	bc, 0:i3
	jr	SeFilL241_OnSideRow4_Join10
SeFilL241_OnSideRow4_Skip10:
	cp	(xsp), 1
	jr	z, SeFilL241_OnSideRow4_Epilogue25
	ld	wa, 3:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	jr	z, SeFilL241_OnSideRow4_Epilogue25
	ldw	wa, 48
	ld	bc, 0:i3
SeFilL241_OnSideRow4_Join10:
	call	SeMenu_SendEvent
SeFilL241_OnSideRow4_Epilogue25:
	inc	6, xsp
	ret
SeFilL241_OnSideRow4_Join11:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, SeFilL241_OnSideRow4_Epilogue26
	cp	(xsp+2), 0
	jr	z, SeFilL241_OnSideRow4_Epilogue26
	ld	wa, 4:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	jr	z, SeFilL241_OnSideRow4_Epilogue26
	ldw	wa, 48
	ld	bc, 0:i3
	call	SeMenu_SendEvent
SeFilL241_OnSideRow4_Epilogue26:
	inc	4, xsp
	ret
SeFilL241_OnSwitch25:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, SeFilL241_OnSwitch25_Epilogue27
	cp	(xsp+2), 0
	jr	nz, SeFilL241_OnSwitch25_Epilogue27
	ldw	wa, 54
	ld	bc, 0:i3
	call	SeMenu_SendEvent
SeFilL241_OnSwitch25_Epilogue27:
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
	jr	nz, SeFilL241_OnSwitch15_Epilogue28
	cp	(xsp), 0
	jr	nz, SeFilL241_OnSwitch15_Skip33
	ldw	wa, 32
	ld	bc, 0:i3
	jr	SeFilL241_OnSwitch15_Join37
SeFilL241_OnSwitch15_Skip33:
	ldw	wa, 61
	ld	bc, 0:i3
SeFilL241_OnSwitch15_Join37:
	call	SeMenu_SendEvent
SeFilL241_OnSwitch15_Epilogue28:
	inc	4, xsp
	ret
SeFilH241_OnColumn3:
	extz	wa
	ld	bc, 3:i3
	ldw	de, 51
	calr	SeMenu_EditFilterCutoff
	ld	wa, 1:i3
	ld	bc, 1:i3
	jp	UpdSeSel_DetailedUpdate_Helper5
SeFilH241_OnColumn4:
	extz	wa
	ld	bc, 4:i3
	ldw	de, 51
	calr	SeMenu_EditFilterResonance
	ld	wa, 1:i3
	ld	bc, 1:i3
	jp	UpdSeSel_DetailedUpdate_Helper5
SeFilH241_OnColumn5:
	extz	wa
	ld	bc, 5:i3
	ldw	de, 51
	jrl	SeFilLpq1_OnColumn3_Join21
SeFilH241_OnColumn6:
	extz	wa
	ld	bc, 6:i3
	ldw	de, 51
	jrl	SeFilLpq1_OnColumn4_Join22
SeFilH241_OnSideRow1:
	extz	wa
	jrl	SeFilL241_OnColumn6_Join33
SeFilH241_OnSideRow2:
	extz	wa
	jrl	SeFilL241_OnColumn6_Join34
SeFilH241_OnSideRow3:
	extz	wa
	jrl	SeFilL241_OnColumn6_Join35
SeFilH241_OnSideRow4:
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+4), 0
	jr	nz, SeFilH241_OnSideRow4_Skip11
	lda	xbc, (xsp+2)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	andmi8	(xsp+2), 248
	ormi8	(xsp+2), 5
	ld	a, (xsp+2)
	extz	wa
	call	SeMenu_SetFilterType
	ldw	wa, 48
	ld	bc, 0:i3
	jr	SeFilH241_OnSideRow4_Join12
SeFilH241_OnSideRow4_Skip11:
	cp	(xsp), 1
	jr	z, SeFilH241_OnSideRow4_Epilogue7
	ld	wa, 3:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	jr	z, SeFilH241_OnSideRow4_Epilogue7
	ldw	wa, 48
	ld	bc, 0:i3
SeFilH241_OnSideRow4_Join12:
	call	SeMenu_SendEvent
SeFilH241_OnSideRow4_Epilogue7:
	inc	6, xsp
	ret
SeFilH241_OnSideRow5:
	extz	wa
	jrl	SeFilL241_OnSideRow4_Join11
SeFilH241_OnSwitch25:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, SeFilH241_OnSwitch25_Epilogue30
	cp	(xsp+2), 0
	jr	nz, SeFilH241_OnSwitch25_Epilogue30
	ldw	wa, 54
	ld	bc, 0:i3
	call	SeMenu_SendEvent
SeFilH241_OnSwitch25_Epilogue30:
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
	jr	nz, SeFilH241_OnSwitch15_Epilogue29
	cp	(xsp), 0
	jr	nz, SeFilH241_OnSwitch15_Skip34
	ldw	wa, 32
	ld	bc, 0:i3
	jr	SeFilH241_OnSwitch15_Join38
SeFilH241_OnSwitch15_Skip34:
	ldw	wa, 61
	ld	bc, 0:i3
SeFilH241_OnSwitch15_Join38:
	call	SeMenu_SendEvent
SeFilH241_OnSwitch15_Epilogue29:
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
	call	SeMenu_SwitchToValueStep
	cp	(xsp+12), 0
	jr	nz, SeFilBpf1_OnColumn2_Skip12
	ld	a, 77:opc
	jr	SeFilBpf1_OnColumn2_Join13
SeFilBpf1_OnColumn2_Skip12:
	ld	a, (xsp+16)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+17)
	ld	(xsp+16), 0
SeFilBpf1_OnColumn2_Join13:
	ld	e, (xsp+16)
	extz	de
	extz	wa
	pushw	wa
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 52
	ld	bc, 2:i3
	call	SeMenu_StepParamFieldAndSend
	call	Scoop_SoundEditorData_Helper7
	ld	wa, 2:i3
	call	SeMenu_BindDialToColumn
	lda	xsp, (xsp+20)
	ret
SeFilBpf1_OnColumn3:
	extz	wa
	ld	bc, 3:i3
	ldw	de, 52
	calr	SeMenu_EditFilterResonance
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
	call	SeMenu_SwitchToValueStep
	lda	xbc, (xsp)
	cp	(xsp+12), 0
	jr	nz, SeFilBpf1_OnColumn4_Skip13
	ld	e, (xsp+16)
	extz	de
	pushw	79
	push	xbc
	ldw	wa, 52
	ld	bc, 4:i3
	jr	SeFilBpf1_OnColumn4_Join43
SeFilBpf1_OnColumn4_Skip13:
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
SeFilBpf1_OnColumn4_Join43:
	call	SeMenu_StepParamFieldAndSend
	call	Scoop_SoundEditorData_Helper7
	ld	wa, 4:i3
	call	SeMenu_BindDialToColumn
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
	call	SeMenu_SwitchToValueStep
	lda	xbc, (xsp)
	cp	(xsp+12), 0
	jr	nz, SeFilBpf1_OnColumn5_Skip14
	ld	e, (xsp+14)
	extz	de
	pushw	80
	push	xbc
	ldw	wa, 52
	ld	bc, 5:i3
	jr	SeFilBpf1_OnColumn5_Join44
SeFilBpf1_OnColumn5_Skip14:
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
SeFilBpf1_OnColumn5_Join44:
	call	SeMenu_StepParamFieldAndSend
	call	Scoop_SoundEditorData_Helper7
	ld	wa, 5:i3
	call	SeMenu_BindDialToColumn
	lda	xsp, (xsp+18)
	ret
SeFilBpf1_OnColumn6:
	extz	wa
	ld	bc, 6:i3
	ldw	de, 52
	jrl	SeFilLpq1_OnColumn3_Join21
SeFilBpf1_OnColumn7:
	extz	wa
	ld	bc, 7:i3
	ldw	de, 52
	jrl	SeFilLpq1_OnColumn4_Join22
SeFilBpf1_OnSideRow1:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 0
	jr	nz, SeFilBpf1_OnSideRow1_Skip35
	cp	(xsp), 0
	jr	nz, SeFilBpf1_OnSideRow1_Epilogue32
	ldw	wa, 55
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	jr	SeFilBpf1_OnSideRow1_Epilogue32
SeFilBpf1_OnSideRow1_Skip35:
	call	SeMenu_ToggleSolo
SeFilBpf1_OnSideRow1_Epilogue32:
	inc	4, xsp
	ret
SeFilBpf1_OnSideRow2:
	cp	a, 0:i3
	ret	z
	ld	wa, 1:i3
	call	SeMenu_SelectPartIfEnabled
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
	jr	nz, SeFilBpf1_OnSideRow3_Skip36
	cp	(xsp), 0
	jr	nz, SeFilBpf1_OnSideRow3_Epilogue33
	ldw	wa, 57
	ld	bc, 0:i3
	jr	SeFilBpf1_OnSideRow3_Join39
SeFilBpf1_OnSideRow3_Skip36:
	ld	wa, 2:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	jr	z, SeFilBpf1_OnSideRow3_Epilogue33
	ldw	wa, 48
	ld	bc, 0:i3
SeFilBpf1_OnSideRow3_Join39:
	call	SeMenu_SendEvent
SeFilBpf1_OnSideRow3_Epilogue33:
	inc	4, xsp
	ret
SeFilBpf1_OnSideRow4:
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+4), 0
	jr	nz, SeFilBpf1_OnSideRow4_Skip15
	lda	xbc, (xsp+2)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	andmi8	(xsp+2), 248
	ld	a, (xsp+2)
	extz	wa
	call	SeMenu_SetFilterType
	ldw	wa, 48
	ld	bc, 0:i3
	jr	SeFilBpf1_OnSideRow4_Join16
SeFilBpf1_OnSideRow4_Skip15:
	cp	(xsp), 1
	jr	z, SeFilBpf1_OnSideRow4_Epilogue34
	ld	wa, 3:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	jr	z, SeFilBpf1_OnSideRow4_Epilogue34
	ldw	wa, 48
	ld	bc, 0:i3
SeFilBpf1_OnSideRow4_Join16:
	call	SeMenu_SendEvent
SeFilBpf1_OnSideRow4_Epilogue34:
	inc	6, xsp
	ret
SeFilBpf1_OnSideRow5:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, SeFilBpf1_OnSideRow5_Epilogue35
	cp	(xsp+2), 0
	jr	z, SeFilBpf1_OnSideRow5_Epilogue35
	ld	wa, 4:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	jr	z, SeFilBpf1_OnSideRow5_Epilogue35
	ldw	wa, 48
	ld	bc, 0:i3
	call	SeMenu_SendEvent
SeFilBpf1_OnSideRow5_Epilogue35:
	inc	4, xsp
	ret
SeFilBpf1_OnSwitch25:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, SeFilBpf1_OnSwitch25_Epilogue36
	cp	(xsp+2), 0
	jr	nz, SeFilBpf1_OnSwitch25_Epilogue36
	ldw	wa, 54
	ld	bc, 0:i3
	call	SeMenu_SendEvent
SeFilBpf1_OnSwitch25_Epilogue36:
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
	jr	nz, SeFilBpf1_OnSwitch15_Epilogue37
	cp	(xsp), 0
	jr	nz, SeFilBpf1_OnSwitch15_Skip37
	ldw	wa, 32
	ld	bc, 0:i3
	jr	SeFilBpf1_OnSwitch15_Join40
SeFilBpf1_OnSwitch15_Skip37:
	ldw	wa, 61
	ld	bc, 0:i3
SeFilBpf1_OnSwitch15_Join40:
	call	SeMenu_SendEvent
SeFilBpf1_OnSwitch15_Epilogue37:
	inc	4, xsp
	ret
SeFilBcf1_OnSideRow1:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 0
	jr	nz, SeFilBcf1_OnSideRow1_Skip38
	cp	(xsp), 0
	jr	nz, SeFilBcf1_OnSideRow1_Epilogue38
	ldw	wa, 55
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	jr	SeFilBcf1_OnSideRow1_Epilogue38
SeFilBcf1_OnSideRow1_Skip38:
	call	SeMenu_ToggleSolo
SeFilBcf1_OnSideRow1_Epilogue38:
	inc	4, xsp
	ret
SeFilBcf1_OnSideRow2:
	cp	a, 0:i3
	ret	z
	ld	wa, 1:i3
	call	SeMenu_SelectPartIfEnabled
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
	jr	nz, SeFilBcf1_OnSideRow3_Skip39
	cp	(xsp), 0
	jr	nz, SeFilBcf1_OnSideRow3_Epilogue39
	ldw	wa, 57
	ld	bc, 0:i3
	jr	SeFilBcf1_OnSideRow3_Join41
SeFilBcf1_OnSideRow3_Skip39:
	ld	wa, 2:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	jr	z, SeFilBcf1_OnSideRow3_Epilogue39
	ldw	wa, 48
	ld	bc, 0:i3
SeFilBcf1_OnSideRow3_Join41:
	call	SeMenu_SendEvent
SeFilBcf1_OnSideRow3_Epilogue39:
	inc	4, xsp
	ret
SeFilBcf1_OnSideRow4:
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+4), 0
	jr	nz, SeFilBcf1_OnSideRow4_Skip16
	lda	xbc, (xsp+2)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	andmi8	(xsp+2), 248
	setm	0, (xsp+2)
	ld	a, (xsp+2)
	extz	wa
	call	SeMenu_SetFilterType
	ldw	wa, 48
	ld	bc, 0:i3
	jr	SeFilBcf1_OnSideRow4_Join17
SeFilBcf1_OnSideRow4_Skip16:
	cp	(xsp), 1
	jr	z, SeFilBcf1_OnSideRow4_Epilogue40
	ld	wa, 3:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	jr	z, SeFilBcf1_OnSideRow4_Epilogue40
	ldw	wa, 48
	ld	bc, 0:i3
SeFilBcf1_OnSideRow4_Join17:
	call	SeMenu_SendEvent
SeFilBcf1_OnSideRow4_Epilogue40:
	inc	6, xsp
	ret
SeFilBcf1_OnSideRow5:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, SeFilBcf1_OnSideRow5_Epilogue41
	cp	(xsp+2), 0
	jr	z, SeFilBcf1_OnSideRow5_Epilogue41
	ld	wa, 4:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	jr	z, SeFilBcf1_OnSideRow5_Epilogue41
	ldw	wa, 48
	ld	bc, 0:i3
	call	SeMenu_SendEvent
SeFilBcf1_OnSideRow5_Epilogue41:
	inc	4, xsp
	ret
SeFilBcf1_OnSwitch25:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, SeFilBcf1_OnSwitch25_Epilogue42
	cp	(xsp+2), 0
	jr	nz, SeFilBcf1_OnSwitch25_Epilogue42
	ldw	wa, 54
	ld	bc, 0:i3
	call	SeMenu_SendEvent
SeFilBcf1_OnSwitch25_Epilogue42:
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
	jr	nz, SeFilBcf1_OnSwitch15_Epilogue35
	cp	(xsp), 0
	jr	nz, SeFilBcf1_OnSwitch15_Skip40
	ldw	wa, 32
	ld	bc, 0:i3
	jr	SeFilBcf1_OnSwitch15_Join42
SeFilBcf1_OnSwitch15_Skip40:
	ldw	wa, 61
	ld	bc, 0:i3
SeFilBcf1_OnSwitch15_Join42:
	call	SeMenu_SendEvent
SeFilBcf1_OnSwitch15_Epilogue35:
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
	call	SeMenu_SwitchToValueStep
	ld	e, (xsp+14)
	extz	de
	pushw	60
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 54
	ld	bc, 3:i3
	call	SeMenu_StepParamFieldAndSend
	cp	l, 1:i3
	jr	nz, SeFilFil2_OnColumn3_Skip41
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
SeFilFil2_OnColumn3_Skip41:
	ld	wa, 3:i3
	call	SeMenu_BindDialToColumn
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
	call	SeMenu_StepNoteParamInRange
	cp	l, 1:i3
	jr	nz, SeFilFil2_OnColumn4_Skip42
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
SeFilFil2_OnColumn4_Skip42:
	ld	wa, 4:i3
	call	SeMenu_BindDialToColumn
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
	call	SeMenu_StepNoteParamInRange
	cp	l, 1:i3
	jr	nz, SeFilFil2_OnColumn5_Skip43
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
SeFilFil2_OnColumn5_Skip43:
	ld	wa, 5:i3
	call	SeMenu_BindDialToColumn
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
	call	SeMenu_StepNoteParamInRange
	cp	l, 1:i3
	jr	nz, SeFilFil2_OnColumn6_Skip44
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
SeFilFil2_OnColumn6_Skip44:
	ld	wa, 6:i3
	call	SeMenu_BindDialToColumn
	inc	8, xsp
	ret
SeFilFil2_OnSideRow1:
	cp	a, 0:i3
	jp	nz, (SeMenu_ToggleSolo:24)
	ldw	wa, 55
	ld	bc, 0:i3
	jp	SeMenu_SendEvent
SeFilFil2_OnSideRow2:
	cp	a, 0:i3
	ret	z
	ld	wa, 1:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	ret	z
	ldw	wa, 54
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
SeFilFil2_OnSideRow3:
	cp	a, 0:i3
	jr	nz, SeFilFil2_OnSideRow3_Skip45
	ldw	wa, 57
	ld	bc, 0:i3
	jr	SeFilFil2_OnSideRow3_Join43
SeFilFil2_OnSideRow3_Skip45:
	ld	wa, 2:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	ret	z
	ldw	wa, 54
	ld	bc, 1:i3
SeFilFil2_OnSideRow3_Join43:
	call	SeMenu_SendEvent
	ret
SeFilFil2_OnSideRow4:
	cp	a, 0:i3
	ret	z
	ld	wa, 3:i3
	call	SeMenu_SelectPartIfEnabled
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
	call	SeMenu_SelectPartIfEnabled
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
	call	SeMenu_ToggleSolo
	ret
SeFilEnv1_OnSideRow2:
	cp	a, 0:i3
	jr	nz, SeFilEnv1_OnSideRow2_Skip46
	ldw	wa, 48
	ld	bc, 0:i3
	jr	SeFilEnv1_OnSideRow2_Join44
SeFilEnv1_OnSideRow2_Skip46:
	ld	wa, 1:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	ret	z
	ldw	wa, 55
	ld	bc, 1:i3
SeFilEnv1_OnSideRow2_Join44:
	call	SeMenu_SendEvent
	ret
SeFilEnv1_OnSideRow3:
	cp	a, 0:i3
	jr	nz, SeFilEnv1_OnSideRow3_Skip47
	ldw	wa, 57
	ld	bc, 0:i3
	jr	SeFilEnv1_OnSideRow3_Join45
SeFilEnv1_OnSideRow3_Skip47:
	ld	wa, 2:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	ret	z
	ldw	wa, 55
	ld	bc, 1:i3
SeFilEnv1_OnSideRow3_Join45:
	call	SeMenu_SendEvent
	ret
SeFilEnv1_OnSideRow4:
	cp	a, 0:i3
	jr	nz, SeFilEnv1_OnSideRow4_Skip48
	ld	wa, 0:i3
	jp	SeMenu_ApplyPartEdit_AltStore_Join7
SeFilEnv1_OnSideRow4_Skip48:
	ld	wa, 3:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	ret	z
	ldw	wa, 55
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
SeFilEnv1_OnSideRow5:
	cp	a, 0:i3
	jr	nz, SeFilEnv1_OnSideRow5_Skip49
	ld	wa, 1:i3
	jp	SeMenu_ApplyPartEdit_AltStore_Join7
SeFilEnv1_OnSideRow5_Skip49:
	ld	wa, 4:i3
	call	SeMenu_SelectPartIfEnabled
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
	call	SeMenu_ToggleSolo
	ret
SeFilEnv2_OnSideRow2:
	cp	a, 0:i3
	jr	nz, SeFilEnv2_OnSideRow2_Skip50
	ldw	wa, 48
	ld	bc, 0:i3
	jr	SeFilEnv2_OnSideRow2_Join46
SeFilEnv2_OnSideRow2_Skip50:
	ld	wa, 1:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	ret	z
	ldw	wa, 56
	ld	bc, 1:i3
SeFilEnv2_OnSideRow2_Join46:
	call	SeMenu_SendEvent
	ret
SeFilEnv2_OnSideRow3:
	cp	a, 0:i3
	jr	nz, SeFilEnv2_OnSideRow3_Skip51
	ldw	wa, 57
	ld	bc, 0:i3
	jr	SeFilEnv2_OnSideRow3_Join47
SeFilEnv2_OnSideRow3_Skip51:
	ld	wa, 2:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	ret	z
	ldw	wa, 56
	ld	bc, 1:i3
SeFilEnv2_OnSideRow3_Join47:
	call	SeMenu_SendEvent
	ret
SeFilEnv2_OnSideRow4:
	cp	a, 0:i3
	ret	z
	ld	wa, 3:i3
	call	SeMenu_SelectPartIfEnabled
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
	call	SeMenu_SelectPartIfEnabled
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
	jp	SeLfo1_StepSelectorAndReload
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
	jp	nz, (SeMenu_ToggleSolo:24)
	ldw	wa, 55
	ld	bc, 0:i3
	jp	SeMenu_SendEvent
SeFilLfo1_OnSideRow2:
	cp	a, 0:i3
	jr	nz, SeFilLfo1_OnSideRow2_Skip52
	ldw	wa, 48
	ld	bc, 0:i3
	jp	SeMenu_SendEvent
SeFilLfo1_OnSideRow2_Skip52:
	ld	wa, 2:i3
	ld	bc, 1:i3
	jp	SeMenu_CyclePartLfoState
SeFilLfo1_OnSideRow3:
	cp	a, 0:i3
	ret	z
	ld	wa, 2:i3
	ld	bc, 2:i3
	call	SeMenu_CyclePartLfoState
	ret
SeFilLfo1_OnSideRow4:
	cp	a, 0:i3
	ret	z
	ld	wa, 2:i3
	ld	bc, 3:i3
	call	SeMenu_CyclePartLfoState
	ret
SeFilLfo1_OnSideRow5:
	cp	a, 0:i3
	ret	z
	ld	wa, 2:i3
	ld	bc, 4:i3
	call	SeMenu_CyclePartLfoState
	ret
SeFilLfo1_OnSwitch15:
	cp	a, 0:i3
	ret	nz
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	ldw	wa, 32
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
