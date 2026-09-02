; ==============================================================================
; Technics SX-WSA1R -- prom_c (CPU 2, IC28) -- 0xFC8BB2-0xFCC53E  the math library: double routines, the runtime, the pools
; ==============================================================================
;
; 5,743 lines moved out of prom_c/wsa1_prom_c.s by notes/prom_c_split.py.  The master
; `.include`s this file at the line the block started on, so the assembler
; sees the same token stream in the same order and the ROM is unchanged:
;
;     python3 scripts/analysis/assert_byte_identical.py    <- the bytes
;     python3 notes/prom_c_split.py --verify               <- the text
;
; ★ EVERY LINE BELOW THIS HEADER IS VERBATIM.  Nothing was reworded, and
;   --verify fails on a single changed character.
;
; WHY THIS IS ONE SUBJECT:
; Three adjacent banners, one subject, and the top one says so: the block at
; 0xFC8BB2 is `the DOUBLE-PRECISION MATH LIBRARY that sits on top of the
; runtime converted just below`.  Then the compiler runtime itself (the
; complete IEEE-754 single and double set, 32-bit multiply/divide, the
; variable shifts) and the 77-entry f64 coefficient pool those routines
; load from.
; ★ This runtime is sub-CPU-ONLY -- prom_a/b/d define no Float32_/Double_
; label -- so unlike kernel/kernel.s it is NOT a shared-source candidate.
;
; >>> END OF EXTRACTION HEADER -- everything below is verbatim from the master

; ==============================================================================
; 0xFC8BB2-0xFCA0B9 -- not yet converted
; ==============================================================================
; ⚠ WHAT THIS IS, AND WHY IT IS LEFT.  It decodes cleanly and contiguously as
; 5,384 bytes of code -- about twenty routines -- and it is the DOUBLE-PRECISION
; MATH LIBRARY that sits on top of the runtime converted just below: its routines
; take arguments in the 64-bit pairs (XIZ+0x08)/(XIZ+0x0C), call Double_Add,
; Double_Multiply, Double_Divide, Double_Compare and Double_Negate, and load
; 64-bit constants out of the pool at 0xFCB27E.  The first of them, 0xFC8BB2,
; loads pi/2 (0xFCB27E), 1.0 (0xFCB286) and 0.0 (0xFCB28E) and is called from
; four sites in prom_c.
; Naming these needs the constant pool decoded first, and that is the next
; round's work, not a guess for this one.

; ==============================================================================
; 0xFC8BB2-0xFCA0B9 -- 12 routines, 0 computed-goto arm(s), 0 table(s), 5,384 bytes
; ==============================================================================
;
; Boundaries, read off the bytes rather than asserted:
;   0xFC8BB1 = 0x0E (`ret`)   0xFC8BB2 = EE 0C (`link XIZ`)
;   0xFCA0B9 = 0x0E (`ret`)   0xFCA0BA = 9F 04 (NOT a `link XIZ` prologue)
;   ⚠ A `ret`/`link` pair at a cut is evidence the cut falls between
;   routines; anything else on those lines is a cut that needs reading.
;
; Call census (`python3 notes/prom_c_module_map.py 0xFC8BB2 0xFCA0BA`):
;   57 literal call site(s) from outside this block, 15 from inside it.
;         18  sub_FA000B
;         13  sub_F9BE3A
;         10  sub_F9ECF1
;          6  sub_F9B887
;          4  sub_F9E1ED
;          3  sub_F9B5A5
;          3  (caller not yet converted)
;   ⚠ Sites in code that is still `.incbin` are counted under
;   "(caller not yet converted)"; that row shrinks as conversion proceeds,
;   so every named row is a FLOOR.
;
; No computed-goto table: `python3 notes/prom_c_jumptables.py 0xFC8BB2 0xFCA0BA`
;   prints none, so the whole range is decoded linearly.
;
; ★ DECODE ALIGNMENT.  notes/gen_prom_c_block.py requires every
;   call/calr/jp/jrl/jr target that a DECODED INSTRUCTION in this file names
;   and that lands inside this range to be the start of a listing line.  A
;   byte round trip cannot show that -- a misaligned decode of data can
;   re-encode to the same bytes -- so this is the test that says the listing
;   was read at the right offsets, and it is what found the BC-form jump
;   table at 0xFAF08F that the table scanner had missed.
;
; ⚠ NO ROUTINE HERE IS NAMED FOR WHAT IT DOES.  Each header states the frame
;   size, the argument slots read, the absolute addresses read and written,
;   the routines called and the call sites -- operands and decoded-instruction
;   scans, nothing interpreted.
;
; ★ REGENERATE:
;     python3 notes/gen_prom_c_block.py --start 0xFC8BB2 --end 0xFCA0BA > /tmp/b.s
;     python3 notes/gen_prom_c_block_headers.py --start 0xFC8BB2 --end 0xFCA0BA \
;         --labels > /tmp/b.labels
;     python3 notes/gen_prom_c_block_headers.py --start 0xFC8BB2 --end 0xFCA0BA \
;         --headers > /tmp/b.headers
;     python3 notes/prom_c_apply_headers.py /tmp/b.s /tmp/b.labels \
;         /tmp/b.headers > /tmp/b.final.s
;     python3 notes/prom_c_verify_fragment.py c 0xFC8BB2 /tmp/b.final.s
; ==============================================================================
; --------------------------------------------------------------------------
; sub_FC8BB2 -- 0xFC8BB2..0xFC8C44 (147 bytes)
;
; Called from: 4 site(s) outside this module:
;          0xF9EE4A in sub_F9ECF1__F9ED7A, 0xF9EFD3 in sub_F9ECF1__F9EFA0
;          0xF9F305 in sub_F9ECF1__F9F235, 0xF9F48E in sub_F9ECF1__F9F45B
; Inputs:  frame `link XIZ,-16`; argument slots read: (XIZ+0x08), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
;          reads 0xFCB27E, 0xFCB282, 0xFCB286, 0xFCB28A, 0xFCB28E, 0xFCB292
; Calls:   0xFC8C45 = sub_FC8C45, 0xFCA121 = Double_Compare
;          0xFCA1B6 = Double_Negate, 0xFCA1E5 = Double_Classify
;          0xFCA41F = Double_Add
; Evidence: the listing below is the byte-identical round-trip of 0xFC8BB2-0xFC8C44
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC8BB2:
	link32 0xEE, 0x0C, 0xF0, 0xFF              ; FC8BB2  link XIZ,0xfff0
	push	xix                                   ; FC8BB6  push XIX
	push	xiy                                   ; FC8BB7  push XIY
	ld	xbc, (xiz+12)                           ; FC8BB8  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC8BBB  push XBC
	ld	xbc, (xiz+8)                            ; FC8BBC  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC8BBF  push XBC
	call	0xFCA1E5                              ; FC8BC0  call 0xfca1e5
	cps	wa, 0                                  ; FC8BC4  cp WA,0
	jr nz, sub_FC8BB2__FC8BDC                  ; FC8BC6  jr NZ,0xfc8bdc
	ld	xiy, (xsp)                              ; FC8BC8  ld XIY,(XSP)
	ld	xix, (0xFCB286:24)                     ; FC8BCA  ld XIX,(0xfcb286)
	stl_dpi	xix, 0xF6                          ; FC8BCF  ld (XIY+),XIX
	ld	xix, (0xFCB28A:24)                     ; FC8BD2  ld XIX,(0xfcb28a)
	ld	(xiy), xix                              ; FC8BD7  ld (XIY),XIX
	jrl sub_FC8BB2__FC8C40                     ; FC8BD9  jrl T,0xfc8c40
sub_FC8BB2__FC8BDC:
	ld	xbc, (0xFCB292:24)                     ; FC8BDC  ld XBC,(0xfcb292)
	push	xbc                                   ; FC8BE1  push XBC
	ld	xbc, (0xFCB28E:24)                     ; FC8BE2  ld XBC,(0xfcb28e)
	push	xbc                                   ; FC8BE7  push XBC
	ld	xbc, (xiz+12)                           ; FC8BE8  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC8BEB  push XBC
	ld	xbc, (xiz+8)                            ; FC8BEC  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC8BEF  push XBC
	call	0xFCA121                              ; FC8BF0  call 0xfca121
	cps	wa, 2                                  ; FC8BF4  cp WA,2
	jr nz, sub_FC8BB2__FC8C07                  ; FC8BF6  jr NZ,0xfc8c07
	ld	xbc, (xiz+12)                           ; FC8BF8  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC8BFB  push XBC
	ld	xbc, (xiz+8)                            ; FC8BFC  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC8BFF  push XBC
	lda	xiy, (xiz+8)                           ; FC8C00  lda XIY,XIZ+0x08
	call	0xFCA1B6                              ; FC8C03  call 0xfca1b6
sub_FC8BB2__FC8C07:
	ld	xbc, (0xFCB282:24)                     ; FC8C07  ld XBC,(0xfcb282)
	push	xbc                                   ; FC8C0C  push XBC
	ld	xbc, (0xFCB27E:24)                     ; FC8C0D  ld XBC,(0xfcb27e)
	push	xbc                                   ; FC8C12  push XBC
	ld	xbc, (xiz+12)                           ; FC8C13  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC8C16  push XBC
	ld	xbc, (xiz+8)                            ; FC8C17  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC8C1A  push XBC
	lda	xiy, (xiz-8)                           ; FC8C1B  lda XIY,XIZ+0xf8
	call	0xFCA41F                              ; FC8C1E  call 0xfca41f
	ld	xbc, (xiz-4)                            ; FC8C22  ld XBC,(XIZ+0xfc)
	push	xbc                                   ; FC8C25  push XBC
	ld	xbc, (xiz-8)                            ; FC8C26  ld XBC,(XIZ+0xf8)
	push	xbc                                   ; FC8C29  push XBC
	lda	xiy, (xiz-16)                          ; FC8C2A  lda XIY,XIZ+0xf0
	call	0xFC8C45                              ; FC8C2D  call 0xfc8c45
	inc	8, xsp                                 ; FC8C31  inc 0,XSP
	ld	xiy, (xsp)                              ; FC8C33  ld XIY,(XSP)
	ld	xix, (xiz-16)                           ; FC8C35  ld XIX,(XIZ+0xf0)
	stl_dpi	xix, 0xF6                          ; FC8C38  ld (XIY+),XIX
	ld	xix, (xiz-12)                           ; FC8C3B  ld XIX,(XIZ+0xf4)
	ld	(xiy), xix                              ; FC8C3E  ld (XIY),XIX
sub_FC8BB2__FC8C40:
	pop	xiy                                    ; FC8C40  pop XIY
	pop	xix                                    ; FC8C41  pop XIX
	unlk32 xiz                                 ; FC8C42  unlk XIZ
	ret                                        ; FC8C44  ret
; --------------------------------------------------------------------------
; sub_FC8C45 -- 0xFC8C45..0xFC8EE4 (672 bytes)
;
; Called from: 4 site(s) outside this module:
;          0xF9EE83 in sub_F9ECF1__F9ED7A, 0xF9F00C in sub_F9ECF1__F9EFA0
;          0xF9F33E in sub_F9ECF1__F9F235, 0xF9F4C7 in sub_F9ECF1__F9F45B
;          1 site(s) inside this module:
;          0xFC8C2D
; Inputs:  frame `link XIZ,-48`; argument slots read: (XIZ+0x08), (XIZ+0x0C)
; Outputs: writes 0x00F362
;          reads 0xFCB296, 0xFCB29A, 0xFCB29E, 0xFCB2A2, 0xFCB2A6, 0xFCB2AA, 0xFCB2AE, 0xFCB2B2, 0xFCB2B6, 0xFCB2BA, 0xFCB2BE, 0xFCB2C2, 0xFCB2C6, 0xFCB2CA
; Calls:   0xFC8EE5 = sub_FC8EE5, 0xFCA121 = Double_Compare
;          0xFCA1B6 = Double_Negate, 0xFCA1E5 = Double_Classify
;          0xFCA252 = Double_Multiply, 0xFCA41F = Double_Add
;          0xFCA626 = Double_Subtract
; Evidence: the listing below is the byte-identical round-trip of 0xFC8C45-0xFC8EE4
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC8C45:
	link32 0xEE, 0x0C, 0xD0, 0xFF              ; FC8C45  link XIZ,0xffd0
	pushw	hl                                   ; FC8C49  push HL
	push	xix                                   ; FC8C4A  push XIX
	push	xiy                                   ; FC8C4B  push XIY
	ldb	h, 0                                   ; FC8C4C  ld H,0x00
	ld	xbc, (0xFCB2CA:24)                     ; FC8C4E  ld XBC,(0xfcb2ca)
	push	xbc                                   ; FC8C53  push XBC
	ld	xbc, (0xFCB2C6:24)                     ; FC8C54  ld XBC,(0xfcb2c6)
	push	xbc                                   ; FC8C59  push XBC
	ld	xbc, (xiz+12)                           ; FC8C5A  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC8C5D  push XBC
	ld	xbc, (xiz+8)                            ; FC8C5E  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC8C61  push XBC
	call	0xFCA121                              ; FC8C62  call 0xfca121
	cps	wa, 2                                  ; FC8C66  cp WA,2
	jr nz, sub_FC8C45__FC8C6C                  ; FC8C68  jr NZ,0xfc8c6c
	ldb	h, 1                                   ; FC8C6A  ld H,0x01
sub_FC8C45__FC8C6C:
	ld	l, h                                    ; FC8C6C  ld L,H
	cps	h, 0                                   ; FC8C6E  cp H,0
	jr z, sub_FC8C45__FC8C81                   ; FC8C70  jr Z,0xfc8c81
	ld	xbc, (xiz+12)                           ; FC8C72  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC8C75  push XBC
	ld	xbc, (xiz+8)                            ; FC8C76  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC8C79  push XBC
	lda	xiy, (xiz+8)                           ; FC8C7A  lda XIY,XIZ+0x08
	call	0xFCA1B6                              ; FC8C7D  call 0xfca1b6
sub_FC8C45__FC8C81:
	ld	xbc, (0xFCB2C2:24)                     ; FC8C81  ld XBC,(0xfcb2c2)
	push	xbc                                   ; FC8C86  push XBC
	ld	xbc, (0xFCB2BE:24)                     ; FC8C87  ld XBC,(0xfcb2be)
	push	xbc                                   ; FC8C8C  push XBC
	ld	xbc, (xiz+12)                           ; FC8C8D  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC8C90  push XBC
	ld	xbc, (xiz+8)                            ; FC8C91  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC8C94  push XBC
	call	0xFCA121                              ; FC8C95  call 0xfca121
	cps	wa, 1                                  ; FC8C99  cp WA,1
	jr nz, sub_FC8C45__FC8CB8                  ; FC8C9B  jr NZ,0xfc8cb8
	ldw	(0xF362:24), 34                       ; FC8C9D  ld (0x00f362),0x0022
	ld	xiy, (xsp)                              ; FC8CA4  ld XIY,(XSP)
	ld	xix, (0xFCB2C6:24)                     ; FC8CA6  ld XIX,(0xfcb2c6)
	stl_dpi	xix, 0xF6                          ; FC8CAB  ld (XIY+),XIX
	ld	xix, (0xFCB2CA:24)                     ; FC8CAE  ld XIX,(0xfcb2ca)
	ld	(xiy), xix                              ; FC8CB3  ld (XIY),XIX
	jrl sub_FC8C45__FC8EDF                     ; FC8CB5  jrl T,0xfc8edf
sub_FC8C45__FC8CB8:
	ld	xbc, (0xFCB2BA:24)                     ; FC8CB8  ld XBC,(0xfcb2ba)
	push	xbc                                   ; FC8CBD  push XBC
	ld	xbc, (0xFCB2B6:24)                     ; FC8CBE  ld XBC,(0xfcb2b6)
	push	xbc                                   ; FC8CC3  push XBC
	ld	xbc, (xiz+12)                           ; FC8CC4  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC8CC7  push XBC
	ld	xbc, (xiz+8)                            ; FC8CC8  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC8CCB  push XBC
	call	0xFCA121                              ; FC8CCC  call 0xfca121
	cps	wa, 1                                  ; FC8CD0  cp WA,1
	jr nz, sub_FC8C45__FC8CDB                  ; FC8CD2  jr NZ,0xfc8cdb
	ldw	(0xF362:24), 34                       ; FC8CD4  ld (0x00f362),0x0022
sub_FC8C45__FC8CDB:
	lda	xbc, (xiz-8)                           ; FC8CDB  lda XBC,XIZ+0xf8
	push	xbc                                   ; FC8CDE  push XBC
	ld	xwa, (xiz+12)                           ; FC8CDF  ld XWA,(XIZ+0x0c)
	push	xwa                                   ; FC8CE2  push XWA
	ld	xwa, (xiz+8)                            ; FC8CE3  ld XWA,(XIZ+0x08)
	push	xwa                                   ; FC8CE6  push XWA
	ld	xwa, (0xFCB2B2:24)                     ; FC8CE7  ld XWA,(0xfcb2b2)
	push	xwa                                   ; FC8CEC  push XWA
	ld	xwa, (0xFCB2AE:24)                     ; FC8CED  ld XWA,(0xfcb2ae)
	push	xwa                                   ; FC8CF2  push XWA
	lda	xiy, (xiz-24)                          ; FC8CF3  lda XIY,XIZ+0xe8
	call	0xFCA252                              ; FC8CF6  call 0xfca252
	ld	xbc, (0xFCB2AA:24)                     ; FC8CFA  ld XBC,(0xfcb2aa)
	push	xbc                                   ; FC8CFF  push XBC
	ld	xbc, (0xFCB2A6:24)                     ; FC8D00  ld XBC,(0xfcb2a6)
	push	xbc                                   ; FC8D05  push XBC
	ld	xbc, (xiz-20)                           ; FC8D06  ld XBC,(XIZ+0xec)
	push	xbc                                   ; FC8D09  push XBC
	ld	xbc, (xiz-24)                           ; FC8D0A  ld XBC,(XIZ+0xe8)
	push	xbc                                   ; FC8D0D  push XBC
	lda	xiy, (xiz-32)                          ; FC8D0E  lda XIY,XIZ+0xe0
	call	0xFCA41F                              ; FC8D11  call 0xfca41f
	ld	xbc, (xiz-28)                           ; FC8D15  ld XBC,(XIZ+0xe4)
	push	xbc                                   ; FC8D18  push XBC
	ld	xbc, (xiz-32)                           ; FC8D19  ld XBC,(XIZ+0xe0)
	push	xbc                                   ; FC8D1C  push XBC
	lda	xiy, (xiz+8)                           ; FC8D1D  lda XIY,XIZ+0x08
	call	0xFC8EE5                              ; FC8D20  call 0xfc8ee5
	lda	xbc, (xiz-8)                           ; FC8D24  lda XBC,XIZ+0xf8
	push	xbc                                   ; FC8D27  push XBC
	add	xbc, 8                                 ; FC8D28  add XBC,0x00000008
	extpfx3 0xD4, 0xE5, 0x04                   ; FC8D2E  pushw (-XBC)
	extpfx3 0xD4, 0xE5, 0x04                   ; FC8D31  pushw (-XBC)
	extpfx3 0xD4, 0xE5, 0x04                   ; FC8D34  pushw (-XBC)
	extpfx2 0x91, 0x04                         ; FC8D37  pushw (XBC)
	ld	xwa, (0xFCB2AA:24)                     ; FC8D39  ld XWA,(0xfcb2aa)
	push	xwa                                   ; FC8D3E  push XWA
	ld	xwa, (0xFCB2A6:24)                     ; FC8D3F  ld XWA,(0xfcb2a6)
	push	xwa                                   ; FC8D44  push XWA
	lda	xiy, (xiz-40)                          ; FC8D45  lda XIY,XIZ+0xd8
	call	0xFCA252                              ; FC8D48  call 0xfca252
	ld	xbc, (xiz-36)                           ; FC8D4C  ld XBC,(XIZ+0xdc)
	push	xbc                                   ; FC8D4F  push XBC
	ld	xbc, (xiz-40)                           ; FC8D50  ld XBC,(XIZ+0xd8)
	push	xbc                                   ; FC8D53  push XBC
	lda	xiy, (xiz-48)                          ; FC8D54  lda XIY,XIZ+0xd0
	call	0xFC8EE5                              ; FC8D57  call 0xfc8ee5
	add	xsp, 24                                ; FC8D5B  add XSP,0x00000018
	ld	xbc, (xiz-44)                           ; FC8D61  ld XBC,(XIZ+0xd4)
	push	xbc                                   ; FC8D64  push XBC
	ld	xbc, (xiz-48)                           ; FC8D65  ld XBC,(XIZ+0xd0)
	push	xbc                                   ; FC8D68  push XBC
	call	0xFCA1E5                              ; FC8D69  call 0xfca1e5
	cps	wa, 0                                  ; FC8D6D  cp WA,0
	jr z, sub_FC8C45__FC8D75                   ; FC8D6F  jr Z,0xfc8d75
	ldb	h, 1                                   ; FC8D71  ld H,0x01
	jr sub_FC8C45__FC8D77                      ; FC8D73  jr T,0xfc8d77
sub_FC8C45__FC8D75:
	ldb	h, 0                                   ; FC8D75  ld H,0x00
sub_FC8C45__FC8D77:
	ld	c, h                                    ; FC8D77  ld C,H
	xor	l, c                                   ; FC8D79  xor L,C
	ld	xbc, (0xFCB2AA:24)                     ; FC8D7B  ld XBC,(0xfcb2aa)
	push	xbc                                   ; FC8D80  push XBC
	ld	xbc, (0xFCB2A6:24)                     ; FC8D81  ld XBC,(0xfcb2a6)
	push	xbc                                   ; FC8D86  push XBC
	ld	xbc, (xiz+12)                           ; FC8D87  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC8D8A  push XBC
	ld	xbc, (xiz+8)                            ; FC8D8B  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC8D8E  push XBC
	lda	xiy, (xiz-24)                          ; FC8D8F  lda XIY,XIZ+0xe8
	call	0xFCA626                              ; FC8D92  call 0xfca626
	ld	xbc, (xiz-20)                           ; FC8D96  ld XBC,(XIZ+0xec)
	push	xbc                                   ; FC8D99  push XBC
	ld	xbc, (xiz-24)                           ; FC8D9A  ld XBC,(XIZ+0xe8)
	push	xbc                                   ; FC8D9D  push XBC
	ld	xbc, (0xFCB2A2:24)                     ; FC8D9E  ld XBC,(0xfcb2a2)
	push	xbc                                   ; FC8DA3  push XBC
	ld	xbc, (0xFCB29E:24)                     ; FC8DA4  ld XBC,(0xfcb29e)
	push	xbc                                   ; FC8DA9  push XBC
	lda	xiy, (xiz+8)                           ; FC8DAA  lda XIY,XIZ+0x08
	call	0xFCA252                              ; FC8DAD  call 0xfca252
	ld	xbc, (0xFCB2CA:24)                     ; FC8DB1  ld XBC,(0xfcb2ca)
	push	xbc                                   ; FC8DB6  push XBC
	ld	xbc, (0xFCB2C6:24)                     ; FC8DB7  ld XBC,(0xfcb2c6)
	push	xbc                                   ; FC8DBC  push XBC
	ld	xbc, (xiz+12)                           ; FC8DBD  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC8DC0  push XBC
	ld	xbc, (xiz+8)                            ; FC8DC1  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC8DC4  push XBC
	call	0xFCA121                              ; FC8DC5  call 0xfca121
	cps	wa, 2                                  ; FC8DC9  cp WA,2
	jr nz, sub_FC8C45__FC8DDF                  ; FC8DCB  jr NZ,0xfc8ddf
	xor	l, 1                                   ; FC8DCD  xor L,0x01
	ld	xbc, (xiz+12)                           ; FC8DD0  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC8DD3  push XBC
	ld	xbc, (xiz+8)                            ; FC8DD4  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC8DD7  push XBC
	lda	xiy, (xiz+8)                           ; FC8DD8  lda XIY,XIZ+0x08
	call	0xFCA1B6                              ; FC8DDB  call 0xfca1b6
sub_FC8C45__FC8DDF:
	ld	xbc, (0xFCB29A:24)                     ; FC8DDF  ld XBC,(0xfcb29a)
	push	xbc                                   ; FC8DE4  push XBC
	ld	xbc, (0xFCB296:24)                     ; FC8DE5  ld XBC,(0xfcb296)
	push	xbc                                   ; FC8DEA  push XBC
	ld	xbc, (xiz+12)                           ; FC8DEB  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC8DEE  push XBC
	ld	xbc, (xiz+8)                            ; FC8DEF  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC8DF2  push XBC
	call	0xFCA121                              ; FC8DF3  call 0xfca121
	cps	wa, 1                                  ; FC8DF7  cp WA,1
	jrl nz, sub_FC8C45__FC8EB0                 ; FC8DF9  jrl NZ,0xfc8eb0
	ld	xbc, (xiz+12)                           ; FC8DFC  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC8DFF  push XBC
	ld	xbc, (xiz+8)                            ; FC8E00  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC8E03  push XBC
	ld	xbc, (xiz+12)                           ; FC8E04  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC8E07  push XBC
	ld	xbc, (xiz+8)                            ; FC8E08  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC8E0B  push XBC
	lda	xiy, (xiz-8)                           ; FC8E0C  lda XIY,XIZ+0xf8
	call	0xFCA252                              ; FC8E0F  call 0xfca252
	lda	xix, (xiz-16)                          ; FC8E13  lda XIX,XIZ+0xf0
	lda	xiy, (0xFCB2CE:24)                     ; FC8E16  lda XIY,0xfcb2ce
	ldw	bc, 4                                  ; FC8E1B  ld BC,0x0004
	extpfx2 0x95, 0x11                         ; FC8E1E  ldirw
	lda	xix, (0xFCB2CE:24)                     ; FC8E20  lda XIX,0xfcb2ce
	inc	8, xix                                 ; FC8E25  inc 0,XIX
	ldb	h, 7                                   ; FC8E27  ld H,0x07
sub_FC8C45__FC8E29:
	ld	xbc, (xiz-12)                           ; FC8E29  ld XBC,(XIZ+0xf4)
	push	xbc                                   ; FC8E2C  push XBC
	ld	xbc, (xiz-16)                           ; FC8E2D  ld XBC,(XIZ+0xf0)
	push	xbc                                   ; FC8E30  push XBC
	ld	xbc, (xiz-4)                            ; FC8E31  ld XBC,(XIZ+0xfc)
	push	xbc                                   ; FC8E34  push XBC
	ld	xbc, (xiz-8)                            ; FC8E35  ld XBC,(XIZ+0xf8)
	push	xbc                                   ; FC8E38  push XBC
	lda	xiy, (xiz-24)                          ; FC8E39  lda XIY,XIZ+0xe8
	call	0xFCA252                              ; FC8E3C  call 0xfca252
	push	xix                                   ; FC8E40  push XIX
	lda	xix, (xiz-32)                          ; FC8E41  lda XIX,XIZ+0xe0
	ld	xiy, (xsp)                              ; FC8E44  ld XIY,(XSP)
	ldw	bc, 4                                  ; FC8E46  ld BC,0x0004
	extpfx2 0x95, 0x11                         ; FC8E49  ldirw
	pop	xix                                    ; FC8E4B  pop XIX
	ld	xbc, (xiz-28)                           ; FC8E4C  ld XBC,(XIZ+0xe4)
	push	xbc                                   ; FC8E4F  push XBC
	ld	xbc, (xiz-32)                           ; FC8E50  ld XBC,(XIZ+0xe0)
	push	xbc                                   ; FC8E53  push XBC
	ld	xbc, (xiz-20)                           ; FC8E54  ld XBC,(XIZ+0xec)
	push	xbc                                   ; FC8E57  push XBC
	ld	xbc, (xiz-24)                           ; FC8E58  ld XBC,(XIZ+0xe8)
	push	xbc                                   ; FC8E5B  push XBC
	lda	xiy, (xiz-16)                          ; FC8E5C  lda XIY,XIZ+0xf0
	call	0xFCA41F                              ; FC8E5F  call 0xfca41f
	inc	8, xix                                 ; FC8E63  inc 0,XIX
	dec	1, h                                   ; FC8E65  dec 1,H
	cps	h, 0                                   ; FC8E67  cp H,0
	jr nz, sub_FC8C45__FC8E29                  ; FC8E69  jr NZ,0xfc8e29
	ld	xbc, (xiz+12)                           ; FC8E6B  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC8E6E  push XBC
	ld	xbc, (xiz+8)                            ; FC8E6F  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC8E72  push XBC
	ld	xbc, (xiz-4)                            ; FC8E73  ld XBC,(XIZ+0xfc)
	push	xbc                                   ; FC8E76  push XBC
	ld	xbc, (xiz-8)                            ; FC8E77  ld XBC,(XIZ+0xf8)
	push	xbc                                   ; FC8E7A  push XBC
	lda	xiy, (xiz-24)                          ; FC8E7B  lda XIY,XIZ+0xe8
	call	0xFCA252                              ; FC8E7E  call 0xfca252
	ld	xbc, (xiz-20)                           ; FC8E82  ld XBC,(XIZ+0xec)
	push	xbc                                   ; FC8E85  push XBC
	ld	xbc, (xiz-24)                           ; FC8E86  ld XBC,(XIZ+0xe8)
	push	xbc                                   ; FC8E89  push XBC
	ld	xbc, (xiz-12)                           ; FC8E8A  ld XBC,(XIZ+0xf4)
	push	xbc                                   ; FC8E8D  push XBC
	ld	xbc, (xiz-16)                           ; FC8E8E  ld XBC,(XIZ+0xf0)
	push	xbc                                   ; FC8E91  push XBC
	lda	xiy, (xiz-32)                          ; FC8E92  lda XIY,XIZ+0xe0
	call	0xFCA252                              ; FC8E95  call 0xfca252
	ld	xbc, (xiz-28)                           ; FC8E99  ld XBC,(XIZ+0xe4)
	push	xbc                                   ; FC8E9C  push XBC
	ld	xbc, (xiz-32)                           ; FC8E9D  ld XBC,(XIZ+0xe0)
	push	xbc                                   ; FC8EA0  push XBC
	ld	xbc, (xiz+12)                           ; FC8EA1  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC8EA4  push XBC
	ld	xbc, (xiz+8)                            ; FC8EA5  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC8EA8  push XBC
	lda	xiy, (xiz+8)                           ; FC8EA9  lda XIY,XIZ+0x08
	call	0xFCA41F                              ; FC8EAC  call 0xfca41f
sub_FC8C45__FC8EB0:
	cps	l, 0                                   ; FC8EB0  cp L,0
	jr z, sub_FC8C45__FC8ED2                   ; FC8EB2  jr Z,0xfc8ed2
	ld	xbc, (xiz+12)                           ; FC8EB4  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC8EB7  push XBC
	ld	xbc, (xiz+8)                            ; FC8EB8  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC8EBB  push XBC
	lda	xiy, (xiz-24)                          ; FC8EBC  lda XIY,XIZ+0xe8
	call	0xFCA1B6                              ; FC8EBF  call 0xfca1b6
	ld	xiy, (xsp)                              ; FC8EC3  ld XIY,(XSP)
	ld	xix, (xiz-24)                           ; FC8EC5  ld XIX,(XIZ+0xe8)
	stl_dpi	xix, 0xF6                          ; FC8EC8  ld (XIY+),XIX
	ld	xix, (xiz-20)                           ; FC8ECB  ld XIX,(XIZ+0xec)
	ld	(xiy), xix                              ; FC8ECE  ld (XIY),XIX
	jr sub_FC8C45__FC8EDF                      ; FC8ED0  jr T,0xfc8edf
sub_FC8C45__FC8ED2:
	ld	xiy, (xsp)                              ; FC8ED2  ld XIY,(XSP)
	ld	xix, (xiz+8)                            ; FC8ED4  ld XIX,(XIZ+0x08)
	stl_dpi	xix, 0xF6                          ; FC8ED7  ld (XIY+),XIX
	ld	xix, (xiz+12)                           ; FC8EDA  ld XIX,(XIZ+0x0c)
	ld	(xiy), xix                              ; FC8EDD  ld (XIY),XIX
sub_FC8C45__FC8EDF:
	pop	xiy                                    ; FC8EDF  pop XIY
	pop	xix                                    ; FC8EE0  pop XIX
	popw	hl                                    ; FC8EE1  pop HL
	unlk32 xiz                                 ; FC8EE2  unlk XIZ
	ret                                        ; FC8EE4  ret
; --------------------------------------------------------------------------
; sub_FC8EE5 -- 0xFC8EE5..0xFC913F (603 bytes)
;
; Called from: no site outside this module.
;          5 site(s) inside this module:
;          0xFC8D20 0xFC8D57 0xFC930A 0xFC9377 0xFC9678
; Inputs:  frame `link XIZ,-32`; argument slots read: (XIZ+0x10)
; Outputs: no absolute-addressed write.
;          reads 0xFCB30E, 0xFCB312
; Calls:   0xFCA0DB = Shift32_LogicalRight, 0xFCA0FE = Shift32_Left
; Evidence: the listing below is the byte-identical round-trip of 0xFC8EE5-0xFC913F
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC8EE5:
	link32 0xEE, 0x0C, 0xE0, 0xFF              ; FC8EE5  link XIZ,0xffe0
	pushw	hl                                   ; FC8EE9  push HL
	pushw	de                                   ; FC8EEA  push DE
	push	xix                                   ; FC8EEB  push XIX
	push	xiy                                   ; FC8EEC  push XIY
	lda	xix, (xiz-12)                          ; FC8EED  lda XIX,XIZ+0xf4
	lda	xiy, (xiz+8)                           ; FC8EF0  lda XIY,XIZ+0x08
	ldw	bc, 4                                  ; FC8EF3  ld BC,0x0004
	extpfx2 0x95, 0x11                         ; FC8EF6  ldirw
	ld	xix, (xiz+16)                           ; FC8EF8  ld XIX,(XIZ+0x10)
	lda	xiy, (xiz+8)                           ; FC8EFB  lda XIY,XIZ+0x08
	ldw	bc, 4                                  ; FC8EFE  ld BC,0x0004
	extpfx2 0x95, 0x11                         ; FC8F01  ldirw
	sub	xbc, xbc                               ; FC8F03  sub XBC,XBC
	ld	(xiz-16), xbc                           ; FC8F05  ld (XIZ+0xf0),XBC
	sub	xwa, xwa                               ; FC8F08  sub XWA,XWA
	ld	(xiz-20), xwa                           ; FC8F0A  ld (XIZ+0xec),XWA
	ldb	e, 7                                   ; FC8F0D  ld E,0x07
sub_FC8EE5__FC8F0F:
	ld	xix, (xiz-20)                           ; FC8F0F  ld XIX,(XIZ+0xec)
	sll	xix, 8                                 ; FC8F12  sll 0x08,XIX
	ld	c, e                                    ; FC8F15  ld C,E
	exts	bc                                    ; FC8F17  exts BC
	exts	xbc                                   ; FC8F19  exts XBC
	ld	(xiz-28), xbc                           ; FC8F1B  ld (XIZ+0xe4),XBC
	add	xbc, xiz                               ; FC8F1E  add XBC,XIZ
	ld	a, (xbc-12)                             ; FC8F20  ld A,(XBC+0xf4)
	extz	wa                                    ; FC8F23  extz WA
	extz	xwa                                   ; FC8F25  extz XWA
	or	xwa, xix                                ; FC8F27  or XWA,XIX
	ld	(xiz-20), xwa                           ; FC8F29  ld (XIZ+0xec),XWA
	ld	xix, (xiz-16)                           ; FC8F2C  ld XIX,(XIZ+0xf0)
	sll	xix, 8                                 ; FC8F2F  sll 0x08,XIX
	ld	xbc, (xiz-28)                           ; FC8F32  ld XBC,(XIZ+0xe4)
	dec	4, xbc                                 ; FC8F35  dec 4,XBC
	add	xbc, xiz                               ; FC8F37  add XBC,XIZ
	ld	a, (xbc-12)                             ; FC8F39  ld A,(XBC+0xf4)
	extz	wa                                    ; FC8F3C  extz WA
	extz	xwa                                   ; FC8F3E  extz XWA
	or	xwa, xix                                ; FC8F40  or XWA,XIX
	ld	(xiz-16), xwa                           ; FC8F42  ld (XIZ+0xf0),XWA
	dec	1, e                                   ; FC8F45  dec 1,E
	cps	e, 3                                   ; FC8F47  cp E,3
	jr gt, sub_FC8EE5__FC8F0F                  ; FC8F49  jr GT,0xfc8f0f
	ld	xix, (xiz-20)                           ; FC8F4B  ld XIX,(XIZ+0xec)
	ld	(xiz-24), xwa                           ; FC8F4E  ld (XIZ+0xe8),XWA
	ld	xbc, (xiz-20)                           ; FC8F51  ld XBC,(XIZ+0xec)
	and	xbc, 0x7FFFFFFF                        ; FC8F54  and XBC,0x7fffffff
	extpfx3 0xAE, 0xF0, 0xE1                   ; FC8F5A  or XBC,(XIZ+0xf0)
	jrl z, sub_FC8EE5__FC9054                  ; FC8F5D  jrl Z,0xfc9054
	pushw	31                                   ; FC8F60  push 0x001f
	push	xix                                   ; FC8F63  push XIX
	call	0xFCA0DB                              ; FC8F64  call 0xfca0db
	extpfx3 0xC7, 0xF4, 0x8C                   ; FC8F68  ld D,IYL
	ld	xiy, xix                                ; FC8F6B  ld XIY,XIX
	srl	xiy, 0                                 ; FC8F6D  srl 0x00,XIY
	ld	hl, iy                                  ; FC8F70  ld HL,IY
	add	iy, iy                                 ; FC8F72  add IY,IY
	ld	hl, iy                                  ; FC8F74  ld HL,IY
	srl	iy, 5                                  ; FC8F76  srl 0x05,IY
	ld	hl, iy                                  ; FC8F79  ld HL,IY
	cp	iy, 0x3FF                               ; FC8F7B  cp IY,0x03ff
	jr nc, sub_FC8EE5__FC8F91                  ; FC8F7F  jr NC,0xfc8f91
	ld	xix, (xiz+16)                           ; FC8F81  ld XIX,(XIZ+0x10)
	lda	xiy, (0xFCB30E:24)                     ; FC8F84  lda XIY,0xfcb30e
	ldw	bc, 4                                  ; FC8F89  ld BC,0x0004
	extpfx2 0x95, 0x11                         ; FC8F8C  ldirw
	jrl sub_FC8EE5__FC9121                     ; FC8F8E  jrl T,0xfc9121
sub_FC8EE5__FC8F91:
	cp	hl, 0x432                               ; FC8F91  cp HL,0x0432
	jrl ugt, sub_FC8EE5__FC9054                ; FC8F95  jrl UGT,0xfc9054
	ld	bc, hl                                  ; FC8F98  ld BC,HL
	sub	bc, 0x3FF                              ; FC8F9A  sub BC,0x03ff
	ld	(xiz-26), bc                            ; FC8F9E  ld (XIZ+0xe6),BC
	ldw	hl, 52                                 ; FC8FA1  ld HL,0x0034
	sub	hl, bc                                 ; FC8FA4  sub HL,BC
	cp	hl, 32                                  ; FC8FA6  cp HL,0x0020
	jr c, sub_FC8EE5__FC8FCE                   ; FC8FAA  jr C,0xfc8fce
	ld	c, l                                    ; FC8FAC  ld C,L
	sub	c, 32                                  ; FC8FAE  sub C,0x20
	pushw	bc                                   ; FC8FB1  push BC
	pushw	0xFFFF                               ; FC8FB2  push 0xffff
	pushw	0xFFFF                               ; FC8FB5  push 0xffff
	call	0xFCA0FE                              ; FC8FB8  call 0xfca0fe
	ld	(xiz-28), xiy                           ; FC8FBC  ld (XIZ+0xe4),XIY
	and	xix, xiy                               ; FC8FBF  and XIX,XIY
	sub	xbc, xbc                               ; FC8FC1  sub XBC,XBC
	ld	(xiz-24), xbc                           ; FC8FC3  ld (XIZ+0xe8),XBC
	extpfx3 0xAE, 0xEC, 0xC5                   ; FC8FC6  and XIY,(XIZ+0xec)
	xor	(xiz-20), xiy                          ; FC8FC9  xor (XIZ+0xec),XIY
	jr sub_FC8EE5__FC8FEC                      ; FC8FCC  jr T,0xfc8fec
sub_FC8EE5__FC8FCE:
	ld	c, l                                    ; FC8FCE  ld C,L
	pushw	bc                                   ; FC8FD0  push BC
	pushw	0xFFFF                               ; FC8FD1  push 0xffff
	pushw	0xFFFF                               ; FC8FD4  push 0xffff
	call	0xFCA0FE                              ; FC8FD7  call 0xfca0fe
	ld	(xiz-28), xiy                           ; FC8FDB  ld (XIZ+0xe4),XIY
	and	(xiz-24), xiy                          ; FC8FDE  and (XIZ+0xe8),XIY
	extpfx3 0xAE, 0xF0, 0xC5                   ; FC8FE1  and XIY,(XIZ+0xf0)
	xor	(xiz-16), xiy                          ; FC8FE4  xor (XIZ+0xf0),XIY
	sub	xbc, xbc                               ; FC8FE7  sub XBC,XBC
	ld	(xiz-20), xbc                           ; FC8FE9  ld (XIZ+0xec),XBC
sub_FC8EE5__FC8FEC:
	ldb	e, 0                                   ; FC8FEC  ld E,0x00
	sub	xbc, xbc                               ; FC8FEE  sub XBC,XBC
	inc	4, xbc                                 ; FC8FF0  inc 4,XBC
	ld	(xiz-4), xbc                            ; FC8FF2  ld (XIZ+0xfc),XBC
sub_FC8EE5__FC8FF5:
	ld	xbc, (xiz-24)                           ; FC8FF5  ld XBC,(XIZ+0xe8)
	and	xbc, 0xFF                              ; FC8FF8  and XBC,0x000000ff
	ld	(xiz-26), c                             ; FC8FFE  ld (XIZ+0xe6),C
	ld	c, e                                    ; FC9001  ld C,E
	exts	bc                                    ; FC9003  exts BC
	exts	xbc                                   ; FC9005  exts XBC
	extpfx3 0xAE, 0x10, 0x81                   ; FC9007  add XBC,(XIZ+0x10)
	ld	a, (xiz-26)                             ; FC900A  ld A,(XIZ+0xe6)
	ld	(xbc), a                                ; FC900D  ld (XBC),A
	ld	xiy, (xiz-24)                           ; FC900F  ld XIY,(XIZ+0xe8)
	srl	xiy, 8                                 ; FC9012  srl 0x08,XIY
	ld	(xiz-24), xiy                           ; FC9015  ld (XIZ+0xe8),XIY
	ld	xbc, xix                                ; FC9018  ld XBC,XIX
	and	xbc, 0xFF                              ; FC901A  and XBC,0x000000ff
	ld	(xiz-28), c                             ; FC9020  ld (XIZ+0xe4),C
	ld	xbc, (xiz-4)                            ; FC9023  ld XBC,(XIZ+0xfc)
	ld	(xiz-32), xbc                           ; FC9026  ld (XIZ+0xe0),XBC
	extpfx3 0xAE, 0x10, 0x81                   ; FC9029  add XBC,(XIZ+0x10)
	ld	a, (xiz-28)                             ; FC902C  ld A,(XIZ+0xe4)
	ld	(xbc), a                                ; FC902F  ld (XBC),A
	ld	xiy, xix                                ; FC9031  ld XIY,XIX
	srl	xiy, 8                                 ; FC9033  srl 0x08,XIY
	ld	xix, xiy                                ; FC9036  ld XIX,XIY
	ld	xbc, (xiz-32)                           ; FC9038  ld XBC,(XIZ+0xe0)
	inc	1, xbc                                 ; FC903B  inc 1,XBC
	ld	(xiz-4), xbc                            ; FC903D  ld (XIZ+0xfc),XBC
	inc	1, e                                   ; FC9040  inc 1,E
	cps	e, 4                                   ; FC9042  cp E,4
	jr lt, sub_FC8EE5__FC8FF5                  ; FC9044  jr LT,0xfc8ff5
	ld	xwa, (xiz-20)                           ; FC9046  ld XWA,(XIZ+0xec)
	or	xwa, xwa                                ; FC9049  or XWA,XWA
	jr nz, sub_FC8EE5__FC9068                  ; FC904B  jr NZ,0xfc9068
	ld	xbc, (xiz-16)                           ; FC904D  ld XBC,(XIZ+0xf0)
	or	xbc, xbc                                ; FC9050  or XBC,XBC
	jr nz, sub_FC8EE5__FC9068                  ; FC9052  jr NZ,0xfc9068
sub_FC8EE5__FC9054:
	ld	xiy, (xsp)                              ; FC9054  ld XIY,(XSP)
	ld	xix, (0xFCB30E:24)                     ; FC9056  ld XIX,(0xfcb30e)
	stl_dpi	xix, 0xF6                          ; FC905B  ld (XIY+),XIX
	ld	xix, (0xFCB312:24)                     ; FC905E  ld XIX,(0xfcb312)
	ld	(xiy), xix                              ; FC9063  ld (XIY),XIX
	jrl sub_FC8EE5__FC9139                     ; FC9065  jrl T,0xfc9139
sub_FC8EE5__FC9068:
	ldw	bc, 52                                 ; FC9068  ld BC,0x0034
	sub	bc, hl                                 ; FC906B  sub BC,HL
	ld	hl, bc                                  ; FC906D  ld HL,BC
	add	bc, 0x3FF                              ; FC906F  add BC,0x03ff
	ld	hl, bc                                  ; FC9073  ld HL,BC
sub_FC8EE5__FC9075:
	ld	xbc, (xiz-20)                           ; FC9075  ld XBC,(XIZ+0xec)
	and	xbc, 0x100000                          ; FC9078  and XBC,0x00100000
	jr nz, sub_FC8EE5__FC90A8                  ; FC907E  jr NZ,0xfc90a8
	ld	xiy, (xiz-20)                           ; FC9080  ld XIY,(XIZ+0xec)
	add	xiy, xiy                               ; FC9083  add XIY,XIY
	ld	(xiz-20), xiy                           ; FC9085  ld (XIZ+0xec),XIY
	ld	xbc, (xiz-16)                           ; FC9088  ld XBC,(XIZ+0xf0)
	and	xbc, 0x80000000                        ; FC908B  and XBC,0x80000000
	jr z, sub_FC8EE5__FC909C                   ; FC9091  jr Z,0xfc909c
	or	xiy, 1                                  ; FC9093  or XIY,0x00000001
	ld	(xiz-20), xiy                           ; FC9099  ld (XIZ+0xec),XIY
sub_FC8EE5__FC909C:
	ld	xiy, (xiz-16)                           ; FC909C  ld XIY,(XIZ+0xf0)
	add	xiy, xiy                               ; FC909F  add XIY,XIY
	ld	(xiz-16), xiy                           ; FC90A1  ld (XIZ+0xf0),XIY
	dec	1, hl                                  ; FC90A4  dec 1,HL
	jr sub_FC8EE5__FC9075                      ; FC90A6  jr T,0xfc9075
sub_FC8EE5__FC90A8:
	ld	xbc, (xiz-20)                           ; FC90A8  ld XBC,(XIZ+0xec)
	and	xbc, 0xFFFFF                           ; FC90AB  and XBC,0x000fffff
	ld	xix, xbc                                ; FC90B1  ld XIX,XBC
	ld	iy, hl                                  ; FC90B3  ld IY,HL
	sll	iy, 4                                  ; FC90B5  sll 0x04,IY
	extz	xiy                                   ; FC90B8  extz XIY
	sll	xiy, 0                                 ; FC90BA  sll 0x00,XIY
	or	xbc, xiy                                ; FC90BD  or XBC,XIY
	ld	(xiz-20), xbc                           ; FC90BF  ld (XIZ+0xec),XBC
	cps	d, 0                                   ; FC90C2  cp D,0
	jr z, sub_FC8EE5__FC90CF                   ; FC90C4  jr Z,0xfc90cf
	or	xbc, 0x80000000                         ; FC90C6  or XBC,0x80000000
	ld	(xiz-20), xbc                           ; FC90CC  ld (XIZ+0xec),XBC
sub_FC8EE5__FC90CF:
	ldb	e, 0                                   ; FC90CF  ld E,0x00
	ld	xix, 4                                  ; FC90D1  ld XIX,0x00000004
sub_FC8EE5__FC90D6:
	ld	xbc, (xiz-16)                           ; FC90D6  ld XBC,(XIZ+0xf0)
	and	xbc, 0xFF                              ; FC90D9  and XBC,0x000000ff
	ld	h, c                                    ; FC90DF  ld H,C
	ld	c, e                                    ; FC90E1  ld C,E
	exts	bc                                    ; FC90E3  exts BC
	exts	xbc                                   ; FC90E5  exts XBC
	add	xbc, xiz                               ; FC90E7  add XBC,XIZ
	ld	(xbc-12), h                             ; FC90E9  ld (XBC+0xf4),H
	ld	xiy, (xiz-16)                           ; FC90EC  ld XIY,(XIZ+0xf0)
	srl	xiy, 8                                 ; FC90EF  srl 0x08,XIY
	ld	(xiz-16), xiy                           ; FC90F2  ld (XIZ+0xf0),XIY
	ld	xbc, (xiz-20)                           ; FC90F5  ld XBC,(XIZ+0xec)
	and	xbc, 0xFF                              ; FC90F8  and XBC,0x000000ff
	ld	h, c                                    ; FC90FE  ld H,C
	ld	(xiz-28), xix                           ; FC9100  ld (XIZ+0xe4),XIX
	ld	h, c                                    ; FC9103  ld H,C
	ld	xbc, (xiz-28)                           ; FC9105  ld XBC,(XIZ+0xe4)
	add	xbc, xiz                               ; FC9108  add XBC,XIZ
	ld	(xbc-12), h                             ; FC910A  ld (XBC+0xf4),H
	ld	xiy, (xiz-20)                           ; FC910D  ld XIY,(XIZ+0xec)
	srl	xiy, 8                                 ; FC9110  srl 0x08,XIY
	ld	(xiz-20), xiy                           ; FC9113  ld (XIZ+0xec),XIY
	ld	xix, (xiz-28)                           ; FC9116  ld XIX,(XIZ+0xe4)
	inc	1, xix                                 ; FC9119  inc 1,XIX
	inc	1, e                                   ; FC911B  inc 1,E
	cps	e, 4                                   ; FC911D  cp E,4
	jr lt, sub_FC8EE5__FC90D6                  ; FC911F  jr LT,0xfc90d6
sub_FC8EE5__FC9121:
	lda	xix, (xiz-32)                          ; FC9121  lda XIX,XIZ+0xe0
	lda	xiy, (xiz-12)                          ; FC9124  lda XIY,XIZ+0xf4
	ldw	bc, 4                                  ; FC9127  ld BC,0x0004
	extpfx2 0x95, 0x11                         ; FC912A  ldirw
	ld	xiy, (xsp)                              ; FC912C  ld XIY,(XSP)
	ld	xix, (xiz-32)                           ; FC912E  ld XIX,(XIZ+0xe0)
	stl_dpi	xix, 0xF6                          ; FC9131  ld (XIY+),XIX
	ld	xix, (xiz-28)                           ; FC9134  ld XIX,(XIZ+0xe4)
	ld	(xiy), xix                              ; FC9137  ld (XIY),XIX
sub_FC8EE5__FC9139:
	pop	xiy                                    ; FC9139  pop XIY
	pop	xix                                    ; FC913A  pop XIX
	popw	de                                    ; FC913B  pop DE
	popw	hl                                    ; FC913C  pop HL
	unlk32 xiz                                 ; FC913D  unlk XIZ
	ret                                        ; FC913F  ret
; --------------------------------------------------------------------------
; sub_FC9140 -- 0xFC9140..0xFC9575 (1078 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xF9E2E3 in sub_F9E1ED__F9E222, 0xF9EA0A in sub_F9E1ED__F9E995
; Inputs:  frame `link XIZ,-82`; argument slots read: (XIZ+0x08), (XIZ+0x0C)
; Outputs: writes 0x00F362
;          reads 0xFCB316, 0xFCB31A, 0xFCB31E, 0xFCB322, 0xFCB326, 0xFCB32A, 0xFCB32E, 0xFCB332, 0xFCB336, 0xFCB33A, 0xFCB33E, 0xFCB342, 0xFCB346, 0xFCB34A, 0xFCB34E, 0xFCB352, 0xFCB356, 0xFCB35A, 0xFCB35E, 0xFCB362, 0xFCB366, 0xFCB36A, 0xFCB36E, 0xFCB372
; Calls:   0xFC8EE5 = sub_FC8EE5, 0xFCA121 = Double_Compare
;          0xFCA1B6 = Double_Negate, 0xFCA1E5 = Double_Classify
;          0xFCA252 = Double_Multiply, 0xFCA41F = Double_Add
;          0xFCA626 = Double_Subtract, 0xFCA661 = Double_ToInt32
;          0xFCA6FD = Int32_ToDouble, 0xFCA7A5 = Double_Divide
; Evidence: the listing below is the byte-identical round-trip of 0xFC9140-0xFC9575
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC9140:
	link32 0xEE, 0x0C, 0xAE, 0xFF              ; FC9140  link XIZ,0xffae
	pushw	hl                                   ; FC9144  push HL
	pushw	de                                   ; FC9145  push DE
	push	xix                                   ; FC9146  push XIX
	push	xiy                                   ; FC9147  push XIY
	ldw	hl, 0                                  ; FC9148  ld HL,0x0000
	ld	xbc, (0xFCB372:24)                     ; FC914B  ld XBC,(0xfcb372)
	push	xbc                                   ; FC9150  push XBC
	ld	xbc, (0xFCB36E:24)                     ; FC9151  ld XBC,(0xfcb36e)
	push	xbc                                   ; FC9156  push XBC
	ld	xbc, (xiz+12)                           ; FC9157  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC915A  push XBC
	ld	xbc, (xiz+8)                            ; FC915B  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC915E  push XBC
	call	0xFCA121                              ; FC915F  call 0xfca121
	cps	wa, 2                                  ; FC9163  cp WA,2
	jr nz, sub_FC9140__FC916A                  ; FC9165  jr NZ,0xfc916a
	ldw	hl, 1                                  ; FC9167  ld HL,0x0001
sub_FC9140__FC916A:
	ld	(xiz-2), hl                             ; FC916A  ld (XIZ+0xfe),HL
	cps	hl, 0                                  ; FC916D  cp HL,0
	jr z, sub_FC9140__FC9180                   ; FC916F  jr Z,0xfc9180
	ld	xbc, (xiz+12)                           ; FC9171  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC9174  push XBC
	ld	xbc, (xiz+8)                            ; FC9175  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC9178  push XBC
	lda	xiy, (xiz+8)                           ; FC9179  lda XIY,XIZ+0x08
	call	0xFCA1B6                              ; FC917C  call 0xfca1b6
sub_FC9140__FC9180:
	ld	xbc, (0xFCB36A:24)                     ; FC9180  ld XBC,(0xfcb36a)
	push	xbc                                   ; FC9185  push XBC
	ld	xbc, (0xFCB366:24)                     ; FC9186  ld XBC,(0xfcb366)
	push	xbc                                   ; FC918B  push XBC
	ld	xbc, (xiz+12)                           ; FC918C  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC918F  push XBC
	ld	xbc, (xiz+8)                            ; FC9190  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC9193  push XBC
	call	0xFCA121                              ; FC9194  call 0xfca121
	cps	wa, 1                                  ; FC9198  cp WA,1
	jr nz, sub_FC9140__FC91B7                  ; FC919A  jr NZ,0xfc91b7
	ldw	(0xF362:24), 34                       ; FC919C  ld (0x00f362),0x0022
	ld	xiy, (xsp)                              ; FC91A3  ld XIY,(XSP)
	ld	xix, (0xFCB36E:24)                     ; FC91A5  ld XIX,(0xfcb36e)
	stl_dpi	xix, 0xF6                          ; FC91AA  ld (XIY+),XIX
	ld	xix, (0xFCB372:24)                     ; FC91AD  ld XIX,(0xfcb372)
	ld	(xiy), xix                              ; FC91B2  ld (XIY),XIX
	jrl sub_FC9140__FC956F                     ; FC91B4  jrl T,0xfc956f
sub_FC9140__FC91B7:
	ld	xbc, (0xFCB362:24)                     ; FC91B7  ld XBC,(0xfcb362)
	push	xbc                                   ; FC91BC  push XBC
	ld	xbc, (0xFCB35E:24)                     ; FC91BD  ld XBC,(0xfcb35e)
	push	xbc                                   ; FC91C2  push XBC
	ld	xbc, (xiz+12)                           ; FC91C3  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC91C6  push XBC
	ld	xbc, (xiz+8)                            ; FC91C7  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC91CA  push XBC
	call	0xFCA121                              ; FC91CB  call 0xfca121
	cps	wa, 1                                  ; FC91CF  cp WA,1
	jr nz, sub_FC9140__FC91DA                  ; FC91D1  jr NZ,0xfc91da
	ldw	(0xF362:24), 34                       ; FC91D3  ld (0x00f362),0x0022
sub_FC9140__FC91DA:
	ld	xbc, (xiz+12)                           ; FC91DA  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC91DD  push XBC
	ld	xbc, (xiz+8)                            ; FC91DE  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC91E1  push XBC
	ld	xbc, (0xFCB35A:24)                     ; FC91E2  ld XBC,(0xfcb35a)
	push	xbc                                   ; FC91E7  push XBC
	ld	xbc, (0xFCB356:24)                     ; FC91E8  ld XBC,(0xfcb356)
	push	xbc                                   ; FC91ED  push XBC
	lda	xiy, (xiz-34)                          ; FC91EE  lda XIY,XIZ+0xde
	call	0xFCA252                              ; FC91F1  call 0xfca252
	ld	xbc, (0xFCB352:24)                     ; FC91F5  ld XBC,(0xfcb352)
	push	xbc                                   ; FC91FA  push XBC
	ld	xbc, (0xFCB34E:24)                     ; FC91FB  ld XBC,(0xfcb34e)
	push	xbc                                   ; FC9200  push XBC
	ld	xbc, (xiz-30)                           ; FC9201  ld XBC,(XIZ+0xe2)
	push	xbc                                   ; FC9204  push XBC
	ld	xbc, (xiz-34)                           ; FC9205  ld XBC,(XIZ+0xde)
	push	xbc                                   ; FC9208  push XBC
	lda	xiy, (xiz-10)                          ; FC9209  lda XIY,XIZ+0xf6
	call	0xFCA41F                              ; FC920C  call 0xfca41f
	ld	xbc, (0xFCB31A:24)                     ; FC9210  ld XBC,(0xfcb31a)
	push	xbc                                   ; FC9215  push XBC
	ld	xbc, (0xFCB316:24)                     ; FC9216  ld XBC,(0xfcb316)
	push	xbc                                   ; FC921B  push XBC
	ld	xbc, (xiz+12)                           ; FC921C  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC921F  push XBC
	ld	xbc, (xiz+8)                            ; FC9220  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC9223  push XBC
	call	0xFCA121                              ; FC9224  call 0xfca121
	cps	wa, 1                                  ; FC9228  cp WA,1
	jrl z, sub_FC9140__FC92FB                  ; FC922A  jrl Z,0xfc92fb
	ld	xbc, (xiz-6)                            ; FC922D  ld XBC,(XIZ+0xfa)
	push	xbc                                   ; FC9230  push XBC
	ld	xbc, (xiz-10)                           ; FC9231  ld XBC,(XIZ+0xf6)
	push	xbc                                   ; FC9234  push XBC
	call	0xFCA661                              ; FC9235  call 0xfca661
	ld	xix, xiy                                ; FC9239  ld XIX,XIY
	push	xiy                                   ; FC923B  push XIY
	lda	xiy, (xiz-34)                          ; FC923C  lda XIY,XIZ+0xde
	call	0xFCA6FD                              ; FC923F  call 0xfca6fd
	ld	xbc, (xiz+12)                           ; FC9243  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC9246  push XBC
	ld	xbc, (xiz+8)                            ; FC9247  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC924A  push XBC
	call	0xFCA661                              ; FC924B  call 0xfca661
	push	xiy                                   ; FC924F  push XIY
	lda	xiy, (xiz-42)                          ; FC9250  lda XIY,XIZ+0xd6
	call	0xFCA6FD                              ; FC9253  call 0xfca6fd
	ld	xbc, (xiz-38)                           ; FC9257  ld XBC,(XIZ+0xda)
	push	xbc                                   ; FC925A  push XBC
	ld	xbc, (xiz-42)                           ; FC925B  ld XBC,(XIZ+0xd6)
	push	xbc                                   ; FC925E  push XBC
	ld	xbc, (xiz+12)                           ; FC925F  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC9262  push XBC
	ld	xbc, (xiz+8)                            ; FC9263  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC9266  push XBC
	lda	xiy, (xiz-50)                          ; FC9267  lda XIY,XIZ+0xce
	call	0xFCA626                              ; FC926A  call 0xfca626
	ld	xbc, (xiz-30)                           ; FC926E  ld XBC,(XIZ+0xe2)
	push	xbc                                   ; FC9271  push XBC
	ld	xbc, (xiz-34)                           ; FC9272  ld XBC,(XIZ+0xde)
	push	xbc                                   ; FC9275  push XBC
	ld	xbc, (0xFCB34A:24)                     ; FC9276  ld XBC,(0xfcb34a)
	push	xbc                                   ; FC927B  push XBC
	ld	xbc, (0xFCB346:24)                     ; FC927C  ld XBC,(0xfcb346)
	push	xbc                                   ; FC9281  push XBC
	lda	xiy, (xiz-58)                          ; FC9282  lda XIY,XIZ+0xc6
	call	0xFCA252                              ; FC9285  call 0xfca252
	ld	xbc, (xiz-54)                           ; FC9289  ld XBC,(XIZ+0xca)
	push	xbc                                   ; FC928C  push XBC
	ld	xbc, (xiz-58)                           ; FC928D  ld XBC,(XIZ+0xc6)
	push	xbc                                   ; FC9290  push XBC
	ld	xbc, (xiz-38)                           ; FC9291  ld XBC,(XIZ+0xda)
	push	xbc                                   ; FC9294  push XBC
	ld	xbc, (xiz-42)                           ; FC9295  ld XBC,(XIZ+0xd6)
	push	xbc                                   ; FC9298  push XBC
	lda	xiy, (xiz-66)                          ; FC9299  lda XIY,XIZ+0xbe
	call	0xFCA626                              ; FC929C  call 0xfca626
	ld	xbc, (xiz-46)                           ; FC92A0  ld XBC,(XIZ+0xd2)
	push	xbc                                   ; FC92A3  push XBC
	ld	xbc, (xiz-50)                           ; FC92A4  ld XBC,(XIZ+0xce)
	push	xbc                                   ; FC92A7  push XBC
	ld	xbc, (xiz-62)                           ; FC92A8  ld XBC,(XIZ+0xc2)
	push	xbc                                   ; FC92AB  push XBC
	ld	xbc, (xiz-66)                           ; FC92AC  ld XBC,(XIZ+0xbe)
	push	xbc                                   ; FC92AF  push XBC
	lda	xiy, (xiz-74)                          ; FC92B0  lda XIY,XIZ+0xb6
	call	0xFCA41F                              ; FC92B3  call 0xfca41f
	ld	xbc, (xiz-30)                           ; FC92B7  ld XBC,(XIZ+0xe2)
	push	xbc                                   ; FC92BA  push XBC
	ld	xbc, (xiz-34)                           ; FC92BB  ld XBC,(XIZ+0xde)
	push	xbc                                   ; FC92BE  push XBC
	ld	xbc, (0xFCB342:24)                     ; FC92BF  ld XBC,(0xfcb342)
	push	xbc                                   ; FC92C4  push XBC
	ld	xbc, (0xFCB33E:24)                     ; FC92C5  ld XBC,(0xfcb33e)
	push	xbc                                   ; FC92CA  push XBC
	lda	xiy, (xiz-82)                          ; FC92CB  lda XIY,XIZ+0xae
	call	0xFCA252                              ; FC92CE  call 0xfca252
	ld	xbc, (xiz-78)                           ; FC92D2  ld XBC,(XIZ+0xb2)
	push	xbc                                   ; FC92D5  push XBC
	ld	xbc, (xiz-82)                           ; FC92D6  ld XBC,(XIZ+0xae)
	push	xbc                                   ; FC92D9  push XBC
	ld	xbc, (xiz-70)                           ; FC92DA  ld XBC,(XIZ+0xba)
	push	xbc                                   ; FC92DD  push XBC
	ld	xbc, (xiz-74)                           ; FC92DE  ld XBC,(XIZ+0xb6)
	push	xbc                                   ; FC92E1  push XBC
	lda	xiy, (xiz+8)                           ; FC92E2  lda XIY,XIZ+0x08
	call	0xFCA626                              ; FC92E5  call 0xfca626
	ld	de, ix                                  ; FC92E9  ld DE,IX
	ld	bc, de                                  ; FC92EB  ld BC,DE
	exts	xbc                                   ; FC92ED  exts XBC
	divs	bc, 2                                 ; FC92EF  divs BC,0x0002
	extpfx3 0xD7, 0xE6, 0xB9                   ; FC92F3  ex BC,QBC
	ld	de, bc                                  ; FC92F6  ld DE,BC
	jrl sub_FC9140__FC9399                     ; FC92F8  jrl T,0xfc9399
sub_FC9140__FC92FB:
	lda	xbc, (xiz-18)                          ; FC92FB  lda XBC,XIZ+0xee
	push	xbc                                   ; FC92FE  push XBC
	ld	xwa, (xiz-6)                            ; FC92FF  ld XWA,(XIZ+0xfa)
	push	xwa                                   ; FC9302  push XWA
	ld	xwa, (xiz-10)                           ; FC9303  ld XWA,(XIZ+0xf6)
	push	xwa                                   ; FC9306  push XWA
	lda	xiy, (xiz-34)                          ; FC9307  lda XIY,XIZ+0xde
	call	0xFC8EE5                              ; FC930A  call 0xfc8ee5
	ld	xbc, (0xFCB352:24)                     ; FC930E  ld XBC,(0xfcb352)
	push	xbc                                   ; FC9313  push XBC
	ld	xbc, (0xFCB34E:24)                     ; FC9314  ld XBC,(0xfcb34e)
	push	xbc                                   ; FC9319  push XBC
	ld	xbc, (xiz-30)                           ; FC931A  ld XBC,(XIZ+0xe2)
	push	xbc                                   ; FC931D  push XBC
	ld	xbc, (xiz-34)                           ; FC931E  ld XBC,(XIZ+0xde)
	push	xbc                                   ; FC9321  push XBC
	lda	xiy, (xiz-42)                          ; FC9322  lda XIY,XIZ+0xd6
	call	0xFCA626                              ; FC9325  call 0xfca626
	ld	xbc, (xiz-38)                           ; FC9329  ld XBC,(XIZ+0xda)
	push	xbc                                   ; FC932C  push XBC
	ld	xbc, (xiz-42)                           ; FC932D  ld XBC,(XIZ+0xd6)
	push	xbc                                   ; FC9330  push XBC
	ld	xbc, (0xFCB33A:24)                     ; FC9331  ld XBC,(0xfcb33a)
	push	xbc                                   ; FC9336  push XBC
	ld	xbc, (0xFCB336:24)                     ; FC9337  ld XBC,(0xfcb336)
	push	xbc                                   ; FC933C  push XBC
	lda	xiy, (xiz+8)                           ; FC933D  lda XIY,XIZ+0x08
	call	0xFCA252                              ; FC9340  call 0xfca252
	lda	xbc, (xiz-18)                          ; FC9344  lda XBC,XIZ+0xee
	push	xbc                                   ; FC9347  push XBC
	add	xbc, 8                                 ; FC9348  add XBC,0x00000008
	extpfx3 0xD4, 0xE5, 0x04                   ; FC934E  pushw (-XBC)
	extpfx3 0xD4, 0xE5, 0x04                   ; FC9351  pushw (-XBC)
	extpfx3 0xD4, 0xE5, 0x04                   ; FC9354  pushw (-XBC)
	extpfx2 0x91, 0x04                         ; FC9357  pushw (XBC)
	ld	xwa, (0xFCB352:24)                     ; FC9359  ld XWA,(0xfcb352)
	push	xwa                                   ; FC935E  push XWA
	ld	xwa, (0xFCB34E:24)                     ; FC935F  ld XWA,(0xfcb34e)
	push	xwa                                   ; FC9364  push XWA
	lda	xiy, (xiz-50)                          ; FC9365  lda XIY,XIZ+0xce
	call	0xFCA252                              ; FC9368  call 0xfca252
	ld	xbc, (xiz-46)                           ; FC936C  ld XBC,(XIZ+0xd2)
	push	xbc                                   ; FC936F  push XBC
	ld	xbc, (xiz-50)                           ; FC9370  ld XBC,(XIZ+0xce)
	push	xbc                                   ; FC9373  push XBC
	lda	xiy, (xiz-58)                          ; FC9374  lda XIY,XIZ+0xc6
	call	0xFC8EE5                              ; FC9377  call 0xfc8ee5
	add	xsp, 24                                ; FC937B  add XSP,0x00000018
	ld	xbc, (xiz-54)                           ; FC9381  ld XBC,(XIZ+0xca)
	push	xbc                                   ; FC9384  push XBC
	ld	xbc, (xiz-58)                           ; FC9385  ld XBC,(XIZ+0xc6)
	push	xbc                                   ; FC9388  push XBC
	call	0xFCA1E5                              ; FC9389  call 0xfca1e5
	cps	wa, 0                                  ; FC938D  cp WA,0
	jr z, sub_FC9140__FC9396                   ; FC938F  jr Z,0xfc9396
	ldw	de, 1                                  ; FC9391  ld DE,0x0001
	jr sub_FC9140__FC9399                      ; FC9394  jr T,0xfc9399
sub_FC9140__FC9396:
	ldw	de, 0                                  ; FC9396  ld DE,0x0000
sub_FC9140__FC9399:
	ld	xbc, (0xFCB332:24)                     ; FC9399  ld XBC,(0xfcb332)
	push	xbc                                   ; FC939E  push XBC
	ld	xbc, (0xFCB32E:24)                     ; FC939F  ld XBC,(0xfcb32e)
	push	xbc                                   ; FC93A4  push XBC
	ld	xbc, (xiz+12)                           ; FC93A5  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC93A8  push XBC
	ld	xbc, (xiz+8)                            ; FC93A9  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC93AC  push XBC
	call	0xFCA121                              ; FC93AD  call 0xfca121
	cps	wa, 1                                  ; FC93B1  cp WA,1
	jr nz, sub_FC9140__FC93E4                  ; FC93B3  jr NZ,0xfc93e4
	ld	xbc, (0xFCB32A:24)                     ; FC93B5  ld XBC,(0xfcb32a)
	push	xbc                                   ; FC93BA  push XBC
	ld	xbc, (0xFCB326:24)                     ; FC93BB  ld XBC,(0xfcb326)
	push	xbc                                   ; FC93C0  push XBC
	ld	xbc, (xiz+12)                           ; FC93C1  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC93C4  push XBC
	ld	xbc, (xiz+8)                            ; FC93C5  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC93C8  push XBC
	call	0xFCA121                              ; FC93C9  call 0xfca121
	cps	wa, 2                                  ; FC93CD  cp WA,2
	jr nz, sub_FC9140__FC93E4                  ; FC93CF  jr NZ,0xfc93e4
	ld	xbc, (0xFCB31E:24)                     ; FC93D1  ld XBC,(0xfcb31e)
	ld	(xiz-10), xbc                           ; FC93D6  ld (XIZ+0xf6),XBC
	ld	xbc, (0xFCB322:24)                     ; FC93D9  ld XBC,(0xfcb322)
	ld	(xiz-6), xbc                            ; FC93DE  ld (XIZ+0xfa),XBC
	jrl sub_FC9140__FC94FC                     ; FC93E1  jrl T,0xfc94fc
sub_FC9140__FC93E4:
	ld	xbc, (xiz+12)                           ; FC93E4  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC93E7  push XBC
	ld	xbc, (xiz+8)                            ; FC93E8  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC93EB  push XBC
	ld	xbc, (xiz+12)                           ; FC93EC  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC93EF  push XBC
	ld	xbc, (xiz+8)                            ; FC93F0  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC93F3  push XBC
	lda	xiy, (xiz-10)                          ; FC93F4  lda XIY,XIZ+0xf6
	call	0xFCA252                              ; FC93F7  call 0xfca252
	lda	xix, (xiz-26)                          ; FC93FB  lda XIX,XIZ+0xe6
	lda	xiy, (0xFCB376:24)                     ; FC93FE  lda XIY,0xfcb376
	ldw	bc, 4                                  ; FC9403  ld BC,0x0004
	extpfx2 0x95, 0x11                         ; FC9406  ldirw
	lda	xix, (0xFCB376:24)                     ; FC9408  lda XIX,0xfcb376
	inc	8, xix                                 ; FC940D  inc 0,XIX
	ldb	h, 2                                   ; FC940F  ld H,0x02
sub_FC9140__FC9411:
	ld	xbc, (xiz-22)                           ; FC9411  ld XBC,(XIZ+0xea)
	push	xbc                                   ; FC9414  push XBC
	ld	xbc, (xiz-26)                           ; FC9415  ld XBC,(XIZ+0xe6)
	push	xbc                                   ; FC9418  push XBC
	ld	xbc, (xiz-6)                            ; FC9419  ld XBC,(XIZ+0xfa)
	push	xbc                                   ; FC941C  push XBC
	ld	xbc, (xiz-10)                           ; FC941D  ld XBC,(XIZ+0xf6)
	push	xbc                                   ; FC9420  push XBC
	lda	xiy, (xiz-34)                          ; FC9421  lda XIY,XIZ+0xde
	call	0xFCA252                              ; FC9424  call 0xfca252
	push	xix                                   ; FC9428  push XIX
	lda	xix, (xiz-42)                          ; FC9429  lda XIX,XIZ+0xd6
	ld	xiy, (xsp)                              ; FC942C  ld XIY,(XSP)
	ldw	bc, 4                                  ; FC942E  ld BC,0x0004
	extpfx2 0x95, 0x11                         ; FC9431  ldirw
	pop	xix                                    ; FC9433  pop XIX
	ld	xbc, (xiz-38)                           ; FC9434  ld XBC,(XIZ+0xda)
	push	xbc                                   ; FC9437  push XBC
	ld	xbc, (xiz-42)                           ; FC9438  ld XBC,(XIZ+0xd6)
	push	xbc                                   ; FC943B  push XBC
	ld	xbc, (xiz-30)                           ; FC943C  ld XBC,(XIZ+0xe2)
	push	xbc                                   ; FC943F  push XBC
	ld	xbc, (xiz-34)                           ; FC9440  ld XBC,(XIZ+0xde)
	push	xbc                                   ; FC9443  push XBC
	lda	xiy, (xiz-26)                          ; FC9444  lda XIY,XIZ+0xe6
	call	0xFCA41F                              ; FC9447  call 0xfca41f
	inc	8, xix                                 ; FC944B  inc 0,XIX
	dec	1, h                                   ; FC944D  dec 1,H
	cps	h, 0                                   ; FC944F  cp H,0
	jr nz, sub_FC9140__FC9411                  ; FC9451  jr NZ,0xfc9411
	ld	xbc, (xiz+12)                           ; FC9453  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC9456  push XBC
	ld	xbc, (xiz+8)                            ; FC9457  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC945A  push XBC
	ld	xbc, (xiz-6)                            ; FC945B  ld XBC,(XIZ+0xfa)
	push	xbc                                   ; FC945E  push XBC
	ld	xbc, (xiz-10)                           ; FC945F  ld XBC,(XIZ+0xf6)
	push	xbc                                   ; FC9462  push XBC
	lda	xiy, (xiz-34)                          ; FC9463  lda XIY,XIZ+0xde
	call	0xFCA252                              ; FC9466  call 0xfca252
	ld	xbc, (xiz-30)                           ; FC946A  ld XBC,(XIZ+0xe2)
	push	xbc                                   ; FC946D  push XBC
	ld	xbc, (xiz-34)                           ; FC946E  ld XBC,(XIZ+0xde)
	push	xbc                                   ; FC9471  push XBC
	ld	xbc, (xiz-22)                           ; FC9472  ld XBC,(XIZ+0xea)
	push	xbc                                   ; FC9475  push XBC
	ld	xbc, (xiz-26)                           ; FC9476  ld XBC,(XIZ+0xe6)
	push	xbc                                   ; FC9479  push XBC
	lda	xiy, (xiz-42)                          ; FC947A  lda XIY,XIZ+0xd6
	call	0xFCA252                              ; FC947D  call 0xfca252
	ld	xbc, (xiz-38)                           ; FC9481  ld XBC,(XIZ+0xda)
	push	xbc                                   ; FC9484  push XBC
	ld	xbc, (xiz-42)                           ; FC9485  ld XBC,(XIZ+0xd6)
	push	xbc                                   ; FC9488  push XBC
	ld	xbc, (xiz+12)                           ; FC9489  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC948C  push XBC
	ld	xbc, (xiz+8)                            ; FC948D  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC9490  push XBC
	lda	xiy, (xiz+8)                           ; FC9491  lda XIY,XIZ+0x08
	call	0xFCA41F                              ; FC9494  call 0xfca41f
	lda	xix, (xiz-26)                          ; FC9498  lda XIX,XIZ+0xe6
	lda	xiy, (0xFCB38E:24)                     ; FC949B  lda XIY,0xfcb38e
	ldw	bc, 4                                  ; FC94A0  ld BC,0x0004
	extpfx2 0x95, 0x11                         ; FC94A3  ldirw
	lda	xix, (0xFCB38E:24)                     ; FC94A5  lda XIX,0xfcb38e
	inc	8, xix                                 ; FC94AA  inc 0,XIX
	ldb	h, 4                                   ; FC94AC  ld H,0x04
sub_FC9140__FC94AE:
	ld	xbc, (xiz-22)                           ; FC94AE  ld XBC,(XIZ+0xea)
	push	xbc                                   ; FC94B1  push XBC
	ld	xbc, (xiz-26)                           ; FC94B2  ld XBC,(XIZ+0xe6)
	push	xbc                                   ; FC94B5  push XBC
	ld	xbc, (xiz-6)                            ; FC94B6  ld XBC,(XIZ+0xfa)
	push	xbc                                   ; FC94B9  push XBC
	ld	xbc, (xiz-10)                           ; FC94BA  ld XBC,(XIZ+0xf6)
	push	xbc                                   ; FC94BD  push XBC
	lda	xiy, (xiz-34)                          ; FC94BE  lda XIY,XIZ+0xde
	call	0xFCA252                              ; FC94C1  call 0xfca252
	push	xix                                   ; FC94C5  push XIX
	lda	xix, (xiz-42)                          ; FC94C6  lda XIX,XIZ+0xd6
	ld	xiy, (xsp)                              ; FC94C9  ld XIY,(XSP)
	ldw	bc, 4                                  ; FC94CB  ld BC,0x0004
	extpfx2 0x95, 0x11                         ; FC94CE  ldirw
	pop	xix                                    ; FC94D0  pop XIX
	ld	xbc, (xiz-38)                           ; FC94D1  ld XBC,(XIZ+0xda)
	push	xbc                                   ; FC94D4  push XBC
	ld	xbc, (xiz-42)                           ; FC94D5  ld XBC,(XIZ+0xd6)
	push	xbc                                   ; FC94D8  push XBC
	ld	xbc, (xiz-30)                           ; FC94D9  ld XBC,(XIZ+0xe2)
	push	xbc                                   ; FC94DC  push XBC
	ld	xbc, (xiz-34)                           ; FC94DD  ld XBC,(XIZ+0xde)
	push	xbc                                   ; FC94E0  push XBC
	lda	xiy, (xiz-26)                          ; FC94E1  lda XIY,XIZ+0xe6
	call	0xFCA41F                              ; FC94E4  call 0xfca41f
	inc	8, xix                                 ; FC94E8  inc 0,XIX
	dec	1, h                                   ; FC94EA  dec 1,H
	cps	h, 0                                   ; FC94EC  cp H,0
	jr nz, sub_FC9140__FC94AE                  ; FC94EE  jr NZ,0xfc94ae
	ld	xbc, (xiz-26)                           ; FC94F0  ld XBC,(XIZ+0xe6)
	ld	(xiz-10), xbc                           ; FC94F3  ld (XIZ+0xf6),XBC
	ld	xbc, (xiz-22)                           ; FC94F6  ld XBC,(XIZ+0xea)
	ld	(xiz-6), xbc                            ; FC94F9  ld (XIZ+0xfa),XBC
sub_FC9140__FC94FC:
	cpw (xiz-2), 0x0000                        ; FC94FC  cp (XIZ+0xfe),0x0000
	jr z, sub_FC9140__FC9512                   ; FC9501  jr Z,0xfc9512
	ld	xbc, (xiz+12)                           ; FC9503  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC9506  push XBC
	ld	xbc, (xiz+8)                            ; FC9507  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC950A  push XBC
	lda	xiy, (xiz+8)                           ; FC950B  lda XIY,XIZ+0x08
	call	0xFCA1B6                              ; FC950E  call 0xfca1b6
sub_FC9140__FC9512:
	cps	de, 0                                  ; FC9512  cp DE,0
	jr z, sub_FC9140__FC954B                   ; FC9514  jr Z,0xfc954b
	ld	xbc, (xiz-6)                            ; FC9516  ld XBC,(XIZ+0xfa)
	push	xbc                                   ; FC9519  push XBC
	ld	xbc, (xiz-10)                           ; FC951A  ld XBC,(XIZ+0xf6)
	push	xbc                                   ; FC951D  push XBC
	lda	xiy, (xiz-34)                          ; FC951E  lda XIY,XIZ+0xde
	call	0xFCA1B6                              ; FC9521  call 0xfca1b6
	ld	xbc, (xiz+12)                           ; FC9525  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC9528  push XBC
	ld	xbc, (xiz+8)                            ; FC9529  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC952C  push XBC
	ld	xbc, (xiz-30)                           ; FC952D  ld XBC,(XIZ+0xe2)
	push	xbc                                   ; FC9530  push XBC
	ld	xbc, (xiz-34)                           ; FC9531  ld XBC,(XIZ+0xde)
	push	xbc                                   ; FC9534  push XBC
	lda	xiy, (xiz-42)                          ; FC9535  lda XIY,XIZ+0xd6
	call	0xFCA7A5                              ; FC9538  call 0xfca7a5
	ld	xiy, (xsp)                              ; FC953C  ld XIY,(XSP)
	ld	xix, (xiz-42)                           ; FC953E  ld XIX,(XIZ+0xd6)
	stl_dpi	xix, 0xF6                          ; FC9541  ld (XIY+),XIX
	ld	xix, (xiz-38)                           ; FC9544  ld XIX,(XIZ+0xda)
	ld	(xiy), xix                              ; FC9547  ld (XIY),XIX
	jr sub_FC9140__FC956F                      ; FC9549  jr T,0xfc956f
sub_FC9140__FC954B:
	ld	xbc, (xiz-6)                            ; FC954B  ld XBC,(XIZ+0xfa)
	push	xbc                                   ; FC954E  push XBC
	ld	xbc, (xiz-10)                           ; FC954F  ld XBC,(XIZ+0xf6)
	push	xbc                                   ; FC9552  push XBC
	ld	xbc, (xiz+12)                           ; FC9553  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC9556  push XBC
	ld	xbc, (xiz+8)                            ; FC9557  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC955A  push XBC
	lda	xiy, (xiz-34)                          ; FC955B  lda XIY,XIZ+0xde
	call	0xFCA7A5                              ; FC955E  call 0xfca7a5
	ld	xiy, (xsp)                              ; FC9562  ld XIY,(XSP)
	ld	xix, (xiz-34)                           ; FC9564  ld XIX,(XIZ+0xde)
	stl_dpi	xix, 0xF6                          ; FC9567  ld (XIY+),XIX
	ld	xix, (xiz-30)                           ; FC956A  ld XIX,(XIZ+0xe2)
	ld	(xiy), xix                              ; FC956D  ld (XIY),XIX
sub_FC9140__FC956F:
	pop	xiy                                    ; FC956F  pop XIY
	pop	xix                                    ; FC9570  pop XIX
	popw	de                                    ; FC9571  pop DE
	popw	hl                                    ; FC9572  pop HL
	unlk32 xiz                                 ; FC9573  unlk XIZ
	ret                                        ; FC9575  ret
; --------------------------------------------------------------------------
; sub_FC9576 -- 0xFC9576..0xFC9843 (718 bytes)
;
; Called from: 44 site(s) outside this module:
;          0xF9B613 in sub_F9B5A5, 0xF9B6DC in sub_F9B5A5__F9B65B
;          0xF9B7E8 in sub_F9B5A5__F9B73C, 0xF9B8C9 in sub_F9B887
;          0xF9B9AA in sub_F9B887__F9B908, 0xF9BAAA in sub_F9B887__F9B9FE
;          0xF9BB8B in sub_F9B887__F9BAE9, 0xF9BC6C in sub_F9B887__F9BBCA
;          0xF9BD62 in sub_F9B887__F9BCC0, 0xF9C529 in sub_F9BE3A__F9C44C
;          0xF9C61D in sub_F9BE3A__F9C547, 0xF9C971 in sub_F9BE3A__F9C8D6
;          0xF9CA44 in sub_F9BE3A__F9C9B0, 0xF9CBC8 in sub_F9BE3A__F9CA8F
;          0xF9D2B3 in sub_F9BE3A__F9D266, 0xF9D3A1 in sub_F9BE3A__F9D31C
;          0xF9D44D in sub_F9BE3A__F9D31C, 0xF9D708 in sub_F9BE3A__F9D622
;          0xF9D82B in sub_F9BE3A__F9D75C, 0xF9D950 in sub_F9BE3A__F9D87F
;          0xF9DA75 in sub_F9BE3A__F9D9A4, 0xF9DB91 in sub_F9BE3A__F9DAC9
;          0xF9E493 in sub_F9E1ED__F9E452, 0xF9E5A2 in sub_F9E1ED__F9E561
;          0xF9EDD6 in sub_F9ECF1__F9ED7A, 0xF9F291 in sub_F9ECF1__F9F235
;          0xFA00E3 in sub_FA000B__FA0047, 0xFA01C5 in sub_FA000B__FA0127
;          0xFA02EA in sub_FA000B__FA0221, 0xFA03E8 in sub_FA000B__FA0329
;          0xFA04E6 in sub_FA000B__FA0427, 0xFA0603 in sub_FA000B__FA053A
;          0xFA0701 in sub_FA000B__FA0642, 0xFA07FF in sub_FA000B__FA0740
;          0xFA0912 in sub_FA000B__FA0853, 0xFA11A7 in sub_FA000B__FA111E
;          0xFA1268 in sub_FA000B__FA11E6, 0xFA13CA in sub_FA000B__FA12AF
;          0xFA1AAC in sub_FA000B__FA1A6D, 0xFA1CE5 in sub_FA000B__FA1C11
;          0xFA1E28 in sub_FA000B__FA1D39, 0xFA1F6B in sub_FA000B__FA1E7C
;          0xFA20AE in sub_FA000B__FA1FBF, 0xFA21C9 in sub_FA000B__FA2102
; Inputs:  frame `link XIZ,-24`; argument slots read: (XIZ+0x08), (XIZ+0x0C), (XIZ+0x10), (XIZ+0x14)
; Outputs: writes 0x00F362
;          reads 0xFCB3B6, 0xFCB3BA, 0xFCB3BE, 0xFCB3C2, 0xFCB3C6, 0xFCB3CA, 0xFCB3CE, 0xFCB3D2, 0xFCB3D6, 0xFCB3DA, 0xFCB3DE, 0xFCB3E2
; Calls:   0xFC8EE5 = sub_FC8EE5, 0xFC9844 = sub_FC9844
;          0xFC9CCD = sub_FC9CCD, 0xFC9D12 = sub_FC9D12
;          0xFCA085 = sub_FCA085, 0xFCA121 = Double_Compare
;          0xFCA1B6 = Double_Negate, 0xFCA1E5 = Double_Classify
;          0xFCA252 = Double_Multiply, 0xFCA661 = Double_ToInt32
;          0xFCA6FD = Int32_ToDouble, 0xFCA7A5 = Double_Divide
; Evidence: the listing below is the byte-identical round-trip of 0xFC9576-0xFC9843
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC9576:
	link32 0xEE, 0x0C, 0xE8, 0xFF              ; FC9576  link XIZ,0xffe8
	push	xix                                   ; FC957A  push XIX
	push	xiy                                   ; FC957B  push XIY
	ld	xbc, (0xFCB3E2:24)                     ; FC957C  ld XBC,(0xfcb3e2)
	push	xbc                                   ; FC9581  push XBC
	ld	xbc, (0xFCB3DE:24)                     ; FC9582  ld XBC,(0xfcb3de)
	push	xbc                                   ; FC9587  push XBC
	ld	xbc, (xiz+20)                           ; FC9588  ld XBC,(XIZ+0x14)
	push	xbc                                   ; FC958B  push XBC
	ld	xbc, (xiz+16)                           ; FC958C  ld XBC,(XIZ+0x10)
	push	xbc                                   ; FC958F  push XBC
	call	0xFCA121                              ; FC9590  call 0xfca121
	cps	wa, 0                                  ; FC9594  cp WA,0
	jrl z, sub_FC9576__FC9832                  ; FC9596  jrl Z,0xfc9832
	ld	xbc, (xiz+12)                           ; FC9599  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC959C  push XBC
	ld	xbc, (xiz+8)                            ; FC959D  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC95A0  push XBC
	call	0xFCA1E5                              ; FC95A1  call 0xfca1e5
	cps	wa, 0                                  ; FC95A5  cp WA,0
	jr nz, sub_FC9576__FC95C9                  ; FC95A7  jr NZ,0xfc95c9
	ld	xbc, (0xFCB3DA:24)                     ; FC95A9  ld XBC,(0xfcb3da)
	push	xbc                                   ; FC95AE  push XBC
	ld	xbc, (0xFCB3D6:24)                     ; FC95AF  ld XBC,(0xfcb3d6)
	push	xbc                                   ; FC95B4  push XBC
	ld	xbc, (xiz+20)                           ; FC95B5  ld XBC,(XIZ+0x14)
	push	xbc                                   ; FC95B8  push XBC
	ld	xbc, (xiz+16)                           ; FC95B9  ld XBC,(XIZ+0x10)
	push	xbc                                   ; FC95BC  push XBC
	call	0xFCA121                              ; FC95BD  call 0xfca121
	cps	wa, 1                                  ; FC95C1  cp WA,1
	jrl nz, sub_FC9576__FC969C                 ; FC95C3  jrl NZ,0xfc969c
	jrl sub_FC9576__FC9832                     ; FC95C6  jrl T,0xfc9832
sub_FC9576__FC95C9:
	ld	xix, 0                                  ; FC95C9  ld XIX,0x00000000
	ld	xbc, (0xFCB3DA:24)                     ; FC95CE  ld XBC,(0xfcb3da)
	push	xbc                                   ; FC95D3  push XBC
	ld	xbc, (0xFCB3D6:24)                     ; FC95D4  ld XBC,(0xfcb3d6)
	push	xbc                                   ; FC95D9  push XBC
	ld	xbc, (xiz+12)                           ; FC95DA  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC95DD  push XBC
	ld	xbc, (xiz+8)                            ; FC95DE  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC95E1  push XBC
	call	0xFCA121                              ; FC95E2  call 0xfca121
	cps	wa, 2                                  ; FC95E6  cp WA,2
	jrl nz, sub_FC9576__FC96BC                 ; FC95E8  jrl NZ,0xfc96bc
	ld	xbc, (xiz+20)                           ; FC95EB  ld XBC,(XIZ+0x14)
	push	xbc                                   ; FC95EE  push XBC
	ld	xbc, (xiz+16)                           ; FC95EF  ld XBC,(XIZ+0x10)
	push	xbc                                   ; FC95F2  push XBC
	lda	xiy, (xiz-16)                          ; FC95F3  lda XIY,XIZ+0xf0
	call	0xFCA085                              ; FC95F6  call 0xfca085
	inc	8, xsp                                 ; FC95FA  inc 0,XSP
	ld	xbc, (0xFCB3D2:24)                     ; FC95FC  ld XBC,(0xfcb3d2)
	push	xbc                                   ; FC9601  push XBC
	ld	xbc, (0xFCB3CE:24)                     ; FC9602  ld XBC,(0xfcb3ce)
	push	xbc                                   ; FC9607  push XBC
	ld	xbc, (xiz-12)                           ; FC9608  ld XBC,(XIZ+0xf4)
	push	xbc                                   ; FC960B  push XBC
	ld	xbc, (xiz-16)                           ; FC960C  ld XBC,(XIZ+0xf0)
	push	xbc                                   ; FC960F  push XBC
	call	0xFCA121                              ; FC9610  call 0xfca121
	cps	wa, 1                                  ; FC9614  cp WA,1
	jr z, sub_FC9576__FC964E                   ; FC9616  jr Z,0xfc964e
	ld	xbc, (xiz+20)                           ; FC9618  ld XBC,(XIZ+0x14)
	push	xbc                                   ; FC961B  push XBC
	ld	xbc, (xiz+16)                           ; FC961C  ld XBC,(XIZ+0x10)
	push	xbc                                   ; FC961F  push XBC
	call	0xFCA661                              ; FC9620  call 0xfca661
	ld	xix, xiy                                ; FC9624  ld XIX,XIY
	push	xiy                                   ; FC9626  push XIY
	lda	xiy, (xiz-16)                          ; FC9627  lda XIY,XIZ+0xf0
	call	0xFCA6FD                              ; FC962A  call 0xfca6fd
	ld	xbc, (xiz-12)                           ; FC962E  ld XBC,(XIZ+0xf4)
	push	xbc                                   ; FC9631  push XBC
	ld	xbc, (xiz-16)                           ; FC9632  ld XBC,(XIZ+0xf0)
	push	xbc                                   ; FC9635  push XBC
	ld	xbc, (xiz+20)                           ; FC9636  ld XBC,(XIZ+0x14)
	push	xbc                                   ; FC9639  push XBC
	ld	xbc, (xiz+16)                           ; FC963A  ld XBC,(XIZ+0x10)
	push	xbc                                   ; FC963D  push XBC
	call	0xFCA121                              ; FC963E  call 0xfca121
	cps	wa, 0                                  ; FC9642  cp WA,0
	jr nz, sub_FC9576__FC969C                  ; FC9644  jr NZ,0xfc969c
	sub	xbc, xbc                               ; FC9646  sub XBC,XBC
	inc	1, xbc                                 ; FC9648  inc 1,XBC
	and	xix, xbc                               ; FC964A  and XIX,XBC
	jr sub_FC9576__FC96AB                      ; FC964C  jr T,0xfc96ab
sub_FC9576__FC964E:
	lda	xbc, (xiz-8)                           ; FC964E  lda XBC,XIZ+0xf8
	push	xbc                                   ; FC9651  push XBC
	ld	xwa, (xiz+20)                           ; FC9652  ld XWA,(XIZ+0x14)
	push	xwa                                   ; FC9655  push XWA
	ld	xwa, (xiz+16)                           ; FC9656  ld XWA,(XIZ+0x10)
	push	xwa                                   ; FC9659  push XWA
	ld	xwa, (0xFCB3CA:24)                     ; FC965A  ld XWA,(0xfcb3ca)
	push	xwa                                   ; FC965F  push XWA
	ld	xwa, (0xFCB3C6:24)                     ; FC9660  ld XWA,(0xfcb3c6)
	push	xwa                                   ; FC9665  push XWA
	lda	xiy, (xiz-16)                          ; FC9666  lda XIY,XIZ+0xf0
	call	0xFCA252                              ; FC9669  call 0xfca252
	ld	xbc, (xiz-12)                           ; FC966D  ld XBC,(XIZ+0xf4)
	push	xbc                                   ; FC9670  push XBC
	ld	xbc, (xiz-16)                           ; FC9671  ld XBC,(XIZ+0xf0)
	push	xbc                                   ; FC9674  push XBC
	lda	xiy, (xiz-24)                          ; FC9675  lda XIY,XIZ+0xe8
	call	0xFC8EE5                              ; FC9678  call 0xfc8ee5
	inc	8, xsp                                 ; FC967C  inc 0,XSP
	inc	4, xsp                                 ; FC967E  inc 4,XSP
	ld	xbc, (0xFCB3CA:24)                     ; FC9680  ld XBC,(0xfcb3ca)
	push	xbc                                   ; FC9685  push XBC
	ld	xbc, (0xFCB3C6:24)                     ; FC9686  ld XBC,(0xfcb3c6)
	push	xbc                                   ; FC968B  push XBC
	ld	xbc, (xiz-20)                           ; FC968C  ld XBC,(XIZ+0xec)
	push	xbc                                   ; FC968F  push XBC
	ld	xbc, (xiz-24)                           ; FC9690  ld XBC,(XIZ+0xe8)
	push	xbc                                   ; FC9693  push XBC
	call	0xFCA121                              ; FC9694  call 0xfca121
	cps	wa, 0                                  ; FC9698  cp WA,0
	jr z, sub_FC9576__FC96A6                   ; FC969A  jr Z,0xfc96a6
sub_FC9576__FC969C:
	ldw	(0xF362:24), 33                       ; FC969C  ld (0x00f362),0x0021
	jrl sub_FC9576__FC97CF                     ; FC96A3  jrl T,0xfc97cf
sub_FC9576__FC96A6:
	ld	xix, 1                                  ; FC96A6  ld XIX,0x00000001
sub_FC9576__FC96AB:
	ld	xbc, (xiz+12)                           ; FC96AB  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC96AE  push XBC
	ld	xbc, (xiz+8)                            ; FC96AF  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC96B2  push XBC
	lda	xiy, (xiz+8)                           ; FC96B3  lda XIY,XIZ+0x08
	call	0xFCA085                              ; FC96B6  call 0xfca085
	inc	8, xsp                                 ; FC96BA  inc 0,XSP
sub_FC9576__FC96BC:
	ld	xbc, (0xFCB3E2:24)                     ; FC96BC  ld XBC,(0xfcb3e2)
	push	xbc                                   ; FC96C1  push XBC
	ld	xbc, (0xFCB3DE:24)                     ; FC96C2  ld XBC,(0xfcb3de)
	push	xbc                                   ; FC96C7  push XBC
	ld	xbc, (xiz+12)                           ; FC96C8  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC96CB  push XBC
	ld	xbc, (xiz+8)                            ; FC96CC  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC96CF  push XBC
	call	0xFCA121                              ; FC96D0  call 0xfca121
	cps	wa, 0                                  ; FC96D4  cp WA,0
	jrl z, sub_FC9576__FC980E                  ; FC96D6  jrl Z,0xfc980e
	ld	xbc, (xiz+12)                           ; FC96D9  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC96DC  push XBC
	ld	xbc, (xiz+8)                            ; FC96DD  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC96E0  push XBC
	lda	xiy, (xiz-16)                          ; FC96E1  lda XIY,XIZ+0xf0
	call	0xFC9D12                              ; FC96E4  call 0xfc9d12
	ld	xbc, (xiz-16)                           ; FC96E8  ld XBC,(XIZ+0xf0)
	ld	(xiz+8), xbc                            ; FC96EB  ld (XIZ+0x08),XBC
	ld	xbc, (xiz-12)                           ; FC96EE  ld XBC,(XIZ+0xf4)
	ld	(xiz+12), xbc                           ; FC96F1  ld (XIZ+0x0c),XBC
	inc	8, xsp                                 ; FC96F4  inc 0,XSP
	ld	xbc, (0xFCB3DA:24)                     ; FC96F6  ld XBC,(0xfcb3da)
	push	xbc                                   ; FC96FB  push XBC
	ld	xbc, (0xFCB3D6:24)                     ; FC96FC  ld XBC,(0xfcb3d6)
	push	xbc                                   ; FC9701  push XBC
	ld	xbc, (xiz-12)                           ; FC9702  ld XBC,(XIZ+0xf4)
	push	xbc                                   ; FC9705  push XBC
	ld	xbc, (xiz-16)                           ; FC9706  ld XBC,(XIZ+0xf0)
	push	xbc                                   ; FC9709  push XBC
	call	0xFCA121                              ; FC970A  call 0xfca121
	cps	wa, 2                                  ; FC970E  cp WA,2
	jr nz, sub_FC9576__FC9730                  ; FC9710  jr NZ,0xfc9730
	ld	xbc, (xiz+12)                           ; FC9712  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC9715  push XBC
	ld	xbc, (xiz+8)                            ; FC9716  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC9719  push XBC
	lda	xiy, (xiz+8)                           ; FC971A  lda XIY,XIZ+0x08
	call	0xFCA1B6                              ; FC971D  call 0xfca1b6
	ld	xbc, (xiz+20)                           ; FC9721  ld XBC,(XIZ+0x14)
	push	xbc                                   ; FC9724  push XBC
	ld	xbc, (xiz+16)                           ; FC9725  ld XBC,(XIZ+0x10)
	push	xbc                                   ; FC9728  push XBC
	lda	xiy, (xiz+16)                          ; FC9729  lda XIY,XIZ+0x10
	call	0xFCA1B6                              ; FC972C  call 0xfca1b6
sub_FC9576__FC9730:
	ld	xbc, (xiz+12)                           ; FC9730  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC9733  push XBC
	ld	xbc, (xiz+8)                            ; FC9734  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC9737  push XBC
	ld	xbc, (0xFCB3C2:24)                     ; FC9738  ld XBC,(0xfcb3c2)
	push	xbc                                   ; FC973D  push XBC
	ld	xbc, (0xFCB3BE:24)                     ; FC973E  ld XBC,(0xfcb3be)
	push	xbc                                   ; FC9743  push XBC
	lda	xiy, (xiz-16)                          ; FC9744  lda XIY,XIZ+0xf0
	call	0xFCA7A5                              ; FC9747  call 0xfca7a5
	ld	xbc, (xiz-12)                           ; FC974B  ld XBC,(XIZ+0xf4)
	push	xbc                                   ; FC974E  push XBC
	ld	xbc, (xiz-16)                           ; FC974F  ld XBC,(XIZ+0xf0)
	push	xbc                                   ; FC9752  push XBC
	ld	xbc, (xiz+20)                           ; FC9753  ld XBC,(XIZ+0x14)
	push	xbc                                   ; FC9756  push XBC
	ld	xbc, (xiz+16)                           ; FC9757  ld XBC,(XIZ+0x10)
	push	xbc                                   ; FC975A  push XBC
	call	0xFCA121                              ; FC975B  call 0xfca121
	cps	wa, 1                                  ; FC975F  cp WA,1
	jrl z, sub_FC9576__FC97E2                  ; FC9761  jrl Z,0xfc97e2
	ld	xbc, (xiz+12)                           ; FC9764  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC9767  push XBC
	ld	xbc, (xiz+8)                            ; FC9768  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC976B  push XBC
	ld	xbc, (0xFCB3BA:24)                     ; FC976C  ld XBC,(0xfcb3ba)
	push	xbc                                   ; FC9771  push XBC
	ld	xbc, (0xFCB3B6:24)                     ; FC9772  ld XBC,(0xfcb3b6)
	push	xbc                                   ; FC9777  push XBC
	lda	xiy, (xiz-16)                          ; FC9778  lda XIY,XIZ+0xf0
	call	0xFCA7A5                              ; FC977B  call 0xfca7a5
	ld	xbc, (xiz-12)                           ; FC977F  ld XBC,(XIZ+0xf4)
	push	xbc                                   ; FC9782  push XBC
	ld	xbc, (xiz-16)                           ; FC9783  ld XBC,(XIZ+0xf0)
	push	xbc                                   ; FC9786  push XBC
	ld	xbc, (xiz+20)                           ; FC9787  ld XBC,(XIZ+0x14)
	push	xbc                                   ; FC978A  push XBC
	ld	xbc, (xiz+16)                           ; FC978B  ld XBC,(XIZ+0x10)
	push	xbc                                   ; FC978E  push XBC
	call	0xFCA121                              ; FC978F  call 0xfca121
	cps	wa, 2                                  ; FC9793  cp WA,2
	jr z, sub_FC9576__FC97C8                   ; FC9795  jr Z,0xfc97c8
	ld	xbc, (xiz+12)                           ; FC9797  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC979A  push XBC
	ld	xbc, (xiz+8)                            ; FC979B  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC979E  push XBC
	ld	xbc, (xiz+20)                           ; FC979F  ld XBC,(XIZ+0x14)
	push	xbc                                   ; FC97A2  push XBC
	ld	xbc, (xiz+16)                           ; FC97A3  ld XBC,(XIZ+0x10)
	push	xbc                                   ; FC97A6  push XBC
	lda	xiy, (xiz-16)                          ; FC97A7  lda XIY,XIZ+0xf0
	call	0xFCA252                              ; FC97AA  call 0xfca252
	ld	xbc, (xiz-12)                           ; FC97AE  ld XBC,(XIZ+0xf4)
	push	xbc                                   ; FC97B1  push XBC
	ld	xbc, (xiz-16)                           ; FC97B2  ld XBC,(XIZ+0xf0)
	push	xbc                                   ; FC97B5  push XBC
	lda	xiy, (xiz+8)                           ; FC97B6  lda XIY,XIZ+0x08
	call	0xFC9844                              ; FC97B9  call 0xfc9844
	inc	8, xsp                                 ; FC97BD  inc 0,XSP
	ld	xbc, xix                                ; FC97BF  ld XBC,XIX
	or	xbc, xbc                                ; FC97C1  or XBC,XBC
	jrl z, sub_FC9576__FC9832                  ; FC97C3  jrl Z,0xfc9832
	jr sub_FC9576__FC9814                      ; FC97C6  jr T,0xfc9814
sub_FC9576__FC97C8:
	ldw	(0xF362:24), 34                       ; FC97C8  ld (0x00f362),0x0022
sub_FC9576__FC97CF:
	ld	xiy, (xsp)                              ; FC97CF  ld XIY,(XSP)
	ld	xix, (0xFCB3D6:24)                     ; FC97D1  ld XIX,(0xfcb3d6)
	stl_dpi	xix, 0xF6                          ; FC97D6  ld (XIY+),XIX
	ld	xix, (0xFCB3DA:24)                     ; FC97D9  ld XIX,(0xfcb3da)
	ld	(xiy), xix                              ; FC97DE  ld (XIY),XIX
	jr sub_FC9576__FC983F                      ; FC97E0  jr T,0xfc983f
sub_FC9576__FC97E2:
	ldw	(0xF362:24), 34                       ; FC97E2  ld (0x00f362),0x0022
	ld	xbc, xix                                ; FC97E9  ld XBC,XIX
	or	xbc, xbc                                ; FC97EB  or XBC,XBC
	jr z, sub_FC9576__FC97F4                   ; FC97ED  jr Z,0xfc97f4
	pushw	1                                    ; FC97EF  push 0x0001
	jr sub_FC9576__FC97F7                      ; FC97F2  jr T,0xfc97f7
sub_FC9576__FC97F4:
	pushw	0                                    ; FC97F4  push 0x0000
sub_FC9576__FC97F7:
	lda	xiy, (xiz-16)                          ; FC97F7  lda XIY,XIZ+0xf0
	call	0xFC9CCD                              ; FC97FA  call 0xfc9ccd
	popw	bc                                    ; FC97FE  pop BC
	ld	xiy, (xsp)                              ; FC97FF  ld XIY,(XSP)
	ld	xix, (xiz-16)                           ; FC9801  ld XIX,(XIZ+0xf0)
	stl_dpi	xix, 0xF6                          ; FC9804  ld (XIY+),XIX
	ld	xix, (xiz-12)                           ; FC9807  ld XIX,(XIZ+0xf4)
	ld	(xiy), xix                              ; FC980A  ld (XIY),XIX
	jr sub_FC9576__FC983F                      ; FC980C  jr T,0xfc983f
sub_FC9576__FC980E:
	ld	xbc, xix                                ; FC980E  ld XBC,XIX
	or	xbc, xbc                                ; FC9810  or XBC,XBC
	jr z, sub_FC9576__FC9832                   ; FC9812  jr Z,0xfc9832
sub_FC9576__FC9814:
	ld	xbc, (xiz+12)                           ; FC9814  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC9817  push XBC
	ld	xbc, (xiz+8)                            ; FC9818  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC981B  push XBC
	lda	xiy, (xiz-16)                          ; FC981C  lda XIY,XIZ+0xf0
	call	0xFCA1B6                              ; FC981F  call 0xfca1b6
	ld	xiy, (xsp)                              ; FC9823  ld XIY,(XSP)
	ld	xix, (xiz-16)                           ; FC9825  ld XIX,(XIZ+0xf0)
	stl_dpi	xix, 0xF6                          ; FC9828  ld (XIY+),XIX
	ld	xix, (xiz-12)                           ; FC982B  ld XIX,(XIZ+0xf4)
	ld	(xiy), xix                              ; FC982E  ld (XIY),XIX
	jr sub_FC9576__FC983F                      ; FC9830  jr T,0xfc983f
sub_FC9576__FC9832:
	ld	xiy, (xsp)                              ; FC9832  ld XIY,(XSP)
	ld	xix, (xiz+8)                            ; FC9834  ld XIX,(XIZ+0x08)
	stl_dpi	xix, 0xF6                          ; FC9837  ld (XIY+),XIX
	ld	xix, (xiz+12)                           ; FC983A  ld XIX,(XIZ+0x0c)
	ld	(xiy), xix                              ; FC983D  ld (XIY),XIX
sub_FC9576__FC983F:
	pop	xiy                                    ; FC983F  pop XIY
	pop	xix                                    ; FC9840  pop XIX
	unlk32 xiz                                 ; FC9841  unlk XIZ
	ret                                        ; FC9843  ret
; --------------------------------------------------------------------------
; sub_FC9844 -- 0xFC9844..0xFC9ACA (647 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFC97B9
; Inputs:  frame `link XIZ,-50`; argument slots read: (XIZ+0x08), (XIZ+0x0C)
; Outputs: writes 0x00F362
;          reads 0xFCB3E6, 0xFCB3EA, 0xFCB3EE, 0xFCB3F2, 0xFCB3F6, 0xFCB3FA, 0xFCB3FE, 0xFCB402, 0xFCB406, 0xFCB40A, 0xFCB40E, 0xFCB412, 0xFCB416, 0xFCB41A, 0xFCB41E, 0xFCB422, 0xFCB426, 0xFCB42A, 0xFCB42E, 0xFCB432
; Calls:   0xFC9CCD = sub_FC9CCD, 0xFCA121 = Double_Compare
;          0xFCA1B6 = Double_Negate, 0xFCA252 = Double_Multiply
;          0xFCA41F = Double_Add, 0xFCA626 = Double_Subtract
;          0xFCA903 = Double_ToInt16, 0xFCA997 = Int16_ToDouble
; Evidence: the listing below is the byte-identical round-trip of 0xFC9844-0xFC9ACA
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC9844:
	link32 0xEE, 0x0C, 0xCE, 0xFF              ; FC9844  link XIZ,0xffce
	pushw	hl                                   ; FC9848  push HL
	pushw	de                                   ; FC9849  push DE
	push	xix                                   ; FC984A  push XIX
	push	xiy                                   ; FC984B  push XIY
	ld	xbc, (0xFCB432:24)                     ; FC984C  ld XBC,(0xfcb432)
	push	xbc                                   ; FC9851  push XBC
	ld	xbc, (0xFCB42E:24)                     ; FC9852  ld XBC,(0xfcb42e)
	push	xbc                                   ; FC9857  push XBC
	ld	xbc, (xiz+12)                           ; FC9858  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC985B  push XBC
	ld	xbc, (xiz+8)                            ; FC985C  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC985F  push XBC
	call	0xFCA121                              ; FC9860  call 0xfca121
	cps	wa, 1                                  ; FC9864  cp WA,1
	jr z, sub_FC9844__FC98B3                   ; FC9866  jr Z,0xfc98b3
	ld	xbc, (0xFCB432:24)                     ; FC9868  ld XBC,(0xfcb432)
	push	xbc                                   ; FC986D  push XBC
	ld	xbc, (0xFCB42E:24)                     ; FC986E  ld XBC,(0xfcb42e)
	push	xbc                                   ; FC9873  push XBC
	ld	xbc, (xiz+12)                           ; FC9874  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC9877  push XBC
	ld	xbc, (xiz+8)                            ; FC9878  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC987B  push XBC
	call	0xFCA121                              ; FC987C  call 0xfca121
	cps	wa, 0                                  ; FC9880  cp WA,0
	jr nz, sub_FC9844__FC9898                  ; FC9882  jr NZ,0xfc9898
	ld	xiy, (xsp)                              ; FC9884  ld XIY,(XSP)
	ld	xix, (0xFCB426:24)                     ; FC9886  ld XIX,(0xfcb426)
	stl_dpi	xix, 0xF6                          ; FC988B  ld (XIY+),XIX
	ld	xix, (0xFCB42A:24)                     ; FC988E  ld XIX,(0xfcb42a)
	ld	(xiy), xix                              ; FC9893  ld (XIY),XIX
	jrl sub_FC9ACB__FC9BB5                     ; FC9895  jrl T,0xfc9bb5
sub_FC9844__FC9898:
	ldw	(0xF362:24), 34                       ; FC9898  ld (0x00f362),0x0022
	ld	xiy, (xsp)                              ; FC989F  ld XIY,(XSP)
	ld	xix, (0xFCB41E:24)                     ; FC98A1  ld XIX,(0xfcb41e)
	stl_dpi	xix, 0xF6                          ; FC98A6  ld (XIY+),XIX
	ld	xix, (0xFCB422:24)                     ; FC98A9  ld XIX,(0xfcb422)
	ld	(xiy), xix                              ; FC98AE  ld (XIY),XIX
	jrl sub_FC9ACB__FC9BB5                     ; FC98B0  jrl T,0xfc9bb5
sub_FC9844__FC98B3:
	ld	xbc, (0xFCB41A:24)                     ; FC98B3  ld XBC,(0xfcb41a)
	push	xbc                                   ; FC98B8  push XBC
	ld	xbc, (0xFCB416:24)                     ; FC98B9  ld XBC,(0xfcb416)
	push	xbc                                   ; FC98BE  push XBC
	ld	xbc, (xiz+12)                           ; FC98BF  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC98C2  push XBC
	ld	xbc, (xiz+8)                            ; FC98C3  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC98C6  push XBC
	call	0xFCA121                              ; FC98C7  call 0xfca121
	cps	wa, 2                                  ; FC98CB  cp WA,2
	jr z, sub_FC9844__FC9921                   ; FC98CD  jr Z,0xfc9921
	ld	xbc, (0xFCB41A:24)                     ; FC98CF  ld XBC,(0xfcb41a)
	push	xbc                                   ; FC98D4  push XBC
	ld	xbc, (0xFCB416:24)                     ; FC98D5  ld XBC,(0xfcb416)
	push	xbc                                   ; FC98DA  push XBC
	ld	xbc, (xiz+12)                           ; FC98DB  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC98DE  push XBC
	ld	xbc, (xiz+8)                            ; FC98DF  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC98E2  push XBC
	call	0xFCA121                              ; FC98E3  call 0xfca121
	cps	wa, 0                                  ; FC98E7  cp WA,0
	jr nz, sub_FC9844__FC98FF                  ; FC98E9  jr NZ,0xfc98ff
	ld	xiy, (xsp)                              ; FC98EB  ld XIY,(XSP)
	ld	xix, (0xFCB40E:24)                     ; FC98ED  ld XIX,(0xfcb40e)
	stl_dpi	xix, 0xF6                          ; FC98F2  ld (XIY+),XIX
	ld	xix, (0xFCB412:24)                     ; FC98F5  ld XIX,(0xfcb412)
	ld	(xiy), xix                              ; FC98FA  ld (XIY),XIX
	jrl sub_FC9ACB__FC9BB5                     ; FC98FC  jrl T,0xfc9bb5
sub_FC9844__FC98FF:
	ldw	(0xF362:24), 34                       ; FC98FF  ld (0x00f362),0x0022
	pushw	0                                    ; FC9906  push 0x0000
	lda	xiy, (xiz-26)                          ; FC9909  lda XIY,XIZ+0xe6
	call	0xFC9CCD                              ; FC990C  call 0xfc9ccd
	popw	bc                                    ; FC9910  pop BC
	ld	xiy, (xsp)                              ; FC9911  ld XIY,(XSP)
	ld	xix, (xiz-26)                           ; FC9913  ld XIX,(XIZ+0xe6)
	stl_dpi	xix, 0xF6                          ; FC9916  ld (XIY+),XIX
	ld	xix, (xiz-22)                           ; FC9919  ld XIX,(XIZ+0xea)
	ld	(xiy), xix                              ; FC991C  ld (XIY),XIX
	jrl sub_FC9ACB__FC9BB5                     ; FC991E  jrl T,0xfc9bb5
sub_FC9844__FC9921:
	ldw	hl, 0                                  ; FC9921  ld HL,0x0000
	ld	xbc, (0xFCB422:24)                     ; FC9924  ld XBC,(0xfcb422)
	push	xbc                                   ; FC9929  push XBC
	ld	xbc, (0xFCB41E:24)                     ; FC992A  ld XBC,(0xfcb41e)
	push	xbc                                   ; FC992F  push XBC
	ld	xbc, (xiz+12)                           ; FC9930  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC9933  push XBC
	ld	xbc, (xiz+8)                            ; FC9934  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC9937  push XBC
	call	0xFCA121                              ; FC9938  call 0xfca121
	cps	wa, 2                                  ; FC993C  cp WA,2
	jr nz, sub_FC9844__FC9943                  ; FC993E  jr NZ,0xfc9943
	ldw	hl, 1                                  ; FC9940  ld HL,0x0001
sub_FC9844__FC9943:
	ld	de, hl                                  ; FC9943  ld DE,HL
	cps	hl, 0                                  ; FC9945  cp HL,0
	jr z, sub_FC9844__FC9958                   ; FC9947  jr Z,0xfc9958
	ld	xbc, (xiz+12)                           ; FC9949  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC994C  push XBC
	ld	xbc, (xiz+8)                            ; FC994D  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC9950  push XBC
	lda	xiy, (xiz+8)                           ; FC9951  lda XIY,XIZ+0x08
	call	0xFCA1B6                              ; FC9954  call 0xfca1b6
sub_FC9844__FC9958:
	ld	xbc, (0xFCB40A:24)                     ; FC9958  ld XBC,(0xfcb40a)
	push	xbc                                   ; FC995D  push XBC
	ld	xbc, (0xFCB406:24)                     ; FC995E  ld XBC,(0xfcb406)
	push	xbc                                   ; FC9963  push XBC
	ld	xbc, (xiz+12)                           ; FC9964  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC9967  push XBC
	ld	xbc, (xiz+8)                            ; FC9968  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC996B  push XBC
	call	0xFCA121                              ; FC996C  call 0xfca121
	cps	wa, 2                                  ; FC9970  cp WA,2
	jr nz, sub_FC9844__FC99CE                  ; FC9972  jr NZ,0xfc99ce
	cps	de, 0                                  ; FC9974  cp DE,0
	jr z, sub_FC9844__FC99A3                   ; FC9976  jr Z,0xfc99a3
	ld	xbc, (xiz+12)                           ; FC9978  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC997B  push XBC
	ld	xbc, (xiz+8)                            ; FC997C  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC997F  push XBC
	ld	xbc, (0xFCB402:24)                     ; FC9980  ld XBC,(0xfcb402)
	push	xbc                                   ; FC9985  push XBC
	ld	xbc, (0xFCB3FE:24)                     ; FC9986  ld XBC,(0xfcb3fe)
	push	xbc                                   ; FC998B  push XBC
	lda	xiy, (xiz-26)                          ; FC998C  lda XIY,XIZ+0xe6
	call	0xFCA626                              ; FC998F  call 0xfca626
	ld	xiy, (xsp)                              ; FC9993  ld XIY,(XSP)
	ld	xix, (xiz-26)                           ; FC9995  ld XIX,(XIZ+0xe6)
	stl_dpi	xix, 0xF6                          ; FC9998  ld (XIY+),XIX
	ld	xix, (xiz-22)                           ; FC999B  ld XIX,(XIZ+0xea)
	ld	(xiy), xix                              ; FC999E  ld (XIY),XIX
	jrl sub_FC9ACB__FC9BB5                     ; FC99A0  jrl T,0xfc9bb5
sub_FC9844__FC99A3:
	ld	xbc, (0xFCB402:24)                     ; FC99A3  ld XBC,(0xfcb402)
	push	xbc                                   ; FC99A8  push XBC
	ld	xbc, (0xFCB3FE:24)                     ; FC99A9  ld XBC,(0xfcb3fe)
	push	xbc                                   ; FC99AE  push XBC
	ld	xbc, (xiz+12)                           ; FC99AF  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC99B2  push XBC
	ld	xbc, (xiz+8)                            ; FC99B3  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC99B6  push XBC
	lda	xiy, (xiz-26)                          ; FC99B7  lda XIY,XIZ+0xe6
	call	0xFCA41F                              ; FC99BA  call 0xfca41f
	ld	xiy, (xsp)                              ; FC99BE  ld XIY,(XSP)
	ld	xix, (xiz-26)                           ; FC99C0  ld XIX,(XIZ+0xe6)
	stl_dpi	xix, 0xF6                          ; FC99C3  ld (XIY+),XIX
	ld	xix, (xiz-22)                           ; FC99C6  ld XIX,(XIZ+0xea)
	ld	(xiy), xix                              ; FC99C9  ld (XIY),XIX
	jrl sub_FC9ACB__FC9BB5                     ; FC99CB  jrl T,0xfc9bb5
sub_FC9844__FC99CE:
	ld	xbc, (xiz+12)                           ; FC99CE  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC99D1  push XBC
	ld	xbc, (xiz+8)                            ; FC99D2  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC99D5  push XBC
	ld	xbc, (0xFCB3FA:24)                     ; FC99D6  ld XBC,(0xfcb3fa)
	push	xbc                                   ; FC99DB  push XBC
	ld	xbc, (0xFCB3F6:24)                     ; FC99DC  ld XBC,(0xfcb3f6)
	push	xbc                                   ; FC99E1  push XBC
	lda	xiy, (xiz-26)                          ; FC99E2  lda XIY,XIZ+0xe6
	call	0xFCA252                              ; FC99E5  call 0xfca252
	ld	xbc, (0xFCB3F2:24)                     ; FC99E9  ld XBC,(0xfcb3f2)
	push	xbc                                   ; FC99EE  push XBC
	ld	xbc, (0xFCB3EE:24)                     ; FC99EF  ld XBC,(0xfcb3ee)
	push	xbc                                   ; FC99F4  push XBC
	ld	xbc, (xiz-22)                           ; FC99F5  ld XBC,(XIZ+0xea)
	push	xbc                                   ; FC99F8  push XBC
	ld	xbc, (xiz-26)                           ; FC99F9  ld XBC,(XIZ+0xe6)
	push	xbc                                   ; FC99FC  push XBC
	lda	xiy, (xiz-34)                          ; FC99FD  lda XIY,XIZ+0xde
	call	0xFCA41F                              ; FC9A00  call 0xfca41f
	ld	xbc, (xiz-30)                           ; FC9A04  ld XBC,(XIZ+0xe2)
	push	xbc                                   ; FC9A07  push XBC
	ld	xbc, (xiz-34)                           ; FC9A08  ld XBC,(XIZ+0xde)
	push	xbc                                   ; FC9A0B  push XBC
	call	0xFCA903                              ; FC9A0C  call 0xfca903
	ld	(xiz-2), wa                             ; FC9A10  ld (XIZ+0xfe),WA
	pushw	wa                                   ; FC9A13  push WA
	lda	xiy, (xiz-42)                          ; FC9A14  lda XIY,XIZ+0xd6
	call	0xFCA997                              ; FC9A17  call 0xfca997
	ld	xbc, (xiz-38)                           ; FC9A1B  ld XBC,(XIZ+0xda)
	push	xbc                                   ; FC9A1E  push XBC
	ld	xbc, (xiz-42)                           ; FC9A1F  ld XBC,(XIZ+0xd6)
	push	xbc                                   ; FC9A22  push XBC
	ld	xbc, (0xFCB3EA:24)                     ; FC9A23  ld XBC,(0xfcb3ea)
	push	xbc                                   ; FC9A28  push XBC
	ld	xbc, (0xFCB3E6:24)                     ; FC9A29  ld XBC,(0xfcb3e6)
	push	xbc                                   ; FC9A2E  push XBC
	lda	xiy, (xiz-50)                          ; FC9A2F  lda XIY,XIZ+0xce
	call	0xFCA252                              ; FC9A32  call 0xfca252
	ld	xbc, (xiz-46)                           ; FC9A36  ld XBC,(XIZ+0xd2)
	push	xbc                                   ; FC9A39  push XBC
	ld	xbc, (xiz-50)                           ; FC9A3A  ld XBC,(XIZ+0xce)
	push	xbc                                   ; FC9A3D  push XBC
	ld	xbc, (xiz+12)                           ; FC9A3E  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC9A41  push XBC
	ld	xbc, (xiz+8)                            ; FC9A42  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC9A45  push XBC
	lda	xiy, (xiz+8)                           ; FC9A46  lda XIY,XIZ+0x08
	call	0xFCA626                              ; FC9A49  call 0xfca626
	cps	de, 0                                  ; FC9A4D  cp DE,0
	jr z, sub_FC9844__FC9A68                   ; FC9A4F  jr Z,0xfc9a68
	ld	xbc, (xiz+12)                           ; FC9A51  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC9A54  push XBC
	ld	xbc, (xiz+8)                            ; FC9A55  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC9A58  push XBC
	lda	xiy, (xiz+8)                           ; FC9A59  lda XIY,XIZ+0x08
	call	0xFCA1B6                              ; FC9A5C  call 0xfca1b6
	ld	bc, (xiz-2)                             ; FC9A60  ld BC,(XIZ+0xfe)
	neg	bc                                     ; FC9A63  neg BC
	ld	(xiz-2), bc                             ; FC9A65  ld (XIZ+0xfe),BC
sub_FC9844__FC9A68:
	ld	xbc, (xiz+12)                           ; FC9A68  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC9A6B  push XBC
	ld	xbc, (xiz+8)                            ; FC9A6C  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC9A6F  push XBC
	ld	xbc, (xiz+12)                           ; FC9A70  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC9A73  push XBC
	ld	xbc, (xiz+8)                            ; FC9A74  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC9A77  push XBC
	lda	xiy, (xiz-10)                          ; FC9A78  lda XIY,XIZ+0xf6
	call	0xFCA252                              ; FC9A7B  call 0xfca252
	lda	xix, (xiz-18)                          ; FC9A7F  lda XIX,XIZ+0xee
	lda	xiy, (0xFCB436:24)                     ; FC9A82  lda XIY,0xfcb436
	ldw	bc, 4                                  ; FC9A87  ld BC,0x0004
	extpfx2 0x95, 0x11                         ; FC9A8A  ldirw
	lda	xix, (0xFCB436:24)                     ; FC9A8C  lda XIX,0xfcb436
	inc	8, xix                                 ; FC9A91  inc 0,XIX
	ldb	h, 2                                   ; FC9A93  ld H,0x02
sub_FC9844__FC9A95:
	ld	xbc, (xiz-14)                           ; FC9A95  ld XBC,(XIZ+0xf2)
	push	xbc                                   ; FC9A98  push XBC
	ld	xbc, (xiz-18)                           ; FC9A99  ld XBC,(XIZ+0xee)
	push	xbc                                   ; FC9A9C  push XBC
	ld	xbc, (xiz-6)                            ; FC9A9D  ld XBC,(XIZ+0xfa)
	push	xbc                                   ; FC9AA0  push XBC
	ld	xbc, (xiz-10)                           ; FC9AA1  ld XBC,(XIZ+0xf6)
	push	xbc                                   ; FC9AA4  push XBC
	lda	xiy, (xiz-26)                          ; FC9AA5  lda XIY,XIZ+0xe6
	call	0xFCA252                              ; FC9AA8  call 0xfca252
	push	xix                                   ; FC9AAC  push XIX
	lda	xix, (xiz-34)                          ; FC9AAD  lda XIX,XIZ+0xde
	ld	xiy, (xsp)                              ; FC9AB0  ld XIY,(XSP)
	ldw	bc, 4                                  ; FC9AB2  ld BC,0x0004
	extpfx2 0x95, 0x11                         ; FC9AB5  ldirw
	pop	xix                                    ; FC9AB7  pop XIX
	ld	xbc, (xiz-30)                           ; FC9AB8  ld XBC,(XIZ+0xe2)
	push	xbc                                   ; FC9ABB  push XBC
	ld	xbc, (xiz-34)                           ; FC9ABC  ld XBC,(XIZ+0xde)
	push	xbc                                   ; FC9ABF  push XBC
	ld	xbc, (xiz-22)                           ; FC9AC0  ld XBC,(XIZ+0xea)
	push	xbc                                   ; FC9AC3  push XBC
	ld	xbc, (xiz-26)                           ; FC9AC4  ld XBC,(XIZ+0xe6)
	push	xbc                                   ; FC9AC7  push XBC
	lda	xiy, (xiz-18)                          ; FC9AC8  lda XIY,XIZ+0xee
; --------------------------------------------------------------------------
; sub_FC9ACB -- 0xFC9ACB..0xFC9BBB (241 bytes)
;
; Called from: ⚠ NO LOCATED CALLER (⚠ CORRECTED 2026-08-25).  The one citation the
;          image-wide scan produced lies inside the 77-entry IEEE-754 DOUBLE
;          COEFFICIENT POOL at 0xFCB27E-0xFCC53E -- eight bytes of a double that
;          happen to spell a call.  notes/prom_c_phantom_callsites.py --selftest.
; Inputs:  no frame; argument slots read: (XIZ+0x08), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
;          reads 0xFCB3EE, 0xFCB3F2
; Calls:   0xFC9BBC = sub_FC9BBC, 0xFCA252 = Double_Multiply
;          0xFCA41F = Double_Add, 0xFCA626 = Double_Subtract
;          0xFCA7A5 = Double_Divide
; Evidence: the listing below is the byte-identical round-trip of 0xFC9ACB-0xFC9BBB
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC9ACB:
	call	0xFCA41F                              ; FC9ACB  call 0xfca41f
	inc	8, xix                                 ; FC9ACF  inc 0,XIX
	dec	1, h                                   ; FC9AD1  dec 1,H
	cps	h, 0                                   ; FC9AD3  cp H,0
	jr nz, sub_FC9844__FC9A95                  ; FC9AD5  jr NZ,0xfc9a95
	ld	xbc, (xiz+12)                           ; FC9AD7  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC9ADA  push XBC
	ld	xbc, (xiz+8)                            ; FC9ADB  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC9ADE  push XBC
	ld	xbc, (xiz-14)                           ; FC9ADF  ld XBC,(XIZ+0xf2)
	push	xbc                                   ; FC9AE2  push XBC
	ld	xbc, (xiz-18)                           ; FC9AE3  ld XBC,(XIZ+0xee)
	push	xbc                                   ; FC9AE6  push XBC
	lda	xiy, (xiz+8)                           ; FC9AE7  lda XIY,XIZ+0x08
	call	0xFCA252                              ; FC9AEA  call 0xfca252
	lda	xix, (xiz-18)                          ; FC9AEE  lda XIX,XIZ+0xee
	lda	xiy, (0xFCB44E:24)                     ; FC9AF1  lda XIY,0xfcb44e
	ldw	bc, 4                                  ; FC9AF6  ld BC,0x0004
	extpfx2 0x95, 0x11                         ; FC9AF9  ldirw
	lda	xix, (0xFCB44E:24)                     ; FC9AFB  lda XIX,0xfcb44e
	inc	8, xix                                 ; FC9B00  inc 0,XIX
	ldb	h, 3                                   ; FC9B02  ld H,0x03
sub_FC9ACB__FC9B04:
	ld	xbc, (xiz-14)                           ; FC9B04  ld XBC,(XIZ+0xf2)
	push	xbc                                   ; FC9B07  push XBC
	ld	xbc, (xiz-18)                           ; FC9B08  ld XBC,(XIZ+0xee)
	push	xbc                                   ; FC9B0B  push XBC
	ld	xbc, (xiz-6)                            ; FC9B0C  ld XBC,(XIZ+0xfa)
	push	xbc                                   ; FC9B0F  push XBC
	ld	xbc, (xiz-10)                           ; FC9B10  ld XBC,(XIZ+0xf6)
	push	xbc                                   ; FC9B13  push XBC
	lda	xiy, (xiz-26)                          ; FC9B14  lda XIY,XIZ+0xe6
	call	0xFCA252                              ; FC9B17  call 0xfca252
	push	xix                                   ; FC9B1B  push XIX
	lda	xix, (xiz-34)                          ; FC9B1C  lda XIX,XIZ+0xde
	ld	xiy, (xsp)                              ; FC9B1F  ld XIY,(XSP)
	ldw	bc, 4                                  ; FC9B21  ld BC,0x0004
	extpfx2 0x95, 0x11                         ; FC9B24  ldirw
	pop	xix                                    ; FC9B26  pop XIX
	ld	xbc, (xiz-30)                           ; FC9B27  ld XBC,(XIZ+0xe2)
	push	xbc                                   ; FC9B2A  push XBC
	ld	xbc, (xiz-34)                           ; FC9B2B  ld XBC,(XIZ+0xde)
	push	xbc                                   ; FC9B2E  push XBC
	ld	xbc, (xiz-22)                           ; FC9B2F  ld XBC,(XIZ+0xea)
	push	xbc                                   ; FC9B32  push XBC
	ld	xbc, (xiz-26)                           ; FC9B33  ld XBC,(XIZ+0xe6)
	push	xbc                                   ; FC9B36  push XBC
	lda	xiy, (xiz-18)                          ; FC9B37  lda XIY,XIZ+0xee
	call	0xFCA41F                              ; FC9B3A  call 0xfca41f
	inc	8, xix                                 ; FC9B3E  inc 0,XIX
	dec	1, h                                   ; FC9B40  dec 1,H
	cps	h, 0                                   ; FC9B42  cp H,0
	jr nz, sub_FC9ACB__FC9B04                  ; FC9B44  jr NZ,0xfc9b04
	ld	bc, (xiz-2)                             ; FC9B46  ld BC,(XIZ+0xfe)
	inc	1, bc                                  ; FC9B49  inc 1,BC
	pushw	bc                                   ; FC9B4B  push BC
	ld	xbc, (xiz+12)                           ; FC9B4C  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC9B4F  push XBC
	ld	xbc, (xiz+8)                            ; FC9B50  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC9B53  push XBC
	ld	xbc, (xiz-14)                           ; FC9B54  ld XBC,(XIZ+0xf2)
	push	xbc                                   ; FC9B57  push XBC
	ld	xbc, (xiz-18)                           ; FC9B58  ld XBC,(XIZ+0xee)
	push	xbc                                   ; FC9B5B  push XBC
	lda	xiy, (xiz-26)                          ; FC9B5C  lda XIY,XIZ+0xe6
	call	0xFCA626                              ; FC9B5F  call 0xfca626
	ld	xbc, (xiz-22)                           ; FC9B63  ld XBC,(XIZ+0xea)
	push	xbc                                   ; FC9B66  push XBC
	ld	xbc, (xiz-26)                           ; FC9B67  ld XBC,(XIZ+0xe6)
	push	xbc                                   ; FC9B6A  push XBC
	ld	xbc, (xiz+12)                           ; FC9B6B  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC9B6E  push XBC
	ld	xbc, (xiz+8)                            ; FC9B6F  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC9B72  push XBC
	lda	xiy, (xiz-34)                          ; FC9B73  lda XIY,XIZ+0xde
	call	0xFCA7A5                              ; FC9B76  call 0xfca7a5
	ld	xbc, (0xFCB3F2:24)                     ; FC9B7A  ld XBC,(0xfcb3f2)
	push	xbc                                   ; FC9B7F  push XBC
	ld	xbc, (0xFCB3EE:24)                     ; FC9B80  ld XBC,(0xfcb3ee)
	push	xbc                                   ; FC9B85  push XBC
	ld	xbc, (xiz-30)                           ; FC9B86  ld XBC,(XIZ+0xe2)
	push	xbc                                   ; FC9B89  push XBC
	ld	xbc, (xiz-34)                           ; FC9B8A  ld XBC,(XIZ+0xde)
	push	xbc                                   ; FC9B8D  push XBC
	lda	xiy, (xiz-42)                          ; FC9B8E  lda XIY,XIZ+0xd6
	call	0xFCA41F                              ; FC9B91  call 0xfca41f
	ld	xbc, (xiz-38)                           ; FC9B95  ld XBC,(XIZ+0xda)
	push	xbc                                   ; FC9B98  push XBC
	ld	xbc, (xiz-42)                           ; FC9B99  ld XBC,(XIZ+0xd6)
	push	xbc                                   ; FC9B9C  push XBC
	lda	xiy, (xiz-50)                          ; FC9B9D  lda XIY,XIZ+0xce
	call	0xFC9BBC                              ; FC9BA0  call 0xfc9bbc
	inc	8, xsp                                 ; FC9BA4  inc 0,XSP
	inc	2, xsp                                 ; FC9BA6  inc 2,XSP
	ld	xiy, (xsp)                              ; FC9BA8  ld XIY,(XSP)
	ld	xix, (xiz-50)                           ; FC9BAA  ld XIX,(XIZ+0xce)
	stl_dpi	xix, 0xF6                          ; FC9BAD  ld (XIY+),XIX
	ld	xix, (xiz-46)                           ; FC9BB0  ld XIX,(XIZ+0xd2)
	ld	(xiy), xix                              ; FC9BB3  ld (XIY),XIX
sub_FC9ACB__FC9BB5:
	pop	xiy                                    ; FC9BB5  pop XIY
	pop	xix                                    ; FC9BB6  pop XIX
	popw	de                                    ; FC9BB7  pop DE
	popw	hl                                    ; FC9BB8  pop HL
	unlk32 xiz                                 ; FC9BB9  unlk XIZ
	ret                                        ; FC9BBB  ret
; --------------------------------------------------------------------------
; sub_FC9BBC -- 0xFC9BBC..0xFC9CCC (273 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFC9BA0
; Inputs:  frame `link XIZ,-18`; argument slots read: (XIZ+0x08), (XIZ+0x0C), (XIZ+0x10)
; Outputs: writes 0x00F362
;          reads 0xFCB46E, 0xFCB472
; Calls:   0xFCA121 = Double_Compare, 0xFCA1B6 = Double_Negate
; Evidence: the listing below is the byte-identical round-trip of 0xFC9BBC-0xFC9CCC
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC9BBC:
	link32 0xEE, 0x0C, 0xEE, 0xFF              ; FC9BBC  link XIZ,0xffee
	pushw	hl                                   ; FC9BC0  push HL
	pushw	de                                   ; FC9BC1  push DE
	push	xix                                   ; FC9BC2  push XIX
	push	xiy                                   ; FC9BC3  push XIY
	ld	xbc, (0xFCB472:24)                     ; FC9BC4  ld XBC,(0xfcb472)
	push	xbc                                   ; FC9BC9  push XBC
	ld	xbc, (0xFCB46E:24)                     ; FC9BCA  ld XBC,(0xfcb46e)
	push	xbc                                   ; FC9BCF  push XBC
	ld	xbc, (xiz+12)                           ; FC9BD0  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC9BD3  push XBC
	ld	xbc, (xiz+8)                            ; FC9BD4  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC9BD7  push XBC
	call	0xFCA121                              ; FC9BD8  call 0xfca121
	cps	wa, 2                                  ; FC9BDC  cp WA,2
	jr nz, sub_FC9BBC__FC9BE7                  ; FC9BDE  jr NZ,0xfc9be7
	ldw (xiz-2), 0x0001                        ; FC9BE0  ld (XIZ+0xfe),0x0001
	jr sub_FC9BBC__FC9BEC                      ; FC9BE5  jr T,0xfc9bec
sub_FC9BBC__FC9BE7:
	ldw (xiz-2), 0x0000                        ; FC9BE7  ld (XIZ+0xfe),0x0000
sub_FC9BBC__FC9BEC:
	lda	xix, (xiz-10)                          ; FC9BEC  lda XIX,XIZ+0xf6
	lda	xiy, (xiz+8)                           ; FC9BEF  lda XIY,XIZ+0x08
	ldw	bc, 4                                  ; FC9BF2  ld BC,0x0004
	extpfx2 0x95, 0x11                         ; FC9BF5  ldirw
	ld	a, (xiz-3)                              ; FC9BF7  ld A,(XIZ+0xfd)
	extz	wa                                    ; FC9BFA  extz WA
	ld	ix, wa                                  ; FC9BFC  ld IX,WA
	sll	ix, 8                                  ; FC9BFE  sll 0x08,IX
	ld	a, (xiz-4)                              ; FC9C01  ld A,(XIZ+0xfc)
	extz	wa                                    ; FC9C04  extz WA
	ld	de, wa                                  ; FC9C06  ld DE,WA
	or	de, ix                                  ; FC9C08  or DE,IX
	ld	hl, de                                  ; FC9C0A  ld HL,DE
	add	hl, hl                                 ; FC9C0C  add HL,HL
	ld	bc, hl                                  ; FC9C0E  ld BC,HL
	srl	bc, 5                                  ; FC9C10  srl 0x05,BC
	ld	hl, bc                                  ; FC9C13  ld HL,BC
	jr z, sub_FC9BBC__FC9C34                   ; FC9C15  jr Z,0xfc9c34
	exts	xbc                                   ; FC9C17  exts XBC
	ld	(xiz-14), xbc                           ; FC9C19  ld (XIZ+0xf2),XBC
	ld	wa, (xiz+16)                            ; FC9C1C  ld WA,(XIZ+0x10)
	exts	xwa                                   ; FC9C1F  exts XWA
	ld	xix, xbc                                ; FC9C21  ld XIX,XBC
	add	xix, xwa                               ; FC9C23  add XIX,XWA
	cp	xix, 0                                  ; FC9C25  cp XIX,0x00000000
	jr gt, sub_FC9BBC__FC9C48                  ; FC9C2B  jr GT,0xfc9c48
	ldw	(0xF362:24), 34                       ; FC9C2D  ld (0x00f362),0x0022
sub_FC9BBC__FC9C34:
	ld	xiy, (xsp)                              ; FC9C34  ld XIY,(XSP)
	ld	xix, (0xFCB46E:24)                     ; FC9C36  ld XIX,(0xfcb46e)
	stl_dpi	xix, 0xF6                          ; FC9C3B  ld (XIY+),XIX
	ld	xix, (0xFCB472:24)                     ; FC9C3E  ld XIX,(0xfcb472)
	ld	(xiy), xix                              ; FC9C43  ld (XIY),XIX
	jrl sub_FC9BBC__FC9CC6                     ; FC9C45  jrl T,0xfc9cc6
sub_FC9BBC__FC9C48:
	ld	xiy, xix                                ; FC9C48  ld XIY,XIX
	sll	xiy, 4                                 ; FC9C4A  sll 0x04,XIY
	ld	hl, iy                                  ; FC9C4D  ld HL,IY
	cp	xix, 0x7FE                              ; FC9C4F  cp XIX,0x000007fe
	jr le, sub_FC9BBC__FC9C70                  ; FC9C55  jr LE,0xfc9c70
	ldw	hl, 0x7FF0                             ; FC9C57  ld HL,0x7ff0
	sub	xbc, xbc                               ; FC9C5A  sub XBC,XBC
	ld	(xiz-10), xbc                           ; FC9C5C  ld (XIZ+0xf6),XBC
	sub	xbc, xbc                               ; FC9C5F  sub XBC,XBC
	ld	(xiz-6), xbc                            ; FC9C61  ld (XIZ+0xfa),XBC
	ldw	(0xF362:24), 34                       ; FC9C64  ld (0x00f362),0x0022
	ldw	de, 0                                  ; FC9C6B  ld DE,0x0000
	jr sub_FC9BBC__FC9C74                      ; FC9C6E  jr T,0xfc9c74
sub_FC9BBC__FC9C70:
	and	de, 15                                 ; FC9C70  and DE,0x000f
sub_FC9BBC__FC9C74:
	ld	ix, hl                                  ; FC9C74  ld IX,HL
	or	ix, de                                  ; FC9C76  or IX,DE
	ld	bc, ix                                  ; FC9C78  ld BC,IX
	and	bc, 0xFF                               ; FC9C7A  and BC,0x00ff
	ld	(xiz-4), c                              ; FC9C7E  ld (XIZ+0xfc),C
	ld	bc, ix                                  ; FC9C81  ld BC,IX
	srl	bc, 8                                  ; FC9C83  srl 0x08,BC
	ld	(xiz-3), c                              ; FC9C86  ld (XIZ+0xfd),C
	lda	xix, (xiz+8)                           ; FC9C89  lda XIX,XIZ+0x08
	lda	xiy, (xiz-10)                          ; FC9C8C  lda XIY,XIZ+0xf6
	ldw	bc, 4                                  ; FC9C8F  ld BC,0x0004
	extpfx2 0x95, 0x11                         ; FC9C92  ldirw
	cpw (xiz-2), 0x0000                        ; FC9C94  cp (XIZ+0xfe),0x0000
	jr z, sub_FC9BBC__FC9CB9                   ; FC9C99  jr Z,0xfc9cb9
	ld	xbc, (xiz+12)                           ; FC9C9B  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC9C9E  push XBC
	ld	xbc, (xiz+8)                            ; FC9C9F  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC9CA2  push XBC
	lda	xiy, (xiz-18)                          ; FC9CA3  lda XIY,XIZ+0xee
	call	0xFCA1B6                              ; FC9CA6  call 0xfca1b6
	ld	xiy, (xsp)                              ; FC9CAA  ld XIY,(XSP)
	ld	xix, (xiz-18)                           ; FC9CAC  ld XIX,(XIZ+0xee)
	stl_dpi	xix, 0xF6                          ; FC9CAF  ld (XIY+),XIX
	ld	xix, (xiz-14)                           ; FC9CB2  ld XIX,(XIZ+0xf2)
	ld	(xiy), xix                              ; FC9CB5  ld (XIY),XIX
	jr sub_FC9BBC__FC9CC6                      ; FC9CB7  jr T,0xfc9cc6
sub_FC9BBC__FC9CB9:
	ld	xiy, (xsp)                              ; FC9CB9  ld XIY,(XSP)
	ld	xix, (xiz+8)                            ; FC9CBB  ld XIX,(XIZ+0x08)
	stl_dpi	xix, 0xF6                          ; FC9CBE  ld (XIY+),XIX
	ld	xix, (xiz+12)                           ; FC9CC1  ld XIX,(XIZ+0x0c)
	ld	(xiy), xix                              ; FC9CC4  ld (XIY),XIX
sub_FC9BBC__FC9CC6:
	pop	xiy                                    ; FC9CC6  pop XIY
	pop	xix                                    ; FC9CC7  pop XIX
	popw	de                                    ; FC9CC8  pop DE
	popw	hl                                    ; FC9CC9  pop HL
	unlk32 xiz                                 ; FC9CCA  unlk XIZ
	ret                                        ; FC9CCC  ret
; --------------------------------------------------------------------------
; sub_FC9CCD -- 0xFC9CCD..0xFC9D11 (69 bytes)
;
; Called from: no site outside this module.
;          3 site(s) inside this module:
;          0xFC97FA 0xFC990C 0xFC9D6A
; Inputs:  frame `link XIZ,-16`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFC9CCD-0xFC9D11
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC9CCD:
	link32 0xEE, 0x0C, 0xF0, 0xFF              ; FC9CCD  link XIZ,0xfff0
	push	xix                                   ; FC9CD1  push XIX
	push	xiy                                   ; FC9CD2  push XIY
	lda	xix, (xiz-8)                           ; FC9CD3  lda XIX,XIZ+0xf8
	sub	xbc, xbc                               ; FC9CD6  sub XBC,XBC
	ld	(xix), xbc                              ; FC9CD8  ld (XIX),XBC
	sub	xbc, xbc                               ; FC9CDA  sub XBC,XBC
	ld	(xix+4), xbc                            ; FC9CDC  ld (XIX+0x04),XBC
	ld	(xix+6), 0xF0                           ; FC9CDF  ld (XIX+0x06),0xf0
	cpw (xiz+8), 0x0000                        ; FC9CE3  cp (XIZ+0x08),0x0000
	jr z, sub_FC9CCD__FC9CF0                   ; FC9CE8  jr Z,0xfc9cf0
	ld	(xix+7), 0xFF                           ; FC9CEA  ld (XIX+0x07),0xff
	jr sub_FC9CCD__FC9CF4                      ; FC9CEE  jr T,0xfc9cf4
sub_FC9CCD__FC9CF0:
	ld	(xix+7), 0x7F                           ; FC9CF0  ld (XIX+0x07),0x7f
sub_FC9CCD__FC9CF4:
	push	xix                                   ; FC9CF4  push XIX
	lda	xix, (xiz-16)                          ; FC9CF5  lda XIX,XIZ+0xf0
	ld	xiy, (xsp)                              ; FC9CF8  ld XIY,(XSP)
	ldw	bc, 4                                  ; FC9CFA  ld BC,0x0004
	extpfx2 0x95, 0x11                         ; FC9CFD  ldirw
	pop	xix                                    ; FC9CFF  pop XIX
	ld	xiy, (xsp)                              ; FC9D00  ld XIY,(XSP)
	ld	xix, (xiz-16)                           ; FC9D02  ld XIX,(XIZ+0xf0)
	stl_dpi	xix, 0xF6                          ; FC9D05  ld (XIY+),XIX
	ld	xix, (xiz-12)                           ; FC9D08  ld XIX,(XIZ+0xf4)
	ld	(xiy), xix                              ; FC9D0B  ld (XIY),XIX
	pop	xiy                                    ; FC9D0D  pop XIY
	pop	xix                                    ; FC9D0E  pop XIX
	unlk32 xiz                                 ; FC9D0F  unlk XIZ
	ret                                        ; FC9D11  ret
; --------------------------------------------------------------------------
; sub_FC9D12 -- 0xFC9D12..0xFC9FA2 (657 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFC96E4
; Inputs:  frame `link XIZ,-82`; argument slots read: (XIZ+0x08), (XIZ+0x0C)
; Outputs: writes 0x00F362
;          reads 0xFCB476, 0xFCB47A, 0xFCB47E, 0xFCB482, 0xFCB486, 0xFCB48A, 0xFCB48E, 0xFCB492, 0xFCB496, 0xFCB49A, 0xFCB49E, 0xFCB4A2
; Calls:   0xFC9CCD = sub_FC9CCD, 0xFC9FA3 = sub_FC9FA3
;          0xFCA121 = Double_Compare, 0xFCA252 = Double_Multiply
;          0xFCA41F = Double_Add, 0xFCA626 = Double_Subtract
;          0xFCA7A5 = Double_Divide, 0xFCA997 = Int16_ToDouble
; Evidence: the listing below is the byte-identical round-trip of 0xFC9D12-0xFC9FA2
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC9D12:
	link32 0xEE, 0x0C, 0xAE, 0xFF              ; FC9D12  link XIZ,0xffae
	pushw	hl                                   ; FC9D16  push HL
	push	xix                                   ; FC9D17  push XIX
	push	xiy                                   ; FC9D18  push XIY
	ld	xbc, (0xFCB4A2:24)                     ; FC9D19  ld XBC,(0xfcb4a2)
	push	xbc                                   ; FC9D1E  push XBC
	ld	xbc, (0xFCB49E:24)                     ; FC9D1F  ld XBC,(0xfcb49e)
	push	xbc                                   ; FC9D24  push XBC
	ld	xbc, (xiz+12)                           ; FC9D25  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC9D28  push XBC
	ld	xbc, (xiz+8)                            ; FC9D29  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC9D2C  push XBC
	call	0xFCA121                              ; FC9D2D  call 0xfca121
	cps	wa, 2                                  ; FC9D31  cp WA,2
	jr z, sub_FC9D12__FC9D41                   ; FC9D33  jr Z,0xfc9d41
	ldw	(0xF362:24), 33                       ; FC9D35  ld (0x00f362),0x0021
	pushw	0                                    ; FC9D3C  push 0x0000
	jr sub_FC9D12__FC9D67                      ; FC9D3F  jr T,0xfc9d67
sub_FC9D12__FC9D41:
	ld	xbc, (0xFCB49A:24)                     ; FC9D41  ld XBC,(0xfcb49a)
	push	xbc                                   ; FC9D46  push XBC
	ld	xbc, (0xFCB496:24)                     ; FC9D47  ld XBC,(0xfcb496)
	push	xbc                                   ; FC9D4C  push XBC
	ld	xbc, (xiz+12)                           ; FC9D4D  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC9D50  push XBC
	ld	xbc, (xiz+8)                            ; FC9D51  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC9D54  push XBC
	call	0xFCA121                              ; FC9D55  call 0xfca121
	cps	wa, 1                                  ; FC9D59  cp WA,1
	jr z, sub_FC9D12__FC9D7F                   ; FC9D5B  jr Z,0xfc9d7f
	ldw	(0xF362:24), 33                       ; FC9D5D  ld (0x00f362),0x0021
	pushw	1                                    ; FC9D64  push 0x0001
sub_FC9D12__FC9D67:
	lda	xiy, (xiz-34)                          ; FC9D67  lda XIY,XIZ+0xde
	call	0xFC9CCD                              ; FC9D6A  call 0xfc9ccd
	popw	bc                                    ; FC9D6E  pop BC
	ld	xiy, (xsp)                              ; FC9D6F  ld XIY,(XSP)
	ld	xix, (xiz-34)                           ; FC9D71  ld XIX,(XIZ+0xde)
	stl_dpi	xix, 0xF6                          ; FC9D74  ld (XIY+),XIX
	ld	xix, (xiz-30)                           ; FC9D77  ld XIX,(XIZ+0xe2)
	ld	(xiy), xix                              ; FC9D7A  ld (XIY),XIX
	jrl sub_FC9D12__FC9F9D                     ; FC9D7C  jrl T,0xfc9f9d
sub_FC9D12__FC9D7F:
	ld	xbc, (0xFCB48E:24)                     ; FC9D7F  ld XBC,(0xfcb48e)
	ld	(xiz-8), xbc                            ; FC9D84  ld (XIZ+0xf8),XBC
	ld	xbc, (0xFCB492:24)                     ; FC9D87  ld XBC,(0xfcb492)
	ld	(xiz-4), xbc                            ; FC9D8C  ld (XIZ+0xfc),XBC
	lda	xbc, (xiz-10)                          ; FC9D8F  lda XBC,XIZ+0xf6
	push	xbc                                   ; FC9D92  push XBC
	ld	xwa, (xiz+12)                           ; FC9D93  ld XWA,(XIZ+0x0c)
	push	xwa                                   ; FC9D96  push XWA
	ld	xwa, (xiz+8)                            ; FC9D97  ld XWA,(XIZ+0x08)
	push	xwa                                   ; FC9D9A  push XWA
	lda	xiy, (xiz+8)                           ; FC9D9B  lda XIY,XIZ+0x08
	call	0xFC9FA3                              ; FC9D9E  call 0xfc9fa3
	inc	8, xsp                                 ; FC9DA2  inc 0,XSP
	inc	4, xsp                                 ; FC9DA4  inc 4,XSP
	ld	xbc, (0xFCB48A:24)                     ; FC9DA6  ld XBC,(0xfcb48a)
	push	xbc                                   ; FC9DAB  push XBC
	ld	xbc, (0xFCB486:24)                     ; FC9DAC  ld XBC,(0xfcb486)
	push	xbc                                   ; FC9DB1  push XBC
	ld	xbc, (xiz+12)                           ; FC9DB2  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC9DB5  push XBC
	ld	xbc, (xiz+8)                            ; FC9DB6  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC9DB9  push XBC
	call	0xFCA121                              ; FC9DBA  call 0xfca121
	cps	wa, 2                                  ; FC9DBE  cp WA,2
	jr nz, sub_FC9D12__FC9DD5                  ; FC9DC0  jr NZ,0xfc9dd5
	decm	1, (xiz-10)                           ; FC9DC2  decw 1,(XIZ+0xf6)
	ld	xbc, (0xFCB47E:24)                     ; FC9DC5  ld XBC,(0xfcb47e)
	ld	(xiz-8), xbc                            ; FC9DCA  ld (XIZ+0xf8),XBC
	ld	xbc, (0xFCB482:24)                     ; FC9DCD  ld XBC,(0xfcb482)
	ld	(xiz-4), xbc                            ; FC9DD2  ld (XIZ+0xfc),XBC
sub_FC9D12__FC9DD5:
	ld	xbc, (xiz-4)                            ; FC9DD5  ld XBC,(XIZ+0xfc)
	push	xbc                                   ; FC9DD8  push XBC
	ld	xbc, (xiz-8)                            ; FC9DD9  ld XBC,(XIZ+0xf8)
	push	xbc                                   ; FC9DDC  push XBC
	ld	xbc, (xiz+12)                           ; FC9DDD  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC9DE0  push XBC
	ld	xbc, (xiz+8)                            ; FC9DE1  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC9DE4  push XBC
	lda	xiy, (xiz-34)                          ; FC9DE5  lda XIY,XIZ+0xde
	call	0xFCA41F                              ; FC9DE8  call 0xfca41f
	ld	xbc, (xiz-4)                            ; FC9DEC  ld XBC,(XIZ+0xfc)
	push	xbc                                   ; FC9DEF  push XBC
	ld	xbc, (xiz-8)                            ; FC9DF0  ld XBC,(XIZ+0xf8)
	push	xbc                                   ; FC9DF3  push XBC
	ld	xbc, (xiz+12)                           ; FC9DF4  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC9DF7  push XBC
	ld	xbc, (xiz+8)                            ; FC9DF8  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC9DFB  push XBC
	lda	xiy, (xiz-42)                          ; FC9DFC  lda XIY,XIZ+0xd6
	call	0xFCA626                              ; FC9DFF  call 0xfca626
	ld	xbc, (xiz-30)                           ; FC9E03  ld XBC,(XIZ+0xe2)
	push	xbc                                   ; FC9E06  push XBC
	ld	xbc, (xiz-34)                           ; FC9E07  ld XBC,(XIZ+0xde)
	push	xbc                                   ; FC9E0A  push XBC
	ld	xbc, (xiz-38)                           ; FC9E0B  ld XBC,(XIZ+0xda)
	push	xbc                                   ; FC9E0E  push XBC
	ld	xbc, (xiz-42)                           ; FC9E0F  ld XBC,(XIZ+0xd6)
	push	xbc                                   ; FC9E12  push XBC
	lda	xiy, (xiz-50)                          ; FC9E13  lda XIY,XIZ+0xce
	call	0xFCA7A5                              ; FC9E16  call 0xfca7a5
	ld	xbc, (xiz-46)                           ; FC9E1A  ld XBC,(XIZ+0xd2)
	push	xbc                                   ; FC9E1D  push XBC
	ld	xbc, (xiz-50)                           ; FC9E1E  ld XBC,(XIZ+0xce)
	push	xbc                                   ; FC9E21  push XBC
	ld	xbc, (xiz-46)                           ; FC9E22  ld XBC,(XIZ+0xd2)
	push	xbc                                   ; FC9E25  push XBC
	ld	xbc, (xiz-50)                           ; FC9E26  ld XBC,(XIZ+0xce)
	push	xbc                                   ; FC9E29  push XBC
	lda	xiy, (xiz+8)                           ; FC9E2A  lda XIY,XIZ+0x08
	call	0xFCA41F                              ; FC9E2D  call 0xfca41f
	ld	xbc, (xiz+12)                           ; FC9E31  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC9E34  push XBC
	ld	xbc, (xiz+8)                            ; FC9E35  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC9E38  push XBC
	ld	xbc, (xiz+12)                           ; FC9E39  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC9E3C  push XBC
	ld	xbc, (xiz+8)                            ; FC9E3D  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC9E40  push XBC
	lda	xiy, (xiz-8)                           ; FC9E41  lda XIY,XIZ+0xf8
	call	0xFCA252                              ; FC9E44  call 0xfca252
	lda	xix, (xiz-18)                          ; FC9E48  lda XIX,XIZ+0xee
	lda	xiy, (0xFCB4A6:24)                     ; FC9E4B  lda XIY,0xfcb4a6
	ldw	bc, 4                                  ; FC9E50  ld BC,0x0004
	extpfx2 0x95, 0x11                         ; FC9E53  ldirw
	lda	xix, (0xFCB4A6:24)                     ; FC9E55  lda XIX,0xfcb4a6
	inc	8, xix                                 ; FC9E5A  inc 0,XIX
	ldb	h, 2                                   ; FC9E5C  ld H,0x02
sub_FC9D12__FC9E5E:
	ld	xbc, (xiz-14)                           ; FC9E5E  ld XBC,(XIZ+0xf2)
	push	xbc                                   ; FC9E61  push XBC
	ld	xbc, (xiz-18)                           ; FC9E62  ld XBC,(XIZ+0xee)
	push	xbc                                   ; FC9E65  push XBC
	ld	xbc, (xiz-4)                            ; FC9E66  ld XBC,(XIZ+0xfc)
	push	xbc                                   ; FC9E69  push XBC
	ld	xbc, (xiz-8)                            ; FC9E6A  ld XBC,(XIZ+0xf8)
	push	xbc                                   ; FC9E6D  push XBC
	lda	xiy, (xiz-34)                          ; FC9E6E  lda XIY,XIZ+0xde
	call	0xFCA252                              ; FC9E71  call 0xfca252
	push	xix                                   ; FC9E75  push XIX
	lda	xix, (xiz-42)                          ; FC9E76  lda XIX,XIZ+0xd6
	ld	xiy, (xsp)                              ; FC9E79  ld XIY,(XSP)
	ldw	bc, 4                                  ; FC9E7B  ld BC,0x0004
	extpfx2 0x95, 0x11                         ; FC9E7E  ldirw
	pop	xix                                    ; FC9E80  pop XIX
	ld	xbc, (xiz-38)                           ; FC9E81  ld XBC,(XIZ+0xda)
	push	xbc                                   ; FC9E84  push XBC
	ld	xbc, (xiz-42)                           ; FC9E85  ld XBC,(XIZ+0xd6)
	push	xbc                                   ; FC9E88  push XBC
	ld	xbc, (xiz-30)                           ; FC9E89  ld XBC,(XIZ+0xe2)
	push	xbc                                   ; FC9E8C  push XBC
	ld	xbc, (xiz-34)                           ; FC9E8D  ld XBC,(XIZ+0xde)
	push	xbc                                   ; FC9E90  push XBC
	lda	xiy, (xiz-18)                          ; FC9E91  lda XIY,XIZ+0xee
	call	0xFCA41F                              ; FC9E94  call 0xfca41f
	inc	8, xix                                 ; FC9E98  inc 0,XIX
	dec	1, h                                   ; FC9E9A  dec 1,H
	cps	h, 0                                   ; FC9E9C  cp H,0
	jr nz, sub_FC9D12__FC9E5E                  ; FC9E9E  jr NZ,0xfc9e5e
	lda	xix, (xiz-26)                          ; FC9EA0  lda XIX,XIZ+0xe6
	lda	xiy, (0xFCB4BE:24)                     ; FC9EA3  lda XIY,0xfcb4be
	ldw	bc, 4                                  ; FC9EA8  ld BC,0x0004
	extpfx2 0x95, 0x11                         ; FC9EAB  ldirw
	lda	xix, (0xFCB4BE:24)                     ; FC9EAD  lda XIX,0xfcb4be
	inc	8, xix                                 ; FC9EB2  inc 0,XIX
	ldb	h, 3                                   ; FC9EB4  ld H,0x03
sub_FC9D12__FC9EB6:
	ld	xbc, (xiz-22)                           ; FC9EB6  ld XBC,(XIZ+0xea)
	push	xbc                                   ; FC9EB9  push XBC
	ld	xbc, (xiz-26)                           ; FC9EBA  ld XBC,(XIZ+0xe6)
	push	xbc                                   ; FC9EBD  push XBC
	ld	xbc, (xiz-4)                            ; FC9EBE  ld XBC,(XIZ+0xfc)
	push	xbc                                   ; FC9EC1  push XBC
	ld	xbc, (xiz-8)                            ; FC9EC2  ld XBC,(XIZ+0xf8)
	push	xbc                                   ; FC9EC5  push XBC
	lda	xiy, (xiz-34)                          ; FC9EC6  lda XIY,XIZ+0xde
	call	0xFCA252                              ; FC9EC9  call 0xfca252
	push	xix                                   ; FC9ECD  push XIX
	lda	xix, (xiz-42)                          ; FC9ECE  lda XIX,XIZ+0xd6
	ld	xiy, (xsp)                              ; FC9ED1  ld XIY,(XSP)
	ldw	bc, 4                                  ; FC9ED3  ld BC,0x0004
	extpfx2 0x95, 0x11                         ; FC9ED6  ldirw
	pop	xix                                    ; FC9ED8  pop XIX
	ld	xbc, (xiz-38)                           ; FC9ED9  ld XBC,(XIZ+0xda)
	push	xbc                                   ; FC9EDC  push XBC
	ld	xbc, (xiz-42)                           ; FC9EDD  ld XBC,(XIZ+0xd6)
	push	xbc                                   ; FC9EE0  push XBC
	ld	xbc, (xiz-30)                           ; FC9EE1  ld XBC,(XIZ+0xe2)
	push	xbc                                   ; FC9EE4  push XBC
	ld	xbc, (xiz-34)                           ; FC9EE5  ld XBC,(XIZ+0xde)
	push	xbc                                   ; FC9EE8  push XBC
	lda	xiy, (xiz-26)                          ; FC9EE9  lda XIY,XIZ+0xe6
	call	0xFCA41F                              ; FC9EEC  call 0xfca41f
	inc	8, xix                                 ; FC9EF0  inc 0,XIX
	dec	1, h                                   ; FC9EF2  dec 1,H
	cps	h, 0                                   ; FC9EF4  cp H,0
	jr nz, sub_FC9D12__FC9EB6                  ; FC9EF6  jr NZ,0xfc9eb6
	ld	xbc, (xiz+12)                           ; FC9EF8  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC9EFB  push XBC
	ld	xbc, (xiz+8)                            ; FC9EFC  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC9EFF  push XBC
	ld	xbc, (xiz-4)                            ; FC9F00  ld XBC,(XIZ+0xfc)
	push	xbc                                   ; FC9F03  push XBC
	ld	xbc, (xiz-8)                            ; FC9F04  ld XBC,(XIZ+0xf8)
	push	xbc                                   ; FC9F07  push XBC
	lda	xiy, (xiz-34)                          ; FC9F08  lda XIY,XIZ+0xde
	call	0xFCA252                              ; FC9F0B  call 0xfca252
	ld	xbc, (xiz-30)                           ; FC9F0F  ld XBC,(XIZ+0xe2)
	push	xbc                                   ; FC9F12  push XBC
	ld	xbc, (xiz-34)                           ; FC9F13  ld XBC,(XIZ+0xde)
	push	xbc                                   ; FC9F16  push XBC
	ld	xbc, (xiz-14)                           ; FC9F17  ld XBC,(XIZ+0xf2)
	push	xbc                                   ; FC9F1A  push XBC
	ld	xbc, (xiz-18)                           ; FC9F1B  ld XBC,(XIZ+0xee)
	push	xbc                                   ; FC9F1E  push XBC
	lda	xiy, (xiz-42)                          ; FC9F1F  lda XIY,XIZ+0xd6
	call	0xFCA252                              ; FC9F22  call 0xfca252
	ld	xbc, (xiz-22)                           ; FC9F26  ld XBC,(XIZ+0xea)
	push	xbc                                   ; FC9F29  push XBC
	ld	xbc, (xiz-26)                           ; FC9F2A  ld XBC,(XIZ+0xe6)
	push	xbc                                   ; FC9F2D  push XBC
	ld	xbc, (xiz-38)                           ; FC9F2E  ld XBC,(XIZ+0xda)
	push	xbc                                   ; FC9F31  push XBC
	ld	xbc, (xiz-42)                           ; FC9F32  ld XBC,(XIZ+0xd6)
	push	xbc                                   ; FC9F35  push XBC
	lda	xiy, (xiz-50)                          ; FC9F36  lda XIY,XIZ+0xce
	call	0xFCA7A5                              ; FC9F39  call 0xfca7a5
	ld	xbc, (xiz-46)                           ; FC9F3D  ld XBC,(XIZ+0xd2)
	push	xbc                                   ; FC9F40  push XBC
	ld	xbc, (xiz-50)                           ; FC9F41  ld XBC,(XIZ+0xce)
	push	xbc                                   ; FC9F44  push XBC
	ld	xbc, (xiz+12)                           ; FC9F45  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC9F48  push XBC
	ld	xbc, (xiz+8)                            ; FC9F49  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC9F4C  push XBC
	lda	xiy, (xiz-58)                          ; FC9F4D  lda XIY,XIZ+0xc6
	call	0xFCA41F                              ; FC9F50  call 0xfca41f
	extpfx3 0x9E, 0xF6, 0x04                   ; FC9F54  pushw (XIZ+0xf6)
	lda	xiy, (xiz-66)                          ; FC9F57  lda XIY,XIZ+0xbe
	call	0xFCA997                              ; FC9F5A  call 0xfca997
	ld	xbc, (xiz-62)                           ; FC9F5E  ld XBC,(XIZ+0xc2)
	push	xbc                                   ; FC9F61  push XBC
	ld	xbc, (xiz-66)                           ; FC9F62  ld XBC,(XIZ+0xbe)
	push	xbc                                   ; FC9F65  push XBC
	ld	xbc, (0xFCB47A:24)                     ; FC9F66  ld XBC,(0xfcb47a)
	push	xbc                                   ; FC9F6B  push XBC
	ld	xbc, (0xFCB476:24)                     ; FC9F6C  ld XBC,(0xfcb476)
	push	xbc                                   ; FC9F71  push XBC
	lda	xiy, (xiz-74)                          ; FC9F72  lda XIY,XIZ+0xb6
	call	0xFCA252                              ; FC9F75  call 0xfca252
	ld	xbc, (xiz-70)                           ; FC9F79  ld XBC,(XIZ+0xba)
	push	xbc                                   ; FC9F7C  push XBC
	ld	xbc, (xiz-74)                           ; FC9F7D  ld XBC,(XIZ+0xb6)
	push	xbc                                   ; FC9F80  push XBC
	ld	xbc, (xiz-54)                           ; FC9F81  ld XBC,(XIZ+0xca)
	push	xbc                                   ; FC9F84  push XBC
	ld	xbc, (xiz-58)                           ; FC9F85  ld XBC,(XIZ+0xc6)
	push	xbc                                   ; FC9F88  push XBC
	lda	xiy, (xiz-82)                          ; FC9F89  lda XIY,XIZ+0xae
	call	0xFCA41F                              ; FC9F8C  call 0xfca41f
	ld	xiy, (xsp)                              ; FC9F90  ld XIY,(XSP)
	ld	xix, (xiz-82)                           ; FC9F92  ld XIX,(XIZ+0xae)
	stl_dpi	xix, 0xF6                          ; FC9F95  ld (XIY+),XIX
	ld	xix, (xiz-78)                           ; FC9F98  ld XIX,(XIZ+0xb2)
	ld	(xiy), xix                              ; FC9F9B  ld (XIY),XIX
sub_FC9D12__FC9F9D:
	pop	xiy                                    ; FC9F9D  pop XIY
	pop	xix                                    ; FC9F9E  pop XIX
	popw	hl                                    ; FC9F9F  pop HL
	unlk32 xiz                                 ; FC9FA0  unlk XIZ
	ret                                        ; FC9FA2  ret
; --------------------------------------------------------------------------
; sub_FC9FA3 -- 0xFC9FA3..0xFCA084 (226 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFC9D9E
; Inputs:  frame `link XIZ,-16`; argument slots read: (XIZ+0x08), (XIZ+0x0C), (XIZ+0x10)
; Outputs: no absolute-addressed write.
;          reads 0xFCB4DE, 0xFCB4E2
; Calls:   0xFCA121 = Double_Compare, 0xFCA1B6 = Double_Negate
; Evidence: the listing below is the byte-identical round-trip of 0xFC9FA3-0xFCA084
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC9FA3:
	link32 0xEE, 0x0C, 0xF0, 0xFF              ; FC9FA3  link XIZ,0xfff0
	pushw	hl                                   ; FC9FA7  push HL
	pushw	de                                   ; FC9FA8  push DE
	push	xix                                   ; FC9FA9  push XIX
	push	xiy                                   ; FC9FAA  push XIY
	ld	xbc, (0xFCB4E2:24)                     ; FC9FAB  ld XBC,(0xfcb4e2)
	push	xbc                                   ; FC9FB0  push XBC
	ld	xbc, (0xFCB4DE:24)                     ; FC9FB1  ld XBC,(0xfcb4de)
	push	xbc                                   ; FC9FB6  push XBC
	ld	xbc, (xiz+12)                           ; FC9FB7  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC9FBA  push XBC
	ld	xbc, (xiz+8)                            ; FC9FBB  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC9FBE  push XBC
	call	0xFCA121                              ; FC9FBF  call 0xfca121
	cps	wa, 2                                  ; FC9FC3  cp WA,2
	jr nz, sub_FC9FA3__FC9FCC                  ; FC9FC5  jr NZ,0xfc9fcc
	ldw	ix, 1                                  ; FC9FC7  ld IX,0x0001
	jr sub_FC9FA3__FC9FCF                      ; FC9FCA  jr T,0xfc9fcf
sub_FC9FA3__FC9FCC:
	ldw	ix, 0                                  ; FC9FCC  ld IX,0x0000
sub_FC9FA3__FC9FCF:
	push	xix                                   ; FC9FCF  push XIX
	lda	xix, (xiz-8)                           ; FC9FD0  lda XIX,XIZ+0xf8
	lda	xiy, (xiz+8)                           ; FC9FD3  lda XIY,XIZ+0x08
	ldw	bc, 4                                  ; FC9FD6  ld BC,0x0004
	extpfx2 0x95, 0x11                         ; FC9FD9  ldirw
	pop	xix                                    ; FC9FDB  pop XIX
	ld	a, (xiz-1)                              ; FC9FDC  ld A,(XIZ+0xff)
	extz	wa                                    ; FC9FDF  extz WA
	sll	wa, 8                                  ; FC9FE1  sll 0x08,WA
	ld	(xiz-10), wa                            ; FC9FE4  ld (XIZ+0xf6),WA
	ld	b, (xiz-2)                              ; FC9FE7  ld B,(XIZ+0xfe)
	ld	c, b                                    ; FC9FEA  ld C,B
	extz	bc                                    ; FC9FEC  extz BC
	ld	hl, wa                                  ; FC9FEE  ld HL,WA
	or	hl, bc                                  ; FC9FF0  or HL,BC
	ld	de, hl                                  ; FC9FF2  ld DE,HL
	add	de, de                                 ; FC9FF4  add DE,DE
	ld	bc, de                                  ; FC9FF6  ld BC,DE
	srl	bc, 5                                  ; FC9FF8  srl 0x05,BC
	ld	de, bc                                  ; FC9FFB  ld DE,BC
	jr nz, sub_FC9FA3__FCA01A                  ; FC9FFD  jr NZ,0xfca01a
	ld	xwa, (xiz+16)                           ; FC9FFF  ld XWA,(XIZ+0x10)
	extpfx4 0xB0, 0x02, 0x00, 0x00             ; FCA002  ld (XWA),0x0000
	ld	xiy, (xsp)                              ; FCA006  ld XIY,(XSP)
	ld	xix, (0xFCB4DE:24)                     ; FCA008  ld XIX,(0xfcb4de)
	stl_dpi	xix, 0xF6                          ; FCA00D  ld (XIY+),XIX
	ld	xix, (0xFCB4E2:24)                     ; FCA010  ld XIX,(0xfcb4e2)
	ld	(xiy), xix                              ; FCA015  ld (XIY),XIX
	jrl sub_FC9FA3__FCA07E                     ; FCA017  jrl T,0xfca07e
sub_FC9FA3__FCA01A:
	ld	bc, de                                  ; FCA01A  ld BC,DE
	sub	bc, 0x3FE                              ; FCA01C  sub BC,0x03fe
	ld	xwa, (xiz+16)                           ; FCA020  ld XWA,(XIZ+0x10)
	ld	(xwa), bc                               ; FCA023  ld (XWA),BC
	ld	bc, hl                                  ; FCA025  ld BC,HL
	and	bc, 15                                 ; FCA027  and BC,0x000f
	ld	hl, bc                                  ; FCA02B  ld HL,BC
	or	hl, 0x3FE0                              ; FCA02D  or HL,0x3fe0
	ld	bc, hl                                  ; FCA031  ld BC,HL
	and	bc, 0xFF                               ; FCA033  and BC,0x00ff
	ld	(xiz-2), c                              ; FCA037  ld (XIZ+0xfe),C
	ld	bc, hl                                  ; FCA03A  ld BC,HL
	srl	bc, 8                                  ; FCA03C  srl 0x08,BC
	ld	(xiz-1), c                              ; FCA03F  ld (XIZ+0xff),C
	push	xix                                   ; FCA042  push XIX
	lda	xix, (xiz+8)                           ; FCA043  lda XIX,XIZ+0x08
	lda	xiy, (xiz-8)                           ; FCA046  lda XIY,XIZ+0xf8
	ldw	bc, 4                                  ; FCA049  ld BC,0x0004
	extpfx2 0x95, 0x11                         ; FCA04C  ldirw
	pop	xix                                    ; FCA04E  pop XIX
	cps	ix, 0                                  ; FCA04F  cp IX,0
	jr z, sub_FC9FA3__FCA071                   ; FCA051  jr Z,0xfca071
	ld	xbc, (xiz+12)                           ; FCA053  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FCA056  push XBC
	ld	xbc, (xiz+8)                            ; FCA057  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FCA05A  push XBC
	lda	xiy, (xiz-16)                          ; FCA05B  lda XIY,XIZ+0xf0
	call	0xFCA1B6                              ; FCA05E  call 0xfca1b6
	ld	xiy, (xsp)                              ; FCA062  ld XIY,(XSP)
	ld	xix, (xiz-16)                           ; FCA064  ld XIX,(XIZ+0xf0)
	stl_dpi	xix, 0xF6                          ; FCA067  ld (XIY+),XIX
	ld	xix, (xiz-12)                           ; FCA06A  ld XIX,(XIZ+0xf4)
	ld	(xiy), xix                              ; FCA06D  ld (XIY),XIX
	jr sub_FC9FA3__FCA07E                      ; FCA06F  jr T,0xfca07e
sub_FC9FA3__FCA071:
	ld	xiy, (xsp)                              ; FCA071  ld XIY,(XSP)
	ld	xix, (xiz+8)                            ; FCA073  ld XIX,(XIZ+0x08)
	stl_dpi	xix, 0xF6                          ; FCA076  ld (XIY+),XIX
	ld	xix, (xiz+12)                           ; FCA079  ld XIX,(XIZ+0x0c)
	ld	(xiy), xix                              ; FCA07C  ld (XIY),XIX
sub_FC9FA3__FCA07E:
	pop	xiy                                    ; FCA07E  pop XIY
	pop	xix                                    ; FCA07F  pop XIX
	popw	de                                    ; FCA080  pop DE
	popw	hl                                    ; FCA081  pop HL
	unlk32 xiz                                 ; FCA082  unlk XIZ
	ret                                        ; FCA084  ret
; --------------------------------------------------------------------------
; sub_FCA085 -- 0xFCA085..0xFCA0B9 (53 bytes)
;
; Called from: no site outside this module.
;          2 site(s) inside this module:
;          0xFC95F6 0xFC96B6
; Inputs:  frame `link XIZ,-16`; no positive frame slot is read
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFCA085-0xFCA0B9
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FCA085:
	link32 0xEE, 0x0C, 0xF0, 0xFF              ; FCA085  link XIZ,0xfff0
	push	xix                                   ; FCA089  push XIX
	push	xiy                                   ; FCA08A  push XIY
	lda	xix, (xiz-8)                           ; FCA08B  lda XIX,XIZ+0xf8
	push	xix                                   ; FCA08E  push XIX
	lda	xiy, (xiz+8)                           ; FCA08F  lda XIY,XIZ+0x08
	ldw	bc, 4                                  ; FCA092  ld BC,0x0004
	extpfx2 0x95, 0x11                         ; FCA095  ldirw
	pop	xix                                    ; FCA097  pop XIX
	extpfx4 0x8C, 0x07, 0x3C, 0x7F             ; FCA098  and (XIX+0x07),0x7f
	push	xix                                   ; FCA09C  push XIX
	lda	xix, (xiz-16)                          ; FCA09D  lda XIX,XIZ+0xf0
	ld	xiy, (xsp)                              ; FCA0A0  ld XIY,(XSP)
	ldw	bc, 4                                  ; FCA0A2  ld BC,0x0004
	extpfx2 0x95, 0x11                         ; FCA0A5  ldirw
	pop	xix                                    ; FCA0A7  pop XIX
	ld	xiy, (xsp)                              ; FCA0A8  ld XIY,(XSP)
	ld	xix, (xiz-16)                           ; FCA0AA  ld XIX,(XIZ+0xf0)
	stl_dpi	xix, 0xF6                          ; FCA0AD  ld (XIY+),XIX
	ld	xix, (xiz-12)                           ; FCA0B0  ld XIX,(XIZ+0xf4)
	ld	(xiy), xix                              ; FCA0B3  ld (XIY),XIX
	pop	xiy                                    ; FCA0B5  pop XIY
	pop	xix                                    ; FCA0B6  pop XIX
	unlk32 xiz                                 ; FCA0B7  unlk XIZ
	ret                                        ; FCA0B9  ret

; ==============================================================================
; 0xFCA0BA-0xFCB27D -- ★★ THE COMPILER'S RUNTIME LIBRARY: soft float, 32-bit
;                      integer multiply/divide, and the variable shifts
; ==============================================================================
;
; THIRTY-EIGHT routines, 4,548 bytes, and they are one module by construction:
; every single one ends in `retd`, none of them is reached by anything except a
; `call`, and the last one ends at 0xFCB27E -- exactly where the pool of IEEE-754
; DOUBLE CONSTANTS begins.  Nothing else in this image is written this way.
;
; ★ THE ABI, READ OFF THE CODE AND NOT ASSUMED.  Three facts fix it:
;
;   1. `retd n` is CALLEE cleanup, and n IS THE ARGUMENT-BYTE COUNT.  The values
;      that occur are 2, 4, 6, 8 and 0x10, and each matches the slots the routine
;      actually loads: 0x10 is used by exactly the five routines that read four
;      32-bit slots (+0x08, +0x0C, +0x10, +0x14) -- i.e. two 64-bit doubles.
;   2. A result WIDER THAN 32 BITS IS RETURNED THROUGH A POINTER the caller puts
;      in XIY.  Every double-producing routine ends `ld XIY,(XSP) / ld (XIY+),XIX
;      / ld (XIY),XIX`, and every caller of one sets XIY with `lda XIY,XIZ+d`
;      first -- Double_Negate at 0xFCA1D1 and Int32_ToDouble at 0xFCA71E are the
;      two shortest examples.
;   3. A result of 32 bits or fewer comes back in XIY (the conversions and the
;      arithmetic) or in WA (the three CLASSIFY routines and the two COMPARE
;      routines, which return a small code).
;
; ★ THE FORMATS ARE IEEE-754, AND THE MASKS SAY SO WITHOUT ANY OUTSIDE HELP.
; Two disjoint sets of magic numbers run through the module:
;
;     DOUBLE   0x7FF0 exponent field in the high halfword, 0x8000 sign,
;              0x0010 the hidden bit, bias arithmetic against 0x3FE / 0x434 /
;              0x413 / 0x403
;     FLOAT32  0x7F80 exponent field in the high halfword, 0x7F800000 whole-word
;              exponent, 0x0080 the hidden bit, bias arithmetic against 0x96 /
;              0x97 / 0x380
;
; and no routine mixes them except the two CONVERSIONS between the formats, which
; is exactly what a conversion has to do.  The bias constants are the proofs:
;
;     Double_Multiply  add the exponents, then `sub IX,0x03FE`   = 1023 - 1
;     Double_Divide    subtract them,     then `add WA,0x0434`   = 1023 + 53
;     Float32_Divide   subtract them,     then `add WA,0x0097`   = 127 + 24
;     Double_ToFloat32                         `sub WA,0x0380`   = 1023 - 127
;     UInt32_ToDouble  starts at exponent  0x0413                = 1023 + 20
;     UInt16_ToDouble  starts at exponent  0x0403                = 1023 + 4
;     UInt32_ToFloat32 starts at exponent  0x0096                = 127 + 23
;
; ★★ AND THE SET IS COMPLETE, WHICH IS ITSELF THE STRONGEST EVIDENCE.  Assigning
; one operation per routine leaves no routine unassigned and no operation
; duplicated:
;
;     double    add sub mul div negate compare classify
;               <-> int16, <-> int32, <-> float32
;     float32   add sub mul div negate compare classify
;               <-> int16, <-> int32
;     integer   32x32 multiply and 32/32 divide, each with a signed wrapper
;     shifts    8-, 16- and 32-bit, left / logical right / arithmetic right
;
; A wrong name anywhere in that table would have to leave a hole somewhere else,
; and there is no hole.
;
; ★ THE SIGNED/UNSIGNED WRAPPER IS A SHAPE THAT REPEATS SIX TIMES, and it is how
; six of the names are settled: a short routine takes the absolute values of its
; arguments, remembers whether the sign should be flipped, `call`s a longer
; routine, and flips the result.  The six pairs are Int32_ToDouble/UInt32_ToDouble,
; Int16_ToDouble/UInt16_ToDouble, Int32_ToFloat32/UInt32_ToFloat32,
; Int16_ToFloat32/UInt16_ToFloat32, Multiply32_Signed/Multiply32 and
; Divide32_Signed/Divide32.  In five of the six the unsigned kernel is called from
; NOWHERE ELSE IN THE IMAGE; Multiply32 is the exception, because it doubles as the
; general 32x32 helper and has 28 call sites.  `notes/prom_c_runtime_check.py`
; asserts the invariant that survives -- exactly one call from inside each wrapper.
;
; ★★ FLOAT32 MULTIPLY IS A DOUBLE RECIPROCAL, AND THAT IS NOT A GUESS.
; Float32_Multiply (0xFCB005) contains no arithmetic of its own.  It loads the
; float32 constant at 0xFCB4E6 -- which is 0x3F800000, i.e. exactly 1.0 -- calls
; Float32_Divide(1.0, b), and then calls Float32_Divide(a, that).  a / (1/b) is
; a*b.  ⚠ It is also TWO roundings where one would do, so this firmware's single
; precision multiply is measurably worse than its divide.  Recorded because
; anyone emulating or re-implementing this machine will reproduce the wrong
; answer if they use a real multiply.
; The argument ORDER that reading depends on is settled inside Float32_Divide:
; it takes the exponent of (XIZ+0x08) in WA and the exponent of (XIZ+0x0C) in BC
; and computes `sub WA,BC`, so the FIRST slot is the numerator.
;
; ★ AND THIS RUNTIME IS NOT DEAD WEIGHT -- CPU 2 DOES ITS DSP ARITHMETIC IN
; FLOATING POINT.  Every one of the 38 routines has real `call` sites; the busiest
; are Double_Multiply (230), Float32_ToDouble (169), Double_ToFloat32 (164),
; Double_Subtract (91), Int32_ToFloat32 (83) and Double_Add (77), and the callers
; are spread across 0xF9Axxx-0xFA2xxx and 0xFC8xxx.  1,274 sites in total.
; ⚠ THAT TOTAL IS AN UPPER BOUND, NOT A COUNT (round-2 audit F12).  It is a byte
; census of `1D <24-bit target>` over EVERY offset of the image with no
; instruction-boundary filter, which is the same scan prom_a_call_graph.py and
; prom_b_call_graph.py both label an upper bound; this file printed it as a
; measured total.  `notes/prom_c_runtime_check.py` re-derives and asserts it as a
; REGRESSION check on the census.  Two independent spot checks land exactly
; (Double_Compare 37, Float32_Divide 2) and a 4-byte coincidence is rare, so the
; figure is probably very close -- but "probably very close" is not "measured".
; ⚠ A FIRST DRAFT OF THESE HEADERS SAID "no site found in prom_c" FOR MOST OF THE
; MODULE.  That was asserted without running the tool -- the exact failure this
; tree has had to retract before -- and every one of those sentences was wrong.
; The counts above and in each header come from
; `python3 notes/prom_c_xrefs.py <addr> --no-window`, filtered to hits whose
; preceding byte is the `call` opcode 0x1D.
;
; ⚠ WHAT IS NOT ESTABLISHED.  Rounding mode, NaN handling and the exact behaviour
; on overflow are not decoded here -- the routines have arms that force 0x7FF0 /
; 0x7F80 exponents, which is what infinity generation looks like, but no test was
; run and no databook is involved.  Nothing here says what the compiler was
; either; "the compiler's runtime library" is a description of the shape, not an
; identification of a toolchain.
;
; --------------------------------------------------------------------------
; Shift16_Left -- 16-bit value << count.
; Called from: 5 `call` sites in prom_c -- e.g. 0xF99903, 0xF99921, 0xFA6CEA.  Counted, not
;              eyeballed: `python3 notes/prom_c_xrefs.py 0xFCA0BA --no-window`,
;              whose hits are filtered to those whose preceding byte is the
;              `call` opcode 0x1D.  ⚠ THAT IS AN UPPER BOUND, NOT A DECODE:
;              nothing checks the 0x1D is itself at an instruction boundary,
;              so a literal that happens to follow a 0x1D operand byte would
;              be counted (round-2 audit F12; the same caveat applies to the
;              1,274 total in notes/prom_c_runtime_check.py).
; Inputs:  (XSP+0x04) word = the value, (XSP+0x06) byte = the count.
; Outputs: WA.  `retd 0x0004` -- four bytes of arguments, callee-popped.
; Evidence: the count is split as `count >> 4` and `count & 15` and applied with
;          `sll A,IY` in two steps, because the TLCS-900 shift takes a count of at
;          most 16 (a count field of 0 MEANS 16, which is why the high half is
;          applied with A = 0).  The whole routine is that split and nothing else.
; --------------------------------------------------------------------------
Shift16_Left:
	ld	iy, (xsp+4)                             ; FCA0BA  ld IY,(XSP+0x04)
	ld	b, (xsp+6)                              ; FCA0BD  ld B,(XSP+0x06)
	ld	w, b                                    ; FCA0C0  ld W,B
	srl	w, 4                                   ; FCA0C2  srl 0x04,W
	sub	a, a                                   ; FCA0C5  sub A,A
	cps	w, 0                                   ; FCA0C7  cp W,0
	jr z, Shift16_Left__FCA0CD                 ; FCA0C9  jr Z,0xfca0cd
	extpfx2 0xDD, 0xFE                         ; FCA0CB  sll A,IY
Shift16_Left__FCA0CD:
	ld	a, b                                    ; FCA0CD  ld A,B
	and	a, 15                                  ; FCA0CF  and A,0x0f
	jr z, Shift16_Left__FCA0D6                 ; FCA0D2  jr Z,0xfca0d6
	extpfx2 0xDD, 0xFE                         ; FCA0D4  sll A,IY
Shift16_Left__FCA0D6:
	ld	wa, iy                                  ; FCA0D6  ld WA,IY
	retd	4                                     ; FCA0D8  retd 0x0004
; --------------------------------------------------------------------------
; Shift32_LogicalRight -- 32-bit value >> count, zero-filling.
; Called from: ONE site, `call` at 0xFC8F64 (`python3 notes/prom_c_xrefs.py
;              0xFCA0DB --no-window`).
; Inputs:  (XSP+0x04) long = the value, (XSP+0x08) byte = the count.
; Outputs: XIY.  `retd 0x0006`.
; Evidence: `srl A,XIY` -- the LOGICAL right shift -- and the high half of the
;          count is applied in a LOOP here rather than once, because a 32-bit
;          shift by 16 has to be repeated for counts of 32 and above.
;          Shift32_ArithRight (0xFCAB06) is the same 15 instructions with `sra`
;          in place of `srl`; that pairing is what fixes both names.
; --------------------------------------------------------------------------
Shift32_LogicalRight:
	ld	xiy, (xsp+4)                            ; FCA0DB  ld XIY,(XSP+0x04)
	ld	b, (xsp+8)                              ; FCA0DE  ld B,(XSP+0x08)
	ld	w, b                                    ; FCA0E1  ld W,B
	srl	w, 4                                   ; FCA0E3  srl 0x04,W
	sub	a, a                                   ; FCA0E6  sub A,A
Shift32_LogicalRight__FCA0E8:
	cps	w, 0                                   ; FCA0E8  cp W,0
	jr z, Shift32_LogicalRight__FCA0F2         ; FCA0EA  jr Z,0xfca0f2
	extpfx2 0xED, 0xFF                         ; FCA0EC  srl A,XIY
	dec	1, w                                   ; FCA0EE  dec 1,W
	jr Shift32_LogicalRight__FCA0E8            ; FCA0F0  jr T,0xfca0e8
Shift32_LogicalRight__FCA0F2:
	ld	a, b                                    ; FCA0F2  ld A,B
	and	a, 15                                  ; FCA0F4  and A,0x0f
	jr z, Shift32_LogicalRight__FCA0FB         ; FCA0F7  jr Z,0xfca0fb
	extpfx2 0xED, 0xFF                         ; FCA0F9  srl A,XIY
Shift32_LogicalRight__FCA0FB:
	retd	6                                     ; FCA0FB  retd 0x0006
; --------------------------------------------------------------------------
; Shift32_Left -- 32-bit value << count.
; Called from: 3 `call` sites in prom_c -- e.g. 0xF9DFC8, 0xFC8FB8, 0xFC8FD7.  Counted, not
;              eyeballed: `python3 notes/prom_c_xrefs.py 0xFCA0FE --no-window`,
;              whose hits are filtered to those whose preceding byte is the
;              `call` opcode 0x1D.  ⚠ THAT IS AN UPPER BOUND, NOT A DECODE:
;              nothing checks the 0x1D is itself at an instruction boundary,
;              so a literal that happens to follow a 0x1D operand byte would
;              be counted (round-2 audit F12; the same caveat applies to the
;              1,274 total in notes/prom_c_runtime_check.py).
; Inputs:  (XSP+0x04) long, (XSP+0x08) byte.  Outputs: XIY.  `retd 0x0006`.
; Evidence: identical to Shift32_LogicalRight with `sll` for `srl`.
; --------------------------------------------------------------------------
Shift32_Left:
	ld	xiy, (xsp+4)                            ; FCA0FE  ld XIY,(XSP+0x04)
	ld	b, (xsp+8)                              ; FCA101  ld B,(XSP+0x08)
	ld	w, b                                    ; FCA104  ld W,B
	srl	w, 4                                   ; FCA106  srl 0x04,W
	sub	a, a                                   ; FCA109  sub A,A
Shift32_Left__FCA10B:
	cps	w, 0                                   ; FCA10B  cp W,0
	jr z, Shift32_Left__FCA115                 ; FCA10D  jr Z,0xfca115
	extpfx2 0xED, 0xFE                         ; FCA10F  sll A,XIY
	dec	1, w                                   ; FCA111  dec 1,W
	jr Shift32_Left__FCA10B                    ; FCA113  jr T,0xfca10b
Shift32_Left__FCA115:
	ld	a, b                                    ; FCA115  ld A,B
	and	a, 15                                  ; FCA117  and A,0x0f
	jr z, Shift32_Left__FCA11E                 ; FCA11A  jr Z,0xfca11e
	extpfx2 0xED, 0xFE                         ; FCA11C  sll A,XIY
Shift32_Left__FCA11E:
	retd	6                                     ; FCA11E  retd 0x0006
; --------------------------------------------------------------------------
; Double_Compare -- order two doubles.
; Called from: 37 `call` sites in prom_c -- e.g. 0xF9E65D, 0xF9E802, 0xF9EE0E.  Counted, not
;              eyeballed: `python3 notes/prom_c_xrefs.py 0xFCA121 --no-window`,
;              whose hits are filtered to those whose preceding byte is the
;              `call` opcode 0x1D.  ⚠ THAT IS AN UPPER BOUND, NOT A DECODE:
;              nothing checks the 0x1D is itself at an instruction boundary,
;              so a literal that happens to follow a 0x1D operand byte would
;              be counted (round-2 audit F12; the same caveat applies to the
;              1,274 total in notes/prom_c_runtime_check.py).
; Inputs:  two doubles, (XIZ+0x08) and (XIZ+0x10).  Outputs: WA, a small code.
;          `retd 0x0010` -- SIXTEEN bytes of arguments, i.e. two 64-bit values.
; Evidence: it reads all four 32-bit halves, masks the high halfwords with 0x7FF0
;          (the double exponent field) to detect zeros, XORs the two sign bits and
;          branches on 0x8000, and then compares the magnitudes -- the standard
;          "signs differ, so the negative one is smaller" shortcut.  It writes
;          nothing and returns a small integer in WA.
; Unknown:  the exact code returned on each ordering; the arms set WA to 0, 1 and
;          2 but which is which was not traced here.
; --------------------------------------------------------------------------
Double_Compare:
	link32 0xEE, 0x0C, 0xF6, 0xFF              ; FCA121  link XIZ,0xfff6
	push	xhl                                   ; FCA125  push XHL
	push	xde                                   ; FCA126  push XDE
	push	xix                                   ; FCA127  push XIX
	ld	xix, (xiz+12)                           ; FCA128  ld XIX,(XIZ+0x0c)
	ld	xhl, (xiz+8)                            ; FCA12B  ld XHL,(XIZ+0x08)
	ld	xiy, (xiz+20)                           ; FCA12E  ld XIY,(XIZ+0x14)
	ld	xde, (xiz+16)                           ; FCA131  ld XDE,(XIZ+0x10)
	ld	wa, qix                                 ; FCA134  ld WA,QIX
	and	wa, 0x7FF0                             ; FCA137  and WA,0x7ff0
	cps	wa, 0                                  ; FCA13B  cp WA,0
	jr nz, Double_Compare__FCA14B              ; FCA13D  jr NZ,0xfca14b
	ld	bc, qiy                                 ; FCA13F  ld BC,QIY
	and	bc, 0x7FF0                             ; FCA142  and BC,0x7ff0
	cps	bc, 0                                  ; FCA146  cp BC,0
	jrl z, Double_Compare__FCA1AC              ; FCA148  jrl Z,0xfca1ac
Double_Compare__FCA14B:
	ld	wa, qix                                 ; FCA14B  ld WA,QIX
	xor	wa, qiy                                ; FCA14E  xor WA,QIY
	and	wa, 0x8000                             ; FCA151  and WA,0x8000
	cps	wa, 0                                  ; FCA155  cp WA,0
	jr z, Double_Compare__FCA16B               ; FCA157  jr Z,0xfca16b
	ld	bc, qix                                 ; FCA159  ld BC,QIX
	cp	bc, qiy                                 ; FCA15C  cp BC,QIY
	jr nc, Double_Compare__FCA166              ; FCA15F  jr NC,0xfca166
	ldw	wa, 1                                  ; FCA161  ld WA,0x0001
	jr Double_Compare__FCA1AE                  ; FCA164  jr T,0xfca1ae
Double_Compare__FCA166:
	ldw	wa, 2                                  ; FCA166  ld WA,0x0002
	jr Double_Compare__FCA1AE                  ; FCA169  jr T,0xfca1ae
Double_Compare__FCA16B:
	ld	bc, qix                                 ; FCA16B  ld BC,QIX
	and	bc, 0x8000                             ; FCA16E  and BC,0x8000
	cps	bc, 0                                  ; FCA172  cp BC,0
	jr z, Double_Compare__FCA17B               ; FCA174  jr Z,0xfca17b
	ldw	wa, 3                                  ; FCA176  ld WA,0x0003
	jr Double_Compare__FCA17E                  ; FCA179  jr T,0xfca17e
Double_Compare__FCA17B:
	ldw	wa, 0                                  ; FCA17B  ld WA,0x0000
Double_Compare__FCA17E:
	ld	bc, qix                                 ; FCA17E  ld BC,QIX
	cp	bc, qiy                                 ; FCA181  cp BC,QIY
	jr ugt, Double_Compare__FCA1A0             ; FCA184  jr UGT,0xfca1a0
	jr c, Double_Compare__FCA1A6               ; FCA186  jr C,0xfca1a6
	cp	ix, iy                                  ; FCA188  cp IX,IY
	jr ugt, Double_Compare__FCA1A0             ; FCA18A  jr UGT,0xfca1a0
	jr c, Double_Compare__FCA1A6               ; FCA18C  jr C,0xfca1a6
	ld	bc, qhl                                 ; FCA18E  ld BC,QHL
	cp	bc, qde                                 ; FCA191  cp BC,QDE
	jr ugt, Double_Compare__FCA1A0             ; FCA194  jr UGT,0xfca1a0
	jr c, Double_Compare__FCA1A6               ; FCA196  jr C,0xfca1a6
	cp	hl, de                                  ; FCA198  cp HL,DE
	jr ugt, Double_Compare__FCA1A0             ; FCA19A  jr UGT,0xfca1a0
	jr c, Double_Compare__FCA1A6               ; FCA19C  jr C,0xfca1a6
	jr Double_Compare__FCA1AC                  ; FCA19E  jr T,0xfca1ac
Double_Compare__FCA1A0:
	xor	wa, 1                                  ; FCA1A0  xor WA,0x0001
	jr Double_Compare__FCA1AE                  ; FCA1A4  jr T,0xfca1ae
Double_Compare__FCA1A6:
	xor	wa, 2                                  ; FCA1A6  xor WA,0x0002
	jr Double_Compare__FCA1AE                  ; FCA1AA  jr T,0xfca1ae
Double_Compare__FCA1AC:
	sub	wa, wa                                 ; FCA1AC  sub WA,WA
Double_Compare__FCA1AE:
	pop	xix                                    ; FCA1AE  pop XIX
	pop	xde                                    ; FCA1AF  pop XDE
	pop	xhl                                    ; FCA1B0  pop XHL
	unlk32 xiz                                 ; FCA1B1  unlk XIZ
	retd	16                                    ; FCA1B3  retd 0x0010
; --------------------------------------------------------------------------
; Double_Negate -- flip a double's sign, except for zero.
; Called from: 24 `call` sites in prom_c -- e.g. 0xF9D71D, 0xF9D840, 0xF9D965.  Counted, not
;              eyeballed: `python3 notes/prom_c_xrefs.py 0xFCA1B6 --no-window`,
;              whose hits are filtered to those whose preceding byte is the
;              `call` opcode 0x1D.  ⚠ THAT IS AN UPPER BOUND, NOT A DECODE:
;              nothing checks the 0x1D is itself at an instruction boundary,
;              so a literal that happens to follow a 0x1D operand byte would
;              be counted (round-2 audit F12; the same caveat applies to the
;              1,274 total in notes/prom_c_runtime_check.py).
; Inputs:  one double at (XIZ+0x08); XIY = where to put the result.
;          `retd 0x0008`.
; Outputs: the negated value written through XIY.
; Evidence: it calls Double_Classify and flips (XIZ+0x0E) -- the SIGN halfword --
;          with `xor 0x8000` only when that call returns non-zero, so a zero
;          operand comes back as +0 rather than -0.  Then it copies both halves
;          out through XIY, which is the module's 64-bit return convention.
; --------------------------------------------------------------------------
Double_Negate:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FCA1B6  link XIZ,0x0000
	push	xix                                   ; FCA1BA  push XIX
	push	xiy                                   ; FCA1BB  push XIY
	ld	xbc, (xiz+12)                           ; FCA1BC  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FCA1BF  push XBC
	ld	xbc, (xiz+8)                            ; FCA1C0  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FCA1C3  push XBC
	call	0xFCA1E5                              ; FCA1C4  call 0xfca1e5
	cps	wa, 0                                  ; FCA1C8  cp WA,0
	jr z, Double_Negate__FCA1D1                ; FCA1CA  jr Z,0xfca1d1
	extpfx5 0x9E, 0x0E, 0x3D, 0x00, 0x80       ; FCA1CC  xor (XIZ+0x0e),0x8000
Double_Negate__FCA1D1:
	ld	xiy, (xsp)                              ; FCA1D1  ld XIY,(XSP)
	ld	xix, (xiz+8)                            ; FCA1D3  ld XIX,(XIZ+0x08)
	stl_dpi	xix, 0xF6                          ; FCA1D6  ld (XIY+),XIX
	ld	xix, (xiz+12)                           ; FCA1D9  ld XIX,(XIZ+0x0c)
	ld	(xiy), xix                              ; FCA1DC  ld (XIY),XIX
	pop	xiy                                    ; FCA1DE  pop XIY
	pop	xix                                    ; FCA1DF  pop XIX
	unlk32 xiz                                 ; FCA1E0  unlk XIZ
	retd	8                                     ; FCA1E2  retd 0x0008
; --------------------------------------------------------------------------
; Double_Classify -- is this double zero, and if not, what sign?
; Called from: 5 `call` sites in prom_c -- e.g. 0xFC8BC0, 0xFC8D69, 0xFCA1C4.  Counted, not
;              eyeballed: `python3 notes/prom_c_xrefs.py 0xFCA1E5 --no-window`,
;              whose hits are filtered to those whose preceding byte is the
;              `call` opcode 0x1D.  ⚠ THAT IS AN UPPER BOUND, NOT A DECODE:
;              nothing checks the 0x1D is itself at an instruction boundary,
;              so a literal that happens to follow a 0x1D operand byte would
;              be counted (round-2 audit F12; the same caveat applies to the
;              1,274 total in notes/prom_c_runtime_check.py).
; Inputs:  one double at (XIZ+0x08).  Outputs: WA = 0, 1 or 2.  `retd 0x0008`.
; Evidence: the first test masks the high halfword with 0x7FF0 and returns early
;          when the exponent field is zero; the second masks 0x8000 and splits on
;          the sign.  Float32_Classify (0xFCB075) is the same routine with 0x7F80
;          for 0x7FF0, and Double_Negate and Float32_Negate use them the same way,
;          which is what makes the pair readable at all.
; Unknown:  which of 1 and 2 means negative.  Not traced; the callers here only
;          test against zero.
; --------------------------------------------------------------------------
Double_Classify:
	link32 0xEE, 0x0C, 0xFA, 0xFF              ; FCA1E5  link XIZ,0xfffa
	push	xde                                   ; FCA1E9  push XDE
	push	xix                                   ; FCA1EA  push XIX
	ld	xix, (xiz+12)                           ; FCA1EB  ld XIX,(XIZ+0x0c)
	ld	xde, (xiz+8)                            ; FCA1EE  ld XDE,(XIZ+0x08)
	ld	bc, qix                                 ; FCA1F1  ld BC,QIX
	and	bc, 0x7FF0                             ; FCA1F4  and BC,0x7ff0
	cps	bc, 0                                  ; FCA1F8  cp BC,0
	jrl z, Double_Classify__FCA249             ; FCA1FA  jrl Z,0xfca249
	ld	bc, qix                                 ; FCA1FD  ld BC,QIX
	and	bc, 0x8000                             ; FCA200  and BC,0x8000
	cps	bc, 0                                  ; FCA204  cp BC,0
	jr z, Double_Classify__FCA217              ; FCA206  jr Z,0xfca217
	cp	qix, 0                                  ; FCA208  cp QIX,0
	jr nc, Double_Classify__FCA212             ; FCA20B  jr NC,0xfca212
	ldw	wa, 1                                  ; FCA20D  ld WA,0x0001
	jr Double_Classify__FCA24B                 ; FCA210  jr T,0xfca24b
Double_Classify__FCA212:
	ldw	wa, 2                                  ; FCA212  ld WA,0x0002
	jr Double_Classify__FCA24B                 ; FCA215  jr T,0xfca24b
Double_Classify__FCA217:
	jr z, Double_Classify__FCA21E              ; FCA217  jr Z,0xfca21e
	ldw	wa, 3                                  ; FCA219  ld WA,0x0003
	jr Double_Classify__FCA221                 ; FCA21C  jr T,0xfca221
Double_Classify__FCA21E:
	ldw	wa, 0                                  ; FCA21E  ld WA,0x0000
Double_Classify__FCA221:
	cp	qix, 0                                  ; FCA221  cp QIX,0
	jr ugt, Double_Classify__FCA23D            ; FCA224  jr UGT,0xfca23d
	jr c, Double_Classify__FCA243              ; FCA226  jr C,0xfca243
	cps	ix, 0                                  ; FCA228  cp IX,0
	jr ugt, Double_Classify__FCA23D            ; FCA22A  jr UGT,0xfca23d
	jr c, Double_Classify__FCA243              ; FCA22C  jr C,0xfca243
	cp	qde, 0                                  ; FCA22E  cp QDE,0
	jr ugt, Double_Classify__FCA23D            ; FCA231  jr UGT,0xfca23d
	jr c, Double_Classify__FCA243              ; FCA233  jr C,0xfca243
	cps	de, 0                                  ; FCA235  cp DE,0
	jr ugt, Double_Classify__FCA23D            ; FCA237  jr UGT,0xfca23d
	jr c, Double_Classify__FCA243              ; FCA239  jr C,0xfca243
	jr Double_Classify__FCA249                 ; FCA23B  jr T,0xfca249
Double_Classify__FCA23D:
	xor	wa, 1                                  ; FCA23D  xor WA,0x0001
	jr Double_Classify__FCA24B                 ; FCA241  jr T,0xfca24b
Double_Classify__FCA243:
	xor	wa, 2                                  ; FCA243  xor WA,0x0002
	jr Double_Classify__FCA24B                 ; FCA247  jr T,0xfca24b
Double_Classify__FCA249:
	sub	wa, wa                                 ; FCA249  sub WA,WA
Double_Classify__FCA24B:
	pop	xix                                    ; FCA24B  pop XIX
	pop	xde                                    ; FCA24C  pop XDE
	unlk32 xiz                                 ; FCA24D  unlk XIZ
	retd	8                                     ; FCA24F  retd 0x0008
; --------------------------------------------------------------------------
; Double_Multiply -- a * b, both doubles.
; Called from: 230 `call` sites in prom_c -- e.g. 0xF9AF3C, 0xF9B1EB, 0xF9B3A6.  Counted, not
;              eyeballed: `python3 notes/prom_c_xrefs.py 0xFCA252 --no-window`,
;              whose hits are filtered to those whose preceding byte is the
;              `call` opcode 0x1D.  ⚠ THAT IS AN UPPER BOUND, NOT A DECODE:
;              nothing checks the 0x1D is itself at an instruction boundary,
;              so a literal that happens to follow a 0x1D operand byte would
;              be counted (round-2 audit F12; the same caveat applies to the
;              1,274 total in notes/prom_c_runtime_check.py).
; Inputs:  two doubles, (XIZ+0x08) and (XIZ+0x10); XIY = the result pointer.
;          `retd 0x0010`.
; Evidence: ★ the exponent arithmetic is the identification.  It XORs the two sign
;          halfwords, extracts both exponent fields with `and 0x7FF0 / srl 4`,
;          restores both hidden bits with `or 0x0010`, and then does
;          `add IX,IY` followed by `sub IX,0x03FE`.  Adding exponents is
;          multiplication, and 0x3FE = 1023 - 1 is the double bias less one --
;          the correction a product needs because two values in [1,2) give a
;          product in [1,4).  The mantissa work that follows is four `mul` cross
;          products accumulated with `adc`, which is a 53x53 bit multiply built
;          out of 16x16.
;          The overflow/underflow guards are literal: `cp IX,0 / jrl LE` and
;          `cp IX,0x07FF / jrl GT`, 0x7FF being the reserved double exponent.
; --------------------------------------------------------------------------
Double_Multiply:
	link32 0xEE, 0x0C, 0x68, 0xFF              ; FCA252  link XIZ,0xff68
	pushw	de                                   ; FCA256  push DE
	push	xhl                                   ; FCA257  push XHL
	push	xix                                   ; FCA258  push XIX
	push	xiy                                   ; FCA259  push XIY
	ld	wa, (xiz+22)                            ; FCA25A  ld WA,(XIZ+0x16)
	extpfx3 0x9E, 0x0E, 0xD0                   ; FCA25D  xor WA,(XIZ+0x0e)
	and	wa, 0x8000                             ; FCA260  and WA,0x8000
	ld	qix, wa                                 ; FCA264  ld QIX,WA
	ld	ix, (xiz+22)                            ; FCA267  ld IX,(XIZ+0x16)
	and	ix, 0x7FF0                             ; FCA26A  and IX,0x7ff0
	srl	ix, 4                                  ; FCA26E  srl 0x04,IX
	cps	ix, 0                                  ; FCA271  cp IX,0
	jrl z, Double_Multiply__FCA3CD             ; FCA273  jrl Z,0xfca3cd
	ld	de, (xiz+22)                            ; FCA276  ld DE,(XIZ+0x16)
	and	de, 15                                 ; FCA279  and DE,0x000f
	or	de, 16                                  ; FCA27D  or DE,0x0010
	ld	(xiz+22), de                            ; FCA281  ld (XIZ+0x16),DE
	ld	iy, (xiz+14)                            ; FCA284  ld IY,(XIZ+0x0e)
	and	iy, 0x7FF0                             ; FCA287  and IY,0x7ff0
	srl	iy, 4                                  ; FCA28B  srl 0x04,IY
	cps	iy, 0                                  ; FCA28E  cp IY,0
	jrl z, Double_Multiply__FCA3CD             ; FCA290  jrl Z,0xfca3cd
	ld	de, (xiz+14)                            ; FCA293  ld DE,(XIZ+0x0e)
	and	de, 15                                 ; FCA296  and DE,0x000f
	or	de, 16                                  ; FCA29A  or DE,0x0010
	ld	(xiz+14), de                            ; FCA29E  ld (XIZ+0x0e),DE
	add	ix, iy                                 ; FCA2A1  add IX,IY
	sub	ix, 0x3FE                              ; FCA2A3  sub IX,0x03fe
	cps	ix, 0                                  ; FCA2A7  cp IX,0
	jrl le, Double_Multiply__FCA3CD            ; FCA2A9  jrl LE,0xfca3cd
	cp	ix, 0x7FF                               ; FCA2AC  cp IX,0x07ff
	jrl gt, Double_Multiply__FCA3A9            ; FCA2B0  jrl GT,0xfca3a9
	ld	iy, (xiz+16)                            ; FCA2B3  ld IY,(XIZ+0x10)
	extpfx3 0x9E, 0x08, 0x45                   ; FCA2B6  mul XIY,(XIZ+0x08)
	ld	bc, qiy                                 ; FCA2B9  ld BC,QIY
	ldw	wa, 0                                  ; FCA2BC  ld WA,0x0000
	ldw	hl, 0                                  ; FCA2BF  ld HL,0x0000
	ld	iy, (xiz+18)                            ; FCA2C2  ld IY,(XIZ+0x12)
	extpfx3 0x9E, 0x08, 0x45                   ; FCA2C5  mul XIY,(XIZ+0x08)
	add	bc, iy                                 ; FCA2C8  add BC,IY
	adc	wa, qiy                                ; FCA2CA  adc WA,QIY
	adc	hl, hl                                 ; FCA2CD  adc HL,HL
	ld	iy, (xiz+16)                            ; FCA2CF  ld IY,(XIZ+0x10)
	extpfx3 0x9E, 0x0A, 0x45                   ; FCA2D2  mul XIY,(XIZ+0x0a)
	add	bc, iy                                 ; FCA2D5  add BC,IY
	adc	wa, qiy                                ; FCA2D7  adc WA,QIY
	adc	hl, 0                                  ; FCA2DA  adc HL,0x0000
	ld	iy, (xiz+18)                            ; FCA2DE  ld IY,(XIZ+0x12)
	extpfx3 0x9E, 0x0A, 0x45                   ; FCA2E1  mul XIY,(XIZ+0x0a)
	add	wa, iy                                 ; FCA2E4  add WA,IY
	adc	hl, qiy                                ; FCA2E6  adc HL,QIY
	ldw	de, 0                                  ; FCA2E9  ld DE,0x0000
	adc	de, de                                 ; FCA2EC  adc DE,DE
	ld	iy, (xiz+16)                            ; FCA2EE  ld IY,(XIZ+0x10)
	extpfx3 0x9E, 0x0C, 0x45                   ; FCA2F1  mul XIY,(XIZ+0x0c)
	add	wa, iy                                 ; FCA2F4  add WA,IY
	adc	hl, qiy                                ; FCA2F6  adc HL,QIY
	adc	de, 0                                  ; FCA2F9  adc DE,0x0000
	ld	iy, (xiz+20)                            ; FCA2FD  ld IY,(XIZ+0x14)
	extpfx3 0x9E, 0x08, 0x45                   ; FCA300  mul XIY,(XIZ+0x08)
	add	wa, iy                                 ; FCA303  add WA,IY
	adc	hl, qiy                                ; FCA305  adc HL,QIY
	adc	de, 0                                  ; FCA308  adc DE,0x0000
	ld	iy, (xiz+22)                            ; FCA30C  ld IY,(XIZ+0x16)
	extpfx3 0x9E, 0x08, 0x45                   ; FCA30F  mul XIY,(XIZ+0x08)
	add	hl, iy                                 ; FCA312  add HL,IY
	adc	de, qiy                                ; FCA314  adc DE,QIY
	ldw	bc, 0                                  ; FCA317  ld BC,0x0000
	adc	bc, bc                                 ; FCA31A  adc BC,BC
	ld	iy, (xiz+20)                            ; FCA31C  ld IY,(XIZ+0x14)
	extpfx3 0x9E, 0x0A, 0x45                   ; FCA31F  mul XIY,(XIZ+0x0a)
	add	hl, iy                                 ; FCA322  add HL,IY
	adc	de, qiy                                ; FCA324  adc DE,QIY
	adc	bc, 0                                  ; FCA327  adc BC,0x0000
	ld	iy, (xiz+18)                            ; FCA32B  ld IY,(XIZ+0x12)
	extpfx3 0x9E, 0x0C, 0x45                   ; FCA32E  mul XIY,(XIZ+0x0c)
	add	hl, iy                                 ; FCA331  add HL,IY
	adc	de, qiy                                ; FCA333  adc DE,QIY
	adc	bc, 0                                  ; FCA336  adc BC,0x0000
	ld	iy, (xiz+16)                            ; FCA33A  ld IY,(XIZ+0x10)
	extpfx3 0x9E, 0x0E, 0x45                   ; FCA33D  mul XIY,(XIZ+0x0e)
	add	hl, iy                                 ; FCA340  add HL,IY
	adc	de, qiy                                ; FCA342  adc DE,QIY
	adc	bc, 0                                  ; FCA345  adc BC,0x0000
	ld	iy, (xiz+18)                            ; FCA349  ld IY,(XIZ+0x12)
	extpfx3 0x9E, 0x0E, 0x45                   ; FCA34C  mul XIY,(XIZ+0x0e)
	add	de, iy                                 ; FCA34F  add DE,IY
	adc	bc, qiy                                ; FCA351  adc BC,QIY
	ldw	wa, 0                                  ; FCA354  ld WA,0x0000
	adc	wa, wa                                 ; FCA357  adc WA,WA
	ld	iy, (xiz+22)                            ; FCA359  ld IY,(XIZ+0x16)
	extpfx3 0x9E, 0x0A, 0x45                   ; FCA35C  mul XIY,(XIZ+0x0a)
	add	de, iy                                 ; FCA35F  add DE,IY
	adc	bc, qiy                                ; FCA361  adc BC,QIY
	adc	wa, 0                                  ; FCA364  adc WA,0x0000
	ld	iy, (xiz+20)                            ; FCA368  ld IY,(XIZ+0x14)
	extpfx3 0x9E, 0x0C, 0x45                   ; FCA36B  mul XIY,(XIZ+0x0c)
	add	de, iy                                 ; FCA36E  add DE,IY
	adc	bc, qiy                                ; FCA370  adc BC,QIY
	adc	wa, 0                                  ; FCA373  adc WA,0x0000
	ld	iy, (xiz+22)                            ; FCA377  ld IY,(XIZ+0x16)
	extpfx3 0x9E, 0x0C, 0x45                   ; FCA37A  mul XIY,(XIZ+0x0c)
	add	bc, iy                                 ; FCA37D  add BC,IY
	adc	wa, qiy                                ; FCA37F  adc WA,QIY
	ld	iy, (xiz+20)                            ; FCA382  ld IY,(XIZ+0x14)
	extpfx3 0x9E, 0x0E, 0x45                   ; FCA385  mul XIY,(XIZ+0x0e)
	add	bc, iy                                 ; FCA388  add BC,IY
	adc	wa, qiy                                ; FCA38A  adc WA,QIY
	ld	iy, (xiz+22)                            ; FCA38D  ld IY,(XIZ+0x16)
	extpfx3 0x9E, 0x0E, 0x45                   ; FCA390  mul XIY,(XIZ+0x0e)
	add	wa, iy                                 ; FCA393  add WA,IY
	ld	qbc, wa                                 ; FCA395  ld QBC,WA
	ld	qhl, de                                 ; FCA398  ld QHL,DE
	and	wa, 0x200                              ; FCA39B  and WA,0x0200
	cps	wa, 0                                  ; FCA39F  cp WA,0
	jr z, Double_Multiply__FCA3C7              ; FCA3A1  jr Z,0xfca3c7
	cp	ix, 0x7FF                               ; FCA3A3  cp IX,0x07ff
	jr nz, Double_Multiply__FCA3BF             ; FCA3A7  jr NZ,0xfca3bf
Double_Multiply__FCA3A9:
	ld	xbc, 0                                  ; FCA3A9  ld XBC,0x00000000
	ld	xhl, 0                                  ; FCA3AE  ld XHL,0x00000000
	ld	wa, qix                                 ; FCA3B3  ld WA,QIX
	xor	wa, 0x7FF0                             ; FCA3B6  xor WA,0x7ff0
	ld	qbc, wa                                 ; FCA3BA  ld QBC,WA
	jr Double_Multiply__FCA40F                 ; FCA3BD  jr T,0xfca40f
Double_Multiply__FCA3BF:
	srl	xbc, 1                                 ; FCA3BF  srl 0x01,XBC
	rr	xhl                                     ; FCA3C2  rr 0x01,XHL
	jr Double_Multiply__FCA3D9                 ; FCA3C5  jr T,0xfca3d9
Double_Multiply__FCA3C7:
	dec	1, ix                                  ; FCA3C7  dec 1,IX
	cps	ix, 0                                  ; FCA3C9  cp IX,0
	jr nz, Double_Multiply__FCA3D9             ; FCA3CB  jr NZ,0xfca3d9
Double_Multiply__FCA3CD:
	ld	xbc, 0                                  ; FCA3CD  ld XBC,0x00000000
	ld	xhl, 0                                  ; FCA3D2  ld XHL,0x00000000
	jr Double_Multiply__FCA40F                 ; FCA3D7  jr T,0xfca40f
Double_Multiply__FCA3D9:
	add	xhl, 8                                 ; FCA3D9  add XHL,0x00000008
	adc	xbc, 0                                 ; FCA3DF  adc XBC,0x00000000
	srl	xbc, 1                                 ; FCA3E5  srl 0x01,XBC
	rr	xhl                                     ; FCA3E8  rr 0x01,XHL
	srl	xbc, 1                                 ; FCA3EB  srl 0x01,XBC
	rr	xhl                                     ; FCA3EE  rr 0x01,XHL
	srl	xbc, 1                                 ; FCA3F1  srl 0x01,XBC
	rr	xhl                                     ; FCA3F4  rr 0x01,XHL
	srl	xbc, 1                                 ; FCA3F7  srl 0x01,XBC
	rr	xhl                                     ; FCA3FA  rr 0x01,XHL
	ld	wa, qbc                                 ; FCA3FD  ld WA,QBC
	xor	wa, 16                                 ; FCA400  xor WA,0x0010
	sll	ix, 4                                  ; FCA404  sll 0x04,IX
	or	ix, qix                                 ; FCA407  or IX,QIX
	or	wa, ix                                  ; FCA40A  or WA,IX
	ld	qbc, wa                                 ; FCA40C  ld QBC,WA
Double_Multiply__FCA40F:
	ld	xix, (xsp)                              ; FCA40F  ld XIX,(XSP)
	stl_dpi	xhl, 0xF2                          ; FCA411  ld (XIX+),XHL
	ld	(xix), xbc                              ; FCA414  ld (XIX),XBC
	pop	xiy                                    ; FCA416  pop XIY
	pop	xix                                    ; FCA417  pop XIX
	pop	xhl                                    ; FCA418  pop XHL
	popw	de                                    ; FCA419  pop DE
	unlk32 xiz                                 ; FCA41A  unlk XIZ
	retd	16                                    ; FCA41C  retd 0x0010
; --------------------------------------------------------------------------
; Double_Add -- a + b, both doubles.
; Called from: 77 `call` sites in prom_c -- e.g. 0xF9C31F, 0xFC8C1E, 0xFCA649.  Counted, not
;              eyeballed: `python3 notes/prom_c_xrefs.py 0xFCA41F --no-window`,
;              whose hits are filtered to those whose preceding byte is the
;              `call` opcode 0x1D.  ⚠ THAT IS AN UPPER BOUND, NOT A DECODE:
;              nothing checks the 0x1D is itself at an instruction boundary,
;              so a literal that happens to follow a 0x1D operand byte would
;              be counted (round-2 audit F12; the same caveat applies to the
;              1,274 total in notes/prom_c_runtime_check.py).
; Inputs:  two doubles, (XIZ+0x08) and (XIZ+0x10); XIY = the result pointer.
;          `retd 0x0010`.
; Evidence: ★ it is named by its CALLER as much as by itself.  Double_Subtract
;          (0xFCA626) does exactly three things: flip the sign halfword of the
;          SECOND operand with `xor 0x8000`, push both operands unchanged, and
;          call this routine.  a + (-b) is a - b, and nothing else that
;          transformation could be paired with makes sense.
;          Internally it separates sign (0x8000) from magnitude (0x7FFF), extracts
;          exponents with 0x7FF0, restores hidden bits with 0x0010, and aligns the
;          smaller operand before adding -- the classic add/subtract kernel.
; --------------------------------------------------------------------------
Double_Add:
	link32 0xEE, 0x0C, 0xE4, 0xFF              ; FCA41F  link XIZ,0xffe4
	push	xhl                                   ; FCA423  push XHL
	push	xde                                   ; FCA424  push XDE
	push	xix                                   ; FCA425  push XIX
	push	xiy                                   ; FCA426  push XIY
	ld	xix, (xiz+12)                           ; FCA427  ld XIX,(XIZ+0x0c)
	ld	xhl, (xiz+8)                            ; FCA42A  ld XHL,(XIZ+0x08)
	ld	xiy, (xiz+20)                           ; FCA42D  ld XIY,(XIZ+0x14)
	ld	xde, (xiz+16)                           ; FCA430  ld XDE,(XIZ+0x10)
	extpfx3 0xD7, 0xF2, 0xBC                   ; FCA433  ex IX,QIX
	extpfx3 0xD7, 0xF6, 0xBD                   ; FCA436  ex IY,QIY
	ld	wa, ix                                  ; FCA439  ld WA,IX
	and	wa, 0x8000                             ; FCA43B  and WA,0x8000
	and	ix, 0x7FFF                             ; FCA43F  and IX,0x7fff
	ld	bc, iy                                  ; FCA443  ld BC,IY
	and	bc, 0x8000                             ; FCA445  and BC,0x8000
	ld	qwa, bc                                 ; FCA449  ld QWA,BC
	and	iy, 0x7FFF                             ; FCA44C  and IY,0x7fff
	extpfx3 0xD7, 0xF2, 0xBC                   ; FCA450  ex IX,QIX
	extpfx3 0xD7, 0xF6, 0xBD                   ; FCA453  ex IY,QIY
	ld	bc, qix                                 ; FCA456  ld BC,QIX
	and	bc, 0x7FF0                             ; FCA459  and BC,0x7ff0
	cps	bc, 0                                  ; FCA45D  cp BC,0
	jr nz, Double_Add__FCA46D                  ; FCA45F  jr NZ,0xfca46d
	ld	bc, qiy                                 ; FCA461  ld BC,QIY
	and	bc, 0x7FF0                             ; FCA464  and BC,0x7ff0
	cps	bc, 0                                  ; FCA468  cp BC,0
	jrl z, Double_Add__FCA5BF                  ; FCA46A  jrl Z,0xfca5bf
Double_Add__FCA46D:
	ld	bc, qix                                 ; FCA46D  ld BC,QIX
	cp	bc, qiy                                 ; FCA470  cp BC,QIY
	jr ugt, Double_Add__FCA49C                 ; FCA473  jr UGT,0xfca49c
	jr c, Double_Add__FCA48D                   ; FCA475  jr C,0xfca48d
	cp	ix, iy                                  ; FCA477  cp IX,IY
	jr ugt, Double_Add__FCA49C                 ; FCA479  jr UGT,0xfca49c
	jr c, Double_Add__FCA48D                   ; FCA47B  jr C,0xfca48d
	ld	bc, qhl                                 ; FCA47D  ld BC,QHL
	cp	bc, qde                                 ; FCA480  cp BC,QDE
	jr ugt, Double_Add__FCA49C                 ; FCA483  jr UGT,0xfca49c
	jr c, Double_Add__FCA48D                   ; FCA485  jr C,0xfca48d
	cp	hl, de                                  ; FCA487  cp HL,DE
	jr c, Double_Add__FCA48D                   ; FCA489  jr C,0xfca48d
	jr Double_Add__FCA49C                      ; FCA48B  jr T,0xfca49c
Double_Add__FCA48D:
	ld	xbc, xix                                ; FCA48D  ld XBC,XIX
	ld	xix, xiy                                ; FCA48F  ld XIX,XIY
	ld	xiy, xbc                                ; FCA491  ld XIY,XBC
	ld	xbc, xhl                                ; FCA493  ld XBC,XHL
	ld	xhl, xde                                ; FCA495  ld XHL,XDE
	ld	xde, xbc                                ; FCA497  ld XDE,XBC
	extpfx3 0xD7, 0xE2, 0xB8                   ; FCA499  ex WA,QWA
Double_Add__FCA49C:
	ld	bc, wa                                  ; FCA49C  ld BC,WA
	xor	bc, qwa                                ; FCA49E  xor BC,QWA
	cps	bc, 0                                  ; FCA4A1  cp BC,0
	jr z, Double_Add__FCA4A9                   ; FCA4A3  jr Z,0xfca4a9
	ldb	a, 45                                  ; FCA4A5  ld A,0x2d
	jr Double_Add__FCA4AB                      ; FCA4A7  jr T,0xfca4ab
Double_Add__FCA4A9:
	ldb	a, 43                                  ; FCA4A9  ld A,0x2b
Double_Add__FCA4AB:
	extpfx3 0xD7, 0xF2, 0xBC                   ; FCA4AB  ex IX,QIX
	extpfx3 0xD7, 0xF6, 0xBD                   ; FCA4AE  ex IY,QIY
	ld	bc, ix                                  ; FCA4B1  ld BC,IX
	and	bc, 0x7FF0                             ; FCA4B3  and BC,0x7ff0
	ld	qwa, bc                                 ; FCA4B7  ld QWA,BC
	xor	ix, qwa                                ; FCA4BA  xor IX,QWA
	or	ix, 16                                  ; FCA4BD  or IX,0x0010
	extpfx4 0xD7, 0xE2, 0xEF, 0x04             ; FCA4C1  srl 0x04,QWA
	ld	bc, iy                                  ; FCA4C5  ld BC,IY
	and	bc, 0x7FF0                             ; FCA4C7  and BC,0x7ff0
	ld	qbc, bc                                 ; FCA4CB  ld QBC,BC
	xor	iy, qbc                                ; FCA4CE  xor IY,QBC
	or	iy, 16                                  ; FCA4D1  or IY,0x0010
	extpfx4 0xD7, 0xE6, 0xEF, 0x04             ; FCA4D5  srl 0x04,QBC
	extpfx3 0xD7, 0xF2, 0xBC                   ; FCA4D9  ex IX,QIX
	extpfx3 0xD7, 0xF6, 0xBD                   ; FCA4DC  ex IY,QIY
	sla	xhl, 1                                 ; FCA4DF  sla 0x01,XHL
	rl	xix                                     ; FCA4E2  rl 0x01,XIX
	sla	xhl, 1                                 ; FCA4E5  sla 0x01,XHL
	rl	xix                                     ; FCA4E8  rl 0x01,XIX
	sla	xde, 1                                 ; FCA4EB  sla 0x01,XDE
	rl	xiy                                     ; FCA4EE  rl 0x01,XIY
	sla	xde, 1                                 ; FCA4F1  sla 0x01,XDE
	rl	xiy                                     ; FCA4F4  rl 0x01,XIY
	ld	bc, qwa                                 ; FCA4F7  ld BC,QWA
	sub	bc, qbc                                ; FCA4FA  sub BC,QBC
	cp	bc, 54                                  ; FCA4FD  cp BC,0x0036
	jrl ugt, Double_Add__FCA5DE                ; FCA501  jrl UGT,0xfca5de
	cp	qbc, 0                                  ; FCA504  cp QBC,0
	jrl z, Double_Add__FCA5DE                  ; FCA507  jrl Z,0xfca5de
Double_Add__FCA50A:
	ld	qbc, bc                                 ; FCA50A  ld QBC,BC
	dec	1, bc                                  ; FCA50D  dec 1,BC
	cp	qbc, 0                                  ; FCA50F  cp QBC,0
	jr z, Double_Add__FCA51C                   ; FCA512  jr Z,0xfca51c
	srl	xiy, 1                                 ; FCA514  srl 0x01,XIY
	rr	xde                                     ; FCA517  rr 0x01,XDE
	jr Double_Add__FCA50A                      ; FCA51A  jr T,0xfca50a
Double_Add__FCA51C:
	cp	a, 43                                   ; FCA51C  cp A,0x2b
	jrl nz, Double_Add__FCA58E                 ; FCA51F  jrl NZ,0xfca58e
	ldb	a, 0                                   ; FCA522  ld A,0x00
	add	xhl, xde                               ; FCA524  add XHL,XDE
	adc	xix, xiy                               ; FCA526  adc XIX,XIY
	ld	bc, qix                                 ; FCA528  ld BC,QIX
	and	bc, 0xFF80                             ; FCA52B  and BC,0xff80
	cps	bc, 0                                  ; FCA52F  cp BC,0
	jr z, Double_Add__FCA554                   ; FCA531  jr Z,0xfca554
	srl	xix, 1                                 ; FCA533  srl 0x01,XIX
	rr	xhl                                     ; FCA536  rr 0x01,XHL
	inc	1, qwa                                 ; FCA539  inc 1,QWA
	cpw	qwa, 0x7FF                             ; FCA53C  cp QWA,0x07ff
	jr c, Double_Add__FCA554                   ; FCA541  jr C,0xfca554
	sub	xix, xix                               ; FCA543  sub XIX,XIX
	sub	xhl, xhl                               ; FCA545  sub XHL,XHL
	ldw	qix, 0x7FF0                            ; FCA547  ld QIX,0x7ff0
	cps	wa, 0                                  ; FCA54C  cp WA,0
	jrl z, Double_Add__FCA616                  ; FCA54E  jrl Z,0xfca616
	jrl Double_Add__FCA60C                     ; FCA551  jrl T,0xfca60c
Double_Add__FCA554:
	add	xhl, 1                                 ; FCA554  add XHL,0x00000001
	adc	xix, 0                                 ; FCA55A  adc XIX,0x00000000
	ld	bc, qix                                 ; FCA560  ld BC,QIX
	and	bc, 0xFF80                             ; FCA563  and BC,0xff80
	cps	bc, 0                                  ; FCA567  cp BC,0
	jrl z, Double_Add__FCA5DE                  ; FCA569  jrl Z,0xfca5de
	srl	xix, 1                                 ; FCA56C  srl 0x01,XIX
	rr	xhl                                     ; FCA56F  rr 0x01,XHL
	inc	1, qwa                                 ; FCA572  inc 1,QWA
	cpw	qwa, 0x7FF                             ; FCA575  cp QWA,0x07ff
	jrl c, Double_Add__FCA5DE                  ; FCA57A  jrl C,0xfca5de
	sub	xix, xix                               ; FCA57D  sub XIX,XIX
	sub	xhl, xhl                               ; FCA57F  sub XHL,XHL
	ldw	qix, 0x7FF0                            ; FCA581  ld QIX,0x7ff0
	cps	wa, 0                                  ; FCA586  cp WA,0
	jrl z, Double_Add__FCA616                  ; FCA588  jrl Z,0xfca616
	jrl Double_Add__FCA60C                     ; FCA58B  jrl T,0xfca60c
Double_Add__FCA58E:
	sub	xhl, xde                               ; FCA58E  sub XHL,XDE
	sbc	xix, xiy                               ; FCA590  sbc XIX,XIY
	cp	qix, 0                                  ; FCA592  cp QIX,0
	jr nz, Double_Add__FCA5A6                  ; FCA595  jr NZ,0xfca5a6
	cps	ix, 0                                  ; FCA597  cp IX,0
	jr nz, Double_Add__FCA5A6                  ; FCA599  jr NZ,0xfca5a6
	cp	qhl, 0                                  ; FCA59B  cp QHL,0
	jr nz, Double_Add__FCA5A6                  ; FCA59E  jr NZ,0xfca5a6
	cps	hl, 0                                  ; FCA5A0  cp HL,0
	jr nz, Double_Add__FCA5A6                  ; FCA5A2  jr NZ,0xfca5a6
	jr z, Double_Add__FCA5BF                   ; FCA5A4  jr Z,0xfca5bf
Double_Add__FCA5A6:
	ld	bc, qix                                 ; FCA5A6  ld BC,QIX
	and	bc, 0xFFC0                             ; FCA5A9  and BC,0xffc0
	cps	bc, 0                                  ; FCA5AD  cp BC,0
	jr nz, Double_Add__FCA5D2                  ; FCA5AF  jr NZ,0xfca5d2
Double_Add__FCA5B1:
	sla	xhl, 1                                 ; FCA5B1  sla 0x01,XHL
	rl	xix                                     ; FCA5B4  rl 0x01,XIX
	dec	1, qwa                                 ; FCA5B7  dec 1,QWA
	cp	qwa, 1                                  ; FCA5BA  cp QWA,1
	jr nc, Double_Add__FCA5C5                  ; FCA5BD  jr NC,0xfca5c5
Double_Add__FCA5BF:
	sub	xix, xix                               ; FCA5BF  sub XIX,XIX
	sub	xhl, xhl                               ; FCA5C1  sub XHL,XHL
	jr Double_Add__FCA616                      ; FCA5C3  jr T,0xfca616
Double_Add__FCA5C5:
	ld	bc, qix                                 ; FCA5C5  ld BC,QIX
	and	bc, 0xFFC0                             ; FCA5C8  and BC,0xffc0
	cps	bc, 0                                  ; FCA5CC  cp BC,0
	jr nz, Double_Add__FCA5DE                  ; FCA5CE  jr NZ,0xfca5de
	jr Double_Add__FCA5B1                      ; FCA5D0  jr T,0xfca5b1
Double_Add__FCA5D2:
	add	xhl, 1                                 ; FCA5D2  add XHL,0x00000001
	adc	xix, 0                                 ; FCA5D8  adc XIX,0x00000000
Double_Add__FCA5DE:
	srl	xix, 1                                 ; FCA5DE  srl 0x01,XIX
	rr	xhl                                     ; FCA5E1  rr 0x01,XHL
	srl	xix, 1                                 ; FCA5E4  srl 0x01,XIX
	rr	xhl                                     ; FCA5E7  rr 0x01,XHL
	extpfx4 0xD7, 0xE2, 0xEE, 0x04             ; FCA5EA  sll 0x04,QWA
	ld	bc, qix                                 ; FCA5EE  ld BC,QIX
	xor	bc, 16                                 ; FCA5F1  xor BC,0x0010
	or	bc, qwa                                 ; FCA5F5  or BC,QWA
	ld	qix, bc                                 ; FCA5F8  ld QIX,BC
	ldb	a, 0                                   ; FCA5FB  ld A,0x00
	cps	wa, 0                                  ; FCA5FD  cp WA,0
	jr z, Double_Add__FCA616                   ; FCA5FF  jr Z,0xfca616
	ld	bc, qix                                 ; FCA601  ld BC,QIX
	and	bc, 0x7FF0                             ; FCA604  and BC,0x7ff0
	cps	bc, 0                                  ; FCA608  cp BC,0
	jr z, Double_Add__FCA616                   ; FCA60A  jr Z,0xfca616
Double_Add__FCA60C:
	ld	bc, qix                                 ; FCA60C  ld BC,QIX
	xor	bc, 0x8000                             ; FCA60F  xor BC,0x8000
	ld	qix, bc                                 ; FCA613  ld QIX,BC
Double_Add__FCA616:
	ld	xiy, (xsp)                              ; FCA616  ld XIY,(XSP)
	stl_dpi	xhl, 0xF6                          ; FCA618  ld (XIY+),XHL
	ld	(xiy), xix                              ; FCA61B  ld (XIY),XIX
	pop	xiy                                    ; FCA61D  pop XIY
	pop	xix                                    ; FCA61E  pop XIX
	pop	xde                                    ; FCA61F  pop XDE
	pop	xhl                                    ; FCA620  pop XHL
	unlk32 xiz                                 ; FCA621  unlk XIZ
	retd	16                                    ; FCA623  retd 0x0010
; --------------------------------------------------------------------------
; Double_Subtract -- a - b, implemented as a + (-b).
; Called from: 91 `call` sites in prom_c -- e.g. 0xF9B5D1, 0xF9B69A, 0xF9B7A6.  Counted, not
;              eyeballed: `python3 notes/prom_c_xrefs.py 0xFCA626 --no-window`,
;              whose hits are filtered to those whose preceding byte is the
;              `call` opcode 0x1D.  ⚠ THAT IS AN UPPER BOUND, NOT A DECODE:
;              nothing checks the 0x1D is itself at an instruction boundary,
;              so a literal that happens to follow a 0x1D operand byte would
;              be counted (round-2 audit F12; the same caveat applies to the
;              1,274 total in notes/prom_c_runtime_check.py).
; Inputs:  two doubles; XIY = the result pointer.  `retd 0x0010`.
; Evidence: twenty-five instructions, of which the only arithmetic is
;          `ld WA,QIX / xor WA,0x8000 / ld QIX,WA` on the SECOND operand's high
;          halfword, followed by `call Double_Add` with both operands pushed in
;          their original order.  It then copies Double_Add's result out through
;          its own XIY.
; --------------------------------------------------------------------------
Double_Subtract:
	link32 0xEE, 0x0C, 0xF0, 0xFF              ; FCA626  link XIZ,0xfff0
	push	xix                                   ; FCA62A  push XIX
	push	xiy                                   ; FCA62B  push XIY
	ld	xix, (xiz+20)                           ; FCA62C  ld XIX,(XIZ+0x14)
	ld	xiy, (xiz+16)                           ; FCA62F  ld XIY,(XIZ+0x10)
	ld	wa, qix                                 ; FCA632  ld WA,QIX
	xor	wa, 0x8000                             ; FCA635  xor WA,0x8000
	ld	qix, wa                                 ; FCA639  ld QIX,WA
	push	xix                                   ; FCA63C  push XIX
	push	xiy                                   ; FCA63D  push XIY
	ld	xiy, (xiz+12)                           ; FCA63E  ld XIY,(XIZ+0x0c)
	push	xiy                                   ; FCA641  push XIY
	ld	xiy, (xiz+8)                            ; FCA642  ld XIY,(XIZ+0x08)
	push	xiy                                   ; FCA645  push XIY
	lda	xiy, (xiz-16)                          ; FCA646  lda XIY,XIZ+0xf0
	call	0xFCA41F                              ; FCA649  call 0xfca41f
	ld	xiy, (xsp)                              ; FCA64D  ld XIY,(XSP)
	ld	xix, (xiz-16)                           ; FCA64F  ld XIX,(XIZ+0xf0)
	stl_dpi	xix, 0xF6                          ; FCA652  ld (XIY+),XIX
	ld	xix, (xiz-12)                           ; FCA655  ld XIX,(XIZ+0xf4)
	ld	(xiy), xix                              ; FCA658  ld (XIY),XIX
	pop	xiy                                    ; FCA65A  pop XIY
	pop	xix                                    ; FCA65B  pop XIX
	unlk32 xiz                                 ; FCA65C  unlk XIZ
	retd	16                                    ; FCA65E  retd 0x0010
; --------------------------------------------------------------------------
; Double_ToInt32 -- truncate a double to a 32-bit integer.
; Called from: 7 `call` sites in prom_c -- e.g. 0xF9AF48, 0xF9B1F7, 0xF9B3B2.  Counted, not
;              eyeballed: `python3 notes/prom_c_xrefs.py 0xFCA661 --no-window`,
;              whose hits are filtered to those whose preceding byte is the
;              `call` opcode 0x1D.  ⚠ THAT IS AN UPPER BOUND, NOT A DECODE:
;              nothing checks the 0x1D is itself at an instruction boundary,
;              so a literal that happens to follow a 0x1D operand byte would
;              be counted (round-2 audit F12; the same caveat applies to the
;              1,274 total in notes/prom_c_runtime_check.py).
; Inputs:  one double at (XIZ+0x08).  Outputs: XIY.  `retd 0x0008`.
; Evidence: it extracts the exponent with 0x7FF0, restores the hidden bit with
;          0x0010, and shifts the mantissa by the difference against **0x0413**.
;          0x413 = 1043 = 1023 + 20 is the double exponent of a value whose
;          integer part just fills 32 bits -- the same constant UInt32_ToDouble
;          (0xFCA746) *starts* from, which is what makes the two the inverse pair.
;          The sign is taken out first (0x8000) and re-applied at the end with
;          0x80000000, i.e. on the 32-bit result.
; --------------------------------------------------------------------------
Double_ToInt32:
	link32 0xEE, 0x0C, 0xF6, 0xFF              ; FCA661  link XIZ,0xfff6
	pushw	hl                                   ; FCA665  push HL
	pushw	de                                   ; FCA666  push DE
	push	xix                                   ; FCA667  push XIX
	ldw	hl, 10                                 ; FCA668  ld HL,0x000a
	ld	de, (xiz+14)                            ; FCA66B  ld DE,(XIZ+0x0e)
	ld	bc, de                                  ; FCA66E  ld BC,DE
	and	bc, 0x8000                             ; FCA670  and BC,0x8000
	cps	bc, 0                                  ; FCA674  cp BC,0
	jr z, Double_ToInt32__FCA67D               ; FCA676  jr Z,0xfca67d
	ldw	hl, 11                                 ; FCA678  ld HL,0x000b
	xor	de, bc                                 ; FCA67B  xor DE,BC
Double_ToInt32__FCA67D:
	ld	wa, de                                  ; FCA67D  ld WA,DE
	and	wa, 0x7FF0                             ; FCA67F  and WA,0x7ff0
	xor	de, wa                                 ; FCA683  xor DE,WA
	or	de, 16                                  ; FCA685  or DE,0x0010
	sra	wa, 4                                  ; FCA689  sra 0x04,WA
	cps	wa, 0                                  ; FCA68C  cp WA,0
	jr nz, Double_ToInt32__FCA695              ; FCA68E  jr NZ,0xfca695
	sub	xiy, xiy                               ; FCA690  sub XIY,XIY
	jrl Double_ToInt32__FCA6F5                 ; FCA692  jrl T,0xfca6f5
Double_ToInt32__FCA695:
	ld	qiy, de                                 ; FCA695  ld QIY,DE
	ld	iy, (xiz+12)                            ; FCA698  ld IY,(XIZ+0x0c)
	ld	xix, (xiz+8)                            ; FCA69B  ld XIX,(XIZ+0x08)
	sub	wa, 0x413                              ; FCA69E  sub WA,0x0413
	cps	wa, 0                                  ; FCA6A2  cp WA,0
	jr lt, Double_ToInt32__FCA6C0              ; FCA6A4  jr LT,0xfca6c0
	cp	wa, hl                                  ; FCA6A6  cp WA,HL
	jr le, Double_ToInt32__FCA6B0              ; FCA6A8  jr LE,0xfca6b0
	cps	bc, 0                                  ; FCA6AA  cp BC,0
	jr z, Double_ToInt32__FCA6E3               ; FCA6AC  jr Z,0xfca6e3
	jr Double_ToInt32__FCA6DC                  ; FCA6AE  jr T,0xfca6dc
Double_ToInt32__FCA6B0:
	ld	de, wa                                  ; FCA6B0  ld DE,WA
	dec	1, wa                                  ; FCA6B2  dec 1,WA
	cps	de, 0                                  ; FCA6B4  cp DE,0
	jr z, Double_ToInt32__FCA6D0               ; FCA6B6  jr Z,0xfca6d0
	sla	xix, 1                                 ; FCA6B8  sla 0x01,XIX
	rl	xiy                                     ; FCA6BB  rl 0x01,XIY
	jr Double_ToInt32__FCA6B0                  ; FCA6BE  jr T,0xfca6b0
Double_ToInt32__FCA6C0:
	ld	de, wa                                  ; FCA6C0  ld DE,WA
	inc	1, wa                                  ; FCA6C2  inc 1,WA
	cps	de, 0                                  ; FCA6C4  cp DE,0
	jr z, Double_ToInt32__FCA6D0               ; FCA6C6  jr Z,0xfca6d0
	sra	xiy, 1                                 ; FCA6C8  sra 0x01,XIY
	rr	xix                                     ; FCA6CB  rr 0x01,XIX
	jr Double_ToInt32__FCA6C0                  ; FCA6CE  jr T,0xfca6c0
Double_ToInt32__FCA6D0:
	cp	xiy, 0x80000000                         ; FCA6D0  cp XIY,0x80000000
	jr c, Double_ToInt32__FCA6EA               ; FCA6D6  jr C,0xfca6ea
	cps	bc, 0                                  ; FCA6D8  cp BC,0
	jr z, Double_ToInt32__FCA6E3               ; FCA6DA  jr Z,0xfca6e3
Double_ToInt32__FCA6DC:
	ld	xiy, 0x80000000                         ; FCA6DC  ld XIY,0x80000000
	jr Double_ToInt32__FCA6F5                  ; FCA6E1  jr T,0xfca6f5
Double_ToInt32__FCA6E3:
	ld	xiy, 0x7FFFFFFF                         ; FCA6E3  ld XIY,0x7fffffff
	jr Double_ToInt32__FCA6F5                  ; FCA6E8  jr T,0xfca6f5
Double_ToInt32__FCA6EA:
	cps	bc, 0                                  ; FCA6EA  cp BC,0
	jr z, Double_ToInt32__FCA6F5               ; FCA6EC  jr Z,0xfca6f5
	cpl	iy                                     ; FCA6EE  cpl IY
	cpl	qiy                                    ; FCA6F0  cpl QIY
	inc	1, xiy                                 ; FCA6F3  inc 1,XIY
Double_ToInt32__FCA6F5:
	pop	xix                                    ; FCA6F5  pop XIX
	popw	de                                    ; FCA6F6  pop DE
	popw	hl                                    ; FCA6F7  pop HL
	unlk32 xiz                                 ; FCA6F8  unlk XIZ
	retd	8                                     ; FCA6FA  retd 0x0008
; --------------------------------------------------------------------------
; Int32_ToDouble -- signed 32-bit integer to double.
; Called from: 25 `call` sites in prom_c -- e.g. 0xF9C35B, 0xF9C3B8, 0xFA0137.  Counted, not
;              eyeballed: `python3 notes/prom_c_xrefs.py 0xFCA6FD --no-window`,
;              whose hits are filtered to those whose preceding byte is the
;              `call` opcode 0x1D.  ⚠ THAT IS AN UPPER BOUND, NOT A DECODE:
;              nothing checks the 0x1D is itself at an instruction boundary,
;              so a literal that happens to follow a 0x1D operand byte would
;              be counted (round-2 audit F12; the same caveat applies to the
;              1,274 total in notes/prom_c_runtime_check.py).
; Inputs:  (XIZ+0x08) long; XIY = the result pointer.  `retd 0x0004`.
; Evidence: the wrapper shape.  It tests bit 31 with `and XIX,0x80000000`, negates
;          the value with `cpl IY / cpl QIY / inc 1,XIY` when set, calls
;          UInt32_ToDouble, and then flips the result's sign halfword with
;          `xor (XIZ-2),0x8000`.  Five other pairs in this module are built the
;          same way.
; --------------------------------------------------------------------------
Int32_ToDouble:
	link32 0xEE, 0x0C, 0xF8, 0xFF              ; FCA6FD  link XIZ,0xfff8
	push	xix                                   ; FCA701  push XIX
	push	xiy                                   ; FCA702  push XIY
	ld	xiy, (xiz+8)                            ; FCA703  ld XIY,(XIZ+0x08)
	ld	xix, xiy                                ; FCA706  ld XIX,XIY
	and	xix, 0x80000000                        ; FCA708  and XIX,0x80000000
	cp	xix, 0                                  ; FCA70E  cp XIX,0x00000000
	jr z, Int32_ToDouble__FCA71D               ; FCA714  jr Z,0xfca71d
	cpl	iy                                     ; FCA716  cpl IY
	cpl	qiy                                    ; FCA718  cpl QIY
	inc	1, xiy                                 ; FCA71B  inc 1,XIY
Int32_ToDouble__FCA71D:
	push	xiy                                   ; FCA71D  push XIY
	lda	xiy, (xiz-8)                           ; FCA71E  lda XIY,XIZ+0xf8
	call	0xFCA746                              ; FCA721  call 0xfca746
	cp	xix, 0                                  ; FCA725  cp XIX,0x00000000
	jr z, Int32_ToDouble__FCA732               ; FCA72B  jr Z,0xfca732
	extpfx5 0x9E, 0xFE, 0x3D, 0x00, 0x80       ; FCA72D  xor (XIZ+0xfe),0x8000
Int32_ToDouble__FCA732:
	ld	xiy, (xsp)                              ; FCA732  ld XIY,(XSP)
	ld	xix, (xiz-8)                            ; FCA734  ld XIX,(XIZ+0xf8)
	stl_dpi	xix, 0xF6                          ; FCA737  ld (XIY+),XIX
	ld	xix, (xiz-4)                            ; FCA73A  ld XIX,(XIZ+0xfc)
	ld	(xiy), xix                              ; FCA73D  ld (XIY),XIX
	pop	xiy                                    ; FCA73F  pop XIY
	pop	xix                                    ; FCA740  pop XIX
	unlk32 xiz                                 ; FCA741  unlk XIZ
	retd	4                                     ; FCA743  retd 0x0004
; --------------------------------------------------------------------------
; UInt32_ToDouble -- unsigned 32-bit integer to double.
; Called from: ONE site, `call` at 0xFCA721 -- Int32_ToDouble, the signed wrapper
;              immediately above.  Census: `python3 notes/prom_c_xrefs.py
;              0xFCA746 --no-window`.
; Inputs:  (XIZ+0x08) long; XIY = the result pointer.  `retd 0x0004`.
; Evidence: `ldw de,0x0413` is the whole argument -- 1043 = 1023 + 20 -- and the
;          normalising loop shifts XIX right and XIY right-through-carry while
;          incrementing DE until the top eleven bits (`and BC,0xFFE0` on the high
;          halfword) are clear.  Shifting the value down while raising the
;          exponent from a fixed start is integer-to-float and nothing else.
;          A zero input short-circuits to a zero result (`cp XIX,0 / jr Z`).
; --------------------------------------------------------------------------
UInt32_ToDouble:
	link32 0xEE, 0x0C, 0xF4, 0xFF              ; FCA746  link XIZ,0xfff4
	push	xde                                   ; FCA74A  push XDE
	push	xix                                   ; FCA74B  push XIX
	push	xiy                                   ; FCA74C  push XIY
	sub	xiy, xiy                               ; FCA74D  sub XIY,XIY
	ld	xix, (xiz+8)                            ; FCA74F  ld XIX,(XIZ+0x08)
	cp	xix, 0                                  ; FCA752  cp XIX,0x00000000
	jr z, UInt32_ToDouble__FCA796              ; FCA758  jr Z,0xfca796
	ldw	de, 0x413                              ; FCA75A  ld DE,0x0413
UInt32_ToDouble__FCA75D:
	ld	bc, qix                                 ; FCA75D  ld BC,QIX
	and	bc, 0xFFE0                             ; FCA760  and BC,0xffe0
	cps	bc, 0                                  ; FCA764  cp BC,0
	jr z, UInt32_ToDouble__FCA772              ; FCA766  jr Z,0xfca772
	srl	xix, 1                                 ; FCA768  srl 0x01,XIX
	rr	xiy                                     ; FCA76B  rr 0x01,XIY
	inc	1, de                                  ; FCA76E  inc 1,DE
	jr UInt32_ToDouble__FCA75D                 ; FCA770  jr T,0xfca75d
UInt32_ToDouble__FCA772:
	ld	bc, qix                                 ; FCA772  ld BC,QIX
	and	bc, 0xFFF0                             ; FCA775  and BC,0xfff0
	cps	bc, 0                                  ; FCA779  cp BC,0
	jr nz, UInt32_ToDouble__FCA787             ; FCA77B  jr NZ,0xfca787
	sla	xiy, 1                                 ; FCA77D  sla 0x01,XIY
	rl	xix                                     ; FCA780  rl 0x01,XIX
	dec	1, de                                  ; FCA783  dec 1,DE
	jr UInt32_ToDouble__FCA772                 ; FCA785  jr T,0xfca772
UInt32_ToDouble__FCA787:
	sll	de, 4                                  ; FCA787  sll 0x04,DE
	ld	bc, qix                                 ; FCA78A  ld BC,QIX
	xor	bc, 16                                 ; FCA78D  xor BC,0x0010
	or	bc, de                                  ; FCA791  or BC,DE
	ld	qix, bc                                 ; FCA793  ld QIX,BC
UInt32_ToDouble__FCA796:
	ld	xde, (xsp)                              ; FCA796  ld XDE,(XSP)
	stl_dpi	xiy, 0xEA                          ; FCA798  ld (XDE+),XIY
	ld	(xde), xix                              ; FCA79B  ld (XDE),XIX
	pop	xiy                                    ; FCA79D  pop XIY
	pop	xix                                    ; FCA79E  pop XIX
	pop	xde                                    ; FCA79F  pop XDE
	unlk32 xiz                                 ; FCA7A0  unlk XIZ
	retd	4                                     ; FCA7A2  retd 0x0004
; --------------------------------------------------------------------------
; Double_Divide -- a / b, both doubles.
; Called from: 45 `call` sites in prom_c -- e.g. 0xF9C3A9, 0xF9C508, 0xF9C5FC.  Counted, not
;              eyeballed: `python3 notes/prom_c_xrefs.py 0xFCA7A5 --no-window`,
;              whose hits are filtered to those whose preceding byte is the
;              `call` opcode 0x1D.  ⚠ THAT IS AN UPPER BOUND, NOT A DECODE:
;              nothing checks the 0x1D is itself at an instruction boundary,
;              so a literal that happens to follow a 0x1D operand byte would
;              be counted (round-2 audit F12; the same caveat applies to the
;              1,274 total in notes/prom_c_runtime_check.py).
; Inputs:  two doubles, (XIZ+0x08) and (XIZ+0x10); XIY = the result pointer.
;          `retd 0x0010`.
; Evidence: ★ the mirror image of Double_Multiply, and the two constants are what
;          separate them.  Same sign XOR, same 0x7FF0 exponent extraction, same
;          0x0010 hidden-bit restore -- but then `sub WA,DE` followed by
;          `add WA,0x0434`.  SUBTRACTING exponents is division, and 0x434 =
;          1076 = 1023 + 53 is the bias plus the mantissa width, the scaling a
;          restoring divider needs to keep 53 bits of quotient.
; --------------------------------------------------------------------------
Double_Divide:
	link32 0xEE, 0x0C, 0xDA, 0xFF              ; FCA7A5  link XIZ,0xffda
	push	xhl                                   ; FCA7A9  push XHL
	push	xde                                   ; FCA7AA  push XDE
	push	xix                                   ; FCA7AB  push XIX
	push	xiy                                   ; FCA7AC  push XIY
	ld	bc, (xiz+14)                            ; FCA7AD  ld BC,(XIZ+0x0e)
	extpfx3 0x9E, 0x16, 0xD1                   ; FCA7B0  xor BC,(XIZ+0x16)
	and	bc, 0x8000                             ; FCA7B3  and BC,0x8000
	ld	qbc, bc                                 ; FCA7B7  ld QBC,BC
	extpfx5 0x9E, 0x0E, 0x3C, 0xFF, 0x7F       ; FCA7BA  and (XIZ+0x0e),0x7fff
	extpfx5 0x9E, 0x16, 0x3C, 0xFF, 0x7F       ; FCA7BF  and (XIZ+0x16),0x7fff
	ld	wa, (xiz+14)                            ; FCA7C4  ld WA,(XIZ+0x0e)
	and	wa, 0x7FF0                             ; FCA7C7  and WA,0x7ff0
	xor	(xiz+14), wa                           ; FCA7CB  xor (XIZ+0x0e),WA
	extpfx5 0x9E, 0x0E, 0x3E, 0x10, 0x00       ; FCA7CE  or (XIZ+0x0e),0x0010
	sra	wa, 4                                  ; FCA7D3  sra 0x04,WA
	cps	wa, 0                                  ; FCA7D6  cp WA,0
	jrl z, Double_Divide__FCA89F               ; FCA7D8  jrl Z,0xfca89f
	cp	wa, 0x7FF                               ; FCA7DB  cp WA,0x07ff
	jr ge, Double_Divide__FCA800               ; FCA7DF  jr GE,0xfca800
	ld	de, (xiz+22)                            ; FCA7E1  ld DE,(XIZ+0x16)
	and	de, 0x7FF0                             ; FCA7E4  and DE,0x7ff0
	xor	(xiz+22), de                           ; FCA7E8  xor (XIZ+0x16),DE
	extpfx5 0x9E, 0x16, 0x3E, 0x10, 0x00       ; FCA7EB  or (XIZ+0x16),0x0010
	sra	de, 4                                  ; FCA7F0  sra 0x04,DE
	cps	de, 0                                  ; FCA7F3  cp DE,0
	jr z, Double_Divide__FCA800                ; FCA7F5  jr Z,0xfca800
	cp	de, 0x7FF                               ; FCA7F7  cp DE,0x07ff
	jrl ge, Double_Divide__FCA89F              ; FCA7FB  jrl GE,0xfca89f
	jr Double_Divide__FCA812                   ; FCA7FE  jr T,0xfca812
Double_Divide__FCA800:
	sub	xiy, xiy                               ; FCA800  sub XIY,XIY
	sub	xix, xix                               ; FCA802  sub XIX,XIX
	ldw	qix, 0x7FF0                            ; FCA804  ld QIX,0x7ff0
	cp	qbc, 0                                  ; FCA809  cp QBC,0
	jrl z, Double_Divide__FCA8C3               ; FCA80C  jrl Z,0xfca8c3
	jrl Double_Divide__FCA8B9                  ; FCA80F  jrl T,0xfca8b9
Double_Divide__FCA812:
	sub	wa, de                                 ; FCA812  sub WA,DE
	add	wa, 0x434                              ; FCA814  add WA,0x0434
	sub	xiy, xiy                               ; FCA818  sub XIY,XIY
	sub	xix, xix                               ; FCA81A  sub XIX,XIX
	ld	xhl, (xiz+12)                           ; FCA81C  ld XHL,(XIZ+0x0c)
	ld	xde, (xiz+8)                            ; FCA81F  ld XDE,(XIZ+0x08)
Double_Divide__FCA822:
	sla	xiy, 1                                 ; FCA822  sla 0x01,XIY
	rl	xix                                     ; FCA825  rl 0x01,XIX
	ld	bc, qhl                                 ; FCA828  ld BC,QHL
	extpfx3 0x9E, 0x16, 0xF1                   ; FCA82B  cp BC,(XIZ+0x16)
	jr ugt, Double_Divide__FCA848              ; FCA82E  jr UGT,0xfca848
	jr c, Double_Divide__FCA85A                ; FCA830  jr C,0xfca85a
	extpfx3 0x9E, 0x14, 0xF3                   ; FCA832  cp HL,(XIZ+0x14)
	jr ugt, Double_Divide__FCA848              ; FCA835  jr UGT,0xfca848
	jr c, Double_Divide__FCA85A                ; FCA837  jr C,0xfca85a
	ld	bc, qde                                 ; FCA839  ld BC,QDE
	extpfx3 0x9E, 0x12, 0xF1                   ; FCA83C  cp BC,(XIZ+0x12)
	jr ugt, Double_Divide__FCA848              ; FCA83F  jr UGT,0xfca848
	jr c, Double_Divide__FCA85A                ; FCA841  jr C,0xfca85a
	extpfx3 0x9E, 0x10, 0xF2                   ; FCA843  cp DE,(XIZ+0x10)
	jr c, Double_Divide__FCA85A                ; FCA846  jr C,0xfca85a
Double_Divide__FCA848:
	add	xiy, 1                                 ; FCA848  add XIY,0x00000001
	adc	xix, 0                                 ; FCA84E  adc XIX,0x00000000
	extpfx3 0xAE, 0x10, 0xA2                   ; FCA854  sub XDE,(XIZ+0x10)
	extpfx3 0xAE, 0x14, 0xB3                   ; FCA857  sbc XHL,(XIZ+0x14)
Double_Divide__FCA85A:
	sla	xde, 1                                 ; FCA85A  sla 0x01,XDE
	rl	xhl                                     ; FCA85D  rl 0x01,XHL
	dec	1, wa                                  ; FCA860  dec 1,WA
	ld	bc, qix                                 ; FCA862  ld BC,QIX
	and	bc, 0x80                               ; FCA865  and BC,0x0080
	cps	bc, 0                                  ; FCA869  cp BC,0
	jr z, Double_Divide__FCA822                ; FCA86B  jr Z,0xfca822
	add	xiy, 1                                 ; FCA86D  add XIY,0x00000001
	adc	xix, 0                                 ; FCA873  adc XIX,0x00000000
	ldw	de, 3                                  ; FCA879  ld DE,0x0003
	ld	bc, qix                                 ; FCA87C  ld BC,QIX
	and	bc, 0x80                               ; FCA87F  and BC,0x0080
	cps	bc, 0                                  ; FCA883  cp BC,0
	jr nz, Double_Divide__FCA889               ; FCA885  jr NZ,0xfca889
	inc	1, de                                  ; FCA887  inc 1,DE
Double_Divide__FCA889:
	add	wa, de                                 ; FCA889  add WA,DE
Double_Divide__FCA88B:
	ld	bc, de                                  ; FCA88B  ld BC,DE
	dec	1, de                                  ; FCA88D  dec 1,DE
	cps	bc, 0                                  ; FCA88F  cp BC,0
	jr z, Double_Divide__FCA89B                ; FCA891  jr Z,0xfca89b
	srl	xix, 1                                 ; FCA893  srl 0x01,XIX
	rr	xiy                                     ; FCA896  rr 0x01,XIY
	jr Double_Divide__FCA88B                   ; FCA899  jr T,0xfca88b
Double_Divide__FCA89B:
	cps	wa, 1                                  ; FCA89B  cp WA,1
	jr ge, Double_Divide__FCA8A5               ; FCA89D  jr GE,0xfca8a5
Double_Divide__FCA89F:
	sub	xiy, xiy                               ; FCA89F  sub XIY,XIY
	sub	xix, xix                               ; FCA8A1  sub XIX,XIX
	jr Double_Divide__FCA8C3                   ; FCA8A3  jr T,0xfca8c3
Double_Divide__FCA8A5:
	cp	wa, 0x7FF                               ; FCA8A5  cp WA,0x07ff
	jr lt, Double_Divide__FCA8C5               ; FCA8A9  jr LT,0xfca8c5
	sub	xiy, xiy                               ; FCA8AB  sub XIY,XIY
	sub	xix, xix                               ; FCA8AD  sub XIX,XIX
	ldw	qix, 0x7FF0                            ; FCA8AF  ld QIX,0x7ff0
	cp	qbc, 0                                  ; FCA8B4  cp QBC,0
	jr z, Double_Divide__FCA8C3                ; FCA8B7  jr Z,0xfca8c3
Double_Divide__FCA8B9:
	ld	hl, qix                                 ; FCA8B9  ld HL,QIX
	xor	hl, 0x8000                             ; FCA8BC  xor HL,0x8000
	ld	qix, hl                                 ; FCA8C0  ld QIX,HL
Double_Divide__FCA8C3:
	jr Double_Divide__FCA8F3                   ; FCA8C3  jr T,0xfca8f3
Double_Divide__FCA8C5:
	sll	wa, 4                                  ; FCA8C5  sll 0x04,WA
	ld	hl, qix                                 ; FCA8C8  ld HL,QIX
	xor	hl, 16                                 ; FCA8CB  xor HL,0x0010
	or	hl, wa                                  ; FCA8CF  or HL,WA
	ld	qix, hl                                 ; FCA8D1  ld QIX,HL
	cp	qbc, 0                                  ; FCA8D4  cp QBC,0
	jr z, Double_Divide__FCA8F3                ; FCA8D7  jr Z,0xfca8f3
	ld	hl, qix                                 ; FCA8D9  ld HL,QIX
	and	hl, 0x7FF0                             ; FCA8DC  and HL,0x7ff0
	cps	hl, 0                                  ; FCA8E0  cp HL,0
	jr z, Double_Divide__FCA8F3                ; FCA8E2  jr Z,0xfca8f3
	cp	qix, 0                                  ; FCA8E4  cp QIX,0
	jr z, Double_Divide__FCA8F3                ; FCA8E7  jr Z,0xfca8f3
	ld	hl, qix                                 ; FCA8E9  ld HL,QIX
	xor	hl, 0x8000                             ; FCA8EC  xor HL,0x8000
	ld	qix, hl                                 ; FCA8F0  ld QIX,HL
Double_Divide__FCA8F3:
	ld	xde, (xsp)                              ; FCA8F3  ld XDE,(XSP)
	stl_dpi	xiy, 0xEA                          ; FCA8F5  ld (XDE+),XIY
	ld	(xde), xix                              ; FCA8F8  ld (XDE),XIX
	pop	xiy                                    ; FCA8FA  pop XIY
	pop	xix                                    ; FCA8FB  pop XIX
	pop	xde                                    ; FCA8FC  pop XDE
	pop	xhl                                    ; FCA8FD  pop XHL
	unlk32 xiz                                 ; FCA8FE  unlk XIZ
	retd	16                                    ; FCA900  retd 0x0010
; --------------------------------------------------------------------------
; Double_ToInt16 -- truncate a double to a 16-bit integer.
; Called from: ONE site, `call` at 0xFC9A0C (`python3 notes/prom_c_xrefs.py
;              0xFCA903 --no-window`).
; Inputs:  one double at (XIZ+0x08).  Outputs: XIY.  `retd 0x0008`.
; Evidence: the same routine as Double_ToInt32 with **0x0403** in place of
;          0x0413 -- 1027 = 1023 + 4, the exponent of a value whose integer part
;          just fills 16 bits, and the constant UInt16_ToDouble starts from.
;          Two conversions differing only in that one constant is what fixes both
;          widths.
; --------------------------------------------------------------------------
Double_ToInt16:
	link32 0xEE, 0x0C, 0xF6, 0xFF              ; FCA903  link XIZ,0xfff6
	pushw	hl                                   ; FCA907  push HL
	pushw	de                                   ; FCA908  push DE
	push	xix                                   ; FCA909  push XIX
	ldw	hl, 10                                 ; FCA90A  ld HL,0x000a
	ld	de, (xiz+14)                            ; FCA90D  ld DE,(XIZ+0x0e)
	ld	bc, de                                  ; FCA910  ld BC,DE
	and	bc, 0x8000                             ; FCA912  and BC,0x8000
	cps	bc, 0                                  ; FCA916  cp BC,0
	jr z, Double_ToInt16__FCA91F               ; FCA918  jr Z,0xfca91f
	ldw	hl, 11                                 ; FCA91A  ld HL,0x000b
	xor	de, bc                                 ; FCA91D  xor DE,BC
Double_ToInt16__FCA91F:
	ld	wa, de                                  ; FCA91F  ld WA,DE
	and	wa, 0x7FF0                             ; FCA921  and WA,0x7ff0
	xor	de, wa                                 ; FCA925  xor DE,WA
	or	de, 16                                  ; FCA927  or DE,0x0010
	sra	wa, 4                                  ; FCA92B  sra 0x04,WA
	cps	wa, 0                                  ; FCA92E  cp WA,0
	jr nz, Double_ToInt16__FCA937              ; FCA930  jr NZ,0xfca937
	sub	wa, wa                                 ; FCA932  sub WA,WA
	jrl Double_ToInt16__FCA98F                 ; FCA934  jrl T,0xfca98f
Double_ToInt16__FCA937:
	ld	qiy, de                                 ; FCA937  ld QIY,DE
	ld	iy, (xiz+12)                            ; FCA93A  ld IY,(XIZ+0x0c)
	ld	xix, (xiz+8)                            ; FCA93D  ld XIX,(XIZ+0x08)
	sub	wa, 0x403                              ; FCA940  sub WA,0x0403
	cps	wa, 0                                  ; FCA944  cp WA,0
	jr lt, Double_ToInt16__FCA962              ; FCA946  jr LT,0xfca962
	cp	wa, hl                                  ; FCA948  cp WA,HL
	jr le, Double_ToInt16__FCA952              ; FCA94A  jr LE,0xfca952
	cps	bc, 0                                  ; FCA94C  cp BC,0
	jr z, Double_ToInt16__FCA984               ; FCA94E  jr Z,0xfca984
	jr Double_ToInt16__FCA97F                  ; FCA950  jr T,0xfca97f
Double_ToInt16__FCA952:
	ld	de, wa                                  ; FCA952  ld DE,WA
	dec	1, wa                                  ; FCA954  dec 1,WA
	cps	de, 0                                  ; FCA956  cp DE,0
	jr z, Double_ToInt16__FCA972               ; FCA958  jr Z,0xfca972
	sla	xix, 1                                 ; FCA95A  sla 0x01,XIX
	rl	xiy                                     ; FCA95D  rl 0x01,XIY
	jr Double_ToInt16__FCA952                  ; FCA960  jr T,0xfca952
Double_ToInt16__FCA962:
	ld	de, wa                                  ; FCA962  ld DE,WA
	inc	1, wa                                  ; FCA964  inc 1,WA
	cps	de, 0                                  ; FCA966  cp DE,0
	jr z, Double_ToInt16__FCA972               ; FCA968  jr Z,0xfca972
	sra	xiy, 1                                 ; FCA96A  sra 0x01,XIY
	rr	xix                                     ; FCA96D  rr 0x01,XIX
	jr Double_ToInt16__FCA962                  ; FCA970  jr T,0xfca962
Double_ToInt16__FCA972:
	ld	wa, qiy                                 ; FCA972  ld WA,QIY
	cp	wa, 0x8000                              ; FCA975  cp WA,0x8000
	jr c, Double_ToInt16__FCA989               ; FCA979  jr C,0xfca989
	cps	bc, 0                                  ; FCA97B  cp BC,0
	jr z, Double_ToInt16__FCA984               ; FCA97D  jr Z,0xfca984
Double_ToInt16__FCA97F:
	ldw	wa, 0x8000                             ; FCA97F  ld WA,0x8000
	jr Double_ToInt16__FCA98F                  ; FCA982  jr T,0xfca98f
Double_ToInt16__FCA984:
	ldw	wa, 0x7FFF                             ; FCA984  ld WA,0x7fff
	jr Double_ToInt16__FCA98F                  ; FCA987  jr T,0xfca98f
Double_ToInt16__FCA989:
	cps	bc, 0                                  ; FCA989  cp BC,0
	jr z, Double_ToInt16__FCA98F               ; FCA98B  jr Z,0xfca98f
	neg	wa                                     ; FCA98D  neg WA
Double_ToInt16__FCA98F:
	pop	xix                                    ; FCA98F  pop XIX
	popw	de                                    ; FCA990  pop DE
	popw	hl                                    ; FCA991  pop HL
	unlk32 xiz                                 ; FCA992  unlk XIZ
	retd	8                                     ; FCA994  retd 0x0008
; --------------------------------------------------------------------------
; Int16_ToDouble -- signed 16-bit integer to double.
; Called from: 14 `call` sites in prom_c -- e.g. 0xF9C388, 0xF9C4BA, 0xF9C4E7.  Counted, not
;              eyeballed: `python3 notes/prom_c_xrefs.py 0xFCA997 --no-window`,
;              whose hits are filtered to those whose preceding byte is the
;              `call` opcode 0x1D.  ⚠ THAT IS AN UPPER BOUND, NOT A DECODE:
;              nothing checks the 0x1D is itself at an instruction boundary,
;              so a literal that happens to follow a 0x1D operand byte would
;              be counted (round-2 audit F12; the same caveat applies to the
;              1,274 total in notes/prom_c_runtime_check.py).
; Inputs:  (XIZ+0x08) word; XIY = the result pointer.  `retd 0x0002`.
; Evidence: the wrapper shape again -- `cp DE,0 / jr GE / neg BC`, call
;          UInt16_ToDouble, then `xor (XIZ-2),0x8000`.
; --------------------------------------------------------------------------
Int16_ToDouble:
	link32 0xEE, 0x0C, 0xF8, 0xFF              ; FCA997  link XIZ,0xfff8
	pushw	de                                   ; FCA99B  push DE
	push	xix                                   ; FCA99C  push XIX
	push	xiy                                   ; FCA99D  push XIY
	ld	bc, (xiz+8)                             ; FCA99E  ld BC,(XIZ+0x08)
	ld	de, bc                                  ; FCA9A1  ld DE,BC
	cps	de, 0                                  ; FCA9A3  cp DE,0
	jr ge, Int16_ToDouble__FCA9A9              ; FCA9A5  jr GE,0xfca9a9
	neg	bc                                     ; FCA9A7  neg BC
Int16_ToDouble__FCA9A9:
	pushw	bc                                   ; FCA9A9  push BC
	lda	xiy, (xiz-8)                           ; FCA9AA  lda XIY,XIZ+0xf8
	call	0xFCA9CF                              ; FCA9AD  call 0xfca9cf
	cps	de, 0                                  ; FCA9B1  cp DE,0
	jr ge, Int16_ToDouble__FCA9BA              ; FCA9B3  jr GE,0xfca9ba
	extpfx5 0x9E, 0xFE, 0x3D, 0x00, 0x80       ; FCA9B5  xor (XIZ+0xfe),0x8000
Int16_ToDouble__FCA9BA:
	ld	xiy, (xsp)                              ; FCA9BA  ld XIY,(XSP)
	ld	xix, (xiz-8)                            ; FCA9BC  ld XIX,(XIZ+0xf8)
	stl_dpi	xix, 0xF6                          ; FCA9BF  ld (XIY+),XIX
	ld	xix, (xiz-4)                            ; FCA9C2  ld XIX,(XIZ+0xfc)
	ld	(xiy), xix                              ; FCA9C5  ld (XIY),XIX
	pop	xiy                                    ; FCA9C7  pop XIY
	pop	xix                                    ; FCA9C8  pop XIX
	popw	de                                    ; FCA9C9  pop DE
	unlk32 xiz                                 ; FCA9CA  unlk XIZ
	retd	2                                     ; FCA9CC  retd 0x0002
; --------------------------------------------------------------------------
; UInt16_ToDouble -- unsigned 16-bit integer to double.
; Called from: ONE site, `call` at 0xFCA9AD -- Int16_ToDouble, the signed wrapper
;              immediately above.  Census: `python3 notes/prom_c_xrefs.py
;              0xFCA9CF --no-window`.
; Inputs:  (XIZ+0x08) word; XIY = the result pointer.  `retd 0x0002`.
; Evidence: `ldw de,0x0403` = 1023 + 4, then the same normalise-and-decrement loop
;          as UInt32_ToDouble.  Zero short-circuits.
; --------------------------------------------------------------------------
UInt16_ToDouble:
	link32 0xEE, 0x0C, 0xF4, 0xFF              ; FCA9CF  link XIZ,0xfff4
	push	xde                                   ; FCA9D3  push XDE
	push	xix                                   ; FCA9D4  push XIX
	push	xiy                                   ; FCA9D5  push XIY
	sub	xix, xix                               ; FCA9D6  sub XIX,XIX
	sub	xiy, xiy                               ; FCA9D8  sub XIY,XIY
	ld	bc, (xiz+8)                             ; FCA9DA  ld BC,(XIZ+0x08)
	cps	bc, 0                                  ; FCA9DD  cp BC,0
	jr z, UInt16_ToDouble__FCAA20              ; FCA9DF  jr Z,0xfcaa20
	ld	qix, bc                                 ; FCA9E1  ld QIX,BC
	ldw	de, 0x403                              ; FCA9E4  ld DE,0x0403
UInt16_ToDouble__FCA9E7:
	ld	bc, qix                                 ; FCA9E7  ld BC,QIX
	and	bc, 0xFFE0                             ; FCA9EA  and BC,0xffe0
	cps	bc, 0                                  ; FCA9EE  cp BC,0
	jr z, UInt16_ToDouble__FCA9FC              ; FCA9F0  jr Z,0xfca9fc
	srl	xix, 1                                 ; FCA9F2  srl 0x01,XIX
	rr	xiy                                     ; FCA9F5  rr 0x01,XIY
	inc	1, de                                  ; FCA9F8  inc 1,DE
	jr UInt16_ToDouble__FCA9E7                 ; FCA9FA  jr T,0xfca9e7
UInt16_ToDouble__FCA9FC:
	ld	bc, qix                                 ; FCA9FC  ld BC,QIX
	and	bc, 0xFFF0                             ; FCA9FF  and BC,0xfff0
	cps	bc, 0                                  ; FCAA03  cp BC,0
	jr nz, UInt16_ToDouble__FCAA11             ; FCAA05  jr NZ,0xfcaa11
	sla	xiy, 1                                 ; FCAA07  sla 0x01,XIY
	rl	xix                                     ; FCAA0A  rl 0x01,XIX
	dec	1, de                                  ; FCAA0D  dec 1,DE
	jr UInt16_ToDouble__FCA9FC                 ; FCAA0F  jr T,0xfca9fc
UInt16_ToDouble__FCAA11:
	sll	de, 4                                  ; FCAA11  sll 0x04,DE
	ld	bc, qix                                 ; FCAA14  ld BC,QIX
	xor	bc, 16                                 ; FCAA17  xor BC,0x0010
	or	bc, de                                  ; FCAA1B  or BC,DE
	ld	qix, bc                                 ; FCAA1D  ld QIX,BC
UInt16_ToDouble__FCAA20:
	ld	xde, (xsp)                              ; FCAA20  ld XDE,(XSP)
	stl_dpi	xiy, 0xEA                          ; FCAA22  ld (XDE+),XIY
	ld	(xde), xix                              ; FCAA25  ld (XDE),XIX
	pop	xiy                                    ; FCAA27  pop XIY
	pop	xix                                    ; FCAA28  pop XIX
	pop	xde                                    ; FCAA29  pop XDE
	unlk32 xiz                                 ; FCAA2A  unlk XIZ
	retd	2                                     ; FCAA2C  retd 0x0002
; --------------------------------------------------------------------------
; Shift16_ArithRight -- 16-bit value >> count, sign-filling.
; Called from: 6 `call` sites in prom_c -- e.g. 0xF9A880, 0xF9ACBB, 0xFA75FA.  Counted, not
;              eyeballed: `python3 notes/prom_c_xrefs.py 0xFCAA2F --no-window`,
;              whose hits are filtered to those whose preceding byte is the
;              `call` opcode 0x1D.  ⚠ THAT IS AN UPPER BOUND, NOT A DECODE:
;              nothing checks the 0x1D is itself at an instruction boundary,
;              so a literal that happens to follow a 0x1D operand byte would
;              be counted (round-2 audit F12; the same caveat applies to the
;              1,274 total in notes/prom_c_runtime_check.py).
; Inputs:  (XSP+0x04) word, (XSP+0x06) byte.  Outputs: WA.  `retd 0x0004`.
; Evidence: byte for byte Shift16_Left with `sra A,IY` in place of `sll A,IY`.
; --------------------------------------------------------------------------
Shift16_ArithRight:
	ld	iy, (xsp+4)                             ; FCAA2F  ld IY,(XSP+0x04)
	ld	b, (xsp+6)                              ; FCAA32  ld B,(XSP+0x06)
	ld	w, b                                    ; FCAA35  ld W,B
	srl	w, 4                                   ; FCAA37  srl 0x04,W
	sub	a, a                                   ; FCAA3A  sub A,A
	cps	w, 0                                   ; FCAA3C  cp W,0
	jr z, Shift16_ArithRight__FCAA42           ; FCAA3E  jr Z,0xfcaa42
	extpfx2 0xDD, 0xFD                         ; FCAA40  sra A,IY
Shift16_ArithRight__FCAA42:
	ld	a, b                                    ; FCAA42  ld A,B
	and	a, 15                                  ; FCAA44  and A,0x0f
	jr z, Shift16_ArithRight__FCAA4B           ; FCAA47  jr Z,0xfcaa4b
	extpfx2 0xDD, 0xFD                         ; FCAA49  sra A,IY
Shift16_ArithRight__FCAA4B:
	ld	wa, iy                                  ; FCAA4B  ld WA,IY
	retd	4                                     ; FCAA4D  retd 0x0004
; --------------------------------------------------------------------------
; Float32_ToDouble -- widen a single to a double.
; Called from: 169 `call` sites in prom_c -- e.g. 0xF9AF21, 0xF9B1D0, 0xF9B38B.  Counted, not
;              eyeballed: `python3 notes/prom_c_xrefs.py 0xFCAA50 --no-window`,
;              whose hits are filtered to those whose preceding byte is the
;              `call` opcode 0x1D.  ⚠ THAT IS AN UPPER BOUND, NOT A DECODE:
;              nothing checks the 0x1D is itself at an instruction boundary,
;              so a literal that happens to follow a 0x1D operand byte would
;              be counted (round-2 audit F12; the same caveat applies to the
;              1,274 total in notes/prom_c_runtime_check.py).
; Inputs:  (XIZ+0x08) long, a float32; XIY = the result pointer.  `retd 0x0004`.
; Evidence: ★ it is the one routine that reads FLOAT32 masks and writes DOUBLE
;          masks.  It tests `and XIX,0x7F800000 / cp 0x7F800000` -- the single
;          precision exponent field, all ones, i.e. infinity or NaN -- and in that
;          case builds a double whose high halfword is 0x7FF0 or 0xFFF0 depending
;          on 0x80000000.  Both format constants appear, and nothing else in the
;          module mixes them except Double_ToFloat32, the other direction.
; --------------------------------------------------------------------------
Float32_ToDouble:
	link32 0xEE, 0x0C, 0xEA, 0xFF              ; FCAA50  link XIZ,0xffea
	pushw	hl                                   ; FCAA54  push HL
	push	xde                                   ; FCAA55  push XDE
	push	xix                                   ; FCAA56  push XIX
	push	xiy                                   ; FCAA57  push XIY
	ld	xix, (xiz+8)                            ; FCAA58  ld XIX,(XIZ+0x08)
	ld	xiy, xix                                ; FCAA5B  ld XIY,XIX
	and	xiy, 0x7F800000                        ; FCAA5D  and XIY,0x7f800000
	cp	xiy, 0x7F800000                         ; FCAA63  cp XIY,0x7f800000
	jr nz, Float32_ToDouble__FCAA94            ; FCAA69  jr NZ,0xfcaa94
	ld	xiy, xix                                ; FCAA6B  ld XIY,XIX
	and	xiy, 0x80000000                        ; FCAA6D  and XIY,0x80000000
	cp	xiy, 0                                  ; FCAA73  cp XIY,0x00000000
	ld	xix, 0                                  ; FCAA79  ld XIX,0x00000000
	ld	xiy, 0                                  ; FCAA7E  ld XIY,0x00000000
	jr z, Float32_ToDouble__FCAA8D             ; FCAA83  jr Z,0xfcaa8d
	ldw	qix, 0xFFF0                            ; FCAA85  ld QIX,0xfff0
	jrl Float32_ToDouble__FCAAF6               ; FCAA8A  jrl T,0xfcaaf6
Float32_ToDouble__FCAA8D:
	ldw	qix, 0x7FF0                            ; FCAA8D  ld QIX,0x7ff0
	jr Float32_ToDouble__FCAAF6                ; FCAA92  jr T,0xfcaaf6
Float32_ToDouble__FCAA94:
	sub	xiy, xiy                               ; FCAA94  sub XIY,XIY
	ld	bc, qix                                 ; FCAA96  ld BC,QIX
	and	bc, 0x8000                             ; FCAA99  and BC,0x8000
	ld	wa, qix                                 ; FCAA9D  ld WA,QIX
	and	wa, 0x7F80                             ; FCAAA0  and WA,0x7f80
	ld	hl, qix                                 ; FCAAA4  ld HL,QIX
	and	hl, 0x7FFF                             ; FCAAA7  and HL,0x7fff
	xor	hl, wa                                 ; FCAAAB  xor HL,WA
	ld	qix, hl                                 ; FCAAAD  ld QIX,HL
	cps	wa, 0                                  ; FCAAB0  cp WA,0
	jr z, Float32_ToDouble__FCAABF             ; FCAAB2  jr Z,0xfcaabf
	sra	wa, 7                                  ; FCAAB4  sra 0x07,WA
	add	wa, 0x380                              ; FCAAB7  add WA,0x0380
	cps	wa, 1                                  ; FCAABB  cp WA,1
	jr ge, Float32_ToDouble__FCAAC5            ; FCAABD  jr GE,0xfcaac5
Float32_ToDouble__FCAABF:
	sub	xiy, xiy                               ; FCAABF  sub XIY,XIY
	sub	xix, xix                               ; FCAAC1  sub XIX,XIX
	jr Float32_ToDouble__FCAAE9                ; FCAAC3  jr T,0xfcaae9
Float32_ToDouble__FCAAC5:
	ldw	de, 3                                  ; FCAAC5  ld DE,0x0003
Float32_ToDouble__FCAAC8:
	ld	hl, de                                  ; FCAAC8  ld HL,DE
	dec	1, de                                  ; FCAACA  dec 1,DE
	cps	hl, 0                                  ; FCAACC  cp HL,0
	jr z, Float32_ToDouble__FCAAD8             ; FCAACE  jr Z,0xfcaad8
	srl	xix, 1                                 ; FCAAD0  srl 0x01,XIX
	rr	xiy                                     ; FCAAD3  rr 0x01,XIY
	jr Float32_ToDouble__FCAAC8                ; FCAAD6  jr T,0xfcaac8
Float32_ToDouble__FCAAD8:
	cp	wa, 0x7FF                               ; FCAAD8  cp WA,0x07ff
	jr lt, Float32_ToDouble__FCAAEB            ; FCAADC  jr LT,0xfcaaeb
	sub	xiy, xiy                               ; FCAADE  sub XIY,XIY
	sub	xix, xix                               ; FCAAE0  sub XIX,XIX
	or	bc, 0x7FF0                              ; FCAAE2  or BC,0x7ff0
	ld	qix, bc                                 ; FCAAE6  ld QIX,BC
Float32_ToDouble__FCAAE9:
	jr Float32_ToDouble__FCAAF6                ; FCAAE9  jr T,0xfcaaf6
Float32_ToDouble__FCAAEB:
	sll	wa, 4                                  ; FCAAEB  sll 0x04,WA
	or	wa, qix                                 ; FCAAEE  or WA,QIX
	or	wa, bc                                  ; FCAAF1  or WA,BC
	ld	qix, wa                                 ; FCAAF3  ld QIX,WA
Float32_ToDouble__FCAAF6:
	ld	xde, (xsp)                              ; FCAAF6  ld XDE,(XSP)
	stl_dpi	xiy, 0xEA                          ; FCAAF8  ld (XDE+),XIY
	ld	(xde), xix                              ; FCAAFB  ld (XDE),XIX
	pop	xiy                                    ; FCAAFD  pop XIY
	pop	xix                                    ; FCAAFE  pop XIX
	pop	xde                                    ; FCAAFF  pop XDE
	popw	hl                                    ; FCAB00  pop HL
	unlk32 xiz                                 ; FCAB01  unlk XIZ
	retd	4                                     ; FCAB03  retd 0x0004
; --------------------------------------------------------------------------
; Shift32_ArithRight -- 32-bit value >> count, sign-filling.
; Called from: 19 `call` sites in prom_c -- e.g. 0xF9AF6C, 0xF9AF8D, 0xF9B068.  Counted, not
;              eyeballed: `python3 notes/prom_c_xrefs.py 0xFCAB06 --no-window`,
;              whose hits are filtered to those whose preceding byte is the
;              `call` opcode 0x1D.  ⚠ THAT IS AN UPPER BOUND, NOT A DECODE:
;              nothing checks the 0x1D is itself at an instruction boundary,
;              so a literal that happens to follow a 0x1D operand byte would
;              be counted (round-2 audit F12; the same caveat applies to the
;              1,274 total in notes/prom_c_runtime_check.py).
; Inputs:  (XSP+0x04) long, (XSP+0x08) byte.  Outputs: XIY.  `retd 0x0006`.
; Evidence: byte for byte Shift32_LogicalRight with `sra` for `srl`.
; --------------------------------------------------------------------------
Shift32_ArithRight:
	ld	xiy, (xsp+4)                            ; FCAB06  ld XIY,(XSP+0x04)
	ld	b, (xsp+8)                              ; FCAB09  ld B,(XSP+0x08)
	ld	w, b                                    ; FCAB0C  ld W,B
	srl	w, 4                                   ; FCAB0E  srl 0x04,W
	sub	a, a                                   ; FCAB11  sub A,A
Shift32_ArithRight__FCAB13:
	cps	w, 0                                   ; FCAB13  cp W,0
	jr z, Shift32_ArithRight__FCAB1D           ; FCAB15  jr Z,0xfcab1d
	extpfx2 0xED, 0xFD                         ; FCAB17  sra A,XIY
	dec	1, w                                   ; FCAB19  dec 1,W
	jr Shift32_ArithRight__FCAB13              ; FCAB1B  jr T,0xfcab13
Shift32_ArithRight__FCAB1D:
	ld	a, b                                    ; FCAB1D  ld A,B
	and	a, 15                                  ; FCAB1F  and A,0x0f
	jr z, Shift32_ArithRight__FCAB26           ; FCAB22  jr Z,0xfcab26
	extpfx2 0xED, 0xFD                         ; FCAB24  sra A,XIY
Shift32_ArithRight__FCAB26:
	retd	6                                     ; FCAB26  retd 0x0006
; --------------------------------------------------------------------------
; Float32_ToInt32 -- truncate a single to a 32-bit integer.
; Called from: 5 `call` sites in prom_c -- e.g. 0xF9B044, 0xF9B0DB, 0xF9B2F1.  Counted, not
;              eyeballed: `python3 notes/prom_c_xrefs.py 0xFCAB29 --no-window`,
;              whose hits are filtered to those whose preceding byte is the
;              `call` opcode 0x1D.  ⚠ THAT IS AN UPPER BOUND, NOT A DECODE:
;              nothing checks the 0x1D is itself at an instruction boundary,
;              so a literal that happens to follow a 0x1D operand byte would
;              be counted (round-2 audit F12; the same caveat applies to the
;              1,274 total in notes/prom_c_runtime_check.py).
; Inputs:  (XIZ+0x08) long, a float32.  Outputs: XIY.  `retd 0x0004`.
; Evidence: the float32 counterpart of Double_ToInt32: exponent field 0x7F80
;          extracted with `sra 0x07` (the single-precision field is seven bits up,
;          not four), hidden bit restored with 0x0080, and the shift computed
;          against **0x0096** = 150 = 127 + 23, which is the constant
;          UInt32_ToFloat32 starts from.  The sign is removed first (0x8000) and
;          re-applied to the 32-bit result (0x80000000).
; --------------------------------------------------------------------------
Float32_ToInt32:
	link32 0xEE, 0x0C, 0xEC, 0xFF              ; FCAB29  link XIZ,0xffec
	pushw	hl                                   ; FCAB2D  push HL
	pushw	de                                   ; FCAB2E  push DE
	push	xix                                   ; FCAB2F  push XIX
	ldw	hl, 7                                  ; FCAB30  ld HL,0x0007
	ld	xiy, (xiz+8)                            ; FCAB33  ld XIY,(XIZ+0x08)
	ld	bc, qiy                                 ; FCAB36  ld BC,QIY
	and	bc, 0x8000                             ; FCAB39  and BC,0x8000
	cps	bc, 0                                  ; FCAB3D  cp BC,0
	jr z, Float32_ToInt32__FCAB4C              ; FCAB3F  jr Z,0xfcab4c
	ldw	hl, 8                                  ; FCAB41  ld HL,0x0008
	ld	de, qiy                                 ; FCAB44  ld DE,QIY
	xor	de, bc                                 ; FCAB47  xor DE,BC
	ld	qiy, de                                 ; FCAB49  ld QIY,DE
Float32_ToInt32__FCAB4C:
	ld	de, qiy                                 ; FCAB4C  ld DE,QIY
	and	de, 0x7F80                             ; FCAB4F  and DE,0x7f80
	ld	wa, qiy                                 ; FCAB53  ld WA,QIY
	xor	wa, de                                 ; FCAB56  xor WA,DE
	or	wa, 0x80                                ; FCAB58  or WA,0x0080
	ld	qiy, wa                                 ; FCAB5C  ld QIY,WA
	sra	de, 7                                  ; FCAB5F  sra 0x07,DE
	cps	de, 0                                  ; FCAB62  cp DE,0
	jr nz, Float32_ToInt32__FCAB6B             ; FCAB64  jr NZ,0xfcab6b
	sub	xiy, xiy                               ; FCAB66  sub XIY,XIY
	jrl Float32_ToInt32__FCABBE                ; FCAB68  jrl T,0xfcabbe
Float32_ToInt32__FCAB6B:
	ld	wa, de                                  ; FCAB6B  ld WA,DE
	sub	wa, 0x96                               ; FCAB6D  sub WA,0x0096
	cps	wa, 0                                  ; FCAB71  cp WA,0
	jr lt, Float32_ToInt32__FCAB8C             ; FCAB73  jr LT,0xfcab8c
	cp	wa, hl                                  ; FCAB75  cp WA,HL
	jr le, Float32_ToInt32__FCAB7F             ; FCAB77  jr LE,0xfcab7f
	cps	bc, 0                                  ; FCAB79  cp BC,0
	jr z, Float32_ToInt32__FCABAC              ; FCAB7B  jr Z,0xfcabac
	jr Float32_ToInt32__FCABA5                 ; FCAB7D  jr T,0xfcaba5
Float32_ToInt32__FCAB7F:
	ld	ix, wa                                  ; FCAB7F  ld IX,WA
	dec	1, wa                                  ; FCAB81  dec 1,WA
	cps	ix, 0                                  ; FCAB83  cp IX,0
	jr z, Float32_ToInt32__FCAB99              ; FCAB85  jr Z,0xfcab99
	sla	xiy, 1                                 ; FCAB87  sla 0x01,XIY
	jr Float32_ToInt32__FCAB7F                 ; FCAB8A  jr T,0xfcab7f
Float32_ToInt32__FCAB8C:
	ld	ix, wa                                  ; FCAB8C  ld IX,WA
	inc	1, wa                                  ; FCAB8E  inc 1,WA
	cps	ix, 0                                  ; FCAB90  cp IX,0
	jr z, Float32_ToInt32__FCAB99              ; FCAB92  jr Z,0xfcab99
	srl	xiy, 1                                 ; FCAB94  srl 0x01,XIY
	jr Float32_ToInt32__FCAB8C                 ; FCAB97  jr T,0xfcab8c
Float32_ToInt32__FCAB99:
	cp	xiy, 0x80000000                         ; FCAB99  cp XIY,0x80000000
	jr c, Float32_ToInt32__FCABB3              ; FCAB9F  jr C,0xfcabb3
	cps	bc, 0                                  ; FCABA1  cp BC,0
	jr z, Float32_ToInt32__FCABAC              ; FCABA3  jr Z,0xfcabac
Float32_ToInt32__FCABA5:
	ld	xiy, 0x80000000                         ; FCABA5  ld XIY,0x80000000
	jr Float32_ToInt32__FCABBE                 ; FCABAA  jr T,0xfcabbe
Float32_ToInt32__FCABAC:
	ld	xiy, 0x7FFFFFFF                         ; FCABAC  ld XIY,0x7fffffff
	jr Float32_ToInt32__FCABBE                 ; FCABB1  jr T,0xfcabbe
Float32_ToInt32__FCABB3:
	cps	bc, 0                                  ; FCABB3  cp BC,0
	jr z, Float32_ToInt32__FCABBE              ; FCABB5  jr Z,0xfcabbe
	cpl	iy                                     ; FCABB7  cpl IY
	cpl	qiy                                    ; FCABB9  cpl QIY
	inc	1, xiy                                 ; FCABBC  inc 1,XIY
Float32_ToInt32__FCABBE:
	pop	xix                                    ; FCABBE  pop XIX
	popw	de                                    ; FCABBF  pop DE
	popw	hl                                    ; FCABC0  pop HL
	unlk32 xiz                                 ; FCABC1  unlk XIZ
	retd	4                                     ; FCABC3  retd 0x0004
; --------------------------------------------------------------------------
; Int32_ToFloat32 -- signed 32-bit integer to single.
; Called from: 83 `call` sites in prom_c -- e.g. 0xF9B4AE, 0xF9B5A6, 0xF9B66F.  Counted, not
;              eyeballed: `python3 notes/prom_c_xrefs.py 0xFCABC6 --no-window`,
;              whose hits are filtered to those whose preceding byte is the
;              `call` opcode 0x1D.  ⚠ THAT IS AN UPPER BOUND, NOT A DECODE:
;              nothing checks the 0x1D is itself at an instruction boundary,
;              so a literal that happens to follow a 0x1D operand byte would
;              be counted (round-2 audit F12; the same caveat applies to the
;              1,274 total in notes/prom_c_runtime_check.py).
; Inputs:  (XIZ+0x08) long.  Outputs: XIY.  `retd 0x0004`.
; Evidence: the wrapper shape -- test 0x80000000, `cpl IY / cpl QIY / inc 1,XIY`,
;          call UInt32_ToFloat32, then `or XIY,0x80000000` to set the sign.
; --------------------------------------------------------------------------
Int32_ToFloat32:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FCABC6  link XIZ,0xfffc
	push	xix                                   ; FCABCA  push XIX
	ld	xiy, (xiz+8)                            ; FCABCB  ld XIY,(XIZ+0x08)
	ld	xix, xiy                                ; FCABCE  ld XIX,XIY
	and	xix, 0x80000000                        ; FCABD0  and XIX,0x80000000
	cp	xix, 0                                  ; FCABD6  cp XIX,0x00000000
	jr z, Int32_ToFloat32__FCABE5              ; FCABDC  jr Z,0xfcabe5
	cpl	iy                                     ; FCABDE  cpl IY
	cpl	qiy                                    ; FCABE0  cpl QIY
	inc	1, xiy                                 ; FCABE3  inc 1,XIY
Int32_ToFloat32__FCABE5:
	push	xiy                                   ; FCABE5  push XIY
	call	0xFCAC00                              ; FCABE6  call 0xfcac00
	cp	xix, 0                                  ; FCABEA  cp XIX,0x00000000
	jr nz, Int32_ToFloat32__FCABF4             ; FCABF0  jr NZ,0xfcabf4
	jr Int32_ToFloat32__FCABFA                 ; FCABF2  jr T,0xfcabfa
Int32_ToFloat32__FCABF4:
	or	xiy, 0x80000000                         ; FCABF4  or XIY,0x80000000
Int32_ToFloat32__FCABFA:
	pop	xix                                    ; FCABFA  pop XIX
	unlk32 xiz                                 ; FCABFB  unlk XIZ
	retd	4                                     ; FCABFD  retd 0x0004
; --------------------------------------------------------------------------
; UInt32_ToFloat32 -- unsigned 32-bit integer to single.
; Called from: ONE site, `call` at 0xFCABE6 -- Int32_ToFloat32, the signed wrapper
;              immediately above.  Census: `python3 notes/prom_c_xrefs.py
;              0xFCAC00 --no-window`.
; Inputs:  (XIZ+0x08) long.  Outputs: XIY.  `retd 0x0004`.
; Evidence: `ldw de,0x0096` = 150 = 127 + 23, then a normalise loop that shifts
;          XIY right while incrementing DE until the top eight bits of the high
;          halfword (`and BC,0xFF00`) are clear -- 24 significant bits is exactly
;          single precision.  Zero short-circuits to zero.
; --------------------------------------------------------------------------
UInt32_ToFloat32:
	link32 0xEE, 0x0C, 0xF2, 0xFF              ; FCAC00  link XIZ,0xfff2
	pushw	de                                   ; FCAC04  push DE
	push	xix                                   ; FCAC05  push XIX
	ld	xiy, (xiz+8)                            ; FCAC06  ld XIY,(XIZ+0x08)
	cp	xiy, 0                                  ; FCAC09  cp XIY,0x00000000
	jr nz, UInt32_ToFloat32__FCAC15            ; FCAC0F  jr NZ,0xfcac15
	sub	xiy, xiy                               ; FCAC11  sub XIY,XIY
	jr UInt32_ToFloat32__FCAC4B                ; FCAC13  jr T,0xfcac4b
UInt32_ToFloat32__FCAC15:
	ldw	de, 0x96                               ; FCAC15  ld DE,0x0096
UInt32_ToFloat32__FCAC18:
	ld	bc, qiy                                 ; FCAC18  ld BC,QIY
	and	bc, 0xFF00                             ; FCAC1B  and BC,0xff00
	cps	bc, 0                                  ; FCAC1F  cp BC,0
	jr z, UInt32_ToFloat32__FCAC2A             ; FCAC21  jr Z,0xfcac2a
	srl	xiy, 1                                 ; FCAC23  srl 0x01,XIY
	inc	1, de                                  ; FCAC26  inc 1,DE
	jr UInt32_ToFloat32__FCAC18                ; FCAC28  jr T,0xfcac18
UInt32_ToFloat32__FCAC2A:
	ld	bc, qiy                                 ; FCAC2A  ld BC,QIY
	and	bc, 0xFF80                             ; FCAC2D  and BC,0xff80
	cps	bc, 0                                  ; FCAC31  cp BC,0
	jr nz, UInt32_ToFloat32__FCAC3C            ; FCAC33  jr NZ,0xfcac3c
	sla	xiy, 1                                 ; FCAC35  sla 0x01,XIY
	dec	1, de                                  ; FCAC38  dec 1,DE
	jr UInt32_ToFloat32__FCAC2A                ; FCAC3A  jr T,0xfcac2a
UInt32_ToFloat32__FCAC3C:
	sll	de, 7                                  ; FCAC3C  sll 0x07,DE
	ld	bc, qiy                                 ; FCAC3F  ld BC,QIY
	xor	bc, 0x80                               ; FCAC42  xor BC,0x0080
	or	bc, de                                  ; FCAC46  or BC,DE
	ld	qiy, bc                                 ; FCAC48  ld QIY,BC
UInt32_ToFloat32__FCAC4B:
	pop	xix                                    ; FCAC4B  pop XIX
	popw	de                                    ; FCAC4C  pop DE
	unlk32 xiz                                 ; FCAC4D  unlk XIZ
	retd	4                                     ; FCAC4F  retd 0x0004
; --------------------------------------------------------------------------
; Float32_Add -- a + b, both singles.
; Called from: 19 `call` sites in prom_c -- e.g. 0xF9B4B9, 0xF9BEC5, 0xFCB041.  Counted, not
;              eyeballed: `python3 notes/prom_c_xrefs.py 0xFCAC52 --no-window`,
;              whose hits are filtered to those whose preceding byte is the
;              `call` opcode 0x1D.  ⚠ THAT IS AN UPPER BOUND, NOT A DECODE:
;              nothing checks the 0x1D is itself at an instruction boundary,
;              so a literal that happens to follow a 0x1D operand byte would
;              be counted (round-2 audit F12; the same caveat applies to the
;              1,274 total in notes/prom_c_runtime_check.py).
; Inputs:  two float32s, (XIZ+0x08) and (XIZ+0x0C).  Outputs: XIY.
;          `retd 0x0008`.
; Evidence: ★ named by its caller, exactly as Double_Add is: Float32_Subtract
;          (0xFCB02B) flips the second operand's sign halfword with `xor 0x8000`
;          and calls this, and does nothing else at all.
;          Internally it aligns the operands before adding -- `sub WA,DE` on the
;          two exponents and then `cp WA,0x0019`, and 25 is the single-precision
;          significand width plus one, the point past which the smaller operand
;          cannot affect the sum.
; --------------------------------------------------------------------------
Float32_Add:
	link32 0xEE, 0x0C, 0xD6, 0xFF              ; FCAC52  link XIZ,0xffd6
	push	xhl                                   ; FCAC56  push XHL
	push	xde                                   ; FCAC57  push XDE
	push	xix                                   ; FCAC58  push XIX
	ld	xiy, (xiz+8)                            ; FCAC59  ld XIY,(XIZ+0x08)
	ld	xix, (xiz+12)                           ; FCAC5C  ld XIX,(XIZ+0x0c)
	ld	bc, qiy                                 ; FCAC5F  ld BC,QIY
	and	bc, 0x8000                             ; FCAC62  and BC,0x8000
	ld	wa, qiy                                 ; FCAC66  ld WA,QIY
	and	wa, 0x7FFF                             ; FCAC69  and WA,0x7fff
	ld	qiy, wa                                 ; FCAC6D  ld QIY,WA
	ld	de, qix                                 ; FCAC70  ld DE,QIX
	and	de, 0x8000                             ; FCAC73  and DE,0x8000
	ld	wa, qix                                 ; FCAC77  ld WA,QIX
	and	wa, 0x7FFF                             ; FCAC7A  and WA,0x7fff
	ld	qix, wa                                 ; FCAC7E  ld QIX,WA
	ld	hl, qiy                                 ; FCAC81  ld HL,QIY
	and	hl, 0x7FF0                             ; FCAC84  and HL,0x7ff0
	cps	hl, 0                                  ; FCAC88  cp HL,0
	jr nz, Float32_Add__FCAC98                 ; FCAC8A  jr NZ,0xfcac98
	ld	hl, qix                                 ; FCAC8C  ld HL,QIX
	and	hl, 0x7FF0                             ; FCAC8F  and HL,0x7ff0
	cps	hl, 0                                  ; FCAC93  cp HL,0
	jrl z, Float32_Add__FCAD81                 ; FCAC95  jrl Z,0xfcad81
Float32_Add__FCAC98:
	ld	hl, qiy                                 ; FCAC98  ld HL,QIY
	cp	hl, qix                                 ; FCAC9B  cp HL,QIX
	jr c, Float32_Add__FCACA8                  ; FCAC9E  jr C,0xfcaca8
	jr ugt, Float32_Add__FCACB0                ; FCACA0  jr UGT,0xfcacb0
	cp	iy, ix                                  ; FCACA2  cp IY,IX
	jr c, Float32_Add__FCACA8                  ; FCACA4  jr C,0xfcaca8
	jr Float32_Add__FCACB0                     ; FCACA6  jr T,0xfcacb0
Float32_Add__FCACA8:
	ld	xhl, xiy                                ; FCACA8  ld XHL,XIY
	ld	xiy, xix                                ; FCACAA  ld XIY,XIX
	ld	xix, xhl                                ; FCACAC  ld XIX,XHL
	ex16	bc, de                                ; FCACAE  ex BC,DE
Float32_Add__FCACB0:
	xor	de, bc                                 ; FCACB0  xor DE,BC
	cps	de, 0                                  ; FCACB2  cp DE,0
	jr z, Float32_Add__FCACBA                  ; FCACB4  jr Z,0xfcacba
	ldb	c, 45                                  ; FCACB6  ld C,0x2d
	jr Float32_Add__FCACBC                     ; FCACB8  jr T,0xfcacbc
Float32_Add__FCACBA:
	ldb	c, 43                                  ; FCACBA  ld C,0x2b
Float32_Add__FCACBC:
	ld	hl, qiy                                 ; FCACBC  ld HL,QIY
	and	hl, 0x7F80                             ; FCACBF  and HL,0x7f80
	ld	de, qiy                                 ; FCACC3  ld DE,QIY
	xor	de, hl                                 ; FCACC6  xor DE,HL
	or	de, 0x80                                ; FCACC8  or DE,0x0080
	ld	qiy, de                                 ; FCACCC  ld QIY,DE
	srl	hl, 7                                  ; FCACCF  srl 0x07,HL
	ld	de, qix                                 ; FCACD2  ld DE,QIX
	and	de, 0x7F80                             ; FCACD5  and DE,0x7f80
	ld	wa, qix                                 ; FCACD9  ld WA,QIX
	xor	wa, de                                 ; FCACDC  xor WA,DE
	or	wa, 0x80                                ; FCACDE  or WA,0x0080
	ld	qix, wa                                 ; FCACE2  ld QIX,WA
	srl	de, 7                                  ; FCACE5  srl 0x07,DE
	sla	xiy, 2                                 ; FCACE8  sla 0x02,XIY
	sla	xix, 2                                 ; FCACEB  sla 0x02,XIX
	ld	wa, hl                                  ; FCACEE  ld WA,HL
	sub	wa, de                                 ; FCACF0  sub WA,DE
	cp	wa, 25                                  ; FCACF2  cp WA,0x0019
	jrl ugt, Float32_Add__FCAD98               ; FCACF6  jrl UGT,0xfcad98
	cps	de, 0                                  ; FCACF9  cp DE,0
	jrl z, Float32_Add__FCAD98                 ; FCACFB  jrl Z,0xfcad98
Float32_Add__FCACFE:
	ld	de, wa                                  ; FCACFE  ld DE,WA
	dec	1, wa                                  ; FCAD00  dec 1,WA
	cps	de, 0                                  ; FCAD02  cp DE,0
	jr z, Float32_Add__FCAD0B                  ; FCAD04  jr Z,0xfcad0b
	srl	xix, 1                                 ; FCAD06  srl 0x01,XIX
	jr Float32_Add__FCACFE                     ; FCAD09  jr T,0xfcacfe
Float32_Add__FCAD0B:
	cp	c, 43                                   ; FCAD0B  cp C,0x2b
	jr nz, Float32_Add__FCAD62                 ; FCAD0E  jr NZ,0xfcad62
	add	xiy, xix                               ; FCAD10  add XIY,XIX
	ld	de, qiy                                 ; FCAD12  ld DE,QIY
	and	de, 0xFC00                             ; FCAD15  and DE,0xfc00
	cps	de, 0                                  ; FCAD19  cp DE,0
	jr z, Float32_Add__FCAD30                  ; FCAD1B  jr Z,0xfcad30
	srl	xiy, 1                                 ; FCAD1D  srl 0x01,XIY
	inc	1, hl                                  ; FCAD20  inc 1,HL
	cp	hl, 0xFF                                ; FCAD22  cp HL,0x00ff
	jr c, Float32_Add__FCAD30                  ; FCAD26  jr C,0xfcad30
	ldb	c, 0                                   ; FCAD28  ld C,0x00
	cps	bc, 0                                  ; FCAD2A  cp BC,0
	jr z, Float32_Add__FCAD5A                  ; FCAD2C  jr Z,0xfcad5a
	jr Float32_Add__FCAD52                     ; FCAD2E  jr T,0xfcad52
Float32_Add__FCAD30:
	add	xiy, 1                                 ; FCAD30  add XIY,0x00000001
	ld	de, qiy                                 ; FCAD36  ld DE,QIY
	and	de, 0xFC00                             ; FCAD39  and DE,0xfc00
	cps	de, 0                                  ; FCAD3D  cp DE,0
	jr z, Float32_Add__FCAD98                  ; FCAD3F  jr Z,0xfcad98
	srl	xiy, 1                                 ; FCAD41  srl 0x01,XIY
	inc	1, hl                                  ; FCAD44  inc 1,HL
	cp	hl, 0xFF                                ; FCAD46  cp HL,0x00ff
	jr c, Float32_Add__FCAD98                  ; FCAD4A  jr C,0xfcad98
	ldb	c, 0                                   ; FCAD4C  ld C,0x00
	cps	bc, 0                                  ; FCAD4E  cp BC,0
	jr z, Float32_Add__FCAD5A                  ; FCAD50  jr Z,0xfcad5a
Float32_Add__FCAD52:
	ld	xiy, 0xFF800000                         ; FCAD52  ld XIY,0xff800000
	jrl Float32_Add__FCADCE                    ; FCAD57  jrl T,0xfcadce
Float32_Add__FCAD5A:
	ld	xiy, 0x7F800000                         ; FCAD5A  ld XIY,0x7f800000
	jrl Float32_Add__FCADCE                    ; FCAD5F  jrl T,0xfcadce
Float32_Add__FCAD62:
	sub	xiy, xix                               ; FCAD62  sub XIY,XIX
	cp	qiy, 0                                  ; FCAD64  cp QIY,0
	jr nz, Float32_Add__FCAD6D                 ; FCAD67  jr NZ,0xfcad6d
	cps	iy, 0                                  ; FCAD69  cp IY,0
	jr z, Float32_Add__FCAD81                  ; FCAD6B  jr Z,0xfcad81
Float32_Add__FCAD6D:
	ld	de, qiy                                 ; FCAD6D  ld DE,QIY
	and	de, 0xFE00                             ; FCAD70  and DE,0xfe00
	cps	de, 0                                  ; FCAD74  cp DE,0
	jr nz, Float32_Add__FCAD92                 ; FCAD76  jr NZ,0xfcad92
Float32_Add__FCAD78:
	sla	xiy, 1                                 ; FCAD78  sla 0x01,XIY
	dec	1, hl                                  ; FCAD7B  dec 1,HL
	cps	hl, 1                                  ; FCAD7D  cp HL,1
	jr nc, Float32_Add__FCAD85                 ; FCAD7F  jr NC,0xfcad85
Float32_Add__FCAD81:
	sub	xiy, xiy                               ; FCAD81  sub XIY,XIY
	jr Float32_Add__FCADCE                     ; FCAD83  jr T,0xfcadce
Float32_Add__FCAD85:
	ld	de, qiy                                 ; FCAD85  ld DE,QIY
	and	de, 0xFE00                             ; FCAD88  and DE,0xfe00
	cps	de, 0                                  ; FCAD8C  cp DE,0
	jr nz, Float32_Add__FCAD98                 ; FCAD8E  jr NZ,0xfcad98
	jr Float32_Add__FCAD78                     ; FCAD90  jr T,0xfcad78
Float32_Add__FCAD92:
	add	xiy, 1                                 ; FCAD92  add XIY,0x00000001
Float32_Add__FCAD98:
	srl	xiy, 2                                 ; FCAD98  srl 0x02,XIY
	sll	hl, 7                                  ; FCAD9B  sll 0x07,HL
	ld	de, qiy                                 ; FCAD9E  ld DE,QIY
	xor	de, 0x80                               ; FCADA1  xor DE,0x0080
	or	de, hl                                  ; FCADA5  or DE,HL
	ld	qiy, de                                 ; FCADA7  ld QIY,DE
	ldb	c, 0                                   ; FCADAA  ld C,0x00
	cps	bc, 0                                  ; FCADAC  cp BC,0
	jr z, Float32_Add__FCADCE                  ; FCADAE  jr Z,0xfcadce
	ld	de, qiy                                 ; FCADB0  ld DE,QIY
	and	de, 0x7F80                             ; FCADB3  and DE,0x7f80
	cps	de, 0                                  ; FCADB7  cp DE,0
	jr z, Float32_Add__FCADCE                  ; FCADB9  jr Z,0xfcadce
	cps	iy, 0                                  ; FCADBB  cp IY,0
	jr nz, Float32_Add__FCADC4                 ; FCADBD  jr NZ,0xfcadc4
	cp	qiy, 0                                  ; FCADBF  cp QIY,0
	jr z, Float32_Add__FCADCE                  ; FCADC2  jr Z,0xfcadce
Float32_Add__FCADC4:
	ld	de, qiy                                 ; FCADC4  ld DE,QIY
	xor	de, 0x8000                             ; FCADC7  xor DE,0x8000
	ld	qiy, de                                 ; FCADCB  ld QIY,DE
Float32_Add__FCADCE:
	pop	xix                                    ; FCADCE  pop XIX
	pop	xde                                    ; FCADCF  pop XDE
	pop	xhl                                    ; FCADD0  pop XHL
	unlk32 xiz                                 ; FCADD1  unlk XIZ
	retd	8                                     ; FCADD3  retd 0x0008
; --------------------------------------------------------------------------
; Double_ToFloat32 -- narrow a double to a single.
; Called from: 164 `call` sites in prom_c -- e.g. 0xF9B644, 0xF9B70D, 0xF9B726.  Counted, not
;              eyeballed: `python3 notes/prom_c_xrefs.py 0xFCADD6 --no-window`,
;              whose hits are filtered to those whose preceding byte is the
;              `call` opcode 0x1D.  ⚠ THAT IS AN UPPER BOUND, NOT A DECODE:
;              nothing checks the 0x1D is itself at an instruction boundary,
;              so a literal that happens to follow a 0x1D operand byte would
;              be counted (round-2 audit F12; the same caveat applies to the
;              1,274 total in notes/prom_c_runtime_check.py).
; Inputs:  one double at (XIZ+0x08).  Outputs: XIY, a float32.  `retd 0x0008`.
; Evidence: ★ the bias difference is the proof: it extracts the DOUBLE exponent
;          with 0x7FF0 and then does `sub WA,0x0380`.  0x380 = 896 = 1023 - 127,
;          the difference between the two biases, and it appears nowhere else in
;          the module.  The overflow guard that follows is `cp WA,0x00FF`, the
;          reserved SINGLE exponent, and the infinity it builds is `or BC,0x7F80`.
;          So it reads one format's fields and writes the other's.
; --------------------------------------------------------------------------
Double_ToFloat32:
	link32 0xEE, 0x0C, 0xF2, 0xFF              ; FCADD6  link XIZ,0xfff2
	pushw	hl                                   ; FCADDA  push HL
	pushw	de                                   ; FCADDB  push DE
	push	xix                                   ; FCADDC  push XIX
	ld	de, (xiz+14)                            ; FCADDD  ld DE,(XIZ+0x0e)
	ld	bc, de                                  ; FCADE0  ld BC,DE
	and	bc, 0x8000                             ; FCADE2  and BC,0x8000
	ld	wa, de                                  ; FCADE6  ld WA,DE
	and	wa, 0x7FF0                             ; FCADE8  and WA,0x7ff0
	and	de, 0x7FFF                             ; FCADEC  and DE,0x7fff
	xor	de, wa                                 ; FCADF0  xor DE,WA
	cps	wa, 0                                  ; FCADF2  cp WA,0
	jr z, Double_ToFloat32__FCAE01             ; FCADF4  jr Z,0xfcae01
	sra	wa, 4                                  ; FCADF6  sra 0x04,WA
	sub	wa, 0x380                              ; FCADF9  sub WA,0x0380
	cps	wa, 1                                  ; FCADFD  cp WA,1
	jr ge, Double_ToFloat32__FCAE05            ; FCADFF  jr GE,0xfcae05
Double_ToFloat32__FCAE01:
	sub	xiy, xiy                               ; FCAE01  sub XIY,XIY
	jr Double_ToFloat32__FCAE58                ; FCAE03  jr T,0xfcae58
Double_ToFloat32__FCAE05:
	ld	qiy, de                                 ; FCAE05  ld QIY,DE
	ld	iy, (xiz+12)                            ; FCAE08  ld IY,(XIZ+0x0c)
	ld	xix, (xiz+8)                            ; FCAE0B  ld XIX,(XIZ+0x08)
	ldw	de, 0xFFFD                             ; FCAE0E  ld DE,0xfffd
Double_ToFloat32__FCAE11:
	ld	hl, de                                  ; FCAE11  ld HL,DE
	inc	1, de                                  ; FCAE13  inc 1,DE
	cps	hl, 0                                  ; FCAE15  cp HL,0
	jr z, Double_ToFloat32__FCAE21             ; FCAE17  jr Z,0xfcae21
	sla	xix, 1                                 ; FCAE19  sla 0x01,XIX
	rl	xiy                                     ; FCAE1C  rl 0x01,XIY
	jr Double_ToFloat32__FCAE11                ; FCAE1F  jr T,0xfcae11
Double_ToFloat32__FCAE21:
	add	xix, 0x80000000                        ; FCAE21  add XIX,0x80000000
	adc	xiy, 0                                 ; FCAE27  adc XIY,0x00000000
	ld	hl, qiy                                 ; FCAE2D  ld HL,QIY
	and	hl, 0x7F80                             ; FCAE30  and HL,0x7f80
	cps	hl, 0                                  ; FCAE34  cp HL,0
	jr z, Double_ToFloat32__FCAE3C             ; FCAE36  jr Z,0xfcae3c
	sub	xiy, xiy                               ; FCAE38  sub XIY,XIY
	inc	1, wa                                  ; FCAE3A  inc 1,WA
Double_ToFloat32__FCAE3C:
	cp	wa, 0xFF                                ; FCAE3C  cp WA,0x00ff
	jr lt, Double_ToFloat32__FCAE4D            ; FCAE40  jr LT,0xfcae4d
	sub	xiy, xiy                               ; FCAE42  sub XIY,XIY
	or	bc, 0x7F80                              ; FCAE44  or BC,0x7f80
	ld	qiy, bc                                 ; FCAE48  ld QIY,BC
	jr Double_ToFloat32__FCAE58                ; FCAE4B  jr T,0xfcae58
Double_ToFloat32__FCAE4D:
	sll	wa, 7                                  ; FCAE4D  sll 0x07,WA
	or	wa, qiy                                 ; FCAE50  or WA,QIY
	or	wa, bc                                  ; FCAE53  or WA,BC
	ld	qiy, wa                                 ; FCAE55  ld QIY,WA
Double_ToFloat32__FCAE58:
	pop	xix                                    ; FCAE58  pop XIX
	popw	de                                    ; FCAE59  pop DE
	popw	hl                                    ; FCAE5A  pop HL
	unlk32 xiz                                 ; FCAE5B  unlk XIZ
	retd	8                                     ; FCAE5D  retd 0x0008
; --------------------------------------------------------------------------
; Float32_Divide -- a / b, both singles.  ★ Also the machine's float MULTIPLY.
; Called from: 40 `call` sites in prom_c -- e.g. 0xF9BDEF, 0xFCB019, 0xFCB022.  Counted, not
;              eyeballed: `python3 notes/prom_c_xrefs.py 0xFCAE60 --no-window`,
;              whose hits are filtered to those whose preceding byte is the
;              `call` opcode 0x1D.  ⚠ THAT IS AN UPPER BOUND, NOT A DECODE:
;              nothing checks the 0x1D is itself at an instruction boundary,
;              so a literal that happens to follow a 0x1D operand byte would
;              be counted (round-2 audit F12; the same caveat applies to the
;              1,274 total in notes/prom_c_runtime_check.py).
; Inputs:  (XIZ+0x08) = a, (XIZ+0x0C) = b.  Outputs: XIY.  `retd 0x0008`.
; Evidence: XOR of the two signs, magnitudes masked with 0x7FFF, exponents taken
;          with 0x7F80 and `sra 0x07`, hidden bits restored with 0x0080, and then
;          `sub WA,BC` followed by `add WA,0x0097`.  Subtracting exponents is
;          division; 0x97 = 151 = 127 + 24 is the single bias plus the significand
;          width, the scaling a restoring divider needs.
;          ★ WHICH OPERAND IS THE NUMERATOR is settled here and matters, because
;          Float32_Multiply's identification depends on it: XIX is loaded from
;          (XIZ+0x08) and XHL from (XIZ+0x0C); WA takes XIX's exponent and BC
;          takes XHL's; `sub WA,BC` is therefore exp(first) - exp(second), so the
;          FIRST slot is the numerator.
; --------------------------------------------------------------------------
Float32_Divide:
	link32 0xEE, 0x0C, 0xCA, 0xFF              ; FCAE60  link XIZ,0xffca
	push	xhl                                   ; FCAE64  push XHL
	pushw	de                                   ; FCAE65  push DE
	push	xix                                   ; FCAE66  push XIX
	ld	xix, (xiz+8)                            ; FCAE67  ld XIX,(XIZ+0x08)
	ld	xhl, (xiz+12)                           ; FCAE6A  ld XHL,(XIZ+0x0c)
	ld	bc, qix                                 ; FCAE6D  ld BC,QIX
	xor	bc, qhl                                ; FCAE70  xor BC,QHL
	and	bc, 0x8000                             ; FCAE73  and BC,0x8000
	ld	qbc, bc                                 ; FCAE77  ld QBC,BC
	ld	wa, qix                                 ; FCAE7A  ld WA,QIX
	and	wa, 0x7FFF                             ; FCAE7D  and WA,0x7fff
	ld	qix, wa                                 ; FCAE81  ld QIX,WA
	ld	wa, qhl                                 ; FCAE84  ld WA,QHL
	and	wa, 0x7FFF                             ; FCAE87  and WA,0x7fff
	ld	qhl, wa                                 ; FCAE8B  ld QHL,WA
	ldw	de, 3                                  ; FCAE8E  ld DE,0x0003
	ld	wa, qix                                 ; FCAE91  ld WA,QIX
	and	wa, 0x7F80                             ; FCAE94  and WA,0x7f80
	ld	bc, qix                                 ; FCAE98  ld BC,QIX
	xor	bc, wa                                 ; FCAE9B  xor BC,WA
	or	bc, 0x80                                ; FCAE9D  or BC,0x0080
	ld	qix, bc                                 ; FCAEA1  ld QIX,BC
	sra	wa, 7                                  ; FCAEA4  sra 0x07,WA
	cps	wa, 0                                  ; FCAEA7  cp WA,0
	jrl z, Float32_Divide__FCAF34              ; FCAEA9  jrl Z,0xfcaf34
	cp	wa, 0xFF                                ; FCAEAC  cp WA,0x00ff
	jr ge, Float32_Divide__FCAED3              ; FCAEB0  jr GE,0xfcaed3
	ld	bc, qhl                                 ; FCAEB2  ld BC,QHL
	and	bc, 0x7F80                             ; FCAEB5  and BC,0x7f80
	ld	iy, qhl                                 ; FCAEB9  ld IY,QHL
	xor	iy, bc                                 ; FCAEBC  xor IY,BC
	or	iy, 0x80                                ; FCAEBE  or IY,0x0080
	ld	qhl, iy                                 ; FCAEC2  ld QHL,IY
	sra	bc, 7                                  ; FCAEC5  sra 0x07,BC
	cp	bc, 0xFF                                ; FCAEC8  cp BC,0x00ff
	jrl ge, Float32_Divide__FCAF34             ; FCAECC  jrl GE,0xfcaf34
	cps	bc, 0                                  ; FCAECF  cp BC,0
	jr nz, Float32_Divide__FCAEDC              ; FCAED1  jr NZ,0xfcaedc
Float32_Divide__FCAED3:
	cp	qbc, 0                                  ; FCAED3  cp QBC,0
	jrl z, Float32_Divide__FCAF4A              ; FCAED6  jrl Z,0xfcaf4a
	jrl Float32_Divide__FCAF43                 ; FCAED9  jrl T,0xfcaf43
Float32_Divide__FCAEDC:
	sub	wa, bc                                 ; FCAEDC  sub WA,BC
	add	wa, 0x97                               ; FCAEDE  add WA,0x0097
	sub	xiy, xiy                               ; FCAEE2  sub XIY,XIY
Float32_Divide__FCAEE4:
	sla	xiy, 1                                 ; FCAEE4  sla 0x01,XIY
	ld	bc, qix                                 ; FCAEE7  ld BC,QIX
	cp	bc, qhl                                 ; FCAEEA  cp BC,QHL
	jr ugt, Float32_Divide__FCAEF5             ; FCAEED  jr UGT,0xfcaef5
	jr c, Float32_Divide__FCAEFD               ; FCAEEF  jr C,0xfcaefd
	cp	ix, hl                                  ; FCAEF1  cp IX,HL
	jr c, Float32_Divide__FCAEFD               ; FCAEF3  jr C,0xfcaefd
Float32_Divide__FCAEF5:
	add	xiy, 1                                 ; FCAEF5  add XIY,0x00000001
	sub	xix, xhl                               ; FCAEFB  sub XIX,XHL
Float32_Divide__FCAEFD:
	sla	xix, 1                                 ; FCAEFD  sla 0x01,XIX
	dec	1, wa                                  ; FCAF00  dec 1,WA
	ld	bc, qiy                                 ; FCAF02  ld BC,QIY
	and	bc, 0x400                              ; FCAF05  and BC,0x0400
	cps	bc, 0                                  ; FCAF09  cp BC,0
	jr z, Float32_Divide__FCAEE4               ; FCAF0B  jr Z,0xfcaee4
	add	xiy, 1                                 ; FCAF0D  add XIY,0x00000001
	ld	bc, qiy                                 ; FCAF13  ld BC,QIY
	and	bc, 0x400                              ; FCAF16  and BC,0x0400
	cps	bc, 0                                  ; FCAF1A  cp BC,0
	jr nz, Float32_Divide__FCAF21              ; FCAF1C  jr NZ,0xfcaf21
	ldw	de, 4                                  ; FCAF1E  ld DE,0x0004
Float32_Divide__FCAF21:
	add	wa, de                                 ; FCAF21  add WA,DE
Float32_Divide__FCAF23:
	ld	bc, de                                  ; FCAF23  ld BC,DE
	dec	1, de                                  ; FCAF25  dec 1,DE
	cps	bc, 0                                  ; FCAF27  cp BC,0
	jr z, Float32_Divide__FCAF30               ; FCAF29  jr Z,0xfcaf30
	srl	xiy, 1                                 ; FCAF2B  srl 0x01,XIY
	jr Float32_Divide__FCAF23                  ; FCAF2E  jr T,0xfcaf23
Float32_Divide__FCAF30:
	cps	wa, 1                                  ; FCAF30  cp WA,1
	jr ge, Float32_Divide__FCAF38              ; FCAF32  jr GE,0xfcaf38
Float32_Divide__FCAF34:
	sub	xiy, xiy                               ; FCAF34  sub XIY,XIY
	jr Float32_Divide__FCAF83                  ; FCAF36  jr T,0xfcaf83
Float32_Divide__FCAF38:
	cp	wa, 0xFF                                ; FCAF38  cp WA,0x00ff
	jr lt, Float32_Divide__FCAF51              ; FCAF3C  jr LT,0xfcaf51
	cp	qbc, 0                                  ; FCAF3E  cp QBC,0
	jr z, Float32_Divide__FCAF4A               ; FCAF41  jr Z,0xfcaf4a
Float32_Divide__FCAF43:
	ld	xiy, 0xFF800000                         ; FCAF43  ld XIY,0xff800000
	jr Float32_Divide__FCAF83                  ; FCAF48  jr T,0xfcaf83
Float32_Divide__FCAF4A:
	ld	xiy, 0x7F800000                         ; FCAF4A  ld XIY,0x7f800000
	jr Float32_Divide__FCAF83                  ; FCAF4F  jr T,0xfcaf83
Float32_Divide__FCAF51:
	sll	wa, 7                                  ; FCAF51  sll 0x07,WA
	ld	bc, qiy                                 ; FCAF54  ld BC,QIY
	xor	bc, 0x80                               ; FCAF57  xor BC,0x0080
	or	bc, wa                                  ; FCAF5B  or BC,WA
	ld	qiy, bc                                 ; FCAF5D  ld QIY,BC
	cp	qbc, 0                                  ; FCAF60  cp QBC,0
	jr z, Float32_Divide__FCAF83               ; FCAF63  jr Z,0xfcaf83
	ld	bc, qiy                                 ; FCAF65  ld BC,QIY
	and	bc, 0x7F80                             ; FCAF68  and BC,0x7f80
	cps	bc, 0                                  ; FCAF6C  cp BC,0
	jr z, Float32_Divide__FCAF83               ; FCAF6E  jr Z,0xfcaf83
	cps	iy, 0                                  ; FCAF70  cp IY,0
	jr nz, Float32_Divide__FCAF79              ; FCAF72  jr NZ,0xfcaf79
	cp	qiy, 0                                  ; FCAF74  cp QIY,0
	jr z, Float32_Divide__FCAF83               ; FCAF77  jr Z,0xfcaf83
Float32_Divide__FCAF79:
	ld	bc, qiy                                 ; FCAF79  ld BC,QIY
	xor	bc, 0x8000                             ; FCAF7C  xor BC,0x8000
	ld	qiy, bc                                 ; FCAF80  ld QIY,BC
Float32_Divide__FCAF83:
	pop	xix                                    ; FCAF83  pop XIX
	popw	de                                    ; FCAF84  pop DE
	pop	xhl                                    ; FCAF85  pop XHL
	unlk32 xiz                                 ; FCAF86  unlk XIZ
	retd	8                                     ; FCAF88  retd 0x0008
; --------------------------------------------------------------------------
; Int16_ToFloat32 -- signed 16-bit integer to single.
; Called from: 61 `call` sites in prom_c -- e.g. 0xF9BEBF, 0xF9BF25, 0xF9BF37.  Counted, not
;              eyeballed: `python3 notes/prom_c_xrefs.py 0xFCAF8B --no-window`,
;              whose hits are filtered to those whose preceding byte is the
;              `call` opcode 0x1D.  ⚠ THAT IS AN UPPER BOUND, NOT A DECODE:
;              nothing checks the 0x1D is itself at an instruction boundary,
;              so a literal that happens to follow a 0x1D operand byte would
;              be counted (round-2 audit F12; the same caveat applies to the
;              1,274 total in notes/prom_c_runtime_check.py).
; Inputs:  (XIZ+0x08) word.  Outputs: XIY.  `retd 0x0002`.
; Evidence: the wrapper shape, calling UInt16_ToFloat32 and setting 0x80000000.
; --------------------------------------------------------------------------
Int16_ToFloat32:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FCAF8B  link XIZ,0x0000
	pushw	de                                   ; FCAF8F  push DE
	push	xix                                   ; FCAF90  push XIX
	ld	bc, (xiz+8)                             ; FCAF91  ld BC,(XIZ+0x08)
	ld	de, bc                                  ; FCAF94  ld DE,BC
	cps	de, 0                                  ; FCAF96  cp DE,0
	jr ge, Int16_ToFloat32__FCAF9C             ; FCAF98  jr GE,0xfcaf9c
	neg	bc                                     ; FCAF9A  neg BC
Int16_ToFloat32__FCAF9C:
	pushw	bc                                   ; FCAF9C  push BC
	call	0xFCAFB4                              ; FCAF9D  call 0xfcafb4
	cps	de, 0                                  ; FCAFA1  cp DE,0
	jr lt, Int16_ToFloat32__FCAFA7             ; FCAFA3  jr LT,0xfcafa7
	jr Int16_ToFloat32__FCAFAD                 ; FCAFA5  jr T,0xfcafad
Int16_ToFloat32__FCAFA7:
	or	xiy, 0x80000000                         ; FCAFA7  or XIY,0x80000000
Int16_ToFloat32__FCAFAD:
	pop	xix                                    ; FCAFAD  pop XIX
	popw	de                                    ; FCAFAE  pop DE
	unlk32 xiz                                 ; FCAFAF  unlk XIZ
	retd	2                                     ; FCAFB1  retd 0x0002
; --------------------------------------------------------------------------
; UInt16_ToFloat32 -- unsigned 16-bit integer to single.
; Called from: ONE site, `call` at 0xFCAF9D -- Int16_ToFloat32, the signed wrapper
;              immediately above.  Census: `python3 notes/prom_c_xrefs.py
;              0xFCAFB4 --no-window`.
; Inputs:  (XIZ+0x08) word.  Outputs: XIY.  `retd 0x0002`.
; Evidence: the same normalise loop as UInt32_ToFloat32, restoring the single
;          precision hidden bit with 0x0080.
; --------------------------------------------------------------------------
UInt16_ToFloat32:
	link32 0xEE, 0x0C, 0xF2, 0xFF              ; FCAFB4  link XIZ,0xfff2
	pushw	de                                   ; FCAFB8  push DE
	push	xix                                   ; FCAFB9  push XIX
	sub	xiy, xiy                               ; FCAFBA  sub XIY,XIY
	ld	bc, (xiz+8)                             ; FCAFBC  ld BC,(XIZ+0x08)
	cps	bc, 0                                  ; FCAFBF  cp BC,0
	jr nz, UInt16_ToFloat32__FCAFC5            ; FCAFC1  jr NZ,0xfcafc5
	jr UInt16_ToFloat32__FCAFFE                ; FCAFC3  jr T,0xfcaffe
UInt16_ToFloat32__FCAFC5:
	ld	qiy, bc                                 ; FCAFC5  ld QIY,BC
	ldw	de, 0x86                               ; FCAFC8  ld DE,0x0086
UInt16_ToFloat32__FCAFCB:
	ld	bc, qiy                                 ; FCAFCB  ld BC,QIY
	and	bc, 0xFF00                             ; FCAFCE  and BC,0xff00
	cps	bc, 0                                  ; FCAFD2  cp BC,0
	jr z, UInt16_ToFloat32__FCAFDD             ; FCAFD4  jr Z,0xfcafdd
	srl	xiy, 1                                 ; FCAFD6  srl 0x01,XIY
	inc	1, de                                  ; FCAFD9  inc 1,DE
	jr UInt16_ToFloat32__FCAFCB                ; FCAFDB  jr T,0xfcafcb
UInt16_ToFloat32__FCAFDD:
	ld	bc, qiy                                 ; FCAFDD  ld BC,QIY
	and	bc, 0xFF80                             ; FCAFE0  and BC,0xff80
	cps	bc, 0                                  ; FCAFE4  cp BC,0
	jr nz, UInt16_ToFloat32__FCAFEF            ; FCAFE6  jr NZ,0xfcafef
	sla	xiy, 1                                 ; FCAFE8  sla 0x01,XIY
	dec	1, de                                  ; FCAFEB  dec 1,DE
	jr UInt16_ToFloat32__FCAFDD                ; FCAFED  jr T,0xfcafdd
UInt16_ToFloat32__FCAFEF:
	sll	de, 7                                  ; FCAFEF  sll 0x07,DE
	ld	bc, qiy                                 ; FCAFF2  ld BC,QIY
	xor	bc, 0x80                               ; FCAFF5  xor BC,0x0080
	or	bc, de                                  ; FCAFF9  or BC,DE
	ld	qiy, bc                                 ; FCAFFB  ld QIY,BC
UInt16_ToFloat32__FCAFFE:
	pop	xix                                    ; FCAFFE  pop XIX
	popw	de                                    ; FCAFFF  pop DE
	unlk32 xiz                                 ; FCB000  unlk XIZ
	retd	2                                     ; FCB002  retd 0x0002
; --------------------------------------------------------------------------
; Float32_Multiply -- a * b, computed as a / (1 / b).
; Called from: 38 `call` sites in prom_c -- e.g. 0xF9BF2B, 0xF9BFA3, 0xF9C073.  Counted, not
;              eyeballed: `python3 notes/prom_c_xrefs.py 0xFCB005 --no-window`,
;              whose hits are filtered to those whose preceding byte is the
;              `call` opcode 0x1D.  ⚠ THAT IS AN UPPER BOUND, NOT A DECODE:
;              nothing checks the 0x1D is itself at an instruction boundary,
;              so a literal that happens to follow a 0x1D operand byte would
;              be counted (round-2 audit F12; the same caveat applies to the
;              1,274 total in notes/prom_c_runtime_check.py).
; Inputs:  (XIZ+0x08) = a, (XIZ+0x0C) = b.  Outputs: XIY.  `retd 0x0008`.
; Evidence: ★ THE ROUTINE CONTAINS NO ARITHMETIC.  All eleven of its instructions
;          are loads, pushes and two `call`s to Float32_Divide:
;            1. load the float32 at 0xFCB4E6 -- the four bytes 00 00 80 3F, which
;               is IEEE-754 single 1.0 -- and divide it by b;
;            2. divide a by that.
;          Float32_Divide's first slot is its numerator (see its header), so this
;          is a / (1/b) = a*b.  It is also the ONLY float32 operation left
;          unassigned once every other routine in the module is accounted for.
; ⚠ THIS IS A REAL NUMERICAL DEFECT, not a curiosity: two divisions means two
;          roundings where a real multiply has one, and the reciprocal of any b
;          that is not a power of two is inexact.  Anyone re-implementing or
;          emulating this firmware with a native float multiply will get
;          different bits.
; Unknown:  why.  A missing multiply in the runtime is the obvious reading and
;          nothing here proves it.
; --------------------------------------------------------------------------
Float32_Multiply:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FCB005  link XIZ,0xfffc
	ld	xbc, (0xFCB4E6:24)                     ; FCB009  ld XBC,(0xfcb4e6)
	ld	(xiz-4), xbc                            ; FCB00E  ld (XIZ+0xfc),XBC
	ld	xbc, (xiz+12)                           ; FCB011  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FCB014  push XBC
	ld	xwa, (xiz-4)                            ; FCB015  ld XWA,(XIZ+0xfc)
	push	xwa                                   ; FCB018  push XWA
	call	0xFCAE60                              ; FCB019  call 0xfcae60
	push	xiy                                   ; FCB01D  push XIY
	ld	xbc, (xiz+8)                            ; FCB01E  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FCB021  push XBC
	call	0xFCAE60                              ; FCB022  call 0xfcae60
	unlk32 xiz                                 ; FCB026  unlk XIZ
	retd	8                                     ; FCB028  retd 0x0008
; --------------------------------------------------------------------------
; Float32_Subtract -- a - b, as a + (-b).
; Called from: 27 `call` sites in prom_c -- e.g. 0xF9C2BE, 0xF9C577, 0xF9C67D.  Counted, not
;              eyeballed: `python3 notes/prom_c_xrefs.py 0xFCB02B --no-window`,
;              whose hits are filtered to those whose preceding byte is the
;              `call` opcode 0x1D.  ⚠ THAT IS AN UPPER BOUND, NOT A DECODE:
;              nothing checks the 0x1D is itself at an instruction boundary,
;              so a literal that happens to follow a 0x1D operand byte would
;              be counted (round-2 audit F12; the same caveat applies to the
;              1,274 total in notes/prom_c_runtime_check.py).
; Inputs:  (XIZ+0x08) = a, (XIZ+0x0C) = b.  Outputs: XIY.  `retd 0x0008`.
; Evidence: `ld WA,QIY / xor WA,0x8000 / ld QIY,WA` on the SECOND operand, then
;          `call Float32_Add` with both pushed unchanged.  Nine instructions.
; --------------------------------------------------------------------------
Float32_Subtract:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FCB02B  link XIZ,0x0000
	ld	xiy, (xiz+12)                           ; FCB02F  ld XIY,(XIZ+0x0c)
	ld	wa, qiy                                 ; FCB032  ld WA,QIY
	xor	wa, 0x8000                             ; FCB035  xor WA,0x8000
	ld	qiy, wa                                 ; FCB039  ld QIY,WA
	push	xiy                                   ; FCB03C  push XIY
	ld	xiy, (xiz+8)                            ; FCB03D  ld XIY,(XIZ+0x08)
	push	xiy                                   ; FCB040  push XIY
	call	0xFCAC52                              ; FCB041  call 0xfcac52
	unlk32 xiz                                 ; FCB045  unlk XIZ
	retd	8                                     ; FCB047  retd 0x0008
; --------------------------------------------------------------------------
; Float32_Negate -- flip a single's sign, except for zero.
; Called from: 14 `call` sites in prom_c -- e.g. 0xF9D25F, 0xF9D537, 0xF9E448.  Counted, not
;              eyeballed: `python3 notes/prom_c_xrefs.py 0xFCB04A --no-window`,
;              whose hits are filtered to those whose preceding byte is the
;              `call` opcode 0x1D.  ⚠ THAT IS AN UPPER BOUND, NOT A DECODE:
;              nothing checks the 0x1D is itself at an instruction boundary,
;              so a literal that happens to follow a 0x1D operand byte would
;              be counted (round-2 audit F12; the same caveat applies to the
;              1,274 total in notes/prom_c_runtime_check.py).
; Inputs:  (XIZ+0x08) long.  Outputs: XIY.  `retd 0x0004`.
; Evidence: calls Float32_Classify and flips the sign halfword with `xor 0x8000`
;          only when it returns non-zero -- the same construction, instruction for
;          instruction, as Double_Negate over Double_Classify.
; --------------------------------------------------------------------------
Float32_Negate:
	link32 0xEE, 0x0C, 0xF8, 0xFF              ; FCB04A  link XIZ,0xfff8
	push	xix                                   ; FCB04E  push XIX
	lda	xix, (xiz-4)                           ; FCB04F  lda XIX,XIZ+0xfc
	ld	xbc, (xiz+8)                            ; FCB052  ld XBC,(XIZ+0x08)
	ld	(xiz-8), xbc                            ; FCB055  ld (XIZ+0xf8),XBC
	ld	(xix), xbc                              ; FCB058  ld (XIX),XBC
	ld	xbc, (xiz-8)                            ; FCB05A  ld XBC,(XIZ+0xf8)
	push	xbc                                   ; FCB05D  push XBC
	call	0xFCB075                              ; FCB05E  call 0xfcb075
	cps	wa, 0                                  ; FCB062  cp WA,0
	jr z, Float32_Negate__FCB06B               ; FCB064  jr Z,0xfcb06b
	extpfx5 0x9C, 0x02, 0x3D, 0x00, 0x80       ; FCB066  xor (XIX+0x02),0x8000
Float32_Negate__FCB06B:
	ld	xbc, (xix)                              ; FCB06B  ld XBC,(XIX)
	ld	xiy, xbc                                ; FCB06D  ld XIY,XBC
	pop	xix                                    ; FCB06F  pop XIX
	unlk32 xiz                                 ; FCB070  unlk XIZ
	retd	4                                     ; FCB072  retd 0x0004
; --------------------------------------------------------------------------
; Float32_Classify -- is this single zero, and if not, what sign?
; Called from: ONE site, `call` at 0xFCB05E -- Float32_Negate, the signed wrapper
;              immediately above.  Census: `python3 notes/prom_c_xrefs.py
;              0xFCB075 --no-window`.
; Inputs:  (XIZ+0x08) long.  Outputs: WA = 0, 1 or 2.  `retd 0x0004`.
; Evidence: `and DE,0x7F80 / cp DE,0` then `and DE,0x8000 / cp DE,0` -- the
;          float32 twin of Double_Classify, with 0x7F80 where that one has 0x7FF0.
; --------------------------------------------------------------------------
Float32_Classify:
	link32 0xEE, 0x0C, 0xF2, 0xFF              ; FCB075  link XIZ,0xfff2
	pushw	de                                   ; FCB079  push DE
	push	xix                                   ; FCB07A  push XIX
	sub	wa, wa                                 ; FCB07B  sub WA,WA
	ld	xix, (xiz+8)                            ; FCB07D  ld XIX,(XIZ+0x08)
	ld	de, qix                                 ; FCB080  ld DE,QIX
	and	de, 0x7F80                             ; FCB083  and DE,0x7f80
	cps	de, 0                                  ; FCB087  cp DE,0
	jr z, Float32_Classify__FCB0CA             ; FCB089  jr Z,0xfcb0ca
	ld	de, qix                                 ; FCB08B  ld DE,QIX
	and	de, 0x8000                             ; FCB08E  and DE,0x8000
	cps	de, 0                                  ; FCB092  cp DE,0
	jr z, Float32_Classify__FCB0A5             ; FCB094  jr Z,0xfcb0a5
	cp	qix, 0                                  ; FCB096  cp QIX,0
	jr nc, Float32_Classify__FCB0A0            ; FCB099  jr NC,0xfcb0a0
	ldw	wa, 1                                  ; FCB09B  ld WA,0x0001
	jr Float32_Classify__FCB0CC                ; FCB09E  jr T,0xfcb0cc
Float32_Classify__FCB0A0:
	ldw	wa, 2                                  ; FCB0A0  ld WA,0x0002
	jr Float32_Classify__FCB0CC                ; FCB0A3  jr T,0xfcb0cc
Float32_Classify__FCB0A5:
	jr z, Float32_Classify__FCB0AC             ; FCB0A5  jr Z,0xfcb0ac
	ldw	wa, 3                                  ; FCB0A7  ld WA,0x0003
	jr Float32_Classify__FCB0AF                ; FCB0AA  jr T,0xfcb0af
Float32_Classify__FCB0AC:
	ldw	wa, 0                                  ; FCB0AC  ld WA,0x0000
Float32_Classify__FCB0AF:
	cp	qix, 0                                  ; FCB0AF  cp QIX,0
	jr ugt, Float32_Classify__FCB0BE           ; FCB0B2  jr UGT,0xfcb0be
	jr c, Float32_Classify__FCB0C4             ; FCB0B4  jr C,0xfcb0c4
	cps	ix, 0                                  ; FCB0B6  cp IX,0
	jr ugt, Float32_Classify__FCB0BE           ; FCB0B8  jr UGT,0xfcb0be
	jr c, Float32_Classify__FCB0C4             ; FCB0BA  jr C,0xfcb0c4
	jr Float32_Classify__FCB0CA                ; FCB0BC  jr T,0xfcb0ca
Float32_Classify__FCB0BE:
	xor	wa, 1                                  ; FCB0BE  xor WA,0x0001
	jr Float32_Classify__FCB0CC                ; FCB0C2  jr T,0xfcb0cc
Float32_Classify__FCB0C4:
	xor	wa, 2                                  ; FCB0C4  xor WA,0x0002
	jr Float32_Classify__FCB0CC                ; FCB0C8  jr T,0xfcb0cc
Float32_Classify__FCB0CA:
	sub	wa, wa                                 ; FCB0CA  sub WA,WA
Float32_Classify__FCB0CC:
	pop	xix                                    ; FCB0CC  pop XIX
	popw	de                                    ; FCB0CD  pop DE
	unlk32 xiz                                 ; FCB0CE  unlk XIZ
	retd	4                                     ; FCB0D0  retd 0x0004
; --------------------------------------------------------------------------
; Multiply32_Signed -- signed 32 x 32 multiply, low 32 bits.
; Called from: 8 `call` sites in prom_c -- e.g. 0xF9DC31, 0xFA2986, 0xFA2991.  Counted, not
;              eyeballed: `python3 notes/prom_c_xrefs.py 0xFCB0D3 --no-window`,
;              whose hits are filtered to those whose preceding byte is the
;              `call` opcode 0x1D.  ⚠ THAT IS AN UPPER BOUND, NOT A DECODE:
;              nothing checks the 0x1D is itself at an instruction boundary,
;              so a literal that happens to follow a 0x1D operand byte would
;              be counted (round-2 audit F12; the same caveat applies to the
;              1,274 total in notes/prom_c_runtime_check.py).
; Inputs:  (XIZ+0x08), (XIZ+0x0C) longs.  Outputs: XIY.  `retd 0x0008`.
; Evidence: the wrapper shape, with the sign accumulated in D: `ldcf 0x0f,QIY`
;          tests bit 15 of the HIGH halfword -- i.e. bit 31 -- of each operand,
;          each negative operand is negated in place, D records whether an odd
;          number of them were, and after `call Multiply32` the result is negated
;          if D is odd.
; Unknown:  ⚠ for the LOW 32 bits of a product the sign handling is redundant --
;          the low half of a two's-complement product does not depend on how the
;          operands are signed.  Recorded as observed; nothing here explains it.
; --------------------------------------------------------------------------
Multiply32_Signed:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FCB0D3  link XIZ,0x0000
	push	d                                     ; FCB0D7  push D
	push	xix                                   ; FCB0D9  push XIX
	ldb	d, 0                                   ; FCB0DA  ld D,0x00
	ld	xiy, (xiz+8)                            ; FCB0DC  ld XIY,(XIZ+0x08)
	ldcf	15, qiy                               ; FCB0DF  ldcf 0x0f,QIY
	jr nc, Multiply32_Signed__FCB0EE           ; FCB0E3  jr NC,0xfcb0ee
	cpl	iy                                     ; FCB0E5  cpl IY
	cpl	qiy                                    ; FCB0E7  cpl QIY
	inc	1, xiy                                 ; FCB0EA  inc 1,XIY
	ldb	d, 1                                   ; FCB0EC  ld D,0x01
Multiply32_Signed__FCB0EE:
	ld	xix, (xiz+12)                           ; FCB0EE  ld XIX,(XIZ+0x0c)
	ldcf	15, qix                               ; FCB0F1  ldcf 0x0f,QIX
	jr nc, Multiply32_Signed__FCB101           ; FCB0F5  jr NC,0xfcb101
	cpl	ix                                     ; FCB0F7  cpl IX
	cpl	qix                                    ; FCB0F9  cpl QIX
	inc	1, xix                                 ; FCB0FC  inc 1,XIX
	xor	d, 1                                   ; FCB0FE  xor D,0x01
Multiply32_Signed__FCB101:
	push	xix                                   ; FCB101  push XIX
	push	xiy                                   ; FCB102  push XIY
	call	0xFCB11B                              ; FCB103  call 0xfcb11b
	extpfx3 0xCC, 0x23, 0x00                   ; FCB107  ldcf 0x00,D
	jr nc, Multiply32_Signed__FCB113           ; FCB10A  jr NC,0xfcb113
	cpl	iy                                     ; FCB10C  cpl IY
	cpl	qiy                                    ; FCB10E  cpl QIY
	inc	1, xiy                                 ; FCB111  inc 1,XIY
Multiply32_Signed__FCB113:
	pop	xix                                    ; FCB113  pop XIX
	pop	d                                      ; FCB114  pop D
	unlk32 xiz                                 ; FCB116  unlk XIZ
	retd	8                                     ; FCB118  retd 0x0008
; --------------------------------------------------------------------------
; Multiply32 -- 32 x 32 multiply, low 32 bits, out of three 16 x 16 products.
; Called from: 28 `call` sites in prom_c -- e.g. 0xFA7946, 0xFA7952, 0xFCB103.  Counted, not
;              eyeballed: `python3 notes/prom_c_xrefs.py 0xFCB11B --no-window`,
;              whose hits are filtered to those whose preceding byte is the
;              `call` opcode 0x1D.  ⚠ THAT IS AN UPPER BOUND, NOT A DECODE:
;              nothing checks the 0x1D is itself at an instruction boundary,
;              so a literal that happens to follow a 0x1D operand byte would
;              be counted (round-2 audit F12; the same caveat applies to the
;              1,274 total in notes/prom_c_runtime_check.py).
; Inputs:  (XIZ+0x08), (XIZ+0x0C) longs.  Outputs: XIY.  `retd 0x0008`.
; Evidence: `mul XIY,IX` on the two low halves, then `mul XIX,(XIZ+0x0a)` and
;          `mul XIX,(XIZ+0x0e)` -- low x high and high x low -- each shifted left
;          16 with `sll A,XIX` (A = 0x10, loaded once) and added.  The high x high
;          product is not computed at all, which is exactly right for a result
;          truncated to 32 bits.
; --------------------------------------------------------------------------
Multiply32:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FCB11B  link XIZ,0x0000
	push	xix                                   ; FCB11F  push XIX
	ldb	a, 16                                  ; FCB120  ld A,0x10
	ld	iy, (xiz+8)                             ; FCB122  ld IY,(XIZ+0x08)
	ld	ix, (xiz+12)                            ; FCB125  ld IX,(XIZ+0x0c)
	mul	xiy, xix                               ; FCB128  mul XIY,IX
	extpfx3 0x9E, 0x0A, 0x44                   ; FCB12A  mul XIX,(XIZ+0x0a)
	extpfx2 0xEC, 0xFE                         ; FCB12D  sll A,XIX
	add	xiy, xix                               ; FCB12F  add XIY,XIX
	ld	ix, (xiz+8)                             ; FCB131  ld IX,(XIZ+0x08)
	extpfx3 0x9E, 0x0E, 0x44                   ; FCB134  mul XIX,(XIZ+0x0e)
	extpfx2 0xEC, 0xFE                         ; FCB137  sll A,XIX
	add	xiy, xix                               ; FCB139  add XIY,XIX
	pop	xix                                    ; FCB13B  pop XIX
	unlk32 xiz                                 ; FCB13C  unlk XIZ
	retd	8                                     ; FCB13E  retd 0x0008
; --------------------------------------------------------------------------
; Divide32_Signed -- signed 32 / 32 divide.
; Called from: 6 `call` sites in prom_c -- e.g. 0xF9DC3C, 0xFA299C, 0xFA29ED.  Counted, not
;              eyeballed: `python3 notes/prom_c_xrefs.py 0xFCB141 --no-window`,
;              whose hits are filtered to those whose preceding byte is the
;              `call` opcode 0x1D.  ⚠ THAT IS AN UPPER BOUND, NOT A DECODE:
;              nothing checks the 0x1D is itself at an instruction boundary,
;              so a literal that happens to follow a 0x1D operand byte would
;              be counted (round-2 audit F12; the same caveat applies to the
;              1,274 total in notes/prom_c_runtime_check.py).
; Inputs:  (XIZ+0x08) = dividend, (XIZ+0x0C) = divisor.  Outputs: XIY.
;          `retd 0x0008`.
; Evidence: byte for byte the same wrapper as Multiply32_Signed -- same `ldcf
;          0x0f` sign tests, same D parity, same negate-on-exit -- calling
;          Divide32 instead.  Here the sign handling is NOT redundant.
; --------------------------------------------------------------------------
Divide32_Signed:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FCB141  link XIZ,0x0000
	push	d                                     ; FCB145  push D
	push	xix                                   ; FCB147  push XIX
	ldb	d, 0                                   ; FCB148  ld D,0x00
	ld	xiy, (xiz+8)                            ; FCB14A  ld XIY,(XIZ+0x08)
	ldcf	15, qiy                               ; FCB14D  ldcf 0x0f,QIY
	jr nc, Divide32_Signed__FCB15C             ; FCB151  jr NC,0xfcb15c
	cpl	iy                                     ; FCB153  cpl IY
	cpl	qiy                                    ; FCB155  cpl QIY
	inc	1, xiy                                 ; FCB158  inc 1,XIY
	ldb	d, 1                                   ; FCB15A  ld D,0x01
Divide32_Signed__FCB15C:
	ld	xix, (xiz+12)                           ; FCB15C  ld XIX,(XIZ+0x0c)
	ldcf	15, qix                               ; FCB15F  ldcf 0x0f,QIX
	jr nc, Divide32_Signed__FCB16F             ; FCB163  jr NC,0xfcb16f
	cpl	ix                                     ; FCB165  cpl IX
	cpl	qix                                    ; FCB167  cpl QIX
	inc	1, xix                                 ; FCB16A  inc 1,XIX
	xor	d, 1                                   ; FCB16C  xor D,0x01
Divide32_Signed__FCB16F:
	push	xix                                   ; FCB16F  push XIX
	push	xiy                                   ; FCB170  push XIY
	call	0xFCB189                              ; FCB171  call 0xfcb189
	extpfx3 0xCC, 0x23, 0x00                   ; FCB175  ldcf 0x00,D
	jr nc, Divide32_Signed__FCB181             ; FCB178  jr NC,0xfcb181
	cpl	iy                                     ; FCB17A  cpl IY
	cpl	qiy                                    ; FCB17C  cpl QIY
	inc	1, xiy                                 ; FCB17F  inc 1,XIY
Divide32_Signed__FCB181:
	pop	xix                                    ; FCB181  pop XIX
	pop	d                                      ; FCB182  pop D
	unlk32 xiz                                 ; FCB184  unlk XIZ
	retd	8                                     ; FCB186  retd 0x0008
; --------------------------------------------------------------------------
; Divide32 -- unsigned 32 / 32 restoring divide.
; Called from: ONE site, `call` at 0xFCB171 -- Divide32_Signed, the signed wrapper
;              immediately above.  Census: `python3 notes/prom_c_xrefs.py
;              0xFCB189 --no-window`.
; Inputs:  (XIZ+0x08) = dividend, (XIZ+0x0C) = divisor.  Outputs: XIY.
;          `retd 0x0008`.
; Evidence: `ldb b,0x20` -- THIRTY-TWO iterations -- around a shift-compare-subtract
;          loop: the dividend is shifted left a bit at a time with `sllw` and
;          `stcf`, the remainder in XIX is compared with the divisor
;          (`cp XIX,(XIZ+0x0c)`) and the quotient bit shifted into XIY.  A 32-step
;          restoring division and nothing else.
; --------------------------------------------------------------------------
Divide32:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FCB189  link XIZ,0x0000
	push	xix                                   ; FCB18D  push XIX
	ldb	b, 32                                  ; FCB18E  ld B,0x20
	sub	wa, wa                                 ; FCB190  sub WA,WA
	sub	xiy, xiy                               ; FCB192  sub XIY,XIY
	sub	xix, xix                               ; FCB194  sub XIX,XIX
Divide32__FCB196:
	sll	xix, 1                                 ; FCB196  sll 0x01,XIX
	extpfx3 0x9E, 0x08, 0x7E                   ; FCB199  sllw (XIZ+0x08)
	extpfx3 0xD8, 0x24, 0x00                   ; FCB19C  stcf 0x00,WA
	extpfx3 0x9E, 0x0A, 0x7E                   ; FCB19F  sllw (XIZ+0x0a)
	extpfx3 0xDC, 0x24, 0x00                   ; FCB1A2  stcf 0x00,IX
	add	(xiz+10), wa                           ; FCB1A5  add (XIZ+0x0a),WA
	sll	xiy, 1                                 ; FCB1A8  sll 0x01,XIY
	extpfx3 0xAE, 0x0C, 0xF4                   ; FCB1AB  cp XIX,(XIZ+0x0c)
	jr c, Divide32__FCB1B5                     ; FCB1AE  jr C,0xfcb1b5
	extpfx3 0xAE, 0x0C, 0xA4                   ; FCB1B0  sub XIX,(XIZ+0x0c)
	inc	1, xiy                                 ; FCB1B3  inc 1,XIY
Divide32__FCB1B5:
	dec	1, b                                   ; FCB1B5  dec 1,B
	jr nz, Divide32__FCB196                    ; FCB1B7  jr NZ,0xfcb196
	pop	xix                                    ; FCB1B9  pop XIX
	unlk32 xiz                                 ; FCB1BA  unlk XIZ
	retd	8                                     ; FCB1BC  retd 0x0008
; --------------------------------------------------------------------------
; Float32_Compare -- order two singles.
; Called from: 2 `call` sites in prom_c -- e.g. 0xF9E432, 0xF9E541.  Counted, not
;              eyeballed: `python3 notes/prom_c_xrefs.py 0xFCB1BF --no-window`,
;              whose hits are filtered to those whose preceding byte is the
;              `call` opcode 0x1D.  ⚠ THAT IS AN UPPER BOUND, NOT A DECODE:
;              nothing checks the 0x1D is itself at an instruction boundary,
;              so a literal that happens to follow a 0x1D operand byte would
;              be counted (round-2 audit F12; the same caveat applies to the
;              1,274 total in notes/prom_c_runtime_check.py).
; Inputs:  (XIZ+0x08), (XIZ+0x0C) float32s.  Outputs: WA, a small code.
;          `retd 0x0008`.
; Evidence: the float32 twin of Double_Compare: both exponent fields masked with
;          0x7F80 and tested for zero, then the signs (0x8000), then the
;          magnitudes.  It writes nothing.
; Unknown:  the meaning of each returned code, as for Double_Compare.
; --------------------------------------------------------------------------
Float32_Compare:
	link32 0xEE, 0x0C, 0xE4, 0xFF              ; FCB1BF  link XIZ,0xffe4
	pushw	de                                   ; FCB1C3  push DE
	push	xix                                   ; FCB1C4  push XIX
	sub	wa, wa                                 ; FCB1C5  sub WA,WA
	ld	xix, (xiz+8)                            ; FCB1C7  ld XIX,(XIZ+0x08)
	ld	xiy, (xiz+12)                           ; FCB1CA  ld XIY,(XIZ+0x0c)
	ld	de, qix                                 ; FCB1CD  ld DE,QIX
	and	de, 0x7F80                             ; FCB1D0  and DE,0x7f80
	cps	de, 0                                  ; FCB1D4  cp DE,0
	jr nz, Float32_Compare__FCB1E3             ; FCB1D6  jr NZ,0xfcb1e3
	ld	de, qiy                                 ; FCB1D8  ld DE,QIY
	and	de, 0x7F80                             ; FCB1DB  and DE,0x7f80
	cps	de, 0                                  ; FCB1DF  cp DE,0
	jr z, Float32_Compare__FCB233              ; FCB1E1  jr Z,0xfcb233
Float32_Compare__FCB1E3:
	ld	de, qix                                 ; FCB1E3  ld DE,QIX
	xor	de, qiy                                ; FCB1E6  xor DE,QIY
	and	de, 0x8000                             ; FCB1E9  and DE,0x8000
	cps	de, 0                                  ; FCB1ED  cp DE,0
	jr z, Float32_Compare__FCB203              ; FCB1EF  jr Z,0xfcb203
	ld	de, qix                                 ; FCB1F1  ld DE,QIX
	cp	de, qiy                                 ; FCB1F4  cp DE,QIY
	jr nc, Float32_Compare__FCB1FE             ; FCB1F7  jr NC,0xfcb1fe
	ldw	wa, 1                                  ; FCB1F9  ld WA,0x0001
	jr Float32_Compare__FCB235                 ; FCB1FC  jr T,0xfcb235
Float32_Compare__FCB1FE:
	ldw	wa, 2                                  ; FCB1FE  ld WA,0x0002
	jr Float32_Compare__FCB235                 ; FCB201  jr T,0xfcb235
Float32_Compare__FCB203:
	ld	de, qix                                 ; FCB203  ld DE,QIX
	and	de, 0x8000                             ; FCB206  and DE,0x8000
	cps	de, 0                                  ; FCB20A  cp DE,0
	jr z, Float32_Compare__FCB213              ; FCB20C  jr Z,0xfcb213
	ldw	wa, 3                                  ; FCB20E  ld WA,0x0003
	jr Float32_Compare__FCB215                 ; FCB211  jr T,0xfcb215
Float32_Compare__FCB213:
	sub	wa, wa                                 ; FCB213  sub WA,WA
Float32_Compare__FCB215:
	ld	de, qix                                 ; FCB215  ld DE,QIX
	cp	de, qiy                                 ; FCB218  cp DE,QIY
	jr ugt, Float32_Compare__FCB227            ; FCB21B  jr UGT,0xfcb227
	jr c, Float32_Compare__FCB22D              ; FCB21D  jr C,0xfcb22d
	cp	ix, iy                                  ; FCB21F  cp IX,IY
	jr ugt, Float32_Compare__FCB227            ; FCB221  jr UGT,0xfcb227
	jr c, Float32_Compare__FCB22D              ; FCB223  jr C,0xfcb22d
	jr Float32_Compare__FCB233                 ; FCB225  jr T,0xfcb233
Float32_Compare__FCB227:
	xor	wa, 1                                  ; FCB227  xor WA,0x0001
	jr Float32_Compare__FCB235                 ; FCB22B  jr T,0xfcb235
Float32_Compare__FCB22D:
	xor	wa, 2                                  ; FCB22D  xor WA,0x0002
	jr Float32_Compare__FCB235                 ; FCB231  jr T,0xfcb235
Float32_Compare__FCB233:
	sub	wa, wa                                 ; FCB233  sub WA,WA
Float32_Compare__FCB235:
	pop	xix                                    ; FCB235  pop XIX
	popw	de                                    ; FCB236  pop DE
	unlk32 xiz                                 ; FCB237  unlk XIZ
	retd	8                                     ; FCB239  retd 0x0008
; --------------------------------------------------------------------------
; Shift8_LogicalRight -- 8-bit value >> count, zero-filling.
; Called from: 13 `call` sites in prom_c -- e.g. 0xFB0BD7, 0xFB0EA6, 0xFB10C5.  Counted, not
;              eyeballed: `python3 notes/prom_c_xrefs.py 0xFCB23C --no-window`,
;              whose hits are filtered to those whose preceding byte is the
;              `call` opcode 0x1D.  ⚠ THAT IS AN UPPER BOUND, NOT A DECODE:
;              nothing checks the 0x1D is itself at an instruction boundary,
;              so a literal that happens to follow a 0x1D operand byte would
;              be counted (round-2 audit F12; the same caveat applies to the
;              1,274 total in notes/prom_c_runtime_check.py).
; Inputs:  (XSP+0x04) byte = the value, (XSP+0x06) byte = the count.
; Outputs: A.  `retd 0x0004`.
; Evidence: the same two-step count split as the 16- and 32-bit shifts, applied to
;          the byte register C with `srl A,C`.
; --------------------------------------------------------------------------
Shift8_LogicalRight:
	ld	c, (xsp+4)                              ; FCB23C  ld C,(XSP+0x04)
	ld	b, (xsp+6)                              ; FCB23F  ld B,(XSP+0x06)
	ld	w, b                                    ; FCB242  ld W,B
	srl	w, 4                                   ; FCB244  srl 0x04,W
	sub	a, a                                   ; FCB247  sub A,A
	cps	w, 0                                   ; FCB249  cp W,0
	jr z, Shift8_LogicalRight__FCB24F          ; FCB24B  jr Z,0xfcb24f
	extpfx2 0xCB, 0xFF                         ; FCB24D  srl A,C
Shift8_LogicalRight__FCB24F:
	ld	a, b                                    ; FCB24F  ld A,B
	and	a, 15                                  ; FCB251  and A,0x0f
	jr z, Shift8_LogicalRight__FCB258          ; FCB254  jr Z,0xfcb258
	extpfx2 0xCB, 0xFF                         ; FCB256  srl A,C
Shift8_LogicalRight__FCB258:
	ld	a, c                                    ; FCB258  ld A,C
	retd	4                                     ; FCB25A  retd 0x0004
; --------------------------------------------------------------------------
; Shift8_Left -- 8-bit value << count.  The last routine in the module.
; Called from: ONE site, `call` at 0xFB9B5D (`python3 notes/prom_c_xrefs.py
;              0xFCB25D --no-window`).
; Inputs:  (XSP+0x04) byte, (XSP+0x06) byte.  Outputs: A.  `retd 0x0004`.
; Evidence: byte for byte Shift8_LogicalRight with `sll A,C` for `srl A,C`.
;          ★ Its `retd` is the last instruction before 0xFCB27E, where the pool of
;          IEEE-754 double constants begins -- which is how the module's upper
;          boundary is fixed rather than chosen.
; --------------------------------------------------------------------------
Shift8_Left:
	ld	c, (xsp+4)                              ; FCB25D  ld C,(XSP+0x04)
	ld	b, (xsp+6)                              ; FCB260  ld B,(XSP+0x06)
	ld	w, b                                    ; FCB263  ld W,B
	srl	w, 4                                   ; FCB265  srl 0x04,W
	sub	a, a                                   ; FCB268  sub A,A
	cps	w, 0                                   ; FCB26A  cp W,0
	jr z, Shift8_Left__FCB270                  ; FCB26C  jr Z,0xfcb270
	extpfx2 0xCB, 0xFE                         ; FCB26E  sll A,C
Shift8_Left__FCB270:
	ld	a, b                                    ; FCB270  ld A,B
	and	a, 15                                  ; FCB272  and A,0x0f
	jr z, Shift8_Left__FCB279                  ; FCB275  jr Z,0xfcb279
	extpfx2 0xCB, 0xFE                         ; FCB277  sll A,C
Shift8_Left__FCB279:
	ld	a, c                                    ; FCB279  ld A,C
	retd	4                                     ; FCB27B  retd 0x0004

; ==============================================================================
; 0xFCB27E-0xFCC53E -- the f64 coefficient pool, one f32, and the RAM-image head
; ==============================================================================
;
; Generated by notes/gen_prom_c_f64_pool.py; `--verify` re-proves every boundary
; and every claim below and exits non-zero on failure.  Nothing here is retyped.
;
; ★ THE BOUNDARIES ARE DERIVED, NOT CHOSEN.
;   * the pool starts where Shift8_Left's `retd` ends, at 0xFCB27E;
;   * 77 doubles at a stride of 8 land exactly on 0xFCB4E6, and those four
;     bytes decode as float32 1.0 -- the only 32-bit-loaded quantity in the range,
;     read from 0xFCB00A;
;   * 0xFCB4E6 + 4 = 0xFCB4EA, which is the SOURCE OPERAND of the boot RAM copy,
;     `lda XIY,0xFCB4EA` at 0xF989EF (notes/prom_c_ram_image.py reads it out of
;     the instruction bytes);
;   * and the decode is its own evidence: at this base and stride the pool comes
;     out as a textbook libm coefficient set -- pi, pi/2, 1/pi, 2/pi, ln 2,
;     1/ln 2, 1/sqrt 2, the odd sine Taylor coefficients -1/6 +1/120 -1/5040
;     +1/362880, the exp bounds +-709.78, DBL_MAX/2, DBL_MIN, INT32_MAX.  One
;     wrong byte in the base turns all of them into denormals.
;
; ★ EVERY CONSTANT IS NAMED BY ITS CONSUMER.  Each double is loaded as two 32-bit
; halves, so it appears in the image as a 24-bit address operand at X and again at
; X+4.  149 such sites exist; 147 are inside the math library at 0xFC8000-0xFCB27D
; and the other two are at 0xFBAA80 and 0xFBBF53.  The routines listed beside each
; entry are the labels those sites fall under in this file -- not a guess from the
; value.
;
; ★ 54 of the 77 entries are loaded by a located site.  The other 23 are NOT
; unexplained: every one of them sits immediately after a loaded entry, in seven
; runs, which is the shape of a COEFFICIENT ARRAY walked with a pointer from its
; first element.  The runs, with the routine that loads the head:
; ⚠ WHAT THOSE ARRAYS ARE is NOT established here, and no routine is renamed on
; the strength of it.  What is MEASURED, and only that:
;   * the eight entries at 0xFCB2CE alternate in sign and, read from the HIGH
;     address downwards, are 1/3!, 1/5!, 1/7! ... 1/17! -- bit-exact at 1/3! and
;     drifting to 3.2e-2 relative at the 1/17! end, i.e. a FITTED odd polynomial
;     rather than the Taylor series;
;   * the arrays at 0xFCB38E and 0xFCB4BE both END on exactly 1.0;
;   * entries [24] and [25] SUM to pi/2 bit-exactly
;     (1.57080078125 + -4.454455103380769e-06), which is a two-word Cody-Waite
;     split of one constant, not two constants.
;
; ⚠ NOT ESTABLISHED: the RAM-image half below is emitted as bytes with the
; DESTINATION RAM ADDRESS in the comment and NOTHING ELSE.  Its field layout is
; open; notes/FINDINGS-prom_c-ram-image.md carries the individual defaults that
; have been pinned down.

; ----------------------------------------------------------------------------
; Float64_ConstantPool -- 0xFCB27E..0xFCB4E5  (77 x 8 = 616 bytes)
; ----------------------------------------------------------------------------
Float64_ConstantPool:
	.byte	0x18, 0x2d, 0x44, 0x54, 0xfb, 0x21, 0xf9, 0x3f   ; [ 0] 0xFCB27E = 1.5707963267948966  (pi/2)
	;      no loading site located
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf0, 0x3f   ; [ 1] 0xFCB286 = 1.0
	;      no loading site located
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; [ 2] 0xFCB28E = 0.0
	;      no loading site located
	.byte	0xcd, 0x3b, 0x7f, 0x66, 0x9e, 0xa0, 0x46, 0x3e   ; [ 3] 0xFCB296 = 1.0536712127723509e-08
	;      no loading site located
	.byte	0x18, 0x2d, 0x44, 0x54, 0xfb, 0x21, 0x09, 0x40   ; [ 4] 0xFCB29E = 3.141592653589793  (pi)
	;      no loading site located
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xe0, 0x3f   ; [ 5] 0xFCB2A6 = 0.5
	;      no loading site located
	.byte	0x83, 0xc8, 0xc9, 0x6d, 0x30, 0x5f, 0xd4, 0x3f   ; [ 6] 0xFCB2AE = 0.3183098861837907  (1/pi)
	;      no loading site located
	.byte	0x00, 0x00, 0x00, 0x1a, 0x83, 0xc5, 0xb1, 0x41   ; [ 7] 0xFCB2B6 = 298156826.0
	;      no loading site located
	.byte	0x18, 0x2d, 0x44, 0x54, 0xfb, 0x21, 0x49, 0x43   ; [ 8] 0xFCB2BE = 1.414847550405688e+16
	;      no loading site located
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; [ 9] 0xFCB2C6 = 0.0
	;      no loading site located
	.byte	0x95, 0xdf, 0x93, 0x69, 0xff, 0x80, 0xe8, 0x3c   ; [10] 0xFCB2CE = 2.7204790957888847e-15
	;      no loading site located
	.byte	0x9c, 0x49, 0x08, 0xdc, 0x20, 0xe4, 0x6a, 0xbd   ; [11] 0xFCB2D6 = -7.642917806891047e-13
	;      no loading site located
	.byte	0x30, 0xd4, 0x6a, 0x68, 0x3c, 0x12, 0xe6, 0x3d   ; [12] 0xFCB2DE = 1.605893649037159e-10
	;      no loading site located
	.byte	0xab, 0xc0, 0x5d, 0x4b, 0x45, 0xe6, 0x5a, 0xbe   ; [13] 0xFCB2E6 = -2.5052106798274583e-08
	;      no loading site located
	.byte	0x63, 0xf0, 0x24, 0xa5, 0xe3, 0x1d, 0xc7, 0x3e   ; [14] 0xFCB2EE = 2.7557319210152756e-06  (~ +1/9!  (5.0e-10 rel.))
	;      no loading site located
	.byte	0x1a, 0x3e, 0x01, 0x1a, 0xa0, 0x01, 0x2a, 0xbf   ; [15] 0xFCB2F6 = -0.0001984126984120184  (~ -1/7!  (3.5e-13 rel.))
	;      no loading site located
	.byte	0xb0, 0x10, 0x11, 0x11, 0x11, 0x11, 0x81, 0x3f   ; [16] 0xFCB2FE = 0.008333333333333165  (~ +1/5!  (1.7e-14 rel.))
	;      no loading site located
	.byte	0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0xc5, 0xbf   ; [17] 0xFCB306 = -0.16666666666666666  (= -1/3!  exactly)
	;      no loading site located
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; [18] 0xFCB30E = 0.0
	;      no loading site located
	.byte	0x00, 0x00, 0xc0, 0xff, 0xff, 0xff, 0xdf, 0x41   ; [19] 0xFCB316 = 2147483647.0  (INT32_MAX)
	;      no loading site located
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf0, 0x3f   ; [20] 0xFCB31E = 1.0
	;      no loading site located
	.byte	0xcd, 0x3b, 0x7f, 0x66, 0x9e, 0xa0, 0x46, 0x3e   ; [21] 0xFCB326 = 1.0536712127723509e-08
	;      no loading site located
	.byte	0xcd, 0x3b, 0x7f, 0x66, 0x9e, 0xa0, 0x46, 0xbe   ; [22] 0xFCB32E = -1.0536712127723509e-08
	;      no loading site located
	.byte	0x18, 0x2d, 0x44, 0x54, 0xfb, 0x21, 0xf9, 0x3f   ; [23] 0xFCB336 = 1.5707963267948966  (pi/2)
	;      no loading site located
	.byte	0x9e, 0xe5, 0x9e, 0x4b, 0xef, 0xae, 0xd2, 0xbe   ; [24] 0xFCB33E = -4.454455103380769e-06
	;      no loading site located
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x22, 0xf9, 0x3f   ; [25] 0xFCB346 = 1.57080078125
	;      no loading site located
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xe0, 0x3f   ; [26] 0xFCB34E = 0.5
	;      no loading site located
	.byte	0x83, 0xc8, 0xc9, 0x6d, 0x30, 0x5f, 0xe4, 0x3f   ; [27] 0xFCB356 = 0.6366197723675814  (2/pi)
	;      no loading site located
	.byte	0x00, 0x00, 0x00, 0x1a, 0x83, 0xc5, 0xa1, 0x41   ; [28] 0xFCB35E = 149078413.0
	;      no loading site located
	.byte	0x18, 0x2d, 0x44, 0x54, 0xfb, 0x21, 0x39, 0x43   ; [29] 0xFCB366 = 7074237752028440.0
	;      no loading site located
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; [30] 0xFCB36E = 0.0
	;      no loading site located
	.byte	0x23, 0xc7, 0xa2, 0x2e, 0xb7, 0xba, 0xf2, 0xbe   ; [31] 0xFCB376 = -1.7861707342254424e-05
	;      no loading site located
	.byte	0xdf, 0xaa, 0x3b, 0xa6, 0x82, 0x0e, 0x6c, 0x3f   ; [32] 0xFCB37E = 0.003424887823589059
	;      no loading site located
	.byte	0xff, 0x08, 0x4d, 0xe5, 0xb5, 0x12, 0xc1, 0xbf   ; [33] 0xFCB386 = -0.1333835000642196
	;      no loading site located
	.byte	0xe9, 0x78, 0x76, 0xf0, 0x74, 0xb7, 0xa0, 0x3e   ; [34] 0xFCB38E = 4.981943399378651e-07
	;      no loading site located
	.byte	0x41, 0x48, 0x09, 0x99, 0x64, 0x6f, 0x34, 0xbf   ; [35] 0xFCB396 = -0.00031181531907010027
	;      no loading site located
	.byte	0x59, 0x21, 0x7e, 0xa1, 0x9e, 0x47, 0x9a, 0x3f   ; [36] 0xFCB39E = 0.025663832289440112
	;      no loading site located
	.byte	0xd5, 0xd9, 0xfb, 0x47, 0xb0, 0xde, 0xdd, 0xbf   ; [37] 0xFCB3A6 = -0.46671683339755293
	;      no loading site located
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf0, 0x3f   ; [38] 0xFCB3AE = 1.0
	;      no loading site located
	.byte	0xa2, 0xb4, 0x37, 0xf8, 0x42, 0x2e, 0x86, 0xc0   ; [39] 0xFCB3B6 = -709.7827
	;      no loading site located
	.byte	0xef, 0x39, 0xfa, 0xfe, 0x42, 0x2e, 0x86, 0x40   ; [40] 0xFCB3BE = 709.782712893384  (ln(DBL_MAX), the exp overflow bound)
	;      no loading site located
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xe0, 0x3f   ; [41] 0xFCB3C6 = 0.5
	;      no loading site located
	.byte	0x00, 0x00, 0xc0, 0xff, 0xff, 0xff, 0xdf, 0x41   ; [42] 0xFCB3CE = 2147483647.0  (INT32_MAX)
	;      no loading site located
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; [43] 0xFCB3D6 = 0.0
	;      no loading site located
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf0, 0x3f   ; [44] 0xFCB3DE = 1.0
	;      no loading site located
	.byte	0xef, 0x39, 0xfa, 0xfe, 0x42, 0x2e, 0xe6, 0x3f   ; [45] 0xFCB3E6 = 0.6931471805599453  (ln 2)
	;      no loading site located
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xe0, 0x3f   ; [46] 0xFCB3EE = 0.5
	;      no loading site located
	.byte	0xfe, 0x82, 0x2b, 0x65, 0x47, 0x15, 0xf7, 0x3f   ; [47] 0xFCB3F6 = 1.4426950408889634  (1/ln 2 = log2(e))
	;      no loading site located
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf0, 0x3f   ; [48] 0xFCB3FE = 1.0
	;      no loading site located
	.byte	0xcd, 0x3b, 0x7f, 0x66, 0x9e, 0xa0, 0x46, 0x3e   ; [49] 0xFCB406 = 1.0536712127723509e-08
	;      no loading site located
	.byte	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xdf, 0x7f   ; [50] 0xFCB40E = 8.988465674311579e+307  (DBL_MAX/2)
	;      no loading site located
	.byte	0xef, 0x39, 0xfa, 0xfe, 0x42, 0x2e, 0x86, 0x40   ; [51] 0xFCB416 = 709.782712893384  (ln(DBL_MAX), the exp overflow bound)
	;      no loading site located
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; [52] 0xFCB41E = 0.0
	;      no loading site located
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x10, 0x00   ; [53] 0xFCB426 = 2.2250738585072014e-308  (DBL_MIN)
	;      no loading site located
	.byte	0xa2, 0xb4, 0x37, 0xf8, 0x42, 0x2e, 0x86, 0xc0   ; [54] 0xFCB42E = -709.7827
	;      no loading site located
	.byte	0x1e, 0x92, 0xe6, 0x2a, 0x44, 0x8b, 0x00, 0x3f   ; [55] 0xFCB436 = 3.1555192765684645e-05
	;      no loading site located
	.byte	0xa5, 0x12, 0x2a, 0xf2, 0x4b, 0x07, 0x7f, 0x3f   ; [56] 0xFCB43E = 0.007575318015942277
	;      no loading site located
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xd0, 0x3f   ; [57] 0xFCB446 = 0.25
	;      no loading site located
	.byte	0x55, 0x04, 0xe5, 0x0c, 0x63, 0x33, 0xa9, 0x3e   ; [58] 0xFCB44E = 7.510402839987004e-07
	;      no loading site located
	.byte	0xdf, 0xd4, 0x28, 0x5c, 0x0c, 0xaf, 0x44, 0x3f   ; [59] 0xFCB456 = 0.000631218943743985
	;      no loading site located
	.byte	0xff, 0xd9, 0xdf, 0x51, 0x28, 0x17, 0xad, 0x3f   ; [60] 0xFCB45E = 0.056817302698551224
	;      no loading site located
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xe0, 0x3f   ; [61] 0xFCB466 = 0.5
	;      no loading site located
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; [62] 0xFCB46E = 0.0
	;      no loading site located
	.byte	0xef, 0x39, 0xfa, 0xfe, 0x42, 0x2e, 0xe6, 0x3f   ; [63] 0xFCB476 = 0.6931471805599453  (ln 2)
	;      no loading site located
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xe0, 0x3f   ; [64] 0xFCB47E = 0.5
	;      no loading site located
	.byte	0xcd, 0x3b, 0x7f, 0x66, 0x9e, 0xa0, 0xe6, 0x3f   ; [65] 0xFCB486 = 0.7071067811865476  (1/sqrt 2)
	;      no loading site located
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf0, 0x3f   ; [66] 0xFCB48E = 1.0
	;      no loading site located
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; [67] 0xFCB496 = 0.0
	;      no loading site located
	.byte	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xdf, 0x7f   ; [68] 0xFCB49E = 8.988465674311579e+307  (DBL_MAX/2)
	;      no loading site located
	.byte	0x29, 0xbd, 0x56, 0xb3, 0x15, 0x44, 0xe9, 0xbf   ; [69] 0xFCB4A6 = -0.7895611288749126
	;      no loading site located
	.byte	0xed, 0xaf, 0x16, 0x20, 0x4a, 0x62, 0x30, 0x40   ; [70] 0xFCB4AE = 16.383943563021536
	;      no loading site located
	.byte	0x9a, 0xb5, 0xb3, 0x12, 0xff, 0x07, 0x50, 0xc0   ; [71] 0xFCB4B6 = -64.12494342374558
	;      no loading site located
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf0, 0x3f   ; [72] 0xFCB4BE = 1.0
	;      no loading site located
	.byte	0x0f, 0xce, 0x67, 0x4b, 0x80, 0xd5, 0x41, 0xc0   ; [73] 0xFCB4C6 = -35.66797773903465
	;      no loading site located
	.byte	0x7e, 0x26, 0x15, 0xfa, 0x83, 0x80, 0x73, 0x40   ; [74] 0xFCB4CE = 312.03222091924533
	;      no loading site located
	.byte	0x77, 0x90, 0x0d, 0x9c, 0xfe, 0x0b, 0x88, 0xc0   ; [75] 0xFCB4D6 = -769.4993210849487
	;      no loading site located
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; [76] 0xFCB4DE = 0.0
	;      no loading site located

; ----------------------------------------------------------------------------
; Float32_One -- 0xFCB4E6..0xFCB4E9  (4 bytes)
; ----------------------------------------------------------------------------
; IEEE-754 float32 1.0.  Loaded from 0xFCB00A -- the site the tone-generator note
; already quotes for `Float32_Multiply is really a / (1/b)`.
Float32_One:
	.byte	0x00, 0x00, 0x80, 0x3f        ; 1.0f

; ----------------------------------------------------------------------------
; BootRamImage_Head -- 0xFCB4EA..0xFCC53E  (4181 bytes)
; ----------------------------------------------------------------------------
; The first 4,181 bytes of the 4,312-byte block RESET copies to RAM 0x00E2DF
; (`ldir` at 0xF989FE, count 0x10D8).  The copy does not stop here -- it runs on
; to 0xFCC5C1, through the first four objects of the table zone below, which is
; why those are relocated to RAM and patchable at runtime.
; The comment on each row is the RAM address its first byte lands on.
BootRamImage_Head:
	.byte	0x00, 0x00, 0xe8, 0x03, 0x00, 0x01, 0x80, 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB4EA -> RAM 0x00E2DF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB4FA -> RAM 0x00E2EF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB50A -> RAM 0x00E2FF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB51A -> RAM 0x00E30F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB52A -> RAM 0x00E31F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB53A -> RAM 0x00E32F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB54A -> RAM 0x00E33F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB55A -> RAM 0x00E34F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB56A -> RAM 0x00E35F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB57A -> RAM 0x00E36F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB58A -> RAM 0x00E37F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB59A -> RAM 0x00E38F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB5AA -> RAM 0x00E39F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB5BA -> RAM 0x00E3AF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB5CA -> RAM 0x00E3BF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB5DA -> RAM 0x00E3CF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB5EA -> RAM 0x00E3DF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB5FA -> RAM 0x00E3EF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB60A -> RAM 0x00E3FF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB61A -> RAM 0x00E40F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB62A -> RAM 0x00E41F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB63A -> RAM 0x00E42F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB64A -> RAM 0x00E43F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB65A -> RAM 0x00E44F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB66A -> RAM 0x00E45F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB67A -> RAM 0x00E46F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB68A -> RAM 0x00E47F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB69A -> RAM 0x00E48F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB6AA -> RAM 0x00E49F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB6BA -> RAM 0x00E4AF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB6CA -> RAM 0x00E4BF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB6DA -> RAM 0x00E4CF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB6EA -> RAM 0x00E4DF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB6FA -> RAM 0x00E4EF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB70A -> RAM 0x00E4FF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB71A -> RAM 0x00E50F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB72A -> RAM 0x00E51F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB73A -> RAM 0x00E52F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB74A -> RAM 0x00E53F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB75A -> RAM 0x00E54F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB76A -> RAM 0x00E55F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB77A -> RAM 0x00E56F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB78A -> RAM 0x00E57F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB79A -> RAM 0x00E58F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB7AA -> RAM 0x00E59F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB7BA -> RAM 0x00E5AF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB7CA -> RAM 0x00E5BF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB7DA -> RAM 0x00E5CF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB7EA -> RAM 0x00E5DF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB7FA -> RAM 0x00E5EF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB80A -> RAM 0x00E5FF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB81A -> RAM 0x00E60F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB82A -> RAM 0x00E61F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB83A -> RAM 0x00E62F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB84A -> RAM 0x00E63F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB85A -> RAM 0x00E64F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB86A -> RAM 0x00E65F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB87A -> RAM 0x00E66F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB88A -> RAM 0x00E67F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB89A -> RAM 0x00E68F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB8AA -> RAM 0x00E69F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB8BA -> RAM 0x00E6AF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB8CA -> RAM 0x00E6BF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB8DA -> RAM 0x00E6CF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB8EA -> RAM 0x00E6DF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB8FA -> RAM 0x00E6EF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB90A -> RAM 0x00E6FF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB91A -> RAM 0x00E70F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB92A -> RAM 0x00E71F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB93A -> RAM 0x00E72F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB94A -> RAM 0x00E73F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB95A -> RAM 0x00E74F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB96A -> RAM 0x00E75F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB97A -> RAM 0x00E76F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB98A -> RAM 0x00E77F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB99A -> RAM 0x00E78F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB9AA -> RAM 0x00E79F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB9BA -> RAM 0x00E7AF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB9CA -> RAM 0x00E7BF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB9DA -> RAM 0x00E7CF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB9EA -> RAM 0x00E7DF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCB9FA -> RAM 0x00E7EF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBA0A -> RAM 0x00E7FF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBA1A -> RAM 0x00E80F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBA2A -> RAM 0x00E81F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBA3A -> RAM 0x00E82F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBA4A -> RAM 0x00E83F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBA5A -> RAM 0x00E84F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBA6A -> RAM 0x00E85F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBA7A -> RAM 0x00E86F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBA8A -> RAM 0x00E87F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBA9A -> RAM 0x00E88F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBAAA -> RAM 0x00E89F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBABA -> RAM 0x00E8AF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBACA -> RAM 0x00E8BF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBADA -> RAM 0x00E8CF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBAEA -> RAM 0x00E8DF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBAFA -> RAM 0x00E8EF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBB0A -> RAM 0x00E8FF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBB1A -> RAM 0x00E90F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBB2A -> RAM 0x00E91F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBB3A -> RAM 0x00E92F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBB4A -> RAM 0x00E93F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBB5A -> RAM 0x00E94F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBB6A -> RAM 0x00E95F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBB7A -> RAM 0x00E96F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBB8A -> RAM 0x00E97F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBB9A -> RAM 0x00E98F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBBAA -> RAM 0x00E99F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBBBA -> RAM 0x00E9AF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBBCA -> RAM 0x00E9BF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBBDA -> RAM 0x00E9CF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBBEA -> RAM 0x00E9DF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBBFA -> RAM 0x00E9EF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBC0A -> RAM 0x00E9FF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBC1A -> RAM 0x00EA0F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBC2A -> RAM 0x00EA1F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBC3A -> RAM 0x00EA2F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBC4A -> RAM 0x00EA3F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBC5A -> RAM 0x00EA4F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBC6A -> RAM 0x00EA5F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBC7A -> RAM 0x00EA6F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBC8A -> RAM 0x00EA7F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBC9A -> RAM 0x00EA8F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBCAA -> RAM 0x00EA9F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBCBA -> RAM 0x00EAAF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBCCA -> RAM 0x00EABF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBCDA -> RAM 0x00EACF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBCEA -> RAM 0x00EADF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBCFA -> RAM 0x00EAEF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBD0A -> RAM 0x00EAFF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBD1A -> RAM 0x00EB0F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBD2A -> RAM 0x00EB1F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBD3A -> RAM 0x00EB2F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBD4A -> RAM 0x00EB3F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBD5A -> RAM 0x00EB4F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBD6A -> RAM 0x00EB5F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBD7A -> RAM 0x00EB6F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBD8A -> RAM 0x00EB7F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBD9A -> RAM 0x00EB8F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBDAA -> RAM 0x00EB9F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBDBA -> RAM 0x00EBAF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBDCA -> RAM 0x00EBBF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBDDA -> RAM 0x00EBCF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBDEA -> RAM 0x00EBDF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBDFA -> RAM 0x00EBEF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBE0A -> RAM 0x00EBFF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBE1A -> RAM 0x00EC0F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBE2A -> RAM 0x00EC1F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBE3A -> RAM 0x00EC2F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBE4A -> RAM 0x00EC3F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBE5A -> RAM 0x00EC4F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBE6A -> RAM 0x00EC5F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBE7A -> RAM 0x00EC6F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBE8A -> RAM 0x00EC7F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBE9A -> RAM 0x00EC8F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBEAA -> RAM 0x00EC9F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBEBA -> RAM 0x00ECAF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBECA -> RAM 0x00ECBF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBEDA -> RAM 0x00ECCF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBEEA -> RAM 0x00ECDF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBEFA -> RAM 0x00ECEF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBF0A -> RAM 0x00ECFF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBF1A -> RAM 0x00ED0F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBF2A -> RAM 0x00ED1F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBF3A -> RAM 0x00ED2F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBF4A -> RAM 0x00ED3F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBF5A -> RAM 0x00ED4F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBF6A -> RAM 0x00ED5F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBF7A -> RAM 0x00ED6F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBF8A -> RAM 0x00ED7F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBF9A -> RAM 0x00ED8F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBFAA -> RAM 0x00ED9F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBFBA -> RAM 0x00EDAF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBFCA -> RAM 0x00EDBF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBFDA -> RAM 0x00EDCF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBFEA -> RAM 0x00EDDF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCBFFA -> RAM 0x00EDEF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC00A -> RAM 0x00EDFF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC01A -> RAM 0x00EE0F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC02A -> RAM 0x00EE1F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC03A -> RAM 0x00EE2F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC04A -> RAM 0x00EE3F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC05A -> RAM 0x00EE4F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC06A -> RAM 0x00EE5F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC07A -> RAM 0x00EE6F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC08A -> RAM 0x00EE7F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC09A -> RAM 0x00EE8F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC0AA -> RAM 0x00EE9F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC0BA -> RAM 0x00EEAF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC0CA -> RAM 0x00EEBF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC0DA -> RAM 0x00EECF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC0EA -> RAM 0x00EEDF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC0FA -> RAM 0x00EEEF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC10A -> RAM 0x00EEFF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC11A -> RAM 0x00EF0F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC12A -> RAM 0x00EF1F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC13A -> RAM 0x00EF2F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC14A -> RAM 0x00EF3F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC15A -> RAM 0x00EF4F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC16A -> RAM 0x00EF5F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC17A -> RAM 0x00EF6F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC18A -> RAM 0x00EF7F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC19A -> RAM 0x00EF8F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC1AA -> RAM 0x00EF9F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC1BA -> RAM 0x00EFAF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC1CA -> RAM 0x00EFBF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC1DA -> RAM 0x00EFCF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC1EA -> RAM 0x00EFDF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC1FA -> RAM 0x00EFEF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC20A -> RAM 0x00EFFF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC21A -> RAM 0x00F00F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC22A -> RAM 0x00F01F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC23A -> RAM 0x00F02F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC24A -> RAM 0x00F03F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC25A -> RAM 0x00F04F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC26A -> RAM 0x00F05F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC27A -> RAM 0x00F06F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC28A -> RAM 0x00F07F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC29A -> RAM 0x00F08F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC2AA -> RAM 0x00F09F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC2BA -> RAM 0x00F0AF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC2CA -> RAM 0x00F0BF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC2DA -> RAM 0x00F0CF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC2EA -> RAM 0x00F0DF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC2FA -> RAM 0x00F0EF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC30A -> RAM 0x00F0FF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC31A -> RAM 0x00F10F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC32A -> RAM 0x00F11F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC33A -> RAM 0x00F12F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC34A -> RAM 0x00F13F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC35A -> RAM 0x00F14F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC36A -> RAM 0x00F15F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC37A -> RAM 0x00F16F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC38A -> RAM 0x00F17F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC39A -> RAM 0x00F18F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC3AA -> RAM 0x00F19F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC3BA -> RAM 0x00F1AF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC3CA -> RAM 0x00F1BF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC3DA -> RAM 0x00F1CF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC3EA -> RAM 0x00F1DF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC3FA -> RAM 0x00F1EF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC40A -> RAM 0x00F1FF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC41A -> RAM 0x00F20F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC42A -> RAM 0x00F21F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC43A -> RAM 0x00F22F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC44A -> RAM 0x00F23F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC45A -> RAM 0x00F24F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC46A -> RAM 0x00F25F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC47A -> RAM 0x00F26F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC48A -> RAM 0x00F27F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC49A -> RAM 0x00F28F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC4AA -> RAM 0x00F29F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC4BA -> RAM 0x00F2AF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC4CA -> RAM 0x00F2BF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC4DA -> RAM 0x00F2CF
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC4EA -> RAM 0x00F2DF
	.byte	0x00, 0x00, 0x64, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0x00, 0x00, 0x00, 0xda, 0x7e, 0x00, 0x00   ; 0xFCC4FA -> RAM 0x00F2EF
	.byte	0xd9, 0x82, 0x00, 0x00, 0xda, 0x7e, 0x00, 0x00, 0xda, 0x7e, 0x00, 0x00, 0xda, 0x7e, 0x00, 0x00   ; 0xFCC50A -> RAM 0x00F2FF
	.byte	0xff, 0x03, 0xda, 0x82, 0x00, 0x00, 0xd9, 0x84, 0x00, 0x00, 0xda, 0x82, 0x00, 0x00, 0xda, 0x82   ; 0xFCC51A -> RAM 0x00F30F
	.byte	0x00, 0x00, 0xda, 0x82, 0x00, 0x00, 0xff, 0x01, 0x00, 0xff, 0x00, 0x06, 0x50, 0x00, 0x00, 0x00   ; 0xFCC52A -> RAM 0x00F31F
	.byte	0x00, 0x00, 0x00, 0x00, 0x00   ; 0xFCC53A -> RAM 0x00F32F
