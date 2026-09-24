; =============================================================================
; Scoop Editor & Display Parameter Data (1.2K lines)
; =============================================================================
;
; Sound editor display data, performance mode parameter
; bytecode, Scoop oscilloscope editor configuration tables,
; and display dirty-region data.
; =============================================================================



Scoop_SoundEditorData:
	; Disassembled from the committed romslice (no source of any kind existed):
	; llvm-mc -triple=tlcs900 --disassemble round-trips these 51 B byte-exact.
	; v9/v10's Scoop_SoundEditorData opens the same way (jp/jp/ld wa,(xsp+4)/
	; ld bc,(xsp+6)/...) confirming the framing; only the call targets differ,
	; unresolved to symbols because this v7 link never names them.
	jp	SeMenu_CopyWriteUpdate_Join
	jp	SeMenu_CopyWriteUpdate_Return
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
	ld	xbc, 29360135
	jp	DeleteEvent
	jp	SeMenu_CopyWriteUpdate_Return2
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeMenu_SetupPartDisplay_End_0x90
	cp HL,0xffff
	jr z, .Lc_f03db4
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (GUI_DisplayStructData_0xCD8:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f03db4:
	inc 4,XSP
	ret
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeMenu_SetupPartDisplay_End_0x90
	cp HL,0xffff
	jr z, .Lc_f03de2
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (GUI_DisplayStructData_0xD20:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f03de2:
	inc 4,XSP
	ret
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeMenu_SetupPartDisplay_End_0x90
	cp HL,0xffff
	jr z, .Lc_f03e10
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (GUI_DisplayStructData_0xD68:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f03e10:
	inc 4,XSP
	ret
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeMenu_SetupPartDisplay_End_0x90
	cp HL,0xffff
	jr z, .Lc_f03e3e
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (GUI_DisplayStructData_0xDB0:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f03e3e:
	inc 4,XSP
	ret
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeMenu_SetupPartDisplay_End_0x90
	cp HL,0xffff
	jr z, .Lc_f03e6c
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (GUI_DisplayStructData_0xDF8:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f03e6c:
	inc 4,XSP
	ret
	.incbin "includes/romslices/v7_block_scoop_soundeditordata_mid1.bin"
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeMenu_SetupPartDisplay_End_0x90
	cp HL,0xffff
	jr z, .Lc_f04e5f
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (GUI_DisplayStructData_0xE40:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f04e5f:
	inc 4,XSP
	ret
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeMenu_SetupPartDisplay_End_0x90
	cp HL,0xffff
	jr z, .Lc_f04e8d
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (GUI_DisplayStructData_0xE88:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f04e8d:
	inc 4,XSP
	ret
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeMenu_SetupPartDisplay_End_0x90
	cp HL,0xffff
	jr z, .Lc_f04ebb
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (GUI_DisplayStructData_0xED0:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f04ebb:
	inc 4,XSP
	ret
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeMenu_SetupPartDisplay_End_0x90
	cp HL,0xffff
	jr z, .Lc_f04ee9
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (GUI_DisplayStructData_0xF18:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f04ee9:
	inc 4,XSP
	ret
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeMenu_SetupPartDisplay_End_0x90
	cp HL,0xffff
	jr z, .Lc_f04f17
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (GUI_DisplayStructData_0xF60:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f04f17:
	inc 4,XSP
	ret
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeMenu_SetupPartDisplay_End_0x90
	cp HL,0xffff
	jr z, .Lc_f04f45
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (GUI_DisplayStructData_0xFA8:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f04f45:
	inc 4,XSP
	ret
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeMenu_SetupPartDisplay_End_0x90
	cp HL,0xffff
	jr z, .Lc_f04f73
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (GUI_DisplayStructData_0xFF0:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f04f73:
	inc 4,XSP
	ret
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeMenu_SetupPartDisplay_End_0x90
	cp HL,0xffff
	jr z, .Lc_f04fa1
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (GUI_DisplayStructData_0x1038:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f04fa1:
	inc 4,XSP
	ret
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeMenu_SetupPartDisplay_End_0x90
	cp HL,0xffff
	jr z, .Lc_f04fcf
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (GUI_DisplayStructData_0x1080:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f04fcf:
	inc 4,XSP
	ret
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeMenu_SetupPartDisplay_End_0x90
	cp HL,0xffff
	jr z, .Lc_f04ffd
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (GUI_DisplayStructData_0x10C8:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f04ffd:
	inc 4,XSP
	ret
	.incbin "includes/romslices/v7_block_scoop_soundeditordata_mid2_head.bin"
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
	call SeMenu_SetupPartDisplay_End_0x219
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
	call SeMenu_TransferPartValues_EndData_0x169
	ld A,(XSP+0x12)
	extz WA
	call SeMenu_SetupPartDisplay_End_0x1F6
	lda xsp, (xsp + 0x16)
	ret
	.incbin "includes/romslices/v7_block_scoop_soundeditordata_mid2_mid1.bin"
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
	call SeMenu_SetupPartDisplay_End_0x219
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
	call SeMenu_TransferPartValues_EndData_0x169
	ld A,(XSP+0x12)
	extz WA
	call SeMenu_SetupPartDisplay_End_0x1F6
	lda xsp, (xsp + 0x16)
	ret
	.incbin "includes/romslices/v7_block_scoop_soundeditordata_mid2_mid2.bin"
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
	call SeMenu_SetupPartDisplay_End_0x219
	cp (XSP+0x0c),0x00
	jr nz, .Lc_f05185
	ld C, 0x37:opc
	jr t, .Lc_f0519e
.Lc_f05185:
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
	ld A,(XSP+0x10)
	extz WA
	ld E,(XSP+0x0e)
	extz DE
	extz BC
	pushw bc
	lda xbc, (xsp + 0x02)
	push XBC
	ld bc, 1:i3
	call SeMenu_TransferPartValues_EndData_0x169
	ld A,(XSP+0x12)
	extz WA
	call SeMenu_SetupPartDisplay_End_0x1F6
	lda xsp, (xsp + 0x16)
	ret
	.incbin "includes/romslices/v7_block_scoop_soundeditordata_mid2_mid3.bin"
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
	call SeMenu_SetupPartDisplay_End_0x219
	cp (XSP+0x0c),0x00
	jr nz, .Lc_f05215
	ld C, 0x36:opc
	jr t, .Lc_f0522e
.Lc_f05215:
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
	ld A,(XSP+0x10)
	extz WA
	ld E,(XSP+0x0e)
	extz DE
	extz BC
	pushw bc
	lda xbc, (xsp + 0x02)
	push XBC
	ld bc, 0:i3
	call SeMenu_TransferPartValues_EndData_0x169
	ld A,(XSP+0x12)
	extz WA
	call SeMenu_SetupPartDisplay_End_0x1F6
	lda xsp, (xsp + 0x16)
	ret
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
	ld (XWA),0xff
.Lc_f05295:
	cp (XSP+0x0c),0x00
	jr nz, .Lc_f0529f
	ld A, 0x50:opc
	jr t, .Lc_f052b6
.Lc_f0529f:
	ld A,(XSP+0x0e)
	dec 1,A
	extz WA
	muls WA,0x0015
	extz XWA
	lda xwa, (xwa + 0x10)
	lda xwa, (xwa + 0x14)
	ld (XSP+0x0e),0x00
.Lc_f052b6:
	ld E,(XSP+0x0e)
	extz DE
	extz WA
	pushw wa
	push XBC
	ldw WA, 0x0030
	ld bc, 5:i3
	call SeMenu_TransferPartValues_EndData_0x169
	cp l, 1:i3
	call z, (SeMenu_ApplyPartEdit_Data2_0x19BD:24)
	ld wa, 6:i3
	call SeMenu_SetupPartDisplay_End_0x1F6
	lda xsp, (xsp + 0x12)
	ret
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
	call SeMenu_SetupPartDisplay_End_0x219
	cp (XSP+0x0c),0x00
	jr nz, .Lc_f0531d
	ld A, 0x4f:opc
	jr t, .Lc_f05334
.Lc_f0531d:
	ld A,(XSP+0x0e)
	dec 1,A
	extz WA
	muls WA,0x0015
	extz XWA
	lda xwa, (xwa + 0x10)
	lda xwa, (xwa + 0x13)
	ld (XSP+0x0e),0x00
.Lc_f05334:
	ld E,(XSP+0x0e)
	extz DE
	extz WA
	pushw wa
	lda xwa, (xsp + 0x02)
	push XWA
	ldw WA, 0x0030
	ld bc, 4:i3
	call SeMenu_TransferPartValues_EndData_0x169
	cp l, 1:i3
	call z, (SeMenu_ApplyPartEdit_Data2_0x19BD:24)
	ld wa, 7:i3
	call SeMenu_SetupPartDisplay_End_0x1F6
	lda xsp, (xsp + 0x12)
	ret
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
	call SeMenu_SetupPartDisplay_End_0x219
	cp (XSP+0x0c),0x00
	jr nz, .Lc_f0539e
	ld A, 0x50:opc
	jr t, .Lc_f053b5
.Lc_f0539e:
	ld A,(XSP+0x0e)
	dec 1,A
	extz WA
	muls WA,0x0015
	extz XWA
	lda xwa, (xwa + 0x10)
	lda xwa, (xwa + 0x14)
	ld (XSP+0x0e),0x00
.Lc_f053b5:
	ld E,(XSP+0x0e)
	extz DE
	extz WA
	pushw wa
	lda xwa, (xsp + 0x02)
	push XWA
	ldw WA, 0x0030
	ld bc, 5:i3
	call SeMenu_TransferPartValues_EndData_0x169
	cp l, 1:i3
	call z, (SeMenu_ApplyPartEdit_Data2_0x19BD:24)
	ldw WA, 0x0008
	call SeMenu_SetupPartDisplay_End_0x1F6
	lda xsp, (xsp + 0x12)
	ret
	.incbin "includes/romslices/v7_block_scoop_soundeditordata_mid2_tail.bin"
	push XSP
	nop
	jr nz, .Lc_f05401
	ldw WA, 0x0037
	ld bc, 0:i3
	call SeMenu_SendEvent
	jr t, .Lc_f05401
	call SeMenu_BitShiftMask_End_0x1A3
.Lc_f05401:
	inc 4,XSP
	ret
	.incbin "includes/romslices/v7_block_scoop_soundeditordata_mid3.bin"
	ldw WA, 0x811d
	cp WA,(XIY)
	cp (XSP+0x02),0x00
	jr nz, .Lc_f05439
	cp (XSP),0x00
	jr nz, .Lc_f0544c
	ldw WA, 0x0039
	ld bc, 0:i3
	jr t, .Lc_f05448
.Lc_f05439:
	ld wa, 2:i3
	call SeMenu_TransferPartValues_EndData_0x1E0
	cp l, 0:i3
	jr z, .Lc_f0544c
	ldw WA, 0x0030
	ld bc, 0:i3
.Lc_f05448:
	call SeMenu_SendEvent
.Lc_f0544c:
	inc 4,XSP
	ret
	.incbin "includes/romslices/v7_block_scoop_soundeditordata_mid4.bin"
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
	inc 4,XSP
	ret
	.incbin "includes/romslices/v7_block_scoop_soundeditordata_tail.bin"
