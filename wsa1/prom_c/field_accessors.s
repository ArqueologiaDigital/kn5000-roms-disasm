; ==============================================================================
; Technics SX-WSA1R -- prom_c (CPU 2, IC28) -- 0xFC3407-0xFC856B  the field accessors and their callers
; ==============================================================================
;
; 10,516 lines moved out of prom_c/wsa1_prom_c.s by notes/prom_c_split.py.  The master
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
; Banner-declared, and kept at the top level BECAUSE it is a grab-bag rather
; than a subsystem: Dev104_PackStagingStruct (the sole producer for the
; 0x00104000 device), the eight-slot note pool, the Q11 fixed-point math
; helpers, SoundRam_ClearFourBanks and 511 sub_XXXXXX.  Giving it a
; subject directory would assert a cohesion it does not have; the tree's own
; title is kept instead.
;
; >>> END OF EXTRACTION HEADER -- everything below is verbatim from the master

; ==============================================================================
; 0xFC3407-0xFC856B -- ★ THE FIELD ACCESSORS AND THEIR CALLERS
;                      86 routines, no tables, 20,837 bytes
; ==============================================================================
;
; The third block converted in round 3, and the last one the frontier ranked before
; the ranking went flat.  It runs from a `link XIZ` at 0xFC3407 (the byte before it,
; 0xFC3406, is `ret`) up to the byte before Flash_ProgramWord at 0xFC856C, which was
; already converted -- so both cuts fall between routines and neither was chosen by
; address arithmetic.
;
;   python3 notes/prom_c_frontier_src.py --range 0xFC3407-0xFC856B
;     RANGE 0xFC3407-0xFC856B  ->  32 target(s), 84 site(s), 20837 byte(s) wide
;
; ★ 173 literal call sites reach it from outside, 81 from inside.  ✔ Re-measured at
;   the end of round 3: ALL 173 are in converted code (95 were still `.incbin` when
;   this block was converted).  The named ones are the note path again --
;   MidiNote_OnByPartMode (9), VoiceParams_Compute_A/C/D (19 between them), the four
;   VoiceRegs_Stage_* (20) -- plus Voice_StageRegs_0040_B from the block converted above and
;   sub_FB6500 (8) and sub_FBB793 (6) from the blocks converted after it.
;   Full tally: `python3 notes/prom_c_module_map.py 0xFC3407 0xFC856C`.  ⚠ The
;   figures were 180/88 for most of round 3, before the tool filtered byte-pattern
;   noise out of its site scan.
;
; ★★ THE SHAPE OF THIS BLOCK IS ONE ACCESSOR PER STRUCT FIELD, and the duplicate
;   census shows it without anyone having to assert it -- NINE pairs, of which these
;   six differ in a single byte
;   (`python3 notes/prom_c_module_map.py 0xFC3407 0xFC856C --dups`):
;
;       0xFC3595 / 0xFC35B8   35 bytes, ONE byte differs   +0x1A: 0C vs 0E
;       0xFC37BE / 0xFC37E2   36 bytes, ONE byte differs   +0x19: 09 vs 0A
;       0xFC37BE / 0xFC3806   36 bytes, ONE byte differs   +0x19: 09 vs 0B
;       0xFC37E2 / 0xFC3806   36 bytes, ONE byte differs   +0x19: 0A vs 0B
;       0xFC419D / 0xFC41C3   38 bytes, ONE byte differs   +0x19: 06 vs 08
;       0xFC6CA8 / 0xFC6CEA   66 bytes, ONE byte differs   +0x2B: DC vs DA
;
;   In the first three the differing byte is the displacement of a `ld W,(XBC+n)` --
;   0xFC37BE reads field +0x09, 0xFC37E2 reads +0x0A, 0xFC3806 reads +0x0B, and the
;   other 35 bytes of all three are identical.  Three routines, three consecutive
;   fields, one routine body.  The 578-byte pair 0xFC6FFD / 0xFC723F differs in eight
;   bytes and is a variant rather than a copy; the tool prints every differing byte
;   with both values rather than rounding it up to "identical".
;
; ★ THE DECODE IS ALIGNED, and that is checked independently of the byte gate.
;   `notes/gen_prom_c_block.py` collects every `call`/`calr`/`jp`/`jrl`/`jr` target
;   that DECODED INSTRUCTIONS in this file name, and requires each one landing inside
;   the range to be the start of a listing line.  For this block that is 623 distinct
;   targets, all of them boundaries.  A byte round trip cannot show that -- a
;   misaligned decode of data can re-encode to the same bytes -- so this is the test
;   that says the listing is not merely rebuildable but read at the right offsets.
;   ⚠ The sites come from decoded instructions only, never from a byte-pattern scan
;   for `1D`/`1E`: at 0xFA8972 such a scan reads the displacement byte of a `jr` as a
;   `calr` and invents a call.  Six phantoms of exactly that kind appeared the first
;   time this check was written.
;
; ★ `python3 notes/prom_c_jumptables.py 0xFB828E 0xFC856C` finds no computed-goto
;   table anywhere in the enclosing span, so unlike 0xFA7E2C-0xFABE2F this range has
;   no embedded pointer arrays to cut around.
;
; ⚠ NO ROUTINE HERE IS NAMED FOR WHAT IT DOES.  Every header states the frame size,
;   the argument slots read, the absolute addresses read and written, the routines
;   called and the call sites -- operands and decoded-instruction scans, nothing
;   interpreted.  The field NUMBERS above are operands; what any field MEANS is not
;   established by anything in this block.
;
; ★ REGENERATE:
;       python3 notes/gen_prom_c_block.py --start 0xFC3407 --end 0xFC856C > /tmp/m3.s
;       python3 notes/gen_prom_c_block_headers.py --start 0xFC3407 --end 0xFC856C \
;           --labels > /tmp/m3.labels
;       python3 notes/gen_prom_c_block_headers.py --start 0xFC3407 --end 0xFC856C \
;           --headers > /tmp/m3.headers
;       python3 notes/prom_c_apply_headers.py /tmp/m3.s /tmp/m3.labels /tmp/m3.headers \
;           > /tmp/m3.final.s
;       python3 notes/prom_c_verify_fragment.py c 0xFC3407 /tmp/m3.final.s
; ==============================================================================
; --------------------------------------------------------------------------
; sub_FC3407 -- 0xFC3407..0xFC347F (121 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFA829C in Voice_StageRegs_0040_B
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFC3407-0xFC347F
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC3407:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FC3407  link XIZ,0xfffc
	pushw	hl                                   ; FC340B  push HL
	pushw	de                                   ; FC340C  push DE
	push	xix                                   ; FC340D  push XIX
	ldb	c, 23                                  ; FC340E  ld C,0x17
	extpfx3 0x8E, 0x08, 0x43                   ; FC3410  mul BC,(XIZ+0x08)
	extz	xbc                                   ; FC3413  extz XBC
	add	xbc, 0xDC0E                            ; FC3415  add XBC,0x0000dc0e
	ld	(xiz-4), xbc                            ; FC341B  ld (XIZ+0xfc),XBC
	ldb	a, 68                                  ; FC341E  ld A,0x44
	extpfx3 0x8E, 0x0A, 0x41                   ; FC3420  mul WA,(XIZ+0x0a)
	inc	6, wa                                  ; FC3423  inc 6,WA
	extz	xwa                                   ; FC3425  extz XWA
	ld	iy, (xwa+0x3BCF)                        ; FC3427  ld IY,(XWA+0x3bcf)
	srl	iy, 8                                  ; FC342C  srl 0x08,IY
	ld	hl, iy                                  ; FC342F  ld HL,IY
	add	hl, 12                                 ; FC3431  add HL,0x000c
	ldb	a, 2                                   ; FC3435  ld A,0x02
	extpfx3 0x8E, 0x0C, 0x41                   ; FC3437  mul WA,(XIZ+0x0c)
	extz	xwa                                   ; FC343A  extz XWA
	ld	xix, xbc                                ; FC343C  ld XIX,XBC
	add	xix, xwa                               ; FC343E  add XIX,XWA
	cp	hl, 36                                  ; FC3440  cp HL,0x0024
	jr c, sub_FC3407__FC344C                   ; FC3444  jr C,0xfc344c
	ld	bc, (xix)                               ; FC3446  ld BC,(XIX)
	ld	wa, bc                                  ; FC3448  ld WA,BC
	jr sub_FC3407__FC347A                      ; FC344A  jr T,0xfc347a
sub_FC3407__FC344C:
	ld	hl, (xix)                               ; FC344C  ld HL,(XIX)
	ld	de, hl                                  ; FC344E  ld DE,HL
	and	de, 15                                 ; FC3450  and DE,0x000f
	ld	bc, hl                                  ; FC3454  ld BC,HL
	srl	bc, 4                                  ; FC3456  srl 0x04,BC
	and	bc, 15                                 ; FC3459  and BC,0x000f
	cp	de, bc                                  ; FC345D  cp DE,BC
	jr nc, sub_FC3407__FC346B                  ; FC345F  jr NC,0xfc346b
	ld	bc, hl                                  ; FC3461  ld BC,HL
	and	bc, 0xFF0                              ; FC3463  and BC,0x0ff0
	ld	wa, bc                                  ; FC3467  ld WA,BC
	jr sub_FC3407__FC347A                      ; FC3469  jr T,0xfc347a
sub_FC3407__FC346B:
	ld	ix, hl                                  ; FC346B  ld IX,HL
	and	ix, 0xF00                              ; FC346D  and IX,0x0f00
	ld	bc, de                                  ; FC3471  ld BC,DE
	sll	bc, 4                                  ; FC3473  sll 0x04,BC
	or	bc, ix                                  ; FC3476  or BC,IX
	ld	wa, bc                                  ; FC3478  ld WA,BC
sub_FC3407__FC347A:
	pop	xix                                    ; FC347A  pop XIX
	popw	de                                    ; FC347B  pop DE
	popw	hl                                    ; FC347C  pop HL
	unlk32 xiz                                 ; FC347D  unlk XIZ
	ret                                        ; FC347F  ret
; --------------------------------------------------------------------------
; sub_FC3480 -- 0xFC3480..0xFC355A (219 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFA82B5 in Voice_StageRegs_0040_B__FA82A4
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFC3480-0xFC355A
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC3480:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FC3480  link XIZ,0xfffc
	pushw	hl                                   ; FC3484  push HL
	pushw	de                                   ; FC3485  push DE
	push	xix                                   ; FC3486  push XIX
	ldb	c, 23                                  ; FC3487  ld C,0x17
	extpfx3 0x8E, 0x08, 0x43                   ; FC3489  mul BC,(XIZ+0x08)
	extz	xbc                                   ; FC348C  extz XBC
	ld	xix, xbc                                ; FC348E  ld XIX,XBC
	add	xix, 0xDC0E                            ; FC3490  add XIX,0x0000dc0e
	ldb	h, 0                                   ; FC3496  ld H,0x00
	ldb	c, 68                                  ; FC3498  ld C,0x44
	extpfx3 0x8E, 0x0A, 0x43                   ; FC349A  mul BC,(XIZ+0x0a)
	inc	6, bc                                  ; FC349D  inc 6,BC
	extz	xbc                                   ; FC349F  extz XBC
	ld	de, (xbc+0x3BCF)                        ; FC34A1  ld DE,(XBC+0x3bcf)
	ld	bc, de                                  ; FC34A6  ld BC,DE
	srl	bc, 8                                  ; FC34A8  srl 0x08,BC
	ld	de, bc                                  ; FC34AB  ld DE,BC
	sub	bc, 12                                 ; FC34AD  sub BC,0x000c
	ld	de, bc                                  ; FC34B1  ld DE,BC
	jr sub_FC3480__FC34BC                      ; FC34B3  jr T,0xfc34bc
sub_FC3480__FC34B5:
	ldw	bc, 12                                 ; FC34B5  ld BC,0x000c
	sub	de, bc                                 ; FC34B8  sub DE,BC
	inc	1, h                                   ; FC34BA  inc 1,H
sub_FC3480__FC34BC:
	cp	de, 84                                  ; FC34BC  cp DE,0x0054
	jr nc, sub_FC3480__FC34B5                  ; FC34C0  jr NC,0xfc34b5
	cps	h, 0                                   ; FC34C2  cp H,0
	jr nz, sub_FC3480__FC34D4                  ; FC34C4  jr NZ,0xfc34d4
	ldb	c, 2                                   ; FC34C6  ld C,0x02
	extpfx3 0x8E, 0x0C, 0x43                   ; FC34C8  mul BC,(XIZ+0x0c)
	extz	xbc                                   ; FC34CB  extz XBC
	add	xbc, xix                               ; FC34CD  add XBC,XIX
	ld	wa, (xbc)                               ; FC34CF  ld WA,(XBC)
	jrl sub_FC3480__FC3555                     ; FC34D1  jrl T,0xfc3555
sub_FC3480__FC34D4:
	cps	h, 1                                   ; FC34D4  cp H,1
	jr nz, sub_FC3480__FC3518                  ; FC34D6  jr NZ,0xfc3518
	ldb	c, 2                                   ; FC34D8  ld C,0x02
	extpfx3 0x8E, 0x0C, 0x43                   ; FC34DA  mul BC,(XIZ+0x0c)
	extz	xbc                                   ; FC34DD  extz XBC
	add	xbc, xix                               ; FC34DF  add XBC,XIX
	ld	wa, (xbc)                               ; FC34E1  ld WA,(XBC)
	ld	(xiz-2), wa                             ; FC34E3  ld (XIZ+0xfe),WA
	ld	de, wa                                  ; FC34E6  ld DE,WA
	and	de, 0xFF                               ; FC34E8  and DE,0x00ff
	srl	wa, 4                                  ; FC34EC  srl 0x04,WA
	and	wa, 15                                 ; FC34EF  and WA,0x000f
	ld	(xiz-4), wa                             ; FC34F3  ld (XIZ+0xfc),WA
	ld	hl, (xiz-2)                             ; FC34F6  ld HL,(XIZ+0xfe)
	srl	hl, 8                                  ; FC34F9  srl 0x08,HL
	and	hl, 15                                 ; FC34FC  and HL,0x000f
	ld	bc, (xiz-4)                             ; FC3500  ld BC,(XIZ+0xfc)
	cp	bc, hl                                  ; FC3503  cp BC,HL
	jr nc, sub_FC3480__FC3553                  ; FC3505  jr NC,0xfc3553
	ld	ix, hl                                  ; FC3507  ld IX,HL
	sll	ix, 4                                  ; FC3509  sll 0x04,IX
	ld	bc, de                                  ; FC350C  ld BC,DE
	and	bc, 15                                 ; FC350E  and BC,0x000f
	or	bc, ix                                  ; FC3512  or BC,IX
	ld	wa, bc                                  ; FC3514  ld WA,BC
	jr sub_FC3480__FC3555                      ; FC3516  jr T,0xfc3555
sub_FC3480__FC3518:
	ldb	c, 2                                   ; FC3518  ld C,0x02
	extpfx3 0x8E, 0x0C, 0x43                   ; FC351A  mul BC,(XIZ+0x0c)
	extz	xbc                                   ; FC351D  extz XBC
	add	xbc, xix                               ; FC351F  add XBC,XIX
	ld	wa, (xbc)                               ; FC3521  ld WA,(XBC)
	ld	(xiz-2), wa                             ; FC3523  ld (XIZ+0xfe),WA
	ld	de, wa                                  ; FC3526  ld DE,WA
	and	de, 15                                 ; FC3528  and DE,0x000f
	ld	ix, wa                                  ; FC352C  ld IX,WA
	srl	ix, 4                                  ; FC352E  srl 0x04,IX
	and	ix, 15                                 ; FC3531  and IX,0x000f
	ld	hl, (xiz-2)                             ; FC3535  ld HL,(XIZ+0xfe)
	srl	hl, 8                                  ; FC3538  srl 0x08,HL
	and	hl, 15                                 ; FC353B  and HL,0x000f
	cp	de, ix                                  ; FC353F  cp DE,IX
	jr nc, sub_FC3480__FC354B                  ; FC3541  jr NC,0xfc354b
	cp	ix, hl                                  ; FC3543  cp IX,HL
	jr c, sub_FC3480__FC354F                   ; FC3545  jr C,0xfc354f
	ld	wa, ix                                  ; FC3547  ld WA,IX
	jr sub_FC3480__FC3555                      ; FC3549  jr T,0xfc3555
sub_FC3480__FC354B:
	cp	de, hl                                  ; FC354B  cp DE,HL
	jr nc, sub_FC3480__FC3553                  ; FC354D  jr NC,0xfc3553
sub_FC3480__FC354F:
	ld	wa, hl                                  ; FC354F  ld WA,HL
	jr sub_FC3480__FC3555                      ; FC3551  jr T,0xfc3555
sub_FC3480__FC3553:
	ld	wa, de                                  ; FC3553  ld WA,DE
sub_FC3480__FC3555:
	pop	xix                                    ; FC3555  pop XIX
	popw	de                                    ; FC3556  pop DE
	popw	hl                                    ; FC3557  pop HL
	unlk32 xiz                                 ; FC3558  unlk XIZ
	ret                                        ; FC355A  ret
; --------------------------------------------------------------------------
; sub_FC355B -- 0xFC355B..0xFC3594 (58 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFA82BE in Voice_StageRegs_0040_B__FA82BB
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFC355B-0xFC3594
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC355B:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC355B  link XIZ,0x0000
	pushw	hl                                   ; FC355F  push HL
	pushw	de                                   ; FC3560  push DE
	pushw	ix                                   ; FC3561  push IX
	ld	hl, (xiz+8)                             ; FC3562  ld HL,(XIZ+0x08)
	ld	bc, hl                                  ; FC3565  ld BC,HL
	srl	bc, 8                                  ; FC3567  srl 0x08,BC
	and	bc, 15                                 ; FC356A  and BC,0x000f
	mul	bc, 81                                 ; FC356E  mul BC,0x0051
	ld	de, bc                                  ; FC3572  ld DE,BC
	ld	iy, hl                                  ; FC3574  ld IY,HL
	srl	iy, 4                                  ; FC3576  srl 0x04,IY
	and	iy, 15                                 ; FC3579  and IY,0x000f
	mul	iy, 9                                  ; FC357D  mul IY,0x0009
	ld	ix, bc                                  ; FC3581  ld IX,BC
	add	ix, iy                                 ; FC3583  add IX,IY
	ld	bc, hl                                  ; FC3585  ld BC,HL
	and	bc, 15                                 ; FC3587  and BC,0x000f
	add	bc, ix                                 ; FC358B  add BC,IX
	ld	wa, bc                                  ; FC358D  ld WA,BC
	popw	ix                                    ; FC358F  pop IX
	popw	de                                    ; FC3590  pop DE
	popw	hl                                    ; FC3591  pop HL
	unlk32 xiz                                 ; FC3592  unlk XIZ
	ret                                        ; FC3594  ret
; --------------------------------------------------------------------------
; SlotRec_AddToArgField_000C -- 0xFC3595..0xFC35B7 (35 bytes)
;             (* NAMED in wave 7 round 12; was `sub_FC3595`.)
;
; Called from: 1 site(s) outside this module:
;          0xFB1F75 in VoiceRegs_Stage_B
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Voice record: touches voice_record[+0x00(r), +0x0D(rw)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFC3595-0xFC35B7
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; * WHAT IT DOES: adds the WORD at offset +0x0C of the slot record into the argument record's own
;   word +0x0D.
; Evidence: `ld C,(XHL)` at 0xFC359F takes the SLOT from byte +0 of the argument
;          record, `mul C,0x04` at 0xFC35A1 scales it and `add XBC,0x0000df05` at 0xFC35A6
;          reaches the 4-byte pointer table; `ld XBC,(XBC)` at 0xFC35AC dereferences it.
;          0x00DF05 is the slot pointer table PartSlot_SetRecordPtr_DF05 (0xFC376C)
;          fills, one 32-bit pointer per slot, each pointing into the 23-byte record
;          array based at 0x0000DC0E -- both strides are that routine's `mul r,imm`
;          operands.  The read and the accumulate are `ld WA,(XBC+0x0c)` 0xFC35AE and
;          `add (XHL+0x0d),WA` 0xFC35B1 -- a read-modify-write on the ARGUMENT, not
;          on the slot record.
; Unknown:  what the field holds.  The suffix is the field OFFSET, an instruction
;          operand with no referent outside the code, so this name is a FRAME and
;          not a content name -- see notes/prom_c_finish_round12.py --inventory.
; --------------------------------------------------------------------------
SlotRec_AddToArgField_000C:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC3595  link XIZ,0x0000
	push	xhl                                   ; FC3599  push XHL
	ld	hl, (xiz+8)                             ; FC359A  ld HL,(XIZ+0x08)
	extz	xhl                                   ; FC359D  extz XHL
	ld	c, (xhl)                                ; FC359F  ld C,(XHL)
	mul	c, 4                                   ; FC35A1  mul C,0x04
	extz	xbc                                   ; FC35A4  extz XBC
	add	xbc, 0xDF05                            ; FC35A6  add XBC,0x0000df05
	ld	xbc, (xbc)                              ; FC35AC  ld XBC,(XBC)
	ld	wa, (xbc+12)                            ; FC35AE  ld WA,(XBC+0x0c)
	add	(xhl+13), wa                           ; FC35B1  add (XHL+0x0d),WA
	pop	xhl                                    ; FC35B4  pop XHL
	unlk32 xiz                                 ; FC35B5  unlk XIZ
	ret                                        ; FC35B7  ret
; --------------------------------------------------------------------------
; SlotRec_AddToArgField_000E -- 0xFC35B8..0xFC35DA (35 bytes)
;             (* NAMED in wave 7 round 12; was `sub_FC35B8`.)
;
; Called from: 1 site(s) outside this module:
;          0xFB2F55 in VoiceRegs_Stage_D
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Voice record: touches voice_record[+0x00(r), +0x0D(rw)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFC35B8-0xFC35DA
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; * WHAT IT DOES: adds the WORD at offset +0x0E of the slot record into the argument record's own
;   word +0x0D.
; Evidence: `ld C,(XHL)` at 0xFC35C2 takes the SLOT from byte +0 of the argument
;          record, `mul C,0x04` at 0xFC35C4 scales it and `add XBC,0x0000df05` at 0xFC35C9
;          reaches the 4-byte pointer table; `ld XBC,(XBC)` at 0xFC35CF dereferences it.
;          0x00DF05 is the slot pointer table PartSlot_SetRecordPtr_DF05 (0xFC376C)
;          fills, one 32-bit pointer per slot, each pointing into the 23-byte record
;          array based at 0x0000DC0E -- both strides are that routine's `mul r,imm`
;          operands.  `ld WA,(XBC+0x0e)` 0xFC35D1 and `add (XHL+0x0d),WA` 0xFC35D4.  Same 35 bytes as
;          SlotRec_AddToArgField_000C with the one offset changed.
; Unknown:  what the field holds.  The suffix is the field OFFSET, an instruction
;          operand with no referent outside the code, so this name is a FRAME and
;          not a content name -- see notes/prom_c_finish_round12.py --inventory.
; --------------------------------------------------------------------------
SlotRec_AddToArgField_000E:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC35B8  link XIZ,0x0000
	push	xhl                                   ; FC35BC  push XHL
	ld	hl, (xiz+8)                             ; FC35BD  ld HL,(XIZ+0x08)
	extz	xhl                                   ; FC35C0  extz XHL
	ld	c, (xhl)                                ; FC35C2  ld C,(XHL)
	mul	c, 4                                   ; FC35C4  mul C,0x04
	extz	xbc                                   ; FC35C7  extz XBC
	add	xbc, 0xDF05                            ; FC35C9  add XBC,0x0000df05
	ld	xbc, (xbc)                              ; FC35CF  ld XBC,(XBC)
	ld	wa, (xbc+14)                            ; FC35D1  ld WA,(XBC+0x0e)
	add	(xhl+13), wa                           ; FC35D4  add (XHL+0x0d),WA
	pop	xhl                                    ; FC35D7  pop XHL
	unlk32 xiz                                 ; FC35D8  unlk XIZ
	ret                                        ; FC35DA  ret
; --------------------------------------------------------------------------
; sub_FC35DB -- 0xFC35DB..0xFC369E (196 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFB1F8D in VoiceRegs_Stage_B__FB1F7B
; Inputs:  frame `link XIZ,-6`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
;          reads 0x00F2F3
; Calls:   0xFCB11B = Multiply32
; Voice record: touches voice_record[+0x00(r), +0x0D(rw), +0x17(r)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFC35DB-0xFC369E
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC35DB:
	link32 0xEE, 0x0C, 0xFA, 0xFF              ; FC35DB  link XIZ,0xfffa
	pushw	hl                                   ; FC35DF  push HL
	push	xde                                   ; FC35E0  push XDE
	push	xix                                   ; FC35E1  push XIX
	ld	de, (xiz+8)                             ; FC35E2  ld DE,(XIZ+0x08)
	extz	xde                                   ; FC35E5  extz XDE
	ld	c, (xde)                                ; FC35E7  ld C,(XDE)
	mul	c, 4                                   ; FC35E9  mul C,0x04
	extz	xbc                                   ; FC35EC  extz XBC
	add	xbc, 0xDF05                            ; FC35EE  add XBC,0x0000df05
	ld	xbc, (xbc)                              ; FC35F4  ld XBC,(XBC)
	ld	xix, xbc                                ; FC35F6  ld XIX,XBC
	ld	a, (xbc+8)                              ; FC35F8  ld A,(XBC+0x08)
	exts	wa                                    ; FC35FB  exts WA
	add	(xde+13), wa                           ; FC35FD  add (XDE+0x0d),WA
	extpfx3 0xBC, 0x16, 0xCF                   ; FC3600  bit 7,(XIX+0x16)
	jr z, sub_FC35DB__FC3614                   ; FC3603  jr Z,0xfc3614
	ei	6                                       ; FC3605  ei 0x06
	ld	xbc, (0xF2F3:24)                       ; FC3607  ld XBC,(0x00f2f3)
	ld	(xix+18), xbc                           ; FC360C  ld (XIX+0x12),XBC
	ei	0                                       ; FC360F  ei 0x00
	jrl sub_FC35DB__FC3699                     ; FC3611  jrl T,0xfc3699
sub_FC35DB__FC3614:
	ei	6                                       ; FC3614  ei 0x06
	ld	xbc, (xix+18)                           ; FC3616  ld XBC,(XIX+0x12)
	ld	xwa, (0xF2F3:24)                       ; FC3619  ld XWA,(0x00f2f3)
	sub	xwa, xbc                               ; FC361E  sub XWA,XBC
	ld	(xiz-4), xwa                            ; FC3620  ld (XIZ+0xfc),XWA
	ei	0                                       ; FC3623  ei 0x00
	ld	xbc, (xiz-4)                            ; FC3625  ld XBC,(XIZ+0xfc)
	cp	xbc, 0x7FFF                             ; FC3628  cp XBC,0x00007fff
	jr ule, sub_FC35DB__FC3638                 ; FC362E  jr ULE,0xfc3638
	ld	xwa, 0x7FFF                             ; FC3630  ld XWA,0x00007fff
	ld	(xiz-4), xwa                            ; FC3635  ld (XIZ+0xfc),XWA
sub_FC35DB__FC3638:
	extz	xde                                   ; FC3638  extz XDE
	ld	xbc, (xde+23)                           ; FC363A  ld XBC,(XDE+0x17)
	ld	a, (xbc+41)                             ; FC363D  ld A,(XBC+0x29)
	extz	wa                                    ; FC3640  extz WA
	ld	(xiz-6), wa                             ; FC3642  ld (XIZ+0xfa),WA
	ld	c, (xix+9)                              ; FC3645  ld C,(XIX+0x09)
	exts	bc                                    ; FC3648  exts BC
	ld	hl, wa                                  ; FC364A  ld HL,WA
	add	hl, bc                                 ; FC364C  add HL,BC
	cp	hl, 0x64                                ; FC364E  cp HL,0x0064
	jr le, sub_FC35DB__FC3657                  ; FC3652  jr LE,0xfc3657
	ldw	hl, 0x64                               ; FC3654  ld HL,0x0064
sub_FC35DB__FC3657:
	cps	hl, 0                                  ; FC3657  cp HL,0
	jr ge, sub_FC35DB__FC365E                  ; FC3659  jr GE,0xfc365e
	ldw	hl, 0                                  ; FC365B  ld HL,0x0000
sub_FC35DB__FC365E:
	ldw	bc, 2                                  ; FC365E  ld BC,0x0002
	muls	xbc, xhl                              ; FC3661  muls XBC,HL
	add	xbc, 0xFE13D6                          ; FC3663  add XBC,0x00fe13d6
	ld	bc, (xbc)                               ; FC3669  ld BC,(XBC)
	extz	xbc                                   ; FC366B  extz XBC
	ld	xix, xbc                                ; FC366D  ld XIX,XBC
	extpfx3 0x9E, 0xFE, 0x04                   ; FC366F  pushw (XIZ+0xfe)
	extpfx3 0x9E, 0xFC, 0x04                   ; FC3672  pushw (XIZ+0xfc)
	push	xbc                                   ; FC3675  push XBC
	call	0xFCB11B                              ; FC3676  call 0xfcb11b
	ld	xix, xiy                                ; FC367A  ld XIX,XIY
	srl	xiy, 10                                ; FC367C  srl 0x0a,XIY
	ld	xix, xiy                                ; FC367F  ld XIX,XIY
	cp	xiy, 0xFFF                              ; FC3681  cp XIY,0x00000fff
	jr ule, sub_FC35DB__FC3692                 ; FC3687  jr ULE,0xfc3692
	extz	xde                                   ; FC3689  extz XDE
	extpfx5 0xBA, 0x0D, 0x02, 0x00, 0xC0       ; FC368B  ld (XDE+0x0d),0xc000
	jr sub_FC35DB__FC3699                      ; FC3690  jr T,0xfc3699
sub_FC35DB__FC3692:
	ld	bc, ix                                  ; FC3692  ld BC,IX
	extz	xde                                   ; FC3694  extz XDE
	sub	(xde+13), bc                           ; FC3696  sub (XDE+0x0d),BC
sub_FC35DB__FC3699:
	pop	xix                                    ; FC3699  pop XIX
	pop	xde                                    ; FC369A  pop XDE
	popw	hl                                    ; FC369B  pop HL
	unlk32 xiz                                 ; FC369C  unlk XIZ
	ret                                        ; FC369E  ret
; --------------------------------------------------------------------------
; Word_AddTickLow3 -- 0xFC369F..0xFC36BD (31 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFB2EF5 in VoiceRegs_Stage_D
; Inputs:  frame `link XIZ,-2`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
;          reads 0x00F2F3
; Evidence: the listing below is the byte-identical round-trip of 0xFC369F-0xFC36BD
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ WHAT IT DOES: `*(u16 *)arg += (u16)((0x00F2F3) & 7)` -- adds the low three bits of
;          the free-running INTT1 tick counter to the word the pointer argument names.
;          `ld BC,(0x00f2f3) / and BC,0x0007` (0xFC36A5/0xFC36AA) and `add (XBC),WA`
;          (0xFC36B9) are the whole body; the `ei 6` / `ei 0` pair around the read
;          (0xFC36A3, 0xFC36B1) masks the interrupt that writes the counter.
; ★ ITS ONLY CALL SITE MAKES IT A PRODUCER OF REGISTER 0x0040.  VoiceRegs_Stage_D pushes
;          `0x00D75E + 2` (`lda XBC,0x00d75e / inc 2,XBC` at 0xFB2EED/0xFB2EF2), i.e. the
;          address of staging WORD 1, which Dev10C_WriteAllChanRegs sends to register
;          0x0040 + chan.  ⚠ This write is INVISIBLE to notes/prom_c_dev10c_field_sources.py,
;          which only follows stores through a base it can see inside one routine; see
;          notes/prom_c_staging_producer_audit.py.
; Unknown:  what a 0..7 addition to that register does.  Register 0x0040 carries the
;          key-zone record's word 0 (see Voice_SelectKeyZone_Reg0040), whose bits 11..0
;          are a payload -- so this jitters the payload's low three bits on the D path
;          only.  Nothing here says what the payload is, so nothing here says what the
;          jitter changes.
; --------------------------------------------------------------------------
Word_AddTickLow3:
	link32 0xEE, 0x0C, 0xFE, 0xFF              ; FC369F  link XIZ,0xfffe
	ei	6                                       ; FC36A3  ei 0x06
	ld	bc, (0xF2F3:24)                        ; FC36A5  ld BC,(0x00f2f3)
	and	bc, 7                                  ; FC36AA  and BC,0x0007
	ld	(xiz-2), bc                             ; FC36AE  ld (XIZ+0xfe),BC
	ei	0                                       ; FC36B1  ei 0x00
	ld	xbc, (xiz+8)                            ; FC36B3  ld XBC,(XIZ+0x08)
	ld	wa, (xiz-2)                             ; FC36B6  ld WA,(XIZ+0xfe)
	add	(xbc), wa                              ; FC36B9  add (XBC),WA
	unlk32 xiz                                 ; FC36BB  unlk XIZ
	ret                                        ; FC36BD  ret
; --------------------------------------------------------------------------
; sub_FC36BE -- 0xFC36BE..0xFC376B (174 bytes)
;
; Called from: 3 site(s) outside this module:
;          0xFB30EE in sub_FB2F74, 0xFB3327 in VoiceParams_Compute_D
;          0xFB3528 in VoiceParams_Compute_D__FB33CE
; Inputs:  frame `link XIZ,-10`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
;          reads 0x001505
; Calls:   0xFA73EB = sub_FA73EB, 0xFA7570 = Sat16_0_to_7FFF
; Evidence: the listing below is the byte-identical round-trip of 0xFC36BE-0xFC376B
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC36BE:
	link32 0xEE, 0x0C, 0xF6, 0xFF              ; FC36BE  link XIZ,0xfff6
	push	xhl                                   ; FC36C2  push XHL
	pushw	de                                   ; FC36C3  push DE
	push	xix                                   ; FC36C4  push XIX
	ld	hl, (xiz+8)                             ; FC36C5  ld HL,(XIZ+0x08)
	extz	xhl                                   ; FC36C8  extz XHL
	ld	xbc, (xhl+23)                           ; FC36CA  ld XBC,(XHL+0x17)
	ld	xix, xbc                                ; FC36CD  ld XIX,XBC
	ld	xwa, (xhl+31)                           ; FC36CF  ld XWA,(XHL+0x1f)
	ld	(xiz-4), xwa                            ; FC36D2  ld (XIZ+0xfc),XWA
	ld	c, (xhl+5)                              ; FC36D5  ld C,(XHL+0x05)
	extz	bc                                    ; FC36D8  extz BC
	res	7, bc                                  ; FC36DA  res 0x07,BC
	sll	bc, 8                                  ; FC36DD  sll 0x08,BC
	ld	de, bc                                  ; FC36E0  ld DE,BC
	add	de, 0x80                               ; FC36E2  add DE,0x0080
	ld	c, (xhl)                                ; FC36E6  ld C,(XHL)
	mul	c, 4                                   ; FC36E8  mul C,0x04
	extz	xbc                                   ; FC36EB  extz XBC
	add	xbc, 0xDF05                            ; FC36ED  add XBC,0x0000df05
	ld	xbc, (xbc)                              ; FC36F3  ld XBC,(XBC)
	ld	wa, (xbc+16)                            ; FC36F5  ld WA,(XBC+0x10)
	add	wa, de                                 ; FC36F8  add WA,DE
	ld	(xiz-6), wa                             ; FC36FA  ld (XIZ+0xfa),WA
	ld	bc, (0x1505:16)                       ; FC36FD  ld BC,(0x1505)
	ld	de, wa                                  ; FC3701  ld DE,WA
	add	de, bc                                 ; FC3703  add DE,BC
	ld	bc, (xhl+35)                            ; FC3705  ld BC,(XHL+0x23)
	extz	xbc                                   ; FC3708  extz XBC
	ld	a, (xbc+21)                             ; FC370A  ld A,(XBC+0x15)
	exts	wa                                    ; FC370D  exts WA
	sll	wa, 8                                  ; FC370F  sll 0x08,WA
	add	wa, de                                 ; FC3712  add WA,DE
	ld	(xiz-8), wa                             ; FC3714  ld (XIZ+0xf8),WA
	pushw	wa                                   ; FC3717  push WA
	call	0xFA7570                              ; FC3718  call 0xfa7570
	ld	(xhl+8), wa                             ; FC371C  ld (XHL+0x08),WA
	ld	xbc, (xiz-4)                            ; FC371F  ld XBC,(XIZ+0xfc)
	ld	a, (xbc+11)                             ; FC3722  ld A,(XBC+0x0b)
	extz	wa                                    ; FC3725  extz WA
	sll	wa, 8                                  ; FC3727  sll 0x08,WA
	add	wa, 0x80                               ; FC372A  add WA,0x0080
	ld	de, (xiz-8)                             ; FC372E  ld DE,(XIZ+0xf8)
	sub	de, wa                                 ; FC3731  sub DE,WA
	ld	wa, (xbc+12)                            ; FC3733  ld WA,(XBC+0x0c)
	add	wa, de                                 ; FC3736  add WA,DE
	ld	(xiz-10), wa                            ; FC3738  ld (XIZ+0xf6),WA
	ld	c, (xix+4)                              ; FC373B  ld C,(XIX+0x04)
	exts	bc                                    ; FC373E  exts BC
	sll	bc, 8                                  ; FC3740  sll 0x08,BC
	ld	de, bc                                  ; FC3743  ld DE,BC
	extpfx3 0x9E, 0xF6, 0x82                   ; FC3745  add DE,(XIZ+0xf6)
	ld	c, (xix+5)                              ; FC3748  ld C,(XIX+0x05)
	exts	bc                                    ; FC374B  exts BC
	ld	ix, bc                                  ; FC374D  ld IX,BC
	add	ix, de                                 ; FC374F  add IX,DE
	ld	xbc, (xiz-4)                            ; FC3751  ld XBC,(XIZ+0xfc)
	ld	a, (xbc+10)                             ; FC3754  ld A,(XBC+0x0a)
	pushw	wa                                   ; FC3757  push WA
	ld	a, (xbc+9)                              ; FC3758  ld A,(XBC+0x09)
	pushw	wa                                   ; FC375B  push WA
	pushw	ix                                   ; FC375C  push IX
	call	0xFA73EB                              ; FC375D  call 0xfa73eb
	ld	(xhl+6), wa                             ; FC3761  ld (XHL+0x06),WA
	inc	8, xsp                                 ; FC3764  inc 0,XSP
	pop	xix                                    ; FC3766  pop XIX
	popw	de                                    ; FC3767  pop DE
	pop	xhl                                    ; FC3768  pop XHL
	unlk32 xiz                                 ; FC3769  unlk XIZ
	ret                                        ; FC376B  ret
; --------------------------------------------------------------------------
; PartSlot_SetRecordPtr_DF05 -- 0xFC376C..0xFC3792 (39 bytes)
;
; Called from: 4 site(s) outside this module:
;          0xFB1DFE in VoiceParams_Compute_A__FB1DB9, 0xFB27D4 in VoiceParams_Compute_B__FB2793
;          0xFB2E9D in VoiceParams_Compute_C__FB2E5C, 0xFB3626 in VoiceParams_Compute_D__FB35B7
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFC376C-0xFC3792
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ WHAT IT DOES: `slotptr[arg1] = &record[arg0]`, over two RAM arrays whose strides are
;   both instruction immediates:
;     0xFC3771  ld C,0x17 / mul BC,(XIZ+0x08)    23-byte records
;     0xFC377A  add XIX,0x0000DC0E               the record array's base
;     0xFC3780  ld C,0x04 / mul BC,(XIZ+0x0a)    4-byte slots, i.e. 32-bit pointers
;     0xFC3787  add XBC,0x0000DF05               the pointer table's base
;     0xFC378D  ld (XBC),XIX                     the store
; Evidence: the five constants are `mul r,imm` and `add rr,imm32` operands and are checked
;          against the routine's 39 ROM bytes by `--claims C8`.  RAM 0x0000DC0E is named on
;          32 addressed lines of prom_c and 0x0000DF05 on 9, all at these two strides
;          (`--claims C11`).
; Unknown:  ⚠ what a 23-byte record holds, and what indexes the pointer table.  All four
;          callers are VoiceParams_Compute_A..D, so arg1 is plausibly a slot within a
;          part -- PLAUSIBLY.  Nothing here reads either field.
; --------------------------------------------------------------------------
PartSlot_SetRecordPtr_DF05:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC376C  link XIZ,0x0000
	push	xix                                   ; FC3770  push XIX
	ldb	c, 23                                  ; FC3771  ld C,0x17
	extpfx3 0x8E, 0x08, 0x43                   ; FC3773  mul BC,(XIZ+0x08)
	extz	xbc                                   ; FC3776  extz XBC
	ld	xix, xbc                                ; FC3778  ld XIX,XBC
	add	xix, 0xDC0E                            ; FC377A  add XIX,0x0000dc0e
	ldb	c, 4                                   ; FC3780  ld C,0x04
	extpfx3 0x8E, 0x0A, 0x43                   ; FC3782  mul BC,(XIZ+0x0a)
	extz	xbc                                   ; FC3785  extz XBC
	add	xbc, 0xDF05                            ; FC3787  add XBC,0x0000df05
	ld	(xbc), xix                              ; FC378D  ld (XBC),XIX
	pop	xix                                    ; FC378F  pop XIX
	unlk32 xiz                                 ; FC3790  unlk XIZ
	ret                                        ; FC3792  ret
; --------------------------------------------------------------------------
; SlotRec_ReadWordAtArgIndex_0003 -- 0xFC3793..0xFC37BD (43 bytes)
;             (* NAMED in wave 7 round 12; was `sub_FC3793`.)
;
; Called from: 1 site(s) outside this module:
;          0xFA82CC in Voice_StageRegs_0040_B__FA82CB
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Voice record: touches voice_record[+0x00(r), +0x03(r)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFC3793-0xFC37BD
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; * WHAT IT DOES: returns the WORD at 2 * (argument byte +0x03) inside the slot record.
; Evidence: `ld A,(XBC)` at 0xFC37A7 takes the SLOT from byte +0 of the argument
;          record, `mul A,0x04` at 0xFC37A9 scales it and `add XWA,0x0000df05` at 0xFC37AE
;          reaches the 4-byte pointer table; `ld XBC,(XWA)` at 0xFC37B4 dereferences it.
;          0x00DF05 is the slot pointer table PartSlot_SetRecordPtr_DF05 (0xFC376C)
;          fills, one 32-bit pointer per slot, each pointing into the 23-byte record
;          array based at 0x0000DC0E -- both strides are that routine's `mul r,imm`
;          operands.  The index is `ld A,(XBC+0x03)` 0xFC379D and `mul A,0x02` 0xFC37A0; the fetch is
;          `add XBC,XIX` 0xFC37B6 then `ld WA,(XBC)` 0xFC37B8.  So the record is being
;          read as an ARRAY OF WORDS here, and as fixed byte fields by the five
;          SlotRec_Read*/Add* routines above -- both readings are instruction operands
;          and neither is reconciled with the other.
; Unknown:  what the field holds.  The suffix is the field OFFSET, an instruction
;          operand with no referent outside the code, so this name is a FRAME and
;          not a content name -- see notes/prom_c_finish_round12.py --inventory.
; --------------------------------------------------------------------------
SlotRec_ReadWordAtArgIndex_0003:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC3793  link XIZ,0x0000
	push	xix                                   ; FC3797  push XIX
	ld	bc, (xiz+8)                             ; FC3798  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FC379B  extz XBC
	ld	a, (xbc+3)                              ; FC379D  ld A,(XBC+0x03)
	mul	a, 2                                   ; FC37A0  mul A,0x02
	extz	xwa                                   ; FC37A3  extz XWA
	ld	xix, xwa                                ; FC37A5  ld XIX,XWA
	ld	a, (xbc)                                ; FC37A7  ld A,(XBC)
	mul	a, 4                                   ; FC37A9  mul A,0x04
	extz	xwa                                   ; FC37AC  extz XWA
	add	xwa, 0xDF05                            ; FC37AE  add XWA,0x0000df05
	ld	xbc, (xwa)                              ; FC37B4  ld XBC,(XWA)
	add	xbc, xix                               ; FC37B6  add XBC,XIX
	ld	wa, (xbc)                               ; FC37B8  ld WA,(XBC)
	pop	xix                                    ; FC37BA  pop XIX
	unlk32 xiz                                 ; FC37BB  unlk XIZ
	ret                                        ; FC37BD  ret
; --------------------------------------------------------------------------
; SlotRec_ReadSignedByte_0009 -- 0xFC37BE..0xFC37E1 (36 bytes)
;             (* NAMED in wave 7 round 12; was `sub_FC37BE`.)
;
; Called from: 2 site(s) outside this module:
;          0xFAB24F in Voice_StageRegs_0800_B_ModeGe3__FAB20E, 0xFAB273 in Voice_StageRegs_0800_B_ModeGe3__FAB20E
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFC37BE-0xFC37E1
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; * WHAT IT DOES: returns the byte at offset +0x09 of the slot record, sign-extended to 16 bits.
; Evidence: `ld A,(XBC)` at 0xFC37C7 takes the SLOT from byte +0 of the argument
;          record, `mul A,0x04` at 0xFC37C9 scales it and `add XWA,0x0000df05` at 0xFC37CE
;          reaches the 4-byte pointer table; `ld XBC,(XWA)` at 0xFC37D4 dereferences it.
;          0x00DF05 is the slot pointer table PartSlot_SetRecordPtr_DF05 (0xFC376C)
;          fills, one 32-bit pointer per slot, each pointing into the 23-byte record
;          array based at 0x0000DC0E -- both strides are that routine's `mul r,imm`
;          operands.  The field read and its widening are `ld W,(XBC+0x09)` 0xFC37D6, `ld C,W` 0xFC37D9
;          and `exts BC` 0xFC37DB.
; Unknown:  what the field holds.  The suffix is the field OFFSET, an instruction
;          operand with no referent outside the code, so this name is a FRAME and
;          not a content name -- see notes/prom_c_finish_round12.py --inventory.
; --------------------------------------------------------------------------
SlotRec_ReadSignedByte_0009:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC37BE  link XIZ,0x0000
	ld	bc, (xiz+8)                             ; FC37C2  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FC37C5  extz XBC
	ld	a, (xbc)                                ; FC37C7  ld A,(XBC)
	mul	a, 4                                   ; FC37C9  mul A,0x04
	extz	xwa                                   ; FC37CC  extz XWA
	add	xwa, 0xDF05                            ; FC37CE  add XWA,0x0000df05
	ld	xbc, (xwa)                              ; FC37D4  ld XBC,(XWA)
	ld	w, (xbc+9)                              ; FC37D6  ld W,(XBC+0x09)
	ld	c, w                                    ; FC37D9  ld C,W
	exts	bc                                    ; FC37DB  exts BC
	ld	wa, bc                                  ; FC37DD  ld WA,BC
	unlk32 xiz                                 ; FC37DF  unlk XIZ
	ret                                        ; FC37E1  ret
; --------------------------------------------------------------------------
; SlotRec_ReadSignedByte_000A -- 0xFC37E2..0xFC3805 (36 bytes)
;             (* NAMED in wave 7 round 12; was `sub_FC37E2`.)
;
; Called from: 1 site(s) outside this module:
;          0xFAAD3E in Voice_StageRegs_0800_B_ModeLt3__FAAD3B
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFC37E2-0xFC3805
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; * WHAT IT DOES: returns the byte at offset +0x0A of the slot record, sign-extended to 16 bits.
; Evidence: `ld A,(XBC)` at 0xFC37EB takes the SLOT from byte +0 of the argument
;          record, `mul A,0x04` at 0xFC37ED scales it and `add XWA,0x0000df05` at 0xFC37F2
;          reaches the 4-byte pointer table; `ld XBC,(XWA)` at 0xFC37F8 dereferences it.
;          0x00DF05 is the slot pointer table PartSlot_SetRecordPtr_DF05 (0xFC376C)
;          fills, one 32-bit pointer per slot, each pointing into the 23-byte record
;          array based at 0x0000DC0E -- both strides are that routine's `mul r,imm`
;          operands.  `ld W,(XBC+0x0a)` 0xFC37FA, `ld C,W` 0xFC37FD, `exts BC` 0xFC37FF.  Byte-for-byte
;          the shape of SlotRec_ReadSignedByte_0009 with a different offset.
; Unknown:  what the field holds.  The suffix is the field OFFSET, an instruction
;          operand with no referent outside the code, so this name is a FRAME and
;          not a content name -- see notes/prom_c_finish_round12.py --inventory.
; --------------------------------------------------------------------------
SlotRec_ReadSignedByte_000A:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC37E2  link XIZ,0x0000
	ld	bc, (xiz+8)                             ; FC37E6  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FC37E9  extz XBC
	ld	a, (xbc)                                ; FC37EB  ld A,(XBC)
	mul	a, 4                                   ; FC37ED  mul A,0x04
	extz	xwa                                   ; FC37F0  extz XWA
	add	xwa, 0xDF05                            ; FC37F2  add XWA,0x0000df05
	ld	xbc, (xwa)                              ; FC37F8  ld XBC,(XWA)
	ld	w, (xbc+10)                             ; FC37FA  ld W,(XBC+0x0a)
	ld	c, w                                    ; FC37FD  ld C,W
	exts	bc                                    ; FC37FF  exts BC
	ld	wa, bc                                  ; FC3801  ld WA,BC
	unlk32 xiz                                 ; FC3803  unlk XIZ
	ret                                        ; FC3805  ret
; --------------------------------------------------------------------------
; SlotRec_ReadSignedByte_000B -- 0xFC3806..0xFC3829 (36 bytes)
;             (* NAMED in wave 7 round 12; was `sub_FC3806`.)
;
; Called from: 1 site(s) outside this module:
;          0xFAB9EB in Dev10C_StageRegs_0800_0840_FAB9D8
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Voice record: touches voice_record[+0x00(r)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFC3806-0xFC3829
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; * WHAT IT DOES: returns the byte at offset +0x0B of the slot record, sign-extended to 16 bits.
; Evidence: `ld A,(XBC)` at 0xFC380F takes the SLOT from byte +0 of the argument
;          record, `mul A,0x04` at 0xFC3811 scales it and `add XWA,0x0000df05` at 0xFC3816
;          reaches the 4-byte pointer table; `ld XBC,(XWA)` at 0xFC381C dereferences it.
;          0x00DF05 is the slot pointer table PartSlot_SetRecordPtr_DF05 (0xFC376C)
;          fills, one 32-bit pointer per slot, each pointing into the 23-byte record
;          array based at 0x0000DC0E -- both strides are that routine's `mul r,imm`
;          operands.  `ld W,(XBC+0x0b)` 0xFC381E, `ld C,W` 0xFC3821, `exts BC` 0xFC3823.
; Unknown:  what the field holds.  The suffix is the field OFFSET, an instruction
;          operand with no referent outside the code, so this name is a FRAME and
;          not a content name -- see notes/prom_c_finish_round12.py --inventory.
; --------------------------------------------------------------------------
SlotRec_ReadSignedByte_000B:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC3806  link XIZ,0x0000
	ld	bc, (xiz+8)                             ; FC380A  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FC380D  extz XBC
	ld	a, (xbc)                                ; FC380F  ld A,(XBC)
	mul	a, 4                                   ; FC3811  mul A,0x04
	extz	xwa                                   ; FC3814  extz XWA
	add	xwa, 0xDF05                            ; FC3816  add XWA,0x0000df05
	ld	xbc, (xwa)                              ; FC381C  ld XBC,(XWA)
	ld	w, (xbc+11)                             ; FC381E  ld W,(XBC+0x0b)
	ld	c, w                                    ; FC3821  ld C,W
	exts	bc                                    ; FC3823  exts BC
	ld	wa, bc                                  ; FC3825  ld WA,BC
	unlk32 xiz                                 ; FC3827  unlk XIZ
	ret                                        ; FC3829  ret
; --------------------------------------------------------------------------
; sub_FC382A -- 0xFC382A..0xFC386B (66 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFB217E in VoiceParams_Compute_B
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFC382A-0xFC386B
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC382A:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC382A  link XIZ,0x0000
	pushw	hl                                   ; FC382E  push HL
	push	xix                                   ; FC382F  push XIX
	ld	bc, (xiz+8)                             ; FC3830  ld BC,(XIZ+0x08)
	extz	bc                                    ; FC3833  extz BC
	mul	bc, 0x12C                              ; FC3835  mul BC,0x012c
	inc	6, bc                                  ; FC3839  inc 6,BC
	extz	xbc                                   ; FC383B  extz XBC
	ld	wa, (xbc+0x1523)                        ; FC383D  ld WA,(XBC+0x1523)
	ld	hl, wa                                  ; FC3842  ld HL,WA
	and	hl, 0x2000                             ; FC3844  and HL,0x2000
	ldb	c, 23                                  ; FC3848  ld C,0x17
	extpfx3 0x8E, 0x08, 0x43                   ; FC384A  mul BC,(XIZ+0x08)
	extz	xbc                                   ; FC384D  extz XBC
	add	xbc, 22                                ; FC384F  add XBC,0x00000016
	ld	xix, xbc                                ; FC3855  ld XIX,XBC
	add	xix, 0xDC0E                            ; FC3857  add XIX,0x0000dc0e
	cps	hl, 0                                  ; FC385D  cp HL,0
	jr z, sub_FC382A__FC3865                   ; FC385F  jr Z,0xfc3865
	extpfx2 0xB4, 0xBF                         ; FC3861  set 7,(XIX)
	jr sub_FC382A__FC3867                      ; FC3863  jr T,0xfc3867
sub_FC382A__FC3865:
	extpfx2 0xB4, 0xB7                         ; FC3865  res 7,(XIX)
sub_FC382A__FC3867:
	pop	xix                                    ; FC3867  pop XIX
	popw	hl                                    ; FC3868  pop HL
	unlk32 xiz                                 ; FC3869  unlk XIZ
	ret                                        ; FC386B  ret
; --------------------------------------------------------------------------
; SoundRam_ClearFourBanks -- 0xFC386C..0xFC39F9 (398 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFBAE75 in sub_FBAC24__FBAE72
;          2 site(s) inside this module:
;          0xFC3A24 0xFC3B4E
; Inputs:  frame `link XIZ,-40`; no positive frame slot is read
; Outputs: no absolute-addressed write.
; Calls:   0xF9A038 = MemCopyWords, 0xFB4124 = ToneDB_ResolveToneRecord
;          0xFC876C = Flash_ReprogramSector, 0xFC89AF = Flash_ReadSectorToBuffer
; Evidence: the listing below is the byte-identical round-trip of 0xFC386C-0xFC39F9
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Name:    ★ IT CLEARS THE FOUR FLASH BANKS THE ROM CALLS "WSA SOUND RAM S0..S3".
;          `ld D,0x04` at 0xFC3899 and `dec 1,D / jrl NZ` at 0xFC39EC bound the
;          loop at four passes; each pass takes the bank base from
;          SoundRam_BankBases (0xFE151F: 0x00E80000, 0x00E90000, 0x00EA0000,
;          0x00EB0000), calls Flash_ReadSectorToBuffer on it, copies sixteen
;          characters of SoundRam_BankName_S<n> -- reached through
;          SoundRam_BankNamePtrs at 0xFE150F -- and sixteen of Str_ClearBanner
;          ("  --(Clear)--   ", 0xFE152F) into the 64 KiB staging buffer at
;          0x00010000, block-copies 0x21D bytes to buffer+0x90 and three 0x51-byte
;          records from buffer+0x169, and calls Flash_ReprogramSector on the same
;          base.
; Evidence: notes/gen_prom_c_tail_tables.py --verify reads the four pointers and
;          the four bases out of the ROM and checks that the pointers ARE the four
;          string addresses and that the strings are "WSA SOUND RAM S0".."S3".
;          The two flash routines are named in this file's own flash-driver block.
;          ★ 0xE80000-0xEBFFFF is 256 KiB -- exactly the span prom_a's
;          Remote_E80000_Read32Blocks fetches over the link (32 blocks of 0x2000).
; Unknown:  ⚠ what the 0x21D-byte and 0x51-byte block copies carry, and what the
;          rest of each bank holds.  The names are the ROM's; "SOUND RAM" for a
;          FLASH bank is the firmware's own word, not a claim about the part.
; --------------------------------------------------------------------------
SoundRam_ClearFourBanks:
	link32 0xEE, 0x0C, 0xD8, 0xFF              ; FC386C  link XIZ,0xffd8
	pushw	hl                                   ; FC3870  push HL
	pushw	de                                   ; FC3871  push DE
	push	xix                                   ; FC3872  push XIX
	ld	xbc, 0x10000                            ; FC3873  ld XBC,0x00010000
	ld	(xiz-28), xbc                           ; FC3878  ld (XIZ+0xe4),XBC
	pushw	0                                    ; FC387B  push 0x0000
	pushw	0                                    ; FC387E  push 0x0000
	call	0xFB4124                              ; FC3881  call 0xfb4124
	ld	(xiz-32), xiy                           ; FC3885  ld (XIZ+0xe0),XIY
	ld	xbc, (xiz-28)                           ; FC3888  ld XBC,(XIZ+0xe4)
	add	xbc, 0xB2D0                            ; FC388B  add XBC,0x0000b2d0
	ld	(xiz-16), xbc                           ; FC3891  ld (XIZ+0xf0),XBC
	sub	xwa, xwa                               ; FC3894  sub XWA,XWA
	ld	(xiz-24), xwa                           ; FC3896  ld (XIZ+0xe8),XWA
	ldb	d, 4                                   ; FC3899  ld D,0x04
	pop	xiy                                    ; FC389B  pop XIY
SoundRam_ClearFourBanks__FC389C:
	ld	xbc, (xiz-24)                           ; FC389C  ld XBC,(XIZ+0xe8)
	ld	(xiz-36), xbc                           ; FC389F  ld (XIZ+0xdc),XBC
	add	xbc, 0xFE151F                          ; FC38A2  add XBC,0x00fe151f
	ld	xbc, (xbc)                              ; FC38A8  ld XBC,(XBC)
	push	xbc                                   ; FC38AA  push XBC
	call	0xFC89AF                              ; FC38AB  call 0xfc89af
	lda	xbc, (0xFE150F:24)                     ; FC38AF  lda XBC,0xfe150f
	extpfx3 0xAE, 0xDC, 0x81                   ; FC38B4  add XBC,(XIZ+0xdc)
	ld	xwa, (xbc)                              ; FC38B7  ld XWA,(XBC)
	ld	xix, xwa                                ; FC38B9  ld XIX,XWA
	ldb	h, 0                                   ; FC38BB  ld H,0x00
	pop	xiy                                    ; FC38BD  pop XIY
SoundRam_ClearFourBanks__FC38BE:
	ld	c, h                                    ; FC38BE  ld C,H
	extz	bc                                    ; FC38C0  extz BC
	extz	xbc                                   ; FC38C2  extz XBC
	ld	(xiz-36), xbc                           ; FC38C4  ld (XIZ+0xdc),XBC
	add	xbc, xix                               ; FC38C7  add XBC,XIX
	ld	a, (xbc)                                ; FC38C9  ld A,(XBC)
	ld	xbc, (xiz-28)                           ; FC38CB  ld XBC,(XIZ+0xe4)
	extpfx3 0xAE, 0xDC, 0x81                   ; FC38CE  add XBC,(XIZ+0xdc)
	ld	(xbc), a                                ; FC38D1  ld (XBC),A
	inc	1, h                                   ; FC38D3  inc 1,H
	cp	h, 16                                   ; FC38D5  cp H,0x10
	jr c, SoundRam_ClearFourBanks__FC38BE                   ; FC38D8  jr C,0xfc38be
	sub	xbc, xbc                               ; FC38DA  sub XBC,XBC
	ld	(xiz-8), xbc                            ; FC38DC  ld (XIZ+0xf8),XBC
	ldb	l, 64                                  ; FC38DF  ld L,0x40
SoundRam_ClearFourBanks__FC38E1:
	pushw	0x21D                                ; FC38E1  push 0x021d
	ld	xix, (xiz-8)                            ; FC38E4  ld XIX,(XIZ+0xf8)
	ld	xbc, xix                                ; FC38E7  ld XBC,XIX
	add	xbc, 0x90                              ; FC38E9  add XBC,0x00000090
	extpfx3 0xAE, 0xE4, 0x81                   ; FC38EF  add XBC,(XIZ+0xe4)
	push	xbc                                   ; FC38F2  push XBC
	ld	xbc, (xiz-32)                           ; FC38F3  ld XBC,(XIZ+0xe0)
	push	xbc                                   ; FC38F6  push XBC
	call	0xF9A038                              ; FC38F7  call 0xf9a038
	ld	xbc, xix                                ; FC38FB  ld XBC,XIX
	add	xbc, 0x169                             ; FC38FD  add XBC,0x00000169
	extpfx3 0xAE, 0xE4, 0x81                   ; FC3903  add XBC,(XIZ+0xe4)
	ld	(xiz-12), xbc                           ; FC3906  ld (XIZ+0xf4),XBC
	ld	(xiz-4), xix                            ; FC3909  ld (XIZ+0xfc),XIX
	ld	xix, 81                                 ; FC390C  ld XIX,0x00000051
	ldb	h, 3                                   ; FC3911  ld H,0x03
	inc	8, xsp                                 ; FC3913  inc 0,XSP
	inc	2, xsp                                 ; FC3915  inc 2,XSP
SoundRam_ClearFourBanks__FC3917:
	pushw	81                                   ; FC3917  push 0x0051
	ld	(xiz-36), xix                           ; FC391A  ld (XIZ+0xdc),XIX
	ld	xbc, (xiz-4)                            ; FC391D  ld XBC,(XIZ+0xfc)
	extpfx3 0xAE, 0xDC, 0x81                   ; FC3920  add XBC,(XIZ+0xdc)
	add	xbc, 0x169                             ; FC3923  add XBC,0x00000169
	extpfx3 0xAE, 0xE4, 0x81                   ; FC3929  add XBC,(XIZ+0xe4)
	push	xbc                                   ; FC392C  push XBC
	ld	xbc, (xiz-12)                           ; FC392D  ld XBC,(XIZ+0xf4)
	push	xbc                                   ; FC3930  push XBC
	call	0xF9A038                              ; FC3931  call 0xf9a038
	ld	xix, (xiz-36)                           ; FC3935  ld XIX,(XIZ+0xdc)
	add	xix, 81                                ; FC3938  add XIX,0x00000051
	dec	1, h                                   ; FC393E  dec 1,H
	inc	8, xsp                                 ; FC3940  inc 0,XSP
	inc	2, xsp                                 ; FC3942  inc 2,XSP
	cps	h, 0                                   ; FC3944  cp H,0
	jr nz, SoundRam_ClearFourBanks__FC3917                  ; FC3946  jr NZ,0xfc3917
	ld	xbc, 0x2C9                              ; FC3948  ld XBC,0x000002c9
	add	(xiz-8), xbc                           ; FC394D  add (XIZ+0xf8),XBC
	dec	1, l                                   ; FC3950  dec 1,L
	cps	l, 0                                   ; FC3952  cp L,0
	jr nz, SoundRam_ClearFourBanks__FC38E1                  ; FC3954  jr NZ,0xfc38e1
	pushw	64                                   ; FC3956  push 0x0040
	pushw	0                                    ; FC3959  push 0x0000
	call	0xFB4124                              ; FC395C  call 0xfb4124
	ld	xix, xiy                                ; FC3960  ld XIX,XIY
	pushw	0x198                                ; FC3962  push 0x0198
	ld	xbc, (xiz-16)                           ; FC3965  ld XBC,(XIZ+0xf0)
	push	xbc                                   ; FC3968  push XBC
	push	xiy                                   ; FC3969  push XIY
	call	0xF9A038                              ; FC396A  call 0xf9a038
	ld	xbc, (xiz-28)                           ; FC396E  ld XBC,(XIZ+0xe4)
	add	xbc, 0xB2D0                            ; FC3971  add XBC,0x0000b2d0
	ld	(xiz-20), xbc                           ; FC3977  ld (XIZ+0xec),XBC
	ld	xix, 0                                  ; FC397A  ld XIX,0x00000000
	ldb	h, 0x80                                ; FC397F  ld H,0x80
	inc	8, xsp                                 ; FC3981  inc 0,XSP
	inc	6, xsp                                 ; FC3983  inc 6,XSP
SoundRam_ClearFourBanks__FC3985:
	ld	(xiz-36), xix                           ; FC3985  ld (XIZ+0xdc),XIX
	ld	xbc, (xiz-36)                           ; FC3988  ld XBC,(XIZ+0xdc)
	ld	(xiz-40), xbc                           ; FC398B  ld (XIZ+0xd8),XBC
	add	xbc, 0x98                              ; FC398E  add XBC,0x00000098
	extpfx3 0xAE, 0xEC, 0x81                   ; FC3994  add XBC,(XIZ+0xec)
	ld	(xbc), 0                                ; FC3997  ld (XBC),0x00
	ld	xbc, (xiz-40)                           ; FC399A  ld XBC,(XIZ+0xd8)
	add	xbc, 0x99                              ; FC399D  add XBC,0x00000099
	extpfx3 0xAE, 0xEC, 0x81                   ; FC39A3  add XBC,(XIZ+0xec)
	ld	(xbc), 64                               ; FC39A6  ld (XBC),0x40
	ld	xix, (xiz-36)                           ; FC39A9  ld XIX,(XIZ+0xdc)
	inc	2, xix                                 ; FC39AC  inc 2,XIX
	dec	1, h                                   ; FC39AE  dec 1,H
	cps	h, 0                                   ; FC39B0  cp H,0
	jr nz, SoundRam_ClearFourBanks__FC3985                  ; FC39B2  jr NZ,0xfc3985
	ldb	h, 0                                   ; FC39B4  ld H,0x00
SoundRam_ClearFourBanks__FC39B6:
	ld	c, h                                    ; FC39B6  ld C,H
	extz	bc                                    ; FC39B8  extz BC
	extz	xbc                                   ; FC39BA  extz XBC
	ld	xix, xbc                                ; FC39BC  ld XIX,XBC
	add	xbc, 0xFE152F                          ; FC39BE  add XBC,0x00fe152f
	ld	a, (xbc)                                ; FC39C4  ld A,(XBC)
	ld	xbc, (xiz-20)                           ; FC39C6  ld XBC,(XIZ+0xec)
	add	xbc, xix                               ; FC39C9  add XBC,XIX
	ld	(xbc), a                                ; FC39CB  ld (XBC),A
	inc	1, h                                   ; FC39CD  inc 1,H
	cp	h, 16                                   ; FC39CF  cp H,0x10
	jr c, SoundRam_ClearFourBanks__FC39B6                   ; FC39D2  jr C,0xfc39b6
	ld	xix, (xiz-24)                           ; FC39D4  ld XIX,(XIZ+0xe8)
	lda	xbc, (0xFE151F:24)                     ; FC39D7  lda XBC,0xfe151f
	add	xbc, xix                               ; FC39DC  add XBC,XIX
	ld	xwa, (xbc)                              ; FC39DE  ld XWA,(XBC)
	push	xwa                                   ; FC39E0  push XWA
	call	0xFC876C                              ; FC39E1  call 0xfc876c
	ld	xbc, xix                                ; FC39E5  ld XBC,XIX
	inc	4, xbc                                 ; FC39E7  inc 4,XBC
	ld	(xiz-24), xbc                           ; FC39E9  ld (XIZ+0xe8),XBC
	dec	1, d                                   ; FC39EC  dec 1,D
	pop	xiy                                    ; FC39EE  pop XIY
	cps	d, 0                                   ; FC39EF  cp D,0
	jrl nz, SoundRam_ClearFourBanks__FC389C                 ; FC39F1  jrl NZ,0xfc389c
	pop	xix                                    ; FC39F4  pop XIX
	popw	de                                    ; FC39F5  pop DE
	popw	hl                                    ; FC39F6  pop HL
	unlk32 xiz                                 ; FC39F7  unlk XIZ
	ret                                        ; FC39F9  ret
; --------------------------------------------------------------------------
; sub_FC39FA -- 0xFC39FA..0xFC3B23 (298 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFC0134 in sub_FBFFD4__FC0129
; Inputs:  frame `link XIZ,-24`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
;          reads 0xFE150F, 0xFE151F
; Calls:   0xF9A038 = MemCopyWords, 0xFC386C = SoundRam_ClearFourBanks
;          0xFC876C = Flash_ReprogramSector, 0xFC89AF = Flash_ReadSectorToBuffer
; Evidence: the listing below is the byte-identical round-trip of 0xFC39FA-0xFC3B23
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC39FA:
	link32 0xEE, 0x0C, 0xE8, 0xFF              ; FC39FA  link XIZ,0xffe8
	pushw	hl                                   ; FC39FE  push HL
	pushw	de                                   ; FC39FF  push DE
	push	xix                                   ; FC3A00  push XIX
	ld	xbc, (0xFE150F:24)                     ; FC3A01  ld XBC,(0xfe150f)
	ld	xix, xbc                                ; FC3A06  ld XIX,XBC
	ldb	h, 0                                   ; FC3A08  ld H,0x00
sub_FC39FA__FC3A0A:
	ld	c, h                                    ; FC3A0A  ld C,H
	extz	bc                                    ; FC3A0C  extz BC
	extz	xbc                                   ; FC3A0E  extz XBC
	ld	(xiz-16), xbc                           ; FC3A10  ld (XIZ+0xf0),XBC
	ld	xwa, (0xFE151F:24)                     ; FC3A13  ld XWA,(0xfe151f)
	add	xwa, xbc                               ; FC3A18  add XWA,XBC
	ld	l, (xwa)                                ; FC3A1A  ld L,(XWA)
	add	xbc, xix                               ; FC3A1C  add XBC,XIX
	ld	w, (xbc)                                ; FC3A1E  ld W,(XBC)
	cp	l, w                                    ; FC3A20  cp L,W
	jr z, sub_FC39FA__FC3A29                   ; FC3A22  jr Z,0xfc3a29
	calr (0xFC386C - 0xFC3A27)                 ; FC3A24  calr 0xfc386c
	jr sub_FC39FA__FC3A30                      ; FC3A27  jr T,0xfc3a30
sub_FC39FA__FC3A29:
	inc	1, h                                   ; FC3A29  inc 1,H
	cp	h, 16                                   ; FC3A2B  cp H,0x10
	jr c, sub_FC39FA__FC3A0A                   ; FC3A2E  jr C,0xfc3a0a
sub_FC39FA__FC3A30:
	ld	c, (xiz+8)                              ; FC3A30  ld C,(XIZ+0x08)
	extz	bc                                    ; FC3A33  extz BC
	div	c, 64                                  ; FC3A35  div C,0x40
	ld	(xiz-7), c                              ; FC3A38  ld (XIZ+0xf9),C
	ld	c, (xiz+8)                              ; FC3A3B  ld C,(XIZ+0x08)
	extz	bc                                    ; FC3A3E  extz BC
	div	c, 64                                  ; FC3A40  div C,0x40
	ld	h, b                                    ; FC3A43  ld H,B
	ld	xwa, 0x10000                            ; FC3A45  ld XWA,0x00010000
	ld	(xiz-12), xwa                           ; FC3A4A  ld (XIZ+0xf4),XWA
	ldb	c, 4                                   ; FC3A4D  ld C,0x04
	extpfx3 0x8E, 0xF9, 0x43                   ; FC3A4F  mul BC,(XIZ+0xf9)
	extz	xbc                                   ; FC3A52  extz XBC
	add	xbc, 0xFE151F                          ; FC3A54  add XBC,0x00fe151f
	ld	xbc, (xbc)                              ; FC3A5A  ld XBC,(XBC)
	push	xbc                                   ; FC3A5C  push XBC
	call	0xFC89AF                              ; FC3A5D  call 0xfc89af
	pushw	0x21D                                ; FC3A61  push 0x021d
	ld	c, h                                    ; FC3A64  ld C,H
	extz	bc                                    ; FC3A66  extz BC
	mul	bc, 0x2C9                              ; FC3A68  mul BC,0x02c9
	ld	xix, xbc                                ; FC3A6C  ld XIX,XBC
	add	xbc, 0x90                              ; FC3A6E  add XBC,0x00000090
	extpfx3 0xAE, 0xF4, 0x81                   ; FC3A74  add XBC,(XIZ+0xf4)
	push	xbc                                   ; FC3A77  push XBC
	lda	xbc, (0x87D2:24)                       ; FC3A78  lda XBC,0x0087d2
	push	xbc                                   ; FC3A7D  push XBC
	call	0xF9A038                              ; FC3A7E  call 0xf9a038
	ld	(xiz-6), xix                            ; FC3A82  ld (XIZ+0xfa),XIX
	ldw (xiz-2), 0x0000                        ; FC3A85  ld (XIZ+0xfe),0x0000
	ldw	de, 0                                  ; FC3A8A  ld DE,0x0000
	ldb	h, 4                                   ; FC3A8D  ld H,0x04
	inc	8, xsp                                 ; FC3A8F  inc 0,XSP
	inc	6, xsp                                 ; FC3A91  inc 6,XSP
sub_FC39FA__FC3A93:
	pushw	43                                   ; FC3A93  push 0x002b
	ld	bc, (xiz-2)                             ; FC3A96  ld BC,(XIZ+0xfe)
	extz	xbc                                   ; FC3A99  extz XBC
	ld	(xiz-16), xbc                           ; FC3A9B  ld (XIZ+0xf0),XBC
	ld	xwa, (xiz-6)                            ; FC3A9E  ld XWA,(XIZ+0xfa)
	ld	(xiz-20), xwa                           ; FC3AA1  ld (XIZ+0xec),XWA
	add	xwa, xbc                               ; FC3AA4  add XWA,XBC
	add	xwa, 0x2AD                             ; FC3AA6  add XWA,0x000002ad
	extpfx3 0xAE, 0xF4, 0x80                   ; FC3AAC  add XWA,(XIZ+0xf4)
	push	xwa                                   ; FC3AAF  push XWA
	add	xbc, 0x21D                             ; FC3AB0  add XBC,0x0000021d
	add	xbc, 0x87D2                            ; FC3AB6  add XBC,0x000087d2
	push	xbc                                   ; FC3ABC  push XBC
	call	0xF9A038                              ; FC3ABD  call 0xf9a038
	ld	bc, de                                  ; FC3AC1  ld BC,DE
	extz	xbc                                   ; FC3AC3  extz XBC
	extpfx3 0xAE, 0xEC, 0x81                   ; FC3AC5  add XBC,(XIZ+0xec)
	add	xbc, 0x16C                             ; FC3AC8  add XBC,0x0000016c
	ld	(xiz-24), xbc                           ; FC3ACE  ld (XIZ+0xe8),XBC
	ld	xix, (xiz-12)                           ; FC3AD1  ld XIX,(XIZ+0xf4)
	add	xix, xbc                               ; FC3AD4  add XIX,XBC
	ld	l, (xix)                                ; FC3AD6  ld L,(XIX)
	ld	c, l                                    ; FC3AD8  ld C,L
	and	c, 0xC0                                ; FC3ADA  and C,0xc0
	inc	8, xsp                                 ; FC3ADD  inc 0,XSP
	inc	2, xsp                                 ; FC3ADF  inc 2,XSP
	cp	c, 0xC0                                 ; FC3AE1  cp C,0xc0
	jr z, sub_FC39FA__FC3AF8                   ; FC3AE4  jr Z,0xfc3af8
	ld	c, l                                    ; FC3AE6  ld C,L
	and	c, 0xCF                                ; FC3AE8  and C,0xcf
	ld	(xiz-14), c                             ; FC3AEB  ld (XIZ+0xf2),C
	ld	(xix), c                                ; FC3AEE  ld (XIX),C
	ld	c, (xiz-14)                             ; FC3AF0  ld C,(XIZ+0xf2)
	set	4, c                                   ; FC3AF3  set 0x04,C
	ld	(xix), c                                ; FC3AF6  ld (XIX),C
sub_FC39FA__FC3AF8:
	extpfx5 0x9E, 0xFE, 0x38, 0x2B, 0x00       ; FC3AF8  add (XIZ+0xfe),0x002b
	add	de, 81                                 ; FC3AFD  add DE,0x0051
	dec	1, h                                   ; FC3B01  dec 1,H
	cps	h, 0                                   ; FC3B03  cp H,0
	jr nz, sub_FC39FA__FC3A93                  ; FC3B05  jr NZ,0xfc3a93
	ldb	c, 4                                   ; FC3B07  ld C,0x04
	extpfx3 0x8E, 0xF9, 0x43                   ; FC3B09  mul BC,(XIZ+0xf9)
	extz	xbc                                   ; FC3B0C  extz XBC
	add	xbc, 0xFE151F                          ; FC3B0E  add XBC,0x00fe151f
	ld	xbc, (xbc)                              ; FC3B14  ld XBC,(XBC)
	push	xbc                                   ; FC3B16  push XBC
	call	0xFC876C                              ; FC3B17  call 0xfc876c
	pop	xiy                                    ; FC3B1B  pop XIY
	sub	a, a                                   ; FC3B1C  sub A,A
	pop	xix                                    ; FC3B1E  pop XIX
	popw	de                                    ; FC3B1F  pop DE
	popw	hl                                    ; FC3B20  pop HL
	unlk32 xiz                                 ; FC3B21  unlk XIZ
	ret                                        ; FC3B23  ret
; --------------------------------------------------------------------------
; sub_FC3B24 -- 0xFC3B24..0xFC3CB7 (404 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFC02BF in sub_FBFFD4__FC02AE
; Inputs:  frame `link XIZ,-24`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
;          reads 0xFE150F, 0xFE151F
; Calls:   0xF9A038 = MemCopyWords, 0xFC386C = SoundRam_ClearFourBanks
;          0xFC876C = Flash_ReprogramSector, 0xFC89AF = Flash_ReadSectorToBuffer
; Evidence: the listing below is the byte-identical round-trip of 0xFC3B24-0xFC3CB7
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC3B24:
	link32 0xEE, 0x0C, 0xE8, 0xFF              ; FC3B24  link XIZ,0xffe8
	pushw	hl                                   ; FC3B28  push HL
	pushw	de                                   ; FC3B29  push DE
	push	xix                                   ; FC3B2A  push XIX
	ld	xbc, (0xFE150F:24)                     ; FC3B2B  ld XBC,(0xfe150f)
	ld	xix, xbc                                ; FC3B30  ld XIX,XBC
	ldb	h, 0                                   ; FC3B32  ld H,0x00
sub_FC3B24__FC3B34:
	ld	c, h                                    ; FC3B34  ld C,H
	extz	bc                                    ; FC3B36  extz BC
	extz	xbc                                   ; FC3B38  extz XBC
	ld	(xiz-20), xbc                           ; FC3B3A  ld (XIZ+0xec),XBC
	ld	xwa, (0xFE151F:24)                     ; FC3B3D  ld XWA,(0xfe151f)
	add	xwa, xbc                               ; FC3B42  add XWA,XBC
	ld	l, (xwa)                                ; FC3B44  ld L,(XWA)
	add	xbc, xix                               ; FC3B46  add XBC,XIX
	ld	w, (xbc)                                ; FC3B48  ld W,(XBC)
	cp	l, w                                    ; FC3B4A  cp L,W
	jr z, sub_FC3B24__FC3B53                   ; FC3B4C  jr Z,0xfc3b53
	calr (0xFC386C - 0xFC3B51)                 ; FC3B4E  calr 0xfc386c
	jr sub_FC3B24__FC3B5A                      ; FC3B51  jr T,0xfc3b5a
sub_FC3B24__FC3B53:
	inc	1, h                                   ; FC3B53  inc 1,H
	cp	h, 16                                   ; FC3B55  cp H,0x10
	jr c, sub_FC3B24__FC3B34                   ; FC3B58  jr C,0xfc3b34
sub_FC3B24__FC3B5A:
	ld	xbc, 0x10000                            ; FC3B5A  ld XBC,0x00010000
	ld	(xiz-16), xbc                           ; FC3B5F  ld (XIZ+0xf0),XBC
	ldb	a, 4                                   ; FC3B62  ld A,0x04
	extpfx3 0x8E, 0x08, 0x41                   ; FC3B64  mul WA,(XIZ+0x08)
	extz	xwa                                   ; FC3B67  extz XWA
	add	xwa, 0xFE151F                          ; FC3B69  add XWA,0x00fe151f
	ld	xwa, (xwa)                              ; FC3B6F  ld XWA,(XWA)
	push	xwa                                   ; FC3B71  push XWA
	call	0xFC89AF                              ; FC3B72  call 0xfc89af
	pushw	0x198                                ; FC3B76  push 0x0198
	ld	xix, (xiz-16)                           ; FC3B79  ld XIX,(XIZ+0xf0)
	add	xix, 0xB2D0                            ; FC3B7C  add XIX,0x0000b2d0
	push	xix                                   ; FC3B82  push XIX
	lda	xbc, (0x8A9B:24)                       ; FC3B83  lda XBC,0x008a9b
	push	xbc                                   ; FC3B88  push XBC
	call	0xF9A038                              ; FC3B89  call 0xf9a038
	ld	(xiz-12), xix                           ; FC3B8D  ld (XIZ+0xf4),XIX
	ldw (xiz-8), 0x0000                        ; FC3B90  ld (XIZ+0xf8),0x0000
	ldw	de, 0                                  ; FC3B95  ld DE,0x0000
	ld	(xiz-5), 0x80                           ; FC3B98  ld (XIZ+0xfb),0x80
	inc	8, xsp                                 ; FC3B9C  inc 0,XSP
	inc	6, xsp                                 ; FC3B9E  inc 6,XSP
sub_FC3B24__FC3BA0:
	ld	bc, (xiz-8)                             ; FC3BA0  ld BC,(XIZ+0xf8)
	extz	xbc                                   ; FC3BA3  extz XBC
	add	xbc, 0x99                              ; FC3BA5  add XBC,0x00000099
	ld	(xiz-20), xbc                           ; FC3BAB  ld (XIZ+0xec),XBC
	ld	xix, (xiz-12)                           ; FC3BAE  ld XIX,(XIZ+0xf4)
	add	xix, xbc                               ; FC3BB1  add XIX,XBC
	ld	h, (xix)                                ; FC3BB3  ld H,(XIX)
	ld	c, h                                    ; FC3BB5  ld C,H
	and	c, 0xC0                                ; FC3BB7  and C,0xc0
	cp	c, 0xC0                                 ; FC3BBA  cp C,0xc0
	jr z, sub_FC3B24__FC3BCD                   ; FC3BBD  jr Z,0xfc3bcd
	ld	l, h                                    ; FC3BBF  ld L,H
	and	l, 0xCF                                ; FC3BC1  and L,0xcf
	ld	(xix), l                                ; FC3BC4  ld (XIX),L
	ld	c, l                                    ; FC3BC6  ld C,L
	set	4, c                                   ; FC3BC8  set 0x04,C
	ld	(xix), c                                ; FC3BCB  ld (XIX),C
sub_FC3B24__FC3BCD:
	pushw	64                                   ; FC3BCD  push 0x0040
	ld	ix, de                                  ; FC3BD0  ld IX,DE
	extz	xix                                   ; FC3BD2  extz XIX
	ld	xbc, xix                                ; FC3BD4  ld XBC,XIX
	add	xbc, 0xB468                            ; FC3BD6  add XBC,0x0000b468
	extpfx3 0xAE, 0xF0, 0x81                   ; FC3BDC  add XBC,(XIZ+0xf0)
	push	xbc                                   ; FC3BDF  push XBC
	ld	xbc, xix                                ; FC3BE0  ld XBC,XIX
	add	xbc, 0x461                             ; FC3BE2  add XBC,0x00000461
	add	xbc, 0x87D2                            ; FC3BE8  add XBC,0x000087d2
	push	xbc                                   ; FC3BEE  push XBC
	call	0xF9A038                              ; FC3BEF  call 0xf9a038
	ldw (xiz-2), 0x0000                        ; FC3BF3  ld (XIZ+0xfe),0x0000
	ldw (xiz-4), 0x0000                        ; FC3BF8  ld (XIZ+0xfc),0x0000
	ldb	h, 2                                   ; FC3BFD  ld H,0x02
	inc	8, xsp                                 ; FC3BFF  inc 0,XSP
	inc	2, xsp                                 ; FC3C01  inc 2,XSP
sub_FC3B24__FC3C03:
	ld	bc, (xiz-2)                             ; FC3C03  ld BC,(XIZ+0xfe)
	extz	xbc                                   ; FC3C06  extz XBC
	ld	(xiz-20), xbc                           ; FC3C08  ld (XIZ+0xec),XBC
	ld	wa, de                                  ; FC3C0B  ld WA,DE
	extz	xwa                                   ; FC3C0D  extz XWA
	add	xwa, xbc                               ; FC3C0F  add XWA,XBC
	add	xwa, 0xB47D                            ; FC3C11  add XWA,0x0000b47d
	ld	(xiz-24), xwa                           ; FC3C17  ld (XIZ+0xe8),XWA
	ld	xix, (xiz-16)                           ; FC3C1A  ld XIX,(XIZ+0xf0)
	add	xix, xwa                               ; FC3C1D  add XIX,XWA
	ld	l, (xix)                                ; FC3C1F  ld L,(XIX)
	ld	c, l                                    ; FC3C21  ld C,L
	and	c, 0xC0                                ; FC3C23  and C,0xc0
	cp	c, 0xC0                                 ; FC3C26  cp C,0xc0
	jr z, sub_FC3B24__FC3C3D                   ; FC3C29  jr Z,0xfc3c3d
	ld	c, l                                    ; FC3C2B  ld C,L
	and	c, 0xCF                                ; FC3C2D  and C,0xcf
	ld	(xiz-18), c                             ; FC3C30  ld (XIZ+0xee),C
	ld	(xix), c                                ; FC3C33  ld (XIX),C
	ld	c, (xiz-18)                             ; FC3C35  ld C,(XIZ+0xee)
	set	4, c                                   ; FC3C38  set 0x04,C
	ld	(xix), c                                ; FC3C3B  ld (XIX),C
sub_FC3B24__FC3C3D:
	pushw	43                                   ; FC3C3D  push 0x002b
	ld	ix, (xiz-4)                             ; FC3C40  ld IX,(XIZ+0xfc)
	ld	bc, ix                                  ; FC3C43  ld BC,IX
	extz	xbc                                   ; FC3C45  extz XBC
	ld	(xiz-20), xbc                           ; FC3C47  ld (XIZ+0xec),XBC
	ld	wa, de                                  ; FC3C4A  ld WA,DE
	extz	xwa                                   ; FC3C4C  extz XWA
	add	xwa, xbc                               ; FC3C4E  add XWA,XBC
	ld	(xiz-24), xwa                           ; FC3C50  ld (XIZ+0xe8),XWA
	add	xwa, 0xB4A8                            ; FC3C53  add XWA,0x0000b4a8
	extpfx3 0xAE, 0xF0, 0x80                   ; FC3C59  add XWA,(XIZ+0xf0)
	push	xwa                                   ; FC3C5C  push XWA
	ld	xbc, (xiz-24)                           ; FC3C5D  ld XBC,(XIZ+0xe8)
	add	xbc, 0x4A1                             ; FC3C60  add XBC,0x000004a1
	add	xbc, 0x87D2                            ; FC3C66  add XBC,0x000087d2
	push	xbc                                   ; FC3C6C  push XBC
	call	0xF9A038                              ; FC3C6D  call 0xf9a038
	extpfx5 0x9E, 0xFE, 0x38, 0x17, 0x00       ; FC3C71  add (XIZ+0xfe),0x0017
	ld	bc, ix                                  ; FC3C76  ld BC,IX
	add	bc, 43                                 ; FC3C78  add BC,0x002b
	ld	(xiz-4), bc                             ; FC3C7C  ld (XIZ+0xfc),BC
	dec	1, h                                   ; FC3C7F  dec 1,H
	inc	8, xsp                                 ; FC3C81  inc 0,XSP
	inc	2, xsp                                 ; FC3C83  inc 2,XSP
	cps	h, 0                                   ; FC3C85  cp H,0
	jrl nz, sub_FC3B24__FC3C03                 ; FC3C87  jrl NZ,0xfc3c03
	incw	2, (xiz-8)                            ; FC3C8A  incw 2,(XIZ+0xf8)
	add	de, 0x96                               ; FC3C8D  add DE,0x0096
	decm8	1, (xiz-5)                           ; FC3C91  dec 1,(XIZ+0xfb)
	cp (xiz-5), 0x00                           ; FC3C94  cp (XIZ+0xfb),0x00
	jrl nz, sub_FC3B24__FC3BA0                 ; FC3C98  jrl NZ,0xfc3ba0
	ldb	a, 4                                   ; FC3C9B  ld A,0x04
	extpfx3 0x8E, 0x08, 0x41                   ; FC3C9D  mul WA,(XIZ+0x08)
	extz	xwa                                   ; FC3CA0  extz XWA
	add	xwa, 0xFE151F                          ; FC3CA2  add XWA,0x00fe151f
	ld	xwa, (xwa)                              ; FC3CA8  ld XWA,(XWA)
	push	xwa                                   ; FC3CAA  push XWA
	call	0xFC876C                              ; FC3CAB  call 0xfc876c
	pop	xiy                                    ; FC3CAF  pop XIY
	sub	a, a                                   ; FC3CB0  sub A,A
	pop	xix                                    ; FC3CB2  pop XIX
	popw	de                                    ; FC3CB3  pop DE
	popw	hl                                    ; FC3CB4  pop HL
	unlk32 xiz                                 ; FC3CB5  unlk XIZ
	ret                                        ; FC3CB7  ret
; --------------------------------------------------------------------------
; sub_FC3CB8 -- 0xFC3CB8..0xFC3CB8 (1 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFBAE7D in sub_FBAC24__FBAE7D
; Inputs:  no frame and no argument slot read.
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFC3CB8-0xFC3CB8
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC3CB8:
	ret                                        ; FC3CB8  ret

; ============================================================================
; ★★ THE EIGHT-SLOT NOTE POOL -- 0xFC3CB9-0xFC3FAD, and its five tables
;    (round 9, 2026-08-30)
; ============================================================================
; A note engine that is NOT the 33-part voice engine.  MidiIn_ParseRingAndDispatch's
; 0x90 arm assembles a 4-byte packet at 0x00D7D4 and then branches on byte [1], the
; part selector: below 0xF0 it calls MidiNote_Dispatch, at 0xF0 or above it calls
; NotePool8_NoteOnOff (`cp H,0xf0` at 0xFB07FD, `jr NC,0xfb0808` at 0xFB0800).  Every
; routine and table below belongs to that second path and to nothing else.
;
;   0xFC3CB9  NotePool8_LevelFromVelocity              register chan+0x0080
;   0xFC3CFB  NotePool8_Reg00C0_FromPart0Ctrl91And93   register chan+0x00C0
;   0xFC3D13  NotePool8_Word0Bits_FromPart0Ctrl9B      staging word 0
;   0xFC3D26  NotePool8_StageVoice                     words 0,1,2,3,7
;   0xFC3DAF  NotePool8_StageVoice_Var1                words 0,1,2,3,7, variant 1
;   0xFC3E02  NotePool8_NoteOnOff                      the entry point
;   0xFE1540  Dev10C_StagingStruct_NotePool8Image      the 68-byte device template
;   0xFE1584  NotePool8_TransposeByVariant             7 signed semitones
;   0xFE158B  NotePool8_LevelCapByVariant              7 level caps
;   0xFE1599  NotePool8_Reg0040_ByPitchClass           12 words, note mod 12
;   0xFE15B1  NotePool8_Reg0040_ByPitchClass_Var6      12 words, variant 6 only
;   0xFE15C9  NotePool8_Word0_ByPitchClass_Var1        12 words, variant 1 only
;
; ★ WHAT MAKES IT A POOL AND NOT A PART.  The slot is a round-robin counter at RAM
; 0x00E005 masked with `and C,0x07` (0xFC3E27); the note sounding in each slot is
; kept in an eight-byte table at 0x00E006 with bit 7 as the in-use flag; the release
; path is a linear scan bounded by `cp L,0x08` (0xFC3FA3).  Nothing anywhere else in
; the image names either address -- 13 addressed source lines and 13 24-bit
; little-endian ROM occurrences, all inside NotePool8_NoteOnOff.  The 33 part records
; at 0x001523, the 0x012C stride and the voice records at 0x003BCF play no part in
; it; the ONLY part-record fields it reads are part 0's +0x10, +0x11 and +0x19.
;
; ★ IT DRIVES BOTH DEVICES WITH THE SAME SLOT NUMBER.  0x0010C000 through
; Dev10C_WriteAllChanRegs (0xFC3F17) and Dev10C_WriteReg_c (0xFC3F27); 0x00104000
; through Dev104_WriteChanReg0 (0xFC3EA1), Dev104_LoadStageBImage (0xFC3EA9) and
; Dev104_WriteAllChanRegs (0xFC3ECD).
;
; ⚠ WHAT IS NOT ESTABLISHED.  What the seven variants are -- the packets come over
; link channel 0 from CPU 1, so their names are in prom_a, and prom_c spells
; 0xF0..0xF6 as a part selector nowhere else.  Whether the note-off pair
; 0xA200/0xA280 is a release envelope or a second quiescent state; nothing in this
; image reads either register back.  What staging word 0's bit fields mean.
;
; Every address quoted here and in the six headers below is checked AT THE CITED
; ADDRESS by `python3 notes/prom_c_inventory_round8.py --pool8`.
; ============================================================================

; --------------------------------------------------------------------------
; NotePool8_LevelFromVelocity -- 0xFC3CB9..0xFC3CFA (66 bytes)
;
; Called from: no site outside this module.
;          2 site(s) inside this module:
;          0xFC3D6D 0xFC3DEE
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFC3CB9-0xFC3CFA
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 9).  THE LEVEL A POOL-8 NOTE IS STAGED AT.  Returns
;          min(velocity*32 + 31, NotePool8_LevelCapByVariant[variant]) for variant 4
;          and the cap unchanged for every other variant; the caller ORs the result
;          into staging word 2, which Dev10C_WriteAllChanRegs sends to register
;          chan+0x0080 -- the OUTPUT LEVEL (FINDINGS-prom_c-dev10c-register-meanings.md
;          sec.3).
; Inputs:  (XIZ+0x08) = the 7-bit velocity, (XIZ+0x0A) = the variant 0..6.
; Evidence: `cp D,4` at 0xFC3CC2 is the only variant that takes the velocity arm;
;          `sll 0x05,BC` at 0xFC3CC9 and `add BC,0x001f` at 0xFC3CCE build
;          velocity*32+31; `cp BC,WA / jr LE` at 0xFC3CE2/0xFC3CE4 keeps the smaller of
;          that and the table entry, and the other arm at 0xFC3CE6 loads the entry
;          alone.  Both callers OR the return into (buf+0x04): 0xFC3D73 and 0xFC3DF1.
; Unknown:  WHAT the seven variants are.  The velocity law and the caps are measured;
;          nothing here says which instrument or function a variant selects.
; --------------------------------------------------------------------------
NotePool8_LevelFromVelocity:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC3CB9  link XIZ,0x0000
	pushw	hl                                   ; FC3CBD  push HL
	pushw	de                                   ; FC3CBE  push DE
	ld	d, (xiz+10)                             ; FC3CBF  ld D,(XIZ+0x0a)
	cps	d, 4                                   ; FC3CC2  cp D,4
	jr nz, NotePool8_LevelFromVelocity__FC3CE6                  ; FC3CC4  jr NZ,0xfc3ce6
	ld	bc, (xiz+8)                             ; FC3CC6  ld BC,(XIZ+0x08)
	sll	bc, 5                                  ; FC3CC9  sll 0x05,BC
	ld	hl, bc                                  ; FC3CCC  ld HL,BC
	add	bc, 31                                 ; FC3CCE  add BC,0x001f
	ld	hl, bc                                  ; FC3CD2  ld HL,BC
	ldb	a, 2                                   ; FC3CD4  ld A,0x02
	mul8rr	a, d                                ; FC3CD6  mul WA,D
	extz	xwa                                   ; FC3CD8  extz XWA
	add	xwa, 0xFE158B                          ; FC3CDA  add XWA,0x00fe158b
	ld	wa, (xwa)                               ; FC3CE0  ld WA,(XWA)
	cp	bc, wa                                  ; FC3CE2  cp BC,WA
	jr le, NotePool8_LevelFromVelocity__FC3CF4                  ; FC3CE4  jr LE,0xfc3cf4
NotePool8_LevelFromVelocity__FC3CE6:
	ldb	c, 2                                   ; FC3CE6  ld C,0x02
	mul8rr	c, d                                ; FC3CE8  mul BC,D
	extz	xbc                                   ; FC3CEA  extz XBC
	add	xbc, 0xFE158B                          ; FC3CEC  add XBC,0x00fe158b
	ld	hl, (xbc)                               ; FC3CF2  ld HL,(XBC)
NotePool8_LevelFromVelocity__FC3CF4:
	ld	wa, hl                                  ; FC3CF4  ld WA,HL
	popw	de                                    ; FC3CF6  pop DE
	popw	hl                                    ; FC3CF7  pop HL
	unlk32 xiz                                 ; FC3CF8  unlk XIZ
	ret                                        ; FC3CFA  ret
; --------------------------------------------------------------------------
; NotePool8_Reg00C0_FromPart0Ctrl91And93 -- 0xFC3CFB..0xFC3D12 (24 bytes)
;
; Called from: no site outside this module.
;          2 site(s) inside this module:
;          0xFC3D5A 0xFC3DE2
; Inputs:  no frame and no argument slot read.
; Outputs: no absolute-addressed write.
;          reads 0x001533, 0x001534
; Evidence: the listing below is the byte-identical round-trip of 0xFC3CFB-0xFC3D12
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 9).  BUILDS REGISTER chan+0x00C0 FOR A POOL-8 NOTE, as the byte
;          pair (part0[+0x10] << 8) | part0[+0x11] -- the values MIDI controllers 91
;          and 93 write into the part record (FINDINGS-prom_c-dev10c-register-
;          meanings.md sec.1).  RAM 0x001533 and 0x001534 are exactly part 0's +0x10
;          and +0x11: the part array starts at 0x001523 with stride 0x012C.
; Evidence: `ld C,(0x1533)` at 0xFC3CFC, `sll 0x08,HL` at 0xFC3D04,
;          `ld C,(0x1534)` at 0xFC3D07 and `or BC,HL` at 0xFC3D0D; the caller ORs the
;          return into (buf+0x06) at 0xFC3D60, and prom_c_tg_chanmap.py --pairs shows
;          Dev10C_WriteAllChanRegs sending struct+0x06 to register chan+0x00C0
;          (0xFB718F).
; ★          THE MAIN VOICE PATH AGREES, independently: Voice_StageRegs_00C0_AB
;          (0xFAA0BC) builds the SAME word for the same register out of the SAME two
;          part fields -- `ld C,(XHL+0x11)` at 0xFC3CFB's counterpart 0xFAA0D3 for the
;          low byte and `ld C,(XDE+0x10)` at 0xFAA12E for the high byte, each clamped
;          to 0..0x7F (0xFAA110/0xFAA181) and each offset by a per-tone amount from
;          part[+0x27] / part[+0x29], before `sll 0x08` at 0xFAA18C and the store to
;          the staging struct at 0xFAA19A.  Two unrelated producers, one field split.
; Unknown:  what the two depths DO.  Controllers 91 and 93 are "effects depth 1 and 3"
;          in the MIDI allocation, and this firmware corroborates only 7, 64 and 120
;          of its controller numbers, so no effect is named here.
; --------------------------------------------------------------------------
NotePool8_Reg00C0_FromPart0Ctrl91And93:
	pushw	hl                                   ; FC3CFB  push HL
	ld	c, (0x1533:16)                         ; FC3CFC  ld C,(0x1533)
	extz	bc                                    ; FC3D00  extz BC
	ld	hl, bc                                  ; FC3D02  ld HL,BC
	sll	hl, 8                                  ; FC3D04  sll 0x08,HL
	ld	c, (0x1534:16)                         ; FC3D07  ld C,(0x1534)
	extz	bc                                    ; FC3D0B  extz BC
	or	bc, hl                                  ; FC3D0D  or BC,HL
	ld	wa, bc                                  ; FC3D0F  ld WA,BC
	popw	hl                                    ; FC3D11  pop HL
	ret                                        ; FC3D12  ret
; --------------------------------------------------------------------------
; NotePool8_Word0Bits_FromPart0Ctrl9B -- 0xFC3D13..0xFC3D25 (19 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFC3D52
; Inputs:  no frame and no argument slot read.
; Outputs: no absolute-addressed write.
;          reads 0x00153C
; Evidence: the listing below is the byte-identical round-trip of 0xFC3D13-0xFC3D25
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 9).  Returns 0x0C00 when the high nibble of part 0's +0x19 byte is
;          5, and 0 otherwise; the caller ORs it into staging word 0.  RAM 0x00153C is
;          part 0's +0x19 (array base 0x001523, stride 0x012C), the field
;          MidiCtrl_Int9B writes (`add BC,0x0019` in that handler).
; Evidence: `ld C,(0x153c)` at 0xFC3D13, `srl 0x04,C` at 0xFC3D17, `cp C,5` at
;          0xFC3D1A, `ld WA,0x0c00` at 0xFC3D1E, `sub WA,WA` at 0xFC3D23; the caller's
;          `or (XBC),WA` is at 0xFC3D58.
; Unknown:  what bits 11..10 of staging word 0 mean, and what the 0x9B message carries.
; --------------------------------------------------------------------------
NotePool8_Word0Bits_FromPart0Ctrl9B:
	ld	c, (0x153C:16)                         ; FC3D13  ld C,(0x153c)
	srl	c, 4                                   ; FC3D17  srl 0x04,C
	cps	c, 5                                   ; FC3D1A  cp C,5
	jr nz, NotePool8_Word0Bits_FromPart0Ctrl9B__FC3D23                  ; FC3D1C  jr NZ,0xfc3d23
	ldw	wa, 0xC00                              ; FC3D1E  ld WA,0x0c00
	jr NotePool8_Word0Bits_FromPart0Ctrl9B__FC3D25                      ; FC3D21  jr T,0xfc3d25
NotePool8_Word0Bits_FromPart0Ctrl9B__FC3D23:
	sub	wa, wa                                 ; FC3D23  sub WA,WA
NotePool8_Word0Bits_FromPart0Ctrl9B__FC3D25:
	ret                                        ; FC3D25  ret
; --------------------------------------------------------------------------
; NotePool8_StageVoice -- 0xFC3D26..0xFC3DAE (137 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFC3F04
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C), (XIZ+0x0E)
; Outputs: no absolute-addressed write.
; Calls:   0xFC3CB9 = NotePool8_LevelFromVelocity, 0xFC3CFB = NotePool8_Reg00C0_FromPart0Ctrl91And93
;          0xFC3D13 = NotePool8_Word0Bits_FromPart0Ctrl9B
; Evidence: the listing below is the byte-identical round-trip of 0xFC3D26-0xFC3DAE
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 9).  STAGES ONE POOL-8 NOTE INTO THE 0x0010C000 STAGING STRUCT.
;          It writes five words of the buffer NotePool8_NoteOnOff copied from
;          Dev10C_StagingStruct_NotePool8Image, and every one of the five is a
;          register whose meaning is already established:
;            word 7 (reg 0x0400, PITCH)  |= (note + NotePool8_TransposeByVariant
;                                            [variant]) & 0x7F, shifted left 8
;            word 2 (reg 0x0080, LEVEL)  |= NotePool8_LevelFromVelocity(vel, variant)
;            word 3 (reg 0x00C0)         |= NotePool8_Reg00C0_FromPart0Ctrl91And93()
;            word 0                      |= NotePool8_Word0Bits_FromPart0Ctrl9B()
;            word 1 (reg 0x0040)          = NotePool8_Reg0040_ByPitchClass[note % 12],
;                                           or the _Var6 table when variant == 6
; Inputs:  (XIZ+0x08) variant 0..6, (XIZ+0x0A) 7-bit note, (XIZ+0x0C) 7-bit velocity,
;          (XIZ+0x0E) the 68-byte staging buffer.
; Evidence: the transpose read and add are 0xFC3D35/0xFC3D3D, the mask 0xFC3D42, the
;          `sll 0x08,BC` 0xFC3D49 and the `or (XWA+0x0e),BC` 0xFC3D4F; the two helper
;          returns land at 0xFC3D58 and 0xFC3D60; the level OR is 0xFC3D73; the
;          pitch-class index is `div C,0x0c` at 0xFC3D7A with the REMAINDER taken at
;          0xFC3D7D and doubled at 0xFC3D7F -- the same idiom as the `note mod 12`
;          user-scale read at 0xFA7FC5-0xFA7FD2 -- and the variant-6 fork is
;          `cp H,6 / jr Z` at 0xFC3D87.  The word->register map is
;          notes/prom_c_tg_chanmap.py --pairs.
; Unknown:  what the seven variants are, and what staging word 0's bits mean.
; --------------------------------------------------------------------------
NotePool8_StageVoice:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC3D26  link XIZ,0x0000
	pushw	hl                                   ; FC3D2A  push HL
	push	xix                                   ; FC3D2B  push XIX
	ld	h, (xiz+8)                              ; FC3D2C  ld H,(XIZ+0x08)
	ld	c, h                                    ; FC3D2F  ld C,H
	extz	bc                                    ; FC3D31  extz BC
	extz	xbc                                   ; FC3D33  extz XBC
	add	xbc, 0xFE1584                          ; FC3D35  add XBC,0x00fe1584
	ld	a, (xbc)                                ; FC3D3B  ld A,(XBC)
	extpfx3 0x8E, 0x0A, 0x81                   ; FC3D3D  add A,(XIZ+0x0a)
	ld	l, a                                    ; FC3D40  ld L,A
	res	7, l                                   ; FC3D42  res 0x07,L
	ld	c, l                                    ; FC3D45  ld C,L
	extz	bc                                    ; FC3D47  extz BC
	sll	bc, 8                                  ; FC3D49  sll 0x08,BC
	ld	xwa, (xiz+14)                           ; FC3D4C  ld XWA,(XIZ+0x0e)
	or	(xwa+14), bc                            ; FC3D4F  or (XWA+0x0e),BC
	calr (0xFC3D13 - 0xFC3D55)                 ; FC3D52  calr 0xfc3d13
	ld	xbc, (xiz+14)                           ; FC3D55  ld XBC,(XIZ+0x0e)
	or	(xbc), wa                               ; FC3D58  or (XBC),WA
	calr (0xFC3CFB - 0xFC3D5D)                 ; FC3D5A  calr 0xfc3cfb
	ld	xbc, (xiz+14)                           ; FC3D5D  ld XBC,(XIZ+0x0e)
	or	(xbc+6), wa                             ; FC3D60  or (XBC+0x06),WA
	push	0                                     ; FC3D63  push 0x00
	push	h                                     ; FC3D65  push H
	ld	bc, (xiz+12)                            ; FC3D67  ld BC,(XIZ+0x0c)
	extz	bc                                    ; FC3D6A  extz BC
	pushw	bc                                   ; FC3D6C  push BC
	calr (0xFC3CB9 - 0xFC3D70)                 ; FC3D6D  calr 0xfc3cb9
	ld	xbc, (xiz+14)                           ; FC3D70  ld XBC,(XIZ+0x0e)
	or	(xbc+4), wa                             ; FC3D73  or (XBC+0x04),WA
	ld	c, l                                    ; FC3D76  ld C,L
	extz	bc                                    ; FC3D78  extz BC
	div	c, 12                                  ; FC3D7A  div C,0x0c
	ld	a, b                                    ; FC3D7D  ld A,B
	mul	a, 2                                   ; FC3D7F  mul A,0x02
	extz	xwa                                   ; FC3D82  extz XWA
	ld	xix, xwa                                ; FC3D84  ld XIX,XWA
	pop	xiy                                    ; FC3D86  pop XIY
	cps	h, 6                                   ; FC3D87  cp H,6
	jr z, NotePool8_StageVoice__FC3D9B                   ; FC3D89  jr Z,0xfc3d9b
	add	xwa, 0xFE1599                          ; FC3D8B  add XWA,0x00fe1599
	ld	bc, (xwa)                               ; FC3D91  ld BC,(XWA)
	ld	xwa, (xiz+14)                           ; FC3D93  ld XWA,(XIZ+0x0e)
	ld	(xwa+2), bc                             ; FC3D96  ld (XWA+0x02),BC
	jr NotePool8_StageVoice__FC3DAA                      ; FC3D99  jr T,0xfc3daa
NotePool8_StageVoice__FC3D9B:
	lda	xbc, (0xFE15B1:24)                     ; FC3D9B  lda XBC,0xfe15b1
	add	xbc, xix                               ; FC3DA0  add XBC,XIX
	ld	wa, (xbc)                               ; FC3DA2  ld WA,(XBC)
	ld	xbc, (xiz+14)                           ; FC3DA4  ld XBC,(XIZ+0x0e)
	ld	(xbc+2), wa                             ; FC3DA7  ld (XBC+0x02),WA
NotePool8_StageVoice__FC3DAA:
	pop	xix                                    ; FC3DAA  pop XIX
	popw	hl                                    ; FC3DAB  pop HL
	unlk32 xiz                                 ; FC3DAC  unlk XIZ
	ret                                        ; FC3DAE  ret
; --------------------------------------------------------------------------
; NotePool8_StageVoice_Var1 -- 0xFC3DAF..0xFC3E01 (83 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFC3EF4
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
;          reads 0xFE1599
; Calls:   0xFC3CB9 = NotePool8_LevelFromVelocity, 0xFC3CFB = NotePool8_Reg00C0_FromPart0Ctrl91And93
; Evidence: the listing below is the byte-identical round-trip of 0xFC3DAF-0xFC3E01
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 9).  THE VARIANT-1 STAGING PATH, called INSTEAD of
;          NotePool8_StageVoice when the variant is 1 (`cp L,1 / jr NZ` at
;          0xFC3EEC/0xFC3EEE in NotePool8_NoteOnOff), and then the general path runs
;          on the same buffer as well.
;          It differs from NotePool8_StageVoice in three measured ways: the pitch it
;          stages is the note with its pitch class REMOVED -- `div C,0x0c` at 0xFC3DBD
;          then `sub C,B` at 0xFC3DC5, i.e. note - (note mod 12), the octave root --
;          the level is taken at a FIXED velocity 0x7F (pushed at 0xFC3DEB) with the
;          variant fixed at 1 (0xFC3DE8), and staging word 1 is entry 0 of
;          NotePool8_Reg0040_ByPitchClass read directly (`ld BC,(0xfe1599)` at
;          0xFC3DF4), never indexed.
; Evidence: the pitch OR is `sll 0x08,BC` at 0xFC3DCC and `or (XIX+0x0e),BC` at
;          0xFC3DCF; NotePool8_Word0_ByPitchClass_Var1 is read at 0xFC3DD8 and OR'd
;          into word 0 at 0xFC3DE0; word 3 at 0xFC3DE5; word 2 at 0xFC3DF1; word 1 at
;          0xFC3DF9.
; Unknown:  what variant 1 is, and why it stages twice.
; --------------------------------------------------------------------------
NotePool8_StageVoice_Var1:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC3DAF  link XIZ,0x0000
	pushw	hl                                   ; FC3DB3  push HL
	push	xix                                   ; FC3DB4  push XIX
	ld	xix, (xiz+10)                           ; FC3DB5  ld XIX,(XIZ+0x0a)
	ld	c, (xiz+8)                              ; FC3DB8  ld C,(XIZ+0x08)
	extz	bc                                    ; FC3DBB  extz BC
	div	c, 12                                  ; FC3DBD  div C,0x0c
	ld	h, b                                    ; FC3DC0  ld H,B
	ld	c, (xiz+8)                              ; FC3DC2  ld C,(XIZ+0x08)
	sub	c, b                                   ; FC3DC5  sub C,B
	res	7, c                                   ; FC3DC7  res 0x07,C
	extz	bc                                    ; FC3DCA  extz BC
	sll	bc, 8                                  ; FC3DCC  sll 0x08,BC
	or	(xix+14), bc                            ; FC3DCF  or (XIX+0x0e),BC
	ldb	c, 2                                   ; FC3DD2  ld C,0x02
	mul8rr	c, h                                ; FC3DD4  mul BC,H
	extz	xbc                                   ; FC3DD6  extz XBC
	add	xbc, 0xFE15C9                          ; FC3DD8  add XBC,0x00fe15c9
	ld	bc, (xbc)                               ; FC3DDE  ld BC,(XBC)
	or	(xix), bc                               ; FC3DE0  or (XIX),BC
	calr (0xFC3CFB - 0xFC3DE5)                 ; FC3DE2  calr 0xfc3cfb
	or	(xix+6), wa                             ; FC3DE5  or (XIX+0x06),WA
	pushw	1                                    ; FC3DE8  push 0x0001
	pushw	0x7F                                 ; FC3DEB  push 0x007f
	calr (0xFC3CB9 - 0xFC3DF1)                 ; FC3DEE  calr 0xfc3cb9
	or	(xix+4), wa                             ; FC3DF1  or (XIX+0x04),WA
	ld	bc, (0xFE1599:24)                      ; FC3DF4  ld BC,(0xfe1599)
	ld	(xix+2), bc                             ; FC3DF9  ld (XIX+0x02),BC
	pop	xbc                                    ; FC3DFC  pop XBC
	pop	xix                                    ; FC3DFD  pop XIX
	popw	hl                                    ; FC3DFE  pop HL
	unlk32 xiz                                 ; FC3DFF  unlk XIZ
	ret                                        ; FC3E01  ret
; --------------------------------------------------------------------------
; NotePool8_NoteOnOff -- 0xFC3E02..0xFC3FAD (428 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFB0808 in MidiIn_ParseRingAndDispatch__FB0808
; Inputs:  frame `link XIZ,-114`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x00E005
; Calls:   0xF9A038 = MemCopyWords, 0xFB713A = Dev10C_WriteAllChanRegs
;          0xFB732C = Dev10C_WriteReg_c, 0xFB77EF = Dev104_WriteAllChanRegs
;          0xFB7A58 = Dev104_WriteChanReg0, 0xFC3D26 = NotePool8_StageVoice
;          0xFC3DAF = NotePool8_StageVoice_Var1, 0xFC571A = Dev104_LoadStageBImage
;          0xFC7DAF = sub_FC7DAF
; Evidence: the listing below is the byte-identical round-trip of 0xFC3E02-0xFC3FAD
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★★ NAMED (round 9).  THE NOTE ENGINE OF A PRIVATE EIGHT-SLOT VOICE POOL.
;          It is the handler MidiIn_ParseRingAndDispatch's 0x90 (note-on) arm calls
;          when the packet's byte [1] -- the PART SELECTOR every other 0x90 packet
;          carries -- is >= 0xF0: `cp H,0xf0` at 0xFB07FD and `jr NC,0xfb0808` choose
;          between MidiNote_Dispatch (the 33 part records) and this routine.
;          ★ THAT CLOSES the "⚠ what packet byte [1] >= 0xF0 means" line in
;          MidiIn_ParseRingAndDispatch's own Unknown section.
; Inputs:  (XIZ+0x08) = the 4-byte packet the arm assembled at 0x00D7D4:
;          [0] status, [1] 0xF0 + variant, [2] note, [3] velocity.  Byte [2] and byte
;          [3] are masked to 7 bits at 0xFC3E35 and 0xFC3E3B; the variant is
;          `and L,0x0f` (0xFC3E17) clamped to 0..6 by `cp L,6 / jr ULE` (0xFC3E1A)
;          with an else-arm `ld L,0x00` (0xFC3E1E).
; Evidence: ★ THE POOL IS EIGHT SLOTS, AND IT IS PRIVATE.  The allocator is a
;          round-robin counter at RAM 0x00E005 -- `inc 1,C` / `and C,0x07` at
;          0xFC3E25/0xFC3E27 -- and each slot's sounding note is remembered in an
;          eight-byte table at 0x00E006 (`add XBC,0x0000e006` at 0xFC3F39) with bit 7
;          set while it sounds (`set 7,L` at 0xFC3F2D) and cleared on release
;          (`and (XBC),0x7f` at 0xFC3F98).  The release scan bounds the table at eight:
;          `inc 1,L` / `cp L,0x08` / `jr C` at 0xFC3FA1-0xFC3FA6.
;          ⚠ THE POOL STATE IS PRIVATE, BY TWO INDEPENDENT SWEEPS.  0x00E005 and
;          0x00E006 appear on THIRTEEN addressed source lines in prom_c and all
;          thirteen are inside this routine (0xFC3E20..0xFC3F90); and the raw ROM
;          holds thirteen 24-bit little-endian occurrences of the two addresses --
;          ten of 0x00E005, three of 0x00E006 -- every one of them the operand of
;          one of those same thirteen instructions.  Both sweeps are blind to a
;          reach through a register; neither says 'dead', both say 'nothing else
;          in the image names it'.
;          ★ VELOCITY 0 IS THE NOTE-OFF.  `cp D,0 / jrl Z,0xfc3f47` at
;          0xFC3E3E/0xFC3E40 splits the two paths.
;          ★ NOTE-ON STEALS THE SLOT WITH THE DOCUMENTED QUIESCENT PAIR: register
;          chan+0x0840 = 0xFF00 (select 0xFC3E58, data 0xFC3E5D) and chan+0x0800 =
;          0xFF80 (select 0xFC3E7C, data 0xFC3E81) -- exactly the two values
;          Dev10C_ResetAllChannels and Dev10C_QuiesceListedChans_0800_0840 write
;          (FINDINGS-prom_c-dev10c-register-meanings.md sec.5).  It then programs the
;          0x00104000 device for the same slot number (0xFC3E91, 0xFC3EA1, 0xFC3EA9,
;          0xFC3ECD), copies Dev10C_StagingStruct_NotePool8Image into a stack buffer
;          (0xFC3ED1-0xFC3EDE), fills it through NotePool8_StageVoice_Var1 and/or
;          NotePool8_StageVoice (0xFC3EF4, 0xFC3F04), bursts it with
;          Dev10C_WriteAllChanRegs (0xFC3F17), and finally sends the buffer's word 0
;          to register chan+0x0000 through Dev10C_WriteReg_c (0xFC3F1B-0xFC3F27).
;          ★ THAT LAST CALL ANSWERS Dev10C_WriteAllChanRegs' OWN "Unknown: what
;          struct word 0 is for" -- on this path word 0 is the value for register
;          block 0, the register that routine instead writes with the literal 0x8100.
;          ★ NOTE-OFF IS A LINEAR SEARCH for the slot whose remembered byte equals
;          note|0x80 (`set 7,H` at 0xFC3F47, `cp A,H` at 0xFC3F63) and writes a
;          DIFFERENT pair to the same two blocks: chan+0x0840 = 0xA200 (0xFC3F74) and
;          chan+0x0800 = 0xA280 (0xFC3F8B).
; Unknown:  ⚠ WHAT THE SEVEN VARIANTS ARE, and what sends these packets.  They arrive
;          over link channel 0 from CPU 1, so the names live in prom_a; nothing in
;          prom_c spells 0xF0..0xF6 as a part selector anywhere else.
;          ⚠ Whether 0xA200/0xA280 is a release envelope or a second quiescent state.
;          Nothing in this image reads either register back.
; --------------------------------------------------------------------------
NotePool8_NoteOnOff:
	link32 0xEE, 0x0C, 0x8E, 0xFF              ; FC3E02  link XIZ,0xff8e
	pushw	hl                                   ; FC3E06  push HL
	pushw	de                                   ; FC3E07  push DE
	pushw	ix                                   ; FC3E08  push IX
	ld	xbc, (xiz+8)                            ; FC3E09  ld XBC,(XIZ+0x08)
	ld	h, (xbc+1)                              ; FC3E0C  ld H,(XBC+0x01)
	cp	h, 0xF0                                 ; FC3E0F  cp H,0xf0
	jrl c, NotePool8_NoteOnOff__FC3FA8                  ; FC3E12  jrl C,0xfc3fa8
	ld	l, h                                    ; FC3E15  ld L,H
	and	l, 15                                  ; FC3E17  and L,0x0f
	cps	l, 6                                   ; FC3E1A  cp L,6
	jr ule, NotePool8_NoteOnOff__FC3E20                 ; FC3E1C  jr ULE,0xfc3e20
	ldb	l, 0                                   ; FC3E1E  ld L,0x00
NotePool8_NoteOnOff__FC3E20:
	ldb_da	c, (0xE005)                         ; FC3E20  ld C,(0x00e005)
	inc	1, c                                   ; FC3E25  inc 1,C
	and	c, 7                                   ; FC3E27  and C,0x07
	stb_da	(0xE005), c                         ; FC3E2A  ld (0x00e005),C
	ld	xbc, (xiz+8)                            ; FC3E2F  ld XBC,(XIZ+0x08)
	ld	d, (xbc+3)                              ; FC3E32  ld D,(XBC+0x03)
	res	7, d                                   ; FC3E35  res 0x07,D
	ld	h, (xbc+2)                              ; FC3E38  ld H,(XBC+0x02)
	res	7, h                                   ; FC3E3B  res 0x07,H
	cps	d, 0                                   ; FC3E3E  cp D,0
	jrl z, NotePool8_NoteOnOff__FC3F47                  ; FC3E40  jrl Z,0xfc3f47
	ld	wa, (0xE005:24)                        ; FC3E43  ld WA,(0x00e005)
	extz	wa                                    ; FC3E48  extz WA
	ld	ix, wa                                  ; FC3E4A  ld IX,WA
	add	ix, 0x840                              ; FC3E4C  add IX,0x0840
	ld	xwa, 0x10C000                           ; FC3E50  ld XWA,0x0010c000
	ld	(xiz-0x72), xwa                         ; FC3E55  ld (XIZ+0x8e),XWA
	ld	(xwa), ix                               ; FC3E58  ld (XWA),IX
	ld	xbc, (xiz-0x72)                         ; FC3E5A  ld XBC,(XIZ+0x8e)
	extpfx5 0xB9, 0x02, 0x02, 0x00, 0xFF       ; FC3E5D  ld (XBC+0x02),0xff00
	nop                                        ; FC3E62  nop
	nop                                        ; FC3E63  nop
	nop                                        ; FC3E64  nop
	nop                                        ; FC3E65  nop
	nop                                        ; FC3E66  nop
	ld	bc, (0xE005:24)                        ; FC3E67  ld BC,(0x00e005)
	extz	bc                                    ; FC3E6C  extz BC
	ld	ix, bc                                  ; FC3E6E  ld IX,BC
	add	ix, 0x800                              ; FC3E70  add IX,0x0800
	ld	xbc, 0x10C000                           ; FC3E74  ld XBC,0x0010c000
	ld	(xiz-0x72), xbc                         ; FC3E79  ld (XIZ+0x8e),XBC
	ld	(xbc), ix                               ; FC3E7C  ld (XBC),IX
	ld	xbc, (xiz-0x72)                         ; FC3E7E  ld XBC,(XIZ+0x8e)
	extpfx5 0xB9, 0x02, 0x02, 0x80, 0xFF       ; FC3E81  ld (XBC+0x02),0xff80
	lda	xbc, (xiz-42)                          ; FC3E86  lda XBC,XIZ+0xd6
	push	xbc                                   ; FC3E89  push XBC
	push	0                                     ; FC3E8A  push 0x00
	extpfx5 0xC2, 0x05, 0xE0, 0x00, 0x04       ; FC3E8C  push (0x00e005)
	call	0xFC7DAF                              ; FC3E91  call 0xfc7daf
	lda	xbc, (xiz-42)                          ; FC3E95  lda XBC,XIZ+0xd6
	push	xbc                                   ; FC3E98  push XBC
	ld	wa, (0xE005:24)                        ; FC3E99  ld WA,(0x00e005)
	extz	wa                                    ; FC3E9E  extz WA
	pushw	wa                                   ; FC3EA0  push WA
	call	0xFB7A58                              ; FC3EA1  call 0xfb7a58
	lda	xbc, (xiz-42)                          ; FC3EA5  lda XBC,XIZ+0xd6
	push	xbc                                   ; FC3EA8  push XBC
	call	0xFC571A                              ; FC3EA9  call 0xfc571a
	ldw (xiz-32), 0x8000                       ; FC3EAD  ld (XIZ+0xe0),0x8000
	ldw (xiz-30), 0x0000                       ; FC3EB2  ld (XIZ+0xe2),0x0000
	ldw (xiz-20), 0x8000                       ; FC3EB7  ld (XIZ+0xec),0x8000
	ldw (xiz-22), 0x0000                       ; FC3EBC  ld (XIZ+0xea),0x0000
	lda	xbc, (xiz-42)                          ; FC3EC1  lda XBC,XIZ+0xd6
	push	xbc                                   ; FC3EC4  push XBC
	ld	wa, (0xE005:24)                        ; FC3EC5  ld WA,(0x00e005)
	extz	wa                                    ; FC3ECA  extz WA
	pushw	wa                                   ; FC3ECC  push WA
	call	0xFB77EF                              ; FC3ECD  call 0xfb77ef
	pushw	68                                   ; FC3ED1  push 0x0044
	lda	xbc, (xiz-0x6E)                        ; FC3ED4  lda XBC,XIZ+0x92
	push	xbc                                   ; FC3ED7  push XBC
	lda	xwa, (0xFE1540:24)                     ; FC3ED8  lda XWA,0xfe1540
	push	xwa                                   ; FC3EDD  push XWA
	call	0xF9A038                              ; FC3EDE  call 0xf9a038
	add	xsp, 32                                ; FC3EE2  add XSP,0x00000020
	lda	xbc, (xiz-0x6E)                        ; FC3EE8  lda XBC,XIZ+0x92
	push	xbc                                   ; FC3EEB  push XBC
	cps	l, 1                                   ; FC3EEC  cp L,1
	jr nz, NotePool8_NoteOnOff__FC3EFB                  ; FC3EEE  jr NZ,0xfc3efb
	push	0                                     ; FC3EF0  push 0x00
	push	h                                     ; FC3EF2  push H
	calr (0xFC3DAF - 0xFC3EF7)                 ; FC3EF4  calr 0xfc3daf
	inc	6, xsp                                 ; FC3EF7  inc 6,XSP
	jr NotePool8_NoteOnOff__FC3F0B                      ; FC3EF9  jr T,0xfc3f0b
NotePool8_NoteOnOff__FC3EFB:
	push	0                                     ; FC3EFB  push 0x00
	push	d                                     ; FC3EFD  push D
	push	0                                     ; FC3EFF  push 0x00
	push	h                                     ; FC3F01  push H
	pushw	hl                                   ; FC3F03  push HL
	calr (0xFC3D26 - 0xFC3F07)                 ; FC3F04  calr 0xfc3d26
	inc	8, xsp                                 ; FC3F07  inc 0,XSP
	inc	2, xsp                                 ; FC3F09  inc 2,XSP
NotePool8_NoteOnOff__FC3F0B:
	lda	xbc, (xiz-0x6E)                        ; FC3F0B  lda XBC,XIZ+0x92
	push	xbc                                   ; FC3F0E  push XBC
	ld	wa, (0xE005:24)                        ; FC3F0F  ld WA,(0x00e005)
	extz	wa                                    ; FC3F14  extz WA
	pushw	wa                                   ; FC3F16  push WA
	call	0xFB713A                              ; FC3F17  call 0xfb713a
	ld	bc, (xiz-0x6E)                          ; FC3F1B  ld BC,(XIZ+0x92)
	pushw	bc                                   ; FC3F1E  push BC
	ld	bc, (0xE005:24)                        ; FC3F1F  ld BC,(0x00e005)
	extz	bc                                    ; FC3F24  extz BC
	pushw	bc                                   ; FC3F26  push BC
	call	0xFB732C                              ; FC3F27  call 0xfb732c
	ld	l, h                                    ; FC3F2B  ld L,H
	set	7, l                                   ; FC3F2D  set 0x07,L
	ld	bc, (0xE005:24)                        ; FC3F30  ld BC,(0x00e005)
	extz	bc                                    ; FC3F35  extz BC
	extz	xbc                                   ; FC3F37  extz XBC
	add	xbc, 0xE006                            ; FC3F39  add XBC,0x0000e006
	ld	(xbc), l                                ; FC3F3F  ld (XBC),L
	inc	8, xsp                                 ; FC3F41  inc 0,XSP
	inc	2, xsp                                 ; FC3F43  inc 2,XSP
	jr NotePool8_NoteOnOff__FC3FA8                      ; FC3F45  jr T,0xfc3fa8
NotePool8_NoteOnOff__FC3F47:
	set	7, h                                   ; FC3F47  set 0x07,H
	ldb	l, 0                                   ; FC3F4A  ld L,0x00
	ldw	de, 0x840                              ; FC3F4C  ld DE,0x0840
	ldw	ix, 0x800                              ; FC3F4F  ld IX,0x0800
NotePool8_NoteOnOff__FC3F52:
	ld	c, l                                    ; FC3F52  ld C,L
	extz	bc                                    ; FC3F54  extz BC
	extz	xbc                                   ; FC3F56  extz XBC
	ld	(xiz-4), xbc                            ; FC3F58  ld (XIZ+0xfc),XBC
	add	xbc, 0xE006                            ; FC3F5B  add XBC,0x0000e006
	ld	a, (xbc)                                ; FC3F61  ld A,(XBC)
	cp	a, h                                    ; FC3F63  cp A,H
	jr nz, NotePool8_NoteOnOff__FC3F9D                  ; FC3F65  jr NZ,0xfc3f9d
	ld	xbc, 0x10C000                           ; FC3F67  ld XBC,0x0010c000
	ld	(xiz-0x72), xbc                         ; FC3F6C  ld (XIZ+0x8e),XBC
	ld	(xbc), de                               ; FC3F6F  ld (XBC),DE
	ld	xbc, (xiz-0x72)                         ; FC3F71  ld XBC,(XIZ+0x8e)
	extpfx5 0xB9, 0x02, 0x02, 0x00, 0xA2       ; FC3F74  ld (XBC+0x02),0xa200
	nop                                        ; FC3F79  nop
	nop                                        ; FC3F7A  nop
	nop                                        ; FC3F7B  nop
	nop                                        ; FC3F7C  nop
	nop                                        ; FC3F7D  nop
	ld	xbc, 0x10C000                           ; FC3F7E  ld XBC,0x0010c000
	ld	(xiz-0x72), xbc                         ; FC3F83  ld (XIZ+0x8e),XBC
	ld	(xbc), ix                               ; FC3F86  ld (XBC),IX
	ld	xbc, (xiz-0x72)                         ; FC3F88  ld XBC,(XIZ+0x8e)
	extpfx5 0xB9, 0x02, 0x02, 0x80, 0xA2       ; FC3F8B  ld (XBC+0x02),0xa280
	lda	xbc, (0xE006:24)                       ; FC3F90  lda XBC,0x00e006
	extpfx3 0xAE, 0xFC, 0x81                   ; FC3F95  add XBC,(XIZ+0xfc)
	extpfx3 0x81, 0x3C, 0x7F                   ; FC3F98  and (XBC),0x7f
	jr NotePool8_NoteOnOff__FC3FA8                      ; FC3F9B  jr T,0xfc3fa8
NotePool8_NoteOnOff__FC3F9D:
	inc	1, de                                  ; FC3F9D  inc 1,DE
	inc	1, ix                                  ; FC3F9F  inc 1,IX
	inc	1, l                                   ; FC3FA1  inc 1,L
	cp	l, 8                                    ; FC3FA3  cp L,0x08
	jr c, NotePool8_NoteOnOff__FC3F52                   ; FC3FA6  jr C,0xfc3f52
NotePool8_NoteOnOff__FC3FA8:
	popw	ix                                    ; FC3FA8  pop IX
	popw	de                                    ; FC3FA9  pop DE
	popw	hl                                    ; FC3FAA  pop HL
	unlk32 xiz                                 ; FC3FAB  unlk XIZ
	ret                                        ; FC3FAD  ret
; --------------------------------------------------------------------------
; sub_FC3FAE -- 0xFC3FAE..0xFC405D (176 bytes)
;
; Called from: no site outside this module.
;          3 site(s) inside this module:
;          0xFC4093 0xFC40C9 0xFC411F
; Inputs:  frame `link XIZ,-2`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFC3FAE-0xFC405D
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC3FAE:
	link32 0xEE, 0x0C, 0xFE, 0xFF              ; FC3FAE  link XIZ,0xfffe
	push	xhl                                   ; FC3FB2  push XHL
	push	xde                                   ; FC3FB3  push XDE
	push	xix                                   ; FC3FB4  push XIX
	ld	de, (xiz+8)                             ; FC3FB5  ld DE,(XIZ+0x08)
	extz	xde                                   ; FC3FB8  extz XDE
	ld	c, (xde+4)                              ; FC3FBA  ld C,(XDE+0x04)
	mul	c, 2                                   ; FC3FBD  mul C,0x02
	extz	xbc                                   ; FC3FC0  extz XBC
	ld	xix, xbc                                ; FC3FC2  ld XIX,XBC
	add	xbc, 0xE00E                            ; FC3FC4  add XBC,0x0000e00e
	ld	bc, (xbc)                               ; FC3FCA  ld BC,(XBC)
	cp	bc, de                                  ; FC3FCC  cp BC,DE
	jr nz, sub_FC3FAE__FC3FEE                  ; FC3FCE  jr NZ,0xfc3fee
	extz	xde                                   ; FC3FD0  extz XDE
	ld	hl, (xde)                               ; FC3FD2  ld HL,(XDE)
	cp	hl, de                                  ; FC3FD4  cp HL,DE
	jr z, sub_FC3FAE__FC3FE3                   ; FC3FD6  jr Z,0xfc3fe3
	lda	xbc, (0xE00E:24)                       ; FC3FD8  lda XBC,0x00e00e
	add	xbc, xix                               ; FC3FDD  add XBC,XIX
	ld	(xbc), hl                               ; FC3FDF  ld (XBC),HL
	jr sub_FC3FAE__FC3FEE                      ; FC3FE1  jr T,0xfc3fee
sub_FC3FAE__FC3FE3:
	sub	bc, bc                                 ; FC3FE3  sub BC,BC
	lda	xwa, (0xE00E:24)                       ; FC3FE5  lda XWA,0x00e00e
	add	xwa, xix                               ; FC3FEA  add XWA,XIX
	ld	(xwa), bc                               ; FC3FEC  ld (XWA),BC
sub_FC3FAE__FC3FEE:
	ldb	c, 2                                   ; FC3FEE  ld C,0x02
	extpfx3 0x8E, 0x0A, 0x43                   ; FC3FF0  mul BC,(XIZ+0x0a)
	extz	xbc                                   ; FC3FF3  extz XBC
	ld	xix, xbc                                ; FC3FF5  ld XIX,XBC
	add	xbc, 0xE00E                            ; FC3FF7  add XBC,0x0000e00e
	ld	hl, (xbc)                               ; FC3FFD  ld HL,(XBC)
	sub	bc, bc                                 ; FC3FFF  sub BC,BC
	cp	hl, bc                                  ; FC4001  cp HL,BC
	jr nz, sub_FC3FAE__FC4029                  ; FC4003  jr NZ,0xfc4029
	lda	xbc, (0xE00E:24)                       ; FC4005  lda XBC,0x00e00e
	add	xbc, xix                               ; FC400A  add XBC,XIX
	ld	(xbc), de                               ; FC400C  ld (XBC),DE
	ld	hl, (xde)                               ; FC400E  ld HL,(XDE)
	ld	bc, (xde+2)                             ; FC4010  ld BC,(XDE+0x02)
	ld	(xiz-2), bc                             ; FC4013  ld (XIZ+0xfe),BC
	extz	xbc                                   ; FC4016  extz XBC
	ld	(xbc), hl                               ; FC4018  ld (XBC),HL
	extz	xhl                                   ; FC401A  extz XHL
	ld	bc, (xiz-2)                             ; FC401C  ld BC,(XIZ+0xfe)
	ld	(xhl+2), bc                             ; FC401F  ld (XHL+0x02),BC
	ld	(xde), de                               ; FC4022  ld (XDE),DE
	ld	(xde+2), de                             ; FC4024  ld (XDE+0x02),DE
	jr sub_FC3FAE__FC4050                      ; FC4027  jr T,0xfc4050
sub_FC3FAE__FC4029:
	extz	xde                                   ; FC4029  extz XDE
	ld	ix, (xde)                               ; FC402B  ld IX,(XDE)
	ld	bc, (xde+2)                             ; FC402D  ld BC,(XDE+0x02)
	ld	(xiz-2), bc                             ; FC4030  ld (XIZ+0xfe),BC
	extz	xbc                                   ; FC4033  extz XBC
	ld	(xbc), ix                               ; FC4035  ld (XBC),IX
	extz	xix                                   ; FC4037  extz XIX
	ld	bc, (xiz-2)                             ; FC4039  ld BC,(XIZ+0xfe)
	ld	(xix+2), bc                             ; FC403C  ld (XIX+0x02),BC
	extz	xhl                                   ; FC403F  extz XHL
	ld	ix, (xhl+2)                             ; FC4041  ld IX,(XHL+0x02)
	extz	xix                                   ; FC4044  extz XIX
	ld	(xix), de                               ; FC4046  ld (XIX),DE
	ld	(xhl+2), de                             ; FC4048  ld (XHL+0x02),DE
	ld	(xde), hl                               ; FC404B  ld (XDE),HL
	ld	(xde+2), ix                             ; FC404D  ld (XDE+0x02),IX
sub_FC3FAE__FC4050:
	extz	xde                                   ; FC4050  extz XDE
	ld	c, (xiz+10)                             ; FC4052  ld C,(XIZ+0x0a)
	ld	(xde+4), c                              ; FC4055  ld (XDE+0x04),C
	pop	xix                                    ; FC4058  pop XIX
	pop	xde                                    ; FC4059  pop XDE
	pop	xhl                                    ; FC405A  pop XHL
	unlk32 xiz                                 ; FC405B  unlk XIZ
	ret                                        ; FC405D  ret
; --------------------------------------------------------------------------
; sub_FC405E -- 0xFC405E..0xFC40A8 (75 bytes)
;
; Called from: no site outside this module.
;          2 site(s) inside this module:
;          0xFC4D1E 0xFC7DE0
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
;          reads 0x00E00E, 0x00E010
; Calls:   0xFC3FAE = sub_FC3FAE
; Evidence: the listing below is the byte-identical round-trip of 0xFC405E-0xFC40A8
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC405E:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC405E  link XIZ,0x0000
	push	xhl                                   ; FC4062  push XHL
	pushw	de                                   ; FC4063  push DE
	cp (xiz+8), 0x40                           ; FC4064  cp (XIZ+0x08),0x40
	jr nc, sub_FC405E__FC407D                  ; FC4068  jr NC,0xfc407d
	ldb	c, 7                                   ; FC406A  ld C,0x07
	extpfx3 0x8E, 0x08, 0x43                   ; FC406C  mul BC,(XIZ+0x08)
	ld	de, bc                                  ; FC406F  ld DE,BC
	ldw	hl, 0x5B63                             ; FC4071  ld HL,0x5b63
	add	hl, bc                                 ; FC4074  add HL,BC
	extz	xhl                                   ; FC4076  extz XHL
	incm8	1, (xhl+6)                           ; FC4078  inc 1,(XHL+0x06)
	jr sub_FC405E__FC409D                      ; FC407B  jr T,0xfc409d
sub_FC405E__FC407D:
	ld	de, (0xE00E:24)                        ; FC407D  ld DE,(0x00e00e)
	ld	hl, (0xE010:24)                        ; FC4082  ld HL,(0x00e010)
	sub	bc, bc                                 ; FC4087  sub BC,BC
	cp	de, bc                                  ; FC4089  cp DE,BC
	jr z, sub_FC405E__FC408F                   ; FC408B  jr Z,0xfc408f
	ld	hl, de                                  ; FC408D  ld HL,DE
sub_FC405E__FC408F:
	pushw	1                                    ; FC408F  push 0x0001
	pushw	hl                                   ; FC4092  push HL
	calr (0xFC3FAE - 0xFC4096)                 ; FC4093  calr 0xfc3fae
	extz	xhl                                   ; FC4096  extz XHL
	ld	(xhl+6), 1                              ; FC4098  ld (XHL+0x06),0x01
	pop	xiy                                    ; FC409C  pop XIY
sub_FC405E__FC409D:
	extz	xhl                                   ; FC409D  extz XHL
	ld	c, (xhl+5)                              ; FC409F  ld C,(XHL+0x05)
	ld	a, c                                    ; FC40A2  ld A,C
	popw	de                                    ; FC40A4  pop DE
	pop	xhl                                    ; FC40A5  pop XHL
	unlk32 xiz                                 ; FC40A6  unlk XIZ
	ret                                        ; FC40A8  ret
; --------------------------------------------------------------------------
; sub_FC40A9 -- 0xFC40A9..0xFC40E5 (61 bytes)
;
; Called from: no site outside this module.
;          2 site(s) inside this module:
;          0xFC4CF0 0xFC7DD9
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFC3FAE = sub_FC3FAE
; Evidence: the listing below is the byte-identical round-trip of 0xFC40A9-0xFC40E5
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC40A9:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC40A9  link XIZ,0x0000
	push	xhl                                   ; FC40AD  push XHL
	pushw	de                                   ; FC40AE  push DE
	pushw	ix                                   ; FC40AF  push IX
	ldb	c, 7                                   ; FC40B0  ld C,0x07
	extpfx3 0x8E, 0x08, 0x43                   ; FC40B2  mul BC,(XIZ+0x08)
	ld	ix, bc                                  ; FC40B5  ld IX,BC
	ldw	hl, 0x5B63                             ; FC40B7  ld HL,0x5b63
	add	hl, bc                                 ; FC40BA  add HL,BC
	extz	xhl                                   ; FC40BC  extz XHL
	ld	d, (xhl+6)                              ; FC40BE  ld D,(XHL+0x06)
	cps	d, 1                                   ; FC40C1  cp D,1
	jr nz, sub_FC40A9__FC40D3                  ; FC40C3  jr NZ,0xfc40d3
	pushw	0                                    ; FC40C5  push 0x0000
	pushw	hl                                   ; FC40C8  push HL
	calr (0xFC3FAE - 0xFC40CC)                 ; FC40C9  calr 0xfc3fae
	ld	(xhl+6), 0                              ; FC40CC  ld (XHL+0x06),0x00
	pop	xiy                                    ; FC40D0  pop XIY
	jr sub_FC40A9__FC40E0                      ; FC40D1  jr T,0xfc40e0
sub_FC40A9__FC40D3:
	cps	d, 1                                   ; FC40D3  cp D,1
	jr le, sub_FC40A9__FC40E0                  ; FC40D5  jr LE,0xfc40e0
	ld	c, d                                    ; FC40D7  ld C,D
	dec	1, c                                   ; FC40D9  dec 1,C
	extz	xhl                                   ; FC40DB  extz XHL
	ld	(xhl+6), c                              ; FC40DD  ld (XHL+0x06),C
sub_FC40A9__FC40E0:
	popw	ix                                    ; FC40E0  pop IX
	popw	de                                    ; FC40E1  pop DE
	pop	xhl                                    ; FC40E2  pop XHL
	unlk32 xiz                                 ; FC40E3  unlk XIZ
	ret                                        ; FC40E5  ret
; --------------------------------------------------------------------------
; sub_FC40E6 -- 0xFC40E6..0xFC412D (72 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFC7D00
; Inputs:  no frame and no argument slot read.
; Outputs: writes 0x00E00E, 0x00E010
; Calls:   0xFC3FAE = sub_FC3FAE
; Evidence: the listing below is the byte-identical round-trip of 0xFC40E6-0xFC412D
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC40E6:
	pushw	hl                                   ; FC40E6  push HL
	push	xde                                   ; FC40E7  push XDE
	sub	bc, bc                                 ; FC40E8  sub BC,BC
	stw_da	(0xE00E), bc                        ; FC40EA  ld (0x00e00e),BC
	sub	bc, bc                                 ; FC40EF  sub BC,BC
	stw_da	(0xE010), bc                        ; FC40F1  ld (0x00e010),BC
	ldw	de, 0x5B63                             ; FC40F6  ld DE,0x5b63
	ldb	h, 0                                   ; FC40F9  ld H,0x00
sub_FC40E6__FC40FB:
	extz	xde                                   ; FC40FB  extz XDE
	ld	(xde+5), h                              ; FC40FD  ld (XDE+0x05),H
	ld	(xde), de                               ; FC4100  ld (XDE),DE
	ld	(xde+2), de                             ; FC4102  ld (XDE+0x02),DE
	ld	(xde+4), 0                              ; FC4105  ld (XDE+0x04),0x00
	ld	(xde+6), 0                              ; FC4109  ld (XDE+0x06),0x00
	inc	7, de                                  ; FC410D  inc 7,DE
	inc	1, h                                   ; FC410F  inc 1,H
	cp	h, 64                                   ; FC4111  cp H,0x40
	jr c, sub_FC40E6__FC40FB                   ; FC4114  jr C,0xfc40fb
	ldw	de, 0x5B63                             ; FC4116  ld DE,0x5b63
	ldb	h, 64                                  ; FC4119  ld H,0x40
sub_FC40E6__FC411B:
	pushw	0                                    ; FC411B  push 0x0000
	pushw	de                                   ; FC411E  push DE
	calr (0xFC3FAE - 0xFC4122)                 ; FC411F  calr 0xfc3fae
	inc	7, de                                  ; FC4122  inc 7,DE
	dec	1, h                                   ; FC4124  dec 1,H
	pop	xiy                                    ; FC4126  pop XIY
	cps	h, 0                                   ; FC4127  cp H,0
	jr nz, sub_FC40E6__FC411B                  ; FC4129  jr NZ,0xfc411b
	pop	xde                                    ; FC412B  pop XDE
	popw	hl                                    ; FC412C  pop HL
	ret                                        ; FC412D  ret
; --------------------------------------------------------------------------
; Multiply16_Signed_Shr11 -- 0xFC412E..0xFC413F (18 bytes)
;             signed 16x16 multiply with an arithmetic right shift of 11 -- a Q11 fixed-
;             point product.
;             (★ NAMED in wave 7 round 2; was `sub_FC412E`.)
;
; Called from: no site outside this module.
;          15 site(s) inside this module:
;          0xFC430C 0xFC432C 0xFC439A 0xFC4403 0xFC4475 0xFC44A1
;          0xFC458D 0xFC4592 0xFC45A7 0xFC45AC 0xFC45BD 0xFC45CE
;          0xFC45E6 0xFC45FB 0xFC465C
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: ★ the routine is 18 bytes and FOUR instructions; there is nothing else in it:
;              0xFC4132  ld BC,(XIZ+0x08)          -- first argument, 16 bits
;              0xFC4135  muls XBC,(XIZ+0x0a)       -- SIGNED 16x16 -> 32 into XBC
;              0xFC4138  sra 0x0b,XBC              -- ARITHMETIC right shift of 11
;              0xFC413B  ld WA,BC                  -- the low 16 bits are the result
;          Both the signedness and the shift are instruction opcodes, not readings:
;          `muls` against `mul`, and `sra` against `srl`.  The ROM bytes are `ee 0c 00
;          00 9e 08 21 9e 0a 49 e9 ed 0b d9 88 ee 0d 0e`.
; Unknown:  ⚠ what the two factors ARE.  All 15 call sites are inside this module; none
;          was traced to a named quantity, so the name states the arithmetic and nothing
;          more.
;          ⚠ the truncation to 16 bits at 0xFC413B discards the product's high half
;          without a saturation or an overflow test, so the caller must guarantee the
;          range.  No caller was checked for that.
; --------------------------------------------------------------------------
Multiply16_Signed_Shr11:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC412E  link XIZ,0x0000
	ld	bc, (xiz+8)                             ; FC4132  ld BC,(XIZ+0x08)
	extpfx3 0x9E, 0x0A, 0x49                   ; FC4135  muls XBC,(XIZ+0x0a)
	sra	xbc, 11                                ; FC4138  sra 0x0b,XBC
	ld	wa, bc                                  ; FC413B  ld WA,BC
	unlk32 xiz                                 ; FC413D  unlk XIZ
	ret                                        ; FC413F  ret
; --------------------------------------------------------------------------
; sub_FC4140 -- 0xFC4140..0xFC419C (93 bytes)
;
; Called from: no site outside this module.
;          2 site(s) inside this module:
;          0xFC463A 0xFC4645
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Calls:   0xFCB141 = Divide32_Signed
; Evidence: the listing below is the byte-identical round-trip of 0xFC4140-0xFC419C
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC4140:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FC4140  link XIZ,0xfffc
	pushw	hl                                   ; FC4144  push HL
	pushw	de                                   ; FC4145  push DE
	pushw	ix                                   ; FC4146  push IX
	ld	ix, (xiz+8)                             ; FC4147  ld IX,(XIZ+0x08)
	ld	de, (xiz+10)                            ; FC414A  ld DE,(XIZ+0x0a)
	ld	bc, ix                                  ; FC414D  ld BC,IX
	exts	xbc                                   ; FC414F  exts XBC
	sll	xbc, 11                                ; FC4151  sll 0x0b,XBC
	ld	(xiz-4), xbc                            ; FC4154  ld (XIZ+0xfc),XBC
	ld	wa, de                                  ; FC4157  ld WA,DE
	exts	xwa                                   ; FC4159  exts XWA
	push	xwa                                   ; FC415B  push XWA
	push	xbc                                   ; FC415C  push XBC
	call	0xFCB141                              ; FC415D  call 0xfcb141
	ld	hl, iy                                  ; FC4161  ld HL,IY
	cps	iy, 0                                  ; FC4163  cp IY,0
	jr ge, sub_FC4140__FC417C                  ; FC4165  jr GE,0xfc417c
	cps	ix, 0                                  ; FC4167  cp IX,0
	jr le, sub_FC4140__FC416F                  ; FC4169  jr LE,0xfc416f
	cps	de, 0                                  ; FC416B  cp DE,0
	jr gt, sub_FC4140__FC4177                  ; FC416D  jr GT,0xfc4177
sub_FC4140__FC416F:
	cps	ix, 0                                  ; FC416F  cp IX,0
	jr ge, sub_FC4140__FC4195                  ; FC4171  jr GE,0xfc4195
	cps	de, 0                                  ; FC4173  cp DE,0
	jr ge, sub_FC4140__FC4195                  ; FC4175  jr GE,0xfc4195
sub_FC4140__FC4177:
	ldw	wa, 0x7FFF                             ; FC4177  ld WA,0x7fff
	jr sub_FC4140__FC4197                      ; FC417A  jr T,0xfc4197
sub_FC4140__FC417C:
	cps	hl, 0                                  ; FC417C  cp HL,0
	jr le, sub_FC4140__FC4195                  ; FC417E  jr LE,0xfc4195
	cps	ix, 0                                  ; FC4180  cp IX,0
	jr le, sub_FC4140__FC4188                  ; FC4182  jr LE,0xfc4188
	cps	de, 0                                  ; FC4184  cp DE,0
	jr lt, sub_FC4140__FC4190                  ; FC4186  jr LT,0xfc4190
sub_FC4140__FC4188:
	cps	ix, 0                                  ; FC4188  cp IX,0
	jr le, sub_FC4140__FC4195                  ; FC418A  jr LE,0xfc4195
	cps	de, 0                                  ; FC418C  cp DE,0
	jr ge, sub_FC4140__FC4195                  ; FC418E  jr GE,0xfc4195
sub_FC4140__FC4190:
	ldw	wa, 0x8000                             ; FC4190  ld WA,0x8000
	jr sub_FC4140__FC4197                      ; FC4193  jr T,0xfc4197
sub_FC4140__FC4195:
	ld	wa, hl                                  ; FC4195  ld WA,HL
sub_FC4140__FC4197:
	popw	ix                                    ; FC4197  pop IX
	popw	de                                    ; FC4198  pop DE
	popw	hl                                    ; FC4199  pop HL
	unlk32 xiz                                 ; FC419A  unlk XIZ
	ret                                        ; FC419C  ret
; --------------------------------------------------------------------------
; Math_Sin_Q11 -- 0xFC419D..0xFC41C2 (38 bytes)
;
; Called from: no site outside this module.
;          3 site(s) inside this module:
;          0xFC444E 0xFC4579 0xFC45F1
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFCAB06 = Shift32_ArithRight
; Evidence: the listing below is the byte-identical round-trip of 0xFC419D-0xFC41C2
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Name:    ★ SINE IN Q11 FIXED POINT.  The argument is an angle in units of
;          1/2048 radian and the result is 2048 * sin(theta) in the same units.
;          index = (arg * 0x28BE) >> 19, and 0x28BE / 2^19 = 256 / (2*pi*2048) to
;          five digits, so the index is the angle scaled onto the 256-entry table
;          MathTable_Sin_S16_256 (0xFE06C9); `sra 4` on a 32767-amplitude entry is
;          the same 2048 = 1.0 scale as the input.
; Evidence: notes/gen_prom_c_tail_tables.py --verify checks the table against
;          round(32767*sin(2*pi*k/256)) over all 256 entries (err in [-4,+8]), and
;          its ONLY caller agrees about the scale independently: at 0xFC445B the
;          caller forms 0x1922 - 2*arg, and 0x1922 = 6434 is exactly the argument
;          that maps to index 128 -- half the table, i.e. pi radians.
; Unknown:  ⚠ what the angle MEANS at the call sites (three, all in sub_FC4269).
; --------------------------------------------------------------------------
Math_Sin_Q11:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC419D  link XIZ,0x0000
	ldw	bc, 0x28BE                             ; FC41A1  ld BC,0x28be
	extpfx3 0x9E, 0x08, 0x49                   ; FC41A4  muls XBC,(XIZ+0x08)
	pushw	19                                   ; FC41A7  push 0x0013
	push	xbc                                   ; FC41AA  push XBC
	call	0xFCAB06                              ; FC41AB  call 0xfcab06
	muls	iy, 2                                 ; FC41AF  muls IY,0x0002
	add	xiy, 0xFE06C9                          ; FC41B3  add XIY,0x00fe06c9
	ld	bc, (xiy)                               ; FC41B9  ld BC,(XIY)
	sra	bc, 4                                  ; FC41BB  sra 0x04,BC
	ld	wa, bc                                  ; FC41BE  ld WA,BC
	unlk32 xiz                                 ; FC41C0  unlk XIZ
	ret                                        ; FC41C2  ret
; --------------------------------------------------------------------------
; Math_Cos_Q11 -- 0xFC41C3..0xFC41E8 (38 bytes)
;
; Called from: no site outside this module.
;          2 site(s) inside this module:
;          0xFC456A 0xFC45DC
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFCAB06 = Shift32_ArithRight
; Evidence: the listing below is the byte-identical round-trip of 0xFC41C3-0xFC41E8
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Name:    ★ COSINE IN Q11.  Byte for byte Math_Sin_Q11 with one operand changed:
;          the two routines are 38 bytes each and differ ONLY in the table address
;          (0xFE08C9 here, 0xFE06C9 there), so the scaling argument made there
;          holds here unchanged.
; Evidence: MathTable_Cos_S16_256 matches round(32768*cos(2*pi*k/256)) mod 2^16 over
;          all 256 entries, err in [-3,+6] (notes/gen_prom_c_tail_tables.py --verify).
; Unknown:  ⚠ AND ONE REAL DEFECT IN THE ROM: entry 0 of the cosine table is 0x8000,
;          which this routine's `ld BC,(XIY) / sra 4,BC` reads as -32768/16 = -2048.
;          cos(0) therefore comes back as -1.0, not +1.0: +1.0 does not fit the s16
;          the reader assumes.  Whether any caller passes 0 is not established.
; --------------------------------------------------------------------------
Math_Cos_Q11:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC41C3  link XIZ,0x0000
	ldw	bc, 0x28BE                             ; FC41C7  ld BC,0x28be
	extpfx3 0x9E, 0x08, 0x49                   ; FC41CA  muls XBC,(XIZ+0x08)
	pushw	19                                   ; FC41CD  push 0x0013
	push	xbc                                   ; FC41D0  push XBC
	call	0xFCAB06                              ; FC41D1  call 0xfcab06
	muls	iy, 2                                 ; FC41D5  muls IY,0x0002
	add	xiy, 0xFE08C9                          ; FC41D9  add XIY,0x00fe08c9
	ld	bc, (xiy)                               ; FC41DF  ld BC,(XIY)
	sra	bc, 4                                  ; FC41E1  sra 0x04,BC
	ld	wa, bc                                  ; FC41E4  ld WA,BC
	unlk32 xiz                                 ; FC41E6  unlk XIZ
	ret                                        ; FC41E8  ret
; --------------------------------------------------------------------------
; Math_Atan_Q11 -- 0xFC41E9..0xFC4226 (62 bytes)
;
; Called from: no site outside this module.
;          2 site(s) inside this module:
;          0xFC464B 0xFC4651
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFC41E9-0xFC4226
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Name:    ★ ARCTANGENT IN Q11, as an ODD function.  index = |arg| >> 7 into
;          MathTable_Atan_256 (0xFE0AC9), result = entry >> 3, then negated if the
;          argument was negative.  With arg in Q11, index/16 = arg/2048 = the Q11
;          value, and the table is 16384*atan(k/16), so the result is
;          2048 * atan(x): Q11 in, Q11 out, same as Math_Sin_Q11.
; Evidence: the table matches round(16384*atan(k/16)) over all 256 entries with an
;          error of -1 or 0 (notes/gen_prom_c_tail_tables.py --verify); the sign
;          handling is the `cp DE,0 / neg BC` pair at 0xFC41F4 and 0xFC4216.
; Unknown:  ⚠ what its two call sites (0xFC464B, 0xFC4651) are computing: they take
;          the DIFFERENCE of two atan results, which is the shape of an angle
;          between two vectors, and hand it on with a 0x0146 constant.
; --------------------------------------------------------------------------
Math_Atan_Q11:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC41E9  link XIZ,0x0000
	pushw	hl                                   ; FC41ED  push HL
	pushw	de                                   ; FC41EE  push DE
	ld	de, (xiz+8)                             ; FC41EF  ld DE,(XIZ+0x08)
	ld	hl, de                                  ; FC41F2  ld HL,DE
	cps	de, 0                                  ; FC41F4  cp DE,0
	jr ge, Math_Atan_Q11__FC41FE                  ; FC41F6  jr GE,0xfc41fe
	ld	bc, de                                  ; FC41F8  ld BC,DE
	neg	bc                                     ; FC41FA  neg BC
	ld	hl, bc                                  ; FC41FC  ld HL,BC
Math_Atan_Q11__FC41FE:
	ld	bc, hl                                  ; FC41FE  ld BC,HL
	sra	bc, 7                                  ; FC4200  sra 0x07,BC
	muls	bc, 2                                 ; FC4203  muls BC,0x0002
	add	xbc, 0xFE0AC9                          ; FC4207  add XBC,0x00fe0ac9
	ld	hl, (xbc)                               ; FC420D  ld HL,(XBC)
	ld	bc, hl                                  ; FC420F  ld BC,HL
	sra	bc, 3                                  ; FC4211  sra 0x03,BC
	ld	hl, bc                                  ; FC4214  ld HL,BC
	cps	de, 0                                  ; FC4216  cp DE,0
	jr ge, Math_Atan_Q11__FC4220                  ; FC4218  jr GE,0xfc4220
	neg	bc                                     ; FC421A  neg BC
	ld	wa, bc                                  ; FC421C  ld WA,BC
	jr Math_Atan_Q11__FC4222                      ; FC421E  jr T,0xfc4222
Math_Atan_Q11__FC4220:
	ld	wa, hl                                  ; FC4220  ld WA,HL
Math_Atan_Q11__FC4222:
	popw	de                                    ; FC4222  pop DE
	popw	hl                                    ; FC4223  pop HL
	unlk32 xiz                                 ; FC4224  unlk XIZ
	ret                                        ; FC4226  ret
; --------------------------------------------------------------------------
; Math_Exp2_Q11 -- 0xFC4227..0xFC4268 (66 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFC435E
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFCAA2F = Shift16_ArithRight
; Evidence: the listing below is the byte-identical round-trip of 0xFC4227-0xFC4268
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Name:    ★ 2^x IN Q11, scaled by 2*pi*1024.  index = (arg & 0x7FF) >> 3 -- the
;          FRACTIONAL part of a Q11 number -- into MathTable_Exp2_256 (0xFE0EC9);
;          result = entry >> 1; and for a negative argument the result is then
;          shifted right by |arg >> 11|, the integer part, through
;          Shift16_ArithRight.  The table is 12868 * 2^(k/256) and
;          12868 = round(2048 * 2*pi), so the value returned is 2*pi*1024 * 2^x.
; Evidence: the table matches that closed form over all 256 entries with an error
;          of -1 or 0 (notes/gen_prom_c_tail_tables.py --verify); the masks and
;          shifts are the operands at 0xFC4232, 0xFC4236, 0xFC4247 and 0xFC4252.
; Unknown:  ⚠ that the 2*pi factor makes it an ANGULAR FREQUENCY is a reading of the
;          constant, not something an instruction says.  ONE caller (0xFC435E).
; --------------------------------------------------------------------------
Math_Exp2_Q11:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC4227  link XIZ,0x0000
	pushw	hl                                   ; FC422B  push HL
	pushw	de                                   ; FC422C  push DE
	ld	de, (xiz+8)                             ; FC422D  ld DE,(XIZ+0x08)
	ld	bc, de                                  ; FC4230  ld BC,DE
	and	bc, 0x7FF                              ; FC4232  and BC,0x07ff
	sra	bc, 3                                  ; FC4236  sra 0x03,BC
	muls	bc, 2                                 ; FC4239  muls BC,0x0002
	add	xbc, 0xFE0EC9                          ; FC423D  add XBC,0x00fe0ec9
	ld	hl, (xbc)                               ; FC4243  ld HL,(XBC)
	ld	bc, hl                                  ; FC4245  ld BC,HL
	sra	bc, 1                                  ; FC4247  sra 0x01,BC
	ld	hl, bc                                  ; FC424A  ld HL,BC
	cps	de, 0                                  ; FC424C  cp DE,0
	jr ge, Math_Exp2_Q11__FC4262                  ; FC424E  jr GE,0xfc4262
	ld	iy, de                                  ; FC4250  ld IY,DE
	sra	iy, 11                                 ; FC4252  sra 0x0b,IY
	neg	iy                                     ; FC4255  neg IY
	extpfx3 0xC7, 0xF4, 0x89                   ; FC4257  ld A,IYL
	pushw	wa                                   ; FC425A  push WA
	pushw	bc                                   ; FC425B  push BC
	call	0xFCAA2F                              ; FC425C  call 0xfcaa2f
	jr Math_Exp2_Q11__FC4264                      ; FC4260  jr T,0xfc4264
Math_Exp2_Q11__FC4262:
	ld	wa, hl                                  ; FC4262  ld WA,HL
Math_Exp2_Q11__FC4264:
	popw	de                                    ; FC4264  pop DE
	popw	hl                                    ; FC4265  pop HL
	unlk32 xiz                                 ; FC4266  unlk XIZ
	ret                                        ; FC4268  ret
; --------------------------------------------------------------------------
; sub_FC4269 -- 0xFC4269..0xFC46A7 (1087 bytes)
;
; Called from: no site outside this module.
;          3 site(s) inside this module:
;          0xFC6F90 0xFC71BC 0xFC73FE
; Inputs:  frame `link XIZ,-80`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFC412E = Multiply16_Signed_Shr11, 0xFC4140 = sub_FC4140
;          0xFC419D = Math_Sin_Q11, 0xFC41C3 = Math_Cos_Q11
;          0xFC41E9 = Math_Atan_Q11, 0xFC4227 = Math_Exp2_Q11
; Evidence: the listing below is the byte-identical round-trip of 0xFC4269-0xFC46A7
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC4269:
	link32 0xEE, 0x0C, 0xB0, 0xFF              ; FC4269  link XIZ,0xffb0
	pushw	hl                                   ; FC426D  push HL
	pushw	de                                   ; FC426E  push DE
	push	xix                                   ; FC426F  push XIX
	ld	xbc, (xiz+8)                            ; FC4270  ld XBC,(XIZ+0x08)
	ld	wa, (xbc+2)                             ; FC4273  ld WA,(XBC+0x02)
	ld	(xiz-72), wa                            ; FC4276  ld (XIZ+0xb8),WA
	ld	iy, (xbc)                               ; FC4279  ld IY,(XBC)
	ld	(xiz-74), iy                            ; FC427B  ld (XIZ+0xb6),IY
	ldw (xiz-76), 0x0000                       ; FC427E  ld (XIZ+0xb4),0x0000
	cps	wa, 0                                  ; FC4283  cp WA,0
	jrl le, sub_FC4269__FC46A2                 ; FC4285  jrl LE,0xfc46a2
	ld	xbc, 36                                 ; FC4288  ld XBC,0x00000024
	ld	(xiz-66), xbc                           ; FC428D  ld (XIZ+0xbe),XBC
	ld	xbc, 20                                 ; FC4290  ld XBC,0x00000014
	ld	(xiz-70), xbc                           ; FC4295  ld (XIZ+0xba),XBC
	lda	xbc, (0xE012:24)                       ; FC4298  lda XBC,0x00e012
	ld	(xiz-62), xbc                           ; FC429D  ld (XIZ+0xc2),XBC
	sub	xbc, xbc                               ; FC42A0  sub XBC,XBC
	ld	(xiz-54), xbc                           ; FC42A2  ld (XIZ+0xca),XBC
	ld	xbc, 52                                 ; FC42A5  ld XBC,0x00000034
	ld	(xiz-58), xbc                           ; FC42AA  ld (XIZ+0xc6),XBC
sub_FC4269__FC42AD:
	ldw (xiz-50), 0x0000                       ; FC42AD  ld (XIZ+0xce),0x0000
	ldw (xiz-48), 0x0000                       ; FC42B2  ld (XIZ+0xd0),0x0000
	ldw (xiz-42), 0x0000                       ; FC42B7  ld (XIZ+0xd6),0x0000
	ldw (xiz-40), 0x0000                       ; FC42BC  ld (XIZ+0xd8),0x0000
	ldw (xiz-44), 0x0000                       ; FC42C1  ld (XIZ+0xd4),0x0000
	cpw (xiz-72), 0x0000                       ; FC42C6  cp (XIZ+0xb8),0x0000
	jrl le, sub_FC4269__FC4388                 ; FC42CB  jrl LE,0xfc4388
	ld	xbc, (xiz-66)                           ; FC42CE  ld XBC,(XIZ+0xbe)
	ld	(xiz-8), xbc                            ; FC42D1  ld (XIZ+0xf8),XBC
	sub	xwa, xwa                               ; FC42D4  sub XWA,XWA
	inc	4, xwa                                 ; FC42D6  inc 4,XWA
	ld	(xiz-24), xwa                           ; FC42D8  ld (XIZ+0xe8),XWA
	lda	xiy, (0xE012:24)                       ; FC42DB  lda XIY,0x00e012
	ld	(xiz-28), xiy                           ; FC42E0  ld (XIZ+0xe4),XIY
	ld	xbc, 36                                 ; FC42E3  ld XBC,0x00000024
	ld	(xiz-20), xbc                           ; FC42E8  ld (XIZ+0xec),XBC
	lda	xix, (0xE052:24)                       ; FC42EB  lda XIX,0x00e052
	sub	xbc, xbc                               ; FC42F0  sub XBC,XBC
	ld	(xiz-12), xbc                           ; FC42F2  ld (XIZ+0xf4),XBC
	lda	xbc, (0xE022:24)                       ; FC42F5  lda XBC,0x00e022
	ld	(xiz-16), xbc                           ; FC42FA  ld (XIZ+0xf0),XBC
sub_FC4269__FC42FD:
	extpfx3 0x9E, 0xB6, 0x04                   ; FC42FD  pushw (XIZ+0xb6)
	ld	xbc, (xiz+8)                            ; FC4300  ld XBC,(XIZ+0x08)
	extpfx3 0xAE, 0xE8, 0x81                   ; FC4303  add XBC,(XIZ+0xe8)
	ld	wa, (xbc)                               ; FC4306  ld WA,(XBC)
	srl	wa, 4                                  ; FC4308  srl 0x04,WA
	pushw	wa                                   ; FC430B  push WA
	calr (0xFC412E - 0xFC430F)                 ; FC430C  calr 0xfc412e
	neg	wa                                     ; FC430F  neg WA
	ld	xbc, (xiz-28)                           ; FC4311  ld XBC,(XIZ+0xe4)
	ld	(xbc), wa                               ; FC4314  ld (XBC),WA
	pushw	0x555                                ; FC4316  push 0x0555
	ld	xbc, (xiz+8)                            ; FC4319  ld XBC,(XIZ+0x08)
	extpfx3 0xAE, 0xEC, 0x81                   ; FC431C  add XBC,(XIZ+0xec)
	ld	hl, (xbc)                               ; FC431F  ld HL,(XBC)
	ld	xbc, (xiz+8)                            ; FC4321  ld XBC,(XIZ+0x08)
	extpfx3 0xAE, 0xF8, 0x81                   ; FC4324  add XBC,(XIZ+0xf8)
	ld	wa, (xbc)                               ; FC4327  ld WA,(XBC)
	sub	wa, hl                                 ; FC4329  sub WA,HL
	pushw	wa                                   ; FC432B  push WA
	calr (0xFC412E - 0xFC432F)                 ; FC432C  calr 0xfc412e
	ld	(xix), wa                               ; FC432F  ld (XIX),WA
	ld	xbc, (xiz-12)                           ; FC4331  ld XBC,(XIZ+0xf4)
	ld	(xiz-4), xbc                            ; FC4334  ld (XIZ+0xfc),XBC
	inc	8, xsp                                 ; FC4337  inc 0,XSP
sub_FC4269__FC4339:
	lda	xbc, (0xE052:24)                       ; FC4339  lda XBC,0x00e052
	extpfx3 0xAE, 0xFC, 0x81                   ; FC433E  add XBC,(XIZ+0xfc)
	ld	hl, (xbc)                               ; FC4341  ld HL,(XBC)
	cp	hl, 0x800                               ; FC4343  cp HL,0x0800
	jr lt, sub_FC4269__FC435B                  ; FC4347  jr LT,0xfc435b
	ld	bc, hl                                  ; FC4349  ld BC,HL
	sub	bc, 0x800                              ; FC434B  sub BC,0x0800
	lda	xwa, (0xE052:24)                       ; FC434F  lda XWA,0x00e052
	extpfx3 0xAE, 0xFC, 0x80                   ; FC4354  add XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FC4357  ld (XWA),BC
	jr sub_FC4269__FC4339                      ; FC4359  jr T,0xfc4339
sub_FC4269__FC435B:
	ld	bc, (xix)                               ; FC435B  ld BC,(XIX)
	pushw	bc                                   ; FC435D  push BC
	calr (0xFC4227 - 0xFC4361)                 ; FC435E  calr 0xfc4227
	ld	xbc, (xiz-16)                           ; FC4361  ld XBC,(XIZ+0xf0)
	ld	(xbc), wa                               ; FC4364  ld (XBC),WA
	sub	xbc, xbc                               ; FC4366  sub XBC,XBC
	inc	2, xbc                                 ; FC4368  inc 2,XBC
	add	(xiz-24), xbc                          ; FC436A  add (XIZ+0xe8),XBC
	add	(xiz-28), xbc                          ; FC436D  add (XIZ+0xe4),XBC
	add	(xiz-20), xbc                          ; FC4370  add (XIZ+0xec),XBC
	add	xix, xbc                               ; FC4373  add XIX,XBC
	add	(xiz-12), xbc                          ; FC4375  add (XIZ+0xf4),XBC
	add	(xiz-16), xbc                          ; FC4378  add (XIZ+0xf0),XBC
	incw	1, (xiz-44)                           ; FC437B  incw 1,(XIZ+0xd4)
	popw	wa                                    ; FC437E  pop WA
	ld	wa, (xiz-44)                            ; FC437F  ld WA,(XIZ+0xd4)
	extpfx3 0x9E, 0xB8, 0xF0                   ; FC4382  cp WA,(XIZ+0xb8)
	jrl lt, sub_FC4269__FC42FD                 ; FC4385  jrl LT,0xfc42fd
sub_FC4269__FC4388:
	ld	xbc, (xiz+8)                            ; FC4388  ld XBC,(XIZ+0x08)
	extpfx3 0xAE, 0xBA, 0x81                   ; FC438B  add XBC,(XIZ+0xba)
	ld	wa, (xbc)                               ; FC438E  ld WA,(XBC)
	srl	wa, 4                                  ; FC4390  srl 0x04,WA
	pushw	wa                                   ; FC4393  push WA
	ld	xbc, (xiz-62)                           ; FC4394  ld XBC,(XIZ+0xc2)
	ld	wa, (xbc)                               ; FC4397  ld WA,(XBC)
	pushw	wa                                   ; FC4399  push WA
	calr (0xFC412E - 0xFC439D)                 ; FC439A  calr 0xfc412e
	add	wa, 0x800                              ; FC439D  add WA,0x0800
	ld	(xiz-46), wa                            ; FC43A1  ld (XIZ+0xd2),WA
	ldw (xiz-44), 0x0000                       ; FC43A4  ld (XIZ+0xd4),0x0000
	pop	xiy                                    ; FC43A9  pop XIY
	cpw (xiz-72), 0x0000                       ; FC43AA  cp (XIZ+0xb8),0x0000
	jrl le, sub_FC4269__FC4634                 ; FC43AF  jrl LE,0xfc4634
	ld	xbc, (xiz-54)                           ; FC43B2  ld XBC,(XIZ+0xca)
	ld	(xiz-38), xbc                           ; FC43B5  ld (XIZ+0xda),XBC
	ld	xiy, 20                                 ; FC43B8  ld XIY,0x00000014
	ld	(xiz-34), xiy                           ; FC43BD  ld (XIZ+0xde),XIY
	lda	xbc, (0xE012:24)                       ; FC43C0  lda XBC,0x00e012
	ld	(xiz-22), xbc                           ; FC43C5  ld (XIZ+0xea),XBC
	lda	xbc, (0xE042:24)                       ; FC43C8  lda XBC,0x00e042
	ld	(xiz-26), xbc                           ; FC43CD  ld (XIZ+0xe6),XBC
	lda	xbc, (0xE022:24)                       ; FC43D0  lda XBC,0x00e022
	ld	(xiz-30), xbc                           ; FC43D5  ld (XIZ+0xe2),XBC
	lda	xbc, (0xE072:24)                       ; FC43D8  lda XBC,0x00e072
	ld	(xiz-18), xbc                           ; FC43DD  ld (XIZ+0xee),XBC
	sub	xbc, xbc                               ; FC43E0  sub XBC,XBC
	ld	(xiz-14), xbc                           ; FC43E2  ld (XIZ+0xf2),XBC
sub_FC4269__FC43E5:
	lda	xbc, (0xE032:24)                       ; FC43E5  lda XBC,0x00e032
	extpfx3 0xAE, 0xDA, 0x81                   ; FC43EA  add XBC,(XIZ+0xda)
	extpfx4 0xB1, 0x02, 0x00, 0x10             ; FC43ED  ld (XBC),0x1000
	ld	xbc, (xiz+8)                            ; FC43F1  ld XBC,(XIZ+0x08)
	extpfx3 0xAE, 0xDE, 0x81                   ; FC43F4  add XBC,(XIZ+0xde)
	ld	wa, (xbc)                               ; FC43F7  ld WA,(XBC)
	srl	wa, 4                                  ; FC43F9  srl 0x04,WA
	pushw	wa                                   ; FC43FC  push WA
	ld	xbc, (xiz-22)                           ; FC43FD  ld XBC,(XIZ+0xea)
	ld	wa, (xbc)                               ; FC4400  ld WA,(XBC)
	pushw	wa                                   ; FC4402  push WA
	calr (0xFC412E - 0xFC4406)                 ; FC4403  calr 0xfc412e
	ld	xbc, (xiz-26)                           ; FC4406  ld XBC,(XIZ+0xe6)
	ld	(xbc), wa                               ; FC4409  ld (XBC),WA
	lda	xbc, (0xE062:24)                       ; FC440B  lda XBC,0x00e062
	extpfx3 0xAE, 0xDA, 0x81                   ; FC4410  add XBC,(XIZ+0xda)
	extpfx4 0xB1, 0x02, 0x00, 0x00             ; FC4413  ld (XBC),0x0000
	ld	xbc, (xiz-30)                           ; FC4417  ld XBC,(XIZ+0xe2)
	ld	wa, (xbc)                               ; FC441A  ld WA,(XBC)
	add	wa, wa                                 ; FC441C  add WA,WA
	neg	wa                                     ; FC441E  neg WA
	ld	xiy, (xiz-18)                           ; FC4420  ld XIY,(XIZ+0xee)
	ld	(xiy), wa                               ; FC4423  ld (XIY),WA
	ldw	hl, 0                                  ; FC4425  ld HL,0x0000
	pop	xiy                                    ; FC4428  pop XIY
	cpw (xiz-72), 0x0000                       ; FC4429  cp (XIZ+0xb8),0x0000
	jrl le, sub_FC4269__FC44C2                 ; FC442E  jrl LE,0xfc44c2
	ldw	bc, 2                                  ; FC4431  ld BC,0x0002
	extpfx3 0x9E, 0xB4, 0x49                   ; FC4434  muls XBC,(XIZ+0xb4)
	ld	(xiz-6), xbc                            ; FC4437  ld (XIZ+0xfa),XBC
	ld	xwa, (xiz-14)                           ; FC443A  ld XWA,(XIZ+0xf2)
	ld	(xiz-10), xwa                           ; FC443D  ld (XIZ+0xf6),XWA
	lda	xix, (0xE022:24)                       ; FC4440  lda XIX,0x00e022
sub_FC4269__FC4445:
	extpfx3 0x9E, 0xB4, 0xF3                   ; FC4445  cp HL,(XIZ+0xb4)
	jrl z, sub_FC4269__FC44B9                  ; FC4448  jrl Z,0xfc44b9
	ld	bc, (xix)                               ; FC444B  ld BC,(XIX)
	pushw	bc                                   ; FC444D  push BC
	calr (0xFC419D - 0xFC4451)                 ; FC444E  calr 0xfc419d
	ld	(xiz-2), wa                             ; FC4451  ld (XIZ+0xfe),WA
	ld	bc, (xix)                               ; FC4454  ld BC,(XIX)
	add	bc, bc                                 ; FC4456  add BC,BC
	ld	(xiz-78), bc                            ; FC4458  ld (XIZ+0xb2),BC
	ldw	de, 0x1922                             ; FC445B  ld DE,0x1922
	sub	de, bc                                 ; FC445E  sub DE,BC
	ld	bc, de                                  ; FC4460  ld BC,DE
	sra	bc, 1                                  ; FC4462  sra 0x01,BC
	ld	de, bc                                  ; FC4465  ld DE,BC
	extpfx3 0x9E, 0xFE, 0x04                   ; FC4467  pushw (XIZ+0xfe)
	lda	xwa, (0xE032:24)                       ; FC446A  lda XWA,0x00e032
	extpfx3 0xAE, 0xFA, 0x80                   ; FC446F  add XWA,(XIZ+0xfa)
	ld	iy, (xwa)                               ; FC4472  ld IY,(XWA)
	pushw	iy                                   ; FC4474  push IY
	calr (0xFC412E - 0xFC4478)                 ; FC4475  calr 0xfc412e
	lda	xbc, (0xE032:24)                       ; FC4478  lda XBC,0x00e032
	extpfx3 0xAE, 0xFA, 0x81                   ; FC447D  add XBC,(XIZ+0xfa)
	ld	(xbc), wa                               ; FC4480  ld (XBC),WA
	lda	xbc, (0xE062:24)                       ; FC4482  lda XBC,0x00e062
	extpfx3 0xAE, 0xFA, 0x81                   ; FC4487  add XBC,(XIZ+0xfa)
	add	(xbc), de                              ; FC448A  add (XBC),DE
	inc	6, xsp                                 ; FC448C  inc 6,XSP
	extpfx3 0x9E, 0xD4, 0xF3                   ; FC448E  cp HL,(XIZ+0xd4)
	jr z, sub_FC4269__FC44B9                   ; FC4491  jr Z,0xfc44b9
	extpfx3 0x9E, 0xFE, 0x04                   ; FC4493  pushw (XIZ+0xfe)
	lda	xbc, (0xE042:24)                       ; FC4496  lda XBC,0x00e042
	extpfx3 0xAE, 0xF6, 0x81                   ; FC449B  add XBC,(XIZ+0xf6)
	ld	wa, (xbc)                               ; FC449E  ld WA,(XBC)
	pushw	wa                                   ; FC44A0  push WA
	calr (0xFC412E - 0xFC44A4)                 ; FC44A1  calr 0xfc412e
	lda	xbc, (0xE042:24)                       ; FC44A4  lda XBC,0x00e042
	extpfx3 0xAE, 0xF6, 0x81                   ; FC44A9  add XBC,(XIZ+0xf6)
	ld	(xbc), wa                               ; FC44AC  ld (XBC),WA
	lda	xbc, (0xE072:24)                       ; FC44AE  lda XBC,0x00e072
	extpfx3 0xAE, 0xF6, 0x81                   ; FC44B3  add XBC,(XIZ+0xf6)
	add	(xbc), de                              ; FC44B6  add (XBC),DE
	pop	xiy                                    ; FC44B8  pop XIY
sub_FC4269__FC44B9:
	inc	2, xix                                 ; FC44B9  inc 2,XIX
	inc	1, hl                                  ; FC44BB  inc 1,HL
	extpfx3 0x9E, 0xB8, 0xF3                   ; FC44BD  cp HL,(XIZ+0xb8)
	jr lt, sub_FC4269__FC4445                  ; FC44C0  jr LT,0xfc4445
sub_FC4269__FC44C2:
	ldw	bc, 2                                  ; FC44C2  ld BC,0x0002
	extpfx3 0x9E, 0xB4, 0x49                   ; FC44C5  muls XBC,(XIZ+0xb4)
	ld	xix, xbc                                ; FC44C8  ld XIX,XBC
sub_FC4269__FC44CA:
	lda	xbc, (0xE062:24)                       ; FC44CA  lda XBC,0x00e062
	add	xbc, xix                               ; FC44CF  add XBC,XIX
	ld	hl, (xbc)                               ; FC44D1  ld HL,(XBC)
	cps	hl, 0                                  ; FC44D3  cp HL,0
	jr ge, sub_FC4269__FC44E8                  ; FC44D5  jr GE,0xfc44e8
	ld	bc, hl                                  ; FC44D7  ld BC,HL
	add	bc, 0x3244                             ; FC44D9  add BC,0x3244
	lda	xwa, (0xE062:24)                       ; FC44DD  lda XWA,0x00e062
	add	xwa, xix                               ; FC44E2  add XWA,XIX
	ld	(xwa), bc                               ; FC44E4  ld (XWA),BC
	jr sub_FC4269__FC44CA                      ; FC44E6  jr T,0xfc44ca
sub_FC4269__FC44E8:
	ldw	bc, 2                                  ; FC44E8  ld BC,0x0002
	extpfx3 0x9E, 0xB4, 0x49                   ; FC44EB  muls XBC,(XIZ+0xb4)
	ld	xix, xbc                                ; FC44EE  ld XIX,XBC
sub_FC4269__FC44F0:
	lda	xbc, (0xE062:24)                       ; FC44F0  lda XBC,0x00e062
	add	xbc, xix                               ; FC44F5  add XBC,XIX
	ld	hl, (xbc)                               ; FC44F7  ld HL,(XBC)
	cp	hl, 0x3244                              ; FC44F9  cp HL,0x3244
	jr lt, sub_FC4269__FC4510                  ; FC44FD  jr LT,0xfc4510
	ld	bc, hl                                  ; FC44FF  ld BC,HL
	sub	bc, 0x3244                             ; FC4501  sub BC,0x3244
	lda	xwa, (0xE062:24)                       ; FC4505  lda XWA,0x00e062
	add	xwa, xix                               ; FC450A  add XWA,XIX
	ld	(xwa), bc                               ; FC450C  ld (XWA),BC
	jr sub_FC4269__FC44F0                      ; FC450E  jr T,0xfc44f0
sub_FC4269__FC4510:
	ld	xix, (xiz-14)                           ; FC4510  ld XIX,(XIZ+0xf2)
sub_FC4269__FC4513:
	lda	xbc, (0xE072:24)                       ; FC4513  lda XBC,0x00e072
	add	xbc, xix                               ; FC4518  add XBC,XIX
	ld	hl, (xbc)                               ; FC451A  ld HL,(XBC)
	cps	hl, 0                                  ; FC451C  cp HL,0
	jr ge, sub_FC4269__FC4531                  ; FC451E  jr GE,0xfc4531
	ld	bc, hl                                  ; FC4520  ld BC,HL
	add	bc, 0x3244                             ; FC4522  add BC,0x3244
	lda	xwa, (0xE072:24)                       ; FC4526  lda XWA,0x00e072
	add	xwa, xix                               ; FC452B  add XWA,XIX
	ld	(xwa), bc                               ; FC452D  ld (XWA),BC
	jr sub_FC4269__FC4513                      ; FC452F  jr T,0xfc4513
sub_FC4269__FC4531:
	ld	xix, (xiz-14)                           ; FC4531  ld XIX,(XIZ+0xf2)
sub_FC4269__FC4534:
	lda	xbc, (0xE072:24)                       ; FC4534  lda XBC,0x00e072
	add	xbc, xix                               ; FC4539  add XBC,XIX
	ld	hl, (xbc)                               ; FC453B  ld HL,(XBC)
	cp	hl, 0x3244                              ; FC453D  cp HL,0x3244
	jr lt, sub_FC4269__FC4554                  ; FC4541  jr LT,0xfc4554
	ld	bc, hl                                  ; FC4543  ld BC,HL
	sub	bc, 0x3244                             ; FC4545  sub BC,0x3244
	lda	xwa, (0xE072:24)                       ; FC4549  lda XWA,0x00e072
	add	xwa, xix                               ; FC454E  add XWA,XIX
	ld	(xwa), bc                               ; FC4550  ld (XWA),BC
	jr sub_FC4269__FC4534                      ; FC4552  jr T,0xfc4534
sub_FC4269__FC4554:
	ld	bc, (xiz-44)                            ; FC4554  ld BC,(XIZ+0xd4)
	extpfx3 0x9E, 0xB4, 0xF1                   ; FC4557  cp BC,(XIZ+0xb4)
	jrl nz, sub_FC4269__FC45D6                 ; FC455A  jrl NZ,0xfc45d6
	ld	xix, (xiz-38)                           ; FC455D  ld XIX,(XIZ+0xda)
	lda	xwa, (0xE062:24)                       ; FC4560  lda XWA,0x00e062
	add	xwa, xix                               ; FC4565  add XWA,XIX
	ld	iy, (xwa)                               ; FC4567  ld IY,(XWA)
	pushw	iy                                   ; FC4569  push IY
	calr (0xFC41C3 - 0xFC456D)                 ; FC456A  calr 0xfc41c3
	ld	hl, wa                                  ; FC456D  ld HL,WA
	lda	xbc, (0xE062:24)                       ; FC456F  lda XBC,0x00e062
	add	xbc, xix                               ; FC4574  add XBC,XIX
	ld	iy, (xbc)                               ; FC4576  ld IY,(XBC)
	pushw	iy                                   ; FC4578  push IY
	calr (0xFC419D - 0xFC457C)                 ; FC4579  calr 0xfc419d
	ld	de, wa                                  ; FC457C  ld DE,WA
	pop	xiy                                    ; FC457E  pop XIY
	pushw	hl                                   ; FC457F  push HL
	extpfx3 0x9E, 0xD2, 0x04                   ; FC4580  pushw (XIZ+0xd2)
	lda	xbc, (0xE032:24)                       ; FC4583  lda XBC,0x00e032
	add	xbc, xix                               ; FC4588  add XBC,XIX
	ld	iy, (xbc)                               ; FC458A  ld IY,(XBC)
	pushw	iy                                   ; FC458C  push IY
	calr (0xFC412E - 0xFC4590)                 ; FC458D  calr 0xfc412e
	pop	xiy                                    ; FC4590  pop XIY
	pushw	wa                                   ; FC4591  push WA
	calr (0xFC412E - 0xFC4595)                 ; FC4592  calr 0xfc412e
	add	(xiz-42), wa                           ; FC4595  add (XIZ+0xd6),WA
	pop	xiy                                    ; FC4598  pop XIY
	pushw	de                                   ; FC4599  push DE
	extpfx3 0x9E, 0xD2, 0x04                   ; FC459A  pushw (XIZ+0xd2)
	lda	xbc, (0xE032:24)                       ; FC459D  lda XBC,0x00e032
	add	xbc, xix                               ; FC45A2  add XBC,XIX
	ld	wa, (xbc)                               ; FC45A4  ld WA,(XBC)
	pushw	wa                                   ; FC45A6  push WA
	calr (0xFC412E - 0xFC45AA)                 ; FC45A7  calr 0xfc412e
	pop	xiy                                    ; FC45AA  pop XIY
	pushw	wa                                   ; FC45AB  push WA
	calr (0xFC412E - 0xFC45AF)                 ; FC45AC  calr 0xfc412e
	add	(xiz-40), wa                           ; FC45AF  add (XIZ+0xd8),WA
	pushw	hl                                   ; FC45B2  push HL
	lda	xbc, (0xE032:24)                       ; FC45B3  lda XBC,0x00e032
	add	xbc, xix                               ; FC45B8  add XBC,XIX
	ld	wa, (xbc)                               ; FC45BA  ld WA,(XBC)
	pushw	wa                                   ; FC45BC  push WA
	calr (0xFC412E - 0xFC45C0)                 ; FC45BD  calr 0xfc412e
	add	(xiz-50), wa                           ; FC45C0  add (XIZ+0xce),WA
	pushw	de                                   ; FC45C3  push DE
	lda	xbc, (0xE032:24)                       ; FC45C4  lda XBC,0x00e032
	add	xbc, xix                               ; FC45C9  add XBC,XIX
	ld	wa, (xbc)                               ; FC45CB  ld WA,(XBC)
	pushw	wa                                   ; FC45CD  push WA
	calr (0xFC412E - 0xFC45D1)                 ; FC45CE  calr 0xfc412e
	add	(xiz-48), wa                           ; FC45D1  add (XIZ+0xd0),WA
	jr sub_FC4269__FC460E                      ; FC45D4  jr T,0xfc460e
sub_FC4269__FC45D6:
	ld	xbc, (xiz-18)                           ; FC45D6  ld XBC,(XIZ+0xee)
	ld	wa, (xbc)                               ; FC45D9  ld WA,(XBC)
	pushw	wa                                   ; FC45DB  push WA
	calr (0xFC41C3 - 0xFC45DF)                 ; FC45DC  calr 0xfc41c3
	pushw	wa                                   ; FC45DF  push WA
	ld	xbc, (xiz-26)                           ; FC45E0  ld XBC,(XIZ+0xe6)
	ld	wa, (xbc)                               ; FC45E3  ld WA,(XBC)
	pushw	wa                                   ; FC45E5  push WA
	calr (0xFC412E - 0xFC45E9)                 ; FC45E6  calr 0xfc412e
	ld	hl, wa                                  ; FC45E9  ld HL,WA
	ld	xbc, (xiz-18)                           ; FC45EB  ld XBC,(XIZ+0xee)
	ld	iy, (xbc)                               ; FC45EE  ld IY,(XBC)
	pushw	iy                                   ; FC45F0  push IY
	calr (0xFC419D - 0xFC45F4)                 ; FC45F1  calr 0xfc419d
	pushw	wa                                   ; FC45F4  push WA
	ld	xbc, (xiz-26)                           ; FC45F5  ld XBC,(XIZ+0xe6)
	ld	wa, (xbc)                               ; FC45F8  ld WA,(XBC)
	pushw	wa                                   ; FC45FA  push WA
	calr (0xFC412E - 0xFC45FE)                 ; FC45FB  calr 0xfc412e
	ld	de, wa                                  ; FC45FE  ld DE,WA
	ld	bc, hl                                  ; FC4600  ld BC,HL
	sub	(xiz-42), bc                           ; FC4602  sub (XIZ+0xd6),BC
	sub	(xiz-40), wa                           ; FC4605  sub (XIZ+0xd8),WA
	sub	(xiz-50), bc                           ; FC4608  sub (XIZ+0xce),BC
	sub	(xiz-48), wa                           ; FC460B  sub (XIZ+0xd0),WA
sub_FC4269__FC460E:
	inc	8, xsp                                 ; FC460E  inc 0,XSP
	inc	4, xsp                                 ; FC4610  inc 4,XSP
	sub	xbc, xbc                               ; FC4612  sub XBC,XBC
	inc	2, xbc                                 ; FC4614  inc 2,XBC
	add	(xiz-34), xbc                          ; FC4616  add (XIZ+0xde),XBC
	add	(xiz-22), xbc                          ; FC4619  add (XIZ+0xea),XBC
	add	(xiz-26), xbc                          ; FC461C  add (XIZ+0xe6),XBC
	add	(xiz-30), xbc                          ; FC461F  add (XIZ+0xe2),XBC
	add	(xiz-18), xbc                          ; FC4622  add (XIZ+0xee),XBC
	add	(xiz-14), xbc                          ; FC4625  add (XIZ+0xf2),XBC
	incw	1, (xiz-44)                           ; FC4628  incw 1,(XIZ+0xd4)
	ld	wa, (xiz-44)                            ; FC462B  ld WA,(XIZ+0xd4)
	extpfx3 0x9E, 0xB8, 0xF0                   ; FC462E  cp WA,(XIZ+0xb8)
	jrl lt, sub_FC4269__FC43E5                 ; FC4631  jrl LT,0xfc43e5
sub_FC4269__FC4634:
	extpfx3 0x9E, 0xCE, 0x04                   ; FC4634  pushw (XIZ+0xce)
	extpfx3 0x9E, 0xD0, 0x04                   ; FC4637  pushw (XIZ+0xd0)
	calr (0xFC4140 - 0xFC463D)                 ; FC463A  calr 0xfc4140
	ld	hl, wa                                  ; FC463D  ld HL,WA
	extpfx3 0x9E, 0xD6, 0x04                   ; FC463F  pushw (XIZ+0xd6)
	extpfx3 0x9E, 0xD8, 0x04                   ; FC4642  pushw (XIZ+0xd8)
	calr (0xFC4140 - 0xFC4648)                 ; FC4645  calr 0xfc4140
	ld	de, wa                                  ; FC4648  ld DE,WA
	pushw	hl                                   ; FC464A  push HL
	calr (0xFC41E9 - 0xFC464E)                 ; FC464B  calr 0xfc41e9
	ld	hl, wa                                  ; FC464E  ld HL,WA
	pushw	de                                   ; FC4650  push DE
	calr (0xFC41E9 - 0xFC4654)                 ; FC4651  calr 0xfc41e9
	ld	de, hl                                  ; FC4654  ld DE,HL
	sub	de, wa                                 ; FC4656  sub DE,WA
	pushw	0x146                                ; FC4658  push 0x0146
	pushw	de                                   ; FC465B  push DE
	calr (0xFC412E - 0xFC465F)                 ; FC465C  calr 0xfc412e
	ldw	bc, 0x800                              ; FC465F  ld BC,0x0800
	sub	bc, wa                                 ; FC4662  sub BC,WA
	sra	bc, 4                                  ; FC4664  sra 0x04,BC
	muls	bc, 2                                 ; FC4667  muls BC,0x0002
	add	xbc, 0xFE0CC9                          ; FC466B  add XBC,0x00fe0cc9
	ld	hl, (xbc)                               ; FC4671  ld HL,(XBC)
	ld	xix, (xiz-58)                           ; FC4673  ld XIX,(XIZ+0xc6)
	ld	xbc, (xiz+8)                            ; FC4676  ld XBC,(XIZ+0x08)
	add	xbc, xix                               ; FC4679  add XBC,XIX
	ld	(xbc), hl                               ; FC467B  ld (XBC),HL
	sub	xbc, xbc                               ; FC467D  sub XBC,XBC
	inc	2, xbc                                 ; FC467F  inc 2,XBC
	add	(xiz-66), xbc                          ; FC4681  add (XIZ+0xbe),XBC
	add	(xiz-70), xbc                          ; FC4684  add (XIZ+0xba),XBC
	add	(xiz-62), xbc                          ; FC4687  add (XIZ+0xc2),XBC
	add	(xiz-54), xbc                          ; FC468A  add (XIZ+0xca),XBC
	add	xbc, xix                               ; FC468D  add XBC,XIX
	ld	(xiz-58), xbc                           ; FC468F  ld (XIZ+0xc6),XBC
	incw	1, (xiz-76)                           ; FC4692  incw 1,(XIZ+0xb4)
	inc	8, xsp                                 ; FC4695  inc 0,XSP
	inc	8, xsp                                 ; FC4697  inc 0,XSP
	ld	wa, (xiz-76)                            ; FC4699  ld WA,(XIZ+0xb4)
	extpfx3 0x9E, 0xB8, 0xF0                   ; FC469C  cp WA,(XIZ+0xb8)
	jrl lt, sub_FC4269__FC42AD                 ; FC469F  jrl LT,0xfc42ad
sub_FC4269__FC46A2:
	pop	xix                                    ; FC46A2  pop XIX
	popw	de                                    ; FC46A3  pop DE
	popw	hl                                    ; FC46A4  pop HL
	unlk32 xiz                                 ; FC46A5  unlk XIZ
	ret                                        ; FC46A7  ret
; --------------------------------------------------------------------------
; sub_FC46A8 -- 0xFC46A8..0xFC47ED (326 bytes)
;
; Called from: no site outside this module.
;          3 site(s) inside this module:
;          0xFC65D2 0xFC6C35 0xFC7991
; Inputs:  no frame and no argument slot read.
; Outputs: no absolute-addressed write.
;          reads 0x00E082, 0x00E084
; Evidence: the listing below is the byte-identical round-trip of 0xFC46A8-0xFC47ED
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC46A8:
	pushw	hl                                   ; FC46A8  push HL
	pushw	de                                   ; FC46A9  push DE
	pushw	ix                                   ; FC46AA  push IX
	ld	bc, (0xE084:24)                        ; FC46AB  ld BC,(0x00e084)
	extz	xbc                                   ; FC46B0  extz XBC
	ld	a, (xbc+2)                              ; FC46B2  ld A,(XBC+0x02)
	and	a, 0xC0                                ; FC46B5  and A,0xc0
	srl	a, 6                                   ; FC46B8  srl 0x06,A
	extz	wa                                    ; FC46BB  extz WA
	cps	wa, 1                                  ; FC46BD  cp WA,1
	jr z, sub_FC46A8__FC46C9                   ; FC46BF  jr Z,0xfc46c9
	cps	wa, 2                                  ; FC46C1  cp WA,2
	jrl z, sub_FC46A8__FC4742                  ; FC46C3  jrl Z,0xfc4742
	jrl sub_FC46A8__FC47D0                     ; FC46C6  jrl T,0xfc47d0
sub_FC46A8__FC46C9:
	ld	bc, (0xE082:24)                        ; FC46C9  ld BC,(0x00e082)
	extz	xbc                                   ; FC46CE  extz XBC
	ld	ix, (xbc+13)                            ; FC46D0  ld IX,(XBC+0x0d)
	ld	wa, (0xE084:24)                        ; FC46D3  ld WA,(0x00e084)
	extz	xwa                                   ; FC46D8  extz XWA
	ld	de, (xwa+14)                            ; FC46DA  ld DE,(XWA+0x0e)
	ld	hl, de                                  ; FC46DD  ld HL,DE
	add	hl, ix                                 ; FC46DF  add HL,IX
	cps	hl, 0                                  ; FC46E1  cp HL,0
	jr ge, sub_FC46A8__FC46F0                  ; FC46E3  jr GE,0xfc46f0
	cps	de, 0                                  ; FC46E5  cp DE,0
	jr lt, sub_FC46A8__FC46F0                  ; FC46E7  jr LT,0xfc46f0
	cps	ix, 0                                  ; FC46E9  cp IX,0
	jr lt, sub_FC46A8__FC46F0                  ; FC46EB  jr LT,0xfc46f0
	ldw	hl, 0x7FFF                             ; FC46ED  ld HL,0x7fff
sub_FC46A8__FC46F0:
	cps	hl, 0                                  ; FC46F0  cp HL,0
	jr le, sub_FC46A8__FC46FF                  ; FC46F2  jr LE,0xfc46ff
	cps	de, 0                                  ; FC46F4  cp DE,0
	jr ge, sub_FC46A8__FC46FF                  ; FC46F6  jr GE,0xfc46ff
	cps	ix, 0                                  ; FC46F8  cp IX,0
	jr ge, sub_FC46A8__FC46FF                  ; FC46FA  jr GE,0xfc46ff
	ldw	hl, 0                                  ; FC46FC  ld HL,0x0000
sub_FC46A8__FC46FF:
	ld	bc, (0xE084:24)                        ; FC46FF  ld BC,(0x00e084)
	extz	xbc                                   ; FC4704  extz XBC
	ld	(xbc+10), hl                            ; FC4706  ld (XBC+0x0a),HL
	ld	bc, (0xE082:24)                        ; FC4709  ld BC,(0x00e082)
	extz	xbc                                   ; FC470E  extz XBC
	ld	ix, (xbc+13)                            ; FC4710  ld IX,(XBC+0x0d)
	ld	wa, (0xE084:24)                        ; FC4713  ld WA,(0x00e084)
	extz	xwa                                   ; FC4718  extz XWA
	ld	de, (xwa+16)                            ; FC471A  ld DE,(XWA+0x10)
	ld	hl, de                                  ; FC471D  ld HL,DE
	add	hl, ix                                 ; FC471F  add HL,IX
	cps	hl, 0                                  ; FC4721  cp HL,0
	jr ge, sub_FC46A8__FC4730                  ; FC4723  jr GE,0xfc4730
	cps	de, 0                                  ; FC4725  cp DE,0
	jr lt, sub_FC46A8__FC4730                  ; FC4727  jr LT,0xfc4730
	cps	ix, 0                                  ; FC4729  cp IX,0
	jr lt, sub_FC46A8__FC4730                  ; FC472B  jr LT,0xfc4730
	ldw	hl, 0x7FFF                             ; FC472D  ld HL,0x7fff
sub_FC46A8__FC4730:
	cps	hl, 0                                  ; FC4730  cp HL,0
	jr le, sub_FC46A8__FC473F                  ; FC4732  jr LE,0xfc473f
	cps	de, 0                                  ; FC4734  cp DE,0
	jr ge, sub_FC46A8__FC473F                  ; FC4736  jr GE,0xfc473f
	cps	ix, 0                                  ; FC4738  cp IX,0
	jr ge, sub_FC46A8__FC473F                  ; FC473A  jr GE,0xfc473f
	ldw	hl, 0                                  ; FC473C  ld HL,0x0000
sub_FC46A8__FC473F:
	jrl sub_FC46A8__FC47C4                     ; FC473F  jrl T,0xfc47c4
sub_FC46A8__FC4742:
	ld	bc, (0xE082:24)                        ; FC4742  ld BC,(0x00e082)
	extz	xbc                                   ; FC4747  extz XBC
	ld	ix, (xbc+13)                            ; FC4749  ld IX,(XBC+0x0d)
	ld	wa, ix                                  ; FC474C  ld WA,IX
	neg	wa                                     ; FC474E  neg WA
	ld	ix, wa                                  ; FC4750  ld IX,WA
	ld	bc, (0xE084:24)                        ; FC4752  ld BC,(0x00e084)
	extz	xbc                                   ; FC4757  extz XBC
	ld	de, (xbc+14)                            ; FC4759  ld DE,(XBC+0x0e)
	ld	hl, wa                                  ; FC475C  ld HL,WA
	add	hl, de                                 ; FC475E  add HL,DE
	cps	hl, 0                                  ; FC4760  cp HL,0
	jr ge, sub_FC46A8__FC476F                  ; FC4762  jr GE,0xfc476f
	cps	de, 0                                  ; FC4764  cp DE,0
	jr lt, sub_FC46A8__FC476F                  ; FC4766  jr LT,0xfc476f
	cps	wa, 0                                  ; FC4768  cp WA,0
	jr lt, sub_FC46A8__FC476F                  ; FC476A  jr LT,0xfc476f
	ldw	hl, 0x7FFF                             ; FC476C  ld HL,0x7fff
sub_FC46A8__FC476F:
	cps	hl, 0                                  ; FC476F  cp HL,0
	jr le, sub_FC46A8__FC477E                  ; FC4771  jr LE,0xfc477e
	cps	de, 0                                  ; FC4773  cp DE,0
	jr ge, sub_FC46A8__FC477E                  ; FC4775  jr GE,0xfc477e
	cps	ix, 0                                  ; FC4777  cp IX,0
	jr ge, sub_FC46A8__FC477E                  ; FC4779  jr GE,0xfc477e
	ldw	hl, 0                                  ; FC477B  ld HL,0x0000
sub_FC46A8__FC477E:
	ld	bc, (0xE084:24)                        ; FC477E  ld BC,(0x00e084)
	extz	xbc                                   ; FC4783  extz XBC
	ld	(xbc+10), hl                            ; FC4785  ld (XBC+0x0a),HL
	ld	bc, (0xE082:24)                        ; FC4788  ld BC,(0x00e082)
	extz	xbc                                   ; FC478D  extz XBC
	ld	ix, (xbc+13)                            ; FC478F  ld IX,(XBC+0x0d)
	ld	wa, ix                                  ; FC4792  ld WA,IX
	neg	wa                                     ; FC4794  neg WA
	ld	ix, wa                                  ; FC4796  ld IX,WA
	ld	bc, (0xE084:24)                        ; FC4798  ld BC,(0x00e084)
	extz	xbc                                   ; FC479D  extz XBC
	ld	de, (xbc+16)                            ; FC479F  ld DE,(XBC+0x10)
	ld	hl, wa                                  ; FC47A2  ld HL,WA
	add	hl, de                                 ; FC47A4  add HL,DE
	cps	hl, 0                                  ; FC47A6  cp HL,0
	jr ge, sub_FC46A8__FC47B5                  ; FC47A8  jr GE,0xfc47b5
	cps	de, 0                                  ; FC47AA  cp DE,0
	jr lt, sub_FC46A8__FC47B5                  ; FC47AC  jr LT,0xfc47b5
	cps	wa, 0                                  ; FC47AE  cp WA,0
	jr lt, sub_FC46A8__FC47B5                  ; FC47B0  jr LT,0xfc47b5
	ldw	hl, 0x7FFF                             ; FC47B2  ld HL,0x7fff
sub_FC46A8__FC47B5:
	cps	hl, 0                                  ; FC47B5  cp HL,0
	jr le, sub_FC46A8__FC47C4                  ; FC47B7  jr LE,0xfc47c4
	cps	de, 0                                  ; FC47B9  cp DE,0
	jr ge, sub_FC46A8__FC47C4                  ; FC47BB  jr GE,0xfc47c4
	cps	ix, 0                                  ; FC47BD  cp IX,0
	jr ge, sub_FC46A8__FC47C4                  ; FC47BF  jr GE,0xfc47c4
	ldw	hl, 0                                  ; FC47C1  ld HL,0x0000
sub_FC46A8__FC47C4:
	ld	bc, (0xE084:24)                        ; FC47C4  ld BC,(0x00e084)
	extz	xbc                                   ; FC47C9  extz XBC
	ld	(xbc+12), hl                            ; FC47CB  ld (XBC+0x0c),HL
	jr sub_FC46A8__FC47EA                      ; FC47CE  jr T,0xfc47ea
sub_FC46A8__FC47D0:
	ld	bc, (0xE084:24)                        ; FC47D0  ld BC,(0x00e084)
	extz	xbc                                   ; FC47D5  extz XBC
	ld	wa, (xbc+14)                            ; FC47D7  ld WA,(XBC+0x0e)
	ld	(xbc+10), wa                            ; FC47DA  ld (XBC+0x0a),WA
	ld	bc, (0xE084:24)                        ; FC47DD  ld BC,(0x00e084)
	extz	xbc                                   ; FC47E2  extz XBC
	ld	wa, (xbc+16)                            ; FC47E4  ld WA,(XBC+0x10)
	ld	(xbc+12), wa                            ; FC47E7  ld (XBC+0x0c),WA
sub_FC46A8__FC47EA:
	popw	ix                                    ; FC47EA  pop IX
	popw	de                                    ; FC47EB  pop DE
	popw	hl                                    ; FC47EC  pop HL
	ret                                        ; FC47ED  ret
; --------------------------------------------------------------------------
; sub_FC47EE -- 0xFC47EE..0xFC49AC (447 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFC6856
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFC47EE-0xFC49AC
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC47EE:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FC47EE  link XIZ,0xfffc
	pushw	hl                                   ; FC47F2  push HL
	pushw	de                                   ; FC47F3  push DE
	push	xix                                   ; FC47F4  push XIX
	lda	xix, (0xE084:24)                       ; FC47F5  lda XIX,0x00e084
	ld	xbc, (xiz+8)                            ; FC47FA  ld XBC,(XIZ+0x08)
	ld	a, (xbc+29)                             ; FC47FD  ld A,(XBC+0x1d)
	exts	wa                                    ; FC4800  exts WA
	ld	hl, wa                                  ; FC4802  ld HL,WA
	sll	hl, 8                                  ; FC4804  sll 0x08,HL
	ld	wa, (xix)                               ; FC4807  ld WA,(XIX)
	extz	xwa                                   ; FC4809  extz XWA
	ld	(xwa+14), hl                            ; FC480B  ld (XWA+0x0e),HL
	ld	xbc, (xiz+8)                            ; FC480E  ld XBC,(XIZ+0x08)
	ld	a, (xbc+30)                             ; FC4811  ld A,(XBC+0x1e)
	muls	a, 2                                  ; FC4814  muls A,0x02
	ld	hl, wa                                  ; FC4817  ld HL,WA
	ld	iy, (xix)                               ; FC4819  ld IY,(XIX)
	extz	xiy                                   ; FC481B  extz XIY
	ld	bc, (xiy+14)                            ; FC481D  ld BC,(XIY+0x0e)
	ld	de, bc                                  ; FC4820  ld DE,BC
	add	de, wa                                 ; FC4822  add DE,WA
	ld	bc, (xix)                               ; FC4824  ld BC,(XIX)
	extz	xbc                                   ; FC4826  extz XBC
	ld	(xbc+14), de                            ; FC4828  ld (XBC+0x0e),DE
	ld	xbc, (xiz+8)                            ; FC482B  ld XBC,(XIZ+0x08)
	ld	a, (xbc+41)                             ; FC482E  ld A,(XBC+0x29)
	exts	wa                                    ; FC4831  exts WA
	ld	hl, wa                                  ; FC4833  ld HL,WA
	sll	hl, 8                                  ; FC4835  sll 0x08,HL
	ld	wa, (xix)                               ; FC4838  ld WA,(XIX)
	extz	xwa                                   ; FC483A  extz XWA
	ld	(xwa+16), hl                            ; FC483C  ld (XWA+0x10),HL
	ld	xbc, (xiz+8)                            ; FC483F  ld XBC,(XIZ+0x08)
	ld	a, (xbc+42)                             ; FC4842  ld A,(XBC+0x2a)
	muls	a, 2                                  ; FC4845  muls A,0x02
	ld	hl, wa                                  ; FC4848  ld HL,WA
	ld	iy, (xix)                               ; FC484A  ld IY,(XIX)
	extz	xiy                                   ; FC484C  extz XIY
	ld	bc, (xiy+16)                            ; FC484E  ld BC,(XIY+0x10)
	ld	de, bc                                  ; FC4851  ld DE,BC
	add	de, wa                                 ; FC4853  add DE,WA
	ld	bc, (xix)                               ; FC4855  ld BC,(XIX)
	extz	xbc                                   ; FC4857  extz XBC
	ld	(xbc+16), de                            ; FC4859  ld (XBC+0x10),DE
	ld	bc, (xix)                               ; FC485C  ld BC,(XIX)
	extz	xbc                                   ; FC485E  extz XBC
	ld	wa, (xbc+7)                             ; FC4860  ld WA,(XBC+0x07)
	ld	hl, wa                                  ; FC4863  ld HL,WA
	and	hl, 0x70                               ; FC4865  and HL,0x0070
	ld	bc, (xix)                               ; FC4869  ld BC,(XIX)
	extz	xbc                                   ; FC486B  extz XBC
	ld	(xbc+7), hl                             ; FC486D  ld (XBC+0x07),HL
	ld	xbc, (xiz+8)                            ; FC4870  ld XBC,(XIZ+0x08)
	ld	a, (xbc+21)                             ; FC4873  ld A,(XBC+0x15)
	and	a, 0x80                                ; FC4876  and A,0x80
	jr z, sub_FC47EE__FC48A2                   ; FC4879  jr Z,0xfc48a2
	ld	wa, (xix)                               ; FC487B  ld WA,(XIX)
	extz	xwa                                   ; FC487D  extz XWA
	ld	iy, (xwa+7)                             ; FC487F  ld IY,(XWA+0x07)
	ld	hl, iy                                  ; FC4882  ld HL,IY
	set	15, hl                                 ; FC4884  set 0x0f,HL
	ld	wa, (xix)                               ; FC4887  ld WA,(XIX)
	extz	xwa                                   ; FC4889  extz XWA
	ld	(xwa+7), hl                             ; FC488B  ld (XWA+0x07),HL
	ld	bc, (xix)                               ; FC488E  ld BC,(XIX)
	extz	xbc                                   ; FC4890  extz XBC
	ld	wa, (xbc+14)                            ; FC4892  ld WA,(XBC+0x0e)
	ld	hl, wa                                  ; FC4895  ld HL,WA
	add	hl, 0xC00                              ; FC4897  add HL,0x0c00
	ld	bc, (xix)                               ; FC489B  ld BC,(XIX)
	extz	xbc                                   ; FC489D  extz XBC
	ld	(xbc+14), hl                            ; FC489F  ld (XBC+0x0e),HL
sub_FC47EE__FC48A2:
	ld	xbc, (xiz+8)                            ; FC48A2  ld XBC,(XIZ+0x08)
	ld	a, (xbc+31)                             ; FC48A5  ld A,(XBC+0x1f)
	and	a, 0x80                                ; FC48A8  and A,0x80
	jr z, sub_FC47EE__FC48D4                   ; FC48AB  jr Z,0xfc48d4
	ld	wa, (xix)                               ; FC48AD  ld WA,(XIX)
	extz	xwa                                   ; FC48AF  extz XWA
	ld	iy, (xwa+7)                             ; FC48B1  ld IY,(XWA+0x07)
	ld	hl, iy                                  ; FC48B4  ld HL,IY
	set	14, hl                                 ; FC48B6  set 0x0e,HL
	ld	wa, (xix)                               ; FC48B9  ld WA,(XIX)
	extz	xwa                                   ; FC48BB  extz XWA
	ld	(xwa+7), hl                             ; FC48BD  ld (XWA+0x07),HL
	ld	bc, (xix)                               ; FC48C0  ld BC,(XIX)
	extz	xbc                                   ; FC48C2  extz XBC
	ld	wa, (xbc+16)                            ; FC48C4  ld WA,(XBC+0x10)
	ld	hl, wa                                  ; FC48C7  ld HL,WA
	add	hl, 0xC00                              ; FC48C9  add HL,0x0c00
	ld	bc, (xix)                               ; FC48CD  ld BC,(XIX)
	extz	xbc                                   ; FC48CF  extz XBC
	ld	(xbc+16), hl                            ; FC48D1  ld (XBC+0x10),HL
sub_FC47EE__FC48D4:
	ld	xbc, (xiz+8)                            ; FC48D4  ld XBC,(XIZ+0x08)
	ld	a, (xbc+33)                             ; FC48D7  ld A,(XBC+0x21)
	cps	a, 0                                   ; FC48DA  cp A,0
	jr ge, sub_FC47EE__FC48F1                  ; FC48DC  jr GE,0xfc48f1
	ld	wa, (xix)                               ; FC48DE  ld WA,(XIX)
	extz	xwa                                   ; FC48E0  extz XWA
	ld	iy, (xwa+7)                             ; FC48E2  ld IY,(XWA+0x07)
	ld	hl, iy                                  ; FC48E5  ld HL,IY
	set	7, hl                                  ; FC48E7  set 0x07,HL
	ld	wa, (xix)                               ; FC48EA  ld WA,(XIX)
	extz	xwa                                   ; FC48EC  extz XWA
	ld	(xwa+7), hl                             ; FC48EE  ld (XWA+0x07),HL
sub_FC47EE__FC48F1:
	ld	xbc, (xiz+8)                            ; FC48F1  ld XBC,(XIZ+0x08)
	ld	a, (xbc+25)                             ; FC48F4  ld A,(XBC+0x19)
	and	a, 0x80                                ; FC48F7  and A,0x80
	jr z, sub_FC47EE__FC4929                   ; FC48FA  jr Z,0xfc4929
	ld	a, (xbc+26)                             ; FC48FC  ld A,(XBC+0x1a)
	extz	wa                                    ; FC48FF  extz WA
	ld	hl, wa                                  ; FC4901  ld HL,WA
	sll	hl, 8                                  ; FC4903  sll 0x08,HL
	ld	wa, (xix)                               ; FC4906  ld WA,(XIX)
	extz	xwa                                   ; FC4908  extz XWA
	ld	(xwa+18), hl                            ; FC490A  ld (XWA+0x12),HL
	ld	xbc, (xiz+8)                            ; FC490D  ld XBC,(XIZ+0x08)
	ld	a, (xbc+27)                             ; FC4910  ld A,(XBC+0x1b)
	extz	wa                                    ; FC4913  extz WA
	ld	hl, wa                                  ; FC4915  ld HL,WA
	ld	iy, (xix)                               ; FC4917  ld IY,(XIX)
	extz	xiy                                   ; FC4919  extz XIY
	ld	bc, (xiy+18)                            ; FC491B  ld BC,(XIY+0x12)
	ld	de, bc                                  ; FC491E  ld DE,BC
	add	de, wa                                 ; FC4920  add DE,WA
	ld	bc, (xix)                               ; FC4922  ld BC,(XIX)
	extz	xbc                                   ; FC4924  extz XBC
	ld	(xbc+18), de                            ; FC4926  ld (XBC+0x12),DE
sub_FC47EE__FC4929:
	ld	xbc, (xiz+8)                            ; FC4929  ld XBC,(XIZ+0x08)
	ld	a, (xbc+37)                             ; FC492C  ld A,(XBC+0x25)
	and	a, 0x80                                ; FC492F  and A,0x80
	jr z, sub_FC47EE__FC4961                   ; FC4932  jr Z,0xfc4961
	ld	a, (xbc+38)                             ; FC4934  ld A,(XBC+0x26)
	extz	wa                                    ; FC4937  extz WA
	ld	hl, wa                                  ; FC4939  ld HL,WA
	sll	hl, 8                                  ; FC493B  sll 0x08,HL
	ld	wa, (xix)                               ; FC493E  ld WA,(XIX)
	extz	xwa                                   ; FC4940  extz XWA
	ld	(xwa+20), hl                            ; FC4942  ld (XWA+0x14),HL
	ld	xbc, (xiz+8)                            ; FC4945  ld XBC,(XIZ+0x08)
	ld	a, (xbc+39)                             ; FC4948  ld A,(XBC+0x27)
	extz	wa                                    ; FC494B  extz WA
	ld	hl, wa                                  ; FC494D  ld HL,WA
	ld	iy, (xix)                               ; FC494F  ld IY,(XIX)
	extz	xiy                                   ; FC4951  extz XIY
	ld	bc, (xiy+20)                            ; FC4953  ld BC,(XIY+0x14)
	ld	de, bc                                  ; FC4956  ld DE,BC
	add	de, wa                                 ; FC4958  add DE,WA
	ld	bc, (xix)                               ; FC495A  ld BC,(XIX)
	extz	xbc                                   ; FC495C  extz XBC
	ld	(xbc+20), de                            ; FC495E  ld (XBC+0x14),DE
sub_FC47EE__FC4961:
	ld	xbc, (xiz+8)                            ; FC4961  ld XBC,(XIZ+0x08)
	ld	a, (xbc+15)                             ; FC4964  ld A,(XBC+0x0f)
	extz	wa                                    ; FC4967  extz WA
	ld	hl, wa                                  ; FC4969  ld HL,WA
	cp	wa, 96                                  ; FC496B  cp WA,0x0060
	jr le, sub_FC47EE__FC4976                  ; FC496F  jr LE,0xfc4976
	ldw	hl, 96                                 ; FC4971  ld HL,0x0060
	jr sub_FC47EE__FC497F                      ; FC4974  jr T,0xfc497f
sub_FC47EE__FC4976:
	cp	hl, 44                                  ; FC4976  cp HL,0x002c
	jr ge, sub_FC47EE__FC497F                  ; FC497A  jr GE,0xfc497f
	ldw	hl, 44                                 ; FC497C  ld HL,0x002c
sub_FC47EE__FC497F:
	ldw	bc, 2                                  ; FC497F  ld BC,0x0002
	muls	xbc, xhl                              ; FC4982  muls XBC,HL
	ld	(xiz-4), xbc                            ; FC4984  ld (XIZ+0xfc),XBC
	add	xbc, 0xFE04C9                          ; FC4987  add XBC,0x00fe04c9
	ld	hl, (xbc)                               ; FC498D  ld HL,(XBC)
	ld	bc, (xix)                               ; FC498F  ld BC,(XIX)
	extz	xbc                                   ; FC4991  extz XBC
	ld	(xbc+38), hl                            ; FC4993  ld (XBC+0x26),HL
	lda	xbc, (0xFE05C9:24)                     ; FC4996  lda XBC,0xfe05c9
	extpfx3 0xAE, 0xFC, 0x81                   ; FC499B  add XBC,(XIZ+0xfc)
	ld	hl, (xbc)                               ; FC499E  ld HL,(XBC)
	ld	bc, (xix)                               ; FC49A0  ld BC,(XIX)
	extz	xbc                                   ; FC49A2  extz XBC
	ld	(xbc+36), hl                            ; FC49A4  ld (XBC+0x24),HL
	pop	xix                                    ; FC49A7  pop XIX
	popw	de                                    ; FC49A8  pop DE
	popw	hl                                    ; FC49A9  pop HL
	unlk32 xiz                                 ; FC49AA  unlk XIZ
	ret                                        ; FC49AC  ret
; --------------------------------------------------------------------------
; sub_FC49AD -- 0xFC49AD..0xFC4AEC (320 bytes)
;
; Called from: no site outside this module.
;          3 site(s) inside this module:
;          0xFC56AA 0xFC5EE9 0xFC7CE9
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
;          reads 0x00E086
; Calls:   0xFCB11B = Multiply32
; Evidence: the listing below is the byte-identical round-trip of 0xFC49AD-0xFC4AEC
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC49AD:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FC49AD  link XIZ,0xfffc
	pushw	hl                                   ; FC49B1  push HL
	pushw	de                                   ; FC49B2  push DE
	push	xix                                   ; FC49B3  push XIX
	ld	bc, (0xE086:24)                        ; FC49B4  ld BC,(0x00e086)
	extz	xbc                                   ; FC49B9  extz XBC
	ld	de, (xbc+33)                            ; FC49BB  ld DE,(XBC+0x21)
	ld	wa, (xbc+22)                            ; FC49BE  ld WA,(XBC+0x16)
	ld	ix, wa                                  ; FC49C1  ld IX,WA
	add	ix, de                                 ; FC49C3  add IX,DE
	ld	wa, (xbc+18)                            ; FC49C5  ld WA,(XBC+0x12)
	ld	hl, wa                                  ; FC49C8  ld HL,WA
	add	hl, ix                                 ; FC49CA  add HL,IX
	cp	hl, 0xFA                                ; FC49CC  cp HL,0x00fa
	jr le, sub_FC49AD__FC49D7                  ; FC49D0  jr LE,0xfc49d7
	ldw	hl, 0xFA                               ; FC49D2  ld HL,0x00fa
	jr sub_FC49AD__FC49DE                      ; FC49D5  jr T,0xfc49de
sub_FC49AD__FC49D7:
	cps	hl, 0                                  ; FC49D7  cp HL,0
	jr ge, sub_FC49AD__FC49DE                  ; FC49D9  jr GE,0xfc49de
	ldw	hl, 0                                  ; FC49DB  ld HL,0x0000
sub_FC49AD__FC49DE:
	ldw	bc, 2                                  ; FC49DE  ld BC,0x0002
	muls	xbc, xhl                              ; FC49E1  muls XBC,HL
	ld	xix, xbc                                ; FC49E3  ld XIX,XBC
	add	xbc, 0xFDFAE0                          ; FC49E5  add XBC,0x00fdfae0
	ld	hl, (xbc)                               ; FC49EB  ld HL,(XBC)
	lda	xbc, (0xFDFCD6:24)                     ; FC49ED  lda XBC,0xfdfcd6
	add	xbc, xix                               ; FC49F2  add XBC,XIX
	ld	wa, (xbc)                               ; FC49F4  ld WA,(XBC)
	ld	xbc, (xiz+8)                            ; FC49F6  ld XBC,(XIZ+0x08)
	ld	(xbc+8), wa                             ; FC49F9  ld (XBC+0x08),WA
	ld	bc, (0xE086:24)                        ; FC49FC  ld BC,(0x00e086)
	extz	xbc                                   ; FC4A01  extz XBC
	ld	xwa, (xbc+1)                            ; FC4A03  ld XWA,(XBC+0x01)
	ld	c, (xwa+14)                             ; FC4A06  ld C,(XWA+0x0e)
	and	c, 0x80                                ; FC4A09  and C,0x80
	jr nz, sub_FC49AD__FC4A1F                  ; FC4A0C  jr NZ,0xfc4a1f
	ld	bc, (0xE086:24)                        ; FC4A0E  ld BC,(0x00e086)
	extz	xbc                                   ; FC4A13  extz XBC
	ld	wa, (xbc+14)                            ; FC4A15  ld WA,(XBC+0x0e)
	ldw	iy, 0x4280                             ; FC4A18  ld IY,0x4280
	sub	iy, wa                                 ; FC4A1B  sub IY,WA
	add	hl, iy                                 ; FC4A1D  add HL,IY
sub_FC49AD__FC4A1F:
	ld	bc, (0xE086:24)                        ; FC4A1F  ld BC,(0x00e086)
	extz	xbc                                   ; FC4A24  extz XBC
	ld	wa, (xbc+12)                            ; FC4A26  ld WA,(XBC+0x0c)
	sub	hl, wa                                 ; FC4A29  sub HL,WA
	cps	hl, 0                                  ; FC4A2B  cp HL,0
	jr ge, sub_FC49AD__FC4A3F                  ; FC4A2D  jr GE,0xfc4a3f
	ld	wa, hl                                  ; FC4A2F  ld WA,HL
	and	wa, 0x4000                             ; FC4A31  and WA,0x4000
	jr z, sub_FC49AD__FC4A3C                   ; FC4A35  jr Z,0xfc4a3c
	ldw	hl, 0                                  ; FC4A37  ld HL,0x0000
	jr sub_FC49AD__FC4A3F                      ; FC4A3A  jr T,0xfc4a3f
sub_FC49AD__FC4A3C:
	ldw	hl, 0x7F00                             ; FC4A3C  ld HL,0x7f00
sub_FC49AD__FC4A3F:
	ld	xbc, (xiz+8)                            ; FC4A3F  ld XBC,(XIZ+0x08)
	ld	(xbc+6), hl                             ; FC4A42  ld (XBC+0x06),HL
	ld	bc, (0xE086:24)                        ; FC4A45  ld BC,(0x00e086)
	extz	xbc                                   ; FC4A4A  extz XBC
	ld	hl, (xbc+26)                            ; FC4A4C  ld HL,(XBC+0x1a)
	ld	wa, hl                                  ; FC4A4F  ld WA,HL
	and	wa, 0x8000                             ; FC4A51  and WA,0x8000
	jr z, sub_FC49AD__FC4A6A                   ; FC4A55  jr Z,0xfc4a6a
	ld	wa, hl                                  ; FC4A57  ld WA,HL
	res	15, wa                                 ; FC4A59  res 0x0f,WA
	extz	xwa                                   ; FC4A5C  extz XWA
	ld	(xiz-4), xwa                            ; FC4A5E  ld (XIZ+0xfc),XWA
	ld	xix, 0x8000                             ; FC4A61  ld XIX,0x00008000
	sub	xix, xwa                               ; FC4A66  sub XIX,XWA
	jr sub_FC49AD__FC4A74                      ; FC4A68  jr T,0xfc4a74
sub_FC49AD__FC4A6A:
	ld	ix, hl                                  ; FC4A6A  ld IX,HL
	extz	xix                                   ; FC4A6C  extz XIX
	add	xix, 0x8000                            ; FC4A6E  add XIX,0x00008000
sub_FC49AD__FC4A74:
	ld	bc, (0xE086:24)                        ; FC4A74  ld BC,(0x00e086)
	extz	xbc                                   ; FC4A79  extz XBC
	ld	hl, (xbc+33)                            ; FC4A7B  ld HL,(XBC+0x21)
	cps	hl, 0                                  ; FC4A7E  cp HL,0
	jr ge, sub_FC49AD__FC4A88                  ; FC4A80  jr GE,0xfc4a88
	ld	wa, hl                                  ; FC4A82  ld WA,HL
	neg	wa                                     ; FC4A84  neg WA
	ld	hl, wa                                  ; FC4A86  ld HL,WA
sub_FC49AD__FC4A88:
	ld	de, hl                                  ; FC4A88  ld DE,HL
	sra	de, 2                                  ; FC4A8A  sra 0x02,DE
	ld	bc, (0xE086:24)                        ; FC4A8D  ld BC,(0x00e086)
	extz	xbc                                   ; FC4A92  extz XBC
	ld	wa, (xbc+24)                            ; FC4A94  ld WA,(XBC+0x18)
	ld	(xiz-2), wa                             ; FC4A97  ld (XIZ+0xfe),WA
	ld	iy, (xbc+20)                            ; FC4A9A  ld IY,(XBC+0x14)
	add	iy, wa                                 ; FC4A9D  add IY,WA
	ld	hl, iy                                  ; FC4A9F  ld HL,IY
	add	hl, de                                 ; FC4AA1  add HL,DE
	cp	hl, 0x7F                                ; FC4AA3  cp HL,0x007f
	jr le, sub_FC49AD__FC4AAE                  ; FC4AA7  jr LE,0xfc4aae
	ldw	hl, 0x7F                               ; FC4AA9  ld HL,0x007f
	jr sub_FC49AD__FC4AB5                      ; FC4AAC  jr T,0xfc4ab5
sub_FC49AD__FC4AAE:
	cps	hl, 0                                  ; FC4AAE  cp HL,0
	jr ge, sub_FC49AD__FC4AB5                  ; FC4AB0  jr GE,0xfc4ab5
	ldw	hl, 0                                  ; FC4AB2  ld HL,0x0000
sub_FC49AD__FC4AB5:
	ldw	bc, 2                                  ; FC4AB5  ld BC,0x0002
	muls	xbc, xhl                              ; FC4AB8  muls XBC,HL
	add	xbc, 0xFDF9E0                          ; FC4ABA  add XBC,0x00fdf9e0
	ld	hl, (xbc)                               ; FC4AC0  ld HL,(XBC)
	ld	bc, hl                                  ; FC4AC2  ld BC,HL
	extz	xbc                                   ; FC4AC4  extz XBC
	push	xbc                                   ; FC4AC6  push XBC
	push	xix                                   ; FC4AC7  push XIX
	call	0xFCB11B                              ; FC4AC8  call 0xfcb11b
	srl	xiy, 0                                 ; FC4ACC  srl 0x00,XIY
	ld	hl, iy                                  ; FC4ACF  ld HL,IY
	ld	xbc, (xiz+8)                            ; FC4AD1  ld XBC,(XIZ+0x08)
	ld	(xbc+18), iy                            ; FC4AD4  ld (XBC+0x12),IY
	ld	bc, hl                                  ; FC4AD7  ld BC,HL
	and	bc, 0xFFF8                             ; FC4AD9  and BC,0xfff8
	or	bc, 7                                   ; FC4ADD  or BC,0x0007
	ld	xwa, (xiz+8)                            ; FC4AE1  ld XWA,(XIZ+0x08)
	ld	(xwa+18), bc                            ; FC4AE4  ld (XWA+0x12),BC
	pop	xix                                    ; FC4AE7  pop XIX
	popw	de                                    ; FC4AE8  pop DE
	popw	hl                                    ; FC4AE9  pop HL
	unlk32 xiz                                 ; FC4AEA  unlk XIZ
	ret                                        ; FC4AEC  ret
; --------------------------------------------------------------------------
; sub_FC4AED -- 0xFC4AED..0xFC4B2D (65 bytes)
;
; Called from: no site outside this module.
;          2 site(s) inside this module:
;          0xFC51A7 0xFC67E9
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
;          reads 0x00E086
; Evidence: the listing below is the byte-identical round-trip of 0xFC4AED-0xFC4B2D
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC4AED:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC4AED  link XIZ,0x0000
	pushw	hl                                   ; FC4AF1  push HL
	pushw	de                                   ; FC4AF2  push DE
	ld	bc, (0xE086:24)                        ; FC4AF3  ld BC,(0x00e086)
	extz	xbc                                   ; FC4AF8  extz XBC
	ld	de, (xbc+16)                            ; FC4AFA  ld DE,(XBC+0x10)
	ld	hl, (xbc+35)                            ; FC4AFD  ld HL,(XBC+0x23)
	ld	wa, de                                  ; FC4B00  ld WA,DE
	add	hl, wa                                 ; FC4B02  add HL,WA
	cp	hl, 0x64                                ; FC4B04  cp HL,0x0064
	jr le, sub_FC4AED__FC4B0F                  ; FC4B08  jr LE,0xfc4b0f
	ldw	hl, 0x64                               ; FC4B0A  ld HL,0x0064
	jr sub_FC4AED__FC4B16                      ; FC4B0D  jr T,0xfc4b16
sub_FC4AED__FC4B0F:
	cps	hl, 0                                  ; FC4B0F  cp HL,0
	jr ge, sub_FC4AED__FC4B16                  ; FC4B11  jr GE,0xfc4b16
	ldw	hl, 0                                  ; FC4B13  ld HL,0x0000
sub_FC4AED__FC4B16:
	ldw	bc, 2                                  ; FC4B16  ld BC,0x0002
	muls	xbc, xhl                              ; FC4B19  muls XBC,HL
	add	xbc, 0xFDFECC                          ; FC4B1B  add XBC,0x00fdfecc
	ld	hl, (xbc)                               ; FC4B21  ld HL,(XBC)
	ld	xbc, (xiz+8)                            ; FC4B23  ld XBC,(XIZ+0x08)
	ld	(xbc+20), hl                            ; FC4B26  ld (XBC+0x14),HL
	popw	de                                    ; FC4B29  pop DE
	popw	hl                                    ; FC4B2A  pop HL
	unlk32 xiz                                 ; FC4B2B  unlk XIZ
	ret                                        ; FC4B2D  ret
; --------------------------------------------------------------------------
; sub_FC4B2E -- 0xFC4B2E..0xFC4BB5 (136 bytes)
;
; Called from: 10 site(s) outside this module:
;          0xFB0DD6 in sub_FB0B95__FB0C19, 0xFB1053 in VoiceParams_Compute_A__FB0ED5
;          0xFB1262 in VoiceParams_Compute_A__FB10F4, 0xFB150F in VoiceParams_Compute_A__FB131D
;          0xFB17A9 in VoiceParams_Compute_A__FB15B0, 0xFB1A7B in VoiceParams_Compute_A__FB185E
;          0xFB1D4D in VoiceParams_Compute_A__FB1B30, 0xFB2A3C in sub_FB289A
;          0xFB2C2B in VoiceParams_Compute_C, 0xFB2DEB in VoiceParams_Compute_C__FB2C6D
; Inputs:  frame `link XIZ,-6`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C), (XIZ+0x0E)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFC4B2E-0xFC4BB5
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC4B2E:
	link32 0xEE, 0x0C, 0xFA, 0xFF              ; FC4B2E  link XIZ,0xfffa
	pushw	hl                                   ; FC4B32  push HL
	pushw	de                                   ; FC4B33  push DE
	pushw	ix                                   ; FC4B34  push IX
	ldb	c, 42                                  ; FC4B35  ld C,0x2a
	extpfx3 0x8E, 0x0A, 0x43                   ; FC4B37  mul BC,(XIZ+0x0a)
	ld	ix, bc                                  ; FC4B3A  ld IX,BC
	ldb	a, 0xBB                                ; FC4B3C  ld A,0xbb
	extpfx3 0x8E, 0x08, 0x41                   ; FC4B3E  mul WA,(XIZ+0x08)
	add	wa, bc                                 ; FC4B41  add WA,BC
	ld	ix, wa                                  ; FC4B43  ld IX,WA
	add	ix, 19                                 ; FC4B45  add IX,0x0013
	ldw	bc, 0x5D23                             ; FC4B49  ld BC,0x5d23
	add	bc, ix                                 ; FC4B4C  add BC,IX
	ld	(xiz-6), bc                             ; FC4B4E  ld (XIZ+0xfa),BC
	extz	xbc                                   ; FC4B51  extz XBC
	ld	hl, (xbc+12)                            ; FC4B53  ld HL,(XBC+0x0c)
	ld	de, (xbc+10)                            ; FC4B56  ld DE,(XBC+0x0a)
	cp	de, hl                                  ; FC4B59  cp DE,HL
	jr gt, sub_FC4B2E__FC4B62                  ; FC4B5B  jr GT,0xfc4b62
	ld	(xiz-4), de                             ; FC4B5D  ld (XIZ+0xfc),DE
	jr sub_FC4B2E__FC4B65                      ; FC4B60  jr T,0xfc4b65
sub_FC4B2E__FC4B62:
	ld	(xiz-4), hl                             ; FC4B62  ld (XIZ+0xfc),HL
sub_FC4B2E__FC4B65:
	ld	bc, (xiz+12)                            ; FC4B65  ld BC,(XIZ+0x0c)
	extpfx3 0x9E, 0x0E, 0xF1                   ; FC4B68  cp BC,(XIZ+0x0e)
	jr ugt, sub_FC4B2E__FC4B72                 ; FC4B6B  jr UGT,0xfc4b72
	ld	(xiz-2), bc                             ; FC4B6D  ld (XIZ+0xfe),BC
	jr sub_FC4B2E__FC4B78                      ; FC4B70  jr T,0xfc4b78
sub_FC4B2E__FC4B72:
	ld	bc, (xiz+14)                            ; FC4B72  ld BC,(XIZ+0x0e)
	ld	(xiz-2), bc                             ; FC4B75  ld (XIZ+0xfe),BC
sub_FC4B2E__FC4B78:
	ld	ix, (xiz-2)                             ; FC4B78  ld IX,(XIZ+0xfe)
	ld	de, (xiz-4)                             ; FC4B7B  ld DE,(XIZ+0xfc)
	ld	hl, (xiz-4)                             ; FC4B7E  ld HL,(XIZ+0xfc)
	ld	bc, (xiz-2)                             ; FC4B81  ld BC,(XIZ+0xfe)
	add	hl, bc                                 ; FC4B84  add HL,BC
	cps	hl, 0                                  ; FC4B86  cp HL,0
	jr ge, sub_FC4B2E__FC4B95                  ; FC4B88  jr GE,0xfc4b95
	cps	de, 0                                  ; FC4B8A  cp DE,0
	jr lt, sub_FC4B2E__FC4B95                  ; FC4B8C  jr LT,0xfc4b95
	cps	ix, 0                                  ; FC4B8E  cp IX,0
	jr lt, sub_FC4B2E__FC4B95                  ; FC4B90  jr LT,0xfc4b95
	ldw	hl, 0x7FFF                             ; FC4B92  ld HL,0x7fff
sub_FC4B2E__FC4B95:
	cps	hl, 0                                  ; FC4B95  cp HL,0
	jr le, sub_FC4B2E__FC4BA4                  ; FC4B97  jr LE,0xfc4ba4
	cps	de, 0                                  ; FC4B99  cp DE,0
	jr ge, sub_FC4B2E__FC4BA4                  ; FC4B9B  jr GE,0xfc4ba4
	cps	ix, 0                                  ; FC4B9D  cp IX,0
	jr ge, sub_FC4B2E__FC4BA4                  ; FC4B9F  jr GE,0xfc4ba4
	ldw	hl, 0                                  ; FC4BA1  ld HL,0x0000
sub_FC4B2E__FC4BA4:
	cp	hl, 0x2980                              ; FC4BA4  cp HL,0x2980
	jr ge, sub_FC4B2E__FC4BAE                  ; FC4BA8  jr GE,0xfc4bae
	ldb	a, 1                                   ; FC4BAA  ld A,0x01
	jr sub_FC4B2E__FC4BB0                      ; FC4BAC  jr T,0xfc4bb0
sub_FC4B2E__FC4BAE:
	sub	a, a                                   ; FC4BAE  sub A,A
sub_FC4B2E__FC4BB0:
	popw	ix                                    ; FC4BB0  pop IX
	popw	de                                    ; FC4BB1  pop DE
	popw	hl                                    ; FC4BB2  pop HL
	unlk32 xiz                                 ; FC4BB3  unlk XIZ
	ret                                        ; FC4BB5  ret
; --------------------------------------------------------------------------
; Pack104_SetInputs_PartRecord -- 0xFC4BB6..0xFC4C84 (207 bytes)
;
; Called from: 5 site(s) outside this module:
;          0xFB369D in MidiNote_OnTail, 0xFB37AA in MidiNote_OffTail
;          0xFB38BF in MidiNote_OnByPartMode__FB389B, 0xFB3A0A in MidiNote_OnByPartMode__FB39E6
;          0xFB3B09 in MidiNote_OnByPartMode__FB3AEE
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x00E082, 0x00E08F, 0x00E090, 0x00E091, 0x00E092
; Evidence: the listing below is the byte-identical round-trip of 0xFC4BB6-0xFC4C84
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ ROUND 6 ------------------------------------------------------------
; Pack104_SetInputs_PartRecord -- sets the global
;          0x00E082 to 0x005D23 + 0xBB*arg, i.e. selects one 187-byte PART RECORD as the one
;          Dev104_PackStagingStruct will read, and also writes 0x00E08F-0x00E092.
;          Called from the five MidiNote_* sites 0xFB369D, 0xFB37AA, 0xFB38BF, 0xFB3A0A and
;          0xFB3B09, so "the part this note-on belongs to" is what it selects.
;          Evidence: the stride 0xBB and the base 0x005D23 are instruction operands; the
;          caller list is the routine's own Called-from census.
; --------------------------------------------------------------------------
Pack104_SetInputs_PartRecord:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FC4BB6  link XIZ,0xfffc
	push	xhl                                   ; FC4BBA  push XHL
	push	xde                                   ; FC4BBB  push XDE
	push	xix                                   ; FC4BBC  push XIX
	ldb	c, 0xBB                                ; FC4BBD  ld C,0xbb
	extpfx3 0x8E, 0x08, 0x43                   ; FC4BBF  mul BC,(XIZ+0x08)
	ld	hl, bc                                  ; FC4BC2  ld HL,BC
	ldw	wa, 0x5D23                             ; FC4BC4  ld WA,0x5d23
	add	wa, bc                                 ; FC4BC7  add WA,BC
	stw_da	(0xE082), wa                        ; FC4BC9  ld (0x00e082),WA
	stib_da	(0xE08F), 0xFF                     ; FC4BCE  ld (0x00e08f),0xff
	stib_da	(0xE090), 0xFF                     ; FC4BD4  ld (0x00e090),0xff
	stib_da	(0xE091), 0xFF                     ; FC4BDA  ld (0x00e091),0xff
	stib_da	(0xE092), 0xFF                     ; FC4BE0  ld (0x00e092),0xff
	ld	bc, (0xE082:24)                        ; FC4BE6  ld BC,(0x00e082)
	extz	xbc                                   ; FC4BEB  extz XBC
	ld	a, (xbc)                                ; FC4BED  ld A,(XBC)
	cps	a, 0                                   ; FC4BEF  cp A,0
	jrl z, Pack104_SetInputs_PartRecord__FC4C7F                  ; FC4BF1  jrl Z,0xfc4c7f
	ld	de, bc                                  ; FC4BF4  ld DE,BC
	add	bc, 19                                 ; FC4BF6  add BC,0x0013
	ld	de, bc                                  ; FC4BFA  ld DE,BC
	ld	wa, (0xE082:24)                        ; FC4BFC  ld WA,(0x00e082)
	extz	xwa                                   ; FC4C01  extz XWA
	ld	xiy, (xwa+22)                           ; FC4C03  ld XIY,(XWA+0x16)
	ld	(xiz-4), xiy                            ; FC4C06  ld (XIZ+0xfc),XIY
	ld	hl, wa                                  ; FC4C09  ld HL,WA
	add	wa, 61                                 ; FC4C0B  add WA,0x003d
	ld	hl, wa                                  ; FC4C0F  ld HL,WA
	ld	bc, (0xE082:24)                        ; FC4C11  ld BC,(0x00e082)
	extz	xbc                                   ; FC4C16  extz XBC
	ld	xwa, (xbc+64)                           ; FC4C18  ld XWA,(XBC+0x40)
	ld	xix, xwa                                ; FC4C1B  ld XIX,XWA
	ld	c, (xiy+11)                             ; FC4C1D  ld C,(XIY+0x0b)
	and	c, 0xC0                                ; FC4C20  and C,0xc0
	jr nz, Pack104_SetInputs_PartRecord__FC4C2D                  ; FC4C23  jr NZ,0xfc4c2d
	ld	c, (xwa+11)                             ; FC4C25  ld C,(XWA+0x0b)
	and	c, 0xC0                                ; FC4C28  and C,0xc0
	jr z, Pack104_SetInputs_PartRecord__FC4C69                   ; FC4C2B  jr Z,0xfc4c69
Pack104_SetInputs_PartRecord__FC4C2D:
	extz	xde                                   ; FC4C2D  extz XDE
	ld	(xde+9), 0                              ; FC4C2F  ld (XDE+0x09),0x00
	extpfx5 0x9A, 0x07, 0x3C, 0x8F, 0xFF       ; FC4C33  and (XDE+0x07),0xff8f
	ld	bc, (xde+7)                             ; FC4C38  ld BC,(XDE+0x07)
	set	4, bc                                  ; FC4C3B  set 0x04,BC
	ld	(xde+7), bc                             ; FC4C3E  ld (XDE+0x07),BC
	ld	bc, de                                  ; FC4C41  ld BC,DE
	extz	xde                                   ; FC4C43  extz XDE
	extpfx2 0xB2, 0xCF                         ; FC4C45  bit 7,(XDE)
	jr z, Pack104_SetInputs_PartRecord__FC4C51                   ; FC4C47  jr Z,0xfc4c51
	extz	xhl                                   ; FC4C49  extz XHL
	ld	(xhl+9), 0                              ; FC4C4B  ld (XHL+0x09),0x00
	jr Pack104_SetInputs_PartRecord__FC4C57                      ; FC4C4F  jr T,0xfc4c57
Pack104_SetInputs_PartRecord__FC4C51:
	extz	xhl                                   ; FC4C51  extz XHL
	ld	(xhl+9), 1                              ; FC4C53  ld (XHL+0x09),0x01
Pack104_SetInputs_PartRecord__FC4C57:
	extz	xhl                                   ; FC4C57  extz XHL
	extpfx5 0x9B, 0x07, 0x3C, 0x8F, 0xFF       ; FC4C59  and (XHL+0x07),0xff8f
	ld	bc, (xhl+7)                             ; FC4C5E  ld BC,(XHL+0x07)
	set	4, bc                                  ; FC4C61  set 0x04,BC
	ld	(xhl+7), bc                             ; FC4C64  ld (XHL+0x07),BC
	jr Pack104_SetInputs_PartRecord__FC4C7F                      ; FC4C67  jr T,0xfc4c7f
Pack104_SetInputs_PartRecord__FC4C69:
	extz	xde                                   ; FC4C69  extz XDE
	ld	(xde+9), 0                              ; FC4C6B  ld (XDE+0x09),0x00
	extpfx5 0x9A, 0x07, 0x3C, 0x8F, 0xFF       ; FC4C6F  and (XDE+0x07),0xff8f
	extz	xhl                                   ; FC4C74  extz XHL
	ld	(xhl+9), 1                              ; FC4C76  ld (XHL+0x09),0x01
	extpfx5 0x9B, 0x07, 0x3C, 0x8F, 0xFF       ; FC4C7A  and (XHL+0x07),0xff8f
Pack104_SetInputs_PartRecord__FC4C7F:
	pop	xix                                    ; FC4C7F  pop XIX
	pop	xde                                    ; FC4C80  pop XDE
	pop	xhl                                    ; FC4C81  pop XHL
	unlk32 xiz                                 ; FC4C82  unlk XIZ
	ret                                        ; FC4C84  ret
; --------------------------------------------------------------------------
; Pack104_SetInputs_SubRecordPair -- 0xFC4C85..0xFC4D62 (222 bytes)
;
; Called from: 5 site(s) outside this module:
;          0xFB36F5 in MidiNote_OnTail, 0xFB3802 in MidiNote_OffTail
;          0xFB391C in MidiNote_OnByPartMode__FB38DD, 0xFB3A67 in MidiNote_OnByPartMode__FB3A28
;          0xFB3B85 in MidiNote_OnByPartMode__FB3B4D
; Inputs:  frame `link XIZ,-8`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: writes 0x00E084
;          reads 0x00E082
; Calls:   0xFC405E = sub_FC405E, 0xFC40A9 = sub_FC40A9
; Evidence: the listing below is the byte-identical round-trip of 0xFC4C85-0xFC4D62
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ ROUND 6 ------------------------------------------------------------
; Pack104_SetInputs_SubRecordPair -- sets the two
;          sub-record pointers the packer reads: 0x00E084 = (0x00E082) + 0x2A*arg + 0x13 (a
;          42-byte sub-record at +0x13 inside the part record; 187 - 19 = 168 = 4 x 42) and
;          0x00E086 = 0x00753E + 0x25*arg (a 37-byte record array), the latter through
;          `lda XIX,0x00e086` at 0xFC4C8C.
;          Called from the same five MidiNote_* paths as Pack104_SetInputs_PartRecord.
;          Unknown: what either sub-record IS.
; --------------------------------------------------------------------------
Pack104_SetInputs_SubRecordPair:
	link32 0xEE, 0x0C, 0xF8, 0xFF              ; FC4C85  link XIZ,0xfff8
	pushw	hl                                   ; FC4C89  push HL
	push	xde                                   ; FC4C8A  push XDE
	push	xix                                   ; FC4C8B  push XIX
	lda	xix, (0xE086:24)                       ; FC4C8C  lda XIX,0x00e086
	ld	l, (xiz+8)                              ; FC4C91  ld L,(XIZ+0x08)
	ldb	c, 42                                  ; FC4C94  ld C,0x2a
	mul8rr	c, l                                ; FC4C96  mul BC,L
	add	bc, 19                                 ; FC4C98  add BC,0x0013
	ld	de, bc                                  ; FC4C9C  ld DE,BC
	addda16_24	de, (0xE082)                    ; FC4C9E  add DE,(0x00e082)
	stw_da	(0xE084), de                        ; FC4CA3  ld (0x00e084),DE
	ldb	c, 37                                  ; FC4CA8  ld C,0x25
	extpfx3 0x8E, 0x0A, 0x43                   ; FC4CAA  mul BC,(XIZ+0x0a)
	ld	(xiz-2), bc                             ; FC4CAD  ld (XIZ+0xfe),BC
	ldw	wa, 0x753E                             ; FC4CB0  ld WA,0x753e
	add	wa, bc                                 ; FC4CB3  add WA,BC
	ld	(xiz-4), wa                             ; FC4CB5  ld (XIZ+0xfc),WA
	ld	(xix), wa                               ; FC4CB8  ld (XIX),WA
	ld	bc, (xiz-4)                             ; FC4CBA  ld BC,(XIZ+0xfc)
	extz	xbc                                   ; FC4CBD  extz XBC
	ld	(xbc+5), de                             ; FC4CBF  ld (XBC+0x05),DE
	extz	xde                                   ; FC4CC2  extz XDE
	ld	xbc, (xde+3)                            ; FC4CC4  ld XBC,(XDE+0x03)
	ld	(xiz-8), xbc                            ; FC4CC7  ld (XIZ+0xf8),XBC
	ld	wa, (xix)                               ; FC4CCA  ld WA,(XIX)
	extz	xwa                                   ; FC4CCC  extz XWA
	ld	(xwa+1), xbc                            ; FC4CCE  ld (XWA+0x01),XBC
	ld	bc, (0xE082:24)                        ; FC4CD1  ld BC,(0x00e082)
	extz	xbc                                   ; FC4CD6  extz XBC
	ld	d, (xbc)                                ; FC4CD8  ld D,(XBC)
	ld	wa, (xix)                               ; FC4CDA  ld WA,(XIX)
	extz	xwa                                   ; FC4CDC  extz XWA
	ld	(xwa), d                                ; FC4CDE  ld (XWA),D
	ld	bc, (xix)                               ; FC4CE0  ld BC,(XIX)
	extz	xbc                                   ; FC4CE2  extz XBC
	ld	h, (xbc+7)                              ; FC4CE4  ld H,(XBC+0x07)
	cp	h, 64                                   ; FC4CE7  cp H,0x40
	jr nc, Pack104_SetInputs_SubRecordPair__FC4CF4                  ; FC4CEA  jr NC,0xfc4cf4
	push	0                                     ; FC4CEC  push 0x00
	push	h                                     ; FC4CEE  push H
	calr (0xFC40A9 - 0xFC4CF3)                 ; FC4CF0  calr 0xfc40a9
	popw	bc                                    ; FC4CF3  pop BC
Pack104_SetInputs_SubRecordPair__FC4CF4:
	ld	bc, (0xE084:24)                        ; FC4CF4  ld BC,(0x00e084)
	extz	xbc                                   ; FC4CF9  extz XBC
	ld	h, (xbc+9)                              ; FC4CFB  ld H,(XBC+0x09)
	cp	h, l                                    ; FC4CFE  cp H,L
	jr z, Pack104_SetInputs_SubRecordPair__FC4D1B                   ; FC4D00  jr Z,0xfc4d1b
	ld	a, h                                    ; FC4D02  ld A,H
	extz	wa                                    ; FC4D04  extz WA
	extz	xwa                                   ; FC4D06  extz XWA
	add	xwa, 0xE08F                            ; FC4D08  add XWA,0x0000e08f
	ld	h, (xwa)                                ; FC4D0E  ld H,(XWA)
	cp	h, 64                                   ; FC4D10  cp H,0x40
	jr nc, Pack104_SetInputs_SubRecordPair__FC4D1B                  ; FC4D13  jr NC,0xfc4d1b
	push	0                                     ; FC4D15  push 0x00
	push	h                                     ; FC4D17  push H
	jr Pack104_SetInputs_SubRecordPair__FC4D1E                      ; FC4D19  jr T,0xfc4d1e
Pack104_SetInputs_SubRecordPair__FC4D1B:
	pushw	0xFF                                 ; FC4D1B  push 0x00ff
Pack104_SetInputs_SubRecordPair__FC4D1E:
	calr (0xFC405E - 0xFC4D21)                 ; FC4D1E  calr 0xfc405e
	ld	h, a                                    ; FC4D21  ld H,A
	ld	bc, (xix)                               ; FC4D23  ld BC,(XIX)
	extz	xbc                                   ; FC4D25  extz XBC
	ld	(xbc+7), a                              ; FC4D27  ld (XBC+0x07),A
	ld	bc, (xix)                               ; FC4D2A  ld BC,(XIX)
	extz	xbc                                   ; FC4D2C  extz XBC
	ld	h, (xbc+7)                              ; FC4D2E  ld H,(XBC+0x07)
	ld	c, l                                    ; FC4D31  ld C,L
	extz	bc                                    ; FC4D33  extz BC
	extz	xbc                                   ; FC4D35  extz XBC
	add	xbc, 0xE08F                            ; FC4D37  add XBC,0x0000e08f
	ld	(xbc), h                                ; FC4D3D  ld (XBC),H
	ld	bc, (xix)                               ; FC4D3F  ld BC,(XIX)
	extz	xbc                                   ; FC4D41  extz XBC
	ld	a, (xbc+7)                              ; FC4D43  ld A,(XBC+0x07)
	extz	wa                                    ; FC4D46  extz WA
	ld	hl, wa                                  ; FC4D48  ld HL,WA
	sll	hl, 8                                  ; FC4D4A  sll 0x08,HL
	ld	xbc, (xiz+12)                           ; FC4D4D  ld XBC,(XIZ+0x0c)
	ld	(xbc), hl                               ; FC4D50  ld (XBC),HL
	ld	bc, hl                                  ; FC4D52  ld BC,HL
	set	2, bc                                  ; FC4D54  set 0x02,BC
	ld	xwa, (xiz+12)                           ; FC4D57  ld XWA,(XIZ+0x0c)
	ld	(xwa), bc                               ; FC4D5A  ld (XWA),BC
	popw	bc                                    ; FC4D5C  pop BC
	pop	xix                                    ; FC4D5D  pop XIX
	pop	xde                                    ; FC4D5E  pop XDE
	popw	hl                                    ; FC4D5F  pop HL
	unlk32 xiz                                 ; FC4D60  unlk XIZ
	ret                                        ; FC4D62  ret
; --------------------------------------------------------------------------
; Pack104_SetInputs_E088_E089_E08A -- 0xFC4D63..0xFC4D84 (34 bytes)
;
; Called from: 4 site(s) outside this module:
;          0xFB0AF8 in VoiceRegs_Stage_A, 0xFB1EE6 in VoiceRegs_Stage_B
;          0xFB2816 in VoiceRegs_Stage_C, 0xFB2EDF in VoiceRegs_Stage_D
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x0A), (XIZ+0x0C), (XIZ+0x0E)
; Outputs: writes 0x00E088, 0x00E089, 0x00E08A
; Evidence: the listing below is the byte-identical round-trip of 0xFC4D63-0xFC4D84
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ WHAT IT DOES: it is a SETTER for the argument block the 0x00104000 packer reads.
;   VoiceRegs_Stage_A's header identifies 0xFC4DBD as that packer and RAM
;   0x00E082..0x00E08D as its inputs; this routine writes three of them and nothing else:
;     0xFC4D6A  res 0x07,C          bit 7 of (XIZ+0x0c) is dropped
;     0xFC4D6D  ld (0x00E088),C     a BYTE
;     0xFC4D75  ld (0x00E08A),BC    a WORD, from (XIZ+0x0a)
;     0xFC4D7D  ld (0x00E089),A     a BYTE, from (XIZ+0x0e)
;   0x00E088 and 0x00E089 are adjacent bytes written from DIFFERENT arguments, so they are
;   two fields and not one word -- which is the only thing an address list alone cannot say.
; Evidence: those three stores are the entire body between `link` and `unlk`; the address
;          list in the "Outputs:" line above is gen_prom_c_block_headers.py's
;          instruction-operand scan, and the mask is the `res 0x07,C` opcode at 0xFC4D6A.
; Unknown:  what each field feeds.  The name records WHERE the values go; "Pack104" is the
;          packer this block belongs to, not a decoded meaning.
; --------------------------------------------------------------------------
Pack104_SetInputs_E088_E089_E08A:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC4D63  link XIZ,0x0000
	ld	c, (xiz+12)                             ; FC4D67  ld C,(XIZ+0x0c)
	res	7, c                                   ; FC4D6A  res 0x07,C
	stb_da	(0xE088), c                         ; FC4D6D  ld (0x00e088),C
	ld	bc, (xiz+10)                            ; FC4D72  ld BC,(XIZ+0x0a)
	stw_da	(0xE08A), bc                        ; FC4D75  ld (0x00e08a),BC
	ld	a, (xiz+14)                             ; FC4D7A  ld A,(XIZ+0x0e)
	stb_da	(0xE089), a                         ; FC4D7D  ld (0x00e089),A
	unlk32 xiz                                 ; FC4D82  unlk XIZ
	ret                                        ; FC4D84  ret
; --------------------------------------------------------------------------
; Pack104_SetInputs_Rec0C_E08C -- 0xFC4D85..0xFC4DA0 (28 bytes)
;
; Called from: 4 site(s) outside this module:
;          0xFA74A0 in KeyZone_Stage_Reg0040_Stride8, 0xFA74E2 in KeyZone_Stage_Reg0040_Stride6A
;          0xFA7524 in KeyZone_Stage_Reg0040_Stride6B, 0xFA7565 in KeyZone_Stage_Reg0040_Stride4
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x0A), (XIZ+0x0C)
; Outputs: writes 0x00E08C
;          reads 0x00E086
; Evidence: the listing below is the byte-identical round-trip of 0xFC4D85-0xFC4DA0
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ WHAT IT DOES: one store THROUGH the pointer at RAM 0x00E086 and one scalar store.
;     0xFC4D89  ld BC,(0x00E086) / extz XBC   0x00E086 is a POINTER, not a scalar
;     0xFC4D93  ld (XBC+0x0c),WA              field +0x0C of the pointed-to record
;     0xFC4D99  ld (0x00E08C),C               a BYTE, from (XIZ+0x0a)
;   So the 0x00E082..0x00E08D block mixes two kinds of slot -- a pointer and scalars -- and
;   this routine is the one that proves it, by dereferencing one of them.
; Evidence: the two stores are the whole body; `ld BC,(0x00E086)` is an absolute LOAD and
;          `ld (XBC+0x0c),WA` an indexed store, so the indirection is in the opcodes.
;          0x00E086 is named on 69 addressed lines of prom_c (`--claims C11`).
; Unknown:  what field +0x0C of the record is, and what 0x00E08C selects.  Called only
;          from the four KeyZone_Stage_Reg0040_Stride* routines listed above.
; --------------------------------------------------------------------------
Pack104_SetInputs_Rec0C_E08C:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC4D85  link XIZ,0x0000
	ld	bc, (0xE086:24)                        ; FC4D89  ld BC,(0x00e086)
	extz	xbc                                   ; FC4D8E  extz XBC
	ld	wa, (xiz+12)                            ; FC4D90  ld WA,(XIZ+0x0c)
	ld	(xbc+12), wa                            ; FC4D93  ld (XBC+0x0c),WA
	ld	c, (xiz+10)                             ; FC4D96  ld C,(XIZ+0x0a)
	stb_da	(0xE08C), c                         ; FC4D99  ld (0x00e08c),C
	unlk32 xiz                                 ; FC4D9E  unlk XIZ
	ret                                        ; FC4DA0  ret
; --------------------------------------------------------------------------
; Pack104_SetInputs_Rec0E_E08D -- 0xFC4DA1..0xFC4DBC (28 bytes)
;
; Called from: 4 site(s) outside this module:
;          0xFB0B57 in VoiceRegs_Stage_A, 0xFB1F38 in VoiceRegs_Stage_B
;          0xFB285C in VoiceRegs_Stage_C, 0xFB2F31 in VoiceRegs_Stage_D
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: writes 0x00E08D
;          reads 0x00E086
; Evidence: the listing below is the byte-identical round-trip of 0xFC4DA1-0xFC4DBC
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ WHAT IT DOES: the +0x0E sibling of Pack104_SetInputs_Rec0C_E08C above.
;     0xFC4DA5  ld BC,(0x00E086) / extz XBC   the same pointer
;     0xFC4DAF  ld (XBC+0x0e),WA              field +0x0E, from (XIZ+0x08)
;     0xFC4DB5  ld (0x00E08D),BC              a WORD, from (XIZ+0x0a)
;   ⚠ Note the asymmetry with its sibling, which is in the opcodes and not a slip: 0x00E08C
;   is written as a BYTE (`ld (0x00E08C),C`) and 0x00E08D as a WORD (`ld (0x00E08D),BC`),
;   so the two overlap unless they are never both live.  Nothing here resolves that.
; Evidence: the three instructions above are the entire body between `link` and `unlk`.
; Unknown:  what field +0x0E is.  Called from VoiceRegs_Stage_A..D, one site each.
; --------------------------------------------------------------------------
Pack104_SetInputs_Rec0E_E08D:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC4DA1  link XIZ,0x0000
	ld	bc, (0xE086:24)                        ; FC4DA5  ld BC,(0x00e086)
	extz	xbc                                   ; FC4DAA  extz XBC
	ld	wa, (xiz+8)                             ; FC4DAC  ld WA,(XIZ+0x08)
	ld	(xbc+14), wa                            ; FC4DAF  ld (XBC+0x0e),WA
	ld	bc, (xiz+10)                            ; FC4DB2  ld BC,(XIZ+0x0a)
	stw_da	(0xE08D), bc                        ; FC4DB5  ld (0x00e08d),BC
	unlk32 xiz                                 ; FC4DBA  unlk XIZ
	ret                                        ; FC4DBC  ret
; --------------------------------------------------------------------------
; Dev104_PackStagingStruct -- 0xFC4DBD..0xFC56C3 (2311 bytes)
;
; Called from: 3 site(s) outside this module:
;          0xFB0B61 in VoiceRegs_Stage_A, 0xFB2866 in VoiceRegs_Stage_C
;          0xFB2F3B in VoiceRegs_Stage_D
; Inputs:  frame `link XIZ,-18`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
;          reads 0x00E082, 0x00E084, 0x00E086, 0x00E088, 0x00E089, 0x00E08A, 0x00E08C, 0x00E08D, 0x00F2F3
; Calls:   0xFC49AD = sub_FC49AD, 0xFC4AED = sub_FC4AED
;          0xFCB11B = Multiply32
; Evidence: the listing below is the byte-identical round-trip of 0xFC4DBD-0xFC56C3
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ ROUND 6 ------------------------------------------------------------
; ★ Dev104_PackStagingStruct -- the ONE routine that fills the
;          0x00104000 staging struct.  Its only argument is the struct pointer, and it makes
;          19 WRITE SITES over 16 DISTINCT OFFSETS inside 0x00..0x24 -- the same span
;          Dev104_WriteAllChanRegs reads as 19 consecutive words.
;          ⚠ CORRECTION: notes/FINDINGS-prom_c-dev10c-producers.md §3 says "writes 19 offsets
;          in 0x00..0x24".  Nineteen is the number of WRITE SITES; the distinct offsets are
;          16, of which 15 are even (whole words) and one (+0x1D) is a high-byte write.  Four
;          of the nineteen even fields -- +0x06, +0x08, +0x12 and +0x16 -- are not written by
;          this routine's own instructions at all; +0x06 and +0x08 come from sub_FC49AD, which
;          it calls at 0xFC56AA.
;          Its inputs are the globals 0x00E082-0x00E08D, set by Pack104_SetInputs_PartRecord,
;          Pack104_SetInputs_SubRecordPair, Pack104_SetInputs_E088_E089_E08A and
;          Pack104_SetInputs_Rec0E_E08D.
;          Evidence: `python3 notes/prom_c_understanding_round6.py --packer`, which counts the
;          sites and the offsets with notes/prom_c_dev10c_field_sources.py's own scanner and
;          asserts 19/16/15.
; --------------------------------------------------------------------------
Dev104_PackStagingStruct:
	link32 0xEE, 0x0C, 0xEE, 0xFF              ; FC4DBD  link XIZ,0xffee
	pushw	hl                                   ; FC4DC1  push HL
	pushw	de                                   ; FC4DC2  push DE
	push	xix                                   ; FC4DC3  push XIX
	ld	bc, (0xE084:24)                        ; FC4DC4  ld BC,(0x00e084)
	extz	xbc                                   ; FC4DC9  extz XBC
	ld	xwa, (xbc+3)                            ; FC4DCB  ld XWA,(XBC+0x03)
	ld	(xiz-4), xwa                            ; FC4DCE  ld (XIZ+0xfc),XWA
	ld	iy, (xbc+7)                             ; FC4DD1  ld IY,(XBC+0x07)
	ld	(xiz-16), iy                            ; FC4DD4  ld (XIZ+0xf0),IY
	ld	xbc, (xiz+8)                            ; FC4DD7  ld XBC,(XIZ+0x08)
	ld	(xbc), iy                               ; FC4DDA  ld (XBC),IY
	ld	bc, (0xE086:24)                        ; FC4DDC  ld BC,(0x00e086)
	extz	xbc                                   ; FC4DE1  extz XBC
	ld	a, (xbc+7)                              ; FC4DE3  ld A,(XBC+0x07)
	extz	wa                                    ; FC4DE6  extz WA
	sll	wa, 8                                  ; FC4DE8  sll 0x08,WA
	extpfx3 0x9E, 0xF0, 0xE0                   ; FC4DEB  or WA,(XIZ+0xf0)
	ld	xiy, (xiz+8)                            ; FC4DEE  ld XIY,(XIZ+0x08)
	ld	(xiy), wa                               ; FC4DF1  ld (XIY),WA
	ld	bc, (0xE084:24)                        ; FC4DF3  ld BC,(0x00e084)
	extz	xbc                                   ; FC4DF8  extz XBC
	ld	de, (xbc+18)                            ; FC4DFA  ld DE,(XBC+0x12)
	ld	ix, (xbc+10)                            ; FC4DFD  ld IX,(XBC+0x0a)
	ld	hl, ix                                  ; FC4E00  ld HL,IX
	add	hl, de                                 ; FC4E02  add HL,DE
	cps	hl, 0                                  ; FC4E04  cp HL,0
	jr ge, Dev104_PackStagingStruct__FC4E13                  ; FC4E06  jr GE,0xfc4e13
	cps	ix, 0                                  ; FC4E08  cp IX,0
	jr lt, Dev104_PackStagingStruct__FC4E13                  ; FC4E0A  jr LT,0xfc4e13
	cps	de, 0                                  ; FC4E0C  cp DE,0
	jr lt, Dev104_PackStagingStruct__FC4E13                  ; FC4E0E  jr LT,0xfc4e13
	ldw	hl, 0x7FFF                             ; FC4E10  ld HL,0x7fff
Dev104_PackStagingStruct__FC4E13:
	cps	hl, 0                                  ; FC4E13  cp HL,0
	jr le, Dev104_PackStagingStruct__FC4E22                  ; FC4E15  jr LE,0xfc4e22
	cps	ix, 0                                  ; FC4E17  cp IX,0
	jr ge, Dev104_PackStagingStruct__FC4E22                  ; FC4E19  jr GE,0xfc4e22
	cps	de, 0                                  ; FC4E1B  cp DE,0
	jr ge, Dev104_PackStagingStruct__FC4E22                  ; FC4E1D  jr GE,0xfc4e22
	ldw	hl, 0                                  ; FC4E1F  ld HL,0x0000
Dev104_PackStagingStruct__FC4E22:
	ld	(xiz-6), hl                             ; FC4E22  ld (XIZ+0xfa),HL
	ld	xbc, (xiz-4)                            ; FC4E25  ld XBC,(XIZ+0xfc)
	ld	a, (xbc+22)                             ; FC4E28  ld A,(XBC+0x16)
	and	a, 0x80                                ; FC4E2B  and A,0x80
	jr z, Dev104_PackStagingStruct__FC4E66                   ; FC4E2E  jr Z,0xfc4e66
	ld	de, (0xE08A:24)                        ; FC4E30  ld DE,(0x00e08a)
	ld	wa, (0xE08D:24)                        ; FC4E35  ld WA,(0x00e08d)
	sub	de, wa                                 ; FC4E3A  sub DE,WA
	ld	ix, (xiz-6)                             ; FC4E3C  ld IX,(XIZ+0xfa)
	ld	hl, (xiz-6)                             ; FC4E3F  ld HL,(XIZ+0xfa)
	ld	iy, de                                  ; FC4E42  ld IY,DE
	add	hl, iy                                 ; FC4E44  add HL,IY
	cps	hl, 0                                  ; FC4E46  cp HL,0
	jr ge, Dev104_PackStagingStruct__FC4E55                  ; FC4E48  jr GE,0xfc4e55
	cps	ix, 0                                  ; FC4E4A  cp IX,0
	jr lt, Dev104_PackStagingStruct__FC4E55                  ; FC4E4C  jr LT,0xfc4e55
	cps	iy, 0                                  ; FC4E4E  cp IY,0
	jr lt, Dev104_PackStagingStruct__FC4E55                  ; FC4E50  jr LT,0xfc4e55
	ldw	hl, 0x7FFF                             ; FC4E52  ld HL,0x7fff
Dev104_PackStagingStruct__FC4E55:
	cps	hl, 0                                  ; FC4E55  cp HL,0
	jr le, Dev104_PackStagingStruct__FC4E64                  ; FC4E57  jr LE,0xfc4e64
	cps	ix, 0                                  ; FC4E59  cp IX,0
	jr ge, Dev104_PackStagingStruct__FC4E64                  ; FC4E5B  jr GE,0xfc4e64
	cps	de, 0                                  ; FC4E5D  cp DE,0
	jr ge, Dev104_PackStagingStruct__FC4E64                  ; FC4E5F  jr GE,0xfc4e64
	ldw	hl, 0                                  ; FC4E61  ld HL,0x0000
Dev104_PackStagingStruct__FC4E64:
	jr Dev104_PackStagingStruct__FC4E9C                      ; FC4E64  jr T,0xfc4e9c
Dev104_PackStagingStruct__FC4E66:
	ld	bc, (0xE086:24)                        ; FC4E66  ld BC,(0x00e086)
	extz	xbc                                   ; FC4E6B  extz XBC
	ld	de, (xbc+12)                            ; FC4E6D  ld DE,(XBC+0x0c)
	ld	wa, de                                  ; FC4E70  ld WA,DE
	neg	wa                                     ; FC4E72  neg WA
	ld	de, wa                                  ; FC4E74  ld DE,WA
	ld	ix, (xiz-6)                             ; FC4E76  ld IX,(XIZ+0xfa)
	ld	hl, (xiz-6)                             ; FC4E79  ld HL,(XIZ+0xfa)
	add	hl, wa                                 ; FC4E7C  add HL,WA
	cps	hl, 0                                  ; FC4E7E  cp HL,0
	jr ge, Dev104_PackStagingStruct__FC4E8D                  ; FC4E80  jr GE,0xfc4e8d
	cps	ix, 0                                  ; FC4E82  cp IX,0
	jr lt, Dev104_PackStagingStruct__FC4E8D                  ; FC4E84  jr LT,0xfc4e8d
	cps	wa, 0                                  ; FC4E86  cp WA,0
	jr lt, Dev104_PackStagingStruct__FC4E8D                  ; FC4E88  jr LT,0xfc4e8d
	ldw	hl, 0x7FFF                             ; FC4E8A  ld HL,0x7fff
Dev104_PackStagingStruct__FC4E8D:
	cps	hl, 0                                  ; FC4E8D  cp HL,0
	jr le, Dev104_PackStagingStruct__FC4E9C                  ; FC4E8F  jr LE,0xfc4e9c
	cps	ix, 0                                  ; FC4E91  cp IX,0
	jr ge, Dev104_PackStagingStruct__FC4E9C                  ; FC4E93  jr GE,0xfc4e9c
	cps	de, 0                                  ; FC4E95  cp DE,0
	jr ge, Dev104_PackStagingStruct__FC4E9C                  ; FC4E97  jr GE,0xfc4e9c
	ldw	hl, 0                                  ; FC4E99  ld HL,0x0000
Dev104_PackStagingStruct__FC4E9C:
	ld	xbc, (xiz+8)                            ; FC4E9C  ld XBC,(XIZ+0x08)
	ld	(xbc+2), hl                             ; FC4E9F  ld (XBC+0x02),HL
	ld	bc, (0xE084:24)                        ; FC4EA2  ld BC,(0x00e084)
	extz	xbc                                   ; FC4EA7  extz XBC
	ld	de, (xbc+20)                            ; FC4EA9  ld DE,(XBC+0x14)
	ld	ix, (xbc+12)                            ; FC4EAC  ld IX,(XBC+0x0c)
	ld	hl, ix                                  ; FC4EAF  ld HL,IX
	add	hl, de                                 ; FC4EB1  add HL,DE
	cps	hl, 0                                  ; FC4EB3  cp HL,0
	jr ge, Dev104_PackStagingStruct__FC4EC2                  ; FC4EB5  jr GE,0xfc4ec2
	cps	ix, 0                                  ; FC4EB7  cp IX,0
	jr lt, Dev104_PackStagingStruct__FC4EC2                  ; FC4EB9  jr LT,0xfc4ec2
	cps	de, 0                                  ; FC4EBB  cp DE,0
	jr lt, Dev104_PackStagingStruct__FC4EC2                  ; FC4EBD  jr LT,0xfc4ec2
	ldw	hl, 0x7FFF                             ; FC4EBF  ld HL,0x7fff
Dev104_PackStagingStruct__FC4EC2:
	cps	hl, 0                                  ; FC4EC2  cp HL,0
	jr le, Dev104_PackStagingStruct__FC4ED1                  ; FC4EC4  jr LE,0xfc4ed1
	cps	ix, 0                                  ; FC4EC6  cp IX,0
	jr ge, Dev104_PackStagingStruct__FC4ED1                  ; FC4EC8  jr GE,0xfc4ed1
	cps	de, 0                                  ; FC4ECA  cp DE,0
	jr ge, Dev104_PackStagingStruct__FC4ED1                  ; FC4ECC  jr GE,0xfc4ed1
	ldw	hl, 0                                  ; FC4ECE  ld HL,0x0000
Dev104_PackStagingStruct__FC4ED1:
	ld	(xiz-6), hl                             ; FC4ED1  ld (XIZ+0xfa),HL
	ld	xbc, (xiz-4)                            ; FC4ED4  ld XBC,(XIZ+0xfc)
	ld	a, (xbc+32)                             ; FC4ED7  ld A,(XBC+0x20)
	and	a, 0x80                                ; FC4EDA  and A,0x80
	jr z, Dev104_PackStagingStruct__FC4F15                   ; FC4EDD  jr Z,0xfc4f15
	ld	de, (0xE08A:24)                        ; FC4EDF  ld DE,(0x00e08a)
	ld	wa, (0xE08D:24)                        ; FC4EE4  ld WA,(0x00e08d)
	sub	de, wa                                 ; FC4EE9  sub DE,WA
	ld	ix, (xiz-6)                             ; FC4EEB  ld IX,(XIZ+0xfa)
	ld	hl, (xiz-6)                             ; FC4EEE  ld HL,(XIZ+0xfa)
	ld	iy, de                                  ; FC4EF1  ld IY,DE
	add	hl, iy                                 ; FC4EF3  add HL,IY
	cps	hl, 0                                  ; FC4EF5  cp HL,0
	jr ge, Dev104_PackStagingStruct__FC4F04                  ; FC4EF7  jr GE,0xfc4f04
	cps	ix, 0                                  ; FC4EF9  cp IX,0
	jr lt, Dev104_PackStagingStruct__FC4F04                  ; FC4EFB  jr LT,0xfc4f04
	cps	iy, 0                                  ; FC4EFD  cp IY,0
	jr lt, Dev104_PackStagingStruct__FC4F04                  ; FC4EFF  jr LT,0xfc4f04
	ldw	hl, 0x7FFF                             ; FC4F01  ld HL,0x7fff
Dev104_PackStagingStruct__FC4F04:
	cps	hl, 0                                  ; FC4F04  cp HL,0
	jr le, Dev104_PackStagingStruct__FC4F13                  ; FC4F06  jr LE,0xfc4f13
	cps	ix, 0                                  ; FC4F08  cp IX,0
	jr ge, Dev104_PackStagingStruct__FC4F13                  ; FC4F0A  jr GE,0xfc4f13
	cps	de, 0                                  ; FC4F0C  cp DE,0
	jr ge, Dev104_PackStagingStruct__FC4F13                  ; FC4F0E  jr GE,0xfc4f13
	ldw	hl, 0                                  ; FC4F10  ld HL,0x0000
Dev104_PackStagingStruct__FC4F13:
	jr Dev104_PackStagingStruct__FC4F4B                      ; FC4F13  jr T,0xfc4f4b
Dev104_PackStagingStruct__FC4F15:
	ld	bc, (0xE086:24)                        ; FC4F15  ld BC,(0x00e086)
	extz	xbc                                   ; FC4F1A  extz XBC
	ld	de, (xbc+12)                            ; FC4F1C  ld DE,(XBC+0x0c)
	ld	wa, de                                  ; FC4F1F  ld WA,DE
	neg	wa                                     ; FC4F21  neg WA
	ld	de, wa                                  ; FC4F23  ld DE,WA
	ld	ix, (xiz-6)                             ; FC4F25  ld IX,(XIZ+0xfa)
	ld	hl, (xiz-6)                             ; FC4F28  ld HL,(XIZ+0xfa)
	add	hl, wa                                 ; FC4F2B  add HL,WA
	cps	hl, 0                                  ; FC4F2D  cp HL,0
	jr ge, Dev104_PackStagingStruct__FC4F3C                  ; FC4F2F  jr GE,0xfc4f3c
	cps	ix, 0                                  ; FC4F31  cp IX,0
	jr lt, Dev104_PackStagingStruct__FC4F3C                  ; FC4F33  jr LT,0xfc4f3c
	cps	wa, 0                                  ; FC4F35  cp WA,0
	jr lt, Dev104_PackStagingStruct__FC4F3C                  ; FC4F37  jr LT,0xfc4f3c
	ldw	hl, 0x7FFF                             ; FC4F39  ld HL,0x7fff
Dev104_PackStagingStruct__FC4F3C:
	cps	hl, 0                                  ; FC4F3C  cp HL,0
	jr le, Dev104_PackStagingStruct__FC4F4B                  ; FC4F3E  jr LE,0xfc4f4b
	cps	ix, 0                                  ; FC4F40  cp IX,0
	jr ge, Dev104_PackStagingStruct__FC4F4B                  ; FC4F42  jr GE,0xfc4f4b
	cps	de, 0                                  ; FC4F44  cp DE,0
	jr ge, Dev104_PackStagingStruct__FC4F4B                  ; FC4F46  jr GE,0xfc4f4b
	ldw	hl, 0                                  ; FC4F48  ld HL,0x0000
Dev104_PackStagingStruct__FC4F4B:
	ld	xbc, (xiz+8)                            ; FC4F4B  ld XBC,(XIZ+0x08)
	ld	(xbc+4), hl                             ; FC4F4E  ld (XBC+0x04),HL
	lda	xix, (0xFE0116:24)                     ; FC4F51  lda XIX,0xfe0116
	ld	xbc, (xiz-4)                            ; FC4F56  ld XBC,(XIZ+0xfc)
	ld	a, (xbc+23)                             ; FC4F59  ld A,(XBC+0x17)
	exts	wa                                    ; FC4F5C  exts WA
	ld	hl, wa                                  ; FC4F5E  ld HL,WA
	ldb_da	d, (0xE088)                         ; FC4F60  ld D,(0x00e088)
	cps	wa, 0                                  ; FC4F65  cp WA,0
	jr nz, Dev104_PackStagingStruct__FC4F70                  ; FC4F67  jr NZ,0xfc4f70
	ldw (xiz-8), 0x0000                        ; FC4F69  ld (XIZ+0xf8),0x0000
	jr Dev104_PackStagingStruct__FC4F99                      ; FC4F6E  jr T,0xfc4f99
Dev104_PackStagingStruct__FC4F70:
	cps	hl, 0                                  ; FC4F70  cp HL,0
	jr ge, Dev104_PackStagingStruct__FC4F85                  ; FC4F72  jr GE,0xfc4f85
	ld	c, d                                    ; FC4F74  ld C,D
	extz	bc                                    ; FC4F76  extz BC
	ldw	wa, 0x7F                               ; FC4F78  ld WA,0x007f
	sub	wa, bc                                 ; FC4F7B  sub WA,BC
	ld	d, a                                    ; FC4F7D  ld D,A
	ld	bc, hl                                  ; FC4F7F  ld BC,HL
	neg	bc                                     ; FC4F81  neg BC
	ld	hl, bc                                  ; FC4F83  ld HL,BC
Dev104_PackStagingStruct__FC4F85:
	ld	c, d                                    ; FC4F85  ld C,D
	extz	bc                                    ; FC4F87  extz BC
	extz	xbc                                   ; FC4F89  extz XBC
	add	xbc, xix                               ; FC4F8B  add XBC,XIX
	ld	a, (xbc)                                ; FC4F8D  ld A,(XBC)
	exts	wa                                    ; FC4F8F  exts WA
	muls	xwa, xhl                              ; FC4F91  muls XWA,HL
	sra	wa, 5                                  ; FC4F93  sra 0x05,WA
	ld	(xiz-8), wa                             ; FC4F96  ld (XIZ+0xf8),WA
Dev104_PackStagingStruct__FC4F99:
	ld	bc, (0xE084:24)                        ; FC4F99  ld BC,(0x00e084)
	extz	xbc                                   ; FC4F9E  extz XBC
	ld	wa, (xbc+22)                            ; FC4FA0  ld WA,(XBC+0x16)
	add	(xiz-8), wa                            ; FC4FA3  add (XIZ+0xf8),WA
	ld	hl, (xiz-8)                             ; FC4FA6  ld HL,(XIZ+0xf8)
	ld	wa, (0xE082:24)                        ; FC4FA9  ld WA,(0x00e082)
	extz	xwa                                   ; FC4FAE  extz XWA
	ld	c, (xwa+17)                             ; FC4FB0  ld C,(XWA+0x11)
	extz	bc                                    ; FC4FB3  extz BC
	ld	de, bc                                  ; FC4FB5  ld DE,BC
	ld	ix, (0xE08C:24)                        ; FC4FB7  ld IX,(0x00e08c)
	exts	ix                                    ; FC4FBC  exts IX
	cp	(xiz-8), bc                             ; FC4FBE  cp (XIZ+0xf8),BC
	jr le, Dev104_PackStagingStruct__FC4FC7                  ; FC4FC1  jr LE,0xfc4fc7
	ld	hl, bc                                  ; FC4FC3  ld HL,BC
	jr Dev104_PackStagingStruct__FC4FCE                      ; FC4FC5  jr T,0xfc4fce
Dev104_PackStagingStruct__FC4FC7:
	cps	hl, 0                                  ; FC4FC7  cp HL,0
	jr ge, Dev104_PackStagingStruct__FC4FCE                  ; FC4FC9  jr GE,0xfc4fce
	ldw	hl, 0                                  ; FC4FCB  ld HL,0x0000
Dev104_PackStagingStruct__FC4FCE:
	cp	hl, 48                                  ; FC4FCE  cp HL,0x0030
	jr ge, Dev104_PackStagingStruct__FC4FE1                  ; FC4FD2  jr GE,0xfc4fe1
	ld	bc, hl                                  ; FC4FD4  ld BC,HL
	sra	bc, 1                                  ; FC4FD6  sra 0x01,BC
	ld	hl, bc                                  ; FC4FD9  ld HL,BC
	add	bc, 24                                 ; FC4FDB  add BC,0x0018
	ld	hl, bc                                  ; FC4FDF  ld HL,BC
Dev104_PackStagingStruct__FC4FE1:
	ldw	bc, 0xCF                               ; FC4FE1  ld BC,0x00cf
	sub	bc, hl                                 ; FC4FE4  sub BC,HL
	ld	hl, bc                                  ; FC4FE6  ld HL,BC
	add	bc, ix                                 ; FC4FE8  add BC,IX
	ld	hl, bc                                  ; FC4FEA  ld HL,BC
	cp	bc, 0xFF                                ; FC4FEC  cp BC,0x00ff
	jr le, Dev104_PackStagingStruct__FC4FF7                  ; FC4FF0  jr LE,0xfc4ff7
	ldw	hl, 0xFF                               ; FC4FF2  ld HL,0x00ff
	jr Dev104_PackStagingStruct__FC4FFE                      ; FC4FF5  jr T,0xfc4ffe
Dev104_PackStagingStruct__FC4FF7:
	cps	hl, 0                                  ; FC4FF7  cp HL,0
	jr ge, Dev104_PackStagingStruct__FC4FFE                  ; FC4FF9  jr GE,0xfc4ffe
	ldw	hl, 0                                  ; FC4FFB  ld HL,0x0000
Dev104_PackStagingStruct__FC4FFE:
	ldw	bc, 2                                  ; FC4FFE  ld BC,0x0002
	muls	xbc, xhl                              ; FC5001  muls XBC,HL
	add	xbc, 0xFDF7E0                          ; FC5003  add XBC,0x00fdf7e0
	ld	bc, (xbc)                               ; FC5009  ld BC,(XBC)
	ld	(xiz-10), bc                            ; FC500B  ld (XIZ+0xf6),BC
	lda	xix, (0xFE0116:24)                     ; FC500E  lda XIX,0xfe0116
	ld	xwa, (xiz-4)                            ; FC5013  ld XWA,(XIZ+0xfc)
	ld	c, (xwa+34)                             ; FC5016  ld C,(XWA+0x22)
	exts	bc                                    ; FC5019  exts BC
	ld	hl, bc                                  ; FC501B  ld HL,BC
	ldb_da	d, (0xE088)                         ; FC501D  ld D,(0x00e088)
	cps	bc, 0                                  ; FC5022  cp BC,0
	jr nz, Dev104_PackStagingStruct__FC502D                  ; FC5024  jr NZ,0xfc502d
	ldw (xiz-12), 0x0000                       ; FC5026  ld (XIZ+0xf4),0x0000
	jr Dev104_PackStagingStruct__FC5056                      ; FC502B  jr T,0xfc5056
Dev104_PackStagingStruct__FC502D:
	cps	hl, 0                                  ; FC502D  cp HL,0
	jr ge, Dev104_PackStagingStruct__FC5042                  ; FC502F  jr GE,0xfc5042
	ld	c, d                                    ; FC5031  ld C,D
	extz	bc                                    ; FC5033  extz BC
	ldw	wa, 0x7F                               ; FC5035  ld WA,0x007f
	sub	wa, bc                                 ; FC5038  sub WA,BC
	ld	d, a                                    ; FC503A  ld D,A
	ld	bc, hl                                  ; FC503C  ld BC,HL
	neg	bc                                     ; FC503E  neg BC
	ld	hl, bc                                  ; FC5040  ld HL,BC
Dev104_PackStagingStruct__FC5042:
	ld	c, d                                    ; FC5042  ld C,D
	extz	bc                                    ; FC5044  extz BC
	extz	xbc                                   ; FC5046  extz XBC
	add	xbc, xix                               ; FC5048  add XBC,XIX
	ld	a, (xbc)                                ; FC504A  ld A,(XBC)
	exts	wa                                    ; FC504C  exts WA
	muls	xwa, xhl                              ; FC504E  muls XWA,HL
	sra	wa, 5                                  ; FC5050  sra 0x05,WA
	ld	(xiz-12), wa                            ; FC5053  ld (XIZ+0xf4),WA
Dev104_PackStagingStruct__FC5056:
	ld	bc, (0xE084:24)                        ; FC5056  ld BC,(0x00e084)
	extz	xbc                                   ; FC505B  extz XBC
	ld	wa, (xbc+24)                            ; FC505D  ld WA,(XBC+0x18)
	add	(xiz-12), wa                           ; FC5060  add (XIZ+0xf4),WA
	ld	hl, (xiz-12)                            ; FC5063  ld HL,(XIZ+0xf4)
	ld	wa, (0xE082:24)                        ; FC5066  ld WA,(0x00e082)
	extz	xwa                                   ; FC506B  extz XWA
	ld	c, (xwa+17)                             ; FC506D  ld C,(XWA+0x11)
	extz	bc                                    ; FC5070  extz BC
	ld	de, bc                                  ; FC5072  ld DE,BC
	ld	ix, (0xE08C:24)                        ; FC5074  ld IX,(0x00e08c)
	exts	ix                                    ; FC5079  exts IX
	cp	(xiz-12), bc                            ; FC507B  cp (XIZ+0xf4),BC
	jr le, Dev104_PackStagingStruct__FC5084                  ; FC507E  jr LE,0xfc5084
	ld	hl, bc                                  ; FC5080  ld HL,BC
	jr Dev104_PackStagingStruct__FC508B                      ; FC5082  jr T,0xfc508b
Dev104_PackStagingStruct__FC5084:
	cps	hl, 0                                  ; FC5084  cp HL,0
	jr ge, Dev104_PackStagingStruct__FC508B                  ; FC5086  jr GE,0xfc508b
	ldw	hl, 0                                  ; FC5088  ld HL,0x0000
Dev104_PackStagingStruct__FC508B:
	cp	hl, 48                                  ; FC508B  cp HL,0x0030
	jr ge, Dev104_PackStagingStruct__FC509E                  ; FC508F  jr GE,0xfc509e
	ld	bc, hl                                  ; FC5091  ld BC,HL
	sra	bc, 1                                  ; FC5093  sra 0x01,BC
	ld	hl, bc                                  ; FC5096  ld HL,BC
	add	bc, 24                                 ; FC5098  add BC,0x0018
	ld	hl, bc                                  ; FC509C  ld HL,BC
Dev104_PackStagingStruct__FC509E:
	ldw	bc, 0xCF                               ; FC509E  ld BC,0x00cf
	sub	bc, hl                                 ; FC50A1  sub BC,HL
	ld	hl, bc                                  ; FC50A3  ld HL,BC
	add	bc, ix                                 ; FC50A5  add BC,IX
	ld	hl, bc                                  ; FC50A7  ld HL,BC
	cp	bc, 0xFF                                ; FC50A9  cp BC,0x00ff
	jr le, Dev104_PackStagingStruct__FC50B4                  ; FC50AD  jr LE,0xfc50b4
	ldw	hl, 0xFF                               ; FC50AF  ld HL,0x00ff
	jr Dev104_PackStagingStruct__FC50BB                      ; FC50B2  jr T,0xfc50bb
Dev104_PackStagingStruct__FC50B4:
	cps	hl, 0                                  ; FC50B4  cp HL,0
	jr ge, Dev104_PackStagingStruct__FC50BB                  ; FC50B6  jr GE,0xfc50bb
	ldw	hl, 0                                  ; FC50B8  ld HL,0x0000
Dev104_PackStagingStruct__FC50BB:
	ldw	bc, 2                                  ; FC50BB  ld BC,0x0002
	muls	xbc, xhl                              ; FC50BE  muls XBC,HL
	add	xbc, 0xFDF7E0                          ; FC50C0  add XBC,0x00fdf7e0
	ld	hl, (xbc)                               ; FC50C6  ld HL,(XBC)
	ldb_da	a, (0xE089)                         ; FC50C8  ld A,(0x00e089)
	and	a, 1                                   ; FC50CD  and A,0x01
	jr z, Dev104_PackStagingStruct__FC510D                   ; FC50D0  jr Z,0xfc510d
	ld	xbc, (xiz+8)                            ; FC50D2  ld XBC,(XIZ+0x08)
	extpfx5 0xB9, 0x0A, 0x02, 0x00, 0x00       ; FC50D5  ld (XBC+0x0a),0x0000
	ld	xbc, (xiz+8)                            ; FC50DA  ld XBC,(XIZ+0x08)
	extpfx5 0xB9, 0x0C, 0x02, 0x00, 0x00       ; FC50DD  ld (XBC+0x0c),0x0000
	ld	bc, (xiz-10)                            ; FC50E2  ld BC,(XIZ+0xf6)
	and	bc, 0xFFF8                             ; FC50E5  and BC,0xfff8
	or	bc, 7                                   ; FC50E9  or BC,0x0007
	ld	wa, (0xE086:24)                        ; FC50ED  ld WA,(0x00e086)
	extz	xwa                                   ; FC50F2  extz XWA
	ld	(xwa+8), bc                             ; FC50F4  ld (XWA+0x08),BC
	ld	bc, hl                                  ; FC50F7  ld BC,HL
	and	bc, 0xFFF8                             ; FC50F9  and BC,0xfff8
	or	bc, 7                                   ; FC50FD  or BC,0x0007
	ld	wa, (0xE086:24)                        ; FC5101  ld WA,(0x00e086)
	extz	xwa                                   ; FC5106  extz XWA
	ld	(xwa+10), bc                            ; FC5108  ld (XWA+0x0a),BC
	jr Dev104_PackStagingStruct__FC513E                      ; FC510B  jr T,0xfc513e
Dev104_PackStagingStruct__FC510D:
	ld	bc, (xiz-10)                            ; FC510D  ld BC,(XIZ+0xf6)
	and	bc, 0xFFF8                             ; FC5110  and BC,0xfff8
	ld	xwa, (xiz+8)                            ; FC5114  ld XWA,(XIZ+0x08)
	ld	(xwa+10), bc                            ; FC5117  ld (XWA+0x0a),BC
	ld	bc, hl                                  ; FC511A  ld BC,HL
	and	bc, 0xFFF8                             ; FC511C  and BC,0xfff8
	ld	xwa, (xiz+8)                            ; FC5120  ld XWA,(XIZ+0x08)
	ld	(xwa+12), bc                            ; FC5123  ld (XWA+0x0c),BC
	ld	bc, (0xE086:24)                        ; FC5126  ld BC,(0x00e086)
	extz	xbc                                   ; FC512B  extz XBC
	extpfx5 0xB9, 0x08, 0x02, 0x00, 0x00       ; FC512D  ld (XBC+0x08),0x0000
	ld	bc, (0xE086:24)                        ; FC5132  ld BC,(0x00e086)
	extz	xbc                                   ; FC5137  extz XBC
	extpfx5 0xB9, 0x0A, 0x02, 0x00, 0x00       ; FC5139  ld (XBC+0x0a),0x0000
Dev104_PackStagingStruct__FC513E:
	lda	xix, (0xFE0216:24)                     ; FC513E  lda XIX,0xfe0216
	ld	xbc, (xiz-4)                            ; FC5143  ld XBC,(XIZ+0xfc)
	ld	a, (xbc+36)                             ; FC5146  ld A,(XBC+0x24)
	exts	wa                                    ; FC5149  exts WA
	ld	hl, wa                                  ; FC514B  ld HL,WA
	ldb_da	d, (0xE088)                         ; FC514D  ld D,(0x00e088)
	cps	wa, 0                                  ; FC5152  cp WA,0
	jr nz, Dev104_PackStagingStruct__FC515B                  ; FC5154  jr NZ,0xfc515b
	ldw	hl, 0                                  ; FC5156  ld HL,0x0000
	jr Dev104_PackStagingStruct__FC5185                      ; FC5159  jr T,0xfc5185
Dev104_PackStagingStruct__FC515B:
	cps	hl, 0                                  ; FC515B  cp HL,0
	jr ge, Dev104_PackStagingStruct__FC5170                  ; FC515D  jr GE,0xfc5170
	ld	c, d                                    ; FC515F  ld C,D
	extz	bc                                    ; FC5161  extz BC
	ldw	wa, 0x7F                               ; FC5163  ld WA,0x007f
	sub	wa, bc                                 ; FC5166  sub WA,BC
	ld	d, a                                    ; FC5168  ld D,A
	ld	bc, hl                                  ; FC516A  ld BC,HL
	neg	bc                                     ; FC516C  neg BC
	ld	hl, bc                                  ; FC516E  ld HL,BC
Dev104_PackStagingStruct__FC5170:
	ld	c, d                                    ; FC5170  ld C,D
	extz	bc                                    ; FC5172  extz BC
	extz	xbc                                   ; FC5174  extz XBC
	add	xbc, xix                               ; FC5176  add XBC,XIX
	ld	a, (xbc)                                ; FC5178  ld A,(XBC)
	exts	wa                                    ; FC517A  exts WA
	muls	xwa, xhl                              ; FC517C  muls XWA,HL
	ld	hl, wa                                  ; FC517E  ld HL,WA
	sra	wa, 5                                  ; FC5180  sra 0x05,WA
	ld	hl, wa                                  ; FC5183  ld HL,WA
Dev104_PackStagingStruct__FC5185:
	ld	bc, (0xE086:24)                        ; FC5185  ld BC,(0x00e086)
	extz	xbc                                   ; FC518A  extz XBC
	ld	(xbc+16), hl                            ; FC518C  ld (XBC+0x10),HL
	ld	bc, (0xE084:24)                        ; FC518F  ld BC,(0x00e084)
	extz	xbc                                   ; FC5194  extz XBC
	ld	wa, (xbc+30)                            ; FC5196  ld WA,(XBC+0x1e)
	ld	bc, (0xE086:24)                        ; FC5199  ld BC,(0x00e086)
	extz	xbc                                   ; FC519E  extz XBC
	ld	(xbc+35), wa                            ; FC51A0  ld (XBC+0x23),WA
	ld	xbc, (xiz+8)                            ; FC51A3  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC51A6  push XBC
	calr (0xFC4AED - 0xFC51AA)                 ; FC51A7  calr 0xfc4aed
	ld	xbc, (xiz+8)                            ; FC51AA  ld XBC,(XIZ+0x08)
	extpfx5 0xB9, 0x16, 0x02, 0x00, 0xFF       ; FC51AD  ld (XBC+0x16),0xff00
	ld	xbc, (xiz+8)                            ; FC51B2  ld XBC,(XIZ+0x08)
	ld	wa, (xbc)                               ; FC51B5  ld WA,(XBC)
	and	wa, 0x70                               ; FC51B7  and WA,0x0070
	pop	xiy                                    ; FC51BB  pop XIY
	jr z, Dev104_PackStagingStruct__FC51EC                   ; FC51BC  jr Z,0xfc51ec
	ld	xwa, (xiz-4)                            ; FC51BE  ld XWA,(XIZ+0xfc)
	ld	c, (xwa+19)                             ; FC51C1  ld C,(XWA+0x13)
	extz	bc                                    ; FC51C4  extz BC
	extz	xbc                                   ; FC51C6  extz XBC
	add	xbc, 0xFDF760                          ; FC51C8  add XBC,0x00fdf760
	ld	b, (xbc)                                ; FC51CE  ld B,(XBC)
	ld	l, b                                    ; FC51D0  ld L,B
	extz	hl                                    ; FC51D2  extz HL
	ld	bc, hl                                  ; FC51D4  ld BC,HL
	sll	bc, 8                                  ; FC51D6  sll 0x08,BC
	ld	de, bc                                  ; FC51D9  ld DE,BC
	or	de, hl                                  ; FC51DB  or DE,HL
	ld	xbc, (xiz+8)                            ; FC51DD  ld XBC,(XIZ+0x08)
	ld	(xbc+24), de                            ; FC51E0  ld (XBC+0x18),DE
	ld	xbc, (xiz+8)                            ; FC51E3  ld XBC,(XIZ+0x08)
	extpfx4 0x91, 0x3C, 0x7F, 0xFF             ; FC51E6  and (XBC),0xff7f
	jr Dev104_PackStagingStruct__FC51F4                      ; FC51EA  jr T,0xfc51f4
Dev104_PackStagingStruct__FC51EC:
	ld	xbc, (xiz+8)                            ; FC51EC  ld XBC,(XIZ+0x08)
	extpfx5 0xB9, 0x18, 0x02, 0x00, 0x00       ; FC51EF  ld (XBC+0x18),0x0000
Dev104_PackStagingStruct__FC51F4:
	ld	xbc, (xiz-4)                            ; FC51F4  ld XBC,(XIZ+0xfc)
	ld	a, (xbc+25)                             ; FC51F7  ld A,(XBC+0x19)
	and	a, 0x80                                ; FC51FA  and A,0x80
	jr z, Dev104_PackStagingStruct__FC5206                   ; FC51FD  jr Z,0xfc5206
	ldw (xiz-14), 0x0000                       ; FC51FF  ld (XIZ+0xf2),0x0000
	jr Dev104_PackStagingStruct__FC5249                      ; FC5204  jr T,0xfc5249
Dev104_PackStagingStruct__FC5206:
	ld	hl, (0xE08A:24)                        ; FC5206  ld HL,(0x00e08a)
	sra	hl, 8                                  ; FC520B  sra 0x08,HL
	ld	xbc, (xiz-4)                            ; FC520E  ld XBC,(XIZ+0xfc)
	ld	a, (xbc+27)                             ; FC5211  ld A,(XBC+0x1b)
	extz	wa                                    ; FC5214  extz WA
	ld	de, wa                                  ; FC5216  ld DE,WA
	cp	hl, wa                                  ; FC5218  cp HL,WA
	jr ule, Dev104_PackStagingStruct__FC5220                 ; FC521A  jr ULE,0xfc5220
	ld	hl, wa                                  ; FC521C  ld HL,WA
	jr Dev104_PackStagingStruct__FC5230                      ; FC521E  jr T,0xfc5230
Dev104_PackStagingStruct__FC5220:
	ld	xbc, (xiz-4)                            ; FC5220  ld XBC,(XIZ+0xfc)
	ld	a, (xbc+26)                             ; FC5223  ld A,(XBC+0x1a)
	extz	wa                                    ; FC5226  extz WA
	ld	de, wa                                  ; FC5228  ld DE,WA
	cp	hl, wa                                  ; FC522A  cp HL,WA
	jr nc, Dev104_PackStagingStruct__FC5230                  ; FC522C  jr NC,0xfc5230
	ld	hl, wa                                  ; FC522E  ld HL,WA
Dev104_PackStagingStruct__FC5230:
	ld	xbc, (xiz-4)                            ; FC5230  ld XBC,(XIZ+0xfc)
	ld	a, (xbc+25)                             ; FC5233  ld A,(XBC+0x19)
	extz	wa                                    ; FC5236  extz WA
	ld	de, hl                                  ; FC5238  ld DE,HL
	sub	de, wa                                 ; FC523A  sub DE,WA
	ld	a, (xbc+28)                             ; FC523C  ld A,(XBC+0x1c)
	exts	wa                                    ; FC523F  exts WA
	muls	xwa, xde                              ; FC5241  muls XWA,DE
	sra	wa, 5                                  ; FC5243  sra 0x05,WA
	ld	(xiz-14), wa                            ; FC5246  ld (XIZ+0xf2),WA
Dev104_PackStagingStruct__FC5249:
	lda	xix, (0xFE0196:24)                     ; FC5249  lda XIX,0xfe0196
	ld	xbc, (xiz-4)                            ; FC524E  ld XBC,(XIZ+0xfc)
	ld	a, (xbc+24)                             ; FC5251  ld A,(XBC+0x18)
	exts	wa                                    ; FC5254  exts WA
	ld	hl, wa                                  ; FC5256  ld HL,WA
	ldb_da	d, (0xE088)                         ; FC5258  ld D,(0x00e088)
	cps	wa, 0                                  ; FC525D  cp WA,0
	jr nz, Dev104_PackStagingStruct__FC5266                  ; FC525F  jr NZ,0xfc5266
	ldw	hl, 0                                  ; FC5261  ld HL,0x0000
	jr Dev104_PackStagingStruct__FC5290                      ; FC5264  jr T,0xfc5290
Dev104_PackStagingStruct__FC5266:
	cps	hl, 0                                  ; FC5266  cp HL,0
	jr ge, Dev104_PackStagingStruct__FC527B                  ; FC5268  jr GE,0xfc527b
	ld	c, d                                    ; FC526A  ld C,D
	extz	bc                                    ; FC526C  extz BC
	ldw	wa, 0x7F                               ; FC526E  ld WA,0x007f
	sub	wa, bc                                 ; FC5271  sub WA,BC
	ld	d, a                                    ; FC5273  ld D,A
	ld	bc, hl                                  ; FC5275  ld BC,HL
	neg	bc                                     ; FC5277  neg BC
	ld	hl, bc                                  ; FC5279  ld HL,BC
Dev104_PackStagingStruct__FC527B:
	ld	c, d                                    ; FC527B  ld C,D
	extz	bc                                    ; FC527D  extz BC
	extz	xbc                                   ; FC527F  extz XBC
	add	xbc, xix                               ; FC5281  add XBC,XIX
	ld	a, (xbc)                                ; FC5283  ld A,(XBC)
	exts	wa                                    ; FC5285  exts WA
	muls	xwa, xhl                              ; FC5287  muls XWA,HL
	ld	hl, wa                                  ; FC5289  ld HL,WA
	sra	wa, 5                                  ; FC528B  sra 0x05,WA
	ld	hl, wa                                  ; FC528E  ld HL,WA
Dev104_PackStagingStruct__FC5290:
	ld	bc, (xiz-14)                            ; FC5290  ld BC,(XIZ+0xf2)
	add	bc, hl                                 ; FC5293  add BC,HL
	ld	(xiz-16), bc                            ; FC5295  ld (XIZ+0xf0),BC
	ld	wa, (0xE084:24)                        ; FC5298  ld WA,(0x00e084)
	extz	xwa                                   ; FC529D  extz XWA
	ld	iy, (xwa+26)                            ; FC529F  ld IY,(XWA+0x1a)
	ld	hl, bc                                  ; FC52A2  ld HL,BC
	add	hl, iy                                 ; FC52A4  add HL,IY
	ldb_da	c, (0xE08C)                         ; FC52A6  ld C,(0x00e08c)
	extz	bc                                    ; FC52AB  extz BC
	extz	xbc                                   ; FC52AD  extz XBC
	add	xbc, 0xFDFF96                          ; FC52AF  add XBC,0x00fdff96
	ld	b, (xbc)                                ; FC52B5  ld B,(XBC)
	extpfx3 0xC7, 0xF0, 0x9A                   ; FC52B7  ld IXL,B
	extz	ix                                    ; FC52BA  extz IX
	ld	bc, (0xE082:24)                        ; FC52BC  ld BC,(0x00e082)
	extz	xbc                                   ; FC52C1  extz XBC
	ld	a, (xbc+18)                             ; FC52C3  ld A,(XBC+0x12)
	extz	wa                                    ; FC52C6  extz WA
	ld	de, wa                                  ; FC52C8  ld DE,WA
	cp	hl, wa                                  ; FC52CA  cp HL,WA
	jr le, Dev104_PackStagingStruct__FC52D2                  ; FC52CC  jr LE,0xfc52d2
	ld	hl, wa                                  ; FC52CE  ld HL,WA
	jr Dev104_PackStagingStruct__FC52D8                      ; FC52D0  jr T,0xfc52d8
Dev104_PackStagingStruct__FC52D2:
	cp	hl, ix                                  ; FC52D2  cp HL,IX
	jr ge, Dev104_PackStagingStruct__FC52D8                  ; FC52D4  jr GE,0xfc52d8
	ld	hl, ix                                  ; FC52D6  ld HL,IX
Dev104_PackStagingStruct__FC52D8:
	ld	de, hl                                  ; FC52D8  ld DE,HL
	ldw	bc, 2                                  ; FC52DA  ld BC,0x0002
	muls	xbc, xde                              ; FC52DD  muls XBC,DE
	ld	xix, xbc                                ; FC52DF  ld XIX,XBC
	add	xbc, 0xFE04C9                          ; FC52E1  add XBC,0x00fe04c9
	ld	bc, (xbc)                               ; FC52E7  ld BC,(XBC)
	ld	xwa, (xiz+8)                            ; FC52E9  ld XWA,(XIZ+0x08)
	ld	(xwa+32), bc                            ; FC52EC  ld (XWA+0x20),BC
	lda	xbc, (0xFE05C9:24)                     ; FC52EF  lda XBC,0xfe05c9
	add	xbc, xix                               ; FC52F4  add XBC,XIX
	ld	wa, (xbc)                               ; FC52F6  ld WA,(XBC)
	ld	xbc, (xiz+8)                            ; FC52F8  ld XBC,(XIZ+0x08)
	ld	(xbc+26), wa                            ; FC52FB  ld (XBC+0x1a),WA
	ld	xbc, (xiz+8)                            ; FC52FE  ld XBC,(XIZ+0x08)
	ld	hl, (xbc+32)                            ; FC5301  ld HL,(XBC+0x20)
	ld	wa, hl                                  ; FC5304  ld WA,HL
	and	wa, 0x8000                             ; FC5306  and WA,0x8000
	jr z, Dev104_PackStagingStruct__FC531F                   ; FC530A  jr Z,0xfc531f
	ld	wa, hl                                  ; FC530C  ld WA,HL
	res	15, wa                                 ; FC530E  res 0x0f,WA
	extz	xwa                                   ; FC5311  extz XWA
	ld	(xiz-18), xwa                           ; FC5313  ld (XIZ+0xee),XWA
	ld	xix, 0x8000                             ; FC5316  ld XIX,0x00008000
	sub	xix, xwa                               ; FC531B  sub XIX,XWA
	jr Dev104_PackStagingStruct__FC5329                      ; FC531D  jr T,0xfc5329
Dev104_PackStagingStruct__FC531F:
	ld	ix, hl                                  ; FC531F  ld IX,HL
	extz	xix                                   ; FC5321  extz XIX
	add	xix, 0x8000                            ; FC5323  add XIX,0x00008000
Dev104_PackStagingStruct__FC5329:
	ld	bc, (0xE082:24)                        ; FC5329  ld BC,(0x00e082)
	extz	xbc                                   ; FC532E  extz XBC
	ld	a, (xbc+17)                             ; FC5330  ld A,(XBC+0x11)
	extz	wa                                    ; FC5333  extz WA
	ld	de, wa                                  ; FC5335  ld DE,WA
	ld	hl, (xiz-8)                             ; FC5337  ld HL,(XIZ+0xf8)
	cp	(xiz-8), wa                             ; FC533A  cp (XIZ+0xf8),WA
	jr le, Dev104_PackStagingStruct__FC5343                  ; FC533D  jr LE,0xfc5343
	ld	hl, wa                                  ; FC533F  ld HL,WA
	jr Dev104_PackStagingStruct__FC534A                      ; FC5341  jr T,0xfc534a
Dev104_PackStagingStruct__FC5343:
	cps	hl, 0                                  ; FC5343  cp HL,0
	jr ge, Dev104_PackStagingStruct__FC534A                  ; FC5345  jr GE,0xfc534a
	ldw	hl, 0                                  ; FC5347  ld HL,0x0000
Dev104_PackStagingStruct__FC534A:
	ldw	bc, 2                                  ; FC534A  ld BC,0x0002
	muls	xbc, xhl                              ; FC534D  muls XBC,HL
	add	xbc, 0xFDF9E0                          ; FC534F  add XBC,0x00fdf9e0
	ld	hl, (xbc)                               ; FC5355  ld HL,(XBC)
	ld	bc, hl                                  ; FC5357  ld BC,HL
	extz	xbc                                   ; FC5359  extz XBC
	push	xbc                                   ; FC535B  push XBC
	push	xix                                   ; FC535C  push XIX
	call	0xFCB11B                              ; FC535D  call 0xfcb11b
	srl	xiy, 0                                 ; FC5361  srl 0x00,XIY
	ld	xbc, (xiz+8)                            ; FC5364  ld XBC,(XIZ+0x08)
	ld	(xbc+14), iy                            ; FC5367  ld (XBC+0x0e),IY
	ld	xbc, (xiz-4)                            ; FC536A  ld XBC,(XIZ+0xfc)
	ld	a, (xbc+37)                             ; FC536D  ld A,(XBC+0x25)
	and	a, 0x80                                ; FC5370  and A,0x80
	jr z, Dev104_PackStagingStruct__FC537C                   ; FC5373  jr Z,0xfc537c
	ldw (xiz-14), 0x0000                       ; FC5375  ld (XIZ+0xf2),0x0000
	jr Dev104_PackStagingStruct__FC53BF                      ; FC537A  jr T,0xfc53bf
Dev104_PackStagingStruct__FC537C:
	ld	hl, (0xE08A:24)                        ; FC537C  ld HL,(0x00e08a)
	sra	hl, 8                                  ; FC5381  sra 0x08,HL
	ld	xbc, (xiz-4)                            ; FC5384  ld XBC,(XIZ+0xfc)
	ld	a, (xbc+39)                             ; FC5387  ld A,(XBC+0x27)
	extz	wa                                    ; FC538A  extz WA
	ld	de, wa                                  ; FC538C  ld DE,WA
	cp	hl, wa                                  ; FC538E  cp HL,WA
	jr ule, Dev104_PackStagingStruct__FC5396                 ; FC5390  jr ULE,0xfc5396
	ld	hl, wa                                  ; FC5392  ld HL,WA
	jr Dev104_PackStagingStruct__FC53A6                      ; FC5394  jr T,0xfc53a6
Dev104_PackStagingStruct__FC5396:
	ld	xbc, (xiz-4)                            ; FC5396  ld XBC,(XIZ+0xfc)
	ld	a, (xbc+38)                             ; FC5399  ld A,(XBC+0x26)
	extz	wa                                    ; FC539C  extz WA
	ld	de, wa                                  ; FC539E  ld DE,WA
	cp	hl, wa                                  ; FC53A0  cp HL,WA
	jr nc, Dev104_PackStagingStruct__FC53A6                  ; FC53A2  jr NC,0xfc53a6
	ld	hl, wa                                  ; FC53A4  ld HL,WA
Dev104_PackStagingStruct__FC53A6:
	ld	xbc, (xiz-4)                            ; FC53A6  ld XBC,(XIZ+0xfc)
	ld	a, (xbc+37)                             ; FC53A9  ld A,(XBC+0x25)
	extz	wa                                    ; FC53AC  extz WA
	ld	de, hl                                  ; FC53AE  ld DE,HL
	sub	de, wa                                 ; FC53B0  sub DE,WA
	ld	a, (xbc+40)                             ; FC53B2  ld A,(XBC+0x28)
	exts	wa                                    ; FC53B5  exts WA
	muls	xwa, xde                              ; FC53B7  muls XWA,DE
	sra	wa, 5                                  ; FC53B9  sra 0x05,WA
	ld	(xiz-14), wa                            ; FC53BC  ld (XIZ+0xf2),WA
Dev104_PackStagingStruct__FC53BF:
	lda	xix, (0xFE0196:24)                     ; FC53BF  lda XIX,0xfe0196
	ld	xbc, (xiz-4)                            ; FC53C4  ld XBC,(XIZ+0xfc)
	ld	a, (xbc+35)                             ; FC53C7  ld A,(XBC+0x23)
	exts	wa                                    ; FC53CA  exts WA
	ld	hl, wa                                  ; FC53CC  ld HL,WA
	ldb_da	d, (0xE088)                         ; FC53CE  ld D,(0x00e088)
	cps	wa, 0                                  ; FC53D3  cp WA,0
	jr nz, Dev104_PackStagingStruct__FC53DC                  ; FC53D5  jr NZ,0xfc53dc
	ldw	hl, 0                                  ; FC53D7  ld HL,0x0000
	jr Dev104_PackStagingStruct__FC5406                      ; FC53DA  jr T,0xfc5406
Dev104_PackStagingStruct__FC53DC:
	cps	hl, 0                                  ; FC53DC  cp HL,0
	jr ge, Dev104_PackStagingStruct__FC53F1                  ; FC53DE  jr GE,0xfc53f1
	ld	c, d                                    ; FC53E0  ld C,D
	extz	bc                                    ; FC53E2  extz BC
	ldw	wa, 0x7F                               ; FC53E4  ld WA,0x007f
	sub	wa, bc                                 ; FC53E7  sub WA,BC
	ld	d, a                                    ; FC53E9  ld D,A
	ld	bc, hl                                  ; FC53EB  ld BC,HL
	neg	bc                                     ; FC53ED  neg BC
	ld	hl, bc                                  ; FC53EF  ld HL,BC
Dev104_PackStagingStruct__FC53F1:
	ld	c, d                                    ; FC53F1  ld C,D
	extz	bc                                    ; FC53F3  extz BC
	extz	xbc                                   ; FC53F5  extz XBC
	add	xbc, xix                               ; FC53F7  add XBC,XIX
	ld	a, (xbc)                                ; FC53F9  ld A,(XBC)
	exts	wa                                    ; FC53FB  exts WA
	muls	xwa, xhl                              ; FC53FD  muls XWA,HL
	ld	hl, wa                                  ; FC53FF  ld HL,WA
	sra	wa, 5                                  ; FC5401  sra 0x05,WA
	ld	hl, wa                                  ; FC5404  ld HL,WA
Dev104_PackStagingStruct__FC5406:
	ld	bc, (xiz-14)                            ; FC5406  ld BC,(XIZ+0xf2)
	add	bc, hl                                 ; FC5409  add BC,HL
	ld	(xiz-16), bc                            ; FC540B  ld (XIZ+0xf0),BC
	ld	wa, (0xE084:24)                        ; FC540E  ld WA,(0x00e084)
	extz	xwa                                   ; FC5413  extz XWA
	ld	iy, (xwa+28)                            ; FC5415  ld IY,(XWA+0x1c)
	ld	hl, bc                                  ; FC5418  ld HL,BC
	add	hl, iy                                 ; FC541A  add HL,IY
	ldb_da	c, (0xE08C)                         ; FC541C  ld C,(0x00e08c)
	extz	bc                                    ; FC5421  extz BC
	extz	xbc                                   ; FC5423  extz XBC
	add	xbc, 0xFDFF96                          ; FC5425  add XBC,0x00fdff96
	ld	b, (xbc)                                ; FC542B  ld B,(XBC)
	extpfx3 0xC7, 0xF0, 0x9A                   ; FC542D  ld IXL,B
	extz	ix                                    ; FC5430  extz IX
	ld	bc, (0xE082:24)                        ; FC5432  ld BC,(0x00e082)
	extz	xbc                                   ; FC5437  extz XBC
	ld	a, (xbc+18)                             ; FC5439  ld A,(XBC+0x12)
	extz	wa                                    ; FC543C  extz WA
	ld	de, wa                                  ; FC543E  ld DE,WA
	cp	hl, wa                                  ; FC5440  cp HL,WA
	jr le, Dev104_PackStagingStruct__FC5448                  ; FC5442  jr LE,0xfc5448
	ld	hl, wa                                  ; FC5444  ld HL,WA
	jr Dev104_PackStagingStruct__FC544E                      ; FC5446  jr T,0xfc544e
Dev104_PackStagingStruct__FC5448:
	cp	hl, ix                                  ; FC5448  cp HL,IX
	jr ge, Dev104_PackStagingStruct__FC544E                  ; FC544A  jr GE,0xfc544e
	ld	hl, ix                                  ; FC544C  ld HL,IX
Dev104_PackStagingStruct__FC544E:
	ld	de, hl                                  ; FC544E  ld DE,HL
	ldw	bc, 2                                  ; FC5450  ld BC,0x0002
	muls	xbc, xde                              ; FC5453  muls XBC,DE
	ld	xix, xbc                                ; FC5455  ld XIX,XBC
	add	xbc, 0xFE04C9                          ; FC5457  add XBC,0x00fe04c9
	ld	bc, (xbc)                               ; FC545D  ld BC,(XBC)
	ld	xwa, (xiz+8)                            ; FC545F  ld XWA,(XIZ+0x08)
	ld	(xwa+34), bc                            ; FC5462  ld (XWA+0x22),BC
	lda	xbc, (0xFE05C9:24)                     ; FC5465  lda XBC,0xfe05c9
	add	xbc, xix                               ; FC546A  add XBC,XIX
	ld	wa, (xbc)                               ; FC546C  ld WA,(XBC)
	ld	xbc, (xiz+8)                            ; FC546E  ld XBC,(XIZ+0x08)
	ld	(xbc+28), wa                            ; FC5471  ld (XBC+0x1c),WA
	ld	xbc, (xiz+8)                            ; FC5474  ld XBC,(XIZ+0x08)
	ld	hl, (xbc+34)                            ; FC5477  ld HL,(XBC+0x22)
	ld	wa, hl                                  ; FC547A  ld WA,HL
	and	wa, 0x8000                             ; FC547C  and WA,0x8000
	jr z, Dev104_PackStagingStruct__FC5495                   ; FC5480  jr Z,0xfc5495
	ld	wa, hl                                  ; FC5482  ld WA,HL
	res	15, wa                                 ; FC5484  res 0x0f,WA
	extz	xwa                                   ; FC5487  extz XWA
	ld	(xiz-18), xwa                           ; FC5489  ld (XIZ+0xee),XWA
	ld	xix, 0x8000                             ; FC548C  ld XIX,0x00008000
	sub	xix, xwa                               ; FC5491  sub XIX,XWA
	jr Dev104_PackStagingStruct__FC549F                      ; FC5493  jr T,0xfc549f
Dev104_PackStagingStruct__FC5495:
	ld	ix, hl                                  ; FC5495  ld IX,HL
	extz	xix                                   ; FC5497  extz XIX
	add	xix, 0x8000                            ; FC5499  add XIX,0x00008000
Dev104_PackStagingStruct__FC549F:
	ld	bc, (0xE082:24)                        ; FC549F  ld BC,(0x00e082)
	extz	xbc                                   ; FC54A4  extz XBC
	ld	a, (xbc+17)                             ; FC54A6  ld A,(XBC+0x11)
	extz	wa                                    ; FC54A9  extz WA
	ld	de, wa                                  ; FC54AB  ld DE,WA
	ld	hl, (xiz-12)                            ; FC54AD  ld HL,(XIZ+0xf4)
	cp	(xiz-12), wa                            ; FC54B0  cp (XIZ+0xf4),WA
	jr le, Dev104_PackStagingStruct__FC54B9                  ; FC54B3  jr LE,0xfc54b9
	ld	hl, wa                                  ; FC54B5  ld HL,WA
	jr Dev104_PackStagingStruct__FC54C0                      ; FC54B7  jr T,0xfc54c0
Dev104_PackStagingStruct__FC54B9:
	cps	hl, 0                                  ; FC54B9  cp HL,0
	jr ge, Dev104_PackStagingStruct__FC54C0                  ; FC54BB  jr GE,0xfc54c0
	ldw	hl, 0                                  ; FC54BD  ld HL,0x0000
Dev104_PackStagingStruct__FC54C0:
	ldw	bc, 2                                  ; FC54C0  ld BC,0x0002
	muls	xbc, xhl                              ; FC54C3  muls XBC,HL
	add	xbc, 0xFDF9E0                          ; FC54C5  add XBC,0x00fdf9e0
	ld	hl, (xbc)                               ; FC54CB  ld HL,(XBC)
	ld	bc, hl                                  ; FC54CD  ld BC,HL
	extz	xbc                                   ; FC54CF  extz XBC
	push	xbc                                   ; FC54D1  push XBC
	push	xix                                   ; FC54D2  push XIX
	call	0xFCB11B                              ; FC54D3  call 0xfcb11b
	srl	xiy, 0                                 ; FC54D7  srl 0x00,XIY
	ld	xbc, (xiz+8)                            ; FC54DA  ld XBC,(XIZ+0x08)
	ld	(xbc+16), iy                            ; FC54DD  ld (XBC+0x10),IY
	ld	xbc, (xiz-4)                            ; FC54E0  ld XBC,(XIZ+0xfc)
	ld	a, (xbc+18)                             ; FC54E3  ld A,(XBC+0x12)
	and	a, 0x80                                ; FC54E6  and A,0x80
	jr z, Dev104_PackStagingStruct__FC5506                   ; FC54E9  jr Z,0xfc5506
	ld	wa, (0xE084:24)                        ; FC54EB  ld WA,(0x00e084)
	extz	xwa                                   ; FC54F0  extz XWA
	ld	c, (xwa+40)                             ; FC54F2  ld C,(XWA+0x28)
	cps	c, 0                                   ; FC54F5  cp C,0
	jr z, Dev104_PackStagingStruct__FC5528                   ; FC54F7  jr Z,0xfc5528
	ld	bc, (0xE086:24)                        ; FC54F9  ld BC,(0x00e086)
	extz	xbc                                   ; FC54FE  extz XBC
	ld	(xbc+28), 2                             ; FC5500  ld (XBC+0x1c),0x02
	jr Dev104_PackStagingStruct__FC5533                      ; FC5504  jr T,0xfc5533
Dev104_PackStagingStruct__FC5506:
	ld	bc, (0xE084:24)                        ; FC5506  ld BC,(0x00e084)
	extz	xbc                                   ; FC550B  extz XBC
	ld	a, (xbc+41)                             ; FC550D  ld A,(XBC+0x29)
	cps	a, 0                                   ; FC5510  cp A,0
	jr z, Dev104_PackStagingStruct__FC5528                   ; FC5512  jr Z,0xfc5528
	ld	a, (xbc+40)                             ; FC5514  ld A,(XBC+0x28)
	cps	a, 0                                   ; FC5517  cp A,0
	jr z, Dev104_PackStagingStruct__FC5528                   ; FC5519  jr Z,0xfc5528
	ld	wa, (0xE086:24)                        ; FC551B  ld WA,(0x00e086)
	extz	xwa                                   ; FC5520  extz XWA
	ld	(xwa+28), 1                             ; FC5522  ld (XWA+0x1c),0x01
	jr Dev104_PackStagingStruct__FC5533                      ; FC5526  jr T,0xfc5533
Dev104_PackStagingStruct__FC5528:
	ld	bc, (0xE086:24)                        ; FC5528  ld BC,(0x00e086)
	extz	xbc                                   ; FC552D  extz XBC
	ld	(xbc+28), 0                             ; FC552F  ld (XBC+0x1c),0x00
Dev104_PackStagingStruct__FC5533:
	ld	bc, (0xE086:24)                        ; FC5533  ld BC,(0x00e086)
	extz	xbc                                   ; FC5538  extz XBC
	ld	a, (xbc+28)                             ; FC553A  ld A,(XBC+0x1c)
	cps	a, 2                                   ; FC553D  cp A,2
	jr nz, Dev104_PackStagingStruct__FC559C                  ; FC553F  jr NZ,0xfc559c
	ei	6                                       ; FC5541  ei 0x06
	ld	hl, (0xF2F3:24)                        ; FC5543  ld HL,(0x00f2f3)
	and	hl, 0x1FF                              ; FC5548  and HL,0x01ff
	ei	0                                       ; FC554C  ei 0x00
	ld	bc, hl                                  ; FC554E  ld BC,HL
	and	bc, 1                                  ; FC5550  and BC,0x0001
	ld	de, bc                                  ; FC5554  ld DE,BC
	sll	de, 8                                  ; FC5556  sll 0x08,DE
	ld	bc, hl                                  ; FC5559  ld BC,HL
	and	bc, 0x100                              ; FC555B  and BC,0x0100
	ld	ix, bc                                  ; FC555F  ld IX,BC
	srl	ix, 8                                  ; FC5561  srl 0x08,IX
	ld	bc, hl                                  ; FC5564  ld BC,HL
	and	bc, 0xFEFE                             ; FC5566  and BC,0xfefe
	or	bc, de                                  ; FC556A  or BC,DE
	or	bc, ix                                  ; FC556C  or BC,IX
	extz	xbc                                   ; FC556E  extz XBC
	add	xbc, 0xFE02C9                          ; FC5570  add XBC,0x00fe02c9
	ld	a, (xbc)                                ; FC5576  ld A,(XBC)
	exts	wa                                    ; FC5578  exts WA
	ld	hl, wa                                  ; FC557A  ld HL,WA
	ld	bc, (0xE084:24)                        ; FC557C  ld BC,(0x00e084)
	extz	xbc                                   ; FC5581  extz XBC
	ld	a, (xbc+40)                             ; FC5583  ld A,(XBC+0x28)
	extz	wa                                    ; FC5586  extz WA
	muls	xwa, xhl                              ; FC5588  muls XWA,HL
	exts	xwa                                   ; FC558A  exts XWA
	divs	wa, 50                                ; FC558C  divs WA,0x0032
	ld	bc, (0xE086:24)                        ; FC5590  ld BC,(0x00e086)
	extz	xbc                                   ; FC5595  extz XBC
	ld	(xbc+33), wa                            ; FC5597  ld (XBC+0x21),WA
	jr Dev104_PackStagingStruct__FC55E0                      ; FC559A  jr T,0xfc55e0
Dev104_PackStagingStruct__FC559C:
	ld	bc, (0xE084:24)                        ; FC559C  ld BC,(0x00e084)
	extz	xbc                                   ; FC55A1  extz XBC
	ld	a, (xbc+40)                             ; FC55A3  ld A,(XBC+0x28)
	ld	h, a                                    ; FC55A6  ld H,A
	ld	wa, (0xE086:24)                        ; FC55A8  ld WA,(0x00e086)
	extz	xwa                                   ; FC55AD  extz XWA
	ld	(xwa+29), h                             ; FC55AF  ld (XWA+0x1d),H
	ld	bc, (0xE084:24)                        ; FC55B2  ld BC,(0x00e084)
	extz	xbc                                   ; FC55B7  extz XBC
	ld	a, (xbc+41)                             ; FC55B9  ld A,(XBC+0x29)
	ld	h, a                                    ; FC55BC  ld H,A
	ld	wa, (0xE086:24)                        ; FC55BE  ld WA,(0x00e086)
	extz	xwa                                   ; FC55C3  extz XWA
	ld	(xwa+30), h                             ; FC55C5  ld (XWA+0x1e),H
	ld	bc, (0xE086:24)                        ; FC55C8  ld BC,(0x00e086)
	extz	xbc                                   ; FC55CD  extz XBC
	extpfx5 0xB9, 0x1F, 0x02, 0x00, 0x00       ; FC55CF  ld (XBC+0x1f),0x0000
	ld	bc, (0xE086:24)                        ; FC55D4  ld BC,(0x00e086)
	extz	xbc                                   ; FC55D9  extz XBC
	extpfx5 0xB9, 0x21, 0x02, 0x00, 0x00       ; FC55DB  ld (XBC+0x21),0x0000
Dev104_PackStagingStruct__FC55E0:
	lda	xix, (0xFE0096:24)                     ; FC55E0  lda XIX,0xfe0096
	ld	xbc, (xiz-4)                            ; FC55E5  ld XBC,(XIZ+0xfc)
	ld	a, (xbc+16)                             ; FC55E8  ld A,(XBC+0x10)
	exts	wa                                    ; FC55EB  exts WA
	ld	hl, wa                                  ; FC55ED  ld HL,WA
	ldb_da	d, (0xE088)                         ; FC55EF  ld D,(0x00e088)
	cps	wa, 0                                  ; FC55F4  cp WA,0
	jr nz, Dev104_PackStagingStruct__FC55FD                  ; FC55F6  jr NZ,0xfc55fd
	ldw	hl, 0                                  ; FC55F8  ld HL,0x0000
	jr Dev104_PackStagingStruct__FC5627                      ; FC55FB  jr T,0xfc5627
Dev104_PackStagingStruct__FC55FD:
	cps	hl, 0                                  ; FC55FD  cp HL,0
	jr ge, Dev104_PackStagingStruct__FC5612                  ; FC55FF  jr GE,0xfc5612
	ld	c, d                                    ; FC5601  ld C,D
	extz	bc                                    ; FC5603  extz BC
	ldw	wa, 0x7F                               ; FC5605  ld WA,0x007f
	sub	wa, bc                                 ; FC5608  sub WA,BC
	ld	d, a                                    ; FC560A  ld D,A
	ld	bc, hl                                  ; FC560C  ld BC,HL
	neg	bc                                     ; FC560E  neg BC
	ld	hl, bc                                  ; FC5610  ld HL,BC
Dev104_PackStagingStruct__FC5612:
	ld	c, d                                    ; FC5612  ld C,D
	extz	bc                                    ; FC5614  extz BC
	extz	xbc                                   ; FC5616  extz XBC
	add	xbc, xix                               ; FC5618  add XBC,XIX
	ld	a, (xbc)                                ; FC561A  ld A,(XBC)
	exts	wa                                    ; FC561C  exts WA
	muls	xwa, xhl                              ; FC561E  muls XWA,HL
	ld	hl, wa                                  ; FC5620  ld HL,WA
	sra	wa, 5                                  ; FC5622  sra 0x05,WA
	ld	hl, wa                                  ; FC5625  ld HL,WA
Dev104_PackStagingStruct__FC5627:
	ld	bc, (0xE086:24)                        ; FC5627  ld BC,(0x00e086)
	extz	xbc                                   ; FC562C  extz XBC
	ld	(xbc+18), hl                            ; FC562E  ld (XBC+0x12),HL
	ld	bc, (0xE086:24)                        ; FC5631  ld BC,(0x00e086)
	extz	xbc                                   ; FC5636  extz XBC
	ld	hl, (xbc+18)                            ; FC5638  ld HL,(XBC+0x12)
	cps	hl, 0                                  ; FC563B  cp HL,0
	jr ge, Dev104_PackStagingStruct__FC564B                  ; FC563D  jr GE,0xfc564b
	ld	wa, hl                                  ; FC563F  ld WA,HL
	neg	wa                                     ; FC5641  neg WA
	sra	wa, 2                                  ; FC5643  sra 0x02,WA
	ld	(xbc+20), wa                            ; FC5646  ld (XBC+0x14),WA
	jr Dev104_PackStagingStruct__FC565A                      ; FC5649  jr T,0xfc565a
Dev104_PackStagingStruct__FC564B:
	ld	bc, hl                                  ; FC564B  ld BC,HL
	sra	bc, 2                                  ; FC564D  sra 0x02,BC
	ld	wa, (0xE086:24)                        ; FC5650  ld WA,(0x00e086)
	extz	xwa                                   ; FC5655  extz XWA
	ld	(xwa+20), bc                            ; FC5657  ld (XWA+0x14),BC
Dev104_PackStagingStruct__FC565A:
	ld	bc, (0xE084:24)                        ; FC565A  ld BC,(0x00e084)
	extz	xbc                                   ; FC565F  extz XBC
	ld	wa, (xbc+32)                            ; FC5661  ld WA,(XBC+0x20)
	ld	bc, (0xE086:24)                        ; FC5664  ld BC,(0x00e086)
	extz	xbc                                   ; FC5669  extz XBC
	ld	(xbc+22), wa                            ; FC566B  ld (XBC+0x16),WA
	ld	bc, (0xE084:24)                        ; FC566E  ld BC,(0x00e084)
	extz	xbc                                   ; FC5673  extz XBC
	ld	wa, (xbc+38)                            ; FC5675  ld WA,(XBC+0x26)
	ld	bc, (0xE086:24)                        ; FC5678  ld BC,(0x00e086)
	extz	xbc                                   ; FC567D  extz XBC
	ld	(xbc+26), wa                            ; FC567F  ld (XBC+0x1a),WA
	ld	bc, (0xE086:24)                        ; FC5682  ld BC,(0x00e086)
	extz	xbc                                   ; FC5687  extz XBC
	ld	wa, (xbc+26)                            ; FC5689  ld WA,(XBC+0x1a)
	ld	xiy, (xiz+8)                            ; FC568C  ld XIY,(XIZ+0x08)
	ld	(xiy+36), wa                            ; FC568F  ld (XIY+0x24),WA
	ld	bc, (0xE084:24)                        ; FC5692  ld BC,(0x00e084)
	extz	xbc                                   ; FC5697  extz XBC
	ld	wa, (xbc+34)                            ; FC5699  ld WA,(XBC+0x22)
	ld	bc, (0xE086:24)                        ; FC569C  ld BC,(0x00e086)
	extz	xbc                                   ; FC56A1  extz XBC
	ld	(xbc+24), wa                            ; FC56A3  ld (XBC+0x18),WA
	ld	xbc, (xiz+8)                            ; FC56A6  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FC56A9  push XBC
	calr (0xFC49AD - 0xFC56AD)                 ; FC56AA  calr 0xfc49ad
	ld	bc, (0xE084:24)                        ; FC56AD  ld BC,(0x00e084)
	extz	xbc                                   ; FC56B2  extz XBC
	ld	wa, (xbc+36)                            ; FC56B4  ld WA,(XBC+0x24)
	ld	xiy, (xiz+8)                            ; FC56B7  ld XIY,(XIZ+0x08)
	ld	(xiy+30), wa                            ; FC56BA  ld (XIY+0x1e),WA
	pop	xbc                                    ; FC56BD  pop XBC
	pop	xix                                    ; FC56BE  pop XIX
	popw	de                                    ; FC56BF  pop DE
	popw	hl                                    ; FC56C0  pop HL
	unlk32 xiz                                 ; FC56C1  unlk XIZ
	ret                                        ; FC56C3  ret
; --------------------------------------------------------------------------
; sub_FC56C4 -- 0xFC56C4..0xFC5719 (86 bytes)
;
; Called from: 5 site(s) outside this module:
;          0xFB3726 in MidiNote_OnTail, 0xFB3833 in MidiNote_OffTail
;          0xFB39BC in MidiNote_OnByPartMode__FB39B2, 0xFB3AC6 in MidiNote_OnByPartMode__FB3A95
;          0xFB3BDF in MidiNote_OnByPartMode__FB3BAE
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFC56C4-0xFC5719
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC56C4:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC56C4  link XIZ,0x0000
	pushw	hl                                   ; FC56C8  push HL
	pushw	de                                   ; FC56C9  push DE
	push	xix                                   ; FC56CA  push XIX
	lda	xix, (0xE086:24)                       ; FC56CB  lda XIX,0x00e086
	ldb	c, 37                                  ; FC56D0  ld C,0x25
	extpfx3 0x8E, 0x08, 0x43                   ; FC56D2  mul BC,(XIZ+0x08)
	ld	de, bc                                  ; FC56D5  ld DE,BC
	ldw	wa, 0x753E                             ; FC56D7  ld WA,0x753e
	add	wa, bc                                 ; FC56DA  add WA,BC
	ld	(xix), wa                               ; FC56DC  ld (XIX),WA
	ld	bc, (xix)                               ; FC56DE  ld BC,(XIX)
	extz	xbc                                   ; FC56E0  extz XBC
	ld	hl, (xbc+8)                             ; FC56E2  ld HL,(XBC+0x08)
	cps	hl, 0                                  ; FC56E5  cp HL,0
	jr z, sub_FC56C4__FC5712                   ; FC56E7  jr Z,0xfc5712
	ld	xbc, (xiz+10)                           ; FC56E9  ld XBC,(XIZ+0x0a)
	ld	(xbc+10), hl                            ; FC56EC  ld (XBC+0x0a),HL
	ld	bc, (xix)                               ; FC56EF  ld BC,(XIX)
	extz	xbc                                   ; FC56F1  extz XBC
	ld	wa, (xbc+10)                            ; FC56F3  ld WA,(XBC+0x0a)
	ld	xbc, (xiz+10)                           ; FC56F6  ld XBC,(XIZ+0x0a)
	ld	(xbc+12), wa                            ; FC56F9  ld (XBC+0x0c),WA
	ld	bc, (xix)                               ; FC56FC  ld BC,(XIX)
	extz	xbc                                   ; FC56FE  extz XBC
	extpfx5 0xB9, 0x08, 0x02, 0x00, 0x00       ; FC5700  ld (XBC+0x08),0x0000
	ld	bc, (xix)                               ; FC5705  ld BC,(XIX)
	extz	xbc                                   ; FC5707  extz XBC
	extpfx5 0xB9, 0x0A, 0x02, 0x00, 0x00       ; FC5709  ld (XBC+0x0a),0x0000
	ldb	a, 1                                   ; FC570E  ld A,0x01
	jr sub_FC56C4__FC5714                      ; FC5710  jr T,0xfc5714
sub_FC56C4__FC5712:
	sub	a, a                                   ; FC5712  sub A,A
sub_FC56C4__FC5714:
	pop	xix                                    ; FC5714  pop XIX
	popw	de                                    ; FC5715  pop DE
	popw	hl                                    ; FC5716  pop HL
	unlk32 xiz                                 ; FC5717  unlk XIZ
	ret                                        ; FC5719  ret
; --------------------------------------------------------------------------
; Dev104_LoadStageBImage -- 0xFC571A..0xFC578B (114 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFAC3E1 in sub_FAC34D, 0xFB1F42 in VoiceRegs_Stage_B
;          1 site(s) inside this module:
;          0xFC3EA9
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
;          reads 0x00E086
; Calls:   0xF9A038 = MemCopyWords
; Evidence: the listing below is the byte-identical round-trip of 0xFC571A-0xFC578B
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ ROUND 6 ------------------------------------------------------------
; ★ Dev104_LoadStageBImage -- and the finding that goes with it:
;          VoiceRegs_Stage_B NEVER RUNS THE 0x00104000 PACKER.  Stage_A, Stage_C and Stage_D
;          all call Dev104_PackStagingStruct; Stage_B calls this instead, at 0xFB1F42, with the
;          same struct pointer 0x00D7A2.
;          It zeroes four fields of the record at (0x00E086) (+5, +8, +0x0A, +0x1C), block-
;          copies 38 bytes = 19 words from Dev104_StagingStruct_StageBImage (0xFE1315) through
;          MemCopyWords (`push 0x0026` at 0xFC5751, `call 0xF9A038` at 0xFC575B), and then
;          patches five fields of the struct:
;          (+0x00) = (0x00E086)[+7] << 8      0xFC576E
;          (+0x0A) = 0x05A8                   0xFC5770
;          (+0x0C) = 0x05A8                   0xFC5775
;          (+0x14) = 0x8000                   0xFC577F
;          (+0x16) = 0xFF00                   0xFC577A
;          Evidence: `python3 notes/prom_c_understanding_round6.py --packer` asserts the
;          packer/loader split across all four VoiceRegs_Stage_* routines, the copy count, and
;          that exactly five fields are patched.
;          ⚠ WHAT THIS IS WORTH TO THE EMULATOR: on the Stage_B path the nineteen 0x00104000
;          registers of a voice are a CONSTANT image plus five patched words, not a computed
;          packing.  Unknown: what selects the Stage_B path.
; --------------------------------------------------------------------------
Dev104_LoadStageBImage:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC571A  link XIZ,0x0000
	push	xix                                   ; FC571E  push XIX
	ld	xix, (xiz+8)                            ; FC571F  ld XIX,(XIZ+0x08)
	sub	bc, bc                                 ; FC5722  sub BC,BC
	ld	wa, (0xE086:24)                        ; FC5724  ld WA,(0x00e086)
	extz	xwa                                   ; FC5729  extz XWA
	ld	(xwa+5), bc                             ; FC572B  ld (XWA+0x05),BC
	ld	bc, (0xE086:24)                        ; FC572E  ld BC,(0x00e086)
	extz	xbc                                   ; FC5733  extz XBC
	extpfx5 0xB9, 0x08, 0x02, 0x00, 0x00       ; FC5735  ld (XBC+0x08),0x0000
	ld	bc, (0xE086:24)                        ; FC573A  ld BC,(0x00e086)
	extz	xbc                                   ; FC573F  extz XBC
	extpfx5 0xB9, 0x0A, 0x02, 0x00, 0x00       ; FC5741  ld (XBC+0x0a),0x0000
	ld	bc, (0xE086:24)                        ; FC5746  ld BC,(0x00e086)
	extz	xbc                                   ; FC574B  extz XBC
	ld	(xbc+28), 0                             ; FC574D  ld (XBC+0x1c),0x00
	pushw	38                                   ; FC5751  push 0x0026
	push	xix                                   ; FC5754  push XIX
	lda	xbc, (0xFE1315:24)                     ; FC5755  lda XBC,0xfe1315
	push	xbc                                   ; FC575A  push XBC
	call	0xF9A038                              ; FC575B  call 0xf9a038
	ld	bc, (0xE086:24)                        ; FC575F  ld BC,(0x00e086)
	extz	xbc                                   ; FC5764  extz XBC
	ld	a, (xbc+7)                              ; FC5766  ld A,(XBC+0x07)
	extz	wa                                    ; FC5769  extz WA
	sll	wa, 8                                  ; FC576B  sll 0x08,WA
	ld	(xix), wa                               ; FC576E  ld (XIX),WA
	extpfx5 0xBC, 0x0A, 0x02, 0xA8, 0x05       ; FC5770  ld (XIX+0x0a),0x05a8
	extpfx5 0xBC, 0x0C, 0x02, 0xA8, 0x05       ; FC5775  ld (XIX+0x0c),0x05a8
	extpfx5 0xBC, 0x16, 0x02, 0x00, 0xFF       ; FC577A  ld (XIX+0x16),0xff00
	extpfx5 0xBC, 0x14, 0x02, 0x00, 0x80       ; FC577F  ld (XIX+0x14),0x8000
	inc	8, xsp                                 ; FC5784  inc 0,XSP
	inc	2, xsp                                 ; FC5786  inc 2,XSP
	pop	xix                                    ; FC5788  pop XIX
	unlk32 xiz                                 ; FC5789  unlk XIZ
	ret                                        ; FC578B  ret
; --------------------------------------------------------------------------
; sub_FC578C -- 0xFC578C..0xFC589D (274 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFAB6BF in sub_FAB5A5__FAB6BF, 0xFAB789 in sub_FAB6D5__FAB742
; Inputs:  no frame and no argument slot read.
; Outputs: no absolute-addressed write.
;          reads 0x00E082, 0x00E084, 0x00E086
; Evidence: the listing below is the byte-identical round-trip of 0xFC578C-0xFC589D
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC578C:
	pushw	hl                                   ; FC578C  push HL
	pushw	de                                   ; FC578D  push DE
	push	xix                                   ; FC578E  push XIX
	ld	ix, (0xE082:24)                        ; FC578F  ld IX,(0x00e082)
	sub	bc, bc                                 ; FC5794  sub BC,BC
	cpdm16_24	(0xE086), bc                     ; FC5796  cp (0x00e086),BC
	jr z, sub_FC578C__FC57BE                   ; FC579B  jr Z,0xfc57be
	ld	bc, (0xE086:24)                        ; FC579D  ld BC,(0x00e086)
	extz	xbc                                   ; FC57A2  extz XBC
	ld	hl, (xbc+5)                             ; FC57A4  ld HL,(XBC+0x05)
	sub	wa, wa                                 ; FC57A7  sub WA,WA
	cp	hl, wa                                  ; FC57A9  cp HL,WA
	jr nz, sub_FC578C__FC57B2                  ; FC57AB  jr NZ,0xfc57b2
	sub	wa, wa                                 ; FC57AD  sub WA,WA
	jrl sub_FC578C__FC589A                     ; FC57AF  jrl T,0xfc589a
sub_FC578C__FC57B2:
	ld	bc, (0xE086:24)                        ; FC57B2  ld BC,(0x00e086)
	extz	xbc                                   ; FC57B7  extz XBC
	ld	hl, (xbc+33)                            ; FC57B9  ld HL,(XBC+0x21)
	jr sub_FC578C__FC57C1                      ; FC57BC  jr T,0xfc57c1
sub_FC578C__FC57BE:
	ldw	hl, 0                                  ; FC57BE  ld HL,0x0000
sub_FC578C__FC57C1:
	ld	bc, (0xE084:24)                        ; FC57C1  ld BC,(0x00e084)
	extz	xbc                                   ; FC57C6  extz XBC
	ld	a, (xbc)                                ; FC57C8  ld A,(XBC)
	and	a, 6                                   ; FC57CA  and A,0x06
	srl	a, 1                                   ; FC57CD  srl 0x01,A
	extz	wa                                    ; FC57D0  extz WA
	cps	wa, 1                                  ; FC57D2  cp WA,1
	jr z, sub_FC578C__FC57DC                   ; FC57D4  jr Z,0xfc57dc
	cps	wa, 2                                  ; FC57D6  cp WA,2
	jr z, sub_FC578C__FC57EF                   ; FC57D8  jr Z,0xfc57ef
	jr sub_FC578C__FC5802                      ; FC57DA  jr T,0xfc5802
sub_FC578C__FC57DC:
	extz	xix                                   ; FC57DC  extz XIX
	ld	bc, (xix+3)                             ; FC57DE  ld BC,(XIX+0x03)
	add	bc, bc                                 ; FC57E1  add BC,BC
	ld	de, bc                                  ; FC57E3  ld DE,BC
	add	de, hl                                 ; FC57E5  add DE,HL
	ld	bc, de                                  ; FC57E7  ld BC,DE
	neg	bc                                     ; FC57E9  neg BC
	ld	de, bc                                  ; FC57EB  ld DE,BC
	jr sub_FC578C__FC5808                      ; FC57ED  jr T,0xfc5808
sub_FC578C__FC57EF:
	extz	xix                                   ; FC57EF  extz XIX
	ld	bc, (xix+3)                             ; FC57F1  ld BC,(XIX+0x03)
	add	bc, bc                                 ; FC57F4  add BC,BC
	ld	de, hl                                  ; FC57F6  ld DE,HL
	sub	de, bc                                 ; FC57F8  sub DE,BC
	ld	bc, de                                  ; FC57FA  ld BC,DE
	neg	bc                                     ; FC57FC  neg BC
	ld	de, bc                                  ; FC57FE  ld DE,BC
	jr sub_FC578C__FC5808                      ; FC5800  jr T,0xfc5808
sub_FC578C__FC5802:
	ld	bc, hl                                  ; FC5802  ld BC,HL
	neg	bc                                     ; FC5804  neg BC
	ld	de, bc                                  ; FC5806  ld DE,BC
sub_FC578C__FC5808:
	ld	bc, de                                  ; FC5808  ld BC,DE
	sra	bc, 4                                  ; FC580A  sra 0x04,BC
	ld	de, bc                                  ; FC580D  ld DE,BC
	cp	bc, 0xFFF8                              ; FC580F  cp BC,0xfff8
	jr ge, sub_FC578C__FC581A                  ; FC5813  jr GE,0xfc581a
	ldw	de, 0xFFF8                             ; FC5815  ld DE,0xfff8
	jr sub_FC578C__FC5823                      ; FC5818  jr T,0xfc5823
sub_FC578C__FC581A:
	cp	de, 8                                   ; FC581A  cp DE,0x0008
	jr le, sub_FC578C__FC5823                  ; FC581E  jr LE,0xfc5823
	ldw	de, 8                                  ; FC5820  ld DE,0x0008
sub_FC578C__FC5823:
	ld	bc, (0xE084:24)                        ; FC5823  ld BC,(0x00e084)
	extz	xbc                                   ; FC5828  extz XBC
	ld	a, (xbc)                                ; FC582A  ld A,(XBC)
	and	a, 24                                  ; FC582C  and A,0x18
	srl	a, 3                                   ; FC582F  srl 0x03,A
	extz	wa                                    ; FC5832  extz WA
	cps	wa, 1                                  ; FC5834  cp WA,1
	jr z, sub_FC578C__FC583E                   ; FC5836  jr Z,0xfc583e
	cps	wa, 2                                  ; FC5838  cp WA,2
	jr z, sub_FC578C__FC5858                   ; FC583A  jr Z,0xfc5858
	jr sub_FC578C__FC587E                      ; FC583C  jr T,0xfc587e
sub_FC578C__FC583E:
	extz	xix                                   ; FC583E  extz XIX
	ld	hl, (xix+1)                             ; FC5840  ld HL,(XIX+0x01)
	ld	bc, hl                                  ; FC5843  ld BC,HL
	sra	bc, 1                                  ; FC5845  sra 0x01,BC
	ld	hl, bc                                  ; FC5848  ld HL,BC
	cp	bc, 0xFFF0                              ; FC584A  cp BC,0xfff0
	jr lt, sub_FC578C__FC586E                  ; FC584E  jr LT,0xfc586e
	cp	bc, 16                                  ; FC5850  cp BC,0x0010
	jr le, sub_FC578C__FC5881                  ; FC5854  jr LE,0xfc5881
	jr sub_FC578C__FC5879                      ; FC5856  jr T,0xfc5879
sub_FC578C__FC5858:
	extz	xix                                   ; FC5858  extz XIX
	ld	hl, (xix+1)                             ; FC585A  ld HL,(XIX+0x01)
	ld	bc, hl                                  ; FC585D  ld BC,HL
	neg	bc                                     ; FC585F  neg BC
	ld	hl, bc                                  ; FC5861  ld HL,BC
	sra	bc, 1                                  ; FC5863  sra 0x01,BC
	ld	hl, bc                                  ; FC5866  ld HL,BC
	cp	bc, 0xFFF0                              ; FC5868  cp BC,0xfff0
	jr ge, sub_FC578C__FC5873                  ; FC586C  jr GE,0xfc5873
sub_FC578C__FC586E:
	ldw	hl, 0xFFF0                             ; FC586E  ld HL,0xfff0
	jr sub_FC578C__FC5881                      ; FC5871  jr T,0xfc5881
sub_FC578C__FC5873:
	cp	hl, 16                                  ; FC5873  cp HL,0x0010
	jr le, sub_FC578C__FC5881                  ; FC5877  jr LE,0xfc5881
sub_FC578C__FC5879:
	ldw	hl, 16                                 ; FC5879  ld HL,0x0010
	jr sub_FC578C__FC5881                      ; FC587C  jr T,0xfc5881
sub_FC578C__FC587E:
	ldw	hl, 0                                  ; FC587E  ld HL,0x0000
sub_FC578C__FC5881:
	ld	bc, (0xE084:24)                        ; FC5881  ld BC,(0x00e084)
	extz	xbc                                   ; FC5886  extz XBC
	ld	xwa, (xbc+3)                            ; FC5888  ld XWA,(XBC+0x03)
	ld	c, (xwa+20)                             ; FC588B  ld C,(XWA+0x14)
	extz	bc                                    ; FC588E  extz BC
	sub	bc, 0x64                               ; FC5890  sub BC,0x0064
	add	bc, de                                 ; FC5894  add BC,DE
	add	bc, hl                                 ; FC5896  add BC,HL
	ld	wa, bc                                  ; FC5898  ld WA,BC
sub_FC578C__FC589A:
	pop	xix                                    ; FC589A  pop XIX
	popw	de                                    ; FC589B  pop DE
	popw	hl                                    ; FC589C  pop HL
	ret                                        ; FC589D  ret
; --------------------------------------------------------------------------
; sub_FC589E -- 0xFC589E..0xFC59EE (337 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFAEAED in sub_FAEACE, 0xFB659F in sub_FB6500
; Inputs:  frame `link XIZ,-2`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: writes 0x00E082, 0x00E084
; Evidence: the listing below is the byte-identical round-trip of 0xFC589E-0xFC59EE
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC589E:
	link32 0xEE, 0x0C, 0xFE, 0xFF              ; FC589E  link XIZ,0xfffe
	pushw	hl                                   ; FC58A2  push HL
	push	xde                                   ; FC58A3  push XDE
	push	xix                                   ; FC58A4  push XIX
	ldb	c, 0xBB                                ; FC58A5  ld C,0xbb
	extpfx3 0x8E, 0x08, 0x43                   ; FC58A7  mul BC,(XIZ+0x08)
	ld	de, bc                                  ; FC58AA  ld DE,BC
	ldw	wa, 0x5D23                             ; FC58AC  ld WA,0x5d23
	ld	ix, wa                                  ; FC58AF  ld IX,WA
	add	ix, bc                                 ; FC58B1  add IX,BC
	stw_da	(0xE082), ix                        ; FC58B3  ld (0x00e082),IX
	extz	xix                                   ; FC58B8  extz XIX
	ld	bc, (xiz+10)                            ; FC58BA  ld BC,(XIZ+0x0a)
	ld	(xix+1), bc                             ; FC58BD  ld (XIX+0x01),BC
	ld	bc, (0xE082:24)                        ; FC58C0  ld BC,(0x00e082)
	add	bc, 19                                 ; FC58C5  add BC,0x0013
	stw_da	(0xE084), bc                        ; FC58C9  ld (0x00e084),BC
	ld	l, (xiz+12)                             ; FC58CE  ld L,(XIZ+0x0c)
	ld	de, bc                                  ; FC58D1  ld DE,BC
	ldb	h, 4                                   ; FC58D3  ld H,0x04
sub_FC589E__FC58D5:
	extz	xde                                   ; FC58D5  extz XDE
	extpfx2 0xB2, 0xB3                         ; FC58D7  res 3,(XDE)
	extpfx2 0xB2, 0xB4                         ; FC58D9  res 4,(XDE)
	ld	de, (0xE084:24)                        ; FC58DB  ld DE,(0x00e084)
	ld	bc, de                                  ; FC58E0  ld BC,DE
	extz	xde                                   ; FC58E2  extz XDE
	extpfx2 0xB2, 0xCF                         ; FC58E4  bit 7,(XDE)
	jrl z, sub_FC589E__FC59D2                  ; FC58E6  jrl Z,0xfc59d2
	ld	a, l                                    ; FC58E9  ld A,L
	and	a, 1                                   ; FC58EB  and A,0x01
	jr z, sub_FC589E__FC590A                   ; FC58EE  jr Z,0xfc590a
	ld	a, l                                    ; FC58F0  ld A,L
	and	a, 2                                   ; FC58F2  and A,0x02
	jr z, sub_FC589E__FC58FF                   ; FC58F5  jr Z,0xfc58ff
	extz	xde                                   ; FC58F7  extz XDE
	extpfx2 0xB2, 0xB3                         ; FC58F9  res 3,(XDE)
	extpfx2 0xB2, 0xBC                         ; FC58FB  set 4,(XDE)
	jr sub_FC589E__FC5905                      ; FC58FD  jr T,0xfc5905
sub_FC589E__FC58FF:
	extz	xde                                   ; FC58FF  extz XDE
	extpfx2 0xB2, 0xBB                         ; FC5901  set 3,(XDE)
	extpfx2 0xB2, 0xB4                         ; FC5903  res 4,(XDE)
sub_FC589E__FC5905:
	ld	de, (0xE084:24)                        ; FC5905  ld DE,(0x00e084)
sub_FC589E__FC590A:
	ld	bc, (0xE082:24)                        ; FC590A  ld BC,(0x00e082)
	extz	xbc                                   ; FC590F  extz XBC
	ld	a, (xbc)                                ; FC5911  ld A,(XBC)
	cps	a, 0                                   ; FC5913  cp A,0
	jrl nz, sub_FC589E__FC59D2                 ; FC5915  jrl NZ,0xfc59d2
	extz	xde                                   ; FC5918  extz XDE
	ld	xwa, (xde+3)                            ; FC591A  ld XWA,(XDE+0x03)
	ld	xix, xwa                                ; FC591D  ld XIX,XWA
	ld	iy, de                                  ; FC591F  ld IY,DE
	extz	xde                                   ; FC5921  extz XDE
	ld	c, (xde)                                ; FC5923  ld C,(XDE)
	and	c, 24                                  ; FC5925  and C,0x18
	srl	c, 3                                   ; FC5928  srl 0x03,C
	extz	bc                                    ; FC592B  extz BC
	cps	bc, 1                                  ; FC592D  cp BC,1
	jr z, sub_FC589E__FC5938                   ; FC592F  jr Z,0xfc5938
	cps	bc, 2                                  ; FC5931  cp BC,2
	jr z, sub_FC589E__FC5974                   ; FC5933  jr Z,0xfc5974
	jrl sub_FC589E__FC59B0                     ; FC5935  jrl T,0xfc59b0
sub_FC589E__FC5938:
	ld	c, (xix+21)                             ; FC5938  ld C,(XIX+0x15)
	res	7, c                                   ; FC593B  res 0x07,C
	extz	bc                                    ; FC593E  extz BC
	ld	(xiz-2), bc                             ; FC5940  ld (XIZ+0xfe),BC
	ld	wa, (0xE082:24)                        ; FC5943  ld WA,(0x00e082)
	extz	xwa                                   ; FC5948  extz XWA
	ld	iy, (xwa+1)                             ; FC594A  ld IY,(XWA+0x01)
	add	bc, iy                                 ; FC594D  add BC,IY
	extz	xde                                   ; FC594F  extz XDE
	ld	(xde+22), bc                            ; FC5951  ld (XDE+0x16),BC
	ld	de, (0xE084:24)                        ; FC5954  ld DE,(0x00e084)
	ld	c, (xix+31)                             ; FC5959  ld C,(XIX+0x1f)
	res	7, c                                   ; FC595C  res 0x07,C
	extz	bc                                    ; FC595F  extz BC
	ld	ix, bc                                  ; FC5961  ld IX,BC
	ld	wa, (0xE082:24)                        ; FC5963  ld WA,(0x00e082)
	extz	xwa                                   ; FC5968  extz XWA
	ld	iy, (xwa+1)                             ; FC596A  ld IY,(XWA+0x01)
	add	bc, iy                                 ; FC596D  add BC,IY
	ld	(xde+24), bc                            ; FC596F  ld (XDE+0x18),BC
	jr sub_FC589E__FC59CD                      ; FC5972  jr T,0xfc59cd
sub_FC589E__FC5974:
	ld	c, (xix+21)                             ; FC5974  ld C,(XIX+0x15)
	res	7, c                                   ; FC5977  res 0x07,C
	extz	bc                                    ; FC597A  extz BC
	ld	(xiz-2), bc                             ; FC597C  ld (XIZ+0xfe),BC
	ld	wa, (0xE082:24)                        ; FC597F  ld WA,(0x00e082)
	extz	xwa                                   ; FC5984  extz XWA
	ld	iy, (xwa+1)                             ; FC5986  ld IY,(XWA+0x01)
	sub	bc, iy                                 ; FC5989  sub BC,IY
	extz	xde                                   ; FC598B  extz XDE
	ld	(xde+22), bc                            ; FC598D  ld (XDE+0x16),BC
	ld	de, (0xE084:24)                        ; FC5990  ld DE,(0x00e084)
	ld	c, (xix+31)                             ; FC5995  ld C,(XIX+0x1f)
	res	7, c                                   ; FC5998  res 0x07,C
	extz	bc                                    ; FC599B  extz BC
	ld	ix, bc                                  ; FC599D  ld IX,BC
	ld	wa, (0xE082:24)                        ; FC599F  ld WA,(0x00e082)
	extz	xwa                                   ; FC59A4  extz XWA
	ld	iy, (xwa+1)                             ; FC59A6  ld IY,(XWA+0x01)
	sub	bc, iy                                 ; FC59A9  sub BC,IY
	ld	(xde+24), bc                            ; FC59AB  ld (XDE+0x18),BC
	jr sub_FC589E__FC59CD                      ; FC59AE  jr T,0xfc59cd
sub_FC589E__FC59B0:
	ld	c, (xix+21)                             ; FC59B0  ld C,(XIX+0x15)
	res	7, c                                   ; FC59B3  res 0x07,C
	extz	bc                                    ; FC59B6  extz BC
	extz	xde                                   ; FC59B8  extz XDE
	ld	(xde+22), bc                            ; FC59BA  ld (XDE+0x16),BC
	ld	de, (0xE084:24)                        ; FC59BD  ld DE,(0x00e084)
	ld	c, (xix+31)                             ; FC59C2  ld C,(XIX+0x1f)
	res	7, c                                   ; FC59C5  res 0x07,C
	extz	bc                                    ; FC59C8  extz BC
	ld	(xde+24), bc                            ; FC59CA  ld (XDE+0x18),BC
sub_FC589E__FC59CD:
	ld	de, (0xE084:24)                        ; FC59CD  ld DE,(0x00e084)
sub_FC589E__FC59D2:
	dec	1, h                                   ; FC59D2  dec 1,H
	add	de, 42                                 ; FC59D4  add DE,0x002a
	stw_da	(0xE084), de                        ; FC59D8  ld (0x00e084),DE
	ld	c, l                                    ; FC59DD  ld C,L
	srl	c, 2                                   ; FC59DF  srl 0x02,C
	ld	l, c                                    ; FC59E2  ld L,C
	cps	h, 0                                   ; FC59E4  cp H,0
	jrl nz, sub_FC589E__FC58D5                 ; FC59E6  jrl NZ,0xfc58d5
	pop	xix                                    ; FC59E9  pop XIX
	pop	xde                                    ; FC59EA  pop XDE
	popw	hl                                    ; FC59EB  pop HL
	unlk32 xiz                                 ; FC59EC  unlk XIZ
	ret                                        ; FC59EE  ret
; --------------------------------------------------------------------------
; sub_FC59EF -- 0xFC59EF..0xFC5BA1 (435 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFAEB19 in sub_FAEAF9, 0xFB65AD in sub_FB6500
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: writes 0x00E082, 0x00E084
; Evidence: the listing below is the byte-identical round-trip of 0xFC59EF-0xFC5BA1
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC59EF:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC59EF  link XIZ,0x0000
	pushw	hl                                   ; FC59F3  push HL
	pushw	de                                   ; FC59F4  push DE
	push	xix                                   ; FC59F5  push XIX
	ldb	c, 0xBB                                ; FC59F6  ld C,0xbb
	extpfx3 0x8E, 0x08, 0x43                   ; FC59F8  mul BC,(XIZ+0x08)
	ld	de, bc                                  ; FC59FB  ld DE,BC
	ldw	wa, 0x5D23                             ; FC59FD  ld WA,0x5d23
	ld	ix, wa                                  ; FC5A00  ld IX,WA
	add	ix, bc                                 ; FC5A02  add IX,BC
	stw_da	(0xE082), ix                        ; FC5A04  ld (0x00e082),IX
	extz	xix                                   ; FC5A09  extz XIX
	ld	bc, (xiz+10)                            ; FC5A0B  ld BC,(XIZ+0x0a)
	ld	(xix+3), bc                             ; FC5A0E  ld (XIX+0x03),BC
	ld	bc, (0xE082:24)                        ; FC5A11  ld BC,(0x00e082)
	add	bc, 19                                 ; FC5A16  add BC,0x0013
	stw_da	(0xE084), bc                        ; FC5A1A  ld (0x00e084),BC
	ld	l, (xiz+12)                             ; FC5A1F  ld L,(XIZ+0x0c)
	ldb	h, 4                                   ; FC5A22  ld H,0x04
sub_FC59EF__FC5A24:
	ld	bc, (0xE084:24)                        ; FC5A24  ld BC,(0x00e084)
	extz	xbc                                   ; FC5A29  extz XBC
	extpfx2 0xB1, 0xB1                         ; FC5A2B  res 1,(XBC)
	extpfx2 0xB1, 0xB2                         ; FC5A2D  res 2,(XBC)
	extpfx2 0xB1, 0xB5                         ; FC5A2F  res 5,(XBC)
	extpfx2 0xB1, 0xCF                         ; FC5A31  bit 7,(XBC)
	jrl z, sub_FC59EF__FC5B87                  ; FC5A33  jrl Z,0xfc5b87
	ld	a, l                                    ; FC5A36  ld A,L
	and	a, 1                                   ; FC5A38  and A,0x01
	jr z, sub_FC59EF__FC5A57                   ; FC5A3B  jr Z,0xfc5a57
	extpfx2 0xB1, 0xBD                         ; FC5A3D  set 5,(XBC)
	ld	a, l                                    ; FC5A3F  ld A,L
	and	a, 2                                   ; FC5A41  and A,0x02
	jr z, sub_FC59EF__FC5A4C                   ; FC5A44  jr Z,0xfc5a4c
	extpfx2 0xB1, 0xB1                         ; FC5A46  res 1,(XBC)
	extpfx2 0xB1, 0xBA                         ; FC5A48  set 2,(XBC)
	jr sub_FC59EF__FC5A57                      ; FC5A4A  jr T,0xfc5a57
sub_FC59EF__FC5A4C:
	ld	bc, (0xE084:24)                        ; FC5A4C  ld BC,(0x00e084)
	extz	xbc                                   ; FC5A51  extz XBC
	extpfx2 0xB1, 0xB9                         ; FC5A53  set 1,(XBC)
	extpfx2 0xB1, 0xB2                         ; FC5A55  res 2,(XBC)
sub_FC59EF__FC5A57:
	ld	bc, (0xE082:24)                        ; FC5A57  ld BC,(0x00e082)
	extz	xbc                                   ; FC5A5C  extz XBC
	ld	a, (xbc)                                ; FC5A5E  ld A,(XBC)
	cps	a, 0                                   ; FC5A60  cp A,0
	jrl nz, sub_FC59EF__FC5B87                 ; FC5A62  jrl NZ,0xfc5b87
	ld	wa, (0xE084:24)                        ; FC5A65  ld WA,(0x00e084)
	extz	xwa                                   ; FC5A6A  extz XWA
	ld	xiy, (xwa+3)                            ; FC5A6C  ld XIY,(XWA+0x03)
	ld	xix, xiy                                ; FC5A6F  ld XIX,XIY
	ld	c, (xwa)                                ; FC5A71  ld C,(XWA)
	and	c, 6                                   ; FC5A73  and C,0x06
	srl	c, 1                                   ; FC5A76  srl 0x01,C
	extz	bc                                    ; FC5A79  extz BC
	cps	bc, 1                                  ; FC5A7B  cp BC,1
	jr z, sub_FC59EF__FC5A86                   ; FC5A7D  jr Z,0xfc5a86
	cps	bc, 2                                  ; FC5A7F  cp BC,2
	jr z, sub_FC59EF__FC5AB5                   ; FC5A81  jr Z,0xfc5ab5
	jrl sub_FC59EF__FC5B20                     ; FC5A83  jrl T,0xfc5b20
sub_FC59EF__FC5A86:
	ld	c, (xix+13)                             ; FC5A86  ld C,(XIX+0x0d)
	extz	bc                                    ; FC5A89  extz BC
	ld	de, bc                                  ; FC5A8B  ld DE,BC
	ld	wa, (0xE082:24)                        ; FC5A8D  ld WA,(0x00e082)
	extz	xwa                                   ; FC5A92  extz XWA
	ld	iy, (xwa+3)                             ; FC5A94  ld IY,(XWA+0x03)
	add	bc, iy                                 ; FC5A97  add BC,IY
	ld	de, bc                                  ; FC5A99  ld DE,BC
	ld	bc, (0xE084:24)                        ; FC5A9B  ld BC,(0x00e084)
	extz	xbc                                   ; FC5AA0  extz XBC
	ld	(xbc+32), de                            ; FC5AA2  ld (XBC+0x20),DE
	ld	bc, (0xE082:24)                        ; FC5AA5  ld BC,(0x00e082)
	extz	xbc                                   ; FC5AAA  extz XBC
	ld	wa, (xbc+3)                             ; FC5AAC  ld WA,(XBC+0x03)
	cps	wa, 0                                  ; FC5AAF  cp WA,0
	jr ge, sub_FC59EF__FC5AF9                  ; FC5AB1  jr GE,0xfc5af9
	jr sub_FC59EF__FC5AE2                      ; FC5AB3  jr T,0xfc5ae2
sub_FC59EF__FC5AB5:
	ld	c, (xix+13)                             ; FC5AB5  ld C,(XIX+0x0d)
	extz	bc                                    ; FC5AB8  extz BC
	ld	de, bc                                  ; FC5ABA  ld DE,BC
	ld	wa, (0xE082:24)                        ; FC5ABC  ld WA,(0x00e082)
	extz	xwa                                   ; FC5AC1  extz XWA
	ld	iy, (xwa+3)                             ; FC5AC3  ld IY,(XWA+0x03)
	sub	bc, iy                                 ; FC5AC6  sub BC,IY
	ld	de, bc                                  ; FC5AC8  ld DE,BC
	ld	bc, (0xE084:24)                        ; FC5ACA  ld BC,(0x00e084)
	extz	xbc                                   ; FC5ACF  extz XBC
	ld	(xbc+32), de                            ; FC5AD1  ld (XBC+0x20),DE
	ld	bc, (0xE082:24)                        ; FC5AD4  ld BC,(0x00e082)
	extz	xbc                                   ; FC5AD9  extz XBC
	ld	wa, (xbc+3)                             ; FC5ADB  ld WA,(XBC+0x03)
	cps	wa, 0                                  ; FC5ADE  cp WA,0
	jr ge, sub_FC59EF__FC5AF9                  ; FC5AE0  jr GE,0xfc5af9
sub_FC59EF__FC5AE2:
	ld	bc, (0xE082:24)                        ; FC5AE2  ld BC,(0x00e082)
	extz	xbc                                   ; FC5AE7  extz XBC
	ld	de, (xbc+3)                             ; FC5AE9  ld DE,(XBC+0x03)
	ld	wa, de                                  ; FC5AEC  ld WA,DE
	neg	wa                                     ; FC5AEE  neg WA
	ld	de, wa                                  ; FC5AF0  ld DE,WA
	sra	wa, 2                                  ; FC5AF2  sra 0x02,WA
	ld	de, wa                                  ; FC5AF5  ld DE,WA
	jr sub_FC59EF__FC5B0A                      ; FC5AF7  jr T,0xfc5b0a
sub_FC59EF__FC5AF9:
	ld	bc, (0xE082:24)                        ; FC5AF9  ld BC,(0x00e082)
	extz	xbc                                   ; FC5AFE  extz XBC
	ld	de, (xbc+3)                             ; FC5B00  ld DE,(XBC+0x03)
	ld	iy, de                                  ; FC5B03  ld IY,DE
	sra	iy, 2                                  ; FC5B05  sra 0x02,IY
	ld	de, iy                                  ; FC5B08  ld DE,IY
sub_FC59EF__FC5B0A:
	ld	c, (xix+14)                             ; FC5B0A  ld C,(XIX+0x0e)
	res	7, c                                   ; FC5B0D  res 0x07,C
	extz	bc                                    ; FC5B10  extz BC
	add	bc, de                                 ; FC5B12  add BC,DE
	ld	wa, (0xE084:24)                        ; FC5B14  ld WA,(0x00e084)
	extz	xwa                                   ; FC5B19  extz XWA
	ld	(xwa+34), bc                            ; FC5B1B  ld (XWA+0x22),BC
	jr sub_FC59EF__FC5B41                      ; FC5B1E  jr T,0xfc5b41
sub_FC59EF__FC5B20:
	ld	c, (xix+13)                             ; FC5B20  ld C,(XIX+0x0d)
	extz	bc                                    ; FC5B23  extz BC
	ld	wa, (0xE084:24)                        ; FC5B25  ld WA,(0x00e084)
	extz	xwa                                   ; FC5B2A  extz XWA
	ld	(xwa+32), bc                            ; FC5B2C  ld (XWA+0x20),BC
	ld	c, (xix+14)                             ; FC5B2F  ld C,(XIX+0x0e)
	res	7, c                                   ; FC5B32  res 0x07,C
	extz	bc                                    ; FC5B35  extz BC
	ld	wa, (0xE084:24)                        ; FC5B37  ld WA,(0x00e084)
	extz	xwa                                   ; FC5B3C  extz XWA
	ld	(xwa+34), bc                            ; FC5B3E  ld (XWA+0x22),BC
sub_FC59EF__FC5B41:
	ld	bc, (0xE084:24)                        ; FC5B41  ld BC,(0x00e084)
	extz	xbc                                   ; FC5B46  extz XBC
	ld	a, (xbc+1)                              ; FC5B48  ld A,(XBC+0x01)
	and	a, 0xC0                                ; FC5B4B  and A,0xc0
	srl	a, 6                                   ; FC5B4E  srl 0x06,A
	extz	wa                                    ; FC5B51  extz WA
	cps	wa, 1                                  ; FC5B53  cp WA,1
	jr z, sub_FC59EF__FC5B5D                   ; FC5B55  jr Z,0xfc5b5d
	cps	wa, 2                                  ; FC5B57  cp WA,2
	jr z, sub_FC59EF__FC5B73                   ; FC5B59  jr Z,0xfc5b73
	jr sub_FC59EF__FC5B87                      ; FC5B5B  jr T,0xfc5b87
sub_FC59EF__FC5B5D:
	ld	bc, (0xE082:24)                        ; FC5B5D  ld BC,(0x00e082)
	extz	xbc                                   ; FC5B62  extz XBC
	ld	wa, (xbc+5)                             ; FC5B64  ld WA,(XBC+0x05)
	ld	bc, (0xE084:24)                        ; FC5B67  ld BC,(0x00e084)
	extz	xbc                                   ; FC5B6C  extz XBC
	add	(xbc+34), wa                           ; FC5B6E  add (XBC+0x22),WA
	jr sub_FC59EF__FC5B87                      ; FC5B71  jr T,0xfc5b87
sub_FC59EF__FC5B73:
	ld	bc, (0xE082:24)                        ; FC5B73  ld BC,(0x00e082)
	extz	xbc                                   ; FC5B78  extz XBC
	ld	wa, (xbc+5)                             ; FC5B7A  ld WA,(XBC+0x05)
	ld	bc, (0xE084:24)                        ; FC5B7D  ld BC,(0x00e084)
	extz	xbc                                   ; FC5B82  extz XBC
	sub	(xbc+34), wa                           ; FC5B84  sub (XBC+0x22),WA
sub_FC59EF__FC5B87:
	dec	1, h                                   ; FC5B87  dec 1,H
	extpfx7 0xD2, 0x84, 0xE0, 0x00, 0x38, 0x2A, 0x00 ; FC5B89  add (0x00e084),0x002a
	ld	c, l                                    ; FC5B90  ld C,L
	srl	c, 2                                   ; FC5B92  srl 0x02,C
	ld	l, c                                    ; FC5B95  ld L,C
	cps	h, 0                                   ; FC5B97  cp H,0
	jrl nz, sub_FC59EF__FC5A24                 ; FC5B99  jrl NZ,0xfc5a24
	pop	xix                                    ; FC5B9C  pop XIX
	popw	de                                    ; FC5B9D  pop DE
	popw	hl                                    ; FC5B9E  pop HL
	unlk32 xiz                                 ; FC5B9F  unlk XIZ
	ret                                        ; FC5BA1  ret
; --------------------------------------------------------------------------
; sub_FC5BA2 -- 0xFC5BA2..0xFC5D5A (441 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFAEB85 in sub_FAEB65
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: writes 0x00E082, 0x00E084
; Evidence: the listing below is the byte-identical round-trip of 0xFC5BA2-0xFC5D5A
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC5BA2:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC5BA2  link XIZ,0x0000
	pushw	hl                                   ; FC5BA6  push HL
	pushw	de                                   ; FC5BA7  push DE
	push	xix                                   ; FC5BA8  push XIX
	ldb	c, 0xBB                                ; FC5BA9  ld C,0xbb
	extpfx3 0x8E, 0x08, 0x43                   ; FC5BAB  mul BC,(XIZ+0x08)
	ld	de, bc                                  ; FC5BAE  ld DE,BC
	ldw	wa, 0x5D23                             ; FC5BB0  ld WA,0x5d23
	ld	ix, wa                                  ; FC5BB3  ld IX,WA
	add	ix, bc                                 ; FC5BB5  add IX,BC
	stw_da	(0xE082), ix                        ; FC5BB7  ld (0x00e082),IX
	extz	xix                                   ; FC5BBC  extz XIX
	ld	bc, (xiz+10)                            ; FC5BBE  ld BC,(XIZ+0x0a)
	ld	(xix+5), bc                             ; FC5BC1  ld (XIX+0x05),BC
	ld	bc, (0xE082:24)                        ; FC5BC4  ld BC,(0x00e082)
	add	bc, 19                                 ; FC5BC9  add BC,0x0013
	stw_da	(0xE084), bc                        ; FC5BCD  ld (0x00e084),BC
	ld	l, (xiz+12)                             ; FC5BD2  ld L,(XIZ+0x0c)
	ldb	h, 4                                   ; FC5BD5  ld H,0x04
sub_FC5BA2__FC5BD7:
	ld	bc, (0xE084:24)                        ; FC5BD7  ld BC,(0x00e084)
	extz	xbc                                   ; FC5BDC  extz XBC
	extpfx3 0xB9, 0x01, 0xB6                   ; FC5BDE  res 6,(XBC+0x01)
	extpfx3 0xB9, 0x01, 0xB7                   ; FC5BE1  res 7,(XBC+0x01)
	extpfx2 0xB1, 0xB5                         ; FC5BE4  res 5,(XBC)
	extpfx2 0xB1, 0xCF                         ; FC5BE6  bit 7,(XBC)
	jrl z, sub_FC5BA2__FC5D40                  ; FC5BE8  jrl Z,0xfc5d40
	ld	a, l                                    ; FC5BEB  ld A,L
	and	a, 1                                   ; FC5BED  and A,0x01
	jr z, sub_FC5BA2__FC5C10                   ; FC5BF0  jr Z,0xfc5c10
	extpfx2 0xB1, 0xBD                         ; FC5BF2  set 5,(XBC)
	ld	a, l                                    ; FC5BF4  ld A,L
	and	a, 2                                   ; FC5BF6  and A,0x02
	jr z, sub_FC5BA2__FC5C03                   ; FC5BF9  jr Z,0xfc5c03
	extpfx3 0xB9, 0x01, 0xB6                   ; FC5BFB  res 6,(XBC+0x01)
	extpfx3 0xB9, 0x01, 0xBF                   ; FC5BFE  set 7,(XBC+0x01)
	jr sub_FC5BA2__FC5C10                      ; FC5C01  jr T,0xfc5c10
sub_FC5BA2__FC5C03:
	ld	bc, (0xE084:24)                        ; FC5C03  ld BC,(0x00e084)
	extz	xbc                                   ; FC5C08  extz XBC
	extpfx3 0xB9, 0x01, 0xBE                   ; FC5C0A  set 6,(XBC+0x01)
	extpfx3 0xB9, 0x01, 0xB7                   ; FC5C0D  res 7,(XBC+0x01)
sub_FC5BA2__FC5C10:
	ld	bc, (0xE082:24)                        ; FC5C10  ld BC,(0x00e082)
	extz	xbc                                   ; FC5C15  extz XBC
	ld	a, (xbc)                                ; FC5C17  ld A,(XBC)
	cps	a, 0                                   ; FC5C19  cp A,0
	jrl nz, sub_FC5BA2__FC5D40                 ; FC5C1B  jrl NZ,0xfc5d40
	ld	wa, (0xE084:24)                        ; FC5C1E  ld WA,(0x00e084)
	extz	xwa                                   ; FC5C23  extz XWA
	ld	xiy, (xwa+3)                            ; FC5C25  ld XIY,(XWA+0x03)
	ld	xix, xiy                                ; FC5C28  ld XIX,XIY
	ld	c, (xwa)                                ; FC5C2A  ld C,(XWA)
	and	c, 6                                   ; FC5C2C  and C,0x06
	srl	c, 1                                   ; FC5C2F  srl 0x01,C
	extz	bc                                    ; FC5C32  extz BC
	cps	bc, 1                                  ; FC5C34  cp BC,1
	jr z, sub_FC5BA2__FC5C3F                   ; FC5C36  jr Z,0xfc5c3f
	cps	bc, 2                                  ; FC5C38  cp BC,2
	jr z, sub_FC5BA2__FC5C6E                   ; FC5C3A  jr Z,0xfc5c6e
	jrl sub_FC5BA2__FC5CD9                     ; FC5C3C  jrl T,0xfc5cd9
sub_FC5BA2__FC5C3F:
	ld	c, (xix+13)                             ; FC5C3F  ld C,(XIX+0x0d)
	extz	bc                                    ; FC5C42  extz BC
	ld	de, bc                                  ; FC5C44  ld DE,BC
	ld	wa, (0xE082:24)                        ; FC5C46  ld WA,(0x00e082)
	extz	xwa                                   ; FC5C4B  extz XWA
	ld	iy, (xwa+3)                             ; FC5C4D  ld IY,(XWA+0x03)
	add	bc, iy                                 ; FC5C50  add BC,IY
	ld	de, bc                                  ; FC5C52  ld DE,BC
	ld	bc, (0xE084:24)                        ; FC5C54  ld BC,(0x00e084)
	extz	xbc                                   ; FC5C59  extz XBC
	ld	(xbc+32), de                            ; FC5C5B  ld (XBC+0x20),DE
	ld	bc, (0xE082:24)                        ; FC5C5E  ld BC,(0x00e082)
	extz	xbc                                   ; FC5C63  extz XBC
	ld	wa, (xbc+3)                             ; FC5C65  ld WA,(XBC+0x03)
	cps	wa, 0                                  ; FC5C68  cp WA,0
	jr ge, sub_FC5BA2__FC5CB2                  ; FC5C6A  jr GE,0xfc5cb2
	jr sub_FC5BA2__FC5C9B                      ; FC5C6C  jr T,0xfc5c9b
sub_FC5BA2__FC5C6E:
	ld	c, (xix+13)                             ; FC5C6E  ld C,(XIX+0x0d)
	extz	bc                                    ; FC5C71  extz BC
	ld	de, bc                                  ; FC5C73  ld DE,BC
	ld	wa, (0xE082:24)                        ; FC5C75  ld WA,(0x00e082)
	extz	xwa                                   ; FC5C7A  extz XWA
	ld	iy, (xwa+3)                             ; FC5C7C  ld IY,(XWA+0x03)
	sub	bc, iy                                 ; FC5C7F  sub BC,IY
	ld	de, bc                                  ; FC5C81  ld DE,BC
	ld	bc, (0xE084:24)                        ; FC5C83  ld BC,(0x00e084)
	extz	xbc                                   ; FC5C88  extz XBC
	ld	(xbc+32), de                            ; FC5C8A  ld (XBC+0x20),DE
	ld	bc, (0xE082:24)                        ; FC5C8D  ld BC,(0x00e082)
	extz	xbc                                   ; FC5C92  extz XBC
	ld	wa, (xbc+3)                             ; FC5C94  ld WA,(XBC+0x03)
	cps	wa, 0                                  ; FC5C97  cp WA,0
	jr ge, sub_FC5BA2__FC5CB2                  ; FC5C99  jr GE,0xfc5cb2
sub_FC5BA2__FC5C9B:
	ld	bc, (0xE082:24)                        ; FC5C9B  ld BC,(0x00e082)
	extz	xbc                                   ; FC5CA0  extz XBC
	ld	de, (xbc+3)                             ; FC5CA2  ld DE,(XBC+0x03)
	ld	wa, de                                  ; FC5CA5  ld WA,DE
	neg	wa                                     ; FC5CA7  neg WA
	ld	de, wa                                  ; FC5CA9  ld DE,WA
	sra	wa, 2                                  ; FC5CAB  sra 0x02,WA
	ld	de, wa                                  ; FC5CAE  ld DE,WA
	jr sub_FC5BA2__FC5CC3                      ; FC5CB0  jr T,0xfc5cc3
sub_FC5BA2__FC5CB2:
	ld	bc, (0xE082:24)                        ; FC5CB2  ld BC,(0x00e082)
	extz	xbc                                   ; FC5CB7  extz XBC
	ld	de, (xbc+3)                             ; FC5CB9  ld DE,(XBC+0x03)
	ld	iy, de                                  ; FC5CBC  ld IY,DE
	sra	iy, 2                                  ; FC5CBE  sra 0x02,IY
	ld	de, iy                                  ; FC5CC1  ld DE,IY
sub_FC5BA2__FC5CC3:
	ld	c, (xix+14)                             ; FC5CC3  ld C,(XIX+0x0e)
	res	7, c                                   ; FC5CC6  res 0x07,C
	extz	bc                                    ; FC5CC9  extz BC
	add	bc, de                                 ; FC5CCB  add BC,DE
	ld	wa, (0xE084:24)                        ; FC5CCD  ld WA,(0x00e084)
	extz	xwa                                   ; FC5CD2  extz XWA
	ld	(xwa+34), bc                            ; FC5CD4  ld (XWA+0x22),BC
	jr sub_FC5BA2__FC5CFA                      ; FC5CD7  jr T,0xfc5cfa
sub_FC5BA2__FC5CD9:
	ld	c, (xix+13)                             ; FC5CD9  ld C,(XIX+0x0d)
	extz	bc                                    ; FC5CDC  extz BC
	ld	wa, (0xE084:24)                        ; FC5CDE  ld WA,(0x00e084)
	extz	xwa                                   ; FC5CE3  extz XWA
	ld	(xwa+32), bc                            ; FC5CE5  ld (XWA+0x20),BC
	ld	c, (xix+14)                             ; FC5CE8  ld C,(XIX+0x0e)
	res	7, c                                   ; FC5CEB  res 0x07,C
	extz	bc                                    ; FC5CEE  extz BC
	ld	wa, (0xE084:24)                        ; FC5CF0  ld WA,(0x00e084)
	extz	xwa                                   ; FC5CF5  extz XWA
	ld	(xwa+34), bc                            ; FC5CF7  ld (XWA+0x22),BC
sub_FC5BA2__FC5CFA:
	ld	bc, (0xE084:24)                        ; FC5CFA  ld BC,(0x00e084)
	extz	xbc                                   ; FC5CFF  extz XBC
	ld	a, (xbc+1)                              ; FC5D01  ld A,(XBC+0x01)
	and	a, 0xC0                                ; FC5D04  and A,0xc0
	srl	a, 6                                   ; FC5D07  srl 0x06,A
	extz	wa                                    ; FC5D0A  extz WA
	cps	wa, 1                                  ; FC5D0C  cp WA,1
	jr z, sub_FC5BA2__FC5D16                   ; FC5D0E  jr Z,0xfc5d16
	cps	wa, 2                                  ; FC5D10  cp WA,2
	jr z, sub_FC5BA2__FC5D2C                   ; FC5D12  jr Z,0xfc5d2c
	jr sub_FC5BA2__FC5D40                      ; FC5D14  jr T,0xfc5d40
sub_FC5BA2__FC5D16:
	ld	bc, (0xE082:24)                        ; FC5D16  ld BC,(0x00e082)
	extz	xbc                                   ; FC5D1B  extz XBC
	ld	wa, (xbc+5)                             ; FC5D1D  ld WA,(XBC+0x05)
	ld	bc, (0xE084:24)                        ; FC5D20  ld BC,(0x00e084)
	extz	xbc                                   ; FC5D25  extz XBC
	add	(xbc+34), wa                           ; FC5D27  add (XBC+0x22),WA
	jr sub_FC5BA2__FC5D40                      ; FC5D2A  jr T,0xfc5d40
sub_FC5BA2__FC5D2C:
	ld	bc, (0xE082:24)                        ; FC5D2C  ld BC,(0x00e082)
	extz	xbc                                   ; FC5D31  extz XBC
	ld	wa, (xbc+5)                             ; FC5D33  ld WA,(XBC+0x05)
	ld	bc, (0xE084:24)                        ; FC5D36  ld BC,(0x00e084)
	extz	xbc                                   ; FC5D3B  extz XBC
	sub	(xbc+34), wa                           ; FC5D3D  sub (XBC+0x22),WA
sub_FC5BA2__FC5D40:
	dec	1, h                                   ; FC5D40  dec 1,H
	extpfx7 0xD2, 0x84, 0xE0, 0x00, 0x38, 0x2A, 0x00 ; FC5D42  add (0x00e084),0x002a
	ld	c, l                                    ; FC5D49  ld C,L
	srl	c, 2                                   ; FC5D4B  srl 0x02,C
	ld	l, c                                    ; FC5D4E  ld L,C
	cps	h, 0                                   ; FC5D50  cp H,0
	jrl nz, sub_FC5BA2__FC5BD7                 ; FC5D52  jrl NZ,0xfc5bd7
	pop	xix                                    ; FC5D55  pop XIX
	popw	de                                    ; FC5D56  pop DE
	popw	hl                                    ; FC5D57  pop HL
	unlk32 xiz                                 ; FC5D58  unlk XIZ
	ret                                        ; FC5D5A  ret
; --------------------------------------------------------------------------
; sub_FC5D5B -- 0xFC5D5B..0xFC5EFA (416 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFAEB41 in sub_FAEAF9__FAEB30, 0xFAEBAD in sub_FAEB65__FAEB9C
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: writes 0x00E084, 0x00E086
;          reads 0x00E082
; Calls:   0xFC49AD = sub_FC49AD
; Evidence: the listing below is the byte-identical round-trip of 0xFC5D5B-0xFC5EFA
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC5D5B:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC5D5B  link XIZ,0x0000
	pushw	hl                                   ; FC5D5F  push HL
	pushw	de                                   ; FC5D60  push DE
	push	xix                                   ; FC5D61  push XIX
	ldb	c, 37                                  ; FC5D62  ld C,0x25
	extpfx3 0x8E, 0x08, 0x43                   ; FC5D64  mul BC,(XIZ+0x08)
	ld	hl, bc                                  ; FC5D67  ld HL,BC
	ldw	wa, 0x753E                             ; FC5D69  ld WA,0x753e
	add	wa, bc                                 ; FC5D6C  add WA,BC
	stw_da	(0xE086), wa                        ; FC5D6E  ld (0x00e086),WA
	extz	xwa                                   ; FC5D73  extz XWA
	ld	bc, (xwa+5)                             ; FC5D75  ld BC,(XWA+0x05)
	stw_da	(0xE084), bc                        ; FC5D78  ld (0x00e084),BC
	sub	iy, iy                                 ; FC5D7D  sub IY,IY
	cp	bc, iy                                  ; FC5D7F  cp BC,IY
	jrl z, sub_FC5D5B__FC5EEF                  ; FC5D81  jrl Z,0xfc5eef
	ld	iy, bc                                  ; FC5D84  ld IY,BC
	extz	xbc                                   ; FC5D86  extz XBC
	ld	c, (xbc)                                ; FC5D88  ld C,(XBC)
	and	c, 32                                  ; FC5D8A  and C,0x20
	srl	c, 5                                   ; FC5D8D  srl 0x05,C
	ld	d, c                                    ; FC5D90  ld D,C
	cps	c, 0                                   ; FC5D92  cp C,0
	jrl z, sub_FC5D5B__FC5EF3                  ; FC5D94  jrl Z,0xfc5ef3
	ld	b, (xwa)                                ; FC5D97  ld B,(XWA)
	cps	b, 0                                   ; FC5D99  cp B,0
	jrl z, sub_FC5D5B__FC5EBD                  ; FC5D9B  jrl Z,0xfc5ebd
	ld	xbc, (xwa+1)                            ; FC5D9E  ld XBC,(XWA+0x01)
	ld	xix, xbc                                ; FC5DA1  ld XIX,XBC
	ld	bc, iy                                  ; FC5DA3  ld BC,IY
	extz	xiy                                   ; FC5DA5  extz XIY
	ld	c, (xiy)                                ; FC5DA7  ld C,(XIY)
	and	c, 6                                   ; FC5DA9  and C,0x06
	srl	c, 1                                   ; FC5DAC  srl 0x01,C
	extz	bc                                    ; FC5DAF  extz BC
	cps	bc, 1                                  ; FC5DB1  cp BC,1
	jr z, sub_FC5D5B__FC5DBC                   ; FC5DB3  jr Z,0xfc5dbc
	cps	bc, 2                                  ; FC5DB5  cp BC,2
	jr z, sub_FC5D5B__FC5DEB                   ; FC5DB7  jr Z,0xfc5deb
	jrl sub_FC5D5B__FC5E56                     ; FC5DB9  jrl T,0xfc5e56
sub_FC5D5B__FC5DBC:
	ld	c, (xix+13)                             ; FC5DBC  ld C,(XIX+0x0d)
	extz	bc                                    ; FC5DBF  extz BC
	ld	hl, bc                                  ; FC5DC1  ld HL,BC
	ld	wa, (0xE082:24)                        ; FC5DC3  ld WA,(0x00e082)
	extz	xwa                                   ; FC5DC8  extz XWA
	ld	iy, (xwa+3)                             ; FC5DCA  ld IY,(XWA+0x03)
	add	bc, iy                                 ; FC5DCD  add BC,IY
	ld	hl, bc                                  ; FC5DCF  ld HL,BC
	ld	bc, (0xE084:24)                        ; FC5DD1  ld BC,(0x00e084)
	extz	xbc                                   ; FC5DD6  extz XBC
	ld	(xbc+32), hl                            ; FC5DD8  ld (XBC+0x20),HL
	ld	bc, (0xE082:24)                        ; FC5DDB  ld BC,(0x00e082)
	extz	xbc                                   ; FC5DE0  extz XBC
	ld	wa, (xbc+3)                             ; FC5DE2  ld WA,(XBC+0x03)
	cps	wa, 0                                  ; FC5DE5  cp WA,0
	jr ge, sub_FC5D5B__FC5E2F                  ; FC5DE7  jr GE,0xfc5e2f
	jr sub_FC5D5B__FC5E18                      ; FC5DE9  jr T,0xfc5e18
sub_FC5D5B__FC5DEB:
	ld	c, (xix+13)                             ; FC5DEB  ld C,(XIX+0x0d)
	extz	bc                                    ; FC5DEE  extz BC
	ld	hl, bc                                  ; FC5DF0  ld HL,BC
	ld	wa, (0xE082:24)                        ; FC5DF2  ld WA,(0x00e082)
	extz	xwa                                   ; FC5DF7  extz XWA
	ld	iy, (xwa+3)                             ; FC5DF9  ld IY,(XWA+0x03)
	sub	bc, iy                                 ; FC5DFC  sub BC,IY
	ld	hl, bc                                  ; FC5DFE  ld HL,BC
	ld	bc, (0xE084:24)                        ; FC5E00  ld BC,(0x00e084)
	extz	xbc                                   ; FC5E05  extz XBC
	ld	(xbc+32), hl                            ; FC5E07  ld (XBC+0x20),HL
	ld	bc, (0xE082:24)                        ; FC5E0A  ld BC,(0x00e082)
	extz	xbc                                   ; FC5E0F  extz XBC
	ld	wa, (xbc+3)                             ; FC5E11  ld WA,(XBC+0x03)
	cps	wa, 0                                  ; FC5E14  cp WA,0
	jr ge, sub_FC5D5B__FC5E2F                  ; FC5E16  jr GE,0xfc5e2f
sub_FC5D5B__FC5E18:
	ld	bc, (0xE082:24)                        ; FC5E18  ld BC,(0x00e082)
	extz	xbc                                   ; FC5E1D  extz XBC
	ld	hl, (xbc+3)                             ; FC5E1F  ld HL,(XBC+0x03)
	ld	wa, hl                                  ; FC5E22  ld WA,HL
	neg	wa                                     ; FC5E24  neg WA
	ld	hl, wa                                  ; FC5E26  ld HL,WA
	sra	wa, 2                                  ; FC5E28  sra 0x02,WA
	ld	hl, wa                                  ; FC5E2B  ld HL,WA
	jr sub_FC5D5B__FC5E40                      ; FC5E2D  jr T,0xfc5e40
sub_FC5D5B__FC5E2F:
	ld	bc, (0xE082:24)                        ; FC5E2F  ld BC,(0x00e082)
	extz	xbc                                   ; FC5E34  extz XBC
	ld	hl, (xbc+3)                             ; FC5E36  ld HL,(XBC+0x03)
	ld	iy, hl                                  ; FC5E39  ld IY,HL
	sra	iy, 2                                  ; FC5E3B  sra 0x02,IY
	ld	hl, iy                                  ; FC5E3E  ld HL,IY
sub_FC5D5B__FC5E40:
	ld	c, (xix+14)                             ; FC5E40  ld C,(XIX+0x0e)
	res	7, c                                   ; FC5E43  res 0x07,C
	extz	bc                                    ; FC5E46  extz BC
	add	bc, hl                                 ; FC5E48  add BC,HL
	ld	wa, (0xE084:24)                        ; FC5E4A  ld WA,(0x00e084)
	extz	xwa                                   ; FC5E4F  extz XWA
	ld	(xwa+34), bc                            ; FC5E51  ld (XWA+0x22),BC
	jr sub_FC5D5B__FC5E77                      ; FC5E54  jr T,0xfc5e77
sub_FC5D5B__FC5E56:
	ld	c, (xix+13)                             ; FC5E56  ld C,(XIX+0x0d)
	extz	bc                                    ; FC5E59  extz BC
	ld	wa, (0xE084:24)                        ; FC5E5B  ld WA,(0x00e084)
	extz	xwa                                   ; FC5E60  extz XWA
	ld	(xwa+32), bc                            ; FC5E62  ld (XWA+0x20),BC
	ld	c, (xix+14)                             ; FC5E65  ld C,(XIX+0x0e)
	res	7, c                                   ; FC5E68  res 0x07,C
	extz	bc                                    ; FC5E6B  extz BC
	ld	wa, (0xE084:24)                        ; FC5E6D  ld WA,(0x00e084)
	extz	xwa                                   ; FC5E72  extz XWA
	ld	(xwa+34), bc                            ; FC5E74  ld (XWA+0x22),BC
sub_FC5D5B__FC5E77:
	ld	bc, (0xE084:24)                        ; FC5E77  ld BC,(0x00e084)
	extz	xbc                                   ; FC5E7C  extz XBC
	ld	a, (xbc+1)                              ; FC5E7E  ld A,(XBC+0x01)
	and	a, 0xC0                                ; FC5E81  and A,0xc0
	srl	a, 6                                   ; FC5E84  srl 0x06,A
	extz	wa                                    ; FC5E87  extz WA
	cps	wa, 1                                  ; FC5E89  cp WA,1
	jr z, sub_FC5D5B__FC5E93                   ; FC5E8B  jr Z,0xfc5e93
	cps	wa, 2                                  ; FC5E8D  cp WA,2
	jr z, sub_FC5D5B__FC5EA9                   ; FC5E8F  jr Z,0xfc5ea9
	jr sub_FC5D5B__FC5EBD                      ; FC5E91  jr T,0xfc5ebd
sub_FC5D5B__FC5E93:
	ld	bc, (0xE082:24)                        ; FC5E93  ld BC,(0x00e082)
	extz	xbc                                   ; FC5E98  extz XBC
	ld	wa, (xbc+5)                             ; FC5E9A  ld WA,(XBC+0x05)
	ld	bc, (0xE084:24)                        ; FC5E9D  ld BC,(0x00e084)
	extz	xbc                                   ; FC5EA2  extz XBC
	add	(xbc+34), wa                           ; FC5EA4  add (XBC+0x22),WA
	jr sub_FC5D5B__FC5EBD                      ; FC5EA7  jr T,0xfc5ebd
sub_FC5D5B__FC5EA9:
	ld	bc, (0xE082:24)                        ; FC5EA9  ld BC,(0x00e082)
	extz	xbc                                   ; FC5EAE  extz XBC
	ld	wa, (xbc+5)                             ; FC5EB0  ld WA,(XBC+0x05)
	ld	bc, (0xE084:24)                        ; FC5EB3  ld BC,(0x00e084)
	extz	xbc                                   ; FC5EB8  extz XBC
	sub	(xbc+34), wa                           ; FC5EBA  sub (XBC+0x22),WA
sub_FC5D5B__FC5EBD:
	ld	bc, (0xE084:24)                        ; FC5EBD  ld BC,(0x00e084)
	extz	xbc                                   ; FC5EC2  extz XBC
	ld	wa, (xbc+32)                            ; FC5EC4  ld WA,(XBC+0x20)
	ld	bc, (0xE086:24)                        ; FC5EC7  ld BC,(0x00e086)
	extz	xbc                                   ; FC5ECC  extz XBC
	ld	(xbc+22), wa                            ; FC5ECE  ld (XBC+0x16),WA
	ld	bc, (0xE084:24)                        ; FC5ED1  ld BC,(0x00e084)
	extz	xbc                                   ; FC5ED6  extz XBC
	ld	wa, (xbc+34)                            ; FC5ED8  ld WA,(XBC+0x22)
	ld	bc, (0xE086:24)                        ; FC5EDB  ld BC,(0x00e086)
	extz	xbc                                   ; FC5EE0  extz XBC
	ld	(xbc+24), wa                            ; FC5EE2  ld (XBC+0x18),WA
	ld	xbc, (xiz+10)                           ; FC5EE5  ld XBC,(XIZ+0x0a)
	push	xbc                                   ; FC5EE8  push XBC
	calr (0xFC49AD - 0xFC5EEC)                 ; FC5EE9  calr 0xfc49ad
	pop	xiy                                    ; FC5EEC  pop XIY
	jr sub_FC5D5B__FC5EF3                      ; FC5EED  jr T,0xfc5ef3
sub_FC5D5B__FC5EEF:
	sub	a, a                                   ; FC5EEF  sub A,A
	jr sub_FC5D5B__FC5EF5                      ; FC5EF1  jr T,0xfc5ef5
sub_FC5D5B__FC5EF3:
	ld	a, d                                    ; FC5EF3  ld A,D
sub_FC5D5B__FC5EF5:
	pop	xix                                    ; FC5EF5  pop XIX
	popw	de                                    ; FC5EF6  pop DE
	popw	hl                                    ; FC5EF7  pop HL
	unlk32 xiz                                 ; FC5EF8  unlk XIZ
	ret                                        ; FC5EFA  ret
; --------------------------------------------------------------------------
; sub_FC5EFB -- 0xFC5EFB..0xFC6026 (300 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFAEBF1 in sub_FAEBD1, 0xFB65BB in sub_FB6500
; Inputs:  frame `link XIZ,-2`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: writes 0x00E082, 0x00E084
; Evidence: the listing below is the byte-identical round-trip of 0xFC5EFB-0xFC6026
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC5EFB:
	link32 0xEE, 0x0C, 0xFE, 0xFF              ; FC5EFB  link XIZ,0xfffe
	pushw	hl                                   ; FC5EFF  push HL
	pushw	de                                   ; FC5F00  push DE
	push	xix                                   ; FC5F01  push XIX
	ldb	c, 0xBB                                ; FC5F02  ld C,0xbb
	extpfx3 0x8E, 0x08, 0x43                   ; FC5F04  mul BC,(XIZ+0x08)
	ld	hl, bc                                  ; FC5F07  ld HL,BC
	ldw	wa, 0x5D23                             ; FC5F09  ld WA,0x5d23
	ld	ix, wa                                  ; FC5F0C  ld IX,WA
	add	ix, bc                                 ; FC5F0E  add IX,BC
	stw_da	(0xE082), ix                        ; FC5F10  ld (0x00e082),IX
	extz	xix                                   ; FC5F15  extz XIX
	ld	bc, (xiz+10)                            ; FC5F17  ld BC,(XIZ+0x0a)
	ld	(xix+7), bc                             ; FC5F1A  ld (XIX+0x07),BC
	ld	bc, (0xE082:24)                        ; FC5F1D  ld BC,(0x00e082)
	add	bc, 19                                 ; FC5F22  add BC,0x0013
	stw_da	(0xE084), bc                        ; FC5F26  ld (0x00e084),BC
	ld	e, (xiz+12)                             ; FC5F2B  ld E,(XIZ+0x0c)
	ldb	d, 4                                   ; FC5F2E  ld D,0x04
sub_FC5EFB__FC5F30:
	ld	bc, (0xE084:24)                        ; FC5F30  ld BC,(0x00e084)
	extz	xbc                                   ; FC5F35  extz XBC
	extpfx3 0xB9, 0x01, 0xB4                   ; FC5F37  res 4,(XBC+0x01)
	extpfx3 0xB9, 0x01, 0xB5                   ; FC5F3A  res 5,(XBC+0x01)
	extpfx2 0xB1, 0xCF                         ; FC5F3D  bit 7,(XBC)
	jrl z, sub_FC5EFB__FC600C                  ; FC5F3F  jrl Z,0xfc600c
	ld	a, e                                    ; FC5F42  ld A,E
	and	a, 1                                   ; FC5F44  and A,0x01
	jr z, sub_FC5EFB__FC5F65                   ; FC5F47  jr Z,0xfc5f65
	ld	a, e                                    ; FC5F49  ld A,E
	and	a, 2                                   ; FC5F4B  and A,0x02
	jr z, sub_FC5EFB__FC5F58                   ; FC5F4E  jr Z,0xfc5f58
	extpfx3 0xB9, 0x01, 0xB4                   ; FC5F50  res 4,(XBC+0x01)
	extpfx3 0xB9, 0x01, 0xBD                   ; FC5F53  set 5,(XBC+0x01)
	jr sub_FC5EFB__FC5F65                      ; FC5F56  jr T,0xfc5f65
sub_FC5EFB__FC5F58:
	ld	bc, (0xE084:24)                        ; FC5F58  ld BC,(0x00e084)
	extz	xbc                                   ; FC5F5D  extz XBC
	extpfx3 0xB9, 0x01, 0xBC                   ; FC5F5F  set 4,(XBC+0x01)
	extpfx3 0xB9, 0x01, 0xB5                   ; FC5F62  res 5,(XBC+0x01)
sub_FC5EFB__FC5F65:
	ld	bc, (0xE082:24)                        ; FC5F65  ld BC,(0x00e082)
	extz	xbc                                   ; FC5F6A  extz XBC
	ld	a, (xbc)                                ; FC5F6C  ld A,(XBC)
	cps	a, 0                                   ; FC5F6E  cp A,0
	jrl nz, sub_FC5EFB__FC600C                 ; FC5F70  jrl NZ,0xfc600c
	ld	wa, (0xE084:24)                        ; FC5F73  ld WA,(0x00e084)
	extz	xwa                                   ; FC5F78  extz XWA
	ld	xiy, (xwa+3)                            ; FC5F7A  ld XIY,(XWA+0x03)
	ld	xix, xiy                                ; FC5F7D  ld XIX,XIY
	ld	c, (xwa+1)                              ; FC5F7F  ld C,(XWA+0x01)
	and	c, 48                                  ; FC5F82  and C,0x30
	srl	c, 4                                   ; FC5F85  srl 0x04,C
	extz	bc                                    ; FC5F88  extz BC
	cps	bc, 1                                  ; FC5F8A  cp BC,1
	jr z, sub_FC5EFB__FC5F95                   ; FC5F8C  jr Z,0xfc5f95
	cps	bc, 2                                  ; FC5F8E  cp BC,2
	jr z, sub_FC5EFB__FC5FB7                   ; FC5F90  jr Z,0xfc5fb7
	jrl sub_FC5EFB__FC5FF3                     ; FC5F92  jrl T,0xfc5ff3
sub_FC5EFB__FC5F95:
	ld	c, (xix+17)                             ; FC5F95  ld C,(XIX+0x11)
	extz	bc                                    ; FC5F98  extz BC
	ld	(xiz-2), bc                             ; FC5F9A  ld (XIZ+0xfe),BC
	ld	wa, (0xE082:24)                        ; FC5F9D  ld WA,(0x00e082)
	extz	xwa                                   ; FC5FA2  extz XWA
	ld	iy, (xwa+7)                             ; FC5FA4  ld IY,(XWA+0x07)
	ld	hl, bc                                  ; FC5FA7  ld HL,BC
	add	hl, iy                                 ; FC5FA9  add HL,IY
	cp	hl, 50                                  ; FC5FAB  cp HL,0x0032
	jr gt, sub_FC5EFB__FC5FD3                  ; FC5FAF  jr GT,0xfc5fd3
	cps	hl, 0                                  ; FC5FB1  cp HL,0
	jr ge, sub_FC5EFB__FC5FDF                  ; FC5FB3  jr GE,0xfc5fdf
	jr sub_FC5EFB__FC5FDC                      ; FC5FB5  jr T,0xfc5fdc
sub_FC5EFB__FC5FB7:
	ld	c, (xix+17)                             ; FC5FB7  ld C,(XIX+0x11)
	extz	bc                                    ; FC5FBA  extz BC
	ld	(xiz-2), bc                             ; FC5FBC  ld (XIZ+0xfe),BC
	ld	wa, (0xE082:24)                        ; FC5FBF  ld WA,(0x00e082)
	extz	xwa                                   ; FC5FC4  extz XWA
	ld	iy, (xwa+7)                             ; FC5FC6  ld IY,(XWA+0x07)
	ld	hl, bc                                  ; FC5FC9  ld HL,BC
	sub	hl, iy                                 ; FC5FCB  sub HL,IY
	cp	hl, 50                                  ; FC5FCD  cp HL,0x0032
	jr le, sub_FC5EFB__FC5FD8                  ; FC5FD1  jr LE,0xfc5fd8
sub_FC5EFB__FC5FD3:
	ldw	hl, 50                                 ; FC5FD3  ld HL,0x0032
	jr sub_FC5EFB__FC5FDF                      ; FC5FD6  jr T,0xfc5fdf
sub_FC5EFB__FC5FD8:
	cps	hl, 0                                  ; FC5FD8  cp HL,0
	jr ge, sub_FC5EFB__FC5FDF                  ; FC5FDA  jr GE,0xfc5fdf
sub_FC5EFB__FC5FDC:
	ldw	hl, 0                                  ; FC5FDC  ld HL,0x0000
sub_FC5EFB__FC5FDF:
	ld	c, l                                    ; FC5FDF  ld C,L
	ld	(xiz-2), c                              ; FC5FE1  ld (XIZ+0xfe),C
	ld	bc, (0xE084:24)                        ; FC5FE4  ld BC,(0x00e084)
	extz	xbc                                   ; FC5FE9  extz XBC
	ld	a, (xiz-2)                              ; FC5FEB  ld A,(XIZ+0xfe)
	ld	(xbc+40), a                             ; FC5FEE  ld (XBC+0x28),A
	jr sub_FC5EFB__FC5FFA                      ; FC5FF1  jr T,0xfc5ffa
sub_FC5EFB__FC5FF3:
	ld	c, (xix+17)                             ; FC5FF3  ld C,(XIX+0x11)
	extz	bc                                    ; FC5FF6  extz BC
	ld	hl, bc                                  ; FC5FF8  ld HL,BC
sub_FC5EFB__FC5FFA:
	ld	c, l                                    ; FC5FFA  ld C,L
	ld	(xiz-2), c                              ; FC5FFC  ld (XIZ+0xfe),C
	ld	bc, (0xE084:24)                        ; FC5FFF  ld BC,(0x00e084)
	extz	xbc                                   ; FC6004  extz XBC
	ld	a, (xiz-2)                              ; FC6006  ld A,(XIZ+0xfe)
	ld	(xbc+40), a                             ; FC6009  ld (XBC+0x28),A
sub_FC5EFB__FC600C:
	dec	1, d                                   ; FC600C  dec 1,D
	extpfx7 0xD2, 0x84, 0xE0, 0x00, 0x38, 0x2A, 0x00 ; FC600E  add (0x00e084),0x002a
	ld	c, e                                    ; FC6015  ld C,E
	srl	c, 2                                   ; FC6017  srl 0x02,C
	ld	e, c                                    ; FC601A  ld E,C
	cps	d, 0                                   ; FC601C  cp D,0
	jrl nz, sub_FC5EFB__FC5F30                 ; FC601E  jrl NZ,0xfc5f30
	pop	xix                                    ; FC6021  pop XIX
	popw	de                                    ; FC6022  pop DE
	popw	hl                                    ; FC6023  pop HL
	unlk32 xiz                                 ; FC6024  unlk XIZ
	ret                                        ; FC6026  ret
; --------------------------------------------------------------------------
; sub_FC6027 -- 0xFC6027..0xFC6174 (334 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFAEC13 in sub_FAEBD1__FAEC08
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x00E084, 0x00E086
;          reads 0x00E082
; Evidence: the listing below is the byte-identical round-trip of 0xFC6027-0xFC6174
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC6027:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC6027  link XIZ,0x0000
	pushw	hl                                   ; FC602B  push HL
	pushw	de                                   ; FC602C  push DE
	push	xix                                   ; FC602D  push XIX
	ldb	c, 37                                  ; FC602E  ld C,0x25
	extpfx3 0x8E, 0x08, 0x43                   ; FC6030  mul BC,(XIZ+0x08)
	ld	hl, bc                                  ; FC6033  ld HL,BC
	ldw	wa, 0x753E                             ; FC6035  ld WA,0x753e
	add	wa, bc                                 ; FC6038  add WA,BC
	stw_da	(0xE086), wa                        ; FC603A  ld (0x00e086),WA
	extz	xwa                                   ; FC603F  extz XWA
	ld	bc, (xwa+5)                             ; FC6041  ld BC,(XWA+0x05)
	stw_da	(0xE084), bc                        ; FC6044  ld (0x00e084),BC
	sub	iy, iy                                 ; FC6049  sub IY,IY
	cp	bc, iy                                  ; FC604B  cp BC,IY
	jrl z, sub_FC6027__FC616F                  ; FC604D  jrl Z,0xfc616f
	ld	c, (xwa)                                ; FC6050  ld C,(XWA)
	cps	c, 0                                   ; FC6052  cp C,0
	jrl z, sub_FC6027__FC60E5                  ; FC6054  jrl Z,0xfc60e5
	ld	xbc, (xwa+1)                            ; FC6057  ld XBC,(XWA+0x01)
	ld	xix, xbc                                ; FC605A  ld XIX,XBC
	ld	iy, (0xE084:24)                        ; FC605C  ld IY,(0x00e084)
	extz	xiy                                   ; FC6061  extz XIY
	ld	c, (xiy+1)                              ; FC6063  ld C,(XIY+0x01)
	and	c, 48                                  ; FC6066  and C,0x30
	srl	c, 4                                   ; FC6069  srl 0x04,C
	extz	bc                                    ; FC606C  extz BC
	cps	bc, 1                                  ; FC606E  cp BC,1
	jr z, sub_FC6027__FC6078                   ; FC6070  jr Z,0xfc6078
	cps	bc, 2                                  ; FC6072  cp BC,2
	jr z, sub_FC6027__FC6099                   ; FC6074  jr Z,0xfc6099
	jr sub_FC6027__FC60D0                      ; FC6076  jr T,0xfc60d0
sub_FC6027__FC6078:
	ld	c, (xix+17)                             ; FC6078  ld C,(XIX+0x11)
	extz	bc                                    ; FC607B  extz BC
	ld	de, bc                                  ; FC607D  ld DE,BC
	ld	wa, (0xE082:24)                        ; FC607F  ld WA,(0x00e082)
	extz	xwa                                   ; FC6084  extz XWA
	ld	iy, (xwa+7)                             ; FC6086  ld IY,(XWA+0x07)
	ld	hl, bc                                  ; FC6089  ld HL,BC
	add	hl, iy                                 ; FC608B  add HL,IY
	cp	hl, 50                                  ; FC608D  cp HL,0x0032
	jr gt, sub_FC6027__FC60B4                  ; FC6091  jr GT,0xfc60b4
	cps	hl, 0                                  ; FC6093  cp HL,0
	jr ge, sub_FC6027__FC60C0                  ; FC6095  jr GE,0xfc60c0
	jr sub_FC6027__FC60BD                      ; FC6097  jr T,0xfc60bd
sub_FC6027__FC6099:
	ld	c, (xix+17)                             ; FC6099  ld C,(XIX+0x11)
	extz	bc                                    ; FC609C  extz BC
	ld	de, bc                                  ; FC609E  ld DE,BC
	ld	wa, (0xE082:24)                        ; FC60A0  ld WA,(0x00e082)
	extz	xwa                                   ; FC60A5  extz XWA
	ld	iy, (xwa+7)                             ; FC60A7  ld IY,(XWA+0x07)
	ld	hl, bc                                  ; FC60AA  ld HL,BC
	sub	hl, iy                                 ; FC60AC  sub HL,IY
	cp	hl, 50                                  ; FC60AE  cp HL,0x0032
	jr le, sub_FC6027__FC60B9                  ; FC60B2  jr LE,0xfc60b9
sub_FC6027__FC60B4:
	ldw	hl, 50                                 ; FC60B4  ld HL,0x0032
	jr sub_FC6027__FC60C0                      ; FC60B7  jr T,0xfc60c0
sub_FC6027__FC60B9:
	cps	hl, 0                                  ; FC60B9  cp HL,0
	jr ge, sub_FC6027__FC60C0                  ; FC60BB  jr GE,0xfc60c0
sub_FC6027__FC60BD:
	ldw	hl, 0                                  ; FC60BD  ld HL,0x0000
sub_FC6027__FC60C0:
	ld	c, l                                    ; FC60C0  ld C,L
	ld	d, c                                    ; FC60C2  ld D,C
	ld	bc, (0xE084:24)                        ; FC60C4  ld BC,(0x00e084)
	extz	xbc                                   ; FC60C9  extz XBC
	ld	(xbc+40), d                             ; FC60CB  ld (XBC+0x28),D
	jr sub_FC6027__FC60D7                      ; FC60CE  jr T,0xfc60d7
sub_FC6027__FC60D0:
	ld	c, (xix+17)                             ; FC60D0  ld C,(XIX+0x11)
	extz	bc                                    ; FC60D3  extz BC
	ld	hl, bc                                  ; FC60D5  ld HL,BC
sub_FC6027__FC60D7:
	ld	c, l                                    ; FC60D7  ld C,L
	ld	d, c                                    ; FC60D9  ld D,C
	ld	bc, (0xE084:24)                        ; FC60DB  ld BC,(0x00e084)
	extz	xbc                                   ; FC60E0  extz XBC
	ld	(xbc+40), d                             ; FC60E2  ld (XBC+0x28),D
sub_FC6027__FC60E5:
	ld	bc, (0xE084:24)                        ; FC60E5  ld BC,(0x00e084)
	extz	xbc                                   ; FC60EA  extz XBC
	ld	a, (xbc+40)                             ; FC60EC  ld A,(XBC+0x28)
	ld	h, a                                    ; FC60EF  ld H,A
	ld	wa, (0xE086:24)                        ; FC60F1  ld WA,(0x00e086)
	extz	xwa                                   ; FC60F6  extz XWA
	ld	(xwa+29), h                             ; FC60F8  ld (XWA+0x1d),H
	ld	bc, (0xE086:24)                        ; FC60FB  ld BC,(0x00e086)
	extz	xbc                                   ; FC6100  extz XBC
	ld	xwa, (xbc+1)                            ; FC6102  ld XWA,(XBC+0x01)
	ld	c, (xwa+18)                             ; FC6105  ld C,(XWA+0x12)
	and	c, 0x80                                ; FC6108  and C,0x80
	jr z, sub_FC6027__FC6121                   ; FC610B  jr Z,0xfc6121
	ld	bc, (0xE086:24)                        ; FC610D  ld BC,(0x00e086)
	extz	xbc                                   ; FC6112  extz XBC
	ld	a, (xbc+29)                             ; FC6114  ld A,(XBC+0x1d)
	cps	a, 0                                   ; FC6117  cp A,0
	jr z, sub_FC6027__FC6164                   ; FC6119  jr Z,0xfc6164
	ld	(xbc+28), 2                             ; FC611B  ld (XBC+0x1c),0x02
	jr sub_FC6027__FC616F                      ; FC611F  jr T,0xfc616f
sub_FC6027__FC6121:
	ld	bc, (0xE086:24)                        ; FC6121  ld BC,(0x00e086)
	extz	xbc                                   ; FC6126  extz XBC
	ld	a, (xbc+30)                             ; FC6128  ld A,(XBC+0x1e)
	cps	a, 0                                   ; FC612B  cp A,0
	jr z, sub_FC6027__FC6150                   ; FC612D  jr Z,0xfc6150
	ld	a, (xbc+29)                             ; FC612F  ld A,(XBC+0x1d)
	cps	a, 0                                   ; FC6132  cp A,0
	jr z, sub_FC6027__FC6150                   ; FC6134  jr Z,0xfc6150
	ld	a, (xbc+28)                             ; FC6136  ld A,(XBC+0x1c)
	cps	a, 1                                   ; FC6139  cp A,1
	jr z, sub_FC6027__FC6143                   ; FC613B  jr Z,0xfc6143
	ld	(xbc+28), 4                             ; FC613D  ld (XBC+0x1c),0x04
	jr sub_FC6027__FC616F                      ; FC6141  jr T,0xfc616f
sub_FC6027__FC6143:
	ld	bc, (0xE086:24)                        ; FC6143  ld BC,(0x00e086)
	extz	xbc                                   ; FC6148  extz XBC
	ld	(xbc+28), 1                             ; FC614A  ld (XBC+0x1c),0x01
	jr sub_FC6027__FC616F                      ; FC614E  jr T,0xfc616f
sub_FC6027__FC6150:
	ld	bc, (0xE086:24)                        ; FC6150  ld BC,(0x00e086)
	extz	xbc                                   ; FC6155  extz XBC
	ld	a, (xbc+28)                             ; FC6157  ld A,(XBC+0x1c)
	cps	a, 0                                   ; FC615A  cp A,0
	jr z, sub_FC6027__FC6164                   ; FC615C  jr Z,0xfc6164
	ld	(xbc+28), 3                             ; FC615E  ld (XBC+0x1c),0x03
	jr sub_FC6027__FC616F                      ; FC6162  jr T,0xfc616f
sub_FC6027__FC6164:
	ld	bc, (0xE086:24)                        ; FC6164  ld BC,(0x00e086)
	extz	xbc                                   ; FC6169  extz XBC
	ld	(xbc+28), 0                             ; FC616B  ld (XBC+0x1c),0x00
sub_FC6027__FC616F:
	pop	xix                                    ; FC616F  pop XIX
	popw	de                                    ; FC6170  pop DE
	popw	hl                                    ; FC6171  pop HL
	unlk32 xiz                                 ; FC6172  unlk XIZ
	ret                                        ; FC6174  ret
; --------------------------------------------------------------------------
; sub_FC6175 -- 0xFC6175..0xFC629A (294 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFAEC41 in sub_FAEC21, 0xFB65C9 in sub_FB6500
; Inputs:  frame `link XIZ,-2`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: writes 0x00E082, 0x00E084
; Evidence: the listing below is the byte-identical round-trip of 0xFC6175-0xFC629A
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC6175:
	link32 0xEE, 0x0C, 0xFE, 0xFF              ; FC6175  link XIZ,0xfffe
	pushw	hl                                   ; FC6179  push HL
	pushw	de                                   ; FC617A  push DE
	push	xix                                   ; FC617B  push XIX
	ldb	c, 0xBB                                ; FC617C  ld C,0xbb
	extpfx3 0x8E, 0x08, 0x43                   ; FC617E  mul BC,(XIZ+0x08)
	ld	hl, bc                                  ; FC6181  ld HL,BC
	ldw	wa, 0x5D23                             ; FC6183  ld WA,0x5d23
	ld	ix, wa                                  ; FC6186  ld IX,WA
	add	ix, bc                                 ; FC6188  add IX,BC
	stw_da	(0xE082), ix                        ; FC618A  ld (0x00e082),IX
	extz	xix                                   ; FC618F  extz XIX
	ld	bc, (xiz+10)                            ; FC6191  ld BC,(XIZ+0x0a)
	ld	(xix+9), bc                             ; FC6194  ld (XIX+0x09),BC
	ld	bc, (0xE082:24)                        ; FC6197  ld BC,(0x00e082)
	add	bc, 19                                 ; FC619C  add BC,0x0013
	stw_da	(0xE084), bc                        ; FC61A0  ld (0x00e084),BC
	ld	e, (xiz+12)                             ; FC61A5  ld E,(XIZ+0x0c)
	ldb	d, 4                                   ; FC61A8  ld D,0x04
sub_FC6175__FC61AA:
	ld	bc, (0xE084:24)                        ; FC61AA  ld BC,(0x00e084)
	extz	xbc                                   ; FC61AF  extz XBC
	extpfx3 0xB9, 0x01, 0xB2                   ; FC61B1  res 2,(XBC+0x01)
	extpfx3 0xB9, 0x01, 0xB3                   ; FC61B4  res 3,(XBC+0x01)
	extpfx2 0xB1, 0xCF                         ; FC61B7  bit 7,(XBC)
	jrl z, sub_FC6175__FC6280                  ; FC61B9  jrl Z,0xfc6280
	ld	a, e                                    ; FC61BC  ld A,E
	and	a, 1                                   ; FC61BE  and A,0x01
	jr z, sub_FC6175__FC61DF                   ; FC61C1  jr Z,0xfc61df
	ld	a, e                                    ; FC61C3  ld A,E
	and	a, 2                                   ; FC61C5  and A,0x02
	jr z, sub_FC6175__FC61D2                   ; FC61C8  jr Z,0xfc61d2
	extpfx3 0xB9, 0x01, 0xB2                   ; FC61CA  res 2,(XBC+0x01)
	extpfx3 0xB9, 0x01, 0xBB                   ; FC61CD  set 3,(XBC+0x01)
	jr sub_FC6175__FC61DF                      ; FC61D0  jr T,0xfc61df
sub_FC6175__FC61D2:
	ld	bc, (0xE084:24)                        ; FC61D2  ld BC,(0x00e084)
	extz	xbc                                   ; FC61D7  extz XBC
	extpfx3 0xB9, 0x01, 0xBA                   ; FC61D9  set 2,(XBC+0x01)
	extpfx3 0xB9, 0x01, 0xB3                   ; FC61DC  res 3,(XBC+0x01)
sub_FC6175__FC61DF:
	ld	bc, (0xE082:24)                        ; FC61DF  ld BC,(0x00e082)
	extz	xbc                                   ; FC61E4  extz XBC
	ld	a, (xbc)                                ; FC61E6  ld A,(XBC)
	cps	a, 0                                   ; FC61E8  cp A,0
	jrl nz, sub_FC6175__FC6280                 ; FC61EA  jrl NZ,0xfc6280
	ld	wa, (0xE084:24)                        ; FC61ED  ld WA,(0x00e084)
	extz	xwa                                   ; FC61F2  extz XWA
	ld	xiy, (xwa+3)                            ; FC61F4  ld XIY,(XWA+0x03)
	ld	xix, xiy                                ; FC61F7  ld XIX,XIY
	ld	c, (xwa+1)                              ; FC61F9  ld C,(XWA+0x01)
	and	c, 12                                  ; FC61FC  and C,0x0c
	srl	c, 2                                   ; FC61FF  srl 0x02,C
	extz	bc                                    ; FC6202  extz BC
	cps	bc, 1                                  ; FC6204  cp BC,1
	jr z, sub_FC6175__FC620E                   ; FC6206  jr Z,0xfc620e
	cps	bc, 2                                  ; FC6208  cp BC,2
	jr z, sub_FC6175__FC6233                   ; FC620A  jr Z,0xfc6233
	jr sub_FC6175__FC6260                      ; FC620C  jr T,0xfc6260
sub_FC6175__FC620E:
	ld	c, (xix+18)                             ; FC620E  ld C,(XIX+0x12)
	res	7, c                                   ; FC6211  res 0x07,C
	extz	bc                                    ; FC6214  extz BC
	ld	(xiz-2), bc                             ; FC6216  ld (XIZ+0xfe),BC
	ld	wa, (0xE082:24)                        ; FC6219  ld WA,(0x00e082)
	extz	xwa                                   ; FC621E  extz XWA
	ld	iy, (xwa+9)                             ; FC6220  ld IY,(XWA+0x09)
	ld	hl, bc                                  ; FC6223  ld HL,BC
	add	hl, iy                                 ; FC6225  add HL,IY
	cp	hl, 50                                  ; FC6227  cp HL,0x0032
	jr gt, sub_FC6175__FC6252                  ; FC622B  jr GT,0xfc6252
	cps	hl, 0                                  ; FC622D  cp HL,0
	jr ge, sub_FC6175__FC626A                  ; FC622F  jr GE,0xfc626a
	jr sub_FC6175__FC625B                      ; FC6231  jr T,0xfc625b
sub_FC6175__FC6233:
	ld	c, (xix+18)                             ; FC6233  ld C,(XIX+0x12)
	res	7, c                                   ; FC6236  res 0x07,C
	extz	bc                                    ; FC6239  extz BC
	ld	(xiz-2), bc                             ; FC623B  ld (XIZ+0xfe),BC
	ld	wa, (0xE082:24)                        ; FC623E  ld WA,(0x00e082)
	extz	xwa                                   ; FC6243  extz XWA
	ld	iy, (xwa+9)                             ; FC6245  ld IY,(XWA+0x09)
	ld	hl, bc                                  ; FC6248  ld HL,BC
	add	hl, iy                                 ; FC624A  add HL,IY
	cp	hl, 50                                  ; FC624C  cp HL,0x0032
	jr le, sub_FC6175__FC6257                  ; FC6250  jr LE,0xfc6257
sub_FC6175__FC6252:
	ldw	hl, 50                                 ; FC6252  ld HL,0x0032
	jr sub_FC6175__FC626A                      ; FC6255  jr T,0xfc626a
sub_FC6175__FC6257:
	cps	hl, 0                                  ; FC6257  cp HL,0
	jr ge, sub_FC6175__FC626A                  ; FC6259  jr GE,0xfc626a
sub_FC6175__FC625B:
	ldw	hl, 0                                  ; FC625B  ld HL,0x0000
	jr sub_FC6175__FC626A                      ; FC625E  jr T,0xfc626a
sub_FC6175__FC6260:
	ld	c, (xix+18)                             ; FC6260  ld C,(XIX+0x12)
	res	7, c                                   ; FC6263  res 0x07,C
	extz	bc                                    ; FC6266  extz BC
	ld	hl, bc                                  ; FC6268  ld HL,BC
sub_FC6175__FC626A:
	ld	bc, hl                                  ; FC626A  ld BC,HL
	exts	xbc                                   ; FC626C  exts XBC
	add	xbc, 0xFE0296                          ; FC626E  add XBC,0x00fe0296
	ld	a, (xbc)                                ; FC6274  ld A,(XBC)
	ld	bc, (0xE084:24)                        ; FC6276  ld BC,(0x00e084)
	extz	xbc                                   ; FC627B  extz XBC
	ld	(xbc+41), a                             ; FC627D  ld (XBC+0x29),A
sub_FC6175__FC6280:
	dec	1, d                                   ; FC6280  dec 1,D
	extpfx7 0xD2, 0x84, 0xE0, 0x00, 0x38, 0x2A, 0x00 ; FC6282  add (0x00e084),0x002a
	ld	c, e                                    ; FC6289  ld C,E
	srl	c, 2                                   ; FC628B  srl 0x02,C
	ld	e, c                                    ; FC628E  ld E,C
	cps	d, 0                                   ; FC6290  cp D,0
	jrl nz, sub_FC6175__FC61AA                 ; FC6292  jrl NZ,0xfc61aa
	pop	xix                                    ; FC6295  pop XIX
	popw	de                                    ; FC6296  pop DE
	popw	hl                                    ; FC6297  pop HL
	unlk32 xiz                                 ; FC6298  unlk XIZ
	ret                                        ; FC629A  ret
; --------------------------------------------------------------------------
; sub_FC629B -- 0xFC629B..0xFC63EB (337 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFAEC63 in sub_FAEC21__FAEC58
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x00E084, 0x00E086
;          reads 0x00E082
; Evidence: the listing below is the byte-identical round-trip of 0xFC629B-0xFC63EB
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC629B:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC629B  link XIZ,0x0000
	pushw	hl                                   ; FC629F  push HL
	pushw	de                                   ; FC62A0  push DE
	push	xix                                   ; FC62A1  push XIX
	ldb	c, 37                                  ; FC62A2  ld C,0x25
	extpfx3 0x8E, 0x08, 0x43                   ; FC62A4  mul BC,(XIZ+0x08)
	ld	hl, bc                                  ; FC62A7  ld HL,BC
	ldw	wa, 0x753E                             ; FC62A9  ld WA,0x753e
	add	wa, bc                                 ; FC62AC  add WA,BC
	stw_da	(0xE086), wa                        ; FC62AE  ld (0x00e086),WA
	extz	xwa                                   ; FC62B3  extz XWA
	ld	bc, (xwa+5)                             ; FC62B5  ld BC,(XWA+0x05)
	stw_da	(0xE084), bc                        ; FC62B8  ld (0x00e084),BC
	sub	iy, iy                                 ; FC62BD  sub IY,IY
	cp	bc, iy                                  ; FC62BF  cp BC,IY
	jrl z, sub_FC629B__FC63E6                  ; FC62C1  jrl Z,0xfc63e6
	ld	c, (xwa)                                ; FC62C4  ld C,(XWA)
	cps	c, 0                                   ; FC62C6  cp C,0
	jrl z, sub_FC629B__FC635C                  ; FC62C8  jrl Z,0xfc635c
	ld	xbc, (xwa+1)                            ; FC62CB  ld XBC,(XWA+0x01)
	ld	xix, xbc                                ; FC62CE  ld XIX,XBC
	ld	iy, (0xE084:24)                        ; FC62D0  ld IY,(0x00e084)
	extz	xiy                                   ; FC62D5  extz XIY
	ld	c, (xiy+1)                              ; FC62D7  ld C,(XIY+0x01)
	and	c, 12                                  ; FC62DA  and C,0x0c
	srl	c, 2                                   ; FC62DD  srl 0x02,C
	extz	bc                                    ; FC62E0  extz BC
	cps	bc, 1                                  ; FC62E2  cp BC,1
	jr z, sub_FC629B__FC62EC                   ; FC62E4  jr Z,0xfc62ec
	cps	bc, 2                                  ; FC62E6  cp BC,2
	jr z, sub_FC629B__FC6310                   ; FC62E8  jr Z,0xfc6310
	jr sub_FC629B__FC633C                      ; FC62EA  jr T,0xfc633c
sub_FC629B__FC62EC:
	ld	c, (xix+18)                             ; FC62EC  ld C,(XIX+0x12)
	res	7, c                                   ; FC62EF  res 0x07,C
	extz	bc                                    ; FC62F2  extz BC
	ld	de, bc                                  ; FC62F4  ld DE,BC
	ld	wa, (0xE082:24)                        ; FC62F6  ld WA,(0x00e082)
	extz	xwa                                   ; FC62FB  extz XWA
	ld	iy, (xwa+9)                             ; FC62FD  ld IY,(XWA+0x09)
	ld	hl, bc                                  ; FC6300  ld HL,BC
	add	hl, iy                                 ; FC6302  add HL,IY
	cp	hl, 50                                  ; FC6304  cp HL,0x0032
	jr gt, sub_FC629B__FC632E                  ; FC6308  jr GT,0xfc632e
	cps	hl, 0                                  ; FC630A  cp HL,0
	jr ge, sub_FC629B__FC6346                  ; FC630C  jr GE,0xfc6346
	jr sub_FC629B__FC6337                      ; FC630E  jr T,0xfc6337
sub_FC629B__FC6310:
	ld	c, (xix+18)                             ; FC6310  ld C,(XIX+0x12)
	res	7, c                                   ; FC6313  res 0x07,C
	extz	bc                                    ; FC6316  extz BC
	ld	de, bc                                  ; FC6318  ld DE,BC
	ld	wa, (0xE082:24)                        ; FC631A  ld WA,(0x00e082)
	extz	xwa                                   ; FC631F  extz XWA
	ld	iy, (xwa+9)                             ; FC6321  ld IY,(XWA+0x09)
	ld	hl, bc                                  ; FC6324  ld HL,BC
	add	hl, iy                                 ; FC6326  add HL,IY
	cp	hl, 50                                  ; FC6328  cp HL,0x0032
	jr le, sub_FC629B__FC6333                  ; FC632C  jr LE,0xfc6333
sub_FC629B__FC632E:
	ldw	hl, 50                                 ; FC632E  ld HL,0x0032
	jr sub_FC629B__FC6346                      ; FC6331  jr T,0xfc6346
sub_FC629B__FC6333:
	cps	hl, 0                                  ; FC6333  cp HL,0
	jr ge, sub_FC629B__FC6346                  ; FC6335  jr GE,0xfc6346
sub_FC629B__FC6337:
	ldw	hl, 0                                  ; FC6337  ld HL,0x0000
	jr sub_FC629B__FC6346                      ; FC633A  jr T,0xfc6346
sub_FC629B__FC633C:
	ld	c, (xix+18)                             ; FC633C  ld C,(XIX+0x12)
	res	7, c                                   ; FC633F  res 0x07,C
	extz	bc                                    ; FC6342  extz BC
	ld	hl, bc                                  ; FC6344  ld HL,BC
sub_FC629B__FC6346:
	ld	bc, hl                                  ; FC6346  ld BC,HL
	exts	xbc                                   ; FC6348  exts XBC
	add	xbc, 0xFE0296                          ; FC634A  add XBC,0x00fe0296
	ld	a, (xbc)                                ; FC6350  ld A,(XBC)
	ld	bc, (0xE084:24)                        ; FC6352  ld BC,(0x00e084)
	extz	xbc                                   ; FC6357  extz XBC
	ld	(xbc+41), a                             ; FC6359  ld (XBC+0x29),A
sub_FC629B__FC635C:
	ld	bc, (0xE084:24)                        ; FC635C  ld BC,(0x00e084)
	extz	xbc                                   ; FC6361  extz XBC
	ld	a, (xbc+41)                             ; FC6363  ld A,(XBC+0x29)
	ld	h, a                                    ; FC6366  ld H,A
	ld	wa, (0xE086:24)                        ; FC6368  ld WA,(0x00e086)
	extz	xwa                                   ; FC636D  extz XWA
	ld	(xwa+30), h                             ; FC636F  ld (XWA+0x1e),H
	ld	bc, (0xE086:24)                        ; FC6372  ld BC,(0x00e086)
	extz	xbc                                   ; FC6377  extz XBC
	ld	xwa, (xbc+1)                            ; FC6379  ld XWA,(XBC+0x01)
	ld	c, (xwa+18)                             ; FC637C  ld C,(XWA+0x12)
	and	c, 0x80                                ; FC637F  and C,0x80
	jr z, sub_FC629B__FC6398                   ; FC6382  jr Z,0xfc6398
	ld	bc, (0xE086:24)                        ; FC6384  ld BC,(0x00e086)
	extz	xbc                                   ; FC6389  extz XBC
	ld	a, (xbc+29)                             ; FC638B  ld A,(XBC+0x1d)
	cps	a, 0                                   ; FC638E  cp A,0
	jr z, sub_FC629B__FC63DB                   ; FC6390  jr Z,0xfc63db
	ld	(xbc+28), 2                             ; FC6392  ld (XBC+0x1c),0x02
	jr sub_FC629B__FC63E6                      ; FC6396  jr T,0xfc63e6
sub_FC629B__FC6398:
	ld	bc, (0xE086:24)                        ; FC6398  ld BC,(0x00e086)
	extz	xbc                                   ; FC639D  extz XBC
	ld	a, (xbc+30)                             ; FC639F  ld A,(XBC+0x1e)
	cps	a, 0                                   ; FC63A2  cp A,0
	jr z, sub_FC629B__FC63C7                   ; FC63A4  jr Z,0xfc63c7
	ld	a, (xbc+29)                             ; FC63A6  ld A,(XBC+0x1d)
	cps	a, 0                                   ; FC63A9  cp A,0
	jr z, sub_FC629B__FC63C7                   ; FC63AB  jr Z,0xfc63c7
	ld	a, (xbc+28)                             ; FC63AD  ld A,(XBC+0x1c)
	cps	a, 1                                   ; FC63B0  cp A,1
	jr z, sub_FC629B__FC63BA                   ; FC63B2  jr Z,0xfc63ba
	ld	(xbc+28), 4                             ; FC63B4  ld (XBC+0x1c),0x04
	jr sub_FC629B__FC63E6                      ; FC63B8  jr T,0xfc63e6
sub_FC629B__FC63BA:
	ld	bc, (0xE086:24)                        ; FC63BA  ld BC,(0x00e086)
	extz	xbc                                   ; FC63BF  extz XBC
	ld	(xbc+28), 1                             ; FC63C1  ld (XBC+0x1c),0x01
	jr sub_FC629B__FC63E6                      ; FC63C5  jr T,0xfc63e6
sub_FC629B__FC63C7:
	ld	bc, (0xE086:24)                        ; FC63C7  ld BC,(0x00e086)
	extz	xbc                                   ; FC63CC  extz XBC
	ld	a, (xbc+28)                             ; FC63CE  ld A,(XBC+0x1c)
	cps	a, 0                                   ; FC63D1  cp A,0
	jr z, sub_FC629B__FC63DB                   ; FC63D3  jr Z,0xfc63db
	ld	(xbc+28), 3                             ; FC63D5  ld (XBC+0x1c),0x03
	jr sub_FC629B__FC63E6                      ; FC63D9  jr T,0xfc63e6
sub_FC629B__FC63DB:
	ld	bc, (0xE086:24)                        ; FC63DB  ld BC,(0x00e086)
	extz	xbc                                   ; FC63E0  extz XBC
	ld	(xbc+28), 0                             ; FC63E2  ld (XBC+0x1c),0x00
sub_FC629B__FC63E6:
	pop	xix                                    ; FC63E6  pop XIX
	popw	de                                    ; FC63E7  pop DE
	popw	hl                                    ; FC63E8  pop HL
	unlk32 xiz                                 ; FC63E9  unlk XIZ
	ret                                        ; FC63EB  ret
; --------------------------------------------------------------------------
; sub_FC63EC -- 0xFC63EC..0xFC654E (355 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFAEC90 in sub_FAEC71, 0xFB65D7 in sub_FB6500
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: writes 0x00E082, 0x00E084
; Evidence: the listing below is the byte-identical round-trip of 0xFC63EC-0xFC654E
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC63EC:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC63EC  link XIZ,0x0000
	pushw	hl                                   ; FC63F0  push HL
	pushw	de                                   ; FC63F1  push DE
	push	xix                                   ; FC63F2  push XIX
	ldb	c, 0xBB                                ; FC63F3  ld C,0xbb
	extpfx3 0x8E, 0x08, 0x43                   ; FC63F5  mul BC,(XIZ+0x08)
	ld	de, bc                                  ; FC63F8  ld DE,BC
	ldw	wa, 0x5D23                             ; FC63FA  ld WA,0x5d23
	ld	ix, wa                                  ; FC63FD  ld IX,WA
	add	ix, bc                                 ; FC63FF  add IX,BC
	stw_da	(0xE082), ix                        ; FC6401  ld (0x00e082),IX
	extz	xix                                   ; FC6406  extz XIX
	ld	bc, (xiz+10)                            ; FC6408  ld BC,(XIZ+0x0a)
	ld	(xix+11), bc                            ; FC640B  ld (XIX+0x0b),BC
	ld	bc, (0xE082:24)                        ; FC640E  ld BC,(0x00e082)
	add	bc, 19                                 ; FC6413  add BC,0x0013
	stw_da	(0xE084), bc                        ; FC6417  ld (0x00e084),BC
	ld	l, (xiz+12)                             ; FC641C  ld L,(XIZ+0x0c)
	ldb	h, 4                                   ; FC641F  ld H,0x04
sub_FC63EC__FC6421:
	ld	bc, (0xE084:24)                        ; FC6421  ld BC,(0x00e084)
	extz	xbc                                   ; FC6426  extz XBC
	extpfx3 0xB9, 0x01, 0xB0                   ; FC6428  res 0,(XBC+0x01)
	extpfx3 0xB9, 0x01, 0xB1                   ; FC642B  res 1,(XBC+0x01)
	extpfx2 0xB1, 0xCF                         ; FC642E  bit 7,(XBC)
	jrl z, sub_FC63EC__FC6534                  ; FC6430  jrl Z,0xfc6534
	ld	a, l                                    ; FC6433  ld A,L
	and	a, 1                                   ; FC6435  and A,0x01
	jr z, sub_FC63EC__FC6456                   ; FC6438  jr Z,0xfc6456
	ld	a, l                                    ; FC643A  ld A,L
	and	a, 2                                   ; FC643C  and A,0x02
	jr z, sub_FC63EC__FC6449                   ; FC643F  jr Z,0xfc6449
	extpfx3 0xB9, 0x01, 0xB0                   ; FC6441  res 0,(XBC+0x01)
	extpfx3 0xB9, 0x01, 0xB9                   ; FC6444  set 1,(XBC+0x01)
	jr sub_FC63EC__FC6456                      ; FC6447  jr T,0xfc6456
sub_FC63EC__FC6449:
	ld	bc, (0xE084:24)                        ; FC6449  ld BC,(0x00e084)
	extz	xbc                                   ; FC644E  extz XBC
	extpfx3 0xB9, 0x01, 0xB8                   ; FC6450  set 0,(XBC+0x01)
	extpfx3 0xB9, 0x01, 0xB1                   ; FC6453  res 1,(XBC+0x01)
sub_FC63EC__FC6456:
	ld	bc, (0xE082:24)                        ; FC6456  ld BC,(0x00e082)
	extz	xbc                                   ; FC645B  extz XBC
	ld	a, (xbc)                                ; FC645D  ld A,(XBC)
	cps	a, 0                                   ; FC645F  cp A,0
	jrl nz, sub_FC63EC__FC6534                 ; FC6461  jrl NZ,0xfc6534
	ld	wa, (0xE084:24)                        ; FC6464  ld WA,(0x00e084)
	extz	xwa                                   ; FC6469  extz XWA
	ld	xiy, (xwa+3)                            ; FC646B  ld XIY,(XWA+0x03)
	ld	xix, xiy                                ; FC646E  ld XIX,XIY
	ld	c, (xwa+1)                              ; FC6470  ld C,(XWA+0x01)
	and	c, 3                                   ; FC6473  and C,0x03
	extz	bc                                    ; FC6476  extz BC
	cps	bc, 1                                  ; FC6478  cp BC,1
	jr z, sub_FC63EC__FC6483                   ; FC647A  jr Z,0xfc6483
	cps	bc, 2                                  ; FC647C  cp BC,2
	jr z, sub_FC63EC__FC64CA                   ; FC647E  jr Z,0xfc64ca
	jrl sub_FC63EC__FC6510                     ; FC6480  jrl T,0xfc6510
sub_FC63EC__FC6483:
	ld	c, (xix+22)                             ; FC6483  ld C,(XIX+0x16)
	res	7, c                                   ; FC6486  res 0x07,C
	extz	bc                                    ; FC6489  extz BC
	ld	de, bc                                  ; FC648B  ld DE,BC
	ld	wa, (0xE082:24)                        ; FC648D  ld WA,(0x00e082)
	extz	xwa                                   ; FC6492  extz XWA
	ld	iy, (xwa+11)                            ; FC6494  ld IY,(XWA+0x0b)
	add	bc, iy                                 ; FC6497  add BC,IY
	ld	de, bc                                  ; FC6499  ld DE,BC
	ld	bc, (0xE084:24)                        ; FC649B  ld BC,(0x00e084)
	extz	xbc                                   ; FC64A0  extz XBC
	ld	(xbc+26), de                            ; FC64A2  ld (XBC+0x1a),DE
	ld	c, (xix+32)                             ; FC64A5  ld C,(XIX+0x20)
	res	7, c                                   ; FC64A8  res 0x07,C
	extz	bc                                    ; FC64AB  extz BC
	ld	de, bc                                  ; FC64AD  ld DE,BC
	ld	wa, (0xE082:24)                        ; FC64AF  ld WA,(0x00e082)
	extz	xwa                                   ; FC64B4  extz XWA
	ld	iy, (xwa+11)                            ; FC64B6  ld IY,(XWA+0x0b)
	add	bc, iy                                 ; FC64B9  add BC,IY
	ld	de, bc                                  ; FC64BB  ld DE,BC
	ld	bc, (0xE084:24)                        ; FC64BD  ld BC,(0x00e084)
	extz	xbc                                   ; FC64C2  extz XBC
	ld	(xbc+28), de                            ; FC64C4  ld (XBC+0x1c),DE
	jrl sub_FC63EC__FC6534                     ; FC64C7  jrl T,0xfc6534
sub_FC63EC__FC64CA:
	ld	c, (xix+22)                             ; FC64CA  ld C,(XIX+0x16)
	res	7, c                                   ; FC64CD  res 0x07,C
	extz	bc                                    ; FC64D0  extz BC
	ld	de, bc                                  ; FC64D2  ld DE,BC
	ld	wa, (0xE082:24)                        ; FC64D4  ld WA,(0x00e082)
	extz	xwa                                   ; FC64D9  extz XWA
	ld	iy, (xwa+11)                            ; FC64DB  ld IY,(XWA+0x0b)
	sub	bc, iy                                 ; FC64DE  sub BC,IY
	ld	de, bc                                  ; FC64E0  ld DE,BC
	ld	bc, (0xE084:24)                        ; FC64E2  ld BC,(0x00e084)
	extz	xbc                                   ; FC64E7  extz XBC
	ld	(xbc+26), de                            ; FC64E9  ld (XBC+0x1a),DE
	ld	c, (xix+32)                             ; FC64EC  ld C,(XIX+0x20)
	res	7, c                                   ; FC64EF  res 0x07,C
	extz	bc                                    ; FC64F2  extz BC
	ld	de, bc                                  ; FC64F4  ld DE,BC
	ld	wa, (0xE082:24)                        ; FC64F6  ld WA,(0x00e082)
	extz	xwa                                   ; FC64FB  extz XWA
	ld	iy, (xwa+11)                            ; FC64FD  ld IY,(XWA+0x0b)
	sub	bc, iy                                 ; FC6500  sub BC,IY
	ld	de, bc                                  ; FC6502  ld DE,BC
	ld	bc, (0xE084:24)                        ; FC6504  ld BC,(0x00e084)
	extz	xbc                                   ; FC6509  extz XBC
	ld	(xbc+28), de                            ; FC650B  ld (XBC+0x1c),DE
	jr sub_FC63EC__FC6534                      ; FC650E  jr T,0xfc6534
sub_FC63EC__FC6510:
	ld	c, (xix+22)                             ; FC6510  ld C,(XIX+0x16)
	res	7, c                                   ; FC6513  res 0x07,C
	extz	bc                                    ; FC6516  extz BC
	ld	wa, (0xE084:24)                        ; FC6518  ld WA,(0x00e084)
	extz	xwa                                   ; FC651D  extz XWA
	ld	(xwa+26), bc                            ; FC651F  ld (XWA+0x1a),BC
	ld	c, (xix+32)                             ; FC6522  ld C,(XIX+0x20)
	res	7, c                                   ; FC6525  res 0x07,C
	extz	bc                                    ; FC6528  extz BC
	ld	wa, (0xE084:24)                        ; FC652A  ld WA,(0x00e084)
	extz	xwa                                   ; FC652F  extz XWA
	ld	(xwa+28), bc                            ; FC6531  ld (XWA+0x1c),BC
sub_FC63EC__FC6534:
	dec	1, h                                   ; FC6534  dec 1,H
	extpfx7 0xD2, 0x84, 0xE0, 0x00, 0x38, 0x2A, 0x00 ; FC6536  add (0x00e084),0x002a
	ld	c, l                                    ; FC653D  ld C,L
	srl	c, 2                                   ; FC653F  srl 0x02,C
	ld	l, c                                    ; FC6542  ld L,C
	cps	h, 0                                   ; FC6544  cp H,0
	jrl nz, sub_FC63EC__FC6421                 ; FC6546  jrl NZ,0xfc6421
	pop	xix                                    ; FC6549  pop XIX
	popw	de                                    ; FC654A  pop DE
	popw	hl                                    ; FC654B  pop HL
	unlk32 xiz                                 ; FC654C  unlk XIZ
	ret                                        ; FC654E  ret
; --------------------------------------------------------------------------
; sub_FC654F -- 0xFC654F..0xFC65EB (157 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFAECBB in sub_FAEC9C, 0xFB65E5 in sub_FB6500
; Inputs:  frame `link XIZ,-2`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: writes 0x00E082
; Calls:   0xFC46A8 = sub_FC46A8
; Evidence: the listing below is the byte-identical round-trip of 0xFC654F-0xFC65EB
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC654F:
	link32 0xEE, 0x0C, 0xFE, 0xFF              ; FC654F  link XIZ,0xfffe
	pushw	hl                                   ; FC6553  push HL
	pushw	de                                   ; FC6554  push DE
	push	xix                                   ; FC6555  push XIX
	lda	xix, (0xE084:24)                       ; FC6556  lda XIX,0x00e084
	ldb	c, 0xBB                                ; FC655B  ld C,0xbb
	extpfx3 0x8E, 0x08, 0x43                   ; FC655D  mul BC,(XIZ+0x08)
	ld	de, bc                                  ; FC6560  ld DE,BC
	ldw	wa, 0x5D23                             ; FC6562  ld WA,0x5d23
	add	wa, bc                                 ; FC6565  add WA,BC
	ld	(xiz-2), wa                             ; FC6567  ld (XIZ+0xfe),WA
	stw_da	(0xE082), wa                        ; FC656A  ld (0x00e082),WA
	ld	bc, (xiz+10)                            ; FC656F  ld BC,(XIZ+0x0a)
	sll	bc, 8                                  ; FC6572  sll 0x08,BC
	ld	wa, (xiz-2)                             ; FC6575  ld WA,(XIZ+0xfe)
	extz	xwa                                   ; FC6578  extz XWA
	ld	(xwa+13), bc                            ; FC657A  ld (XWA+0x0d),BC
	ld	bc, (0xE082:24)                        ; FC657D  ld BC,(0x00e082)
	add	bc, 19                                 ; FC6582  add BC,0x0013
	ld	(xix), bc                               ; FC6586  ld (XIX),BC
	ld	l, (xiz+12)                             ; FC6588  ld L,(XIZ+0x0c)
	ldb	h, 4                                   ; FC658B  ld H,0x04
sub_FC654F__FC658D:
	ld	bc, (xix)                               ; FC658D  ld BC,(XIX)
	extz	xbc                                   ; FC658F  extz XBC
	extpfx3 0xB9, 0x02, 0xB6                   ; FC6591  res 6,(XBC+0x02)
	extpfx3 0xB9, 0x02, 0xB7                   ; FC6594  res 7,(XBC+0x02)
	ld	bc, (xix)                               ; FC6597  ld BC,(XIX)
	ld	wa, bc                                  ; FC6599  ld WA,BC
	extz	xbc                                   ; FC659B  extz XBC
	extpfx2 0xB1, 0xCF                         ; FC659D  bit 7,(XBC)
	jr z, sub_FC654F__FC65D5                   ; FC659F  jr Z,0xfc65d5
	ld	c, l                                    ; FC65A1  ld C,L
	and	c, 1                                   ; FC65A3  and C,0x01
	jr z, sub_FC654F__FC65C5                   ; FC65A6  jr Z,0xfc65c5
	ld	c, l                                    ; FC65A8  ld C,L
	and	c, 2                                   ; FC65AA  and C,0x02
	jr z, sub_FC654F__FC65BB                   ; FC65AD  jr Z,0xfc65bb
	ld	bc, (xix)                               ; FC65AF  ld BC,(XIX)
	extz	xbc                                   ; FC65B1  extz XBC
	extpfx3 0xB9, 0x02, 0xB6                   ; FC65B3  res 6,(XBC+0x02)
	extpfx3 0xB9, 0x02, 0xBF                   ; FC65B6  set 7,(XBC+0x02)
	jr sub_FC654F__FC65C5                      ; FC65B9  jr T,0xfc65c5
sub_FC654F__FC65BB:
	ld	bc, (xix)                               ; FC65BB  ld BC,(XIX)
	extz	xbc                                   ; FC65BD  extz XBC
	extpfx3 0xB9, 0x02, 0xBE                   ; FC65BF  set 6,(XBC+0x02)
	extpfx3 0xB9, 0x02, 0xB7                   ; FC65C2  res 7,(XBC+0x02)
sub_FC654F__FC65C5:
	ld	bc, (0xE082:24)                        ; FC65C5  ld BC,(0x00e082)
	extz	xbc                                   ; FC65CA  extz XBC
	ld	a, (xbc)                                ; FC65CC  ld A,(XBC)
	cps	a, 0                                   ; FC65CE  cp A,0
	jr nz, sub_FC654F__FC65D5                  ; FC65D0  jr NZ,0xfc65d5
	calr (0xFC46A8 - 0xFC65D5)                 ; FC65D2  calr 0xfc46a8
sub_FC654F__FC65D5:
	dec	1, h                                   ; FC65D5  dec 1,H
	extpfx4 0x94, 0x38, 0x2A, 0x00             ; FC65D7  add (XIX),0x002a
	ld	c, l                                    ; FC65DB  ld C,L
	srl	c, 2                                   ; FC65DD  srl 0x02,C
	ld	l, c                                    ; FC65E0  ld L,C
	cps	h, 0                                   ; FC65E2  cp H,0
	jr nz, sub_FC654F__FC658D                  ; FC65E4  jr NZ,0xfc658d
	pop	xix                                    ; FC65E6  pop XIX
	popw	de                                    ; FC65E7  pop DE
	popw	hl                                    ; FC65E8  pop HL
	unlk32 xiz                                 ; FC65E9  unlk XIZ
	ret                                        ; FC65EB  ret
; --------------------------------------------------------------------------
; sub_FC65EC -- 0xFC65EC..0xFC6711 (294 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFAECE7 in sub_FAECC7, 0xFB65F3 in sub_FB6500
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: writes 0x00E082, 0x00E084
; Evidence: the listing below is the byte-identical round-trip of 0xFC65EC-0xFC6711
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC65EC:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FC65EC  link XIZ,0xfffc
	pushw	hl                                   ; FC65F0  push HL
	push	xde                                   ; FC65F1  push XDE
	push	xix                                   ; FC65F2  push XIX
	ldb	c, 0xBB                                ; FC65F3  ld C,0xbb
	extpfx3 0x8E, 0x08, 0x43                   ; FC65F5  mul BC,(XIZ+0x08)
	ld	hl, bc                                  ; FC65F8  ld HL,BC
	ldw	wa, 0x5D23                             ; FC65FA  ld WA,0x5d23
	ld	de, wa                                  ; FC65FD  ld DE,WA
	add	de, bc                                 ; FC65FF  add DE,BC
	stw_da	(0xE082), de                        ; FC6601  ld (0x00e082),DE
	extz	xde                                   ; FC6606  extz XDE
	ld	bc, (xiz+10)                            ; FC6608  ld BC,(XIZ+0x0a)
	ld	(xde+15), bc                            ; FC660B  ld (XDE+0x0f),BC
	ld	bc, (0xE082:24)                        ; FC660E  ld BC,(0x00e082)
	add	bc, 19                                 ; FC6613  add BC,0x0013
	stw_da	(0xE084), bc                        ; FC6617  ld (0x00e084),BC
	ld	ix, bc                                  ; FC661C  ld IX,BC
	ldb	e, 4                                   ; FC661E  ld E,0x04
sub_FC65EC__FC6620:
	ld	bc, ix                                  ; FC6620  ld BC,IX
	extz	xbc                                   ; FC6622  extz XBC
	extpfx3 0xB9, 0x02, 0xB4                   ; FC6624  res 4,(XBC+0x02)
	extpfx3 0xB9, 0x02, 0xB5                   ; FC6627  res 5,(XBC+0x02)
	ld	ix, (0xE084:24)                        ; FC662A  ld IX,(0x00e084)
	ld	bc, ix                                  ; FC662F  ld BC,IX
	extz	xbc                                   ; FC6631  extz XBC
	extpfx2 0xB1, 0xB6                         ; FC6633  res 6,(XBC)
	ld	ix, (0xE084:24)                        ; FC6635  ld IX,(0x00e084)
	ld	bc, ix                                  ; FC663A  ld BC,IX
	extz	xix                                   ; FC663C  extz XIX
	extpfx2 0xB4, 0xCF                         ; FC663E  bit 7,(XIX)
	jrl z, sub_FC65EC__FC66F3                  ; FC6640  jrl Z,0xfc66f3
	ld	a, (xiz+12)                             ; FC6643  ld A,(XIZ+0x0c)
	and	a, 1                                   ; FC6646  and A,0x01
	jr z, sub_FC65EC__FC6679                   ; FC6649  jr Z,0xfc6679
	ld	bc, ix                                  ; FC664B  ld BC,IX
	extz	xbc                                   ; FC664D  extz XBC
	extpfx2 0xB1, 0xBE                         ; FC664F  set 6,(XBC)
	ld	ix, (0xE084:24)                        ; FC6651  ld IX,(0x00e084)
	ld	c, (xiz+12)                             ; FC6656  ld C,(XIZ+0x0c)
	and	c, 2                                   ; FC6659  and C,0x02
	jr z, sub_FC65EC__FC666A                   ; FC665C  jr Z,0xfc666a
	ld	bc, ix                                  ; FC665E  ld BC,IX
	extz	xbc                                   ; FC6660  extz XBC
	extpfx3 0xB9, 0x02, 0xB4                   ; FC6662  res 4,(XBC+0x02)
	extpfx3 0xB9, 0x02, 0xBD                   ; FC6665  set 5,(XBC+0x02)
	jr sub_FC65EC__FC6674                      ; FC6668  jr T,0xfc6674
sub_FC65EC__FC666A:
	ld	bc, ix                                  ; FC666A  ld BC,IX
	extz	xbc                                   ; FC666C  extz XBC
	extpfx3 0xB9, 0x02, 0xBC                   ; FC666E  set 4,(XBC+0x02)
	extpfx3 0xB9, 0x02, 0xB5                   ; FC6671  res 5,(XBC+0x02)
sub_FC65EC__FC6674:
	ld	ix, (0xE084:24)                        ; FC6674  ld IX,(0x00e084)
sub_FC65EC__FC6679:
	ld	bc, (0xE082:24)                        ; FC6679  ld BC,(0x00e082)
	extz	xbc                                   ; FC667E  extz XBC
	ld	a, (xbc)                                ; FC6680  ld A,(XBC)
	cps	a, 0                                   ; FC6682  cp A,0
	jrl nz, sub_FC65EC__FC66F3                 ; FC6684  jrl NZ,0xfc66f3
	extz	xix                                   ; FC6687  extz XIX
	ld	xwa, (xix+3)                            ; FC6689  ld XWA,(XIX+0x03)
	ld	(xiz-4), xwa                            ; FC668C  ld (XIZ+0xfc),XWA
	ld	d, (xwa+33)                             ; FC668F  ld D,(XWA+0x21)
	cps	d, 0                                   ; FC6692  cp D,0
	jr ge, sub_FC65EC__FC66A2                  ; FC6694  jr GE,0xfc66a2
	ld	a, d                                    ; FC6696  ld A,D
	exts	wa                                    ; FC6698  exts WA
	ld	hl, wa                                  ; FC669A  ld HL,WA
	neg	wa                                     ; FC669C  neg WA
	ld	hl, wa                                  ; FC669E  ld HL,WA
	jr sub_FC65EC__FC66A8                      ; FC66A0  jr T,0xfc66a8
sub_FC65EC__FC66A2:
	ld	c, d                                    ; FC66A2  ld C,D
	exts	bc                                    ; FC66A4  exts BC
	ld	hl, bc                                  ; FC66A6  ld HL,BC
sub_FC65EC__FC66A8:
	ld	bc, ix                                  ; FC66A8  ld BC,IX
	extz	xix                                   ; FC66AA  extz XIX
	ld	a, (xix+2)                              ; FC66AC  ld A,(XIX+0x02)
	and	a, 48                                  ; FC66AF  and A,0x30
	srl	a, 4                                   ; FC66B2  srl 0x04,A
	extz	wa                                    ; FC66B5  extz WA
	cps	wa, 1                                  ; FC66B7  cp WA,1
	jr z, sub_FC65EC__FC66C1                   ; FC66B9  jr Z,0xfc66c1
	cps	wa, 2                                  ; FC66BB  cp WA,2
	jr z, sub_FC65EC__FC66D4                   ; FC66BD  jr Z,0xfc66d4
	jr sub_FC65EC__FC66E9                      ; FC66BF  jr T,0xfc66e9
sub_FC65EC__FC66C1:
	ld	bc, (0xE082:24)                        ; FC66C1  ld BC,(0x00e082)
	extz	xbc                                   ; FC66C6  extz XBC
	ld	wa, (xbc+15)                            ; FC66C8  ld WA,(XBC+0x0f)
	add	wa, hl                                 ; FC66CB  add WA,HL
	extz	xix                                   ; FC66CD  extz XIX
	ld	(xix+30), wa                            ; FC66CF  ld (XIX+0x1e),WA
	jr sub_FC65EC__FC66EE                      ; FC66D2  jr T,0xfc66ee
sub_FC65EC__FC66D4:
	ld	bc, (0xE082:24)                        ; FC66D4  ld BC,(0x00e082)
	extz	xbc                                   ; FC66D9  extz XBC
	ld	wa, (xbc+15)                            ; FC66DB  ld WA,(XBC+0x0f)
	ld	iy, hl                                  ; FC66DE  ld IY,HL
	sub	iy, wa                                 ; FC66E0  sub IY,WA
	extz	xix                                   ; FC66E2  extz XIX
	ld	(xix+30), iy                            ; FC66E4  ld (XIX+0x1e),IY
	jr sub_FC65EC__FC66EE                      ; FC66E7  jr T,0xfc66ee
sub_FC65EC__FC66E9:
	extz	xix                                   ; FC66E9  extz XIX
	ld	(xix+30), hl                            ; FC66EB  ld (XIX+0x1e),HL
sub_FC65EC__FC66EE:
	ld	ix, (0xE084:24)                        ; FC66EE  ld IX,(0x00e084)
sub_FC65EC__FC66F3:
	dec	1, e                                   ; FC66F3  dec 1,E
	add	ix, 42                                 ; FC66F5  add IX,0x002a
	stw_da	(0xE084), ix                        ; FC66F9  ld (0x00e084),IX
	ld	c, (xiz+12)                             ; FC66FE  ld C,(XIZ+0x0c)
	srl	c, 2                                   ; FC6701  srl 0x02,C
	ld	(xiz+12), c                             ; FC6704  ld (XIZ+0x0c),C
	cps	e, 0                                   ; FC6707  cp E,0
	jrl nz, sub_FC65EC__FC6620                 ; FC6709  jrl NZ,0xfc6620
	pop	xix                                    ; FC670C  pop XIX
	pop	xde                                    ; FC670D  pop XDE
	popw	hl                                    ; FC670E  pop HL
	unlk32 xiz                                 ; FC670F  unlk XIZ
	ret                                        ; FC6711  ret
; --------------------------------------------------------------------------
; sub_FC6712 -- 0xFC6712..0xFC6802 (241 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFAED0F in sub_FAECC7__FAECFE
; Inputs:  frame `link XIZ,-6`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: writes 0x00E086
;          reads 0x00E082
; Calls:   0xFC4AED = sub_FC4AED
; Evidence: the listing below is the byte-identical round-trip of 0xFC6712-0xFC6802
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC6712:
	link32 0xEE, 0x0C, 0xFA, 0xFF              ; FC6712  link XIZ,0xfffa
	pushw	hl                                   ; FC6716  push HL
	pushw	de                                   ; FC6717  push DE
	push	xix                                   ; FC6718  push XIX
	lda	xix, (0xE084:24)                       ; FC6719  lda XIX,0x00e084
	ldb	c, 37                                  ; FC671E  ld C,0x25
	extpfx3 0x8E, 0x08, 0x43                   ; FC6720  mul BC,(XIZ+0x08)
	ld	hl, bc                                  ; FC6723  ld HL,BC
	ldw	wa, 0x753E                             ; FC6725  ld WA,0x753e
	add	wa, bc                                 ; FC6728  add WA,BC
	stw_da	(0xE086), wa                        ; FC672A  ld (0x00e086),WA
	extz	xwa                                   ; FC672F  extz XWA
	ld	bc, (xwa+5)                             ; FC6731  ld BC,(XWA+0x05)
	ld	(xix), bc                               ; FC6734  ld (XIX),BC
	ldw	hl, 0                                  ; FC6736  ld HL,0x0000
	ld	bc, (xix)                               ; FC6739  ld BC,(XIX)
	cp	bc, hl                                  ; FC673B  cp BC,HL
	jrl z, sub_FC6712__FC67F7                  ; FC673D  jrl Z,0xfc67f7
	ld	bc, (xix)                               ; FC6740  ld BC,(XIX)
	ld	wa, bc                                  ; FC6742  ld WA,BC
	extz	xbc                                   ; FC6744  extz XBC
	ld	c, (xbc)                                ; FC6746  ld C,(XBC)
	and	c, 64                                  ; FC6748  and C,0x40
	srl	c, 6                                   ; FC674B  srl 0x06,C
	ld	e, c                                    ; FC674E  ld E,C
	cps	c, 0                                   ; FC6750  cp C,0
	jrl z, sub_FC6712__FC67FB                  ; FC6752  jrl Z,0xfc67fb
	ld	bc, (0xE086:24)                        ; FC6755  ld BC,(0x00e086)
	extz	xbc                                   ; FC675A  extz XBC
	ld	a, (xbc)                                ; FC675C  ld A,(XBC)
	cps	a, 0                                   ; FC675E  cp A,0
	jrl z, sub_FC6712__FC67D4                  ; FC6760  jrl Z,0xfc67d4
	ld	xwa, (xbc+1)                            ; FC6763  ld XWA,(XBC+0x01)
	ld	(xiz-4), xwa                            ; FC6766  ld (XIZ+0xfc),XWA
	ld	d, (xwa+33)                             ; FC6769  ld D,(XWA+0x21)
	cps	d, 0                                   ; FC676C  cp D,0
	jr ge, sub_FC6712__FC677C                  ; FC676E  jr GE,0xfc677c
	ld	a, d                                    ; FC6770  ld A,D
	exts	wa                                    ; FC6772  exts WA
	ld	hl, wa                                  ; FC6774  ld HL,WA
	neg	wa                                     ; FC6776  neg WA
	ld	hl, wa                                  ; FC6778  ld HL,WA
	jr sub_FC6712__FC6782                      ; FC677A  jr T,0xfc6782
sub_FC6712__FC677C:
	ld	c, d                                    ; FC677C  ld C,D
	exts	bc                                    ; FC677E  exts BC
	ld	hl, bc                                  ; FC6780  ld HL,BC
sub_FC6712__FC6782:
	ld	bc, (xix)                               ; FC6782  ld BC,(XIX)
	extz	xbc                                   ; FC6784  extz XBC
	ld	a, (xbc+2)                              ; FC6786  ld A,(XBC+0x02)
	and	a, 48                                  ; FC6789  and A,0x30
	srl	a, 4                                   ; FC678C  srl 0x04,A
	extz	wa                                    ; FC678F  extz WA
	cps	wa, 1                                  ; FC6791  cp WA,1
	jr z, sub_FC6712__FC679B                   ; FC6793  jr Z,0xfc679b
	cps	wa, 2                                  ; FC6795  cp WA,2
	jr z, sub_FC6712__FC67B3                   ; FC6797  jr Z,0xfc67b3
	jr sub_FC6712__FC67CD                      ; FC6799  jr T,0xfc67cd
sub_FC6712__FC679B:
	ld	bc, (0xE082:24)                        ; FC679B  ld BC,(0x00e082)
	extz	xbc                                   ; FC67A0  extz XBC
	ld	wa, (xbc+15)                            ; FC67A2  ld WA,(XBC+0x0f)
	add	wa, hl                                 ; FC67A5  add WA,HL
	ld	(xiz-6), wa                             ; FC67A7  ld (XIZ+0xfa),WA
	ld	iy, (xix)                               ; FC67AA  ld IY,(XIX)
	extz	xiy                                   ; FC67AC  extz XIY
	ld	(xiy+30), wa                            ; FC67AE  ld (XIY+0x1e),WA
	jr sub_FC6712__FC67D4                      ; FC67B1  jr T,0xfc67d4
sub_FC6712__FC67B3:
	ld	bc, (0xE082:24)                        ; FC67B3  ld BC,(0x00e082)
	extz	xbc                                   ; FC67B8  extz XBC
	ld	wa, (xbc+15)                            ; FC67BA  ld WA,(XBC+0x0f)
	ld	iy, hl                                  ; FC67BD  ld IY,HL
	sub	iy, wa                                 ; FC67BF  sub IY,WA
	ld	(xiz-6), iy                             ; FC67C1  ld (XIZ+0xfa),IY
	ld	wa, (xix)                               ; FC67C4  ld WA,(XIX)
	extz	xwa                                   ; FC67C6  extz XWA
	ld	(xwa+30), iy                            ; FC67C8  ld (XWA+0x1e),IY
	jr sub_FC6712__FC67D4                      ; FC67CB  jr T,0xfc67d4
sub_FC6712__FC67CD:
	ld	bc, (xix)                               ; FC67CD  ld BC,(XIX)
	extz	xbc                                   ; FC67CF  extz XBC
	ld	(xbc+30), hl                            ; FC67D1  ld (XBC+0x1e),HL
sub_FC6712__FC67D4:
	ld	bc, (xix)                               ; FC67D4  ld BC,(XIX)
	extz	xbc                                   ; FC67D6  extz XBC
	ld	wa, (xbc+30)                            ; FC67D8  ld WA,(XBC+0x1e)
	ld	bc, (0xE086:24)                        ; FC67DB  ld BC,(0x00e086)
	extz	xbc                                   ; FC67E0  extz XBC
	ld	(xbc+35), wa                            ; FC67E2  ld (XBC+0x23),WA
	ld	xbc, (xiz+10)                           ; FC67E5  ld XBC,(XIZ+0x0a)
	push	xbc                                   ; FC67E8  push XBC
	calr (0xFC4AED - 0xFC67EC)                 ; FC67E9  calr 0xfc4aed
	ld	xbc, (xiz+10)                           ; FC67EC  ld XBC,(XIZ+0x0a)
	extpfx5 0x99, 0x14, 0x3E, 0x07, 0x00       ; FC67EF  or (XBC+0x14),0x0007
	pop	xiy                                    ; FC67F4  pop XIY
	jr sub_FC6712__FC67FB                      ; FC67F5  jr T,0xfc67fb
sub_FC6712__FC67F7:
	sub	a, a                                   ; FC67F7  sub A,A
	jr sub_FC6712__FC67FD                      ; FC67F9  jr T,0xfc67fd
sub_FC6712__FC67FB:
	ld	a, e                                    ; FC67FB  ld A,E
sub_FC6712__FC67FD:
	pop	xix                                    ; FC67FD  pop XIX
	popw	de                                    ; FC67FE  pop DE
	popw	hl                                    ; FC67FF  pop HL
	unlk32 xiz                                 ; FC6800  unlk XIZ
	ret                                        ; FC6802  ret
; --------------------------------------------------------------------------
; sub_FC6803 -- 0xFC6803..0xFC6CA7 (1189 bytes)
;
; Called from: 40 site(s) outside this module:
;          0xFAFCC7 in sub_FAFBEC__FAFCB1, 0xFB2A10 in sub_FB289A
;          0xFB2A8A in sub_FB289A__FB2A65, 0xFB2C0B in VoiceParams_Compute_C
;          0xFB2C65 in VoiceParams_Compute_C__FB2C4B, 0xFB2DCB in VoiceParams_Compute_C__FB2C6D
;          0xFB2E25 in VoiceParams_Compute_C__FB2E0B, 0xFB319D in sub_FB2F74__FB3194
;          0xFB33AE in VoiceParams_Compute_D__FB33A5, 0xFB35AF in VoiceParams_Compute_D__FB35A6
;          0xFB68AA in sub_FB6681__FB6891, 0xFB6B29 in sub_FB68DD__FB6B0F
;          0xFB9233 in ToneDB_SourceNameList1_SelectEntry__FB91E3, 0xFB9268 in ToneDB_SourceNameList1_SelectEntry__FB923D
;          0xFB93C4 in ToneDB_SourceNameList2_SelectEntry__FB92D2, 0xFB93F9 in ToneDB_SourceNameList2_SelectEntry__FB93CE
;          0xFB94F0 in sub_FB9414__FB94AF, 0xFB9524 in sub_FB9414__FB94FA
;          0xFB9754 in ToneDB_DrumSourceNameList_SelectEntry__FB9709, 0xFB976F in ToneDB_DrumSourceNameList_SelectEntry__FB975E
;          0xFB9918 in ToneDB_PercSourceNameList1_SelectEntry__FB98D5, 0xFB9933 in ToneDB_PercSourceNameList1_SelectEntry__FB9922
;          0xFB9A8B in ToneDB_PercSourceNameList2_SelectEntry__FB9A48, 0xFB9AA6 in ToneDB_PercSourceNameList2_SelectEntry__FB9A95
;          0xFBBB34 in sub_FBB793__FBBAE4, 0xFBBB69 in sub_FBB793__FBBB3E
;          0xFBBD6F in sub_FBB793__FBBD1F, 0xFBBDA4 in sub_FBB793__FBBD79
;          0xFBC0BC in sub_FBBFFB__FBC06C, 0xFBC0F1 in sub_FBBFFB__FBC0C6
;          0xFBCB59 in sub_FBC958__FBCB09, 0xFBCB8E in sub_FBC958__FBCB63
;          0xFBCCE0 in sub_FBCBA7__FBCC95, 0xFBCCFB in sub_FBCBA7__FBCCEA
;          0xFBD19D in sub_FBD0A2__FBD15A, 0xFBD1B8 in sub_FBD0A2__FBD1A7
;          0xFBD520 in sub_FBD46B__FBD4DB, 0xFBD556 in sub_FBD46B__FBD52A
;          0xFBD821 in sub_FBD6FC__FBD7D3, 0xFBD83C in sub_FBD6FC__FBD82B
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C), (XIZ+0x10)
; Outputs: writes 0x00E082
; Calls:   0xFC46A8 = sub_FC46A8, 0xFC47EE = sub_FC47EE
; Evidence: the listing below is the byte-identical round-trip of 0xFC6803-0xFC6CA7
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC6803:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC6803  link XIZ,0x0000
	pushw	hl                                   ; FC6807  push HL
	pushw	de                                   ; FC6808  push DE
	push	xix                                   ; FC6809  push XIX
	lda	xix, (0xE084:24)                       ; FC680A  lda XIX,0x00e084
	ldb	c, 0xBB                                ; FC680F  ld C,0xbb
	extpfx3 0x8E, 0x08, 0x43                   ; FC6811  mul BC,(XIZ+0x08)
	ld	hl, bc                                  ; FC6814  ld HL,BC
	ldw	wa, 0x5D23                             ; FC6816  ld WA,0x5d23
	add	wa, bc                                 ; FC6819  add WA,BC
	stw_da	(0xE082), wa                        ; FC681B  ld (0x00e082),WA
	ldb	c, 42                                  ; FC6820  ld C,0x2a
	extpfx3 0x8E, 0x0A, 0x43                   ; FC6822  mul BC,(XIZ+0x0a)
	add	bc, 19                                 ; FC6825  add BC,0x0013
	add	wa, bc                                 ; FC6829  add WA,BC
	ld	(xix), wa                               ; FC682B  ld (XIX),WA
	ld	bc, (xix)                               ; FC682D  ld BC,(XIX)
	extz	xbc                                   ; FC682F  extz XBC
	ld	xwa, (xiz+12)                           ; FC6831  ld XWA,(XIZ+0x0c)
	ld	(xbc+3), xwa                            ; FC6834  ld (XBC+0x03),XWA
	cp (xiz+16), 0x00                          ; FC6837  cp (XIZ+0x10),0x00
	jr z, sub_FC6803__FC6845                   ; FC683B  jr Z,0xfc6845
	ld	bc, (xix)                               ; FC683D  ld BC,(XIX)
	extz	xbc                                   ; FC683F  extz XBC
	extpfx2 0xB1, 0xBF                         ; FC6841  set 7,(XBC)
	jr sub_FC6803__FC684B                      ; FC6843  jr T,0xfc684b
sub_FC6803__FC6845:
	ld	bc, (xix)                               ; FC6845  ld BC,(XIX)
	extz	xbc                                   ; FC6847  extz XBC
	extpfx2 0xB1, 0xB7                         ; FC6849  res 7,(XBC)
sub_FC6803__FC684B:
	cp (xiz+16), 0x00                          ; FC684B  cp (XIZ+0x10),0x00
	jrl z, sub_FC6803__FC6CA2                  ; FC684F  jrl Z,0xfc6ca2
	ld	xbc, (xiz+12)                           ; FC6852  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FC6855  push XBC
	calr (0xFC47EE - 0xFC6859)                 ; FC6856  calr 0xfc47ee
	ld	bc, (xix)                               ; FC6859  ld BC,(XIX)
	extz	xbc                                   ; FC685B  extz XBC
	ld	a, (xbc)                                ; FC685D  ld A,(XBC)
	and	a, 24                                  ; FC685F  and A,0x18
	srl	a, 3                                   ; FC6862  srl 0x03,A
	extz	wa                                    ; FC6865  extz WA
	pop	xiy                                    ; FC6867  pop XIY
	cps	wa, 1                                  ; FC6868  cp WA,1
	jr z, sub_FC6803__FC6873                   ; FC686A  jr Z,0xfc6873
	cps	wa, 2                                  ; FC686C  cp WA,2
	jr z, sub_FC6803__FC68BA                   ; FC686E  jr Z,0xfc68ba
	jrl sub_FC6803__FC6900                     ; FC6870  jrl T,0xfc6900
sub_FC6803__FC6873:
	ld	xbc, (xiz+12)                           ; FC6873  ld XBC,(XIZ+0x0c)
	ld	a, (xbc+21)                             ; FC6876  ld A,(XBC+0x15)
	res	7, a                                   ; FC6879  res 0x07,A
	extz	wa                                    ; FC687C  extz WA
	ld	hl, wa                                  ; FC687E  ld HL,WA
	ld	bc, (0xE082:24)                        ; FC6880  ld BC,(0x00e082)
	extz	xbc                                   ; FC6885  extz XBC
	ld	iy, (xbc+1)                             ; FC6887  ld IY,(XBC+0x01)
	ld	de, wa                                  ; FC688A  ld DE,WA
	add	de, iy                                 ; FC688C  add DE,IY
	ld	wa, (xix)                               ; FC688E  ld WA,(XIX)
	extz	xwa                                   ; FC6890  extz XWA
	ld	(xwa+22), de                            ; FC6892  ld (XWA+0x16),DE
	ld	xbc, (xiz+12)                           ; FC6895  ld XBC,(XIZ+0x0c)
	ld	a, (xbc+31)                             ; FC6898  ld A,(XBC+0x1f)
	res	7, a                                   ; FC689B  res 0x07,A
	extz	wa                                    ; FC689E  extz WA
	ld	hl, wa                                  ; FC68A0  ld HL,WA
	ld	bc, (0xE082:24)                        ; FC68A2  ld BC,(0x00e082)
	extz	xbc                                   ; FC68A7  extz XBC
	ld	iy, (xbc+1)                             ; FC68A9  ld IY,(XBC+0x01)
	ld	de, wa                                  ; FC68AC  ld DE,WA
	add	de, iy                                 ; FC68AE  add DE,IY
	ld	wa, (xix)                               ; FC68B0  ld WA,(XIX)
	extz	xwa                                   ; FC68B2  extz XWA
	ld	(xwa+24), de                            ; FC68B4  ld (XWA+0x18),DE
	jrl sub_FC6803__FC6928                     ; FC68B7  jrl T,0xfc6928
sub_FC6803__FC68BA:
	ld	xbc, (xiz+12)                           ; FC68BA  ld XBC,(XIZ+0x0c)
	ld	a, (xbc+21)                             ; FC68BD  ld A,(XBC+0x15)
	res	7, a                                   ; FC68C0  res 0x07,A
	extz	wa                                    ; FC68C3  extz WA
	ld	hl, wa                                  ; FC68C5  ld HL,WA
	ld	bc, (0xE082:24)                        ; FC68C7  ld BC,(0x00e082)
	extz	xbc                                   ; FC68CC  extz XBC
	ld	iy, (xbc+1)                             ; FC68CE  ld IY,(XBC+0x01)
	ld	de, wa                                  ; FC68D1  ld DE,WA
	sub	de, iy                                 ; FC68D3  sub DE,IY
	ld	wa, (xix)                               ; FC68D5  ld WA,(XIX)
	extz	xwa                                   ; FC68D7  extz XWA
	ld	(xwa+22), de                            ; FC68D9  ld (XWA+0x16),DE
	ld	xbc, (xiz+12)                           ; FC68DC  ld XBC,(XIZ+0x0c)
	ld	a, (xbc+31)                             ; FC68DF  ld A,(XBC+0x1f)
	res	7, a                                   ; FC68E2  res 0x07,A
	extz	wa                                    ; FC68E5  extz WA
	ld	hl, wa                                  ; FC68E7  ld HL,WA
	ld	bc, (0xE082:24)                        ; FC68E9  ld BC,(0x00e082)
	extz	xbc                                   ; FC68EE  extz XBC
	ld	iy, (xbc+1)                             ; FC68F0  ld IY,(XBC+0x01)
	ld	de, wa                                  ; FC68F3  ld DE,WA
	sub	de, iy                                 ; FC68F5  sub DE,IY
	ld	wa, (xix)                               ; FC68F7  ld WA,(XIX)
	extz	xwa                                   ; FC68F9  extz XWA
	ld	(xwa+24), de                            ; FC68FB  ld (XWA+0x18),DE
	jr sub_FC6803__FC6928                      ; FC68FE  jr T,0xfc6928
sub_FC6803__FC6900:
	ld	xbc, (xiz+12)                           ; FC6900  ld XBC,(XIZ+0x0c)
	ld	a, (xbc+21)                             ; FC6903  ld A,(XBC+0x15)
	res	7, a                                   ; FC6906  res 0x07,A
	extz	wa                                    ; FC6909  extz WA
	ld	hl, wa                                  ; FC690B  ld HL,WA
	ld	iy, (xix)                               ; FC690D  ld IY,(XIX)
	extz	xiy                                   ; FC690F  extz XIY
	ld	(xiy+22), wa                            ; FC6911  ld (XIY+0x16),WA
	ld	xbc, (xiz+12)                           ; FC6914  ld XBC,(XIZ+0x0c)
	ld	a, (xbc+31)                             ; FC6917  ld A,(XBC+0x1f)
	res	7, a                                   ; FC691A  res 0x07,A
	extz	wa                                    ; FC691D  extz WA
	ld	hl, wa                                  ; FC691F  ld HL,WA
	ld	iy, (xix)                               ; FC6921  ld IY,(XIX)
	extz	xiy                                   ; FC6923  extz XIY
	ld	(xiy+24), wa                            ; FC6925  ld (XIY+0x18),WA
sub_FC6803__FC6928:
	ld	bc, (xix)                               ; FC6928  ld BC,(XIX)
	extz	xbc                                   ; FC692A  extz XBC
	ld	a, (xbc)                                ; FC692C  ld A,(XBC)
	and	a, 6                                   ; FC692E  and A,0x06
	srl	a, 1                                   ; FC6931  srl 0x01,A
	extz	wa                                    ; FC6934  extz WA
	cps	wa, 1                                  ; FC6936  cp WA,1
	jr z, sub_FC6803__FC6941                   ; FC6938  jr Z,0xfc6941
	cps	wa, 2                                  ; FC693A  cp WA,2
	jr z, sub_FC6803__FC6970                   ; FC693C  jr Z,0xfc6970
	jrl sub_FC6803__FC69DD                     ; FC693E  jrl T,0xfc69dd
sub_FC6803__FC6941:
	ld	xbc, (xiz+12)                           ; FC6941  ld XBC,(XIZ+0x0c)
	ld	a, (xbc+13)                             ; FC6944  ld A,(XBC+0x0d)
	extz	wa                                    ; FC6947  extz WA
	ld	hl, wa                                  ; FC6949  ld HL,WA
	ld	bc, (0xE082:24)                        ; FC694B  ld BC,(0x00e082)
	extz	xbc                                   ; FC6950  extz XBC
	ld	iy, (xbc+3)                             ; FC6952  ld IY,(XBC+0x03)
	ld	de, wa                                  ; FC6955  ld DE,WA
	add	de, iy                                 ; FC6957  add DE,IY
	ld	wa, (xix)                               ; FC6959  ld WA,(XIX)
	extz	xwa                                   ; FC695B  extz XWA
	ld	(xwa+32), de                            ; FC695D  ld (XWA+0x20),DE
	ld	bc, (0xE082:24)                        ; FC6960  ld BC,(0x00e082)
	extz	xbc                                   ; FC6965  extz XBC
	ld	wa, (xbc+3)                             ; FC6967  ld WA,(XBC+0x03)
	cps	wa, 0                                  ; FC696A  cp WA,0
	jr ge, sub_FC6803__FC69B4                  ; FC696C  jr GE,0xfc69b4
	jr sub_FC6803__FC699D                      ; FC696E  jr T,0xfc699d
sub_FC6803__FC6970:
	ld	xbc, (xiz+12)                           ; FC6970  ld XBC,(XIZ+0x0c)
	ld	a, (xbc+13)                             ; FC6973  ld A,(XBC+0x0d)
	extz	wa                                    ; FC6976  extz WA
	ld	hl, wa                                  ; FC6978  ld HL,WA
	ld	bc, (0xE082:24)                        ; FC697A  ld BC,(0x00e082)
	extz	xbc                                   ; FC697F  extz XBC
	ld	iy, (xbc+3)                             ; FC6981  ld IY,(XBC+0x03)
	ld	de, wa                                  ; FC6984  ld DE,WA
	sub	de, iy                                 ; FC6986  sub DE,IY
	ld	wa, (xix)                               ; FC6988  ld WA,(XIX)
	extz	xwa                                   ; FC698A  extz XWA
	ld	(xwa+32), de                            ; FC698C  ld (XWA+0x20),DE
	ld	bc, (0xE082:24)                        ; FC698F  ld BC,(0x00e082)
	extz	xbc                                   ; FC6994  extz XBC
	ld	wa, (xbc+3)                             ; FC6996  ld WA,(XBC+0x03)
	cps	wa, 0                                  ; FC6999  cp WA,0
	jr ge, sub_FC6803__FC69B4                  ; FC699B  jr GE,0xfc69b4
sub_FC6803__FC699D:
	ld	bc, (0xE082:24)                        ; FC699D  ld BC,(0x00e082)
	extz	xbc                                   ; FC69A2  extz XBC
	ld	hl, (xbc+3)                             ; FC69A4  ld HL,(XBC+0x03)
	ld	wa, hl                                  ; FC69A7  ld WA,HL
	neg	wa                                     ; FC69A9  neg WA
	ld	hl, wa                                  ; FC69AB  ld HL,WA
	sra	wa, 2                                  ; FC69AD  sra 0x02,WA
	ld	hl, wa                                  ; FC69B0  ld HL,WA
	jr sub_FC6803__FC69C5                      ; FC69B2  jr T,0xfc69c5
sub_FC6803__FC69B4:
	ld	bc, (0xE082:24)                        ; FC69B4  ld BC,(0x00e082)
	extz	xbc                                   ; FC69B9  extz XBC
	ld	hl, (xbc+3)                             ; FC69BB  ld HL,(XBC+0x03)
	ld	iy, hl                                  ; FC69BE  ld IY,HL
	sra	iy, 2                                  ; FC69C0  sra 0x02,IY
	ld	hl, iy                                  ; FC69C3  ld HL,IY
sub_FC6803__FC69C5:
	ld	xbc, (xiz+12)                           ; FC69C5  ld XBC,(XIZ+0x0c)
	ld	a, (xbc+14)                             ; FC69C8  ld A,(XBC+0x0e)
	res	7, a                                   ; FC69CB  res 0x07,A
	extz	wa                                    ; FC69CE  extz WA
	ld	de, wa                                  ; FC69D0  ld DE,WA
	add	de, hl                                 ; FC69D2  add DE,HL
	ld	wa, (xix)                               ; FC69D4  ld WA,(XIX)
	extz	xwa                                   ; FC69D6  extz XWA
	ld	(xwa+34), de                            ; FC69D8  ld (XWA+0x22),DE
	jr sub_FC6803__FC6A02                      ; FC69DB  jr T,0xfc6a02
sub_FC6803__FC69DD:
	ld	xbc, (xiz+12)                           ; FC69DD  ld XBC,(XIZ+0x0c)
	ld	a, (xbc+13)                             ; FC69E0  ld A,(XBC+0x0d)
	extz	wa                                    ; FC69E3  extz WA
	ld	hl, wa                                  ; FC69E5  ld HL,WA
	ld	iy, (xix)                               ; FC69E7  ld IY,(XIX)
	extz	xiy                                   ; FC69E9  extz XIY
	ld	(xiy+32), wa                            ; FC69EB  ld (XIY+0x20),WA
	ld	xbc, (xiz+12)                           ; FC69EE  ld XBC,(XIZ+0x0c)
	ld	a, (xbc+14)                             ; FC69F1  ld A,(XBC+0x0e)
	res	7, a                                   ; FC69F4  res 0x07,A
	extz	wa                                    ; FC69F7  extz WA
	ld	hl, wa                                  ; FC69F9  ld HL,WA
	ld	iy, (xix)                               ; FC69FB  ld IY,(XIX)
	extz	xiy                                   ; FC69FD  extz XIY
	ld	(xiy+34), wa                            ; FC69FF  ld (XIY+0x22),WA
sub_FC6803__FC6A02:
	ld	bc, (xix)                               ; FC6A02  ld BC,(XIX)
	extz	xbc                                   ; FC6A04  extz XBC
	ld	a, (xbc+1)                              ; FC6A06  ld A,(XBC+0x01)
	and	a, 0xC0                                ; FC6A09  and A,0xc0
	srl	a, 6                                   ; FC6A0C  srl 0x06,A
	extz	wa                                    ; FC6A0F  extz WA
	cps	wa, 1                                  ; FC6A11  cp WA,1
	jr z, sub_FC6803__FC6A1B                   ; FC6A13  jr Z,0xfc6a1b
	cps	wa, 2                                  ; FC6A15  cp WA,2
	jr z, sub_FC6803__FC6A39                   ; FC6A17  jr Z,0xfc6a39
	jr sub_FC6803__FC6A55                      ; FC6A19  jr T,0xfc6a55
sub_FC6803__FC6A1B:
	ld	bc, (0xE082:24)                        ; FC6A1B  ld BC,(0x00e082)
	extz	xbc                                   ; FC6A20  extz XBC
	ld	hl, (xbc+5)                             ; FC6A22  ld HL,(XBC+0x05)
	ld	wa, (xix)                               ; FC6A25  ld WA,(XIX)
	extz	xwa                                   ; FC6A27  extz XWA
	ld	iy, (xwa+34)                            ; FC6A29  ld IY,(XWA+0x22)
	ld	de, iy                                  ; FC6A2C  ld DE,IY
	add	de, hl                                 ; FC6A2E  add DE,HL
	ld	wa, (xix)                               ; FC6A30  ld WA,(XIX)
	extz	xwa                                   ; FC6A32  extz XWA
	ld	(xwa+34), de                            ; FC6A34  ld (XWA+0x22),DE
	jr sub_FC6803__FC6A55                      ; FC6A37  jr T,0xfc6a55
sub_FC6803__FC6A39:
	ld	bc, (0xE082:24)                        ; FC6A39  ld BC,(0x00e082)
	extz	xbc                                   ; FC6A3E  extz XBC
	ld	hl, (xbc+5)                             ; FC6A40  ld HL,(XBC+0x05)
	ld	wa, (xix)                               ; FC6A43  ld WA,(XIX)
	extz	xwa                                   ; FC6A45  extz XWA
	ld	iy, (xwa+34)                            ; FC6A47  ld IY,(XWA+0x22)
	ld	de, iy                                  ; FC6A4A  ld DE,IY
	sub	de, hl                                 ; FC6A4C  sub DE,HL
	ld	wa, (xix)                               ; FC6A4E  ld WA,(XIX)
	extz	xwa                                   ; FC6A50  extz XWA
	ld	(xwa+34), de                            ; FC6A52  ld (XWA+0x22),DE
sub_FC6803__FC6A55:
	ld	bc, (xix)                               ; FC6A55  ld BC,(XIX)
	extz	xbc                                   ; FC6A57  extz XBC
	ld	a, (xbc+1)                              ; FC6A59  ld A,(XBC+0x01)
	and	a, 48                                  ; FC6A5C  and A,0x30
	srl	a, 4                                   ; FC6A5F  srl 0x04,A
	extz	wa                                    ; FC6A62  extz WA
	cps	wa, 1                                  ; FC6A64  cp WA,1
	jr z, sub_FC6803__FC6A6E                   ; FC6A66  jr Z,0xfc6a6e
	cps	wa, 2                                  ; FC6A68  cp WA,2
	jr z, sub_FC6803__FC6A92                   ; FC6A6A  jr Z,0xfc6a92
	jr sub_FC6803__FC6AC7                      ; FC6A6C  jr T,0xfc6ac7
sub_FC6803__FC6A6E:
	ld	xbc, (xiz+12)                           ; FC6A6E  ld XBC,(XIZ+0x0c)
	ld	a, (xbc+17)                             ; FC6A71  ld A,(XBC+0x11)
	extz	wa                                    ; FC6A74  extz WA
	ld	de, wa                                  ; FC6A76  ld DE,WA
	ld	bc, (0xE082:24)                        ; FC6A78  ld BC,(0x00e082)
	extz	xbc                                   ; FC6A7D  extz XBC
	ld	iy, (xbc+7)                             ; FC6A7F  ld IY,(XBC+0x07)
	ld	hl, wa                                  ; FC6A82  ld HL,WA
	add	hl, iy                                 ; FC6A84  add HL,IY
	cp	hl, 50                                  ; FC6A86  cp HL,0x0032
	jr gt, sub_FC6803__FC6AB0                  ; FC6A8A  jr GT,0xfc6ab0
	cps	hl, 0                                  ; FC6A8C  cp HL,0
	jr ge, sub_FC6803__FC6ABC                  ; FC6A8E  jr GE,0xfc6abc
	jr sub_FC6803__FC6AB9                      ; FC6A90  jr T,0xfc6ab9
sub_FC6803__FC6A92:
	ld	xbc, (xiz+12)                           ; FC6A92  ld XBC,(XIZ+0x0c)
	ld	a, (xbc+17)                             ; FC6A95  ld A,(XBC+0x11)
	extz	wa                                    ; FC6A98  extz WA
	ld	de, wa                                  ; FC6A9A  ld DE,WA
	ld	bc, (0xE082:24)                        ; FC6A9C  ld BC,(0x00e082)
	extz	xbc                                   ; FC6AA1  extz XBC
	ld	iy, (xbc+7)                             ; FC6AA3  ld IY,(XBC+0x07)
	ld	hl, wa                                  ; FC6AA6  ld HL,WA
	sub	hl, iy                                 ; FC6AA8  sub HL,IY
	cp	hl, 50                                  ; FC6AAA  cp HL,0x0032
	jr le, sub_FC6803__FC6AB5                  ; FC6AAE  jr LE,0xfc6ab5
sub_FC6803__FC6AB0:
	ldw	hl, 50                                 ; FC6AB0  ld HL,0x0032
	jr sub_FC6803__FC6ABC                      ; FC6AB3  jr T,0xfc6abc
sub_FC6803__FC6AB5:
	cps	hl, 0                                  ; FC6AB5  cp HL,0
	jr ge, sub_FC6803__FC6ABC                  ; FC6AB7  jr GE,0xfc6abc
sub_FC6803__FC6AB9:
	ldw	hl, 0                                  ; FC6AB9  ld HL,0x0000
sub_FC6803__FC6ABC:
	ld	d, l                                    ; FC6ABC  ld D,L
	ld	bc, (xix)                               ; FC6ABE  ld BC,(XIX)
	extz	xbc                                   ; FC6AC0  extz XBC
	ld	(xbc+40), d                             ; FC6AC2  ld (XBC+0x28),D
	jr sub_FC6803__FC6AD1                      ; FC6AC5  jr T,0xfc6ad1
sub_FC6803__FC6AC7:
	ld	xbc, (xiz+12)                           ; FC6AC7  ld XBC,(XIZ+0x0c)
	ld	a, (xbc+17)                             ; FC6ACA  ld A,(XBC+0x11)
	extz	wa                                    ; FC6ACD  extz WA
	ld	hl, wa                                  ; FC6ACF  ld HL,WA
sub_FC6803__FC6AD1:
	ld	d, l                                    ; FC6AD1  ld D,L
	ld	bc, (xix)                               ; FC6AD3  ld BC,(XIX)
	extz	xbc                                   ; FC6AD5  extz XBC
	ld	(xbc+40), d                             ; FC6AD7  ld (XBC+0x28),D
	ld	bc, (xix)                               ; FC6ADA  ld BC,(XIX)
	extz	xbc                                   ; FC6ADC  extz XBC
	ld	a, (xbc+1)                              ; FC6ADE  ld A,(XBC+0x01)
	and	a, 12                                  ; FC6AE1  and A,0x0c
	srl	a, 2                                   ; FC6AE4  srl 0x02,A
	extz	wa                                    ; FC6AE7  extz WA
	cps	wa, 1                                  ; FC6AE9  cp WA,1
	jr z, sub_FC6803__FC6AF3                   ; FC6AEB  jr Z,0xfc6af3
	cps	wa, 2                                  ; FC6AED  cp WA,2
	jr z, sub_FC6803__FC6B1A                   ; FC6AEF  jr Z,0xfc6b1a
	jr sub_FC6803__FC6B49                      ; FC6AF1  jr T,0xfc6b49
sub_FC6803__FC6AF3:
	ld	xbc, (xiz+12)                           ; FC6AF3  ld XBC,(XIZ+0x0c)
	ld	a, (xbc+18)                             ; FC6AF6  ld A,(XBC+0x12)
	res	7, a                                   ; FC6AF9  res 0x07,A
	extz	wa                                    ; FC6AFC  extz WA
	ld	de, wa                                  ; FC6AFE  ld DE,WA
	ld	bc, (0xE082:24)                        ; FC6B00  ld BC,(0x00e082)
	extz	xbc                                   ; FC6B05  extz XBC
	ld	iy, (xbc+9)                             ; FC6B07  ld IY,(XBC+0x09)
	ld	hl, wa                                  ; FC6B0A  ld HL,WA
	add	hl, iy                                 ; FC6B0C  add HL,IY
	cp	hl, 50                                  ; FC6B0E  cp HL,0x0032
	jr gt, sub_FC6803__FC6B3B                  ; FC6B12  jr GT,0xfc6b3b
	cps	hl, 0                                  ; FC6B14  cp HL,0
	jr ge, sub_FC6803__FC6B56                  ; FC6B16  jr GE,0xfc6b56
	jr sub_FC6803__FC6B44                      ; FC6B18  jr T,0xfc6b44
sub_FC6803__FC6B1A:
	ld	xbc, (xiz+12)                           ; FC6B1A  ld XBC,(XIZ+0x0c)
	ld	a, (xbc+18)                             ; FC6B1D  ld A,(XBC+0x12)
	res	7, a                                   ; FC6B20  res 0x07,A
	extz	wa                                    ; FC6B23  extz WA
	ld	de, wa                                  ; FC6B25  ld DE,WA
	ld	bc, (0xE082:24)                        ; FC6B27  ld BC,(0x00e082)
	extz	xbc                                   ; FC6B2C  extz XBC
	ld	iy, (xbc+9)                             ; FC6B2E  ld IY,(XBC+0x09)
	ld	hl, wa                                  ; FC6B31  ld HL,WA
	add	hl, iy                                 ; FC6B33  add HL,IY
	cp	hl, 50                                  ; FC6B35  cp HL,0x0032
	jr le, sub_FC6803__FC6B40                  ; FC6B39  jr LE,0xfc6b40
sub_FC6803__FC6B3B:
	ldw	hl, 50                                 ; FC6B3B  ld HL,0x0032
	jr sub_FC6803__FC6B56                      ; FC6B3E  jr T,0xfc6b56
sub_FC6803__FC6B40:
	cps	hl, 0                                  ; FC6B40  cp HL,0
	jr ge, sub_FC6803__FC6B56                  ; FC6B42  jr GE,0xfc6b56
sub_FC6803__FC6B44:
	ldw	hl, 0                                  ; FC6B44  ld HL,0x0000
	jr sub_FC6803__FC6B56                      ; FC6B47  jr T,0xfc6b56
sub_FC6803__FC6B49:
	ld	xbc, (xiz+12)                           ; FC6B49  ld XBC,(XIZ+0x0c)
	ld	a, (xbc+18)                             ; FC6B4C  ld A,(XBC+0x12)
	res	7, a                                   ; FC6B4F  res 0x07,A
	extz	wa                                    ; FC6B52  extz WA
	ld	hl, wa                                  ; FC6B54  ld HL,WA
sub_FC6803__FC6B56:
	ld	bc, hl                                  ; FC6B56  ld BC,HL
	exts	xbc                                   ; FC6B58  exts XBC
	add	xbc, 0xFE0296                          ; FC6B5A  add XBC,0x00fe0296
	ld	d, (xbc)                                ; FC6B60  ld D,(XBC)
	ld	bc, (xix)                               ; FC6B62  ld BC,(XIX)
	extz	xbc                                   ; FC6B64  extz XBC
	ld	(xbc+41), d                             ; FC6B66  ld (XBC+0x29),D
	ld	bc, (xix)                               ; FC6B69  ld BC,(XIX)
	extz	xbc                                   ; FC6B6B  extz XBC
	ld	a, (xbc+1)                              ; FC6B6D  ld A,(XBC+0x01)
	and	a, 3                                   ; FC6B70  and A,0x03
	extz	wa                                    ; FC6B73  extz WA
	cps	wa, 1                                  ; FC6B75  cp WA,1
	jr z, sub_FC6803__FC6B80                   ; FC6B77  jr Z,0xfc6b80
	cps	wa, 2                                  ; FC6B79  cp WA,2
	jr z, sub_FC6803__FC6BC7                   ; FC6B7B  jr Z,0xfc6bc7
	jrl sub_FC6803__FC6C0D                     ; FC6B7D  jrl T,0xfc6c0d
sub_FC6803__FC6B80:
	ld	xbc, (xiz+12)                           ; FC6B80  ld XBC,(XIZ+0x0c)
	ld	a, (xbc+22)                             ; FC6B83  ld A,(XBC+0x16)
	res	7, a                                   ; FC6B86  res 0x07,A
	extz	wa                                    ; FC6B89  extz WA
	ld	hl, wa                                  ; FC6B8B  ld HL,WA
	ld	bc, (0xE082:24)                        ; FC6B8D  ld BC,(0x00e082)
	extz	xbc                                   ; FC6B92  extz XBC
	ld	iy, (xbc+11)                            ; FC6B94  ld IY,(XBC+0x0b)
	ld	de, wa                                  ; FC6B97  ld DE,WA
	add	de, iy                                 ; FC6B99  add DE,IY
	ld	wa, (xix)                               ; FC6B9B  ld WA,(XIX)
	extz	xwa                                   ; FC6B9D  extz XWA
	ld	(xwa+26), de                            ; FC6B9F  ld (XWA+0x1a),DE
	ld	xbc, (xiz+12)                           ; FC6BA2  ld XBC,(XIZ+0x0c)
	ld	a, (xbc+32)                             ; FC6BA5  ld A,(XBC+0x20)
	res	7, a                                   ; FC6BA8  res 0x07,A
	extz	wa                                    ; FC6BAB  extz WA
	ld	hl, wa                                  ; FC6BAD  ld HL,WA
	ld	bc, (0xE082:24)                        ; FC6BAF  ld BC,(0x00e082)
	extz	xbc                                   ; FC6BB4  extz XBC
	ld	iy, (xbc+11)                            ; FC6BB6  ld IY,(XBC+0x0b)
	ld	de, wa                                  ; FC6BB9  ld DE,WA
	add	de, iy                                 ; FC6BBB  add DE,IY
	ld	wa, (xix)                               ; FC6BBD  ld WA,(XIX)
	extz	xwa                                   ; FC6BBF  extz XWA
	ld	(xwa+28), de                            ; FC6BC1  ld (XWA+0x1c),DE
	jrl sub_FC6803__FC6C35                     ; FC6BC4  jrl T,0xfc6c35
sub_FC6803__FC6BC7:
	ld	xbc, (xiz+12)                           ; FC6BC7  ld XBC,(XIZ+0x0c)
	ld	a, (xbc+22)                             ; FC6BCA  ld A,(XBC+0x16)
	res	7, a                                   ; FC6BCD  res 0x07,A
	extz	wa                                    ; FC6BD0  extz WA
	ld	hl, wa                                  ; FC6BD2  ld HL,WA
	ld	bc, (0xE082:24)                        ; FC6BD4  ld BC,(0x00e082)
	extz	xbc                                   ; FC6BD9  extz XBC
	ld	iy, (xbc+11)                            ; FC6BDB  ld IY,(XBC+0x0b)
	ld	de, wa                                  ; FC6BDE  ld DE,WA
	sub	de, iy                                 ; FC6BE0  sub DE,IY
	ld	wa, (xix)                               ; FC6BE2  ld WA,(XIX)
	extz	xwa                                   ; FC6BE4  extz XWA
	ld	(xwa+26), de                            ; FC6BE6  ld (XWA+0x1a),DE
	ld	xbc, (xiz+12)                           ; FC6BE9  ld XBC,(XIZ+0x0c)
	ld	a, (xbc+32)                             ; FC6BEC  ld A,(XBC+0x20)
	res	7, a                                   ; FC6BEF  res 0x07,A
	extz	wa                                    ; FC6BF2  extz WA
	ld	hl, wa                                  ; FC6BF4  ld HL,WA
	ld	bc, (0xE082:24)                        ; FC6BF6  ld BC,(0x00e082)
	extz	xbc                                   ; FC6BFB  extz XBC
	ld	iy, (xbc+11)                            ; FC6BFD  ld IY,(XBC+0x0b)
	ld	de, wa                                  ; FC6C00  ld DE,WA
	sub	de, iy                                 ; FC6C02  sub DE,IY
	ld	wa, (xix)                               ; FC6C04  ld WA,(XIX)
	extz	xwa                                   ; FC6C06  extz XWA
	ld	(xwa+28), de                            ; FC6C08  ld (XWA+0x1c),DE
	jr sub_FC6803__FC6C35                      ; FC6C0B  jr T,0xfc6c35
sub_FC6803__FC6C0D:
	ld	xbc, (xiz+12)                           ; FC6C0D  ld XBC,(XIZ+0x0c)
	ld	a, (xbc+22)                             ; FC6C10  ld A,(XBC+0x16)
	res	7, a                                   ; FC6C13  res 0x07,A
	extz	wa                                    ; FC6C16  extz WA
	ld	hl, wa                                  ; FC6C18  ld HL,WA
	ld	iy, (xix)                               ; FC6C1A  ld IY,(XIX)
	extz	xiy                                   ; FC6C1C  extz XIY
	ld	(xiy+26), wa                            ; FC6C1E  ld (XIY+0x1a),WA
	ld	xbc, (xiz+12)                           ; FC6C21  ld XBC,(XIZ+0x0c)
	ld	a, (xbc+32)                             ; FC6C24  ld A,(XBC+0x20)
	res	7, a                                   ; FC6C27  res 0x07,A
	extz	wa                                    ; FC6C2A  extz WA
	ld	hl, wa                                  ; FC6C2C  ld HL,WA
	ld	iy, (xix)                               ; FC6C2E  ld IY,(XIX)
	extz	xiy                                   ; FC6C30  extz XIY
	ld	(xiy+28), wa                            ; FC6C32  ld (XIY+0x1c),WA
sub_FC6803__FC6C35:
	calr (0xFC46A8 - 0xFC6C38)                 ; FC6C35  calr 0xfc46a8
	ld	xbc, (xiz+12)                           ; FC6C38  ld XBC,(XIZ+0x0c)
	ld	d, (xbc+33)                             ; FC6C3B  ld D,(XBC+0x21)
	cps	d, 0                                   ; FC6C3E  cp D,0
	jr ge, sub_FC6803__FC6C4E                  ; FC6C40  jr GE,0xfc6c4e
	ld	a, d                                    ; FC6C42  ld A,D
	exts	wa                                    ; FC6C44  exts WA
	ld	hl, wa                                  ; FC6C46  ld HL,WA
	neg	wa                                     ; FC6C48  neg WA
	ld	hl, wa                                  ; FC6C4A  ld HL,WA
	jr sub_FC6803__FC6C54                      ; FC6C4C  jr T,0xfc6c54
sub_FC6803__FC6C4E:
	ld	c, d                                    ; FC6C4E  ld C,D
	exts	bc                                    ; FC6C50  exts BC
	ld	hl, bc                                  ; FC6C52  ld HL,BC
sub_FC6803__FC6C54:
	ld	bc, (xix)                               ; FC6C54  ld BC,(XIX)
	extz	xbc                                   ; FC6C56  extz XBC
	ld	a, (xbc+2)                              ; FC6C58  ld A,(XBC+0x02)
	and	a, 48                                  ; FC6C5B  and A,0x30
	srl	a, 4                                   ; FC6C5E  srl 0x04,A
	extz	wa                                    ; FC6C61  extz WA
	cps	wa, 1                                  ; FC6C63  cp WA,1
	jr z, sub_FC6803__FC6C6D                   ; FC6C65  jr Z,0xfc6c6d
	cps	wa, 2                                  ; FC6C67  cp WA,2
	jr z, sub_FC6803__FC6C84                   ; FC6C69  jr Z,0xfc6c84
	jr sub_FC6803__FC6C9B                      ; FC6C6B  jr T,0xfc6c9b
sub_FC6803__FC6C6D:
	ld	bc, (0xE082:24)                        ; FC6C6D  ld BC,(0x00e082)
	extz	xbc                                   ; FC6C72  extz XBC
	ld	wa, (xbc+15)                            ; FC6C74  ld WA,(XBC+0x0f)
	ld	de, wa                                  ; FC6C77  ld DE,WA
	add	de, hl                                 ; FC6C79  add DE,HL
	ld	wa, (xix)                               ; FC6C7B  ld WA,(XIX)
	extz	xwa                                   ; FC6C7D  extz XWA
	ld	(xwa+30), de                            ; FC6C7F  ld (XWA+0x1e),DE
	jr sub_FC6803__FC6CA2                      ; FC6C82  jr T,0xfc6ca2
sub_FC6803__FC6C84:
	ld	bc, (0xE082:24)                        ; FC6C84  ld BC,(0x00e082)
	extz	xbc                                   ; FC6C89  extz XBC
	ld	wa, (xbc+15)                            ; FC6C8B  ld WA,(XBC+0x0f)
	ld	de, hl                                  ; FC6C8E  ld DE,HL
	sub	de, wa                                 ; FC6C90  sub DE,WA
	ld	wa, (xix)                               ; FC6C92  ld WA,(XIX)
	extz	xwa                                   ; FC6C94  extz XWA
	ld	(xwa+30), de                            ; FC6C96  ld (XWA+0x1e),DE
	jr sub_FC6803__FC6CA2                      ; FC6C99  jr T,0xfc6ca2
sub_FC6803__FC6C9B:
	ld	bc, (xix)                               ; FC6C9B  ld BC,(XIX)
	extz	xbc                                   ; FC6C9D  extz XBC
	ld	(xbc+30), hl                            ; FC6C9F  ld (XBC+0x1e),HL
sub_FC6803__FC6CA2:
	pop	xix                                    ; FC6CA2  pop XIX
	popw	de                                    ; FC6CA3  pop DE
	popw	hl                                    ; FC6CA4  pop HL
	unlk32 xiz                                 ; FC6CA5  unlk XIZ
	ret                                        ; FC6CA7  ret
; --------------------------------------------------------------------------
; sub_FC6CA8 -- 0xFC6CA8..0xFC6CE9 (66 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFC74EC
; Inputs:  no frame and no argument slot read.
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFC6CA8-0xFC6CE9
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC6CA8:
	pushw	hl                                   ; FC6CA8  push HL
	push	xde                                   ; FC6CA9  push XDE
	push	xix                                   ; FC6CAA  push XIX
	lda	xix, (0xE082:24)                       ; FC6CAB  lda XIX,0x00e082
	ld	de, (xix)                               ; FC6CB0  ld DE,(XIX)
	add	de, 19                                 ; FC6CB2  add DE,0x0013
	ldb	h, 0                                   ; FC6CB6  ld H,0x00
sub_FC6CA8__FC6CB8:
	extz	xde                                   ; FC6CB8  extz XDE
	ld	(xde+9), h                              ; FC6CBA  ld (XDE+0x09),H
	extpfx5 0x9A, 0x07, 0x3C, 0x8F, 0xFF       ; FC6CBD  and (XDE+0x07),0xff8f
	extpfx5 0xBA, 0x12, 0x02, 0x00, 0x00       ; FC6CC2  ld (XDE+0x12),0x0000
	extpfx5 0xBA, 0x14, 0x02, 0x00, 0x00       ; FC6CC7  ld (XDE+0x14),0x0000
	inc	1, h                                   ; FC6CCC  inc 1,H
	add	de, 42                                 ; FC6CCE  add DE,0x002a
	cps	h, 4                                   ; FC6CD2  cp H,4
	jr c, sub_FC6CA8__FC6CB8                   ; FC6CD4  jr C,0xfc6cb8
	ld	bc, (xix)                               ; FC6CD6  ld BC,(XIX)
	extz	xbc                                   ; FC6CD8  extz XBC
	ld	(xbc+17), 0x7F                          ; FC6CDA  ld (XBC+0x11),0x7f
	ld	bc, (xix)                               ; FC6CDE  ld BC,(XIX)
	extz	xbc                                   ; FC6CE0  extz XBC
	ld	(xbc+18), 0x7F                          ; FC6CE2  ld (XBC+0x12),0x7f
	pop	xix                                    ; FC6CE6  pop XIX
	pop	xde                                    ; FC6CE7  pop XDE
	popw	hl                                    ; FC6CE8  pop HL
	ret                                        ; FC6CE9  ret
; --------------------------------------------------------------------------
; sub_FC6CEA -- 0xFC6CEA..0xFC6D2B (66 bytes)
;
; Called from: no site outside this module.
;          2 site(s) inside this module:
;          0xFC7507 0xFC7A74
; Inputs:  no frame and no argument slot read.
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFC6CEA-0xFC6D2B
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC6CEA:
	pushw	hl                                   ; FC6CEA  push HL
	push	xde                                   ; FC6CEB  push XDE
	push	xix                                   ; FC6CEC  push XIX
	lda	xix, (0xE082:24)                       ; FC6CED  lda XIX,0x00e082
	ld	de, (xix)                               ; FC6CF2  ld DE,(XIX)
	add	de, 19                                 ; FC6CF4  add DE,0x0013
	ldb	h, 0                                   ; FC6CF8  ld H,0x00
sub_FC6CEA__FC6CFA:
	extz	xde                                   ; FC6CFA  extz XDE
	ld	(xde+9), h                              ; FC6CFC  ld (XDE+0x09),H
	extpfx5 0x9A, 0x07, 0x3C, 0x8F, 0xFF       ; FC6CFF  and (XDE+0x07),0xff8f
	extpfx5 0xBA, 0x12, 0x02, 0x00, 0x00       ; FC6D04  ld (XDE+0x12),0x0000
	extpfx5 0xBA, 0x14, 0x02, 0x00, 0x00       ; FC6D09  ld (XDE+0x14),0x0000
	inc	1, h                                   ; FC6D0E  inc 1,H
	add	de, 42                                 ; FC6D10  add DE,0x002a
	cps	h, 2                                   ; FC6D14  cp H,2
	jr c, sub_FC6CEA__FC6CFA                   ; FC6D16  jr C,0xfc6cfa
	ld	bc, (xix)                               ; FC6D18  ld BC,(XIX)
	extz	xbc                                   ; FC6D1A  extz XBC
	ld	(xbc+17), 0x7F                          ; FC6D1C  ld (XBC+0x11),0x7f
	ld	bc, (xix)                               ; FC6D20  ld BC,(XIX)
	extz	xbc                                   ; FC6D22  extz XBC
	ld	(xbc+18), 0x7F                          ; FC6D24  ld (XBC+0x12),0x7f
	pop	xix                                    ; FC6D28  pop XIX
	pop	xde                                    ; FC6D29  pop XDE
	popw	hl                                    ; FC6D2A  pop HL
	ret                                        ; FC6D2B  ret
; --------------------------------------------------------------------------
; sub_FC6D2C -- 0xFC6D2C..0xFC6D6D (66 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFC7516
; Inputs:  no frame and no argument slot read.
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFC6D2C-0xFC6D6D
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC6D2C:
	pushw	hl                                   ; FC6D2C  push HL
	push	xde                                   ; FC6D2D  push XDE
	push	xix                                   ; FC6D2E  push XIX
	lda	xix, (0xE082:24)                       ; FC6D2F  lda XIX,0x00e082
	ld	de, (xix)                               ; FC6D34  ld DE,(XIX)
	add	de, 0x67                               ; FC6D36  add DE,0x0067
	ldb	h, 2                                   ; FC6D3A  ld H,0x02
sub_FC6D2C__FC6D3C:
	extz	xde                                   ; FC6D3C  extz XDE
	ld	(xde+9), h                              ; FC6D3E  ld (XDE+0x09),H
	extpfx5 0x9A, 0x07, 0x3C, 0x8F, 0xFF       ; FC6D41  and (XDE+0x07),0xff8f
	extpfx5 0xBA, 0x12, 0x02, 0x00, 0x00       ; FC6D46  ld (XDE+0x12),0x0000
	extpfx5 0xBA, 0x14, 0x02, 0x00, 0x00       ; FC6D4B  ld (XDE+0x14),0x0000
	inc	1, h                                   ; FC6D50  inc 1,H
	add	de, 42                                 ; FC6D52  add DE,0x002a
	cps	h, 4                                   ; FC6D56  cp H,4
	jr c, sub_FC6D2C__FC6D3C                   ; FC6D58  jr C,0xfc6d3c
	ld	bc, (xix)                               ; FC6D5A  ld BC,(XIX)
	extz	xbc                                   ; FC6D5C  extz XBC
	ld	(xbc+17), 0x7F                          ; FC6D5E  ld (XBC+0x11),0x7f
	ld	bc, (xix)                               ; FC6D62  ld BC,(XIX)
	extz	xbc                                   ; FC6D64  extz XBC
	ld	(xbc+18), 0x7F                          ; FC6D66  ld (XBC+0x12),0x7f
	pop	xix                                    ; FC6D6A  pop XIX
	pop	xde                                    ; FC6D6B  pop XDE
	popw	hl                                    ; FC6D6C  pop HL
	ret                                        ; FC6D6D  ret
; --------------------------------------------------------------------------
; sub_FC6D6E -- 0xFC6D6E..0xFC6FFC (655 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFC74F6
; Inputs:  frame `link XIZ,-34`; no positive frame slot is read
; Outputs: writes 0x00E093, 0x00E095
;          reads 0x00E082
; Calls:   0xFC4269 = sub_FC4269
; Evidence: the listing below is the byte-identical round-trip of 0xFC6D6E-0xFC6FFC
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC6D6E:
	link32 0xEE, 0x0C, 0xDE, 0xFF              ; FC6D6E  link XIZ,0xffde
	pushw	hl                                   ; FC6D72  push HL
	pushw	de                                   ; FC6D73  push DE
	push	xix                                   ; FC6D74  push XIX
	ld	bc, (0xE082:24)                        ; FC6D75  ld BC,(0x00e082)
	add	bc, 19                                 ; FC6D7A  add BC,0x0013
	ld	(xiz-22), bc                            ; FC6D7E  ld (XIZ+0xea),BC
	ldb	d, 0xFF                                ; FC6D81  ld D,0xff
	ldb	h, 0                                   ; FC6D83  ld H,0x00
	ld	(xiz-23), 0                             ; FC6D85  ld (XIZ+0xe9),0x00
sub_FC6D6E__FC6D89:
	ld	bc, (xiz-22)                            ; FC6D89  ld BC,(XIZ+0xea)
	extz	xbc                                   ; FC6D8C  extz XBC
	extpfx2 0xB1, 0xCF                         ; FC6D8E  bit 7,(XBC)
	jr z, sub_FC6D6E__FC6D9C                   ; FC6D90  jr Z,0xfc6d9c
	inc	1, h                                   ; FC6D92  inc 1,H
	cp	d, 0xFF                                 ; FC6D94  cp D,0xff
	jr nz, sub_FC6D6E__FC6D9C                  ; FC6D97  jr NZ,0xfc6d9c
	ld	d, (xiz-23)                             ; FC6D99  ld D,(XIZ+0xe9)
sub_FC6D6E__FC6D9C:
	incm8	1, (xiz-23)                          ; FC6D9C  inc 1,(XIZ+0xe9)
	extpfx5 0x9E, 0xEA, 0x38, 0x2A, 0x00       ; FC6D9F  add (XIZ+0xea),0x002a
	cp (xiz-23), 0x04                          ; FC6DA4  cp (XIZ+0xe9),0x04
	jr c, sub_FC6D6E__FC6D89                   ; FC6DA8  jr C,0xfc6d89
	ld	c, h                                    ; FC6DAA  ld C,H
	extz	bc                                    ; FC6DAC  extz BC
	cps	bc, 0                                  ; FC6DAE  cp BC,0
	jr z, sub_FC6D6E__FC6DBC                   ; FC6DB0  jr Z,0xfc6dbc
	cps	bc, 3                                  ; FC6DB2  cp BC,3
	jr z, sub_FC6D6E__FC6DC0                   ; FC6DB4  jr Z,0xfc6dc0
	cps	bc, 4                                  ; FC6DB6  cp BC,4
	jr z, sub_FC6D6E__FC6DD8                   ; FC6DB8  jr Z,0xfc6dd8
	jr sub_FC6D6E__FC6DF0                      ; FC6DBA  jr T,0xfc6df0
sub_FC6D6E__FC6DBC:
	ldb	d, 0                                   ; FC6DBC  ld D,0x00
	jr sub_FC6D6E__FC6DF0                      ; FC6DBE  jr T,0xfc6df0
sub_FC6D6E__FC6DC0:
	ld	bc, (0xE082:24)                        ; FC6DC0  ld BC,(0x00e082)
	extz	xbc                                   ; FC6DC5  extz XBC
	ld	(xbc+17), 86                            ; FC6DC7  ld (XBC+0x11),0x56
	ld	bc, (0xE082:24)                        ; FC6DCB  ld BC,(0x00e082)
	extz	xbc                                   ; FC6DD0  extz XBC
	ld	(xbc+18), 87                            ; FC6DD2  ld (XBC+0x12),0x57
	jr sub_FC6D6E__FC6E06                      ; FC6DD6  jr T,0xfc6e06
sub_FC6D6E__FC6DD8:
	ld	bc, (0xE082:24)                        ; FC6DD8  ld BC,(0x00e082)
	extz	xbc                                   ; FC6DDD  extz XBC
	ld	(xbc+17), 80                            ; FC6DDF  ld (XBC+0x11),0x50
	ld	bc, (0xE082:24)                        ; FC6DE3  ld BC,(0x00e082)
	extz	xbc                                   ; FC6DE8  extz XBC
	ld	(xbc+18), 80                            ; FC6DEA  ld (XBC+0x12),0x50
	jr sub_FC6D6E__FC6E06                      ; FC6DEE  jr T,0xfc6e06
sub_FC6D6E__FC6DF0:
	ld	bc, (0xE082:24)                        ; FC6DF0  ld BC,(0x00e082)
	extz	xbc                                   ; FC6DF5  extz XBC
	ld	(xbc+17), 0x7F                          ; FC6DF7  ld (XBC+0x11),0x7f
	ld	bc, (0xE082:24)                        ; FC6DFB  ld BC,(0x00e082)
	extz	xbc                                   ; FC6E00  extz XBC
	ld	(xbc+18), 0x7F                          ; FC6E02  ld (XBC+0x12),0x7f
sub_FC6D6E__FC6E06:
	ld	bc, (0xE082:24)                        ; FC6E06  ld BC,(0x00e082)
	add	bc, 19                                 ; FC6E0B  add BC,0x0013
	ld	(xiz-22), bc                            ; FC6E0F  ld (XIZ+0xea),BC
	sub	xwa, xwa                               ; FC6E12  sub XWA,XWA
	inc	4, xwa                                 ; FC6E14  inc 4,XWA
	ld	(xiz-12), xwa                           ; FC6E16  ld (XIZ+0xf4),XWA
	sub	xiy, xiy                               ; FC6E19  sub XIY,XIY
	inc	6, xiy                                 ; FC6E1B  inc 6,XIY
	ld	(xiz-16), xiy                           ; FC6E1D  ld (XIZ+0xf0),XIY
	ld	xbc, 20                                 ; FC6E20  ld XBC,0x00000014
	ld	(xiz-20), xbc                           ; FC6E25  ld (XIZ+0xec),XBC
	ld	xix, 22                                 ; FC6E28  ld XIX,0x00000016
	ld	xbc, 36                                 ; FC6E2D  ld XBC,0x00000024
	ld	(xiz-4), xbc                            ; FC6E32  ld (XIZ+0xfc),XBC
	ld	xbc, 38                                 ; FC6E35  ld XBC,0x00000026
	ld	(xiz-8), xbc                            ; FC6E3A  ld (XIZ+0xf8),XBC
	ld	(xiz-23), 4                             ; FC6E3D  ld (XIZ+0xe9),0x04
sub_FC6D6E__FC6E41:
	ld	bc, (xiz-22)                            ; FC6E41  ld BC,(XIZ+0xea)
	extz	xbc                                   ; FC6E44  extz XBC
	ld	(xbc+9), d                              ; FC6E46  ld (XBC+0x09),D
	ld	bc, (xiz-22)                            ; FC6E49  ld BC,(XIZ+0xea)
	extz	xbc                                   ; FC6E4C  extz XBC
	extpfx5 0x99, 0x07, 0x3C, 0x8F, 0xFF       ; FC6E4E  and (XBC+0x07),0xff8f
	ld	bc, (xiz-22)                            ; FC6E53  ld BC,(XIZ+0xea)
	extz	xbc                                   ; FC6E56  extz XBC
	ld	wa, (xbc+7)                             ; FC6E58  ld WA,(XBC+0x07)
	set	5, wa                                  ; FC6E5B  set 0x05,WA
	ld	(xbc+7), wa                             ; FC6E5E  ld (XBC+0x07),WA
	ld	bc, (xiz-22)                            ; FC6E61  ld BC,(XIZ+0xea)
	extz	xbc                                   ; FC6E64  extz XBC
	ld	xwa, (xbc+3)                            ; FC6E66  ld XWA,(XBC+0x03)
	ld	(xiz-30), xwa                           ; FC6E69  ld (XIZ+0xe2),XWA
	ld	c, (xwa+19)                             ; FC6E6C  ld C,(XWA+0x13)
	extz	bc                                    ; FC6E6F  extz BC
	extz	xbc                                   ; FC6E71  extz XBC
	add	xbc, 0xFDF760                          ; FC6E73  add XBC,0x00fdf760
	ld	a, (xbc)                                ; FC6E79  ld A,(XBC)
	extz	wa                                    ; FC6E7B  extz WA
	ld	hl, wa                                  ; FC6E7D  ld HL,WA
	sll	wa, 8                                  ; FC6E7F  sll 0x08,WA
	or	wa, hl                                  ; FC6E82  or WA,HL
	ld	(xiz-32), wa                            ; FC6E84  ld (XIZ+0xe0),WA
	and	wa, 0xFF00                             ; FC6E87  and WA,0xff00
	lda	xbc, (0xE093:24)                       ; FC6E8B  lda XBC,0x00e093
	extpfx3 0xAE, 0xF4, 0x81                   ; FC6E90  add XBC,(XIZ+0xf4)
	ld	(xbc), wa                               ; FC6E93  ld (XBC),WA
	ld	bc, (xiz-32)                            ; FC6E95  ld BC,(XIZ+0xe0)
	sll	bc, 8                                  ; FC6E98  sll 0x08,BC
	lda	xwa, (0xE093:24)                       ; FC6E9B  lda XWA,0x00e093
	extpfx3 0xAE, 0xF0, 0x80                   ; FC6EA0  add XWA,(XIZ+0xf0)
	ld	(xwa), bc                               ; FC6EA3  ld (XWA),BC
	lda	xbc, (0xE093:24)                       ; FC6EA5  lda XBC,0x00e093
	extpfx3 0xAE, 0xEC, 0x81                   ; FC6EAA  add XBC,(XIZ+0xec)
	extpfx4 0xB1, 0x02, 0x00, 0x80             ; FC6EAD  ld (XBC),0x8000
	ld	bc, (xiz-22)                            ; FC6EB1  ld BC,(XIZ+0xea)
	extz	xbc                                   ; FC6EB4  extz XBC
	ld	xwa, (xbc+3)                            ; FC6EB6  ld XWA,(XBC+0x03)
	ld	e, (xwa+33)                             ; FC6EB9  ld E,(XWA+0x21)
	cps	e, 0                                   ; FC6EBC  cp E,0
	jr ge, sub_FC6D6E__FC6EEE                  ; FC6EBE  jr GE,0xfc6eee
	ld	a, e                                    ; FC6EC0  ld A,E
	exts	wa                                    ; FC6EC2  exts WA
	ld	hl, wa                                  ; FC6EC4  ld HL,WA
	neg	wa                                     ; FC6EC6  neg WA
	ld	hl, wa                                  ; FC6EC8  ld HL,WA
	cp	wa, 0x64                                ; FC6ECA  cp WA,0x0064
	jr le, sub_FC6D6E__FC6ED5                  ; FC6ECE  jr LE,0xfc6ed5
	ldw	hl, 0x64                               ; FC6ED0  ld HL,0x0064
	jr sub_FC6D6E__FC6EDC                      ; FC6ED3  jr T,0xfc6edc
sub_FC6D6E__FC6ED5:
	cps	hl, 0                                  ; FC6ED5  cp HL,0
	jr ge, sub_FC6D6E__FC6EDC                  ; FC6ED7  jr GE,0xfc6edc
	ldw	hl, 0                                  ; FC6ED9  ld HL,0x0000
sub_FC6D6E__FC6EDC:
	ldw	bc, 2                                  ; FC6EDC  ld BC,0x0002
	muls	xbc, xhl                              ; FC6EDF  muls XBC,HL
	add	xbc, 0xFDFECC                          ; FC6EE1  add XBC,0x00fdfecc
	ld	bc, (xbc)                               ; FC6EE7  ld BC,(XBC)
	ld	(xiz-26), bc                            ; FC6EE9  ld (XIZ+0xe6),BC
	jr sub_FC6D6E__FC6F16                      ; FC6EEC  jr T,0xfc6f16
sub_FC6D6E__FC6EEE:
	ld	c, e                                    ; FC6EEE  ld C,E
	exts	bc                                    ; FC6EF0  exts BC
	ld	hl, bc                                  ; FC6EF2  ld HL,BC
	cp	bc, 0x64                                ; FC6EF4  cp BC,0x0064
	jr le, sub_FC6D6E__FC6EFF                  ; FC6EF8  jr LE,0xfc6eff
	ldw	hl, 0x64                               ; FC6EFA  ld HL,0x0064
	jr sub_FC6D6E__FC6F06                      ; FC6EFD  jr T,0xfc6f06
sub_FC6D6E__FC6EFF:
	cps	hl, 0                                  ; FC6EFF  cp HL,0
	jr ge, sub_FC6D6E__FC6F06                  ; FC6F01  jr GE,0xfc6f06
	ldw	hl, 0                                  ; FC6F03  ld HL,0x0000
sub_FC6D6E__FC6F06:
	ldw	bc, 2                                  ; FC6F06  ld BC,0x0002
	muls	xbc, xhl                              ; FC6F09  muls XBC,HL
	add	xbc, 0xFDFECC                          ; FC6F0B  add XBC,0x00fdfecc
	ld	bc, (xbc)                               ; FC6F11  ld BC,(XBC)
	ld	(xiz-26), bc                            ; FC6F13  ld (XIZ+0xe6),BC
sub_FC6D6E__FC6F16:
	lda	xbc, (0xE093:24)                       ; FC6F16  lda XBC,0x00e093
	add	xbc, xix                               ; FC6F1B  add XBC,XIX
	ld	wa, (xiz-26)                            ; FC6F1D  ld WA,(XIZ+0xe6)
	ld	(xbc), wa                               ; FC6F20  ld (XBC),WA
	ld	bc, (xiz-22)                            ; FC6F22  ld BC,(XIZ+0xea)
	extz	xbc                                   ; FC6F25  extz XBC
	ld	hl, (xbc+14)                            ; FC6F27  ld HL,(XBC+0x0e)
	ld	xwa, (xiz-4)                            ; FC6F2A  ld XWA,(XIZ+0xfc)
	ld	(xiz-30), xwa                           ; FC6F2D  ld (XIZ+0xe2),XWA
	add	xwa, 0xE093                            ; FC6F30  add XWA,0x0000e093
	ld	(xwa), hl                               ; FC6F36  ld (XWA),HL
	ld	bc, (xiz-22)                            ; FC6F38  ld BC,(XIZ+0xea)
	extz	xbc                                   ; FC6F3B  extz XBC
	ld	hl, (xbc+16)                            ; FC6F3D  ld HL,(XBC+0x10)
	ld	xwa, (xiz-8)                            ; FC6F40  ld XWA,(XIZ+0xf8)
	ld	(xiz-34), xwa                           ; FC6F43  ld (XIZ+0xde),XWA
	add	xwa, 0xE093                            ; FC6F46  add XWA,0x0000e093
	ld	(xwa), hl                               ; FC6F4C  ld (XWA),HL
	decm8	1, (xiz-23)                          ; FC6F4E  dec 1,(XIZ+0xe9)
	ld	xbc, (xiz-34)                           ; FC6F51  ld XBC,(XIZ+0xde)
	inc	4, xbc                                 ; FC6F54  inc 4,XBC
	ld	(xiz-8), xbc                            ; FC6F56  ld (XIZ+0xf8),XBC
	ld	xwa, (xiz-30)                           ; FC6F59  ld XWA,(XIZ+0xe2)
	inc	4, xwa                                 ; FC6F5C  inc 4,XWA
	ld	(xiz-4), xwa                            ; FC6F5E  ld (XIZ+0xfc),XWA
	inc	4, xix                                 ; FC6F61  inc 4,XIX
	sub	xiy, xiy                               ; FC6F63  sub XIY,XIY
	inc	4, xiy                                 ; FC6F65  inc 4,XIY
	add	(xiz-20), xiy                          ; FC6F67  add (XIZ+0xec),XIY
	add	(xiz-16), xiy                          ; FC6F6A  add (XIZ+0xf0),XIY
	add	(xiz-12), xiy                          ; FC6F6D  add (XIZ+0xf4),XIY
	extpfx5 0x9E, 0xEA, 0x38, 0x2A, 0x00       ; FC6F70  add (XIZ+0xea),0x002a
	cp (xiz-23), 0x00                          ; FC6F75  cp (XIZ+0xe9),0x00
	jrl nz, sub_FC6D6E__FC6E41                 ; FC6F79  jrl NZ,0xfc6e41
	stiw_da	(0xE093), 0x200                    ; FC6F7C  ld (0x00e093),0x0200
	stiw_da	(0xE095), 8                        ; FC6F83  ld (0x00e095),0x0008
	lda	xbc, (0xE093:24)                       ; FC6F8A  lda XBC,0x00e093
	push	xbc                                   ; FC6F8F  push XBC
	calr (0xFC4269 - 0xFC6F93)                 ; FC6F90  calr 0xfc4269
	ld	bc, (0xE082:24)                        ; FC6F93  ld BC,(0x00e082)
	add	bc, 19                                 ; FC6F98  add BC,0x0013
	ld	(xiz-22), bc                            ; FC6F9C  ld (XIZ+0xea),BC
	ld	xix, 52                                 ; FC6F9F  ld XIX,0x00000034
	ld	xwa, 54                                 ; FC6FA4  ld XWA,0x00000036
	ld	(xiz-4), xwa                            ; FC6FA9  ld (XIZ+0xfc),XWA
	ld	(xiz-23), 4                             ; FC6FAC  ld (XIZ+0xe9),0x04
	pop	xiy                                    ; FC6FB0  pop XIY
sub_FC6D6E__FC6FB1:
	ld	(xiz-30), xix                           ; FC6FB1  ld (XIZ+0xe2),XIX
	lda	xbc, (0xE093:24)                       ; FC6FB4  lda XBC,0x00e093
	extpfx3 0xAE, 0xE2, 0x81                   ; FC6FB9  add XBC,(XIZ+0xe2)
	ld	wa, (xbc)                               ; FC6FBC  ld WA,(XBC)
	ld	bc, (xiz-22)                            ; FC6FBE  ld BC,(XIZ+0xea)
	extz	xbc                                   ; FC6FC1  extz XBC
	ld	(xbc+18), wa                            ; FC6FC3  ld (XBC+0x12),WA
	ld	xbc, (xiz-4)                            ; FC6FC6  ld XBC,(XIZ+0xfc)
	ld	(xiz-34), xbc                           ; FC6FC9  ld (XIZ+0xde),XBC
	add	xbc, 0xE093                            ; FC6FCC  add XBC,0x0000e093
	ld	bc, (xbc)                               ; FC6FD2  ld BC,(XBC)
	ld	wa, (xiz-22)                            ; FC6FD4  ld WA,(XIZ+0xea)
	extz	xwa                                   ; FC6FD7  extz XWA
	ld	(xwa+20), bc                            ; FC6FD9  ld (XWA+0x14),BC
	decm8	1, (xiz-23)                          ; FC6FDC  dec 1,(XIZ+0xe9)
	ld	xbc, (xiz-34)                           ; FC6FDF  ld XBC,(XIZ+0xde)
	inc	4, xbc                                 ; FC6FE2  inc 4,XBC
	ld	(xiz-4), xbc                            ; FC6FE4  ld (XIZ+0xfc),XBC
	ld	xix, (xiz-30)                           ; FC6FE7  ld XIX,(XIZ+0xe2)
	inc	4, xix                                 ; FC6FEA  inc 4,XIX
	extpfx5 0x9E, 0xEA, 0x38, 0x2A, 0x00       ; FC6FEC  add (XIZ+0xea),0x002a
	cp (xiz-23), 0x00                          ; FC6FF1  cp (XIZ+0xe9),0x00
	jr nz, sub_FC6D6E__FC6FB1                  ; FC6FF5  jr NZ,0xfc6fb1
	pop	xix                                    ; FC6FF7  pop XIX
	popw	de                                    ; FC6FF8  pop DE
	popw	hl                                    ; FC6FF9  pop HL
	unlk32 xiz                                 ; FC6FFA  unlk XIZ
	ret                                        ; FC6FFC  ret
; --------------------------------------------------------------------------
; sub_FC6FFD -- 0xFC6FFD..0xFC723E (578 bytes)
;
; Called from: no site outside this module.
;          2 site(s) inside this module:
;          0xFC7502 0xFC7A6F
; Inputs:  frame `link XIZ,-34`; no positive frame slot is read
; Outputs: writes 0x00E093, 0x00E095
;          reads 0x00E082
; Calls:   0xFC4269 = sub_FC4269
; Evidence: the listing below is the byte-identical round-trip of 0xFC6FFD-0xFC723E
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC6FFD:
	link32 0xEE, 0x0C, 0xDE, 0xFF              ; FC6FFD  link XIZ,0xffde
	pushw	hl                                   ; FC7001  push HL
	pushw	de                                   ; FC7002  push DE
	push	xix                                   ; FC7003  push XIX
	ld	bc, (0xE082:24)                        ; FC7004  ld BC,(0x00e082)
	add	bc, 19                                 ; FC7009  add BC,0x0013
	ld	(xiz-22), bc                            ; FC700D  ld (XIZ+0xea),BC
	ld	(xiz-23), 0                             ; FC7010  ld (XIZ+0xe9),0x00
	ldb	e, 0                                   ; FC7014  ld E,0x00
sub_FC6FFD__FC7016:
	ld	bc, (xiz-22)                            ; FC7016  ld BC,(XIZ+0xea)
	extz	xbc                                   ; FC7019  extz XBC
	extpfx2 0xB1, 0xCF                         ; FC701B  bit 7,(XBC)
	jr z, sub_FC6FFD__FC7024                   ; FC701D  jr Z,0xfc7024
	ld	e, (xiz-23)                             ; FC701F  ld E,(XIZ+0xe9)
	jr sub_FC6FFD__FC7032                      ; FC7022  jr T,0xfc7032
sub_FC6FFD__FC7024:
	incm8	1, (xiz-23)                          ; FC7024  inc 1,(XIZ+0xe9)
	extpfx5 0x9E, 0xEA, 0x38, 0x2A, 0x00       ; FC7027  add (XIZ+0xea),0x002a
	cp (xiz-23), 0x02                          ; FC702C  cp (XIZ+0xe9),0x02
	jr c, sub_FC6FFD__FC7016                   ; FC7030  jr C,0xfc7016
sub_FC6FFD__FC7032:
	ld	bc, (0xE082:24)                        ; FC7032  ld BC,(0x00e082)
	add	bc, 19                                 ; FC7037  add BC,0x0013
	ld	(xiz-22), bc                            ; FC703B  ld (XIZ+0xea),BC
	sub	xwa, xwa                               ; FC703E  sub XWA,XWA
	inc	4, xwa                                 ; FC7040  inc 4,XWA
	ld	(xiz-12), xwa                           ; FC7042  ld (XIZ+0xf4),XWA
	sub	xiy, xiy                               ; FC7045  sub XIY,XIY
	inc	6, xiy                                 ; FC7047  inc 6,XIY
	ld	(xiz-16), xiy                           ; FC7049  ld (XIZ+0xf0),XIY
	ld	xbc, 20                                 ; FC704C  ld XBC,0x00000014
	ld	(xiz-20), xbc                           ; FC7051  ld (XIZ+0xec),XBC
	ld	xix, 22                                 ; FC7054  ld XIX,0x00000016
	ld	xbc, 36                                 ; FC7059  ld XBC,0x00000024
	ld	(xiz-4), xbc                            ; FC705E  ld (XIZ+0xfc),XBC
	ld	xbc, 38                                 ; FC7061  ld XBC,0x00000026
	ld	(xiz-8), xbc                            ; FC7066  ld (XIZ+0xf8),XBC
	ld	(xiz-23), 2                             ; FC7069  ld (XIZ+0xe9),0x02
sub_FC6FFD__FC706D:
	ld	bc, (xiz-22)                            ; FC706D  ld BC,(XIZ+0xea)
	extz	xbc                                   ; FC7070  extz XBC
	ld	(xbc+9), e                              ; FC7072  ld (XBC+0x09),E
	ld	bc, (xiz-22)                            ; FC7075  ld BC,(XIZ+0xea)
	extz	xbc                                   ; FC7078  extz XBC
	extpfx5 0x99, 0x07, 0x3C, 0x8F, 0xFF       ; FC707A  and (XBC+0x07),0xff8f
	ld	bc, (xiz-22)                            ; FC707F  ld BC,(XIZ+0xea)
	extz	xbc                                   ; FC7082  extz XBC
	ld	wa, (xbc+7)                             ; FC7084  ld WA,(XBC+0x07)
	set	4, wa                                  ; FC7087  set 0x04,WA
	ld	(xbc+7), wa                             ; FC708A  ld (XBC+0x07),WA
	ld	bc, (xiz-22)                            ; FC708D  ld BC,(XIZ+0xea)
	extz	xbc                                   ; FC7090  extz XBC
	ld	xwa, (xbc+3)                            ; FC7092  ld XWA,(XBC+0x03)
	ld	(xiz-30), xwa                           ; FC7095  ld (XIZ+0xe2),XWA
	ld	c, (xwa+19)                             ; FC7098  ld C,(XWA+0x13)
	extz	bc                                    ; FC709B  extz BC
	extz	xbc                                   ; FC709D  extz XBC
	add	xbc, 0xFDF760                          ; FC709F  add XBC,0x00fdf760
	ld	a, (xbc)                                ; FC70A5  ld A,(XBC)
	extz	wa                                    ; FC70A7  extz WA
	ld	hl, wa                                  ; FC70A9  ld HL,WA
	sll	wa, 8                                  ; FC70AB  sll 0x08,WA
	or	wa, hl                                  ; FC70AE  or WA,HL
	ld	(xiz-32), wa                            ; FC70B0  ld (XIZ+0xe0),WA
	and	wa, 0xFF00                             ; FC70B3  and WA,0xff00
	lda	xbc, (0xE093:24)                       ; FC70B7  lda XBC,0x00e093
	extpfx3 0xAE, 0xF4, 0x81                   ; FC70BC  add XBC,(XIZ+0xf4)
	ld	(xbc), wa                               ; FC70BF  ld (XBC),WA
	ld	bc, (xiz-32)                            ; FC70C1  ld BC,(XIZ+0xe0)
	sll	bc, 8                                  ; FC70C4  sll 0x08,BC
	lda	xwa, (0xE093:24)                       ; FC70C7  lda XWA,0x00e093
	extpfx3 0xAE, 0xF0, 0x80                   ; FC70CC  add XWA,(XIZ+0xf0)
	ld	(xwa), bc                               ; FC70CF  ld (XWA),BC
	lda	xbc, (0xE093:24)                       ; FC70D1  lda XBC,0x00e093
	extpfx3 0xAE, 0xEC, 0x81                   ; FC70D6  add XBC,(XIZ+0xec)
	extpfx4 0xB1, 0x02, 0x00, 0x80             ; FC70D9  ld (XBC),0x8000
	ld	bc, (xiz-22)                            ; FC70DD  ld BC,(XIZ+0xea)
	extz	xbc                                   ; FC70E0  extz XBC
	ld	xwa, (xbc+3)                            ; FC70E2  ld XWA,(XBC+0x03)
	ld	d, (xwa+33)                             ; FC70E5  ld D,(XWA+0x21)
	cps	d, 0                                   ; FC70E8  cp D,0
	jr ge, sub_FC6FFD__FC711A                  ; FC70EA  jr GE,0xfc711a
	ld	a, d                                    ; FC70EC  ld A,D
	exts	wa                                    ; FC70EE  exts WA
	ld	hl, wa                                  ; FC70F0  ld HL,WA
	neg	wa                                     ; FC70F2  neg WA
	ld	hl, wa                                  ; FC70F4  ld HL,WA
	cp	wa, 0x64                                ; FC70F6  cp WA,0x0064
	jr le, sub_FC6FFD__FC7101                  ; FC70FA  jr LE,0xfc7101
	ldw	hl, 0x64                               ; FC70FC  ld HL,0x0064
	jr sub_FC6FFD__FC7108                      ; FC70FF  jr T,0xfc7108
sub_FC6FFD__FC7101:
	cps	hl, 0                                  ; FC7101  cp HL,0
	jr ge, sub_FC6FFD__FC7108                  ; FC7103  jr GE,0xfc7108
	ldw	hl, 0                                  ; FC7105  ld HL,0x0000
sub_FC6FFD__FC7108:
	ldw	bc, 2                                  ; FC7108  ld BC,0x0002
	muls	xbc, xhl                              ; FC710B  muls XBC,HL
	add	xbc, 0xFDFECC                          ; FC710D  add XBC,0x00fdfecc
	ld	bc, (xbc)                               ; FC7113  ld BC,(XBC)
	ld	(xiz-26), bc                            ; FC7115  ld (XIZ+0xe6),BC
	jr sub_FC6FFD__FC7142                      ; FC7118  jr T,0xfc7142
sub_FC6FFD__FC711A:
	ld	c, d                                    ; FC711A  ld C,D
	exts	bc                                    ; FC711C  exts BC
	ld	hl, bc                                  ; FC711E  ld HL,BC
	cp	bc, 0x64                                ; FC7120  cp BC,0x0064
	jr le, sub_FC6FFD__FC712B                  ; FC7124  jr LE,0xfc712b
	ldw	hl, 0x64                               ; FC7126  ld HL,0x0064
	jr sub_FC6FFD__FC7132                      ; FC7129  jr T,0xfc7132
sub_FC6FFD__FC712B:
	cps	hl, 0                                  ; FC712B  cp HL,0
	jr ge, sub_FC6FFD__FC7132                  ; FC712D  jr GE,0xfc7132
	ldw	hl, 0                                  ; FC712F  ld HL,0x0000
sub_FC6FFD__FC7132:
	ldw	bc, 2                                  ; FC7132  ld BC,0x0002
	muls	xbc, xhl                              ; FC7135  muls XBC,HL
	add	xbc, 0xFDFECC                          ; FC7137  add XBC,0x00fdfecc
	ld	bc, (xbc)                               ; FC713D  ld BC,(XBC)
	ld	(xiz-26), bc                            ; FC713F  ld (XIZ+0xe6),BC
sub_FC6FFD__FC7142:
	lda	xbc, (0xE093:24)                       ; FC7142  lda XBC,0x00e093
	add	xbc, xix                               ; FC7147  add XBC,XIX
	ld	wa, (xiz-26)                            ; FC7149  ld WA,(XIZ+0xe6)
	ld	(xbc), wa                               ; FC714C  ld (XBC),WA
	ld	bc, (xiz-22)                            ; FC714E  ld BC,(XIZ+0xea)
	extz	xbc                                   ; FC7151  extz XBC
	ld	hl, (xbc+14)                            ; FC7153  ld HL,(XBC+0x0e)
	ld	xwa, (xiz-4)                            ; FC7156  ld XWA,(XIZ+0xfc)
	ld	(xiz-30), xwa                           ; FC7159  ld (XIZ+0xe2),XWA
	add	xwa, 0xE093                            ; FC715C  add XWA,0x0000e093
	ld	(xwa), hl                               ; FC7162  ld (XWA),HL
	ld	bc, (xiz-22)                            ; FC7164  ld BC,(XIZ+0xea)
	extz	xbc                                   ; FC7167  extz XBC
	ld	hl, (xbc+16)                            ; FC7169  ld HL,(XBC+0x10)
	ld	xwa, (xiz-8)                            ; FC716C  ld XWA,(XIZ+0xf8)
	ld	(xiz-34), xwa                           ; FC716F  ld (XIZ+0xde),XWA
	add	xwa, 0xE093                            ; FC7172  add XWA,0x0000e093
	ld	(xwa), hl                               ; FC7178  ld (XWA),HL
	decm8	1, (xiz-23)                          ; FC717A  dec 1,(XIZ+0xe9)
	ld	xbc, (xiz-34)                           ; FC717D  ld XBC,(XIZ+0xde)
	inc	4, xbc                                 ; FC7180  inc 4,XBC
	ld	(xiz-8), xbc                            ; FC7182  ld (XIZ+0xf8),XBC
	ld	xwa, (xiz-30)                           ; FC7185  ld XWA,(XIZ+0xe2)
	inc	4, xwa                                 ; FC7188  inc 4,XWA
	ld	(xiz-4), xwa                            ; FC718A  ld (XIZ+0xfc),XWA
	inc	4, xix                                 ; FC718D  inc 4,XIX
	sub	xiy, xiy                               ; FC718F  sub XIY,XIY
	inc	4, xiy                                 ; FC7191  inc 4,XIY
	add	(xiz-20), xiy                          ; FC7193  add (XIZ+0xec),XIY
	add	(xiz-16), xiy                          ; FC7196  add (XIZ+0xf0),XIY
	add	(xiz-12), xiy                          ; FC7199  add (XIZ+0xf4),XIY
	extpfx5 0x9E, 0xEA, 0x38, 0x2A, 0x00       ; FC719C  add (XIZ+0xea),0x002a
	cp (xiz-23), 0x00                          ; FC71A1  cp (XIZ+0xe9),0x00
	jrl nz, sub_FC6FFD__FC706D                 ; FC71A5  jrl NZ,0xfc706d
	stiw_da	(0xE093), 0x400                    ; FC71A8  ld (0x00e093),0x0400
	stiw_da	(0xE095), 4                        ; FC71AF  ld (0x00e095),0x0004
	lda	xbc, (0xE093:24)                       ; FC71B6  lda XBC,0x00e093
	push	xbc                                   ; FC71BB  push XBC
	calr (0xFC4269 - 0xFC71BF)                 ; FC71BC  calr 0xfc4269
	ld	bc, (0xE082:24)                        ; FC71BF  ld BC,(0x00e082)
	add	bc, 19                                 ; FC71C4  add BC,0x0013
	ld	(xiz-22), bc                            ; FC71C8  ld (XIZ+0xea),BC
	ld	xwa, 52                                 ; FC71CB  ld XWA,0x00000034
	ld	(xiz-4), xwa                            ; FC71D0  ld (XIZ+0xfc),XWA
	ld	xix, 54                                 ; FC71D3  ld XIX,0x00000036
	ld	(xiz-23), 2                             ; FC71D8  ld (XIZ+0xe9),0x02
	pop	xiy                                    ; FC71DC  pop XIY
sub_FC6FFD__FC71DD:
	ld	xbc, (xiz-4)                            ; FC71DD  ld XBC,(XIZ+0xfc)
	ld	(xiz-30), xbc                           ; FC71E0  ld (XIZ+0xe2),XBC
	add	xbc, 0xE093                            ; FC71E3  add XBC,0x0000e093
	ld	bc, (xbc)                               ; FC71E9  ld BC,(XBC)
	ld	wa, (xiz-22)                            ; FC71EB  ld WA,(XIZ+0xea)
	extz	xwa                                   ; FC71EE  extz XWA
	ld	(xwa+18), bc                            ; FC71F0  ld (XWA+0x12),BC
	ld	(xiz-34), xix                           ; FC71F3  ld (XIZ+0xde),XIX
	lda	xbc, (0xE093:24)                       ; FC71F6  lda XBC,0x00e093
	extpfx3 0xAE, 0xDE, 0x81                   ; FC71FB  add XBC,(XIZ+0xde)
	ld	wa, (xbc)                               ; FC71FE  ld WA,(XBC)
	ld	bc, (xiz-22)                            ; FC7200  ld BC,(XIZ+0xea)
	extz	xbc                                   ; FC7203  extz XBC
	ld	(xbc+20), wa                            ; FC7205  ld (XBC+0x14),WA
	decm8	1, (xiz-23)                          ; FC7208  dec 1,(XIZ+0xe9)
	ld	xix, (xiz-34)                           ; FC720B  ld XIX,(XIZ+0xde)
	inc	4, xix                                 ; FC720E  inc 4,XIX
	ld	xbc, (xiz-30)                           ; FC7210  ld XBC,(XIZ+0xe2)
	inc	4, xbc                                 ; FC7213  inc 4,XBC
	ld	(xiz-4), xbc                            ; FC7215  ld (XIZ+0xfc),XBC
	extpfx5 0x9E, 0xEA, 0x38, 0x2A, 0x00       ; FC7218  add (XIZ+0xea),0x002a
	cp (xiz-23), 0x00                          ; FC721D  cp (XIZ+0xe9),0x00
	jr nz, sub_FC6FFD__FC71DD                  ; FC7221  jr NZ,0xfc71dd
	ld	wa, (0xE082:24)                        ; FC7223  ld WA,(0x00e082)
	extz	xwa                                   ; FC7228  extz XWA
	ld	(xwa+17), 0x7F                          ; FC722A  ld (XWA+0x11),0x7f
	ld	bc, (0xE082:24)                        ; FC722E  ld BC,(0x00e082)
	extz	xbc                                   ; FC7233  extz XBC
	ld	(xbc+18), 0x7F                          ; FC7235  ld (XBC+0x12),0x7f
	pop	xix                                    ; FC7239  pop XIX
	popw	de                                    ; FC723A  pop DE
	popw	hl                                    ; FC723B  pop HL
	unlk32 xiz                                 ; FC723C  unlk XIZ
	ret                                        ; FC723E  ret
; --------------------------------------------------------------------------
; sub_FC723F -- 0xFC723F..0xFC7480 (578 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFC7511
; Inputs:  frame `link XIZ,-34`; no positive frame slot is read
; Outputs: writes 0x00E093, 0x00E095
;          reads 0x00E082
; Calls:   0xFC4269 = sub_FC4269
; Evidence: the listing below is the byte-identical round-trip of 0xFC723F-0xFC7480
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC723F:
	link32 0xEE, 0x0C, 0xDE, 0xFF              ; FC723F  link XIZ,0xffde
	pushw	hl                                   ; FC7243  push HL
	pushw	de                                   ; FC7244  push DE
	push	xix                                   ; FC7245  push XIX
	ld	bc, (0xE082:24)                        ; FC7246  ld BC,(0x00e082)
	add	bc, 0x67                               ; FC724B  add BC,0x0067
	ld	(xiz-22), bc                            ; FC724F  ld (XIZ+0xea),BC
	ld	(xiz-23), 2                             ; FC7252  ld (XIZ+0xe9),0x02
	ldb	e, 2                                   ; FC7256  ld E,0x02
sub_FC723F__FC7258:
	ld	bc, (xiz-22)                            ; FC7258  ld BC,(XIZ+0xea)
	extz	xbc                                   ; FC725B  extz XBC
	extpfx2 0xB1, 0xCF                         ; FC725D  bit 7,(XBC)
	jr z, sub_FC723F__FC7266                   ; FC725F  jr Z,0xfc7266
	ld	e, (xiz-23)                             ; FC7261  ld E,(XIZ+0xe9)
	jr sub_FC723F__FC7274                      ; FC7264  jr T,0xfc7274
sub_FC723F__FC7266:
	incm8	1, (xiz-23)                          ; FC7266  inc 1,(XIZ+0xe9)
	extpfx5 0x9E, 0xEA, 0x38, 0x2A, 0x00       ; FC7269  add (XIZ+0xea),0x002a
	cp (xiz-23), 0x04                          ; FC726E  cp (XIZ+0xe9),0x04
	jr c, sub_FC723F__FC7258                   ; FC7272  jr C,0xfc7258
sub_FC723F__FC7274:
	ld	bc, (0xE082:24)                        ; FC7274  ld BC,(0x00e082)
	add	bc, 0x67                               ; FC7279  add BC,0x0067
	ld	(xiz-22), bc                            ; FC727D  ld (XIZ+0xea),BC
	sub	xwa, xwa                               ; FC7280  sub XWA,XWA
	inc	4, xwa                                 ; FC7282  inc 4,XWA
	ld	(xiz-12), xwa                           ; FC7284  ld (XIZ+0xf4),XWA
	sub	xiy, xiy                               ; FC7287  sub XIY,XIY
	inc	6, xiy                                 ; FC7289  inc 6,XIY
	ld	(xiz-16), xiy                           ; FC728B  ld (XIZ+0xf0),XIY
	ld	xbc, 20                                 ; FC728E  ld XBC,0x00000014
	ld	(xiz-20), xbc                           ; FC7293  ld (XIZ+0xec),XBC
	ld	xix, 22                                 ; FC7296  ld XIX,0x00000016
	ld	xbc, 36                                 ; FC729B  ld XBC,0x00000024
	ld	(xiz-4), xbc                            ; FC72A0  ld (XIZ+0xfc),XBC
	ld	xbc, 38                                 ; FC72A3  ld XBC,0x00000026
	ld	(xiz-8), xbc                            ; FC72A8  ld (XIZ+0xf8),XBC
	ld	(xiz-23), 2                             ; FC72AB  ld (XIZ+0xe9),0x02
sub_FC723F__FC72AF:
	ld	bc, (xiz-22)                            ; FC72AF  ld BC,(XIZ+0xea)
	extz	xbc                                   ; FC72B2  extz XBC
	ld	(xbc+9), e                              ; FC72B4  ld (XBC+0x09),E
	ld	bc, (xiz-22)                            ; FC72B7  ld BC,(XIZ+0xea)
	extz	xbc                                   ; FC72BA  extz XBC
	extpfx5 0x99, 0x07, 0x3C, 0x8F, 0xFF       ; FC72BC  and (XBC+0x07),0xff8f
	ld	bc, (xiz-22)                            ; FC72C1  ld BC,(XIZ+0xea)
	extz	xbc                                   ; FC72C4  extz XBC
	ld	wa, (xbc+7)                             ; FC72C6  ld WA,(XBC+0x07)
	set	4, wa                                  ; FC72C9  set 0x04,WA
	ld	(xbc+7), wa                             ; FC72CC  ld (XBC+0x07),WA
	ld	bc, (xiz-22)                            ; FC72CF  ld BC,(XIZ+0xea)
	extz	xbc                                   ; FC72D2  extz XBC
	ld	xwa, (xbc+3)                            ; FC72D4  ld XWA,(XBC+0x03)
	ld	(xiz-30), xwa                           ; FC72D7  ld (XIZ+0xe2),XWA
	ld	c, (xwa+19)                             ; FC72DA  ld C,(XWA+0x13)
	extz	bc                                    ; FC72DD  extz BC
	extz	xbc                                   ; FC72DF  extz XBC
	add	xbc, 0xFDF760                          ; FC72E1  add XBC,0x00fdf760
	ld	a, (xbc)                                ; FC72E7  ld A,(XBC)
	extz	wa                                    ; FC72E9  extz WA
	ld	hl, wa                                  ; FC72EB  ld HL,WA
	sll	wa, 8                                  ; FC72ED  sll 0x08,WA
	or	wa, hl                                  ; FC72F0  or WA,HL
	ld	(xiz-32), wa                            ; FC72F2  ld (XIZ+0xe0),WA
	and	wa, 0xFF00                             ; FC72F5  and WA,0xff00
	lda	xbc, (0xE093:24)                       ; FC72F9  lda XBC,0x00e093
	extpfx3 0xAE, 0xF4, 0x81                   ; FC72FE  add XBC,(XIZ+0xf4)
	ld	(xbc), wa                               ; FC7301  ld (XBC),WA
	ld	bc, (xiz-32)                            ; FC7303  ld BC,(XIZ+0xe0)
	sll	bc, 8                                  ; FC7306  sll 0x08,BC
	lda	xwa, (0xE093:24)                       ; FC7309  lda XWA,0x00e093
	extpfx3 0xAE, 0xF0, 0x80                   ; FC730E  add XWA,(XIZ+0xf0)
	ld	(xwa), bc                               ; FC7311  ld (XWA),BC
	lda	xbc, (0xE093:24)                       ; FC7313  lda XBC,0x00e093
	extpfx3 0xAE, 0xEC, 0x81                   ; FC7318  add XBC,(XIZ+0xec)
	extpfx4 0xB1, 0x02, 0x00, 0x80             ; FC731B  ld (XBC),0x8000
	ld	bc, (xiz-22)                            ; FC731F  ld BC,(XIZ+0xea)
	extz	xbc                                   ; FC7322  extz XBC
	ld	xwa, (xbc+3)                            ; FC7324  ld XWA,(XBC+0x03)
	ld	d, (xwa+33)                             ; FC7327  ld D,(XWA+0x21)
	cps	d, 0                                   ; FC732A  cp D,0
	jr ge, sub_FC723F__FC735C                  ; FC732C  jr GE,0xfc735c
	ld	a, d                                    ; FC732E  ld A,D
	exts	wa                                    ; FC7330  exts WA
	ld	hl, wa                                  ; FC7332  ld HL,WA
	neg	wa                                     ; FC7334  neg WA
	ld	hl, wa                                  ; FC7336  ld HL,WA
	cp	wa, 0x64                                ; FC7338  cp WA,0x0064
	jr le, sub_FC723F__FC7343                  ; FC733C  jr LE,0xfc7343
	ldw	hl, 0x64                               ; FC733E  ld HL,0x0064
	jr sub_FC723F__FC734A                      ; FC7341  jr T,0xfc734a
sub_FC723F__FC7343:
	cps	hl, 0                                  ; FC7343  cp HL,0
	jr ge, sub_FC723F__FC734A                  ; FC7345  jr GE,0xfc734a
	ldw	hl, 0                                  ; FC7347  ld HL,0x0000
sub_FC723F__FC734A:
	ldw	bc, 2                                  ; FC734A  ld BC,0x0002
	muls	xbc, xhl                              ; FC734D  muls XBC,HL
	add	xbc, 0xFDFECC                          ; FC734F  add XBC,0x00fdfecc
	ld	bc, (xbc)                               ; FC7355  ld BC,(XBC)
	ld	(xiz-26), bc                            ; FC7357  ld (XIZ+0xe6),BC
	jr sub_FC723F__FC7384                      ; FC735A  jr T,0xfc7384
sub_FC723F__FC735C:
	ld	c, d                                    ; FC735C  ld C,D
	exts	bc                                    ; FC735E  exts BC
	ld	hl, bc                                  ; FC7360  ld HL,BC
	cp	bc, 0x64                                ; FC7362  cp BC,0x0064
	jr le, sub_FC723F__FC736D                  ; FC7366  jr LE,0xfc736d
	ldw	hl, 0x64                               ; FC7368  ld HL,0x0064
	jr sub_FC723F__FC7374                      ; FC736B  jr T,0xfc7374
sub_FC723F__FC736D:
	cps	hl, 0                                  ; FC736D  cp HL,0
	jr ge, sub_FC723F__FC7374                  ; FC736F  jr GE,0xfc7374
	ldw	hl, 0                                  ; FC7371  ld HL,0x0000
sub_FC723F__FC7374:
	ldw	bc, 2                                  ; FC7374  ld BC,0x0002
	muls	xbc, xhl                              ; FC7377  muls XBC,HL
	add	xbc, 0xFDFECC                          ; FC7379  add XBC,0x00fdfecc
	ld	bc, (xbc)                               ; FC737F  ld BC,(XBC)
	ld	(xiz-26), bc                            ; FC7381  ld (XIZ+0xe6),BC
sub_FC723F__FC7384:
	lda	xbc, (0xE093:24)                       ; FC7384  lda XBC,0x00e093
	add	xbc, xix                               ; FC7389  add XBC,XIX
	ld	wa, (xiz-26)                            ; FC738B  ld WA,(XIZ+0xe6)
	ld	(xbc), wa                               ; FC738E  ld (XBC),WA
	ld	bc, (xiz-22)                            ; FC7390  ld BC,(XIZ+0xea)
	extz	xbc                                   ; FC7393  extz XBC
	ld	hl, (xbc+14)                            ; FC7395  ld HL,(XBC+0x0e)
	ld	xwa, (xiz-4)                            ; FC7398  ld XWA,(XIZ+0xfc)
	ld	(xiz-30), xwa                           ; FC739B  ld (XIZ+0xe2),XWA
	add	xwa, 0xE093                            ; FC739E  add XWA,0x0000e093
	ld	(xwa), hl                               ; FC73A4  ld (XWA),HL
	ld	bc, (xiz-22)                            ; FC73A6  ld BC,(XIZ+0xea)
	extz	xbc                                   ; FC73A9  extz XBC
	ld	hl, (xbc+16)                            ; FC73AB  ld HL,(XBC+0x10)
	ld	xwa, (xiz-8)                            ; FC73AE  ld XWA,(XIZ+0xf8)
	ld	(xiz-34), xwa                           ; FC73B1  ld (XIZ+0xde),XWA
	add	xwa, 0xE093                            ; FC73B4  add XWA,0x0000e093
	ld	(xwa), hl                               ; FC73BA  ld (XWA),HL
	decm8	1, (xiz-23)                          ; FC73BC  dec 1,(XIZ+0xe9)
	ld	xbc, (xiz-34)                           ; FC73BF  ld XBC,(XIZ+0xde)
	inc	4, xbc                                 ; FC73C2  inc 4,XBC
	ld	(xiz-8), xbc                            ; FC73C4  ld (XIZ+0xf8),XBC
	ld	xwa, (xiz-30)                           ; FC73C7  ld XWA,(XIZ+0xe2)
	inc	4, xwa                                 ; FC73CA  inc 4,XWA
	ld	(xiz-4), xwa                            ; FC73CC  ld (XIZ+0xfc),XWA
	inc	4, xix                                 ; FC73CF  inc 4,XIX
	sub	xiy, xiy                               ; FC73D1  sub XIY,XIY
	inc	4, xiy                                 ; FC73D3  inc 4,XIY
	add	(xiz-20), xiy                          ; FC73D5  add (XIZ+0xec),XIY
	add	(xiz-16), xiy                          ; FC73D8  add (XIZ+0xf0),XIY
	add	(xiz-12), xiy                          ; FC73DB  add (XIZ+0xf4),XIY
	extpfx5 0x9E, 0xEA, 0x38, 0x2A, 0x00       ; FC73DE  add (XIZ+0xea),0x002a
	cp (xiz-23), 0x00                          ; FC73E3  cp (XIZ+0xe9),0x00
	jrl nz, sub_FC723F__FC72AF                 ; FC73E7  jrl NZ,0xfc72af
	stiw_da	(0xE093), 0x400                    ; FC73EA  ld (0x00e093),0x0400
	stiw_da	(0xE095), 4                        ; FC73F1  ld (0x00e095),0x0004
	lda	xbc, (0xE093:24)                       ; FC73F8  lda XBC,0x00e093
	push	xbc                                   ; FC73FD  push XBC
	calr (0xFC4269 - 0xFC7401)                 ; FC73FE  calr 0xfc4269
	ld	bc, (0xE082:24)                        ; FC7401  ld BC,(0x00e082)
	add	bc, 0x67                               ; FC7406  add BC,0x0067
	ld	(xiz-22), bc                            ; FC740A  ld (XIZ+0xea),BC
	ld	xwa, 52                                 ; FC740D  ld XWA,0x00000034
	ld	(xiz-4), xwa                            ; FC7412  ld (XIZ+0xfc),XWA
	ld	xix, 54                                 ; FC7415  ld XIX,0x00000036
	ld	(xiz-23), 2                             ; FC741A  ld (XIZ+0xe9),0x02
	pop	xiy                                    ; FC741E  pop XIY
sub_FC723F__FC741F:
	ld	xbc, (xiz-4)                            ; FC741F  ld XBC,(XIZ+0xfc)
	ld	(xiz-30), xbc                           ; FC7422  ld (XIZ+0xe2),XBC
	add	xbc, 0xE093                            ; FC7425  add XBC,0x0000e093
	ld	bc, (xbc)                               ; FC742B  ld BC,(XBC)
	ld	wa, (xiz-22)                            ; FC742D  ld WA,(XIZ+0xea)
	extz	xwa                                   ; FC7430  extz XWA
	ld	(xwa+18), bc                            ; FC7432  ld (XWA+0x12),BC
	ld	(xiz-34), xix                           ; FC7435  ld (XIZ+0xde),XIX
	lda	xbc, (0xE093:24)                       ; FC7438  lda XBC,0x00e093
	extpfx3 0xAE, 0xDE, 0x81                   ; FC743D  add XBC,(XIZ+0xde)
	ld	wa, (xbc)                               ; FC7440  ld WA,(XBC)
	ld	bc, (xiz-22)                            ; FC7442  ld BC,(XIZ+0xea)
	extz	xbc                                   ; FC7445  extz XBC
	ld	(xbc+20), wa                            ; FC7447  ld (XBC+0x14),WA
	decm8	1, (xiz-23)                          ; FC744A  dec 1,(XIZ+0xe9)
	ld	xix, (xiz-34)                           ; FC744D  ld XIX,(XIZ+0xde)
	inc	4, xix                                 ; FC7450  inc 4,XIX
	ld	xbc, (xiz-30)                           ; FC7452  ld XBC,(XIZ+0xe2)
	inc	4, xbc                                 ; FC7455  inc 4,XBC
	ld	(xiz-4), xbc                            ; FC7457  ld (XIZ+0xfc),XBC
	extpfx5 0x9E, 0xEA, 0x38, 0x2A, 0x00       ; FC745A  add (XIZ+0xea),0x002a
	cp (xiz-23), 0x00                          ; FC745F  cp (XIZ+0xe9),0x00
	jr nz, sub_FC723F__FC741F                  ; FC7463  jr NZ,0xfc741f
	ld	wa, (0xE082:24)                        ; FC7465  ld WA,(0x00e082)
	extz	xwa                                   ; FC746A  extz XWA
	ld	(xwa+17), 0x7F                          ; FC746C  ld (XWA+0x11),0x7f
	ld	bc, (0xE082:24)                        ; FC7470  ld BC,(0x00e082)
	extz	xbc                                   ; FC7475  extz XBC
	ld	(xbc+18), 0x7F                          ; FC7477  ld (XBC+0x12),0x7f
	pop	xix                                    ; FC747B  pop XIX
	popw	de                                    ; FC747C  pop DE
	popw	hl                                    ; FC747D  pop HL
	unlk32 xiz                                 ; FC747E  unlk XIZ
	ret                                        ; FC7480  ret
; --------------------------------------------------------------------------
; sub_FC7481 -- 0xFC7481..0xFC7A1E (1438 bytes)
;
; Called from: 8 site(s) outside this module:
;          0xFB68C8 in sub_FB6681__FB6891, 0xFB6B45 in sub_FB68DD__FB6B0F
;          0xFB9278 in ToneDB_SourceNameList1_SelectEntry__FB9270, 0xFB9409 in ToneDB_SourceNameList2_SelectEntry__FB9401
;          0xFBBB7C in sub_FBB793__FBBB74, 0xFBBDB7 in sub_FBB793__FBBDAF
;          0xFBC101 in sub_FBBFFB__FBC0F9, 0xFBCB9E in sub_FBC958__FBCB96
; Inputs:  frame `link XIZ,-10`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: writes 0x00E082, 0x00E084
; Calls:   0xFC46A8 = sub_FC46A8, 0xFC6CA8 = sub_FC6CA8
;          0xFC6CEA = sub_FC6CEA, 0xFC6D2C = sub_FC6D2C
;          0xFC6D6E = sub_FC6D6E, 0xFC6FFD = sub_FC6FFD
;          0xFC723F = sub_FC723F
; Evidence: the listing below is the byte-identical round-trip of 0xFC7481-0xFC7A1E
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC7481:
	link32 0xEE, 0x0C, 0xF6, 0xFF              ; FC7481  link XIZ,0xfff6
	pushw	hl                                   ; FC7485  push HL
	pushw	de                                   ; FC7486  push DE
	push	xix                                   ; FC7487  push XIX
	ldb	c, 0xBB                                ; FC7488  ld C,0xbb
	extpfx3 0x8E, 0x08, 0x43                   ; FC748A  mul BC,(XIZ+0x08)
	ld	de, bc                                  ; FC748D  ld DE,BC
	ldw	wa, 0x5D23                             ; FC748F  ld WA,0x5d23
	ld	ix, wa                                  ; FC7492  ld IX,WA
	add	ix, bc                                 ; FC7494  add IX,BC
	stw_da	(0xE082), ix                        ; FC7496  ld (0x00e082),IX
	extz	xix                                   ; FC749B  extz XIX
	ld	(xix), 0                                ; FC749D  ld (XIX),0x00
	ld	bc, (0xE082:24)                        ; FC74A0  ld BC,(0x00e082)
	add	bc, 19                                 ; FC74A5  add BC,0x0013
	stw_da	(0xE084), bc                        ; FC74A9  ld (0x00e084),BC
	ldb	h, 0                                   ; FC74AE  ld H,0x00
	ldb	e, 3                                   ; FC74B0  ld E,0x03
sub_FC7481__FC74B2:
	ld	bc, (0xE084:24)                        ; FC74B2  ld BC,(0x00e084)
	extz	xbc                                   ; FC74B7  extz XBC
	ld	xwa, (xbc+3)                            ; FC74B9  ld XWA,(XBC+0x03)
	ld	c, (xwa+11)                             ; FC74BC  ld C,(XWA+0x0b)
	and	c, 0xC0                                ; FC74BF  and C,0xc0
	ld	l, c                                    ; FC74C2  ld L,C
	or	l, h                                    ; FC74C4  or L,H
	dec	1, e                                   ; FC74C6  dec 1,E
	extpfx7 0xD2, 0x84, 0xE0, 0x00, 0x38, 0x2A, 0x00 ; FC74C8  add (0x00e084),0x002a
	ld	h, l                                    ; FC74CF  ld H,L
	srl	h, 2                                   ; FC74D1  srl 0x02,H
	cps	e, 0                                   ; FC74D4  cp E,0
	jr nz, sub_FC7481__FC74B2                  ; FC74D6  jr NZ,0xfc74b2
	ld	bc, (0xE084:24)                        ; FC74D8  ld BC,(0x00e084)
	extz	xbc                                   ; FC74DD  extz XBC
	ld	xwa, (xbc+3)                            ; FC74DF  ld XWA,(XBC+0x03)
	ld	c, (xwa+11)                             ; FC74E2  ld C,(XWA+0x0b)
	and	c, 0xC0                                ; FC74E5  and C,0xc0
	or	h, c                                    ; FC74E8  or H,C
	jr nz, sub_FC7481__FC74F1                  ; FC74EA  jr NZ,0xfc74f1
	calr (0xFC6CA8 - 0xFC74EF)                 ; FC74EC  calr 0xfc6ca8
	jr sub_FC7481__FC7519                      ; FC74EF  jr T,0xfc7519
sub_FC7481__FC74F1:
	cp	h, 0xAA                                 ; FC74F1  cp H,0xaa
	jr nz, sub_FC7481__FC74FB                  ; FC74F4  jr NZ,0xfc74fb
	calr (0xFC6D6E - 0xFC74F9)                 ; FC74F6  calr 0xfc6d6e
	jr sub_FC7481__FC7519                      ; FC74F9  jr T,0xfc7519
sub_FC7481__FC74FB:
	ld	c, h                                    ; FC74FB  ld C,H
	and	c, 15                                  ; FC74FD  and C,0x0f
	jr z, sub_FC7481__FC7507                   ; FC7500  jr Z,0xfc7507
	calr (0xFC6FFD - 0xFC7505)                 ; FC7502  calr 0xfc6ffd
	jr sub_FC7481__FC750A                      ; FC7505  jr T,0xfc750a
sub_FC7481__FC7507:
	calr (0xFC6CEA - 0xFC750A)                 ; FC7507  calr 0xfc6cea
sub_FC7481__FC750A:
	ld	c, h                                    ; FC750A  ld C,H
	and	c, 0xF0                                ; FC750C  and C,0xf0
	jr z, sub_FC7481__FC7516                   ; FC750F  jr Z,0xfc7516
	calr (0xFC723F - 0xFC7514)                 ; FC7511  calr 0xfc723f
	jr sub_FC7481__FC7519                      ; FC7514  jr T,0xfc7519
sub_FC7481__FC7516:
	calr (0xFC6D2C - 0xFC7519)                 ; FC7516  calr 0xfc6d2c
sub_FC7481__FC7519:
	cp (xiz+10), 0x01                          ; FC7519  cp (XIZ+0x0a),0x01
	jrl nz, sub_FC7481__FC7A19                 ; FC751D  jrl NZ,0xfc7a19
	ld	bc, (0xE082:24)                        ; FC7520  ld BC,(0x00e082)
	extz	xbc                                   ; FC7525  extz XBC
	extpfx5 0xB9, 0x01, 0x02, 0x00, 0x00       ; FC7527  ld (XBC+0x01),0x0000
	ld	bc, (0xE082:24)                        ; FC752C  ld BC,(0x00e082)
	extz	xbc                                   ; FC7531  extz XBC
	extpfx5 0xB9, 0x03, 0x02, 0x00, 0x00       ; FC7533  ld (XBC+0x03),0x0000
	ld	bc, (0xE082:24)                        ; FC7538  ld BC,(0x00e082)
	extz	xbc                                   ; FC753D  extz XBC
	extpfx5 0xB9, 0x05, 0x02, 0x00, 0x00       ; FC753F  ld (XBC+0x05),0x0000
	ld	bc, (0xE082:24)                        ; FC7544  ld BC,(0x00e082)
	extz	xbc                                   ; FC7549  extz XBC
	extpfx5 0xB9, 0x07, 0x02, 0x00, 0x00       ; FC754B  ld (XBC+0x07),0x0000
	ld	bc, (0xE082:24)                        ; FC7550  ld BC,(0x00e082)
	extz	xbc                                   ; FC7555  extz XBC
	extpfx5 0xB9, 0x09, 0x02, 0x00, 0x00       ; FC7557  ld (XBC+0x09),0x0000
	ld	bc, (0xE082:24)                        ; FC755C  ld BC,(0x00e082)
	extz	xbc                                   ; FC7561  extz XBC
	extpfx5 0xB9, 0x0B, 0x02, 0x00, 0x00       ; FC7563  ld (XBC+0x0b),0x0000
	ld	bc, (0xE082:24)                        ; FC7568  ld BC,(0x00e082)
	extz	xbc                                   ; FC756D  extz XBC
	extpfx5 0xB9, 0x0D, 0x02, 0x00, 0x00       ; FC756F  ld (XBC+0x0d),0x0000
	ld	bc, (0xE082:24)                        ; FC7574  ld BC,(0x00e082)
	extz	xbc                                   ; FC7579  extz XBC
	extpfx5 0xB9, 0x0F, 0x02, 0x00, 0x00       ; FC757B  ld (XBC+0x0f),0x0000
	ld	bc, (0xE082:24)                        ; FC7580  ld BC,(0x00e082)
	add	bc, 19                                 ; FC7585  add BC,0x0013
	stw_da	(0xE084), bc                        ; FC7589  ld (0x00e084),BC
	ldb	e, 4                                   ; FC758E  ld E,0x04
sub_FC7481__FC7590:
	ld	bc, (0xE084:24)                        ; FC7590  ld BC,(0x00e084)
	extz	xbc                                   ; FC7595  extz XBC
	extpfx2 0xB1, 0xCF                         ; FC7597  bit 7,(XBC)
	jrl z, sub_FC7481__FC7A0B                  ; FC7599  jrl Z,0xfc7a0b
	ld	xwa, (xbc+3)                            ; FC759C  ld XWA,(XBC+0x03)
	ld	(xiz-4), xwa                            ; FC759F  ld (XIZ+0xfc),XWA
	extpfx3 0x81, 0x3C, 0xE1                   ; FC75A2  and (XBC),0xe1
	ld	(xbc+1), 0                              ; FC75A5  ld (XBC+0x01),0x00
	ld	bc, (0xE084:24)                        ; FC75A9  ld BC,(0x00e084)
	extz	xbc                                   ; FC75AE  extz XBC
	extpfx4 0x89, 0x02, 0x3C, 0x0F             ; FC75B0  and (XBC+0x02),0x0f
	ld	a, (xbc)                                ; FC75B4  ld A,(XBC)
	and	a, 24                                  ; FC75B6  and A,0x18
	srl	a, 3                                   ; FC75B9  srl 0x03,A
	extz	wa                                    ; FC75BC  extz WA
	cps	wa, 1                                  ; FC75BE  cp WA,1
	jr z, sub_FC7481__FC75C9                   ; FC75C0  jr Z,0xfc75c9
	cps	wa, 2                                  ; FC75C2  cp WA,2
	jr z, sub_FC7481__FC7612                   ; FC75C4  jr Z,0xfc7612
	jrl sub_FC7481__FC765A                     ; FC75C6  jrl T,0xfc765a
sub_FC7481__FC75C9:
	ld	xbc, (xiz-4)                            ; FC75C9  ld XBC,(XIZ+0xfc)
	ld	a, (xbc+21)                             ; FC75CC  ld A,(XBC+0x15)
	res	7, a                                   ; FC75CF  res 0x07,A
	extz	wa                                    ; FC75D2  extz WA
	ld	hl, wa                                  ; FC75D4  ld HL,WA
	ld	bc, (0xE082:24)                        ; FC75D6  ld BC,(0x00e082)
	extz	xbc                                   ; FC75DB  extz XBC
	ld	iy, (xbc+1)                             ; FC75DD  ld IY,(XBC+0x01)
	add	wa, iy                                 ; FC75E0  add WA,IY
	ld	bc, (0xE084:24)                        ; FC75E2  ld BC,(0x00e084)
	extz	xbc                                   ; FC75E7  extz XBC
	ld	(xbc+22), wa                            ; FC75E9  ld (XBC+0x16),WA
	ld	xbc, (xiz-4)                            ; FC75EC  ld XBC,(XIZ+0xfc)
	ld	a, (xbc+31)                             ; FC75EF  ld A,(XBC+0x1f)
	res	7, a                                   ; FC75F2  res 0x07,A
	extz	wa                                    ; FC75F5  extz WA
	ld	hl, wa                                  ; FC75F7  ld HL,WA
	ld	bc, (0xE082:24)                        ; FC75F9  ld BC,(0x00e082)
	extz	xbc                                   ; FC75FE  extz XBC
	ld	iy, (xbc+1)                             ; FC7600  ld IY,(XBC+0x01)
	add	wa, iy                                 ; FC7603  add WA,IY
	ld	bc, (0xE084:24)                        ; FC7605  ld BC,(0x00e084)
	extz	xbc                                   ; FC760A  extz XBC
	ld	(xbc+24), wa                            ; FC760C  ld (XBC+0x18),WA
	jrl sub_FC7481__FC7684                     ; FC760F  jrl T,0xfc7684
sub_FC7481__FC7612:
	ld	xbc, (xiz-4)                            ; FC7612  ld XBC,(XIZ+0xfc)
	ld	a, (xbc+21)                             ; FC7615  ld A,(XBC+0x15)
	res	7, a                                   ; FC7618  res 0x07,A
	extz	wa                                    ; FC761B  extz WA
	ld	hl, wa                                  ; FC761D  ld HL,WA
	ld	bc, (0xE082:24)                        ; FC761F  ld BC,(0x00e082)
	extz	xbc                                   ; FC7624  extz XBC
	ld	iy, (xbc+1)                             ; FC7626  ld IY,(XBC+0x01)
	sub	wa, iy                                 ; FC7629  sub WA,IY
	ld	bc, (0xE084:24)                        ; FC762B  ld BC,(0x00e084)
	extz	xbc                                   ; FC7630  extz XBC
	ld	(xbc+22), wa                            ; FC7632  ld (XBC+0x16),WA
	ld	xbc, (xiz-4)                            ; FC7635  ld XBC,(XIZ+0xfc)
	ld	a, (xbc+31)                             ; FC7638  ld A,(XBC+0x1f)
	res	7, a                                   ; FC763B  res 0x07,A
	extz	wa                                    ; FC763E  extz WA
	ld	hl, wa                                  ; FC7640  ld HL,WA
	ld	bc, (0xE082:24)                        ; FC7642  ld BC,(0x00e082)
	extz	xbc                                   ; FC7647  extz XBC
	ld	iy, (xbc+1)                             ; FC7649  ld IY,(XBC+0x01)
	sub	wa, iy                                 ; FC764C  sub WA,IY
	ld	bc, (0xE084:24)                        ; FC764E  ld BC,(0x00e084)
	extz	xbc                                   ; FC7653  extz XBC
	ld	(xbc+24), wa                            ; FC7655  ld (XBC+0x18),WA
	jr sub_FC7481__FC7684                      ; FC7658  jr T,0xfc7684
sub_FC7481__FC765A:
	ld	xbc, (xiz-4)                            ; FC765A  ld XBC,(XIZ+0xfc)
	ld	a, (xbc+21)                             ; FC765D  ld A,(XBC+0x15)
	res	7, a                                   ; FC7660  res 0x07,A
	extz	wa                                    ; FC7663  extz WA
	ld	bc, (0xE084:24)                        ; FC7665  ld BC,(0x00e084)
	extz	xbc                                   ; FC766A  extz XBC
	ld	(xbc+22), wa                            ; FC766C  ld (XBC+0x16),WA
	ld	xbc, (xiz-4)                            ; FC766F  ld XBC,(XIZ+0xfc)
	ld	a, (xbc+31)                             ; FC7672  ld A,(XBC+0x1f)
	res	7, a                                   ; FC7675  res 0x07,A
	extz	wa                                    ; FC7678  extz WA
	ld	bc, (0xE084:24)                        ; FC767A  ld BC,(0x00e084)
	extz	xbc                                   ; FC767F  extz XBC
	ld	(xbc+24), wa                            ; FC7681  ld (XBC+0x18),WA
sub_FC7481__FC7684:
	ld	xix, (xiz-4)                            ; FC7684  ld XIX,(XIZ+0xfc)
	ld	bc, (0xE084:24)                        ; FC7687  ld BC,(0x00e084)
	extz	xbc                                   ; FC768C  extz XBC
	ld	a, (xbc)                                ; FC768E  ld A,(XBC)
	and	a, 6                                   ; FC7690  and A,0x06
	srl	a, 1                                   ; FC7693  srl 0x01,A
	extz	wa                                    ; FC7696  extz WA
	cps	wa, 1                                  ; FC7698  cp WA,1
	jr z, sub_FC7481__FC76A3                   ; FC769A  jr Z,0xfc76a3
	cps	wa, 2                                  ; FC769C  cp WA,2
	jr z, sub_FC7481__FC76D2                   ; FC769E  jr Z,0xfc76d2
	jrl sub_FC7481__FC773D                     ; FC76A0  jrl T,0xfc773d
sub_FC7481__FC76A3:
	ld	c, (xix+13)                             ; FC76A3  ld C,(XIX+0x0d)
	extz	bc                                    ; FC76A6  extz BC
	ld	hl, bc                                  ; FC76A8  ld HL,BC
	ld	wa, (0xE082:24)                        ; FC76AA  ld WA,(0x00e082)
	extz	xwa                                   ; FC76AF  extz XWA
	ld	iy, (xwa+3)                             ; FC76B1  ld IY,(XWA+0x03)
	add	bc, iy                                 ; FC76B4  add BC,IY
	ld	hl, bc                                  ; FC76B6  ld HL,BC
	ld	bc, (0xE084:24)                        ; FC76B8  ld BC,(0x00e084)
	extz	xbc                                   ; FC76BD  extz XBC
	ld	(xbc+32), hl                            ; FC76BF  ld (XBC+0x20),HL
	ld	bc, (0xE082:24)                        ; FC76C2  ld BC,(0x00e082)
	extz	xbc                                   ; FC76C7  extz XBC
	ld	wa, (xbc+3)                             ; FC76C9  ld WA,(XBC+0x03)
	cps	wa, 0                                  ; FC76CC  cp WA,0
	jr ge, sub_FC7481__FC7716                  ; FC76CE  jr GE,0xfc7716
	jr sub_FC7481__FC76FF                      ; FC76D0  jr T,0xfc76ff
sub_FC7481__FC76D2:
	ld	c, (xix+13)                             ; FC76D2  ld C,(XIX+0x0d)
	extz	bc                                    ; FC76D5  extz BC
	ld	hl, bc                                  ; FC76D7  ld HL,BC
	ld	wa, (0xE082:24)                        ; FC76D9  ld WA,(0x00e082)
	extz	xwa                                   ; FC76DE  extz XWA
	ld	iy, (xwa+3)                             ; FC76E0  ld IY,(XWA+0x03)
	sub	bc, iy                                 ; FC76E3  sub BC,IY
	ld	hl, bc                                  ; FC76E5  ld HL,BC
	ld	bc, (0xE084:24)                        ; FC76E7  ld BC,(0x00e084)
	extz	xbc                                   ; FC76EC  extz XBC
	ld	(xbc+32), hl                            ; FC76EE  ld (XBC+0x20),HL
	ld	bc, (0xE082:24)                        ; FC76F1  ld BC,(0x00e082)
	extz	xbc                                   ; FC76F6  extz XBC
	ld	wa, (xbc+3)                             ; FC76F8  ld WA,(XBC+0x03)
	cps	wa, 0                                  ; FC76FB  cp WA,0
	jr ge, sub_FC7481__FC7716                  ; FC76FD  jr GE,0xfc7716
sub_FC7481__FC76FF:
	ld	bc, (0xE082:24)                        ; FC76FF  ld BC,(0x00e082)
	extz	xbc                                   ; FC7704  extz XBC
	ld	hl, (xbc+3)                             ; FC7706  ld HL,(XBC+0x03)
	ld	wa, hl                                  ; FC7709  ld WA,HL
	neg	wa                                     ; FC770B  neg WA
	ld	hl, wa                                  ; FC770D  ld HL,WA
	sra	wa, 2                                  ; FC770F  sra 0x02,WA
	ld	hl, wa                                  ; FC7712  ld HL,WA
	jr sub_FC7481__FC7727                      ; FC7714  jr T,0xfc7727
sub_FC7481__FC7716:
	ld	bc, (0xE082:24)                        ; FC7716  ld BC,(0x00e082)
	extz	xbc                                   ; FC771B  extz XBC
	ld	hl, (xbc+3)                             ; FC771D  ld HL,(XBC+0x03)
	ld	iy, hl                                  ; FC7720  ld IY,HL
	sra	iy, 2                                  ; FC7722  sra 0x02,IY
	ld	hl, iy                                  ; FC7725  ld HL,IY
sub_FC7481__FC7727:
	ld	c, (xix+14)                             ; FC7727  ld C,(XIX+0x0e)
	res	7, c                                   ; FC772A  res 0x07,C
	extz	bc                                    ; FC772D  extz BC
	add	bc, hl                                 ; FC772F  add BC,HL
	ld	wa, (0xE084:24)                        ; FC7731  ld WA,(0x00e084)
	extz	xwa                                   ; FC7736  extz XWA
	ld	(xwa+34), bc                            ; FC7738  ld (XWA+0x22),BC
	jr sub_FC7481__FC775E                      ; FC773B  jr T,0xfc775e
sub_FC7481__FC773D:
	ld	c, (xix+13)                             ; FC773D  ld C,(XIX+0x0d)
	extz	bc                                    ; FC7740  extz BC
	ld	wa, (0xE084:24)                        ; FC7742  ld WA,(0x00e084)
	extz	xwa                                   ; FC7747  extz XWA
	ld	(xwa+32), bc                            ; FC7749  ld (XWA+0x20),BC
	ld	c, (xix+14)                             ; FC774C  ld C,(XIX+0x0e)
	res	7, c                                   ; FC774F  res 0x07,C
	extz	bc                                    ; FC7752  extz BC
	ld	wa, (0xE084:24)                        ; FC7754  ld WA,(0x00e084)
	extz	xwa                                   ; FC7759  extz XWA
	ld	(xwa+34), bc                            ; FC775B  ld (XWA+0x22),BC
sub_FC7481__FC775E:
	ld	bc, (0xE084:24)                        ; FC775E  ld BC,(0x00e084)
	extz	xbc                                   ; FC7763  extz XBC
	ld	a, (xbc+1)                              ; FC7765  ld A,(XBC+0x01)
	and	a, 0xC0                                ; FC7768  and A,0xc0
	srl	a, 6                                   ; FC776B  srl 0x06,A
	extz	wa                                    ; FC776E  extz WA
	cps	wa, 1                                  ; FC7770  cp WA,1
	jr z, sub_FC7481__FC777A                   ; FC7772  jr Z,0xfc777a
	cps	wa, 2                                  ; FC7774  cp WA,2
	jr z, sub_FC7481__FC7790                   ; FC7776  jr Z,0xfc7790
	jr sub_FC7481__FC77A4                      ; FC7778  jr T,0xfc77a4
sub_FC7481__FC777A:
	ld	bc, (0xE082:24)                        ; FC777A  ld BC,(0x00e082)
	extz	xbc                                   ; FC777F  extz XBC
	ld	wa, (xbc+5)                             ; FC7781  ld WA,(XBC+0x05)
	ld	bc, (0xE084:24)                        ; FC7784  ld BC,(0x00e084)
	extz	xbc                                   ; FC7789  extz XBC
	add	(xbc+34), wa                           ; FC778B  add (XBC+0x22),WA
	jr sub_FC7481__FC77A4                      ; FC778E  jr T,0xfc77a4
sub_FC7481__FC7790:
	ld	bc, (0xE082:24)                        ; FC7790  ld BC,(0x00e082)
	extz	xbc                                   ; FC7795  extz XBC
	ld	wa, (xbc+5)                             ; FC7797  ld WA,(XBC+0x05)
	ld	bc, (0xE084:24)                        ; FC779A  ld BC,(0x00e084)
	extz	xbc                                   ; FC779F  extz XBC
	sub	(xbc+34), wa                           ; FC77A1  sub (XBC+0x22),WA
sub_FC7481__FC77A4:
	ld	xix, (xiz-4)                            ; FC77A4  ld XIX,(XIZ+0xfc)
	ld	bc, (0xE084:24)                        ; FC77A7  ld BC,(0x00e084)
	extz	xbc                                   ; FC77AC  extz XBC
	ld	a, (xbc+1)                              ; FC77AE  ld A,(XBC+0x01)
	and	a, 48                                  ; FC77B1  and A,0x30
	srl	a, 4                                   ; FC77B4  srl 0x04,A
	extz	wa                                    ; FC77B7  extz WA
	cps	wa, 1                                  ; FC77B9  cp WA,1
	jr z, sub_FC7481__FC77C3                   ; FC77BB  jr Z,0xfc77c3
	cps	wa, 2                                  ; FC77BD  cp WA,2
	jr z, sub_FC7481__FC77E5                   ; FC77BF  jr Z,0xfc77e5
	jr sub_FC7481__FC781D                      ; FC77C1  jr T,0xfc781d
sub_FC7481__FC77C3:
	ld	c, (xix+17)                             ; FC77C3  ld C,(XIX+0x11)
	extz	bc                                    ; FC77C6  extz BC
	ld	(xiz-10), bc                            ; FC77C8  ld (XIZ+0xf6),BC
	ld	wa, (0xE082:24)                        ; FC77CB  ld WA,(0x00e082)
	extz	xwa                                   ; FC77D0  extz XWA
	ld	iy, (xwa+7)                             ; FC77D2  ld IY,(XWA+0x07)
	ld	hl, bc                                  ; FC77D5  ld HL,BC
	add	hl, iy                                 ; FC77D7  add HL,IY
	cp	hl, 50                                  ; FC77D9  cp HL,0x0032
	jr gt, sub_FC7481__FC7801                  ; FC77DD  jr GT,0xfc7801
	cps	hl, 0                                  ; FC77DF  cp HL,0
	jr ge, sub_FC7481__FC780D                  ; FC77E1  jr GE,0xfc780d
	jr sub_FC7481__FC780A                      ; FC77E3  jr T,0xfc780a
sub_FC7481__FC77E5:
	ld	c, (xix+17)                             ; FC77E5  ld C,(XIX+0x11)
	extz	bc                                    ; FC77E8  extz BC
	ld	(xiz-10), bc                            ; FC77EA  ld (XIZ+0xf6),BC
	ld	wa, (0xE082:24)                        ; FC77ED  ld WA,(0x00e082)
	extz	xwa                                   ; FC77F2  extz XWA
	ld	iy, (xwa+7)                             ; FC77F4  ld IY,(XWA+0x07)
	ld	hl, bc                                  ; FC77F7  ld HL,BC
	sub	hl, iy                                 ; FC77F9  sub HL,IY
	cp	hl, 50                                  ; FC77FB  cp HL,0x0032
	jr le, sub_FC7481__FC7806                  ; FC77FF  jr LE,0xfc7806
sub_FC7481__FC7801:
	ldw	hl, 50                                 ; FC7801  ld HL,0x0032
	jr sub_FC7481__FC780D                      ; FC7804  jr T,0xfc780d
sub_FC7481__FC7806:
	cps	hl, 0                                  ; FC7806  cp HL,0
	jr ge, sub_FC7481__FC780D                  ; FC7808  jr GE,0xfc780d
sub_FC7481__FC780A:
	ldw	hl, 0                                  ; FC780A  ld HL,0x0000
sub_FC7481__FC780D:
	ld	c, l                                    ; FC780D  ld C,L
	ld	d, c                                    ; FC780F  ld D,C
	ld	bc, (0xE084:24)                        ; FC7811  ld BC,(0x00e084)
	extz	xbc                                   ; FC7816  extz XBC
	ld	(xbc+40), d                             ; FC7818  ld (XBC+0x28),D
	jr sub_FC7481__FC7824                      ; FC781B  jr T,0xfc7824
sub_FC7481__FC781D:
	ld	c, (xix+17)                             ; FC781D  ld C,(XIX+0x11)
	extz	bc                                    ; FC7820  extz BC
	ld	hl, bc                                  ; FC7822  ld HL,BC
sub_FC7481__FC7824:
	ld	c, l                                    ; FC7824  ld C,L
	ld	d, c                                    ; FC7826  ld D,C
	ld	bc, (0xE084:24)                        ; FC7828  ld BC,(0x00e084)
	extz	xbc                                   ; FC782D  extz XBC
	ld	(xbc+40), d                             ; FC782F  ld (XBC+0x28),D
	ld	xix, (xiz-4)                            ; FC7832  ld XIX,(XIZ+0xfc)
	ld	bc, (0xE084:24)                        ; FC7835  ld BC,(0x00e084)
	extz	xbc                                   ; FC783A  extz XBC
	ld	a, (xbc+1)                              ; FC783C  ld A,(XBC+0x01)
	and	a, 12                                  ; FC783F  and A,0x0c
	srl	a, 2                                   ; FC7842  srl 0x02,A
	extz	wa                                    ; FC7845  extz WA
	cps	wa, 1                                  ; FC7847  cp WA,1
	jr z, sub_FC7481__FC7851                   ; FC7849  jr Z,0xfc7851
	cps	wa, 2                                  ; FC784B  cp WA,2
	jr z, sub_FC7481__FC7876                   ; FC784D  jr Z,0xfc7876
	jr sub_FC7481__FC78A3                      ; FC784F  jr T,0xfc78a3
sub_FC7481__FC7851:
	ld	c, (xix+18)                             ; FC7851  ld C,(XIX+0x12)
	res	7, c                                   ; FC7854  res 0x07,C
	extz	bc                                    ; FC7857  extz BC
	ld	(xiz-10), bc                            ; FC7859  ld (XIZ+0xf6),BC
	ld	wa, (0xE082:24)                        ; FC785C  ld WA,(0x00e082)
	extz	xwa                                   ; FC7861  extz XWA
	ld	iy, (xwa+9)                             ; FC7863  ld IY,(XWA+0x09)
	ld	hl, bc                                  ; FC7866  ld HL,BC
	add	hl, iy                                 ; FC7868  add HL,IY
	cp	hl, 50                                  ; FC786A  cp HL,0x0032
	jr gt, sub_FC7481__FC7895                  ; FC786E  jr GT,0xfc7895
	cps	hl, 0                                  ; FC7870  cp HL,0
	jr ge, sub_FC7481__FC78AD                  ; FC7872  jr GE,0xfc78ad
	jr sub_FC7481__FC789E                      ; FC7874  jr T,0xfc789e
sub_FC7481__FC7876:
	ld	c, (xix+18)                             ; FC7876  ld C,(XIX+0x12)
	res	7, c                                   ; FC7879  res 0x07,C
	extz	bc                                    ; FC787C  extz BC
	ld	(xiz-10), bc                            ; FC787E  ld (XIZ+0xf6),BC
	ld	wa, (0xE082:24)                        ; FC7881  ld WA,(0x00e082)
	extz	xwa                                   ; FC7886  extz XWA
	ld	iy, (xwa+9)                             ; FC7888  ld IY,(XWA+0x09)
	ld	hl, bc                                  ; FC788B  ld HL,BC
	add	hl, iy                                 ; FC788D  add HL,IY
	cp	hl, 50                                  ; FC788F  cp HL,0x0032
	jr le, sub_FC7481__FC789A                  ; FC7893  jr LE,0xfc789a
sub_FC7481__FC7895:
	ldw	hl, 50                                 ; FC7895  ld HL,0x0032
	jr sub_FC7481__FC78AD                      ; FC7898  jr T,0xfc78ad
sub_FC7481__FC789A:
	cps	hl, 0                                  ; FC789A  cp HL,0
	jr ge, sub_FC7481__FC78AD                  ; FC789C  jr GE,0xfc78ad
sub_FC7481__FC789E:
	ldw	hl, 0                                  ; FC789E  ld HL,0x0000
	jr sub_FC7481__FC78AD                      ; FC78A1  jr T,0xfc78ad
sub_FC7481__FC78A3:
	ld	c, (xix+18)                             ; FC78A3  ld C,(XIX+0x12)
	res	7, c                                   ; FC78A6  res 0x07,C
	extz	bc                                    ; FC78A9  extz BC
	ld	hl, bc                                  ; FC78AB  ld HL,BC
sub_FC7481__FC78AD:
	ld	bc, hl                                  ; FC78AD  ld BC,HL
	exts	xbc                                   ; FC78AF  exts XBC
	add	xbc, 0xFE0296                          ; FC78B1  add XBC,0x00fe0296
	ld	a, (xbc)                                ; FC78B7  ld A,(XBC)
	ld	bc, (0xE084:24)                        ; FC78B9  ld BC,(0x00e084)
	extz	xbc                                   ; FC78BE  extz XBC
	ld	(xbc+41), a                             ; FC78C0  ld (XBC+0x29),A
	ld	xix, (xiz-4)                            ; FC78C3  ld XIX,(XIZ+0xfc)
	ld	bc, (0xE084:24)                        ; FC78C6  ld BC,(0x00e084)
	extz	xbc                                   ; FC78CB  extz XBC
	ld	a, (xbc+1)                              ; FC78CD  ld A,(XBC+0x01)
	and	a, 3                                   ; FC78D0  and A,0x03
	extz	wa                                    ; FC78D3  extz WA
	cps	wa, 1                                  ; FC78D5  cp WA,1
	jr z, sub_FC7481__FC78E0                   ; FC78D7  jr Z,0xfc78e0
	cps	wa, 2                                  ; FC78D9  cp WA,2
	jr z, sub_FC7481__FC7927                   ; FC78DB  jr Z,0xfc7927
	jrl sub_FC7481__FC796D                     ; FC78DD  jrl T,0xfc796d
sub_FC7481__FC78E0:
	ld	c, (xix+22)                             ; FC78E0  ld C,(XIX+0x16)
	res	7, c                                   ; FC78E3  res 0x07,C
	extz	bc                                    ; FC78E6  extz BC
	ld	hl, bc                                  ; FC78E8  ld HL,BC
	ld	wa, (0xE082:24)                        ; FC78EA  ld WA,(0x00e082)
	extz	xwa                                   ; FC78EF  extz XWA
	ld	iy, (xwa+11)                            ; FC78F1  ld IY,(XWA+0x0b)
	add	bc, iy                                 ; FC78F4  add BC,IY
	ld	hl, bc                                  ; FC78F6  ld HL,BC
	ld	bc, (0xE084:24)                        ; FC78F8  ld BC,(0x00e084)
	extz	xbc                                   ; FC78FD  extz XBC
	ld	(xbc+26), hl                            ; FC78FF  ld (XBC+0x1a),HL
	ld	c, (xix+32)                             ; FC7902  ld C,(XIX+0x20)
	res	7, c                                   ; FC7905  res 0x07,C
	extz	bc                                    ; FC7908  extz BC
	ld	hl, bc                                  ; FC790A  ld HL,BC
	ld	wa, (0xE082:24)                        ; FC790C  ld WA,(0x00e082)
	extz	xwa                                   ; FC7911  extz XWA
	ld	iy, (xwa+11)                            ; FC7913  ld IY,(XWA+0x0b)
	add	bc, iy                                 ; FC7916  add BC,IY
	ld	hl, bc                                  ; FC7918  ld HL,BC
	ld	bc, (0xE084:24)                        ; FC791A  ld BC,(0x00e084)
	extz	xbc                                   ; FC791F  extz XBC
	ld	(xbc+28), hl                            ; FC7921  ld (XBC+0x1c),HL
	jrl sub_FC7481__FC7991                     ; FC7924  jrl T,0xfc7991
sub_FC7481__FC7927:
	ld	c, (xix+22)                             ; FC7927  ld C,(XIX+0x16)
	res	7, c                                   ; FC792A  res 0x07,C
	extz	bc                                    ; FC792D  extz BC
	ld	hl, bc                                  ; FC792F  ld HL,BC
	ld	wa, (0xE082:24)                        ; FC7931  ld WA,(0x00e082)
	extz	xwa                                   ; FC7936  extz XWA
	ld	iy, (xwa+11)                            ; FC7938  ld IY,(XWA+0x0b)
	sub	bc, iy                                 ; FC793B  sub BC,IY
	ld	hl, bc                                  ; FC793D  ld HL,BC
	ld	bc, (0xE084:24)                        ; FC793F  ld BC,(0x00e084)
	extz	xbc                                   ; FC7944  extz XBC
	ld	(xbc+26), hl                            ; FC7946  ld (XBC+0x1a),HL
	ld	c, (xix+32)                             ; FC7949  ld C,(XIX+0x20)
	res	7, c                                   ; FC794C  res 0x07,C
	extz	bc                                    ; FC794F  extz BC
	ld	hl, bc                                  ; FC7951  ld HL,BC
	ld	wa, (0xE082:24)                        ; FC7953  ld WA,(0x00e082)
	extz	xwa                                   ; FC7958  extz XWA
	ld	iy, (xwa+11)                            ; FC795A  ld IY,(XWA+0x0b)
	sub	bc, iy                                 ; FC795D  sub BC,IY
	ld	hl, bc                                  ; FC795F  ld HL,BC
	ld	bc, (0xE084:24)                        ; FC7961  ld BC,(0x00e084)
	extz	xbc                                   ; FC7966  extz XBC
	ld	(xbc+28), hl                            ; FC7968  ld (XBC+0x1c),HL
	jr sub_FC7481__FC7991                      ; FC796B  jr T,0xfc7991
sub_FC7481__FC796D:
	ld	c, (xix+22)                             ; FC796D  ld C,(XIX+0x16)
	res	7, c                                   ; FC7970  res 0x07,C
	extz	bc                                    ; FC7973  extz BC
	ld	wa, (0xE084:24)                        ; FC7975  ld WA,(0x00e084)
	extz	xwa                                   ; FC797A  extz XWA
	ld	(xwa+26), bc                            ; FC797C  ld (XWA+0x1a),BC
	ld	c, (xix+32)                             ; FC797F  ld C,(XIX+0x20)
	res	7, c                                   ; FC7982  res 0x07,C
	extz	bc                                    ; FC7985  extz BC
	ld	wa, (0xE084:24)                        ; FC7987  ld WA,(0x00e084)
	extz	xwa                                   ; FC798C  extz XWA
	ld	(xwa+28), bc                            ; FC798E  ld (XWA+0x1c),BC
sub_FC7481__FC7991:
	calr (0xFC46A8 - 0xFC7994)                 ; FC7991  calr 0xfc46a8
	ld	xbc, (xiz-4)                            ; FC7994  ld XBC,(XIZ+0xfc)
	ld	(xiz-8), xbc                            ; FC7997  ld (XIZ+0xf8),XBC
	ld	d, (xbc+33)                             ; FC799A  ld D,(XBC+0x21)
	cps	d, 0                                   ; FC799D  cp D,0
	jr ge, sub_FC7481__FC79AD                  ; FC799F  jr GE,0xfc79ad
	ld	c, d                                    ; FC79A1  ld C,D
	exts	bc                                    ; FC79A3  exts BC
	ld	hl, bc                                  ; FC79A5  ld HL,BC
	neg	bc                                     ; FC79A7  neg BC
	ld	hl, bc                                  ; FC79A9  ld HL,BC
	jr sub_FC7481__FC79B3                      ; FC79AB  jr T,0xfc79b3
sub_FC7481__FC79AD:
	ld	c, d                                    ; FC79AD  ld C,D
	exts	bc                                    ; FC79AF  exts BC
	ld	hl, bc                                  ; FC79B1  ld HL,BC
sub_FC7481__FC79B3:
	ld	bc, (0xE084:24)                        ; FC79B3  ld BC,(0x00e084)
	extz	xbc                                   ; FC79B8  extz XBC
	ld	a, (xbc+2)                              ; FC79BA  ld A,(XBC+0x02)
	and	a, 48                                  ; FC79BD  and A,0x30
	srl	a, 4                                   ; FC79C0  srl 0x04,A
	extz	wa                                    ; FC79C3  extz WA
	cps	wa, 1                                  ; FC79C5  cp WA,1
	jr z, sub_FC7481__FC79CF                   ; FC79C7  jr Z,0xfc79cf
	cps	wa, 2                                  ; FC79C9  cp WA,2
	jr z, sub_FC7481__FC79E7                   ; FC79CB  jr Z,0xfc79e7
	jr sub_FC7481__FC7A01                      ; FC79CD  jr T,0xfc7a01
sub_FC7481__FC79CF:
	ld	bc, (0xE082:24)                        ; FC79CF  ld BC,(0x00e082)
	extz	xbc                                   ; FC79D4  extz XBC
	ld	wa, (xbc+15)                            ; FC79D6  ld WA,(XBC+0x0f)
	add	wa, hl                                 ; FC79D9  add WA,HL
	ld	bc, (0xE084:24)                        ; FC79DB  ld BC,(0x00e084)
	extz	xbc                                   ; FC79E0  extz XBC
	ld	(xbc+30), wa                            ; FC79E2  ld (XBC+0x1e),WA
	jr sub_FC7481__FC7A0B                      ; FC79E5  jr T,0xfc7a0b
sub_FC7481__FC79E7:
	ld	bc, (0xE082:24)                        ; FC79E7  ld BC,(0x00e082)
	extz	xbc                                   ; FC79EC  extz XBC
	ld	wa, (xbc+15)                            ; FC79EE  ld WA,(XBC+0x0f)
	ld	iy, hl                                  ; FC79F1  ld IY,HL
	sub	iy, wa                                 ; FC79F3  sub IY,WA
	ld	wa, (0xE084:24)                        ; FC79F5  ld WA,(0x00e084)
	extz	xwa                                   ; FC79FA  extz XWA
	ld	(xwa+30), iy                            ; FC79FC  ld (XWA+0x1e),IY
	jr sub_FC7481__FC7A0B                      ; FC79FF  jr T,0xfc7a0b
sub_FC7481__FC7A01:
	ld	bc, (0xE084:24)                        ; FC7A01  ld BC,(0x00e084)
	extz	xbc                                   ; FC7A06  extz XBC
	ld	(xbc+30), hl                            ; FC7A08  ld (XBC+0x1e),HL
sub_FC7481__FC7A0B:
	dec	1, e                                   ; FC7A0B  dec 1,E
	extpfx7 0xD2, 0x84, 0xE0, 0x00, 0x38, 0x2A, 0x00 ; FC7A0D  add (0x00e084),0x002a
	cps	e, 0                                   ; FC7A14  cp E,0
	jrl nz, sub_FC7481__FC7590                 ; FC7A16  jrl NZ,0xfc7590
sub_FC7481__FC7A19:
	pop	xix                                    ; FC7A19  pop XIX
	popw	de                                    ; FC7A1A  pop DE
	popw	hl                                    ; FC7A1B  pop HL
	unlk32 xiz                                 ; FC7A1C  unlk XIZ
	ret                                        ; FC7A1E  ret
; --------------------------------------------------------------------------
; sub_FC7A1F -- 0xFC7A1F..0xFC7AB3 (149 bytes)
;
; Called from: 9 site(s) outside this module:
;          0xFB6CD9 in sub_FB6BA8__FB6CD1, 0xFB9537 in sub_FB9414__FB952F
;          0xFB9781 in ToneDB_DrumSourceNameList_SelectEntry__FB9779, 0xFB9945 in ToneDB_PercSourceNameList1_SelectEntry__FB993D
;          0xFB9AB8 in ToneDB_PercSourceNameList2_SelectEntry__FB9AB0, 0xFBCD0D in sub_FBCBA7__FBCD05
;          0xFBD1CA in sub_FBD0A2__FBD1C2, 0xFBD569 in sub_FBD46B__FBD561
;          0xFBD84E in sub_FBD6FC__FBD846
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Calls:   0xFC6CEA = sub_FC6CEA, 0xFC6FFD = sub_FC6FFD
; Evidence: the listing below is the byte-identical round-trip of 0xFC7A1F-0xFC7AB3
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC7A1F:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC7A1F  link XIZ,0x0000
	push	xhl                                   ; FC7A23  push XHL
	pushw	de                                   ; FC7A24  push DE
	push	xix                                   ; FC7A25  push XIX
	lda	xix, (0xE082:24)                       ; FC7A26  lda XIX,0x00e082
	ldb	c, 0xBB                                ; FC7A2B  ld C,0xbb
	extpfx3 0x8E, 0x08, 0x43                   ; FC7A2D  mul BC,(XIZ+0x08)
	ld	de, bc                                  ; FC7A30  ld DE,BC
	ldw	wa, 0x5D23                             ; FC7A32  ld WA,0x5d23
	add	wa, bc                                 ; FC7A35  add WA,BC
	ld	(xix), wa                               ; FC7A37  ld (XIX),WA
	ld	bc, (xix)                               ; FC7A39  ld BC,(XIX)
	extz	xbc                                   ; FC7A3B  extz XBC
	ld	(xbc), 0x80                             ; FC7A3D  ld (XBC),0x80
	cp (xiz+10), 0x00                          ; FC7A40  cp (XIZ+0x0a),0x00
	jrl nz, sub_FC7A1F__FC7AAE                 ; FC7A44  jrl NZ,0xfc7aae
	ld	bc, (xix)                               ; FC7A47  ld BC,(XIX)
	extz	xbc                                   ; FC7A49  extz XBC
	ld	xwa, (xbc+22)                           ; FC7A4B  ld XWA,(XBC+0x16)
	ld	c, (xwa+11)                             ; FC7A4E  ld C,(XWA+0x0b)
	and	c, 0xC0                                ; FC7A51  and C,0xc0
	or	c, h                                    ; FC7A54  or C,H
	ld	h, c                                    ; FC7A56  ld H,C
	srl	h, 2                                   ; FC7A58  srl 0x02,H
	ld	bc, (xix)                               ; FC7A5B  ld BC,(XIX)
	extz	xbc                                   ; FC7A5D  extz XBC
	ld	xwa, (xbc+64)                           ; FC7A5F  ld XWA,(XBC+0x40)
	ld	c, (xwa+11)                             ; FC7A62  ld C,(XWA+0x0b)
	and	c, 0xC0                                ; FC7A65  and C,0xc0
	or	c, h                                    ; FC7A68  or C,H
	and	c, 0xF0                                ; FC7A6A  and C,0xf0
	jr z, sub_FC7A1F__FC7A74                   ; FC7A6D  jr Z,0xfc7a74
	calr (0xFC6FFD - 0xFC7A72)                 ; FC7A6F  calr 0xfc6ffd
	jr sub_FC7A1F__FC7A77                      ; FC7A72  jr T,0xfc7a77
sub_FC7A1F__FC7A74:
	calr (0xFC6CEA - 0xFC7A77)                 ; FC7A74  calr 0xfc6cea
sub_FC7A1F__FC7A77:
	ld	hl, (xix)                               ; FC7A77  ld HL,(XIX)
	add	hl, 19                                 ; FC7A79  add HL,0x0013
	ldb	d, 2                                   ; FC7A7D  ld D,0x02
sub_FC7A1F__FC7A7F:
	extz	xhl                                   ; FC7A7F  extz XHL
	ld	xbc, (xhl+3)                            ; FC7A81  ld XBC,(XHL+0x03)
	ld	xix, xbc                                ; FC7A84  ld XIX,XBC
	ld	wa, (xhl+18)                            ; FC7A86  ld WA,(XHL+0x12)
	sra	wa, 8                                  ; FC7A89  sra 0x08,WA
	ld	(xbc+26), a                             ; FC7A8C  ld (XBC+0x1a),A
	ld	c, (xhl+18)                             ; FC7A8F  ld C,(XHL+0x12)
	ld	(xix+27), c                             ; FC7A92  ld (XIX+0x1b),C
	ld	bc, (xhl+20)                            ; FC7A95  ld BC,(XHL+0x14)
	sra	bc, 8                                  ; FC7A98  sra 0x08,BC
	ld	(xix+38), c                             ; FC7A9B  ld (XIX+0x26),C
	ld	c, (xhl+20)                             ; FC7A9E  ld C,(XHL+0x14)
	ld	(xix+39), c                             ; FC7AA1  ld (XIX+0x27),C
	dec	1, d                                   ; FC7AA4  dec 1,D
	add	hl, 42                                 ; FC7AA6  add HL,0x002a
	cps	d, 0                                   ; FC7AAA  cp D,0
	jr nz, sub_FC7A1F__FC7A7F                  ; FC7AAC  jr NZ,0xfc7a7f
sub_FC7A1F__FC7AAE:
	pop	xix                                    ; FC7AAE  pop XIX
	popw	de                                    ; FC7AAF  pop DE
	pop	xhl                                    ; FC7AB0  pop XHL
	unlk32 xiz                                 ; FC7AB1  unlk XIZ
	ret                                        ; FC7AB3  ret
; --------------------------------------------------------------------------
; sub_FC7AB4 -- 0xFC7AB4..0xFC7B63 (176 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFBEB3D in sub_FBDCD3__FBEAF1, 0xFBF832 in sub_FBF280__FBF7FE
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: writes 0x00E084
; Evidence: the listing below is the byte-identical round-trip of 0xFC7AB4-0xFC7B63
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC7AB4:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC7AB4  link XIZ,0x0000
	pushw	hl                                   ; FC7AB8  push HL
	pushw	de                                   ; FC7AB9  push DE
	push	xix                                   ; FC7ABA  push XIX
	lda	xix, (0xE082:24)                       ; FC7ABB  lda XIX,0x00e082
	ldb	c, 0xBB                                ; FC7AC0  ld C,0xbb
	extpfx3 0x8E, 0x08, 0x43                   ; FC7AC2  mul BC,(XIZ+0x08)
	ld	hl, bc                                  ; FC7AC5  ld HL,BC
	ldw	wa, 0x5D23                             ; FC7AC7  ld WA,0x5d23
	add	wa, bc                                 ; FC7ACA  add WA,BC
	ld	(xix), wa                               ; FC7ACC  ld (XIX),WA
	ldb	c, 42                                  ; FC7ACE  ld C,0x2a
	extpfx3 0x8E, 0x0A, 0x43                   ; FC7AD0  mul BC,(XIZ+0x0a)
	ld	hl, bc                                  ; FC7AD3  ld HL,BC
	add	hl, 19                                 ; FC7AD5  add HL,0x0013
	ld	bc, (xix)                               ; FC7AD9  ld BC,(XIX)
	add	bc, hl                                 ; FC7ADB  add BC,HL
	stw_da	(0xE084), bc                        ; FC7ADD  ld (0x00e084),BC
	ld	wa, bc                                  ; FC7AE2  ld WA,BC
	extz	xbc                                   ; FC7AE4  extz XBC
	ld	a, (xbc)                                ; FC7AE6  ld A,(XBC)
	and	a, 6                                   ; FC7AE8  and A,0x06
	srl	a, 1                                   ; FC7AEB  srl 0x01,A
	extz	wa                                    ; FC7AEE  extz WA
	cps	wa, 1                                  ; FC7AF0  cp WA,1
	jr z, sub_FC7AB4__FC7AFA                   ; FC7AF2  jr Z,0xfc7afa
	cps	wa, 2                                  ; FC7AF4  cp WA,2
	jr z, sub_FC7AB4__FC7B0D                   ; FC7AF6  jr Z,0xfc7b0d
	jr sub_FC7AB4__FC7B1C                      ; FC7AF8  jr T,0xfc7b1c
sub_FC7AB4__FC7AFA:
	ld	bc, (xix)                               ; FC7AFA  ld BC,(XIX)
	extz	xbc                                   ; FC7AFC  extz XBC
	ld	hl, (xbc+3)                             ; FC7AFE  ld HL,(XBC+0x03)
	ld	bc, hl                                  ; FC7B01  ld BC,HL
	add	bc, hl                                 ; FC7B03  add BC,HL
	ld	hl, bc                                  ; FC7B05  ld HL,BC
	neg	bc                                     ; FC7B07  neg BC
	ld	hl, bc                                  ; FC7B09  ld HL,BC
	jr sub_FC7AB4__FC7B1F                      ; FC7B0B  jr T,0xfc7b1f
sub_FC7AB4__FC7B0D:
	ld	bc, (xix)                               ; FC7B0D  ld BC,(XIX)
	extz	xbc                                   ; FC7B0F  extz XBC
	ld	hl, (xbc+3)                             ; FC7B11  ld HL,(XBC+0x03)
	ld	bc, hl                                  ; FC7B14  ld BC,HL
	add	bc, hl                                 ; FC7B16  add BC,HL
	ld	hl, bc                                  ; FC7B18  ld HL,BC
	jr sub_FC7AB4__FC7B1F                      ; FC7B1A  jr T,0xfc7b1f
sub_FC7AB4__FC7B1C:
	ldw	hl, 0                                  ; FC7B1C  ld HL,0x0000
sub_FC7AB4__FC7B1F:
	ld	bc, hl                                  ; FC7B1F  ld BC,HL
	sra	bc, 4                                  ; FC7B21  sra 0x04,BC
	ld	hl, bc                                  ; FC7B24  ld HL,BC
	cp	bc, 0xFFF8                              ; FC7B26  cp BC,0xfff8
	jr ge, sub_FC7AB4__FC7B31                  ; FC7B2A  jr GE,0xfc7b31
	ldw	hl, 0xFFF8                             ; FC7B2C  ld HL,0xfff8
	jr sub_FC7AB4__FC7B3A                      ; FC7B2F  jr T,0xfc7b3a
sub_FC7AB4__FC7B31:
	cp	hl, 8                                   ; FC7B31  cp HL,0x0008
	jr le, sub_FC7AB4__FC7B3A                  ; FC7B35  jr LE,0xfc7b3a
	ldw	hl, 8                                  ; FC7B37  ld HL,0x0008
sub_FC7AB4__FC7B3A:
	ld	xbc, (xiz+12)                           ; FC7B3A  ld XBC,(XIZ+0x0c)
	ld	a, (xbc+20)                             ; FC7B3D  ld A,(XBC+0x14)
	extz	wa                                    ; FC7B40  extz WA
	ld	de, wa                                  ; FC7B42  ld DE,WA
	add	wa, hl                                 ; FC7B44  add WA,HL
	ld	de, wa                                  ; FC7B46  ld DE,WA
	cp	wa, 0x7F                                ; FC7B48  cp WA,0x007f
	jr le, sub_FC7AB4__FC7B53                  ; FC7B4C  jr LE,0xfc7b53
	ldw	de, 0x7F                               ; FC7B4E  ld DE,0x007f
	jr sub_FC7AB4__FC7B5A                      ; FC7B51  jr T,0xfc7b5a
sub_FC7AB4__FC7B53:
	cps	de, 0                                  ; FC7B53  cp DE,0
	jr ge, sub_FC7AB4__FC7B5A                  ; FC7B55  jr GE,0xfc7b5a
	ldw	de, 0                                  ; FC7B57  ld DE,0x0000
sub_FC7AB4__FC7B5A:
	ld	c, e                                    ; FC7B5A  ld C,E
	ld	a, c                                    ; FC7B5C  ld A,C
	pop	xix                                    ; FC7B5E  pop XIX
	popw	de                                    ; FC7B5F  pop DE
	popw	hl                                    ; FC7B60  pop HL
	unlk32 xiz                                 ; FC7B61  unlk XIZ
	ret                                        ; FC7B63  ret
; --------------------------------------------------------------------------
; sub_FC7B64 -- 0xFC7B64..0xFC7C0C (169 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFBEA31 in sub_FBDCD3__FBE9B5, 0xFBF73A in sub_FBF280__FBF6C2
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: writes 0x00E084
; Evidence: the listing below is the byte-identical round-trip of 0xFC7B64-0xFC7C0C
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC7B64:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC7B64  link XIZ,0x0000
	pushw	hl                                   ; FC7B68  push HL
	pushw	de                                   ; FC7B69  push DE
	push	xix                                   ; FC7B6A  push XIX
	lda	xix, (0xE082:24)                       ; FC7B6B  lda XIX,0x00e082
	ldb	c, 0xBB                                ; FC7B70  ld C,0xbb
	extpfx3 0x8E, 0x08, 0x43                   ; FC7B72  mul BC,(XIZ+0x08)
	ld	hl, bc                                  ; FC7B75  ld HL,BC
	ldw	wa, 0x5D23                             ; FC7B77  ld WA,0x5d23
	ld	de, wa                                  ; FC7B7A  ld DE,WA
	add	de, bc                                 ; FC7B7C  add DE,BC
	ld	(xix), de                               ; FC7B7E  ld (XIX),DE
	ldb	c, 42                                  ; FC7B80  ld C,0x2a
	extpfx3 0x8E, 0x0A, 0x43                   ; FC7B82  mul BC,(XIZ+0x0a)
	add	bc, 19                                 ; FC7B85  add BC,0x0013
	add	bc, de                                 ; FC7B89  add BC,DE
	stw_da	(0xE084), bc                        ; FC7B8B  ld (0x00e084),BC
	ld	wa, bc                                  ; FC7B90  ld WA,BC
	extz	xbc                                   ; FC7B92  extz XBC
	ld	a, (xbc)                                ; FC7B94  ld A,(XBC)
	and	a, 24                                  ; FC7B96  and A,0x18
	srl	a, 3                                   ; FC7B99  srl 0x03,A
	extz	wa                                    ; FC7B9C  extz WA
	cps	wa, 1                                  ; FC7B9E  cp WA,1
	jr z, sub_FC7B64__FC7BA8                   ; FC7BA0  jr Z,0xfc7ba8
	cps	wa, 2                                  ; FC7BA2  cp WA,2
	jr z, sub_FC7B64__FC7BB8                   ; FC7BA4  jr Z,0xfc7bb8
	jr sub_FC7B64__FC7BCC                      ; FC7BA6  jr T,0xfc7bcc
sub_FC7B64__FC7BA8:
	ld	bc, (xix)                               ; FC7BA8  ld BC,(XIX)
	extz	xbc                                   ; FC7BAA  extz XBC
	ld	hl, (xbc+1)                             ; FC7BAC  ld HL,(XBC+0x01)
	ld	bc, hl                                  ; FC7BAF  ld BC,HL
	sra	bc, 1                                  ; FC7BB1  sra 0x01,BC
	ld	hl, bc                                  ; FC7BB4  ld HL,BC
	jr sub_FC7B64__FC7BCF                      ; FC7BB6  jr T,0xfc7bcf
sub_FC7B64__FC7BB8:
	ld	bc, (xix)                               ; FC7BB8  ld BC,(XIX)
	extz	xbc                                   ; FC7BBA  extz XBC
	ld	hl, (xbc+1)                             ; FC7BBC  ld HL,(XBC+0x01)
	ld	bc, hl                                  ; FC7BBF  ld BC,HL
	neg	bc                                     ; FC7BC1  neg BC
	ld	hl, bc                                  ; FC7BC3  ld HL,BC
	sra	bc, 1                                  ; FC7BC5  sra 0x01,BC
	ld	hl, bc                                  ; FC7BC8  ld HL,BC
	jr sub_FC7B64__FC7BCF                      ; FC7BCA  jr T,0xfc7bcf
sub_FC7B64__FC7BCC:
	ldw	hl, 0                                  ; FC7BCC  ld HL,0x0000
sub_FC7B64__FC7BCF:
	cp	hl, 0xFFF0                              ; FC7BCF  cp HL,0xfff0
	jr ge, sub_FC7B64__FC7BDA                  ; FC7BD3  jr GE,0xfc7bda
	ldw	hl, 0xFFF0                             ; FC7BD5  ld HL,0xfff0
	jr sub_FC7B64__FC7BE3                      ; FC7BD8  jr T,0xfc7be3
sub_FC7B64__FC7BDA:
	cp	hl, 16                                  ; FC7BDA  cp HL,0x0010
	jr le, sub_FC7B64__FC7BE3                  ; FC7BDE  jr LE,0xfc7be3
	ldw	hl, 16                                 ; FC7BE0  ld HL,0x0010
sub_FC7B64__FC7BE3:
	ld	xbc, (xiz+12)                           ; FC7BE3  ld XBC,(XIZ+0x0c)
	ld	a, (xbc+20)                             ; FC7BE6  ld A,(XBC+0x14)
	extz	wa                                    ; FC7BE9  extz WA
	ld	de, wa                                  ; FC7BEB  ld DE,WA
	add	wa, hl                                 ; FC7BED  add WA,HL
	ld	de, wa                                  ; FC7BEF  ld DE,WA
	cp	wa, 0x7F                                ; FC7BF1  cp WA,0x007f
	jr le, sub_FC7B64__FC7BFC                  ; FC7BF5  jr LE,0xfc7bfc
	ldw	de, 0x7F                               ; FC7BF7  ld DE,0x007f
	jr sub_FC7B64__FC7C03                      ; FC7BFA  jr T,0xfc7c03
sub_FC7B64__FC7BFC:
	cps	de, 0                                  ; FC7BFC  cp DE,0
	jr ge, sub_FC7B64__FC7C03                  ; FC7BFE  jr GE,0xfc7c03
	ldw	de, 0                                  ; FC7C00  ld DE,0x0000
sub_FC7B64__FC7C03:
	ld	c, e                                    ; FC7C03  ld C,E
	ld	a, c                                    ; FC7C05  ld A,C
	pop	xix                                    ; FC7C07  pop XIX
	popw	de                                    ; FC7C08  pop DE
	popw	hl                                    ; FC7C09  pop HL
	unlk32 xiz                                 ; FC7C0A  unlk XIZ
	ret                                        ; FC7C0C  ret
; --------------------------------------------------------------------------
; sub_FC7C0D -- 0xFC7C0D..0xFC7CF8 (236 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFACB68 in sub_FACAB7__FACB5F
; Inputs:  frame `link XIZ,-2`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: writes 0x00E084
; Calls:   0xFC49AD = sub_FC49AD
; Evidence: the listing below is the byte-identical round-trip of 0xFC7C0D-0xFC7CF8
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC7C0D:
	link32 0xEE, 0x0C, 0xFE, 0xFF              ; FC7C0D  link XIZ,0xfffe
	pushw	hl                                   ; FC7C11  push HL
	pushw	de                                   ; FC7C12  push DE
	push	xix                                   ; FC7C13  push XIX
	lda	xix, (0xE086:24)                       ; FC7C14  lda XIX,0x00e086
	ldb	l, 0                                   ; FC7C19  ld L,0x00
	ldb	c, 37                                  ; FC7C1B  ld C,0x25
	extpfx3 0x8E, 0x08, 0x43                   ; FC7C1D  mul BC,(XIZ+0x08)
	ld	de, bc                                  ; FC7C20  ld DE,BC
	ldw	wa, 0x753E                             ; FC7C22  ld WA,0x753e
	add	wa, bc                                 ; FC7C25  add WA,BC
	ld	(xiz-2), wa                             ; FC7C27  ld (XIZ+0xfe),WA
	ld	(xix), wa                               ; FC7C2A  ld (XIX),WA
	ld	bc, (xiz-2)                             ; FC7C2C  ld BC,(XIZ+0xfe)
	extz	xbc                                   ; FC7C2F  extz XBC
	ld	wa, (xbc+5)                             ; FC7C31  ld WA,(XBC+0x05)
	stw_da	(0xE084), wa                        ; FC7C34  ld (0x00e084),WA
	sub	bc, bc                                 ; FC7C39  sub BC,BC
	cp	wa, bc                                  ; FC7C3B  cp WA,BC
	jrl z, sub_FC7C0D__FC7CF1                  ; FC7C3D  jrl Z,0xfc7cf1
	ld	bc, (xix)                               ; FC7C40  ld BC,(XIX)
	extz	xbc                                   ; FC7C42  extz XBC
	ld	h, (xbc+28)                             ; FC7C44  ld H,(XBC+0x1c)
	cps	h, 1                                   ; FC7C47  cp H,1
	jr nz, sub_FC7C0D__FC7CB9                  ; FC7C49  jr NZ,0xfc7cb9
	ld	bc, (xix)                               ; FC7C4B  ld BC,(XIX)
	extz	xbc                                   ; FC7C4D  extz XBC
	ld	a, (xbc+30)                             ; FC7C4F  ld A,(XBC+0x1e)
	extz	wa                                    ; FC7C52  extz WA
	ld	hl, wa                                  ; FC7C54  ld HL,WA
	ldw	de, 31                                 ; FC7C56  ld DE,0x001f
	ld	bc, (xix)                               ; FC7C59  ld BC,(XIX)
	extz	xbc                                   ; FC7C5B  extz XBC
	extpfx5 0xD3, 0x07, 0xE4, 0xE8, 0x25       ; FC7C5D  ld IY,(XBC+DE)
	add	iy, wa                                 ; FC7C62  add IY,WA
	ld	(xiz-2), iy                             ; FC7C64  ld (XIZ+0xfe),IY
	ld	bc, (xix)                               ; FC7C67  ld BC,(XIX)
	extz	xbc                                   ; FC7C69  extz XBC
	add	bc, de                                 ; FC7C6B  add BC,DE
	ld	(xbc), iy                               ; FC7C6D  ld (XBC),IY
	ld	bc, (xix)                               ; FC7C6F  ld BC,(XIX)
	extz	xbc                                   ; FC7C71  extz XBC
	extpfx5 0xD3, 0x07, 0xE4, 0xE8, 0x20       ; FC7C73  ld WA,(XBC+DE)
	ld	hl, wa                                  ; FC7C78  ld HL,WA
	and	hl, 0x1FF                              ; FC7C7A  and HL,0x01ff
	ld	bc, (xix)                               ; FC7C7E  ld BC,(XIX)
	extz	xbc                                   ; FC7C80  extz XBC
	add	bc, de                                 ; FC7C82  add BC,DE
	ld	(xbc), hl                               ; FC7C84  ld (XBC),HL
	ld	bc, (xix)                               ; FC7C86  ld BC,(XIX)
	extz	xbc                                   ; FC7C88  extz XBC
	extpfx5 0xD3, 0x07, 0xE4, 0xE8, 0x20       ; FC7C8A  ld WA,(XBC+DE)
	extz	xwa                                   ; FC7C8F  extz XWA
	add	xwa, 0xFE02C9                          ; FC7C91  add XWA,0x00fe02c9
	ld	c, (xwa)                                ; FC7C97  ld C,(XWA)
	exts	bc                                    ; FC7C99  exts BC
	ld	hl, bc                                  ; FC7C9B  ld HL,BC
	ld	wa, (xix)                               ; FC7C9D  ld WA,(XIX)
	extz	xwa                                   ; FC7C9F  extz XWA
	ld	c, (xwa+29)                             ; FC7CA1  ld C,(XWA+0x1d)
	extz	bc                                    ; FC7CA4  extz BC
	muls	xbc, xhl                              ; FC7CA6  muls XBC,HL
	exts	xbc                                   ; FC7CA8  exts XBC
	divs	bc, 50                                ; FC7CAA  divs BC,0x0032
	ld	hl, bc                                  ; FC7CAE  ld HL,BC
	ld	wa, (xix)                               ; FC7CB0  ld WA,(XIX)
	extz	xwa                                   ; FC7CB2  extz XWA
	ld	(xwa+33), bc                            ; FC7CB4  ld (XWA+0x21),BC
	jr sub_FC7C0D__FC7CE5                      ; FC7CB7  jr T,0xfc7ce5
sub_FC7C0D__FC7CB9:
	cps	h, 4                                   ; FC7CB9  cp H,4
	jr nz, sub_FC7C0D__FC7CD0                  ; FC7CBB  jr NZ,0xfc7cd0
	ld	bc, (xix)                               ; FC7CBD  ld BC,(XIX)
	extz	xbc                                   ; FC7CBF  extz XBC
	ld	(xbc+28), 1                             ; FC7CC1  ld (XBC+0x1c),0x01
	ld	bc, (xix)                               ; FC7CC5  ld BC,(XIX)
	extz	xbc                                   ; FC7CC7  extz XBC
	extpfx5 0xB9, 0x1F, 0x02, 0x00, 0x00       ; FC7CC9  ld (XBC+0x1f),0x0000
	jr sub_FC7C0D__FC7CDC                      ; FC7CCE  jr T,0xfc7cdc
sub_FC7C0D__FC7CD0:
	cps	h, 3                                   ; FC7CD0  cp H,3
	jr nz, sub_FC7C0D__FC7CF1                  ; FC7CD2  jr NZ,0xfc7cf1
	ld	bc, (xix)                               ; FC7CD4  ld BC,(XIX)
	extz	xbc                                   ; FC7CD6  extz XBC
	ld	(xbc+28), 0                             ; FC7CD8  ld (XBC+0x1c),0x00
sub_FC7C0D__FC7CDC:
	ld	bc, (xix)                               ; FC7CDC  ld BC,(XIX)
	extz	xbc                                   ; FC7CDE  extz XBC
	extpfx5 0xB9, 0x21, 0x02, 0x00, 0x00       ; FC7CE0  ld (XBC+0x21),0x0000
sub_FC7C0D__FC7CE5:
	ld	xbc, (xiz+10)                           ; FC7CE5  ld XBC,(XIZ+0x0a)
	push	xbc                                   ; FC7CE8  push XBC
	calr (0xFC49AD - 0xFC7CEC)                 ; FC7CE9  calr 0xfc49ad
	pop	xiy                                    ; FC7CEC  pop XIY
	ldb	a, 1                                   ; FC7CED  ld A,0x01
	jr sub_FC7C0D__FC7CF3                      ; FC7CEF  jr T,0xfc7cf3
sub_FC7C0D__FC7CF1:
	ld	a, l                                    ; FC7CF1  ld A,L
sub_FC7C0D__FC7CF3:
	pop	xix                                    ; FC7CF3  pop XIX
	popw	de                                    ; FC7CF4  pop DE
	popw	hl                                    ; FC7CF5  pop HL
	unlk32 xiz                                 ; FC7CF6  unlk XIZ
	ret                                        ; FC7CF8  ret
; --------------------------------------------------------------------------
; sub_FC7CF9 -- 0xFC7CF9..0xFC7DAE (182 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFB05D8 in ExtBoard_ProbeAndInstallBases__FB05CD
; Inputs:  frame `link XIZ,-10`; no positive frame slot is read
; Outputs: no absolute-addressed write.
; Calls:   0xFC40E6 = sub_FC40E6
; Evidence: the listing below is the byte-identical round-trip of 0xFC7CF9-0xFC7DAE
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC7CF9:
	link32 0xEE, 0x0C, 0xF6, 0xFF              ; FC7CF9  link XIZ,0xfff6
	pushw	hl                                   ; FC7CFD  push HL
	pushw	de                                   ; FC7CFE  push DE
	push	xix                                   ; FC7CFF  push XIX
	calr (0xFC40E6 - 0xFC7D03)                 ; FC7D00  calr 0xfc40e6
	ld	xix, 0                                  ; FC7D03  ld XIX,0x00000000
	ldb	d, 33                                  ; FC7D08  ld D,0x21
sub_FC7CF9__FC7D0A:
	ldw	hl, 0                                  ; FC7D0A  ld HL,0x0000
sub_FC7CF9__FC7D0D:
	ld	(xiz-4), hl                             ; FC7D0D  ld (XIZ+0xfc),HL
	ld	bc, ix                                  ; FC7D10  ld BC,IX
	extpfx3 0x9E, 0xFC, 0x81                   ; FC7D12  add BC,(XIZ+0xfc)
	ld	(xiz-6), bc                             ; FC7D15  ld (XIZ+0xfa),BC
	add	bc, 19                                 ; FC7D18  add BC,0x0013
	ld	(xiz-8), bc                             ; FC7D1C  ld (XIZ+0xf8),BC
	ldw	wa, 0x5D23                             ; FC7D1F  ld WA,0x5d23
	add	wa, bc                                 ; FC7D22  add WA,BC
	extz	xwa                                   ; FC7D24  extz XWA
	extpfx2 0xB0, 0xB7                         ; FC7D26  res 7,(XWA)
	ld	bc, (xiz-6)                             ; FC7D28  ld BC,(XIZ+0xfa)
	add	bc, 22                                 ; FC7D2B  add BC,0x0016
	ld	(xiz-10), bc                            ; FC7D2F  ld (XIZ+0xf6),BC
	sub	xwa, xwa                               ; FC7D32  sub XWA,XWA
	extz	xbc                                   ; FC7D34  extz XBC
	ld	(xbc+0x5D23), xwa                       ; FC7D36  ld (XBC+0x5d23),XWA
	add	hl, 42                                 ; FC7D3B  add HL,0x002a
	cp	hl, 0xA8                                ; FC7D3F  cp HL,0x00a8
	jr c, sub_FC7CF9__FC7D0D                   ; FC7D43  jr C,0xfc7d0d
	add	xix, 0xBB                              ; FC7D45  add XIX,0x000000bb
	dec	1, d                                   ; FC7D4B  dec 1,D
	cps	d, 0                                   ; FC7D4D  cp D,0
	jr nz, sub_FC7CF9__FC7D0A                  ; FC7D4F  jr NZ,0xfc7d0a
	ldw	hl, 0                                  ; FC7D51  ld HL,0x0000
	ldw	ix, 7                                  ; FC7D54  ld IX,0x0007
	ldw	de, 1                                  ; FC7D57  ld DE,0x0001
	ldw (xiz-2), 0x0005                        ; FC7D5A  ld (XIZ+0xfe),0x0005
sub_FC7CF9__FC7D5F:
	ld	(xiz-4), ix                             ; FC7D5F  ld (XIZ+0xfc),IX
	ld	bc, (xiz-4)                             ; FC7D62  ld BC,(XIZ+0xfc)
	extz	xbc                                   ; FC7D65  extz XBC
	ld	(xbc+0x753E), 0xFF                      ; FC7D67  ld (XBC+0x753e),0xff
	ld	(xiz-6), de                             ; FC7D6D  ld (XIZ+0xfa),DE
	sub	xwa, xwa                               ; FC7D70  sub XWA,XWA
	ld	bc, (xiz-6)                             ; FC7D72  ld BC,(XIZ+0xfa)
	extz	xbc                                   ; FC7D75  extz XBC
	ld	(xbc+0x753E), xwa                       ; FC7D77  ld (XBC+0x753e),XWA
	ld	wa, (xiz-2)                             ; FC7D7C  ld WA,(XIZ+0xfe)
	ld	(xiz-8), wa                             ; FC7D7F  ld (XIZ+0xf8),WA
	sub	iy, iy                                 ; FC7D82  sub IY,IY
	extz	xwa                                   ; FC7D84  extz XWA
	ld	(xwa+0x753E), iy                        ; FC7D86  ld (XWA+0x753e),IY
	add	hl, 37                                 ; FC7D8B  add HL,0x0025
	add	wa, 37                                 ; FC7D8F  add WA,0x0025
	ld	(xiz-2), wa                             ; FC7D93  ld (XIZ+0xfe),WA
	ld	de, bc                                  ; FC7D96  ld DE,BC
	add	de, 37                                 ; FC7D98  add DE,0x0025
	ld	ix, (xiz-4)                             ; FC7D9C  ld IX,(XIZ+0xfc)
	add	ix, 37                                 ; FC7D9F  add IX,0x0025
	cp	hl, 0x940                               ; FC7DA3  cp HL,0x0940
	jr c, sub_FC7CF9__FC7D5F                   ; FC7DA7  jr C,0xfc7d5f
	pop	xix                                    ; FC7DA9  pop XIX
	popw	de                                    ; FC7DAA  pop DE
	popw	hl                                    ; FC7DAB  pop HL
	unlk32 xiz                                 ; FC7DAC  unlk XIZ
	ret                                        ; FC7DAE  ret
; --------------------------------------------------------------------------
; sub_FC7DAF -- 0xFC7DAF..0xFC7E0F (97 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFAC3CC in sub_FAC34D
;          1 site(s) inside this module:
;          0xFC3E91
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Calls:   0xFC405E = sub_FC405E, 0xFC40A9 = sub_FC40A9
; Evidence: the listing below is the byte-identical round-trip of 0xFC7DAF-0xFC7E0F
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC7DAF:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC7DAF  link XIZ,0x0000
	pushw	hl                                   ; FC7DB3  push HL
	pushw	de                                   ; FC7DB4  push DE
	push	xix                                   ; FC7DB5  push XIX
	lda	xix, (0xE086:24)                       ; FC7DB6  lda XIX,0x00e086
	ldb	c, 37                                  ; FC7DBB  ld C,0x25
	extpfx3 0x8E, 0x08, 0x43                   ; FC7DBD  mul BC,(XIZ+0x08)
	ld	de, bc                                  ; FC7DC0  ld DE,BC
	ldw	wa, 0x753E                             ; FC7DC2  ld WA,0x753e
	add	wa, bc                                 ; FC7DC5  add WA,BC
	ld	(xix), wa                               ; FC7DC7  ld (XIX),WA
	ld	bc, (xix)                               ; FC7DC9  ld BC,(XIX)
	extz	xbc                                   ; FC7DCB  extz XBC
	ld	h, (xbc+7)                              ; FC7DCD  ld H,(XBC+0x07)
	cp	h, 64                                   ; FC7DD0  cp H,0x40
	jr nc, sub_FC7DAF__FC7DDD                  ; FC7DD3  jr NC,0xfc7ddd
	push	0                                     ; FC7DD5  push 0x00
	push	h                                     ; FC7DD7  push H
	calr (0xFC40A9 - 0xFC7DDC)                 ; FC7DD9  calr 0xfc40a9
	popw	bc                                    ; FC7DDC  pop BC
sub_FC7DAF__FC7DDD:
	pushw	0xFF                                 ; FC7DDD  push 0x00ff
	calr (0xFC405E - 0xFC7DE3)                 ; FC7DE0  calr 0xfc405e
	ld	h, a                                    ; FC7DE3  ld H,A
	ld	bc, (xix)                               ; FC7DE5  ld BC,(XIX)
	extz	xbc                                   ; FC7DE7  extz XBC
	ld	(xbc+7), a                              ; FC7DE9  ld (XBC+0x07),A
	ld	bc, (xix)                               ; FC7DEC  ld BC,(XIX)
	extz	xbc                                   ; FC7DEE  extz XBC
	ld	a, (xbc+7)                              ; FC7DF0  ld A,(XBC+0x07)
	extz	wa                                    ; FC7DF3  extz WA
	ld	hl, wa                                  ; FC7DF5  ld HL,WA
	sll	hl, 8                                  ; FC7DF7  sll 0x08,HL
	ld	xbc, (xiz+10)                           ; FC7DFA  ld XBC,(XIZ+0x0a)
	ld	(xbc), hl                               ; FC7DFD  ld (XBC),HL
	ld	bc, hl                                  ; FC7DFF  ld BC,HL
	set	2, bc                                  ; FC7E01  set 0x02,BC
	ld	xwa, (xiz+10)                           ; FC7E04  ld XWA,(XIZ+0x0a)
	ld	(xwa), bc                               ; FC7E07  ld (XWA),BC
	popw	bc                                    ; FC7E09  pop BC
	pop	xix                                    ; FC7E0A  pop XIX
	popw	de                                    ; FC7E0B  pop DE
	popw	hl                                    ; FC7E0C  pop HL
	unlk32 xiz                                 ; FC7E0D  unlk XIZ
	ret                                        ; FC7E0F  ret
; --------------------------------------------------------------------------
; sub_FC7E10 -- 0xFC7E10..0xFC7E56 (71 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFAD312 in sub_FAD2D5__FAD2FD, 0xFB652A in sub_FB6500
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFC7E10-0xFC7E56
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC7E10:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC7E10  link XIZ,0x0000
	pushw	hl                                   ; FC7E14  push HL
	push	xix                                   ; FC7E15  push XIX
	ld	ix, (xiz+8)                             ; FC7E16  ld IX,(XIZ+0x08)
	extz	ix                                    ; FC7E19  extz IX
	extz	xix                                   ; FC7E1B  extz XIX
	lda	xbc, (0xE15B:24)                       ; FC7E1D  lda XBC,0x00e15b
	add	xbc, xix                               ; FC7E22  add XBC,XIX
	ld	a, (xiz+10)                             ; FC7E24  ld A,(XIZ+0x0a)
	ld	(xbc), a                                ; FC7E27  ld (XBC),A
	ld	hl, (xiz+12)                            ; FC7E29  ld HL,(XIZ+0x0c)
	extz	hl                                    ; FC7E2C  extz HL
	ld	bc, (xiz+8)                             ; FC7E2E  ld BC,(XIZ+0x08)
	extz	bc                                    ; FC7E31  extz BC
	mul	bc, 0x12C                              ; FC7E33  mul BC,0x012c
	add	bc, 18                                 ; FC7E37  add BC,0x0012
	extz	xbc                                   ; FC7E3B  extz XBC
	ld	a, (xbc+0x1523)                         ; FC7E3D  ld A,(XBC+0x1523)
	extz	wa                                    ; FC7E42  extz WA
	mul	xwa, xhl                               ; FC7E44  mul XWA,HL
	sra	wa, 3                                  ; FC7E46  sra 0x03,WA
	lda	xbc, (0xE17C:24)                       ; FC7E49  lda XBC,0x00e17c
	add	xbc, xix                               ; FC7E4E  add XBC,XIX
	ld	(xbc), a                                ; FC7E50  ld (XBC),A
	pop	xix                                    ; FC7E52  pop XIX
	popw	hl                                    ; FC7E53  pop HL
	unlk32 xiz                                 ; FC7E54  unlk XIZ
	ret                                        ; FC7E56  ret
; --------------------------------------------------------------------------
; Dev10C_ReadChanReg_0100 -- 0xFC7E57..0xFC7E78 (34 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFC7EB8
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFC7E57-0xFC7E78
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; --------------------------------------------------------------------------
; ★ NAMED (round 7 finish pass).  ★ A DEDICATED READ ACCESSOR for register
;          (chan + 0x0100) of the 0x0010C000 device -- the SECOND read site in the
;          whole image, and the first one that does nothing else.
; Inputs:  (XIZ+0x08) = chan, zero-extended at 0xFC7E60.
; Outputs: WA = the 16 bits the device returns.  No write anywhere except the select.
; Evidence: `add HL,0x0100` at 0xFC7E64 forms the register selector;
;          `ld XIX,0x0010C000` at 0xFC7E68 is the port window; `ld (XIX),HL` at
;          0xFC7E6D selects; `ld BC,(XIX+0x04)` at 0xFC7E6F READS, and `ld WA,BC` at
;          0xFC7E72 returns it.  That is the {+0x00 select, +0x02 write, +0x04 read}
;          shape the 0xFACE67 bank's block comment derives from 0xFA68FC, confirmed
;          here by an independent site in another module -- see the correction in
;          that block comment.
; Called from: 0xFC7EBB, in sub_FC7E79.
; Unknown:  what register 0x0100 + chan HOLDS.  Nothing here reads the value's
;          meaning; the name says which register and which direction, both operands.
Dev10C_ReadChanReg_0100:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC7E57  link XIZ,0x0000
	pushw	hl                                   ; FC7E5B  push HL
	push	xix                                   ; FC7E5C  push XIX
	ld	bc, (xiz+8)                             ; FC7E5D  ld BC,(XIZ+0x08)
	extz	bc                                    ; FC7E60  extz BC
	ld	hl, bc                                  ; FC7E62  ld HL,BC
	add	hl, 0x100                              ; FC7E64  add HL,0x0100
	ld	xix, 0x10C000                           ; FC7E68  ld XIX,0x0010c000
	ld	(xix), hl                               ; FC7E6D  ld (XIX),HL
	ld	bc, (xix+4)                             ; FC7E6F  ld BC,(XIX+0x04)
	ld	wa, bc                                  ; FC7E72  ld WA,BC
	pop	xix                                    ; FC7E74  pop XIX
	popw	hl                                    ; FC7E75  pop HL
	unlk32 xiz                                 ; FC7E76  unlk XIZ
	ret                                        ; FC7E78  ret
; --------------------------------------------------------------------------
; sub_FC7E79 -- 0xFC7E79..0xFC7F02 (138 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFADD50 in sub_FADD29__FADD3B
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFC7E57 = Dev10C_ReadChanReg_0100
; Evidence: the listing below is the byte-identical round-trip of 0xFC7E79-0xFC7F02
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC7E79:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC7E79  link XIZ,0x0000
	pushw	hl                                   ; FC7E7D  push HL
	push	xde                                   ; FC7E7E  push XDE
	push	xix                                   ; FC7E7F  push XIX
	ld	de, (xiz+8)                             ; FC7E80  ld DE,(XIZ+0x08)
	extz	xde                                   ; FC7E83  extz XDE
	ld	c, (xde+4)                              ; FC7E85  ld C,(XDE+0x04)
	mul	c, 4                                   ; FC7E88  mul C,0x04
	extz	xbc                                   ; FC7E8B  extz XBC
	ld	xix, xbc                                ; FC7E8D  ld XIX,XBC
	ld	a, (xde+3)                              ; FC7E8F  ld A,(XDE+0x03)
	extz	wa                                    ; FC7E92  extz WA
	extz	xwa                                   ; FC7E94  extz XWA
	add	xbc, xwa                               ; FC7E96  add XBC,XWA
	add	xbc, 0xE0D7                            ; FC7E98  add XBC,0x0000e0d7
	ld	h, (xbc)                                ; FC7E9E  ld H,(XBC)
	cps	h, 1                                   ; FC7EA0  cp H,1
	jr z, sub_FC7E79__FC7EEC                   ; FC7EA2  jr Z,0xfc7eec
	cps	h, 2                                   ; FC7EA4  cp H,2
	jr nz, sub_FC7E79__FC7EEC                  ; FC7EA6  jr NZ,0xfc7eec
	extz	xde                                   ; FC7EA8  extz XDE
	ld	bc, (xde+1)                             ; FC7EAA  ld BC,(XDE+0x01)
	and	bc, 0x200                              ; FC7EAD  and BC,0x0200
	jr nz, sub_FC7E79__FC7EFD                  ; FC7EB1  jr NZ,0xfc7efd
	extz	xde                                   ; FC7EB3  extz XDE
	ld	c, (xde)                                ; FC7EB5  ld C,(XDE)
	pushw	bc                                   ; FC7EB7  push BC
	calr (0xFC7E57 - 0xFC7EBB)                 ; FC7EB8  calr 0xfc7e57
	popw	bc                                    ; FC7EBB  pop BC
	cp	wa, 0x8000                              ; FC7EBC  cp WA,0x8000
	jr c, sub_FC7E79__FC7ECB                   ; FC7EC0  jr C,0xfc7ecb
	extz	xde                                   ; FC7EC2  extz XDE
	extpfx5 0x9A, 0x01, 0x3E, 0x00, 0x02       ; FC7EC4  or (XDE+0x01),0x0200
	jr sub_FC7E79__FC7EFD                      ; FC7EC9  jr T,0xfc7efd
sub_FC7E79__FC7ECB:
	extz	xde                                   ; FC7ECB  extz XDE
	ld	c, (xde+4)                              ; FC7ECD  ld C,(XDE+0x04)
	extz	bc                                    ; FC7ED0  extz BC
	extz	xbc                                   ; FC7ED2  extz XBC
	add	xbc, 0xE15B                            ; FC7ED4  add XBC,0x0000e15b
	ld	h, (xbc)                                ; FC7EDA  ld H,(XBC)
	ld	a, (xde)                                ; FC7EDC  ld A,(XDE)
	extz	wa                                    ; FC7EDE  extz WA
	extz	xwa                                   ; FC7EE0  extz XWA
	add	xwa, 0xE19D                            ; FC7EE2  add XWA,0x0000e19d
	ld	(xwa), h                                ; FC7EE8  ld (XWA),H
	jr sub_FC7E79__FC7EFD                      ; FC7EEA  jr T,0xfc7efd
sub_FC7E79__FC7EEC:
	extz	xde                                   ; FC7EEC  extz XDE
	ld	c, (xde)                                ; FC7EEE  ld C,(XDE)
	extz	bc                                    ; FC7EF0  extz BC
	extz	xbc                                   ; FC7EF2  extz XBC
	add	xbc, 0xE19D                            ; FC7EF4  add XBC,0x0000e19d
	ld	(xbc), 0                                ; FC7EFA  ld (XBC),0x00
sub_FC7E79__FC7EFD:
	pop	xix                                    ; FC7EFD  pop XIX
	pop	xde                                    ; FC7EFE  pop XDE
	popw	hl                                    ; FC7EFF  pop HL
	unlk32 xiz                                 ; FC7F00  unlk XIZ
	ret                                        ; FC7F02  ret
; --------------------------------------------------------------------------
; sub_FC7F03 -- 0xFC7F03..0xFC7F79 (119 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFB0AFD in VoiceRegs_Stage_A, 0xFB1EEB in VoiceRegs_Stage_B
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Voice record: touches voice_record[+0x00(r), +0x01(rw), +0x03(r), +0x04(r)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFC7F03-0xFC7F79
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC7F03:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC7F03  link XIZ,0x0000
	pushw	hl                                   ; FC7F07  push HL
	push	xde                                   ; FC7F08  push XDE
	push	xix                                   ; FC7F09  push XIX
	ld	de, (xiz+8)                             ; FC7F0A  ld DE,(XIZ+0x08)
	extz	xde                                   ; FC7F0D  extz XDE
	ld	c, (xde+4)                              ; FC7F0F  ld C,(XDE+0x04)
	mul	c, 4                                   ; FC7F12  mul C,0x04
	extz	xbc                                   ; FC7F15  extz XBC
	ld	xix, xbc                                ; FC7F17  ld XIX,XBC
	ld	a, (xde+3)                              ; FC7F19  ld A,(XDE+0x03)
	extz	wa                                    ; FC7F1C  extz WA
	extz	xwa                                   ; FC7F1E  extz XWA
	add	xbc, xwa                               ; FC7F20  add XBC,XWA
	add	xbc, 0xE0D7                            ; FC7F22  add XBC,0x0000e0d7
	ld	h, (xbc)                                ; FC7F28  ld H,(XBC)
	cps	h, 1                                   ; FC7F2A  cp H,1
	jr nz, sub_FC7F03__FC7F37                  ; FC7F2C  jr NZ,0xfc7f37
	extz	xde                                   ; FC7F2E  extz XDE
	extpfx5 0x9A, 0x01, 0x3E, 0x00, 0x02       ; FC7F30  or (XDE+0x01),0x0200
	jr sub_FC7F03__FC7F63                      ; FC7F35  jr T,0xfc7f63
sub_FC7F03__FC7F37:
	extz	xde                                   ; FC7F37  extz XDE
	extpfx5 0x9A, 0x01, 0x3C, 0xFF, 0xFD       ; FC7F39  and (XDE+0x01),0xfdff
	cps	h, 2                                   ; FC7F3E  cp H,2
	jr nz, sub_FC7F03__FC7F63                  ; FC7F40  jr NZ,0xfc7f63
	extz	xde                                   ; FC7F42  extz XDE
	ld	c, (xde+4)                              ; FC7F44  ld C,(XDE+0x04)
	extz	bc                                    ; FC7F47  extz BC
	extz	xbc                                   ; FC7F49  extz XBC
	add	xbc, 0xE15B                            ; FC7F4B  add XBC,0x0000e15b
	ld	h, (xbc)                                ; FC7F51  ld H,(XBC)
	ld	a, (xde)                                ; FC7F53  ld A,(XDE)
	extz	wa                                    ; FC7F55  extz WA
	extz	xwa                                   ; FC7F57  extz XWA
	add	xwa, 0xE19D                            ; FC7F59  add XWA,0x0000e19d
	ld	(xwa), h                                ; FC7F5F  ld (XWA),H
	jr sub_FC7F03__FC7F74                      ; FC7F61  jr T,0xfc7f74
sub_FC7F03__FC7F63:
	extz	xde                                   ; FC7F63  extz XDE
	ld	c, (xde)                                ; FC7F65  ld C,(XDE)
	extz	bc                                    ; FC7F67  extz BC
	extz	xbc                                   ; FC7F69  extz XBC
	add	xbc, 0xE19D                            ; FC7F6B  add XBC,0x0000e19d
	ld	(xbc), 0                                ; FC7F71  ld (XBC),0x00
sub_FC7F03__FC7F74:
	pop	xix                                    ; FC7F74  pop XIX
	pop	xde                                    ; FC7F75  pop XDE
	popw	hl                                    ; FC7F76  pop HL
	unlk32 xiz                                 ; FC7F77  unlk XIZ
	ret                                        ; FC7F79  ret
; --------------------------------------------------------------------------
; sub_FC7F7A -- 0xFC7F7A..0xFC7FC9 (80 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFB281B in VoiceRegs_Stage_C, 0xFB2EE4 in VoiceRegs_Stage_D
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Voice record: touches voice_record[+0x00(r), +0x01(rw), +0x03(r), +0x04(r)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFC7F7A-0xFC7FC9
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC7F7A:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC7F7A  link XIZ,0x0000
	push	xhl                                   ; FC7F7E  push XHL
	push	xix                                   ; FC7F7F  push XIX
	ld	hl, (xiz+8)                             ; FC7F80  ld HL,(XIZ+0x08)
	extz	xhl                                   ; FC7F83  extz XHL
	ld	c, (xhl+4)                              ; FC7F85  ld C,(XHL+0x04)
	mul	c, 4                                   ; FC7F88  mul C,0x04
	extz	xbc                                   ; FC7F8B  extz XBC
	ld	xix, xbc                                ; FC7F8D  ld XIX,XBC
	ld	a, (xhl+3)                              ; FC7F8F  ld A,(XHL+0x03)
	extz	wa                                    ; FC7F92  extz WA
	extz	xwa                                   ; FC7F94  extz XWA
	add	xbc, xwa                               ; FC7F96  add XBC,XWA
	add	xbc, 0xE0D7                            ; FC7F98  add XBC,0x0000e0d7
	ld	a, (xbc)                                ; FC7F9E  ld A,(XBC)
	cps	a, 1                                   ; FC7FA0  cp A,1
	jr nz, sub_FC7F7A__FC7FAD                  ; FC7FA2  jr NZ,0xfc7fad
	extz	xhl                                   ; FC7FA4  extz XHL
	extpfx5 0x9B, 0x01, 0x3E, 0x00, 0x02       ; FC7FA6  or (XHL+0x01),0x0200
	jr sub_FC7F7A__FC7FB4                      ; FC7FAB  jr T,0xfc7fb4
sub_FC7F7A__FC7FAD:
	extz	xhl                                   ; FC7FAD  extz XHL
	extpfx5 0x9B, 0x01, 0x3C, 0xFF, 0xFD       ; FC7FAF  and (XHL+0x01),0xfdff
sub_FC7F7A__FC7FB4:
	extz	xhl                                   ; FC7FB4  extz XHL
	ld	c, (xhl)                                ; FC7FB6  ld C,(XHL)
	extz	bc                                    ; FC7FB8  extz BC
	extz	xbc                                   ; FC7FBA  extz XBC
	add	xbc, 0xE19D                            ; FC7FBC  add XBC,0x0000e19d
	ld	(xbc), 0                                ; FC7FC2  ld (XBC),0x00
	pop	xix                                    ; FC7FC5  pop XIX
	pop	xhl                                    ; FC7FC6  pop XHL
	unlk32 xiz                                 ; FC7FC7  unlk XIZ
	ret                                        ; FC7FC9  ret
; --------------------------------------------------------------------------
; sub_FC7FCA -- 0xFC7FCA..0xFC810B (322 bytes)
;
; Called from: 3 site(s) outside this module:
;          0xFA844F in Voice_StageRegs_0900_0940_0980_AB, 0xFA9760 in Voice_StageRegs_CD
;          0xFADD69 in sub_FADD29__FADD3B
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFC7FCA-0xFC810B
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC7FCA:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FC7FCA  link XIZ,0xfffc
	pushw	hl                                   ; FC7FCE  push HL
	pushw	de                                   ; FC7FCF  push DE
	push	xix                                   ; FC7FD0  push XIX
	ld	ix, (xiz+8)                             ; FC7FD1  ld IX,(XIZ+0x08)
	extz	xix                                   ; FC7FD4  extz XIX
	ld	bc, (xix+37)                            ; FC7FD6  ld BC,(XIX+0x25)
	extz	xbc                                   ; FC7FD9  extz XBC
	ld	hl, (xbc+24)                            ; FC7FDB  ld HL,(XBC+0x18)
	ld	bc, hl                                  ; FC7FDE  ld BC,HL
	and	bc, 16                                 ; FC7FE0  and BC,0x0010
	jrl z, sub_FC7FCA__FC805E                  ; FC7FE4  jrl Z,0xfc805e
	ld	bc, hl                                  ; FC7FE7  ld BC,HL
	and	bc, 32                                 ; FC7FE9  and BC,0x0020
	jr z, sub_FC7FCA__FC802E                   ; FC7FED  jr Z,0xfc802e
	extz	xix                                   ; FC7FEF  extz XIX
	ld	c, (xix)                                ; FC7FF1  ld C,(XIX)
	extz	bc                                    ; FC7FF3  extz BC
	extz	xbc                                   ; FC7FF5  extz XBC
	add	xbc, 0xE19D                            ; FC7FF7  add XBC,0x0000e19d
	ld	a, (xbc)                                ; FC7FFD  ld A,(XBC)
	exts	wa                                    ; FC7FFF  exts WA
	ld	hl, wa                                  ; FC8001  ld HL,WA
	ld	b, (xix+4)                              ; FC8003  ld B,(XIX+0x04)
	extpfx3 0xC7, 0xF4, 0x9A                   ; FC8006  ld IYL,B
	extz	iy                                    ; FC8009  extz IY
	extz	xiy                                   ; FC800B  extz XIY
	add	xiy, 0xE15B                            ; FC800D  add XIY,0x0000e15b
	ld	c, (xiy)                                ; FC8013  ld C,(XIY)
	exts	bc                                    ; FC8015  exts BC
	ld	de, bc                                  ; FC8017  ld DE,BC
	sub	bc, wa                                 ; FC8019  sub BC,WA
	ld	de, bc                                  ; FC801B  ld DE,BC
	cp	bc, 0xFF81                              ; FC801D  cp BC,0xff81
	jr ge, sub_FC7FCA__FC8026                  ; FC8021  jr GE,0xfc8026
	ldw	de, 0xFF81                             ; FC8023  ld DE,0xff81
sub_FC7FCA__FC8026:
	ld	bc, de                                  ; FC8026  ld BC,DE
	neg	bc                                     ; FC8028  neg BC
	ld	hl, bc                                  ; FC802A  ld HL,BC
	jr sub_FC7FCA__FC8061                      ; FC802C  jr T,0xfc8061
sub_FC7FCA__FC802E:
	extz	xix                                   ; FC802E  extz XIX
	ld	c, (xix)                                ; FC8030  ld C,(XIX)
	extz	bc                                    ; FC8032  extz BC
	extz	xbc                                   ; FC8034  extz XBC
	add	xbc, 0xE19D                            ; FC8036  add XBC,0x0000e19d
	ld	a, (xbc)                                ; FC803C  ld A,(XBC)
	exts	wa                                    ; FC803E  exts WA
	ld	de, wa                                  ; FC8040  ld DE,WA
	ld	b, (xix+4)                              ; FC8042  ld B,(XIX+0x04)
	extpfx3 0xC7, 0xF4, 0x9A                   ; FC8045  ld IYL,B
	extz	iy                                    ; FC8048  extz IY
	extz	xiy                                   ; FC804A  extz XIY
	add	xiy, 0xE15B                            ; FC804C  add XIY,0x0000e15b
	ld	c, (xiy)                                ; FC8052  ld C,(XIY)
	exts	bc                                    ; FC8054  exts BC
	ld	hl, bc                                  ; FC8056  ld HL,BC
	sub	bc, wa                                 ; FC8058  sub BC,WA
	ld	hl, bc                                  ; FC805A  ld HL,BC
	jr sub_FC7FCA__FC8061                      ; FC805C  jr T,0xfc8061
sub_FC7FCA__FC805E:
	ldw	hl, 0                                  ; FC805E  ld HL,0x0000
sub_FC7FCA__FC8061:
	extz	xix                                   ; FC8061  extz XIX
	ld	d, (xix+4)                              ; FC8063  ld D,(XIX+0x04)
	ldb	c, 4                                   ; FC8066  ld C,0x04
	mul8rr	c, d                                ; FC8068  mul BC,D
	extz	xbc                                   ; FC806A  extz XBC
	ld	(xiz-4), xbc                            ; FC806C  ld (XIZ+0xfc),XBC
	ld	a, (xix+3)                              ; FC806F  ld A,(XIX+0x03)
	extz	wa                                    ; FC8072  extz WA
	extz	xwa                                   ; FC8074  extz XWA
	add	xbc, xwa                               ; FC8076  add XBC,XWA
	add	xbc, 0xE0D7                            ; FC8078  add XBC,0x0000e0d7
	ld	a, (xbc)                                ; FC807E  ld A,(XBC)
	cps	a, 2                                   ; FC8080  cp A,2
	jr nz, sub_FC7FCA__FC80A8                  ; FC8082  jr NZ,0xfc80a8
	ld	bc, hl                                  ; FC8084  ld BC,HL
	sra	bc, 1                                  ; FC8086  sra 0x01,BC
	ld	hl, bc                                  ; FC8089  ld HL,BC
	ld	a, d                                    ; FC808B  ld A,D
	extz	wa                                    ; FC808D  extz WA
	extz	xwa                                   ; FC808F  extz XWA
	add	xwa, 0xE17C                            ; FC8091  add XWA,0x0000e17c
	ld	w, (xwa)                                ; FC8097  ld W,(XWA)
	ld	a, w                                    ; FC8099  ld A,W
	extz	wa                                    ; FC809B  extz WA
	sll	wa, 9                                  ; FC809D  sll 0x09,WA
	ld	xiy, (xiz+10)                           ; FC80A0  ld XIY,(XIZ+0x0a)
	ld	(xiy+22), wa                            ; FC80A3  ld (XIY+0x16),WA
	jr sub_FC7FCA__FC80C1                      ; FC80A6  jr T,0xfc80c1
sub_FC7FCA__FC80A8:
	ld	c, d                                    ; FC80A8  ld C,D
	extz	bc                                    ; FC80AA  extz BC
	extz	xbc                                   ; FC80AC  extz XBC
	add	xbc, 0xE17C                            ; FC80AE  add XBC,0x0000e17c
	ld	a, (xbc)                                ; FC80B4  ld A,(XBC)
	extz	wa                                    ; FC80B6  extz WA
	sll	wa, 8                                  ; FC80B8  sll 0x08,WA
	ld	xbc, (xiz+10)                           ; FC80BB  ld XBC,(XIZ+0x0a)
	ld	(xbc+22), wa                            ; FC80BE  ld (XBC+0x16),WA
sub_FC7FCA__FC80C1:
	extz	xix                                   ; FC80C1  extz XIX
	ld	c, (xix)                                ; FC80C3  ld C,(XIX)
	extz	bc                                    ; FC80C5  extz BC
	extz	xbc                                   ; FC80C7  extz XBC
	add	xbc, 0xE1DD                            ; FC80C9  add XBC,0x0000e1dd
	ld	a, (xbc)                                ; FC80CF  ld A,(XBC)
	extz	wa                                    ; FC80D1  extz WA
	ld	xbc, (xiz+10)                           ; FC80D3  ld XBC,(XIZ+0x0a)
	or	(xbc+22), wa                            ; FC80D6  or (XBC+0x16),WA
	ld	bc, hl                                  ; FC80D9  ld BC,HL
	and	bc, 0xFF                               ; FC80DB  and BC,0x00ff
	or	bc, 0xE000                              ; FC80DF  or BC,0xe000
	ld	hl, bc                                  ; FC80E3  ld HL,BC
	ld	xwa, (xiz+10)                           ; FC80E5  ld XWA,(XIZ+0x0a)
	ld	(xwa+32), bc                            ; FC80E8  ld (XWA+0x20),BC
	ld	xbc, (xiz+10)                           ; FC80EB  ld XBC,(XIZ+0x0a)
	ld	(xbc+34), hl                            ; FC80EE  ld (XBC+0x22),HL
	ld	xbc, (xiz+10)                           ; FC80F1  ld XBC,(XIZ+0x0a)
	ld	(xbc+36), hl                            ; FC80F4  ld (XBC+0x24),HL
	ld	c, (xix)                                ; FC80F7  ld C,(XIX)
	mul	c, 2                                   ; FC80F9  mul C,0x02
	extz	xbc                                   ; FC80FC  extz XBC
	add	xbc, 0xE21D                            ; FC80FE  add XBC,0x0000e21d
	ld	(xbc), hl                               ; FC8104  ld (XBC),HL
	pop	xix                                    ; FC8106  pop XIX
	popw	de                                    ; FC8107  pop DE
	popw	hl                                    ; FC8108  pop HL
	unlk32 xiz                                 ; FC8109  unlk XIZ
	ret                                        ; FC810B  ret
; --------------------------------------------------------------------------
; sub_FC810C -- 0xFC810C..0xFC8128 (29 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFA960D in Voice_StageRegs_0500_08C0_AB, 0xFA9746 in Voice_StageRegs_CD
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFC810C-0xFC8128
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC810C:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC810C  link XIZ,0x0000
	ld	bc, (xiz+8)                             ; FC8110  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FC8113  extz XBC
	ld	a, (xbc)                                ; FC8115  ld A,(XBC)
	extz	wa                                    ; FC8117  extz WA
	extz	xwa                                   ; FC8119  extz XWA
	add	xwa, 0xE1DD                            ; FC811B  add XWA,0x0000e1dd
	ld	c, (xiz+10)                             ; FC8121  ld C,(XIZ+0x0a)
	ld	(xwa), c                                ; FC8124  ld (XWA),C
	unlk32 xiz                                 ; FC8126  unlk XIZ
	ret                                        ; FC8128  ret
; --------------------------------------------------------------------------
; sub_FC8129 -- 0xFC8129..0xFC8163 (59 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFABAFF in Dev10C_StageRegs_0900_0940, 0xFABD14 in sub_FABCF9
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFC8129-0xFC8163
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC8129:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC8129  link XIZ,0x0000
	ld	bc, (xiz+8)                             ; FC812D  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FC8130  extz XBC
	ld	a, (xbc)                                ; FC8132  ld A,(XBC)
	mul	a, 2                                   ; FC8134  mul A,0x02
	extz	xwa                                   ; FC8137  extz XWA
	add	xwa, 0xE21D                            ; FC8139  add XWA,0x0000e21d
	ld	wa, (xwa)                               ; FC813F  ld WA,(XWA)
	ld	xiy, (xiz+10)                           ; FC8141  ld XIY,(XIZ+0x0a)
	ld	(xiy+48), wa                            ; FC8144  ld (XIY+0x30),WA
	ld	bc, (xiz+8)                             ; FC8147  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FC814A  extz XBC
	ld	a, (xbc)                                ; FC814C  ld A,(XBC)
	mul	a, 2                                   ; FC814E  mul A,0x02
	extz	xwa                                   ; FC8151  extz XWA
	add	xwa, 0xE21D                            ; FC8153  add XWA,0x0000e21d
	ld	wa, (xwa)                               ; FC8159  ld WA,(XWA)
	ld	xiy, (xiz+10)                           ; FC815B  ld XIY,(XIZ+0x0a)
	ld	(xiy+50), wa                            ; FC815E  ld (XIY+0x32),WA
	unlk32 xiz                                 ; FC8161  unlk XIZ
	ret                                        ; FC8163  ret
; --------------------------------------------------------------------------
; PartRec_TallyScaledField_80_40 -- 0xFC8164..0xFC81B7 (84 bytes)
;
; Called from: no site outside this module.
;          14 site(s) inside this module:
;          0xFC825F 0xFC8287 0xFC82A0 0xFC82B9 0xFC82D2 0xFC8306
;          0xFC831F 0xFC8444 0xFC846D 0xFC8485 0xFC849D 0xFC84B5
;          0xFC84EB 0xFC8503
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0E)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFC8164-0xFC81B7
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ WHAT IT DOES: a two-threshold tally of one scaled record byte.
;     0xFC8171  ld A,(XBC+0x01) / and A,0x3f / cp A,1 / jr NZ   runs only when the record's
;                                                               byte +1, masked to 6 bits, is 1
;     0xFC817B  ld A,(XBC+0x02)                                 the value
;     0xFC8187  mul IY,0x012c / add IY,0x0012                   part stride 0x12C, field +0x12
;     0xFC8191  ld C,(XIY+0x1523)                               of the part record at RAM 0x1523
;     0xFC8198  mul XWA,BC / srl 0x03,WA                        value * field, then >> 3
;     0xFC81A1  cp WA,0x007f / jr UGT / inc 1,(XIX)             tally A if the result <= 0x7F
;     0xFC81A9  cp HL,0x003f / jr UGT / inc 1,(XIX+0x01)        tally B if the result <= 0x3F
;   The two counters are ADJACENT BYTES of the caller's block, so what a caller learns is
;   how many records fall under each of two thresholds.
; ★ `0x1523 + part * 0x12C` is the same part-record geometry round 2 established for
;   PartRec_ResetSlotValues_ByTag (0xFAF340) -- two routines in two modules, one structure.
; Evidence: `--claims C9` finds all five constants -- 0x012C, 0x1523, 0x0012, 0x007F and
;          0x003F -- in this routine's 84 ROM bytes.  The comparisons are UNSIGNED (`jr UGT`)
;          and the shift is LOGICAL (`srl`, not `sra`); both are opcodes, not readings.
; Unknown:  ⚠ what tag value 1 selects, and what the scaled quantity is.  The first
;          `ld HL,WA` at 0xFC819A is overwritten at 0xFC819F and is dead.
; --------------------------------------------------------------------------
PartRec_TallyScaledField_80_40:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC8164  link XIZ,0x0000
	pushw	hl                                   ; FC8168  push HL
	pushw	de                                   ; FC8169  push DE
	push	xix                                   ; FC816A  push XIX
	ld	xix, (xiz+14)                           ; FC816B  ld XIX,(XIZ+0x0e)
	ld	xbc, (xiz+10)                           ; FC816E  ld XBC,(XIZ+0x0a)
	ld	a, (xbc+1)                              ; FC8171  ld A,(XBC+0x01)
	and	a, 63                                  ; FC8174  and A,0x3f
	cps	a, 1                                   ; FC8177  cp A,1
	jr nz, PartRec_TallyScaledField_80_40__FC81B2                  ; FC8179  jr NZ,0xfc81b2
	ld	a, (xbc+2)                              ; FC817B  ld A,(XBC+0x02)
	extz	wa                                    ; FC817E  extz WA
	ld	de, wa                                  ; FC8180  ld DE,WA
	ld	iy, (xiz+8)                             ; FC8182  ld IY,(XIZ+0x08)
	extz	iy                                    ; FC8185  extz IY
	mul	iy, 0x12C                              ; FC8187  mul IY,0x012c
	add	iy, 18                                 ; FC818B  add IY,0x0012
	extz	xiy                                   ; FC818F  extz XIY
	ld	c, (xiy+0x1523)                         ; FC8191  ld C,(XIY+0x1523)
	extz	bc                                    ; FC8196  extz BC
	mul	xwa, xbc                               ; FC8198  mul XWA,BC
	ld	hl, wa                                  ; FC819A  ld HL,WA
	srl	wa, 3                                  ; FC819C  srl 0x03,WA
	ld	hl, wa                                  ; FC819F  ld HL,WA
	cp	wa, 0x7F                                ; FC81A1  cp WA,0x007f
	jr ugt, PartRec_TallyScaledField_80_40__FC81A9                 ; FC81A5  jr UGT,0xfc81a9
	incm8	1, (xix)                             ; FC81A7  inc 1,(XIX)
PartRec_TallyScaledField_80_40__FC81A9:
	cp	hl, 63                                  ; FC81A9  cp HL,0x003f
	jr ugt, PartRec_TallyScaledField_80_40__FC81B2                 ; FC81AD  jr UGT,0xfc81b2
	incm8	1, (xix+1)                           ; FC81AF  inc 1,(XIX+0x01)
PartRec_TallyScaledField_80_40__FC81B2:
	pop	xix                                    ; FC81B2  pop XIX
	popw	de                                    ; FC81B3  pop DE
	popw	hl                                    ; FC81B4  pop HL
	unlk32 xiz                                 ; FC81B5  unlk XIZ
	ret                                        ; FC81B7  ret
; --------------------------------------------------------------------------
; sub_FC81B8 -- 0xFC81B8..0xFC81F7 (64 bytes)
;
; Called from: no site outside this module.
;          2 site(s) inside this module:
;          0xFC8382 0xFC83DA
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFC81B8-0xFC81F7
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC81B8:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC81B8  link XIZ,0x0000
	push	xix                                   ; FC81BC  push XIX
	ld	xix, (xiz+8)                            ; FC81BD  ld XIX,(XIZ+0x08)
	ld	c, (xix+7)                              ; FC81C0  ld C,(XIX+0x07)
	cps	c, 0                                   ; FC81C3  cp C,0
	jr z, sub_FC81B8__FC81EE                   ; FC81C5  jr Z,0xfc81ee
	ld	c, (xix+14)                             ; FC81C7  ld C,(XIX+0x0e)
	cps	c, 0                                   ; FC81CA  cp C,0
	jr nz, sub_FC81B8__FC81F2                  ; FC81CC  jr NZ,0xfc81f2
	ld	c, (xix+16)                             ; FC81CE  ld C,(XIX+0x10)
	cps	c, 0                                   ; FC81D1  cp C,0
	jr nz, sub_FC81B8__FC81F2                  ; FC81D3  jr NZ,0xfc81f2
	ld	c, (xix+8)                              ; FC81D5  ld C,(XIX+0x08)
	cps	c, 0                                   ; FC81D8  cp C,0
	jr nz, sub_FC81B8__FC81EA                  ; FC81DA  jr NZ,0xfc81ea
	ld	c, (xix+10)                             ; FC81DC  ld C,(XIX+0x0a)
	cps	c, 0                                   ; FC81DF  cp C,0
	jr nz, sub_FC81B8__FC81EA                  ; FC81E1  jr NZ,0xfc81ea
	ld	c, (xix+12)                             ; FC81E3  ld C,(XIX+0x0c)
	cps	c, 0                                   ; FC81E6  cp C,0
	jr z, sub_FC81B8__FC81EE                   ; FC81E8  jr Z,0xfc81ee
sub_FC81B8__FC81EA:
	ldb	a, 1                                   ; FC81EA  ld A,0x01
	jr sub_FC81B8__FC81F4                      ; FC81EC  jr T,0xfc81f4
sub_FC81B8__FC81EE:
	sub	a, a                                   ; FC81EE  sub A,A
	jr sub_FC81B8__FC81F4                      ; FC81F0  jr T,0xfc81f4
sub_FC81B8__FC81F2:
	ldb	a, 2                                   ; FC81F2  ld A,0x02
sub_FC81B8__FC81F4:
	pop	xix                                    ; FC81F4  pop XIX
	unlk32 xiz                                 ; FC81F5  unlk XIZ
	ret                                        ; FC81F7  ret
; --------------------------------------------------------------------------
; sub_FC81F8 -- 0xFC81F8..0xFC856B (884 bytes)
;
; Called from: 6 site(s) outside this module:
;          0xFAD8E9 in MidiCtrl_Int80, 0xFB68D1 in sub_FB6681__FB6891
;          0xFB6B4E in sub_FB68DD__FB6B0F, 0xFB6CE2 in sub_FB6BA8__FB6CD1
;          0xFBC4A4 in sub_FBC39D__FBC49F, 0xFC2647 in sub_FC2600__FC262D
; Inputs:  frame `link XIZ,-26`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFC8164 = PartRec_TallyScaledField_80_40, 0xFC81B8 = sub_FC81B8
; Evidence: the listing below is the byte-identical round-trip of 0xFC81F8-0xFC856B
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FC81F8:
	link32 0xEE, 0x0C, 0xE6, 0xFF              ; FC81F8  link XIZ,0xffe6
	pushw	hl                                   ; FC81FC  push HL
	pushw	de                                   ; FC81FD  push DE
	push	xix                                   ; FC81FE  push XIX
	ld	(xiz-11), 0                             ; FC81FF  ld (XIZ+0xf5),0x00
	ld	(xiz-12), 0                             ; FC8203  ld (XIZ+0xf4),0x00
	ld	bc, (xiz+8)                             ; FC8207  ld BC,(XIZ+0x08)
	extz	bc                                    ; FC820A  extz BC
	mul	bc, 0x12C                              ; FC820C  mul BC,0x012c
	extz	xbc                                   ; FC8210  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FC8212  ld XWA,(XBC+0x1523)
	ld	(xiz-20), xwa                           ; FC8217  ld (XIZ+0xec),XWA
	ld	c, (xwa+16)                             ; FC821A  ld C,(XWA+0x10)
	and	c, 0xC0                                ; FC821D  and C,0xc0
	extz	bc                                    ; FC8220  extz BC
	cps	bc, 0                                  ; FC8222  cp BC,0
	jr z, sub_FC81F8__FC823C                   ; FC8224  jr Z,0xfc823c
	cp	bc, 64                                  ; FC8226  cp BC,0x0040
	jr z, sub_FC81F8__FC823C                   ; FC822A  jr Z,0xfc823c
	cp	bc, 0x80                                ; FC822C  cp BC,0x0080
	jrl z, sub_FC81F8__FC842F                  ; FC8230  jrl Z,0xfc842f
	cp	bc, 0xC0                                ; FC8233  cp BC,0x00c0
	jr z, sub_FC81F8__FC823C                   ; FC8237  jr Z,0xfc823c
	jrl sub_FC81F8__FC8566                     ; FC8239  jrl T,0xfc8566
sub_FC81F8__FC823C:
	ld	bc, (xiz+8)                             ; FC823C  ld BC,(XIZ+0x08)
	extz	bc                                    ; FC823F  extz BC
	mul	bc, 0x12C                              ; FC8241  mul BC,0x012c
	extz	xbc                                   ; FC8245  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FC8247  ld XWA,(XBC+0x1523)
	ld	(xiz-16), xwa                           ; FC824C  ld (XIZ+0xf0),XWA
	lda	xbc, (xiz-12)                          ; FC824F  lda XBC,XIZ+0xf4
	push	xbc                                   ; FC8252  push XBC
	add	xwa, 20                                ; FC8253  add XWA,0x00000014
	push	xwa                                   ; FC8259  push XWA
	push	0                                     ; FC825A  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FC825C  push (XIZ+0x08)
	calr (0xFC8164 - 0xFC8262)                 ; FC825F  calr 0xfc8164
	ldw	de, 0                                  ; FC8262  ld DE,0x0000
	ldb	h, 2                                   ; FC8265  ld H,0x02
	inc	8, xsp                                 ; FC8267  inc 0,XSP
	inc	2, xsp                                 ; FC8269  inc 2,XSP
sub_FC81F8__FC826B:
	lda	xbc, (xiz-12)                          ; FC826B  lda XBC,XIZ+0xf4
	push	xbc                                   ; FC826E  push XBC
	ld	ix, de                                  ; FC826F  ld IX,DE
	ld	wa, ix                                  ; FC8271  ld WA,IX
	extz	xwa                                   ; FC8273  extz XWA
	ld	(xiz-24), xwa                           ; FC8275  ld (XIZ+0xe8),XWA
	add	xwa, 23                                ; FC8278  add XWA,0x00000017
	extpfx3 0xAE, 0xF0, 0x80                   ; FC827E  add XWA,(XIZ+0xf0)
	push	xwa                                   ; FC8281  push XWA
	push	0                                     ; FC8282  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FC8284  push (XIZ+0x08)
	calr (0xFC8164 - 0xFC828A)                 ; FC8287  calr 0xfc8164
	lda	xbc, (xiz-12)                          ; FC828A  lda XBC,XIZ+0xf4
	push	xbc                                   ; FC828D  push XBC
	ld	xwa, (xiz-24)                           ; FC828E  ld XWA,(XIZ+0xe8)
	add	xwa, 29                                ; FC8291  add XWA,0x0000001d
	extpfx3 0xAE, 0xF0, 0x80                   ; FC8297  add XWA,(XIZ+0xf0)
	push	xwa                                   ; FC829A  push XWA
	push	0                                     ; FC829B  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FC829D  push (XIZ+0x08)
	calr (0xFC8164 - 0xFC82A3)                 ; FC82A0  calr 0xfc8164
	lda	xbc, (xiz-12)                          ; FC82A3  lda XBC,XIZ+0xf4
	push	xbc                                   ; FC82A6  push XBC
	ld	xwa, (xiz-24)                           ; FC82A7  ld XWA,(XIZ+0xe8)
	add	xwa, 37                                ; FC82AA  add XWA,0x00000025
	extpfx3 0xAE, 0xF0, 0x80                   ; FC82B0  add XWA,(XIZ+0xf0)
	push	xwa                                   ; FC82B3  push XWA
	push	0                                     ; FC82B4  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FC82B6  push (XIZ+0x08)
	calr (0xFC8164 - 0xFC82BC)                 ; FC82B9  calr 0xfc8164
	lda	xbc, (xiz-12)                          ; FC82BC  lda XBC,XIZ+0xf4
	push	xbc                                   ; FC82BF  push XBC
	ld	xwa, (xiz-24)                           ; FC82C0  ld XWA,(XIZ+0xe8)
	add	xwa, 43                                ; FC82C3  add XWA,0x0000002b
	extpfx3 0xAE, 0xF0, 0x80                   ; FC82C9  add XWA,(XIZ+0xf0)
	push	xwa                                   ; FC82CC  push XWA
	push	0                                     ; FC82CD  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FC82CF  push (XIZ+0x08)
	calr (0xFC8164 - 0xFC82D5)                 ; FC82D2  calr 0xfc8164
	ld	de, ix                                  ; FC82D5  ld DE,IX
	inc	3, de                                  ; FC82D7  inc 3,DE
	dec	1, h                                   ; FC82D9  dec 1,H
	add	xsp, 40                                ; FC82DB  add XSP,0x00000028
	cps	h, 0                                   ; FC82E1  cp H,0
	jr nz, sub_FC81F8__FC826B                  ; FC82E3  jr NZ,0xfc826b
	ldw	de, 0                                  ; FC82E5  ld DE,0x0000
	ldb	h, 6                                   ; FC82E8  ld H,0x06
sub_FC81F8__FC82EA:
	lda	xbc, (xiz-12)                          ; FC82EA  lda XBC,XIZ+0xf4
	push	xbc                                   ; FC82ED  push XBC
	ld	ix, de                                  ; FC82EE  ld IX,DE
	ld	wa, ix                                  ; FC82F0  ld WA,IX
	extz	xwa                                   ; FC82F2  extz XWA
	ld	(xiz-24), xwa                           ; FC82F4  ld (XIZ+0xe8),XWA
	add	xwa, 49                                ; FC82F7  add XWA,0x00000031
	extpfx3 0xAE, 0xF0, 0x80                   ; FC82FD  add XWA,(XIZ+0xf0)
	push	xwa                                   ; FC8300  push XWA
	push	0                                     ; FC8301  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FC8303  push (XIZ+0x08)
	calr (0xFC8164 - 0xFC8309)                 ; FC8306  calr 0xfc8164
	lda	xbc, (xiz-12)                          ; FC8309  lda XBC,XIZ+0xf4
	push	xbc                                   ; FC830C  push XBC
	ld	xwa, (xiz-24)                           ; FC830D  ld XWA,(XIZ+0xe8)
	add	xwa, 52                                ; FC8310  add XWA,0x00000034
	extpfx3 0xAE, 0xF0, 0x80                   ; FC8316  add XWA,(XIZ+0xf0)
	push	xwa                                   ; FC8319  push XWA
	push	0                                     ; FC831A  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FC831C  push (XIZ+0x08)
	calr (0xFC8164 - 0xFC8322)                 ; FC831F  calr 0xfc8164
	ld	de, ix                                  ; FC8322  ld DE,IX
	inc	6, de                                  ; FC8324  inc 6,DE
	dec	1, h                                   ; FC8326  dec 1,H
	add	xsp, 20                                ; FC8328  add XSP,0x00000014
	cps	h, 0                                   ; FC832E  cp H,0
	jr nz, sub_FC81F8__FC82EA                  ; FC8330  jr NZ,0xfc82ea
	ld	c, (xiz-12)                             ; FC8332  ld C,(XIZ+0xf4)
	cps	c, 0                                   ; FC8335  cp C,0
	jr nz, sub_FC81F8__FC8360                  ; FC8337  jr NZ,0xfc8360
	ldb	h, 0                                   ; FC8339  ld H,0x00
	ldb	c, 4                                   ; FC833B  ld C,0x04
	extpfx3 0x8E, 0x08, 0x43                   ; FC833D  mul BC,(XIZ+0x08)
	extz	xbc                                   ; FC8340  extz XBC
	ld	xix, xbc                                ; FC8342  ld XIX,XBC
sub_FC81F8__FC8344:
	ld	(xiz-24), xix                           ; FC8344  ld (XIZ+0xe8),XIX
	lda	xbc, (0xE0D7:24)                       ; FC8347  lda XBC,0x00e0d7
	extpfx3 0xAE, 0xE8, 0x81                   ; FC834C  add XBC,(XIZ+0xe8)
	ld	(xbc), 0                                ; FC834F  ld (XBC),0x00
	ld	xix, (xiz-24)                           ; FC8352  ld XIX,(XIZ+0xe8)
	inc	1, xix                                 ; FC8355  inc 1,XIX
	inc	1, h                                   ; FC8357  inc 1,H
	cps	h, 4                                   ; FC8359  cp H,4
	jr c, sub_FC81F8__FC8344                   ; FC835B  jr C,0xfc8344
	jrl sub_FC81F8__FC8566                     ; FC835D  jrl T,0xfc8566
sub_FC81F8__FC8360:
	ld	l, (xiz-11)                             ; FC8360  ld L,(XIZ+0xf5)
	ldb	h, 0                                   ; FC8363  ld H,0x00
	cps	l, 0                                   ; FC8365  cp L,0
	jr nz, sub_FC81F8__FC83C1                  ; FC8367  jr NZ,0xfc83c1
	ldb	c, 4                                   ; FC8369  ld C,0x04
	extpfx3 0x8E, 0x08, 0x43                   ; FC836B  mul BC,(XIZ+0x08)
	ld	(xiz-2), bc                             ; FC836E  ld (XIZ+0xfe),BC
	ldw	de, 0                                  ; FC8371  ld DE,0x0000
sub_FC81F8__FC8374:
	ld	bc, de                                  ; FC8374  ld BC,DE
	extz	xbc                                   ; FC8376  extz XBC
	add	xbc, 0xD9                              ; FC8378  add XBC,0x000000d9
	extpfx3 0xAE, 0xF0, 0x81                   ; FC837E  add XBC,(XIZ+0xf0)
	push	xbc                                   ; FC8381  push XBC
	calr (0xFC81B8 - 0xFC8385)                 ; FC8382  calr 0xfc81b8
	ld	l, a                                    ; FC8385  ld L,A
	ld	bc, (xiz-2)                             ; FC8387  ld BC,(XIZ+0xfe)
	extz	xbc                                   ; FC838A  extz XBC
	ld	(xiz-24), xbc                           ; FC838C  ld (XIZ+0xe8),XBC
	ld	a, h                                    ; FC838F  ld A,H
	extz	wa                                    ; FC8391  extz WA
	extz	xwa                                   ; FC8393  extz XWA
	ld	xix, xbc                                ; FC8395  ld XIX,XBC
	add	xix, xwa                               ; FC8397  add XIX,XWA
	pop	xiy                                    ; FC8399  pop XIY
	cps	l, 0                                   ; FC839A  cp L,0
	jr nz, sub_FC81F8__FC83AA                  ; FC839C  jr NZ,0xfc83aa
	lda	xbc, (0xE0D7:24)                       ; FC839E  lda XBC,0x00e0d7
	add	xbc, xix                               ; FC83A3  add XBC,XIX
	ld	(xbc), 1                                ; FC83A5  ld (XBC),0x01
	jr sub_FC81F8__FC83B4                      ; FC83A8  jr T,0xfc83b4
sub_FC81F8__FC83AA:
	lda	xbc, (0xE0D7:24)                       ; FC83AA  lda XBC,0x00e0d7
	add	xbc, xix                               ; FC83AF  add XBC,XIX
	ld	(xbc), 0                                ; FC83B1  ld (XBC),0x00
sub_FC81F8__FC83B4:
	add	de, 81                                 ; FC83B4  add DE,0x0051
	inc	1, h                                   ; FC83B8  inc 1,H
	cps	h, 4                                   ; FC83BA  cp H,4
	jr c, sub_FC81F8__FC8374                   ; FC83BC  jr C,0xfc8374
	jrl sub_FC81F8__FC8566                     ; FC83BE  jrl T,0xfc8566
sub_FC81F8__FC83C1:
	ldb	c, 4                                   ; FC83C1  ld C,0x04
	extpfx3 0x8E, 0x08, 0x43                   ; FC83C3  mul BC,(XIZ+0x08)
	ld	(xiz-2), bc                             ; FC83C6  ld (XIZ+0xfe),BC
	ldw	de, 0                                  ; FC83C9  ld DE,0x0000
sub_FC81F8__FC83CC:
	ld	bc, de                                  ; FC83CC  ld BC,DE
	extz	xbc                                   ; FC83CE  extz XBC
	add	xbc, 0xD9                              ; FC83D0  add XBC,0x000000d9
	extpfx3 0xAE, 0xF0, 0x81                   ; FC83D6  add XBC,(XIZ+0xf0)
	push	xbc                                   ; FC83D9  push XBC
	calr (0xFC81B8 - 0xFC83DD)                 ; FC83DA  calr 0xfc81b8
	ld	l, a                                    ; FC83DD  ld L,A
	ld	bc, (xiz-2)                             ; FC83DF  ld BC,(XIZ+0xfe)
	extz	xbc                                   ; FC83E2  extz XBC
	ld	(xiz-10), xbc                           ; FC83E4  ld (XIZ+0xf6),XBC
	ld	a, h                                    ; FC83E7  ld A,H
	extz	wa                                    ; FC83E9  extz WA
	extz	xwa                                   ; FC83EB  extz XWA
	ld	(xiz-6), xwa                            ; FC83ED  ld (XIZ+0xfa),XWA
	pop	xiy                                    ; FC83F0  pop XIY
	cps	l, 0                                   ; FC83F1  cp L,0
	jr nz, sub_FC81F8__FC8402                  ; FC83F3  jr NZ,0xfc8402
	add	xbc, xwa                               ; FC83F5  add XBC,XWA
	add	xbc, 0xE0D7                            ; FC83F7  add XBC,0x0000e0d7
	ld	(xbc), 1                                ; FC83FD  ld (XBC),0x01
	jr sub_FC81F8__FC8422                      ; FC8400  jr T,0xfc8422
sub_FC81F8__FC8402:
	ld	xix, (xiz-10)                           ; FC8402  ld XIX,(XIZ+0xf6)
	extpfx3 0xAE, 0xFA, 0x84                   ; FC8405  add XIX,(XIZ+0xfa)
	cps	l, 1                                   ; FC8408  cp L,1
	jr nz, sub_FC81F8__FC8418                  ; FC840A  jr NZ,0xfc8418
	lda	xbc, (0xE0D7:24)                       ; FC840C  lda XBC,0x00e0d7
	add	xbc, xix                               ; FC8411  add XBC,XIX
	ld	(xbc), 2                                ; FC8413  ld (XBC),0x02
	jr sub_FC81F8__FC8422                      ; FC8416  jr T,0xfc8422
sub_FC81F8__FC8418:
	lda	xbc, (0xE0D7:24)                       ; FC8418  lda XBC,0x00e0d7
	add	xbc, xix                               ; FC841D  add XBC,XIX
	ld	(xbc), 0                                ; FC841F  ld (XBC),0x00
sub_FC81F8__FC8422:
	add	de, 81                                 ; FC8422  add DE,0x0051
	inc	1, h                                   ; FC8426  inc 1,H
	cps	h, 4                                   ; FC8428  cp H,4
	jr c, sub_FC81F8__FC83CC                   ; FC842A  jr C,0xfc83cc
	jrl sub_FC81F8__FC8566                     ; FC842C  jrl T,0xfc8566
sub_FC81F8__FC842F:
	ld	xix, (xiz-20)                           ; FC842F  ld XIX,(XIZ+0xec)
	lda	xbc, (xiz-12)                          ; FC8432  lda XBC,XIZ+0xf4
	push	xbc                                   ; FC8435  push XBC
	ld	xwa, xix                                ; FC8436  ld XWA,XIX
	add	xwa, 17                                ; FC8438  add XWA,0x00000011
	push	xwa                                   ; FC843E  push XWA
	push	0                                     ; FC843F  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FC8441  push (XIZ+0x08)
	calr (0xFC8164 - 0xFC8447)                 ; FC8444  calr 0xfc8164
	ldb	h, 0                                   ; FC8447  ld H,0x00
	ldw	de, 0                                  ; FC8449  ld DE,0x0000
	inc	8, xsp                                 ; FC844C  inc 0,XSP
	inc	2, xsp                                 ; FC844E  inc 2,XSP
sub_FC81F8__FC8450:
	lda	xbc, (xiz-12)                          ; FC8450  lda XBC,XIZ+0xf4
	push	xbc                                   ; FC8453  push XBC
	ld	(xiz-22), de                            ; FC8454  ld (XIZ+0xea),DE
	ld	wa, (xiz-22)                            ; FC8457  ld WA,(XIZ+0xea)
	extz	xwa                                   ; FC845A  extz XWA
	ld	(xiz-26), xwa                           ; FC845C  ld (XIZ+0xe6),XWA
	add	xwa, 20                                ; FC845F  add XWA,0x00000014
	add	xwa, xix                               ; FC8465  add XWA,XIX
	push	xwa                                   ; FC8467  push XWA
	push	0                                     ; FC8468  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FC846A  push (XIZ+0x08)
	calr (0xFC8164 - 0xFC8470)                 ; FC846D  calr 0xfc8164
	lda	xbc, (xiz-12)                          ; FC8470  lda XBC,XIZ+0xf4
	push	xbc                                   ; FC8473  push XBC
	ld	xwa, (xiz-26)                           ; FC8474  ld XWA,(XIZ+0xe6)
	add	xwa, 26                                ; FC8477  add XWA,0x0000001a
	add	xwa, xix                               ; FC847D  add XWA,XIX
	push	xwa                                   ; FC847F  push XWA
	push	0                                     ; FC8480  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FC8482  push (XIZ+0x08)
	calr (0xFC8164 - 0xFC8488)                 ; FC8485  calr 0xfc8164
	lda	xbc, (xiz-12)                          ; FC8488  lda XBC,XIZ+0xf4
	push	xbc                                   ; FC848B  push XBC
	ld	xwa, (xiz-26)                           ; FC848C  ld XWA,(XIZ+0xe6)
	add	xwa, 34                                ; FC848F  add XWA,0x00000022
	add	xwa, xix                               ; FC8495  add XWA,XIX
	push	xwa                                   ; FC8497  push XWA
	push	0                                     ; FC8498  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FC849A  push (XIZ+0x08)
	calr (0xFC8164 - 0xFC84A0)                 ; FC849D  calr 0xfc8164
	lda	xbc, (xiz-12)                          ; FC84A0  lda XBC,XIZ+0xf4
	push	xbc                                   ; FC84A3  push XBC
	ld	xwa, (xiz-26)                           ; FC84A4  ld XWA,(XIZ+0xe6)
	add	xwa, 40                                ; FC84A7  add XWA,0x00000028
	add	xwa, xix                               ; FC84AD  add XWA,XIX
	push	xwa                                   ; FC84AF  push XWA
	push	0                                     ; FC84B0  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FC84B2  push (XIZ+0x08)
	calr (0xFC8164 - 0xFC84B8)                 ; FC84B5  calr 0xfc8164
	ld	de, (xiz-22)                            ; FC84B8  ld DE,(XIZ+0xea)
	inc	3, de                                  ; FC84BB  inc 3,DE
	inc	1, h                                   ; FC84BD  inc 1,H
	add	xsp, 40                                ; FC84BF  add XSP,0x00000028
	cps	h, 2                                   ; FC84C5  cp H,2
	jr c, sub_FC81F8__FC8450                   ; FC84C7  jr C,0xfc8450
	ldb	h, 0                                   ; FC84C9  ld H,0x00
	ldw	de, 0                                  ; FC84CB  ld DE,0x0000
sub_FC81F8__FC84CE:
	lda	xbc, (xiz-12)                          ; FC84CE  lda XBC,XIZ+0xf4
	push	xbc                                   ; FC84D1  push XBC
	ld	(xiz-22), de                            ; FC84D2  ld (XIZ+0xea),DE
	ld	wa, (xiz-22)                            ; FC84D5  ld WA,(XIZ+0xea)
	extz	xwa                                   ; FC84D8  extz XWA
	ld	(xiz-26), xwa                           ; FC84DA  ld (XIZ+0xe6),XWA
	add	xwa, 46                                ; FC84DD  add XWA,0x0000002e
	add	xwa, xix                               ; FC84E3  add XWA,XIX
	push	xwa                                   ; FC84E5  push XWA
	push	0                                     ; FC84E6  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FC84E8  push (XIZ+0x08)
	calr (0xFC8164 - 0xFC84EE)                 ; FC84EB  calr 0xfc8164
	lda	xbc, (xiz-12)                          ; FC84EE  lda XBC,XIZ+0xf4
	push	xbc                                   ; FC84F1  push XBC
	ld	xwa, (xiz-26)                           ; FC84F2  ld XWA,(XIZ+0xe6)
	add	xwa, 49                                ; FC84F5  add XWA,0x00000031
	add	xwa, xix                               ; FC84FB  add XWA,XIX
	push	xwa                                   ; FC84FD  push XWA
	push	0                                     ; FC84FE  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FC8500  push (XIZ+0x08)
	calr (0xFC8164 - 0xFC8506)                 ; FC8503  calr 0xfc8164
	ld	de, (xiz-22)                            ; FC8506  ld DE,(XIZ+0xea)
	inc	6, de                                  ; FC8509  inc 6,DE
	inc	1, h                                   ; FC850B  inc 1,H
	add	xsp, 20                                ; FC850D  add XSP,0x00000014
	cps	h, 6                                   ; FC8513  cp H,6
	jr c, sub_FC81F8__FC84CE                   ; FC8515  jr C,0xfc84ce
	ld	l, (xiz-12)                             ; FC8517  ld L,(XIZ+0xf4)
	ldb	h, 0                                   ; FC851A  ld H,0x00
	cps	l, 0                                   ; FC851C  cp L,0
	jr nz, sub_FC81F8__FC8544                  ; FC851E  jr NZ,0xfc8544
	ldb	c, 4                                   ; FC8520  ld C,0x04
	extpfx3 0x8E, 0x08, 0x43                   ; FC8522  mul BC,(XIZ+0x08)
	extz	xbc                                   ; FC8525  extz XBC
	ld	xix, xbc                                ; FC8527  ld XIX,XBC
sub_FC81F8__FC8529:
	ld	(xiz-24), xix                           ; FC8529  ld (XIZ+0xe8),XIX
	lda	xbc, (0xE0D7:24)                       ; FC852C  lda XBC,0x00e0d7
	extpfx3 0xAE, 0xE8, 0x81                   ; FC8531  add XBC,(XIZ+0xe8)
	ld	(xbc), 0                                ; FC8534  ld (XBC),0x00
	ld	xix, (xiz-24)                           ; FC8537  ld XIX,(XIZ+0xe8)
	inc	1, xix                                 ; FC853A  inc 1,XIX
	inc	1, h                                   ; FC853C  inc 1,H
	cps	h, 2                                   ; FC853E  cp H,2
	jr c, sub_FC81F8__FC8529                   ; FC8540  jr C,0xfc8529
	jr sub_FC81F8__FC8566                      ; FC8542  jr T,0xfc8566
sub_FC81F8__FC8544:
	ldb	c, 4                                   ; FC8544  ld C,0x04
	extpfx3 0x8E, 0x08, 0x43                   ; FC8546  mul BC,(XIZ+0x08)
	extz	xbc                                   ; FC8549  extz XBC
	ld	xix, xbc                                ; FC854B  ld XIX,XBC
sub_FC81F8__FC854D:
	ld	(xiz-24), xix                           ; FC854D  ld (XIZ+0xe8),XIX
	lda	xbc, (0xE0D7:24)                       ; FC8550  lda XBC,0x00e0d7
	extpfx3 0xAE, 0xE8, 0x81                   ; FC8555  add XBC,(XIZ+0xe8)
	ld	(xbc), 1                                ; FC8558  ld (XBC),0x01
	ld	xix, (xiz-24)                           ; FC855B  ld XIX,(XIZ+0xe8)
	inc	1, xix                                 ; FC855E  inc 1,XIX
	inc	1, h                                   ; FC8560  inc 1,H
	cps	h, 2                                   ; FC8562  cp H,2
	jr c, sub_FC81F8__FC854D                   ; FC8564  jr C,0xfc854d
sub_FC81F8__FC8566:
	pop	xix                                    ; FC8566  pop XIX
	popw	de                                    ; FC8567  pop DE
	popw	hl                                    ; FC8568  pop HL
	unlk32 xiz                                 ; FC8569  unlk XIZ
	ret                                        ; FC856B  ret

