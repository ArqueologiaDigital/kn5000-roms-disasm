; ==============================================================================
; Technics SX-WSA1R -- prom_c (CPU 2, IC28) -- 0xFC89C5-0xFC8BB1  THE SERIAL EEPROM, a Microwire 64 x 16 bit-banged on port pins
; ==============================================================================
;
; 474 lines moved out of prom_c/wsa1_prom_c.s by notes/prom_c_split.py.  The master
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
; Banner-declared, and the storage behind the key-touch calibration.
;
; >>> END OF EXTRACTION HEADER -- everything below is verbatim from the master

; ==============================================================================
; 0xFC89C5-0xFC8BB1 -- ★★ THE SERIAL EEPROM, bit-banged on two port pins
; ==============================================================================
;
; EIGHT routines and one pad byte, 493 bytes, and between them they answer a
; question this file has been carrying open: `NoteTrim_BuildFromCalibration` (0xF997FA) said of its data
; source *"⚠ 0xFC8B0B is NOT CONVERTED … a 62-byte block with a checksum and a
; magic is what a stored calibration looks like; WHERE it is read from is not
; established here"*.  It is read from a **serial EEPROM**, one bit at a time.
;
; ★ THE PROTOCOL IS MICROWIRE, AND THE COMMAND WORDS PROVE IT.  Four of these
; routines shift a NINE-bit value out MSB-first (`ldb h,9`, test 0x0100, shift
; left, repeat).  Their four command words are:
;
;     0xFC89C5   0x130          = 1 00 110000
;     0xFC89F7   0x100          = 1 00 000000
;     0xFC8A29   0x180 | addr   = 1 10 aaaaaa
;     0xFC8A62   0x140 | addr   = 1 01 aaaaaa
;
; A 9-bit frame that splits as 1 start bit + 2 opcode bits + 6 address bits, with
; 16 data bits, is the 64 x 16 Microwire organisation, and those four opcodes are
; its four instructions in the standard encoding: 00 with address 11xxxx = EWEN
; (erase/write enable), 00 with address 00xxxx = EWDS (erase/write disable),
; 10 = READ, 01 = WRITE.  Nothing else explains 0x130 and 0x100 differing only in
; two address bits while 0x180 and 0x140 differ in the opcode field.
;
; ⚠ The PART is inferred from the protocol, not read: a 6-bit address and 16-bit
; data is a 93C46-class device.  Nothing in the ROM names it and no schematic was
; consulted for this note.
;
; ★ THE THREE PINS, AND WHAT RESET INDEPENDENTLY SAYS ABOUT THEM.  The driver
; touches exactly three bits, and only ever in these roles:
;
;     P6 bit 5   CS   -- `set 5,(P6)` opens every frame, `res 5,(P6)` closes it
;     P8 bit 3   SK   -- `set 3,(P8)` / `res 3,(P8)` once per bit
;     P8 bit 4   DI   -- set or cleared from the bit being sent, before SK rises
;     P8 bit 5   DO   -- only ever READ (`bit 5,(P8)`), never written
;
; `python3 notes/prom_c_runtime_check.py` censuses every one of those bit
; operations from the BYTES and asserts the shape rather than a hand count: P6 is
; touched at 11 sites and every one of them is bit 5; CS, SK and DI each have
; exactly ONE more `res` than `set`, and all three extras are EEPROM_PortInit's
; opening trio at 0xFC8B9D, which parks the bus without ever driving it high; and
; there is NO `set 5,(P8)` or `res 5,(P8)` anywhere in the driver, so DO is an
; input by the code's own usage.  (A first draft of that script asserted
; hand-counted totals and failed on all four -- the counts are derived and printed,
; never asserted.)
;
; P6 and P8 are SFRs 0x12 and 0x18 in include/tmp95c061_sfr.inc (MAME's symbol
; table for this part).  RESET corroborates the roles from the other side:
;   * `ldio P6FC,0x1F` (0xFFF01A) leaves P6 bit 5 clear, i.e. a plain port pin and
;     not one of the DRAM controller's alternate functions -- the existing RESET
;     comment already says so for its own reasons;
;   * `ldio P8CR,0x19` (0xFFF078) sets bits 0, 3 and 4 and leaves bit 5 CLEAR.
;     ⚠ P8CR's bit layout is NOT decoded anywhere in these trees -- MAME stores it
;     and never reads it (`tmp95c061_device::port_cr_w`, which for every port but
;     PORT_A is a bare assignment) and no databook is available.  But if PnCR is a
;     direction register with 1 = output, then the two pins this driver DRIVES are
;     outputs and the one pin it READS is not, and no other bit of P8 is touched
;     by either.  Offered as CORROBORATION of the pin roles, not as a decode of
;     P8CR.
;
; ★ THE STORED BLOCK: 33 words, and every boundary comes from the reader.
; Every figure below is re-derived by `python3 notes/prom_c_runtime_check.py`.
; EEPROM_LoadCalibration reads words 0..0x1E into RAM 0x00E2A1 (31 words, 62
; bytes), sums them, requires word 0x1F to equal that sum and word 0x20 to equal
; 0x5AA5, and returns the RAM address or 0.  ★ And the RAM side closes exactly
; where the next structure starts: 0x00E2A1 + 62 = 0x00E2DF, which is the
; destination of RamImage_Copy's 4,312-byte boot copy (0xF989EF, converted
; above).  The EEPROM shadow and the ROM-initialised variable block are adjacent,
; and neither figure was chosen to make that true.
;
; ⚠ WHAT THE 62 BYTES MEAN is only established for the part
; NoteTrim_BuildFromCalibration uses: it reads bytes 0..0x3C of the shadow as
; per-note key-touch calibration.  That is 61 of the 62.  What byte 61 is, and
; whether the block has other consumers, is not established here.
;
; --------------------------------------------------------------------------
; EEPROM_WriteEnable -- send EWEN (0x130).
;
; Called from: EEPROM_WriteIndexPattern, `calr` at 0xFC8B83.  The only site
;              (prom_c_xrefs.py 0xFC89C5).
; Inputs:  none.  Outputs: the device's write-enable latch set; CS left LOW.
; Evidence: `ldw de,0x130` is the whole argument, and 0x130 in the 9-bit frame is
;          opcode 00 with address 11xxxx -- EWEN.  The nine-bit loop is the same
;          nine instructions as in the other three command routines; the only
;          differences between all four are the constant and where it comes from.
; --------------------------------------------------------------------------
EEPROM_WriteEnable:
	pushw	hl                                   ; FC89C5  push HL
	pushw	de                                   ; FC89C6  push DE
	ldw	de, 0x130                              ; FC89C7  ld DE,0x0130
	set_dd8	5, P6                              ; FC89CA  set 5,(0x12)
	ld	h, 9:opc                                   ; FC89CD  ld H,0x09
