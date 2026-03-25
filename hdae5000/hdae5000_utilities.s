HDAE5000_Code_Remainder:	; 29AF2Dh
	; Validate display buffer and read file data
	; Input: (XSP+8) = XIZ context, (XSP+0x12) = XWA file params
	push xiz
	ld xiz, (xsp + 8)		; load context pointer
	push xiz			; arg for Display_Buffer_Validate
	call HDAE5000_Display_Buffer_Validate
	pushw hl			; save validation result
	ld xwa, (xsp + 0x12)		; load file params
	push xwa			; arg 2
	push xiz			; arg 1
	call HDAE5000_File_Read
	lda xsp, (xsp + 0x0E)		; clean up 14 bytes
	pop xiz
	ret

HDAE5000_MemCopy_Block:	; 0x29AF45
	; Block memory copy with null-termination
	; Stack: [+0x10] source ptr, [+0x0C] dest ptr (XIZ context)
	; Calls String_Copy_N with limit 0xFFFE, null-terminates if successful
	; Returns: XHL = dest pointer (XIZ)
	push xiz
	pushw 0xFFFE			; max length
	pushw 0x0000			; flags
	ld xwa, (xsp + 0x10)		; source pointer
	push xwa
	ld xiz, (xsp + 0x10)		; dest pointer
	push xiz
	call HDAE5000_String_Copy_N
	add xsp, 0x0000000C		; clean up 12 bytes
	or xhl, xhl			; test result
	jr nz, .Lmcb_done
	ld xwa, xiz			; get dest pointer
	add xwa, 0x0000FFFF		; point to last byte
	ld (xwa), 0x00		; null-terminate
.Lmcb_done:
	ld xhl, xiz			; return dest pointer
	pop xiz
	ret

HDAE5000_Display_Buffer_Validate:	; 0x29AF71
	; Validate display buffer - call String_Length, return offset or -1
	; Stack: [+0x0C] = buffer pointer (XIZ)
	; Returns: HL = offset from XIZ or -1 on failure
	push xiz
	pushw 0xFFFF			; sentinel
	pushw 0x0000			; flags
	ld xiz, (xsp + 0x0C)		; buffer pointer
	push xiz
	call HDAE5000_String_Length
	inc 0, xsp			; clean up 8 bytes
	or xhl, xhl			; test result
	jr nz, .Ldbv_ok
	ldw hl, 0xFFFF			; return -1
	jr t, .Ldbv_done
.Ldbv_ok:
	sub xhl, xiz			; HL = length (offset from base)
.Ldbv_done:
	pop xiz
	ret
	; --- String copy with length limit (secondary entry) ---
	; Stack: [+0x04] dest, [+0x08] source, [+0x0C] count
	; Returns: XHL = end of copied string
	ld xix, (xsp + 4)		; XIX = dest
	ld xhl, xix			; XHL = dest (for return)
	jr t, .Lscl_entry
.Lscl_next:
	inc 1, xix
.Lscl_entry:
	cp (xix), 0x00		; find end of dest string
	jr nz, .Lscl_next
	ld xde, (xsp + 8)		; XDE = source
	ld bc, (xsp + 0x0C)		; BC = count
	jr t, .Lscl_check
.Lscl_copy:
	ld a, (xde)			; load source byte
	ld (xix), a			; store to dest
	cp (xix), 0x00		; was it null terminator?
	ret z				; yes - done
	inc 1, xix
	inc 1, xde
.Lscl_check:
	ld wa, bc			; save current count
	dec 1, bc			; decrement remaining
	cps wa, 0			; was count zero?
	jr nz, .Lscl_copy		; no - copy next byte
	ld (xix), 0x00		; null-terminate
	ret

HDAE5000_MemCompare_Block:	; 0x29AFBE
	; Compare two memory blocks byte-by-byte
	; Stack: [+0x04] block A (XIX), [+0x08] block B (XDE), [+0x0C] count (BC)
	; Returns: HL = 0 if match, else sign-extended difference of first mismatch
	ld bc, (xsp + 0x0C)		; BC = count
	ld xde, (xsp + 8)		; XDE = block B
	ld xix, (xsp + 4)		; XIX = block A
	jr t, .Lmcmp_check
.Lmcmp_loop:
	cp (xix), 0x00		; block A byte is null?
	jr nz, .Lmcmp_advance
	lds hl, 0			; return 0 (match up to null)
	ret
.Lmcmp_advance:
	inc 1, xix
	inc 1, xde
	dec 1, bc
.Lmcmp_check:
	cps bc, 0			; count exhausted?
	jr z, .Lmcmp_result
	ld a, (xde)			; B byte
	cp a, (xix)			; compare with A byte
	jr z, .Lmcmp_loop		; equal - continue
.Lmcmp_result:
	ldb l, 0x00			; default L = 0
	cps bc, 0			; if count exhausted, return 0
	jr z, .Lmcmp_done
	ld a, (xix)			; A byte
	sub a, (xde)			; difference = A - B
	ld l, a
.Lmcmp_done:
	exts hl				; sign-extend L to HL
	ret

HDAE5000_MemCopy_Reverse:	; 0x29AFF0
	; Memory copy (reverse direction)
; LMCR: 0x29AFF0 (1853 bytes)

	ld	bc, (xsp+12)
	ld xde, (xsp + 0x08)                    ; ld XDE,(XSP+0x08)
	ld xix, (xsp + 0x04)                    ; ld XIX,(XSP+0x04)
	ld	xhl, xix
	jr t, .LMCR_b005                       ; [68 08] jr T,0x29b005
.LMCR_affd:
	ldb_spi a, 0xe8		; ld A,(XDE+)
	lda_dpi xbc, 0xf0		; ld (XIX+),A
	dec	1, bc
.LMCR_b005:
	cps	bc, 0
	jr z, .LMCR_b00e                       ; [66 05] jr Z,0x29b00e
	cp	(xde), 0x00
	jr nz, .LMCR_affd                      ; [6e ef] jr NZ,0x29affd
.LMCR_b00e:
	jr t, .LMCR_b016                       ; [68 06] jr T,0x29b016
.LMCR_b010:
	stib_dsp 0xf0, 0x00		; ld (XIX+),0x00
	dec	1, bc
.LMCR_b016:
	cps	bc, 0
	jr nz, .LMCR_b010                      ; [6e f6] jr NZ,0x29b010
	ret

	push xiz
	ld xiz, (xsp + 0x08)                    ; ld XIZ,(XSP+0x08)
	push xiz
	call HDAE5000_Display_Buffer_Validate
	inc 4, xsp                              ; inc 4,XSP
	extz xhl                                ; extz XHL
	ld	xix, xhl
	add	xix, xiz
	dec	1, xix
	cp	xiz, xix
	jr nc, .LMCR_b049                      ; [6f 17] jr NC,0x29b049
	ld	xbc, xiz
	ld	xde, xix
.LMCR_b036:
	ld	a, (xbc)
	ld8_src_ri xde, l		; ld L,(XDE)
	lda_dpi xsp, 0xe4		; ld (XBC+),L
	ld	(xde), a
	inc 1, xiz                              ; inc 1,XIZ
	dec	1, xde
	dec	1, xix
	cp	xiz, xix
	jr c, .LMCR_b036                       ; [67 ed] jr C,0x29b036
.LMCR_b049:
	ld xhl, (xsp + 0x08)                    ; ld XHL,(XSP+0x08)
	pop xiz                                 ; pop XIZ
	ret

	ld xix, (xsp + 0x04)                    ; ld XIX,(XSP+0x04)
	ld	xhl, xix
	jr t, .LMCR_b074                       ; [68 1f] jr T,0x29b074
.LMCR_b055:
	ld	xde, xix
	ld	a, (xix)
	extz wa                                 ; extz WA
	lda_24 xbc, 0x2f9362
	bit_dri 1, 0x07, 0xE4, 0xE0	; bit 1,(XBC+WA)
	jr z, .LMCR_b06e                       ; [66 07] jr Z,0x29b06e
	ld	a, (xix)
	sub	a, 0x20
	jr t, .LMCR_b070                       ; [68 02] jr T,0x29b070
.LMCR_b06e:
	ld	a, (xix)
.LMCR_b070:
	ld	(xde), a
	inc 1, xix                              ; inc 1,XIX
.LMCR_b074:
	cp	(xix), 0x00
	jr nz, .LMCR_b055                      ; [6e dc] jr NZ,0x29b055
	ret

	lda	xsp, (xsp-16)
	push xiz
	lds	iz, 0
	ldw (xsp + 0x06), 15
	ldw (xsp + 0x08), 8
	pushw 0x0020
	pushw 0x0000
	pushw 0x0023
	pushw 0x948a
	call HDAE5000_MemFill
	inc 0, xsp                              ; inc 0,XSP
	ld	qiz, 0
.LMCR_b09f:
	ld	bc, qiz
	add	bc, bc
	lda_24 xde, 0x2394ea
	lda_24 xwa, 0x2394aa
	stiw_ind 0x07, 0xE0, 0xE4, 0x00, 0x00	; ld (XWA+BC),0x0000
	stiw_ind 0x07, 0xE8, 0xE4, 0x00, 0x00	; ld (XDE+BC),0x0000
	inc	1, qiz
	cpw	qiz, 0x0020
	jr lt, .LMCR_b09f                      ; [61 d9] jr LT,0x29b09f
	ld	wa, (xsp+32)
	bit	0x07, wa
	jr z, .LMCR_b0d8                       ; [66 0a] jr Z,0x29b0d8
	ldw (xsp + 0x06), 18
	ldw (xsp + 0x08), 10
.LMCR_b0d8:
	ld	qiz, 0
	cpw	(xsp+8), 0x0000
	jr le, .LMCR_b104                      ; [62 22] jr LE,0x29b104
.LMCR_b0e2:
	lda	xwa, (xsp+10)
	ld	bc, (xsp+8)
	dec	1, bc
	sub	bc, qiz
	extz xbc                                ; extz XBC
	add	xbc, (xsp+24)
	ld	c, (xbc)
	lda_dri xhl, 0x07, 0xE0, 0xFA	; ld (XWA+QIZ),C
	inc	1, qiz
	ld	wa, qiz
	cp	wa, (xsp+8)
	jr lt, .LMCR_b0e2                      ; [61 de] jr LT,0x29b0e2
