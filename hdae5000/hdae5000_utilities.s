HDAE5000_StrPrefixCmp:	; 29AF2Dh
	; returns HDAE5000_MemCmp(s, t, HDAE5000_StrLen(s)): 0 when t BEGINS WITH
	; s (a string compare that ignores whatever follows in t).  Callers use
	; it as a string-equality test (CHS code entry, slot names).
	; Validate display buffer and read file data
	; Input: (XSP+8) = XIZ context, (XSP+0x12) = XWA file params
	push xiz
	ld xiz, (xsp + 8)		; load context pointer
	push xiz			; arg for Display_Buffer_Validate
	call HDAE5000_StrLen
	pushw hl			; save validation result
	ld xwa, (xsp + 0x12)		; load file params
	push xwa			; arg 2
	push xiz			; arg 1
	call HDAE5000_MemCmp
	lda xsp, (xsp + 0x0E)		; clean up 14 bytes
	pop xiz
	ret

HDAE5000_StrCpy:	; 0x29AF45
	; strcpy(dest, src) = HDAE5000_MemCCpy(dest, src, 0, 0xFFFE), then a
	; forced terminator if no NUL was found.  328 call sites.
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
	call HDAE5000_MemCCpy
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

HDAE5000_StrLen:	; 0x29AF71
	; strlen(s) = HDAE5000_MemChr(s, 0, 0xFFFF) - s, or 0xFFFF if no NUL.
	; Validate display buffer - call String_Length, return offset or -1
	; Stack: [+0x0C] = buffer pointer (XIZ)
	; Returns: HL = offset from XIZ or -1 on failure
	push xiz
	pushw 0xFFFF			; sentinel
	pushw 0x0000			; flags
	ld xiz, (xsp + 0x0C)		; buffer pointer
	push xiz
	call HDAE5000_MemChr
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
	; strncat(dest, src, n): walks to dest's terminator first (.Lscl_entry
	; loop), then appends at most n bytes and terminates.  XHL = dest.
HDAE5000_StrNCat:
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
	cp wa, 0:i3			; was count zero?
	jr nz, .Lscl_copy		; no - copy next byte
	ld (xix), 0x00		; null-terminate
	ret

HDAE5000_StrNCmp:	; 0x29AFBE
	; strncmp(a, b, n): stops at n or at a NUL in a.
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
	ld hl, 0:i3			; return 0 (match up to null)
	ret
.Lmcmp_advance:
	inc 1, xix
	inc 1, xde
	dec 1, bc
.Lmcmp_check:
	cp bc, 0:i3			; count exhausted?
	jr z, .Lmcmp_result
	ld a, (xde)			; B byte
	cp a, (xix)			; compare with A byte
	jr z, .Lmcmp_loop		; equal - continue
.Lmcmp_result:
	ld l, 0x00:opc			; default L = 0
	cp bc, 0:i3			; if count exhausted, return 0
	jr z, .Lmcmp_done
	ld a, (xix)			; A byte
	sub a, (xde)			; difference = A - B
	ld l, a
.Lmcmp_done:
	exts hl				; sign-extend L to HL
	ret

HDAE5000_StrNCpy:	; 0x29AFF0
	; strncpy(dest, src, n): copies until n or src's NUL, then zero-fills
	; the rest of the n bytes (.LMCR_b010 loop).  XHL = dest.  (Was named
	; MemCopy_Reverse; nothing here runs backwards.)
; LMCR: 0x29AFF0 (1853 bytes)
	; ^ the 1853 bytes are the whole run of library routines from here to
	;   HDAE5000_Multiply, NOT this routine (43 bytes); see the labels below.

	ld	bc, (xsp+12)
	ld xde, (xsp + 0x08)                    ; ld XDE,(XSP+0x08)
	ld xix, (xsp + 0x04)                    ; ld XIX,(XSP+0x04)
	ld	xhl, xix
	jr t, .LMCR_b005                       ; [68 08] jr T,0x29b005
.LMCR_affd:
	ld a, (xde+)		; ld A,(XDE+)
	ld (xix+), a		; ld (XIX+),A
	dec	1, bc
.LMCR_b005:
	cp	bc, 0:i3
	jr z, .LMCR_b00e                       ; [66 05] jr Z,0x29b00e
	cp	(xde), 0x00
	jr nz, .LMCR_affd                      ; [6e ef] jr NZ,0x29affd
.LMCR_b00e:
	jr t, .LMCR_b016                       ; [68 06] jr T,0x29b016
.LMCR_b010:
	ld (xix+), 0x00		; ld (XIX+),0x00
	dec	1, bc
.LMCR_b016:
	cp	bc, 0:i3
	jr nz, .LMCR_b010                      ; [6e f6] jr NZ,0x29b010
	ret

HDAE5000_StrRev:
	; strrev(s): swaps s[i] and s[strlen(s)-1-i] in place; returns XHL = s.
	push xiz
	ld xiz, (xsp + 0x08)                    ; ld XIZ,(XSP+0x08)
	push xiz
	call HDAE5000_StrLen
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
	ld (xbc+), l		; ld (XBC+),L
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

HDAE5000_StrUpr:
	; strupr(s): subtracts 0x20 from every byte whose HDAE5000_CType_Table
	; entry has bit 1 (lower case) set; returns XHL = s.
	ld xix, (xsp + 0x04)                    ; ld XIX,(XSP+0x04)
	ld	xhl, xix
	jr t, .LMCR_b074                       ; [68 1f] jr T,0x29b074