EEPROM_WriteEnable__bit:
	ld	bc, de                                  ; FC89CF  ld BC,DE
	and	bc, 0x100                              ; FC89D1  and BC,0x0100
	jr z, EEPROM_WriteEnable__zero             ; FC89D5  jr Z,0xfc89dc
	set_dd8	4, P8                              ; FC89D7  set 4,(0x18)
	jr EEPROM_WriteEnable__clock               ; FC89DA  jr T,0xfc89df
EEPROM_WriteEnable__zero:
	res_dd8	4, P8                              ; FC89DC  res 4,(0x18)
EEPROM_WriteEnable__clock:
	set_dd8	3, P8                              ; FC89DF  set 3,(0x18)
	ld	bc, de                                  ; FC89E2  ld BC,DE
	add	bc, de                                 ; FC89E4  add BC,DE
	ld	de, bc                                  ; FC89E6  ld DE,BC
	res_dd8	3, P8                              ; FC89E8  res 3,(0x18)
	dec	1, h                                   ; FC89EB  dec 1,H
	cp	h, 0:i3                                   ; FC89ED  cp H,0
	jr nz, EEPROM_WriteEnable__bit             ; FC89EF  jr NZ,0xfc89cf
	res_dd8	5, P6                              ; FC89F1  res 5,(0x12)
	popw	de                                    ; FC89F4  pop DE
	popw	hl                                    ; FC89F5  pop HL
	ret                                        ; FC89F6  ret