.LMCR_b104:
	lda	xde, (xsp+10)
	bitm	7, (xde)
	jr z, .LMCR_b10f                       ; [66 04] jr Z,0x29b10f
	lds	wa, 1
	jr t, .LMCR_b111                       ; [68 02] jr T,0x29b111
.LMCR_b10f:
	lds	wa, 0
.LMCR_b111:
	ld xbc, (xsp + 0x26)                    ; ld XBC,(XSP+0x26)
	ld (xbc), wa                            ; ld (XBC),WA
	lda	xbc, (xde+1)
	ld	wa, (xsp+32)
	bit	0x07, wa
	jr z, .LMCR_b137                       ; [66 16] jr Z,0x29b137
	cp	(xde), 0x00
	jr nz, .LMCR_b12b                      ; [6e 05] jr NZ,0x29b12b
	cp	(xbc), 0x00
	jr z, .LMCR_b137                       ; [66 0c] jr Z,0x29b137
.LMCR_b12b:
	ld8_src_ri xbc, l		; ld L,(XBC)
	extz hl                                 ; extz HL
	ldw	wa, 0x0008
	ldw	bc, 0x4000
	jr t, .LMCR_b150                       ; [68 19] jr T,0x29b150
.LMCR_b137:
	cp	(xde), 0x00
	jr nz, .LMCR_b141                      ; [6e 05] jr NZ,0x29b141
	cp	(xbc), 0x00
	jr z, .LMCR_b164                       ; [66 23] jr Z,0x29b164
.LMCR_b141:
	ld8_src_ri xbc, l		; ld L,(XBC)
	and l, 0xf0		; and L,0xf0
	extz hl                                 ; extz HL
	sra	hl, 0x04
	lds	wa, 4
	ldw	bc, 0x0400
.LMCR_b150:
	ld	e, (xde)
	res	0x07, e
	extz de                                 ; extz DE
	and	a, 0x0f
	jr z, .LMCR_b15e                       ; [66 02] jr Z,0x29b15e
	slaa	de
.LMCR_b15e:
	ld	iz, de
	add	iz, hl
	sub	iz, bc
.LMCR_b164:
	pushw iz                                ; push IZ
	calr	0x0541
	inc 2, xsp                              ; inc 2,XSP
	ld (xsp + 0x04), hl
	cps	iz, 0
	jr ge, .LMCR_b174                      ; [69 03] jr GE,0x29b174
	decm	1, (xsp+4)
.LMCR_b174:
	ld	wa, (xsp+32)
	bit	0x07, wa
	jr z, .LMCR_b1a7                       ; [66 2b] jr Z,0x29b1a7
	ld	qiz, 2
.LMCR_b17f:
	lda	xwa, (xsp+10)
	ldb_sri a, 0x07, 0xE0, 0xFA	; ld A,(XWA+QIZ)
	and	a, 0xff
	ld	de, qiz
	add	de, de
	lda_24 xbc, 0x2394a6
	extz wa                                 ; extz WA
	stw_dri wa, 0x07, 0xE4, 0xE8	; ld (XBC+DE),WA
	inc	1, qiz
	cpw	qiz, 0x000a
	jr lt, .LMCR_b17f                      ; [61 da] jr LT,0x29b17f
	jr t, .LMCR_b1f9                       ; [68 52] jr T,0x29b1f9
.LMCR_b1a7:
	lds	ix, 0
	ld	qiz, 0
.LMCR_b1ac:
	lda	xbc, (xsp+10)
	cpib_sri 0x07, 0xE4, 0xFA, 0x00	; cp (XBC+QIZ),0x00
	jr z, .LMCR_b1bb                       ; [66 04] jr Z,0x29b1bb
	lds	ix, 1
	jr t, .LMCR_b1c5                       ; [68 0a] jr T,0x29b1c5
.LMCR_b1bb:
	inc	1, qiz
	cpw	qiz, 0x0008
	jr lt, .LMCR_b1ac                      ; [61 e7] jr LT,0x29b1ac
.LMCR_b1c5:
	and8_imm_rid8 xbc, 0x01, 0x0f		; and (XBC+0x01),0x0f
	ld	qiz, 1
.LMCR_b1cc:
	ldb_sri a, 0x07, 0xE4, 0xFA	; ld A,(XBC+QIZ)
	and	a, 0xff
	ld	hl, qiz
	add	hl, hl
	dec	2, hl
	lda_24 xde, 0x2394aa
	extz wa                                 ; extz WA
	stw_dri wa, 0x07, 0xE8, 0xEC	; ld (XDE+HL),WA
	inc	1, qiz
	cpw	qiz, 0x0008
	jr lt, .LMCR_b1cc                      ; [61 db] jr LT,0x29b1cc
	cps	ix, 0
	jr z, .LMCR_b1f9                       ; [66 04] jr Z,0x29b1f9
	or16_imm_ri xde, 0x10, 0x00		; or (XDE),0x0010
.LMCR_b1f9:
	pushm	(xsp+8)
	pushw 0x0023
	pushw 0x94aa
	calr	0x03e0
	inc	6, xsp
	ld	qiz, 0
	cps	iz, 0
	jr le, .LMCR_b262                      ; [62 54] jr LE,0x29b262
	cpw	(xsp+4), 0x0000
	jr le, .LMCR_b23a                      ; [62 25] jr LE,0x29b23a
.LMCR_b215:
	pushw 0x0023
	pushw 0x94aa
	calr	0x02f7
	pushm	(xsp+12)
	pushw 0x0023
	pushw 0x94aa
	calr	0x03bb
	lda	xsp, (xsp+10)
	sub	iz, hl
	inc	1, qiz
	ld	wa, qiz
	cp	wa, (xsp+4)
	jr lt, .LMCR_b215                      ; [61 db] jr LT,0x29b215
.LMCR_b23a:
	pushm	(xsp+6)
	lds	wa, 6
	sub	wa, iz
	pushw wa                                ; push WA
	pushw 0x0023
	pushw 0x94aa
	jr t, .LMCR_b27c                       ; [68 32] jr T,0x29b27c
.LMCR_b24a:
	push xbc
	calr	0x02f0
	pushm	(xsp+12)
	pushw 0x0023
	pushw 0x94aa
	calr	0x03fd
	lda	xsp, (xsp+10)
	add	iz, hl
	inc	1, qiz
.LMCR_b262:
	ld	de, (xsp+4)
	neg	de
	lda_24 xbc, 0x2394aa
	ld	wa, qiz
	cp	wa, de
	jr lt, .LMCR_b24a                      ; [61 d7] jr LT,0x29b24a
	pushm	(xsp+6)
	lds	wa, 6
	sub	wa, iz
	pushw wa                                ; push WA
	push xbc
.LMCR_b27c:
	calr	0x00e6
	inc 0, xsp                              ; inc 0,XSP
	ld	qiz, 1
.LMCR_b284:
	push	qiz
	ld	bc, qiz
	add	bc, bc
	lda_24 xwa, 0x2394aa
	push_sriw 0x07, 0xE0, 0xE4	; pushw (XWA+BC)
	calr	0x0195
	inc 4, xsp                              ; inc 4,XSP
	inc	1, qiz
	cpw	qiz, 0x0009
	jr lt, .LMCR_b284                      ; [61 df] jr LT,0x29b284
	lds	de, 0
	lda_24 xbc, 0x2394aa
	ld xhl, (xsp + 0x1c)                    ; ld XHL,(XSP+0x1c)
	ld	wa, (xbc)
	cp	wa, 0x0009
	jr ule, .LMCR_b2c4                     ; [63 0d] jr ULE,0x29b2c4
	lds	de, 1
	extz xwa
	div wa, 0x000a
	ld	(xhl), a
	incm	1, (xsp+4)
.LMCR_b2c4:
	ld	ix, de
	inc	1, de
	ld	wa, (xbc)
	extz xwa
	div wa, 0x000a
	ld	wa, qwa
	lda_dri xbc, 0x07, 0xEC, 0xF0	; ld (XHL+IX),A
	incm	1, (xsp+4)
	ld	qiz, 1
	jr t, .LMCR_b2f6                       ; [68 16] jr T,0x29b2f6
.LMCR_b2e0:
	ld	bc, de
	inc	1, de
	lda_24 xwa, 0x23948a
	ldb_sri a, 0x07, 0xE0, 0xFA	; ld A,(XWA+QIZ)
	lda_dri xbc, 0x07, 0xEC, 0xE4	; ld (XHL+BC),A
	inc	1, qiz
.LMCR_b2f6:
	ld	bc, (xsp+6)
	inc	2, bc
	ld	wa, qiz
	cp	wa, bc
	jr lt, .LMCR_b2e0                      ; [61 de] jr LT,0x29b2e0
	ld	de, (xsp+6)
	inc	1, de
	stb_dri a, 0x07, 0xEC, 0xE8	; lda XBC,XHL+DE
	cp	(xbc), 0x05
	jr c, .LMCR_b319                       ; [67 08] jr C,0x29b319
	ld	wa, (xsp+6)
	inc_srib 1, 0x07, 0xEC, 0xE0	; inc 1,(XHL+WA)
.LMCR_b319:
	ld	(xbc), 0x00
	ld	wa, (xsp+6)
	ld	qiz, wa
	jr t, .LMCR_b334                       ; [68 10] jr T,0x29b334
.LMCR_b324:
	ld	bc, qiz
	dec	1, bc
	inc_srib 1, 0x07, 0xEC, 0xE4	; inc 1,(XHL+BC)
	ld	(xwa), 0x00
	dec	1, qiz
.LMCR_b334:
	cp	qiz, 0
	jr z, .LMCR_b343                       ; [66 0a] jr Z,0x29b343
	stb_dri w, 0x07, 0xEC, 0xFA	; lda XWA,XHL+QIZ
	cp	(xwa), 0x09
	jr ugt, .LMCR_b324                     ; [6b e1] jr UGT,0x29b324
.LMCR_b343:
	ld	qiz, 0
	jr t, .LMCR_b351                       ; [68 09] jr T,0x29b351
