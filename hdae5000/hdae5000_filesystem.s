HDAE5000_FS_Init:	; 0x2870D6 (3711 bytes)
; FS_Init: 0x2870D6 (3711 bytes) — disassembled from original ROM
; Main entry + 10 event handler callbacks

	lda	xsp, (xsp-36)
	pushw iz                                ; push IZ
	ld (xsp + 0x24), bc
	ld	iz, wa
	ldw (xsp + 0x02), 0
	ld	wa, de
	cps	wa, 6
	jrl ugt, .LFS_7334                     ; [7b 49 02] jrl UGT,0x287334
	add	wa, wa
	lda_24 xix, 0x2e2d46
	ldw_sri wa, 0x07, 0xF0, 0xE0	; ld WA,(XIX+WA)
	lda_24 xix, 0x287101
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
	pushw 0x0005
	lda_24 xwa, 0x2e1cac
	push xwa
	lda_24 xwa, 0x22aa62
	push xwa
	call HDAE5000_MemCopy
	pushw 0x0012
	lda_24 xwa, 0x2e1cb2
	push xwa
	lda_24 xwa, 0x22aa68
	push xwa
	call HDAE5000_MemCopy
	pushw 0x0005
	lda_24 xwa, 0x2e1cc4
	push xwa
	lda_24 xwa, 0x22aa7a
	push xwa
	call HDAE5000_MemCopy
	lda	xsp, (xsp+30)
	pushw 0x001c
	lda_24 xwa, 0x2e1cca
	push xwa
	lda_24 xwa, 0x22aa80
	push xwa
	call HDAE5000_MemCopy
	lda	xsp, (xsp+10)
	jrl t, .LFS_7334                       ; [78 de 01] jrl T,0x287334
	ld	wa, iz
	extz xwa
	div wa, 0x0064
	pushw wa                                ; push WA
	pushw 0x002e
	pushw 0x2d24
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xwa, (xsp+14)
	push xwa
	call HDAE5000_Display_Buffer_Validate
	pushw hl                                ; push HL
	lda	xwa, (xsp+20)
	push xwa
	lda_24 xwa, 0x22aa62
	push xwa
	call HDAE5000_MemCopy
	lda	xsp, (xsp+24)
	jrl t, .LFS_7334                       ; [78 aa 01] jrl T,0x287334
	ld	wa, iz
	extz xwa
	div wa, 0x000a
	pushw wa                                ; push WA
	pushw 0x002e
	pushw 0x2d2a
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xwa, (xsp+14)
	push xwa
	call HDAE5000_Display_Buffer_Validate
	pushw hl                                ; push HL
	lda	xwa, (xsp+20)
	push xwa
	lda_24 xwa, 0x22aa62
	push xwa
	call HDAE5000_MemCopy
	lda	xsp, (xsp+24)
	jrl t, .LFS_7334                       ; [78 76 01] jrl T,0x287334
	pushw iz                                ; push IZ
	pushw 0x002e
	pushw 0x2d30
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xwa, (xsp+14)
	push xwa
	call HDAE5000_Display_Buffer_Validate
	pushw hl                                ; push HL
	lda	xwa, (xsp+20)
	push xwa
	lda_24 xwa, 0x22aa62
	push xwa
	call HDAE5000_MemCopy
	lda	xsp, (xsp+24)
	cps	iz, 0
	jr z, .LFS_720d                        ; [66 22] jr Z,0x28720d
	cp	iz, 0x0078
	jr ugt, .LFS_720d                      ; [6b 1c] jr UGT,0x28720d
	pushw 0x0010
	ld	wa, iz
	dec	1, wa
	call HDAE5000_Calc_Offset_16
	push xhl
	lda_24 xwa, 0x22aa68
	push xwa
	call HDAE5000_MemCopy
	lda	xsp, (xsp+10)
	jrl t, .LFS_7334                       ; [78 27 01] jrl T,0x287334
.LFS_720d:
	ldw (xsp + 0x02), 65535
	jrl t, .LFS_7334                       ; [78 1f 01] jrl T,0x287334
	ld	wa, (xsp+36)
	extz xwa
	div wa, 0x000a
	pushw wa                                ; push WA
	pushw 0x002e
	pushw 0x2d36
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xwa, (xsp+14)
	push xwa
	call HDAE5000_Display_Buffer_Validate
	pushw hl                                ; push HL
	lda	xwa, (xsp+20)
	push xwa
	lda_24 xwa, 0x22aa7a
	push xwa
	call HDAE5000_MemCopy
	lda	xsp, (xsp+24)
	jrl t, .LFS_7334                       ; [78 ea 00] jrl T,0x287334
	pushm	(xsp+36)
	pushw 0x002e
	pushw 0x2d3e
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xwa, (xsp+14)
	push xwa
	call HDAE5000_Display_Buffer_Validate
	pushw hl                                ; push HL
	lda	xwa, (xsp+20)
	push xwa
	lda_24 xwa, 0x22aa7a
	push xwa
	call HDAE5000_MemCopy
	lda	xsp, (xsp+24)
	cps	iz, 0
	jr z, .LFS_72b5                        ; [66 3c] jr Z,0x2872b5
	cp	iz, 0x0078
	jr ugt, .LFS_72b5                      ; [6b 36] jr UGT,0x2872b5
	cpw	(xsp+36), 0x0000
	jr z, .LFS_72ae                        ; [66 28] jr Z,0x2872ae
	cpw	(xsp+36), 0x0010
	jr ugt, .LFS_72ae                      ; [6b 21] jr UGT,0x2872ae
	pushw 0x001a
	ld	wa, iz
	dec	1, wa
	ld	bc, (xsp+38)
	dec	1, bc
	call HDAE5000_Calculate_Row_Address
	push xhl
	lda_24 xwa, 0x22aa80
	push xwa
	call HDAE5000_MemCopy
	lda	xsp, (xsp+10)
	jrl t, .LFS_7334                       ; [78 86 00] jrl T,0x287334
.LFS_72ae:
	ldw (xsp + 0x02), 65534
	jr t, .LFS_7334                        ; [68 7f] jr T,0x287334
.LFS_72b5:
	ldw (xsp + 0x02), 65535
	jr t, .LFS_7334                        ; [68 78] jr T,0x287334
	pushw 0x0005
	lda_24 xwa, 0x2e1cac
	push xwa
	lda_24 xwa, 0x22aa62
	push xwa
	call HDAE5000_MemCopy
	pushw 0x0012
	lda_24 xwa, 0x2e1cb2
	push xwa
	lda_24 xwa, 0x22aa68
	push xwa
	call HDAE5000_MemCopy
	pushw 0x0005
	lda_24 xwa, 0x2e1cc4
	push xwa
	lda_24 xwa, 0x22aa7a
	push xwa
	call HDAE5000_MemCopy
	lda	xsp, (xsp+30)
	pushw 0x001c
	lda_24 xwa, 0x2e1cca
	push xwa
	lda_24 xwa, 0x22aa80
	push xwa
	call HDAE5000_MemCopy
	lda	xsp, (xsp+10)
	stiw_da	0x22AA5E, 0
	stiw_da	0x22AA60, 0
	stiw_da	0x22AA5C, 0
	pushw 0xffff
	ld	xwa, 0x007f0098
	ldw	bc, 0xffff
	ldw	de, 0xffff
	calr	0xc698
.LFS_7334:
	cpw	(xsp+42), 0x0001
	jrl nz, .LFS_7447                      ; [7e 0b 01] jrl NZ,0x287447
	lda_24 xwa, 0x22aa62
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0100)
	ld	xwa, 0x007f00a8
	ld	xbc, 0x01ea000a
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0100)
	ld	xwa, 0x007f00a8
	ld	xbc, 0x01c0000f
	ld	xde, 0xffffffff
	call	(xhl)
	lda_24 xwa, 0x22aa68
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0100)
	ld	xwa, 0x007f00a9
	ld	xbc, 0x01ea000a
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0100)
	ld	xwa, 0x007f00a9
	ld	xbc, 0x01c0000f
	ld	xde, 0xffffffff
	call	(xhl)
	lda_24 xwa, 0x22aa7a
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0100)
	ld	xwa, 0x007f00aa
	ld	xbc, 0x01ea000a
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0100)
	ld	xwa, 0x007f00aa
	ld	xbc, 0x01c0000f
	ld	xde, 0xffffffff
	call	(xhl)
	lda_24 xwa, 0x22aa80
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0100)
	ld	xwa, 0x007f00ab
	ld	xbc, 0x01ea000a
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0100)
	ld	xwa, 0x007f00ab
	ld	xbc, 0x01c0000f
	ld	xde, 0xffffffff
	call	(xhl)
	jrl t, .LFS_754f                       ; [78 08 01] jrl T,0x28754f
.LFS_7447:
	lda_24 xwa, 0x22aa62
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f00a8
	ld	xbc, 0x01ea000a
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f00a8
	ld	xbc, 0x01c0000f
	ld	xde, 0xffffffff
	call	(xhl)
	lda_24 xwa, 0x22aa68
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f00a9
	ld	xbc, 0x01ea000a
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f00a9
	ld	xbc, 0x01c0000f
	ld	xde, 0xffffffff
	call	(xhl)
	lda_24 xwa, 0x22aa7a
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f00aa
	ld	xbc, 0x01ea000a
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f00aa
	ld	xbc, 0x01c0000f
	ld	xde, 0xffffffff
	call	(xhl)
	lda_24 xwa, 0x22aa80
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f00ab
	ld	xbc, 0x01ea000a
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f00ab
	ld	xbc, 0x01c0000f
	ld	xde, 0xffffffff
	call	(xhl)
.LFS_754f:
	ld	hl, (xsp+2)
	popw iz                                 ; pop IZ
	lda	xsp, (xsp+36)
	retd 0x0002		; retd 0x0002

	dec	4, xsp
	push xiz
	ld (xsp + 0x04), xwa                    ; ld (XSP+0x04),XWA
	ld	xwa, xbc
	cp	xwa, 0x01e00082
	jrl z, .LFS_75f1                       ; [76 87 00] jrl Z,0x2875f1
	sub	xwa, 0x01e0003e
	cp	xwa, 0x00000000
	jr lt, .LFS_75f5                       ; [61 7d] jr LT,0x2875f5
	cp	xwa, 0x00000009
	jr gt, .LFS_75f5                       ; [6a 75] jr GT,0x2875f5
	add	xwa, xwa
	add	xwa, 0x002e2d74
	ld	wa, (xwa)
	lda_24 xix, 0x287594
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
	ld	xiz, xde
	cpw_da	0x22AA5C, 5
	jr nz, .LFS_75c1                       ; [6e 22] jr NZ,0x2875c1
	ldw_da	wa, 0x23A092
	ldw_da	bc, 0x23A094
	call HDAE5000_Calculate_Row_Address
	push xhl
	pushw 0x002e
	pushw 0x2d70
	ld xwa, (xiz + 0x12)                    ; ld XWA,(XIZ+0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+12)
	jr t, .LFS_75d1                        ; [68 10] jr T,0x2875d1
.LFS_75c1:
	pushw 0x002e
	pushw 0x2d54
	ld xwa, (xiz + 0x12)                    ; ld XWA,(XIZ+0x12)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LFS_75d1:
	ld xhl, (xsp + 0x04)                    ; ld XHL,(XSP+0x04)
	jr t, .LFS_75f7                        ; [68 21] jr T,0x2875f7
	lds32	xhl, 1
	jr t, .LFS_75f7                        ; [68 1d] jr T,0x2875f7
	lds32	xhl, 1
	jr t, .LFS_75f7                        ; [68 19] jr T,0x2875f7
	lds32	xhl, 0
	jr t, .LFS_75f7                        ; [68 15] jr T,0x2875f7
	lds32	xhl, 0
	jr t, .LFS_75f7                        ; [68 11] jr T,0x2875f7
	lda_24 xhl, 0x22aa57
	jr t, .LFS_75f7                        ; [68 0a] jr T,0x2875f7
	lds32	xhl, 1
	jr t, .LFS_75f7                        ; [68 06] jr T,0x2875f7
.LFS_75f1:
	lds32	xhl, 0
	jr t, .LFS_75f7                        ; [68 02] jr T,0x2875f7
.LFS_75f5:
	lds32	xhl, 0
.LFS_75f7:
	pop xiz                                 ; pop XIZ
	inc 4, xsp                              ; inc 4,XSP
	ret

	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, 0x01e00082
	jrl z, .LFS_76c1                       ; [76 b8 00] jrl Z,0x2876c1
	sub	xwa, 0x01e0003e
	cp	xwa, 0x00000000
	jrl lt, .LFS_7701                      ; [71 e9 00] jrl LT,0x287701
	cp	xwa, 0x00000009
	jrl gt, .LFS_7701                      ; [7a e0 00] jrl GT,0x287701
	add	xwa, xwa
	add	xwa, 0x002e2d8c
	ld	wa, (xwa)
	lda_24 xix, 0x287635
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
	cpw_da	0x22AA5C, 5
	jr nz, .LFS_7661                       ; [6e 23] jr NZ,0x287661
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	sll	xwa, 0x02
	ld	xbc, 0x002e2922
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	push xwa
	pushw 0x002e
	pushw 0x2d88
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+12)
	jr t, .LFS_7671                        ; [68 10] jr T,0x287671
.LFS_7661:
	ld	xwa, (0x2e2922)
	push xwa
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LFS_7671:
	ld	xhl, xiz
	jrl t, .LFS_7703                       ; [78 8d 00] jrl T,0x287703
	lds32	xhl, 1
	jrl t, .LFS_7703                       ; [78 88 00] jrl T,0x287703
	lds32	xhl, 1
	jrl t, .LFS_7703                       ; [78 83 00] jrl T,0x287703
	cpw_da	0x22AA5C, 5
	jr nz, .LFS_7697                       ; [6e 0e] jr NZ,0x287697
	lds32	xhl, 2
	cpib_da	0x22AA4E, 0
	jr nz, .LFS_7699                       ; [6e 06] jr NZ,0x287699
	lds32	xhl, 0
	jr t, .LFS_7699                        ; [68 02] jr T,0x287699
.LFS_7697:
	lds32	xhl, 0
.LFS_7699:
	jr t, .LFS_7703                        ; [68 68] jr T,0x287703
	cpw_da	0x22AA5C, 5
	jr nz, .LFS_76b2                       ; [6e 0e] jr NZ,0x2876b2
	lds32	xhl, 1
	cpib_da	0x22AA4E, 0
	jr nz, .LFS_76b4                       ; [6e 06] jr NZ,0x2876b4
	lds32	xhl, 0
	jr t, .LFS_76b4                        ; [68 02] jr T,0x2876b4
.LFS_76b2:
	lds32	xhl, 0
.LFS_76b4:
	jr t, .LFS_7703                        ; [68 4d] jr T,0x287703
	lda_24 xhl, 0x22aa4e
	jr t, .LFS_7703                        ; [68 46] jr T,0x287703
	lds32	xhl, 1
	jr t, .LFS_7703                        ; [68 42] jr T,0x287703
.LFS_76c1:
	cpw_da	0x22AA5C, 5
	jr nz, .LFS_76ec                       ; [6e 22] jr NZ,0x2876ec
	lda_24 xwa, 0x22aa4c
	calr	0xdc6e
	ldw_da	bc, 0x23A092
	ldw_da	de, 0x23A094
	ldw_da	wa, 0x22AA4C
	pushw wa                                ; push WA
	ld	xwa, 0x007f0102
	calr	0xc2e2
	jr t, .LFS_76fd                        ; [68 11] jr T,0x2876fd
.LFS_76ec:
	pushw 0xffff
	ld	xwa, 0x007f0102
	ldw	bc, 0xffff
	ldw	de, 0xffff
	calr	0xc2cf
.LFS_76fd:
	lds32	xhl, 0
	jr t, .LFS_7703                        ; [68 02] jr T,0x287703
.LFS_7701:
	lds32	xhl, 0
.LFS_7703:
	pop xiz                                 ; pop XIZ
	ret

	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, 0x01e00082
	jrl z, .LFS_77cb                       ; [76 b8 00] jrl Z,0x2877cb
	sub	xwa, 0x01e0003e
	cp	xwa, 0x00000000
	jrl lt, .LFS_780b                      ; [71 e9 00] jrl LT,0x28780b
	cp	xwa, 0x00000009
	jrl gt, .LFS_780b                      ; [7a e0 00] jrl GT,0x28780b
	add	xwa, xwa
	add	xwa, 0x002e2da4
	ld	wa, (xwa)
	lda_24 xix, 0x28773f
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
	cpw_da	0x22AA5C, 5
	jr nz, .LFS_776b                       ; [6e 23] jr NZ,0x28776b
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	sll	xwa, 0x02
	ld	xbc, 0x002e2922
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	push xwa
	pushw 0x002e
	pushw 0x2da0
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+12)
	jr t, .LFS_777b                        ; [68 10] jr T,0x28777b
.LFS_776b:
	ld	xwa, (0x2e2922)
	push xwa
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LFS_777b:
	ld	xhl, xiz
	jrl t, .LFS_780d                       ; [78 8d 00] jrl T,0x28780d
	lds32	xhl, 1
	jrl t, .LFS_780d                       ; [78 88 00] jrl T,0x28780d
	lds32	xhl, 1
	jrl t, .LFS_780d                       ; [78 83 00] jrl T,0x28780d
	cpw_da	0x22AA5C, 5
	jr nz, .LFS_77a1                       ; [6e 0e] jr NZ,0x2877a1
	lds32	xhl, 2
	cpib_da	0x22AA4F, 0
	jr nz, .LFS_77a3                       ; [6e 06] jr NZ,0x2877a3
	lds32	xhl, 0
	jr t, .LFS_77a3                        ; [68 02] jr T,0x2877a3
.LFS_77a1:
	lds32	xhl, 0
.LFS_77a3:
	jr t, .LFS_780d                        ; [68 68] jr T,0x28780d
	cpw_da	0x22AA5C, 5
	jr nz, .LFS_77bc                       ; [6e 0e] jr NZ,0x2877bc
	lds32	xhl, 1
	cpib_da	0x22AA4F, 0
	jr nz, .LFS_77be                       ; [6e 06] jr NZ,0x2877be
	lds32	xhl, 0
	jr t, .LFS_77be                        ; [68 02] jr T,0x2877be
.LFS_77bc:
	lds32	xhl, 0
.LFS_77be:
	jr t, .LFS_780d                        ; [68 4d] jr T,0x28780d
	lda_24 xhl, 0x22aa4f
	jr t, .LFS_780d                        ; [68 46] jr T,0x28780d
	lds32	xhl, 1
	jr t, .LFS_780d                        ; [68 42] jr T,0x28780d
.LFS_77cb:
	cpw_da	0x22AA5C, 5
	jr nz, .LFS_77f6                       ; [6e 22] jr NZ,0x2877f6
	lda_24 xwa, 0x22aa4c
	calr	0xdb64
	ldw_da	bc, 0x23A092
	ldw_da	de, 0x23A094
	ldw_da	wa, 0x22AA4C
	pushw wa                                ; push WA
	ld	xwa, 0x007f0102
	calr	0xc1d8
	jr t, .LFS_7807                        ; [68 11] jr T,0x287807
.LFS_77f6:
	pushw 0xffff
	ld	xwa, 0x007f0102
	ldw	bc, 0xffff
	ldw	de, 0xffff
	calr	0xc1c5
.LFS_7807:
	lds32	xhl, 0
	jr t, .LFS_780d                        ; [68 02] jr T,0x28780d
.LFS_780b:
	lds32	xhl, 0
.LFS_780d:
	pop xiz                                 ; pop XIZ
	ret

	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, 0x01e00082
	jrl z, .LFS_78d5                       ; [76 b8 00] jrl Z,0x2878d5
	sub	xwa, 0x01e0003e
	cp	xwa, 0x00000000
	jrl lt, .LFS_7915                      ; [71 e9 00] jrl LT,0x287915
	cp	xwa, 0x00000009
	jrl gt, .LFS_7915                      ; [7a e0 00] jrl GT,0x287915
	add	xwa, xwa
	add	xwa, 0x002e2dbc
	ld	wa, (xwa)
	lda_24 xix, 0x287849
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
	cpw_da	0x22AA5C, 5
	jr nz, .LFS_7875                       ; [6e 23] jr NZ,0x287875
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	sll	xwa, 0x02
	ld	xbc, 0x002e2922
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	push xwa
	pushw 0x002e
	pushw 0x2db8
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+12)
	jr t, .LFS_7885                        ; [68 10] jr T,0x287885
.LFS_7875:
	ld	xwa, (0x2e2922)
	push xwa
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LFS_7885:
	ld	xhl, xiz
	jrl t, .LFS_7917                       ; [78 8d 00] jrl T,0x287917
	lds32	xhl, 1
	jrl t, .LFS_7917                       ; [78 88 00] jrl T,0x287917
	lds32	xhl, 1
	jrl t, .LFS_7917                       ; [78 83 00] jrl T,0x287917
	cpw_da	0x22AA5C, 5
	jr nz, .LFS_78ab                       ; [6e 0e] jr NZ,0x2878ab
	lds32	xhl, 2
	cpib_da	0x22AA50, 0
	jr nz, .LFS_78ad                       ; [6e 06] jr NZ,0x2878ad
	lds32	xhl, 0
	jr t, .LFS_78ad                        ; [68 02] jr T,0x2878ad
.LFS_78ab:
	lds32	xhl, 0
.LFS_78ad:
	jr t, .LFS_7917                        ; [68 68] jr T,0x287917
	cpw_da	0x22AA5C, 5
	jr nz, .LFS_78c6                       ; [6e 0e] jr NZ,0x2878c6
	lds32	xhl, 1
	cpib_da	0x22AA50, 0
	jr nz, .LFS_78c8                       ; [6e 06] jr NZ,0x2878c8
	lds32	xhl, 0
	jr t, .LFS_78c8                        ; [68 02] jr T,0x2878c8
.LFS_78c6:
	lds32	xhl, 0
.LFS_78c8:
	jr t, .LFS_7917                        ; [68 4d] jr T,0x287917
	lda_24 xhl, 0x22aa50
	jr t, .LFS_7917                        ; [68 46] jr T,0x287917
	lds32	xhl, 1
	jr t, .LFS_7917                        ; [68 42] jr T,0x287917