; --------------------------------------------------------------------------
; EEPROM_WriteDisable -- send EWDS (0x100).
;
; Called from: EEPROM_WriteIndexPattern, `calr` at 0xFC8B97.  The only site.
; Inputs:  none.  Outputs: the write-enable latch cleared; CS left LOW.
; Evidence: 0x100 is opcode 00 with address 00xxxx -- EWDS, the exact complement
;          of EEPROM_WriteEnable's 0x130, and the two routines are otherwise the
;          same 22 instructions.
; --------------------------------------------------------------------------
EEPROM_WriteDisable:
	pushw	hl                                   ; FC89F7  push HL
	pushw	de                                   ; FC89F8  push DE
	ldw	de, 0x100                              ; FC89F9  ld DE,0x0100
	set_dd8	5, P6                              ; FC89FC  set 5,(0x12)
	ld	h, 9:opc                                   ; FC89FF  ld H,0x09
EEPROM_WriteDisable__bit:
	ld	bc, de                                  ; FC8A01  ld BC,DE
	and	bc, 0x100                              ; FC8A03  and BC,0x0100
	jr z, EEPROM_WriteDisable__zero            ; FC8A07  jr Z,0xfc8a0e
	set_dd8	4, P8                              ; FC8A09  set 4,(0x18)
	jr EEPROM_WriteDisable__clock              ; FC8A0C  jr T,0xfc8a11
EEPROM_WriteDisable__zero:
	res_dd8	4, P8                              ; FC8A0E  res 4,(0x18)
EEPROM_WriteDisable__clock:
	set_dd8	3, P8                              ; FC8A11  set 3,(0x18)
	ld	bc, de                                  ; FC8A14  ld BC,DE
	add	bc, de                                 ; FC8A16  add BC,DE
	ld	de, bc                                  ; FC8A18  ld DE,BC
	res_dd8	3, P8                              ; FC8A1A  res 3,(0x18)
	dec	1, h                                   ; FC8A1D  dec 1,H
	cp	h, 0:i3                                   ; FC8A1F  cp H,0
	jr nz, EEPROM_WriteDisable__bit            ; FC8A21  jr NZ,0xfc8a01
	res_dd8	5, P6                              ; FC8A23  res 5,(0x12)
	popw	de                                    ; FC8A26  pop DE
	popw	hl                                    ; FC8A27  pop HL
	ret                                        ; FC8A28  ret
; --------------------------------------------------------------------------
; EEPROM_SendReadCommand -- send READ (0x180 | address) and LEAVE CS ASSERTED.
;
; Called from: EEPROM_LoadCalibration, three `calr` sites -- 0xFC8B20, 0xFC8B58
;              and 0xFC8B64.  Those are all three (prom_c_xrefs.py 0xFC8A29).
; Inputs:  (XIZ+0x08) word, the 6-bit word address.
; Outputs: the command clocked out; ★ CS is NOT dropped -- the caller must follow
;          with EEPROM_ShiftIn16, which reads the 16 data bits and drops CS.
; Evidence: `or de,0x180` is opcode 10 = READ.  That CS stays high is the whole
;          point and is visible in the epilogue: there is no `res 5,(P6)` between
;          the last clock and the `ret`, and every one of the three callers pairs
;          this call immediately with EEPROM_ShiftIn16.  The other three command
;          routines DO end with `res 5,(P6)`.
; --------------------------------------------------------------------------
EEPROM_SendReadCommand:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC8A29  link XIZ,0x0000
	pushw	hl                                   ; FC8A2D  push HL
	pushw	de                                   ; FC8A2E  push DE
	ld	de, (xiz+8)                             ; FC8A2F  ld DE,(XIZ+0x08)
	or	de, 0x180                               ; FC8A32  or DE,0x0180
	set_dd8	5, P6                              ; FC8A36  set 5,(0x12)
	ld	h, 9:opc                                   ; FC8A39  ld H,0x09
EEPROM_SendReadCommand__bit:
	ld	bc, de                                  ; FC8A3B  ld BC,DE
	and	bc, 0x100                              ; FC8A3D  and BC,0x0100
	jr z, EEPROM_SendReadCommand__zero         ; FC8A41  jr Z,0xfc8a48
	set_dd8	4, P8                              ; FC8A43  set 4,(0x18)
	jr EEPROM_SendReadCommand__clock           ; FC8A46  jr T,0xfc8a4b