.LMCR_b348:
	or_srib_im 0x07, 0xEC, 0xFA, 0x30	; or (XHL+QIZ),0x30
	inc	1, qiz
.LMCR_b351:
	ld	wa, qiz
	cp	wa, de
	jr lt, .LMCR_b348                      ; [61 f0] jr LT,0x29b348
	ld xbc, (xsp + 0x22)                    ; ld XBC,(XSP+0x22)
	ld	wa, (xsp+4)
	ld (xbc), wa                            ; ld (XBC),WA
	pop xiz                                 ; pop XIZ
	lda	xsp, (xsp+16)
	ret

	dec 0, xsp                              ; dec 0,XSP
	pushw iz                                ; push IZ
	lds	iz, 0
	lds	wa, 0
	ld	hl, (xsp+18)
	cps	hl, 0
	jr le, .LMCR_b37e                      ; [62 0b] jr LE,0x29b37e
.LMCR_b373:
	add	wa, wa
	set	0x00, wa
	inc	1, iz
	cp	iz, hl
	jr lt, .LMCR_b373                      ; [61 f5] jr LT,0x29b373
.LMCR_b37e:
	ld	iz, (xsp+20)
	dec	1, iz
	ld xiy, (xsp + 0x0e)                    ; ld XIY,(XSP+0x0e)
	cps	iz, 0
	jr le, .LMCR_b3d9                      ; [62 4f] jr LE,0x29b3d9
	ld (xsp + 0x04), wa                     ; ld (XSP+0x04),WA
	ldw (xsp + 0x02), 8
	sub	(xsp+2), hl
	ld	wa, iz
	exts xwa                                ; exts XWA
	add	xwa, xwa
	ld	xix, xwa
.LMCR_b39d:
	ld (xsp + 0x06), xix                    ; ld (XSP+0x06),XIX
	add	(xsp+6), xiy
	ld xbc, (xsp + 0x06)                    ; ld XBC,(XSP+0x06)
	ld	de, (xbc)
	ld	wa, hl
	and	a, 0x0f
	jr z, .LMCR_b3b1                       ; [66 02] jr Z,0x29b3b1
	srla	de
.LMCR_b3b1:
	ld (xbc), de                            ; ld (XBC),DE
	ld	xbc, xix
	lds32	xwa, 2
	sub	xbc, xwa
	add	xbc, xiy
	ld	wa, (xsp+4)
	and	wa, (xbc)
	ld	bc, wa
	ld	wa, (xsp+2)
	and	a, 0x0f
	jr z, .LMCR_b3cc                       ; [66 02] jr Z,0x29b3cc
	slla	bc
.LMCR_b3cc:
	ld xwa, (xsp + 0x06)                    ; ld XWA,(XSP+0x06)
	or	(xwa), bc
	dec	1, iz
	dec	2, xix
	cps	iz, 0
	jr gt, .LMCR_b39d                      ; [6a c4] jr GT,0x29b39d
.LMCR_b3d9:
	ld	bc, (xiy)
	ld	wa, hl
	and	a, 0x0f
	jr z, .LMCR_b3e4                       ; [66 02] jr Z,0x29b3e4
	srla	bc
.LMCR_b3e4:
	ld (xiy), bc                            ; ld (XIY),BC
	popw iz                                 ; pop IZ
	inc 0, xsp                              ; inc 0,XSP
	ret

	ld xiy, (xsp + 0x04)                    ; ld XIY,(XSP+0x04)
	and16_imm_ri xiy, 0xff, 0x00		; and (XIY),0x00ff
	lds	ix, 1
	ld	hl, (xsp+8)
	add	hl, hl
	jr t, .LMCR_b429                       ; [68 2f] jr T,0x29b429
.LMCR_b3fa:
	ld	de, ix
	exts xde                                ; exts XDE
	add	xde, xde
	add	xde, xiy
	ld	wa, (xsp+10)
	ld	bc, (xde)
	and	a, 0x0f
	jr z, .LMCR_b40e                       ; [66 02] jr Z,0x29b40e
	slla	bc
.LMCR_b40e:
	ld (xde), bc                            ; ld (XDE),BC
	ld	wa, ix
	dec	1, wa
	exts xwa                                ; exts XWA
	add	xwa, xwa
	ld	xbc, xwa
	add	xbc, xiy
	ld	wa, (xde)
	srl	wa, 0x08
	add	(xbc), wa
	and16_imm_ri xde, 0xff, 0x00		; and (XDE),0x00ff
	inc	1, ix
.LMCR_b429:
	cp	ix, hl
	jr lt, .LMCR_b3fa                      ; [61 cd] jr LT,0x29b3fa
	ret

	pushw iz                                ; push IZ
	lda_24 xde, 0x2394ea
	ld	xwa, xde
	lda	xbc, (xde+18)
.LMCR_b439:
	stiw_dsp 0xe1, 0x00, 0x00		; ld (XWA+),0x0000
	cp	xwa, xbc
	jr c, .LMCR_b439                       ; [67 f7] jr C,0x29b439
	ld	wa, (xsp+6)
	ld (xde + 0x10), wa                     ; ld (XDE+0x10),WA
	lds	iz, 0
.LMCR_b44a:
	lda_24 xwa, 0x2394ea
	cpw	(xwa), 0x0000
	jr nz, .LMCR_b494                      ; [6e 3f] jr NZ,0x29b494
	cpw	(xwa+2), 0x0000
	jr nz, .LMCR_b494                      ; [6e 38] jr NZ,0x29b494
	cpw	(xwa+4), 0x0000
	jr nz, .LMCR_b494                      ; [6e 31] jr NZ,0x29b494
	cpw	(xwa+6), 0x0000
	jr nz, .LMCR_b494                      ; [6e 2a] jr NZ,0x29b494
	cpw	(xwa+8), 0x0000
	jr nz, .LMCR_b494                      ; [6e 23] jr NZ,0x29b494
	cpw	(xwa+10), 0x0000
	jr nz, .LMCR_b494                      ; [6e 1c] jr NZ,0x29b494
	cpw	(xwa+12), 0x0000
	jr nz, .LMCR_b494                      ; [6e 15] jr NZ,0x29b494
	cpw	(xwa+14), 0x0000
	jr nz, .LMCR_b494                      ; [6e 0e] jr NZ,0x29b494
	cpw	(xwa+16), 0x0000
	jr nz, .LMCR_b494                      ; [6e 07] jr NZ,0x29b494
	jr t, .LMCR_b4cc                       ; [68 3d] jr T,0x29b4cc
.LMCR_b48f:
	inc	1, iz
	calr	0x010c
.LMCR_b494:
	ldw	wa, 0x0008
	sub	wa, (xsp+8)
	add	wa, wa
	lda_24 xbc, 0x2394ea
	ldw_sri wa, 0x07, 0xE4, 0xE0	; ld WA,(XBC+WA)
	cps	wa, 0
	jr z, .LMCR_b48f                       ; [66 e5] jr Z,0x29b48f
	pushw iz                                ; push IZ
	pushw wa                                ; push WA
	calr	0x001f
	inc 4, xsp                              ; inc 4,XSP
	ldw	bc, 0x0008
	sub	bc, (xsp+8)
	add	bc, bc
	lda_24 xwa, 0x2394ea
	stiw_ind 0x07, 0xE0, 0xE4, 0x00, 0x00	; ld (XWA+BC),0x0000
	cp	iz, 0x0020
	jrl le, .LMCR_b44a                     ; [72 7e ff] jrl LE,0x29b44a
.LMCR_b4cc:
	popw iz                                 ; pop IZ
	ret

	ld	de, (xsp+6)
	cp	de, 0x0020
	jr ge, .LMCR_b4e4                      ; [69 0d] jr GE,0x29b4e4
	lda_24 xbc, 0x23948a
	ld	wa, (xsp+4)
	add_srib_mr a, 0x07, 0xE4, 0xE8	; add (XBC+DE),A
.LMCR_b4e4:
	jr t, .LMCR_b4e8                       ; [68 02] jr T,0x29b4e8
.LMCR_b4e6:
	dec	1, de
.LMCR_b4e8:
	cp	de, 0x0020
	jr ge, .LMCR_b4e6                      ; [69 f8] jr GE,0x29b4e6
	lda_24 xwa, 0x23948a
	jr t, .LMCR_b508                       ; [68 13] jr T,0x29b508
.LMCR_b4f5:
	ld	bc, de
	dec	1, bc
	inc_srib 1, 0x07, 0xE0, 0xE4	; inc 1,(XWA+BC)
	ld	bc, de
	dec	1, de
	sub_srib_im 0x07, 0xE0, 0xE4, 0x0A	; sub (XWA+BC),0x0a
.LMCR_b508:
	cpib_sri 0x07, 0xE0, 0xE8, 0x0A	; cp (XWA+DE),0x0a
	ret lt                                  ; ret LT

	cps	de, 0
	jr gt, .LMCR_b4f5                      ; [6a e1] jr GT,0x29b4f5
	ret

	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld	xbc, xwa
	lda	xde, (xwa+18)
.LMCR_b51d:
	ld	wa, (xbc)
	extz xwa
	div wa, 0x000a
	ld	wa, qwa
	sll	wa, 0x08
	add	(xbc+2), wa
	ld	wa, (xbc)
	extz xwa
	div wa, 0x000a
	stw_dpi wa, 0xe5		; ld (XBC+),WA
	cp	xbc, xde
	jr c, .LMCR_b51d                       ; [67 e0] jr C,0x29b51d
	ret

	pushw iz                                ; push IZ
	lds	ix, 0
	lds32	xbc, 0
.LMCR_b543:
	ld xhl, (xsp + 0x06)                    ; ld XHL,(XSP+0x06)
	ld	xde, xbc
	add	xde, xhl
	ld	wa, (xde)
	mul	wa, 0x000a
	ld (xde), wa                            ; ld (XDE),WA
	cps	ix, 0
	jr z, .LMCR_b583                       ; [66 2d] jr Z,0x29b583
	ld	iz, ix
	jr t, .LMCR_b56f                       ; [68 15] jr T,0x29b56f
.LMCR_b55a:
	ld	iy, iz
	dec	1, iy
	exts xiy                                ; exts XIY
	add	xiy, xiy
	add	xiy, xhl
	srl	wa, 0x08
	add	(xiy), wa
	and16_imm_ri xde, 0xff, 0x00		; and (XDE),0x00ff
	dec	1, iz