.LFS_78d5:
	cpw_da	0x22AA5C, 5
	jr nz, .LFS_7900                       ; [6e 22] jr NZ,0x287900
	lda_24 xwa, 0x22aa4c
	calr	0xda5a
	ldw_da	bc, 0x23A092
	ldw_da	de, 0x23A094
	ldw_da	wa, 0x22AA4C
	pushw wa                                ; push WA
	ld	xwa, 0x007f0102
	calr	0xc0ce
	jr t, .LFS_7911                        ; [68 11] jr T,0x287911
.LFS_7900:
	pushw 0xffff
	ld	xwa, 0x007f0102
	ldw	bc, 0xffff
	ldw	de, 0xffff
	calr	0xc0bb
.LFS_7911:
	lds32	xhl, 0
	jr t, .LFS_7917                        ; [68 02] jr T,0x287917
.LFS_7915:
	lds32	xhl, 0
.LFS_7917:
	pop xiz                                 ; pop XIZ
	ret

	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, 0x01e00082
	jrl z, .LFS_79df                       ; [76 b8 00] jrl Z,0x2879df
	sub	xwa, 0x01e0003e
	cp	xwa, 0x00000000
	jrl lt, .LFS_7a1f                      ; [71 e9 00] jrl LT,0x287a1f
	cp	xwa, 0x00000009
	jrl gt, .LFS_7a1f                      ; [7a e0 00] jrl GT,0x287a1f
	add	xwa, xwa
	add	xwa, 0x002e2dd4
	ld	wa, (xwa)
	lda_24 xix, 0x287953
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
	cpw_da	0x22AA5C, 5
	jr nz, .LFS_797f                       ; [6e 23] jr NZ,0x28797f
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	sll	xwa, 0x02
	ld	xbc, 0x002e2922
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	push xwa
	pushw 0x002e
	pushw 0x2dd0
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+12)
	jr t, .LFS_798f                        ; [68 10] jr T,0x28798f
.LFS_797f:
	ld	xwa, (0x2e2922)
	push xwa
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LFS_798f:
	ld	xhl, xiz
	jrl t, .LFS_7a21                       ; [78 8d 00] jrl T,0x287a21
	lds32	xhl, 1
	jrl t, .LFS_7a21                       ; [78 88 00] jrl T,0x287a21
	lds32	xhl, 1
	jrl t, .LFS_7a21                       ; [78 83 00] jrl T,0x287a21
	cpw_da	0x22AA5C, 5
	jr nz, .LFS_79b5                       ; [6e 0e] jr NZ,0x2879b5
	lds32	xhl, 2
	cpib_da	0x22AA51, 0
	jr nz, .LFS_79b7                       ; [6e 06] jr NZ,0x2879b7
	lds32	xhl, 0
	jr t, .LFS_79b7                        ; [68 02] jr T,0x2879b7
.LFS_79b5:
	lds32	xhl, 0
.LFS_79b7:
	jr t, .LFS_7a21                        ; [68 68] jr T,0x287a21
	cpw_da	0x22AA5C, 5
	jr nz, .LFS_79d0                       ; [6e 0e] jr NZ,0x2879d0
	lds32	xhl, 1
	cpib_da	0x22AA51, 0
	jr nz, .LFS_79d2                       ; [6e 06] jr NZ,0x2879d2
	lds32	xhl, 0
	jr t, .LFS_79d2                        ; [68 02] jr T,0x2879d2
.LFS_79d0:
	lds32	xhl, 0
.LFS_79d2:
	jr t, .LFS_7a21                        ; [68 4d] jr T,0x287a21
	lda_24 xhl, 0x22aa51
	jr t, .LFS_7a21                        ; [68 46] jr T,0x287a21
	lds32	xhl, 1
	jr t, .LFS_7a21                        ; [68 42] jr T,0x287a21
.LFS_79df:
	cpw_da	0x22AA5C, 5
	jr nz, .LFS_7a0a                       ; [6e 22] jr NZ,0x287a0a
	lda_24 xwa, 0x22aa4c
	calr	0xd950
	ldw_da	bc, 0x23A092
	ldw_da	de, 0x23A094
	ldw_da	wa, 0x22AA4C
	pushw wa                                ; push WA
	ld	xwa, 0x007f0102
	calr	0xbfc4
	jr t, .LFS_7a1b                        ; [68 11] jr T,0x287a1b
.LFS_7a0a:
	pushw 0xffff
	ld	xwa, 0x007f0102
	ldw	bc, 0xffff
	ldw	de, 0xffff
	calr	0xbfb1
.LFS_7a1b:
	lds32	xhl, 0
	jr t, .LFS_7a21                        ; [68 02] jr T,0x287a21
.LFS_7a1f:
	lds32	xhl, 0
.LFS_7a21:
	pop xiz                                 ; pop XIZ
	ret

	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, 0x01e00082
	jrl z, .LFS_7ae9                       ; [76 b8 00] jrl Z,0x287ae9
	sub	xwa, 0x01e0003e
	cp	xwa, 0x00000000
	jrl lt, .LFS_7b29                      ; [71 e9 00] jrl LT,0x287b29
	cp	xwa, 0x00000009
	jrl gt, .LFS_7b29                      ; [7a e0 00] jrl GT,0x287b29
	add	xwa, xwa
	add	xwa, 0x002e2dec
	ld	wa, (xwa)
	lda_24 xix, 0x287a5d
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
	cpw_da	0x22AA5C, 5
	jr nz, .LFS_7a89                       ; [6e 23] jr NZ,0x287a89
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	sll	xwa, 0x02
	ld	xbc, 0x002e2922
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	push xwa
	pushw 0x002e
	pushw 0x2de8
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+12)
	jr t, .LFS_7a99                        ; [68 10] jr T,0x287a99
.LFS_7a89:
	ld	xwa, (0x2e2922)
	push xwa
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LFS_7a99:
	ld	xhl, xiz
	jrl t, .LFS_7b2b                       ; [78 8d 00] jrl T,0x287b2b
	lds32	xhl, 1
	jrl t, .LFS_7b2b                       ; [78 88 00] jrl T,0x287b2b
	lds32	xhl, 1
	jrl t, .LFS_7b2b                       ; [78 83 00] jrl T,0x287b2b
	cpw_da	0x22AA5C, 5
	jr nz, .LFS_7abf                       ; [6e 0e] jr NZ,0x287abf
	lds32	xhl, 2
	cpib_da	0x22AA52, 0
	jr nz, .LFS_7ac1                       ; [6e 06] jr NZ,0x287ac1
	lds32	xhl, 0
	jr t, .LFS_7ac1                        ; [68 02] jr T,0x287ac1
.LFS_7abf:
	lds32	xhl, 0
.LFS_7ac1:
	jr t, .LFS_7b2b                        ; [68 68] jr T,0x287b2b
	cpw_da	0x22AA5C, 5
	jr nz, .LFS_7ada                       ; [6e 0e] jr NZ,0x287ada
	lds32	xhl, 1
	cpib_da	0x22AA52, 0
	jr nz, .LFS_7adc                       ; [6e 06] jr NZ,0x287adc
	lds32	xhl, 0
	jr t, .LFS_7adc                        ; [68 02] jr T,0x287adc
.LFS_7ada:
	lds32	xhl, 0
.LFS_7adc:
	jr t, .LFS_7b2b                        ; [68 4d] jr T,0x287b2b
	lda_24 xhl, 0x22aa52
	jr t, .LFS_7b2b                        ; [68 46] jr T,0x287b2b
	lds32	xhl, 1
	jr t, .LFS_7b2b                        ; [68 42] jr T,0x287b2b
.LFS_7ae9:
	cpw_da	0x22AA5C, 5
	jr nz, .LFS_7b14                       ; [6e 22] jr NZ,0x287b14
	lda_24 xwa, 0x22aa4c
	calr	0xd846
	ldw_da	bc, 0x23A092
	ldw_da	de, 0x23A094
	ldw_da	wa, 0x22AA4C
	pushw wa                                ; push WA
	ld	xwa, 0x007f0102
	calr	0xbeba
	jr t, .LFS_7b25                        ; [68 11] jr T,0x287b25
.LFS_7b14:
	pushw 0xffff
	ld	xwa, 0x007f0102
	ldw	bc, 0xffff
	ldw	de, 0xffff
	calr	0xbea7
.LFS_7b25:
	lds32	xhl, 0
	jr t, .LFS_7b2b                        ; [68 02] jr T,0x287b2b
.LFS_7b29:
	lds32	xhl, 0
.LFS_7b2b:
	pop xiz                                 ; pop XIZ
	ret

	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, 0x01e00082
	jrl z, .LFS_7bf3                       ; [76 b8 00] jrl Z,0x287bf3
	sub	xwa, 0x01e0003e
	cp	xwa, 0x00000000
	jrl lt, .LFS_7c33                      ; [71 e9 00] jrl LT,0x287c33
	cp	xwa, 0x00000009
	jrl gt, .LFS_7c33                      ; [7a e0 00] jrl GT,0x287c33
	add	xwa, xwa
	add	xwa, 0x002e2e04
	ld	wa, (xwa)
	lda_24 xix, 0x287b67
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
	cpw_da	0x22AA5C, 5
	jr nz, .LFS_7b93                       ; [6e 23] jr NZ,0x287b93
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	sll	xwa, 0x02
	ld	xbc, 0x002e2922
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	push xwa
	pushw 0x002e
	pushw 0x2e00
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+12)
	jr t, .LFS_7ba3                        ; [68 10] jr T,0x287ba3
.LFS_7b93:
	ld	xwa, (0x2e2922)
	push xwa
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LFS_7ba3:
	ld	xhl, xiz
	jrl t, .LFS_7c35                       ; [78 8d 00] jrl T,0x287c35
	lds32	xhl, 1
	jrl t, .LFS_7c35                       ; [78 88 00] jrl T,0x287c35
	lds32	xhl, 1
	jrl t, .LFS_7c35                       ; [78 83 00] jrl T,0x287c35
	cpw_da	0x22AA5C, 5
	jr nz, .LFS_7bc9                       ; [6e 0e] jr NZ,0x287bc9
	lds32	xhl, 2
	cpib_da	0x22AA53, 0
	jr nz, .LFS_7bcb                       ; [6e 06] jr NZ,0x287bcb
	lds32	xhl, 0
	jr t, .LFS_7bcb                        ; [68 02] jr T,0x287bcb
.LFS_7bc9:
	lds32	xhl, 0
.LFS_7bcb:
	jr t, .LFS_7c35                        ; [68 68] jr T,0x287c35
	cpw_da	0x22AA5C, 5
	jr nz, .LFS_7be4                       ; [6e 0e] jr NZ,0x287be4
	lds32	xhl, 1
	cpib_da	0x22AA53, 0
	jr nz, .LFS_7be6                       ; [6e 06] jr NZ,0x287be6
	lds32	xhl, 0
	jr t, .LFS_7be6                        ; [68 02] jr T,0x287be6
.LFS_7be4:
	lds32	xhl, 0
.LFS_7be6:
	jr t, .LFS_7c35                        ; [68 4d] jr T,0x287c35
	lda_24 xhl, 0x22aa53
	jr t, .LFS_7c35                        ; [68 46] jr T,0x287c35
	lds32	xhl, 1
	jr t, .LFS_7c35                        ; [68 42] jr T,0x287c35
.LFS_7bf3:
	cpw_da	0x22AA5C, 5
	jr nz, .LFS_7c1e                       ; [6e 22] jr NZ,0x287c1e
	lda_24 xwa, 0x22aa4c
	calr	0xd73c
	ldw_da	bc, 0x23A092
	ldw_da	de, 0x23A094
	ldw_da	wa, 0x22AA4C
	pushw wa                                ; push WA
	ld	xwa, 0x007f0102
	calr	0xbdb0
	jr t, .LFS_7c2f                        ; [68 11] jr T,0x287c2f
.LFS_7c1e:
	pushw 0xffff
	ld	xwa, 0x007f0102
	ldw	bc, 0xffff
	ldw	de, 0xffff
	calr	0xbd9d
.LFS_7c2f:
	lds32	xhl, 0
	jr t, .LFS_7c35                        ; [68 02] jr T,0x287c35
.LFS_7c33:
	lds32	xhl, 0
.LFS_7c35:
	pop xiz                                 ; pop XIZ
	ret

	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, 0x01e00082
	jrl z, .LFS_7cfd                       ; [76 b8 00] jrl Z,0x287cfd
	sub	xwa, 0x01e0003e
	cp	xwa, 0x00000000
	jrl lt, .LFS_7d3d                      ; [71 e9 00] jrl LT,0x287d3d
	cp	xwa, 0x00000009
	jrl gt, .LFS_7d3d                      ; [7a e0 00] jrl GT,0x287d3d
	add	xwa, xwa
	add	xwa, 0x002e2e1c
	ld	wa, (xwa)
	lda_24 xix, 0x287c71
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
	cpw_da	0x22AA5C, 5
	jr nz, .LFS_7c9d                       ; [6e 23] jr NZ,0x287c9d
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	sll	xwa, 0x02
	ld	xbc, 0x002e2922
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	push xwa
	pushw 0x002e
	pushw 0x2e18
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+12)
	jr t, .LFS_7cad                        ; [68 10] jr T,0x287cad
.LFS_7c9d:
	ld	xwa, (0x2e2922)
	push xwa
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LFS_7cad:
	ld	xhl, xiz
	jrl t, .LFS_7d3f                       ; [78 8d 00] jrl T,0x287d3f
	lds32	xhl, 1
	jrl t, .LFS_7d3f                       ; [78 88 00] jrl T,0x287d3f
	lds32	xhl, 1
	jrl t, .LFS_7d3f                       ; [78 83 00] jrl T,0x287d3f
	cpw_da	0x22AA5C, 5
	jr nz, .LFS_7cd3                       ; [6e 0e] jr NZ,0x287cd3
	lds32	xhl, 2
	cpib_da	0x22AA54, 0
	jr nz, .LFS_7cd5                       ; [6e 06] jr NZ,0x287cd5
	lds32	xhl, 0
	jr t, .LFS_7cd5                        ; [68 02] jr T,0x287cd5
.LFS_7cd3:
	lds32	xhl, 0
.LFS_7cd5:
	jr t, .LFS_7d3f                        ; [68 68] jr T,0x287d3f
	cpw_da	0x22AA5C, 5
	jr nz, .LFS_7cee                       ; [6e 0e] jr NZ,0x287cee
	lds32	xhl, 1
	cpib_da	0x22AA54, 0
	jr nz, .LFS_7cf0                       ; [6e 06] jr NZ,0x287cf0
	lds32	xhl, 0
	jr t, .LFS_7cf0                        ; [68 02] jr T,0x287cf0
.LFS_7cee:
	lds32	xhl, 0
.LFS_7cf0:
	jr t, .LFS_7d3f                        ; [68 4d] jr T,0x287d3f
	lda_24 xhl, 0x22aa54
	jr t, .LFS_7d3f                        ; [68 46] jr T,0x287d3f
	lds32	xhl, 1
	jr t, .LFS_7d3f                        ; [68 42] jr T,0x287d3f
.LFS_7cfd:
	cpw_da	0x22AA5C, 5
	jr nz, .LFS_7d28                       ; [6e 22] jr NZ,0x287d28
	lda_24 xwa, 0x22aa4c
	calr	0xd632
	ldw_da	bc, 0x23A092
	ldw_da	de, 0x23A094
	ldw_da	wa, 0x22AA4C
	pushw wa                                ; push WA
	ld	xwa, 0x007f0102
	calr	0xbca6
	jr t, .LFS_7d39                        ; [68 11] jr T,0x287d39
.LFS_7d28:
	pushw 0xffff
	ld	xwa, 0x007f0102
	ldw	bc, 0xffff
	ldw	de, 0xffff
	calr	0xbc93
.LFS_7d39:
	lds32	xhl, 0
	jr t, .LFS_7d3f                        ; [68 02] jr T,0x287d3f
.LFS_7d3d:
	lds32	xhl, 0
.LFS_7d3f:
	pop xiz                                 ; pop XIZ
	ret

	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, 0x01e00082
	jrl z, .LFS_7e07                       ; [76 b8 00] jrl Z,0x287e07
	sub	xwa, 0x01e0003e
	cp	xwa, 0x00000000
	jrl lt, .LFS_7e47                      ; [71 e9 00] jrl LT,0x287e47
	cp	xwa, 0x00000009
	jrl gt, .LFS_7e47                      ; [7a e0 00] jrl GT,0x287e47
	add	xwa, xwa
	add	xwa, 0x002e2e34
	ld	wa, (xwa)
	lda_24 xix, 0x287d7b
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
	cpw_da	0x22AA5C, 5
	jr nz, .LFS_7da7                       ; [6e 23] jr NZ,0x287da7
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	sll	xwa, 0x02
	ld	xbc, 0x002e2922
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	push xwa
	pushw 0x002e
	pushw 0x2e30
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+12)
	jr t, .LFS_7db7                        ; [68 10] jr T,0x287db7
.LFS_7da7:
	ld	xwa, (0x2e2922)
	push xwa
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LFS_7db7:
	ld	xhl, xiz
	jrl t, .LFS_7e49                       ; [78 8d 00] jrl T,0x287e49
	lds32	xhl, 1
	jrl t, .LFS_7e49                       ; [78 88 00] jrl T,0x287e49
	lds32	xhl, 1
	jrl t, .LFS_7e49                       ; [78 83 00] jrl T,0x287e49
	cpw_da	0x22AA5C, 5
	jr nz, .LFS_7ddd                       ; [6e 0e] jr NZ,0x287ddd
	lds32	xhl, 2
	cpib_da	0x22AA55, 0
	jr nz, .LFS_7ddf                       ; [6e 06] jr NZ,0x287ddf
	lds32	xhl, 0
	jr t, .LFS_7ddf                        ; [68 02] jr T,0x287ddf
.LFS_7ddd:
	lds32	xhl, 0
.LFS_7ddf:
	jr t, .LFS_7e49                        ; [68 68] jr T,0x287e49
	cpw_da	0x22AA5C, 5
	jr nz, .LFS_7df8                       ; [6e 0e] jr NZ,0x287df8
	lds32	xhl, 1
	cpib_da	0x22AA55, 0
	jr nz, .LFS_7dfa                       ; [6e 06] jr NZ,0x287dfa
	lds32	xhl, 0
	jr t, .LFS_7dfa                        ; [68 02] jr T,0x287dfa
.LFS_7df8:
	lds32	xhl, 0
.LFS_7dfa:
	jr t, .LFS_7e49                        ; [68 4d] jr T,0x287e49
	lda_24 xhl, 0x22aa55
	jr t, .LFS_7e49                        ; [68 46] jr T,0x287e49
	lds32	xhl, 1
	jr t, .LFS_7e49                        ; [68 42] jr T,0x287e49
.LFS_7e07:
	cpw_da	0x22AA5C, 5
	jr nz, .LFS_7e32                       ; [6e 22] jr NZ,0x287e32
	lda_24 xwa, 0x22aa4c
	calr	0xd528
	ldw_da	bc, 0x23A092
	ldw_da	de, 0x23A094
	ldw_da	wa, 0x22AA4C
	pushw wa                                ; push WA
	ld	xwa, 0x007f0102
	calr	0xbb9c
	jr t, .LFS_7e43                        ; [68 11] jr T,0x287e43
.LFS_7e32:
	pushw 0xffff
	ld	xwa, 0x007f0102
	ldw	bc, 0xffff
	ldw	de, 0xffff
	calr	0xbb89
.LFS_7e43:
	lds32	xhl, 0
	jr t, .LFS_7e49                        ; [68 02] jr T,0x287e49
.LFS_7e47:
	lds32	xhl, 0
.LFS_7e49:
	pop xiz                                 ; pop XIZ
	ret

	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, 0x01e00082
	jrl z, .LFS_7f11                       ; [76 b8 00] jrl Z,0x287f11
	sub	xwa, 0x01e0003e
	cp	xwa, 0x00000000
	jrl lt, .LFS_7f51                      ; [71 e9 00] jrl LT,0x287f51
	cp	xwa, 0x00000009
	jrl gt, .LFS_7f51                      ; [7a e0 00] jrl GT,0x287f51
	add	xwa, xwa
	add	xwa, 0x002e2e4c
	ld	wa, (xwa)
	lda_24 xix, 0x287e85
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
	cpw_da	0x22AA5C, 5
	jr nz, .LFS_7eb1                       ; [6e 23] jr NZ,0x287eb1
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	sll	xwa, 0x02
	ld	xbc, 0x002e2922
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	push xwa
	pushw 0x002e
	pushw 0x2e48
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+12)
	jr t, .LFS_7ec1                        ; [68 10] jr T,0x287ec1
.LFS_7eb1:
	ld	xwa, (0x2e2922)
	push xwa
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LFS_7ec1:
	ld	xhl, xiz
	jrl t, .LFS_7f53                       ; [78 8d 00] jrl T,0x287f53
	lds32	xhl, 1
	jrl t, .LFS_7f53                       ; [78 88 00] jrl T,0x287f53
	lds32	xhl, 1
	jrl t, .LFS_7f53                       ; [78 83 00] jrl T,0x287f53
	cpw_da	0x22AA5C, 5
	jr nz, .LFS_7ee7                       ; [6e 0e] jr NZ,0x287ee7
	lds32	xhl, 2
	cpib_da	0x22AA56, 0
	jr nz, .LFS_7ee9                       ; [6e 06] jr NZ,0x287ee9
	lds32	xhl, 0
	jr t, .LFS_7ee9                        ; [68 02] jr T,0x287ee9
.LFS_7ee7:
	lds32	xhl, 0
.LFS_7ee9:
	jr t, .LFS_7f53                        ; [68 68] jr T,0x287f53
	cpw_da	0x22AA5C, 5
	jr nz, .LFS_7f02                       ; [6e 0e] jr NZ,0x287f02
	lds32	xhl, 1
	cpib_da	0x22AA56, 0
	jr nz, .LFS_7f04                       ; [6e 06] jr NZ,0x287f04
	lds32	xhl, 0
	jr t, .LFS_7f04                        ; [68 02] jr T,0x287f04
.LFS_7f02:
	lds32	xhl, 0
.LFS_7f04:
	jr t, .LFS_7f53                        ; [68 4d] jr T,0x287f53
	lda_24 xhl, 0x22aa56
	jr t, .LFS_7f53                        ; [68 46] jr T,0x287f53
	lds32	xhl, 1
	jr t, .LFS_7f53                        ; [68 42] jr T,0x287f53