.LMCR_b055:
	ld	xde, xix
	ld	a, (xix)
	extz wa                                 ; extz WA
	lda xbc, (HDAE5000_CType_Table:24)
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

; ----------------------------------------------------------------------------
; Floating point -> decimal digits (used by HDAE5000_FormatFloat)
;
; HDAE5000_FltDec_Convert and the ten FltDec_* helpers below turn the IEEE
; bytes of a double (or, with flag bit 7, the 10-byte long double) into a
; string of decimal digits plus a decimal exponent, using multi-precision
; arithmetic on arrays of u16 limbs that each hold one byte (every helper
; masks with 0x00ff and carries the high byte into the neighbour).  Buffers
; are in RAM: 0x2394AA (the binary mantissa, limbs), 0x2394EA (fraction
; work area, 10 limbs), 0x23948A (the decimal digits, 32 bytes).
; Each helper's name says what its loop does; which C library source
; routine each corresponds to is not recoverable from the ROM.
; ----------------------------------------------------------------------------
HDAE5000_FltDec_Convert:
	; five stack arguments (HDAE5000_FormatFloat pushes them): +0x18 value
	; bytes *, +0x1C digit output buffer, +0x20 flags (bit 7 = 10-byte long
	; double), +0x22 int *decimal exponent, +0x26 int *sign (offsets as
	; read inside the 20-byte frame below).
	lda	xsp, (xsp-16)
	push xiz
	ld	iz, 0:i3
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
	lda xde, (0x2394ea:24)
	lda xwa, (0x2394aa:24)
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
	stb_dri c, 0x07, 0xE0, 0xFA	; ld (XWA+QIZ),C
	inc	1, qiz
	ld	wa, qiz
	cp	wa, (xsp+8)
	jr lt, .LMCR_b0e2                      ; [61 de] jr LT,0x29b0e2
.LMCR_b104:
	lda	xde, (xsp+10)
	bitm	7, (xde)
	jr z, .LMCR_b10f                       ; [66 04] jr Z,0x29b10f
	ld	wa, 1:i3
	jr t, .LMCR_b111                       ; [68 02] jr T,0x29b111
.LMCR_b10f:
	ld	wa, 0:i3
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
	ld	wa, 4:i3
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
	calr	HDAE5000_FltDec_DecimalExponent
	inc 2, xsp                              ; inc 2,XSP
	ld (xsp + 0x04), hl
	cp	iz, 0:i3
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
	lda xbc, (0x2394a6:24)
	extz wa                                 ; extz WA
	stw_dri wa, 0x07, 0xE4, 0xE8	; ld (XBC+DE),WA
	inc	1, qiz
	cpw	qiz, 0x000a
	jr lt, .LMCR_b17f                      ; [61 da] jr LT,0x29b17f
	jr t, .LMCR_b1f9                       ; [68 52] jr T,0x29b1f9
.LMCR_b1a7:
	ld	ix, 0:i3
	ld	qiz, 0
.LMCR_b1ac:
	lda	xbc, (xsp+10)
	cpib_sri 0x07, 0xE4, 0xFA, 0x00	; cp (XBC+QIZ),0x00
	jr z, .LMCR_b1bb                       ; [66 04] jr Z,0x29b1bb
	ld	ix, 1:i3
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
	lda xde, (0x2394aa:24)
	extz wa                                 ; extz WA
	stw_dri wa, 0x07, 0xE8, 0xEC	; ld (XDE+HL),WA
	inc	1, qiz
	cpw	qiz, 0x0008
	jr lt, .LMCR_b1cc                      ; [61 db] jr LT,0x29b1cc
	cp	ix, 0:i3
	jr z, .LMCR_b1f9                       ; [66 04] jr Z,0x29b1f9
	or16_imm_ri xde, 0x10, 0x00		; or (XDE),0x0010
.LMCR_b1f9:
	pushm	(xsp+8)
	pushw 0x0023
	pushw 0x94aa
	calr	HDAE5000_FltDec_NormalizeLeft
	inc	6, xsp
	ld	qiz, 0
	cp	iz, 0:i3
	jr le, .LMCR_b262                      ; [62 54] jr LE,0x29b262
	cpw	(xsp+4), 0x0000
	jr le, .LMCR_b23a                      ; [62 25] jr LE,0x29b23a
.LMCR_b215:
	pushw 0x0023
	pushw 0x94aa
	calr	HDAE5000_FltDec_DivBy10
	pushm	(xsp+12)
	pushw 0x0023
	pushw 0x94aa
	calr	HDAE5000_FltDec_NormalizeLeft
	lda	xsp, (xsp+10)
	sub	iz, hl
	inc	1, qiz
	ld	wa, qiz
	cp	wa, (xsp+4)
	jr lt, .LMCR_b215                      ; [61 db] jr LT,0x29b215
.LMCR_b23a:
	pushm	(xsp+6)
	ld	wa, 6:i3
	sub	wa, iz
	pushw wa                                ; push WA
	pushw 0x0023
	pushw 0x94aa
	jr t, .LMCR_b27c                       ; [68 32] jr T,0x29b27c
.LMCR_b24a:
	push xbc
	calr	HDAE5000_FltDec_MulBy10
	pushm	(xsp+12)
	pushw 0x0023
	pushw 0x94aa
	calr	HDAE5000_FltDec_NormalizeRight
	lda	xsp, (xsp+10)
	add	iz, hl
	inc	1, qiz
