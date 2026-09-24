; ==============================================================================
; Technics SX-WSA1R -- prom_c (CPU 2, IC28) -- 0xFAD142-0xFB0503  the MIDI controllers, the part record and the global setup
; ==============================================================================
;
; 8,616 lines moved out of prom_c/wsa1_prom_c.s by notes/prom_c_split.py.  The master
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
; Its top banner is a routine census with no title, but the block is
; majority-NAMED and the names agree: 105 MidiCtrl_*, 131 Voice_*,
; 31 GlobalSetup_*, 19 PartRec_* against 150 sub_XXXXXX.  It carries two of
; its own sub-banners -- `THE GLOBAL SETUP RECORD` and `THE PART RECORD, AND
; THE CONTROLLERS THAT WRITE IT` -- which is the subject stated by the tree,
; not by this pass.
;
; >>> END OF EXTRACTION HEADER -- everything below is verbatim from the master

; ==============================================================================
; 0xFAD142-0xFB0503 -- not yet converted
; ==============================================================================

; ==============================================================================
; 0xFAD142-0xFB0503 -- 99 routines, 48 computed-goto arm(s), 1 table(s), 13,250 bytes
; ==============================================================================
;
; Boundaries, read off the bytes rather than asserted:
;   0xFAD141 = 0x0E (`ret`)   0xFAD142 = EE 0C (`link XIZ`)
;   0xFB0503 = 0x0E (`ret`)   0xFB0504 = EE 0C (`link XIZ`)
;   ⚠ A `ret`/`link` pair at a cut is evidence the cut falls between
;   routines; anything else on those lines is a cut that needs reading.
;
; Call census (`python3 notes/prom_c_module_map.py 0xFAD142 0xFB0504`):
;   104 literal call site(s) from outside this block, 154 from inside it.
;         22  sub_FBB793
;         21  sub_FBCD17
;         20  sub_FBDCD3
;         20  sub_FBF280
;          8  sub_FB8CEC
;          4  MidiIn_ParseRingAndDispatch
;          3  sub_FBC39D
;          2  sub_FBD46B
;          2  MidiMsg_SendBootSequence
;          1  sub_FBDA2C
;       ... and 1 further caller(s)
;   ⚠ Sites in code that is still `.incbin` are counted under
;   "(caller not yet converted)"; that row shrinks as conversion proceeds,
;   so every named row is a FLOOR.
;
; Computed-goto tables (`python3 notes/prom_c_jumptables.py 0xFAD142 0xFB0504`):
;   0xFAF08F  49 entries -- the `cp rr,48` guard and the contents walk
;             both give 49, and the word after the last entry is not a
;             plausible one.  Emitted as `.long`, not decoded.
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
;     python3 notes/gen_prom_c_block.py --start 0xFAD142 --end 0xFB0504 > /tmp/b.s
;     python3 notes/gen_prom_c_block_headers.py --start 0xFAD142 --end 0xFB0504 \
;         --labels > /tmp/b.labels
;     python3 notes/gen_prom_c_block_headers.py --start 0xFAD142 --end 0xFB0504 \
;         --headers > /tmp/b.headers
;     python3 notes/prom_c_apply_headers.py /tmp/b.s /tmp/b.labels \
;         /tmp/b.headers > /tmp/b.final.s
;     python3 notes/prom_c_verify_fragment.py c 0xFAD142 /tmp/b.final.s
; ==============================================================================
; --------------------------------------------------------------------------
; sub_FAD142 -- 0xFAD142..0xFAD202 (193 bytes)
;
; Called from: no site outside this module.
;          3 site(s) inside this module:
;          0xFAE145 0xFAE198 0xFAE1EF
; Inputs:  frame `link XIZ,-15`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C), (XIZ+0x0E)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFAD142-0xFAD202
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FAD142:
	link32 0xEE, 0x0C, 0xF1, 0xFF              ; FAD142  link XIZ,0xfff1
	push	xhl                                   ; FAD146  push XHL
	pushw	de                                   ; FAD147  push DE
	push	xix                                   ; FAD148  push XIX
	ld	(xiz-11), 0                             ; FAD149  ld (XIZ+0xf5),0x00
	ld	bc, (xiz+14)                            ; FAD14D  ld BC,(XIZ+0x0e)
	extpfx3 0x9E, 0x0C, 0xE1                   ; FAD150  or BC,(XIZ+0x0c)
	ld	(xiz-6), bc                             ; FAD153  ld (XIZ+0xfa),BC
	ld	hl, (xiz+8)                             ; FAD156  ld HL,(XIZ+0x08)
	extz	hl                                    ; FAD159  extz HL
	ld	wa, (xiz+14)                            ; FAD15B  ld WA,(XIZ+0x0e)
	cpl	wa                                     ; FAD15E  cpl WA
	ld	(xiz-2), wa                             ; FAD160  ld (XIZ+0xfe),WA
	ldw	iy, 0x12C                              ; FAD163  ld IY,0x012c
	mul	xiy, xhl                               ; FAD166  mul XIY,HL
	ld	(xiz-10), xiy                           ; FAD168  ld (XIZ+0xf6),XIY
	cpl	bc                                     ; FAD16B  cpl BC
	ld	(xiz-4), bc                             ; FAD16D  ld (XIZ+0xfc),BC
	ldw	de, 0                                  ; FAD170  ld DE,0x0000
sub_FAD142__FAD173:
	ld	ix, (xiz-11)                            ; FAD173  ld IX,(XIZ+0xf5)
	extz	ix                                    ; FAD176  extz IX
	extz	xix                                   ; FAD178  extz XIX
	lda	xbc, (0xFE1286:24)                     ; FAD17A  lda XBC,0xfe1286
	add	xbc, xix                               ; FAD17F  add XBC,XIX
	ld	a, (xbc)                                ; FAD181  ld A,(XBC)
	extpfx3 0x8E, 0x0A, 0xC1                   ; FAD183  and A,(XIZ+0x0a)
	jr z, sub_FAD142__FAD1DA                   ; FAD186  jr Z,0xfad1da
	lda	xbc, (0xFE128A:24)                     ; FAD188  lda XBC,0xfe128a
	add	xbc, xix                               ; FAD18D  add XBC,XIX
	ld	a, (xbc)                                ; FAD18F  ld A,(XBC)
	extpfx3 0x8E, 0x0A, 0xC1                   ; FAD191  and A,(XIZ+0x0a)
	ld	(xiz-13), a                             ; FAD194  ld (XIZ+0xf3),A
	ld	(xiz-15), de                            ; FAD197  ld (XIZ+0xf1),DE
	ld	hl, (xiz-10)                            ; FAD19A  ld HL,(XIZ+0xf6)
	ld	bc, (xiz-15)                            ; FAD19D  ld BC,(XIZ+0xf1)
	add	hl, bc                                 ; FAD1A0  add HL,BC
	add	hl, 0xA0                               ; FAD1A2  add HL,0x00a0
	extz	xhl                                   ; FAD1A6  extz XHL
	ld	ix, (xhl+0x1523)                        ; FAD1A8  ld IX,(XHL+0x1523)
	cp	a, 0:i3                                   ; FAD1AD  cp A,0
	jr z, sub_FAD142__FAD1BF                   ; FAD1AF  jr Z,0xfad1bf
	ld	bc, (xiz-6)                             ; FAD1B1  ld BC,(XIZ+0xfa)
	or	bc, ix                                  ; FAD1B4  or BC,IX
	extz	xhl                                   ; FAD1B6  extz XHL
	ld	(xhl+0x1523), bc                        ; FAD1B8  ld (XHL+0x1523),BC
	jr sub_FAD142__FAD1EF                      ; FAD1BD  jr T,0xfad1ef
sub_FAD142__FAD1BF:
	ld	bc, (xiz-2)                             ; FAD1BF  ld BC,(XIZ+0xfe)
	and	bc, ix                                 ; FAD1C2  and BC,IX
	ld	(xiz-13), bc                            ; FAD1C4  ld (XIZ+0xf3),BC
	extz	xhl                                   ; FAD1C7  extz XHL
	ld	(xhl+0x1523), bc                        ; FAD1C9  ld (XHL+0x1523),BC
	extpfx3 0x9E, 0x0C, 0xE1                   ; FAD1CE  or BC,(XIZ+0x0c)
	extz	xhl                                   ; FAD1D1  extz XHL
	ld	(xhl+0x1523), bc                        ; FAD1D3  ld (XHL+0x1523),BC
	jr sub_FAD142__FAD1EF                      ; FAD1D8  jr T,0xfad1ef
sub_FAD142__FAD1DA:
	ld	hl, de                                  ; FAD1DA  ld HL,DE
	ld	bc, (xiz-10)                            ; FAD1DC  ld BC,(XIZ+0xf6)
	add	bc, hl                                 ; FAD1DF  add BC,HL
	add	bc, 0xA0                               ; FAD1E1  add BC,0x00a0
	extz	xbc                                   ; FAD1E5  extz XBC
	ld	wa, (xiz-4)                             ; FAD1E7  ld WA,(XIZ+0xfc)
	and	(xbc+0x1523), wa                       ; FAD1EA  and (XBC+0x1523),WA
sub_FAD142__FAD1EF:
	add	de, 41                                 ; FAD1EF  add DE,0x0029
	incm8	1, (xiz-11)                          ; FAD1F3  inc 1,(XIZ+0xf5)
	cp (xiz-11), 0x04                          ; FAD1F6  cp (XIZ+0xf5),0x04
	jrl c, sub_FAD142__FAD173                  ; FAD1FA  jrl C,0xfad173
	pop	xix                                    ; FAD1FD  pop XIX
	popw	de                                    ; FAD1FE  pop DE
	pop	xhl                                    ; FAD1FF  pop XHL
	unlk32 xiz                                 ; FAD200  unlk XIZ
	ret                                        ; FAD202  ret
; --------------------------------------------------------------------------
; PartRec_SetOrClearParamBits_x4 -- 0xFAD203..0xFAD2D4 (210 bytes)
;
; Called from: no site outside this module.
;          9 site(s) inside this module:
;          0xFAED6B 0xFAEDB0 0xFAEDFC 0xFAEE3F 0xFAEE82 0xFAEEC5
;          0xFAEF0A 0xFAEF5F 0xFAEFB7
; Inputs:  frame `link XIZ,-11`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C), (XIZ+0x0E)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFAD203-0xFAD2D4
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7 finish pass).  SETS OR CLEARS TWO MASKS IN EACH OF FOUR 41-BYTE
;          SUB-RECORDS OF ONE PART RECORD.
;          ⚠ THIS HEADER IS THE CORRECTED ONE.  Its first draft, written in this same
;          round, said the routine only ORs, cited a third `or` at 0xFAD2AB that is
;          not an `or` at all (0xFAD2AB is `ld (XIZ+0xF7),HL`), and missed the two
;          `and` sites entirely.  The corrected reading below is what
;          `python3 notes/prom_c_finish_round7.py --params` re-derives.
;          THE BASE.  `mul BC,0x012C` at 0xFAD225 on argument (XIZ+0x08) forms the
;          part-record base (RAM 0x001523, stride 0x012C, 33 parts) and keeps it in
;          XIX.  A running offset starts at 0 (`ld HL,0x0000` at 0xFAD22B) and gains
;          41 per pass (`add HL,0x0029` at 0xFAD2C1); the loop runs FOUR times
;          (`cp (XIZ+0xF9),0x04` at 0xFAD2C8).  So the two words this touches are
;          part_record + 41*i + 0xA2 and + 41*i + 0xA4, i = 0..3 -- FOUR SUB-RECORDS
;          OF 41 BYTES starting at part_record+0xA0.
;          ★ THAT STRIDE IS CONFIRMED FROM OUTSIDE THIS ROUTINE: PartRec_RecomputeWord0006_FromToneRec's four
;          constant offsets into the same record are 0xA0, 0xC9, 0xF2 and 0x11B --
;          three gaps of exactly 41.
;          THE ARMS, AND WHAT THE SELECTOR ARGUMENT IS.  Two 4-byte tables are
;          indexed by the loop counter -- `add XBC,0x00FE1286` at 0xFAD238 and
;          `lda XBC,0xFE128A` at 0xFAD245 -- and each byte is ANDed with argument
;          (XIZ+0x0A) at 0xFAD240 and 0xFAD24F.  ★ THE TWO TABLES ARE ALREADY NAMED
;          OBJECTS IN THIS FILE: BitMasks_EvenBits (0xFE1286) = 1<<0, 1<<2, 1<<4,
;          1<<6 and BitMasks_OddBits (0xFE128A) = 1<<1, 1<<3, 1<<5, 1<<7.  So on
;          pass i the routine tests bit 2i and bit 2i+1 of the selector, and
;          ARGUMENT (XIZ+0x0A) IS A BYTE CARRYING TWO BITS PER SUB-RECORD -- the
;          even bit says whether that sub-record's +0xA2 word is set or cleared,
;          the odd bit the same for its +0xA4 word.  Four sub-records, eight bits,
;          one byte: the argument is exactly used up, which is what makes the
;          reading a decode and not a shape.
;            table0 byte fails      -> CLEAR both: `and (XBC+0x1523),DE` at 0xFAD2A6
;                                      on +0xA2 and `and (XBC+0x1523),WA` at 0xFAD2BC
;                                      on +0xA4.  DE and (XIZ+0xFE) are the arguments
;                                      COMPLEMENTED, by `cpl IY` at 0xFAD221 and
;                                      `cpl WA` at 0xFAD219.
;            table0 ok, table1 ok   -> SET both: `or (XBC+0x1523),WA` at 0xFAD268 on
;                                      +0xA2 with argument (XIZ+0x0C), and
;                                      `or (XBC+0x1523),IY` at 0xFAD279 on +0xA4 with
;                                      argument (XIZ+0x0E).
;            table0 ok, table1 fails-> SET +0xA2 only (`or` at 0xFAD291) and CLEAR
;                                      +0xA4 (the 0xFAD2AB arm).
;          WHO CALLS IT names it: ALL NINE of its literal call sites are
;          PartRec_ApplyParam_* routines -- the nine at part-record offsets +0x23,
;          +0x25, +0x27, +0x29, +0x2B, +0x2D, +0x2F, +0x31 and +0x33 -- each of which
;          stores one word of the part record's parameter block and then calls this
;          with a mask constant of its own.  ★ THOSE NINE MASKS ARE 1<<5 .. 1<<13,
;          one bit per word, in order, with no gap: nine consecutive words at stride
;          two against nine consecutive bit positions.  The other three appliers
;          (+0x1D, +0x1F, +0x21) do not call this routine at all.  Tabulated and
;          asserted by `python3 notes/prom_c_finish_round7.py --params`.
; Unknown:  what the four 41-byte sub-records ARE, and what reads +0xA2/+0xA4.  The
;          name states the operation, the count and the two field offsets, all
;          operands, and claims nothing about their role.
;          ⚠ AND WHAT THE CALLERS PASS AS THE SELECTOR IS NOT TRACED HERE.  All nine
;          callers push `ld A,(XBC)` -- byte +0 of the record at (XIZ+0x0C), the same
;          record Scale7Bit_ByDepth_* reads its bit-7 selector and its depth byte
;          from.  Checked on the FIRST and the LAST of the nine (0xFAED63 in
;          PartRec_ApplyParam_0023 and 0xFAEFAF in PartRec_ApplyParam_0033).  What
;          that record IS remains the open question the whole module hangs on.
; --------------------------------------------------------------------------
PartRec_SetOrClearParamBits_x4:
	link32 0xEE, 0x0C, 0xF5, 0xFF              ; FAD203  link XIZ,0xfff5
	pushw	hl                                   ; FAD207  push HL
	pushw	de                                   ; FAD208  push DE
	push	xix                                   ; FAD209  push XIX
	ld	(xiz-7), 0                              ; FAD20A  ld (XIZ+0xf9),0x00
	ld	bc, (xiz+8)                             ; FAD20E  ld BC,(XIZ+0x08)
	extz	bc                                    ; FAD211  extz BC
	ld	(xiz-9), bc                             ; FAD213  ld (XIZ+0xf7),BC
	ld	wa, (xiz+14)                            ; FAD216  ld WA,(XIZ+0x0e)
	cpl	wa                                     ; FAD219  cpl WA
	ld	(xiz-2), wa                             ; FAD21B  ld (XIZ+0xfe),WA
	ld	iy, (xiz+12)                            ; FAD21E  ld IY,(XIZ+0x0c)
	cpl	iy                                     ; FAD221  cpl IY
	ld	de, iy                                  ; FAD223  ld DE,IY
	mul	bc, 0x12C                              ; FAD225  mul BC,0x012c
	ld	xix, xbc                                ; FAD229  ld XIX,XBC
	ldw	hl, 0                                  ; FAD22B  ld HL,0x0000
sub_FAD203__FAD22E:
	ld	bc, (xiz-7)                             ; FAD22E  ld BC,(XIZ+0xf9)
	extz	bc                                    ; FAD231  extz BC
	extz	xbc                                   ; FAD233  extz XBC
	ld	(xiz-6), xbc                            ; FAD235  ld (XIZ+0xfa),XBC
	add	xbc, 0xFE1286                          ; FAD238  add XBC,0x00fe1286
	ld	a, (xbc)                                ; FAD23E  ld A,(XBC)
	extpfx3 0x8E, 0x0A, 0xC1                   ; FAD240  and A,(XIZ+0x0a)
	jr z, sub_FAD203__FAD298                   ; FAD243  jr Z,0xfad298
	lda	xbc, (0xFE128A:24)                     ; FAD245  lda XBC,0xfe128a
	extpfx3 0xAE, 0xFA, 0x81                   ; FAD24A  add XBC,(XIZ+0xfa)
	ld	a, (xbc)                                ; FAD24D  ld A,(XBC)
	extpfx3 0x8E, 0x0A, 0xC1                   ; FAD24F  and A,(XIZ+0x0a)
	jr z, sub_FAD203__FAD280                   ; FAD252  jr Z,0xfad280
	ld	(xiz-9), hl                             ; FAD254  ld (XIZ+0xf7),HL
	ld	bc, ix                                  ; FAD257  ld BC,IX
	extpfx3 0x9E, 0xF7, 0x81                   ; FAD259  add BC,(XIZ+0xf7)
	ld	(xiz-11), bc                            ; FAD25C  ld (XIZ+0xf5),BC
	add	bc, 0xA2                               ; FAD25F  add BC,0x00a2
	extz	xbc                                   ; FAD263  extz XBC
	ld	wa, (xiz+12)                            ; FAD265  ld WA,(XIZ+0x0c)
	or	(xbc+0x1523), wa                        ; FAD268  or (XBC+0x1523),WA
	ld	bc, (xiz-11)                            ; FAD26D  ld BC,(XIZ+0xf5)
	add	bc, 0xA4                               ; FAD270  add BC,0x00a4
	extz	xbc                                   ; FAD274  extz XBC
	ld	iy, (xiz+14)                            ; FAD276  ld IY,(XIZ+0x0e)
	or	(xbc+0x1523), iy                        ; FAD279  or (XBC+0x1523),IY
	jr sub_FAD203__FAD2C1                      ; FAD27E  jr T,0xfad2c1
sub_FAD203__FAD280:
	ld	(xiz-9), hl                             ; FAD280  ld (XIZ+0xf7),HL
	ld	bc, ix                                  ; FAD283  ld BC,IX
	extpfx3 0x9E, 0xF7, 0x81                   ; FAD285  add BC,(XIZ+0xf7)
	add	bc, 0xA2                               ; FAD288  add BC,0x00a2
	extz	xbc                                   ; FAD28C  extz XBC
	ld	wa, (xiz+12)                            ; FAD28E  ld WA,(XIZ+0x0c)
	or	(xbc+0x1523), wa                        ; FAD291  or (XBC+0x1523),WA
	jr sub_FAD203__FAD2AB                      ; FAD296  jr T,0xfad2ab
sub_FAD203__FAD298:
	ld	(xiz-9), hl                             ; FAD298  ld (XIZ+0xf7),HL
	ld	bc, ix                                  ; FAD29B  ld BC,IX
	extpfx3 0x9E, 0xF7, 0x81                   ; FAD29D  add BC,(XIZ+0xf7)
	add	bc, 0xA2                               ; FAD2A0  add BC,0x00a2
	extz	xbc                                   ; FAD2A4  extz XBC
	and	(xbc+0x1523), de                       ; FAD2A6  and (XBC+0x1523),DE
sub_FAD203__FAD2AB:
	ld	(xiz-9), hl                             ; FAD2AB  ld (XIZ+0xf7),HL
	ld	bc, ix                                  ; FAD2AE  ld BC,IX
	extpfx3 0x9E, 0xF7, 0x81                   ; FAD2B0  add BC,(XIZ+0xf7)
	add	bc, 0xA4                               ; FAD2B3  add BC,0x00a4
	extz	xbc                                   ; FAD2B7  extz XBC
	ld	wa, (xiz-2)                             ; FAD2B9  ld WA,(XIZ+0xfe)
	and	(xbc+0x1523), wa                       ; FAD2BC  and (XBC+0x1523),WA
sub_FAD203__FAD2C1:
	add	hl, 41                                 ; FAD2C1  add HL,0x0029
	incm8	1, (xiz-7)                           ; FAD2C5  inc 1,(XIZ+0xf9)
	cp (xiz-7), 0x04                           ; FAD2C8  cp (XIZ+0xf9),0x04
	jrl c, sub_FAD203__FAD22E                  ; FAD2CC  jrl C,0xfad22e
	pop	xix                                    ; FAD2CF  pop XIX
	popw	de                                    ; FAD2D0  pop DE
	popw	hl                                    ; FAD2D1  pop HL
	unlk32 xiz                                 ; FAD2D2  unlk XIZ
	ret                                        ; FAD2D4  ret
; --------------------------------------------------------------------------
; sub_FAD2D5 -- 0xFAD2D5..0xFAD37D (169 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFBDCFC in sub_FBDCD3__FBDCEA, 0xFBF2A9 in sub_FBF280
;          1 site(s) inside this module:
;          0xFAE11D
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Calls:   0xFC7E10 = sub_FC7E10, 0xFCB0D3 = Multiply32_Signed
;          0xFCB141 = Divide32_Signed
; Evidence: the listing below is the byte-identical round-trip of 0xFAD2D5-0xFAD37D
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FAD2D5:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FAD2D5  link XIZ,0xfffc
	push	xix                                   ; FAD2D9  push XIX
	ld	xbc, (xiz+12)                           ; FAD2DA  ld XBC,(XIZ+0x0c)
	ld	a, (xbc+1)                              ; FAD2DD  ld A,(XBC+0x01)
	and	a, 0x80                                ; FAD2E0  and A,0x80
	jr z, sub_FAD2D5__FAD2F3                   ; FAD2E3  jr Z,0xfad2f3
	ld	ix, (xiz+10)                            ; FAD2E5  ld IX,(XIZ+0x0a)
	exts	xix                                   ; FAD2E8  exts XIX
	ld	xwa, 0x2000                             ; FAD2EA  ld XWA,0x00002000
	sub	xix, xwa                               ; FAD2EF  sub XIX,XWA
	jr sub_FAD2D5__FAD2FD                      ; FAD2F1  jr T,0xfad2fd
sub_FAD2D5__FAD2F3:
	ld	bc, (xiz+10)                            ; FAD2F3  ld BC,(XIZ+0x0a)
	sra	bc, 1                                  ; FAD2F6  sra 0x01,BC
	exts	xbc                                   ; FAD2F9  exts XBC
	ld	xix, xbc                                ; FAD2FB  ld XIX,XBC
sub_FAD2D5__FAD2FD:
	ld	xbc, (xiz+12)                           ; FAD2FD  ld XBC,(XIZ+0x0c)
	ld	a, (xbc+2)                              ; FAD300  ld A,(XBC+0x02)
	pushw	wa                                   ; FAD303  push WA
	ld	xiy, xix                                ; FAD304  ld XIY,XIX
	sra	xiy, 6                                 ; FAD306  sra 0x06,XIY
	extpfx3 0xC7, 0xF4, 0x89                   ; FAD309  ld A,IYL
	pushw	wa                                   ; FAD30C  push WA
	push	0                                     ; FAD30D  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAD30F  push (XIZ+0x08)
	call	sub_FC7E10                              ; FAD312  call 0xfc7e10
	ld	xbc, (xiz+12)                           ; FAD316  ld XBC,(XIZ+0x0c)
	ld	a, (xbc+2)                              ; FAD319  ld A,(XBC+0x02)
	extz	wa                                    ; FAD31C  extz WA
	extz	xwa                                   ; FAD31E  extz XWA
	push	xwa                                   ; FAD320  push XWA
	push	xix                                   ; FAD321  push XIX
	call	Multiply32_Signed                              ; FAD322  call 0xfcb0d3
	sra	xiy, 6                                 ; FAD326  sra 0x06,XIY
	ld	(xiz-4), xiy                            ; FAD329  ld (XIZ+0xfc),XIY
	ld	bc, (xiz+8)                             ; FAD32C  ld BC,(XIZ+0x08)
	extz	bc                                    ; FAD32F  extz BC
	mul	bc, 0x12C                              ; FAD331  mul BC,0x012c
	add	bc, 18                                 ; FAD335  add BC,0x0012
	extz	xbc                                   ; FAD339  extz XBC
	ld	a, (xbc+0x1523)                         ; FAD33B  ld A,(XBC+0x1523)
	extz	wa                                    ; FAD340  extz WA
	extz	xwa                                   ; FAD342  extz XWA
	push	xwa                                   ; FAD344  push XWA
	push	xiy                                   ; FAD345  push XIY
	call	Multiply32_Signed                              ; FAD346  call 0xfcb0d3
	ld	xix, xiy                                ; FAD34A  ld XIX,XIY
	add	xiy, xiy                               ; FAD34C  add XIY,XIY
	ld	xix, xiy                                ; FAD34E  ld XIX,XIY
	inc	6, xsp                                 ; FAD350  inc 6,XSP
	cp	xiy, 0                                  ; FAD352  cp XIY,0x00000000
	jr le, sub_FAD2D5__FAD369                  ; FAD358  jr LE,0xfad369
	pushw	0                                    ; FAD35A  push 0x0000
	pushw	63                                   ; FAD35D  push 0x003f
	push	xiy                                   ; FAD360  push XIY
	call	Divide32_Signed                              ; FAD361  call 0xfcb141
	ld	xix, xiy                                ; FAD365  ld XIX,XIY
	jr sub_FAD2D5__FAD376                      ; FAD367  jr T,0xfad376
sub_FAD2D5__FAD369:
	pushw	0                                    ; FAD369  push 0x0000
	pushw	64                                   ; FAD36C  push 0x0040
	push	xix                                   ; FAD36F  push XIX
	call	Divide32_Signed                              ; FAD370  call 0xfcb141
	ld	xix, xiy                                ; FAD374  ld XIX,XIY
sub_FAD2D5__FAD376:
	ld	bc, ix                                  ; FAD376  ld BC,IX
	ld	wa, bc                                  ; FAD378  ld WA,BC
	pop	xix                                    ; FAD37A  pop XIX
	unlk32 xiz                                 ; FAD37B  unlk XIZ
	ret                                        ; FAD37D  ret
; --------------------------------------------------------------------------
; sub_FAD37E -- 0xFAD37E..0xFAD43D (192 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFBDA49 in sub_FBDA2C
;          1 site(s) inside this module:
;          0xFAE262
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C), (XIZ+0x10), (XIZ+0x12)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFAD37E-0xFAD43D
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FAD37E:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FAD37E  link XIZ,0xfffc
	push	xhl                                   ; FAD382  push XHL
	pushw	de                                   ; FAD383  push DE
	push	xix                                   ; FAD384  push XIX
	ld	xix, (xiz+12)                           ; FAD385  ld XIX,(XIZ+0x0c)
	ld	d, (xiz+10)                             ; FAD388  ld D,(XIZ+0x0a)
	ld	c, (xix+1)                              ; FAD38B  ld C,(XIX+0x01)
	and	c, 0x80                                ; FAD38E  and C,0x80
	jr z, sub_FAD37E__FAD3A8                   ; FAD391  jr Z,0xfad3a8
	cp	d, 64                                   ; FAD393  cp D,0x40
	jr ule, sub_FAD37E__FAD3A6                 ; FAD396  jr ULE,0xfad3a6
	ld	c, d                                    ; FAD398  ld C,D
	extz	bc                                    ; FAD39A  extz BC
	sub	bc, 64                                 ; FAD39C  sub BC,0x0040
	add	bc, bc                                 ; FAD3A0  add BC,BC
	ld	d, c                                    ; FAD3A2  ld D,C
	jr sub_FAD37E__FAD3A8                      ; FAD3A4  jr T,0xfad3a8
sub_FAD37E__FAD3A6:
	ld	d, 0:opc                                   ; FAD3A6  ld D,0x00
sub_FAD37E__FAD3A8:
	ld	c, 16:opc                                  ; FAD3A8  ld C,0x10
	extpfx3 0x8E, 0x12, 0x43                   ; FAD3AA  mul BC,(XIZ+0x12)
	ld	(xiz-2), bc                             ; FAD3AD  ld (XIZ+0xfe),BC
	ld	wa, (xiz+8)                             ; FAD3B0  ld WA,(XIZ+0x08)
	extz	wa                                    ; FAD3B3  extz WA
	mul	wa, 0x12C                              ; FAD3B5  mul WA,0x012c
	add	wa, bc                                 ; FAD3B9  add WA,BC
	ld	(xiz-4), wa                             ; FAD3BB  ld (XIZ+0xfc),WA
	ld	c, 4:opc                                   ; FAD3BE  ld C,0x04
	extpfx3 0x8E, 0x10, 0x43                   ; FAD3C0  mul BC,(XIZ+0x10)
	ld	hl, wa                                  ; FAD3C3  ld HL,WA
	add	hl, bc                                 ; FAD3C5  add HL,BC
	add	hl, 54                                 ; FAD3C7  add HL,0x0036
	cp	d, 0:i3                                   ; FAD3CB  cp D,0
	jr z, sub_FAD37E__FAD3F9                   ; FAD3CD  jr Z,0xfad3f9
	extz	xhl                                   ; FAD3CF  extz XHL
	ld	c, (xhl+0x1523)                         ; FAD3D1  ld C,(XHL+0x1523)
	ld	e, c                                    ; FAD3D6  ld E,C
	and	e, 85                                  ; FAD3D8  and E,0x55
	ld	c, (xix)                                ; FAD3DB  ld C,(XIX)
	ld	(xiz-2), c                              ; FAD3DD  ld (XIZ+0xfe),C
	and	c, 85                                  ; FAD3E0  and C,0x55
	or	c, e                                    ; FAD3E3  or C,E
	ld	(xiz-4), c                              ; FAD3E5  ld (XIZ+0xfc),C
	ld	a, (xiz-2)                              ; FAD3E8  ld A,(XIZ+0xfe)
	and	a, 0xAA                                ; FAD3EB  and A,0xaa
	or	c, a                                    ; FAD3EE  or C,A
	extz	xhl                                   ; FAD3F0  extz XHL
	ld	(xhl+0x1523), c                         ; FAD3F2  ld (XHL+0x1523),C
	jr sub_FAD37E__FAD401                      ; FAD3F7  jr T,0xfad401
sub_FAD37E__FAD3F9:
	extz	xhl                                   ; FAD3F9  extz XHL
	ld	(xhl+0x1523), 0                         ; FAD3FB  ld (XHL+0x1523),0x00
sub_FAD37E__FAD401:
	ld	c, d                                    ; FAD401  ld C,D
	extz	bc                                    ; FAD403  extz BC
	ld	(xiz-2), bc                             ; FAD405  ld (XIZ+0xfe),BC
	ld	a, (xix+2)                              ; FAD408  ld A,(XIX+0x02)
	extz	wa                                    ; FAD40B  extz WA
	mul	xbc, xwa                               ; FAD40D  mul XBC,WA
	ld	hl, bc                                  ; FAD40F  ld HL,BC
	srl	bc, 6                                  ; FAD411  srl 0x06,BC
	ld	hl, bc                                  ; FAD414  ld HL,BC
	ld	a, (xix+1)                              ; FAD416  ld A,(XIX+0x01)
	and	a, 0x80                                ; FAD419  and A,0x80
	jr z, sub_FAD37E__FAD429                   ; FAD41C  jr Z,0xfad429
	cp	bc, 0:i3                                  ; FAD41E  cp BC,0
	jr nz, sub_FAD37E__FAD434                  ; FAD420  jr NZ,0xfad434
	cp	d, 64                                   ; FAD422  cp D,0x40
	jr ule, sub_FAD37E__FAD434                 ; FAD425  jr ULE,0xfad434
	jr sub_FAD37E__FAD431                      ; FAD427  jr T,0xfad431
sub_FAD37E__FAD429:
	cp	hl, 0:i3                                  ; FAD429  cp HL,0
	jr nz, sub_FAD37E__FAD434                  ; FAD42B  jr NZ,0xfad434
	cp	d, 0:i3                                   ; FAD42D  cp D,0
	jr z, sub_FAD37E__FAD434                   ; FAD42F  jr Z,0xfad434
sub_FAD37E__FAD431:
	ldw	hl, 1                                  ; FAD431  ld HL,0x0001
sub_FAD37E__FAD434:
	ld	c, l                                    ; FAD434  ld C,L
	ld	a, c                                    ; FAD436  ld A,C
	pop	xix                                    ; FAD438  pop XIX
	popw	de                                    ; FAD439  pop DE
	pop	xhl                                    ; FAD43A  pop XHL
	unlk32 xiz                                 ; FAD43B  unlk XIZ
	ret                                        ; FAD43D  ret
; --------------------------------------------------------------------------
; sub_FAD43E -- 0xFAD43E..0xFAD4FD (192 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFBDBEB in sub_FBDBCE
;          1 site(s) inside this module:
;          0xFAE2E6
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C), (XIZ+0x10), (XIZ+0x12)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFAD43E-0xFAD4FD
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FAD43E:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FAD43E  link XIZ,0xfffc
	push	xhl                                   ; FAD442  push XHL
	pushw	de                                   ; FAD443  push DE
	push	xix                                   ; FAD444  push XIX
	ld	xix, (xiz+12)                           ; FAD445  ld XIX,(XIZ+0x0c)
	ld	d, (xiz+10)                             ; FAD448  ld D,(XIZ+0x0a)
	ld	c, (xix+1)                              ; FAD44B  ld C,(XIX+0x01)
	and	c, 0x80                                ; FAD44E  and C,0x80
	jr z, sub_FAD43E__FAD468                   ; FAD451  jr Z,0xfad468
	cp	d, 64                                   ; FAD453  cp D,0x40
	jr ule, sub_FAD43E__FAD466                 ; FAD456  jr ULE,0xfad466
	ld	c, d                                    ; FAD458  ld C,D
	extz	bc                                    ; FAD45A  extz BC
	sub	bc, 64                                 ; FAD45C  sub BC,0x0040
	add	bc, bc                                 ; FAD460  add BC,BC
	ld	d, c                                    ; FAD462  ld D,C
	jr sub_FAD43E__FAD468                      ; FAD464  jr T,0xfad468
sub_FAD43E__FAD466:
	ld	d, 0:opc                                   ; FAD466  ld D,0x00
sub_FAD43E__FAD468:
	ld	c, 16:opc                                  ; FAD468  ld C,0x10
	extpfx3 0x8E, 0x12, 0x43                   ; FAD46A  mul BC,(XIZ+0x12)
	ld	(xiz-2), bc                             ; FAD46D  ld (XIZ+0xfe),BC
	ld	wa, (xiz+8)                             ; FAD470  ld WA,(XIZ+0x08)
	extz	wa                                    ; FAD473  extz WA
	mul	wa, 0x12C                              ; FAD475  mul WA,0x012c
	add	wa, bc                                 ; FAD479  add WA,BC
	ld	(xiz-4), wa                             ; FAD47B  ld (XIZ+0xfc),WA
	ld	c, 4:opc                                   ; FAD47E  ld C,0x04
	extpfx3 0x8E, 0x10, 0x43                   ; FAD480  mul BC,(XIZ+0x10)
	ld	hl, wa                                  ; FAD483  ld HL,WA
	add	hl, bc                                 ; FAD485  add HL,BC
	add	hl, 54                                 ; FAD487  add HL,0x0036
	cp	d, 0:i3                                   ; FAD48B  cp D,0
	jr z, sub_FAD43E__FAD4B9                   ; FAD48D  jr Z,0xfad4b9
	extz	xhl                                   ; FAD48F  extz XHL
	ld	c, (xhl+0x1523)                         ; FAD491  ld C,(XHL+0x1523)
	ld	e, c                                    ; FAD496  ld E,C
	and	e, 85                                  ; FAD498  and E,0x55
	ld	c, (xix)                                ; FAD49B  ld C,(XIX)
	ld	(xiz-2), c                              ; FAD49D  ld (XIZ+0xfe),C
	and	c, 85                                  ; FAD4A0  and C,0x55
	or	c, e                                    ; FAD4A3  or C,E
	ld	(xiz-4), c                              ; FAD4A5  ld (XIZ+0xfc),C
	ld	a, (xiz-2)                              ; FAD4A8  ld A,(XIZ+0xfe)
	and	a, 0xAA                                ; FAD4AB  and A,0xaa
	or	c, a                                    ; FAD4AE  or C,A
	extz	xhl                                   ; FAD4B0  extz XHL
	ld	(xhl+0x1523), c                         ; FAD4B2  ld (XHL+0x1523),C
	jr sub_FAD43E__FAD4C1                      ; FAD4B7  jr T,0xfad4c1
sub_FAD43E__FAD4B9:
	extz	xhl                                   ; FAD4B9  extz XHL
	ld	(xhl+0x1523), 0                         ; FAD4BB  ld (XHL+0x1523),0x00
sub_FAD43E__FAD4C1:
	ld	c, d                                    ; FAD4C1  ld C,D
	extz	bc                                    ; FAD4C3  extz BC
	ld	(xiz-2), bc                             ; FAD4C5  ld (XIZ+0xfe),BC
	ld	a, (xix+2)                              ; FAD4C8  ld A,(XIX+0x02)
	extz	wa                                    ; FAD4CB  extz WA
	mul	xbc, xwa                               ; FAD4CD  mul XBC,WA
	ld	hl, bc                                  ; FAD4CF  ld HL,BC
	srl	bc, 6                                  ; FAD4D1  srl 0x06,BC
	ld	hl, bc                                  ; FAD4D4  ld HL,BC
	ld	a, (xix+1)                              ; FAD4D6  ld A,(XIX+0x01)
	and	a, 0x80                                ; FAD4D9  and A,0x80
	jr z, sub_FAD43E__FAD4E9                   ; FAD4DC  jr Z,0xfad4e9
	cp	bc, 0:i3                                  ; FAD4DE  cp BC,0
	jr nz, sub_FAD43E__FAD4F4                  ; FAD4E0  jr NZ,0xfad4f4
	cp	d, 64                                   ; FAD4E2  cp D,0x40
	jr ule, sub_FAD43E__FAD4F4                 ; FAD4E5  jr ULE,0xfad4f4
	jr sub_FAD43E__FAD4F1                      ; FAD4E7  jr T,0xfad4f1
sub_FAD43E__FAD4E9:
	cp	hl, 0:i3                                  ; FAD4E9  cp HL,0
	jr nz, sub_FAD43E__FAD4F4                  ; FAD4EB  jr NZ,0xfad4f4
	cp	d, 0:i3                                   ; FAD4ED  cp D,0
	jr z, sub_FAD43E__FAD4F4                   ; FAD4EF  jr Z,0xfad4f4
sub_FAD43E__FAD4F1:
	ldw	hl, 1                                  ; FAD4F1  ld HL,0x0001
sub_FAD43E__FAD4F4:
	ld	c, l                                    ; FAD4F4  ld C,L
	ld	a, c                                    ; FAD4F6  ld A,C
	pop	xix                                    ; FAD4F8  pop XIX
	popw	de                                    ; FAD4F9  pop DE
	pop	xhl                                    ; FAD4FA  pop XHL
	unlk32 xiz                                 ; FAD4FB  unlk XIZ
	ret                                        ; FAD4FD  ret
; --------------------------------------------------------------------------
; Scale7Bit_ByDepth_UniOrBipolar_Shl2 -- 0xFAD4FE..0xFAD560 (99 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFBF09D in sub_FBDCD3__FBF094, 0xFBFE43 in sub_FBF280__FBFE37
;          1 site(s) inside this module:
;          0xFAEF8D
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFAD4FE-0xFAD560
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7 finish pass).  Scale7Bit_ByDepth_UniOrBipolar WITH A SHIFT OF 2.
;          99 bytes, 3 of which differ from Scale7Bit_ByDepth_UniOrBipolar at 0xFAD5C2,
;          and all three are the SAME PARAMETER expressed twice: the shift in the
;          bipolar arm (`sll 0x02,IY` at 0xFAD515, count byte 0xFAD517), the shift in
;          the unipolar arm (`sll 0x02,BC` at 0xFAD541, count byte 0xFAD543) and the
;          bipolar mid-point (`sub IY,0x0100` at 0xFAD51A, high byte 0xFAD51D).
;          0x0100 = 64 << 2, so the mid-point tracks the shift exactly.
;          The output span therefore runs -4..+4 instead of the -32..+32 of the shl-5
;          original: v<<N spans 0..127<<N, the bipolar arm subtracts 64<<N and divides
;          the halves by 63 and 64, and the unipolar arm divides by 127.
; --------------------------------------------------------------------------
Scale7Bit_ByDepth_UniOrBipolar_Shl2:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAD4FE  link XIZ,0x0000
	pushw	hl                                   ; FAD502  push HL
	ld	xbc, (xiz+10)                           ; FAD503  ld XBC,(XIZ+0x0a)
	ld	a, (xbc+1)                              ; FAD506  ld A,(XBC+0x01)
	and	a, 0x80                                ; FAD509  and A,0x80
	jr z, sub_FAD4FE__FAD53A                   ; FAD50C  jr Z,0xfad53a
	ld	hl, (xiz+8)                             ; FAD50E  ld HL,(XIZ+0x08)
	extz	hl                                    ; FAD511  extz HL
	ld	iy, hl                                  ; FAD513  ld IY,HL
	sll	iy, 2                                  ; FAD515  sll 0x02,IY
	ld	hl, iy                                  ; FAD518  ld HL,IY
	sub	iy, 0x100                              ; FAD51A  sub IY,0x0100
	ld	hl, iy                                  ; FAD51E  ld HL,IY
	cp	iy, 0:i3                                  ; FAD520  cp IY,0
	jr le, sub_FAD4FE__FAD52E                  ; FAD522  jr LE,0xfad52e
	exts	xiy                                   ; FAD524  exts XIY
	divs	iy, 63                                ; FAD526  divs IY,0x003f
	ld	hl, iy                                  ; FAD52A  ld HL,IY
	jr sub_FAD4FE__FAD54E                      ; FAD52C  jr T,0xfad54e
sub_FAD4FE__FAD52E:
	ld	bc, hl                                  ; FAD52E  ld BC,HL
	exts	xbc                                   ; FAD530  exts XBC
	divs	bc, 64                                ; FAD532  divs BC,0x0040
	ld	hl, bc                                  ; FAD536  ld HL,BC
	jr sub_FAD4FE__FAD54E                      ; FAD538  jr T,0xfad54e
sub_FAD4FE__FAD53A:
	ld	hl, (xiz+8)                             ; FAD53A  ld HL,(XIZ+0x08)
	extz	hl                                    ; FAD53D  extz HL
	ld	bc, hl                                  ; FAD53F  ld BC,HL
	sll	bc, 2                                  ; FAD541  sll 0x02,BC
	ld	hl, bc                                  ; FAD544  ld HL,BC
	exts	xbc                                   ; FAD546  exts XBC
	divs	bc, 0x7F                              ; FAD548  divs BC,0x007f
	ld	hl, bc                                  ; FAD54C  ld HL,BC
sub_FAD4FE__FAD54E:
	ld	xbc, (xiz+10)                           ; FAD54E  ld XBC,(XIZ+0x0a)
	ld	a, (xbc+2)                              ; FAD551  ld A,(XBC+0x02)
	extz	wa                                    ; FAD554  extz WA
	muls	xwa, xhl                              ; FAD556  muls XWA,HL
	ld	hl, wa                                  ; FAD558  ld HL,WA
	sra	wa, 6                                  ; FAD55A  sra 0x06,WA
	popw	hl                                    ; FAD55D  pop HL
	unlk32 xiz                                 ; FAD55E  unlk XIZ
	ret                                        ; FAD560  ret
; --------------------------------------------------------------------------
; sub_FAD561 -- 0xFAD561..0xFAD5C1 (97 bytes)
;
; Called from: 6 site(s) outside this module:
;          0xFBEBC2 in sub_FBDCD3__FBEBB9, 0xFBEC1C in sub_FBDCD3__FBEC13
;          0xFBEDE6 in sub_FBDCD3__FBEDDD, 0xFBF8B2 in sub_FBF280__FBF8A6
;          0xFBF917 in sub_FBF280__FBF90B, 0xFBFB23 in sub_FBF280__FBFB17
;          3 site(s) inside this module:
;          0xFAEBE0 0xFAEC30 0xFAED41
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFAD561-0xFAD5C1
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FAD561:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAD561  link XIZ,0x0000
	pushw	hl                                   ; FAD565  push HL
	ld	xbc, (xiz+10)                           ; FAD566  ld XBC,(XIZ+0x0a)
	ld	a, (xbc+1)                              ; FAD569  ld A,(XBC+0x01)
	and	a, 0x80                                ; FAD56C  and A,0x80
	jr z, sub_FAD561__FAD59C                   ; FAD56F  jr Z,0xfad59c
	ld	wa, (xiz+8)                             ; FAD571  ld WA,(XIZ+0x08)
	extz	wa                                    ; FAD574  extz WA
	muls	wa, 25                                ; FAD576  muls WA,0x0019
	ld	hl, wa                                  ; FAD57A  ld HL,WA
	sub	wa, 0x640                              ; FAD57C  sub WA,0x0640
	ld	hl, wa                                  ; FAD580  ld HL,WA
	cp	wa, 0:i3                                  ; FAD582  cp WA,0
	jr le, sub_FAD561__FAD590                  ; FAD584  jr LE,0xfad590
	exts	xwa                                   ; FAD586  exts XWA
	divs	wa, 63                                ; FAD588  divs WA,0x003f
	ld	hl, wa                                  ; FAD58C  ld HL,WA
	jr sub_FAD561__FAD5AF                      ; FAD58E  jr T,0xfad5af
sub_FAD561__FAD590:
	ld	bc, hl                                  ; FAD590  ld BC,HL
	exts	xbc                                   ; FAD592  exts XBC
	divs	bc, 64                                ; FAD594  divs BC,0x0040
	ld	hl, bc                                  ; FAD598  ld HL,BC
	jr sub_FAD561__FAD5AF                      ; FAD59A  jr T,0xfad5af
sub_FAD561__FAD59C:
	ld	bc, (xiz+8)                             ; FAD59C  ld BC,(XIZ+0x08)
	extz	bc                                    ; FAD59F  extz BC
	muls	bc, 25                                ; FAD5A1  muls BC,0x0019
	ld	hl, bc                                  ; FAD5A5  ld HL,BC
	exts	xbc                                   ; FAD5A7  exts XBC
	divs	bc, 0x7F                              ; FAD5A9  divs BC,0x007f
	ld	hl, bc                                  ; FAD5AD  ld HL,BC
sub_FAD561__FAD5AF:
	ld	xbc, (xiz+10)                           ; FAD5AF  ld XBC,(XIZ+0x0a)
	ld	a, (xbc+2)                              ; FAD5B2  ld A,(XBC+0x02)
	extz	wa                                    ; FAD5B5  extz WA
	muls	xwa, xhl                              ; FAD5B7  muls XWA,HL
	ld	hl, wa                                  ; FAD5B9  ld HL,WA
	sra	wa, 6                                  ; FAD5BB  sra 0x06,WA
	popw	hl                                    ; FAD5BE  pop HL
	unlk32 xiz                                 ; FAD5BF  unlk XIZ
	ret                                        ; FAD5C1  ret
; --------------------------------------------------------------------------
; Scale7Bit_ByDepth_UniOrBipolar -- 0xFAD5C2..0xFAD624 (99 bytes)
;             scale a 0..127 value by a record's depth byte, normalised either unipolar
;             (/0x7F) or bipolar (offset 0x800, /63 or /64) as bit 7 of the record
;             selects.
;             (★ NAMED in wave 7 round 2; was `sub_FAD5C2`.)
;
; Called from: 28 site(s) outside this module:
;          0xFBDE9B in sub_FBDCD3__FBDE92, 0xFBDFCE in sub_FBDCD3__FBDFC5
;          0xFBE998 in sub_FBDCD3__FBE98F, 0xFBEB68 in sub_FBDCD3__FBEB5F
;          0xFBEC76 in sub_FBDCD3__FBEC6D, 0xFBED01 in sub_FBDCD3__FBECF8
;          0xFBED8C in sub_FBDCD3__FBED83, 0xFBEE40 in sub_FBDCD3__FBEE37
;          0xFBEE9A in sub_FBDCD3__FBEE91, 0xFBEECF in sub_FBDCD3__FBEEC6
;          0xFBEF04 in sub_FBDCD3__FBEEFB, 0xFBEF5E in sub_FBDCD3__FBEF55
;          0xFBEFB8 in sub_FBDCD3__FBEFAF, 0xFBF043 in sub_FBDCD3__FBF03A
;          0xFBF461 in sub_FBF280__FBF455, 0xFBF59F in sub_FBF280__FBF593
;          0xFBF6A5 in sub_FBF280__FBF699, 0xFBF84D in sub_FBF280__FBF841
;          0xFBF97C in sub_FBF280__FBF970, 0xFBFA1D in sub_FBF280__FBFA11
;          0xFBFABE in sub_FBF280__FBFAB2, 0xFBFB88 in sub_FBF280__FBFB7C
;          0xFBFBED in sub_FBF280__FBFBE1, 0xFBFC30 in sub_FBF280__FBFBE1
;          0xFBFC73 in sub_FBF280__FBFBE1, 0xFBFCD8 in sub_FBF280__FBFCCC
;          0xFBFD3D in sub_FBF280__FBFD31, 0xFBFDDE in sub_FBF280__FBFDD2
;          13 site(s) inside this module:
;          0xFAE170 0xFAEADC 0xFAEB74 0xFAEC7F 0xFAECAA 0xFAECD6
;          0xFAED88 0xFAEDD2 0xFAEE15 0xFAEE58 0xFAEE9B 0xFAEEE2
;          0xFAEF37
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: ★ the branch, the two normalisations and the final scale are all immediates:
;          (Each address in the block below is the FIRST instruction of the step it
;          labels, not the only one; the rest of the step follows it.)
;              0xFAD5C7  ld XBC,(XIZ+0x0a) / ld A,(XBC+0x01) / and A,0x80 / jr
;                Z,unipolar        -- BIT 7 of record byte +1 is the selector
;            bipolar arm:
;              0xFAD5D7  ld IY,HL / sll 0x05,IY / sub IY,0x0800     -- v*32 - 2048
;              0xFAD5E4  cp IY,0 / jr LE,neg
;              0xFAD5EA  divs IY,0x003f       -- positive half divided by 63
;              0xFAD5F6  divs BC,0x0040       -- negative half divided by 64
;            unipolar arm:
;              0xFAD605  sll 0x05,BC   then   0xFAD60C  divs BC,0x007f   -- v*32 / 127
;            both arms:
;              0xFAD612  ld XBC,(XIZ+0x0a)   -- the record again
;              0xFAD615  ld A,(XBC+0x02)     -- the depth byte
;              0xFAD61A  muls XWA,HL   then   0xFAD61E  sra 0x06,WA   -- * depth, >> 6
;          v*32 spans 0..4064 for v in 0..127, so the unipolar arm lands in 0..32 and
;          the bipolar arm, after the 2048 offset, in about -32..+32 -- which is what
;          makes "uni or bipolar" a description of the arithmetic rather than an
;          interpretation of it.  The asymmetric divisors 63 and 64 are the two halves'
;          own spans; they are immediates, not a reading.
;          The routine sits between the Dev10C_SetChanReg_* accessors and MidiCtrl_CC07,
;          and 28 of its 41 call sites are outside this module.
; Unknown:  ⚠ what the record at (XIZ+0x0A) IS.  Only two of its bytes are touched, +1
;          for the selector bit and +2 for the depth, and neither was traced to a named
;          structure.  "Depth" names the ROLE the multiply gives byte +2, not a
;          documented field.
;          ⚠ that the input is a MIDI controller value.  0..127 is what the arithmetic
;          assumes; the module is the MIDI controller module; neither fact is a proof
;          about the caller.
; --------------------------------------------------------------------------
Scale7Bit_ByDepth_UniOrBipolar:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAD5C2  link XIZ,0x0000
	pushw	hl                                   ; FAD5C6  push HL
	ld	xbc, (xiz+10)                           ; FAD5C7  ld XBC,(XIZ+0x0a)
	ld	a, (xbc+1)                              ; FAD5CA  ld A,(XBC+0x01)
	and	a, 0x80                                ; FAD5CD  and A,0x80
	jr z, Scale7Bit_ByDepth_UniOrBipolar__FAD5FE                   ; FAD5D0  jr Z,0xfad5fe
	ld	hl, (xiz+8)                             ; FAD5D2  ld HL,(XIZ+0x08)
	extz	hl                                    ; FAD5D5  extz HL
	ld	iy, hl                                  ; FAD5D7  ld IY,HL
	sll	iy, 5                                  ; FAD5D9  sll 0x05,IY
	ld	hl, iy                                  ; FAD5DC  ld HL,IY
	sub	iy, 0x800                              ; FAD5DE  sub IY,0x0800
	ld	hl, iy                                  ; FAD5E2  ld HL,IY
	cp	iy, 0:i3                                  ; FAD5E4  cp IY,0
	jr le, Scale7Bit_ByDepth_UniOrBipolar__FAD5F2                  ; FAD5E6  jr LE,0xfad5f2
	exts	xiy                                   ; FAD5E8  exts XIY
	divs	iy, 63                                ; FAD5EA  divs IY,0x003f
	ld	hl, iy                                  ; FAD5EE  ld HL,IY
	jr Scale7Bit_ByDepth_UniOrBipolar__FAD612                      ; FAD5F0  jr T,0xfad612
Scale7Bit_ByDepth_UniOrBipolar__FAD5F2:
	ld	bc, hl                                  ; FAD5F2  ld BC,HL
	exts	xbc                                   ; FAD5F4  exts XBC
	divs	bc, 64                                ; FAD5F6  divs BC,0x0040
	ld	hl, bc                                  ; FAD5FA  ld HL,BC
	jr Scale7Bit_ByDepth_UniOrBipolar__FAD612                      ; FAD5FC  jr T,0xfad612
Scale7Bit_ByDepth_UniOrBipolar__FAD5FE:
	ld	hl, (xiz+8)                             ; FAD5FE  ld HL,(XIZ+0x08)
	extz	hl                                    ; FAD601  extz HL
	ld	bc, hl                                  ; FAD603  ld BC,HL
	sll	bc, 5                                  ; FAD605  sll 0x05,BC
	ld	hl, bc                                  ; FAD608  ld HL,BC
	exts	xbc                                   ; FAD60A  exts XBC
	divs	bc, 0x7F                              ; FAD60C  divs BC,0x007f
	ld	hl, bc                                  ; FAD610  ld HL,BC
Scale7Bit_ByDepth_UniOrBipolar__FAD612:
	ld	xbc, (xiz+10)                           ; FAD612  ld XBC,(XIZ+0x0a)
	ld	a, (xbc+2)                              ; FAD615  ld A,(XBC+0x02)
	extz	wa                                    ; FAD618  extz WA
	muls	xwa, xhl                              ; FAD61A  muls XWA,HL
	ld	hl, wa                                  ; FAD61C  ld HL,WA
	sra	wa, 6                                  ; FAD61E  sra 0x06,WA
	popw	hl                                    ; FAD621  pop HL
	unlk32 xiz                                 ; FAD622  unlk XIZ
	ret                                        ; FAD624  ret
; --------------------------------------------------------------------------
; Scale7Bit_ByDepth_UniOrBipolar_Shl6 -- 0xFAD625..0xFAD687 (99 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAE1C4
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFAD625-0xFAD687
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7 finish pass).  Scale7Bit_ByDepth_UniOrBipolar WITH A SHIFT OF 6.
;          99 bytes, 3 differing from 0xFAD5C2: `sll 0x06,IY` at 0xFAD63C (count byte
;          0xFAD63E), `sll 0x06,BC` at 0xFAD668 (count byte 0xFAD66A) and
;          `sub IY,0x1000` at 0xFAD641 (high byte 0xFAD644).
;          0x1000 = 64 << 6.  Output span -64..+64.
; --------------------------------------------------------------------------
Scale7Bit_ByDepth_UniOrBipolar_Shl6:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAD625  link XIZ,0x0000
	pushw	hl                                   ; FAD629  push HL
	ld	xbc, (xiz+10)                           ; FAD62A  ld XBC,(XIZ+0x0a)
	ld	a, (xbc+1)                              ; FAD62D  ld A,(XBC+0x01)
	and	a, 0x80                                ; FAD630  and A,0x80
	jr z, sub_FAD625__FAD661                   ; FAD633  jr Z,0xfad661
	ld	hl, (xiz+8)                             ; FAD635  ld HL,(XIZ+0x08)
	extz	hl                                    ; FAD638  extz HL
	ld	iy, hl                                  ; FAD63A  ld IY,HL
	sll	iy, 6                                  ; FAD63C  sll 0x06,IY
	ld	hl, iy                                  ; FAD63F  ld HL,IY
	sub	iy, 0x1000                             ; FAD641  sub IY,0x1000
	ld	hl, iy                                  ; FAD645  ld HL,IY
	cp	iy, 0:i3                                  ; FAD647  cp IY,0
	jr le, sub_FAD625__FAD655                  ; FAD649  jr LE,0xfad655
	exts	xiy                                   ; FAD64B  exts XIY
	divs	iy, 63                                ; FAD64D  divs IY,0x003f
	ld	hl, iy                                  ; FAD651  ld HL,IY
	jr sub_FAD625__FAD675                      ; FAD653  jr T,0xfad675
sub_FAD625__FAD655:
	ld	bc, hl                                  ; FAD655  ld BC,HL
	exts	xbc                                   ; FAD657  exts XBC
	divs	bc, 64                                ; FAD659  divs BC,0x0040
	ld	hl, bc                                  ; FAD65D  ld HL,BC
	jr sub_FAD625__FAD675                      ; FAD65F  jr T,0xfad675
sub_FAD625__FAD661:
	ld	hl, (xiz+8)                             ; FAD661  ld HL,(XIZ+0x08)
	extz	hl                                    ; FAD664  extz HL
	ld	bc, hl                                  ; FAD666  ld BC,HL
	sll	bc, 6                                  ; FAD668  sll 0x06,BC
	ld	hl, bc                                  ; FAD66B  ld HL,BC
	exts	xbc                                   ; FAD66D  exts XBC
	divs	bc, 0x7F                              ; FAD66F  divs BC,0x007f
	ld	hl, bc                                  ; FAD673  ld HL,BC
sub_FAD625__FAD675:
	ld	xbc, (xiz+10)                           ; FAD675  ld XBC,(XIZ+0x0a)
	ld	a, (xbc+2)                              ; FAD678  ld A,(XBC+0x02)
	extz	wa                                    ; FAD67B  extz WA
	muls	xwa, xhl                              ; FAD67D  muls XWA,HL
	ld	hl, wa                                  ; FAD67F  ld HL,WA
	sra	wa, 6                                  ; FAD681  sra 0x06,WA
	popw	hl                                    ; FAD684  pop HL
	unlk32 xiz                                 ; FAD685  unlk XIZ
	ret                                        ; FAD687  ret
; --------------------------------------------------------------------------
; Scale7Bit_ByDepth_UniOrBipolar_Shl7 -- 0xFAD688..0xFAD6EA (99 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFBEA5C in sub_FBDCD3__FBEA53, 0xFBF755 in sub_FBF280__FBF749
;          1 site(s) inside this module:
;          0xFAEB08
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFAD688-0xFAD6EA
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7 finish pass).  Scale7Bit_ByDepth_UniOrBipolar WITH A SHIFT OF 7.
;          99 bytes, 3 differing from 0xFAD5C2: `sll 0x07,IY` at 0xFAD69F (count byte
;          0xFAD6A1), `sll 0x07,BC` at 0xFAD6CB (count byte 0xFAD6CD) and
;          `sub IY,0x2000` at 0xFAD6A4 (high byte 0xFAD6A7).
;          0x2000 = 64 << 7.  Output span -128..+128.
;          ⚠ THE FAMILY IS FOUR AND ONLY FOUR: shifts 2, 5, 6 and 7.  Exactly three
;          99-byte objects in prom_c are within 3 differing bytes of 0xFAD5C2, and
;          they are these three -- `notes/prom_c_finish_round7.py --twins` sweeps
;          every same-length pair in the image, not a shortlist, and --selftest
;          asserts the count is 3.
; --------------------------------------------------------------------------
Scale7Bit_ByDepth_UniOrBipolar_Shl7:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAD688  link XIZ,0x0000
	pushw	hl                                   ; FAD68C  push HL
	ld	xbc, (xiz+10)                           ; FAD68D  ld XBC,(XIZ+0x0a)
	ld	a, (xbc+1)                              ; FAD690  ld A,(XBC+0x01)
	and	a, 0x80                                ; FAD693  and A,0x80
	jr z, sub_FAD688__FAD6C4                   ; FAD696  jr Z,0xfad6c4
	ld	hl, (xiz+8)                             ; FAD698  ld HL,(XIZ+0x08)
	extz	hl                                    ; FAD69B  extz HL
	ld	iy, hl                                  ; FAD69D  ld IY,HL
	sll	iy, 7                                  ; FAD69F  sll 0x07,IY
	ld	hl, iy                                  ; FAD6A2  ld HL,IY
	sub	iy, 0x2000                             ; FAD6A4  sub IY,0x2000
	ld	hl, iy                                  ; FAD6A8  ld HL,IY
	cp	iy, 0:i3                                  ; FAD6AA  cp IY,0
	jr le, sub_FAD688__FAD6B8                  ; FAD6AC  jr LE,0xfad6b8
	exts	xiy                                   ; FAD6AE  exts XIY
	divs	iy, 63                                ; FAD6B0  divs IY,0x003f
	ld	hl, iy                                  ; FAD6B4  ld HL,IY
	jr sub_FAD688__FAD6D8                      ; FAD6B6  jr T,0xfad6d8
sub_FAD688__FAD6B8:
	ld	bc, hl                                  ; FAD6B8  ld BC,HL
	exts	xbc                                   ; FAD6BA  exts XBC
	divs	bc, 64                                ; FAD6BC  divs BC,0x0040
	ld	hl, bc                                  ; FAD6C0  ld HL,BC
	jr sub_FAD688__FAD6D8                      ; FAD6C2  jr T,0xfad6d8
sub_FAD688__FAD6C4:
	ld	hl, (xiz+8)                             ; FAD6C4  ld HL,(XIZ+0x08)
	extz	hl                                    ; FAD6C7  extz HL
	ld	bc, hl                                  ; FAD6C9  ld BC,HL
	sll	bc, 7                                  ; FAD6CB  sll 0x07,BC
	ld	hl, bc                                  ; FAD6CE  ld HL,BC
	exts	xbc                                   ; FAD6D0  exts XBC
	divs	bc, 0x7F                              ; FAD6D2  divs BC,0x007f
	ld	hl, bc                                  ; FAD6D6  ld HL,BC
sub_FAD688__FAD6D8:
	ld	xbc, (xiz+10)                           ; FAD6D8  ld XBC,(XIZ+0x0a)
	ld	a, (xbc+2)                              ; FAD6DB  ld A,(XBC+0x02)
	extz	wa                                    ; FAD6DE  extz WA
	muls	xwa, xhl                              ; FAD6E0  muls XWA,HL
	ld	hl, wa                                  ; FAD6E2  ld HL,WA
	sra	wa, 6                                  ; FAD6E4  sra 0x06,WA
	popw	hl                                    ; FAD6E7  pop HL
	unlk32 xiz                                 ; FAD6E8  unlk XIZ
	ret                                        ; FAD6EA  ret
; --------------------------------------------------------------------------
; MidiCtrl_CC07 -- 0xFAD6EB..0xFAD763 (121 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAFE9E
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
;          reads 0x0014FF
; Evidence: the listing below is the byte-identical round-trip of 0xFAD6EB-0xFAD763
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7).  CONTROLLER 7 (MIDI channel volume).
; Inputs:  (XIZ+0x08) part index, (XIZ+0x0A) controller value 0..0x7F.
; Outputs: the WORD at part_record[+0x0B], where part_record = RAM 0x001523 + 0x12C*part.
;          value 0            -> 0xFE00
;          (0x0014FF) & 3 = 0 -> value - 0x7F          (a linear law)
;          otherwise          -> Voice_CC_VolumeCurve[value]   (0xFDF3F1, 128 u16)
; Evidence: `cp BC,7 / jrl Z` at 0xFAFDCA selects this handler; `add XBC,0x00FDF3F1` at
;          0xFAD710, `mul BC,0x012C / add BC,0x000B` at 0xFAD71C and `ld (XBC),DE` at
;          0xFAD728.  All four asserted by notes/prom_c_dev10c_meaning_checks.py section 2.
;          The curve is 0 at value 127 and -255 at value 0 and falls EXACTLY 32 counts per
;          halving of the value on every power of two (section 3), so the field is a
;          LOGARITHMIC ATTENUATION, 32 counts per 6.02 dB.
; ★ Where it goes: Voice_StageLevel_Reg0080 adds this field to part[+0x0E] (controller 11)
;          and stages the sum as 0x0010C000 register `chan + 0x0080`.
; --------------------------------------------------------------------------
MidiCtrl_CC07:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAD6EB  link XIZ,0x0000
	pushw	hl                                   ; FAD6EF  push HL
	pushw	de                                   ; FAD6F0  push DE
	push	xix                                   ; FAD6F1  push XIX
	lda	xix, (0x1523:16)                      ; FAD6F2  lda XIX,0x1523
	ld	l, (xiz+10)                             ; FAD6F6  ld L,(XIZ+0x0a)
	ld	h, (xiz+8)                              ; FAD6F9  ld H,(XIZ+0x08)
	cp	l, 0:i3                                   ; FAD6FC  cp L,0
	jr z, MidiCtrl_CC07__FAD74A                   ; FAD6FE  jr Z,0xfad74a
	ld	bc, (0x14FF:16)                       ; FAD700  ld BC,(0x14ff)
	and	bc, 3                                  ; FAD704  and BC,0x0003
	jr z, MidiCtrl_CC07__FAD72C                   ; FAD708  jr Z,0xfad72c
	ld	c, 2:opc                                   ; FAD70A  ld C,0x02
	mul8rr	c, l                                ; FAD70C  mul BC,L
	extz	xbc                                   ; FAD70E  extz XBC
	add	xbc, 0xFDF3F1                          ; FAD710  add XBC,0x00fdf3f1
	ld	de, (xbc)                               ; FAD716  ld DE,(XBC)
	ld	c, h                                    ; FAD718  ld C,H
	extz	bc                                    ; FAD71A  extz BC
	mul	bc, 0x12C                              ; FAD71C  mul BC,0x012c
	add	bc, 11                                 ; FAD720  add BC,0x000b
	extz	xbc                                   ; FAD724  extz XBC
	add	bc, ix                                 ; FAD726  add BC,IX
	ld	(xbc), de                               ; FAD728  ld (XBC),DE
	jr MidiCtrl_CC07__FAD75E                      ; FAD72A  jr T,0xfad75e
MidiCtrl_CC07__FAD72C:
	ld	c, l                                    ; FAD72C  ld C,L
	extz	bc                                    ; FAD72E  extz BC
	ld	de, bc                                  ; FAD730  ld DE,BC
	sub	de, 0x7F                               ; FAD732  sub DE,0x007f
	ld	c, h                                    ; FAD736  ld C,H
	extz	bc                                    ; FAD738  extz BC
	mul	bc, 0x12C                              ; FAD73A  mul BC,0x012c
	add	bc, 11                                 ; FAD73E  add BC,0x000b
	extz	xbc                                   ; FAD742  extz XBC
	add	bc, ix                                 ; FAD744  add BC,IX
	ld	(xbc), de                               ; FAD746  ld (XBC),DE
	jr MidiCtrl_CC07__FAD75E                      ; FAD748  jr T,0xfad75e
MidiCtrl_CC07__FAD74A:
	ld	c, h                                    ; FAD74A  ld C,H
	extz	bc                                    ; FAD74C  extz BC
	mul	bc, 0x12C                              ; FAD74E  mul BC,0x012c
	add	bc, 11                                 ; FAD752  add BC,0x000b
	extz	xbc                                   ; FAD756  extz XBC
	add	bc, ix                                 ; FAD758  add BC,IX
	extpfx4 0xB1, 0x02, 0x00, 0xFE             ; FAD75A  ld (XBC),0xfe00
MidiCtrl_CC07__FAD75E:
	pop	xix                                    ; FAD75E  pop XIX
	popw	de                                    ; FAD75F  pop DE
	popw	hl                                    ; FAD760  pop HL
	unlk32 xiz                                 ; FAD761  unlk XIZ
	ret                                        ; FAD763  ret
; --------------------------------------------------------------------------
; MidiCtrl_CC10 -- 0xFAD764..0xFAD781 (30 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAFEAB
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFAD764-0xFAD781
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7).  CONTROLLER 10.  The MIDI standard assigns 10 to PAN; nothing in this
;          image says so, and the name states only the number.
; Outputs: the raw controller value, ONE BYTE, at part_record[+0x0D].  No curve.
; Evidence: `cp BC,0x000A / jrl Z` at 0xFAFDCF; `mul BC,0x012C / add BC,0x000D` at 0xFAD76D;
;          `ld (XBC+0x1523),A` at 0xFAD77A.  notes/prom_c_dev10c_meaning_checks.py section 2.
; ★ This routine is 30 bytes and is byte-identical to MidiCtrl_CC91, MidiCtrl_CC93,
;          MidiCtrl_Int97, MidiCtrl_Int9B and MidiCtrl_Int9C EXCEPT for the one immediate
;          byte that names the part-record offset (0x0D, 0x10, 0x11, 0x16, 0x19, 0x1A).
; --------------------------------------------------------------------------
MidiCtrl_CC10:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAD764  link XIZ,0x0000
	ld	bc, (xiz+8)                             ; FAD768  ld BC,(XIZ+0x08)
	extz	bc                                    ; FAD76B  extz BC
	mul	bc, 0x12C                              ; FAD76D  mul BC,0x012c
	add	bc, 13                                 ; FAD771  add BC,0x000d
	extz	xbc                                   ; FAD775  extz XBC
	ld	a, (xiz+10)                             ; FAD777  ld A,(XIZ+0x0a)
	ld	(xbc+0x1523), a                         ; FAD77A  ld (XBC+0x1523),A
	unlk32 xiz                                 ; FAD77F  unlk XIZ
	ret                                        ; FAD781  ret
; --------------------------------------------------------------------------
; MidiCtrl_CC11 -- 0xFAD782..0xFAD7FA (121 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAFEC0
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
;          reads 0x0014FF
; Evidence: the listing below is the byte-identical round-trip of 0xFAD782-0xFAD7FA
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7).  CONTROLLER 11 (MIDI expression).
; Outputs: the WORD at part_record[+0x0E], by the identical law MidiCtrl_CC07 uses for
;          +0x0B -- the two handlers share the curve address byte for byte (notes/prom_c_dev10c_meaning_checks.py
;          section 2 compares the six bytes at 0xFAD710 and 0xFAD7A7).
; Evidence: `cp BC,0x000B / jrl Z` at 0xFAFDD6; `mul BC,0x012C / add BC,0x000E` at
;          0xFAD7B3; `ld (XBC),DE` at 0xFAD7BF.
; --------------------------------------------------------------------------
MidiCtrl_CC11:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAD782  link XIZ,0x0000
	pushw	hl                                   ; FAD786  push HL
	pushw	de                                   ; FAD787  push DE
	push	xix                                   ; FAD788  push XIX
	lda	xix, (0x1523:16)                      ; FAD789  lda XIX,0x1523
	ld	l, (xiz+10)                             ; FAD78D  ld L,(XIZ+0x0a)
	ld	h, (xiz+8)                              ; FAD790  ld H,(XIZ+0x08)
	cp	l, 0:i3                                   ; FAD793  cp L,0
	jr z, MidiCtrl_CC11__FAD7E1                   ; FAD795  jr Z,0xfad7e1
	ld	bc, (0x14FF:16)                       ; FAD797  ld BC,(0x14ff)
	and	bc, 3                                  ; FAD79B  and BC,0x0003
	jr z, MidiCtrl_CC11__FAD7C3                   ; FAD79F  jr Z,0xfad7c3
	ld	c, 2:opc                                   ; FAD7A1  ld C,0x02
	mul8rr	c, l                                ; FAD7A3  mul BC,L
	extz	xbc                                   ; FAD7A5  extz XBC
	add	xbc, 0xFDF3F1                          ; FAD7A7  add XBC,0x00fdf3f1
	ld	de, (xbc)                               ; FAD7AD  ld DE,(XBC)
	ld	c, h                                    ; FAD7AF  ld C,H
	extz	bc                                    ; FAD7B1  extz BC
	mul	bc, 0x12C                              ; FAD7B3  mul BC,0x012c
	add	bc, 14                                 ; FAD7B7  add BC,0x000e
	extz	xbc                                   ; FAD7BB  extz XBC
	add	bc, ix                                 ; FAD7BD  add BC,IX
	ld	(xbc), de                               ; FAD7BF  ld (XBC),DE
	jr MidiCtrl_CC11__FAD7F5                      ; FAD7C1  jr T,0xfad7f5
MidiCtrl_CC11__FAD7C3:
	ld	c, l                                    ; FAD7C3  ld C,L
	extz	bc                                    ; FAD7C5  extz BC
	ld	de, bc                                  ; FAD7C7  ld DE,BC
	sub	de, 0x7F                               ; FAD7C9  sub DE,0x007f
	ld	c, h                                    ; FAD7CD  ld C,H
	extz	bc                                    ; FAD7CF  extz BC
	mul	bc, 0x12C                              ; FAD7D1  mul BC,0x012c
	add	bc, 14                                 ; FAD7D5  add BC,0x000e
	extz	xbc                                   ; FAD7D9  extz XBC
	add	bc, ix                                 ; FAD7DB  add BC,IX
	ld	(xbc), de                               ; FAD7DD  ld (XBC),DE
	jr MidiCtrl_CC11__FAD7F5                      ; FAD7DF  jr T,0xfad7f5
MidiCtrl_CC11__FAD7E1:
	ld	c, h                                    ; FAD7E1  ld C,H
	extz	bc                                    ; FAD7E3  extz BC
	mul	bc, 0x12C                              ; FAD7E5  mul BC,0x012c
	add	bc, 14                                 ; FAD7E9  add BC,0x000e
	extz	xbc                                   ; FAD7ED  extz XBC
	add	bc, ix                                 ; FAD7EF  add BC,IX
	extpfx4 0xB1, 0x02, 0x00, 0xFE             ; FAD7F1  ld (XBC),0xfe00
MidiCtrl_CC11__FAD7F5:
	pop	xix                                    ; FAD7F5  pop XIX
	popw	de                                    ; FAD7F6  pop DE
	popw	hl                                    ; FAD7F7  pop HL
	unlk32 xiz                                 ; FAD7F8  unlk XIZ
	ret                                        ; FAD7FA  ret
; --------------------------------------------------------------------------
; MidiCtrl_CC64 -- 0xFAD7FB..0xFAD843 (73 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAFF15
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFAD7FB-0xFAD843
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7).  CONTROLLER 64.  The MIDI standard assigns 64 to the SUSTAIN (damper)
;          pedal, and this handler treats the value as a SWITCH WITH THE STANDARD THRESHOLD:
;              value >= 0x40  ->  set bit 0 of the word at part_record[+0x09]
;              value <  0x40  ->  clear it
;          The threshold 64 is the MIDI specification's own on/off point for a switch
;          controller, and it is here as an immediate.
; Evidence: `cp BC,0x0040 / jrl Z` at 0xFAFDF9 selects this arm; `mul BC,0x012C / ld HL,BC /
;          add BC,0x0009` at 0xFAD80B; `cp (XIZ+0x0A),0x40` at 0xFAD81E; `set 0x00,WA` at
;          0xFAD826 and `res 0x00,BC` at 0xFAD833.  notes/prom_c_dev10c_meaning_checks.py section 14.
; Unknown:  what else reads part[+0x09] bit 0.
; --------------------------------------------------------------------------
MidiCtrl_CC64:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAD7FB  link XIZ,0x0000
	pushw	hl                                   ; FAD7FF  push HL
	pushw	de                                   ; FAD800  push DE
	push	xix                                   ; FAD801  push XIX
	lda	xix, (0x1523:16)                      ; FAD802  lda XIX,0x1523
	ld	bc, (xiz+8)                             ; FAD806  ld BC,(XIZ+0x08)
	extz	bc                                    ; FAD809  extz BC
	mul	bc, 0x12C                              ; FAD80B  mul BC,0x012c
	ld	hl, bc                                  ; FAD80F  ld HL,BC
	add	bc, 9                                  ; FAD811  add BC,0x0009
	ld	hl, bc                                  ; FAD815  ld HL,BC
	extz	xix                                   ; FAD817  extz XIX
	extpfx5 0xD3, 0x07, 0xF0, 0xE4, 0x22       ; FAD819  ld DE,(XIX+BC)
	cp (xiz+10), 0x40                          ; FAD81E  cp (XIZ+0x0a),0x40
	jr c, MidiCtrl_CC64__FAD831                   ; FAD822  jr C,0xfad831
	ld	wa, de                                  ; FAD824  ld WA,DE
	set	0, wa                                  ; FAD826  set 0x00,WA
	extz	xbc                                   ; FAD829  extz XBC
	add	bc, ix                                 ; FAD82B  add BC,IX
	ld	(xbc), wa                               ; FAD82D  ld (XBC),WA
	jr MidiCtrl_CC64__FAD83E                      ; FAD82F  jr T,0xfad83e
MidiCtrl_CC64__FAD831:
	ld	bc, de                                  ; FAD831  ld BC,DE
	res	0, bc                                  ; FAD833  res 0x00,BC
	ld	wa, ix                                  ; FAD836  ld WA,IX
	extz	xwa                                   ; FAD838  extz XWA
	add	wa, hl                                 ; FAD83A  add WA,HL
	ld	(xwa), bc                               ; FAD83C  ld (XWA),BC
MidiCtrl_CC64__FAD83E:
	pop	xix                                    ; FAD83E  pop XIX
	popw	de                                    ; FAD83F  pop DE
	popw	hl                                    ; FAD840  pop HL
	unlk32 xiz                                 ; FAD841  unlk XIZ
	ret                                        ; FAD843  ret
; --------------------------------------------------------------------------
; MidiCtrl_CC91 -- 0xFAD844..0xFAD861 (30 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAFF38
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFAD844-0xFAD861
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7).  CONTROLLER 91.  The MIDI standard assigns 91 to effect-1 (reverb)
;          depth; not established here.  Writes the raw value as a byte to part[+0x10].
; Evidence: `cp BC,0x005B / jrl Z` at 0xFAFE00; `mul BC,0x012C` at 0xFAD84D and
;          `add BC,0x0010` at 0xFAD851.  ⚠ CORRECTED 2026-08-25 (round-1 audit F6): this
;          line used to cite 0xFAD850, which is the first IMMEDIATE BYTE of the `mul`,
;          not an instruction start.  `python3 notes/prom_c_prose_citation_check.py`
;          now checks every citation of this shape in prom_c and prom_d.
; --------------------------------------------------------------------------
MidiCtrl_CC91:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAD844  link XIZ,0x0000
	ld	bc, (xiz+8)                             ; FAD848  ld BC,(XIZ+0x08)
	extz	bc                                    ; FAD84B  extz BC
	mul	bc, 0x12C                              ; FAD84D  mul BC,0x012c
	add	bc, 16                                 ; FAD851  add BC,0x0010
	extz	xbc                                   ; FAD855  extz XBC
	ld	a, (xiz+10)                             ; FAD857  ld A,(XIZ+0x0a)
	ld	(xbc+0x1523), a                         ; FAD85A  ld (XBC+0x1523),A
	unlk32 xiz                                 ; FAD85F  unlk XIZ
	ret                                        ; FAD861  ret
; --------------------------------------------------------------------------
; MidiCtrl_CC93 -- 0xFAD862..0xFAD87F (30 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAFF46
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFAD862-0xFAD87F
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7).  CONTROLLER 93.  The MIDI standard assigns 93 to effect-3 (chorus)
;          depth; not established here.  Writes the raw value as a byte to part[+0x11].
; Evidence: `cp BC,0x005D / jrl Z` at 0xFAFE07; `mul BC,0x012C` at 0xFAD86B and
;          `add BC,0x0011` at 0xFAD86F.  ⚠ CORRECTED 2026-08-25 (round-1 audit F6):
;          this line used to cite 0xFAD86E, three bytes into the `mul`.
; --------------------------------------------------------------------------
MidiCtrl_CC93:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAD862  link XIZ,0x0000
	ld	bc, (xiz+8)                             ; FAD866  ld BC,(XIZ+0x08)
	extz	bc                                    ; FAD869  extz BC
	mul	bc, 0x12C                              ; FAD86B  mul BC,0x012c
	add	bc, 17                                 ; FAD86F  add BC,0x0011
	extz	xbc                                   ; FAD873  extz XBC
	ld	a, (xiz+10)                             ; FAD875  ld A,(XIZ+0x0a)
	ld	(xbc+0x1523), a                         ; FAD878  ld (XBC+0x1523),A
	unlk32 xiz                                 ; FAD87D  unlk XIZ
	ret                                        ; FAD87F  ret
; --------------------------------------------------------------------------
; PartRec_Flags09_Bit14_SetOrClear -- 0xFAD880..0xFAD8C8 (73 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAFC2E
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFAD880-0xFAD8C8
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7 finish pass).  SETS OR CLEARS BIT 14 of the part record's flag word
;          at +0x09.  `lda XIX,0x1523` at 0xFAD887 and `mul BC,0x012C` at 0xFAD890 form
;          the part-record base (RAM 0x001523, stride 0x012C, 33 parts -- see
;          notes/FINDINGS-prom_c-dev10c-register-meanings.md); `add BC,0x0009` at
;          0xFAD896 selects the word.  `cp (XIZ+0x0A),0x00` at 0xFAD8A3 branches on the
;          argument: non-zero takes `set 0x0e,WA` at 0xFAD8AB, zero takes
;          `res 0x0e,BC` at 0xFAD8B8.  Both write the word back.
;          73 bytes, 2 of which differ from MidiCtrl_Int95 at 0xFAD987 -- and both are
;          the BIT NUMBER, 0x0E here against 0x02 there (0xFAD8AD/0xFAD9B4 and
;          0xFAD8BA/0xFAD9C1).  So the two are one routine with one operand changed;
;          MidiCtrl_Int95 is the SAME set-or-clear on bit 2 of the same word.
; Unknown:  what bit 14 of that word MEANS.  The name states the operation and the
;          field, which are operands, and claims nothing else.
; --------------------------------------------------------------------------
PartRec_Flags09_Bit14_SetOrClear:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAD880  link XIZ,0x0000
	pushw	hl                                   ; FAD884  push HL
	pushw	de                                   ; FAD885  push DE
	push	xix                                   ; FAD886  push XIX
	lda	xix, (0x1523:16)                      ; FAD887  lda XIX,0x1523
	ld	bc, (xiz+8)                             ; FAD88B  ld BC,(XIZ+0x08)
	extz	bc                                    ; FAD88E  extz BC
	mul	bc, 0x12C                              ; FAD890  mul BC,0x012c
	ld	hl, bc                                  ; FAD894  ld HL,BC
	add	bc, 9                                  ; FAD896  add BC,0x0009
	ld	hl, bc                                  ; FAD89A  ld HL,BC
	extz	xix                                   ; FAD89C  extz XIX
	extpfx5 0xD3, 0x07, 0xF0, 0xE4, 0x22       ; FAD89E  ld DE,(XIX+BC)
	cp (xiz+10), 0x00                          ; FAD8A3  cp (XIZ+0x0a),0x00
	jr z, sub_FAD880__FAD8B6                   ; FAD8A7  jr Z,0xfad8b6
	ld	wa, de                                  ; FAD8A9  ld WA,DE
	set	14, wa                                 ; FAD8AB  set 0x0e,WA
	extz	xbc                                   ; FAD8AE  extz XBC
	add	bc, ix                                 ; FAD8B0  add BC,IX
	ld	(xbc), wa                               ; FAD8B2  ld (XBC),WA
	jr sub_FAD880__FAD8C3                      ; FAD8B4  jr T,0xfad8c3
sub_FAD880__FAD8B6:
	ld	bc, de                                  ; FAD8B6  ld BC,DE
	res	14, bc                                 ; FAD8B8  res 0x0e,BC
	ld	wa, ix                                  ; FAD8BB  ld WA,IX
	extz	xwa                                   ; FAD8BD  extz XWA
	add	wa, hl                                 ; FAD8BF  add WA,HL
	ld	(xwa), bc                               ; FAD8C1  ld (XWA),BC
sub_FAD880__FAD8C3:
	pop	xix                                    ; FAD8C3  pop XIX
	popw	de                                    ; FAD8C4  pop DE
	popw	hl                                    ; FAD8C5  pop HL
	unlk32 xiz                                 ; FAD8C6  unlk XIZ
	ret                                        ; FAD8C8  ret
; --------------------------------------------------------------------------
; MidiCtrl_Int80 -- 0xFAD8C9..0xFAD8F0 (40 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAFF91
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Calls:   0xFC81F8 = sub_FC81F8
; Evidence: the listing below is the byte-identical round-trip of 0xFAD8C9-0xFAD8F0
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7).  INTERNAL controller 0x80 -- ABOVE 0x7F, so it cannot be a MIDI
;          controller number at all; it is this firmware's own extension of the
;          controller message.  `cp BC,0x80 / jrl Z` at 0xFAFE2A.
; Outputs: part_record[+0x12 (byte)] = the raw controller value.
;          Extracted with the other 25 arms by `python3 notes/prom_c_dev10c_meaning_checks.py`
;          section 1.
; Unknown:  what the field is FOR.
; --------------------------------------------------------------------------
MidiCtrl_Int80:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAD8C9  link XIZ,0x0000
	ld	bc, (xiz+8)                             ; FAD8CD  ld BC,(XIZ+0x08)
	extz	bc                                    ; FAD8D0  extz BC
	mul	bc, 0x12C                              ; FAD8D2  mul BC,0x012c
	add	bc, 18                                 ; FAD8D6  add BC,0x0012
	extz	xbc                                   ; FAD8DA  extz XBC
	ld	a, (xiz+10)                             ; FAD8DC  ld A,(XIZ+0x0a)
	ld	(xbc+0x1523), a                         ; FAD8DF  ld (XBC+0x1523),A
	push	0                                     ; FAD8E4  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAD8E6  push (XIZ+0x08)
	call	sub_FC81F8                              ; FAD8E9  call 0xfc81f8
	popw	bc                                    ; FAD8ED  pop BC
	unlk32 xiz                                 ; FAD8EE  unlk XIZ
	ret                                        ; FAD8F0  ret
; --------------------------------------------------------------------------
; MidiCtrl_Int81_FineTune -- 0xFAD8F1..0xFAD91A (42 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAFF9F
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFAD8F1-0xFAD91A
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7).  INTERNAL controller 0x81 -- not a MIDI controller number.
; Outputs: part_record[+0x13] = (value - 0x0080) * 2, a WORD.
; Evidence: `cp BC,0x0081 / jrl Z` at 0xFAFE31; the arithmetic at 0xFAD8F6-0xFAD901; the
;          store `ld (XBC+0x1523),HL` at 0xFAD912 with `add BC,0x0013` at 0xFAD90C.
; ★ WHY "FineTune".  Voice_ComputePitch adds part[+0x13] straight into the pitch
;          accumulator (`ld WA,(XHL+0x13) / add HL,WA` at 0xFA7F68), and that accumulator is
;          the note number times 256 (0xFA7F3F).  So one count is 1/256 of a semitone and
;          this control's full range, +/-0x100, is exactly +/-ONE SEMITONE.
; --------------------------------------------------------------------------
MidiCtrl_Int81_FineTune:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAD8F1  link XIZ,0x0000
	pushw	hl                                   ; FAD8F5  push HL
	ld	bc, (xiz+10)                            ; FAD8F6  ld BC,(XIZ+0x0a)
	extz	bc                                    ; FAD8F9  extz BC
	sub	bc, 0x80                               ; FAD8FB  sub BC,0x0080
	ld	hl, bc                                  ; FAD8FF  ld HL,BC
	add	hl, hl                                 ; FAD901  add HL,HL
	ld	bc, (xiz+8)                             ; FAD903  ld BC,(XIZ+0x08)
	extz	bc                                    ; FAD906  extz BC
	mul	bc, 0x12C                              ; FAD908  mul BC,0x012c
	add	bc, 19                                 ; FAD90C  add BC,0x0013
	extz	xbc                                   ; FAD910  extz XBC
	ld	(xbc+0x1523), hl                        ; FAD912  ld (XBC+0x1523),HL
	popw	hl                                    ; FAD917  pop HL
	unlk32 xiz                                 ; FAD918  unlk XIZ
	ret                                        ; FAD91A  ret
; --------------------------------------------------------------------------
; MidiCtrl_Int82_Transpose -- 0xFAD91B..0xFAD93D (35 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAFFBD
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFAD91B-0xFAD93D
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7).  INTERNAL controller 0x82 -- not a MIDI controller number.
; Outputs: part_record[+0x15] = value - 0x40, a signed BYTE.
; Evidence: `cp BC,0x0082 / jrl Z` at 0xFAFE38; `sub H,0x40` at 0xFAD923; `add BC,0x0015` at
;          0xFAD92F; `ld (XBC+0x1523),H` at 0xFAD935.
; ★ WHY "Transpose".  Voice_ComputePitch reads the same field SIGN-EXTENDED AND SHIFTED
;          LEFT EIGHT (`ld C,(XHL+0x15) / exts BC / sll 0x08,BC` at 0xFA7F5A) before adding
;          it to the pitch accumulator, so one count is one SEMITONE and the range is
;          +/-64 semitones.
; --------------------------------------------------------------------------
MidiCtrl_Int82_Transpose:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAD91B  link XIZ,0x0000
	pushw	hl                                   ; FAD91F  push HL
	ld	h, (xiz+10)                             ; FAD920  ld H,(XIZ+0x0a)
	sub	h, 64                                  ; FAD923  sub H,0x40
	ld	bc, (xiz+8)                             ; FAD926  ld BC,(XIZ+0x08)
	extz	bc                                    ; FAD929  extz BC
	mul	bc, 0x12C                              ; FAD92B  mul BC,0x012c
	add	bc, 21                                 ; FAD92F  add BC,0x0015
	extz	xbc                                   ; FAD933  extz XBC
	ld	(xbc+0x1523), h                         ; FAD935  ld (XBC+0x1523),H
	popw	hl                                    ; FAD93A  pop HL
	unlk32 xiz                                 ; FAD93B  unlk XIZ
	ret                                        ; FAD93D  ret
; --------------------------------------------------------------------------
; PartRec_Flags09_Bit1_SetOrClear -- 0xFAD93E..0xFAD986 (73 bytes)
;
; Called from: no site outside this module.
;          ⚠ NOT FOUND -- no literal call/calr/jp reaches this address anywhere
;          in the image.  A register-indirect call would be invisible to that
;          scan, so this is "not found", not "dead".
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFAD93E-0xFAD986
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7 finish pass).  SETS OR CLEARS BIT 1 of the part record's flag word
;          at +0x09 -- the same routine as PartRec_Flags09_Bit14_SetOrClear and
;          MidiCtrl_Int95 with one operand changed.  `lda XIX,0x1523` at 0xFAD945,
;          `mul BC,0x012C` at 0xFAD94E, `add BC,0x0009` at 0xFAD954; `set 0x01,WA` at
;          0xFAD969 on the non-zero arm and `res 0x01,BC` at 0xFAD976 on the zero arm.
;          73 bytes, 2 differing from MidiCtrl_Int95 at 0xFAD987, both the bit number
;          (0xFAD96B and 0xFAD978 hold 01 where 0xFAD9B4/0xFAD9C1 hold 02).
; Called from: NOT FOUND -- no literal call/calr/jp and no 24- or 32-bit pointer
;          anywhere in the 512 KiB image reaches 0xFAD93E
;          (notes/prom_c_finish_round7.py --noref).  A register-indirect call would be
;          invisible to that census, so this is "not found", not "dead".
; Unknown:  what bit 1 of that word MEANS.
; --------------------------------------------------------------------------
PartRec_Flags09_Bit1_SetOrClear:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAD93E  link XIZ,0x0000
	pushw	hl                                   ; FAD942  push HL
	pushw	de                                   ; FAD943  push DE
	push	xix                                   ; FAD944  push XIX
	lda	xix, (0x1523:16)                      ; FAD945  lda XIX,0x1523
	ld	bc, (xiz+8)                             ; FAD949  ld BC,(XIZ+0x08)
	extz	bc                                    ; FAD94C  extz BC
	mul	bc, 0x12C                              ; FAD94E  mul BC,0x012c
	ld	hl, bc                                  ; FAD952  ld HL,BC
	add	bc, 9                                  ; FAD954  add BC,0x0009
	ld	hl, bc                                  ; FAD958  ld HL,BC
	extz	xix                                   ; FAD95A  extz XIX
	extpfx5 0xD3, 0x07, 0xF0, 0xE4, 0x22       ; FAD95C  ld DE,(XIX+BC)
	cp (xiz+10), 0x00                          ; FAD961  cp (XIZ+0x0a),0x00
	jr z, sub_FAD93E__FAD974                   ; FAD965  jr Z,0xfad974
	ld	wa, de                                  ; FAD967  ld WA,DE
	set	1, wa                                  ; FAD969  set 0x01,WA
	extz	xbc                                   ; FAD96C  extz XBC
	add	bc, ix                                 ; FAD96E  add BC,IX
	ld	(xbc), wa                               ; FAD970  ld (XBC),WA
	jr sub_FAD93E__FAD981                      ; FAD972  jr T,0xfad981
sub_FAD93E__FAD974:
	ld	bc, de                                  ; FAD974  ld BC,DE
	res	1, bc                                  ; FAD976  res 0x01,BC
	ld	wa, ix                                  ; FAD979  ld WA,IX
	extz	xwa                                   ; FAD97B  extz XWA
	add	wa, hl                                 ; FAD97D  add WA,HL
	ld	(xwa), bc                               ; FAD97F  ld (XWA),BC
sub_FAD93E__FAD981:
	pop	xix                                    ; FAD981  pop XIX
	popw	de                                    ; FAD982  pop DE
	popw	hl                                    ; FAD983  pop HL
	unlk32 xiz                                 ; FAD984  unlk XIZ
	ret                                        ; FAD986  ret
; --------------------------------------------------------------------------
; MidiCtrl_Int95 -- 0xFAD987..0xFAD9CF (73 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAFFCA
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFAD987-0xFAD9CF
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7).  INTERNAL controller 0x95 -- ABOVE 0x7F, so it cannot be a MIDI
;          controller number at all; it is this firmware's own extension of the
;          controller message.  `cp BC,0x95 / jrl Z` at 0xFAFE3F.
;          Extracted with the other 25 arms by `python3 notes/prom_c_dev10c_meaning_checks.py`
;          section 1.
; Unknown:  what the field is FOR.
; --------------------------------------------------------------------------
MidiCtrl_Int95:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAD987  link XIZ,0x0000
	pushw	hl                                   ; FAD98B  push HL
	pushw	de                                   ; FAD98C  push DE
	push	xix                                   ; FAD98D  push XIX
	lda	xix, (0x1523:16)                      ; FAD98E  lda XIX,0x1523
	ld	bc, (xiz+8)                             ; FAD992  ld BC,(XIZ+0x08)
	extz	bc                                    ; FAD995  extz BC
	mul	bc, 0x12C                              ; FAD997  mul BC,0x012c
	ld	hl, bc                                  ; FAD99B  ld HL,BC
	add	bc, 9                                  ; FAD99D  add BC,0x0009
	ld	hl, bc                                  ; FAD9A1  ld HL,BC
	extz	xix                                   ; FAD9A3  extz XIX
	extpfx5 0xD3, 0x07, 0xF0, 0xE4, 0x22       ; FAD9A5  ld DE,(XIX+BC)
	cp (xiz+10), 0x00                          ; FAD9AA  cp (XIZ+0x0a),0x00
	jr z, MidiCtrl_Int95__FAD9BD                   ; FAD9AE  jr Z,0xfad9bd
	ld	wa, de                                  ; FAD9B0  ld WA,DE
	set	2, wa                                  ; FAD9B2  set 0x02,WA
	extz	xbc                                   ; FAD9B5  extz XBC
	add	bc, ix                                 ; FAD9B7  add BC,IX
	ld	(xbc), wa                               ; FAD9B9  ld (XBC),WA
	jr MidiCtrl_Int95__FAD9CA                      ; FAD9BB  jr T,0xfad9ca
MidiCtrl_Int95__FAD9BD:
	ld	bc, de                                  ; FAD9BD  ld BC,DE
	res	2, bc                                  ; FAD9BF  res 0x02,BC
	ld	wa, ix                                  ; FAD9C2  ld WA,IX
	extz	xwa                                   ; FAD9C4  extz XWA
	add	wa, hl                                 ; FAD9C6  add WA,HL
	ld	(xwa), bc                               ; FAD9C8  ld (XWA),BC
MidiCtrl_Int95__FAD9CA:
	pop	xix                                    ; FAD9CA  pop XIX
	popw	de                                    ; FAD9CB  pop DE
	popw	hl                                    ; FAD9CC  pop HL
	unlk32 xiz                                 ; FAD9CD  unlk XIZ
	ret                                        ; FAD9CF  ret
; --------------------------------------------------------------------------
; MidiCtrl_Int97 -- 0xFAD9D0..0xFAD9ED (30 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAFFD7
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFAD9D0-0xFAD9ED
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7).  INTERNAL controller 0x97 -- ABOVE 0x7F, so it cannot be a MIDI
;          controller number at all; it is this firmware's own extension of the
;          controller message.  `cp BC,0x97 / jrl Z` at 0xFAFE46.
; Outputs: part_record[+0x16 (byte)] = the raw controller value.
;          Extracted with the other 25 arms by `python3 notes/prom_c_dev10c_meaning_checks.py`
;          section 1.
; Unknown:  what the field is FOR.
; --------------------------------------------------------------------------
MidiCtrl_Int97:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAD9D0  link XIZ,0x0000
	ld	bc, (xiz+8)                             ; FAD9D4  ld BC,(XIZ+0x08)
	extz	bc                                    ; FAD9D7  extz BC
	mul	bc, 0x12C                              ; FAD9D9  mul BC,0x012c
	add	bc, 22                                 ; FAD9DD  add BC,0x0016
	extz	xbc                                   ; FAD9E1  extz XBC
	ld	a, (xiz+10)                             ; FAD9E3  ld A,(XIZ+0x0a)
	ld	(xbc+0x1523), a                         ; FAD9E6  ld (XBC+0x1523),A
	unlk32 xiz                                 ; FAD9EB  unlk XIZ
	ret                                        ; FAD9ED  ret
; --------------------------------------------------------------------------
; MidiCtrl_Int99 -- 0xFAD9EE..0xFADA16 (41 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAFFE4
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Calls:   0xFC280D = MidiCtrl_Int99_ApplyToSelectedPart
; Evidence: the listing below is the byte-identical round-trip of 0xFAD9EE-0xFADA16
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7).  INTERNAL controller 0x99 -- ABOVE 0x7F, so it cannot be a MIDI
;          controller number at all; it is this firmware's own extension of the
;          controller message.  `cp BC,0x99 / jrl Z` at 0xFAFE4D.
; Outputs: part_record[+0x17 (byte)] = the raw controller value.
;          Extracted with the other 25 arms by `python3 notes/prom_c_dev10c_meaning_checks.py`
;          section 1.
; Unknown:  what the field is FOR.
; --------------------------------------------------------------------------
MidiCtrl_Int99:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAD9EE  link XIZ,0x0000
	ld	bc, (xiz+8)                             ; FAD9F2  ld BC,(XIZ+0x08)
	extz	bc                                    ; FAD9F5  extz BC
	mul	bc, 0x12C                              ; FAD9F7  mul BC,0x012c
	add	bc, 23                                 ; FAD9FB  add BC,0x0017
	extz	xbc                                   ; FAD9FF  extz XBC
	ld	a, (xiz+10)                             ; FADA01  ld A,(XIZ+0x0a)
	ld	(xbc+0x1523), a                         ; FADA04  ld (XBC+0x1523),A
	pushw	wa                                   ; FADA09  push WA
	push	0                                     ; FADA0A  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FADA0C  push (XIZ+0x08)
	call	MidiCtrl_Int99_ApplyToSelectedPart                              ; FADA0F  call 0xfc280d
	pop	xbc                                    ; FADA13  pop XBC
	unlk32 xiz                                 ; FADA14  unlk XIZ
	ret                                        ; FADA16  ret
; --------------------------------------------------------------------------
; MidiCtrl_Int9A -- 0xFADA17..0xFADA3F (41 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAFFF1
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Calls:   0xFC2861 = MidiCtrl_Int9A_ApplyToSelectedPart
; Evidence: the listing below is the byte-identical round-trip of 0xFADA17-0xFADA3F
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7).  INTERNAL controller 0x9A -- ABOVE 0x7F, so it cannot be a MIDI
;          controller number at all; it is this firmware's own extension of the
;          controller message.  `cp BC,0x9A / jrl Z` at 0xFAFE54.
; Outputs: part_record[+0x18 (byte)] = the raw controller value.
;          Extracted with the other 25 arms by `python3 notes/prom_c_dev10c_meaning_checks.py`
;          section 1.
; Unknown:  what the field is FOR.
; --------------------------------------------------------------------------
MidiCtrl_Int9A:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FADA17  link XIZ,0x0000
	ld	bc, (xiz+8)                             ; FADA1B  ld BC,(XIZ+0x08)
	extz	bc                                    ; FADA1E  extz BC
	mul	bc, 0x12C                              ; FADA20  mul BC,0x012c
	add	bc, 24                                 ; FADA24  add BC,0x0018
	extz	xbc                                   ; FADA28  extz XBC
	ld	a, (xiz+10)                             ; FADA2A  ld A,(XIZ+0x0a)
	ld	(xbc+0x1523), a                         ; FADA2D  ld (XBC+0x1523),A
	pushw	wa                                   ; FADA32  push WA
	push	0                                     ; FADA33  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FADA35  push (XIZ+0x08)
	call	MidiCtrl_Int9A_ApplyToSelectedPart                              ; FADA38  call 0xfc2861
	pop	xbc                                    ; FADA3C  pop XBC
	unlk32 xiz                                 ; FADA3D  unlk XIZ
	ret                                        ; FADA3F  ret
; --------------------------------------------------------------------------
; MidiCtrl_Int9B -- 0xFADA40..0xFADA5D (30 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAFFFE
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFADA40-0xFADA5D
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7).  INTERNAL controller 0x9B -- ABOVE 0x7F, so it cannot be a MIDI
;          controller number at all; it is this firmware's own extension of the
;          controller message.  `cp BC,0x9B / jrl Z` at 0xFAFE5B.
; Outputs: part_record[+0x19 (byte)] = the raw controller value.
;          Extracted with the other 25 arms by `python3 notes/prom_c_dev10c_meaning_checks.py`
;          section 1.
; Unknown:  what the field is FOR.
; --------------------------------------------------------------------------
MidiCtrl_Int9B:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FADA40  link XIZ,0x0000
	ld	bc, (xiz+8)                             ; FADA44  ld BC,(XIZ+0x08)
	extz	bc                                    ; FADA47  extz BC
	mul	bc, 0x12C                              ; FADA49  mul BC,0x012c
	add	bc, 25                                 ; FADA4D  add BC,0x0019
	extz	xbc                                   ; FADA51  extz XBC
	ld	a, (xiz+10)                             ; FADA53  ld A,(XIZ+0x0a)
	ld	(xbc+0x1523), a                         ; FADA56  ld (XBC+0x1523),A
	unlk32 xiz                                 ; FADA5B  unlk XIZ
	ret                                        ; FADA5D  ret
; --------------------------------------------------------------------------
; MidiCtrl_Int9C -- 0xFADA5E..0xFADA7B (30 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFB000B
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFADA5E-0xFADA7B
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7).  INTERNAL controller 0x9C -- ABOVE 0x7F, so it cannot be a MIDI
;          controller number at all; it is this firmware's own extension of the
;          controller message.  `cp BC,0x9C / jrl Z` at 0xFAFE62.
; Outputs: part_record[+0x1A (byte)] = the raw controller value.
;          Extracted with the other 25 arms by `python3 notes/prom_c_dev10c_meaning_checks.py`
;          section 1.
; Unknown:  what the field is FOR.
; --------------------------------------------------------------------------
MidiCtrl_Int9C:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FADA5E  link XIZ,0x0000
	ld	bc, (xiz+8)                             ; FADA62  ld BC,(XIZ+0x08)
	extz	bc                                    ; FADA65  extz BC
	mul	bc, 0x12C                              ; FADA67  mul BC,0x012c
	add	bc, 26                                 ; FADA6B  add BC,0x001a
	extz	xbc                                   ; FADA6F  extz XBC
	ld	a, (xiz+10)                             ; FADA71  ld A,(XIZ+0x0a)
	ld	(xbc+0x1523), a                         ; FADA74  ld (XBC+0x1523),A
	unlk32 xiz                                 ; FADA79  unlk XIZ
	ret                                        ; FADA7B  ret

; ==============================================================================
; ** THE GLOBAL SETUP RECORD -- RAM 0x0014FE..0x001522, 37 bytes
; ==============================================================================
;
; The instrument's part-less settings, read by the voice engine on every note.  It
; ends where the part records begin, at 0x001523 (their base and 0x012C stride are in
; the module header below; the record COUNT there carries its own warning and is not
; leaned on here).  EIGHTEEN routines write into
; it.  THIRTEEN are arms of GlobalSetup_Dispatch, the status-0xF0 message handler at
; 0xFB0338; a fourteenth, GlobalTune_StoreFineTune, sits one level below arm 0x82.
; The remaining FOUR are outside that message entirely:
; ExtBoard_ProbeAndInstallBases, Toggle14FE_AndDispatch, PartRec_InitAllParts, and sub_FAC34D,
; which decrements the countdown at +0x1E.
; `python3 notes/prom_c_inventory_round8.py --record` lists every writer and every
; reader per field, and asserts the last row.
;
;   off   addr    w  writer                              reader
;   +00  0x14FE   1  ExtBoard_ProbeAndInstallBases       Toggle14FE_AndDispatch
;                    (0xFB05E0, = 0)                     (0xFB05F1, then xor 0xFF)
;   +01  0x14FF   2  the FLAG WORD, bit by bit:
;                    bit 0  sub_FADA7C          (arm 0x09)  Voice_GetOctaveShift 0xFA72F0,
;                                                           Voice_StageRegs_0800_A 0xFAA4DB
;                    bit 1  sub_FADBFC          (arm 0x99)  only with bit 0, as `and 0x0003`:
;                                                           MidiCtrl_CC07 0xFAD700,
;                                                           MidiCtrl_CC11 0xFAD797
;                    bit 2  ExtBoard_ProbeAndInstallBases   Voice_SelectKeyZone_Reg0040 0xFA8233,
;                           (set 0xFB0518, clear 0xFB0510)  Voice_StageRegs_0040_B 0xFA82F0
;                    bit 9  GlobalScale_SelectGlobalOrPerTone (arm 0xB1)
;                                                           Voice_ComputePitch 0xFA7F81
;                    bits 11..15  sub_FADB0F     (arm 0x85)  NO READER FOUND
;   +03  0x1501   1  P7Mixer_SetGainIndex1       (arm 0x80)  P7Mixer_SetGainIndex2 0xFADAD8
;   +04  0x1502   1  P7Mixer_SetGainIndex2       (arm 0x81)  NO READER FOUND
;   +05  0x1503   2  GlobalTune_StoreFineTune    (arm 0x82)  Voice_StagePitch_Reg0400_AB 0xFA8356,
;                    master fine tune, 1/256 semitone        _CD 0xFA83DB
;   +07  0x1505   2  GlobalTune_StoreTranspose   (arm 0x83)  Voice_ComputePitch 0xFA7F4C,
;                    master transpose, semitones * 256       sub_FC36BE 0xFC36FD
;   +09  0x1507   1  sub_FADBEE                  (arm 0x91)  NO READER FOUND
;   +0A  0x1508   1  sub_FADC3E                  (arm 0xB0)  NO READER FOUND
;   +0B  0x1509   1  Dev10C_SetReg0201_FromNibblePair (0xB2) NO READER FOUND
;                    also written 0x11 by sub_FB6CEE__FB6D83 (0xFB6DA7)
;   +0C  0x150A   1  GlobalScale_StoreMode       (arm 0x86)  Voice_ComputePitch 0xFA7F9B
;   +0D  0x150B  12  GlobalScale_StorePitchClassDetune       Voice_ComputePitch 0xFA7FD2
;         ..0x1516   (arms 0xA4..0xAF, index 0..11)          -- the USER SCALE, one
;                                                           signed detune per pitch class
;   +1B  0x1519   2  sub_FADB0F                  (arm 0x85)  sub_FADB0F itself,
;                    (cleared at 0xFADB66)                   0xFADB4E
;   +1D  0x151B   1  VoiceDefaults_StoreFromPackedByte (0x87) sub_FAC34D 0xFAC35A
;   +1E  0x151C   1  VoiceDefaults_StoreFromPackedByte       sub_FAC34D 0xFAC364/0xFAC367
;   +1F  0x151D   2  VoiceDefaults_StoreFromPackedByte       VoiceRecords_InitFromAlloc
;                                                           0xFB3FAA/0xFB3FF1/0xFB3FFA/0xFB4027,
;                                                           sub_FAC2AE 0xFAC2BD
;   +21  0x151F   2  VoiceDefaults_StoreFromPackedByte       sub_FAC2AE 0xFAC314, 0xFAC31B
;   +23  0x1521   2  VoiceDefaults_StoreFromPackedByte       sub_FAC2AE 0xFAC322
;
; * HOW THE EXTENT IS FIXED, since a record boundary asserted from nothing is how this
;   tree has been wrong before.  The BASE is not chosen: 0x14FE is the literal seven
;   routines load with `lda XIX,0x14fe`, and Voice_ComputePitch reads the scale table
;   through the SAME base, `ld A,(XBC+0x14fe)` at 0xFA7FD2 with XBC = 13 + note mod 12.
;   The END is the part records, whose base 0x001523 and 0x012C stride are established
;   in the module header below.  Between them every byte listed above has a located
;   writer; the offsets reached through a register are exactly
;   +0x00, +0x01, +0x0D, +0x1B, +0x1D, +0x1E, +0x1F, +0x21, +0x23 and the rest are absolute stores.
; * "NO READER FOUND" is a census result, not a guess: `python3
;   notes/prom_c_inventory_round8.py --record` re-derives every row of this table from
;   the source text and asserts the last one.  It is blind to a read through a register
;   this scan does not track, so it says "not found", never "dead".
; ==============================================================================

; --------------------------------------------------------------------------
; sub_FADA7C -- 0xFADA7C..0xFADAB0 (53 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFB0409
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFA664B = VoiceSubsystem_Init, 0xFB029E = sub_FB029E
;          0xFB6CEE = PartRec_InitAllParts
; Evidence: the listing below is the byte-identical round-trip of 0xFADA7C-0xFADAB0
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Named:   NO -- and the reason is derived, not asserted.  What it DOES is exact:
;          `lda XIX,0x14fe` at 0xFADA81, then `cp (XIZ+0x08),0x01` at 0xFADA85 selecting
;          `or (XIX+0x01),0x0001` at 0xFADA8D or `and (XIX+0x01),0xfffe` at 0xFADA99 --
;          so v == 1 SETS global-setup flag bit 0 and anything else clears it -- and it
;          then re-runs VoiceSubsystem_Init with the same 0/1, PartRec_InitAllParts and sub_FB029E.
;          It is arm 0x09 of GlobalSetup_Dispatch (0xFB0409).
; Refused: bit 0 has two readers and neither says what it MEANS.  Voice_GetOctaveShift tests it
;          (`ld HL,(0x14ff) / and BC,0x0001 / jr Z` at 0xFA72F0) and so does
;          Voice_StageRegs_0800_A (0xFAA4DB, branching the other way), and both are
;          themselves unnamed or named for their register rather than their purpose.
;          MidiCtrl_CC07 and MidiCtrl_CC11 read bits 0 and 1 TOGETHER (`and BC,0x0003`
;          at 0xFAD700 and 0xFAD797), so the bit is not even separable from bit 1 there.
;          A name built on "the mode bit 0 selects" would be naming a thing this image
;          does not define.
; --------------------------------------------------------------------------
sub_FADA7C:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FADA7C  link XIZ,0x0000
	push	xix                                   ; FADA80  push XIX
	lda	xix, (0x14FE:16)                      ; FADA81  lda XIX,0x14fe
	cp (xiz+8), 0x01                           ; FADA85  cp (XIZ+0x08),0x01
	jr nz, sub_FADA7C__FADA97                  ; FADA89  jr NZ,0xfada97
	extz	xix                                   ; FADA8B  extz XIX
	extpfx5 0x9C, 0x01, 0x3E, 0x01, 0x00       ; FADA8D  or (XIX+0x01),0x0001
	pushw	1                                    ; FADA92  push 0x0001
	jr sub_FADA7C__FADAA1                      ; FADA95  jr T,0xfadaa1
sub_FADA7C__FADA97:
	extz	xix                                   ; FADA97  extz XIX
	extpfx5 0x9C, 0x01, 0x3C, 0xFE, 0xFF       ; FADA99  and (XIX+0x01),0xfffe
	pushw	0                                    ; FADA9E  push 0x0000
sub_FADA7C__FADAA1:
	call	VoiceSubsystem_Init                              ; FADAA1  call 0xfa664b
	call	PartRec_InitAllParts                              ; FADAA5  call 0xfb6cee
	calr sub_FB029E                 ; FADAA9  calr 0xfb029e
	popw	bc                                    ; FADAAC  pop BC
	pop	xix                                    ; FADAAD  pop XIX
	unlk32 xiz                                 ; FADAAE  unlk XIZ
	ret                                        ; FADAB0  ret
; --------------------------------------------------------------------------
; P7Mixer_SetGainIndex1 -- 0xFADAB1..0xFADAC9 (25 bytes)
;             store global-setup byte +0x03 (RAM 0x001501) and request the mixer gain
;             pair (v, 0x7F).   (* NAMED in wave 7 round 3; was `sub_FADAB1`.)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFB0413
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x001501
; Calls:   0xFA2DCD = P7Mixer_RequestGain
; Evidence: the listing below is the byte-identical round-trip of 0xFADAB1-0xFADAC9
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Name:    `ld (0x1501),C` at 0xFADAB8, then `push 0x007f` at 0xFADABC and `push BC /
;          call 0xFA2DCD` at 0xFADAC1-0xFADAC2: it sets the FIRST of the two mixer-gain
;          indices and forces the second to 0x7F.  Its one reference is arm 0x80 of
;          GlobalSetup_Dispatch, at 0xFB0413.
; Evidence: P7Mixer_RequestGain (0xFA2DCD) stores argument 1 in RAM 0x00F3B3 and
;          argument 2 in 0x00F3B4 and signals semaphore 2; the byte is kept in 0x001501
;          because P7Mixer_SetGainIndex2 reads it back at 0xFADAD8 as argument 1 of the
;          next request.
; Unknown:  which signal the gain scales.  P7Mixer_RequestGain's own header states that
;          gap -- the two indices select rows of DSP_MixerGain_Curve_B and _A -- and
;          nothing in this routine closes it.
; --------------------------------------------------------------------------
P7Mixer_SetGainIndex1:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FADAB1  link XIZ,0x0000
	ld	c, (xiz+8)                              ; FADAB5  ld C,(XIZ+0x08)
	ld	(0x1501:16), c                         ; FADAB8  ld (0x1501),C
	pushw	0x7F                                 ; FADABC  push 0x007f
	extz	bc                                    ; FADABF  extz BC
	pushw	bc                                   ; FADAC1  push BC
	call	P7Mixer_RequestGain                              ; FADAC2  call 0xfa2dcd
	pop	xbc                                    ; FADAC6  pop XBC
	unlk32 xiz                                 ; FADAC7  unlk XIZ
	ret                                        ; FADAC9  ret
; --------------------------------------------------------------------------
; P7Mixer_SetGainIndex2 -- 0xFADACA..0xFADAE6 (29 bytes)
;             store global-setup byte +0x04 (RAM 0x001502) and request the mixer gain
;             pair ((0x001501), v).   (* NAMED in wave 7 round 3; was `sub_FADACA`.)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFB041D
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x001502
;          reads 0x001501
; Calls:   0xFA2DCD = P7Mixer_RequestGain
; Evidence: the listing below is the byte-identical round-trip of 0xFADACA-0xFADAE6
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Name:    `ld (0x1502),C` at 0xFADAD1, then `ld C,(0x1501)` at 0xFADAD8 and `call
;          0xFA2DCD` at 0xFADADF: it sets the SECOND mixer-gain index and re-sends the
;          FIRST from the byte P7Mixer_SetGainIndex1 left at 0x001501.  Its one
;          reference is arm 0x81 of GlobalSetup_Dispatch, at 0xFB041D.
; Evidence: the two pushes at 0xFADAD7 and 0xFADADE are in that order, so the stored
;          0x001501 is argument 1 and the new value argument 2 -- the same order
;          P7Mixer_SetGainIndex1 uses.
; Unknown:  which signal the gain scales; see P7Mixer_RequestGain.
; --------------------------------------------------------------------------
P7Mixer_SetGainIndex2:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FADACA  link XIZ,0x0000
	ld	c, (xiz+8)                              ; FADACE  ld C,(XIZ+0x08)
	ld	(0x1502:16), c                         ; FADAD1  ld (0x1502),C
	extz	bc                                    ; FADAD5  extz BC
	pushw	bc                                   ; FADAD7  push BC
	ld	c, (0x1501:16)                         ; FADAD8  ld C,(0x1501)
	extz	bc                                    ; FADADC  extz BC
	pushw	bc                                   ; FADADE  push BC
	call	P7Mixer_RequestGain                              ; FADADF  call 0xfa2dcd
	pop	xbc                                    ; FADAE3  pop XBC
	unlk32 xiz                                 ; FADAE4  unlk XIZ
	ret                                        ; FADAE6  ret
; --------------------------------------------------------------------------
; GlobalTune_StoreFineTune -- 0xFADAE7..0xFADAFB (21 bytes)
;             store global-setup word +0x05 (RAM 0x001503), the MASTER FINE TUNE, in
;             units of 1/256 semitone.   (* NAMED in wave 7 round 3; was `sub_FADAE7`.)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFB0275
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x001503
; Evidence: the listing below is the byte-identical round-trip of 0xFADAE7-0xFADAFB
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Name:    `ld C,(XIZ+0x08) / sub C,0x40 / add C,C / exts BC / ld (0x1503),BC`
;          (0xFADAEB-0xFADAF5): the byte is centred on 0x40, doubled in EIGHT-BIT
;          arithmetic, and only then sign-extended, so v = 0x00..0x7F maps exactly onto
;          -128..+126 and nothing wraps inside the MIDI data range.
; Evidence: Voice_StagePitch_Reg0400_AB (`ld BC,(0x1503)` at 0xFA8356) and _CD (at
;          0xFA83DB) are the ONLY readers of 0x001503 anywhere in the image, and both
;          add it to the word they stage into register 0x0400+chan, whose unit is
;          1/256 semitone (FINDINGS-prom_c-dev10c-register-meanings.md sec 2).  So the
;          control's full swing is -128..+126 * 1/256 semitone, i.e. just under a
;          quarter tone either way, and the shape is the same one
;          MidiCtrl_Int81_FineTune uses per part, `(v - 0x80) * 2` into part[+0x13].
; Unknown:  nothing outstanding about the arithmetic.  Whether CPU 1 ever sends a value
;          above 0x7F is not established here; the byte-wide doubling would wrap.
; --------------------------------------------------------------------------
GlobalTune_StoreFineTune:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FADAE7  link XIZ,0x0000
	ld	c, (xiz+8)                              ; FADAEB  ld C,(XIZ+0x08)
	sub	c, 64                                  ; FADAEE  sub C,0x40
	add	c, c                                   ; FADAF1  add C,C
	exts	bc                                    ; FADAF3  exts BC
	ld	(0x1503:16), bc                        ; FADAF5  ld (0x1503),BC
	unlk32 xiz                                 ; FADAF9  unlk XIZ
	ret                                        ; FADAFB  ret
; --------------------------------------------------------------------------
; GlobalTune_StoreTranspose -- 0xFADAFC..0xFADB0E (19 bytes)
;             store global-setup word +0x07 (RAM 0x001505), the MASTER TRANSPOSE, as a
;             signed semitone count times 256.
;             (* NAMED in wave 7 round 3; was `sub_FADAFC`.)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFB0431
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x001505
; Evidence: the listing below is the byte-identical round-trip of 0xFADAFC-0xFADB0E
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Name:    `ld BC,(XIZ+0x08) / exts BC / sll 0x08,BC / ld (0x1505),BC`
;          (0xFADB00-0xFADB08).  The `sll 8` shifts the argument byte into the high half
;          and discards whatever the `exts` put there, so the stored word is v * 256 --
;          v read as a two's-complement SEMITONE count.
; Evidence: Voice_ComputePitch reads 0x001505 at 0xFA7F4C and adds it, unshifted, to an
;          accumulator seeded `note * 256 + 0x80` at 0xFA7F3A-0xFA7F48, i.e. in units of
;          1/256 semitone.  The per-part transpose does the identical thing one field
;          later: part[+0x15], which MidiCtrl_Int82_Transpose stores as a signed
;          semitone count, is added SHIFTED LEFT EIGHT at 0xFA7F5A.  Here the shift is
;          done once in the setter instead of on every note.
;          The only other reader of 0x001505 is sub_FC36BE (0xFC36FD).
; Unknown:  nothing outstanding.
; --------------------------------------------------------------------------
GlobalTune_StoreTranspose:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FADAFC  link XIZ,0x0000
	ld	bc, (xiz+8)                             ; FADB00  ld BC,(XIZ+0x08)
	exts	bc                                    ; FADB03  exts BC
	sll	bc, 8                                  ; FADB05  sll 0x08,BC
	ld	(0x1505:16), bc                        ; FADB08  ld (0x1505),BC
	unlk32 xiz                                 ; FADB0C  unlk XIZ
	ret                                        ; FADB0E  ret
; --------------------------------------------------------------------------
; sub_FADB0F -- 0xFADB0F..0xFADB6F (97 bytes)
;
; Called from: no site outside this module.
;          2 site(s) inside this module:
;          0xFB028E 0xFB043B
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFADB0F-0xFADB6F
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Named:   NO.  What it DOES is exact: with XIX = 0x14FE (0xFADB15) it edits the
;          global-setup flag word +0x01 and the word +0x1B.  v != 0 takes 0xFADB1F:
;          if flag bit 12 (0x1000) is already set it returns unchanged, otherwise it
;          sets bit 11 (`set 0x0b,BC` at 0xFADB2E).  v == 0 takes 0xFADB38: it returns
;          unless bit 12 is set, then masks the word to 0x2FFF, sets bit 13, and sets
;          bit 15 or bit 14 according to whether (XIX+0x1B) exceeds 0x0014 (0xFADB51),
;          finally clearing (XIX+0x1B) at 0xFADB66.
; Refused: NOTHING IN THE IMAGE READS BITS 11..15 OF 0x0014FF.  Every located reader of
;          that word masks a low bit -- 0x0001 (0xFA72F0, 0xFAA4DB), 0x0003 (0xFAD700,
;          0xFAD797), 0x0004 (0xFA8233, 0xFA82F0) or 0x0200 (0xFA7F81) -- and the word
;          at 0x001519 is read by NOTHING BUT THIS ROUTINE: `ld BC,(XIX+0x1b)` at
;          0xFADB4E, only to pick bit 15 over bit 14, and then cleared at 0xFADB66.
;          So this routine's effect is fully decoded
;          and its PURPOSE has no evidence anywhere; a name would have to invent one.
;          It is arm 0x85 of GlobalSetup_Dispatch (0xFB043B) and is also called from
;          sub_FB0285.
; --------------------------------------------------------------------------
sub_FADB0F:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FADB0F  link XIZ,0x0000
	pushw	hl                                   ; FADB13  push HL
	push	xix                                   ; FADB14  push XIX
	lda	xix, (0x14FE:16)                      ; FADB15  lda XIX,0x14fe
	cp (xiz+8), 0x00                           ; FADB19  cp (XIZ+0x08),0x00
	jr z, sub_FADB0F__FADB38                   ; FADB1D  jr Z,0xfadb38
	extz	xix                                   ; FADB1F  extz XIX
	ld	hl, (xix+1)                             ; FADB21  ld HL,(XIX+0x01)
	ld	bc, hl                                  ; FADB24  ld BC,HL
	and	bc, 0x1000                             ; FADB26  and BC,0x1000
	jr nz, sub_FADB0F__FADB6B                  ; FADB2A  jr NZ,0xfadb6b
	ld	bc, hl                                  ; FADB2C  ld BC,HL
	set	11, bc                                 ; FADB2E  set 0x0b,BC
	extz	xix                                   ; FADB31  extz XIX
	ld	(xix+1), bc                             ; FADB33  ld (XIX+0x01),BC
	jr sub_FADB0F__FADB64                      ; FADB36  jr T,0xfadb64
sub_FADB0F__FADB38:
	extz	xix                                   ; FADB38  extz XIX
	ld	hl, (xix+1)                             ; FADB3A  ld HL,(XIX+0x01)
	ld	bc, hl                                  ; FADB3D  ld BC,HL
	and	bc, 0x1000                             ; FADB3F  and BC,0x1000
	jr z, sub_FADB0F__FADB6B                   ; FADB43  jr Z,0xfadb6b
	and	hl, 0x2FFF                             ; FADB45  and HL,0x2fff
	set	13, hl                                 ; FADB49  set 0x0d,HL
	extz	xix                                   ; FADB4C  extz XIX
	ld	bc, (xix+27)                            ; FADB4E  ld BC,(XIX+0x1b)
	cp	bc, 20                                  ; FADB51  cp BC,0x0014
	jr ule, sub_FADB0F__FADB5C                 ; FADB55  jr ULE,0xfadb5c
	set	15, hl                                 ; FADB57  set 0x0f,HL
	jr sub_FADB0F__FADB5F                      ; FADB5A  jr T,0xfadb5f
sub_FADB0F__FADB5C:
	set	14, hl                                 ; FADB5C  set 0x0e,HL
sub_FADB0F__FADB5F:
	extz	xix                                   ; FADB5F  extz XIX
	ld	(xix+1), hl                             ; FADB61  ld (XIX+0x01),HL
sub_FADB0F__FADB64:
	extz	xix                                   ; FADB64  extz XIX
	extpfx5 0xBC, 0x1B, 0x02, 0x00, 0x00       ; FADB66  ld (XIX+0x1b),0x0000
sub_FADB0F__FADB6B:
	pop	xix                                    ; FADB6B  pop XIX
	popw	hl                                    ; FADB6C  pop HL
	unlk32 xiz                                 ; FADB6D  unlk XIZ
	ret                                        ; FADB6F  ret
; --------------------------------------------------------------------------
; GlobalScale_StoreMode -- 0xFADB70..0xFADB7D (14 bytes)
;             store global-setup byte +0x0C (RAM 0x00150A), the selector that decides
;             WHICH key-dependent pitch correction Voice_ComputePitch applies.
;             (* NAMED in wave 7 round 3; was `sub_FADB70`.)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFB0445
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x00150A
; Evidence: the listing below is the byte-identical round-trip of 0xFADB70-0xFADB7D
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Name:    `ld C,(XIZ+0x08) / ld (0x150a),C` (0xFADB74-0xFADB77) is the whole body, and
;          0x00150A is the byte Voice_ComputePitch branches on at 0xFA7F9B.
; Evidence: Voice_ComputePitch reads it ONLY on the path guarded by global-setup flag
;          bit 9 (`ld BC,(0x14ff) / and BC,0x0200 / jr Z` at 0xFA7F81-0xFA7F8A), and
;          then compares it against 0x40 (0xFA7FA1 -> the pseudo-random detune at
;          0xFA8006), 0x41 (0xFA7FA7 -> Voice_KeyBend_Curve_0), 0x42 (0xFA7FAE ->
;          Voice_KeyBend_Curve_1) and 0x80 (0xFA7FB5), otherwise falling into the
;          twelve-entry RAM scale table at 0xFA7FBB.
;          * THE 0x80 ARM IS DEGENERATE ON THIS PATH: `jr Z,0xfa7fbb` at 0xFA7FB9 jumps
;          to the very next instruction, so 0x80 takes the table arm like any other
;          value.  On the PER-TONE path the same comparison at 0xFA7FFE jumps to
;          0xFA8072, the join, and really does mean "no correction".  Stated as measured;
;          why the two differ is not established.
; Unknown:  what the mode numbers are called on the panel.
; --------------------------------------------------------------------------
GlobalScale_StoreMode:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FADB70  link XIZ,0x0000
	ld	c, (xiz+8)                              ; FADB74  ld C,(XIZ+0x08)
	ld	(0x150A:16), c                         ; FADB77  ld (0x150a),C
	unlk32 xiz                                 ; FADB7B  unlk XIZ
	ret                                        ; FADB7D  ret
; --------------------------------------------------------------------------
; VoiceDefaults_StoreFromPackedByte -- 0xFADB7E..0xFADBED (112 bytes)
;             unpack four bit-fields of one byte into five global-setup fields that
;             seed every newly allocated voice.
;             (* NAMED in wave 7 round 3; was `sub_FADB7E`.)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFB044F
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFADB7E-0xFADBED
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Name:    five stores into the global-setup record (XIX = 0x14FE, loaded at 0xFADB84),
;          each driven by a different bit-field of the one argument byte:
;              (XIX+0x1D) = 0x001                    3 if v & 0x08 else 1   (0xFADB8D)
;              (XIX+0x1E) = 0x001C     always 1                             (0xFADBA2)
;              (XIX+0x1F) = 0x001D     ROM word at 0xFE128E + 2*(v >> 4)    (0xFADBA8)
;              (XIX+0x21) = 0x001F     0x8000 if v & 0x04 else 0xA000       (0xFADBC0)
;              (XIX+0x23) = 0x0021     0xA8 - ((v & 3) << 3)                (0xFADBD7)
; Evidence: three of the five are VOICE DEFAULTS, read only when a voice is built:
;          VoiceRecords_InitFromAlloc reads 0x00151D four times (0xFB3FAA, 0xFB3FF1,
;          0xFB3FFA, 0xFB4027) into voice[+0x00], [+0x06], [+0x08] and [+0x05], and
;          sub_FAC2AE seeds the 0x00D75E staging block from 0x00151D (0xFAC2BD),
;          0x00151F twice (0xFAC314, 0xFAC31B) and 0x001521 (0xFAC322).  The remaining
;          two are a gate and a countdown: sub_FAC34D tests 0x00151B at 0xFAC35A and
;          decrements 0x00151C at 0xFAC364, calling VoiceRecords_InitFromAlloc only when
;          the counter reaches zero.
;          Its one reference is arm 0x87 of GlobalSetup_Dispatch, at 0xFB044F.
; Unknown:  what each of the four bit-fields is called, and what the 0xFE128E word table
;          holds -- it is indexed by v >> 4 and nothing else reads it.
; --------------------------------------------------------------------------
VoiceDefaults_StoreFromPackedByte:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FADB7E  link XIZ,0x0000
	pushw	hl                                   ; FADB82  push HL
	push	xix                                   ; FADB83  push XIX
	lda	xix, (0x14FE:16)                      ; FADB84  lda XIX,0x14fe
	ld	h, (xiz+8)                              ; FADB88  ld H,(XIZ+0x08)
	ld	c, h                                    ; FADB8B  ld C,H
	and	c, 8                                   ; FADB8D  and C,0x08
	jr z, VoiceDefaults_StoreFromPackedByte__FADB9A                   ; FADB90  jr Z,0xfadb9a
	extz	xix                                   ; FADB92  extz XIX
	ld	(xix+29), 3                             ; FADB94  ld (XIX+0x1d),0x03
	jr VoiceDefaults_StoreFromPackedByte__FADBA0                      ; FADB98  jr T,0xfadba0
VoiceDefaults_StoreFromPackedByte__FADB9A:
	extz	xix                                   ; FADB9A  extz XIX
	ld	(xix+29), 1                             ; FADB9C  ld (XIX+0x1d),0x01
VoiceDefaults_StoreFromPackedByte__FADBA0:
	extz	xix                                   ; FADBA0  extz XIX
	ld	(xix+30), 1                             ; FADBA2  ld (XIX+0x1e),0x01
	ld	c, h                                    ; FADBA6  ld C,H
	and	c, 0xF0                                ; FADBA8  and C,0xf0
	srl	c, 4                                   ; FADBAB  srl 0x04,C
	mul	c, 2                                   ; FADBAE  mul C,0x02
	extz	xbc                                   ; FADBB1  extz XBC
	add	xbc, 0xFE128E                          ; FADBB3  add XBC,0x00fe128e
	ld	bc, (xbc)                               ; FADBB9  ld BC,(XBC)
	ld	(xix+31), bc                            ; FADBBB  ld (XIX+0x1f),BC
	ld	c, h                                    ; FADBBE  ld C,H
	and	c, 4                                   ; FADBC0  and C,0x04
	jr z, VoiceDefaults_StoreFromPackedByte__FADBCE                   ; FADBC3  jr Z,0xfadbce
	extz	xix                                   ; FADBC5  extz XIX
	extpfx5 0xBC, 0x21, 0x02, 0x00, 0x80       ; FADBC7  ld (XIX+0x21),0x8000
	jr VoiceDefaults_StoreFromPackedByte__FADBD5                      ; FADBCC  jr T,0xfadbd5
VoiceDefaults_StoreFromPackedByte__FADBCE:
	extz	xix                                   ; FADBCE  extz XIX
	extpfx5 0xBC, 0x21, 0x02, 0x00, 0xA0       ; FADBD0  ld (XIX+0x21),0xa000
VoiceDefaults_StoreFromPackedByte__FADBD5:
	ld	c, h                                    ; FADBD5  ld C,H
	and	c, 3                                   ; FADBD7  and C,0x03
	sll	c, 3                                   ; FADBDA  sll 0x03,C
	extz	bc                                    ; FADBDD  extz BC
	ldw	wa, 0xA8                               ; FADBDF  ld WA,0x00a8
	sub	wa, bc                                 ; FADBE2  sub WA,BC
	extz	xix                                   ; FADBE4  extz XIX
	ld	(xix+35), wa                            ; FADBE6  ld (XIX+0x23),WA
	pop	xix                                    ; FADBE9  pop XIX
	popw	hl                                    ; FADBEA  pop HL
	unlk32 xiz                                 ; FADBEB  unlk XIZ
	ret                                        ; FADBED  ret
; --------------------------------------------------------------------------
; sub_FADBEE -- 0xFADBEE..0xFADBFB (14 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFB0459
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x001507
; Evidence: the listing below is the byte-identical round-trip of 0xFADBEE-0xFADBFB
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Named:   NO.  The body is three instructions: `ld C,(XIZ+0x08) / ld (0x1507),C`
;          (0xFADBF2-0xFADBF5).  It is arm 0x91 of GlobalSetup_Dispatch (0xFB0459).
; Refused: global-setup byte +0x09 (RAM 0x001507) IS NEVER READ.  The census is over
;          both spellings the record is reached by: `(0x1507)` appears exactly once in
;          prom_c's source, at this store, and every access the record gets through a
;          register lands on
;          +0x00, +0x01, +0x0D, +0x1B, +0x1D, +0x1E, +0x1F, +0x21, +0x23 -- never +0x09.  A field with a writer and no reader can be named for
;          the message that writes it and for nothing else, which is a number, so the
;          name stays an address.  (`python3 notes/prom_c_inventory_round8.py --record`)
; --------------------------------------------------------------------------
sub_FADBEE:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FADBEE  link XIZ,0x0000
	ld	c, (xiz+8)                              ; FADBF2  ld C,(XIZ+0x08)
	ld	(0x1507:16), c                         ; FADBF5  ld (0x1507),C
	unlk32 xiz                                 ; FADBF9  unlk XIZ
	ret                                        ; FADBFB  ret
; --------------------------------------------------------------------------
; sub_FADBFC -- 0xFADBFC..0xFADC1E (35 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFB0469
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFADBFC-0xFADC1E
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Named:   NO.  What it DOES is exact: `cp (XIZ+0x08),0x00` at 0xFADC05 selecting
;          `or (XIX+0x01),0x0002` at 0xFADC0D or `and (XIX+0x01),0xfffd` at 0xFADC16,
;          with XIX = 0x14FE -- v != 0 sets global-setup flag bit 1, v == 0 clears it.
;          It is arm 0x99 of GlobalSetup_Dispatch (0xFB0469).
; Refused: bit 1 is never read ALONE.  Its only readers are MidiCtrl_CC07 (0xFAD700)
;          and MidiCtrl_CC11 (0xFAD797), and both mask `0x0003` -- bit 1 together with
;          bit 0, which sub_FADA7C owns.  So the image gives the PAIR a meaning and
;          neither bit one of its own, and a name for this setter would be splitting a
;          condition the hardware path never splits.
; --------------------------------------------------------------------------
sub_FADBFC:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FADBFC  link XIZ,0x0000
	push	xix                                   ; FADC00  push XIX
	lda	xix, (0x14FE:16)                      ; FADC01  lda XIX,0x14fe
	cp (xiz+8), 0x00                           ; FADC05  cp (XIZ+0x08),0x00
	jr z, sub_FADBFC__FADC14                   ; FADC09  jr Z,0xfadc14
	extz	xix                                   ; FADC0B  extz XIX
	extpfx5 0x9C, 0x01, 0x3E, 0x02, 0x00       ; FADC0D  or (XIX+0x01),0x0002
	jr sub_FADBFC__FADC1B                      ; FADC12  jr T,0xfadc1b
sub_FADBFC__FADC14:
	extz	xix                                   ; FADC14  extz XIX
	extpfx5 0x9C, 0x01, 0x3C, 0xFD, 0xFF       ; FADC16  and (XIX+0x01),0xfffd
sub_FADBFC__FADC1B:
	pop	xix                                    ; FADC1B  pop XIX
	unlk32 xiz                                 ; FADC1C  unlk XIZ
	ret                                        ; FADC1E  ret
; --------------------------------------------------------------------------
; GlobalScale_StorePitchClassDetune -- 0xFADC1F..0xFADC3D (31 bytes)
;             store one of the TWELVE per-pitch-class detunes at global-setup +0x0D
;             (RAM 0x00150B..0x001516) -- the user scale / temperament table.
;             (* NAMED in wave 7 round 3; was `sub_FADC1F`.)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFB04E0
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFADC1F-0xFADC3D
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Name:    `ld H,(XIZ+0x0a) / sub H,0x80` then `ld BC,(XIZ+0x08) / add BC,13 /
;          ld (XBC+0x14fe),H` (0xFADC24-0xFADC35): argument 1 is an index 0..11 and
;          argument 2 the value, stored centred on 0x80 at RAM 0x14FE + 13 + index =
;          0x00150B + index.
; Evidence: the index is not inferred -- GlobalSetup_Dispatch's twelve arms 0xA4..0xAF
;          push it as a literal, 0x0000 at 0xFB0479 rising by one to 0x000B at 0xFB04DD,
;          and all twelve then `calr 0xfadc1f` through the single site 0xFB04E0.
;          The reader is Voice_ComputePitch__FA7FBB: it takes the note byte
;          (`ld C,(XIX+0x05) / res 7,C` at 0xFA7FBD), divides by twelve and keeps the
;          REMAINDER (`div C,0x0c / ld C,B` at 0xFA7FC5-0xFA7FC8), adds 13, and reads
;          `(XBC+0x14fe)` at 0xFA7FD2 -- the same base and the same +13 -- then sign-
;          extends and DOUBLES it (`add WA,WA` at 0xFA7FD9) into the pitch accumulator.
;          So entry i is the detune of pitch class i, one unit = 2/256 semitone, and the
;          signed byte range -128..+127 is +/- one semitone.
; Unknown:  whether the panel calls this a scale, a temperament or a tuning table.
; --------------------------------------------------------------------------
GlobalScale_StorePitchClassDetune:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FADC1F  link XIZ,0x0000
	pushw	hl                                   ; FADC23  push HL
	ld	h, (xiz+10)                             ; FADC24  ld H,(XIZ+0x0a)
	sub	h, 0x80                                ; FADC27  sub H,0x80
	ld	bc, (xiz+8)                             ; FADC2A  ld BC,(XIZ+0x08)
	extz	bc                                    ; FADC2D  extz BC
	add	bc, 13                                 ; FADC2F  add BC,0x000d
	extz	xbc                                   ; FADC33  extz XBC
	ld	(xbc+0x14FE), h                         ; FADC35  ld (XBC+0x14fe),H
	popw	hl                                    ; FADC3A  pop HL
	unlk32 xiz                                 ; FADC3B  unlk XIZ
	ret                                        ; FADC3D  ret
; --------------------------------------------------------------------------
; sub_FADC3E -- 0xFADC3E..0xFADC4B (14 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFB04EA
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x001508
; Evidence: the listing below is the byte-identical round-trip of 0xFADC3E-0xFADC4B
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Named:   NO.  The body is three instructions: `ld C,(XIZ+0x08) / ld (0x1508),C`
;          (0xFADC42-0xFADC45).  It is arm 0xB0 of GlobalSetup_Dispatch (0xFB04EA).
; Refused: global-setup byte +0x0A (RAM 0x001508) IS NEVER READ -- same census as
;          sub_FADBEE's, same result: one appearance of `(0x1508)` in the whole source,
;          this store, and no +0x0A among the offsets reached through the 0x14FE base.
; --------------------------------------------------------------------------
sub_FADC3E:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FADC3E  link XIZ,0x0000
	ld	c, (xiz+8)                              ; FADC42  ld C,(XIZ+0x08)
	ld	(0x1508:16), c                         ; FADC45  ld (0x1508),C
	unlk32 xiz                                 ; FADC49  unlk XIZ
	ret                                        ; FADC4B  ret
; --------------------------------------------------------------------------
; GlobalScale_SelectGlobalOrPerTone -- 0xFADC4C..0xFADC6E (35 bytes)
;             set or clear global-setup flag bit 9, which chooses between the GLOBAL
;             scale above and the PER-TONE scale in ROM.
;             (* NAMED in wave 7 round 3; was `sub_FADC4C`.)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFB04F3
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFADC4C-0xFADC6E
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Name:    `cp (XIZ+0x08),0x00 / jr NZ` at 0xFADC55-0xFADC59 then `or (XIX+0x01),0x0200`
;          at 0xFADC5D or `and (XIX+0x01),0xfdff` at 0xFADC66, with XIX = 0x14FE loaded
;          at 0xFADC51: v == 0 SETS global-setup flag bit 9, v != 0 CLEARS it.
; Evidence: Voice_ComputePitch tests exactly that bit at 0xFA7F81-0xFA7F8A and the two
;          arms are a matched pair.  With the bit SET it takes the GLOBAL scale: mode
;          byte 0x00150A, table RAM 0x00150B + note mod 12 (0xFA7F9B, 0xFA7FD2).  With
;          the bit CLEAR it takes the PER-TONE scale: mode byte (voice[+0x13])[+0x13],
;          table ROM 0xFDF2C3 + 12 * mode + note mod 12 (0xFA7FE5, 0xFA8064).  Same
;          four mode numbers, same doubling, different source -- which is what makes
;          "global or per-tone" the meaning of the bit rather than a guess about it.
; Unknown:  why v == 0 is the GLOBAL case rather than the other way round.
; --------------------------------------------------------------------------
GlobalScale_SelectGlobalOrPerTone:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FADC4C  link XIZ,0x0000
	push	xix                                   ; FADC50  push XIX
	lda	xix, (0x14FE:16)                      ; FADC51  lda XIX,0x14fe
	cp (xiz+8), 0x00                           ; FADC55  cp (XIZ+0x08),0x00
	jr nz, GlobalScale_SelectGlobalOrPerTone__FADC64                  ; FADC59  jr NZ,0xfadc64
	extz	xix                                   ; FADC5B  extz XIX
	extpfx5 0x9C, 0x01, 0x3E, 0x00, 0x02       ; FADC5D  or (XIX+0x01),0x0200
	jr GlobalScale_SelectGlobalOrPerTone__FADC6B                      ; FADC62  jr T,0xfadc6b
GlobalScale_SelectGlobalOrPerTone__FADC64:
	extz	xix                                   ; FADC64  extz XIX
	extpfx5 0x9C, 0x01, 0x3C, 0xFF, 0xFD       ; FADC66  and (XIX+0x01),0xfdff
GlobalScale_SelectGlobalOrPerTone__FADC6B:
	pop	xix                                    ; FADC6B  pop XIX
	unlk32 xiz                                 ; FADC6C  unlk XIZ
	ret                                        ; FADC6E  ret
; --------------------------------------------------------------------------
; Dev10C_SetReg0201_FromNibblePair -- 0xFADC6F..0xFADCC2 (84 bytes)
;             store global-setup byte +0x0B (RAM 0x001509) and rebuild device register
;             0x0201 from its two nibbles and a ROM default word.
;             (* NAMED in wave 7 round 3; was `sub_FADC6F`.)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFB04FC
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x001509
;          reads 0xFE12B7
; Calls:   0xFAD12A = Dev10C_WriteReg_0201
; Evidence: the listing below is the byte-identical round-trip of 0xFADC6F-0xFADCC2
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Name:    `ld D,(XIZ+0x08) / ld (0x1509),D` at 0xFADC76-0xFADC79 keeps the byte, and
;          the rest of the body splits it into two nibbles and rebuilds one device
;          register word: the low nibble, non-zero, contributes (n - 1) << 5
;          (0xFADC7F-0xFADC8E); the high nibble, non-zero, contributes (n - 0x10) << 8
;          (0xFADC95-0xFADCA6); both are OR-ed at 0xFADCB4/0xFADCB6 onto
;          `(0xFE12B7) & 0x0F9F`, a ROM word masked to the bits the two fields do not
;          occupy, and the result is passed to Dev10C_WriteReg_0201 at 0xFADCB9.
; Evidence: the two shift amounts and the mask are immediates in the listing below, and
;          0x0F9F is the exact complement of the two fields the nibbles fill -- bits
;          5..6 and 8..11 -- which is what makes "rebuild, do not overwrite" the reading.
;          Its one reference is arm 0xB2 of GlobalSetup_Dispatch, at 0xFB04FC.
; Unknown:  what register 0x0201 of the 0x0010C000 device controls.  It is not one of
;          the per-channel blocks; Dev10C_WriteReg_0201 is its only writer and this is
;          its only caller.
; --------------------------------------------------------------------------
Dev10C_SetReg0201_FromNibblePair:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FADC6F  link XIZ,0x0000
	pushw	hl                                   ; FADC73  push HL
	pushw	de                                   ; FADC74  push DE
	pushw	ix                                   ; FADC75  push IX
	ld	d, (xiz+8)                              ; FADC76  ld D,(XIZ+0x08)
	ld	(0x1509:16), d                         ; FADC79  ld (0x1509),D
	ld	c, d                                    ; FADC7D  ld C,D
	and	c, 15                                  ; FADC7F  and C,0x0f
	extz	bc                                    ; FADC82  extz BC
	ld	ix, bc                                  ; FADC84  ld IX,BC
	cp	bc, 0:i3                                  ; FADC86  cp BC,0
	jr z, Dev10C_SetReg0201_FromNibblePair__FADC93                   ; FADC88  jr Z,0xfadc93
	dec	1, bc                                  ; FADC8A  dec 1,BC
	ld	ix, bc                                  ; FADC8C  ld IX,BC
	sll	bc, 5                                  ; FADC8E  sll 0x05,BC
	ld	ix, bc                                  ; FADC91  ld IX,BC
Dev10C_SetReg0201_FromNibblePair__FADC93:
	ld	c, d                                    ; FADC93  ld C,D
	and	c, 0xF0                                ; FADC95  and C,0xf0
	extz	bc                                    ; FADC98  extz BC
	ld	hl, bc                                  ; FADC9A  ld HL,BC
	cp	bc, 0:i3                                  ; FADC9C  cp BC,0
	jr z, Dev10C_SetReg0201_FromNibblePair__FADCAB                   ; FADC9E  jr Z,0xfadcab
	sub	bc, 16                                 ; FADCA0  sub BC,0x0010
	ld	hl, bc                                  ; FADCA4  ld HL,BC
	sll	bc, 8                                  ; FADCA6  sll 0x08,BC
	ld	hl, bc                                  ; FADCA9  ld HL,BC
Dev10C_SetReg0201_FromNibblePair__FADCAB:
	ld	bc, (0xFE12B7:24)                      ; FADCAB  ld BC,(0xfe12b7)
	and	bc, 0xF9F                              ; FADCB0  and BC,0x0f9f
	or	bc, ix                                  ; FADCB4  or BC,IX
	or	bc, hl                                  ; FADCB6  or BC,HL
	pushw	bc                                   ; FADCB8  push BC
	calr Dev10C_WriteReg_0201                 ; FADCB9  calr 0xfad12a
	popw	bc                                    ; FADCBC  pop BC
	popw	ix                                    ; FADCBD  pop IX
	popw	de                                    ; FADCBE  pop DE
	popw	hl                                    ; FADCBF  pop HL
	unlk32 xiz                                 ; FADCC0  unlk XIZ
	ret                                        ; FADCC2  ret
; --------------------------------------------------------------------------
; Voice_RestagePitchReg0400_ForList -- 0xFADCC3..0xFADD28 (102 bytes)
;             for every voice index in a caller-supplied list, restage and re-send
;             register 0x0400+chan -- the pitch.
;             (* NAMED in wave 7 round 3; was `sub_FADCC3`.)
;
; Called from: 1 site(s) outside this module:
;          0xFBC448 in sub_FBC39D__FBC43A
;          3 site(s) inside this module:
;          0xFAFFAB 0xFB027D 0xFB0296
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFA8347 = Voice_StagePitch_Reg0400_AB, 0xFA83CC = Voice_StagePitch_Reg0400_CD
;          0xFACE67 = Dev10C_SetChanPitch_Reg0400
; Voice record: touches voice_record[+0x01(r)] -- pointer built in place.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFADCC3-0xFADD28
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Name:    it walks the caller's byte list at (XIZ+0x08), starting at offset +5
;          (`inc 5,XIX` at 0xFADCD0) and stopping at the first entry >= 0x40
;          (`cp H,0x40 / jr NC` at 0xFADCD4) -- 0x40 being the channel count of the
;          0x0010C000 device -- and for each entry it restages and re-sends that voice's
;          pitch register.
; Evidence: the record it forms is the VOICE record: `ld DE,0x3bcf` at 0xFADCCA,
;          `ld C,0x44 / mul BC,H` at 0xFADCD9, the base and stride
;          FINDINGS-prom_c-dev10c-register-meanings.md sec 2 establishes for the 64
;          voice records.  It then selects on (record+1) & 0x003C and calls
;          Voice_StagePitch_Reg0400_AB (0xFADD03) or _CD (0xFADD0A) -- the two routines
;          that write the 0x0400 staging word -- and finishes with
;          Dev10C_SetChanPitch_Reg0400 (0xFADD1A), passing the voice index and the
;          staging block at 0x00D75E.
; Unknown:  what the four values 4 / 8 / 0x10 / 0x20 of (record+1) & 0x3C denote.  Three
;          of them route to _AB and one to _CD; nothing here says what the split means.
; --------------------------------------------------------------------------
Voice_RestagePitchReg0400_ForList:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FADCC3  link XIZ,0x0000
	push	xhl                                   ; FADCC7  push XHL
	pushw	de                                   ; FADCC8  push DE
	push	xix                                   ; FADCC9  push XIX
	ldw	de, 0x3BCF                             ; FADCCA  ld DE,0x3bcf
	ld	xix, (xiz+8)                            ; FADCCD  ld XIX,(XIZ+0x08)
	inc	5, xix                                 ; FADCD0  inc 5,XIX
Voice_RestagePitchReg0400_ForList__FADCD2:
	ld	h, (xix)                                ; FADCD2  ld H,(XIX)
	cp	h, 64                                   ; FADCD4  cp H,0x40
	jr nc, Voice_RestagePitchReg0400_ForList__FADD23                  ; FADCD7  jr NC,0xfadd23
	ld	c, 68:opc                                  ; FADCD9  ld C,0x44
	mul8rr	c, h                                ; FADCDB  mul BC,H
	ld	hl, bc                                  ; FADCDD  ld HL,BC
	add	hl, de                                 ; FADCDF  add HL,DE
	extz	xhl                                   ; FADCE1  extz XHL
	ld	bc, (xhl+1)                             ; FADCE3  ld BC,(XHL+0x01)
	and	bc, 60                                 ; FADCE6  and BC,0x003c
	cp	bc, 4:i3                                  ; FADCEA  cp BC,4
	jr z, Voice_RestagePitchReg0400_ForList__FADD02                   ; FADCEC  jr Z,0xfadd02
	cp	bc, 8                                   ; FADCEE  cp BC,0x0008
	jr z, Voice_RestagePitchReg0400_ForList__FADD02                   ; FADCF2  jr Z,0xfadd02
	cp	bc, 16                                  ; FADCF4  cp BC,0x0010
	jr z, Voice_RestagePitchReg0400_ForList__FADD09                   ; FADCF8  jr Z,0xfadd09
	cp	bc, 32                                  ; FADCFA  cp BC,0x0020
	jr z, Voice_RestagePitchReg0400_ForList__FADD02                   ; FADCFE  jr Z,0xfadd02
	jr Voice_RestagePitchReg0400_ForList__FADD1F                      ; FADD00  jr T,0xfadd1f
Voice_RestagePitchReg0400_ForList__FADD02:
	pushw	hl                                   ; FADD02  push HL
	call	Voice_StagePitch_Reg0400_AB                              ; FADD03  call 0xfa8347
	jr Voice_RestagePitchReg0400_ForList__FADD0E                      ; FADD07  jr T,0xfadd0e
Voice_RestagePitchReg0400_ForList__FADD09:
	pushw	hl                                   ; FADD09  push HL
	call	Voice_StagePitch_Reg0400_CD                              ; FADD0A  call 0xfa83cc
Voice_RestagePitchReg0400_ForList__FADD0E:
	popw	bc                                    ; FADD0E  pop BC
	lda	xbc, (0xD75E:24)                       ; FADD0F  lda XBC,0x00d75e
	push	xbc                                   ; FADD14  push XBC
	ld	a, (xix)                                ; FADD15  ld A,(XIX)
	extz	wa                                    ; FADD17  extz WA
	pushw	wa                                   ; FADD19  push WA
	calr Dev10C_SetChanPitch_Reg0400                 ; FADD1A  calr 0xface67
	inc	6, xsp                                 ; FADD1D  inc 6,XSP
Voice_RestagePitchReg0400_ForList__FADD1F:
	inc	1, xix                                 ; FADD1F  inc 1,XIX
	jr Voice_RestagePitchReg0400_ForList__FADCD2                      ; FADD21  jr T,0xfadcd2
Voice_RestagePitchReg0400_ForList__FADD23:
	pop	xix                                    ; FADD23  pop XIX
	popw	de                                    ; FADD24  pop DE
	pop	xhl                                    ; FADD25  pop XHL
	unlk32 xiz                                 ; FADD26  unlk XIZ
	ret                                        ; FADD28  ret
; --------------------------------------------------------------------------
; sub_FADD29 -- 0xFADD29..0xFADDC7 (159 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAE151
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFA8347 = Voice_StagePitch_Reg0400_AB, 0xFA83CC = Voice_StagePitch_Reg0400_CD
;          0xFACE67 = Dev10C_SetChanPitch_Reg0400, 0xFB707E = sub_FB707E
;          0xFC7E79 = sub_FC7E79, 0xFC7FCA = sub_FC7FCA
; Evidence: the listing below is the byte-identical round-trip of 0xFADD29-0xFADDC7
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FADD29:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FADD29  link XIZ,0xfffc
	push	xhl                                   ; FADD2D  push XHL
	pushw	de                                   ; FADD2E  push DE
	push	xix                                   ; FADD2F  push XIX
	ldw	bc, 0x3BCF                             ; FADD30  ld BC,0x3bcf
	ld	(xiz-2), bc                             ; FADD33  ld (XIZ+0xfe),BC
	ld	xix, (xiz+8)                            ; FADD36  ld XIX,(XIZ+0x08)
	inc	5, xix                                 ; FADD39  inc 5,XIX
sub_FADD29__FADD3B:
	ld	h, (xix)                                ; FADD3B  ld H,(XIX)
	cp	h, 64                                   ; FADD3D  cp H,0x40
	jrl nc, sub_FADD29__FADDC2                 ; FADD40  jrl NC,0xfaddc2
	ld	c, 68:opc                                  ; FADD43  ld C,0x44
	mul8rr	c, h                                ; FADD45  mul BC,H
	ld	(xiz-4), bc                             ; FADD47  ld (XIZ+0xfc),BC
	ld	hl, (xiz-2)                             ; FADD4A  ld HL,(XIZ+0xfe)
	add	hl, bc                                 ; FADD4D  add HL,BC
	pushw	hl                                   ; FADD4F  push HL
	call	sub_FC7E79                              ; FADD50  call 0xfc7e79
	extz	xhl                                   ; FADD54  extz XHL
	ld	de, (xhl+1)                             ; FADD56  ld DE,(XHL+0x01)
	ld	bc, de                                  ; FADD59  ld BC,DE
	and	bc, 0x200                              ; FADD5B  and BC,0x0200
	popw	wa                                    ; FADD5F  pop WA
	jr z, sub_FADD29__FADD82                   ; FADD60  jr Z,0xfadd82
	lda	xbc, (0xD75E:24)                       ; FADD62  lda XBC,0x00d75e
	push	xbc                                   ; FADD67  push XBC
	pushw	hl                                   ; FADD68  push HL
	call	sub_FC7FCA                              ; FADD69  call 0xfc7fca
	lda	xbc, (0xD75E:24)                       ; FADD6D  lda XBC,0x00d75e
	push	xbc                                   ; FADD72  push XBC
	ld	a, (xix)                                ; FADD73  ld A,(XIX)
	extz	wa                                    ; FADD75  extz WA
	pushw	wa                                   ; FADD77  push WA
	call	sub_FB707E                              ; FADD78  call 0xfb707e
	inc	8, xsp                                 ; FADD7C  inc 0,XSP
	inc	4, xsp                                 ; FADD7E  inc 4,XSP
	jr sub_FADD29__FADDBD                      ; FADD80  jr T,0xfaddbd
sub_FADD29__FADD82:
	ld	bc, de                                  ; FADD82  ld BC,DE
	and	bc, 60                                 ; FADD84  and BC,0x003c
	cp	bc, 4:i3                                  ; FADD88  cp BC,4
	jr z, sub_FADD29__FADDA0                   ; FADD8A  jr Z,0xfadda0
	cp	bc, 8                                   ; FADD8C  cp BC,0x0008
	jr z, sub_FADD29__FADDA0                   ; FADD90  jr Z,0xfadda0
	cp	bc, 16                                  ; FADD92  cp BC,0x0010
	jr z, sub_FADD29__FADDA7                   ; FADD96  jr Z,0xfadda7
	cp	bc, 32                                  ; FADD98  cp BC,0x0020
	jr z, sub_FADD29__FADDA0                   ; FADD9C  jr Z,0xfadda0
	jr sub_FADD29__FADDBD                      ; FADD9E  jr T,0xfaddbd
sub_FADD29__FADDA0:
	pushw	hl                                   ; FADDA0  push HL
	call	Voice_StagePitch_Reg0400_AB                              ; FADDA1  call 0xfa8347
	jr sub_FADD29__FADDAC                      ; FADDA5  jr T,0xfaddac
sub_FADD29__FADDA7:
	pushw	hl                                   ; FADDA7  push HL
	call	Voice_StagePitch_Reg0400_CD                              ; FADDA8  call 0xfa83cc
sub_FADD29__FADDAC:
	popw	bc                                    ; FADDAC  pop BC
	lda	xbc, (0xD75E:24)                       ; FADDAD  lda XBC,0x00d75e
	push	xbc                                   ; FADDB2  push XBC
	ld	a, (xix)                                ; FADDB3  ld A,(XIX)
	extz	wa                                    ; FADDB5  extz WA
	pushw	wa                                   ; FADDB7  push WA
	calr Dev10C_SetChanPitch_Reg0400                 ; FADDB8  calr 0xface67
	inc	6, xsp                                 ; FADDBB  inc 6,XSP
sub_FADD29__FADDBD:
	inc	1, xix                                 ; FADDBD  inc 1,XIX
	jrl sub_FADD29__FADD3B                     ; FADDBF  jrl T,0xfadd3b
sub_FADD29__FADDC2:
	pop	xix                                    ; FADDC2  pop XIX
	popw	de                                    ; FADDC3  pop DE
	pop	xhl                                    ; FADDC4  pop XHL
	unlk32 xiz                                 ; FADDC5  unlk XIZ
	ret                                        ; FADDC7  ret
; --------------------------------------------------------------------------
; Voice_RestageReg0080_ForList -- 0xFADDC8..0xFADE2E (103 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFBC4BA in sub_FBC39D__FBC4AC
;          1 site(s) inside this module:
;          0xFAFECD
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFAB79D = Voice_StageLevel_Reg0080_AB, 0xFAB7E0 = Voice_StageLevel_Reg0080_CD
;          0xFB7038 = Dev10C_SetChanReg_0080_ClrBit15
; Voice record: touches voice_record[+0x01(r)] -- pointer built in place.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFADDC8-0xFADE2E
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; What it is:  re-sends device register 0x0080 for every voice in the list its
;          first argument points at.  Same walk as the rest of the family;
;          stages through Voice_StageLevel_Reg0080_AB or Voice_StageLevel_Reg0080_CD and pushes with
;          Dev10C_SetChanReg_0080_ClrBit15.
; Evidence: `call 0xfb7038` at 0xFADE1F IS Dev10C_SetChanReg_0080_ClrBit15, and
;          the two stagers are `call 0xfab79d` (0xFADE08) and `call 0xfab7e0`
;          (0xFADE0F).  No other member of the six-routine family
;          (notes/prom_c_record68_round10.py --restage) touches register 0x0080.
; Unknown:  what the two stagers do -- they are still sub_XXXXXX -- and what
;          the class values select.  The name claims the register and no more.
; --------------------------------------------------------------------------
Voice_RestageReg0080_ForList:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FADDC8  link XIZ,0x0000
	push	xhl                                   ; FADDCC  push XHL
	pushw	de                                   ; FADDCD  push DE
	push	xix                                   ; FADDCE  push XIX
	ldw	de, 0x3BCF                             ; FADDCF  ld DE,0x3bcf
	ld	xix, (xiz+8)                            ; FADDD2  ld XIX,(XIZ+0x08)
	inc	5, xix                                 ; FADDD5  inc 5,XIX
Voice_RestageReg0080_ForList__FADDD7:
	ld	h, (xix)                                ; FADDD7  ld H,(XIX)
	cp	h, 64                                   ; FADDD9  cp H,0x40
	jr nc, Voice_RestageReg0080_ForList__FADE29                  ; FADDDC  jr NC,0xfade29
	ld	c, 68:opc                                  ; FADDDE  ld C,0x44
	mul8rr	c, h                                ; FADDE0  mul BC,H
	ld	hl, bc                                  ; FADDE2  ld HL,BC
	add	hl, de                                 ; FADDE4  add HL,DE
	extz	xhl                                   ; FADDE6  extz XHL
	ld	bc, (xhl+1)                             ; FADDE8  ld BC,(XHL+0x01)
	and	bc, 60                                 ; FADDEB  and BC,0x003c
	cp	bc, 4:i3                                  ; FADDEF  cp BC,4
	jr z, Voice_RestageReg0080_ForList__FADE07                   ; FADDF1  jr Z,0xfade07
	cp	bc, 8                                   ; FADDF3  cp BC,0x0008
	jr z, Voice_RestageReg0080_ForList__FADE07                   ; FADDF7  jr Z,0xfade07
	cp	bc, 16                                  ; FADDF9  cp BC,0x0010
	jr z, Voice_RestageReg0080_ForList__FADE0E                   ; FADDFD  jr Z,0xfade0e
	cp	bc, 32                                  ; FADDFF  cp BC,0x0020
	jr z, Voice_RestageReg0080_ForList__FADE07                   ; FADE03  jr Z,0xfade07
	jr Voice_RestageReg0080_ForList__FADE14                      ; FADE05  jr T,0xfade14
Voice_RestageReg0080_ForList__FADE07:
	pushw	hl                                   ; FADE07  push HL
	call	Voice_StageLevel_Reg0080_AB                              ; FADE08  call 0xfab79d
	jr Voice_RestageReg0080_ForList__FADE13                      ; FADE0C  jr T,0xfade13
Voice_RestageReg0080_ForList__FADE0E:
	pushw	hl                                   ; FADE0E  push HL
	call	Voice_StageLevel_Reg0080_CD                              ; FADE0F  call 0xfab7e0
Voice_RestageReg0080_ForList__FADE13:
	popw	bc                                    ; FADE13  pop BC
Voice_RestageReg0080_ForList__FADE14:
	lda	xbc, (0xD75E:24)                       ; FADE14  lda XBC,0x00d75e
	push	xbc                                   ; FADE19  push XBC
	ld	a, (xix)                                ; FADE1A  ld A,(XIX)
	extz	wa                                    ; FADE1C  extz WA
	pushw	wa                                   ; FADE1E  push WA
	call	Dev10C_SetChanReg_0080_ClrBit15                              ; FADE1F  call 0xfb7038
	inc	1, xix                                 ; FADE23  inc 1,XIX
	inc	6, xsp                                 ; FADE25  inc 6,XSP
	jr Voice_RestageReg0080_ForList__FADDD7                      ; FADE27  jr T,0xfaddd7
Voice_RestageReg0080_ForList__FADE29:
	pop	xix                                    ; FADE29  pop XIX
	popw	de                                    ; FADE2A  pop DE
	pop	xhl                                    ; FADE2B  pop XHL
	unlk32 xiz                                 ; FADE2C  unlk XIZ
	ret                                        ; FADE2E  ret
; --------------------------------------------------------------------------
; sub_FADE2F -- 0xFADE2F..0xFADEAB (125 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAEF16
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFAA96C = Voice_StageRegs_0800_CD, 0xFAAC00 = Voice_StageRegs_0840_0880_CD
;          0xFACEA2 = Dev10C_SetChanReg_0840_0880
; Voice record: touches voice_record[+0x01(r), +0x43(r)] -- pointer built in place.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFADE2F-0xFADEAB
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; REFUSED (round 10): this is one of the six voice-list walkers
;          notes/prom_c_record68_round10.py --restage selects, and THREE of the six
;          end in the SAME register pair 0x0840/0x0880 --
;          sub_FADE2F through Dev10C_SetChanReg_0840_0880 (`calr 0xfacea2`,
;          0xFADE9B), sub_FAE013 and sub_FAE0A1 through ..._dup (`calr 0xfacf78`,
;          0xFAE092 and 0xFAE0F8), and the tree's own name for the second says it
;          writes the same two registers.  So `Voice_RestageRegs0840_0880_ForList`
;          would be true of all three and identify none.  The only discriminators
;          are the class mask each accepts out of record[+0x01] & 0x3C (0xFADE53,
;          0xFAE037, 0xFAE0C4) and a flag byte pushed to the CD stager, and
;          neither has an established meaning in this tree.  So it keeps its
;          address, and this is the reason rather than a shrug.
; --------------------------------------------------------------------------
sub_FADE2F:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FADE2F  link XIZ,0x0000
	push	xhl                                   ; FADE33  push XHL
	pushw	de                                   ; FADE34  push DE
	push	xix                                   ; FADE35  push XIX
	ldw	de, 0x3BCF                             ; FADE36  ld DE,0x3bcf
	ld	xix, (xiz+8)                            ; FADE39  ld XIX,(XIZ+0x08)
	inc	5, xix                                 ; FADE3C  inc 5,XIX
sub_FADE2F__FADE3E:
	ld	h, (xix)                                ; FADE3E  ld H,(XIX)
	cp	h, 64                                   ; FADE40  cp H,0x40
	jrl nc, sub_FADE2F__FADEA6                 ; FADE43  jrl NC,0xfadea6
	ld	c, 68:opc                                  ; FADE46  ld C,0x44
	mul8rr	c, h                                ; FADE48  mul BC,H
	ld	hl, bc                                  ; FADE4A  ld HL,BC
	add	hl, de                                 ; FADE4C  add HL,DE
	extz	xhl                                   ; FADE4E  extz XHL
	ld	bc, (xhl+1)                             ; FADE50  ld BC,(XHL+0x01)
	and	bc, 60                                 ; FADE53  and BC,0x003c
	cp	bc, 4:i3                                  ; FADE57  cp BC,4
	jr z, sub_FADE2F__FADEA2                   ; FADE59  jr Z,0xfadea2
	cp	bc, 8                                   ; FADE5B  cp BC,0x0008
	jr z, sub_FADE2F__FADEA2                   ; FADE5F  jr Z,0xfadea2
	cp	bc, 16                                  ; FADE61  cp BC,0x0010
	jr z, sub_FADE2F__FADE6F                   ; FADE65  jr Z,0xfade6f
	cp	bc, 32                                  ; FADE67  cp BC,0x0020
	jr z, sub_FADE2F__FADEA2                   ; FADE6B  jr Z,0xfadea2
	jr sub_FADE2F__FADEA2                      ; FADE6D  jr T,0xfadea2
sub_FADE2F__FADE6F:
	extz	xhl                                   ; FADE6F  extz XHL
	ld	c, (xhl+67)                             ; FADE71  ld C,(XHL+0x43)
	cp	c, 0:i3                                   ; FADE74  cp C,0
	jr nz, sub_FADE2F__FADEA2                  ; FADE76  jr NZ,0xfadea2
	extz	xhl                                   ; FADE78  extz XHL
	ld	bc, (xhl+1)                             ; FADE7A  ld BC,(XHL+0x01)
	and	bc, 0x1000                             ; FADE7D  and BC,0x1000
	jr nz, sub_FADE2F__FADEA2                  ; FADE81  jr NZ,0xfadea2
	pushw	hl                                   ; FADE83  push HL
	call	Voice_StageRegs_0800_CD                              ; FADE84  call 0xfaa96c
	pushw	1                                    ; FADE88  push 0x0001
	pushw	hl                                   ; FADE8B  push HL
	call	Voice_StageRegs_0840_0880_CD                              ; FADE8C  call 0xfaac00
	lda	xbc, (0xD75E:24)                       ; FADE90  lda XBC,0x00d75e
	push	xbc                                   ; FADE95  push XBC
	ld	a, (xix)                                ; FADE96  ld A,(XIX)
	extz	wa                                    ; FADE98  extz WA
	pushw	wa                                   ; FADE9A  push WA
	calr Dev10C_SetChanReg_0840_0880                 ; FADE9B  calr 0xfacea2
	inc	8, xsp                                 ; FADE9E  inc 0,XSP
	inc	4, xsp                                 ; FADEA0  inc 4,XSP
sub_FADE2F__FADEA2:
	inc	1, xix                                 ; FADEA2  inc 1,XIX
	jr sub_FADE2F__FADE3E                      ; FADEA4  jr T,0xfade3e
sub_FADE2F__FADEA6:
	pop	xix                                    ; FADEA6  pop XIX
	popw	de                                    ; FADEA7  pop DE
	pop	xhl                                    ; FADEA8  pop XHL
	unlk32 xiz                                 ; FADEA9  unlk XIZ
	ret                                        ; FADEAB  ret
; --------------------------------------------------------------------------
; sub_FADEAC -- 0xFADEAC..0xFADFAC (257 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFBC528 in sub_FBC39D__FBC517, 0xFBD606 in sub_FBD46B__FBD5F3
;          2 site(s) inside this module:
;          0xFAEF70 0xFAFF26
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Calls:   0xFA6EA5 = ChanRec_ClearHoldAndRelease, 0xFAB8CC = Dev10C_StageRegs_0800_0840_FAB8CC
;          0xFABAE3 = Dev10C_StageRegs_0900_0940, 0xFABBFB = Dev10C_StageRegs_09C0_0A00
;          0xFABD50 = Dev10C_StageRegs_0800_0840_FABD50, 0xFACE89 = Dev10C_WriteReg
;          0xFACEDE = Dev10C_SetChanReg_0840_0800, 0xFACF1A = Dev10C_SetChanReg_0840
;          0xFB3DC1 = Voice_Retire_Mode08, 0xFB7345 = Dev10C_WriteSixChanRegs_FromD78A
; Evidence: the listing below is the byte-identical round-trip of 0xFADEAC-0xFADFAC
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FADEAC:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FADEAC  link XIZ,0xfffc
	push	xhl                                   ; FADEB0  push XHL
	pushw	de                                   ; FADEB1  push DE
	push	xix                                   ; FADEB2  push XIX
	ldw	bc, 0x3BCF                             ; FADEB3  ld BC,0x3bcf
	ld	(xiz-2), bc                             ; FADEB6  ld (XIZ+0xfe),BC
	ld	xix, (xiz+8)                            ; FADEB9  ld XIX,(XIZ+0x08)
	inc	5, xix                                 ; FADEBC  inc 5,XIX
sub_FADEAC__FADEBE:
	ld	d, (xix)                                ; FADEBE  ld D,(XIX)
	cp	d, 64                                   ; FADEC0  cp D,0x40
	jrl nc, sub_FADEAC__FADFA7                 ; FADEC3  jrl NC,0xfadfa7
	ld	c, 68:opc                                  ; FADEC6  ld C,0x44
	mul8rr	c, d                                ; FADEC8  mul BC,D
	ld	(xiz-4), bc                             ; FADECA  ld (XIZ+0xfc),BC
	ld	hl, (xiz-2)                             ; FADECD  ld HL,(XIZ+0xfe)
	add	hl, bc                                 ; FADED0  add HL,BC
	extz	xhl                                   ; FADED2  extz XHL
	ld	bc, (xhl+1)                             ; FADED4  ld BC,(XHL+0x01)
	and	bc, 60                                 ; FADED7  and BC,0x003c
	cp	bc, 4:i3                                  ; FADEDB  cp BC,4
	jr z, sub_FADEAC__FADEF6                   ; FADEDD  jr Z,0xfadef6
	cp	bc, 8                                   ; FADEDF  cp BC,0x0008
	jrl z, sub_FADEAC__FADF98                  ; FADEE3  jrl Z,0xfadf98
	cp	bc, 16                                  ; FADEE6  cp BC,0x0010
	jrl z, sub_FADEAC__FADF7A                  ; FADEEA  jrl Z,0xfadf7a
	cp	bc, 32                                  ; FADEED  cp BC,0x0020
	jr z, sub_FADEAC__FADEF6                   ; FADEF1  jr Z,0xfadef6
	jrl sub_FADEAC__FADFA2                     ; FADEF3  jrl T,0xfadfa2
sub_FADEAC__FADEF6:
	extz	xhl                                   ; FADEF6  extz XHL
	ld	bc, (xhl+1)                             ; FADEF8  ld BC,(XHL+0x01)
	and	bc, 0x8000                             ; FADEFB  and BC,0x8000
	jr nz, sub_FADEAC__FADF12                  ; FADEFF  jr NZ,0xfadf12
	extz	xhl                                   ; FADF01  extz XHL
	ld	bc, (xhl+35)                            ; FADF03  ld BC,(XHL+0x23)
	extz	xbc                                   ; FADF06  extz XBC
	ld	wa, (xbc+9)                             ; FADF08  ld WA,(XBC+0x09)
	and	wa, 1                                  ; FADF0B  and WA,0x0001
	jrl nz, sub_FADEAC__FADFA2                 ; FADF0F  jrl NZ,0xfadfa2
sub_FADEAC__FADF12:
	extz	xhl                                   ; FADF12  extz XHL
	ld	bc, (xhl+1)                             ; FADF14  ld BC,(XHL+0x01)
	ld	de, bc                                  ; FADF17  ld DE,BC
	and	de, 0x100                              ; FADF19  and DE,0x0100
	pushw	hl                                   ; FADF1D  push HL
	call	Dev10C_StageRegs_0800_0840_FAB8CC                              ; FADF1E  call 0xfab8cc
	popw	bc                                    ; FADF22  pop BC
	cp	de, 0:i3                                  ; FADF23  cp DE,0
	jr z, sub_FADEAC__FADF55                   ; FADF25  jr Z,0xfadf55
	lda	xbc, (0xD75E:24)                       ; FADF27  lda XBC,0x00d75e
	push	xbc                                   ; FADF2C  push XBC
	ld	a, (xix)                                ; FADF2D  ld A,(XIX)
	extz	wa                                    ; FADF2F  extz WA
	pushw	wa                                   ; FADF31  push WA
	calr Dev10C_SetChanReg_0840                 ; FADF32  calr 0xfacf1a
	extz	xhl                                   ; FADF35  extz XHL
	ld	bc, (xhl+41)                            ; FADF37  ld BC,(XHL+0x29)
	pushw	bc                                   ; FADF3A  push BC
	ld	c, (xix)                                ; FADF3B  ld C,(XIX)
	extz	bc                                    ; FADF3D  extz BC
	pushw	bc                                   ; FADF3F  push BC
	calr Dev10C_WriteReg                 ; FADF40  calr 0xface89
	ld	c, (xix)                                ; FADF43  ld C,(XIX)
	pushw	bc                                   ; FADF45  push BC
	call	ChanRec_ClearHoldAndRelease                              ; FADF46  call 0xfa6ea5
	extpfx5 0x9B, 0x01, 0x3C, 0xFF, 0xFE       ; FADF4A  and (XHL+0x01),0xfeff
	inc	8, xsp                                 ; FADF4F  inc 0,XSP
	inc	4, xsp                                 ; FADF51  inc 4,XSP
	jr sub_FADEAC__FADFA2                      ; FADF53  jr T,0xfadfa2
sub_FADEAC__FADF55:
	cp (xiz+12), 0x02                          ; FADF55  cp (XIZ+0x0c),0x02
	jr nz, sub_FADEAC__FADF86                  ; FADF59  jr NZ,0xfadf86
	pushw	hl                                   ; FADF5B  push HL
	call	Dev10C_StageRegs_0900_0940                              ; FADF5C  call 0xfabae3
	pushw	hl                                   ; FADF60  push HL
	call	Dev10C_StageRegs_09C0_0A00                              ; FADF61  call 0xfabbfb
	lda	xbc, (0xD75E:24)                       ; FADF65  lda XBC,0x00d75e
	push	xbc                                   ; FADF6A  push XBC
	ld	a, (xix)                                ; FADF6B  ld A,(XIX)
	extz	wa                                    ; FADF6D  extz WA
	pushw	wa                                   ; FADF6F  push WA
	call	Dev10C_WriteSixChanRegs_FromD78A                              ; FADF70  call 0xfb7345
	inc	8, xsp                                 ; FADF74  inc 0,XSP
	inc	2, xsp                                 ; FADF76  inc 2,XSP
	jr sub_FADEAC__FADFA2                      ; FADF78  jr T,0xfadfa2
sub_FADEAC__FADF7A:
	cp (xiz+12), 0x01                          ; FADF7A  cp (XIZ+0x0c),0x01
	jr nz, sub_FADEAC__FADFA2                  ; FADF7E  jr NZ,0xfadfa2
	pushw	hl                                   ; FADF80  push HL
	call	Dev10C_StageRegs_0800_0840_FABD50                              ; FADF81  call 0xfabd50
	popw	bc                                    ; FADF85  pop BC
sub_FADEAC__FADF86:
	lda	xbc, (0xD75E:24)                       ; FADF86  lda XBC,0x00d75e
	push	xbc                                   ; FADF8B  push XBC
	ld	a, (xix)                                ; FADF8C  ld A,(XIX)
	extz	wa                                    ; FADF8E  extz WA
	pushw	wa                                   ; FADF90  push WA
	calr Dev10C_SetChanReg_0840_0800                 ; FADF91  calr 0xfacede
	inc	6, xsp                                 ; FADF94  inc 6,XSP
	jr sub_FADEAC__FADFA2                      ; FADF96  jr T,0xfadfa2
sub_FADEAC__FADF98:
	ld	c, d                                    ; FADF98  ld C,D
	extz	bc                                    ; FADF9A  extz BC
	pushw	bc                                   ; FADF9C  push BC
	call	Voice_Retire_Mode08                              ; FADF9D  call 0xfb3dc1
	popw	bc                                    ; FADFA1  pop BC
sub_FADEAC__FADFA2:
	inc	1, xix                                 ; FADFA2  inc 1,XIX
	jrl sub_FADEAC__FADEBE                     ; FADFA4  jrl T,0xfadebe
sub_FADEAC__FADFA7:
	pop	xix                                    ; FADFA7  pop XIX
	popw	de                                    ; FADFA8  pop DE
	pop	xhl                                    ; FADFA9  pop XHL
	unlk32 xiz                                 ; FADFAA  unlk XIZ
	ret                                        ; FADFAC  ret
; --------------------------------------------------------------------------
; Voice_RestageRegs0100_0140_ForList -- 0xFADFAD..0xFAE012 (102 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAE1A4
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFA919B = Voice_StagePair_Reg0100_0140_AB, 0xFA92A5 = Voice_StagePair_Reg0100_0140_CD
;          0xFACF3C = Dev10C_SetChanReg_0100_0140
; Voice record: touches voice_record[+0x01(r)] -- pointer built in place.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFADFAD-0xFAE012
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; What it is:  re-sends device registers 0x0100/0x0140 for every voice in the
;          list its first argument points at.  Walks voice_record[] at the
;          0x44 stride, switches on record[+0x01] & 0x3C, stages through
;          Voice_StagePair_Reg0100_0140_AB or _CD and pushes the pair with
;          Dev10C_SetChanReg_0100_0140.
; Evidence: `calr 0xfacf3c` at 0xFAE004 IS Dev10C_SetChanReg_0100_0140, and the
;          two stagers are `call 0xfa919b` (0xFADFED) and `call 0xfa92a5`
;          (0xFADFF4).  Six routines in prom_c share this shape
;          (notes/prom_c_record68_round10.py --restage) and no other one
;          touches registers 0x0100/0x0140.
; Unknown:  what the four class values 4/8/0x10/0x20 of record[+0x01] & 0x3C
;          SELECT.  The name claims the register group and nothing else.
; --------------------------------------------------------------------------
Voice_RestageRegs0100_0140_ForList:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FADFAD  link XIZ,0x0000
	push	xhl                                   ; FADFB1  push XHL
	pushw	de                                   ; FADFB2  push DE
	push	xix                                   ; FADFB3  push XIX
	ldw	de, 0x3BCF                             ; FADFB4  ld DE,0x3bcf
	ld	xix, (xiz+8)                            ; FADFB7  ld XIX,(XIZ+0x08)
	inc	5, xix                                 ; FADFBA  inc 5,XIX
Voice_RestageRegs0100_0140_ForList__FADFBC:
	ld	h, (xix)                                ; FADFBC  ld H,(XIX)
	cp	h, 64                                   ; FADFBE  cp H,0x40
	jr nc, Voice_RestageRegs0100_0140_ForList__FAE00D                  ; FADFC1  jr NC,0xfae00d
	ld	c, 68:opc                                  ; FADFC3  ld C,0x44
	mul8rr	c, h                                ; FADFC5  mul BC,H
	ld	hl, bc                                  ; FADFC7  ld HL,BC
	add	hl, de                                 ; FADFC9  add HL,DE
	extz	xhl                                   ; FADFCB  extz XHL
	ld	bc, (xhl+1)                             ; FADFCD  ld BC,(XHL+0x01)
	and	bc, 60                                 ; FADFD0  and BC,0x003c
	cp	bc, 4:i3                                  ; FADFD4  cp BC,4
	jr z, Voice_RestageRegs0100_0140_ForList__FADFEC                   ; FADFD6  jr Z,0xfadfec
	cp	bc, 8                                   ; FADFD8  cp BC,0x0008
	jr z, Voice_RestageRegs0100_0140_ForList__FADFEC                   ; FADFDC  jr Z,0xfadfec
	cp	bc, 16                                  ; FADFDE  cp BC,0x0010
	jr z, Voice_RestageRegs0100_0140_ForList__FADFF3                   ; FADFE2  jr Z,0xfadff3
	cp	bc, 32                                  ; FADFE4  cp BC,0x0020
	jr z, Voice_RestageRegs0100_0140_ForList__FADFEC                   ; FADFE8  jr Z,0xfadfec
	jr Voice_RestageRegs0100_0140_ForList__FAE009                      ; FADFEA  jr T,0xfae009
Voice_RestageRegs0100_0140_ForList__FADFEC:
	pushw	hl                                   ; FADFEC  push HL
	call	Voice_StagePair_Reg0100_0140_AB                              ; FADFED  call 0xfa919b
	jr Voice_RestageRegs0100_0140_ForList__FADFF8                      ; FADFF1  jr T,0xfadff8
Voice_RestageRegs0100_0140_ForList__FADFF3:
	pushw	hl                                   ; FADFF3  push HL
	call	Voice_StagePair_Reg0100_0140_CD                              ; FADFF4  call 0xfa92a5
Voice_RestageRegs0100_0140_ForList__FADFF8:
	popw	bc                                    ; FADFF8  pop BC
	lda	xbc, (0xD75E:24)                       ; FADFF9  lda XBC,0x00d75e
	push	xbc                                   ; FADFFE  push XBC
	ld	a, (xix)                                ; FADFFF  ld A,(XIX)
	extz	wa                                    ; FAE001  extz WA
	pushw	wa                                   ; FAE003  push WA
	calr Dev10C_SetChanReg_0100_0140                 ; FAE004  calr 0xfacf3c
	inc	6, xsp                                 ; FAE007  inc 6,XSP
Voice_RestageRegs0100_0140_ForList__FAE009:
	inc	1, xix                                 ; FAE009  inc 1,XIX
	jr Voice_RestageRegs0100_0140_ForList__FADFBC                      ; FAE00B  jr T,0xfadfbc
Voice_RestageRegs0100_0140_ForList__FAE00D:
	pop	xix                                    ; FAE00D  pop XIX
	popw	de                                    ; FAE00E  pop DE
	pop	xhl                                    ; FAE00F  pop XHL
	unlk32 xiz                                 ; FAE010  unlk XIZ
	ret                                        ; FAE012  ret
; --------------------------------------------------------------------------
; sub_FAE013 -- 0xFAE013..0xFAE0A0 (142 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAE238
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFAA87E = Voice_StageRegs_0840_0880_AB, 0xFAAC00 = Voice_StageRegs_0840_0880_CD
;          0xFACF78 = Dev10C_SetChanReg_0840_0880_dup
; Voice record: touches voice_record[+0x01(r), +0x05(r), +0x13(r)] -- pointer built in place.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFAE013-0xFAE0A0
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; REFUSED (round 10): this is one of the six voice-list walkers
;          notes/prom_c_record68_round10.py --restage selects, and THREE of the six
;          end in the SAME register pair 0x0840/0x0880 --
;          sub_FADE2F through Dev10C_SetChanReg_0840_0880 (`calr 0xfacea2`,
;          0xFADE9B), sub_FAE013 and sub_FAE0A1 through ..._dup (`calr 0xfacf78`,
;          0xFAE092 and 0xFAE0F8), and the tree's own name for the second says it
;          writes the same two registers.  So `Voice_RestageRegs0840_0880_ForList`
;          would be true of all three and identify none.  The only discriminators
;          are the class mask each accepts out of record[+0x01] & 0x3C (0xFADE53,
;          0xFAE037, 0xFAE0C4) and a flag byte pushed to the CD stager, and
;          neither has an established meaning in this tree.  So it keeps its
;          address, and this is the reason rather than a shrug.
; --------------------------------------------------------------------------
sub_FAE013:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAE013  link XIZ,0x0000
	push	xhl                                   ; FAE017  push XHL
	pushw	de                                   ; FAE018  push DE
	push	xix                                   ; FAE019  push XIX
	ldw	de, 0x3BCF                             ; FAE01A  ld DE,0x3bcf
	ld	xix, (xiz+8)                            ; FAE01D  ld XIX,(XIZ+0x08)
	inc	5, xix                                 ; FAE020  inc 5,XIX
sub_FAE013__FAE022:
	ld	h, (xix)                                ; FAE022  ld H,(XIX)
	cp	h, 64                                   ; FAE024  cp H,0x40
	jrl nc, sub_FAE013__FAE09B                 ; FAE027  jrl NC,0xfae09b
	ld	c, 68:opc                                  ; FAE02A  ld C,0x44
	mul8rr	c, h                                ; FAE02C  mul BC,H
	ld	hl, bc                                  ; FAE02E  ld HL,BC
	add	hl, de                                 ; FAE030  add HL,DE
	extz	xhl                                   ; FAE032  extz XHL
	ld	bc, (xhl+1)                             ; FAE034  ld BC,(XHL+0x01)
	and	bc, 60                                 ; FAE037  and BC,0x003c
	cp	bc, 4:i3                                  ; FAE03B  cp BC,4
	jr z, sub_FAE013__FAE053                   ; FAE03D  jr Z,0xfae053
	cp	bc, 8                                   ; FAE03F  cp BC,0x0008
	jr z, sub_FAE013__FAE097                   ; FAE043  jr Z,0xfae097
	cp	bc, 16                                  ; FAE045  cp BC,0x0010
	jr z, sub_FAE013__FAE067                   ; FAE049  jr Z,0xfae067
	cp	bc, 32                                  ; FAE04B  cp BC,0x0020
	jr z, sub_FAE013__FAE053                   ; FAE04F  jr Z,0xfae053
	jr sub_FAE013__FAE097                      ; FAE051  jr T,0xfae097
sub_FAE013__FAE053:
	extz	xhl                                   ; FAE053  extz XHL
	ld	c, (xhl+5)                              ; FAE055  ld C,(XHL+0x05)
	and	c, 0x80                                ; FAE058  and C,0x80
	jr z, sub_FAE013__FAE097                   ; FAE05B  jr Z,0xfae097
	pushw	1                                    ; FAE05D  push 0x0001
	pushw	hl                                   ; FAE060  push HL
	call	Voice_StageRegs_0840_0880_AB                              ; FAE061  call 0xfaa87e
	jr sub_FAE013__FAE086                      ; FAE065  jr T,0xfae086
sub_FAE013__FAE067:
	extz	xhl                                   ; FAE067  extz XHL
	ld	xbc, (xhl+19)                           ; FAE069  ld XBC,(XHL+0x13)
	ld	a, (xbc+13)                             ; FAE06C  ld A,(XBC+0x0d)
	and	a, 32                                  ; FAE06F  and A,0x20
	jr z, sub_FAE013__FAE07E                   ; FAE072  jr Z,0xfae07e
	extz	xhl                                   ; FAE074  extz XHL
	ld	c, (xhl+5)                              ; FAE076  ld C,(XHL+0x05)
	and	c, 0x80                                ; FAE079  and C,0x80
	jr z, sub_FAE013__FAE097                   ; FAE07C  jr Z,0xfae097
sub_FAE013__FAE07E:
	pushw	1                                    ; FAE07E  push 0x0001
	pushw	hl                                   ; FAE081  push HL
	call	Voice_StageRegs_0840_0880_CD                              ; FAE082  call 0xfaac00
sub_FAE013__FAE086:
	pop	xiy                                    ; FAE086  pop XIY
	lda	xbc, (0xD75E:24)                       ; FAE087  lda XBC,0x00d75e
	push	xbc                                   ; FAE08C  push XBC
	ld	a, (xix)                                ; FAE08D  ld A,(XIX)
	extz	wa                                    ; FAE08F  extz WA
	pushw	wa                                   ; FAE091  push WA
	calr Dev10C_SetChanReg_0840_0880_dup                 ; FAE092  calr 0xfacf78
	inc	6, xsp                                 ; FAE095  inc 6,XSP
sub_FAE013__FAE097:
	inc	1, xix                                 ; FAE097  inc 1,XIX
	jr sub_FAE013__FAE022                      ; FAE099  jr T,0xfae022
sub_FAE013__FAE09B:
	pop	xix                                    ; FAE09B  pop XIX
	popw	de                                    ; FAE09C  pop DE
	pop	xhl                                    ; FAE09D  pop XHL
	unlk32 xiz                                 ; FAE09E  unlk XIZ
	ret                                        ; FAE0A0  ret
; --------------------------------------------------------------------------
; sub_FAE0A1 -- 0xFAE0A1..0xFAE108 (104 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFBD5EB in sub_FBD46B__FBD5DB
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFAA96C = Voice_StageRegs_0800_CD, 0xFAAC00 = Voice_StageRegs_0840_0880_CD
;          0xFACF78 = Dev10C_SetChanReg_0840_0880_dup
; Voice record: touches voice_record[+0x01(r)] -- pointer built in place.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFAE0A1-0xFAE108
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; REFUSED (round 10): this is one of the six voice-list walkers
;          notes/prom_c_record68_round10.py --restage selects, and THREE of the six
;          end in the SAME register pair 0x0840/0x0880 --
;          sub_FADE2F through Dev10C_SetChanReg_0840_0880 (`calr 0xfacea2`,
;          0xFADE9B), sub_FAE013 and sub_FAE0A1 through ..._dup (`calr 0xfacf78`,
;          0xFAE092 and 0xFAE0F8), and the tree's own name for the second says it
;          writes the same two registers.  So `Voice_RestageRegs0840_0880_ForList`
;          would be true of all three and identify none.  The only discriminators
;          are the class mask each accepts out of record[+0x01] & 0x3C (0xFADE53,
;          0xFAE037, 0xFAE0C4) and a flag byte pushed to the CD stager, and
;          neither has an established meaning in this tree.  So it keeps its
;          address, and this is the reason rather than a shrug.
; --------------------------------------------------------------------------
sub_FAE0A1:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAE0A1  link XIZ,0x0000
	push	xhl                                   ; FAE0A5  push XHL
	pushw	de                                   ; FAE0A6  push DE
	push	xix                                   ; FAE0A7  push XIX
	ldw	de, 0x3BCF                             ; FAE0A8  ld DE,0x3bcf
	ld	xix, (xiz+8)                            ; FAE0AB  ld XIX,(XIZ+0x08)
	inc	5, xix                                 ; FAE0AE  inc 5,XIX
sub_FAE0A1__FAE0B0:
	ld	h, (xix)                                ; FAE0B0  ld H,(XIX)
	cp	h, 64                                   ; FAE0B2  cp H,0x40
	jr nc, sub_FAE0A1__FAE103                  ; FAE0B5  jr NC,0xfae103
	ld	c, 68:opc                                  ; FAE0B7  ld C,0x44
	mul8rr	c, h                                ; FAE0B9  mul BC,H
	ld	hl, bc                                  ; FAE0BB  ld HL,BC
	add	hl, de                                 ; FAE0BD  add HL,DE
	extz	xhl                                   ; FAE0BF  extz XHL
	ld	bc, (xhl+1)                             ; FAE0C1  ld BC,(XHL+0x01)
	and	bc, 60                                 ; FAE0C4  and BC,0x003c
	cp	bc, 4:i3                                  ; FAE0C8  cp BC,4
	jr z, sub_FAE0A1__FAE0FF                   ; FAE0CA  jr Z,0xfae0ff
	cp	bc, 8                                   ; FAE0CC  cp BC,0x0008
	jr z, sub_FAE0A1__FAE0FF                   ; FAE0D0  jr Z,0xfae0ff
	cp	bc, 16                                  ; FAE0D2  cp BC,0x0010
	jr z, sub_FAE0A1__FAE0E0                   ; FAE0D6  jr Z,0xfae0e0
	cp	bc, 32                                  ; FAE0D8  cp BC,0x0020
	jr z, sub_FAE0A1__FAE0FF                   ; FAE0DC  jr Z,0xfae0ff
	jr sub_FAE0A1__FAE0FF                      ; FAE0DE  jr T,0xfae0ff
sub_FAE0A1__FAE0E0:
	pushw	hl                                   ; FAE0E0  push HL
	call	Voice_StageRegs_0800_CD                              ; FAE0E1  call 0xfaa96c
	pushw	0                                    ; FAE0E5  push 0x0000
	pushw	hl                                   ; FAE0E8  push HL
	call	Voice_StageRegs_0840_0880_CD                              ; FAE0E9  call 0xfaac00
	lda	xbc, (0xD75E:24)                       ; FAE0ED  lda XBC,0x00d75e
	push	xbc                                   ; FAE0F2  push XBC
	ld	a, (xix)                                ; FAE0F3  ld A,(XIX)
	extz	wa                                    ; FAE0F5  extz WA
	pushw	wa                                   ; FAE0F7  push WA
	calr Dev10C_SetChanReg_0840_0880_dup                 ; FAE0F8  calr 0xfacf78
	inc	8, xsp                                 ; FAE0FB  inc 0,XSP
	inc	4, xsp                                 ; FAE0FD  inc 4,XSP
sub_FAE0A1__FAE0FF:
	inc	1, xix                                 ; FAE0FF  inc 1,XIX
	jr sub_FAE0A1__FAE0B0                      ; FAE101  jr T,0xfae0b0
sub_FAE0A1__FAE103:
	pop	xix                                    ; FAE103  pop XIX
	popw	de                                    ; FAE104  pop DE
	pop	xhl                                    ; FAE105  pop XHL
	unlk32 xiz                                 ; FAE106  unlk XIZ
	ret                                        ; FAE108  ret
; --------------------------------------------------------------------------
; PartRec_ApplyParam_001D -- 0xFAE109..0xFAE15E (86 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAF159
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Calls:   0xFAD142 = sub_FAD142, 0xFAD2D5 = sub_FAD2D5
;          0xFADD29 = sub_FADD29, 0xFB3CE0 = VoiceQuery_Tag00_Part
; Evidence: the listing below is the byte-identical round-trip of 0xFAE109-0xFAE15E
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7 finish pass).  APPLIES ONE WORD OF THE PART RECORD'S 12-WORD
;          PARAMETER BLOCK: it stores its normalised argument into part_record
;          +0x1D and then marks that parameter.
;          `mul BC,0x012C` (part-record stride) and `add BC,0x001D` at 0xFAE12A select
;          the word; `ld (XBC+0x1523),WA` at 0xFAE130 stores it.
;          ⚠ THE NAME IS FRAMED, NOT CONTENT, AND DELIBERATELY SO: +0x1D is the
;          field's OFFSET, which is an instruction operand.  What the parameter IS
;          is NOT established -- see the block comment above PartRec_ApplyParam_001D.
;          Reached through ENTRY 0 of Voice_ApplyParamChange_Dispatch's 49-entry
;          table at 0xFAF08F, whose word holds 0xFAF153, and that arm calls here.
;          ⚠ ENTRY NUMBER AND TARGET CODE ARE NOT THE SAME NUMBER: `dec 1,BC` at
;          0xFAF079 runs before the index, so entry 0 is RAW TARGET CODE 1.
;          An earlier draft of this header printed one number under both names and
;          had the arm index off by one as well; the ROM table and the arm's own
;          call are re-read by notes/prom_c_finish_round7.py --selftest.
; --------------------------------------------------------------------------
PartRec_ApplyParam_001D:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAE109  link XIZ,0x0000
	pushw	hl                                   ; FAE10D  push HL
	pushw	de                                   ; FAE10E  push DE
	ld	h, (xiz+8)                              ; FAE10F  ld H,(XIZ+0x08)
	ld	xbc, (xiz+12)                           ; FAE112  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FAE115  push XBC
	extpfx3 0x9E, 0x0A, 0x04                   ; FAE116  pushw (XIZ+0x0a)
	push	0                                     ; FAE119  push 0x00
	push	h                                     ; FAE11B  push H
	calr sub_FAD2D5                 ; FAE11D  calr 0xfad2d5
	ld	de, wa                                  ; FAE120  ld DE,WA
	ld	c, h                                    ; FAE122  ld C,H
	extz	bc                                    ; FAE124  extz BC
	mul	bc, 0x12C                              ; FAE126  mul BC,0x012c
	add	bc, 29                                 ; FAE12A  add BC,0x001d
	extz	xbc                                   ; FAE12E  extz XBC
	ld	(xbc+0x1523), wa                        ; FAE130  ld (XBC+0x1523),WA
	pushw	32                                   ; FAE135  push 0x0020
	pushw	16                                   ; FAE138  push 0x0010
	ld	xbc, (xiz+12)                           ; FAE13B  ld XBC,(XIZ+0x0c)
	ld	a, (xbc)                                ; FAE13E  ld A,(XBC)
	pushw	wa                                   ; FAE140  push WA
	push	0                                     ; FAE141  push 0x00
	push	h                                     ; FAE143  push H
	calr sub_FAD142                 ; FAE145  calr 0xfad142
	push	0                                     ; FAE148  push 0x00
	push	h                                     ; FAE14A  push H
	call	VoiceQuery_Tag00_Part                              ; FAE14C  call 0xfb3ce0
	push	xiy                                   ; FAE150  push XIY
	calr sub_FADD29                 ; FAE151  calr 0xfadd29
	add	xsp, 22                                ; FAE154  add XSP,0x00000016
	popw	de                                    ; FAE15A  pop DE
	popw	hl                                    ; FAE15B  pop HL
	unlk32 xiz                                 ; FAE15C  unlk XIZ
	ret                                        ; FAE15E  ret
; --------------------------------------------------------------------------
; PartRec_ApplyParam_0021 -- 0xFAE15F..0xFAE1B1 (83 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAF171
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Calls:   0xFAD142 = sub_FAD142, 0xFAD5C2 = Scale7Bit_ByDepth_UniOrBipolar
;          0xFADFAD = Voice_RestageRegs0100_0140_ForList, 0xFB3CE0 = VoiceQuery_Tag00_Part
; Evidence: the listing below is the byte-identical round-trip of 0xFAE15F-0xFAE1B1
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7 finish pass).  APPLIES ONE WORD OF THE PART RECORD'S 12-WORD
;          PARAMETER BLOCK: it stores its normalised argument into part_record
;          +0x21 and then marks that parameter.
;          `mul BC,0x012C` (part-record stride) and `add BC,0x0021` at 0xFAE17D select
;          the word; `ld (XBC+0x1523),WA` at 0xFAE183 stores it.
;          ⚠ THE NAME IS FRAMED, NOT CONTENT, AND DELIBERATELY SO: +0x21 is the
;          field's OFFSET, which is an instruction operand.  What the parameter IS
;          is NOT established -- see the block comment above PartRec_ApplyParam_001D.
;          Reached through ENTRY 2 of Voice_ApplyParamChange_Dispatch's 49-entry
;          table at 0xFAF08F, whose word holds 0xFAF16B, and that arm calls here.
;          ⚠ ENTRY NUMBER AND TARGET CODE ARE NOT THE SAME NUMBER: `dec 1,BC` at
;          0xFAF079 runs before the index, so entry 2 is RAW TARGET CODE 3.
;          An earlier draft of this header printed one number under both names and
;          had the arm index off by one as well; the ROM table and the arm's own
;          call are re-read by notes/prom_c_finish_round7.py --selftest.
;          ⚠ It does NOT call PartRec_SetOrClearParamBits_x4; its push of 0x0080
;          goes to a different callee, and an earlier draft of this round's table
;          read it as a change mask.  It is not.
; --------------------------------------------------------------------------
PartRec_ApplyParam_0021:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAE15F  link XIZ,0x0000
	pushw	hl                                   ; FAE163  push HL
	pushw	de                                   ; FAE164  push DE
	ld	h, (xiz+8)                              ; FAE165  ld H,(XIZ+0x08)
	ld	xbc, (xiz+12)                           ; FAE168  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FAE16B  push XBC
	ld	a, (xiz+10)                             ; FAE16C  ld A,(XIZ+0x0a)
	pushw	wa                                   ; FAE16F  push WA
	calr Scale7Bit_ByDepth_UniOrBipolar                 ; FAE170  calr 0xfad5c2
	ld	de, wa                                  ; FAE173  ld DE,WA
	ld	c, h                                    ; FAE175  ld C,H
	extz	bc                                    ; FAE177  extz BC
	mul	bc, 0x12C                              ; FAE179  mul BC,0x012c
	add	bc, 33                                 ; FAE17D  add BC,0x0021
	extz	xbc                                   ; FAE181  extz XBC
	ld	(xbc+0x1523), wa                        ; FAE183  ld (XBC+0x1523),WA
	pushw	0x80                                 ; FAE188  push 0x0080
	pushw	64                                   ; FAE18B  push 0x0040
	ld	xbc, (xiz+12)                           ; FAE18E  ld XBC,(XIZ+0x0c)
	ld	a, (xbc)                                ; FAE191  ld A,(XBC)
	pushw	wa                                   ; FAE193  push WA
	push	0                                     ; FAE194  push 0x00
	push	h                                     ; FAE196  push H
	calr sub_FAD142                 ; FAE198  calr 0xfad142
	push	0                                     ; FAE19B  push 0x00
	push	h                                     ; FAE19D  push H
	call	VoiceQuery_Tag00_Part                              ; FAE19F  call 0xfb3ce0
	push	xiy                                   ; FAE1A3  push XIY
	calr Voice_RestageRegs0100_0140_ForList                 ; FAE1A4  calr 0xfadfad
	add	xsp, 20                                ; FAE1A7  add XSP,0x00000014
	popw	de                                    ; FAE1AD  pop DE
	popw	hl                                    ; FAE1AE  pop HL
	unlk32 xiz                                 ; FAE1AF  unlk XIZ
	ret                                        ; FAE1B1  ret
; --------------------------------------------------------------------------
; PartRec_ApplyParam_001F -- 0xFAE1B2..0xFAE241 (144 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAF165
; Inputs:  frame `link XIZ,-2`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Calls:   0xFAD142 = sub_FAD142, 0xFAD625 = Scale7Bit_ByDepth_UniOrBipolar_Shl6
;          0xFAE013 = sub_FAE013, 0xFB3CB4 = VoiceQuery_Tag00_PartBit7
;          0xFB3CE0 = VoiceQuery_Tag00_Part
; Evidence: the listing below is the byte-identical round-trip of 0xFAE1B2-0xFAE241
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7 finish pass).  APPLIES ONE WORD OF THE PART RECORD'S 12-WORD
;          PARAMETER BLOCK: it stores its normalised argument into part_record
;          +0x1F and then marks that parameter.
;          `mul BC,0x012C` (part-record stride) and `add BC,0x001F` at 0xFAE1D4 select
;          the word; `ld (XBC+0x1523),WA` at 0xFAE1DA stores it.
;          ⚠ THE NAME IS FRAMED, NOT CONTENT, AND DELIBERATELY SO: +0x1F is the
;          field's OFFSET, which is an instruction operand.  What the parameter IS
;          is NOT established -- see the block comment above PartRec_ApplyParam_001D.
;          Reached through ENTRY 1 of Voice_ApplyParamChange_Dispatch's 49-entry
;          table at 0xFAF08F, whose word holds 0xFAF15F, and that arm calls here.
;          ⚠ ENTRY NUMBER AND TARGET CODE ARE NOT THE SAME NUMBER: `dec 1,BC` at
;          0xFAF079 runs before the index, so entry 1 is RAW TARGET CODE 2.
;          An earlier draft of this header printed one number under both names and
;          had the arm index off by one as well; the ROM table and the arm's own
;          call are re-read by notes/prom_c_finish_round7.py --selftest.
;          ⚠ It does NOT call PartRec_SetOrClearParamBits_x4; its two pushes of
;          0x0200 and 0x0100 go to a different callee, and an earlier draft of this
;          round's table read them as change masks.  They are not.
; --------------------------------------------------------------------------
PartRec_ApplyParam_001F:
	link32 0xEE, 0x0C, 0xFE, 0xFF              ; FAE1B2  link XIZ,0xfffe
	pushw	hl                                   ; FAE1B6  push HL
	pushw	de                                   ; FAE1B7  push DE
	push	xix                                   ; FAE1B8  push XIX
	ld	h, (xiz+8)                              ; FAE1B9  ld H,(XIZ+0x08)
	ld	xbc, (xiz+12)                           ; FAE1BC  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FAE1BF  push XBC
	ld	a, (xiz+10)                             ; FAE1C0  ld A,(XIZ+0x0a)
	pushw	wa                                   ; FAE1C3  push WA
	calr Scale7Bit_ByDepth_UniOrBipolar_Shl6                 ; FAE1C4  calr 0xfad625
	ld	de, wa                                  ; FAE1C7  ld DE,WA
	ld	c, h                                    ; FAE1C9  ld C,H
	extz	bc                                    ; FAE1CB  extz BC
	mul	bc, 0x12C                              ; FAE1CD  mul BC,0x012c
	ld	(xiz-2), bc                             ; FAE1D1  ld (XIZ+0xfe),BC
	add	bc, 31                                 ; FAE1D4  add BC,0x001f
	extz	xbc                                   ; FAE1D8  extz XBC
	ld	(xbc+0x1523), wa                        ; FAE1DA  ld (XBC+0x1523),WA
	pushw	0x200                                ; FAE1DF  push 0x0200
	pushw	0x100                                ; FAE1E2  push 0x0100
	ld	xbc, (xiz+12)                           ; FAE1E5  ld XBC,(XIZ+0x0c)
	ld	a, (xbc)                                ; FAE1E8  ld A,(XBC)
	pushw	wa                                   ; FAE1EA  push WA
	push	0                                     ; FAE1EB  push 0x00
	push	h                                     ; FAE1ED  push H
	calr sub_FAD142                 ; FAE1EF  calr 0xfad142
	ld	bc, (xiz-2)                             ; FAE1F2  ld BC,(XIZ+0xfe)
	extz	xbc                                   ; FAE1F5  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FAE1F7  ld XWA,(XBC+0x1523)
	ld	c, (xwa+16)                             ; FAE1FC  ld C,(XWA+0x10)
	and	c, 0xC0                                ; FAE1FF  and C,0xc0
	extz	bc                                    ; FAE202  extz BC
	inc	8, xsp                                 ; FAE204  inc 0,XSP
	inc	6, xsp                                 ; FAE206  inc 6,XSP
	cp	bc, 0:i3                                  ; FAE208  cp BC,0
	jr z, sub_FAE1B2__FAE220                   ; FAE20A  jr Z,0xfae220
	cp	bc, 64                                  ; FAE20C  cp BC,0x0040
	jr z, sub_FAE1B2__FAE237                   ; FAE210  jr Z,0xfae237
	cp	bc, 0x80                                ; FAE212  cp BC,0x0080
	jr z, sub_FAE1B2__FAE22C                   ; FAE216  jr Z,0xfae22c
	cp	bc, 0xC0                                ; FAE218  cp BC,0x00c0
	jr z, sub_FAE1B2__FAE237                   ; FAE21C  jr Z,0xfae237
	jr sub_FAE1B2__FAE237                      ; FAE21E  jr T,0xfae237
sub_FAE1B2__FAE220:
	push	0                                     ; FAE220  push 0x00
	push	h                                     ; FAE222  push H
	call	VoiceQuery_Tag00_PartBit7                              ; FAE224  call 0xfb3cb4
	ld	xix, xiy                                ; FAE228  ld XIX,XIY
	jr sub_FAE1B2__FAE236                      ; FAE22A  jr T,0xfae236
sub_FAE1B2__FAE22C:
	push	0                                     ; FAE22C  push 0x00
	push	h                                     ; FAE22E  push H
	call	VoiceQuery_Tag00_Part                              ; FAE230  call 0xfb3ce0
	ld	xix, xiy                                ; FAE234  ld XIX,XIY
sub_FAE1B2__FAE236:
	popw	bc                                    ; FAE236  pop BC
sub_FAE1B2__FAE237:
	push	xix                                   ; FAE237  push XIX
	calr sub_FAE013                 ; FAE238  calr 0xfae013
	pop	xbc                                    ; FAE23B  pop XBC
	pop	xix                                    ; FAE23C  pop XIX
	popw	de                                    ; FAE23D  pop DE
	popw	hl                                    ; FAE23E  pop HL
	unlk32 xiz                                 ; FAE23F  unlk XIZ
	ret                                        ; FAE241  ret
; --------------------------------------------------------------------------
; Voice_RestageArm_BaseCurve_Shared -- 0xFAE242..0xFAE2C5 (132 bytes)
;
; Called from: no site outside this module.
;          3 site(s) inside this module:
;          0xFAE386 0xFAE603 0xFAE884
; Inputs:  frame `link XIZ,-2`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C), (XIZ+0x10), (XIZ+0x12)
; Outputs: no absolute-addressed write.
; Calls:   0xFAD37E = sub_FAD37E, 0xFB501F = sub_FB501F
;          0xFB53C5 = sub_FB53C5
; Evidence: the listing below is the byte-identical round-trip of 0xFAE242-0xFAE2C5
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ ROUND 6 ------------------------------------------------------------
; Voice_RestageArm_BaseCurve_Shared -- the body
;          the three BASE restage arms share.  Its ONLY call sites are 0xFAE386 in
;          Voice_Restage_Reg0440_BaseCurve_ForPart, 0xFAE603 in
;          Voice_Restage_Reg0180_BaseCurve_ForPart and 0xFAE884 in
;          Voice_Restage_Reg04C0_BaseCurve_ForPart -- three of three, and nothing else in the
;          512 KiB.  Its value-curve counterpart is Voice_RestageArm_ValueCurve_Shared, whose
;          three call sites are the other three arms.
;          The two are 132 bytes each and differ in which helper they call (0xFAD37E and
;          0xFB501F here, 0xFAD43E and 0xFB5103 there); they share 0xFB53C5.
;          ⚠ NOT ESTABLISHED: what any of those helpers computes.  The name records the
;          PARTITION -- base arms here, value arms there -- which is a call census, and
;          nothing else.
;          Evidence: the call sites are the routine's own Called-from census, reproduced by
;          `python3 notes/prom_c_understanding_round6.py --names`.
; --------------------------------------------------------------------------
Voice_RestageArm_BaseCurve_Shared:
	link32 0xEE, 0x0C, 0xFE, 0xFF              ; FAE242  link XIZ,0xfffe
	pushw	hl                                   ; FAE246  push HL
	pushw	de                                   ; FAE247  push DE
	pushw	ix                                   ; FAE248  push IX
	ld	e, (xiz+18)                             ; FAE249  ld E,(XIZ+0x12)
	ld	d, (xiz+8)                              ; FAE24C  ld D,(XIZ+0x08)
	pushw	de                                   ; FAE24F  push DE
	push	0                                     ; FAE250  push 0x00
	extpfx3 0x8E, 0x10, 0x04                   ; FAE252  push (XIZ+0x10)
	ld	xbc, (xiz+12)                           ; FAE255  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FAE258  push XBC
	push	0                                     ; FAE259  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FAE25B  push (XIZ+0x0a)
	push	0                                     ; FAE25E  push 0x00
	push	d                                     ; FAE260  push D
	calr sub_FAD37E                 ; FAE262  calr 0xfad37e
	ld	l, a                                    ; FAE265  ld L,A
	ld	c, 16:opc                                  ; FAE267  ld C,0x10
	mul8rr	c, e                                ; FAE269  mul BC,E
	ld	ix, bc                                  ; FAE26B  ld IX,BC
	ld	a, d                                    ; FAE26D  ld A,D
	extz	wa                                    ; FAE26F  extz WA
	mul	wa, 0x12C                              ; FAE271  mul WA,0x012c
	add	wa, bc                                 ; FAE275  add WA,BC
	ld	(xiz-2), wa                             ; FAE277  ld (XIZ+0xfe),WA
	ld	c, 4:opc                                   ; FAE27A  ld C,0x04
	extpfx3 0x8E, 0x10, 0x43                   ; FAE27C  mul BC,(XIZ+0x10)
	add	wa, bc                                 ; FAE27F  add WA,BC
	add	wa, 56                                 ; FAE281  add WA,0x0038
	extz	xwa                                   ; FAE285  extz XWA
	ld	(xwa+0x1523), l                         ; FAE287  ld (XWA+0x1523),L
	push	0                                     ; FAE28C  push 0x00
	extpfx3 0x8E, 0x10, 0x04                   ; FAE28E  push (XIZ+0x10)
	pushw	de                                   ; FAE291  push DE
	push	0                                     ; FAE292  push 0x00
	push	d                                     ; FAE294  push D
	call	sub_FB501F                              ; FAE296  call 0xfb501f
	ld	h, 0:opc                                   ; FAE29A  ld H,0x00
	add	xsp, 18                                ; FAE29C  add XSP,0x00000012
Voice_RestageArm_BaseCurve_Shared__FAE2A2:
	pushw	de                                   ; FAE2A2  push DE
	ld	(xiz-2), h                              ; FAE2A3  ld (XIZ+0xfe),H
	push	0                                     ; FAE2A6  push 0x00
	extpfx3 0x8E, 0xFE, 0x04                   ; FAE2A8  push (XIZ+0xfe)
	push	0                                     ; FAE2AB  push 0x00
	push	d                                     ; FAE2AD  push D
	call	sub_FB53C5                              ; FAE2AF  call 0xfb53c5
	ld	h, (xiz-2)                              ; FAE2B3  ld H,(XIZ+0xfe)
	inc	1, h                                   ; FAE2B6  inc 1,H
	inc	6, xsp                                 ; FAE2B8  inc 6,XSP
	cp	h, 4:i3                                   ; FAE2BA  cp H,4
	jr c, Voice_RestageArm_BaseCurve_Shared__FAE2A2                   ; FAE2BC  jr C,0xfae2a2
	ld	a, l                                    ; FAE2BE  ld A,L
	popw	ix                                    ; FAE2C0  pop IX
	popw	de                                    ; FAE2C1  pop DE
	popw	hl                                    ; FAE2C2  pop HL
	unlk32 xiz                                 ; FAE2C3  unlk XIZ
	ret                                        ; FAE2C5  ret
; --------------------------------------------------------------------------
; Voice_RestageArm_ValueCurve_Shared -- 0xFAE2C6..0xFAE349 (132 bytes)
;
; Called from: no site outside this module.
;          3 site(s) inside this module:
;          0xFAE4C0 0xFAE73F 0xFAE9C2
; Inputs:  frame `link XIZ,-2`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C), (XIZ+0x10), (XIZ+0x12)
; Outputs: no absolute-addressed write.
; Calls:   0xFAD43E = sub_FAD43E, 0xFB5103 = sub_FB5103
;          0xFB53C5 = sub_FB53C5
; Evidence: the listing below is the byte-identical round-trip of 0xFAE2C6-0xFAE349
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ ROUND 6 ------------------------------------------------------------
; Voice_RestageArm_ValueCurve_Shared -- the body
;          the three VALUE restage arms share; call sites 0xFAE4C0, 0xFAE73F and 0xFAE9C2,
;          three of three and nothing else.  See Voice_RestageArm_BaseCurve_Shared above for
;          the partition and for what it does NOT establish.
; --------------------------------------------------------------------------
Voice_RestageArm_ValueCurve_Shared:
	link32 0xEE, 0x0C, 0xFE, 0xFF              ; FAE2C6  link XIZ,0xfffe
	pushw	hl                                   ; FAE2CA  push HL
	pushw	de                                   ; FAE2CB  push DE
	pushw	ix                                   ; FAE2CC  push IX
	ld	e, (xiz+18)                             ; FAE2CD  ld E,(XIZ+0x12)
	ld	d, (xiz+8)                              ; FAE2D0  ld D,(XIZ+0x08)
	pushw	de                                   ; FAE2D3  push DE
	push	0                                     ; FAE2D4  push 0x00
	extpfx3 0x8E, 0x10, 0x04                   ; FAE2D6  push (XIZ+0x10)
	ld	xbc, (xiz+12)                           ; FAE2D9  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FAE2DC  push XBC
	push	0                                     ; FAE2DD  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FAE2DF  push (XIZ+0x0a)
	push	0                                     ; FAE2E2  push 0x00
	push	d                                     ; FAE2E4  push D
	calr sub_FAD43E                 ; FAE2E6  calr 0xfad43e
	ld	l, a                                    ; FAE2E9  ld L,A
	ld	c, 16:opc                                  ; FAE2EB  ld C,0x10
	mul8rr	c, e                                ; FAE2ED  mul BC,E
	ld	ix, bc                                  ; FAE2EF  ld IX,BC
	ld	a, d                                    ; FAE2F1  ld A,D
	extz	wa                                    ; FAE2F3  extz WA
	mul	wa, 0x12C                              ; FAE2F5  mul WA,0x012c
	add	wa, bc                                 ; FAE2F9  add WA,BC
	ld	(xiz-2), wa                             ; FAE2FB  ld (XIZ+0xfe),WA
	ld	c, 4:opc                                   ; FAE2FE  ld C,0x04
	extpfx3 0x8E, 0x10, 0x43                   ; FAE300  mul BC,(XIZ+0x10)
	add	wa, bc                                 ; FAE303  add WA,BC
	add	wa, 55                                 ; FAE305  add WA,0x0037
	extz	xwa                                   ; FAE309  extz XWA
	ld	(xwa+0x1523), l                         ; FAE30B  ld (XWA+0x1523),L
	push	0                                     ; FAE310  push 0x00
	extpfx3 0x8E, 0x10, 0x04                   ; FAE312  push (XIZ+0x10)
	pushw	de                                   ; FAE315  push DE
	push	0                                     ; FAE316  push 0x00
	push	d                                     ; FAE318  push D
	call	sub_FB5103                              ; FAE31A  call 0xfb5103
	ld	h, 0:opc                                   ; FAE31E  ld H,0x00
	add	xsp, 18                                ; FAE320  add XSP,0x00000012
Voice_RestageArm_ValueCurve_Shared__FAE326:
	pushw	de                                   ; FAE326  push DE
	ld	(xiz-2), h                              ; FAE327  ld (XIZ+0xfe),H
	push	0                                     ; FAE32A  push 0x00
	extpfx3 0x8E, 0xFE, 0x04                   ; FAE32C  push (XIZ+0xfe)
	push	0                                     ; FAE32F  push 0x00
	push	d                                     ; FAE331  push D
	call	sub_FB53C5                              ; FAE333  call 0xfb53c5
	ld	h, (xiz-2)                              ; FAE337  ld H,(XIZ+0xfe)
	inc	1, h                                   ; FAE33A  inc 1,H
	inc	6, xsp                                 ; FAE33C  inc 6,XSP
	cp	h, 4:i3                                   ; FAE33E  cp H,4
	jr c, Voice_RestageArm_ValueCurve_Shared__FAE326                   ; FAE340  jr C,0xfae326
	ld	a, l                                    ; FAE342  ld A,L
	popw	ix                                    ; FAE344  pop IX
	popw	de                                    ; FAE345  pop DE
	popw	hl                                    ; FAE346  pop HL
	unlk32 xiz                                 ; FAE347  unlk XIZ
	ret                                        ; FAE349  ret
; --------------------------------------------------------------------------
; Voice_Restage_Reg0440_BaseCurve_ForPart -- 0xFAE34A..0xFAE483 (314 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAF191
; Inputs:  frame `link XIZ,-11`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C), (XIZ+0x10)
; Outputs: writes 0x00D79E
; Calls:   0xFA6110 = VoiceSlots_ListSlotsOfPart, 0xFA796D = EGEnv_Eval_BaseCurveA
;          0xFA981B = EnvRec_LoadSlot, 0xFA9915 = Voice_StageChanSel_Reg0440_Reg0480
;          0xFACFD6 = Dev10C_SetChanReg_0440, 0xFAD01A = Dev10C_SetChanReg_0600
;          0xFAE242 = Voice_RestageArm_BaseCurve_Shared, 0xFB3CE0 = VoiceQuery_Tag00_Part
; Evidence: the listing below is the byte-identical round-trip of 0xFAE34A-0xFAE483
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ ROUND 6 ------------------------------------------------------------
; Voice_Restage_Reg0440_BaseCurve_ForPart -- one of the 49 arms of
;          Voice_ApplyParamChange_Dispatch (its ONLY caller, at 0xFAF191), and the one that
;          refreshes register 0x0440 + chan for every voice the part owns.
;          It obtains the part's voice list from VoiceQuery_Tag00_Part (0xFB3CE0), walks it
;          while the voice number is below 0x40, forms voice_record = 0x003BCF + 0x44*voice,
;          and per voice calls Voice_StageChanSel_Reg0440_Reg0480 (0xFA9915) and then Dev10C_SetChanReg_0440 (0xFACFD6).
;          Evidence: the callee addresses are instruction operands;
;          `python3 notes/prom_c_understanding_round6.py --dispatch` asserts that this arm has
;          exactly one call site and that it is inside the dispatcher, and --blocks asserts
;          which envelope block its evaluator belongs to.
;          Unknown: what register 0x0440 carries, and what the dispatcher's target code
;          for this arm means.
; --------------------------------------------------------------------------
Voice_Restage_Reg0440_BaseCurve_ForPart:
	link32 0xEE, 0x0C, 0xF5, 0xFF              ; FAE34A  link XIZ,0xfff5
	pushw	hl                                   ; FAE34E  push HL
	pushw	de                                   ; FAE34F  push DE
	push	xix                                   ; FAE350  push XIX
	ld	c, 4:opc                                   ; FAE351  ld C,0x04
	extpfx3 0x8E, 0x10, 0x43                   ; FAE353  mul BC,(XIZ+0x10)
	ld	de, bc                                  ; FAE356  ld DE,BC
	ld	wa, (xiz+8)                             ; FAE358  ld WA,(XIZ+0x08)
	extz	wa                                    ; FAE35B  extz WA
	mul	wa, 0x12C                              ; FAE35D  mul WA,0x012c
	ld	hl, wa                                  ; FAE361  ld HL,WA
	add	wa, bc                                 ; FAE363  add WA,BC
	add	wa, 56                                 ; FAE365  add WA,0x0038
	extz	xwa                                   ; FAE369  extz XWA
	ld	d, (xwa+0x1523)                         ; FAE36B  ld D,(XWA+0x1523)
	pushw	0                                    ; FAE370  push 0x0000
	push	0                                     ; FAE373  push 0x00
	extpfx3 0x8E, 0x10, 0x04                   ; FAE375  push (XIZ+0x10)
	ld	xbc, (xiz+12)                           ; FAE378  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FAE37B  push XBC
	push	0                                     ; FAE37C  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FAE37E  push (XIZ+0x0a)
	push	0                                     ; FAE381  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAE383  push (XIZ+0x08)
	calr Voice_RestageArm_BaseCurve_Shared                 ; FAE386  calr 0xfae242
	ld	(xiz-7), a                              ; FAE389  ld (XIZ+0xf9),A
	inc	8, xsp                                 ; FAE38C  inc 0,XSP
	inc	4, xsp                                 ; FAE38E  inc 4,XSP
	cp	d, 0:i3                                   ; FAE390  cp D,0
	jr nz, Voice_Restage_Reg0440_BaseCurve_ForPart__FAE3DC                  ; FAE392  jr NZ,0xfae3dc
	push	0                                     ; FAE394  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAE396  push (XIZ+0x08)
	call	VoiceQuery_Tag00_Part                              ; FAE399  call 0xfb3ce0
	ld	(xiz-11), xiy                           ; FAE39D  ld (XIZ+0xf5),XIY
	ld	bc, hl                                  ; FAE3A0  ld BC,HL
	inc	4, bc                                  ; FAE3A2  inc 4,BC
	extz	xbc                                   ; FAE3A4  extz XBC
	extpfx7 0xD3, 0xE5, 0x23, 0x15, 0x3E, 0x08, 0x00 ; FAE3A6  or (XBC+0x1523),0x0008
	ldw	de, 0x3BCF                             ; FAE3AD  ld DE,0x3bcf
	ld	xix, xiy                                ; FAE3B0  ld XIX,XIY
	inc	5, xix                                 ; FAE3B2  inc 5,XIX
	popw	bc                                    ; FAE3B4  pop BC
Voice_Restage_Reg0440_BaseCurve_ForPart__FAE3B5:
	ld	h, (xix)                                ; FAE3B5  ld H,(XIX)
	cp	h, 64                                   ; FAE3B7  cp H,0x40
	jrl nc, Voice_Restage_Reg0440_BaseCurve_ForPart__FAE47E                 ; FAE3BA  jrl NC,0xfae47e
	ld	c, 68:opc                                  ; FAE3BD  ld C,0x44
	mul8rr	c, h                                ; FAE3BF  mul BC,H
	add	bc, de                                 ; FAE3C1  add BC,DE
	pushw	bc                                   ; FAE3C3  push BC
	call	Voice_StageChanSel_Reg0440_Reg0480                              ; FAE3C4  call 0xfa9915
	lda	xbc, (0xD75E:24)                       ; FAE3C8  lda XBC,0x00d75e
	push	xbc                                   ; FAE3CD  push XBC
	ld	a, (xix)                                ; FAE3CE  ld A,(XIX)
	extz	wa                                    ; FAE3D0  extz WA
	pushw	wa                                   ; FAE3D2  push WA
	calr Dev10C_SetChanReg_0440                 ; FAE3D3  calr 0xfacfd6
	inc	1, xix                                 ; FAE3D6  inc 1,XIX
	inc	8, xsp                                 ; FAE3D8  inc 0,XSP
	jr Voice_Restage_Reg0440_BaseCurve_ForPart__FAE3B5                      ; FAE3DA  jr T,0xfae3b5
Voice_Restage_Reg0440_BaseCurve_ForPart__FAE3DC:
	pushw	32                                   ; FAE3DC  push 0x0020
	push	0                                     ; FAE3DF  push 0x00
	extpfx3 0x8E, 0x10, 0x04                   ; FAE3E1  push (XIZ+0x10)
	push	0                                     ; FAE3E4  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAE3E6  push (XIZ+0x08)
	call	VoiceSlots_ListSlotsOfPart                              ; FAE3E9  call 0xfa6110
	ld	(xiz-6), iy                             ; FAE3ED  ld (XIZ+0xfa),IY
	ldw	de, 0                                  ; FAE3F0  ld DE,0x0000
	ldw	ix, 0x1523                             ; FAE3F3  ld IX,0x1523
	ld	(xiz-4), hl                             ; FAE3F6  ld (XIZ+0xfc),HL
	ld	bc, ix                                  ; FAE3F9  ld BC,IX
	extpfx3 0x9E, 0xFC, 0x81                   ; FAE3FB  add BC,(XIZ+0xfc)
	ld	(xiz-2), bc                             ; FAE3FE  ld (XIZ+0xfe),BC
	jrl Voice_Restage_Reg0440_BaseCurve_ForPart__FAE47A                     ; FAE401  jrl T,0xfae47a
Voice_Restage_Reg0440_BaseCurve_ForPart__FAE404:
	ld	bc, (xiz-6)                             ; FAE404  ld BC,(XIZ+0xfa)
	extz	xbc                                   ; FAE407  extz XBC
	extpfx5 0xD3, 0x07, 0xE4, 0xE8, 0x23       ; FAE409  ld HL,(XBC+DE)
	ld	wa, hl                                  ; FAE40E  ld WA,HL
	and	wa, 0xFF                               ; FAE410  and WA,0x00ff
	cp	wa, 0x80                                ; FAE414  cp WA,0x0080
	jr nc, Voice_Restage_Reg0440_BaseCurve_ForPart__FAE47E                  ; FAE418  jr NC,0xfae47e
	ld	ix, hl                                  ; FAE41A  ld IX,HL
	and	ix, 0x7F                               ; FAE41C  and IX,0x007f
	extpfx3 0xC7, 0xF0, 0x89                   ; FAE420  ld A,IXL
	ld	h, a                                    ; FAE423  ld H,A
	pushw	wa                                   ; FAE425  push WA
	pushw	0                                    ; FAE426  push 0x0000
	push	0                                     ; FAE429  push 0x00
	extpfx3 0x8E, 0x10, 0x04                   ; FAE42B  push (XIZ+0x10)
	extpfx3 0x9E, 0xFE, 0x04                   ; FAE42E  pushw (XIZ+0xfe)
	push	0                                     ; FAE431  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAE433  push (XIZ+0x08)
	call	EnvRec_LoadSlot                              ; FAE436  call 0xfa981b
	inc	8, xsp                                 ; FAE43A  inc 0,XSP
	inc	2, xsp                                 ; FAE43C  inc 2,XSP
	cp (xiz-7), 0x00                           ; FAE43E  cp (XIZ+0xf9),0x00
	jr nz, Voice_Restage_Reg0440_BaseCurve_ForPart__FAE45B                  ; FAE442  jr NZ,0xfae45b
	ld	bc, (xiz-4)                             ; FAE444  ld BC,(XIZ+0xfc)
	inc	4, bc                                  ; FAE447  inc 4,BC
	extz	xbc                                   ; FAE449  extz XBC
	extpfx7 0xD3, 0xE5, 0x23, 0x15, 0x3E, 0x08, 0x00 ; FAE44B  or (XBC+0x1523),0x0008
	ldw	(0xD79E:24), 0                        ; FAE452  ld (0x00d79e),0x0000
	jr Voice_Restage_Reg0440_BaseCurve_ForPart__FAE469                      ; FAE459  jr T,0xfae469
Voice_Restage_Reg0440_BaseCurve_ForPart__FAE45B:
	push	0                                     ; FAE45B  push 0x00
	push	h                                     ; FAE45D  push H
	call	EGEnv_Eval_BaseCurveA                              ; FAE45F  call 0xfa796d
	ld	(0xD79E:24), wa                        ; FAE463  ld (0x00d79e),WA
	popw	bc                                    ; FAE468  pop BC
Voice_Restage_Reg0440_BaseCurve_ForPart__FAE469:
	lda	xbc, (0xD75E:24)                       ; FAE469  lda XBC,0x00d75e
	push	xbc                                   ; FAE46E  push XBC
	extpfx3 0xC7, 0xF0, 0x89                   ; FAE46F  ld A,IXL
	extz	wa                                    ; FAE472  extz WA
	pushw	wa                                   ; FAE474  push WA
	calr Dev10C_SetChanReg_0600                 ; FAE475  calr 0xfad01a
	inc	2, de                                  ; FAE478  inc 2,DE
Voice_Restage_Reg0440_BaseCurve_ForPart__FAE47A:
	inc	6, xsp                                 ; FAE47A  inc 6,XSP
	jr Voice_Restage_Reg0440_BaseCurve_ForPart__FAE404                      ; FAE47C  jr T,0xfae404
Voice_Restage_Reg0440_BaseCurve_ForPart__FAE47E:
	pop	xix                                    ; FAE47E  pop XIX
	popw	de                                    ; FAE47F  pop DE
	popw	hl                                    ; FAE480  pop HL
	unlk32 xiz                                 ; FAE481  unlk XIZ
	ret                                        ; FAE483  ret
; --------------------------------------------------------------------------
; Voice_Restage_Reg0440_ValueCurve_ForPart -- 0xFAE484..0xFAE5C6 (323 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAF1F3
; Inputs:  frame `link XIZ,-9`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C), (XIZ+0x10)
; Outputs: writes 0x00D79A, 0x00D79E
; Calls:   0xFA6110 = VoiceSlots_ListSlotsOfPart, 0xFA79F4 = EGEnv_Eval_ValueCurve_WithBaseCurveA
;          0xFA981B = EnvRec_LoadSlot, 0xFA9915 = Voice_StageChanSel_Reg0440_Reg0480
;          0xFACFD6 = Dev10C_SetChanReg_0440, 0xFAD01A = Dev10C_SetChanReg_0600
;          0xFAD03C = Dev10C_SetChanReg_0580, 0xFAE2C6 = Voice_RestageArm_ValueCurve_Shared
;          0xFB3CE0 = VoiceQuery_Tag00_Part
; Evidence: the listing below is the byte-identical round-trip of 0xFAE484-0xFAE5C6
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ ROUND 6 ------------------------------------------------------------
; Voice_Restage_Reg0440_ValueCurve_ForPart -- one of the 49 arms of
;          Voice_ApplyParamChange_Dispatch (its ONLY caller, at 0xFAF1F3), and the one that
;          refreshes register 0x0440 + chan for every voice the part owns.
;          It obtains the part's voice list from VoiceQuery_Tag00_Part (0xFB3CE0), walks it
;          while the voice number is below 0x40, forms voice_record = 0x003BCF + 0x44*voice,
;          and per voice calls EGEnv_Eval_ValueCurve_WithBaseCurveA (0xFA79F4) and then Dev10C_SetChanReg_0440 (0xFACFD6) / _0580 / _0600.
;          Evidence: the callee addresses are instruction operands;
;          `python3 notes/prom_c_understanding_round6.py --dispatch` asserts that this arm has
;          exactly one call site and that it is inside the dispatcher, and --blocks asserts
;          which envelope block its evaluator belongs to.
;          Unknown: what register 0x0440 carries, and what the dispatcher's target code
;          for this arm means.
; --------------------------------------------------------------------------
Voice_Restage_Reg0440_ValueCurve_ForPart:
	link32 0xEE, 0x0C, 0xF7, 0xFF              ; FAE484  link XIZ,0xfff7
	pushw	hl                                   ; FAE488  push HL
	pushw	de                                   ; FAE489  push DE
	push	xix                                   ; FAE48A  push XIX
	ld	c, 4:opc                                   ; FAE48B  ld C,0x04
	extpfx3 0x8E, 0x10, 0x43                   ; FAE48D  mul BC,(XIZ+0x10)
	ld	de, bc                                  ; FAE490  ld DE,BC
	ld	wa, (xiz+8)                             ; FAE492  ld WA,(XIZ+0x08)
	extz	wa                                    ; FAE495  extz WA
	mul	wa, 0x12C                              ; FAE497  mul WA,0x012c
	ld	hl, wa                                  ; FAE49B  ld HL,WA
	add	wa, bc                                 ; FAE49D  add WA,BC
	add	wa, 55                                 ; FAE49F  add WA,0x0037
	extz	xwa                                   ; FAE4A3  extz XWA
	ld	d, (xwa+0x1523)                         ; FAE4A5  ld D,(XWA+0x1523)
	pushw	0                                    ; FAE4AA  push 0x0000
	push	0                                     ; FAE4AD  push 0x00
	extpfx3 0x8E, 0x10, 0x04                   ; FAE4AF  push (XIZ+0x10)
	ld	xbc, (xiz+12)                           ; FAE4B2  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FAE4B5  push XBC
	push	0                                     ; FAE4B6  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FAE4B8  push (XIZ+0x0a)
	push	0                                     ; FAE4BB  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAE4BD  push (XIZ+0x08)
	calr Voice_RestageArm_ValueCurve_Shared                 ; FAE4C0  calr 0xfae2c6
	ld	(xiz-5), a                              ; FAE4C3  ld (XIZ+0xfb),A
	inc	8, xsp                                 ; FAE4C6  inc 0,XSP
	inc	4, xsp                                 ; FAE4C8  inc 4,XSP
	cp	d, 0:i3                                   ; FAE4CA  cp D,0
	jr nz, Voice_Restage_Reg0440_ValueCurve_ForPart__FAE516                  ; FAE4CC  jr NZ,0xfae516
	push	0                                     ; FAE4CE  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAE4D0  push (XIZ+0x08)
	call	VoiceQuery_Tag00_Part                              ; FAE4D3  call 0xfb3ce0
	ld	(xiz-9), xiy                            ; FAE4D7  ld (XIZ+0xf7),XIY
	ld	bc, hl                                  ; FAE4DA  ld BC,HL
	inc	4, bc                                  ; FAE4DC  inc 4,BC
	extz	xbc                                   ; FAE4DE  extz XBC
	extpfx7 0xD3, 0xE5, 0x23, 0x15, 0x3E, 0x08, 0x00 ; FAE4E0  or (XBC+0x1523),0x0008
	ldw	de, 0x3BCF                             ; FAE4E7  ld DE,0x3bcf
	ld	xix, xiy                                ; FAE4EA  ld XIX,XIY
	inc	5, xix                                 ; FAE4EC  inc 5,XIX
	popw	bc                                    ; FAE4EE  pop BC
Voice_Restage_Reg0440_ValueCurve_ForPart__FAE4EF:
	ld	h, (xix)                                ; FAE4EF  ld H,(XIX)
	cp	h, 64                                   ; FAE4F1  cp H,0x40
	jrl nc, Voice_Restage_Reg0440_ValueCurve_ForPart__FAE5C1                 ; FAE4F4  jrl NC,0xfae5c1
	ld	c, 68:opc                                  ; FAE4F7  ld C,0x44
	mul8rr	c, h                                ; FAE4F9  mul BC,H
	add	bc, de                                 ; FAE4FB  add BC,DE
	pushw	bc                                   ; FAE4FD  push BC
	call	Voice_StageChanSel_Reg0440_Reg0480                              ; FAE4FE  call 0xfa9915
	lda	xbc, (0xD75E:24)                       ; FAE502  lda XBC,0x00d75e
	push	xbc                                   ; FAE507  push XBC
	ld	a, (xix)                                ; FAE508  ld A,(XIX)
	extz	wa                                    ; FAE50A  extz WA
	pushw	wa                                   ; FAE50C  push WA
	calr Dev10C_SetChanReg_0440                 ; FAE50D  calr 0xfacfd6
	inc	1, xix                                 ; FAE510  inc 1,XIX
	inc	8, xsp                                 ; FAE512  inc 0,XSP
	jr Voice_Restage_Reg0440_ValueCurve_ForPart__FAE4EF                      ; FAE514  jr T,0xfae4ef
Voice_Restage_Reg0440_ValueCurve_ForPart__FAE516:
	pushw	32                                   ; FAE516  push 0x0020
	push	0                                     ; FAE519  push 0x00
	extpfx3 0x8E, 0x10, 0x04                   ; FAE51B  push (XIZ+0x10)
	push	0                                     ; FAE51E  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAE520  push (XIZ+0x08)
	call	VoiceSlots_ListSlotsOfPart                              ; FAE523  call 0xfa6110
	ld	(xiz-4), iy                             ; FAE527  ld (XIZ+0xfc),IY
	ldw	de, 0                                  ; FAE52A  ld DE,0x0000
	ldw	bc, 0x1523                             ; FAE52D  ld BC,0x1523
	ld	(xiz-7), bc                             ; FAE530  ld (XIZ+0xf9),BC
	ld	(xiz-2), hl                             ; FAE533  ld (XIZ+0xfe),HL
	ld	ix, bc                                  ; FAE536  ld IX,BC
	extpfx3 0x9E, 0xFE, 0x84                   ; FAE538  add IX,(XIZ+0xfe)
	inc	6, xsp                                 ; FAE53B  inc 6,XSP
Voice_Restage_Reg0440_ValueCurve_ForPart__FAE53D:
	ld	bc, (xiz-4)                             ; FAE53D  ld BC,(XIZ+0xfc)
	extz	xbc                                   ; FAE540  extz XBC
	extpfx5 0xD3, 0x07, 0xE4, 0xE8, 0x23       ; FAE542  ld HL,(XBC+DE)
	ld	wa, hl                                  ; FAE547  ld WA,HL
	and	wa, 0xFF                               ; FAE549  and WA,0x00ff
	cp	wa, 0x80                                ; FAE54D  cp WA,0x0080
	jr nc, Voice_Restage_Reg0440_ValueCurve_ForPart__FAE5C1                  ; FAE551  jr NC,0xfae5c1
	ld	wa, hl                                  ; FAE553  ld WA,HL
	and	wa, 0x7F                               ; FAE555  and WA,0x007f
	ld	h, a                                    ; FAE559  ld H,A
	pushw	wa                                   ; FAE55B  push WA
	pushw	0                                    ; FAE55C  push 0x0000
	push	0                                     ; FAE55F  push 0x00
	extpfx3 0x8E, 0x10, 0x04                   ; FAE561  push (XIZ+0x10)
	pushw	ix                                   ; FAE564  push IX
	push	0                                     ; FAE565  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAE567  push (XIZ+0x08)
	call	EnvRec_LoadSlot                              ; FAE56A  call 0xfa981b
	inc	8, xsp                                 ; FAE56E  inc 0,XSP
	inc	2, xsp                                 ; FAE570  inc 2,XSP
	cp (xiz-5), 0x00                           ; FAE572  cp (XIZ+0xfb),0x00
	jr nz, Voice_Restage_Reg0440_ValueCurve_ForPart__FAE59F                  ; FAE576  jr NZ,0xfae59f
	ld	bc, (xiz-2)                             ; FAE578  ld BC,(XIZ+0xfe)
	inc	4, bc                                  ; FAE57B  inc 4,BC
	extz	xbc                                   ; FAE57D  extz XBC
	extpfx7 0xD3, 0xE5, 0x23, 0x15, 0x3E, 0x08, 0x00 ; FAE57F  or (XBC+0x1523),0x0008
	ldw	(0xD79E:24), 0                        ; FAE586  ld (0x00d79e),0x0000
	lda	xbc, (0xD75E:24)                       ; FAE58D  lda XBC,0x00d75e
	push	xbc                                   ; FAE592  push XBC
	ld	a, h                                    ; FAE593  ld A,H
	extz	wa                                    ; FAE595  extz WA
	pushw	wa                                   ; FAE597  push WA
	calr Dev10C_SetChanReg_0600                 ; FAE598  calr 0xfad01a
	inc	6, xsp                                 ; FAE59B  inc 6,XSP
	jr Voice_Restage_Reg0440_ValueCurve_ForPart__FAE5BC                      ; FAE59D  jr T,0xfae5bc
Voice_Restage_Reg0440_ValueCurve_ForPart__FAE59F:
	push	0                                     ; FAE59F  push 0x00
	push	h                                     ; FAE5A1  push H
	call	EGEnv_Eval_ValueCurve_WithBaseCurveA                              ; FAE5A3  call 0xfa79f4
	ld	(0xD79A:24), wa                        ; FAE5A7  ld (0x00d79a),WA
	lda	xbc, (0xD75E:24)                       ; FAE5AC  lda XBC,0x00d75e
	push	xbc                                   ; FAE5B1  push XBC
	ld	a, h                                    ; FAE5B2  ld A,H
	extz	wa                                    ; FAE5B4  extz WA
	pushw	wa                                   ; FAE5B6  push WA
	calr Dev10C_SetChanReg_0580                 ; FAE5B7  calr 0xfad03c
	inc	8, xsp                                 ; FAE5BA  inc 0,XSP
Voice_Restage_Reg0440_ValueCurve_ForPart__FAE5BC:
	inc	2, de                                  ; FAE5BC  inc 2,DE
	jrl Voice_Restage_Reg0440_ValueCurve_ForPart__FAE53D                     ; FAE5BE  jrl T,0xfae53d
Voice_Restage_Reg0440_ValueCurve_ForPart__FAE5C1:
	pop	xix                                    ; FAE5C1  pop XIX
	popw	de                                    ; FAE5C2  pop DE
	popw	hl                                    ; FAE5C3  pop HL
	unlk32 xiz                                 ; FAE5C4  unlk XIZ
	ret                                        ; FAE5C6  ret
; --------------------------------------------------------------------------
; Voice_Restage_Reg0180_BaseCurve_ForPart -- 0xFAE5C7..0xFAE702 (316 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAF1B5
; Inputs:  frame `link XIZ,-11`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C), (XIZ+0x10)
; Outputs: writes 0x00D796
; Calls:   0xFA6110 = VoiceSlots_ListSlotsOfPart, 0xFA7A4B = EGEnv_Eval_BaseCurveB
;          0xFA981B = EnvRec_LoadSlot, 0xFA9C60 = Voice_StageRegs_0180_AB
;          0xFACFB4 = Dev10C_SetChanReg_0180, 0xFAD05E = Dev10C_SetChanReg_01C0
;          0xFAE242 = Voice_RestageArm_BaseCurve_Shared, 0xFB3CE0 = VoiceQuery_Tag00_Part
; Evidence: the listing below is the byte-identical round-trip of 0xFAE5C7-0xFAE702
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ ROUND 6 ------------------------------------------------------------
; Voice_Restage_Reg0180_BaseCurve_ForPart -- one of the 49 arms of
;          Voice_ApplyParamChange_Dispatch (its ONLY caller, at 0xFAF1B5), and the one that
;          refreshes register 0x0180 + chan for every voice the part owns.
;          It obtains the part's voice list from VoiceQuery_Tag00_Part (0xFB3CE0), walks it
;          while the voice number is below 0x40, forms voice_record = 0x003BCF + 0x44*voice,
;          and per voice calls EGEnv_Eval_BaseCurveB (0xFA7A4B) and then Dev10C_SetChanReg_0180 (0xFACFB4) / _01C0.
;          Evidence: the callee addresses are instruction operands;
;          `python3 notes/prom_c_understanding_round6.py --dispatch` asserts that this arm has
;          exactly one call site and that it is inside the dispatcher, and --blocks asserts
;          which envelope block its evaluator belongs to.
;          Unknown: what register 0x0180 carries, and what the dispatcher's target code
;          for this arm means.
; --------------------------------------------------------------------------
Voice_Restage_Reg0180_BaseCurve_ForPart:
	link32 0xEE, 0x0C, 0xF5, 0xFF              ; FAE5C7  link XIZ,0xfff5
	pushw	hl                                   ; FAE5CB  push HL
	pushw	de                                   ; FAE5CC  push DE
	push	xix                                   ; FAE5CD  push XIX
	ld	c, 4:opc                                   ; FAE5CE  ld C,0x04
	extpfx3 0x8E, 0x10, 0x43                   ; FAE5D0  mul BC,(XIZ+0x10)
	ld	de, bc                                  ; FAE5D3  ld DE,BC
	ld	wa, (xiz+8)                             ; FAE5D5  ld WA,(XIZ+0x08)
	extz	wa                                    ; FAE5D8  extz WA
	mul	wa, 0x12C                              ; FAE5DA  mul WA,0x012c
	ld	hl, wa                                  ; FAE5DE  ld HL,WA
	add	wa, bc                                 ; FAE5E0  add WA,BC
	add	wa, 72                                 ; FAE5E2  add WA,0x0048
	extz	xwa                                   ; FAE5E6  extz XWA
	ld	d, (xwa+0x1523)                         ; FAE5E8  ld D,(XWA+0x1523)
	pushw	1                                    ; FAE5ED  push 0x0001
	push	0                                     ; FAE5F0  push 0x00
	extpfx3 0x8E, 0x10, 0x04                   ; FAE5F2  push (XIZ+0x10)
	ld	xbc, (xiz+12)                           ; FAE5F5  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FAE5F8  push XBC
	push	0                                     ; FAE5F9  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FAE5FB  push (XIZ+0x0a)
	push	0                                     ; FAE5FE  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAE600  push (XIZ+0x08)
	calr Voice_RestageArm_BaseCurve_Shared                 ; FAE603  calr 0xfae242
	ld	(xiz-7), a                              ; FAE606  ld (XIZ+0xf9),A
	inc	8, xsp                                 ; FAE609  inc 0,XSP
	inc	4, xsp                                 ; FAE60B  inc 4,XSP
	cp	d, 0:i3                                   ; FAE60D  cp D,0
	jr nz, Voice_Restage_Reg0180_BaseCurve_ForPart__FAE659                  ; FAE60F  jr NZ,0xfae659
	push	0                                     ; FAE611  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAE613  push (XIZ+0x08)
	call	VoiceQuery_Tag00_Part                              ; FAE616  call 0xfb3ce0
	ld	(xiz-11), xiy                           ; FAE61A  ld (XIZ+0xf5),XIY
	ld	bc, hl                                  ; FAE61D  ld BC,HL
	inc	4, bc                                  ; FAE61F  inc 4,BC
	extz	xbc                                   ; FAE621  extz XBC
	extpfx7 0xD3, 0xE5, 0x23, 0x15, 0x3E, 0x08, 0x00 ; FAE623  or (XBC+0x1523),0x0008
	ldw	de, 0x3BCF                             ; FAE62A  ld DE,0x3bcf
	ld	xix, xiy                                ; FAE62D  ld XIX,XIY
	inc	5, xix                                 ; FAE62F  inc 5,XIX
	popw	bc                                    ; FAE631  pop BC
Voice_Restage_Reg0180_BaseCurve_ForPart__FAE632:
	ld	h, (xix)                                ; FAE632  ld H,(XIX)
	cp	h, 64                                   ; FAE634  cp H,0x40
	jrl nc, Voice_Restage_Reg0180_BaseCurve_ForPart__FAE6FD                 ; FAE637  jrl NC,0xfae6fd
	ld	c, 68:opc                                  ; FAE63A  ld C,0x44
	mul8rr	c, h                                ; FAE63C  mul BC,H
	add	bc, de                                 ; FAE63E  add BC,DE
	pushw	bc                                   ; FAE640  push BC
	call	Voice_StageRegs_0180_AB                              ; FAE641  call 0xfa9c60
	lda	xbc, (0xD75E:24)                       ; FAE645  lda XBC,0x00d75e
	push	xbc                                   ; FAE64A  push XBC
	ld	a, (xix)                                ; FAE64B  ld A,(XIX)
	extz	wa                                    ; FAE64D  extz WA
	pushw	wa                                   ; FAE64F  push WA
	calr Dev10C_SetChanReg_0180                 ; FAE650  calr 0xfacfb4
	inc	1, xix                                 ; FAE653  inc 1,XIX
	inc	8, xsp                                 ; FAE655  inc 0,XSP
	jr Voice_Restage_Reg0180_BaseCurve_ForPart__FAE632                      ; FAE657  jr T,0xfae632
Voice_Restage_Reg0180_BaseCurve_ForPart__FAE659:
	pushw	32                                   ; FAE659  push 0x0020
	ld	c, (xiz+16)                             ; FAE65C  ld C,(XIZ+0x10)
	set	2, c                                   ; FAE65F  set 0x02,C
	pushw	bc                                   ; FAE662  push BC
	push	0                                     ; FAE663  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAE665  push (XIZ+0x08)
	call	VoiceSlots_ListSlotsOfPart                              ; FAE668  call 0xfa6110
	ld	(xiz-6), iy                             ; FAE66C  ld (XIZ+0xfa),IY
	ldw	de, 0                                  ; FAE66F  ld DE,0x0000
	ldw	ix, 0x1523                             ; FAE672  ld IX,0x1523
	ld	(xiz-4), hl                             ; FAE675  ld (XIZ+0xfc),HL
	ld	bc, ix                                  ; FAE678  ld BC,IX
	extpfx3 0x9E, 0xFC, 0x81                   ; FAE67A  add BC,(XIZ+0xfc)
	ld	(xiz-2), bc                             ; FAE67D  ld (XIZ+0xfe),BC
	jrl Voice_Restage_Reg0180_BaseCurve_ForPart__FAE6F9                     ; FAE680  jrl T,0xfae6f9
Voice_Restage_Reg0180_BaseCurve_ForPart__FAE683:
	ld	bc, (xiz-6)                             ; FAE683  ld BC,(XIZ+0xfa)
	extz	xbc                                   ; FAE686  extz XBC
	extpfx5 0xD3, 0x07, 0xE4, 0xE8, 0x23       ; FAE688  ld HL,(XBC+DE)
	ld	wa, hl                                  ; FAE68D  ld WA,HL
	and	wa, 0xFF                               ; FAE68F  and WA,0x00ff
	cp	wa, 64                                  ; FAE693  cp WA,0x0040
	jr nc, Voice_Restage_Reg0180_BaseCurve_ForPart__FAE6FD                  ; FAE697  jr NC,0xfae6fd
	ld	ix, hl                                  ; FAE699  ld IX,HL
	and	ix, 63                                 ; FAE69B  and IX,0x003f
	extpfx3 0xC7, 0xF0, 0x89                   ; FAE69F  ld A,IXL
	ld	h, a                                    ; FAE6A2  ld H,A
	pushw	wa                                   ; FAE6A4  push WA
	pushw	1                                    ; FAE6A5  push 0x0001
	push	0                                     ; FAE6A8  push 0x00
	extpfx3 0x8E, 0x10, 0x04                   ; FAE6AA  push (XIZ+0x10)
	extpfx3 0x9E, 0xFE, 0x04                   ; FAE6AD  pushw (XIZ+0xfe)
	push	0                                     ; FAE6B0  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAE6B2  push (XIZ+0x08)
	call	EnvRec_LoadSlot                              ; FAE6B5  call 0xfa981b
	inc	8, xsp                                 ; FAE6B9  inc 0,XSP
	inc	2, xsp                                 ; FAE6BB  inc 2,XSP
	cp (xiz-7), 0x00                           ; FAE6BD  cp (XIZ+0xf9),0x00
	jr nz, Voice_Restage_Reg0180_BaseCurve_ForPart__FAE6DA                  ; FAE6C1  jr NZ,0xfae6da
	ld	bc, (xiz-4)                             ; FAE6C3  ld BC,(XIZ+0xfc)
	inc	4, bc                                  ; FAE6C6  inc 4,BC
	extz	xbc                                   ; FAE6C8  extz XBC
	extpfx7 0xD3, 0xE5, 0x23, 0x15, 0x3E, 0x08, 0x00 ; FAE6CA  or (XBC+0x1523),0x0008
	ldw	(0xD796:24), 0                        ; FAE6D1  ld (0x00d796),0x0000
	jr Voice_Restage_Reg0180_BaseCurve_ForPart__FAE6E8                      ; FAE6D8  jr T,0xfae6e8
Voice_Restage_Reg0180_BaseCurve_ForPart__FAE6DA:
	push	0                                     ; FAE6DA  push 0x00
	push	h                                     ; FAE6DC  push H
	call	EGEnv_Eval_BaseCurveB                              ; FAE6DE  call 0xfa7a4b
	ld	(0xD796:24), wa                        ; FAE6E2  ld (0x00d796),WA
	popw	bc                                    ; FAE6E7  pop BC
Voice_Restage_Reg0180_BaseCurve_ForPart__FAE6E8:
	lda	xbc, (0xD75E:24)                       ; FAE6E8  lda XBC,0x00d75e
	push	xbc                                   ; FAE6ED  push XBC
	extpfx3 0xC7, 0xF0, 0x89                   ; FAE6EE  ld A,IXL
	extz	wa                                    ; FAE6F1  extz WA
	pushw	wa                                   ; FAE6F3  push WA
	calr Dev10C_SetChanReg_01C0                 ; FAE6F4  calr 0xfad05e
	inc	2, de                                  ; FAE6F7  inc 2,DE
Voice_Restage_Reg0180_BaseCurve_ForPart__FAE6F9:
	inc	6, xsp                                 ; FAE6F9  inc 6,XSP
	jr Voice_Restage_Reg0180_BaseCurve_ForPart__FAE683                      ; FAE6FB  jr T,0xfae683
Voice_Restage_Reg0180_BaseCurve_ForPart__FAE6FD:
	pop	xix                                    ; FAE6FD  pop XIX
	popw	de                                    ; FAE6FE  pop DE
	popw	hl                                    ; FAE6FF  pop HL
	unlk32 xiz                                 ; FAE700  unlk XIZ
	ret                                        ; FAE702  ret
; --------------------------------------------------------------------------
; Voice_Restage_Reg0180_ValueCurve_ForPart -- 0xFAE703..0xFAE847 (325 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAF212
; Inputs:  frame `link XIZ,-9`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C), (XIZ+0x10)
; Outputs: writes 0x00D796, 0x00D798
; Calls:   0xFA6110 = VoiceSlots_ListSlotsOfPart, 0xFA7AD6 = EGEnv_Eval_ValueCurve_WithBaseCurveB
;          0xFA981B = EnvRec_LoadSlot, 0xFA9C60 = Voice_StageRegs_0180_AB
;          0xFACFB4 = Dev10C_SetChanReg_0180, 0xFAD05E = Dev10C_SetChanReg_01C0
;          0xFAD080 = Dev10C_SetChanReg_0540, 0xFAE2C6 = Voice_RestageArm_ValueCurve_Shared
;          0xFB3CE0 = VoiceQuery_Tag00_Part
; Evidence: the listing below is the byte-identical round-trip of 0xFAE703-0xFAE847
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ ROUND 6 ------------------------------------------------------------
; Voice_Restage_Reg0180_ValueCurve_ForPart -- one of the 49 arms of
;          Voice_ApplyParamChange_Dispatch (its ONLY caller, at 0xFAF212), and the one that
;          refreshes register 0x0180 + chan for every voice the part owns.
;          It obtains the part's voice list from VoiceQuery_Tag00_Part (0xFB3CE0), walks it
;          while the voice number is below 0x40, forms voice_record = 0x003BCF + 0x44*voice,
;          and per voice calls EGEnv_Eval_ValueCurve_WithBaseCurveB (0xFA7AD6) and then Dev10C_SetChanReg_0180 (0xFACFB4) / _01C0 / _0540.
;          Evidence: the callee addresses are instruction operands;
;          `python3 notes/prom_c_understanding_round6.py --dispatch` asserts that this arm has
;          exactly one call site and that it is inside the dispatcher, and --blocks asserts
;          which envelope block its evaluator belongs to.
;          Unknown: what register 0x0180 carries, and what the dispatcher's target code
;          for this arm means.
; --------------------------------------------------------------------------
Voice_Restage_Reg0180_ValueCurve_ForPart:
	link32 0xEE, 0x0C, 0xF7, 0xFF              ; FAE703  link XIZ,0xfff7
	pushw	hl                                   ; FAE707  push HL
	pushw	de                                   ; FAE708  push DE
	push	xix                                   ; FAE709  push XIX
	ld	c, 4:opc                                   ; FAE70A  ld C,0x04
	extpfx3 0x8E, 0x10, 0x43                   ; FAE70C  mul BC,(XIZ+0x10)
	ld	de, bc                                  ; FAE70F  ld DE,BC
	ld	wa, (xiz+8)                             ; FAE711  ld WA,(XIZ+0x08)
	extz	wa                                    ; FAE714  extz WA
	mul	wa, 0x12C                              ; FAE716  mul WA,0x012c
	ld	hl, wa                                  ; FAE71A  ld HL,WA
	add	wa, bc                                 ; FAE71C  add WA,BC
	add	wa, 71                                 ; FAE71E  add WA,0x0047
	extz	xwa                                   ; FAE722  extz XWA
	ld	d, (xwa+0x1523)                         ; FAE724  ld D,(XWA+0x1523)
	pushw	1                                    ; FAE729  push 0x0001
	push	0                                     ; FAE72C  push 0x00
	extpfx3 0x8E, 0x10, 0x04                   ; FAE72E  push (XIZ+0x10)
	ld	xbc, (xiz+12)                           ; FAE731  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FAE734  push XBC
	push	0                                     ; FAE735  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FAE737  push (XIZ+0x0a)
	push	0                                     ; FAE73A  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAE73C  push (XIZ+0x08)
	calr Voice_RestageArm_ValueCurve_Shared                 ; FAE73F  calr 0xfae2c6
	ld	(xiz-5), a                              ; FAE742  ld (XIZ+0xfb),A
	inc	8, xsp                                 ; FAE745  inc 0,XSP
	inc	4, xsp                                 ; FAE747  inc 4,XSP
	cp	d, 0:i3                                   ; FAE749  cp D,0
	jr nz, Voice_Restage_Reg0180_ValueCurve_ForPart__FAE795                  ; FAE74B  jr NZ,0xfae795
	push	0                                     ; FAE74D  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAE74F  push (XIZ+0x08)
	call	VoiceQuery_Tag00_Part                              ; FAE752  call 0xfb3ce0
	ld	(xiz-9), xiy                            ; FAE756  ld (XIZ+0xf7),XIY
	ld	bc, hl                                  ; FAE759  ld BC,HL
	inc	4, bc                                  ; FAE75B  inc 4,BC
	extz	xbc                                   ; FAE75D  extz XBC
	extpfx7 0xD3, 0xE5, 0x23, 0x15, 0x3E, 0x08, 0x00 ; FAE75F  or (XBC+0x1523),0x0008
	ldw	de, 0x3BCF                             ; FAE766  ld DE,0x3bcf
	ld	xix, xiy                                ; FAE769  ld XIX,XIY
	inc	5, xix                                 ; FAE76B  inc 5,XIX
	popw	bc                                    ; FAE76D  pop BC
Voice_Restage_Reg0180_ValueCurve_ForPart__FAE76E:
	ld	h, (xix)                                ; FAE76E  ld H,(XIX)
	cp	h, 64                                   ; FAE770  cp H,0x40
	jrl nc, Voice_Restage_Reg0180_ValueCurve_ForPart__FAE842                 ; FAE773  jrl NC,0xfae842
	ld	c, 68:opc                                  ; FAE776  ld C,0x44
	mul8rr	c, h                                ; FAE778  mul BC,H
	add	bc, de                                 ; FAE77A  add BC,DE
	pushw	bc                                   ; FAE77C  push BC
	call	Voice_StageRegs_0180_AB                              ; FAE77D  call 0xfa9c60
	lda	xbc, (0xD75E:24)                       ; FAE781  lda XBC,0x00d75e
	push	xbc                                   ; FAE786  push XBC
	ld	a, (xix)                                ; FAE787  ld A,(XIX)
	extz	wa                                    ; FAE789  extz WA
	pushw	wa                                   ; FAE78B  push WA
	calr Dev10C_SetChanReg_0180                 ; FAE78C  calr 0xfacfb4
	inc	1, xix                                 ; FAE78F  inc 1,XIX
	inc	8, xsp                                 ; FAE791  inc 0,XSP
	jr Voice_Restage_Reg0180_ValueCurve_ForPart__FAE76E                      ; FAE793  jr T,0xfae76e
Voice_Restage_Reg0180_ValueCurve_ForPart__FAE795:
	pushw	32                                   ; FAE795  push 0x0020
	ld	c, (xiz+16)                             ; FAE798  ld C,(XIZ+0x10)
	set	2, c                                   ; FAE79B  set 0x02,C
	pushw	bc                                   ; FAE79E  push BC
	push	0                                     ; FAE79F  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAE7A1  push (XIZ+0x08)
	call	VoiceSlots_ListSlotsOfPart                              ; FAE7A4  call 0xfa6110
	ld	(xiz-4), iy                             ; FAE7A8  ld (XIZ+0xfc),IY
	ldw	de, 0                                  ; FAE7AB  ld DE,0x0000
	ldw	bc, 0x1523                             ; FAE7AE  ld BC,0x1523
	ld	(xiz-7), bc                             ; FAE7B1  ld (XIZ+0xf9),BC
	ld	(xiz-2), hl                             ; FAE7B4  ld (XIZ+0xfe),HL
	ld	ix, bc                                  ; FAE7B7  ld IX,BC
	extpfx3 0x9E, 0xFE, 0x84                   ; FAE7B9  add IX,(XIZ+0xfe)
	inc	6, xsp                                 ; FAE7BC  inc 6,XSP
Voice_Restage_Reg0180_ValueCurve_ForPart__FAE7BE:
	ld	bc, (xiz-4)                             ; FAE7BE  ld BC,(XIZ+0xfc)
	extz	xbc                                   ; FAE7C1  extz XBC
	extpfx5 0xD3, 0x07, 0xE4, 0xE8, 0x23       ; FAE7C3  ld HL,(XBC+DE)
	ld	wa, hl                                  ; FAE7C8  ld WA,HL
	and	wa, 0xFF                               ; FAE7CA  and WA,0x00ff
	cp	wa, 64                                  ; FAE7CE  cp WA,0x0040
	jr nc, Voice_Restage_Reg0180_ValueCurve_ForPart__FAE842                  ; FAE7D2  jr NC,0xfae842
	ld	wa, hl                                  ; FAE7D4  ld WA,HL
	and	wa, 63                                 ; FAE7D6  and WA,0x003f
	ld	h, a                                    ; FAE7DA  ld H,A
	pushw	wa                                   ; FAE7DC  push WA
	pushw	1                                    ; FAE7DD  push 0x0001
	push	0                                     ; FAE7E0  push 0x00
	extpfx3 0x8E, 0x10, 0x04                   ; FAE7E2  push (XIZ+0x10)
	pushw	ix                                   ; FAE7E5  push IX
	push	0                                     ; FAE7E6  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAE7E8  push (XIZ+0x08)
	call	EnvRec_LoadSlot                              ; FAE7EB  call 0xfa981b
	inc	8, xsp                                 ; FAE7EF  inc 0,XSP
	inc	2, xsp                                 ; FAE7F1  inc 2,XSP
	cp (xiz-5), 0x00                           ; FAE7F3  cp (XIZ+0xfb),0x00
	jr nz, Voice_Restage_Reg0180_ValueCurve_ForPart__FAE820                  ; FAE7F7  jr NZ,0xfae820
	ld	bc, (xiz-2)                             ; FAE7F9  ld BC,(XIZ+0xfe)
	inc	4, bc                                  ; FAE7FC  inc 4,BC
	extz	xbc                                   ; FAE7FE  extz XBC
	extpfx7 0xD3, 0xE5, 0x23, 0x15, 0x3E, 0x08, 0x00 ; FAE800  or (XBC+0x1523),0x0008
	ldw	(0xD796:24), 0                        ; FAE807  ld (0x00d796),0x0000
	lda	xbc, (0xD75E:24)                       ; FAE80E  lda XBC,0x00d75e
	push	xbc                                   ; FAE813  push XBC
	ld	a, h                                    ; FAE814  ld A,H
	extz	wa                                    ; FAE816  extz WA
	pushw	wa                                   ; FAE818  push WA
	calr Dev10C_SetChanReg_01C0                 ; FAE819  calr 0xfad05e
	inc	6, xsp                                 ; FAE81C  inc 6,XSP
	jr Voice_Restage_Reg0180_ValueCurve_ForPart__FAE83D                      ; FAE81E  jr T,0xfae83d
Voice_Restage_Reg0180_ValueCurve_ForPart__FAE820:
	push	0                                     ; FAE820  push 0x00
	push	h                                     ; FAE822  push H
	call	EGEnv_Eval_ValueCurve_WithBaseCurveB                              ; FAE824  call 0xfa7ad6
	ld	(0xD798:24), wa                        ; FAE828  ld (0x00d798),WA
	lda	xbc, (0xD75E:24)                       ; FAE82D  lda XBC,0x00d75e
	push	xbc                                   ; FAE832  push XBC
	ld	a, h                                    ; FAE833  ld A,H
	extz	wa                                    ; FAE835  extz WA
	pushw	wa                                   ; FAE837  push WA
	calr Dev10C_SetChanReg_0540                 ; FAE838  calr 0xfad080
	inc	8, xsp                                 ; FAE83B  inc 0,XSP
Voice_Restage_Reg0180_ValueCurve_ForPart__FAE83D:
	inc	2, de                                  ; FAE83D  inc 2,DE
	jrl Voice_Restage_Reg0180_ValueCurve_ForPart__FAE7BE                     ; FAE83F  jrl T,0xfae7be
Voice_Restage_Reg0180_ValueCurve_ForPart__FAE842:
	pop	xix                                    ; FAE842  pop XIX
	popw	de                                    ; FAE843  pop DE
	popw	hl                                    ; FAE844  pop HL
	unlk32 xiz                                 ; FAE845  unlk XIZ
	ret                                        ; FAE847  ret
; --------------------------------------------------------------------------
; Voice_Restage_Reg04C0_BaseCurve_ForPart -- 0xFAE848..0xFAE985 (318 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAF1D4
; Inputs:  frame `link XIZ,-11`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C), (XIZ+0x10)
; Outputs: writes 0x00D796, 0x00D7A0
; Calls:   0xFA6110 = VoiceSlots_ListSlotsOfPart, 0xFA7B31 = EGEnv_Eval_FreqWriteBaseCurve
;          0xFA981B = EnvRec_LoadSlot, 0xFA9F19 = Voice_StageChanSel_Reg04C0
;          0xFACFF8 = Dev10C_SetChanReg_04C0, 0xFAD0A2 = Dev10C_SetChanReg_01C0_or_0600
;          0xFAE242 = Voice_RestageArm_BaseCurve_Shared, 0xFB3CE0 = VoiceQuery_Tag00_Part
; Evidence: the listing below is the byte-identical round-trip of 0xFAE848-0xFAE985
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ ROUND 6 ------------------------------------------------------------
; Voice_Restage_Reg04C0_BaseCurve_ForPart -- one of the 49 arms of
;          Voice_ApplyParamChange_Dispatch (its ONLY caller, at 0xFAF1D4), and the one that
;          refreshes register 0x04C0 + chan for every voice the part owns.
;          It obtains the part's voice list from VoiceQuery_Tag00_Part (0xFB3CE0), walks it
;          while the voice number is below 0x40, forms voice_record = 0x003BCF + 0x44*voice,
;          and per voice calls EGEnv_Eval_FreqWriteBaseCurve (0xFA7B31) and then Dev10C_SetChanReg_04C0 (0xFACFF8) / _01C0_or_0600.
;          Evidence: the callee addresses are instruction operands;
;          `python3 notes/prom_c_understanding_round6.py --dispatch` asserts that this arm has
;          exactly one call site and that it is inside the dispatcher, and --blocks asserts
;          which envelope block its evaluator belongs to.
;          Unknown: what register 0x04C0 carries, and what the dispatcher's target code
;          for this arm means.
; --------------------------------------------------------------------------
Voice_Restage_Reg04C0_BaseCurve_ForPart:
	link32 0xEE, 0x0C, 0xF5, 0xFF              ; FAE848  link XIZ,0xfff5
	pushw	hl                                   ; FAE84C  push HL
	pushw	de                                   ; FAE84D  push DE
	push	xix                                   ; FAE84E  push XIX
	ld	c, 4:opc                                   ; FAE84F  ld C,0x04
	extpfx3 0x8E, 0x10, 0x43                   ; FAE851  mul BC,(XIZ+0x10)
	ld	de, bc                                  ; FAE854  ld DE,BC
	ld	wa, (xiz+8)                             ; FAE856  ld WA,(XIZ+0x08)
	extz	wa                                    ; FAE859  extz WA
	mul	wa, 0x12C                              ; FAE85B  mul WA,0x012c
	ld	hl, wa                                  ; FAE85F  ld HL,WA
	add	wa, bc                                 ; FAE861  add WA,BC
	add	wa, 88                                 ; FAE863  add WA,0x0058
	extz	xwa                                   ; FAE867  extz XWA
	ld	d, (xwa+0x1523)                         ; FAE869  ld D,(XWA+0x1523)
	pushw	2                                    ; FAE86E  push 0x0002
	push	0                                     ; FAE871  push 0x00
	extpfx3 0x8E, 0x10, 0x04                   ; FAE873  push (XIZ+0x10)
	ld	xbc, (xiz+12)                           ; FAE876  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FAE879  push XBC
	push	0                                     ; FAE87A  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FAE87C  push (XIZ+0x0a)
	push	0                                     ; FAE87F  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAE881  push (XIZ+0x08)
	calr Voice_RestageArm_BaseCurve_Shared                 ; FAE884  calr 0xfae242
	ld	(xiz-7), a                              ; FAE887  ld (XIZ+0xf9),A
	inc	8, xsp                                 ; FAE88A  inc 0,XSP
	inc	4, xsp                                 ; FAE88C  inc 4,XSP
	cp	d, 0:i3                                   ; FAE88E  cp D,0
	jr nz, Voice_Restage_Reg04C0_BaseCurve_ForPart__FAE8DA                  ; FAE890  jr NZ,0xfae8da
	push	0                                     ; FAE892  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAE894  push (XIZ+0x08)
	call	VoiceQuery_Tag00_Part                              ; FAE897  call 0xfb3ce0
	ld	(xiz-11), xiy                           ; FAE89B  ld (XIZ+0xf5),XIY
	ld	bc, hl                                  ; FAE89E  ld BC,HL
	inc	4, bc                                  ; FAE8A0  inc 4,BC
	extz	xbc                                   ; FAE8A2  extz XBC
	extpfx7 0xD3, 0xE5, 0x23, 0x15, 0x3E, 0x08, 0x00 ; FAE8A4  or (XBC+0x1523),0x0008
	ldw	de, 0x3BCF                             ; FAE8AB  ld DE,0x3bcf
	ld	xix, xiy                                ; FAE8AE  ld XIX,XIY
	inc	5, xix                                 ; FAE8B0  inc 5,XIX
	popw	bc                                    ; FAE8B2  pop BC
Voice_Restage_Reg04C0_BaseCurve_ForPart__FAE8B3:
	ld	h, (xix)                                ; FAE8B3  ld H,(XIX)
	cp	h, 64                                   ; FAE8B5  cp H,0x40
	jrl nc, Voice_Restage_Reg04C0_BaseCurve_ForPart__FAE980                 ; FAE8B8  jrl NC,0xfae980
	ld	c, 68:opc                                  ; FAE8BB  ld C,0x44
	mul8rr	c, h                                ; FAE8BD  mul BC,H
	add	bc, de                                 ; FAE8BF  add BC,DE
	pushw	bc                                   ; FAE8C1  push BC
	call	Voice_StageChanSel_Reg04C0                              ; FAE8C2  call 0xfa9f19
	lda	xbc, (0xD75E:24)                       ; FAE8C6  lda XBC,0x00d75e
	push	xbc                                   ; FAE8CB  push XBC
	ld	a, (xix)                                ; FAE8CC  ld A,(XIX)
	extz	wa                                    ; FAE8CE  extz WA
	pushw	wa                                   ; FAE8D0  push WA
	calr Dev10C_SetChanReg_04C0                 ; FAE8D1  calr 0xfacff8
	inc	1, xix                                 ; FAE8D4  inc 1,XIX
	inc	8, xsp                                 ; FAE8D6  inc 0,XSP
	jr Voice_Restage_Reg04C0_BaseCurve_ForPart__FAE8B3                      ; FAE8D8  jr T,0xfae8b3
Voice_Restage_Reg04C0_BaseCurve_ForPart__FAE8DA:
	pushw	32                                   ; FAE8DA  push 0x0020
	ld	c, (xiz+16)                             ; FAE8DD  ld C,(XIZ+0x10)
	set	3, c                                   ; FAE8E0  set 0x03,C
	pushw	bc                                   ; FAE8E3  push BC
	push	0                                     ; FAE8E4  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAE8E6  push (XIZ+0x08)
	call	VoiceSlots_ListSlotsOfPart                              ; FAE8E9  call 0xfa6110
	ld	(xiz-6), iy                             ; FAE8ED  ld (XIZ+0xfa),IY
	ldw	de, 0                                  ; FAE8F0  ld DE,0x0000
	ldw	ix, 0x1523                             ; FAE8F3  ld IX,0x1523
	ld	(xiz-4), hl                             ; FAE8F6  ld (XIZ+0xfc),HL
	ld	bc, ix                                  ; FAE8F9  ld BC,IX
	extpfx3 0x9E, 0xFC, 0x81                   ; FAE8FB  add BC,(XIZ+0xfc)
	ld	(xiz-2), bc                             ; FAE8FE  ld (XIZ+0xfe),BC
	jrl Voice_Restage_Reg04C0_BaseCurve_ForPart__FAE97C                     ; FAE901  jrl T,0xfae97c
Voice_Restage_Reg04C0_BaseCurve_ForPart__FAE904:
	ld	bc, (xiz-6)                             ; FAE904  ld BC,(XIZ+0xfa)
	extz	xbc                                   ; FAE907  extz XBC
	extpfx5 0xD3, 0x07, 0xE4, 0xE8, 0x23       ; FAE909  ld HL,(XBC+DE)
	ld	wa, hl                                  ; FAE90E  ld WA,HL
	and	wa, 0xFF                               ; FAE910  and WA,0x00ff
	cp	wa, 0x80                                ; FAE914  cp WA,0x0080
	jr nc, Voice_Restage_Reg04C0_BaseCurve_ForPart__FAE980                  ; FAE918  jr NC,0xfae980
	ld	ix, hl                                  ; FAE91A  ld IX,HL
	and	ix, 0x7F                               ; FAE91C  and IX,0x007f
	extpfx3 0xC7, 0xF0, 0x89                   ; FAE920  ld A,IXL
	ld	h, a                                    ; FAE923  ld H,A
	pushw	wa                                   ; FAE925  push WA
	pushw	2                                    ; FAE926  push 0x0002
	push	0                                     ; FAE929  push 0x00
	extpfx3 0x8E, 0x10, 0x04                   ; FAE92B  push (XIZ+0x10)
	extpfx3 0x9E, 0xFE, 0x04                   ; FAE92E  pushw (XIZ+0xfe)
	push	0                                     ; FAE931  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAE933  push (XIZ+0x08)
	call	EnvRec_LoadSlot                              ; FAE936  call 0xfa981b
	inc	8, xsp                                 ; FAE93A  inc 0,XSP
	inc	2, xsp                                 ; FAE93C  inc 2,XSP
	cp (xiz-7), 0x00                           ; FAE93E  cp (XIZ+0xf9),0x00
	jr nz, Voice_Restage_Reg04C0_BaseCurve_ForPart__FAE962                  ; FAE942  jr NZ,0xfae962
	ld	bc, (xiz-4)                             ; FAE944  ld BC,(XIZ+0xfc)
	inc	4, bc                                  ; FAE947  inc 4,BC
	extz	xbc                                   ; FAE949  extz XBC
	extpfx7 0xD3, 0xE5, 0x23, 0x15, 0x3E, 0x08, 0x00 ; FAE94B  or (XBC+0x1523),0x0008
	ldw	(0xD796:24), 0                        ; FAE952  ld (0x00d796),0x0000
	ldw	(0xD7A0:24), 0                        ; FAE959  ld (0x00d7a0),0x0000
	jr Voice_Restage_Reg04C0_BaseCurve_ForPart__FAE96B                      ; FAE960  jr T,0xfae96b
Voice_Restage_Reg04C0_BaseCurve_ForPart__FAE962:
	push	0                                     ; FAE962  push 0x00
	push	h                                     ; FAE964  push H
	call	EGEnv_Eval_FreqWriteBaseCurve                              ; FAE966  call 0xfa7b31
	popw	bc                                    ; FAE96A  pop BC
Voice_Restage_Reg04C0_BaseCurve_ForPart__FAE96B:
	lda	xbc, (0xD75E:24)                       ; FAE96B  lda XBC,0x00d75e
	push	xbc                                   ; FAE970  push XBC
	extpfx3 0xC7, 0xF0, 0x89                   ; FAE971  ld A,IXL
	extz	wa                                    ; FAE974  extz WA
	pushw	wa                                   ; FAE976  push WA
	calr Dev10C_SetChanReg_01C0_or_0600                 ; FAE977  calr 0xfad0a2
	inc	2, de                                  ; FAE97A  inc 2,DE
Voice_Restage_Reg04C0_BaseCurve_ForPart__FAE97C:
	inc	6, xsp                                 ; FAE97C  inc 6,XSP
	jr Voice_Restage_Reg04C0_BaseCurve_ForPart__FAE904                      ; FAE97E  jr T,0xfae904
Voice_Restage_Reg04C0_BaseCurve_ForPart__FAE980:
	pop	xix                                    ; FAE980  pop XIX
	popw	de                                    ; FAE981  pop DE
	popw	hl                                    ; FAE982  pop HL
	unlk32 xiz                                 ; FAE983  unlk XIZ
	ret                                        ; FAE985  ret
; --------------------------------------------------------------------------
; Voice_Restage_Reg04C0_ValueCurve_ForPart -- 0xFAE986..0xFAEACD (328 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAF232
; Inputs:  frame `link XIZ,-9`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C), (XIZ+0x10)
; Outputs: writes 0x00D796, 0x00D7A0
; Calls:   0xFA6110 = VoiceSlots_ListSlotsOfPart, 0xFA7C3A = EGEnv_Eval_ValueCurve_WithFreqWriteCurve
;          0xFA981B = EnvRec_LoadSlot, 0xFA9F19 = Voice_StageChanSel_Reg04C0
;          0xFACFF8 = Dev10C_SetChanReg_04C0, 0xFAD0A2 = Dev10C_SetChanReg_01C0_or_0600
;          0xFAD0E6 = Dev10C_SetChanReg_0540_or_0580, 0xFAE2C6 = Voice_RestageArm_ValueCurve_Shared
;          0xFB3CE0 = VoiceQuery_Tag00_Part
; Evidence: the listing below is the byte-identical round-trip of 0xFAE986-0xFAEACD
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ ROUND 6 ------------------------------------------------------------
; Voice_Restage_Reg04C0_ValueCurve_ForPart -- one of the 49 arms of
;          Voice_ApplyParamChange_Dispatch (its ONLY caller, at 0xFAF232), and the one that
;          refreshes register 0x04C0 + chan for every voice the part owns.
;          It obtains the part's voice list from VoiceQuery_Tag00_Part (0xFB3CE0), walks it
;          while the voice number is below 0x40, forms voice_record = 0x003BCF + 0x44*voice,
;          and per voice calls EGEnv_Eval_ValueCurve_WithFreqWriteCurve (0xFA7C3A) and then Dev10C_SetChanReg_04C0 (0xFACFF8) / _0540_or_0580.
;          Evidence: the callee addresses are instruction operands;
;          `python3 notes/prom_c_understanding_round6.py --dispatch` asserts that this arm has
;          exactly one call site and that it is inside the dispatcher, and --blocks asserts
;          which envelope block its evaluator belongs to.
;          Unknown: what register 0x04C0 carries, and what the dispatcher's target code
;          for this arm means.
; --------------------------------------------------------------------------
Voice_Restage_Reg04C0_ValueCurve_ForPart:
	link32 0xEE, 0x0C, 0xF7, 0xFF              ; FAE986  link XIZ,0xfff7
	pushw	hl                                   ; FAE98A  push HL
	pushw	de                                   ; FAE98B  push DE
	push	xix                                   ; FAE98C  push XIX
	ld	c, 4:opc                                   ; FAE98D  ld C,0x04
	extpfx3 0x8E, 0x10, 0x43                   ; FAE98F  mul BC,(XIZ+0x10)
	ld	de, bc                                  ; FAE992  ld DE,BC
	ld	wa, (xiz+8)                             ; FAE994  ld WA,(XIZ+0x08)
	extz	wa                                    ; FAE997  extz WA
	mul	wa, 0x12C                              ; FAE999  mul WA,0x012c
	ld	hl, wa                                  ; FAE99D  ld HL,WA
	add	wa, bc                                 ; FAE99F  add WA,BC
	add	wa, 87                                 ; FAE9A1  add WA,0x0057
	extz	xwa                                   ; FAE9A5  extz XWA
	ld	d, (xwa+0x1523)                         ; FAE9A7  ld D,(XWA+0x1523)
	pushw	2                                    ; FAE9AC  push 0x0002
	push	0                                     ; FAE9AF  push 0x00
	extpfx3 0x8E, 0x10, 0x04                   ; FAE9B1  push (XIZ+0x10)
	ld	xbc, (xiz+12)                           ; FAE9B4  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FAE9B7  push XBC
	push	0                                     ; FAE9B8  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FAE9BA  push (XIZ+0x0a)
	push	0                                     ; FAE9BD  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAE9BF  push (XIZ+0x08)
	calr Voice_RestageArm_ValueCurve_Shared                 ; FAE9C2  calr 0xfae2c6
	ld	(xiz-5), a                              ; FAE9C5  ld (XIZ+0xfb),A
	inc	8, xsp                                 ; FAE9C8  inc 0,XSP
	inc	4, xsp                                 ; FAE9CA  inc 4,XSP
	cp	d, 0:i3                                   ; FAE9CC  cp D,0
	jr nz, Voice_Restage_Reg04C0_ValueCurve_ForPart__FAEA18                  ; FAE9CE  jr NZ,0xfaea18
	push	0                                     ; FAE9D0  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAE9D2  push (XIZ+0x08)
	call	VoiceQuery_Tag00_Part                              ; FAE9D5  call 0xfb3ce0
	ld	(xiz-9), xiy                            ; FAE9D9  ld (XIZ+0xf7),XIY
	ld	bc, hl                                  ; FAE9DC  ld BC,HL
	inc	4, bc                                  ; FAE9DE  inc 4,BC
	extz	xbc                                   ; FAE9E0  extz XBC
	extpfx7 0xD3, 0xE5, 0x23, 0x15, 0x3E, 0x08, 0x00 ; FAE9E2  or (XBC+0x1523),0x0008
	ldw	de, 0x3BCF                             ; FAE9E9  ld DE,0x3bcf
	ld	xix, xiy                                ; FAE9EC  ld XIX,XIY
	inc	5, xix                                 ; FAE9EE  inc 5,XIX
	popw	bc                                    ; FAE9F0  pop BC
Voice_Restage_Reg04C0_ValueCurve_ForPart__FAE9F1:
	ld	h, (xix)                                ; FAE9F1  ld H,(XIX)
	cp	h, 64                                   ; FAE9F3  cp H,0x40
	jrl nc, Voice_Restage_Reg04C0_ValueCurve_ForPart__FAEAC8                 ; FAE9F6  jrl NC,0xfaeac8
	ld	c, 68:opc                                  ; FAE9F9  ld C,0x44
	mul8rr	c, h                                ; FAE9FB  mul BC,H
	add	bc, de                                 ; FAE9FD  add BC,DE
	pushw	bc                                   ; FAE9FF  push BC
	call	Voice_StageChanSel_Reg04C0                              ; FAEA00  call 0xfa9f19
	lda	xbc, (0xD75E:24)                       ; FAEA04  lda XBC,0x00d75e
	push	xbc                                   ; FAEA09  push XBC
	ld	a, (xix)                                ; FAEA0A  ld A,(XIX)
	extz	wa                                    ; FAEA0C  extz WA
	pushw	wa                                   ; FAEA0E  push WA
	calr Dev10C_SetChanReg_04C0                 ; FAEA0F  calr 0xfacff8
	inc	1, xix                                 ; FAEA12  inc 1,XIX
	inc	8, xsp                                 ; FAEA14  inc 0,XSP
	jr Voice_Restage_Reg04C0_ValueCurve_ForPart__FAE9F1                      ; FAEA16  jr T,0xfae9f1
Voice_Restage_Reg04C0_ValueCurve_ForPart__FAEA18:
	pushw	32                                   ; FAEA18  push 0x0020
	ld	c, (xiz+16)                             ; FAEA1B  ld C,(XIZ+0x10)
	set	3, c                                   ; FAEA1E  set 0x03,C
	pushw	bc                                   ; FAEA21  push BC
	push	0                                     ; FAEA22  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAEA24  push (XIZ+0x08)
	call	VoiceSlots_ListSlotsOfPart                              ; FAEA27  call 0xfa6110
	ld	(xiz-4), iy                             ; FAEA2B  ld (XIZ+0xfc),IY
	ldw	de, 0                                  ; FAEA2E  ld DE,0x0000
	ldw	bc, 0x1523                             ; FAEA31  ld BC,0x1523
	ld	(xiz-7), bc                             ; FAEA34  ld (XIZ+0xf9),BC
	ld	(xiz-2), hl                             ; FAEA37  ld (XIZ+0xfe),HL
	ld	ix, bc                                  ; FAEA3A  ld IX,BC
	extpfx3 0x9E, 0xFE, 0x84                   ; FAEA3C  add IX,(XIZ+0xfe)
	inc	6, xsp                                 ; FAEA3F  inc 6,XSP
Voice_Restage_Reg04C0_ValueCurve_ForPart__FAEA41:
	ld	bc, (xiz-4)                             ; FAEA41  ld BC,(XIZ+0xfc)
	extz	xbc                                   ; FAEA44  extz XBC
	extpfx5 0xD3, 0x07, 0xE4, 0xE8, 0x23       ; FAEA46  ld HL,(XBC+DE)
	ld	wa, hl                                  ; FAEA4B  ld WA,HL
	and	wa, 0xFF                               ; FAEA4D  and WA,0x00ff
	cp	wa, 0x80                                ; FAEA51  cp WA,0x0080
	jrl nc, Voice_Restage_Reg04C0_ValueCurve_ForPart__FAEAC8                 ; FAEA55  jrl NC,0xfaeac8
	ld	wa, hl                                  ; FAEA58  ld WA,HL
	and	wa, 0x7F                               ; FAEA5A  and WA,0x007f
	ld	h, a                                    ; FAEA5E  ld H,A
	pushw	wa                                   ; FAEA60  push WA
	pushw	2                                    ; FAEA61  push 0x0002
	push	0                                     ; FAEA64  push 0x00
	extpfx3 0x8E, 0x10, 0x04                   ; FAEA66  push (XIZ+0x10)
	pushw	ix                                   ; FAEA69  push IX
	push	0                                     ; FAEA6A  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAEA6C  push (XIZ+0x08)
	call	EnvRec_LoadSlot                              ; FAEA6F  call 0xfa981b
	inc	8, xsp                                 ; FAEA73  inc 0,XSP
	inc	2, xsp                                 ; FAEA75  inc 2,XSP
	cp (xiz-5), 0x00                           ; FAEA77  cp (XIZ+0xfb),0x00
	jr nz, Voice_Restage_Reg04C0_ValueCurve_ForPart__FAEAAB                  ; FAEA7B  jr NZ,0xfaeaab
	ld	bc, (xiz-2)                             ; FAEA7D  ld BC,(XIZ+0xfe)
	inc	4, bc                                  ; FAEA80  inc 4,BC
	extz	xbc                                   ; FAEA82  extz XBC
	extpfx7 0xD3, 0xE5, 0x23, 0x15, 0x3E, 0x08, 0x00 ; FAEA84  or (XBC+0x1523),0x0008
	ldw	(0xD796:24), 0                        ; FAEA8B  ld (0x00d796),0x0000
	ldw	(0xD7A0:24), 0                        ; FAEA92  ld (0x00d7a0),0x0000
	lda	xbc, (0xD75E:24)                       ; FAEA99  lda XBC,0x00d75e
	push	xbc                                   ; FAEA9E  push XBC
	ld	a, h                                    ; FAEA9F  ld A,H
	extz	wa                                    ; FAEAA1  extz WA
	pushw	wa                                   ; FAEAA3  push WA
	calr Dev10C_SetChanReg_01C0_or_0600                 ; FAEAA4  calr 0xfad0a2
	inc	6, xsp                                 ; FAEAA7  inc 6,XSP
	jr Voice_Restage_Reg04C0_ValueCurve_ForPart__FAEAC3                      ; FAEAA9  jr T,0xfaeac3
Voice_Restage_Reg04C0_ValueCurve_ForPart__FAEAAB:
	push	0                                     ; FAEAAB  push 0x00
	push	h                                     ; FAEAAD  push H
	call	EGEnv_Eval_ValueCurve_WithFreqWriteCurve                              ; FAEAAF  call 0xfa7c3a
	lda	xbc, (0xD75E:24)                       ; FAEAB3  lda XBC,0x00d75e
	push	xbc                                   ; FAEAB8  push XBC
	ld	a, h                                    ; FAEAB9  ld A,H
	extz	wa                                    ; FAEABB  extz WA
	pushw	wa                                   ; FAEABD  push WA
	calr Dev10C_SetChanReg_0540_or_0580                 ; FAEABE  calr 0xfad0e6
	inc	8, xsp                                 ; FAEAC1  inc 0,XSP
Voice_Restage_Reg04C0_ValueCurve_ForPart__FAEAC3:
	inc	2, de                                  ; FAEAC3  inc 2,DE
	jrl Voice_Restage_Reg04C0_ValueCurve_ForPart__FAEA41                     ; FAEAC5  jrl T,0xfaea41
Voice_Restage_Reg04C0_ValueCurve_ForPart__FAEAC8:
	pop	xix                                    ; FAEAC8  pop XIX
	popw	de                                    ; FAEAC9  pop DE
	popw	hl                                    ; FAEACA  pop HL
	unlk32 xiz                                 ; FAEACB  unlk XIZ
	ret                                        ; FAEACD  ret
; --------------------------------------------------------------------------
; sub_FAEACE -- 0xFAEACE..0xFAEAF8 (43 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAF240
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Calls:   0xFAD5C2 = Scale7Bit_ByDepth_UniOrBipolar, 0xFC589E = PartRec_SetFittingOffset_0001
; Evidence: the listing below is the byte-identical round-trip of 0xFAEACE-0xFAEAF8
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FAEACE:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAEACE  link XIZ,0x0000
	pushw	hl                                   ; FAEAD2  push HL
	ld	xbc, (xiz+12)                           ; FAEAD3  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FAEAD6  push XBC
	push	0                                     ; FAEAD7  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FAEAD9  push (XIZ+0x0a)
	calr Scale7Bit_ByDepth_UniOrBipolar                 ; FAEADC  calr 0xfad5c2
	ld	hl, wa                                  ; FAEADF  ld HL,WA
	ld	xbc, (xiz+12)                           ; FAEAE1  ld XBC,(XIZ+0x0c)
	ld	a, (xbc)                                ; FAEAE4  ld A,(XBC)
	pushw	wa                                   ; FAEAE6  push WA
	pushw	hl                                   ; FAEAE7  push HL
	push	0                                     ; FAEAE8  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAEAEA  push (XIZ+0x08)
	call	PartRec_SetFittingOffset_0001                              ; FAEAED  call 0xfc589e
	inc	8, xsp                                 ; FAEAF1  inc 0,XSP
	inc	4, xsp                                 ; FAEAF3  inc 4,XSP
	popw	hl                                    ; FAEAF5  pop HL
	unlk32 xiz                                 ; FAEAF6  unlk XIZ
	ret                                        ; FAEAF8  ret
; --------------------------------------------------------------------------
; sub_FAEAF9 -- 0xFAEAF9..0xFAEB64 (108 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAF24E
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Calls:   0xFAD688 = Scale7Bit_ByDepth_UniOrBipolar_Shl7, 0xFB3CE0 = VoiceQuery_Tag00_Part
;          0xFB7A73 = Dev104_SetChanRegs_00C0_0100_0240, 0xFC59EF = PartRec_SetPositionOffset_0003
;          0xFC5D5B = Pack104_RestageRegs_00C0_0100_0240_ForVoice
; Evidence: the listing below is the byte-identical round-trip of 0xFAEAF9-0xFAEB64
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FAEAF9:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAEAF9  link XIZ,0x0000
	pushw	hl                                   ; FAEAFD  push HL
	push	xix                                   ; FAEAFE  push XIX
	ld	xbc, (xiz+12)                           ; FAEAFF  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FAEB02  push XBC
	push	0                                     ; FAEB03  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FAEB05  push (XIZ+0x0a)
	calr Scale7Bit_ByDepth_UniOrBipolar_Shl7                 ; FAEB08  calr 0xfad688
	ld	hl, wa                                  ; FAEB0B  ld HL,WA
	ld	xbc, (xiz+12)                           ; FAEB0D  ld XBC,(XIZ+0x0c)
	ld	a, (xbc)                                ; FAEB10  ld A,(XBC)
	pushw	wa                                   ; FAEB12  push WA
	pushw	hl                                   ; FAEB13  push HL
	push	0                                     ; FAEB14  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAEB16  push (XIZ+0x08)
	call	PartRec_SetPositionOffset_0003                              ; FAEB19  call 0xfc59ef
	push	0                                     ; FAEB1D  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAEB1F  push (XIZ+0x08)
	call	VoiceQuery_Tag00_Part                              ; FAEB22  call 0xfb3ce0
	ld	xix, xiy                                ; FAEB26  ld XIX,XIY
	inc	5, xiy                                 ; FAEB28  inc 5,XIY
	ld	xix, xiy                                ; FAEB2A  ld XIX,XIY
	inc	8, xsp                                 ; FAEB2C  inc 0,XSP
	inc	6, xsp                                 ; FAEB2E  inc 6,XSP
sub_FAEAF9__FAEB30:
	ld	h, (xix)                                ; FAEB30  ld H,(XIX)
	cp	h, 64                                   ; FAEB32  cp H,0x40
	jr nc, sub_FAEAF9__FAEB60                  ; FAEB35  jr NC,0xfaeb60
	lda	xbc, (0xD7A2:24)                       ; FAEB37  lda XBC,0x00d7a2
	push	xbc                                   ; FAEB3C  push XBC
	push	0                                     ; FAEB3D  push 0x00
	push	h                                     ; FAEB3F  push H
	call	Pack104_RestageRegs_00C0_0100_0240_ForVoice                              ; FAEB41  call 0xfc5d5b
	inc	6, xsp                                 ; FAEB45  inc 6,XSP
	cp	a, 0:i3                                   ; FAEB47  cp A,0
	jr z, sub_FAEAF9__FAEB5C                   ; FAEB49  jr Z,0xfaeb5c
	lda	xbc, (0xD7A2:24)                       ; FAEB4B  lda XBC,0x00d7a2
	push	xbc                                   ; FAEB50  push XBC
	ld	a, (xix)                                ; FAEB51  ld A,(XIX)
	extz	wa                                    ; FAEB53  extz WA
	pushw	wa                                   ; FAEB55  push WA
	call	Dev104_SetChanRegs_00C0_0100_0240                              ; FAEB56  call 0xfb7a73
	inc	6, xsp                                 ; FAEB5A  inc 6,XSP
sub_FAEAF9__FAEB5C:
	inc	1, xix                                 ; FAEB5C  inc 1,XIX
	jr sub_FAEAF9__FAEB30                      ; FAEB5E  jr T,0xfaeb30
sub_FAEAF9__FAEB60:
	pop	xix                                    ; FAEB60  pop XIX
	popw	hl                                    ; FAEB61  pop HL
	unlk32 xiz                                 ; FAEB62  unlk XIZ
	ret                                        ; FAEB64  ret
; --------------------------------------------------------------------------
; sub_FAEB65 -- 0xFAEB65..0xFAEBD0 (108 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAF25C
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Calls:   0xFAD5C2 = Scale7Bit_ByDepth_UniOrBipolar, 0xFB3CE0 = VoiceQuery_Tag00_Part
;          0xFB7A73 = Dev104_SetChanRegs_00C0_0100_0240, 0xFC5BA2 = PartRec_SetPositionOffset_0005
;          0xFC5D5B = Pack104_RestageRegs_00C0_0100_0240_ForVoice
; Evidence: the listing below is the byte-identical round-trip of 0xFAEB65-0xFAEBD0
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FAEB65:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAEB65  link XIZ,0x0000
	pushw	hl                                   ; FAEB69  push HL
	push	xix                                   ; FAEB6A  push XIX
	ld	xbc, (xiz+12)                           ; FAEB6B  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FAEB6E  push XBC
	push	0                                     ; FAEB6F  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FAEB71  push (XIZ+0x0a)
	calr Scale7Bit_ByDepth_UniOrBipolar                 ; FAEB74  calr 0xfad5c2
	ld	hl, wa                                  ; FAEB77  ld HL,WA
	ld	xbc, (xiz+12)                           ; FAEB79  ld XBC,(XIZ+0x0c)
	ld	a, (xbc)                                ; FAEB7C  ld A,(XBC)
	pushw	wa                                   ; FAEB7E  push WA
	pushw	hl                                   ; FAEB7F  push HL
	push	0                                     ; FAEB80  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAEB82  push (XIZ+0x08)
	call	PartRec_SetPositionOffset_0005                              ; FAEB85  call 0xfc5ba2
	push	0                                     ; FAEB89  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAEB8B  push (XIZ+0x08)
	call	VoiceQuery_Tag00_Part                              ; FAEB8E  call 0xfb3ce0
	ld	xix, xiy                                ; FAEB92  ld XIX,XIY
	inc	5, xiy                                 ; FAEB94  inc 5,XIY
	ld	xix, xiy                                ; FAEB96  ld XIX,XIY
	inc	8, xsp                                 ; FAEB98  inc 0,XSP
	inc	6, xsp                                 ; FAEB9A  inc 6,XSP
sub_FAEB65__FAEB9C:
	ld	h, (xix)                                ; FAEB9C  ld H,(XIX)
	cp	h, 64                                   ; FAEB9E  cp H,0x40
	jr nc, sub_FAEB65__FAEBCC                  ; FAEBA1  jr NC,0xfaebcc
	lda	xbc, (0xD7A2:24)                       ; FAEBA3  lda XBC,0x00d7a2
	push	xbc                                   ; FAEBA8  push XBC
	push	0                                     ; FAEBA9  push 0x00
	push	h                                     ; FAEBAB  push H
	call	Pack104_RestageRegs_00C0_0100_0240_ForVoice                              ; FAEBAD  call 0xfc5d5b
	inc	6, xsp                                 ; FAEBB1  inc 6,XSP
	cp	a, 0:i3                                   ; FAEBB3  cp A,0
	jr z, sub_FAEB65__FAEBC8                   ; FAEBB5  jr Z,0xfaebc8
	lda	xbc, (0xD7A2:24)                       ; FAEBB7  lda XBC,0x00d7a2
	push	xbc                                   ; FAEBBC  push XBC
	ld	a, (xix)                                ; FAEBBD  ld A,(XIX)
	extz	wa                                    ; FAEBBF  extz WA
	pushw	wa                                   ; FAEBC1  push WA
	call	Dev104_SetChanRegs_00C0_0100_0240                              ; FAEBC2  call 0xfb7a73
	inc	6, xsp                                 ; FAEBC6  inc 6,XSP
sub_FAEB65__FAEBC8:
	inc	1, xix                                 ; FAEBC8  inc 1,XIX
	jr sub_FAEB65__FAEB9C                      ; FAEBCA  jr T,0xfaeb9c
sub_FAEB65__FAEBCC:
	pop	xix                                    ; FAEBCC  pop XIX
	popw	hl                                    ; FAEBCD  pop HL
	unlk32 xiz                                 ; FAEBCE  unlk XIZ
	ret                                        ; FAEBD0  ret
; --------------------------------------------------------------------------
; sub_FAEBD1 -- 0xFAEBD1..0xFAEC20 (80 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAF26A
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Calls:   0xFAD561 = sub_FAD561, 0xFB3CE0 = VoiceQuery_Tag00_Part
;          0xFC5EFB = PartRec_SetMovementDepth_0007, 0xFC6027 = Pack104_RefreshMovementDepth_ForVoice
; Evidence: the listing below is the byte-identical round-trip of 0xFAEBD1-0xFAEC20
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FAEBD1:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAEBD1  link XIZ,0x0000
	pushw	hl                                   ; FAEBD5  push HL
	push	xix                                   ; FAEBD6  push XIX
	ld	xbc, (xiz+12)                           ; FAEBD7  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FAEBDA  push XBC
	push	0                                     ; FAEBDB  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FAEBDD  push (XIZ+0x0a)
	calr sub_FAD561                 ; FAEBE0  calr 0xfad561
	ld	hl, wa                                  ; FAEBE3  ld HL,WA
	ld	xbc, (xiz+12)                           ; FAEBE5  ld XBC,(XIZ+0x0c)
	ld	a, (xbc)                                ; FAEBE8  ld A,(XBC)
	pushw	wa                                   ; FAEBEA  push WA
	pushw	hl                                   ; FAEBEB  push HL
	push	0                                     ; FAEBEC  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAEBEE  push (XIZ+0x08)
	call	PartRec_SetMovementDepth_0007                              ; FAEBF1  call 0xfc5efb
	push	0                                     ; FAEBF5  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAEBF7  push (XIZ+0x08)
	call	VoiceQuery_Tag00_Part                              ; FAEBFA  call 0xfb3ce0
	ld	xix, xiy                                ; FAEBFE  ld XIX,XIY
	inc	5, xiy                                 ; FAEC00  inc 5,XIY
	ld	xix, xiy                                ; FAEC02  ld XIX,XIY
	inc	8, xsp                                 ; FAEC04  inc 0,XSP
	inc	6, xsp                                 ; FAEC06  inc 6,XSP
sub_FAEBD1__FAEC08:
	ld	h, (xix)                                ; FAEC08  ld H,(XIX)
	cp	h, 64                                   ; FAEC0A  cp H,0x40
	jr nc, sub_FAEBD1__FAEC1C                  ; FAEC0D  jr NC,0xfaec1c
	push	0                                     ; FAEC0F  push 0x00
	push	h                                     ; FAEC11  push H
	call	Pack104_RefreshMovementDepth_ForVoice                              ; FAEC13  call 0xfc6027
	inc	1, xix                                 ; FAEC17  inc 1,XIX
	popw	bc                                    ; FAEC19  pop BC
	jr sub_FAEBD1__FAEC08                      ; FAEC1A  jr T,0xfaec08
sub_FAEBD1__FAEC1C:
	pop	xix                                    ; FAEC1C  pop XIX
	popw	hl                                    ; FAEC1D  pop HL
	unlk32 xiz                                 ; FAEC1E  unlk XIZ
	ret                                        ; FAEC20  ret
; --------------------------------------------------------------------------
; sub_FAEC21 -- 0xFAEC21..0xFAEC70 (80 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAF278
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Calls:   0xFAD561 = sub_FAD561, 0xFB3CE0 = VoiceQuery_Tag00_Part
;          0xFC6175 = PartRec_SetMovementRate_0009, 0xFC629B = Pack104_RefreshMovementRate_ForVoice
; Evidence: the listing below is the byte-identical round-trip of 0xFAEC21-0xFAEC70
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FAEC21:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAEC21  link XIZ,0x0000
	pushw	hl                                   ; FAEC25  push HL
	push	xix                                   ; FAEC26  push XIX
	ld	xbc, (xiz+12)                           ; FAEC27  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FAEC2A  push XBC
	push	0                                     ; FAEC2B  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FAEC2D  push (XIZ+0x0a)
	calr sub_FAD561                 ; FAEC30  calr 0xfad561
	ld	hl, wa                                  ; FAEC33  ld HL,WA
	ld	xbc, (xiz+12)                           ; FAEC35  ld XBC,(XIZ+0x0c)
	ld	a, (xbc)                                ; FAEC38  ld A,(XBC)
	pushw	wa                                   ; FAEC3A  push WA
	pushw	hl                                   ; FAEC3B  push HL
	push	0                                     ; FAEC3C  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAEC3E  push (XIZ+0x08)
	call	PartRec_SetMovementRate_0009                              ; FAEC41  call 0xfc6175
	push	0                                     ; FAEC45  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAEC47  push (XIZ+0x08)
	call	VoiceQuery_Tag00_Part                              ; FAEC4A  call 0xfb3ce0
	ld	xix, xiy                                ; FAEC4E  ld XIX,XIY
	inc	5, xiy                                 ; FAEC50  inc 5,XIY
	ld	xix, xiy                                ; FAEC52  ld XIX,XIY
	inc	8, xsp                                 ; FAEC54  inc 0,XSP
	inc	6, xsp                                 ; FAEC56  inc 6,XSP
sub_FAEC21__FAEC58:
	ld	h, (xix)                                ; FAEC58  ld H,(XIX)
	cp	h, 64                                   ; FAEC5A  cp H,0x40
	jr nc, sub_FAEC21__FAEC6C                  ; FAEC5D  jr NC,0xfaec6c
	push	0                                     ; FAEC5F  push 0x00
	push	h                                     ; FAEC61  push H
	call	Pack104_RefreshMovementRate_ForVoice                              ; FAEC63  call 0xfc629b
	inc	1, xix                                 ; FAEC67  inc 1,XIX
	popw	bc                                    ; FAEC69  pop BC
	jr sub_FAEC21__FAEC58                      ; FAEC6A  jr T,0xfaec58
sub_FAEC21__FAEC6C:
	pop	xix                                    ; FAEC6C  pop XIX
	popw	hl                                    ; FAEC6D  pop HL
	unlk32 xiz                                 ; FAEC6E  unlk XIZ
	ret                                        ; FAEC70  ret
; --------------------------------------------------------------------------
; sub_FAEC71 -- 0xFAEC71..0xFAEC9B (43 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAF286
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Calls:   0xFAD5C2 = Scale7Bit_ByDepth_UniOrBipolar, 0xFC63EC = PartRec_SetMutingOffset_000B
; Evidence: the listing below is the byte-identical round-trip of 0xFAEC71-0xFAEC9B
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FAEC71:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAEC71  link XIZ,0x0000
	pushw	hl                                   ; FAEC75  push HL
	ld	xbc, (xiz+12)                           ; FAEC76  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FAEC79  push XBC
	push	0                                     ; FAEC7A  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FAEC7C  push (XIZ+0x0a)
	calr Scale7Bit_ByDepth_UniOrBipolar                 ; FAEC7F  calr 0xfad5c2
	ld	hl, wa                                  ; FAEC82  ld HL,WA
	ld	xbc, (xiz+12)                           ; FAEC84  ld XBC,(XIZ+0x0c)
	ld	a, (xbc)                                ; FAEC87  ld A,(XBC)
	pushw	wa                                   ; FAEC89  push WA
	pushw	hl                                   ; FAEC8A  push HL
	push	0                                     ; FAEC8B  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAEC8D  push (XIZ+0x08)
	call	PartRec_SetMutingOffset_000B                              ; FAEC90  call 0xfc63ec
	inc	8, xsp                                 ; FAEC94  inc 0,XSP
	inc	4, xsp                                 ; FAEC96  inc 4,XSP
	popw	hl                                    ; FAEC98  pop HL
	unlk32 xiz                                 ; FAEC99  unlk XIZ
	ret                                        ; FAEC9B  ret
; --------------------------------------------------------------------------
; sub_FAEC9C -- 0xFAEC9C..0xFAECC6 (43 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAF294
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Calls:   0xFAD5C2 = Scale7Bit_ByDepth_UniOrBipolar, 0xFC654F = PartRec_SetTuningOffset_000D
; Evidence: the listing below is the byte-identical round-trip of 0xFAEC9C-0xFAECC6
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FAEC9C:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAEC9C  link XIZ,0x0000
	pushw	hl                                   ; FAECA0  push HL
	ld	xbc, (xiz+12)                           ; FAECA1  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FAECA4  push XBC
	push	0                                     ; FAECA5  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FAECA7  push (XIZ+0x0a)
	calr Scale7Bit_ByDepth_UniOrBipolar                 ; FAECAA  calr 0xfad5c2
	ld	hl, wa                                  ; FAECAD  ld HL,WA
	ld	xbc, (xiz+12)                           ; FAECAF  ld XBC,(XIZ+0x0c)
	ld	a, (xbc)                                ; FAECB2  ld A,(XBC)
	pushw	wa                                   ; FAECB4  push WA
	pushw	hl                                   ; FAECB5  push HL
	push	0                                     ; FAECB6  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAECB8  push (XIZ+0x08)
	call	PartRec_SetTuningOffset_000D                              ; FAECBB  call 0xfc654f
	inc	8, xsp                                 ; FAECBF  inc 0,XSP
	inc	4, xsp                                 ; FAECC1  inc 4,XSP
	popw	hl                                    ; FAECC3  pop HL
	unlk32 xiz                                 ; FAECC4  unlk XIZ
	ret                                        ; FAECC6  ret
; --------------------------------------------------------------------------
; sub_FAECC7 -- 0xFAECC7..0xFAED32 (108 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAF2A2
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Calls:   0xFAD5C2 = Scale7Bit_ByDepth_UniOrBipolar, 0xFB3CE0 = VoiceQuery_Tag00_Part
;          0xFB7B41 = Dev104_SetChanReg_0280, 0xFC65EC = PartRec_SetSubGainOffset_000F
;          0xFC6712 = Pack104_RestageReg_0280_ForVoice
; Evidence: the listing below is the byte-identical round-trip of 0xFAECC7-0xFAED32
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FAECC7:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAECC7  link XIZ,0x0000
	pushw	hl                                   ; FAECCB  push HL
	push	xix                                   ; FAECCC  push XIX
	ld	xbc, (xiz+12)                           ; FAECCD  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FAECD0  push XBC
	push	0                                     ; FAECD1  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FAECD3  push (XIZ+0x0a)
	calr Scale7Bit_ByDepth_UniOrBipolar                 ; FAECD6  calr 0xfad5c2
	ld	hl, wa                                  ; FAECD9  ld HL,WA
	ld	xbc, (xiz+12)                           ; FAECDB  ld XBC,(XIZ+0x0c)
	ld	a, (xbc)                                ; FAECDE  ld A,(XBC)
	pushw	wa                                   ; FAECE0  push WA
	pushw	hl                                   ; FAECE1  push HL
	push	0                                     ; FAECE2  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAECE4  push (XIZ+0x08)
	call	PartRec_SetSubGainOffset_000F                              ; FAECE7  call 0xfc65ec
	push	0                                     ; FAECEB  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAECED  push (XIZ+0x08)
	call	VoiceQuery_Tag00_Part                              ; FAECF0  call 0xfb3ce0
	ld	xix, xiy                                ; FAECF4  ld XIX,XIY
	inc	5, xiy                                 ; FAECF6  inc 5,XIY
	ld	xix, xiy                                ; FAECF8  ld XIX,XIY
	inc	8, xsp                                 ; FAECFA  inc 0,XSP
	inc	6, xsp                                 ; FAECFC  inc 6,XSP
sub_FAECC7__FAECFE:
	ld	h, (xix)                                ; FAECFE  ld H,(XIX)
	cp	h, 64                                   ; FAED00  cp H,0x40
	jr nc, sub_FAECC7__FAED2E                  ; FAED03  jr NC,0xfaed2e
	lda	xbc, (0xD7A2:24)                       ; FAED05  lda XBC,0x00d7a2
	push	xbc                                   ; FAED0A  push XBC
	push	0                                     ; FAED0B  push 0x00
	push	h                                     ; FAED0D  push H
	call	Pack104_RestageReg_0280_ForVoice                              ; FAED0F  call 0xfc6712
	inc	6, xsp                                 ; FAED13  inc 6,XSP
	cp	a, 0:i3                                   ; FAED15  cp A,0
	jr z, sub_FAECC7__FAED2A                   ; FAED17  jr Z,0xfaed2a
	lda	xbc, (0xD7A2:24)                       ; FAED19  lda XBC,0x00d7a2
	push	xbc                                   ; FAED1E  push XBC
	ld	a, (xix)                                ; FAED1F  ld A,(XIX)
	extz	wa                                    ; FAED21  extz WA
	pushw	wa                                   ; FAED23  push WA
	call	Dev104_SetChanReg_0280                              ; FAED24  call 0xfb7b41
	inc	6, xsp                                 ; FAED28  inc 6,XSP
sub_FAECC7__FAED2A:
	inc	1, xix                                 ; FAED2A  inc 1,XIX
	jr sub_FAECC7__FAECFE                      ; FAED2C  jr T,0xfaecfe
sub_FAECC7__FAED2E:
	pop	xix                                    ; FAED2E  pop XIX
	popw	hl                                    ; FAED2F  pop HL
	unlk32 xiz                                 ; FAED30  unlk XIZ
	ret                                        ; FAED32  ret
; --------------------------------------------------------------------------
; PartRec_ApplyParam_0023 -- 0xFAED33..0xFAED75 (67 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAF2B0
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Calls:   0xFAD203 = PartRec_SetOrClearParamBits_x4, 0xFAD561 = sub_FAD561
; Evidence: the listing below is the byte-identical round-trip of 0xFAED33-0xFAED75
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7 finish pass).  APPLIES ONE WORD OF THE PART RECORD'S 12-WORD
;          PARAMETER BLOCK: it stores its normalised argument into part_record
;          +0x23 and then marks that parameter.
;          `mul BC,0x012C` (part-record stride) and `add BC,0x0023` at 0xFAED4F select
;          the word; `ld (XBC+0x1523),WA` at 0xFAED55 stores it.
;          ⚠ THE NAME IS FRAMED, NOT CONTENT, AND DELIBERATELY SO: +0x23 is the
;          field's OFFSET, which is an instruction operand.  What the parameter IS
;          is NOT established -- see the block comment above PartRec_ApplyParam_001D.
;          Reached through ENTRY 37 of Voice_ApplyParamChange_Dispatch's 49-entry
;          table at 0xFAF08F, whose word holds 0xFAF2A8, and that arm calls here.
;          ⚠ ENTRY NUMBER AND TARGET CODE ARE NOT THE SAME NUMBER: `dec 1,BC` at
;          0xFAF079 runs before the index, so entry 37 is RAW TARGET CODE 38.
;          An earlier draft of this header printed one number under both names and
;          had the arm index off by one as well; the ROM table and the arm's own
;          call are re-read by notes/prom_c_finish_round7.py --selftest.
;          Change mask pushed to PartRec_SetOrClearParamBits_x4: 0x0020 / 0x0020 = 1<<5.
; --------------------------------------------------------------------------
PartRec_ApplyParam_0023:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAED33  link XIZ,0x0000
	pushw	hl                                   ; FAED37  push HL
	ld	xbc, (xiz+12)                           ; FAED38  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FAED3B  push XBC
	push	0                                     ; FAED3C  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FAED3E  push (XIZ+0x0a)
	calr sub_FAD561                 ; FAED41  calr 0xfad561
	ld	hl, wa                                  ; FAED44  ld HL,WA
	ld	bc, (xiz+8)                             ; FAED46  ld BC,(XIZ+0x08)
	extz	bc                                    ; FAED49  extz BC
	mul	bc, 0x12C                              ; FAED4B  mul BC,0x012c
	add	bc, 35                                 ; FAED4F  add BC,0x0023
	extz	xbc                                   ; FAED53  extz XBC
	ld	(xbc+0x1523), wa                        ; FAED55  ld (XBC+0x1523),WA
	pushw	32                                   ; FAED5A  push 0x0020
	pushw	32                                   ; FAED5D  push 0x0020
	ld	xbc, (xiz+12)                           ; FAED60  ld XBC,(XIZ+0x0c)
	ld	a, (xbc)                                ; FAED63  ld A,(XBC)
	pushw	wa                                   ; FAED65  push WA
	push	0                                     ; FAED66  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAED68  push (XIZ+0x08)
	calr PartRec_SetOrClearParamBits_x4                 ; FAED6B  calr 0xfad203
	inc	8, xsp                                 ; FAED6E  inc 0,XSP
	inc	6, xsp                                 ; FAED70  inc 6,XSP
	popw	hl                                    ; FAED72  pop HL
	unlk32 xiz                                 ; FAED73  unlk XIZ
	ret                                        ; FAED75  ret
; --------------------------------------------------------------------------
; PartRec_ApplyParam_0025 -- 0xFAED76..0xFAEDC3 (78 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAF2BD
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Calls:   0xFAD203 = PartRec_SetOrClearParamBits_x4, 0xFAD5C2 = Scale7Bit_ByDepth_UniOrBipolar
;          0xFB4D45 = sub_FB4D45
; Evidence: the listing below is the byte-identical round-trip of 0xFAED76-0xFAEDC3
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7 finish pass).  APPLIES ONE WORD OF THE PART RECORD'S 12-WORD
;          PARAMETER BLOCK: it stores its normalised argument into part_record
;          +0x25 and then marks that parameter.
;          `mul BC,0x012C` (part-record stride) and `add BC,0x0025` at 0xFAED95 select
;          the word; `ld (XBC+0x1523),WA` at 0xFAED9B stores it.
;          ⚠ THE NAME IS FRAMED, NOT CONTENT, AND DELIBERATELY SO: +0x25 is the
;          field's OFFSET, which is an instruction operand.  What the parameter IS
;          is NOT established -- see the block comment above PartRec_ApplyParam_001D.
;          Reached through ENTRY 38 of Voice_ApplyParamChange_Dispatch's 49-entry
;          table at 0xFAF08F, whose word holds 0xFAF2B5, and that arm calls here.
;          ⚠ ENTRY NUMBER AND TARGET CODE ARE NOT THE SAME NUMBER: `dec 1,BC` at
;          0xFAF079 runs before the index, so entry 38 is RAW TARGET CODE 39.
;          An earlier draft of this header printed one number under both names and
;          had the arm index off by one as well; the ROM table and the arm's own
;          call are re-read by notes/prom_c_finish_round7.py --selftest.
;          Change mask pushed to PartRec_SetOrClearParamBits_x4: 0x0040 / 0x0040 = 1<<6.
; --------------------------------------------------------------------------
PartRec_ApplyParam_0025:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAED76  link XIZ,0x0000
	pushw	hl                                   ; FAED7A  push HL
	pushw	de                                   ; FAED7B  push DE
	ld	h, (xiz+8)                              ; FAED7C  ld H,(XIZ+0x08)
	ld	xbc, (xiz+12)                           ; FAED7F  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FAED82  push XBC
	push	0                                     ; FAED83  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FAED85  push (XIZ+0x0a)
	calr Scale7Bit_ByDepth_UniOrBipolar                 ; FAED88  calr 0xfad5c2
	ld	de, wa                                  ; FAED8B  ld DE,WA
	ld	c, h                                    ; FAED8D  ld C,H
	extz	bc                                    ; FAED8F  extz BC
	mul	bc, 0x12C                              ; FAED91  mul BC,0x012c
	add	bc, 37                                 ; FAED95  add BC,0x0025
	extz	xbc                                   ; FAED99  extz XBC
	ld	(xbc+0x1523), wa                        ; FAED9B  ld (XBC+0x1523),WA
	pushw	64                                   ; FAEDA0  push 0x0040
	pushw	64                                   ; FAEDA3  push 0x0040
	ld	xbc, (xiz+12)                           ; FAEDA6  ld XBC,(XIZ+0x0c)
	ld	a, (xbc)                                ; FAEDA9  ld A,(XBC)
	pushw	wa                                   ; FAEDAB  push WA
	push	0                                     ; FAEDAC  push 0x00
	push	h                                     ; FAEDAE  push H
	calr PartRec_SetOrClearParamBits_x4                 ; FAEDB0  calr 0xfad203
	push	0                                     ; FAEDB3  push 0x00
	push	h                                     ; FAEDB5  push H
	call	sub_FB4D45                              ; FAEDB7  call 0xfb4d45
	inc	8, xsp                                 ; FAEDBB  inc 0,XSP
	inc	8, xsp                                 ; FAEDBD  inc 0,XSP
	popw	de                                    ; FAEDBF  pop DE
	popw	hl                                    ; FAEDC0  pop HL
	unlk32 xiz                                 ; FAEDC1  unlk XIZ
	ret                                        ; FAEDC3  ret
; --------------------------------------------------------------------------
; PartRec_ApplyParam_0027 -- 0xFAEDC4..0xFAEE06 (67 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAF2CA
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Calls:   0xFAD203 = PartRec_SetOrClearParamBits_x4, 0xFAD5C2 = Scale7Bit_ByDepth_UniOrBipolar
; Evidence: the listing below is the byte-identical round-trip of 0xFAEDC4-0xFAEE06
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7 finish pass).  APPLIES ONE WORD OF THE PART RECORD'S 12-WORD
;          PARAMETER BLOCK: it stores its normalised argument into part_record
;          +0x27 and then marks that parameter.
;          `mul BC,0x012C` (part-record stride) and `add BC,0x0027` at 0xFAEDE0 select
;          the word; `ld (XBC+0x1523),WA` at 0xFAEDE6 stores it.
;          ⚠ THE NAME IS FRAMED, NOT CONTENT, AND DELIBERATELY SO: +0x27 is the
;          field's OFFSET, which is an instruction operand.  What the parameter IS
;          is NOT established -- see the block comment above PartRec_ApplyParam_001D.
;          Reached through ENTRY 39 of Voice_ApplyParamChange_Dispatch's 49-entry
;          table at 0xFAF08F, whose word holds 0xFAF2C2, and that arm calls here.
;          ⚠ ENTRY NUMBER AND TARGET CODE ARE NOT THE SAME NUMBER: `dec 1,BC` at
;          0xFAF079 runs before the index, so entry 39 is RAW TARGET CODE 40.
;          An earlier draft of this header printed one number under both names and
;          had the arm index off by one as well; the ROM table and the arm's own
;          call are re-read by notes/prom_c_finish_round7.py --selftest.
;          Change mask pushed to PartRec_SetOrClearParamBits_x4: 0x0080 / 0x0080 = 1<<7.
; --------------------------------------------------------------------------
PartRec_ApplyParam_0027:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAEDC4  link XIZ,0x0000
	pushw	hl                                   ; FAEDC8  push HL
	ld	xbc, (xiz+12)                           ; FAEDC9  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FAEDCC  push XBC
	push	0                                     ; FAEDCD  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FAEDCF  push (XIZ+0x0a)
	calr Scale7Bit_ByDepth_UniOrBipolar                 ; FAEDD2  calr 0xfad5c2
	ld	hl, wa                                  ; FAEDD5  ld HL,WA
	ld	bc, (xiz+8)                             ; FAEDD7  ld BC,(XIZ+0x08)
	extz	bc                                    ; FAEDDA  extz BC
	mul	bc, 0x12C                              ; FAEDDC  mul BC,0x012c
	add	bc, 39                                 ; FAEDE0  add BC,0x0027
	extz	xbc                                   ; FAEDE4  extz XBC
	ld	(xbc+0x1523), wa                        ; FAEDE6  ld (XBC+0x1523),WA
	pushw	0x80                                 ; FAEDEB  push 0x0080
	pushw	0x80                                 ; FAEDEE  push 0x0080
	ld	xbc, (xiz+12)                           ; FAEDF1  ld XBC,(XIZ+0x0c)
	ld	a, (xbc)                                ; FAEDF4  ld A,(XBC)
	pushw	wa                                   ; FAEDF6  push WA
	push	0                                     ; FAEDF7  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAEDF9  push (XIZ+0x08)
	calr PartRec_SetOrClearParamBits_x4                 ; FAEDFC  calr 0xfad203
	inc	8, xsp                                 ; FAEDFF  inc 0,XSP
	inc	6, xsp                                 ; FAEE01  inc 6,XSP
	popw	hl                                    ; FAEE03  pop HL
	unlk32 xiz                                 ; FAEE04  unlk XIZ
	ret                                        ; FAEE06  ret
; --------------------------------------------------------------------------
; PartRec_ApplyParam_0029 -- 0xFAEE07..0xFAEE49 (67 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAF2D7
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Calls:   0xFAD203 = PartRec_SetOrClearParamBits_x4, 0xFAD5C2 = Scale7Bit_ByDepth_UniOrBipolar
; Evidence: the listing below is the byte-identical round-trip of 0xFAEE07-0xFAEE49
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7 finish pass).  APPLIES ONE WORD OF THE PART RECORD'S 12-WORD
;          PARAMETER BLOCK: it stores its normalised argument into part_record
;          +0x29 and then marks that parameter.
;          `mul BC,0x012C` (part-record stride) and `add BC,0x0029` at 0xFAEE23 select
;          the word; `ld (XBC+0x1523),WA` at 0xFAEE29 stores it.
;          ⚠ THE NAME IS FRAMED, NOT CONTENT, AND DELIBERATELY SO: +0x29 is the
;          field's OFFSET, which is an instruction operand.  What the parameter IS
;          is NOT established -- see the block comment above PartRec_ApplyParam_001D.
;          Reached through ENTRY 40 of Voice_ApplyParamChange_Dispatch's 49-entry
;          table at 0xFAF08F, whose word holds 0xFAF2CF, and that arm calls here.
;          ⚠ ENTRY NUMBER AND TARGET CODE ARE NOT THE SAME NUMBER: `dec 1,BC` at
;          0xFAF079 runs before the index, so entry 40 is RAW TARGET CODE 41.
;          An earlier draft of this header printed one number under both names and
;          had the arm index off by one as well; the ROM table and the arm's own
;          call are re-read by notes/prom_c_finish_round7.py --selftest.
;          Change mask pushed to PartRec_SetOrClearParamBits_x4: 0x0100 / 0x0100 = 1<<8.
; --------------------------------------------------------------------------
PartRec_ApplyParam_0029:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAEE07  link XIZ,0x0000
	pushw	hl                                   ; FAEE0B  push HL
	ld	xbc, (xiz+12)                           ; FAEE0C  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FAEE0F  push XBC
	push	0                                     ; FAEE10  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FAEE12  push (XIZ+0x0a)
	calr Scale7Bit_ByDepth_UniOrBipolar                 ; FAEE15  calr 0xfad5c2
	ld	hl, wa                                  ; FAEE18  ld HL,WA
	ld	bc, (xiz+8)                             ; FAEE1A  ld BC,(XIZ+0x08)
	extz	bc                                    ; FAEE1D  extz BC
	mul	bc, 0x12C                              ; FAEE1F  mul BC,0x012c
	add	bc, 41                                 ; FAEE23  add BC,0x0029
	extz	xbc                                   ; FAEE27  extz XBC
	ld	(xbc+0x1523), wa                        ; FAEE29  ld (XBC+0x1523),WA
	pushw	0x100                                ; FAEE2E  push 0x0100
	pushw	0x100                                ; FAEE31  push 0x0100
	ld	xbc, (xiz+12)                           ; FAEE34  ld XBC,(XIZ+0x0c)
	ld	a, (xbc)                                ; FAEE37  ld A,(XBC)
	pushw	wa                                   ; FAEE39  push WA
	push	0                                     ; FAEE3A  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAEE3C  push (XIZ+0x08)
	calr PartRec_SetOrClearParamBits_x4                 ; FAEE3F  calr 0xfad203
	inc	8, xsp                                 ; FAEE42  inc 0,XSP
	inc	6, xsp                                 ; FAEE44  inc 6,XSP
	popw	hl                                    ; FAEE46  pop HL
	unlk32 xiz                                 ; FAEE47  unlk XIZ
	ret                                        ; FAEE49  ret
; --------------------------------------------------------------------------
; PartRec_ApplyParam_002B -- 0xFAEE4A..0xFAEE8C (67 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAF2E4
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Calls:   0xFAD203 = PartRec_SetOrClearParamBits_x4, 0xFAD5C2 = Scale7Bit_ByDepth_UniOrBipolar
; Evidence: the listing below is the byte-identical round-trip of 0xFAEE4A-0xFAEE8C
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7 finish pass).  APPLIES ONE WORD OF THE PART RECORD'S 12-WORD
;          PARAMETER BLOCK: it stores its normalised argument into part_record
;          +0x2B and then marks that parameter.
;          `mul BC,0x012C` (part-record stride) and `add BC,0x002B` at 0xFAEE66 select
;          the word; `ld (XBC+0x1523),WA` at 0xFAEE6C stores it.
;          ⚠ THE NAME IS FRAMED, NOT CONTENT, AND DELIBERATELY SO: +0x2B is the
;          field's OFFSET, which is an instruction operand.  What the parameter IS
;          is NOT established -- see the block comment above PartRec_ApplyParam_001D.
;          Reached through ENTRY 41 of Voice_ApplyParamChange_Dispatch's 49-entry
;          table at 0xFAF08F, whose word holds 0xFAF2DC, and that arm calls here.
;          ⚠ ENTRY NUMBER AND TARGET CODE ARE NOT THE SAME NUMBER: `dec 1,BC` at
;          0xFAF079 runs before the index, so entry 41 is RAW TARGET CODE 42.
;          An earlier draft of this header printed one number under both names and
;          had the arm index off by one as well; the ROM table and the arm's own
;          call are re-read by notes/prom_c_finish_round7.py --selftest.
;          Change mask pushed to PartRec_SetOrClearParamBits_x4: 0x0200 / 0x0200 = 1<<9.
; --------------------------------------------------------------------------
PartRec_ApplyParam_002B:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAEE4A  link XIZ,0x0000
	pushw	hl                                   ; FAEE4E  push HL
	ld	xbc, (xiz+12)                           ; FAEE4F  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FAEE52  push XBC
	push	0                                     ; FAEE53  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FAEE55  push (XIZ+0x0a)
	calr Scale7Bit_ByDepth_UniOrBipolar                 ; FAEE58  calr 0xfad5c2
	ld	hl, wa                                  ; FAEE5B  ld HL,WA
	ld	bc, (xiz+8)                             ; FAEE5D  ld BC,(XIZ+0x08)
	extz	bc                                    ; FAEE60  extz BC
	mul	bc, 0x12C                              ; FAEE62  mul BC,0x012c
	add	bc, 43                                 ; FAEE66  add BC,0x002b
	extz	xbc                                   ; FAEE6A  extz XBC
	ld	(xbc+0x1523), wa                        ; FAEE6C  ld (XBC+0x1523),WA
	pushw	0x200                                ; FAEE71  push 0x0200
	pushw	0x200                                ; FAEE74  push 0x0200
	ld	xbc, (xiz+12)                           ; FAEE77  ld XBC,(XIZ+0x0c)
	ld	a, (xbc)                                ; FAEE7A  ld A,(XBC)
	pushw	wa                                   ; FAEE7C  push WA
	push	0                                     ; FAEE7D  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAEE7F  push (XIZ+0x08)
	calr PartRec_SetOrClearParamBits_x4                 ; FAEE82  calr 0xfad203
	inc	8, xsp                                 ; FAEE85  inc 0,XSP
	inc	6, xsp                                 ; FAEE87  inc 6,XSP
	popw	hl                                    ; FAEE89  pop HL
	unlk32 xiz                                 ; FAEE8A  unlk XIZ
	ret                                        ; FAEE8C  ret
; --------------------------------------------------------------------------
; PartRec_ApplyParam_002D -- 0xFAEE8D..0xFAEECF (67 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAF2F1
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Calls:   0xFAD203 = PartRec_SetOrClearParamBits_x4, 0xFAD5C2 = Scale7Bit_ByDepth_UniOrBipolar
; Evidence: the listing below is the byte-identical round-trip of 0xFAEE8D-0xFAEECF
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7 finish pass).  APPLIES ONE WORD OF THE PART RECORD'S 12-WORD
;          PARAMETER BLOCK: it stores its normalised argument into part_record
;          +0x2D and then marks that parameter.
;          `mul BC,0x012C` (part-record stride) and `add BC,0x002D` at 0xFAEEA9 select
;          the word; `ld (XBC+0x1523),WA` at 0xFAEEAF stores it.
;          ⚠ THE NAME IS FRAMED, NOT CONTENT, AND DELIBERATELY SO: +0x2D is the
;          field's OFFSET, which is an instruction operand.  What the parameter IS
;          is NOT established -- see the block comment above PartRec_ApplyParam_001D.
;          Reached through ENTRY 42 of Voice_ApplyParamChange_Dispatch's 49-entry
;          table at 0xFAF08F, whose word holds 0xFAF2E9, and that arm calls here.
;          ⚠ ENTRY NUMBER AND TARGET CODE ARE NOT THE SAME NUMBER: `dec 1,BC` at
;          0xFAF079 runs before the index, so entry 42 is RAW TARGET CODE 43.
;          An earlier draft of this header printed one number under both names and
;          had the arm index off by one as well; the ROM table and the arm's own
;          call are re-read by notes/prom_c_finish_round7.py --selftest.
;          Change mask pushed to PartRec_SetOrClearParamBits_x4: 0x0400 / 0x0400 = 1<<10.
; --------------------------------------------------------------------------
PartRec_ApplyParam_002D:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAEE8D  link XIZ,0x0000
	pushw	hl                                   ; FAEE91  push HL
	ld	xbc, (xiz+12)                           ; FAEE92  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FAEE95  push XBC
	push	0                                     ; FAEE96  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FAEE98  push (XIZ+0x0a)
	calr Scale7Bit_ByDepth_UniOrBipolar                 ; FAEE9B  calr 0xfad5c2
	ld	hl, wa                                  ; FAEE9E  ld HL,WA
	ld	bc, (xiz+8)                             ; FAEEA0  ld BC,(XIZ+0x08)
	extz	bc                                    ; FAEEA3  extz BC
	mul	bc, 0x12C                              ; FAEEA5  mul BC,0x012c
	add	bc, 45                                 ; FAEEA9  add BC,0x002d
	extz	xbc                                   ; FAEEAD  extz XBC
	ld	(xbc+0x1523), wa                        ; FAEEAF  ld (XBC+0x1523),WA
	pushw	0x400                                ; FAEEB4  push 0x0400
	pushw	0x400                                ; FAEEB7  push 0x0400
	ld	xbc, (xiz+12)                           ; FAEEBA  ld XBC,(XIZ+0x0c)
	ld	a, (xbc)                                ; FAEEBD  ld A,(XBC)
	pushw	wa                                   ; FAEEBF  push WA
	push	0                                     ; FAEEC0  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAEEC2  push (XIZ+0x08)
	calr PartRec_SetOrClearParamBits_x4                 ; FAEEC5  calr 0xfad203
	inc	8, xsp                                 ; FAEEC8  inc 0,XSP
	inc	6, xsp                                 ; FAEECA  inc 6,XSP
	popw	hl                                    ; FAEECC  pop HL
	unlk32 xiz                                 ; FAEECD  unlk XIZ
	ret                                        ; FAEECF  ret
; --------------------------------------------------------------------------
; PartRec_ApplyParam_002F -- 0xFAEED0..0xFAEF23 (84 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAF2FE
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Calls:   0xFAD203 = PartRec_SetOrClearParamBits_x4, 0xFAD5C2 = Scale7Bit_ByDepth_UniOrBipolar
;          0xFADE2F = sub_FADE2F, 0xFB3C8B = VoiceQuery_Tag40_Part
; Evidence: the listing below is the byte-identical round-trip of 0xFAEED0-0xFAEF23
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7 finish pass).  APPLIES ONE WORD OF THE PART RECORD'S 12-WORD
;          PARAMETER BLOCK: it stores its normalised argument into part_record
;          +0x2F and then marks that parameter.
;          `mul BC,0x012C` (part-record stride) and `add BC,0x002F` at 0xFAEEEF select
;          the word; `ld (XBC+0x1523),WA` at 0xFAEEF5 stores it.
;          ⚠ THE NAME IS FRAMED, NOT CONTENT, AND DELIBERATELY SO: +0x2F is the
;          field's OFFSET, which is an instruction operand.  What the parameter IS
;          is NOT established -- see the block comment above PartRec_ApplyParam_001D.
;          Reached through ENTRY 43 of Voice_ApplyParamChange_Dispatch's 49-entry
;          table at 0xFAF08F, whose word holds 0xFAF2F6, and that arm calls here.
;          ⚠ ENTRY NUMBER AND TARGET CODE ARE NOT THE SAME NUMBER: `dec 1,BC` at
;          0xFAF079 runs before the index, so entry 43 is RAW TARGET CODE 44.
;          An earlier draft of this header printed one number under both names and
;          had the arm index off by one as well; the ROM table and the arm's own
;          call are re-read by notes/prom_c_finish_round7.py --selftest.
;          Change mask pushed to PartRec_SetOrClearParamBits_x4: 0x0800 / 0x0800 = 1<<11.
; --------------------------------------------------------------------------
PartRec_ApplyParam_002F:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAEED0  link XIZ,0x0000
	pushw	hl                                   ; FAEED4  push HL
	pushw	de                                   ; FAEED5  push DE
	ld	h, (xiz+8)                              ; FAEED6  ld H,(XIZ+0x08)
	ld	xbc, (xiz+12)                           ; FAEED9  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FAEEDC  push XBC
	push	0                                     ; FAEEDD  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FAEEDF  push (XIZ+0x0a)
	calr Scale7Bit_ByDepth_UniOrBipolar                 ; FAEEE2  calr 0xfad5c2
	ld	de, wa                                  ; FAEEE5  ld DE,WA
	ld	c, h                                    ; FAEEE7  ld C,H
	extz	bc                                    ; FAEEE9  extz BC
	mul	bc, 0x12C                              ; FAEEEB  mul BC,0x012c
	add	bc, 47                                 ; FAEEEF  add BC,0x002f
	extz	xbc                                   ; FAEEF3  extz XBC
	ld	(xbc+0x1523), wa                        ; FAEEF5  ld (XBC+0x1523),WA
	pushw	0x800                                ; FAEEFA  push 0x0800
	pushw	0x800                                ; FAEEFD  push 0x0800
	ld	xbc, (xiz+12)                           ; FAEF00  ld XBC,(XIZ+0x0c)
	ld	a, (xbc)                                ; FAEF03  ld A,(XBC)
	pushw	wa                                   ; FAEF05  push WA
	push	0                                     ; FAEF06  push 0x00
	push	h                                     ; FAEF08  push H
	calr PartRec_SetOrClearParamBits_x4                 ; FAEF0A  calr 0xfad203
	push	0                                     ; FAEF0D  push 0x00
	push	h                                     ; FAEF0F  push H
	call	VoiceQuery_Tag40_Part                              ; FAEF11  call 0xfb3c8b
	push	xiy                                   ; FAEF15  push XIY
	calr sub_FADE2F                 ; FAEF16  calr 0xfade2f
	add	xsp, 20                                ; FAEF19  add XSP,0x00000014
	popw	de                                    ; FAEF1F  pop DE
	popw	hl                                    ; FAEF20  pop HL
	unlk32 xiz                                 ; FAEF21  unlk XIZ
	ret                                        ; FAEF23  ret
; --------------------------------------------------------------------------
; PartRec_ApplyParam_0031 -- 0xFAEF24..0xFAEF7E (91 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAF30B
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Calls:   0xFAD203 = PartRec_SetOrClearParamBits_x4, 0xFAD5C2 = Scale7Bit_ByDepth_UniOrBipolar
;          0xFADEAC = sub_FADEAC, 0xFB3C8B = VoiceQuery_Tag40_Part
; Evidence: the listing below is the byte-identical round-trip of 0xFAEF24-0xFAEF7E
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7 finish pass).  APPLIES ONE WORD OF THE PART RECORD'S 12-WORD
;          PARAMETER BLOCK: it stores its normalised argument into part_record
;          +0x31 and then marks that parameter.
;          `mul BC,0x012C` (part-record stride) and `add BC,0x0031` at 0xFAEF44 select
;          the word; `ld (XBC+0x1523),WA` at 0xFAEF4A stores it.
;          ⚠ THE NAME IS FRAMED, NOT CONTENT, AND DELIBERATELY SO: +0x31 is the
;          field's OFFSET, which is an instruction operand.  What the parameter IS
;          is NOT established -- see the block comment above PartRec_ApplyParam_001D.
;          Reached through ENTRY 44 of Voice_ApplyParamChange_Dispatch's 49-entry
;          table at 0xFAF08F, whose word holds 0xFAF303, and that arm calls here.
;          ⚠ ENTRY NUMBER AND TARGET CODE ARE NOT THE SAME NUMBER: `dec 1,BC` at
;          0xFAF079 runs before the index, so entry 44 is RAW TARGET CODE 45.
;          An earlier draft of this header printed one number under both names and
;          had the arm index off by one as well; the ROM table and the arm's own
;          call are re-read by notes/prom_c_finish_round7.py --selftest.
;          Change mask pushed to PartRec_SetOrClearParamBits_x4: 0x1000 / 0x1000 = 1<<12.
; --------------------------------------------------------------------------
PartRec_ApplyParam_0031:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAEF24  link XIZ,0x0000
	pushw	hl                                   ; FAEF28  push HL
	pushw	de                                   ; FAEF29  push DE
	push	xix                                   ; FAEF2A  push XIX
	ld	h, (xiz+8)                              ; FAEF2B  ld H,(XIZ+0x08)
	ld	xbc, (xiz+12)                           ; FAEF2E  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FAEF31  push XBC
	push	0                                     ; FAEF32  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FAEF34  push (XIZ+0x0a)
	calr Scale7Bit_ByDepth_UniOrBipolar                 ; FAEF37  calr 0xfad5c2
	ld	de, wa                                  ; FAEF3A  ld DE,WA
	ld	c, h                                    ; FAEF3C  ld C,H
	extz	bc                                    ; FAEF3E  extz BC
	mul	bc, 0x12C                              ; FAEF40  mul BC,0x012c
	add	bc, 49                                 ; FAEF44  add BC,0x0031
	extz	xbc                                   ; FAEF48  extz XBC
	ld	(xbc+0x1523), wa                        ; FAEF4A  ld (XBC+0x1523),WA
	pushw	0x1000                               ; FAEF4F  push 0x1000
	pushw	0x1000                               ; FAEF52  push 0x1000
	ld	xbc, (xiz+12)                           ; FAEF55  ld XBC,(XIZ+0x0c)
	ld	a, (xbc)                                ; FAEF58  ld A,(XBC)
	pushw	wa                                   ; FAEF5A  push WA
	push	0                                     ; FAEF5B  push 0x00
	push	h                                     ; FAEF5D  push H
	calr PartRec_SetOrClearParamBits_x4                 ; FAEF5F  calr 0xfad203
	push	0                                     ; FAEF62  push 0x00
	push	h                                     ; FAEF64  push H
	call	VoiceQuery_Tag40_Part                              ; FAEF66  call 0xfb3c8b
	ld	xix, xiy                                ; FAEF6A  ld XIX,XIY
	pushw	0                                    ; FAEF6C  push 0x0000
	push	xiy                                   ; FAEF6F  push XIY
	calr sub_FADEAC                 ; FAEF70  calr 0xfadeac
	add	xsp, 22                                ; FAEF73  add XSP,0x00000016
	pop	xix                                    ; FAEF79  pop XIX
	popw	de                                    ; FAEF7A  pop DE
	popw	hl                                    ; FAEF7B  pop HL
	unlk32 xiz                                 ; FAEF7C  unlk XIZ
	ret                                        ; FAEF7E  ret
; --------------------------------------------------------------------------
; PartRec_ApplyParam_0033 -- 0xFAEF7F..0xFAEFC1 (67 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAF318
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Calls:   0xFAD203 = PartRec_SetOrClearParamBits_x4, 0xFAD4FE = Scale7Bit_ByDepth_UniOrBipolar_Shl2
; Evidence: the listing below is the byte-identical round-trip of 0xFAEF7F-0xFAEFC1
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7 finish pass).  APPLIES ONE WORD OF THE PART RECORD'S 12-WORD
;          PARAMETER BLOCK: it stores its normalised argument into part_record
;          +0x33 and then marks that parameter.
;          `mul BC,0x012C` (part-record stride) and `add BC,0x0033` at 0xFAEF9B select
;          the word; `ld (XBC+0x1523),WA` at 0xFAEFA1 stores it.
;          ⚠ THE NAME IS FRAMED, NOT CONTENT, AND DELIBERATELY SO: +0x33 is the
;          field's OFFSET, which is an instruction operand.  What the parameter IS
;          is NOT established -- see the block comment above PartRec_ApplyParam_001D.
;          Reached through ENTRY 45 of Voice_ApplyParamChange_Dispatch's 49-entry
;          table at 0xFAF08F, whose word holds 0xFAF310, and that arm calls here.
;          ⚠ ENTRY NUMBER AND TARGET CODE ARE NOT THE SAME NUMBER: `dec 1,BC` at
;          0xFAF079 runs before the index, so entry 45 is RAW TARGET CODE 46.
;          An earlier draft of this header printed one number under both names and
;          had the arm index off by one as well; the ROM table and the arm's own
;          call are re-read by notes/prom_c_finish_round7.py --selftest.
;          Change mask pushed to PartRec_SetOrClearParamBits_x4: 0x2000 / 0x2000 = 1<<13.
; --------------------------------------------------------------------------
PartRec_ApplyParam_0033:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAEF7F  link XIZ,0x0000
	pushw	hl                                   ; FAEF83  push HL
	ld	xbc, (xiz+12)                           ; FAEF84  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FAEF87  push XBC
	push	0                                     ; FAEF88  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FAEF8A  push (XIZ+0x0a)
	calr Scale7Bit_ByDepth_UniOrBipolar_Shl2                 ; FAEF8D  calr 0xfad4fe
	ld	hl, wa                                  ; FAEF90  ld HL,WA
	ld	bc, (xiz+8)                             ; FAEF92  ld BC,(XIZ+0x08)
	extz	bc                                    ; FAEF95  extz BC
	mul	bc, 0x12C                              ; FAEF97  mul BC,0x012c
	add	bc, 51                                 ; FAEF9B  add BC,0x0033
	extz	xbc                                   ; FAEF9F  extz XBC
	ld	(xbc+0x1523), wa                        ; FAEFA1  ld (XBC+0x1523),WA
	pushw	0x2000                               ; FAEFA6  push 0x2000
	pushw	0x2000                               ; FAEFA9  push 0x2000
	ld	xbc, (xiz+12)                           ; FAEFAC  ld XBC,(XIZ+0x0c)
	ld	a, (xbc)                                ; FAEFAF  ld A,(XBC)
	pushw	wa                                   ; FAEFB1  push WA
	push	0                                     ; FAEFB2  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAEFB4  push (XIZ+0x08)
	calr PartRec_SetOrClearParamBits_x4                 ; FAEFB7  calr 0xfad203
	inc	8, xsp                                 ; FAEFBA  inc 0,XSP
	inc	6, xsp                                 ; FAEFBC  inc 6,XSP
	popw	hl                                    ; FAEFBE  pop HL
	unlk32 xiz                                 ; FAEFBF  unlk XIZ
	ret                                        ; FAEFC1  ret
; --------------------------------------------------------------------------
; sub_FAEFC2 -- 0xFAEFC2..0xFAEFE6 (37 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAF323
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Calls:   0xFA267A = Rec8644_Store3Bytes_AndFlagChanged
; Evidence: the listing below is the byte-identical round-trip of 0xFAEFC2-0xFAEFE6
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FAEFC2:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAEFC2  link XIZ,0x0000
	ld	xbc, (xiz+10)                           ; FAEFC6  ld XBC,(XIZ+0x0a)
	ld	a, (xbc+2)                              ; FAEFC9  ld A,(XBC+0x02)
	extz	wa                                    ; FAEFCC  extz WA
	pushw	wa                                   ; FAEFCE  push WA
	ld	a, (xbc+1)                              ; FAEFCF  ld A,(XBC+0x01)
	extz	wa                                    ; FAEFD2  extz WA
	pushw	wa                                   ; FAEFD4  push WA
	ld	wa, (xiz+8)                             ; FAEFD5  ld WA,(XIZ+0x08)
	extz	wa                                    ; FAEFD8  extz WA
	pushw	wa                                   ; FAEFDA  push WA
	pushw	0                                    ; FAEFDB  push 0x0000
	call	Rec8644_Store3Bytes_AndFlagChanged                              ; FAEFDE  call 0xfa267a
	inc	8, xsp                                 ; FAEFE2  inc 0,XSP
	unlk32 xiz                                 ; FAEFE4  unlk XIZ
	ret                                        ; FAEFE6  ret
; --------------------------------------------------------------------------
; sub_FAEFE7 -- 0xFAEFE7..0xFAF00B (37 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAF32C
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Calls:   0xFA267A = Rec8644_Store3Bytes_AndFlagChanged
; Evidence: the listing below is the byte-identical round-trip of 0xFAEFE7-0xFAF00B
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FAEFE7:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAEFE7  link XIZ,0x0000
	ld	xbc, (xiz+10)                           ; FAEFEB  ld XBC,(XIZ+0x0a)
	ld	a, (xbc+2)                              ; FAEFEE  ld A,(XBC+0x02)
	extz	wa                                    ; FAEFF1  extz WA
	pushw	wa                                   ; FAEFF3  push WA
	ld	a, (xbc+1)                              ; FAEFF4  ld A,(XBC+0x01)
	extz	wa                                    ; FAEFF7  extz WA
	pushw	wa                                   ; FAEFF9  push WA
	ld	wa, (xiz+8)                             ; FAEFFA  ld WA,(XIZ+0x08)
	extz	wa                                    ; FAEFFD  extz WA
	pushw	wa                                   ; FAEFFF  push WA
	pushw	1                                    ; FAF000  push 0x0001
	call	Rec8644_Store3Bytes_AndFlagChanged                              ; FAF003  call 0xfa267a
	inc	8, xsp                                 ; FAF007  inc 0,XSP
	unlk32 xiz                                 ; FAF009  unlk XIZ
	ret                                        ; FAF00B  ret
; --------------------------------------------------------------------------
; sub_FAF00C -- 0xFAF00C..0xFAF030 (37 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAF335
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Calls:   0xFA267A = Rec8644_Store3Bytes_AndFlagChanged
; Evidence: the listing below is the byte-identical round-trip of 0xFAF00C-0xFAF030
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FAF00C:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAF00C  link XIZ,0x0000
	ld	xbc, (xiz+10)                           ; FAF010  ld XBC,(XIZ+0x0a)
	ld	a, (xbc+2)                              ; FAF013  ld A,(XBC+0x02)
	extz	wa                                    ; FAF016  extz WA
	pushw	wa                                   ; FAF018  push WA
	ld	a, (xbc+1)                              ; FAF019  ld A,(XBC+0x01)
	extz	wa                                    ; FAF01C  extz WA
	pushw	wa                                   ; FAF01E  push WA
	ld	wa, (xiz+8)                             ; FAF01F  ld WA,(XIZ+0x08)
	extz	wa                                    ; FAF022  extz WA
	pushw	wa                                   ; FAF024  push WA
	pushw	2                                    ; FAF025  push 0x0002
	call	Rec8644_Store3Bytes_AndFlagChanged                              ; FAF028  call 0xfa267a
	inc	8, xsp                                 ; FAF02C  inc 0,XSP
	unlk32 xiz                                 ; FAF02E  unlk XIZ
	ret                                        ; FAF030  ret
; --------------------------------------------------------------------------
; Voice_ApplyParamChange_Dispatch -- 0xFAF031..0xFAF33F (783 bytes)
;
; Called from: 50 site(s) outside this module:
;          0xFB8DE4 in sub_FB8CEC__FB8DCC, 0xFB8E02 in sub_FB8CEC__FB8DCC
;          0xFB8E4B in sub_FB8CEC__FB8E33, 0xFB8E69 in sub_FB8CEC__FB8E33
;          0xFB8F90 in sub_FB8CEC__FB8F56, 0xFB8FCB in sub_FB8CEC__FB8F56
;          0xFB904C in sub_FB8CEC__FB9012, 0xFB9087 in sub_FB8CEC__FB9012
;          0xFBB7CE in sub_FBB793__FBB7BC, 0xFBB7E9 in sub_FBB793__FBB7D7
;          0xFBB804 in sub_FBB793__FBB7F2, 0xFBB81F in sub_FBB793__FBB80D
;          0xFBB83A in sub_FBB793__FBB828, 0xFBB855 in sub_FBB793__FBB843
;          0xFBB870 in sub_FBB793__FBB85E, 0xFBB88B in sub_FBB793__FBB879
;          0xFBB8A6 in sub_FBB793__FBB894, 0xFBB8C1 in sub_FBB793__FBB8AF
;          0xFBB8DC in sub_FBB793__FBB8CA, 0xFBB8F7 in sub_FBB793__FBB8E5
;          0xFBB912 in sub_FBB793__FBB900, 0xFBB92D in sub_FBB793__FBB91B
;          0xFBB948 in sub_FBB793__FBB936, 0xFBB963 in sub_FBB793__FBB951
;          0xFBB97E in sub_FBB793__FBB96C, 0xFBB999 in sub_FBB793__FBB987
;          0xFBB9B4 in sub_FBB793__FBB9A2, 0xFBB9CF in sub_FBB793__FBB9BD
;          0xFBB9EA in sub_FBB793__FBB9D8, 0xFBCD5F in sub_FBCD17__FBCD4D
;          0xFBCD7A in sub_FBCD17__FBCD68, 0xFBCD95 in sub_FBCD17__FBCD83
;          0xFBCDB0 in sub_FBCD17__FBCD9E, 0xFBCDCB in sub_FBCD17__FBCDB9
;          0xFBCDE6 in sub_FBCD17__FBCDD4, 0xFBCE01 in sub_FBCD17__FBCDEF
;          0xFBCE1C in sub_FBCD17__FBCE0A, 0xFBCE37 in sub_FBCD17__FBCE25
;          0xFBCE52 in sub_FBCD17__FBCE40, 0xFBCE6D in sub_FBCD17__FBCE5B
;          0xFBCE88 in sub_FBCD17__FBCE76, 0xFBCEA3 in sub_FBCD17__FBCE91
;          0xFBCEBE in sub_FBCD17__FBCEAC, 0xFBCED9 in sub_FBCD17__FBCEC7
;          0xFBCEF4 in sub_FBCD17__FBCEE2, 0xFBCF0F in sub_FBCD17__FBCEFD
;          0xFBCF2A in sub_FBCD17__FBCF18, 0xFBCF45 in sub_FBCD17__FBCF33
;          0xFBCF60 in sub_FBCD17__FBCF4E, 0xFBCF7B in sub_FBCD17__FBCF69
;          18 site(s) inside this module:
;          0xFAF442 0xFAF4A7 0xFAF553 0xFAF5B8 0xFAF666 0xFAF6C6
;          0xFAF7A7 0xFAF817 0xFAF91E 0xFAF98C 0xFAFA74 0xFAFAAE
;          0xFAFB77 0xFAFBB1 0xFB0099 0xFB00FC 0xFB01B2 0xFB01D7
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Calls:   0xFAE109 = PartRec_ApplyParam_001D, 0xFAE15F = PartRec_ApplyParam_0021
;          0xFAE1B2 = PartRec_ApplyParam_001F, 0xFAE34A = Voice_Restage_Reg0440_BaseCurve_ForPart
;          0xFAE484 = Voice_Restage_Reg0440_ValueCurve_ForPart, 0xFAE5C7 = Voice_Restage_Reg0180_BaseCurve_ForPart
;          0xFAE703 = Voice_Restage_Reg0180_ValueCurve_ForPart, 0xFAE848 = Voice_Restage_Reg04C0_BaseCurve_ForPart
;          0xFAE986 = Voice_Restage_Reg04C0_ValueCurve_ForPart, 0xFAEACE = sub_FAEACE
;          0xFAEAF9 = sub_FAEAF9, 0xFAEB65 = sub_FAEB65
;          0xFAEBD1 = sub_FAEBD1, 0xFAEC21 = sub_FAEC21
;          0xFAEC71 = sub_FAEC71, 0xFAEC9C = sub_FAEC9C
;          0xFAECC7 = sub_FAECC7, 0xFAED33 = PartRec_ApplyParam_0023
;          0xFAED76 = PartRec_ApplyParam_0025, 0xFAEDC4 = PartRec_ApplyParam_0027
;          0xFAEE07 = PartRec_ApplyParam_0029, 0xFAEE4A = PartRec_ApplyParam_002B
;          0xFAEE8D = PartRec_ApplyParam_002D, 0xFAEED0 = PartRec_ApplyParam_002F
;          0xFAEF24 = PartRec_ApplyParam_0031, 0xFAEF7F = PartRec_ApplyParam_0033
;          0xFAEFC2 = sub_FAEFC2, 0xFAEFE7 = sub_FAEFE7
;          0xFAF00C = sub_FAF00C
; Arms:    48 computed-goto arm(s) inside this routine: 0xFAF153 0xFAF15F 0xFAF16B 0xFAF177 0xFAF17C 0xFAF181 0xFAF186 0xFAF19B 0xFAF1A0 0xFAF1A5 0xFAF1AA 0xFAF1BA 0xFAF1BF 0xFAF1C4 0xFAF1C9 0xFAF1D9 0xFAF1DE 0xFAF1E3 0xFAF1E8 0xFAF1F8 0xFAF1FD 0xFAF202 0xFAF207 0xFAF218 0xFAF21D 0xFAF222 0xFAF227 0xFAF238 0xFAF246 0xFAF254 0xFAF262 0xFAF270 0xFAF27E 0xFAF28C 0xFAF29A 0xFAF2A8 0xFAF2B5 0xFAF2C2 0xFAF2CF 0xFAF2DC 0xFAF2E9 0xFAF2F6 0xFAF303 0xFAF310 0xFAF31F 0xFAF328 0xFAF331 0xFAF33A
; Evidence: the listing below is the byte-identical round-trip of 0xFAF031-0xFAF33F
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ ROUND 6 ------------------------------------------------------------
; ★★ Voice_ApplyParamChange_Dispatch -- the routine
;          that pushes ONE changed parameter back out to the hardware.  68 call sites in
;          prom_c, seven of them inside named MIDI controller handlers (MidiCtrl_CC01, CC02,
;          CC04, CC16, CC17, CC18, CC19).
;          H  = (XIZ+0x08)   a part or voice selector
;          DE = (XIZ+0x0a)   the new value
;          XIX= (XIZ+0x0c)   a record whose byte +1 carries the 6-bit TARGET CODE
;          `ld L,(XIX+0x01) / and L,0x3f` at 0xFAF041 and 0xFAF044 takes the code; the value is
;          then normalised -- for code 1, `DE & 0x8000 ? DE &= 0x7FFF : DE <<= 7`
;          (0xFAF04D-0xFAF05A); for every other code, `DE & 0x8000 ? DE = (DE & 0x7FFF) >> 7`
;          (0xFAF063-0xFAF06E).  Then `dec 1,BC / cp BC,0x30 / jrl UGT` (0xFAF079-0xFAF07F)
;          bounds the index to 0..48 and `sll 2,BC / add XBC,0x00FAF08F / ld XBC,(XBC) /
;          jp (XBC)` dispatches through a 49-entry table.
;          ★ THE TABLE IS 49 ENTRIES AND 48 DISTINCT ARMS, and the two facts are independent:
;          0xFAF08F + 4*49 = 0xFAF153, which is exactly where the first arm begins, and entry
;          0 and the out-of-range path both reach 0xFAF33A.
;          Evidence: every address above is an instruction operand; the table is read out of
;          the ROM bytes and the arm count, the last entry and the 68 call sites are asserted
;          by `python3 notes/prom_c_understanding_round6.py --dispatch`.
;          Unknown: what the 6-bit target code MEANS, i.e. what parameter each of the 49
;          entries is.  The arms are named for the REGISTER each one refreshes, which is an
;          instruction operand, and for nothing else.
; --------------------------------------------------------------------------
Voice_ApplyParamChange_Dispatch:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAF031  link XIZ,0x0000
	pushw	hl                                   ; FAF035  push HL
	pushw	de                                   ; FAF036  push DE
	push	xix                                   ; FAF037  push XIX
	ld	xix, (xiz+12)                           ; FAF038  ld XIX,(XIZ+0x0c)
	ld	de, (xiz+10)                            ; FAF03B  ld DE,(XIZ+0x0a)
	ld	h, (xiz+8)                              ; FAF03E  ld H,(XIZ+0x08)
	ld	l, (xix+1)                              ; FAF041  ld L,(XIX+0x01)
	and	l, 63                                  ; FAF044  and L,0x3f
	cp	l, 1:i3                                   ; FAF047  cp L,1
	jr nz, Voice_ApplyParamChange_Dispatch__FAF061                  ; FAF049  jr NZ,0xfaf061
	ld	bc, de                                  ; FAF04B  ld BC,DE
	and	bc, 0x8000                             ; FAF04D  and BC,0x8000
	jr z, Voice_ApplyParamChange_Dispatch__FAF058                   ; FAF051  jr Z,0xfaf058
	res	15, de                                 ; FAF053  res 0x0f,DE
	jr Voice_ApplyParamChange_Dispatch__FAF073                      ; FAF056  jr T,0xfaf073
Voice_ApplyParamChange_Dispatch__FAF058:
	ld	bc, de                                  ; FAF058  ld BC,DE
	sll	bc, 7                                  ; FAF05A  sll 0x07,BC
	ld	de, bc                                  ; FAF05D  ld DE,BC
	jr Voice_ApplyParamChange_Dispatch__FAF073                      ; FAF05F  jr T,0xfaf073
Voice_ApplyParamChange_Dispatch__FAF061:
	ld	bc, de                                  ; FAF061  ld BC,DE
	and	bc, 0x8000                             ; FAF063  and BC,0x8000
	jr z, Voice_ApplyParamChange_Dispatch__FAF073                   ; FAF067  jr Z,0xfaf073
	res	15, de                                 ; FAF069  res 0x0f,DE
	ld	bc, de                                  ; FAF06C  ld BC,DE
	srl	bc, 7                                  ; FAF06E  srl 0x07,BC
	ld	de, bc                                  ; FAF071  ld DE,BC
Voice_ApplyParamChange_Dispatch__FAF073:
	ld	c, l                                    ; FAF073  ld C,L
	extz	bc                                    ; FAF075  extz BC
	extz	xbc                                   ; FAF077  extz XBC
	dec	1, bc                                  ; FAF079  dec 1,BC
	cp	bc, 48                                  ; FAF07B  cp BC,0x0030
	jrl ugt, Voice_ApplyParamChange_Dispatch__FAF33A                ; FAF07F  jrl UGT,0xfaf33a
	sll	bc, 2                                  ; FAF082  sll 0x02,BC
	add	xbc, 0xFAF08F                          ; FAF085  add XBC,0x00faf08f
	ld	xbc, (xbc)                              ; FAF08B  ld XBC,(XBC)
	jp	(xbc)                                   ; FAF08D  jp T,XBC
; 49 x u32 computed-goto table, 0xFAF08F-0xFAF152, 196 bytes.
; THE ENTRY COUNT IS ESTABLISHED TWICE AND THE TWO AGREE: the `cp rr,48`
; guard before the `jr UGT` gives 49, and reading consecutive words while
; each is a plausible code address also gives 49.  The word after the last
; entry is not a plausible entry, so the table ends here rather than being
; assumed to.  (python3 notes/prom_c_jumptables.py 0xFAD142 0xFB0504;
; asserted per table by notes/prom_c_voiceparam_checks.py section 2.)
; Entry 0 is the SAME address the out-of-range guard branches to.
	.long 0x00FAF153	; 0xFAF08F  entry 0 -> 0xFAF153   (also the out-of-range arm)
	.long 0x00FAF15F	; 0xFAF093  entry 1 -> 0xFAF15F
	.long 0x00FAF16B	; 0xFAF097  entry 2 -> 0xFAF16B
	.long 0x00FAF177	; 0xFAF09B  entry 3 -> 0xFAF177
	.long 0x00FAF17C	; 0xFAF09F  entry 4 -> 0xFAF17C
	.long 0x00FAF181	; 0xFAF0A3  entry 5 -> 0xFAF181
	.long 0x00FAF186	; 0xFAF0A7  entry 6 -> 0xFAF186
	.long 0x00FAF19B	; 0xFAF0AB  entry 7 -> 0xFAF19B
	.long 0x00FAF1A0	; 0xFAF0AF  entry 8 -> 0xFAF1A0
	.long 0x00FAF1A5	; 0xFAF0B3  entry 9 -> 0xFAF1A5
	.long 0x00FAF1AA	; 0xFAF0B7  entry 10 -> 0xFAF1AA
	.long 0x00FAF1BA	; 0xFAF0BB  entry 11 -> 0xFAF1BA
	.long 0x00FAF1BF	; 0xFAF0BF  entry 12 -> 0xFAF1BF
	.long 0x00FAF1C4	; 0xFAF0C3  entry 13 -> 0xFAF1C4
	.long 0x00FAF1C9	; 0xFAF0C7  entry 14 -> 0xFAF1C9
	.long 0x00FAF1D9	; 0xFAF0CB  entry 15 -> 0xFAF1D9
	.long 0x00FAF1DE	; 0xFAF0CF  entry 16 -> 0xFAF1DE
	.long 0x00FAF1E3	; 0xFAF0D3  entry 17 -> 0xFAF1E3
	.long 0x00FAF1E8	; 0xFAF0D7  entry 18 -> 0xFAF1E8
	.long 0x00FAF1F8	; 0xFAF0DB  entry 19 -> 0xFAF1F8
	.long 0x00FAF1FD	; 0xFAF0DF  entry 20 -> 0xFAF1FD
	.long 0x00FAF202	; 0xFAF0E3  entry 21 -> 0xFAF202
	.long 0x00FAF207	; 0xFAF0E7  entry 22 -> 0xFAF207
	.long 0x00FAF218	; 0xFAF0EB  entry 23 -> 0xFAF218
	.long 0x00FAF21D	; 0xFAF0EF  entry 24 -> 0xFAF21D
	.long 0x00FAF222	; 0xFAF0F3  entry 25 -> 0xFAF222
	.long 0x00FAF227	; 0xFAF0F7  entry 26 -> 0xFAF227
	.long 0x00FAF238	; 0xFAF0FB  entry 27 -> 0xFAF238
	.long 0x00FAF246	; 0xFAF0FF  entry 28 -> 0xFAF246
	.long 0x00FAF254	; 0xFAF103  entry 29 -> 0xFAF254
	.long 0x00FAF33A	; 0xFAF107  entry 30 -> 0xFAF33A
	.long 0x00FAF262	; 0xFAF10B  entry 31 -> 0xFAF262
	.long 0x00FAF270	; 0xFAF10F  entry 32 -> 0xFAF270
	.long 0x00FAF33A	; 0xFAF113  entry 33 -> 0xFAF33A
	.long 0x00FAF27E	; 0xFAF117  entry 34 -> 0xFAF27E
	.long 0x00FAF28C	; 0xFAF11B  entry 35 -> 0xFAF28C
	.long 0x00FAF29A	; 0xFAF11F  entry 36 -> 0xFAF29A
	.long 0x00FAF2A8	; 0xFAF123  entry 37 -> 0xFAF2A8
	.long 0x00FAF2B5	; 0xFAF127  entry 38 -> 0xFAF2B5
	.long 0x00FAF2C2	; 0xFAF12B  entry 39 -> 0xFAF2C2
	.long 0x00FAF2CF	; 0xFAF12F  entry 40 -> 0xFAF2CF
	.long 0x00FAF2DC	; 0xFAF133  entry 41 -> 0xFAF2DC
	.long 0x00FAF2E9	; 0xFAF137  entry 42 -> 0xFAF2E9
	.long 0x00FAF2F6	; 0xFAF13B  entry 43 -> 0xFAF2F6
	.long 0x00FAF303	; 0xFAF13F  entry 44 -> 0xFAF303
	.long 0x00FAF310	; 0xFAF143  entry 45 -> 0xFAF310
	.long 0x00FAF31F	; 0xFAF147  entry 46 -> 0xFAF31F
	.long 0x00FAF328	; 0xFAF14B  entry 47 -> 0xFAF328
	.long 0x00FAF331	; 0xFAF14F  entry 48 -> 0xFAF331
Voice_ApplyParamChange_Dispatch__FAF153:
	push	xix                                   ; FAF153  push XIX
	pushw	de                                   ; FAF154  push DE
	push	0                                     ; FAF155  push 0x00
	push	h                                     ; FAF157  push H
	calr PartRec_ApplyParam_001D                 ; FAF159  calr 0xfae109
	jrl Voice_ApplyParamChange_Dispatch__FAF31B                     ; FAF15C  jrl T,0xfaf31b
Voice_ApplyParamChange_Dispatch__FAF15F:
	push	xix                                   ; FAF15F  push XIX
	pushw	de                                   ; FAF160  push DE
	push	0                                     ; FAF161  push 0x00
	push	h                                     ; FAF163  push H
	calr PartRec_ApplyParam_001F                 ; FAF165  calr 0xfae1b2
	jrl Voice_ApplyParamChange_Dispatch__FAF31B                     ; FAF168  jrl T,0xfaf31b
Voice_ApplyParamChange_Dispatch__FAF16B:
	push	xix                                   ; FAF16B  push XIX
	pushw	de                                   ; FAF16C  push DE
	push	0                                     ; FAF16D  push 0x00
	push	h                                     ; FAF16F  push H
	calr PartRec_ApplyParam_0021                 ; FAF171  calr 0xfae15f
	jrl Voice_ApplyParamChange_Dispatch__FAF31B                     ; FAF174  jrl T,0xfaf31b
Voice_ApplyParamChange_Dispatch__FAF177:
	pushw	0                                    ; FAF177  push 0x0000
	jr Voice_ApplyParamChange_Dispatch__FAF189                      ; FAF17A  jr T,0xfaf189
Voice_ApplyParamChange_Dispatch__FAF17C:
	pushw	1                                    ; FAF17C  push 0x0001
	jr Voice_ApplyParamChange_Dispatch__FAF189                      ; FAF17F  jr T,0xfaf189
Voice_ApplyParamChange_Dispatch__FAF181:
	pushw	2                                    ; FAF181  push 0x0002
	jr Voice_ApplyParamChange_Dispatch__FAF189                      ; FAF184  jr T,0xfaf189
Voice_ApplyParamChange_Dispatch__FAF186:
	pushw	3                                    ; FAF186  push 0x0003
Voice_ApplyParamChange_Dispatch__FAF189:
	push	xix                                   ; FAF189  push XIX
	ld	c, e                                    ; FAF18A  ld C,E
	pushw	bc                                   ; FAF18C  push BC
	push	0                                     ; FAF18D  push 0x00
	push	h                                     ; FAF18F  push H
	calr Voice_Restage_Reg0440_BaseCurve_ForPart                 ; FAF191  calr 0xfae34a
Voice_ApplyParamChange_Dispatch__FAF194:
	inc	8, xsp                                 ; FAF194  inc 0,XSP
	inc	2, xsp                                 ; FAF196  inc 2,XSP
	jrl Voice_ApplyParamChange_Dispatch__FAF33A                     ; FAF198  jrl T,0xfaf33a
Voice_ApplyParamChange_Dispatch__FAF19B:
	pushw	0                                    ; FAF19B  push 0x0000
	jr Voice_ApplyParamChange_Dispatch__FAF1AD                      ; FAF19E  jr T,0xfaf1ad
Voice_ApplyParamChange_Dispatch__FAF1A0:
	pushw	1                                    ; FAF1A0  push 0x0001
	jr Voice_ApplyParamChange_Dispatch__FAF1AD                      ; FAF1A3  jr T,0xfaf1ad
Voice_ApplyParamChange_Dispatch__FAF1A5:
	pushw	2                                    ; FAF1A5  push 0x0002
	jr Voice_ApplyParamChange_Dispatch__FAF1AD                      ; FAF1A8  jr T,0xfaf1ad
Voice_ApplyParamChange_Dispatch__FAF1AA:
	pushw	3                                    ; FAF1AA  push 0x0003
Voice_ApplyParamChange_Dispatch__FAF1AD:
	push	xix                                   ; FAF1AD  push XIX
	ld	c, e                                    ; FAF1AE  ld C,E
	pushw	bc                                   ; FAF1B0  push BC
	push	0                                     ; FAF1B1  push 0x00
	push	h                                     ; FAF1B3  push H
	calr Voice_Restage_Reg0180_BaseCurve_ForPart                 ; FAF1B5  calr 0xfae5c7
	jr Voice_ApplyParamChange_Dispatch__FAF194                      ; FAF1B8  jr T,0xfaf194
Voice_ApplyParamChange_Dispatch__FAF1BA:
	pushw	0                                    ; FAF1BA  push 0x0000
	jr Voice_ApplyParamChange_Dispatch__FAF1CC                      ; FAF1BD  jr T,0xfaf1cc
Voice_ApplyParamChange_Dispatch__FAF1BF:
	pushw	1                                    ; FAF1BF  push 0x0001
	jr Voice_ApplyParamChange_Dispatch__FAF1CC                      ; FAF1C2  jr T,0xfaf1cc
Voice_ApplyParamChange_Dispatch__FAF1C4:
	pushw	2                                    ; FAF1C4  push 0x0002
	jr Voice_ApplyParamChange_Dispatch__FAF1CC                      ; FAF1C7  jr T,0xfaf1cc
Voice_ApplyParamChange_Dispatch__FAF1C9:
	pushw	3                                    ; FAF1C9  push 0x0003
Voice_ApplyParamChange_Dispatch__FAF1CC:
	push	xix                                   ; FAF1CC  push XIX
	ld	c, e                                    ; FAF1CD  ld C,E
	pushw	bc                                   ; FAF1CF  push BC
	push	0                                     ; FAF1D0  push 0x00
	push	h                                     ; FAF1D2  push H
	calr Voice_Restage_Reg04C0_BaseCurve_ForPart                 ; FAF1D4  calr 0xfae848
	jr Voice_ApplyParamChange_Dispatch__FAF194                      ; FAF1D7  jr T,0xfaf194
Voice_ApplyParamChange_Dispatch__FAF1D9:
	pushw	0                                    ; FAF1D9  push 0x0000
	jr Voice_ApplyParamChange_Dispatch__FAF1EB                      ; FAF1DC  jr T,0xfaf1eb
Voice_ApplyParamChange_Dispatch__FAF1DE:
	pushw	1                                    ; FAF1DE  push 0x0001
	jr Voice_ApplyParamChange_Dispatch__FAF1EB                      ; FAF1E1  jr T,0xfaf1eb
Voice_ApplyParamChange_Dispatch__FAF1E3:
	pushw	2                                    ; FAF1E3  push 0x0002
	jr Voice_ApplyParamChange_Dispatch__FAF1EB                      ; FAF1E6  jr T,0xfaf1eb
Voice_ApplyParamChange_Dispatch__FAF1E8:
	pushw	3                                    ; FAF1E8  push 0x0003
Voice_ApplyParamChange_Dispatch__FAF1EB:
	push	xix                                   ; FAF1EB  push XIX
	ld	c, e                                    ; FAF1EC  ld C,E
	pushw	bc                                   ; FAF1EE  push BC
	push	0                                     ; FAF1EF  push 0x00
	push	h                                     ; FAF1F1  push H
	calr Voice_Restage_Reg0440_ValueCurve_ForPart                 ; FAF1F3  calr 0xfae484
	jr Voice_ApplyParamChange_Dispatch__FAF194                      ; FAF1F6  jr T,0xfaf194
Voice_ApplyParamChange_Dispatch__FAF1F8:
	pushw	0                                    ; FAF1F8  push 0x0000
	jr Voice_ApplyParamChange_Dispatch__FAF20A                      ; FAF1FB  jr T,0xfaf20a
Voice_ApplyParamChange_Dispatch__FAF1FD:
	pushw	1                                    ; FAF1FD  push 0x0001
	jr Voice_ApplyParamChange_Dispatch__FAF20A                      ; FAF200  jr T,0xfaf20a
Voice_ApplyParamChange_Dispatch__FAF202:
	pushw	2                                    ; FAF202  push 0x0002
	jr Voice_ApplyParamChange_Dispatch__FAF20A                      ; FAF205  jr T,0xfaf20a
Voice_ApplyParamChange_Dispatch__FAF207:
	pushw	3                                    ; FAF207  push 0x0003
Voice_ApplyParamChange_Dispatch__FAF20A:
	push	xix                                   ; FAF20A  push XIX
	ld	c, e                                    ; FAF20B  ld C,E
	pushw	bc                                   ; FAF20D  push BC
	push	0                                     ; FAF20E  push 0x00
	push	h                                     ; FAF210  push H
	calr Voice_Restage_Reg0180_ValueCurve_ForPart                 ; FAF212  calr 0xfae703
	jrl Voice_ApplyParamChange_Dispatch__FAF194                     ; FAF215  jrl T,0xfaf194
Voice_ApplyParamChange_Dispatch__FAF218:
	pushw	0                                    ; FAF218  push 0x0000
	jr Voice_ApplyParamChange_Dispatch__FAF22A                      ; FAF21B  jr T,0xfaf22a
Voice_ApplyParamChange_Dispatch__FAF21D:
	pushw	1                                    ; FAF21D  push 0x0001
	jr Voice_ApplyParamChange_Dispatch__FAF22A                      ; FAF220  jr T,0xfaf22a
Voice_ApplyParamChange_Dispatch__FAF222:
	pushw	2                                    ; FAF222  push 0x0002
	jr Voice_ApplyParamChange_Dispatch__FAF22A                      ; FAF225  jr T,0xfaf22a
Voice_ApplyParamChange_Dispatch__FAF227:
	pushw	3                                    ; FAF227  push 0x0003
Voice_ApplyParamChange_Dispatch__FAF22A:
	push	xix                                   ; FAF22A  push XIX
	ld	c, e                                    ; FAF22B  ld C,E
	pushw	bc                                   ; FAF22D  push BC
	push	0                                     ; FAF22E  push 0x00
	push	h                                     ; FAF230  push H
	calr Voice_Restage_Reg04C0_ValueCurve_ForPart                 ; FAF232  calr 0xfae986
	jrl Voice_ApplyParamChange_Dispatch__FAF194                     ; FAF235  jrl T,0xfaf194
Voice_ApplyParamChange_Dispatch__FAF238:
	push	xix                                   ; FAF238  push XIX
	ld	c, e                                    ; FAF239  ld C,E
	pushw	bc                                   ; FAF23B  push BC
	push	0                                     ; FAF23C  push 0x00
	push	h                                     ; FAF23E  push H
	calr sub_FAEACE                 ; FAF240  calr 0xfaeace
	jrl Voice_ApplyParamChange_Dispatch__FAF31B                     ; FAF243  jrl T,0xfaf31b
Voice_ApplyParamChange_Dispatch__FAF246:
	push	xix                                   ; FAF246  push XIX
	ld	c, e                                    ; FAF247  ld C,E
	pushw	bc                                   ; FAF249  push BC
	push	0                                     ; FAF24A  push 0x00
	push	h                                     ; FAF24C  push H
	calr sub_FAEAF9                 ; FAF24E  calr 0xfaeaf9
	jrl Voice_ApplyParamChange_Dispatch__FAF31B                     ; FAF251  jrl T,0xfaf31b
Voice_ApplyParamChange_Dispatch__FAF254:
	push	xix                                   ; FAF254  push XIX
	ld	c, e                                    ; FAF255  ld C,E
	pushw	bc                                   ; FAF257  push BC
	push	0                                     ; FAF258  push 0x00
	push	h                                     ; FAF25A  push H
	calr sub_FAEB65                 ; FAF25C  calr 0xfaeb65
	jrl Voice_ApplyParamChange_Dispatch__FAF31B                     ; FAF25F  jrl T,0xfaf31b
Voice_ApplyParamChange_Dispatch__FAF262:
	push	xix                                   ; FAF262  push XIX
	ld	c, e                                    ; FAF263  ld C,E
	pushw	bc                                   ; FAF265  push BC
	push	0                                     ; FAF266  push 0x00
	push	h                                     ; FAF268  push H
	calr sub_FAEBD1                 ; FAF26A  calr 0xfaebd1
	jrl Voice_ApplyParamChange_Dispatch__FAF31B                     ; FAF26D  jrl T,0xfaf31b
Voice_ApplyParamChange_Dispatch__FAF270:
	push	xix                                   ; FAF270  push XIX
	ld	c, e                                    ; FAF271  ld C,E
	pushw	bc                                   ; FAF273  push BC
	push	0                                     ; FAF274  push 0x00
	push	h                                     ; FAF276  push H
	calr sub_FAEC21                 ; FAF278  calr 0xfaec21
	jrl Voice_ApplyParamChange_Dispatch__FAF31B                     ; FAF27B  jrl T,0xfaf31b
Voice_ApplyParamChange_Dispatch__FAF27E:
	push	xix                                   ; FAF27E  push XIX
	ld	c, e                                    ; FAF27F  ld C,E
	pushw	bc                                   ; FAF281  push BC
	push	0                                     ; FAF282  push 0x00
	push	h                                     ; FAF284  push H
	calr sub_FAEC71                 ; FAF286  calr 0xfaec71
	jrl Voice_ApplyParamChange_Dispatch__FAF31B                     ; FAF289  jrl T,0xfaf31b
Voice_ApplyParamChange_Dispatch__FAF28C:
	push	xix                                   ; FAF28C  push XIX
	ld	c, e                                    ; FAF28D  ld C,E
	pushw	bc                                   ; FAF28F  push BC
	push	0                                     ; FAF290  push 0x00
	push	h                                     ; FAF292  push H
	calr sub_FAEC9C                 ; FAF294  calr 0xfaec9c
	jrl Voice_ApplyParamChange_Dispatch__FAF31B                     ; FAF297  jrl T,0xfaf31b
Voice_ApplyParamChange_Dispatch__FAF29A:
	push	xix                                   ; FAF29A  push XIX
	ld	c, e                                    ; FAF29B  ld C,E
	pushw	bc                                   ; FAF29D  push BC
	push	0                                     ; FAF29E  push 0x00
	push	h                                     ; FAF2A0  push H
	calr sub_FAECC7                 ; FAF2A2  calr 0xfaecc7
	jrl Voice_ApplyParamChange_Dispatch__FAF31B                     ; FAF2A5  jrl T,0xfaf31b
Voice_ApplyParamChange_Dispatch__FAF2A8:
	push	xix                                   ; FAF2A8  push XIX
	ld	c, e                                    ; FAF2A9  ld C,E
	pushw	bc                                   ; FAF2AB  push BC
	push	0                                     ; FAF2AC  push 0x00
	push	h                                     ; FAF2AE  push H
	calr PartRec_ApplyParam_0023                 ; FAF2B0  calr 0xfaed33
	jr Voice_ApplyParamChange_Dispatch__FAF31B                      ; FAF2B3  jr T,0xfaf31b
Voice_ApplyParamChange_Dispatch__FAF2B5:
	push	xix                                   ; FAF2B5  push XIX
	ld	c, e                                    ; FAF2B6  ld C,E
	pushw	bc                                   ; FAF2B8  push BC
	push	0                                     ; FAF2B9  push 0x00
	push	h                                     ; FAF2BB  push H
	calr PartRec_ApplyParam_0025                 ; FAF2BD  calr 0xfaed76
	jr Voice_ApplyParamChange_Dispatch__FAF31B                      ; FAF2C0  jr T,0xfaf31b
Voice_ApplyParamChange_Dispatch__FAF2C2:
	push	xix                                   ; FAF2C2  push XIX
	ld	c, e                                    ; FAF2C3  ld C,E
	pushw	bc                                   ; FAF2C5  push BC
	push	0                                     ; FAF2C6  push 0x00
	push	h                                     ; FAF2C8  push H
	calr PartRec_ApplyParam_0027                 ; FAF2CA  calr 0xfaedc4
	jr Voice_ApplyParamChange_Dispatch__FAF31B                      ; FAF2CD  jr T,0xfaf31b
Voice_ApplyParamChange_Dispatch__FAF2CF:
	push	xix                                   ; FAF2CF  push XIX
	ld	c, e                                    ; FAF2D0  ld C,E
	pushw	bc                                   ; FAF2D2  push BC
	push	0                                     ; FAF2D3  push 0x00
	push	h                                     ; FAF2D5  push H
	calr PartRec_ApplyParam_0029                 ; FAF2D7  calr 0xfaee07
	jr Voice_ApplyParamChange_Dispatch__FAF31B                      ; FAF2DA  jr T,0xfaf31b
Voice_ApplyParamChange_Dispatch__FAF2DC:
	push	xix                                   ; FAF2DC  push XIX
	ld	c, e                                    ; FAF2DD  ld C,E
	pushw	bc                                   ; FAF2DF  push BC
	push	0                                     ; FAF2E0  push 0x00
	push	h                                     ; FAF2E2  push H
	calr PartRec_ApplyParam_002B                 ; FAF2E4  calr 0xfaee4a
	jr Voice_ApplyParamChange_Dispatch__FAF31B                      ; FAF2E7  jr T,0xfaf31b
Voice_ApplyParamChange_Dispatch__FAF2E9:
	push	xix                                   ; FAF2E9  push XIX
	ld	c, e                                    ; FAF2EA  ld C,E
	pushw	bc                                   ; FAF2EC  push BC
	push	0                                     ; FAF2ED  push 0x00
	push	h                                     ; FAF2EF  push H
	calr PartRec_ApplyParam_002D                 ; FAF2F1  calr 0xfaee8d
	jr Voice_ApplyParamChange_Dispatch__FAF31B                      ; FAF2F4  jr T,0xfaf31b
Voice_ApplyParamChange_Dispatch__FAF2F6:
	push	xix                                   ; FAF2F6  push XIX
	ld	c, e                                    ; FAF2F7  ld C,E
	pushw	bc                                   ; FAF2F9  push BC
	push	0                                     ; FAF2FA  push 0x00
	push	h                                     ; FAF2FC  push H
	calr PartRec_ApplyParam_002F                 ; FAF2FE  calr 0xfaeed0
	jr Voice_ApplyParamChange_Dispatch__FAF31B                      ; FAF301  jr T,0xfaf31b
Voice_ApplyParamChange_Dispatch__FAF303:
	push	xix                                   ; FAF303  push XIX
	ld	c, e                                    ; FAF304  ld C,E
	pushw	bc                                   ; FAF306  push BC
	push	0                                     ; FAF307  push 0x00
	push	h                                     ; FAF309  push H
	calr PartRec_ApplyParam_0031                 ; FAF30B  calr 0xfaef24
	jr Voice_ApplyParamChange_Dispatch__FAF31B                      ; FAF30E  jr T,0xfaf31b
Voice_ApplyParamChange_Dispatch__FAF310:
	push	xix                                   ; FAF310  push XIX
	ld	c, e                                    ; FAF311  ld C,E
	pushw	bc                                   ; FAF313  push BC
	push	0                                     ; FAF314  push 0x00
	push	h                                     ; FAF316  push H
	calr PartRec_ApplyParam_0033                 ; FAF318  calr 0xfaef7f
Voice_ApplyParamChange_Dispatch__FAF31B:
	inc	8, xsp                                 ; FAF31B  inc 0,XSP
	jr Voice_ApplyParamChange_Dispatch__FAF33A                      ; FAF31D  jr T,0xfaf33a
Voice_ApplyParamChange_Dispatch__FAF31F:
	push	xix                                   ; FAF31F  push XIX
	ld	c, e                                    ; FAF320  ld C,E
	pushw	bc                                   ; FAF322  push BC
	calr sub_FAEFC2                 ; FAF323  calr 0xfaefc2
	jr Voice_ApplyParamChange_Dispatch__FAF338                      ; FAF326  jr T,0xfaf338
Voice_ApplyParamChange_Dispatch__FAF328:
	push	xix                                   ; FAF328  push XIX
	ld	c, e                                    ; FAF329  ld C,E
	pushw	bc                                   ; FAF32B  push BC
	calr sub_FAEFE7                 ; FAF32C  calr 0xfaefe7
	jr Voice_ApplyParamChange_Dispatch__FAF338                      ; FAF32F  jr T,0xfaf338
Voice_ApplyParamChange_Dispatch__FAF331:
	push	xix                                   ; FAF331  push XIX
	ld	c, e                                    ; FAF332  ld C,E
	pushw	bc                                   ; FAF334  push BC
	calr sub_FAF00C                 ; FAF335  calr 0xfaf00c
Voice_ApplyParamChange_Dispatch__FAF338:
	inc	6, xsp                                 ; FAF338  inc 6,XSP
Voice_ApplyParamChange_Dispatch__FAF33A:
	pop	xix                                    ; FAF33A  pop XIX
	popw	de                                    ; FAF33B  pop DE
	popw	hl                                    ; FAF33C  pop HL
	unlk32 xiz                                 ; FAF33D  unlk XIZ
	ret                                        ; FAF33F  ret
; --------------------------------------------------------------------------
; PartRec_ResetSlotValues_ByTag -- 0xFAF340..0xFAF3CB (140 bytes)
;             walk six 6-byte slot records and, where a slot's 6-bit tag matches and its
;             index is not the excluded one, write 0x40 into that slot's byte of the
;             part record.
;             (★ NAMED in wave 7 round 2; was `sub_FAF340`.)
;
; Called from: no site outside this module.
;          13 site(s) inside this module:
;          0xFAF45E 0xFAF4C4 0xFAF56F 0xFAF5D5 0xFAF682 0xFAF6E2
;          0xFAF858 0xFAF9CB 0xFAFAD3 0xFAFBD6 0xFB00B5 0xFB0118
;          0xFB01F3
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C), (XIZ+0x0E)
; Outputs: no absolute-addressed write.
; Evidence: ★ the loop bounds, the record stride and the destination address are all
;          immediates:
;          (Each address in the block below is the FIRST instruction of the step it
;          labels, not the only one; the rest of the step follows it.)
;              0xFAF34A  ld BC,(XIZ+0x08) / mul BC,0x012c / ld XIX,XBC       
;                        -- the PART RECORD base: stride 0x012C = 300 bytes, the
;                        geometry notes/FINDINGS-prom_c-voice-module.md and
;                        notes/FINDINGS-prom_c-dev10c-register-meanings.md §1 both give
;                        for RAM 0x001523
;              0xFAF35B  ld A,(*(XIZ+0x0e)+1) / and A,0x3f / cp A,(XIZ+0x0c) 
;                        -- tag test, arm 1
;              0xFAF38D  ld A,(*(XIZ+0x0e)+4) / and A,0x3f / cp A,(XIZ+0x0c) 
;                        -- tag test, arm 2
;              0xFAF36B / 0xFAF39D  cp DE,WA  (WA loaded from (XIZ+0x0a) at 0xFAF366 /
;                                   0xFAF398) -- the slot index must NOT be the excluded one
;              0xFAF377  add WA,0x0076  then  0xFAF37E  ld BC,0x1523 / 0xFAF383 add WA,BC
;                        then  0xFAF385  ld (XWA),0x40        -- arm 1 destination
;              0xFAF3A9  add WA,0x0077 / ld (XWA+0x1523),0x40           
;                        -- arm 2 destination
;              0xFAF3B7  inc 6,XBC  then  0xFAF3B9  add (XIZ+0x0e),XBC
;                        -- the slot record stride is SIX bytes
;              0xFAF3BC  inc 2,HL / inc 1,DE / cp HL,0x000c / jr C  
;                        -- SIX iterations, HL = 2*i
;          so the destination is 0x001523 + 300*part + 0x76 + 2*i (arm 1) or +0x77 + 2*i
;          (arm 2), for i = 0..5, and the value written is always 0x40.
;          Thirteen call sites, all in this module, and ten of them are named MIDI
;          controller handlers: MidiCtrl_CC01, CC02, CC04, CC16, CC17, CC18 and CC19
;          (two sites each for CC01/CC02/CC04).
; Unknown:  ⚠ what the tag at (XIZ+0x0C) and the two record fields +1 and +4 SELECT.
;          `ByTag` names the comparison, not the quantity.
;          ⚠ what part-record bytes +0x76..+0x81 hold.  The field map in notes/FINDINGS-
;          prom_c-dev10c-register-meanings.md §1 documents +0x09..+0x1A and says nothing
;          about this range, so "SlotValues" is a name for twelve bytes that are indexed
;          per slot, not a claim about their contents.  That 0x40 is a CENTRE value for
;          a 0x00..0x7F range is PLAUSIBLE and is NOT asserted.
;          ⚠ whether the two arms are two independent slot fields or one field read at
;          two offsets.  Both are tested per iteration and arm 2 is only reached when
;          arm 1 misses.
; --------------------------------------------------------------------------
PartRec_ResetSlotValues_ByTag:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FAF340  link XIZ,0xfffc
	pushw	hl                                   ; FAF344  push HL
	pushw	de                                   ; FAF345  push DE
	push	xix                                   ; FAF346  push XIX
	ldw	de, 0                                  ; FAF347  ld DE,0x0000
	ld	bc, (xiz+8)                             ; FAF34A  ld BC,(XIZ+0x08)
	extz	bc                                    ; FAF34D  extz BC
	mul	bc, 0x12C                              ; FAF34F  mul BC,0x012c
	ld	xix, xbc                                ; FAF353  ld XIX,XBC
	ldw	hl, 0                                  ; FAF355  ld HL,0x0000
PartRec_ResetSlotValues_ByTag__FAF358:
	ld	xbc, (xiz+14)                           ; FAF358  ld XBC,(XIZ+0x0e)
	ld	a, (xbc+1)                              ; FAF35B  ld A,(XBC+0x01)
	and	a, 63                                  ; FAF35E  and A,0x3f
	extpfx3 0x8E, 0x0C, 0xF1                   ; FAF361  cp A,(XIZ+0x0c)
	jr nz, PartRec_ResetSlotValues_ByTag__FAF38A                  ; FAF364  jr NZ,0xfaf38a
	ld	wa, (xiz+10)                            ; FAF366  ld WA,(XIZ+0x0a)
	extz	wa                                    ; FAF369  extz WA
	cp	de, wa                                  ; FAF36B  cp DE,WA
	jr z, PartRec_ResetSlotValues_ByTag__FAF38A                   ; FAF36D  jr Z,0xfaf38a
	ld	(xiz-2), hl                             ; FAF36F  ld (XIZ+0xfe),HL
	ld	wa, ix                                  ; FAF372  ld WA,IX
	extpfx3 0x9E, 0xFE, 0x80                   ; FAF374  add WA,(XIZ+0xfe)
	add	wa, 0x76                               ; FAF377  add WA,0x0076
	ld	(xiz-4), wa                             ; FAF37B  ld (XIZ+0xfc),WA
	ldw	bc, 0x1523                             ; FAF37E  ld BC,0x1523
	extz	xwa                                   ; FAF381  extz XWA
	add	wa, bc                                 ; FAF383  add WA,BC
	ld	(xwa), 64                               ; FAF385  ld (XWA),0x40
	jr PartRec_ResetSlotValues_ByTag__FAF3B5                      ; FAF388  jr T,0xfaf3b5
PartRec_ResetSlotValues_ByTag__FAF38A:
	ld	xbc, (xiz+14)                           ; FAF38A  ld XBC,(XIZ+0x0e)
	ld	a, (xbc+4)                              ; FAF38D  ld A,(XBC+0x04)
	and	a, 63                                  ; FAF390  and A,0x3f
	extpfx3 0x8E, 0x0C, 0xF1                   ; FAF393  cp A,(XIZ+0x0c)
	jr nz, PartRec_ResetSlotValues_ByTag__FAF3B5                  ; FAF396  jr NZ,0xfaf3b5
	ld	wa, (xiz+10)                            ; FAF398  ld WA,(XIZ+0x0a)
	extz	wa                                    ; FAF39B  extz WA
	cp	de, wa                                  ; FAF39D  cp DE,WA
	jr z, PartRec_ResetSlotValues_ByTag__FAF3B5                   ; FAF39F  jr Z,0xfaf3b5
	ld	(xiz-2), hl                             ; FAF3A1  ld (XIZ+0xfe),HL
	ld	wa, ix                                  ; FAF3A4  ld WA,IX
	extpfx3 0x9E, 0xFE, 0x80                   ; FAF3A6  add WA,(XIZ+0xfe)
	add	wa, 0x77                               ; FAF3A9  add WA,0x0077
	extz	xwa                                   ; FAF3AD  extz XWA
	ld	(xwa+0x1523), 64                        ; FAF3AF  ld (XWA+0x1523),0x40
PartRec_ResetSlotValues_ByTag__FAF3B5:
	sub	xbc, xbc                               ; FAF3B5  sub XBC,XBC
	inc	6, xbc                                 ; FAF3B7  inc 6,XBC
	add	(xiz+14), xbc                          ; FAF3B9  add (XIZ+0x0e),XBC
	inc	2, hl                                  ; FAF3BC  inc 2,HL
	inc	1, de                                  ; FAF3BE  inc 1,DE
	cp	hl, 12                                  ; FAF3C0  cp HL,0x000c
	jr c, PartRec_ResetSlotValues_ByTag__FAF358                   ; FAF3C4  jr C,0xfaf358
	pop	xix                                    ; FAF3C6  pop XIX
	popw	de                                    ; FAF3C7  pop DE
	popw	hl                                    ; FAF3C8  pop HL
	unlk32 xiz                                 ; FAF3C9  unlk XIZ
	ret                                        ; FAF3CB  ret
; --------------------------------------------------------------------------
; MidiCtrl_CC01 -- 0xFAF3CC..0xFAF4DC (273 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAFE74
; Inputs:  frame `link XIZ,-20`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Calls:   0xFAF031 = Voice_ApplyParamChange_Dispatch, 0xFAF340 = PartRec_ResetSlotValues_ByTag
; Evidence: the listing below is the byte-identical round-trip of 0xFAF3CC-0xFAF4DC
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7).  CONTROLLER 1.  The number is read off `cp BC,1 / jrl Z` at
;          0xFAFDBB; this routine is its only arm, and the dispatcher its only caller.
;          The MIDI standard assigns 1 to "modulation wheel" -- that role is NOT
;          established by anything in this image, and the name states the number only.
;          The 26 (number, handler) pairs are re-extracted from the ROM by
;          `python3 notes/prom_c_dev10c_meaning_checks.py` section 1.
; Unknown:  what the routine DOES with the value.
; --------------------------------------------------------------------------
MidiCtrl_CC01:
	link32 0xEE, 0x0C, 0xEC, 0xFF              ; FAF3CC  link XIZ,0xffec
	pushw	hl                                   ; FAF3D0  push HL
	push	xix                                   ; FAF3D1  push XIX
	ld	l, (xiz+8)                              ; FAF3D2  ld L,(XIZ+0x08)
	ld	c, l                                    ; FAF3D5  ld C,L
	extz	bc                                    ; FAF3D7  extz BC
	mul	bc, 0x12C                              ; FAF3D9  mul BC,0x012c
	extz	xbc                                   ; FAF3DD  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FAF3DF  ld XWA,(XBC+0x1523)
	ld	xix, xwa                                ; FAF3E4  ld XIX,XWA
	ld	c, (xwa+16)                             ; FAF3E6  ld C,(XWA+0x10)
	and	c, 0xC0                                ; FAF3E9  and C,0xc0
	extz	bc                                    ; FAF3EC  extz BC
	cp	bc, 0:i3                                  ; FAF3EE  cp BC,0
	jr z, MidiCtrl_CC01__FAF408                   ; FAF3F0  jr Z,0xfaf408
	cp	bc, 64                                  ; FAF3F2  cp BC,0x0040
	jr z, MidiCtrl_CC01__FAF408                   ; FAF3F6  jr Z,0xfaf408
	cp	bc, 0x80                                ; FAF3F8  cp BC,0x0080
	jrl z, MidiCtrl_CC01__FAF477                  ; FAF3FC  jrl Z,0xfaf477
	cp	bc, 0xC0                                ; FAF3FF  cp BC,0x00c0
	jr z, MidiCtrl_CC01__FAF408                   ; FAF403  jr Z,0xfaf408
	jrl MidiCtrl_CC01__FAF4D8                     ; FAF405  jrl T,0xfaf4d8
MidiCtrl_CC01__FAF408:
	ld	c, l                                    ; FAF408  ld C,L
	extz	bc                                    ; FAF40A  extz BC
	mul	bc, 0x12C                              ; FAF40C  mul BC,0x012c
	extz	xbc                                   ; FAF410  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FAF412  ld XWA,(XBC+0x1523)
	ld	xix, xwa                                ; FAF417  ld XIX,XWA
	add	xwa, 49                                ; FAF419  add XWA,0x00000031
	ld	(xiz-8), xwa                            ; FAF41F  ld (XIZ+0xf8),XWA
	sub	xbc, xbc                               ; FAF422  sub XBC,XBC
	ld	(xiz-4), xbc                            ; FAF424  ld (XIZ+0xfc),XBC
	ld	h, 2:opc                                   ; FAF427  ld H,0x02
MidiCtrl_CC01__FAF429:
	ld	xbc, (xiz-4)                            ; FAF429  ld XBC,(XIZ+0xfc)
	ld	(xiz-16), xbc                           ; FAF42C  ld (XIZ+0xf0),XBC
	ld	(xiz-20), xbc                           ; FAF42F  ld (XIZ+0xec),XBC
	add	xbc, 23                                ; FAF432  add XBC,0x00000017
	add	xbc, xix                               ; FAF438  add XBC,XIX
	push	xbc                                   ; FAF43A  push XBC
	ld	bc, (xiz+10)                            ; FAF43B  ld BC,(XIZ+0x0a)
	extz	bc                                    ; FAF43E  extz BC
	pushw	bc                                   ; FAF440  push BC
	pushw	hl                                   ; FAF441  push HL
	calr Voice_ApplyParamChange_Dispatch                 ; FAF442  calr 0xfaf031
	ld	xbc, (xiz-8)                            ; FAF445  ld XBC,(XIZ+0xf8)
	push	xbc                                   ; FAF448  push XBC
	ld	xwa, (xiz-20)                           ; FAF449  ld XWA,(XIZ+0xec)
	add	xwa, 24                                ; FAF44C  add XWA,0x00000018
	add	xwa, xix                               ; FAF452  add XWA,XIX
	ld	c, (xwa)                                ; FAF454  ld C,(XWA)
	and	c, 63                                  ; FAF456  and C,0x3f
	pushw	bc                                   ; FAF459  push BC
	pushw	0xFF                                 ; FAF45A  push 0x00ff
	pushw	hl                                   ; FAF45D  push HL
	calr PartRec_ResetSlotValues_ByTag                 ; FAF45E  calr 0xfaf340
	ld	xbc, (xiz-16)                           ; FAF461  ld XBC,(XIZ+0xf0)
	inc	3, xbc                                 ; FAF464  inc 3,XBC
	ld	(xiz-4), xbc                            ; FAF466  ld (XIZ+0xfc),XBC
	dec	1, h                                   ; FAF469  dec 1,H
	add	xsp, 18                                ; FAF46B  add XSP,0x00000012
	cp	h, 0:i3                                   ; FAF471  cp H,0
	jr nz, MidiCtrl_CC01__FAF429                  ; FAF473  jr NZ,0xfaf429
	jr MidiCtrl_CC01__FAF4D8                      ; FAF475  jr T,0xfaf4d8
MidiCtrl_CC01__FAF477:
	ld	(xiz-12), xix                           ; FAF477  ld (XIZ+0xf4),XIX
	ld	xbc, (xiz-12)                           ; FAF47A  ld XBC,(XIZ+0xf4)
	add	xbc, 46                                ; FAF47D  add XBC,0x0000002e
	ld	(xiz-4), xbc                            ; FAF483  ld (XIZ+0xfc),XBC
	ld	xix, 0                                  ; FAF486  ld XIX,0x00000000
	ld	h, 2:opc                                   ; FAF48B  ld H,0x02
MidiCtrl_CC01__FAF48D:
	ld	(xiz-16), xix                           ; FAF48D  ld (XIZ+0xf0),XIX
	ld	xbc, (xiz-16)                           ; FAF490  ld XBC,(XIZ+0xf0)
	ld	(xiz-20), xbc                           ; FAF493  ld (XIZ+0xec),XBC
	add	xbc, 20                                ; FAF496  add XBC,0x00000014
	extpfx3 0xAE, 0xF4, 0x81                   ; FAF49C  add XBC,(XIZ+0xf4)
	push	xbc                                   ; FAF49F  push XBC
	ld	bc, (xiz+10)                            ; FAF4A0  ld BC,(XIZ+0x0a)
	extz	bc                                    ; FAF4A3  extz BC
	pushw	bc                                   ; FAF4A5  push BC
	pushw	hl                                   ; FAF4A6  push HL
	calr Voice_ApplyParamChange_Dispatch                 ; FAF4A7  calr 0xfaf031
	ld	xbc, (xiz-4)                            ; FAF4AA  ld XBC,(XIZ+0xfc)
	push	xbc                                   ; FAF4AD  push XBC
	ld	xwa, (xiz-20)                           ; FAF4AE  ld XWA,(XIZ+0xec)
	add	xwa, 21                                ; FAF4B1  add XWA,0x00000015
	extpfx3 0xAE, 0xF4, 0x80                   ; FAF4B7  add XWA,(XIZ+0xf4)
	ld	c, (xwa)                                ; FAF4BA  ld C,(XWA)
	and	c, 63                                  ; FAF4BC  and C,0x3f
	pushw	bc                                   ; FAF4BF  push BC
	pushw	0xFF                                 ; FAF4C0  push 0x00ff
	pushw	hl                                   ; FAF4C3  push HL
	calr PartRec_ResetSlotValues_ByTag                 ; FAF4C4  calr 0xfaf340
	ld	xix, (xiz-16)                           ; FAF4C7  ld XIX,(XIZ+0xf0)
	inc	3, xix                                 ; FAF4CA  inc 3,XIX
	dec	1, h                                   ; FAF4CC  dec 1,H
	add	xsp, 18                                ; FAF4CE  add XSP,0x00000012
	cp	h, 0:i3                                   ; FAF4D4  cp H,0
	jr nz, MidiCtrl_CC01__FAF48D                  ; FAF4D6  jr NZ,0xfaf48d
MidiCtrl_CC01__FAF4D8:
	pop	xix                                    ; FAF4D8  pop XIX
	popw	hl                                    ; FAF4D9  pop HL
	unlk32 xiz                                 ; FAF4DA  unlk XIZ
	ret                                        ; FAF4DC  ret
; --------------------------------------------------------------------------
; MidiCtrl_CC02 -- 0xFAF4DD..0xFAF5ED (273 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAFE82
; Inputs:  frame `link XIZ,-20`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Calls:   0xFAF031 = Voice_ApplyParamChange_Dispatch, 0xFAF340 = PartRec_ResetSlotValues_ByTag
; Evidence: the listing below is the byte-identical round-trip of 0xFAF4DD-0xFAF5ED
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7).  CONTROLLER 2.  The number is read off `cp BC,2 / jrl Z` at
;          0xFAFDC0; this routine is its only arm, and the dispatcher its only caller.
;          The MIDI standard assigns 2 to "breath controller" -- that role is NOT
;          established by anything in this image, and the name states the number only.
;          The 26 (number, handler) pairs are re-extracted from the ROM by
;          `python3 notes/prom_c_dev10c_meaning_checks.py` section 1.
; Unknown:  what the routine DOES with the value.
; --------------------------------------------------------------------------
MidiCtrl_CC02:
	link32 0xEE, 0x0C, 0xEC, 0xFF              ; FAF4DD  link XIZ,0xffec
	pushw	hl                                   ; FAF4E1  push HL
	push	xix                                   ; FAF4E2  push XIX
	ld	l, (xiz+8)                              ; FAF4E3  ld L,(XIZ+0x08)
	ld	c, l                                    ; FAF4E6  ld C,L
	extz	bc                                    ; FAF4E8  extz BC
	mul	bc, 0x12C                              ; FAF4EA  mul BC,0x012c
	extz	xbc                                   ; FAF4EE  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FAF4F0  ld XWA,(XBC+0x1523)
	ld	xix, xwa                                ; FAF4F5  ld XIX,XWA
	ld	c, (xwa+16)                             ; FAF4F7  ld C,(XWA+0x10)
	and	c, 0xC0                                ; FAF4FA  and C,0xc0
	extz	bc                                    ; FAF4FD  extz BC
	cp	bc, 0:i3                                  ; FAF4FF  cp BC,0
	jr z, MidiCtrl_CC02__FAF519                   ; FAF501  jr Z,0xfaf519
	cp	bc, 64                                  ; FAF503  cp BC,0x0040
	jr z, MidiCtrl_CC02__FAF519                   ; FAF507  jr Z,0xfaf519
	cp	bc, 0x80                                ; FAF509  cp BC,0x0080
	jrl z, MidiCtrl_CC02__FAF588                  ; FAF50D  jrl Z,0xfaf588
	cp	bc, 0xC0                                ; FAF510  cp BC,0x00c0
	jr z, MidiCtrl_CC02__FAF519                   ; FAF514  jr Z,0xfaf519
	jrl MidiCtrl_CC02__FAF5E9                     ; FAF516  jrl T,0xfaf5e9
MidiCtrl_CC02__FAF519:
	ld	c, l                                    ; FAF519  ld C,L
	extz	bc                                    ; FAF51B  extz BC
	mul	bc, 0x12C                              ; FAF51D  mul BC,0x012c
	extz	xbc                                   ; FAF521  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FAF523  ld XWA,(XBC+0x1523)
	ld	xix, xwa                                ; FAF528  ld XIX,XWA
	add	xwa, 49                                ; FAF52A  add XWA,0x00000031
	ld	(xiz-8), xwa                            ; FAF530  ld (XIZ+0xf8),XWA
	sub	xbc, xbc                               ; FAF533  sub XBC,XBC
	ld	(xiz-4), xbc                            ; FAF535  ld (XIZ+0xfc),XBC
	ld	h, 2:opc                                   ; FAF538  ld H,0x02
MidiCtrl_CC02__FAF53A:
	ld	xbc, (xiz-4)                            ; FAF53A  ld XBC,(XIZ+0xfc)
	ld	(xiz-16), xbc                           ; FAF53D  ld (XIZ+0xf0),XBC
	ld	(xiz-20), xbc                           ; FAF540  ld (XIZ+0xec),XBC
	add	xbc, 29                                ; FAF543  add XBC,0x0000001d
	add	xbc, xix                               ; FAF549  add XBC,XIX
	push	xbc                                   ; FAF54B  push XBC
	ld	bc, (xiz+10)                            ; FAF54C  ld BC,(XIZ+0x0a)
	extz	bc                                    ; FAF54F  extz BC
	pushw	bc                                   ; FAF551  push BC
	pushw	hl                                   ; FAF552  push HL
	calr Voice_ApplyParamChange_Dispatch                 ; FAF553  calr 0xfaf031
	ld	xbc, (xiz-8)                            ; FAF556  ld XBC,(XIZ+0xf8)
	push	xbc                                   ; FAF559  push XBC
	ld	xwa, (xiz-20)                           ; FAF55A  ld XWA,(XIZ+0xec)
	add	xwa, 30                                ; FAF55D  add XWA,0x0000001e
	add	xwa, xix                               ; FAF563  add XWA,XIX
	ld	c, (xwa)                                ; FAF565  ld C,(XWA)
	and	c, 63                                  ; FAF567  and C,0x3f
	pushw	bc                                   ; FAF56A  push BC
	pushw	0xFF                                 ; FAF56B  push 0x00ff
	pushw	hl                                   ; FAF56E  push HL
	calr PartRec_ResetSlotValues_ByTag                 ; FAF56F  calr 0xfaf340
	ld	xbc, (xiz-16)                           ; FAF572  ld XBC,(XIZ+0xf0)
	inc	3, xbc                                 ; FAF575  inc 3,XBC
	ld	(xiz-4), xbc                            ; FAF577  ld (XIZ+0xfc),XBC
	dec	1, h                                   ; FAF57A  dec 1,H
	add	xsp, 18                                ; FAF57C  add XSP,0x00000012
	cp	h, 0:i3                                   ; FAF582  cp H,0
	jr nz, MidiCtrl_CC02__FAF53A                  ; FAF584  jr NZ,0xfaf53a
	jr MidiCtrl_CC02__FAF5E9                      ; FAF586  jr T,0xfaf5e9
MidiCtrl_CC02__FAF588:
	ld	(xiz-12), xix                           ; FAF588  ld (XIZ+0xf4),XIX
	ld	xbc, (xiz-12)                           ; FAF58B  ld XBC,(XIZ+0xf4)
	add	xbc, 46                                ; FAF58E  add XBC,0x0000002e
	ld	(xiz-4), xbc                            ; FAF594  ld (XIZ+0xfc),XBC
	ld	xix, 0                                  ; FAF597  ld XIX,0x00000000
	ld	h, 2:opc                                   ; FAF59C  ld H,0x02
MidiCtrl_CC02__FAF59E:
	ld	(xiz-16), xix                           ; FAF59E  ld (XIZ+0xf0),XIX
	ld	xbc, (xiz-16)                           ; FAF5A1  ld XBC,(XIZ+0xf0)
	ld	(xiz-20), xbc                           ; FAF5A4  ld (XIZ+0xec),XBC
	add	xbc, 26                                ; FAF5A7  add XBC,0x0000001a
	extpfx3 0xAE, 0xF4, 0x81                   ; FAF5AD  add XBC,(XIZ+0xf4)
	push	xbc                                   ; FAF5B0  push XBC
	ld	bc, (xiz+10)                            ; FAF5B1  ld BC,(XIZ+0x0a)
	extz	bc                                    ; FAF5B4  extz BC
	pushw	bc                                   ; FAF5B6  push BC
	pushw	hl                                   ; FAF5B7  push HL
	calr Voice_ApplyParamChange_Dispatch                 ; FAF5B8  calr 0xfaf031
	ld	xbc, (xiz-4)                            ; FAF5BB  ld XBC,(XIZ+0xfc)
	push	xbc                                   ; FAF5BE  push XBC
	ld	xwa, (xiz-20)                           ; FAF5BF  ld XWA,(XIZ+0xec)
	add	xwa, 27                                ; FAF5C2  add XWA,0x0000001b
	extpfx3 0xAE, 0xF4, 0x80                   ; FAF5C8  add XWA,(XIZ+0xf4)
	ld	c, (xwa)                                ; FAF5CB  ld C,(XWA)
	and	c, 63                                  ; FAF5CD  and C,0x3f
	pushw	bc                                   ; FAF5D0  push BC
	pushw	0xFF                                 ; FAF5D1  push 0x00ff
	pushw	hl                                   ; FAF5D4  push HL
	calr PartRec_ResetSlotValues_ByTag                 ; FAF5D5  calr 0xfaf340
	ld	xix, (xiz-16)                           ; FAF5D8  ld XIX,(XIZ+0xf0)
	inc	3, xix                                 ; FAF5DB  inc 3,XIX
	dec	1, h                                   ; FAF5DD  dec 1,H
	add	xsp, 18                                ; FAF5DF  add XSP,0x00000012
	cp	h, 0:i3                                   ; FAF5E5  cp H,0
	jr nz, MidiCtrl_CC02__FAF59E                  ; FAF5E7  jr NZ,0xfaf59e
MidiCtrl_CC02__FAF5E9:
	pop	xix                                    ; FAF5E9  pop XIX
	popw	hl                                    ; FAF5EA  pop HL
	unlk32 xiz                                 ; FAF5EB  unlk XIZ
	ret                                        ; FAF5ED  ret
; --------------------------------------------------------------------------
; MidiCtrl_CC04 -- 0xFAF5EE..0xFAF6FB (270 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAFE90
; Inputs:  frame `link XIZ,-14`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Calls:   0xFAF031 = Voice_ApplyParamChange_Dispatch, 0xFAF340 = PartRec_ResetSlotValues_ByTag
; Evidence: the listing below is the byte-identical round-trip of 0xFAF5EE-0xFAF6FB
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7).  CONTROLLER 4.  The number is read off `cp BC,4 / jrl Z` at
;          0xFAFDC5; this routine is its only arm, and the dispatcher its only caller.
;          The MIDI standard assigns 4 to "foot controller" -- that role is NOT
;          established by anything in this image, and the name states the number only.
;          The 26 (number, handler) pairs are re-extracted from the ROM by
;          `python3 notes/prom_c_dev10c_meaning_checks.py` section 1.
; Unknown:  what the routine DOES with the value.
; --------------------------------------------------------------------------
MidiCtrl_CC04:
	link32 0xEE, 0x0C, 0xF2, 0xFF              ; FAF5EE  link XIZ,0xfff2
	pushw	hl                                   ; FAF5F2  push HL
	pushw	de                                   ; FAF5F3  push DE
	push	xix                                   ; FAF5F4  push XIX
	ld	l, (xiz+8)                              ; FAF5F5  ld L,(XIZ+0x08)
	ld	c, l                                    ; FAF5F8  ld C,L
	extz	bc                                    ; FAF5FA  extz BC
	mul	bc, 0x12C                              ; FAF5FC  mul BC,0x012c
	extz	xbc                                   ; FAF600  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FAF602  ld XWA,(XBC+0x1523)
	ld	(xiz-8), xwa                            ; FAF607  ld (XIZ+0xf8),XWA
	ld	c, (xwa+16)                             ; FAF60A  ld C,(XWA+0x10)
	and	c, 0xC0                                ; FAF60D  and C,0xc0
	extz	bc                                    ; FAF610  extz BC
	cp	bc, 0:i3                                  ; FAF612  cp BC,0
	jr z, MidiCtrl_CC04__FAF62C                   ; FAF614  jr Z,0xfaf62c
	cp	bc, 64                                  ; FAF616  cp BC,0x0040
	jr z, MidiCtrl_CC04__FAF62C                   ; FAF61A  jr Z,0xfaf62c
	cp	bc, 0x80                                ; FAF61C  cp BC,0x0080
	jrl z, MidiCtrl_CC04__FAF698                  ; FAF620  jrl Z,0xfaf698
	cp	bc, 0xC0                                ; FAF623  cp BC,0x00c0
	jr z, MidiCtrl_CC04__FAF62C                   ; FAF627  jr Z,0xfaf62c
	jrl MidiCtrl_CC04__FAF6F6                     ; FAF629  jrl T,0xfaf6f6
MidiCtrl_CC04__FAF62C:
	ld	c, l                                    ; FAF62C  ld C,L
	extz	bc                                    ; FAF62E  extz BC
	mul	bc, 0x12C                              ; FAF630  mul BC,0x012c
	extz	xbc                                   ; FAF634  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FAF636  ld XWA,(XBC+0x1523)
	ld	xix, xwa                                ; FAF63B  ld XIX,XWA
	add	xwa, 49                                ; FAF63D  add XWA,0x00000031
	ld	(xiz-4), xwa                            ; FAF643  ld (XIZ+0xfc),XWA
	ldw	de, 0                                  ; FAF646  ld DE,0x0000
	ld	h, 2:opc                                   ; FAF649  ld H,0x02
MidiCtrl_CC04__FAF64B:
	ld	(xiz-10), de                            ; FAF64B  ld (XIZ+0xf6),DE
	ld	bc, (xiz-10)                            ; FAF64E  ld BC,(XIZ+0xf6)
	extz	xbc                                   ; FAF651  extz XBC
	ld	(xiz-14), xbc                           ; FAF653  ld (XIZ+0xf2),XBC
	add	xbc, 37                                ; FAF656  add XBC,0x00000025
	add	xbc, xix                               ; FAF65C  add XBC,XIX
	push	xbc                                   ; FAF65E  push XBC
	ld	bc, (xiz+10)                            ; FAF65F  ld BC,(XIZ+0x0a)
	extz	bc                                    ; FAF662  extz BC
	pushw	bc                                   ; FAF664  push BC
	pushw	hl                                   ; FAF665  push HL
	calr Voice_ApplyParamChange_Dispatch                 ; FAF666  calr 0xfaf031
	ld	xbc, (xiz-4)                            ; FAF669  ld XBC,(XIZ+0xfc)
	push	xbc                                   ; FAF66C  push XBC
	ld	xwa, (xiz-14)                           ; FAF66D  ld XWA,(XIZ+0xf2)
	add	xwa, 38                                ; FAF670  add XWA,0x00000026
	add	xwa, xix                               ; FAF676  add XWA,XIX
	ld	c, (xwa)                                ; FAF678  ld C,(XWA)
	and	c, 63                                  ; FAF67A  and C,0x3f
	pushw	bc                                   ; FAF67D  push BC
	pushw	0xFF                                 ; FAF67E  push 0x00ff
	pushw	hl                                   ; FAF681  push HL
	calr PartRec_ResetSlotValues_ByTag                 ; FAF682  calr 0xfaf340
	ld	de, (xiz-10)                            ; FAF685  ld DE,(XIZ+0xf6)
	inc	3, de                                  ; FAF688  inc 3,DE
	dec	1, h                                   ; FAF68A  dec 1,H
	add	xsp, 18                                ; FAF68C  add XSP,0x00000012
	cp	h, 0:i3                                   ; FAF692  cp H,0
	jr nz, MidiCtrl_CC04__FAF64B                  ; FAF694  jr NZ,0xfaf64b
	jr MidiCtrl_CC04__FAF6F6                      ; FAF696  jr T,0xfaf6f6
MidiCtrl_CC04__FAF698:
	ld	xix, (xiz-8)                            ; FAF698  ld XIX,(XIZ+0xf8)
	ld	xbc, xix                                ; FAF69B  ld XBC,XIX
	add	xbc, 46                                ; FAF69D  add XBC,0x0000002e
	ld	(xiz-4), xbc                            ; FAF6A3  ld (XIZ+0xfc),XBC
	ldw	de, 0                                  ; FAF6A6  ld DE,0x0000
	ld	h, 2:opc                                   ; FAF6A9  ld H,0x02
MidiCtrl_CC04__FAF6AB:
	ld	(xiz-10), de                            ; FAF6AB  ld (XIZ+0xf6),DE
	ld	bc, (xiz-10)                            ; FAF6AE  ld BC,(XIZ+0xf6)
	extz	xbc                                   ; FAF6B1  extz XBC
	ld	(xiz-14), xbc                           ; FAF6B3  ld (XIZ+0xf2),XBC
	add	xbc, 34                                ; FAF6B6  add XBC,0x00000022
	add	xbc, xix                               ; FAF6BC  add XBC,XIX
	push	xbc                                   ; FAF6BE  push XBC
	ld	bc, (xiz+10)                            ; FAF6BF  ld BC,(XIZ+0x0a)
	extz	bc                                    ; FAF6C2  extz BC
	pushw	bc                                   ; FAF6C4  push BC
	pushw	hl                                   ; FAF6C5  push HL
	calr Voice_ApplyParamChange_Dispatch                 ; FAF6C6  calr 0xfaf031
	ld	xbc, (xiz-4)                            ; FAF6C9  ld XBC,(XIZ+0xfc)
	push	xbc                                   ; FAF6CC  push XBC
	ld	xwa, (xiz-14)                           ; FAF6CD  ld XWA,(XIZ+0xf2)
	add	xwa, 35                                ; FAF6D0  add XWA,0x00000023
	add	xwa, xix                               ; FAF6D6  add XWA,XIX
	ld	c, (xwa)                                ; FAF6D8  ld C,(XWA)
	and	c, 63                                  ; FAF6DA  and C,0x3f
	pushw	bc                                   ; FAF6DD  push BC
	pushw	0xFF                                 ; FAF6DE  push 0x00ff
	pushw	hl                                   ; FAF6E1  push HL
	calr PartRec_ResetSlotValues_ByTag                 ; FAF6E2  calr 0xfaf340
	ld	de, (xiz-10)                            ; FAF6E5  ld DE,(XIZ+0xf6)
	inc	3, de                                  ; FAF6E8  inc 3,DE
	dec	1, h                                   ; FAF6EA  dec 1,H
	add	xsp, 18                                ; FAF6EC  add XSP,0x00000012
	cp	h, 0:i3                                   ; FAF6F2  cp H,0
	jr nz, MidiCtrl_CC04__FAF6AB                  ; FAF6F4  jr NZ,0xfaf6ab
MidiCtrl_CC04__FAF6F6:
	pop	xix                                    ; FAF6F6  pop XIX
	popw	de                                    ; FAF6F7  pop DE
	popw	hl                                    ; FAF6F8  pop HL
	unlk32 xiz                                 ; FAF6F9  unlk XIZ
	ret                                        ; FAF6FB  ret
; --------------------------------------------------------------------------
; MidiCtrl_CC16 -- 0xFAF6FC..0xFAF872 (375 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAFEDD
; Inputs:  frame `link XIZ,-16`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Calls:   0xFAF031 = Voice_ApplyParamChange_Dispatch, 0xFAF340 = PartRec_ResetSlotValues_ByTag
; Evidence: the listing below is the byte-identical round-trip of 0xFAF6FC-0xFAF872
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7).  CONTROLLER 16.  The number is read off `cp BC,16 / jrl Z` at
;          0xFAFDDD; this routine is its only arm, and the dispatcher its only caller.
;          The MIDI standard assigns 16 to "general purpose 1" -- that role is NOT
;          established by anything in this image, and the name states the number only.
;          The 26 (number, handler) pairs are re-extracted from the ROM by
;          `python3 notes/prom_c_dev10c_meaning_checks.py` section 1.
; Unknown:  what the routine DOES with the value.
; --------------------------------------------------------------------------
MidiCtrl_CC16:
	link32 0xEE, 0x0C, 0xF0, 0xFF              ; FAF6FC  link XIZ,0xfff0
	push	xhl                                   ; FAF700  push XHL
	pushw	de                                   ; FAF701  push DE
	push	xix                                   ; FAF702  push XIX
	ldw (xiz-6), 0x0000                        ; FAF703  ld (XIZ+0xfa),0x0000
	ld	bc, (xiz+8)                             ; FAF708  ld BC,(XIZ+0x08)
	extz	bc                                    ; FAF70B  extz BC
	mul	bc, 0x12C                              ; FAF70D  mul BC,0x012c
	ld	hl, bc                                  ; FAF711  ld HL,BC
	add	bc, 23                                 ; FAF713  add BC,0x0017
	ld	(xiz-4), bc                             ; FAF717  ld (XIZ+0xfc),BC
	ld	wa, hl                                  ; FAF71A  ld WA,HL
	inc	4, wa                                  ; FAF71C  inc 4,WA
	ld	(xiz-2), wa                             ; FAF71E  ld (XIZ+0xfe),WA
	ld	xix, 0                                  ; FAF721  ld XIX,0x00000000
	ldw	de, 0                                  ; FAF726  ld DE,0x0000
MidiCtrl_CC16__FAF729:
	ld	bc, (xiz-4)                             ; FAF729  ld BC,(XIZ+0xfc)
	extz	xbc                                   ; FAF72C  extz XBC
	ld	a, (xbc+0x1523)                         ; FAF72E  ld A,(XBC+0x1523)
	ld	(xiz-8), a                              ; FAF733  ld (XIZ+0xf8),A
	ld	wa, (xiz-6)                             ; FAF736  ld WA,(XIZ+0xfa)
	extz	xwa                                   ; FAF739  extz XWA
	add	xwa, 0xFE1280                          ; FAF73B  add XWA,0x00fe1280
	ld	w, (xwa)                                ; FAF741  ld W,(XWA)
	extpfx3 0x8E, 0xF8, 0xC0                   ; FAF743  and W,(XIZ+0xf8)
	jrl z, MidiCtrl_CC16__FAF85F                  ; FAF746  jrl Z,0xfaf85f
	extz	xhl                                   ; FAF749  extz XHL
	ld	xwa, (xhl+0x1523)                       ; FAF74B  ld XWA,(XHL+0x1523)
	ld	c, (xwa+16)                             ; FAF750  ld C,(XWA+0x10)
	and	c, 0xC0                                ; FAF753  and C,0xc0
	extz	bc                                    ; FAF756  extz BC
	cp	bc, 0:i3                                  ; FAF758  cp BC,0
	jr z, MidiCtrl_CC16__FAF772                   ; FAF75A  jr Z,0xfaf772
	cp	bc, 64                                  ; FAF75C  cp BC,0x0040
	jr z, MidiCtrl_CC16__FAF772                   ; FAF760  jr Z,0xfaf772
	cp	bc, 0x80                                ; FAF762  cp BC,0x0080
	jrl z, MidiCtrl_CC16__FAF7E2                  ; FAF766  jrl Z,0xfaf7e2
	cp	bc, 0xC0                                ; FAF769  cp BC,0x00c0
	jr z, MidiCtrl_CC16__FAF772                   ; FAF76D  jr Z,0xfaf772
	jrl MidiCtrl_CC16__FAF85F                     ; FAF76F  jrl T,0xfaf85f
MidiCtrl_CC16__FAF772:
	ld	bc, (xiz-2)                             ; FAF772  ld BC,(XIZ+0xfe)
	extz	xbc                                   ; FAF775  extz XBC
	ld	wa, (xbc+0x1523)                        ; FAF777  ld WA,(XBC+0x1523)
	and	wa, 2                                  ; FAF77C  and WA,0x0002
	jrl nz, MidiCtrl_CC16__FAF85F                 ; FAF780  jrl NZ,0xfaf85f
	extz	xhl                                   ; FAF783  extz XHL
	ld	xwa, (xhl+0x1523)                       ; FAF785  ld XWA,(XHL+0x1523)
	ld	(xiz-10), xwa                           ; FAF78A  ld (XIZ+0xf6),XWA
	ld	(xiz-14), xix                           ; FAF78D  ld (XIZ+0xf2),XIX
	ld	xiy, (xiz-14)                           ; FAF790  ld XIY,(XIZ+0xf2)
	add	xiy, 49                                ; FAF793  add XIY,0x00000031
	add	xwa, xiy                               ; FAF799  add XWA,XIY
	push	xwa                                   ; FAF79B  push XWA
	ld	wa, (xiz+10)                            ; FAF79C  ld WA,(XIZ+0x0a)
	extz	wa                                    ; FAF79F  extz WA
	pushw	wa                                   ; FAF7A1  push WA
	push	0                                     ; FAF7A2  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAF7A4  push (XIZ+0x08)
	calr Voice_ApplyParamChange_Dispatch                 ; FAF7A7  calr 0xfaf031
	ld	bc, hl                                  ; FAF7AA  ld BC,HL
	add	bc, de                                 ; FAF7AC  add BC,DE
	add	bc, 0x76                               ; FAF7AE  add BC,0x0076
	ld	(xiz-16), bc                            ; FAF7B2  ld (XIZ+0xf0),BC
	ldw	wa, 0x1523                             ; FAF7B5  ld WA,0x1523
	extz	xbc                                   ; FAF7B8  extz XBC
	add	bc, wa                                 ; FAF7BA  add BC,WA
	ld	a, (xiz+10)                             ; FAF7BC  ld A,(XIZ+0x0a)
	ld	(xbc), a                                ; FAF7BF  ld (XBC),A
	ld	xbc, (xiz-10)                           ; FAF7C1  ld XBC,(XIZ+0xf6)
	add	xbc, 49                                ; FAF7C4  add XBC,0x00000031
	inc	8, xsp                                 ; FAF7CA  inc 0,XSP
	push	xbc                                   ; FAF7CC  push XBC
	ld	xbc, (xiz-14)                           ; FAF7CD  ld XBC,(XIZ+0xf2)
	add	xbc, 50                                ; FAF7D0  add XBC,0x00000032
	extpfx3 0xAE, 0xF6, 0x81                   ; FAF7D6  add XBC,(XIZ+0xf6)
	ld	a, (xbc)                                ; FAF7D9  ld A,(XBC)
	and	a, 63                                  ; FAF7DB  and A,0x3f
	pushw	wa                                   ; FAF7DE  push WA
	jrl MidiCtrl_CC16__FAF84F                     ; FAF7DF  jrl T,0xfaf84f
MidiCtrl_CC16__FAF7E2:
	ld	bc, (xiz-2)                             ; FAF7E2  ld BC,(XIZ+0xfe)
	extz	xbc                                   ; FAF7E5  extz XBC
	ld	wa, (xbc+0x1523)                        ; FAF7E7  ld WA,(XBC+0x1523)
	and	wa, 2                                  ; FAF7EC  and WA,0x0002
	jrl nz, MidiCtrl_CC16__FAF85F                 ; FAF7F0  jrl NZ,0xfaf85f
	extz	xhl                                   ; FAF7F3  extz XHL
	ld	xwa, (xhl+0x1523)                       ; FAF7F5  ld XWA,(XHL+0x1523)
	ld	(xiz-10), xwa                           ; FAF7FA  ld (XIZ+0xf6),XWA
	ld	(xiz-14), xix                           ; FAF7FD  ld (XIZ+0xf2),XIX
	ld	xiy, (xiz-14)                           ; FAF800  ld XIY,(XIZ+0xf2)
	add	xiy, 46                                ; FAF803  add XIY,0x0000002e
	add	xwa, xiy                               ; FAF809  add XWA,XIY
	push	xwa                                   ; FAF80B  push XWA
	ld	wa, (xiz+10)                            ; FAF80C  ld WA,(XIZ+0x0a)
	extz	wa                                    ; FAF80F  extz WA
	pushw	wa                                   ; FAF811  push WA
	push	0                                     ; FAF812  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAF814  push (XIZ+0x08)
	calr Voice_ApplyParamChange_Dispatch                 ; FAF817  calr 0xfaf031
	ld	bc, hl                                  ; FAF81A  ld BC,HL
	add	bc, de                                 ; FAF81C  add BC,DE
	add	bc, 0x76                               ; FAF81E  add BC,0x0076
	ld	(xiz-16), bc                            ; FAF822  ld (XIZ+0xf0),BC
	ldw	wa, 0x1523                             ; FAF825  ld WA,0x1523
	extz	xbc                                   ; FAF828  extz XBC
	add	bc, wa                                 ; FAF82A  add BC,WA
	ld	a, (xiz+10)                             ; FAF82C  ld A,(XIZ+0x0a)
	ld	(xbc), a                                ; FAF82F  ld (XBC),A
	ld	xbc, (xiz-10)                           ; FAF831  ld XBC,(XIZ+0xf6)
	add	xbc, 46                                ; FAF834  add XBC,0x0000002e
	inc	8, xsp                                 ; FAF83A  inc 0,XSP
	push	xbc                                   ; FAF83C  push XBC
	ld	xbc, (xiz-14)                           ; FAF83D  ld XBC,(XIZ+0xf2)
	add	xbc, 47                                ; FAF840  add XBC,0x0000002f
	extpfx3 0xAE, 0xF6, 0x81                   ; FAF846  add XBC,(XIZ+0xf6)
	ld	a, (xbc)                                ; FAF849  ld A,(XBC)
	and	a, 63                                  ; FAF84B  and A,0x3f
	pushw	wa                                   ; FAF84E  push WA
MidiCtrl_CC16__FAF84F:
	ld	c, (xiz-6)                              ; FAF84F  ld C,(XIZ+0xfa)
	pushw	bc                                   ; FAF852  push BC
	push	0                                     ; FAF853  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAF855  push (XIZ+0x08)
	calr PartRec_ResetSlotValues_ByTag                 ; FAF858  calr 0xfaf340
	inc	8, xsp                                 ; FAF85B  inc 0,XSP
	inc	2, xsp                                 ; FAF85D  inc 2,XSP
MidiCtrl_CC16__FAF85F:
	inc	6, xix                                 ; FAF85F  inc 6,XIX
	inc	2, de                                  ; FAF861  inc 2,DE
	incw	1, (xiz-6)                            ; FAF863  incw 1,(XIZ+0xfa)
	cp	de, 12                                  ; FAF866  cp DE,0x000c
	jrl c, MidiCtrl_CC16__FAF729                  ; FAF86A  jrl C,0xfaf729
	pop	xix                                    ; FAF86D  pop XIX
	popw	de                                    ; FAF86E  pop DE
	pop	xhl                                    ; FAF86F  pop XHL
	unlk32 xiz                                 ; FAF870  unlk XIZ
	ret                                        ; FAF872  ret
; --------------------------------------------------------------------------
; MidiCtrl_CC17 -- 0xFAF873..0xFAF9E5 (371 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAFEEB
; Inputs:  frame `link XIZ,-14`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Calls:   0xFAF031 = Voice_ApplyParamChange_Dispatch, 0xFAF340 = PartRec_ResetSlotValues_ByTag
; Evidence: the listing below is the byte-identical round-trip of 0xFAF873-0xFAF9E5
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7).  CONTROLLER 17.  The number is read off `cp BC,17 / jrl Z` at
;          0xFAFDE4; this routine is its only arm, and the dispatcher its only caller.
;          The MIDI standard assigns 17 to "general purpose 2" -- that role is NOT
;          established by anything in this image, and the name states the number only.
;          The 26 (number, handler) pairs are re-extracted from the ROM by
;          `python3 notes/prom_c_dev10c_meaning_checks.py` section 1.
; Unknown:  what the routine DOES with the value.
; --------------------------------------------------------------------------
MidiCtrl_CC17:
	link32 0xEE, 0x0C, 0xF2, 0xFF              ; FAF873  link XIZ,0xfff2
	push	xhl                                   ; FAF877  push XHL
	pushw	de                                   ; FAF878  push DE
	push	xix                                   ; FAF879  push XIX
	ldw (xiz-6), 0x0000                        ; FAF87A  ld (XIZ+0xfa),0x0000
	ld	bc, (xiz+8)                             ; FAF87F  ld BC,(XIZ+0x08)
	extz	bc                                    ; FAF882  extz BC
	mul	bc, 0x12C                              ; FAF884  mul BC,0x012c
	ld	hl, bc                                  ; FAF888  ld HL,BC
	add	bc, 23                                 ; FAF88A  add BC,0x0017
	ld	(xiz-4), bc                             ; FAF88E  ld (XIZ+0xfc),BC
	ld	wa, hl                                  ; FAF891  ld WA,HL
	inc	4, wa                                  ; FAF893  inc 4,WA
	ld	(xiz-2), wa                             ; FAF895  ld (XIZ+0xfe),WA
	ld	xix, 0                                  ; FAF898  ld XIX,0x00000000
	ldw	de, 0                                  ; FAF89D  ld DE,0x0000
MidiCtrl_CC17__FAF8A0:
	ld	bc, (xiz-4)                             ; FAF8A0  ld BC,(XIZ+0xfc)
	extz	xbc                                   ; FAF8A3  extz XBC
	ld	a, (xbc+0x1523)                         ; FAF8A5  ld A,(XBC+0x1523)
	ld	(xiz-8), a                              ; FAF8AA  ld (XIZ+0xf8),A
	ld	wa, (xiz-6)                             ; FAF8AD  ld WA,(XIZ+0xfa)
	extz	xwa                                   ; FAF8B0  extz XWA
	add	xwa, 0xFE1280                          ; FAF8B2  add XWA,0x00fe1280
	ld	w, (xwa)                                ; FAF8B8  ld W,(XWA)
	extpfx3 0x8E, 0xF8, 0xC0                   ; FAF8BA  and W,(XIZ+0xf8)
	jrl z, MidiCtrl_CC17__FAF9D2                  ; FAF8BD  jrl Z,0xfaf9d2
	extz	xhl                                   ; FAF8C0  extz XHL
	ld	xwa, (xhl+0x1523)                       ; FAF8C2  ld XWA,(XHL+0x1523)
	ld	c, (xwa+16)                             ; FAF8C7  ld C,(XWA+0x10)
	and	c, 0xC0                                ; FAF8CA  and C,0xc0
	extz	bc                                    ; FAF8CD  extz BC
	cp	bc, 0:i3                                  ; FAF8CF  cp BC,0
	jr z, MidiCtrl_CC17__FAF8E9                   ; FAF8D1  jr Z,0xfaf8e9
	cp	bc, 64                                  ; FAF8D3  cp BC,0x0040
	jr z, MidiCtrl_CC17__FAF8E9                   ; FAF8D7  jr Z,0xfaf8e9
	cp	bc, 0x80                                ; FAF8D9  cp BC,0x0080
	jrl z, MidiCtrl_CC17__FAF957                  ; FAF8DD  jrl Z,0xfaf957
	cp	bc, 0xC0                                ; FAF8E0  cp BC,0x00c0
	jr z, MidiCtrl_CC17__FAF8E9                   ; FAF8E4  jr Z,0xfaf8e9
	jrl MidiCtrl_CC17__FAF9D2                     ; FAF8E6  jrl T,0xfaf9d2
MidiCtrl_CC17__FAF8E9:
	ld	bc, (xiz-2)                             ; FAF8E9  ld BC,(XIZ+0xfe)
	extz	xbc                                   ; FAF8EC  extz XBC
	ld	wa, (xbc+0x1523)                        ; FAF8EE  ld WA,(XBC+0x1523)
	and	wa, 2                                  ; FAF8F3  and WA,0x0002
	jrl nz, MidiCtrl_CC17__FAF9D2                 ; FAF8F7  jrl NZ,0xfaf9d2
	extz	xhl                                   ; FAF8FA  extz XHL
	ld	xwa, (xhl+0x1523)                       ; FAF8FC  ld XWA,(XHL+0x1523)
	ld	(xiz-10), xwa                           ; FAF901  ld (XIZ+0xf6),XWA
	ld	(xiz-14), xix                           ; FAF904  ld (XIZ+0xf2),XIX
	ld	xiy, (xiz-14)                           ; FAF907  ld XIY,(XIZ+0xf2)
	add	xiy, 52                                ; FAF90A  add XIY,0x00000034
	add	xwa, xiy                               ; FAF910  add XWA,XIY
	push	xwa                                   ; FAF912  push XWA
	ld	wa, (xiz+10)                            ; FAF913  ld WA,(XIZ+0x0a)
	extz	wa                                    ; FAF916  extz WA
	pushw	wa                                   ; FAF918  push WA
	push	0                                     ; FAF919  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAF91B  push (XIZ+0x08)
	calr Voice_ApplyParamChange_Dispatch                 ; FAF91E  calr 0xfaf031
	ld	bc, hl                                  ; FAF921  ld BC,HL
	add	bc, de                                 ; FAF923  add BC,DE
	add	bc, 0x77                               ; FAF925  add BC,0x0077
	extz	xbc                                   ; FAF929  extz XBC
	ld	a, (xiz+10)                             ; FAF92B  ld A,(XIZ+0x0a)
	ld	(xbc+0x1523), a                         ; FAF92E  ld (XBC+0x1523),A
	ld	xbc, (xiz-10)                           ; FAF933  ld XBC,(XIZ+0xf6)
	add	xbc, 49                                ; FAF936  add XBC,0x00000031
	inc	8, xsp                                 ; FAF93C  inc 0,XSP
	push	xbc                                   ; FAF93E  push XBC
	ld	xbc, (xiz-14)                           ; FAF93F  ld XBC,(XIZ+0xf2)
	add	xbc, 53                                ; FAF942  add XBC,0x00000035
	extpfx3 0xAE, 0xF6, 0x81                   ; FAF948  add XBC,(XIZ+0xf6)
	ld	w, (xbc)                                ; FAF94B  ld W,(XBC)
	and	w, 63                                  ; FAF94D  and W,0x3f
	push	0                                     ; FAF950  push 0x00
	push	w                                     ; FAF952  push W
	jrl MidiCtrl_CC17__FAF9C2                     ; FAF954  jrl T,0xfaf9c2
MidiCtrl_CC17__FAF957:
	ld	bc, (xiz-2)                             ; FAF957  ld BC,(XIZ+0xfe)
	extz	xbc                                   ; FAF95A  extz XBC
	ld	wa, (xbc+0x1523)                        ; FAF95C  ld WA,(XBC+0x1523)
	and	wa, 2                                  ; FAF961  and WA,0x0002
	jrl nz, MidiCtrl_CC17__FAF9D2                 ; FAF965  jrl NZ,0xfaf9d2
	extz	xhl                                   ; FAF968  extz XHL
	ld	xwa, (xhl+0x1523)                       ; FAF96A  ld XWA,(XHL+0x1523)
	ld	(xiz-10), xwa                           ; FAF96F  ld (XIZ+0xf6),XWA
	ld	(xiz-14), xix                           ; FAF972  ld (XIZ+0xf2),XIX
	ld	xiy, (xiz-14)                           ; FAF975  ld XIY,(XIZ+0xf2)
	add	xiy, 49                                ; FAF978  add XIY,0x00000031
	add	xwa, xiy                               ; FAF97E  add XWA,XIY
	push	xwa                                   ; FAF980  push XWA
	ld	wa, (xiz+10)                            ; FAF981  ld WA,(XIZ+0x0a)
	extz	wa                                    ; FAF984  extz WA
	pushw	wa                                   ; FAF986  push WA
	push	0                                     ; FAF987  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAF989  push (XIZ+0x08)
	calr Voice_ApplyParamChange_Dispatch                 ; FAF98C  calr 0xfaf031
	ld	bc, hl                                  ; FAF98F  ld BC,HL
	add	bc, de                                 ; FAF991  add BC,DE
	add	bc, 0x77                               ; FAF993  add BC,0x0077
	extz	xbc                                   ; FAF997  extz XBC
	ld	a, (xiz+10)                             ; FAF999  ld A,(XIZ+0x0a)
	ld	(xbc+0x1523), a                         ; FAF99C  ld (XBC+0x1523),A
	ld	xbc, (xiz-10)                           ; FAF9A1  ld XBC,(XIZ+0xf6)
	add	xbc, 46                                ; FAF9A4  add XBC,0x0000002e
	inc	8, xsp                                 ; FAF9AA  inc 0,XSP
	push	xbc                                   ; FAF9AC  push XBC
	ld	xbc, (xiz-14)                           ; FAF9AD  ld XBC,(XIZ+0xf2)
	add	xbc, 50                                ; FAF9B0  add XBC,0x00000032
	extpfx3 0xAE, 0xF6, 0x81                   ; FAF9B6  add XBC,(XIZ+0xf6)
	ld	w, (xbc)                                ; FAF9B9  ld W,(XBC)
	and	w, 63                                  ; FAF9BB  and W,0x3f
	push	0                                     ; FAF9BE  push 0x00
	push	w                                     ; FAF9C0  push W
MidiCtrl_CC17__FAF9C2:
	ld	c, (xiz-6)                              ; FAF9C2  ld C,(XIZ+0xfa)
	pushw	bc                                   ; FAF9C5  push BC
	push	0                                     ; FAF9C6  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAF9C8  push (XIZ+0x08)
	calr PartRec_ResetSlotValues_ByTag                 ; FAF9CB  calr 0xfaf340
	inc	8, xsp                                 ; FAF9CE  inc 0,XSP
	inc	2, xsp                                 ; FAF9D0  inc 2,XSP
MidiCtrl_CC17__FAF9D2:
	inc	6, xix                                 ; FAF9D2  inc 6,XIX
	inc	2, de                                  ; FAF9D4  inc 2,DE
	incw	1, (xiz-6)                            ; FAF9D6  incw 1,(XIZ+0xfa)
	cp	de, 12                                  ; FAF9D9  cp DE,0x000c
	jrl c, MidiCtrl_CC17__FAF8A0                  ; FAF9DD  jrl C,0xfaf8a0
	pop	xix                                    ; FAF9E0  pop XIX
	popw	de                                    ; FAF9E1  pop DE
	pop	xhl                                    ; FAF9E2  pop XHL
	unlk32 xiz                                 ; FAF9E3  unlk XIZ
	ret                                        ; FAF9E5  ret
; --------------------------------------------------------------------------
; MidiCtrl_CC18 -- 0xFAF9E6..0xFAFAE8 (259 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAFEF9
; Inputs:  frame `link XIZ,-14`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Calls:   0xFAF031 = Voice_ApplyParamChange_Dispatch, 0xFAF340 = PartRec_ResetSlotValues_ByTag
; Evidence: the listing below is the byte-identical round-trip of 0xFAF9E6-0xFAFAE8
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7).  CONTROLLER 18.  The number is read off `cp BC,18 / jrl Z` at
;          0xFAFDEB; this routine is its only arm, and the dispatcher its only caller.
;          The MIDI standard assigns 18 to "general purpose 3" -- that role is NOT
;          established by anything in this image, and the name states the number only.
;          The 26 (number, handler) pairs are re-extracted from the ROM by
;          `python3 notes/prom_c_dev10c_meaning_checks.py` section 1.
; Unknown:  what the routine DOES with the value.
; --------------------------------------------------------------------------
MidiCtrl_CC18:
	link32 0xEE, 0x0C, 0xF2, 0xFF              ; FAF9E6  link XIZ,0xfff2
	pushw	hl                                   ; FAF9EA  push HL
	push	xde                                   ; FAF9EB  push XDE
	push	xix                                   ; FAF9EC  push XIX
	ld	l, (xiz+8)                              ; FAF9ED  ld L,(XIZ+0x08)
	ld	c, l                                    ; FAF9F0  ld C,L
	extz	bc                                    ; FAF9F2  extz BC
	mul	bc, 0x12C                              ; FAF9F4  mul BC,0x012c
	ld	de, bc                                  ; FAF9F8  ld DE,BC
	add	bc, 24                                 ; FAF9FA  add BC,0x0018
	ld	(xiz-2), bc                             ; FAF9FE  ld (XIZ+0xfe),BC
	ld	xix, 0                                  ; FAFA01  ld XIX,0x00000000
	ld	h, 0:opc                                   ; FAFA06  ld H,0x00
MidiCtrl_CC18__FAFA08:
	ld	bc, (xiz-2)                             ; FAFA08  ld BC,(XIZ+0xfe)
	extz	xbc                                   ; FAFA0B  extz XBC
	ld	a, (xbc+0x1523)                         ; FAFA0D  ld A,(XBC+0x1523)
	ld	(xiz-8), a                              ; FAFA12  ld (XIZ+0xf8),A
	ld	a, h                                    ; FAFA15  ld A,H
	extz	wa                                    ; FAFA17  extz WA
	extz	xwa                                   ; FAFA19  extz XWA
	add	xwa, 0xFE1280                          ; FAFA1B  add XWA,0x00fe1280
	ld	w, (xwa)                                ; FAFA21  ld W,(XWA)
	extpfx3 0x8E, 0xF8, 0xC0                   ; FAFA23  and W,(XIZ+0xf8)
	jrl z, MidiCtrl_CC18__FAFADA                  ; FAFA26  jrl Z,0xfafada
	extz	xde                                   ; FAFA29  extz XDE
	ld	xwa, (xde+0x1523)                       ; FAFA2B  ld XWA,(XDE+0x1523)
	ld	(xiz-6), xwa                            ; FAFA30  ld (XIZ+0xfa),XWA
	ld	c, (xwa+16)                             ; FAFA33  ld C,(XWA+0x10)
	and	c, 0xC0                                ; FAFA36  and C,0xc0
	extz	bc                                    ; FAFA39  extz BC
	cp	bc, 0:i3                                  ; FAFA3B  cp BC,0
	jr z, MidiCtrl_CC18__FAFA54                   ; FAFA3D  jr Z,0xfafa54
	cp	bc, 64                                  ; FAFA3F  cp BC,0x0040
	jr z, MidiCtrl_CC18__FAFA54                   ; FAFA43  jr Z,0xfafa54
	cp	bc, 0x80                                ; FAFA45  cp BC,0x0080
	jr z, MidiCtrl_CC18__FAFA97                   ; FAFA49  jr Z,0xfafa97
	cp	bc, 0xC0                                ; FAFA4B  cp BC,0x00c0
	jr z, MidiCtrl_CC18__FAFA54                   ; FAFA4F  jr Z,0xfafa54
	jrl MidiCtrl_CC18__FAFADA                     ; FAFA51  jrl T,0xfafada
MidiCtrl_CC18__FAFA54:
	extz	xde                                   ; FAFA54  extz XDE
	ld	xbc, (xde+0x1523)                       ; FAFA56  ld XBC,(XDE+0x1523)
	ld	(xiz-10), xbc                           ; FAFA5B  ld (XIZ+0xf6),XBC
	ld	(xiz-14), xix                           ; FAFA5E  ld (XIZ+0xf2),XIX
	ld	xwa, (xiz-14)                           ; FAFA61  ld XWA,(XIZ+0xf2)
	add	xwa, 49                                ; FAFA64  add XWA,0x00000031
	add	xbc, xwa                               ; FAFA6A  add XBC,XWA
	push	xbc                                   ; FAFA6C  push XBC
	ld	bc, (xiz+10)                            ; FAFA6D  ld BC,(XIZ+0x0a)
	extz	bc                                    ; FAFA70  extz BC
	pushw	bc                                   ; FAFA72  push BC
	pushw	hl                                   ; FAFA73  push HL
	calr Voice_ApplyParamChange_Dispatch                 ; FAFA74  calr 0xfaf031
	ld	xbc, (xiz-10)                           ; FAFA77  ld XBC,(XIZ+0xf6)
	add	xbc, 49                                ; FAFA7A  add XBC,0x00000031
	inc	8, xsp                                 ; FAFA80  inc 0,XSP
	push	xbc                                   ; FAFA82  push XBC
	ld	xbc, (xiz-14)                           ; FAFA83  ld XBC,(XIZ+0xf2)
	add	xbc, 50                                ; FAFA86  add XBC,0x00000032
	extpfx3 0xAE, 0xF6, 0x81                   ; FAFA8C  add XBC,(XIZ+0xf6)
	ld	a, (xbc)                                ; FAFA8F  ld A,(XBC)
	and	a, 63                                  ; FAFA91  and A,0x3f
	pushw	wa                                   ; FAFA94  push WA
	jr MidiCtrl_CC18__FAFACF                      ; FAFA95  jr T,0xfafacf
MidiCtrl_CC18__FAFA97:
	ld	(xiz-10), xix                           ; FAFA97  ld (XIZ+0xf6),XIX
	ld	xbc, (xiz-10)                           ; FAFA9A  ld XBC,(XIZ+0xf6)
	add	xbc, 46                                ; FAFA9D  add XBC,0x0000002e
	extpfx3 0xAE, 0xFA, 0x81                   ; FAFAA3  add XBC,(XIZ+0xfa)
	push	xbc                                   ; FAFAA6  push XBC
	ld	bc, (xiz+10)                            ; FAFAA7  ld BC,(XIZ+0x0a)
	extz	bc                                    ; FAFAAA  extz BC
	pushw	bc                                   ; FAFAAC  push BC
	pushw	hl                                   ; FAFAAD  push HL
	calr Voice_ApplyParamChange_Dispatch                 ; FAFAAE  calr 0xfaf031
	ld	xbc, (xiz-6)                            ; FAFAB1  ld XBC,(XIZ+0xfa)
	add	xbc, 46                                ; FAFAB4  add XBC,0x0000002e
	inc	8, xsp                                 ; FAFABA  inc 0,XSP
	push	xbc                                   ; FAFABC  push XBC
	ld	xbc, (xiz-10)                           ; FAFABD  ld XBC,(XIZ+0xf6)
	add	xbc, 47                                ; FAFAC0  add XBC,0x0000002f
	extpfx3 0xAE, 0xFA, 0x81                   ; FAFAC6  add XBC,(XIZ+0xfa)
	ld	a, (xbc)                                ; FAFAC9  ld A,(XBC)
	and	a, 63                                  ; FAFACB  and A,0x3f
	pushw	wa                                   ; FAFACE  push WA
MidiCtrl_CC18__FAFACF:
	pushw	0xFF                                 ; FAFACF  push 0x00ff
	pushw	hl                                   ; FAFAD2  push HL
	calr PartRec_ResetSlotValues_ByTag                 ; FAFAD3  calr 0xfaf340
	inc	8, xsp                                 ; FAFAD6  inc 0,XSP
	inc	2, xsp                                 ; FAFAD8  inc 2,XSP
MidiCtrl_CC18__FAFADA:
	inc	6, xix                                 ; FAFADA  inc 6,XIX
	inc	1, h                                   ; FAFADC  inc 1,H
	cp	h, 6:i3                                   ; FAFADE  cp H,6
	jrl c, MidiCtrl_CC18__FAFA08                  ; FAFAE0  jrl C,0xfafa08
	pop	xix                                    ; FAFAE3  pop XIX
	pop	xde                                    ; FAFAE4  pop XDE
	popw	hl                                    ; FAFAE5  pop HL
	unlk32 xiz                                 ; FAFAE6  unlk XIZ
	ret                                        ; FAFAE8  ret
; --------------------------------------------------------------------------
; MidiCtrl_CC19 -- 0xFAFAE9..0xFAFBEB (259 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAFF07
; Inputs:  frame `link XIZ,-14`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Calls:   0xFAF031 = Voice_ApplyParamChange_Dispatch, 0xFAF340 = PartRec_ResetSlotValues_ByTag
; Evidence: the listing below is the byte-identical round-trip of 0xFAFAE9-0xFAFBEB
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7).  CONTROLLER 19.  The number is read off `cp BC,19 / jrl Z` at
;          0xFAFDF2; this routine is its only arm, and the dispatcher its only caller.
;          The MIDI standard assigns 19 to "general purpose 4" -- that role is NOT
;          established by anything in this image, and the name states the number only.
;          The 26 (number, handler) pairs are re-extracted from the ROM by
;          `python3 notes/prom_c_dev10c_meaning_checks.py` section 1.
; Unknown:  what the routine DOES with the value.
; --------------------------------------------------------------------------
MidiCtrl_CC19:
	link32 0xEE, 0x0C, 0xF2, 0xFF              ; FAFAE9  link XIZ,0xfff2
	pushw	hl                                   ; FAFAED  push HL
	push	xde                                   ; FAFAEE  push XDE
	push	xix                                   ; FAFAEF  push XIX
	ld	l, (xiz+8)                              ; FAFAF0  ld L,(XIZ+0x08)
	ld	c, l                                    ; FAFAF3  ld C,L
	extz	bc                                    ; FAFAF5  extz BC
	mul	bc, 0x12C                              ; FAFAF7  mul BC,0x012c
	ld	de, bc                                  ; FAFAFB  ld DE,BC
	add	bc, 24                                 ; FAFAFD  add BC,0x0018
	ld	(xiz-2), bc                             ; FAFB01  ld (XIZ+0xfe),BC
	ld	xix, 0                                  ; FAFB04  ld XIX,0x00000000
	ld	h, 0:opc                                   ; FAFB09  ld H,0x00
MidiCtrl_CC19__FAFB0B:
	ld	bc, (xiz-2)                             ; FAFB0B  ld BC,(XIZ+0xfe)
	extz	xbc                                   ; FAFB0E  extz XBC
	ld	a, (xbc+0x1523)                         ; FAFB10  ld A,(XBC+0x1523)
	ld	(xiz-8), a                              ; FAFB15  ld (XIZ+0xf8),A
	ld	a, h                                    ; FAFB18  ld A,H
	extz	wa                                    ; FAFB1A  extz WA
	extz	xwa                                   ; FAFB1C  extz XWA
	add	xwa, 0xFE1280                          ; FAFB1E  add XWA,0x00fe1280
	ld	w, (xwa)                                ; FAFB24  ld W,(XWA)
	extpfx3 0x8E, 0xF8, 0xC0                   ; FAFB26  and W,(XIZ+0xf8)
	jrl z, MidiCtrl_CC19__FAFBDD                  ; FAFB29  jrl Z,0xfafbdd
	extz	xde                                   ; FAFB2C  extz XDE
	ld	xwa, (xde+0x1523)                       ; FAFB2E  ld XWA,(XDE+0x1523)
	ld	(xiz-6), xwa                            ; FAFB33  ld (XIZ+0xfa),XWA
	ld	c, (xwa+16)                             ; FAFB36  ld C,(XWA+0x10)
	and	c, 0xC0                                ; FAFB39  and C,0xc0
	extz	bc                                    ; FAFB3C  extz BC
	cp	bc, 0:i3                                  ; FAFB3E  cp BC,0
	jr z, MidiCtrl_CC19__FAFB57                   ; FAFB40  jr Z,0xfafb57
	cp	bc, 64                                  ; FAFB42  cp BC,0x0040
	jr z, MidiCtrl_CC19__FAFB57                   ; FAFB46  jr Z,0xfafb57
	cp	bc, 0x80                                ; FAFB48  cp BC,0x0080
	jr z, MidiCtrl_CC19__FAFB9A                   ; FAFB4C  jr Z,0xfafb9a
	cp	bc, 0xC0                                ; FAFB4E  cp BC,0x00c0
	jr z, MidiCtrl_CC19__FAFB57                   ; FAFB52  jr Z,0xfafb57
	jrl MidiCtrl_CC19__FAFBDD                     ; FAFB54  jrl T,0xfafbdd
MidiCtrl_CC19__FAFB57:
	extz	xde                                   ; FAFB57  extz XDE
	ld	xbc, (xde+0x1523)                       ; FAFB59  ld XBC,(XDE+0x1523)
	ld	(xiz-10), xbc                           ; FAFB5E  ld (XIZ+0xf6),XBC
	ld	(xiz-14), xix                           ; FAFB61  ld (XIZ+0xf2),XIX
	ld	xwa, (xiz-14)                           ; FAFB64  ld XWA,(XIZ+0xf2)
	add	xwa, 52                                ; FAFB67  add XWA,0x00000034
	add	xbc, xwa                               ; FAFB6D  add XBC,XWA
	push	xbc                                   ; FAFB6F  push XBC
	ld	bc, (xiz+10)                            ; FAFB70  ld BC,(XIZ+0x0a)
	extz	bc                                    ; FAFB73  extz BC
	pushw	bc                                   ; FAFB75  push BC
	pushw	hl                                   ; FAFB76  push HL
	calr Voice_ApplyParamChange_Dispatch                 ; FAFB77  calr 0xfaf031
	ld	xbc, (xiz-10)                           ; FAFB7A  ld XBC,(XIZ+0xf6)
	add	xbc, 49                                ; FAFB7D  add XBC,0x00000031
	inc	8, xsp                                 ; FAFB83  inc 0,XSP
	push	xbc                                   ; FAFB85  push XBC
	ld	xbc, (xiz-14)                           ; FAFB86  ld XBC,(XIZ+0xf2)
	add	xbc, 53                                ; FAFB89  add XBC,0x00000035
	extpfx3 0xAE, 0xF6, 0x81                   ; FAFB8F  add XBC,(XIZ+0xf6)
	ld	a, (xbc)                                ; FAFB92  ld A,(XBC)
	and	a, 63                                  ; FAFB94  and A,0x3f
	pushw	wa                                   ; FAFB97  push WA
	jr MidiCtrl_CC19__FAFBD2                      ; FAFB98  jr T,0xfafbd2
MidiCtrl_CC19__FAFB9A:
	ld	(xiz-10), xix                           ; FAFB9A  ld (XIZ+0xf6),XIX
	ld	xbc, (xiz-10)                           ; FAFB9D  ld XBC,(XIZ+0xf6)
	add	xbc, 49                                ; FAFBA0  add XBC,0x00000031
	extpfx3 0xAE, 0xFA, 0x81                   ; FAFBA6  add XBC,(XIZ+0xfa)
	push	xbc                                   ; FAFBA9  push XBC
	ld	bc, (xiz+10)                            ; FAFBAA  ld BC,(XIZ+0x0a)
	extz	bc                                    ; FAFBAD  extz BC
	pushw	bc                                   ; FAFBAF  push BC
	pushw	hl                                   ; FAFBB0  push HL
	calr Voice_ApplyParamChange_Dispatch                 ; FAFBB1  calr 0xfaf031
	ld	xbc, (xiz-6)                            ; FAFBB4  ld XBC,(XIZ+0xfa)
	add	xbc, 46                                ; FAFBB7  add XBC,0x0000002e
	inc	8, xsp                                 ; FAFBBD  inc 0,XSP
	push	xbc                                   ; FAFBBF  push XBC
	ld	xbc, (xiz-10)                           ; FAFBC0  ld XBC,(XIZ+0xf6)
	add	xbc, 50                                ; FAFBC3  add XBC,0x00000032
	extpfx3 0xAE, 0xFA, 0x81                   ; FAFBC9  add XBC,(XIZ+0xfa)
	ld	a, (xbc)                                ; FAFBCC  ld A,(XBC)
	and	a, 63                                  ; FAFBCE  and A,0x3f
	pushw	wa                                   ; FAFBD1  push WA
MidiCtrl_CC19__FAFBD2:
	pushw	0xFF                                 ; FAFBD2  push 0x00ff
	pushw	hl                                   ; FAFBD5  push HL
	calr PartRec_ResetSlotValues_ByTag                 ; FAFBD6  calr 0xfaf340
	inc	8, xsp                                 ; FAFBD9  inc 0,XSP
	inc	2, xsp                                 ; FAFBDB  inc 2,XSP
MidiCtrl_CC19__FAFBDD:
	inc	6, xix                                 ; FAFBDD  inc 6,XIX
	inc	1, h                                   ; FAFBDF  inc 1,H
	cp	h, 6:i3                                   ; FAFBE1  cp H,6
	jrl c, MidiCtrl_CC19__FAFB0B                  ; FAFBE3  jrl C,0xfafb0b
	pop	xix                                    ; FAFBE6  pop XIX
	pop	xde                                    ; FAFBE7  pop XDE
	popw	hl                                    ; FAFBE8  pop HL
	unlk32 xiz                                 ; FAFBE9  unlk XIZ
	ret                                        ; FAFBEB  ret
; --------------------------------------------------------------------------
; sub_FAFBEC -- 0xFAFBEC..0xFAFCE0 (245 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFBBC60 in sub_FBB793__FBBC51
;          1 site(s) inside this module:
;          0xFAFF54
; Inputs:  frame `link XIZ,-6`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Calls:   0xFAD880 = PartRec_Flags09_Bit14_SetOrClear, 0xFB4A9F = PartRec_RecomputeWord0006_FromToneRec
;          0xFB4D45 = sub_FB4D45, 0xFB5636 = Part_StageDspAlgoParams
;          0xFB5E00 = Part_GetDspParam_00D8, 0xFB639A = PartElement_StageAlgoDescBytes_0024
;          0xFB6487 = PartRec_StageByte0075_FromDspParam00D7, 0xFBB765 = sub_FBB765
;          0xFC6803 = Pack104_LoadElementWaveSelRec
; Evidence: the listing below is the byte-identical round-trip of 0xFAFBEC-0xFAFCE0
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FAFBEC:
	link32 0xEE, 0x0C, 0xFA, 0xFF              ; FAFBEC  link XIZ,0xfffa
	pushw	hl                                   ; FAFBF0  push HL
	pushw	de                                   ; FAFBF1  push DE
	pushw	ix                                   ; FAFBF2  push IX
	ld	e, (xiz+8)                              ; FAFBF3  ld E,(XIZ+0x08)
	ld	c, e                                    ; FAFBF6  ld C,E
	extz	bc                                    ; FAFBF8  extz BC
	mul	bc, 0x12C                              ; FAFBFA  mul BC,0x012c
	extz	xbc                                   ; FAFBFE  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FAFC00  ld XWA,(XBC+0x1523)
	ld	c, (xwa+16)                             ; FAFC05  ld C,(XWA+0x10)
	and	c, 0xC0                                ; FAFC08  and C,0xc0
	extz	bc                                    ; FAFC0B  extz BC
	cp	bc, 0:i3                                  ; FAFC0D  cp BC,0
	jr z, sub_FAFBEC__FAFC28                   ; FAFC0F  jr Z,0xfafc28
	cp	bc, 64                                  ; FAFC11  cp BC,0x0040
	jrl z, sub_FAFBEC__FAFCDB                  ; FAFC15  jrl Z,0xfafcdb
	cp	bc, 0x80                                ; FAFC18  cp BC,0x0080
	jrl z, sub_FAFBEC__FAFCDB                  ; FAFC1C  jrl Z,0xfafcdb
	cp	bc, 0xC0                                ; FAFC1F  cp BC,0x00c0
	jr z, sub_FAFBEC__FAFC28                   ; FAFC23  jr Z,0xfafc28
	jrl sub_FAFBEC__FAFCDB                     ; FAFC25  jrl T,0xfafcdb
sub_FAFBEC__FAFC28:
	push	0                                     ; FAFC28  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FAFC2A  push (XIZ+0x0a)
	pushw	de                                   ; FAFC2D  push DE
	calr PartRec_Flags09_Bit14_SetOrClear                 ; FAFC2E  calr 0xfad880
	pushw	1                                    ; FAFC31  push 0x0001
	pushw	de                                   ; FAFC34  push DE
	call	Part_StageDspAlgoParams                              ; FAFC35  call 0xfb5636
	push	0                                     ; FAFC39  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FAFC3B  push (XIZ+0x0a)
	pushw	de                                   ; FAFC3E  push DE
	call	sub_FBB765                              ; FAFC3F  call 0xfbb765
	pushw	de                                   ; FAFC43  push DE
	call	PartRec_RecomputeWord0006_FromToneRec                              ; FAFC44  call 0xfb4a9f
	pushw	de                                   ; FAFC48  push DE
	call	sub_FB4D45                              ; FAFC49  call 0xfb4d45
	pushw	de                                   ; FAFC4D  push DE
	call	PartElement_StageAlgoDescBytes_0024                              ; FAFC4E  call 0xfb639a
	pushw	de                                   ; FAFC52  push DE
	call	PartRec_StageByte0075_FromDspParam00D7                              ; FAFC53  call 0xfb6487
	pushw	de                                   ; FAFC57  push DE
	call	Part_GetDspParam_00D8                              ; FAFC58  call 0xfb5e00
	ld	(xiz-6), a                              ; FAFC5C  ld (XIZ+0xfa),A
	ld	c, e                                    ; FAFC5F  ld C,E
	extz	bc                                    ; FAFC61  extz BC
	mul	bc, 0x12C                              ; FAFC63  mul BC,0x012c
	ld	hl, bc                                  ; FAFC67  ld HL,BC
	add	bc, 0x74                               ; FAFC69  add BC,0x0074
	extz	xbc                                   ; FAFC6D  extz XBC
	ld	(xbc+0x1523), a                         ; FAFC6F  ld (XBC+0x1523),A
	ld	d, 0:opc                                   ; FAFC74  ld D,0x00
	ld	(xiz-4), hl                             ; FAFC76  ld (XIZ+0xfc),HL
	ld	bc, hl                                  ; FAFC79  ld BC,HL
	inc	6, bc                                  ; FAFC7B  inc 6,BC
	ld	(xiz-2), bc                             ; FAFC7D  ld (XIZ+0xfe),BC
	ldw	hl, 0                                  ; FAFC80  ld HL,0x0000
	ldw	ix, 0                                  ; FAFC83  ld IX,0x0000
	add	xsp, 22                                ; FAFC86  add XSP,0x00000016
sub_FAFBEC__FAFC8C:
	ld	bc, (xiz-2)                             ; FAFC8C  ld BC,(XIZ+0xfe)
	extz	xbc                                   ; FAFC8F  extz XBC
	ld	wa, (xbc+0x1523)                        ; FAFC91  ld WA,(XBC+0x1523)
	ld	(xiz-6), wa                             ; FAFC96  ld (XIZ+0xfa),WA
	ld	iy, hl                                  ; FAFC99  ld IY,HL
	extz	xiy                                   ; FAFC9B  extz XIY
	add	xiy, 0xFDE695                          ; FAFC9D  add XIY,0x00fde695
	ld	iy, (xiy)                               ; FAFCA3  ld IY,(XIY)
	and	wa, iy                                 ; FAFCA5  and WA,IY
	jr z, sub_FAFBEC__FAFCAE                   ; FAFCA7  jr Z,0xfafcae
	pushw	1                                    ; FAFCA9  push 0x0001
	jr sub_FAFBEC__FAFCB1                      ; FAFCAC  jr T,0xfafcb1
sub_FAFBEC__FAFCAE:
	pushw	0                                    ; FAFCAE  push 0x0000
sub_FAFBEC__FAFCB1:
	ld	bc, (xiz-4)                             ; FAFCB1  ld BC,(XIZ+0xfc)
	add	bc, ix                                 ; FAFCB4  add BC,IX
	add	bc, 0x8C                               ; FAFCB6  add BC,0x008c
	extz	xbc                                   ; FAFCBA  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FAFCBC  ld XWA,(XBC+0x1523)
	push	xwa                                   ; FAFCC1  push XWA
	push	0                                     ; FAFCC2  push 0x00
	push	d                                     ; FAFCC4  push D
	pushw	de                                   ; FAFCC6  push DE
	call	Pack104_LoadElementWaveSelRec                              ; FAFCC7  call 0xfc6803
	inc	2, hl                                  ; FAFCCB  inc 2,HL
	add	ix, 41                                 ; FAFCCD  add IX,0x0029
	inc	1, d                                   ; FAFCD1  inc 1,D
	inc	8, xsp                                 ; FAFCD3  inc 0,XSP
	inc	2, xsp                                 ; FAFCD5  inc 2,XSP
	cp	d, 4:i3                                   ; FAFCD7  cp D,4
	jr c, sub_FAFBEC__FAFC8C                   ; FAFCD9  jr C,0xfafc8c
sub_FAFBEC__FAFCDB:
	popw	ix                                    ; FAFCDB  pop IX
	popw	de                                    ; FAFCDC  pop DE
	popw	hl                                    ; FAFCDD  pop HL
	unlk32 xiz                                 ; FAFCDE  unlk XIZ
	ret                                        ; FAFCE0  ret
; --------------------------------------------------------------------------
; MidiCtrl_CC120 -- 0xFAFCE1..0xFAFDA4 (196 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAFF5E
; Inputs:  frame `link XIZ,-8`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFACC3F = PartRec_Word0006_SetBit13, 0xFB3C5F = VoiceQuery_Tag80_Part
;          0xFB3CE0 = VoiceQuery_Tag00_Part
; Evidence: the listing below is the byte-identical round-trip of 0xFAFCE1-0xFAFDA4
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7).  CONTROLLER 120.  The number is read off `cp BC,120 / jrl Z` at
;          0xFAFE15; this routine is its only arm, and the dispatcher its only caller.
;          The MIDI standard assigns 120 to "all sound off" -- that role is NOT
;          established by anything in this image, and the name states the number only.
;          The 26 (number, handler) pairs are re-extracted from the ROM by
;          `python3 notes/prom_c_dev10c_meaning_checks.py` section 1.
; Unknown:  what the routine DOES with the value.
; --------------------------------------------------------------------------
MidiCtrl_CC120:
	link32 0xEE, 0x0C, 0xF8, 0xFF              ; FAFCE1  link XIZ,0xfff8
	pushw	hl                                   ; FAFCE5  push HL
	push	xix                                   ; FAFCE6  push XIX
	ld	l, (xiz+8)                              ; FAFCE7  ld L,(XIZ+0x08)
	pushw	hl                                   ; FAFCEA  push HL
	call	VoiceQuery_Tag80_Part                              ; FAFCEB  call 0xfb3c5f
	pushw	hl                                   ; FAFCEF  push HL
	call	PartRec_Word0006_SetBit13                              ; FAFCF0  call 0xfacc3f
	pushw	hl                                   ; FAFCF4  push HL
	call	VoiceQuery_Tag00_Part                              ; FAFCF5  call 0xfb3ce0
	ld	xix, xiy                                ; FAFCF9  ld XIX,XIY
	inc	5, xiy                                 ; FAFCFB  inc 5,XIY
	ld	xix, xiy                                ; FAFCFD  ld XIX,XIY
	ld	xbc, 0x10C000                           ; FAFCFF  ld XBC,0x0010c000
	ld	(xiz-8), xbc                            ; FAFD04  ld (XIZ+0xf8),XBC
	inc	2, xbc                                 ; FAFD07  inc 2,XBC
	ld	(xiz-4), xbc                            ; FAFD09  ld (XIZ+0xfc),XBC
	inc	6, xsp                                 ; FAFD0C  inc 6,XSP
MidiCtrl_CC120__FAFD0E:
	ld	h, (xix)                                ; FAFD0E  ld H,(XIX)
	cp	h, 64                                   ; FAFD10  cp H,0x40
	jrl nc, MidiCtrl_CC120__FAFDA0                 ; FAFD13  jrl NC,0xfafda0
	ld	c, 68:opc                                  ; FAFD16  ld C,0x44
	mul8rr	c, h                                ; FAFD18  mul BC,H
	inc	1, bc                                  ; FAFD1A  inc 1,BC
	extz	xbc                                   ; FAFD1C  extz XBC
	ld	wa, (xbc+0x3BCF)                        ; FAFD1E  ld WA,(XBC+0x3bcf)
	and	wa, 60                                 ; FAFD23  and WA,0x003c
	cp	wa, 4:i3                                  ; FAFD27  cp WA,4
	jr z, MidiCtrl_CC120__FAFD3F                   ; FAFD29  jr Z,0xfafd3f
	cp	wa, 8                                   ; FAFD2B  cp WA,0x0008
	jr z, MidiCtrl_CC120__FAFD6E                   ; FAFD2F  jr Z,0xfafd6e
	cp	wa, 16                                  ; FAFD31  cp WA,0x0010
	jr z, MidiCtrl_CC120__FAFD3F                   ; FAFD35  jr Z,0xfafd3f
	cp	wa, 32                                  ; FAFD37  cp WA,0x0020
	jr z, MidiCtrl_CC120__FAFD3F                   ; FAFD3B  jr Z,0xfafd3f
	jr MidiCtrl_CC120__FAFD9B                      ; FAFD3D  jr T,0xfafd9b
MidiCtrl_CC120__FAFD3F:
	ld	c, (xix)                                ; FAFD3F  ld C,(XIX)
	extz	bc                                    ; FAFD41  extz BC
	add	bc, 0x840                              ; FAFD43  add BC,0x0840
	ld	xwa, (xiz-8)                            ; FAFD47  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FAFD4A  ld (XWA),BC
	ld	xbc, (xiz-4)                            ; FAFD4C  ld XBC,(XIZ+0xfc)
	extpfx4 0xB1, 0x02, 0x00, 0xC3             ; FAFD4F  ld (XBC),0xc300
	nop                                        ; FAFD53  nop
	nop                                        ; FAFD54  nop
	nop                                        ; FAFD55  nop
	nop                                        ; FAFD56  nop
	nop                                        ; FAFD57  nop
	ld	c, (xix)                                ; FAFD58  ld C,(XIX)
	extz	bc                                    ; FAFD5A  extz BC
	add	bc, 0x800                              ; FAFD5C  add BC,0x0800
	ld	xwa, (xiz-8)                            ; FAFD60  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FAFD63  ld (XWA),BC
	ld	xbc, (xiz-4)                            ; FAFD65  ld XBC,(XIZ+0xfc)
	extpfx4 0xB1, 0x02, 0x80, 0xC3             ; FAFD68  ld (XBC),0xc380
	jr MidiCtrl_CC120__FAFD9B                      ; FAFD6C  jr T,0xfafd9b
MidiCtrl_CC120__FAFD6E:
	ld	c, h                                    ; FAFD6E  ld C,H
	extz	bc                                    ; FAFD70  extz BC
	add	bc, 0x840                              ; FAFD72  add BC,0x0840
	ld	xwa, (xiz-8)                            ; FAFD76  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FAFD79  ld (XWA),BC
	ld	xbc, (xiz-4)                            ; FAFD7B  ld XBC,(XIZ+0xfc)
	extpfx4 0xB1, 0x02, 0x00, 0xA2             ; FAFD7E  ld (XBC),0xa200
	nop                                        ; FAFD82  nop
	nop                                        ; FAFD83  nop
	nop                                        ; FAFD84  nop
	nop                                        ; FAFD85  nop
	nop                                        ; FAFD86  nop
	ld	c, (xix)                                ; FAFD87  ld C,(XIX)
	extz	bc                                    ; FAFD89  extz BC
	add	bc, 0x800                              ; FAFD8B  add BC,0x0800
	ld	xwa, (xiz-8)                            ; FAFD8F  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FAFD92  ld (XWA),BC
	ld	xbc, (xiz-4)                            ; FAFD94  ld XBC,(XIZ+0xfc)
	extpfx4 0xB1, 0x02, 0x80, 0xA2             ; FAFD97  ld (XBC),0xa280
MidiCtrl_CC120__FAFD9B:
	inc	1, xix                                 ; FAFD9B  inc 1,XIX
	jrl MidiCtrl_CC120__FAFD0E                     ; FAFD9D  jrl T,0xfafd0e
MidiCtrl_CC120__FAFDA0:
	pop	xix                                    ; FAFDA0  pop XIX
	popw	hl                                    ; FAFDA1  pop HL
	unlk32 xiz                                 ; FAFDA2  unlk XIZ
	ret                                        ; FAFDA4  ret
; ============================================================================
; ★★ THE PART RECORD, AND THE CONTROLLERS THAT WRITE IT   (round 7, 2026-08-25)
; ============================================================================
; RAM 0x001523, stride 0x012C = 300 bytes, index 0..0x20 (MidiCtrl_Dispatch and
; MidiNote_Dispatch both refuse >= 0x21).
;
; ⚠ NAME COLLISION, flagged 2026-08-25 (round-1 audit F8); the prom_a name was then
; changed, and this cross-reference is updated to match (round-2 audit, F9).  prom_a
; has an object its own header now calls `RecordPtrs_RAM76A2` -- 35 pointers to
; 64-BYTE records at RAM 0x76A2 on CPU 1, and it was called `PartRecordPtrs` until
; 2026-08-25, when prom_a's lane dropped the word "Part" as unjustified
; (prom_a/wsa1_prom_a.s:119447 carries that history).  THIS IS A DIFFERENT STRUCTURE ON A DIFFERENT PROCESSOR: 300-byte
; records at RAM 0x001523 on CPU 2, reached by multiplication rather than through a
; pointer table.  Nothing in either image ties the two together, and the similar entry
; counts (33 here, 35 there) are not evidence that they are one object.  The word
; "part" here is justified by what writes the record -- a MIDI controller handler
; selected by a per-message channel-like index, below -- and by nothing else.  Every row below is `mul BC,0x012C /
; add BC,<offset> / <store>` inside the named handler -- an instruction, not a
; guess -- and the handler is reached only from the controller number in the
; first column.  All twenty-six (number, handler) pairs are re-extracted from the
; ROM by `python3 notes/prom_c_dev10c_meaning_checks.py` section 1.
;
;   ctrl  handler                     part field  width  what is stored
;   ----  --------------------------  ----------  -----  ------------------------
;      1  MidiCtrl_CC01               --                 (no direct part field)
;      2  MidiCtrl_CC02               --
;      4  MidiCtrl_CC04               --
;      7  MidiCtrl_CC07               +0x0B       word   Voice_CC_VolumeCurve[v]
;     10  MidiCtrl_CC10               +0x0D       byte   v, raw
;     11  MidiCtrl_CC11               +0x0E       word   Voice_CC_VolumeCurve[v]
;     16  MidiCtrl_CC16               --
;     17  MidiCtrl_CC17               --
;     18  MidiCtrl_CC18               --
;     19  MidiCtrl_CC19               --
;     64  MidiCtrl_CC64               +0x09       word   bit 0 set/cleared on v >= 0x40
;     91  MidiCtrl_CC91               +0x10       byte   v, raw
;     93  MidiCtrl_CC93               +0x11       byte   v, raw
;     94  sub_FAFBEC                  --                 (shared: 2 call sites)
;    120  MidiCtrl_CC120              --
;    121  PartRec_ResetToDefaults                  --                 (shared: 5 call sites)
;    123  PartRec_Word0006_SetBit13                  --                 (shared: 4 call sites)
;   0x80  MidiCtrl_Int80              +0x12       byte   v, raw
;   0x81  MidiCtrl_Int81_FineTune     +0x13       word   (v - 0x80) * 2
;   0x82  MidiCtrl_Int82_Transpose    +0x15       byte   v - 0x40, signed
;   0x95  MidiCtrl_Int95              --
;   0x97  MidiCtrl_Int97              +0x16       byte   v, raw
;   0x99  MidiCtrl_Int99              +0x17       byte   v, raw
;   0x9A  MidiCtrl_Int9A              +0x18       byte   v, raw
;   0x9B  MidiCtrl_Int9B              +0x19       byte   v, raw
;   0x9C  MidiCtrl_Int9C              +0x1A       byte   v, raw
;
; ★ SIX OF THESE HANDLERS ARE THE SAME THIRTY BYTES.  MidiCtrl_CC10, CC91, CC93,
; Int97, Int9B and Int9C differ in EXACTLY ONE BYTE each -- the immediate that
; names the part-record offset (0x0D, 0x10, 0x11, 0x16, 0x19, 0x1A).  Stated
; because this tree's rule is to diff the bytes before calling two things twins.
;
; ★ AND FOUR OF THE FIELDS ARE READ BACK ON THE VOICE PATH, which is what makes
; this table load-bearing rather than decorative:
;   +0x0B and +0x0E -> Voice_StageLevel_Reg0080 -> register `chan + 0x0080`
;   +0x13 and +0x15 -> Voice_ComputePitch       -> register `chan + 0x0400`
; and the units of the last two are fixed by the arithmetic on both sides: +0x15
; is added SHIFTED LEFT EIGHT and +0x13 unshifted, so the pitch unit is 1/256 of
; a semitone and controller 0x81's full swing is exactly one semitone.
;
; ⚠ NOT ESTABLISHED: the MIDI standard's names for controllers 1, 2, 4, 10, 16-19,
; 64, 91, 93, 94 (modulation, breath, foot, pan, general purpose 1-4, sustain,
; effect depths).  The NUMBERS are read off `cp BC,imm`; the roles are the MIDI
; specification's, and only 7 (volume) and 120 (all sound off) are corroborated
; inside this firmware, by the literals in MidiMsg_SendBootSequence.
; ============================================================================

; --------------------------------------------------------------------------
; MidiCtrl_Dispatch -- 0xFAFDA5..0xFB0012 (622 bytes)
;
; Called from: 3 site(s) outside this module:
;          0xFB0863 in MidiIn_ParseRingAndDispatch__FB080E, 0xFB0A4B in MidiMsg_SendBootSequence
;          0xFB0A81 in MidiMsg_SendBootSequence
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFACC3F = PartRec_Word0006_SetBit13, 0xFAD6EB = MidiCtrl_CC07
;          0xFAD764 = MidiCtrl_CC10, 0xFAD782 = MidiCtrl_CC11
;          0xFAD7FB = MidiCtrl_CC64, 0xFAD844 = MidiCtrl_CC91
;          0xFAD862 = MidiCtrl_CC93, 0xFAD8C9 = MidiCtrl_Int80
;          0xFAD8F1 = MidiCtrl_Int81_FineTune, 0xFAD91B = MidiCtrl_Int82_Transpose
;          0xFAD987 = MidiCtrl_Int95, 0xFAD9D0 = MidiCtrl_Int97
;          0xFAD9EE = MidiCtrl_Int99, 0xFADA17 = MidiCtrl_Int9A
;          0xFADA40 = MidiCtrl_Int9B, 0xFADA5E = MidiCtrl_Int9C
;          0xFADCC3 = Voice_RestagePitchReg0400_ForList, 0xFADDC8 = Voice_RestageReg0080_ForList
;          0xFADEAC = sub_FADEAC, 0xFAF3CC = MidiCtrl_CC01
;          0xFAF4DD = MidiCtrl_CC02, 0xFAF5EE = MidiCtrl_CC04
;          0xFAF6FC = MidiCtrl_CC16, 0xFAF873 = MidiCtrl_CC17
;          0xFAF9E6 = MidiCtrl_CC18, 0xFAFAE9 = MidiCtrl_CC19
;          0xFAFBEC = sub_FAFBEC, 0xFAFCE1 = MidiCtrl_CC120
;          0xFB3C5F = VoiceQuery_Tag80_Part, 0xFB3C8B = VoiceQuery_Tag40_Part
;          0xFB3CE0 = VoiceQuery_Tag00_Part, 0xFB3E8B = VoiceList_RetireByMode
;          0xFB4D45 = sub_FB4D45, 0xFB6500 = PartRec_ResetToDefaults
; Evidence: the listing below is the byte-identical round-trip of 0xFAFDA5-0xFB0012
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7).  The MIDI-DERIVED CONTROLLER DISPATCHER.  Packet byte [1] is the
;          part index (guard `cp C,0x21` at 0xFAFDB0), byte [2] the controller NUMBER and
;          byte [3] its value.  A chain of `cp BC,imm / jrl Z` selects one of TWENTY-SIX
;          arms; the arm labels below carry the number.
; Evidence: the 26 (number, arm) pairs are extracted from these bytes -- not retyped -- by
;          `python3 notes/prom_c_dev10c_meaning_checks.py` section 1, which walks the
;          `d9 dN` / `d9 cf ll hh` compare forms and the `76 ll hh` branch and asserts the
;          LAST pair (156 -> 0xFB0003).  The seventeen numbers below 0x80 are
;              1 2 4 7 10 11 16 17 18 19 64 91 93 94 120 121 123
;          i.e. modulation, breath, foot, VOLUME, pan, EXPRESSION, general purpose 1-4,
;          sustain, effect depths 1/3/4 and the three channel-mode messages -- the standard
;          MIDI allocation, with no number that is not in it.  Independently,
;          MidiMsg_SendBootSequence hands this same routine `B0 00 07 00` and `B0 00 78 7F`
;          (notes/FINDINGS-prom_c-voice-module.md §2), which is controller 7 = volume and
;          controller 120 = all sound off spelled out in a literal.
;          ⚠ The nine numbers >= 0x80 cannot be MIDI controllers at all; they are this
;          firmware's own extensions and are named `MidiCtrl_IntXX`.
; Unknown:  what any arm DOES beyond the field it writes; see each handler.
; --------------------------------------------------------------------------
MidiCtrl_Dispatch:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAFDA5  link XIZ,0x0000
	push	xix                                   ; FAFDA9  push XIX
	ld	xix, (xiz+8)                            ; FAFDAA  ld XIX,(XIZ+0x08)
	ld	c, (xix+1)                              ; FAFDAD  ld C,(XIX+0x01)
	cp	c, 33                                   ; FAFDB0  cp C,0x21
	jrl nc, MidiCtrl_Dispatch__FB000F                 ; FAFDB3  jrl NC,0xfb000f
	ld	c, (xix+2)                              ; FAFDB6  ld C,(XIX+0x02)
	extz	bc                                    ; FAFDB9  extz BC
	cp	bc, 1:i3                                  ; FAFDBB  cp BC,1
	jrl z, MidiCtrl_Dispatch__FAFE6C                  ; FAFDBD  jrl Z,0xfafe6c
	cp	bc, 2:i3                                  ; FAFDC0  cp BC,2
	jrl z, MidiCtrl_Dispatch__FAFE7A                  ; FAFDC2  jrl Z,0xfafe7a
	cp	bc, 4:i3                                  ; FAFDC5  cp BC,4
	jrl z, MidiCtrl_Dispatch__FAFE88                  ; FAFDC7  jrl Z,0xfafe88
	cp	bc, 7:i3                                  ; FAFDCA  cp BC,7
	jrl z, MidiCtrl_Dispatch__FAFE96                  ; FAFDCC  jrl Z,0xfafe96
	cp	bc, 10                                  ; FAFDCF  cp BC,0x000a
	jrl z, MidiCtrl_Dispatch__FAFEA3                  ; FAFDD3  jrl Z,0xfafea3
	cp	bc, 11                                  ; FAFDD6  cp BC,0x000b
	jrl z, MidiCtrl_Dispatch__FAFEB8                  ; FAFDDA  jrl Z,0xfafeb8
	cp	bc, 16                                  ; FAFDDD  cp BC,0x0010
	jrl z, MidiCtrl_Dispatch__FAFED5                  ; FAFDE1  jrl Z,0xfafed5
	cp	bc, 17                                  ; FAFDE4  cp BC,0x0011
	jrl z, MidiCtrl_Dispatch__FAFEE3                  ; FAFDE8  jrl Z,0xfafee3
	cp	bc, 18                                  ; FAFDEB  cp BC,0x0012
	jrl z, MidiCtrl_Dispatch__FAFEF1                  ; FAFDEF  jrl Z,0xfafef1
	cp	bc, 19                                  ; FAFDF2  cp BC,0x0013
	jrl z, MidiCtrl_Dispatch__FAFEFF                  ; FAFDF6  jrl Z,0xfafeff
	cp	bc, 64                                  ; FAFDF9  cp BC,0x0040
	jrl z, MidiCtrl_Dispatch__FAFF0D                  ; FAFDFD  jrl Z,0xfaff0d
	cp	bc, 91                                  ; FAFE00  cp BC,0x005b
	jrl z, MidiCtrl_Dispatch__FAFF30                  ; FAFE04  jrl Z,0xfaff30
	cp	bc, 93                                  ; FAFE07  cp BC,0x005d
	jrl z, MidiCtrl_Dispatch__FAFF3E                  ; FAFE0B  jrl Z,0xfaff3e
	cp	bc, 94                                  ; FAFE0E  cp BC,0x005e
	jrl z, MidiCtrl_Dispatch__FAFF4C                  ; FAFE12  jrl Z,0xfaff4c
	cp	bc, 0x78                                ; FAFE15  cp BC,0x0078
	jrl z, MidiCtrl_Dispatch__FAFF5A                  ; FAFE19  jrl Z,0xfaff5a
	cp	bc, 0x79                                ; FAFE1C  cp BC,0x0079
	jrl z, MidiCtrl_Dispatch__FAFF63                  ; FAFE20  jrl Z,0xfaff63
	cp	bc, 0x7B                                ; FAFE23  cp BC,0x007b
	jrl z, MidiCtrl_Dispatch__FAFF6F                  ; FAFE27  jrl Z,0xfaff6f
	cp	bc, 0x80                                ; FAFE2A  cp BC,0x0080
	jrl z, MidiCtrl_Dispatch__FAFF89                  ; FAFE2E  jrl Z,0xfaff89
	cp	bc, 0x81                                ; FAFE31  cp BC,0x0081
	jrl z, MidiCtrl_Dispatch__FAFF97                  ; FAFE35  jrl Z,0xfaff97
	cp	bc, 0x82                                ; FAFE38  cp BC,0x0082
	jrl z, MidiCtrl_Dispatch__FAFFB5                  ; FAFE3C  jrl Z,0xfaffb5
	cp	bc, 0x95                                ; FAFE3F  cp BC,0x0095
	jrl z, MidiCtrl_Dispatch__FAFFC2                  ; FAFE43  jrl Z,0xfaffc2
	cp	bc, 0x97                                ; FAFE46  cp BC,0x0097
	jrl z, MidiCtrl_Dispatch__FAFFCF                  ; FAFE4A  jrl Z,0xfaffcf
	cp	bc, 0x99                                ; FAFE4D  cp BC,0x0099
	jrl z, MidiCtrl_Dispatch__FAFFDC                  ; FAFE51  jrl Z,0xfaffdc
	cp	bc, 0x9A                                ; FAFE54  cp BC,0x009a
	jrl z, MidiCtrl_Dispatch__FAFFE9                  ; FAFE58  jrl Z,0xfaffe9
	cp	bc, 0x9B                                ; FAFE5B  cp BC,0x009b
	jrl z, MidiCtrl_Dispatch__FAFFF6                  ; FAFE5F  jrl Z,0xfafff6
	cp	bc, 0x9C                                ; FAFE62  cp BC,0x009c
	jrl z, MidiCtrl_Dispatch__FB0003                  ; FAFE66  jrl Z,0xfb0003
	jrl MidiCtrl_Dispatch__FB000F                     ; FAFE69  jrl T,0xfb000f
MidiCtrl_Dispatch__FAFE6C:                     ; controller 1     -> MidiCtrl_CC01
	ld	c, (xix+3)                              ; FAFE6C  ld C,(XIX+0x03)
	pushw	bc                                   ; FAFE6F  push BC
	ld	c, (xix+1)                              ; FAFE70  ld C,(XIX+0x01)
	pushw	bc                                   ; FAFE73  push BC
	calr MidiCtrl_CC01                 ; FAFE74  calr 0xfaf3cc
	jrl MidiCtrl_Dispatch__FB000E                     ; FAFE77  jrl T,0xfb000e
MidiCtrl_Dispatch__FAFE7A:                     ; controller 2     -> MidiCtrl_CC02
	ld	c, (xix+3)                              ; FAFE7A  ld C,(XIX+0x03)
	pushw	bc                                   ; FAFE7D  push BC
	ld	c, (xix+1)                              ; FAFE7E  ld C,(XIX+0x01)
	pushw	bc                                   ; FAFE81  push BC
	calr MidiCtrl_CC02                 ; FAFE82  calr 0xfaf4dd
	jrl MidiCtrl_Dispatch__FB000E                     ; FAFE85  jrl T,0xfb000e
MidiCtrl_Dispatch__FAFE88:                     ; controller 4     -> MidiCtrl_CC04
	ld	c, (xix+3)                              ; FAFE88  ld C,(XIX+0x03)
	pushw	bc                                   ; FAFE8B  push BC
	ld	c, (xix+1)                              ; FAFE8C  ld C,(XIX+0x01)
	pushw	bc                                   ; FAFE8F  push BC
	calr MidiCtrl_CC04                 ; FAFE90  calr 0xfaf5ee
	jrl MidiCtrl_Dispatch__FB000E                     ; FAFE93  jrl T,0xfb000e
MidiCtrl_Dispatch__FAFE96:                     ; controller 7     -> MidiCtrl_CC07
	ld	c, (xix+3)                              ; FAFE96  ld C,(XIX+0x03)
	pushw	bc                                   ; FAFE99  push BC
	ld	c, (xix+1)                              ; FAFE9A  ld C,(XIX+0x01)
	pushw	bc                                   ; FAFE9D  push BC
	calr MidiCtrl_CC07                 ; FAFE9E  calr 0xfad6eb
	jr MidiCtrl_Dispatch__FAFEC3                      ; FAFEA1  jr T,0xfafec3
MidiCtrl_Dispatch__FAFEA3:                     ; controller 10    -> MidiCtrl_CC10
	ld	c, (xix+3)                              ; FAFEA3  ld C,(XIX+0x03)
	pushw	bc                                   ; FAFEA6  push BC
	ld	c, (xix+1)                              ; FAFEA7  ld C,(XIX+0x01)
	pushw	bc                                   ; FAFEAA  push BC
	calr MidiCtrl_CC10                 ; FAFEAB  calr 0xfad764
	ld	c, (xix+1)                              ; FAFEAE  ld C,(XIX+0x01)
	pushw	bc                                   ; FAFEB1  push BC
	call	sub_FB4D45                              ; FAFEB2  call 0xfb4d45
	jr MidiCtrl_Dispatch__FAFED0                      ; FAFEB6  jr T,0xfafed0
MidiCtrl_Dispatch__FAFEB8:                     ; controller 11    -> MidiCtrl_CC11
	ld	c, (xix+3)                              ; FAFEB8  ld C,(XIX+0x03)
	pushw	bc                                   ; FAFEBB  push BC
	ld	c, (xix+1)                              ; FAFEBC  ld C,(XIX+0x01)
	pushw	bc                                   ; FAFEBF  push BC
	calr MidiCtrl_CC11                 ; FAFEC0  calr 0xfad782
MidiCtrl_Dispatch__FAFEC3:
	pop	xiy                                    ; FAFEC3  pop XIY
	ld	c, (xix+1)                              ; FAFEC4  ld C,(XIX+0x01)
	pushw	bc                                   ; FAFEC7  push BC
	call	VoiceQuery_Tag00_Part                              ; FAFEC8  call 0xfb3ce0
	push	xiy                                   ; FAFECC  push XIY
	calr Voice_RestageReg0080_ForList                 ; FAFECD  calr 0xfaddc8
MidiCtrl_Dispatch__FAFED0:
	inc	6, xsp                                 ; FAFED0  inc 6,XSP
	jrl MidiCtrl_Dispatch__FB000F                     ; FAFED2  jrl T,0xfb000f
MidiCtrl_Dispatch__FAFED5:                     ; controller 16    -> MidiCtrl_CC16
	ld	c, (xix+3)                              ; FAFED5  ld C,(XIX+0x03)
	pushw	bc                                   ; FAFED8  push BC
	ld	c, (xix+1)                              ; FAFED9  ld C,(XIX+0x01)
	pushw	bc                                   ; FAFEDC  push BC
	calr MidiCtrl_CC16                 ; FAFEDD  calr 0xfaf6fc
	jrl MidiCtrl_Dispatch__FB000E                     ; FAFEE0  jrl T,0xfb000e
MidiCtrl_Dispatch__FAFEE3:                     ; controller 17    -> MidiCtrl_CC17
	ld	c, (xix+3)                              ; FAFEE3  ld C,(XIX+0x03)
	pushw	bc                                   ; FAFEE6  push BC
	ld	c, (xix+1)                              ; FAFEE7  ld C,(XIX+0x01)
	pushw	bc                                   ; FAFEEA  push BC
	calr MidiCtrl_CC17                 ; FAFEEB  calr 0xfaf873
	jrl MidiCtrl_Dispatch__FB000E                     ; FAFEEE  jrl T,0xfb000e
MidiCtrl_Dispatch__FAFEF1:                     ; controller 18    -> MidiCtrl_CC18
	ld	c, (xix+3)                              ; FAFEF1  ld C,(XIX+0x03)
	pushw	bc                                   ; FAFEF4  push BC
	ld	c, (xix+1)                              ; FAFEF5  ld C,(XIX+0x01)
	pushw	bc                                   ; FAFEF8  push BC
	calr MidiCtrl_CC18                 ; FAFEF9  calr 0xfaf9e6
	jrl MidiCtrl_Dispatch__FB000E                     ; FAFEFC  jrl T,0xfb000e
MidiCtrl_Dispatch__FAFEFF:                     ; controller 19    -> MidiCtrl_CC19
	ld	c, (xix+3)                              ; FAFEFF  ld C,(XIX+0x03)
	pushw	bc                                   ; FAFF02  push BC
	ld	c, (xix+1)                              ; FAFF03  ld C,(XIX+0x01)
	pushw	bc                                   ; FAFF06  push BC
	calr MidiCtrl_CC19                 ; FAFF07  calr 0xfafae9
	jrl MidiCtrl_Dispatch__FB000E                     ; FAFF0A  jrl T,0xfb000e
MidiCtrl_Dispatch__FAFF0D:                     ; controller 64    -> MidiCtrl_CC64
	ld	c, (xix+3)                              ; FAFF0D  ld C,(XIX+0x03)
	pushw	bc                                   ; FAFF10  push BC
	ld	c, (xix+1)                              ; FAFF11  ld C,(XIX+0x01)
	pushw	bc                                   ; FAFF14  push BC
	calr MidiCtrl_CC64                 ; FAFF15  calr 0xfad7fb
	ld	c, (xix+1)                              ; FAFF18  ld C,(XIX+0x01)
	pushw	bc                                   ; FAFF1B  push BC
	call	VoiceQuery_Tag40_Part                              ; FAFF1C  call 0xfb3c8b
	ld	xix, xiy                                ; FAFF20  ld XIX,XIY
	pushw	2                                    ; FAFF22  push 0x0002
	push	xiy                                   ; FAFF25  push XIY
	calr sub_FADEAC                 ; FAFF26  calr 0xfadeac
	inc	8, xsp                                 ; FAFF29  inc 0,XSP
	inc	4, xsp                                 ; FAFF2B  inc 4,XSP
	jrl MidiCtrl_Dispatch__FB000F                     ; FAFF2D  jrl T,0xfb000f
MidiCtrl_Dispatch__FAFF30:                     ; controller 91    -> MidiCtrl_CC91
	ld	c, (xix+3)                              ; FAFF30  ld C,(XIX+0x03)
	pushw	bc                                   ; FAFF33  push BC
	ld	c, (xix+1)                              ; FAFF34  ld C,(XIX+0x01)
	pushw	bc                                   ; FAFF37  push BC
	calr MidiCtrl_CC91                 ; FAFF38  calr 0xfad844
	jrl MidiCtrl_Dispatch__FB000E                     ; FAFF3B  jrl T,0xfb000e
MidiCtrl_Dispatch__FAFF3E:                     ; controller 93    -> MidiCtrl_CC93
	ld	c, (xix+3)                              ; FAFF3E  ld C,(XIX+0x03)
	pushw	bc                                   ; FAFF41  push BC
	ld	c, (xix+1)                              ; FAFF42  ld C,(XIX+0x01)
	pushw	bc                                   ; FAFF45  push BC
	calr MidiCtrl_CC93                 ; FAFF46  calr 0xfad862
	jrl MidiCtrl_Dispatch__FB000E                     ; FAFF49  jrl T,0xfb000e
MidiCtrl_Dispatch__FAFF4C:                     ; controller 94    -> sub_FAFBEC (shared)
	ld	c, (xix+3)                              ; FAFF4C  ld C,(XIX+0x03)
	pushw	bc                                   ; FAFF4F  push BC
	ld	c, (xix+1)                              ; FAFF50  ld C,(XIX+0x01)
	pushw	bc                                   ; FAFF53  push BC
	calr sub_FAFBEC                 ; FAFF54  calr 0xfafbec
	jrl MidiCtrl_Dispatch__FB000E                     ; FAFF57  jrl T,0xfb000e
MidiCtrl_Dispatch__FAFF5A:                     ; controller 120   -> MidiCtrl_CC120
	ld	c, (xix+1)                              ; FAFF5A  ld C,(XIX+0x01)
	pushw	bc                                   ; FAFF5D  push BC
	calr MidiCtrl_CC120                 ; FAFF5E  calr 0xfafce1
	jr MidiCtrl_Dispatch__FAFF6B                      ; FAFF61  jr T,0xfaff6b
MidiCtrl_Dispatch__FAFF63:                     ; controller 121   -> PartRec_ResetToDefaults (shared)
	ld	c, (xix+1)                              ; FAFF63  ld C,(XIX+0x01)
	pushw	bc                                   ; FAFF66  push BC
	call	PartRec_ResetToDefaults                              ; FAFF67  call 0xfb6500
MidiCtrl_Dispatch__FAFF6B:
	popw	bc                                    ; FAFF6B  pop BC
	jrl MidiCtrl_Dispatch__FB000F                     ; FAFF6C  jrl T,0xfb000f
MidiCtrl_Dispatch__FAFF6F:                     ; controller 123   -> PartRec_Word0006_SetBit13 (shared)
	ld	c, (xix+1)                              ; FAFF6F  ld C,(XIX+0x01)
	pushw	bc                                   ; FAFF72  push BC
	call	PartRec_Word0006_SetBit13                              ; FAFF73  call 0xfacc3f
	ld	c, (xix+1)                              ; FAFF77  ld C,(XIX+0x01)
	pushw	bc                                   ; FAFF7A  push BC
	call	VoiceQuery_Tag80_Part                              ; FAFF7B  call 0xfb3c5f
	push	xiy                                   ; FAFF7F  push XIY
	call	VoiceList_RetireByMode                              ; FAFF80  call 0xfb3e8b
	inc	8, xsp                                 ; FAFF84  inc 0,XSP
	jrl MidiCtrl_Dispatch__FB000F                     ; FAFF86  jrl T,0xfb000f
MidiCtrl_Dispatch__FAFF89:                     ; controller 0x80  -> MidiCtrl_Int80
	ld	c, (xix+3)                              ; FAFF89  ld C,(XIX+0x03)
	pushw	bc                                   ; FAFF8C  push BC
	ld	c, (xix+1)                              ; FAFF8D  ld C,(XIX+0x01)
	pushw	bc                                   ; FAFF90  push BC
	calr MidiCtrl_Int80                 ; FAFF91  calr 0xfad8c9
	jrl MidiCtrl_Dispatch__FB000E                     ; FAFF94  jrl T,0xfb000e
MidiCtrl_Dispatch__FAFF97:                     ; controller 0x81  -> MidiCtrl_Int81_FineTune
	ld	c, (xix+3)                              ; FAFF97  ld C,(XIX+0x03)
	pushw	bc                                   ; FAFF9A  push BC
	ld	c, (xix+1)                              ; FAFF9B  ld C,(XIX+0x01)
	pushw	bc                                   ; FAFF9E  push BC
	calr MidiCtrl_Int81_FineTune                 ; FAFF9F  calr 0xfad8f1
	ld	c, (xix+1)                              ; FAFFA2  ld C,(XIX+0x01)
	pushw	bc                                   ; FAFFA5  push BC
	call	VoiceQuery_Tag00_Part                              ; FAFFA6  call 0xfb3ce0
	push	xiy                                   ; FAFFAA  push XIY
	calr Voice_RestagePitchReg0400_ForList                 ; FAFFAB  calr 0xfadcc3
	inc	8, xsp                                 ; FAFFAE  inc 0,XSP
	inc	2, xsp                                 ; FAFFB0  inc 2,XSP
	jrl MidiCtrl_Dispatch__FB000F                     ; FAFFB2  jrl T,0xfb000f
MidiCtrl_Dispatch__FAFFB5:                     ; controller 0x82  -> MidiCtrl_Int82_Transpose
	ld	c, (xix+3)                              ; FAFFB5  ld C,(XIX+0x03)
	pushw	bc                                   ; FAFFB8  push BC
	ld	c, (xix+1)                              ; FAFFB9  ld C,(XIX+0x01)
	pushw	bc                                   ; FAFFBC  push BC
	calr MidiCtrl_Int82_Transpose                 ; FAFFBD  calr 0xfad91b
	jr MidiCtrl_Dispatch__FB000E                      ; FAFFC0  jr T,0xfb000e
MidiCtrl_Dispatch__FAFFC2:                     ; controller 0x95  -> MidiCtrl_Int95
	ld	c, (xix+3)                              ; FAFFC2  ld C,(XIX+0x03)
	pushw	bc                                   ; FAFFC5  push BC
	ld	c, (xix+1)                              ; FAFFC6  ld C,(XIX+0x01)
	pushw	bc                                   ; FAFFC9  push BC
	calr MidiCtrl_Int95                 ; FAFFCA  calr 0xfad987
	jr MidiCtrl_Dispatch__FB000E                      ; FAFFCD  jr T,0xfb000e
MidiCtrl_Dispatch__FAFFCF:                     ; controller 0x97  -> MidiCtrl_Int97
	ld	c, (xix+3)                              ; FAFFCF  ld C,(XIX+0x03)
	pushw	bc                                   ; FAFFD2  push BC
	ld	c, (xix+1)                              ; FAFFD3  ld C,(XIX+0x01)
	pushw	bc                                   ; FAFFD6  push BC
	calr MidiCtrl_Int97                 ; FAFFD7  calr 0xfad9d0
	jr MidiCtrl_Dispatch__FB000E                      ; FAFFDA  jr T,0xfb000e
MidiCtrl_Dispatch__FAFFDC:                     ; controller 0x99  -> MidiCtrl_Int99
	ld	c, (xix+3)                              ; FAFFDC  ld C,(XIX+0x03)
	pushw	bc                                   ; FAFFDF  push BC
	ld	c, (xix+1)                              ; FAFFE0  ld C,(XIX+0x01)
	pushw	bc                                   ; FAFFE3  push BC
	calr MidiCtrl_Int99                 ; FAFFE4  calr 0xfad9ee
	jr MidiCtrl_Dispatch__FB000E                      ; FAFFE7  jr T,0xfb000e
MidiCtrl_Dispatch__FAFFE9:                     ; controller 0x9A  -> MidiCtrl_Int9A
	ld	c, (xix+3)                              ; FAFFE9  ld C,(XIX+0x03)
	pushw	bc                                   ; FAFFEC  push BC
	ld	c, (xix+1)                              ; FAFFED  ld C,(XIX+0x01)
	pushw	bc                                   ; FAFFF0  push BC
	calr MidiCtrl_Int9A                 ; FAFFF1  calr 0xfada17
	jr MidiCtrl_Dispatch__FB000E                      ; FAFFF4  jr T,0xfb000e
MidiCtrl_Dispatch__FAFFF6:                     ; controller 0x9B  -> MidiCtrl_Int9B
	ld	c, (xix+3)                              ; FAFFF6  ld C,(XIX+0x03)
	pushw	bc                                   ; FAFFF9  push BC
	ld	c, (xix+1)                              ; FAFFFA  ld C,(XIX+0x01)
	pushw	bc                                   ; FAFFFD  push BC
	calr MidiCtrl_Int9B                 ; FAFFFE  calr 0xfada40
	jr MidiCtrl_Dispatch__FB000E                      ; FB0001  jr T,0xfb000e
MidiCtrl_Dispatch__FB0003:                     ; controller 0x9C  -> MidiCtrl_Int9C
	ld	c, (xix+3)                              ; FB0003  ld C,(XIX+0x03)
	pushw	bc                                   ; FB0006  push BC
	ld	c, (xix+1)                              ; FB0007  ld C,(XIX+0x01)
	pushw	bc                                   ; FB000A  push BC
	calr MidiCtrl_Int9C                 ; FB000B  calr 0xfada5e
MidiCtrl_Dispatch__FB000E:
	pop	xiy                                    ; FB000E  pop XIY
MidiCtrl_Dispatch__FB000F:
	pop	xix                                    ; FB000F  pop XIX
	unlk32 xiz                                 ; FB0010  unlk XIZ
	ret                                        ; FB0012  ret
; --------------------------------------------------------------------------
; sub_FB0013 -- 0xFB0013..0xFB0131 (287 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFB092F in MidiIn_ParseRingAndDispatch__FB08DA
; Inputs:  frame `link XIZ,-14`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFAF031 = Voice_ApplyParamChange_Dispatch, 0xFAF340 = PartRec_ResetSlotValues_ByTag
; Evidence: the listing below is the byte-identical round-trip of 0xFB0013-0xFB0131
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB0013:
	link32 0xEE, 0x0C, 0xF2, 0xFF              ; FB0013  link XIZ,0xfff2
	pushw	hl                                   ; FB0017  push HL
	pushw	de                                   ; FB0018  push DE
	push	xix                                   ; FB0019  push XIX
	ld	xbc, (xiz+8)                            ; FB001A  ld XBC,(XIZ+0x08)
	ld	h, (xbc+1)                              ; FB001D  ld H,(XBC+0x01)
	cp	h, 33                                   ; FB0020  cp H,0x21
	jrl nc, sub_FB0013__FB012C                 ; FB0023  jrl NC,0xfb012c
	ld	l, h                                    ; FB0026  ld L,H
	ld	a, h                                    ; FB0028  ld A,H
	extz	wa                                    ; FB002A  extz WA
	mul	wa, 0x12C                              ; FB002C  mul WA,0x012c
	extz	xwa                                   ; FB0030  extz XWA
	ld	xiy, (xwa+0x1523)                       ; FB0032  ld XIY,(XWA+0x1523)
	ld	(xiz-8), xiy                            ; FB0037  ld (XIZ+0xf8),XIY
	ld	a, (xiy+16)                             ; FB003A  ld A,(XIY+0x10)
	and	a, 0xC0                                ; FB003D  and A,0xc0
	extz	wa                                    ; FB0040  extz WA
	cp	wa, 0:i3                                  ; FB0042  cp WA,0
	jr z, sub_FB0013__FB005C                   ; FB0044  jr Z,0xfb005c
	cp	wa, 64                                  ; FB0046  cp WA,0x0040
	jr z, sub_FB0013__FB005C                   ; FB004A  jr Z,0xfb005c
	cp	wa, 0x80                                ; FB004C  cp WA,0x0080
	jrl z, sub_FB0013__FB00CB                  ; FB0050  jrl Z,0xfb00cb
	cp	wa, 0xC0                                ; FB0053  cp WA,0x00c0
	jr z, sub_FB0013__FB005C                   ; FB0057  jr Z,0xfb005c
	jrl sub_FB0013__FB012C                     ; FB0059  jrl T,0xfb012c
sub_FB0013__FB005C:
	ld	c, l                                    ; FB005C  ld C,L
	extz	bc                                    ; FB005E  extz BC
	mul	bc, 0x12C                              ; FB0060  mul BC,0x012c
	extz	xbc                                   ; FB0064  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB0066  ld XWA,(XBC+0x1523)
	ld	xix, xwa                                ; FB006B  ld XIX,XWA
	add	xwa, 49                                ; FB006D  add XWA,0x00000031
	ld	(xiz-4), xwa                            ; FB0073  ld (XIZ+0xfc),XWA
	ldw	de, 0                                  ; FB0076  ld DE,0x0000
	ld	h, 2:opc                                   ; FB0079  ld H,0x02
sub_FB0013__FB007B:
	ld	(xiz-10), de                            ; FB007B  ld (XIZ+0xf6),DE
	ld	bc, (xiz-10)                            ; FB007E  ld BC,(XIZ+0xf6)
	extz	xbc                                   ; FB0081  extz XBC
	ld	(xiz-14), xbc                           ; FB0083  ld (XIZ+0xf2),XBC
	add	xbc, 43                                ; FB0086  add XBC,0x0000002b
	add	xbc, xix                               ; FB008C  add XBC,XIX
	push	xbc                                   ; FB008E  push XBC
	ld	xbc, (xiz+8)                            ; FB008F  ld XBC,(XIZ+0x08)
	ld	a, (xbc+3)                              ; FB0092  ld A,(XBC+0x03)
	extz	wa                                    ; FB0095  extz WA
	pushw	wa                                   ; FB0097  push WA
	pushw	hl                                   ; FB0098  push HL
	calr Voice_ApplyParamChange_Dispatch                 ; FB0099  calr 0xfaf031
	ld	xbc, (xiz-4)                            ; FB009C  ld XBC,(XIZ+0xfc)
	push	xbc                                   ; FB009F  push XBC
	ld	xwa, (xiz-14)                           ; FB00A0  ld XWA,(XIZ+0xf2)
	add	xwa, 44                                ; FB00A3  add XWA,0x0000002c
	add	xwa, xix                               ; FB00A9  add XWA,XIX
	ld	c, (xwa)                                ; FB00AB  ld C,(XWA)
	and	c, 63                                  ; FB00AD  and C,0x3f
	pushw	bc                                   ; FB00B0  push BC
	pushw	0xFF                                 ; FB00B1  push 0x00ff
	pushw	hl                                   ; FB00B4  push HL
	calr PartRec_ResetSlotValues_ByTag                 ; FB00B5  calr 0xfaf340
	ld	de, (xiz-10)                            ; FB00B8  ld DE,(XIZ+0xf6)
	inc	3, de                                  ; FB00BB  inc 3,DE
	dec	1, h                                   ; FB00BD  dec 1,H
	add	xsp, 18                                ; FB00BF  add XSP,0x00000012
	cp	h, 0:i3                                   ; FB00C5  cp H,0
	jr nz, sub_FB0013__FB007B                  ; FB00C7  jr NZ,0xfb007b
	jr sub_FB0013__FB012C                      ; FB00C9  jr T,0xfb012c
sub_FB0013__FB00CB:
	ld	xix, (xiz-8)                            ; FB00CB  ld XIX,(XIZ+0xf8)
	ld	xbc, xix                                ; FB00CE  ld XBC,XIX
	add	xbc, 46                                ; FB00D0  add XBC,0x0000002e
	ld	(xiz-4), xbc                            ; FB00D6  ld (XIZ+0xfc),XBC
	ldw	de, 0                                  ; FB00D9  ld DE,0x0000
	ld	h, 2:opc                                   ; FB00DC  ld H,0x02
sub_FB0013__FB00DE:
	ld	(xiz-10), de                            ; FB00DE  ld (XIZ+0xf6),DE
	ld	bc, (xiz-10)                            ; FB00E1  ld BC,(XIZ+0xf6)
	extz	xbc                                   ; FB00E4  extz XBC
	ld	(xiz-14), xbc                           ; FB00E6  ld (XIZ+0xf2),XBC
	add	xbc, 40                                ; FB00E9  add XBC,0x00000028
	add	xbc, xix                               ; FB00EF  add XBC,XIX
	push	xbc                                   ; FB00F1  push XBC
	ld	xbc, (xiz+8)                            ; FB00F2  ld XBC,(XIZ+0x08)
	ld	a, (xbc+3)                              ; FB00F5  ld A,(XBC+0x03)
	extz	wa                                    ; FB00F8  extz WA
	pushw	wa                                   ; FB00FA  push WA
	pushw	hl                                   ; FB00FB  push HL
	calr Voice_ApplyParamChange_Dispatch                 ; FB00FC  calr 0xfaf031
	ld	xbc, (xiz-4)                            ; FB00FF  ld XBC,(XIZ+0xfc)
	push	xbc                                   ; FB0102  push XBC
	ld	xwa, (xiz-14)                           ; FB0103  ld XWA,(XIZ+0xf2)
	add	xwa, 41                                ; FB0106  add XWA,0x00000029
	add	xwa, xix                               ; FB010C  add XWA,XIX
	ld	c, (xwa)                                ; FB010E  ld C,(XWA)
	and	c, 63                                  ; FB0110  and C,0x3f
	pushw	bc                                   ; FB0113  push BC
	pushw	0xFF                                 ; FB0114  push 0x00ff
	pushw	hl                                   ; FB0117  push HL
	calr PartRec_ResetSlotValues_ByTag                 ; FB0118  calr 0xfaf340
	ld	de, (xiz-10)                            ; FB011B  ld DE,(XIZ+0xf6)
	inc	3, de                                  ; FB011E  inc 3,DE
	dec	1, h                                   ; FB0120  dec 1,H
	add	xsp, 18                                ; FB0122  add XSP,0x00000012
	cp	h, 0:i3                                   ; FB0128  cp H,0
	jr nz, sub_FB0013__FB00DE                  ; FB012A  jr NZ,0xfb00de
sub_FB0013__FB012C:
	pop	xix                                    ; FB012C  pop XIX
	popw	de                                    ; FB012D  pop DE
	popw	hl                                    ; FB012E  pop HL
	unlk32 xiz                                 ; FB012F  unlk XIZ
	ret                                        ; FB0131  ret
; --------------------------------------------------------------------------
; sub_FB0132 -- 0xFB0132..0xFB01FF (206 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFB098B in MidiIn_ParseRingAndDispatch__FB0936
; Inputs:  frame `link XIZ,-2`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFAF031 = Voice_ApplyParamChange_Dispatch, 0xFAF340 = PartRec_ResetSlotValues_ByTag
; Evidence: the listing below is the byte-identical round-trip of 0xFB0132-0xFB01FF
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB0132:
	link32 0xEE, 0x0C, 0xFE, 0xFF              ; FB0132  link XIZ,0xfffe
	pushw	hl                                   ; FB0136  push HL
	pushw	de                                   ; FB0137  push DE
	push	xix                                   ; FB0138  push XIX
	ld	xbc, (xiz+8)                            ; FB0139  ld XBC,(XIZ+0x08)
	ld	h, (xbc+1)                              ; FB013C  ld H,(XBC+0x01)
	cp	h, 33                                   ; FB013F  cp H,0x21
	jrl nc, sub_FB0132__FB01FA                 ; FB0142  jrl NC,0xfb01fa
	ld	d, h                                    ; FB0145  ld D,H
	ld	a, (xbc+3)                              ; FB0147  ld A,(XBC+0x03)
	extz	wa                                    ; FB014A  extz WA
	sll	wa, 7                                  ; FB014C  sll 0x07,WA
	ld	(xiz-2), wa                             ; FB014F  ld (XIZ+0xfe),WA
	ld	a, (xbc+2)                              ; FB0152  ld A,(XBC+0x02)
	extz	wa                                    ; FB0155  extz WA
	ld	hl, wa                                  ; FB0157  ld HL,WA
	extpfx3 0x9E, 0xFE, 0xE0                   ; FB0159  or WA,(XIZ+0xfe)
	ld	hl, wa                                  ; FB015C  ld HL,WA
	set	15, wa                                 ; FB015E  set 0x0f,WA
	ld	hl, wa                                  ; FB0161  ld HL,WA
	extpfx3 0xC7, 0xF4, 0x9C                   ; FB0163  ld IYL,D
	extz	iy                                    ; FB0166  extz IY
	mul	iy, 0x12C                              ; FB0168  mul IY,0x012c
	extz	xiy                                   ; FB016C  extz XIY
	ld	xbc, (xiy+0x1523)                       ; FB016E  ld XBC,(XIY+0x1523)
	ld	xix, xbc                                ; FB0173  ld XIX,XBC
	ld	a, (xbc+16)                             ; FB0175  ld A,(XBC+0x10)
	and	a, 0xC0                                ; FB0178  and A,0xc0
	extz	wa                                    ; FB017B  extz WA
	cp	wa, 0:i3                                  ; FB017D  cp WA,0
	jr z, sub_FB0132__FB0195                   ; FB017F  jr Z,0xfb0195
	cp	wa, 64                                  ; FB0181  cp WA,0x0040
	jr z, sub_FB0132__FB0195                   ; FB0185  jr Z,0xfb0195
	cp	wa, 0x80                                ; FB0187  cp WA,0x0080
	jr z, sub_FB0132__FB01C9                   ; FB018B  jr Z,0xfb01c9
	cp	wa, 0xC0                                ; FB018D  cp WA,0x00c0
	jr z, sub_FB0132__FB0195                   ; FB0191  jr Z,0xfb0195
	jr sub_FB0132__FB01FA                      ; FB0193  jr T,0xfb01fa
sub_FB0132__FB0195:
	ld	c, d                                    ; FB0195  ld C,D
	extz	bc                                    ; FB0197  extz BC
	mul	bc, 0x12C                              ; FB0199  mul BC,0x012c
	extz	xbc                                   ; FB019D  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB019F  ld XWA,(XBC+0x1523)
	ld	xix, xwa                                ; FB01A4  ld XIX,XWA
	add	xwa, 20                                ; FB01A6  add XWA,0x00000014
	push	xwa                                   ; FB01AC  push XWA
	pushw	hl                                   ; FB01AD  push HL
	push	0                                     ; FB01AE  push 0x00
	push	d                                     ; FB01B0  push D
	calr Voice_ApplyParamChange_Dispatch                 ; FB01B2  calr 0xfaf031
	ld	xbc, xix                                ; FB01B5  ld XBC,XIX
	add	xbc, 49                                ; FB01B7  add XBC,0x00000031
	inc	8, xsp                                 ; FB01BD  inc 0,XSP
	push	xbc                                   ; FB01BF  push XBC
	ld	c, (xix+21)                             ; FB01C0  ld C,(XIX+0x15)
	and	c, 63                                  ; FB01C3  and C,0x3f
	pushw	bc                                   ; FB01C6  push BC
	jr sub_FB0132__FB01EC                      ; FB01C7  jr T,0xfb01ec
sub_FB0132__FB01C9:
	ld	xbc, xix                                ; FB01C9  ld XBC,XIX
	add	xbc, 17                                ; FB01CB  add XBC,0x00000011
	push	xbc                                   ; FB01D1  push XBC
	pushw	hl                                   ; FB01D2  push HL
	push	0                                     ; FB01D3  push 0x00
	push	d                                     ; FB01D5  push D
	calr Voice_ApplyParamChange_Dispatch                 ; FB01D7  calr 0xfaf031
	ld	xbc, xix                                ; FB01DA  ld XBC,XIX
	add	xbc, 46                                ; FB01DC  add XBC,0x0000002e
	inc	8, xsp                                 ; FB01E2  inc 0,XSP
	push	xbc                                   ; FB01E4  push XBC
	ld	c, (xix+18)                             ; FB01E5  ld C,(XIX+0x12)
	and	c, 63                                  ; FB01E8  and C,0x3f
	pushw	bc                                   ; FB01EB  push BC
sub_FB0132__FB01EC:
	pushw	0xFF                                 ; FB01EC  push 0x00ff
	push	0                                     ; FB01EF  push 0x00
	push	d                                     ; FB01F1  push D
	calr PartRec_ResetSlotValues_ByTag                 ; FB01F3  calr 0xfaf340
	inc	8, xsp                                 ; FB01F6  inc 0,XSP
	inc	2, xsp                                 ; FB01F8  inc 2,XSP
sub_FB0132__FB01FA:
	pop	xix                                    ; FB01FA  pop XIX
	popw	de                                    ; FB01FB  pop DE
	popw	hl                                    ; FB01FC  pop HL
	unlk32 xiz                                 ; FB01FD  unlk XIZ
	ret                                        ; FB01FF  ret
; --------------------------------------------------------------------------
; Dev10C_QuiesceListedChans_0800_0840 -- 0xFB0200..0xFB026B (108 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFB046F
; Inputs:  frame `link XIZ,-8`; no positive frame slot is read
; Outputs: no absolute-addressed write.
; Calls:   0xFB3D09 = VoiceQuery_Tag00_All, 0xFB6500 = PartRec_ResetToDefaults
; Evidence: the listing below is the byte-identical round-trip of 0xFB0200-0xFB026B
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7); ⚠ RE-NAMED 2026-08-25 (round-1 audit F9).  It used to be called
;          `Dev10C_ClearVoiceList_0800_0840`, which reads as "it clears the voice list".
;          IT DOES NOT: the list is only walked, never written.  What it clears -- if
;          0xFF80/0xFF00 is a clear at all, which is NOT asserted -- is two REGISTERS per
;          listed channel.  Walks a one-byte-per-voice list until the first entry >= 0x40
;          (`ld H,(XIX) / cp H,0x40` at 0xFB022F) and, for each channel in it, writes
;          0x0010C000 register `chan + 0x0840` = 0xFF00 and `chan + 0x0800` = 0xFF80.
; Evidence: the two register constants and the two data words at 0xFB023A and 0xFB0253,
;          with the five `nop`s of bus padding between them.
;          ★ These are EXACTLY the two values Dev10C_ResetAllChannels writes to the same two
;          blocks for all 64 channels at power-on (0xFB811E and 0xFB8132), so 0xFF80/0xFF00
;          in blocks 0x20 and 0x21 is this device's QUIESCENT state for a channel.
;          notes/prom_c_dev10c_meaning_checks.py section 12.
; Unknown:  what the two registers hold.  "Silence" fits the two uses and is NOT asserted:
;          nothing here reads either register back or ties it to an audible effect.
; --------------------------------------------------------------------------
Dev10C_QuiesceListedChans_0800_0840:
	link32 0xEE, 0x0C, 0xF8, 0xFF              ; FB0200  link XIZ,0xfff8
	pushw	hl                                   ; FB0204  push HL
	push	xix                                   ; FB0205  push XIX
	ld	h, 0:opc                                   ; FB0206  ld H,0x00
Dev10C_QuiesceListedChans_0800_0840__FB0208:
	push	0                                     ; FB0208  push 0x00
	push	h                                     ; FB020A  push H
	call	PartRec_ResetToDefaults                              ; FB020C  call 0xfb6500
	inc	1, h                                   ; FB0210  inc 1,H
	popw	bc                                    ; FB0212  pop BC
	cp	h, 33                                   ; FB0213  cp H,0x21
	jr c, Dev10C_QuiesceListedChans_0800_0840__FB0208                   ; FB0216  jr C,0xfb0208
	call	VoiceQuery_Tag00_All                              ; FB0218  call 0xfb3d09
	ld	xix, xiy                                ; FB021C  ld XIX,XIY
	inc	5, xiy                                 ; FB021E  inc 5,XIY
	ld	xix, xiy                                ; FB0220  ld XIX,XIY
	ld	xbc, 0x10C000                           ; FB0222  ld XBC,0x0010c000
	ld	(xiz-8), xbc                            ; FB0227  ld (XIZ+0xf8),XBC
	inc	2, xbc                                 ; FB022A  inc 2,XBC
	ld	(xiz-4), xbc                            ; FB022C  ld (XIZ+0xfc),XBC
Dev10C_QuiesceListedChans_0800_0840__FB022F:
	ld	h, (xix)                                ; FB022F  ld H,(XIX)
	cp	h, 64                                   ; FB0231  cp H,0x40
	jr nc, Dev10C_QuiesceListedChans_0800_0840__FB0267                  ; FB0234  jr NC,0xfb0267
	ld	c, h                                    ; FB0236  ld C,H
	extz	bc                                    ; FB0238  extz BC
	add	bc, 0x840                              ; FB023A  add BC,0x0840
	ld	xwa, (xiz-8)                            ; FB023E  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB0241  ld (XWA),BC
	ld	xbc, (xiz-4)                            ; FB0243  ld XBC,(XIZ+0xfc)
	extpfx4 0xB1, 0x02, 0x00, 0xFF             ; FB0246  ld (XBC),0xff00
	nop                                        ; FB024A  nop
	nop                                        ; FB024B  nop
	nop                                        ; FB024C  nop
	nop                                        ; FB024D  nop
	nop                                        ; FB024E  nop
	ld	c, (xix)                                ; FB024F  ld C,(XIX)
	extz	bc                                    ; FB0251  extz BC
	add	bc, 0x800                              ; FB0253  add BC,0x0800
	ld	xwa, (xiz-8)                            ; FB0257  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB025A  ld (XWA),BC
	ld	xbc, (xiz-4)                            ; FB025C  ld XBC,(XIZ+0xfc)
	extpfx4 0xB1, 0x02, 0x80, 0xFF             ; FB025F  ld (XBC),0xff80
	inc	1, xix                                 ; FB0263  inc 1,XIX
	jr Dev10C_QuiesceListedChans_0800_0840__FB022F                      ; FB0265  jr T,0xfb022f
Dev10C_QuiesceListedChans_0800_0840__FB0267:
	pop	xix                                    ; FB0267  pop XIX
	popw	hl                                    ; FB0268  pop HL
	unlk32 xiz                                 ; FB0269  unlk XIZ
	ret                                        ; FB026B  ret
; --------------------------------------------------------------------------
; GlobalTune_SetFineTune_AndRestageAll -- 0xFB026C..0xFB0284 (25 bytes)
;             store the master fine tune, then re-send the pitch register of every
;             voice the query returns.   (* NAMED in wave 7 round 3; was `sub_FB026C`.)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFB0427
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFADAE7 = GlobalTune_StoreFineTune, 0xFADCC3 = Voice_RestagePitchReg0400_ForList
;          0xFB3D09 = VoiceQuery_Tag00_All
; Evidence: the listing below is the byte-identical round-trip of 0xFB026C-0xFB0284
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Name:    three calls in order (0xFB0275, 0xFB0278, 0xFB027D): store the new master
;          fine tune, ask VoiceQuery_Tag00_All for the list of voices, then hand that
;          list to Voice_RestagePitchReg0400_ForList.  Its one reference is arm 0x82 of
;          GlobalSetup_Dispatch, at 0xFB0427.
; Evidence: `push 0x00 / push (XIZ+0x08)` at 0xFB0270-0xFB0272 is the two-word argument
;          GlobalTune_StoreFineTune reads at (XIZ+0x08); `push XIY` at 0xFB027C forwards
;          the query's result register.  So the value takes effect on notes ALREADY
;          SOUNDING, not only on the next one -- which is why the arm is not just the
;          store.
; Unknown:  what tag 0x00 selects in VoiceQuery_Tag00_All.
; --------------------------------------------------------------------------
GlobalTune_SetFineTune_AndRestageAll:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB026C  link XIZ,0x0000
	push	0                                     ; FB0270  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB0272  push (XIZ+0x08)
	calr GlobalTune_StoreFineTune                 ; FB0275  calr 0xfadae7
	call	VoiceQuery_Tag00_All                              ; FB0278  call 0xfb3d09
	push	xiy                                   ; FB027C  push XIY
	calr Voice_RestagePitchReg0400_ForList                 ; FB027D  calr 0xfadcc3
	inc	6, xsp                                 ; FB0280  inc 6,XSP
	unlk32 xiz                                 ; FB0282  unlk XIZ
	ret                                        ; FB0284  ret
; --------------------------------------------------------------------------
; sub_FB0285 -- 0xFB0285..0xFB029D (25 bytes)
;
; Called from: no site outside this module.
;          ⚠ NOT FOUND -- no literal call/calr/jp reaches this address anywhere
;          in the image.  A register-indirect call would be invisible to that
;          scan, so this is "not found", not "dead".
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFADB0F = sub_FADB0F, 0xFADCC3 = Voice_RestagePitchReg0400_ForList
;          0xFB3D09 = VoiceQuery_Tag00_All
; Evidence: the listing below is the byte-identical round-trip of 0xFB0285-0xFB029D
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Named:   NO, but it is now placed.  It is the exact shape of
;          GlobalTune_SetFineTune_AndRestageAll with ONE substitution: store, query,
;          restage -- `calr 0xfadb0f` at 0xFB028E where the named routine has
;          `calr 0xfadae7`, then `call 0xFB3D09` (VoiceQuery_Tag00_All) and
;          `calr 0xfadcc3` (Voice_RestagePitchReg0400_ForList) in the same order at the
;          same offsets.
; Refused: it inherits sub_FADB0F's gap.  The routine it stores through edits flag bits
;          11..15 of 0x0014FF, which nothing in the image reads, so "what this applies"
;          is undefined; and NOTHING REFERENCES THIS ROUTINE -- no literal call, calr or
;          jp, and no 24-bit pointer in the 512 KiB image.  GlobalSetup_Dispatch has no
;          arm for it.  It is reached, if at all, through a register.
; --------------------------------------------------------------------------
sub_FB0285:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB0285  link XIZ,0x0000
	push	0                                     ; FB0289  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB028B  push (XIZ+0x08)
	calr sub_FADB0F                 ; FB028E  calr 0xfadb0f
	call	VoiceQuery_Tag00_All                              ; FB0291  call 0xfb3d09
	push	xiy                                   ; FB0295  push XIY
	calr Voice_RestagePitchReg0400_ForList                 ; FB0296  calr 0xfadcc3
	inc	6, xsp                                 ; FB0299  inc 6,XSP
	unlk32 xiz                                 ; FB029B  unlk XIZ
	ret                                        ; FB029D  ret
; --------------------------------------------------------------------------
; sub_FB029E -- 0xFB029E..0xFB0337 (154 bytes)
;
; Called from: no site outside this module.
;          2 site(s) inside this module:
;          0xFADAA9 0xFB045F
; Inputs:  frame `link XIZ,-1`; no positive frame slot is read
; Outputs: no absolute-addressed write.
; Calls:   0xFACC3F = PartRec_Word0006_SetBit13, 0xFB47C4 = Part_LoadToneRecordAndPointers
;          0xFB6500 = PartRec_ResetToDefaults, 0xFB6681 = Part_RestageVoiceParams_Melodic
;          0xFB68DD = Part_RestageVoiceParams_Drawbar
; Evidence: the listing below is the byte-identical round-trip of 0xFB029E-0xFB0337
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB029E:
	link32 0xEE, 0x0C, 0xFF, 0xFF              ; FB029E  link XIZ,0xffff
	push	xhl                                   ; FB02A2  push XHL
	push	xde                                   ; FB02A3  push XDE
	push	xix                                   ; FB02A4  push XIX
	ld	(xiz-1), 0                              ; FB02A5  ld (XIZ+0xff),0x00
	ldw	ix, 0                                  ; FB02A9  ld IX,0x0000
	ldw	hl, 28                                 ; FB02AC  ld HL,0x001c
	ldw	de, 27                                 ; FB02AF  ld DE,0x001b
sub_FB029E__FB02B2:
	push	0                                     ; FB02B2  push 0x00
	extpfx3 0x8E, 0xFF, 0x04                   ; FB02B4  push (XIZ+0xff)
	call	PartRec_ResetToDefaults                              ; FB02B7  call 0xfb6500
	push	0                                     ; FB02BB  push 0x00
	extpfx3 0x8E, 0xFF, 0x04                   ; FB02BD  push (XIZ+0xff)
	call	PartRec_Word0006_SetBit13                              ; FB02C0  call 0xfacc3f
	extz	xhl                                   ; FB02C4  extz XHL
	ld	c, (xhl+0x1523)                         ; FB02C6  ld C,(XHL+0x1523)
	pushw	bc                                   ; FB02CB  push BC
	extz	xde                                   ; FB02CC  extz XDE
	ld	c, (xde+0x1523)                         ; FB02CE  ld C,(XDE+0x1523)
	pushw	bc                                   ; FB02D3  push BC
	push	0                                     ; FB02D4  push 0x00
	extpfx3 0x8E, 0xFF, 0x04                   ; FB02D6  push (XIZ+0xff)
	call	Part_LoadToneRecordAndPointers                              ; FB02D9  call 0xfb47c4
	extz	xix                                   ; FB02DD  extz XIX
	ld	xbc, (xix+0x1523)                       ; FB02DF  ld XBC,(XIX+0x1523)
	ld	a, (xbc+16)                             ; FB02E4  ld A,(XBC+0x10)
	and	a, 0xC0                                ; FB02E7  and A,0xc0
	extz	wa                                    ; FB02EA  extz WA
	inc	8, xsp                                 ; FB02EC  inc 0,XSP
	inc	2, xsp                                 ; FB02EE  inc 2,XSP
	cp	wa, 0:i3                                  ; FB02F0  cp WA,0
	jr z, sub_FB029E__FB0308                   ; FB02F2  jr Z,0xfb0308
	cp	wa, 64                                  ; FB02F4  cp WA,0x0040
	jr z, sub_FB029E__FB0313                   ; FB02F8  jr Z,0xfb0313
	cp	wa, 0x80                                ; FB02FA  cp WA,0x0080
	jr z, sub_FB029E__FB031D                   ; FB02FE  jr Z,0xfb031d
	cp	wa, 0xC0                                ; FB0300  cp WA,0x00c0
	jr z, sub_FB029E__FB0308                   ; FB0304  jr Z,0xfb0308
	jr sub_FB029E__FB031D                      ; FB0306  jr T,0xfb031d
sub_FB029E__FB0308:
	push	0                                     ; FB0308  push 0x00
	extpfx3 0x8E, 0xFF, 0x04                   ; FB030A  push (XIZ+0xff)
	call	Part_RestageVoiceParams_Melodic                              ; FB030D  call 0xfb6681
	jr sub_FB029E__FB031C                      ; FB0311  jr T,0xfb031c
sub_FB029E__FB0313:
	push	0                                     ; FB0313  push 0x00
	extpfx3 0x8E, 0xFF, 0x04                   ; FB0315  push (XIZ+0xff)
	call	Part_RestageVoiceParams_Drawbar                              ; FB0318  call 0xfb68dd
sub_FB029E__FB031C:
	popw	bc                                    ; FB031C  pop BC
sub_FB029E__FB031D:
	add	ix, 0x12C                              ; FB031D  add IX,0x012c
	add	de, 0x12C                              ; FB0321  add DE,0x012c
	add	hl, 0x12C                              ; FB0325  add HL,0x012c
	incm8	1, (xiz-1)                           ; FB0329  inc 1,(XIZ+0xff)
	cp (xiz-1), 0x21                           ; FB032C  cp (XIZ+0xff),0x21
	jr c, sub_FB029E__FB02B2                   ; FB0330  jr C,0xfb02b2
	pop	xix                                    ; FB0332  pop XIX
	pop	xde                                    ; FB0333  pop XDE
	pop	xhl                                    ; FB0334  pop XHL
	unlk32 xiz                                 ; FB0335  unlk XIZ
	ret                                        ; FB0337  ret
; --------------------------------------------------------------------------
; GlobalSetup_Dispatch -- 0xFB0338..0xFB0503 (460 bytes)
;             the status-0xF0 arm of the internal message protocol -- 27 codes, each
;             writing one field of the GLOBAL SETUP record at RAM 0x0014FE.
;             (* NAMED in wave 7 round 3; was `sub_FB0338`.)
;
; Called from: 1 site(s) outside this module:
;          0xFB09E6 in MidiIn_ParseRingAndDispatch__FB0992
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFADA7C = sub_FADA7C, 0xFADAB1 = P7Mixer_SetGainIndex1
;          0xFADACA = P7Mixer_SetGainIndex2, 0xFADAFC = GlobalTune_StoreTranspose
;          0xFADB0F = sub_FADB0F, 0xFADB70 = GlobalScale_StoreMode
;          0xFADB7E = VoiceDefaults_StoreFromPackedByte, 0xFADBEE = sub_FADBEE
;          0xFADBFC = sub_FADBFC, 0xFADC1F = GlobalScale_StorePitchClassDetune
;          0xFADC3E = sub_FADC3E, 0xFADC4C = GlobalScale_SelectGlobalOrPerTone
;          0xFADC6F = Dev10C_SetReg0201_FromNibblePair, 0xFB0200 = Dev10C_QuiesceListedChans_0800_0840
;          0xFB026C = GlobalTune_SetFineTune_AndRestageAll, 0xFB029E = sub_FB029E
; Evidence: the listing below is the byte-identical round-trip of 0xFB0338-0xFB0503
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Name:    this is the handler MidiIn_ParseRingAndDispatch reaches for status nibble
;          0xF0 (`cp BC,0x00f0` at 0xFB0678 selecting 0xFB0992, which pushes the packet
;          address 0x00D7E9 and calls 0xFB0338 at 0xFB09E6).  It selects on packet byte
;          [2] through 27 `cp BC,imm / jrl Z` arms running 0xFB0345..0xFB03FF -- the
;          FIRST code is 0x09 and the LAST is 0xB2 -- and hands packet byte [3],
;          `ld C,(XIX+0x03)`, to the arm's setter.
; Evidence: that the record it writes is GLOBAL and not per-part is measured over the
;          whole 460-byte body, three independent ways: there is NO read of (XIX+0x01),
;          the byte every other four-byte status uses as its PART index; there is NO
;          `mul BC,0x012c`, the part-record stride; and every setter it calls writes a
;          fixed absolute address inside 0x0014FE..0x001522 -- the 37 bytes that end
;          exactly where the part records begin, at 0x001523.
;          The twelve arms 0xA4..0xAF all call ONE setter and differ only in the
;          immediate they push first, 0x0000 at 0xFB0479 through 0x000B at 0xFB04DD.
;          Reproduced, with the last arm asserted, by
;          `python3 notes/prom_c_inventory_round8.py --dispatch`.
; Unknown:  what CPU 1 calls each of the 27 codes.  These packets arrive over link
;          channel 0 (Link_Ch0_AppendToRing -> the ring at 0x00E2F1 -> MAIN's
;          `lda XBC,0x00E2EB / call 0xFB060A` at 0xF98CA4), so the panel's own names for
;          these parameters are in prom_a; a scan of prom_a's converted text for a
;          builder that emits a 0xF0 status together with three or more of these codes
;          found none, so the naming lever is in prom_a's unconverted bytes.
; --------------------------------------------------------------------------
GlobalSetup_Dispatch:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB0338  link XIZ,0x0000
	push	xix                                   ; FB033C  push XIX
	ld	xix, (xiz+8)                            ; FB033D  ld XIX,(XIZ+0x08)
	ld	c, (xix+2)                              ; FB0340  ld C,(XIX+0x02)
	extz	bc                                    ; FB0343  extz BC
	cp	bc, 9                                   ; FB0345  cp BC,0x0009
	jrl z, GlobalSetup_Dispatch__FB0405                  ; FB0349  jrl Z,0xfb0405
	cp	bc, 0x80                                ; FB034C  cp BC,0x0080
	jrl z, GlobalSetup_Dispatch__FB040F                  ; FB0350  jrl Z,0xfb040f
	cp	bc, 0x81                                ; FB0353  cp BC,0x0081
	jrl z, GlobalSetup_Dispatch__FB0419                  ; FB0357  jrl Z,0xfb0419
	cp	bc, 0x82                                ; FB035A  cp BC,0x0082
	jrl z, GlobalSetup_Dispatch__FB0423                  ; FB035E  jrl Z,0xfb0423
	cp	bc, 0x83                                ; FB0361  cp BC,0x0083
	jrl z, GlobalSetup_Dispatch__FB042D                  ; FB0365  jrl Z,0xfb042d
	cp	bc, 0x85                                ; FB0368  cp BC,0x0085
	jrl z, GlobalSetup_Dispatch__FB0437                  ; FB036C  jrl Z,0xfb0437
	cp	bc, 0x86                                ; FB036F  cp BC,0x0086
	jrl z, GlobalSetup_Dispatch__FB0441                  ; FB0373  jrl Z,0xfb0441
	cp	bc, 0x87                                ; FB0376  cp BC,0x0087
	jrl z, GlobalSetup_Dispatch__FB044B                  ; FB037A  jrl Z,0xfb044b
	cp	bc, 0x91                                ; FB037D  cp BC,0x0091
	jrl z, GlobalSetup_Dispatch__FB0455                  ; FB0381  jrl Z,0xfb0455
	cp	bc, 0x92                                ; FB0384  cp BC,0x0092
	jrl z, GlobalSetup_Dispatch__FB045F                  ; FB0388  jrl Z,0xfb045f
	cp	bc, 0x99                                ; FB038B  cp BC,0x0099
	jrl z, GlobalSetup_Dispatch__FB0465                  ; FB038F  jrl Z,0xfb0465
	cp	bc, 0xA3                                ; FB0392  cp BC,0x00a3
	jrl z, GlobalSetup_Dispatch__FB046F                  ; FB0396  jrl Z,0xfb046f
	cp	bc, 0xA4                                ; FB0399  cp BC,0x00a4
	jrl z, GlobalSetup_Dispatch__FB0475                  ; FB039D  jrl Z,0xfb0475
	cp	bc, 0xA5                                ; FB03A0  cp BC,0x00a5
	jrl z, GlobalSetup_Dispatch__FB047F                  ; FB03A4  jrl Z,0xfb047f
	cp	bc, 0xA6                                ; FB03A7  cp BC,0x00a6
	jrl z, GlobalSetup_Dispatch__FB0488                  ; FB03AB  jrl Z,0xfb0488
	cp	bc, 0xA7                                ; FB03AE  cp BC,0x00a7
	jrl z, GlobalSetup_Dispatch__FB0491                  ; FB03B2  jrl Z,0xfb0491
	cp	bc, 0xA8                                ; FB03B5  cp BC,0x00a8
	jrl z, GlobalSetup_Dispatch__FB049A                  ; FB03B9  jrl Z,0xfb049a
	cp	bc, 0xA9                                ; FB03BC  cp BC,0x00a9
	jrl z, GlobalSetup_Dispatch__FB04A3                  ; FB03C0  jrl Z,0xfb04a3
	cp	bc, 0xAA                                ; FB03C3  cp BC,0x00aa
	jrl z, GlobalSetup_Dispatch__FB04AC                  ; FB03C7  jrl Z,0xfb04ac
	cp	bc, 0xAB                                ; FB03CA  cp BC,0x00ab
	jrl z, GlobalSetup_Dispatch__FB04B5                  ; FB03CE  jrl Z,0xfb04b5
	cp	bc, 0xAC                                ; FB03D1  cp BC,0x00ac
	jrl z, GlobalSetup_Dispatch__FB04BE                  ; FB03D5  jrl Z,0xfb04be
	cp	bc, 0xAD                                ; FB03D8  cp BC,0x00ad
	jrl z, GlobalSetup_Dispatch__FB04C7                  ; FB03DC  jrl Z,0xfb04c7
	cp	bc, 0xAE                                ; FB03DF  cp BC,0x00ae
	jrl z, GlobalSetup_Dispatch__FB04D0                  ; FB03E3  jrl Z,0xfb04d0
	cp	bc, 0xAF                                ; FB03E6  cp BC,0x00af
	jrl z, GlobalSetup_Dispatch__FB04D9                  ; FB03EA  jrl Z,0xfb04d9
	cp	bc, 0xB0                                ; FB03ED  cp BC,0x00b0
	jrl z, GlobalSetup_Dispatch__FB04E6                  ; FB03F1  jrl Z,0xfb04e6
	cp	bc, 0xB1                                ; FB03F4  cp BC,0x00b1
	jrl z, GlobalSetup_Dispatch__FB04EF                  ; FB03F8  jrl Z,0xfb04ef
	cp	bc, 0xB2                                ; FB03FB  cp BC,0x00b2
	jrl z, GlobalSetup_Dispatch__FB04F8                  ; FB03FF  jrl Z,0xfb04f8
	jrl GlobalSetup_Dispatch__FB0500                     ; FB0402  jrl T,0xfb0500
GlobalSetup_Dispatch__FB0405:
	ld	c, (xix+3)                              ; FB0405  ld C,(XIX+0x03)
	pushw	bc                                   ; FB0408  push BC
	calr sub_FADA7C                 ; FB0409  calr 0xfada7c
	jrl GlobalSetup_Dispatch__FB04FF                     ; FB040C  jrl T,0xfb04ff
GlobalSetup_Dispatch__FB040F:
	ld	c, (xix+3)                              ; FB040F  ld C,(XIX+0x03)
	pushw	bc                                   ; FB0412  push BC
	calr P7Mixer_SetGainIndex1                 ; FB0413  calr 0xfadab1
	jrl GlobalSetup_Dispatch__FB04FF                     ; FB0416  jrl T,0xfb04ff
GlobalSetup_Dispatch__FB0419:
	ld	c, (xix+3)                              ; FB0419  ld C,(XIX+0x03)
	pushw	bc                                   ; FB041C  push BC
	calr P7Mixer_SetGainIndex2                 ; FB041D  calr 0xfadaca
	jrl GlobalSetup_Dispatch__FB04FF                     ; FB0420  jrl T,0xfb04ff
GlobalSetup_Dispatch__FB0423:
	ld	c, (xix+3)                              ; FB0423  ld C,(XIX+0x03)
	pushw	bc                                   ; FB0426  push BC
	calr GlobalTune_SetFineTune_AndRestageAll                 ; FB0427  calr 0xfb026c
	jrl GlobalSetup_Dispatch__FB04FF                     ; FB042A  jrl T,0xfb04ff
GlobalSetup_Dispatch__FB042D:
	ld	c, (xix+3)                              ; FB042D  ld C,(XIX+0x03)
	pushw	bc                                   ; FB0430  push BC
	calr GlobalTune_StoreTranspose                 ; FB0431  calr 0xfadafc
	jrl GlobalSetup_Dispatch__FB04FF                     ; FB0434  jrl T,0xfb04ff
GlobalSetup_Dispatch__FB0437:
	ld	c, (xix+3)                              ; FB0437  ld C,(XIX+0x03)
	pushw	bc                                   ; FB043A  push BC
	calr sub_FADB0F                 ; FB043B  calr 0xfadb0f
	jrl GlobalSetup_Dispatch__FB04FF                     ; FB043E  jrl T,0xfb04ff
GlobalSetup_Dispatch__FB0441:
	ld	c, (xix+3)                              ; FB0441  ld C,(XIX+0x03)
	pushw	bc                                   ; FB0444  push BC
	calr GlobalScale_StoreMode                 ; FB0445  calr 0xfadb70
	jrl GlobalSetup_Dispatch__FB04FF                     ; FB0448  jrl T,0xfb04ff
GlobalSetup_Dispatch__FB044B:
	ld	c, (xix+3)                              ; FB044B  ld C,(XIX+0x03)
	pushw	bc                                   ; FB044E  push BC
	calr VoiceDefaults_StoreFromPackedByte                 ; FB044F  calr 0xfadb7e
	jrl GlobalSetup_Dispatch__FB04FF                     ; FB0452  jrl T,0xfb04ff
GlobalSetup_Dispatch__FB0455:
	ld	c, (xix+3)                              ; FB0455  ld C,(XIX+0x03)
	pushw	bc                                   ; FB0458  push BC
	calr sub_FADBEE                 ; FB0459  calr 0xfadbee
	jrl GlobalSetup_Dispatch__FB04FF                     ; FB045C  jrl T,0xfb04ff
GlobalSetup_Dispatch__FB045F:
	calr sub_FB029E                 ; FB045F  calr 0xfb029e
	jrl GlobalSetup_Dispatch__FB0500                     ; FB0462  jrl T,0xfb0500
GlobalSetup_Dispatch__FB0465:
	ld	c, (xix+3)                              ; FB0465  ld C,(XIX+0x03)
	pushw	bc                                   ; FB0468  push BC
	calr sub_FADBFC                 ; FB0469  calr 0xfadbfc
	jrl GlobalSetup_Dispatch__FB04FF                     ; FB046C  jrl T,0xfb04ff
GlobalSetup_Dispatch__FB046F:
	calr Dev10C_QuiesceListedChans_0800_0840                 ; FB046F  calr 0xfb0200
	jrl GlobalSetup_Dispatch__FB0500                     ; FB0472  jrl T,0xfb0500
GlobalSetup_Dispatch__FB0475:
	ld	c, (xix+3)                              ; FB0475  ld C,(XIX+0x03)
	pushw	bc                                   ; FB0478  push BC
	pushw	0                                    ; FB0479  push 0x0000
	jrl GlobalSetup_Dispatch__FB04E0                     ; FB047C  jrl T,0xfb04e0
GlobalSetup_Dispatch__FB047F:
	ld	c, (xix+3)                              ; FB047F  ld C,(XIX+0x03)
	pushw	bc                                   ; FB0482  push BC
	pushw	1                                    ; FB0483  push 0x0001
	jr GlobalSetup_Dispatch__FB04E0                      ; FB0486  jr T,0xfb04e0
GlobalSetup_Dispatch__FB0488:
	ld	c, (xix+3)                              ; FB0488  ld C,(XIX+0x03)
	pushw	bc                                   ; FB048B  push BC
	pushw	2                                    ; FB048C  push 0x0002
	jr GlobalSetup_Dispatch__FB04E0                      ; FB048F  jr T,0xfb04e0
GlobalSetup_Dispatch__FB0491:
	ld	c, (xix+3)                              ; FB0491  ld C,(XIX+0x03)
	pushw	bc                                   ; FB0494  push BC
	pushw	3                                    ; FB0495  push 0x0003
	jr GlobalSetup_Dispatch__FB04E0                      ; FB0498  jr T,0xfb04e0
GlobalSetup_Dispatch__FB049A:
	ld	c, (xix+3)                              ; FB049A  ld C,(XIX+0x03)
	pushw	bc                                   ; FB049D  push BC
	pushw	4                                    ; FB049E  push 0x0004
	jr GlobalSetup_Dispatch__FB04E0                      ; FB04A1  jr T,0xfb04e0
GlobalSetup_Dispatch__FB04A3:
	ld	c, (xix+3)                              ; FB04A3  ld C,(XIX+0x03)
	pushw	bc                                   ; FB04A6  push BC
	pushw	5                                    ; FB04A7  push 0x0005
	jr GlobalSetup_Dispatch__FB04E0                      ; FB04AA  jr T,0xfb04e0
GlobalSetup_Dispatch__FB04AC:
	ld	c, (xix+3)                              ; FB04AC  ld C,(XIX+0x03)
	pushw	bc                                   ; FB04AF  push BC
	pushw	6                                    ; FB04B0  push 0x0006
	jr GlobalSetup_Dispatch__FB04E0                      ; FB04B3  jr T,0xfb04e0
GlobalSetup_Dispatch__FB04B5:
	ld	c, (xix+3)                              ; FB04B5  ld C,(XIX+0x03)
	pushw	bc                                   ; FB04B8  push BC
	pushw	7                                    ; FB04B9  push 0x0007
	jr GlobalSetup_Dispatch__FB04E0                      ; FB04BC  jr T,0xfb04e0
GlobalSetup_Dispatch__FB04BE:
	ld	c, (xix+3)                              ; FB04BE  ld C,(XIX+0x03)
	pushw	bc                                   ; FB04C1  push BC
	pushw	8                                    ; FB04C2  push 0x0008
	jr GlobalSetup_Dispatch__FB04E0                      ; FB04C5  jr T,0xfb04e0
GlobalSetup_Dispatch__FB04C7:
	ld	c, (xix+3)                              ; FB04C7  ld C,(XIX+0x03)
	pushw	bc                                   ; FB04CA  push BC
	pushw	9                                    ; FB04CB  push 0x0009
	jr GlobalSetup_Dispatch__FB04E0                      ; FB04CE  jr T,0xfb04e0
GlobalSetup_Dispatch__FB04D0:
	ld	c, (xix+3)                              ; FB04D0  ld C,(XIX+0x03)
	pushw	bc                                   ; FB04D3  push BC
	pushw	10                                   ; FB04D4  push 0x000a
	jr GlobalSetup_Dispatch__FB04E0                      ; FB04D7  jr T,0xfb04e0
GlobalSetup_Dispatch__FB04D9:
	ld	c, (xix+3)                              ; FB04D9  ld C,(XIX+0x03)
	pushw	bc                                   ; FB04DC  push BC
	pushw	11                                   ; FB04DD  push 0x000b
GlobalSetup_Dispatch__FB04E0:
	calr GlobalScale_StorePitchClassDetune                 ; FB04E0  calr 0xfadc1f
	pop	xiy                                    ; FB04E3  pop XIY
	jr GlobalSetup_Dispatch__FB0500                      ; FB04E4  jr T,0xfb0500
GlobalSetup_Dispatch__FB04E6:
	ld	c, (xix+3)                              ; FB04E6  ld C,(XIX+0x03)
	pushw	bc                                   ; FB04E9  push BC
	calr sub_FADC3E                 ; FB04EA  calr 0xfadc3e
	jr GlobalSetup_Dispatch__FB04FF                      ; FB04ED  jr T,0xfb04ff
GlobalSetup_Dispatch__FB04EF:
	ld	c, (xix+3)                              ; FB04EF  ld C,(XIX+0x03)
	pushw	bc                                   ; FB04F2  push BC
	calr GlobalScale_SelectGlobalOrPerTone                 ; FB04F3  calr 0xfadc4c
	jr GlobalSetup_Dispatch__FB04FF                      ; FB04F6  jr T,0xfb04ff
GlobalSetup_Dispatch__FB04F8:
	ld	c, (xix+3)                              ; FB04F8  ld C,(XIX+0x03)
	pushw	bc                                   ; FB04FB  push BC
	calr Dev10C_SetReg0201_FromNibblePair                 ; FB04FC  calr 0xfadc6f
GlobalSetup_Dispatch__FB04FF:
	popw	bc                                    ; FB04FF  pop BC
GlobalSetup_Dispatch__FB0500:
	pop	xix                                    ; FB0500  pop XIX
	unlk32 xiz                                 ; FB0501  unlk XIZ
	ret                                        ; FB0503  ret