.LFS_7f11:
	cpw_da	0x22AA5C, 5
	jr nz, .LFS_7f3c                       ; [6e 22] jr NZ,0x287f3c
	lda_24 xwa, 0x22aa4c
	calr	0xd41e
	ldw_da	bc, 0x23A092
	ldw_da	de, 0x23A094
	ldw_da	wa, 0x22AA4C
	pushw wa                                ; push WA
	ld	xwa, 0x007f0102
	calr	0xba92
	jr t, .LFS_7f4d                        ; [68 11] jr T,0x287f4d
.LFS_7f3c:
	pushw 0xffff
	ld	xwa, 0x007f0102
	ldw	bc, 0xffff
	ldw	de, 0xffff
	calr	0xba7f
.LFS_7f4d:
	lds32	xhl, 0
	jr t, .LFS_7f53                        ; [68 02] jr T,0x287f53
.LFS_7f51:
	lds32	xhl, 0
.LFS_7f53:
	pop xiz                                 ; pop XIZ
	ret



HDAE5000_FS_Read_FSB:	; 0x287F55 (832 bytes)
	; FS_Read_FSB: Initialize the FSB directory listing display.
	; Populates 24 display tile entries in RAM from a ROM template, formats
	; entry numbers (1-24 per page), copies 16-byte tiles to VRAM, then
	; registers two event handlers for the left/right file browser panes.
	;
	; The FSB supports 5 pages x 24 entries = 120 total directory slots.
	; Page selector at 0x23A090 steps by 24 (values: 0, 24, 48, 72, 96).
	;
	; 21-byte in-RAM directory entry layout (at 0x22A2CA + IZ*21):
	;   [0-3]   Header: " N:" where N=entry number (formatted by PPI_Block_Copy)
	;   [4-19]  Display tile: 16-byte text block (filename, initially spaces)
	;   [20]    Terminator: 0x09 (tab character)
	;
	; Part 1: Init loop — populate 24 directory entries from ROM template
	lda	xsp, (xsp-22)
	pushw iz                                ; push iz (compact)
	pushw 0x0781                            ; MemFill pattern (clear display buffer)
	pushw 0x0000
	lda_24 xwa, 0x22a2ca                    ; dest = FSB display buffer base
	push xwa
	call HDAE5000_MemFill			; MemFill — clear all 24 entries
	inc 0, xsp			; dealloc 8 bytes
	lds iz, 0			; IZ = 0 (entry index, 0-23)
	cp iz, 0x0018			; pre-check: 24 iterations?
	jrl nc, .LFS_RdFSB__loop_done
.LFS_RdFSB__loop:			; --- per-entry initialization ---
	pushw 0x0015                            ; size = 21 bytes
	lda_24 xwa, 0x2e2e60                    ; src = ROM template "   :                \t"
	push xwa
	ldw wa, 0x0015			; 21 bytes per entry
	mul xwa, xiz			; offset = IZ * 21
	ld xbc, 0x0022a2ca                      ; dest = display buffer + offset
	add xbc, xwa
	push xbc
	call HDAE5000_MemCopy			; MemCopy — copy ROM template to entry slot
	ldw_da xwa, 0x23a090                   ; WA = page_base (0/24/48/72/96)
	add wa, iz                              ; WA = page_base + index
	inc 1, wa                               ; WA = entry_number (1-based)
	pushw wa                                ; push entry number
	pushw 0x002e		; format spec offset (decimal number formatting)
	pushw 0x2e76		; format handler ROM address
	lda xwa, (xsp + 0x12)                   ; XWA = entry buffer ptr
	push xwa
	call HDAE5000_PPI_Block_Copy            ; format entry number into header bytes [0-2]
	lda xwa, (xsp + 0x16)                   ; XWA = entry buffer ptr
	push xwa
	call HDAE5000_Display_Buffer_Validate			; Display_Buffer_Validate — validate display string
	lda xsp, (xsp + 0x18)
	pushw hl                                ; push validated length
	lda xwa, (xsp + 0x04)                   ; XWA = validated string ptr
	push xwa
	ldw wa, 0x0015
	mul xwa, xiz
	ld xbc, 0x0022a2ca
	add xbc, xwa
	push xbc                                ; dest = entry buffer
	call HDAE5000_MemCopy                           ; MemCopy — copy validated data back
	lda xsp, (xsp + 0x0a)
	ldw_da xwa, 0x23a090                   ; WA = page_base
	add wa, iz                              ; WA = page_base + index (0-based display row)
	call HDAE5000_Calculate_Tile_Address     ; XHL = VRAM address for this tile row
	pushw 0x0010                            ; size = 16 bytes (display tile only)
	push xhl                                ; dest = VRAM tile address
	ldw wa, 0x0015
	mul xwa, xiz
	inc 4, wa			; offset + 4 → skip 4-byte header, point to tile data
	extz xwa
	ld xbc, 0x0022a2ca
	add xbc, xwa                            ; src = entry[4..19] = 16-byte display tile
	push xbc
	call HDAE5000_MemCopy                           ; MemCopy — copy tile to VRAM
	lda xsp, (xsp + 0x0a)
	inc 1, iz			; IZ++ (next entry)
	cp iz, 0x0018
	jrl c, .LFS_RdFSB__loop	; loop while IZ < 24
.LFS_RdFSB__loop_done:
	; --- Register event handlers with UI framework ---
	; The UI framework uses a vtable-based dispatch system:
	;   0x23A1A2 → UI framework object pointer
	;   object + 0x0E0A → active display context
	;   context + 0x0124 → RegisterEventHandler method
	;   context + 0x050C → GetCurrentSelection method
	;   context + 0x0100 → SetDisplayCell method
	lda_24 xwa, 0x22a2ca                    ; XWA = display buffer base (handler data ptr)
	ld xde, xwa
	ldl_da xwa, 0x23a1a2                   ; XWA = UI framework ptr
	ld_sril xwa, (xwa + 0x0e0a)             ; XWA = active display context
	ld_sril xhl, (xwa + 0x0124)             ; XHL = RegisterEventHandler method
	ld xwa, 0x007f00fb                      ; params: handlerA, VRAM tile ID 0xFB
	ld xbc, 0x01ea000a                      ; event mask: register handler A
	call (xhl)                              ; RegisterEventHandler(handlerA)
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0124)
	ld xwa, 0x007f00fb                      ; params: same tile ID
	ld xbc, 0x01c0000f                      ; event mask: register completion handler
	ld xde, 0xffffffff                      ; no filter
	call (xhl)                              ; RegisterEventHandler(completion)
	popw iz                                 ; pop iz (compact)
	lda xsp, (xsp + 0x16)		; dealloc stack frame
	ret
	;
	; Part 2: Event handler A — left pane of file browser (0x288041)
	; Called by UI framework when user interacts with left column.
	; Input: XWA=context, XBC=event_code, XDE=event_param
	; Events handled:
	;   0x01C00007: Action event (sub-codes: 0x0B=navigate, 0x8A=validate string)
	;   0x01E0003A: Copy display tile data (16 bytes from tile buffer)
	;   0x01E0007C: Query tile size → returns 16
	;   0x01E00084: Acknowledge/no-op → returns 0
	;   0x01E00086: Copy display tile data + clear dirty flag
.LFS_RdFSB__handlerA:
	push xiz
	ld xiz, xwa			; save UI context
	cp xbc, 0x01c00007
	jr z, .LFS_RdFSB__a_evt07
	cp xbc, 0x01e0007c
	jr z, .LFS_RdFSB__a_evt7c
	cp xbc, 0x01e00084
	jr z, .LFS_RdFSB__a_evt84
	cp xbc, 0x01e00086
	jr z, .LFS_RdFSB__a_evt86
	cp xbc, 0x01e0003a
	jr z, .LFS_RdFSB__a_evt3a
	lds32 xhl, 0			; unrecognized event → return 0
	jrl t, .LFS_RdFSB__a_exit
.LFS_RdFSB__a_evt3a:			; EVT 0x3A: Read tile — copy 16-byte tile to caller
	pushw 0x0010                            ; size = 16 bytes (tile data)
	lda_24 xwa, 0x23a06e                    ; src = current tile buffer
	push xwa
	push xde                                ; dest = caller's buffer (from event param)
	call HDAE5000_MemCopy_Reverse
	lda xsp, (xsp + 0x0a)
	ld xhl, xiz                             ; return context pointer
	jrl t, .LFS_RdFSB__a_exit
.LFS_RdFSB__a_evt86:			; EVT 0x86: Write tile + clear dirty flag
	pushw 0x0010                            ; size = 16 bytes
	push xde                                ; src = caller's new tile data
	pushw 0x0023
	pushw 0xa06e		; dest = tile buffer at 0x23A06E
	call HDAE5000_MemCopy_Reverse
	lda xsp, (xsp + 0x0a)
	stib_da 0x23a07e, 0x00	; clear dirty flag (tile updated)
	ld xhl, xiz
	jrl t, .LFS_RdFSB__a_exit
.LFS_RdFSB__a_evt84:                           ; EVT 0x84: Acknowledge — no action needed
	lds32 xhl, 0
	jrl t, .LFS_RdFSB__a_exit
.LFS_RdFSB__a_evt7c:                           ; EVT 0x7C: Query tile size → 16 bytes
	ld xhl, 0x00000010
	jrl t, .LFS_RdFSB__a_exit
.LFS_RdFSB__a_evt07:			; EVT 0x07: Action — dispatch on sub-code in XDE
	cp xde, 0x0000000b
	jr z, .LFS_RdFSB__a_case0b
	cp xde, 0x0000008a
	jrl nz, .LFS_RdFSB__a_done
	; Sub-code 0x8A: Validate filename string and update display
	lda_24 xwa, 0x22ad0a                    ; XWA = filename string buffer
	calr HDAE5000_Validate_String            ; validate/sanitize string
	ld xiz, xhl                              ; XIZ = validated string ptr (or NULL)
	ld xwa, xiz
	or xwa, xwa
	jrl z, .LFS_RdFSB__a_done               ; skip if validation failed (NULL)
	ld xwa, xiz
	push xwa
	call HDAE5000_Display_Buffer_Validate                            ; Display_Buffer_Validate
	pushw hl                                ; push validated length
	ld xwa, xiz
	push xwa
	lda_24 xwa, 0x23a06e                    ; dest = current tile buffer
	push xwa
	call HDAE5000_MemCopy                            ; MemCopy — copy validated name to tile
	lda xsp, (xsp + 0x0e)
	ldl_da xwa, 0x23a1a2                   ; UI framework → GetCurrentSelection
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xix, (xwa + 0x050c)             ; XIX = GetCurrentSelection method
	call (xix)                               ; XHL = current selection index
	lda_24 xwa, 0x23a06e                    ; XDE = tile buffer ptr
	ld xbc, xwa
	ld xwa, xhl                              ; XWA = selection index
	ld xde, xbc                              ; XDE = tile data
	ldl_da xbc, 0x23a1a2                   ; UI framework → SetDisplayCell
	ld_sril xbc, (xbc + 0x0e0a)
	ld_sril xhl, (xbc + 0x0100)             ; XHL = SetDisplayCell method
	ld xbc, 0x01e00086                       ; event code = write tile + clear dirty
	call (xhl)                               ; SetDisplayCell(selection, tile, 0x86)
	jr t, .LFS_RdFSB__a_done
.LFS_RdFSB__a_case0b:			; Sub-code 0x0B: Navigate to item — refresh display
	ldl_da xwa, 0x23a1a2                   ; GetCurrentSelection
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xix, (xwa + 0x050c)
	call (xix)
	lda_24 xwa, 0x23a06e
	ld xbc, xwa
	ld xwa, xhl
	ld xde, xbc
	ldl_da xbc, 0x23a1a2                   ; SetDisplayCell with evt 0x3A (read tile)
	ld_sril xbc, (xbc + 0x0e0a)
	ld_sril xhl, (xbc + 0x0100)
	ld xbc, 0x01e0003a
	call (xhl)
	ldw_da xwa, 0x23a096                   ; WA = display row base
	lda_24 xbc, 0x23a06e                    ; XBC = tile buffer
	ld xde, 0x007f00f0                       ; params: left pane tile ID 0xF0
	calr HDAE5000_Menu_Callback              ; update menu display
	calr HDAE5000_FS_Read_FSB	; recursive call — refresh page
.LFS_RdFSB__a_done:
	lds32 xhl, 0
.LFS_RdFSB__a_exit:
	pop xiz
	ret
	;
	; Part 3: Event handler B — right pane of file browser (0x288169)
	; Same event handling as handler A, but operates on the right display column.
	; Key differences: uses tile ID 0x0163 (right pane), and sub-code 0x0B
	; calls FS_Write_FSB instead of FS_Read_FSB (save operation).
.LFS_RdFSB__handlerB:
	push xiz
	ld xiz, xwa			; save UI context
	cp xbc, 0x01c00007
	jr z, .LFS_RdFSB__b_evt07
	cp xbc, 0x01e0007c
	jr z, .LFS_RdFSB__b_evt7c
	cp xbc, 0x01e00084
	jr z, .LFS_RdFSB__b_evt84
	cp xbc, 0x01e00086
	jr z, .LFS_RdFSB__b_evt86
	cp xbc, 0x01e0003a
	jr z, .LFS_RdFSB__b_evt3a
	lds32 xhl, 0			; unrecognized event → return 0
	jrl t, .LFS_RdFSB__b_exit
.LFS_RdFSB__b_evt3a:			; EVT 0x3A: Read tile — copy 16-byte tile to caller
	pushw 0x0010
	lda_24 xwa, 0x23a06e
	push xwa
	push xde
	call HDAE5000_MemCopy_Reverse
	lda xsp, (xsp + 0x0a)
	ld xhl, xiz
	jrl t, .LFS_RdFSB__b_exit
.LFS_RdFSB__b_evt86:			; EVT 0x86: Write tile + clear dirty flag
	pushw 0x0010
	push xde
	pushw 0x0023
	pushw 0xa06e		; dest = tile buffer at 0x23A06E
	call HDAE5000_MemCopy_Reverse
	lda xsp, (xsp + 0x0a)
	stib_da 0x23a07e, 0x00	; clear dirty flag
	ld xhl, xiz
	jrl t, .LFS_RdFSB__b_exit
.LFS_RdFSB__b_evt84:                           ; EVT 0x84: Acknowledge — no-op
	lds32 xhl, 0
	jrl t, .LFS_RdFSB__b_exit
.LFS_RdFSB__b_evt7c:                           ; EVT 0x7C: Query tile size → 16 bytes
	ld xhl, 0x00000010
	jrl t, .LFS_RdFSB__b_exit
.LFS_RdFSB__b_evt07:			; EVT 0x07: Action — dispatch on sub-code
	cp xde, 0x0000000b
	jr z, .LFS_RdFSB__b_case0b
	cp xde, 0x0000008a
	jrl nz, .LFS_RdFSB__b_done
	; Sub-code 0x8A: Validate filename and update display (same as handler A)
	lda_24 xwa, 0x22ad0a                    ; filename string buffer
	calr HDAE5000_Validate_String
	ld xiz, xhl
	ld xwa, xiz
	or xwa, xwa
	jrl z, .LFS_RdFSB__b_done
	ld xwa, xiz
	push xwa
	call HDAE5000_Display_Buffer_Validate                            ; Display_Buffer_Validate
	pushw hl                                ; validated length
	ld xwa, xiz
	push xwa
	lda_24 xwa, 0x23a06e
	push xwa
	call HDAE5000_MemCopy                            ; MemCopy — name to tile buffer
	lda xsp, (xsp + 0x0e)
	ldl_da xwa, 0x23a1a2                   ; GetCurrentSelection
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xix, (xwa + 0x050c)
	call (xix)
	lda_24 xwa, 0x23a06e
	ld xbc, xwa
	ld xwa, xhl
	ld xde, xbc
	ldl_da xbc, 0x23a1a2                   ; SetDisplayCell(selection, tile, 0x86)
	ld_sril xbc, (xbc + 0x0e0a)
	ld_sril xhl, (xbc + 0x0100)
	ld xbc, 0x01e00086
	call (xhl)
	jr t, .LFS_RdFSB__b_done
.LFS_RdFSB__b_case0b:			; Sub-code 0x0B: Navigate — save and refresh
	ldl_da xwa, 0x23a1a2                   ; GetCurrentSelection
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xix, (xwa + 0x050c)
	call (xix)
	lda_24 xwa, 0x23a06e
	ld xbc, xwa
	ld xwa, xhl
	ld xde, xbc
	ldl_da xbc, 0x23a1a2                   ; SetDisplayCell with evt 0x3A
	ld_sril xbc, (xbc + 0x0e0a)
	ld_sril xhl, (xbc + 0x0100)
	ld xbc, 0x01e0003a
	call (xhl)
	ldw_da xwa, 0x23a096                   ; WA = display row base
	lda_24 xbc, 0x23a06e                    ; XBC = tile buffer
	ld xde, 0x007f0163                       ; params: right pane tile ID 0x0163
	calr HDAE5000_Menu_Callback              ; update menu display
	lds wa, 1                                ; WA = operation mode 1
	lds bc, 2                                ; BC = sector count 2
	calr HDAE5000_FS_Write_FSB               ; → write FSB to disk (save operation)
.LFS_RdFSB__b_done:
	lds32 xhl, 0
.LFS_RdFSB__b_exit:
	pop xiz
	ret

HDAE5000_FS_Write_FSB:	; 0x288295 (5072 bytes)
; FS_Write_FSB: 0x288295 (5072 bytes) — disassembled from original ROM

	lda	xsp, (xsp-32)
	pushw iz                                ; push IZ
	ld	(xsp+30), c
	ld	(xsp+32), a
	cp	(xsp+30), 0x00
	jr z, .LFWF_82ac                       ; [66 07] jr Z,0x2882ac
	cp	(xsp+30), 0x02
	jrl nz, .LFWF_8390                     ; [7e e4 00] jrl NZ,0x288390
.LFWF_82ac:
	pushw 0x0020
	pushw 0x0000
	lda_24 xwa, 0x22a058
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x2eac
	pushw 0x0022
	pushw 0xa058
	call HDAE5000_StrCopy
	ldw_da	wa, 0x23A096
	inc	1, wa
	pushw wa                                ; push WA
	pushw 0x002e
	pushw 0x2eb6
	lda	xwa, (xsp+30)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+26)
	lda	xwa, (xsp+8)
	push xwa
	pushw 0x0022
	pushw 0xa058
	call HDAE5000_StrCopy
	pushw 0x002e
	pushw 0x2ebc
	pushw 0x0022
	pushw 0xa058
	call HDAE5000_StrCopy
	lda	xsp, (xsp+16)
	pushw 0x0010
	ldw_da	wa, 0x23A096
	call HDAE5000_Calculate_Tile_Address
	push xhl
	pushw 0x0022
	pushw 0xa058
	call 0x29af8f
	pushw 0x002e
	pushw 0x2ebe
	pushw 0x0022
	pushw 0xa058
	call HDAE5000_StrCopy
	lda	xsp, (xsp+18)
	ld	a, (xsp+32)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	lda_24 xbc, 0x2e2e7c
	ld_sril3 xde, 0x07, 0xE4, 0xE0	; ld XDE,(XBC+WA)
	lda_24 xwa, 0x22a058
	ld	xbc, xwa
	ld	xwa, xde
	ld	xde, xbc
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01ea000a
	call	(xhl)
	ld	a, (xsp+32)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	lda_24 xbc, 0x2e2e7c
	ld_sril3 xwa, 0x07, 0xE4, 0xE0	; ld XWA,(XBC+WA)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01c0000f
	ld	xde, 0xffffffff
	call	(xhl)
.LFWF_8390:
	cp	(xsp+30), 0x00
	jr z, .LFWF_839d                       ; [66 07] jr Z,0x28839d
	cp	(xsp+30), 0x02
	jrl nz, .LFWF_84e6                     ; [7e 49 01] jrl NZ,0x2884e6
.LFWF_839d:
	lds	iz, 0
	cp	iz, 0x0010
	jrl nc, .LFWF_8486                     ; [7f e0 00] jrl NC,0x288486
.LFWF_83a6:
	pushw 0x0023
	lda_24 xwa, 0x2e2ec0
	push xwa
	ldw	wa, 0x0025
	mul	xwa, xiz
	inc	2, wa
	extz xwa
	ld	xbc, 0x0022b020
	add	xbc, xwa
	push xbc
	call HDAE5000_MemCopy
	ldw_da	wa, 0x22B272
	add	wa, iz
	inc	1, wa
	pushw wa                                ; push WA
	pushw 0x002e
	pushw 0x2ee4
	lda	xwa, (xsp+24)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xwa, (xsp+28)
	push xwa
	call HDAE5000_Display_Buffer_Validate
	lda	xsp, (xsp+24)
	pushw hl                                ; push HL
	lda	xwa, (xsp+10)
	push xwa
	ldw	wa, 0x0025
	mul	xwa, xiz
	ld	xbc, 0x0022b020
	add	xbc, xwa
	push xbc
	call HDAE5000_MemCopy
	lda	xsp, (xsp+10)
	ldw_da	bc, 0x22B272
	add	bc, iz
	ldw_da	wa, 0x23A096
	call HDAE5000_Resolve_Cell_Address
	pushw 0x001a
	push xhl
	ldw	wa, 0x0025
	mul	xwa, xiz
	inc	3, wa
	extz xwa
	ld	xbc, 0x0022b020
	add	xbc, xwa
	push xbc
	call HDAE5000_MemCopy
	lda	xsp, (xsp+10)
	ldw_da	bc, 0x22B272
	add	bc, iz
	lda	xwa, (xsp+2)
	ld	xde, xwa
	ldw_da	wa, 0x23A096
	call 0x28fbf3
	cp	hl, 0xffff
	jr z, .LFWF_847d                       ; [66 36] jr Z,0x28847d
	cp	(xsp+6), 0x01
	jr nz, .LFWF_8462                      ; [6e 15] jr NZ,0x288462
	ldw	wa, 0x0025
	mul	xwa, xiz
	add	wa, 0x0020
	extz xwa
	ld	xbc, 0x0022b020
	add	xbc, xwa
	ld	(xbc), 0x2a
.LFWF_8462:
	cp	(xsp+7), 0x01
	jr nz, .LFWF_847d                      ; [6e 15] jr NZ,0x28847d
	ldw	wa, 0x0025
	mul	xwa, xiz
	add	wa, 0x0023
	extz xwa
	ld	xbc, 0x0022b020
	add	xbc, xwa
	ld	(xbc), 0x2a