EEPROM_SendReadCommand__zero:
	res_dd8	4, P8                              ; FC8A48  res 4,(0x18)
EEPROM_SendReadCommand__clock:
	set_dd8	3, P8                              ; FC8A4B  set 3,(0x18)
	ld	bc, de                                  ; FC8A4E  ld BC,DE
	add	bc, de                                 ; FC8A50  add BC,DE
	ld	de, bc                                  ; FC8A52  ld DE,BC
	res_dd8	3, P8                              ; FC8A54  res 3,(0x18)
	dec	1, h                                   ; FC8A57  dec 1,H
	cp	h, 0:i3                                   ; FC8A59  cp H,0
	jr nz, EEPROM_SendReadCommand__bit         ; FC8A5B  jr NZ,0xfc8a3b
	popw	de                                    ; FC8A5D  pop DE
	popw	hl                                    ; FC8A5E  pop HL
	unlk32 xiz                                 ; FC8A5F  unlk XIZ
	ret                                        ; FC8A61  ret
; --------------------------------------------------------------------------
; EEPROM_WriteWord -- send WRITE (0x140 | address), 16 data bits, then wait out
; the device's internal programming cycle.
;
; Called from: EEPROM_WriteIndexPattern, `calr` at 0xFC8B8B.  The only site.
; Inputs:  (XIZ+0x08) word = the 6-bit word address; (XIZ+0x0a) word = the data.
; Outputs: one EEPROM word programmed.  Returns only when the device says ready.
; Evidence: the two argument slots are told apart by what happens to them --
;          (XIZ+0x08) is `or`ed with 0x140, the WRITE opcode, and shifted out as
;          NINE bits; (XIZ+0x0a) is shifted out as SIXTEEN (`ldb h,0x10`) with no
;          opcode.  ★ The tail is the Microwire ready poll and nothing else fits
;          it: drop CS, burn a 32-count delay, RAISE CS AGAIN, spin until
;          `bit 5,(P8)` reads 1, drop CS.  Re-asserting CS purely to sample DO,
;          with no clocking, is how a Microwire device reports "programming
;          finished"; DO is low while busy.
; Unknown:  how long the delay of 32 is in real time -- no cycle counts are
;          available in these trees.
; --------------------------------------------------------------------------
EEPROM_WriteWord:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FC8A62  link XIZ,0x0000
	pushw	hl                                   ; FC8A66  push HL
	pushw	de                                   ; FC8A67  push DE
	pushw	ix                                   ; FC8A68  push IX
	ld	de, (xiz+8)                             ; FC8A69  ld DE,(XIZ+0x08)
	or	de, 0x140                               ; FC8A6C  or DE,0x0140
	set_dd8	5, P6                              ; FC8A70  set 5,(0x12)
	ld	h, 9:opc                                   ; FC8A73  ld H,0x09
EEPROM_WriteWord__cmd_bit:
	ld	bc, de                                  ; FC8A75  ld BC,DE
	and	bc, 0x100                              ; FC8A77  and BC,0x0100
	jr z, EEPROM_WriteWord__cmd_zero           ; FC8A7B  jr Z,0xfc8a82
	set_dd8	4, P8                              ; FC8A7D  set 4,(0x18)
	jr EEPROM_WriteWord__cmd_clock             ; FC8A80  jr T,0xfc8a85
EEPROM_WriteWord__cmd_zero:
	res_dd8	4, P8                              ; FC8A82  res 4,(0x18)
EEPROM_WriteWord__cmd_clock:
	set_dd8	3, P8                              ; FC8A85  set 3,(0x18)
	ld	bc, de                                  ; FC8A88  ld BC,DE
	add	bc, de                                 ; FC8A8A  add BC,DE
	ld	de, bc                                  ; FC8A8C  ld DE,BC
	res_dd8	3, P8                              ; FC8A8E  res 3,(0x18)
	dec	1, h                                   ; FC8A91  dec 1,H
	cp	h, 0:i3                                   ; FC8A93  cp H,0
	jr nz, EEPROM_WriteWord__cmd_bit           ; FC8A95  jr NZ,0xfc8a75
	ld	ix, (xiz+10)                            ; FC8A97  ld IX,(XIZ+0x0a)
	ld	h, 16:opc                                  ; FC8A9A  ld H,0x10