.LMCR_b262:
	ld	de, (xsp+4)
	neg	de
	lda xbc, (0x2394aa:24)
	ld	wa, qiz
	cp	wa, de
	jr lt, .LMCR_b24a                      ; [61 d7] jr LT,0x29b24a
	pushm	(xsp+6)
	ld	wa, 6:i3
	sub	wa, iz
	pushw wa                                ; push WA
	push xbc
.LMCR_b27c:
	calr	HDAE5000_FltDec_ShiftRightBits
	inc 0, xsp                              ; inc 0,XSP
	ld	qiz, 1
.LMCR_b284:
	push	qiz
	ld	bc, qiz
	add	bc, bc
	lda xwa, (0x2394aa:24)
	push_sriw 0x07, 0xE0, 0xE4	; pushw (XWA+BC)
	calr	HDAE5000_FltDec_FractionDigits
	inc 4, xsp                              ; inc 4,XSP
	inc	1, qiz
	cpw	qiz, 0x0009
	jr lt, .LMCR_b284                      ; [61 df] jr LT,0x29b284
	ld	de, 0:i3
	lda xbc, (0x2394aa:24)
	ld xhl, (xsp + 0x1c)                    ; ld XHL,(XSP+0x1c)
	ld	wa, (xbc)
	cp	wa, 0x0009
	jr ule, .LMCR_b2c4                     ; [63 0d] jr ULE,0x29b2c4
	ld	de, 1:i3
	extz xwa
	div wa, 0x000a
	ld	(xhl), a
	incw	1, (xsp+4)
.LMCR_b2c4:
	ld	ix, de
	inc	1, de
	ld	wa, (xbc)
	extz xwa
	div wa, 0x000a
	ld	wa, qwa
	stb_dri a, 0x07, 0xEC, 0xF0	; ld (XHL+IX),A
	incw	1, (xsp+4)
	ld	qiz, 1
	jr t, .LMCR_b2f6                       ; [68 16] jr T,0x29b2f6
.LMCR_b2e0:
	ld	bc, de
	inc	1, de
	lda xwa, (0x23948a:24)
	ldb_sri a, 0x07, 0xE0, 0xFA	; ld A,(XWA+QIZ)
	stb_dri a, 0x07, 0xEC, 0xE4	; ld (XHL+BC),A
	inc	1, qiz
.LMCR_b2f6:
	ld	bc, (xsp+6)
	inc	2, bc
	ld	wa, qiz
	cp	wa, bc
	jr lt, .LMCR_b2e0                      ; [61 de] jr LT,0x29b2e0
	ld	de, (xsp+6)
	inc	1, de
	lda_dri xbc, 0x07, 0xEC, 0xE8	; lda XBC,XHL+DE
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
	lda_dri xwa, 0x07, 0xEC, 0xFA	; lda XWA,XHL+QIZ
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

HDAE5000_FltDec_ShiftRightBits:
	; shift a limb array right by N bits (limbs hold 8 bits each)
	dec 0, xsp                              ; dec 0,XSP
	pushw iz                                ; push IZ
	ld	iz, 0:i3
	ld	wa, 0:i3
	ld	hl, (xsp+18)
	cp	hl, 0:i3
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
	cp	iz, 0:i3
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
	ld	xwa, 2:i3
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
	cp	iz, 0:i3
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

HDAE5000_FltDec_ShiftLeftBits:
	; shift a limb array left by N bits, carrying each limb's high byte up
	ld xiy, (xsp + 0x04)                    ; ld XIY,(XSP+0x04)
	and16_imm_ri xiy, 0xff, 0x00		; and (XIY),0x00ff
	ld	ix, 1:i3
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

HDAE5000_FltDec_FractionDigits:
	; zero the 0x2394EA work area, then repeatedly x10 (FracMulBy10) and
	; add the integer part as the next decimal digit (AddDigit)
	pushw iz                                ; push IZ
	lda xde, (0x2394ea:24)
	ld	xwa, xde
	lda	xbc, (xde+18)
.LMCR_b439:
	ldw (xwa+), 0x0000		; ld (XWA+),0x0000
	cp	xwa, xbc
	jr c, .LMCR_b439                       ; [67 f7] jr C,0x29b439
	ld	wa, (xsp+6)
	ld (xde + 0x10), wa                     ; ld (XDE+0x10),WA
	ld	iz, 0:i3
.LMCR_b44a:
	lda xwa, (0x2394ea:24)
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
	calr	HDAE5000_FltDec_FracMulBy10
.LMCR_b494:
	ldw	wa, 0x0008
	sub	wa, (xsp+8)
	add	wa, wa
	lda xbc, (0x2394ea:24)
	ldw_sri wa, 0x07, 0xE4, 0xE0	; ld WA,(XBC+WA)
	cp	wa, 0:i3
	jr z, .LMCR_b48f                       ; [66 e5] jr Z,0x29b48f
	pushw iz                                ; push IZ
	pushw wa                                ; push WA
	calr	HDAE5000_FltDec_AddDigit
	inc 4, xsp                              ; inc 4,XSP
	ldw	bc, 0x0008
	sub	bc, (xsp+8)
	add	bc, bc
	lda xwa, (0x2394ea:24)
	stiw_ind 0x07, 0xE0, 0xE4, 0x00, 0x00	; ld (XWA+BC),0x0000
	cp	iz, 0x0020
	jrl le, .LMCR_b44a                     ; [72 7e ff] jrl LE,0x29b44a
.LMCR_b4cc:
	popw iz                                 ; pop IZ
	ret