.LFWF_847d:
	inc	1, iz
	cp	iz, 0x0010
	jrl c, .LFWF_83a6                      ; [77 20 ff] jrl C,0x2883a6
.LFWF_8486:
	ld	a, (xsp+32)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	lda_24 xbc, 0x2e2e84
	ld_sril3 xde, 0x07, 0xE4, 0xE0	; ld XDE,(XBC+WA)
	lda_24 xwa, 0x22b020
	ld	xbc, xwa
	ld	xwa, xde
	ld	xde, xbc
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01ea000a
	call	(xhl)
	ld	a, (xsp+32)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	lda_24 xbc, 0x2e2e84
	ld_sril3 xwa, 0x07, 0xE4, 0xE0	; ld XWA,(XBC+WA)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01c0000f
	ld	xde, 0xffffffff
	call	(xhl)
.LFWF_84e6:
	pushw 0x0010
	pushw 0x0000
	lda_24 xwa, 0x22a078
	push xwa
	call HDAE5000_MemFill
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+2)
	ld	xde, xwa
	ldw_da	wa, 0x23A096
	ldw_da	bc, 0x23A098
	call 0x28fbf3
	ld	iz, hl
	ld	wa, iz
	cp	wa, 0xffff
	jr z, .LFWF_8534                       ; [66 1f] jr Z,0x288534
	ld	wa, (xsp+4)
	inc	1, wa
	pushw wa                                ; push WA
	ld	wa, (xsp+4)
	inc	1, wa
	pushw wa                                ; push WA
	pushw 0x002e
	pushw 0x2eea
	lda	xwa, (xsp+16)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+12)
	jr t, .LFWF_8544                       ; [68 10] jr T,0x288544
.LFWF_8534:
	pushw 0x002e
	pushw 0x2efe
	lda	xwa, (xsp+12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	inc 0, xsp                              ; inc 0,XSP
.LFWF_8544:
	lda	xwa, (xsp+8)
	push xwa
	call HDAE5000_Display_Buffer_Validate
	pushw hl                                ; push HL
	lda	xwa, (xsp+14)
	push xwa
	lda_24 xwa, 0x22a078
	push xwa
	call HDAE5000_MemCopy
	lda	xsp, (xsp+14)
	ld	a, (xsp+32)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	lda_24 xbc, 0x2e2e8c
	ld_sril3 xde, 0x07, 0xE4, 0xE0	; ld XDE,(XBC+WA)
	lda_24 xwa, 0x22a078
	ld	xbc, xwa
	ld	xwa, xde
	ld	xde, xbc
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01ea000a
	call	(xhl)
	ld	a, (xsp+32)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	lda_24 xbc, 0x2e2e8c
	ld_sril3 xwa, 0x07, 0xE4, 0xE0	; ld XWA,(XBC+WA)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01c0000f
	ld	xde, 0xffffffff
	call	(xhl)
	cp	iz, 0xffff
	jr z, .LFWF_85ee                       ; [66 2a] jr Z,0x2885ee
	ld	wa, (xsp+2)
	ld	bc, (xsp+4)
	call HDAE5000_Table_Lookup
	ld	iz, hl
	ld	a, (xsp+32)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	lda_24 xbc, 0x2e2e94
	ld_sril3 xwa, 0x07, 0xE4, 0xE0	; ld XWA,(XBC+WA)
	ld	bc, (xsp+2)
	ld	de, (xsp+4)
	pushw iz                                ; push IZ
	calr	0xb3e0
	jr t, .LFWF_860c                       ; [68 1e] jr T,0x28860c
.LFWF_85ee:
	ld	a, (xsp+32)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	lda_24 xbc, 0x2e2e94
	ld_sril3 xwa, 0x07, 0xE4, 0xE0	; ld XWA,(XBC+WA)
	pushw 0xffff
	ldw	bc, 0xffff
	ldw	de, 0xffff
	calr	0xb3c0
.LFWF_860c:
	cp	(xsp+30), 0x02
	jr z, .LFWF_8666                       ; [66 54] jr Z,0x288666
	ld	a, (xsp+32)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	lda_24 xbc, 0x2e2e9c
	ld_sril3 xwa, 0x07, 0xE4, 0xE0	; ld XWA,(XBC+WA)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01c0000d
	lds32	xde, 0
	call	(xhl)
	ld	a, (xsp+32)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	lda_24 xbc, 0x2e2ea4
	ld_sril3 xwa, 0x07, 0xE4, 0xE0	; ld XWA,(XBC+WA)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01c0000d
	lds32	xde, 0
	call	(xhl)
.LFWF_8666:
	popw iz                                 ; pop IZ
	lda	xsp, (xsp+32)
	ret

	push xiz
	ld	xiz, xde
	cp	xbc, 0x01ea0000
	jrl z, .LFWF_87e6                      ; [76 6f 01] jrl Z,0x2887e6
	cp	xbc, 0x01ea0001
	jrl z, .LFWF_87ac                      ; [76 2c 01] jrl Z,0x2887ac
	cp	xbc, 0x01ea0008
	jrl z, .LFWF_875c                      ; [76 d3 00] jrl Z,0x28875c
	cp	xbc, 0x01ea0007
	jrl z, .LFWF_8727                      ; [76 95 00] jrl Z,0x288727
	cp	xbc, 0x01ea0006
	jrl z, .LFWF_8727                      ; [76 8c 00] jrl Z,0x288727
	cp	xbc, 0x01c00007
	jrl nz, .LFWF_881e                     ; [7e 7a 01] jrl NZ,0x28881e
	ld	xde, xiz
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xix, (xwa + 0x0100)
	ld	xwa, 0x02600024
	ld	xbc, 0x01e00029
	call	(xix)
	cp	xhl, 0x00000007
	jr z, .LFWF_871a                       ; [66 51] jr Z,0x28871a
	cp	xhl, 0x00000006
	jr z, .LFWF_870d                       ; [66 3c] jr Z,0x28870d
	cp	xhl, 0x00000005
	jr z, .LFWF_8700                       ; [66 27] jr Z,0x288700
	cp	xhl, 0x00000001
	jr z, .LFWF_86f3                       ; [66 12] jr Z,0x2886f3
	or xhl, xhl                             ; or XHL,XHL
	jrl nz, .LFWF_881e                     ; [7e 38 01] jrl NZ,0x28881e
	stiw_da	0x23A090, 0
	calr	0xf865
	jrl t, .LFWF_881e                      ; [78 2b 01] jrl T,0x28881e
.LFWF_86f3:
	stiw_da	0x23A090, 24
	calr	0xf858
	jrl t, .LFWF_881e                      ; [78 1e 01] jrl T,0x28881e
.LFWF_8700:
	stiw_da	0x23A090, 48
	calr	0xf84b
	jrl t, .LFWF_881e                      ; [78 11 01] jrl T,0x28881e
.LFWF_870d:
	stiw_da	0x23A090, 72
	calr	0xf83e
	jrl t, .LFWF_881e                      ; [78 04 01] jrl T,0x28881e
.LFWF_871a:
	stiw_da	0x23A090, 96
	calr	0xf831
	jrl t, .LFWF_881e                      ; [78 f7 00] jrl T,0x28881e
.LFWF_8727:
	ldw_da	bc, 0x23A090
	ld	wa, iz
	add	wa, bc
	ld	(0x23a096), wa
	lds	wa, 0
	lds	bc, 2
	calr	0xfb59
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f013a
	ld	xbc, 0x01c00001
	lds32	xde, 0
	call	(xhl)
	jrl t, .LFWF_881e                      ; [78 c2 00] jrl T,0x28881e
.LFWF_875c:
	ldw_da	wa, 0x23A090
	ld	bc, iz
	add	bc, wa
	ld	(0x23a096), bc
	ld	wa, bc
	call HDAE5000_Calculate_Tile_Address
	ld	xde, xhl
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0250)
	ld	xwa, 0x012a0017
	ld	xbc, 0x01e00086
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f0134
	ld	xbc, 0x01c00001
	lds32	xde, 0
	call	(xhl)
	jr t, .LFWF_881e                       ; [68 72] jr T,0x28881e
.LFWF_87ac:
	cpw_da	0x23A090, 24
	jr lt, .LFWF_881e                      ; [61 69] jr LT,0x28881e
	subdi16_24	0x23A090, 24
	calr	0xf796
	ld	xwa, xiz
	add	xwa, 0x00000018
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f00fb
	ld	xbc, 0x01ea0003
	call	(xhl)
	jr t, .LFWF_881e                       ; [68 38] jr T,0x28881e
.LFWF_87e6:
	cpw_da	0x23A090, 96
	jr ge, .LFWF_881e                      ; [69 2f] jr GE,0x28881e
	adddi16_24	0x23A090, 24
	calr	0xf75c
	ld	xwa, xiz
	sub	xwa, 0x00000018
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f00fb
	ld	xbc, 0x01ea0003
	call	(xhl)
.LFWF_881e:
	lds32	xhl, 0
	pop xiz                                 ; pop XIZ
	ret

	dec	6, xsp
	push xiz
	ld	xiz, xde
	cp	xbc, 0x01ea0002
	jrl z, .LFWF_8c05                      ; [76 d5 03] jrl Z,0x288c05
	cp	xbc, 0x01ea0000
	jrl z, .LFWF_8b83                      ; [76 4a 03] jrl Z,0x288b83
	cp	xbc, 0x01ea0001
	jrl z, .LFWF_8aff                      ; [76 bd 02] jrl Z,0x288aff
	cp	xbc, 0x01ea0008
	jrl z, .LFWF_8a75                      ; [76 2a 02] jrl Z,0x288a75
	cp	xbc, 0x01ea0006
	jrl z, .LFWF_89a8                      ; [76 54 01] jrl Z,0x2889a8
	cp	xbc, 0x01c00007
	jrl z, .LFWF_8c1a                      ; [76 bd 03] jrl Z,0x288c1a
	cp	xbc, 0x01ca0001
	jr z, .LFWF_88bf                       ; [66 5a] jr Z,0x2888bf
	cp	xbc, 0x01ca0000
	jr z, .LFWF_8896                       ; [66 29] jr Z,0x288896
	cp	xbc, 0x01c00001
	jrl nz, .LFWF_8c1a                     ; [7e a4 03] jrl NZ,0x288c1a
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f0148
	ld	xbc, 0x01ea0002
	lds32	xde, 0
	call	(xhl)
	jrl t, .LFWF_8c1a                      ; [78 84 03] jrl T,0x288c1a
.LFWF_8896:
	ld	xbc, 0x01ca0001
	push xbc
	lds32	xbc, 0
	push xbc
	ld	xbc, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0410)
	ld	xwa, 0x00000053
	ld	xde, 0xffffffff
	call	(xhl)
	jrl t, .LFWF_8c1a                      ; [78 5b 03] jrl T,0x288c1a
.LFWF_88bf:
	cpib_da	0x22AD9A, 1
	jrl nz, .LFWF_8c1a                     ; [7e 52 03] jrl NZ,0x288c1a
	ldw_da	iz, 0x22AD96
	ldw_da	wa, 0x22AD98
	inc	1, wa
	ld	qiz, wa
	cp	wa, 0x0020
	jr c, .LFWF_88ec                       ; [67 0f] jr C,0x2888ec
	inc	1, iz
	ld	wa, iz
	cp	wa, 0x0078
	jr c, .LFWF_88e9                       ; [67 02] jr C,0x2888e9
	lds	iz, 0
.LFWF_88e9:
	ld	qiz, 0
.LFWF_88ec:
	lda	xwa, (xsp+4)
	ld	xde, xwa
	ld	wa, iz
	ld	bc, qiz
	call 0x28fbf3
	cp	hl, 0xffff
	jrl z, .LFWF_899f                      ; [76 9e 00] jrl Z,0x28899f
	cp	(xsp+9), 0x01
	jr nz, .LFWF_891c                      ; [6e 15] jr NZ,0x28891c
	stib_da	0x22AD9A, 1
	ld	(0x22ad96), iz
	ld	wa, qiz
	ld	(0x22ad98), wa
	jr t, .LFWF_8922                       ; [68 06] jr T,0x288922
.LFWF_891c:
	stib_da	0x22AD9A, 0
.LFWF_8922:
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	call HDAE5000_Table_Lookup
	ld	iz, hl
	ld	de, iz
	pushw 0x0000
	ld	xwa, 0x007f013a
	push xwa
	ld	wa, (xsp+10)
	ld	bc, (xsp+12)
	calr	0x25f6
	cp	hl, 0xffff
	jrl z, .LFWF_8c1a                      ; [76 d1 02] jrl Z,0x288c1a
	cpib_da	0x229DAC, 2
	jr nz, .LFWF_897a                      ; [6e 29] jr NZ,0x28897a
	ld	wa, iz
	and	wa, 0x0100
	cp	wa, 0x0100
	jr nz, .LFWF_897a                      ; [6e 1d] jr NZ,0x28897a
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f02f0
	ld	xbc, 0x01c00001
	lds32	xde, 0
	call	(xhl)
.LFWF_897a:
	cp	(xsp+8), 0x01
	jrl nz, .LFWF_8c1a                     ; [7e 99 02] jrl NZ,0x288c1a
	pushw 0x0001
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x0120)
	ldw	wa, 0x0048
	lds	bc, 5
	lds	de, 1
	call	(xhl)
	jrl t, .LFWF_8c1a                      ; [78 7b 02] jrl T,0x288c1a
.LFWF_899f:
	stib_da	0x22AD9A, 0
	jrl t, .LFWF_8c1a                      ; [78 72 02] jrl T,0x288c1a
.LFWF_89a8:
	ld	bc, iz
	ldw_da	wa, 0x22B272
	add	wa, bc
	ld	(0x23a098), wa
	lda	xwa, (xsp+4)
	ld	xde, xwa
	ldw_da	wa, 0x23A096
	ldw_da	bc, 0x23A098
	call 0x28fbf3
	cp	hl, 0xffff
	jrl z, .LFWF_8c1a                      ; [76 4a 02] jrl Z,0x288c1a
	cp	(xsp+9), 0x01
	jr nz, .LFWF_89f2                      ; [6e 1c] jr NZ,0x2889f2
	stib_da	0x22AD9A, 1
	ldw_da	wa, 0x23A096
	ld	(0x22ad96), wa
	ldw_da	wa, 0x23A098
	ld	(0x22ad98), wa
	jr t, .LFWF_89f8                       ; [68 06] jr T,0x2889f8
.LFWF_89f2:
	stib_da	0x22AD9A, 0
.LFWF_89f8:
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	call HDAE5000_Table_Lookup
	ld	iz, hl
	ld	de, iz
	pushw 0x0000
	ld	xwa, 0x007f013a
	push xwa
	ld	wa, (xsp+10)
	ld	bc, (xsp+12)
	calr	0x2520
	cp	hl, 0xffff
	jrl z, .LFWF_8c1a                      ; [76 fb 01] jrl Z,0x288c1a
	cpib_da	0x229DAC, 2
	jr nz, .LFWF_8a50                      ; [6e 29] jr NZ,0x288a50
	ld	wa, iz
	and	wa, 0x0100
	cp	wa, 0x0100
	jr nz, .LFWF_8a50                      ; [6e 1d] jr NZ,0x288a50
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f02f0
	ld	xbc, 0x01c00001
	lds32	xde, 0
	call	(xhl)
.LFWF_8a50:
	cp	(xsp+8), 0x01
	jrl nz, .LFWF_8c1a                     ; [7e c3 01] jrl NZ,0x288c1a
	pushw 0x0001
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x0120)
	ldw	wa, 0x0048
	lds	bc, 5
	lds	de, 1
	call	(xhl)
	jrl t, .LFWF_8c1a                      ; [78 a5 01] jrl T,0x288c1a
.LFWF_8a75:
	ld	bc, iz
	ldw_da	wa, 0x22B272
	add	wa, bc
	ld	(0x23a098), wa
	lds	wa, 1
	lds	bc, 0
	calr	0xf80b
	ldw_da	wa, 0x23A096
	call HDAE5000_Validate_Cell_Coords
	cp	hl, 0xffff
	jr z, .LFWF_8ab9                       ; [66 20] jr Z,0x288ab9
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f0163
	ld	xbc, 0x01c00001
	lds32	xde, 0
	call	(xhl)
	jrl t, .LFWF_8c1a                      ; [78 61 01] jrl T,0x288c1a
.LFWF_8ab9:
	ldw_da	wa, 0x23A096
	call HDAE5000_Calculate_Tile_Address
	ld	xde, xhl
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0250)
	ld	xwa, 0x012a0017
	ld	xbc, 0x01e00086
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f0244
	ld	xbc, 0x01c00001
	lds32	xde, 0
	call	(xhl)
	jrl t, .LFWF_8c1a                      ; [78 1b 01] jrl T,0x288c1a
.LFWF_8aff:
	cpw_da	0x22B272, 0
	jr nz, .LFWF_8b4d                      ; [6e 45] jr NZ,0x288b4d
	cpw_da	0x23A096, 0
	jrl z, .LFWF_8c1a                      ; [76 08 01] jrl Z,0x288c1a
	decdi16_24	1, 0x23A096
	stiw_da	0x22B272, 16
	lds	wa, 0
	lds	bc, 0
	calr	0xf770
	ld	xwa, xiz
	add	xwa, 0x00000010
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f0148
	ld	xbc, 0x01ea0003
	call	(xhl)
	jrl t, .LFWF_8c1a                      ; [78 cd 00] jrl T,0x288c1a
.LFWF_8b4d:
	stiw_da	0x22B272, 0
	lds	wa, 0
	lds	bc, 0
	calr	0xf73a
	ld	xwa, xiz
	add	xwa, 0x00000010
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f0148
	ld	xbc, 0x01ea0003
	call	(xhl)
	jrl t, .LFWF_8c1a                      ; [78 97 00] jrl T,0x288c1a
.LFWF_8b83:
	cpw_da	0x22B272, 0
	jr z, .LFWF_8bd0                       ; [66 44] jr Z,0x288bd0
	cpw_da	0x23A096, 119
	jrl nc, .LFWF_8c1a                     ; [7f 84 00] jrl NC,0x288c1a
	incdi16_24	1, 0x23A096
	stiw_da	0x22B272, 0
	lds	wa, 0
	lds	bc, 0
	calr	0xf6ec
	ld	xwa, xiz
	sub	xwa, 0x00000010
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f0148
	ld	xbc, 0x01ea0003
	call	(xhl)
	jr t, .LFWF_8c1a                       ; [68 4a] jr T,0x288c1a
.LFWF_8bd0:
	stiw_da	0x22B272, 16
	lds	wa, 0
	lds	bc, 0
	calr	0xf6b7
	ld	xwa, xiz
	sub	xwa, 0x00000010
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f0148
	ld	xbc, 0x01ea0003
	call	(xhl)
	jr t, .LFWF_8c1a                       ; [68 15] jr T,0x288c1a
.LFWF_8c05:
	ld	bc, iz
	ldw_da	wa, 0x22B272
	add	wa, bc
	ld	(0x23a098), wa
	lds	wa, 0
	lds	bc, 1
	calr	0xf67b
.LFWF_8c1a:
	lds32	xhl, 0
	pop xiz                                 ; pop XIZ
	inc	6, xsp
	ret

	dec 0, xsp                              ; dec 0,XSP
	push xiz
	ld (xsp + 0x04), xde                    ; ld (XSP+0x04),XDE
	ld	xiz, xbc
	ld (xsp + 0x08), xwa                    ; ld (XSP+0x08),XWA
	ld	xwa, xiz
	cp	xwa, 0x01c00007
	jr z, .LFWF_8c8a                       ; [66 55] jr Z,0x288c8a
	cp	xwa, 0x01c0000d
	jr z, .LFWF_8c4b                       ; [66 0e] jr Z,0x288c4b
	cp	xwa, 0x01e00085
	jrl nz, .LFWF_8cd1                     ; [7e 8b 00] jrl NZ,0x288cd1
	lds32	xhl, 1
	jrl t, .LFWF_8cea                      ; [78 9f 00] jrl T,0x288cea
.LFWF_8c4b:
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	ld	xbc, xiz
	ld xde, (xsp + 0x04)                    ; ld XDE,(XSP+0x04)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00dc)
	call	(xhl)
	lda_24 xwa, 0x2e2f0c
	ld	xbc, xwa
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	ld	xde, xbc
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01c0000f
	call	(xhl)
	lds32	xhl, 0
	jr t, .LFWF_8cea                       ; [68 60] jr T,0x288cea
.LFWF_8c8a:
	ld xde, (xsp + 0x04)                    ; ld XDE,(XSP+0x04)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xix, (xwa + 0x0100)
	ld	xwa, 0x02600024
	ld	xbc, 0x01e00029
	call	(xix)
	cp	xhl, 0x00000007
	jr z, .LFWF_8cb8                       ; [66 08] jr Z,0x288cb8
	cp	xhl, 0x00000006
	jr nz, .LFWF_8cd1                      ; [6e 19] jr NZ,0x288cd1
.LFWF_8cb8:
	stib_da	0x22AD9A, 0
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x00e8)
	lds	wa, 0
	call	(xhl)
.LFWF_8cd1:
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	ld	xbc, xiz
	ld xde, (xsp + 0x04)                    ; ld XDE,(XSP+0x04)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xix, (xhl + 0x00dc)
	call	(xix)
.LFWF_8cea:
	pop xiz                                 ; pop XIZ
	inc 0, xsp                              ; inc 0,XSP
	ret

	push xiz
	ld	xiz, xde
	cp	xbc, 0x01ea0002
	jrl z, .LFWF_8fd6                      ; [76 dc 02] jrl Z,0x288fd6
	cp	xbc, 0x01ea0000
	jrl z, .LFWF_8f98                      ; [76 95 02] jrl Z,0x288f98
	cp	xbc, 0x01ea0001
	jrl z, .LFWF_8f59                      ; [76 4d 02] jrl Z,0x288f59
	cp	xbc, 0x01ea0008
	jrl z, .LFWF_8e74                      ; [76 5f 01] jrl Z,0x288e74
	cp	xbc, 0x01ea0006
	jrl z, .LFWF_8e4c                      ; [76 2e 01] jrl Z,0x288e4c
	cp	xbc, 0x01c00007
	jr z, .LFWF_8d4f                       ; [66 29] jr Z,0x288d4f
	cp	xbc, 0x01c00001
	jrl nz, .LFWF_8fe9                     ; [7e ba 02] jrl NZ,0x288fe9
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f0169
	ld	xbc, 0x01ea0002
	lds32	xde, 0
	call	(xhl)
	jrl t, .LFWF_8fe9                      ; [78 9a 02] jrl T,0x288fe9