EEPROM_WriteWord__data_bit:
	ld	bc, ix                                  ; FC8A9C  ld BC,IX
	and	bc, 0x8000                             ; FC8A9E  and BC,0x8000
	jr z, EEPROM_WriteWord__data_zero          ; FC8AA2  jr Z,0xfc8aa9
	set_dd8	4, P8                              ; FC8AA4  set 4,(0x18)
	jr EEPROM_WriteWord__data_clock            ; FC8AA7  jr T,0xfc8aac
EEPROM_WriteWord__data_zero:
	res_dd8	4, P8                              ; FC8AA9  res 4,(0x18)
EEPROM_WriteWord__data_clock:
	set_dd8	3, P8                              ; FC8AAC  set 3,(0x18)
	ld	bc, ix                                  ; FC8AAF  ld BC,IX
	add	bc, ix                                 ; FC8AB1  add BC,IX
	ld	ix, bc                                  ; FC8AB3  ld IX,BC
	res_dd8	3, P8                              ; FC8AB5  res 3,(0x18)
	dec	1, h                                   ; FC8AB8  dec 1,H
	cp	h, 0:i3                                   ; FC8ABA  cp H,0
	jr nz, EEPROM_WriteWord__data_bit          ; FC8ABC  jr NZ,0xfc8a9c
	res_dd8	5, P6                              ; FC8ABE  res 5,(0x12)
	ld	h, 32:opc                                  ; FC8AC1  ld H,0x20
EEPROM_WriteWord__cs_low_delay:
	dec	1, h                                   ; FC8AC3  dec 1,H
	cp	h, 0:i3                                   ; FC8AC5  cp H,0
	jr nz, EEPROM_WriteWord__cs_low_delay      ; FC8AC7  jr NZ,0xfc8ac3
	set_dd8	5, P6                              ; FC8AC9  set 5,(0x12)
EEPROM_WriteWord__wait_ready:
	bit_dd8	5, P8                              ; FC8ACC  bit 5,(0x18)
	jr z, EEPROM_WriteWord__wait_ready         ; FC8ACF  jr Z,0xfc8acc
	res_dd8	5, P6                              ; FC8AD1  res 5,(0x12)
	popw	ix                                    ; FC8AD4  pop IX
	popw	de                                    ; FC8AD5  pop DE
	popw	hl                                    ; FC8AD6  pop HL
	unlk32 xiz                                 ; FC8AD7  unlk XIZ
	ret                                        ; FC8AD9  ret
; --------------------------------------------------------------------------
; EEPROM_ShiftIn16 -- clock in 16 data bits MSB-first, then drop CS.
;
; Called from: EEPROM_LoadCalibration, three `calr` sites -- 0xFC8B23, 0xFC8B5B
;              and 0xFC8B67, each immediately after a call to
;              EEPROM_SendReadCommand.  Those are all three.
; Inputs:  none but the bus state EEPROM_SendReadCommand left: CS asserted.
; Outputs: WA = the 16-bit word; CS dropped.
; Evidence: sixteen passes of {SK high, sample `bit 5,(P8)` into bit 0, SK low,
;          shift the accumulator left}.  ⚠ The shift happens AFTER the OR on every
;          pass, including the last, so the accumulator ends one bit too far left
;          -- and the routine corrects exactly that with `srl 0x01,XBC` before
;          `ld wa,bc`.  That correction is what fixes the bit order as MSB-first
;          rather than leaving it a guess.
;          It is the only routine here that reads P8 bit 5 for data, and the only
;          one that writes neither P8 bit 4 nor a command.
; --------------------------------------------------------------------------
EEPROM_ShiftIn16:
	pushw	hl                                   ; FC8ADA  push HL
	push	xix                                   ; FC8ADB  push XIX
	ld	xix, 0                                  ; FC8ADC  ld XIX,0x00000000
	ld	h, 16:opc                                  ; FC8AE1  ld H,0x10