.LMCR_b56f:
	cps	iz, 0
	jr le, .LMCR_b583                      ; [62 10] jr LE,0x29b583
	ld	de, iz
	exts xde                                ; exts XDE
	add	xde, xde
	add	xde, xhl
	ld	wa, (xde)
	cp	wa, 0x00ff
	jr ugt, .LMCR_b55a                     ; [6b d7] jr UGT,0x29b55a
.LMCR_b583:
	inc	1, ix
	inc 2, xbc                              ; inc 2,XBC
	cp	ix, 0x0010
	jr lt, .LMCR_b543                      ; [61 b6] jr LT,0x29b543
	lda	xbc, (xhl+30)
	ld	wa, (xbc)
	bit	0x07, wa
	jr z, .LMCR_b59a                       ; [66 03] jr Z,0x29b59a
	incm	1, (xhl+28)
.LMCR_b59a:
	ldw	(xbc), 0x0000
	popw iz                                 ; pop IZ
	ret

	lda_24 xhl, 0x2394ea
	ld	xbc, xhl
	lda	xde, (xhl+20)
.LMCR_b5aa:
	cpw	(xbc), 0x0000
	jr z, .LMCR_b5b8                       ; [66 08] jr Z,0x29b5b8
	ld	wa, (xbc)
	mul	wa, 0x000a
	ld (xbc), wa                            ; ld (XBC),WA
.LMCR_b5b8:
	inc 2, xbc                              ; inc 2,XBC
	cp	xbc, xde
	jr c, .LMCR_b5aa                       ; [67 ec] jr C,0x29b5aa
	lda	xbc, (xhl+18)
	ldw	de, 0x0012
.LMCR_b5c4:
	ld	wa, (xbc)
	cp	wa, 0x0100
	jr c, .LMCR_b5dc                       ; [67 10] jr C,0x29b5dc
	ld	ix, de
	dec	2, ix
	srl	wa, 0x08
	add_sriw_mr wa, 0x07, 0xEC, 0xF0	; add (XHL+IX),WA
	and16_imm_ri xbc, 0xff, 0x00		; and (XBC),0x00ff
.LMCR_b5dc:
	dec	2, de
	dec	2, xbc
	cps	de, 0
	jr gt, .LMCR_b5c4                      ; [6a e0] jr GT,0x29b5c4
	ret

	dec	2, xsp
	pushw iz                                ; push IZ
	lds	iz, 0
	cpw	(xsp+12), 0x0000
	jr le, .LMCR_b607                      ; [62 16] jr LE,0x29b607
.LMCR_b5f1:
	ld	wa, iz
	exts xwa                                ; exts XWA
	add	xwa, xwa
	add	xwa, (xsp+8)
	cpw	(xwa), 0x0000
	jr nz, .LMCR_b607                      ; [6e 07] jr NZ,0x29b607
	inc	1, iz
	cp	iz, (xsp+12)
	jr lt, .LMCR_b5f1                      ; [61 ea] jr LT,0x29b5f1
.LMCR_b607:
	cp	iz, (xsp+12)
	jr nz, .LMCR_b610                      ; [6e 04] jr NZ,0x29b610
	lds	hl, 0
	jr t, .LMCR_b653                       ; [68 43] jr T,0x29b653
.LMCR_b610:
	ldw (xsp + 0x02), 0
	jr t, .LMCR_b646                       ; [68 2f] jr T,0x29b646
.LMCR_b617:
	lds	iz, 0
	ld xbc, (xsp + 0x08)                    ; ld XBC,(XSP+0x08)
	jr t, .LMCR_b625                       ; [68 07] jr T,0x29b625
.LMCR_b61e:
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	sllw_ri xwa		; sllw (XWA)
	inc	1, iz
.LMCR_b625:
	ld	wa, (xbc)
	bit	0x07, wa
	jr nz, .LMCR_b632                      ; [6e 06] jr NZ,0x29b632
	cp	iz, 0x0008
	jr lt, .LMCR_b61e                      ; [61 ec] jr LT,0x29b61e
.LMCR_b632:
	cps	iz, 0
	jr z, .LMCR_b643                       ; [66 0d] jr Z,0x29b643
	pushw iz                                ; push IZ
	pushm	(xsp+14)
	ld xwa, (xsp + 0x0c)                    ; ld XWA,(XSP+0x0c)
	push xwa
	calr	0xfda9
	inc 0, xsp                              ; inc 0,XSP
.LMCR_b643:
	add	(xsp+2), iz
.LMCR_b646:
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	ld	wa, (xwa)
	bit	0x07, wa
	jr z, .LMCR_b617                       ; [66 c7] jr Z,0x29b617
	ld	hl, (xsp+2)
.LMCR_b653:
	popw iz                                 ; pop IZ
	inc 2, xsp                              ; inc 2,XSP
	ret

	pushw iz                                ; push IZ
	ld xde, (xsp + 0x06)                    ; ld XDE,(XSP+0x06)
	lds	iz, 0
	ld	bc, (xsp+10)
	cps	bc, 0
	jr le, .LMCR_b678                      ; [62 14] jr LE,0x29b678
.LMCR_b664:
	ld	wa, iz
	exts xwa                                ; exts XWA
	add	xwa, xwa
	add	xwa, xde
	cpw	(xwa), 0x0000
	jr nz, .LMCR_b678                      ; [6e 06] jr NZ,0x29b678
	inc	1, iz
	cp	iz, bc
	jr lt, .LMCR_b664                      ; [61 ec] jr LT,0x29b664
.LMCR_b678:
	cp	iz, bc
	jr nz, .LMCR_b680                      ; [6e 04] jr NZ,0x29b680
	lds	hl, 0
	jr t, .LMCR_b6a7                       ; [68 27] jr T,0x29b6a7
.LMCR_b680:
	ld	hl, (xde)
	lds	iz, 0
	jr t, .LMCR_b68b                       ; [68 05] jr T,0x29b68b
.LMCR_b686:
	srl	hl, 0x01
	inc	1, iz
.LMCR_b68b:
	ld	wa, hl
	and	wa, 0xff00
	jr z, .LMCR_b699                       ; [66 06] jr Z,0x29b699
	cp	iz, 0x0008
	jr lt, .LMCR_b686                      ; [61 ed] jr LT,0x29b686
.LMCR_b699:
	cps	iz, 0
	jr z, .LMCR_b6a5                       ; [66 08] jr Z,0x29b6a5
	pushw bc                                ; push BC
	pushw iz                                ; push IZ
	push xde
	calr	0xfcc2
	inc 0, xsp                              ; inc 0,XSP
.LMCR_b6a5:
	ld	hl, iz
.LMCR_b6a7:
	popw iz                                 ; pop IZ
	ret

	dec 0, xsp                              ; dec 0,XSP
	push xiz
	ld	wa, (xsp+16)
	exts xwa                                ; exts XWA
	lda_d16	xbc, 301
	call HDAE5000_Multiply
	ld	xiz, xhl
	cp	xiz, 0x00000000
	jr ge, .LMCR_b6d1                      ; [69 0e] jr GE,0x29b6d1
	ld	xwa, xiz
	cpl	wa
	cpl	qwa
	inc 1, xwa                              ; inc 1,XWA
	ld (xsp + 0x04), xwa                    ; ld (XSP+0x04),XWA
	jr t, .LMCR_b6d4                       ; [68 03] jr T,0x29b6d4
.LMCR_b6d1:
	ld (xsp + 0x04), xiz                    ; ld (XSP+0x04),XIZ
.LMCR_b6d4:
	ld xiz, (xsp + 0x04)                    ; ld XIZ,(XSP+0x04)
	ld	xwa, xiz
	lda_d16	xbc, 1000
	call 0x29b8b7
	ld (xsp + 0x08), xhl                    ; ld (XSP+0x08),XHL
	ld	xwa, xiz
	lda_d16	xbc, 1000
	call 0x29b8bb
	ld	xiz, xhl
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	cp	xwa, 0x000003d4
	jr le, .LMCR_b6ff                      ; [62 04] jr LE,0x29b6ff
	inc 1, xiz                              ; inc 1,XIZ
	jr t, .LMCR_b713                       ; [68 14] jr T,0x29b713
.LMCR_b6ff:
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	or xwa, xwa                             ; or XWA,XWA
	jr z, .LMCR_b713                       ; [66 0d] jr Z,0x29b713
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	cp	xwa, 0x00000014
	jr ge, .LMCR_b713                      ; [69 02] jr GE,0x29b713
	dec	1, xiz
.LMCR_b713:
	cpw	(xsp+16), 0x0000
	jr ge, .LMCR_b727                      ; [69 0d] jr GE,0x29b727
	ld	xwa, xiz
	cpl	wa
	cpl	qwa
	inc 1, xwa                              ; inc 1,XWA
	ld	xhl, xwa
	jr t, .LMCR_b729                       ; [68 02] jr T,0x29b729
.LMCR_b727:
	ld	xhl, xiz
.LMCR_b729:
	pop xiz                                 ; pop XIZ
	inc 0, xsp                              ; inc 0,XSP
	ret


HDAE5000_Multiply:	; 0x29B72D
	; 32-bit multiply routine
; LMUL: 0x29B72D (402 bytes)

	ld	hl, qwa
	mul	xhl, xbc
	ld	de, qbc
	mul	xde, xwa
	add	xhl, xde
	ld	qhl, hl
	lds	hl, 0
	mul	xwa, xbc
	add	xhl, xwa
	ret

	nop                                     ; nop
	lds32	xhl, 0
	ld xix, (xbc)                           ; ld XIX,(XBC)
	ld	de, qix
	ldcf16ri 15, de		; ldcf 0x0f,DE
	stcf	0x0f, qhl
	ld	hl, de
	sll	hl, 0x01
	ldb	l, 0x00
	ex8 h, l		; ex H,L
	cps	hl, 0
	jr z, .LMUL_b776                       ; [66 17] jr Z,0x29b776
	and	de, 0x007f
	set	0x07, de
	ld	qix, de
	sub	hl, 0x007f