.LFWF_8d4f:
	ld	xde, xiz
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xix, (xwa + 0x0100)
	ld	xwa, 0x02600024
	ld	xbc, 0x01e00029
	call	(xix)
	cp	xhl, 0x00000007
	jrl z, .LFWF_8e1b                      ; [76 a6 00] jrl Z,0x288e1b
	cp	xhl, 0x00000006
	jr z, .LFWF_8dea                       ; [66 6d] jr Z,0x288dea
	cp	xhl, 0x00000005
	jr z, .LFWF_8dd2                       ; [66 4d] jr Z,0x288dd2
	cp	xhl, 0x00000001
	jr z, .LFWF_8db2                       ; [66 25] jr Z,0x288db2
	or xhl, xhl                             ; or XHL,XHL
	jrl nz, .LFWF_8fe9                     ; [7e 57 02] jrl NZ,0x288fe9
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f022f
	ld	xbc, 0x01c00001
	lds32	xde, 0
	call	(xhl)
	jrl t, .LFWF_8fe9                      ; [78 37 02] jrl T,0x288fe9
.LFWF_8db2:
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f020d
	ld	xbc, 0x01c00001
	lds32	xde, 0
	call	(xhl)
	jrl t, .LFWF_8fe9                      ; [78 17 02] jrl T,0x288fe9
.LFWF_8dd2:
	ldw_da	wa, 0x23A096
	ldw_da	bc, 0x23A098
	call 0x28feae
	lds	wa, 1
	lds	bc, 0
	calr	0xf4ae
	jrl t, .LFWF_8fe9                      ; [78 ff 01] jrl T,0x288fe9
.LFWF_8dea:
	bit	0x07, iz
	jr z, .LFWF_8e01                       ; [66 12] jr Z,0x288e01
	ldw_da	wa, 0x23A096
	ldw_da	bc, 0x23A098
	lds	de, 0
	call 0x290106
	jr t, .LFWF_8e11                       ; [68 10] jr T,0x288e11
.LFWF_8e01:
	ldw_da	wa, 0x23A096
	ldw_da	bc, 0x23A098
	lds	de, 1
	call 0x290106
.LFWF_8e11:
	lds	wa, 1
	lds	bc, 0
	calr	0xf47d
	jrl t, .LFWF_8fe9                      ; [78 ce 01] jrl T,0x288fe9
.LFWF_8e1b:
	bit	0x07, iz
	jr z, .LFWF_8e32                       ; [66 12] jr Z,0x288e32
	ldw_da	wa, 0x23A096
	ldw_da	bc, 0x23A098
	lds	de, 0
	call 0x290148
	jr t, .LFWF_8e42                       ; [68 10] jr T,0x288e42
.LFWF_8e32:
	ldw_da	wa, 0x23A096
	ldw_da	bc, 0x23A098
	lds	de, 1
	call 0x290148
.LFWF_8e42:
	lds	wa, 1
	lds	bc, 0
	calr	0xf44c
	jrl t, .LFWF_8fe9                      ; [78 9d 01] jrl T,0x288fe9
.LFWF_8e4c:
	ld	xwa, 0x007f0151
	calr	0xa8ba
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f014e
	ld	xbc, 0x01c00001
	lds32	xde, 0
	call	(xhl)
	jrl t, .LFWF_8fe9                      ; [78 75 01] jrl T,0x288fe9
.LFWF_8e74:
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f02c1
	ld	xbc, 0x01c00001
	lds32	xde, 5
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x00e4)
	ldw	wa, 0x0064
	call	(xhl)
	calr	0x2383
	lds	wa, 0
	call HDAE5000_Display_Callback
	cp	hl, 0xffff
	jr z, .LFWF_8ed4                       ; [66 20] jr Z,0x288ed4
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f0163
	ld	xbc, 0x01c00001
	lds32	xde, 0
	call	(xhl)
	jrl t, .LFWF_8fe9                      ; [78 15 01] jrl T,0x288fe9
.LFWF_8ed4:
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f0297
	ld	xbc, 0x01c00001
	lds32	xde, 0
	call	(xhl)
	ld	xwa, 0x007f0298
	ld	xbc, 0x007f0163
	calr	0x24ec
	ld	xwa, 0x01ca0002
	push xwa
	ld	xwa, 0x007f0163
	push xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0418)
	ld	xwa, 0x0000014d
	ld	xbc, 0x007f0299
	ld	xde, 0xffffffff
	call	(xhl)
	ld	xwa, 0x01ca0002
	push xwa
	ld	xwa, 0x007f0163
	push xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0410)
	ld	xwa, 0x0000014d
	ld	xbc, 0x007f0299
	ld	xde, 0xffffffff
	call	(xhl)
	jrl t, .LFWF_8fe9                      ; [78 90 00] jrl T,0x288fe9
.LFWF_8f59:
	cpw_da	0x22B272, 0
	jrl z, .LFWF_8fe9                      ; [76 86 00] jrl Z,0x288fe9
	stiw_da	0x22B272, 0
	lds	wa, 1
	lds	bc, 0
	calr	0xf324
	ld	xwa, xiz
	add	xwa, 0x00000010
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f0169
	ld	xbc, 0x01ea0003
	call	(xhl)
	jr t, .LFWF_8fe9                       ; [68 51] jr T,0x288fe9
.LFWF_8f98:
	cpw_da	0x22B272, 0
	jr nz, .LFWF_8fe9                      ; [6e 48] jr NZ,0x288fe9
	stiw_da	0x22B272, 16
	lds	wa, 1
	lds	bc, 0
	calr	0xf2e6
	ld	xwa, xiz
	sub	xwa, 0x00000010
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f0169
	ld	xbc, 0x01ea0003
	call	(xhl)
	jr t, .LFWF_8fe9                       ; [68 13] jr T,0x288fe9
.LFWF_8fd6:
	ld	wa, iz
	addda16_24	wa, 0x22B272
	ld	(0x23a098), wa
	lds	wa, 1
	lds	bc, 1
	calr	0xf2ac
.LFWF_8fe9:
	lds32	xhl, 0
	pop xiz                                 ; pop XIZ
	ret

	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, 0x01c00007
	jr z, .LFWF_905e                       ; [66 64] jr Z,0x28905e
	cp	xwa, 0x01c0000d
	jr z, .LFWF_9025                       ; [66 23] jr Z,0x289025
	cp	xwa, 0x01e00085
	jr z, .LFWF_9020                       ; [66 16] jr Z,0x289020
	ld	xwa, xiz
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xix, (xhl + 0x00dc)
	call	(xix)
	jrl t, .LFWF_90e8                      ; [78 c8 00] jrl T,0x2890e8
.LFWF_9020:
	lds32	xhl, 1
	jrl t, .LFWF_90e8                      ; [78 c3 00] jrl T,0x2890e8
.LFWF_9025:
	ld	xwa, xiz
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00dc)
	call	(xhl)
	lda_24 xwa, 0x2e2f12
	ld	xbc, xwa
	ld	xwa, xiz
	ld	xde, xbc
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01c0000f
	call	(xhl)
	lds32	xhl, 0
	jrl t, .LFWF_90e8                      ; [78 8a 00] jrl T,0x2890e8
.LFWF_905e:
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xix, (xwa + 0x0100)
	ld	xwa, 0x02600024
	ld	xbc, 0x01e00029
	call	(xix)
	cp	xhl, 0x00000007
	jr z, .LFWF_90c9                       ; [66 48] jr Z,0x2890c9
	cp	xhl, 0x00000006
	jr z, .LFWF_90c9                       ; [66 40] jr Z,0x2890c9
	cp	xhl, 0x00000001
	jr z, .LFWF_9095                       ; [66 04] jr Z,0x289095
	or xhl, xhl                             ; or XHL,XHL
	jr nz, .LFWF_90e6                      ; [6e 51] jr NZ,0x2890e6
.LFWF_9095:
	ldw_da	wa, 0x23A096
	ldw_da	bc, 0x23A098
	call 0x28fcb2
	lds	wa, 1
	lds	bc, 0
	calr	0xf1eb
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0104)
	ld	xwa, 0x007f0163
	ld	xbc, 0x01c00001
	lds32	xde, 0
	call	(xhl)
	jr t, .LFWF_90e6                       ; [68 1d] jr T,0x2890e6
.LFWF_90c9:
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0104)
	ld	xwa, 0x007f0163
	ld	xbc, 0x01c00001
	lds32	xde, 0
	call	(xhl)
.LFWF_90e6:
	lds32	xhl, 0
.LFWF_90e8:
	pop xiz                                 ; pop XIZ
	ret

	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, 0x01c00007
	jr z, .LFWF_915b                       ; [66 64] jr Z,0x28915b
	cp	xwa, 0x01c0000d
	jr z, .LFWF_9122                       ; [66 23] jr Z,0x289122
	cp	xwa, 0x01e00085
	jr z, .LFWF_911d                       ; [66 16] jr Z,0x28911d
	ld	xwa, xiz
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xix, (xhl + 0x00dc)
	call	(xix)
	jrl t, .LFWF_91e5                      ; [78 c8 00] jrl T,0x2891e5
.LFWF_911d:
	lds32	xhl, 1
	jrl t, .LFWF_91e5                      ; [78 c3 00] jrl T,0x2891e5
.LFWF_9122:
	ld	xwa, xiz
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00dc)
	call	(xhl)
	lda_24 xwa, 0x2e2f18
	ld	xbc, xwa
	ld	xwa, xiz
	ld	xde, xbc
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01c0000f
	call	(xhl)
	lds32	xhl, 0
	jrl t, .LFWF_91e5                      ; [78 8a 00] jrl T,0x2891e5
.LFWF_915b:
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xix, (xwa + 0x0100)
	ld	xwa, 0x02600024
	ld	xbc, 0x01e00029
	call	(xix)
	cp	xhl, 0x00000007
	jr z, .LFWF_91c6                       ; [66 48] jr Z,0x2891c6
	cp	xhl, 0x00000006
	jr z, .LFWF_91c6                       ; [66 40] jr Z,0x2891c6
	cp	xhl, 0x00000001
	jr z, .LFWF_9192                       ; [66 04] jr Z,0x289192
	or xhl, xhl                             ; or XHL,XHL
	jr nz, .LFWF_91e3                      ; [6e 51] jr NZ,0x2891e3
.LFWF_9192:
	ldw_da	wa, 0x23A096
	ldw_da	bc, 0x23A098
	call 0x28fd29
	lds	wa, 1
	lds	bc, 0
	calr	0xf0ee
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0104)
	ld	xwa, 0x007f0163
	ld	xbc, 0x01c00001
	lds32	xde, 0
	call	(xhl)
	jr t, .LFWF_91e3                       ; [68 1d] jr T,0x2891e3
.LFWF_91c6:
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0104)
	ld	xwa, 0x007f0163
	ld	xbc, 0x01c00001
	lds32	xde, 0
	call	(xhl)
.LFWF_91e3:
	lds32	xhl, 0
.LFWF_91e5:
	pop xiz                                 ; pop XIZ
	ret

	push xiz
	ld	xiz, xde
	cp	xbc, 0x01ea0000
	jrl z, .LFWF_931d                      ; [76 2a 01] jrl Z,0x28931d
	cp	xbc, 0x01ea0001
	jrl z, .LFWF_92de                      ; [76 e2 00] jrl Z,0x2892de
	cp	xbc, 0x01ea0006
	jrl z, .LFWF_92aa                      ; [76 a5 00] jrl Z,0x2892aa
	cp	xbc, 0x01c00007
	jrl nz, .LFWF_935a                     ; [7e 4c 01] jrl NZ,0x28935a
	ld	xde, xiz
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xix, (xwa + 0x0100)
	ld	xwa, 0x02600024
	ld	xbc, 0x01e00029
	call	(xix)
	cp	xhl, 0x00000007
	jr z, .LFWF_9298                       ; [66 65] jr Z,0x289298
	cp	xhl, 0x00000006
	jr z, .LFWF_9286                       ; [66 4b] jr Z,0x289286
	cp	xhl, 0x00000005
	jr z, .LFWF_9274                       ; [66 31] jr Z,0x289274
	cp	xhl, 0x00000001
	jr z, .LFWF_9262                       ; [66 17] jr Z,0x289262
	or xhl, xhl                             ; or XHL,XHL
	jrl nz, .LFWF_935a                     ; [7e 0a 01] jrl NZ,0x28935a
	stiw_da	0x23A08E, 0
	ld	xwa, 0x007f0151
	calr	0xa4af
	jrl t, .LFWF_935a                      ; [78 f8 00] jrl T,0x28935a
.LFWF_9262:
	stiw_da	0x23A08E, 24
	ld	xwa, 0x007f0151
	calr	0xa49d
	jrl t, .LFWF_935a                      ; [78 e6 00] jrl T,0x28935a
.LFWF_9274:
	stiw_da	0x23A08E, 48
	ld	xwa, 0x007f0151
	calr	0xa48b
	jrl t, .LFWF_935a                      ; [78 d4 00] jrl T,0x28935a
.LFWF_9286:
	stiw_da	0x23A08E, 72
	ld	xwa, 0x007f0151
	calr	0xa479
	jrl t, .LFWF_935a                      ; [78 c2 00] jrl T,0x28935a
.LFWF_9298:
	stiw_da	0x23A08E, 96
	ld	xwa, 0x007f0151
	calr	0xa467
	jrl t, .LFWF_935a                      ; [78 b0 00] jrl T,0x28935a
.LFWF_92aa:
	ldw_da	bc, 0x23A08E
	ld	wa, iz
	add	wa, bc
	ld	(0x23a092), wa
	lds	wa, 1
	lds	bc, 0
	calr	0xa8a9
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f0159
	ld	xbc, 0x01c00001
	lds32	xde, 0
	call	(xhl)
	jr t, .LFWF_935a                       ; [68 7c] jr T,0x28935a
.LFWF_92de:
	cpw_da	0x23A08E, 24
	jr lt, .LFWF_935a                      ; [61 73] jr LT,0x28935a
	subdi16_24	0x23A08E, 24
	ld	xwa, 0x007f0151
	calr	0xa418
	ld	xwa, xiz
	add	xwa, 0x00000018
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f0151
	ld	xbc, 0x01ea0003
	call	(xhl)
	jr t, .LFWF_935a                       ; [68 3d] jr T,0x28935a
.LFWF_931d:
	cpw_da	0x23A08E, 96
	jr ge, .LFWF_935a                      ; [69 34] jr GE,0x28935a
	adddi16_24	0x23A08E, 24
	ld	xwa, 0x007f0151
	calr	0xa3d9
	ld	xwa, xiz
	sub	xwa, 0x00000018
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f0151
	ld	xbc, 0x01ea0003
	call	(xhl)
.LFWF_935a:
	lds32	xhl, 0
	pop xiz                                 ; pop XIZ
	ret

	push xiz
	ld	xiz, xde
	cp	xbc, 0x01ea0002
	jrl z, .LFWF_94e2                      ; [76 78 01] jrl Z,0x2894e2
	cp	xbc, 0x01ea0000
	jrl z, .LFWF_94a6                      ; [76 33 01] jrl Z,0x2894a6
	cp	xbc, 0x01ea0001
	jrl z, .LFWF_9468                      ; [76 ec 00] jrl Z,0x289468
	cp	xbc, 0x01ea0006
	jr z, .LFWF_93ad                       ; [66 29] jr Z,0x2893ad
	cp	xbc, 0x01c00001
	jrl nz, .LFWF_952a                     ; [7e 9d 01] jrl NZ,0x28952a
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f015c
	ld	xbc, 0x01ea0002
	lds32	xde, 0
	call	(xhl)
	jrl t, .LFWF_952a                      ; [78 7d 01] jrl T,0x28952a
.LFWF_93ad:
	ld	(0x23a094), iz
	ldw_da	wa, 0x23A096
	ldw_da	bc, 0x23A098
	call HDAE5000_Cell_In_Bounds
	cp	hl, 0xffff
	jrl nz, .LFWF_9448                     ; [7e 81 00] jrl NZ,0x289448
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f02c1
	ld	xbc, 0x01c00001
	lds32	xde, 5
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x00e4)
	ldw	wa, 0x0064
	call	(xhl)
	calr	0x1e30
	ldw_da	wa, 0x23A096
	ldw_da	bc, 0x23A098
	ldw_da	de, 0x23A092
	call 0x2900c2
	ldw_da	wa, 0x23A096
	ldw_da	bc, 0x23A098
	ldw_da	de, 0x23A094
	call 0x2900e4
	lds	wa, 1
	lds	bc, 0
	calr	0xee6d
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f0163
	ld	xbc, 0x01c00001
	lds32	xde, 0
	call	(xhl)
	jrl t, .LFWF_952a                      ; [78 e2 00] jrl T,0x28952a
.LFWF_9448:
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f0204
	ld	xbc, 0x01c00001
	lds32	xde, 0
	call	(xhl)
	jrl t, .LFWF_952a                      ; [78 c2 00] jrl T,0x28952a
.LFWF_9468:
	cpw_da	0x23A092, 0
	jrl z, .LFWF_952a                      ; [76 b8 00] jrl Z,0x28952a
	decdi16_24	1, 0x23A092
	lds	wa, 1
	lds	bc, 0
	calr	0xa6ea
	ld	xwa, xiz
	add	xwa, 0x00000010
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f015c
	ld	xbc, 0x01ea0003
	call	(xhl)
	jrl t, .LFWF_952a                      ; [78 84 00] jrl T,0x28952a
.LFWF_94a6:
	cpw_da	0x23A092, 119
	jr nc, .LFWF_952a                      ; [6f 7b] jr NC,0x28952a
	incdi16_24	1, 0x23A092
	lds	wa, 1
	lds	bc, 0
	calr	0xa6ad
	ld	xwa, xiz
	sub	xwa, 0x00000010
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f015c
	ld	xbc, 0x01ea0003
	call	(xhl)
	jr t, .LFWF_952a                       ; [68 48] jr T,0x28952a
.LFWF_94e2:
	ld	(0x23a094), iz
	ldw_da	wa, 0x23A092
	ldw_da	bc, 0x23A094
	call HDAE5000_Table_Lookup
	ld	wa, hl
	cp	wa, 0xffff
	jr z, .LFWF_9511                       ; [66 14] jr Z,0x289511
	lda_24 xwa, 0x22aa4c
	pushw 0x0002
	ld	bc, hl
	lda_24 xde, 0x2e1c96
	calr	0xbdd5
	jr t, .LFWF_9523                       ; [68 12] jr T,0x289523
.LFWF_9511:
	lda_24 xwa, 0x22aa4c
	pushw 0x0002
	lda_24 xde, 0x2e1c96
	lds	bc, 0
	calr	0xbdc1
.LFWF_9523:
	lds	wa, 1
	lds	bc, 1
	calr	0xa63e
.LFWF_952a:
	lds32	xhl, 0
	pop xiz                                 ; pop XIZ
	ret

	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, 0x01c00007
	jr z, .LFWF_959f                       ; [66 64] jr Z,0x28959f
	cp	xwa, 0x01c0000d
	jr z, .LFWF_9566                       ; [66 23] jr Z,0x289566
	cp	xwa, 0x01e00085
	jr z, .LFWF_9561                       ; [66 16] jr Z,0x289561
	ld	xwa, xiz
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xix, (xhl + 0x00dc)
	call	(xix)
	jrl t, .LFWF_9663                      ; [78 02 01] jrl T,0x289663
.LFWF_9561:
	lds32	xhl, 1
	jrl t, .LFWF_9663                      ; [78 fd 00] jrl T,0x289663
.LFWF_9566:
	ld	xwa, xiz
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00dc)
	call	(xhl)
	lda_24 xwa, 0x2e2f1e
	ld	xbc, xwa
	ld	xwa, xiz
	ld	xde, xbc
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01c0000f
	call	(xhl)
	lds32	xhl, 0
	jrl t, .LFWF_9663                      ; [78 c4 00] jrl T,0x289663
.LFWF_959f:
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xix, (xwa + 0x0100)
	ld	xwa, 0x02600024
	ld	xbc, 0x01e00029
	call	(xix)
	cp	xhl, 0x00000007
	jrl z, .LFWF_9644                      ; [76 81 00] jrl Z,0x289644
	cp	xhl, 0x00000006
	jr z, .LFWF_9644                       ; [66 79] jr Z,0x289644
	cp	xhl, 0x00000001
	jr z, .LFWF_95d8                       ; [66 05] jr Z,0x2895d8
	or xhl, xhl                             ; or XHL,XHL
	jrl nz, .LFWF_9661                     ; [7e 89 00] jrl NZ,0x289661
.LFWF_95d8:
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0100)
	ld	xwa, 0x007f02c1
	ld	xbc, 0x01c00001
	lds32	xde, 5
	call	(xhl)
	calr	0x1c33
	ldw_da	wa, 0x23A096
	ldw_da	bc, 0x23A098
	ldw_da	de, 0x23A092
	call 0x2900c2
	ldw_da	wa, 0x23A096
	ldw_da	bc, 0x23A098
	ldw_da	de, 0x23A094
	call 0x2900e4
	lds	wa, 1
	lds	bc, 0
	calr	0xec70
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0104)
	ld	xwa, 0x007f0163
	ld	xbc, 0x01c00001
	lds32	xde, 0
	call	(xhl)
	jr t, .LFWF_9661                       ; [68 1d] jr T,0x289661
.LFWF_9644:
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0104)
	ld	xwa, 0x007f0163
	ld	xbc, 0x01c00001
	lds32	xde, 0
	call	(xhl)
.LFWF_9661:
	lds32	xhl, 0
.LFWF_9663:
	pop xiz                                 ; pop XIZ
	ret