HDAE5000_FltDec_AddDigit:
	; add a value at a position of the 0x23948A decimal digit buffer, with
	; decimal carry (subtract 10, increment the digit to the left)
	ld	de, (xsp+6)
	cp	de, 0x0020
	jr ge, .LMCR_b4e4                      ; [69 0d] jr GE,0x29b4e4
	lda xbc, (0x23948a:24)
	ld	wa, (xsp+4)
	add_srib_mr a, 0x07, 0xE4, 0xE8	; add (XBC+DE),A
.LMCR_b4e4:
	jr t, .LMCR_b4e8                       ; [68 02] jr T,0x29b4e8
.LMCR_b4e6:
	dec	1, de
.LMCR_b4e8:
	cp	de, 0x0020
	jr ge, .LMCR_b4e6                      ; [69 f8] jr GE,0x29b4e6
	lda xwa, (0x23948a:24)
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

	cp	de, 0:i3
	jr gt, .LMCR_b4f5                      ; [6a e1] jr GT,0x29b4f5
	ret

HDAE5000_FltDec_DivBy10:
	; divide a limb array by 10 in place (DIV per limb, remainder carried down)
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
	ld (xbc+), wa		; ld (XBC+),WA
	cp	xbc, xde
	jr c, .LMCR_b51d                       ; [67 e0] jr C,0x29b51d
	ret

HDAE5000_FltDec_MulBy10:
	; multiply a 16-limb array by 10 in place with carry propagation
	pushw iz                                ; push IZ
	ld	ix, 0:i3
	ld	xbc, 0:i3
.LMCR_b543:
	ld xhl, (xsp + 0x06)                    ; ld XHL,(XSP+0x06)
	ld	xde, xbc
	add	xde, xhl
	ld	wa, (xde)
	mul	wa, 0x000a
	ld (xde), wa                            ; ld (XDE),WA
	cp	ix, 0:i3
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
	cp	iz, 0:i3
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
	incw	1, (xhl+28)
.LMCR_b59a:
	ldw	(xbc), 0x0000
	popw iz                                 ; pop IZ
	ret

HDAE5000_FltDec_FracMulBy10:
	; multiply the 0x2394EA work area (10 limbs) by 10 and normalise carries
	lda xhl, (0x2394ea:24)
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
	cp	de, 0:i3
	jr gt, .LMCR_b5c4                      ; [6a e0] jr GT,0x29b5c4
	ret

HDAE5000_FltDec_NormalizeLeft:
	; shift left until the top limb has bit 7 set; returns HL = shift count
	dec	2, xsp
	pushw iz                                ; push IZ
	ld	iz, 0:i3
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
	ld	hl, 0:i3
	jr t, .LMCR_b653                       ; [68 43] jr T,0x29b653
.LMCR_b610:
	ldw (xsp + 0x02), 0
	jr t, .LMCR_b646                       ; [68 2f] jr T,0x29b646
.LMCR_b617:
	ld	iz, 0:i3
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
	cp	iz, 0:i3
	jr z, .LMCR_b643                       ; [66 0d] jr Z,0x29b643
	pushw iz                                ; push IZ
	pushm	(xsp+14)
	ld xwa, (xsp + 0x0c)                    ; ld XWA,(XSP+0x0c)
	push xwa
	calr	HDAE5000_FltDec_ShiftLeftBits
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

HDAE5000_FltDec_NormalizeRight:
	; if the top limb exceeds 8 bits, shift right until it fits; HL = count
	pushw iz                                ; push IZ
	ld xde, (xsp + 0x06)                    ; ld XDE,(XSP+0x06)
	ld	iz, 0:i3
	ld	bc, (xsp+10)
	cp	bc, 0:i3
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
	ld	hl, 0:i3
	jr t, .LMCR_b6a7                       ; [68 27] jr T,0x29b6a7
.LMCR_b680:
	ld	hl, (xde)
	ld	iz, 0:i3
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
	cp	iz, 0:i3
	jr z, .LMCR_b6a5                       ; [66 08] jr Z,0x29b6a5
	pushw bc                                ; push BC
	pushw iz                                ; push IZ
	push xde
	calr	HDAE5000_FltDec_ShiftRightBits
	inc 0, xsp                              ; inc 0,XSP
.LMCR_b6a5:
	ld	hl, iz
.LMCR_b6a7:
	popw iz                                 ; pop IZ
	ret

HDAE5000_FltDec_DecimalExponent:
	; decimal exponent from the binary one: e * 301 / 1000 (log10 2 ~ 0.301),
	; with the remainder deciding the rounding (HDAE5000_SMod32/_SDiv32 by 1000)
	dec 0, xsp                              ; dec 0,XSP
	push xiz
	ld	wa, (xsp+16)
	exts xwa                                ; exts XWA
	lda	xbc, (301:16)
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
	lda	xbc, (1000:16)
	call HDAE5000_SMod32
	ld (xsp + 0x08), xhl                    ; ld (XSP+0x08),XHL
	ld	xwa, xiz
	lda	xbc, (1000:16)
	call HDAE5000_SDiv32
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
	; XHL = low 32 bits of XWA * XBC, from three 16x16 MULs (hi*lo, lo*hi,
	; lo*lo).  23 bytes.
; LMUL: 0x29B72D (402 bytes)
	; ^ region size, not routine size: soft-float Float_Unpack/Pack, Copy8,
	;   Copy10, (U)LongToFloat, FloatDiv and the signed divide front end
	;   follow, each under its own label below.

	ld	hl, qwa
	mul	xhl, bc
	ld	de, qbc
	mul	xde, wa
	add	xhl, xde
	ld	qhl, hl
	ld	hl, 0:i3
	mul	xwa, bc
	add	xhl, xwa
	ret

	nop                                     ; nop