.LMUL_b76d:
	ld (xwa), xhl                           ; ld (XWA),XHL
	ld (xwa + 0x04), xix                    ; ld (XWA+0x04),XIX
	stb_erp l, 0xee		; ld L,QL
	ret

.LMUL_b776:
	lds32	xix, 0
	ldib_erp 0xee, 1		; ld QL,1
	jr t, .LMUL_b76d                       ; [68 f0] jr T,0x29b76d
	nop                                     ; nop
	ld xhl, (xbc)                           ; ld XHL,(XBC)
	cpib_erp 0xee, 0		; cp QL,0
	jr nz, .LMUL_b7ac                      ; [6e 27] jr NZ,0x29b7ac
	ld xde, (xbc + 0x04)                    ; ld XDE,(XBC+0x04)
	cp	hl, 0x007f
	jr gt, .LMUL_b7bd                      ; [6a 2f] jr GT,0x29b7bd
	cp	hl, 0xff82
	jr lt, .LMUL_b7b8                      ; [61 24] jr LT,0x29b7b8
	add	hl, 0x007f
	ld	bc, qde
	res	0x07, bc
	sll	hl, 0x07
	orb_erp h, 0xef		; or H,QH
	or	hl, bc
	ld	qde, hl
	ld (xwa), xde                           ; ld (XWA),XDE
	ret

.LMUL_b7ac:
	stb_erp e, 0xee		; ld E,QL
	cp	e, 0x08
	jr nz, .LMUL_b7b8                      ; [6e 04] jr NZ,0x29b7b8
	lds32	xde, 0
	jr t, .LMUL_b7c9                       ; [68 11] jr T,0x29b7c9
.LMUL_b7b8:
	lds32	xde, 0
	ld (xwa), xde                           ; ld (XWA),XDE
	ret

.LMUL_b7bd:
	ldw	de, 0xffff
	ldw	bc, 0x7f7f
	orb_erp b, 0xef		; or B,QH
	ld	qde, bc
.LMUL_b7c9:
	stiw_da	0x230ECA, 34
	ld (xwa), xde                           ; ld (XWA),XDE
	ld	xbc, (0x23a1a8)
	or xbc, xbc                             ; or XBC,XBC
	call_cc_ri xbc, 14		; call NZ,XBC
	ret

	ld xix, (xbc)                           ; ld XIX,(XBC)
	ld xiy, (xbc + 0x04)                    ; ld XIY,(XBC+0x04)
	ld (xwa), xix                           ; ld (XWA),XIX
	ld (xwa + 0x04), xiy                    ; ld (XWA+0x04),XIY
	ret

	nop                                     ; nop
	ld xix, (xbc)                           ; ld XIX,(XBC)
	ld xiy, (xbc + 0x04)                    ; ld XIY,(XBC+0x04)
	ld	hl, (xbc+8)
	ld (xwa), xix                           ; ld (XWA),XIX
	ld (xwa + 0x04), xiy                    ; ld (XWA+0x04),XIY
	ld (xwa + 0x08), hl                     ; ld (XWA+0x08),HL
	ret

	nop                                     ; nop
	push xiz
	lda	xsp, (xsp-8)
	ld	xiz, xwa
	ld	xwa, xsp
	ld xbc, (xbc)                           ; ld XBC,(XBC)
	call 0x29b9ac
	ld	xwa, xiz
	ld	xbc, xsp
	call 0x29b77e
	lda	xsp, (xsp+8)
	pop xiz                                 ; pop XIZ
	ret

	push xiz
	lda	xsp, (xsp-8)
	ld	xiz, xwa
	ld	xwa, xsp
	ld xbc, (xbc)                           ; ld XBC,(XBC)
	call 0x29b9c5
	ld	xwa, xiz
	ld	xbc, xsp
	call 0x29b77e
	lda	xsp, (xsp+8)
	pop xiz                                 ; pop XIZ
	ret

	ld	h, (xwa+2)
	ld8_src_rid8 xbc, 0x02, l		; ld L,(XBC+0x02)
	bit 0x00, l		; bit 0x00,L
	ret z                                   ; ret Z

	ld	(xwa+2), 0x08
	ret

	push xiz
	lda	xsp, (xsp-20)
	ld	xiz, xde
	ld (xsp + 0x10), xwa                    ; ld (XSP+0x10),XWA
	ld	xwa, xsp
	call 0x29b744
	ld	xbc, xiz
	lda	xiz, (xsp+8)
	lda	xwa, (xiz)
	call 0x29b744
	ld	xwa, xsp
	lda	xbc, (xiz)
	call 0x29ba64
	ld xwa, (xsp + 0x10)                    ; ld XWA,(XSP+0x10)
	ld	xbc, xsp
	call 0x29b77e
	lda	xsp, (xsp+20)
	pop xiz                                 ; pop XIZ
	ret

.LMUL_b870:
	ldb	e, 0x00
	bit	0x0f, qwa
	jr z, .LMUL_b881                       ; [66 09] jr Z,0x29b881
	ldb	e, 0x01
	cpl	qwa
	cpl	wa
	inc 1, xwa                              ; inc 1,XWA
.LMUL_b881:
	bit	0x0f, qbc
	jr z, .LMUL_b891                       ; [66 0a] jr Z,0x29b891
	or	e, 0x02
	cpl	qbc
	cpl	bc
	inc 1, xbc                              ; inc 1,XBC
.LMUL_b891:
	pushw de                                ; push DE
	calr	0x0030
	popw wa                                 ; pop WA
	cps	w, 1
	jr z, .LMUL_b8a3                       ; [66 09] jr Z,0x29b8a3
	ld	xhl, xde
	bit	0x00, a
	scc8	nz, a
	jr t, .LMUL_b8a7                       ; [68 04] jr T,0x29b8a7
.LMUL_b8a3:
	cps	a, 3
	ret z                                   ; ret Z

.LMUL_b8a7:
	or xhl, xhl                             ; or XHL,XHL
	ret z                                   ; ret Z

	cps	a, 0
	ret z                                   ; ret Z

	cpl	qhl
	cpl	hl
	inc 1, xhl                              ; inc 1,XHL
	ret

	ldb	d, 0x00
	jr t, .LMUL_b870                       ; [68 b5] jr T,0x29b870
	ldb	d, 0x01
	jr t, .LMUL_b870                       ; [68 b1] jr T,0x29b870


HDAE5000_Divide_Unsigned:	; 0x29B8BF (6 bytes)
	; Unsigned 32÷32 divide - calls signed divide then copies result
	calr HDAE5000_Divide_Signed
	ld xhl, xde		; copy quotient from XDE to XHL
	ret

HDAE5000_Divide_Signed:	; 0x29B8C5
	; Signed 32÷32 divide (used by decimal string conversion)
; LDIV: 0x29B8C5 (1819 bytes)

	cp	xbc, 0x00000001
	jr z, .LDIV_b8fe                       ; [66 31] jr Z,0x29b8fe
	jr c, .LDIV_b903                       ; [67 34] jr C,0x29b903
	cp	xwa, xbc
	jr ule, .LDIV_b90a                     ; [63 37] jr ULE,0x29b90a
	cp	qbc, 0
	jr nz, .LDIV_b915                      ; [6e 3d] jr NZ,0x29b915
	ld	xde, xwa
	div	xwa, xbc
	jr	ov, 0x0a
	lds32	xhl, 0
	ld	xde, xhl
	ld	hl, wa
	ld	de, qwa
	ret

.LDIV_b8e8:
	ld	wa, qde
	extz xwa
	div	xwa, xbc
	ld	qhl, wa
	ld	wa, de
	div	xwa, xbc
	ld	hl, wa
	ld	de, qwa
	extz xde                                ; extz XDE
	ret

.LDIV_b8fe:
	ld	xhl, xwa
	lds32	xde, 0
	ret

.LDIV_b903:
	lds32	xhl, 0
	ld	xde, xhl
	dec	1, xhl
	ret

.LDIV_b90a:
	lds32	xhl, 1
	lds32	xde, 0
	ret z                                   ; ret Z

	dec	1, xhl
	ld	xde, xwa
	ret

.LDIV_b915:
	ldb	d, 0x00
.LDIV_b917:
	cp	xwa, xbc
	jr c, .LDIV_b929                       ; [67 0e] jr C,0x29b929
	inc	1, d
	add	xbc, xbc
	jr nc, .LDIV_b917                      ; [6f f6] jr NC,0x29b917
	stcf16ri 0, bc		; stcf 0x00,BC
	rrc	xbc
	jr t, .LDIV_b92c                       ; [68 03] jr T,0x29b92c
.LDIV_b929:
	srl	xbc, 0x01
.LDIV_b92c:
	lds32	xhl, 0
	add	xhl, xhl
	cp	xwa, xbc
	jr c, .LDIV_b939                       ; [67 05] jr C,0x29b939
	set 0x00, l		; set 0x00,L
	sub	xwa, xbc
.LDIV_b939:
	srl	xbc, 0x01
	djnz8	d, -17				; loop back for next division bit
	ld	xde, xwa
	ret

	ld xhl, (xbc)                           ; ld XHL,(XBC)
	cpib_erp 0xee, 0		; cp QL,0
	jr nz, .LDIV_b97b                      ; [6e 32] jr NZ,0x29b97b
	ld xix, (xbc + 0x08)                    ; ld XIX,(XBC+0x08)
	ld xiy, (xbc + 0x04)                    ; ld XIY,(XBC+0x04)
	cp	hl, 0x03ff
	jr gt, .LDIV_b981                      ; [6a 2c] jr GT,0x29b981
	cp	hl, 0xfc02
	jr lt, .LDIV_b975                      ; [61 1a] jr LT,0x29b975
	add	hl, 0x03ff
	res	0x04, qix
	sll	hl, 0x04
	orb_erp h, 0xef		; or H,QH
	or	hl, qix
	ld	qix, hl
.LDIV_b96f:
	ld (xwa), xiy                           ; ld (XWA),XIY
	ld (xwa + 0x04), xix                    ; ld (XWA+0x04),XIX
	ret

.LDIV_b975:
	lds32	xix, 0
	ld	xiy, xix
	jr t, .LDIV_b96f                       ; [68 f4] jr T,0x29b96f