HDAE5000_FS_Buffer_Setup:	; 0x289665 (548 bytes)
	; Set up filesystem buffers at 0x22AA9C
	; --- Register events for filesystem buffer at 0x22AA9C ---
	lda_24 xwa, 0x22aa9c			; f2 9c aa 22 30
	ld xde, xwa				; e8 8a
	ldl_da xwa, 0x23a1a2		; e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20 — ld xwa, (xwa+0x0e0a)
	ld_sril xhl, (xwa + 0x0124)             ; e3 e1 24 01 23 — ld xhl, (xwa+0x0124)
	ld xwa, 0x007f00de			; 40 de 00 7f 00
	ld xbc, 0x01ea000a			; 41 0a 00 ea 01
	call (xhl)				; b3 e8

	; Deregister event 0x01C0000F
	ldl_da xwa, 0x23a1a2		; e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + 0x0124)             ; e3 e1 24 01 23
	ld xwa, 0x007f00de			; 40 de 00 7f 00
	ld xbc, 0x01c0000f			; 41 0f 00 c0 01
	ld xde, 0xffffffff			; 42 ff ff ff ff
	call (xhl)				; b3 e8

	; --- Initialize 20 buffer entries ---
	lds de, 0				; da a8
	cp de, 0x0014				; da cf 14 00
	jr nc, .Lfbs_after_loop			; 6f xx

.Lfbs_loop:					; 0x2896AF
	ld wa, de				; da 88
	mul wa, 0x000c				; d8 08 0c 00
	add wa, 0x000a				; d8 c8 0a 00
	extz xwa				; e8 12
	add xwa, 0x0000000e			; e8 c8 0e 00 00 00
	ld xbc, 0x0022aa9c			; 41 9c aa 22 00
	add xbc, xwa				; e8 81
	ld	(xbc), 0x20

	; Check status flag at +0x0114
	ld wa, de				; da 88
	extz xwa				; e8 12
	add xwa, 0x00000114			; e8 c8 14 01 00 00
	ld xbc, 0x0022aa9c			; 41 9c aa 22 00
	add xbc, xwa				; e8 81
	cp	(xbc), 0x01
	jr nz, .Lfbs_loop_next			; 6e xx

	; Entry is active: set flag to 0x2A (asterisk)
	ld wa, de				; da 88
	mul wa, 0x000c				; d8 08 0c 00
	add wa, 0x000a				; d8 c8 0a 00
	extz xwa				; e8 12
	add xwa, 0x0000000e			; e8 c8 0e 00 00 00
	ld xbc, 0x0022aa9c			; 41 9c aa 22 00
	add xbc, xwa				; e8 81
	ld	(xbc), 0x2a

.Lfbs_loop_next:				; 0x2896FD
	inc 1, de				; da 61
	cp de, 0x0014				; da cf 14 00
	jr c, .Lfbs_loop			; 67 xx

.Lfbs_after_loop:				; 0x289705
	; --- Register events for second buffer at 0x22AAAA ---
	lda_24 xwa, 0x22aaaa			; f2 aa aa 22 30
	ld xde, xwa				; e8 8a
	ldl_da xwa, 0x23a1a2		; e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + 0x0124)             ; e3 e1 24 01 23
	ld xwa, 0x007f00d7			; 40 d7 00 7f 00
	ld xbc, 0x01ea000a			; 41 0a 00 ea 01
	call (xhl)				; b3 e8

	; Deregister event 0x01C0000F
	ldl_da xwa, 0x23a1a2		; e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + 0x0124)             ; e3 e1 24 01 23
	ld xwa, 0x007f00d7			; 40 d7 00 7f 00
	ld xbc, 0x01c0000f			; 41 0f 00 c0 01
	ld xde, 0xffffffff			; 42 ff ff ff ff
	call (xhl)				; b3 e8

	; Register event 0x01C0000D (handler 1)
	ldl_da xwa, 0x23a1a2		; e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + 0x0124)             ; e3 e1 24 01 23
	ld xwa, 0x007f00d9			; 40 d9 00 7f 00
	ld xbc, 0x01c0000d			; 41 0d 00 c0 01
	lds32 xde, 0				; ea a8
	call (xhl)				; b3 e8

	; Register event 0x01C0000D (handler 2) — tail call via jp
	ldl_da xwa, 0x23a1a2		; e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + 0x0124)             ; e3 e1 24 01 23
	ld xwa, 0x007f00d8			; 40 d8 00 7f 00
	ld xbc, 0x01c0000d			; 41 0d 00 c0 01
	lds32 xde, 0				; ea a8
	jp (xhl)				; b3 d8 — tail call

; --- Event handler sub-function ---
.Lfbs_evt_handler:				; 0x289781
	pushw iz                                ; push iz (compact 16-bit)
	cp xbc, 0x01ea0002			; e9 cf 02 00 ea 01
	jrl z, .Lfbs_evt_0002			; 76 xx xx
	cp xbc, 0x01ea0008			; e9 cf 08 00 ea 01
	jrl z, .Lfbs_evt_0008			; 76 xx xx
	cp xbc, 0x01ea0006			; e9 cf 06 00 ea 01
	jr z, .Lfbs_evt_0006			; 66 xx
	cp xbc, 0x01ea0009			; e9 cf 09 00 ea 01
	jrl nz, .Lfbs_evt_done			; 7e xx xx

	; Event 0x01EA0009: scan all 20 entries, mark active ones
.Lfbs_evt_0009:					; 0x2897A5
	lds iz, 0				; de a8
	cp iz, 0x0014				; de cf 14 00
	jrl nc, .Lfbs_evt_done			; 7f xx xx

.Lfbs_evt_0009_loop:				; 0x2897AE
	ld wa, iz				; de 88
	extz xwa				; e8 12
	add xwa, 0x00000100			; e8 c8 00 01 00 00
	ld xbc, 0x0022aa9c			; 41 9c aa 22 00
	add xbc, xwa				; e8 81
	cp	(xbc), 0x01
	jr nz, .Lfbs_evt_0009_next		; 6e xx
	; Entry is active: mark status flag
	ld wa, iz				; de 88
	extz xwa				; e8 12
	add xwa, 0x00000114			; e8 c8 14 01 00 00
	ld xbc, 0x0022aa9c			; 41 9c aa 22 00
	add xbc, xwa				; e8 81
	ld	(xbc), 0x01
	calr HDAE5000_FS_Buffer_Setup		; 1e xx xx — self-call

.Lfbs_evt_0009_next:				; 0x2897DB
	inc 1, iz				; de 61
	cp iz, 0x0014				; de cf 14 00
	jr c, .Lfbs_evt_0009_loop		; 67 xx
	jrl t, .Lfbs_evt_done			; 78 xx xx

	; Event 0x01EA0006: format params and check active files
.Lfbs_evt_0006:					; 0x2897E6
	ld xwa, 0x007f00e6			; 40 e6 00 7f 00
	calr HDAE5000_HD_Format_Params		; 1e xx xx
	calr HDAE5000_Count_Active_Files	; 1e xx xx
	cps hl, 0				; db d8
	jr z, .Lfbs_evt_0006_empty		; 66 xx
	; Has active files: register status 0x007f00e2
	ldl_da xwa, 0x23a1a2		; e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + 0x0124)             ; e3 e1 24 01 23
	ld xwa, 0x007f00e2			; 40 e2 00 7f 00
	ld xbc, 0x01c00001			; 41 01 00 c0 01
	lds32 xde, 0				; ea a8
	call (xhl)				; b3 e8
	jr t, .Lfbs_evt_done			; 68 xx

.Lfbs_evt_0006_empty:				; 0x289814
	; No active files: register status 0x007f027a
	ldl_da xwa, 0x23a1a2		; e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + 0x0124)             ; e3 e1 24 01 23
	ld xwa, 0x007f027a			; 40 7a 02 7f 00
	ld xbc, 0x01c00001			; 41 01 00 c0 01
	lds32 xde, 0				; ea a8
	call (xhl)				; b3 e8
	jr t, .Lfbs_evt_done			; 68 xx

	; Event 0x01EA0008: check entry, toggle flag
.Lfbs_evt_0008:					; 0x289833
	ld xwa, xde				; ea 88
	add xwa, 0x00000100			; e8 c8 00 01 00 00
	ld xbc, 0x0022aa9c			; 41 9c aa 22 00
	add xbc, xwa				; e8 81
	cp	(xbc), 0x01
	jr nz, .Lfbs_evt_done			; 6e xx
	; First flag is set: check second flag at +0x0114
	ld xwa, xde				; ea 88
	add xwa, 0x00000114			; e8 c8 14 01 00 00
	ld xbc, 0x0022aa9c			; 41 9c aa 22 00
	add xbc, xwa				; e8 81
	cp	(xbc), 0x01
	jr nz, .Lfbs_evt_0008_set1		; 6e xx
	; Second flag is set: clear it to 0
	add xde, 0x00000114			; ea c8 14 01 00 00
	ld xwa, 0x0022aa9c			; 40 9c aa 22 00
	add xwa, xde				; ea 80
	ld	(xwa), 0x00
	jr t, .Lfbs_evt_0008_done		; 68 xx

.Lfbs_evt_0008_set1:				; 0x28986D
	; Second flag not set: set it to 1
	add xde, 0x00000114			; ea c8 14 01 00 00
	ld xwa, 0x0022aa9c			; 40 9c aa 22 00
	add xwa, xde				; ea 80
	ld	(xwa), 0x01

.Lfbs_evt_0008_done:				; 0x28987D
	calr HDAE5000_FS_Buffer_Setup		; 1e xx xx — self-call
	jr t, .Lfbs_evt_done			; 68 xx

.Lfbs_evt_0002:					; 0x289882
	calr HDAE5000_FS_Buffer_Setup		; 1e xx xx — self-call

.Lfbs_evt_done:					; 0x289885
	lds32 xhl, 0				; eb a8
	popw iz                                 ; pop iz (compact 16-bit)
	ret					; 0e

HDAE5000_FS_Scan_Directory:	; 0x289889 (2663 bytes)
	; Part 1: Main scan loop — iterate directory entries, search partitions
	stb_dri l, 0xFD, 0xD4, 0xFE	; lda XSP, XSP+0xFED4 (alloc ~300 bytes)
	push xiz
	stw_dri de, 0xFD, 0x2C, 0x01	; ld (XSP+0x012C), DE
	stw_dri bc, 0xFD, 0x2E, 0x01	; ld (XSP+0x012E), BC
	lds iz, 0
.LFSD__loop:
	cpw_sri_rm iz, 0xFD, 0x2E, 0x01	; cp IZ, (XSP+0x012E)
	jrl nc, .LFSD__loop_done
.LFSD__loop_body:
	ld wa, iz
	extz xwa
	add xwa, 0x00000114
	ld xbc, 0x0022aa9c
	add xbc, xwa
	cp	(xbc), 0x01
	jrl nz, .LFSD__loop_next
	; Valid entry — format and display
	pushw 0x000d
	pushw 0x0000
	stb_dri w, 0xFD, 0x22, 0x01	; lda XWA, XSP+0x0122
	push xwa
	call HDAE5000_MemFill			; MemFill
	ld wa, iz
	inc 1, wa
	pushw wa                                ; push wa (compact)
	pushw 0x002e
	pushw 0x2f24
	stb_dri w, 0xFD, 0x2C, 0x01	; lda XWA, XSP+0x012C
	push xwa
	call HDAE5000_PPI_Block_Copy
	pushw 0x0006
	ld wa, iz
	mul wa, 0x000c
	inc 3, wa
	extz xwa
	add xwa, 0x0000000e
	ld xbc, 0x0022aa9c
	add xbc, xwa
	push xbc
	stb_dri w, 0xFD, 0x38, 0x01	; lda XWA, XSP+0x0138
	push xwa
	call HDAE5000_MemCopy_Reverse			; MemCopy_Reverse
	lda xsp, (xsp + 0x1c)
	ldw	(xsp+4), 0xffff
	; QIZ loop: search 16 partitions
	ld	qiz, 0
	cpw	qiz, 0x0010
	jr nc, .LFSD__qiz_done
.LFSD__qiz_loop:
	ld	bc, qiz
	ldw_sri0	wa, (xsp + 0x012c)
	call HDAE5000_Table_Calc_Offset
	cp hl, 0xffff
	jr nz, .LFSD__qiz_found
	ld	wa, qiz
	ld (xsp + 0x04), wa
	jr t, .LFSD__qiz_done
.LFSD__qiz_found:
	inc	1, qiz
	cpw	qiz, 0x0010
	jr c, .LFSD__qiz_loop
.LFSD__qiz_done:
	cpw	(xsp+4), 0xffff
	jrl z, .LFSD__loop_next
	; Copy 8 bytes from entry
	pushw 0x0008
	stb_dri w, 0xFD, 0x20, 0x01	; lda XWA, XSP+0x0120
	push xwa
	stb_dri w, 0xFD, 0x16, 0x01	; lda XWA, XSP+0x0116
	push xwa
	call HDAE5000_MemCopy			; MemCopy
	lda xsp, (xsp + 0x0a)
	; Search 8 format fields (set QIZ bits 0-7)
	ld	qiz, 0
	; Field 0 (0x2F2A)
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)             ; XWA = (XWA+0x0E88)
	ld xhl, (xwa + 0x08)
	call (xhl)
	pushw 0x002e
	pushw 0x2f2a
	stb_dri w, 0xFD, 0x1C, 0x01	; lda XWA, XSP+0x011C
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp
	lda xwa, (xsp + 0x06)
	ld xbc, xwa
	stb_dri w, 0xFD, 0x10, 0x01	; lda XWA, XSP+0x0110
	ldl_da xde, 0x23a1a2
	ld_sril xde, (xde + 0x0e88)             ; XDE = (XDE+0x0E88)
	ld_sril xix, (xde + 0x0094)             ; XIX = (XDE+0x0094)
	call (xix)
	ld xwa, xhl
	cp xwa, 0xffffffff
	jr z, .LFSD__f1
	ld	qiz, 1
	ld xwa, xhl
	ldl_da xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e88)
	ld_sril xhl, (xbc + 0x009c)             ; XHL = (XBC+0x009C)
	call (xhl)
.LFSD__f1:				; Field 1 (0x2F30)
	pushw 0x002e
	pushw 0x2f30
	stb_dri w, 0xFD, 0x1C, 0x01	; lda XWA, XSP+0x011C
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp
	lda xwa, (xsp + 0x06)
	ld xbc, xwa
	stb_dri w, 0xFD, 0x10, 0x01	; lda XWA, XSP+0x0110
	ldl_da xde, 0x23a1a2
	ld_sril xde, (xde + 0x0e88)
	ld_sril xix, (xde + 0x0094)
	call (xix)
	ld xwa, xhl
	cp xwa, 0xffffffff
	jr z, .LFSD__f2
	set	0x01, qiz
	ld xwa, xhl
	ldl_da xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e88)
	ld_sril xhl, (xbc + 0x009c)
	call (xhl)
.LFSD__f2:				; Field 2 (0x2F36)
	pushw 0x002e
	pushw 0x2f36
	stb_dri w, 0xFD, 0x1C, 0x01
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp
	lda xwa, (xsp + 0x06)
	ld xbc, xwa
	stb_dri w, 0xFD, 0x10, 0x01
	ldl_da xde, 0x23a1a2
	ld_sril xde, (xde + 0x0e88)
	ld_sril xix, (xde + 0x0094)
	call (xix)
	ld xwa, xhl
	cp xwa, 0xffffffff
	jr z, .LFSD__f3
	set	0x02, qiz
	ld xwa, xhl
	ldl_da xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e88)
	ld_sril xhl, (xbc + 0x009c)
	call (xhl)
.LFSD__f3:				; Field 3 (0x2F3C)
	pushw 0x002e
	pushw 0x2f3c
	stb_dri w, 0xFD, 0x1C, 0x01
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp
	lda xwa, (xsp + 0x06)
	ld xbc, xwa
	stb_dri w, 0xFD, 0x10, 0x01
	ldl_da xde, 0x23a1a2
	ld_sril xde, (xde + 0x0e88)
	ld_sril xix, (xde + 0x0094)
	call (xix)
	ld xwa, xhl
	cp xwa, 0xffffffff
	jr z, .LFSD__f4
	set	0x03, qiz
	ld xwa, xhl
	ldl_da xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e88)
	ld_sril xhl, (xbc + 0x009c)
	call (xhl)
.LFSD__f4:				; Field 4 (0x2F42)
	pushw 0x002e
	pushw 0x2f42
	stb_dri w, 0xFD, 0x1C, 0x01
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp
	lda xwa, (xsp + 0x06)
	ld xbc, xwa
	stb_dri w, 0xFD, 0x10, 0x01
	ldl_da xde, 0x23a1a2
	ld_sril xde, (xde + 0x0e88)
	ld_sril xix, (xde + 0x0094)
	call (xix)
	ld xwa, xhl
	cp xwa, 0xffffffff
	jr z, .LFSD__f5
	set	0x04, qiz
	ld xwa, xhl
	ldl_da xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e88)
	ld_sril xhl, (xbc + 0x009c)
	call (xhl)
.LFSD__f5:				; Field 5 (0x2F46)
	pushw 0x002e
	pushw 0x2f46
	stb_dri w, 0xFD, 0x1C, 0x01
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp
	lda xwa, (xsp + 0x06)
	ld xbc, xwa
	stb_dri w, 0xFD, 0x10, 0x01
	ldl_da xde, 0x23a1a2
	ld_sril xde, (xde + 0x0e88)
	ld_sril xix, (xde + 0x0094)
	call (xix)
	ld xwa, xhl
	cp xwa, 0xffffffff
	jr z, .LFSD__f6
	set	0x05, qiz
	ld xwa, xhl
	ldl_da xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e88)
	ld_sril xhl, (xbc + 0x009c)
	call (xhl)
.LFSD__f6:				; Field 6 (0x2F4C)
	pushw 0x002e
	pushw 0x2f4c
	stb_dri w, 0xFD, 0x1C, 0x01
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp
	lda xwa, (xsp + 0x06)
	ld xbc, xwa
	stb_dri w, 0xFD, 0x10, 0x01
	ldl_da xde, 0x23a1a2
	ld_sril xde, (xde + 0x0e88)
	ld_sril xix, (xde + 0x0094)
	call (xix)
	ld xwa, xhl
	cp xwa, 0xffffffff
	jr z, .LFSD__f7
	set	0x06, qiz
	ld xwa, xhl
	ldl_da xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e88)
	ld_sril xhl, (xbc + 0x009c)
	call (xhl)
.LFSD__f7:				; Field 7 (0x2F52)
	pushw 0x002e
	pushw 0x2f52
	stb_dri w, 0xFD, 0x1C, 0x01
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp
	lda xwa, (xsp + 0x06)
	ld xbc, xwa
	stb_dri w, 0xFD, 0x10, 0x01
	ldl_da xde, 0x23a1a2
	ld_sril xde, (xde + 0x0e88)
	ld_sril xix, (xde + 0x0094)
	call (xix)
	ld xwa, xhl
	cp xwa, 0xffffffff
	jr z, .LFSD__f8
	set	0x07, qiz
	ld xwa, xhl
	ldl_da xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e88)
	ld_sril xhl, (xbc + 0x009c)
	call (xhl)
.LFSD__f8:				; Field 8 (0x2F56)
	pushw 0x002e
	pushw 0x2f56
	stb_dri w, 0xFD, 0x1C, 0x01
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp
	lda xwa, (xsp + 0x06)
	ld xbc, xwa
	stb_dri w, 0xFD, 0x10, 0x01
	ldl_da xde, 0x23a1a2
	ld_sril xde, (xde + 0x0e88)
	ld_sril xix, (xde + 0x0094)
	call (xix)
	ld xwa, xhl
	cp xwa, 0xffffffff
	jr z, .LFSD__post_search
	set	0x08, qiz
	ld xwa, xhl
	ldl_da xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e88)
	ld_sril xhl, (xbc + 0x009c)
	call (xhl)
.LFSD__post_search:
	; Check results and call directory handler
	stb_dri w, 0xFD, 0x1E, 0x01	; lda XWA, XSP+0x011E
	ld	bc, qiz
	call 0x291c58
	cp hl, 0xffff
	jrl z, .LFSD__no_match
	; Match — attempt write
	ld bc, (xsp + 0x04)
	stb_dri w, 0xFD, 0x1E, 0x01	; lda XWA, XSP+0x011E
	ld xde, xwa
	push	qiz
	pushw 0x0000
	pushw 0x0000
	ldw_sri0	wa, (xsp + 0x0132)
	call 0x292151
	cp hl, 0xffff
	jrl nz, .LFSD__loop_next
	; Write failed — error display
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0124)             ; XHL = (XWA+0x0124)
	ld xwa, 0x007f0297
	ld xbc, 0x01c00001
	lds32 xde, 0
	call (xhl)
	ld xwa, 0x007f0298
	ld xbc, 0x007f00d2
	calr HDAE5000_UI_Main_Handler
	ld xwa, 0x01ca0002
	push xwa
	ld xwa, 0x007f00d2
	push xwa
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0418)
	ld xwa, 0x0000014d
	ld xbc, 0x007f0299
	ld xde, 0xffffffff
	call (xhl)
	ld xwa, 0x01ca0002
	push xwa
	ld xwa, 0x007f00d2
	push xwa
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0410)
	ld xwa, 0x0000014d
	ld xbc, 0x007f0299
	ld xde, 0xffffffff
	call (xhl)
	ldw hl, 0xffff
	jrl t, .LFSD__exit
.LFSD__no_match:
	; No match — confirmation display
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0124)
	ld xwa, 0x007f02a3
	ld xbc, 0x01c00001
	lds32 xde, 3
	call (xhl)
	ld xwa, 0x01ca0002
	push xwa
	ld xwa, 0x007f00d2
	push xwa
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0418)
	ld xwa, 0x0000014d
	ld xbc, 0x007f02a5
	ld xde, 0xffffffff
	call (xhl)
	ld xwa, 0x01ca0002
	push xwa
	ld xwa, 0x007f00d2
	push xwa
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0410)
	ld xwa, 0x0000014d
	ld xbc, 0x007f02a5
	ld xde, 0xffffffff
	call (xhl)
	ldw hl, 0xffff
	jr t, .LFSD__exit
.LFSD__loop_next:
	inc 1, iz
	cpw_sri_rm iz, 0xFD, 0x2E, 0x01	; cp IZ, (XSP+0x012E)
	jrl c, .LFSD__loop_body
.LFSD__loop_done:
	lds hl, 0
.LFSD__exit:
	pop xiz
	stb_dri l, 0xFD, 0x2C, 0x01	; lda XSP, XSP+0x012C (dealloc)
	ret
	;
	; Part 2: Event handler — navigation (0x289D72)