HDAE5000_Float_Unpack:
	; unpack the IEEE single at (XBC) into the internal form at (XWA):
	;   +0 s16 unbiased exponent, +2 u8 class flag (1 = zero), +3 u8 sign
	;   (bit 7), +4 u32 mantissa with the hidden bit restored (bit 23).
	; Returns L = class flag.
	ld	xhl, 0:i3
	ld xix, (xbc)                           ; ld XIX,(XBC)
	ld	de, qix
	ldcf16ri 15, de		; ldcf 0x0f,DE
	stcf	0x0f, qhl
	ld	hl, de
	sll	hl, 0x01
	ld	l, 0x00:opc
	ex8 h, l		; ex H,L
	cp	hl, 0:i3
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
	ld	xix, 0:i3
	ldib_erp 0xee, 1		; ld QL,1
	jr t, .LMUL_b76d                       ; [68 f0] jr T,0x29b76d
	nop                                     ; nop
HDAE5000_Float_Pack:
	; pack the internal form at (XBC) into an IEEE single at (XWA).  Exponent
	; overflow stores +/-0x7F7FFFFF (FLT_MAX); class flag 8 stores 0; both
	; set errno (RAM 0x230ECA) = 34 (ERANGE) and call the hook pointer at
	; RAM 0x23A1A8 when it is non-zero.  Zero (class 1) and exponent
	; underflow store 0 silently.
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
	ld	xde, 0:i3
	jr t, .LMUL_b7c9                       ; [68 11] jr T,0x29b7c9
.LMUL_b7b8:
	ld	xde, 0:i3
	ld (xwa), xde                           ; ld (XWA),XDE
	ret

.LMUL_b7bd:
	ldw	de, 0xffff
	ldw	bc, 0x7f7f
	orb_erp b, 0xef		; or B,QH
	ld	qde, bc
.LMUL_b7c9:
	ldw	(0x230ECA:24), 34
	ld (xwa), xde                           ; ld (XWA),XDE
	ld	xbc, (0x23a1a8)
	or xbc, xbc                             ; or XBC,XBC
	call_cc_ri xbc, 14		; call NZ,XBC
	ret

HDAE5000_Copy8:
	; *(double *)XWA = *(double *)XBC -- 8-byte copy.  HDAE5000_DoPrintf uses
	; it to fetch a double va_arg for %e/%f/%g (ap += 8 first).
	ld xix, (xbc)                           ; ld XIX,(XBC)
	ld xiy, (xbc + 0x04)                    ; ld XIY,(XBC+0x04)
	ld (xwa), xix                           ; ld (XWA),XIX
	ld (xwa + 0x04), xiy                    ; ld (XWA+0x04),XIY
	ret

	nop                                     ; nop
HDAE5000_Copy10:
	; 10-byte copy (XBC) -> (XWA): HDAE5000_DoPrintf's long double va_arg
	; fetch, taken when its flag bit 7 is set (ap += 10 first).
	ld xix, (xbc)                           ; ld XIX,(XBC)
	ld xiy, (xbc + 0x04)                    ; ld XIY,(XBC+0x04)
	ld	hl, (xbc+8)
	ld (xwa), xix                           ; ld (XWA),XIX
	ld (xwa + 0x04), xiy                    ; ld (XWA+0x04),XIY
	ld (xwa + 0x08), hl                     ; ld (XWA+0x08),HL
	ret

	nop                                     ; nop
HDAE5000_LongToFloat:
	; *(float *)XWA = (float)*(long *)XBC.  No caller in this ROM (searched:
	; symbolic references to this label, which did not exist before, and
	; the literal 0x29B7FA in every hdae5000 source); library code linked in.
	push xiz
	lda	xsp, (xsp-8)
	ld	xiz, xwa
	ld	xwa, xsp
	ld xbc, (xbc)                           ; ld XBC,(XBC)
	call HDAE5000_Long_To_Unpacked
	ld	xwa, xiz
	ld	xbc, xsp
	call HDAE5000_Float_Pack
	lda	xsp, (xsp+8)
	pop xiz                                 ; pop XIZ
	ret

HDAE5000_ULongToFloat:
	; *(float *)XWA = (float)*(unsigned long *)XBC.
	push xiz
	lda	xsp, (xsp-8)
	ld	xiz, xwa
	ld	xwa, xsp
	ld xbc, (xbc)                           ; ld XBC,(XBC)
	call HDAE5000_ULong_To_Unpacked
	ld	xwa, xiz
	ld	xbc, xsp
	call HDAE5000_Float_Pack
	lda	xsp, (xsp+8)
	pop xiz                                 ; pop XIZ
	ret

HDAE5000_FloatDiv_Special:
	; entered from HDAE5000_Unpacked_Div when either operand's class flag
	; (+2) is non-zero: a zero divisor (flag bit 0) makes the quotient's
	; class 8, which HDAE5000_Float_Pack stores as 0 with errno = ERANGE;
	; otherwise the dividend's special class stands.
	ld	h, (xwa+2)
	ld8_src_rid8 xbc, 0x02, l		; ld L,(XBC+0x02)
	bit 0x00, l		; bit 0x00,L
	ret z                                   ; ret Z

	ld	(xwa+2), 0x08
	ret