.LDIV_b97b:
	bit_erpb 0xee, 0x00		; bit 0x00,QL
	jr nz, .LDIV_b975                      ; [6e f4] jr NZ,0x29b975
.LDIV_b981:
	stiw_da	0x230ECA, 34
	lds32	xde, 0
	dec	1, xde
	ld (xwa), xde                           ; ld (XWA),XDE
	ld	xde, 0x7fefffff
	stb_erp c, 0xef		; ld C,QH
	orb_erp c, 0xeb		; or C,QD
	ldb_erp c, 0xeb		; ld QD,C
	ld (xwa + 0x04), xde                    ; ld (XWA+0x04),XDE
	jr t, .LDIV_b9a1                       ; [68 00] jr T,0x29b9a1
.LDIV_b9a1:
	ld	xbc, (0x23a1a8)
	or xbc, xbc                             ; or XBC,XBC
	call_cc_ri xbc, 14		; call NZ,XBC
	ret

	nop                                     ; nop
	ldb	e, 0x00
	ldcf	0x0f, qbc
	stcf8ri 7, e		; stcf 0x07,E
	jr nc, .LDIV_b9be                      ; [6f 07] jr NC,0x29b9be
	cpl	qbc
	cpl	bc
	inc 1, xbc                              ; inc 1,XBC
.LDIV_b9be:
	calr	0x0004
	ld	(xiy+3), e
	ret

	ld	xiy, xwa
	or xbc, xbc                             ; or XBC,XBC
	jr z, .LDIV_ba1a                       ; [66 4f] jr Z,0x29ba1a
	bs1b	qbc
	jr	ov, 0x05
	add	a, 0x10
	jr t, .LDIV_b9d7                       ; [68 02] jr T,0x29b9d7
.LDIV_b9d5:
	bs1b16 bc		; bs1b A,BC
.LDIV_b9d7:
	lds	hl, 0
	ld (xiy + 0x02), hl                     ; ld (XIY+0x02),HL
	ld l, a		; ld L,A
	ld_dst16_rid8 xiy, 0x00, hl		; ld (XIY+0x00),HL
	cp l, 0x17		; cp L,0x17
	jr z, .LDIV_ba16                       ; [66 30] jr Z,0x29ba16
	jr lt, .LDIV_ba01                      ; [61 19] jr LT,0x29ba01
	sub l, 0x17		; sub L,0x17
	ld a, l		; ld A,L
	srla	xbc
	jr nc, .LDIV_ba16                      ; [6f 25] jr NC,0x29ba16
	inc 1, xbc                              ; inc 1,XBC
	bit_erpb 0xe7, 0x00		; bit 0x00,QB
	jr z, .LDIV_ba16                       ; [66 1d] jr Z,0x29ba16
	srl	xbc, 0x01
	inc1_8_rid8 xiy, 0x00		; inc 1,(XIY+0x00)
	jr t, .LDIV_ba16                       ; [68 15] jr T,0x29ba16
.LDIV_ba01:
	ldb	a, 0x17
	sub a, l		; sub A,L
	cp	a, 0x10
	jr lt, .LDIV_ba14                      ; [61 0a] jr LT,0x29ba14
	ld	qbc, bc
	lds	bc, 0
	sub	a, 0x10
	jr z, .LDIV_ba16                       ; [66 02] jr Z,0x29ba16
.LDIV_ba14:
	slla	xbc
.LDIV_ba16:
	ld (xiy + 0x04), xbc                    ; ld (XIY+0x04),XBC
	ret

.LDIV_ba1a:
	ld	(xiy+2), 0x01
	ret

	nop                                     ; nop
	push xiz
	lda	xsp, (xsp-12)
	ld	xiz, xwa
	ld	xwa, xsp
	call 0x29b744
	cps	l, 0
	jr nz, .LDIV_ba56                      ; [6e 26] jr NZ,0x29ba56
	ld xhl, (xsp + 0x04)                    ; ld XHL,(XSP+0x04)
	lds32	xde, 0
	srl	xhl, 0x01
	stcf16ri 0, de		; stcf 0x00,DE
	rrc	xde
	srl	xhl, 0x01
	stcf16ri 0, de		; stcf 0x00,DE
	rrc	xde
	srl	xhl, 0x01
	stcf16ri 0, de		; stcf 0x00,DE
	rrc	xde
	ld (xsp + 0x08), xhl                    ; ld (XSP+0x08),XHL
	ld (xsp + 0x04), xde                    ; ld (XSP+0x04),XDE
.LDIV_ba56:
	ld	xwa, xiz
	ld	xbc, xsp
	call 0x29b942
	lda	xsp, (xsp+12)
	pop xiz                                 ; pop XIZ
	ret

	nop                                     ; nop
	ld	e, (xwa+2)
	or	e, (xwa+2)
	jp_24	nz, 0x29B830
	push xiz
	push xwa
	ld16_src_rid8 xbc, 0x00, hl		; ld HL,(XBC+0x00)
	sub16_mem_rid8 xwa, 0x00, hl		; sub (XWA+0x00),HL
	ld8_src_rid8 xbc, 0x03, l		; ld L,(XBC+0x03)
	xor8_mem_rid8 xwa, 0x03, l		; xor (XWA+0x03),L
	ld xwa, (xwa + 0x04)                    ; ld XWA,(XWA+0x04)
	ld xbc, (xbc + 0x04)                    ; ld XBC,(XBC+0x04)
	cp	xbc, 0x00800000
	jr z, .LDIV_baf7                       ; [66 6c] jr Z,0x29baf7
	lds32	xhl, 0
	ld	xix, xbc
	add	xix, xix
	ld	xiy, xix
	add	xiy, xiy
	ld	xiz, xiy
	add	xiz, xiz
	ldw	de, 0x0008
	sll	xwa, 0x03
.LDIV_ba9f:
	cp	xwa, xiz
	jr c, .LDIV_baa8                       ; [67 05] jr C,0x29baa8
	sub	xwa, xiz
	set 0x03, l		; set 0x03,L
.LDIV_baa8:
	cp	xwa, xiy
	jr c, .LDIV_bab1                       ; [67 05] jr C,0x29bab1
	sub	xwa, xiy
	set 0x02, l		; set 0x02,L
.LDIV_bab1:
	cp	xwa, xix
	jr c, .LDIV_baba                       ; [67 05] jr C,0x29baba
	sub	xwa, xix
	set 0x01, l		; set 0x01,L
.LDIV_baba:
	cp	xwa, xbc
	jr c, .LDIV_bac3                       ; [67 05] jr C,0x29bac3
	sub	xwa, xbc
	set 0x00, l		; set 0x00,L
.LDIV_bac3:
	dec	1, e
	jr z, .LDIV_bacf                       ; [66 08] jr Z,0x29bacf
	sll	xhl, 0x04
	sll	xwa, 0x04
	jr t, .LDIV_ba9f                       ; [68 d0] jr T,0x29ba9f
.LDIV_bacf:
	pop xwa                                 ; pop XWA
	bit	0x0f, qhl
	jr nz, .LDIV_badc                      ; [6e 06] jr NZ,0x29badc
	sll	xhl, 0x01
	dec1_16_rid8 xwa, 0x00		; decw 1,(XWA+0x00)
.LDIV_badc:
	cp l, 0x80		; cp L,0x80
	jr c, .LDIV_baef                       ; [67 0e] jr C,0x29baef
	add	xhl, 0x00000100
	jr nc, .LDIV_baef                      ; [6f 06] jr NC,0x29baef
	stcf16ri 0, hl		; stcf 0x00,HL
	rrc	xhl
.LDIV_baef:
	srl	xhl, 0x08
.LDIV_baf2:
	ld (xwa + 0x04), xhl                    ; ld (XWA+0x04),XHL
	pop xiz                                 ; pop XIZ
	ret

.LDIV_baf7:
	ld	xhl, xwa
	pop xwa                                 ; pop XWA
	jr t, .LDIV_baf2                       ; [68 f6] jr T,0x29baf2
	nop                                     ; nop
	nop                                     ; nop
	popw ix                                 ; pop IX
	jrl	ge, 0x6972
	jr	ule, 0x42
	jr	lt, 0x63
	jr ugt, .LDIV_bb4b                     ; [6b 43] jr UGT,0x29bb4b
	jr	nc, 0x6c
	jr	nc, 0x72
	ld	xhl, 0x6b636568
	nop                                     ; nop
	popw ix                                 ; pop IX
	jrl	ge, 0x6972
	jr	ule, 0x46
	jr	nc, 0x72
	jr	mi, 0x43
	jr	nc, 0x6c
	jr	nc, 0x72
	ld	xhl, 0x6b636568
	nop                                     ; nop
	popw ix                                 ; pop IX
	jrl	ge, 0x6972
	jr	ule, 0x4a
	jrl	mi, 0x706d
	ld	xiy, 0x43746964
	jr t, .LDIV_bb9b                       ; [68 65] jr T,0x29bb9b
	jr	ule, 0x6b
	nop                                     ; nop
	nop                                     ; nop
	ld	xde, 0x616d7469
	jrl	f, 0x7542
	jrl	ov, 0x3074
	ldw	bc, 0x0000
	popw ix                                 ; pop IX
	jr lt, .LDIV_bbb9                      ; [61 6e] jr LT,0x29bbb9
.LDIV_bb4b:
	jr	c, 0x75
	jr lt, .LDIV_bbb6                      ; [61 67] jr LT,0x29bbb6
	jr	mi, 0x54
	jr	mi, 0x78
	jrl	ov, 0x6552
	jrl	ov, 0x7275
	jr nz, .LDIV_bb5b                      ; [6e 00] jr NZ,0x29bb5b
.LDIV_bb5b:
	nop                                     ; nop
	ld	xiy, 0x734d7272
	jr	c, 0x54
	jr	ge, 0x6d
	jr	mi, 0x72
	ld	xhl, 0x68637461
	popw ix                                 ; pop IX
	ld	xde, 0x7245004e
	jrl	le, 0x734d
	jr c, .LDIV_bbcb                       ; [67 54] jr C,0x29bbcb
	jr	ge, 0x6d
	jr	mi, 0x72
	ld	xhl, 0x68637461
	nop                                     ; nop
	nop                                     ; nop
	.byte 0x53                             ; db
	jr	mi, 0x70
	jr	lt, 0x72
	jr	lt, 0x74
	jr	mi, 0x42
	jr lt, .LDIV_bc00                      ; [61 73] jr LT,0x29bc00
	jrl	ule, 0x6150
	jrl	le, 0x4374
	jr	t, 0x65
	jr	ule, 0x6b
	nop                                     ; nop
	.byte 0x53                             ; db
	jr	mi, 0x70