EEPROM_ShiftIn16__bit:
	set_dd8	3, P8                              ; FC8AE3  set 3,(0x18)
	bit_dd8	5, P8                              ; FC8AE6  bit 5,(0x18)
	jr z, EEPROM_ShiftIn16__clock_low          ; FC8AE9  jr Z,0xfc8af1
	sub	xbc, xbc                               ; FC8AEB  sub XBC,XBC
	inc	1, xbc                                 ; FC8AED  inc 1,XBC
	or	xix, xbc                                ; FC8AEF  or XIX,XBC
EEPROM_ShiftIn16__clock_low:
	res_dd8	3, P8                              ; FC8AF1  res 3,(0x18)
	ld	xbc, xix                                ; FC8AF4  ld XBC,XIX
	add	xbc, xix                               ; FC8AF6  add XBC,XIX
	ld	xix, xbc                                ; FC8AF8  ld XIX,XBC
	dec	1, h                                   ; FC8AFA  dec 1,H
	cp	h, 0:i3                                   ; FC8AFC  cp H,0
	jr nz, EEPROM_ShiftIn16__bit               ; FC8AFE  jr NZ,0xfc8ae3
	res_dd8	5, P6                              ; FC8B00  res 5,(0x12)
	srl	xbc, 1                                 ; FC8B03  srl 0x01,XBC
	ld	wa, bc                                  ; FC8B06  ld WA,BC
	pop	xix                                    ; FC8B08  pop XIX
	popw	hl                                    ; FC8B09  pop HL
	ret                                        ; FC8B0A  ret
; --------------------------------------------------------------------------
; EEPROM_LoadCalibration -- read the whole stored block, verify it, and hand back
; a pointer to the RAM shadow.
;
; Called from: NoteTrim_BuildFromCalibration, `call 0xFC8B0B` at 0xF99802 -- which
;              is reached from MAIN's power-on init chain.  The only site
;              (prom_c_xrefs.py 0xFC8B0B).
; Inputs:  none.
; Outputs: XIY = 0x00E2A1 if the block verifies, XIY = 0 if it does not; and in
;          BOTH cases RAM 0x00E2A1..0x00E2DE holds whatever the first 31 words
;          read back as.
; Evidence: the loop guard is `cp HL,0x001F / jr C`, so word addresses 0..0x1E are
;          read -- 31 words.  Each is stored at 0x00E2A1 + XIX with XIX stepping
;          by 2, then RE-READ from that address and added into DE.  After the
;          loop, word 0x1F is read and compared with DE (`cp DE,WA`), and word
;          0x20 is read and compared with 0x5AA5; either mismatch falls into the
;          arm that sets XIY = 0.  So the layout is 31 data words, a sum, and a
;          magic -- 33 words, and each boundary is one of the routine's own
;          comparisons.
;          ★ 0x00E2A1 + 31*2 = 0x00E2DF, exactly where RamImage_Copy's boot copy
;          begins.  Two independently derived numbers meeting is the reason this
;          header states the shadow's extent rather than its start alone.
;          The `ei 6` / `ei 0` bracket around each word read raises the interrupt
;          mask for the duration of one frame -- the bit-banged clock cannot
;          tolerate an interrupt between SK edges.
; Unknown:  ⚠ the checksum is a plain 16-bit sum of the 31 words with no seed and
;          no complement, which is weak; recorded as read.  Nothing here writes
;          the block, and EEPROM_WriteIndexPattern below is the only writer in the
;          image and does not write the sum or the magic.
; --------------------------------------------------------------------------
EEPROM_LoadCalibration:
	link32 0xEE, 0x0C, 0xF8, 0xFF              ; FC8B0B  link XIZ,0xfff8
	pushw	hl                                   ; FC8B0F  push HL
	pushw	de                                   ; FC8B10  push DE
	push	xix                                   ; FC8B11  push XIX
	ldw	de, 0                                  ; FC8B12  ld DE,0x0000
	ldw	hl, 0                                  ; FC8B15  ld HL,0x0000
	ld	xix, 0                                  ; FC8B18  ld XIX,0x00000000
