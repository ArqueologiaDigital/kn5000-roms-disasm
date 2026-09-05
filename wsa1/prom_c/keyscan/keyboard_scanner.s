; ==============================================================================
; Technics SX-WSA1R -- prom_c (CPU 2, IC28) -- 0xF9973D-0xF99BBD  the keyboard scanner at 0x00108000, and the per-note trim
; ==============================================================================
;
; 976 lines moved out of prom_c/wsa1_prom_c.s by notes/prom_c_split.py.  The master
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
; Banner-declared.  KeyScan_*, NoteTrim_* and the Link_* senders that carry
; each key event out.
;
; >>> END OF EXTRACTION HEADER -- everything below is verbatim from the master

; ==============================================================================
; 0xF9973D-0xF99BBD -- THE KEYBOARD SCANNER at 0x00108000, the per-note touch
;                      calibration, and CPU 2's half of the link TRANSMITTER
;                      10 routines, 1,153 bytes
; ==============================================================================
;
; ★★ 0x00108000 IS THE KEY-SCAN PORT, AND ITS 16-BIT WORD IS {touch, key event}.
; notes/FINDINGS-memory-map.md lists 0x108000 as "same shape" as the other two
; address/data devices with the note "Three sites, not five: 0xF9914D, 0xF99776,
; 0xF998C6".  Two of those three are in this block, and they settle what the port
; carries -- not by resemblance, but because the word they read is handed
; STRAIGHT to a routine whose argument meanings are already converted:
;
;     +2  read  a status word.  Bit 0 gates everything: KeyScan_ReadEvent returns
;               "no event" unless it is set (0xF9976F `and BC,0x0001`).  The whole
;               word is separately compared against 2 (0xF9979A).
;     +0  read  one key event, 16 bits:
;                   low  byte  bit 7 = note ON, bits 6..0 = key number
;                   high byte  the touch measurement
;
; The low/high split is READ OFF THE CALL, not guessed.  Both call sites push the
; two bytes as the first two arguments of ToneGen_VelocityFromTouch (0xF995DF,
; converted above), whose own header -- written before this block existed --
; already says (XIZ+0x08) is "the touch measurement, index into
; ToneGen_Velocity_Input_Curve" and (XIZ+0x0a) is "bit 7 = note ON, bits 6..0 =
; note number".  The argument that lands in each slot follows from the push
; widths, and those are cited: `push #imm8` (0x09) and `push (mem)` in byte size
; (0x8E .. 0x04) each move ONE byte -- op_PUSHBI and op_PUSHBM in
; mame/src/devices/cpu/tlcs900/900tbl.hxx:2935-2946 -- so each
; `push 0x00 / push (XIZ+d)` PAIR builds one zero-extended 16-bit argument, and
; the pair pushed LAST is the one at (XIZ+0x08).  The caller drops 12 bytes
; afterwards (`inc 8,xsp` + `inc 4,xsp`), which is exactly 4+4+1+1+1+1.
;
; ★ THE KEYBOARD HAS 61 KEYS, AND THE NUMBER COMES OUT TWICE.
;   * KeyScan_InitKeyStateBitmap folds each event into a bit at
;     base[(key>>3)&7] bit (key&7) -- an EIGHT-byte bitmap, so 64 bit positions.
;   * NoteTrim_BuildFromCalibration walks note 0..0x3C inclusive -- `cp
;     (XIZ-2),0x003D / jr GE` -- which is 61 notes, and it is the SAME index that
;     ToneGen_VelocityFromTouch uses to read 0x0084DA.
;   61 keys in a 64-bit map is what a 61-key instrument needs; 64 would fit
;   exactly and 61 is what the firmware actually walks.  Stated as read.
;
; ★★ THE ORIGIN OF THE PER-NOTE TRIM TABLE AT 0x0084DA IS NOW KNOWN.
; notes/FINDINGS-prom_c-voice-tables.md §3 ends with "find what writes the signed
; per-note table at 0x0084DA.  It is the only term of the velocity formula whose
; origin is unknown".  NoteTrim_BuildFromCalibration (0xF997FA) is the writer, and
; it is the ONLY one.  `python3 notes/prom_c_xrefs.py 0x0084DA --no-window
; --classify` reports THREE literal-addressed sites in the whole image, and the
; instruction each one belongs to starts two bytes before the literal it prints:
; 0xF99829 and 0xF9987F -- both `add XBC,0x000084DA` in this block, each feeding
; a WRITE -- and 0xF9964D, the `add XWA,0x000084DA` inside
; ToneGen_VelocityFromTouch that feeds its only READ.  The rule is
;
;     trim[note] = ToneGen_VelCurve_Trim51[ clamp(cal[note] - 0x4B, 0, 50) ]
;
; with ToneGen_VelCurve_Trim51 at ROM 0xFCC5C9 (already emitted in the zone-2
; listing below) and cal[] the byte array returned by
; 0xFC8B0B; if that routine returns a null pointer, all 61 trims are set to zero.
;
; ★ AND IT CONFIRMS ToneGen_VelCurve_Trim51 FROM THE CODE SIDE.
; ⚠ RETRACTION, SAME SESSION: an earlier draft of this header said the table at
; 0xFCC5C9 was "unidentified" and claimed to decode it.  It was NOT unidentified --
; the zone-2 listing further down this file already emits it as
; ToneGen_VelCurve_Trim51, 51 bytes, sized by the object chain.  What this pass
; actually adds is the INDEPENDENT confirmation and the purpose:
;   * the clamp here is `cp A,0 / jr GE` then `cp (XIZ-7),0x32 / jr LE`, so the
;     index range is exactly 0..0x32 = 51 values -- the code's own bound agrees
;     with the size the data chain gave, which it did not have to;
;   * the curve is what turns a per-note CALIBRATION byte into the signed velocity
;     trim at 0x0084DA, which is what the table is FOR.
; 0xFCC5C9 + 51 = 0xFCC5FC, which is where ToneGen_VelCurve_ModeParams begins.
;
; ★ 0xFCC81A IS NOT THE START OF A FLOAT POOL.  The zone-2 text in this file
; leaves 0xFCC81A-0xFCCA81 as a deliberate `.incbin`, calling it "an IEEE-754
; constant pool ... the element boundaries are not established".  Its FIRST FOUR
; BYTES are not a float: they are `f0 ff 00 00` = the 32-bit constant 0x0000FFF0,
; and all three references to 0xFCC81A in the image are the same instruction,
; `add XBC,(0xFCC81A)` (0xF998AA, 0xF99910, 0xF99930), adding it to a 0..7 index.
; So bytes 0..3 of that block are the BASE OF THE KEY-STATE BITMAP, at work DRAM
; 0x0000FFF0-0x0000FFF7.  The remaining 612 bytes are untouched by this pass.
; ⚠ 0x0000FFF0 occurs as a 32-bit literal in exactly three places in prom_c --
; 0xF980EE (EntryPoint_Records' second column), 0xFCC81A (here) and 0xFFF007
; (RESET's `ld XSP,0x0000FFF0`).  The boot stack and the key bitmap are therefore
; the SAME eight bytes at two different times: RESET's stack is moved down to
; 0x0000FA00 at 0xF9816B before MAIN runs, and the bitmap is not built until
; MAIN's init chain reaches 0xF997FA.  Nothing here says the two uses were meant
; to overlap; they are recorded because they do.
; ⚠ And nothing in prom_c READS the bitmap by literal address.  The three sites
; above are its only literal-addressed users and all three are writes.  A reader
; through a pointer would be invisible to that census, so this is "no
; literal-addressed reader", not "nobody reads it".
;
; ★ TIMER 2 IS THE BYTE CLOCK OF THE OUTBOUND LINK.  Link_Init stops timer 2
; (`res 2,(TRUN)`), programs T23MOD = 0x0E and TREG2 = 5, and arms micro-DMA
; channel 2 on it; every one of the four senders below ends with
; `ldio DMA2V,0x12` + `set 2,(TRUN)`.  0x12 << 2 = 0x48 = INTT2
; (tmp95c061.cpp:353 and the vector map at :322-346), so each timer-2 tick moves
; one byte out of the packet buffer into the port at 0x00100000 and the CPU is
; not involved until INTTC2.  This is the transmit mirror of the receive path
; already documented in notes/FINDINGS-prom_c-link-receive.md.
;
; ⚠ WHAT THIS BLOCK DOES NOT ESTABLISH.  What the status word's value 2 means; the
; physical unit of the touch byte; what 0xFC8B0B reads its 62-byte block FROM;
; what 0x008517, 0x008535-0x008537 and 0x00852B are beyond the one bit each site
; touches.
;
; Transcribed with notes/llvm_roundtrip_autoforce.py c 0xF9973D 0x481, restyled by
; notes/prom_c_listing_prep.py and re-proved before insertion with
; `python3 notes/prom_c_verify_fragment.py c 0xF9973D <file>`.

; --------------------------------------------------------------------------
; KeyScan_ReadEvent -- take ONE key event off the scanner at 0x00108000 and turn
;             it into a note number and a velocity.
;
; Called from: 0xF98CD4 and 0xF98D0F, both `call 0xF9973D`.  Both sites are inside
;          KeyEvents_ToLink, which MAIN calls on every pass.
; Inputs:  none.
;          ⚠ THE TWO ADDRESSES ABOVE ARE INSTRUCTION STARTS, NOT LITERAL STARTS.
;          `notes/prom_c_xrefs.py 0xF9973D` prints the 24-bit literals, one byte
;          later, and copying ITS addresses into a header is this tree's single
;          most repeated documentation defect.  The enclosing routine begins at
;          0xF98CB9.  Those three addresses are named here and not in
;          `Called from:` because prom_c_audit_callsites.py classifies an address
;          one byte past a real site as OFF-BY-N -- correctly, since it cannot see
;          that the prose meant the literal.
; Inputs:  (XIZ+0x08) ptr, receives the note number.
;          (XIZ+0x0c) ptr, receives the velocity byte.
;          Device: 0x00108002 status, 0x00108000 event.  Global: 0x00F329.
; Outputs: WA = 0 if an event was decoded, 0xFFFF if not.  *(XIZ+0x08) and
;          *(XIZ+0x0c) are written by ToneGen_VelocityFromTouch, which this
;          routine calls with the two device bytes.
; Evidence: the argument-to-slot mapping and the port layout are derived in the
;          block comment above, from the push widths cited there.  The two
;          pointer arguments are passed straight through: the routine pushes
;          (XIZ+0x0c) FIRST and (XIZ+0x08) second, and the callee's converted
;          header says its (XIZ+0x10) receives the velocity and its (XIZ+0x0c)
;          the note -- so this routine's +0x08 is the note pointer and its +0x0c
;          the velocity pointer.
; ★ THE SCANNER IS NOT READ FOR THE FIRST 1000 TICKS.  While (0x00F329) is zero
;          the routine returns 0xFFFF without touching the device, and it only
;          sets that byte once the INTT1 tick counter at 0x00F2F3 has passed
;          0x3E8 = 1000 (`cp XBC,0x000003E8 / jr ULE`).  0x00F329 is written by
;          exactly one instruction in the image and read by exactly one
;          (notes/prom_c_xrefs.py 0x00F329), both of them here, so this is a
;          one-shot arming latch and nothing else can clear it.
;          ⚠ The tick RATE is still not established (see the INTT1 header), so
;          1000 ticks cannot be turned into milliseconds.
; ★ THE THREE OUTCOMES, read off the branches at 0xF99795-0xF997B4:
;          (a) touch byte != 0xFF and status word != 2  -> decode normally.
;          (b) touch byte == 0xFF, or status word == 2:
;                 note ON  -> `or (0x008517),0x03`, return 0xFFFF, event dropped;
;                 note OFF -> decode, then FORCE the velocity byte to 0.
;          ⚠ "touch byte == 0xFF means no travel time was measured" fits (b) --
;          a note-on with no touch value cannot be given a velocity, a note-off
;          does not need one -- but nothing here proves it and 0x008517 is
;          referenced by this one instruction alone in the whole image, so what
;          collects the two bits is unknown.
; Unknown:  the meaning of status-word value 2; who reads 0x008517.
; --------------------------------------------------------------------------
KeyScan_ReadEvent:
	link32 0xEE, 0x0C, 0xFA, 0xFF          ; F9973D  link XIZ,0xfffa   [llvm-mc cannot encode this]
	cp (0x00F329:24), 0x00                 ; F99741  cp (0x00f329),0x00   [llvm-mc cannot encode this]
	jr nz, KeyScan_ReadEvent__F99762                       ; F99747  jr NZ,0xf99762
	ld	xbc, (0xF2F3:24)                   ; F99749  ld XBC,(0x00f2f3)
	cp	xbc, 0x3E8                          ; F9974E  cp XBC,0x000003e8
	jr ule, KeyScan_ReadEvent__F9975C                      ; F99754  jr ULE,0xf9975c
	ld	(0xF329:24), 1                    ; F99756  ld (0x00f329),0x01
KeyScan_ReadEvent__F9975C:
	ldw	wa, 0xFFFF                         ; F9975C  ld WA,0xffff
	jrl KeyScan_ReadEvent__F997F7                          ; F9975F  jrl T,0xf997f7
KeyScan_ReadEvent__F99762:
	ld	xbc, 0x108002                       ; F99762  ld XBC,0x00108002
	ld	wa, (xbc)                           ; F99767  ld WA,(XBC)
	ld	(xiz-6), wa                         ; F99769  ld (XIZ+0xfa),WA
	ld	bc, (xiz-6)                         ; F9976C  ld BC,(XIZ+0xfa)
	and	bc, 1                              ; F9976F  and BC,0x0001
	jrl z, KeyScan_ReadEvent__F997F4                       ; F99773  jrl Z,0xf997f4
	ld	xbc, 0x108000                       ; F99776  ld XBC,0x00108000
	ld	wa, (xbc)                           ; F9977B  ld WA,(XBC)
	ld	(xiz-4), wa                         ; F9977D  ld (XIZ+0xfc),WA
	ld	c, (xiz-4)                          ; F99780  ld C,(XIZ+0xfc)
	and	c, 0xFF                            ; F99783  and C,0xff
	ld	(xiz-1), c                          ; F99786  ld (XIZ+0xff),C
	ld	bc, (xiz-4)                         ; F99789  ld BC,(XIZ+0xfc)
	srl	bc, 8                              ; F9978C  srl 0x08,BC
	and	c, 0xFF                            ; F9978F  and C,0xff
	ld	(xiz-2), c                          ; F99792  ld (XIZ+0xfe),C
	cp	c, 0xFF                             ; F99795  cp C,0xff
	jr z, KeyScan_ReadEvent__F997A1                        ; F99798  jr Z,0xf997a1
	cpw (xiz-6), 0x0002                    ; F9979A  cp (XIZ+0xfa),0x0002   [llvm-mc cannot encode this]
	jr nz, KeyScan_ReadEvent__F997D7                       ; F9979F  jr NZ,0xf997d7
KeyScan_ReadEvent__F997A1:
	ld	c, (xiz-1)                          ; F997A1  ld C,(XIZ+0xff)
	and	c, 0x80                            ; F997A4  and C,0x80
	jr z, KeyScan_ReadEvent__F997B6                        ; F997A7  jr Z,0xf997b6
	extpfx6 0xC2, 0x17, 0x85, 0x00, 0x3E, 0x03 ; F997A9  or (0x008517),0x03   [llvm-mc cannot encode this]
	ldw	wa, 0xFFFF                         ; F997AF  ld WA,0xffff
	jr KeyScan_ReadEvent__F997F7                           ; F997B2  jr T,0xf997f7
	jr KeyScan_ReadEvent__F997D5                           ; F997B4  jr T,0xf997d5
KeyScan_ReadEvent__F997B6:
	ld	xbc, (xiz+12)                       ; F997B6  ld XBC,(XIZ+0x0c)
	push	xbc                               ; F997B9  push XBC
	ld	xwa, (xiz+8)                        ; F997BA  ld XWA,(XIZ+0x08)
	push	xwa                               ; F997BD  push XWA
	push	0                                 ; F997BE  push 0x00
	extpfx3 0x8E, 0xFF, 0x04               ; F997C0  push (XIZ+0xff)   [llvm-mc cannot encode this]
	push	0                                 ; F997C3  push 0x00
	extpfx3 0x8E, 0xFE, 0x04               ; F997C5  push (XIZ+0xfe)   [llvm-mc cannot encode this]
	calr (0xF995DF - 0xF997CB)             ; F997C8  calr 0xf995df
	ld	xbc, (xiz+12)                       ; F997CB  ld XBC,(XIZ+0x0c)
	ld	(xbc), 0                            ; F997CE  ld (XBC),0x00
	inc	8, xsp                             ; F997D1  inc 0,XSP
	inc	4, xsp                             ; F997D3  inc 4,XSP
KeyScan_ReadEvent__F997D5:
	jr KeyScan_ReadEvent__F997F0                           ; F997D5  jr T,0xf997f0
KeyScan_ReadEvent__F997D7:
	ld	xbc, (xiz+12)                       ; F997D7  ld XBC,(XIZ+0x0c)
	push	xbc                               ; F997DA  push XBC
	ld	xwa, (xiz+8)                        ; F997DB  ld XWA,(XIZ+0x08)
	push	xwa                               ; F997DE  push XWA
	push	0                                 ; F997DF  push 0x00
	extpfx3 0x8E, 0xFF, 0x04               ; F997E1  push (XIZ+0xff)   [llvm-mc cannot encode this]
	push	0                                 ; F997E4  push 0x00
	extpfx3 0x8E, 0xFE, 0x04               ; F997E6  push (XIZ+0xfe)   [llvm-mc cannot encode this]
	calr (0xF995DF - 0xF997EC)             ; F997E9  calr 0xf995df
	inc	8, xsp                             ; F997EC  inc 0,XSP
	inc	4, xsp                             ; F997EE  inc 4,XSP
KeyScan_ReadEvent__F997F0:
	sub	wa, wa                             ; F997F0  sub WA,WA
	jr KeyScan_ReadEvent__F997F7                           ; F997F2  jr T,0xf997f7
KeyScan_ReadEvent__F997F4:
	ldw	wa, 0xFFFF                         ; F997F4  ld WA,0xffff
KeyScan_ReadEvent__F997F7:
	unlk32 xiz                             ; F997F7  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F997F9  ret

; --------------------------------------------------------------------------
; NoteTrim_BuildFromCalibration -- fill the 61-entry signed per-note velocity trim
;             table at 0x0084DA from a checksummed calibration block.
;
; Called from: 0xF98B99 (`call 0xF997FA`), in MAIN's power-on init chain -- the
;          same chain that calls DSP_ChannelRegs_Init and Link_Init.  One site.
; Inputs:  none.  It calls KeyScan_InitKeyStateBitmap first, then 0xFC8B0B.
; Outputs: 0x0084DA[0..0x3C], 61 signed bytes.
; Evidence: ★ 0xFC8B0B RETURNS ITS ANSWER IN XIY, and the branch here is
;          `cp XIY,0x00000000 / jr NZ`, so a null return is a defined case: the
;          zero arm writes 0 to all 61 entries and returns.  The non-null arm
;          reads `cal[i] = (XIY)[i]`, subtracts 0x4B = 75, clamps the result to
;          0..0x32 = 0..50, and uses it to index the signed byte curve at ROM
;          0xFCC5C9, storing the looked-up byte at 0x0084DA + i.
;          ★ THE ENTRY COUNT IS 61 AND THE LAST ENTRY IS THE TEST.  The loop
;          guard is `cp (XIZ-2),0x003D / jr GE,done`, so i runs 0..0x3C
;          inclusive; entry 0x3C is written by the same instruction as entry 0
;          and is inside the same guard.  61 is also the count
;          ToneGen_VelocityFromTouch can reach, because it indexes 0x0084DA with
;          `note & 0x7F` and the scanner's key numbers are what fill that field.
;          ★ THE 51-ENTRY CURVE IS BOUNDED BY THE CLAMP.  0..0x32 is 51 values
;          and 0xFCC5C9 + 51 = 0xFCC5FC, exactly where
;          ToneGen_VelCurve_ModeParams starts (see the zone-2 chain below).  So
;          the code's bound and the data's next-object boundary agree without
;          either being assumed from the other.
;          ★ 0xFC8B0B IS NOW CONVERTED, and it is EEPROM_LoadCalibration: the
;          62-byte block, its trailing checksum word and its 0x5AA5 magic are read
;          out of a MICROWIRE SERIAL EEPROM, bit-banged on P6 bit 5 (CS), P8 bit 3
;          (SK), P8 bit 4 (DI) and P8 bit 5 (DO).  See the block comment at
;          0xFC89C5.  The old wording -- "WHERE it is read from is not established
;          here" -- is answered; the rest of this header stands unchanged.
; Unknown:  the physical meaning of the 75 that is subtracted (the curve is zero
;          for cal values 0x61..0x65).  ⚠ And nothing in prom_c ever WRITES a
;          valid calibration: the image's only EEPROM writer,
;          EEPROM_WriteIndexPattern, writes word n = n and does not write the
;          checksum or the magic, so a block it produced would fail this test.
; --------------------------------------------------------------------------
NoteTrim_BuildFromCalibration:
	link32 0xEE, 0x0C, 0xF9, 0xFF          ; F997FA  link XIZ,0xfff9   [llvm-mc cannot encode this]
	pushw	hl                               ; F997FE  push HL
	calr (0xF9988D - 0xF99802)             ; F997FF  calr 0xf9988d
	call	0xFC8B0B                          ; F99802  call 0xfc8b0b
	ld	(xiz-6), xiy                        ; F99806  ld (XIZ+0xfa),XIY
	cp	xiy, 0                              ; F99809  cp XIY,0x00000000
	jr nz, NoteTrim_BuildFromCalibration__F99836                       ; F9980F  jr NZ,0xf99836
	ldw (xiz-2), 0x0000                    ; F99811  ld (XIZ+0xfe),0x0000   [llvm-mc cannot encode this]
NoteTrim_BuildFromCalibration__F99816:
	cpw (xiz-2), 0x003D                    ; F99816  cp (XIZ+0xfe),0x003d   [llvm-mc cannot encode this]
	jr ge, NoteTrim_BuildFromCalibration__F99834                       ; F9981B  jr GE,0xf99834
	jr NoteTrim_BuildFromCalibration__F99824                           ; F9981D  jr T,0xf99824
NoteTrim_BuildFromCalibration__F9981F:
	incw	1, (xiz-2)                        ; F9981F  incw 1,(XIZ+0xfe)
	jr NoteTrim_BuildFromCalibration__F99816                           ; F99822  jr T,0xf99816
NoteTrim_BuildFromCalibration__F99824:
	ld	bc, (xiz-2)                         ; F99824  ld BC,(XIZ+0xfe)
	exts	xbc                               ; F99827  exts XBC
	add	xbc, 0x84DA                        ; F99829  add XBC,0x000084da
	ld	(xbc), 0                            ; F9982F  ld (XBC),0x00
	jr NoteTrim_BuildFromCalibration__F9981F                           ; F99832  jr T,0xf9981f
NoteTrim_BuildFromCalibration__F99834:
	jr NoteTrim_BuildFromCalibration__F99889                           ; F99834  jr T,0xf99889
NoteTrim_BuildFromCalibration__F99836:
	ldw (xiz-2), 0x0000                    ; F99836  ld (XIZ+0xfe),0x0000   [llvm-mc cannot encode this]
NoteTrim_BuildFromCalibration__F9983B:
	cpw (xiz-2), 0x003D                    ; F9983B  cp (XIZ+0xfe),0x003d   [llvm-mc cannot encode this]
	jr ge, NoteTrim_BuildFromCalibration__F99889                       ; F99840  jr GE,0xf99889
	jr NoteTrim_BuildFromCalibration__F99849                           ; F99842  jr T,0xf99849
NoteTrim_BuildFromCalibration__F99844:
	incw	1, (xiz-2)                        ; F99844  incw 1,(XIZ+0xfe)
	jr NoteTrim_BuildFromCalibration__F9983B                           ; F99847  jr T,0xf9983b
NoteTrim_BuildFromCalibration__F99849:
	ld	bc, (xiz-2)                         ; F99849  ld BC,(XIZ+0xfe)
	exts	xbc                               ; F9984C  exts XBC
	extpfx3 0xAE, 0xFA, 0x81               ; F9984E  add XBC,(XIZ+0xfa)   [llvm-mc cannot encode this]
	ld	a, (xbc)                            ; F99851  ld A,(XBC)
	sub	a, 75                              ; F99853  sub A,0x4b
	ld	(xiz-7), a                          ; F99856  ld (XIZ+0xf9),A
	cp	a, 0:i3                               ; F99859  cp A,0
	jr ge, NoteTrim_BuildFromCalibration__F99861                       ; F9985B  jr GE,0xf99861
	ld	(xiz-7), 0                          ; F9985D  ld (XIZ+0xf9),0x00
NoteTrim_BuildFromCalibration__F99861:
	cp (xiz-7), 0x32                       ; F99861  cp (XIZ+0xf9),0x32   [llvm-mc cannot encode this]
	jr le, NoteTrim_BuildFromCalibration__F9986B                       ; F99865  jr LE,0xf9986b
	ld	(xiz-7), 50                         ; F99867  ld (XIZ+0xf9),0x32
NoteTrim_BuildFromCalibration__F9986B:
	ld	bc, (xiz-7)                         ; F9986B  ld BC,(XIZ+0xf9)
	exts	bc                                ; F9986E  exts BC
	exts	xbc                               ; F99870  exts XBC
	add	xbc, 0xFCC5C9                      ; F99872  add XBC,0x00fcc5c9
	ld	h, (xbc)                            ; F99878  ld H,(XBC)
	ld	bc, (xiz-2)                         ; F9987A  ld BC,(XIZ+0xfe)
	exts	xbc                               ; F9987D  exts XBC
	add	xbc, 0x84DA                        ; F9987F  add XBC,0x000084da
	ld	(xbc), h                            ; F99885  ld (XBC),H
	jr NoteTrim_BuildFromCalibration__F99844                           ; F99887  jr T,0xf99844
NoteTrim_BuildFromCalibration__F99889:
	popw	hl                                ; F99889  pop HL
	unlk32 xiz                             ; F9988A  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F9988C  ret

; --------------------------------------------------------------------------
; KeyScan_InitKeyStateBitmap -- clear the 8-byte key-state bitmap and fold the
;             next SIXTEEN scanner events into it.
;
; Called from: 0xF997FF, the `calr 0xF9988D` inside NoteTrim_BuildFromCalibration.
;          One site; notes/prom_c_xrefs.py 0xF9988D.
; Inputs:  the scanner at 0x00108000.  Base pointer: the 32-bit constant at ROM
;          0xFCC81A, which is 0x0000FFF0.
;          ⚠ CORRECTED 2026-08-25.  The `Called from:` line used to give the
;          CALLING ROUTINE'S ENTRY, 0xF997FA (`link XIZ,0xfff9`), five bytes before
;          the call, in the slot where a call site goes -- which is
;          indistinguishable from an off-by-five citation, and
;          notes/prom_c_audit_callsites.py now classifies it as one.  The caller is
;          named rather than numbered, and the number is stated here, outside the
;          paragraph that tool harvests.
; Outputs: 0x0000FFF0-0x0000FFF7, one bit per key.
; Evidence: two counted loops, both bounded by an UNSIGNED compare:
;          `cp (XIZ-7),0x08 / jr NC` clears eight bytes, and
;          `cp (XIZ-7),0x10 / jr NC` runs the body sixteen times.  The body reads
;          0x00108000 once per pass, splits the word exactly as
;          KeyScan_ReadEvent does, and computes byte = (low >> 3) & 7,
;          bit = low & 7 -- so eight bytes hold 64 bit positions and key numbers
;          above 63 would alias, which the 61-key walk in
;          NoteTrim_BuildFromCalibration says they never are.
;          ★ THE BIT MASK COMES FROM THE COMPILER'S SHIFT HELPER, and the helper
;          is decoded rather than assumed: 0xFCA0BA reads (XSP+4) into IY and the
;          BYTE at (XSP+6) into B, then does `sll A,IY` twice with A = B>>4 = 0
;          and A = B & 0x0F.  A shift count of ZERO on TLCS-900 means SIXTEEN --
;          `count = (s & 0x0f) ? (s & 0x0f) : 16` in
;          mame/src/devices/cpu/tlcs900/900tbl.hxx:990-992 -- which is what makes
;          the first `sll` the "count >= 16" arm and not a no-op.  Both call
;          sites here pass the value 1 and the count (key & 7), so A comes back
;          holding 1 << (key & 7): the note-on arm ORs it in, the note-off arm
;          complements it and ANDs.
;          ⚠ The note-on arm pushes WA whose high byte is the leftover
;          (low & 0x80); only the byte at (XSP+6) is read by the helper, so the
;          high half is dead.  Recorded because it looks like an argument and is
;          not one.
; Unknown:  ⚠ WHY SIXTEEN.  Nothing here bounds the scanner's queue; 16 is a
;          literal and the routine runs once, at boot.  Also: nothing in prom_c
;          reads the bitmap through a literal address (see the block comment), so
;          its consumer has not been found.
; --------------------------------------------------------------------------
KeyScan_InitKeyStateBitmap:
	link32 0xEE, 0x0C, 0xF9, 0xFF          ; F9988D  link XIZ,0xfff9   [llvm-mc cannot encode this]
	pushw	hl                               ; F99891  push HL
	ld	(xiz-7), 0                          ; F99892  ld (XIZ+0xf9),0x00
KeyScan_InitKeyStateBitmap__F99896:
	cp (xiz-7), 0x08                       ; F99896  cp (XIZ+0xf9),0x08   [llvm-mc cannot encode this]
	jr nc, KeyScan_InitKeyStateBitmap__F998B4                       ; F9989A  jr NC,0xf998b4
	jr KeyScan_InitKeyStateBitmap__F998A3                           ; F9989C  jr T,0xf998a3
KeyScan_InitKeyStateBitmap__F9989E:
	incm8	1, (xiz-7)                       ; F9989E  inc 1,(XIZ+0xf9)
	jr KeyScan_InitKeyStateBitmap__F99896                           ; F998A1  jr T,0xf99896
KeyScan_InitKeyStateBitmap__F998A3:
	ld	bc, (xiz-7)                         ; F998A3  ld BC,(XIZ+0xf9)
	extz	bc                                ; F998A6  extz BC
	extz	xbc                               ; F998A8  extz XBC
	add	xbc, (0xFCC81A:24)             ; F998AA  add XBC,(0xfcc81a)
	ld	(xbc), 0                            ; F998AF  ld (XBC),0x00
	jr KeyScan_InitKeyStateBitmap__F9989E                           ; F998B2  jr T,0xf9989e
KeyScan_InitKeyStateBitmap__F998B4:
	ld	(xiz-7), 0                          ; F998B4  ld (XIZ+0xf9),0x00
KeyScan_InitKeyStateBitmap__F998B8:
	cp (xiz-7), 0x10                       ; F998B8  cp (XIZ+0xf9),0x10   [llvm-mc cannot encode this]
	jrl nc, KeyScan_InitKeyStateBitmap__F99939                      ; F998BC  jrl NC,0xf99939
	jr KeyScan_InitKeyStateBitmap__F998C6                           ; F998BF  jr T,0xf998c6
KeyScan_InitKeyStateBitmap__F998C1:
	incm8	1, (xiz-7)                       ; F998C1  inc 1,(XIZ+0xf9)
	jr KeyScan_InitKeyStateBitmap__F998B8                           ; F998C4  jr T,0xf998b8
KeyScan_InitKeyStateBitmap__F998C6:
	ld	xbc, 0x108000                       ; F998C6  ld XBC,0x00108000
	ld	wa, (xbc)                           ; F998CB  ld WA,(XBC)
	ld	(xiz-6), wa                         ; F998CD  ld (XIZ+0xfa),WA
	and	a, 0xFF                            ; F998D0  and A,0xff
	ld	(xiz-1), a                          ; F998D3  ld (XIZ+0xff),A
	ld	bc, (xiz-6)                         ; F998D6  ld BC,(XIZ+0xfa)
	srl	bc, 8                              ; F998D9  srl 0x08,BC
	and	c, 0xFF                            ; F998DC  and C,0xff
	ld	(xiz-2), c                          ; F998DF  ld (XIZ+0xfe),C
	ld	b, (xiz-1)                          ; F998E2  ld B,(XIZ+0xff)
	srl	b, 3                               ; F998E5  srl 0x03,B
	and	b, 7                               ; F998E8  and B,0x07
	ld	(xiz-3), b                          ; F998EB  ld (XIZ+0xfd),B
	ld	a, (xiz-1)                          ; F998EE  ld A,(XIZ+0xff)
	and	a, 7                               ; F998F1  and A,0x07
	ld	(xiz-4), a                          ; F998F4  ld (XIZ+0xfc),A
	ld	w, (xiz-1)                          ; F998F7  ld W,(XIZ+0xff)
	and	w, 0x80                            ; F998FA  and W,0x80
	jr z, KeyScan_InitKeyStateBitmap__F99919                        ; F998FD  jr Z,0xf99919
	pushw	wa                               ; F998FF  push WA
	pushw	1                                ; F99900  push 0x0001
	call	0xFCA0BA                          ; F99903  call 0xfca0ba
	ld	h, a                                ; F99907  ld H,A
	ld	bc, (xiz-3)                         ; F99909  ld BC,(XIZ+0xfd)
	extz	bc                                ; F9990C  extz BC
	extz	xbc                               ; F9990E  extz XBC
	add	xbc, (0xFCC81A:24)             ; F99910  add XBC,(0xfcc81a)
	or	(xbc), a                            ; F99915  or (XBC),A
	jr KeyScan_InitKeyStateBitmap__F99937                           ; F99917  jr T,0xf99937
KeyScan_InitKeyStateBitmap__F99919:
	push	0                                 ; F99919  push 0x00
	extpfx3 0x8E, 0xFC, 0x04               ; F9991B  push (XIZ+0xfc)   [llvm-mc cannot encode this]
	pushw	1                                ; F9991E  push 0x0001
	call	0xFCA0BA                          ; F99921  call 0xfca0ba
	cpl	a                                  ; F99925  cpl A
	ld	h, a                                ; F99927  ld H,A
	ld	bc, (xiz-3)                         ; F99929  ld BC,(XIZ+0xfd)
	extz	bc                                ; F9992C  extz BC
	extz	xbc                               ; F9992E  extz XBC
	add	xbc, (0xFCC81A:24)             ; F99930  add XBC,(0xfcc81a)
	and	(xbc), a                           ; F99935  and (XBC),A
KeyScan_InitKeyStateBitmap__F99937:
	jr KeyScan_InitKeyStateBitmap__F998C1                           ; F99937  jr T,0xf998c1
KeyScan_InitKeyStateBitmap__F99939:
	popw	hl                                ; F99939  pop HL
	unlk32 xiz                             ; F9993A  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F9993C  ret

; --------------------------------------------------------------------------
; Link_ChannelHandler_Ignore -- the do-nothing handler for link channels 4-7.
;
; ⚠ RETRACTION, SAME SESSION.  The first version of this header said "a lone 0x0E
; `ret` ... Nothing in prom_c references it (notes/prom_c_xrefs.py 0xF9993D: no
; literal, no calr)".  That claim was written WITHOUT RUNNING THE TOOL.  Running
; it gives FOUR references:
;
;   $ python3 notes/prom_c_xrefs.py 0xF9993D --no-window
;     ABS32 at 0xFCC54F / 0xFCC553 / 0xFCC557 / 0xFCC55B
;     TOTAL literal-addressed sites: 4
;
; They are entries 4, 5, 6 and 7 of Link_ClassHandlerTable, whose own header
; further down THIS FILE already said so -- "the remaining four are all the SAME
; address, 0xF9993D, whose first byte is 0x0E = RET".  The byte gate passed either
; way; nothing but reading catches this.
;
; Called from: entries 4, 5, 6 and 7 of Link_ClassHandlerTable -- the ROM table
;          entries at 0xFCC54F/0xFCC553/0xFCC557/0xFCC55B, which is the whole of
;          `notes/prom_c_xrefs.py 0xF9993D --no-window`.  No instruction calls it.
; Inputs:  none.  Outputs: none.  It returns immediately, so a packet on channels
;          4-7 is received and discarded.
;          The dispatcher is INTTC3_HANDLER__state1_generic (0xF99D6F), which
;          indexes the table's RAM COPY at 0x00F334 by (link command byte >> 5).
;          ⚠ The address above is a VARIABLE, not a call site.  It is stated here rather than in `Called from:` because notes/prom_c_audit_callsites.py harvests every 0xXXXXXX in that paragraph and cannot tell prose from a citation.
; --------------------------------------------------------------------------
Link_ChannelHandler_Ignore:
	ret                                    ; F9993D  ret

; --------------------------------------------------------------------------
; Link_Init -- program timer 2 and BOTH micro-DMA channels of the CPU-1 link.
;
; Called from: 0xF98B8D (`call 0xF9993E`), MAIN's power-on init chain.  One site.
; Inputs:  none.  Outputs: TRUN, T23MOD, TREG2, INTET32, INTETC23, INTE0AD, the
;          three bytes 0x008535-0x008537, and micro-DMA channels 2 and 3.
; Evidence: ★ THIS IS THE ROUTINE notes/FINDINGS-prom_c-link-receive.md POINTS AT.
;          That note says "The channel's other half is programmed once, at
;          0xF99966-0xF99977: DMAS3 := 0x00100000, DMAM3 := 0x00" -- those two
;          instructions are the `push 0x0000 / push XIX / call 0xF9A012` at
;          0xF99970-0xF99974, because uDMA3_SetSource (converted below) writes
;          (XSP+4) to DMAS3 and (XSP+8) to DMAM3.  The channel-2 half is the pair
;          before it: `push 0x0008 / push XIX / call 0xF99FF8` = uDMA2_SetDest,
;          so DMAD2 := 0x00100000 and DMAM2 := 0x08.  Mode 0x08 is "byte
;          transfer, SOURCE incremented" and mode 0x00 is "byte transfer,
;          DESTINATION incremented" (tmp95c061.cpp:366-371 and :398-401), which is
;          exactly right for a walking buffer writing a fixed port and a fixed
;          port filling a walking buffer.
;          ★ TIMER 2 IS SET UP HERE AND STARTED BY THE SENDERS.  `res 2,(TRUN)`
;          stops it, T23MOD := 0x0E and TREG2 := 5 program it, and every sender
;          below finishes with `set 2,(TRUN)`.  Nothing else in the converted
;          code writes TREG2.
;          INTET32 := 0x00 disables the INTT2/INTT3 levels while this runs;
;          INTETC23 := 0x55 sets the INTTC2/INTTC3 levels; INTE0AD := 0x01 the
;          INT0 level -- names from include/tmp95c061_sfr.inc.
; Unknown:  the three bytes 0x008535-0x008537 zeroed at 0xF9994B-0xF9995D; the
;          exact level fields inside 0x55 and 0x01 (the register layout is not
;          decoded anywhere in this tree).
; --------------------------------------------------------------------------
Link_Init:
	push	xix                               ; F9993E  push XIX
	ldio	INTET32, 0                        ; F9993F  ld (0x74),0x00
	res_dd8	2, TRUN                        ; F99942  res 2,(0x20)
	ldio	T23MOD, 14                        ; F99945  ld (0x28),0x0e
	ldio	INTETC23, 85                      ; F99948  ld (0x7a),0x55
	ld	(0x8537:24), 0                    ; F9994B  ld (0x008537),0x00
	ld	(0x8535:24), 0                    ; F99951  ld (0x008535),0x00
	ld	(0x8536:24), 0                    ; F99957  ld (0x008536),0x00
	ldio	INTE0AD, 1                        ; F9995D  ld (0x70),0x01
	ldio	TREG2, 5                          ; F99960  ld (0x26),0x05
	pushw	8                                ; F99963  push 0x0008
	ld	xix, 0x100000                       ; F99966  ld XIX,0x00100000
	push	xix                               ; F9996B  push XIX
	call	0xF99FF8                          ; F9996C  call 0xf99ff8
	pushw	0                                ; F99970  push 0x0000
	push	xix                               ; F99973  push XIX
	call	0xF9A012                          ; F99974  call 0xf9a012
	inc	8, xsp                             ; F99978  inc 0,XSP
	inc	4, xsp                             ; F9997A  inc 4,XSP
	pop	xix                                ; F9997C  pop XIX
	ret                                    ; F9997D  ret

; --------------------------------------------------------------------------
; Link_SendBlock -- send a buffer of arbitrary length as 32-byte packets.
;
; Called from: 0xF98B30, 0xF98C00, 0xF98D48, 0xF98D8F -- four `call 0xF9997E`
;          sites (notes/prom_c_xrefs.py 0xF9997E).  Two of them are inside MAIN
;          and are already named in the MAIN listing above as the MIDI drain path.
; Inputs:  (XIZ+0x08) u16 channel number, (XIZ+0x0a) u16 length,
;          (XIZ+0x0c) ptr buffer.
; Outputs: one call to Link_SendChunk per packet.
; Evidence: the loop is `cp HL,0x0020 / jr UGT` with HL = the remaining length:
;          while more than 32 bytes remain it sends exactly 0x20 and advances the
;          pointer by 0x20, and it always finishes with ONE more call carrying
;          the remainder in C (`ld C,L`).  So a length that is an exact multiple
;          of 32 still ends with a zero-length call -- read off the code, not
;          smoothed over.  32 is the largest length the header byte can express:
;          notes/FINDINGS-memory-map.md gives the header as
;          `(channel << 5) | (len - 1)`, and len-1 has five bits.
; Unknown:  which channel numbers the four callers use.
; --------------------------------------------------------------------------
Link_SendBlock:
	link32 0xEE, 0x0C, 0x00, 0x00          ; F9997E  link XIZ,0x0000   [llvm-mc cannot encode this]
	pushw	hl                               ; F99982  push HL
	push	xix                               ; F99983  push XIX
	ld	xix, (xiz+12)                       ; F99984  ld XIX,(XIZ+0x0c)
	ld	hl, (xiz+10)                        ; F99987  ld HL,(XIZ+0x0a)
	jr Link_SendBlock__F999A5                           ; F9998A  jr T,0xf999a5
Link_SendBlock__F9998C:
	push	xix                               ; F9998C  push XIX
	pushw	32                               ; F9998D  push 0x0020
	push	0                                 ; F99990  push 0x00
	extpfx3 0x8E, 0x08, 0x04               ; F99992  push (XIZ+0x08)   [llvm-mc cannot encode this]
	calr (0xF999BE - 0xF99998)             ; F99995  calr 0xf999be
	add	xix, 32                            ; F99998  add XIX,0x00000020
	ldw	bc, 32                             ; F9999E  ld BC,0x0020
	sub	hl, bc                             ; F999A1  sub HL,BC
	inc	8, xsp                             ; F999A3  inc 0,XSP
Link_SendBlock__F999A5:
	cp	hl, 32                              ; F999A5  cp HL,0x0020
	jr ugt, Link_SendBlock__F9998C                      ; F999A9  jr UGT,0xf9998c
	push	xix                               ; F999AB  push XIX
	ld	c, l                                ; F999AC  ld C,L
	pushw	bc                               ; F999AE  push BC
	push	0                                 ; F999AF  push 0x00
	extpfx3 0x8E, 0x08, 0x04               ; F999B1  push (XIZ+0x08)   [llvm-mc cannot encode this]
	calr (0xF999BE - 0xF999B7)             ; F999B4  calr 0xf999be
	inc	8, xsp                             ; F999B7  inc 0,XSP
	pop	xix                                ; F999B9  pop XIX
	popw	hl                                ; F999BA  pop HL
	unlk32 xiz                             ; F999BB  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F999BD  ret

; --------------------------------------------------------------------------
; Link_SendChunk -- send ONE packet: header byte by hand, payload by micro-DMA.
;
; Called from: Link_SendBlock, two calr sites (the instructions at 0xF99995 and
;          0xF999B4).
; Inputs:  (XIZ+0x08) u16 channel, (XIZ+0x0a) u16 length, (XIZ+0x0c) ptr payload.
; Outputs: the header byte at 0x00100000, then `length` payload bytes moved by
;          micro-DMA channel 2; (0x00F32C) := 1 for the duration.
; Evidence: ★ THE HEADER BYTE IS BUILT HERE AND IT IS THE ONE THE MEMORY MAP
;          ALREADY RECORDS.  `ld L,H / dec 1,L / ld C,(XIZ+0x08) / sll 0x05,C /
;          or C,L` is (channel << 5) | (len - 1), which is
;          notes/FINDINGS-memory-map.md §3's format, now read off the SENDER
;          rather than inferred.  A length of 0 is rejected up front
;          (`cp H,0 / jrl Z,exit`), which is why `len - 1` never underflows.
;          The handshake is the one §3 tabulates: wait for PA bit 3, drop PA
;          bit 0, write the byte, wait for PA bit 3 again, raise PA bit 0.  Both
;          waits are bounded by 0x4E20 = 20000 spins and both time out by raising
;          PA bit 0 and returning.
;          The payload goes out through uDMA2_SetSource(payload, length) followed
;          by `ldio DMA2V,0x12` and `set 2,(TRUN)`: 0x12 << 2 = 0x48 = INTT2
;          (tmp95c061.cpp:353), so timer 2 clocks the bytes.  The routine then
;          spins on (0x00F32C) until the completion path clears it.
; Unknown:  ⚠ the busy flag 0x00F32C is written with 0, 1 and 2 across the image
;          (16 literal-addressed sites, notes/prom_c_xrefs.py 0x00F32C); 1 and 2
;          are set by different senders and both are compared against by
;          INTTC2_HANDLER at 0xF99D01/0xF99D11.  What distinguishes them is not
;          established here.
; --------------------------------------------------------------------------
Link_SendChunk:
	link32 0xEE, 0x0C, 0xFE, 0xFF          ; F999BE  link XIZ,0xfffe   [llvm-mc cannot encode this]
	pushw	hl                               ; F999C2  push HL
	pushw	de                               ; F999C3  push DE
	pushw	ix                               ; F999C4  push IX
	ld	h, (xiz+10)                         ; F999C5  ld H,(XIZ+0x0a)
	cp	h, 0:i3                               ; F999C8  cp H,0
	jrl z, Link_SendChunk__F99A3A                       ; F999CA  jrl Z,0xf99a3a
	ldw	de, 0                              ; F999CD  ld DE,0x0000
Link_SendChunk__F999D0:
	bit_dd8	3, PA                          ; F999D0  bit 3,(0x1e)
	jr nz, Link_SendChunk__F999E1                       ; F999D3  jr NZ,0xf999e1
	ld	ix, de                              ; F999D5  ld IX,DE
	inc	1, de                              ; F999D7  inc 1,DE
	cp	ix, 0x4E20                          ; F999D9  cp IX,0x4e20
	jr ule, Link_SendChunk__F999D0                      ; F999DD  jr ULE,0xf999d0
	jr Link_SendChunk__F99A3A                           ; F999DF  jr T,0xf99a3a
Link_SendChunk__F999E1:
	res_dd8	0, PA                          ; F999E1  res 0,(0x1e)
	ld	(0xF32C:24), 1                    ; F999E4  ld (0x00f32c),0x01
	ld	l, h                                ; F999EA  ld L,H
	dec	1, l                               ; F999EC  dec 1,L
	ld	c, (xiz+8)                          ; F999EE  ld C,(XIZ+0x08)
	sll	c, 5                               ; F999F1  sll 0x05,C
	or	c, l                                ; F999F4  or C,L
	ld	(xiz-2), c                          ; F999F6  ld (XIZ+0xfe),C
	ld	xbc, 0x100000                       ; F999F9  ld XBC,0x00100000
	ld	a, (xiz-2)                          ; F999FE  ld A,(XIZ+0xfe)
	ld	(xbc), a                            ; F99A01  ld (XBC),A
	ldw	de, 0                              ; F99A03  ld DE,0x0000
Link_SendChunk__F99A06:
	bit_dd8	3, PA                          ; F99A06  bit 3,(0x1e)
	jr z, Link_SendChunk__F99A1A                        ; F99A09  jr Z,0xf99a1a
	ld	ix, de                              ; F99A0B  ld IX,DE
	inc	1, de                              ; F99A0D  inc 1,DE
	cp	ix, 0x4E20                          ; F99A0F  cp IX,0x4e20
	jr ule, Link_SendChunk__F99A06                      ; F99A13  jr ULE,0xf99a06
	set_dd8	0, PA                          ; F99A15  set 0,(0x1e)
	jr Link_SendChunk__F99A3A                           ; F99A18  jr T,0xf99a3a
Link_SendChunk__F99A1A:
	set_dd8	0, PA                          ; F99A1A  set 0,(0x1e)
	ld	c, h                                ; F99A1D  ld C,H
	extz	bc                                ; F99A1F  extz BC
	pushw	bc                               ; F99A21  push BC
	ld	xbc, (xiz+12)                       ; F99A22  ld XBC,(XIZ+0x0c)
	push	xbc                               ; F99A25  push XBC
	call	0xF9A005                          ; F99A26  call 0xf9a005
	ldio	DMA2V, 18                         ; F99A2A  ld (0x7e),0x12
	set_dd8	2, TRUN                        ; F99A2D  set 2,(0x20)
	inc	6, xsp                             ; F99A30  inc 6,XSP
Link_SendChunk__F99A32:
	cp (0x00F32C:24), 0x00                 ; F99A32  cp (0x00f32c),0x00   [llvm-mc cannot encode this]
	jr nz, Link_SendChunk__F99A32                       ; F99A38  jr NZ,0xf99a32
Link_SendChunk__F99A3A:
	popw	ix                                ; F99A3A  pop IX
	popw	de                                ; F99A3B  pop DE
	popw	hl                                ; F99A3C  pop HL
	unlk32 xiz                             ; F99A3D  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F99A3F  ret

; --------------------------------------------------------------------------
; Link_SendCmdE2_MemRead -- command 0xE2 plus a 10-byte parameter packet.
;
; Called from: NOT FOUND.  notes/prom_c_xrefs.py 0xF99A40 reports no literal and
;          no calr reaching it; short PC-relative forms are not searched.
; Inputs:  (XIZ+0x08) u32, (XIZ+0x0c) u16, (XIZ+0x0e) u32.
; Outputs: the byte 0xE2 at 0x00100000, then the 10-byte packet built at
;          0x008538 -- +0x00 = arg(XIZ+0x08), +0x04 = arg(XIZ+0x0e),
;          +0x08 = arg(XIZ+0x0c) -- moved by micro-DMA channel 2.  Bit 7 of
;          (0x00852B) is set, which is the flag Link_WaitBlockDone polls.
; Evidence: ★ THIS IS prom_a's 0xF8E0FE, COMPILED FOR THE OTHER CPU -- and the
;          claim is measured, not eyeballed:
;
;            $ python3 notes/prom_c_prom_a_routine_diff.py 0xF99A40 0xF8E0FE 0x83
;              instruction slots compared: 47
;              identical text:        29
;              same mnemonic, different operand: 18
;              DIFFERENT MNEMONIC:    0
;
;          All eighteen differences are substituted addresses: buffer 0x008538 vs
;          0x600793, port 0x00100000 vs 0x007C0000, handshake PA vs P7, busy flag
;          0x00F32C vs 0x6007D9, outstanding flag 0x00852B vs 0x00008A, the DMA
;          setter, and the branch targets.  ⚠ They are therefore NOT byte-
;          identical, and the honest byte figure is NOT the leading run:
;
;            $ python3 notes/prom_c_prom_a_shared_runs.py --window 0xF99A40 0xF8E0FE 0x83
;              equal runs (offset,len): (0,8) (11,18) (32,5) (38,2) (43,5) (49,8)
;                                       (58,14) (73,4) (78,23) (104,7) (113,5) (121,10)
;              leading run: 8      LONGEST equal run: 23 of 131
;              total equal bytes: 109 of 131  (83%)
;
;          ★ A ROUND-1 DRAFT OF THIS HEADER SAID "an identical run of only EIGHT
;          bytes".  Eight is the LEADING run; the longest is 23 and 83% of the
;          window is equal.  Elsewhere in this file "identical run" means the
;          MAXIMAL run, so that sentence understated byte similarity about
;          threefold.  The conclusion is unchanged -- 83% equal bytes still cannot
;          tell you the two routines have the same 47-instruction structure, which
;          is why the header cites the instruction-level diff -- but the number was
;          wrong and is corrected here.  Both figures are now asserted by that
;          script's --selftest.
;          The three packet stores are in the IDENTICAL group, so the field
;          layout is literally the same code -- and notes/FINDINGS-memory-map.md
;          §3 already pins what those fields mean, from TWO CPU-1 callers:
;          +0x00 the address to read on the other processor, +0x04 the local
;          destination, +0x08 the length.
;          ⚠ Those meanings are CARRIED FROM prom_a.  prom_c has no caller of
;          this routine, so nothing in this image confirms the direction.
; Unknown:  what sends this; what else reads bit 7 of 0x00852B.
; --------------------------------------------------------------------------
Link_SendCmdE2_MemRead:
	link32 0xEE, 0x0C, 0x00, 0x00          ; F99A40  link XIZ,0x0000   [llvm-mc cannot encode this]
	pushw	hl                               ; F99A44  push HL
	pushw	de                               ; F99A45  push DE
	push	xix                               ; F99A46  push XIX
	lda	xix, (0x8538:24)                   ; F99A47  lda XIX,0x008538
	ldw	hl, 0                              ; F99A4C  ld HL,0x0000
	jr Link_SendCmdE2_MemRead__F99A5C                           ; F99A4F  jr T,0xf99a5c
Link_SendCmdE2_MemRead__F99A51:
	ld	de, hl                              ; F99A51  ld DE,HL
	inc	1, hl                              ; F99A53  inc 1,HL
	cp	de, 0x4E20                          ; F99A55  cp DE,0x4e20
	jrl ugt, Link_SendCmdE2_MemRead__F99ABD                     ; F99A59  jrl UGT,0xf99abd
Link_SendCmdE2_MemRead__F99A5C:
	cp (0x00F32C:24), 0x00                 ; F99A5C  cp (0x00f32c),0x00   [llvm-mc cannot encode this]
	jr nz, Link_SendCmdE2_MemRead__F99A51                       ; F99A62  jr NZ,0xf99a51
	res_dd8	0, PA                          ; F99A64  res 0,(0x1e)
	ld	(0xF32C:24), 1                    ; F99A67  ld (0x00f32c),0x01
	ld	xbc, 0x100000                       ; F99A6D  ld XBC,0x00100000
	ld	(xbc), 0xE2                         ; F99A72  ld (XBC),0xe2
	ldw	hl, 0                              ; F99A75  ld HL,0x0000
Link_SendCmdE2_MemRead__F99A78:
	bit_dd8	3, PA                          ; F99A78  bit 3,(0x1e)
	jr z, Link_SendCmdE2_MemRead__F99A8C                        ; F99A7B  jr Z,0xf99a8c
	ld	de, hl                              ; F99A7D  ld DE,HL
	inc	1, hl                              ; F99A7F  inc 1,HL
	cp	de, 0x4E20                          ; F99A81  cp DE,0x4e20
	jr ule, Link_SendCmdE2_MemRead__F99A78                      ; F99A85  jr ULE,0xf99a78
	set_dd8	0, PA                          ; F99A87  set 0,(0x1e)
	jr Link_SendCmdE2_MemRead__F99ABD                           ; F99A8A  jr T,0xf99abd
Link_SendCmdE2_MemRead__F99A8C:
	set_dd8	0, PA                          ; F99A8C  set 0,(0x1e)
	ld	xbc, (xiz+8)                        ; F99A8F  ld XBC,(XIZ+0x08)
	ld	(xix), xbc                          ; F99A92  ld (XIX),XBC
	ld	xbc, (xiz+14)                       ; F99A94  ld XBC,(XIZ+0x0e)
	ld	(xix+4), xbc                        ; F99A97  ld (XIX+0x04),XBC
	ld	bc, (xiz+12)                        ; F99A9A  ld BC,(XIZ+0x0c)
	ld	(xix+8), bc                         ; F99A9D  ld (XIX+0x08),BC
	pushw	10                               ; F99AA0  push 0x000a
	push	xix                               ; F99AA3  push XIX
	call	0xF9A005                          ; F99AA4  call 0xf9a005
	ldio	DMA2V, 18                         ; F99AA8  ld (0x7e),0x12
	set_dd8	2, TRUN                        ; F99AAB  set 2,(0x20)
	set 7, (0x00852B:24)                   ; F99AAE  set 7,(0x00852b)   [llvm-mc cannot encode this]
	inc	6, xsp                             ; F99AB3  inc 6,XSP
Link_SendCmdE2_MemRead__F99AB5:
	cp (0x00F32C:24), 0x00                 ; F99AB5  cp (0x00f32c),0x00   [llvm-mc cannot encode this]
	jr nz, Link_SendCmdE2_MemRead__F99AB5                       ; F99ABB  jr NZ,0xf99ab5
Link_SendCmdE2_MemRead__F99ABD:
	pop	xix                                ; F99ABD  pop XIX
	popw	de                                ; F99ABE  pop DE
	popw	hl                                ; F99ABF  pop HL
	unlk32 xiz                             ; F99AC0  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F99AC2  ret

; --------------------------------------------------------------------------
; Link_SendCmdByte -- send one bare command byte 0xE0 | n, with no payload.
;
; Called from: 0xF99EFD (`calr 0xF99AC3`), inside Link_ServiceTask -- the last
;          instruction of the arm guarded by bit 6 of the flag byte 852C (see
;          that routine).  ONE site
;          (`notes/prom_c_xrefs.py 0xF99AC3 --no-window`: CALR 1, literal 0).
;          ⚠ "the unconverted stretch that follows INTT2_HANDLER" was a round-1
;          draft; 0xF99EFD is converted, in this file.  Corrected.
; Inputs:  (XIZ+0x08) -- only the low nibble survives `or H,0xE0`.
; Outputs: one byte at 0x00100000; (0x00F32C) raised to 1 and lowered to 0 by
;          this routine itself.
; Evidence: `ld H,(XIZ+0x08) / or H,0xE0 / ld XBC,0x00100000 / ld (XBC),H` is the
;          "bare command 0xE0 | n" form notes/FINDINGS-memory-map.md §3 names,
;          and 0xF99AEC is the exact instruction that note already cites for it.
;          ★ IT IS NOT THE SAME ROUTINE AS CPU 1's.  prom_a 0xF8E181 is the
;          nearest match and the diff is not clean:
;            $ python3 notes/prom_c_prom_a_routine_diff.py 0xF99AC3 0xF8E181 0x4A
;              identical text: 7   same mnemonic, different operand: 10
;              DIFFERENT MNEMONIC: 9
;          The nine are one block: where CPU 1 waits on its busy PIN after
;          writing the byte, CPU 2 runs a fixed countdown of 0x3E8 = 1000 and then
;          clears the busy flag itself.  So this variant NEVER waits for the far
;          end and never leaves the flag set.  Also, CPU 1 takes the command in
;          (XIZ+0x0c) and CPU 2 in (XIZ+0x08).
;          ★ THE ONE CALLER SENDS COMMAND 0xE6, and this is arithmetic, not a
;          guess.  `link XIZ,0x0000` leaves XIZ on the saved XIZ, so XIZ+0 = saved
;          XIZ (4), XIZ+4 = the return address (4), and XIZ+0x08 = the LAST thing
;          pushed -- confirmed independently by Link_SendCmdE1, whose three
;          arguments at +0x08/+0x0c/+0x0e line up byte for byte with its caller's
;          `push XBC / push BC / push XBC`.  The last push before 0xF99EFD is
;          `push 0x0006` at 0xF99EFA (16-bit, little-endian, so the byte at
;          XIZ+0x08 is 0x06), `ld H,(XIZ+0x08)` reads it, and `or H,0xe0` makes
;          0xE6.  The following `inc 6,XSP` pops that 2-byte argument together
;          with the 4-byte XBC left by the `call 0xFC88F9` above it.
; Unknown:  what 0xE6 means to CPU 1; why the acknowledgement is replaced by a
;          delay here and not there.
; --------------------------------------------------------------------------
Link_SendCmdByte:
	link32 0xEE, 0x0C, 0x00, 0x00          ; F99AC3  link XIZ,0x0000   [llvm-mc cannot encode this]
	pushw	hl                               ; F99AC7  push HL
	pushw	de                               ; F99AC8  push DE
	ldw	hl, 0                              ; F99AC9  ld HL,0x0000
	jr Link_SendCmdByte__F99AD8                           ; F99ACC  jr T,0xf99ad8
Link_SendCmdByte__F99ACE:
	ld	de, hl                              ; F99ACE  ld DE,HL
	inc	1, hl                              ; F99AD0  inc 1,HL
	cp	de, 0x4E20                          ; F99AD2  cp DE,0x4e20
	jr ugt, Link_SendCmdByte__F99B08                      ; F99AD6  jr UGT,0xf99b08
Link_SendCmdByte__F99AD8:
	cp (0x00F32C:24), 0x00                 ; F99AD8  cp (0x00f32c),0x00   [llvm-mc cannot encode this]
	jr nz, Link_SendCmdByte__F99ACE                       ; F99ADE  jr NZ,0xf99ace
	res_dd8	0, PA                          ; F99AE0  res 0,(0x1e)
	ld	(0xF32C:24), 1                    ; F99AE3  ld (0x00f32c),0x01
	ld	h, (xiz+8)                          ; F99AE9  ld H,(XIZ+0x08)
	or	h, 0xE0                             ; F99AEC  or H,0xe0
	ld	xbc, 0x100000                       ; F99AEF  ld XBC,0x00100000
	ld	(xbc), h                            ; F99AF4  ld (XBC),H
	ldw	hl, 0x3E8                          ; F99AF6  ld HL,0x03e8
Link_SendCmdByte__F99AF9:
	dec	1, hl                              ; F99AF9  dec 1,HL
	cp	hl, 0:i3                              ; F99AFB  cp HL,0
	jr nz, Link_SendCmdByte__F99AF9                       ; F99AFD  jr NZ,0xf99af9
	set_dd8	0, PA                          ; F99AFF  set 0,(0x1e)
	ld	(0xF32C:24), 0                    ; F99B02  ld (0x00f32c),0x00
Link_SendCmdByte__F99B08:
	popw	de                                ; F99B08  pop DE
	popw	hl                                ; F99B09  pop HL
	unlk32 xiz                             ; F99B0A  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F99B0C  ret

; --------------------------------------------------------------------------
; Link_SendCmdE1 -- command 0xE1, a 6-byte parameter packet, then the caller's
;             own buffer as a second micro-DMA transfer.
;
; Called from: 0xF99E87 (`calr 0xF99B0D`), inside Link_ServiceTask -- the arm
;          guarded by bit 7 of the flag byte 852A (see that routine).  ONE site
;          (`notes/prom_c_xrefs.py 0xF99B0D --no-window`: CALR 1, literal 0).
;          ⚠ A round-1 draft of this line said "in the unconverted stretch after
;          INTT2_HANDLER".  0xF99E87 is converted, in this file, at the label
;          Link_ServiceTask__F99E8E's predecessor -- and the Evidence block below
;          already reasoned from that very caller.  Corrected.
; Inputs:  (XIZ+0x08) u32, (XIZ+0x0c) u16, (XIZ+0x0e) u32.
; Outputs: the byte 0xE1 at 0x00100000; then SIX bytes from 0x008542, laid out
;          +0x00 = arg(XIZ+0x0e) u32 and +0x04 = arg(XIZ+0x0c) u16; then, once
;          the busy flag has fallen to 1, a SECOND transfer of arg(XIZ+0x0c)
;          bytes taken from arg(XIZ+0x08).  (0x00F32C) is set to 2 here, not 1.
; Evidence: ★ prom_a 0xF8E26F IS THE SAME ROUTINE, measured not eyeballed:
;
;            $ python3 notes/prom_c_prom_a_routine_diff.py 0xF99B0D 0xF8E26F 0xAB
;              instruction slots compared: 58
;              identical text: 34
;              same mnemonic, different operand: 24
;              DIFFERENT MNEMONIC:    0
;
;          -- 58 instructions, no structural difference, 24 substituted operands
;          (the port, the pins, the flags, the buffers and the branch targets).
;          The two-stage shape is readable in prom_c alone: uDMA2_SetSource is
;          called first with (0x008542, 6), then `cp (0x00F32C),0x01 / jr NZ`
;          spins until the state machine has moved the flag from 2 down to 1, a
;          0xC8 = 200-pass countdown follows, and then uDMA2_SetSource is called
;          again with ((XIX), (XIX+4)) where XIX = 0x00851A.
;          ★ SO THE SECOND TRANSFER IS THE PAYLOAD AND THE FIRST IS ITS HEADER:
;          the 6-byte packet carries a 32-bit address and a 16-bit length, and
;          the payload that follows is that many bytes from arg(XIZ+0x08).
;          ⚠ THE LENGTH IS STORED TWICE and the two ADDRESSES ARE DIFFERENT ONES.
;          arg(XIZ+0x08) goes to (0x00851A) and arg(XIZ+0x0e) to (0x008542) --
;          two distinct 32-bit slots -- while arg(XIZ+0x0c) is written to BOTH
;          (0x00851E) and (0x008546).  0x008542 is 0x00851A + 0x28, so these are
;          two separate buffers and not one object seen twice.
;          ★ AND THE CALLER SETTLES WHICH IS WHICH, WITHOUT prom_a.  Link_ServiceTask
;          (0xF99E5F, converted below) is the only caller, and it passes the three
;          words of the 0xE2 request packet that micro-DMA channel 3 just deposited
;          at 0x008520: `Link_SendCmdE1((0x008520), (0x008528), (0x008524))`.  The
;          0xE2 packet's fields are +0x00 address, +0x04 address, +0x08 length, so
;          arg(XIZ+0x08) = packet+0x00 -- the one THIS routine dereferences as the
;          payload's source -- is an address on THIS processor, and
;          arg(XIZ+0x0e) = packet+0x04, the one that travels in the header, is on
;          the OTHER one.  Command 0xE2 is a remote READ REQUEST and command 0xE1
;          is the WRITE that answers it.
; Unknown:  what 0xE1 means to CPU 1.  (What the caller passes is NOT unknown --
;          the Evidence block above reads it off Link_ServiceTask; the round-1
;          draft of this line contradicted its own header.)
; --------------------------------------------------------------------------
Link_SendCmdE1:
	link32 0xEE, 0x0C, 0x00, 0x00          ; F99B0D  link XIZ,0x0000   [llvm-mc cannot encode this]
	pushw	hl                               ; F99B11  push HL
	pushw	de                               ; F99B12  push DE
	push	xix                               ; F99B13  push XIX
	lda	xix, (0x851A:24)                   ; F99B14  lda XIX,0x00851a
	ldw	hl, 0                              ; F99B19  ld HL,0x0000
	jr Link_SendCmdE1__F99B29                           ; F99B1C  jr T,0xf99b29
Link_SendCmdE1__F99B1E:
	ld	de, hl                              ; F99B1E  ld DE,HL
	inc	1, hl                              ; F99B20  inc 1,HL
	cp	de, 0x4E20                          ; F99B22  cp DE,0x4e20
	jrl ugt, Link_SendCmdE1__F99BB8                     ; F99B26  jrl UGT,0xf99bb8
Link_SendCmdE1__F99B29:
	cp (0x00F32C:24), 0x00                 ; F99B29  cp (0x00f32c),0x00   [llvm-mc cannot encode this]
	jr nz, Link_SendCmdE1__F99B1E                       ; F99B2F  jr NZ,0xf99b1e
	res_dd8	0, PA                          ; F99B31  res 0,(0x1e)
	ld	(0xF32C:24), 2                    ; F99B34  ld (0x00f32c),0x02
	ld	xbc, 0x100000                       ; F99B3A  ld XBC,0x00100000
	ld	(xbc), 0xE1                         ; F99B3F  ld (XBC),0xe1
	ldw	hl, 0                              ; F99B42  ld HL,0x0000
Link_SendCmdE1__F99B45:
	bit_dd8	3, PA                          ; F99B45  bit 3,(0x1e)
	jr z, Link_SendCmdE1__F99B5A                        ; F99B48  jr Z,0xf99b5a
	ld	de, hl                              ; F99B4A  ld DE,HL
	inc	1, hl                              ; F99B4C  inc 1,HL
	cp	de, 0x4E20                          ; F99B4E  cp DE,0x4e20
	jr ule, Link_SendCmdE1__F99B45                      ; F99B52  jr ULE,0xf99b45
	set_dd8	0, PA                          ; F99B54  set 0,(0x1e)
	jrl Link_SendCmdE1__F99BB8                          ; F99B57  jrl T,0xf99bb8
Link_SendCmdE1__F99B5A:
	set_dd8	0, PA                          ; F99B5A  set 0,(0x1e)
	ld	xbc, (xiz+8)                        ; F99B5D  ld XBC,(XIZ+0x08)
	ld	(xix), xbc                          ; F99B60  ld (XIX),XBC
	ld	xbc, (xiz+14)                       ; F99B62  ld XBC,(XIZ+0x0e)
	ld	(0x8542:24), xbc                   ; F99B65  ld (0x008542),XBC
	ld	bc, (xiz+12)                        ; F99B6A  ld BC,(XIZ+0x0c)
	ld	(xix+4), bc                         ; F99B6D  ld (XIX+0x04),BC
	ld	bc, (xiz+12)                        ; F99B70  ld BC,(XIZ+0x0c)
	ld	(0x8546:24), bc                    ; F99B73  ld (0x008546),BC
	pushw	6                                ; F99B78  push 0x0006
	lda	xbc, (0x8542:24)                   ; F99B7B  lda XBC,0x008542
	push	xbc                               ; F99B80  push XBC
	call	0xF9A005                          ; F99B81  call 0xf9a005
	ldio	DMA2V, 18                         ; F99B85  ld (0x7e),0x12
	set_dd8	2, TRUN                        ; F99B88  set 2,(0x20)
	inc	6, xsp                             ; F99B8B  inc 6,XSP
Link_SendCmdE1__F99B8D:
	cp (0x00F32C:24), 0x01                 ; F99B8D  cp (0x00f32c),0x01   [llvm-mc cannot encode this]
	jr nz, Link_SendCmdE1__F99B8D                       ; F99B93  jr NZ,0xf99b8d
	ldb	h, 0xC8                            ; F99B95  ld H,0xc8
Link_SendCmdE1__F99B97:
	dec	1, h                               ; F99B97  dec 1,H
	cp	h, 0:i3                               ; F99B99  cp H,0
	jr nz, Link_SendCmdE1__F99B97                       ; F99B9B  jr NZ,0xf99b97
	ld	bc, (xix+4)                         ; F99B9D  ld BC,(XIX+0x04)
	pushw	bc                               ; F99BA0  push BC
	ld	xbc, (xix)                          ; F99BA1  ld XBC,(XIX)
	push	xbc                               ; F99BA3  push XBC
	call	0xF9A005                          ; F99BA4  call 0xf9a005
	ldio	DMA2V, 18                         ; F99BA8  ld (0x7e),0x12
	set_dd8	2, TRUN                        ; F99BAB  set 2,(0x20)
	inc	6, xsp                             ; F99BAE  inc 6,XSP
Link_SendCmdE1__F99BB0:
	cp (0x00F32C:24), 0x00                 ; F99BB0  cp (0x00f32c),0x00   [llvm-mc cannot encode this]
	jr nz, Link_SendCmdE1__F99BB0                       ; F99BB6  jr NZ,0xf99bb0
Link_SendCmdE1__F99BB8:
	pop	xix                                ; F99BB8  pop XIX
	popw	de                                ; F99BB9  pop DE
	popw	hl                                ; F99BBA  pop HL
	unlk32 xiz                             ; F99BBB  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F99BBD  ret