.LDIV_bb9b:
	jr lt, .LDIV_bc0f                      ; [61 72] jr LT,0x29bc0f
	jr	lt, 0x74
	jr	mi, 0x44
	jrl	le, 0x6d75
	.byte 0x50                             ; db
.LDIV_bba5:
	jr	lt, 0x72
	jrl	ov, 0x6843
	jr	mi, 0x63
	jr ugt, .LDIV_bbae                     ; [6b 00] jr UGT,0x29bbae
.LDIV_bbae:
	ld	xiz, 0x764f736c
	jr	mi, 0x72
	.byte 0x57                             ; db
.LDIV_bbb6:
	jrl	le, 0x7753
.LDIV_bbb9:
	ld	xhl, 0x68637461
	nop                                     ; nop
	nop                                     ; nop
	ld	xiz, 0x6544736c
	jr	nov, 0x32
	.byte 0x53                             ; db
	jrl	c, 0x6143
.LDIV_bbcb:
	jrl	ov, 0x6863
	nop                                     ; nop
	nop                                     ; nop
	ld	xiz, 0x6544736c
	jr	nov, 0x31
	.byte 0x53                             ; db
	jrl	c, 0x6143
	jrl	ov, 0x6863
	nop                                     ; nop
	nop                                     ; nop
	ld	xbc, 0x6e657474
.LDIV_bbe5:
	ld	xhl, 0x4d6f5470
	jr	lt, 0x72
	jr ugt, .LDIV_bc41                     ; [6b 53] jr UGT,0x29bc41
	jrl	c, 0x6143
	jrl	ov, 0x6863
	nop                                     ; nop
.LDIV_bbf5:
	nop                                     ; nop
	ld	xbc, 0x6e657474
	ld	xhl, 0x486f5470
.LDIV_bc00:
	ld	xix, 0x61437753
	jrl	ov, 0x6863
.LDIV_bc08:
	nop                                     ; nop
	nop                                     ; nop
	ld	xbc, 0x6e657474
.LDIV_bc0f:
	popw wa                                 ; pop WA
	ld	xix, 0x6d726f46
	jr lt, .LDIV_bc8b                      ; [61 74] jr LT,0x29bc8b
	.byte 0x53                             ; db
	jrl	c, 0x6143
	jrl	ov, 0x6863
	nop                                     ; nop
	nop                                     ; nop
	ld	xbc, 0x6e657474
	ld	xix, 0x69466c65
	jr	nov, 0x65
	.byte 0x53                             ; db
	jrl	c, 0x6143
	jrl	ov, 0x6863
	nop                                     ; nop
	ld	xbc, 0x6e657474
	ld	xix, 0x69446c65
	jrl	le, 0x7753
.LDIV_bc41:
	ld	xhl, 0x68637461
	nop                                     ; nop
	nop                                     ; nop
	ld	xiz, 0x6946736c
	jr	nov, 0x65
	popw ix                                 ; pop IX
	jr nc, .LDIV_bcb3                      ; [6f 61] jr NC,0x29bcb3
	jr	ov, 0x53
	jrl	c, 0x6143
	jrl	ov, 0x6863
	nop                                     ; nop
	nop                                     ; nop
	popw ix                                 ; pop IX
	ld	xde, 0x42644d4e
	jr ge, .LDIV_bcd8                      ; [69 74] jr GE,0x29bcd8
	ld	xhl, 0x6b636568
	nop                                     ; nop
	popw ix                                 ; pop IX
	ld	xde, 0x6d63524e
	ld	xde, 0x68437469
	jr	mi, 0x63
	jr ugt, .LDIV_bc79                     ; [6b 00] jr UGT,0x29bc79
.LDIV_bc79:
	nop                                     ; nop
	popw ix                                 ; pop IX
	ld	xde, 0x70734d4e
	ld	xde, 0x68437469
	jr	mi, 0x63
	jr ugt, .LDIV_bc89                     ; [6b 00] jr UGT,0x29bc89
.LDIV_bc89:
	nop                                     ; nop
	popw ix                                 ; pop IX
.LDIV_bc8b:
	ld	xde, 0x426d544e
	jr ge, .LDIV_bd06                      ; [69 74] jr GE,0x29bd06
	ld	xhl, 0x6b636568
	nop                                     ; nop
	popw ix                                 ; pop IX
	ld	xde, 0x706d434e
	ld	xde, 0x68437469
	jr	mi, 0x63
	jr ugt, .LDIV_bca7                     ; [6b 00] jr UGT,0x29bca7
.LDIV_bca7:
	nop                                     ; nop
	popw ix                                 ; pop IX
	ld	xde, 0x7471534e
	ld	xde, 0x68437469
.LDIV_bcb3:
	jr	mi, 0x63
	jr ugt, .LDIV_bcb7                     ; [6b 00] jr UGT,0x29bcb7
.LDIV_bcb7:
	nop                                     ; nop
	popw ix                                 ; pop IX
	ld	xde, 0x746d504e
	ld	xde, 0x68437469
	jr	mi, 0x63
	jr ugt, .LDIV_bcc7                     ; [6b 00] jr UGT,0x29bcc7
.LDIV_bcc7:
	nop                                     ; nop
	popw ix                                 ; pop IX
	ld	xde, 0x77734c4e
	ld	xde, 0x68437469
	jr	mi, 0x63
	jr ugt, .LDIV_bcd7                     ; [6b 00] jr UGT,0x29bcd7
.LDIV_bcd7:
	nop                                     ; nop
.LDIV_bcd8:
	ld	xiz, 0x4c656c69
	ld	xde, 0x6d614e4e
	jr	mi, 0x43
	jr	t, 0x65
	jr	ule, 0x6b
	nop                                     ; nop
	nop                                     ; nop
.LDIV_bcea:
	popw ix                                 ; pop IX
	ld	xde, 0x616f4c4e
	jr	ov, 0x53
	jrl	c, 0x6143
	jrl	ov, 0x6863
	nop                                     ; nop
	nop                                     ; nop
	popw ix                                 ; pop IX
	ld	xde, 0x6761504e
	jr	mi, 0x31
	.byte 0x53                             ; db
	jrl	c, 0x6143
.LDIV_bd06:
	jrl	ov, 0x6863
	nop                                     ; nop
	ld	xde, 0x616d7469
	jrl	f, 0x6448
	jr	ov, 0x5f
	jr ge, .LDIV_bd79                      ; [69 63] jr GE,0x29bd79
	jr	nc, 0x6e
.LDIV_bd18:
	nop                                     ; nop
	nop                                     ; nop
	ld	xix, 0x6c546c65
	jrl	t, 0x6445
	jr	ge, 0x74
	ld	xhl, 0x6b636568
	nop                                     ; nop
	ld	xix, 0x644d6c65
	ld	xiy, 0x43746964
	jr	t, 0x65
	jr	ule, 0x6b
.LDIV_bd38:
	nop                                     ; nop
	nop                                     ; nop
	ld	xix, 0x63526c65
	jr	pl, 0x45
	jr	ov, 0x69
	jrl	ov, 0x6843
	jr	mi, 0x63
	jr ugt, .LDIV_bd4a                     ; [6b 00] jr UGT,0x29bd4a
.LDIV_bd4a:
	ld	xix, 0x734d6c65
	jrl	f, 0x6445
	jr	ge, 0x74
	ld	xhl, 0x6b636568
	nop                                     ; nop
	ld	xix, 0x6d546c65
	ld	xiy, 0x43746964
	jr	t, 0x65
	jr ule, .LDIV_bdd3                     ; [63 6b] jr ULE,0x29bdd3
	nop                                     ; nop
	nop                                     ; nop
	ld	xix, 0x6d436c65
	jrl	f, 0x6445
	jr ge, .LDIV_bde8                      ; [69 74] jr GE,0x29bde8
	ld	xhl, 0x6b636568
.LDIV_bd79:
	nop                                     ; nop
	ld	xix, 0x71536c65
	jrl	ov, 0x6445
	jr	ge, 0x74
	ld	xhl, 0x6b636568
	nop                                     ; nop
	ld	xix, 0x6d506c65
	jrl	ov, 0x6445
	jr	ge, 0x74
	ld	xhl, 0x6b636568
	nop                                     ; nop
	ld	xix, 0x734c6c65
	jrl	c, 0x6445
	jr ge, .LDIV_be18                      ; [69 74] jr GE,0x29be18
	ld	xhl, 0x6b636568
	nop                                     ; nop
	ld	xix, 0x704f6c65
	jrl	ov, 0x614e
	jr	pl, 0x65
	ld	xhl, 0x6b636568
	nop                                     ; nop
	ld	xix, 0x704f6c65
	jrl	ov, 0x7753
	ld	xiy, 0x746e6576
	ld	xhl, 0x68637461
	nop                                     ; nop
	nop                                     ; nop
	.byte 0x53                             ; db
	jr	lt, 0x76
	jr	mi, 0x4f
.LDIV_bdd3:
	jrl	f, 0x5374
	jrl	c, 0x7645
	jr	mi, 0x6e
	jrl	ov, 0x6143
	jrl	ov, 0x6863
	nop                                     ; nop
	.byte 0x57                             ; db
	jrl	le, 0x6f43
	jr nz, .LDIV_be4e                      ; [6e 66] jr NZ,0x29be4e
.LDIV_bde8:
	jr	ge, 0x72
	jr	pl, 0x45
	jrl	z, 0x6e65
	jrl	ov, 0x6143
	jrl	ov, 0x6863
	nop                                     ; nop
	ld	xhl, 0x44465f50
	pop xsp                                 ; pop XSP
	ld	xix, 0x414e5249
	popw iy                                 ; pop IY
	ld	xiy, 0x63656843
	jr ugt, .LDIV_be09                     ; [6b 00] jr UGT,0x29be09