.LFSD__handlerA:
	push xiz
	ld xiz, xde
	cp xbc, 0x01ea0000
	jrl z, .LFSD__hA_scroll_down
	cp xbc, 0x01ea0001
	jrl z, .LFSD__hA_scroll_up
	cp xbc, 0x01ea0008
	jrl z, .LFSD__hA_sector_info
	cp xbc, 0x01ea0006
	jrl z, .LFSD__hA_cyl_calc
	cp xbc, 0x01c00007
	jrl nz, .LFSD__hA_exit
	; Event 0x01C00007: page select
	ld xde, xiz
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xix, (xwa + 0x0100)
	ld xwa, 0x02600024
	ld xbc, 0x01e00029
	call (xix)
	cp xhl, 0x00000007
	jr z, .LFSD__hA_page7
	cp xhl, 0x00000006
	jr z, .LFSD__hA_page6
	cp xhl, 0x00000005
	jr z, .LFSD__hA_page5
	cp xhl, 0x00000001
	jr z, .LFSD__hA_page1
	or xhl, xhl
	jrl nz, .LFSD__hA_exit
	; Page 0: offset = 0x0000
	stiw_da 0x23a08e, 0x0000
	ld xwa, 0x007f00e6
	calr HDAE5000_HD_Format_Params
	jrl t, .LFSD__hA_exit
.LFSD__hA_page1:			; Page 1: offset = 0x0018
	stiw_da 0x23a08e, 0x0018
	ld xwa, 0x007f00e6
	calr HDAE5000_HD_Format_Params
	jrl t, .LFSD__hA_exit
.LFSD__hA_page5:			; Page 5: offset = 0x0030
	stiw_da 0x23a08e, 0x0030
	ld xwa, 0x007f00e6
	calr HDAE5000_HD_Format_Params
	jrl t, .LFSD__hA_exit
.LFSD__hA_page6:			; Page 6: offset = 0x0048
	stiw_da 0x23a08e, 0x0048
	ld xwa, 0x007f00e6
	calr HDAE5000_HD_Format_Params
	jrl t, .LFSD__hA_exit
.LFSD__hA_page7:			; Page 7: offset = 0x0060
	stiw_da 0x23a08e, 0x0060
	ld xwa, 0x007f00e6
	calr HDAE5000_HD_Format_Params
	jrl t, .LFSD__hA_exit
.LFSD__hA_cyl_calc:			; Event 0x01EA0006: cylinder select
	ldw_da xwa, 0x23a08e
	ld bc, iz
	add bc, wa
	stw_da 0x23a092, xbc
	ld wa, bc
	call HDAE5000_Get_Display_Dimensions_A1_2F
	cp hl, 0xffff
	jr nz, .LFSD__hA_cyl_ok
	; Invalid — error display
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0124)
	ld xwa, 0x007f02b0
	ld xbc, 0x01c00001
	lds32 xde, 0
	call (xhl)
	ld xwa, 0x01ca0002
	push xwa
	ld xwa, 0x007f00e2
	push xwa
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0418)
	ld xwa, 0x0000014d
	ld xbc, 0x007f02b2
	ld xde, 0xffffffff
	call (xhl)
	ld xwa, 0x01ca0002
	push xwa
	ld xwa, 0x007f00e2
	push xwa
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0410)
	ld xwa, 0x0000014d
	ld xbc, 0x007f02b2
	ld xde, 0xffffffff
	call (xhl)
	jrl t, .LFSD__hA_exit
.LFSD__hA_cyl_ok:
	; Valid cylinder — check bounds
	calr HDAE5000_Count_Active_Files
	ld iz, hl
	ldw_da xwa, 0x23a092
	call HDAE5000_Count_Invalid_Cells
	cp hl, iz
	jr c, .LFSD__hA_cyl_fits
	; Too many — error + recursive scan
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0124)
	ld xwa, 0x007f02c1
	ld xbc, 0x01c00001
	lds32 xde, 5
	call (xhl)
	lda_24 xwa, 0x22abb0
	ldw_da xde, 0x23a092
	ldw bc, 0x0014
	calr HDAE5000_FS_Scan_Directory	; recursive
	cp hl, 0xffff
	jrl z, .LFSD__hA_exit
	; Display clear + redraw
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0124)
	ld xwa, 0x007f00d2
	ld xbc, 0x01c00001
	lds32 xde, 0
	call (xhl)
	jrl t, .LFSD__hA_exit
.LFSD__hA_cyl_fits:
	; Fits — setup display + dialog boxes
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0124)
	ld xwa, 0x007f02a9
	ld xbc, 0x01c00001
	lds32 xde, 0
	call (xhl)
	ld xwa, 0x01ca0002
	push xwa
	ld xwa, 0x007f00e2
	push xwa
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0418)
	ld xwa, 0x0000014d
	ld xbc, 0x007f02ab
	ld xde, 0xffffffff
	call (xhl)
	ld xwa, 0x01ca0002
	push xwa
	ld xwa, 0x007f00e2
	push xwa
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0410)
	ld xwa, 0x0000014d
	ld xbc, 0x007f02ab
	ld xde, 0xffffffff
	call (xhl)
	jrl t, .LFSD__hA_exit
.LFSD__hA_sector_info:			; Event 0x01EA0008: sector info display
	ldw_da xwa, 0x23a08e
	ld bc, iz
	add bc, wa
	stw_da 0x23a092, xbc
	ld wa, bc
	call HDAE5000_Calc_Offset_16
	ld xde, xhl
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0250)             ; XHL = (XWA+0x0250)
	ld xwa, 0x012a0019
	ld xbc, 0x01e00086
	call (xhl)
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0124)
	ld xwa, 0x007f017b
	ld xbc, 0x01c00001
	lds32 xde, 0
	call (xhl)
	jr t, .LFSD__hA_exit
.LFSD__hA_scroll_up:			; Event 0x01EA0001: scroll up
	cpw_da 0x23a08e, 0x0018
	jr lt, .LFSD__hA_exit
	subdi16_24	0x23A08E, 24
	ld xwa, 0x007f00e6
	calr HDAE5000_HD_Format_Params
	ld xwa, xiz
	add xwa, 0x00000018
	ld xde, xwa
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0124)
	ld xwa, 0x007f00e6
	ld xbc, 0x01ea0003
	call (xhl)
	jr t, .LFSD__hA_exit
.LFSD__hA_scroll_down:			; Event 0x01EA0000: scroll down
	cpw_da 0x23a08e, 0x0060
	jr ge, .LFSD__hA_exit
	adddi16_24	0x23A08E, 24
	ld xwa, 0x007f00e6
	calr HDAE5000_HD_Format_Params
	ld xwa, xiz
	sub xwa, 0x00000018
	ld xde, xwa
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0124)
	ld xwa, 0x007f00e6
	ld xbc, 0x01ea0003
	call (xhl)
.LFSD__hA_exit:
	lds32 xhl, 0
	pop xiz
	ret
	;
	; Part 3: Event handler — file operations (0x28A07E)
.LFSD__handlerB:
	push xiz
	ld xiz, xwa
	cp xbc, 0x01c00007
	jr z, .LFSD__hB_key
	cp xbc, 0x01e0007c
	jr z, .LFSD__hB_7c
	cp xbc, 0x01e00084
	jr z, .LFSD__hB_84
	cp xbc, 0x01e00086
	jr z, .LFSD__hB_86
	cp xbc, 0x01e0003a
	jrl nz, .LFSD__hB_default
	; Event 0x01E0003A: copy data block
	pushw 0x0010
	lda_24 xwa, 0x23a06e
	push xwa
	push xde
	call HDAE5000_MemCopy_Reverse
	lda xsp, (xsp + 0x0a)
	ld xhl, xiz
	jrl t, .LFSD__hB_exit2
.LFSD__hB_86:				; Event 0x01E00086: copy + clear flag
	pushw 0x0010
	push xde
	pushw 0x0023
	pushw 0xa06e
	call HDAE5000_MemCopy_Reverse
	lda xsp, (xsp + 0x0a)
	stib_da 0x23a07e, 0x00
	ld xhl, xiz
	jrl t, .LFSD__hB_exit2
.LFSD__hB_84:				; Event 0x01E00084
	lds32 xhl, 0
	jrl t, .LFSD__hB_exit2
.LFSD__hB_7c:				; Event 0x01E0007C
	ld xhl, 0x00000010
	jrl t, .LFSD__hB_exit2
.LFSD__hB_key:				; Event 0x01C00007: key dispatch
	cp xde, 0x0000000b
	jr z, .LFSD__hB_key_0b
	cp xde, 0x0000008a
	jrl nz, .LFSD__hB_default
	; Key 0x8A: validate string + copy
	lda_24 xwa, 0x22abf2
	calr HDAE5000_Validate_String
	ld xiz, xhl
	ld xwa, xiz
	or xwa, xwa
	jrl z, .LFSD__hB_default
	ld xwa, xiz
	push xwa
	call HDAE5000_Display_Buffer_Validate
	pushw hl                                ; push hl (compact)
	ld xwa, xiz
	push xwa
	lda_24 xwa, 0x23a06e
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 0x0e)
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xix, (xwa + 0x050c)             ; XIX = (XWA+0x050C)
	call (xix)
	lda_24 xwa, 0x23a06e
	ld xbc, xwa
	ld xwa, xhl
	ld xde, xbc
	ldl_da xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e0a)
	ld_sril xhl, (xbc + 0x0100)
	ld xbc, 0x01e00086
	call (xhl)
	jr t, .LFSD__hB_default
.LFSD__hB_key_0b:			; Key 0x0B: direct lookup
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xix, (xwa + 0x050c)
	call (xix)
	lda_24 xwa, 0x23a06e
	ld xbc, xwa
	ld xwa, xhl
	ld xde, xbc
	ldl_da xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e0a)
	ld_sril xhl, (xbc + 0x0100)
	ld xbc, 0x01e0003a
	call (xhl)
	; Update display
	ldw_da xwa, 0x23a092
	lda_24 xbc, 0x23a06e
	ld xde, 0x007f00e2
	calr HDAE5000_Menu_Handler
	ld xwa, 0x007f0025
	calr HDAE5000_HD_Format_Params
.LFSD__hB_default:
	lds32 xhl, 0
.LFSD__hB_exit2:
	pop xiz
	ret
	;
	; Part 4: Event handler — menu selection (0x28A1A7)
.LFSD__handlerC:
	dec 0, xsp			; alloc 4 bytes
	push xiz
	ld (xsp + 0x04), xde
	ld xiz, xbc
	ld (xsp + 0x08), xwa
	ld xwa, xiz
	cp xwa, 0x01c00007
	jr z, .LFSD__hC_key
	cp xwa, 0x01c0000d
	jr z, .LFSD__hC_0d
	cp xwa, 0x01e00085
	jrl nz, .LFSD__hC_default
	; Event 0x01E00085
	lds32 xhl, 1
	jrl t, .LFSD__hC_exit
.LFSD__hC_0d:				; Event 0x01C0000D: pass-through
	ld xwa, (xsp + 0x08)
	ld xbc, xiz
	ld xde, (xsp + 0x04)
	ldl_da xhl, 0x23a1a2
	ld_sril xhl, (xhl + 0x0e0a)
	ld_sril xhl, (xhl + 0x00dc)
	call (xhl)
	lda_24 xwa, 0x2e2f5c
	ld xbc, xwa
	ld xwa, (xsp + 0x08)
	ld xde, xbc
	ldl_da xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e0a)
	ld_sril xhl, (xbc + 0x0100)
	ld xbc, 0x01c0000f
	call (xhl)
	lds32 xhl, 0
	jrl t, .LFSD__hC_exit
.LFSD__hC_key:				; Event 0x01C00007: key dispatch
	ld xde, (xsp + 0x04)
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xix, (xwa + 0x0100)
	ld xwa, 0x02600024
	ld xbc, 0x01e00029
	call (xix)
	cp xhl, 0x00000007
	jr z, .LFSD__hC_key_67
	cp xhl, 0x00000006
	jr z, .LFSD__hC_key_67
	cp xhl, 0x00000001
	jr z, .LFSD__hC_key_1
	or xhl, xhl
	jrl nz, .LFSD__hC_default
.LFSD__hC_key_1:			; Key 0 or 1: register menu + display
	lda_24 xwa, 0x23a04e
	ld xde, xwa
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0100)
	ld xwa, 0x007f01ae
	ld xbc, 0x01e0003a
	call (xhl)
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0100)
	ld xwa, 0x007f004e
	ld xbc, 0x01c00001
	lds32 xde, 0
	call (xhl)
	pushw 0x0023
	pushw 0xa04e
	pushw 0x0001
	ld xwa, 0x007f0018
	push xwa
	ldw_da xwa, 0x23a092
	ldw_da xbc, 0x23a094
	ldw_da xde, 0x22aa4c
	calr HDAE5000_Display_Scroll
	lds wa, 0
	lds bc, 0
	calr HDAE5000_HD_Read_Write
	jr t, .LFSD__hC_default
.LFSD__hC_key_67:			; Key 6 or 7: close display
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0104)
	ld xwa, 0x007f0018
	ld xbc, 0x01c00001
	lds32 xde, 0
	call (xhl)
.LFSD__hC_default:			; Default: pass-through to registered handler
	ld xwa, (xsp + 0x08)
	ld xbc, xiz
	ld xde, (xsp + 0x04)
	ldl_da xhl, 0x23a1a2
	ld_sril xhl, (xhl + 0x0e0a)
	ld_sril xix, (xhl + 0x00dc)
	call (xix)
.LFSD__hC_exit:
	pop xiz
	inc 0, xsp
	ret

HDAE5000_FS_Entry_Lookup:	; 0x28A2F0 (739 bytes)
	; Look up a file entry in the filesystem
	; Part 1: 9 lookup blocks — read byte, lookup table, call handler
	; Block 1: address 0x22ABE8, command 0x007F01CF
	ldb_da xwa, 0x22abe8
	extz wa
	sla wa, 2
	lda_24 xbc, 0x2e1e14
	ld_sril3 xde, 0x07, 0xe4, 0xe0	; ld XDE, (XBC + WA)
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)             ; ld XWA, (XWA + 0x0E0A)
	ld_sril xhl, (xwa + 0x0104)             ; ld XHL, (XWA + 0x0104)
	ld xwa, 0x007f01cf
	ld xbc, 0x01c0000f
	call (xhl)
	; Block 2: address 0x22ABE9, command 0x007F01D0
	ldb_da xwa, 0x22abe9
	extz wa
	sla wa, 2
	lda_24 xbc, 0x2e1e14
	ld_sril3 xde, 0x07, 0xe4, 0xe0
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0104)
	ld xwa, 0x007f01d0
	ld xbc, 0x01c0000f
	call (xhl)
	; Block 3: address 0x22ABEA, command 0x007F01D1
	ldb_da xwa, 0x22abea
	extz wa
	sla wa, 2
	lda_24 xbc, 0x2e1e14
	ld_sril3 xde, 0x07, 0xe4, 0xe0
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0104)
	ld xwa, 0x007f01d1
	ld xbc, 0x01c0000f
	call (xhl)
	; Block 4: address 0x22ABEB, command 0x007F01D2
	ldb_da xwa, 0x22abeb
	extz wa
	sla wa, 2
	lda_24 xbc, 0x2e1e14
	ld_sril3 xde, 0x07, 0xe4, 0xe0
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0104)
	ld xwa, 0x007f01d2
	ld xbc, 0x01c0000f
	call (xhl)
	; Block 5: address 0x22ABEC, command 0x007F01D3
	ldb_da xwa, 0x22abec
	extz wa
	sla wa, 2
	lda_24 xbc, 0x2e1e14
	ld_sril3 xde, 0x07, 0xe4, 0xe0
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0104)
	ld xwa, 0x007f01d3
	ld xbc, 0x01c0000f
	call (xhl)
	; Block 6: address 0x22ABED, command 0x007F01D4
	ldb_da xwa, 0x22abed
	extz wa
	sla wa, 2
	lda_24 xbc, 0x2e1e14
	ld_sril3 xde, 0x07, 0xe4, 0xe0
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0104)
	ld xwa, 0x007f01d4
	ld xbc, 0x01c0000f
	call (xhl)
	; Block 7: address 0x22ABEE, command 0x007F01D5
	ldb_da xwa, 0x22abee
	extz wa
	sla wa, 2
	lda_24 xbc, 0x2e1e14
	ld_sril3 xde, 0x07, 0xe4, 0xe0
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0104)
	ld xwa, 0x007f01d5
	ld xbc, 0x01c0000f
	call (xhl)
	; Block 8: address 0x22ABEF, command 0x007F01D6
	ldb_da xwa, 0x22abef
	extz wa
	sla wa, 2
	lda_24 xbc, 0x2e1e14
	ld_sril3 xde, 0x07, 0xe4, 0xe0
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0104)
	ld xwa, 0x007f01d6
	ld xbc, 0x01c0000f
	call (xhl)
	; Block 9: address 0x22ABF0, command 0x007F01E9 (tail call)
	ldb_da xwa, 0x22abf0
	extz wa
	sla wa, 2
	lda_24 xbc, 0x2e1e14
	ld_sril3 xde, 0x07, 0xe4, 0xe0
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0104)
	ld xwa, 0x007f01e9
	ld xbc, 0x01c0000f
	jp (xhl)			; tail call (not call)
	;
	; Part 2: Event handler (0x28A497) — dispatches on event codes
.LFS_EL__handler:
	dec 0, xsp			; allocate 8 bytes
	push xiz
	ld (xsp + 0x04), xde		; save XDE to stack
	ld xiz, xbc			; save event code in XIZ
	ld (xsp + 0x08), xwa		; save XWA to stack
	ld xwa, xiz			; XWA = event code
	cp xwa, 0x01c00007		; event 0x01C00007?
	jr z, .LFS_EL__evt_07
	cp xwa, 0x01c0000d		; event 0x01C0000D?
	jr z, .LFS_EL__evt_0d
	cp xwa, 0x01e00085		; event 0x01E00085?
	jrl nz, .LFS_EL__exit		; no match → exit
	lds32 xhl, 1			; XHL = 1
	jrl t, .LFS_EL__epilogue
.LFS_EL__evt_0d:			; handler for event 0x0D
	ld xwa, (xsp + 0x08)		; restore XWA
	ld xbc, xiz
	ld xde, (xsp + 0x04)		; restore XDE
	ldl_da xhl, 0x23a1a2
	ld_sril xhl, (xhl + 0x0e0a)             ; ld XHL, (XHL + 0x0E0A)
	ld_sril xhl, (xhl + 0x00dc)             ; ld XHL, (XHL + 0x00DC)
	call (xhl)
	lda_24 xwa, 0x2e2f62		; status display data
	ld xbc, xwa
	ld xwa, (xsp + 0x08)
	ld xde, xbc
	ldl_da xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e0a)             ; ld XBC, (XBC + 0x0E0A)
	ld_sril xhl, (xbc + 0x0100)             ; ld XHL, (XBC + 0x0100)
	ld xbc, 0x01c0000f
	call (xhl)
	lds32 xhl, 0
	jrl t, .LFS_EL__epilogue
.LFS_EL__evt_07:			; handler for event 0x07
	ld xde, (xsp + 0x04)
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xix, (xwa + 0x0100)             ; ld XIX, (XWA + 0x0100)
	ld xwa, 0x02600024
	ld xbc, 0x01e00029
	call (xix)
	; Check return value in XHL
	cp xhl, 0x0000000b
	jr z, .LFS_EL__case_0b
	cp xhl, 0x0000000a
	jr z, .LFS_EL__case_0a
	cp xhl, 0x00000008
	jr nz, .LFS_EL__exit
	; Case 0x08: delete file entry
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0124)             ; ld XHL, (XWA + 0x0124)
	ld xwa, 0x007f01fb
	ld xbc, 0x01c00001
	lds32 xde, 0
	call (xhl)
	jr t, .LFS_EL__exit
.LFS_EL__case_0a:			; Case 0x0A: copy file
	ldw_da xwa, 0x23a092
	ldw_da xbc, 0x23a094
	call HDAE5000_Table_Lookup
	ld wa, hl
	cp wa, 0xffff
	jr z, .LFS_EL__0a_skip
	lda_24 xwa, 0x22abe6
	pushw 0x0002
	ld bc, hl
	lda_24 xde, 0x2e1e08
	calr HDAE5000_HD_Data_Copy
.LFS_EL__0a_skip:
	calr HDAE5000_FS_Entry_Lookup	; recursive call
	jr t, .LFS_EL__exit
.LFS_EL__case_0b:			; Case 0x0B: save file
	ldw_da xwa, 0x23a092
	ldw_da xbc, 0x23a094
	call HDAE5000_Table_Lookup
	ld wa, hl
	cp wa, 0xffff
	jr z, .LFS_EL__0b_skip
	lda_24 xwa, 0x22abe6
	pushw 0x0001
	ld bc, hl
	lda_24 xde, 0x2e1e08
	calr HDAE5000_HD_Data_Copy
.LFS_EL__0b_skip:
	stiw_da 0x22abe6, 0x0000	; clear entry
	calr HDAE5000_FS_Entry_Lookup	; recursive call
.LFS_EL__exit:				; common exit path
	ld xwa, (xsp + 0x08)		; restore registers
	ld xbc, xiz
	ld xde, (xsp + 0x04)
	ldl_da xhl, 0x23a1a2
	ld_sril xhl, (xhl + 0x0e0a)             ; ld XHL, (XHL + 0x0E0A)
	ld_sril xix, (xhl + 0x00dc)             ; ld XIX, (XHL + 0x00DC)
	call (xix)
.LFS_EL__epilogue:
	pop xiz
	inc 0, xsp			; deallocate 8 bytes
	ret

; --- Display, Menu, and Utility Routines ---
HDAE5000_Display_Update_Offset:	; 0x28A5D3 (1612 bytes)
	; Part 1: Table lookup + data copy utility (68 bytes)
	ldw_da xwa, 0x23a092		; WA = cylinder
	ldw_da xbc, 0x23a094	; BC = head
	call HDAE5000_Table_Lookup
	ld wa, hl
	cp wa, 0xffff
	jr z, .LDUO__not_found
	; Found — copy data
	lda_24 xwa, 0x22abe6
	pushw 0x0002
	ld bc, hl
	lda_24 xde, 0x2e1e08
	calr HDAE5000_HD_Data_Copy
	jr t, .LDUO__done_p1
