; =============================================================================
; Scoop Editor & Display Parameter Data (1.2K lines)
; =============================================================================
;
; Sound editor display data, performance mode parameter
; bytecode, Scoop oscilloscope editor configuration tables,
; and display dirty-region data.
; =============================================================================



Scoop_SoundEditorData:
	.incbin "includes/romslices/v7_block_scoop_soundeditordata_head.bin"
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
	lda_24 xde, (GUI_DisplayStructData_0xCD8)
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
	lda_24 xde, (GUI_DisplayStructData_0xD20)
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
	lda_24 xde, (GUI_DisplayStructData_0xD68)
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
	lda_24 xde, (GUI_DisplayStructData_0xDB0)
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
	lda_24 xde, (GUI_DisplayStructData_0xDF8)
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
	lda_24 xde, (GUI_DisplayStructData_0xE40)
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
	lda_24 xde, (GUI_DisplayStructData_0xE88)
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
	lda_24 xde, (GUI_DisplayStructData_0xED0)
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
	lda_24 xde, (GUI_DisplayStructData_0xF18)
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
	lda_24 xde, (GUI_DisplayStructData_0xF60)
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
	lda_24 xde, (GUI_DisplayStructData_0xFA8)
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
	lda_24 xde, (GUI_DisplayStructData_0xFF0)
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
	lda_24 xde, (GUI_DisplayStructData_0x1038)
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
	lda_24 xde, (GUI_DisplayStructData_0x1080)
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
	lda_24 xde, (GUI_DisplayStructData_0x10C8)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f04ffd:
	inc 4,XSP
	ret
	.incbin "includes/romslices/v7_block_scoop_soundeditordata_mid2.bin"
	push XSP
	nop
	jr nz, .Lc_f05401
	ldw WA, 0x0037
	lds bc, 0
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
	lds bc, 0
	jr t, .Lc_f05448
.Lc_f05439:
	lds wa, 2
	call SeMenu_TransferPartValues_EndData_0x1E0
	cps l, 0
	jr z, .Lc_f0544c
	ldw WA, 0x0030
	lds bc, 0
.Lc_f05448:
	call SeMenu_SendEvent
.Lc_f0544c:
	inc 4,XSP
	ret
	.incbin "includes/romslices/v7_block_scoop_soundeditordata_mid4.bin"
	cp (XSP),0x00
	jr nz, .Lc_f0550c
	ldw WA, 0x0020
	lds bc, 0
	jr t, .Lc_f05511
.Lc_f0550c:
	ldw WA, 0x003d
	lds bc, 0
.Lc_f05511:
	call SeMenu_SendEvent
	inc 4,XSP
	ret
	.incbin "includes/romslices/v7_block_scoop_soundeditordata_tail.bin"