HDAE5000_FloatDiv:
	; *(float *)XWA = *(float *)XBC / *(float *)XDE: unpack both
	; (HDAE5000_Float_Unpack), HDAE5000_Unpacked_Div, HDAE5000_Float_Pack.
	push xiz
	lda	xsp, (xsp-20)
	ld	xiz, xde
	ld (xsp + 0x10), xwa                    ; ld (XSP+0x10),XWA
	ld	xwa, xsp
	call HDAE5000_Float_Unpack
	ld	xbc, xiz
	lda	xiz, (xsp+8)
	lda	xwa, (xiz)
	call HDAE5000_Float_Unpack
	ld	xwa, xsp
	lda	xbc, (xiz)
	call HDAE5000_Unpacked_Div
	ld xwa, (xsp + 0x10)                    ; ld XWA,(XSP+0x10)
	ld	xbc, xsp
	call HDAE5000_Float_Pack
	lda	xsp, (xsp+20)
	pop xiz                                 ; pop XIZ
	ret

HDAE5000_SDivMod32_Common:
	; signed front end of HDAE5000_UDivMod32.  D = 0: remainder (sign of the
	; dividend); D = 1: quotient (negated when exactly one operand is
	; negative).  E collects the operand signs (bit 0 dividend, bit 1
	; divisor) before both are made positive.
	ld	e, 0x00:opc
	bit	0x0f, qwa
	jr z, .LMUL_b881                       ; [66 09] jr Z,0x29b881
	ld	e, 0x01:opc
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
	calr	HDAE5000_UDivMod32
	popw wa                                 ; pop WA
	cp	w, 1:i3
	jr z, .LMUL_b8a3                       ; [66 09] jr Z,0x29b8a3
	ld	xhl, xde
	bit	0x00, a
	scc8	nz, a
	jr t, .LMUL_b8a7                       ; [68 04] jr T,0x29b8a7
.LMUL_b8a3:
	cp	a, 3:i3
	ret z                                   ; ret Z

.LMUL_b8a7:
	or xhl, xhl                             ; or XHL,XHL
	ret z                                   ; ret Z

	cp	a, 0:i3
	ret z                                   ; ret Z

	cpl	qhl
	cpl	hl
	inc 1, xhl                              ; inc 1,XHL
	ret

HDAE5000_SMod32:
	; XHL = XWA % XBC, signed (D = 0 into HDAE5000_SDivMod32_Common)
	ld	d, 0x00:opc
	jr t, HDAE5000_SDivMod32_Common                       ; [68 b5] jr T,0x29b870
HDAE5000_SDiv32:
	; XHL = XWA / XBC, signed (D = 1 into HDAE5000_SDivMod32_Common)
	ld	d, 0x01:opc
	jr t, HDAE5000_SDivMod32_Common                       ; [68 b1] jr T,0x29b870