.LDUO__not_found:
	lda_24 xwa, 0x22abe6
	pushw 0x0002
	lda_24 xde, 0x2e1e08
	lds bc, 0
	calr HDAE5000_HD_Data_Copy
.LDUO__done_p1:
	stiw_da 0x22abe6, 0x0000
	ret
	;
	; Part 2: Handler A (0x28A617) — event handler with stack frame
.LDUO__handlerA:
	dec 4, xsp			; alloc 16 bytes
	push xiz
	ld (xsp + 0x04), xwa
	ld xwa, xbc
	cp xwa, 0x01e00082
	jr z, .LDUO__hA_ev82
	sub xwa, 0x01e0003e		; normalize event code
	cp xwa, 0x00000000
	jr lt, .LDUO__hA_default
	cp xwa, 0x00000009
	jr gt, .LDUO__hA_default
	add xwa, xwa
	add xwa, 0x002e2f6c		; jump table
	ld wa, (xwa)
	lda_24 xix, 0x28a651		; dispatch base
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp (XIX + WA)
	; Case 0: full lookup
	ld xiz, xde
	ldw_da xwa, 0x23a092
	ldw_da xbc, 0x23a094
	call HDAE5000_Calculate_Row_Address
	push xhl
	pushw 0x002e
	pushw 0x2f68
	ld xwa, (xiz + 0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda xsp, (xsp + 0x0c)
	ld xhl, (xsp + 0x04)
	jr t, .LDUO__hA_exit
	; Case 1
	lds32 xhl, 1
	jr t, .LDUO__hA_exit
	; Case 2
	lds32 xhl, 1
	jr t, .LDUO__hA_exit
	; Case 3
	lds32 xhl, 0
	jr t, .LDUO__hA_exit
	; Case 4
	lds32 xhl, 0
	jr t, .LDUO__hA_exit
	; Case 5
	lda_24 xhl, 0x22aa57
	jr t, .LDUO__hA_exit
	; Case 6
	lds32 xhl, 1
	jr t, .LDUO__hA_exit
.LDUO__hA_ev82:
	lds32 xhl, 0
	jr t, .LDUO__hA_exit
.LDUO__hA_default:
	lds32 xhl, 0
.LDUO__hA_exit:
	pop xiz
	inc 4, xsp
	ret
	;
	; Part 3: Handler B (0x28A69D) — digit callback for slot 0 (0x22ABE8)
.LDUO__handlerB:
	push xiz
	ld xiz, xwa
	ld xwa, xbc
	cp xwa, 0x01e00082
	jr z, .LDUO__hB_ev82
	sub xwa, 0x01e0003e
	cp xwa, 0x00000000
	jr lt, .LDUO__hB_default
	cp xwa, 0x00000009
	jr gt, .LDUO__hB_default
	add xwa, xwa
	add xwa, 0x002e2f84
	ld wa, (xwa)
	lda_24 xix, 0x28a6d4
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp (XIX + WA)
	; Case 0: index + format + display
	ld xwa, (xde + 0x0e)
	sll xwa, 2
	ld xbc, 0x002e1e14
	add xbc, xwa
	ld xwa, (xbc)
	push xwa
	pushw 0x002e
	pushw 0x2f80
	ld xwa, (xde + 0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda xsp, (xsp + 0x0c)
	ld xhl, xiz
	jr t, .LDUO__hB_exit
	; Case 1
	lds32 xhl, 1
	jr t, .LDUO__hB_exit
	; Case 2
	lds32 xhl, 1
	jr t, .LDUO__hB_exit
	; Case 3: conditional on (0x22abe8)
	lds32 xhl, 2
	cpib_da 0x22abe8, 0x00
	jr nz, .LDUO__hB_c3_nz
	lds32 xhl, 0
.LDUO__hB_c3_nz:
	jr t, .LDUO__hB_exit
	; Case 4: conditional on (0x22abe8)
	lds32 xhl, 1
	cpib_da 0x22abe8, 0x00
	jr nz, .LDUO__hB_c4_nz
	lds32 xhl, 0
.LDUO__hB_c4_nz:
	jr t, .LDUO__hB_exit
	; Case 5
	lda_24 xhl, 0x22abe8
	jr t, .LDUO__hB_exit
	; Case 6
	lds32 xhl, 1
	jr t, .LDUO__hB_exit
.LDUO__hB_ev82:
	lda_24 xwa, 0x22abe6
	calr HDAE5000_HD_Buffer_Init
	lds32 xhl, 0
	jr t, .LDUO__hB_exit
.LDUO__hB_default:
	lds32 xhl, 0
.LDUO__hB_exit:
	pop xiz
	ret
	;
	; Part 4: Handler C (0x28A738) — slot 1 (0x22ABE9)
.LDUO__handlerC:
	push xiz
	ld xiz, xwa
	ld xwa, xbc
	cp xwa, 0x01e00082
	jr z, .LDUO__hC_ev82
	sub xwa, 0x01e0003e
	cp xwa, 0x00000000
	jr lt, .LDUO__hC_default
	cp xwa, 0x00000009
	jr gt, .LDUO__hC_default
	add xwa, xwa
	add xwa, 0x002e2f9c
	ld wa, (xwa)
	lda_24 xix, 0x28a76f
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp (XIX + WA)
	; Case 0
	ld xwa, (xde + 0x0e)
	sll xwa, 2
	ld xbc, 0x002e1e14
	add xbc, xwa
	ld xwa, (xbc)
	push xwa
	pushw 0x002e
	pushw 0x2f98
	ld xwa, (xde + 0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda xsp, (xsp + 0x0c)
	ld xhl, xiz
	jr t, .LDUO__hC_exit
	; Case 1
	lds32 xhl, 1
	jr t, .LDUO__hC_exit
	; Case 2
	lds32 xhl, 1
	jr t, .LDUO__hC_exit
	; Case 3
	lds32 xhl, 2
	cpib_da 0x22abe9, 0x00
	jr nz, .LDUO__hC_c3_nz
	lds32 xhl, 0
.LDUO__hC_c3_nz:
	jr t, .LDUO__hC_exit
	; Case 4
	lds32 xhl, 1
	cpib_da 0x22abe9, 0x00
	jr nz, .LDUO__hC_c4_nz
	lds32 xhl, 0
.LDUO__hC_c4_nz:
	jr t, .LDUO__hC_exit
	; Case 5
	lda_24 xhl, 0x22abe9
	jr t, .LDUO__hC_exit
	; Case 6
	lds32 xhl, 1
	jr t, .LDUO__hC_exit
.LDUO__hC_ev82:
	lda_24 xwa, 0x22abe6
	calr HDAE5000_HD_Buffer_Init
	lds32 xhl, 0
	jr t, .LDUO__hC_exit
.LDUO__hC_default:
	lds32 xhl, 0
.LDUO__hC_exit:
	pop xiz
	ret
	;
	; Part 5: Handler D (0x28A7D3) — slot 2 (0x22ABEA)
.LDUO__handlerD:
	push xiz
	ld xiz, xwa
	ld xwa, xbc
	cp xwa, 0x01e00082
	jr z, .LDUO__hD_ev82
	sub xwa, 0x01e0003e
	cp xwa, 0x00000000
	jr lt, .LDUO__hD_default
	cp xwa, 0x00000009
	jr gt, .LDUO__hD_default
	add xwa, xwa
	add xwa, 0x002e2fb4
	ld wa, (xwa)
	lda_24 xix, 0x28a80a
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp (XIX + WA)
	; Case 0
	ld xwa, (xde + 0x0e)
	sll xwa, 2
	ld xbc, 0x002e1e14
	add xbc, xwa
	ld xwa, (xbc)
	push xwa
	pushw 0x002e
	pushw 0x2fb0
	ld xwa, (xde + 0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda xsp, (xsp + 0x0c)
	ld xhl, xiz
	jr t, .LDUO__hD_exit
	; Case 1
	lds32 xhl, 1
	jr t, .LDUO__hD_exit
	; Case 2
	lds32 xhl, 1
	jr t, .LDUO__hD_exit
	; Case 3
	lds32 xhl, 2
	cpib_da 0x22abea, 0x00
	jr nz, .LDUO__hD_c3_nz
	lds32 xhl, 0
.LDUO__hD_c3_nz:
	jr t, .LDUO__hD_exit
	; Case 4
	lds32 xhl, 1
	cpib_da 0x22abea, 0x00
	jr nz, .LDUO__hD_c4_nz
	lds32 xhl, 0
.LDUO__hD_c4_nz:
	jr t, .LDUO__hD_exit
	; Case 5
	lda_24 xhl, 0x22abea
	jr t, .LDUO__hD_exit
	; Case 6
	lds32 xhl, 1
	jr t, .LDUO__hD_exit
.LDUO__hD_ev82:
	lda_24 xwa, 0x22abe6
	calr HDAE5000_HD_Buffer_Init
	lds32 xhl, 0
	jr t, .LDUO__hD_exit
.LDUO__hD_default:
	lds32 xhl, 0
.LDUO__hD_exit:
	pop xiz
	ret
	;
	; Part 6: Handler E (0x28A86E) — slot 3 (0x22ABEB)
.LDUO__handlerE:
	push xiz
	ld xiz, xwa
	ld xwa, xbc
	cp xwa, 0x01e00082
	jr z, .LDUO__hE_ev82
	sub xwa, 0x01e0003e
	cp xwa, 0x00000000
	jr lt, .LDUO__hE_default
	cp xwa, 0x00000009
	jr gt, .LDUO__hE_default
	add xwa, xwa
	add xwa, 0x002e2fcc
	ld wa, (xwa)
	lda_24 xix, 0x28a8a5
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp (XIX + WA)
	; Case 0
	ld xwa, (xde + 0x0e)
	sll xwa, 2
	ld xbc, 0x002e1e14
	add xbc, xwa
	ld xwa, (xbc)
	push xwa
	pushw 0x002e
	pushw 0x2fc8
	ld xwa, (xde + 0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda xsp, (xsp + 0x0c)
	ld xhl, xiz
	jr t, .LDUO__hE_exit
	; Case 1
	lds32 xhl, 1
	jr t, .LDUO__hE_exit
	; Case 2
	lds32 xhl, 1
	jr t, .LDUO__hE_exit
	; Case 3
	lds32 xhl, 2
	cpib_da 0x22abeb, 0x00
	jr nz, .LDUO__hE_c3_nz
	lds32 xhl, 0
.LDUO__hE_c3_nz:
	jr t, .LDUO__hE_exit
	; Case 4
	lds32 xhl, 1
	cpib_da 0x22abeb, 0x00
	jr nz, .LDUO__hE_c4_nz
	lds32 xhl, 0
.LDUO__hE_c4_nz:
	jr t, .LDUO__hE_exit
	; Case 5
	lda_24 xhl, 0x22abeb
	jr t, .LDUO__hE_exit
	; Case 6
	lds32 xhl, 1
	jr t, .LDUO__hE_exit
.LDUO__hE_ev82:
	lda_24 xwa, 0x22abe6
	calr HDAE5000_HD_Buffer_Init
	lds32 xhl, 0
	jr t, .LDUO__hE_exit
.LDUO__hE_default:
	lds32 xhl, 0
.LDUO__hE_exit:
	pop xiz
	ret
	;
	; Part 7: Handler F (0x28A909) — slot 4 (0x22ABEC)
.LDUO__handlerF:
	push xiz
	ld xiz, xwa
	ld xwa, xbc
	cp xwa, 0x01e00082
	jr z, .LDUO__hF_ev82
	sub xwa, 0x01e0003e
	cp xwa, 0x00000000
	jr lt, .LDUO__hF_default
	cp xwa, 0x00000009
	jr gt, .LDUO__hF_default
	add xwa, xwa
	add xwa, 0x002e2fe4
	ld wa, (xwa)
	lda_24 xix, 0x28a940
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp (XIX + WA)
	; Case 0
	ld xwa, (xde + 0x0e)
	sll xwa, 2
	ld xbc, 0x002e1e14
	add xbc, xwa
	ld xwa, (xbc)
	push xwa
	pushw 0x002e
	pushw 0x2fe0
	ld xwa, (xde + 0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda xsp, (xsp + 0x0c)
	ld xhl, xiz
	jr t, .LDUO__hF_exit
	; Case 1
	lds32 xhl, 1
	jr t, .LDUO__hF_exit
	; Case 2
	lds32 xhl, 1
	jr t, .LDUO__hF_exit
	; Case 3
	lds32 xhl, 2
	cpib_da 0x22abec, 0x00
	jr nz, .LDUO__hF_c3_nz
	lds32 xhl, 0
.LDUO__hF_c3_nz:
	jr t, .LDUO__hF_exit
	; Case 4
	lds32 xhl, 1
	cpib_da 0x22abec, 0x00
	jr nz, .LDUO__hF_c4_nz
	lds32 xhl, 0
.LDUO__hF_c4_nz:
	jr t, .LDUO__hF_exit
	; Case 5
	lda_24 xhl, 0x22abec
	jr t, .LDUO__hF_exit
	; Case 6
	lds32 xhl, 1
	jr t, .LDUO__hF_exit
.LDUO__hF_ev82:
	lda_24 xwa, 0x22abe6
	calr HDAE5000_HD_Buffer_Init
	lds32 xhl, 0
	jr t, .LDUO__hF_exit
.LDUO__hF_default:
	lds32 xhl, 0
.LDUO__hF_exit:
	pop xiz
	ret
	;
	; Part 8: Handler G (0x28A9A4) — slot 5 (0x22ABED)
.LDUO__handlerG:
	push xiz
	ld xiz, xwa
	ld xwa, xbc
	cp xwa, 0x01e00082
	jr z, .LDUO__hG_ev82
	sub xwa, 0x01e0003e
	cp xwa, 0x00000000
	jr lt, .LDUO__hG_default
	cp xwa, 0x00000009
	jr gt, .LDUO__hG_default
	add xwa, xwa
	add xwa, 0x002e2ffc
	ld wa, (xwa)
	lda_24 xix, 0x28a9db
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp (XIX + WA)
	; Case 0
	ld xwa, (xde + 0x0e)
	sll xwa, 2
	ld xbc, 0x002e1e14
	add xbc, xwa
	ld xwa, (xbc)
	push xwa
	pushw 0x002e
	pushw 0x2ff8
	ld xwa, (xde + 0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda xsp, (xsp + 0x0c)
	ld xhl, xiz
	jr t, .LDUO__hG_exit
	; Case 1
	lds32 xhl, 1
	jr t, .LDUO__hG_exit
	; Case 2
	lds32 xhl, 1
	jr t, .LDUO__hG_exit
	; Case 3
	lds32 xhl, 2
	cpib_da 0x22abed, 0x00
	jr nz, .LDUO__hG_c3_nz
	lds32 xhl, 0
.LDUO__hG_c3_nz:
	jr t, .LDUO__hG_exit
	; Case 4
	lds32 xhl, 1
	cpib_da 0x22abed, 0x00
	jr nz, .LDUO__hG_c4_nz
	lds32 xhl, 0
.LDUO__hG_c4_nz:
	jr t, .LDUO__hG_exit
	; Case 5
	lda_24 xhl, 0x22abed
	jr t, .LDUO__hG_exit
	; Case 6
	lds32 xhl, 1
	jr t, .LDUO__hG_exit
.LDUO__hG_ev82:
	lda_24 xwa, 0x22abe6
	calr HDAE5000_HD_Buffer_Init
	lds32 xhl, 0
	jr t, .LDUO__hG_exit
.LDUO__hG_default:
	lds32 xhl, 0
.LDUO__hG_exit:
	pop xiz
	ret
	;
	; Part 9: Handler H (0x28AA3F) — slot 6 (0x22ABEE)
.LDUO__handlerH:
	push xiz
	ld xiz, xwa
	ld xwa, xbc
	cp xwa, 0x01e00082
	jr z, .LDUO__hH_ev82
	sub xwa, 0x01e0003e
	cp xwa, 0x00000000
	jr lt, .LDUO__hH_default
	cp xwa, 0x00000009
	jr gt, .LDUO__hH_default
	add xwa, xwa
	add xwa, 0x002e3014
	ld wa, (xwa)
	lda_24 xix, 0x28aa76
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp (XIX + WA)
	; Case 0
	ld xwa, (xde + 0x0e)
	sll xwa, 2
	ld xbc, 0x002e1e14
	add xbc, xwa
	ld xwa, (xbc)
	push xwa
	pushw 0x002e
	pushw 0x3010
	ld xwa, (xde + 0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda xsp, (xsp + 0x0c)
	ld xhl, xiz
	jr t, .LDUO__hH_exit
	; Case 1
	lds32 xhl, 1
	jr t, .LDUO__hH_exit
	; Case 2
	lds32 xhl, 1
	jr t, .LDUO__hH_exit
	; Case 3
	lds32 xhl, 2
	cpib_da 0x22abee, 0x00
	jr nz, .LDUO__hH_c3_nz
	lds32 xhl, 0
.LDUO__hH_c3_nz:
	jr t, .LDUO__hH_exit
	; Case 4
	lds32 xhl, 1
	cpib_da 0x22abee, 0x00
	jr nz, .LDUO__hH_c4_nz
	lds32 xhl, 0
.LDUO__hH_c4_nz:
	jr t, .LDUO__hH_exit
	; Case 5
	lda_24 xhl, 0x22abee
	jr t, .LDUO__hH_exit
	; Case 6
	lds32 xhl, 1
	jr t, .LDUO__hH_exit
.LDUO__hH_ev82:
	lda_24 xwa, 0x22abe6
	calr HDAE5000_HD_Buffer_Init
	lds32 xhl, 0
	jr t, .LDUO__hH_exit
.LDUO__hH_default:
	lds32 xhl, 0
.LDUO__hH_exit:
	pop xiz
	ret
	;
	; Part 10: Handler I (0x28AADA) — slot 7 (0x22ABEF)
.LDUO__handlerI:
	push xiz
	ld xiz, xwa
	ld xwa, xbc
	cp xwa, 0x01e00082
	jr z, .LDUO__hI_ev82
	sub xwa, 0x01e0003e
	cp xwa, 0x00000000
	jr lt, .LDUO__hI_default
	cp xwa, 0x00000009
	jr gt, .LDUO__hI_default
	add xwa, xwa
	add xwa, 0x002e302c
	ld wa, (xwa)
	lda_24 xix, 0x28ab11
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp (XIX + WA)
	; Case 0
	ld xwa, (xde + 0x0e)
	sll xwa, 2
	ld xbc, 0x002e1e14
	add xbc, xwa
	ld xwa, (xbc)
	push xwa
	pushw 0x002e
	pushw 0x3028
	ld xwa, (xde + 0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda xsp, (xsp + 0x0c)
	ld xhl, xiz
	jr t, .LDUO__hI_exit
	; Case 1
	lds32 xhl, 1
	jr t, .LDUO__hI_exit
	; Case 2
	lds32 xhl, 1
	jr t, .LDUO__hI_exit
	; Case 3
	lds32 xhl, 2
	cpib_da 0x22abef, 0x00
	jr nz, .LDUO__hI_c3_nz
	lds32 xhl, 0
.LDUO__hI_c3_nz:
	jr t, .LDUO__hI_exit
	; Case 4
	lds32 xhl, 1
	cpib_da 0x22abef, 0x00
	jr nz, .LDUO__hI_c4_nz
	lds32 xhl, 0
.LDUO__hI_c4_nz:
	jr t, .LDUO__hI_exit
	; Case 5
	lda_24 xhl, 0x22abef
	jr t, .LDUO__hI_exit
	; Case 6
	lds32 xhl, 1
	jr t, .LDUO__hI_exit
.LDUO__hI_ev82:
	lda_24 xwa, 0x22abe6
	calr HDAE5000_HD_Buffer_Init
	lds32 xhl, 0
	jr t, .LDUO__hI_exit
.LDUO__hI_default:
	lds32 xhl, 0
.LDUO__hI_exit:
	pop xiz
	ret
	;
	; Part 11: Handler J (0x28AB75) — slot 8 (0x22ABF0), variant with jrl
.LDUO__handlerJ:
	push xiz
	ld xiz, xwa
	ld xwa, xbc
	cp xwa, 0x01e00082
	jrl z, .LDUO__hJ_ev82
	sub xwa, 0x01e0003e
	cp xwa, 0x00000000
	jrl lt, .LDUO__hJ_default
	cp xwa, 0x00000009
	jrl gt, .LDUO__hJ_default
	add xwa, xwa
	add xwa, 0x002e3044
	ld wa, (xwa)
	lda_24 xix, 0x28abaf
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp (XIX + WA)
	; Case 0
	ld xwa, (xde + 0x0e)
	sll xwa, 2
	ld xbc, 0x002e1e14
	add xbc, xwa
	ld xwa, (xbc)
	push xwa
	pushw 0x002e
	pushw 0x3040
	ld xwa, (xde + 0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda xsp, (xsp + 0x0c)
	ld xhl, xiz
	jr t, .LDUO__hJ_exit
	; Case 1
	lds32 xhl, 1
	jr t, .LDUO__hJ_exit
	; Case 2
	lds32 xhl, 1
	jr t, .LDUO__hJ_exit
	; Case 3
	lds32 xhl, 2
	cpib_da 0x22abf0, 0x00
	jr nz, .LDUO__hJ_c3_nz
	lds32 xhl, 0
.LDUO__hJ_c3_nz:
	jr t, .LDUO__hJ_exit
	; Case 4: extra comparison vs 0x01
	cpib_da 0x22abf0, 0x01
	jr nz, .LDUO__hJ_c4_ne1
	lds32 xhl, 2
	jr t, .LDUO__hJ_c4_chk
.LDUO__hJ_c4_ne1:
	lds32 xhl, 1
.LDUO__hJ_c4_chk:
	cpib_da 0x22abf0, 0x00
	jr nz, .LDUO__hJ_c4_nz
	lds32 xhl, 0
.LDUO__hJ_c4_nz:
	jr t, .LDUO__hJ_exit
	; Case 5
	lda_24 xhl, 0x22abf0
	jr t, .LDUO__hJ_exit
	; Case 6
	lds32 xhl, 1
	jr t, .LDUO__hJ_exit
.LDUO__hJ_ev82:
	lda_24 xwa, 0x22abe6
	calr HDAE5000_HD_Buffer_Init
	lds32 xhl, 0
	jr t, .LDUO__hJ_exit
.LDUO__hJ_default:
	lds32 xhl, 0
.LDUO__hJ_exit:
	pop xiz
	ret