EEPROM_LoadCalibration__word:
	ei	6                                       ; FC8B1D  ei 0x06
	pushw	hl                                   ; FC8B1F  push HL
	calr (0xFC8A29 - 0xFC8B23)                 ; FC8B20  calr 0xfc8a29
	calr (0xFC8ADA - 0xFC8B26)                 ; FC8B23  calr 0xfc8ada
	ld	(xiz-6), wa                             ; FC8B26  ld (XIZ+0xfa),WA
	ld	(xiz-4), xix                            ; FC8B29  ld (XIZ+0xfc),XIX
	lda	xbc, (0xE2A1:24)                       ; FC8B2C  lda XBC,0x00e2a1
	extpfx3 0xAE, 0xFC, 0x81                   ; FC8B31  add XBC,(XIZ+0xfc)
	ld	(xbc), wa                               ; FC8B34  ld (XBC),WA
	popw	bc                                    ; FC8B36  pop BC
	ei	0                                       ; FC8B37  ei 0x00
	ld	(xiz-8), xix                            ; FC8B39  ld (XIZ+0xf8),XIX
	lda	xbc, (0xE2A1:24)                       ; FC8B3C  lda XBC,0x00e2a1
	extpfx3 0xAE, 0xFC, 0x81                   ; FC8B41  add XBC,(XIZ+0xfc)
	ld	wa, (xbc)                               ; FC8B44  ld WA,(XBC)
	add	de, wa                                 ; FC8B46  add DE,WA
	ld	xix, (xiz-8)                            ; FC8B48  ld XIX,(XIZ+0xf8)
	inc	2, xix                                 ; FC8B4B  inc 2,XIX
	inc	1, hl                                  ; FC8B4D  inc 1,HL
	cp	hl, 31                                  ; FC8B4F  cp HL,0x001f
	jr c, EEPROM_LoadCalibration__word         ; FC8B53  jr C,0xfc8b1d
	pushw	hl                                   ; FC8B55  push HL
	inc	1, hl                                  ; FC8B56  inc 1,HL
	calr (0xFC8A29 - 0xFC8B5B)                 ; FC8B58  calr 0xfc8a29
	calr (0xFC8ADA - 0xFC8B5E)                 ; FC8B5B  calr 0xfc8ada
	popw	bc                                    ; FC8B5E  pop BC
	cp	de, wa                                  ; FC8B5F  cp DE,WA
	jr nz, EEPROM_LoadCalibration__invalid     ; FC8B61  jr NZ,0xfc8b71
	pushw	hl                                   ; FC8B63  push HL
	calr (0xFC8A29 - 0xFC8B67)                 ; FC8B64  calr 0xfc8a29
	calr (0xFC8ADA - 0xFC8B6A)                 ; FC8B67  calr 0xfc8ada
	popw	bc                                    ; FC8B6A  pop BC
	cp	wa, 0x5AA5                              ; FC8B6B  cp WA,0x5aa5
	jr z, EEPROM_LoadCalibration__valid        ; FC8B6F  jr Z,0xfc8b77
EEPROM_LoadCalibration__invalid:
	sub	xbc, xbc                               ; FC8B71  sub XBC,XBC
	ld	xiy, xbc                                ; FC8B73  ld XIY,XBC
	jr EEPROM_LoadCalibration__ret             ; FC8B75  jr T,0xfc8b7c
EEPROM_LoadCalibration__valid:
	lda	xiy, (0xE2A1:24)                       ; FC8B77  lda XIY,0x00e2a1
EEPROM_LoadCalibration__ret:
	pop	xix                                    ; FC8B7C  pop XIX
	popw	de                                    ; FC8B7D  pop DE
	popw	hl                                    ; FC8B7E  pop HL
	unlk32 xiz                                 ; FC8B7F  unlk XIZ
	ret                                        ; FC8B81  ret