HDAE5000_UMod32:	; 0x29B8BF (6 bytes)
	; XHL = XWA % XBC, unsigned: calls HDAE5000_UDivMod32 and returns its
	; remainder.  (Was named Divide_Unsigned: XDE is the REMAINDER, and the
	; decimal converters' own comments already read it as one.)
	calr HDAE5000_UDivMod32
	ld xhl, xde		; XHL = remainder (XDE)
	ret

HDAE5000_UDivMod32:	; 0x29B8C5
	; UNSIGNED 32/32 divide: XHL = XWA / XBC, XDE = XWA % XBC.
	; Unsigned throughout: `jr c`/`jr ule` compares, a 32/16 DIV fast path
	; when QBC = 0, else a shift-and-subtract loop.  XBC = 0 returns
	; XHL = 0xFFFFFFFF.  (Was named Divide_Signed; the signed forms are
	; HDAE5000_SDiv32 / HDAE5000_SMod32, which call this core.)
; LDIV: 0x29B8C5 (1819 bytes)
	; ^ region size: the double-precision pack, (U)long->unpacked and
	;   float->double routines below share it; this routine is 125 bytes.

	cp	xbc, 0x00000001
	jr z, .LDIV_b8fe                       ; [66 31] jr Z,0x29b8fe
	jr c, .LDIV_b903                       ; [67 34] jr C,0x29b903
	cp	xwa, xbc
	jr ule, .LDIV_b90a                     ; [63 37] jr ULE,0x29b90a
	cp	qbc, 0
	jr nz, .LDIV_b915                      ; [6e 3d] jr NZ,0x29b915
	ld	xde, xwa
	div	xwa, bc
	jr	ov, .LDIV_b8e8
	ld	xhl, 0:i3
	ld	xde, xhl
	ld	hl, wa
	ld	de, qwa
	ret

.LDIV_b8e8:
	ld	wa, qde
	extz xwa
	div	xwa, bc
	ld	qhl, wa
	ld	wa, de
	div	xwa, bc
	ld	hl, wa
	ld	de, qwa
	extz xde                                ; extz XDE
	ret

.LDIV_b8fe:
	ld	xhl, xwa
	ld	xde, 0:i3
	ret

.LDIV_b903:
	ld	xhl, 0:i3
	ld	xde, xhl
	dec	1, xhl
	ret

.LDIV_b90a:
	ld	xhl, 1:i3
	ld	xde, 0:i3
	ret z                                   ; ret Z

	dec	1, xhl
	ld	xde, xwa
	ret

.LDIV_b915:
	ld	d, 0x00:opc
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
	ld	xhl, 0:i3
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

HDAE5000_Double_Pack:
	; pack the 12-byte internal form at (XBC) (exponent/class/sign word,
	; +4 low and +8 high mantissa longs) into an IEEE double at (XWA),
	; bias 0x3FF; exponent overflow and class 8 store DBL_MAX
	; (0x7FEFFFFF FFFFFFFF) with the sign, set errno = 34 (ERANGE) and call
	; the RAM 0x23A1A8 hook; class 1 (zero) and underflow store 0.
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
	ld	xix, 0:i3
	ld	xiy, xix
	jr t, .LDIV_b96f                       ; [68 f4] jr T,0x29b96f
.LDIV_b97b:
	bit_erpb 0xee, 0x00		; bit 0x00,QL
	jr nz, .LDIV_b975                      ; [6e f4] jr NZ,0x29b975
.LDIV_b981:
	ldw	(0x230ECA:24), 34
	ld	xde, 0:i3
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
HDAE5000_Long_To_Unpacked:
	; signed long XBC -> internal form at (XWA): records the sign, negates,
	; then HDAE5000_ULong_To_Unpacked.
	ld	e, 0x00:opc
	ldcf	0x0f, qbc
	stcf8ri 7, e		; stcf 0x07,E
	jr nc, .LDIV_b9be                      ; [6f 07] jr NC,0x29b9be
	cpl	qbc
	cpl	bc
	inc 1, xbc                              ; inc 1,XBC
.LDIV_b9be:
	calr	HDAE5000_ULong_To_Unpacked
	ld	(xiy+3), e
	ret

HDAE5000_ULong_To_Unpacked:
	; unsigned long XBC -> internal form at (XWA): BS1B finds the top bit,
	; the value is shifted to a 24-bit mantissa (rounded) and the exponent
	; stored; XBC = 0 sets class flag 1 (zero).
	ld	xiy, xwa
	or xbc, xbc                             ; or XBC,XBC
	jr z, .LDIV_ba1a                       ; [66 4f] jr Z,0x29ba1a
	bs1b	qbc
	jr	ov, .LDIV_b9d5
	add	a, 0x10
	jr t, .LDIV_b9d7                       ; [68 02] jr T,0x29b9d7
.LDIV_b9d5:
	bs1b16 bc		; bs1b A,BC
.LDIV_b9d7:
	ld	hl, 0:i3
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
	ld	a, 0x17:opc
	sub a, l		; sub A,L
	cp	a, 0x10
	jr lt, .LDIV_ba14                      ; [61 0a] jr LT,0x29ba14
	ld	qbc, bc
	ld	bc, 0:i3
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
HDAE5000_FloatToDouble:
	; *(double *)XWA = (double)*(float *)XBC: Float_Unpack, widen the
	; mantissa by three right shifts into a high/low pair, Double_Pack.
	push xiz
	lda	xsp, (xsp-12)
	ld	xiz, xwa
	ld	xwa, xsp
	call HDAE5000_Float_Unpack
	cp	l, 0:i3
	jr nz, .LDIV_ba56                      ; [6e 26] jr NZ,0x29ba56
	ld xhl, (xsp + 0x04)                    ; ld XHL,(XSP+0x04)
	ld	xde, 0:i3
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
	call HDAE5000_Double_Pack
	lda	xsp, (xsp+12)
	pop xiz                                 ; pop XIZ
	ret

	nop                                     ; nop
HDAE5000_Unpacked_Div:
	; (XWA) /= (XBC) on the internal form: exponents subtracted, signs
	; XORed, mantissas divided four quotient bits per pass; special
	; classes go to HDAE5000_FloatDiv_Special.
	ld	e, (xwa+2)
	or	e, (xwa+2)
	jp	nz, (HDAE5000_FloatDiv_Special:24)
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
	ld	xhl, 0:i3
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

; ----------------------------------------------------------------------------
; Registered-object name pool  (0x29bafc - 0x29bfdf)
;
; NUL-terminated ASCII names published to the main-CPU UI framework.  Every
; string here is the target of a pointer in HDAE5000_ObjName_Table (the .data
; image at HDAE5000_Init_Data), so the framework can resolve a handler, a
; bitmap or a screen by name.  The pool is laid out in reverse table order.
;
; This region used to be decoded as TLCS-900 instructions (.LDIV_* labels);
; the "code" was the ASCII of these names.
;
; NOTE: the pool continues past the end of this file - the include boundary at
; 0x29bfe0 falls INSIDE the string "en_paradraw", whose last six characters are
; the first bytes of HDAE5000_UI_Config in hdae5000_data_tables.s.
; ----------------------------------------------------------------------------
HDAE5000_Str_End_ObjNames:
	.zero 2
HDAE5000_Str_LyricBackColorCheck:
	.asciz "LyricBackColorCheck"
HDAE5000_Str_LyricForeColorCheck:
	.asciz "LyricForeColorCheck"
HDAE5000_Str_LyricJumpEditCheck:
	.asciz "LyricJumpEditCheck"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_BitmapButt01:
	.asciz "BitmapButt01"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_LanguageTextReturn:
	.asciz "LanguageTextReturn"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_ErrMsgTimerCatchLBN:
	.asciz "ErrMsgTimerCatchLBN"
HDAE5000_Str_ErrMsgTimerCatch:
	.asciz "ErrMsgTimerCatch"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_SeparateBassPartCheck:
	.asciz "SeparateBassPartCheck"
HDAE5000_Str_SeparateDrumPartCheck:
	.asciz "SeparateDrumPartCheck"
HDAE5000_Str_FlsOverWrSwCatch:
	.asciz "FlsOverWrSwCatch"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_FlsDel2SwCatch:
	.asciz "FlsDel2SwCatch"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_FlsDel1SwCatch:
	.asciz "FlsDel1SwCatch"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_AttenCpToMarkSwCatch:
	.asciz "AttenCpToMarkSwCatch"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_AttenCpToHDSwCatch:
	.asciz "AttenCpToHDSwCatch"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_AttenHDFormatSwCatch:
	.asciz "AttenHDFormatSwCatch"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_AttenDelFileSwCatch:
	.asciz "AttenDelFileSwCatch"
HDAE5000_Str_AttenDelDirSwCatch:
	.asciz "AttenDelDirSwCatch"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_FlsFileLoadSwCatch:
	.asciz "FlsFileLoadSwCatch"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_LBNMdBitCheck:
	.asciz "LBNMdBitCheck"
HDAE5000_Str_LBNRcmBitCheck:
	.asciz "LBNRcmBitCheck"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_LBNMspBitCheck:
	.asciz "LBNMspBitCheck"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_LBNTmBitCheck:
	.asciz "LBNTmBitCheck"
HDAE5000_Str_LBNCmpBitCheck:
	.asciz "LBNCmpBitCheck"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_LBNSqtBitCheck:
	.asciz "LBNSqtBitCheck"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_LBNPmtBitCheck:
	.asciz "LBNPmtBitCheck"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_LBNLswBitCheck:
	.asciz "LBNLswBitCheck"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_FileLBNNameCheck:
	.asciz "FileLBNNameCheck"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_LBNLoadSwCatch:
	.asciz "LBNLoadSwCatch"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_LBNPage1SwCatch:
	.asciz "LBNPage1SwCatch"
HDAE5000_Str_BitmapHdd_icon:
	.asciz "BitmapHdd_icon"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_DelTlxEditCheck:
	.asciz "DelTlxEditCheck"
HDAE5000_Str_DelMdEditCheck:
	.asciz "DelMdEditCheck"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_DelRcmEditCheck:
	.asciz "DelRcmEditCheck"
HDAE5000_Str_DelMspEditCheck:
	.asciz "DelMspEditCheck"
HDAE5000_Str_DelTmEditCheck:
	.asciz "DelTmEditCheck"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_DelCmpEditCheck:
	.asciz "DelCmpEditCheck"
HDAE5000_Str_DelSqtEditCheck:
	.asciz "DelSqtEditCheck"
HDAE5000_Str_DelPmtEditCheck:
	.asciz "DelPmtEditCheck"
HDAE5000_Str_DelLswEditCheck:
	.asciz "DelLswEditCheck"
HDAE5000_Str_DelOptNameCheck:
	.asciz "DelOptNameCheck"
HDAE5000_Str_DelOptSwEventCatch:
	.asciz "DelOptSwEventCatch"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_SaveOptSwEventCatch:
	.asciz "SaveOptSwEventCatch"
HDAE5000_Str_WrConfirmEventCatch:
	.asciz "WrConfirmEventCatch"
HDAE5000_Str_CP_FD_DIRNAMECheck:
	.asciz "CP_FD_DIRNAMECheck"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_FlsNamingCheck2:
	.asciz "FlsNamingCheck2"
HDAE5000_Str_FlsNamingCheck:
	.asciz "FlsNamingCheck"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_HdTitleEventCatch:
	.asciz "HdTitleEventCatch"
HDAE5000_Str_JumpAfterLoadModeEditCheck:
	.asciz "JumpAfterLoadModeEditCheck"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_LoadByNumberModeEditCheck:
	.asciz "LoadByNumberModeEditCheck"
HDAE5000_Str_QuickLoadModeEditCheck:
	.asciz "QuickLoadModeEditCheck"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_WriteConfirmEditCheck:
	.asciz "WriteConfirmEditCheck"
HDAE5000_Str_WriteProtectEditCheck:
	.asciz "WriteProtectEditCheck"
HDAE5000_Str_SfxTlxBitCheck:
	.asciz "SfxTlxBitCheck"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_SfxMdBitCheck:
	.asciz "SfxMdBitCheck"
HDAE5000_Str_SfxRcmBitCheck:
	.asciz "SfxRcmBitCheck"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_SfxMspBitCheck:
	.asciz "SfxMspBitCheck"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_SfxTmBitCheck:
	.asciz "SfxTmBitCheck"
HDAE5000_Str_SfxCmpBitCheck:
	.asciz "SfxCmpBitCheck"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_SfxSqtBitCheck:
	.asciz "SfxSqtBitCheck"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_SfxPmtBitCheck:
	.asciz "SfxPmtBitCheck"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_SfxLswBitCheck:
	.asciz "SfxLswBitCheck"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_FileOptNameCheck:
	.asciz "FileOptNameCheck"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_SaveOptNameCheck:
	.asciz "SaveOptNameCheck"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_SeparateOutputModeCheck:
	.asciz "SeparateOutputModeCheck"
HDAE5000_Str_PC_DATA_LINK_PAGE:
	.asciz "PC_DATA_LINK_PAGE"
HDAE5000_Str_HDD_UTIL_PAGE:
	.asciz "HDD_UTIL_PAGE"
HDAE5000_Str_HDD_DIRNAMECheck:
	.asciz "HDD_DIRNAMECheck"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_HDDNamingCheck:
	.asciz "HDDNamingCheck"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_HardTestPage:
	.asciz "HardTestPage"
	.byte 0x00
HDAE5000_ParamStr_ListBox_End:
	.zero 2
HDAE5000_ParamStr_ListBox_sel_type:
	.asciz "sel_type"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_ParamStr_ListBox_en_paradraw:
	.ascii "en_par"