.LDIV_be09:
	nop                                     ; nop
	ld	xiz, 0x614e736c
	jr	pl, 0x69
	jr nz, .LDIV_be7a                      ; [6e 67] jr NZ,0x29be7a
	ld	xhl, 0x6b636568
.LDIV_be18:
	ldw	de, 0x4600
	jr	nov, 0x73
	popw iz                                 ; pop IZ
	jr	lt, 0x6d
	jr ge, .LDIV_be90                      ; [69 6e] jr GE,0x29be90
.LDIV_be22:
	jr c, .LDIV_be67                       ; [67 43] jr C,0x29be67
	jr t, .LDIV_be8b                       ; [68 65] jr T,0x29be8b
	jr	ule, 0x6b
	nop                                     ; nop
	nop                                     ; nop
	popw wa                                 ; pop WA
	jr	ov, 0x54
	jr	ge, 0x74
	jr	nov, 0x65
.LDIV_be31:
	ld	xiy, 0x746e6576
	ld	xhl, 0x68637461
	nop                                     ; nop
	popw de                                 ; pop DE
	jrl	mi, 0x706d
	ld	xbc, 0x72657466
	popw ix                                 ; pop IX
	jr nc, .LDIV_bea9                      ; [6f 61] jr NC,0x29bea9
	jr	ov, 0x4d
	jr nc, .LDIV_beb0                      ; [6f 64] jr NC,0x29beb0
	jr	mi, 0x45
.LDIV_be4e:
	jr	ov, 0x69
	jrl	ov, 0x6843
	jr	mi, 0x63
	jr ugt, .LDIV_be57                     ; [6b 00] jr UGT,0x29be57
.LDIV_be57:
	nop                                     ; nop
	popw ix                                 ; pop IX
	jr nc, .LDIV_bebc                      ; [6f 61] jr NC,0x29bebc
	jr	ov, 0x42
	jrl	ge, 0x754e
	jr	pl, 0x62
	jr	mi, 0x72
	popw iy                                 ; pop IY
	jr	nc, 0x64
.LDIV_be67:
	jr	mi, 0x45
	jr	ov, 0x69
	jrl	ov, 0x6843
	jr	mi, 0x63
	jr ugt, .LDIV_be72                     ; [6b 00] jr UGT,0x29be72
.LDIV_be72:
	.byte 0x51                             ; db
	jrl	mi, 0x6369
	jr	ugt, 0x4c
	jr	nc, 0x61
.LDIV_be7a:
	jr	ov, 0x4d
	jr	nc, 0x64
	jr	mi, 0x45
	jr	ov, 0x69
	jrl	ov, 0x6843
	jr	mi, 0x63
	jr ugt, .LDIV_be89                     ; [6b 00] jr UGT,0x29be89
.LDIV_be89:
	nop                                     ; nop
	.byte 0x57                             ; db
.LDIV_be8b:
	jrl	le, 0x7469
	jr	mi, 0x43
.LDIV_be90:
	jr	nc, 0x6e
	jr	z, 0x69
	jrl	le, 0x456d
.LDIV_be97:
	jr	ov, 0x69
	jrl	ov, 0x6843
	jr	mi, 0x63
	jr ugt, .LDIV_bea0                     ; [6b 00] jr UGT,0x29bea0
.LDIV_bea0:
	.byte 0x57                             ; db
	jrl	le, 0x7469
	jr	mi, 0x50
	jrl	le, 0x746f
.LDIV_bea9:
	jr	mi, 0x63
	jrl	ov, 0x6445
.LDIV_beae:
	jr	ge, 0x74
.LDIV_beb0:
	ld	xhl, 0x6b636568
	nop                                     ; nop
	.byte 0x53                             ; db
	jr z, .LDIV_bf31                       ; [66 78] jr Z,0x29bf31
.LDIV_beb9:
	.byte 0x54                             ; db
	jr	nov, 0x78
.LDIV_bebc:
	ld	xde, 0x68437469
	jr	mi, 0x63
	jr ugt, .LDIV_bec5                     ; [6b 00] jr UGT,0x29bec5
.LDIV_bec5:
	nop                                     ; nop
	.byte 0x53                             ; db
	jr z, .LDIV_bf41                       ; [66 78] jr Z,0x29bf41
.LDIV_bec9:
	popw iy                                 ; pop IY
	jr	ov, 0x42
	jr ge, .LDIV_bf42                      ; [69 74] jr GE,0x29bf42
	ld	xhl, 0x6b636568
.LDIV_bed3:
	nop                                     ; nop
.LDIV_bed4:
	.byte 0x53                             ; db
	jr	z, 0x78
	.byte 0x52                             ; db
	jr ule, .LDIV_bf47                     ; [63 6d] jr ULE,0x29bf47
	ld	xde, 0x68437469
	jr	mi, 0x63
	jr ugt, .LDIV_bee3                     ; [6b 00] jr UGT,0x29bee3
.LDIV_bee3:
	nop                                     ; nop
	.byte 0x53                             ; db
	jr	z, 0x78
	popw iy                                 ; pop IY
	jrl	ule, 0x4270
.LDIV_beeb:
	jr	ge, 0x74
	ld	xhl, 0x6b636568
	nop                                     ; nop
	nop                                     ; nop
	.byte 0x53                             ; db
	jr z, .LDIV_bf6f                       ; [66 78] jr Z,0x29bf6f
	.byte 0x54                             ; db
	jr	pl, 0x42
	jr	ge, 0x74
	ld	xhl, 0x6b636568
.LDIV_bf01:
	nop                                     ; nop
.LDIV_bf02:
	.byte 0x53                             ; db
	jr z, .LDIV_bf7d                       ; [66 78] jr Z,0x29bf7d
	ld	xhl, 0x6942706d
	jrl	ov, 0x6843
	jr	mi, 0x63
	jr ugt, .LDIV_bf11                     ; [6b 00] jr UGT,0x29bf11
.LDIV_bf11:
	nop                                     ; nop
	.byte 0x53                             ; db
	jr	z, 0x78
	.byte 0x53                             ; db
	jrl	lt, 0x4274
	jr	ge, 0x74
	ld	xhl, 0x6b636568
	nop                                     ; nop
	nop                                     ; nop
	.byte 0x53                             ; db
	jr	z, 0x78
	.byte 0x50                             ; db
.LDIV_bf26:
	jr	pl, 0x74
	ld	xde, 0x68437469
	jr	mi, 0x63
	jr ugt, .LDIV_bf31                     ; [6b 00] jr UGT,0x29bf31
.LDIV_bf31:
	nop                                     ; nop
	.byte 0x53                             ; db
	jr z, .LDIV_bfad                       ; [66 78] jr Z,0x29bfad
	popw ix                                 ; pop IX
	jrl	ule, 0x4277
	jr ge, .LDIV_bfaf                      ; [69 74] jr GE,0x29bfaf
	ld	xhl, 0x6b636568
	nop                                     ; nop
.LDIV_bf41:
	nop                                     ; nop
.LDIV_bf42:
	ld	xiz, 0x4f656c69
.LDIV_bf47:
	jrl	f, 0x4e74
	jr	lt, 0x6d
	jr	mi, 0x43
	jr	t, 0x65
	jr	ule, 0x6b
	nop                                     ; nop
	nop                                     ; nop
	.byte 0x53                             ; db
	jr lt, .LDIV_bfcd                      ; [61 76] jr LT,0x29bfcd
	jr	mi, 0x4f
	jrl	f, 0x4e74
	jr	lt, 0x6d
	jr	mi, 0x43
	jr t, .LDIV_bfc7                       ; [68 65] jr T,0x29bfc7
	jr ule, .LDIV_bfcf                     ; [63 6b] jr ULE,0x29bfcf
	nop                                     ; nop
	nop                                     ; nop
	.byte 0x53                             ; db
	jr	mi, 0x70
	jr lt, .LDIV_bfdd                      ; [61 72] jr LT,0x29bfdd
	jr	lt, 0x74
	jr	mi, 0x4f
.LDIV_bf6f:
	jrl	mi, 0x7074
.LDIV_bf72:
	jrl	mi, 0x4d74
	jr	nc, 0x64
	jr	mi, 0x43
	jr	t, 0x65
	jr	ule, 0x6b
.LDIV_bf7d:
	nop                                     ; nop
	.byte 0x50                             ; db
	ld	xhl, 0x5441445f
	ld	xbc, 0x4e494c5f
	popw hl                                 ; pop HL
	pop xsp                                 ; pop XSP
	.byte 0x50                             ; db
	ld	xbc, 0x48004547
.LDIV_bf91:
	ld	xix, 0x54555f44
	popw bc                                 ; pop BC
	popw ix                                 ; pop IX
	pop xsp                                 ; pop XSP
	.byte 0x50                             ; db
	ld	xbc, 0x48004547
	ld	xix, 0x49445f44
	.byte 0x52                             ; db
	popw iz                                 ; pop IZ
	ld	xbc, 0x6843454d
	jr	mi, 0x63
.LDIV_bfad:
	jr ugt, .LDIV_bfaf                     ; [6b 00] jr UGT,0x29bfaf
.LDIV_bfaf:
	nop                                     ; nop
	popw wa                                 ; pop WA
	ld	xix, 0x6d614e44
	jr	ge, 0x6e
	jr	c, 0x43
	jr	t, 0x65
.LDIV_bfbc:
	jr	ule, 0x6b
.LDIV_bfbe:
	nop                                     ; nop
	nop                                     ; nop
	popw wa                                 ; pop WA
	jr	lt, 0x72
	jr	ov, 0x54
	jr	mi, 0x73
.LDIV_bfc7:
	jrl	ov, 0x6150
	jr	c, 0x65
	nop                                     ; nop
.LDIV_bfcd:
	nop                                     ; nop
	nop                                     ; nop
.LDIV_bfcf:
	nop                                     ; nop
	jrl	ule, 0x6c65
	pop xsp                                 ; pop XSP
	jrl	ov, 0x7079
	jr	mi, 0x00
.LDIV_bfd9:
	nop                                     ; nop
	jr	mi, 0x6e
	pop xsp                                 ; pop XSP
.LDIV_bfdd:
	jrl	f, 0x7261