; --------------------------------------------------------------------------
; EEPROM_WriteIndexPattern -- write word n with the value n, for n = 0..0x1E.
;
; Called from: ⚠ NOT FOUND -- no literal reference and no calr displacement
;              anywhere in prom_c (prom_c_xrefs.py 0xFC8B82).  A searched
;              negative: short PC-relative forms are not searched.
; Inputs:  none.  Outputs: 31 EEPROM words overwritten.
; Evidence: EWEN, then 0x1F passes of {push HL, push HL, call EEPROM_WriteWord,
;           inc HL} with the loop guard `cp HL,0x001F / jr C`, then EWDS.  Both
;           pushes are HL, and EEPROM_WriteWord's own code says which slot is
;           which, so word n gets the value n.
;           ★ IT DOES NOT WRITE WORD 0x1F OR WORD 0x20.  A block left by this
;           routine therefore FAILS EEPROM_LoadCalibration's checksum test (the
;           sum of 0..30 is 465, and nothing stores it) and its magic test.  So
;           whatever this is for, it is not "write a valid calibration".
; Unknown:  ⚠ what it IS for.  Writing an index pattern and then leaving the block
;           invalid is what a production test or a deliberate erase looks like;
;           with no caller found, which of those is NOT ESTABLISHED, and the name
;           says only what the code does.
; --------------------------------------------------------------------------
EEPROM_WriteIndexPattern:
	pushw	hl                                   ; FC8B82  push HL
	calr (0xFC89C5 - 0xFC8B86)                 ; FC8B83  calr 0xfc89c5
	ldw	hl, 0                                  ; FC8B86  ld HL,0x0000
EEPROM_WriteIndexPattern__word:
	pushw	hl                                   ; FC8B89  push HL
	pushw	hl                                   ; FC8B8A  push HL
	calr (0xFC8A62 - 0xFC8B8E)                 ; FC8B8B  calr 0xfc8a62
	inc	1, hl                                  ; FC8B8E  inc 1,HL
	pop	xiy                                    ; FC8B90  pop XIY
	cp	hl, 31                                  ; FC8B91  cp HL,0x001f
	jr c, EEPROM_WriteIndexPattern__word       ; FC8B95  jr C,0xfc8b89
	calr (0xFC89F7 - 0xFC8B9A)                 ; FC8B97  calr 0xfc89f7
	popw	hl                                    ; FC8B9A  pop HL
	ret                                        ; FC8B9B  ret
; --------------------------------------------------------------------------
; EEPROM_PortInit -- park CS, SK and DI low, then wait 6,000 counts.
;
; Called from: MAIN's power-on init chain, `call 0xFC8B9C` at 0xF98B89 -- the
;              third of its twelve init calls.  The only site.
; Inputs:  none.  Outputs: P6 bit 5, P8 bit 3 and P8 bit 4 all cleared.
; Evidence: the three `res` instructions are exactly the three pins the driver
;          above drives, and nothing else in the routine touches a port.  The
;          delay is `ldw hl,0x1770` counted down to zero -- 6,000 passes.
;          That it runs before any EEPROM access is the ordering in MAIN: this is
;          call 3, and EEPROM_LoadCalibration is reached from call 7
;          (0xF997FA, NoteTrim_BuildFromCalibration).
; Unknown:  how long 6,000 passes is; no cycle counts are available here.  A
;          power-on settling delay is the obvious reading and is not proved.
; --------------------------------------------------------------------------
EEPROM_PortInit:
	pushw	hl                                   ; FC8B9C  push HL
	res_dd8	5, P6                              ; FC8B9D  res 5,(0x12)
	res_dd8	3, P8                              ; FC8BA0  res 3,(0x18)
	res_dd8	4, P8                              ; FC8BA3  res 4,(0x18)
	ldw	hl, 0x1770                             ; FC8BA6  ld HL,0x1770
EEPROM_PortInit__delay:
	dec	1, hl                                  ; FC8BA9  dec 1,HL
	cp	hl, 0:i3                                  ; FC8BAB  cp HL,0
	jr nz, EEPROM_PortInit__delay              ; FC8BAD  jr NZ,0xfc8ba9
	popw	hl                                    ; FC8BAF  pop HL
	ret                                        ; FC8BB0  ret
; --------------------------------------------------------------------------
; EEPROM_Pad_Ret -- one 0x0E byte between this module and the next.
; 0x0E is the RET opcode and this file's padding byte (the 3,611-byte run at
; 0xFFF0E5 is the same value).  Nothing reaches it: the routine above ends in its
; own `ret` at 0xFC8BB0, and 0xFC8BB2 is a `link` -- a fresh frame, i.e. a
; function entry, not a fall-through target.  Emitted as an instruction rather
; than a `.byte` only so the disassembly stays continuous.
; --------------------------------------------------------------------------
EEPROM_Pad_Ret:
	ret                                        ; FC8BB1  ret
